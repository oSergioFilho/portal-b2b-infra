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
| VM principal | `34.29.84.207` | Aplicação principal | ✅ Validada |
| VM standby | `34.59.229.37` | Aplicação redundante | ✅ Validada |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado | ✅ Validado |
| Portal principal | `http://34.8.17.245/` | Front principal (portal-front) via Load Balancer | ✅ Validado |
| Front produtos | `http://34.8.17.245/produtos/` | Front publicado via Gateway/Load Balancer | ✅ Validado |
| Front logística | `http://34.8.17.245/logistica/` | Front publicado via Gateway/Load Balancer | ✅ Validado |
| PgAdmin | `http://34.8.17.245/pgadmin/` | Ferramenta de apoio via Load Balancer | ✅ Implementado |
| Uptime Kuma | `http://34.59.229.37:3001` | Painel de status | ✅ Implementado |
| Status Page | `http://34.59.229.37:3001/status/portal-b2b-status` | Página pública de status | ✅ Implementado |

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
http://34.8.17.245/
http://34.8.17.245/produtos/
http://34.8.17.245/logistica/
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
| fornecimentos-service | ⏳ Aguardando deploy | http://34.8.17.245/api/fornecimentos/health |
| demanda-service | ✅ Integrado | http://34.8.17.245/api/demandas/health |
| mercado-service | ⏳ Aguardando deploy | http://34.8.17.245/api/mercado/health |
| negociacao-service | ⏳ Aguardando deploy | http://34.8.17.245/api/negociacoes/health |
| pedidos-service | ⏳ Aguardando deploy | http://34.8.17.245/api/pedidos/health |

> **Nota sobre Transportadoras:** Não existe mais o microsserviço `transportadoras-service` separado. A parte de transporte/transportadoras está integrada ao módulo de **Logística**.
> - Front logística: http://34.8.17.245/logistica/ (Porta: 8088)
> - API logística: http://34.8.17.245/api/logistica/ (Porta: 5008)

---

## 8. Front-ends integrados

| Front | Porta | Rota oficial | Status |
|---|---|---|---|
| Portal principal (portal-front / usuários) | 8082 | http://34.8.17.245/ | ✅ Validado |
| Front produtos | 8081 | http://34.8.17.245/produtos/ | ✅ Validado |
| Front logística | 8088 | http://34.8.17.245/logistica/ | ✅ Validado |

---

## 9. Serviços centrais
 
 Os seguintes serviços compõem a infraestrutura central:
 
- Cluster Redpanda (3 brokers distribuídos, portas 9092, 33145, 9644, 18081, 18082)
- Kafka UI
- Nginx Gateway
- PgAdmin
- Cloud SQL PostgreSQL (Banco oficial externo)

---

## 10. O que já foi implementado

- [x] VM principal funcionando
- [x] Cloud SQL PostgreSQL
- [x] VM standby criada
- [x] Load Balancer HTTP criado e validado
- [x] usuarios-service validado nas duas VMs
- [x] produtos-service validado nas duas VMs
- [x] logistica-service validado nas duas VMs
- [x] demanda-service validado nas duas VMs
- [x] Front principal (portal-front) validado na rota /
- [x] Front produtos validado na rota /produtos/
- [x] Front logística validado na rota /logistica/
- [x] Cloud SQL acessível pelas duas VMs
- [x] sync-redundant.sh validado
- [x] Deploy redundante documentado

## 11. Próximas etapas

- [x] Cluster Redpanda/Kafka (3 brokers replicados)
- [ ] Fazer teste de falha controlada quando for conveniente
- [ ] Definir rotina oficial de backup/exportação do Cloud SQL
- [ ] Avaliar HTTPS/domínio futuramente

---

## 12. Observabilidade

O painel visual de status da infraestrutura com Uptime Kuma está documentado em:

[docs/observabilidade-status.md](./observabilidade-status.md)
