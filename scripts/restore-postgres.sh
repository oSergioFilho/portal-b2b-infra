#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Uso: bash scripts/restore-postgres.sh caminho_do_backup.sql"
  exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Arquivo de backup não encontrado: $BACKUP_FILE"
  exit 1
fi

echo "Restaurando backup no banco portal_b2b..."
echo "Arquivo: $BACKUP_FILE"

cat "$BACKUP_FILE" | docker compose exec -T postgres psql -U postgres -d portal_b2b

echo "Backup restaurado com sucesso."
