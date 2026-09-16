-- Title: einvoice S4a official invoice view operations
-- Kind: patch
-- Intent: einvoice_s4a_official_view
-- Context: TH-08 / EP-03 / US-01
-- Touches: _official_view_command_id, get_electronic_invoice_detail, load_official_view_operation_context, record_official_invoice_view_result, request_official_invoice_view
-- Safety: idempotent ; medium
-- Depends on: 007_einvoice_issuance_schema_and_publish_rpcs.sql, 009_einvoice_issuance_reconciliation_rpcs.sql, 018_sales_einvoice_source_contract.sql

create unique index if not exists electronic_invoices_tenant_id_id_idx
  on einvoice.electronic_invoices (tenant_id, id);

create table if not exists einvoice.official_invoice_view_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  electronic_invoice_id uuid not null,
  generation integer not null check (generation > 0),
  attempt_ordinal integer not null default 1 check (attempt_ordinal > 0),
  status text not null check (status in ('PENDING','AVAILABLE','FAILED','CHECK_REQUIRED')),
  provider_viewer_url text null,
  viewer_token text null,
  expires_at timestamptz null,
  failure_code text null,
  failure_message text null,
  provider_interaction_reference uuid null,
  requested_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, electronic_invoice_id, generation),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id)
);

create index if not exists official_invoice_view_operations_invoice_idx
  on einvoice.official_invoice_view_operations (tenant_id, electronic_invoice_id, generation desc);

alter table einvoice.official_invoice_view_operations enable row level security;
revoke all on einvoice.official_invoice_view_operations from anon, authenticated;

create or replace function einvoice._official_view_command_id(
  p_operation_id uuid,
  p_attempt_ordinal integer
) returns uuid
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_hex text;
begin
  v_raw := p_operation_id::text || '|official_view|' || p_attempt_ordinal::text;
  v_hex := encode(sha256(v_raw::bytea), 'hex');
  return (
    substr(v_hex, 1, 8) || '-' ||
    substr(v_hex, 9, 4) || '-' ||
    substr(v_hex, 13, 4) || '-' ||
    substr(v_hex, 17, 4) || '-' ||
    substr(v_hex, 21, 12)
  )::uuid;
end;
$$;

