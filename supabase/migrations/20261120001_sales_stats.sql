-- Title: sales stats RPC for AI assistant (revenue / order count / quantity / avg order value)
-- Kind: schema
-- Intent: sales_stats
-- Context: AI-1 Task 1 (trợ lý "Hỏi VET45"); doanh thu khớp báo cáo lãi gộp G5-7
-- Touches: get_sales_stats
-- Safety: one-shot ; read-only RPC, no new tables
-- Depends on: 20261119001_inventory_reports, 20260830005_sales_rebuild_schema, 20260811014_iam_tenant_membership_lifecycle

create or replace function sales.get_sales_stats(
  p_tenant_id uuid,
  p_metric text,
  p_group_by text,
  p_from date,
  p_to date,
  p_top_n int default 10
)
returns jsonb
language plpgsql
stable
security definer
set search_path = sales, inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_store_id uuid;
  v_top int := least(greatest(coalesce(p_top_n, 10), 1), 20);
  v_time_group boolean;
  v_total numeric;
  v_rev bigint;
  v_qty numeric;
  v_orders bigint;
  v_rows jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'sales.order.view');
  v_store_id := (v_actor->>'store_id')::uuid;

  perform inventory._report_range_check(p_from, p_to);
  if p_to - p_from > 365 then
    perform inventory._raise('CONTEXT_INVALID', 'Khoảng ngày tối đa 366 ngày.');
  end if;

  if p_metric is null or p_metric not in ('revenue', 'order_count', 'quantity', 'avg_order_value') then
    perform inventory._raise('CONTEXT_INVALID', 'Chỉ số không hợp lệ.');
  end if;

  if p_group_by is null
     or p_group_by not in ('none', 'day', 'week', 'month', 'product', 'customer', 'seller') then
    perform inventory._raise('CONTEXT_INVALID', 'Cách nhóm không hợp lệ.');
  end if;

  v_time_group := p_group_by in ('day', 'week', 'month');

  -- Tổng cả kỳ (không nhóm) -------------------------------------------------
  select
    coalesce(sum(f.revenue), 0)::bigint,
    coalesce(sum(f.qty), 0)
  into v_rev, v_qty
  from (
    -- đơn hoàn tất trong kỳ (kể cả đơn bị huỷ sau đó)
    select sol.line_total_minor::bigint as revenue,
           sol.base_quantity_micros / 1000000.0 as qty
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    -- dòng hàng đổi
    select round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
           rl.base_quantity_micros / 1000000.0
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'exchange'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    -- hàng trả
    select -round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
           -(rl.base_quantity_micros / 1000000.0)
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'returned'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    -- đơn huỷ trong kỳ
    select -sol.line_total_minor::bigint,
           -(sol.base_quantity_micros / 1000000.0)
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'cancelled'
      and (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
  ) f;

  select count(*)::bigint
  into v_orders
  from sales.sales_orders so
  where so.tenant_id = p_tenant_id
    and so.store_id = v_store_id
    and so.lifecycle_status = 'completed'
    and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to;

  v_total := case p_metric
    when 'revenue' then v_rev
    when 'order_count' then v_orders
    when 'quantity' then v_qty
    else case when v_orders = 0 then null else round(v_rev::numeric / v_orders) end
  end;

  if p_group_by = 'none' then
    return jsonb_build_object(
      'from', p_from,
      'to', p_to,
      'metric', p_metric,
      'group_by', p_group_by,
      'total', v_total,
      'rows', '[]'::jsonb
    );
  end if;

  -- Theo nhóm ---------------------------------------------------------------
  with facts as (
    select (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ev_date,
           sol.product_id, so.customer_partner_id as customer_id, so.seller_user_id as seller_id,
           sol.line_total_minor::bigint as revenue,
           sol.base_quantity_micros / 1000000.0 as qty,
           0::bigint as orders
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           rl.product_id, so.customer_partner_id, so.seller_user_id,
           round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
           rl.base_quantity_micros / 1000000.0,
           0::bigint
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'exchange'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           rl.product_id, so.customer_partner_id, so.seller_user_id,
           -round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint,
           -(rl.base_quantity_micros / 1000000.0),
           0::bigint
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'returned'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date,
           sol.product_id, so.customer_partner_id, so.seller_user_id,
           -sol.line_total_minor::bigint,
           -(sol.base_quantity_micros / 1000000.0),
           0::bigint
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'cancelled'
      and (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    -- số đơn: mỗi đơn hoàn tất một dòng (nhóm sản phẩm: mỗi cặp đơn - sản phẩm)
    select (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           case when p_group_by = 'product' then sol.product_id end,
           so.customer_partner_id, so.seller_user_id,
           0::bigint, 0::numeric, 1::bigint
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'completed'
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    group by so.id, (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
             case when p_group_by = 'product' then sol.product_id end,
             so.customer_partner_id, so.seller_user_id
  ),
  keyed as (
    select
      case p_group_by
        when 'day' then to_char(f.ev_date, 'YYYY-MM-DD')
        when 'week' then to_char(date_trunc('week', f.ev_date), 'YYYY-MM-DD')
        when 'month' then to_char(f.ev_date, 'YYYY-MM')
        when 'product' then f.product_id::text
        when 'customer' then coalesce(f.customer_id::text, 'walk_in')
        when 'seller' then f.seller_id::text
      end as key,
      f.revenue, f.qty, f.orders
    from facts f
  ),
  agg as (
    select k.key,
           sum(k.revenue)::bigint as revenue,
           sum(k.qty) as qty,
           sum(k.orders)::bigint as orders
    from keyed k
    group by k.key
    having sum(k.revenue) <> 0 or sum(k.qty) <> 0 or sum(k.orders) <> 0
  ),
  valued as (
    select a.key,
           case p_metric
             when 'revenue' then a.revenue::numeric
             when 'order_count' then a.orders::numeric
             when 'quantity' then a.qty
             else case when a.orders = 0 then null else round(a.revenue::numeric / a.orders) end
           end as value
    from agg a
  ),
  labeled as (
    select
      v.key,
      case p_group_by
        when 'product' then coalesce(
          (select p.name from catalog.products p
            where p.tenant_id = p_tenant_id and p.id::text = v.key), v.key)
        when 'customer' then case when v.key = 'walk_in' then 'Khách lẻ' else coalesce(
          (select pt.display_name from partner.partners pt
            where pt.tenant_id = p_tenant_id and pt.partner_id::text = v.key), v.key) end
        when 'seller' then coalesce(
          (select nullif(trim(concat_ws(' ', pr.family_middle_name, pr.given_name)), '')
             from iam.platform_user_profiles pr where pr.user_id::text = v.key), 'Nhân viên')
        else v.key
      end as label,
      v.value
    from valued v
  ),
  ranked as (
    select l.*,
           row_number() over (
             order by
               case when v_time_group then l.key end asc,
               case when not v_time_group then l.value end desc nulls last,
               l.key asc
           ) as rn
    from labeled l
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object('key', r.key, 'label', r.label, 'value', r.value)
      order by r.rn
    ),
    '[]'::jsonb
  )
  into v_rows
  from ranked r
  where v_time_group or r.rn <= v_top;

  return jsonb_build_object(
    'from', p_from,
    'to', p_to,
    'metric', p_metric,
    'group_by', p_group_by,
    'total', v_total,
    'rows', v_rows
  );
end;
$$;

revoke all on function sales.get_sales_stats(uuid, text, text, date, date, int) from public, anon;
grant execute on function sales.get_sales_stats(uuid, text, text, date, date, int) to authenticated;
