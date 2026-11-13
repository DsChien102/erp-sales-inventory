-- Title: inventory reports (stock in-out-balance, stock card, movement detail, gross profit, supplier purchases)
-- Kind: schema
-- Intent: inventory_reports
-- Context: TH-07 / BJ-15, SCR-055 / SCR-056, spec giá vốn mục 7-8; PLAN T7-G5-7
-- Touches: _report_range_check, _movement_source, get_stock_report, get_stock_card, get_movement_detail, get_gross_profit_report, get_supplier_purchase_report
-- Safety: one-shot ; read-only RPCs, no new tables
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy, 20261114001_inventory_goods_receipts, 20261115001_inventory_sales_link, 20261116001_inventory_stocktake, 20261117001_inventory_supplier_rebates, 20261118001_inventory_costing

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Helpers
-- ---------------------------------------------------------------------------

create or replace function inventory._report_range_check(p_from date, p_to date)
returns void
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
begin
  if p_from is null or p_to is null or p_from > p_to then
    perform inventory._raise('CONTEXT_INVALID', 'Khoảng ngày không hợp lệ.');
  end if;
end;
$$;

revoke all on function inventory._report_range_check(date, date) from public, anon, authenticated;

create or replace function inventory._movement_source(
  p_tenant_id uuid,
  p_intent_type text,
  p_intent_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_code text;
  v_order_id uuid;
  v_return_id uuid;
begin
  if p_intent_type = 'GOODS_RECEIPT' then
    select gr.receipt_no
    into v_code
    from inventory.goods_receipts gr
    where gr.tenant_id = p_tenant_id
      and gr.id = p_intent_id;

    if found then
      return jsonb_build_object(
        'kind', 'RECEIPT',
        'doc_code', v_code,
        'target', jsonb_build_object('receipt_id', p_intent_id)
      );
    end if;
  elsif p_intent_type = 'SALES_ORDER' then
    select so.order_code
    into v_code
    from sales.sales_orders so
    where so.tenant_id = p_tenant_id
      and so.id = p_intent_id;

    if found then
      return jsonb_build_object(
        'kind', 'ORDER',
        'doc_code', v_code,
        'target', jsonb_build_object('order_id', p_intent_id)
      );
    end if;
  elsif p_intent_type = 'SALES_CANCELLATION' then
    select so.order_code, so.id
    into v_code, v_order_id
    from sales.sales_order_cancellations sc
    join sales.sales_orders so
      on so.tenant_id = sc.tenant_id
     and so.id = sc.sales_order_id
    where sc.tenant_id = p_tenant_id
      and sc.id = p_intent_id;

    if found then
      return jsonb_build_object(
        'kind', 'CANCELLATION',
        'doc_code', v_code,
        'target', jsonb_build_object('order_id', v_order_id)
      );
    end if;
  elsif p_intent_type = 'RETURN_EXCHANGE' then
    select so.order_code, so.id, rx.id
    into v_code, v_order_id, v_return_id
    from sales.return_exchange_orders rx
    join sales.sales_orders so
      on so.tenant_id = rx.tenant_id
     and so.id = rx.sales_order_id
    where rx.tenant_id = p_tenant_id
      and rx.id = p_intent_id;

    if found then
      return jsonb_build_object(
        'kind', 'RETURN_EXCHANGE',
        'doc_code', v_code,
        'target', jsonb_build_object('order_id', v_order_id, 'return_id', v_return_id)
      );
    end if;
  elsif p_intent_type = 'STOCKTAKE' then
    select ss.code
    into v_code
    from inventory.stocktake_sessions ss
    where ss.tenant_id = p_tenant_id
      and ss.id = p_intent_id;

    if found then
      return jsonb_build_object(
        'kind', 'STOCKTAKE',
        'doc_code', v_code,
        'target', null
      );
    end if;
  end if;

  return jsonb_build_object('kind', 'OTHER', 'doc_code', '', 'target', null);
end;
$$;

revoke all on function inventory._movement_source(uuid, text, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. get_stock_report (SCR-055 báo cáo nhập – xuất – tồn)
-- ---------------------------------------------------------------------------

create or replace function inventory.get_stock_report(
  p_tenant_id uuid,
  p_from date,
  p_to date,
  p_search text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_warehouse_id uuid;
  v_show_available boolean;
  v_search text;
  v_rows jsonb;
  v_total bigint;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', false);
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  perform inventory._report_range_check(p_from, p_to);

  v_show_available := (p_to >= inventory._today());
  v_search := nullif(lower(btrim(coalesce(p_search, ''))), '');

  with movement_agg as (
    select
      sm.product_id,
      coalesce(sum(sm.quantity_delta) filter (where sm.business_date < p_from), 0) as opening_qty,
      coalesce(sum(sm.quantity_delta) filter (where sm.business_date >= p_from and sm.quantity_delta > 0), 0) as in_qty,
      coalesce(-sum(sm.quantity_delta) filter (where sm.business_date >= p_from and sm.quantity_delta < 0), 0) as out_qty,
      count(*) filter (where sm.business_date >= p_from) as in_period_count
    from inventory.stock_movements sm
    where sm.tenant_id = p_tenant_id
      and sm.warehouse_id = v_warehouse_id
      and sm.business_date <= p_to
    group by sm.product_id
  ),
  value_agg as (
    select vm.product_id, coalesce(sum(vm.amount_vnd), 0)::bigint as closing_value
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.business_date <= p_to
    group by vm.product_id
  ),
  picked as (
    select
      p.id as product_id,
      p.name,
      coalesce(p.sku, '') as code,
      ma.opening_qty,
      ma.in_qty,
      ma.out_qty,
      (ma.opening_qty + ma.in_qty - ma.out_qty) as closing_qty,
      coalesce(va.closing_value, 0)::bigint as closing_value
    from movement_agg ma
    join catalog.products p
      on p.tenant_id = p_tenant_id
     and p.id = ma.product_id
     and p.deleted_at is null
    left join value_agg va on va.product_id = ma.product_id
    where (ma.in_period_count > 0 or ma.opening_qty <> 0)
      and (
        v_search is null
        or position(v_search in lower(p.name)) > 0
        or position(v_search in lower(coalesce(p.sku, ''))) > 0
      )
  ),
  stock_now as (
    select sr.product_id, sr.available
    from inventory._product_stock_rows(p_tenant_id, (select array_agg(pk.product_id) from picked pk)) sr
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'product_id', pk.product_id,
          'name', pk.name,
          'code', pk.code,
          'uom', catalog._product_base_unit_name(p_tenant_id, pk.product_id),
          'opening_qty', pk.opening_qty,
          'in_qty', pk.in_qty,
          'out_qty', pk.out_qty,
          'closing_qty', pk.closing_qty,
          'available', case when v_show_available then coalesce(sn.available, pk.closing_qty) else null end,
          'closing_value', case when v_is_owner then pk.closing_value else null end
        ) order by pk.name asc, pk.product_id asc
      ),
      '[]'::jsonb
    ),
    coalesce(sum(pk.closing_value), 0)::bigint
  into v_rows, v_total
  from picked pk
  left join stock_now sn on sn.product_id = pk.product_id;

  return jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'as_of', now(),
    'show_available', v_show_available,
    'financial_masked', not v_is_owner,
    'rows', v_rows,
    'total_closing_value', case when v_is_owner then v_total else null end
  );
