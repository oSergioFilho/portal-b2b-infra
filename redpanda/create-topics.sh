#!/bin/bash

# Esperar Redpanda ficar disponível
echo "Aguardando Redpanda..."
while ! rpk cluster info --brokers redpanda:9092 > /dev/null 2>&1; do
  sleep 2
done
echo "Redpanda está disponível. Criando tópicos..."

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

for TOPIC in "${TOPICS[@]}"; do
  rpk topic create "$TOPIC" --brokers redpanda:9092 -p 1 -r 1 || true
done

echo "Tópicos criados:"
rpk topic list --brokers redpanda:9092
