# Guia Oficial de Integração

## Regra principal de integração

Cada equipe é responsável por entregar o próprio microsserviço dockerizado. A equipe de infraestrutura mantém a configuração de acesso ao Cloud SQL PostgreSQL, Kafka/Redpanda, Kafka UI, PgAdmin, API Gateway e a rede Docker compartilhada. O PostgreSQL local permanece apenas como legado/fallback. A infraestrutura não instalará dependências manualmente de cada projeto.

---

## Ambiente atual de integração

A VM de integração já está disponível no Google Cloud Platform.

Acesso oficial:

- API Gateway: http://34.8.17.245
- Health do Gateway: http://34.8.17.245/health
- produtos-service: http://34.8.17.245/api/produtos/health
- Front produtos: http://34.8.17.245/produtos/

Diagnóstico direto:

- VM principal: http://34.29.84.207
- VM standby: http://104.197.23.241

> **Atenção:** O acesso oficial das APIs é pelo Load Balancer: `http://34.8.17.245/api/{dominio}`. O IP da VM principal (`34.29.84.207`) e da VM standby (`104.197.23.241`) devem ser usados apenas para diagnóstico direto. As equipes de microsserviços e front-end não devem usar o IP da VM principal como endpoint oficial. Front-ends devem chamar APIs usando o Load Balancer ou rotas relativas (ex: `/api/produtos`).
>
> Esse IP da VM principal pode ser usado pelas equipes para acessar o PgAdmin e Kafka UI durante a integração ou para testes diretos de diagnóstico. O banco oficial agora é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`. Dentro dos containers, o Kafka continua sendo acessado por `redpanda:9092`.

---

## 1. Objetivo do guia

Este documento é o **guia oficial** para as equipes conectarem seus microsserviços à infraestrutura central do Portal B2B. Ele foi projetado para que você consiga conectar, rodar e testar seu serviço sem precisar perguntar ao responsável pela infraestrutura.

A divisão de responsabilidades é muito clara:
- A **equipe de infraestrutura** entrega a VM central, Banco de Dados, Kafka, Gateway, PgAdmin e Kafka UI já configurados e rodando.
- A **equipe de banco de dados** cria as tabelas e o modelo relacional centralizado.
- As **equipes de microsserviços** (você) implementam as APIs, as regras de negócio e a publicação/consumo de eventos.

---

## 2. Visão geral da arquitetura

A arquitetura atual utiliza uma VM de aplicação no GCP (`34.29.84.207`) com banco de dados oficial em **Cloud SQL PostgreSQL** (`136.114.235.212`). A infraestrutura roda via Docker Compose, e cada microsserviço deve rodar como container próprio conectado à rede externa portal-b2b-network. A evolução para uma arquitetura redundante com duas VMs de aplicação está documentada em `docs/arquitetura-redundante-gcp.md`.

O fluxo de dados funciona assim:

```text
Usuário/Frontend
    ↓
API Gateway - Porta 80
    ↓
Microsserviço na VM - Porta 5001 a 5009
    ↓
Cloud SQL PostgreSQL - 136.114.235.212:5432
    ↓
Kafka/Redpanda - Porta 9092
    ↓
