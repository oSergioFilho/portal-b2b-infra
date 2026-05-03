# Guia de Integração para as Equipes

Bem-vindos! Este documento foi feito para você, desenvolvedor(a) de um dos microsserviços do **Portal B2B Distribuído**.

A infraestrutura (banco de dados central, mensageria Kafka e o API Gateway) já está pronta. O seu trabalho não é mexer na infraestrutura, mas sim **conectar o seu microsserviço a ela**.

Siga este passo a passo para integrar a sua parte do projeto sem dores de cabeça.

---

## 1. Onde está rodando a Infraestrutura?

Você tem dois cenários:
- **Testes Iniciais (Localhost):** O líder de infraestrutura do seu grupo de testes sobe a infra no próprio PC dele. Você conectará usando `localhost` (ou o IP da rede local dele).
- **Ambiente Oficial (VM da Turma):** A infraestrutura estará rodando num servidor central. Você conectará usando o IP dessa máquina (ex: via Tailscale/ZeroTier). 

> **Atenção:** Em todas as variáveis de ambiente abaixo, substitua `IP_DA_VM` pelo IP real onde a infraestrutura está hospedada (ou `localhost` se for na sua própria máquina).

---

## 2. Configurando o seu Banco de Dados

O projeto usa o padrão *"Database per Service"*, mas para facilitar o ambiente acadêmico, usamos um **único PostgreSQL físico** separado logicamente por **Schemas**.

**Regra de Ouro:** Você só tem permissão para ler e escrever no seu próprio Schema. Não tente fazer `SELECT` nas tabelas de outros grupos! Se precisar de dados deles, consuma via API ou Eventos Kafka.

Descubra o seu acesso na tabela abaixo e configure no seu `.env`:

| Equipe | Serviço | Porta REST | Schema Reservado | Usuário DB | Senha DB |
|--------|---------|------------|------------------|------------|----------|
| **Usuários** | `usuarios-service` | 5001 | `schema_usuarios` | `svc_usuarios` | `senha_usuarios` |
| **Produtos** | `produtos-service` | 5002 | `schema_produtos` | `svc_produtos` | `senha_produtos` |
| **Fornecimentos** | `fornecimentos-service` | 5003 | `schema_fornecimentos` | `svc_fornecimentos` | `senha_fornecimentos` |
| **Demanda** | `demanda-service` | 5004 | `schema_demanda` | `svc_demanda` | `senha_demanda` |
| **Mercado** | `mercado-service` | 5005 | `schema_mercado` | `svc_mercado` | `senha_mercado` |
| **Negociação** | `negociacao-service` | 5006 | `schema_negociacao` | `svc_negociacao` | `senha_negociacao` |
| **Pedidos** | `pedidos-service` | 5007 | `schema_pedidos` | `svc_pedidos` | `senha_pedidos` |
| **Logística** | `logistica-service` | 5008 | `schema_logistica` | `svc_logistica` | `senha_logistica` |
| **Transportadoras** | `transportadoras-service` | 5009 | `schema_transportadoras` | `svc_transportadoras` | `senha_transportadoras` |

### Exemplo de `.env` que você deve usar na sua aplicação:
*(Exemplo focado na equipe de Produtos)*
```env
# Porta em que o SEU microsserviço vai rodar (veja a tabela acima)
PORT=5002

# Nome do seu serviço
SERVICE_NAME=produtos-service

# Banco de dados
DATABASE_URL=postgresql://svc_produtos:senha_produtos@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=schema_produtos

# Kafka
KAFKA_BOOTSTRAP_SERVERS=IP_DA_VM:9092
```

---

## 3. Mensageria (Kafka / Redpanda)

Toda a comunicação *assíncrona* entre os grupos deve ser feita pelo Kafka.
Você pode monitorar as mensagens que chegam acessando o **Kafka UI** pelo navegador em: `http://IP_DA_VM:8080`.

**Regras para o Kafka:**
1. O tópico do Kafka tem o **mesmo nome** do evento (ex: `produto_cadastrado`).
2. O corpo do evento (JSON) precisa seguir exatamente o nosso contrato padrão.

### Contrato Padrão do JSON
Todos os eventos publicados por vocês devem respeitar esse envelope:
```json
{
  "eventId": "gerar-um-uuid-unico-aqui",
  "eventType": "produto_cadastrado",
  "eventVersion": "1.0",
  "timestamp": "2026-05-03T10:00:00Z",
  "source": "produtos-service",
  "correlationId": "uuid-da-jornada-do-usuario",
  "payload": {
    // AQUI DENTRO VAI O SEU DADO ESPECÍFICO (Regra de negócio)
    "idProduto": 1,
    "nome": "Arroz 5kg"
  }
}
```

> **Consulte a documentação completa dos eventos e quem consome o quê no arquivo:** [`docs/eventos-kafka.md`](docs/eventos-kafka.md).

---

## 4. API Gateway e Comunicação Síncrona

Se o Frontend for chamar o seu serviço, ou se outro grupo precisar de um dado de forma imediata (síncrona), eles não baterão direto na sua porta 5002 ou 5004. Eles baterão no **API Gateway**.

O Gateway roda na **Porta 80**. O mapeamento já foi feito:

- `/api/usuarios/` -> Roteia para quem estiver rodando na porta 5001.
- `/api/produtos/` -> Roteia para quem estiver rodando na porta 5002.
- `/api/fornecimentos/` -> Roteia para quem estiver rodando na porta 5003.
- *(E assim por diante, veja a tabela de portas)*.

**O que você precisa fazer?**
Nada de especial! Apenas garanta que a API REST do seu microsserviço comece sempre pelo `/api/...` correspondente e rode na porta listada na tabela do passo 2. O Nginx fará a mágica de pegar a requisição do usuário na porta 80 e enviar pra você!

---

## 5. Visualizando seus Dados (PgAdmin)

Você pode acessar o banco de dados visualmente para debugar sua aplicação pelo **PgAdmin**:
- **Acesso:** `http://IP_DA_VM:5050`
- **Login:** `admin@portalb2b.com`
- **Senha:** `admin`

Para adicionar o banco de dados dentro do PgAdmin:
- **Host:** `IP_DA_VM` (ou `postgres` se estiver rodando local no seu PC via docker compose)
- **Port:** `5432`
- **User / Password:** O usuário e a senha do **seu** grupo (ex: `svc_produtos` / `senha_produtos`).
- **Database:** `portal_b2b`

---

## Dúvidas?
Se algo na conexão do banco ou do Kafka não funcionar:
1. Revise se você preencheu o `IP_DA_VM` corretamente no seu `.env`.
2. Lembre-se que você só pode criar tabelas dentro do seu próprio `schema_...`. Se tentar criar tabelas no schema padrão do Postgres (`public`), dará erro de permissão negada. Configure seu ORM (Sequelize, Prisma, TypeORM, SQLAlchemy) para usar o schema definido!
3. Caso a infra caia, acione o administrador de infraestrutura do seu grupo.
