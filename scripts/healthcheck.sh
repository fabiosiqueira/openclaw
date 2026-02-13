#!/bin/bash
# Deep health check for OpenClaw

HEALTH_URL="http://localhost:18789/health"
TIMEOUT=10

# Check if gateway is responding
if ! curl -f -s --max-time $TIMEOUT "$HEALTH_URL" > /dev/null; then
    echo "Gateway health check failed"
    exit 1
fi

# Check if we can access data volume
if [ ! -w /data ]; then
    echo "Data volume not writable"
    exit 1
fi

# Check if config volume has config
if [ ! -f /config/config.json ]; then
    echo "Config file missing"
    exit 1
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 90 ]; then
    echo "Disk usage too high: ${DISK_USAGE}%"
    exit 1
fi

# Check memory usage (if available)
if command -v free > /dev/null; then
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ $MEM_USAGE -gt 90 ]; then
        echo "Memory usage too high: ${MEM_USAGE}%"
        exit 1
    fi
fi

echo "All health checks passed"
exit 0