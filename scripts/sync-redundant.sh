#!/bin/bash
set -e

STANDBY_USER="${STANDBY_USER:-sergiofilho_almeida}"
STANDBY_HOST="${STANDBY_HOST:-104.197.23.241}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/portal_b2b_standby}"

INFRA_DIR="${INFRA_DIR:-/opt/portal-b2b/infra/portal-b2b-infra}"

LOAD_BALANCER_IP="${LOAD_BALANCER_IP:-34.8.17.245}"

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

ssh -i "$SSH_KEY" "$STANDBY_USER@$STANDBY_HOST" <<'REMOTE'
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
