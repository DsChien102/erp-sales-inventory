-- Title: receivable return offsets
-- Kind: feature
-- Intent: receivable_return_offsets
-- Context: TH-06 2.2/3.3/6.2 (T6-1b Task 2)
-- Touches: return_exchange_settlement_plans, evaluate_return_exchange_valuation, confirm_return_exchange, settle_return_exchange_difference, get_return_exchange_detail, get_sales_order_payment_summary, get_sales_order_payment_transactions
-- Safety: destructive (drop settle_return_exchange_difference, bo khoa settlement_plan khoi valuation_details) sau khi chep du lieu va kiem dem
-- Depends on: 20261124001_receivable_customer_collections

-- 1) Bang ke hoach tien doi/tra (TH-06 3.3). Them 4 cot ky thuat (source_session_version,
--    pricing_source_version, inventory_source_version, correlation_id) de confirm kiem phien ban
--    ma khong con doc jsonb.
create table receivable.return_exchange_settlement_plans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  return_exchange_order_id uuid not null,
  sales_order_id uuid not null,
  net_difference_minor bigint not null,
  collect_amount_minor bigint not null default 0,
  receivable_create_amount_minor bigint not null default 0,
  receivable_reverse_amount_minor bigint not null default 0,
  offset_amount_minor bigint not null default 0,
  refund_amount_minor bigint not null default 0,
  offset_candidates jsonb not null default '[]'::jsonb,
  source_order_version bigint not null,
  source_settlement_version bigint not null,
  source_session_version bigint,
  pricing_source_version integer,
  inventory_source_version integer,
  correlation_id text,
  status text not null,
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint return_exchange_settlement_plans_rx_unique unique (return_exchange_order_id),
  constraint return_exchange_settlement_plans_status_check
    check (status in ('calculated', 'confirmed')),
  constraint return_exchange_settlement_plans_nonneg
    check (collect_amount_minor >= 0 and receivable_create_amount_minor >= 0
      and receivable_reverse_amount_minor >= 0 and offset_amount_minor >= 0
      and refund_amount_minor >= 0),
  constraint return_exchange_settlement_plans_balance check (
    (net_difference_minor < 0
      and collect_amount_minor = 0 and receivable_create_amount_minor = 0
      and -net_difference_minor
        = receivable_reverse_amount_minor + offset_amount_minor + refund_amount_minor)
    or (net_difference_minor > 0
      and receivable_reverse_amount_minor = 0 and offset_amount_minor = 0
      and refund_amount_minor = 0
      and net_difference_minor = collect_amount_minor + receivable_create_amount_minor)
    or (net_difference_minor = 0
      and collect_amount_minor = 0 and receivable_create_amount_minor = 0
      and receivable_reverse_amount_minor = 0 and offset_amount_minor = 0
      and refund_amount_minor = 0)
  ),
  constraint return_exchange_settlement_plans_rx_fk
    foreign key (tenant_id, return_exchange_order_id)
    references sales.return_exchange_orders (tenant_id, id),
  constraint return_exchange_settlement_plans_order_fk
    foreign key (tenant_id, sales_order_id)
    references sales.sales_orders (tenant_id, id)
);
alter table receivable.return_exchange_settlement_plans enable row level security;
revoke all on receivable.return_exchange_settlement_plans from public, anon, authenticated;

-- 2) Chep ke hoach tu valuation_details, kiem dem, roi bo khoa
insert into receivable.return_exchange_settlement_plans (
  tenant_id, return_exchange_order_id, sales_order_id, net_difference_minor,
  collect_amount_minor, receivable_create_amount_minor, receivable_reverse_amount_minor,
  offset_amount_minor, refund_amount_minor, offset_candidates,
  source_order_version, source_settlement_version, source_session_version,
  pricing_source_version, inventory_source_version, correlation_id,
  status, calculated_at
)
select v.tenant_id, v.return_exchange_order_id, rx.sales_order_id, v.net_difference_minor,
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'collect_amount_minor')::bigint, 0),
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'receivable_create_amount_minor')::bigint, 0),
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'receivable_reverse_amount_minor')::bigint, 0),
       0,
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'refund_amount_minor')::bigint, 0),
       '[]'::jsonb,
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'source_order_version')::bigint, 0),
       coalesce((v.valuation_details -> 'settlement_plan' ->> 'source_settlement_version')::bigint, 0),
       nullif(v.valuation_details -> 'settlement_plan' ->> 'source_session_version', '')::bigint,
       nullif(v.valuation_details -> 'settlement_plan' ->> 'pricing_source_version', '')::integer,
       nullif(v.valuation_details -> 'settlement_plan' ->> 'inventory_source_version', '')::integer,
       nullif(v.valuation_details -> 'settlement_plan' ->> 'correlation_id', ''),
       case when v.status = 'confirmed' then 'confirmed' else 'calculated' end,
       v.calculated_at
from sales.return_exchange_valuations v
join sales.return_exchange_orders rx
  on rx.tenant_id = v.tenant_id and rx.id = v.return_exchange_order_id
where v.valuation_details ? 'settlement_plan';

do $$
declare
  v_valuations bigint;
  v_plans bigint;
begin
  select count(*) into v_valuations
  from sales.return_exchange_valuations where valuation_details ? 'settlement_plan';
  select count(*) into v_plans from receivable.return_exchange_settlement_plans;
  if v_valuations <> v_plans then
    raise exception 'T6-1b: chep ke hoach lech (dinh gia co ke hoach=%, dong ke hoach=%)',
      v_valuations, v_plans;
  end if;
end;
$$;

update sales.return_exchange_valuations
set valuation_details = valuation_details - 'settlement_plan'
where valuation_details ? 'settlement_plan';

