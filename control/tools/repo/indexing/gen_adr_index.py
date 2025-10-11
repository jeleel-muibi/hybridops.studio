#!/usr/bin/env python3
"""
Generate ADR indexes under docs/adr.

Outputs
- docs/adr/README.md           (from README.tmpl.md or a small built-in template; two marker blocks replaced)
- docs/adr/by-domain/<d>.md    (per-domain lists)

Notes
- Run from the repository root so paths resolve correctly.
- ADR files must start with YAML front matter and include a valid id: ADR-####.
- Files with draft: true or template: true are excluded.
- Domains are taken from 'domain' or 'domains' (string or list) and normalized for filenames.
"""
from pathlib import Path
import re, sys
from collections import defaultdict

from _index_utils import load_text, write_text, parse_front_matter, replace_block, normalize_domains

# Paths (assumes invocation from repo root)
ROOT     = Path.cwd()
ADR_DIR  = ROOT / "docs" / "adr"
OUT_MAIN = ADR_DIR / "README.md"
TEMPLATE = ADR_DIR / "README.tmpl.md"
DOM_DIR  = ADR_DIR / "by-domain"
DOM_DIR.mkdir(parents=True, exist_ok=True)

# Marker comments inside README.md
MARK_DOM_START = "<!-- ADR:DOMAINS START -->"
MARK_DOM_END   = "<!-- ADR:DOMAINS END -->"
MARK_IDX_START = "<!-- ADR:INDEX START -->"
MARK_IDX_END   = "<!-- ADR:INDEX END -->"

# Built-in minimal README template (used only if README.tmpl.md is absent)
DEFAULT_TMPL = f"""# Architecture Decision Records (ADRs)

Project-wide decision log. Each ADR captures context, options, decision, and consequences with links to code, diagrams, evidence, and runbooks.

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

# Require ADR IDs like ADR-0001
VALID_ID = re.compile(r"^ADR-\d{4}$")


def numify(adr_id: str) -> int:
    try:
        return int(adr_id.split("-")[1])
    except Exception:
        return 0


def collect_items():
    items = []
    for p in sorted(ADR_DIR.glob("[Aa][Dd][Rr]-*.md")):
        if not p.is_file() or "template" in p.name.lower():
            continue
        fm, _ = parse_front_matter(load_text(p))

        if str(fm.get("draft", "false")).lower() in ("true", "yes", "1"):
            continue
        if str(fm.get("template", "false")).lower() in ("true", "yes", "1"):
            continue

        adr_id = (fm.get("id") or p.stem.split("_")[0]).strip()
        if not VALID_ID.match(adr_id):
            continue

        items.append({
            "file":   p.name,
            "id":     adr_id,
            "title":  (fm.get("title") or p.stem).replace("|", "\\|"),
            "status": fm.get("status", "Unknown"),
            "date":   fm.get("decision_date") or fm.get("date", ""),
            "domains": normalize_domains(fm),
        })
    return items


def render_domains(items) -> str:
    dm = defaultdict(list)
    for it in items:
        for d in it["domains"]:
            dm[d].append(it)
    if not dm:
        return ""
    lines = []
    for d in sorted(dm.keys()):
        lines.append(f"- [{d}](./by-domain/{d}.md) ({len(dm[d])})")
    return "\n".join(lines) + "\n"


def render_index(items) -> str:
    rows = ["| No. | Title | Status | Date |", "|:---:|:------|:------:|:----:|"]
    for it in sorted(items, key=lambda x: numify(x["id"])):
        n = it["id"].split("-")[1] if "-" in it["id"] else "?"
        rows.append(f"| {n} | [{it['id']} — {it['title']}](./{it['file']}) | {it['status']} | {it['date']} |")
    return "\n".join(rows) + "\n"


def write_main(items):
    tmpl = load_text(TEMPLATE) if TEMPLATE.exists() else DEFAULT_TMPL
    out  = replace_block(tmpl, MARK_DOM_START, MARK_DOM_END, render_domains(items))
    out  = replace_block(out,  MARK_IDX_START, MARK_IDX_END, render_index(items))
    write_text(OUT_MAIN, out)


def write_domains(items):
    dm = defaultdict(list)
    for it in items:
        for d in it["domains"]:
            dm[d].append(it)
    for d, arr in dm.items():
        arr = sorted(arr, key=lambda x: numify(x["id"]))
        lines = [f"# ADRs — {d}", ""]
        for it in arr:
            lines.append(f"- [{it['id']} — {it['title']}](../{it['file']}) — **{it['status']}**")
        write_text(DOM_DIR / f"{d}.md", "\n".join(lines) + "\n")


def main():
    items = collect_items()
    if not items:
        print("No ADRs found under docs/adr/*.md", file=sys.stderr)
        sys.exit(1)
    write_main(items)
    write_domains(items)
    print(f"Wrote {OUT_MAIN} and domain files under {DOM_DIR}/")


if __name__ == "__main__":
    main()
