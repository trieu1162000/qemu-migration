#!/bin/bash
# Usage: ./run_migration.sh <label> <snapshot_name> [multifd_channels]
# Example (Phase 2, multifd off): ./run_migration.sh "A-idle-run1" "A_W1_idle"
# Example (Phase 3, multifd on):  ./run_migration.sh "D-idle-run1" "B_W1_idle" 4

LABEL=$1
SNAPSHOT=$2
CHANNELS=${3:-0}   # default 0 = multifd disabled (Phase 2 behaviour)
SRC="127.0.0.1 4444"   # source monitor
DST="127.0.0.1 4445"   # destination monitor
OUT="/home/ngerr/workspace/qemu-migration/experiments/results/${LABEL}-$(date +%H%M%S).txt"

echo "=== $LABEL | channels=$CHANNELS ===" | tee "$OUT"
echo "Snapshot: $SNAPSHOT" | tee -a "$OUT"
# multifd off before loadvm
printf 'migrate_set_capability multifd off\n' | nc -q1 $SRC

# Restore source to steady-state snapshot — migrate immediately after
printf "loadvm ${SNAPSHOT}\n" | nc -q1 $SRC
sleep 3

# Log guest RAM state for verification
echo "--- guest free -m ---" | tee -a "$OUT"
ssh -p 2222 ubuntu@localhost "free -m" | tee -a "$OUT"

# Set bandwidth cap on source — do NOT skip this
printf 'migrate_set_parameter max-bandwidth 10M\n' | nc -q1 $SRC
printf 'migrate_set_parameter max-bandwidth 10M\n' | nc -q1 $DST

# Enable/disable multifd capability on BOTH source and destination
if [ "$CHANNELS" -gt 0 ]; then
    printf 'migrate_set_capability multifd on\n' | nc -q1 $SRC
    printf "migrate_set_parameter multifd-channels ${CHANNELS}\n" | nc -q1 $SRC
    printf 'migrate_set_capability multifd on\n' | nc -q1 $DST
    printf "migrate_set_parameter multifd-channels ${CHANNELS}\n" | nc -q1 $DST
else
    printf 'migrate_set_capability multifd off\n' | nc -q1 $SRC
    printf 'migrate_set_capability multifd off\n' | nc -q1 $DST
fi

# Tell destination to start listening (deferred until now so multifd is set first)
printf 'migrate_incoming tcp:0:4455\n' | nc -q1 $DST
sleep 1

# Start migration immediately (workload state is already baked into snapshot)
echo "Migrating..."
printf 'migrate tcp:127.0.0.1:4455\n' | nc -q1 $SRC

# Poll for completion — QEMU 11 outputs "Status: completed"
while true; do
    RESULT=$(printf 'info migrate\n' | nc -q1 $SRC)
    ST=$(echo "$RESULT" | grep "^Status:" | awk '{print $2}' | tr -d '\r')
    if [ "$ST" = "completed" ] || [ "$ST" = "failed" ]; then
        echo "$RESULT" | tee -a "$OUT"
        echo "Result: $ST — saved to $OUT"
        break
    fi
    sleep 2
    echo "not completed, try again"
done
printf 'c\n' | nc -q1 $SRC

