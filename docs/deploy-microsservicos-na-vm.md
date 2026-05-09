# Deploy Controlado de Microsserviços na VM

## Objetivo

Este documento descreve como o responsável pela infraestrutura vai subir os microsserviços das equipes na VM central de forma controlada, garantindo consistência, rastreabilidade e ausência de intervenções manuais no código de cada equipe.

---

## Modelo escolhido

Inicialmente, será usado o modelo **controlado pela infraestrutura**:

- As equipes desenvolvem em seus próprios computadores.
- As equipes sobem o código no GitHub.
- As equipes enviam o link do repositório para a infraestrutura.
- A infraestrutura clona o repositório na VM.
- A infraestrutura executa `docker compose up -d --build`.
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
    └── transportadoras-service/
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

## Como subir um microsserviço usando o script

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service.sh produtos-service https://github.com/EXEMPLO/produtos-service.git
```

Outros exemplos:

```bash
bash scripts/deploy-service.sh usuarios-service https://github.com/EXEMPLO/usuarios-service.git
bash scripts/deploy-service.sh demanda-service https://github.com/EXEMPLO/demanda-service.git
bash scripts/deploy-service.sh pedidos-service https://github.com/EXEMPLO/pedidos-service.git
```

O script vai:
1. Validar o nome e o link.
2. Criar a pasta se não existir.
3. Clonar o repositório (ou fazer `git pull` se já existir).
4. Verificar os arquivos obrigatórios (`Dockerfile`, `docker-compose.yml`, `.env.example`).
5. Criar `.env` a partir do `.env.example` se não existir.
6. Executar `docker compose up -d --build`.
7. Mostrar logs recentes.
8. Mostrar os comandos de teste pelo Gateway.

---

## Como subir manualmente, se necessário

```bash
cd /opt/portal-b2b/services/produtos-service
git clone LINK_DO_REPOSITORIO .
cp .env.example .env
docker compose up -d --build
docker logs -f produtos-service
```

---

## .env esperado em container

```env
SERVICE_NAME=produtos-service
PORT=5002

DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

> **Atenção:**
> - O banco oficial é o **Cloud SQL PostgreSQL** em `136.114.235.212:5432`.
> - O host `postgres` foi removido e não deve ser usado. O banco oficial é o Cloud SQL em 136.114.235.212.
> - Dentro do container, **não usar `localhost`** para Kafka. O host correto é `redpanda`.
> - O `localhost` dentro de um container aponta para o próprio container, não para os serviços da infraestrutura.

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

**Teste direto na VM (diagnóstico):**
```bash
curl http://34.29.84.207/api/produtos/health
```

> **Observação:** A partir da arquitetura redundante, o endereço oficial externo é o Load Balancer `34.8.17.245`. Os IPs das VMs (`34.29.84.207` e `34.59.229.37`) devem ser usados apenas para diagnóstico direto.

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
| Kafka não conecta | Usou `localhost` dentro do container | Trocar para `redpanda:9092` |
| Porta já em uso | Outro serviço usa a mesma porta | Conferir porta oficial |
| `/health` não responde | Serviço não implementou endpoint ou iniciou com erro | Verificar logs e pedir correção à equipe |

---

## Responsabilidade da infraestrutura

**A infraestrutura faz:**
- Clonar o repositório.
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
