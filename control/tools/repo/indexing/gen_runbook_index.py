#!/usr/bin/env python3
"""
Generate runbook indexes under docs/runbooks.

Outputs
- docs/runbooks/000-INDEX.md           (table: Category, Last updated, Severity)
- docs/runbooks/by-category/<cat>.md   (clean link list; no severity)
- docs/runbooks/README.md              (block between markers replaced; seeds from README.tmpl.md if present)

Notes
- Run from the repository root so paths resolve correctly.
- Files with draft: true or template: true are excluded.
- README block stays compact; details live in 000-INDEX.md.
"""
from pathlib import Path
from datetime import datetime, timezone
import sys
import re

from _index_utils import load_text, write_text, parse_front_matter, replace_block, utc_now, slugify

# Paths (assumes invocation from repo root)
ROOT        = Path.cwd()
RUNBOOK_DIR = ROOT / "docs" / "runbooks"
README      = RUNBOOK_DIR / "README.md"
README_TMPL = RUNBOOK_DIR / "README.tmpl.md"
INDEX       = RUNBOOK_DIR / "000-INDEX.md"
BYCAT_DIR   = RUNBOOK_DIR / "by-category"

# Markers inside README.md
MARK_START = "<!-- RUNBOOKS:INDEX START -->"
MARK_END   = "<!-- RUNBOOKS:INDEX END -->"

# Ignore patterns
IGNORE_CONTAINS = (" copy",)
IGNORE_SUFFIXES = (".bak", ".backup", ".old", "~", ".tmp")
IGNORE_STARTS   = ("readme", "000-index")  # case-insensitive startswith
IGNORE_EXACT    = ("runbook_template.md",)


def should_skip(rel: Path) -> bool:
    if "by-category" in rel.parts:
        return True
    name = rel.name
    low = name.lower()
    if name.startswith("_") or low in IGNORE_EXACT:
        return True
    if low.startswith(IGNORE_STARTS):
        return True
    if any(k in name for k in IGNORE_CONTAINS):
        return True
    if any(name.endswith(s) for s in IGNORE_SUFFIXES):
        return True
    return False


def _first_h1_or_default(body: str, stem: str) -> str:
    for line in body.splitlines():
        if line.strip().startswith("# "):
            return line.strip("# ").strip()
    return stem.replace("_", " ").replace("-", " ").title()


def collect_items():
    if not RUNBOOK_DIR.exists():
        print(f"[ERROR] Not found: {RUNBOOK_DIR}", file=sys.stderr)
        sys.exit(2)

    items = []
    for p in RUNBOOK_DIR.rglob("*.md"):
        rel = p.relative_to(RUNBOOK_DIR)
        if should_skip(rel):
            continue
        if rel.as_posix() in ("README.md", "000-INDEX.md"):
            continue

        fm, body = parse_front_matter(load_text(p))

        if str(fm.get("template", "false")).lower() in ("true", "yes", "1"):
            continue
        if str(fm.get("draft", "false")).lower() in ("true", "yes", "1"):
            continue

        title = fm.get("title") or _first_h1_or_default(body, p.stem)
        category = slugify(fm.get("category") or (rel.parts[0] if len(rel.parts) > 1 else "general"))
        severity = (fm.get("severity") or "").strip()
        last_upd = fm.get("last_updated") or datetime.fromtimestamp(
            p.stat().st_mtime, tz=timezone.utc
        ).strftime("%Y-%m-%d %H:%M UTC")
        path_disp = "./" + str(rel).replace("\\", "/")

        items.append({
            "title": " ".join(title.split()),
            "category": category,
            "severity": severity,
            "last_updated": last_upd,
            "path": path_disp,
        })

    items.sort(key=lambda x: (x["category"], x["title"].lower()))
    return items


def _counts(items):
    out = {}
    for it in items:
        out[it["category"]] = out.get(it["category"], 0) + 1
    return out


def write_000_index(items):
    now, cats = utc_now(), _counts(items)
    lines = [
        f"# 000-INDEX — Runbooks\n_Last updated: {now}_\n",
        "Tabular view of procedures with category, severity, and last-updated timestamps.\n",
    ]
    if cats:
        lines.append("**Categories**")
        for c, n in sorted(cats.items()):
            lines.append(f"- [{c} ({n})](./by-category/{c}.md)")
        lines.append("")
    lines.append("**Legend:** P1 = critical · P2 = high · P3 = normal\n")
    lines.append("| Runbook | Category | Last updated | Severity | Link |")
    lines.append("|---|---|---|---|---|")
    for it in items:
        sev = it["severity"] or ""
        lines.append(f"| {it['title']} | {it['category']} | {it['last_updated']} | {sev} | [open]({it['path']}) |")
    write_text(INDEX, "\n".join(lines) + "\n")


def write_by_category(items):
    """Per-category link lists (no severity / timestamps)."""
    BYCAT_DIR.mkdir(parents=True, exist_ok=True)
    buckets = {}
    for it in items:
        buckets.setdefault(it["category"], []).append(it)

    for cat, lst in buckets.items():
        lst.sort(key=lambda x: x["title"].lower())
        lines = [f"# {cat.title()} runbooks\n"]
        for it in lst:
            rel_path = "../" + it["path"].lstrip("./")  # from by-category/* back to runbooks/*
            lines.append(f"- [{it['title']}]({rel_path})")
        write_text(BYCAT_DIR / f"{cat}.md", "\n".join(lines) + "\n")


def _render_readme_block(items):
    pills = " · ".join(f"[{c} ({n})](./by-category/{c}.md)" for c, n in sorted(_counts(items).items()))
    now = utc_now()
    out = []
    out.append(f"**Categories:** {pills}\n")
    out.append("For detailed metadata (severity, timestamps), see the [full index](./000-INDEX.md).\n")
    out.append("\n---\n")
    out.append(f"<details>\n  <summary><strong>All runbooks</strong> ({len(items)}) — click to expand</summary>\n\n")
    out.extend(f"- [{it['title']}]({it['path']})" for it in items)
    out.append("\n</details>\n")
    out.append(f"\n<sub>Last generated: {now}</sub>\n")
    return "\n".join(out)


def patch_readme(items):
    if not README.exists():
        if README_TMPL.exists():
            write_text(README, load_text(README_TMPL))
        else:
            write_text(README, "# Runbooks — Operational Procedures\n\n" + MARK_START + "\n" + MARK_END + "\n")
    new_block = _render_readme_block(items)
    write_text(README, replace_block(load_text(README), MARK_START, MARK_END, new_block))


def main():
    items = collect_items()
    write_000_index(items)
    write_by_category(items)
    patch_readme(items)
    print(f"Updated {README}, wrote {INDEX} and {BYCAT_DIR}/*")


if __name__ == "__main__":
    main()
