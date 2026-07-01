-- <Title>: <1-line intent>
-- Context: <Theme/Epic/US/FR or ticket id>
-- Safety: idempotent ; <low|medium|high lock/data impact>

-- 1) Extensions (if needed)
-- create extension if not exists pg_trgm;

-- 2) Schema
-- create schema if not exists <schema_name>;

-- 3) Types / enums
-- do $$
-- begin
--   if not exists (select 1 from pg_type where typname = '<type_name>') then
--     create type <schema_name>.<type_name> as enum ('value_1', 'value_2');
--   end if;
-- end $$;

-- 4) Tables
-- create table if not exists <schema_name>.<table_name> (
--   id uuid primary key default gen_random_uuid(),
--   tenant_id uuid not null,
--   created_at timestamptz not null default now()
-- );

-- 5) Indexes
-- create index if not exists idx_<table>_tenant_created_at
--   on <schema_name>.<table_name> (tenant_id, created_at desc);

-- 6) Functions / triggers (optional)
-- create or replace function <schema_name>.<function_name>()
-- returns trigger
-- language plpgsql
-- as $$
-- begin
--   return new;
-- end;
-- $$;

-- drop trigger if exists trg_<table>_<purpose> on <schema_name>.<table_name>;
-- create trigger trg_<table>_<purpose>
-- before update on <schema_name>.<table_name>
-- for each row
-- execute function <schema_name>.<function_name>();

-- 7) Security (RLS + policies + grants)
-- alter table <schema_name>.<table_name> enable row level security;
--
-- drop policy if exists p_<table>_tenant_isolation on <schema_name>.<table_name>;
-- create policy p_<table>_tenant_isolation
-- on <schema_name>.<table_name>
-- using (tenant_id = ((auth.jwt() ->> 'tenant_id')::uuid))
-- with check (tenant_id = ((auth.jwt() ->> 'tenant_id')::uuid));
--
-- revoke all on table <schema_name>.<table_name> from public, anon;
-- grant select, insert, update on <schema_name>.<table_name> to authenticated;

-- 8) Notes
-- - Why this migration exists
-- - Known follow-ups / assumptions