-- 3) Dinh gia: giam no -> can tru -> hoan, ke hoach ghi vao bang rieng
CREATE OR REPLACE FUNCTION sales.evaluate_return_exchange_valuation(query_id text, tenant_id uuid, actor_id uuid, return_exchange_id uuid, expected_source_version bigint DEFAULT NULL::bigint, reference_decision jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_session sales.return_exchange_orders%rowtype;
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_jwt_store text;
  v_return_value_minor bigint := 0;
  v_exchange_value_minor bigint := 0;
  v_net_difference_minor bigint;
  v_currency text;
  v_pricing_source_version integer;
  v_inventory_source_version integer;
  v_net_confirmed_collection bigint;
  v_collect_amount_minor bigint := 0;
  v_refund_amount_minor bigint := 0;
  v_receivable_create_amount_minor bigint := 0;
  v_receivable_reverse_amount_minor bigint := 0;
  v_abs_diff bigint;
  v_line record;
  v_unit_price_minor bigint;
  v_priced jsonb;
  v_orig_line_total_minor bigint;
  v_orig_quantity_micros bigint;
  v_line_value_minor bigint;
  v_is_walk_in boolean;
  v_correlation_id text;
  v_valuation_id uuid;
  v_details jsonb;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_offset_amount_minor bigint := 0;
  v_keep_minor bigint := 0;
  v_candidates jsonb := '[]'::jsonb;
  v_cand record;
  v_left bigint;
  v_x bigint;
begin
  if auth.uid() is distinct from actor_id
    or iam.has_permission(
      evaluate_return_exchange_valuation.tenant_id,
      'sales.return_exchange.view'
    ) is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED',
      'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_session
  from sales.return_exchange_orders
  where return_exchange_orders.id = evaluate_return_exchange_valuation.return_exchange_id
    and return_exchange_orders.tenant_id = evaluate_return_exchange_valuation.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND',
      'message', 'Return/exchange session not found.',
      'details', jsonb_build_object('returnExchangeId', return_exchange_id)
    )::text;
  end if;

  if v_session.status is distinct from 'draft' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Valuation requires a draft return/exchange session.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = v_session.sales_order_id
    and sales_orders.tenant_id = evaluate_return_exchange_valuation.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND',
      'message', 'Sales order not found.'
    )::text;
  end if;

  v_jwt_store := nullif(
    btrim(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'store_id'),
    ''
  );
  if v_jwt_store is not null
    and v_order.store_id is distinct from v_jwt_store::uuid then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED',
      'message', 'Store scope denied.'
    )::text;
  end if;

  if expected_source_version is not null
    and v_order.version is distinct from expected_source_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Sales order version is stale.',
      'details', jsonb_build_object('expectedSourceVersion', expected_source_version)
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = evaluate_return_exchange_valuation.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Authoritative settlement context is unavailable.'
    )::text;
  end if;

  v_currency := coalesce(v_session.currency_code, v_order.currency_code, v_settlement.currency_code);
  v_pricing_source_version := nullif(reference_decision ->> 'pricing_source_version', '')::integer;
  v_inventory_source_version := nullif(reference_decision ->> 'inventory_source_version', '')::integer;
  v_correlation_id := coalesce(
    nullif(btrim(v_session.correlation_id), ''),
    return_exchange_id::text
  );
  v_is_walk_in := v_order.customer_partner_id is null;

  -- Return value from original commercial snapshots on source order lines.
  for v_line in
    select
      rl.quantity_micros,
      rl.original_sales_order_line_id,
      rl.source_exchange_line_id,
      rl.line_role,
      rl.product_id,
      rl.product_unit_id,
      rl.unit_value_minor
    from sales.return_exchange_lines rl
    where rl.return_exchange_order_id = v_session.id
      and rl.tenant_id = evaluate_return_exchange_valuation.tenant_id
  loop
    if v_line.line_role = 'returned' then
      if v_line.source_exchange_line_id is not null then
        select xl.unit_value_minor into v_unit_price_minor
        from sales.return_exchange_lines xl
        where xl.id = v_line.source_exchange_line_id
          and xl.tenant_id = evaluate_return_exchange_valuation.tenant_id
          and xl.line_role = 'exchange';
        if v_unit_price_minor is null then
          raise exception using message = jsonb_build_object(
            'code', 'RETURN_EXCHANGE_BLOCKED',
            'message', 'Source exchange line valuation is missing.'
          )::text;
        end if;
      elsif v_line.original_sales_order_line_id is null then
        raise exception using message = jsonb_build_object(
          'code', 'RETURN_EXCHANGE_BLOCKED',
          'message', 'Returned lines must reference a returnable unit.'
        )::text;
      else
        -- S3: giá trị trả = phần thành tiền (đã trừ chiết khấu) tương ứng số lượng trả.
        select line_total_minor, quantity_micros
        into v_orig_line_total_minor, v_orig_quantity_micros
        from sales.sales_order_lines
        where id = v_line.original_sales_order_line_id
          and sales_order_id = v_order.id
          and tenant_id = evaluate_return_exchange_valuation.tenant_id;
        if not found or coalesce(v_orig_quantity_micros, 0) <= 0 then
          raise exception using message = jsonb_build_object(
            'code', 'RETURN_EXCHANGE_BLOCKED',
            'message', 'Original sales order line snapshot is missing.'
          )::text;
        end if;
        v_line_value_minor := round(v_orig_line_total_minor::numeric * v_line.quantity_micros / v_orig_quantity_micros)::bigint;
      end if;
      if v_line.source_exchange_line_id is not null then
        v_line_value_minor := v_unit_price_minor * v_line.quantity_micros / 1000000;
      end if;
      v_return_value_minor := v_return_value_minor + v_line_value_minor;
    elsif v_line.line_role = 'exchange' then
      -- Plan 2: giá món đổi = giá server đã ghi; tính lại để phát hiện giá vừa đổi.
      v_unit_price_minor := v_line.unit_value_minor;
      perform sales._assert_exchange_price(
        evaluate_return_exchange_valuation.tenant_id, v_order,
        v_line.product_id, v_line.product_unit_id, v_unit_price_minor
      );

      if v_unit_price_minor is null then
        raise exception using message = jsonb_build_object(
          'code', 'RETURN_EXCHANGE_BLOCKED',
          'message', 'Exchange pricing decision is missing.',
          'details', jsonb_build_object('productUnitId', v_line.product_unit_id)
        )::text;
      end if;
      if v_unit_price_minor < 0 then
        raise exception using message = jsonb_build_object(
          'code', 'RETURN_EXCHANGE_BLOCKED',
          'message', 'Exchange unit price is invalid.'
        )::text;
      end if;
      v_exchange_value_minor := v_exchange_value_minor
        + (v_unit_price_minor * v_line.quantity_micros / 1000000);
    end if;
  end loop;

  -- FC-14 / ADR-2: exchange_value_minor - return_value_minor.
  v_net_difference_minor := v_exchange_value_minor - v_return_value_minor;

  v_net_confirmed_collection := v_settlement.net_collected_amount_minor;
  if v_net_confirmed_collection < 0 then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Negative refundable capacity is not allowed.'
    )::text;
  end if;

  if v_net_difference_minor > 0 then
    -- Positive: customer owes (exchange > return) → collect / receivable create.
    -- collect_amount_minor + receivable_create_amount_minor == abs(net)
    v_abs_diff := v_net_difference_minor;
    v_collect_amount_minor := v_abs_diff;
    v_receivable_create_amount_minor := 0;
    if v_collect_amount_minor + v_receivable_create_amount_minor
      is distinct from v_abs_diff then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settlement plan collect/create components must balance.'
      )::text;
    end if;
  elsif v_net_difference_minor < 0 then
    -- Negative: store owes (return > exchange) → refund / receivable reverse.
    -- refund_amount_minor + receivable_reverse_amount_minor == abs(net)
    -- T6-1b (TH-06 2.2): giam no chinh don nguon truoc -> can tru -> hoan.
    v_abs_diff := abs(v_net_difference_minor);
    v_receivable_reverse_amount_minor := least(v_abs_diff, v_settlement.outstanding_amount_minor);
    -- con_lai khong vuot net_collected don nguon (BR-27); phan du neu co chuyen sang giam no.
    v_keep_minor := least(v_abs_diff - v_receivable_reverse_amount_minor, v_net_confirmed_collection);
    v_receivable_reverse_amount_minor := v_abs_diff - v_keep_minor;

    if v_keep_minor > 0 and v_order.customer_partner_id is not null then
      v_left := v_keep_minor;
      for v_cand in
        select o.sales_order_id, o.order_code, o.completed_at, o.outstanding_minor,
               o.due_date, o.settlement_version
        from receivable._open_orders(
          evaluate_return_exchange_valuation.tenant_id,
          evaluate_return_exchange_valuation.actor_id,
          v_order.customer_partner_id) o
        where o.sales_order_id <> v_order.id
        order by o.completed_at, o.order_code
      loop
        v_x := least(v_left, v_cand.outstanding_minor);
        v_left := v_left - v_x;
        v_offset_amount_minor := v_offset_amount_minor + v_x;
        v_candidates := v_candidates || jsonb_build_array(jsonb_build_object(
          'salesOrderId', v_cand.sales_order_id,
          'orderCode', v_cand.order_code,
          'completedAt', v_cand.completed_at,
          'outstandingMinor', v_cand.outstanding_minor,
          'offsetAmountMinor', v_x,
          'dueDate', v_cand.due_date,
          'overdueDays', case when v_cand.due_date < v_today then v_today - v_cand.due_date else 0 end,
          'settlementVersion', v_cand.settlement_version));
      end loop;
    end if;
    v_refund_amount_minor := v_keep_minor - v_offset_amount_minor;
    if v_refund_amount_minor + v_offset_amount_minor + v_receivable_reverse_amount_minor
      is distinct from v_abs_diff then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settlement plan refund/offset/reversal components must balance.'
      )::text;
    end if;
  else
    v_collect_amount_minor := 0;
    v_refund_amount_minor := 0;
    v_receivable_create_amount_minor := 0;
    v_receivable_reverse_amount_minor := 0;
  end if;

  if v_is_walk_in
    and (
      v_receivable_create_amount_minor > 0
      or v_receivable_reverse_amount_minor > 0
    ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Walk-in customers cannot use receivable create or reversal.'
    )::text;
  end if;

  v_details := jsonb_build_object(
    'reference_decision', coalesce(reference_decision, '{}'::jsonb)
  );

  insert into sales.return_exchange_valuations (
    id,
    tenant_id,
    return_exchange_order_id,
    currency_code,
    return_value_minor,
    exchange_value_minor,
    net_difference_minor,
    status,
    valuation_details,
    calculated_at
  ) values (
    gen_random_uuid(),
    evaluate_return_exchange_valuation.tenant_id,
    v_session.id,
    v_currency,
    v_return_value_minor,
    v_exchange_value_minor,
    v_net_difference_minor,
    'calculated',
    v_details,
    now()
  )
  on conflict (return_exchange_order_id) do update
  set
    currency_code = excluded.currency_code,
    return_value_minor = excluded.return_value_minor,
    exchange_value_minor = excluded.exchange_value_minor,
    net_difference_minor = excluded.net_difference_minor,
    status = 'calculated',
    valuation_details = excluded.valuation_details,
    calculated_at = now()
  returning id into v_valuation_id;

  insert into receivable.return_exchange_settlement_plans (
    id, tenant_id, return_exchange_order_id, sales_order_id, net_difference_minor,
    collect_amount_minor, receivable_create_amount_minor, receivable_reverse_amount_minor,
    offset_amount_minor, refund_amount_minor, offset_candidates,
    source_order_version, source_settlement_version, source_session_version,
    pricing_source_version, inventory_source_version, correlation_id,
    status, calculated_at
  ) values (
    gen_random_uuid(), evaluate_return_exchange_valuation.tenant_id, v_session.id, v_order.id,
    v_net_difference_minor, v_collect_amount_minor, v_receivable_create_amount_minor,
    v_receivable_reverse_amount_minor, v_offset_amount_minor, v_refund_amount_minor, v_candidates,
    v_order.version, v_settlement.version, v_session.version,
    v_pricing_source_version, v_inventory_source_version, v_correlation_id,
    'calculated', now()
  )
  on conflict (return_exchange_order_id) do update
  set
    sales_order_id = excluded.sales_order_id,
    net_difference_minor = excluded.net_difference_minor,
    collect_amount_minor = excluded.collect_amount_minor,
    receivable_create_amount_minor = excluded.receivable_create_amount_minor,
    receivable_reverse_amount_minor = excluded.receivable_reverse_amount_minor,
    offset_amount_minor = excluded.offset_amount_minor,
    refund_amount_minor = excluded.refund_amount_minor,
    offset_candidates = excluded.offset_candidates,
    source_order_version = excluded.source_order_version,
    source_settlement_version = excluded.source_settlement_version,
    source_session_version = excluded.source_session_version,
    pricing_source_version = excluded.pricing_source_version,
    inventory_source_version = excluded.inventory_source_version,
    correlation_id = excluded.correlation_id,
    status = 'calculated',
    calculated_at = now();

  return jsonb_build_object(
    'returnValue', jsonb_build_object(
      'amountMinor', v_return_value_minor,
      'currencyCode', v_currency
    ),
    'exchangeValue', jsonb_build_object(
      'amountMinor', v_exchange_value_minor,
      'currencyCode', v_currency
    ),
    'settlementDifference', jsonb_build_object(
      'amountMinor', v_net_difference_minor,
      'currencyCode', v_currency
    ),
    'settlementPlan', jsonb_build_object(
      'currencyCode', v_currency,
      'netDifferenceMinor', v_net_difference_minor,
      'collectAmountMinor', v_collect_amount_minor,
      'refundAmountMinor', v_refund_amount_minor,
      'receivableCreateAmountMinor', v_receivable_create_amount_minor,
      'receivableReverseAmountMinor', v_receivable_reverse_amount_minor,
      'processedCollectMinor', 0,
      'processedRefundMinor', 0,
      'pendingReceivableCreateMinor', 0,
      'pendingReceivableReverseMinor', 0,
      'remainderCollectMinor', v_collect_amount_minor,
      'remainderRefundMinor', v_refund_amount_minor,
      'offsetAmountMinor', v_offset_amount_minor,
      'offsetCandidates', v_candidates,
      'sourceOrderVersion', v_order.version,
      'sourceSettlementVersion', v_settlement.version,
      'pricingSourceVersion', v_pricing_source_version
    ),
    'sourceOrderVersion', v_order.version,
    'pricingSourceVersion', v_pricing_source_version
  );
