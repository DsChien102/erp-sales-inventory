-- Title: receivable move money tables
-- Kind: surgical
-- Intent: receivable_move_money_tables
-- Context: TH-06 3.6 / Q12 / Q13 R1
-- Touches: _apply_settlement_obligation_adjustment, _emit_sales_settlement_changed, _get_return_exchange_context, _recompute_sales_settlement, _settlement_id_for_order, _settlement_mutation_snapshot, audit_sales_review_invariants, confirm_return_exchange, confirm_sales_order_cancellation, evaluate_return_exchange_valuation, finalize_sales_order, generate_sales_receipt, get_sales_order_detail, get_sales_order_original_receipt, get_sales_order_payment_summary, get_sales_order_payment_transactions, get_sales_order_settlement, get_sales_order_timeline, list_sales_orders, precheck_sales_order_cancellation, record_sales_payment, record_sales_refund, search_sales_orders, settle_return_exchange_difference, start_return_exchange
-- Safety: destructive (drop column sales.sales_orders.payment_due_date) sau khi chep du lieu va kiem dem; khong cascade
-- Depends on: 20261122003_inventory_gross_profit_all_members

-- 1) Schema
create schema if not exists receivable;
grant usage on schema receivable to authenticated, service_role;

-- 2) Chuyen ba bang tien (du lieu, khoa, CHECK, index, RLS, quyen di theo bang)
alter table sales.sales_order_settlements set schema receivable;
alter table sales.sales_payment_transactions set schema receivable;
alter table sales.settlement_obligation_adjustments set schema receivable;

-- 3) Ngay hen tra vao quyet toan
alter table receivable.sales_order_settlements add column payment_due_date date;
update receivable.sales_order_settlements s
set payment_due_date = o.payment_due_date
from sales.sales_orders o
where o.id = s.sales_order_id
  and o.tenant_id = s.tenant_id
  and o.payment_due_date is not null;

-- 4) Kiem chep
do $$
declare
  v_orders bigint;
  v_settlements bigint;
  v_mismatch bigint;
begin
  select count(*) into v_orders from sales.sales_orders where payment_due_date is not null;
  select count(*) into v_settlements from receivable.sales_order_settlements where payment_due_date is not null;
  select count(*) into v_mismatch
  from sales.sales_orders o
  join receivable.sales_order_settlements s on s.sales_order_id = o.id and s.tenant_id = o.tenant_id
  where o.payment_due_date is distinct from s.payment_due_date;
  if v_orders <> v_settlements or v_mismatch <> 0 then
    raise exception 'T6-1a: chep payment_due_date lech (don co han=%, quyet toan co han=%, lech=%)',
      v_orders, v_settlements, v_mismatch;
  end if;
end;
$$;

-- 5) Tao lai cac ham (than sinh tu DB bang pg_get_functiondef, doi ten schema; R1 sua tay)
CREATE OR REPLACE FUNCTION sales._apply_settlement_obligation_adjustment(p_tenant_id uuid, p_settlement_id uuid, p_source_kind text, p_source_id uuid, p_amount_minor bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_existing receivable.settlement_obligation_adjustments%rowtype;
begin
  perform 1
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and id = p_settlement_id
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'REFERENCE_UNAVAILABLE',
      'message', 'Settlement was not found for obligation adjustment.'
    )::text;
  end if;

  select * into v_existing
  from receivable.settlement_obligation_adjustments
  where tenant_id = p_tenant_id
    and source_kind = p_source_kind
    and source_id = p_source_id
  for update;

  if found then
    if v_existing.sales_order_settlement_id is distinct from p_settlement_id
       or v_existing.amount_minor is distinct from p_amount_minor then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Conflicting obligation adjustment for the same source.'
      )::text;
    end if;
    return;
  end if;

  insert into receivable.settlement_obligation_adjustments (
    id, tenant_id, sales_order_settlement_id, source_kind, source_id, amount_minor
  ) values (
    gen_random_uuid(), p_tenant_id, p_settlement_id, p_source_kind, p_source_id, p_amount_minor
  );

  update receivable.sales_order_settlements
  set post_sale_adjustment_amount_minor = post_sale_adjustment_amount_minor + p_amount_minor,
      current_payable_amount_minor = original_payable_amount_minor
        + post_sale_adjustment_amount_minor + p_amount_minor,
      updated_at = now()
  where tenant_id = p_tenant_id and id = p_settlement_id;

  perform sales._recompute_sales_settlement(p_tenant_id, p_settlement_id);
end $function$
;

