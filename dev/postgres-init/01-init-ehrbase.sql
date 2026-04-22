-- Bootstrap the EHRbase database, roles, and required Postgres extensions.
-- Runs once on first container start via /docker-entrypoint-initdb.d.
-- Mirrors the upstream EHRbase init:
-- https://github.com/ehrbase/ehrbase/blob/develop/base/db-setup/createdb.sql

CREATE ROLE ehrbase_restricted;
CREATE USER ehrbase WITH PASSWORD 'ehrbase' IN ROLE ehrbase_restricted;
CREATE USER ehrbase_admin WITH PASSWORD 'ehrbase_admin' SUPERUSER;

CREATE DATABASE ehrbase ENCODING 'UTF-8' TEMPLATE template0;
GRANT ALL PRIVILEGES ON DATABASE ehrbase TO ehrbase_admin;

\connect ehrbase

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "temporal_tables";
CREATE EXTENSION IF NOT EXISTS "jsquery";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "ltree";

CREATE SCHEMA IF NOT EXISTS ehr AUTHORIZATION ehrbase_admin;
CREATE SCHEMA IF NOT EXISTS ext AUTHORIZATION ehrbase_admin;

GRANT USAGE ON SCHEMA ehr TO ehrbase_restricted;
GRANT USAGE ON SCHEMA ext TO ehrbase_restricted;

ALTER DEFAULT PRIVILEGES FOR USER ehrbase_admin IN SCHEMA ehr
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ehrbase_restricted;
ALTER DEFAULT PRIVILEGES FOR USER ehrbase_admin IN SCHEMA ext
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ehrbase_restricted;
ALTER DEFAULT PRIVILEGES FOR USER ehrbase_admin IN SCHEMA ehr
    GRANT USAGE, SELECT ON SEQUENCES TO ehrbase_restricted;
ALTER DEFAULT PRIVILEGES FOR USER ehrbase_admin IN SCHEMA ext
    GRANT USAGE, SELECT ON SEQUENCES TO ehrbase_restricted;
