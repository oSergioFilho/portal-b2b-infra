# Deploy Controlado de Microsserviços na VM

## Objetivo

Este documento descreve como o responsável pela infraestrutura vai subir os microsserviços das equipes nas duas VMs de forma controlada, garantindo consistência, rastreabilidade e ausência de intervenções manuais no código de cada equipe.

---

## Modelo escolhido

Inicialmente, será usado o modelo **controlado pela infraestrutura**:

- As equipes desenvolvem em seus próprios computadores.
- As equipes sobem o código no GitHub.
- As equipes enviam o link do repositório para a infraestrutura.
- A infraestrutura clona o repositório nas duas VMs.
- A infraestrutura executa `docker compose up -d --build` nas duas VMs.
- A equipe continua responsável por corrigir erros no próprio código, `Dockerfile`, `docker-compose.yml` e `.env.example`.

---

## Estrutura de diretórios da VM

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
    └── vendas-service/

```

---

## Preparar as pastas dos serviços

Execute uma vez na VM para criar todas as pastas oficiais:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/setup-service-folders.sh
```

---

## O que cada equipe precisa enviar

Antes de solicitar o deploy, cada equipe deve enviar ao responsável pela infraestrutura:

- [ ] Link do repositório GitHub
- [ ] Nome oficial do serviço (ex: `produtos-service`)
- [ ] Porta oficial usada (ex: `5002`)
- [ ] Confirmação de que o repositório contém `Dockerfile`
- [ ] Confirmação de que o repositório contém `docker-compose.yml`
- [ ] Confirmação de que o repositório contém `.env.example`
- [ ] Confirmação de que `GET /health` está implementado e retorna HTTP 200
- [ ] Confirmação de que Swagger/OpenAPI está disponível

---

## Como subir um microsserviço nas duas VMs (padrão oficial)

O deploy oficial deve ser feito com o script redundante, que publica o serviço na VM principal **e** na VM standby:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

Exemplos reais:

```bash
bash scripts/deploy-service-redundant.sh usuarios-service https://github.com/guilherme-cognitiva/autenticacao-b2b.git
bash scripts/deploy-service-redundant.sh logistica-service https://github.com/faculdade-sistemas-distribuidos/b2b_logistica.git
bash scripts/deploy-service-redundant.sh produtos-service https://github.com/PedroVian9/SDI.Micro.Produto
bash scripts/deploy-service-redundant.sh vendas-service https://github.com/HenriqueSPaixao/portal-b2b-servico-vendas.git
```

O script faz deploy na VM principal e depois na VM standby via SSH.

---

## Deploy apenas na VM atual (teste local — não é o padrão oficial)

Se precisar testar o deploy apenas na VM em que você está (sem replicar para a outra):

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service.sh nome-service URL_DO_REPOSITORIO
```

> **Atenção:** Este comando não replica o deploy para a outra VM. Use apenas para diagnóstico local ou testes isolados. O padrão oficial é `deploy-service-redundant.sh`.

---

## Como o script `deploy-service-redundant.sh` funciona

O script vai:
1. Validar o nome e o link.
2. Criar a pasta se não existir.
3. Clonar o repositório (ou fazer `git pull` se já existir).
4. Verificar os arquivos obrigatórios (`Dockerfile`, `docker-compose.yml`, `.env.example`).
5. Criar `.env` a partir do `.env.example` se não existir.
6. Executar `docker compose up -d --build` na VM principal.
7. SSH na VM standby e repetir os mesmos passos.
8. Mostrar logs recentes.
9. Mostrar os comandos de teste pelo Gateway.

---

## Como subir manualmente, se necessário

```bash
cd /opt/portal-b2b/services/produtos-service
git clone LINK_DO_REPOSITORIO .
cp .env.example .env
docker compose up -d --build
docker logs -f produtos-service
```

### Subindo o bundle de Vendas manualmente

O caso do `vendas-service` é especial por ser um monorepo. Para ele:

```bash
cd /opt/portal-b2b/services/vendas-service
git clone LINK_DO_REPOSITORIO .
cp .env.example .env
docker compose -f docker-compose.yml up -d --build
docker compose -f docker-compose.yml ps
```

O `vendas-service` é um bundle especial que publica:
- `/api/mercado/` -> `mercado-service:5005`
- `/api/negociacoes/` -> `negociacao-service:5006`
- `/mercado/` -> `mercado-web:8085`
- `/negociacao/` -> `negociacao-web:8086`

---

## .env esperado em container

```env
SERVICE_NAME=produtos-service
PORT=5002

DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

> **Atenção:**
> - O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`.
> - O host `postgres` foi removido e não deve ser usado.
> - O barramento de eventos é um **Cluster Redpanda** de 3 brokers. Em integração/produção, use o bootstrap acima.
> - O host `redpanda:9092` deve ser usado **apenas** para desenvolvimento local ou rollback temporário.

> **Nota:** Se a equipe estiver rodando tudo localmente em ambiente próprio, pode usar outro banco local. Mas na VM oficial de integração, o banco deve ser o Cloud SQL.

---

## docker-compose.yml esperado

```yaml
services:
  produtos-service:
    build: .
    container_name: produtos-service
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "5002:5002"
    networks:
      - portal-b2b-network

networks:
  portal-b2b-network:
    external: true
```

> **Regras:**
> - `container_name` deve ser exatamente igual ao nome oficial do serviço.
> - A porta deve ser a porta oficial.
> - A rede `portal-b2b-network` é obrigatória.
> - Não subir outro PostgreSQL no compose do microsserviço.
> - Não subir outro Kafka no compose do microsserviço.

---

## Como testar depois do deploy

**Teste direto na VM:**
```bash
curl http://localhost:5002/health
```

**Teste pelo Gateway na VM:**
```bash
curl http://localhost/api/produtos/health
```

**Teste externo (oficial pelo Load Balancer):**
```bash
curl http://34.8.17.245/api/produtos/health
```

**Teste direto na VM principal (diagnóstico):**
```bash
curl http://34.29.84.207/api/produtos/health
```

> **Observação:** O endereço oficial externo é o Load Balancer `34.8.17.245`. Os IPs das VMs (`34.29.84.207` e `34.59.229.37`) devem ser usados apenas para diagnóstico direto.

---

## Como testar todos os serviços de uma vez

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/check-services.sh
```

---

## O que fazer se der erro

| Erro | Possível causa | Ação |
|---|---|---|
| `Arquivo Dockerfile não encontrado` | Equipe não entregou `Dockerfile` | Pedir correção à equipe |
| `Arquivo docker-compose.yml não encontrado` | Equipe não entregou compose | Pedir correção à equipe |
| `Arquivo .env.example não encontrado` | Equipe não padronizou variáveis | Pedir correção à equipe |
| Gateway retorna `502` | Container não está rodando ou porta errada | Verificar `docker ps` e `docker logs` |
| Banco não conecta | Usou host errado para o banco | Usar `136.114.235.212:5432` (Cloud SQL). O host `postgres` não existe mais na infraestrutura. |
| Kafka não conecta | Usou `localhost` ou `redpanda:9092` em produção | Usar o bootstrap oficial do cluster: `10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092` |
| Porta já em uso | Outro serviço usa a mesma porta | Conferir porta oficial |
| `/health` não responde | Serviço não implementou endpoint ou iniciou com erro | Verificar logs e pedir correção à equipe |

---

## Responsabilidade da infraestrutura

**A infraestrutura faz:**
- Clonar o repositório nas duas VMs.
- Verificar arquivos obrigatórios.
- Criar `.env` a partir do `.env.example`.
- Executar `docker compose up -d --build`.
- Testar `/health`.
- Validar pelo Gateway.

**A infraestrutura não faz:**
- Corrigir código do microsserviço.
- Criar `Dockerfile` da equipe.
- Criar `docker-compose.yml` da equipe.
- Ajustar regra de negócio.
- Instalar dependências manualmente (`npm install`, `pip install`, etc.).
- Criar tabelas no banco sem alinhamento com a equipe de banco.

---

## Lista de comandos úteis

```bash
# Ver containers rodando
docker ps

# Ver logs de um serviço
docker logs -f nome-service

# Ver status dos containers da infra
docker compose ps

# Recriar e subir um serviço
docker compose up -d --build

# Parar um serviço
docker compose down

# Testar endpoint diretamente
curl http://localhost:PORTA/health

# Testar pelo Gateway localmente
curl http://localhost/api/DOMINIO/health

# Testar pelo Gateway externamente (Load Balancer - oficial)
curl http://34.8.17.245/api/DOMINIO/health

# Testar pelo Gateway diretamente na VM (diagnóstico)
curl http://34.29.84.207/api/DOMINIO/health
```
