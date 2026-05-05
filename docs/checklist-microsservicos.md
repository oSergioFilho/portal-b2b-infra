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
