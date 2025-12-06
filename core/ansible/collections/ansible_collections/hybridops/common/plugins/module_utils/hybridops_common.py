# file: hybridops_common.py
# purpose: Shared helpers for HybridOps custom modules
# Maintainer: HybridOps.Studio
# date: 2025-11-26


def build_standard_result(changed=False, message="", extra=None):
    data = {
        "changed": bool(changed),
        "message": str(message),
    }
    if extra and isinstance(extra, dict):
        data.update(extra)
    return data
