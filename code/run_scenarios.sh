#!/bin/bash
set -euo pipefail

SCENARIOS=("default_config" "stress_test" "fault_injection" "scaling")

mkdir -p outputs

for s in "${SCENARIOS[@]}"; do
  CFG="./config/${s}.json"
  
  # Read parameters from the JSON using jq
  W=$(jq -r '.TestRunners // 3' "$CFG")
  R=$(jq -r '.Repeats // 0' "$CFG")
  D=$(jq -r '.TestDuration // "10s"' "$CFG")
  D="${D}s"
  S=$(jq -r '.SleepBetweenRequests // "100ms"' "$CFG")
  S="${S}ms"

  echo "=== Running scenario: $s ==="

  docker run --rm \
    --network code_msim-net \
    -v "$(pwd)/config":/config \
    -e OTEL_EXPORTER_OTLP_ENDPOINT=http://jaeger:4318 \
    -e OTEL_EXPORTER_OTLP_INSECURE=true \
    yurishkuro/microsim \
    -c /config/$(basename "$CFG") \
    -w "$W" \
    -r "$R" \
    -d "$D" \
    -s "$S" \
    > outputs/microsim_${s}.log 2>&1

  echo "=> finished: outputs/microsim_${s}.log"
  sleep 5
done
