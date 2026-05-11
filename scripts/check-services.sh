#!/bin/bash
set -e

echo "Iniciando teste dos microsserviços pelo Gateway..."
echo "=================================================="

SERVICES=(
    "usuarios"
    "produtos"
    "fornecimentos"
    "demandas"
    "mercado"
    "negociacoes"
    "pedidos"
    "logistica"

)

HAS_ERROR=0

for SERVICE in "${SERVICES[@]}"; do
    URL="http://localhost/api/$SERVICE/health"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$URL")
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "[OK] $SERVICE-service disponível"
    else
        echo "[ERRO] $SERVICE-service não respondeu (HTTP $HTTP_CODE)"
        HAS_ERROR=1
    fi
done

echo "=================================================="

if [ "$HAS_ERROR" -eq 1 ]; then
    echo "Resumo: Alguns serviços falharam no teste."
    exit 1
else
    echo "Resumo: Todos os serviços estão disponíveis!"
    exit 0
fi
