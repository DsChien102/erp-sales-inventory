-- Title: einvoice S4c provider interactions and observations
-- Kind: patch
-- Intent: einvoice_s4c_provider_observations
-- Context: TH-08 / EP-03 / US-03
-- Touches: _provider_observation_command_id, get_latest_provider_observation, load_provider_observation_context, record_provider_interaction_result, record_provider_observation, request_provider_observation_refresh, start_provider_interaction
-- Safety: idempotent ; medium
-- Depends on: 001_einvoice_configuration_schema.sql, 002_einvoice_install_module_messaging.sql, 007_einvoice_issuance_schema_and_publish_rpcs.sql, 009_einvoice_issuance_reconciliation_rpcs.sql

create table if not exists einvoice.invoice_provider_observations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  electronic_invoice_id uuid not null,
  provider_state_code text not null,
  provider_state_description text null,
  provider_reference text null,
  observed_at timestamptz not null,
  deduplication_key text not null,
  details_snapshot jsonb not null default '{}'::jsonb,
  provider_interaction_reference uuid not null,
  created_at timestamptz not null default now(),
  unique (tenant_id, deduplication_key),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id),
  foreign key (tenant_id, provider_interaction_reference)
    references einvoice.provider_interaction_records (tenant_id, id)
);

alter table einvoice.invoice_provider_observations enable row level security;
revoke all on einvoice.invoice_provider_observations from anon, authenticated;

create or replace function einvoice._provider_observation_command_id(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_discriminator text
) returns uuid
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_hex text;
begin
  v_raw :=
    p_tenant_id::text || '|' ||
    p_electronic_invoice_id::text || '|' ||
    p_discriminator;
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

create or replace function einvoice._validate_observation_details_snapshot(
  p_details_snapshot jsonb
) returns void
language plpgsql
immutable
as $$
declare
  v_key text;
  v_allowed constant text[] := array[
    'publishStatus',
    'eInvoiceStatus',
    'referenceType',
    'sendTaxStatus',
    'invoiceCode',
    'invNo',
    'invSeries',
    'publishedTime',
    'transactionId'
  ];
begin
  if p_details_snapshot is null then
    return;
  end if;
  for v_key in select jsonb_object_keys(p_details_snapshot) loop
    if not (v_key = any (v_allowed)) then
      raise exception 'VALIDATION_ERROR: details_snapshot key not allowed: %', v_key;
    end if;
  end loop;
end;
$$;

