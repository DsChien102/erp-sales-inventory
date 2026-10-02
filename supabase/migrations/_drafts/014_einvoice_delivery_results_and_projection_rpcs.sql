-- Title: einvoice S5 delivery result state machine + projection fields
-- Kind: cohesive
-- Intent: einvoice_s5_delivery_results
-- Context: TH-08 EP-04 S5 — prepare/record/dead-letter delivery outcomes, projection delivery fields
-- Touches: einvoice._delivery_reconciliation_command_id, einvoice._open_delivery_reconciliation_case, einvoice.prepare_delivery_provider_call, einvoice.record_delivery_result, einvoice.record_delivery_command_dead_letter, einvoice.get_order_invoice_projection
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped; safe Vet45-authored messages only; no legal issuance mutation
-- Depends on: 007_einvoice_issuance_schema_and_publish_rpcs.sql, 009_einvoice_issuance_reconciliation_rpcs.sql, 013_einvoice_delivery_schema_and_start_rpcs.sql

-- ---------------------------------------------------------------------------
-- Deterministic reconciliation command id (mirror _reconciliation_poll_command_id)
-- ---------------------------------------------------------------------------
create or replace function einvoice._delivery_reconciliation_command_id(
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

-- ---------------------------------------------------------------------------
-- Mở tối đa một hồ sơ đối soát cho lần gửi UNKNOWN.
-- ---------------------------------------------------------------------------
create or replace function einvoice._open_delivery_reconciliation_case(
  p_tenant_id uuid,
  p_delivery_id uuid,
  p_provider_connection_id uuid,
  p_reason_code text
) returns void
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_case_id uuid;
  v_correlation_id varchar(100);
  v_next_check timestamptz;
  v_cmd_id uuid;
begin
  -- Lần gửi UNKNOWN là trạng thái cuối → tối đa một hồ sơ cho mỗi lần gửi.
  if exists (
    select 1
    from einvoice.invoice_reconciliation_cases irc
    where irc.tenant_id = p_tenant_id
      and irc.target_type = 'INVOICE_DELIVERY'
      and irc.target_id = p_delivery_id
      and irc.status = 'PENDING'
  ) then
    return;
  end if;

  v_case_id := gen_random_uuid();
  v_correlation_id := 'einvoice:delivery-reconcile:' || v_case_id::text;
  v_next_check := now() + interval '30 seconds';

  insert into einvoice.invoice_reconciliation_cases (
    id,
    tenant_id,
    target_type,
    target_id,
    provider_connection_id,
    reason_code,
    status,
    check_count,
    next_check_at,
    correlation_id,
    version
  ) values (
    v_case_id,
    p_tenant_id,
    'INVOICE_DELIVERY',
    p_delivery_id,
    p_provider_connection_id,
    p_reason_code,
    'PENDING',
    0,
    v_next_check,
    v_correlation_id,
    0
  );

  v_cmd_id := einvoice._delivery_reconciliation_command_id(v_case_id, 1);
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
    'einvoice.reconcile_invoice_delivery',
    jsonb_build_object(
      'tenantId', p_tenant_id,
      'reconciliationCaseId', v_case_id,
      'checkSequence', 1
    ),
    v_cmd_id,
    v_next_check,
    now()
  )
  on conflict (id) do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- prepare_delivery_provider_call — atomic SUBMITTED barrier
-- ---------------------------------------------------------------------------
-- Drop old signatures (incl. boolean simulation flag) to avoid overload ambiguity.
drop function if exists einvoice.prepare_delivery_provider_call(uuid, uuid, uuid, bigint, bigint, text);
drop function if exists einvoice.prepare_delivery_provider_call(uuid, uuid, uuid, bigint, bigint, text, boolean);
create or replace function einvoice.prepare_delivery_provider_call(
  p_tenant_id uuid,
  p_delivery_id uuid,
  p_retry_count int,
  p_request_reference text
) returns table(
  action text,
  delivery_version bigint,
  provider_connection_id uuid,
  provider_transaction_id text,
  invoice_series text,
  recipient_email text,
  recipient_name text
)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_delivery einvoice.invoice_deliveries%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if nullif(btrim(coalesce(p_request_reference, '')), '') is null then
    raise exception 'VALIDATION_ERROR: request reference is required';
  end if;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.id = p_delivery_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice delivery';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = v_delivery.electronic_invoice_id;

  -- Lệnh của lần thử cũ, hoặc lần gửi đã xong: không làm gì.
  if v_delivery.retry_count <> p_retry_count
     or v_delivery.status in ('SUCCEEDED', 'FAILED', 'UNKNOWN') then
    return query select 'SKIP'::text, v_delivery.version,
      null::uuid, null::text, null::text, null::text, null::text;
    return;
  end if;

  -- Lần chạy trước đã qua chốt rồi mất dấu: không gọi MISA lần hai.
  if v_delivery.status = 'SUBMITTED' then
    return query select 'RECORD_UNKNOWN'::text, v_delivery.version,
      v_delivery.provider_connection_id,
      v_invoice.provider_invoice_reference::text,
      v_invoice.invoice_series::text,
      v_delivery.recipient_snapshot ->> 'toEmail',
      nullif(v_delivery.recipient_snapshot ->> 'recipientName', '');
    return;
  end if;

  if v_delivery.status <> 'QUEUED' then
    raise exception 'INVALID_STATUS: %', v_delivery.status;
  end if;

  update einvoice.invoice_deliveries d
  set status = 'SUBMITTED',
      submitted_at = now(),
      provider_request_reference = p_request_reference,
      version = d.version + 1
  where d.id = p_delivery_id
  returning d.version into v_delivery.version;

  return query select 'CALL_PROVIDER'::text, v_delivery.version,
    v_delivery.provider_connection_id,
    v_invoice.provider_invoice_reference::text,
    v_invoice.invoice_series::text,
    v_delivery.recipient_snapshot ->> 'toEmail',
    nullif(v_delivery.recipient_snapshot ->> 'recipientName', '');
