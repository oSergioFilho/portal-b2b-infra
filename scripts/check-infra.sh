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

echo "=== Testando Schema portal_b2b e Health Check ==="
docker compose exec -T postgres psql -U postgres -d portal_b2b -c "\dn portal_b2b" || echo "Falha ao validar schema portal_b2b"
docker compose exec -T postgres psql -U postgres -d portal_b2b -c "SELECT * FROM portal_b2b.health_check;" || echo "Falha ao acessar tabela health_check"
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
