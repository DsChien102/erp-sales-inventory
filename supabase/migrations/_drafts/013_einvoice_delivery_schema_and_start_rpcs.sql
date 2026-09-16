-- Title: einvoice S5 delivery schema + start/read/load RPCs
-- Kind: cohesive
-- Intent: einvoice_s5_delivery_schema_and_start
-- Context: TH-08 EP-04 S5 — InvoiceDelivery / DeliveryAttempt schema and atomic start/read contracts
-- Touches: einvoice._delivery_send_command_id, einvoice._delivery_intent_hash, einvoice._delivery_display_projection, einvoice._start_invoice_delivery, einvoice.start_auto_delivery, einvoice.send_electronic_invoice, einvoice.get_send_invoice_sheet_context, einvoice.get_invoice_delivery_history, einvoice.load_delivery_attempt_context
-- Safety: idempotent DDL, RLS enabled, security definer RPCs, tenant scoped; safe Vet45-authored messages only
-- Depends on: 001_einvoice_configuration_schema.sql, 002_einvoice_install_module_messaging.sql, 007_einvoice_issuance_schema_and_publish_rpcs.sql, 010_einvoice_official_view_rpcs.sql, 016_partner_einvoice_recipient_snapshot.sql
--
-- Stable automatic initial-send business key (application UUIDv5; SQL stores the provided key):
--   namespace = 9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275
--   name      = <tenantId>|<electronicInvoiceId>|auto_initial

create unique index if not exists electronic_invoices_tenant_id_id_idx
  on einvoice.electronic_invoices (tenant_id, id);

-- ---------------------------------------------------------------------------
-- Schema: invoice_deliveries
-- ---------------------------------------------------------------------------
create table if not exists einvoice.invoice_deliveries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  electronic_invoice_id uuid not null,
  delivery_no integer not null check (delivery_no > 0),
  delivery_intent text not null check (delivery_intent in ('INITIAL_SEND','RESEND')),
  trigger_type text not null check (trigger_type in ('AUTOMATIC','MANUAL')),
  channel text not null check (channel in ('EMAIL')),
  recipient_snapshot_schema_version integer not null default 1,
  recipient_snapshot jsonb not null,
  idempotency_key uuid not null,
  intent_hash varchar(128) not null,
  status text not null check (status in ('PROCESSING','SUCCEEDED','FAILED','UNKNOWN')),
  provider_delivery_reference varchar(255) null,
  provider_result_code varchar(100) null,
  provider_result_message text null,
  failure_code varchar(100) null,
  failure_message text null,
  initiated_by_actor_type text not null check (initiated_by_actor_type in ('SYSTEM','USER')),
  initiated_by_actor_id uuid null,
  started_at timestamptz not null default now(),
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 0,
  unique (tenant_id, electronic_invoice_id, delivery_no),
  unique (tenant_id, idempotency_key),
  foreign key (tenant_id, electronic_invoice_id)
    references einvoice.electronic_invoices (tenant_id, id)
);

create unique index if not exists invoice_deliveries_one_initial_send
  on einvoice.invoice_deliveries (tenant_id, electronic_invoice_id)
  where delivery_intent = 'INITIAL_SEND';

drop index if exists einvoice.invoice_deliveries_one_active_lock;
create unique index invoice_deliveries_one_active_lock
  on einvoice.invoice_deliveries (tenant_id, electronic_invoice_id)
  where status = 'PROCESSING';

create index if not exists invoice_deliveries_invoice_chrono_idx
  on einvoice.invoice_deliveries (tenant_id, electronic_invoice_id, delivery_no);

alter table einvoice.invoice_deliveries enable row level security;
revoke all on einvoice.invoice_deliveries from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Schema: delivery_attempts
-- ---------------------------------------------------------------------------
create table if not exists einvoice.delivery_attempts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  invoice_delivery_id uuid not null references einvoice.invoice_deliveries(id),
  attempt_no integer not null check (attempt_no > 0),
  status text not null check (status in ('QUEUED','SUBMITTED','SUCCEEDED','FAILED','UNKNOWN')),
  provider_connection_id uuid not null references einvoice.provider_connections(id),
  provider_interaction_reference uuid null,
  provider_request_reference varchar(255) null,
  provider_result_code varchar(100) null,
  provider_result_message text null,
  failure_code varchar(100) null,
  failure_message text null,
  queued_at timestamptz not null default now(),
  submitted_at timestamptz null,
  completed_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 0,
  unique (tenant_id, invoice_delivery_id, attempt_no)
);