end;
$$;

-- ---------------------------------------------------------------------------
-- record_delivery_result
-- ---------------------------------------------------------------------------
drop function if exists einvoice.record_delivery_result(uuid, uuid, uuid, bigint, bigint, text, text, text, text);
create or replace function einvoice.record_delivery_result(
  p_tenant_id uuid,
  p_delivery_id uuid,
  p_retry_count int,
  p_expected_version bigint,
  p_outcome_kind text,
  p_provider_reference text,
  p_safe_code text,
  p_failure_source text
) returns table(
  delivery_status text,
  display_state text,
  has_secondary_attention boolean
)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_delivery einvoice.invoice_deliveries%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
  v_statuses text[];
  v_projection record;
  v_safe_code text := nullif(btrim(coalesce(p_safe_code, '')), '');
  v_safe_message text;
  v_cmd_id uuid;
  v_display_camel text;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if p_outcome_kind not in (
    'SUCCESS', 'DEFINITE_FAILURE', 'RETRYABLE_FAILURE', 'UNDETERMINED'
  ) then
    raise exception 'VALIDATION_ERROR: unknown outcome kind %', p_outcome_kind;
  end if;

  if p_outcome_kind <> 'SUCCESS'
     and coalesce(p_failure_source, '') not in ('PROVIDER', 'INTERNAL') then
    raise exception 'VALIDATION_ERROR: failure source required';
  end if;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.id = p_delivery_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice delivery';
  end if;

  -- Gọi lặp hoặc kết quả của lần thử cũ: trả trạng thái hiện tại, không ghi.
  -- SUCCEEDED không bao giờ bị đảo ngược.
  if v_delivery.retry_count <> p_retry_count
     or v_delivery.status in ('SUCCEEDED', 'FAILED', 'UNKNOWN') then
    select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
    into v_statuses
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_delivery.electronic_invoice_id;

    select p.* into v_projection
    from einvoice._delivery_display_projection(v_statuses) p;

    return query select
      einvoice._delivery_public_status(v_delivery.status),
      v_projection.display_state,
      v_projection.has_secondary_attention;
    return;
  end if;

  if v_delivery.version is distinct from p_expected_version then
    raise exception 'STATE_CHANGED: expected version mismatch';
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = v_delivery.electronic_invoice_id;

  v_safe_message := case coalesce(v_safe_code, '')
    when 'WORKER_EXHAUSTED_BEFORE_DISPATCH' then
      'Worker exhausted delivery command before provider dispatch'
    when 'DISPATCH_STATE_UNCERTAIN' then
      'Delivery dispatch state is uncertain'
    when 'PROVIDER_TIMEOUT' then
      'Provider response timed out'
    when 'PROVIDER_TRANSPORT_FAILURE' then
      'Provider transport failure'
    when '' then null
    else 'Delivery outcome recorded with allow-listed failure code'
  end;

  if p_outcome_kind = 'SUCCESS' then
    update einvoice.invoice_deliveries
    set status = 'SUCCEEDED',
        provider_delivery_reference = nullif(btrim(coalesce(p_provider_reference, '')), ''),
        failure_code = null,
        failure_message = null,
        failure_source = null,
        completed_at = now(),
        version = version + 1
    where id = p_delivery_id;

  elsif p_outcome_kind = 'RETRYABLE_FAILURE' and v_delivery.retry_count < 2 then
    -- Hệ thống tự thử lại → tăng bộ đếm trên cùng dòng (S5).
    update einvoice.invoice_deliveries
    set status = 'QUEUED',
        retry_count = v_delivery.retry_count + 1,
        failure_code = v_safe_code,
        failure_message = v_safe_message,
        failure_source = p_failure_source,
        version = version + 1
    where id = p_delivery_id;

    v_cmd_id := einvoice._delivery_send_command_id(p_delivery_id, v_delivery.retry_count + 1);
    perform einvoice.enqueue_internal_command(
      p_tenant_id,
      'einvoice.send_invoice_email',
      jsonb_build_object(
        'tenant_id', p_tenant_id,
        'delivery_id', p_delivery_id,
        'retry_count', v_delivery.retry_count + 1
      ),
      null,
      v_cmd_id
    );

  else
    -- DEFINITE_FAILURE, RETRYABLE_FAILURE ở lần thử cuối, UNDETERMINED.
    update einvoice.invoice_deliveries
    set status = case when p_outcome_kind = 'UNDETERMINED' then 'UNKNOWN' else 'FAILED' end,
        failure_code = v_safe_code,
        failure_message = v_safe_message,
        failure_source = p_failure_source,
        completed_at = now(),
        version = version + 1
    where id = p_delivery_id;

    if p_outcome_kind = 'UNDETERMINED' then
      perform einvoice._open_delivery_reconciliation_case(
        p_tenant_id,
        p_delivery_id,
        v_delivery.provider_connection_id,
        coalesce(v_safe_code, 'DISPATCH_STATE_UNCERTAIN')
      );
    end if;
  end if;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.id = p_delivery_id;

  select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
  into v_statuses
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_delivery.electronic_invoice_id;

  select p.*
  into v_projection
  from einvoice._delivery_display_projection(v_statuses) p;

  v_display_camel := case v_projection.display_state
    when 'NOT_SENT' then 'notSent'
    when 'SENDING' then 'sending'
    when 'SENT' then 'sent'
    when 'FAILED' then 'failed'
    else lower(v_projection.display_state)
  end;

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.delivery.result_recorded',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_invoice.sales_order_id,
      'delivery_id', p_delivery_id,
      'delivery_status', lower(einvoice._delivery_public_status(v_delivery.status)),
      'delivery_display_state', v_display_camel,
      'delivery_version', v_delivery.version,
      'has_secondary_attention', v_projection.has_secondary_attention
    )
  );

  return query select
    einvoice._delivery_public_status(v_delivery.status),
    v_projection.display_state,
    v_projection.has_secondary_attention;
