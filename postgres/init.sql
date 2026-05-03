-- Criar schemas
CREATE SCHEMA IF NOT EXISTS schema_usuarios;
CREATE SCHEMA IF NOT EXISTS schema_produtos;
CREATE SCHEMA IF NOT EXISTS schema_fornecimentos;
CREATE SCHEMA IF NOT EXISTS schema_demanda;
CREATE SCHEMA IF NOT EXISTS schema_mercado;
CREATE SCHEMA IF NOT EXISTS schema_negociacao;
CREATE SCHEMA IF NOT EXISTS schema_pedidos;
CREATE SCHEMA IF NOT EXISTS schema_logistica;
CREATE SCHEMA IF NOT EXISTS schema_transportadoras;

-- Criar usuários (idempotente)
DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_usuarios') THEN
        CREATE ROLE svc_usuarios WITH LOGIN PASSWORD 'senha_usuarios';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_produtos') THEN
        CREATE ROLE svc_produtos WITH LOGIN PASSWORD 'senha_produtos';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_fornecimentos') THEN
        CREATE ROLE svc_fornecimentos WITH LOGIN PASSWORD 'senha_fornecimentos';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_demanda') THEN
        CREATE ROLE svc_demanda WITH LOGIN PASSWORD 'senha_demanda';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_mercado') THEN
        CREATE ROLE svc_mercado WITH LOGIN PASSWORD 'senha_mercado';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_negociacao') THEN
        CREATE ROLE svc_negociacao WITH LOGIN PASSWORD 'senha_negociacao';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_pedidos') THEN
        CREATE ROLE svc_pedidos WITH LOGIN PASSWORD 'senha_pedidos';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_logistica') THEN
        CREATE ROLE svc_logistica WITH LOGIN PASSWORD 'senha_logistica';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'svc_transportadoras') THEN
        CREATE ROLE svc_transportadoras WITH LOGIN PASSWORD 'senha_transportadoras';
    END IF;
END $$;

-- Definir search_path
ALTER ROLE svc_usuarios SET search_path TO schema_usuarios;
ALTER ROLE svc_produtos SET search_path TO schema_produtos;
ALTER ROLE svc_fornecimentos SET search_path TO schema_fornecimentos;
ALTER ROLE svc_demanda SET search_path TO schema_demanda;
ALTER ROLE svc_mercado SET search_path TO schema_mercado;
ALTER ROLE svc_negociacao SET search_path TO schema_negociacao;
ALTER ROLE svc_pedidos SET search_path TO schema_pedidos;
ALTER ROLE svc_logistica SET search_path TO schema_logistica;
ALTER ROLE svc_transportadoras SET search_path TO schema_transportadoras;

-- Garantir que cada usuário só tenha permissão no próprio schema
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;

GRANT USAGE, CREATE ON SCHEMA schema_usuarios TO svc_usuarios;
GRANT USAGE, CREATE ON SCHEMA schema_produtos TO svc_produtos;
GRANT USAGE, CREATE ON SCHEMA schema_fornecimentos TO svc_fornecimentos;
GRANT USAGE, CREATE ON SCHEMA schema_demanda TO svc_demanda;
GRANT USAGE, CREATE ON SCHEMA schema_mercado TO svc_mercado;
GRANT USAGE, CREATE ON SCHEMA schema_negociacao TO svc_negociacao;
GRANT USAGE, CREATE ON SCHEMA schema_pedidos TO svc_pedidos;
GRANT USAGE, CREATE ON SCHEMA schema_logistica TO svc_logistica;
GRANT USAGE, CREATE ON SCHEMA schema_transportadoras TO svc_transportadoras;

-- Permissões padrão para tabelas e sequences futuras
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_usuarios GRANT ALL ON TABLES TO svc_usuarios;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_produtos GRANT ALL ON TABLES TO svc_produtos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_fornecimentos GRANT ALL ON TABLES TO svc_fornecimentos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_demanda GRANT ALL ON TABLES TO svc_demanda;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_mercado GRANT ALL ON TABLES TO svc_mercado;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_negociacao GRANT ALL ON TABLES TO svc_negociacao;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_pedidos GRANT ALL ON TABLES TO svc_pedidos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_logistica GRANT ALL ON TABLES TO svc_logistica;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_transportadoras GRANT ALL ON TABLES TO svc_transportadoras;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_usuarios GRANT ALL ON SEQUENCES TO svc_usuarios;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_produtos GRANT ALL ON SEQUENCES TO svc_produtos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_fornecimentos GRANT ALL ON SEQUENCES TO svc_fornecimentos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_demanda GRANT ALL ON SEQUENCES TO svc_demanda;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_mercado GRANT ALL ON SEQUENCES TO svc_mercado;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_negociacao GRANT ALL ON SEQUENCES TO svc_negociacao;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_pedidos GRANT ALL ON SEQUENCES TO svc_pedidos;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_logistica GRANT ALL ON SEQUENCES TO svc_logistica;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA schema_transportadoras GRANT ALL ON SEQUENCES TO svc_transportadoras;

-- Criar tabela de health check e inserir registros
CREATE TABLE schema_usuarios.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_usuarios.health_check (service_name) VALUES ('usuarios-service');

CREATE TABLE schema_produtos.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_produtos.health_check (service_name) VALUES ('produtos-service');

CREATE TABLE schema_fornecimentos.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_fornecimentos.health_check (service_name) VALUES ('fornecimentos-service');

CREATE TABLE schema_demanda.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_demanda.health_check (service_name) VALUES ('demanda-service');

CREATE TABLE schema_mercado.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_mercado.health_check (service_name) VALUES ('mercado-service');

CREATE TABLE schema_negociacao.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_negociacao.health_check (service_name) VALUES ('negociacao-service');

CREATE TABLE schema_pedidos.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_pedidos.health_check (service_name) VALUES ('pedidos-service');

CREATE TABLE schema_logistica.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_logistica.health_check (service_name) VALUES ('logistica-service');

CREATE TABLE schema_transportadoras.health_check (id SERIAL PRIMARY KEY, service_name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
INSERT INTO schema_transportadoras.health_check (service_name) VALUES ('transportadoras-service');