create unique index if not exists delivery_attempts_one_active
  on einvoice.delivery_attempts (tenant_id, invoice_delivery_id)
  where status in ('QUEUED','SUBMITTED');

create index if not exists delivery_attempts_delivery_idx
  on einvoice.delivery_attempts (tenant_id, invoice_delivery_id, attempt_no);

alter table einvoice.delivery_attempts enable row level security;
revoke all on einvoice.delivery_attempts from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
create or replace function einvoice._delivery_send_command_id(
  p_attempt_id uuid
) returns uuid
language plpgsql
immutable
as $$
declare
  v_raw text;
  v_hex text;
begin
  v_raw := p_attempt_id::text || '|send_invoice_email|1';
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

create or replace function einvoice._delivery_intent_hash(
  p_intent jsonb
) returns text
language sql
immutable
as $$
  select encode(extensions.digest(convert_to(p_intent::text, 'UTF8'), 'sha256'), 'hex');
$$;

create or replace function einvoice._delivery_display_projection(
  p_statuses text[]
) returns table(
  display_state text,
  has_secondary_attention boolean
)
language plpgsql
immutable
as $$
declare
  v_has_success boolean := false;
  v_latest text;
  v_status text;
begin
  if p_statuses is null or cardinality(p_statuses) = 0 then
    display_state := 'NOT_SENT';
    has_secondary_attention := false;
    return next;
    return;
  end if;

  foreach v_status in array p_statuses loop
    if v_status = 'SUCCEEDED' then
      v_has_success := true;
    end if;
  end loop;

  v_latest := p_statuses[cardinality(p_statuses)];

  if v_has_success then
    display_state := 'SENT';
    has_secondary_attention := (v_latest in ('FAILED', 'UNKNOWN'));
    return next;
    return;
  end if;

  if 'PROCESSING' = any (p_statuses) then
    display_state := 'SENDING';
    has_secondary_attention := false;
    return next;
    return;
  end if;

  if 'UNKNOWN' = any (p_statuses) then
    display_state := 'UNKNOWN';
    has_secondary_attention := false;
    return next;
    return;
  end if;

  display_state := 'FAILED';
  has_secondary_attention := false;
  return next;
end;
$$;

create or replace function einvoice._start_invoice_delivery(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_delivery_intent text,
  p_trigger_type text,
  p_channel text,
  p_recipient_snapshot jsonb,
  p_idempotency_key uuid,
  p_intent_hash text,
  p_actor_type text,
  p_actor_id uuid,
  p_provider_connection_id uuid,
  p_source_event_id uuid default null
) returns table(
  delivery_id uuid,
  attempt_id uuid,
  status text
)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_delivery_id uuid;
  v_attempt_id uuid;
  v_delivery_no integer;
  v_cmd_id uuid;
  v_existing einvoice.invoice_deliveries%rowtype;
