-- Title: purchase forecast RPC for AI assistant (daily sell rate, days left, suggested reorder qty)
-- Kind: schema
-- Intent: inventory_purchase_forecast
-- Context: AI-3 Task 1 (trợ lý "Hỏi VET45"); tốc độ bán 8 tuần có trọng số, cùng cách tính get_sales_stats (quantity)
-- Touches: get_purchase_forecast
-- Safety: one-shot ; read-only RPC, no new tables, no money / cost in output
-- Depends on: 20261120001_sales_stats, 20261112001_inventory_stock_view, 20261111001_inventory_stock_policy

create or replace function inventory.get_purchase_forecast(
  p_tenant_id uuid,
  p_product_id uuid default null,
  p_only_need_reorder boolean default true,
  p_limit int default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, sales, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_store_id uuid;
  v_today date := inventory._today();
  v_limit int := least(greatest(coalesce(p_limit, 20), 1), 20);
  v_need_count int;
  v_rows jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_store_id := (v_actor->>'store_id')::uuid;

  if p_product_id is not null and not exists (
    select 1 from catalog.products p
    where p.tenant_id = p_tenant_id and p.id = p_product_id
  ) then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không thuộc cửa hàng này.');
  end if;

  with facts as (
    select (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ev_date,
           sol.product_id,
           sol.base_quantity_micros / 1000000.0 as qty
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between v_today - 55 and v_today
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           rl.product_id,
           rl.base_quantity_micros / 1000000.0
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'exchange'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between v_today - 55 and v_today
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           rl.product_id,
           -(rl.base_quantity_micros / 1000000.0)
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and rx.status = 'completed'
      and rl.line_role = 'returned'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between v_today - 55 and v_today
    union all
    select (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date,
           sol.product_id,
           -(sol.base_quantity_micros / 1000000.0)
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'cancelled'
      and (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date between v_today - 55 and v_today
  ),
  sold as (
    select f.product_id,
           sum(f.qty) as qty_8w,
           sum((8 - ((v_today - f.ev_date) / 7)) * f.qty) as weighted
    from facts f
    group by f.product_id
  ),
  base as (
    select p.id as product_id,
           p.name,
           coalesce(p.sku, '') as code,
           catalog._product_base_unit_name(p_tenant_id, p.id) as uom,
           sr.available,
           psp.reorder_threshold,
           psp.target_level,
           coalesce(s.qty_8w, 0) as qty_8w,
           greatest(0, coalesce(s.weighted, 0) / (7 * 36.0)) as rate
    from catalog.products p
    join inventory._product_stock_rows(p_tenant_id) sr on sr.product_id = p.id
    left join inventory.product_stock_policies psp
      on psp.tenant_id = p_tenant_id and psp.product_id = p.id
    left join sold s on s.product_id = p.id
    where p.tenant_id = p_tenant_id
      and p.deleted_at is null
      and p.business_status = 'active'
  ),
  calc as (
    select b.*,
           (b.reorder_threshold is not null and b.available <= b.reorder_threshold) as needs,
           case
             when b.available <= 0 then 0::numeric
             when b.rate = 0 then null
             else round(b.available / b.rate, 1)
           end as days_left,
           case
             when b.reorder_threshold is null then null
             when b.available <= b.reorder_threshold then ceil(b.target_level - b.available)
             else 0::numeric
           end as suggest_qty
    from base b
  ),
  picked as (
    select c.*
    from calc c
    where case
            when p_product_id is not null then c.product_id = p_product_id
            when coalesce(p_only_need_reorder, true) then c.needs
            else true
          end
    order by c.days_left asc nulls last, c.name asc
    limit v_limit
  )
  select
    (select count(*) from calc where needs)::int,
    coalesce(
      (select jsonb_agg(
         jsonb_build_object(
           'product_id', pk.product_id,
           'name', pk.name,
           'code', pk.code,
           'uom', pk.uom,
           'available', pk.available,
           'reorder_threshold', pk.reorder_threshold,
           'target_level', pk.target_level,
           'qty_8w', pk.qty_8w,
           'daily_rate', round(pk.rate, 1),
           'days_left', pk.days_left,
           'suggest_qty', pk.suggest_qty
         ) order by pk.days_left asc nulls last, pk.name asc)
       from picked pk),
      '[]'::jsonb)
  into v_need_count, v_rows;

  return jsonb_build_object(
    'as_of', now(),
    'weeks', 8,
    'need_reorder_count', v_need_count,
    'rows', v_rows
  );
end;
$$;

revoke all on function inventory.get_purchase_forecast(uuid, uuid, boolean, int) from public, anon;
grant execute on function inventory.get_purchase_forecast(uuid, uuid, boolean, int) to authenticated;