Outros microsserviços consumidores
```

---

## 3. O que roda na VM central

A VM central roda os componentes de aplicação e suporte. O banco oficial é externo (Cloud SQL).

**Infraestrutura (Docker Compose):**
- Nginx API Gateway
- Redpanda/Kafka
- Kafka UI
- PgAdmin
- PostgreSQL local (legado/fallback, ainda presente no Docker Compose)

**Banco oficial (externo à VM):**
- Cloud SQL PostgreSQL em `136.114.235.212`

O banco oficial **não é mais o PostgreSQL local**. O banco oficial é o Cloud SQL PostgreSQL em `136.114.235.212`.

**Microsserviços das equipes:**
- rodam como containers próprios.
- cada equipe mantém o próprio Dockerfile e docker-compose.yml.
- cada container publica sua porta oficial no host.
- cada container entra na rede portal-b2b-network.
- usuarios-service
- produtos-service
- fornecimentos-service
- demanda-service
- mercado-service
- negociacao-service
- pedidos-service
- logistica-service
- transportadoras-service

---

## 4. Endereços principais da infraestrutura

| Recurso | URL/Host | Porta | Uso |
|---|---|---|---|
| API Gateway / Load Balancer | `http://34.8.17.245` | 80 | Entrada oficial para APIs REST |
| VM principal | `http://34.29.84.207` | 80 | Diagnóstico direto |
| VM standby | `http://104.197.23.241` | 80 | Diagnóstico direto |
| PostgreSQL (Cloud SQL) | `136.114.235.212` | 5432 | Banco oficial (Cloud SQL) |
| PostgreSQL (local/legado) | `postgres` (container) / `34.29.84.207` (externo) | 5432 | Legado/fallback |
| PgAdmin | `http://34.29.84.207:5050` | 5050 | Administração visual do banco |
| Kafka/Redpanda | `redpanda` (container) / `34.29.84.207` (externo) | 9092 | Broker de eventos |
| Kafka UI | `http://34.29.84.207:8080` | 8080 | Visualizar tópicos e mensagens |

**Atenção:**
- O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`. Os microsserviços devem apontar para este IP.
- O host `postgres` (Docker Compose local) é **legado** e não deve mais ser usado como banco oficial.
- O Kafka/Redpanda continua sendo acessado por `redpanda:9092` dentro dos containers.
- Se estiver acessando visualmente **de fora** (ex: DBeaver no seu PC), use `136.114.235.212` para o banco.

---

## 5. Tabela oficial de portas

**Infraestrutura:**
- API Gateway: `80`
- PostgreSQL: `5432`
- PgAdmin: `5050`
- Kafka/Redpanda: `9092`
- Kafka UI: `8080`

**Microsserviços:**
- usuarios-service: `5001`
- produtos-service: `5002`
- fornecimentos-service: `5003`
- demanda-service: `5004`
- mercado-service: `5005`
- negociacao-service: `5006`
- pedidos-service: `5007`
- logistica-service: `5008`
- transportadoras-service: `5009`

**Regra inegociável:** Nenhuma equipe pode trocar a porta do serviço sem avisar a equipe de infraestrutura.

---

## 6. Tabela oficial dos microsserviços

| Equipe | Serviço | Porta | Gateway | Evento(s) que publica |
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

---

## 7. Como cada equipe deve configurar o .env

Todo microsserviço no Portal B2B deve conter um arquivo `.env` para carregar as configurações dinamicamente.

Regras importantes:
- O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`.
- Dentro de container, **NÃO usar localhost** para PostgreSQL. O host correto é `136.114.235.212`.
- Dentro de container, **NÃO usar localhost** para Kafka. O host correto é `redpanda`.
- O `localhost` só resolve dentro do próprio container, não alcança os outros serviços da rede Docker.
- O host `postgres` (Docker Compose local) é legado e não deve mais ser usado como banco oficial.

### Padrão OBRIGATÓRIO (Cloud SQL)

```env
SERVICE_NAME=produtos-service
PORT=5002

DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

> **Nota:** O host `postgres` do Docker Compose local é legado. O banco oficial é `136.114.235.212` (Cloud SQL). O container ainda precisa estar na rede `portal-b2b-network` para acessar o Kafka (`redpanda:9092`). Se a equipe esquecer essa rede no docker-compose.yml, a conexão com Kafka vai falhar.

### Alternativa emergencial: rodar direto no host da VM (sem Docker)

Se por algum motivo emergencial o serviço precisar rodar diretamente no host da VM, sem Docker:

```env
DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

> O banco continua sendo o Cloud SQL (`136.114.235.212`). O Kafka muda para `localhost:9092` pois sem Docker o Redpanda é acessado diretamente no host.

**Este não é o padrão oficial.** A entrega sem Docker será aceita apenas em situações emergenciais justificadas.

---

## 8. Como rodar o microsserviço na VM

A execução do microsserviço é **estritamente via Docker**. A execução direta na VM (com `uvicorn`, `npm start`, `java -jar`) deve ficar apenas como alternativa emergencial.

