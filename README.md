# Portal B2B Distribuído - Infraestrutura

## Objetivo da infraestrutura
Montar a infraestrutura acadêmica centralizada do Portal B2B Distribuído, fornecendo os componentes compartilhados para que as diferentes equipes consigam desenvolver seus microsserviços. Este repositório NÃO implementa regras de negócio ou microsserviços, servindo apenas como fundação de infraestrutura.

## Guia principal para as equipes

Antes de integrar qualquer microsserviço, leia:

[GUIA_DE_INTEGRACAO.md](./GUIA_DE_INTEGRACAO.md)

## Padrão de entrega dos microsserviços

Cada equipe deve entregar seu serviço dockerizado contendo:
- `Dockerfile`
- `docker-compose.yml`
- `.env.example`
- Endpoint `/health`

A infraestrutura **não** instalará dependências (npm, pip, maven) manualmente para nenhuma equipe. O deploy e execução do microsserviço devem ocorrer exclusivamente via Docker utilizando a rede da infraestrutura.

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
- Rodar seu respectivo microsserviço como container Docker, publicando a porta oficial na VM central e conectando o container à rede externa portal-b2b-network.
- Entregar Dockerfile.
- Entregar docker-compose.yml.
- Entregar .env.example.
- Garantir que o container use a rede portal-b2b-network.
- Garantir que o serviço publique a porta oficial no host.
- Usar postgres:5432 para PostgreSQL quando rodar em container.
- Usar redpanda:9092 para Kafka quando rodar em container.
- Publicar e consumir eventos Kafka.
- Fornecer endpoint `/health`.

## O que é a VM Central?
O ambiente do projeto funcionará em uma **VM Central** (Máquina Virtual em nuvem ou um servidor dedicado).
- **O que roda na VM central?** Tudo. A infraestrutura (via Docker Compose) e todos os microsserviços das equipes devem rodar como containers próprios, usando a rede Docker compartilhada `portal-b2b-network`. A execução direta no host da VM fica apenas como alternativa emergencial.
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

**Padrão em container (Obrigatório):**
```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
DB_SCHEMA=portal_b2b
KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

*(Se rodar direto na VM sem Docker, use `localhost` no lugar de `postgres` e `redpanda`).*

**Regras de Integração:**
- `Dockerfile` é obrigatório.
- `docker-compose.yml` é obrigatório.
- A rede externa obrigatória é `portal-b2b-network`.
- A infraestrutura **não** instalará dependências manualmente.

Veja os arquivos na pasta `docs/` para mais detalhes de portas e integrações.

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

A infraestrutura possui mecanismos de resiliência e um plano de recuperação para lidar com falhas:

- **Restart automático:** Todos os containers utilizam `restart: unless-stopped`. Se um container cair, o Docker reinicia automaticamente.
- **Health checks:** PostgreSQL e Redpanda possuem health checks configurados para detectar estados degradados.
- **Backup do PostgreSQL:** Scripts para gerar e restaurar backups do banco `portal_b2b`.
- **VM Standby:** Estratégia acadêmica recomendada de manter uma segunda VM preparada para assumir em caso de falha da VM principal.

Em caso de falha da VM principal, a infraestrutura pode ser restaurada na VM standby seguindo o procedimento documentado.

### Gerar backup do banco

```bash
bash scripts/backup-postgres.sh
```
* **Atenção:** Backups gerados em `backups/postgres/` não devem ser commitados no Git.
* **Recomendação:** Após gerar backup, copie o arquivo para fora da VM principal.

### Restaurar backup do banco

```bash
bash scripts/restore-postgres.sh backups/postgres/NOME_DO_BACKUP.sql
```
* **Recomendação:** A restauração deve ser feita preferencialmente em VM standby ou ambiente limpo.
* O script possui uma **confirmação interativa** para evitar sobrescrever dados por engano.
* Para automação, é possível usar `--force` (use apenas quando tiver certeza):
  ```bash
  bash scripts/restore-postgres.sh backups/postgres/NOME_DO_BACKUP.sql --force
  ```

Para o plano completo de redundância e recuperação, consulte:

[docs/redundancia-e-recuperacao.md](./docs/redundancia-e-recuperacao.md)

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
