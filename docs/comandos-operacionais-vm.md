# Comandos Operacionais das VMs

Guia rápido ("cola operacional") para o responsável pela infraestrutura executar os comandos mais usados na VM principal e na VM standby.

---

## 1. Acessos principais

| Recurso | Endereço |
|---|---|
| Load Balancer (oficial) | http://34.8.17.245 |
| VM principal | 34.29.84.207 |
| VM standby | 34.59.229.37 |
| Cloud SQL | 136.114.235.212:5432 |

**Caminhos nas VMs:**

```text
Infra:    /opt/portal-b2b/infra/portal-b2b-infra
Serviços: /opt/portal-b2b/services
```

---

## 2. Entrar na pasta da infra

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
```

---

## 3. Atualizar a infraestrutura na VM principal

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
git pull origin main
```

---

## 4. Sincronizar infraestrutura com a standby

```bash
bash scripts/sync-redundant.sh
```

> Esse comando atualiza a infraestrutura da VM standby a partir da VM principal. Execute sempre após alterações em `nginx.conf`, `docker-compose.yml` ou qualquer arquivo da infra.

---

## 5. Deploy redundante de microsserviço

```bash
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

**Exemplos:**

```bash
bash scripts/deploy-service-redundant.sh usuarios-service https://github.com/guilherme-cognitiva/autenticacao-b2b.git

bash scripts/deploy-service-redundant.sh logistica-service https://github.com/faculdade-sistemas-distribuidos/b2b_logistica.git

bash scripts/deploy-service-redundant.sh produtos-service URL_DO_REPOSITORIO
```

> Esse comando faz o deploy na VM principal e depois na VM standby automaticamente.

---

## 6. Deploy somente na VM atual

```bash
bash scripts/deploy-service.sh nome-service URL_DO_REPOSITORIO
```

> Usar apenas quando quiser testar em uma VM específica. Para deploy oficial, usar o script redundante da seção 5.

---

## 7. Testes básicos do Gateway e Load Balancer

```bash
# Via Load Balancer (oficial)
curl http://34.8.17.245/health

# Via Gateway local da VM
curl http://localhost/health
```

---

## 8. Testar microsserviços pelo Gateway

**Via Load Balancer (oficial):**

```bash
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/fornecimentos/health
curl http://34.8.17.245/api/demandas/health
curl http://34.8.17.245/api/mercado/health
curl http://34.8.17.245/api/negociacoes/health
curl http://34.8.17.245/api/pedidos/health
curl http://34.8.17.245/api/logistica/health
```

**Via Gateway local (diagnóstico da VM):**

```bash
curl http://localhost/api/usuarios/health
curl http://localhost/api/produtos/health
curl http://localhost/api/logistica/health
```

---

## 9. Testar portas diretas dos serviços

```bash
curl http://localhost:5001/health   # usuarios-service
curl http://localhost:5002/health   # produtos-service
curl http://localhost:5003/health   # fornecimentos-service
curl http://localhost:5004/health   # demanda-service
curl http://localhost:5005/health   # mercado-service
curl http://localhost:5006/health   # negociacao-service
curl http://localhost:5007/health   # pedidos-service
curl http://localhost:5008/health   # logistica-service
```

**Tabela de portas oficiais:**

| Serviço | Porta |
|---|---|
| usuarios-service | 5001 |
| produtos-service | 5002 |
| fornecimentos-service | 5003 |
| demanda-service | 5004 |
| mercado-service | 5005 |
| negociacao-service | 5006 |
| pedidos-service | 5007 |
| logistica-service | 5008 |

---

## 10. Testar fronts publicados

```bash
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/demandas/
curl -I http://34.8.17.245/logistica/
curl -I http://34.8.17.245/pgadmin/
```

**Acessos dos fronts:**

| Front | URL |
|---|---|
| Portal principal | http://34.8.17.245/ |
| Produtos | http://34.8.17.245/produtos/ |
| Demandas / Pedidos (unificados) | http://34.8.17.245/demandas/ |
| Logística | http://34.8.17.245/logistica/ |
| PgAdmin | http://34.8.17.245/pgadmin/ |

---

## 11. Testar fronts direto nas VMs

**VM principal:**

```bash
curl -I http://34.29.84.207:8082   # portal-front
curl -I http://34.29.84.207:8081   # produtos-front
curl -I http://34.29.84.207:8084   # demandas-front
curl -I http://34.29.84.207:8088   # logistica-front
```

**VM standby:**

```bash
curl -I http://34.59.229.37:8082   # portal-front
curl -I http://34.59.229.37:8081   # produtos-front
curl -I http://34.59.229.37:8084   # demandas-front
curl -I http://34.59.229.37:8088   # logistica-front
```

**Tabela de portas dos fronts:**

| Front | Porta |
|---|---|
| portal-front | 8082 |
| produtos-front | 8081 |
| demandas-front (unificado) | 8084 |
| logistica-front | 8088 |

---

## 12. Ver containers rodando

```bash
# Todos os containers em execução
docker ps

