-- Title: einvoice S2b — issuance schema + dispatch/result RPCs
-- Kind: patch
-- Intent: invoice_issuances/attempts/electronic_invoices/reconciliation_cases + issue/publish barrier/result landing
-- Context: TH-08 EP-02/US-02 + immediate-result US-04 subset; authoritative sales.* not yet available
-- Touches: einvoice.load_issuance_source_snapshot, einvoice.issue_invoice, einvoice.prepare_issuance_publish, einvoice.record_issuance_success, einvoice.record_issuance_failure, einvoice.record_issuance_command_integrity_failure, einvoice.record_issuance_undetermined, einvoice.get_order_invoice_projection
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped
-- Depends on: 001_einvoice_s1_schema_configuration.sql, 002_einvoice_s1_install_module_messaging.sql, 005_einvoice_s2a_schema.sql
--
-- contract: hash-key-order-independence — sha256(convert_to(jsonb::text,'UTF8')) ignores object key order
-- contract: hash-content-sensitivity — changed scalar values or array order fail prepare_issuance_publish with STATE_CHANGED

create table if not exists einvoice.invoice_issuances (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  sales_order_id uuid not null,
  issuance_type text not null default 'ORIGINAL'
    check (issuance_type in ('ORIGINAL')),
  settled_result text null
    check (settled_result is null or settled_result in ('ISSUED', 'FAILED')),
  successful_attempt_id uuid null,
  electronic_invoice_id uuid null,
  last_attempt_id uuid null,
  initiated_at timestamptz not null default now(),
  created_by_actor_type text not null
    check (created_by_actor_type in ('USER', 'SYSTEM')),
  created_by_actor_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, sales_order_id, issuance_type)
);

create table if not exists einvoice.issuance_attempts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  invoice_issuance_id uuid not null references einvoice.invoice_issuances(id),
  attempt_no integer not null,
  trigger_type text not null check (trigger_type in ('MANUAL', 'AUTOMATIC')),
  status text not null
    check (status in (
      'PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING', 'SUCCEEDED', 'FAILED'
    )),
  provider_connection_id uuid not null references einvoice.provider_connections(id),
  issuance_profile_id uuid not null references einvoice.issuance_profiles(id),
  idempotency_key varchar(150) not null,
  intent_hash varchar(128) not null,
  snapshot_schema_version integer not null,
  attempt_snapshot jsonb not null,
  canonical_model_version text not null,
  canonical_payload_hash varchar(128) not null,
  provider_interaction_reference varchar(255) null,
  provider_request_reference varchar(255) null,
  provider_invoice_reference varchar(255) null,
  provider_result_code varchar(100) null,
  provider_result_message text null,
  failure_code varchar(100) null,
  failure_message text null,
  internal_finalization_state text not null default 'PENDING'
    check (internal_finalization_state in ('PENDING', 'COMPLETED', 'UNRESOLVED')),
  started_at timestamptz not null default now(),
  submitted_at timestamptz null,
  provider_confirmed_at timestamptz null,
  completed_at timestamptz null,
  initiated_by_actor_type text not null
    check (initiated_by_actor_type in ('USER', 'SYSTEM')),
  initiated_by_actor_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (invoice_issuance_id, attempt_no),
  unique (tenant_id, idempotency_key)
);

create unique index if not exists issuance_attempts_one_active_idx
  on einvoice.issuance_attempts (invoice_issuance_id)
  where status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING');

create table if not exists einvoice.electronic_invoices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  invoice_issuance_id uuid not null references einvoice.invoice_issuances(id),
  successful_attempt_id uuid not null references einvoice.issuance_attempts(id),
  sales_order_id uuid not null,
  provider_connection_id uuid not null references einvoice.provider_connections(id),
  provider_invoice_reference varchar(255) not null,
  invoice_number varchar(100) not null,
  template_code varchar(100) not null,
  series varchar(100) not null,
  issued_at timestamptz not null,
  lookup_code varchar(255) null,
  tax_authority_code varchar(255) null,
  tax_authority_result jsonb null,
  snapshot_schema_version integer not null,
  invoice_snapshot jsonb not null,
  latest_provider_state_code varchar(100) null,
  last_provider_observed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, invoice_issuance_id),
  unique (tenant_id, sales_order_id)
);