begin
  select coalesce(max(d.delivery_no), 0) + 1
  into v_delivery_no
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = p_electronic_invoice_id;

  begin
    insert into einvoice.invoice_deliveries (
      tenant_id,
      electronic_invoice_id,
      delivery_no,
      delivery_intent,
      trigger_type,
      channel,
      recipient_snapshot_schema_version,
      recipient_snapshot,
      idempotency_key,
      intent_hash,
      status,
      initiated_by_actor_type,
      initiated_by_actor_id,
      started_at,
      version
    ) values (
      p_tenant_id,
      p_electronic_invoice_id,
      v_delivery_no,
      p_delivery_intent,
      p_trigger_type,
      p_channel,
      1,
      p_recipient_snapshot,
      p_idempotency_key,
      p_intent_hash,
      'PROCESSING',
      p_actor_type,
      p_actor_id,
      now(),
      0
    )
    returning id into v_delivery_id;
  exception
    when unique_violation then
      -- Concurrent idempotency winner: replay or conflict by intent_hash.
      select d.*
      into v_existing
      from einvoice.invoice_deliveries d
      where d.tenant_id = p_tenant_id
        and d.idempotency_key = p_idempotency_key;

      if found then
        if v_existing.intent_hash is distinct from p_intent_hash then
          raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
        end if;

        select a.id
        into v_attempt_id
        from einvoice.delivery_attempts a
        where a.tenant_id = p_tenant_id
          and a.invoice_delivery_id = v_existing.id
          and a.attempt_no = 1;

        return query select v_existing.id, v_attempt_id, v_existing.status::text;
        return;
      end if;

      -- Concurrent INITIAL_SEND unique loser (partial unique index).
      if p_delivery_intent = 'INITIAL_SEND'
         and exists (
           select 1
           from einvoice.invoice_deliveries d
           where d.tenant_id = p_tenant_id
             and d.electronic_invoice_id = p_electronic_invoice_id
             and d.delivery_intent = 'INITIAL_SEND'
         ) then
        raise exception 'INITIAL_DELIVERY_ALREADY_CLAIMED: initial delivery already exists';
      end if;

      -- Concurrent active PROCESSING lock unique loser.
      if exists (
        select 1
        from einvoice.invoice_deliveries d
        where d.tenant_id = p_tenant_id
          and d.electronic_invoice_id = p_electronic_invoice_id
          and d.status = 'PROCESSING'
      ) then
        raise exception 'OPERATION_IN_PROGRESS: delivery currently locked';
      end if;

      raise;
  end;

  insert into einvoice.delivery_attempts (
    tenant_id,
    invoice_delivery_id,
    attempt_no,
    status,
    provider_connection_id,
    queued_at,
    version
  ) values (
    p_tenant_id,
    v_delivery_id,
    1,
    'QUEUED',
    p_provider_connection_id,
    now(),
    0
  )
  returning id into v_attempt_id;

  v_cmd_id := einvoice._delivery_send_command_id(v_attempt_id);

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.send_invoice_email',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'delivery_id', v_delivery_id,
      'attempt_id', v_attempt_id
    ),
    p_source_event_id,
    v_cmd_id
  );

  return query select v_delivery_id, v_attempt_id, 'PROCESSING'::text;
end;
$$;

