# Redundância e Recuperação da Infraestrutura

## 1. Objetivo

Este documento descreve como a infraestrutura do Portal B2B lida com falhas de containers, falha de serviços e queda da VM principal. O objetivo é garantir que a equipe tenha um plano documentado de recuperação e que os mecanismos básicos de resiliência estejam configurados.

---

## 2. Ponto único de falha atual

Na arquitetura atual, a **VM central concentra toda a infraestrutura e todos os microsserviços**. Isso significa que, se a VM cair completamente, o sistema inteiro fica indisponível.

Esse modelo é aceitável como **primeira versão acadêmica**, pois simplifica o deploy e a operação. No entanto, é fundamental ter um **plano de recuperação** para minimizar o tempo de indisponibilidade caso ocorra uma falha.

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
- **PostgreSQL:** verifica se o banco está aceitando conexões via `pg_isready`.
- **Redpanda:** verifica se o broker Kafka está respondendo via endpoint de saúde.

Esses health checks permitem que o Docker identifique quando um serviço está em estado degradado e tome ações de recuperação.

---

## 4. Camada 2: Backups do PostgreSQL

O banco central `portal_b2b` deve ter **backup periódico** utilizando `pg_dump`. Os backups garantem que, mesmo em caso de perda total da VM, os dados podem ser recuperados.

### Como gerar um backup

```bash
bash scripts/backup-postgres.sh
```

O script salva o dump do banco na pasta:

```
backups/postgres/
```

Cada arquivo é nomeado com timestamp, por exemplo:
```
backups/postgres/portal_b2b_20260505_143000.sql
```

### Onde armazenar os backups

Os backups devem ser **copiados para fora da VM** regularmente. Opções recomendadas:
- Google Drive (via rclone ou upload manual).
- Outra VM ou servidor.
- Armazenamento externo (pendrive, HD externo).
- Repositório privado (apenas para backups pequenos).

> **Recomendação:** Gerar backup antes de qualquer atualização significativa e pelo menos uma vez por dia durante o período de desenvolvimento ativo.

---

## 5. Camada 3: VM Standby

Para reduzir o risco de indisponibilidade prolongada, recomendamos manter uma **VM Standby** preparada para assumir em caso de falha da VM principal.

### VM Principal

- Roda a infraestrutura oficial (PostgreSQL, Redpanda, Nginx, PgAdmin, Kafka UI).
- Roda os microsserviços das equipes.
- Recebe as chamadas do grupo.
- É o ambiente de produção acadêmica.

### VM Standby

- Tem **Docker** e **Docker Compose** instalados.
- Tem o repositório `portal-b2b-infra` **clonado e atualizado**.
- Tem a mesma estrutura de diretórios: `/opt/portal-b2b/`.
- **Recebe cópias dos backups** do banco periodicamente.
- Pode ser **ativada rapidamente** se a VM principal cair.

### Diagrama da estratégia

```text
┌──────────────────────────┐         ┌──────────────────────────┐
│      VM PRINCIPAL        │         │       VM STANDBY         │
│                          │         │                          │
│  Docker Compose (infra)  │  ───▶   │  Docker + Docker Compose │
│  PostgreSQL              │ backup  │  portal-b2b-infra clonado│
│  Redpanda/Kafka          │  ───▶   │  Backups do PostgreSQL   │
│  Nginx API Gateway       │         │  Mesma estrutura /opt/   │
│  Microsserviços          │         │                          │
│                          │         │  (Inativa até necessário)│
└──────────────────────────┘         └──────────────────────────┘
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

4. **Restaurar o último backup do PostgreSQL:**
   ```bash
   bash scripts/restore-postgres.sh backups/postgres/NOME_DO_ULTIMO_BACKUP.sql
   ```

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

✅ Perda parcial da infraestrutura — health checks detectam e Docker reinicia.

✅ Recuperação manual em outra VM — procedimento documentado com VM standby.

✅ Restauração do banco via backup — scripts `backup-postgres.sh` e `restore-postgres.sh`.

---

## 8. O que essa solução ainda não cobre

❌ **Failover automático** — a troca para a VM standby é manual.

❌ **Replicação em tempo real do PostgreSQL** — não há primary/replica configurado.

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

> "A infraestrutura possui uma primeira camada de resiliência com restart automático dos containers e health checks. Além disso, foi definido um plano de recuperação com backups do PostgreSQL e uma VM standby. Caso a VM principal falhe, a infraestrutura pode ser restaurada na VM standby, o banco pode ser recuperado a partir do último backup e os microsserviços podem ser reiniciados. Para produção, a arquitetura poderia evoluir para replicação em tempo real, load balancer e cluster Kafka."

---

## Referências internas

- [Scripts de backup e restore](../scripts/)
- [Checklist de microsserviços](./checklist-microsservicos.md)
- [Guia de integração](../GUIA_DE_INTEGRACAO.md)