create or replace function einvoice.start_provider_interaction(
  p_tenant_id uuid,
  p_provider_connection_id uuid,
  p_direction text,
  p_operation_type text,
  p_target_type text,
  p_target_id uuid,
  p_correlation_id uuid,
  p_request_reference varchar(255)
) returns table(
  interaction_reference uuid,
  tenant_id uuid,
  version bigint,
  provider_connection_id uuid,
  direction text,
  operation_type text,
  target_type text,
  target_id uuid,
  correlation_id uuid,
  request_reference varchar(255),
  response_reference varchar(255),
  provider_reference varchar(255),
  status text,
  outcome text,
  safe_error_code varchar(100),
  started_at timestamptz,
  completed_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_row einvoice.provider_interaction_records%rowtype;
begin
  if p_direction not in ('OUTBOUND', 'INBOUND_CALLBACK') then
    raise exception 'VALIDATION_ERROR: invalid direction %', p_direction;
  end if;

  if not exists (
    select 1
    from einvoice.provider_connections pc
    where pc.id = p_provider_connection_id
      and pc.tenant_id = p_tenant_id
  ) then
    raise exception 'NOT_FOUND: provider connection';
  end if;

  select pir.*
  into v_row
  from einvoice.provider_interaction_records pir
  where pir.tenant_id = p_tenant_id
    and pir.correlation_id = p_correlation_id
    and pir.operation_type = p_operation_type;

  if found then
    return query select
      v_row.id,
      v_row.tenant_id,
      v_row.version,
      v_row.provider_connection_id,
      v_row.direction,
      v_row.operation_type,
      v_row.target_type,
      v_row.target_id,
      v_row.correlation_id,
      v_row.request_reference,
      v_row.response_reference,
      v_row.provider_reference,
      v_row.status,
      v_row.outcome,
      v_row.safe_error_code,
      v_row.started_at,
      v_row.completed_at;
    return;
  end if;

  insert into einvoice.provider_interaction_records (
    tenant_id,
    version,
    provider_connection_id,
    direction,
    operation_type,
    target_type,
    target_id,
    correlation_id,
    request_reference,
    status,
    started_at
  ) values (
    p_tenant_id,
    0,
    p_provider_connection_id,
    p_direction,
    p_operation_type,
    p_target_type,
    p_target_id,
    p_correlation_id,
    p_request_reference,
    'STARTED',
    now()
  )
  returning * into v_row;

  return query select
    v_row.id,
    v_row.tenant_id,
    v_row.version,
    v_row.provider_connection_id,
    v_row.direction,
    v_row.operation_type,
    v_row.target_type,
    v_row.target_id,
    v_row.correlation_id,
    v_row.request_reference,
    v_row.response_reference,
    v_row.provider_reference,
    v_row.status,
    v_row.outcome,
    v_row.safe_error_code,
    v_row.started_at,
    v_row.completed_at;
end;
$$;

create or replace function einvoice.record_provider_interaction_result(
  p_tenant_id uuid,
  p_interaction_reference uuid,
  p_expected_version bigint,
  p_outcome text,
  p_response_reference varchar(255) default null,
  p_provider_reference varchar(255) default null,
  p_safe_error_code varchar(100) default null
) returns table(
  interaction_reference uuid,
  tenant_id uuid,
  version bigint,
  provider_connection_id uuid,
  direction text,
  operation_type text,
  target_type text,
  target_id uuid,
  correlation_id uuid,
  request_reference varchar(255),
  response_reference varchar(255),
  provider_reference varchar(255),
  status text,
  outcome text,
  safe_error_code varchar(100),
  started_at timestamptz,
  completed_at timestamptz
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_row einvoice.provider_interaction_records%rowtype;
begin
  if p_outcome not in (
    'SUCCEEDED', 'DEFINITE_FAILURE', 'TIMEOUT', 'UNAVAILABLE',
    'NOT_FOUND', 'MISMATCH', 'CHECK_REQUIRED'
  ) then
    raise exception 'VALIDATION_ERROR: invalid outcome %', p_outcome;
  end if;

  select pir.*
  into v_row
  from einvoice.provider_interaction_records pir
  where pir.id = p_interaction_reference
    and pir.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: provider interaction';
  end if;

  if v_row.status = 'COMPLETED' then
    if v_row.outcome = p_outcome
       and v_row.response_reference is not distinct from p_response_reference
       and v_row.provider_reference is not distinct from p_provider_reference
       and v_row.safe_error_code is not distinct from p_safe_error_code then
      return query select
        v_row.id,
        v_row.tenant_id,
        v_row.version,
        v_row.provider_connection_id,
        v_row.direction,
        v_row.operation_type,
        v_row.target_type,
        v_row.target_id,
        v_row.correlation_id,
        v_row.request_reference,
        v_row.response_reference,
        v_row.provider_reference,
        v_row.status,
        v_row.outcome,
        v_row.safe_error_code,
        v_row.started_at,
        v_row.completed_at;
      return;
    end if;
    raise exception 'INTERACTION_RESULT_CONFLICT: interaction already finalized';
  end if;

  if v_row.version <> p_expected_version then
    raise exception 'STATE_CHANGED: interaction version mismatch';
  end if;

  update einvoice.provider_interaction_records pir
  set
    version = pir.version + 1,
    status = 'COMPLETED',
    outcome = p_outcome,
    response_reference = p_response_reference,
    provider_reference = p_provider_reference,
    safe_error_code = p_safe_error_code,
    completed_at = now(),
    updated_at = now()
  where pir.id = p_interaction_reference
    and pir.tenant_id = p_tenant_id
    and pir.version = p_expected_version
  returning * into v_row;

  if not found then
    raise exception 'STATE_CHANGED: interaction version mismatch';
  end if;

  return query select
    v_row.id,
    v_row.tenant_id,
    v_row.version,
    v_row.provider_connection_id,
    v_row.direction,
    v_row.operation_type,
    v_row.target_type,
    v_row.target_id,
    v_row.correlation_id,
    v_row.request_reference,
    v_row.response_reference,
    v_row.provider_reference,
    v_row.status,
    v_row.outcome,
    v_row.safe_error_code,
    v_row.started_at,
    v_row.completed_at;
end;
$$;

create or replace function einvoice.request_provider_observation_refresh(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_trigger_id uuid,
  p_trigger_source text,
  p_requested_by text
) returns table(command_id uuid, replayed boolean)
language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_dedupe_key text;
  v_cmd_id uuid;
  v_inserted integer := 0;
begin
  if p_trigger_source not in ('POLICY', 'SUPPORT') then
    raise exception 'VALIDATION_ERROR: invalid trigger source %', p_trigger_source;
  end if;

  if p_requested_by is null or btrim(p_requested_by) = '' then
    raise exception 'VALIDATION_ERROR: requested_by is required';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = p_electronic_invoice_id;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice';
  end if;

  if v_invoice.provider_invoice_reference is null
     or btrim(v_invoice.provider_invoice_reference) = '' then
    raise exception 'VALIDATION_ERROR: provider reference missing';
  end if;

  v_dedupe_key :=
    'provider_observation:' ||
    p_tenant_id::text || ':' ||
    p_electronic_invoice_id::text || ':' ||
    p_trigger_id::text;
  v_cmd_id := einvoice._provider_observation_command_id(
    p_tenant_id,
    p_electronic_invoice_id,
    v_dedupe_key
  );

  insert into einvoice.internal_commands (
    id, tenant_id, command_type, payload, source_event_id, enqueued_at
  ) values (
    v_cmd_id,
    p_tenant_id,
    'einvoice.poll_provider_observation',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'electronic_invoice_id', p_electronic_invoice_id,
      'provider_connection_id', v_invoice.provider_connection_id,
      'trigger_id', p_trigger_id,
      'correlation_id', v_cmd_id
    ),
    p_trigger_id,
    now()
  ) on conflict (id) do nothing;

  get diagnostics v_inserted = row_count;

  return query select v_cmd_id, v_inserted = 0;
end;
$$;

create or replace function einvoice.load_provider_observation_context(
  p_tenant_id uuid,
  p_command_id uuid
) returns table(
  command_id uuid,
  tenant_id uuid,
  electronic_invoice_id uuid,
  provider_connection_id uuid,
  provider_invoice_reference varchar(255),
  invoice_series varchar(100),
  trigger_id uuid,
  correlation_id uuid
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_cmd einvoice.internal_commands%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
begin
  select ic.*
  into v_cmd
  from einvoice.internal_commands ic
  where ic.id = p_command_id
    and ic.tenant_id = p_tenant_id
    and ic.command_type = 'einvoice.poll_provider_observation';

  if not found then
    raise exception 'NOT_FOUND: observation command';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = (v_cmd.payload ->> 'electronic_invoice_id')::uuid;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice';
  end if;

  return query select
    v_cmd.id,
    v_cmd.tenant_id,
    v_invoice.id,
    v_invoice.provider_connection_id,
    v_invoice.provider_invoice_reference,
    v_invoice.series,
    (v_cmd.payload ->> 'trigger_id')::uuid,
    (v_cmd.payload ->> 'correlation_id')::uuid;
end;
$$;

create or replace function einvoice.record_provider_observation(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_provider_state_code text,
  p_provider_state_description text,
  p_provider_reference text,
  p_observed_at timestamptz,
  p_deduplication_key text,
  p_details_snapshot jsonb,
  p_provider_interaction_reference uuid
) returns table(
  observation_id uuid,
  electronic_invoice_id uuid,
  provider_state_code text,
  observed_at timestamptz,
  provider_state_description text,
  provider_reference text,
  correlation_id uuid,
  details_snapshot jsonb,
  replayed boolean
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_interaction einvoice.provider_interaction_records%rowtype;
  v_observation_id uuid;
  v_replayed boolean := false;
  v_correlation_id uuid;
begin
  perform einvoice._validate_observation_details_snapshot(p_details_snapshot);

  select pir.*
  into v_interaction
  from einvoice.provider_interaction_records pir
  where pir.id = p_provider_interaction_reference
    and pir.tenant_id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND: provider interaction';
  end if;

  if v_interaction.status <> 'COMPLETED' then
    raise exception 'VALIDATION_ERROR: interaction not finalized';
  end if;

  v_correlation_id := v_interaction.correlation_id;

  insert into einvoice.invoice_provider_observations (
    tenant_id,
    electronic_invoice_id,
    provider_state_code,
    provider_state_description,
    provider_reference,
    observed_at,
    deduplication_key,
    details_snapshot,
    provider_interaction_reference
  ) values (
    p_tenant_id,
    p_electronic_invoice_id,
    p_provider_state_code,
    p_provider_state_description,
    p_provider_reference,
    p_observed_at,
    p_deduplication_key,
    coalesce(p_details_snapshot, '{}'::jsonb),
    p_provider_interaction_reference
  )
  on conflict (tenant_id, deduplication_key) do nothing
  returning id into v_observation_id;

  if v_observation_id is null then
    v_replayed := true;
    select ipo.id
    into v_observation_id
    from einvoice.invoice_provider_observations ipo
    where ipo.tenant_id = p_tenant_id
      and ipo.deduplication_key = p_deduplication_key;
  end if;

  update einvoice.electronic_invoices ei
  set
    latest_provider_state_code = p_provider_state_code,
    last_provider_observed_at = p_observed_at,
    updated_at = now()
  where ei.tenant_id = p_tenant_id
    and ei.id = p_electronic_invoice_id
    and (
      ei.last_provider_observed_at is null
      or ei.last_provider_observed_at < p_observed_at
    );

  if p_provider_state_code in ('NOT_FOUND', 'MISMATCH') then
    insert into einvoice.outbox_messages (
      id, tenant_id, event_type, payload, occurred_at
    ) values (
      einvoice._provider_observation_command_id(
        p_tenant_id,
        p_electronic_invoice_id,
        'attention:' || p_deduplication_key
      ),
      p_tenant_id,
      'einvoice.provider_observation_attention_required',
      jsonb_build_object(
        'observation_id', v_observation_id,
        'electronic_invoice_id', p_electronic_invoice_id,
        'provider_state_code', p_provider_state_code,
        'provider_interaction_reference', p_provider_interaction_reference
      ),
      p_observed_at
    ) on conflict (id) do nothing;
  end if;

  return query select
    v_observation_id,
    p_electronic_invoice_id,
    p_provider_state_code,
    p_observed_at,
    p_provider_state_description,
    p_provider_reference,
    v_correlation_id,
    coalesce(p_details_snapshot, '{}'::jsonb),
    v_replayed;
end;
$$;

create or replace function einvoice.get_latest_provider_observation(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  observation_id uuid,
  electronic_invoice_id uuid,
  provider_state_code text,
  observed_at timestamptz,
  provider_state_description text,
  provider_reference text,
  correlation_id uuid,
  details_snapshot jsonb
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
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

  return query
  select
    ipo.id,
    ipo.electronic_invoice_id,
    ipo.provider_state_code,
    ipo.observed_at,
    ipo.provider_state_description,
    ipo.provider_reference,
    pir.correlation_id,
    ipo.details_snapshot
  from einvoice.invoice_provider_observations ipo
  left join einvoice.provider_interaction_records pir
    on pir.tenant_id = ipo.tenant_id
    and pir.id = ipo.provider_interaction_reference
  where ipo.tenant_id = p_tenant_id
    and ipo.electronic_invoice_id = v_invoice.id
  order by ipo.observed_at desc, ipo.created_at desc
  limit 1;
end;
$$;

revoke all on function einvoice._provider_observation_command_id(uuid, uuid, text)
  from public, anon, authenticated;
revoke all on function einvoice._validate_observation_details_snapshot(jsonb)
  from public, anon, authenticated;
revoke all on function einvoice.start_provider_interaction(
  uuid, uuid, text, text, text, uuid, uuid, varchar
) from public, anon, authenticated;
revoke all on function einvoice.record_provider_interaction_result(
  uuid, uuid, bigint, text, varchar, varchar, varchar
) from public, anon, authenticated;
revoke all on function einvoice.request_provider_observation_refresh(
  uuid, uuid, uuid, text, text
) from public, anon, authenticated;
revoke all on function einvoice.load_provider_observation_context(uuid, uuid)
  from public, anon, authenticated;
revoke all on function einvoice.record_provider_observation(
  uuid, uuid, text, text, text, timestamptz, text, jsonb, uuid
) from public, anon, authenticated;
revoke all on function einvoice.get_latest_provider_observation(uuid, uuid, uuid)
  from public, anon, authenticated;

grant execute on function einvoice._provider_observation_command_id(uuid, uuid, text)
  to service_role;
grant execute on function einvoice.start_provider_interaction(
  uuid, uuid, text, text, text, uuid, uuid, varchar
) to service_role;
grant execute on function einvoice.record_provider_interaction_result(
  uuid, uuid, bigint, text, varchar, varchar, varchar
) to service_role;
grant execute on function einvoice.request_provider_observation_refresh(
  uuid, uuid, uuid, text, text
) to service_role;
grant execute on function einvoice.load_provider_observation_context(uuid, uuid)
  to service_role;
grant execute on function einvoice.record_provider_observation(
  uuid, uuid, text, text, text, timestamptz, text, jsonb, uuid
) to service_role;
grant execute on function einvoice.get_latest_provider_observation(uuid, uuid, uuid)
  to authenticated;
