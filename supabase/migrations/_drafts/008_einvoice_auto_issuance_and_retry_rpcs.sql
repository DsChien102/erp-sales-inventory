-- Title: einvoice S3a/S3c — automatic trigger process records + start helper & retry transactions
-- Kind: cohesive
-- Intent: einvoice_s3_start_and_retry
-- Touches: einvoice.issuance_attempts, einvoice.automatic_trigger_process_records, einvoice._start_issuance_attempt, einvoice.issue_invoice, einvoice.start_auto_issuance, einvoice.list_open_auto_issuance_processes, einvoice.reevaluate_auto_issuance, einvoice.retry_issuance
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped
-- Depends on: 001_einvoice_configuration_schema.sql, 002_einvoice_install_module_messaging.sql, 005_einvoice_buyer_completion_and_preview_schema.sql, 007_einvoice_issuance_schema_and_publish_rpcs.sql

-- 1. einvoice.automatic_trigger_process_records table
create table if not exists einvoice.automatic_trigger_process_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  process_type text not null check (process_type in ('SALES_ORDER_COMPLETED')),
  sales_order_id uuid not null,
  sales_order_version text not null,
  trigger_key varchar(255) not null,
  provider_idempotency_key varchar(150) not null,
  process_status text not null check (
    process_status in ('PENDING_REEVALUATION', 'ATTEMPT_STARTED', 'SKIPPED')
  ),
  retry_count integer not null default 0,
  next_retry_at timestamptz null,
  blocker_code varchar(100) null,
  buyer_invoice_completion_id uuid null references einvoice.buyer_invoice_completions(id),
  claimed_at timestamptz null,
  claim_token varchar(100) null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 0,
  unique (tenant_id, sales_order_id, sales_order_version, process_type),
  unique (tenant_id, trigger_key)
);

create index if not exists auto_trigger_process_open_idx
  on einvoice.automatic_trigger_process_records (tenant_id, process_status, sales_order_id)
  where process_status = 'PENDING_REEVALUATION';

alter table einvoice.automatic_trigger_process_records enable row level security;

