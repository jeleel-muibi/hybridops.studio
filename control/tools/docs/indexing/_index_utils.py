#!/usr/bin/env python3
# _index_utils.py - Shared helpers for documentation index generation
# Author: HybridOps.Studio
# Date: 2025-11-21

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Tuple, Dict, Any, List

import io

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None  # type: ignore[assignment]


def load_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def parse_front_matter(text: str) -> Tuple[Dict[str, Any], str]:
    """Return (front_matter_dict, body) from a Markdown string."""
    if not text.startswith("---"):
        return {}, text

    stream = io.StringIO(text)
    first = stream.readline()
    if not first.strip().startswith("---"):
        return {}, text

    fm_lines: List[str] = []
    for line in stream:
        if line.strip().startswith("---"):
            break
        fm_lines.append(line)

    fm_text = "".join(fm_lines).strip()
    body = stream.read()

    if not fm_text or yaml is None:
        return {}, body

    data = yaml.safe_load(fm_text) or {}
    if not isinstance(data, dict):
        return {}, body

    return data, body


def replace_block(text: str, start_marker: str, end_marker: str, block: str) -> str:
    start_idx = text.find(start_marker)
    end_idx = text.find(end_marker)

    if start_idx == -1 or end_idx == -1 or end_idx < start_idx:
        parts = [text.rstrip(), "", start_marker, block, end_marker, ""]
        return "\n".join(parts)

    before = text[: start_idx + len(start_marker)]
    after = text[end_idx:]
    if not before.endswith("\n"):
        before += "\n"
    if not block.endswith("\n"):
        block += "\n"
    return before + block + after


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def slugify(value: str) -> str:
    value = value.strip().lower()
    if not value:
        return ""
    out: List[str] = []
    last_dash = False
    for ch in value:
        if ch.isalnum():
            out.append(ch)
            last_dash = False
        elif ch in (" ", "-", "_", "/"):
            if not last_dash:
                out.append("-")
                last_dash = True
        else:
            if not last_dash:
                out.append("-")
                last_dash = True
    slug = "".join(out).strip("-")
    return slug or "general"


def should_skip_file(rel_path: Path, ignore_folders: list[str] | None = None) -> bool:
    """Return True for files that should not appear in generated indexes."""
    parts = rel_path.parts
    name = rel_path.name
    lower = name.lower()

    if ignore_folders and any(p in ignore_folders for p in parts[:-1]):
        return True

    if not lower.endswith(".md"):
        return True

    if lower.startswith(".") or lower.startswith("_"):
        return True

    if lower in {"readme.md", "000-index.md"}:
        return True

    if lower.endswith(".tmpl.md"):
        return True

    stem = lower[:-3]
    if stem.endswith("_template") or stem.endswith("-template"):
        return True

    return False
