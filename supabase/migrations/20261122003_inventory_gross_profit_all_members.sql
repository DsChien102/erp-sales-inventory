-- Title: inventory patch gross profit report open to all store members
-- Kind: patch
-- Intent: inventory_gross_profit_all_members
-- Context: AI-4 Task 4; chưa phân quyền theo vai trò (chốt 2026-11-17), nhất quán với ai.run_query cho mọi thành viên xem giá vốn
-- Touches: get_gross_profit_report
-- Safety: idempotent ; low (chỉ đổi điều kiện quyền, giữ nguyên chữ ký và kết quả)
-- Depends on: 20261119001_inventory_reports

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
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', false);
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
