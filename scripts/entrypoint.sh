#!/bin/bash
set -e

echo "[$(date)] Starting OpenClaw Container"

# Cleanup stale locks
echo "[$(date)] Cleaning up stale locks..."
/app/scripts/cleanup-locks.sh

# Update code if needed
echo "[$(date)] Checking for code updates..."
/app/scripts/update-checker.sh

# Generate config
echo "[$(date)] Generating configuration..."
node /app/scripts/configure.js > /config/config.json

# Start services
echo "[$(date)] Starting services..."
exec supervisord -c /etc/supervisord.conf