end;
$$;


-- ---------------------------------------------------------------------------
-- record_delivery_command_dead_letter
-- ---------------------------------------------------------------------------
drop function if exists einvoice.record_delivery_command_dead_letter(uuid, uuid, uuid, text);
create or replace function einvoice.record_delivery_command_dead_letter(
  p_tenant_id uuid,
  p_delivery_id uuid,
  p_retry_count int,
  p_safe_failure_code text
) returns void
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_delivery einvoice.invoice_deliveries%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
  v_safe_code text;
  v_safe_message text;
  v_statuses text[];
  v_projection record;
  v_display_camel text;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  v_safe_code := coalesce(
    nullif(btrim(p_safe_failure_code), ''),
    'WORKER_EXHAUSTED_BEFORE_DISPATCH'
  );
  v_safe_message := case v_safe_code
    when 'WORKER_EXHAUSTED_BEFORE_DISPATCH' then
      'Worker exhausted delivery command before provider dispatch'
    else 'Delivery command dead-lettered with allow-listed failure code'
  end;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.id = p_delivery_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: invoice delivery';
  end if;

  if v_delivery.retry_count <> p_retry_count
     or v_delivery.status in ('SUCCEEDED', 'FAILED', 'UNKNOWN') then
    return;
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = v_delivery.electronic_invoice_id;

  if v_delivery.status = 'QUEUED' then
    -- Chưa qua chốt: chắc chắn chưa gửi thư.
    update einvoice.invoice_deliveries
    set status = 'FAILED',
        failure_code = 'WORKER_EXHAUSTED_BEFORE_DISPATCH',
        failure_message = v_safe_message,
        failure_source = 'INTERNAL',
        completed_at = now(),
        version = version + 1
    where id = p_delivery_id;
  elsif v_delivery.status = 'SUBMITTED' then
    update einvoice.invoice_deliveries
    set status = 'UNKNOWN',
        failure_code = v_safe_code,
        failure_message = v_safe_message,
        failure_source = 'INTERNAL',
        completed_at = now(),
        version = version + 1
    where id = p_delivery_id;

    perform einvoice._open_delivery_reconciliation_case(
      p_tenant_id, p_delivery_id, v_delivery.provider_connection_id, v_safe_code
    );
  else
    raise exception 'INVALID_STATUS: %', v_delivery.status;
  end if;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.id = p_delivery_id;

  select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
  into v_statuses
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_delivery.electronic_invoice_id;

  select p.*
  into v_projection
  from einvoice._delivery_display_projection(v_statuses) p;

  v_display_camel := case v_projection.display_state
    when 'NOT_SENT' then 'notSent'
    when 'SENDING' then 'sending'
    when 'SENT' then 'sent'
    when 'FAILED' then 'failed'
    else lower(v_projection.display_state)
  end;

  perform einvoice.enqueue_outbox_message(
    p_tenant_id,
    'einvoice.delivery.result_recorded',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', v_invoice.sales_order_id,
      'delivery_id', p_delivery_id,
      'delivery_status', lower(einvoice._delivery_public_status(v_delivery.status)),
      'delivery_display_state', v_display_camel,
      'delivery_version', v_delivery.version,
      'has_secondary_attention', v_projection.has_secondary_attention
    )
  );
