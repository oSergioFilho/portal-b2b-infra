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
API Gateway Nginx
        ↓
Microsserviços / Fronts publicados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
```

---

## 2. Componentes

| Componente | Endereço | Função | Status |
|---|---|---|---|
| Load Balancer | `34.8.17.245` | Entrada principal do sistema | ✅ Validado |
| VM principal | `34.29.84.207` | Aplicação principal | ✅ Validada |
| VM standby | `34.59.229.37` | Aplicação redundante | ✅ Validada |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado | ✅ Validado |
| Front produtos | `http://34.8.17.245/produtos/` | Front publicado via Gateway/Load Balancer | A validar |
| Uptime Kuma | `http://34.59.229.37:3001` | Painel de status | ✅ Implementado |
| Status Page | `http://34.59.229.37:3001/status/portal-b2b-status` | Página pública de status | ✅ Implementado |

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
IP: 34.59.229.37
```

Mesma estrutura da VM principal. Roda os mesmos containers e microsserviços.

> **Observação:** O IP público da VM standby deve permanecer reservado como IP estático no GCP para evitar novas mudanças após reinicialização.

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
http://34.8.17.245/produtos/
```

O Load Balancer distribui requisições entre a VM principal e a VM standby com base no health check (`GET /health`).

> **Observação:** O acesso oficial do sistema (APIs e Front-end) é feito pelo Load Balancer. Os IPs diretos da VM principal (`34.29.84.207`) e da VM standby (`34.59.229.37`) devem ser usados apenas para diagnóstico.

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
- [x] Load Balancer HTTP criado e validado
- [x] produtos-service validado nas duas VMs
- [x] Cloud SQL acessível pelas duas VMs
- [x] sync-redundant.sh validado
- [x] Deploy redundante documentado

## 10. Próximas etapas

- [ ] Validar os próximos microsserviços nas duas VMs
- [ ] Fazer teste de falha controlada quando for conveniente
- [ ] Definir rotina oficial de backup/exportação do Cloud SQL
- [ ] Avaliar cluster Redpanda/Kafka futuramente
- [ ] Avaliar HTTPS/domínio futuramente

---

## 11. Observabilidade

O painel visual de status da infraestrutura com Uptime Kuma está documentado em:

[docs/observabilidade-status.md](./observabilidade-status.md)
