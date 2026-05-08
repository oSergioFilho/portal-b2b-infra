# Migração do PostgreSQL Local para Cloud SQL

## 1. Objetivo

Este documento descreve como migrar o banco PostgreSQL local da VM para uma instância **Cloud SQL PostgreSQL** gerenciada pelo GCP.

A migração permite que o banco seja acessado por múltiplas VMs de aplicação, eliminando a dependência do PostgreSQL local e habilitando a arquitetura redundante.

---

## 2. Criar backup do banco atual

Antes de qualquer migração, gerar um dump completo do banco atual:

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

## 3. Criar instância Cloud SQL

Criar uma instância Cloud SQL PostgreSQL no console do GCP ou via `gcloud`:

**Configuração esperada:**

| Item | Valor |
|---|---|
| Tipo | PostgreSQL |
| Banco | `portal_b2b` |
| Usuário de aplicação | `svc_portal_b2b` |
| Usuário de banco (DDL) | `db_portal_b2b` |

> **Observação:** Anotar o IP privado ou público da instância Cloud SQL para configurar os microsserviços.

---

## 4. Restaurar dump no Cloud SQL

Com a instância criada e o banco `portal_b2b` configurado, restaurar o dump:

```bash
psql "postgresql://USUARIO:SENHA@IP_DO_CLOUD_SQL:5432/portal_b2b" \
  < backups/postgres/portal_b2b_cloudsql_migration.sql
```

> **Substituir** `USUARIO`, `SENHA` e `IP_DO_CLOUD_SQL` pelos valores reais da instância.

---

## 5. Garantir permissões

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

## 6. Atualizar .env dos microsserviços

Alterar o `DATABASE_URL` em cada microsserviço para apontar para o Cloud SQL.

**Antes (PostgreSQL local via Docker):**

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@postgres:5432/portal_b2b
```

**Depois (Cloud SQL PostgreSQL):**

```env
DATABASE_URL=postgresql://svc_portal_b2b:senha_portal_b2b@IP_DO_CLOUD_SQL:5432/portal_b2b
```

> **Atenção:** Fazer essa alteração em **todas as VMs** que rodam microsserviços (app-primary e app-standby).

---

## 7. Testar conexão

Após atualizar o `DATABASE_URL`, testar a conectividade com o Cloud SQL:

```bash
psql "postgresql://svc_portal_b2b:SENHA@IP_DO_CLOUD_SQL:5432/portal_b2b" \
  -c "SELECT * FROM portal_b2b.health_check;"
```

Se a consulta retornar resultado, a conexão está funcionando corretamente.

> **Substituir** `SENHA` e `IP_DO_CLOUD_SQL` pelos valores reais.

---

## 8. Observação importante

**Não apagar o PostgreSQL local imediatamente.**

O procedimento seguro é:

1. Configurar o Cloud SQL.
2. Restaurar o dump.
3. Atualizar o `DATABASE_URL` de **pelo menos um microsserviço**.
4. Validar que o microsserviço funciona normalmente com o Cloud SQL.
5. Somente após validação completa, considerar desativar o PostgreSQL local.

O PostgreSQL local pode continuar rodando como fallback durante o período de transição.
