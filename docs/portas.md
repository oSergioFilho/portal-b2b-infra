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

## Acesso Público e Segurança
Somente o **API Gateway (Porta 80)** deve ser exposto publicamente para acesso aos serviços. 

**ATENÇÃO À SEGURANÇA EM VM CENTRAL:**
- Em ambiente local, as portas podem ficar abertas no `localhost`.
- Em uma VM pública, **NÃO EXPONHA** as portas de banco de dados, Kafka e interfaces visuais (5432, 9092, 5050, 8080) diretamente para a internet.
- Use Firewall, Security Groups ou uma rede VPN privada como **Tailscale** ou **ZeroTier** para garantir que apenas os colegas autorizados tenham acesso a essas ferramentas da infraestrutura.
