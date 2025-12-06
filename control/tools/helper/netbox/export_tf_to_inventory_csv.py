#!/usr/bin/env python3
# file: export_tf_to_inventory_csv.py
# purpose: Merge Terraform inventory JSON into a single NetBox-ready CSV while preserving non-Terraform rows
# Maintainer: HybridOps.Studio
# date: 2025-11-29

import argparse
import csv
import json
import sys
from pathlib import Path
from typing import Any, Dict, List, Tuple

# Canonical CSV columns
COLUMNS = [
    "name",
    "fqdn",
    "environment",
    "role",
    "provider",
    "site",
    "mgmt_ip",
    "mgmt_prefix",
    "os_family",
    "os_name",
    "is_ctrl_host",
    "tags",
    "source",
]


def load_tf_inventory_json(path: Path) -> List[Dict[str, Any]]:
    """Load a JSON file expected to contain a list of inventory rows."""
    if not path.is_file():
        print(f"[WARN] Terraform inventory JSON not found: {path}", file=sys.stderr)
        return []

    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001
        print(f"[WARN] Failed to parse JSON from {path}: {exc}", file=sys.stderr)
        return []

    if not isinstance(data, list):
        print(
            f"[WARN] Unexpected JSON structure in {path}; expected a top-level list. Skipping.",
            file=sys.stderr,
        )
        return []

    rows: List[Dict[str, Any]] = []
    for idx, row in enumerate(data):
        if not isinstance(row, dict):
            print(
                f"[WARN] Entry {idx} in {path} is not an object; skipping.",
                file=sys.stderr,
            )
            continue
        rows.append(row)
    return rows


def load_existing_inventory(path: Path) -> List[Dict[str, str]]:
    """Load existing inventory CSV if present."""
    if not path.is_file():
        return []

    rows: List[Dict[str, str]] = []
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Normalise to string keys/values
            rows.append({k: (v or "").strip() for k, v in row.items()})
    return rows


def normalise_row(row: Dict[str, Any]) -> Dict[str, str]:
    """Normalise a row to the canonical CSV schema.

    - Missing columns are filled with empty strings.
    - Extra keys are ignored.
    - is_ctrl_host is normalised to 'true'/'false' strings.
    """
    normalised: Dict[str, str] = {col: "" for col in COLUMNS}

    for key, value in row.items():
        if key not in COLUMNS:
            continue
        if key == "is_ctrl_host":
            if isinstance(value, bool):
                normalised[key] = "true" if value else "false"
            else:
                s = str(value).strip().lower()
                normalised[key] = "true" if s in {"1", "true", "yes"} else "false"
        else:
            normalised[key] = str(value).strip()

    if not normalised["source"]:
        normalised["source"] = "terraform"

    return normalised


def key_for_row(row: Dict[str, str]) -> Tuple[str, str, str]:
    """Stable key used for deduplication."""
    return (
        row.get("name", ""),
        row.get("environment", ""),
        row.get("provider", ""),
    )


def merge_inventory(
    existing_rows: List[Dict[str, str]],
    tf_rows: List[Dict[str, Any]],
) -> List[Dict[str, str]]:
    """Merge existing inventory with new Terraform rows.

    Behaviour:
      - Existing rows with source == 'terraform' are discarded.
      - Existing rows with source != 'terraform' are kept.
      - New Terraform rows are normalised and then merged.
      - On key collision, Terraform rows overwrite existing rows.
    """
    merged: Dict[Tuple[str, str, str], Dict[str, str]] = {}

    # Preserve non-Terraform rows from existing inventory
    for row in existing_rows:
        source = row.get("source", "").strip().lower()
        if source == "terraform":
            continue
        key = key_for_row(row)
        merged[key] = {col: row.get(col, "") for col in COLUMNS}

    # Overlay Terraform-derived rows
    for row in tf_rows:
        n = normalise_row(row)
        merged[key_for_row(n)] = n

    # Stable sort for deterministic output
    return sorted(
        merged.values(),
        key=lambda r: (r.get("environment", ""), r.get("provider", ""), r.get("name", "")),
    )


def write_inventory(path: Path, rows: List[Dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=COLUMNS)
        writer.writeheader()
        for row in rows:
            writer.writerow({col: row.get(col, "") for col in COLUMNS})


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Merge Terraform inventory JSON into a single NetBox-ready CSV, "
            "preserving non-Terraform rows."
        ),
    )
    parser.add_argument(
        "--tf-json",
        dest="tf_json",
        nargs="+",
        required=True,
        help="Paths to Terraform inventory JSON files "
             "(e.g. terraform output -json inventory_rows > dev.inventory.json)",
    )
    parser.add_argument(
        "--inventory",
        dest="inventory",
        default="infra/env/netbox.inventory.csv",
        help="Path to the unified inventory CSV "
             "(default: infra/env/netbox.inventory.csv)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)

    inventory_path = Path(args.inventory)
    tf_paths = [Path(p) for p in args.tf_json]

    existing_rows = load_existing_inventory(inventory_path)

    all_tf_rows: List[Dict[str, Any]] = []
    for p in tf_paths:
        all_tf_rows.extend(load_tf_inventory_json(p))

    merged_rows = merge_inventory(existing_rows, all_tf_rows)
    write_inventory(inventory_path, merged_rows)

    print(f"[INFO] Wrote {len(merged_rows)} rows to {inventory_path}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
