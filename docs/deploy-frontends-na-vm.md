# Deploy de Front-ends na VM

## Objetivo

Este documento define como as equipes devem preparar front-ends que estejam dentro dos repositórios dos microsserviços para deploy na VM central do Portal B2B.

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

A infraestrutura principal está preparada para:

- API Gateway;
- backends/microsserviços;
- PostgreSQL;
- Kafka/Redpanda;
- PgAdmin;
- Kafka UI.

A raiz:

```text
http://34.8.17.245
```

O Load Balancer em `34.8.17.245` é o ponto de entrada oficial. A raiz do Load Balancer é usada pelo Nginx API Gateway. Se a raiz retornar `404`, isso não significa erro; significa apenas que ainda não existe um front-end principal publicado na raiz.

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
- pode ser exposto em uma porta específica.

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

## Modelos de Acesso ao Front-end

Depois do deploy, o acesso oficial do front de produtos é:

http://34.8.17.245/produtos/

E manter os acessos diretos por VM apenas como diagnóstico.

**Acesso oficial do front de produtos pelo Load Balancer:**
http://34.8.17.245/produtos/

**Acessos diretos para diagnóstico:**
http://34.29.84.207:8081
http://34.59.229.37:8081

O Load Balancer atual atende a porta 80/Gateway. Por isso, o front de produtos deve ser publicado pelo Nginx Gateway na rota `/produtos/`. A porta 8081 continua existindo nas VMs, mas deve ser usada apenas para diagnóstico direto.

---

## Portas sugeridas para front-ends

| Equipe | Backend | Front-end sugerido |
|---|---:|---:|
| Produtos | 5002 | 8081 |
| Usuários | 5001 | 8082 |
| Fornecimentos | 5003 | 8083 |
| Demanda | 5004 | 8084 |
| Mercado | 5005 | 8085 |
| Negociação | 5006 | 8086 |
| Pedidos | 5007 | 8087 |
| Logística | 5008 | 3000 |
| Transportadoras | 5009 | 8089 |

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
curl -I http://34.8.17.245/produtos/
```

**Teste direto por porta, somente diagnóstico:**

```bash
curl -I http://34.29.84.207:8081
curl -I http://34.59.229.37:8081
```

> **Observação:** Se o front-end for servido em subpath, como `/produtos/`, a aplicação deve estar preparada para esse base path. Em projetos Vite, por exemplo, pode ser necessário configurar `base: '/produtos/'` no `vite.config.js`. Caso contrário, assets com caminho absoluto, como `/assets/...`, podem quebrar quando publicados atrás de `/produtos/`. Preferencialmente, o front-end deve chamar APIs com rotas relativas, por exemplo `/api/produtos`, em vez de fixar `http://34.29.84.207`.

---

## O que não fazer

- Não rodar `npm install` manualmente na VM como solução final.
- Não rodar `npm run dev` manualmente como entrega final.
- Não expor porta sem avisar a infraestrutura.
- Não alterar o Nginx da infraestrutura sem alinhamento.
- Não usar `localhost` dentro do container para chamar backend.
- Não criar outro PostgreSQL ou Kafka dentro do compose do front.

---

## Observação sobre ambiente de desenvolvimento

Rodar `npm run dev` na VM pode ser usado apenas para **teste temporário**. A entrega final deve ser via Docker.

---

## Observação sobre Cloud SQL e Load Balancer

Front-ends devem chamar as APIs por rota relativa:

```text
/api/produtos
```

ou pelo Load Balancer oficial:

```text
http://34.8.17.245/api/produtos
```

**Não usar no código do front:**

```text
http://34.29.84.207/api/produtos
```

**Não devem chamar o Cloud SQL diretamente.** O Cloud SQL (`136.114.235.212`) é acessado apenas pelos microsserviços/backend.

> **Observação:** Na arquitetura atual, o Load Balancer oficial é `34.8.17.245`. As APIs devem ser consumidas por rotas relativas ou `http://34.8.17.245/api/{dominio}`. Acesso direto a `34.29.84.207` ou `34.59.229.37` deve ser usado apenas para diagnóstico.
