# Conexão das Equipes

## Ambiente atual

Acesso oficial de integração:
http://34.8.17.245

VM principal:
34.29.84.207 apenas diagnóstico

VM standby:
34.59.229.37 apenas diagnóstico

| Recurso | URL |
|---|---|
| API Gateway oficial | http://34.8.17.245 |
| Health oficial | http://34.8.17.245/health |
| produtos-service oficial | http://34.8.17.245/api/produtos/health |
| Front produtos oficial | http://34.8.17.245/produtos/ |
| Front demandas/pedidos (unificados) | http://34.8.17.245/demandas/ |
| Front logística oficial | http://34.8.17.245/logistica/ |
| PgAdmin (Redundante) | http://34.8.17.245/pgadmin/ |
| Kafka UI principal | http://34.29.84.207:8080 |
| Kafka UI standby | http://34.59.229.37:8080 |
| Uptime Kuma | http://34.59.229.37:3001 |
| Status Page | http://34.59.229.37:3001/status/portal-b2b-status |

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
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

**Regras importantes:**
- O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`.
- O barramento de eventos é um **Cluster Redpanda** de 3 brokers. Em integração/produção, use o bootstrap acima.
- O host `redpanda:9092` deve ser usado **apenas** para desenvolvimento local ou rollback temporário.
- O host `postgres` não existe mais na infraestrutura. O banco oficial é exclusivamente o Cloud SQL em 136.114.235.212.
- O container do microsserviço **precisa estar na rede `portal-b2b-network`** para integração com o API Gateway (Nginx) e demais serviços da infraestrutura. O acesso ao cluster Kafka é via rede interna da VPC (IPs `10.128.0.x`), não via resolução de nome Docker.

---

## Conexão externa para ferramentas

**PgAdmin (interface web):**
- URL: http://34.8.17.245/pgadmin/
- Login: `admin@portalb2b.com`
- Senha: `***`
- Host do banco oficial no PgAdmin: `136.114.235.212`

> O host `postgres` não existe mais na infraestrutura. O banco oficial é exclusivamente o Cloud SQL em `136.114.235.212`.

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