create table if not exists einvoice.invoice_reconciliation_cases (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  target_type text not null check (
    target_type in ('ISSUANCE_ATTEMPT', 'ELECTRONIC_INVOICE', 'INVOICE_DOCUMENT', 'DELIVERY_ATTEMPT')
  ),
  target_id uuid not null,
  reconciliation_purpose text not null check (
    reconciliation_purpose in (
      'DETERMINE_RESULT', 'VERIFY_DOCUMENT', 'SYNC_PROVIDER_STATE', 'VERIFY_DELIVERY'
    )
  ),
  provider_connection_id uuid not null references einvoice.provider_connections(id),
  provider_reference varchar(255) null,
  idempotency_key varchar(150) null,
  reason_code varchar(100) not null,
  status text not null check (status in ('PENDING', 'RESOLVED', 'UNRESOLVED')),
  attempt_count integer not null default 0,
  next_check_at timestamptz null,
  last_checked_at timestamptz null,
  latest_provider_interaction_reference varchar(255) null,
  resolved_at timestamptz null,
  resolution_code varchar(100) null,
  resolution_snapshot jsonb null,
  last_error_code varchar(100) null,
  last_error_message text null,
  correlation_id varchar(100) not null,
  opened_by_actor_type text not null,
  opened_by_actor_id uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists invoice_reconciliation_cases_one_pending
  on einvoice.invoice_reconciliation_cases (tenant_id, target_type, target_id, reconciliation_purpose)
  where status = 'PENDING';

alter table einvoice.invoice_issuances enable row level security;
alter table einvoice.issuance_attempts enable row level security;
alter table einvoice.electronic_invoices enable row level security;
alter table einvoice.invoice_reconciliation_cases enable row level security;

create or replace function einvoice.load_issuance_source_snapshot(
  p_tenant_id uuid,
  p_sales_order_id uuid
) returns table(
  available boolean,
  source_version text,
  order_completed boolean,
  buyer_partner_id uuid,
  commercial_snapshot jsonb,
  buyer_snapshot jsonb,
  blockers jsonb
) language plpgsql security definer set search_path = einvoice, public as $$
begin
  -- TODO(Theme05): authoritative completed SalesOrder snapshot contract.
  -- Fail closed until Theme 05 lands — no placeholder commercial data.
  return query select
    false as available,
    null::text as source_version,
    false as order_completed,
    null::uuid as buyer_partner_id,
    '{}'::jsonb as commercial_snapshot,
    '{}'::jsonb as buyer_snapshot,
    jsonb_build_array('SOURCE_SNAPSHOT_UNAVAILABLE') as blockers;
end;
$$;

create or replace function einvoice.issue_invoice(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_source_version text,
  p_idempotency_key varchar(150),
  p_acknowledge_warnings boolean default false
) returns table(
  issuance_id uuid,
  attempt_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_intent jsonb;
  v_intent_hash text;
  v_existing einvoice.issuance_attempts%rowtype;
  v_source record;
  v_blockers jsonb := '[]'::jsonb;
  v_provider_connection_id uuid;
  v_issuance_profile_id uuid;
  v_issuance_id uuid;
  v_attempt_id uuid;
  v_attempt_no integer := 1;
  v_attempt_snapshot jsonb;
  v_canonical_jsonb jsonb;
  v_canonical_hash text;
  v_buyer_completion einvoice.buyer_invoice_completions%rowtype;
begin
  if p_source_version is null or btrim(p_source_version) = '' then
    raise exception 'VALIDATION_ERROR: source_version is required';
  end if;
  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  v_intent := jsonb_build_object(
    'operation','ISSUE_ORIGINAL',
    'sales_order_id',p_sales_order_id,
    'source_version',p_source_version,
    'acknowledge_warnings',coalesce(p_acknowledge_warnings, false)
  );
  v_intent_hash := encode(
    digest(convert_to(v_intent::text, 'UTF8'), 'sha256'),
    'hex'
  );

  select ia.*
  into v_existing
  from einvoice.issuance_attempts ia
  where ia.tenant_id = p_tenant_id
    and ia.idempotency_key = p_idempotency_key
  for update;

  if found then
    if v_existing.intent_hash = v_intent_hash then
      return query select
        v_existing.invoice_issuance_id,
        v_existing.id,
        v_existing.status;
      return;
    end if;
    raise exception 'IDEMPOTENCY_CONFLICT: same idempotency key with different business intent';
  end if;

  select *
  into v_source
  from einvoice.load_issuance_source_snapshot(p_tenant_id, p_sales_order_id)
  limit 1;

  if not coalesce(v_source.available, false) then
    v_blockers := coalesce(v_source.blockers, '[]'::jsonb);
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object('blockers', v_blockers)
    )::text;
  end if;

  if v_source.source_version is distinct from p_source_version then
    raise exception 'STATE_CHANGED: source version mismatch';
  end if;

  if not coalesce(v_source.order_completed, false) then
    raise exception 'ORDER_NOT_COMPLETED';
  end if;

  if exists (
    select 1
    from einvoice.electronic_invoices ei
    where ei.tenant_id = p_tenant_id
      and ei.sales_order_id = p_sales_order_id
  ) then
    raise exception 'ALREADY_ISSUED';
  end if;

  if exists (
    select 1
    from einvoice.invoice_issuances ii
    join einvoice.issuance_attempts ia on ia.invoice_issuance_id = ii.id
    where ii.tenant_id = p_tenant_id
      and ii.sales_order_id = p_sales_order_id
      and ia.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING')
  ) then
    raise exception 'OPERATION_IN_PROGRESS';
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
  limit 1;

  if v_provider_connection_id is null then
    raise exception 'CONFIG_NOT_READY';
  end if;

  select ip.id
  into v_issuance_profile_id
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
    and ip.default_template is not null
    and ip.default_signing is not null
  limit 1;

  if v_issuance_profile_id is null then
    raise exception 'CONFIG_NOT_READY';
  end if;

  select bc.*
  into v_buyer_completion
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id
    and bc.sales_order_id = p_sales_order_id
    and bc.sales_order_version = p_source_version
  for update;

  if found and v_buyer_completion.status = 'open' then
    -- TODO(Theme03): controlled buyer completion for eligible missing fields.
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('BUYER_SOURCE_UNAVAILABLE')
      )
    )::text;
  end if;

  insert into einvoice.invoice_issuances (
    tenant_id,
    sales_order_id,
    issuance_type,
    initiated_at,
    created_by_actor_type,
    created_by_actor_id
  ) values (
    p_tenant_id,
    p_sales_order_id,
    'ORIGINAL',
    now(),
    'USER',
    p_actor_id
  )
  on conflict (tenant_id, sales_order_id, issuance_type) do update set
    updated_at = now()
  returning id into v_issuance_id;

  if v_issuance_id is null then
    select ii.id
    into v_issuance_id
    from einvoice.invoice_issuances ii
    where ii.tenant_id = p_tenant_id
      and ii.sales_order_id = p_sales_order_id
      and ii.issuance_type = 'ORIGINAL';
  end if;

  select coalesce(max(ia.attempt_no), 0) + 1
  into v_attempt_no
  from einvoice.issuance_attempts ia
  where ia.invoice_issuance_id = v_issuance_id;

  v_attempt_snapshot := jsonb_build_object(
    'schemaVersion', 1,
    'salesOrderId', p_sales_order_id,
    'sourceVersion', p_source_version,
    'commercial', coalesce(v_source.commercial_snapshot, '{}'::jsonb),
    'buyer', coalesce(v_source.buyer_snapshot, '{}'::jsonb),
    'acknowledgeWarnings', coalesce(p_acknowledge_warnings, false)
  );

  v_canonical_jsonb := jsonb_build_object(
    'modelVersion', '1.0.0',
    'salesOrderId', p_sales_order_id,
    'sourceVersion', p_source_version,
    'buyer', coalesce(v_source.buyer_snapshot, '{}'::jsonb),
    'lines', coalesce(v_source.commercial_snapshot -> 'lines', '[]'::jsonb)
  );
  v_canonical_hash := encode(
    digest(convert_to(v_canonical_jsonb::text, 'UTF8'), 'sha256'),
    'hex'
  );

  insert into einvoice.issuance_attempts (
    tenant_id,
    invoice_issuance_id,
    attempt_no,
    trigger_type,
    status,
    provider_connection_id,
    issuance_profile_id,
    idempotency_key,
    intent_hash,
    snapshot_schema_version,
    attempt_snapshot,
    canonical_model_version,
    canonical_payload_hash,
    internal_finalization_state,
    initiated_by_actor_type,
    initiated_by_actor_id
  ) values (
    p_tenant_id,
    v_issuance_id,
    v_attempt_no,
    'MANUAL',
    'PREPARING',
    v_provider_connection_id,
    v_issuance_profile_id,
    p_idempotency_key,
    v_intent_hash,
    1,
    v_attempt_snapshot,
    '1.0.0',
    v_canonical_hash,
    'PENDING',
    'USER',
    p_actor_id
  )
  returning id into v_attempt_id;

  update einvoice.invoice_issuances
  set last_attempt_id = v_attempt_id,
      updated_at = now()
  where id = v_issuance_id;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.publish_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'attempt_id', v_attempt_id,
      'canonical_invoice', v_canonical_jsonb,
      'payload_hash', v_canonical_hash,
      'idempotency_key', p_idempotency_key
    ),
    p_source_event_id => v_attempt_id
  );

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.issuance.processing',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', p_sales_order_id,
      'issuance_id', v_issuance_id,
      'attempt_id', v_attempt_id,
      'status', 'PREPARING'
    )
  );

  return query select v_issuance_id, v_attempt_id, 'PREPARING'::text;
