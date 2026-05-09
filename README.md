# Portal B2B Distribuído - Infraestrutura

## Objetivo da infraestrutura
Montar a infraestrutura acadêmica centralizada do Portal B2B Distribuído, fornecendo os componentes compartilhados para que as diferentes equipes consigam desenvolver seus microsserviços. Este repositório NÃO implementa regras de negócio ou microsserviços, servindo apenas como fundação de infraestrutura.

## Guia principal para as equipes

Antes de integrar qualquer microsserviço, leia:

[GUIA_DE_INTEGRACAO.md](./GUIA_DE_INTEGRACAO.md)

[Deploy de Front-ends na VM](./docs/deploy-frontends-na-vm.md)

## Padrão de entrega dos microsserviços

Cada equipe deve entregar seu serviço dockerizado contendo:
- `Dockerfile`
- `docker-compose.yml`
- `.env.example`
- Endpoint `/health`

A infraestrutura **não** instalará dependências (npm, pip, maven) manualmente para nenhuma equipe. O deploy e execução do microsserviço devem ocorrer exclusivamente via Docker utilizando a rede da infraestrutura.

## Arquitetura e Componentes Centrais
A arquitetura atual utiliza um Load Balancer HTTP externo no GCP como ponto oficial de entrada, duas VMs de aplicação e banco oficial em Cloud SQL PostgreSQL. A evolução para uma arquitetura redundante com duas VMs de aplicação está documentada em [docs/arquitetura-redundante-gcp.md](./docs/arquitetura-redundante-gcp.md).

- Load Balancer oficial: http://34.8.17.245
- VM principal: 34.29.84.207
- VM standby: 34.59.229.37
- Cloud SQL: 136.114.235.212

> **Observação:** O IP público da VM standby deve permanecer reservado como IP estático no GCP para evitar novas mudanças após reinicialização.

A infraestrutura fornece:
- **API Gateway (Nginx):** Entrada única para as APIs REST. Encaminha requisições para os microsserviços rodando nas portas da VM via `host.docker.internal`.
- **Kafka-compatible Broker (Redpanda):** Barramento central de eventos Kafka para comunicação assíncrona.
- **Banco de Dados Oficial (Cloud SQL PostgreSQL):** Instância gerenciada pelo GCP usando banco `portal_b2b` e schema `portal_b2b`. O PostgreSQL local foi removido da infraestrutura. O banco oficial é exclusivamente o Cloud SQL PostgreSQL em 136.114.235.212.
- **Ferramentas de Suporte:** PgAdmin (Banco) e Kafka UI (Eventos) para testes e visualização.

## Divisão de Responsabilidades

**Equipe de Infraestrutura:**
- Manter e documentar a VM de aplicação.
- Manter API Gateway, Redpanda/Kafka, Kafka UI, PgAdmin e scripts de deploy.
- Manter a configuração de acesso ao Cloud SQL PostgreSQL.

- Criar o schema geral `portal_b2b` e usuários base (`db_portal_b2b` e `svc_portal_b2b`).
- Fornecer documentação de portas, acessos, Cloud SQL, Kafka e Gateway.

**Equipe de Banco de Dados:**
- Utilizar o usuário `db_portal_b2b` para se conectar ao banco central (`portal_b2b`).
- Criar tabelas, relacionamentos, constraints e scripts SQL.
- Manter o modelo físico do banco de dados e garantir padronização (usar prefixos nas tabelas, ex: `produtos_produto`).

**Equipes de Microsserviços:**
- Implementar as APIs, regras de negócio e conectar ao banco de dados com o usuário `svc_portal_b2b`.
- Rodar seu respectivo microsserviço como container Docker, publicando a porta oficial na VM central e conectando o container à rede externa portal-b2b-network.
- Entregar Dockerfile.
- Entregar docker-compose.yml.
- Entregar .env.example.
- Garantir que o container use a rede portal-b2b-network.
- Garantir que o serviço publique a porta oficial no host.
- Usar `136.114.235.212:5432` (Cloud SQL) para PostgreSQL. O host `postgres:5432` do Docker Compose local foi removido.
- Usar redpanda:9092 para Kafka quando rodar em container.
- Publicar e consumir eventos Kafka.
- Fornecer endpoint `/health`.

