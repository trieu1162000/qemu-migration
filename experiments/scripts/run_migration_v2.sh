#!/bin/bash
# run_migration_v2.sh — extended migration runner with codec + XBZRLE support
#
# Usage:
#   ./run_migration_v2.sh <label> <snapshot> [channels=0] [codec=none] [bw_MB=10]
#
# codec values: none | xbzrle | zstd | zlib
#
# Examples:
#   G0 (XBZRLE only):        ./run_migration_v2.sh "G0-idle-run1"  "A_W1_idle" 0 xbzrle
#   H4 (multifd+zstd ch4):   ./run_migration_v2.sh "H4-idle-run1"  "A_W1_idle" 4 zstd
#   H8 (multifd+zstd ch8):   ./run_migration_v2.sh "H8-idle-run1"  "A_W1_idle" 8 zstd
#   I4 (multifd+zlib ch4):   ./run_migration_v2.sh "I4-idle-run1"  "A_W1_idle" 4 zlib
#   I8 (multifd+zlib ch8):   ./run_migration_v2.sh "I8-idle-run1"  "A_W1_idle" 8 zlib

LABEL=$1
SNAPSHOT=$2
CHANNELS=${3:-0}
CODEC=${4:-none}
BW=${5:-10}

SRC="127.0.0.1 4444"
DST="127.0.0.1 4445"
RESULTS_DIR="/home/ngerr/workspace/qemu-migration/experiments/results"
OUT="${RESULTS_DIR}/${LABEL}-$(date +%H%M%S).txt"

echo "=== $LABEL | channels=$CHANNELS | codec=$CODEC ===" | tee "$OUT"
echo "Snapshot: $SNAPSHOT" | tee -a "$OUT"

# ── Reset capabilities to clean state ────────────────────────────────────────
for MONITOR in "$SRC" "$DST"; do
    printf 'migrate_set_capability multifd off\n'   | nc -q1 $MONITOR
    printf 'migrate_set_capability xbzrle off\n'    | nc -q1 $MONITOR
    printf 'migrate_set_parameter multifd-compression none\n' | nc -q1 $MONITOR
done

# ── Restore snapshot ─────────────────────────────────────────────────────────
printf "loadvm ${SNAPSHOT}\n" | nc -q1 $SRC
sleep 3

echo "--- guest free -m ---" | tee -a "$OUT"
ssh -p 2222 ubuntu@localhost "free -m" 2>/dev/null | tee -a "$OUT"

# ── Bandwidth cap ─────────────────────────────────────────────────────────────
if [ "$BW" -gt 0 ]; then
    printf "migrate_set_parameter max-bandwidth ${BW}M\n" | nc -q1 $SRC
else
    printf 'migrate_set_parameter max-bandwidth 0\n' | nc -q1 $SRC
    echo "WARNING: bandwidth cap disabled" | tee -a "$OUT"
fi
printf 'migrate_set_parameter max-bandwidth 10M\n' | nc -q1 $DST

# ── Codec / channel setup ─────────────────────────────────────────────────────
case "$CODEC" in
    xbzrle)
	# For proposed xbzlre 
        if [ "$CHANNELS" -gt 0 ]; then
            echo "PROPOSED MODE: Enabling both multifd ($CHANNELS channels) and XBZRLE" | tee -a "$OUT"
            for MONITOR in "$SRC" "$DST"; do
                # Kích hoạt cả 2 capabilities cùng lúc
                printf 'migrate_set_capability multifd on\n'                      | nc -q1 $MONITOR
                printf 'migrate_set_capability xbzrle on\n'                       | nc -q1 $MONITOR
                printf "migrate_set_parameter multifd-channels ${CHANNELS}\n"     | nc -q1 $MONITOR
                # Đặt cache size cho XBZRLE
                printf 'migrate_set_parameter xbzrle-cache-size 64M\n'   | nc -q1 $MONITOR
            done
	# QEMU upstream only
        else
            printf 'migrate_set_capability xbzrle on\n'              | nc -q1 $SRC
            printf 'migrate_set_parameter xbzrle-cache-size 64M\n'   | nc -q1 $SRC
            printf 'migrate_set_capability xbzrle on\n'              | nc -q1 $DST
            printf 'migrate_set_parameter xbzrle-cache-size 64M\n'   | nc -q1 $DST
            echo "XBZRLE enabled, cache=64M, multifd=off" | tee -a "$OUT"
        fi
        ;;
    zstd|zlib)
        # zstd/zlib: multifd compression codecs — require channels >= 1
        if [ "$CHANNELS" -lt 1 ]; then
            echo "ERROR: $CODEC requires channels >= 1" | tee -a "$OUT"
            exit 1
        fi
        for MONITOR in "$SRC" "$DST"; do
            printf 'migrate_set_capability multifd on\n'                      | nc -q1 $MONITOR
            printf "migrate_set_parameter multifd-channels ${CHANNELS}\n"     | nc -q1 $MONITOR
            printf "migrate_set_parameter multifd-compression ${CODEC}\n"     | nc -q1 $MONITOR
        done
        echo "multifd=$CODEC, channels=$CHANNELS" | tee -a "$OUT"
        ;;
    none|"")
        # Plain multifd, no compression
        if [ "$CHANNELS" -gt 0 ]; then
            for MONITOR in "$SRC" "$DST"; do
                printf 'migrate_set_capability multifd on\n'                  | nc -q1 $MONITOR
                printf "migrate_set_parameter multifd-channels ${CHANNELS}\n" | nc -q1 $MONITOR
            done
            echo "multifd=none, channels=$CHANNELS" | tee -a "$OUT"
        else
            echo "legacy precopy, no multifd, no compression" | tee -a "$OUT"
        fi
        ;;
    *)
        echo "ERROR: unknown codec '$CODEC'" | tee -a "$OUT"
        exit 1
        ;;
esac

# ── Start migration ───────────────────────────────────────────────────────────
printf 'migrate_incoming tcp:0:4455\n' | nc -q1 $DST
sleep 1

echo "Migrating..." | tee -a "$OUT"
printf 'migrate tcp:127.0.0.1:4455\n' | nc -q1 $SRC

while true; do
    RESULT=$(printf 'info migrate\n' | nc -q1 $SRC)
    ST=$(echo "$RESULT" | grep "^Status:" | awk '{print $2}' | tr -d '\r')
    if [ "$ST" = "completed" ] || [ "$ST" = "failed" ]; then
        echo "$RESULT" | tee -a "$OUT"
        echo "Result: $ST — saved to $OUT"
        break
    fi
    sleep 2
    echo "waiting..."
done
printf 'c\n' | nc -q1 $SRC

