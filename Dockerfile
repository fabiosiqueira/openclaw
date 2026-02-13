FROM node:22-slim AS base

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    jq \
    python3 \
    make \
    g++ \
    && npm install -g pnpm \
    && mkdir -p /app /data /config /backups

# Clone OpenClaw official repo
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git /app

WORKDIR /app

# Install dependencies
RUN npm install --ignore-scripts --legacy-peer-deps || npm install --force

# Build the application
# RUN npm run build

# Build UI
WORKDIR /app/ui
RUN npm install && npm run build
WORKDIR /app

# Production stage - clean and optimized
FROM node:22-slim AS runtime

# Install runtime dependencies for full browser support
RUN apt-get update && apt-get install -y \
    git \
    bash \
    curl \
    jq \
    nginx \
    supervisor \
    openssh-client \
    chromium \
    chromium-driver \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    && ln -sf /usr/bin/chromium /usr/bin/chromium-browser \
    && mkdir -p /app /data /config /backups /logs

WORKDIR /app

# Copy entire OpenClaw application from build stage
COPY --from=base /app /app

# Install puppeteer-core for browser service
RUN npm install puppeteer-core

# Create openclaw wrapper script
RUN echo '#!/bin/bash\nexec npx tsx /app/src/index.ts "$@"' > /usr/local/bin/openclaw && chmod +x /usr/local/bin/openclaw

# Copy our custom files (overwrites if needed)
COPY scripts/ /app/scripts/
RUN mkdir -p /app/browser
RUN echo '#!/usr/bin/env node\n\
// Browser Service for headless web access\n\
// Provides API for OpenClaw to perform web searches and extractions\n\
\n\
import express from "express";\n\
import puppeteer from "puppeteer-core";\n\
\n\
const app = express();\n\
const PORT = process.env.BROWSER_PORT || 9223;\n\
\n\
let browser;\n\
\n\
async function initBrowser() {\n\
    try {\n\
        browser = await puppeteer.launch({\n\
            headless: true,\n\
            executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || "/usr/bin/chromium",\n\
            args: [\n\
                "--no-sandbox",\n\
                "--disable-setuid-sandbox",\n\
                "--disable-dev-shm-usage",\n\
                "--disable-accelerated-2d-canvas",\n\
                "--no-first-run",\n\
                "--no-zygote",\n\
                "--single-process",\n\
                "--disable-gpu"\n\
            ]\n\
        });\n\
        console.log("Browser initialized");\n\
    } catch (error) {\n\
        console.error("Failed to initialize browser:", error);\n\
        process.exit(1);\n\
    }\n\
}\n\
\n\
app.use(express.json());\n\
\n\
app.get("/health", (req, res) => {\n\
    res.json({ status: "ok", browser: !!browser });\n\
});\n\
\n\
app.post("/search", async (req, res) => {\n\
    try {\n\
        const { query } = req.body;\n\
        if (!query) {\n\
            return res.status(400).json({ error: "Query required" });\n\
        }\n\
        res.json({ query, results: [], message: "Search not implemented yet" });\n\
    } catch (error) {\n\
        res.status(500).json({ error: error.message });\n\
    }\n\
});\n\
\n\
app.post("/extract", async (req, res) => {\n\
    try {\n\
        const { url } = req.body;\n\
        if (!url) {\n\
            return res.status(400).json({ error: "URL required" });\n\
        }\n\
        res.json({ url, content: "Content extraction not implemented yet" });\n\
    } catch (error) {\n\
        res.status(500).json({ error: error.message });\n\
    }\n\
});\n\
\n\
async function start() {\n\
    await initBrowser();\n\
    app.listen(PORT, () => {\n\
        console.log(`Browser service listening on port ${PORT}`);\n\
    });\n\
}\n\
\n\
start().catch(console.error);' > /app/browser/browser-service.js
COPY supervisord.conf /etc/supervisord.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Make scripts executable
RUN chmod +x /app/scripts/*.sh

# Create optimized non-root user
RUN mkdir -p /var/cache/nginx /var/lib/nginx/body /var/lib/nginx/proxy /var/lib/nginx/fastcgi /var/lib/nginx/uwsgi /var/lib/nginx/scgi && \
    groupadd -r openclaw -g 1001 && \
    useradd -r -u 1001 -g openclaw -m -d /home/openclaw openclaw && \
    chown -R openclaw:openclaw /var/lib/nginx /var/log/nginx /var/cache/nginx /run /app /data /config /backups /logs /home/openclaw && \
    chmod -R 755 /var/lib/nginx /var/cache/nginx

# Clean up APT cache to reduce image size
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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
    CMD /app/scripts/healthcheck.sh || exit 1

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
