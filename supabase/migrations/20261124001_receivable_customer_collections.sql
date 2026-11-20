-- Title: receivable customer collections
-- Kind: feature
-- Intent: receivable_customer_collections
-- Context: TH-06 3.3/6.2 (T6-1b Task 1)
-- Touches: customer_collections, receivable_offsets, idempotency_records, _raise_error, _assert_actor, _begin_idempotency, _complete_idempotency, _post_money_transaction, _open_orders, _customer_receivable_rows, list_customer_receivables, get_customer_receivable, list_customer_receivable_history, get_customer_receivable_summary, record_customer_collection
-- Safety: additive ; low (them bang, ham, 1 CHECK moi tren receivable.sales_payment_transactions)
-- Depends on: 20261123001_receivable_move_money_tables

-- 1) Bang moi (TH-06 3.3). RLS bat, khong policy: chi doc qua RPC security definer.
create table receivable.customer_collections (
  id uuid primary key,
  tenant_id uuid not null,
  customer_partner_id uuid not null references partner.partners (partner_id),
  amount_minor bigint not null,
  currency_code char(3) not null default 'VND',
  payment_method_code varchar(50) not null,
  external_reference varchar(150),
  customer_outstanding_before_minor bigint not null,
  customer_outstanding_after_minor bigint not null,
  allocation_snapshot jsonb not null,
  collected_by_user_id uuid not null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint customer_collections_amount_positive check (amount_minor > 0),
  constraint customer_collections_before_after
    check (customer_outstanding_before_minor - amount_minor = customer_outstanding_after_minor),
  constraint customer_collections_method_check
    check (payment_method_code in ('cash', 'manualBankTransfer')),
  constraint customer_collections_tenant_id_unique unique (tenant_id, id)
);
alter table receivable.customer_collections enable row level security;

create table receivable.receivable_offsets (
  id uuid primary key,
  tenant_id uuid not null,
  customer_partner_id uuid not null references partner.partners (partner_id),
  return_exchange_order_id uuid not null,
  source_sales_order_id uuid not null,
  target_sales_order_id uuid not null,
  amount_minor bigint not null,
  source_refund_transaction_id uuid not null
    references receivable.sales_payment_transactions (id),
  target_collection_transaction_id uuid not null
    references receivable.sales_payment_transactions (id),
  created_by_user_id uuid not null,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint receivable_offsets_amount_positive check (amount_minor > 0),
  constraint receivable_offsets_source_target_differ
    check (source_sales_order_id <> target_sales_order_id),
  constraint receivable_offsets_return_exchange_fk
    foreign key (tenant_id, return_exchange_order_id)
    references sales.return_exchange_orders (tenant_id, id),
  constraint receivable_offsets_source_order_fk
    foreign key (tenant_id, source_sales_order_id)
    references sales.sales_orders (tenant_id, id),
  constraint receivable_offsets_target_order_fk
    foreign key (tenant_id, target_sales_order_id)
    references sales.sales_orders (tenant_id, id),
  constraint receivable_offsets_pair_unique
    unique (tenant_id, return_exchange_order_id, target_sales_order_id)
);
alter table receivable.receivable_offsets enable row level security;

create table receivable.idempotency_records (
  tenant_id uuid not null,
  command_scope varchar(100) not null,
  idempotency_key varchar(150) not null,
  payload_hash varchar(128) not null,
  status text not null,
  result_snapshot jsonb,
  created_at timestamptz not null default now(),
  constraint receivable_idempotency_records_pkey
    primary key (tenant_id, command_scope, idempotency_key),
  constraint receivable_idempotency_records_status_check
    check (status in ('in_progress', 'succeeded', 'failed'))
);
alter table receivable.idempotency_records enable row level security;

revoke all on receivable.customer_collections, receivable.receivable_offsets,
  receivable.idempotency_records from public, anon, authenticated;

-- 2) Phuong thuc offset chi di voi cap (return_exchange, receivable_offset)
alter table receivable.sales_payment_transactions
  add constraint sales_payment_tx_offset_source_check
  check (payment_method_code <> 'offset'
    or (source_context = 'return_exchange' and source_type = 'receivable_offset'));

-- 3) Index (TH-06 3.4)
create index sales_orders_tenant_customer_completed_idx
  on sales.sales_orders (tenant_id, customer_partner_id)
  where lifecycle_status = 'completed';
