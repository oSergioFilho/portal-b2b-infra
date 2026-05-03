# Eventos Kafka

A comunicação assíncrona entre os domínios do Portal B2B ocorre via Kafka. Cada evento no barramento deve seguir um formato JSON padronizado.

## Padrão de Evento

Todos os eventos devem ter o seguinte formato de envelope (wrapper):

```json
{
  "eventId": "uuid",
  "eventType": "nome_do_evento",
  "eventVersion": "1.0",
  "timestamp": "ISO8601",
  "source": "nome-do-servico",
  "correlationId": "uuid",
  "payload": {}
}
```

- **Nome do tópico:** Deve ser igual ao `eventType`.
- **eventId:** Identifica exclusivamente o evento.
- **correlationId:** Ajuda a rastrear uma operação entre serviços.
- **source:** Identifica o serviço que publicou o evento.
- **payload:** Carrega os dados específicos do negócio.
- **Imutabilidade:** Eventos publicados não devem ser alterados.
- **Isolamento:** Cada serviço deve consumir apenas eventos relevantes para seu domínio.

## Tópicos e Serviços

- **usuarios-service** publica: `empresa_cadastrada`
- **produtos-service** publica: `produto_cadastrado`
- **fornecimentos-service** publica: `fornecimento_criado`, `estoque_atualizado`
- **demanda-service** publica: `demanda_criada`, `demanda_recorrente_gerada`
- **mercado-service** publica: `modo_negociacao_definido`, `leilao_iniciado`
- **negociacao-service** publica: `lance_realizado`, `negociacao_fechada`
- **pedidos-service** publica: `pedido_criado`, `pedido_atualizado`
- **logistica-service** publica: `solicitacao_frete_criada`, `frete_selecionado`
- **transportadoras-service** publica: `cotacao_frete_enviada`

## Exemplos JSON

### produto_cadastrado

```json
{
  "eventId": "uuid",
  "eventType": "produto_cadastrado",
  "eventVersion": "1.0",
  "timestamp": "2026-05-03T10:00:00Z",
  "source": "produtos-service",
  "correlationId": "uuid",
  "payload": {
    "idProduto": 1,
    "nome": "Arroz",
    "categoria": "Alimentos",
    "unidadeMedida": "kg",
    "tipoTransporte": "rodoviario"
  }
}
```

### demanda_criada

```json
{
  "eventId": "uuid",
  "eventType": "demanda_criada",
  "eventVersion": "1.0",
  "timestamp": "2026-05-03T10:05:00Z",
  "source": "demanda-service",
  "correlationId": "uuid",
  "payload": {
    "idDemanda": 1,
    "idEmpresaComprador": 10,
    "idProduto": 1,
    "quantidadeDesejada": 500,
    "tipoDemanda": "unica",
    "status": "aberta"
  }
}
```

### pedido_criado

```json
{
  "eventId": "uuid",
  "eventType": "pedido_criado",
  "eventVersion": "1.0",
  "timestamp": "2026-05-03T11:00:00Z",
  "source": "pedidos-service",
  "correlationId": "uuid",
  "payload": {
    "idPedido": 1,
    "idProduto": 1,
    "quantidade": 500,
    "valorTotal": 2900.00,
    "status": "criado"
  }
}
```
