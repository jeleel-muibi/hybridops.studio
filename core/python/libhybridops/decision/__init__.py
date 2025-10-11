"""
libhybridops.decision — Policy-based target selection for DR/burst.
Pure library (no I/O side effects) for CLIs, Ansible, or services.

Public API:
    choose_target(metrics, credits, max_rpo=300, max_rto=900, strategy="balanced")
returns:
    {"provider": "azure"|"gcp", "reason": "...", "eligible": {"azure": bool, "gcp": bool}}
"""
from typing import Dict, Any

def _eligible(m: Dict[str, float], max_rpo: float, max_rto: float) -> bool:
    rpo = float(m.get("rpo", 1e12))
    rto = float(m.get("rto", 1e12))
    return (rpo <= max_rpo) and (rto <= max_rto)

def choose_target(*, metrics: Dict[str, Dict[str, float]], credits: Dict[str, float],
                  max_rpo: float = 300.0, max_rto: float = 900.0, strategy: str = "balanced") -> Dict[str, Any]:
    az = metrics.get("azure", {}) or {}
    gp = metrics.get("gcp", {}) or {}
    elig = {"azure": _eligible(az, max_rpo, max_rto), "gcp": _eligible(gp, max_rpo, max_rto)}

    lat_az = float(az.get("latency_ms", 1e9))
    lat_gp = float(gp.get("latency_ms", 1e9))
    cr_az = float(credits.get("azure", 0.0))
    cr_gp = float(credits.get("gcp", 0.0))

    if elig["azure"] and not elig["gcp"]:
        return {"provider": "azure", "reason": "only azure meets SLOs", "eligible": elig}
    if elig["gcp"] and not elig["azure"]:
        return {"provider": "gcp", "reason": "only gcp meets SLOs", "eligible": elig}

    if elig["azure"] and elig["gcp"]:
        if strategy == "cost":
            if cr_az > cr_gp: return {"provider": "azure", "reason": "higher credits (cost)", "eligible": elig}
            if cr_gp > cr_az: return {"provider": "gcp", "reason": "higher credits (cost)", "eligible": elig}
            if lat_az < lat_gp: return {"provider": "azure", "reason": "credits tie → lower latency", "eligible": elig}
            if lat_gp < lat_az: return {"provider": "gcp", "reason": "credits tie → lower latency", "eligible": elig}
            return {"provider": "azure", "reason": "full tie → prefer azure", "eligible": elig}
        elif strategy == "latency":
            if lat_az < lat_gp: return {"provider": "azure", "reason": "lower latency", "eligible": elig}
            if lat_gp < lat_az: return {"provider": "gcp", "reason": "lower latency", "eligible": elig}
            if cr_az >= cr_gp: return {"provider": "azure", "reason": "latency tie → higher/equal credits", "eligible": elig}
            return {"provider": "gcp", "reason": "latency tie → higher credits", "eligible": elig}
        else:  # balanced
            if cr_az > cr_gp: return {"provider": "azure", "reason": "higher credits (balanced)", "eligible": elig}
            if cr_gp > cr_az: return {"provider": "gcp", "reason": "higher credits (balanced)", "eligible": elig}
            if lat_az < lat_gp: return {"provider": "azure", "reason": "credits tie → lower latency", "eligible": elig}
            if lat_gp < lat_az: return {"provider": "gcp", "reason": "credits tie → lower latency", "eligible": elig}
            return {"provider": "azure", "reason": "full tie → prefer azure", "eligible": elig}

    if cr_az >= cr_gp:
        return {"provider": "azure", "reason": "no provider meets SLOs → pick higher/equal credits (degraded)", "eligible": elig}
    else:
        return {"provider": "gcp", "reason": "no provider meets SLOs → pick higher credits (degraded)", "eligible": elig}
