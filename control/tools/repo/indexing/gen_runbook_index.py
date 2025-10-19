#!/usr/bin/env python3
# SPDX-License-Identifier: MIT-0
"""
HybridOps.Studio — Runbook Index Generator
==========================================

Purpose:
--------
Generates dynamic indexes and metadata summaries for all operational runbooks under
`docs/runbooks/`. The generator respects the README template structure exactly, using
marker replacement for automation while leaving layout, headings, and formatting intact.

Outputs:
--------
- docs/runbooks/000-INDEX.md           → tabular summary (category, severity, timestamps)
- docs/runbooks/by-category/<cat>.md   → per-category link lists
- docs/runbooks/README.md              → updated from README.tmpl.md via marker replacement

Typical usage:
--------------
    $ make runbook.index
or
    $ python3 control/tools/repo/indexing/gen_runbook_index.py
"""

import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Dict
from _index_utils import load_text, write_text, parse_front_matter, replace_block, utc_now, slugify, should_skip_file

# --------------------------------------------------------------------
# Constants & Paths
# --------------------------------------------------------------------
ROOT = Path.cwd()
RUNBOOK_DIR = ROOT / "docs" / "runbooks"
README = RUNBOOK_DIR / "README.md"
README_TMPL = RUNBOOK_DIR / "README.tmpl.md"
INDEX = RUNBOOK_DIR / "000-INDEX.md"
BYCAT_DIR = RUNBOOK_DIR / "by-category"

MARK_START = "<!-- RUNBOOKS:INDEX START -->"
MARK_END = "<!-- RUNBOOKS:INDEX END -->"

# --------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------
def _first_h1_or_default(body: str, stem: str) -> str:
    """Return first Markdown H1 or fallback to filename."""
    for line in body.splitlines():
        if line.strip().startswith("# "):
            return line.strip("# ").strip()
    return stem.replace("_", " ").replace("-", " ").title()


def collect_items() -> List[Dict[str, str]]:
    """Scan runbook markdown files and extract metadata."""
    items = []
    for p in RUNBOOK_DIR.rglob("*.md"):
        rel = p.relative_to(RUNBOOK_DIR)

        # Use shared skip logic from _index_utils
        if should_skip_file(rel, ignore_folders=["by-category"]):
            continue
        if p.name.lower() in ("readme.md", "000-index.md"):
            continue

        fm, body = parse_front_matter(load_text(p))
        title = fm.get("title") or _first_h1_or_default(body, p.stem)
        category = slugify(fm.get("category") or (rel.parts[0] if len(rel.parts) > 1 else "general"))
        severity = (fm.get("severity") or "").strip().upper()
        last_upd = fm.get("last_updated") or datetime.fromtimestamp(
            p.stat().st_mtime, tz=timezone.utc
        ).strftime("%Y-%m-%d")
        rel_path = "./" + str(rel).replace("\\", "/")

        items.append({
            "title": title,
            "category": category,
            "severity": severity,
            "last_updated": last_upd,
            "path": rel_path,
        })

    return sorted(items, key=lambda x: (x["category"], x["title"].lower()))



def _counts(items: List[Dict[str, str]]) -> Dict[str, int]:
    """Return category counts for summary pills."""
    counts = {}
    for it in items:
        counts[it["category"]] = counts.get(it["category"], 0) + 1
    return counts


# --------------------------------------------------------------------
# Writers
# --------------------------------------------------------------------
def write_000_index(items: List[Dict[str, str]]) -> None:
    """Generate the tabular runbook index with horizontal category listing."""
    now, cats = utc_now(), _counts(items)
    lines = [
        f"# 000-INDEX — Runbooks\n_Last updated: {now}_\n",
        "Tabular summary of reproducible operational procedures grouped by category and severity.\n",
    ]

    # Horizontal "pills" line for categories
    if cats:
        pills = " · ".join(
            f"[{c} ({n})](./by-category/{c}.md)" for c, n in sorted(cats.items())
        )
        lines.append(f"**Categories:** {pills}\n")

    lines.append("**Legend:** P1 = critical · P2 = high · P3 = normal\n")

    # Centered table layout — first column left-aligned for readability
    lines.append("| Runbook | Link | Severity | Category | Last updated |")
    lines.append("|:---------|:----:|:--------:|:---------:|:-------------:|")

    for it in items:
        lines.append(
            f"| {it['title']} | [Open]({it['path']}) | {it['severity']} | {it['category']} | {it['last_updated']} |"
        )

    write_text(INDEX, "\n".join(lines) + "\n")


def write_by_category(items: List[Dict[str, str]]) -> None:
    """Generate simple per-category link lists."""
    BYCAT_DIR.mkdir(parents=True, exist_ok=True)
    buckets = {}
    for it in items:
        buckets.setdefault(it["category"], []).append(it)

    for cat, lst in buckets.items():
        lst.sort(key=lambda x: x["title"].lower())
        lines = [f"# {cat.title()} Runbooks\n"]
        for it in lst:
            rel = "../" + it["path"].lstrip("./")
            lines.append(f"- [{it['title']}]({rel})")
        write_text(BYCAT_DIR / f"{cat}.md", "\n".join(lines) + "\n")


# --------------------------------------------------------------------
# README Rendering (wrapped, like HOWTOs)
# --------------------------------------------------------------------
def _render_readme_block(items: List[Dict[str, str]]) -> str:
    """Render collapsible markdown block injected into README.md."""
    pills = " · ".join(
        f"[{c} ({n})](./by-category/{c}.md)" for c, n in sorted(_counts(items).items())
    )
    now = utc_now()
    out = [
        f"**Categories:** {pills}\n",
        "For detailed metadata (severity, timestamps), see the [full index](./000-INDEX.md).\n",
        "\n---\n",
        f"<details>\n  <summary><strong>All Runbooks</strong> ({len(items)}) — click to expand</summary>\n",
    ]
    for it in items:
        out.append(f"- [{it['title']}]({it['path']})")
    out.append("\n</details>\n")
    out.append(f"\n<sub>Last generated: {now}</sub>\n")
    return "\n".join(out)


def patch_readme(items: List[Dict[str, str]]) -> None:
    """Respect README template layout; safely replace marker block."""
    if not README.exists():
        if README_TMPL.exists():
            write_text(README, load_text(README_TMPL))
        else:
            write_text(README, "# Runbooks — Operational Procedures\n\n" + MARK_START + "\n" + MARK_END + "\n")

    current = load_text(README)

    # Auto-clean duplicate marker pairs
    if current.count(MARK_START) > 1 or current.count(MARK_END) > 1:
        print(f"⚠️  Warning: Multiple RUNBOOK markers found in {README}. Cleaning automatically.")
        before = current.split(MARK_START, 1)[0]
        after = current.split(MARK_END, 1)[-1]
        current = before + MARK_START + "\n" + MARK_END + after

    new_block = _render_readme_block(items)
    updated = replace_block(current, MARK_START, MARK_END, new_block)
    write_text(README, updated)


# --------------------------------------------------------------------
# Entrypoint
# --------------------------------------------------------------------
def main() -> None:
    items = collect_items()
    if not items:
        print(f"⚠️  No runbooks found under {RUNBOOK_DIR}")
        return
    write_000_index(items)
    write_by_category(items)
    patch_readme(items)
    print(f"✅  Updated {README}, wrote {INDEX}, and populated {BYCAT_DIR}/")


if __name__ == "__main__":
    main()
