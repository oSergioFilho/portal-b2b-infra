# Portal B2B Distribuído - Infraestrutura

## Objetivo da infraestrutura
Montar a infraestrutura acadêmica centralizada do Portal B2B Distribuído, fornecendo os componentes compartilhados para que as diferentes equipes consigam desenvolver seus microsserviços. Este repositório NÃO implementa regras de negócio ou microsserviços, servindo apenas como fundação de infraestrutura.

## Arquitetura e Componentes Centrais
A arquitetura final define que **todos os microsserviços e a infraestrutura rodam na mesma VM central**.

A infraestrutura fornece:
- **API Gateway (Nginx):** Entrada única para as APIs REST. Encaminha requisições para os microsserviços rodando nas portas da VM via `host.docker.internal`.
- **Kafka-compatible Broker (Redpanda):** Barramento central de eventos Kafka para comunicação assíncrona.
- **Banco de Dados Centralizado (PostgreSQL):** Instância física única usando um schema geral (`portal_b2b`).
- **Ferramentas de Suporte:** PgAdmin (Banco) e Kafka UI (Eventos) para testes e visualização.

## Divisão de Responsabilidades

**Equipe de Infraestrutura:**
- Configurar e manter a VM Central e ambiente Docker.
- Disponibilizar PostgreSQL, PgAdmin, Redpanda/Kafka, Kafka UI e API Gateway.
- Criar o schema geral `portal_b2b` e usuários base (`db_portal_b2b` e `svc_portal_b2b`).
- Fornecer documentação de portas e acessos.

**Equipe de Banco de Dados:**
- Utilizar o usuário `db_portal_b2b` para se conectar ao banco central (`portal_b2b`).
- Criar tabelas, relacionamentos, constraints e scripts SQL.
- Manter o modelo físico do banco de dados e garantir padronização (usar prefixos nas tabelas, ex: `produtos_produto`).

**Equipes de Microsserviços:**
- Implementar as APIs, regras de negócio e conectar ao banco de dados com o usuário `svc_portal_b2b`.
- Rodar seu respectivo microsserviço na porta oficial designada na VM central.
- Publicar e consumir eventos Kafka.
- Fornecer endpoint `/health`.

## O que é a VM Central?
O ambiente do projeto funcionará em uma **VM Central** (Máquina Virtual em nuvem ou um servidor dedicado).
- **O que roda na VM central?** Tudo. A infraestrutura (via Docker Compose) e todos os microsserviços das equipes (via execução direta no host ou container adicional na mesma rede).
- **Banco de Dados Único:** Ao invés de um schema por microsserviço, todos compartilharão o schema `portal_b2b`.

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

## Acessos e Validação

| Componente | URL / Conexão | Credenciais / Notas |
|------------|---------------|---------------------|
| API Gateway | http://IP_DA_VM | Retorna `API Gateway do Portal B2B ativo` em `/health` |
| PgAdmin | http://IP_DA_VM:5050 | `admin@portalb2b.com` / `admin`. Permite visualizar as tabelas do PostgreSQL. |
| Kafka UI | http://IP_DA_VM:8080 | Permite monitorar os tópicos e mensagens em tempo real. |
| PostgreSQL | `IP_DA_VM:5432` | `postgres` (Admin), `db_portal_b2b` (Equipe Banco), `svc_portal_b2b` (Aplicação) |
| Redpanda/Kafka| `IP_DA_VM:9092` | Broker Kafka principal |

**Acesso da Equipe de Banco:**

Se usar o **PgAdmin web (já incluso na infra)**:
- Host: `postgres` (Pois o PgAdmin roda dentro do Docker e acessa o banco pelo nome interno).
- Port: `5432`
- Database: `portal_b2b`
- User: `db_portal_b2b`
- Password: `senha_db_portal_b2b`

Se usar **Ferramenta Externa (DBeaver, DataGrip, psql no seu PC)**:
- Host: `IP_DA_VM` (Ou `localhost` se estiver rodando a infra na sua própria máquina).
- Port: `5432`
- Database: `portal_b2b`
- User: `db_portal_b2b`
- Password: `senha_db_portal_b2b`

**Acesso das Equipes de Microsserviços (.env):**
- URL do Banco: `postgresql://svc_portal_b2b:senha_portal_b2b@localhost:5432/portal_b2b` (Se rodando na VM).
- Schema: `portal_b2b`

Veja os arquivos na pasta `docs/` para mais detalhes de portas e integrações.
