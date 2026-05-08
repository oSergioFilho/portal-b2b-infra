# Estado Atual da Infraestrutura

## 1. Visão geral

A infraestrutura atual do Portal B2B utiliza Load Balancer, duas VMs de aplicação e Cloud SQL PostgreSQL como banco oficial.

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal ou VM standby
        ↓
Microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
```

---

## 2. Componentes

| Componente | Endereço | Função |
|---|---|---|
| Load Balancer | `34.8.17.245` | Entrada principal do sistema |
| VM principal | `34.29.84.207` | Aplicação principal |
| VM standby | `104.197.23.241` | Aplicação redundante |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado |

---

## 3. VM principal

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

## 4. VM standby

```text
IP: 104.197.23.241
```

Mesma estrutura da VM principal. Roda os mesmos containers e microsserviços.

---

## 5. Cloud SQL

```text
IP: 136.114.235.212
```

| Item | Valor |
|---|---|
| Banco | `portal_b2b` |
| Schema | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

O Cloud SQL é o banco oficial. As duas VMs usam o mesmo banco. Os microsserviços devem usar:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

---

## 6. Load Balancer

```text
IP: 34.8.17.245
```

O acesso principal ao sistema é pelo Load Balancer:

```text
http://34.8.17.245/health
http://34.8.17.245/api/produtos/health
```

O Load Balancer distribui requisições entre a VM principal e a VM standby com base no health check (`GET /health`).

---

## 7. Microsserviços integrados

| Serviço | Status | Endpoint (via LB) |
|---|---|---|
| produtos-service | ✅ Integrado | http://34.8.17.245/api/produtos/health |
| usuarios-service | ⏳ Aguardando deploy | http://34.8.17.245/api/usuarios/health |
| fornecimentos-service | ⏳ Aguardando deploy | http://34.8.17.245/api/fornecimentos/health |
| demanda-service | ⏳ Aguardando deploy | http://34.8.17.245/api/demandas/health |
| mercado-service | ⏳ Aguardando deploy | http://34.8.17.245/api/mercado/health |
| negociacao-service | ⏳ Aguardando deploy | http://34.8.17.245/api/negociacoes/health |
| pedidos-service | ⏳ Aguardando deploy | http://34.8.17.245/api/pedidos/health |
| logistica-service | ⏳ Aguardando deploy | http://34.8.17.245/api/logistica/health |
| transportadoras-service | ⏳ Aguardando deploy | http://34.8.17.245/api/transportadoras/health |

---

## 8. Serviços ainda locais nas VMs

Os seguintes serviços continuam rodando localmente em cada VM via Docker Compose:

- Redpanda/Kafka
- Kafka UI
- Nginx Gateway
- PgAdmin
- PostgreSQL local (legado/opcional)

O PostgreSQL local permanece no `docker-compose.yml` por compatibilidade e testes locais, mas **não é mais o banco oficial da integração principal**.

---

## 9. O que já foi implementado

- [x] VM principal funcionando
- [x] Cloud SQL PostgreSQL
- [x] VM standby criada
- [x] Load Balancer HTTP criado
- [x] produtos-service validado nas duas VMs
- [x] Cloud SQL acessível pelas duas VMs

## 10. Próximas etapas

- [ ] Documentar teste de falha controlada
- [ ] Validar cada novo microsserviço nas duas VMs
- [ ] Definir rotina oficial de backup/exportação do Cloud SQL
- [ ] Avaliar cluster Redpanda/Kafka futuramente