-- 2. einvoice._start_issuance_attempt (private helper)
create or replace function einvoice._start_issuance_attempt(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_source_version text,
  p_trigger_type text,
  p_idempotency_key varchar(150),
  p_intent_hash text,
  p_actor_type text,
  p_actor_id uuid,
  p_provider_connection_id uuid,
  p_issuance_profile_id uuid,
  p_buyer_partner_id uuid,
  p_buyer_snapshot jsonb,
  p_commercial_snapshot jsonb,
  p_acknowledge_warnings boolean default false,
  p_buyer_completion_id uuid default null
) returns table(
  issuance_id uuid,
  attempt_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, extensions, public as $$
declare
  v_issuance_id uuid;
  v_attempt_id uuid;
  v_attempt_no integer := 1;
  v_attempt_snapshot jsonb;
  v_canonical_jsonb jsonb;
  v_canonical_hash text;
  v_invoice_series text;
  v_invoice_with_code boolean;
  v_is_invoice_summary boolean;
  v_sign_type smallint;
  v_base_buyer_snapshot jsonb;
  v_effective_buyer jsonb;
  v_completion_values jsonb := '{}'::jsonb;
begin
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
    p_actor_type,
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

  -- Source-owned Theme-05 base BuyerInvoiceSnapshot, captured before any
  -- buyer-completion merge produces the effective buyer.
  v_base_buyer_snapshot := coalesce(p_buyer_snapshot, '{}'::jsonb);

  -- EffectiveBuyerInvoiceData cho payload; lineage giữ base nguyên bản (S5 freeze)
  select coalesce(bc.resolved_values, '{}'::jsonb)
  into v_completion_values
  from einvoice.buyer_invoice_completions bc
  where bc.id = p_buyer_completion_id;

  v_effective_buyer := v_base_buyer_snapshot || jsonb_strip_nulls(
    jsonb_build_object(
      'buyerLegalName',  nullif(btrim(coalesce(v_completion_values ->> 'name', '')), ''),
      'buyerTaxCode',    nullif(btrim(coalesce(v_completion_values ->> 'taxCode', '')), ''),
      'buyerEmail',      nullif(btrim(coalesce(v_completion_values ->> 'email', '')), ''),
      'buyerAddress',    nullif(btrim(coalesce(v_completion_values ->> 'address', '')), '')
    ));

  v_attempt_snapshot := jsonb_build_object(
    'schemaVersion', 1,
    'source_order', jsonb_build_object(
      'salesOrderId', p_sales_order_id,
      'sourceVersion', p_source_version,
      'status', 'COMPLETED'
    ),
    'seller', coalesce(p_commercial_snapshot -> 'seller', '{}'::jsonb),
    'buyer', v_effective_buyer,
    'buyer_lineage', jsonb_build_object(
      'buyerPartnerId', p_buyer_partner_id,
      'buyerInvoiceCompletionId', p_buyer_completion_id,
      'buyerInvoiceSnapshotSourceVersion', p_source_version,
      'buyerInvoiceSnapshot', v_base_buyer_snapshot
    ),
    'invoice_context', jsonb_build_object(
      'issuanceProfileId', p_issuance_profile_id,
      'providerConnectionId', p_provider_connection_id
    ),
    'lines', coalesce(p_commercial_snapshot -> 'lines', '[]'::jsonb),
    'totals', coalesce(p_commercial_snapshot -> 'totals', '{}'::jsonb),
    'payment_information', null,
    'automation_policy', jsonb_build_object(
      'acknowledgeWarnings', coalesce(p_acknowledge_warnings, false)
    ),
    'readiness_result', jsonb_build_object('blockers', '[]'::jsonb),
    'mapping_schema_version', '1.0.0'
  );

  v_canonical_jsonb := einvoice.build_canonical_invoice(
    p_tenant_id,
    p_sales_order_id,
    p_source_version,
    v_effective_buyer,
    p_commercial_snapshot
  );

  v_invoice_series := nullif(
    upper(btrim(v_canonical_jsonb ->> 'invSeries')),
    ''
  );
  if v_invoice_series is null
     or v_invoice_series !~ '^[1256][CK].{2}[TM]'
     or jsonb_typeof(v_canonical_jsonb -> 'invoiceWithCode') is distinct from 'boolean'
     or jsonb_typeof(v_canonical_jsonb -> 'isInvoiceSummary') is distinct from 'boolean'
     or jsonb_typeof(v_canonical_jsonb -> 'signType') is distinct from 'number' then
    raise exception 'STATE_INVALID: canonical provider contract is missing or malformed';
  end if;

  v_invoice_with_code := (v_canonical_jsonb ->> 'invoiceWithCode')::boolean;
  v_is_invoice_summary := (v_canonical_jsonb ->> 'isInvoiceSummary')::boolean;
  v_sign_type := (v_canonical_jsonb ->> 'signType')::smallint;

  if v_sign_type not in (2, 5)
     or v_invoice_with_code is distinct from (substr(v_invoice_series, 2, 1) = 'C')
     or v_sign_type is distinct from (
       case
         when substr(v_invoice_series, 5, 1) = 'M' then 5
         else 2
       end
     ) then
    raise exception 'STATE_INVALID: canonical provider contract is inconsistent';
  end if;

  v_attempt_snapshot := v_attempt_snapshot || jsonb_build_object(
    'provider_contract', jsonb_build_object(
      'invoice_series', v_invoice_series,
      'invoice_with_code', v_invoice_with_code,
      'is_invoice_summary', v_is_invoice_summary,
      'sign_type', v_sign_type
    )
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
    invoice_series,
    invoice_with_code,
    is_invoice_summary,
    sign_type,
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
    p_trigger_type,
    'PREPARING',
    p_provider_connection_id,
    p_issuance_profile_id,
    v_invoice_series,
    v_invoice_with_code,
    v_is_invoice_summary,
    v_sign_type,
    p_idempotency_key,
    p_intent_hash,
    1,
    v_attempt_snapshot,
    '1.0.0',
    v_canonical_hash,
    'PENDING',
    p_actor_type,
    p_actor_id
  )
  returning id into v_attempt_id;

  update einvoice.invoice_issuances
  set last_attempt_id = v_attempt_id,
      settled_result = null,
      version = version + 1,
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

revoke all on function einvoice._start_issuance_attempt(
  uuid, uuid, text, text, varchar, text, text, uuid, uuid, uuid, uuid, jsonb, jsonb, boolean, uuid
) from public;

-- 3. einvoice.issue_invoice
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
) language plpgsql security definer set search_path = einvoice, iam, sales, extensions, public as $$
declare
  v_intent jsonb;
  v_intent_hash text;
  v_existing einvoice.issuance_attempts%rowtype;
  v_source record;
  v_provider_connection_id uuid;
  v_issuance_profile_id uuid;
  v_issuance_id uuid;
  v_buyer_completion einvoice.buyer_invoice_completions%rowtype;
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.issue')
       and not iam.has_permission(p_tenant_id, 'einvoice.manage_issuance') then
      raise exception 'NO_PERMISSION: einvoice.issue required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  if p_source_version is null or btrim(p_source_version) = '' then
    raise exception 'VALIDATION_ERROR: source_version is required';
  end if;
  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  v_intent := jsonb_build_object(
    'operation', 'ISSUE_ORIGINAL',
    'sales_order_id', p_sales_order_id,
    'source_version', p_source_version,
    'acknowledge_warnings', coalesce(p_acknowledge_warnings, false)
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
    if v_existing.intent_hash <> v_intent_hash then
      raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
    end if;

    select ii.id
    into v_issuance_id
    from einvoice.invoice_issuances ii
    where ii.id = v_existing.invoice_issuance_id
      and ii.tenant_id = p_tenant_id;

    return query select v_issuance_id, v_existing.id, v_existing.status;
    return;
  end if;

  select s.*
  into v_source
  from einvoice.load_issuance_source_snapshot(p_tenant_id, p_sales_order_id) s;

  if not coalesce(v_source.available, false) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', coalesce(v_source.blockers, jsonb_build_array('SOURCE_SNAPSHOT_UNAVAILABLE'))
      )
    )::text;
  end if;

  if v_source.source_version <> p_source_version then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('SOURCE_VERSION_MISMATCH')
      )
    )::text;
  end if;

  if not coalesce(v_source.order_completed, false) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('SALES_ORDER_NOT_COMPLETED')
      )
    )::text;
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
  order by pc.created_at asc
  limit 1;

  if v_provider_connection_id is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('NO_ACTIVE_PROVIDER_CONNECTION')
      )
    )::text;
  end if;

  select ip.id
  into v_issuance_profile_id
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
    and ip.default_template is not null
    and ip.default_signing is not null
  limit 1;

  if v_issuance_profile_id is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('NO_ACTIVE_ISSUANCE_PROFILE')
      )
    )::text;
  end if;

  select bc.*
  into v_buyer_completion
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id
    and bc.sales_order_id = p_sales_order_id
    and bc.sales_order_version = p_source_version
  for update;

  if found and v_buyer_completion.status = 'open' then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('BUYER_SOURCE_UNAVAILABLE')
      )
    )::text;
  end if;

  return query
  select * from einvoice._start_issuance_attempt(
    p_tenant_id => p_tenant_id,
    p_sales_order_id => p_sales_order_id,
    p_source_version => p_source_version,
    p_trigger_type => 'MANUAL',
    p_idempotency_key => p_idempotency_key,
    p_intent_hash => v_intent_hash,
    p_actor_type => 'USER',
    p_actor_id => p_actor_id,
    p_provider_connection_id => v_provider_connection_id,
    p_issuance_profile_id => v_issuance_profile_id,
    p_buyer_partner_id => v_source.buyer_partner_id,
    p_buyer_snapshot => v_source.buyer_snapshot,
    p_commercial_snapshot => v_source.commercial_snapshot,
    p_acknowledge_warnings => coalesce(p_acknowledge_warnings, false),
    p_buyer_completion_id => case when found then v_buyer_completion.id else null end
  );
