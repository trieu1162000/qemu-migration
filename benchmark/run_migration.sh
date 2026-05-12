#!/bin/bash
# Usage: ./run_migration.sh <label> "<workload command>"
# Example: ./run_migration.sh "A-idle-run1" "sleep 200"

LABEL=$1
WORKLOAD=$2
MONITOR="127.0.0.1 4444"
OUT="$HOME/workspace/qemu-migration/results/${LABEL}-$(date +%H%M%S).txt"

echo "=== $LABEL ===" | tee "$OUT"
echo "Workload: $WORKLOAD" | tee -a "$OUT"

# Launch workload inside guest (background, non-blocking)
ssh -p 2222 ubuntu@localhost "nohup bash -c '$WORKLOAD' &>/tmp/wload.log &"
sleep 5

# Set bandwidth cap — do NOT skip this
printf 'migrate_set_parameter max-bandwidth 10M\n' | nc -q1 $MONITOR

# Start migration
echo "Migrating... (wait 3 min)"
printf 'migrate tcp:127.0.0.1:4455\n' | nc -q1 $MONITOR

# Poll for completion — QEMU 11 outputs "Status: completed"
while true; do
    RESULT=$(printf 'info migrate\n' | nc -q1 $MONITOR)
    # Lọc lấy Status và xóa ký tự \r
    ST=$(echo "$RESULT" | grep "^Status:" | awk '{print $2}' | tr -d '\r')
    if [ "$ST" = "completed" ] || [ "$ST" = "failed" ]; then
        echo "$RESULT" | tee -a "$OUT"
        echo "Result: $ST — saved to $OUT"
        break
    fi
    sleep 2
    echo "not completed, try again"
done
echo "Resume src"
printf 'c\n' | nc -q1 $MONITOR
