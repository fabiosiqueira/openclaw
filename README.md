# OpenClaw Docker

An improved Docker setup for OpenClaw with runtime updates, health checks, and headless web browsing capabilities.

## Features

- **Runtime Code Updates**: Automatic git pull without rebuild
- **Headless Browser**: Built-in Chromium for web scraping and search
- **Health Checks**: Deep monitoring of gateway, browser, volumes, and resources
- **Persistent Volumes**: `/data` for app data, `/config` for configuration
- **Backup/Restore**: Automated backup system for volumes
- **Stale Lock Cleanup**: Automatic cleanup of stale session locks

## Quick Start

```bash
# Build the image
docker build -t openclaw-improved .

# Run with volumes
docker run -d \
  -p 8080:8080 \
  -v openclaw_data:/data \
  -v openclaw_config:/config \
  --name openclaw \
  openclaw-improved
```

## Volumes

- `/data`: Application data, logs, sessions
- `/config`: Configuration files, tokens, settings

## Services

The container runs multiple services:

- **OpenClaw Gateway**: Main API server (port 18789)
- **Browser Service**: Headless web access (port 9223)
- **Nginx**: Reverse proxy with health endpoint (port 8080)

## Scripts

- `scripts/entrypoint.sh`: Main startup script
- `scripts/update-checker.sh`: Runtime code updates
- `scripts/healthcheck.sh`: Deep health monitoring
- `scripts/backup.sh`: Volume backup
- `scripts/restore.sh`: Volume restore
- `scripts/cleanup-locks.sh`: Stale lock removal
- `browser/browser-service.js`: Headless browser API

## Browser API

The browser service provides web access capabilities:

### Search
```bash
curl -X POST http://localhost:9223/search \
  -H "Content-Type: application/json" \
  -d '{"query": "OpenClaw documentation"}'
```

### Content Extraction
```bash
curl -X POST http://localhost:9223/extract \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## Environment Variables

- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key
- `BROWSER_SIDECAR`: Enable browser sidecar (default: true)
- `WEBHOOKS`: Enable webhooks (default: true)
- `BROWSER_PORT`: Browser service port (default: 9223)

## Health Checks

The container includes health checks that monitor:
- Gateway responsiveness
- Browser service availability
- Volume writability
- Configuration presence
- Disk and memory usage

## Updates

Code updates are checked daily and applied automatically without container restart.

## Backup

Automated backups are created in `/backups` with data and config volumes.

## License

Same as OpenClaw