- **Docker é obrigatório para integração.**
- Cada equipe deve entregar `Dockerfile`.
- Cada equipe deve entregar `docker-compose.yml`.
- Cada equipe deve entregar `.env.example`.
- Cada equipe deve subir seu próprio container na VM.
- A infraestrutura **não instala dependências manualmente**.
- A infraestrutura **não roda** `pip install`, `npm install`, `maven`, `gradle` etc. para cada equipe.
- A infraestrutura **não corrige código de microsserviço**.
- Sem `Dockerfile`, `docker-compose.yml`, `.env.example` e endpoint `/health` funcionando, o serviço não será aceito para integração.

Ao subir seu `docker-compose.yml`, seu container será anexado à rede `portal-b2b-network` e estará pronto para responder ao Gateway e se conectar ao PostgreSQL e Kafka.

### Padrão obrigatório de docker-compose.yml do microsserviço

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

**Observações importantes:**
- `container_name` deve ser igual ao nome do serviço.
- A porta deve ser a porta oficial.
- Não subir outro PostgreSQL no compose do microsserviço.
- Não subir outro Kafka no compose do microsserviço.
- A rede `portal-b2b-network` já é criada pela infraestrutura.
- O serviço precisa expor `/health`.

**Exemplos rápidos de portas:**
- `usuarios-service`: porta 5001
- `produtos-service`: porta 5002
- `demanda-service`: porta 5004
- `pedidos-service`: porta 5007

### Exemplos de Dockerfile

**Exemplo de Dockerfile para FastAPI**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5002

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5002"]
```
*(A porta deve ser trocada conforme o seu serviço).*

**Exemplo de Dockerfile para Node.js/Express**
```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5002

CMD ["npm", "start"]
```

**Exemplo de Express escutando em `0.0.0.0`:**
```javascript
const port = process.env.PORT || 5002;

app.listen(port, "0.0.0.0", () => {
  console.log(`Service running on port ${port}`);
});
```

### Como subir seu microsserviço na VM

Passo a passo:
```bash
cd /opt/portal-b2b/services
git clone LINK_DO_REPOSITORIO nome-service
cd nome-service
cp .env.example .env
docker compose up -d --build
docker ps
docker logs -f nome-service
```

O responsável pela infraestrutura só deve validar a integração depois que a equipe conseguir executar:

```bash
docker compose up -d --build
```

dentro da pasta do próprio microsserviço.

**Exemplo completo para produtos-service:**
```bash
cd /opt/portal-b2b/services
git clone LINK_DO_REPOSITORIO produtos-service
cd produtos-service
cp .env.example .env
docker compose up -d --build
docker logs -f produtos-service
```

---

### Deploy controlado pela infraestrutura

Nesta primeira etapa, para evitar alterações indevidas na VM, o deploy dos microsserviços será feito de forma controlada pelo responsável da infraestrutura.

Cada equipe deverá enviar:

- Nome do serviço (ex: `produtos-service`).
- Link do repositório GitHub.
- Porta oficial.
- Confirmação de `Dockerfile`.
- Confirmação de `docker-compose.yml`.
- Confirmação de `.env.example`.
- Confirmação de `GET /health`.

A infraestrutura irá usar:

```bash
bash scripts/deploy-service.sh nome-service URL_DO_REPOSITORIO
```

Para o passo a passo completo, consulte:

[docs/deploy-microsservicos-na-vm.md](./docs/deploy-microsservicos-na-vm.md)

---

## 9. Como o API Gateway encaminha as chamadas

A comunicação com as suas rotas externas passará pelo Nginx Gateway.

Se o Frontend fizer uma requisição para:
`GET /api/produtos/health`

O Nginx **remove o prefixo** `/api/produtos/` e encaminha apenas `/health` para o `produtos-service` na porta 5002.

### Tabela de Exemplos de Roteamento

| Chamada pelo Gateway | Chega no serviço |
|---|---|
| `/api/usuarios/health` | `/health` na porta 5001 |
| `/api/produtos/health` | `/health` na porta 5002 |
| `/api/fornecimentos/health`| `/health` na porta 5003 |
| `/api/demandas/health` | `/health` na porta 5004 |
| `/api/mercado/health` | `/health` na porta 5005 |
| `/api/negociacoes/health`| `/health` na porta 5006 |
| `/api/pedidos/health` | `/health` na porta 5007 |
| `/api/logistica/health` | `/health` na porta 5008 |
| `/api/transportadoras/health`| `/health` na porta 5009 |

**Aviso:**
O seu microsserviço **NÃO DEVE** criar rotas internas começando com `/api/produtos` ou `/api/pedidos`. A rota no seu código deve ser apenas `/health`, `/listar`, `/cadastrar`. O prefixo `/api/...` é responsabilidade exclusiva do Gateway.

---

## 10. Como testar seu serviço

Uma vez que seu serviço está rodando em container, teste:

**Teste direto:**
```bash
curl http://localhost:5002/health
```

**Teste pelo Gateway:**
```bash
curl http://localhost/api/produtos/health
```

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/api/produtos/health
```