-- ---------------------------------------------------------------------------
-- start_auto_delivery (worker/internal)
-- ---------------------------------------------------------------------------
create or replace function einvoice.start_auto_delivery(
  p_tenant_id uuid,
  p_electronic_invoice_id uuid,
  p_trigger_id uuid,
  p_idempotency_key uuid
) returns table(
  disposition text,
  delivery_id uuid,
  skip_reason text
)
language plpgsql
security definer
set search_path = einvoice, extensions, public
as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_policy einvoice.invoice_automation_policies%rowtype;
  v_connection einvoice.provider_connections%rowtype;
  v_existing einvoice.invoice_deliveries%rowtype;
  v_intent jsonb;
  v_intent_hash text;
  v_buyer_partner_id uuid;
  v_recipient_row record;
  v_email text;
  v_name text;
  v_source text;
  v_snapshot jsonb;
  v_start record;
  v_active uuid;
  v_initial uuid;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  if p_idempotency_key is null then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  -- Intent for stable auto_initial key (namespace 9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275).
  v_intent := jsonb_build_object(
    'operation', 'AUTO_INITIAL_SEND',
    'electronic_invoice_id', p_electronic_invoice_id,
    'channel', 'EMAIL',
    'seed', 'auto_initial'
  );
  v_intent_hash := einvoice._delivery_intent_hash(v_intent);

  select d.*
  into v_existing
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.idempotency_key = p_idempotency_key
  for update;

  if found then
    if v_existing.intent_hash <> v_intent_hash then
      raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
    end if;
    return query select 'started'::text, v_existing.id, null::text;
    return;
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = p_electronic_invoice_id
  for update;

  if not found then
    raise exception 'NOT_FOUND: electronic invoice not found';
  end if;

  select ap.*
  into v_policy
  from einvoice.invoice_automation_policies ap
  where ap.tenant_id = p_tenant_id;

  if not found or not coalesce(v_policy.auto_send_enabled, false) then
    return query select 'skipped'::text, null::uuid, 'POLICY_OFF'::text;
    return;
  end if;

  select pc.*
  into v_connection
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.id = v_invoice.provider_connection_id
    and pc.status = 'connected';

  if not found
     or coalesce((v_connection.capabilities_snapshot ->> 'supports_email_delivery')::boolean, false)
        is not true then
    raise exception 'DELIVERY_NOT_SUPPORTED: email delivery capability missing';
  end if;

  select d.id
  into v_active
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = p_electronic_invoice_id
    and d.status = 'PROCESSING'
  limit 1;

  if v_active is not null then
    raise exception 'OPERATION_IN_PROGRESS: delivery currently locked';
  end if;

  select d.id
  into v_initial
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = p_electronic_invoice_id
    and d.delivery_intent = 'INITIAL_SEND'
  limit 1;

  if v_initial is not null then
    return query select
      'skipped'::text,
      null::uuid,
      'INITIAL_DELIVERY_ALREADY_CLAIMED'::text;
    return;
  end if;

  v_buyer_partner_id := nullif(
    trim(
      coalesce(
        v_invoice.invoice_snapshot #>> '{attemptSnapshot,buyer_lineage,buyerPartnerId}',
        ''
      )
    ),
    ''
  )::uuid;

  v_email := null;
  v_name := null;
  v_source := null;

  if v_buyer_partner_id is not null then
    select *
    into v_recipient_row
    from partner.get_einvoice_recipient_snapshot(p_tenant_id, v_buyer_partner_id)
    limit 1;

    if found
       and coalesce(v_recipient_row.is_active, false)
       and nullif(btrim(coalesce(v_recipient_row.invoice_email, '')), '') is not null then
      v_email := nullif(btrim(v_recipient_row.invoice_email), '');
      v_name := nullif(btrim(coalesce(v_recipient_row.recipient_name, '')), '');
      v_source := 'CURRENT_PARTNER_PROFILE';
    end if;
  end if;

  if v_email is null then
    -- Immutable BuyerInvoiceSnapshot lineage only — never EffectiveBuyerInvoiceData email.
    v_email := nullif(
      btrim(
        coalesce(
          v_invoice.invoice_snapshot #>> '{attemptSnapshot,buyer_lineage,buyerInvoiceSnapshot,email}',
          ''
        )
      ),
      ''
    );
    if v_email is not null then
      v_name := nullif(
        btrim(
          coalesce(
            v_invoice.invoice_snapshot #>> '{attemptSnapshot,buyer_lineage,buyerInvoiceSnapshot,name}',
            ''
          )
        ),
        ''
      );
      v_source := 'BUYER_INVOICE_SNAPSHOT';
    end if;
  end if;

  if v_email is null
     or position('@' in v_email) = 0 then
    return query select
      'skipped'::text,
      null::uuid,
      'INVALID_OR_MISSING_EMAIL'::text;
    return;
  end if;

  v_snapshot := jsonb_build_object(
    'toEmail', v_email,
    'source', v_source,
    'recipientName', to_jsonb(v_name),
    'ccEmails', '[]'::jsonb,
    'schemaVersion', '1',
    'buyerPartnerId', to_jsonb(v_buyer_partner_id)
  );

  begin
    select s.*
    into v_start
    from einvoice._start_invoice_delivery(
      p_tenant_id,
      p_electronic_invoice_id,
      'INITIAL_SEND',
      'AUTOMATIC',
      'EMAIL',
      v_snapshot,
      p_idempotency_key,
      v_intent_hash,
      'SYSTEM',
      null,
      v_connection.id,
      p_trigger_id
    ) s;

    return query select 'started'::text, v_start.delivery_id, null::text;
  exception
    when others then
      -- Shared helper maps concurrent INITIAL unique races to this message.
      if SQLERRM like 'INITIAL_DELIVERY_ALREADY_CLAIMED%' then
        return query select
          'skipped'::text,
          null::uuid,
          'INITIAL_DELIVERY_ALREADY_CLAIMED'::text;
        return;
      end if;
      raise;
  end;
