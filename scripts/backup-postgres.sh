#!/bin/bash
set -e

# Verifica se o PostgreSQL está rodando
if ! docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
  echo "PostgreSQL não está acessível. Verifique se a infraestrutura está rodando com docker compose up -d."
  exit 1
fi

BACKUP_DIR="./backups/postgres"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/portal_b2b_$TIMESTAMP.sql"

mkdir -p "$BACKUP_DIR"

echo "Gerando backup do banco portal_b2b..."

docker compose exec -T postgres pg_dump -U postgres -d portal_b2b > "$BACKUP_FILE"

echo "Backup criado com sucesso:"
echo "$BACKUP_FILE"
echo ""
echo "Recomendação: copie este arquivo para fora da VM principal, por exemplo para a VM standby, Google Drive, S3, outro servidor ou armazenamento externo."
