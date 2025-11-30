#!/usr/bin/env python3
# build_mkdocs_trees.py - Build public and academy documentation trees from docs/
# Author: HybridOps.Studio
# Date: 2025-11-21

from __future__ import annotations

import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Tuple

SCRIPT_DIR = Path(__file__).resolve().parent
INDEXING_DIR = SCRIPT_DIR.parent.parent / "indexing"
sys.path.insert(0, str(INDEXING_DIR))

from _index_utils import load_text, write_text, parse_front_matter  # type: ignore[import]


ROOT = Path.cwd()
SOURCE_DOCS = ROOT / "docs"
PUBLIC_ROOT = ROOT / "deployment" / "build" / "docs" / "public"
ACADEMY_ROOT = ROOT / "deployment" / "build" / "docs" / "academy"


@dataclass
class ParsedMarkdown:
    front_matter: Dict
    body: str
    fm_block: str | None
    raw: str


def _split_front_matter(raw: str) -> Tuple[str | None, str]:
    if not raw.startswith("---"):
        return None, raw
    lines = raw.splitlines(keepends=True)
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return None, raw
    fm_block = "".join(lines[: end_idx + 1]).strip() + "\n"
    body = "".join(lines[end_idx + 1 :]).lstrip("\n")
    return fm_block, body


def _parse_markdown(path: Path) -> ParsedMarkdown:
    raw = load_text(path)
    fm_block, _ = _split_front_matter(raw)
    fm, body = parse_front_matter(raw)
    if not isinstance(fm, dict):
        fm = {}
    return ParsedMarkdown(front_matter=fm, body=body, fm_block=fm_block, raw=raw)


def _normalize_access(fm: Dict) -> str:
    value = str(fm.get("access") or "public").strip().lower()
    if value not in {"public", "academy", "mixed"}:
        return "public"
    return value


def _is_template_or_draft(fm: Dict) -> bool:
    if str(fm.get("template") or "").strip().lower() == "true":
        return True
    if str(fm.get("draft") or "").strip().lower() == "true":
        return True
    return False


def _derive_title(md: ParsedMarkdown, src: Path) -> str:
    title = str(md.front_matter.get("title") or "").strip()
    if title:
        return title
    for line in md.body.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped.lstrip("# ").strip()
    return src.stem.replace("_", " ").replace("-", " ").title()


def _stub_blurb(fm: Dict) -> tuple[str, list[str], str, str]:
    stub_cfg = fm.get("stub") or {}
    if not isinstance(stub_cfg, dict):
        stub_cfg = {}
    blurb = str(stub_cfg.get("blurb") or "").strip()
    if not blurb:
        blurb = (
            "This document is part of the HybridOps Academy teaching material.\n\n"
            "The public site shows a high-level summary; the full narrative, labs, and "
            "guided walkthrough are delivered in HybridOps Academy."
        )
    highlights_raw = stub_cfg.get("highlights") or []
    if isinstance(highlights_raw, str):
        highlights = [highlights_raw.strip()] if highlights_raw.strip() else []
    else:
        highlights = [str(h).strip() for h in highlights_raw if str(h).strip()]
    cta_url = str(stub_cfg.get("cta_url") or "").strip()
    cta_label = str(stub_cfg.get("cta_label") or "").strip() or "View full content on HybridOps Academy"
    return blurb, highlights, cta_url, cta_label


def _build_stub_markdown(md: ParsedMarkdown, src: Path) -> str:
    fm_block = md.fm_block
    if not fm_block:
        fm_block = "---\naccess: academy\nstub_built: true\n---\n"
    title = _derive_title(md, src)
    blurb, highlights, cta_url, cta_label = _stub_blurb(md.front_matter)

    parts: list[str] = [fm_block.rstrip(), "", f"# {title}", "", blurb, ""]
    if highlights:
        parts.append("**Highlights:**")
        parts.extend(f"- {h}" for h in highlights)
        parts.append("")
    if cta_url:
        parts.append(f"[{cta_label}]({cta_url})")
        parts.append("")
    return "\n".join(parts).rstrip() + "\n"


def _clean_root(root: Path) -> None:
    if root.exists():
        shutil.rmtree(root)
    root.mkdir(parents=True, exist_ok=True)