end;
$function$
;

-- 4) Xac nhan doi/tra: them offset_target_order_ids, ghi can tru; thay settle_return_exchange_difference
drop function sales.confirm_return_exchange(text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date);

CREATE OR REPLACE FUNCTION sales.confirm_return_exchange(command_id text, tenant_id uuid, actor_id uuid, return_exchange_id uuid, idempotency_key text, payload_hash text, correlation_id text, causation_id text DEFAULT NULL::text, expected_version integer DEFAULT NULL::integer, reference_decision jsonb DEFAULT '{}'::jsonb, payment_settled_now_minor bigint DEFAULT NULL::bigint, payment_method text DEFAULT 'cash'::text, payment_due_date date DEFAULT NULL::date, offset_target_order_ids uuid[] DEFAULT '{}'::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'inventory', 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_decision jsonb;
  v_correlation uuid;
  v_settled_now bigint;
  v_collect_debt bigint := 0;
  v_session sales.return_exchange_orders%rowtype;
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_valuation sales.return_exchange_valuations%rowtype;
  v_pl receivable.return_exchange_settlement_plans%rowtype;
  v_jwt_store text;
  v_result jsonb;
  v_line record;
  v_reserved_micros bigint;
  v_blockers jsonb;
  v_pricing_source_version integer;
  v_inventory_source_version integer;
  v_inventory_required boolean := false;
  v_has_returned boolean := false;
  v_has_exchange boolean := false;
  v_receivable_required boolean := false;
  v_entry_source text;
  v_decision_snapshot jsonb;
  v_plan_corr text;
  v_remainder_collect bigint;
  v_remainder_refund bigint;
  v_plan_currency text;
  v_recv_create bigint;
  v_recv_reverse bigint;
  v_source_order_version bigint;
  v_source_settlement_version bigint;
  v_plan_pricing_version integer;
  v_exchange_line record;
  v_resulting_version bigint;
  v_sold_base_micros bigint;
  v_returned_base_micros bigint;
  v_return_status text;
  v_exchange_issue_res jsonb;
  v_ex_issue_line jsonb;
  v_tx_id uuid;
  v_left bigint;
  v_x bigint;
  v_target record;
  v_offset_id uuid;
  v_ref_tx uuid;
  v_col_tx uuid;
begin
  if tenant_id is null
    or nullif(btrim(idempotency_key), '') is null then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Required confirmation identity is missing.'
    )::text;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      tenant_id::text || ':confirm_return_exchange:' || idempotency_key,
      0
    )
  );

  begin
    v_correlation := nullif(btrim(correlation_id), '')::uuid;
  exception when others then
    v_correlation := null;
  end;
  if v_correlation is null then
    begin
      v_correlation := nullif(btrim(command_id), '')::uuid;
    exception when others then
      v_correlation := gen_random_uuid();
    end;
  end if;
  if v_correlation is null then
    v_correlation := gen_random_uuid();
  end if;

  -- 'IDEMPOTENCY_CONFLICT' via sales._begin_sales_idempotency on hash mismatch.
  v_decision := sales._begin_sales_idempotency(
    confirm_return_exchange.tenant_id,
    'confirm_return_exchange',
    trim(idempotency_key),
    coalesce(nullif(btrim(payload_hash), ''), ''));
  if (v_decision ->> 'decision') = 'replay' then
    return v_decision -> 'result_snapshot';
  end if;
  if (v_decision ->> 'decision') = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Idempotency key is already in progress.'
    )::text;
  end if;

  if nullif(btrim(command_id), '') is null
    or actor_id is null
    or return_exchange_id is null
    or nullif(btrim(payload_hash), '') is null
    or nullif(btrim(correlation_id), '') is null
    or expected_version is null
    or expected_version <= 0 then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Required confirmation arguments are missing or invalid.'
    )::text;
  end if;

  if auth.uid() is distinct from actor_id
    or iam.has_permission(tenant_id, 'sales.return_exchange.confirm') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED',
      'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_session
  from sales.return_exchange_orders
  where return_exchange_orders.id = confirm_return_exchange.return_exchange_id
    and return_exchange_orders.tenant_id = confirm_return_exchange.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND',
      'message', 'Return/exchange session not found.',
      'details', jsonb_build_object('returnExchangeId', return_exchange_id)
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = v_session.sales_order_id
    and sales_orders.tenant_id = confirm_return_exchange.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND',
      'message', 'Sales order not found.'
    )::text;
  end if;

  v_jwt_store := nullif(
    btrim(coalesce(current_setting('request.jwt.claims', true), '{}')::jsonb ->> 'store_id'),
    ''
  );
  if v_order.store_id is null
    or (
      v_jwt_store is not null
      and v_order.store_id is distinct from v_jwt_store::uuid
    ) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED',
      'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = confirm_return_exchange.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'DEPENDENCY_UNAVAILABLE',
      'message', 'Authoritative settlement is unavailable.'
    )::text;
  end if;

  perform 1
  from sales.return_exchange_orders r
  where r.tenant_id = confirm_return_exchange.tenant_id
    and r.sales_order_id = v_session.sales_order_id
    and r.id is distinct from v_session.id
    and r.status in ('confirmed', 'processing', 'completed')
  for update;

  perform 1
  from sales.sales_order_cancellations c
  where c.tenant_id = confirm_return_exchange.tenant_id
    and c.sales_order_id = v_session.sales_order_id
    and c.status in ('requested', 'validating', 'confirmed', 'processing', 'completed')
  for update;

  if v_session.version is distinct from expected_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Return/exchange version is stale.',
      'details', jsonb_build_object(
        'expectedVersion', expected_version,
        'actualVersion', v_session.version
      )
    )::text;
  end if;

  if v_session.status is distinct from 'draft' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Only draft return/exchange sessions may be confirmed.'
    )::text;
  end if;

  if v_session.confirmation_decision_snapshot is not null
    or v_session.confirmed_at is not null then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Return/exchange already has immutable confirmation evidence.'
    )::text;
  end if;

  if exists (
    select 1
    from sales.return_exchange_lines rl
    where rl.tenant_id = confirm_return_exchange.tenant_id
      and rl.return_exchange_order_id = v_session.id
      and (
        rl.product_snapshot is null
        or rl.product_unit_snapshot is null
        or rl.unit_value_minor is null
        or (
          rl.line_role = 'returned'
          and (rl.original_sales_order_line_id is null and rl.source_exchange_line_id is null)
        )
        or (
          rl.line_role = 'exchange'
          and (
            rl.return_reason_code is not null
            or rl.return_condition_code is not null
            or rl.original_sales_order_line_id is not null
          )
        )
      )
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Stored return/exchange line policies or snapshots failed revalidation.'
    )::text;
  end if;

  -- Plan 2: giá món đổi phải còn đúng tại lúc xác nhận.
  for v_exchange_line in
    select rl.product_id, rl.product_unit_id, rl.unit_value_minor
    from sales.return_exchange_lines rl
    where rl.tenant_id = confirm_return_exchange.tenant_id
      and rl.return_exchange_order_id = v_session.id
      and rl.line_role = 'exchange'
  loop
    perform sales._assert_exchange_price(
      confirm_return_exchange.tenant_id, v_order,
      v_exchange_line.product_id, v_exchange_line.product_unit_id,
      v_exchange_line.unit_value_minor
    );
  end loop;

  for v_line in
    select
      rl.original_sales_order_line_id,
      rl.source_exchange_line_id,
      rl.quantity_micros as request_micros,
      coalesce(l.quantity_micros, xl.quantity_micros) as sold_micros
    from sales.return_exchange_lines rl
    left join sales.sales_order_lines l
      on l.id = rl.original_sales_order_line_id
     and l.sales_order_id = v_session.sales_order_id
     and l.tenant_id = confirm_return_exchange.tenant_id
    left join sales.return_exchange_lines xl
      on xl.id = rl.source_exchange_line_id
     and xl.tenant_id = confirm_return_exchange.tenant_id
     and xl.line_role = 'exchange'
    where rl.return_exchange_order_id = v_session.id
      and rl.tenant_id = confirm_return_exchange.tenant_id
      and rl.line_role = 'returned'
  loop
    if v_line.sold_micros is null
       or (v_line.original_sales_order_line_id is null and v_line.source_exchange_line_id is null) then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Returned lines must reference a returnable unit.'
      )::text;
    end if;

    select coalesce(sum(rl.quantity_micros), 0) into v_reserved_micros
    from sales.return_exchange_lines rl
    inner join sales.return_exchange_orders r
      on r.id = rl.return_exchange_order_id
    where r.tenant_id = confirm_return_exchange.tenant_id
      and r.sales_order_id = v_session.sales_order_id
      and r.id is distinct from v_session.id
      and r.status in ('confirmed', 'processing', 'completed')
      and rl.line_role = 'returned'
      and (
        (v_line.original_sales_order_line_id is not null
          and rl.original_sales_order_line_id = v_line.original_sales_order_line_id)
        or (v_line.source_exchange_line_id is not null
          and rl.source_exchange_line_id = v_line.source_exchange_line_id)
      );

    if v_line.request_micros > (v_line.sold_micros - v_reserved_micros) then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_QUANTITY_EXCEEDED',
        'message', 'Returned quantity exceeds remaining returnable quantity.',
        'details', jsonb_build_object(
          'originalSalesOrderLineId', v_line.original_sales_order_line_id,
          'sourceExchangeLineId', v_line.source_exchange_line_id,
          'requestMicros', v_line.request_micros,
          'remainingMicros', v_line.sold_micros - v_reserved_micros
        )
      )::text;
    end if;
  end loop;

  if not exists (
    select 1
    from sales.return_exchange_lines rl
    where rl.return_exchange_order_id = v_session.id
      and rl.tenant_id = confirm_return_exchange.tenant_id
      and rl.line_role = 'returned'
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Confirmation requires at least one returned line.'
    )::text;
  end if;

  if exists (
    select 1
    from sales.sales_order_cancellations c
    where c.tenant_id = confirm_return_exchange.tenant_id
      and c.sales_order_id = v_session.sales_order_id
      and c.status in ('requested', 'validating', 'confirmed', 'processing', 'completed')
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'An active or committed cancellation blocks return/exchange confirmation.'
    )::text;
  end if;

  v_blockers := coalesce(reference_decision -> 'blockers', '[]'::jsonb);
  if jsonb_typeof(v_blockers) is distinct from 'array'
    or jsonb_array_length(v_blockers) > 0 then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Provider decisions block confirmation.',
      'details', jsonb_build_object('blockers', v_blockers)
    )::text;
  end if;

  v_pricing_source_version := nullif(reference_decision ->> 'pricing_source_version', '')::integer;
  v_inventory_source_version := nullif(reference_decision ->> 'inventory_source_version', '')::integer;

  select * into v_valuation
  from sales.return_exchange_valuations
  where return_exchange_valuations.tenant_id = confirm_return_exchange.tenant_id
    and return_exchange_valuations.return_exchange_order_id = v_session.id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Versioned valuation is required before confirmation.'
    )::text;
  end if;

  select * into v_pl
  from receivable.return_exchange_settlement_plans p
  where p.tenant_id = confirm_return_exchange.tenant_id
    and p.return_exchange_order_id = v_session.id
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Stored settlement plan is required before confirmation.'
    )::text;
  end if;

  v_source_order_version := v_pl.source_order_version;
  v_source_settlement_version := v_pl.source_settlement_version;
  v_plan_pricing_version := v_pl.pricing_source_version;
  v_remainder_collect := v_pl.collect_amount_minor;
  v_remainder_refund := v_pl.refund_amount_minor;
  v_plan_currency := v_valuation.currency_code;
  v_plan_corr := coalesce(nullif(v_pl.correlation_id, ''), v_session.correlation_id, v_session.id::text);
  v_recv_create := v_pl.receivable_create_amount_minor;
  v_recv_reverse := v_pl.receivable_reverse_amount_minor;

  if v_source_order_version is distinct from v_order.version
    or v_source_settlement_version is distinct from v_settlement.version
    or (
      -- B3b: valuation phai thuoc noi dung phien hien tai (source_session_version).
      -- Guard is-not-null de tuong thich valuation cu tao truoc B3a.
      v_pl.source_session_version is not null
      and v_pl.source_session_version is distinct from v_session.version
    )
    or (
      v_pricing_source_version is not null
      and v_plan_pricing_version is not null
      and v_pricing_source_version is distinct from v_plan_pricing_version
    ) then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Valuation, settlement plan, or provider version is stale.'
    )::text;
  end if;

  -- T6-1b: don nhan can tru phai hop le va con dung phien ban — kiem truoc khi dung toi kho.
  if coalesce(cardinality(offset_target_order_ids), 0) > 0 then
    if (select count(distinct x.id) from unnest(offset_target_order_ids) x(id))
         <> cardinality(offset_target_order_ids)
       or v_order.customer_partner_id is null
       or exists (
         select 1 from unnest(offset_target_order_ids) x(id)
         where not exists (
           select 1 from sales.sales_orders t
           where t.tenant_id = confirm_return_exchange.tenant_id
             and t.id = x.id
             and t.id <> v_order.id
             and t.customer_partner_id = v_order.customer_partner_id
             and t.lifecycle_status = 'completed'
             and iam.can_access_store(
               confirm_return_exchange.tenant_id, t.store_id, confirm_return_exchange.actor_id)
         )
       ) then
      raise exception using message = jsonb_build_object(
        'code', 'OFFSET_TARGET_INVALID',
        'message', 'Offset target orders are invalid.'
      )::text;
    end if;

    perform 1
    from receivable.sales_order_settlements s
    where s.tenant_id = confirm_return_exchange.tenant_id
      and s.sales_order_id = any (offset_target_order_ids)
    order by s.id
    for update;

    if exists (
      select 1 from unnest(offset_target_order_ids) x(id)
      where not exists (
        select 1
        from jsonb_array_elements(v_pl.offset_candidates) c
        join receivable.sales_order_settlements s
          on s.tenant_id = confirm_return_exchange.tenant_id
         and s.sales_order_id = x.id
        where (c ->> 'salesOrderId')::uuid = x.id
          and (c ->> 'settlementVersion')::bigint = s.version
          and s.outstanding_amount_minor > 0
      )
    ) then
      raise exception using message = jsonb_build_object(
        'code', 'STALE_VERSION',
        'message', 'Offset target receivable has changed.'
      )::text;
    end if;
  end if;

  -- Client-directed split of remaining collect; null defaults to full remainder.
  -- B3b: khong clamp — input am hoac vuot remainder phai bao loi (khong tra success sai so).
  if payment_settled_now_minor is not null then
    if payment_settled_now_minor < 0 then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settled-now amount cannot be negative.'
      )::text;
    end if;
    if payment_settled_now_minor > v_remainder_collect then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settled-now amount exceeds remaining collect capacity.'
      )::text;
    end if;
  end if;
  v_settled_now := coalesce(payment_settled_now_minor, v_remainder_collect);
  v_collect_debt := v_remainder_collect - v_settled_now;

  if v_collect_debt > 0 then
    if v_order.customer_partner_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Walk-in customers cannot defer payment into a receivable.'
      )::text;
    end if;
    if payment_due_date is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Payment due date is required for an outstanding balance.'
      )::text;
    end if;
    if payment_due_date < (now() at time zone 'Asia/Ho_Chi_Minh')::date then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Payment due date cannot be before today.'
      )::text;
    end if;
  end if;

  v_entry_source := coalesce(nullif(btrim(v_session.entry_source), ''), 'standard');

  select
    exists (
      select 1 from sales.return_exchange_lines rl
      where rl.return_exchange_order_id = v_session.id
        and rl.tenant_id = confirm_return_exchange.tenant_id
        and rl.line_role = 'returned'
    ),
    exists (
      select 1 from sales.return_exchange_lines rl
      where rl.return_exchange_order_id = v_session.id
        and rl.tenant_id = confirm_return_exchange.tenant_id
        and rl.line_role = 'exchange'
    )
  into v_has_returned, v_has_exchange;

  v_inventory_required := v_has_returned or v_has_exchange;
  v_receivable_required := (
    v_recv_create > 0
    or v_recv_reverse > 0
    or v_collect_debt > 0
  );

  v_resulting_version := v_session.version + 1;
  v_decision_snapshot := jsonb_build_object(
    'sourceOrderVersion', v_order.version,
    'sourceSettlementVersion', v_settlement.version,
    'pricingSourceVersion', v_pricing_source_version,
    'inventorySourceVersion', v_inventory_source_version,
    'entrySource', v_entry_source,
    'reasonCode', null,
    'conditionCode', null,
    'impacts', jsonb_build_object(
      'inventory', case when v_inventory_required then 'required' else 'not_required' end,
      'receivable', case when v_receivable_required then 'required' else 'not_required' end,
      'eInvoice', 'not_required',
      'pricing', 'required',
      'reporting', 'required'
    )
  );

  update sales.return_exchange_orders
  set
    status = 'confirmed',
    version = v_resulting_version,
    source_order_version = v_order.version,
    source_settlement_version = v_settlement.version,
    confirmed_by_user_id = confirm_return_exchange.actor_id,
    confirmed_at = now(),
    confirmation_decision_snapshot = v_decision_snapshot,
    updated_at = now()
  where id = v_session.id;

  update sales.return_exchange_valuations
  set status = 'confirmed'
  where id = v_valuation.id;

  -- Reverse sale for returned lines
  if v_has_returned then
    perform inventory._reverse_sale(
      confirm_return_exchange.tenant_id,
      v_order.store_id,
      'RETURN_EXCHANGE',
      v_session.id,
      (
        select jsonb_agg(jsonb_build_object(
          'line_id', rl.id,
          'source_intent_type', case when rl.source_exchange_line_id is not null then 'RETURN_EXCHANGE' else 'SALES_ORDER' end,
          'source_intent_line_id', coalesce(rl.source_exchange_line_id, rl.original_sales_order_line_id),
          'product_id', rl.product_id,
          'base_qty', rl.base_quantity_micros::numeric / 1000000.0
        ))
        from sales.return_exchange_lines rl
        where rl.tenant_id = confirm_return_exchange.tenant_id
          and rl.return_exchange_order_id = v_session.id
          and rl.line_role = 'returned'
      ),
      confirm_return_exchange.actor_id
    );
  end if;

  -- Issue stock FEFO for exchange lines
  if v_has_exchange then
    v_exchange_issue_res := inventory._issue_for_sale(
      confirm_return_exchange.tenant_id,
      v_order.store_id,
      'RETURN_EXCHANGE',
      v_session.id,
      (
        select jsonb_agg(jsonb_build_object(
          'line_id', rl.id,
          'product_id', rl.product_id,
          'base_qty', rl.base_quantity_micros::numeric / 1000000.0,
          'unit_name', coalesce(rl.product_unit_snapshot ->> 'unitName', ''),
          'conversion_rate', case when coalesce(rl.quantity_micros, 0) > 0 then rl.base_quantity_micros::numeric / rl.quantity_micros else 1 end
        ))
        from sales.return_exchange_lines rl
        where rl.tenant_id = confirm_return_exchange.tenant_id
          and rl.return_exchange_order_id = v_session.id
          and rl.line_role = 'exchange'
      ),
      confirm_return_exchange.actor_id
    );

    for v_ex_issue_line in select * from jsonb_array_elements(coalesce(v_exchange_issue_res -> 'lines', '[]'::jsonb)) loop
      update sales.return_exchange_lines
      set cogs_amount_vnd = (v_ex_issue_line ->> 'cogs_amount_vnd')::bigint,
          cogs_unit_cost = (v_ex_issue_line ->> 'cogs_unit_cost')::numeric,
          cost_version_id = nullif(v_ex_issue_line ->> 'cost_version_id', '')::uuid,
          cogs_is_provisional = coalesce((v_ex_issue_line ->> 'is_provisional')::boolean, false)
      where tenant_id = confirm_return_exchange.tenant_id
        and return_exchange_order_id = v_session.id
        and id = (v_ex_issue_line ->> 'line_id')::uuid;
    end loop;
  end if;

  -- T6-1b: ghi giao dich tien truoc, dieu chinh nghia vu sau (nhu cu).
  if v_remainder_collect > 0 and v_settled_now > 0 then
    v_tx_id := receivable._post_money_transaction(
      confirm_return_exchange.tenant_id, v_settlement.id, 'collection', v_settled_now,
      coalesce(nullif(btrim(payment_method), ''), 'cash'),
      'return_exchange', 'return_exchange_order', v_session.id,
      confirm_return_exchange.actor_id, 'confirm:' || v_plan_corr);
    perform sales._emit_sales_settlement_changed(
      confirm_return_exchange.tenant_id, v_settlement.id,
      'return_exchange_difference', v_session.id::text, 'confirm_return_exchange');
  end if;

  -- Khach duoc huong: can tru sang don nhan da chon (cu truoc), phan con lai hoan tien.
  v_left := v_pl.offset_amount_minor + v_pl.refund_amount_minor;
  if v_left > 0 then
    for v_target in
      select s.id as settlement_id, t.id as order_id, t.order_code::text as order_code,
             s.outstanding_amount_minor as outstanding
      from sales.sales_orders t
      join receivable.sales_order_settlements s
        on s.tenant_id = t.tenant_id and s.sales_order_id = t.id
      where t.tenant_id = confirm_return_exchange.tenant_id
        and t.id = any (offset_target_order_ids)
      order by t.completed_at, t.order_code
    loop
      exit when v_left <= 0;
      v_x := least(v_left, v_target.outstanding);
      continue when v_x <= 0;
      v_left := v_left - v_x;
      v_offset_id := gen_random_uuid();

      v_ref_tx := receivable._post_money_transaction(
        confirm_return_exchange.tenant_id, v_settlement.id, 'refund', v_x, 'offset',
        'return_exchange', 'receivable_offset', v_offset_id,
        confirm_return_exchange.actor_id, null);
      v_col_tx := receivable._post_money_transaction(
        confirm_return_exchange.tenant_id, v_target.settlement_id, 'collection', v_x, 'offset',
        'return_exchange', 'receivable_offset', v_offset_id,
        confirm_return_exchange.actor_id, null);

      insert into receivable.receivable_offsets (
        id, tenant_id, customer_partner_id, return_exchange_order_id,
        source_sales_order_id, target_sales_order_id, amount_minor,
        source_refund_transaction_id, target_collection_transaction_id,
        created_by_user_id, occurred_at
      ) values (
        v_offset_id, confirm_return_exchange.tenant_id, v_order.customer_partner_id, v_session.id,
        v_order.id, v_target.order_id, v_x, v_ref_tx, v_col_tx,
        confirm_return_exchange.actor_id, clock_timestamp()
      );

      insert into sales.outbox_messages (id, tenant_id, event_type, payload)
      select gen_random_uuid(), confirm_return_exchange.tenant_id, 'receivable_offset_recorded.v1',
        jsonb_build_object(
          'salesOrderId', o.id::text,
          'offsetId', v_offset_id::text,
          'returnExchangeId', v_session.id::text,
          'sourceSalesOrderId', v_order.id::text,
          'targetSalesOrderId', v_target.order_id::text,
          'amountMinor', v_x,
          'actorId', confirm_return_exchange.actor_id::text,
          'correlationId', v_correlation::text
        )
      from unnest(array[v_order.id, v_target.order_id]) o(id);

      perform sales._emit_sales_settlement_changed(
        confirm_return_exchange.tenant_id, v_target.settlement_id,
        'receivable_offset', v_offset_id::text, 'confirm_return_exchange');

      perform sales.generate_sales_receipt(
        p_command_id => gen_random_uuid(),
        p_tenant_id => confirm_return_exchange.tenant_id,
        p_actor_id => confirm_return_exchange.actor_id,
        p_sales_order_id => v_target.order_id,
        p_idempotency_key => 'receivable_offset:' || v_offset_id::text,
        p_payload_hash => md5(v_offset_id::text),
        p_correlation_id => v_correlation::text);
    end loop;

    if v_left > 0 then
      v_tx_id := receivable._post_money_transaction(
        confirm_return_exchange.tenant_id, v_settlement.id, 'refund', v_left,
        coalesce(nullif(btrim(payment_method), ''), 'cash'),
        'return_exchange', 'return_exchange_order', v_session.id,
        confirm_return_exchange.actor_id, 'confirm:' || v_plan_corr);
      perform sales._emit_sales_settlement_changed(
        confirm_return_exchange.tenant_id, v_settlement.id,
        'return_exchange_difference', v_session.id::text, 'confirm_return_exchange');
    end if;
  end if;

  update receivable.return_exchange_settlement_plans
  set status = 'confirmed'
  where id = v_pl.id;

  -- Model B handoff deferred: confirmation only publishes Sales lifecycle facts.
  insert into sales.outbox_messages (id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(),
    confirm_return_exchange.tenant_id,
    'return_exchange_confirmed.v1',
    jsonb_build_object(
      'returnExchangeId', v_session.id,
      'salesOrderId', v_session.sales_order_id,
      'correlationId', confirm_return_exchange.correlation_id,
      'impacts', v_decision_snapshot -> 'impacts'
    )
  );


  -- Model B handoff deferred: no pricing reverse_commitment command is dispatched.

  -- Single-phase completion (TH-05): finalize the return/exchange immediately.
  update sales.return_exchange_orders
  set
    status = 'completed',
    version = v_resulting_version,
    completed_by_user_id = confirm_return_exchange.actor_id,
    completed_at = now(),
    updated_at = now()
  where id = v_session.id;

  -- B2b: fully_returned tinh PER-ORIGINAL-LINE, chi dem dong tra co nguon GOC
  -- (original_sales_order_line_id). Dong tra nguon exchange KHONG lam giam luong ban goc.
  -- So sanh theo tung dong goc bang quantity_micros (dong tra tham chieu 1 dong goc va
  -- nhap theo don vi cua dong do — danh sach returnable theo dung don vi nguon).
  -- (Neu sau nay cho phep tra khac don vi voi luc ban, can chuyen sang base_quantity
  --  o ca dong tra lan dong goc.)
  with per_line as (
    select
      l.id,
      l.quantity_micros as sold_qty,
      l.base_quantity_micros as sold_base,
      coalesce(returned.qty, 0) as returned_qty,
      coalesce(returned.base, 0) as returned_base
    from sales.sales_order_lines l
    left join lateral (
      select sum(rl.quantity_micros) as qty, sum(rl.base_quantity_micros) as base
      from sales.return_exchange_lines rl
      join sales.return_exchange_orders r
        on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
      where r.tenant_id = confirm_return_exchange.tenant_id
        and r.sales_order_id = v_session.sales_order_id
        and r.status = 'completed'
        and rl.line_role = 'returned'
        and rl.original_sales_order_line_id = l.id
    ) returned on true
    where l.sales_order_id = v_session.sales_order_id
      and l.tenant_id = confirm_return_exchange.tenant_id
  )
  select
    coalesce(sum(sold_base), 0),
    coalesce(sum(returned_base), 0),
    case
      when count(*) = 0 then 'none'
      when bool_or(returned_qty > 0) and bool_and(returned_qty >= sold_qty)
        then 'fully_returned'
      when bool_or(returned_qty > 0) then 'partially_returned'
      else 'none'
    end
  into v_sold_base_micros, v_returned_base_micros, v_return_status
  from per_line;

  insert into sales.sales_order_return_status_projections (
    tenant_id,
    sales_order_id,
    return_status,
    updated_at
  ) values (
    confirm_return_exchange.tenant_id,
    v_session.sales_order_id,
    v_return_status,
    now()
  )
  on conflict (tenant_id, sales_order_id) do update
  set
    return_status = excluded.return_status,
    updated_at = now();

  -- Doi/tra lam thay doi noi dung thuong mai cua don: tang version (giong huy don)
  -- de hoa don dien tu va man hinh dang giu version cu biet du lieu da cu.
  update sales.sales_orders
  set version = version + 1,
      updated_at = now()
  where id = v_order.id
    and tenant_id = v_order.tenant_id;

  -- T6-1a: ngay hen tra nam o quyet toan (khong tang version quyet toan; ledger lo viec do).
  update receivable.sales_order_settlements s
  set payment_due_date = confirm_return_exchange.payment_due_date,
      updated_at = now()
  where v_collect_debt > 0
    and s.sales_order_id = v_order.id
    and s.tenant_id = v_order.tenant_id;

  -- B4b: cap nhat nghia vu settlement theo chenh lech dinh gia (exchange - return),
  -- mot lan/nguon (source_id = session) qua ledger idempotent, cung transaction confirm.
  -- current_payable doi theo nghia vu; tien mat (thu/hoan) van di rieng qua settle.
  perform sales._apply_settlement_obligation_adjustment(
    confirm_return_exchange.tenant_id,
    v_settlement.id,
    'return_exchange',
    v_session.id,
    coalesce(v_valuation.exchange_value_minor, 0)
      - coalesce(v_valuation.return_value_minor, 0)
  );

  -- Money snapshot after obligation recompute. return_exchange_completed owns goods, not money.
  perform sales._emit_sales_settlement_changed(
    confirm_return_exchange.tenant_id,
    v_settlement.id,
    'return_exchange',
    v_session.id::text,
    'confirm_return_exchange'
  );

  insert into sales.outbox_messages (id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(),
    confirm_return_exchange.tenant_id,
    'return_exchange_completed.v1',
    jsonb_build_object(
      'returnExchangeId', v_session.id,
      'salesOrderId', v_session.sales_order_id,
      'returnStatus', v_return_status,
      'correlationId', confirm_return_exchange.correlation_id,
      'soldBaseQuantityMicros', v_sold_base_micros,
      'returnedBaseQuantityMicros', v_returned_base_micros
    )
  );

  v_result := jsonb_build_object(
    'returnExchangeId', v_session.id::text,
    'salesOrderId', v_session.sales_order_id::text,
    'version', v_resulting_version,
    'status', 'completed'
  );

  perform sales._complete_sales_idempotency(
    confirm_return_exchange.tenant_id,
    'confirm_return_exchange',
    trim(idempotency_key),
    'succeeded',
    v_result);

  return v_result;
