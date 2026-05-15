# Implantação do Cluster Redpanda com 3 Brokers no GCP

## 1. Visão geral

Este documento descreve o passo a passo para implantar um cluster Redpanda com 3 brokers distribuídos em 3 VMs no GCP.

### Arquitetura do cluster

```text
portal-b2b-vm          (IP interno: 10.128.0.2)  → Broker 0  (VM principal)
portal-b2b-vm-standby  (IP interno: 10.128.0.3)  → Broker 1  (VM standby)
portal-b2b-kafka-3     (IP interno: 10.128.0.4)  → Broker 2  (VM dedicada Kafka)
```

Bootstrap oficial dos microsserviços:

```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

> **Importante:** Usar **IPs internos** da VPC, não IPs públicos.

---

## 2. Pré-requisitos

- 3 VMs no GCP na mesma VPC
- Docker e Docker Compose plugin instalados nas 3 VMs
- Repositório `portal-b2b-infra` clonado nas 3 VMs
- Firewall interno liberado (ver seção 8)

---

## 3. Terceira VM (portal-b2b-kafka-3)

### 3.1. Dados da VM criada

A terceira VM já foi criada com as seguintes configurações:

| Campo | Valor |
|-------|-------|
| Nome | `portal-b2b-kafka-3` |
| Zona | `us-central1-a` |
| Tipo de máquina | `e2-standard-2` |
| Imagem | Ubuntu 22.04 LTS |
| Disco | 50 GB |
| Tag de rede | `redpanda` |
| IP interno | `10.128.0.4` |

### 3.2. Comando para recriar (referência)

Caso precise recriar a VM do zero:

```bash
gcloud compute instances create portal-b2b-kafka-3 \
  --zone=us-central1-a \
  --machine-type=e2-standard-2 \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB \
  --tags=redpanda
```

### 3.3. Instalar Docker e Docker Compose plugin

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
# Relogar para o grupo docker ter efeito
```

### 3.4. Clonar o repositório

```bash
sudo mkdir -p /opt/portal-b2b/infra
cd /opt/portal-b2b/infra
sudo git clone https://github.com/oSergioFilho/portal-b2b-infra.git
cd portal-b2b-infra
```

---

## 4. IPs internos das 3 VMs

Os IPs internos reais são:

```text
portal-b2b-vm          → 10.128.0.2
portal-b2b-vm-standby  → 10.128.0.3
portal-b2b-kafka-3     → 10.128.0.4
```

Para conferir:

```bash
gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,tags.items)"
```

Ou individualmente:

```bash
# VM principal
gcloud compute instances describe portal-b2b-vm \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'

# VM standby
gcloud compute instances describe portal-b2b-vm-standby \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'

# VM kafka-3
gcloud compute instances describe portal-b2b-kafka-3 \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'
```

---

## 5. Gerar os arquivos .env de cada broker

### Opção 1: Usar o script auxiliar

Em cada VM, execute:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

# Na VM principal:
bash scripts/generate-redpanda-env.sh primary 10.128.0.2 10.128.0.3 10.128.0.4

# Na VM standby:
bash scripts/generate-redpanda-env.sh standby 10.128.0.2 10.128.0.3 10.128.0.4

# Na VM kafka-3:
bash scripts/generate-redpanda-env.sh kafka3 10.128.0.2 10.128.0.3 10.128.0.4
```

### Opção 2: Copiar manualmente do exemplo

```bash
# Na VM principal:
cp redpanda/env.primary.example redpanda/.env
# Editar redpanda/.env e substituir os IPs placeholder pelos IPs reais

# Na VM standby:
cp redpanda/env.standby.example redpanda/.env

