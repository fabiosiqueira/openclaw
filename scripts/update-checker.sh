#!/bin/bash
# Runtime code update checker

UPDATE_CHECK_FILE="/config/last_update_check"
UPDATE_INTERVAL=$((24 * 60 * 60))  # 24 hours

# Check if we need to update
if [ -f "$UPDATE_CHECK_FILE" ]; then
    LAST_CHECK=$(cat "$UPDATE_CHECK_FILE")
    NOW=$(date +%s)
    if [ $((NOW - LAST_CHECK)) -lt $UPDATE_INTERVAL ]; then
        echo "Update check skipped (last check: $(date -d @$LAST_CHECK))"
        exit 0
    fi
fi

echo "Checking for OpenClaw updates..."
cd /app

# Fetch latest changes
git fetch origin

# Check if we're behind
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates available! Pulling changes..."
    git pull origin main
    npm ci
    npm run build
    echo "OpenClaw updated to $(git rev-parse HEAD)"
else
    echo "Already up to date"
fi

# Update check timestamp
date +%s > "$UPDATE_CHECK_FILE"