create or replace function einvoice.request_official_invoice_view(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  operation_id uuid,
  status text,
  viewer_url text,
  viewer_token text,
  expires_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_operation einvoice.official_invoice_view_operations%rowtype;
  v_generation integer;
  v_operation_id uuid;
  v_attempt_ordinal integer;
  v_cmd_id uuid;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.view') then
    raise exception 'NO_PERMISSION: einvoice.view required';
  end if;

  if not sales.can_access_sales_order(
    p_tenant_id,
    p_actor_id,
    p_sales_order_id
  ) then
    raise exception 'NOT_FOUND: sales order not found';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice not found';
  end if;

  select o.*
  into v_operation
  from einvoice.official_invoice_view_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
  order by o.generation desc
  limit 1;

  if found then
    if v_operation.status = 'PENDING' then
      return query select
        v_cmd_id,
        v_operation.status,
        v_operation.provider_viewer_url,
        v_operation.viewer_token,
        v_operation.expires_at;
      return;
    end if;

    if v_operation.status = 'AVAILABLE'
       and v_operation.expires_at is not null
       and v_operation.expires_at > now() then
      return query select
        v_operation.id,
        v_operation.status,
        v_operation.provider_viewer_url,
        v_operation.viewer_token,
        v_operation.expires_at;
      return;
    end if;

    if v_operation.status = 'CHECK_REQUIRED' then
      v_attempt_ordinal := v_operation.attempt_ordinal + 1;
      update einvoice.official_invoice_view_operations o
      set
        status = 'PENDING',
        attempt_ordinal = v_attempt_ordinal,
        version = o.version + 1,
        provider_viewer_url = null,
        viewer_token = null,
        expires_at = null,
        failure_code = null,
        failure_message = null,
        completed_at = null,
        requested_at = now(),
        updated_at = now()
      where o.id = v_operation.id
        and o.tenant_id = p_tenant_id
        and o.version = v_operation.version;

      if not found then
        raise exception 'STATE_CHANGED: official view operation version mismatch';
      end if;

      v_cmd_id := einvoice._official_view_command_id(v_operation.id, v_attempt_ordinal);
      insert into einvoice.internal_commands (
        id, tenant_id, command_type, payload, source_event_id, enqueued_at
      ) values (
        v_cmd_id,
        p_tenant_id,
        'einvoice.fetch_official_view',
        jsonb_build_object(
          'tenant_id', p_tenant_id,
          'operation_id', v_operation.id,
          'electronic_invoice_id', v_invoice.id,
          'attempt_ordinal', v_attempt_ordinal,
          'correlation_id', v_operation.id
        ),
        v_cmd_id,
        now()
      ) on conflict (id) do nothing;

      return query select
        v_operation.id,
        'PENDING'::text,
        null::text,
        null::text,
        null::timestamptz;
      return;
    end if;
  end if;

  select coalesce(max(o.generation), 0) + 1
  into v_generation
  from einvoice.official_invoice_view_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id;

  v_operation_id := gen_random_uuid();
  v_attempt_ordinal := 1;

  insert into einvoice.official_invoice_view_operations (
    id,
    tenant_id,
    version,
    electronic_invoice_id,
    generation,
    attempt_ordinal,
    status,
    requested_at
  ) values (
    v_operation_id,
    p_tenant_id,
    0,
    v_invoice.id,
    v_generation,
    v_attempt_ordinal,
    'PENDING',
    now()
  );

  v_cmd_id := einvoice._official_view_command_id(v_operation_id, v_attempt_ordinal);
  insert into einvoice.internal_commands (
    id, tenant_id, command_type, payload, source_event_id, enqueued_at
  ) values (
    v_cmd_id,
    p_tenant_id,
    'einvoice.fetch_official_view',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'operation_id', v_operation_id,
      'electronic_invoice_id', v_invoice.id,
      'attempt_ordinal', v_attempt_ordinal,
      'correlation_id', v_operation_id
    ),
    v_cmd_id,
    now()
  ) on conflict (id) do nothing;

  return query select
    v_operation_id,
    'PENDING'::text,
    null::text,
    null::text,
    null::timestamptz;
end;
$$;

