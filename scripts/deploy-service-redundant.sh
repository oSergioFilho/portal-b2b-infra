#!/bin/bash
set -e

SERVICE_NAME="$1"
REPO_URL="$2"

STANDBY_USER="${STANDBY_USER:-sergiofilho_almeida}"
STANDBY_HOST="${STANDBY_HOST:-34.59.229.37}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/portal_b2b_standby}"

INFRA_DIR="${INFRA_DIR:-/opt/portal-b2b/infra/portal-b2b-infra}"

LOAD_BALANCER_IP="${LOAD_BALANCER_IP:-34.8.17.245}"

if [ -z "$SERVICE_NAME" ] || [ -z "$REPO_URL" ]; then
  echo "Uso:"
  echo "bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO"
  echo ""
  echo "Exemplo:"
  echo "bash scripts/deploy-service-redundant.sh produtos-service https://github.com/PedroVian9/SDI.Micro.Produto"
  echo "bash scripts/deploy-service-redundant.sh vendas-service https://github.com/HenriqueSPaixao/portal-b2b-servico-vendas.git"
  exit 1
fi

# Verificar se a chave SSH existe
if [ ! -f "$SSH_KEY" ]; then
  echo "ERRO: chave SSH não encontrada em: $SSH_KEY"
  echo ""
  echo "Crie a chave na VM principal com:"
  echo "ssh-keygen -t ed25519 -f ~/.ssh/portal_b2b_standby -N \"\" -C \"portal-b2b-primary-to-standby\""
  echo ""
  echo "Depois adicione o conteúdo de ~/.ssh/portal_b2b_standby.pub no ~/.ssh/authorized_keys da VM standby."
  exit 1
fi

echo "======================================="
echo "Deploy do $SERVICE_NAME na VM principal"
echo "======================================="

cd "$INFRA_DIR"
bash scripts/deploy-service.sh "$SERVICE_NAME" "$REPO_URL"

echo ""
echo "====================================="
echo "Deploy do $SERVICE_NAME na VM standby"
echo "====================================="

ssh -i "$SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  "$STANDBY_USER@$STANDBY_HOST" "cd $INFRA_DIR && bash scripts/deploy-service.sh '$SERVICE_NAME' '$REPO_URL'"

echo ""
echo "Deploy redundante do serviço $SERVICE_NAME concluído nas duas VMs."
echo ""
echo "Validação sugerida pelo Load Balancer:"
echo "curl http://$LOAD_BALANCER_IP/health"

if [ "$SERVICE_NAME" == "vendas-service" ]; then
  echo "curl http://$LOAD_BALANCER_IP/api/mercado/health"
  echo "curl http://$LOAD_BALANCER_IP/api/negociacoes/health"
  echo "curl -I http://$LOAD_BALANCER_IP/mercado/"
  echo "curl -I http://$LOAD_BALANCER_IP/negociacao/"
else
  # Extrai o domínio principal do nome do serviço
  DOMAIN=$(echo "$SERVICE_NAME" | sed -e 's/-service//')
  if [ "$DOMAIN" == "negociacao" ]; then DOMAIN="negociacoes"; fi
  echo "curl http://$LOAD_BALANCER_IP/api/$DOMAIN/health"
fi
echo ""