# Responsabilidades por Equipe

Para garantir que a arquitetura centralizada do Portal B2B funcione de forma limpa e organizada, as responsabilidades estão claramente divididas entre três perfis principais de equipes.

## 1. Equipe de Infraestrutura
Responsável por garantir que o ambiente base esteja operando de forma estável e segura para o desenvolvimento.

**Deveres:**
- Criar e gerenciar a VM (Máquina Virtual) central.
- Instalar e configurar o ambiente Docker e Docker Compose.
- Subir e manter operacionais os serviços centrais: PostgreSQL, PgAdmin, Redpanda/Kafka, Kafka UI e API Gateway.
- Configurar o schema geral do banco de dados (`portal_b2b`).
- Criar e gerenciar os usuários de acesso ao banco (`db_portal_b2b` e `svc_portal_b2b`).
- Criar os tópicos iniciais no Kafka.
- Documentar portas, endpoints de acesso e variáveis de ambiente padronizadas.
- Prestar suporte para ajudar as demais equipes a subirem seus serviços na VM e lidarem com gargalos de integração.

## 2. Equipe de Banco de Dados
Responsável pela estruturação e integridade dos dados no sistema centralizado.

**Deveres:**
- Conectar-se ao banco de dados com as credenciais administrativas (`db_portal_b2b`).
- Criar as tabelas necessárias no schema geral `portal_b2b`.
- Criar relacionamentos (chaves estrangeiras) e constraints (restrições) para garantir a integridade referencial.
- Manter scripts SQL de DDL versionados ou organizados.
- Manter o modelo físico do banco de dados (MER/DER) atualizado.
- **Alinhar nomes das tabelas:** Usar prefixos por domínio (ex: `produtos_categoria`, `pedidos_item_pedido`) para evitar conflitos no schema centralizado.
- Validar periodicamente a integridade do modelo.

## 3. Equipes de Microsserviços
Responsáveis pelas regras de negócios e desenvolvimento dos serviços isolados.

**Deveres:**
- Implementar as APIs baseadas nas especificações.
- Implementar todas as regras de negócio de seu domínio.
- Conectar ao banco de dados utilizando exclusivamente as credenciais de aplicação (`svc_portal_b2b`). **Não alterar estruturas de tabelas a partir da aplicação.**
- Publicar eventos no Kafka para operações assíncronas pertinentes.
- Consumir eventos no Kafka quando necessário para integrar com as operações de outros domínios.
- Fornecer e manter um endpoint de health check (`GET /health`).
- Manter a documentação da API em Swagger (OpenAPI) acessível.
- Rodar o serviço sempre na sua porta oficial acordada (ex: `5001`, `5002`) no ambiente da VM central.
