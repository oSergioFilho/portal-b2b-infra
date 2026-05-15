# Portas do Sistema

## Infraestrutura

- **API Gateway (Nginx):** `80`
- **PgAdmin:** `5050` (Acessível via `/pgadmin/` no Load Balancer)
- **Kafka UI:** `8080`

### Cluster Redpanda/Kafka (3 brokers)

- **Kafka API:** `9092` (produção/consumo de mensagens)
- **Redpanda RPC:** `33145` (comunicação entre brokers)
- **Redpanda Admin API:** `9644` (monitoramento)

> **Nota:** Schema Registry (8081) e Pandaproxy (8082) estão **desativados** no cluster para evitar conflito com os front-ends. Se necessário no futuro, podem ser ativados em portas alternativas (ex: 18081 e 18082).

## Front-ends

- **produtos-front:** `8081`
- **portal-front / usuarios-front:** `8082`
- **fornecimentos-front:** `8083`
- **demandas-front:** `8084`
- **mercado-front:** `8085`
- **negociacao-front:** `8086`
- **pedidos-front:** `8087`
- **logistica-front:** `8088`

## Microsserviços (APIs)

- **usuarios-service:** `5001`
- **produtos-service:** `5002`
- **fornecimentos-service:** `5003`
- **demanda-service:** `5004`
- **mercado-service:** `5005`
- **negociacao-service:** `5006`
- **pedidos-service:** `5007`
- **logistica-service:** `5008`

## Banco de dados

- **Cloud SQL PostgreSQL:** `5432` (externo, `136.114.235.212`)

## Segurança

- Em ambiente de desenvolvimento acadêmico, as portas podem ficar disponíveis na VM para teste e facilitação do aprendizado.
- Idealmente, em produção, somente o **API Gateway (Porta 80)** deveria ficar exposto publicamente para acesso aos serviços.
- PostgreSQL, Kafka, PgAdmin e Kafka UI devem ser protegidos por firewall, VPN ou regra de acesso da VM (Security Groups), garantindo que apenas membros da equipe acessem.
- **Atenção:** Não usar as credenciais de `admin` ou do `db_portal_b2b` nos microsserviços. Os microsserviços devem usar apenas `svc_portal_b2b`.

## Schema Registry / Pandaproxy (opcional — futuro)

Se Schema Registry ou Pandaproxy forem necessários, ativar em portas alternativas para evitar conflito com os front-ends:

- **Schema Registry:** `18081` (em vez de 8081)
- **Pandaproxy:** `18082` (em vez de 8082)

Para ativar no `redpanda/docker-compose.cluster.yml`, adicionar ao command:

```yaml
- --schema-registry-addr=0.0.0.0:18081
- --advertise-schema-registry-addr=${REDPANDA_ADVERTISE_IP}:18081
- --pandaproxy-addr=0.0.0.0:18082
- --advertise-pandaproxy-addr=${REDPANDA_ADVERTISE_IP}:18082
```

E liberar as portas no firewall:

```bash
gcloud compute firewall-rules update allow-redpanda-internal \
  --rules=tcp:9092,tcp:33145,tcp:9644,tcp:18081,tcp:18082
```
