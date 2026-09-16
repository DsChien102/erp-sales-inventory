-- Title: einvoice S3b — reconciliation RPCs, due-time claiming, and recovery
-- Kind: cohesive
-- Intent: einvoice_s3b_reconciliation
-- Touches: einvoice.open_reconciliation_case, einvoice.record_issuance_undetermined, einvoice.claim_issuance_reconciliation_case, einvoice.record_reconciliation_pending, einvoice.resolve_reconciliation_case, einvoice.recover_internal_finalization, einvoice.get_issuance_attempt_status, einvoice.claim_internal_commands_batch, einvoice._reconciliation_poll_command_id, einvoice.seed_due_issuance_reconciliation_commands
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped
-- Depends on: 001_einvoice_configuration_schema.sql, 002_einvoice_install_module_messaging.sql, 005_einvoice_buyer_completion_and_preview_schema.sql, 007_einvoice_issuance_schema_and_publish_rpcs.sql, 008_einvoice_auto_issuance_and_retry_rpcs.sql

alter table einvoice.invoice_reconciliation_cases
  add column if not exists claimed_at timestamptz null;

alter table einvoice.invoice_reconciliation_cases
  add column if not exists claim_token varchar(100) null;

alter table einvoice.invoice_reconciliation_cases
  add column if not exists terminal_evidence jsonb null;

-- 1. Private helper: deterministic reconciliation poll command ID
create or replace function einvoice._reconciliation_poll_command_id(
  p_case_id uuid,
  p_check_ordinal integer
) returns uuid
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_hex text;
begin
  v_raw := p_case_id::text || '|' || p_check_ordinal::text;
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

-- 2. Open reconciliation case
create or replace function einvoice.open_reconciliation_case(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_reason text
) returns table(
  case_id uuid,
  attempt_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_existing_case einvoice.invoice_reconciliation_cases%rowtype;
  v_case_id uuid;
  v_correlation_id varchar(100);
  v_next_check timestamptz;
  v_cmd_id uuid;
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

  if v_attempt.status not in ('WAITING_RESULT', 'SUBMITTED', 'RECONCILING') then
    raise exception 'INVALID_STATUS: attempt is %', v_attempt.status;
  end if;

  if v_attempt.status <> 'RECONCILING' then
    update einvoice.issuance_attempts
    set status = 'RECONCILING',
        failure_code = null,
        failure_message = null,
        version = version + 1,
        updated_at = now()
    where id = p_attempt_id;
  end if;

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
    v_correlation_id := v_existing_case.correlation_id;
  else
    v_case_id := gen_random_uuid();
    v_correlation_id := 'einvoice:reconcile:' || v_case_id::text;
    v_next_check := now() + interval '30 seconds';

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
      opened_by_actor_id,
      created_at,
      updated_at,
      version
    ) values (
      v_case_id,
      p_tenant_id,
      'ISSUANCE_ATTEMPT',
      p_attempt_id,
      'DETERMINE_RESULT',
      v_attempt.provider_connection_id,
      v_attempt.idempotency_key,
      coalesce(nullif(p_reason, ''), 'MANUAL_RECONCILIATION'),
      'PENDING',
      0,
      v_next_check,
      v_correlation_id,
      'SYSTEM',
      null,
      now(),
      now(),
      0
    );

    v_cmd_id := einvoice._reconciliation_poll_command_id(v_case_id, 1);
    insert into einvoice.internal_commands (
      id,
      tenant_id,
      command_type,
      payload,
      source_event_id,
      enqueued_at,
      created_at
    ) values (
      v_cmd_id,
      p_tenant_id,
      'einvoice.poll_issuance_status',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'case_id', v_case_id,
        'attempt_id', p_attempt_id,
        'correlation_id', v_correlation_id
      ),
      v_cmd_id,
      v_next_check,
      now()
    )
    on conflict (id) do nothing;
  end if;

  return query select
    v_case_id,
    p_attempt_id,
    'PENDING'::text;
end;
$$;