end;
$function$
;

revoke all on function sales.confirm_return_exchange(
  text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date, uuid[]
) from public, anon;
grant execute on function sales.confirm_return_exchange(
  text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date, uuid[]
) to authenticated;

-- 5) Xoa ham thanh toan chenh lech cu (chi confirm tung goi)
drop function sales.settle_return_exchange_difference(text, uuid, uuid, text, uuid, uuid, bigint, text, text, text, text, text, text, text, bigint);

-- 6) Doc chi tiet doi/tra: ke hoach doc tu bang
create or replace function sales.get_return_exchange_detail(
  query_id text,
  tenant_id uuid,
  actor_id uuid,
  return_exchange_id uuid,
  expected_version integer default null
) returns jsonb
language plpgsql
security definer
set search_path = sales, iam, public, pg_temp
as $$
#variable_conflict use_column
declare
  v_session sales.return_exchange_orders%rowtype;
  v_order sales.sales_orders%rowtype;
  v_valuation sales.return_exchange_valuations%rowtype;
  v_lines jsonb;
  v_impacts jsonb;
  v_completion_ready boolean := false;
  v_pl receivable.return_exchange_settlement_plans%rowtype;
  v_plan_json jsonb := 'null'::jsonb;
begin
  if auth.uid() is distinct from actor_id
    or iam.has_permission(tenant_id, 'sales.return_exchange.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_session
  from sales.return_exchange_orders
  where return_exchange_orders.id = get_return_exchange_detail.return_exchange_id
    and return_exchange_orders.tenant_id = get_return_exchange_detail.tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Return/exchange session not found.'
    )::text;
  end if;

  if expected_version is not null
     and v_session.version is distinct from expected_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION', 'message', 'Return/exchange version is stale.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = v_session.sales_order_id
    and sales_orders.tenant_id = get_return_exchange_detail.tenant_id;
  if not found or not iam.can_access_store(get_return_exchange_detail.tenant_id, v_order.store_id, get_return_exchange_detail.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_valuation
  from sales.return_exchange_valuations v
  where v.tenant_id = get_return_exchange_detail.tenant_id
    and v.return_exchange_order_id = v_session.id
  order by v.calculated_at desc, v.id desc
  limit 1;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kind', case rl.line_role when 'returned' then 'returnLine' else 'exchangeLine' end,
      'productId', rl.product_id,
      'productUnitId', rl.product_unit_id,
      'quantity', jsonb_build_object('quantityMicros', rl.quantity_micros),
      'originalSalesOrderLineId', rl.original_sales_order_line_id,
      'sourceExchangeLineId', rl.source_exchange_line_id,
      'reasonCode', rl.return_reason_code,
      'conditionCode', rl.return_condition_code,
      'lineSnapshot', jsonb_build_object(
        'product', rl.product_snapshot,
        'unit', rl.product_unit_snapshot,
        'unitPrice', jsonb_build_object(
          'amountMinor', rl.unit_value_minor,
          'currencyCode', v_session.currency_code
        )
      )
    )
    order by rl.line_sequence, rl.id
  ), '[]'::jsonb)
  into v_lines
  from sales.return_exchange_lines rl
  where rl.tenant_id = get_return_exchange_detail.tenant_id
    and rl.return_exchange_order_id = v_session.id;

  -- Model B handoff deferred: Sales no longer tracks downstream impact requests.
  v_impacts := '[]'::jsonb;

  v_completion_ready := v_session.status in ('confirmed', 'processing')
    and v_valuation.id is not null
    and v_valuation.status in ('calculated', 'confirmed');

  select * into v_pl
  from receivable.return_exchange_settlement_plans p
  where p.tenant_id = get_return_exchange_detail.tenant_id
    and p.return_exchange_order_id = v_session.id;
  if found then
    v_plan_json := jsonb_build_object(
      'currencyCode', v_valuation.currency_code,
      'netDifferenceMinor', v_pl.net_difference_minor,
      'collectAmountMinor', v_pl.collect_amount_minor,
      'refundAmountMinor', v_pl.refund_amount_minor,
      'receivableCreateAmountMinor', v_pl.receivable_create_amount_minor,
      'receivableReverseAmountMinor', v_pl.receivable_reverse_amount_minor,
      'offsetAmountMinor', v_pl.offset_amount_minor,
      'offsetCandidates', v_pl.offset_candidates,
      'processedCollectMinor', case when v_session.status = 'completed' then v_pl.collect_amount_minor else 0 end,
      'processedRefundMinor', case when v_session.status = 'completed' then v_pl.refund_amount_minor else 0 end,
      'pendingReceivableCreateMinor', 0,
      'pendingReceivableReverseMinor', 0,
      'remainderCollectMinor', case when v_session.status = 'completed' then 0 else v_pl.collect_amount_minor end,
      'remainderRefundMinor', case when v_session.status = 'completed' then 0 else v_pl.refund_amount_minor end,
      'sourceOrderVersion', v_pl.source_order_version,
      'sourceSettlementVersion', v_pl.source_settlement_version,
      'pricingSourceVersion', v_pl.pricing_source_version
    );
  end if;

  return jsonb_build_object(
    'returnExchangeId', v_session.id,
    'salesOrderId', v_session.sales_order_id,
    'referenceNumber', v_session.reference_number,
    'entrySource', coalesce(v_session.entry_source, 'standard'),
    'version', v_session.version,
    'status', v_session.status,
    'completionReady', v_completion_ready,
    'createdAt', to_char(
      v_session.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
    ),
    'confirmedAt', case
      when v_session.confirmed_at is null then null
      else to_char(
        v_session.confirmed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
      )
    end,
    'completedAt', case
      when v_session.completed_at is null then null
      else to_char(
        v_session.completed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
      )
    end,
    'lines', v_lines,
    'valuation', case
      when v_valuation.id is null then null
      else jsonb_build_object(
        'returnValue', jsonb_build_object(
          'amountMinor', v_valuation.return_value_minor,
          'currencyCode', v_valuation.currency_code
        ),
        'exchangeValue', jsonb_build_object(
          'amountMinor', v_valuation.exchange_value_minor,
          'currencyCode', v_valuation.currency_code
        ),
        'netDifference', jsonb_build_object(
          'amountMinor', v_valuation.net_difference_minor,
          'currencyCode', v_valuation.currency_code
        ),
        'status', v_valuation.status
      )
    end,
    'settlementPlan', v_plan_json,
    'impacts', coalesce(v_impacts, '[]'::jsonb)
  );
