# Portal B2B Distribuído - Infraestrutura

## Objetivo da infraestrutura
Montar a infraestrutura acadêmica centralizada do Portal B2B Distribuído, fornecendo os componentes compartilhados para que as diferentes equipes consigam desenvolver seus microsserviços de forma isolada, porém conectada. Este repositório NÃO implementa regras de negócio, servindo apenas como fundação.

## Arquitetura e Componentes Centrais
O sistema é um Portal B2B baseado em microsserviços, com a infraestrutura fornecendo:
- **API Gateway (Nginx):** Entrada única para as APIs REST (comunicando com `host.docker.internal`).
- **Kafka-compatible Broker (Redpanda):** Barramento central de eventos Kafka para comunicação assíncrona.
- **Banco de Dados Centralizado (PostgreSQL):** Instância física única, porém com esquemas lógicos e usuários isolados por microsserviço (simulando "database per service").
- **Ferramentas de Suporte:** PgAdmin (Banco) e Kafka UI (Eventos) para testes e visualização.

## O que é a VM Central?
O ambiente ideal para o projeto funcionar com todas as equipes é subir esta infraestrutura em uma **VM Central** (Máquina Virtual em nuvem ou um servidor dedicado na rede da turma). 
- **O que roda na VM central?** Somente os componentes *deste* repositório (PostgreSQL, Redpanda, Gateway, PgAdmin, Kafka UI).
- **Onde rodam os microsserviços?** Os microsserviços das equipes devem rodar localmente no computador de cada desenvolvedor, conectando-se aos recursos da VM central.

## Pré-requisitos
- Docker e Docker Compose instalados.
- Se for executar os scripts diretamente: bash (no Windows pode ser Git Bash ou WSL).

## Como subir a infraestrutura (Local ou na VM)
Pelo script:
```bash
bash scripts/start.sh
```
Ou diretamente:
```bash
docker compose up -d
```

## Como parar
Pelo script:
```bash
bash scripts/stop.sh
```
Ou diretamente:
```bash
docker compose down
```

## Acessos e Validação

| Componente | URL / Conexão | Credenciais / Notas |
|------------|---------------|---------------------|
| API Gateway | http://localhost | Retorna `API Gateway do Portal B2B ativo` em `/health` |
| PgAdmin | http://localhost:5050 | `admin@portalb2b.com` / `admin`. Permite visualizar as tabelas do PostgreSQL. |
| Kafka UI | http://localhost:8080 | Permite monitorar os tópicos e mensagens em tempo real. |
| PostgreSQL | `localhost:5432` | `postgres` / `postgres` (Admin) |
| Redpanda/Kafka| `localhost:9092` | - |

**Para configurar o servidor no PgAdmin:**
- Host: `postgres`
- Port: `5432`
- User: `postgres`
- Password: `postgres`
- Database: `portal_b2b`

## Migrando de Localhost para a VM Central

Para que todos trabalhem juntos, sigam este roteiro:
1. **Validar localmente:** O responsável da infraestrutura roda tudo no `localhost` e verifica se os serviços respondem.
2. **Subir na VM central:** Clonar este projeto na VM e rodar `docker compose up -d`. A VM deve permanecer ligada.
3. **Mudar as Variáveis de Ambiente:** Em vez de `localhost`, os `.env` das equipes devem usar o IP da VM (`IP_DA_VM`).
4. **Rede Privada (Tailscale/ZeroTier):** É altamente recomendado não expor bancos e Kafka na internet pública. Usem ferramentas como **Tailscale** ou **ZeroTier** para criar uma rede virtual privada (VPN). Assim, o `IP_DA_VM` será o IP privado fornecido pela VPN, e todos os computadores da turma estarão na mesma rede segura. Apenas o API Gateway (porta 80) deveria, em teoria, ser público.

## Checklist de validação
Você pode rodar o script de validação:
```bash
bash scripts/check-infra.sh
```

## Troubleshooting e Práticas Proibidas
- **Problema de porta em uso:** Feche serviços locais (como um postgres na 5432) antes de subir a infraestrutura.
- **Kafka sendo usado como banco:** O Kafka é apenas um barramento de eventos (mensageria), não armazene estado permanente nele em substituição ao PostgreSQL.
- **Ignorando o API Gateway:** Chamadas síncronas de fora devem sempre passar pelo Gateway (Nginx).
