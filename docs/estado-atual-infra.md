# Estado Atual da Infraestrutura

## 1. Visão geral

A infraestrutura atual do Portal B2B utiliza Load Balancer HTTP externo, duas VMs de aplicação e Cloud SQL PostgreSQL como banco oficial. As duas VMs rodam a mesma infraestrutura e os mesmos microsserviços/fronts. O failover HTTP entre VMs é automático pelo Load Balancer.

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal (34.29.84.207) ou VM standby (34.59.229.37) saudável
        ↓
Nginx Gateway
        ↓
Fronts e microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
+ Cluster Redpanda (3 brokers)
```

---

## 2. Componentes

| Componente | Endereço | Função | Status |
|---|---|---|---|
| Load Balancer | `34.8.17.245` | Entrada principal do sistema | ✅ Validado |
| VM principal (portal-b2b-vm) | `34.29.84.207` / `10.128.0.2` | Aplicação + Broker 0 | ✅ Validada |
| VM standby (portal-b2b-vm-standby) | `34.59.229.37` / `10.128.0.3` | Aplicação + Broker 1 | ✅ Validada |
| VM kafka-3 (portal-b2b-kafka-3) | `35.222.59.59` / `10.128.0.4` | Broker 2 (dedicado) | ✅ Validada |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado | ✅ Validado |
| Portal principal | `http://34.8.17.245/` | Front principal (portal-front) via Load Balancer | ✅ Validado |
| Front produtos | `http://34.8.17.245/produtos/` | Front publicado via Gateway/Load Balancer | ✅ Validado |
| Front logística | `http://34.8.17.245/logistica/` | Front publicado via Gateway/Load Balancer | ✅ Validado |
| Front fornecimentos | `http://34.8.17.245/fornecimentos/` | Front publicado via Gateway/Load Balancer | ✅ Integrado (redirect de /fornecimentos) |
| PgAdmin | `http://34.8.17.245/pgadmin/` | Ferramenta de apoio via Load Balancer | ✅ Implementado |
| Uptime Kuma | `http://34.59.229.37:3001` | Painel de status | ✅ Implementado |
| Status Page | `http://34.59.229.37:3001/status/portal-b2b-status` | Página pública de status | ✅ Implementado |

> **Nota:** O IP público `35.222.59.59` da VM kafka-3 é apenas para acesso administrativo/SSH. Não deve ser usado no `KAFKA_BOOTSTRAP_SERVERS`. Os microsserviços devem usar exclusivamente os IPs internos da VPC.

---

## 3. VM principal

```text
IP: 34.29.84.207
```

O que roda na VM:

- Nginx API Gateway (porta 80)
- Broker do Cluster Redpanda/Kafka
- Kafka UI (porta 8080)
- PgAdmin (acesso via `/pgadmin/` no Load Balancer)
- Microsserviços dockerizados (portas 5001 a 5008)
- Front-ends dockerizados (portas 8081, 8082, 8088 etc.)
- Scripts de deploy e verificação
- Rede Docker `portal-b2b-network`

---

## 4. VM standby

```text
IP: 34.59.229.37
```

Mesma estrutura da VM principal. Roda os mesmos containers, microsserviços e fronts. As duas VMs ficam atrás do Load Balancer, que distribui o tráfego entre elas com base no health check.

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
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

> **Nota:** O endereço `redpanda:9092` deve ser usado apenas para desenvolvimento local.

---

## 6. Load Balancer

```text
IP: 34.8.17.245
```

O acesso principal ao sistema é pelo Load Balancer. O Load Balancer usa `GET /health` para verificar a saúde de cada VM e roteia o tráfego somente para VMs saudáveis.

Endpoints principais:

```text
http://34.8.17.245/health
http://34.8.17.245/api/usuarios/health
http://34.8.17.245/api/produtos/health
http://34.8.17.245/api/logistica/health
http://34.8.17.245/api/fornecimentos/health
http://34.8.17.245/
http://34.8.17.245/produtos/
http://34.8.17.245/logistica/
http://34.8.17.245/fornecimentos/
http://34.8.17.245/fornecimentos
http://34.8.17.245/pgadmin/
```

> **Observação:** O acesso oficial do sistema (APIs e front-ends) é feito pelo Load Balancer. Os IPs diretos da VM principal (`34.29.84.207`) e da VM standby (`34.59.229.37`) devem ser usados apenas para diagnóstico.

---

## 7. Microsserviços integrados