def _copy_binary(src: Path, rel: Path) -> None:
    dst_pub = PUBLIC_ROOT / rel
    dst_academy = ACADEMY_ROOT / rel
    dst_pub.parent.mkdir(parents=True, exist_ok=True)
    dst_academy.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst_pub)
    shutil.copy2(src, dst_academy)


def _is_index_or_readme_for_academy(rel: Path) -> bool:
    if len(rel.parts) < 2:
        return False
    root = rel.parts[0]
    if root not in {"adr", "runbooks", "howto", "ci", "case-studies"}:
        return False
    if rel.name not in {"README.md", "000-INDEX.md"}:
        return False
    return True


def _remove_access_column_from_tables(text: str) -> str:
    lines = text.splitlines()
    out: list[str] = []
    i = 0

    while i < len(lines):
        line = lines[i]

        if "|" in line and "access" in line.lower():
            if i + 1 < len(lines) and "|" in lines[i + 1] and "---" in lines[i + 1]:
                header = line
                separator = lines[i + 1]

                header_cells = [c.strip() for c in header.strip().strip("|").split("|")]
                try:
                    access_idx = next(
                        idx
                        for idx, cell in enumerate(header_cells)
                        if cell.lower() == "access"
                    )
                except StopIteration:
                    out.append(line)
                    i += 1
                    continue

                def strip_col(row: str) -> str:
                    cells = row.strip().strip("|").split("|")
                    if len(cells) <= access_idx:
                        return row
                    del cells[access_idx]
                    cells = [c.strip() for c in cells]
                    return "| " + " | ".join(cells) + " |"

                out.append(strip_col(header))
                out.append(strip_col(separator))
                i += 2

                while i < len(lines) and "|" in lines[i]:
                    out.append(strip_col(lines[i]))
                    i += 1
                continue

        out.append(line)
        i += 1

    return "\n".join(out)


def _strip_access_for_academy(_rel: Path, text: str) -> str:
    lines = text.splitlines()
    filtered: list[str] = []

    for ln in lines:
        low = ln.lower()

        # Drop helper lines about access flags / labels / ADR-0021
        if "access flags" in low and "access model" in low:
            continue
        if "access labels" in low:
            continue
        if "adr-0021" in low and "access" in low:
            continue

        # Scrub trailing " — public"/" — academy"/" — mixed" and " · public"/etc.
        stripped = re.sub(
            r"\s+—\s*(public|academy|mixed)\b",
            "",
            ln,
            flags=re.IGNORECASE,
        )
        stripped = re.sub(
            r"\s+·\s*(public|academy|mixed)\b",
            "",
            stripped,
            flags=re.IGNORECASE,
        )

        filtered.append(stripped)

    joined = "\n".join(filtered)
    return _remove_access_column_from_tables(joined)


def _copy_markdown(src: Path, rel: Path) -> None:
    md = _parse_markdown(src)
    fm = md.front_matter

    if _is_template_or_draft(fm):
        return

    access = _normalize_access(fm)

    dst_pub = PUBLIC_ROOT / rel
    dst_academy = ACADEMY_ROOT / rel
    dst_pub.parent.mkdir(parents=True, exist_ok=True)
    dst_academy.parent.mkdir(parents=True, exist_ok=True)

    public_text = md.raw
    academy_text = md.raw

    if access == "academy":
        public_text = _build_stub_markdown(md, src)

    if _is_index_or_readme_for_academy(rel):
        academy_text = _strip_access_for_academy(rel, academy_text)

    write_text(dst_pub, public_text)
    write_text(dst_academy, academy_text)


def build_trees() -> None:
    if not SOURCE_DOCS.exists():
        raise SystemExit(f"Source docs directory not found: {SOURCE_DOCS}")

    _clean_root(PUBLIC_ROOT)
    _clean_root(ACADEMY_ROOT)

    for src in SOURCE_DOCS.rglob("*"):
        if src.is_dir():
            continue
        rel = src.relative_to(SOURCE_DOCS)
        if src.suffix.lower() == ".md":
            _copy_markdown(src, rel)
        else:
            _copy_binary(src, rel)


def main() -> None:
    build_trees()
    print(f"Public docs:   {PUBLIC_ROOT}")
    print(f"Academy docs:  {ACADEMY_ROOT}")


if __name__ == "__main__":
    main()