# Na VM kafka-3:
cp redpanda/env.kafka3.example redpanda/.env
```

---

## 6. Parar o Redpanda local antigo (VMs principal e standby)

> **Obrigatório antes de subir o broker do cluster.** O `docker-compose.cluster.yml` usa `network_mode: host` e ocupa as portas reais da VM (9092, 33145, 9644, 8081, 8082). Se o Redpanda local antigo estiver rodando, o broker do cluster não conseguirá subir.

Nas VMs principal e standby:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

# Parar e remover o Redpanda local antigo (profile local-kafka):
docker compose --profile local-kafka down --remove-orphans || true

# Verificar se as portas estão livres:
sudo ss -lntp | grep -E ':9092|:33145|:9644|:8081|:8082' || echo "Portas livres."
```

Se alguma dessas portas estiver ocupada por outro processo/container, identifique e pare o processo antes de continuar:

```bash
# Identificar processo na porta 9092:
sudo ss -lntp | grep :9092

# Se for um container antigo:
docker ps | grep redpanda
docker stop portal-b2b-redpanda || true
docker rm portal-b2b-redpanda || true
```

> **Nota:** Na VM kafka-3, essa etapa não é necessária porque é uma VM nova sem Redpanda local anterior.

---

## 7. Subir os brokers (nas 3 VMs)

**Importante:** Subir os 3 brokers em sequência rápida. O cluster só fica saudável quando todos os seed servers estão acessíveis.

Em cada VM:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra/redpanda
docker compose --env-file .env -f docker-compose.cluster.yml up -d
```

Verificar se o container subiu:

```bash
docker ps | grep redpanda
docker logs portal-b2b-redpanda
```

---

## 8. Configurar firewall interno no GCP

### Portas necessárias

| Porta | Protocolo | Serviço |
|-------|-----------|---------|
| 9092 | TCP | Kafka API (produção/consumo de mensagens) |
| 33145 | TCP | Redpanda RPC (comunicação entre brokers) |
| 9644 | TCP | Redpanda Admin API (monitoramento) |
| 8081 | TCP | Schema Registry (se usado) |
| 8082 | TCP | Pandaproxy/REST Proxy (se usado) |

### Regra de firewall criada

A regra de firewall já foi criada com o seguinte comando:

```bash
gcloud compute firewall-rules create allow-redpanda-internal \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:9092,tcp:33145,tcp:9644,tcp:8081,tcp:8082 \
  --source-ranges=10.128.0.0/20 \
  --target-tags=redpanda
```

As três VMs possuem a tag `redpanda`.

### Verificar a regra e as tags

```bash
gcloud compute firewall-rules list --filter="name=allow-redpanda-internal"

gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,tags.items)"
```

---

## 9. Validar o cluster

Após os 3 brokers estarem rodando:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

export KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092

# Health check do cluster
bash scripts/check-kafka-cluster.sh

# Criar tópicos oficiais
bash redpanda/create-topics-cluster.sh

# Verificar novamente (agora com tópicos)
bash scripts/check-kafka-cluster.sh
```

Resultado esperado:

```text
=== Cluster Info ===
(3 brokers listados)

=== Cluster Health ===
Healthy: true

=== Tópicos do Cluster ===
(15 tópicos oficiais)

✅ Todos os tópicos oficiais estão presentes no cluster.
```

### Teste de publicação e consumo

**Publicar mensagem de teste:**

```bash
docker run --rm -i --network host docker.redpanda.com/redpandadata/redpanda:latest \
  rpk topic produce produto_cadastrado --brokers "$KAFKA_BOOTSTRAP_SERVERS"
```

Digite a mensagem JSON e finalize com `Ctrl+D`:

```json
{"eventId":"teste","eventType":"produto_cadastrado","payload":{"id":"teste","nome":"Produto Teste"}}
```

**Consumir a mensagem:**

```bash
docker run --rm --network host docker.redpanda.com/redpandadata/redpanda:latest \
  rpk topic consume produto_cadastrado --brokers "$KAFKA_BOOTSTRAP_SERVERS" -n 1
```

A mensagem publicada deve aparecer no output.

---

## 10. Atualizar `.env` da infraestrutura

