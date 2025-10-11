#!/usr/bin/env python3
import json
import os
import re
import subprocess
from datetime import datetime

MIN = float(os.getenv("MIN_CREDIT", "50"))


def read_env_float(name):
    v = os.getenv(name)
    try:
        return float(v) if v is not None else None
    except ValueError:
        return None


def read_prom(path="decision/credits.prom"):
    az = gcp = None
    try:
        with open(path, "r") as f:
            for line in f:
                if line.startswith("#"):
                    continue
                m = re.match(r"azure_available_credit\s+(\d+(?:\.\d+)?)", line)
                if m:
                    az = float(m.group(1))
                m = re.match(r"gcp_available_credit\s+(\d+(?:\.\d+)?)", line)
                if m:
                    gcp = float(m.group(1))
    except FileNotFoundError:
        pass
    return az, gcp


def decide(az, gcp):
    if az is None and gcp is None:
        return "azure", "no_data_default_azure"
    if az is None:
        return "gcp", "azure_no_data"
    if gcp is None:
        return "azure", "gcp_no_data"
    if az < MIN and gcp >= MIN:
        return "gcp", "threshold_breach:azure_below_min"
    if gcp < MIN and az >= MIN:
        return "azure", "threshold_breach:gcp_below_min"
    if az > gcp:
        return "azure", "higher_credit"
    if gcp > az:
        return "gcp", "higher_credit"
    # tie
    day = int(datetime.now().strftime("%j"))
    return (
        ("azure", "tie_breaker:round_robin_even_day")
        if day % 2 == 0
        else ("gcp", "tie_breaker:round_robin_odd_day")
    )


az = read_env_float("AZURE_AVAILABLE_CREDIT")
gcp = read_env_float("GCP_AVAILABLE_CREDIT")
if az is None or gcp is None:
    paz, pgcp = read_prom()
    az = paz if az is None else az
    gcp = pgcp if gcp is None else gcp

cloud, reason = decide(az, gcp)
print(f"export TARGET_CLOUD={cloud}")
print(f"export DECISION_REASON={reason}")
