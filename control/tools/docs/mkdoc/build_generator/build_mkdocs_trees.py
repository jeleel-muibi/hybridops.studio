#!/usr/bin/env python3
"""Generate MkDocs configs for public and academy variants from a shared base."""

from __future__ import annotations

from copy import deepcopy
from pathlib import Path
from typing import Any, Dict, List

import yaml

# Import pymdownx.superfences to allow !!python/name: tags to resolve
try:
    import pymdownx.superfences  # noqa: F401
except ImportError:
    pymdownx = None  # Will fail later if actually needed


SCRIPT_DIR = Path(__file__).resolve().parent
# repo root: .../hybridops-studio
ROOT = SCRIPT_DIR.parents[4]

# mkdocs.base.yml lives one level above build_generator/
BASE_CONFIG = SCRIPT_DIR.parent / "mkdocs.base.yml"
PUBLIC_CONFIG = SCRIPT_DIR.parent / "mkdocs.public.yml"
ACADEMY_CONFIG = SCRIPT_DIR.parent / "mkdocs.academy.yml"

DOCS_ROOT = ROOT / "docs"

PUBLIC_DOCS_DIR = "../../../../deployment/build/docs/public"
PUBLIC_SITE_DIR = "../../../../deployment/build/site/docs-public"
ACADEMY_DOCS_DIR = "../../../../deployment/build/docs/academy"
ACADEMY_SITE_DIR = "../../../../deployment/build/site/docs-academy"


def _load_yaml(path: Path) -> Dict[str, Any]:
    if not path.exists():
        raise SystemExit(f"Base MkDocs config not found: {path}")
    data = yaml.full_load(path.read_text(encoding="utf-8")) or {}
    if not isinstance(data, dict):
        raise SystemExit(f"Unexpected YAML structure in {path}")
    return data


def _slug_title_from_stem(stem: str) -> str:
    name = stem.replace("_", " ").replace("-", " ")
    return name.title()


def _files_under(root: Path) -> List[Path]:
    if not root.exists():
        return []
    return sorted(
        p
        for p in root.glob("*.md")
        if p.name.lower() not in {"readme.md", "000-index.md"}
    )


def _build_howto_topics_nav() -> List[Dict[str, str]]:
    base = DOCS_ROOT / "howto" / "by-topic"
    items: List[Dict[str, str]] = []
    for p in _files_under(base):
        title = _slug_title_from_stem(p.stem)
        rel = f"howto/by-topic/{p.name}"
        items.append({title: rel})
    return items


def _build_runbook_categories_nav() -> List[Dict[str, str]]:
    base = DOCS_ROOT / "runbooks" / "by-category"
    items: List[Dict[str, str]] = []
    for p in _files_under(base):
        title = _slug_title_from_stem(p.stem)
        rel = f"runbooks/by-category/{p.name}"
        items.append({title: rel})
    return items


def _build_adr_domains_nav() -> List[Dict[str, str]]:
    base = DOCS_ROOT / "adr" / "by-domain"
    items: List[Dict[str, str]] = []
    for p in _files_under(base):
        title = _slug_title_from_stem(p.stem)
        rel = f"adr/by-domain/{p.name}"
        items.append({title: rel})
    return items


def _build_showcase_audience_nav() -> List[Dict[str, str]]:
    base = DOCS_ROOT / "showcases" / "by-audience"
    items: List[Dict[str, str]] = []
    for p in _files_under(base):
        title = _slug_title_from_stem(p.stem)
        rel = f"showcases/by-audience/{p.name}"
        items.append({title: rel})
    return items


def _build_placeholder_mapping() -> Dict[str, List[Dict[str, str]]]:
    return {
        "__HOWTO_TOPICS__": _build_howto_topics_nav(),
        "__RUNBOOK_CATEGORIES__": _build_runbook_categories_nav(),
        "__ADR_DOMAINS__": _build_adr_domains_nav(),
        "__SHOWCASE_BY_AUDIENCE__": _build_showcase_audience_nav(),
    }


def _expand_nav(node: Any, mapping: Dict[str, List[Dict[str, str]]]) -> Any:
    if isinstance(node, list):
        expanded: List[Any] = []
        for item in node:
            if isinstance(item, str) and item in mapping:
                expanded.extend(mapping[item])
            else:
                expanded.append(_expand_nav(item, mapping))
        return expanded

    if isinstance(node, dict):
        out: Dict[str, Any] = {}
        for key, value in node.items():
            out[key] = _expand_nav(value, mapping)
        return out

    return node


def _derive_site_urls(base_cfg: Dict[str, Any]) -> tuple[str | None, str | None]:
    base_url = str(base_cfg.get("site_url") or "").strip()
    if not base_url:
        return None, None
    base_url = base_url.rstrip("/")
    return f"{base_url}/public", f"{base_url}/academy"


def build_configs() -> None:
    base_cfg = _load_yaml(BASE_CONFIG)
    placeholder_map = _build_placeholder_mapping()

    nav = base_cfg.get("nav") or []
    nav = _expand_nav(nav, placeholder_map)

    site_url_public, site_url_academy = _derive_site_urls(base_cfg)

    public_cfg = deepcopy(base_cfg)
    academy_cfg = deepcopy(base_cfg)

    public_cfg["nav"] = nav
    academy_cfg["nav"] = nav

    base_name = base_cfg.get("site_name", "HybridOps.Studio")

    public_cfg["site_name"] = f"{base_name} (Public Doc)"
    if site_url_public:
        public_cfg["site_url"] = site_url_public
    public_cfg["docs_dir"] = PUBLIC_DOCS_DIR
    public_cfg["site_dir"] = PUBLIC_SITE_DIR
    extra_public = dict(public_cfg.get("extra") or {})
    extra_public["audience"] = "public"
    public_cfg["extra"] = extra_public

    academy_cfg["site_name"] = f"{base_name} (Academy Doc)"
    if site_url_academy:
        academy_cfg["site_url"] = site_url_academy
    academy_cfg["docs_dir"] = ACADEMY_DOCS_DIR
    academy_cfg["site_dir"] = ACADEMY_SITE_DIR
    extra_academy = dict(academy_cfg.get("extra") or {})
    extra_academy["audience"] = "academy"
    academy_cfg["extra"] = extra_academy

    PUBLIC_CONFIG.write_text(
        yaml.dump(public_cfg, sort_keys=False, default_flow_style=False),
        encoding="utf-8",
    )
    ACADEMY_CONFIG.write_text(
        yaml.dump(academy_cfg, sort_keys=False, default_flow_style=False),
        encoding="utf-8",
    )


def main() -> None:
    build_configs()
    print(f"MkDocs public config:  {PUBLIC_CONFIG}")
    print(f"MkDocs academy config: {ACADEMY_CONFIG}")


if __name__ == "__main__":
    main()
