#!/bin/bash
set -e

# Find OpenClaw entry point (could be index.js, main.js, dist/main.js, openclaw.mjs, or src/index.ts)
if [ -f /app/dist/main.js ]; then
    exec node /app/dist/main.js
elif [ -f /app/openclaw.mjs ]; then
    exec node /app/openclaw.mjs
elif [ -f /app/index.js ]; then
    exec node /app/index.js
elif [ -f /app/main.js ]; then
    exec node /app/main.js
elif [ -f /app/src/index.ts ]; then
    exec npx tsx /app/src/index.ts
else
    echo "Error: Cannot find OpenClaw entry point"
    exit 1
fi
