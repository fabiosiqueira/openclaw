# OpenClaw Docker

An improved Docker setup for OpenClaw with runtime updates, health checks, and persistent volumes.

## Features

- **Runtime Code Updates**: Automatic git pull without rebuild
- **Health Checks**: Deep monitoring of gateway, volumes, and resources
- **Persistent Volumes**: `/data` for app data, `/config` for configuration
- **Backup/Restore**: Automated backup system for volumes
- **Stale Lock Cleanup**: Automatic cleanup of stale session locks
- **Supervisor Management**: Proper process management with auto-restart

## Quick Start

```bash
# Build the image
docker build -t openclaw-improved .

# Run with volumes
docker run -d \
  -p 8080:8080 \
  -v openclaw_data:/data \
  -v openclaw_config:/config \
  -e OPENAI_API_KEY=your_key \
  --name openclaw \
  openclaw-improved
```

## Volumes

- `/data`: Application data, logs, sessions
- `/config`: Configuration files, tokens, settings

## Scripts

- `scripts/entrypoint.sh`: Main startup script
- `scripts/update-checker.sh`: Runtime code updates
- `scripts/healthcheck.sh`: Deep health monitoring
- `scripts/backup.sh`: Volume backup
- `scripts/restore.sh`: Volume restore
- `scripts/cleanup-locks.sh`: Stale lock removal

## Environment Variables

- `OPENAI_API_KEY`: OpenAI API key
- `ANTHROPIC_API_KEY`: Anthropic API key
- `BROWSER_SIDECAR`: Enable browser sidecar (default: true)
- `WEBHOOKS`: Enable webhooks (default: true)

## Health Checks

The container includes health checks that monitor:
- Gateway responsiveness
- Volume writability
- Configuration presence
- Disk and memory usage

## Updates

Code updates are checked daily and applied automatically without container restart.

## Backup

Automated backups are created in `/backups` with data and config volumes.

## License

Same as OpenClaw