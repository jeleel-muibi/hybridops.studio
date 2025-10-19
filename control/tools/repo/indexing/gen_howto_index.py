#!/usr/bin/env python3
# SPDX-License-Identifier: MIT-0
"""
HybridOps.Studio — HOWTO Index Generator
========================================

Purpose:
--------
Generates dynamic indexes and metadata summaries for all HOWTO guides under
`docs/howto/`. These indexes are used to keep the documentation library
organized, cross-linked, and continuously up-to-date.

Outputs:
--------
- docs/howto/000-INDEX.md               → tabular summary (topic, difficulty, link)
- docs/howto/by-topic/<topic>.md        → per-topic list view
- docs/howto/README.md                  → rebuilt from README.tmpl.md (marker-based)

Typical usage:
--------------
    $ make howto.index
or
    $ python3 control/tools/repo/indexing/gen_howto_index.py

Conventions:
------------
HOWTO files must begin with valid YAML front matter defining:
  - title, summary, difficulty, video, topic, draft/template (optional)
"""

import re
import yaml
from datetime import datetime, timezone
from pathlib import Path
from _index_utils import load_text, write_text, replace_block, utc_now, slugify, should_skip_file

# --------------------------------------------------------------------
# Constants & Paths
# --------------------------------------------------------------------
ROOT = Path.cwd()
HOWTO_DIR = ROOT / "docs" / "howto"
README = HOWTO_DIR / "README.md"
README_TMPL = HOWTO_DIR / "README.tmpl.md"
INDEX = HOWTO_DIR / "000-INDEX.md"
BYTOPIC_DIR = HOWTO_DIR / "by-topic"

MARK_START = "<!-- HOWTO:INDEX START -->"
MARK_END = "<!-- HOWTO:INDEX END -->"

# --------------------------------------------------------------------
# Helper functions
# --------------------------------------------------------------------
def parse_front_matter(text: str) -> tuple[dict, str]:
    """Extract YAML front matter and return (front_matter, body)."""
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    fm = yaml.safe_load(parts[1]) or {}
    body = parts[2].lstrip()
    return fm, body


def collect_items() -> list[dict]:
    """Scan HOWTO markdown files and extract metadata."""
    items = []
    for p in HOWTO_DIR.glob("HOWTO_*.md"):
        # Use unified skip logic (avoids templates, backups, etc.)
        if should_skip_file(p.relative_to(HOWTO_DIR), ignore_folders=["by-topic"]):
            continue
        if p.name.lower() in ("readme.md", "000-index.md"):
            continue

        fm, _ = parse_front_matter(load_text(p))
        title = fm.get("title", p.stem.replace("HOWTO_", ""))
        topic = slugify(fm.get("topic", "general"))
        summary = fm.get("summary", "")
        difficulty = fm.get("difficulty", "")
        video = fm.get("video") or fm.get("video_demo", "")
        last_upd = fm.get("last_updated") or datetime.fromtimestamp(
            p.stat().st_mtime, tz=timezone.utc
        ).strftime("%Y-%m-%d")
        relpath = "./" + str(p.relative_to(HOWTO_DIR)).replace("\\", "/")

        items.append(
            {
                "title": title,
                "topic": topic,
                "summary": summary,
                "difficulty": difficulty,
                "video": video,
                "last_updated": last_upd,
                "path": relpath,
            }
        )

    return sorted(items, key=lambda x: (x["topic"], x["title"].lower()))


def _counts(items: list[dict]) -> dict[str, int]:
    """Return count of HOWTOs per topic."""
    counts = {}
    for it in items:
        counts[it["topic"]] = counts.get(it["topic"], 0) + 1
    return counts


def write_000_index(items: list[dict]) -> None:
    """Generate the top-level tabular HOWTO index file with centered columns."""
    now, cats = utc_now(), _counts(items)
    lines = [
        f"# 000-INDEX — HOWTOs\n_Last updated: {now}_\n",
        "Tabular summary of reproducible HOWTO guides, grouped by topic.\n",
    ]

    if cats:
        lines.append("**Topics**")
        for c, n in sorted(cats.items()):
            lines.append(f"- [{c} ({n})](./by-topic/{c}.md)")
        lines.append("")

    # Table header — centered except the first column
    lines.append("| HOWTO | Link | Topic | Difficulty | Last updated | Video |")
    lines.append("|:------|:----:|:------:|:------------:|:-------------:|:------:|")

    for it in items:
        vid = f"[Demo]({it['video']})" if it["video"] else ""
        last_upd = it["last_updated"].split(" ")[0]  # drop time/UTC if present
        lines.append(
            f"| {it['title']} | [Open]({it['path']}) | {it['topic']} | {it['difficulty']} | {last_upd} | {vid} |"
        )

    write_text(INDEX, "\n".join(lines) + "\n")


def write_by_topic(items: list[dict]) -> None:
    """Generate categorized markdown lists for each HOWTO topic."""
    BYTOPIC_DIR.mkdir(parents=True, exist_ok=True)
    buckets: dict[str, list[dict]] = {}
    for it in items:
        buckets.setdefault(it["topic"], []).append(it)

    for topic, lst in buckets.items():
        lst.sort(key=lambda x: x["title"].lower())
        lines = [f"# {topic.title()} HOWTOs\n"]
        for it in lst:
            rel = "../" + it["path"].lstrip("./")
            line = f"- [{it['title']}]({rel})"
            if it["video"]:
                line += f" — [YouTube Demo]({it['video']})"
            lines.append(line)
        write_text(BYTOPIC_DIR / f"{topic}.md", "\n".join(lines) + "\n")


def _render_readme_block(items: list[dict]) -> str:
    """Render the replacement markdown block injected into README.md."""
    pills = " · ".join(
        f"[{c} ({n})](./by-topic/{c}.md)" for c, n in sorted(_counts(items).items())
    )
    now = utc_now()
    out = [
        f"**Topics:** {pills}\n",
        "For detailed metadata (difficulty, timestamps), see the [full index](./000-INDEX.md).\n",
        "\n---\n",
        f"<details>\n  <summary><strong>All HOWTOs</strong> ({len(items)}) — click to expand</summary>\n",
    ]
    for it in items:
        line = f"- [{it['title']}]({it['path']})"
        if it["video"]:
            line += f" — [YouTube Demo]({it['video']})"
        out.append(line)
    out.append("\n</details>\n")
    out.append(f"\n<sub>Last generated: {now}</sub>\n")
    return "\n".join(out)


def patch_readme(items: list[dict]) -> None:
    """Insert generated HOWTO summary into README.md between marker tags."""
    if not README.exists():
        if README_TMPL.exists():
            write_text(README, load_text(README_TMPL))
        else:
            write_text(README, "# HOWTO Library\n\n" + MARK_START + "\n" + MARK_END + "\n")

    new_block = _render_readme_block(items)
    current = load_text(README)
    write_text(README, replace_block(current, MARK_START, MARK_END, new_block))


# --------------------------------------------------------------------
# Entrypoint
# --------------------------------------------------------------------
def main() -> None:
    """Entry point for command-line execution."""
    items = collect_items()
    if not items:
        print(f"⚠️  No HOWTOs found under {HOWTO_DIR}")
        return
    write_000_index(items)
    write_by_topic(items)
    patch_readme(items)
    print(f"✅  Updated {README}, wrote {INDEX}, and populated {BYTOPIC_DIR}/")


if __name__ == "__main__":
    main()