| Serviço | Status | Endpoint (via LB) |
|---|---|---|
| usuarios-service | ✅ Integrado | http://34.8.17.245/api/usuarios/health |
| produtos-service | ✅ Integrado | http://34.8.17.245/api/produtos/health |
| logistica-service | ✅ Integrado | http://34.8.17.245/api/logistica/health |
| fornecimentos-service | ✅ Integrado | http://34.8.17.245/api/fornecimentos/health |
| demanda-service | ✅ Integrado | http://34.8.17.245/api/demandas/health |
| mercado-service | ⏳ Aguardando deploy | http://34.8.17.245/api/mercado/health |
| negociacao-service | ⏳ Aguardando deploy | http://34.8.17.245/api/negociacoes/health |
| pedidos-service | ✅ Integrado | http://34.8.17.245/api/pedidos/health |

> **Nota sobre Transportadoras:** Não existe mais o microsserviço `transportadoras-service` separado. A parte de transporte/transportadoras está integrada ao módulo de **Logística**.
> - Front logística: http://34.8.17.245/logistica/ (Porta: 8088)
> - API logística: http://34.8.17.245/api/logistica/ (Porta: 5008)

> **Nota sobre Demandas e Pedidos:** O front-end de **Demandas** e **Pedidos** foi unificado em uma única interface (servida pelo `demandas-front`). O microsserviço `pedidos-service` foi implementado e integrado no back-end. Não há um front-end standalone para Pedidos.
> - Front unificado (Demandas/Pedidos): http://34.8.17.245/demandas/ (Porta: 8084)
> - API demandas: http://34.8.17.245/api/demandas/ (Porta: 5004)
> - API pedidos: http://34.8.17.245/api/pedidos/ (Porta: 5007)

---

## 8. Front-ends integrados

| Front | Porta | Rota oficial | Status |
|---|---|---|---|
| Portal principal (portal-front / usuários) | 8082 | http://34.8.17.245/ | ✅ Validado |
| Front produtos | 8081 | http://34.8.17.245/produtos/ | ✅ Validado |
| Front demandas/pedidos (unificados) | 8084 | http://34.8.17.245/demandas/ | ✅ Validado |
| Front logística | 8088 | http://34.8.17.245/logistica/ | ✅ Validado |
| fornecimentos-front | 8083 | http://34.8.17.245/fornecimentos/ | ✅ Integrado |

---

## 9. Cluster Redpanda/Kafka

O barramento de eventos opera como **cluster Redpanda com 3 brokers replicados**:

| Broker | VM | IP interno | Porta Kafka |
|---|---|---|---|
| Broker 0 | portal-b2b-vm | 10.128.0.2 | 9092 |
| Broker 1 | portal-b2b-vm-standby | 10.128.0.3 | 9092 |
| Broker 2 | portal-b2b-kafka-3 | 10.128.0.4 | 9092 |

**Portas do cluster:**
- Kafka API: 9092
- RPC (inter-broker): 33145
- Admin API: 9644
- Schema Registry: 18081
- Pandaproxy: 18082
- **8081 e 8082 são front-ends, não Redpanda.**

**Bootstrap oficial:**
```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

O cluster usa **replication factor 3** e tolera a queda de **1 broker** mantendo a operação.

---

## 10. Serviços centrais

Os seguintes serviços compõem a infraestrutura central:

- Cluster Redpanda (3 brokers: 10.128.0.2, 10.128.0.3, 10.128.0.4)
- Kafka UI
- Nginx Gateway
- PgAdmin
- Cloud SQL PostgreSQL (Banco oficial externo)

---

## 11. O que já foi implementado

- [x] VM principal funcionando
- [x] Cloud SQL PostgreSQL
- [x] VM standby criada
- [x] Load Balancer HTTP criado e validado
- [x] Cluster Redpanda/Kafka com 3 brokers replicados
- [x] usuarios-service validado nas duas VMs
- [x] produtos-service validado nas duas VMs
- [x] logistica-service validado nas duas VMs
- [x] demanda-service validado nas duas VMs
- [x] pedidos-service validado nas duas VMs
- [x] fornecimentos-service validado nas duas VMs
- [x] Front principal (portal-front) validado na rota /
- [x] Front produtos validado na rota /produtos/
- [x] Front demandas/pedidos (unificados) validado na rota /demandas/
- [x] Front logística validado na rota /logistica/
- [x] Front fornecimentos (fornecimentos-front) validado na rota /fornecimentos/
- [x] Cloud SQL acessível pelas duas VMs
- [x] sync-redundant.sh validado
- [x] Deploy redundante documentado

## 12. Próximas etapas

- [ ] Fazer teste de falha controlada quando for conveniente
- [ ] Definir rotina oficial de backup/exportação do Cloud SQL
- [ ] Avaliar HTTPS/domínio futuramente

---

## 13. Observabilidade

O painel visual de status da infraestrutura com Uptime Kuma está documentado em:

[docs/observabilidade-status.md](./observabilidade-status.md)