# Filtrar por serviço
docker ps | grep usuarios
docker ps | grep produtos
docker ps | grep logistica
docker ps | grep redpanda
docker ps | grep nginx
docker ps | grep pgadmin

# Todos, inclusive parados
docker ps -a
```

---

## 13. Ver logs de containers

```bash
docker logs --tail=100 usuarios-service
docker logs --tail=100 produtos-service
docker logs --tail=100 logistica-service
docker logs --tail=100 logistica-front
docker logs --tail=100 portal-front
docker logs --tail=100 portal-b2b-nginx-gateway
docker logs --tail=100 portal-b2b-redpanda
```

**Logs em tempo real (follow):**

```bash
docker logs -f nome-do-container
```

---

## 14. Reiniciar containers específicos

```bash
docker restart portal-b2b-nginx-gateway
docker restart portal-b2b-redpanda
docker restart usuarios-service
docker restart produtos-service
docker restart logistica-service
docker restart logistica-front
```

---

## 15. Recriar Nginx Gateway após alteração no nginx.conf

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

docker compose up -d --force-recreate nginx-gateway
```

**Validar após recriar:**

```bash
docker exec portal-b2b-nginx-gateway nginx -t
docker exec portal-b2b-nginx-gateway nginx -T | grep -A10 "location /logistica"
```

---

## 16. Validar configuração do Nginx em execução

```bash
# Testar configuração (sintaxe)
docker exec portal-b2b-nginx-gateway nginx -t

# Ver configuração completa carregada
docker exec portal-b2b-nginx-gateway nginx -T
```

**Buscar rota específica:**

```bash
docker exec portal-b2b-nginx-gateway nginx -T | grep -A10 "location /api/logistica"
docker exec portal-b2b-nginx-gateway nginx -T | grep -A10 "location /logistica"
docker exec portal-b2b-nginx-gateway nginx -T | grep -A10 "location /produtos"
docker exec portal-b2b-nginx-gateway nginx -T | grep -A10 "location /api/usuarios"
```

---

## 17. Testar VM standby via SSH

**Verificar se a standby está acessível:**

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37 "hostname && date"
```

**Entrar na standby:**

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37
```

**Executar comando remoto:**

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37 '
cd /opt/portal-b2b/infra/portal-b2b-infra
docker ps
'
```

---

## 18. Testar serviços na standby

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37 '
curl http://localhost/health
curl http://localhost/api/usuarios/health
curl http://localhost/api/produtos/health
curl http://localhost/api/logistica/health
'
```

---

## 19. Recriar Nginx Gateway na standby

```bash
ssh -i ~/.ssh/portal_b2b_standby sergiofilho_almeida@34.59.229.37 '
cd /opt/portal-b2b/infra/portal-b2b-infra
docker compose up -d --force-recreate nginx-gateway
'
```

---

## 20. Ver restart policy dos containers

```bash
docker inspect portal-b2b-redpanda --format '{{.HostConfig.RestartPolicy.Name}}'
docker inspect portal-b2b-nginx-gateway --format '{{.HostConfig.RestartPolicy.Name}}'
docker inspect usuarios-service --format '{{.HostConfig.RestartPolicy.Name}}'
docker inspect logistica-service --format '{{.HostConfig.RestartPolicy.Name}}'
```

> O valor esperado para todos é: `unless-stopped`

---

## 21. Redpanda / Kafka (Cluster)

**Ver status do broker nesta VM:**

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra/redpanda
docker compose --env-file .env -f docker-compose.cluster.yml ps
docker logs --tail=100 portal-b2b-redpanda
```

**Health do Cluster:**

```bash
export KAFKA_BOOTSTRAP_SERVERS=10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/check-kafka-cluster.sh
```

**Listar tópicos no cluster:**

```bash
# Usando rpk (se disponível na VM)
rpk cluster info --brokers 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
rpk topic list --brokers 10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092
```

**Recriar Broker nesta VM:**

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra/redpanda
docker compose --env-file .env -f docker-compose.cluster.yml up -d --force-recreate
```

---

## 22. Kafka UI

**Acesso direto:**

```text
http://34.29.84.207:8080
```

**Testar:**

```bash
curl -I http://34.29.84.207:8080
```

---

## 23. PgAdmin

**Acesso oficial:**

```text
http://34.8.17.245/pgadmin/
```

