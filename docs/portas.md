# Portas do Sistema

## Infraestrutura
- **PostgreSQL:** `5432`
- **Redpanda (Kafka):** `9092`
- **PgAdmin:** `5050`
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

## Acesso Público
- **API Gateway:** `80`

## Acesso Privado
Somente o **API Gateway** deve ser exposto publicamente para acesso aos serviços. As demais portas (como Banco de Dados, Kafka, interfaces de gerência e microsserviços diretos) devem permanecer em rede privada ou protegidas por firewall.
