# Implantação do Cluster Redpanda com 3 Brokers no GCP

## 1. Visão geral

Este documento descreve o passo a passo para implantar um cluster Redpanda com 3 brokers distribuídos em 3 VMs no GCP.

### Arquitetura do cluster

```text
VM principal  (IP interno: IP_INTERNO_VM_PRINCIPAL)  → Broker 0
VM standby    (IP interno: IP_INTERNO_VM_STANDBY)    → Broker 1
VM kafka-3    (IP interno: IP_INTERNO_VM_KAFKA_3)    → Broker 2
```

Os microsserviços conectam ao cluster via:

```env
KAFKA_BOOTSTRAP_SERVERS=IP_INTERNO_VM_PRINCIPAL:9092,IP_INTERNO_VM_STANDBY:9092,IP_INTERNO_VM_KAFKA_3:9092
```

> **Importante:** Usar **IPs internos** da VPC, não IPs públicos. Os IPs internos não mudam com reinicialização da VM (a menos que sejam efêmeros).

---

## 2. Pré-requisitos

- 3 VMs no GCP na mesma VPC
- Docker e Docker Compose plugin instalados nas 3 VMs
- Repositório `portal-b2b-infra` clonado nas 3 VMs
- Firewall interno liberado (ver seção 8)

---

## 3. Criar a terceira VM (kafka-3)

### 3.1. Criar a VM no GCP

```bash
gcloud compute instances create portal-b2b-vm-kafka-3 \
  --zone=us-central1-a \
  --machine-type=e2-small \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --boot-disk-size=20GB \
  --tags=portal-b2b-kafka \
  --metadata=startup-script='#!/bin/bash
apt-get update
apt-get install -y docker.io docker-compose-plugin git
systemctl enable docker
systemctl start docker
usermod -aG docker $(whoami)'
```

### 3.2. Reservar IP interno fixo (recomendado)

Para evitar que o IP interno mude após reinicialização, use um endereço interno estático:

```bash
gcloud compute addresses create portal-b2b-kafka-3-internal \
  --region=us-central1 \
  --subnet=default \
  --addresses=IP_INTERNO_DESEJADO
```

Ou, para manter o IP interno atual estável, simplesmente anote o IP interno da VM:

```bash
gcloud compute instances describe portal-b2b-vm-kafka-3 \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'
```

### 3.3. Instalar Docker e Docker Compose plugin

Se o startup-script não instalou automaticamente:

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

## 4. Coletar os IPs internos das 3 VMs

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
gcloud compute instances describe portal-b2b-vm-kafka-3 \
  --zone=us-central1-a \
  --format='get(networkInterfaces[0].networkIP)'
```

Anote os 3 IPs internos. Exemplo:

```text
VM principal: 10.128.0.10
VM standby:   10.128.0.11
VM kafka-3:   10.128.0.12
```

---

## 5. Gerar os arquivos .env de cada broker

### Opção 1: Usar o script auxiliar

Em cada VM, execute:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

# Na VM principal:
bash scripts/generate-redpanda-env.sh primary 10.128.0.10 10.128.0.11 10.128.0.12

# Na VM standby:
bash scripts/generate-redpanda-env.sh standby 10.128.0.10 10.128.0.11 10.128.0.12

# Na VM kafka-3:
bash scripts/generate-redpanda-env.sh kafka3 10.128.0.10 10.128.0.11 10.128.0.12
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

## 6. Subir os brokers (nas 3 VMs)

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

## 7. Validar o cluster

Após os 3 brokers estarem rodando:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

export KAFKA_BOOTSTRAP_SERVERS=10.128.0.10:9092,10.128.0.11:9092,10.128.0.12:9092

# Health check do cluster
bash scripts/check-kafka-cluster.sh

# Criar tópicos oficiais
bash redpanda/create-topics-cluster.sh
```

Resultado esperado do health check:

```text
=== Cluster Info ===
(3 brokers listados)

=== Cluster Health ===
Healthy: true

=== Tópicos do Cluster ===
(15 tópicos oficiais)

✅ Todos os tópicos oficiais estão presentes no cluster.
```

---

## 8. Configurar firewall interno no GCP

Os brokers precisam se comunicar entre si e os microsserviços precisam acessar o Kafka. Todas as portas devem ser liberadas **apenas na rede interna**.

### Portas necessárias