**Teste direto na VM principal, somente diagnóstico:**
```bash
curl http://34.29.84.207/api/produtos/health
```

**Teste direto na VM standby, somente diagnóstico:**
```bash
curl http://104.197.23.241/api/produtos/health
```

> **Observação:** Front-ends devem chamar APIs usando rotas relativas, como `/api/produtos`, ou o Load Balancer `http://34.8.17.245/api/produtos`. Não usar o IP da VM principal como endpoint oficial.

O Gateway continua encaminhando pelo Nginx para a porta oficial publicada no host. O retorno esperado deve ser:
```json
{
  "status": "ok",
  "service": "produtos-service"
}
```

---

## 11. Como conectar ao PostgreSQL

O banco de dados oficial do projeto é o **Cloud SQL PostgreSQL**.

- **Host:** `136.114.235.212`
- **Banco:** `portal_b2b`
- **Schema:** `portal_b2b`
- **Porta:** `5432`

> **Nota:** O PostgreSQL local do Docker Compose (`postgres:5432`) é legado. O banco oficial é o Cloud SQL.

Existem credenciais separadas por responsabilidade.

**Usuário dos microsserviços (Aplicação):**
- Usuário: `svc_portal_b2b`
- Senha: `***` *(fornecida pela equipe de infraestrutura)*

**Usuário da equipe de banco (DDL):**
- Usuário: `db_portal_b2b`
- Senha: `***` *(fornecida pela equipe de infraestrutura)*

Ninguém, sob nenhuma hipótese, deve usar o usuário `postgres` na aplicação.

---

## 12. Diferença entre usuário de banco e usuário de aplicação

| Usuário | Quem usa | Para quê |
|---|---|---|
| `postgres` | Infraestrutura | Administração geral do banco. |
| `db_portal_b2b` | Equipe de banco | Criar e alterar tabelas, views, constraints e estrutura do banco (DDL). |
| `svc_portal_b2b`| Microsserviços | Ler (SELECT), inserir (INSERT), atualizar (UPDATE) e excluir (DELETE) dados da aplicação (DML). |

**Aviso muito importante para Microsserviços:**
Os microsserviços **não devem fazer DDL**. Você deve **desativar** qualquer flag de `auto-migrate`, `sync` ou geração automática de esquema do seu ORM (ex: Sequelize, TypeORM, Hibernate) se ele tentar criar tabelas na inicialização. A criação de tabelas é responsabilidade exclusiva da equipe de banco.

---

## 13. Como acessar pelo PgAdmin

O PgAdmin é a interface web de banco providenciada pela infraestrutura.

- **URL:** `http://34.29.84.207:5050`
- **Login:** `admin@portalb2b.com`
- **Senha:** `***`

Para cadastrar a conexão com o banco de dados **dentro do PgAdmin**, aponte para o Cloud SQL:
- **Host:** `136.114.235.212`
- **Port:** `5432`
- **Database:** `portal_b2b`
- **User:** `db_portal_b2b` (Se for equipe de banco)
- **Password:** `***` *(fornecida pela equipe de infraestrutura)*

> **Nota:** O host `postgres` (Docker Compose local) ainda funciona para o banco legado, mas o banco oficial é o Cloud SQL.