end;
$$;

create or replace function einvoice.prepare_issuance_publish(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_idempotency_key varchar(150),
  p_payload_hash varchar(128),
  p_canonical_payload jsonb
) returns table(action text) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_recomputed_hash text;
begin
  v_recomputed_hash := encode(
    digest(convert_to(p_canonical_payload::text, 'UTF8'), 'sha256'),
    'hex'
  );

  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  if v_attempt.idempotency_key <> p_idempotency_key then
    raise exception 'STATE_CHANGED: idempotency identity mismatch';
  end if;

  if v_recomputed_hash <> v_attempt.canonical_payload_hash
     or v_recomputed_hash <> p_payload_hash then
    raise exception 'STATE_CHANGED: canonical payload hash mismatch';
  end if;

  if v_attempt.status = 'PREPARING' then
    update einvoice.issuance_attempts
    set status = 'WAITING_RESULT',
        submitted_at = coalesce(submitted_at, now()),
        updated_at = now()
    where id = p_attempt_id;
    return query select 'CALL_PROVIDER'::text;
    return;
  end if;

  if v_attempt.status in ('SUBMITTED', 'WAITING_RESULT') then
    return query select 'RECONCILE_ONLY'::text;
    return;
  end if;

  if v_attempt.status in ('RECONCILING', 'SUCCEEDED', 'FAILED') then
    return query select 'SKIP'::text;
    return;
  end if;

  raise exception 'INVALID_STATUS: %', v_attempt.status;
