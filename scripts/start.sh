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
echo "PostgreSQL: localhost:5432"
echo "Kafka/Redpanda: localhost:9092"
echo "========================================"
echo "Observação: Na VM, troque 'localhost' pelo IP_DA_VM."
