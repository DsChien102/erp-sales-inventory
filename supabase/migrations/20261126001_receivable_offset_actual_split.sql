-- Title: receivable offset actual split
-- Kind: patch
-- Intent: receivable_offset_actual_split
-- Context: TH-06 6.2 (T6-2c Task 1)
-- Touches: confirm_return_exchange, get_sales_order_timeline
-- Safety: idempotent ; medium
-- Depends on: 20261125001_receivable_history_actor_name

-- 1) confirm_return_exchange: sau khi ghi, cap nhat ke hoach theo cach chia that
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

  update receivable.return_exchange_settlement_plans p
  set status = 'confirmed',
      offset_amount_minor = x.actual,
      refund_amount_minor = p.offset_amount_minor + p.refund_amount_minor - x.actual,
      offset_candidates = coalesce((
        select jsonb_agg(c || jsonb_build_object('offsetAmountMinor', coalesce((
                 select sum(ro.amount_minor) from receivable.receivable_offsets ro
                 where ro.tenant_id = p.tenant_id and ro.return_exchange_order_id = v_session.id
                   and ro.target_sales_order_id = (c ->> 'salesOrderId')::uuid), 0))
               order by ord)
        from jsonb_array_elements(p.offset_candidates) with ordinality e(c, ord)), '[]'::jsonb)
  from (select coalesce(sum(ro.amount_minor), 0)::bigint as actual
        from receivable.receivable_offsets ro
        where ro.tenant_id = confirm_return_exchange.tenant_id
          and ro.return_exchange_order_id = v_session.id) x
  where p.id = v_pl.id;

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

-- 2) get_sales_order_timeline: nhan thu theo khach
CREATE OR REPLACE FUNCTION sales.get_sales_order_timeline(query_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
begin
  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(tenant_id, 'sales.order.history.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders o
  where o.id = get_sales_order_timeline.sales_order_id
    and o.tenant_id = get_sales_order_timeline.tenant_id;

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

  if not iam.can_access_store(get_sales_order_timeline.tenant_id, v_order.store_id, get_sales_order_timeline.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  return jsonb_build_object(
    'salesOrderId', v_order.id,
    'entries', (
      select coalesce(
        jsonb_agg(entry order by (entry ->> 'occurredAt') asc, (entry ->> 'eventId') asc),
        '[]'::jsonb
      )
      from (
        select jsonb_build_object(
          'eventId', o.id,
          'eventType', o.event_type,
          'occurredAt', to_char(o.occurred_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
          'sourceVersion', coalesce((o.payload ->> 'salesOrderVersion')::integer, v_order.version),
          'actor', case
            when src.actor_id is null then null
            else jsonb_build_object(
              'actorId', src.actor_id,
              'displayName', coalesce(nullif(src.actor_name, ''), 'Không rõ')
            )
          end,
          'description', coalesce(o.payload ->> 'description',
            case when o.event_type = 'sales_payment_recorded.v1' and o.payload ? 'customerCollectionId'
                 then 'Ghi nhận thu nợ theo khách' end),
          'amount', case
            when o.payload ? 'grandTotalMinor' then jsonb_build_object(
              'amountMinor', (o.payload ->> 'grandTotalMinor')::bigint,
              'currencyCode', coalesce(o.payload ->> 'currencyCode', v_order.currency_code)
            )
            when o.payload ? 'amountMinor' then jsonb_build_object(
              'amountMinor', (o.payload ->> 'amountMinor')::bigint,
              'currencyCode', coalesce(o.payload ->> 'currencyCode', v_order.currency_code)
            )
            else null
          end
        ) as entry
        from sales.outbox_messages o
        left join lateral (
          select
            resolved.actor_id,
            resolved.actor_name
          from (
            select
              coalesce(
                nullif(o.payload ->> 'actorId', ''),
                case
                  when o.event_type in (
                    'sales_order_finalized.v1',
                    'sales_order_confirmed',
                    'sales_order_cancelled.v1'
                  ) then coalesce(
                    nullif(v_order.sales_context_snapshot -> 'seller' ->> 'actorId', ''),
                    v_order.seller_user_id::text
                  )
                  else null
                end,
                (
                  select t.initiated_by_user_id::text
                  from receivable.sales_payment_transactions t
                  where t.tenant_id = get_sales_order_timeline.tenant_id
                    and t.id::text = coalesce(
                      o.payload ->> 'transactionId',
                      o.payload ->> 'paymentTransactionId'
                    )
                  limit 1
                ),
                (
                  select c.requested_by_user_id::text
                  from sales.sales_order_cancellations c
                  where c.tenant_id = get_sales_order_timeline.tenant_id
                    and c.sales_order_id = v_order.id
                    and (
                      o.payload ->> 'cancellationId' is null
                      or c.id::text = o.payload ->> 'cancellationId'
                    )
                    and o.event_type like '%cancel%'
                  order by c.created_at desc
                  limit 1
                ),
                (
                  select coalesce(
                    r.completed_by_user_id,
                    r.confirmed_by_user_id,
                    r.created_by_user_id
                  )::text
                  from sales.return_exchange_orders r
                  where r.tenant_id = get_sales_order_timeline.tenant_id
                    and r.sales_order_id = v_order.id
                    and (
                      o.payload ->> 'returnExchangeId' is null
                      or r.id::text = o.payload ->> 'returnExchangeId'
                    )
                    and o.event_type like '%return%'
                  order by r.created_at desc
                  limit 1
                )
              ) as actor_id,
              coalesce(
                nullif(o.payload ->> 'actorDisplayName', ''),
                case
                  when coalesce(nullif(o.payload ->> 'actorId', ''), v_order.seller_user_id::text)
                    = nullif(v_order.sales_context_snapshot -> 'seller' ->> 'actorId', '')
                    then nullif(v_order.sales_context_snapshot -> 'seller' ->> 'displayName', '')
                  else null
                end
              ) as actor_name
          ) resolved
        ) src on true
        where o.tenant_id = get_sales_order_timeline.tenant_id
          and (o.payload ->> 'salesOrderId') = get_sales_order_timeline.sales_order_id::text
      ) timeline_entries
    )
  );
end;
$function$
;

revoke all on function sales.confirm_return_exchange(
  text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date, uuid[]
) from public, anon;
grant execute on function sales.confirm_return_exchange(
  text, uuid, uuid, uuid, text, text, text, text, integer, jsonb, bigint, text, date, uuid[]
) to authenticated;
