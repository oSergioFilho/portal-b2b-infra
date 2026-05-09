# Banco de Dados

## Regras e Arquitetura

1. O banco de dados (`portal_b2b`) é **centralizado**.
2. Existe um **schema único** chamado `portal_b2b` que todas as equipes utilizarão.
3. Existem duas credenciais separadas por responsabilidade:
   - **`db_portal_b2b`**: Usuário exclusivo da equipe de Banco de Dados. Responsável por DDL (Data Definition Language). Cria e altera tabelas, relacionamentos, constraints, etc.
   - **`svc_portal_b2b`**: Usuário para os Microsserviços. Responsável por DML (Data Manipulation Language). Apenas lê, insere, atualiza e exclui dados das tabelas, mas não altera a estrutura do banco.

Embora todos os serviços usem o mesmo schema e o mesmo banco, a separação de responsabilidades e o isolamento de domínio devem ser respeitados logicamente (e não mais fisicamente com schemas isolados).

## Alinhamento e Organização

Como todos usam o mesmo schema, deve haver alinhamento rigoroso na nomenclatura das tabelas para evitar conflitos. A recomendação é o uso de prefixos por domínio.

### Sugestão de Nomes de Tabelas por Domínio:

- **Usuários:** `usuarios_empresa`, `usuarios_perfil`, `usuarios_empresa_perfil`, `usuarios_endereco`
- **Produtos:** `produtos_produto`, `produtos_categoria`, `produtos_unidade_medida`
- **Fornecimentos:** `fornecimentos_fornecimento`, `fornecimentos_estoque`
- **Demanda:** `demanda_demanda`, `demanda_recorrencia`
- **Mercado:** `mercado_processo_negociacao`, `mercado_modo_negociacao`
- **Negociação:** `negociacao_lance`, `negociacao_resultado`
- **Pedidos:** `pedidos_pedido`, `pedidos_item_pedido`
- **Logística:** `logistica_solicitacao_frete`, `logistica_frete_selecionado`
- **Transportadoras:** `transportadoras_cotacao_frete`, `transportadoras_area_atuacao`

Esta organização permite que o banco permaneça estruturado em um modelo único sem que tabelas de domínios diferentes se misturem.

## Acesso da equipe de banco

A equipe de banco utiliza o usuário administrador do schema para gerenciar a estrutura das tabelas.

O banco oficial é o **Cloud SQL PostgreSQL**:

- **Host:** `136.114.235.212`
- **Porta:** `5432`
- **Banco:** `portal_b2b`
- **Schema:** `portal_b2b`
- **Usuário:** `db_portal_b2b`
- **Senha:** `***` *(fornecida pela equipe de infraestrutura)*

*A equipe pode usar o PgAdmin disponibilizado pela infraestrutura ou uma ferramenta local conectando no IP do Cloud SQL.*

## Acesso dos microsserviços

As equipes de desenvolvimento dos microsserviços configuram suas aplicações para conectar usando o usuário de aplicação:

```env
DATABASE_URL=postgresql://svc_portal_b2b:***@136.114.235.212:5432/portal_b2b
DB_SCHEMA=portal_b2b
```

> **Nota:** O banco oficial é exclusivamente o Cloud SQL PostgreSQL em `136.114.235.212`. Não há PostgreSQL local no Docker Compose.
