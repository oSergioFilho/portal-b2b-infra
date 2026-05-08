# Observabilidade e Painel de Status

## Objetivo

Documentar o painel de status da infraestrutura usando Uptime Kuma.

## Acesso

**Uptime Kuma:**
http://104.197.23.241:3001

**Status Page:**
http://104.197.23.241:3001/status/portal-b2b-status

## Onde roda

O Uptime Kuma roda na VM standby:

```text
104.197.23.241
```

## Componentes monitorados

- Load Balancer: `http://34.8.17.245/health`
- VM principal: `http://34.29.84.207/health`
- VM standby: `http://104.197.23.241/health`
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