end;
$$;

revoke all on function einvoice.issue_invoice(uuid, uuid, uuid, text, varchar, boolean) from public;
grant execute on function einvoice.issue_invoice(uuid, uuid, uuid, text, varchar, boolean)
  to authenticated, service_role;

-- 4. einvoice.start_auto_issuance
create or replace function einvoice.start_auto_issuance(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_trigger_key varchar(255),
  p_idempotency_key varchar(150)
) returns table(
  started boolean,
  skipped boolean,
  process_id uuid,
  attempt_id uuid,
  status text,
  reason text
) language plpgsql security definer set search_path = einvoice, extensions, public as $$
declare
  v_existing_proc einvoice.automatic_trigger_process_records%rowtype;
  v_policy einvoice.invoice_automation_policies%rowtype;
  v_source record;
  v_source_version text;
  v_provider_connection_id uuid;
  v_issuance_profile_id uuid;
  v_buyer_completion einvoice.buyer_invoice_completions%rowtype;
  v_proc_id uuid;
  v_start_res record;
  v_intent jsonb;
  v_intent_hash text;
  v_existing_invoice uuid;
  v_active_attempt uuid;
begin
  if p_trigger_key is null or btrim(p_trigger_key) = '' then
    raise exception 'VALIDATION_ERROR: trigger_key is required';
  end if;
  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  -- 1. Check duplicate trigger key (idempotent replay)
  select pr.*
  into v_existing_proc
  from einvoice.automatic_trigger_process_records pr
  where pr.tenant_id = p_tenant_id
    and pr.trigger_key = p_trigger_key
  for update;

  if found then
    return query select
      (v_existing_proc.process_status = 'ATTEMPT_STARTED')::boolean as started,
      (v_existing_proc.process_status = 'SKIPPED')::boolean as skipped,
      v_existing_proc.id as process_id,
      null::uuid as attempt_id,
      v_existing_proc.process_status as status,
      v_existing_proc.blocker_code as reason;
    return;
  end if;

  -- 2. Check Automation Policy
  select ap.*
  into v_policy
  from einvoice.invoice_automation_policies ap
  where ap.tenant_id = p_tenant_id;

  if not found or not coalesce(v_policy.auto_issue_enabled, false) then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      'unknown',
      p_trigger_key,
      p_idempotency_key,
      'SKIPPED',
      'AUTOMATION_POLICY_DISABLED'
    )
    returning id into v_proc_id;

    return query select
      false as started,
      true as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'SKIPPED'::text as status,
      'AUTOMATION_POLICY_DISABLED'::text as reason;
    return;
  end if;

  -- 3. Check already issued or active attempt locks
  select ei.id
  into v_existing_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id;

  if found then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      'unknown',
      p_trigger_key,
      p_idempotency_key,
      'SKIPPED',
      'ALREADY_ISSUED'
    )
    returning id into v_proc_id;

    return query select
      false as started,
      true as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'SKIPPED'::text as status,
      'ALREADY_ISSUED'::text as reason;
    return;
  end if;

  select ia.id
  into v_active_attempt
  from einvoice.invoice_issuances ii
  join einvoice.issuance_attempts ia on ia.invoice_issuance_id = ii.id
  where ii.tenant_id = p_tenant_id
    and ii.sales_order_id = p_sales_order_id
    and ia.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING')
  limit 1;

  if found then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      'unknown',
      p_trigger_key,
      p_idempotency_key,
      'SKIPPED',
      'OPERATION_IN_PROGRESS'
    )
    returning id into v_proc_id;

    return query select
      false as started,
      true as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'SKIPPED'::text as status,
      'OPERATION_IN_PROGRESS'::text as reason;
    return;
  end if;

  -- 4. Load Source Snapshot & Readiness
  select s.*
  into v_source
  from einvoice.load_issuance_source_snapshot(p_tenant_id, p_sales_order_id) s;

  v_source_version := coalesce(v_source.source_version, 'unknown');

  if not coalesce(v_source.available, false) or not coalesce(v_source.order_completed, false) then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      v_source_version,
      p_trigger_key,
      p_idempotency_key,
      'PENDING_REEVALUATION',
      coalesce((v_source.blockers->>0), 'SOURCE_SNAPSHOT_UNAVAILABLE')
    )
    returning id into v_proc_id;

    return query select
      false as started,
      false as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      coalesce((v_source.blockers->>0), 'SOURCE_SNAPSHOT_UNAVAILABLE')::text as reason;
    return;
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
  order by pc.created_at asc
  limit 1;

  if v_provider_connection_id is null then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      v_source_version,
      p_trigger_key,
      p_idempotency_key,
      'PENDING_REEVALUATION',
      'NO_ACTIVE_PROVIDER_CONNECTION'
    )
    returning id into v_proc_id;

    return query select
      false as started,
      false as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'NO_ACTIVE_PROVIDER_CONNECTION'::text as reason;
    return;
  end if;

  select ip.id
  into v_issuance_profile_id
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
    and ip.default_template is not null
    and ip.default_signing is not null
  limit 1;

  if v_issuance_profile_id is null then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      v_source_version,
      p_trigger_key,
      p_idempotency_key,
      'PENDING_REEVALUATION',
      'NO_ACTIVE_ISSUANCE_PROFILE'
    )
    returning id into v_proc_id;

    return query select
      false as started,
      false as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'NO_ACTIVE_ISSUANCE_PROFILE'::text as reason;
    return;
  end if;

  select bc.*
  into v_buyer_completion
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id
    and bc.sales_order_id = p_sales_order_id
    and bc.sales_order_version = v_source_version
  for update;

  if found and v_buyer_completion.status = 'open' then
    insert into einvoice.automatic_trigger_process_records (
      tenant_id,
      process_type,
      sales_order_id,
      sales_order_version,
      trigger_key,
      provider_idempotency_key,
      process_status,
      blocker_code,
      buyer_invoice_completion_id
    ) values (
      p_tenant_id,
      'SALES_ORDER_COMPLETED',
      p_sales_order_id,
      v_source_version,
      p_trigger_key,
      p_idempotency_key,
      'PENDING_REEVALUATION',
      'BUYER_DATA_INCOMPLETE',
      v_buyer_completion.id
    )
    returning id into v_proc_id;

    return query select
      false as started,
      false as skipped,
      v_proc_id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'BUYER_DATA_INCOMPLETE'::text as reason;
    return;
  end if;

  -- 5. Ready: Lock completion (if present), create attempt via helper, and record ATTEMPT_STARTED
  if found and v_buyer_completion.status = 'open' then
    update einvoice.buyer_invoice_completions
    set status = 'locked',
        locked_at = now(),
        version = version + 1,
        updated_at = now()
    where id = v_buyer_completion.id;
  end if;

  v_intent := jsonb_build_object(
    'operation', 'ISSUE_ORIGINAL',
    'sales_order_id', p_sales_order_id,
    'source_version', v_source_version,
    'acknowledge_warnings', false
  );
  v_intent_hash := encode(
    digest(convert_to(v_intent::text, 'UTF8'), 'sha256'),
    'hex'
  );

  select *
  into v_start_res
  from einvoice._start_issuance_attempt(
    p_tenant_id => p_tenant_id,
    p_sales_order_id => p_sales_order_id,
    p_source_version => v_source_version,
    p_trigger_type => 'AUTOMATIC',
    p_idempotency_key => p_idempotency_key,
    p_intent_hash => v_intent_hash,
    p_actor_type => 'SYSTEM',
    p_actor_id => null,
    p_provider_connection_id => v_provider_connection_id,
    p_issuance_profile_id => v_issuance_profile_id,
    p_buyer_partner_id => v_source.buyer_partner_id,
    p_buyer_snapshot => v_source.buyer_snapshot,
    p_commercial_snapshot => v_source.commercial_snapshot,
    p_acknowledge_warnings => false,
    p_buyer_completion_id => case when found then v_buyer_completion.id else null end
  );

  insert into einvoice.automatic_trigger_process_records (
    tenant_id,
    process_type,
    sales_order_id,
    sales_order_version,
    trigger_key,
    provider_idempotency_key,
    process_status,
    buyer_invoice_completion_id
  ) values (
    p_tenant_id,
    'SALES_ORDER_COMPLETED',
    p_sales_order_id,
    v_source_version,
    p_trigger_key,
    p_idempotency_key,
    'ATTEMPT_STARTED',
    case when found then v_buyer_completion.id else null end
  )
  returning id into v_proc_id;

  return query select
    true as started,
    false as skipped,
    v_proc_id as process_id,
    v_start_res.attempt_id as attempt_id,
    'ATTEMPT_STARTED'::text as status,
    null::text as reason;