end;
$$;

grant execute on function inventory.get_stock_report(uuid, date, date, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 3. get_stock_card (SCR-055 thẻ kho)
-- ---------------------------------------------------------------------------

create or replace function inventory.get_stock_card(
  p_tenant_id uuid,
  p_product_id uuid,
  p_from date,
  p_to date,
  p_lot_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_warehouse_id uuid;
  v_prod record;
  v_opening numeric := 0;
  v_in numeric := 0;
  v_out numeric := 0;
  v_lots jsonb := '[]'::jsonb;
  v_rows jsonb := '[]'::jsonb;
  v_closing_value bigint := null;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', false);
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  perform inventory._report_range_check(p_from, p_to);

  select p.id, p.name, p.sku, p.tracking_mode
  into v_prod
  from catalog.products p
  where p.id = p_product_id
    and p.tenant_id = p_tenant_id
    and p.deleted_at is null;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại hoặc không thuộc cửa hàng.');
  end if;

  if p_lot_id is not null and not exists (
    select 1
    from inventory.lots l
    where l.id = p_lot_id
      and l.tenant_id = p_tenant_id
      and l.product_id = p_product_id
  ) then
    perform inventory._raise('CONTEXT_INVALID', 'Lô không tồn tại hoặc không thuộc sản phẩm.');
  end if;

  select
    coalesce(sum(sm.quantity_delta) filter (where sm.business_date < p_from), 0),
    coalesce(sum(sm.quantity_delta) filter (where sm.business_date >= p_from and sm.quantity_delta > 0), 0),
    coalesce(-sum(sm.quantity_delta) filter (where sm.business_date >= p_from and sm.quantity_delta < 0), 0)
  into v_opening, v_in, v_out
  from inventory.stock_movements sm
  where sm.tenant_id = p_tenant_id
    and sm.warehouse_id = v_warehouse_id
    and sm.product_id = p_product_id
    and sm.business_date <= p_to
    and (p_lot_id is null or sm.lot_id = p_lot_id);

  if v_prod.tracking_mode = 'lot' then
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'lot_id', lt.lot_id,
          'lot_code', lt.lot_code,
          'closing_qty', lt.closing_qty
        ) order by lt.lot_code asc, lt.lot_id asc
      ),
      '[]'::jsonb
    )
    into v_lots
    from (
      select l.id as lot_id, l.lot_code, coalesce(sum(sm.quantity_delta), 0) as closing_qty
      from inventory.stock_movements sm
      join inventory.lots l
        on l.tenant_id = sm.tenant_id
       and l.id = sm.lot_id
      where sm.tenant_id = p_tenant_id
        and sm.warehouse_id = v_warehouse_id
        and sm.product_id = p_product_id
        and sm.business_date <= p_to
      group by l.id, l.lot_code
    ) lt;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'movement_id', mv.id,
        'ledger_sequence', mv.ledger_sequence,
        'business_date', mv.business_date,
        'recorded_at', mv.created_at,
        'movement_kind', mv.movement_kind,
        'reason', mv.reason,
        'intent_type', mv.intent_type,
        'doc_code', inventory._movement_source(p_tenant_id, mv.intent_type, mv.intent_id)->>'doc_code',
        'lot_code', mv.lot_code,
        'quantity_delta', mv.quantity_delta,
        'balance_after', v_opening + mv.running_delta,
        'actor_name', iam._member_display_name(mv.created_by)
      ) order by mv.ledger_sequence asc
    ),
    '[]'::jsonb
  )
  into v_rows
  from (
    select
      sm.id,
      sm.ledger_sequence,
      sm.business_date,
      sm.created_at,
      sm.movement_kind,
      sm.reason,
      sm.intent_type,
      sm.intent_id,
      l.lot_code,
      sm.quantity_delta,
      sm.created_by,
      sum(sm.quantity_delta) over (order by sm.ledger_sequence) as running_delta
    from inventory.stock_movements sm
    left join inventory.lots l
      on l.tenant_id = sm.tenant_id
     and l.id = sm.lot_id
    where sm.tenant_id = p_tenant_id
      and sm.warehouse_id = v_warehouse_id
      and sm.product_id = p_product_id
      and sm.business_date >= p_from
      and sm.business_date <= p_to
      and (p_lot_id is null or sm.lot_id = p_lot_id)
  ) mv;

  if v_is_owner and p_lot_id is null then
    select coalesce(sum(vm.amount_vnd), 0)::bigint
    into v_closing_value
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.product_id = p_product_id
      and vm.business_date <= p_to;
  end if;

  return jsonb_build_object(
    'product', jsonb_build_object(
      'product_id', v_prod.id,
      'name', v_prod.name,
      'code', coalesce(v_prod.sku, ''),
      'uom', catalog._product_base_unit_name(p_tenant_id, v_prod.id),
      'is_lot_tracked', (v_prod.tracking_mode = 'lot')
    ),
    'from', p_from,
    'to', p_to,
    'as_of', now(),
    'financial_masked', not v_is_owner,
    'lots', v_lots,
    'summary', jsonb_build_object(
      'opening_qty', v_opening,
      'in_qty', v_in,
      'out_qty', v_out,
      'closing_qty', v_opening + v_in - v_out
    ),
    'closing_value', v_closing_value,
    'rows', v_rows
  );
