# Arquitetura Redundante no GCP

## 1. Objetivo

Este documento descreve a arquitetura redundante atual do Portal B2B, com duas VMs de aplicação atrás de um Load Balancer HTTP externo e banco PostgreSQL compartilhado via Cloud SQL.

O objetivo é eliminar o ponto único de falha, permitindo que o sistema continue disponível mesmo em caso de queda de uma das VMs.

---

## 2. Arquitetura implementada — situação atual

A infraestrutura possui **duas VMs de aplicação atrás de um Load Balancer HTTP externo**. As duas VMs rodam a mesma infraestrutura, os mesmos microsserviços e os mesmos front-ends. O banco é externo, no Cloud SQL PostgreSQL.

Cada VM roda:
- API Gateway (Nginx)
- Microsserviços das equipes
- Front-ends dockerizados
- Kafka/Redpanda (local por VM)
- PgAdmin
- Kafka UI

O banco de dados oficial é o **Cloud SQL PostgreSQL** (`136.114.235.212`), compartilhado entre as duas VMs.

Se uma VM cair, o Load Balancer redireciona automaticamente o tráfego para a VM saudável.

---

## 3. Fluxo da arquitetura

```text
Usuários / Frontend
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
+ Redpanda/Kafka local da VM
```

Pontos importantes:
- **O Load Balancer é o ponto oficial de entrada.** Acesso sempre pelo IP `34.8.17.245`.
- **As duas VMs rodam a mesma infraestrutura.** A VM standby não é passiva; ela roda os mesmos containers e microsserviços que a VM principal.
- **O failover HTTP é automático** pelo Load Balancer, baseado no health check `GET /health`.
- **Acesso direto às VMs** (`34.29.84.207`, `34.59.229.37`) é apenas para diagnóstico.

As duas VMs terão a mesma estrutura de diretórios:

```text
/opt/portal-b2b/
├── infra/
│   └── portal-b2b-infra/
└── services/
    ├── usuarios-service/
    ├── produtos-service/
    ├── fornecimentos-service/
    ├── demanda-service/
    ├── mercado-service/
    ├── negociacao-service/
    ├── pedidos-service/
    ├── logistica-service/

```

---

## 4. Banco compartilhado com Cloud SQL

O banco oficial já é uma instância **Cloud SQL PostgreSQL** gerenciada pelo GCP.

**Configuração atual do banco:**

| Item | Valor |
|---|---|
| Host | `136.114.235.212` |
| Banco | `portal_b2b` |
| Schema | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

Os microsserviços de **ambas as VMs** apontam para o mesmo banco Cloud SQL. Isso garante que os dados são consistentes independentemente de qual VM está atendendo o tráfego.

---

## 5. Mudança na conexão dos microsserviços

### Antes — ambiente antigo (PostgreSQL local, já removido)

```env
# AMBIENTE ANTIGO — não usar mais
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
```

O host `postgres` resolvia dentro da rede Docker (`portal-b2b-network`) quando o banco rodava como container local. Esse container foi removido.

### Atual — Cloud SQL

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
```

**Observações importantes:**

- O host `postgres:5432` não existe mais na infraestrutura. O PostgreSQL local foi removido.
- Na arquitetura redundante, o Cloud SQL é o único banco, compartilhado pelas duas VMs.
- O arquivo `.env.example` **não deve conter senha real** nem IP fixo obrigatório — use placeholders.

---

## 6. VM app-primary

A VM principal é responsável por rodar:

- API Gateway (Nginx)
- Microsserviços de todas as equipes
- Containers de aplicação
- Integração com Cloud SQL PostgreSQL
- Integração com Kafka/Redpanda

No dia a dia, o tráfego oficial chega pelo Load Balancer, que pode encaminhar para a VM principal ou para a VM standby conforme a saúde dos backends.

---

## 7. VM app-standby

A VM standby:

- Roda a mesma infraestrutura que a VM principal
- Roda os mesmos microsserviços e front-ends
- Usa o mesmo Cloud SQL PostgreSQL
- **Recebe tráfego do Load Balancer quando saudável**
- **Assume automaticamente quando a VM principal cai** — o Load Balancer detecta via health check e redireciona o tráfego

A VM standby não é passiva. Ela está sempre ativa e disponível para atender requisições.

> **Observação:** O IP público da VM standby deve permanecer reservado como IP estático no GCP para evitar novas mudanças após reinicialização.

---

## 8. Intervenção manual — fallback operacional

O failover HTTP principal já é feito automaticamente pelo Load Balancer. O acesso direto às VMs é somente diagnóstico/contingência.

A intervenção manual é necessária apenas quando a VM standby está desatualizada, desligada ou com container parado. O procedimento abaixo é fallback operacional — **não é o fluxo normal**.

Se for necessário intervir manualmente na VM standby:

1. Acessar a VM standby via SSH.
2. Rodar `git pull` nos repositórios de infraestrutura e microsserviços.
3. Subir a infraestrutura e microsserviços com Docker Compose.
4. Validar os serviços com `check-infra.sh` e `check-services.sh`.

> **Importante:** Não é necessário trocar IP/DNS. O ponto oficial de acesso é sempre o Load Balancer `34.8.17.245`.

```bash
# Na VM standby
cd /opt/portal-b2b/infra/portal-b2b-infra
git pull
bash scripts/start.sh