-- 3. Record issuance undetermined (replaces 007 with durable enqueue)
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
  v_next_check timestamptz;
  v_cmd_id uuid;
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
      version = version + 1,
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
    v_next_check := now() + interval '30 seconds';

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
      opened_by_actor_id,
      created_at,
      updated_at,
      version
    ) values (
      v_case_id,
      p_tenant_id,
      'ISSUANCE_ATTEMPT',
      p_attempt_id,
      'DETERMINE_RESULT',
      v_attempt.provider_connection_id,
      v_attempt.idempotency_key,
      coalesce(nullif(p_reason_code, ''), 'PROVIDER_TIMEOUT'),
      'PENDING',
      0,
      v_next_check,
      v_case_correlation_id,
      'SYSTEM',
      null,
      now(),
      now(),
      0
    );

    v_cmd_id := einvoice._reconciliation_poll_command_id(v_case_id, 1);
    insert into einvoice.internal_commands (
      id,
      tenant_id,
      command_type,
      payload,
      source_event_id,
      enqueued_at,
      created_at
    ) values (
      v_cmd_id,
      p_tenant_id,
      'einvoice.poll_issuance_status',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'case_id', v_case_id,
        'attempt_id', p_attempt_id,
        'correlation_id', v_case_correlation_id
      ),
      v_cmd_id,
      v_next_check,
      now()
    )
    on conflict (id) do nothing;
  end if;

  return query select
    'RECONCILING'::text,
    v_case_id,
    v_case_correlation_id;
end;
$$;

-- 4. Claim issuance reconciliation case
create or replace function einvoice.claim_issuance_reconciliation_case(
  p_tenant_id uuid,
  p_case_id uuid,
  p_worker_id varchar(100)
) returns table(
  case_id uuid,
  attempt_id uuid,
  claim_token varchar(100),
  idempotency_key varchar(150),
  payload_hash varchar(128),
  invoice_series varchar(100),
  provider_reference varchar(255),
  check_sequence integer,
  max_checks integer
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_case einvoice.invoice_reconciliation_cases%rowtype;
  v_attempt einvoice.issuance_attempts%rowtype;
  v_claim_token varchar(100);
begin
  select irc.*
  into v_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.id = p_case_id
    and irc.tenant_id = p_tenant_id
    and irc.status = 'PENDING'
  for update skip locked;

  if not found then
    return;
  end if;

  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = v_case.target_id
    and ia.tenant_id = p_tenant_id;

  if not found then
    return;
  end if;

  v_claim_token := gen_random_uuid()::varchar(100);

  update einvoice.invoice_reconciliation_cases
  set claimed_at = now(),
      claim_token = v_claim_token,
      updated_at = now()
  where id = p_case_id;

  return query select
    v_case.id,
    v_attempt.id,
    v_claim_token,
    v_attempt.idempotency_key,
    v_attempt.canonical_payload_hash,
    coalesce(
      nullif(trim(v_attempt.invoice_series), ''),
      nullif(trim(v_attempt.provider_result_snapshot ->> 'invoice_series'), '')
    ),
    coalesce(
      v_attempt.provider_invoice_reference,
      v_attempt.provider_request_reference,
      v_attempt.provider_interaction_reference
    ),
    v_case.attempt_count,
    5::integer;
end;
$$;

-- 5. Record reconciliation pending (reschedule next poll check)
create or replace function einvoice.record_reconciliation_pending(
  p_tenant_id uuid,
  p_case_id uuid,
  p_claim_token varchar(100),
  p_next_delay_seconds integer,
  p_check_sequence integer
) returns void
language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_case einvoice.invoice_reconciliation_cases%rowtype;
  v_next_check timestamptz;
  v_cmd_id uuid;
begin
  select irc.*
  into v_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.id = p_case_id
    and irc.tenant_id = p_tenant_id
    and irc.status = 'PENDING'
  for update;

  if not found then
    raise exception 'NOT_FOUND: reconciliation case';
  end if;

  if v_case.claim_token is distinct from p_claim_token then
    raise exception 'STATE_CHANGED: claim token mismatch';
  end if;

  v_next_check := now() + (greatest(p_next_delay_seconds, 1) || ' seconds')::interval;

  update einvoice.invoice_reconciliation_cases
  set attempt_count = p_check_sequence,
      next_check_at = v_next_check,
      claimed_at = null,
      claim_token = null,
      version = version + 1,
      updated_at = now()
  where id = p_case_id;

  v_cmd_id := einvoice._reconciliation_poll_command_id(p_case_id, p_check_sequence);
  insert into einvoice.internal_commands (
    id,
    tenant_id,
    command_type,
    payload,
    source_event_id,
    enqueued_at,
    created_at
  ) values (
    v_cmd_id,
    p_tenant_id,
    'einvoice.poll_issuance_status',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'case_id', p_case_id,
      'attempt_id', v_case.target_id,
      'correlation_id', v_case.correlation_id
    ),
    v_cmd_id,
    v_next_check,
    now()
  )
  on conflict (id) do nothing;