end;
$$;

create or replace function einvoice.record_issuance_success(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_idempotency_key varchar(150),
  p_payload_hash varchar(128),
  p_provider_reference varchar(255),
  p_invoice_number varchar(100),
  p_invoice_series varchar(100),
  p_issued_at timestamptz
) returns table(
  attempt_status text,
  internal_finalization_state text,
  electronic_invoice_id uuid
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
  v_invoice_id uuid;
  v_invoice_snapshot jsonb;
begin
  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  if v_attempt.idempotency_key <> p_idempotency_key
     or v_attempt.canonical_payload_hash <> p_payload_hash then
    raise exception 'STATE_CHANGED: attempt identity mismatch';
  end if;

  if v_attempt.status in ('SUCCEEDED', 'FAILED') then
    select ei.id
    into v_invoice_id
    from einvoice.electronic_invoices ei
    where ei.successful_attempt_id = p_attempt_id
    limit 1;

    return query select
      v_attempt.status,
      v_attempt.internal_finalization_state,
      v_invoice_id;
    return;
  end if;

  if v_attempt.status not in ('WAITING_RESULT', 'RECONCILING', 'SUBMITTED') then
    raise exception 'INVALID_STATUS: %', v_attempt.status;
  end if;

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.id = v_attempt.invoice_issuance_id
    and ii.tenant_id = p_tenant_id;

  update einvoice.issuance_attempts
  set provider_invoice_reference = p_provider_reference,
      provider_request_reference = p_provider_reference,
      provider_result_code = 'SUCCESS',
      provider_result_message = p_invoice_number,
      provider_confirmed_at = now(),
      updated_at = now()
  where id = p_attempt_id;

  begin
    v_invoice_snapshot := jsonb_build_object(
      'schemaVersion', v_attempt.snapshot_schema_version,
      'attemptSnapshot', v_attempt.attempt_snapshot,
      'providerReference', p_provider_reference,
      'invoiceNumber', p_invoice_number,
      'series', p_invoice_series,
      'issuedAt', p_issued_at
    );

    insert into einvoice.electronic_invoices (
      tenant_id,
      invoice_issuance_id,
      successful_attempt_id,
      sales_order_id,
      provider_connection_id,
      provider_invoice_reference,
      invoice_number,
      template_code,
      series,
      issued_at,
      snapshot_schema_version,
      invoice_snapshot
    ) values (
      p_tenant_id,
      v_attempt.invoice_issuance_id,
      p_attempt_id,
      v_issuance.sales_order_id,
      v_attempt.provider_connection_id,
      p_provider_reference,
      p_invoice_number,
      coalesce(v_attempt.attempt_snapshot ->> 'templateCode', 'UNKNOWN'),
      p_invoice_series,
      p_issued_at,
      v_attempt.snapshot_schema_version,
      v_invoice_snapshot
    )
    on conflict (tenant_id, invoice_issuance_id) do update set
      updated_at = now()
    returning id into v_invoice_id;

    update einvoice.issuance_attempts
    set status = 'SUCCEEDED',
        internal_finalization_state = 'COMPLETED',
        completed_at = now(),
        updated_at = now()
    where id = p_attempt_id;

    update einvoice.invoice_issuances
    set settled_result = 'ISSUED',
        successful_attempt_id = p_attempt_id,
        electronic_invoice_id = v_invoice_id,
        updated_at = now()
    where id = v_attempt.invoice_issuance_id;

    perform einvoice.enqueue_outbox_message(
      p_tenant_id,
      'einvoice.electronic_invoice.registered',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'sales_order_id', v_issuance.sales_order_id,
        'issuance_id', v_attempt.invoice_issuance_id,
        'attempt_id', p_attempt_id,
        'electronic_invoice_id', v_invoice_id
      )
    );
  exception when others then
    update einvoice.issuance_attempts
    set status = 'SUCCEEDED',
        internal_finalization_state = 'UNRESOLVED',
        completed_at = coalesce(completed_at, now()),
        updated_at = now()
    where id = p_attempt_id;

    perform einvoice.enqueue_outbox_message(
      p_tenant_id,
      'einvoice.issuance.processing',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'sales_order_id', v_issuance.sales_order_id,
        'issuance_id', v_attempt.invoice_issuance_id,
        'attempt_id', p_attempt_id,
        'status', 'SUCCEEDED',
        'internal_finalization_state', 'UNRESOLVED'
      )
    );
  end;

  select ia.status, ia.internal_finalization_state
  into v_attempt.status, v_attempt.internal_finalization_state
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id;

  if v_invoice_id is null then
    select ei.id
    into v_invoice_id
    from einvoice.electronic_invoices ei
    where ei.successful_attempt_id = p_attempt_id
    limit 1;
  end if;

  return query select
    v_attempt.status,
    v_attempt.internal_finalization_state,
    v_invoice_id;
