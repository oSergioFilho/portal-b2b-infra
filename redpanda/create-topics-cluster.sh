#!/bin/bash

# Criação de tópicos oficiais no cluster Redpanda com 3 brokers.
# Uso: KAFKA_BOOTSTRAP_SERVERS=IP1:9092,IP2:9092,IP3:9092 bash redpanda/create-topics-cluster.sh
#
# Pré-requisito: rpk instalado ou usar via Docker:
#   docker run --rm --network host docker.redpanda.com/redpandadata/redpanda:latest \
#     rpk topic list --brokers "$KAFKA_BOOTSTRAP_SERVERS"

set -e

rpk_cmd() {
  if command -v rpk &> /dev/null; then
    rpk "$@"
  else
    docker run --rm -i --network host docker.redpanda.com/redpandadata/redpanda:latest rpk "$@"
  fi
}

if [ -z "$KAFKA_BOOTSTRAP_SERVERS" ]; then
  echo "ERRO: KAFKA_BOOTSTRAP_SERVERS não está definido."
  echo ""
  echo "Uso:"
  echo "  export KAFKA_BOOTSTRAP_SERVERS=IP_INTERNO_VM1:9092,IP_INTERNO_VM2:9092,IP_INTERNO_VM3:9092"
  echo "  bash redpanda/create-topics-cluster.sh"
  exit 1
fi

echo "Aguardando cluster Redpanda ficar disponível em $KAFKA_BOOTSTRAP_SERVERS..."
RETRIES=30
COUNT=0
while ! rpk_cmd cluster info --brokers "$KAFKA_BOOTSTRAP_SERVERS" > /dev/null 2>&1; do
  COUNT=$((COUNT + 1))
  if [ "$COUNT" -ge "$RETRIES" ]; then
    echo "ERRO: Cluster Redpanda não ficou disponível após $RETRIES tentativas."
    exit 1
  fi
  sleep 2
done
echo "Cluster Redpanda disponível."
echo ""

TOPICS=(
  "empresa_cadastrada"
  "produto_cadastrado"
  "fornecimento_criado"
  "estoque_atualizado"
  "demanda_criada"
  "demanda_recorrente_gerada"
  "modo_negociacao_definido"
  "leilao_iniciado"
  "lance_realizado"
  "negociacao_fechada"
  "pedido_criado"
  "pedido_atualizado"
  "solicitacao_frete_criada"
  "cotacao_frete_enviada"
  "frete_selecionado"
)

PARTITIONS=3
REPLICATION_FACTOR=3

echo "Criando tópicos com $PARTITIONS partições e replication factor $REPLICATION_FACTOR..."
echo ""

for TOPIC in "${TOPICS[@]}"; do
  echo "  Criando tópico: $TOPIC"
  rpk_cmd topic create "$TOPIC" --brokers "$KAFKA_BOOTSTRAP_SERVERS" -p "$PARTITIONS" -r "$REPLICATION_FACTOR" || true
done

echo ""
echo "Tópicos criados. Listando tópicos do cluster:"
rpk_cmd topic list --brokers "$KAFKA_BOOTSTRAP_SERVERS"

# Nota: Se o cluster tiver menos de 3 brokers ativos no momento da criação,
# o comando rpk topic create com -r 3 pode falhar com erro de replicação.
# Nesse caso, suba os 3 brokers primeiro, valide com check-kafka-cluster.sh,
# e depois execute este script.