end;
$$;

-- 6. Resolve reconciliation case
create or replace function einvoice.resolve_reconciliation_case(
  p_tenant_id uuid,
  p_case_id uuid,
  p_outcome text,
  p_evidence jsonb default null
) returns table(
  case_id uuid,
  attempt_id uuid,
  status text
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_case einvoice.invoice_reconciliation_cases%rowtype;
  v_attempt einvoice.issuance_attempts%rowtype;
  v_normalized_outcome text := upper(trim(p_outcome));
begin
  select irc.*
  into v_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.id = p_case_id
    and irc.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: reconciliation case';
  end if;

  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.id = v_case.target_id
    and ia.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: issuance attempt';
  end if;

  -- Idempotent terminal check
  if v_case.status = 'RESOLVED' then
    if p_evidence is not null and v_case.terminal_evidence is null then
      update einvoice.invoice_reconciliation_cases
      set terminal_evidence = p_evidence,
          version = version + 1,
          updated_at = now()
      where id = p_case_id;
    end if;

    return query select
      v_case.id,
      v_case.target_id,
      v_case.status;
    return;
  end if;

  if v_normalized_outcome = 'SUCCESS' then
    if p_evidence is null
       or nullif(trim(p_evidence->>'provider_reference'), '') is null
       or nullif(trim(p_evidence->>'invoice_number'), '') is null
       or nullif(trim(p_evidence->>'invoice_series'), '') is null
       or nullif(trim(p_evidence->>'issued_at'), '') is null then
      raise exception 'INVALID_EVIDENCE: incomplete success evidence';
    end if;

    if v_attempt.status not in ('RECONCILING', 'SUCCEEDED') then
      raise exception 'STATE_CHANGED: attempt cannot resolve SUCCESS from %', v_attempt.status;
    end if;

    update einvoice.issuance_attempts
    set status = 'SUCCEEDED',
        provider_invoice_reference = p_evidence->>'provider_reference',
        provider_request_reference = coalesce(
          provider_request_reference,
          p_evidence->>'provider_reference'
        ),
        provider_result_code = 'SUCCESS',
        provider_result_message = p_evidence->>'invoice_number',
        provider_result_snapshot = p_evidence,
        provider_confirmed_at = coalesce(provider_confirmed_at, now()),
        internal_finalization_state = case
          when internal_finalization_state = 'COMPLETED' then 'COMPLETED'
          else 'UNRESOLVED'
        end,
        failure_code = null,
        failure_message = null,
        completed_at = coalesce(completed_at, now()),
        version = version + 1,
        updated_at = now()
    where id = v_attempt.id;

    update einvoice.invoice_reconciliation_cases
    set status = 'RESOLVED',
        terminal_evidence = p_evidence,
        resolution_code = 'SUCCESS',
        resolution_snapshot = p_evidence,
        next_check_at = null,
        claimed_at = null,
        claim_token = null,
        resolved_at = now(),
        version = version + 1,
        updated_at = now()
    where id = p_case_id;

    return query select
      v_case.id,
      v_case.target_id,
      'RESOLVED'::text;
    return;
  end if;

  if v_normalized_outcome = 'FAILURE' then
    if p_evidence is null
       or nullif(trim(p_evidence->>'provider_code'), '') is null
       or nullif(trim(p_evidence->>'provider_message'), '') is null then
      raise exception 'INVALID_EVIDENCE: incomplete failure evidence';
    end if;

    if v_attempt.status not in ('RECONCILING', 'FAILED') then
      raise exception 'STATE_CHANGED: attempt cannot resolve FAILURE from %', v_attempt.status;
    end if;

    update einvoice.issuance_attempts
    set status = 'FAILED',
        provider_result_code = p_evidence->>'provider_code',
        provider_result_message = p_evidence->>'provider_message',
        provider_result_snapshot = p_evidence,
        failure_code = p_evidence->>'provider_code',
        failure_message = p_evidence->>'provider_message',
        completed_at = coalesce(completed_at, now()),
        version = version + 1,
        updated_at = now()
    where id = v_attempt.id;

    update einvoice.invoice_issuances
    set settled_result = 'FAILED',
        version = version + 1,
        updated_at = now()
    where id = v_attempt.invoice_issuance_id;

    update einvoice.invoice_reconciliation_cases
    set status = 'RESOLVED',
        terminal_evidence = p_evidence,
        resolution_code = 'FAILURE',
        resolution_snapshot = p_evidence,
        next_check_at = null,
        claimed_at = null,
        claim_token = null,
        resolved_at = now(),
        version = version + 1,
        updated_at = now()
    where id = p_case_id;

    return query select
      v_case.id,
      v_case.target_id,
      'RESOLVED'::text;
    return;
  end if;

  if v_normalized_outcome = 'UNRESOLVED' then
    update einvoice.invoice_reconciliation_cases
    set status = 'UNRESOLVED',
        terminal_evidence = coalesce(p_evidence, terminal_evidence),
        resolution_code = 'UNRESOLVED',
        resolution_snapshot = coalesce(p_evidence, resolution_snapshot),
        next_check_at = null,
        claimed_at = null,
        claim_token = null,
        resolved_at = now(),
        version = version + 1,
        updated_at = now()
    where id = p_case_id;

    return query select
      v_case.id,
      v_case.target_id,
      'UNRESOLVED'::text;
    return;
  end if;

  raise exception 'INVALID_OUTCOME: %', p_outcome;
end;
$$;

-- 7. Recover internal finalization
create or replace function einvoice.recover_internal_finalization(
  p_tenant_id uuid,
  p_attempt_id uuid
) returns table(
  electronic_invoice_id uuid,
  sales_order_id uuid,
  invoice_number varchar(100),
  invoice_series varchar(100),
  provider_invoice_ref varchar(255),
  issued_at timestamptz,
  status text
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_issuance einvoice.invoice_issuances%rowtype;
  v_existing_invoice einvoice.electronic_invoices%rowtype;
  v_invoice_id uuid;
  v_invoice_number varchar(100);
  v_invoice_series varchar(100);
  v_provider_reference varchar(255);
  v_issued_at timestamptz;
  v_case einvoice.invoice_reconciliation_cases%rowtype;
  v_success_evidence jsonb;
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

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.id = v_attempt.invoice_issuance_id
    and ii.tenant_id = p_tenant_id;

  if not found then
    raise exception 'NOT_FOUND: invoice issuance';
  end if;

  select ei.*
  into v_existing_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and (
      ei.successful_attempt_id = p_attempt_id
      or ei.sales_order_id = v_issuance.sales_order_id
    )
  limit 1;

  if found then
    return query select
      v_existing_invoice.id,
      v_existing_invoice.sales_order_id,
      v_existing_invoice.invoice_number,
      v_existing_invoice.series,
      v_existing_invoice.provider_invoice_reference,
      v_existing_invoice.issued_at,
      'EXISTING'::text;
    return;
  end if;

  if v_attempt.status <> 'SUCCEEDED' then
    raise exception 'STATE_INVALID: attempt is not succeeded';
  end if;

  select irc.*
  into v_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.tenant_id = p_tenant_id
    and irc.target_type = 'ISSUANCE_ATTEMPT'
    and irc.target_id = p_attempt_id
  order by irc.resolved_at desc nulls last, irc.created_at desc
  limit 1;

  v_success_evidence := case
    when nullif(trim(v_case.terminal_evidence->>'invoice_number'), '') is not null
      and nullif(trim(v_case.terminal_evidence->>'invoice_series'), '') is not null
      and nullif(trim(v_case.terminal_evidence->>'issued_at'), '') is not null
      then v_case.terminal_evidence
    when nullif(trim(v_case.resolution_snapshot->>'invoice_number'), '') is not null
      and nullif(trim(v_case.resolution_snapshot->>'invoice_series'), '') is not null
      and nullif(trim(v_case.resolution_snapshot->>'issued_at'), '') is not null
      then v_case.resolution_snapshot
    else v_attempt.provider_result_snapshot
  end;
  v_provider_reference := coalesce(
    nullif(trim(v_success_evidence->>'provider_reference'), ''),
    v_attempt.provider_invoice_reference,
    v_attempt.provider_request_reference
  );
  v_invoice_number := nullif(
    trim(v_success_evidence->>'invoice_number'),
    ''
  )::varchar(100);
  v_invoice_series := nullif(
    trim(v_success_evidence->>'invoice_series'),
    ''
  )::varchar(100);

  if v_provider_reference is null
     or v_invoice_number is null
     or v_invoice_series is null
     or nullif(trim(v_success_evidence->>'issued_at'), '') is null then
    raise exception 'STATE_INVALID: complete success evidence is required';
  end if;

  v_issued_at := (v_success_evidence->>'issued_at')::timestamptz;
  v_invoice_snapshot := jsonb_build_object(
    'schemaVersion', v_attempt.snapshot_schema_version,
    'attemptSnapshot', v_attempt.attempt_snapshot,
    'providerReference', v_provider_reference,
    'invoiceNumber', v_invoice_number,
    'series', v_invoice_series,
    'issuedAt', v_issued_at
  );

  v_invoice_id := gen_random_uuid();

  insert into einvoice.electronic_invoices (
    id,
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
    invoice_snapshot,
    version
  ) values (
    v_invoice_id,
    p_tenant_id,
    v_issuance.id,
    p_attempt_id,
    v_issuance.sales_order_id,
    v_attempt.provider_connection_id,
    v_provider_reference,
    v_invoice_number,
    coalesce(v_attempt.attempt_snapshot ->> 'templateCode', 'UNKNOWN'),
    v_invoice_series,
    v_issued_at,
    v_attempt.snapshot_schema_version,
    v_invoice_snapshot,
    0
  );

  update einvoice.issuance_attempts
  set status = 'SUCCEEDED',
      provider_invoice_reference = v_provider_reference,
      provider_result_code = 'SUCCESS',
      provider_result_message = v_invoice_number,
      provider_result_snapshot = v_success_evidence,
      internal_finalization_state = 'COMPLETED',
      completed_at = coalesce(completed_at, now()),
      version = version + 1,
      updated_at = now()
  where id = p_attempt_id;

  update einvoice.invoice_issuances
  set settled_result = 'ISSUED',
      successful_attempt_id = p_attempt_id,
      electronic_invoice_id = v_invoice_id,
      version = version + 1,
      updated_at = now()
  where id = v_attempt.invoice_issuance_id;

  update einvoice.invoice_reconciliation_cases
  set status = 'RESOLVED',
      resolution_code = 'SUCCESS',
      resolution_snapshot = v_success_evidence,
      terminal_evidence = v_success_evidence,
      next_check_at = null,
      claimed_at = null,
      claim_token = null,
      resolved_at = coalesce(resolved_at, now()),
      version = version + 1,
      updated_at = now()
  where tenant_id = p_tenant_id
    and target_type = 'ISSUANCE_ATTEMPT'
    and target_id = p_attempt_id
    and reconciliation_purpose = 'DETERMINE_RESULT';

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.electronic_invoice.registered',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_issuance.sales_order_id,
      'issuance_id', v_attempt.invoice_issuance_id,
      'attempt_id', p_attempt_id,
      'electronic_invoice_id', v_invoice_id,
      'recovered', true
    )
  );

  return query select
    v_invoice_id,
    v_issuance.sales_order_id,
    v_invoice_number,
    v_invoice_series,
    v_provider_reference,
    v_issued_at,
    'RECOVERED'::text;