end;
$$;

create or replace function einvoice.record_issuance_failure(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_idempotency_key varchar(150),
  p_payload_hash varchar(128),
  p_provider_code varchar(100),
  p_provider_message text
) returns table(attempt_status text) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
begin
  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  if v_attempt.idempotency_key <> p_idempotency_key
     or v_attempt.canonical_payload_hash <> p_payload_hash then
    raise exception 'STATE_CHANGED: attempt identity mismatch';
  end if;

  if v_attempt.status = 'FAILED' then
    return query select v_attempt.status;
    return;
  end if;

  if v_attempt.status not in ('WAITING_RESULT', 'RECONCILING', 'SUBMITTED') then
    raise exception 'INVALID_STATUS: %', v_attempt.status;
  end if;

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.id = v_attempt.invoice_issuance_id;

  update einvoice.issuance_attempts
  set status = 'FAILED',
      provider_result_code = p_provider_code,
      provider_result_message = p_provider_message,
      failure_code = p_provider_code,
      failure_message = p_provider_message,
      completed_at = now(),
      updated_at = now()
  where id = p_attempt_id;

  update einvoice.invoice_issuances
  set settled_result = 'FAILED',
      updated_at = now()
  where id = v_attempt.invoice_issuance_id;

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.issuance.failed',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_issuance.sales_order_id,
      'issuance_id', v_attempt.invoice_issuance_id,
      'attempt_id', p_attempt_id,
      'failure_code', p_provider_code
    )
  );

  return query select 'FAILED'::text;
