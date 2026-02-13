// OpenClaw Configuration Generator
// Reads API keys from persistent volume files or environment variables

const fs = require('fs');
const path = require('path');

function readKeyFile(filename) {
    const filepath = path.join('/config', filename);
    try {
        if (fs.existsSync(filepath)) {
            return fs.readFileSync(filepath, 'utf8').trim();
        }
    } catch (error) {
        console.warn(`Warning: Could not read ${filename}:`, error.message);
    }
    return null;
}

function generateConfig() {
    const config = {
        // Basic OpenClaw config
        port: process.env.PORT || 18789,
        host: process.env.HOST || '0.0.0.0',

        // Data paths
        dataDir: '/data',
        configDir: '/config',
        logsDir: '/logs',

        // API Keys - Read from files first, then env vars
        apiKeys: {
            openai: readKeyFile('openai.key') || process.env.OPENAI_API_KEY || '',
            anthropic: readKeyFile('anthropic.key') || process.env.ANTHROPIC_API_KEY || '',
            github: readKeyFile('github.key') || process.env.GITHUB_TOKEN || '',
            gitlab: readKeyFile('gitlab.key') || process.env.GITLAB_TOKEN || ''
        },

        // Provider configs
        providers: {
            openai: {
                apiKey: readKeyFile('openai.key') || process.env.OPENAI_API_KEY || '',
                enabled: !!(readKeyFile('openai.key') || process.env.OPENAI_API_KEY)
            },
            anthropic: {
                apiKey: readKeyFile('anthropic.key') || process.env.ANTHROPIC_API_KEY || '',
                enabled: !!(readKeyFile('anthropic.key') || process.env.ANTHROPIC_API_KEY)
            }
        },

        // Features
        features: {
            browserSidecar: process.env.BROWSER_SIDECAR !== 'false',
            webhooks: process.env.WEBHOOKS !== 'false',
            persistentSessions: true,
            autoBackup: true,
            healthChecks: true
        },

        // Browser service
        browser: {
            port: process.env.BROWSER_PORT || 9223,
            enabled: true
        }
    };

    return config;
}

// Generate and save config
const config = generateConfig();
console.log(JSON.stringify(config, null, 2));

// Save to file for debugging
fs.writeFileSync('/config/config.json', JSON.stringify(config, null, 2));

// This would be called by entrypoint.sh