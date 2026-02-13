#!/bin/bash
set -e

# Start OpenClaw Gateway
cd /app
exec node dist/main.js
