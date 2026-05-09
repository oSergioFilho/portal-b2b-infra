   # Redundância e Recuperação da Infraestrutura

## 1. Objetivo

Este documento descreve como a infraestrutura do Portal B2B lida com falhas de containers, falha de serviços e queda da VM principal. O objetivo é garantir que a equipe tenha um plano documentado de recuperação e que os mecanismos básicos de resiliência estejam configurados.

---

## 2. Ponto único de falha atual

Na arquitetura atual, a **VM central concentra a aplicação e os serviços**. O banco de dados oficial já foi migrado para **Cloud SQL PostgreSQL** (`136.114.235.212`), eliminando o ponto único de falha do banco. Se a VM cair, os microsserviços ficam indisponíveis, mas o banco permanece acessível externamente.

Esse modelo é aceitável como **primeira versão acadêmica**, pois simplifica o deploy e a operação. No entanto, é fundamental ter um **plano de recuperação** para minimizar o tempo de indisponibilidade caso ocorra uma falha na VM.

---

## 3. Camada 1: Recuperação local de containers

Os containers da infraestrutura e dos microsserviços utilizam a política de restart automático:

```yaml
restart: unless-stopped
```

Isso significa que:
- Se um container **cair por erro interno**, o Docker tentará reiniciá-lo automaticamente.
- Se o **Docker Engine reiniciar** (ex: reboot da VM), os containers voltam automaticamente.
- O container **só não reinicia** se for parado manualmente com `docker compose stop` ou `docker compose down`.

Além disso, os serviços críticos possuem **health checks** configurados:
- **Redpanda:** verifica se o broker Kafka está respondendo via endpoint de saúde.

Esses health checks permitem identificar quando um serviço está em estado degradado. A política de restart automático cobre falhas em que o processo do container encerra. Em caso de container unhealthy sem encerramento do processo, a equipe de infraestrutura deve investigar usando docker compose ps e docker logs.

---

## 4. Camada 2: Backups do Cloud SQL

O banco central `portal_b2b` está no Cloud SQL PostgreSQL, que possui backups automáticos e exportações gerenciadas pelo GCP. Em caso de necessidade de restauração, a equipe de infraestrutura deve usar o console do GCP para restaurar um backup ou exportação.

---

## 5. Camada 3: VM Standby

Para reduzir o risco de indisponibilidade prolongada, recomendamos manter uma **VM Standby** preparada para assumir em caso de falha da VM principal.

### VM Principal

- Roda a infraestrutura oficial (Redpanda, Nginx, PgAdmin, Kafka UI).
- Roda os microsserviços das equipes.
- Conecta ao Cloud SQL PostgreSQL (`136.114.235.212`).
- Recebe as chamadas do grupo.
- É o ambiente de produção acadêmica.

### VM Standby

- Tem **Docker** e **Docker Compose** instalados.
- Tem o repositório `portal-b2b-infra` **clonado e atualizado**.
- Tem a mesma estrutura de diretórios: `/opt/portal-b2b/`.
- Conecta ao mesmo **Cloud SQL PostgreSQL** (`136.114.235.212`).
- Pode ser **ativada rapidamente** se a VM principal cair.

### Diagrama da estratégia

```text
┌──────────────────────────┐         ┌──────────────────────────┐
│      VM PRINCIPAL        │         │       VM STANDBY         │
│                          │         │                          │
│  Docker Compose (infra)  │         │  Docker + Docker Compose │
│  Redpanda/Kafka          │         │  portal-b2b-infra clonado│
│  Nginx API Gateway       │         │  Mesma estrutura /opt/   │
│  Microsserviços          │         │                          │
│                          │         │  (Inativa até necessário)│
└──────────────────────────┘         └──────────────────────────┘
         │                                │
         └────────────────┬───────────────┘
                          │
              Cloud SQL PostgreSQL
              136.114.235.212:5432
```

---

## 6. Processo de recuperação em caso de queda da VM principal



Se a VM principal ficar indisponível, siga este procedimento na **VM Standby**:

### Passo a passo

