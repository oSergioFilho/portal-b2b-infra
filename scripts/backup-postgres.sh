#!/bin/bash
set -e

BACKUP_DIR="./backups/postgres"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/portal_b2b_$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"

echo "Gerando backup do banco portal_b2b..."

docker compose exec -T postgres pg_dump -U postgres -d portal_b2b > "$BACKUP_FILE"

echo "Backup criado com sucesso:"
echo "$BACKUP_FILE"
