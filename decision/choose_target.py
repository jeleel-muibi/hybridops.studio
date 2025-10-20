#!/usr/bin/env python3
import argparse, json, time
from pathlib import Path

def load_env(env_path: Path) -> dict:
    out = {}
    for line in env_path.read_text().splitlines():
        line=line.strip()
        if not line or line.startswith("#") or "=" not in line: continue
        k,v = line.split("=",1)
        out[k.strip()] = v.strip()
    return out

def normalize(vs):
    m, M = min(vs), max(vs)
    if M == m:
        return [0.0 for _ in vs]
    return [(v - m) / (M - m) for v in vs]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--policy", required=True)
    ap.add_argument("--metrics", required=True)
    ap.add_argument("--credits", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    policy   = json.loads(Path(args.policy).read_text())
    metrics  = json.loads(Path(args.metrics).read_text())
    credits  = load_env(Path(args.credits))

    candidates = {}
    for provider, m in metrics.items():
        rto_ok = m["rto_s"] <= policy["rto_max_s"]
        rpo_ok = m["rpo_s"] <= policy["rpo_max_s"]
        cred_key = f"{provider.upper()}_CREDITS"
        cval = int(credits.get(cred_key, "0") or "0")
        credit_ok = cval >= policy["skip_if_credits_below"]
        if rto_ok and rpo_ok and credit_ok:
            candidates[provider] = {**m, "credits": cval}

    if not candidates:
        chosen = policy.get("default_fallback", "onprem")
        decision = {
            "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "reason": "no_candidates_met_constraints",
            "chosen": chosen,
            "scores": {},
            "inputs": {"metrics": metrics, "credits": credits, "policy": policy}
        }
        Path(args.out).write_text(json.dumps(decision, indent=2))
        print(f"[choose_target] No candidates met constraints. Fallback -> {chosen}")
        return

    rtos = [candidates[p]["rto_s"] for p in candidates]
    rpos = [candidates[p]["rpo_s"] for p in candidates]
    lats = [candidates[p]["latency_ms"] for p in candidates]
    nr, np, nl = normalize(rtos), normalize(rpos), normalize(lats)

    weights = policy["weights"]
    scores = {}
    for i, provider in enumerate(candidates):
        score = (
            weights.get("rto_s", 0)*nr[i] +
            weights.get("rpo_s", 0)*np[i] +
            weights.get("latency_ms", 0)*nl[i]
        )
        scores[provider] = round(float(score), 6)

    chosen = sorted(scores.items(), key=lambda kv: kv[1])[0][0]

    decision = {
        "timestamp_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "reason": "lowest_weighted_score",
        "chosen": chosen,
        "scores": scores,
        "inputs": {"metrics": metrics, "credits": credits, "policy": policy}
    }
    Path(args.out).write_text(json.dumps(decision, indent=2))
    print(f"[choose_target] chosen={chosen} scores={scores}")

if __name__ == "__main__":
    main()
