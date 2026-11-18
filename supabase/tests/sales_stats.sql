-- Test suite for sales.get_sales_stats (AI-1 Task 1)
-- Run via: tools/db_check.sh --no-reset sales_stats
-- Cases: s1_revenue_matches_gross_profit, s2_order_count_excludes_cancelled, s3_top_products,
--        s4_customer_walk_in, s5_day_keys, s6_avg_order_value, s7/s7b/s8 invalid input,
--        s9_non_member, s10_other_tenant_excluded

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
create or replace function pg_temp.rep_return(
  p_tenant uuid, p_actor uuid, p_order uuid, p_line_id uuid,
  p_product uuid, p_unit uuid, p_qty_micros bigint, p_key text
)
returns uuid
language plpgsql
as $$
declare
  v_rx jsonb;
  v_rx_id uuid;
  v_rx_ver int;
begin
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, p_tenant, p_actor, p_order, 'standard',
    jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', p_line_id,
      'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
      'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    p_key || '-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, p_tenant, p_actor, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, p_tenant, p_actor, v_rx_id,
    p_key || '-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);
  return v_rx_id;
end;
$$;



-- Dựng một cửa hàng: chủ, kho, cửa hàng, 2 sản phẩm có tồn 100
create or replace function pg_temp.ss_tenant(
  p_owner uuid, p_t uuid, p_store uuid, p_wh uuid,
  p_p1 uuid, p_u1 uuid, p_p2 uuid, p_u2 uuid, p_tag text
)
returns void
language plpgsql
as $$
begin
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (p_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'owner-ss-' || p_tag || '-' || substr(p_owner::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.tenants (id, display_name) values (p_t, 'Stats Tenant ' || p_tag);
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (p_t, p_owner, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (p_store, p_t, 'SS' || p_tag, 'Cửa hàng ' || p_tag, 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (p_wh, p_t, 'Kho ' || p_tag, 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (p_t, p_store, p_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', p_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_owner::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by) values (p_t, 'MOVING', p_owner);

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values
    (p_p1, p_t, 'SP Một ' || p_tag, 'SS1-' || p_tag, 'none', false, 'active', true, 'SS-REF1-' || p_tag, p_owner, p_owner),
    (p_p2, p_t, 'SP Hai ' || p_tag, 'SS2-' || p_tag, 'none', false, 'active', true, 'SS-REF2-' || p_tag, p_owner, p_owner);
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

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_owner2 uuid := gen_random_uuid();
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
  v_from date := inventory._today() - 6;
  v_cust uuid;
  v_res jsonb;
  v_gp jsonb;
  v_o1 uuid;
  v_o3 uuid;
  v_o4 uuid;
  v_line3 uuid;
  v_row jsonb;
  v_prev_key text;
  v_n int;
begin
  -- 1. Fixture --------------------------------------------------------------
  perform pg_temp.ss_tenant(v_owner, v_t, v_store, v_wh, v_p1, v_u1, v_p2, v_u2, 'A');
  perform pg_temp.ss_tenant(v_owner2, v_t2, v_store2, v_wh2, v_q1, v_w1, v_q2, v_w2, 'B');

  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (v_outsider, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'outsider-ss-' || substr(v_outsider::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  -- Tenant A (jwt = chủ A)
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  select c.partner_id into v_cust
  from partner.create_partner(v_t, v_owner, 'person', array['customer'], jsonb_build_object('full_name', 'Khách thống kê', 'phone', '0988000999')) c;

  -- o1: SP Một x1 100000, có khách, trả đủ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), pg_temp.rep_pay(100000), 'ss-o1', v_cust, null);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o1: %', v_res; end if;
  v_o1 := (v_res ->> 'salesOrderId')::uuid;

  -- o2: SP Hai x1 50000, khách lẻ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p2, v_u2, 1000000, 50000)), pg_temp.rep_pay(50000), 'ss-o2');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o2: %', v_res; end if;

  -- o3: SP Một x2 200000, khách lẻ; rồi trả 1
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 2000000, 100000)), pg_temp.rep_pay(200000), 'ss-o3');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o3: %', v_res; end if;
  v_o3 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_line3 from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_o3;
  perform pg_temp.rep_return(v_t, v_owner, v_o3, v_line3, v_p1, v_u1, 1000000, 'ss-r1');

  -- o4: SP Một x1, bán nợ rồi huỷ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), '[]'::jsonb, 'ss-o4', v_cust, v_today + 5);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o4: %', v_res; end if;
  v_o4 := (v_res ->> 'salesOrderId')::uuid;
  perform pg_temp.rep_cancel(v_t, v_owner, v_o4, 'ss-c4');

  -- Tenant B (jwt = chủ B): 2 đơn 100000 + 50000
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner2::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner2::text, true);
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q1, v_w1, 1000000, 100000)), pg_temp.rep_pay(100000), 'ss-b1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b1: %', v_res; end if;
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q2, v_w2, 1000000, 50000)), pg_temp.rep_pay(50000), 'ss-b2');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b2: %', v_res; end if;

  -- Quay lại chủ A
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- s1_revenue_matches_gross_profit ------------------------------------------
  v_res := sales.get_sales_stats(v_t, 'revenue', 'none', v_from, v_today);
  v_gp := inventory.get_gross_profit_report(v_t, v_from, v_today, 'PRODUCT');
  if (v_res->>'total')::bigint <> (v_gp->'totals'->>'net_revenue')::bigint then
    raise exception 'FAIL: s1_revenue_matches_gross_profit % vs %', v_res->>'total', v_gp->'totals'->>'net_revenue';
  end if;
  if (v_res->>'total')::bigint = 0 then
    raise exception 'FAIL: s1_revenue_matches_gross_profit total must not be 0';
  end if;
  if jsonb_array_length(v_res->'rows') <> 0 then
    raise exception 'FAIL: s1 group none must have empty rows';
  end if;

  -- s2_order_count_excludes_cancelled ----------------------------------------
  v_res := sales.get_sales_stats(v_t, 'order_count', 'none', v_from, v_today);
  if (v_res->>'total')::bigint <> 3 then
    raise exception 'FAIL: s2_order_count_excludes_cancelled expected 3, got %', v_res->>'total';
  end if;

  -- s3_top_products ----------------------------------------------------------
  v_res := sales.get_sales_stats(v_t, 'revenue', 'product', v_from, v_today, 2);
  if jsonb_array_length(v_res->'rows') <> 2 then
    raise exception 'FAIL: s3_top_products expected 2 rows: %', v_res;
  end if;
  if (v_res->'rows'->0->>'value')::numeric < (v_res->'rows'->1->>'value')::numeric then
    raise exception 'FAIL: s3_top_products must be descending: %', v_res;
  end if;
  if v_res->'rows'->0->>'label' <> 'SP Một A' then
    raise exception 'FAIL: s3_top_products label expected "SP Một A", got %', v_res->'rows'->0->>'label';
  end if;

  -- s4_customer_walk_in ------------------------------------------------------
  v_res := sales.get_sales_stats(v_t, 'order_count', 'customer', v_from, v_today);
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'key' = 'walk_in';
  if v_row is null or v_row->>'label' <> 'Khách lẻ' then
    raise exception 'FAIL: s4_customer_walk_in missing walk_in row: %', v_res;
  end if;
  if (v_row->>'value')::int <> 2 then
    raise exception 'FAIL: s4_customer_walk_in expected 2 walk-in orders: %', v_row;
  end if;
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'key' = v_cust::text;
  if v_row is null or v_row->>'label' <> 'Khách thống kê' then
    raise exception 'FAIL: s4_customer_walk_in missing named customer row: %', v_res;
  end if;

  -- s11_quantity: o1 1 + o2 1 + o3 2 - trả 1 + (o4 hoàn tất rồi huỷ trong kỳ: +1 -1) = 3
  v_res := sales.get_sales_stats(v_t, 'quantity', 'none', v_from, v_today);
  if (v_res->>'total')::numeric <> 3 then
    raise exception 'FAIL: s11_quantity total expected 3, got %', v_res->>'total';
  end if;
  v_res := sales.get_sales_stats(v_t, 'quantity', 'product', v_from, v_today);
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'key' = v_p1::text;
  if v_row is null or (v_row->>'value')::numeric <> 2 then
    raise exception 'FAIL: s11_quantity SP Một expected 2: %', v_res;
  end if;

  -- s12_seller: một nhân viên bán cả 3 đơn, nhãn không rỗng
  v_res := sales.get_sales_stats(v_t, 'order_count', 'seller', v_from, v_today);
  if jsonb_array_length(v_res->'rows') <> 1
     or v_res->'rows'->0->>'key' <> v_owner::text
     or coalesce(v_res->'rows'->0->>'label', '') = ''
     or (v_res->'rows'->0->>'value')::int <> 3 then
    raise exception 'FAIL: s12_seller %', v_res;
  end if;

  -- s5_day_keys: lùi o1 về hôm qua ⇒ 2 dòng, key tăng dần, ngày không có đơn không có dòng
  update sales.sales_orders
  set completed_at = completed_at - interval '1 day'
  where tenant_id = v_t and id = v_o1;

  v_res := sales.get_sales_stats(v_t, 'order_count', 'day', v_today - 3, v_today);
  if jsonb_array_length(v_res->'rows') <> 2
     or v_res->'rows'->0->>'key' <> to_char(v_today - 1, 'YYYY-MM-DD')
     or v_res->'rows'->1->>'key' <> to_char(v_today, 'YYYY-MM-DD')
     or (v_res->'rows'->0->>'value')::int <> 1
     or (v_res->'rows'->1->>'value')::int <> 2 then
    raise exception 'FAIL: s5_day_keys expected [yesterday:1, today:2]: %', v_res;
  end if;
  v_res := sales.get_sales_stats(v_t, 'revenue', 'month', v_from, v_today);
  if v_res->'rows'->0->>'key' <> to_char(v_today - 1, 'YYYY-MM')
     and v_res->'rows'->0->>'key' <> to_char(v_today, 'YYYY-MM') then
    raise exception 'FAIL: s5_day_keys month key: %', v_res;
  end if;
  v_res := sales.get_sales_stats(v_t, 'revenue', 'week', v_from, v_today);
  if (v_res->'rows'->(jsonb_array_length(v_res->'rows') - 1)->>'key')::date <> date_trunc('week', v_today)::date then
    raise exception 'FAIL: s5_day_keys last week key must be this Monday: %', v_res;
  end if;
  -- doanh thu vẫn khớp báo cáo lãi gộp sau khi lùi ngày
  v_res := sales.get_sales_stats(v_t, 'revenue', 'none', v_from, v_today);
  v_gp := inventory.get_gross_profit_report(v_t, v_from, v_today, 'PRODUCT');
  if (v_res->>'total')::bigint <> (v_gp->'totals'->>'net_revenue')::bigint then
    raise exception 'FAIL: s5_day_keys revenue must still match gross profit';
  end if;

  -- s6_avg_order_value (tenant B: 100000 + 50000) -----------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner2::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner2::text, true);
  v_res := sales.get_sales_stats(v_t2, 'avg_order_value', 'none', v_from, v_today);
  if (v_res->>'total')::bigint <> 75000 then
    raise exception 'FAIL: s6_avg_order_value expected 75000, got %', v_res->>'total';
  end if;
  v_res := sales.get_sales_stats(v_t2, 'revenue', 'none', v_from, v_today);
  if (v_res->>'total')::bigint <> 150000 then
    raise exception 'FAIL: s10_other_tenant_excluded tenant B revenue expected 150000, got %', v_res->>'total';
  end if;
  -- s10: tenant A không lẫn đơn của B (đã kiểm ở s2: đúng 3 đơn)
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  v_res := sales.get_sales_stats(v_t, 'order_count', 'none', v_from, v_today);
  if (v_res->>'total')::bigint <> 3 then
    raise exception 'FAIL: s10_other_tenant_excluded tenant A order_count %', v_res->>'total';
  end if;

  -- s7 / s7b / s8 ------------------------------------------------------------
  perform pg_temp.expect_err(
    format('select sales.get_sales_stats(%L, %L, %L, %L::date, %L::date)', v_t, 'profit', 'none', v_from, v_today),
    'CONTEXT_INVALID', 's7_bad_metric');
  perform pg_temp.expect_err(
    format('select sales.get_sales_stats(%L, %L, %L, %L::date, %L::date)', v_t, 'revenue', 'region', v_from, v_today),
    'CONTEXT_INVALID', 's7b_bad_group');
  perform pg_temp.expect_err(
    format('select sales.get_sales_stats(%L, %L, %L, %L::date, %L::date)', v_t, 'revenue', 'none', v_today, v_from),
    'CONTEXT_INVALID', 's8_bad_range from > to');
  perform pg_temp.expect_err(
    format('select sales.get_sales_stats(%L, %L, %L, %L::date, %L::date)', v_t, 'revenue', 'none', v_today - 366, v_today),
    'CONTEXT_INVALID', 's8_bad_range > 366 days');
  -- đúng 366 ngày vẫn được
  perform sales.get_sales_stats(v_t, 'revenue', 'none', v_today - 365, v_today);

  -- s9_non_member ------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_outsider::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_outsider::text, true);
  perform pg_temp.expect_err(
    format('select sales.get_sales_stats(%L, %L, %L, %L::date, %L::date)', v_t, 'revenue', 'none', v_from, v_today),
    'PERMISSION_DENIED', 's9_non_member');

  raise notice 'sales_stats: OK';
end;
$$;
