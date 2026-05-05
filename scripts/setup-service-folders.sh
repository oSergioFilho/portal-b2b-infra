#!/bin/bash
set -e

BASE_DIR="/opt/portal-b2b/services"

echo "Criando pastas dos microsserviços em $BASE_DIR..."

sudo mkdir -p "$BASE_DIR/usuarios-service"
sudo mkdir -p "$BASE_DIR/produtos-service"
sudo mkdir -p "$BASE_DIR/fornecimentos-service"
sudo mkdir -p "$BASE_DIR/demanda-service"
sudo mkdir -p "$BASE_DIR/mercado-service"
sudo mkdir -p "$BASE_DIR/negociacao-service"
sudo mkdir -p "$BASE_DIR/pedidos-service"
sudo mkdir -p "$BASE_DIR/logistica-service"
sudo mkdir -p "$BASE_DIR/transportadoras-service"

sudo chown -R "$USER:$USER" "$BASE_DIR"

echo ""
echo "Pastas criadas com sucesso:"
ls -la "$BASE_DIR"

echo ""
echo "Próximo passo:"
echo "Clone cada repositório de microsserviço na pasta correspondente."
echo "Exemplo:"
echo "  cd $BASE_DIR/produtos-service"
echo "  git clone LINK_DO_REPOSITORIO ."