CREATE OR REPLACE FUNCTION sales._emit_sales_settlement_changed(p_tenant_id uuid, p_settlement_id uuid, p_source_kind text, p_source_id text, p_source_command text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_settlement receivable.sales_order_settlements%rowtype;
  v_event_id uuid;
  v_payload jsonb;
  v_digest text;
begin
  if p_settlement_id is null
    or nullif(btrim(coalesce(p_source_kind, '')), '') is null
    or nullif(btrim(coalesce(p_source_id, '')), '') is null
    or nullif(btrim(coalesce(p_source_command, '')), '') is null then
    return;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where id = p_settlement_id
    and tenant_id = p_tenant_id;
  if not found then
    return;
  end if;

  v_digest := md5(
    p_tenant_id::text
    || ':sales_settlement_changed.v1:'
    || btrim(p_source_kind)
    || ':'
    || btrim(p_source_id)
    || ':'
    || v_settlement.version::text
  );
  v_event_id := (
    substr(v_digest, 1, 8) || '-' ||
    substr(v_digest, 9, 4) || '-' ||
    substr(v_digest, 13, 4) || '-' ||
    substr(v_digest, 17, 4) || '-' ||
    substr(v_digest, 21, 12)
  )::uuid;

  if exists (
    select 1
    from sales.outbox_messages
    where id = v_event_id
       or (
         tenant_id = p_tenant_id
         and event_type = 'sales_settlement_changed.v1'
         and payload->>'sourceKind' = btrim(p_source_kind)
         and payload->>'sourceId' = btrim(p_source_id)
         and payload->>'settlementVersion' = v_settlement.version::text
       )
  ) then
    return;
  end if;

  v_payload := jsonb_build_object(
    'id', v_event_id::text,
    'eventVersion', 1,
    'occurredOn', to_char(now() at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'tenantId', p_tenant_id::text,
    'salesOrderId', v_settlement.sales_order_id::text,
    'settlementId', v_settlement.id::text,
    'sourceKind', btrim(p_source_kind),
    'sourceId', btrim(p_source_id),
    'sourceCommand', btrim(p_source_command),
    'settlementVersion', v_settlement.version,
    'currencyCode', v_settlement.currency_code,
    'originalPayableMinor', v_settlement.original_payable_amount_minor,
    'adjustmentMinor', v_settlement.post_sale_adjustment_amount_minor,
    'currentPayableMinor', v_settlement.current_payable_amount_minor,
    'collectedMinor', v_settlement.collected_amount_minor,
    'refundedMinor', v_settlement.refunded_amount_minor,
    'netCollectedMinor', v_settlement.net_collected_amount_minor,
    'outstandingMinor', v_settlement.outstanding_amount_minor,
    'paymentStatus', v_settlement.payment_status
  );

  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (v_event_id, p_tenant_id, 'sales_settlement_changed.v1', v_payload);
end;
$function$
;

CREATE OR REPLACE FUNCTION sales._get_return_exchange_context(tenant_id uuid, actor_id uuid, return_exchange_id uuid)
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
  v_lines jsonb;
begin
  if auth.uid() is distinct from actor_id
    or (
      iam.has_permission(tenant_id, 'sales.return_exchange.view') is not true
      and iam.has_permission(tenant_id, 'sales.return_exchange.update') is not true
      and iam.has_permission(tenant_id, 'sales.return_exchange.cancel') is not true
    ) then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_session
  from sales.return_exchange_orders
  where return_exchange_orders.id = _get_return_exchange_context.return_exchange_id
    and return_exchange_orders.tenant_id = _get_return_exchange_context.tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Return/exchange session not found.',
      'details', jsonb_build_object('returnExchangeId', return_exchange_id)
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = v_session.sales_order_id
    and sales_orders.tenant_id = _get_return_exchange_context.tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.'
    )::text;
  end if;

  if not iam.can_access_store(_get_return_exchange_context.tenant_id, v_order.store_id, _get_return_exchange_context.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = _get_return_exchange_context.tenant_id
  order by sales_order_settlements.version desc nulls last, sales_order_settlements.id desc
  limit 1;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'kind', case rl.line_role when 'returned' then 'returnLine' else 'exchangeLine' end,
      'productId', rl.product_id,
      'productUnitId', rl.product_unit_id,
      'quantity', jsonb_build_object('quantityMicros', rl.quantity_micros),
      'originalSalesOrderLineId', rl.original_sales_order_line_id,
      'sourceExchangeLineId', rl.source_exchange_line_id,
      'lineSnapshot', jsonb_build_object(
        'product', rl.product_snapshot,
        'unit', rl.product_unit_snapshot,
        'unitPrice', jsonb_build_object(
          'amountMinor', rl.unit_value_minor,
          'currencyCode', coalesce(v_session.currency_code, v_order.currency_code)
        )
      )
    )
    order by rl.line_sequence, rl.id
  ), '[]'::jsonb)
  into v_lines
  from sales.return_exchange_lines rl
  where rl.return_exchange_order_id = v_session.id
    and rl.tenant_id = _get_return_exchange_context.tenant_id;

  return jsonb_build_object(
    'draft', jsonb_build_object(
      'returnExchangeId', v_session.id,
      'salesOrderId', v_session.sales_order_id,
      'version', v_session.version,
      'status', v_session.status,
      'lines', v_lines
    ),
    'currencyCode', coalesce(v_session.currency_code, v_order.currency_code),
    'sourceOrderVersion', coalesce(v_session.source_order_version, v_order.version),
    'sourceSettlementVersion', coalesce(
      v_session.source_settlement_version,
      v_settlement.version,
      1
    ),
    'reservationIds', '[]'::jsonb
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales._recompute_sales_settlement(p_tenant_id uuid, p_settlement_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_collected bigint;
  v_refunded bigint;
  v_net bigint;
begin
  perform 1
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and id = p_settlement_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'REFERENCE_UNAVAILABLE',
      'message', 'Settlement was not found.'
    )::text;
  end if;

  select
    coalesce(sum(amount_minor) filter (where direction = 'inflow' and status = 'confirmed'), 0),
    coalesce(sum(amount_minor) filter (where direction = 'outflow' and status = 'confirmed'), 0)
  into v_collected, v_refunded
  from receivable.sales_payment_transactions
  where tenant_id = p_tenant_id
    and sales_order_settlement_id = p_settlement_id;

  v_net := v_collected - v_refunded;

  update receivable.sales_order_settlements
  set collected_amount_minor = v_collected,
      refunded_amount_minor = v_refunded,
      net_collected_amount_minor = v_net,
      outstanding_amount_minor = greatest(current_payable_amount_minor - v_net, 0),
      payment_status = case
        when current_payable_amount_minor <= 0 and v_collected = 0 and v_refunded = 0
          then 'no_balance'
        when v_net <= 0 and v_refunded > 0 then 'refunded'
        when v_net <= 0 then 'unpaid'
        when v_refunded > 0
             and greatest(current_payable_amount_minor - v_net, 0) > 0
          then 'partially_refunded'
        when greatest(current_payable_amount_minor - v_net, 0) = 0
             and v_net >= current_payable_amount_minor
          then 'paid'
        else 'partially_paid'
      end,
      settled_at = case
        when greatest(current_payable_amount_minor - v_net, 0) = 0
             and v_net > 0
        then coalesce(settled_at, now())
        else null
      end,
      version = version + 1,
      updated_at = now()
  where tenant_id = p_tenant_id and id = p_settlement_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales._settlement_id_for_order(p_tenant_id uuid, p_sales_order_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_id uuid;
begin
  select id into v_id
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and sales_order_id = p_sales_order_id;
  if v_id is null then
    raise exception using message = jsonb_build_object(
      'code', 'REFERENCE_UNAVAILABLE',
      'message', 'Settlement was not found.'
    )::text;
  end if;
  return v_id;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales._settlement_mutation_snapshot(p_tenant_id uuid, p_settlement_id uuid, p_transaction_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_s receivable.sales_order_settlements%rowtype;
begin
  select * into v_s
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and id = p_settlement_id;

  return jsonb_build_object(
    'settlementId', v_s.id::text,
    'salesOrderId', v_s.sales_order_id::text,
    'transactionId', p_transaction_id::text,
    'currencyCode', v_s.currency_code,
    'currentPayableMinor', v_s.current_payable_amount_minor,
    'collectedMinor', v_s.collected_amount_minor,
    'refundedMinor', v_s.refunded_amount_minor,
    'netCollectedMinor', v_s.net_collected_amount_minor,
    'outstandingMinor', v_s.outstanding_amount_minor,
    'paymentStatus', v_s.payment_status,
    'version', v_s.version
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.audit_sales_review_invariants()
 RETURNS TABLE(rule_code text, tenant_id uuid, sales_order_id uuid, source_id uuid, recoverability text, current_value text, proposed_value text, basis text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'sales', 'public', 'pg_temp'
AS $function$
  select
    'payment_related_cross_settlement',
    payment.tenant_id,
    settlement.sales_order_id,
    payment.id,
    'not_applicable',
    payment.related_transaction_id::text,
    null,
    'related transaction must share tenant and settlement; do not rewrite'
  from receivable.sales_payment_transactions payment
  join receivable.sales_order_settlements settlement
    on settlement.id = payment.sales_order_settlement_id
   and settlement.tenant_id = payment.tenant_id
  join receivable.sales_payment_transactions related
    on related.id = payment.related_transaction_id
  where payment.related_transaction_id is not null
    and (
      related.tenant_id is distinct from payment.tenant_id
      or related.sales_order_settlement_id is distinct from payment.sales_order_settlement_id
    )

  union all
  select
    'return_source_xor',
    line.tenant_id,
    line.source_sales_order_id,
    line.id,
    'not_applicable',
    concat_ws(
      ',',
      line.original_sales_order_line_id::text,
      line.source_exchange_line_id::text
    ),
    null,
    'returned line needs exactly one source; do not invent a source'
  from sales.return_exchange_lines line
  where line.line_role = 'returned'
    and (
      (line.original_sales_order_line_id is not null)::integer
      + (line.source_exchange_line_id is not null)::integer
    ) is distinct from 1

  union all
  select
    'order_line_base_qty_nonpositive',
    line.tenant_id,
    line.sales_order_id,
    line.id,
    case
      when (line.product_unit_snapshot ->> 'conversionRateToBase') ~ '^[0-9]+(\.[0-9]+)?$'
        and (line.product_unit_snapshot ->> 'conversionRateToBase')::numeric > 0
        then 'recomputable_from_line_snapshot'
      else 'unrecoverable'
    end,
    line.base_quantity_micros::text,
    case
      when (line.product_unit_snapshot ->> 'conversionRateToBase') ~ '^[0-9]+(\.[0-9]+)?$'
        and (line.product_unit_snapshot ->> 'conversionRateToBase')::numeric > 0
        then round(line.quantity_micros * (line.product_unit_snapshot ->> 'conversionRateToBase')::numeric)::text
      else null
    end,
    case
      when (line.product_unit_snapshot ->> 'conversionRateToBase') ~ '^[0-9]+(\.[0-9]+)?$'
        and (line.product_unit_snapshot ->> 'conversionRateToBase')::numeric > 0
        then 'product_unit_snapshot.conversionRateToBase on the line; never current Catalog'
      else 'no trusted conversion on the line snapshot'
    end
  from sales.sales_order_lines line
  where line.base_quantity_micros <= 0

  union all
  select
    'order_line_commercial_mismatch',
    line.tenant_id,
    line.sales_order_id,
    line.id,
    'unrecoverable',
    line.line_total_minor::text,
    (line.gross_amount_minor - line.discount_amount_minor + line.tax_amount_minor)::text,
    'formula only; do not replace a stored total without a separate repair scope'
  from sales.sales_order_lines line
  where line.line_total_minor is distinct from
    line.gross_amount_minor - line.discount_amount_minor + line.tax_amount_minor

  union all
  select
    'order_commercial_mismatch',
    sales_order.tenant_id,
    sales_order.id,
    sales_order.id,
    'unrecoverable',
    sales_order.payable_amount_minor::text,
    (
      sales_order.subtotal_amount_minor
      - sales_order.discount_amount_minor
      + sales_order.tax_amount_minor
      + sales_order.rounding_amount_minor
    )::text,
    'A3 header formula; do not backfill tax or rounding from another source'
  from sales.sales_orders sales_order
  where sales_order.payable_amount_minor is distinct from
    sales_order.subtotal_amount_minor
    - sales_order.discount_amount_minor
    + sales_order.tax_amount_minor
    + sales_order.rounding_amount_minor

  union all
  select
    'settlement_adjustment_sum_mismatch',
    settlement.tenant_id,
    settlement.sales_order_id,
    settlement.id,
    'recomputable_from_adjustment_ledger',
    settlement.post_sale_adjustment_amount_minor::text,
    coalesce(ledger.total_minor, 0)::text,
    'post_sale_adjustment_amount_minor must equal sum of settlement_obligation_adjustments'
  from receivable.sales_order_settlements settlement
  left join lateral (
    select sum(adjustment.amount_minor) as total_minor
    from receivable.settlement_obligation_adjustments adjustment
    where adjustment.tenant_id = settlement.tenant_id
      and adjustment.sales_order_settlement_id = settlement.id
  ) ledger on true
  where settlement.post_sale_adjustment_amount_minor
    is distinct from coalesce(ledger.total_minor, 0)

  union all
  select
    'return_projection_status_mismatch',
    projection.tenant_id,
    projection.sales_order_id,
    projection.sales_order_id,
    'recomputable_from_line_snapshot',
    projection.return_status,
    recomputed.return_status,
    'per original line: completed returned quantity vs sold quantity; not Catalog'
  from sales.sales_order_return_status_projections projection
  join lateral (
    select case
      when count(*) = 0 then 'none'
      when bool_or(per_line.returned_qty > 0)
        and bool_and(per_line.returned_qty >= per_line.sold_qty) then 'fully_returned'
      when bool_or(per_line.returned_qty > 0) then 'partially_returned'
      else 'none'
    end as return_status
    from (
      select
        order_line.quantity_micros as sold_qty,
        coalesce((
          select sum(return_line.quantity_micros)
          from sales.return_exchange_lines return_line
          join sales.return_exchange_orders return_order
            on return_order.id = return_line.return_exchange_order_id
           and return_order.tenant_id = return_line.tenant_id
          where return_order.tenant_id = projection.tenant_id
            and return_order.sales_order_id = projection.sales_order_id
            and return_order.status = 'completed'
            and return_line.line_role = 'returned'
            and return_line.original_sales_order_line_id = order_line.id
        ), 0) as returned_qty
      from sales.sales_order_lines order_line
      where order_line.tenant_id = projection.tenant_id
        and order_line.sales_order_id = projection.sales_order_id
    ) per_line
  ) recomputed on true
  where projection.return_status is distinct from recomputed.return_status;
$function$
;

CREATE OR REPLACE FUNCTION sales.confirm_return_exchange(command_id text, tenant_id uuid, actor_id uuid, return_exchange_id uuid, idempotency_key text, payload_hash text, correlation_id text, causation_id text DEFAULT NULL::text, expected_version integer DEFAULT NULL::integer, reference_decision jsonb DEFAULT '{}'::jsonb, payment_settled_now_minor bigint DEFAULT NULL::bigint, payment_method text DEFAULT 'cash'::text, payment_due_date date DEFAULT NULL::date)
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
  v_plan jsonb;
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

  v_plan := coalesce(v_valuation.valuation_details -> 'settlement_plan', '{}'::jsonb);
  if v_plan = '{}'::jsonb then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Stored settlement plan is required before confirmation.'
    )::text;
  end if;

  v_source_order_version := coalesce((v_plan ->> 'source_order_version')::bigint, 0);
  v_source_settlement_version := coalesce((v_plan ->> 'source_settlement_version')::bigint, 0);
  v_plan_pricing_version := nullif(v_plan ->> 'pricing_source_version', '')::integer;
  v_remainder_collect := coalesce((v_plan ->> 'remainder_collect_minor')::bigint, 0);
  v_remainder_refund := coalesce((v_plan ->> 'remainder_refund_minor')::bigint, 0);
  v_plan_currency := coalesce(v_plan ->> 'currency_code', v_valuation.currency_code);
  v_plan_corr := coalesce(nullif(v_plan ->> 'correlation_id', ''), v_session.correlation_id, v_session.id::text);
  v_recv_create := coalesce((v_plan ->> 'receivable_create_amount_minor')::bigint, 0);
  v_recv_reverse := coalesce((v_plan ->> 'receivable_reverse_amount_minor')::bigint, 0);

  if v_source_order_version is distinct from v_order.version
    or v_source_settlement_version is distinct from v_settlement.version
    or (
      -- B3b: valuation phai thuoc noi dung phien hien tai (source_session_version).
      -- Guard is-not-null de tuong thich valuation cu tao truoc B3a.
      nullif(v_plan ->> 'source_session_version', '') is not null
      and (v_plan ->> 'source_session_version')::bigint is distinct from v_session.version
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

  -- Auto-settle remainders in the same transaction via settle helper.
  -- Set confirmation_context GUC so settle skips payment/refund permission.
  -- Default method='cash' when client omits payment_method.
  perform set_config('sales.return_exchange_confirmation_context', '1', true);

  if v_remainder_collect > 0 and v_settled_now > 0 then
    perform sales.settle_return_exchange_difference(
      command_id => (confirm_return_exchange.command_id || ':collect')::text,
      tenant_id => confirm_return_exchange.tenant_id,
      actor_id => confirm_return_exchange.actor_id,
      operation => 'collection'::text,
      sales_order_id => v_session.sales_order_id,
      return_exchange_id => v_session.id,
      amount_minor => v_settled_now,
      currency_code => v_plan_currency,
      method => coalesce(nullif(btrim(payment_method), ''), 'cash')::text,
      reference => ('confirm:' || v_plan_corr)::text,
      idempotency_key => (confirm_return_exchange.idempotency_key || ':confirm-collect')::text,
      payload_hash => confirm_return_exchange.payload_hash::text,
      correlation_id => v_plan_corr::text,
      causation_id => confirm_return_exchange.causation_id::text,
      expected_source_version => v_settlement.version
    );
  end if;

  if v_remainder_refund > 0 then
    select * into v_settlement
    from receivable.sales_order_settlements
    where sales_order_settlements.sales_order_id = v_order.id
      and sales_order_settlements.tenant_id = confirm_return_exchange.tenant_id;

    perform sales.settle_return_exchange_difference(
      command_id => (confirm_return_exchange.command_id || ':refund')::text,
      tenant_id => confirm_return_exchange.tenant_id,
      actor_id => confirm_return_exchange.actor_id,
      operation => 'refund'::text,
      sales_order_id => v_order.id,
      return_exchange_id => v_session.id,
      amount_minor => v_remainder_refund,
      currency_code => v_plan_currency,
      method => coalesce(nullif(btrim(payment_method), ''), 'cash')::text,
      reference => ('confirm:' || v_plan_corr)::text,
      idempotency_key => (confirm_return_exchange.idempotency_key || ':confirm-refund')::text,
      payload_hash => confirm_return_exchange.payload_hash::text,
      correlation_id => v_plan_corr::text,
      causation_id => confirm_return_exchange.causation_id::text,
      expected_source_version => v_settlement.version
    );
  end if;

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

CREATE OR REPLACE FUNCTION sales.confirm_sales_order_cancellation(command_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, reason_text text, idempotency_key text, payload_hash text, correlation_id text, causation_id text DEFAULT NULL::text, expected_order_version integer DEFAULT NULL::integer, expected_settlement_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'inventory', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_inserted sales.sales_order_cancellations%rowtype;
  v_net_confirmed_collection_minor bigint;
  v_reason_text text;
  v_resulting_version bigint;
  v_outstanding_minor bigint := 0;
  v_decision_snapshot jsonb;
  v_idem jsonb;
  v_correlation uuid;
  v_result jsonb;
  v_id uuid := gen_random_uuid();
begin
  if tenant_id is null or nullif(btrim(idempotency_key), '') is null then
    raise exception using message = jsonb_build_object(
      'code', 'FIELD_NOT_ALLOWED',
      'message', 'Required cancellation identity is missing.'
    )::text;
  end if;

  begin
    v_correlation := nullif(trim(coalesce(correlation_id, '')), '')::uuid;
  exception when others then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID', 'message', 'Correlation id is invalid.'
    )::text;
  end;
  if v_correlation is null then
    begin
      v_correlation := nullif(trim(coalesce(command_id, '')), '')::uuid;
    exception when others then
      v_correlation := gen_random_uuid();
    end;
  end if;

  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'confirm_sales_order_cancellation', idempotency_key, payload_hash);
  if v_idem ->> 'decision' = 'replay' then
    return coalesce(v_idem -> 'result_snapshot', '{}'::jsonb);
  end if;
  if v_idem ->> 'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IN_PROGRESS', 'message', 'Cancellation is already in progress.'
    )::text;
  end if;

  if nullif(btrim(command_id), '') is null
    or actor_id is null
    or sales_order_id is null
    or nullif(btrim(payload_hash), '') is null
    or nullif(btrim(correlation_id), '') is null
    or expected_order_version is null
    or expected_order_version <= 0
    or expected_settlement_version is null
    or expected_settlement_version <= 0 then
    raise exception using message = jsonb_build_object(
      'code', 'FIELD_NOT_ALLOWED',
      'message', 'Required cancellation arguments are missing or invalid.'
    )::text;
  end if;

  if auth.uid() is distinct from actor_id
    or iam.has_permission(tenant_id, 'sales.order.cancel') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = confirm_sales_order_cancellation.sales_order_id
    and sales_orders.tenant_id = confirm_sales_order_cancellation.tenant_id
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.',
      'details', jsonb_build_object('salesOrderId', sales_order_id)
    )::text;
  end if;

  perform sales._assert_sales_actor(
    tenant_id, actor_id, v_order.store_id, 'sales.order.cancel'
  );

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = confirm_sales_order_cancellation.tenant_id
  order by sales_order_settlements.version desc, sales_order_settlements.id desc
  limit 1
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'DEPENDENCY_UNAVAILABLE',
      'message', 'Authoritative settlement is unavailable.'
    )::text;
  end if;

  if v_order.version is distinct from expected_order_version
    or v_settlement.version is distinct from expected_settlement_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Sales order or settlement version is stale.',
      'details', jsonb_build_object(
        'expectedOrderVersion', expected_order_version,
        'actualOrderVersion', v_order.version,
        'expectedSettlementVersion', expected_settlement_version,
        'actualSettlementVersion', v_settlement.version
      )
    )::text;
  end if;

  if v_order.lifecycle_status is distinct from 'completed' then
    raise exception using message = jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'Only completed sales orders may be cancelled.',
      'details', jsonb_build_object(
        'reason', case
          when v_order.lifecycle_status = 'cancelled' then 'ORDER_ALREADY_CANCELLED'
          else 'INVALID_LIFECYCLE'
        end
      )
    )::text;
  end if;

  v_net_confirmed_collection_minor := coalesce(v_settlement.net_collected_amount_minor, 0);
  if v_net_confirmed_collection_minor <> 0 then
    raise exception using message = jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'Net confirmed collection must be zero for EP-05 cancellation.',
      'details', jsonb_build_object(
        'reason', 'PAYMENT_ALREADY_COLLECTED',
        'netConfirmedCollectionMinor', v_net_confirmed_collection_minor
      )
    )::text;
  end if;

  if exists (
    select 1 from sales.sales_order_cancellations c
    where c.tenant_id = confirm_sales_order_cancellation.tenant_id
      and c.sales_order_id = confirm_sales_order_cancellation.sales_order_id
      and c.status in ('requested', 'validating', 'confirmed', 'processing', 'completed')
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'A competing sales order cancellation is already in progress or committed.',
      'details', jsonb_build_object('reason', 'COMPETING_CANCELLATION')
    )::text;
  end if;

  if exists (
    select 1 from sales.return_exchange_orders r
    where r.tenant_id = confirm_sales_order_cancellation.tenant_id
      and r.sales_order_id = confirm_sales_order_cancellation.sales_order_id
      and r.status in ('confirmed', 'processing', 'completed')
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'A confirmed, processing, or completed return/exchange blocks cancellation.',
      'details', jsonb_build_object('reason', 'RETURN_EXCHANGE_CONFLICT')
    )::text;
  end if;

  if exists (
    select 1 from sales.return_exchange_orders r
    where r.tenant_id = confirm_sales_order_cancellation.tenant_id
      and r.sales_order_id = confirm_sales_order_cancellation.sales_order_id
      and r.status = 'draft'
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'Resolve or discard the draft return/exchange before cancelling.',
      'details', jsonb_build_object('reason', 'DRAFT_RETURN_ACTIVE')
    )::text;
  end if;

  v_reason_text := btrim(coalesce(reason_text, ''));

  v_outstanding_minor := coalesce(v_settlement.outstanding_amount_minor, 0);

  v_resulting_version := v_order.version + 1;
  v_decision_snapshot := jsonb_build_object(
    'netConfirmedCollectionMinor', v_net_confirmed_collection_minor,
    'sourceOrderVersion', v_order.version,
    'sourceSettlementVersion', v_settlement.version,
    'resultingOrderVersion', v_resulting_version,
    'payloadHash', payload_hash,
    'correlationId', correlation_id,
    'causationId', causation_id,
    'reasonText', v_reason_text,
    -- Model B handoff deferred: downstream impacts are not tracked by Sales.
    'impacts', jsonb_build_object(
      'inventory', 'not_required',
      'receivable', 'not_required',
      'eInvoice', 'not_required',
      'pricing', 'required',
      'reporting', 'required'
    )
  );

  insert into sales.sales_order_cancellations (
    id, tenant_id, sales_order_id, status, source_order_version,
    requested_by_user_id, reason, precheck_snapshot, confirmed_at
  ) values (
    v_id,
    confirm_sales_order_cancellation.tenant_id,
    confirm_sales_order_cancellation.sales_order_id,
    'confirmed',
    v_order.version,
    confirm_sales_order_cancellation.actor_id,
    nullif(v_reason_text, ''),
    v_decision_snapshot,
    now()
  )
  returning * into v_inserted;

  update sales.sales_orders
  set lifecycle_status = 'cancelled',
      cancelled_at = coalesce(cancelled_at, now()),
      version = v_resulting_version,
      updated_at = now()
  where id = confirm_sales_order_cancellation.sales_order_id
    and sales_orders.tenant_id = confirm_sales_order_cancellation.tenant_id;

  -- Reverse sale in inventory ledger
  perform inventory._reverse_sale(
    confirm_sales_order_cancellation.tenant_id,
    v_order.store_id,
    'SALES_CANCELLATION',
    v_inserted.id,
    (
      select jsonb_agg(jsonb_build_object(
        'line_id', sol.id,
        'source_intent_type', 'SALES_ORDER',
        'source_intent_line_id', sol.id,
        'product_id', sol.product_id,
        'base_qty', sol.base_quantity_micros::numeric / 1000000.0
      ))
      from sales.sales_order_lines sol
      where sol.tenant_id = confirm_sales_order_cancellation.tenant_id
        and sol.sales_order_id = v_order.id
    ),
    confirm_sales_order_cancellation.actor_id
  );

  -- B4b: huy don -> triet tieu nghia vu con lai (current_payable -> 0), mot lan/nguon
  -- (source_id = cancellation). Giu nguyen tien thuong mai goc; chi doi nghia vu.
  if v_settlement.id is not null then
    perform sales._apply_settlement_obligation_adjustment(
      confirm_sales_order_cancellation.tenant_id,
      v_settlement.id,
      'cancellation',
      v_inserted.id,
      -v_settlement.current_payable_amount_minor
    );
  end if;

  if v_settlement.id is not null then
    -- Money snapshot after cancellation obligation. sales_order_cancelled owns goods, not money.
    perform sales._emit_sales_settlement_changed(
      confirm_sales_order_cancellation.tenant_id,
      v_settlement.id,
      'cancellation',
      v_inserted.id::text,
      'confirm_sales_order_cancellation'
    );
  end if;

  -- Model B handoff deferred: cancellation only publishes Sales lifecycle facts.
  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(),
    confirm_sales_order_cancellation.tenant_id,
    'sales_order_cancellation_confirmed.v1',
    jsonb_build_object(
      'cancellationId', v_inserted.id,
      'salesOrderId', v_inserted.sales_order_id,
      'salesOrderVersion', v_resulting_version,
      'correlationId', correlation_id,
      'impacts', v_decision_snapshot -> 'impacts'
    )
  );

  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(),
    confirm_sales_order_cancellation.tenant_id,
    'sales_order_cancelled.v1',
    jsonb_build_object(
      'cancellationId', v_inserted.id,
      'salesOrderId', v_inserted.sales_order_id,
      'salesOrderVersion', v_resulting_version,
      'correlationId', correlation_id
    )
  );


  -- Deprecated transitional producer. No in-repo consumer. External consumers NOT RUN.
  -- Reporting must consume sales_order_cancelled.v1. Do not delete until that check is verified.
  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(),
    confirm_sales_order_cancellation.tenant_id,
    'sales_reporting_cancellation_recorded.v1',
    jsonb_build_object(
      'cancellationId', v_inserted.id,
      'salesOrderId', v_inserted.sales_order_id,
      'correlationId', correlation_id
    )
  );

  v_result := jsonb_build_object(
    'cancellationId', v_inserted.id,
    'salesOrderId', v_inserted.sales_order_id,
    'salesOrderVersion', v_resulting_version,
    'status', v_inserted.status
  );
  perform sales._complete_sales_idempotency(
    tenant_id, 'confirm_sales_order_cancellation', trim(idempotency_key),
    'succeeded', v_result);
  return v_result;
