#!/bin/bash
set -e

echo "Iniciando a infraestrutura..."
docker compose up -d

echo ""
echo "========================================"
echo "Serviços disponíveis:"
echo "API Gateway: http://localhost"
echo "PgAdmin: http://localhost:5050"
echo "Kafka UI: http://localhost:8080"
echo "PostgreSQL: localhost:5432"
echo "Kafka: localhost:9092"
echo "========================================"
