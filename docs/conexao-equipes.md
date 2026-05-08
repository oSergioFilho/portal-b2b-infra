# Conexão das Equipes

## Ambiente atual

IP atual da VM de integração: **34.29.84.207**

| Recurso | URL |
|---|---|
| API Gateway | http://34.29.84.207 |
| Health do Gateway | http://34.29.84.207/health |
| PgAdmin | http://34.29.84.207:5050 |
| Kafka UI | http://34.29.84.207:8080 |

---

## Banco de dados

- **Banco:** `portal_b2b`
- **Schema:** `portal_b2b`

**Usuário da equipe de banco (DDL):**
```
db_portal_b2b
```

**Usuário dos microsserviços (DML):**
```
svc_portal_b2b
```

---

## Conexão padrão dos microsserviços em container

Todo microsserviço deve rodar em container na rede `portal-b2b-network`. As variáveis de ambiente obrigatórias são:

```env
DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

**Regras importantes:**
- O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`.
- Dentro do container, **não usar `localhost`** para Kafka. O host correto é `redpanda`.
- O host `postgres` (Docker Compose local) é **legado** e não deve mais ser usado como banco oficial.
- O container do microsserviço **precisa estar na rede `portal-b2b-network`** para que o nome `redpanda` funcione.

---

## Conexão externa para ferramentas

**PgAdmin (interface web):**
- URL: http://34.29.84.207:5050
- Login: `admin@portalb2b.com`
- Senha: `***`
- Host do banco dentro do PgAdmin: `postgres` (não usar o IP externo dentro do PgAdmin)

**Kafka UI:**
- URL: http://34.29.84.207:8080

**DBeaver / DataGrip / psql (ferramenta externa no seu PC):**
- Host: `136.114.235.212` (Cloud SQL — banco oficial)
- Porta: `5432`
- Banco: `portal_b2b`
- Usuário: `db_portal_b2b` (equipe de banco) ou `svc_portal_b2b` (microsserviços)

---

## Portas dos microsserviços

| Serviço | Porta | Gateway |
|---|---:|---|
| usuarios-service | 5001 | /api/usuarios/ |
| produtos-service | 5002 | /api/produtos/ |
| fornecimentos-service | 5003 | /api/fornecimentos/ |
| demanda-service | 5004 | /api/demandas/ |
| mercado-service | 5005 | /api/mercado/ |
| negociacao-service | 5006 | /api/negociacoes/ |
| pedidos-service | 5007 | /api/pedidos/ |
| logistica-service | 5008 | /api/logistica/ |
| transportadoras-service | 5009 | /api/transportadoras/ |

---

## Exemplo de docker-compose.yml do microsserviço

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

> Substitua `produtos-service` e `5002` pelo nome e porta oficial do seu microsserviço.