Atualizar o `KAFKA_BOOTSTRAP_SERVERS` no `.env` da infraestrutura para que o Kafka UI aponte para o cluster:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/set-kafka-bootstrap-env.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

Depois recriar o Kafka UI:

```bash
docker compose up -d
```

> **Nota:** O Kafka UI no `docker-compose.yml` principal usa `${KAFKA_BOOTSTRAP_SERVERS}` com `network_mode: host` para acessar os IPs internos.

---

## 11. Atualizar os microsserviços

### 11.1. Atualizar o .env de todos os microsserviços

```bash
bash scripts/update-services-kafka-bootstrap.sh 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

**Antes:**

```env
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

**Agora:**

```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

### 11.2. Recriar os containers dos microsserviços

```bash
for SERVICE_DIR in /opt/portal-b2b/services/*/; do
  if [ -f "$SERVICE_DIR/docker-compose.yml" ]; then
    echo "Recriando $(basename "$SERVICE_DIR")..."
    (cd "$SERVICE_DIR" && docker compose up -d --build --force-recreate)
  fi
done
```

Ou individualmente:

```bash
cd /opt/portal-b2b/services/usuarios-service && docker compose up -d --build
cd /opt/portal-b2b/services/produtos-service && docker compose up -d --build
# ... repetir para cada serviço
```

---

## 12. Rollback — Reverter para Redpanda local

Se precisar reverter temporariamente para o Redpanda local:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

# 1. Parar o broker do cluster:
cd redpanda
docker compose --env-file .env -f docker-compose.cluster.yml down
cd ..

# 2. Subir o Redpanda local via profile:
docker compose --profile local-kafka up -d

# 3. Atualizar .env dos microsserviços:
bash scripts/update-services-kafka-bootstrap.sh redpanda:9092

# 4. Recriar containers dos microsserviços:
for SERVICE_DIR in /opt/portal-b2b/services/*/; do
  if [ -f "$SERVICE_DIR/docker-compose.yml" ]; then
    echo "Recriando $(basename "$SERVICE_DIR")..."
    (cd "$SERVICE_DIR" && docker compose up -d --build --force-recreate)
  fi
done

# 5. Atualizar .env da infra:
bash scripts/set-kafka-bootstrap-env.sh redpanda:9092
docker compose up -d
```

> **Aviso:** O Redpanda local é **single-node sem replicação**. Usar apenas como **contingência temporária**. A volta para o local significa perda de tolerância a falha de broker e perda de replicação de eventos.

---

## 13. Checklist de implantação

- [ ] Terceira VM (`portal-b2b-kafka-3`) criada no GCP
- [ ] Docker e Docker Compose instalados nas 3 VMs
- [ ] Repositório clonado nas 3 VMs
- [ ] IPs internos confirmados (10.128.0.2, 10.128.0.3, 10.128.0.4)
- [ ] Firewall `allow-redpanda-internal` configurado com tag `redpanda`
- [ ] Redpanda local antigo parado nas VMs principal e standby
- [ ] Portas 9092/33145/9644 livres nas 3 VMs
- [ ] Arquivos .env gerados para cada VM
- [ ] Broker subido na VM principal (10.128.0.2)
- [ ] Broker subido na VM standby (10.128.0.3)
- [ ] Broker subido na VM kafka-3 (10.128.0.4)
- [ ] Cluster saudável (3 brokers visíveis)
- [ ] Tópicos oficiais criados com replication factor 3
- [ ] Teste de publicação/consumo validado
- [ ] `.env` da infra atualizado com `KAFKA_BOOTSTRAP_SERVERS` do cluster
- [ ] Kafka UI apontando para o cluster
- [ ] `.env` dos microsserviços atualizado com `KAFKA_BOOTSTRAP_SERVERS` do cluster
- [ ] Containers dos microsserviços recriados
- [ ] `check-kafka-cluster.sh` passa sem erros
- [ ] `check-infra.sh` passa sem erros
