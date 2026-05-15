# Operação Redundante

## 1. Objetivo

Documentar como operar a infraestrutura redundante do Portal B2B com VM principal, VM standby, Cloud SQL e Load Balancer.

## 2. Componentes atuais

| Componente | Endereço | Função |
|---|---|---|
| Load Balancer | `34.8.17.245` | Entrada principal e oficial do sistema |
| VM principal | `34.29.84.207` | Aplicação — diagnóstico direto |
| VM standby | `34.59.229.37` | Aplicação redundante — diagnóstico direto |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado entre as duas VMs |

## 3. Fluxo atual

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal ou VM standby saudável
        ↓
Nginx Gateway
        ↓
Fronts e microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
+ Cluster Redpanda/Kafka (3 brokers)
```

Pontos importantes:
- **Cloud SQL é compartilhado** pelas duas VMs. Os dados são consistentes independente de qual VM atende o tráfego.
- **Cluster Redpanda (3 brokers) é replicado.** O barramento de eventos agora opera em cluster com 3 brokers distribuídos, garantindo alta disponibilidade e persistência de dados.
- **O Load Balancer só balanceia HTTP na porta 80.** Serviços/fronts em portas diretas (8081, 8082, 8088) só ficam redundantes automaticamente se forem publicados por uma rota no Nginx Gateway (ex: `/produtos/`, `/logistica/`, `/`).
- **O acesso oficial é sempre pelo Load Balancer.**

## 4. Load Balancer

O Load Balancer HTTP externo utiliza o endpoint:

```text
GET /health
```

para verificar se cada VM está saudável. Se uma VM deixar de responder, o tráfego HTTP é automaticamente redirecionado para a VM saudável — sem intervenção manual.

Acesso principal:

```text
http://34.8.17.245
```

## 5. Sincronização da infraestrutura

Para atualizar a infraestrutura nas duas VMs, entrar apenas na VM principal e executar:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/sync-redundant.sh
```

Esse script faz:

- `git pull` na VM principal;
- `docker compose up -d --build` na VM principal;
- `check-infra.sh` na VM principal;
- SSH na VM standby;
- `git pull` na VM standby;
- `docker compose up -d --build` na VM standby;
- `check-infra.sh` na VM standby.

## 6. Deploy redundante de microsserviço

Para subir ou atualizar um microsserviço nas duas VMs, executar na VM principal:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

Exemplos reais:

```bash
bash scripts/deploy-service-redundant.sh usuarios-service https://github.com/guilherme-cognitiva/autenticacao-b2b.git
bash scripts/deploy-service-redundant.sh logistica-service https://github.com/faculdade-sistemas-distribuidos/b2b_logistica.git
```

Esse script faz deploy na VM principal e depois na VM standby.

## 7. Configuração SSH necessária

A VM principal precisa conseguir acessar a VM standby por SSH.

A chave privada deve ficar somente na VM principal:

```text
~/.ssh/portal_b2b_standby
```

A chave pública correspondente deve estar em:

```text
~/.ssh/authorized_keys
```

na VM standby.

> **Nunca commitar chave SSH no repositório.**

## 8. Testes após sincronização

Após sincronizar, testar todos os endpoints oficiais pelo Load Balancer:

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

Também é possível testar diretamente nas VMs (somente diagnóstico):

```bash
curl http://34.29.84.207/health
curl http://34.59.229.37/health
```

## 9. Observação sobre banco

O banco oficial é o Cloud SQL PostgreSQL:

```text
136.114.235.212
```

As duas VMs usam o mesmo banco. O PostgreSQL local foi removido.

## 10. Observação sobre Kafka/Redpanda

O barramento de eventos agora opera como um **cluster Redpanda com 3 brokers**:

- **Broker 0:** VM principal (10.128.0.2)
- **Broker 1:** VM standby (10.128.0.3)
- **Broker 2:** VM kafka-3 (10.128.0.4)

**Configuração para Microsserviços:**
```env
KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

**Resiliência:**
- O cluster utiliza **replication factor 3** para todos os tópicos oficiais.
- O cluster possui tolerância a falhas, permitindo que a operação continue normalmente mesmo com a **queda de 1 broker**.
- O endereço `redpanda:9092` deve ser usado apenas para desenvolvimento local ou rollback temporário.
- **Portas Técnicas:** RPC (33145), Admin (9644), Schema Registry (18081), Pandaproxy (18082).
- **Aviso:** Portas 8081 e 8082 são front-ends, não Kafka.

## 11. Fluxo operacional recomendado

Para atualização de documentação/infra:

```bash
bash scripts/sync-redundant.sh
```

Para atualização de microsserviço:

```bash
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

## 12. Validação realizada

A operação redundante foi validada com sucesso.

Foram executados os seguintes testes:

```bash
bash scripts/sync-redundant.sh
```

Resultado:

- VM principal atualizada com `git pull origin main`;
- infraestrutura da VM principal recriada com `docker compose up -d --build`;
- `check-infra.sh` executado com sucesso na VM principal;
- conexão SSH da VM principal para a VM standby funcionando;
- VM standby atualizada com `git pull origin main`;
- infraestrutura da VM standby recriada com `docker compose up -d --build`;
- `check-infra.sh` executado com sucesso na VM standby;
- Load Balancer validado.

Endpoints validados atualmente:

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

Retornos esperados:

```text
API Gateway do Portal B2B ativo
{"status":"ok","service":"usuarios-service"}
{"status":"ok","service":"produtos-service"}
{"status":"ok","service":"logistica-service"}
HTTP 200 (front principal)
HTTP 200 (front produtos)
HTTP 200 (front logística)
```

## 13. Configuração SSH entre as VMs

Para que `sync-redundant.sh` funcione, a VM principal precisa acessar a VM standby via SSH.

Na VM principal, a chave privada esperada é:

```text
~/.ssh/portal_b2b_standby
```

A chave pública correspondente deve estar no arquivo:

```text
~/.ssh/authorized_keys
```

da VM standby.

Comando para testar a conexão a partir da VM principal:

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37 "hostname && date"
```

Resultado esperado:

```text
portal-b2b-vm-standby
```

> **Nunca commitar chave SSH no repositório.**