**Testar:**

```bash
curl -I http://34.8.17.245/pgadmin/
```

> Comportamento esperado: HTTP 302 redirecionando para `/pgadmin/login`.

---

## 24. Cloud SQL

**Banco oficial:**

| Item | Valor |
|---|---|
| Host | 136.114.235.212 |
| Porta | 5432 |
| Database | portal_b2b |
| Schema | portal_b2b |
| Usuário (app) | svc_portal_b2b |
| Usuário (DDL) | db_portal_b2b |

**Testar com psql:**

```bash
export SVC_PASSWORD="senha_portal_b2b"

PGPASSWORD="$SVC_PASSWORD" psql \
  -h 136.114.235.212 \
  -U svc_portal_b2b \
  -d portal_b2b \
  -c "SELECT * FROM portal_b2b.health_check;"
```

---

## 25. Ver se PostgreSQL local está removido

```bash
docker ps | grep postgres || echo "PostgreSQL local não está rodando"
```

> O PostgreSQL local foi removido da infraestrutura. O banco oficial é exclusivamente o Cloud SQL.

---

## 26. Testar Load Balancer no GCP

**No Cloud Shell do GCP:**

```bash
gcloud compute backend-services get-health portal-b2b-backend-service --global
```

---

## 27. Ver IPs das VMs no GCP

**No Cloud Shell do GCP:**

```bash
# VM principal
gcloud compute instances describe portal-b2b-vm \
  --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"

# VM standby
gcloud compute instances describe portal-b2b-vm-standby \
  --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

---

## 28. Ver se a standby está ligada

**No Cloud Shell do GCP:**

```bash
gcloud compute instances describe portal-b2b-vm-standby \
  --zone=us-central1-a \
  --format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP)"
```

**Ligar a standby se estiver desligada:**

```bash
gcloud compute instances start portal-b2b-vm-standby --zone=us-central1-a
```

---

## 29. Validar serviços principais de uma vez

```bash
curl http://34.8.17.245/health
curl http://34.8.17.245/api/usuarios/health
curl http://34.8.17.245/api/produtos/health
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/
curl -I http://34.8.17.245/produtos/
curl -I http://34.8.17.245/logistica/
curl -I http://34.8.17.245/pgadmin/
```

---

## 30. Checklist após deploy de microsserviço

- [ ] O deploy terminou sem erro?
- [ ] O container aparece no `docker ps`?
- [ ] O `/health` direto na porta responde?
- [ ] O `/api/{dominio}/health` pelo Gateway local responde?
- [ ] O `/api/{dominio}/health` pelo Load Balancer responde?
- [ ] O mesmo serviço subiu na standby?
- [ ] O Load Balancer continua saudável?
- [ ] Os logs não mostram erro crítico?

---

## 31. Comandos específicos já usados no projeto

**Deploy usuarios-service:**

```bash
bash scripts/deploy-service-redundant.sh usuarios-service https://github.com/guilherme-cognitiva/autenticacao-b2b.git
```

**Deploy logistica-service:**

```bash
bash scripts/deploy-service-redundant.sh logistica-service https://github.com/faculdade-sistemas-distribuidos/b2b_logistica.git
```

**Testar usuarios:**

```bash
curl http://34.8.17.245/api/usuarios/health
```

**Testar logística:**

```bash
curl http://34.8.17.245/api/logistica/health
curl -I http://34.8.17.245/logistica/
```

**Testar produtos:**

```bash
curl http://34.8.17.245/api/produtos/health
curl -I http://34.8.17.245/produtos/
```

---

## 32. Observações importantes

- **Não instalar dependências manualmente na VM.** Não rodar `npm install`, `pip install`, `dotnet restore` etc. fora do Docker.
- **Cada equipe deve corrigir seu próprio repositório.** A infraestrutura só executa o deploy a partir do Git.
- **Não usar o IP da VM principal como endpoint oficial.** O endpoint oficial é o Load Balancer (`34.8.17.245`).
- **O banco oficial é o Cloud SQL** (`136.114.235.212:5432`). O PostgreSQL local foi removido.
- **O Kafka/Redpanda opera em cluster** de 3 brokers replicados. O bootstrap oficial é `10.128.0.2:9092,10.128.0.3:9092,10.128.0.4:9092`.
- **A standby deve ser sincronizada após qualquer alteração de infra** (`bash scripts/sync-redundant.sh`).
- **Alterações em `nginx/nginx.conf` exigem recriar o `nginx-gateway` nas duas VMs** (seções 15 e 19).
- A chave SSH `~/.ssh/portal_b2b_standby` existe apenas na VM principal e **nunca deve ser versionada no Git**.
