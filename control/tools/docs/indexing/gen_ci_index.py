#!/usr/bin/env python3
# SPDX-License-Identifier: MIT-0
"""Generate CI/CD indexes and area views.

Outputs:
- docs/ci/000-INDEX.md
- docs/ci/by-area/<area>.md
- Patches docs/ci/README.md between CI:AREAS and CI:INDEX markers.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List

from _index_utils import (
    load_text,
    write_text,
    parse_front_matter,
    replace_block,
    utc_now,
)

CI_ROOT = Path("docs/ci")
CI_INDEX = CI_ROOT / "000-INDEX.md"
CI_BY_AREA_ROOT = CI_ROOT / "by-area"
README = CI_ROOT / "README.md"
README_TMPL = CI_ROOT / "README.tmpl.md"

AREAS_START = "<!-- CI:AREAS START -->"
AREAS_END = "<!-- CI:AREAS END -->"
INDEX_START = "<!-- CI:INDEX START -->"
INDEX_END = "<!-- CI:INDEX END -->"


@dataclass
class CiItem:
    slug: str
    title: str
    area: str
    access: str
    updated: str
    path: Path


def _is_ci_doc(path: Path) -> bool:
    if path.suffix.lower() != ".md":
        return False

    name = path.name.lower()
    if name.startswith(".") or name.startswith("_"):
        return False

    if name in {"readme.md", "000-index.md"}:
        return False

    if name.endswith(".tmpl.md"):
        return False

    stem = name[:-3]
    if stem.endswith("_template") or stem.endswith("-template"):
        return False

    return True


def _area_label(area: str) -> str:
    return area.replace("-", " ").title()


def collect_items() -> List[CiItem]:
    items: List[CiItem] = []

    for path in sorted(CI_ROOT.rglob("*.md")):
        if not _is_ci_doc(path):
            continue

        fm, _ = parse_front_matter(load_text(path))

        title = (fm.get("title") or "").strip()
        if not title:
            title = path.stem.replace("_", " ").title()

        area = (fm.get("area") or "general").strip() or "general"
        access = (fm.get("access") or "public").strip() or "public"
        updated_raw = (fm.get("updated") or fm.get("date") or "").strip()
        updated = updated_raw or utc_now().split("T")[0]

        rel = path.relative_to(CI_ROOT)
        slug = rel.with_suffix("").as_posix()

        items.append(
            CiItem(
                slug=slug,
                title=title,
                area=area,
                access=access,
                updated=updated,
                path=path,
            )
        )

    items.sort(key=lambda it: (it.area, it.slug))
    return items


def _group_by_area(items: List[CiItem]) -> Dict[str, List[CiItem]]:
    groups: Dict[str, List[CiItem]] = {}
    for it in items:
        groups.setdefault(it.area, []).append(it)
    return dict(sorted(groups.items(), key=lambda kv: kv[0]))


def _render_table(items: List[CiItem], link_prefix: str = "./") -> str:
    if not items:
        return "_No CI/CD pipelines found._"

    lines: List[str] = []
    lines.append("| Pipeline | Area | Access | Updated |")
    lines.append("|:---------|:-----|:------:|:-------:|")

    for it in items:
        href = f"{link_prefix}{it.slug}.md"
        label = it.title
        area = _area_label(it.area)
        lines.append(
            f"| [{label}]({href}) | {area} | {it.access} | {it.updated} |"
        )

    return "\n".join(lines)


def write_000_index(items: List[CiItem]) -> None:
    groups = _group_by_area(items)

    lines: List[str] = []
    lines.append("# CI/CD Pipelines Index")
    lines.append("")
    lines.append("Summary by area:")
    lines.append("")
    for area, group in groups.items():
        lines.append(f"- [{_area_label(area)} ({len(group)})](./by-area/{area}.md)")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## All Pipelines")
    lines.append("")
    lines.append(_render_table(items))
    lines.append("")
    write_text(CI_INDEX, "\n".join(lines))


def write_by_area(items: List[CiItem]) -> None:
    groups = _group_by_area(items)
    CI_BY_AREA_ROOT.mkdir(parents=True, exist_ok=True)

    for area, group in groups.items():
        dest = CI_BY_AREA_ROOT / f"{area}.md"

        lines: List[str] = []
        lines.append(f"# CI/CD Pipelines — {_area_label(area)}")
        lines.append("")
        lines.append(f"Pipelines tagged as `{area}`.")
        lines.append("")
        # from docs/ci/by-area/<area>.md back to docs/ci/*.md
        lines.append(_render_table(group, link_prefix="../"))
        lines.append("")
        lines.append("[Back to CI/CD index](../000-INDEX.md)")
        lines.append("")
        write_text(dest, "\n".join(lines))


def _render_areas_block(items: List[CiItem]) -> str:
    """Render CI:AREAS as horizontal pills (for README)."""
    groups = _group_by_area(items)
    if not groups:
        return "_No CI/CD pipelines found._\n"

    pills: List[str] = []
    for area, group in groups.items():
        label = f"{_area_label(area)} ({len(group)})"
        href = f"./by-area/{area}.md"
        pills.append(f"[{label}]({href})")

    return " · ".join(pills) + "\n"


def _render_index_block(items: List[CiItem]) -> str:
    """Render a wrapped, access-suffixed bullet index for docs/ci/README.md."""
    if not items:
        return "_No CI/CD pipelines found._\n"

    lines: List[str] = []
    lines.append(f'??? note "All CI/CD pipelines ({len(items)}) — click to browse"')
    lines.append("")

    for it in items:
        href = f"./{it.slug}.md"
        label = it.title
        access = it.access or "public"
        lines.append(f"    - [{label}]({href}) — **{access}**")

    lines.append("")
    return "\n".join(lines)


def patch_readme(items: List[CiItem]) -> None:
    if README_TMPL.exists():
        base = load_text(README_TMPL)
    else:
        base = load_text(README)

    areas_block = _render_areas_block(items)
    index_block = _render_index_block(items)

    updated = replace_block(base, AREAS_START, AREAS_END, areas_block)
    updated = replace_block(updated, INDEX_START, INDEX_END, index_block)
    write_text(README, updated)


def main() -> None:
    items = collect_items()
    write_000_index(items)
    write_by_area(items)
    patch_readme(items)
    print(f"Generation complete: {len(items)} CI/CD pipelines processed.")


if __name__ == "__main__":
    main()
