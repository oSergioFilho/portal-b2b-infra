#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Uso: $0 <nome_do_topico>"
  exit 1
fi

TOPIC_NAME=$1

echo "Criando tópico: $TOPIC_NAME"
docker compose exec -T redpanda rpk topic create "$TOPIC_NAME" --brokers redpanda:9092 -p 1 -r 1
echo "Tópico $TOPIC_NAME criado com sucesso!"