## O que são as VMs de aplicação?
O ambiente possui duas VMs de aplicação atrás do Load Balancer. Cada VM roda API Gateway, Redpanda/Kafka, Kafka UI, PgAdmin, microsserviços dockerizados e scripts de deploy. O banco oficial é externo, no Cloud SQL PostgreSQL.
- **Banco oficial:** O banco oficial é o Cloud SQL PostgreSQL, usando o banco `portal_b2b` e o schema `portal_b2b`. O PostgreSQL local do Docker Compose foi removido.

*Observação opcional:* Dependendo das limitações acadêmicas, desenvolvedores podem testar localmente usando Tailscale/ZeroTier antes de implantar na VM Central, mas o foco da arquitetura é rodar na VM.

## Como subir a infraestrutura
Para levantar apenas a infraestrutura:
```bash
bash scripts/start.sh
```
Ou diretamente:
```bash
docker compose up -d
```

## Como parar
```bash
bash scripts/stop.sh
```
Ou diretamente:
```bash
docker compose down
```

## Como rodar o check de saúde
Você pode validar os serviços essenciais de infraestrutura através do comando:
```bash
bash scripts/check-infra.sh
```

## Ambiente atual de integração

A infraestrutura está atualmente disponível por meio de um Load Balancer no Google Cloud Platform, com duas VMs de aplicação por trás.

Acesso oficial do sistema:

```text
http://34.8.17.245
```

**Acessos principais:**

| Recurso | URL | Observação |
|---|---|---|
| Load Balancer / Gateway | http://34.8.17.245 | Acesso oficial |
| Health do Gateway | http://34.8.17.245/health | Acesso oficial |
| produtos-service | http://34.8.17.245/api/produtos/health | Acesso oficial |
| Front produtos | http://34.8.17.245/produtos/ | Acesso oficial, se o front estiver rodando na porta 8081 |
| VM principal | http://34.29.84.207 | Diagnóstico direto |
| VM standby | http://34.59.229.37 | Diagnóstico direto |
| PgAdmin (Redundante) | http://34.8.17.245/pgadmin/ | Ferramenta de apoio via Load Balancer |
| Kafka UI principal | http://34.29.84.207:8080 | Ferramenta de apoio |
| Uptime Kuma | http://34.59.229.37:3001 | Painel de status |
| Status Page | http://34.59.229.37:3001/status/portal-b2b-status | Status público |

> **Observação:** O IP da VM principal não deve ser usado como endpoint oficial por microsserviços ou front-ends. O acesso oficial externo deve passar pelo Load Balancer. Caso a VM seja recriada ou o IP mude, esta seção deve ser atualizada.

## Acessos e Validação

| Componente | URL / Conexão | Credenciais / Notas |
|------------|---------------|---------------------|
| API Gateway / Load Balancer | http://34.8.17.245 | Retorna `API Gateway do Portal B2B ativo` em `/health` |
| PgAdmin | http://34.8.17.245/pgadmin/ | `admin@portalb2b.com` / `***`. Permite visualizar as tabelas. Redundante via Load Balancer. |
| Kafka UI | http://34.29.84.207:8080 | Permite monitorar os tópicos e mensagens em tempo real. |
| PostgreSQL (Cloud SQL) | `136.114.235.212:5432` | `db_portal_b2b` (Equipe Banco), `svc_portal_b2b` (Aplicação). Banco oficial. |

| Redpanda/Kafka| `34.29.84.207:9092` | Broker Kafka principal |

**Acesso da Equipe de Banco:**

O banco oficial é o **Cloud SQL PostgreSQL**:
- Host: `136.114.235.212`
- Port: `5432`
- Database: `portal_b2b`
- Schema: `portal_b2b`
- User: `db_portal_b2b`
- Password: `***` *(senha fornecida diretamente pela equipe de infraestrutura)*

> **Nota:** O PgAdmin da VM ainda pode ser utilizado para visualização, mas o banco oficial agora é externo (Cloud SQL).