end;
$$;

-- 8. Get issuance attempt status
create or replace function einvoice.get_issuance_attempt_status(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  attempt_id uuid,
  status text,
  internal_finalization_status text,
  has_electronic_invoice boolean,
  has_active_operation boolean,
  failure_code varchar(100),
  last_error_message text
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
declare
  v_issuance einvoice.invoice_issuances%rowtype;
  v_attempt einvoice.issuance_attempts%rowtype;
  v_case einvoice.invoice_reconciliation_cases%rowtype;
  v_has_invoice boolean := false;
  v_internal_fin text := 'pending';
  v_has_active_op boolean := false;
  v_safe_failure_code varchar(100) := null;
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.issue') then
      raise exception 'NO_PERMISSION: einvoice.issue required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  select ii.*
  into v_issuance
  from einvoice.invoice_issuances ii
  where ii.tenant_id = p_tenant_id
    and ii.sales_order_id = p_sales_order_id
    and ii.issuance_type = 'ORIGINAL';

  if not found then
    return query select
      null::uuid,
      'PREPARING'::text,
      'pending'::text,
      false,
      false,
      null::varchar(100),
      null::text;
    return;
  end if;

  select ia.*
  into v_attempt
  from einvoice.issuance_attempts ia
  where ia.invoice_issuance_id = v_issuance.id
    and ia.tenant_id = p_tenant_id
  order by ia.attempt_no desc
  limit 1;

  if not found then
    return query select
      null::uuid,
      'PREPARING'::text,
      'pending'::text,
      false,
      false,
      null::varchar(100),
      null::text;
    return;
  end if;

  select exists (
    select 1
    from einvoice.electronic_invoices ei
    where ei.tenant_id = p_tenant_id
      and ei.sales_order_id = p_sales_order_id
  ) into v_has_invoice;

  select irc.*
  into v_case
  from einvoice.invoice_reconciliation_cases irc
  where irc.tenant_id = p_tenant_id
    and irc.target_type = 'ISSUANCE_ATTEMPT'
    and irc.target_id = v_attempt.id
  order by irc.created_at desc
  limit 1;

  if v_has_invoice then
    v_internal_fin := 'completed';
  else
    v_internal_fin := lower(v_attempt.internal_finalization_state);
  end if;

  if v_attempt.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT') then
    v_has_active_op := true;
  elsif v_attempt.status = 'RECONCILING' and (v_case.id is null or v_case.status = 'PENDING') then
    v_has_active_op := true;
  else
    v_has_active_op := false;
  end if;

  if v_attempt.failure_code is not null then
    v_safe_failure_code := regexp_replace(v_attempt.failure_code, '[^A-Za-z0-9_]', '', 'g');
  end if;

  return query select
    v_attempt.id,
    v_attempt.status,
    v_internal_fin,
    v_has_invoice,
    v_has_active_op,
    v_safe_failure_code,
    null::text;
end;
$$;

-- 9. Seed due issuance reconciliation commands
create or replace function einvoice.seed_due_issuance_reconciliation_commands(
  p_tenant_id uuid,
  p_limit int default 50
) returns integer
language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_seeded_count integer := 0;
  v_case record;
  v_cmd_id uuid;
begin
  for v_case in
    select
      irc.id as case_id,
      irc.target_id as attempt_id,
      irc.correlation_id,
      irc.attempt_count,
      irc.next_check_at
    from einvoice.invoice_reconciliation_cases irc
    where irc.tenant_id = p_tenant_id
      and irc.status = 'PENDING'
      and irc.next_check_at <= now()
    order by irc.next_check_at
    limit greatest(p_limit, 1)
  loop
    v_cmd_id := einvoice._reconciliation_poll_command_id(v_case.case_id, v_case.attempt_count + 1);

    insert into einvoice.internal_commands (
      id,
      tenant_id,
      command_type,
      payload,
      source_event_id,
      enqueued_at,
      created_at
    ) values (
      v_cmd_id,
      p_tenant_id,
      'einvoice.poll_issuance_status',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'case_id', v_case.case_id,
        'attempt_id', v_case.attempt_id,
        'correlation_id', v_case.correlation_id
      ),
      v_cmd_id,
      coalesce(v_case.next_check_at, now()),
      now()
    )
    on conflict (id) do update set
      failed_at = null,
      claimed_at = null,
      claim_token = null,
      enqueued_at = case
        when internal_commands.failed_at is not null then now()
        else internal_commands.enqueued_at
      end
    where internal_commands.processed_at is null;

    v_seeded_count := v_seeded_count + 1;
  end loop;

  return v_seeded_count;
