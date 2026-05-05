# Checklist de Entrega dos Microsserviços

Para garantir a integração suave com a infraestrutura centralizada do Portal B2B, cada equipe de desenvolvimento de microsserviço deve entregar seu projeto contendo os seguintes requisitos devidamente implementados e documentados em seu próprio repositório.

## Checklist

- [ ] **Dockerfile obrigatório**: Um `Dockerfile` válido que instale dependências, copie o código e exponha a porta oficial.
- [ ] **docker-compose.yml obrigatório**: Arquivo configurado para mapear a porta, ler o `.env` e usar a rede `portal-b2b-network`.
- [ ] O compose usa a rede externa `portal-b2b-network`.
- [ ] O compose não sobe outro banco.
- [ ] O compose não sobe outro Kafka.
- [ ] `.env.example` usa `postgres` e `redpanda` quando rodar em container.
- [ ] Serviço roda na porta oficial (ex: `5002`).
- [ ] Porta está mapeada corretamente (ex: `"5002:5002"`).
- [ ] `GET /health` responde corretamente.
- [ ] Swagger funciona e expõe os endpoints.
- [ ] Eventos Kafka seguem o envelope padrão.
- [ ] Aplicação não tenta criar tabelas automaticamente (DDL automático desativado).
- [ ] O container_name no docker-compose.yml está igual ao nome oficial do serviço.
- [ ] O serviço publica a porta oficial no host da VM usando o formato "PORTA:PORTA".
- [ ] O serviço não usa localhost para acessar PostgreSQL quando roda em container.
- [ ] O serviço não usa localhost para acessar Kafka quando roda em container.
- [ ] O serviço usa postgres:5432 para acessar PostgreSQL em container.
- [ ] O serviço usa redpanda:9092 para acessar Kafka em container.
- [ ] O comando docker compose up -d --build funciona sem intervenção manual.
- [ ] O comando docker logs -f nome-do-container mostra os logs do serviço.
- [ ] O endpoint GET /health retorna HTTP 200.
- [ ] O endpoint GET /health retorna JSON com status igual a "ok".
- [ ] O endpoint GET /health retorna o campo service com o nome oficial do serviço.
- [ ] O serviço foi testado diretamente na porta oficial.
- [ ] O serviço foi testado pelo API Gateway.
- [ ] O serviço passou no script scripts/check-services.sh, quando aplicável.
