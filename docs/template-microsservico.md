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

DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
DB_SCHEMA=portal_b2b

KAFKA_BOOTSTRAP_SERVERS=redpanda:9092
```

Explicar que cada equipe deve trocar:
- `SERVICE_NAME`
- `PORT`

E não deve trocar:
- `postgres`
- `redpanda`
- `portal_b2b`
- `svc_portal_b2b`

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

Explicar:
- trocar `nome-service` pelo nome oficial;
- trocar `5000` pela porta oficial;
- manter `portal-b2b-network` como external;
- não subir outro PostgreSQL;
- não subir outro Kafka.

## Exemplo FastAPI

Incluir Dockerfile:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "5000"]
```

Incluir exemplo mínimo de `/health` em FastAPI:

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

Incluir Dockerfile:

```dockerfile
FROM node:20-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 5000

CMD ["npm", "start"]
```

Incluir exemplo mínimo de `/health` em Express:

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