end;
$$;

-- 10. Claim internal commands batch (due-time enabled)
create or replace function einvoice.claim_internal_commands_batch(
  p_tenant_id uuid,
  p_limit int default 10
)
returns table (
  command_id uuid,
  command_type text,
  payload jsonb,
  source_event_id uuid,
  enqueued_at timestamptz,
  claim_token uuid,
  retry_count int
)
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  return query
  with candidates as (
    select m.id
    from einvoice.internal_commands m
    where m.tenant_id = p_tenant_id
      and m.processed_at is null
      and m.failed_at is null
      and m.enqueued_at <= now()
      and (
        m.claimed_at is null
        or m.claimed_at < now() - interval '10 minutes'
      )
    order by m.enqueued_at
    for update skip locked
    limit greatest(p_limit, 1)
  ),
  updated as (
    update einvoice.internal_commands m
    set
      claimed_at = now(),
      claim_token = gen_random_uuid()
    from candidates c
    where m.id = c.id
    returning
      m.id,
      m.command_type,
      m.payload,
      m.source_event_id,
      m.enqueued_at,
      m.claim_token,
      m.retry_count
  )
  select
    u.id,
    u.command_type,
    u.payload,
    u.source_event_id,
    u.enqueued_at,
    u.claim_token,
    u.retry_count
  from updated u;