end;
$$;

-- ---------------------------------------------------------------------------
-- send_electronic_invoice (public manual)
-- ---------------------------------------------------------------------------
create or replace function einvoice.send_electronic_invoice(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_recipient_email text,
  p_idempotency_key uuid
) returns table(
  delivery_id uuid,
  status text
)
language plpgsql
security definer
set search_path = einvoice, iam, sales, extensions, public
as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_connection einvoice.provider_connections%rowtype;
  v_existing einvoice.invoice_deliveries%rowtype;
  v_intent jsonb;
  v_intent_hash text;
  v_email text;
  v_snapshot jsonb;
  v_intent_kind text;
  v_start record;
  v_active uuid;
  v_has_initial boolean;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.send') then
    raise exception 'NO_PERMISSION: einvoice.send required';
  end if;

  if not sales.can_access_sales_order(
    p_tenant_id,
    p_actor_id,
    p_sales_order_id
  ) then
    raise exception 'NOT_FOUND: sales order not found';
  end if;

  if p_idempotency_key is null then
    raise exception 'VALIDATION_ERROR: idempotency_key is required';
  end if;

  v_email := nullif(btrim(coalesce(p_recipient_email, '')), '');
  if v_email is null or position('@' in v_email) = 0 then
    raise exception 'VALIDATION_ERROR: recipient email is invalid';
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

  select exists (
    select 1
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_invoice.id
      and d.delivery_intent = 'INITIAL_SEND'
  )
  into v_has_initial;

  v_intent_kind := case when v_has_initial then 'RESEND' else 'INITIAL_SEND' end;

  v_intent := jsonb_build_object(
    'operation', 'MANUAL_SEND',
    'sales_order_id', p_sales_order_id,
    'electronic_invoice_id', v_invoice.id,
    'delivery_intent', v_intent_kind,
    'recipient_email', v_email,
    'channel', 'EMAIL'
  );
  v_intent_hash := einvoice._delivery_intent_hash(v_intent);

  select d.*
  into v_existing
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.idempotency_key = p_idempotency_key
  for update;

  if found then
    if v_existing.intent_hash <> v_intent_hash then
      raise exception 'IDEMPOTENCY_CONFLICT: payload differs for key %', p_idempotency_key;
    end if;
    return query select v_existing.id, v_existing.status;
    return;
  end if;

  select pc.*
  into v_connection
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.id = v_invoice.provider_connection_id
    and pc.status = 'connected';

  if not found
     or coalesce((v_connection.capabilities_snapshot ->> 'supports_email_delivery')::boolean, false)
        is not true then
    raise exception 'DELIVERY_NOT_SUPPORTED: email delivery capability missing';
  end if;

  select d.id
  into v_active
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id
    and d.status = 'PROCESSING'
  limit 1;

  if v_active is not null then
    raise exception 'OPERATION_IN_PROGRESS: delivery currently locked';
  end if;

  v_snapshot := jsonb_build_object(
    'toEmail', v_email,
    'source', 'USER_INPUT',
    'recipientName', null,
    'ccEmails', '[]'::jsonb,
    'schemaVersion', '1'
  );

  select s.*
  into v_start
  from einvoice._start_invoice_delivery(
    p_tenant_id,
    v_invoice.id,
    v_intent_kind,
    'MANUAL',
    'EMAIL',
    v_snapshot,
    p_idempotency_key,
    v_intent_hash,
    'USER',
    p_actor_id,
    v_connection.id,
    null
  ) s;

  return query select v_start.delivery_id, v_start.status;
end;
$$;

