#!/bin/bash
set -e

SERVICE_NAME="$1"
REPO_URL="$2"
BASE_DIR="/opt/portal-b2b/services"
VM_IP="${VM_IP:-34.29.84.207}"
LOAD_BALANCER_IP="${LOAD_BALANCER_IP:-34.8.17.245}"

if [ -z "$SERVICE_NAME" ] || [ -z "$REPO_URL" ]; then
  echo "Uso: bash scripts/deploy-service.sh nome-service URL_DO_REPOSITORIO"
  echo "Exemplo: bash scripts/deploy-service.sh produtos-service https://github.com/EXEMPLO/produtos-service.git"
  exit 1
fi

case "$SERVICE_NAME" in
  usuarios-service)
    PORT=5001
    DOMAIN="usuarios"
    ;;
  produtos-service)
    PORT=5002
    DOMAIN="produtos"
    ;;
  fornecimentos-service)
    PORT=5003
    DOMAIN="fornecimentos"
    ;;
  demanda-service)
    PORT=5004
    DOMAIN="demandas"
    ;;
  mercado-service)
    PORT=5005
    DOMAIN="mercado"
    ;;
  negociacao-service)
    PORT=5006
    DOMAIN="negociacoes"
    ;;
  pedidos-service)
    PORT=5007
    DOMAIN="pedidos"
    ;;
  logistica-service)
    PORT=5008
    DOMAIN="logistica"
    ;;
  transportadoras-service)
    PORT=5009
    DOMAIN="transportadoras"
    ;;
  *)
    echo "Serviço inválido: $SERVICE_NAME"
    echo "Serviços válidos:"
    echo "  - usuarios-service"
    echo "  - produtos-service"
    echo "  - fornecimentos-service"
    echo "  - demanda-service"
    echo "  - mercado-service"
    echo "  - negociacao-service"
    echo "  - pedidos-service"
    echo "  - logistica-service"
    echo "  - transportadoras-service"
    exit 1
    ;;
esac

SERVICE_DIR="$BASE_DIR/$SERVICE_NAME"

mkdir -p "$SERVICE_DIR"
cd "$SERVICE_DIR"

if [ -z "$(ls -A .)" ]; then
  echo "Clonando repositório $REPO_URL em $SERVICE_DIR..."
  git clone "$REPO_URL" .
elif [ -d ".git" ]; then
  echo "Repositório já existe. Atualizando..."
  git pull origin main
else
  echo "A pasta $SERVICE_DIR não está vazia e não é um repositório Git."
  echo "Resolva manualmente antes de continuar."
  exit 1
fi

for REQUIRED_FILE in Dockerfile docker-compose.yml .env.example; do
  if [ ! -f "$REQUIRED_FILE" ]; then
    echo "Arquivo obrigatório não encontrado: $REQUIRED_FILE"
    echo "A equipe precisa corrigir o repositório antes da integração."
    exit 1
  fi
done

if [ ! -f ".env" ]; then
  echo "Criando .env a partir de .env.example..."
  cp .env.example .env
fi

echo "Subindo container do serviço $SERVICE_NAME..."
docker compose up -d --build

echo ""
echo "Logs recentes:"
docker logs --tail=50 "$SERVICE_NAME" || true

echo ""
echo "Serviço $SERVICE_NAME enviado para deploy."
echo ""
echo "Testes sugeridos:"
echo "  curl http://localhost:$PORT/health"
echo "  curl http://localhost/api/$DOMAIN/health"
echo ""
echo "Validação oficial pelo Load Balancer:"
echo "  curl http://$LOAD_BALANCER_IP/api/$DOMAIN/health"
echo ""
echo "Teste direto nesta VM, se necessário:"
echo "  curl http://$VM_IP/api/$DOMAIN/health"
echo ""
echo "Se o endpoint /health responder HTTP 200 pelo Load Balancer, o serviço está integrado ao Gateway redundante."
