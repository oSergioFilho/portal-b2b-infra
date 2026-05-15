#!/bin/bash
set -e

# Atualiza KAFKA_BOOTSTRAP_SERVERS em todos os .env dos microsserviços.
#
# Uso:
#   bash scripts/update-services-kafka-bootstrap.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
#
# Percorre /opt/portal-b2b/services/*/.env e atualiza a variável.
# Não recria containers — isso deve ser feito manualmente depois.

BOOTSTRAP="$1"
SERVICES_DIR="/opt/portal-b2b/services"

if [ -z "$BOOTSTRAP" ]; then
  echo "Uso: bash scripts/update-services-kafka-bootstrap.sh IP1:9092,IP2:9092,IP3:9092"
  echo ""
  echo "Exemplo:"
  echo "  bash scripts/update-services-kafka-bootstrap.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092"
  exit 1
fi

if [ ! -d "$SERVICES_DIR" ]; then
  echo "ERRO: Diretório $SERVICES_DIR não encontrado."
  exit 1
fi

UPDATED=0
SKIPPED=0

for SERVICE_DIR in "$SERVICES_DIR"/*/; do
  SERVICE_NAME=$(basename "$SERVICE_DIR")
  ENV_FILE="$SERVICE_DIR/.env"

  if [ ! -f "$ENV_FILE" ]; then
    echo "  ⏭️  $SERVICE_NAME — sem .env, pulando."
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Backup
  BACKUP="$ENV_FILE.bak.$(date +%Y%m%d%H%M%S)"
  cp "$ENV_FILE" "$BACKUP"

  if grep -q "^KAFKA_BOOTSTRAP_SERVERS=" "$ENV_FILE"; then
    sed -i "s|^KAFKA_BOOTSTRAP_SERVERS=.*|KAFKA_BOOTSTRAP_SERVERS=$BOOTSTRAP|" "$ENV_FILE"
    echo "  ✅ $SERVICE_NAME — KAFKA_BOOTSTRAP_SERVERS atualizado."
  else
    echo "" >> "$ENV_FILE"
    echo "KAFKA_BOOTSTRAP_SERVERS=$BOOTSTRAP" >> "$ENV_FILE"
    echo "  ✅ $SERVICE_NAME — KAFKA_BOOTSTRAP_SERVERS adicionado."
  fi

  UPDATED=$((UPDATED + 1))
done

echo ""
echo "Resultado: $UPDATED serviço(s) atualizado(s), $SKIPPED pulado(s)."
echo ""
echo "Para recriar os containers dos microsserviços, execute:"
echo ""
echo '  for SERVICE_DIR in /opt/portal-b2b/services/*/; do'
echo '    if [ -f "$SERVICE_DIR/docker-compose.yml" ]; then'
echo '      echo "Recriando $(basename "$SERVICE_DIR")..."'
echo '      (cd "$SERVICE_DIR" && docker compose up -d --build --force-recreate)'
echo '    fi'
echo '  done'