| Porta | Protocolo | Serviço |
|-------|-----------|---------|
| 9092 | TCP | Kafka API (produção/consumo de mensagens) |
| 33145 | TCP | Redpanda RPC (comunicação entre brokers) |
| 9644 | TCP | Redpanda Admin API (monitoramento) |
| 8081 | TCP | Schema Registry (se usado) |
| 8082 | TCP | Pandaproxy/REST Proxy (se usado) |

### Criar regra de firewall

```bash
gcloud compute firewall-rules create allow-redpanda-internal \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:9092,tcp:33145,tcp:9644,tcp:8081,tcp:8082 \
  --source-ranges=FAIXA_INTERNA_DA_VPC \
  --target-tags=portal-b2b-kafka \
  --description="Permite comunicação interna entre brokers Redpanda e microsserviços"
```

> **Recomendação de segurança:** Prefira usar `--target-tags` e `--source-tags` para restringir o acesso apenas às VMs relevantes, em vez de liberar toda a faixa da VPC.

Exemplo com tags:

```bash
gcloud compute firewall-rules create allow-redpanda-internal \
  --network=default \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:9092,tcp:33145,tcp:9644 \
  --source-tags=portal-b2b,portal-b2b-kafka \
  --target-tags=portal-b2b-kafka \
  --description="Permite comunicação interna entre VMs do portal-b2b para Redpanda"
```

Para verificar as regras existentes:

```bash
gcloud compute firewall-rules list --filter="name~redpanda"
```

---

## 9. Atualizar os microsserviços

### 9.1. Atualizar o .env de cada microsserviço

Em cada VM, atualizar o `.env` de cada microsserviço em `/opt/portal-b2b/services/*/`:

**Antes:**

```env
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

**Agora:**

```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.10:9092,10.128.0.11:9092,10.128.0.12:9092
```

### 9.2. Recriar os containers dos microsserviços

```bash
for SERVICE_DIR in /opt/portal-b2b/services/*/; do
  echo "Recriando $(basename $SERVICE_DIR)..."
  cd "$SERVICE_DIR"
  docker compose up -d --build
done
```

Ou individualmente:

```bash
cd /opt/portal-b2b/services/usuarios-service && docker compose up -d --build
cd /opt/portal-b2b/services/produtos-service && docker compose up -d --build
# ... repetir para cada serviço
```

---

## 10. Parar o Redpanda local (docker-compose.yml principal)

Após o cluster estar funcionando, o Redpanda local do `docker-compose.yml` principal não é mais necessário em produção/integração.

O Redpanda local foi movido para o profile `local-kafka`. Para garantir que ele não está rodando:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
docker compose down
docker compose up -d  # Sobe apenas pgadmin, kafka-ui, nginx-gateway
```

> **Nota:** O Kafka UI no `docker-compose.yml` principal agora aponta para `${KAFKA_BOOTSTRAP_SERVERS}`, que deve apontar para o cluster.

---

## 11. Atualizar o Kafka UI

O `.env` da infraestrutura principal deve ter:

```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.10:9092,10.128.0.11:9092,10.128.0.12:9092
```

O Kafka UI no `docker-compose.yml` principal já referencia `${KAFKA_BOOTSTRAP_SERVERS}` e usa `network_mode: host` para acessar os IPs internos.

---

## 12. Rollback — Reverter para Redpanda local

Se precisar reverter temporariamente para o Redpanda local:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

# Subir o Redpanda local via profile
docker compose --profile local-kafka up -d

# Atualizar .env dos microsserviços:
# KAFKA_BOOTSTRAP_SERVERS=redpanda:9092

# Recriar containers dos microsserviços
```

> **Aviso:** O Redpanda local é single-node sem replicação. Usar apenas como contingência temporária.

---

## 13. Checklist de implantação

- [ ] Terceira VM criada no GCP
- [ ] Docker e Docker Compose instalados nas 3 VMs
- [ ] Repositório clonado nas 3 VMs
- [ ] IPs internos coletados
- [ ] Arquivos .env gerados para cada VM
- [ ] Firewall interno configurado
- [ ] Broker subido na VM principal
- [ ] Broker subido na VM standby
- [ ] Broker subido na VM kafka-3
- [ ] Cluster saudável (3 brokers visíveis)
- [ ] Tópicos oficiais criados com replication factor 3
- [ ] .env dos microsserviços atualizado com KAFKA_BOOTSTRAP_SERVERS do cluster
- [ ] Containers dos microsserviços recriados
- [ ] Kafka UI apontando para o cluster
- [ ] Redpanda local desativado do docker-compose.yml principal
- [ ] check-kafka-cluster.sh passa sem erros
- [ ] check-infra.sh passa sem erros
