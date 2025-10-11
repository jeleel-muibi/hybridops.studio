
#!/usr/bin/env bash
# Minimal, local decision helper for Jenkins. Replace with API-driven logic.
set -euo pipefail

: ${AZURE_AVAILABLE_CREDIT:=80}
: ${GCP_AVAILABLE_CREDIT:=60}
: ${MIN_CREDIT:=50}

AZURE=$AZURE_AVAILABLE_CREDIT
GCP=$GCP_AVAILABLE_CREDIT

choose=""
reason=""

if (( $(echo "$AZURE < $MIN_CREDIT" | bc -l) )) && (( $(echo "$GCP >= $MIN_CREDIT" | bc -l) )); then
  choose="gcp"; reason="threshold_breach:azure_below_min"
elif (( $(echo "$GCP < $MIN_CREDIT" | bc -l) )) && (( $(echo "$AZURE >= $MIN_CREDIT" | bc -l) )); then
  choose="azure"; reason="threshold_breach:gcp_below_min"
elif (( $(echo "$AZURE >= $MIN_CREDIT" | bc -l) )) && (( $(echo "$GCP >= $MIN_CREDIT" | bc -l) )); then
  if (( $(echo "$AZURE > $GCP" | bc -l) )); then
    choose="azure"; reason="higher_credit"
  elif (( $(echo "$GCP > $AZURE" | bc -l) )); then
    choose="gcp"; reason="higher_credit"
  else
    if [ $(( $(date +%j) % 2 )) -eq 0 ]; then choose="azure"; else choose="gcp"; fi
    reason="tie_breaker:round_robin"
  fi
else
  if (( $(echo "$AZURE >= $GCP" | bc -l) )); then choose="azure"; else choose="gcp"; fi
  reason="both_below_threshold_choose_higher"
fi

echo "export TARGET_CLOUD=${choose}"
echo "export DECISION_REASON=${reason}"
