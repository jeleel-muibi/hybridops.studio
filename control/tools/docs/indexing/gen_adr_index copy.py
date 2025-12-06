#!/usr/bin/env python3
"""Generate ADR domain and index views.

Outputs:
- docs/adr/README.md (patched between ADR:DOMAINS and ADR:INDEX markers)
- docs/adr/by-domain/<domain>.md
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple

from _index_utils import load_text, write_text, parse_front_matter, replace_block


ROOT = Path.cwd()
ADR_DIR = ROOT / "docs" / "adr"
README = ADR_DIR / "README.md"
README_TMPL = ADR_DIR / "README.tmpl.md"
BYDOMAIN_DIR = ADR_DIR / "by-domain"

DOMAINS_START = "<!-- ADR:DOMAINS START -->"
DOMAINS_END = "<!-- ADR:DOMAINS END -->"

INDEX_START = "<!-- ADR:INDEX START -->"
INDEX_END = "<!-- ADR:INDEX END -->"


@dataclass
class AdrItem:
    id: str
    num: int
    title: str
    status: str
    date: str
    access: str
    domains: List[str]
    filename: str


def _as_str(value, default: str = "") -> str:
    if value is None:
        return default
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value).strip() or default


def _parse_id(raw_id: str, fallback: str) -> Tuple[str, int]:
    value = (raw_id or fallback).strip()
    if not value.upper().startswith("ADR-"):
        raise ValueError(f"Invalid ADR id: {value}")
    tail = value.split("-", 1)[1]
    num = int(tail)
    return f"ADR-{tail.zfill(4)}", num


def collect_adrs() -> List[AdrItem]:
    items: List[AdrItem] = []

    if not ADR_DIR.exists():
        return items

    for path in ADR_DIR.glob("ADR-*.md"):
        if path.name.lower() == "readme.md":
            continue

        text = load_text(path)
        fm, _ = parse_front_matter(text)

        try:
            adr_id, num = _parse_id(fm.get("id"), path.stem)
        except Exception:
            continue

        title = _as_str(fm.get("title"))
        if not title:
            continue

        status = _as_str(fm.get("status"))
        date = _as_str(fm.get("date"))
        access = _as_str(fm.get("access"), default="public") or "public"

        domains_raw = fm.get("domains") or []
        if isinstance(domains_raw, str):
            domains = [domains_raw.strip().lower()] if domains_raw.strip() else []
        else:
            domains = [str(d).strip().lower() for d in domains_raw if str(d).strip()]

        items.append(
            AdrItem(
                id=adr_id,
                num=num,
                title=title,
                status=status,
                date=date,
                access=access,
                domains=domains,
                filename=path.name,
            )
        )

    items.sort(key=lambda it: it.num)
    return items


def _domain_counts(items: List[AdrItem]) -> Dict[str, int]:
    counts: Dict[str, int] = {}
    for it in items:
        if not it.domains:
            counts["uncategorised"] = counts.get("unccategorised", 0) + 1
        else:
            for d in it.domains:
                counts[d] = counts.get(d, 0) + 1
    return counts


def _domain_buckets(items: List[AdrItem]) -> Dict[str, List[AdrItem]]:
    buckets: Dict[str, List[AdrItem]] = {}
    for it in items:
        if not it.domains:
            buckets.setdefault("uncategorised", []).append(it)
        else:
            for d in it.domains:
                buckets.setdefault(d, []).append(it)
    return buckets


def _domain_label(dom: str) -> str:
    return dom.replace("-", " ").title()


def render_domains_block(items: List[AdrItem]) -> str:
    counts = _domain_counts(items)
    if not counts:
        return "_No ADRs found._"

    parts: List[str] = []
    for dom, count in sorted(counts.items()):
        href = f"./by-domain/{dom}.md"
        label = _domain_label(dom)
        parts.append(f"[{label} ({count})]({href})")
    return " · ".join(parts)


def render_index_block(items: List[AdrItem]) -> str:
    if not items:
        return "_No ADRs found._"

    lines: List[str] = []
    lines.append(f'??? note "All ADRs ({len(items)}) — click to browse"')
    lines.append("")

    for it in items:
        label = it.title
        href = f"./{it.filename}"

        meta_bits: List[str] = []
        if it.status:
            meta_bits.append(it.status)
        if it.access:
            meta_bits.append(it.access)

        meta = f" — {' · '.join(meta_bits)}" if meta_bits else ""
        lines.append(f"    - [{label}]({href}){meta}")

    lines.append("")
    return "\n".join(lines)


def write_by_domain(items: List[AdrItem]) -> None:
    BYDOMAIN_DIR.mkdir(parents=True, exist_ok=True)
    buckets = _domain_buckets(items)

    for dom, bucket in buckets.items():
        bucket.sort(key=lambda it: it.num)
        lines: List[str] = []
        label = _domain_label(dom)
        lines.append(f"# ADRs — {label}")
        lines.append("")
        lines.append(f"ADRs primarily tagged with the **{label}** domain.")
        lines.append("")
        lines.append("| Title | Status | Access | Date |")
        lines.append("|:------|:------:|:------:|:----:|")
        for it in bucket:
            href = f"../{it.filename}"
            title_label = f"{it.id} — {it.title}"
            lines.append(
                f"| [{title_label}]({href}) | {it.status} | {it.access} | {it.date} |"
            )
        lines.append("")
        write_text(BYDOMAIN_DIR / f"{dom}.md", "\n".join(lines))


def _ensure_readme_exists() -> None:
    if README.exists():
        return
    if README_TMPL.exists():
        write_text(README, load_text(README_TMPL))
        return

    skeleton = f"""# Architecture Decision Records (ADRs)

Project-wide decision log for HybridOps.Studio.

## Domains

{DOMAINS_START}
_No ADRs found._
{DOMAINS_END}

## Index

{INDEX_START}
_No ADRs found._
{INDEX_END}
"""
    write_text(README, skeleton)


def patch_readme(items: List[AdrItem]) -> None:
    _ensure_readme_exists()
    current = load_text(README)
    domains_block = render_domains_block(items)
    index_block = render_index_block(items)

    updated = replace_block(current, DOMAINS_START, DOMAINS_END, domains_block)
    updated = replace_block(updated, INDEX_START, INDEX_END, index_block)
    write_text(README, updated)


def main() -> None:
    items = collect_adrs()
    write_by_domain(items)
    patch_readme(items)
    print(f"Generation complete: {len(items)} ADRs processed.")


if __name__ == "__main__":
    main()
