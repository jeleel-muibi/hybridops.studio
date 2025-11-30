#!/usr/bin/env python3
"""
Generate runbook indexes and category views.

Outputs:
- docs/runbooks/000-INDEX.md
- docs/runbooks/by-category/<category>.md
- Patches docs/runbooks/README.md between RUNBOOKS:INDEX markers.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List

from _index_utils import (
    load_text,
    write_text,
    parse_front_matter,
    replace_block,
    utc_now,
    slugify,
    should_skip_file,
)


ROOT = Path.cwd()
RUNBOOK_DIR = ROOT / "docs" / "runbooks"
README = RUNBOOK_DIR / "README.md"
README_TMPL = RUNBOOK_DIR / "README.tmpl.md"
INDEX = RUNBOOK_DIR / "000-INDEX.md"
BYCAT_DIR = RUNBOOK_DIR / "by-category"

MARK_START = "<!-- RUNBOOKS:INDEX START -->"
MARK_END = "<!-- RUNBOOKS:INDEX END -->"


@dataclass
class RunbookItem:
    title: str
    category: str
    severity: str
    last_updated: str
    rel_path: str
    access: str


def _first_h1_or_default(body: str, stem: str) -> str:
    for line in body.splitlines():
        if line.strip().startswith("# "):
            return line.lstrip("# ").strip()
    return stem.replace("_", " ").replace("-", " ").title()


def collect_items() -> List[RunbookItem]:
    items: List[RunbookItem] = []

    if not RUNBOOK_DIR.exists():
        return items

    for path in RUNBOOK_DIR.rglob("*.md"):
        rel = path.relative_to(RUNBOOK_DIR)

        if should_skip_file(rel, ignore_folders=["by-category"]):
            continue

        fm, body = parse_front_matter(load_text(path))

        title = (fm.get("title") or "").strip()
        if not title:
            title = _first_h1_or_default(body, path.stem)

        raw_category = fm.get("category")
        if raw_category:
            category = slugify(str(raw_category))
        elif len(rel.parts) > 1:
            category = slugify(rel.parts[0])
        else:
            category = "general"

        severity = str(fm.get("severity") or "").strip().upper()
        if not severity:
            severity = "P3"

        fm_last = fm.get("last_updated")
        if hasattr(fm_last, "isoformat"):
            last_updated = fm_last.isoformat()[:10]
        else:
            last_updated = str(fm_last or "").strip()
        if not last_updated:
            mtime = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc)
            last_updated = mtime.strftime("%Y-%m-%d")

        rel_path = "./" + str(rel).replace("\\", "/")
        access = str(fm.get("access") or "public").strip() or "public"

        items.append(
            RunbookItem(
                title=title,
                category=category,
                severity=severity,
                last_updated=last_updated,
                rel_path=rel_path,
                access=access,
            )
        )

    items.sort(key=lambda it: (it.category, it.title.lower()))
    return items


def _category_counts(items: List[RunbookItem]) -> Dict[str, int]:
    counts: Dict[str, int] = {}
    for it in items:
        counts[it.category] = counts.get(it.category, 0) + 1
    return counts


def write_000_index(items: List[RunbookItem]) -> None:
    now = utc_now()
    counts = _category_counts(items)

    lines: List[str] = []
    lines.append("# 000-INDEX — Runbooks")
    lines.append(f"_Last updated: {now}_")
    lines.append("")
    lines.append(
        "Tabular summary of reproducible operational procedures grouped by "
        "category, severity, and access."
    )
    lines.append("")

    if counts:
        pills = " · ".join(
            f"[{cat} ({count})](./by-category/{cat}.md)"
            for cat, count in sorted(counts.items())
        )
        lines.append(f"**Categories:** {pills}")
        lines.append("")

    lines.append("**Legend:** P1 = critical · P2 = high · P3 = normal")
    lines.append("")
    lines.append("| Runbook | Category | Severity | Access | Last updated |")
    lines.append("|:--------|:--------:|:--------:|:------:|:------------:|")

    for it in items:
        lines.append(
            f"| [{it.title}]({it.rel_path}) | {it.category} | "
            f"{it.severity} | {it.access} | {it.last_updated} |"
        )

    lines.append("")
    lines.append("- [Back to RUNBOOK overview](./README.md)")
    lines.append("- [Back to Docs Home](../README.md)")
    lines.append("")
    write_text(INDEX, "\n".join(lines) + "\n")


def write_by_category(items: List[RunbookItem]) -> None:
    BYCAT_DIR.mkdir(parents=True, exist_ok=True)
    buckets: Dict[str, List[RunbookItem]] = {}

    for it in items:
        buckets.setdefault(it.category, []).append(it)

    for cat, bucket in buckets.items():
        bucket.sort(key=lambda it: it.title.lower())
        lines: List[str] = []
        label = cat.replace("-", " ").title()
        lines.append(f"# {label} runbooks")
        lines.append("")
        lines.append(f"Operational runbooks tagged as `{cat}`.")
        lines.append("")
        lines.append("| Runbook | Severity | Access | Last updated |")
        lines.append("|:--------|:--------:|:------:|:------------:|")
        for it in bucket:
            rel = "../" + it.rel_path.lstrip("./")
            lines.append(
                f"| [{it.title}]({rel}) | {it.severity} | {it.access} | {it.last_updated} |"
            )
        lines.append("")
        lines.append("[Back to RUNBOOK index](../000-INDEX.md)")
        lines.append("")
        lines.append("[Back to Docs Home](../README.md)")
        lines.append("")
        write_text(BYCAT_DIR / f"{cat}.md", "\n".join(lines))


def _ensure_readme_exists() -> None:
    if README.exists():
        return
    if README_TMPL.exists():
        write_text(README, load_text(README_TMPL))
        return

    skeleton = f"""# Runbooks — Operational Procedures

Generated index of operational procedures for HybridOps.Studio.

## Runbook Catalog

{MARK_START}
_No runbooks found._
{MARK_END}
"""
    write_text(README, skeleton)


def _render_readme_block(items: List[RunbookItem]) -> str:
    counts = _category_counts(items)
    now = utc_now()

    lines: List[str] = []
    lines.append("Runbook catalog")
    lines.append("")
    if counts:
        pills = " · ".join(
            f"[{cat}](./by-category/{cat}.md) ({count})"
            for cat, count in sorted(counts.items())
        )
        lines.append(f"**Categories:** {pills}")
        lines.append("")
    lines.append("---")
    lines.append("")
    lines.append(f"??? note \"All runbooks ({len(items)}) — click to browse\"")
    lines.append("")
    for it in items:
        lines.append(f"    - [{it.title}]({it.rel_path}) — {it.access}")
    lines.append("")
    lines.append(f"_Last generated: {now}_")
    lines.append("")
    return "\n".join(lines)


def patch_readme(items: List[RunbookItem]) -> None:
    _ensure_readme_exists()
    current = load_text(README)
    block = _render_readme_block(items)
    updated = replace_block(current, MARK_START, MARK_END, block)
    write_text(README, updated)


def main() -> None:
    items = collect_items()
    write_000_index(items)
    write_by_category(items)
    patch_readme(items)
    print(f"Generation complete: {len(items)} runbooks processed.")


if __name__ == "__main__":
    main()