end;
$function$
;

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
  v_plan jsonb;
  v_details jsonb;
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
    v_abs_diff := abs(v_net_difference_minor);
    v_refund_amount_minor := least(v_abs_diff, v_net_confirmed_collection);
    v_receivable_reverse_amount_minor := v_abs_diff - v_refund_amount_minor;
    if v_refund_amount_minor + v_receivable_reverse_amount_minor
      is distinct from v_abs_diff then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settlement plan refund/reversal components must balance.'
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

  v_plan := jsonb_build_object(
    'currency_code', v_currency,
    'net_difference_minor', v_net_difference_minor,
    'collect_amount_minor', v_collect_amount_minor,
    'refund_amount_minor', v_refund_amount_minor,
    'receivable_create_amount_minor', v_receivable_create_amount_minor,
    'receivable_reverse_amount_minor', v_receivable_reverse_amount_minor,
    'processed_collect_minor', 0,
    'processed_refund_minor', 0,
    'pending_receivable_create_minor', 0,
    'pending_receivable_reverse_minor', 0,
    'remainder_collect_minor', v_collect_amount_minor,
    'remainder_refund_minor', v_refund_amount_minor,
    'source_session_version', v_session.version,
    'source_order_version', v_order.version,
    'source_settlement_version', v_settlement.version,
    'pricing_source_version', v_pricing_source_version,
    'inventory_source_version', v_inventory_source_version,
    'sales_order_id', v_order.id,
    'correlation_id', v_correlation_id
  );

  v_details := jsonb_build_object(
    'settlement_plan', v_plan,
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

CREATE OR REPLACE FUNCTION sales.finalize_sales_order(p_command_id uuid, p_tenant_id uuid, p_actor_id uuid, p_store_id uuid, p_source_draft_id uuid, p_customer_id uuid, p_currency_code text, p_order_note text, p_commercial_snapshot jsonb, p_lines jsonb, p_payment_intents jsonb, p_idempotency_key text, p_payload_hash text, p_correlation_id text, p_payment_due_date date DEFAULT NULL::date, p_causation_id text DEFAULT NULL::text, p_expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'inventory', 'catalog', 'public', 'pg_temp'
AS $function$
declare
  v_decision jsonb;
  v_correlation uuid;
  v_currency_code text := upper(trim(coalesce(p_currency_code, '')));
  v_order_id uuid := gen_random_uuid();
  v_settlement_id uuid := gen_random_uuid();
  v_grand_total_minor bigint := 0;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_paid_total_minor bigint := 0;
  v_remaining_minor bigint := 0;
  v_line jsonb;
  v_commercial_line jsonb;
  v_payment jsonb;
  v_line_index integer := 0;
  v_order_line_id uuid;
  v_conversion_rate numeric;
  v_base_numeric numeric;
  v_unit_price_minor bigint;
  v_gross_minor bigint;
  v_discount_minor bigint;
  v_line_total_minor bigint;
  v_pricing jsonb;
  v_pricing_lines jsonb := '[]'::jsonb;
  v_priced jsonb;
  v_is_discount_mode boolean;
  v_pricing_snapshot jsonb;
  v_subtotal_minor bigint := 0;
  v_order_discount_minor bigint := 0;
  v_persisted_line_inputs jsonb := '[]'::jsonb;
  v_normalized_commercial_snapshot jsonb;
  v_period text;
  v_seq_no bigint;
  v_order_code text;
  v_payment_status text;
  v_result jsonb;
  v_request jsonb;
  v_request_hash text;
  v_error text;
  v_error_code text;
  v_error_msg text;
  v_stock_issue_input jsonb := '[]'::jsonb;
  v_stock_issue_res jsonb;
  v_issue_line jsonb;
begin
  perform sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.checkout.create');

  if jsonb_typeof(coalesce(p_payment_intents, '[]'::jsonb)) = 'array'
     and jsonb_array_length(coalesce(p_payment_intents, '[]'::jsonb)) > 0
     and iam.has_permission(p_tenant_id, 'sales.payment.record') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED',
      'message', 'Payment recording permission is required.'
    )::text;
  end if;

  if p_command_id is null
     or nullif(trim(coalesce(p_idempotency_key, '')), '') is null
     or nullif(trim(coalesce(p_payload_hash, '')), '') is null
     or v_currency_code = '' then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Checkout context is invalid.'
    )::text;
  end if;

  if nullif(trim(coalesce(p_correlation_id, '')), '') is null then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Correlation id is required.'
    )::text;
  end if;
  if trim(p_correlation_id) !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Correlation id is malformed.'
    )::text;
  end if;
  v_correlation := trim(p_correlation_id)::uuid;

  -- A4 (VĐ1): server tự dựng payload chuẩn từ tham số THẬT và tự băm, không tin
  -- p_payload_hash do client gửi. Bỏ các field transport (command_id/correlation/causation)
  -- khỏi identity. jsonb::text đã chuẩn hóa thứ tự key nên md5 ổn định; array giữ thứ tự.
  v_request := jsonb_build_object(
    'storeId', p_store_id,
    'sourceDraftId', p_source_draft_id,
    'customerId', p_customer_id,
    'currencyCode', p_currency_code,
    'orderNote', p_order_note,
    'commercialSnapshot', p_commercial_snapshot,
    'lines', p_lines,
    'paymentIntents', p_payment_intents,
    'paymentDueDate', p_payment_due_date,
    'expectedSourceVersion', p_expected_source_version
  );
  v_request_hash := md5(v_request::text);

  -- IdempotencyRecord owns checkout recovery; helper locks tenant:scope:key.
  v_decision := sales._begin_sales_idempotency(
    p_tenant_id,
    'finalize_sales_order',
    trim(p_idempotency_key),
    v_request_hash);
  if v_decision->>'decision' = 'replay' then
    return v_decision->'result_snapshot'->'checkoutResult';
  end if;
  if v_decision->>'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Checkout is already in progress for this request.'
    )::text;
  end if;

  if (p_source_draft_id is null) is distinct from (p_expected_source_version is null) then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Source draft ID and expected version must be supplied together.'
    )::text;
  end if;

  begin
    if p_source_draft_id is not null then
      perform 1
      from sales.sales_order_drafts
      where tenant_id = p_tenant_id
        and store_id = p_store_id
        and id = p_source_draft_id
        and status = 'active'
        and version = p_expected_source_version
      for update;
      if not found then
        raise exception using message = jsonb_build_object(
          'code', 'STALE_VERSION',
          'message', 'Source draft version is stale.'
        )::text;
      end if;
    end if;

    if jsonb_typeof(coalesce(p_lines, '[]'::jsonb)) <> 'array'
       or jsonb_array_length(coalesce(p_lines, '[]'::jsonb)) = 0
       or jsonb_typeof(coalesce(p_payment_intents, '[]'::jsonb)) <> 'array'
       or jsonb_typeof(coalesce(p_commercial_snapshot, 'null'::jsonb)) <> 'object'
       or jsonb_typeof(p_commercial_snapshot -> 'store') <> 'object'
       or jsonb_typeof(p_commercial_snapshot -> 'seller') <> 'object'
       or jsonb_typeof(p_commercial_snapshot -> 'lines') <> 'array'
       or jsonb_array_length(p_commercial_snapshot -> 'lines') <> jsonb_array_length(p_lines) then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Checkout payload is invalid.'
      )::text;
    end if;

    if nullif(trim(coalesce(p_commercial_snapshot -> 'store' ->> 'storeId', '')), '') is null
       or trim(p_commercial_snapshot -> 'store' ->> 'storeId') <> p_store_id::text
       or nullif(trim(coalesce(p_commercial_snapshot -> 'seller' ->> 'actorId', '')), '') is null
       or trim(p_commercial_snapshot -> 'seller' ->> 'actorId') <> p_actor_id::text
       or (p_customer_id is null) is distinct from (
         jsonb_typeof(coalesce(p_commercial_snapshot -> 'customer', 'null'::jsonb)) = 'null'
       ) then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Commercial snapshot context is invalid.'
      )::text;
    end if;

    if p_customer_id is not null
       and (
         jsonb_typeof(p_commercial_snapshot -> 'customer') <> 'object'
         or trim(p_commercial_snapshot -> 'customer' ->> 'customerId') <> p_customer_id::text
         or nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'displayName', '')), '') is null
       ) then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Commercial customer snapshot is invalid.'
      )::text;
    end if;

    if p_customer_id is not null
       and nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'buyerType', '')), '') is not null
       and nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'buyerType', '')), '')
           not in ('individual', 'organization') then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Commercial customer buyerType is invalid.'
      )::text;
    end if;

    if p_customer_id is not null and not exists (
      select 1
      from partner.partners pp
      join partner.partner_roles pr
        on pr.partner_id = pp.partner_id and pr.role = 'customer' and pr.is_active
      where pp.tenant_id = p_tenant_id and pp.partner_id = p_customer_id and pp.status = 'active'
    ) then
      raise exception using message = jsonb_build_object(
        'code', 'CUSTOMER_INVALID',
        'message', 'Customer is inactive or not a customer.'
      )::text;
    end if;

    -- Server tự tính giá bằng đúng hàm màn bán hàng dùng; không dùng đơn giá app gửi.
    select coalesce(jsonb_agg(jsonb_build_object(
      'local_line_id', l.ordinality::text,
      'product_id', l.value ->> 'product_id',
      'product_unit_id', l.value ->> 'product_unit_id',
      'quantity_micros', (l.value ->> 'quantity_micros')::bigint,
      'manual_unit_price_minor', l.value -> 'manual_unit_price_minor',
      'manual_discount_minor', l.value -> 'manual_discount_minor',
      'manual_discount_basis_points', l.value -> 'manual_discount_basis_points'
    ) order by l.ordinality), '[]'::jsonb)
    into v_pricing_lines
    from jsonb_array_elements(p_lines) with ordinality as l(value, ordinality);

    v_pricing := pricing.preview_sales_working_state_pricing(
      p_tenant_id, p_store_id, p_customer_id, v_currency_code, 0, now(), v_pricing_lines
    );

    for v_line in select * from jsonb_array_elements(p_lines) loop
      v_line_index := v_line_index + 1;
      v_commercial_line := p_commercial_snapshot -> 'lines' -> (v_line_index - 1);
      if nullif(trim(coalesce(v_line ->> 'product_id', '')), '') is null
         or nullif(trim(coalesce(v_line ->> 'product_unit_id', '')), '') is null
         or coalesce((v_line ->> 'quantity_micros')::bigint, 0) <= 0
         or coalesce((v_line -> 'unit_price' ->> 'amount_minor')::bigint, 0) <= 0
         or upper(trim(coalesce(v_line -> 'unit_price' ->> 'currency_code', ''))) <> v_currency_code then
        raise exception using message = jsonb_build_object(
          'code', 'CONTEXT_INVALID',
          'message', 'Checkout line is invalid.'
        )::text;
      end if;

      -- Tiền dòng do server tính (spec 2026-09-28 §4.1): chỉ giảm tiền/% sinh chiết khấu;
      -- giá riêng / sửa đơn giá / niêm yết: đơn giá = giá áp dụng, chiết khấu 0. Thuế 0.
      v_priced := v_pricing -> 'lines' -> (v_line_index - 1);
      if v_priced is null or (v_priced ->> 'local_line_id') <> v_line_index::text then
        raise exception using message = jsonb_build_object(
          'code', 'CONTEXT_INVALID',
          'message', 'Pricing result does not match checkout lines.'
        )::text;
      end if;
      if jsonb_array_length(coalesce(v_priced -> 'blocking_codes', '[]'::jsonb)) > 0 then
        raise exception using message = jsonb_build_object(
          'code', 'PRICING_BLOCKED',
          'message', 'Line pricing is blocked.',
          'details', jsonb_build_object('lineIndex', v_line_index, 'blockingCodes', v_priced -> 'blocking_codes')
        )::text;
      end if;

      v_is_discount_mode := (v_priced ->> 'source_code') = 'MANUAL'
        and (v_line ->> 'manual_unit_price_minor') is null
        and ((v_line ->> 'manual_discount_minor') is not null
          or (v_line ->> 'manual_discount_basis_points') is not null);
      v_line_total_minor := (v_priced ->> 'line_total_minor')::bigint;
      if v_is_discount_mode then
        v_unit_price_minor := (v_priced ->> 'list_price_minor')::bigint;
        v_gross_minor := v_unit_price_minor * (v_line ->> 'quantity_micros')::bigint / 1000000;
      else
        v_unit_price_minor := (v_priced ->> 'applied_unit_price_minor')::bigint;
        v_gross_minor := v_line_total_minor;
      end if;
      v_discount_minor := v_gross_minor - v_line_total_minor;

      v_pricing_snapshot := jsonb_strip_nulls(jsonb_build_object(
        'sourceCode', case
          when (v_priced ->> 'source_code') <> 'MANUAL' then v_priced ->> 'source_code'
          when (v_line ->> 'manual_unit_price_minor') is not null then 'MANUAL_PRICE'
          when (v_line ->> 'manual_discount_minor') is not null then 'MANUAL_DISCOUNT_AMOUNT'
          else 'MANUAL_DISCOUNT_PERCENT'
        end,
        'listUnitPriceMinor', (v_priced ->> 'list_price_minor')::bigint,
        'appliedUnitPriceMinor', (v_priced ->> 'applied_unit_price_minor')::bigint,
        'manualDiscountMinor', case when v_is_discount_mode then (v_line ->> 'manual_discount_minor')::bigint end,
        'discountBasisPoints', case when v_is_discount_mode then (v_line ->> 'manual_discount_basis_points')::integer end,
        'warningCodes', coalesce(v_priced -> 'warning_codes', '[]'::jsonb),
        'pricedAt', now()
      ));

      if v_discount_minor < 0 or v_discount_minor > v_gross_minor then
        raise exception using message = jsonb_build_object(
          'code', 'COMMERCIAL_TOTAL_MISMATCH',
          'message', 'Line discount is out of range.'
        )::text;
      end if;

      if jsonb_typeof(v_commercial_line) <> 'object'
         or nullif(trim(coalesce(v_commercial_line ->> 'lineId', '')), '') is null
         or jsonb_typeof(v_commercial_line -> 'product') <> 'object'
         or trim(v_commercial_line -> 'product' ->> 'productId') <> trim(v_line ->> 'product_id')
         or nullif(trim(coalesce(v_commercial_line -> 'product' ->> 'displayName', '')), '') is null
         or jsonb_typeof(v_commercial_line -> 'unit') <> 'object'
         or trim(v_commercial_line -> 'unit' ->> 'productUnitId') <> trim(v_line ->> 'product_unit_id')
         or nullif(trim(coalesce(v_commercial_line -> 'unit' ->> 'unitName', '')), '') is null
         or coalesce((v_commercial_line ->> 'quantityMicros')::bigint, 0) <> (v_line ->> 'quantity_micros')::bigint then
        raise exception using message = jsonb_build_object(
          'code', 'CHECKOUT_BLOCKED',
          'message', 'Commercial line snapshot does not match checkout lines.'
        )::text;
      end if;

      -- Số khách đã xem khác số server tính (giá vừa đổi) → không tạo đơn.
      if coalesce((v_commercial_line -> 'lineTotal' ->> 'amountMinor')::bigint, -1) <> v_line_total_minor then
        raise exception using message = jsonb_build_object(
          'code', 'PRICE_CHANGED',
          'message', 'Line price changed since preview.',
          'details', jsonb_build_object(
            'lineId', v_commercial_line ->> 'lineId',
            'expectedLineTotalMinor', (v_commercial_line -> 'lineTotal' ->> 'amountMinor')::bigint,
            'actualLineTotalMinor', v_line_total_minor
          )
        )::text;
      end if;

      -- A2: đọc luôn conversion_rate_to_base để tính số lượng cơ sở, thay cho perform 1.
      select pu.conversion_rate_to_base
      into v_conversion_rate
      from catalog.products p
      join catalog.product_units pu
        on pu.tenant_id = p.tenant_id
       and pu.product_id = p.id
      where p.tenant_id = p_tenant_id
        and p.id = trim(v_line ->> 'product_id')::uuid
        and p.business_status = 'active'::catalog.product_business_status
        and p.is_ready_to_sell = true
        and pu.id = trim(v_line ->> 'product_unit_id')::uuid
        and pu.is_active = true;

      if not found then
        raise exception using message = jsonb_build_object(
          'code', 'PRODUCT_NOT_SELLABLE',
          'message', 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.'
        )::text;
      end if;

      -- A2: base = số lượng bán × conversion_rate_to_base (đơn vị cơ sở/đơn vị bán).
      -- Bán nguyên đơn vị (quyết định #3): ra số lẻ hoặc vượt phạm vi thì từ chối.
      if v_conversion_rate is null or v_conversion_rate <= 0 then
        raise exception using message = jsonb_build_object(
          'code', 'INVALID_QUANTITY',
          'message', 'Missing or invalid unit conversion rate.'
        )::text;
      end if;
      v_base_numeric := (v_line ->> 'quantity_micros')::numeric * v_conversion_rate;
      if v_base_numeric <> trunc(v_base_numeric)
         or v_base_numeric <= 0
         or v_base_numeric > 9223372036854775807 then
        raise exception using message = jsonb_build_object(
          'code', 'INVALID_QUANTITY',
          'message', 'Base quantity is fractional or out of range.'
        )::text;
      end if;

      v_order_line_id := gen_random_uuid();
      v_persisted_line_inputs := v_persisted_line_inputs || jsonb_build_array(
        jsonb_build_object(
          'lineId', v_order_line_id::text,
          'product_id', trim(v_line ->> 'product_id'),
          'product_unit_id', trim(v_line ->> 'product_unit_id'),
          'quantity_micros', (v_line ->> 'quantity_micros')::bigint,
          'base_quantity_micros', v_base_numeric::bigint,
          'unit_price_minor', v_unit_price_minor,
          'gross_amount_minor', v_gross_minor,
          'discount_amount_minor', v_discount_minor,
          'line_total_minor', v_line_total_minor,
          'pricing_snapshot', v_pricing_snapshot,
          'note', nullif(trim(coalesce(v_line ->> 'note', '')), ''),
          'product_snapshot', jsonb_build_object(
            'productId', trim(v_commercial_line -> 'product' ->> 'productId'),
            'sku', nullif(trim(coalesce(v_commercial_line -> 'product' ->> 'sku', '')), ''),
            'displayName', trim(v_commercial_line -> 'product' ->> 'displayName')
          ),
          'product_unit_snapshot', jsonb_build_object(
            'productUnitId', trim(v_commercial_line -> 'unit' ->> 'productUnitId'),
            'unitCode', nullif(trim(coalesce(v_commercial_line -> 'unit' ->> 'unitCode', '')), ''),
            'unitName', trim(v_commercial_line -> 'unit' ->> 'unitName'),
            'conversionRateToBase', v_conversion_rate
          )
        )
      );
      v_subtotal_minor := v_subtotal_minor + v_gross_minor;
      v_order_discount_minor := v_order_discount_minor + v_discount_minor;
      v_grand_total_minor := v_grand_total_minor + v_line_total_minor;
    end loop;

    for v_payment in
      select * from jsonb_array_elements(coalesce(p_payment_intents, '[]'::jsonb))
    loop
      if coalesce((v_payment -> 'amount' ->> 'amount_minor')::bigint, 0) <= 0
         or upper(trim(coalesce(v_payment -> 'amount' ->> 'currency_code', ''))) <> v_currency_code
         or nullif(trim(coalesce(v_payment ->> 'method', '')), '') is null then
        raise exception using message = jsonb_build_object(
          'code', 'CONTEXT_INVALID',
          'message', 'Payment intent is invalid.'
        )::text;
      end if;
      v_paid_total_minor := v_paid_total_minor
        + (v_payment -> 'amount' ->> 'amount_minor')::bigint;
    end loop;

    if v_paid_total_minor > v_grand_total_minor then
      raise exception using message = jsonb_build_object(
        'code', 'CHECKOUT_BLOCKED',
        'message', 'Paid amount exceeds checkout total.'
      )::text;
    end if;
    v_remaining_minor := v_grand_total_minor - v_paid_total_minor;
    if v_remaining_minor > 0 and p_customer_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'CHECKOUT_BLOCKED',
        'message', 'Walk-in checkout cannot leave a receivable balance.'
      )::text;
    end if;
    if v_remaining_minor > 0 and p_payment_due_date is null then
      raise exception using message = jsonb_build_object(
        'code', 'RECEIVABLE_DUE_DATE_REQUIRED',
        'message', 'Ngày hẹn thanh toán là bắt buộc khi phát sinh công nợ.'
      )::text;
    end if;
    if v_remaining_minor > 0 and p_payment_due_date < v_today then
      raise exception using message = jsonb_build_object(
        'code', 'RECEIVABLE_DUE_DATE_INVALID',
        'message', 'Ngày hẹn thanh toán không được trước hôm nay.'
      )::text;
    end if;

    v_normalized_commercial_snapshot := jsonb_build_object(
      'store', jsonb_build_object(
        'storeId', p_store_id::text,
        'storeCode', trim(coalesce(p_commercial_snapshot -> 'store' ->> 'storeCode', '')),
        'displayName', trim(coalesce(p_commercial_snapshot -> 'store' ->> 'displayName', ''))
      ),
      'seller', jsonb_build_object(
        'actorId', p_actor_id::text,
        'displayName', trim(coalesce(p_commercial_snapshot -> 'seller' ->> 'displayName', ''))
      ),
      'customer', case
        when p_customer_id is null then null
        else jsonb_build_object(
          'customerId', p_customer_id::text,
          'displayName', trim(p_commercial_snapshot -> 'customer' ->> 'displayName'),
          'phoneNumber', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'phoneNumber', '')), ''),
          'taxCode', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'taxCode', '')), ''),
          'buyerType', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'buyerType', '')), ''),
          'invoiceLegalName', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceLegalName', '')), ''),
          'invoiceAddress', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceAddress', '')), ''),
          'invoiceEmail', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceEmail', '')), '')
        )
      end
    );

    v_period := to_char((current_timestamp at time zone 'Asia/Ho_Chi_Minh')::date, 'YYYYMMDD');
    insert into sales.sales_order_number_counters(tenant_id, store_id, period_key, next_value)
    values (p_tenant_id, p_store_id, v_period, 1)
    on conflict (tenant_id, store_id, period_key)
      do update set next_value = sales.sales_order_number_counters.next_value + 1
    returning next_value into v_seq_no;

    if v_seq_no > 9999 then
      raise exception using message = jsonb_build_object(
        'code', 'CHECKOUT_BLOCKED',
        'message', 'Daily order number limit exceeded.'
      )::text;
    end if;

    v_order_code := 'DH' || v_period || lpad(v_seq_no::text, 4, '0');
    v_payment_status := case
      when v_paid_total_minor <= 0 then 'unpaid'
      when v_remaining_minor = 0 then 'paid'
      else 'partially_paid'
    end;

    insert into sales.sales_orders(
      id, tenant_id, source_draft_id, order_code, store_id,
      seller_user_id, customer_partner_id, channel_code, currency_code,
      lifecycle_status, lock_status, version, internal_note,
      subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor,
      payable_amount_minor, sales_context_snapshot,
      buyer_tax_snapshot,
      completed_at
    ) values (
      v_order_id, p_tenant_id, p_source_draft_id, v_order_code, p_store_id,
      p_actor_id, p_customer_id, 'pos', v_currency_code,
      'completed', 'unlocked', 1, nullif(trim(coalesce(p_order_note, '')), ''),
      v_subtotal_minor, v_order_discount_minor, 0, 0, v_grand_total_minor,
      v_normalized_commercial_snapshot,
      case
        when p_customer_id is null then null
        else jsonb_strip_nulls(jsonb_build_object(
          'buyerType', nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'buyerType', '')), ''),
          'legalName', coalesce(
            nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceLegalName', '')), ''),
            trim(p_commercial_snapshot -> 'customer' ->> 'displayName')),
          'taxCode',   nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'taxCode', '')), ''),
          'address',   nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceAddress', '')), ''),
          'email',     nullif(trim(coalesce(p_commercial_snapshot -> 'customer' ->> 'invoiceEmail', '')), '')
        ))
      end,
      now()
    );

    v_line_index := 0;
    for v_line in select * from jsonb_array_elements(v_persisted_line_inputs) loop
      v_line_index := v_line_index + 1;
      insert into sales.sales_order_lines(
        id, tenant_id, sales_order_id, line_sequence, product_id, product_unit_id,
        quantity_micros, base_quantity_micros, unit_price_minor, gross_amount_minor,
        discount_amount_minor, tax_amount_minor, line_total_minor,
        product_snapshot, product_unit_snapshot, line_note, pricing_snapshot
      ) values (
        (v_line ->> 'lineId')::uuid, p_tenant_id, v_order_id, v_line_index,
        (v_line ->> 'product_id')::uuid, (v_line ->> 'product_unit_id')::uuid,
        (v_line ->> 'quantity_micros')::bigint, (v_line ->> 'base_quantity_micros')::bigint,
        (v_line ->> 'unit_price_minor')::bigint, (v_line ->> 'gross_amount_minor')::bigint,
        (v_line ->> 'discount_amount_minor')::bigint, 0, (v_line ->> 'line_total_minor')::bigint,
        coalesce(v_line -> 'product_snapshot', '{}'::jsonb),
        coalesce(v_line -> 'product_unit_snapshot', '{}'::jsonb),
        nullif(trim(coalesce(v_line ->> 'note', '')), ''),
        coalesce(v_line -> 'pricing_snapshot', '{}'::jsonb)
      );
    end loop;

    -- Issue stock FEFO for sale order lines and persist COGS snapshot
    for v_line in select * from jsonb_array_elements(v_persisted_line_inputs) loop
      v_stock_issue_input := v_stock_issue_input || jsonb_build_array(jsonb_build_object(
        'line_id', (v_line ->> 'lineId')::uuid,
        'product_id', (v_line ->> 'product_id')::uuid,
        'base_qty', (v_line ->> 'base_quantity_micros')::numeric / 1000000.0,
        'unit_name', coalesce(v_line -> 'product_unit_snapshot' ->> 'unitName', ''),
        'conversion_rate', coalesce((v_line -> 'product_unit_snapshot' ->> 'conversionRateToBase')::numeric, 1)
      ));
    end loop;

    v_stock_issue_res := inventory._issue_for_sale(
      p_tenant_id,
      p_store_id,
      'SALES_ORDER',
      v_order_id,
      v_stock_issue_input,
      p_actor_id
    );

    for v_issue_line in select * from jsonb_array_elements(coalesce(v_stock_issue_res -> 'lines', '[]'::jsonb)) loop
      update sales.sales_order_lines
      set cogs_amount_vnd = (v_issue_line ->> 'cogs_amount_vnd')::bigint,
          cogs_unit_cost = (v_issue_line ->> 'cogs_unit_cost')::numeric,
          cost_version_id = nullif(v_issue_line ->> 'cost_version_id', '')::uuid,
          cogs_is_provisional = coalesce((v_issue_line ->> 'is_provisional')::boolean, false)
      where tenant_id = p_tenant_id
        and sales_order_id = v_order_id
        and id = (v_issue_line ->> 'line_id')::uuid;
    end loop;

    insert into receivable.sales_order_settlements(
      id, tenant_id, sales_order_id, currency_code, original_payable_amount_minor,
      post_sale_adjustment_amount_minor, current_payable_amount_minor, collected_amount_minor,
      refunded_amount_minor, net_collected_amount_minor, outstanding_amount_minor,
      payment_status, settled_at, payment_due_date
    ) values (
      v_settlement_id, p_tenant_id, v_order_id, v_currency_code, v_grand_total_minor,
      0, v_grand_total_minor, v_paid_total_minor, 0, v_paid_total_minor, v_remaining_minor,
      v_payment_status,
      case when v_remaining_minor = 0 and v_paid_total_minor > 0 then now() else null end,
      p_payment_due_date
    );

    for v_payment in
      select value
      from jsonb_array_elements(coalesce(p_payment_intents, '[]'::jsonb))
    loop
      insert into receivable.sales_payment_transactions(
        id, tenant_id, sales_order_settlement_id, transaction_type,
        direction, amount_minor, currency_code, payment_method_code, status, source_context,
        source_type, source_id, initiated_by_user_id,
        external_reference, occurred_at
      ) values (
        gen_random_uuid(), p_tenant_id, v_settlement_id,
        'collection', 'inflow',
        (v_payment -> 'amount' ->> 'amount_minor')::bigint, v_currency_code,
        trim(v_payment ->> 'method'), 'confirmed', 'checkout',
        'sales_order', v_order_id, p_actor_id,
        nullif(trim(coalesce(v_payment ->> 'reference', '')), ''),
        now()
      );
    end loop;

    -- Money snapshot after checkout collections. Lifecycle fact below owns goods, not money.
    perform sales._emit_sales_settlement_changed(
      p_tenant_id,
      v_settlement_id,
      'checkout',
      p_command_id::text,
      'finalize_sales_order'
    );

    -- Model B handoff deferred: no inventory/receivable impact enqueue here.
    -- Sales only publishes the lifecycle fact below.
    insert into sales.outbox_messages(id, tenant_id, event_type, payload)
    values (
      gen_random_uuid(), p_tenant_id, 'sales_order_finalized.v1',
      jsonb_build_object(
        'salesOrderId', v_order_id::text,
        'salesOrderVersion', 1,
        'orderCode', v_order_code,
        'correlationId', v_correlation::text,
        'causationId', p_causation_id,
        'paymentStatus', v_payment_status,
        'payableMinor', v_grand_total_minor,
        'collectedMinor', v_paid_total_minor,
        'currencyCode', v_currency_code
      )
    );

    if p_source_draft_id is not null then
      update sales.sales_order_drafts
      set status = 'converted',
          version = version + 1,
          updated_by_user_id = p_actor_id,
          updated_at = now()
      where tenant_id = p_tenant_id
        and store_id = p_store_id
        and id = p_source_draft_id
        and status = 'active'
        and version = p_expected_source_version;
      if not found then
        raise exception using message = jsonb_build_object(
          'code', 'STALE_VERSION',
          'message', 'Source draft changed during checkout.'
        )::text;
      end if;
    end if;

    v_result := jsonb_build_object(
      'idempotencyKey', trim(p_idempotency_key),
      'salesOrderId', v_order_id::text,
      'salesOrderVersion', 1,
      'status', 'succeeded'
    );

    perform sales._complete_sales_idempotency(
      p_tenant_id,
      'finalize_sales_order',
      trim(p_idempotency_key),
      'succeeded',
      jsonb_build_object(
        'storeId', p_store_id,
        'requestedByUserId', p_actor_id,
        'checkoutResult', v_result
      ));

    return v_result;

  exception when others then
    v_error := sqlerrm;
    begin
      v_error_code := coalesce((v_error::jsonb) ->> 'code', 'CHECKOUT_FAILED');
      v_error_msg := (v_error::jsonb) ->> 'message';
    exception when others then
      v_error_code := 'CHECKOUT_FAILED';
      v_error_msg := null;
    end;

    v_result := jsonb_build_object(
      'idempotencyKey', trim(p_idempotency_key),
      'salesOrderId', '',
      'salesOrderVersion', 0,
      'status', case
        when v_error_code in (
          'CHECKOUT_BLOCKED', 'STALE_VERSION', 'CONTEXT_INVALID',
          'PRODUCT_NOT_SELLABLE', 'RECEIVABLE_DUE_DATE_REQUIRED',
          'PRICE_CHANGED', 'PRICING_BLOCKED', 'CUSTOMER_INVALID',
          'RECEIVABLE_DUE_DATE_INVALID', 'INSUFFICIENT_STOCK'
        ) then 'blocked'
        else 'failed'
      end
    );
    if v_result ->> 'status' = 'blocked' then
      v_result := v_result || jsonb_build_object(
        'blockedCode', v_error_code,
        'blockedMessage', case
          when v_error_code = 'INSUFFICIENT_STOCK' then coalesce(v_error_msg, 'Không đủ tồn kho để bán.')
          else null
        end
      );
    end if;

    if v_error_code in (
      'PERMISSION_DENIED', 'DATA_SCOPE_DENIED', 'IDEMPOTENCY_CONFLICT',
      'CHECKOUT_RESULT_NOT_FOUND'
    ) then
      raise;
    end if;

    -- Ghi kết quả blocked/failed vào IdempotencyRecord để replay trả lại đúng kết quả.
    perform sales._complete_sales_idempotency(
      p_tenant_id,
      'finalize_sales_order',
      trim(p_idempotency_key),
      'failed',
      jsonb_build_object(
        'storeId', p_store_id,
        'requestedByUserId', p_actor_id,
        'checkoutResult', v_result
      ));

    return v_result;
  end;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.generate_sales_receipt(p_command_id uuid, p_tenant_id uuid, p_actor_id uuid, p_sales_order_id uuid, p_idempotency_key text, p_payload_hash text, p_correlation_id text, p_causation_id text DEFAULT NULL::text, p_expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_receipt sales.sales_receipts%rowtype;
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_due_at text;
  v_payments jsonb;
  v_adjustment_sources jsonb;
  v_receipt_lines jsonb;
  v_receipt_subtotal_minor bigint;
  v_snapshot jsonb;
  v_idem jsonb;
  v_idem_key text;
  v_correlation uuid;
  v_next_version integer;
  v_receipt_id uuid := gen_random_uuid();
  v_result jsonb;
  v_currency text;
begin
  begin
    v_correlation := nullif(trim(coalesce(p_correlation_id, '')), '')::uuid;
  exception when others then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID', 'message', 'Correlation id is invalid.'
    )::text;
  end;
  if v_correlation is null then
    v_correlation := p_command_id;
  end if;

  select * into v_order from sales.sales_orders
  where id = p_sales_order_id and tenant_id = p_tenant_id
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found for receipt generation.'
    )::text;
  end if;

  perform sales._assert_sales_actor(
    p_tenant_id, p_actor_id, v_order.store_id, 'sales.receipt.generate'
  );

  if p_expected_source_version is not null and v_order.version <> p_expected_source_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION', 'message', 'Sales order version is stale.'
    )::text;
  end if;

  select * into v_settlement from receivable.sales_order_settlements
  where sales_order_id = p_sales_order_id and tenant_id = p_tenant_id
  order by version desc nulls last, id desc
  limit 1
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PROJECTION_PENDING', 'message', 'Settlement projection not ready.'
    )::text;
  end if;

  -- Return/exchange, extra collection and refund bump the settlement version
  -- but not the order version the client keys on; scoping the key to the
  -- settlement version makes each settlement state produce its own receipt
  -- while retries within one state still replay.
  v_idem_key := trim(p_idempotency_key) || ':s' || v_settlement.version;
  v_idem := sales._begin_sales_idempotency(
    p_tenant_id, 'generate_sales_receipt', v_idem_key, p_payload_hash);
  if v_idem ->> 'decision' = 'replay' then
    return coalesce(v_idem -> 'result_snapshot', '{}'::jsonb);
  end if;
  if v_idem ->> 'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IN_PROGRESS', 'message', 'Receipt generation is already in progress.'
    )::text;
  end if;

  perform 1
  from receivable.sales_payment_transactions transaction
  where transaction.tenant_id = p_tenant_id
    and transaction.sales_order_settlement_id = v_settlement.id
  order by transaction.id
  for update;

  perform 1
  from receivable.settlement_obligation_adjustments adjustment
  where adjustment.tenant_id = p_tenant_id
    and adjustment.sales_order_settlement_id = v_settlement.id
  order by adjustment.id
  for update;

  v_currency := v_settlement.currency_code;
  v_due_at := case
    when v_settlement.payment_due_date is null then null
    else to_char(v_settlement.payment_due_date, 'YYYY-MM-DD')
  end;

  -- One row per method: confirmed collections minus refunds (checkout +
  -- return/exchange), so a refund never prints as a payment.
  select coalesce(jsonb_agg(jsonb_build_object(
    'method', method_total.payment_method_code,
    'amount', jsonb_build_object(
      'amountMinor', method_total.net_minor,
      'currencyCode', v_currency
    ),
    'status', 'confirmed'
  ) order by method_total.first_at, method_total.payment_method_code), '[]'::jsonb)
  into v_payments
  from (
    select
      transaction.payment_method_code,
      sum(case
        when transaction.transaction_type = 'refund' then -transaction.amount_minor
        else transaction.amount_minor
      end) as net_minor,
      min(transaction.occurred_at) as first_at
    from receivable.sales_payment_transactions transaction
    where transaction.tenant_id = p_tenant_id
      and transaction.sales_order_settlement_id = v_settlement.id
      and transaction.status = 'confirmed'
    group by transaction.payment_method_code
  ) method_total
  where method_total.net_minor <> 0;

  v_receipt_lines := sales._sales_receipt_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code);
  select coalesce(sum(round(
    (line ->> 'quantityMicros')::numeric
      * (line -> 'unitPrice' ->> 'amountMinor')::bigint / 1000000
  )), 0)::bigint
  into v_receipt_subtotal_minor
  from jsonb_array_elements(v_receipt_lines) line;

  select coalesce(jsonb_agg(jsonb_build_object(
    'sourceKind', adjustment.source_kind,
    'sourceId', adjustment.source_id,
    'amount', jsonb_build_object(
      'amountMinor', adjustment.amount_minor,
      'currencyCode', v_currency
    )
  ) order by adjustment.created_at, adjustment.id), '[]'::jsonb)
  into v_adjustment_sources
  from receivable.settlement_obligation_adjustments adjustment
  where adjustment.tenant_id = p_tenant_id
    and adjustment.sales_order_settlement_id = v_settlement.id;

  v_snapshot := jsonb_build_object(
    'receiptNumber', 'PBH-' || to_char(v_order.created_at at time zone 'utc', 'YYYYMMDD')
      || '-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 8)),
    'orderNumber', coalesce(
      nullif(btrim(v_order.order_code), ''),
      'SO-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 12))
    ),
    'soldAt', to_char(v_order.completed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'store', coalesce(v_order.sales_context_snapshot -> 'store', '{}'::jsonb),
    'seller', coalesce(v_order.sales_context_snapshot -> 'seller', '{}'::jsonb),
    'customer', v_order.sales_context_snapshot -> 'customer',
    'lines', v_receipt_lines,
    'subtotal', jsonb_build_object(
      'amountMinor', v_receipt_subtotal_minor,
      'currencyCode', v_order.currency_code
    ),
    'discountTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.discount_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'taxTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.tax_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'roundingTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.rounding_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'orderTotal', jsonb_build_object(
      'amountMinor', v_settlement.current_payable_amount_minor,
      'currencyCode', v_currency
    ),
    'paidTotal', jsonb_build_object(
      'amountMinor', v_settlement.collected_amount_minor,
      'currencyCode', v_currency
    ),
    'outstandingTotal', jsonb_build_object(
      'amountMinor', v_settlement.outstanding_amount_minor,
      'currencyCode', v_currency
    ),
    'payments', v_payments,
    'dueAt', v_due_at,
    'settlementSnapshot', jsonb_build_object(
      'originalPayable', jsonb_build_object(
        'amountMinor', v_settlement.original_payable_amount_minor,
        'currencyCode', v_currency
      ),
      'adjustment', jsonb_build_object(
        'amountMinor', v_settlement.post_sale_adjustment_amount_minor,
        'currencyCode', v_currency
      ),
      'currentPayable', jsonb_build_object(
        'amountMinor', v_settlement.current_payable_amount_minor,
        'currencyCode', v_currency
      ),
      'collected', jsonb_build_object(
        'amountMinor', v_settlement.collected_amount_minor,
        'currencyCode', v_currency
      ),
      'refunded', jsonb_build_object(
        'amountMinor', v_settlement.refunded_amount_minor,
        'currencyCode', v_currency
      ),
      'netCollected', jsonb_build_object(
        'amountMinor', v_settlement.net_collected_amount_minor,
        'currencyCode', v_currency
      ),
      'outstanding', jsonb_build_object(
        'amountMinor', v_settlement.outstanding_amount_minor,
        'currencyCode', v_currency
      ),
      'adjustmentSources', v_adjustment_sources
    )
  );

  perform 1
  from sales.sales_receipts
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
  order by receipt_version, id
  for update;

  select coalesce(max(receipt_version), 0) + 1 into v_next_version
  from sales.sales_receipts
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id;

  insert into sales.sales_receipts (
    id, tenant_id, sales_order_id, receipt_version, status,
    content_hash, receipt_snapshot, generated_at
  ) values (
    v_receipt_id, p_tenant_id, p_sales_order_id, v_next_version, 'generated',
    md5(v_snapshot::text), v_snapshot, now()
  ) returning * into v_receipt;

  update sales.sales_receipts
  set status = 'superseded'
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
    and status = 'generated'
    and id is distinct from v_receipt.id;

  v_result := sales._sales_receipt_envelope(v_receipt);
  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'generate_sales_receipt',
    v_idem_key,
    'succeeded',
    v_result);
  return v_result;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.get_sales_order_detail(query_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_current_receipt_id uuid;
begin
  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(tenant_id, 'sales.order.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders o
  where o.id = get_sales_order_detail.sales_order_id
    and o.tenant_id = get_sales_order_detail.tenant_id;

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

  if not iam.can_access_store(get_sales_order_detail.tenant_id, v_order.store_id, get_sales_order_detail.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  -- A receipt older than the latest settlement change (return/exchange,
  -- extra collection, refund) is a stale snapshot: return null so the app
  -- generates a fresh receipt instead of re-reading the old one.
  select r.id
  into v_current_receipt_id
  from sales.sales_receipts r
  where r.tenant_id = v_order.tenant_id
    and r.sales_order_id = v_order.id
    and r.status = 'generated'
    and not exists (
      select 1
      from receivable.sales_order_settlements s
      where s.tenant_id = r.tenant_id
        and s.sales_order_id = r.sales_order_id
        and s.updated_at > r.generated_at
    )
  order by r.receipt_version desc, r.generated_at desc, r.id desc
  limit 1;

  return jsonb_build_object(
    'order', jsonb_build_object(
      'salesOrderId', v_order.id,
      'orderNumber', coalesce(
        nullif(btrim(v_order.order_code), ''),
        'SO-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 12))
      ),
      'version', v_order.version,
      'lifecycleStatus', v_order.lifecycle_status,
      'lockStatus', 'unlocked',
      'total', jsonb_build_object(
        'amountMinor', v_order.payable_amount_minor,
        'currencyCode', v_order.currency_code
      )
    ),
    'committedAt', to_char(v_order.completed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'store', v_order.sales_context_snapshot -> 'store',
    'seller', v_order.sales_context_snapshot -> 'seller',
    'customer', v_order.sales_context_snapshot -> 'customer',
    'orderNote', v_order.internal_note,
    'currentReceiptId', v_current_receipt_id,
    'lines', sales._sales_order_lines_payload(v_order.tenant_id, v_order.id, v_order.currency_code),
    'currentLines', coalesce((
      select jsonb_agg(unit.obj order by unit.sort_seq, unit.sort_id)
      from (
        -- Source 1: original order lines still held (sold − returned).
        select jsonb_build_object(
          'product', jsonb_build_object(
            'productId', l.product_id,
            'sku', nullif(btrim(l.product_snapshot ->> 'sku'), ''),
            'displayName', coalesce(nullif(btrim(l.product_snapshot ->> 'displayName'), ''), l.product_id::text)
          ),
          'unit', jsonb_build_object(
            'productUnitId', l.product_unit_id,
            'unitCode', nullif(btrim(l.product_unit_snapshot ->> 'unitCode'), ''),
            'unitName', coalesce(nullif(btrim(l.product_unit_snapshot ->> 'unitName'), ''), l.product_unit_id::text)
          ),
          'heldQuantity', jsonb_build_object('quantityMicros', greatest(
            l.quantity_micros - coalesce((
              select sum(rl.quantity_micros)
              from sales.return_exchange_lines rl
              join sales.return_exchange_orders r on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
              where r.tenant_id = get_sales_order_detail.tenant_id
                and r.sales_order_id = v_order.id
                and r.status in ('confirmed','processing','completed')
                and rl.line_role = 'returned'
                and rl.original_sales_order_line_id = l.id
            ), 0), 0)),
          'unitPrice', jsonb_build_object('amountMinor', round(l.line_total_minor::numeric * 1000000 / l.quantity_micros)::bigint, 'currencyCode', v_order.currency_code),
          'originalUnitPrice', case when l.discount_amount_minor > 0
            then jsonb_build_object('amountMinor', l.unit_price_minor, 'currencyCode', v_order.currency_code)
          end,
          'source', 'original'
        ) as obj,
        l.line_sequence as sort_seq, l.id as sort_id,
        greatest(l.quantity_micros - coalesce((
          select sum(rl.quantity_micros) from sales.return_exchange_lines rl
          join sales.return_exchange_orders r on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
          where r.tenant_id = get_sales_order_detail.tenant_id and r.sales_order_id = v_order.id
            and r.status in ('confirmed','processing','completed') and rl.line_role = 'returned'
            and rl.original_sales_order_line_id = l.id), 0), 0) as held_micros
        from sales.sales_order_lines l
        where l.tenant_id = get_sales_order_detail.tenant_id and l.sales_order_id = v_order.id

        union all
        -- Source 2 (ADR-9): confirmed exchanged-in goods still held.
        select jsonb_build_object(
          'product', jsonb_build_object(
            'productId', xl.product_id,
            'sku', nullif(btrim(xl.product_snapshot ->> 'sku'), ''),
            'displayName', coalesce(nullif(btrim(xl.product_snapshot ->> 'displayName'), ''), xl.product_id::text)
          ),
          'unit', jsonb_build_object(
            'productUnitId', xl.product_unit_id,
            'unitCode', nullif(btrim(xl.product_unit_snapshot ->> 'unitCode'), ''),
            'unitName', coalesce(nullif(btrim(xl.product_unit_snapshot ->> 'unitName'), ''), xl.product_unit_id::text)
          ),
          'heldQuantity', jsonb_build_object('quantityMicros', greatest(
            xl.quantity_micros - coalesce((
              select sum(rl.quantity_micros)
              from sales.return_exchange_lines rl
              join sales.return_exchange_orders r on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
              where r.tenant_id = get_sales_order_detail.tenant_id
                and r.sales_order_id = v_order.id
                and r.status in ('confirmed','processing','completed')
                and rl.line_role = 'returned'
                and rl.source_exchange_line_id = xl.id
            ), 0), 0)),
          'unitPrice', jsonb_build_object('amountMinor', xl.unit_value_minor, 'currencyCode', v_order.currency_code),
          'source', 'exchange'
        ) as obj,
        1000000 + xl.line_sequence as sort_seq, xl.id as sort_id,
        greatest(xl.quantity_micros - coalesce((
          select sum(rl.quantity_micros) from sales.return_exchange_lines rl
          join sales.return_exchange_orders r on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
          where r.tenant_id = get_sales_order_detail.tenant_id and r.sales_order_id = v_order.id
            and r.status in ('confirmed','processing','completed') and rl.line_role = 'returned'
            and rl.source_exchange_line_id = xl.id), 0), 0) as held_micros
        from sales.return_exchange_lines xl
        join sales.return_exchange_orders xr on xr.id = xl.return_exchange_order_id and xr.tenant_id = xl.tenant_id
        where xl.tenant_id = get_sales_order_detail.tenant_id and xr.sales_order_id = v_order.id
          and xl.line_role = 'exchange' and xr.status in ('confirmed','processing','completed')
      ) unit
      where unit.held_micros > 0
    ), '[]'::jsonb)
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.get_sales_order_original_receipt(p_query_id uuid, p_tenant_id uuid, p_actor_id uuid, p_sales_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_payments jsonb;
  v_paid_minor bigint;
  v_due_date date;
begin
  if auth.uid() is distinct from p_actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(p_tenant_id, 'sales.receipt.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order from sales.sales_orders
  where id = p_sales_order_id and tenant_id = p_tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.'
    )::text;
  end if;
  if not iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  perform sales._assert_sales_actor(
    p_tenant_id, p_actor_id, v_order.store_id, 'sales.receipt.view'
  );

  select s.payment_due_date into v_due_date
  from receivable.sales_order_settlements s
  where s.sales_order_id = v_order.id and s.tenant_id = v_order.tenant_id;

  -- Checkout collections only: later collections/refunds belong to the
  -- after-return/exchange receipt.
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'method', method_total.payment_method_code,
      'amount', jsonb_build_object(
        'amountMinor', method_total.paid_minor,
        'currencyCode', v_order.currency_code
      ),
      'status', 'confirmed'
    ) order by method_total.first_at, method_total.payment_method_code), '[]'::jsonb),
    coalesce(sum(method_total.paid_minor), 0)::bigint
  into v_payments, v_paid_minor
  from (
    select
      transaction.payment_method_code,
      sum(transaction.amount_minor) as paid_minor,
      min(transaction.occurred_at) as first_at
    from receivable.sales_payment_transactions transaction
    join receivable.sales_order_settlements settlement
      on settlement.id = transaction.sales_order_settlement_id
     and settlement.tenant_id = transaction.tenant_id
    where transaction.tenant_id = p_tenant_id
      and settlement.sales_order_id = p_sales_order_id
      and transaction.status = 'confirmed'
      and transaction.source_context = 'checkout'
      and transaction.transaction_type = 'collection'
    group by transaction.payment_method_code
  ) method_total;

  return jsonb_build_object(
    'receiptNumber', 'PBH-' || to_char(v_order.created_at at time zone 'utc', 'YYYYMMDD')
      || '-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 8)),
    'orderNumber', coalesce(
      nullif(btrim(v_order.order_code), ''),
      'SO-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 12))
    ),
    'soldAt', to_char(v_order.completed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'store', coalesce(v_order.sales_context_snapshot -> 'store', '{}'::jsonb),
    'seller', coalesce(v_order.sales_context_snapshot -> 'seller', '{}'::jsonb),
    'customer', v_order.sales_context_snapshot -> 'customer',
    'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),
    'subtotal', jsonb_build_object(
      'amountMinor', v_order.subtotal_amount_minor,
      'currencyCode', v_order.currency_code
    ),
    'discountTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.discount_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'taxTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.tax_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'roundingTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.rounding_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'orderTotal', jsonb_build_object(
      'amountMinor', v_order.payable_amount_minor,
      'currencyCode', v_order.currency_code
    ),
    'paidTotal', jsonb_build_object(
      'amountMinor', v_paid_minor,
      'currencyCode', v_order.currency_code
    ),
    'outstandingTotal', jsonb_build_object(
      'amountMinor', greatest(v_order.payable_amount_minor - v_paid_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'payments', v_payments,
    'dueAt', case
      when v_due_date is null then null
      else to_char(v_due_date, 'YYYY-MM-DD')
    end
  );
end;
$function$
;

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
        t.reason
      from receivable.sales_payment_transactions t
      join receivable.sales_order_settlements s
        on s.id = t.sales_order_settlement_id
       and s.tenant_id = t.tenant_id
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
              'reason', p.reason
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

CREATE OR REPLACE FUNCTION sales.get_sales_order_settlement(query_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_refunded_minor bigint;
  v_voided_minor bigint;
  v_net_collected_minor bigint;
  v_outstanding_minor bigint;
  v_due_at text;
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
  where o.id = get_sales_order_settlement.sales_order_id
    and o.tenant_id = get_sales_order_settlement.tenant_id;

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

  if not iam.can_access_store(get_sales_order_settlement.tenant_id, v_order.store_id, get_sales_order_settlement.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements s
  where s.sales_order_id = get_sales_order_settlement.sales_order_id
    and s.tenant_id = get_sales_order_settlement.tenant_id
  order by s.version desc nulls last, s.id desc
  limit 1;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PROJECTION_PENDING', 'message', 'Settlement projection not ready.',
      'details', jsonb_build_object('salesOrderId', sales_order_id)
    )::text;
  end if;

  v_refunded_minor := coalesce(v_settlement.refunded_amount_minor, 0);
  v_voided_minor := 0;
  v_net_collected_minor := coalesce(v_settlement.net_collected_amount_minor, 0);
  v_outstanding_minor := coalesce(v_settlement.outstanding_amount_minor, 0);

  -- Model B handoff deferred: no receivable impact request to read a due date from.
  v_due_at := null;

  return jsonb_build_object(
    'settlementId', v_settlement.id,
    'salesOrderId', v_settlement.sales_order_id,
    'version', coalesce(v_settlement.version::integer, 1),
    'status', case v_settlement.payment_status
      when 'partially_paid' then 'partiallyPaid'
      when 'partially_refunded' then 'partiallyRefunded'
      else v_settlement.payment_status
    end,
    'orderTotal', jsonb_build_object(
      'amountMinor', v_settlement.current_payable_amount_minor,
      'currencyCode', v_settlement.currency_code
    ),
    'paidTotal', jsonb_build_object(
      'amountMinor', v_settlement.collected_amount_minor,
      'currencyCode', v_settlement.currency_code
    ),
    'refundedTotal', jsonb_build_object(
      'amountMinor', v_refunded_minor,
      'currencyCode', v_settlement.currency_code
    ),
    'outstanding', jsonb_build_object(
      'amountMinor', v_outstanding_minor,
      'currencyCode', v_settlement.currency_code
    ),
    'dueAt', v_due_at
  );
end;
$function$
;

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
          'description', o.payload ->> 'description',
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

CREATE OR REPLACE FUNCTION sales.list_sales_orders(query_id text, tenant_id uuid, actor_id uuid, cursor text DEFAULT NULL::text, page_size integer DEFAULT 25, completed_from timestamp with time zone DEFAULT NULL::timestamp with time zone, completed_to timestamp with time zone DEFAULT NULL::timestamp with time zone, store_id uuid DEFAULT NULL::uuid, seller_id text DEFAULT NULL::text, customer_id text DEFAULT NULL::text, lifecycle_status text DEFAULT NULL::text, lock_status text DEFAULT NULL::text, settlement_status text DEFAULT NULL::text, has_return_exchange boolean DEFAULT NULL::boolean, e_invoice_status text DEFAULT NULL::text, has_outstanding_receivable boolean DEFAULT NULL::boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_cursor_at timestamptz;
  v_cursor_id uuid;
  v_limit integer;
begin
  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(tenant_id, 'sales.order.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  if cursor is not null and position('|' in cursor) > 0 then
    v_cursor_at := nullif(split_part(cursor, '|', 1), '')::timestamptz;
    v_cursor_id := nullif(split_part(cursor, '|', 2), '')::uuid;
  end if;

  v_limit := least(greatest(page_size, 1), 100);

  return (
    with filtered as (
      select
        o.id,
        o.completed_at as created_at,
        o.version as source_version,
        coalesce(
          nullif(btrim(o.order_code), ''),
          'SO-' || upper(substr(replace(o.id::text, '-', ''), 1, 12))
        ) as order_number,
        o.lifecycle_status,
        o.lock_status,
        o.sales_context_snapshot,
        o.payable_amount_minor,
        o.currency_code,
        case coalesce(s.payment_status, 'unpaid')
          when 'partially_paid' then 'partiallyPaid'
          when 'partially_refunded' then 'partiallyRefunded'
          when 'no_balance' then 'no_balance'
          else coalesce(s.payment_status, 'unpaid')
        end as settlement_status,
        case coalesce(p.return_status, 'none')
          when 'partially_returned' then 'partiallyReturned'
          when 'fully_returned' then 'fullyReturned'
          else 'none'
        end as return_status,
        case
          when exists (
            select 1
            from einvoice.electronic_invoices ei
            where ei.tenant_id = o.tenant_id
              and ei.sales_order_id = o.id
          ) then 'delivered'
          else 'notRequired'
        end as e_invoice_status,
        coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) as outstanding_minor
      from sales.sales_orders o
      left join lateral (
        select payment_status, outstanding_amount_minor
        from receivable.sales_order_settlements
        where sales_order_settlements.tenant_id = o.tenant_id
          and sales_order_settlements.sales_order_id = o.id
        order by sales_order_settlements.version desc nulls last, sales_order_settlements.id desc
        limit 1
      ) s on true
      left join sales.sales_order_return_status_projections p
        on p.tenant_id = o.tenant_id
       and p.sales_order_id = o.id
      where o.tenant_id = list_sales_orders.tenant_id
        and o.lifecycle_status in ('completed', 'cancelled')
        and iam.can_access_store(list_sales_orders.tenant_id, o.store_id, list_sales_orders.actor_id)
        and (
          list_sales_orders.store_id is null
          or o.store_id = list_sales_orders.store_id
        )
        and (
          list_sales_orders.completed_from is null
          or o.completed_at >= list_sales_orders.completed_from
        )
        and (
          list_sales_orders.completed_to is null
          or o.completed_at <= list_sales_orders.completed_to
        )
        and (
          list_sales_orders.seller_id is null
          or o.sales_context_snapshot -> 'seller' ->> 'actorId' = list_sales_orders.seller_id
          or o.seller_user_id::text = list_sales_orders.seller_id
        )
        and (
          list_sales_orders.customer_id is null
          or o.sales_context_snapshot -> 'customer' ->> 'customerId' =
            list_sales_orders.customer_id
        )
        and (
          list_sales_orders.lifecycle_status is null
          or o.lifecycle_status = list_sales_orders.lifecycle_status
        )
        and (
          list_sales_orders.lock_status is null
          or o.lock_status = list_sales_orders.lock_status
        )
        and (
          list_sales_orders.settlement_status is null
          or (
            case coalesce(s.payment_status, 'unpaid')
              when 'partially_paid' then 'partiallyPaid'
              when 'partially_refunded' then 'partiallyRefunded'
              when 'no_balance' then 'no_balance'
              else coalesce(s.payment_status, 'unpaid')
            end
          ) = list_sales_orders.settlement_status
          or (
            list_sales_orders.settlement_status = 'noBalance'
            and coalesce(s.payment_status, 'unpaid') = 'no_balance'
          )
        )
        and (
          list_sales_orders.has_outstanding_receivable is null
          or (
            list_sales_orders.has_outstanding_receivable
            and coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) > 0
          )
          or (
            not list_sales_orders.has_outstanding_receivable
            and coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) = 0
          )
        )
        and (
          list_sales_orders.has_return_exchange is null
          or (
            coalesce(p.return_status, 'none') in ('partially_returned', 'fully_returned')
          ) = list_sales_orders.has_return_exchange
        )
        and (
          list_sales_orders.e_invoice_status is null
          or (
            list_sales_orders.e_invoice_status = 'delivered'
            and exists (
              select 1
              from einvoice.electronic_invoices ei
              where ei.tenant_id = o.tenant_id
                and ei.sales_order_id = o.id
            )
          )
          or (
            list_sales_orders.e_invoice_status = 'queued'
            and not exists (
              select 1
              from einvoice.electronic_invoices ei
              where ei.tenant_id = o.tenant_id
                and ei.sales_order_id = o.id
            )
          )
        )
    ),
    page as (
      select *
      from filtered
      where (
        v_cursor_at is null
        or (created_at, id) < (v_cursor_at, v_cursor_id)
      )
      order by created_at desc, id desc
      limit v_limit + 1
    ),
    visible as (
      select *
      from page
      order by created_at desc, id desc
      limit v_limit
    )
    select jsonb_build_object(
      'items',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'salesOrderId', v.id,
              'orderNumber', v.order_number,
              'sourceVersion', v.source_version,
              'committedAt', to_char(v.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
              'customer', v.sales_context_snapshot -> 'customer',
              'store', v.sales_context_snapshot -> 'store',
              'total', jsonb_build_object('amountMinor', v.payable_amount_minor, 'currencyCode', v.currency_code),
              'lifecycleStatus', v.lifecycle_status,
              'lockStatus', v.lock_status,
              'settlementStatus', v.settlement_status,
              'returnStatus', v.return_status,
              'eInvoiceStatus', v.e_invoice_status
            )
            order by v.created_at desc, v.id desc
          )
          from visible v
        ),
        '[]'::jsonb
      ),
      'hasMore', (select count(*) > v_limit from page),
      'nextCursor',
      (
        select case
          when (select count(*) from page) > v_limit then
            concat(
              to_char(
                (select created_at from visible order by created_at asc, id asc limit 1)
                  at time zone 'utc',
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
              ),
              '|',
              (select id::text from visible order by created_at asc, id asc limit 1)
            )
          else null
        end
      ),
      'totalMatching', (select count(*) from filtered),
      'facets', jsonb_build_object(
        'all', (select count(*) from filtered),
        'outstandingReceivable', (select count(*) filter (where outstanding_minor > 0) from filtered),
        'eInvoicePending', (select count(*) filter (where filtered.e_invoice_status = 'notRequired') from filtered)
      )
    )
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.precheck_sales_order_cancellation(query_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, expected_source_version integer DEFAULT NULL::integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_net_confirmed_collection_minor bigint;
  v_blockers jsonb := '[]'::jsonb;
begin
  if auth.uid() is distinct from actor_id
    or iam.has_permission(tenant_id, 'sales.order.cancel') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = precheck_sales_order_cancellation.sales_order_id
    and sales_orders.tenant_id = precheck_sales_order_cancellation.tenant_id;
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

  if not iam.can_access_store(precheck_sales_order_cancellation.tenant_id, v_order.store_id, precheck_sales_order_cancellation.actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = precheck_sales_order_cancellation.tenant_id
  order by sales_order_settlements.version desc, sales_order_settlements.id desc
  limit 1;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'DEPENDENCY_UNAVAILABLE',
      'message', 'Authoritative settlement is unavailable.'
    )::text;
  end if;

  v_net_confirmed_collection_minor := coalesce(v_settlement.net_collected_amount_minor, 0);

  if v_order.lifecycle_status = 'cancelled' then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'ORDER_ALREADY_CANCELLED',
      'message', 'Sales order is already cancelled.',
      'field', 'lifecycleStatus'
    ));
  elsif v_order.lifecycle_status is distinct from 'completed' then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'CANCELLATION_BLOCKED',
      'message', 'Only completed sales orders may be cancelled.',
      'field', 'lifecycleStatus'
    ));
  end if;

  if v_net_confirmed_collection_minor <> 0 then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'PAYMENT_ALREADY_COLLECTED',
      'message', 'Net confirmed collection must be zero for EP-05 cancellation.',
      'field', 'settlement'
    ));
  end if;

  if exists (
    select 1 from sales.sales_order_cancellations c
    where c.tenant_id = precheck_sales_order_cancellation.tenant_id
      and c.sales_order_id = precheck_sales_order_cancellation.sales_order_id
      and c.status in ('requested', 'validating', 'confirmed', 'processing', 'completed')
  ) then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'COMPETING_CANCELLATION',
      'message', 'A competing sales order cancellation is already in progress or committed.'
    ));
  end if;

  if exists (
    select 1 from sales.return_exchange_orders r
    where r.tenant_id = precheck_sales_order_cancellation.tenant_id
      and r.sales_order_id = precheck_sales_order_cancellation.sales_order_id
      and r.status in ('confirmed', 'processing', 'completed')
  ) then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'RETURN_EXCHANGE_CONFLICT',
      'message', 'A confirmed, processing, or completed return/exchange blocks cancellation.'
    ));
  end if;

  if exists (
    select 1 from sales.return_exchange_orders r
    where r.tenant_id = precheck_sales_order_cancellation.tenant_id
      and r.sales_order_id = precheck_sales_order_cancellation.sales_order_id
      and r.status = 'draft'
  ) then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'DRAFT_RETURN_ACTIVE',
      'message', 'Resolve or discard the draft return/exchange before cancelling.'
    ));
  end if;

  return jsonb_build_object(
    'allowed', jsonb_array_length(v_blockers) = 0,
    'sourceVersion', v_order.version,
    'sourceSettlementVersion', v_settlement.version,
    'blockers', v_blockers
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.record_sales_payment(p_tenant_id uuid, p_actor_id uuid, p_store_id uuid, p_sales_order_id uuid, p_amount_minor bigint, p_payment_method_code text, p_idempotency_key text, p_payload_hash text, p_source_context text DEFAULT 'additional_collection'::text, p_payment_method_snapshot jsonb DEFAULT NULL::jsonb, p_external_reference text DEFAULT NULL::text, p_correlation_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_decision jsonb;
  v_settlement_id uuid;
  v_currency text;
  v_outstanding bigint;
  v_order_store uuid;
  v_order_status text;
  v_tx_id uuid := gen_random_uuid();
  v_result jsonb;
  v_correlation uuid := coalesce(p_correlation_id, gen_random_uuid());
begin
  perform sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.payment.record');

  if coalesce(p_amount_minor, 0) <= 0
     or nullif(trim(coalesce(p_payment_method_code, '')), '') is null
     or nullif(trim(coalesce(p_idempotency_key, '')), '') is null
     or nullif(trim(coalesce(p_payload_hash, '')), '') is null then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Payment context is invalid.'
    )::text;
  end if;

  select store_id, lifecycle_status into v_order_store, v_order_status
  from sales.sales_orders
  where tenant_id = p_tenant_id and id = p_sales_order_id
  for update;
  if not found or v_order_store is distinct from p_store_id then
    raise exception using message = jsonb_build_object(
      'code', 'REFERENCE_UNAVAILABLE',
      'message', 'Sales order was not found in store scope.'
    )::text;
  end if;

  v_decision := sales._begin_sales_idempotency(
    p_tenant_id,
    'record_sales_payment',
    trim(p_idempotency_key),
    trim(p_payload_hash));
  if v_decision->>'decision' = 'replay' then
    return v_decision->'result_snapshot';
  end if;
  if v_decision->>'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Idempotency key is already in progress.'
    )::text;
  end if;

  -- Replay returns above; only a new collection is forbidden after cancellation.
  -- The order lock serializes this check with confirm_sales_order_cancellation.
  if v_order_status = 'cancelled' then
    raise exception using message = jsonb_build_object(
      'code', 'ORDER_CANCELLED',
      'message', 'Cannot record a new collection on a cancelled sales order.'
    )::text;
  end if;

  v_settlement_id := sales._settlement_id_for_order(p_tenant_id, p_sales_order_id);
  select currency_code, outstanding_amount_minor
  into v_currency, v_outstanding
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and id = v_settlement_id
  for update;

  if p_amount_minor > v_outstanding then
    raise exception using message = jsonb_build_object(
      'code', 'OVERPAYMENT_NOT_ALLOWED',
      'message', 'Payment exceeds outstanding payable.'
    )::text;
  end if;

  insert into receivable.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, payment_method_snapshot, status,
    source_context, source_type, source_id, initiated_by_user_id,
    external_reference, occurred_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'collection', 'inflow', p_amount_minor, v_currency, trim(p_payment_method_code),
    p_payment_method_snapshot, 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'additional_collection'),
    'sales_order', p_sales_order_id, p_actor_id,
    nullif(trim(coalesce(p_external_reference, '')), ''),
    now()
  );

  perform sales._recompute_sales_settlement(p_tenant_id, v_settlement_id);
  v_result := sales._settlement_mutation_snapshot(p_tenant_id, v_settlement_id, v_tx_id);

  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(), p_tenant_id, 'sales_payment_recorded.v1',
    jsonb_build_object(
      'salesOrderId', p_sales_order_id::text,
      'settlementId', v_settlement_id::text,
      'transactionId', v_tx_id::text,
      'amountMinor', p_amount_minor,
      'correlationId', v_correlation::text
    )
  );

  -- sales_payment_recorded.v1 is a transaction fact, not a second money ledger.
  perform sales._emit_sales_settlement_changed(
    p_tenant_id,
    v_settlement_id,
    'payment',
    v_tx_id::text,
    'record_sales_payment'
  );

  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'record_sales_payment',
    trim(p_idempotency_key),
    'succeeded',
    v_result);

  return v_result;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.record_sales_refund(p_tenant_id uuid, p_actor_id uuid, p_store_id uuid, p_sales_order_id uuid, p_amount_minor bigint, p_payment_method_code text, p_reason_code text, p_idempotency_key text, p_payload_hash text, p_related_transaction_id uuid DEFAULT NULL::uuid, p_source_context text DEFAULT 'manual_correction'::text, p_reason text DEFAULT NULL::text, p_correlation_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_decision jsonb;
  v_settlement_id uuid;
  v_currency text;
  v_net bigint;
  v_order_store uuid;
  v_related receivable.sales_payment_transactions%rowtype;
  v_related_refunded bigint;
  v_tx_id uuid := gen_random_uuid();
  v_result jsonb;
  v_correlation uuid := coalesce(p_correlation_id, gen_random_uuid());
begin
  perform sales._assert_sales_actor(p_tenant_id, p_actor_id, p_store_id, 'sales.payment.refund');

  if coalesce(p_amount_minor, 0) <= 0
     or nullif(trim(coalesce(p_payment_method_code, '')), '') is null
     or nullif(trim(coalesce(p_reason_code, '')), '') is null
     or nullif(trim(coalesce(p_idempotency_key, '')), '') is null
     or nullif(trim(coalesce(p_payload_hash, '')), '') is null then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Refund context is invalid.'
    )::text;
  end if;

  select store_id into v_order_store
  from sales.sales_orders
  where tenant_id = p_tenant_id and id = p_sales_order_id
  for update;
  if not found or v_order_store is distinct from p_store_id then
    raise exception using message = jsonb_build_object(
      'code', 'REFERENCE_UNAVAILABLE',
      'message', 'Sales order was not found in store scope.'
    )::text;
  end if;

  v_decision := sales._begin_sales_idempotency(
    p_tenant_id,
    'record_sales_refund',
    trim(p_idempotency_key),
    trim(p_payload_hash));
  if v_decision->>'decision' = 'replay' then
    return v_decision->'result_snapshot';
  end if;
  if v_decision->>'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Idempotency key is already in progress.'
    )::text;
  end if;

  v_settlement_id := sales._settlement_id_for_order(p_tenant_id, p_sales_order_id);
  select currency_code, net_collected_amount_minor
  into v_currency, v_net
  from receivable.sales_order_settlements
  where tenant_id = p_tenant_id and id = v_settlement_id
  for update;

  if p_related_transaction_id is not null then
    select * into v_related
    from receivable.sales_payment_transactions
    where tenant_id = p_tenant_id
      and id = p_related_transaction_id
      and sales_order_settlement_id = v_settlement_id
    for update;
    if not found then
      raise exception using message = jsonb_build_object(
        'code', 'REFERENCE_UNAVAILABLE',
        'message', 'Related payment transaction was not found on this settlement.'
      )::text;
    end if;
    if v_related.status <> 'confirmed'
       or v_related.direction <> 'inflow'
       or v_related.transaction_type <> 'collection' then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Related transaction is not a refundable collection.'
      )::text;
    end if;

    select coalesce(sum(refund.amount_minor), 0)
    into v_related_refunded
    from receivable.sales_payment_transactions refund
    where refund.tenant_id = p_tenant_id
      and refund.sales_order_settlement_id = v_settlement_id
      and refund.related_transaction_id = v_related.id
      and refund.transaction_type = 'refund'
      and refund.direction = 'outflow'
      and refund.status = 'confirmed';

    if p_amount_minor > v_related.amount_minor - v_related_refunded then
      raise exception using message = jsonb_build_object(
        'code', 'REFUND_EXCEEDS_COLLECTED',
        'message', 'Refund exceeds the remaining amount of the related collection.'
      )::text;
    end if;
  end if;

  if p_amount_minor > v_net then
    raise exception using message = jsonb_build_object(
      'code', 'REFUND_EXCEEDS_COLLECTED',
      'message', 'Refund exceeds net collected amount.'
    )::text;
  end if;

  insert into receivable.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, status, source_context, source_type,
    source_id, related_transaction_id, initiated_by_user_id,
    reason_code, reason, occurred_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'refund', 'outflow', p_amount_minor, v_currency, trim(p_payment_method_code), 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'manual_correction'),
    'sales_order', p_sales_order_id, p_related_transaction_id, p_actor_id,
    trim(p_reason_code), nullif(trim(coalesce(p_reason, '')), ''),
    now()
  );

  perform sales._recompute_sales_settlement(p_tenant_id, v_settlement_id);
  v_result := sales._settlement_mutation_snapshot(p_tenant_id, v_settlement_id, v_tx_id);

  insert into sales.outbox_messages(id, tenant_id, event_type, payload)
  values (
    gen_random_uuid(), p_tenant_id, 'sales_refund_recorded.v1',
    jsonb_build_object(
      'salesOrderId', p_sales_order_id::text,
      'settlementId', v_settlement_id::text,
      'transactionId', v_tx_id::text,
      'amountMinor', p_amount_minor,
      'correlationId', v_correlation::text
    )
  );

  -- sales_refund_recorded.v1 is a transaction fact, not a second money ledger.
  perform sales._emit_sales_settlement_changed(
    p_tenant_id,
    v_settlement_id,
    'refund',
    v_tx_id::text,
    'record_sales_refund'
  );

  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'record_sales_refund',
    trim(p_idempotency_key),
    'succeeded',
    v_result);

  return v_result;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.search_sales_orders(query_id text, tenant_id uuid, actor_id uuid, search_text text, cursor text DEFAULT NULL::text, page_size integer DEFAULT 25, completed_from timestamp with time zone DEFAULT NULL::timestamp with time zone, completed_to timestamp with time zone DEFAULT NULL::timestamp with time zone, store_id uuid DEFAULT NULL::uuid, seller_id text DEFAULT NULL::text, customer_id text DEFAULT NULL::text, lifecycle_status text DEFAULT NULL::text, lock_status text DEFAULT NULL::text, settlement_status text DEFAULT NULL::text, has_return_exchange boolean DEFAULT NULL::boolean, e_invoice_status text DEFAULT NULL::text, has_outstanding_receivable boolean DEFAULT NULL::boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
declare
  v_cursor_at timestamptz;
  v_cursor_id uuid;
  v_limit integer;
  v_search text;
begin
  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(tenant_id, 'sales.order.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  if cursor is not null and position('|' in cursor) > 0 then
    v_cursor_at := nullif(split_part(cursor, '|', 1), '')::timestamptz;
    v_cursor_id := nullif(split_part(cursor, '|', 2), '')::uuid;
  end if;

  v_limit := least(greatest(page_size, 1), 100);
  v_search := nullif(btrim(catalog.unaccent_immutable(coalesce(search_text, ''))), '');

  return (
    with filtered as (
      select
        o.id,
        o.completed_at as created_at,
        o.version as source_version,
        coalesce(
          nullif(btrim(o.order_code), ''),
          'SO-' || upper(substr(replace(o.id::text, '-', ''), 1, 12))
        ) as order_number,
        o.lifecycle_status,
        o.lock_status,
        o.sales_context_snapshot,
        o.payable_amount_minor,
        o.currency_code,
        case coalesce(s.payment_status, 'unpaid')
          when 'partially_paid' then 'partiallyPaid'
          when 'partially_refunded' then 'partiallyRefunded'
          when 'no_balance' then 'no_balance'
          else coalesce(s.payment_status, 'unpaid')
        end as settlement_status,
        case coalesce(p.return_status, 'none')
          when 'partially_returned' then 'partiallyReturned'
          when 'fully_returned' then 'fullyReturned'
          else 'none'
        end as return_status,
        case
          when exists (
            select 1
            from einvoice.electronic_invoices ei
            where ei.tenant_id = o.tenant_id
              and ei.sales_order_id = o.id
          ) then 'delivered'
          else 'notRequired'
        end as e_invoice_status,
        coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) as outstanding_minor
      from sales.sales_orders o
      left join lateral (
        select payment_status, outstanding_amount_minor
        from receivable.sales_order_settlements
        where sales_order_settlements.tenant_id = o.tenant_id
          and sales_order_settlements.sales_order_id = o.id
        order by sales_order_settlements.version desc nulls last, sales_order_settlements.id desc
        limit 1
      ) s on true
      left join sales.sales_order_return_status_projections p
        on p.tenant_id = o.tenant_id
       and p.sales_order_id = o.id
      where o.tenant_id = search_sales_orders.tenant_id
        and o.lifecycle_status in ('completed', 'cancelled')
        and iam.can_access_store(search_sales_orders.tenant_id, o.store_id, search_sales_orders.actor_id)
        and (
          search_sales_orders.store_id is null
          or o.store_id = search_sales_orders.store_id
        )
        and (
          search_sales_orders.completed_from is null
          or o.completed_at >= search_sales_orders.completed_from
        )
        and (
          search_sales_orders.completed_to is null
          or o.completed_at <= search_sales_orders.completed_to
        )
        and (
          search_sales_orders.seller_id is null
          or o.sales_context_snapshot -> 'seller' ->> 'actorId' = search_sales_orders.seller_id
          or o.seller_user_id::text = search_sales_orders.seller_id
        )
        and (
          search_sales_orders.customer_id is null
          or o.sales_context_snapshot -> 'customer' ->> 'customerId' =
            search_sales_orders.customer_id
        )
        and (
          search_sales_orders.lifecycle_status is null
          or o.lifecycle_status = search_sales_orders.lifecycle_status
        )
        and (
          search_sales_orders.lock_status is null
          or o.lock_status = search_sales_orders.lock_status
        )
        and (
          search_sales_orders.settlement_status is null
          or (
            case coalesce(s.payment_status, 'unpaid')
              when 'partially_paid' then 'partiallyPaid'
              when 'partially_refunded' then 'partiallyRefunded'
              when 'no_balance' then 'no_balance'
              else coalesce(s.payment_status, 'unpaid')
            end
          ) = search_sales_orders.settlement_status
          or (
            search_sales_orders.settlement_status = 'noBalance'
            and coalesce(s.payment_status, 'unpaid') = 'no_balance'
          )
        )
        and (
          search_sales_orders.has_outstanding_receivable is null
          or (
            search_sales_orders.has_outstanding_receivable
            and coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) > 0
          )
          or (
            not search_sales_orders.has_outstanding_receivable
            and coalesce(s.outstanding_amount_minor, o.payable_amount_minor, 0) = 0
          )
        )
        and (
          search_sales_orders.has_return_exchange is null
          or (
            coalesce(p.return_status, 'none') in ('partially_returned', 'fully_returned')
          ) = search_sales_orders.has_return_exchange
        )
        and (
          search_sales_orders.e_invoice_status is null
          or (
            search_sales_orders.e_invoice_status = 'delivered'
            and exists (
              select 1
              from einvoice.electronic_invoices ei
              where ei.tenant_id = o.tenant_id
                and ei.sales_order_id = o.id
            )
          )
          or (
            search_sales_orders.e_invoice_status = 'queued'
            and not exists (
              select 1
              from einvoice.electronic_invoices ei
              where ei.tenant_id = o.tenant_id
                and ei.sales_order_id = o.id
            )
          )
        )
        and (
          v_search is null
          or catalog.unaccent_immutable(coalesce(
            nullif(btrim(o.order_code), ''),
            'SO-' || upper(substr(replace(o.id::text, '-', ''), 1, 12))
          )) ilike '%' || v_search || '%'
          or catalog.unaccent_immutable(o.sales_context_snapshot -> 'customer' ->> 'displayName') ilike '%' || v_search || '%'
          or catalog.unaccent_immutable(o.sales_context_snapshot -> 'customer' ->> 'phoneNumber') ilike '%' || v_search || '%'
        )
    ),
    page as (
      select *
      from filtered
      where (
        v_cursor_at is null
        or (created_at, id) < (v_cursor_at, v_cursor_id)
      )
      order by created_at desc, id desc
      limit v_limit + 1
    ),
    visible as (
      select *
      from page
      order by created_at desc, id desc
      limit v_limit
    )
    select jsonb_build_object(
      'items',
      coalesce(
        (
          select jsonb_agg(
            jsonb_build_object(
              'salesOrderId', v.id,
              'orderNumber', v.order_number,
              'sourceVersion', v.source_version,
              'committedAt', to_char(v.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
              'customer', v.sales_context_snapshot -> 'customer',
              'store', v.sales_context_snapshot -> 'store',
              'total', jsonb_build_object('amountMinor', v.payable_amount_minor, 'currencyCode', v.currency_code),
              'lifecycleStatus', v.lifecycle_status,
              'lockStatus', v.lock_status,
              'settlementStatus', v.settlement_status,
              'returnStatus', v.return_status,
              'eInvoiceStatus', v.e_invoice_status
            )
            order by v.created_at desc, v.id desc
          )
          from visible v
        ),
        '[]'::jsonb
      ),
      'hasMore', (select count(*) > v_limit from page),
      'nextCursor',
      (
        select case
          when (select count(*) from page) > v_limit then
            concat(
              to_char(
                (select created_at from visible order by created_at asc, id asc limit 1)
                  at time zone 'utc',
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
              ),
              '|',
              (select id::text from visible order by created_at asc, id asc limit 1)
            )
          else null
        end
      ),
      'totalMatching', (select count(*) from filtered),
      'facets', jsonb_build_object(
        'all', (select count(*) from filtered),
        'outstandingReceivable', (select count(*) filter (where outstanding_minor > 0) from filtered),
        'eInvoicePending', (select count(*) filter (where filtered.e_invoice_status = 'notRequired') from filtered)
      )
    )
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.settle_return_exchange_difference(command_id text, tenant_id uuid, actor_id uuid, operation text, sales_order_id uuid DEFAULT NULL::uuid, return_exchange_id uuid DEFAULT NULL::uuid, amount_minor bigint DEFAULT NULL::bigint, currency_code text DEFAULT NULL::text, method text DEFAULT NULL::text, reference text DEFAULT NULL::text, idempotency_key text DEFAULT NULL::text, payload_hash text DEFAULT NULL::text, correlation_id text DEFAULT NULL::text, causation_id text DEFAULT NULL::text, expected_source_version bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_permission text;
  v_decision jsonb;
  v_correlation uuid;
  v_session sales.return_exchange_orders%rowtype;
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_valuation sales.return_exchange_valuations%rowtype;
  v_plan jsonb;
  v_plan_count integer;
  v_jwt_store text;
  v_is_walk_in boolean;
  v_net_confirmed_collection bigint;
  v_transaction_id uuid;
  v_outstanding bigint;
  v_status text;
  v_result jsonb;
  v_scope text;
  v_collect_amount_minor bigint;
  v_refund_amount_minor bigint;
  v_receivable_create_amount_minor bigint;
  v_receivable_reverse_amount_minor bigint;
  v_processed_collect_minor bigint;
  v_processed_refund_minor bigint;
  v_pending_receivable_create_minor bigint;
  v_pending_receivable_reverse_minor bigint;
  v_remainder_collect_minor bigint;
  v_remainder_refund_minor bigint;
  v_source_order_version bigint;
  v_source_settlement_version bigint;
  v_plan_currency text;
  v_plan_sales_order_id uuid;
  v_rx_id uuid;
  v_pricing_source_version integer;
  v_inventory_source_version integer;
begin
  if operation is distinct from 'collection' and operation is distinct from 'refund' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Unsupported settlement operation.'
    )::text;
  end if;

  v_permission := case
    when operation = 'collection' then 'sales.payment.record'
    else 'sales.payment.refund'
  end;

  if auth.uid() is distinct from actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED',
      'message', 'Permission denied.'
    )::text;
  end if;

  -- Confirm auto-settle runs under sales.return_exchange.confirm only.
  -- Skip payment/refund permission when confirmation context GUC is set;
  -- public settle still requires the payment/refund permission below.
  if coalesce(current_setting('sales.return_exchange_confirmation_context', true), '')
      is distinct from '1'
    and iam.has_permission(
      settle_return_exchange_difference.tenant_id,
      v_permission
    ) is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED',
      'message', 'Permission denied.'
    )::text;
  end if;

  if amount_minor is null or amount_minor <= 0
    or nullif(btrim(currency_code), '') is null
    or nullif(btrim(method), '') is null
    or nullif(btrim(idempotency_key), '') is null
    or nullif(btrim(payload_hash), '') is null
    or nullif(btrim(correlation_id), '') is null
    or expected_source_version is null
    or expected_source_version <= 0 then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Settlement context is invalid.'
    )::text;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      settle_return_exchange_difference.tenant_id::text
        || ':' || coalesce(correlation_id, '') || ':' || operation,
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

  v_scope := 'settle_return_exchange_difference:' || operation;
  -- 'IDEMPOTENCY_CONFLICT' raised by sales._begin_sales_idempotency on hash mismatch.
  v_decision := sales._begin_sales_idempotency(
    settle_return_exchange_difference.tenant_id,
    v_scope,
    trim(idempotency_key),
    trim(payload_hash));

  if (v_decision ->> 'decision') = 'replay' then
    return v_decision -> 'result_snapshot';
  end if;
  if (v_decision ->> 'decision') = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IDEMPOTENCY_CONFLICT',
      'message', 'Idempotency key is already in progress.'
    )::text;
  end if;

  -- Resolve the plan by the session when the caller names it (confirm always
  -- does). One app run reuses one correlation id across sessions, so the
  -- correlation lookup below is only a fallback for callers without an id.
  if settle_return_exchange_difference.return_exchange_id is not null then
    select * into v_valuation
    from sales.return_exchange_valuations
    where return_exchange_valuations.tenant_id = settle_return_exchange_difference.tenant_id
      and return_exchange_valuations.return_exchange_order_id
        = settle_return_exchange_difference.return_exchange_id
    for update;
    if not found then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Stored settlement plan is missing.'
      )::text;
    end if;
  elsif operation = 'refund' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Refund settlement requires return_exchange_id.'
    )::text;
  else
    if sales_order_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Collection settlement requires sales_order_id.'
      )::text;
    end if;
    select count(*) into v_plan_count
    from sales.return_exchange_valuations v
    join sales.return_exchange_orders rx
      on rx.id = v.return_exchange_order_id
     and rx.tenant_id = v.tenant_id
    where v.tenant_id = settle_return_exchange_difference.tenant_id
      and rx.sales_order_id = settle_return_exchange_difference.sales_order_id
      and coalesce(rx.correlation_id, '') = settle_return_exchange_difference.correlation_id
      and v.status in ('calculated', 'confirmed');
    if v_plan_count is distinct from 1 then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settlement plan association is missing or ambiguous.'
      )::text;
    end if;
    select v.* into v_valuation
    from sales.return_exchange_valuations v
    join sales.return_exchange_orders rx
      on rx.id = v.return_exchange_order_id
     and rx.tenant_id = v.tenant_id
    where v.tenant_id = settle_return_exchange_difference.tenant_id
      and rx.sales_order_id = settle_return_exchange_difference.sales_order_id
      and coalesce(rx.correlation_id, '') = settle_return_exchange_difference.correlation_id
      and v.status in ('calculated', 'confirmed')
    for update of v;
  end if;

  v_plan := coalesce(v_valuation.valuation_details -> 'settlement_plan', '{}'::jsonb);
  v_rx_id := v_valuation.return_exchange_order_id;
  v_collect_amount_minor := coalesce((v_plan ->> 'collect_amount_minor')::bigint, 0);
  v_refund_amount_minor := coalesce((v_plan ->> 'refund_amount_minor')::bigint, 0);
  v_receivable_create_amount_minor := coalesce((v_plan ->> 'receivable_create_amount_minor')::bigint, 0);
  v_receivable_reverse_amount_minor := coalesce((v_plan ->> 'receivable_reverse_amount_minor')::bigint, 0);
  v_processed_collect_minor := coalesce((v_plan ->> 'processed_collect_minor')::bigint, 0);
  v_processed_refund_minor := coalesce((v_plan ->> 'processed_refund_minor')::bigint, 0);
  v_pending_receivable_create_minor := coalesce((v_plan ->> 'pending_receivable_create_minor')::bigint, 0);
  v_pending_receivable_reverse_minor := coalesce((v_plan ->> 'pending_receivable_reverse_minor')::bigint, 0);
  v_remainder_collect_minor := coalesce((v_plan ->> 'remainder_collect_minor')::bigint, 0);
  v_remainder_refund_minor := coalesce((v_plan ->> 'remainder_refund_minor')::bigint, 0);
  v_source_order_version := coalesce((v_plan ->> 'source_order_version')::bigint, 0);
  v_source_settlement_version := coalesce((v_plan ->> 'source_settlement_version')::bigint, 0);
  v_plan_currency := coalesce(v_plan ->> 'currency_code', v_valuation.currency_code);
  v_plan_sales_order_id := nullif(v_plan ->> 'sales_order_id', '')::uuid;
  v_pricing_source_version := nullif(v_plan ->> 'pricing_source_version', '')::integer;
  v_inventory_source_version := nullif(v_plan ->> 'inventory_source_version', '')::integer;

  select * into v_session
  from sales.return_exchange_orders
  where return_exchange_orders.id = v_rx_id
    and return_exchange_orders.tenant_id = settle_return_exchange_difference.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND',
      'message', 'Return/exchange session not found.'
    )::text;
  end if;

  if v_session.status not in ('confirmed', 'processing')
    and coalesce(current_setting('sales.return_exchange_confirmation_context', true), '')
      is distinct from '1' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Settlement requires a confirmed return or confirmation transaction context.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = coalesce(v_plan_sales_order_id, v_session.sales_order_id)
    and sales_orders.tenant_id = settle_return_exchange_difference.tenant_id
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

  v_is_walk_in := v_order.customer_partner_id is null;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = settle_return_exchange_difference.tenant_id
  for update;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Authoritative settlement context is unavailable.'
    )::text;
  end if;

  if expected_source_version is distinct from v_settlement.version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Settlement version is stale.',
      'details', jsonb_build_object('expectedSourceVersion', expected_source_version)
    )::text;
  end if;

  if v_source_settlement_version is distinct from v_settlement.version
    or v_source_order_version is distinct from v_order.version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION',
      'message', 'Stored settlement plan is stale.',
      'details', jsonb_build_object(
        'planSourceSettlementVersion', v_source_settlement_version,
        'currentSettlementVersion', v_settlement.version,
        'planSourceOrderVersion', v_source_order_version,
        'currentOrderVersion', v_order.version
      )
    )::text;
  end if;

  if upper(btrim(currency_code)) is distinct from upper(v_plan_currency) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Settlement currency does not match the stored plan.'
    )::text;
  end if;

  v_net_confirmed_collection := v_settlement.net_collected_amount_minor;
  if v_net_confirmed_collection < 0 then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Negative refundable capacity is not allowed.'
    )::text;
  end if;

  if operation = 'collection' then
    if amount_minor > v_remainder_collect_minor then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Collection exceeds remaining collect capacity.'
      )::text;
    end if;
  else
    if amount_minor > v_remainder_refund_minor then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Refund exceeds remaining refund capacity.'
      )::text;
    end if;
    if amount_minor > v_net_confirmed_collection then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Refund exceeds net confirmed collection capacity.'
      )::text;
    end if;
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

  v_transaction_id := gen_random_uuid();
  insert into receivable.sales_payment_transactions (
    id,
    tenant_id,
    sales_order_settlement_id,
    transaction_type,
    direction,
    amount_minor,
    currency_code,
    payment_method_code,
    status,
    source_context,
    source_type,
    source_id,
    initiated_by_user_id,
    external_reference,
    occurred_at
  ) values (
    v_transaction_id,
    settle_return_exchange_difference.tenant_id,
    v_settlement.id,
    operation,
    case when operation = 'collection' then 'inflow' else 'outflow' end,
    amount_minor,
    upper(btrim(currency_code)),
    btrim(method),
    'confirmed',
    'return_exchange',
    'return_exchange_order',
    v_rx_id,
    settle_return_exchange_difference.actor_id,
    nullif(btrim(coalesce(reference, '')), ''),
    now()
  );

  perform sales._recompute_sales_settlement(
    settle_return_exchange_difference.tenant_id,
    v_settlement.id
  );

  select * into v_settlement
  from receivable.sales_order_settlements
  where id = v_settlement.id
    and tenant_id = settle_return_exchange_difference.tenant_id;

  if operation = 'collection' then
    v_processed_collect_minor := v_processed_collect_minor + amount_minor;
    v_remainder_collect_minor := v_remainder_collect_minor - amount_minor;
  else
    v_processed_refund_minor := v_processed_refund_minor + amount_minor;
    v_remainder_refund_minor := v_remainder_refund_minor - amount_minor;
  end if;

  -- Keep plan aligned with this settle's settlement bump so partial
  -- settle / second settle against the same plan does not false-STALE.
  -- External settlement changes still fail the pre-mutation check above.
  v_source_settlement_version := v_settlement.version;

  if (
    (operation = 'collection' and v_receivable_create_amount_minor > 0
      and v_pending_receivable_create_minor = 0
      and v_processed_collect_minor >= v_collect_amount_minor)
    or (
      operation = 'refund' and v_receivable_reverse_amount_minor > 0
      and v_pending_receivable_reverse_minor = 0
      and v_processed_refund_minor >= v_refund_amount_minor
    )
  ) then
    if v_order.customer_partner_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Walk-in customers cannot use receivable create or reversal.'
      )::text;
    end if;
    -- Model B handoff deferred: receivable create/reverse stays inside the Sales plan.
    if operation = 'collection' then
      v_pending_receivable_create_minor := v_receivable_create_amount_minor;
    else
      v_pending_receivable_reverse_minor := v_receivable_reverse_amount_minor;
    end if;
  end if;

  v_plan := jsonb_build_object(
    'currency_code', v_plan_currency,
    'net_difference_minor', v_valuation.net_difference_minor,
    'collect_amount_minor', v_collect_amount_minor,
    'refund_amount_minor', v_refund_amount_minor,
    'receivable_create_amount_minor', v_receivable_create_amount_minor,
    'receivable_reverse_amount_minor', v_receivable_reverse_amount_minor,
    'processed_collect_minor', v_processed_collect_minor,
    'processed_refund_minor', v_processed_refund_minor,
    'pending_receivable_create_minor', v_pending_receivable_create_minor,
    'pending_receivable_reverse_minor', v_pending_receivable_reverse_minor,
    'remainder_collect_minor', v_remainder_collect_minor,
    'remainder_refund_minor', v_remainder_refund_minor,
    'source_order_version', v_source_order_version,
    'source_settlement_version', v_source_settlement_version,
    'pricing_source_version', v_pricing_source_version,
    'inventory_source_version', v_inventory_source_version,
    'sales_order_id', v_order.id,
    'correlation_id', coalesce(nullif(v_plan ->> 'correlation_id', ''), correlation_id)
  );

  update sales.return_exchange_valuations
  set
    valuation_details = jsonb_set(
      coalesce(valuation_details, '{}'::jsonb),
      '{settlement_plan}',
      v_plan,
      true
    ),
    status = case
      when status = 'calculated' then 'confirmed'
      else status
    end
  where id = v_valuation.id;

  v_outstanding := v_settlement.outstanding_amount_minor;
  v_status := case v_settlement.payment_status
    when 'partially_paid' then 'partiallyPaid'
    when 'partially_refunded' then 'partiallyRefunded'
    else v_settlement.payment_status
  end;

  if operation = 'collection' then
    v_result := jsonb_build_object(
      'status', v_status,
      'orderTotal', jsonb_build_object(
        'amountMinor', v_settlement.current_payable_amount_minor,
        'currencyCode', v_settlement.currency_code
      ),
      'paidTotal', jsonb_build_object(
        'amountMinor', v_settlement.collected_amount_minor,
        'currencyCode', v_settlement.currency_code
      ),
      'outstandingTotal', jsonb_build_object(
        'amountMinor', v_outstanding,
        'currencyCode', v_settlement.currency_code
      )
    );
  else
    v_result := jsonb_build_object(
      'returnExchangeId', v_rx_id::text,
      'difference', jsonb_build_object(
        'amountMinor', amount_minor,
        'currencyCode', v_plan_currency
      ),
      'status', v_status
    );
  end if;

  perform sales._emit_sales_settlement_changed(
    settle_return_exchange_difference.tenant_id,
    v_settlement.id,
    'return_exchange_difference',
    coalesce(v_rx_id::text, v_transaction_id::text),
    'settle_return_exchange_difference'
  );

  perform sales._complete_sales_idempotency(
    settle_return_exchange_difference.tenant_id,
    v_scope,
    trim(idempotency_key),
    'succeeded',
    v_result);

  return v_result;