end;
$$;

-- Grants
grant execute on function einvoice.open_reconciliation_case(uuid, uuid, text) to service_role;
grant execute on function einvoice.record_issuance_undetermined(uuid, uuid, varchar, varchar, varchar) to service_role;
grant execute on function einvoice.claim_issuance_reconciliation_case(uuid, uuid, varchar) to service_role;
grant execute on function einvoice.record_reconciliation_pending(uuid, uuid, varchar, integer, integer) to service_role;
grant execute on function einvoice.resolve_reconciliation_case(uuid, uuid, text, jsonb) to service_role;
grant execute on function einvoice.recover_internal_finalization(uuid, uuid) to service_role;
grant execute on function einvoice.get_issuance_attempt_status(uuid, uuid, uuid) to authenticated, service_role;
grant execute on function einvoice.seed_due_issuance_reconciliation_commands(uuid, int) to service_role;
grant execute on function einvoice.claim_internal_commands_batch(uuid, int) to service_role;

-- Idempotent backfill: seed poll commands for existing PENDING cases without command rows
do $$
declare
  v_case record;
  v_cmd_id uuid;
begin
  for v_case in
    select id, tenant_id, target_id, correlation_id, attempt_count, next_check_at
    from einvoice.invoice_reconciliation_cases
    where status = 'PENDING'
  loop
    v_cmd_id := einvoice._reconciliation_poll_command_id(v_case.id, v_case.attempt_count + 1);
    insert into einvoice.internal_commands (
      id,
      tenant_id,
      command_type,
      payload,
      source_event_id,
      enqueued_at,
      created_at
    ) values (
      v_cmd_id,
      v_case.tenant_id,
      'einvoice.poll_issuance_status',
      jsonb_build_object(
        'tenant_id', v_case.tenant_id,
        'case_id', v_case.id,
        'attempt_id', v_case.target_id,
        'correlation_id', v_case.correlation_id
      ),
      v_cmd_id,
      coalesce(v_case.next_check_at, now()),
      now()
    )
    on conflict (id) do nothing;
  end loop;
end;
$$;