create index sales_order_settlements_open_idx
  on receivable.sales_order_settlements (tenant_id, sales_order_id)
  where outstanding_amount_minor > 0;
create index sales_order_settlements_due_idx
  on receivable.sales_order_settlements (tenant_id, payment_due_date)
  where outstanding_amount_minor > 0;

-- 4) Ham noi bo ---------------------------------------------------------------
create function receivable._raise_error(p_code text, p_message text)
returns void
language plpgsql
set search_path = ''
as $$
begin
  raise exception using message = jsonb_build_object(
    'code', p_code, 'message', p_message
  )::text;
end;
$$;

create function receivable._assert_actor(
  p_tenant_id uuid, p_actor_id uuid, p_permissions text[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_permission text;
begin
  if auth.uid() is distinct from p_actor_id then
    perform receivable._raise_error('PERMISSION_DENIED', 'Permission denied.');
  end if;
  foreach v_permission in array p_permissions loop
    if iam.has_permission(p_tenant_id, v_permission) is not true then
      perform receivable._raise_error('PERMISSION_DENIED', 'Permission denied.');
    end if;
  end loop;
end;
$$;

create function receivable._begin_idempotency(
  p_tenant_id uuid,
  p_command_scope text,
  p_idempotency_key text,
  p_payload_hash text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_key text := trim(p_idempotency_key);
  v_hash text := coalesce(nullif(trim(coalesce(p_payload_hash, '')), ''), '');
  v_record receivable.idempotency_records%rowtype;
begin
  if nullif(v_key, '') is null or nullif(trim(coalesce(p_command_scope, '')), '') is null then
    perform receivable._raise_error('CONTEXT_INVALID', 'Idempotency scope and key are required.');
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(p_tenant_id::text || ':' || trim(p_command_scope) || ':' || v_key, 0)
  );

  select * into v_record
  from receivable.idempotency_records r
  where r.tenant_id = p_tenant_id
    and r.command_scope = trim(p_command_scope)
    and r.idempotency_key = v_key
  for update;

  if found then
    if v_record.payload_hash is distinct from v_hash then
      perform receivable._raise_error(
        'IDEMPOTENCY_CONFLICT', 'Idempotency key was already used with another payload.');
    end if;
    if v_record.status = 'in_progress' then
      return jsonb_build_object(
        'decision', 'in_progress', 'status', v_record.status,
        'result_snapshot', v_record.result_snapshot);
    end if;
    return jsonb_build_object(
      'decision', 'replay', 'status', v_record.status,
      'result_snapshot', v_record.result_snapshot);
  end if;

  insert into receivable.idempotency_records (
    tenant_id, command_scope, idempotency_key, payload_hash, status
  ) values (
    p_tenant_id, trim(p_command_scope), v_key, v_hash, 'in_progress'
  );

  return jsonb_build_object('decision', 'new', 'status', 'in_progress');
end;
$$;

create function receivable._complete_idempotency(
  p_tenant_id uuid,
  p_command_scope text,
  p_idempotency_key text,
  p_status text,
  p_result_snapshot jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status not in ('succeeded', 'failed') then
    perform receivable._raise_error('CONTEXT_INVALID', 'Idempotency completion status is invalid.');
  end if;

  update receivable.idempotency_records r
  set status = p_status,
      result_snapshot = p_result_snapshot
  where r.tenant_id = p_tenant_id
    and r.command_scope = trim(p_command_scope)
    and r.idempotency_key = trim(p_idempotency_key);

  if not found then
    perform receivable._raise_error('CONTEXT_INVALID', 'Idempotency record was not found for completion.');
  end if;
end;
$$;

-- Ghi mot giao dich tien (khong kiem so du: nguoi goi kiem), tinh lai quyet toan.
create function receivable._post_money_transaction(
  p_tenant_id uuid,
  p_settlement_id uuid,
  p_transaction_type text,
  p_amount_minor bigint,
  p_payment_method_code text,
  p_source_context text,
  p_source_type text,
  p_source_id uuid,
  p_actor_id uuid,
  p_external_reference text default null
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tx_id uuid := gen_random_uuid();
  v_currency text;
begin
  if p_transaction_type not in ('collection', 'refund') or coalesce(p_amount_minor, 0) <= 0 then
    perform receivable._raise_error('CONTEXT_INVALID', 'Money transaction context is invalid.');
  end if;

  select s.currency_code into v_currency
  from receivable.sales_order_settlements s
  where s.tenant_id = p_tenant_id and s.id = p_settlement_id;
  if v_currency is null then
    perform receivable._raise_error('REFERENCE_UNAVAILABLE', 'Settlement was not found.');
  end if;

  insert into receivable.sales_payment_transactions (
    id, tenant_id, sales_order_settlement_id, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, status,
    source_context, source_type, source_id, initiated_by_user_id,
    external_reference, occurred_at
  ) values (
    v_tx_id, p_tenant_id, p_settlement_id, p_transaction_type,
    case when p_transaction_type = 'collection' then 'inflow' else 'outflow' end,
    p_amount_minor, v_currency, p_payment_method_code, 'confirmed',
    p_source_context, p_source_type, p_source_id, p_actor_id,
    nullif(trim(coalesce(p_external_reference, '')), ''),
    clock_timestamp()
  );

  perform sales._recompute_sales_settlement(p_tenant_id, p_settlement_id);
  return v_tx_id;
end;
$$;

-- Don con no (completed, co khach, outstanding > 0) trong pham vi cua hang cua nguoi goi.
create function receivable._open_orders(
  p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid default null
)
returns table (
  customer_partner_id uuid,
  sales_order_id uuid,
  order_code text,
  completed_at timestamptz,
  store_id uuid,
  settlement_id uuid,
  payable_minor bigint,
  outstanding_minor bigint,
  due_date date,
  settlement_version bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select so.customer_partner_id, so.id, so.order_code::text, so.completed_at, so.store_id,
         s.id, s.current_payable_amount_minor, s.outstanding_amount_minor,
         s.payment_due_date, s.version
  from sales.sales_orders so
  join receivable.sales_order_settlements s
    on s.tenant_id = so.tenant_id and s.sales_order_id = so.id
  where so.tenant_id = p_tenant_id
    and so.lifecycle_status = 'completed'
    and so.customer_partner_id is not null
    and (p_customer_partner_id is null or so.customer_partner_id = p_customer_partner_id)
    and s.outstanding_amount_minor > 0
    and iam.can_access_store(p_tenant_id, so.store_id, p_actor_id);
$$;

-- Mot dong / khach con no, kem khoa sap xep muc khan (BR-10).
create function receivable._customer_receivable_rows(p_tenant_id uuid, p_actor_id uuid)
returns table (
  customer_id uuid,
  display_name text,
  phone text,
  is_active boolean,
  outstanding_minor bigint,
  open_order_count bigint,
  overdue_order_count bigint,
  overdue_amount_minor bigint,
  max_overdue_days integer,
  next_due_date date,
  bucket integer,
  k1 integer
)
language sql
stable
security definer
set search_path = ''
as $$
  with today as (
    select (now() at time zone 'Asia/Ho_Chi_Minh')::date as d
  ),
  agg as (
    select o.customer_partner_id,
           sum(o.outstanding_minor)::bigint as outstanding_minor,
           count(*) as open_order_count,
           count(*) filter (where o.due_date < t.d) as overdue_order_count,
           coalesce(sum(o.outstanding_minor) filter (where o.due_date < t.d), 0)::bigint
             as overdue_amount_minor,
           coalesce(max(t.d - o.due_date) filter (where o.due_date < t.d), 0)::integer
             as max_overdue_days,
           min(o.due_date) filter (where o.due_date >= t.d) as next_due_date
    from receivable._open_orders(p_tenant_id, p_actor_id, null) o
    cross join today t
    group by o.customer_partner_id
  ),
  keyed as (
    select a.*,
           case
             when a.max_overdue_days > 0 then 0
             when a.next_due_date = t.d then 1
             when a.next_due_date > t.d then 2
             else 3
           end as bucket,
           t.d as today
    from agg a cross join today t
  )
  select k.customer_partner_id, p.display_name, partner._profile_phone(p.partner_id),
         (p.status = 'active'),
         k.outstanding_minor, k.open_order_count, k.overdue_order_count,
         k.overdue_amount_minor, k.max_overdue_days, k.next_due_date, k.bucket,
         case k.bucket
           when 0 then -k.max_overdue_days
           when 2 then (k.next_due_date - k.today)
           else 0
         end
  from keyed k
  join partner.partners p
    on p.tenant_id = p_tenant_id and p.partner_id = k.customer_partner_id;
$$;

revoke all on function receivable._raise_error(text, text) from public, anon, authenticated;
revoke all on function receivable._assert_actor(uuid, uuid, text[]) from public, anon, authenticated;
revoke all on function receivable._begin_idempotency(uuid, text, text, text) from public, anon, authenticated;
revoke all on function receivable._complete_idempotency(uuid, text, text, text, jsonb) from public, anon, authenticated;
revoke all on function receivable._post_money_transaction(uuid, uuid, text, bigint, text, text, text, uuid, uuid, text) from public, anon, authenticated;
revoke all on function receivable._open_orders(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function receivable._customer_receivable_rows(uuid, uuid) from public, anon, authenticated;

-- 5) RPC doc ---------------------------------------------------------------------
create function receivable.list_customer_receivables(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_filter text default 'all',
  p_search text default null,
  p_cursor text default null,
  p_page_size int default 50
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_filter text := coalesce(nullif(trim(coalesce(p_filter, '')), ''), 'all');
  v_search text := nullif(catalog.unaccent_immutable(trim(coalesce(p_search, ''))), '');
  v_size int := least(greatest(coalesce(p_page_size, 50), 1), 100);
  v_cursor jsonb;
  v_summary jsonb;
  v_rows jsonb;
  v_items jsonb;
  v_next text;
begin
  perform receivable._assert_actor(p_tenant_id, p_actor_id, array['receivable.view']);

  if v_filter not in ('all', 'overdue') then
    perform receivable._raise_error('CONTEXT_INVALID', 'Filter is invalid.');
  end if;

  if nullif(p_cursor, '') is not null then
    begin
      v_cursor := convert_from(decode(p_cursor, 'base64'), 'utf8')::jsonb;
    exception when others then
      perform receivable._raise_error('CONTEXT_INVALID', 'Cursor is invalid.');
    end;
  end if;

  -- BR-11: tong tren toan pham vi, khong theo loc / tim
  select jsonb_build_object(
    'totalOutstandingMinor', coalesce(sum(r.outstanding_minor), 0)::bigint,
    'customerCount', count(*),
    'overdueCustomerCount', count(*) filter (where r.overdue_order_count > 0),
    'overdueAmountMinor', coalesce(sum(r.overdue_amount_minor), 0)::bigint,
    'maxOverdueDays', coalesce(max(r.max_overdue_days), 0)
  ) into v_summary
  from receivable._customer_receivable_rows(p_tenant_id, p_actor_id) r;

  select coalesce(jsonb_agg(page.item order by page.ord), '[]'::jsonb)
  into v_rows
  from (
    select row_number() over (
             order by r.bucket, r.k1, r.outstanding_minor desc, r.display_name, r.customer_id
           ) as ord,
           jsonb_build_object(
             'customerId', r.customer_id,
             'displayName', r.display_name,
             'phone', r.phone,
             'isActive', r.is_active,
             'outstandingMinor', r.outstanding_minor,
             'openOrderCount', r.open_order_count,
             'overdueOrderCount', r.overdue_order_count,
             'overdueAmountMinor', r.overdue_amount_minor,
             'maxOverdueDays', r.max_overdue_days,
             'nextDueDate', r.next_due_date,
             '_k', jsonb_build_array(
               r.bucket, r.k1, r.outstanding_minor, r.display_name, r.customer_id)
           ) as item
    from receivable._customer_receivable_rows(p_tenant_id, p_actor_id) r
    where (v_filter = 'all' or r.bucket = 0)
      and (v_search is null
           or catalog.unaccent_immutable(r.display_name) ilike '%' || v_search || '%'
           or catalog.unaccent_immutable(coalesce(r.phone, '')) ilike '%' || v_search || '%')
      and (v_cursor is null
           or r.bucket > (v_cursor ->> 0)::int
           or (r.bucket = (v_cursor ->> 0)::int and r.k1 > (v_cursor ->> 1)::int)
           or (r.bucket = (v_cursor ->> 0)::int and r.k1 = (v_cursor ->> 1)::int
               and (r.outstanding_minor < (v_cursor ->> 2)::bigint
                 or (r.outstanding_minor = (v_cursor ->> 2)::bigint
                     and (r.display_name > (v_cursor ->> 3)
                       or (r.display_name = (v_cursor ->> 3)
                           and r.customer_id > (v_cursor ->> 4)::uuid))))))
    order by r.bucket, r.k1, r.outstanding_minor desc, r.display_name, r.customer_id
    limit v_size + 1
  ) page;

  if jsonb_array_length(v_rows) > v_size then
    v_next := replace(
      encode(convert_to((v_rows -> (v_size - 1) -> '_k')::text, 'utf8'), 'base64'),
      E'\n', '');
  end if;

  select coalesce(jsonb_agg(t.e - '_k' order by t.ord), '[]'::jsonb)
  into v_items
  from jsonb_array_elements(v_rows) with ordinality as t(e, ord)
  where t.ord <= v_size;

  return jsonb_build_object('summary', v_summary, 'items', v_items, 'nextCursor', v_next);
end;
$$;

create function receivable.get_customer_receivable(
  p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_partner partner.partners%rowtype;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_orders jsonb;
begin
  perform receivable._assert_actor(p_tenant_id, p_actor_id, array['receivable.view']);

  select * into v_partner
  from partner.partners p
  where p.tenant_id = p_tenant_id and p.partner_id = p_customer_partner_id;
  if not found then
    perform receivable._raise_error('NOT_FOUND', 'Customer was not found.');
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
           'salesOrderId', o.sales_order_id,
           'orderCode', o.order_code,
           'completedAt', o.completed_at,
           'payableMinor', o.payable_minor,
           'outstandingMinor', o.outstanding_minor,
           'dueDate', o.due_date,
           'overdueDays', case when o.due_date < v_today then v_today - o.due_date else 0 end,
           'settlementVersion', o.settlement_version
         ) order by o.completed_at, o.order_code), '[]'::jsonb)
  into v_orders
  from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o;

  return jsonb_build_object(
    'customer', jsonb_build_object(
      'customerId', v_partner.partner_id,
      'displayName', v_partner.display_name,
      'phone', partner._profile_phone(v_partner.partner_id),
      'isActive', v_partner.status = 'active'),
    'outstandingMinor', (
      select coalesce(sum(o.outstanding_minor), 0)::bigint
      from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o),
    'openOrderCount', jsonb_array_length(v_orders),
    'overdueOrderCount', (
      select count(*) from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
      where o.due_date < v_today),
    'maxOverdueDays', (
      select coalesce(max(v_today - o.due_date), 0)
      from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
      where o.due_date < v_today),
    'openOrders', v_orders
  );
end;
$$;

create function receivable.get_customer_receivable_summary(
  p_tenant_id uuid, p_actor_id uuid, p_customer_partner_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
begin
  perform receivable._assert_actor(p_tenant_id, p_actor_id, array['receivable.view']);

  if not exists (
    select 1 from partner.partners p
    where p.tenant_id = p_tenant_id and p.partner_id = p_customer_partner_id
  ) then
    perform receivable._raise_error('NOT_FOUND', 'Customer was not found.');
  end if;

  return (
    select jsonb_build_object(
      'outstandingMinor', coalesce(sum(o.outstanding_minor), 0)::bigint,
      'openOrderCount', count(*),
      'maxOverdueDays', coalesce(max(v_today - o.due_date) filter (where o.due_date < v_today), 0)
    )
    from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
  );
end;
$$;

create function receivable.list_customer_receivable_history(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_customer_partner_id uuid,
  p_cursor text default null,
  p_page_size int default 20
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_size int := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_cursor jsonb;
  v_rows jsonb;
  v_items jsonb;
  v_next text;
begin
  perform receivable._assert_actor(p_tenant_id, p_actor_id, array['receivable.view']);

  if not exists (
    select 1 from partner.partners p
    where p.tenant_id = p_tenant_id and p.partner_id = p_customer_partner_id
  ) then
    perform receivable._raise_error('NOT_FOUND', 'Customer was not found.');
  end if;

  if nullif(p_cursor, '') is not null then
    begin
      v_cursor := convert_from(decode(p_cursor, 'base64'), 'utf8')::jsonb;
    exception when others then
      perform receivable._raise_error('CONTEXT_INVALID', 'Cursor is invalid.');
    end;
  end if;

  select coalesce(jsonb_agg(page.item order by page.ord), '[]'::jsonb)
  into v_rows
  from (
    select row_number() over (order by h.occurred_at desc, h.row_id desc) as ord,
           jsonb_build_object(
             'kind', h.kind,
             'occurredAt', h.occurred_at,
             'amountMinor', h.amount_minor,
             'paymentMethodCode', h.payment_method_code,
             'externalReference', h.external_reference,
             'actorId', h.actor_id,
             'salesOrderId', h.sales_order_id,
             'orderCode', h.order_code,
             'allocations', h.allocations,
             'sourceOrderCode', h.source_order_code,
             'targetOrderCode', h.target_order_code,
             'returnExchangeReference', h.return_exchange_reference,
             '_k', jsonb_build_array(h.occurred_at::text, h.row_id)
           ) as item
    from (
      select cc.occurred_at, cc.id as row_id, 'customer_collection'::text as kind,
             cc.amount_minor, cc.payment_method_code::text as payment_method_code,
             cc.external_reference::text as external_reference,
             cc.collected_by_user_id as actor_id,
             null::uuid as sales_order_id, null::text as order_code,
             cc.allocation_snapshot as allocations,
             null::text as source_order_code, null::text as target_order_code,
             null::text as return_exchange_reference
      from receivable.customer_collections cc
      where cc.tenant_id = p_tenant_id and cc.customer_partner_id = p_customer_partner_id

      union all

      select t.occurred_at, t.id,
             case when t.transaction_type = 'collection' then 'order_collection' else 'refund' end,
             t.amount_minor, t.payment_method_code::text, t.external_reference::text,
             t.initiated_by_user_id, so.id, so.order_code::text, null::jsonb,
             null::text, null::text, null::text
      from receivable.sales_payment_transactions t
      join receivable.sales_order_settlements s
        on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
      join sales.sales_orders so
        on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
      where t.tenant_id = p_tenant_id
        and so.customer_partner_id = p_customer_partner_id
        and t.status = 'confirmed'
        and t.payment_method_code <> 'offset'
        and ((t.transaction_type = 'collection'
              and t.source_context in ('checkout', 'additional_collection'))
          or (t.transaction_type = 'refund' and t.source_context = 'return_exchange'))
        and iam.can_access_store(p_tenant_id, so.store_id, p_actor_id)

      union all

      select o.occurred_at, o.id, 'offset', o.amount_minor, 'offset'::text, null::text,
             o.created_by_user_id, null::uuid, null::text, null::jsonb,
             src.order_code::text, tgt.order_code::text, rx.reference_number::text
      from receivable.receivable_offsets o
      join sales.sales_orders src
        on src.tenant_id = o.tenant_id and src.id = o.source_sales_order_id
      join sales.sales_orders tgt
        on tgt.tenant_id = o.tenant_id and tgt.id = o.target_sales_order_id
      left join sales.return_exchange_orders rx
        on rx.tenant_id = o.tenant_id and rx.id = o.return_exchange_order_id
      where o.tenant_id = p_tenant_id
        and o.customer_partner_id = p_customer_partner_id
        and iam.can_access_store(p_tenant_id, src.store_id, p_actor_id)
        and iam.can_access_store(p_tenant_id, tgt.store_id, p_actor_id)
    ) h
    where v_cursor is null
       or h.occurred_at < (v_cursor ->> 0)::timestamptz
       or (h.occurred_at = (v_cursor ->> 0)::timestamptz
           and h.row_id < (v_cursor ->> 1)::uuid)
    order by h.occurred_at desc, h.row_id desc
    limit v_size + 1
  ) page;

  if jsonb_array_length(v_rows) > v_size then
    v_next := replace(
      encode(convert_to((v_rows -> (v_size - 1) -> '_k')::text, 'utf8'), 'base64'),
      E'\n', '');
  end if;

  select coalesce(jsonb_agg(t.e - '_k' order by t.ord), '[]'::jsonb)
  into v_items
  from jsonb_array_elements(v_rows) with ordinality as t(e, ord)
  where t.ord <= v_size;

  return jsonb_build_object('items', v_items, 'nextCursor', v_next);
end;
$$;

-- 6) Thu theo khach ----------------------------------------------------------------
create function receivable.record_customer_collection(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_customer_partner_id uuid,
  p_amount_minor bigint,
  p_payment_method_code text,
  p_external_reference text,
  p_order_ids uuid[],
  p_expected_outstanding_minor bigint,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_method text := trim(coalesce(p_payment_method_code, ''));
  v_ref text := nullif(trim(coalesce(p_external_reference, '')), '');
  v_order_ids uuid[];
  v_hash text;
  v_decision jsonb;
  v_open_total bigint;
  v_selected_total bigint;
  v_collection_id uuid := gen_random_uuid();
  v_remaining bigint;
  v_alloc bigint;
  v_tx_id uuid;
  v_correlation uuid := gen_random_uuid();
  v_allocations jsonb := '[]'::jsonb;
  v_after_order bigint;
  v_after_total bigint;
  v_result jsonb;
  r record;
begin
  perform receivable._assert_actor(
    p_tenant_id, p_actor_id, array['receivable.collect', 'sales.payment.record']);

  if not exists (
    select 1 from partner.partners p
    where p.tenant_id = p_tenant_id and p.partner_id = p_customer_partner_id
  ) then
    perform receivable._raise_error('NOT_FOUND', 'Customer was not found.');
  end if;

  if v_method not in ('cash', 'manualBankTransfer') then
    perform receivable._raise_error('PAYMENT_METHOD_INVALID', 'Payment method is invalid.');
  end if;

  select coalesce(array_agg(distinct x order by x), '{}'::uuid[])
  into v_order_ids
  from unnest(coalesce(p_order_ids, '{}'::uuid[])) x;

  if coalesce(p_amount_minor, 0) <= 0 or cardinality(v_order_ids) < 1 then
    perform receivable._raise_error('AMOUNT_INVALID', 'Amount must be greater than 0.');
  end if;

  v_hash := md5(jsonb_build_object(
    'customer', p_customer_partner_id,
    'amount', p_amount_minor,
    'method', v_method,
    'reference', v_ref,
    'orders', to_jsonb(v_order_ids),
    'expected', p_expected_outstanding_minor
  )::text);

  -- Idempotency truoc moi kiem so du (thu lai sau khi da ghi phai tra ket qua cu).
  v_decision := receivable._begin_idempotency(
    p_tenant_id, 'customer_collection', p_idempotency_key, v_hash);
  if v_decision ->> 'decision' = 'replay' then
    return v_decision -> 'result_snapshot';
  end if;
  if v_decision ->> 'decision' = 'in_progress' then
    perform receivable._raise_error('IDEMPOTENCY_CONFLICT', 'Idempotency key is already in progress.');
  end if;

  -- Khoa quyet toan moi don con no cua khach, theo id.
  perform 1
  from receivable.sales_order_settlements s
  join sales.sales_orders so on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
  where s.tenant_id = p_tenant_id
    and so.customer_partner_id = p_customer_partner_id
    and so.lifecycle_status = 'completed'
    and s.outstanding_amount_minor > 0
    and iam.can_access_store(p_tenant_id, so.store_id, p_actor_id)
  order by s.id
  for update of s;

  select coalesce(sum(o.outstanding_minor), 0)::bigint into v_open_total
  from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o;
  if v_open_total = 0 then
    perform receivable._raise_error('NO_OUTSTANDING', 'Customer has no outstanding receivable.');
  end if;

  select coalesce(sum(o.outstanding_minor), 0)::bigint into v_selected_total
  from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
  where o.sales_order_id = any (v_order_ids);

  if (select count(*) from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
      where o.sales_order_id = any (v_order_ids)) <> cardinality(v_order_ids)
     or v_selected_total is distinct from p_expected_outstanding_minor then
    perform receivable._raise_error('RECEIVABLE_CHANGED', 'Customer receivable has changed.');
  end if;

  if p_amount_minor > v_selected_total then
    perform receivable._raise_error('OVERPAYMENT_NOT_ALLOWED', 'Amount exceeds outstanding receivable.');
  end if;

  v_remaining := p_amount_minor;
  for r in
    select o.sales_order_id, o.order_code, o.settlement_id, o.outstanding_minor
    from receivable._open_orders(p_tenant_id, p_actor_id, p_customer_partner_id) o
    where o.sales_order_id = any (v_order_ids)
    order by o.completed_at, o.order_code
  loop
    exit when v_remaining <= 0;
    v_alloc := least(v_remaining, r.outstanding_minor);
    v_remaining := v_remaining - v_alloc;

    v_tx_id := receivable._post_money_transaction(
      p_tenant_id, r.settlement_id, 'collection', v_alloc, v_method,
      'receivable_collection', 'customer_collection', v_collection_id,
      p_actor_id, v_ref);

    insert into sales.outbox_messages (id, tenant_id, event_type, payload)
    values (
      gen_random_uuid(), p_tenant_id, 'sales_payment_recorded.v1',
      jsonb_build_object(
        'salesOrderId', r.sales_order_id::text,
        'settlementId', r.settlement_id::text,
        'transactionId', v_tx_id::text,
        'amountMinor', v_alloc,
        'customerCollectionId', v_collection_id::text,
        'correlationId', v_correlation::text
      )
    );

    perform sales._emit_sales_settlement_changed(
      p_tenant_id, r.settlement_id, 'payment', v_tx_id::text, 'record_customer_collection');

    select s.outstanding_amount_minor into v_after_order
    from receivable.sales_order_settlements s
    where s.tenant_id = p_tenant_id and s.id = r.settlement_id;

    perform sales.generate_sales_receipt(
      p_command_id => gen_random_uuid(),
      p_tenant_id => p_tenant_id,
      p_actor_id => p_actor_id,
      p_sales_order_id => r.sales_order_id,
      p_idempotency_key => 'customer_collection:' || v_collection_id::text || ':' || r.sales_order_id::text,
      p_payload_hash => md5(v_collection_id::text || r.sales_order_id::text),
      p_correlation_id => v_correlation::text);

    v_allocations := v_allocations || jsonb_build_array(jsonb_build_object(
      'salesOrderId', r.sales_order_id,
      'orderCode', r.order_code,
      'amountMinor', v_alloc,
      'outstandingAfterMinor', v_after_order));
  end loop;

  v_after_total := v_open_total - p_amount_minor;

  insert into receivable.customer_collections (
    id, tenant_id, customer_partner_id, amount_minor, currency_code,
    payment_method_code, external_reference,
    customer_outstanding_before_minor, customer_outstanding_after_minor,
    allocation_snapshot, collected_by_user_id, occurred_at
  ) values (
    v_collection_id, p_tenant_id, p_customer_partner_id, p_amount_minor, 'VND',
    v_method, v_ref, v_open_total, v_after_total,
    v_allocations, p_actor_id, clock_timestamp()
  );

  v_result := jsonb_build_object(
    'collectionId', v_collection_id,
    'allocations', v_allocations,
    'outstandingAfterMinor', v_after_total);

  perform receivable._complete_idempotency(
    p_tenant_id, 'customer_collection', p_idempotency_key, 'succeeded', v_result);

  return v_result;
end;
$$;

-- 7) Quyen
revoke all on function receivable.list_customer_receivables(uuid, uuid, text, text, text, int) from public, anon;
revoke all on function receivable.get_customer_receivable(uuid, uuid, uuid) from public, anon;
revoke all on function receivable.list_customer_receivable_history(uuid, uuid, uuid, text, int) from public, anon;
revoke all on function receivable.get_customer_receivable_summary(uuid, uuid, uuid) from public, anon;
revoke all on function receivable.record_customer_collection(uuid, uuid, uuid, bigint, text, text, uuid[], bigint, text) from public, anon;
grant execute on function receivable.list_customer_receivables(uuid, uuid, text, text, text, int) to authenticated;
grant execute on function receivable.get_customer_receivable(uuid, uuid, uuid) to authenticated;
grant execute on function receivable.list_customer_receivable_history(uuid, uuid, uuid, text, int) to authenticated;
grant execute on function receivable.get_customer_receivable_summary(uuid, uuid, uuid) to authenticated;
grant execute on function receivable.record_customer_collection(uuid, uuid, uuid, bigint, text, text, uuid[], bigint, text) to authenticated;
