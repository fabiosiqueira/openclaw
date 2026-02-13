FROM node:22-alpine AS base

# Install dependencies
RUN apk add --no-cache \
    git \
    bash \
    curl \
    jq \
    nginx \
    supervisor \
    && mkdir -p /app /data /config /backups

# Clone OpenClaw (will be updated at runtime)
RUN git clone --depth 1 https://github.com/coollabsio/openclaw.git /app

WORKDIR /app

# Install dependencies
RUN npm ci

# Build OpenClaw
RUN npm run build

# Runtime stage
FROM node:22-alpine AS runtime

# Install runtime dependencies
RUN apk add --no-cache \
    git \
    bash \
    curl \
    jq \
    nginx \
    supervisor \
    openssh-client \
    && mkdir -p /app /data /config /backups /logs

# Copy built application
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

USER openclaw

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/scripts/healthcheck.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]