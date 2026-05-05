# Como as equipes se conectam

Antes de criar ou ajustar o microsserviço, consulte:
`docs/template-microsservico.md`

Todas as equipes devem usar o template como base mínima para Dockerfile, docker-compose.yml, .env.example e endpoint /health.

Na arquitetura atual, todos os microsserviços devem rodar como **containers Docker** na **VM Central** do projeto, compartilhando os mesmos recursos de banco de dados e mensageria através da rede `portal-b2b-network`.

## Tabela de Conexões e Responsabilidades

Cada equipe é responsável por um serviço que escuta em uma porta específica e responde atrás do API Gateway:

| Equipe | Serviço | Porta | Endpoint Gateway | Eventos publicados |
|---|---|---|---|---|
| Usuários | usuarios-service | 5001 | `/api/usuarios/` | `empresa_cadastrada` |
| Produtos | produtos-service | 5002 | `/api/produtos/` | `produto_cadastrado` |
| Fornecimentos | fornecimentos-service | 5003 | `/api/fornecimentos/` | `fornecimento_criado`, `estoque_atualizado` |
| Demanda | demanda-service | 5004 | `/api/demandas/` | `demanda_criada`, `demanda_recorrente_gerada` |
| Mercado | mercado-service | 5005 | `/api/mercado/` | `modo_negociacao_definido`, `leilao_iniciado` |
| Negociação | negociacao-service | 5006 | `/api/negociacoes/` | `lance_realizado`, `negociacao_fechada` |
| Pedidos | pedidos-service | 5007 | `/api/pedidos/` | `pedido_criado`, `pedido_atualizado` |
| Logística | logistica-service | 5008 | `/api/logistica/` | `solicitacao_frete_criada`, `frete_selecionado` |
| Transportadoras | transportadoras-service | 5009 | `/api/transportadoras/` | `cotacao_frete_enviada` |

## Conexão padrão em container (obrigatório)

O padrão oficial de execução é via Docker (container). Esse é o padrão oficial. Não use localhost dentro do container para banco ou Kafka. O microsserviço roda dentro da rede `portal-b2b-network` e acessa banco e mensageria pelos nomes dos serviços Docker:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

localhost dentro de um container aponta para o próprio container. Por isso, para acessar serviços da infraestrutura na rede Docker, devem ser usados os nomes dos containers/serviços: postgres e redpanda.

Exemplo mínimo de docker-compose.yml para microsserviço:

```yaml
services:
  produtos-service:
    build: .
    container_name: produtos-service
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "5002:5002"
    networks:
      - portal-b2b-network

networks:
  portal-b2b-network:
    external: true
```

**Importante:** Dentro de um container, `localhost` aponta para o próprio container, não para o host ou para outros serviços. Por isso, o host do banco é `postgres` e o host do Kafka é `redpanda`.

## Alternativa emergencial: rodar direto no host da VM (sem Docker)

Apenas em situações emergenciais justificadas, caso o microsserviço precise rodar diretamente no host da VM sem container:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@localhost:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

**Este não é o padrão oficial.** A entrega final deve ser dockerizada.

## Requisitos de Implementação

- **Rodar escutando em todos os IPs (0.0.0.0):** Para que o API Gateway consiga alcançar o seu microsserviço na VM, você DEVE subir o servidor web escutando em `0.0.0.0` (todos os endereços), e não apenas em `127.0.0.1` ou `localhost`.
  Exemplo (FastAPI/Uvicorn):
  ```bash
  uvicorn main:app --host 0.0.0.0 --port 5002
  ```
- **Endpoint de Health:** Todos os serviços **precisam** ter um endpoint `GET /health` operante.
  O Gateway Nginx deve conseguir acessar:
  - `GET http://IP_DA_VM/api/produtos/health`
  - `GET http://IP_DA_VM/api/demandas/health`
  - `GET http://IP_DA_VM/api/pedidos/health`
  - *(e assim por diante)*