Se usar **Ferramenta Externa (DBeaver, DataGrip, psql no seu PC)**:
- Host: `136.114.235.212`
- Port: `5432`
- Database: `portal_b2b`
- User: `db_portal_b2b`
- Password: `***` *(senha fornecida diretamente pela equipe de infraestrutura)*

**Acesso das Equipes de Microsserviços (.env):**

**Padrão oficial (Cloud SQL):**
```env
DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

> **Importante:** O host `postgres:5432` do Docker Compose local foi removido. O banco oficial é `136.114.235.212:5432` (Cloud SQL).

**Regras de Integração:**
- `Dockerfile` é obrigatório.
- `docker-compose.yml` é obrigatório.
- A rede externa obrigatória é `portal-b2b-network`.
- A infraestrutura **não** instalará dependências manualmente.

Veja os arquivos na pasta `docs/` para mais detalhes de portas e integrações.

## Deploy controlado dos microsserviços

Neste primeiro momento, o deploy dos microsserviços será feito de forma controlada pela infraestrutura. Cada equipe deve enviar o link do repositório do seu microsserviço. O responsável pela infraestrutura irá clonar o repositório na pasta correta da VM e subir o container com:

```bash
bash scripts/deploy-service.sh nome-service URL_DO_REPOSITORIO
```

Exemplo:

```bash
bash scripts/deploy-service.sh produtos-service https://github.com/EXEMPLO/produtos-service.git
```

Esse processo não substitui a responsabilidade da equipe de entregar `Dockerfile`, `docker-compose.yml`, `.env.example` e `GET /health` funcionando.

Para o passo a passo completo, consulte: [docs/deploy-microsservicos-na-vm.md](./docs/deploy-microsservicos-na-vm.md)

## Testando os microsserviços pelo Gateway

Depois que as equipes subirem seus containers, o responsável pela infraestrutura pode testar todos os endpoints `/health` com:

```bash
bash scripts/check-services.sh
```

Esse script testa:
- usuarios-service
- produtos-service
- fornecimentos-service
- demanda-service
- mercado-service
- negociacao-service
- pedidos-service
- logistica-service
- transportadoras-service

## Redundância e recuperação

O banco oficial atual é o **Cloud SQL PostgreSQL** em `136.114.235.212`.

A infraestrutura possui mecanismos de resiliência e um plano de recuperação para lidar com falhas:

- **Restart automático:** Todos os containers utilizam `restart: unless-stopped`. Se um container cair, o Docker reinicia automaticamente.
- **Health checks:** PostgreSQL e Redpanda possuem health checks configurados para detectar estados degradados.
- **Cloud SQL:** O banco oficial está no Cloud SQL, que possui backups automáticos e exportações gerenciadas pelo GCP.
- **VM Standby:** Estratégia acadêmica recomendada de manter uma segunda VM preparada para assumir em caso de falha da VM principal.

Em caso de falha da VM principal, a infraestrutura pode ser restaurada na VM standby seguindo o procedimento documentado. O banco Cloud SQL permanece acessível externamente.

### Backup e Restore do Banco

O PostgreSQL local foi removido da infraestrutura. O banco oficial é o Cloud SQL PostgreSQL. Use backups/exportações gerenciadas do Cloud SQL no GCP. Não existe mais banco PostgreSQL local na VM. Qualquer tabela criada deve ser criada no Cloud SQL.

Para o plano completo de redundância e recuperação, consulte:

[docs/redundancia-e-recuperacao.md](./docs/redundancia-e-recuperacao.md)

## Arquitetura atual

A arquitetura atual utiliza Load Balancer HTTP externo, duas VMs de aplicação e Cloud SQL PostgreSQL como banco oficial.

Para o estado completo da infraestrutura, consulte: [docs/estado-atual-infra.md](./docs/estado-atual-infra.md)

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal ou VM standby
        ↓
API Gateway Nginx
        ↓
Microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
```

Os IPs 34.29.84.207 e 34.59.229.37 devem ser usados apenas para diagnóstico direto. As equipes devem usar o Load Balancer 34.8.17.245 como entrada oficial.