end;
$$;

-- 7) RPC doc TH-05: phuong thuc offset
CREATE OR REPLACE FUNCTION sales.get_sales_order_payment_summary(p_query_id uuid, p_tenant_id uuid, p_actor_id uuid, p_sales_order_id uuid, p_expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_due_at text;
  v_checkout_cash_minor bigint := 0;
  v_checkout_bank_minor bigint := 0;
  v_collected_cash_minor bigint := 0;
  v_collected_bank_minor bigint := 0;
  v_return_slips jsonb := '[]'::jsonb;
  v_collected_offset_minor bigint := 0;
  v_refunded_offset_minor bigint := 0;
begin
  if auth.uid() is distinct from p_actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(p_tenant_id, 'sales.payment.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where id = p_sales_order_id and tenant_id = p_tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.'
    )::text;
  end if;
  if p_expected_source_version is not null and v_order.version <> p_expected_source_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION', 'message', 'Sales order version is stale.'
    )::text;
  end if;
  if not iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_id = p_sales_order_id and tenant_id = p_tenant_id
  order by id desc
  limit 1;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PROJECTION_PENDING',
      'message', 'Settlement projection not ready.',
      'details', jsonb_build_object('salesOrderId', p_sales_order_id)
    )::text;
  end if;

  select
    coalesce(sum(case when payment_method_code = 'cash' then amount_minor else 0 end), 0),
    coalesce(sum(case when payment_method_code in ('manualBankTransfer', 'bankTransfer') then amount_minor else 0 end), 0)
  into v_checkout_cash_minor, v_checkout_bank_minor
  from receivable.sales_payment_transactions
  where sales_order_settlement_id = v_settlement.id
    and tenant_id = p_tenant_id
    and status = 'confirmed'
    and transaction_type = 'collection'
    and direction = 'inflow'
    and source_context = 'checkout';

  select
    coalesce(sum(case when payment_method_code = 'cash' then amount_minor else 0 end), 0),
    coalesce(sum(case when payment_method_code in ('manualBankTransfer', 'bankTransfer') then amount_minor else 0 end), 0)
  into v_collected_cash_minor, v_collected_bank_minor
  from receivable.sales_payment_transactions
  where sales_order_settlement_id = v_settlement.id
    and tenant_id = p_tenant_id
    and status = 'confirmed'
    and transaction_type = 'collection'
    and direction = 'inflow';

  select
    coalesce(sum(amount_minor) filter (where transaction_type = 'collection'), 0),
    coalesce(sum(amount_minor) filter (where transaction_type = 'refund'), 0)
  into v_collected_offset_minor, v_refunded_offset_minor
  from receivable.sales_payment_transactions
  where sales_order_settlement_id = v_settlement.id
    and tenant_id = p_tenant_id
    and status = 'confirmed'
    and payment_method_code = 'offset';

  select coalesce(
    jsonb_agg(slip.payload order by slip.sort_at, slip.slip_id),
    '[]'::jsonb
  )
  into v_return_slips
  from (
    select
      rx.created_at as sort_at,
      rx.id as slip_id,
      jsonb_build_object(
        'slipNumber', coalesce(nullif(btrim(rx.reference_number), ''), rx.id::text),
        'customerPaysExtra', jsonb_build_object(
          'amountMinor', greatest(coalesce(val.net_difference_minor, 0), 0),
          'currencyCode', v_settlement.currency_code
        ),
        'paidCashExtra', jsonb_build_object(
          'amountMinor', coalesce(pay.cash_minor, 0),
          'currencyCode', v_settlement.currency_code
        ),
        'paidBankExtra', jsonb_build_object(
          'amountMinor', coalesce(pay.bank_minor, 0),
          'currencyCode', v_settlement.currency_code
        )
      ) as payload
    from sales.return_exchange_orders rx
    left join sales.return_exchange_valuations val
      on val.tenant_id = rx.tenant_id
     and val.return_exchange_order_id = rx.id
     and val.status = 'confirmed'
    left join lateral (
      select
        coalesce(sum(case when t.payment_method_code = 'cash' then t.amount_minor else 0 end), 0) as cash_minor,
        coalesce(sum(case when t.payment_method_code in ('manualBankTransfer', 'bankTransfer') then t.amount_minor else 0 end), 0) as bank_minor
      from receivable.sales_payment_transactions t
      where t.tenant_id = rx.tenant_id
        and t.sales_order_settlement_id = v_settlement.id
        and t.status = 'confirmed'
        and t.transaction_type = 'collection'
        and t.direction = 'inflow'
        and t.source_context = 'return_exchange'
        and t.source_id = rx.id
    ) pay on true
    where rx.tenant_id = p_tenant_id
      and rx.sales_order_id = p_sales_order_id
      and rx.status in ('confirmed', 'processing', 'completed')
  ) slip;

  -- Date-only. Do not invent a due date when checkout did not persist one.
  v_due_at := case
    when v_settlement.payment_due_date is null then null
    else to_char(v_settlement.payment_due_date, 'YYYY-MM-DD')
  end;

  return jsonb_build_object(
    'status', case v_settlement.payment_status
      when 'partially_paid' then 'partiallyPaid'
      when 'partially_refunded' then 'partiallyRefunded'
      when 'no_balance' then 'no_balance'
      else v_settlement.payment_status
    end,
    'orderTotal', jsonb_build_object('amountMinor', v_settlement.current_payable_amount_minor, 'currencyCode', v_settlement.currency_code),
    'paidTotal', jsonb_build_object('amountMinor', v_settlement.collected_amount_minor, 'currencyCode', v_settlement.currency_code),
    'refundedTotal', jsonb_build_object('amountMinor', v_settlement.refunded_amount_minor, 'currencyCode', v_settlement.currency_code),
    'netCollectedTotal', jsonb_build_object('amountMinor', v_settlement.net_collected_amount_minor, 'currencyCode', v_settlement.currency_code),
    'originalPayableTotal', jsonb_build_object('amountMinor', v_settlement.original_payable_amount_minor, 'currencyCode', v_settlement.currency_code),
    'adjustmentTotal', jsonb_build_object('amountMinor', v_settlement.post_sale_adjustment_amount_minor, 'currencyCode', v_settlement.currency_code),
    'collectedCash', jsonb_build_object('amountMinor', v_collected_cash_minor, 'currencyCode', v_settlement.currency_code),
    'collectedBank', jsonb_build_object('amountMinor', v_collected_bank_minor, 'currencyCode', v_settlement.currency_code),
    'collectedOffset', jsonb_build_object('amountMinor', v_collected_offset_minor, 'currencyCode', v_settlement.currency_code),
    'refundedOffset', jsonb_build_object('amountMinor', v_refunded_offset_minor, 'currencyCode', v_settlement.currency_code),
    'outstandingTotal', jsonb_build_object('amountMinor', v_settlement.outstanding_amount_minor, 'currencyCode', v_settlement.currency_code),
    'dueAt', v_due_at,
    'originalOrder', jsonb_build_object(
      'orderTotal', jsonb_build_object('amountMinor', v_settlement.original_payable_amount_minor, 'currencyCode', v_settlement.currency_code),
      'paidCash', jsonb_build_object('amountMinor', v_checkout_cash_minor, 'currencyCode', v_settlement.currency_code),
      'paidBank', jsonb_build_object('amountMinor', v_checkout_bank_minor, 'currencyCode', v_settlement.currency_code),
      'outstanding', jsonb_build_object('amountMinor', greatest(v_settlement.original_payable_amount_minor - v_checkout_cash_minor - v_checkout_bank_minor, 0), 'currencyCode', v_settlement.currency_code)
    ),
    'returnSlips', v_return_slips
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.get_sales_order_payment_transactions(query_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, expected_source_version integer DEFAULT NULL::integer, cursor text DEFAULT NULL::text, page_size integer DEFAULT 25)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_cursor_at timestamptz;
  v_cursor_id uuid;
  v_limit integer;
begin
  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(tenant_id, 'sales.payment.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders o
  where o.id = get_sales_order_payment_transactions.sales_order_id
    and o.tenant_id = get_sales_order_payment_transactions.tenant_id;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.',
      'details', jsonb_build_object('salesOrderId', sales_order_id)
    )::text;
  end if;

  if expected_source_version is not null
     and v_order.version is distinct from expected_source_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION', 'message', 'Sales order version is stale.'
    )::text;
  end if;

  if not iam.can_access_store(get_sales_order_payment_transactions.tenant_id, v_order.store_id, get_sales_order_payment_transactions.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  if cursor is not null and position('|' in cursor) > 0 then
    v_cursor_at := split_part(cursor, '|', 1)::timestamptz;
    v_cursor_id := split_part(cursor, '|', 2)::uuid;
  end if;

  v_limit := least(greatest(page_size, 1), 100);

  return (
    with ranked as (
      select
        t.id,
        t.payment_method_code,
        t.amount_minor,
        t.currency_code,
        t.status,
        t.occurred_at,
        t.transaction_type,
        t.direction,
        t.related_transaction_id,
        t.source_context,
        t.initiated_by_user_id,
        t.reason_code,
        t.reason,
        co.id as counterpart_order_id,
        co.order_code::text as counterpart_order_code,
        case when t.source_type = 'customer_collection' then t.source_id end as customer_collection_id
      from receivable.sales_payment_transactions t
      join receivable.sales_order_settlements s
        on s.id = t.sales_order_settlement_id
       and s.tenant_id = t.tenant_id
      left join receivable.receivable_offsets ro
        on ro.tenant_id = t.tenant_id
       and t.source_type = 'receivable_offset'
       and ro.id = t.source_id
      left join sales.sales_orders co
        on co.tenant_id = ro.tenant_id
       and co.id = case when t.transaction_type = 'refund'
                        then ro.target_sales_order_id
                        else ro.source_sales_order_id end
      where s.sales_order_id = get_sales_order_payment_transactions.sales_order_id
        and s.tenant_id = get_sales_order_payment_transactions.tenant_id
        and t.tenant_id = get_sales_order_payment_transactions.tenant_id
        and (
          v_cursor_at is null
          or (t.occurred_at, t.id) < (v_cursor_at, v_cursor_id)
        )
      order by t.occurred_at desc, t.id desc
      limit v_limit + 1
    ),
    page as (
      select * from ranked limit v_limit
    )
    select jsonb_build_object(
      'items', coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'transactionId', p.id,
              'method', p.payment_method_code,
              'amount', jsonb_build_object(
                'amountMinor', p.amount_minor,
                'currencyCode', p.currency_code
              ),
              'status', p.status,
              'recordedAt', to_char(
                p.occurred_at at time zone 'utc',
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
              ),
              'transactionType', p.transaction_type,
              'direction', p.direction,
              'relatedTransactionId', p.related_transaction_id,
              'sourceContext', p.source_context,
              'actorId', p.initiated_by_user_id,
              'reasonCode', p.reason_code,
              'reason', p.reason,
              'counterpartSalesOrderId', p.counterpart_order_id,
              'counterpartOrderCode', p.counterpart_order_code,
              'customerCollectionId', p.customer_collection_id
            )
            order by p.occurred_at desc, p.id desc
          )
          from page p
        ),
        '[]'::jsonb
      ),
      'hasMore', (select count(*) > v_limit from ranked),
      'nextCursor', (
        select case
          when (select count(*) from ranked) > v_limit then
            concat(
              to_char(
                (select occurred_at from page order by occurred_at asc, id asc limit 1)
                  at time zone 'utc',
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
              ),
              '|',
              (select id::text from page order by occurred_at asc, id asc limit 1)
            )
          else null
        end
      )
    )
  );
end;
$function$
;

