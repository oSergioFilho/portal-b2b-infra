#!/bin/bash
set -e

echo "=== Verificando containers ==="
docker compose ps
echo ""

echo "=== Testando API Gateway ==="
curl -s http://localhost/health || echo "Falha ao acessar API Gateway"
echo -e "\n"

echo "=== Testando PostgreSQL ==="
docker compose exec -T postgres pg_isready -U postgres || echo "Falha ao acessar PostgreSQL"
echo ""

echo "=== Testando Kafka UI ==="
curl -I -s http://localhost:8080 | head -n 1 || echo "Falha ao acessar Kafka UI"
echo ""

echo "=== Testando PgAdmin ==="
curl -I -s http://localhost:5050 | head -n 1 || echo "Falha ao acessar PgAdmin"
echo ""

echo "=== Listando tópicos no Redpanda ==="
docker compose exec -T redpanda rpk topic list --brokers redpanda:9092 || echo "Falha ao listar tópicos"
echo ""

echo "Verificação concluída."
