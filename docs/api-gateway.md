# API Gateway

## O Papel do Gateway
O API Gateway funciona como ponto único de entrada (Porta `80`) para todas as APIs REST dos microsserviços. O Nginx atua como proxy reverso, recebendo requisições externas e encaminhando-as para o serviço adequado.

## Rotas e Remoção de Prefixo

A configuração atual do Nginx mapeia os caminhos usando o padrão `/api/{dominio}/`.
**Importante:** Graças à barra final (`/`) na diretiva `proxy_pass`, o prefixo da rota é removido antes de ser repassado ao microsserviço.

Este é o **padrão oficial**:
- Gateway expõe: `/api/{dominio}/...`
- Microsserviço recebe a rota **sem** o prefixo `/api/{dominio}`.

**Exemplos:**
- `GET /api/produtos/health` -> `produtos-service` recebe `GET /health`
- `GET /api/demandas/health` -> `demanda-service` recebe `GET /health`

## Cenários de Comunicação (host.docker.internal vs IPs Privados)

### Cenário A: Infraestrutura e Microsserviços na Mesma Máquina/VM
O arquivo `nginx.conf` padrão utiliza `host.docker.internal`. Isso significa que o Nginx tentará encontrar o serviço na **máquina hospedeira** onde o Docker está rodando. Se o colega subir a infraestrutura localmente e o seu microsserviço também localmente, as rotas funcionarão imediatamente.

### Cenário B: Infra na VM Central e Microsserviços nas Máquinas dos Colegas (Tailscale/ZeroTier)
Quando a infraestrutura roda de forma centralizada e cada equipe roda seu próprio código no seu computador via uma rede privada (VPN como Tailscale ou ZeroTier), o `host.docker.internal` **não vai encontrar** o microsserviço (porque ele não está na VM central, está no PC do colega).

Nesse caso, o responsável pela infraestrutura precisará editar o `nginx/nginx.conf` substituindo `host.docker.internal` pelo IP privado do desenvolvedor responsável. 

Exemplo de adaptação no `nginx.conf`:
```nginx
location /api/produtos/ {
    # Apontando para o IP da máquina do colega de Produtos na VPN
    proxy_pass http://100.100.10.2:5002/;
}

location /api/demandas/ {
    # Apontando para o IP da máquina do colega de Demandas na VPN
    proxy_pass http://100.100.20.5:5004/;
}
```
Após as edições, basta recarregar as configurações: `docker compose restart nginx-gateway`.
