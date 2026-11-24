-- Title: home summary RPC for Trang chủ "Bảng giá chợ" (APP-01)
-- Kind: schema
-- Intent: sales_home_summary
-- Context: 10-8b Task 1; doanh thu cùng công thức get_sales_stats metric revenue
-- Touches: _daily_revenue, get_home_summary
-- Safety: one-shot ; read-only RPC, no new tables
-- Depends on: 20261120001_sales_stats, 20261123001_receivable_move_money_tables, 20261124002_receivable_return_offsets, 20261031001_einvoice_configuration_schema

-- Doanh thu theo ngày (Asia/Ho_Chi_Minh): chép đúng 4 nhánh của get_sales_stats
-- (đơn hoàn tất theo completed_at, dòng đổi +, dòng trả −, đơn huỷ − theo cancelled_at).
create or replace function sales._daily_revenue(
  p_tenant_id uuid,
  p_store_id uuid,
  p_from date,
  p_to date
)
returns table (day date, revenue_minor bigint)
language sql
stable
security definer
set search_path = sales, pg_temp
as $$
  select f.ev_date, coalesce(sum(f.revenue), 0)::bigint
  from (
    select (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date as ev_date,
           sol.line_total_minor::bigint as revenue
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = p_store_id
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = p_store_id
      and rx.status = 'completed'
      and rl.line_role = 'exchange'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date,
           -round(rl.quantity_micros::numeric / 1000000.0 * rl.unit_value_minor)::bigint
    from sales.return_exchange_orders rx
    join sales.sales_orders so on so.tenant_id = rx.tenant_id and so.id = rx.sales_order_id
    join sales.return_exchange_lines rl
      on rl.tenant_id = rx.tenant_id and rl.return_exchange_order_id = rx.id
    where rx.tenant_id = p_tenant_id
      and so.store_id = p_store_id
      and rx.status = 'completed'
      and rl.line_role = 'returned'
      and (rx.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
    union all
    select (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date,
           -sol.line_total_minor::bigint
    from sales.sales_orders so
    join sales.sales_order_lines sol
      on sol.tenant_id = so.tenant_id and sol.sales_order_id = so.id
    where so.tenant_id = p_tenant_id
      and so.store_id = p_store_id
      and so.lifecycle_status = 'cancelled'
      and (so.cancelled_at at time zone 'Asia/Ho_Chi_Minh')::date between p_from and p_to
  ) f
  group by f.ev_date;
$$;
revoke all on function sales._daily_revenue(uuid, uuid, date, date) from public, anon, authenticated;

create or replace function sales.get_home_summary(p_tenant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = sales, receivable, inventory, iam, einvoice, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_store_id uuid;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_week jsonb;
  v_rev_today bigint;
  v_rev_yesterday bigint;
  v_orders_today bigint;
  v_orders_yesterday bigint;
  v_cash bigint;
  v_bank bigint;
  v_debt bigint;
  v_uninvoiced bigint;
  v_in_cash bigint;
  v_in_bank bigint;
  v_recv_total bigint;
  v_recv_overdue bigint;
begin
  -- Q1: mọi thành viên đang hoạt động của tenant
  if v_actor is null or not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_actor
      and iam._membership_status_code(m.is_active, m.removed_at) = 'active'
  ) then
    perform inventory._raise('PERMISSION_DENIED', 'Bạn không thuộc tổ chức này.');
  end if;

  begin
    select a.store_id into strict v_store_id
    from inventory.store_warehouse_assignments a
    where a.tenant_id = p_tenant_id
      and a.status = 'active';
  exception
    when no_data_found then
      perform inventory._raise('CONTEXT_INVALID', 'Active store warehouse assignment not found.');
    when too_many_rows then
      perform inventory._raise('CONTEXT_INVALID', 'Multiple active store warehouse assignments found, expected exactly one.');
  end;

  -- Q2: doanh thu 7 ngày (đủ 7 phần tử, cũ → mới)
  select jsonb_agg(jsonb_build_object('day', d.day, 'revenue', coalesce(r.revenue_minor, 0)) order by d.day)
  into v_week
  from generate_series(v_today - 6, v_today, interval '1 day') as g(ts)
  cross join lateral (select g.ts::date as day) d
  left join sales._daily_revenue(p_tenant_id, v_store_id, v_today - 6, v_today) r on r.day = d.day;

  select coalesce(sum(r.revenue_minor) filter (where r.day = v_today), 0),
         coalesce(sum(r.revenue_minor) filter (where r.day = v_today - 1), 0)
  into v_rev_today, v_rev_yesterday
  from sales._daily_revenue(p_tenant_id, v_store_id, v_today - 1, v_today) r;

  -- Q3: số đơn hoàn tất
  select count(*) filter (where (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today),
         count(*) filter (where (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today - 1)
  into v_orders_today, v_orders_yesterday
  from sales.sales_orders so
  where so.tenant_id = p_tenant_id
    and so.store_id = v_store_id
    and so.lifecycle_status = 'completed'
    and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date between v_today - 1 and v_today;

  -- Q4: cách trả của đơn hôm nay (một đơn một nhóm)
  with today_orders as (
    select so.id, so.payable_amount_minor
    from sales.sales_orders so
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'completed'
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today
  ),
  paid as (
    select s.sales_order_id,
           sum(t.amount_minor) filter (where t.payment_method_code = 'cash') as cash_minor,
           sum(t.amount_minor) filter (where t.payment_method_code <> 'cash') as bank_minor,
           sum(t.amount_minor) as total_minor
    from receivable.sales_payment_transactions t
    join receivable.sales_order_settlements s
      on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
    where t.tenant_id = p_tenant_id
      and s.sales_order_id in (select id from today_orders)
      and t.source_context = 'checkout'
      and t.transaction_type = 'collection'
      and t.status = 'confirmed'
      and t.payment_method_code <> 'offset'
    group by s.sales_order_id
  ),
  grouped as (
    select case
             when o.payable_amount_minor = 0 then 'cash'
             when coalesce(p.total_minor, 0) < o.payable_amount_minor then 'debt'
             when coalesce(p.bank_minor, 0) > coalesce(p.cash_minor, 0) then 'bank'
             else 'cash'
           end as grp
    from today_orders o
    left join paid p on p.sales_order_id = o.id
  )
  select count(*) filter (where grp = 'cash'),
         count(*) filter (where grp = 'bank'),
         count(*) filter (where grp = 'debt')
  into v_cash, v_bank, v_debt
  from grouped;

  -- Q5: chưa xuất hoá đơn (null khi chưa kết nối HĐĐT)
  if exists (
    select 1 from einvoice.provider_connections pc
    where pc.tenant_id = p_tenant_id and pc.status <> 'DISCONNECTED'
  ) then
    select count(*)
    into v_uninvoiced
    from sales.sales_orders so
    where so.tenant_id = p_tenant_id
      and so.store_id = v_store_id
      and so.lifecycle_status = 'completed'
      and (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today
      and not exists (
        select 1 from einvoice.electronic_invoices ei
        where ei.tenant_id = so.tenant_id and ei.sales_order_id = so.id
      );
  else
    v_uninvoiced := null;
  end if;

  -- Q6: tiền đã thu hôm nay, mọi nguồn, bỏ cấn trừ
  select coalesce(sum(t.amount_minor) filter (where t.payment_method_code = 'cash'), 0),
         coalesce(sum(t.amount_minor) filter (where t.payment_method_code <> 'cash'), 0)
  into v_in_cash, v_in_bank
  from receivable.sales_payment_transactions t
  join receivable.sales_order_settlements s
    on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
  join sales.sales_orders so
    on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
  where t.tenant_id = p_tenant_id
    and so.store_id = v_store_id
    and t.transaction_type = 'collection'
    and t.status = 'confirmed'
    and t.payment_method_code <> 'offset'
    and (t.occurred_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today;

  -- Q7: công nợ phải thu
  select coalesce(sum(o.outstanding_minor), 0),
         count(*) filter (where o.due_date < v_today)
  into v_recv_total, v_recv_overdue
  from receivable._open_orders(p_tenant_id, v_actor) o;

  return jsonb_build_object(
    'today', v_today,
    'revenue_today', v_rev_today,
    'revenue_yesterday', v_rev_yesterday,
    'revenue_week', v_week,
    'orders_today', v_orders_today,
    'orders_yesterday', v_orders_yesterday,
    'orders_by_payment', jsonb_build_object('cash', v_cash, 'bank', v_bank, 'debt', v_debt),
    'orders_uninvoiced', v_uninvoiced,
    'cash_in_today', jsonb_build_object('total', v_in_cash + v_in_bank, 'cash', v_in_cash, 'bank', v_in_bank),
    'receivable_total', v_recv_total,
    'receivable_overdue_count', v_recv_overdue
  );
end;
$$;
revoke all on function sales.get_home_summary(uuid) from public, anon;
grant execute on function sales.get_home_summary(uuid) to authenticated;
