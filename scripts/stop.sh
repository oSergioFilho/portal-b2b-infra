#!/bin/bash
set -e

echo "Parando a infraestrutura..."
docker compose down
echo "Infraestrutura parada com sucesso."
