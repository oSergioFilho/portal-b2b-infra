# Roteiro de Testes da Infraestrutura Atual

## 1. Objetivo

Este documento centraliza os testes operacionais para validar a infraestrutura atual do Portal B2B.

A arquitetura atual usa:

- VM principal: `34.29.84.207`
- Cloud SQL PostgreSQL oficial: `136.114.235.212`
- Redpanda/Kafka na VM
- API Gateway na VM
- Microsserviços dockerizados na VM
- PostgreSQL local apenas como legado/fallback

---

## 2. Verificar containers da infraestrutura

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
docker compose ps
```

Serviços esperados:

- `portal-b2b-nginx-gateway`
- `portal-b2b-redpanda`
- `portal-b2b-kafka-ui`
- `portal-b2b-pgadmin`
- `portal-b2b-postgres`

> **Observação:** `portal-b2b-postgres` é legado/fallback. O banco oficial é Cloud SQL.

---

## 3. Rodar check da infraestrutura

```bash
bash scripts/check-infra.sh
```

> **Observação:** Esse script valida Gateway, Kafka/Redpanda, Kafka UI, PgAdmin e também o PostgreSQL local legado. O banco oficial Cloud SQL deve ser testado separadamente (seções 5 e 6).

---

## 4. Testar API Gateway

```bash
curl http://34.29.84.207/health
```

Resposta esperada:

```text
API Gateway do Portal B2B ativo
```

---

## 5. Testar Cloud SQL com usuário dos microsserviços

```bash
export CLOUDSQL_IP="136.114.235.212"
export SVC_PASSWORD="senha_portal_b2b"

PGPASSWORD="$SVC_PASSWORD" psql \
  -h "$CLOUDSQL_IP" \
  -U svc_portal_b2b \
  -d portal_b2b \
  -c "SELECT * FROM portal_b2b.health_check;"
```

Resultado esperado:

A tabela `portal_b2b.health_check` deve retornar registros.

---

## 6. Testar Cloud SQL com usuário da equipe de banco

```bash
export CLOUDSQL_IP="136.114.235.212"
export DB_PASSWORD="senha_db_portal_b2b"

PGPASSWORD="$DB_PASSWORD" psql \
  -h "$CLOUDSQL_IP" \
  -U db_portal_b2b \
  -d portal_b2b \
  -c "\dn"
```

Resultado esperado:

O schema `portal_b2b` deve aparecer.

---

## 7. Testar PgAdmin

Abrir:

```text
http://34.29.84.207:5050
```

A conexão cadastrada no PgAdmin deve apontar para:

```text
136.114.235.212:5432
```

e não para o PostgreSQL local, exceto em testes legados.

---

## 8. Testar Kafka UI

Abrir:

```text
http://34.29.84.207:8080
```

Conferir se os tópicos aparecem.

---

## 9. Testar publicação Kafka

```bash
echo '{"eventId":"teste-002","eventType":"produto_cadastrado","eventVersion":"1.0","timestamp":"2026-05-05T00:00:00Z","source":"infra-test","correlationId":"teste-002","payload":{"produtoId":1,"nome":"Produto de Teste"}}' | docker compose exec -T redpanda rpk topic produce produto_cadastrado --brokers redpanda:9092
```

Depois conferir a mensagem no Kafka UI:

```text
http://34.29.84.207:8080
```

---

## 10. Testar produtos-service

```bash
curl http://34.29.84.207/api/produtos/health
```

Resposta esperada:

```json
{"status":"ok","service":"produtos-service"}
```

---

## 11. Testar todos os microsserviços

```bash
bash scripts/check-services.sh
```

Resultado esperado atual:

- `produtos-service` deve responder OK.
- Os demais serviços podem retornar HTTP 502 enquanto ainda não forem deployados.

---

## 12. Testes legados do PostgreSQL local

Esses testes só são necessários se a equipe quiser validar o PostgreSQL local/fallback.

```bash
docker compose exec -T postgres pg_isready -U postgres
```

```bash
docker compose exec -T postgres psql -U postgres -d portal_b2b -c "SELECT * FROM portal_b2b.health_check;"
```

> **Observação:** O PostgreSQL local não é mais o banco oficial.

---

## 13. Resultado esperado geral

A infraestrutura atual está validada quando:

- [ ] Gateway responde `/health`.
- [ ] Cloud SQL responde com `svc_portal_b2b`.
- [ ] Cloud SQL responde com `db_portal_b2b`.
- [ ] Kafka UI abre.
- [ ] Kafka recebe mensagem de teste.
- [ ] PgAdmin abre.
- [ ] `produtos-service` responde pelo Gateway.
- [ ] `check-infra.sh` conclui sem erro crítico.
- [ ] `check-services.sh` mostra OK para os serviços já deployados.