end;
$$;

grant execute on function inventory.get_stock_card(uuid, uuid, date, date, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. get_movement_detail (SCR-056)
-- ---------------------------------------------------------------------------

create or replace function inventory.get_movement_detail(
  p_tenant_id uuid,
  p_movement_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_warehouse_id uuid;
  v_mv record;
  v_prod record;
  v_lot_code text;
  v_before numeric;
  v_value bigint := null;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', false);
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  select sm.id, sm.ledger_sequence, sm.product_id, sm.lot_id, sm.movement_kind, sm.reason,
         sm.intent_type, sm.intent_id, sm.quantity_delta, sm.business_date, sm.created_at, sm.created_by
  into v_mv
  from inventory.stock_movements sm
  where sm.id = p_movement_id
    and sm.tenant_id = p_tenant_id
    and sm.warehouse_id = v_warehouse_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Biến động không tồn tại hoặc không thuộc cửa hàng.');
  end if;

  select p.id, p.name, p.sku, p.tracking_mode
  into v_prod
  from catalog.products p
  where p.id = v_mv.product_id
    and p.tenant_id = p_tenant_id;

  if v_mv.lot_id is not null then
    select l.lot_code
    into v_lot_code
    from inventory.lots l
    where l.id = v_mv.lot_id
      and l.tenant_id = p_tenant_id;
  end if;

  select coalesce(sum(sm.quantity_delta), 0)
  into v_before
  from inventory.stock_movements sm
  where sm.tenant_id = p_tenant_id
    and sm.warehouse_id = v_warehouse_id
    and sm.product_id = v_mv.product_id
    and sm.ledger_sequence < v_mv.ledger_sequence;

  if v_is_owner then
    select sum(vm.amount_vnd)::bigint
    into v_value
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.movement_id = v_mv.id;
  end if;

  return jsonb_build_object(
    'movement_id', v_mv.id,
    'product', jsonb_build_object(
      'product_id', v_prod.id,
      'name', v_prod.name,
      'code', coalesce(v_prod.sku, ''),
      'uom', catalog._product_base_unit_name(p_tenant_id, v_prod.id),
      'is_lot_tracked', (v_prod.tracking_mode = 'lot')
    ),
    'lot_code', v_lot_code,
    'movement_kind', v_mv.movement_kind,
    'reason', v_mv.reason,
    'intent_type', v_mv.intent_type,
    'quantity_delta', v_mv.quantity_delta,
    'before_qty', v_before,
    'after_qty', v_before + v_mv.quantity_delta,
    'business_date', v_mv.business_date,
    'recorded_at', v_mv.created_at,
    'actor_name', iam._member_display_name(v_mv.created_by),
    'value_amount', v_value,
    'source', inventory._movement_source(p_tenant_id, v_mv.intent_type, v_mv.intent_id)
  );
end;
$$;

grant execute on function inventory.get_movement_detail(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. get_gross_profit_report (lãi gộp theo sản phẩm / theo đơn) — chỉ chủ cửa hàng
-- ---------------------------------------------------------------------------

create or replace function inventory.get_gross_profit_report(
  p_tenant_id uuid,
  p_from date,
  p_to date,
  p_mode text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_store_id uuid;
  v_rows jsonb;
  v_loss bigint := 0;
  v_revenue bigint;
  v_deduction bigint;
  v_net bigint;
  v_cogs_sale bigint;
  v_cogs_adjust bigint;
  v_rebate bigint;
  v_cogs_after bigint;
  v_gross bigint;
  v_cogs bigint;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', true);
  v_store_id := (v_actor->>'store_id')::uuid;

  perform inventory._report_range_check(p_from, p_to);

  if p_mode is null or p_mode not in ('PRODUCT', 'ORDER') then
    perform inventory._raise('CONTEXT_INVALID', 'Chế độ báo cáo không hợp lệ.');
  end if;

  if p_mode = 'ORDER' then
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'order_id', o.order_id,
          'order_code', o.order_code,
          'completed_on', o.completed_on,
          'revenue_vnd', o.revenue_vnd,
          'cogs_vnd', o.cogs_vnd,
          'gross_profit_vnd', o.revenue_vnd - o.cogs_vnd,
          'margin_pct', case
            when o.revenue_vnd > 0
              then round((o.revenue_vnd - o.cogs_vnd) * 100.0 / o.revenue_vnd, 1)
            else null
          end,
          'has_provisional', o.has_provisional
        ) order by o.completed_on desc, o.order_code desc
      ),
      '[]'::jsonb
    )
    into v_rows
    from (
      select
        so.id as order_id,
        so.order_code::text as order_code,
        (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as completed_on,
        sum(sol.line_total_minor)::bigint as revenue_vnd,
        coalesce(sum(coalesce(sol.cogs_amount_vnd, 0)), 0)::bigint as cogs_vnd,
        coalesce(bool_or(coalesce(sol.cogs_is_provisional, false)), false) as has_provisional
      from sales.sales_orders so
      join sales.sales_order_lines sol
        on sol.tenant_id = so.tenant_id
       and sol.sales_order_id = so.id
      where so.tenant_id = p_tenant_id
        and so.store_id = v_store_id
        and so.lifecycle_status = 'completed'
        and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
      group by so.id, so.order_code, (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date
    ) o;

    select
      coalesce(sum((e->>'revenue_vnd')::bigint), 0)::bigint,
      coalesce(sum((e->>'cogs_vnd')::bigint), 0)::bigint
    into v_revenue, v_cogs
    from jsonb_array_elements(v_rows) e;

    return jsonb_build_object(
      'from', p_from,
      'to', p_to,
      'as_of', now(),
      'mode', 'ORDER',
      'rows', v_rows,
      'totals', jsonb_build_object(
        'revenue', v_revenue,
        'cogs', v_cogs,
        'gross_profit', v_revenue - v_cogs,
        'margin_pct', case
          when v_revenue > 0 then round((v_revenue - v_cogs) * 100.0 / v_revenue, 1)
          else null
        end
      )
    );
  end if;

  -- PRODUCT -----------------------------------------------------------------
  with parts as (
    -- doanh thu: đơn hoàn tất trong kỳ (kể cả đơn bị huỷ sau đó)
    select sol.product_id,
           sum(sol.line_total_minor)::bigint as revenue,
           0::bigint as deduction, 0::bigint as cogs_sale, 0::bigint as cogs_adjust, 0::bigint as rebate
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id
     and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    group by sol.product_id
    union all
    -- doanh thu: dòng hàng đổi
    select rl.product_id,
           sum(round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor))::bigint,
           0, 0, 0, 0
    from sales.return_exchange_orders rx
    join sales.sales_orders so
      on so.tenant_id = rx.tenant_id
     and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id
     and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'exchange'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    group by rl.product_id
    union all
    -- giảm trừ: hàng trả
    select rl.product_id, 0,
           sum(round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor))::bigint,
           0, 0, 0
    from sales.return_exchange_orders rx
    join sales.sales_orders so
      on so.tenant_id = rx.tenant_id
     and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id
     and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'returned'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    group by rl.product_id
    union all
    -- giảm trừ: đơn huỷ trong kỳ
    select sol.product_id, 0, sum(sol.line_total_minor)::bigint, 0, 0, 0
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id
     and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'cancelled'
      and (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    group by sol.product_id
    union all
    -- giá vốn lúc bán: đọc thẳng sổ giá trị
    select vm.product_id, 0, 0, (-sum(vm.amount_vnd))::bigint, 0, 0
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.kind in ('SALE', 'SALE_REVERSAL', 'RETURN_IN')
      and vm.business_date between p_from and p_to
    group by vm.product_id
    union all
    -- điều chỉnh giá vốn (D5)
    select vm.product_id, 0, 0, 0, (-sum(vm.amount_vnd))::bigint, 0
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.kind = 'COGS_TRUE_UP'
      and vm.business_date between p_from and p_to
    group by vm.product_id
    union all
    -- chiết khấu NCC: chỉ phần đã bán
    select a.product_id, 0, 0, 0, 0, sum(a.cogs_part_vnd)::bigint
    from inventory.supplier_rebate_allocations a
    join inventory.supplier_rebates r
      on r.id = a.rebate_id
     and r.tenant_id = a.tenant_id
    where a.tenant_id = p_tenant_id
      and r.business_date between p_from and p_to
    group by a.product_id
  ),
  agg as (
    select
      pt.product_id,
      sum(pt.revenue)::bigint as revenue,
      sum(pt.deduction)::bigint as deduction,
      sum(pt.cogs_sale)::bigint as cogs_sale,
      sum(pt.cogs_adjust)::bigint as cogs_adjust,
      sum(pt.rebate)::bigint as rebate
    from parts pt
    group by pt.product_id
  ),
  calc as (
    select
      ag.product_id,
      p.name,
      coalesce(p.sku, '') as code,
      ag.revenue,
      ag.deduction,
      (ag.revenue - ag.deduction) as net_revenue,
      ag.cogs_sale,
      ag.cogs_adjust,
      ag.rebate,
      (ag.cogs_sale + ag.cogs_adjust - ag.rebate) as cogs_after
    from agg ag
    join catalog.products p
      on p.tenant_id = p_tenant_id
     and p.id = ag.product_id
    where ag.revenue <> 0 or ag.deduction <> 0 or ag.cogs_sale <> 0 or ag.cogs_adjust <> 0 or ag.rebate <> 0
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', c.product_id,
        'name', c.name,
        'code', c.code,
        'uom', catalog._product_base_unit_name(p_tenant_id, c.product_id),
        'revenue_vnd', c.revenue,
        'deduction_vnd', c.deduction,
        'net_revenue_vnd', c.net_revenue,
        'cogs_at_sale_vnd', c.cogs_sale,
        'cogs_adjust_vnd', c.cogs_adjust,
        'rebate_vnd', c.rebate,
        'cogs_after_vnd', c.cogs_after,
        'gross_profit_vnd', c.net_revenue - c.cogs_after,
        'margin_pct', case
          when c.net_revenue > 0
            then round((c.net_revenue - c.cogs_after) * 100.0 / c.net_revenue, 1)
          else null
        end
      ) order by (c.net_revenue - c.cogs_after) desc, c.name asc, c.product_id asc
    ),
    '[]'::jsonb
  )
  into v_rows
  from calc c;

  -- hao hụt: kiểm kê thiếu / thừa, huỷ hàng, điều chỉnh hao hụt kỳ
  select coalesce(-sum(vm.amount_vnd), 0)::bigint
  into v_loss
  from inventory.value_movements vm
  where vm.tenant_id = p_tenant_id
    and vm.kind in ('COUNT_LOSS', 'WRITE_OFF', 'COUNT_GAIN', 'LOSS_TRUE_UP')
    and vm.business_date between p_from and p_to;

  select
    coalesce(sum((e->>'revenue_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'deduction_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'net_revenue_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'cogs_at_sale_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'cogs_adjust_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'rebate_vnd')::bigint), 0)::bigint,
    coalesce(sum((e->>'cogs_after_vnd')::bigint), 0)::bigint
  into v_revenue, v_deduction, v_net, v_cogs_sale, v_cogs_adjust, v_rebate, v_cogs_after
  from jsonb_array_elements(v_rows) e;

  v_gross := v_net - v_cogs_after;

  return jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'as_of', now(),
    'mode', 'PRODUCT',
    'rows', v_rows,
    'loss_vnd', v_loss,
    'totals', jsonb_build_object(
      'revenue', v_revenue,
      'deduction', v_deduction,
      'net_revenue', v_net,
      'cogs_at_sale', v_cogs_sale,
      'cogs_adjust', v_cogs_adjust,
      'rebate', v_rebate,
      'cogs_after', v_cogs_after,
      'gross_profit', v_gross,
      'margin_pct', case
        when v_net > 0 then round(v_gross * 100.0 / v_net, 1)
        else null
      end,
      'loss', v_loss,
      'profit_after_loss', v_gross - v_loss
    )
  );
end;
$$;

grant execute on function inventory.get_gross_profit_report(uuid, date, date, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. get_supplier_purchase_report (nhập hàng theo NCC) — chỉ chủ cửa hàng
-- ---------------------------------------------------------------------------

create or replace function inventory.get_supplier_purchase_report(
  p_tenant_id uuid,
  p_from date,
  p_to date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, sales, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_suppliers jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', true);

  perform inventory._report_range_check(p_from, p_to);

  with gr as (
    select g.id, g.supplier_id, g.purchase_total_vnd, g.freight_cost_vnd, g.trade_discount_vnd, g.landed_total_vnd
    from inventory.goods_receipts g
    where g.tenant_id = p_tenant_id
      and g.business_date between p_from and p_to
  ),
  rb as (
    select sp.supplier_id, sum(r.rebate_amount_vnd)::bigint as rebate_vnd
    from inventory.supplier_rebates r
    join inventory.supplier_programs sp
      on sp.id = r.program_id
     and sp.tenant_id = r.tenant_id
    where r.tenant_id = p_tenant_id
      and r.business_date between p_from and p_to
    group by sp.supplier_id
  ),
  sup_totals as (
    select
      g.supplier_id,
      count(*)::int as receipt_count,
      sum(g.purchase_total_vnd)::bigint as purchase_vnd,
      sum(g.freight_cost_vnd)::bigint as freight_vnd,
      sum(g.trade_discount_vnd)::bigint as trade_discount_vnd,
      sum(g.landed_total_vnd)::bigint as landed_vnd
    from gr g
    group by g.supplier_id
  ),
  sup_ids as (
    select st.supplier_id from sup_totals st
    union
    select rb.supplier_id from rb
  ),
  prod as (
    select
      g.supplier_id,
      l.product_id,
      sum(l.paid_qty * l.conversion_rate) as paid_qty,
      sum(l.free_qty * l.conversion_rate) as free_qty,
      sum(l.purchase_amount_vnd)::bigint as purchase_vnd,
      sum(l.landed_amount_vnd)::bigint as landed_vnd
    from gr g
    join inventory.goods_receipt_lines l
      on l.receipt_id = g.id
     and l.tenant_id = p_tenant_id
    group by g.supplier_id, l.product_id
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'supplier_id', si.supplier_id,
        'name', pa.display_name,
        'is_system', pa.is_system,
        'receipt_count', coalesce(st.receipt_count, 0),
        'purchase_vnd', coalesce(st.purchase_vnd, 0),
        'freight_vnd', coalesce(st.freight_vnd, 0),
        'trade_discount_vnd', coalesce(st.trade_discount_vnd, 0),
        'landed_vnd', coalesce(st.landed_vnd, 0),
        'rebate_vnd', coalesce(rb.rebate_vnd, 0),
        'products', coalesce(pj.products, '[]'::jsonb)
      ) order by coalesce(st.landed_vnd, 0) desc, pa.display_name asc, si.supplier_id asc
    ),
    '[]'::jsonb
  )
  into v_suppliers
  from sup_ids si
  join partner.partners pa
    on pa.tenant_id = p_tenant_id
   and pa.partner_id = si.supplier_id
  left join sup_totals st on st.supplier_id = si.supplier_id
  left join rb on rb.supplier_id = si.supplier_id
  left join lateral (
    select jsonb_agg(
      jsonb_build_object(
        'product_id', pr.id,
        'name', pr.name,
        'code', coalesce(pr.sku, ''),
        'uom', catalog._product_base_unit_name(p_tenant_id, pr.id),
        'paid_qty', pd.paid_qty,
        'free_qty', pd.free_qty,
        'purchase_vnd', pd.purchase_vnd,
        'landed_vnd', pd.landed_vnd,
        'avg_landed_unit_cost', case
          when pd.paid_qty + pd.free_qty > 0
            then round(pd.landed_vnd::numeric / (pd.paid_qty + pd.free_qty), 4)
          else null
        end
      ) order by pd.landed_vnd desc, pr.name asc, pr.id asc
    ) as products
    from prod pd
    join catalog.products pr
      on pr.tenant_id = p_tenant_id
     and pr.id = pd.product_id
    where pd.supplier_id = si.supplier_id
  ) pj on true;

  return jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'as_of', now(),
    'suppliers', v_suppliers,
    'totals', (
      select jsonb_build_object(
        'purchase', coalesce(sum((e->>'purchase_vnd')::bigint), 0)::bigint,
        'freight', coalesce(sum((e->>'freight_vnd')::bigint), 0)::bigint,
        'trade_discount', coalesce(sum((e->>'trade_discount_vnd')::bigint), 0)::bigint,
        'landed', coalesce(sum((e->>'landed_vnd')::bigint), 0)::bigint,
        'rebate', coalesce(sum((e->>'rebate_vnd')::bigint), 0)::bigint
      )
      from jsonb_array_elements(v_suppliers) e
    )
  );
end;
$$;

grant execute on function inventory.get_supplier_purchase_report(uuid, date, date) to authenticated;
