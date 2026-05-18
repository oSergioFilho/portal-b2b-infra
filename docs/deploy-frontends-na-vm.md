# Deploy de Front-ends na VM

## Objetivo

Este documento define como as equipes devem preparar front-ends que estejam dentro dos repositórios dos microsserviços para deploy nas VMs do Portal B2B.

---

## Regra principal

Se uma equipe tiver front-end, ele **deve ser entregue dockerizado**.

A infraestrutura **não vai executar manualmente**:

```bash
npm install
npm run dev
npm run build
```

diretamente na VM como solução final.

Esses comandos devem estar **dentro do Dockerfile** do front-end.

---

## Situação atual

A infraestrutura possui duas VMs de aplicação atrás de um Load Balancer HTTP externo (`34.8.17.245`). Cada VM roda Nginx API Gateway, microsserviços e front-ends dockerizados.

**Front-ends oficiais já validados:**

| Front | Porta | Rota oficial | Status |
|---|---|---|---|
| Portal principal (portal-front / usuários) | 8082 | http://34.8.17.245/ | ✅ Validado |
| Front produtos | 8081 | http://34.8.17.245/produtos/ | ✅ Validado |
| Front logística | 8088 | http://34.8.17.245/logistica/ | ✅ Validado |

O Load Balancer em `34.8.17.245` é o ponto de entrada oficial. A raiz (`/`) aponta para o `portal-front` (portal principal de usuários).

---

## Diferença entre backend e front-end

**Backend/microsserviço:**
- expõe API REST;
- responde pelo Gateway em `/api/{dominio}`;
- exemplo: `http://34.8.17.245/api/produtos/health`

**Front-end:**
- interface visual;
- geralmente React, Vite, Angular ou Next;
- precisa ser buildado e servido por um container próprio;
- deve ser publicado no Nginx Gateway para ficar acessível pelo Load Balancer.

---

## Modelo recomendado para front-end de equipe

Se a equipe de produtos tiver front-end, o compose do repositório pode subir dois serviços:

- `produtos-service`: backend na porta 5002;
- `produtos-front`: front-end na porta 8081.

Exemplo:

```yaml
services:
  produtos-service:
    build: .
    container_name: produtos-service
    restart: unless-stopped
    env_file:
      - .env
    environment:
      ASPNETCORE_URLS: http://0.0.0.0:5002
      ASPNETCORE_ENVIRONMENT: Production
    ports:
      - "5002:5002"
    networks:
      - portal-b2b-network

  produtos-front:
    build:
      context: ./front-end
    container_name: produtos-front
    restart: unless-stopped
    ports:
      - "8081:80"
    depends_on:
      - produtos-service
    networks:
      - portal-b2b-network

networks:
  portal-b2b-network:
    external: true
```

---

## Exemplo de Dockerfile para React/Vite

Criar em:

`front-end/Dockerfile`

```dockerfile
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
```

---

## Exemplo de nginx.conf do front-end

Criar em:

`front-end/nginx.conf`

```nginx
server {
    listen 80;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
        proxy_pass http://produtos-service:5002/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## Front-ends em subpath — configuração obrigatória de base

Front-ends publicados em subpath (como `/produtos/` ou `/logistica/`) **precisam** configurar o `base` no `vite.config.js`. Sem isso, os assets com caminho absoluto (como `/assets/...`) quebram quando publicados atrás de um subpath.

### Front de Produtos — base: `/produtos/`

```js
// vite.config.js
export default {
  base: '/produtos/',
}
```

### Front de Logística — base: `/logistica/`

```js
// vite.config.js
export default {
  base: '/logistica/',
}
```

### Portal principal — base: `/` (raiz)

```js
// vite.config.js
export default {
  base: '/',
}
```

---

## Chamadas de API — use rotas relativas

As chamadas de API dentro dos front-ends devem usar rotas relativas, não fixar IPs das VMs:

```text
✅ /api/usuarios
✅ /api/produtos
✅ /api/logistica
❌ http://34.29.84.207/api/produtos
❌ http://34.59.229.37/api/logistica
```

---

## Modelos de Acesso ao Front-end

Depois do deploy, os acessos oficiais são pelos caminhos no Load Balancer:

| Front | Acesso oficial |
|---|---|
| Portal principal (usuários) | http://34.8.17.245/ |
| Produtos | http://34.8.17.245/produtos/ |
| Demandas / Pedidos (unificados) | http://34.8.17.245/demandas/ |
| Logística | http://34.8.17.245/logistica/ |

Os acessos diretos pelas portas das VMs devem ser usados apenas como diagnóstico:

```text
http://34.29.84.207:8082  (portal-front — diagnóstico)
http://34.29.84.207:8081  (produtos-front — diagnóstico)
http://34.29.84.207:8084  (demandas-front — diagnóstico)
http://34.29.84.207:8088  (logistica-front — diagnóstico)
http://34.59.229.37:8082  (portal-front — diagnóstico)
http://34.59.229.37:8081  (produtos-front — diagnóstico)
http://34.59.229.37:8084  (demandas-front — diagnóstico)
http://34.59.229.37:8088  (logistica-front — diagnóstico)
```

---

## Portas sugeridas para front-ends

| Equipe | Backend | Front-end sugerido |
|---|---:|---:|
| Usuários | 5001 | 8082 |
| Produtos | 5002 | 8081 |
| Fornecimentos | 5003 | 8083 |
| Demanda / Pedidos | 5004 / 5007 | 8084 (unificados no demandas-front) |
| Mercado | 5005 | 8085 |
| Negociação | 5006 | 8086 |
| Pedidos | 5007 | - (integrado ao front de demandas) |
| Logística | 5008 | 8088 |

**Observação:**
Se apenas uma equipe tiver front-end, a porta pode ser combinada manualmente. O importante é **não repetir porta**.

---

## Como validar

Depois do deploy:

```bash
docker ps
```

**Teste oficial pelo Load Balancer:**

```bash
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
```

**Teste direto por porta, somente diagnóstico:**

```bash
curl -I http://34.29.84.207:8082
curl -I http://34.29.84.207:8081
curl -I http://34.29.84.207:8088
```

---

## O que não fazer

- Não rodar `npm install` manualmente na VM como solução final.
- Não rodar `npm run dev` manualmente como entrega final.
- Não expor porta sem avisar a infraestrutura.
- Não alterar o Nginx da infraestrutura sem alinhamento.
- Não usar `localhost` dentro do container para chamar backend.
- Não criar outro PostgreSQL ou Kafka dentro do compose do front.
- Não fixar o IP da VM (`34.29.84.207` ou `34.59.229.37`) como endpoint de API no código do front.

---

## Observação sobre ambiente de desenvolvimento

Rodar `npm run dev` na VM pode ser usado apenas para **teste temporário**. A entrega final deve ser via Docker.

---

## Observação sobre Cloud SQL e Load Balancer

Front-ends devem chamar as APIs por rota relativa:

```text
/api/usuarios
/api/produtos
/api/logistica
```

ou pelo Load Balancer oficial:

```text
http://34.8.17.245/api/usuarios
http://34.8.17.245/api/produtos
http://34.8.17.245/api/logistica
```

**Não devem chamar o Cloud SQL diretamente.** O Cloud SQL (`136.114.235.212`) é acessado apenas pelos microsserviços/backend.
