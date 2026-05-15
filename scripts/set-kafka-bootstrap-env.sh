#!/bin/bash
set -e

# Atualiza KAFKA_BOOTSTRAP_SERVERS no .env da infraestrutura.
#
# Uso:
#   bash scripts/set-kafka-bootstrap-env.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092

BOOTSTRAP="$1"
ENV_FILE=".env"

if [ -z "$BOOTSTRAP" ]; then
  echo "Uso: bash scripts/set-kafka-bootstrap-env.sh IP1:9092,IP2:9092,IP3:9092"
  echo ""
  echo "Exemplo:"
  echo "  bash scripts/set-kafka-bootstrap-env.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092"
  exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
  echo "Arquivo $ENV_FILE não encontrado. Copiando de .env.example..."
  cp .env.example "$ENV_FILE"
fi

BACKUP="$ENV_FILE.bak.$(date +%Y%m%d%H%M%S)"
cp "$ENV_FILE" "$BACKUP"
echo "Backup criado: $BACKUP"

if grep -q "^KAFKA_BOOTSTRAP_SERVERS=" "$ENV_FILE"; then
  sed -i "s|^KAFKA_BOOTSTRAP_SERVERS=.*|KAFKA_BOOTSTRAP_SERVERS=$BOOTSTRAP|" "$ENV_FILE"
  echo "KAFKA_BOOTSTRAP_SERVERS atualizado em $ENV_FILE."
else
  echo "" >> "$ENV_FILE"
  echo "KAFKA_BOOTSTRAP_SERVERS=$BOOTSTRAP" >> "$ENV_FILE"
  echo "KAFKA_BOOTSTRAP_SERVERS adicionado em $ENV_FILE."
fi

echo ""
echo "Valor atual:"
grep "^KAFKA_BOOTSTRAP_SERVERS=" "$ENV_FILE"