> **Observação:** Redpanda/Kafka ainda roda localmente em cada VM. Ainda não há cluster Kafka/Redpanda replicado.

**VM principal:**

```text
34.29.84.207
```

O que roda na VM:
- API Gateway (Nginx)
- Redpanda/Kafka
- Kafka UI
- PgAdmin
- Microsserviços dockerizados
- Rede Docker `portal-b2b-network`

### Banco oficial

O banco oficial do projeto é o **Cloud SQL PostgreSQL**:

```text
136.114.235.212
```

| Item | Valor |
|---|---|
| Banco | `portal_b2b` |
| Schema | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

Os microsserviços não devem mais usar `postgres:5432` como banco oficial em ambiente de integração com Cloud SQL. Em vez disso, devem usar:

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

### PostgreSQL local

O container PostgreSQL local foi removido da infraestrutura. O banco oficial é exclusivamente o Cloud SQL PostgreSQL.

A evolução para uma arquitetura redundante com duas VMs de aplicação está documentada em:

[docs/arquitetura-redundante-gcp.md](./docs/arquitetura-redundante-gcp.md)

A migração do PostgreSQL local para Cloud SQL está documentada em:

[docs/migracao-cloud-sql.md](./docs/migracao-cloud-sql.md)

## Operação redundante validada

A infraestrutura atual já foi validada com operação redundante entre duas VMs de aplicação, Load Balancer e banco externo compartilhado.

Componentes atuais:

| Componente | Endereço | Status |
|---|---|---|
| Load Balancer | http://34.8.17.245 | Validado |
| VM principal | `34.29.84.207` | Validada |
| VM standby | `34.59.229.37` | Validada |
| Cloud SQL PostgreSQL | `136.114.235.212` | Validado |
| produtos-service | `/api/produtos/health` | Validado |

Fluxo atual:

```text
Usuário / Frontend
        ↓
Load Balancer - 34.8.17.245
        ↓
VM principal ou VM standby
        ↓
API Gateway Nginx
        ↓
Microsserviços dockerizados
        ↓
Cloud SQL PostgreSQL - 136.114.235.212
```

Acesso oficial das APIs:

```text
http://34.8.17.245/api/{dominio}
```

Acesso oficial do front de produtos, se publicado no Gateway:

```text
http://34.8.17.245/produtos/
```

Acessos diretos às VMs são apenas para diagnóstico:

```text
http://34.29.84.207
http://34.59.229.37
```

Health do Gateway:

```text
http://34.8.17.245/health
```

Health do produtos-service:

```text
http://34.8.17.245/api/produtos/health
```

Comando oficial para sincronizar a infraestrutura nas duas VMs:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/sync-redundant.sh
```

Comando oficial para fazer deploy de um microsserviço nas duas VMs:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

Exemplo:

```bash
bash scripts/deploy-service-redundant.sh produtos-service https://github.com/PedroVian9/SDI.Micro.Produto
```

> **Nota:** A chave SSH usada para a VM principal acessar a VM standby fica somente na VM principal em `~/.ssh/portal_b2b_standby`. Essa chave nunca deve ser versionada no Git.

A operação redundante está documentada em:

[docs/operacao-redundante.md](./docs/operacao-redundante.md)

## Testes da infraestrutura

O roteiro atualizado de testes da infraestrutura, incluindo Cloud SQL, Gateway, Kafka e microsserviços, está em:

[docs/testes-infra.md](./docs/testes-infra.md)

## Observabilidade e Status

O painel visual de status da infraestrutura com Uptime Kuma está documentado em:

[docs/observabilidade-status.md](./docs/observabilidade-status.md)

## Estrutura recomendada da VM

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

- `portal-b2b-infra` guarda a infraestrutura.
- `services` guarda os repositórios dos microsserviços das equipes.
- Cada equipe deve subir seu container dentro da própria pasta de serviço.

As pastas oficiais dos microsserviços podem ser criadas com:

```bash
bash scripts/setup-service-folders.sh
```
