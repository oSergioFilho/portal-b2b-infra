# Arquitetura Redundante no GCP

## 1. Objetivo

Este documento descreve a evolução da infraestrutura atual do Portal B2B para uma arquitetura redundante com duas VMs de aplicação e banco PostgreSQL compartilhado via Cloud SQL.

O objetivo é reduzir o ponto único de falha da VM central, permitindo que o sistema continue disponível mesmo em caso de queda da VM principal.

---

## 2. Limitação da arquitetura atual

Hoje a VM central (`34.29.84.207`) concentra os componentes de aplicação:

- API Gateway (Nginx)
- Microsserviços de todas as equipes
- Kafka/Redpanda
- PgAdmin
- Kafka UI

O banco de dados oficial já foi migrado para **Cloud SQL PostgreSQL** (`136.114.235.212`), reduzindo a dependência do banco local.

Se a VM cair, os microsserviços ficam indisponíveis, mas o banco permanece acessível externamente.

---

## 3. Arquitetura proposta

A proposta é separar o banco de dados em uma instância Cloud SQL PostgreSQL e manter duas VMs de aplicação: uma principal e uma standby.

```text
Usuários / Frontend
        ↓
Load Balancer ou IP/DNS
        ↓
┌──────────────────┐    ┌──────────────────┐
│  VM app-primary  │    │  VM app-standby  │
│  Gateway         │    │  Gateway         │
│  Microsserviços  │    │  Microsserviços  │
└────────┬─────────┘    └────────┬─────────┘
         │                       │
         └───────────┬───────────┘
                     ↓
          Cloud SQL PostgreSQL
```

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
    └── transportadoras-service/
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

### Antes — arquitetura de VM única

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
```

O host `postgres` resolve dentro da rede Docker (`portal-b2b-network`) porque o banco roda como container na mesma VM.

### Atual — Cloud SQL

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
```

**Observações importantes:**

- `postgres:5432` é usado quando o banco roda dentro do Docker Compose local.
- Na arquitetura redundante, o Cloud SQL deve ser usado quando houver duas VMs compartilhando o mesmo banco.
- O arquivo `.env.example` **não deve conter senha real** nem IP fixo obrigatório — use placeholders.

---

## 6. VM app-primary

A VM principal é responsável por rodar:

- API Gateway (Nginx)
- Microsserviços de todas as equipes
- Containers de aplicação
- Integração com Cloud SQL PostgreSQL
- Integração com Kafka/Redpanda

No dia a dia, todo o tráfego é direcionado para esta VM.

---

## 7. VM app-standby

A VM standby é responsável por:

- Ter Docker instalado e configurado
- Ter o repositório `portal-b2b-infra` clonado e atualizado
- Ter os mesmos microsserviços clonados
- Usar o mesmo Cloud SQL PostgreSQL
- **Assumir caso a VM principal fique indisponível**

A VM standby deve estar preparada para subir a infraestrutura a qualquer momento, sem depender de transferências de dados ou configurações manuais longas.

---

## 8. Estratégia de failover manual

Inicialmente o failover será manual. Se a VM principal cair:

1. Acessar a VM standby via SSH.
2. Rodar `git pull` nos repositórios de infraestrutura e microsserviços.
3. Subir a infraestrutura e microsserviços com Docker Compose.
4. Validar os serviços com `check-infra.sh` e `check-services.sh`.
5. Usar o IP da VM standby temporariamente ou atualizar o DNS.

```bash
# Na VM standby
cd /opt/portal-b2b/infra/portal-b2b-infra
git pull
bash scripts/start.sh

# Subir cada microsserviço
cd /opt/portal-b2b/services/usuarios-service && git pull && docker compose up -d --build
cd /opt/portal-b2b/services/produtos-service && git pull && docker compose up -d --build
# ... repetir para cada serviço

# Validar
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-infra.sh
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-services.sh
```

---

## 9. Estratégia com Load Balancer

Como evolução, um **Load Balancer** do GCP pode ser colocado na frente das duas VMs para automatizar o redirecionamento de tráfego.

```text
Usuário
  ↓
Load Balancer
  ↓
VM saudável
```

**Health check sugerido:**

```text
GET /health
```

O Load Balancer deve enviar tráfego apenas para a VM que responder com sucesso ao health check. Se a VM principal parar de responder, o tráfego é automaticamente redirecionado para a VM standby.

---

## 10. Kafka/Redpanda

A versão atual usa **Redpanda/Kafka em broker único** rodando na VM principal.

Na arquitetura redundante, existem duas possibilidades:

### Opção acadêmica inicial (recomendada)

- Manter Redpanda como broker único na VM principal.
- Documentar a limitação: se a VM principal cair, o broker Kafka também cai.
- Priorizar o banco compartilhado e a redundância de aplicação.

### Opção futura

- Criar cluster Redpanda/Kafka com 3 brokers.
- Distribuir brokers entre as VMs.
- Configurar `replication.factor` maior que 1.
- Garantir tolerância a falha de pelo menos 1 broker.

---

## 11. O que essa arquitetura cobre

- ✅ Queda da VM de aplicação principal
- ✅ Retomada do sistema na VM standby
- ✅ Banco compartilhado entre VMs
- ✅ Menor risco de perda de dados
- ✅ Deploy reproduzível por Git e Docker

---

## 12. O que ainda não cobre

- ❌ Failover instantâneo sem Load Balancer
- ❌ Kafka cluster real
- ❌ Múltiplas réplicas automáticas de microsserviços
- ❌ Kubernetes
- ❌ Escalabilidade horizontal automática

---

## 13. Evolução por fases

| Fase | Entrega | Status |
|------|---------|--------|
| 1 | VM principal funcionando | ✅ Implementado |
| 2 | Cloud SQL PostgreSQL | ✅ Implementado |
| 3 | VM standby | ✅ Implementado |
| 4 | Load Balancer HTTP | ✅ Implementado |
| 5 | Failover manual/controlado | 🔜 Próxima etapa |
| 6 | Redpanda cluster | 📋 Evolução futura |
| 7 | Kubernetes | 📋 Evolução futura |

**Endereços atuais:**

| Componente | Endereço |
|---|---|
| Load Balancer | `34.8.17.245` |
| VM principal | `34.29.84.207` |
| VM standby | `104.197.23.241` |
| Cloud SQL | `136.114.235.212` |

O acesso recomendado ao sistema é pelo **Load Balancer** (`34.8.17.245`), não diretamente pela VM principal.

---

## 14. Texto para apresentação

> A infraestrutura inicialmente foi validada em uma VM central. O banco foi migrado para Cloud SQL PostgreSQL, eliminando o ponto único de falha do banco local. Para reduzir o ponto único de falha da aplicação, foram criadas duas VMs: uma principal e uma standby. As duas VMs utilizam o mesmo banco Cloud SQL. Um Load Balancer HTTP externo distribui as requisições entre as VMs, verificando a saúde de cada uma via `/health`. Se uma VM cair, o Load Balancer redireciona automaticamente para a VM saudável.
