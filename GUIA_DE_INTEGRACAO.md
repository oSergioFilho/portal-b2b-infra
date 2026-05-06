# Guia Oficial de Integração

## Regra principal de integração

Cada equipe é responsável por entregar o próprio microsserviço dockerizado. A equipe de infraestrutura mantém PostgreSQL, Kafka/Redpanda, Kafka UI, PgAdmin, API Gateway e a rede Docker compartilhada. A infraestrutura não instalará dependências manualmente de cada projeto.

---

## Ambiente atual da VM

A VM de integração já está disponível no Google Cloud Platform.

IP público atual:

```text
34.29.84.207
```

Acessos:

- API Gateway: http://34.29.84.207
- Health do Gateway: http://34.29.84.207/health
- PgAdmin: http://34.29.84.207:5050
- Kafka UI: http://34.29.84.207:8080

> **Observação:** Esse IP deve ser usado pelas equipes para acessar o Gateway, PgAdmin e Kafka UI durante a integração. Dentro dos containers dos microsserviços, o banco e o Kafka continuam sendo acessados por `postgres:5432` e `redpanda:9092`, não pelo IP público.

---

## 1. Objetivo do guia

Este documento é o **guia oficial** para as equipes conectarem seus microsserviços à infraestrutura central do Portal B2B. Ele foi projetado para que você consiga conectar, rodar e testar seu serviço sem precisar perguntar ao responsável pela infraestrutura.

A divisão de responsabilidades é muito clara:
- A **equipe de infraestrutura** entrega a VM central, Banco de Dados, Kafka, Gateway, PgAdmin e Kafka UI já configurados e rodando.
- A **equipe de banco de dados** cria as tabelas e o modelo relacional centralizado.
- As **equipes de microsserviços** (você) implementam as APIs, as regras de negócio e a publicação/consumo de eventos.

---

## 2. Visão geral da arquitetura

A arquitetura do Portal B2B exige que **todos os serviços e ferramentas rodem na mesma VM central. A infraestrutura roda via Docker Compose, e cada microsserviço deve rodar como container próprio conectado à rede externa portal-b2b-network.**

O fluxo de dados funciona assim:

```text
Usuário/Frontend
    ↓
API Gateway - Porta 80
    ↓
Microsserviço na VM - Porta 5001 a 5009
    ↓
PostgreSQL central - Porta 5432
    ↓
Kafka/Redpanda - Porta 9092
    ↓
Outros microsserviços consumidores
```

---

## 3. O que roda na VM central

Absolutamente tudo roda na VM central:

**Infraestrutura:**
- roda no docker-compose.yml deste repositório.
- PostgreSQL
- PgAdmin
- Redpanda/Kafka
- Kafka UI
- Nginx API Gateway

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
| API Gateway | `http://34.29.84.207` | 80 | Entrada para APIs REST |
| PostgreSQL | `postgres` (container) / `34.29.84.207` (externo) | 5432 | Banco central |
| PgAdmin | `http://34.29.84.207:5050` | 5050 | Administração visual do banco |
| Kafka/Redpanda | `redpanda` (container) / `34.29.84.207` (externo) | 9092 | Broker de eventos |
| Kafka UI | `http://34.29.84.207:8080` | 8080 | Visualizar tópicos e mensagens |

**Atenção:**
- Se o seu microsserviço roda **em container na VM** (padrão obrigatório), aponte para `postgres` e `redpanda` — os nomes dos serviços na rede Docker.
- Se estiver acessando visualmente **de fora** da VM (ex: DBeaver no seu PC), use o `34.29.84.207`.

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

Todo microsserviço deve conter um arquivo `.env` para carregar as configurações dinamicamente. Como o padrão oficial é rodar em container, as conexões de banco e mensageria devem apontar para os nomes dos serviços na rede Docker.

Regras importantes:
- Dentro de container, **NÃO usar localhost** para PostgreSQL. O host correto é `postgres`.
- Dentro de container, **NÃO usar localhost** para Kafka. O host correto é `redpanda`.
- O `localhost` só resolve dentro do próprio container, não alcança os outros serviços da rede Docker.

