#!/usr/bin/env node
// Browser Service for headless web access
// Provides API for OpenClaw to perform web searches and extractions

const express = require('express');
const puppeteer = require('puppeteer-core');
const app = express();
const PORT = process.env.BROWSER_PORT || 9223;

let browser;

async function initBrowser() {
    try {
        browser = await puppeteer.launch({
            headless: true,
            executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || '/usr/bin/chromium-browser',
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--disable-dev-shm-usage',
                '--disable-accelerated-2d-canvas',
                '--no-first-run',
                '--no-zygote',
                '--single-process',
                '--disable-gpu'
            ]
        });
        console.log('Browser initialized');
    } catch (error) {
        console.error('Failed to initialize browser:', error);
        process.exit(1);
    }
}

async function searchWeb(query, options = {}) {
    if (!browser) throw new Error('Browser not initialized');

    const page = await browser.newPage();

    try {
        // Set user agent to avoid bot detection
        await page.setUserAgent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

        // Go to search engine
        const searchUrl = `https://www.google.com/search?q=${encodeURIComponent(query)}&num=10`;
        await page.goto(searchUrl, { waitUntil: 'networkidle2' });

        // Extract search results
        const results = await page.evaluate(() => {
            const resultElements = document.querySelectorAll('div.g, div[data-ved]');
            const results = [];

            for (const element of resultElements) {
                const titleElement = element.querySelector('h3, a > h3');
                const linkElement = element.querySelector('a[href]');
                const snippetElement = element.querySelector('span[data-ved], div[data-ved] span');

                if (titleElement && linkElement) {
                    results.push({
                        title: titleElement.textContent?.trim(),
                        url: linkElement.href,
                        snippet: snippetElement?.textContent?.trim() || ''
                    });
                }

                if (results.length >= 10) break;
            }

            return results;
        });

        return {
            query,
            results,
            timestamp: new Date().toISOString(),
            engine: 'google'
        };

    } finally {
        await page.close();
    }
}

async function extractContent(url, options = {}) {
    if (!browser) throw new Error('Browser not initialized');

    const page = await browser.newPage();

    try {
        await page.setUserAgent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');

        await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });

        // Extract main content
        const content = await page.evaluate(() => {
            // Remove scripts, styles, nav, footer
            const elementsToRemove = document.querySelectorAll('script, style, nav, footer, aside, .ad, .advertisement');
            elementsToRemove.forEach(el => el.remove());

            // Try to find main content
            const mainSelectors = ['main', 'article', '[role="main"]', '.content', '.post', '.entry'];
            let mainContent = '';

            for (const selector of mainSelectors) {
                const element = document.querySelector(selector);
                if (element && element.textContent?.trim().length > 100) {
                    mainContent = element.textContent.trim();
                    break;
                }
            }

            // Fallback to body text
            if (!mainContent) {
                mainContent = document.body?.textContent?.trim() || '';
            }

            return {
                title: document.title,
                content: mainContent.substring(0, 10000), // Limit content length
                url: window.location.href
            };
        });

        return content;

    } finally {
        await page.close();
    }
}

// API endpoints
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'ok', browser: !!browser });
});

app.post('/search', async (req, res) => {
    try {
        const { query, options } = req.body;
        if (!query) {
            return res.status(400).json({ error: 'Query required' });
        }

        const results = await searchWeb(query, options);
        res.json(results);
    } catch (error) {
        console.error('Search error:', error);
        res.status(500).json({ error: error.message });
    }
});

app.post('/extract', async (req, res) => {
    try {
        const { url, options } = req.body;
        if (!url) {
            return res.status(400).json({ error: 'URL required' });
        }

        const content = await extractContent(url, options);
        res.json(content);
    } catch (error) {
        console.error('Extract error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('Shutting down browser service...');
    if (browser) {
        await browser.close();
    }
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('Interrupted, shutting down...');
    if (browser) {
        await browser.close();
    }
    process.exit(0);
});

// Start service
async function start() {
    await initBrowser();

    app.listen(PORT, () => {
        console.log(`Browser service listening on port ${PORT}`);
    });
}

start().catch(console.error);