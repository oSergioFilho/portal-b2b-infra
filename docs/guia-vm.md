# Guia de Configuração da Infraestrutura na VM

Este guia descreve o passo a passo para subir e configurar a infraestrutura central do Portal B2B na Máquina Virtual (VM) principal.

## VM atual no GCP

- IP público atual: 34.29.84.207
- API Gateway: http://34.29.84.207
- Health: http://34.29.84.207/health
- PgAdmin: http://34.29.84.207:5050
- Kafka UI: http://34.29.84.207:8080

> **Observação importante:** No arquivo `.env` da VM, a variável `REDPANDA_EXTERNAL_HOST` deve estar configurada como:
> ```env
> REDPANDA_EXTERNAL_HOST=34.29.84.207
> ```
> Atenção: isso deve ser feito no `.env` da VM, não no `.env.example`.

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
Você pode acessar os serviços da infraestrutura usando o IP da VM no navegador:
- **API Gateway:** `http://34.29.84.207`
- **PgAdmin:** `http://34.29.84.207:5050`
- **Kafka UI:** `http://34.29.84.207:8080`

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

Os microsserviços devem ser executados na mesma VM. A equipe responsável deve iniciar o serviço mapeando para a porta oficial definida.

Exemplo de execução de um serviço FastAPI (produtos-service na porta 5002):
```bash
uvicorn main:app --host 0.0.0.0 --port 5002
```

## Como Testar o Roteamento via API Gateway

Uma vez que o microsserviço está rodando, teste o acesso através do Gateway:
```bash
curl http://localhost/api/produtos/health
```
*(Substitua `localhost` por `34.29.84.207` se estiver testando fora da VM).*

## Checklist Final da VM
- [ ] PostgreSQL ativo (porta 5432)
- [ ] PgAdmin ativo (porta 5050)
- [ ] Redpanda ativo (porta 9092)
- [ ] Kafka UI ativo (porta 8080)
- [ ] API Gateway ativo (porta 80)
- [ ] Tópicos do Kafka criados e visíveis no Kafka UI
- [ ] Microsserviços executando em suas portas oficiais
