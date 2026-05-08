# Guia de Configuração das VMs de Aplicação

Este guia descreve o passo a passo para subir e configurar a infraestrutura central do Portal B2B na Máquina Virtual (VM) principal.

## VM atual no GCP

Deve ficar claro:

- Acesso oficial: http://34.8.17.245
- VM principal: http://34.29.84.207 apenas diagnóstico
- VM standby: http://104.197.23.241 apenas diagnóstico
- Cloud SQL: 136.114.235.212
- PgAdmin/Kafka UI podem continuar por IP direto das VMs

> **Observação importante:** No arquivo `.env` da VM, a variável `REDPANDA_EXTERNAL_HOST` deve estar configurada como:
> - Na VM principal: `REDPANDA_EXTERNAL_HOST=34.29.84.207`
> - Na VM standby: `REDPANDA_EXTERNAL_HOST=104.197.23.241`
> Não colocar isso no `.env.example`.

## Passo a Passo

### 1. Acesso à VM
Acesse a VM via SSH:
```bash
ssh usuario@34.29.84.207
```

### 2. Instalação do Docker e Docker Compose
Certifique-se de que o Docker está instalado. Para distribuições baseadas em Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
```
Configure o Docker para rodar sem `sudo` (opcional, mas recomendado):
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Clonar o Repositório
Clone este repositório de infraestrutura na VM:
```bash
git clone https://github.com/oSergioFilho/portal-b2b-infra.git
cd portal-b2b-infra
```

### 4. Configurar as Variáveis de Ambiente
Copie o arquivo `.env.example` para `.env`:
```bash
cp .env.example .env
```
Edite o arquivo `.env` para ajustar o endereço do Redpanda e outras variáveis necessárias:
```bash
nano .env
```
Altere a linha:
```env
REDPANDA_EXTERNAL_HOST=localhost
```
Para:
```env
REDPANDA_EXTERNAL_HOST=34.29.84.207
```

### 5. Iniciar a Infraestrutura
Com as variáveis configuradas, inicie os containers em modo detached:
```bash
docker compose up -d
```

### 6. Verificar a Saúde da Infraestrutura
Rode o script de validação para garantir que os serviços principais estão operacionais e o banco de dados foi inicializado corretamente:
```bash
bash scripts/check-infra.sh
```

### 7. Acessar os Serviços Externamente
Você pode acessar os serviços da infraestrutura externamente:
- API Gateway oficial: http://34.8.17.245
- API Gateway VM principal, diagnóstico: http://34.29.84.207
- API Gateway VM standby, diagnóstico: http://104.197.23.241
- PgAdmin/Kafka UI podem continuar por IP direto das VMs

### 8. Conferir Logs e Status dos Containers
Para ver o status atual dos containers:
```bash
docker compose ps
```
Para acompanhar os logs de toda a infraestrutura em tempo real:
```bash
docker compose logs -f
```

## Como Subir um Microsserviço na VM

Os microsserviços devem ser executados na VM usando o Docker. O padrão oficial é Docker. Qualquer exemplo de rodar microsserviço direto com `uvicorn`, `npm` ou `java` (ex: `uvicorn main:app --host 0.0.0.0 --port 5002`) é **emergencial/não oficial**.

**Sincronizar infra nas duas VMs:**
```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/sync-redundant.sh
```

**Deploy redundante de microsserviço:**
```bash
cd /opt/portal-b2b/infra/portal-b2b-infra
bash scripts/deploy-service-redundant.sh nome-service URL_DO_REPOSITORIO
```

## Como Testar o Roteamento via API Gateway

Uma vez que o microsserviço está rodando, teste o acesso através do Gateway:
```bash
curl http://localhost/api/produtos/health
```
Para teste externo oficial, use http://34.8.17.245/api/produtos/health. Os IPs 34.29.84.207 e 104.197.23.241 são apenas diagnóstico direto.

## Checklist Final da VM
- [ ] PostgreSQL ativo (porta 5432)
- [ ] PgAdmin ativo (porta 5050)
- [ ] Redpanda ativo (porta 9092)
- [ ] Kafka UI ativo (porta 8080)
- [ ] API Gateway ativo (porta 80)
- [ ] Tópicos do Kafka criados e visíveis no Kafka UI
- [ ] Microsserviços executando em suas portas oficiais
