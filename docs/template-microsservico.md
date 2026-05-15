# Template de Microsserviço - Portal B2B

## Estrutura mínima esperada

```text
nome-service/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── README.md
└── código da aplicação
```

## Arquivo .env.example obrigatório

```env
SERVICE_NAME=nome-service
PORT=5000

DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

> **Nota:** O endereço `redpanda:9092` deve ser usado apenas para desenvolvimento local.

Cada equipe deve trocar:
- `SERVICE_NAME`
- `PORT`

E não deve trocar:
- `136.114.235.212` (Cloud SQL oficial)
- `10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092` (Bootstrap do cluster)
- `portal_b2b`
- `svc_portal_b2b`

> **Nota:** O host `postgres` (Docker Compose local) é legado. O banco oficial é o Cloud SQL.

## docker-compose.yml mínimo

```yaml
services:
  nome-service:
    build: .
    container_name: nome-service
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "5000:5000"
    networks:
      - portal-b2b-network

networks:
  portal-b2b-network:
    external: true
```

Observações:
- Trocar `nome-service` pelo nome oficial.
- Trocar `5000` pela porta oficial.
- Manter `portal-b2b-network` como external.
- Não subir outro PostgreSQL.
- Não subir outro Kafka.

## Exemplo FastAPI

Dockerfile de exemplo:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
```

Exemplo mínimo de `/health` em FastAPI:

```python
from fastapi import FastAPI
import os

app = FastAPI()

SERVICE_NAME = os.getenv("SERVICE_NAME", "nome-service")

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": SERVICE_NAME
    }
```

## Exemplo Node.js/Express

Dockerfile de exemplo:

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

Exemplo mínimo de `/health` em Express:

```javascript
const express = require("express");

const app = express();

const port = process.env.PORT || 5000;
const serviceName = process.env.SERVICE_NAME || "nome-service";

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: serviceName
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`${serviceName} running on port ${port}`);
});
```

## Checklist antes de entregar para integração

- [ ] Tenho Dockerfile.
- [ ] Tenho docker-compose.yml.
- [ ] Tenho .env.example.
- [ ] O container_name está correto.
- [ ] A porta oficial está correta.
- [ ] O serviço entra na rede portal-b2b-network.
- [ ] O serviço não sobe outro banco.
- [ ] O serviço não sobe outro Kafka.
- [ ] GET /health responde HTTP 200.
- [ ] /health retorna status ok e service nome-do-servico.
- [ ] Swagger/OpenAPI está funcionando.
- [ ] O serviço não tenta criar tabelas automaticamente.
- [ ] Os eventos Kafka publicados seguem o envelope padrão.
