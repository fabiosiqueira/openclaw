#!/bin/bash
# Backup script for OpenClaw volumes

BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="openclaw_backup_$TIMESTAMP"

echo "Creating backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup data volume
echo "Backing up /data..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME/data.tar.gz" -C / data 2>/dev/null || true

# Backup config volume
echo "Backing up /config..."
tar -czf "$BACKUP_DIR/$BACKUP_NAME/config.tar.gz" -C / config 2>/dev/null || true

# Create backup manifest
cat > "$BACKUP_DIR/$BACKUP_NAME/manifest.json" << EOF
{
  "name": "$BACKUP_NAME",
  "timestamp": "$TIMESTAMP",
  "created_at": "$(date -Iseconds)",
  "volumes": {
    "data": "data.tar.gz",
    "config": "config.tar.gz"
  }
}
EOF

# Cleanup old backups (keep last 10)
cd "$BACKUP_DIR"
ls -t | tail -n +11 | xargs -r rm -rf

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME"