# Variáveis de Ambiente Padrão

Todo microsserviço no Portal B2B deve padronizar as seguintes variáveis de ambiente:

- `DATABASE_URL`: String de conexão com o banco de dados.
- `DB_SCHEMA`: Nome do schema isolado para o serviço.
- `KAFKA_BOOTSTRAP_SERVERS`: Endereço de conexão com o broker Kafka.
- `SERVICE_NAME`: Nome identificador do microsserviço.
- `PORT`: Porta em que a aplicação vai escutar.

## Exemplo de configuração (Python/SQLAlchemy)

Explique como configurar SQLAlchemy com search_path:

```python
from sqlalchemy import create_engine

engine = create_engine(
    DATABASE_URL,
    connect_args={
        "options": f"-csearch_path={DB_SCHEMA}"
    }
)
```
