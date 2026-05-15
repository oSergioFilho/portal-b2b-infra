#!/bin/bash

# Health check do cluster Redpanda com 3 brokers.
# Uso: KAFKA_BOOTSTRAP_SERVERS=IP1:9092,IP2:9092,IP3:9092 bash scripts/check-kafka-cluster.sh
#
# Pré-requisito: rpk instalado na VM ou usar via Docker:
#   docker run --rm --network host docker.redpanda.com/redpandadata/redpanda:latest \
#     rpk cluster info --brokers "$KAFKA_BOOTSTRAP_SERVERS"

set -e

if [ -z "$KAFKA_BOOTSTRAP_SERVERS" ]; then
  echo "ERRO: KAFKA_BOOTSTRAP_SERVERS não está definido."
  echo ""
  echo "Uso:"
  echo "  export KAFKA_BOOTSTRAP_SERVERS=IP_INTERNO_VM1:9092,IP_INTERNO_VM2:9092,IP_INTERNO_VM3:9092"
  echo "  bash scripts/check-kafka-cluster.sh"
  exit 1
fi

echo "=== Kafka Cluster Health Check ==="
echo "Brokers: $KAFKA_BOOTSTRAP_SERVERS"
echo ""

echo "=== Cluster Info ==="
rpk cluster info --brokers "$KAFKA_BOOTSTRAP_SERVERS" || {
  echo "ERRO: Falha ao obter informações do cluster."
  exit 1
}
echo ""

echo "=== Cluster Health ==="
rpk cluster health --brokers "$KAFKA_BOOTSTRAP_SERVERS" || {
  echo "ERRO: Falha ao verificar saúde do cluster."
  exit 1
}
echo ""

echo "=== Tópicos do Cluster ==="
rpk topic list --brokers "$KAFKA_BOOTSTRAP_SERVERS" || {
  echo "ERRO: Falha ao listar tópicos."
  exit 1
}
echo ""

# Validar tópicos oficiais
OFFICIAL_TOPICS=(
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

echo "=== Validação de Tópicos Oficiais ==="
EXISTING_TOPICS=$(rpk topic list --brokers "$KAFKA_BOOTSTRAP_SERVERS" 2>/dev/null | awk 'NR>1{print $1}')
MISSING=0

for TOPIC in "${OFFICIAL_TOPICS[@]}"; do
  if echo "$EXISTING_TOPICS" | grep -q "^${TOPIC}$"; then
    echo "  ✅ $TOPIC"
  else
    echo "  ❌ $TOPIC (NÃO ENCONTRADO)"
    MISSING=$((MISSING + 1))
  fi
done

echo ""
if [ "$MISSING" -gt 0 ]; then
  echo "⚠️  $MISSING tópico(s) oficial(is) não encontrado(s)."
  echo "Execute: KAFKA_BOOTSTRAP_SERVERS=$KAFKA_BOOTSTRAP_SERVERS bash redpanda/create-topics-cluster.sh"
else
  echo "✅ Todos os tópicos oficiais estão presentes no cluster."
fi

echo ""
echo "Health check do cluster concluído."
