# Guia de Integração para as Equipes

Bem-vindos! Este documento foi feito para você, desenvolvedor(a) de um dos microsserviços do **Portal B2B Distribuído**.

A infraestrutura (banco de dados central, mensageria Kafka e o API Gateway) já está pronta. O seu trabalho não é mexer na infraestrutura, mas sim **conectar o seu microsserviço a ela**.

Siga este passo a passo para integrar a sua parte do projeto sem dores de cabeça.

---

## 1. Onde está rodando a Infraestrutura?

O ambiente oficial do projeto funciona com **todos os serviços e a infraestrutura rodando na mesma VM da Turma**.
Você conectará usando o IP dessa máquina (ex: `IP_DA_VM`) quando estiver desenvolvendo na sua máquina, ou usará `localhost`/`0.0.0.0` quando for subir o seu serviço definitivamente na VM.

> **Atenção:** Em todas as variáveis de ambiente abaixo, substitua `IP_DA_VM` pelo IP real onde a infraestrutura está hospedada.

---

## 2. Configurando o seu Banco de Dados

O projeto usa um **Banco de Dados Centralizado**. Todas as equipes compartilham o banco `portal_b2b` e o schema `portal_b2b`.

A equipe de banco de dados é responsável pela estruturação. O seu papel como desenvolvedor de microsserviço é conectar-se ao banco com o usuário da aplicação e consumir ou gravar dados, respeitando o isolamento lógico das tabelas do seu domínio.

**Usuário da Aplicação (Comum a todos os microsserviços):**
- **Usuário DB:** `svc_portal_b2b`
- **Senha DB:** `senha_portal_b2b`

### Exemplo de `.env` que você deve usar na sua aplicação:

```env
# Porta em que o SEU microsserviço vai rodar
PORT=5002

# Nome do seu serviço
SERVICE_NAME=produtos-service

# Banco de dados
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@IP_DA_VM:5432/portal_b2b
DB_SCHEMA=portal_b2b

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

O Gateway roda na **Porta 80**. O mapeamento já foi feito e roteará para a porta oficial de cada serviço na VM.

**Atenção ao Mapeamento (Remoção do Prefixo):**
O Nginx está configurado para **remover o prefixo** `/api/{dominio}/` quando envia a requisição para você.

**Este é o padrão oficial:**
- Cliente chama o Gateway: `GET /api/produtos/health`
- O `produtos-service` recebe: `GET /health`

Portanto, o seu microsserviço **não deve** incluir `/api/...` nas rotas internas dele. Ele deve expor apenas as rotas diretas (ex: `/health`, `/listar`, `/criar`), e o Nginx fará a tradução.

**IMPORTANTE:** Para que o Gateway consiga alcançar o seu microsserviço na VM, você deve executá-lo escutando em todos os IPs (ex: `0.0.0.0`).

---

## 5. Visualizando seus Dados (PgAdmin e Clientes Externos)

Você pode acessar o banco de dados visualmente para debugar sua aplicação pelo **PgAdmin** que já vem junto com a infra:
- **Acesso:** `http://IP_DA_VM:5050`
- **Login:** `admin@portalb2b.com`
- **Senha:** `admin`

Para adicionar o banco de dados **dentro da interface web do PgAdmin**:
- **Host:** `postgres` *(Atenção: como o PgAdmin roda dentro do Docker, ele enxerga o banco pelo nome interno do container)*
- **Port:** `5432`
- **User / Password:** `db_portal_b2b` e `senha_db_portal_b2b` (ou `svc_portal_b2b` se quiser ver com a visão da aplicação).
- **Database:** `portal_b2b`

**Se for usar o DBeaver, DataGrip ou `psql` direto no seu computador:**
Neste caso, a sua ferramenta está fora do Docker, então o host será o IP da máquina central:
- **Host:** `IP_DA_VM`
- **Port:** `5432`
- **User / Password:** `db_portal_b2b` ou `svc_portal_b2b`
- **Database:** `portal_b2b`

---

## Dúvidas?
Se algo na conexão do banco ou do Kafka não funcionar:
1. Revise se você preencheu o `IP_DA_VM` e as credenciais (`svc_portal_b2b`) corretamente no seu `.env`.
2. Você só tem permissão de DML (Manipulação de Dados). Se a sua aplicação (ORM) tentar criar ou alterar tabelas (ex: `sync()`, `auto_migrate`), dará erro de permissão negada. A estruturação do banco é dever da equipe de Banco de Dados.
3. Caso a infra caia, acione o responsável pela VM central.
