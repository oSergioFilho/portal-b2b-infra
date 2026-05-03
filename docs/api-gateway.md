# API Gateway

## O Papel do Gateway
O API Gateway funciona como ponto único de entrada (Porta `80`) para todas as APIs REST dos microsserviços. O Nginx atua como proxy reverso, recebendo requisições externas e encaminhando-as para o serviço adequado em `host.docker.internal`.

## Rotas
A rota base indica para qual microsserviço a requisição será direcionada:

- `/api/usuarios/` -> Redireciona para porta `5001`
- `/api/produtos/` -> Redireciona para porta `5002`
- `/api/fornecimentos/` -> Redireciona para porta `5003`
- `/api/demandas/` -> Redireciona para porta `5004`
- `/api/mercado/` -> Redireciona para porta `5005`
- `/api/negociacoes/` -> Redireciona para porta `5006`
- `/api/pedidos/` -> Redireciona para porta `5007`
- `/api/logistica/` -> Redireciona para porta `5008`
- `/api/transportadoras/` -> Redireciona para porta `5009`

**Importante:** A rota só funcionará quando o microsserviço correspondente estiver rodando na sua porta oficial no host onde a infraestrutura está executando.
