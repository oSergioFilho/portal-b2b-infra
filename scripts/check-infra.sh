#!/bin/bash
set -e

echo "=== Verificando containers ==="
docker compose ps
echo ""

echo "=== Testando API Gateway ==="
curl -s http://localhost/health || echo "Falha ao acessar API Gateway"
echo -e "\n"

echo "=== Testando Cloud SQL PostgreSQL ==="
if [ -z "$SVC_PASSWORD" ]; then
  echo "SVC_PASSWORD não definida. Pulando teste autenticado do Cloud SQL."
  echo "Para testar manualmente:"
  echo "PGPASSWORD=\"SENHA\" psql -h 136.114.235.212 -U svc_portal_b2b -d portal_b2b -c \"SELECT * FROM portal_b2b.health_check;\""
else
  if ! command -v psql &> /dev/null; then
    echo "Comando psql não encontrado na VM. Instale o pacote postgresql-client ou teste pelo PgAdmin."
  else
    PGPASSWORD="$SVC_PASSWORD" psql \
      -h 136.114.235.212 \
      -U svc_portal_b2b \
      -d portal_b2b \
      -c "SELECT * FROM portal_b2b.health_check;" || echo "Falha ao acessar tabela health_check no Cloud SQL"
  fi
fi
echo ""


echo "=== Testando Kafka UI ==="
curl -I -s http://localhost:8080 | head -n 1 || echo "Falha ao acessar Kafka UI"
echo ""

echo "=== Testando PgAdmin ==="
curl -I -s http://localhost:5050 | head -n 1 || echo "Falha ao acessar PgAdmin"
echo ""

echo "=== Testando Kafka/Redpanda ==="
if [ -n "$KAFKA_BOOTSTRAP_SERVERS" ]; then
  echo "KAFKA_BOOTSTRAP_SERVERS=$KAFKA_BOOTSTRAP_SERVERS"
  echo "Executando health check do cluster externo..."
  echo ""
  bash scripts/check-kafka-cluster.sh
else
  echo "⚠️  KAFKA_BOOTSTRAP_SERVERS não está definido."
  echo "O cluster Kafka/Redpanda externo não foi configurado nesta sessão."
  echo ""
  echo "Para testar o cluster, defina:"
  echo "  export KAFKA_BOOTSTRAP_SERVERS=IP_VM1:9092,IP_VM2:9092,IP_VM3:9092"
  echo "  bash scripts/check-infra.sh"
  echo ""
  echo "Ou execute diretamente:"
  echo "  bash scripts/check-kafka-cluster.sh"
  echo ""
  echo "Nota: O Redpanda local (redpanda:9092) não é mais o broker oficial de produção."
  echo "Para usar o Redpanda local em desenvolvimento:"
  echo "  docker compose --profile local-kafka up -d"
fi
echo ""

echo "Verificação concluída."
