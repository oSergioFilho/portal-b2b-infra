# Operação Redundante

## 1. Objetivo

Documentar como operar a infraestrutura redundante do Portal B2B com VM principal, VM standby, Cloud SQL e Load Balancer.

## 2. Componentes atuais

| Componente | Endereço | Função |
|---|---|---|
| Load Balancer | `34.8.17.245` | Entrada principal do sistema |
| VM principal | `34.29.84.207` | Aplicação principal |
| VM standby | `104.197.23.241` | Aplicação redundante |
| Cloud SQL | `136.114.235.212` | Banco oficial compartilhado |

## 3. Fluxo atual

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal ou VM standby
        ↓
Microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
        ↓
Kafka/Redpanda local da VM
```

## 4. Load Balancer

O Load Balancer HTTP externo utiliza o endpoint:

```text
GET /health
```

para verificar se cada VM está saudável.

Acesso principal:

```text
http://34.8.17.245
```

Endpoint validado:

```text
http://34.8.17.245/health
```

Endpoint do produtos-service validado:

```text
http://34.8.17.245/api/produtos/health
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
bash scripts/deploy-service-redundant.sh produtos-service https://github.com/PedroVian9/SDI.Micro.Produto
```

Esse script faz deploy na principal e depois na standby.

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

Após sincronizar, testar:

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/produtos/health
```

Também é possível testar diretamente:

```bash
curl http://34.29.84.207/health
curl http://104.197.23.241/health
```

## 9. Observação sobre banco

O banco oficial é o Cloud SQL PostgreSQL:

```text
136.114.235.212
```

As duas VMs usam o mesmo banco.

O PostgreSQL local continua apenas como legado/fallback.

## 10. Observação sobre Kafka

Nesta fase, cada VM roda seu próprio Redpanda/Kafka local.

Isso atende à demonstração acadêmica de redundância da aplicação e Gateway.

Como evolução futura, pode ser criado um cluster Kafka/Redpanda real com múltiplos brokers.

## 11. Fluxo operacional recomendado

Para atualização de documentação/infra:

```bash
bash scripts/sync-redundant.sh
```

Para atualização de microsserviço:

```bash
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```
