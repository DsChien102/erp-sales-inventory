-- Title: einvoice H1 — MISA publish retry policy persistence
-- Kind: patch
-- Intent: einvoice_misa_publish_retry_policy
-- Touches: einvoice.record_retryable_provider_publish_rejection, einvoice.claim_issuance_reconciliation_case
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped, service_role only
-- Depends on: 007_einvoice_issuance_schema_and_publish_rpcs.sql, 009_einvoice_issuance_reconciliation_rpcs.sql

create or replace function einvoice.record_retryable_provider_publish_rejection(
  p_tenant_id uuid,
  p_attempt_id uuid,
  p_source_command_id uuid,
  p_idempotency_key varchar(150),
  p_payload_hash varchar(128),
  p_provider_code varchar(100),
  p_provider_message text,
  p_retry_after_seconds integer default 5
) returns table(
  attempt_status text,
  provider_publish_retry_count integer,
  scheduled_publish_retry boolean
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_attempt einvoice.issuance_attempts%rowtype;
  v_next_retry_count integer;
  v_delay interval;
  v_min_delay_seconds integer;
  v_canonical jsonb;
  v_cmd_id uuid;
  v_existing_child_id uuid;
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
    return query select
      v_attempt.status,
      v_attempt.retry_count,
      false;
    return;
  end if;

  select ic.id
  into v_existing_child_id
  from einvoice.internal_commands ic
  where ic.tenant_id = p_tenant_id
    and ic.source_event_id = p_source_command_id
    and ic.command_type = 'einvoice.publish_invoice'
  limit 1;

  if found then
    return query select
      v_attempt.status,
      v_attempt.retry_count,
      true;
    return;
  end if;

  select ic.payload -> 'canonical_invoice'
  into v_canonical
  from einvoice.internal_commands ic
  where ic.id = p_source_command_id
    and ic.tenant_id = p_tenant_id
    and ic.command_type = 'einvoice.publish_invoice'
    and ic.payload ->> 'attempt_id' = p_attempt_id::text;

  if v_canonical is null then
    raise exception 'STATE_INVALID: missing source publish command canonical payload';
  end if;

  v_next_retry_count := v_attempt.retry_count + 1;

  if v_next_retry_count > 3 then
    update einvoice.issuance_attempts
    set version = version + 1
    where id = p_attempt_id;

    perform einvoice.record_issuance_failure(
      p_tenant_id,
      p_attempt_id,
      p_idempotency_key,
      p_payload_hash,
      p_provider_code,
      p_provider_message
    );

    return query select 'FAILED'::text, 3, false;
    return;
  end if;

  v_min_delay_seconds := case
    when v_next_retry_count = 1 then 5
    else 30
  end;
  v_delay := make_interval(
    secs => greatest(coalesce(p_retry_after_seconds, 0), v_min_delay_seconds)
  );

  update einvoice.issuance_attempts
  set status = 'PREPARING',
      retry_count = v_next_retry_count,
      version = version + 1
  where id = p_attempt_id;

  v_cmd_id := gen_random_uuid();

  insert into einvoice.internal_commands (
    id,
    tenant_id,
    command_type,
    payload,
    source_event_id,
    enqueued_at
  ) values (
    v_cmd_id,
    p_tenant_id,
    'einvoice.publish_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'attempt_id', p_attempt_id,
      'canonical_invoice', v_canonical,
      'payload_hash', v_attempt.canonical_payload_hash,
      'idempotency_key', v_attempt.idempotency_key
    ),
    p_source_command_id,
    now() + v_delay
  )
  on conflict (tenant_id, source_event_id, command_type)
  where source_event_id is not null do nothing;

  return query select 'PREPARING'::text, v_next_retry_count, true;
end;
$$;

-- Bản duy nhất; `drop` để chạy lại draft trên DB cũ.
drop function if exists einvoice.claim_issuance_reconciliation_case(uuid, uuid, varchar);

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
  reconciliation_reason_code varchar(100),
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
      claim_token = v_claim_token
  where id = p_case_id;

  return query select
    v_case.id,
    v_attempt.id,
    v_claim_token,
    v_attempt.idempotency_key,
    v_attempt.canonical_payload_hash,
    v_attempt.invoice_series,
    -- Cột nguồn là text, cột trả về là varchar: RETURN QUERY không tự ép kiểu.
    coalesce(
      v_attempt.provider_invoice_reference,
      v_attempt.provider_request_reference
    )::varchar(255),
    v_case.reason_code::varchar(100),
    v_case.check_count,
    5::integer;
end;
$$;

revoke all on function einvoice.record_retryable_provider_publish_rejection(uuid, uuid, uuid, varchar, varchar, varchar, text, integer) from public;
grant execute on function einvoice.record_retryable_provider_publish_rejection(uuid, uuid, uuid, varchar, varchar, varchar, text, integer) to service_role;
grant execute on function einvoice.claim_issuance_reconciliation_case(uuid, uuid, varchar) to service_role;
