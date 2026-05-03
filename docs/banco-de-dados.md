# Banco de Dados

## Regras e Arquitetura

1. O PostgreSQL é **centralizado fisicamente** (uma única instância Docker).
2. Cada microsserviço tem **schema próprio**.
3. Cada microsserviço tem **usuário próprio**.
4. Nenhum serviço deve acessar diretamente o schema de outro serviço (permissões limitadas em nível de banco).
5. Quando um serviço precisar de informação de outro domínio, deve usar **API REST ou eventos Kafka**.
6. Essa abordagem preserva o isolamento lógico em um ambiente acadêmico, simulando o modelo "database per service".

## Por que um serviço não pode acessar o schema de outro?

- **Acoplamento forte:** Se `pedidos-service` fizer um `SELECT` direto na tabela do `produtos-service`, qualquer mudança na tabela de produtos quebrará o sistema de pedidos.
- **Dona do domínio:** O serviço de produtos é o único responsável por ditar como os produtos são armazenados.
- **Escalabilidade:** Em um cenário real, o banco de produtos poderia estar em um servidor diferente ou usar um banco NoSQL. O acesso direto impede essa evolução.
- **Contrato claro:** A comunicação via APIs REST ou Kafka garante que apenas informações públicas e validadas sejam compartilhadas entre os domínios.

## O que NÃO PODE acontecer (Anti-patterns)

- **Consultas cruzadas:** `pedidos-service` fazendo um `SELECT` direto em `schema_fornecimentos` ou `demanda-service` acessando a tabela de produtos diretamente.
- **Credenciais globais:** Um serviço utilizando o usuário administrador `postgres` ou todos os serviços usando a mesma senha no `DATABASE_URL`.

## Estrutura de Schemas

```text
PostgreSQL Central
│
├── schema_usuarios
├── schema_produtos
├── schema_fornecimentos
├── schema_demanda
├── schema_mercado
├── schema_negociacao
├── schema_pedidos
├── schema_logistica
└── schema_transportadoras
```
