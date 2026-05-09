# Roteiro de Testes da Infraestrutura Atual

## 1. Objetivo

Este documento centraliza os testes operacionais para validar a infraestrutura atual do Portal B2B.

A arquitetura atual usa:

- Load Balancer: `34.8.17.245`
- VM principal: `34.29.84.207`
- VM standby: `34.59.229.37`
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

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/health
```

**Teste direto na VM principal, diagnóstico:**
```bash
curl http://34.29.84.207/health
```

**Teste direto na VM standby, diagnóstico:**
```bash
curl http://34.59.229.37/health
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
http://34.8.17.245/pgadmin/
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

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/api/produtos/health
```

**Teste direto na VM principal, diagnóstico:**
```bash
curl http://34.29.84.207/api/produtos/health
```

**Teste direto na VM standby, diagnóstico:**
```bash
curl http://34.59.229.37/api/produtos/health
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

## 12. Testar Load Balancer

```bash
curl http://34.8.17.245/health
```

Resposta esperada:

```text
API Gateway do Portal B2B ativo
```

```bash
curl http://34.8.17.245/api/produtos/health
```

Resposta esperada:

```json
{"status":"ok","service":"produtos-service"}
```

---

## 13. Testar Front-end pelo Load Balancer

**Teste oficial do front produtos pelo Load Balancer:**
```bash
curl -I http://34.8.17.245/produtos/
```

**Teste direto na VM principal, somente diagnóstico:**
```bash
curl -I http://34.29.84.207:8081
```

**Teste direto na VM standby, somente diagnóstico:**
```bash
curl -I http://34.59.229.37:8081
```

**Resultado esperado:**
- Pelo Load Balancer, o front deve responder.
- Se a VM principal cair, o acesso direto a `34.29.84.207:8081` falha, mas o acesso pelo Load Balancer deve continuar funcionando se a standby estiver saudável.

> **Observação:** Se esse teste falhar, verificar se o produtos-front está rodando nas duas VMs e se a aplicação front-end suporta o subpath `/produtos/`.

---

## 14. Testar backends do Load Balancer

No Cloud Shell do GCP:

```bash
gcloud compute backend-services get-health portal-b2b-backend-service --global
```

Resultado esperado:

```text
portal-b2b-vm         HEALTHY
portal-b2b-vm-standby HEALTHY
```

---

## 15. Testar VM standby diretamente

```bash
curl http://34.59.229.37/health
curl http://34.59.229.37/api/produtos/health
```

Resultado esperado: mesmas respostas que a VM principal.

---

## 16. Testes legados do PostgreSQL local

Esses testes só são necessários se a equipe quiser validar o PostgreSQL local/fallback.

```bash
docker compose exec -T postgres pg_isready -U postgres
```

```bash
docker compose exec -T postgres psql -U postgres -d portal_b2b -c "SELECT * FROM portal_b2b.health_check;"
```

> **Observação:** O PostgreSQL local não é mais o banco oficial.

---

## 17. Resultado esperado geral

A infraestrutura atual está validada quando:

- [ ] Gateway responde `/health` na VM principal.
- [ ] Gateway responde `/health` na VM standby.
- [ ] Load Balancer responde `/health`.
- [ ] Cloud SQL responde com `svc_portal_b2b`.
- [ ] Cloud SQL responde com `db_portal_b2b`.
- [ ] Kafka UI abre.
- [ ] Kafka recebe mensagem de teste.
- [ ] PgAdmin abre via Load Balancer em `/pgadmin/`.
- [ ] `produtos-service` responde pelo Load Balancer.
- [ ] Front produtos responde pelo Load Balancer em `/produtos/`.
- [ ] Backends do Load Balancer estão HEALTHY.
- [ ] `check-infra.sh` conclui sem erro crítico.
- [ ] `check-services.sh` mostra OK para os serviços já deployados.

---

## 18. Testar sincronização redundante

Na VM principal:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/sync-redundant.sh
```

Resultado esperado:

- A VM principal faz pull e sobe a infraestrutura.
- A VM standby faz pull e sobe a infraestrutura.
- O `check-infra.sh` passa nas duas VMs.
- O Load Balancer continua respondendo.

---

## 19. Testar Load Balancer após sincronização

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/produtos/health
```

Resultado esperado:

```text
API Gateway do Portal B2B ativo
{"status":"ok","service":"produtos-service"}
```