-- ---------------------------------------------------------------------------
-- get_send_invoice_sheet_context
-- ---------------------------------------------------------------------------
create or replace function einvoice.get_send_invoice_sheet_context(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  mode text,
  suggested_email text,
  suggested_email_source text,
  history jsonb,
  operation_locked boolean,
  display_state text
)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_has_initial boolean;
  v_mode text;
  v_locked boolean;
  v_statuses text[];
  v_projection record;
  v_history jsonb;
  v_buyer_partner_id uuid;
  v_recipient_row record;
  v_suggested text;
  v_source text;
  v_last_success record;
  v_last_any record;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.send') then
    raise exception 'NO_PERMISSION: einvoice.send required';
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

  select exists (
    select 1
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_invoice.id
      and d.delivery_intent = 'INITIAL_SEND'
  )
  into v_has_initial;

  v_mode := case when v_has_initial then 'resend' else 'send' end;

  select exists (
    select 1
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_invoice.id
      and d.status = 'PROCESSING'
  )
  into v_locked;

  select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
  into v_statuses
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id;

  select p.*
  into v_projection
  from einvoice._delivery_display_projection(v_statuses) p;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'deliveryId', d.id,
        'deliveryNo', d.delivery_no,
        'kind', d.delivery_intent,
        'triggerType', d.trigger_type,
        'recipientEmail', d.recipient_snapshot ->> 'toEmail',
        'status', d.status,
        'initiatedByActorType', d.initiated_by_actor_type,
        'initiatedByActorId', d.initiated_by_actor_id,
        'startedAt', d.started_at,
        'completedAt', d.completed_at,
        'failureCode', d.failure_code
      )
      order by d.delivery_no
    ),
    '[]'::jsonb
  )
  into v_history
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id;

  v_suggested := null;
  v_source := null;

  v_buyer_partner_id := nullif(
    trim(
      coalesce(
        v_invoice.invoice_snapshot #>> '{attemptSnapshot,buyer_lineage,buyerPartnerId}',
        ''
      )
    ),
    ''
  )::uuid;

  if v_mode = 'send' then
    if v_buyer_partner_id is not null then
      select *
      into v_recipient_row
      from partner.get_einvoice_recipient_snapshot(p_tenant_id, v_buyer_partner_id)
      limit 1;

      if found
         and coalesce(v_recipient_row.is_active, false)
         and nullif(btrim(coalesce(v_recipient_row.invoice_email, '')), '') is not null then
        v_suggested := nullif(btrim(v_recipient_row.invoice_email), '');
        v_source := 'CURRENT_PARTNER_PROFILE';
      end if;

      if v_suggested is null then
        select
          d.recipient_snapshot ->> 'toEmail' as email
        into v_last_success
        from einvoice.invoice_deliveries d
        where d.tenant_id = p_tenant_id
          and d.status = 'SUCCEEDED'
          and nullif(d.recipient_snapshot ->> 'buyerPartnerId', '')::uuid
              = v_buyer_partner_id
        order by d.started_at desc, d.delivery_no desc
        limit 1;

        if found and nullif(btrim(coalesce(v_last_success.email, '')), '') is not null then
          v_suggested := nullif(btrim(v_last_success.email), '');
          v_source := 'LAST_SUCCESSFUL_PARTNER_DELIVERY';
        end if;
      end if;
    end if;
  else
    select
      d.recipient_snapshot ->> 'toEmail' as email
    into v_last_any
    from einvoice.invoice_deliveries d
    where d.tenant_id = p_tenant_id
      and d.electronic_invoice_id = v_invoice.id
    order by d.delivery_no desc
    limit 1;

    if found and nullif(btrim(coalesce(v_last_any.email, '')), '') is not null then
      v_suggested := nullif(btrim(v_last_any.email), '');
      v_source := 'LAST_INVOICE_DELIVERY';
    end if;
  end if;

  return query select
    v_mode,
    v_suggested,
    v_source,
    v_history,
    v_locked,
    v_projection.display_state;
end;
$$;

