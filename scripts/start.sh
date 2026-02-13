#!/bin/bash
set -e

# Find OpenClaw entry point (could be index.js, main.js, or dist/main.js)
if [ -f /app/dist/main.js ]; then
    exec node /app/dist/main.js
elif [ -f /app/index.js ]; then
    exec node /app/index.js
elif [ -f /app/main.js ]; then
    exec node /app/main.js
else
    echo "Error: Cannot find OpenClaw entry point"
    exit 1
fi
