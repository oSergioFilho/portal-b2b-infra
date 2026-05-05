#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Uso: bash scripts/restore-postgres.sh caminho_do_backup.sql [--force]"
  exit 1
fi

BACKUP_FILE=$1
FORCE=false

if [ "$2" == "--force" ]; then
  FORCE=true
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Arquivo de backup não encontrado: $BACKUP_FILE"
  exit 1
fi

if [ "$FORCE" = false ]; then
  echo "Atenção: este script irá aplicar o backup no banco portal_b2b atual."
  echo "Se já existirem tabelas/dados, pode haver conflito."
  read -p "Deseja continuar? (s/N): " CONFIRM
  if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo "Restauração cancelada."
    exit 0
  fi
fi

echo "Restaurando backup no banco portal_b2b..."
echo "Arquivo: $BACKUP_FILE"

cat "$BACKUP_FILE" | docker compose exec -T postgres psql -U postgres -d portal_b2b

echo "Backup restaurado com sucesso."
