#!/usr/bin/env python3
"""
choose_target.py — tiny operator CLI for picking a DR/burst target.
Prints only: 'azure' or 'gcp' (one line).

Inputs (mix and match):
  --metrics <file.json>    # JSON with structure:
                           # {"azure":{"rpo":300,"rto":600,"latency_ms":45},
                           #  "gcp":{"rpo":240,"rto":480,"latency_ms":55}}
  --credits "azure=100,gcp=40"  # or env DECISION_CREDITS="azure=100,gcp=40"
  --max-rpo 300            # seconds (default 300)
  --max-rto 900            # seconds (default 900)
  --strategy balanced|cost|latency  (default: balanced or $DECISION_STRATEGY)
  --verbose                # print decision context to stderr

Environment fallbacks:
  DECISION_CREDITS="azure=100,gcp=40"
  DECISION_STRATEGY="balanced"

Exit:
  0 with provider string on stdout.
"""
import argparse, json, os, sys, re
from typing import Dict, Any
from libhybridops.decision import choose_target as choose

def parse_credits(s: str) -> Dict[str, float]:
    out: Dict[str, float] = {}
    for part in s.split(","):
        part = part.strip()
        if not part:
            continue
        m = re.match(r"^(azure|gcp)\s*=\s*([0-9]+(\.[0-9]+)?)$", part, re.I)
        if not m:
            raise ValueError(f"Invalid credits format: {part!r}. Use 'azure=NN,gcp=NN'")
        out[m.group(1).lower()] = float(m.group(2))
    out.setdefault("azure", 0.0)
    out.setdefault("gcp", 0.0)
    return out

def load_metrics(path: str):
    if not path:
        return {"azure": {}, "gcp": {}}
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    norm = {"azure": {}, "gcp": {}}
    for prov in ("azure","gcp"):
        if prov in data:
            d = data[prov] or {}
            norm[prov] = {
                "rpo": float(d.get("rpo", 1e9)),
                "rto": float(d.get("rto", 1e9)),
                "latency_ms": float(d.get("latency_ms", 1e9)),
            }
    return norm

def main() -> int:
    ap = argparse.ArgumentParser(description="Choose DR/burst target provider")
    ap.add_argument("--metrics", help="Path to metrics JSON (azure/gcp keys)", default="")
    ap.add_argument("--credits", help="Credits 'azure=NN,gcp=NN' (or DECISION_CREDITS)", default="")
    ap.add_argument("--max-rpo", type=float, default=300.0)
    ap.add_argument("--max-rto", type=float, default=900.0)
    ap.add_argument("--strategy", choices=["balanced","cost","latency"],
                    default=os.getenv("DECISION_STRATEGY","balanced"))
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    credits_str = args.credits or os.getenv("DECISION_CREDITS","azure=0,gcp=0")
    try:
        credits = parse_credits(credits_str)
    except Exception as e:
        print(f"[decision] {e}", file=sys.stderr)
        return 2

    metrics = load_metrics(args.metrics)

    decision = choose(
        metrics=metrics,
        credits=credits,
        max_rpo=args.max_rpo,
        max_rto=args.max_rto,
        strategy=args.strategy,
    )

    if args.verbose:
        ctx = {
            "inputs": {"metrics": metrics, "credits": credits,
                       "max_rpo": args.max_rpo, "max_rto": args.max_rto,
                       "strategy": args.strategy},
            "decision": decision,
        }
        print(json.dumps(ctx, indent=2), file=sys.stderr)

    print(decision["provider"])
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
