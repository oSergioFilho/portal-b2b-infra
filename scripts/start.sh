#!/bin/bash
set -e

echo "Iniciando a infraestrutura..."
docker compose up -d

echo ""
echo "========================================"
echo "Serviços disponíveis:"
echo "API Gateway: http://localhost"
echo "Health Gateway: http://localhost/health"
echo "PgAdmin: http://localhost:5050"
echo "Kafka UI: http://localhost:8080"
echo "========================================"
echo ""
echo "Kafka/Redpanda:"
echo "  O Kafka/Redpanda agora é um cluster com 3 brokers."
echo "  Os microsserviços devem usar KAFKA_BOOTSTRAP_SERVERS=IP1:9092,IP2:9092,IP3:9092"
echo "  Para subir o Redpanda local (dev): docker compose --profile local-kafka up -d"
echo ""
echo "Observação: Na VM, troque 'localhost' pelo IP_DA_VM."

echo ""
echo "Para testar os microsserviços depois de iniciados, execute:"
echo "bash scripts/check-services.sh"