1. **Acessar a VM standby** via SSH ou console.

2. **Atualizar o repositório da infraestrutura:**
   ```bash
   cd /opt/portal-b2b/infra/portal-b2b-infra
   git pull origin main
   ```

3. **Subir a infraestrutura:**
   ```bash
   docker compose up -d
   ```

4. **Verificar Cloud SQL:**
   - O banco de dados está fora da VM (Cloud SQL). Portanto, não é necessário rodar restore de banco de dados na VM. Apenas certifique-se de que a VM Standby tem conectividade com `136.114.235.212`.

5. **Subir os microsserviços das equipes:**
   ```bash
   cd /opt/portal-b2b/services/usuarios-service && docker compose up -d
   cd /opt/portal-b2b/services/produtos-service && docker compose up -d
   # Repetir para cada microsserviço
   ```

6. **Validar infraestrutura:**
   ```bash
   cd /opt/portal-b2b/infra/portal-b2b-infra
   bash scripts/check-infra.sh
   ```

7. **Validar microsserviços:**
   ```bash
   bash scripts/check-services.sh
   ```

8. **Atualizar o IP/DNS usado pelo grupo**, se necessário, apontando para o IP da VM standby.

### Tempo estimado de recuperação

| Etapa | Tempo estimado |
|---|---|
| Acesso à VM standby | 1-2 minutos |
| Atualizar repositório | 1 minuto |
| Subir infraestrutura | 2-3 minutos |
| Restaurar backup | 1-5 minutos (depende do tamanho) |
| Subir microsserviços | 3-5 minutos |
| Validação | 2-3 minutos |
| **Total estimado** | **10-20 minutos** |

---

## 7. O que essa solução cobre

✅ Queda de container individual — restart automático via Docker.

✅ Reinício automático de container — política `unless-stopped`.

✅ Perda parcial da infraestrutura — health checks ajudam a detectar falhas, e containers que encerram são reiniciados pela política restart.

✅ Recuperação manual em outra VM — procedimento documentado com VM standby.

✅ Restauração do banco via backup — gerenciado pelo GCP no Cloud SQL.

---

## 8. O que essa solução ainda não cobre

❌ **Failover automático** — a troca para a VM standby é manual.



❌ **Cluster real de Kafka/Redpanda** — roda com broker único.

❌ **Balanceamento automático entre múltiplas VMs** — não há load balancer entre VMs.

❌ **Alta disponibilidade de produção** — a solução é acadêmica e operacional.

---

## 9. Evolução futura

Em uma arquitetura de produção, seria possível evoluir para:

| Componente | Evolução |
|---|---|
| API Gateway | Load Balancer com duas ou mais instâncias do Nginx |
| Microsserviços | Múltiplas réplicas com balanceamento de carga |
| PostgreSQL | Configuração primary/replica com failover automático |
| Redpanda/Kafka | Cluster com 3 brokers para tolerância a falhas |
| Monitoramento | Prometheus + Grafana para métricas em tempo real |
| Logs | Loki + Grafana para logs centralizados |
| DNS | DNS com failover automático entre VMs |
| Orquestração | Kubernetes para gerenciamento de containers em escala |

Essas evoluções estão fora do escopo da versão acadêmica atual, mas representam o caminho natural para um ambiente de produção.

---

## 10. Explicação curta para apresentação

> "A infraestrutura possui uma primeira camada de resiliência com restart automático dos containers e health checks. O banco de dados oficial foi migrado para Cloud SQL PostgreSQL, eliminando o ponto único de falha do banco local. Além disso, foi definido um plano de recuperação com uma VM standby. Caso a VM principal falhe, a VM standby pode ser ativada apontando para o mesmo banco Cloud SQL, e os microsserviços podem ser reiniciados. Para produção, a arquitetura poderia evoluir para load balancer e cluster Kafka."

---

## Referências internas

- [Scripts de backup e restore](../scripts/)
- [Checklist de microsserviços](./checklist-microsservicos.md)
- [Guia de integração](../GUIA_DE_INTEGRACAO.md)
