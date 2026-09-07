-- Title: einvoice S1 schema — configuration tables + credential vault
-- Kind: patch
-- Intent: einvoice_s1_configuration_schema
-- Context: TH-08 / EP-01 / S1
-- Touches: (DDL only)
-- Safety: idempotent ; medium
-- Depends on: none

create extension if not exists pgcrypto with schema extensions;

create schema if not exists einvoice;

-- PostgreSQL grants EXECUTE on new functions to PUBLIC by default. Keep every
-- future einvoice RPC closed until a slice grants its intended API role.
alter default privileges in schema einvoice revoke execute on functions from public, anon, authenticated;

do $$ begin
  create type einvoice.provider_connection_status as enum (
    'disconnected', 'connected', 'checkRequired', 'reconnectRequired'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type einvoice.provider_code as enum ('misaMeinvoice');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type einvoice.signing_method as enum ('hsm', 'mtt', 'noSign');
exception when duplicate_object then null;
end $$;

create table if not exists einvoice.provider_connections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  provider_code einvoice.provider_code not null default 'misaMeinvoice',
  status einvoice.provider_connection_status not null default 'disconnected',
  capabilities_snapshot jsonb,
  last_verified_at timestamptz,
  connection_version int not null default 1,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_provider_connections_active_tenant
  on einvoice.provider_connections (tenant_id)
  where status <> 'disconnected';

create table if not exists einvoice.provider_credentials (
  connection_id uuid primary key references einvoice.provider_connections(id) on delete cascade,
  tenant_id uuid not null,
  username text not null,
  password_ciphertext bytea not null,
  tax_code text,
  updated_at timestamptz not null default now()
);

revoke all on einvoice.provider_credentials from anon, authenticated;

create table if not exists einvoice.issuance_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null unique,
  provider_connection_id uuid references einvoice.provider_connections(id),
  default_template jsonb,
  default_signing jsonb,
  profile_version int not null default 0,
  compatibility_warnings jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists einvoice.invoice_automation_policies (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null unique,
  auto_issue_enabled boolean not null default false,
  auto_send_enabled boolean not null default false,
  policy_version int not null default 0,
  blockers jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists einvoice.idempotency_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  idempotency_key text not null,
  response jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id, idempotency_key)
);

create table if not exists einvoice.provider_interaction_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  provider_connection_id uuid not null
    references einvoice.provider_connections(id),
  direction text not null
    check (direction in ('OUTBOUND','INBOUND_CALLBACK')),
  operation_type text not null,
  target_type text not null,
  target_id uuid not null,
  correlation_id uuid not null,
  request_reference varchar(255) not null,
  response_reference varchar(255) null,
  provider_reference varchar(255) null,
  status text not null default 'STARTED'
    check (status in ('STARTED','COMPLETED')),
  outcome text null check (outcome is null or outcome in (
    'SUCCEEDED','DEFINITE_FAILURE','TIMEOUT','UNAVAILABLE',
    'NOT_FOUND','MISMATCH','CHECK_REQUIRED'
  )),
  safe_error_code varchar(100) null,
  started_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, correlation_id, operation_type),
  check (
    (status = 'STARTED' and outcome is null and completed_at is null)
    or
    (status = 'COMPLETED' and outcome is not null and completed_at is not null)
  )
);

alter table einvoice.provider_interaction_records enable row level security;
revoke all on einvoice.provider_interaction_records from anon, authenticated;

create table if not exists einvoice.audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  actor_id uuid,
  action text not null,
  payload jsonb,
  created_at timestamptz not null default now()
);

alter table einvoice.provider_connections enable row level security;
alter table einvoice.issuance_profiles enable row level security;
alter table einvoice.invoice_automation_policies enable row level security;

create or replace function einvoice._credential_encryption_key()
returns text
language sql
stable
security definer
set search_path = einvoice, vault, public
as $$
  select decrypted_secret
  from vault.decrypted_secrets
  where name = 'einvoice_credential_key'
  limit 1;
$$;

create or replace function einvoice._encrypt_credential(p_plaintext text)
returns bytea
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_key text;
begin
  v_key := einvoice._credential_encryption_key();
  if v_key is null or v_key = '' then
    raise exception 'VALIDATION_ERROR: einvoice credential encryption key missing';
  end if;
  return extensions.pgp_sym_encrypt(p_plaintext, v_key);
end;
$$;

create or replace function einvoice._decrypt_credential(p_ciphertext bytea)
returns text
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_key text;
begin
  v_key := einvoice._credential_encryption_key();
  if v_key is null or v_key = '' then
    raise exception 'SYSTEM_ERROR: einvoice credential encryption key missing';
  end if;
  return extensions.pgp_sym_decrypt(p_ciphertext, v_key);
end;
$$;

-- Credential primitives are implementation details. API roles may only reach
-- them through guarded user RPCs or service-role worker RPCs.
revoke all on function einvoice._credential_encryption_key() from public, anon, authenticated;
revoke all on function einvoice._encrypt_credential(text) from public, anon, authenticated;
revoke all on function einvoice._decrypt_credential(bytea) from public, anon, authenticated;