end;
$function$
;

CREATE OR REPLACE FUNCTION sales.start_return_exchange(command_id text, tenant_id uuid, actor_id uuid, sales_order_id uuid, entry_source text, lines jsonb, idempotency_key text, payload_hash text, correlation_id text, causation_id text DEFAULT NULL::text, expected_source_version integer DEFAULT NULL::integer, reference_decision jsonb DEFAULT '{}'::jsonb, reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'sales', 'iam', 'public', 'pg_temp'
AS $function$
#variable_conflict use_column
declare
  v_order sales.sales_orders%rowtype;
  v_settlement receivable.sales_order_settlements%rowtype;
  v_session_id uuid := gen_random_uuid();
  v_reference_number text;
  v_seq bigint;
  v_line jsonb;
  v_kind text;
  v_role text;
  v_line_seq integer := 0;
  v_product_snapshot jsonb;
  v_unit_snapshot jsonb;
  v_unit_price_minor bigint;
  v_line_id uuid;
  v_orig uuid;
  v_src_exchange uuid;
  v_qty bigint;
  v_base_qty bigint;
  v_src_product_id uuid;
  v_src_product_unit_id uuid;
  v_idem jsonb;
  v_correlation uuid;
  v_result jsonb;
  v_product_src jsonb;
  v_unit_src jsonb;
  v_priced jsonb;
begin
  if auth.uid() is distinct from start_return_exchange.actor_id
    or iam.has_permission(
      start_return_exchange.tenant_id, 'sales.return_exchange.create'
    ) is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  if start_return_exchange.entry_source is distinct from 'standard'
    and start_return_exchange.entry_source is distinct from 'full_return_from_cancel_attempt' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'entry_source must be standard or full_return_from_cancel_attempt.'
    )::text;
  end if;

  begin
    v_correlation := nullif(trim(coalesce(correlation_id, '')), '')::uuid;
  exception when others then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID', 'message', 'Correlation id is invalid.'
    )::text;
  end;
  if v_correlation is null then
    begin
      v_correlation := nullif(trim(coalesce(command_id, '')), '')::uuid;
    exception when others then
      v_correlation := gen_random_uuid();
    end;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      start_return_exchange.tenant_id::text || ':start_return_exchange:' ||
      start_return_exchange.idempotency_key, 0
    )
  );

  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'start_return_exchange', idempotency_key, payload_hash);
  if v_idem ->> 'decision' = 'replay' then
    return coalesce(v_idem -> 'result_snapshot', '{}'::jsonb);
  end if;
  if v_idem ->> 'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IN_PROGRESS', 'message', 'Return/exchange start is already in progress.'
    )::text;
  end if;

  select * into v_order
  from sales.sales_orders
  where sales_orders.id = start_return_exchange.sales_order_id
    and sales_orders.tenant_id = start_return_exchange.tenant_id
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.',
      'details', jsonb_build_object('salesOrderId', start_return_exchange.sales_order_id)
    )::text;
  end if;

  perform sales._assert_sales_actor(
    tenant_id, actor_id, v_order.store_id, 'sales.return_exchange.create'
  );

  if expected_source_version is not null
     and v_order.version is distinct from expected_source_version then
    raise exception using message = jsonb_build_object(
      'code', 'STALE_VERSION', 'message', 'Sales order version is stale.'
    )::text;
  end if;

  if v_order.lifecycle_status is distinct from 'completed' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Only completed sales orders may start a return/exchange.'
    )::text;
  end if;

  if exists (
    select 1 from sales.sales_order_cancellations c
    where c.tenant_id = start_return_exchange.tenant_id
      and c.sales_order_id = v_order.id
      and c.status in ('requested', 'validating', 'confirmed', 'processing', 'completed')
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'A competing cancellation blocks return/exchange entry.',
      'details', jsonb_build_object('reason', 'COMPETING_CANCELLATION')
    )::text;
  end if;

  select * into v_settlement
  from receivable.sales_order_settlements
  where sales_order_settlements.sales_order_id = v_order.id
    and sales_order_settlements.tenant_id = start_return_exchange.tenant_id
  order by version desc, id desc
  limit 1;

  if exists (
    select 1 from jsonb_array_elements(coalesce(start_return_exchange.lines, '[]'::jsonb)) elem
    where (elem ->> 'kind') = 'returnLine'
      and (nullif(elem ->> 'original_sales_order_line_id', '') is not null)
          = (nullif(elem ->> 'source_exchange_line_id', '') is not null)
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Returned lines require exactly one source: original or exchange.'
    )::text;
  end if;

  if exists (
    select 1 from jsonb_array_elements(coalesce(start_return_exchange.lines, '[]'::jsonb)) elem
    where (elem ->> 'kind') = 'exchangeLine'
      and (
        nullif(btrim(coalesce(elem ->> 'reason_code', '')), '') is not null
        or nullif(btrim(coalesce(elem ->> 'condition_code', '')), '') is not null
        or nullif(elem ->> 'original_sales_order_line_id', '') is not null
      )
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Exchange lines forbid reason_code, condition_code, and original_sales_order_line_id.'
    )::text;
  end if;

  if exists (
    select 1 from jsonb_array_elements(coalesce(start_return_exchange.lines, '[]'::jsonb)) elem
    where (elem ->> 'kind') = 'returnLine'
      and nullif(elem ->> 'original_sales_order_line_id', '') is not null
      and not exists (
        select 1 from sales.sales_order_lines sol
        where sol.id = (elem ->> 'original_sales_order_line_id')::uuid
          and sol.sales_order_id = v_order.id
          and sol.tenant_id = start_return_exchange.tenant_id
      )
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Returned lines must reference a line on the source sales order.'
    )::text;
  end if;

  -- Requested-vs-remaining guard for lines returning against an original sales
  -- order line. Lines carrying source_exchange_line_id (returning a previously
  -- exchanged-in unit) have a null original_line_id here, so the inner join
  -- below naturally excludes them; the strict remaining-quantity check for
  -- exchange-source lines is enforced in get_returnable/confirm (Tasks 3/5).
  if exists (
    select 1
    from (
      select (elem ->> 'original_sales_order_line_id')::uuid as original_line_id,
             sum((elem ->> 'quantity_micros')::bigint) as requested_micros
      from jsonb_array_elements(coalesce(start_return_exchange.lines, '[]'::jsonb)) elem
      where (elem ->> 'kind') = 'returnLine'
      group by 1
    ) req
    inner join sales.sales_order_lines sol
      on sol.id = req.original_line_id
     and sol.sales_order_id = v_order.id
    where req.requested_micros > greatest(
      sol.quantity_micros - coalesce((
        select sum(rl.quantity_micros)
        from sales.return_exchange_lines rl
        join sales.return_exchange_orders r
          on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
        where r.tenant_id = start_return_exchange.tenant_id
          and r.sales_order_id = v_order.id
          and r.status in ('confirmed', 'processing', 'completed')
          and rl.line_role = 'returned'
          and rl.original_sales_order_line_id = sol.id
          and rl.source_sales_order_id = v_order.id
      ), 0),
      0
    )
  ) then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_QUANTITY_EXCEEDED',
      'message', 'Requested return quantity exceeds remaining returnable quantity.'
    )::text;
  end if;

  -- Per-order occurrence number: the Nth return/exchange opened against this
  -- source order (1-based, counting every status incl. cancelled so numbers
  -- are never reused). Serialise concurrent starts on the same source order so
  -- two sessions cannot claim the same suffix.
  perform pg_advisory_xact_lock(
    hashtextextended(
      start_return_exchange.tenant_id::text || ':start_return_exchange:order:' ||
      v_order.id::text, 0
    )
  );

  select count(*) + 1
  into v_seq
  from sales.return_exchange_orders
  where return_exchange_orders.tenant_id = start_return_exchange.tenant_id
    and return_exchange_orders.sales_order_id = v_order.id;

  -- DT<source order code digits>-NN, e.g. DH202608190002 -> DT202608190002-01.
  v_reference_number := 'DT' || regexp_replace(v_order.order_code, '^DH', '')
    || '-' || lpad(v_seq::text, 2, '0');

  insert into sales.return_exchange_orders (
    id, tenant_id, sales_order_id, status, version, source_order_version,
    created_by_user_id, reason, currency_code,
    entry_source, source_settlement_version, reference_number, correlation_id
  ) values (
    v_session_id, start_return_exchange.tenant_id, v_order.id,
    'draft', 1, v_order.version, start_return_exchange.actor_id,
    nullif(btrim(start_return_exchange.reason), ''),
    v_order.currency_code,
    start_return_exchange.entry_source,
    coalesce(v_settlement.version, 1), v_reference_number,
    start_return_exchange.correlation_id
  );

  for v_line in
    select value from jsonb_array_elements(coalesce(start_return_exchange.lines, '[]'::jsonb))
  loop
    v_line_seq := v_line_seq + 1;
    v_kind := v_line ->> 'kind';
    v_role := case when v_kind = 'returnLine' then 'returned' else 'exchange' end;
    v_line_id := gen_random_uuid();
    v_orig := nullif(v_line ->> 'original_sales_order_line_id', '')::uuid;
    v_src_exchange := nullif(v_line ->> 'source_exchange_line_id', '')::uuid;
    v_qty := (v_line ->> 'quantity_micros')::bigint;
    v_unit_price_minor := 0;
    v_product_snapshot := '{}'::jsonb;
    v_unit_snapshot := '{}'::jsonb;

    if v_role = 'returned' then
      if v_src_exchange is not null then
        -- Returning a previously exchanged-in unit: snapshot/price come from
        -- the source exchange line, not from the original sales order line.
        select rl.unit_value_minor, rl.product_snapshot, rl.product_unit_snapshot,
               rl.product_id, rl.product_unit_id
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot,
               v_src_product_id, v_src_product_unit_id
        from sales.return_exchange_lines rl
        join sales.return_exchange_orders r
          on r.id = rl.return_exchange_order_id and r.tenant_id = rl.tenant_id
        where rl.id = v_src_exchange
          and rl.tenant_id = start_return_exchange.tenant_id
          and rl.line_role = 'exchange'
          and r.sales_order_id = v_order.id
          and r.status in ('confirmed', 'processing', 'completed');
        if v_unit_price_minor is null then
          raise exception using message = jsonb_build_object(
            'code', 'RETURN_EXCHANGE_BLOCKED',
            'message', 'Source exchange line snapshot is missing.'
          )::text;
        end if;
      else
        -- Giá trị 1 đơn vị hàng trả = giá khách thực trả (đã trừ chiết khấu),
        -- khớp tiền hoàn ở evaluate_return_exchange_valuation. Không chép
        -- unit_price_minor: với dòng có chiết khấu đó là giá niêm yết.
        select round(sol.line_total_minor::numeric * 1000000 / sol.quantity_micros)::bigint,
               sol.product_snapshot, sol.product_unit_snapshot,
               sol.product_id, sol.product_unit_id
          into v_unit_price_minor, v_product_snapshot, v_unit_snapshot,
               v_src_product_id, v_src_product_unit_id
        from sales.sales_order_lines sol
        where sol.id = v_orig
          and sol.sales_order_id = v_order.id
          and sol.tenant_id = start_return_exchange.tenant_id;
        if v_unit_price_minor is null then
          raise exception using message = jsonb_build_object(
            'code', 'RETURN_EXCHANGE_BLOCKED',
            'message', 'Returned line commercial unit price snapshot is missing.'
          )::text;
        end if;
      end if;
    else
      v_product_src := coalesce(
        start_return_exchange.reference_decision -> 'exchange_products_by_product_unit_id'
          -> (v_line ->> 'product_unit_id'),
        '{}'::jsonb
      );
      v_unit_src := coalesce(
        start_return_exchange.reference_decision -> 'exchange_units_by_product_unit_id'
          -> (v_line ->> 'product_unit_id'),
        '{}'::jsonb
      );
      v_priced := coalesce(
        start_return_exchange.reference_decision -> 'exchange_prices_by_product_unit_id'
          -> (v_line ->> 'product_unit_id'),
        '{}'::jsonb
      );
      v_product_snapshot := v_product_src;
      v_unit_snapshot := v_unit_src;
      -- Plan 2: server tự tính giá món đổi; giá app gửi chỉ để đối chiếu.
      v_unit_price_minor := sales._assert_exchange_price(
        start_return_exchange.tenant_id, v_order,
        (v_line ->> 'product_id')::uuid, (v_line ->> 'product_unit_id')::uuid,
        (v_priced ->> 'amountMinor')::bigint
      );
    end if;

    if v_role = 'returned'
       and (v_src_product_id is distinct from (v_line ->> 'product_id')::uuid
         or v_src_product_unit_id is distinct from (v_line ->> 'product_unit_id')::uuid) then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Hàng trả phải cùng sản phẩm và đơn vị với dòng gốc.'
      )::text;
    end if;
    if v_role = 'exchange' then
      v_unit_snapshot := coalesce(v_unit_snapshot, '{}'::jsonb) || jsonb_build_object(
        'conversionRateToBase',
        sales._product_unit_conversion_rate(
          start_return_exchange.tenant_id,
          (v_line ->> 'product_id')::uuid,
          (v_line ->> 'product_unit_id')::uuid
        )
      );
    end if;
    v_base_qty := sales._base_quantity_micros(
      v_qty, (v_unit_snapshot ->> 'conversionRateToBase')::numeric
    );

    insert into sales.return_exchange_lines (
      id, tenant_id, return_exchange_order_id, source_sales_order_id, line_sequence,
      line_role, original_sales_order_line_id, source_exchange_line_id, product_id, product_unit_id,
      quantity_micros, base_quantity_micros, unit_value_minor,
      return_reason_code, return_condition_code, product_snapshot, product_unit_snapshot
    ) values (
      v_line_id, start_return_exchange.tenant_id, v_session_id, v_order.id, v_line_seq,
      v_role, v_orig, v_src_exchange, (v_line ->> 'product_id')::uuid, (v_line ->> 'product_unit_id')::uuid,
      v_qty, v_base_qty, v_unit_price_minor,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'reason_code'), '')) else null end,
      case when v_role = 'returned' then upper(nullif(btrim(v_line ->> 'condition_code'), '')) else null end,
      coalesce(v_product_snapshot, '{}'::jsonb),
      coalesce(v_unit_snapshot, '{}'::jsonb)
    );
  end loop;

  v_result := sales._get_return_exchange_context(
    start_return_exchange.tenant_id, start_return_exchange.actor_id, v_session_id
  ) -> 'draft';
  perform sales._complete_sales_idempotency(
    tenant_id, 'start_return_exchange', trim(idempotency_key),
    'succeeded', v_result);
  return v_result;
