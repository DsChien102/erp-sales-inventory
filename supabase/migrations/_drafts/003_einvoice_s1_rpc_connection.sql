-- Title: einvoice S1 RPC — connection lifecycle (async connect)
-- Kind: patch
-- Intent: einvoice_s1_rpc_connection
-- Context: TH-08 / EP-01 / US-01
-- Touches: connect_provider, verify_provider_connection, reconnect_provider, disconnect_provider, get_provider_connection_screen, record_connection_verified, read_provider_credentials
-- Safety: idempotent ; medium
-- Depends on: 001_einvoice_s1_schema_configuration.sql, 002_einvoice_s1_install_module_messaging.sql

create or replace function einvoice.connect_provider(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_username text,
  p_password text,
  p_expected_connection_version int default null
) returns table(connection_id uuid, status text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_connection_id uuid;
  v_version int;
begin
  select pc.id, pc.connection_version into v_connection_id, v_version
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
  limit 1;

  if v_connection_id is null then
    insert into einvoice.provider_connections (tenant_id, status, created_by)
    values (p_tenant_id, 'checkRequired', p_actor_id)
    returning id, connection_version into v_connection_id, v_version;
  else
    if p_expected_connection_version is not null and p_expected_connection_version <> v_version then
      raise exception 'STATE_CHANGED: connection version mismatch';
    end if;
    update einvoice.provider_connections
    set status = 'checkRequired', connection_version = connection_version + 1, updated_at = now()
    where id = v_connection_id
    returning connection_version into v_version;
  end if;

  insert into einvoice.provider_credentials (
    connection_id, tenant_id, username, password_ciphertext
  ) values (
    v_connection_id, p_tenant_id, p_username, einvoice._encrypt_credential(p_password)
  )
  on conflict (connection_id) do update set
    username = excluded.username,
    password_ciphertext = excluded.password_ciphertext,
    updated_at = now();

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object('tenant_id', p_tenant_id, 'connection_id', v_connection_id)
  );

  return query select v_connection_id, 'checkRequired'::text;
end;
$$;

create or replace function einvoice.record_connection_verified(
  p_tenant_id uuid,
  p_connection_id uuid,
  p_status text,
  p_capabilities jsonb default null,
  p_verified_at timestamptz default null,
  p_correlation_id text default null
) returns table(connection_id uuid, status text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
begin
  update einvoice.provider_connections pc
  set
    status = p_status::einvoice.provider_connection_status,
    capabilities_snapshot = coalesce(p_capabilities, capabilities_snapshot),
    last_verified_at = coalesce(p_verified_at, last_verified_at),
    connection_version = connection_version + 1,
    updated_at = now()
  where pc.id = p_connection_id and pc.tenant_id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  return query select p_connection_id, p_status;
end;
$$;

create or replace function einvoice.get_provider_connection_screen(
  p_tenant_id uuid,
  p_actor_id uuid
) returns table(legal_profile jsonb, connection jsonb)
language sql
security definer
set search_path = einvoice, iam, public
as $$
  select
    jsonb_build_object(
      'legal_name', coalesce(lp.legal_name, ''),
      'tax_code', coalesce(lp.tax_code, ''),
      'address', lp.registered_address_text
    ) as legal_profile,
    coalesce(
      (
        select jsonb_build_object(
          'connection_id', pc.id,
          'status', pc.status::text,
          'last_checked_at', pc.last_verified_at
        )
        from einvoice.provider_connections pc
        where pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
        order by pc.updated_at desc
        limit 1
      ),
      jsonb_build_object('status', 'disconnected')
    ) as connection
  from iam.tenants t
  left join iam.tenant_legal_profiles lp on lp.tenant_id = t.id
  where t.id = p_tenant_id;
$$;

create or replace function einvoice.verify_provider_connection(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_connection_id uuid
) returns table(connection_id uuid, status text, checked_at timestamptz)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_status text;
begin
  select pc.status::text into v_status
  from einvoice.provider_connections pc
  where pc.id = p_connection_id and pc.tenant_id = p_tenant_id;

  if v_status is null then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object('tenant_id', p_tenant_id, 'connection_id', p_connection_id)
  );

  return query select p_connection_id, v_status, now();
end;
$$;

create or replace function einvoice.reconnect_provider(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_connection_id uuid,
  p_username text,
  p_password text
) returns table(connection_id uuid, status text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
begin
  update einvoice.provider_credentials
  set username = p_username,
      password_ciphertext = einvoice._encrypt_credential(p_password),
      updated_at = now()
  where connection_id = p_connection_id and tenant_id = p_tenant_id;

  update einvoice.provider_connections
  set status = 'checkRequired', connection_version = connection_version + 1, updated_at = now()
  where id = p_connection_id and tenant_id = p_tenant_id;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object('tenant_id', p_tenant_id, 'connection_id', p_connection_id)
  );

  return query select p_connection_id, 'checkRequired'::text;
end;
$$;

create or replace function einvoice.disconnect_provider(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_connection_id uuid,
  p_confirm boolean
) returns table(connection_id uuid, status text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
begin
  if not p_confirm then
    raise exception 'VALIDATION_ERROR: disconnect requires confirmation';
  end if;

  update einvoice.provider_connections
  set status = 'disconnected', connection_version = connection_version + 1, updated_at = now()
  where id = p_connection_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  return query select p_connection_id, 'disconnected'::text;
end;
$$;

create or replace function einvoice.read_provider_credentials(p_tenant_id uuid)
returns table(username text, password text, tax_code text, base_url text)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
begin
  if current_setting('request.jwt.claim.role', true) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  return query
  select
    c.username,
    einvoice._decrypt_credential(c.password_ciphertext) as password,
    coalesce(nullif(c.tax_code, ''), lp.tax_code) as tax_code,
    null::text as base_url
  from einvoice.provider_credentials c
  join einvoice.provider_connections pc on pc.id = c.connection_id
  left join iam.tenant_legal_profiles lp on lp.tenant_id = c.tenant_id
  where c.tenant_id = p_tenant_id and pc.status <> 'disconnected'
  limit 1;
end;
$$;
