#!/bin/bash
# Usage: ./run_migration.sh <label> <snapshot_name>
# Example: ./run_migration.sh "A-idle-run1" "W1_idle"

LABEL=$1
SNAPSHOT=$2
MONITOR="127.0.0.1 4444"
OUT="$HOME/workspace/qemu-migration/results/${LABEL}-$(date +%H%M%S).txt"

echo "=== $LABEL ===" | tee "$OUT"
echo "Snapshot: $SNAPSHOT" | tee -a "$OUT"

# Restore source to steady-state snapshot — migrate immediately after
printf "loadvm ${SNAPSHOT}\n" | nc -q1 $MONITOR
sleep 3

# Log guest RAM state for verification
echo "--- guest free -m ---" | tee -a "$OUT"
ssh -p 2222 ubuntu@localhost "free -m" | tee -a "$OUT"

# Set bandwidth cap — do NOT skip this
printf 'migrate_set_parameter max-bandwidth 10M\n' | nc -q1 $MONITOR

# Start migration immediately (workload state is already baked into snapshot)
echo "Migrating..."
printf 'migrate tcp:127.0.0.1:4455\n' | nc -q1 $MONITOR

# Poll for completion — QEMU 11 outputs "Status: completed"
while true; do
    RESULT=$(printf 'info migrate\n' | nc -q1 $MONITOR)
    ST=$(echo "$RESULT" | grep "^Status:" | awk '{print $2}' | tr -d '\r')
    if [ "$ST" = "completed" ] || [ "$ST" = "failed" ]; then
        echo "$RESULT" | tee -a "$OUT"
        echo "Result: $ST — saved to $OUT"
        break
    fi
    sleep 2
    echo "not completed, try again"
done
printf 'c\n' | nc -q1 $MONITOR

