#!/bin/bash
# Stale lock cleanup script

LOCK_DIR="/data/.openclaw/locks"
MAX_AGE=300  # 5 minutes

echo "Checking for stale locks in $LOCK_DIR"

if [ ! -d "$LOCK_DIR" ]; then
    echo "Lock directory does not exist"
    exit 0
fi

NOW=$(date +%s)
CLEANED=0

for lockfile in "$LOCK_DIR"/*.lock; do
    if [ ! -f "$lockfile" ]; then
        continue
    fi

    # Check if lock has PID info
    if grep -q '"pid"' "$lockfile" 2>/dev/null; then
        PID=$(jq -r '.pid // empty' "$lockfile" 2>/dev/null || echo "")
        if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
            # Process is still running
            continue
        fi
    fi

    # Check file age
    FILE_AGE=$((NOW - $(stat -c %Y "$lockfile")))
    if [ $FILE_AGE -gt $MAX_AGE ]; then
        echo "Removing stale lock: $lockfile (age: ${FILE_AGE}s)"
        rm -f "$lockfile"
        CLEANED=$((CLEANED + 1))
    fi
done

echo "Cleaned $CLEANED stale locks"