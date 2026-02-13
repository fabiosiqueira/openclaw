# OpenClaw Docker - AI Coding Guidelines

## Architecture Overview
This is a multi-service Docker container for OpenClaw AI assistant with:
- **OpenClaw Gateway**: Main API server (port 18789) - core AI functionality
- **Browser Service**: Headless Chromium API (port 9223) for web search/extraction
- **Nginx Proxy**: Reverse proxy (port 8080) with health endpoint
- **Supervisor**: Process manager coordinating all services

## Key Patterns & Conventions

### Configuration Management
- Config generated at runtime by `scripts/configure.js` → `/config/config.json`
- API keys stored as files: `/config/openai.key`, `/config/anthropic.key`, etc.
- Environment variables override file-based config
- Never commit API keys - use volume mounting

### Service Communication
- Browser service endpoints: `POST /search` (Google search), `POST /extract` (content extraction)
- Gateway integrates browser service for web access capabilities
- Nginx proxies all external requests to gateway

### Docker & Deployment
- Multi-stage build: `base` (build deps) → `runtime` (production optimized)
- Non-root user: `openclaw:openclaw` (uid/gid 1001)
- Volumes: `/data` (sessions/logs), `/config` (keys/settings), `/logs` (service logs), `/backups`
- Runtime updates via `scripts/update-checker.sh` (git pull + rebuild)

### Development Workflow
```bash
# Build container
docker build -t openclaw-improved .

# Run with persistent volumes
docker run -d -p 8080:8080 \
  -v openclaw_data:/data \
  -v openclaw_config:/config \
  openclaw-improved

# Or use docker-compose for full stack
docker-compose up -d
```

### Health Monitoring
- Deep health checks via `scripts/healthcheck.sh`
- Monitors: gateway responsiveness, browser service, volume writability, disk/memory usage
- Individual service health endpoints: `/health` on each service

### Browser Integration
- Puppeteer-core with Alpine Chromium
- User agent spoofing to avoid bot detection
- Content extraction prioritizes main content selectors: `main`, `article`, `[role="main"]`
- Page timeouts: 30s for navigation, content limited to 10k chars

### Process Management
- Supervisor config: `supervisord.conf` manages all services
- Auto-restart on failure for all components
- Logs centralized in `/logs` volume

## Common Tasks
- **Add new API key**: Create file in `/config/` (e.g., `github.key`) - configure.js will pick it up
- **Debug browser issues**: Check `/logs/browser.log`, test via `curl localhost:9223/health`
- **Update OpenClaw**: Container auto-updates daily, or force via `docker exec openclaw-improved /app/scripts/update-checker.sh`
- **Backup data**: Run `scripts/backup.sh` - creates timestamped archives in `/backups`

## File Structure Reference
- `scripts/start.sh`: Finds and launches OpenClaw entry point (index.js/main.js/dist/main.js)
- `scripts/entrypoint.sh`: Container startup sequence (cleanup → update → config → supervisord)
- `browser/browser-service.js`: Standalone Express API for web operations
- `Dockerfile`: Multi-stage build with Chromium dependencies</content>
<parameter name="filePath">/Users/fabiosiqueira/dev/projetos/openclaw-docker/.github/copilot-instructions.md