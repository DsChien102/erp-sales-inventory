-- Test suite for sales.get_home_summary (10-8b Task 1)
-- Run via: tools/db_check.sh home_summary
-- Cases: h1_empty_store, h2_revenue_matches_sales_stats, h3_payment_groups, h4_cancelled_excluded_from_count,
--        h5_uninvoiced, h6_cash_in_includes_debt_collection, h7_receivable, h8_staff_can_read,
--        h9_non_member_denied, h10_other_tenant_excluded
-- Hàm dựng dữ liệu chép từ sales_stats.sql.

create or replace function pg_temp.expect_err(p_sql text, p_code text, p_case text)
returns void
language plpgsql
as $$
begin
  execute p_sql;
  raise exception 'FAIL: %: expected % but no error', p_case, p_code;
exception when others then
  if sqlerrm like 'FAIL: %' then
    raise;
  end if;
  if sqlerrm not like '%' || p_code || '%' then
    raise exception 'FAIL: %: expected %, got %', p_case, p_code, sqlerrm;
  end if;
end;
$$;

create or replace function pg_temp.rep_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create or replace function pg_temp.rep_pay(p_amount bigint)
returns jsonb
language sql
as $$
  select jsonb_build_array(jsonb_build_object(
    'method', 'cash',
    'amount', jsonb_build_object('amount_minor', p_amount, 'currency_code', 'VND')
  ));
$$;

create or replace function pg_temp.rep_finalize(
  p_tenant uuid, p_actor uuid, p_store uuid, p_lines jsonb, p_payments jsonb, p_key text,
  p_customer uuid default null, p_due date default null
)
returns jsonb
language plpgsql
as $$
declare
  v_snap_lines jsonb;
  v_snapshot jsonb;
begin
  select jsonb_agg(jsonb_build_object(
    'lineId', 'line-' || l.ordinality::text,
    'product', jsonb_build_object('productId', l.value ->> 'product_id', 'displayName', 'SP'),
    'unit', jsonb_build_object('productUnitId', l.value ->> 'product_unit_id', 'unitName', coalesce(pu.unit_name, 'DV')),
    'quantityMicros', (l.value ->> 'quantity_micros')::bigint,
    'lineTotal', jsonb_build_object(
      'amountMinor',
      (l.value -> 'unit_price' ->> 'amount_minor')::bigint
        * (l.value ->> 'quantity_micros')::bigint / 1000000
    )
  ) order by l.ordinality)
  into v_snap_lines
  from jsonb_array_elements(p_lines) with ordinality as l(value, ordinality)
  left join catalog.product_units pu on pu.id = (l.value ->> 'product_unit_id')::uuid;

  v_snapshot := jsonb_build_object(
    'store', jsonb_build_object('storeId', p_store::text),
    'seller', jsonb_build_object('actorId', p_actor::text),
    'customer', case when p_customer is null then null
      else jsonb_build_object(
        'customerId', p_customer::text,
        'displayName', (select display_name from partner.partners where partner_id = p_customer))
    end,
    'lines', v_snap_lines
  );

  return sales.finalize_sales_order(
    p_command_id => gen_random_uuid(),
    p_tenant_id => p_tenant,
    p_actor_id => p_actor,
    p_store_id => p_store,
    p_source_draft_id => null,
    p_customer_id => p_customer,
    p_currency_code => 'VND',
    p_order_note => null,
    p_commercial_snapshot => v_snapshot,
    p_lines => p_lines,
    p_payment_intents => coalesce(p_payments, '[]'::jsonb),
    p_idempotency_key => p_key,
    p_payload_hash => 'h',
    p_correlation_id => gen_random_uuid()::text,
    p_payment_due_date => p_due
  );
end;
$$;

create or replace function pg_temp.rep_cancel(p_tenant uuid, p_actor uuid, p_order uuid, p_key text)
returns jsonb
language plpgsql
as $$
declare
  v_ov int;
  v_sv int;
begin
  select version into v_ov from sales.sales_orders where tenant_id = p_tenant and id = p_order;
  select version into v_sv from receivable.sales_order_settlements
    where tenant_id = p_tenant and sales_order_id = p_order
    order by version desc limit 1;
  return sales.confirm_sales_order_cancellation(
    command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    sales_order_id => p_order, reason_text => 'Report test huy',
    idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text,
    expected_order_version => v_ov, expected_settlement_version => v_sv);
end;
$$;

