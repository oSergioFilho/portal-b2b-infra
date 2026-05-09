# API Gateway

## O Papel do Gateway
O API Gateway funciona como ponto único de entrada (Porta `80`) para todas as APIs REST dos microsserviços do Portal B2B. O Nginx atua como proxy reverso, recebendo requisições externas e encaminhando-as para o serviço adequado rodando na VM.

## Padrão Oficial de Infraestrutura

O padrão atual definido para a arquitetura é:
- O API Gateway Nginx roda em container Docker na VM central.
- Todos os microsserviços também devem rodar em containers próprios na VM central.
- Cada microsserviço publica sua porta oficial no host da VM (ex: `5002:5002`).
- O Gateway acessa os microsserviços pela máquina host usando `host.docker.internal:PORTA`.
- Cada container de microsserviço deve estar na rede portal-b2b-network para acessar o Kafka/Redpanda pelo host redpanda:9092. O banco oficial não é o PostgreSQL local; os microsserviços devem acessar o Cloud SQL PostgreSQL em 136.114.235.212:5432. O host postgres:5432 existe apenas como legado/fallback local.

### Caminho da requisição

```text
Cliente / Frontend
    ↓
Load Balancer - 34.8.17.245
    ↓
Nginx Gateway da VM saudável
    ↓
host.docker.internal:PORTA
    ↓
Container do microsserviço
```

**Exemplo:** `GET /api/produtos/health` → Load Balancer encaminha para VM saudável → Gateway Nginx encaminha para `host.docker.internal:5002` → chega no container `produtos-service` como `GET /health`.

Rotas principais documentadas:
- `/api/produtos/` -> `host.docker.internal:5002`
- `/produtos/` -> `host.docker.internal:8081`

Para o Gateway conseguir acessar o container do microsserviço, o docker-compose.yml do microsserviço precisa publicar a porta oficial no host da VM.

Exemplo:

```yaml
ports:
  - "5002:5002"
```

Sem esse mapeamento, o Gateway não conseguirá acessar host.docker.internal:5002.

### Por que `host.docker.internal`?

O Nginx do Gateway roda em seu próprio container. Como cada microsserviço publica sua porta no host da VM, o Gateway utiliza `host.docker.internal` para alcançar essas portas publicadas.

## Rotas e Remoção de Prefixo

A configuração atual do Nginx mapeia os caminhos usando o padrão `/api/{dominio}/`.
**Importante:** Graças à barra final (`/`) na diretiva `proxy_pass`, o prefixo da rota é removido antes de ser repassado ao microsserviço.

Este é o **padrão oficial**:
- Gateway expõe: `/api/{dominio}/...`
- Microsserviço recebe a rota **sem** o prefixo `/api/{dominio}`.

**Exemplos de Roteamento:**
- `GET http://34.8.17.245/api/produtos/health` -> `produtos-service` recebe `GET /health` na porta `5002`.
- `GET http://34.8.17.245/api/pedidos/health` -> `pedidos-service` recebe `GET /health` na porta `5007`.

As portas e URLs diretas das VMs, como `http://34.29.84.207` e `http://34.59.229.37`, servem apenas como diagnóstico direto.

## Evolução futura (opcional)

Se no futuro todos os microsserviços passarem a rodar no **mesmo Docker Compose** da infraestrutura, o `nginx.conf` poderá ser alterado para usar o nome dos containers diretamente:
```nginx
proxy_pass http://produtos-service:5002/;
```
Essa mudança é opcional e não é necessária na arquitetura atual, onde cada microsserviço tem seu próprio `docker-compose.yml`.

**VPN (Tailscale/ZeroTier):**
A arquitetura anterior considerava cada desenvolvedor rodando seu microsserviço em sua própria máquina via VPN. Esse modelo não é mais o padrão.
