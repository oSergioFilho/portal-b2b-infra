#!/bin/bash
set -e

STANDBY_USER="${STANDBY_USER:-sergiofilho_almeida}"
STANDBY_HOST="${STANDBY_HOST:-104.197.23.241}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/portal_b2b_standby}"

INFRA_DIR="${INFRA_DIR:-/opt/portal-b2b/infra/portal-b2b-infra}"

LOAD_BALANCER_IP="${LOAD_BALANCER_IP:-34.8.17.245}"

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

echo "========================================="
echo "Sincronizando infraestrutura na principal"
echo "========================================="

cd "$INFRA_DIR"

echo "VM principal:"
hostname

git pull origin main
docker compose up -d --build
bash scripts/check-infra.sh

echo ""
echo "======================================="
echo "Sincronizando infraestrutura na standby"
echo "======================================="

ssh -i "$SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  "$STANDBY_USER@$STANDBY_HOST" <<'REMOTE'
set -e

INFRA_DIR="${INFRA_DIR:-/opt/portal-b2b/infra/portal-b2b-infra}"

git config --global --add safe.directory "$INFRA_DIR" || true

cd "$INFRA_DIR"

echo "VM standby:"
hostname

git pull origin main
docker compose up -d --build
bash scripts/check-infra.sh
REMOTE

echo ""
echo "Sincronização concluída nas duas VMs."
echo ""
echo "Validação sugerida pelo Load Balancer:"
echo "curl http://$LOAD_BALANCER_IP/health"
echo "curl http://$LOAD_BALANCER_IP/api/produtos/health"
