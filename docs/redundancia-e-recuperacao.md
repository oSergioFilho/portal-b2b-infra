# Redundância e Recuperação da Infraestrutura

## 1. Objetivo

Este documento descreve como a infraestrutura do Portal B2B lida com falhas de containers, falha de serviços e queda de uma das VMs de aplicação. O objetivo é garantir que a equipe tenha um plano documentado de recuperação e que os mecanismos básicos de resiliência estejam configurados.

---

## 2. Arquitetura atual de resiliência

A infraestrutura possui **duas VMs de aplicação atrás de um Load Balancer HTTP externo**. O Load Balancer encaminha tráfego para a VM saudável com base no endpoint `/health`. Se uma VM cair, o tráfego HTTP é direcionado automaticamente para a outra VM saudável.

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal (34.29.84.207) ou VM standby (34.59.229.37)
        ↓
Nginx Gateway
        ↓
Fronts e microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
+ Cluster Redpanda (3 brokers)
```

Pontos principais:
- **O Load Balancer é o ponto oficial de entrada.** O acesso dos usuários e front-ends deve sempre usar `34.8.17.245`.
- **As duas VMs rodam a mesma infraestrutura e os mesmos microsserviços/fronts.**
- **O banco Cloud SQL é compartilhado entre as duas VMs.**
- **Cluster Redpanda (3 brokers):** O Kafka/Redpanda agora opera em cluster com 3 brokers replicados entre as VMs, garantindo que eventos publicados estejam disponíveis no cluster independentemente da VM de origem.
- **O failover HTTP é automático pelo Load Balancer** quando uma VM deixa de responder ao health check.
- **Acesso direto às VMs (`34.29.84.207`, `34.59.229.37`) é apenas para diagnóstico.**

---

## 3. Camada 1: Restart automático de containers

Os containers da infraestrutura e dos microsserviços utilizam a política de restart automático:

```yaml
restart: unless-stopped
```

Isso significa que:
- Se um container **cair por erro interno**, o Docker tentará reiniciá-lo automaticamente.
- Se o **Docker Engine reiniciar** (ex: reboot da VM), os containers voltam automaticamente.
- O container **só não reinicia** se for parado manualmente com `docker compose stop` ou `docker compose down`.

Além disso, os serviços críticos possuem **health checks** configurados:
- **Redpanda:** verifica se os brokers do cluster estão respondendo e saudáveis.

---

## 4. Camada 2: Failover HTTP automático pelo Load Balancer

O Load Balancer HTTP externo no GCP verifica periodicamente o endpoint:

```text
GET /health
```

em cada VM. Se uma VM deixar de responder com sucesso ao health check, o Load Balancer **automaticamente** redireciona todo o tráfego para a VM saudável. Não é necessária nenhuma intervenção manual para o failover HTTP.

Endpoints de validação oficiais:

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

---

## 5. Camada 3: Backups do Cloud SQL

O banco central `portal_b2b` está no Cloud SQL PostgreSQL, que possui backups automáticos e exportações gerenciadas pelo GCP. O banco Cloud SQL permanece acessível independentemente da situação de qualquer VM. Em caso de necessidade de restauração de dados, a equipe de infraestrutura deve usar o console do GCP.

> **Importante:** Em um failover de aplicação (queda de uma VM), **não é necessário restaurar backup de banco**. O Cloud SQL continua disponível e a outra VM já está conectada a ele.

---

## 6. Camada 4: Recuperação manual (fallback operacional)

A recuperação manual é usada apenas como **fallback operacional** nos casos em que:
- A VM standby está desatualizada (sem os microsserviços ou configurações mais recentes).
- A VM standby estava desligada.
- Um container específico na VM standby está parado.

> **Este não é o fluxo principal.** O failover HTTP normal é automático pelo Load Balancer.

### Atualizar a infraestrutura nas duas VMs (comando oficial)

Execute a partir da VM principal:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/sync-redundant.sh
```

