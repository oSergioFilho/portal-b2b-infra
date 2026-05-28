# Roteiro de Testes da Infraestrutura Atual

## 1. Objetivo

Este documento centraliza os testes operacionais para validar a infraestrutura atual do Portal B2B.

A arquitetura atual usa:

- Load Balancer: `34.8.17.245` (ponto oficial de entrada)
- VM principal: `34.29.84.207` (diagnóstico direto)
- VM standby: `34.59.229.37` (diagnóstico direto)
- Cloud SQL PostgreSQL oficial: `136.114.235.212`
- Cluster Redpanda/Kafka com 3 brokers (VM principal, VM standby, VM kafka-3)
- API Gateway Nginx nas duas VMs de aplicação
- Microsserviços dockerizados nas duas VMs de aplicação

---

## 2. Verificar containers da infraestrutura

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
docker compose ps
```

Serviços esperados:

- `portal-b2b-nginx-gateway`
- `portal-b2b-kafka-ui`
- `portal-b2b-pgadmin`

> **Observação:** O PostgreSQL local foi removido. O banco oficial é Cloud SQL. O Redpanda local foi movido para o profile `local-kafka` e não sobe por padrão. O Kafka/Redpanda agora opera como cluster externo com 3 brokers.

---

## 3. Rodar check da infraestrutura

```bash
bash scripts/check-infra.sh
```

> **Observação:** Esse script valida Gateway, Kafka UI, PgAdmin e o Cloud SQL PostgreSQL oficial. Para o cluster Kafka/Redpanda, use `KAFKA_BOOTSTRAP_SERVERS=... bash scripts/check-infra.sh` ou execute `scripts/check-kafka-cluster.sh` diretamente.

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

O PostgreSQL local foi removido.

---

## 8. Testar Kafka UI

Abrir:

```text
http://34.29.84.207:8080
```

Conferir se os tópicos aparecem.

---

## 9. Testar publicação Kafka

> **Nota:** O teste abaixo usa o cluster Redpanda. Defina `KAFKA_BOOTSTRAP_SERVERS` com os IPs internos das VMs.

```bash
export KAFKA_BOOTSTRAP_SERVERS=IP_INTERNO_VM1:9092,IP_INTERNO_VM2:9092,IP_INTERNO_VM3:9092

echo '{"eventId":"teste-002","eventType":"produto_cadastrado","eventVersion":"1.0","timestamp":"2026-05-05T00:00:00Z","source":"infra-test","correlationId":"teste-002","payload":{"produtoId":1,"nome":"Produto de Teste"}}' | rpk topic produce produto_cadastrado --brokers "$KAFKA_BOOTSTRAP_SERVERS"
```

Se `rpk` não estiver instalado na VM, use via Docker:

```bash
echo '{"eventId":"teste-002","eventType":"produto_cadastrado","eventVersion":"1.0","timestamp":"2026-05-05T00:00:00Z","source":"infra-test","correlationId":"teste-002","payload":{"produtoId":1,"nome":"Produto de Teste"}}' | docker run --rm -i --network host docker.redpanda.com/redpandadata/redpanda:latest rpk topic produce produto_cadastrado --brokers "$KAFKA_BOOTSTRAP_SERVERS"
```

Depois conferir a mensagem no Kafka UI:

```text
http://34.29.84.207:8080
```

---

## 10. Testar microsserviços integrados

### usuarios-service

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/api/usuarios/health
```

**Teste direto na VM principal, diagnóstico:**
```bash
curl http://34.29.84.207/api/usuarios/health
```

**Teste direto na VM standby, diagnóstico:**
```bash
curl http://34.59.229.37/api/usuarios/health
```

Resposta esperada:

```json
{"status":"ok","service":"usuarios-service"}
```

---

### produtos-service

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

### logistica-service

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/api/logistica/health
```

**Teste direto na VM principal, diagnóstico:**
```bash
curl http://34.29.84.207/api/logistica/health
```

**Teste direto na VM standby, diagnóstico:**
```bash
curl http://34.59.229.37/api/logistica/health
```

Resposta esperada:

```json
{"status":"ok","service":"logistica-service"}
```

---

### fornecimentos-service

**Teste oficial pelo Load Balancer:**
```bash
curl http://34.8.17.245/api/fornecimentos/health
curl http://34.8.17.245/api/fornecimentos/health/db
```

**Teste direto na VM principal, diagnóstico:**
```bash
curl http://34.29.84.207/api/fornecimentos/health
curl http://34.29.84.207/api/fornecimentos/health/db
```

**Teste direto na VM standby, diagnóstico:**
```bash
curl http://34.59.229.37/api/fornecimentos/health
curl http://34.59.229.37/api/fornecimentos/health/db
```

Resposta esperada:

```json
{"status":"ok","service":"fornecimentos-service"}
```

---

## 11. Testar todos os microsserviços

```bash
bash scripts/check-services.sh
```

**Serviços esperados como OK atualmente:**

- `usuarios-service` — integrado ✅
- `produtos-service` — integrado ✅
- `logistica-service` — integrado ✅
- `fornecimentos-service` — integrado ✅
- `mercado-service` (via vendas-service) — integrado ✅
- `negociacao-service` (via vendas-service) — integrado ✅

> **Observação:** Os demais serviços ainda aguardam deploy e podem retornar HTTP 502.

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
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl http://34.8.17.245/api/mercado/health
curl http://34.8.17.245/api/negociacoes/health
curl http://34.8.17.245/api/fornecimentos/health
curl http://34.8.17.245/api/fornecimentos/health/db
```