-- ---------------------------------------------------------------------------
-- get_invoice_delivery_history
-- ---------------------------------------------------------------------------
create or replace function einvoice.get_invoice_delivery_history(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  deliveries jsonb,
  display_state text,
  has_secondary_attention boolean
)
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_invoice einvoice.electronic_invoices%rowtype;
  v_statuses text[];
  v_projection record;
  v_deliveries jsonb;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.send') then
    raise exception 'NO_PERMISSION: einvoice.send required';
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

  select coalesce(array_agg(d.status order by d.delivery_no), '{}'::text[])
  into v_statuses
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id;

  select p.*
  into v_projection
  from einvoice._delivery_display_projection(v_statuses) p;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'deliveryId', d.id,
        'deliveryNo', d.delivery_no,
        'kind', d.delivery_intent,
        'triggerType', d.trigger_type,
        'recipientEmail', d.recipient_snapshot ->> 'toEmail',
        'status', d.status,
        'initiatedByActorType', d.initiated_by_actor_type,
        'initiatedByActorId', d.initiated_by_actor_id,
        'startedAt', d.started_at,
        'completedAt', d.completed_at,
        'failureCode', d.failure_code
      )
      order by d.delivery_no
    ),
    '[]'::jsonb
  )
  into v_deliveries
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.electronic_invoice_id = v_invoice.id;

  return query select
    v_deliveries,
    v_projection.display_state,
    v_projection.has_secondary_attention;
end;
$$;

-- ---------------------------------------------------------------------------
-- load_delivery_attempt_context (worker)
-- ---------------------------------------------------------------------------
-- OUT row type change: drop then recreate without simulation provenance columns.
drop function if exists einvoice.load_delivery_attempt_context(uuid, uuid, uuid);
create or replace function einvoice.load_delivery_attempt_context(
  p_tenant_id uuid,
  p_delivery_id uuid,
  p_attempt_id uuid
) returns table(
  tenant_id uuid,
  delivery_id uuid,
  attempt_id uuid,
  delivery_version bigint,
  attempt_version bigint,
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
  v_attempt einvoice.delivery_attempts%rowtype;
  v_invoice einvoice.electronic_invoices%rowtype;
begin
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: service role required';
  end if;

  select d.*
  into v_delivery
  from einvoice.invoice_deliveries d
  where d.tenant_id = p_tenant_id
    and d.id = p_delivery_id;

  if not found then
    return;
  end if;

  select a.*
  into v_attempt
  from einvoice.delivery_attempts a
  where a.tenant_id = p_tenant_id
    and a.id = p_attempt_id
    and a.invoice_delivery_id = p_delivery_id;

  if not found then
    return;
  end if;

  select ei.*
  into v_invoice
  from einvoice.electronic_invoices ei
  where ei.tenant_id = p_tenant_id
    and ei.id = v_delivery.electronic_invoice_id;

  if not found then
    return;
  end if;

  return query select
    p_tenant_id,
    v_delivery.id,
    v_attempt.id,
    v_delivery.version,
    v_attempt.version,
    v_attempt.provider_connection_id,
    v_invoice.provider_invoice_reference::text,
    v_invoice.series::text,
    v_delivery.recipient_snapshot ->> 'toEmail',
    nullif(v_delivery.recipient_snapshot ->> 'recipientName', '');
end;
$$;

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
revoke all on function einvoice._delivery_send_command_id(uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice._delivery_intent_hash(jsonb)
  from public, anon, authenticated, service_role;
revoke all on function einvoice._delivery_display_projection(text[])
  from public, anon, authenticated, service_role;
revoke all on function einvoice._start_invoice_delivery(
  uuid, uuid, text, text, text, jsonb, uuid, text, text, uuid, uuid, uuid
) from public, anon, authenticated, service_role;
revoke all on function einvoice.start_auto_delivery(uuid, uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.send_electronic_invoice(uuid, uuid, uuid, text, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_send_invoice_sheet_context(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_invoice_delivery_history(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.load_delivery_attempt_context(uuid, uuid, uuid)
  from public, anon, authenticated, service_role;

grant execute on function einvoice.send_electronic_invoice(uuid, uuid, uuid, text, uuid)
  to authenticated;
grant execute on function einvoice.get_send_invoice_sheet_context(uuid, uuid, uuid)
  to authenticated;
grant execute on function einvoice.get_invoice_delivery_history(uuid, uuid, uuid)
  to authenticated;

-- Private helpers stay revoked from service_role (mirror S3 _start_issuance_attempt);
-- security-definer public/worker RPCs still call them as owner.
grant execute on function einvoice.start_auto_delivery(uuid, uuid, uuid, uuid)
  to service_role;
grant execute on function einvoice.load_delivery_attempt_context(uuid, uuid, uuid)
  to service_role;