create or replace function einvoice.get_electronic_invoice_detail(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  electronic_invoice_id uuid,
  sales_order_id uuid,
  invoice_number text,
  provider_ref text,
  issued_at timestamptz,
  official_view_operation_id uuid,
  official_view_status text,
  official_viewer_url text,
  official_viewer_token text,
  official_viewer_expires_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_operation einvoice.official_invoice_view_operations%rowtype;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.view') then
    raise exception 'NO_PERMISSION: einvoice.view required';
  end if;

  if not sales.can_access_sales_order(
    p_tenant_id,
    p_actor_id,
    p_sales_order_id
  ) then
    raise exception 'NOT_FOUND: sales order not found';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice not found';
  end if;

  select o.*
  into v_operation
  from einvoice.official_invoice_view_operations o
  where o.tenant_id = p_tenant_id
    and o.electronic_invoice_id = v_invoice.id
  order by o.generation desc
  limit 1;

  return query select
    v_invoice.id,
    v_invoice.sales_order_id,
    v_invoice.invoice_number::text,
    v_invoice.provider_invoice_reference::text,
    v_invoice.issued_at,
  case when found then v_operation.id else null end,
  case when found then v_operation.status else null end,
  case when found then v_operation.provider_viewer_url else null end,
  case when found then v_operation.viewer_token else null end,
  case when found then v_operation.expires_at else null end;
end;
$$;

create or replace function einvoice.load_official_view_operation_context(
  p_tenant_id uuid,
  p_operation_id uuid
) returns table(
  operation_id uuid,
  tenant_id uuid,
  electronic_invoice_id uuid,
  generation integer,
  attempt_ordinal integer,
  status text,
  provider_connection_id uuid,
  provider_invoice_reference text,
  invoice_series text,
  expected_version bigint
) language plpgsql security definer set search_path = einvoice, public as $$
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  return query
  select
    o.id,
    o.tenant_id,
    o.electronic_invoice_id,
    o.generation,
    o.attempt_ordinal,
    o.status,
    ei.provider_connection_id,
    ei.provider_invoice_reference::text,
    ei.series::text,
    o.version
  from einvoice.official_invoice_view_operations o
  join einvoice.electronic_invoices ei
    on ei.tenant_id = o.tenant_id
   and ei.id = o.electronic_invoice_id
  where o.tenant_id = p_tenant_id
    and o.id = p_operation_id;
end;
$$;

create or replace function einvoice.record_official_invoice_view_result(
  p_tenant_id uuid,
  p_operation_id uuid,
  p_status text,
  p_expected_version bigint,
  p_provider_interaction_reference uuid,
  p_viewer_url text default null,
  p_viewer_token text default null,
  p_expires_at timestamptz default null,
  p_failure_code text default null,
  p_failure_message text default null
) returns table(
  operation_id uuid,
  status text,
  viewer_url text,
  viewer_token text,
  expires_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_operation einvoice.official_invoice_view_operations%rowtype;
  v_status text := upper(p_status);
  v_expires_at timestamptz;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if v_status not in ('AVAILABLE', 'FAILED', 'CHECK_REQUIRED') then
    raise exception 'VALIDATION_ERROR: invalid official view result status';
  end if;

  select o.*
  into v_operation
  from einvoice.official_invoice_view_operations o
  where o.tenant_id = p_tenant_id
    and o.id = p_operation_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: official view operation not found';
  end if;

  if v_operation.status in ('AVAILABLE', 'FAILED', 'CHECK_REQUIRED')
     and v_operation.status = v_status then
    return query select
      v_operation.id,
      v_operation.status,
      v_operation.provider_viewer_url,
      v_operation.viewer_token,
      v_operation.expires_at;
    return;
  end if;

  if v_operation.status <> 'PENDING' then
    raise exception 'INVALID_STATUS: official view operation is not pending';
  end if;

  if v_operation.version <> p_expected_version then
    raise exception 'STATE_CHANGED: official view operation version mismatch';
  end if;

  if v_status = 'AVAILABLE' then
    if coalesce(trim(p_viewer_url), '') = '' then
      raise exception 'VALIDATION_ERROR: viewer url required for AVAILABLE';
    end if;
    v_expires_at := least(
      coalesce(p_expires_at, now() + interval '5 minutes'),
      now() + interval '5 minutes'
    );
  else
    v_expires_at := null;
  end if;

  update einvoice.official_invoice_view_operations o
  set
    status = v_status,
    provider_viewer_url = case when v_status = 'AVAILABLE' then p_viewer_url else null end,
    viewer_token = case when v_status = 'AVAILABLE' then p_viewer_token else null end,
    expires_at = v_expires_at,
    failure_code = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_code else null end,
    failure_message = case when v_status in ('FAILED', 'CHECK_REQUIRED') then p_failure_message else null end,
    provider_interaction_reference = p_provider_interaction_reference,
    completed_at = now(),
    version = o.version + 1,
    updated_at = now()
  where o.id = p_operation_id
    and o.tenant_id = p_tenant_id
    and o.version = p_expected_version;

  if not found then
    raise exception 'STATE_CHANGED: official view operation version mismatch';
  end if;

  return query
  select
    o.id,
    o.status,
    o.provider_viewer_url,
    o.viewer_token,
    o.expires_at
  from einvoice.official_invoice_view_operations o
  where o.id = p_operation_id
    and o.tenant_id = p_tenant_id;
end;
$$;

revoke all on function einvoice._official_view_command_id(uuid, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.request_official_invoice_view(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_electronic_invoice_detail(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.load_official_view_operation_context(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.record_official_invoice_view_result(
  uuid, uuid, text, bigint, uuid, text, text, timestamptz, text, text
) from public, anon, authenticated, service_role;

grant execute on function einvoice.request_official_invoice_view(uuid, uuid, uuid)
  to authenticated;
grant execute on function einvoice.get_electronic_invoice_detail(uuid, uuid, uuid)
  to authenticated;

grant execute on function einvoice._official_view_command_id(uuid, integer)
  to service_role;
grant execute on function einvoice.load_official_view_operation_context(uuid, uuid)
  to service_role;
grant execute on function einvoice.record_official_invoice_view_result(
  uuid, uuid, text, bigint, uuid, text, text, timestamptz, text, text
) to service_role;
