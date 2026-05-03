# Conexão das Equipes

Esta documentação explica como as equipes devem conectar seus microsserviços à infraestrutura centralizada.

| Equipe | Serviço | Porta | Schema | Usuário DB | Eventos publicados |
|--------|---------|-------|--------|------------|--------------------|
| Usuários | usuarios-service | 5001 | schema_usuarios | svc_usuarios | empresa_cadastrada |
| Produtos | produtos-service | 5002 | schema_produtos | svc_produtos | produto_cadastrado |
| Fornecimentos | fornecimentos-service | 5003 | schema_fornecimentos | svc_fornecimentos | fornecimento_criado, estoque_atualizado |
| Demanda | demanda-service | 5004 | schema_demanda | svc_demanda | demanda_criada, demanda_recorrente_gerada |
| Mercado | mercado-service | 5005 | schema_mercado | svc_mercado | modo_negociacao_definido, leilao_iniciado |
| Negociação | negociacao-service | 5006 | schema_negociacao | svc_negociacao | lance_realizado, negociacao_fechada |
| Pedidos | pedidos-service | 5007 | schema_pedidos | svc_pedidos | pedido_criado, pedido_atualizado |
| Logística | logistica-service | 5008 | schema_logistica | svc_logistica | solicitacao_frete_criada, frete_selecionado |
| Transportadoras | transportadoras-service | 5009 | schema_transportadoras | svc_transportadoras | cotacao_frete_enviada |

## Conectando ao Banco (PostgreSQL) e Kafka

Cada equipe acessa os recursos com usuários estritos, garantindo que não consultem o schema do vizinho. 

**Como testar o Gateway localmente:** 
O Gateway rodará na VM/localhost na porta 80 e encaminhará requisições para os microsserviços no `host.docker.internal` (ex: porta 5002 para produtos). Basta que seu microsserviço esteja rodando e não bloqueado pelo firewall local.

## Exemplos de Arquivos `.env`

**Importante:** `IP_DA_VM` deve ser substituído pelo IP da VM central ou pelo IP da rede privada (ex: IP do Tailscale/ZeroTier). Se estiver rodando a infraestrutura no seu próprio PC para testes, use `localhost`.

### usuarios-service:
```env
DATABASE_URL=postgresql://svc_usuarios:senha_usuarios@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_usuarios
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=usuarios-service
PORT=5001
```

### produtos-service:
```env
DATABASE_URL=postgresql://svc_produtos:senha_produtos@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_produtos
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=produtos-service
PORT=5002
```

### fornecimentos-service:
```env
DATABASE_URL=postgresql://svc_fornecimentos:senha_fornecimentos@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_fornecimentos
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=fornecimentos-service
PORT=5003
```

### demanda-service:
```env
DATABASE_URL=postgresql://svc_demanda:senha_demanda@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_demanda
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=demanda-service
PORT=5004
```

### mercado-service:
```env
DATABASE_URL=postgresql://svc_mercado:senha_mercado@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_mercado
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=mercado-service
PORT=5005
```

### negociacao-service:
```env
DATABASE_URL=postgresql://svc_negociacao:senha_negociacao@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_negociacao
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=negociacao-service
PORT=5006
```

### pedidos-service:
```env
DATABASE_URL=postgresql://svc_pedidos:senha_pedidos@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_pedidos
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=pedidos-service
PORT=5007
```

### logistica-service:
```env
DATABASE_URL=postgresql://svc_logistica:senha_logistica@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_logistica
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=logistica-service
PORT=5008
```

### transportadoras-service:
```env
DATABASE_URL=postgresql://svc_transportadoras:senha_transportadoras@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_transportadoras
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
SERVICE_NAME=transportadoras-service
PORT=5009
```