-- Trả `p_qty_micros` của dòng đơn `p_line_id` (phiếu trả hoàn tất); trả về return_exchange_orders.id
-- Thanh toán nhiều phương thức: [[method, amount], ...]
create or replace function pg_temp.rep_pays(p_items jsonb)
returns jsonb
language sql
as $$
  select jsonb_agg(jsonb_build_object(
    'method', i ->> 0,
    'amount', jsonb_build_object('amount_minor', (i ->> 1)::bigint, 'currency_code', 'VND')
  ))
  from jsonb_array_elements(p_items) i;
$$;

-- Dựng một cửa hàng: chủ, kho, cửa hàng, 2 sản phẩm có tồn 100
create or replace function pg_temp.hs_tenant(
  p_owner uuid, p_t uuid, p_store uuid, p_wh uuid,
  p_p1 uuid, p_u1 uuid, p_p2 uuid, p_u2 uuid, p_tag text
)
returns void
language plpgsql
as $$
begin
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (p_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'owner-hs-' || p_tag || '-' || substr(p_owner::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.tenants (id, display_name) values (p_t, 'Home Tenant ' || p_tag);
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (p_t, p_owner, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (p_store, p_t, 'HS' || p_tag, 'Cửa hàng ' || p_tag, 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (p_wh, p_t, 'Kho ' || p_tag, 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (p_t, p_store, p_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', p_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_owner::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by) values (p_t, 'MOVING', p_owner);

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values
    (p_p1, p_t, 'SP Một ' || p_tag, 'HS1-' || p_tag, 'none', false, 'active', true, 'HS-REF1-' || p_tag, p_owner, p_owner),
    (p_p2, p_t, 'SP Hai ' || p_tag, 'HS2-' || p_tag, 'none', false, 'active', true, 'HS-REF2-' || p_tag, p_owner, p_owner);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values (p_u1, p_t, p_p1, 'hộp', 1, true), (p_u2, p_t, p_p2, 'hộp', 1, true);
  perform catalog.set_product_unit_price_band(p_tenant_id => p_t, p_product_id => p_p1, p_product_unit_id => p_u1, p_source_type => 'manual', p_list_price_before_vat => 100000, p_list_price_after_vat => 100000, p_floor_price_before_vat => 10000, p_floor_price_after_vat => 10000);
  perform catalog.set_product_unit_price_band(p_tenant_id => p_t, p_product_id => p_p2, p_product_unit_id => p_u2, p_source_type => 'manual', p_list_price_before_vat => 50000, p_list_price_after_vat => 50000, p_floor_price_before_vat => 5000, p_floor_price_after_vat => 5000);
  update catalog.products set is_ready_to_sell = true where tenant_id = p_t;

  perform inventory._post_movements(
    p_t, p_wh, 'SETUP', gen_random_uuid(), inventory._today(),
    jsonb_build_array(
      jsonb_build_object('product_id', p_p1, 'quantity_delta', 100, 'unit_cost', 40000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', p_p2, 'quantity_delta', 100, 'unit_cost', 20000, 'movement_kind', 'RECEIPT')),
    p_owner);
end;
$$;


create or replace function pg_temp.as_user(p_user uuid)
returns void
language sql
as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  select set_config('request.jwt.claim.sub', p_user::text, true);
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_owner2 uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_outsider uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_t2 uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_store2 uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_wh2 uuid := gen_random_uuid();
  v_p1 uuid := gen_random_uuid();
  v_u1 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_u2 uuid := gen_random_uuid();
  v_q1 uuid := gen_random_uuid();
  v_w1 uuid := gen_random_uuid();
  v_q2 uuid := gen_random_uuid();
  v_w2 uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_cust uuid;
  v_res jsonb;
  v_hs jsonb;
  v_ss jsonb;
  v_o1 uuid;
  v_o2 uuid;
  v_o3 uuid;
  v_o5 uuid;
  v_o6 uuid;
  v_conn uuid;
  v_iss uuid;
  v_att uuid;
  v_day jsonb;
  v_row jsonb;
  v_in_before bigint;
  v_tx uuid;
  v_tx_amount bigint;
  v_tx_context text;
  v_tx_type text;
begin
  -- 1. Fixture --------------------------------------------------------------
  perform pg_temp.hs_tenant(v_owner, v_t, v_store, v_wh, v_p1, v_u1, v_p2, v_u2, 'A');
  perform pg_temp.hs_tenant(v_owner2, v_t2, v_store2, v_wh2, v_q1, v_w1, v_q2, v_w2, 'B');

  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values
    (v_outsider, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'outsider-hs-' || substr(v_outsider::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_staff, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'staff-hs-' || substr(v_staff::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (v_t, v_staff, 'staff', false);

  -- h1_empty_store (tenant B chưa bán gì) -------------------------------------
  perform pg_temp.as_user(v_owner2);
  v_hs := sales.get_home_summary(v_t2);
  if (v_hs->>'today')::date <> v_today then
    raise exception 'FAIL: h1_empty_store today %', v_hs->>'today';
  end if;
  if (v_hs->>'revenue_today')::bigint <> 0 or (v_hs->>'revenue_yesterday')::bigint <> 0
     or (v_hs->>'orders_today')::bigint <> 0 or (v_hs->>'orders_yesterday')::bigint <> 0
     or (v_hs->'orders_by_payment'->>'cash')::bigint <> 0
     or (v_hs->'orders_by_payment'->>'bank')::bigint <> 0
     or (v_hs->'orders_by_payment'->>'debt')::bigint <> 0
     or (v_hs->'cash_in_today'->>'total')::bigint <> 0
     or (v_hs->>'receivable_total')::bigint <> 0
     or (v_hs->>'receivable_overdue_count')::bigint <> 0 then
    raise exception 'FAIL: h1_empty_store numbers must be 0: %', v_hs;
  end if;
  if jsonb_array_length(v_hs->'revenue_week') <> 7
     or (v_hs->'revenue_week'->0->>'day')::date <> v_today - 6
     or (v_hs->'revenue_week'->6->>'day')::date <> v_today
     or exists (select 1 from jsonb_array_elements(v_hs->'revenue_week') e where (e->>'revenue')::bigint <> 0) then
    raise exception 'FAIL: h1_empty_store revenue_week: %', v_hs->'revenue_week';
  end if;
  if v_hs->'orders_uninvoiced' <> 'null'::jsonb then
    raise exception 'FAIL: h1_empty_store orders_uninvoiced must be null without einvoice: %', v_hs->'orders_uninvoiced';
  end if;

  -- Tenant B: 1 đơn (h10)
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q1, v_w1, 1000000, 100000)), pg_temp.rep_pay(100000), 'hs-b1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b1: %', v_res; end if;

  -- Tenant A (chủ A)
  perform pg_temp.as_user(v_owner);
  select c.partner_id into v_cust
  from partner.create_partner(v_t, v_owner, 'person', array['customer'], jsonb_build_object('full_name', 'Khách trang chủ', 'phone', '0988000777')) c;

  -- o1: 100000 tiền mặt đủ → cash
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), pg_temp.rep_pay(100000), 'hs-o1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o1: %', v_res; end if;
  v_o1 := (v_res ->> 'salesOrderId')::uuid;
  -- o2: 50000 chuyển khoản đủ → bank
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p2, v_u2, 1000000, 50000)),
    pg_temp.rep_pays('[["manualBankTransfer", 50000]]'), 'hs-o2');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o2: %', v_res; end if;
  v_o2 := (v_res ->> 'salesOrderId')::uuid;
  -- o3: 100000, trả 30000 tiền mặt, ghi nợ 70000 → debt
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), pg_temp.rep_pay(30000), 'hs-o3', v_cust, v_today + 5);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o3: %', v_res; end if;
  v_o3 := (v_res ->> 'salesOrderId')::uuid;
  -- o4: 400000, tiền mặt 100000 + CK 300000 → bank
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 4000000, 100000)),
    pg_temp.rep_pays('[["cash", 100000], ["manualBankTransfer", 300000]]'), 'hs-o4');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o4: %', v_res; end if;
  -- o5: bán nợ rồi huỷ hôm nay
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p2, v_u2, 1000000, 50000)), '[]'::jsonb, 'hs-o5', v_cust, v_today + 5);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o5: %', v_res; end if;
  v_o5 := (v_res ->> 'salesOrderId')::uuid;
  perform pg_temp.rep_cancel(v_t, v_owner, v_o5, 'hs-c5');
  -- o6: 100000 bán nợ hoàn toàn → debt
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), '[]'::jsonb, 'hs-o6', v_cust, v_today + 5);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o6: %', v_res; end if;
  v_o6 := (v_res ->> 'salesOrderId')::uuid;

  v_hs := sales.get_home_summary(v_t);

  -- h4_cancelled_excluded_from_count: o1, o2, o3, o4, o6 -----------------------
  if (v_hs->>'orders_today')::bigint <> 5 then
    raise exception 'FAIL: h4_cancelled_excluded_from_count expected 5, got %', v_hs->>'orders_today';
  end if;

  -- h3_payment_groups ----------------------------------------------------------
  if (v_hs->'orders_by_payment'->>'cash')::bigint <> 1
     or (v_hs->'orders_by_payment'->>'bank')::bigint <> 2
     or (v_hs->'orders_by_payment'->>'debt')::bigint <> 2 then
    raise exception 'FAIL: h3_payment_groups expected cash 1 bank 2 debt 2: %', v_hs->'orders_by_payment';
  end if;
  if (v_hs->'orders_by_payment'->>'cash')::bigint + (v_hs->'orders_by_payment'->>'bank')::bigint
     + (v_hs->'orders_by_payment'->>'debt')::bigint <> (v_hs->>'orders_today')::bigint then
    raise exception 'FAIL: h3_payment_groups sum must equal orders_today: %', v_hs;
  end if;

  -- h2_revenue_matches_sales_stats --------------------------------------------
  v_ss := sales.get_sales_stats(v_t, 'revenue', 'none', v_today, v_today);
  if (v_hs->>'revenue_today')::bigint <> (v_ss->>'total')::bigint or (v_hs->>'revenue_today')::bigint = 0 then
    raise exception 'FAIL: h2_revenue_matches_sales_stats today % vs %', v_hs->>'revenue_today', v_ss->>'total';
  end if;
  -- lùi o2 về hôm qua: hôm qua có số, tuần vẫn khớp từng ngày
  update sales.sales_orders set completed_at = completed_at - interval '1 day'
  where tenant_id = v_t and id = v_o2;
  v_hs := sales.get_home_summary(v_t);
  v_ss := sales.get_sales_stats(v_t, 'revenue', 'none', v_today - 1, v_today - 1);
  if (v_hs->>'revenue_yesterday')::bigint <> (v_ss->>'total')::bigint or (v_hs->>'revenue_yesterday')::bigint <> 50000 then
    raise exception 'FAIL: h2_revenue_matches_sales_stats yesterday % vs %', v_hs->>'revenue_yesterday', v_ss->>'total';
  end if;
  if (v_hs->>'orders_yesterday')::bigint <> 1 or (v_hs->>'orders_today')::bigint <> 4 then
    raise exception 'FAIL: h2 orders_yesterday/today after shift: %', v_hs;
  end if;
  v_ss := sales.get_sales_stats(v_t, 'revenue', 'day', v_today - 6, v_today);
  for v_day in select e from jsonb_array_elements(v_hs->'revenue_week') e loop
    select e into v_row from jsonb_array_elements(v_ss->'rows') e where e->>'key' = v_day->>'day';
    if coalesce((v_row->>'value')::bigint, 0) <> (v_day->>'revenue')::bigint then
      raise exception 'FAIL: h2_revenue_matches_sales_stats day % : % vs %', v_day->>'day', v_day->>'revenue', v_row;
    end if;
  end loop;
  update sales.sales_orders set completed_at = completed_at + interval '1 day'
  where tenant_id = v_t and id = v_o2;

  -- h6_cash_in_includes_debt_collection ---------------------------------------
  -- lúc bán: tiền mặt o1 100000 + o3 30000 + o4 100000 = 230000; CK o2 50000 + o4 300000 = 350000
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->'cash_in_today'->>'cash')::bigint <> 230000
     or (v_hs->'cash_in_today'->>'bank')::bigint <> 350000
     or (v_hs->'cash_in_today'->>'total')::bigint <> 580000 then
    raise exception 'FAIL: h6_cash_in checkout totals: %', v_hs->'cash_in_today';
  end if;
  v_in_before := (v_hs->'cash_in_today'->>'total')::bigint;
  v_res := receivable.record_customer_collection(
    v_t, v_owner, v_cust, 20000, 'cash', null, array[v_o3], 70000, 'hs-col1');
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->'cash_in_today'->>'total')::bigint <> v_in_before + 20000
     or (v_hs->'cash_in_today'->>'cash')::bigint <> 250000 then
    raise exception 'FAIL: h6_cash_in_includes_debt_collection: % (collection %)', v_hs->'cash_in_today', v_res;
  end if;
  -- cấn trừ không phải tiền: giả lập giao dịch vừa ghi thành cấn trừ khi trả hàng
  -- (ràng buộc sales_payment_tx_offset_source_check: offset chỉ đi với return_exchange / receivable_offset)
  select t.id, t.amount_minor, t.source_context, t.source_type
  into v_tx, v_tx_amount, v_tx_context, v_tx_type
  from receivable.sales_payment_transactions t
  where t.tenant_id = v_t and t.source_context = 'receivable_collection'
  order by t.occurred_at desc limit 1;
  update receivable.sales_payment_transactions
  set payment_method_code = 'offset', source_context = 'return_exchange', source_type = 'receivable_offset'
  where id = v_tx;
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->'cash_in_today'->>'total')::bigint <> v_in_before + 20000 - v_tx_amount then
    raise exception 'FAIL: h6 offset must not count: %', v_hs->'cash_in_today';
  end if;
  update receivable.sales_payment_transactions
  set payment_method_code = 'cash', source_context = v_tx_context, source_type = v_tx_type
  where id = v_tx;

  -- h7_receivable: o3 còn 50000 (hẹn hôm qua), o6 còn 100000 ---------------------
  update receivable.sales_order_settlements set payment_due_date = v_today - 1
  where tenant_id = v_t and sales_order_id = v_o3;
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->>'receivable_total')::bigint <> 150000
     or (v_hs->>'receivable_overdue_count')::bigint <> 1 then
    raise exception 'FAIL: h7_receivable expected 150000 / 1: % / %', v_hs->>'receivable_total', v_hs->>'receivable_overdue_count';
  end if;

  -- h5_uninvoiced: kết nối HĐĐT, o1 có hoá đơn → 5 − 1 = 4 ---------------------
  insert into einvoice.provider_connections (tenant_id, status) values (v_t, 'CONNECTED') returning id into v_conn;
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->>'orders_uninvoiced')::bigint is distinct from 5 then
    raise exception 'FAIL: h5_uninvoiced before invoice expected 5, got %', v_hs->'orders_uninvoiced';
  end if;
  insert into einvoice.invoice_issuances (tenant_id, sales_order_id) values (v_t, v_o1) returning id into v_iss;
  insert into einvoice.issuance_attempts (
    tenant_id, invoice_issuance_id, attempt_no, status, provider_connection_id, invoice_series,
    idempotency_key, intent_hash, snapshot_schema_version, attempt_snapshot, canonical_payload_hash,
    initiated_by_actor_type, initiated_by_actor_id
  ) values (
    v_t, v_iss, 1, 'SUCCEEDED', v_conn, '1C26TAA', 'hs-ei-' || v_iss::text, 'h', 1, '{}'::jsonb, 'h',
    'USER', v_owner
  ) returning id into v_att;
  insert into einvoice.electronic_invoices (
    tenant_id, invoice_issuance_id, successful_attempt_id, sales_order_id, provider_connection_id,
    provider_invoice_reference, invoice_number, invoice_series, issued_at
  ) values (v_t, v_iss, v_att, v_o1, v_conn, 'ref-hs', '0000001', '1C26TAA', now());
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->>'orders_uninvoiced')::bigint is distinct from 4 then
    raise exception 'FAIL: h5_uninvoiced expected 4, got %', v_hs->'orders_uninvoiced';
  end if;

  -- h10_other_tenant_excluded: đơn của B không vào số của A (đã kiểm 5 đơn ở h4) ---
  perform pg_temp.as_user(v_owner2);
  v_hs := sales.get_home_summary(v_t2);
  if (v_hs->>'orders_today')::bigint <> 1 or (v_hs->>'revenue_today')::bigint <> 100000 then
    raise exception 'FAIL: h10_other_tenant_excluded tenant B: %', v_hs;
  end if;

  -- h8_staff_can_read ----------------------------------------------------------
  perform pg_temp.as_user(v_staff);
  v_hs := sales.get_home_summary(v_t);
  if (v_hs->>'orders_today')::bigint <> 5 then
    raise exception 'FAIL: h8_staff_can_read orders_today %', v_hs->>'orders_today';
  end if;
  -- thành viên đã nghỉ thì không đọc được
  update iam.memberships set is_active = false where tenant_id = v_t and user_id = v_staff;
  perform pg_temp.expect_err(format('select sales.get_home_summary(%L)', v_t), 'PERMISSION_DENIED', 'h8b_inactive_member');

  -- h9_non_member_denied -------------------------------------------------------
  perform pg_temp.as_user(v_outsider);
  perform pg_temp.expect_err(format('select sales.get_home_summary(%L)', v_t), 'PERMISSION_DENIED', 'h9_non_member_denied');

  raise notice 'home_summary: OK';
end;
$$;
