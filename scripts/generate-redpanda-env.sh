#!/bin/bash

# Gera arquivo .env para um broker Redpanda do cluster.
#
# Uso:
#   bash scripts/generate-redpanda-env.sh primary IP_VM1 IP_VM2 IP_VM3
#   bash scripts/generate-redpanda-env.sh standby IP_VM1 IP_VM2 IP_VM3
#   bash scripts/generate-redpanda-env.sh kafka3  IP_VM1 IP_VM2 IP_VM3
#
# Saída: arquivo .env gerado em redpanda/.env

set -e

ROLE="$1"
IP_VM1="$2"
IP_VM2="$3"
IP_VM3="$4"

if [ -z "$ROLE" ] || [ -z "$IP_VM1" ] || [ -z "$IP_VM2" ] || [ -z "$IP_VM3" ]; then
  echo "Uso: bash scripts/generate-redpanda-env.sh <role> <IP_VM1> <IP_VM2> <IP_VM3>"
  echo ""
  echo "Roles disponíveis:"
  echo "  primary  - VM principal (node-id 0)"
  echo "  standby  - VM standby  (node-id 1)"
  echo "  kafka3   - VM kafka-3  (node-id 2)"
  echo ""
  echo "Exemplo:"
  echo "  bash scripts/generate-redpanda-env.sh primary 10.128.0.10 10.128.0.11 10.128.0.12"
  exit 1
fi

case "$ROLE" in
  primary)
    NODE_ID=0
    ADVERTISE_IP="$IP_VM1"
    ;;
  standby)
    NODE_ID=1
    ADVERTISE_IP="$IP_VM2"
    ;;
  kafka3)
    NODE_ID=2
    ADVERTISE_IP="$IP_VM3"
    ;;
  *)
    echo "ERRO: Role inválida: $ROLE"
    echo "Roles válidas: primary, standby, kafka3"
    exit 1
    ;;
esac

OUTPUT_FILE="redpanda/.env"

cat > "$OUTPUT_FILE" <<EOF
# Gerado automaticamente por scripts/generate-redpanda-env.sh
# Role: $ROLE | Node ID: $NODE_ID
# Data: $(date -u '+%Y-%m-%dT%H:%M:%SZ')

REDPANDA_NODE_ID=$NODE_ID
REDPANDA_ADVERTISE_IP=$ADVERTISE_IP
REDPANDA_BROKER_1=$IP_VM1
REDPANDA_BROKER_2=$IP_VM2
REDPANDA_BROKER_3=$IP_VM3
REDPANDA_KAFKA_PORT=9092
REDPANDA_RPC_PORT=33145
REDPANDA_ADMIN_PORT=9644
EOF

echo "Arquivo $OUTPUT_FILE gerado com sucesso:"
echo ""
cat "$OUTPUT_FILE"
echo ""
echo "Para subir o broker:"
echo "  cd redpanda"
echo "  docker compose --env-file .env -f docker-compose.cluster.yml up -d"