end;
$$;


-- ---------------------------------------------------------------------------
-- get_order_invoice_projection — drop then recreate (OUT row type change)
-- ---------------------------------------------------------------------------
drop function if exists einvoice.get_order_invoice_projection(uuid, uuid, uuid);

create or replace function einvoice.get_order_invoice_projection(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  sales_order_id uuid,
  issuance_display_state text,
  delivery_display_state text,
  has_secondary_attention boolean,
  actions jsonb,
  delivery_pending boolean
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
declare
  v_issuance einvoice.invoice_issuances%rowtype;
  v_attempt einvoice.issuance_attempts%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
  v_statuses text[];
  v_projection record;
  v_issuance_state text;
  v_actions jsonb;
  v_pending boolean := false;
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.view') then
      raise exception 'NO_PERMISSION: einvoice.view required';
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
    and ii.issuance_type = 'ORIGINAL'
  limit 1;

  if not found then
    v_issuance_state := 'notIssued';
    v_actions := jsonb_build_array('issue');
    return query select
      p_sales_order_id,
      v_issuance_state,
      'NOT_SENT'::text,
      false,
      v_actions,
      false;
    return;
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.invoice_issuance_id = v_issuance.id
  limit 1;

  if found then
    v_issuance_state := 'issued';
    v_actions := jsonb_build_array('view');
  else
    select ia.*
    into v_attempt
    from einvoice.issuance_attempts ia
    where ia.invoice_issuance_id = v_issuance.id
    order by ia.attempt_no desc
    limit 1;

    if not found then
      v_issuance_state := 'notIssued';
      v_actions := jsonb_build_array('issue');
    elsif v_attempt.status = 'FAILED' then
      v_issuance_state := 'failed';
      v_actions := jsonb_build_array('issue');
    else
      v_issuance_state := 'processing';
      v_actions := '[]'::jsonb;
    end if;
  end if;

  if v_invoice.id is null then
    v_statuses := '{}'::text[];
  else
    select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
    into v_statuses
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_invoice.id;
  end if;

  select p.*
  into v_projection
  from einvoice._delivery_display_projection(v_statuses) p;

  select exists (
    select 1 from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id and d.electronic_invoice_id = v_invoice.id
      and d.status in ('QUEUED', 'SUBMITTED')
  ) into v_pending;

  return query select
    p_sales_order_id,
    v_issuance_state,
    v_projection.display_state,
    v_projection.has_secondary_attention,
    v_actions,
    v_pending;
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
revoke all on function einvoice._delivery_reconciliation_command_id(uuid, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice._open_delivery_reconciliation_case(uuid, uuid, uuid, text)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.prepare_delivery_provider_call(
  uuid, uuid, int, text
) from public, anon, authenticated, service_role;
-- Biến thể 7 tham số (thêm boolean) đã bị `drop function if exists` ở đầu hàm prepare
-- và không được tạo lại. `revoke` không có mệnh đề `if exists`, nên revoke nó
-- trên DB sạch sẽ ném 42883. Đừng thêm lại.
revoke all on function einvoice.record_delivery_result(
  uuid, uuid, int, bigint, text, text, text, text
) from public, anon, authenticated, service_role;
revoke all on function einvoice.record_delivery_command_dead_letter(
  uuid, uuid, int, text
) from public, anon, authenticated, service_role;
revoke all on function einvoice.get_order_invoice_projection(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;

grant execute on function einvoice.prepare_delivery_provider_call(
  uuid, uuid, int, text
) to service_role;
grant execute on function einvoice.record_delivery_result(
  uuid, uuid, int, bigint, text, text, text, text
) to service_role;
grant execute on function einvoice.record_delivery_command_dead_letter(
  uuid, uuid, int, text
) to service_role;
grant execute on function einvoice.get_order_invoice_projection(uuid, uuid, uuid)
  to authenticated, service_role;
