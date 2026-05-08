# Estado Atual da Infraestrutura

## 1. Visão geral

A infraestrutura atual do Portal B2B está dividida entre uma **VM de aplicação** no GCP e um **Cloud SQL PostgreSQL** como banco oficial.

```text
Usuário / Frontend
        ↓
API Gateway - VM 34.29.84.207
        ↓
Microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
        ↓
Kafka/Redpanda - VM 34.29.84.207
```

---

## 2. VM principal

```text
IP: 34.29.84.207
```

O que roda na VM:

- Nginx API Gateway (porta 80)
- Redpanda/Kafka (porta 9092)
- Kafka UI (porta 8080)
- PgAdmin (porta 5050)
- Microsserviços dockerizados (portas 5001 a 5009)
- Scripts de deploy e verificação
- Rede Docker `portal-b2b-network`
- PostgreSQL local (legado/opcional — porta 5432)

---

## 3. Cloud SQL

```text
IP: 136.114.235.212
```

| Item | Valor |
|---|---|
| Banco | `portal_b2b` |
| Schema | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

O Cloud SQL é o banco oficial. Os microsserviços devem usar:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

---

## 4. Microsserviços integrados

| Serviço | Status | Endpoint |
|---|---|---|
| produtos-service | ✅ Integrado | http://34.29.84.207/api/produtos/health |
| usuarios-service | ⏳ Aguardando deploy | http://34.29.84.207/api/usuarios/health |
| fornecimentos-service | ⏳ Aguardando deploy | http://34.29.84.207/api/fornecimentos/health |
| demanda-service | ⏳ Aguardando deploy | http://34.29.84.207/api/demandas/health |
| mercado-service | ⏳ Aguardando deploy | http://34.29.84.207/api/mercado/health |
| negociacao-service | ⏳ Aguardando deploy | http://34.29.84.207/api/negociacoes/health |
| pedidos-service | ⏳ Aguardando deploy | http://34.29.84.207/api/pedidos/health |
| logistica-service | ⏳ Aguardando deploy | http://34.29.84.207/api/logistica/health |
| transportadoras-service | ⏳ Aguardando deploy | http://34.29.84.207/api/transportadoras/health |

---

## 5. Serviços ainda locais na VM

Os seguintes serviços continuam rodando localmente na VM via Docker Compose:

- Redpanda/Kafka
- Kafka UI
- Nginx Gateway
- PgAdmin
- PostgreSQL local (legado/opcional)

O PostgreSQL local permanece no `docker-compose.yml` por compatibilidade e testes locais, mas **não é mais o banco oficial da integração principal**.

---

## 6. Próximas etapas

- [ ] Atualizar `.env` de cada novo microsserviço para Cloud SQL durante o deploy
- [ ] Validar cada microsserviço com endpoint real que consulte o Cloud SQL, não apenas `/health`
- [ ] Definir rotina oficial de backup/exportação do Cloud SQL
- [ ] Criar VM standby
- [ ] Autorizar IP da VM standby no Cloud SQL
- [ ] Replicar deploy dos microsserviços na VM standby
- [ ] Avaliar Load Balancer
- [ ] Documentar failover manual