---

## 14. Como acessar pelo DBeaver/DataGrip/psql

Se preferir usar sua ferramenta favorita instalada no seu PC:

- **Host:** `136.114.235.212`
- **Port:** `5432`
- **Database:** `portal_b2b`
- **User:** `db_portal_b2b` ou `svc_portal_b2b`
- **Password:** A senha correspondente ao usuário.

Exemplo de string de conexão para `psql`:
```bash
psql "postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b"
```

---

## 15. Como conectar ao Kafka/Redpanda

A mensageria utiliza Redpanda (100% compatível com a API do Apache Kafka).

**Para microsserviços rodando em container na VM (padrão obrigatório):**
```env
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

**Para microsserviços rodando direto no host da VM (alternativa emergencial):**
```env
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

**Para ferramentas rodando de fora da VM:**
```env
KAFKA_BOOTSTRAP_SERVERS=34.29.84.207:9092
```

Para monitorar tópicos e mensagens em tempo real, utilize a interface do **Kafka UI**:
- URL: `http://34.29.84.207:8080`

---

## 16. Lista de tópicos Kafka disponíveis

Abaixo estão os tópicos oficiais do barramento:

- `empresa_cadastrada`
- `produto_cadastrado`
- `fornecimento_criado`
- `estoque_atualizado`
- `demanda_criada`
- `demanda_recorrente_gerada`
- `modo_negociacao_definido`
- `leilao_iniciado`
- `lance_realizado`
- `negociacao_fechada`
- `pedido_criado`
- `pedido_atualizado`
- `solicitacao_frete_criada`
- `cotacao_frete_enviada`
- `frete_selecionado`

---

## 17. Padrão obrigatório dos eventos Kafka

Todo evento postado no barramento **deve obrigatoriamente** ser envelopado neste padrão JSON exato:

```json
{
  "eventId": "uuid",
  "eventType": "nome_do_evento",
  "eventVersion": "1.0",
  "timestamp": "ISO8601",
  "source": "nome-do-servico",
  "correlationId": "uuid",
  "payload": {}
}
```

**Regras:**
- **Nome do tópico:** Deve ser **exatamente igual** ao valor do campo `eventType`.
- **eventId:** Deve ser um UUID único gerado para este disparo específico.
- **timestamp:** Data/hora no formato ISO8601.
- **source:** O nome do seu microsserviço (ex: `produtos-service`).
- **correlationId:** UUID compartilhado para rastrear um fluxo entre vários serviços.
- **payload:** Um objeto JSON contendo os dados de negócio do seu domínio. Não há padrão estrito para dentro do payload.
- **Não publique eventos fora desse padrão de envelope.**

---

## 18. O que cada equipe deve publicar

| Serviço | Publica |
|---|---|
| `usuarios-service` | `empresa_cadastrada` |
| `produtos-service` | `produto_cadastrado` |
| `fornecimentos-service` | `fornecimento_criado`, `estoque_atualizado` |
| `demanda-service` | `demanda_criada`, `demanda_recorrente_gerada` |
| `mercado-service` | `modo_negociacao_definido`, `leilao_iniciado` |
| `negociacao-service` | `lance_realizado`, `negociacao_fechada` |
| `pedidos-service` | `pedido_criado`, `pedido_atualizado` |
| `logistica-service` | `solicitacao_frete_criada`, `frete_selecionado` |
| `transportadoras-service`| `cotacao_frete_enviada` |

---

## 19. O que cada equipe deve consumir

Sugestão de fluxo inicial de mensageria assíncrona (A confirmar com alinhamentos de negócio):

- `fornecimentos-service` pode consumir `produto_cadastrado` e `empresa_cadastrada`.
- `demanda-service` pode consumir `produto_cadastrado` e `empresa_cadastrada`.
- `mercado-service` consome `fornecimento_criado`, `estoque_atualizado` e `demanda_criada`.
- `negociacao-service` consome `modo_negociacao_definido` e `leilao_iniciado`.
- `pedidos-service` consome `negociacao_fechada`.
- `logistica-service` consome `pedido_criado`.
- `transportadoras-service` consome `solicitacao_frete_criada`.

