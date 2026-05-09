# Portas do Sistema

## Infraestrutura

- **API Gateway:** `80`
- **PostgreSQL:** `5432`
- **PgAdmin:** `5050` (Acessível via `/pgadmin/` no Load Balancer)
- **Kafka/Redpanda:** `9092`
- **Kafka UI:** `8080`

## Microsserviços

- **usuarios-service:** `5001`
- **produtos-service:** `5002`
- **fornecimentos-service:** `5003`
- **demanda-service:** `5004`
- **mercado-service:** `5005`
- **negociacao-service:** `5006`
- **pedidos-service:** `5007`
- **logistica-service:** `5008`
- **transportadoras-service:** `5009`

## Segurança

- Em ambiente de desenvolvimento acadêmico, as portas podem ficar disponíveis na VM para teste e facilitação do aprendizado.
- Idealmente, em produção, somente o **API Gateway (Porta 80)** deveria ficar exposto publicamente para acesso aos serviços.
- PostgreSQL, Kafka, PgAdmin e Kafka UI devem ser protegidos por firewall, VPN ou regra de acesso da VM (Security Groups), garantindo que apenas membros da equipe acessem.
- **Atenção:** Não usar as credenciais de `admin` ou do `db_portal_b2b` nos microsserviços. Os microsserviços devem usar apenas `svc_portal_b2b`.
