#!/usr/bin/env python3
"""
Shared helpers for indexing scripts.

Functions
- load_text(path):         Read text (UTF-8 with Latin-1 fallback).
- write_text(path, text):  Ensure parent dirs and write UTF-8 text.
- parse_front_matter(txt): Return (front_matter: dict, body: str). YAML if available; tolerant to BOM.
- replace_block(src, start, end, payload): Replace a delimited region.
- utc_now():               UTC timestamp (YYYY-MM-DD HH:MM UTC).
- slugify(s):              Lowercase, hyphenate, restrict to [a-z0-9-].
- normalize_domains(fm):   From fm['domain'] or fm['domains'] (str or list); default ['uncategorized'].
"""
from pathlib import Path
from datetime import datetime, timezone
import re

try:
    import yaml  # type: ignore
except Exception:
    yaml = None


def load_text(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return p.read_text(encoding="latin-1")


def write_text(p: Path, s: str) -> None:
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding="utf-8")


def parse_front_matter(txt: str):
    """Parse YAML front matter. Return (dict, body). Tolerates UTF-8 BOM and leading whitespace."""
    m = re.match(r"(?s)^\ufeff?\s*---\n(.*?)\n---\n(.*)$", txt)
    if not m:
        return {}, txt
    fm_raw, body = m.group(1), m.group(2)
    if yaml:
        try:
            fm = yaml.safe_load(fm_raw) or {}
        except Exception:
            fm = {}
    else:
        fm = {}
        for line in fm_raw.splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm, body


def replace_block(src: str, start: str, end: str, payload: str) -> str:
    pattern = re.compile(re.escape(start) + r"(.*?)" + re.escape(end), re.S)
    if not pattern.search(src):
        return src.rstrip() + f"\n\n{start}\n{payload}{end}\n"
    return pattern.sub(start + "\n" + payload + end, src)


def utc_now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")


def slugify(s: str) -> str:
    s = s.lower().replace(" ", "-")
    s = re.sub(r"[^a-z0-9\-]+", "-", s)
    s = re.sub(r"-+", "-", s)
    return s.strip("-")


def normalize_domains(fm: dict) -> list[str]:
    vals = []
    for key in ("domain", "domains"):
        if key in fm and fm[key] is not None:
            v = fm[key]
            if isinstance(v, str) and v.strip():
                vals.append(v.strip())
            elif isinstance(v, (list, tuple)):
                vals.extend([str(x).strip() for x in v if str(x).strip()])
    if not vals:
        vals = ["uncategorized"]
    out, seen = [], set()
    for d in vals:
        sd = slugify(d)
        if sd and sd not in seen:
            seen.add(sd)
            out.append(sd)
    return out