end;
$$;

revoke all on function einvoice.start_auto_issuance(uuid, uuid, varchar, varchar) from public;
grant execute on function einvoice.start_auto_issuance(uuid, uuid, varchar, varchar)
  to authenticated, service_role;

-- 5. einvoice.list_open_auto_issuance_processes
create or replace function einvoice.list_open_auto_issuance_processes(
  p_tenant_id uuid,
  p_partner_id uuid
) returns table(
  process_id uuid,
  sales_order_id uuid,
  partner_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, public as $$
begin
  return query
  select
    pr.id as process_id,
    pr.sales_order_id,
    p_partner_id as partner_id,
    pr.process_status as status
  from einvoice.automatic_trigger_process_records pr
  left join einvoice.buyer_invoice_completions bc on bc.id = pr.buyer_invoice_completion_id
  where pr.tenant_id = p_tenant_id
    and pr.process_status = 'PENDING_REEVALUATION'
    and (bc.buyer_partner_id = p_partner_id or pr.buyer_invoice_completion_id is null);
end;
$$;

revoke all on function einvoice.list_open_auto_issuance_processes(uuid, uuid) from public;
grant execute on function einvoice.list_open_auto_issuance_processes(uuid, uuid)
  to authenticated, service_role;

-- 6. einvoice.reevaluate_auto_issuance
create or replace function einvoice.reevaluate_auto_issuance(
  p_tenant_id uuid,
  p_process_id uuid,
  p_source_event_id varchar(255)
) returns table(
  started boolean,
  skipped boolean,
  process_id uuid,
  attempt_id uuid,
  status text,
  reason text
) language plpgsql security definer set search_path = einvoice, extensions, public as $$
declare
  v_proc einvoice.automatic_trigger_process_records%rowtype;
  v_source record;
  v_provider_connection_id uuid;
  v_issuance_profile_id uuid;
  v_buyer_completion einvoice.buyer_invoice_completions%rowtype;
  v_intent jsonb;
  v_intent_hash text;
  v_start_res record;
begin
  select pr.*
  into v_proc
  from einvoice.automatic_trigger_process_records pr
  where pr.id = p_process_id
    and pr.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: automatic trigger process record';
  end if;

  if v_proc.process_status <> 'PENDING_REEVALUATION' then
    return query select
      (v_proc.process_status = 'ATTEMPT_STARTED')::boolean as started,
      (v_proc.process_status = 'SKIPPED')::boolean as skipped,
      v_proc.id as process_id,
      null::uuid as attempt_id,
      v_proc.process_status as status,
      v_proc.blocker_code as reason;
    return;
  end if;

  -- Load source snapshot
  select s.*
  into v_source
  from einvoice.load_issuance_source_snapshot(p_tenant_id, v_proc.sales_order_id) s;

  if not coalesce(v_source.available, false) or not coalesce(v_source.order_completed, false) then
    return query select
      false as started,
      false as skipped,
      v_proc.id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      coalesce((v_source.blockers->>0), 'SOURCE_SNAPSHOT_UNAVAILABLE')::text as reason;
    return;
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
  order by pc.created_at asc
  limit 1;

  if v_provider_connection_id is null then
    return query select
      false as started,
      false as skipped,
      v_proc.id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'NO_ACTIVE_PROVIDER_CONNECTION'::text as reason;
    return;
  end if;

  select ip.id
  into v_issuance_profile_id
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
    and ip.default_template is not null
    and ip.default_signing is not null
  limit 1;

  if v_issuance_profile_id is null then
    return query select
      false as started,
      false as skipped,
      v_proc.id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'NO_ACTIVE_ISSUANCE_PROFILE'::text as reason;
    return;
  end if;

  select bc.*
  into v_buyer_completion
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id
    and bc.sales_order_id = v_proc.sales_order_id
    and bc.sales_order_version = v_proc.sales_order_version
  for update;

  if found and v_buyer_completion.status = 'open' then
    return query select
      false as started,
      false as skipped,
      v_proc.id as process_id,
      null::uuid as attempt_id,
      'PENDING_REEVALUATION'::text as status,
      'BUYER_DATA_INCOMPLETE'::text as reason;
    return;
  end if;

  -- Ready: lock completion and start attempt
  if found and v_buyer_completion.status = 'open' then
    update einvoice.buyer_invoice_completions
    set status = 'locked',
        locked_at = now(),
        version = version + 1,
        updated_at = now()
    where id = v_buyer_completion.id;
  end if;

  v_intent := jsonb_build_object(
    'operation', 'ISSUE_ORIGINAL',
    'sales_order_id', v_proc.sales_order_id,
    'source_version', v_proc.sales_order_version,
    'acknowledge_warnings', false
  );
  v_intent_hash := encode(
    digest(convert_to(v_intent::text, 'UTF8'), 'sha256'),
    'hex'
  );

  select *
  into v_start_res
  from einvoice._start_issuance_attempt(
    p_tenant_id => p_tenant_id,
    p_sales_order_id => v_proc.sales_order_id,
    p_source_version => v_proc.sales_order_version,
    p_trigger_type => 'AUTOMATIC',
    p_idempotency_key => v_proc.provider_idempotency_key,
    p_intent_hash => v_intent_hash,
    p_actor_type => 'SYSTEM',
    p_actor_id => null,
    p_provider_connection_id => v_provider_connection_id,
    p_issuance_profile_id => v_issuance_profile_id,
    p_buyer_partner_id => v_source.buyer_partner_id,
    p_buyer_snapshot => v_source.buyer_snapshot,
    p_commercial_snapshot => v_source.commercial_snapshot,
    p_acknowledge_warnings => false,
    p_buyer_completion_id => case when found then v_buyer_completion.id else null end
  );

  update einvoice.automatic_trigger_process_records
  set process_status = 'ATTEMPT_STARTED',
      blocker_code = null,
      updated_at = now(),
      version = version + 1
  where id = p_process_id;

  return query select
    true as started,
    false as skipped,
    v_proc.id as process_id,
    v_start_res.attempt_id as attempt_id,
    'ATTEMPT_STARTED'::text as status,
    null::text as reason;
end;
$$;

revoke all on function einvoice.reevaluate_auto_issuance(uuid, uuid, varchar) from public;
grant execute on function einvoice.reevaluate_auto_issuance(uuid, uuid, varchar)
  to authenticated, service_role;

-- 7. einvoice.retry_issuance
create or replace function einvoice.retry_issuance(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_expected_order_version text,
  p_idempotency_key varchar(150),
  p_acknowledge_warnings boolean default false
) returns table(
  issuance_id uuid,
  attempt_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, iam, sales, extensions, public as $$
declare
  v_intent jsonb;
  v_intent_hash text;
  v_existing einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
  v_last_attempt einvoice.issuance_attempts%rowtype;
  v_existing_invoice uuid;
  v_source record;
  v_provider_connection_id uuid;
  v_issuance_profile_id uuid;
  v_buyer_completion einvoice.buyer_invoice_completions%rowtype;
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.issue')
       and not iam.has_permission(p_tenant_id, 'einvoice.manage_issuance') then
      raise exception 'NO_PERMISSION: einvoice.issue required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  if p_expected_order_version is null or btrim(p_expected_order_version) = '' then
    raise exception 'VALIDATION_ERROR: expected_order_version is required';
  end if;
  if p_idempotency_key is null or btrim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  v_intent := jsonb_build_object(
    'operation', 'RETRY_ISSUE',
    'sales_order_id', p_sales_order_id,
    'expected_order_version', p_expected_order_version,
    'acknowledge_warnings', coalesce(p_acknowledge_warnings, false)
  );
  v_intent_hash := encode(
    digest(convert_to(v_intent::text, 'UTF8'), 'sha256'),
    'hex'
  );

  -- 1. Check duplicate idempotency key
  select ia.*
  into v_existing
  from einvoice.issuance_attempts ia
  where ia.tenant_id = p_tenant_id
    and ia.idempotency_key = p_idempotency_key
  for update;

  if found then
    if v_existing.intent_hash <> v_intent_hash then
      raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
    end if;

    return query select v_existing.invoice_issuance_id, v_existing.id, v_existing.status;
    return;
  end if;

  -- 2. Verify invoice issuance exists and no electronic invoice exists
  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.tenant_id = p_tenant_id
    and ii.sales_order_id = p_sales_order_id
    and ii.issuance_type = 'ORIGINAL'
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice issuance for sales order';
  end if;

  select ei.id
  into v_existing_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.sales_order_id = p_sales_order_id;

  if found then
    raise exception 'ALREADY_ISSUED: sales order already has electronic invoice';
  end if;

  -- 3. Verify latest attempt is definite FAILED and no attempt is in-flight
  select ia.*
  into v_last_attempt
  from einvoice.issuance_attempts ia
  where ia.invoice_issuance_id = v_issuance.id
  order by ia.attempt_no desc
  limit 1
  for update;

  if not found then
    raise exception 'NOT_FOUND: prior issuance attempt';
  end if;

  if v_last_attempt.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING') then
    raise exception 'OPERATION_IN_PROGRESS: issuance attempt currently %', v_last_attempt.status;
  end if;

  if v_last_attempt.status <> 'FAILED' then
    raise exception 'INVALID_STATUS: cannot retry from %', v_last_attempt.status;
  end if;

  -- 4. Load authoritative source snapshot
  select s.*
  into v_source
  from einvoice.load_issuance_source_snapshot(p_tenant_id, p_sales_order_id) s;

  if not coalesce(v_source.available, false) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', coalesce(v_source.blockers, jsonb_build_array('SOURCE_SNAPSHOT_UNAVAILABLE'))
      )
    )::text;
  end if;

  -- Check version mismatch against client expectation
  if v_source.source_version <> p_expected_order_version then
    raise exception 'STATE_CHANGED: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('VERSION_MISMATCH')
      )
    )::text;
  end if;

  if not coalesce(v_source.order_completed, false) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('SALES_ORDER_NOT_COMPLETED')
      )
    )::text;
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
  order by pc.created_at asc
  limit 1;

  if v_provider_connection_id is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('NO_ACTIVE_PROVIDER_CONNECTION')
      )
    )::text;
  end if;

  select ip.id
  into v_issuance_profile_id
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
    and ip.default_template is not null
    and ip.default_signing is not null
  limit 1;

  if v_issuance_profile_id is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('NO_ACTIVE_ISSUANCE_PROFILE')
      )
    )::text;
  end if;

  -- 5. Canonical retry branching:
  -- (1) scn_e02_u05_sc11_01: same version + completion LOCKED -> reuse locked completion/lineage without Theme 03 resolve
  -- (2) scn_e02_u05_sc12_01: different version -> lookup matching completion for new version
  select bc.*
  into v_buyer_completion
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id
    and bc.sales_order_id = p_sales_order_id
    and bc.sales_order_version = v_source.source_version
  for update;

  if found and v_buyer_completion.status = 'open' then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object(
        'blockers', jsonb_build_array('BUYER_SOURCE_UNAVAILABLE')
      )
    )::text;
  end if;

  return query
  select * from einvoice._start_issuance_attempt(
    p_tenant_id => p_tenant_id,
    p_sales_order_id => p_sales_order_id,
    p_source_version => v_source.source_version,
    p_trigger_type => 'MANUAL',
    p_idempotency_key => p_idempotency_key,
    p_intent_hash => v_intent_hash,
    p_actor_type => 'USER',
    p_actor_id => p_actor_id,
    p_provider_connection_id => v_provider_connection_id,
    p_issuance_profile_id => v_issuance_profile_id,
    p_buyer_partner_id => v_source.buyer_partner_id,
    p_buyer_snapshot => v_source.buyer_snapshot,
    p_commercial_snapshot => v_source.commercial_snapshot,
    p_acknowledge_warnings => coalesce(p_acknowledge_warnings, false),
    p_buyer_completion_id => case when found then v_buyer_completion.id else null end
  );
end;
$$;

revoke all on function einvoice.retry_issuance(uuid, uuid, uuid, text, varchar, boolean) from public;
grant execute on function einvoice.retry_issuance(uuid, uuid, uuid, text, varchar, boolean)
  to authenticated, service_role;
