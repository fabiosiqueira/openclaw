#!/bin/bash
# Restore script for OpenClaw volumes

BACKUP_DIR="/backups"
BACKUP_NAME="$1"

if [ -z "$BACKUP_NAME" ]; then
    echo "Usage: $0 <backup_name>"
    echo "Available backups:"
    ls "$BACKUP_DIR"
    exit 1
fi

BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

if [ ! -d "$BACKUP_PATH" ]; then
    echo "Backup not found: $BACKUP_NAME"
    exit 1
fi

echo "Restoring from backup: $BACKUP_NAME"

# Stop services temporarily (if running)
# This would be handled by container orchestration

# Restore data volume
if [ -f "$BACKUP_PATH/data.tar.gz" ]; then
    echo "Restoring /data..."
    rm -rf /data/*
    tar -xzf "$BACKUP_PATH/data.tar.gz" -C /
fi

# Restore config volume
if [ -f "$BACKUP_PATH/config.tar.gz" ]; then
    echo "Restoring /config..."
    rm -rf /config/*
    tar -xzf "$BACKUP_PATH/config.tar.gz" -C /
fi

echo "Restore completed from $BACKUP_NAME"