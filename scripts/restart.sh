#!/bin/bash
set -e

echo "Reiniciando a infraestrutura..."
docker compose down
docker compose up -d
echo "Infraestrutura reiniciada."