**Aviso:**
Os eventos consumidos devem ser confirmados entre as equipes de acordo com o mapeamento e a regra de negócio estabelecida.

---

## 20. O que cada equipe precisa entregar para integração

Antes de dar seu microsserviço como concluído, valide se a sua equipe preparou esta **lista obrigatória**:

- [ ] Repositório do microsserviço;
- [ ] `Dockerfile` (obrigatório);
- [ ] `docker-compose.yml` (obrigatório);
- [ ] `.env.example` (obrigatório);
- [ ] Porta oficial configurada para rodar e escutar em `0.0.0.0`;
- [ ] Serviço publica a porta oficial no host da VM;
- [ ] Serviço entra na rede `portal-b2b-network`;
- [ ] Endpoint `GET /health` funcionando;
- [ ] Swagger/OpenAPI funcionando (ex: `/docs` ou `/api-docs`);
- [ ] Lista de endpoints REST mapeados;
- [ ] Eventos Kafka que publica programados;
- [ ] Eventos Kafka que consome programados;
- [ ] Tabelas que usa acordadas com equipe de DB.

---

## 21. Erros comuns e como resolver

| Erro | Causa provável | Solução |
|---|---|---|
| `connection refused` no PostgreSQL | host incorreto, Cloud SQL inacessível ou IP de origem não autorizado no Cloud SQL | usar `136.114.235.212:5432` no `DATABASE_URL` e confirmar se o IP de origem está autorizado no Cloud SQL |
| `connection refused` no Kafka | usou `localhost` dentro do container | usar `redpanda:9092` |
| `network portal-b2b-network not found` | infra não foi subida | subir infra primeiro |
| Gateway `502` | container não está rodando ou porta errada | verificar `docker ps`, logs e ports |
| `permission denied` no banco | aplicação tentou criar tabela | desativar auto-migrate/sync |
| porta já em uso | outro container está usando a porta | verificar `docker ps` |
| Swagger não abre | rota não exposta | testar primeiro direto na porta |

---

## 22. Checklist final antes de chamar o responsável pela infra

- [ ] Meu serviço roda na porta oficial.
- [ ] Meu serviço escuta em `0.0.0.0`.
- [ ] Meu `.env` usa `DATABASE_URL` correta (`svc_portal_b2b` e `portal_b2b`).
- [ ] Meu `.env` usa `KAFKA_BOOTSTRAP_SERVERS` correto.
- [ ] `GET /health` funciona localmente.
- [ ] `GET /api/meu-dominio/health` funciona pelo Gateway.
- [ ] Swagger está acessível.
- [ ] Não estou usando o usuário `postgres`.
- [ ] Não estou tentando criar tabela pela aplicação.
- [ ] Sei quais eventos publico.
- [ ] Sei quais eventos consumo.
- [ ] As tabelas que uso foram alinhadas com a equipe de banco.

---

## 23. Resumo rápido por equipe

### Usuários
- Porta `5001`
- Gateway `/api/usuarios/`
- Evento `empresa_cadastrada`

### Produtos
- Porta `5002`
- Gateway `/api/produtos/`
- Evento `produto_cadastrado`

### Fornecimentos
- Porta `5003`
- Gateway `/api/fornecimentos/`
- Eventos `fornecimento_criado`, `estoque_atualizado`

### Demanda
- Porta `5004`
- Gateway `/api/demandas/`
- Eventos `demanda_criada`, `demanda_recorrente_gerada`

### Mercado
- Porta `5005`
- Gateway `/api/mercado/`
- Eventos `modo_negociacao_definido`, `leilao_iniciado`

### Negociação
- Porta `5006`
- Gateway `/api/negociacoes/`
- Eventos `lance_realizado`, `negociacao_fechada`

### Pedidos
- Porta `5007`
- Gateway `/api/pedidos/`
- Eventos `pedido_criado`, `pedido_atualizado`

### Logística
- Porta `5008`
- Gateway `/api/logistica/`
- Eventos `solicitacao_frete_criada`, `frete_selecionado`