end;
$function$
;


-- 6) View AI doc ngay hen tu quyet toan
create or replace view ai_read.don_ban as
select
  so.id as don_id,
  so.order_code::text as ma_don,
  (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay_ban,
  to_char(so.completed_at at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI') as gio_ban,
  case so.lifecycle_status when 'cancelled' then 'da_huy' else 'hoan_tat' end as trang_thai,
  so.customer_partner_id as khach_id,
  case when so.customer_partner_id is null then 'Khách lẻ'
       else coalesce(pt.display_name, 'Khách') end as ten_khach,
  coalesce(
    (select nullif(trim(concat_ws(' ', pr.family_middle_name, pr.given_name)), '')
       from iam.platform_user_profiles pr where pr.user_id = so.seller_user_id),
    'Nhân viên') as ten_nhan_vien,
  (select count(*)::int from sales.sales_order_lines l
    where l.tenant_id = so.tenant_id and l.sales_order_id = so.id) as so_dong,
  so.payable_amount_minor::bigint as tong_tien_vnd,
  coalesce(st.collected_amount_minor, 0)::bigint as da_thu_vnd,
  coalesce(st.outstanding_amount_minor, 0)::bigint as con_no_vnd,
  st.payment_due_date as han_thanh_toan,
  (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date as ngay_huy
from sales.sales_orders so
left join receivable.sales_order_settlements st
  on st.tenant_id = so.tenant_id and st.sales_order_id = so.id
left join partner.partners pt
  on pt.tenant_id = so.tenant_id and pt.partner_id = so.customer_partner_id
where so.tenant_id = ai._tenant()
  and so.store_id = ai._store();



-- 7) Xoa cot cu (khong cascade: loi phu thuoc = con cho chua sua)
alter table sales.sales_orders drop column payment_due_date;
