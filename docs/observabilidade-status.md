# Observabilidade e Painel de Status

## Objetivo

Documentar o painel de status da infraestrutura usando Uptime Kuma.

## Acesso

**Uptime Kuma:**
http://34.59.229.37:3001

**Status Page:**
http://34.59.229.37:3001/status/portal-b2b-status

## Onde roda

O Uptime Kuma roda na VM standby:

```text
34.59.229.37
```

## Componentes monitorados

- Load Balancer: `http://34.8.17.245/health`
- VM principal: `http://34.29.84.207/health`
- VM standby: `http://34.59.229.37/health`
- produtos-service: `http://34.8.17.245/api/produtos/health`
- Cloud SQL: `136.114.235.212:5432`
- Kafka UI
- PgAdmin
- Redpanda/Kafka

## Observações

- O Uptime Kuma é painel visual de status.
- Não substitui Prometheus/Grafana.
- Não documentar senha do painel no Git.
- Para métricas detalhadas, evoluir para Prometheus, Node Exporter e Grafana.

## Interpretação durante apresentação

Durante teste de falha da VM principal, o comportamento esperado é:

- VM Principal - Gateway: DOWN
- VM Standby - Gateway: UP
- Load Balancer - Gateway: UP
- produtos-service via Load Balancer: UP
- Cloud SQL: UP

Isso demonstra que a aplicação continua disponível mesmo com falha na VM principal.

## Intervalo de checagem

O Uptime Kuma usa intervalo mínimo de 20 segundos. Para registrar falhas visualmente, deixar a falha ativa por pelo menos 1 minuto durante a apresentação.

## Operação

Comandos:

```bash
gcloud compute ssh portal-b2b-vm-standby --zone=us-central1-a
cd /opt/portal-b2b/monitoring/uptime-kuma
docker ps | grep uptime
docker compose logs -f
docker compose restart
docker compose up -d
```
