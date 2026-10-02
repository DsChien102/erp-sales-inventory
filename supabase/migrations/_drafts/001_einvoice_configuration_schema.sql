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

create table if not exists einvoice.provider_connections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  status text not null default 'DISCONNECTED'
    check (status in (
      'DISCONNECTED', 'CONNECTED', 'CHECK_REQUIRED', 'RECONNECT_REQUIRED'
    )),
  capabilities_snapshot jsonb,
  last_verified_at timestamptz,
  connection_version int not null default 1,
  created_at timestamptz not null default now(),
  unique (tenant_id, id)
);

create unique index if not exists uq_provider_connections_active_tenant
  on einvoice.provider_connections (tenant_id)
  where status <> 'DISCONNECTED';

create table if not exists einvoice.provider_credentials (
  connection_id uuid primary key,
  tenant_id uuid not null,
  username text not null,
  password_ciphertext bytea not null,
  created_at timestamptz not null default now(),
  foreign key (tenant_id, connection_id)
    references einvoice.provider_connections (tenant_id, id) on delete cascade
);

alter table einvoice.provider_credentials enable row level security;
revoke all on einvoice.provider_credentials from anon, authenticated;

create table if not exists einvoice.tenant_settings (
  tenant_id uuid primary key,
  -- profile_version bảo vệ hai cột mặc định (màn "Cấu hình phát hành mặc định")
  default_template_id text,
  default_invoice_series varchar(100)
    check (
      default_invoice_series is null
      or default_invoice_series ~ '^[1256][CK].{2}[TM]'
    ),
  profile_version int not null default 0,
  -- policy_version bảo vệ hai công tắc (màn "Tự động hoá")
  auto_issue_enabled boolean not null default false,
  auto_send_enabled boolean not null default false,
  policy_version int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (default_template_id is null and default_invoice_series is null)
    or (default_template_id is not null and default_invoice_series is not null)
  )
);

alter table einvoice.tenant_settings enable row level security;
revoke all on einvoice.tenant_settings from anon, authenticated;

alter table einvoice.provider_connections enable row level security;
revoke all on einvoice.provider_connections from anon, authenticated;

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