Esse script faz:
- `git pull` na VM principal.
- `docker compose up -d --build` na VM principal.
- `check-infra.sh` na VM principal.
- SSH na VM standby.
- `git pull` na VM standby.
- `docker compose up -d --build` na VM standby.
- `check-infra.sh` na VM standby.

### Deploy de um microsserviço nas duas VMs (comando oficial)

```bash
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

Exemplos reais:

```bash
bash scripts/deploy-service-redundant.sh usuarios-service https://github.com/guilherme-cognitiva/autenticacao-b2b.git
bash scripts/deploy-service-redundant.sh logistica-service https://github.com/faculdade-sistemas-distribuidos/b2b_logistica.git
```

### Intervenção manual direta na VM standby (diagnóstico/emergência)

Se for necessário intervir manualmente na VM standby:

```bash
# Na VM standby
cd /opt/portal-b2b/infra/portal-b2b-infra
git pull
bash scripts/start.sh

# Subir cada microsserviço
cd /opt/portal-b2b/services/usuarios-service && git pull && docker compose up -d --build
cd /opt/portal-b2b/services/produtos-service && git pull && docker compose up -d --build
cd /opt/portal-b2b/services/logistica-service && git pull && docker compose up -d --build

# Validar
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-infra.sh
bash /opt/portal-b2b/infra/portal-b2b-infra/scripts/check-services.sh
```

> **Atenção:** Não é necessário trocar IP/DNS em caso de queda de uma VM. O Load Balancer cuida do roteamento automaticamente.

---

## 7. Testes oficiais de validação

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

---

## 8. O que essa solução cobre

✅ Queda de uma VM de aplicação — Load Balancer faz failover HTTP automático para a VM saudável.

✅ Restart automático de containers — política `unless-stopped`.

✅ Banco compartilhado via Cloud SQL — dados consistentes independente de qual VM atende o tráfego.

✅ Deploy reproduzível nas duas VMs — via `deploy-service-redundant.sh`.

✅ Failover HTTP pelo Load Balancer — automático, baseado em health check.

✅ Cluster Kafka/Redpanda replicado — o Redpanda opera como um cluster de 3 brokers para tolerância a falhas e replicação de eventos.

---

## 9. O que essa solução ainda não cobre

❌ **HTTPS/domínio** — o acesso é via IP.

❌ **Métricas avançadas Prometheus/Grafana** — observabilidade básica com Uptime Kuma.

❌ **Autoscaling** — não há escalabilidade horizontal automática.

❌ **Alta disponibilidade real de banco** — o Cloud SQL configurado é básico, sem réplicas de leitura ou failover automático de banco.

---

## 10. Evolução futura

Em uma arquitetura de produção, seria possível evoluir para:

| Componente | Evolução |
|---|---|
| Kafka UI | Visualização centralizada de tópicos e mensagens |
| PostgreSQL | Configuração primary/replica com failover automático |
| Monitoramento | Prometheus + Grafana para métricas em tempo real |
| Logs | Loki + Grafana para logs centralizados |
| DNS | Domínio com HTTPS (TLS) |
| Orquestração | Kubernetes para gerenciamento de containers em escala |

Essas evoluções estão fora do escopo da versão acadêmica atual.

---

## 11. Explicação curta para apresentação

> "A infraestrutura possui duas VMs de aplicação atrás de um Load Balancer HTTP externo. O Load Balancer verifica a saúde de cada VM via `/health` e redireciona o tráfego automaticamente para a VM saudável. O banco de dados é o Cloud SQL PostgreSQL, compartilhado entre as duas VMs. O barramento de eventos é um cluster Redpanda/Kafka com 3 brokers replicados, garantindo alta disponibilidade das mensagens. Cada VM roda o Nginx Gateway e os microsserviços dockerizados. O failover HTTP é automático; a resiliência do Kafka é garantida pelo quórum do cluster."

---

## Referências internas

- [Scripts de deploy e sync](../scripts/)
- [Checklist de microsserviços](./checklist-microsservicos.md)
- [Guia de integração](../GUIA_DE_INTEGRACAO.md)
- [Operação redundante](./operacao-redundante.md)
- [Arquitetura redundante GCP](./arquitetura-redundante-gcp.md)
