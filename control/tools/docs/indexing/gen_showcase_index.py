#!/usr/bin/env python3
# SPDX-License-Identifier: MIT-0
"""HybridOps.Studio — showcase index generator.

Generates:
- docs/showcases/README.md               (root showcase catalogue)
- docs/showcases/by-audience/*.md        (audience-specific views)

Source:
- docs/showcases/**/README.md
- docs/showcases/templates/README.tmpl.md
- docs/showcases/templates/README.by-audience.tmpl.md
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
    slugify,
)

ROOT = Path.cwd()
SHOWCASE_DIR = ROOT / "docs" / "showcases"
BY_AUDIENCE_DIR = SHOWCASE_DIR / "by-audience"

ROOT_INDEX_TEMPLATE = SHOWCASE_DIR / "templates" / "README.tmpl.md"
ROOT_INDEX_OUTPUT = SHOWCASE_DIR / "README.md"

BY_AUDIENCE_TEMPLATE = SHOWCASE_DIR / "templates" / "README.by-audience.tmpl.md"

ROOT_INDEX_START = "<!-- SHOWCASE:INDEX START -->"
ROOT_INDEX_END = "<!-- SHOWCASE:INDEX END -->"

ROOT_AUDIENCE_START = "<!-- SHOWCASE:BY_AUDIENCE START -->"
ROOT_AUDIENCE_END = "<!-- SHOWCASE:BY_AUDIENCE END -->"

BY_AUDIENCE_INDEX_START = "<!-- SHOWCASE_BY_AUDIENCE:INDEX START -->"
BY_AUDIENCE_INDEX_END = "<!-- SHOWCASE_BY_AUDIENCE:INDEX END -->"


@dataclass
class ShowcaseItem:
    title: str
    slug: str
    rel_path: str
    audiences: List[str]
    access: str
    tags: List[str]
    topic: str


def _first_h1_or_default(body: str, stem: str) -> str:
    for line in body.splitlines():
        if line.strip().startswith("# "):
            return line.lstrip("# ").strip()
    return stem.replace("_", " ").replace("-", " ").title()


def collect_showcase_items() -> List[ShowcaseItem]:
    items: List[ShowcaseItem] = []

    if not SHOWCASE_DIR.exists():
        return items

    for path in SHOWCASE_DIR.rglob("README.md"):
        rel = path.relative_to(SHOWCASE_DIR)

        # Skip the root catalogue and non-content folders
        if rel == Path("README.md"):
            continue
        if rel.parts[0] in {"by-audience", "templates"}:
            continue

        fm, body = parse_front_matter(load_text(path))

        title_raw = (fm.get("title") or "").strip()
        title = title_raw or _first_h1_or_default(body, path.stem)

        # Top-level folder under docs/showcases becomes the slug
        slug = rel.parts[0]

        # Audiences (list or string); default to "general"
        raw_audience = fm.get("audience") or []
        audiences: List[str] = []
        if isinstance(raw_audience, str):
            value = raw_audience.strip()
            if value:
                audiences.append(slugify(value))
        elif isinstance(raw_audience, list):
            for entry in raw_audience:
                value = str(entry).strip()
                if value:
                    audiences.append(slugify(value))
        if not audiences:
            audiences = ["general"]

        # Access defaults to public
        access_raw = (fm.get("access") or "public").strip().lower()
        access = access_raw or "public"

        # Tags (optional, not used in index yet but kept for future)
        raw_tags = fm.get("tags") or []
        tags: List[str] = []
        if isinstance(raw_tags, str):
            for part in raw_tags.split(","):
                value = part.strip()
                if value:
                    tags.append(value)
        elif isinstance(raw_tags, list):
            for entry in raw_tags:
                value = str(entry).strip()
                if value:
                    tags.append(value)

        topic = str(fm.get("topic") or "").strip()

        rel_path = "./" + str(rel).replace("\\", "/")

        items.append(
            ShowcaseItem(
                title=title,
                slug=slug,
                rel_path=rel_path,
                audiences=audiences,
                access=access,
                tags=tags,
                topic=topic,
            )
        )

    return items


def _render_root_index(items: List[ShowcaseItem]) -> str:
    """Render the root showcase catalogue as a collapsible bullet list."""
    if not items:
        return "_No showcases registered yet._"

    lines: List[str] = []
    lines.append(f'??? note "All showcases ({len(items)}) — click to browse"')
    lines.append("")

    for item in sorted(items, key=lambda i: i.title.lower()):
        link = f"./{item.slug}/README.md"

        # Only show access when it's not public to avoid noise
        suffix = ""
        if item.access and item.access != "public":
            suffix = f" — {item.access}"

        # 4 spaces indent so Markdown treats it as a list inside the admonition
        lines.append(f"    - [{item.title}]({link}){suffix}")

    lines.append("")
    return "\n".join(lines)


def _render_audience_list(by_audience: Dict[str, List[ShowcaseItem]]) -> str:
    """Inline pill links to each audience view, used in the root catalogue."""
    if not by_audience:
        return "_No audience groups discovered yet._"

    links: List[str] = []
    for audience_key in sorted(by_audience.keys()):
        label = audience_key.replace("-", " ").title()
        link = f"./by-audience/{audience_key}.md"
        links.append(f"[{label}]({link})")
    return " · ".join(links)


def _render_audience_block(items: List[ShowcaseItem]) -> str:
    """Per-audience page content (simple bullet list)."""
    lines: List[str] = []

    for item in sorted(items, key=lambda i: i.title.lower()):
        rel = "../" + item.rel_path.lstrip("./")
        meta: List[str] = []
        if item.access and item.access != "public":
            meta.append(item.access)
        suffix = f"  (_{', '.join(meta)}_)" if meta else ""
        lines.append(f"- [{item.title}]({rel}){suffix}")

    if not lines:
        lines.append("_No showcases registered for this audience yet._")

    return "\n".join(lines)


def _load_template(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"Template not found: {path}")
    return load_text(path)


def write_root_index(
    items: List[ShowcaseItem],
    by_audience: Dict[str, List[ShowcaseItem]],
) -> None:
    template = _load_template(ROOT_INDEX_TEMPLATE)
    index_block = _render_root_index(items)
    audience_block = _render_audience_list(by_audience)

    rendered = replace_block(template, ROOT_INDEX_START, ROOT_INDEX_END, index_block)
    rendered = replace_block(
        rendered,
        ROOT_AUDIENCE_START,
        ROOT_AUDIENCE_END,
        audience_block,
    )
    write_text(ROOT_INDEX_OUTPUT, rendered)


def write_by_audience_pages(items: List[ShowcaseItem]) -> Dict[str, List[ShowcaseItem]]:
    BY_AUDIENCE_DIR.mkdir(parents=True, exist_ok=True)

    by_audience: Dict[str, List[ShowcaseItem]] = {}
    for item in items:
        for audience in item.audiences:
            by_audience.setdefault(audience, []).append(item)

    template = _load_template(BY_AUDIENCE_TEMPLATE)

    for audience_key, audience_items in sorted(by_audience.items(), key=lambda kv: kv[0]):
        label = audience_key.replace("-", " ").title()

        page = template.replace("{{AUDIENCE_KEY}}", audience_key).replace(
            "{{AUDIENCE_LABEL}}",
            label,
        )
        block = _render_audience_block(audience_items)
        rendered = replace_block(
            page,
            BY_AUDIENCE_INDEX_START,
            BY_AUDIENCE_INDEX_END,
            block,
        )

        out_path = BY_AUDIENCE_DIR / f"{audience_key}.md"
        write_text(out_path, rendered)

    return by_audience


def main() -> None:
    items = collect_showcase_items()
    by_audience = write_by_audience_pages(items)
    write_root_index(items, by_audience)
    print(
        f"Showcase index generated: {len(items)} showcase(s), "
        f"{len(by_audience)} audience view(s)."
    )


if __name__ == "__main__":
    main()
