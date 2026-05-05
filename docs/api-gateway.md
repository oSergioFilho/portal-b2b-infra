# API Gateway

## O Papel do Gateway
O API Gateway funciona como ponto único de entrada (Porta `80`) para todas as APIs REST dos microsserviços do Portal B2B. O Nginx atua como proxy reverso, recebendo requisições externas e encaminhando-as para o serviço adequado rodando na VM.

## Padrão Oficial de Infraestrutura
O padrão definido para a arquitetura é:
- **Todos os microsserviços rodam na VM central.**
- O API Gateway Nginx roda em um container Docker na mesma VM.
- O Gateway acessa os microsserviços pela máquina host usando `host.docker.internal`.
- Cada serviço deve escutar em sua porta oficial.

## Rotas e Remoção de Prefixo

A configuração atual do Nginx mapeia os caminhos usando o padrão `/api/{dominio}/`.
**Importante:** Graças à barra final (`/`) na diretiva `proxy_pass`, o prefixo da rota é removido antes de ser repassado ao microsserviço.

Este é o **padrão oficial**:
- Gateway expõe: `/api/{dominio}/...`
- Microsserviço recebe a rota **sem** o prefixo `/api/{dominio}`.

**Exemplos de Roteamento:**
- `GET http://IP_DA_VM/api/produtos/health` -> `produtos-service` recebe `GET /health` na porta `5002`.
- `GET http://IP_DA_VM/api/pedidos/health` -> `pedidos-service` recebe `GET /health` na porta `5007`.

## Observações Futuras (Dockerização/VPNs)

**Containers no mesmo Docker Compose:**
Se futuramente os microsserviços forem containerizados dentro do mesmo Docker Compose (e não mais rodando via processo na VM), o `nginx.conf` poderá ser alterado para usar o nome dos containers na rede Docker, substituindo `host.docker.internal` por:
```nginx
proxy_pass http://produtos-service:5002/;
```
Mas nesta etapa atual, manteremos `host.docker.internal` porque os serviços podem rodar diretamente no host da VM.

**VPN (Tailscale/ZeroTier):**
A arquitetura anterior considerava cada desenvolvedor rodando seu microsserviço em sua própria máquina, conectados à VM através de VPN (Tailscale/ZeroTier). Esse modelo não é mais o padrão, mas se necessário academicamente, o `nginx.conf` precisaria ser alterado para apontar para o IP privado da VPN do desenvolvedor ao invés de `host.docker.internal`.
