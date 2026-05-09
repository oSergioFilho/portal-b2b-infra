# Migração do PostgreSQL Local para Cloud SQL

## 1. Status

> **Migração concluída.** O banco oficial do projeto agora é o Cloud SQL PostgreSQL em `136.114.235.212`.

## 2. Objetivo

Este documento descreve como foi feita a migração do banco PostgreSQL local da VM para a instância **Cloud SQL PostgreSQL** gerenciada pelo GCP.

A migração permite que o banco seja acessado por múltiplas VMs de aplicação, eliminando a dependência do PostgreSQL local e habilitando a arquitetura redundante.

---

## 3. Backup do banco local (referência histórica)

> **Nota:** Os comandos abaixo referem-se ao ambiente antigo antes da migração, quando o PostgreSQL rodava como container local. O PostgreSQL local foi removido da infraestrutura.

Antes da migração, foi gerado um dump completo do banco local:

```bash
cd /opt/portal-b2b/infra/portal-b2b-infra

docker compose exec -T postgres pg_dump \
  -U postgres \
  -d portal_b2b \
  --no-owner \
  --no-acl \
  > backups/postgres/portal_b2b_cloudsql_migration.sql
```

> **Importante:** Validar que o arquivo gerado não está vazio e contém as tabelas esperadas antes de prosseguir.

---

## 4. Instância Cloud SQL atual

A instância Cloud SQL PostgreSQL está ativa no GCP.

**Configuração atual:**

| Item | Valor |
|---|---|
| Tipo | PostgreSQL |
| Host | `136.114.235.212` |
| Banco | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

---

## 5. Restaurar dump no Cloud SQL (referência)

Com a instância criada e o banco `portal_b2b` configurado, restaurar o dump:

```bash
psql "postgresql://USUARIO:SENHA@136.114.235.212:5432/portal_b2b" \
  < backups/postgres/portal_b2b_cloudsql_migration.sql
```

> **Substituir** `USUARIO`, `SENHA` e `136.114.235.212` pelos valores reais da instância.

---

## 6. Garantir permissões

Após a restauração, aplicar as permissões nos usuários do Cloud SQL:

```sql
-- Permissões para o usuário de aplicação (microsserviços)
GRANT USAGE ON SCHEMA portal_b2b TO svc_portal_b2b;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA portal_b2b TO svc_portal_b2b;
ALTER DEFAULT PRIVILEGES IN SCHEMA portal_b2b GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO svc_portal_b2b;

-- Permissões para o usuário de banco (equipe de banco de dados)
GRANT USAGE, CREATE ON SCHEMA portal_b2b TO db_portal_b2b;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA portal_b2b TO db_portal_b2b;
ALTER DEFAULT PRIVILEGES IN SCHEMA portal_b2b GRANT ALL ON TABLES TO db_portal_b2b;
```

---

## 7. Atualizar .env dos microsserviços

Alterar o `DATABASE_URL` em cada microsserviço para apontar para o Cloud SQL.

**Antes (ambiente antigo — PostgreSQL local via Docker, já removido):**

```env
# AMBIENTE ANTIGO — não usar mais
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
```

**Atual (Cloud SQL PostgreSQL):**

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@136.114.235.212:5432/portal_b2b
```

> **Atenção:** Fazer essa alteração em **todas as VMs** que rodam microsserviços (app-primary e app-standby).

---

## 8. Testar conexão

Após atualizar o `DATABASE_URL`, testar a conectividade com o Cloud SQL:

```bash
psql "postgresql://svc_portal_b2b:SENHA@136.114.235.212:5432/portal_b2b" \
  -c "SELECT * FROM portal_b2b.health_check;"
```

Se a consulta retornar resultado, a conexão está funcionando corretamente.

> **Substituir** `SENHA` e `136.114.235.212` pelos valores reais.

---

## 9. Validação da migração

A migração inicial do PostgreSQL local para o Cloud SQL foi realizada com sucesso.

Teste validado:

```bash
export CLOUDSQL_IP="136.114.235.212"
export SVC_PASSWORD="senha_portal_b2b"

PGPASSWORD="$SVC_PASSWORD" psql \
  -h "$CLOUDSQL_IP" \
  -U svc_portal_b2b \
  -d portal_b2b \
  -c "SELECT * FROM portal_b2b.health_check;"
```

**Resultado esperado/obtido:**

A tabela `portal_b2b.health_check` retornou os registros dos serviços.

---

## 10. Observação importante

O PostgreSQL local foi removido da infraestrutura. O banco oficial é exclusivamente o Cloud SQL PostgreSQL em `136.114.235.212`.

Para cada novo microsserviço implantado, validar se o `.env` aponta para o Cloud SQL. O `produtos-service` já foi validado na arquitetura atual; os demais serviços devem seguir o mesmo padrão durante o deploy.

Os scripts `backup-postgres.sh` e `restore-postgres.sh` servem apenas como aviso de que o banco local não existe mais. Para backups do banco oficial, utilizar backups automáticos, exportações ou snapshots gerenciados pelo GCP.