### Transportadoras
- Porta `5009`
- Gateway `/api/transportadoras/`
- Evento `cotacao_frete_enviada`

---

## 24. Contrato obrigatório do endpoint /health

Todo microsserviço precisa expor:

`GET /health`

**Resposta esperada:**
```json
{
  "status": "ok",
  "service": "produtos-service"
}
```

**Regras:**
- status deve ser "ok".
- service deve ser o nome oficial do serviço.
- o endpoint deve retornar HTTP 200.
- o endpoint deve funcionar direto na porta do serviço e também pelo Gateway.

**Exemplo:**
Direto na VM:
```bash
curl http://localhost:5002/health
```
Pelo Gateway:
```bash
curl http://localhost/api/produtos/health
```

---

## 25. Estrutura recomendada da VM

```text
/opt/portal-b2b/
├── infra/
│   └── portal-b2b-infra/
└── services/
    ├── usuarios-service/
    ├── produtos-service/
    ├── fornecimentos-service/
    ├── demanda-service/
    ├── mercado-service/
    ├── negociacao-service/
    ├── pedidos-service/
    ├── logistica-service/
    └── transportadoras-service/
```

Cada equipe deve clonar o próprio repositório dentro de `/opt/portal-b2b/services`.

---

## 26. Como o responsável pela infraestrutura valida os serviços

- A equipe sobe o próprio container.
- A equipe confirma que `docker compose up -d --build` funcionou.
- A equipe confirma que `docker logs -f nome-do-container` não mostra erro.
- O responsável pela infraestrutura testa diretamente:

```bash
curl http://localhost:PORTA/health
```

- Depois testa pelo Gateway:

```bash
curl http://localhost/api/DOMINIO/health
```

- Por fim, pode rodar:

```bash
bash scripts/check-services.sh
```

---

## 27. Redundância e plano de recuperação

A infraestrutura possui mecanismos básicos de resiliência e um plano de recuperação documentado:

- **Se um container cair**, o Docker tenta reiniciar automaticamente (política `restart: unless-stopped`).
- **O banco oficial está no Cloud SQL**, que possui backups automáticos e exportações gerenciadas pelo GCP.
- **Os scripts `backup-postgres.sh` e `restore-postgres.sh` validam backup e restore do PostgreSQL local legado.** O banco oficial atual está no Cloud SQL, e os backups principais devem ser feitos pelas ferramentas do GCP/Cloud SQL.
  - **Aviso:** Os backups do banco local são responsabilidade operacional da infraestrutura.
  - As equipes de microsserviços não devem executar restore do banco.
  - Restore deve ser feito apenas pela equipe de infraestrutura, preferencialmente na VM standby ou ambiente limpo.
- **Existe um plano de VM standby** para recuperação em caso de queda completa da VM principal. A VM standby pode ser ativada com a infraestrutura clonada, apontando para o mesmo Cloud SQL.
- **Isso não substitui alta disponibilidade real**, mas atende ao plano acadêmico de recuperação com procedimentos documentados e testáveis.

Para o plano completo, consulte: [docs/redundancia-e-recuperacao.md](./docs/redundancia-e-recuperacao.md)

---

## 28. Front-ends dos microsserviços

Se o repositório da equipe tiver front-end, ele também deve ser dockerizado. A infraestrutura **não executará** `npm install` ou `npm run dev` manualmente como solução final. Para o padrão recomendado, consulte:

[docs/deploy-frontends-na-vm.md](./docs/deploy-frontends-na-vm.md)

---

## 29. Banco de dados oficial — Cloud SQL PostgreSQL

O banco oficial do projeto é o **Cloud SQL PostgreSQL**:

```text
Host: 136.114.235.212
Banco: portal_b2b
Schema: portal_b2b
```

Todos os microsserviços devem usar:

```env
DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
```

> **Importante:** O host `postgres:5432` do Docker Compose local é legado. Não usar como banco oficial.

Para detalhes sobre a arquitetura redundante e a migração, consulte:

[docs/arquitetura-redundante-gcp.md](./docs/arquitetura-redundante-gcp.md)

[docs/migracao-cloud-sql.md](./docs/migracao-cloud-sql.md)