end;
$$;

create or replace function einvoice.record_issuance_command_integrity_failure(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_reason_code varchar(100)
) returns table(attempt_status text) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
begin
  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  if v_attempt.status = 'FAILED' then
    return query select v_attempt.status;
    return;
  end if;

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.id = v_attempt.invoice_issuance_id;

  update einvoice.issuance_attempts
  set status = 'FAILED',
      failure_code = 'COMMAND_INTEGRITY',
      failure_message = p_reason_code,
      provider_interaction_reference = null,
      provider_request_reference = null,
      provider_invoice_reference = null,
      provider_result_code = null,
      provider_result_message = null,
      completed_at = now(),
      updated_at = now()
  where id = p_attempt_id;

  update einvoice.invoice_issuances
  set settled_result = 'FAILED',
      updated_at = now()
  where id = v_attempt.invoice_issuance_id;

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.issuance.failed',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_issuance.sales_order_id,
      'issuance_id', v_attempt.invoice_issuance_id,
      'attempt_id', p_attempt_id,
      'failure_code', 'COMMAND_INTEGRITY',
      'reason_code', p_reason_code
    )
  );

  return query select 'FAILED'::text;
end;
$$;

create or replace function einvoice.record_issuance_undetermined(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_idempotency_key varchar(150),
  p_payload_hash varchar(128),
  p_reason_code varchar(100)
) returns table(
  attempt_status text,
  reconciliation_case_id uuid,
  correlation_id varchar(100)
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
  v_case_id uuid;
  v_case_correlation_id varchar(100);
  v_existing_case einvoice.invoice_reconciliation_cases%rowtype;
begin
  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = p_attempt_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  if v_attempt.idempotency_key <> p_idempotency_key
     or v_attempt.canonical_payload_hash <> p_payload_hash then
    raise exception 'STATE_CHANGED: attempt identity mismatch';
  end if;

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.id = v_attempt.invoice_issuance_id;

  if v_attempt.status = 'RECONCILING' then
    select irc.*
    into v_existing_case
    from einvoice.invoice_reconciliation_cases irc
    where irc.tenant_id = p_tenant_id
      and irc.target_type = 'ISSUANCE_ATTEMPT'
      and irc.target_id = p_attempt_id
      and irc.reconciliation_purpose = 'DETERMINE_RESULT'
      and irc.status = 'PENDING'
    limit 1;

    return query select
      v_attempt.status,
      v_existing_case.id,
      v_existing_case.correlation_id;
    return;
  end if;

  if v_attempt.status not in ('WAITING_RESULT', 'SUBMITTED') then
    raise exception 'INVALID_STATUS: %', v_attempt.status;
  end if;

  update einvoice.issuance_attempts
  set status = 'RECONCILING',
      failure_code = null,
      failure_message = null,
      updated_at = now()
  where id = p_attempt_id;

  select irc.*
  into v_existing_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.tenant_id = p_tenant_id
    and irc.target_type = 'ISSUANCE_ATTEMPT'
    and irc.target_id = p_attempt_id
    and irc.reconciliation_purpose = 'DETERMINE_RESULT'
    and irc.status = 'PENDING'
  for update;

  if found then
    v_case_id := v_existing_case.id;
    v_case_correlation_id := v_existing_case.correlation_id;
  else
    v_case_id := gen_random_uuid();
    v_case_correlation_id := 'einvoice:reconcile:' || v_case_id::text;

    insert into einvoice.invoice_reconciliation_cases (
      id,
      tenant_id,
      target_type,
      target_id,
      reconciliation_purpose,
      provider_connection_id,
      idempotency_key,
      reason_code,
      status,
      attempt_count,
      next_check_at,
      correlation_id,
      opened_by_actor_type,
      opened_by_actor_id
    ) values (
      v_case_id,
      p_tenant_id,
      'ISSUANCE_ATTEMPT',
      p_attempt_id,
      'DETERMINE_RESULT',
      v_attempt.provider_connection_id,
      p_idempotency_key,
      p_reason_code,
      'PENDING',
      0,
      now() + interval '30 seconds',
      v_case_correlation_id,
      'SYSTEM',
      null
    );
  end if;

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.issuance.processing',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_issuance.sales_order_id,
      'issuance_id', v_attempt.invoice_issuance_id,
      'attempt_id', p_attempt_id,
      'status', 'RECONCILING',
      'reconciliation_case_id', v_case_id
    )
  );

  return query select 'RECONCILING'::text, v_case_id, v_case_correlation_id;
