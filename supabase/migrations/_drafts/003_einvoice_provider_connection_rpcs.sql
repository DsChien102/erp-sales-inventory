-- Title: einvoice S1 RPC — connection lifecycle (async connect)
-- Kind: patch
-- Intent: einvoice_s1_rpc_connection
-- Context: TH-08 / EP-01 / US-01
-- Touches: connect_provider, verify_provider_connection, reconnect_provider, disconnect_provider, get_provider_connection_screen, record_connection_verified, read_provider_credentials
-- Safety: idempotent ; medium
-- Depends on: 001_einvoice_configuration_schema.sql, 002_einvoice_install_module_messaging.sql
--
-- capabilities_snapshot.templates[] JSON shape (H1 hardening, additive):
--   template_id, name, serial, symbol, invoice_series, invoice_with_code,
--   is_mtt, is_send_summary, is_available
-- Legacy rows may omit invoice_series / invoice_with_code / is_send_summary;
-- readers prefer invoice_series then symbol and re-classify from InvSeries.

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
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  if nullif(btrim(p_username), '') is null or nullif(p_password, '') is null then
    raise exception 'VALIDATION_ERROR: username and password are required';
  end if;

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
  on conflict on constraint provider_credentials_pkey do update set
    username = excluded.username,
    password_ciphertext = excluded.password_ciphertext,
    updated_at = now();

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'connection_id', v_connection_id,
      'expected_connection_version', v_version
    )
  );

  return query select v_connection_id, 'checkRequired'::text;
end;
$$;

-- The worker compare-and-set version is part of the RPC identity. Remove the
-- pre-version signature so rerunning this bundle cannot leave a callable
-- legacy overload behind.
drop function if exists einvoice.record_connection_verified(
  uuid, uuid, text, jsonb, timestamptz, text
);

create or replace function einvoice.record_connection_verified(
  p_tenant_id uuid,
  p_connection_id uuid,
  p_expected_connection_version int,
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
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if p_status not in ('connected', 'reconnectRequired') then
    raise exception 'VALIDATION_ERROR: invalid worker connection status';
  end if;

  -- A disconnect or newer reconnect increments connection_version. A stale
  -- worker result must become an idempotent no-op instead of reviving or
  -- overwriting that newer state.
  update einvoice.provider_connections pc
  set
    status = p_status::einvoice.provider_connection_status,
    capabilities_snapshot = coalesce(p_capabilities, capabilities_snapshot),
    last_verified_at = coalesce(p_verified_at, last_verified_at),
    connection_version = connection_version + 1,
    updated_at = now()
  where pc.id = p_connection_id
    and pc.tenant_id = p_tenant_id
    and pc.status = 'checkRequired'
    and pc.connection_version = p_expected_connection_version;

  if not found then
    if not exists (
      select 1
      from einvoice.provider_connections pc
      where pc.id = p_connection_id and pc.tenant_id = p_tenant_id
    ) then
      raise exception 'NOT_FOUND: provider connection';
    end if;

    return query
    select pc.id, pc.status::text
    from einvoice.provider_connections pc
    where pc.id = p_connection_id and pc.tenant_id = p_tenant_id;
    return;
  end if;

  return query select p_connection_id, p_status;
end;
$$;

create or replace function einvoice.get_provider_connection_screen(
  p_tenant_id uuid,
  p_actor_id uuid
) returns table(legal_profile jsonb, connection jsonb)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  return query
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
          'connection_version', pc.connection_version,
          'last_checked_at', pc.last_verified_at,
          'masked_account', case
            when c.username is null then null
            when position('@' in c.username) > 2
              then left(c.username, 2) || '***' || substring(c.username from position('@' in c.username))
            when length(c.username) > 2 then left(c.username, 2) || '***'
            else '***'
          end
        )
        from einvoice.provider_connections pc
        left join einvoice.provider_credentials c on c.connection_id = pc.id
        where pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
        order by pc.updated_at desc
        limit 1
      ),
      jsonb_build_object('status', 'disconnected')
    ) as connection
  from iam.tenants t
  left join iam.tenant_legal_profiles lp on lp.tenant_id = t.id
  where t.id = p_tenant_id;
end;
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
  v_version int;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  select pc.status::text, pc.connection_version into v_status, v_version
  from einvoice.provider_connections pc
  where pc.id = p_connection_id and pc.tenant_id = p_tenant_id;

  if v_status is null then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'connection_id', p_connection_id,
      'expected_connection_version', v_version
    )
  );

  return query select p_connection_id, v_status, now();
end;
$$;

drop function if exists einvoice.reconnect_provider(uuid, uuid, uuid, text, text);

create or replace function einvoice.reconnect_provider(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_connection_id uuid,
  p_username text,
  p_password text,
  p_expected_connection_version int default null
) returns table(connection_id uuid, status text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_version int;
  v_status text;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  if nullif(btrim(p_username), '') is null or nullif(p_password, '') is null then
    raise exception 'VALIDATION_ERROR: username and password are required';
  end if;

  select pc.connection_version, pc.status::text into v_version, v_status
  from einvoice.provider_connections pc
  where pc.id = p_connection_id and pc.tenant_id = p_tenant_id
  for update;

  if v_version is null then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  if v_status = 'disconnected' then
    raise exception 'INVALID_STATUS: disconnected connection cannot reconnect';
  end if;

  if p_expected_connection_version is not null
     and p_expected_connection_version <> v_version then
    raise exception 'STATE_CHANGED: connection version mismatch';
  end if;

  update einvoice.provider_credentials as credentials
  set username = p_username,
      password_ciphertext = einvoice._encrypt_credential(p_password),
      updated_at = now()
  where credentials.connection_id = p_connection_id
    and credentials.tenant_id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND: provider credentials';
  end if;

  update einvoice.provider_connections
  set status = 'checkRequired', connection_version = connection_version + 1, updated_at = now()
  where id = p_connection_id and tenant_id = p_tenant_id
  returning connection_version into v_version;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.sync_capabilities',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'connection_id', p_connection_id,
      'expected_connection_version', v_version
    )
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
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  if p_confirm is not true then
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
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
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

revoke all on function einvoice.connect_provider(uuid, uuid, text, text, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_provider_connection_screen(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.verify_provider_connection(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.reconnect_provider(uuid, uuid, uuid, text, text, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.disconnect_provider(uuid, uuid, uuid, boolean)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.record_connection_verified(uuid, uuid, integer, text, jsonb, timestamptz, text)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.read_provider_credentials(uuid)
  from public, anon, authenticated, service_role;

grant execute on function einvoice.connect_provider(uuid, uuid, text, text, integer)
  to authenticated;
grant execute on function einvoice.get_provider_connection_screen(uuid, uuid) to authenticated;
grant execute on function einvoice.verify_provider_connection(uuid, uuid, uuid) to authenticated;
grant execute on function einvoice.reconnect_provider(uuid, uuid, uuid, text, text, integer) to authenticated;
grant execute on function einvoice.disconnect_provider(uuid, uuid, uuid, boolean) to authenticated;

grant execute on function einvoice.record_connection_verified(uuid, uuid, integer, text, jsonb, timestamptz, text) to service_role;
grant execute on function einvoice.read_provider_credentials(uuid) to service_role;
