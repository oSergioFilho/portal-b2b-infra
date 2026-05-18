# Portas do Sistema

## Infraestrutura

- **API Gateway (Nginx):** `80`
- **PgAdmin:** `5050` (Acessível via `/pgadmin/` no Load Balancer)
- **Kafka UI:** `8080`

### Cluster Redpanda/Kafka (3 brokers)

- **Kafka API:** `9092` (produção/consumo de mensagens)
- **Redpanda RPC:** `33145` (comunicação entre brokers)
- **Redpanda Admin API:** `9644` (monitoramento)
- **Schema Registry:** `18081` (API para schemas Avro/Protobuf)
- **Pandaproxy:** `18082` (REST API do Kafka)

> **Nota:** As portas 8081 e 8082 são usadas pelos front-ends. Portanto, o Redpanda usa as portas 9092, 33145, 9644, 18081 e 18082. O `KAFKA_BOOTSTRAP_SERVERS` oficial é: `10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092`.

## Front-ends

- **produtos-front:** `8081`
- **portal-front / usuarios-front:** `8082`
- **fornecimentos-front:** `8083`
- **demandas-front (Demandas/Pedidos unificados):** `8084`
- **mercado-front:** `8085`
- **negociacao-front:** `8086`
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


