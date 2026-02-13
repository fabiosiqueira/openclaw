FROM node:22-alpine AS base

# Install build dependencies
RUN apk add --no-cache \
    git \
    bash \
    curl \
    jq \
    python3 \
    make \
    g++ \
    && mkdir -p /app /data /config /backups

# Clone OpenClaw official repo
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git /app

WORKDIR /app

# Copy our enhanced package.json with full dependencies
COPY package.json /app/

# Install all dependencies including dev dependencies for build
RUN npm install

# Build the application
RUN npm run build

# Production stage - clean and optimized
FROM node:22-alpine AS runtime

# Install runtime dependencies for full browser support
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
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    && mkdir -p /app /data /config /backups /logs

# Copy built application and production dependencies
COPY --from=base /app/node_modules /app/node_modules
COPY --from=base /app/package.json /app/package.json

# Copy our custom scripts and configs
COPY scripts/ /app/scripts/
COPY browser/ /app/browser/

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Setup nginx with optimized config
COPY nginx.conf /etc/nginx/nginx.conf

# Setup supervisor
COPY supervisord.conf /etc/supervisord.conf

# Create optimized non-root user
RUN addgroup -g 1001 -S openclaw && \
    adduser -u 1001 -S openclaw -G openclaw && \
    chown -R openclaw:openclaw /app /data /config /backups /logs

# Clean up APK cache to reduce image size
RUN rm -rf /var/cache/apk/*

# Set environment for headless browser
ENV CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    NODE_ENV=production \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

USER openclaw

EXPOSE 8080

# Health check with optimized timing
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /app/scripts/healthcheck.sh

ENTRYPOINT ["/app/scripts/entrypoint.sh"]