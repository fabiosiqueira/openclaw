// OpenClaw Configuration Generator
// This would be expanded based on OpenClaw's actual config needs

const fs = require('fs');
const path = require('path');

function generateConfig() {
    const config = {
        // Basic OpenClaw config
        port: process.env.PORT || 18789,
        host: process.env.HOST || '0.0.0.0',

        // Data paths
        dataDir: '/data',
        configDir: '/config',
        logsDir: '/logs',

        // Provider configs (would be set via env)
        providers: {
            openai: {
                apiKey: process.env.OPENAI_API_KEY || '',
                enabled: !!process.env.OPENAI_API_KEY
            },
            anthropic: {
                apiKey: process.env.ANTHROPIC_API_KEY || '',
                enabled: !!process.env.ANTHROPIC_API_KEY
            }
        },

        // Features
        features: {
            browserSidecar: process.env.BROWSER_SIDECAR !== 'false',
            webhooks: process.env.WEBHOOKS !== 'false',
            persistentSessions: true
        }
    };

    return config;
}

// Generate and save config
const config = generateConfig();
console.log(JSON.stringify(config, null, 2));

// This would be called by entrypoint.sh