Resposta esperada para cada:

```json
{"status":"ok","service":"nome-do-service"}
```

---

## 13. Testar Front-ends pelo Load Balancer

**Teste oficial dos front-ends pelo Load Balancer:**
```bash
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
curl -I http://34.8.17.245/mercado/
curl -I http://34.8.17.245/negociacao/
curl -IL --max-redirs 10 http://34.8.17.245/fornecimentos/
curl -I http://34.8.17.245/pgadmin/
```

**Teste direto na VM principal, somente diagnóstico:**
```bash
curl -I http://34.29.84.207:8082   # portal-front
curl -I http://34.29.84.207:8081   # produtos-front
curl -I http://34.29.84.207:8088   # logistica-front
curl -I http://34.29.84.207:8085   # mercado-web
curl -I http://34.29.84.207:8086   # negociacao-web
curl -I http://34.29.84.207:8083   # fornecimentos-front
```

**Teste direto na VM standby, somente diagnóstico:**
```bash
curl -I http://34.59.229.37:8082   # portal-front
curl -I http://34.59.229.37:8081   # produtos-front
curl -I http://34.59.229.37:8088   # logistica-front
curl -I http://34.59.229.37:8085   # mercado-web
curl -I http://34.59.229.37:8086   # negociacao-web
curl -I http://34.59.229.37:8083   # fornecimentos-front
```

**Resultado esperado:**
- Todos os fronts devem responder HTTP 200 pelo Load Balancer.
- Portal principal (/) → portal-front (porta 8082).
- Front produtos (/produtos/) → produtos-front (porta 8081).
- Front logística (/logistica/) → logistica-front (porta 8088).
- Front mercado (/mercado/) → mercado-web (porta 8085).
- Front negociação (/negociacao/) → negociacao-web (porta 8086).
- Front fornecimentos (/fornecimentos/) → fornecimentos-front (porta 8083).

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
curl http://34.59.229.37/api/usuarios/health
curl http://34.59.229.37/api/produtos/health
curl http://34.59.229.37/api/logistica/health
curl http://34.59.229.37/api/fornecimentos/health
curl http://34.59.229.37/api/fornecimentos/health/db
```

Resultado esperado: mesmas respostas que a VM principal.

---

## 16. Resultado esperado geral

A infraestrutura atual está validada quando:

- [ ] Gateway responde `/health` na VM principal.
- [ ] Gateway responde `/health` na VM standby.
- [ ] Load Balancer responde `/health`.
- [ ] Cloud SQL responde com `svc_portal_b2b`.
- [ ] Cloud SQL responde com `db_portal_b2b`.
- [ ] Kafka UI abre.
- [ ] Cluster Redpanda saudável (`check-kafka-cluster.sh`).
- [ ] Kafka recebe mensagem de teste.
- [ ] PgAdmin abre via Load Balancer em `/pgadmin/`.
- [ ] `usuarios-service` responde pelo Load Balancer.
- [ ] `produtos-service` responde pelo Load Balancer.
- [ ] `logistica-service` responde pelo Load Balancer.
- [ ] `mercado-service` responde pelo Load Balancer.
- [ ] `negociacao-service` responde pelo Load Balancer.
- [ ] `fornecimentos-service` responde pelo Load Balancer.
- [ ] Portal principal responde pelo Load Balancer em `/`.
- [ ] Front produtos responde pelo Load Balancer em `/produtos/`.
- [ ] Front logística responde pelo Load Balancer em `/logistica/`.
- [ ] Front mercado responde pelo Load Balancer em `/mercado/`.
- [ ] Front negociação responde pelo Load Balancer em `/negociacao/`.
- [ ] Front fornecimentos responde pelo Load Balancer em `/fornecimentos/`.
- [ ] Backends do Load Balancer estão HEALTHY.
- [ ] `check-infra.sh` conclui sem erro crítico.
- [ ] `check-services.sh` mostra OK para os serviços já deployados.

---

## 17. Testar sincronização redundante

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

## 18. Testar Load Balancer após sincronização

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl http://34.8.17.245/api/mercado/health
curl http://34.8.17.245/api/negociacoes/health
curl http://34.8.17.245/api/fornecimentos/health
curl http://34.8.17.245/api/fornecimentos/health/db
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
curl -I http://34.8.17.245/mercado/
curl -I http://34.8.17.245/negociacao/
curl -IL --max-redirs 10 http://34.8.17.245/fornecimentos/
```

Resultado esperado:

```text
API Gateway do Portal B2B ativo
{"status":"ok","service":"usuarios-service"}
{"status":"ok","service":"produtos-service"}
{"status":"ok","service":"logistica-service"}
{"status":"ok","service":"mercado-service"}
{"status":"ok","service":"negociacao-service"}
{"status":"ok","service":"fornecimentos-service"}
HTTP 200 (front principal)
HTTP 200 (front produtos)
HTTP 200 (front logística)
HTTP 200 (front mercado)
HTTP 200 (front negociação)
HTTP 200 (front fornecimentos)
```
