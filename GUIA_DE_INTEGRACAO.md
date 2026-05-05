# Guia Oficial de Integração

## 1. Objetivo do guia

Este documento é o **guia oficial** para as equipes conectarem seus microsserviços à infraestrutura central do Portal B2B. Ele foi projetado para que você consiga conectar, rodar e testar seu serviço sem precisar perguntar ao responsável pela infraestrutura.

A divisão de responsabilidades é muito clara:
- A **equipe de infraestrutura** entrega a VM central, Banco de Dados, Kafka, Gateway, PgAdmin e Kafka UI já configurados e rodando.
- A **equipe de banco de dados** cria as tabelas e o modelo relacional centralizado.
- As **equipes de microsserviços** (você) implementam as APIs, as regras de negócio e a publicação/consumo de eventos.

## Regra principal de integração

Cada equipe é responsável por entregar o próprio microsserviço dockerizado. A equipe de infraestrutura mantém PostgreSQL, Kafka/Redpanda, Kafka UI, PgAdmin, API Gateway e a rede Docker compartilhada. A infraestrutura não instalará dependências manualmente de cada projeto.

---

## 2. Visão geral da arquitetura

A arquitetura do Portal B2B exige que **todos os serviços e ferramentas rodem na mesma VM central**.

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
- PostgreSQL
- PgAdmin
- Redpanda/Kafka
- Kafka UI
- Nginx API Gateway

**Microsserviços das equipes:**
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
| API Gateway | `http://IP_DA_VM` | 80 | Entrada para APIs REST |
| PostgreSQL | `IP_DA_VM` (ou `localhost` na VM) | 5432 | Banco central |
| PgAdmin | `http://IP_DA_VM:5050` | 5050 | Administração visual do banco |
| Kafka/Redpanda | `IP_DA_VM` (ou `localhost` na VM) | 9092 | Broker de eventos |
| Kafka UI | `http://IP_DA_VM:8080` | 8080 | Visualizar tópicos e mensagens |

**Atenção:** 
- Se você está rodando seu código **dentro** da VM, aponte as credenciais do `.env` para `localhost`. 
- Se estiver rodando o código ou acessando visualmente **de fora** da VM, use o `IP_DA_VM`.

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

**Padrão OBRIGATÓRIO (Microsserviço em Container):**
```env
SERVICE_NAME=produtos-service
PORT=5002

DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

*(Nota: Se precisar testar rodando localmente no seu PC sem Docker, troque `postgres` e `redpanda` pelo IP da VM).*

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

## 10. Como testar o /health pelo Gateway

Uma vez que seu serviço está rodando, teste se o Gateway o reconhece.

Se você está na VM, rode no terminal:
```bash
curl http://localhost/api/produtos/health
curl http://localhost/api/demandas/health
curl http://localhost/api/pedidos/health
```

Se estiver testando de fora da VM (no seu computador local):
```bash
curl http://IP_DA_VM/api/produtos/health
```

O retorno esperado deve ser um JSON padrão de saúde. Exemplo:
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

- **URL:** `http://IP_DA_VM:5050`
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

- **Host:** `IP_DA_VM`
- **Port:** `5432`
- **Database:** `portal_b2b`
- **User:** `db_portal_b2b` ou `svc_portal_b2b`
- **Password:** A senha correspondente ao usuário.

Exemplo de string de conexão para `psql`:
```bash
psql "postgresql://svc_portal_b2b:senha_portal_b2b@IP_DA_VM:5432/portal_b2b"
```

---

## 15. Como conectar ao Kafka/Redpanda

A mensageria utiliza Redpanda (100% compatível com a API do Apache Kafka).

**Para aplicações rodando na VM:**
`KAFKA_BOOTSTRAP_SERVERS=localhost:9092`

**Para aplicações rodando de fora da VM:**
`KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092`

Para monitorar tópicos e mensagens em tempo real, utilize a interface do **Kafka UI**:
- URL: `http://IP_DA_VM:8080`

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

- [ ] repositório do microsserviço;
- [ ] comando de instalação (ex: `npm install`);
- [ ] comando para rodar (ex: `npm start`);
- [ ] porta oficial configurada para rodar e escutar em `0.0.0.0`;
- [ ] arquivo `.env.example`;
- [ ] endpoint `GET /health`;
- [ ] Swagger/OpenAPI funcionando (ex: `/docs` ou `/api-docs`);
- [ ] lista de endpoints REST mapeados;
- [ ] eventos Kafka que publica programados;
- [ ] eventos Kafka que consome programados;
- [ ] tabelas que usa acordadas com equipe de DB;
- [ ] Dockerfile se tiver (opcional, mas recomendado).

---

## 21. Erros comuns e como resolver

| Erro | Causa provável | Como resolver |
|---|---|---|
| `Connection refused` no banco | PostgreSQL não está acessível ou host errado. | Verificar se usou `IP_DA_VM`, porta `5432` e se a infra está de pé. |
| `permission denied for schema` | Usando usuário errado ou tentando criar tabela com `svc_portal_b2b`. | Usar `db_portal_b2b` para DDL ou pedir à equipe de banco. |
| Gateway retorna `502` | Microsserviço não está rodando ou está na porta errada. | Subir serviço na porta oficial com `0.0.0.0`. |
| Kafka não conecta | Bootstrap server errado. | Usar `localhost:9092` na VM ou `IP_DA_VM:9092` fora da VM. |
| Swagger não abre pelo Gateway | Rota interna incompatível. | Lembrar que o Gateway remove `/api/{dominio}/` da rota. |
| Serviço funciona local, mas Gateway não vê | O serviço está escutando em `127.0.0.1`. | Rodar o servidor web com binding para `0.0.0.0`. |
| ORM tentou criar tabela na inicialização | `auto-migrate`/`sync` ativado no código. | Desativar DDL automático na aplicação; isso é dever do DB Admin. |
| Porta já em uso ao iniciar | Outro serviço travou segurando a porta. | Verificar com `lsof -i :PORT` (Linux) ou `docker ps` e matar o processo. |

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