# Subir cada microsserviço
cd /opt/portal-b2b/services/usuarios-service && git pull && docker compose up -d --build
cd /opt/portal-b2b/services/produtos-service && git pull && docker compose up -d --build
cd /opt/portal-b2b/services/logistica-service && git pull && docker compose up -d --build
# ... repetir para cada serviço

# Validar
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-infra.sh
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-services.sh
```

---

## 9. Load Balancer (implementado)

O Load Balancer HTTP externo já foi implementado no GCP e é o ponto oficial de entrada do sistema.

Load Balancer atual:
http://34.8.17.245

Health check:
GET /health

O Load Balancer distribui para a VM principal ou standby conforme o health check. O failover é automático — se uma VM não responde ao health check, o tráfego vai para a outra.

O Load Balancer cobre a porta 80/Gateway. Serviços expostos em portas diretas (8081, 8082, 8088) só ficam redundantes automaticamente se forem publicados por uma rota no Nginx Gateway (ex: `/`, `/produtos/`, `/logistica/`).

**Endpoints atualmente validados:**

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

```text
Usuário
  ↓
Load Balancer - 34.8.17.245
  ↓
VM saudável
```

**Health check configurado:**

```text
GET /health
```

O Load Balancer envia tráfego apenas para a VM que responder com sucesso ao health check. Se a VM principal parar de responder, o tráfego é automaticamente redirecionado para a VM standby.

---

## 10. Kafka/Redpanda

Nesta fase, cada VM roda seu próprio Redpanda/Kafka local. Isso mantém a infraestrutura de apoio disponível em cada VM, mas ainda não representa um cluster Kafka/Redpanda real com replicação entre brokers. Como evolução futura, pode ser criado um cluster Redpanda/Kafka com múltiplos brokers e replication factor maior que 1.

### Opção futura

- Criar cluster Redpanda/Kafka com 3 brokers.
- Distribuir brokers entre as VMs.
- Configurar `replication.factor` maior que 1.
- Garantir tolerância a falha de pelo menos 1 broker.

---

## 11. O que essa arquitetura cobre

- ✅ Queda de uma VM de aplicação — Load Balancer faz failover HTTP automático
- ✅ Banco compartilhado entre VMs via Cloud SQL
- ✅ Dados consistentes independente de qual VM atende o tráfego
- ✅ Deploy reproduzível nas duas VMs por Git e Docker
- ✅ Load Balancer HTTP com health check automático
- ✅ Sincronização automatizada via `sync-redundant.sh`
- ✅ Restart automático de containers via `unless-stopped`

---

## 12. O que ainda não cobre

- ❌ cluster Kafka/Redpanda real
- ❌ replicação de eventos entre brokers
- ❌ HTTPS/domínio
- ❌ métricas detalhadas com Prometheus/Grafana
- ❌ escalabilidade horizontal automática

---

## 13. Evolução por fases

| Fase | Entrega | Status |
|------|---------|--------|
| 1 | VM principal funcionando | ✅ Implementado |
| 2 | Cloud SQL PostgreSQL | ✅ Implementado |
| 3 | VM standby | ✅ Implementado |
| 4 | Load Balancer HTTP | ✅ Implementado |
| 5 | Sincronização principal → standby | ✅ Implementado |
| 6 | Teste de falha controlada | 🔜 Próxima etapa |
| 7 | Redpanda cluster | 📋 Evolução futura |
| 8 | Kubernetes | 📋 Evolução futura |

**Endereços atuais:**

| Componente | Endereço |
|---|---|
| Load Balancer | `34.8.17.245` |
| VM principal | `34.29.84.207` |
| VM standby | `34.59.229.37` |
| Cloud SQL | `136.114.235.212` |

O acesso recomendado ao sistema é pelo **Load Balancer** (`http://34.8.17.245`), não diretamente pela VM principal.

---

## 14. Texto para apresentação

> "A infraestrutura possui duas VMs de aplicação atrás de um Load Balancer HTTP externo no GCP. As duas VMs rodam a mesma infraestrutura: Nginx API Gateway, microsserviços dockerizados, front-ends dockerizados e Redpanda/Kafka local. O banco de dados oficial é o Cloud SQL PostgreSQL, compartilhado entre as duas VMs. Um Load Balancer HTTP distribui as requisições entre as VMs com base em health check — se uma VM cair, o tráfego vai automaticamente para a outra. O acesso oficial ao sistema é sempre pelo Load Balancer (34.8.17.245). Acesso direto às VMs é apenas diagnóstico."