end;
$$;

create or replace function einvoice.get_order_invoice_projection(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  sales_order_id uuid,
  issuance_display_state text,
  actions jsonb
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_issuance einvoice.invoice_issuances%rowtype;
  v_attempt einvoice.issuance_attempts%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
begin
  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.tenant_id = p_tenant_id
    and ii.sales_order_id = p_sales_order_id
    and ii.issuance_type = 'ORIGINAL'
  limit 1;

  if not found then
    return query select
      p_sales_order_id,
      'notIssued'::text,
      jsonb_build_array('issue');
    return;
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.invoice_issuance_id = v_issuance.id
  limit 1;

  if found then
    return query select
      p_sales_order_id,
      'issued'::text,
      jsonb_build_array('view');
    return;
  end if;

  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.invoice_issuance_id = v_issuance.id
  order by ia.attempt_no desc
  limit 1;

  if not found then
    return query select
      p_sales_order_id,
      'notIssued'::text,
      jsonb_build_array('issue');
    return;
  end if;

  if v_attempt.status = 'FAILED' then
    return query select
      p_sales_order_id,
      'failed'::text,
      jsonb_build_array('issue');
    return;
  end if;

  if v_attempt.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING')
     or (v_attempt.status = 'SUCCEEDED' and v_attempt.internal_finalization_state = 'UNRESOLVED') then
    return query select
      p_sales_order_id,
      'processing'::text,
      '[]'::jsonb;
    return;
  end if;

  return query select
    p_sales_order_id,
    'processing'::text,
    '[]'::jsonb;
end;
$$;

revoke all on table einvoice.invoice_issuances from anon, authenticated;
revoke all on table einvoice.issuance_attempts from anon, authenticated;
revoke all on table einvoice.electronic_invoices from anon, authenticated;
revoke all on table einvoice.invoice_reconciliation_cases from anon, authenticated;

grant execute on function einvoice.load_issuance_source_snapshot(uuid, uuid) to service_role;
grant execute on function einvoice.issue_invoice(uuid, uuid, uuid, text, varchar, boolean) to service_role;
grant execute on function einvoice.prepare_issuance_publish(uuid, uuid, varchar, varchar, jsonb) to service_role;
grant execute on function einvoice.record_issuance_success(uuid, uuid, varchar, varchar, varchar, varchar, varchar, timestamptz) to service_role;
grant execute on function einvoice.record_issuance_failure(uuid, uuid, varchar, varchar, varchar, text) to service_role;
grant execute on function einvoice.record_issuance_command_integrity_failure(uuid, uuid, varchar) to service_role;
grant execute on function einvoice.record_issuance_undetermined(uuid, uuid, varchar, varchar, varchar) to service_role;
grant execute on function einvoice.get_order_invoice_projection(uuid, uuid, uuid) to service_role;