### Padrão OBRIGATÓRIO (Microsserviço em Container)

```env
SERVICE_NAME=produtos-service
PORT=5002

DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

Esses nomes, postgres e redpanda, só funcionam porque o container do microsserviço está conectado à rede externa portal-b2b-network. Se a equipe esquecer essa rede no docker-compose.yml, a conexão com banco e Kafka vai falhar.

### Alternativa emergencial: rodar direto no host da VM (sem Docker)

Se por algum motivo emergencial o serviço precisar rodar diretamente no host da VM, sem Docker, as conexões mudam para `localhost` porque nesse caso o processo está no mesmo host que o PostgreSQL e o Redpanda:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@localhost:5432/portal_b2b
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
```

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

**Teste externo:**
```bash
curl http://34.29.84.207/api/produtos/health
```

O Gateway continua encaminhando pelo Nginx para a porta oficial publicada no host. O retorno esperado deve ser:
```json
{
  "status": "ok",
  "service": "produtos-service"
}
```

---

## 11. Como conectar ao PostgreSQL

O banco de dados do projeto é completamente centralizado.

- **Banco:** `portal_b2b`
- **Schema:** `portal_b2b`
- **Porta:** `5432`

Existem credenciais separadas por responsabilidade.

**Usuário dos microsserviços (Aplicação):**
- Usuário: `svc_portal_b2b`
- Senha: `senha_portal_b2b`

**Usuário da equipe de banco (DDL):**
- Usuário: `db_portal_b2b`
- Senha: `senha_db_portal_b2b`

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
- **Senha:** `admin`

Para cadastrar a conexão com o banco de dados **dentro do PgAdmin**:
- **Host:** `postgres` *(Usa-se "postgres" porque o PgAdmin roda no Docker na mesma rede)*
- **Port:** `5432`
- **Database:** `portal_b2b`
- **User:** `db_portal_b2b` (Se for equipe de banco)
- **Password:** `senha_db_portal_b2b`

---

## 14. Como acessar pelo DBeaver/DataGrip/psql

Se preferir usar sua ferramenta favorita instalada no seu PC:

- **Host:** `34.29.84.207`
- **Port:** `5432`
- **Database:** `portal_b2b`
- **User:** `db_portal_b2b` ou `svc_portal_b2b`
- **Password:** A senha correspondente ao usuário.

Exemplo de string de conexão para `psql`:
```bash
psql "postgresql://svc_portal_b2b:senha_portal_b2b@34.29.84.207:5432/portal_b2b"
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
| `connection refused` no PostgreSQL | usou `localhost` dentro do container | usar `postgres:5432` |
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
- **O banco possui backup via script.** O responsável pela infraestrutura pode gerar backups com `bash scripts/backup-postgres.sh` e restaurar com `bash scripts/restore-postgres.sh`.
  - **Aviso:** Os backups do banco são responsabilidade operacional da infraestrutura.
  - As equipes de microsserviços não devem executar restore do banco.
  - Restore deve ser feito apenas pela equipe de infraestrutura, preferencialmente na VM standby ou ambiente limpo.
- **Existe um plano de VM standby** para recuperação em caso de queda completa da VM principal. A VM standby pode ser ativada com a infraestrutura clonada e o último backup do banco.
- **Isso não substitui alta disponibilidade real**, mas atende ao plano acadêmico de recuperação com procedimentos documentados e testáveis.

Para o plano completo, consulte: [docs/redundancia-e-recuperacao.md](./docs/redundancia-e-recuperacao.md)

---

## 28. Front-ends dos microsserviços

Se o repositório da equipe tiver front-end, ele também deve ser dockerizado. A infraestrutura **não executará** `npm install` ou `npm run dev` manualmente como solução final. Para o padrão recomendado, consulte:

[docs/deploy-frontends-na-vm.md](./docs/deploy-frontends-na-vm.md)
