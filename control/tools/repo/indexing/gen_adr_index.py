#!/usr/bin/env python3
# SPDX-License-Identifier: MIT-0
"""
HybridOps.Studio — ADR Index Generator
======================================

Purpose:
--------
Generates dynamic indexes for all Architecture Decision Records (ADRs)
under `docs/adr/`. It maintains an organized domain-based hierarchy
and regenerates the main ADR README with live counts and metadata.

Outputs:
--------
- docs/adr/README.md             → rebuilt from README.tmpl.md (or default template)
- docs/adr/by-domain/<domain>.md → per-domain categorized lists

Usage:
------
    $ make adr.index
or:
    $ python3 control/tools/repo/indexing/gen_adr_index.py

Conventions:
------------
- ADR filenames: `ADR-####_<slug>.md`
- Each ADR must start with YAML front matter containing:
    id: ADR-0001
    title: "<decision title>"
    status: Proposed | Accepted | Deprecated | Superseded
    domains: [platform, networking, secops, ...]
- Files marked `draft: true` or `template: true` are skipped.
- Invoked from repository root (ensures relative paths resolve correctly).
"""

import re
import sys
from pathlib import Path
from collections import defaultdict
from typing import List, Dict
from _index_utils import load_text, write_text, parse_front_matter, replace_block, normalize_domains, should_skip_file

# --------------------------------------------------------------------
# Paths and Constants
# --------------------------------------------------------------------
ROOT = Path.cwd()
ADR_DIR = ROOT / "docs" / "adr"
OUT_MAIN = ADR_DIR / "README.md"
TEMPLATE = ADR_DIR / "README.tmpl.md"
DOM_DIR = ADR_DIR / "by-domain"
DOM_DIR.mkdir(parents=True, exist_ok=True)

# Marker comments inside README.md
MARK_DOM_START = "<!-- ADR:DOMAINS START -->"
MARK_DOM_END = "<!-- ADR:DOMAINS END -->"
MARK_IDX_START = "<!-- ADR:INDEX START -->"
MARK_IDX_END = "<!-- ADR:INDEX END -->"

# Minimal fallback template (used if README.tmpl.md missing)
DEFAULT_TMPL = f"""# Architecture Decision Records (ADRs)

Project-wide decision log. Each ADR captures context, options, decisions, and consequences,
with links to code, diagrams, evidence, and runbooks.

---

## Domains

{MARK_DOM_START}
<!-- Populated by generator -->
{MARK_DOM_END}

---

## Index

{MARK_IDX_START}
<!-- Populated by generator -->
{MARK_IDX_END}
"""

VALID_ID = re.compile(r"^ADR-\d{4}$")


# --------------------------------------------------------------------
# Helper Functions
# --------------------------------------------------------------------
def numify(adr_id: str) -> int:
    """Convert ADR ID (e.g., ADR-0012) to integer for sorting."""
    try:
        return int(str(adr_id).split("-")[1])
    except Exception:
        return 0


def collect_items() -> List[Dict[str, str]]:
    """Scan ADR markdown files and extract metadata from front matter."""
    items = []
    for p in sorted(ADR_DIR.glob("ADR-*.md")):
        rel = p.relative_to(ADR_DIR)

        # Unified skip handling
        if should_skip_file(rel, ignore_folders=["by-domain"]):
            continue
        if not p.is_file() or not p.name.lower().startswith("adr-"):
            continue

        fm, _ = parse_front_matter(load_text(p))

        adr_id = str(fm.get("id") or p.stem.split("_")[0]).strip()
        if not adr_id.startswith("ADR-"):
            adr_id = f"ADR-{adr_id.zfill(4)}"

        title = (fm.get("title") or p.stem).replace("|", "\\|")
        status = fm.get("status", "Unknown")
        date = fm.get("decision_date") or fm.get("date", "")
        domains = normalize_domains(fm)

        items.append({
            "file": p.name,
            "id": adr_id,
            "title": title,
            "status": status,
            "date": date,
            "domains": domains,
        })

    return sorted(items, key=lambda x: int(x["id"].split("-")[1]))


def render_domains(items: List[Dict[str, str]]) -> str:
    """Render a list of domains with counts."""
    dm: Dict[str, list] = defaultdict(list)
    for it in items:
        for d in it["domains"]:
            dm[d].append(it)

    if not dm:
        return "_No domains found._\n"

    pills = " · ".join(
        f"[{d} ({len(dm[d])})](./by-domain/{d}.md)" for d in sorted(dm.keys())
    )
    return f"**Domains:** {pills}\n"


def render_index(items: List[Dict[str, str]]) -> str:
    """Generate tabular index for ADRs (ID, Title, Status, Date)."""
    rows = ["| No. | Title | Status | Date |", "|:---:|:------|:------:|:----:|"]
    for it in sorted(items, key=lambda x: numify(x["id"])):
        n = it["id"].split("-")[1]
        rows.append(
            f"| {n} | [{it['id']} — {it['title']}](./{it['file']}) | {it['status']} | {it['date']} |"
        )
    return "\n".join(rows) + "\n"


def write_main(items: List[Dict[str, str]]) -> None:
    """Render the ADR README using template markers."""
    tmpl = load_text(TEMPLATE) if TEMPLATE.exists() else DEFAULT_TMPL
    out = replace_block(tmpl, MARK_DOM_START, MARK_DOM_END, render_domains(items))
    out = replace_block(out, MARK_IDX_START, MARK_IDX_END, render_index(items))
    write_text(OUT_MAIN, out)


def write_domains(items: List[Dict[str, str]]) -> None:
    """Generate domain-level ADR listings."""
    dm: Dict[str, list] = defaultdict(list)
    for it in items:
        for d in it["domains"]:
            dm[d].append(it)

    for d, arr in dm.items():
        arr = sorted(arr, key=lambda x: numify(x["id"]))
        lines = [f"# ADRs — {d.title()}", ""]
        for it in arr:
            lines.append(
                f"- [{it['id']} — {it['title']}](../{it['file']}) — **{it['status']}**"
            )
        write_text(DOM_DIR / f"{d}.md", "\n".join(lines) + "\n")


# --------------------------------------------------------------------
# Entrypoint
# --------------------------------------------------------------------
def main() -> None:
    """Main entry point — build all ADR indexes."""
    items = collect_items()
    if not items:
        print("⚠️ No ADRs found under docs/adr/*.md", file=sys.stderr)
        sys.exit(1)

    write_main(items)
    write_domains(items)

    print(f"✅ Wrote {OUT_MAIN} and domain indexes under {DOM_DIR}/")


if __name__ == "__main__":
    main()
