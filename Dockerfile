FROM node:18-alpine AS base

# Install dependencies
RUN apk add --no-cache \
    git \
    bash \
    curl \
    jq \
    && mkdir -p /app /data /config /backups

# Clone OpenClaw (will be updated at runtime)
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git /app

WORKDIR /app

# Copy our minimal package.json
COPY package.json /app/

# Install minimal dependencies
RUN npm install --production

# Runtime stage
FROM node:18-alpine AS runtime

# Install runtime dependencies including browser (lighter)
RUN apk add --no-cache \
    git \
    bash \
    curl \
    jq \
    nginx \
    supervisor \
    openssh-client \
    chromium \
    chromium-chromedriver \
    && mkdir -p /app /data /config /backups /logs

# Copy application (including node_modules)
COPY --from=base /app /app

# Copy scripts
COPY scripts/ /app/scripts/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Setup nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Setup supervisor
COPY supervisord.conf /etc/supervisord.conf

# Create non-root user
RUN addgroup -g 1001 -S openclaw && \
    adduser -u 1001 -S openclaw -G openclaw

# Set permissions
RUN chown -R openclaw:openclaw /app /data /config /backups /logs

# Set environment for headless browser
ENV CHROME_BIN=/usr/bin/chromium-browser
ENV CHROME_PATH=/usr/lib/chromium/

USER openclaw

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/scripts/healthcheck.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]