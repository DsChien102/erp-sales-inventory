-- Test suite for inventory.get_purchase_forecast (AI-3 Task 1)
-- Run on Dev: psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_purchase_forecast.sql
-- Bọc begin/rollback: fixture không ở lại DB.
-- Cases: f1..f9 (xem plan AI-3 Task 1)
begin;


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
  v_cashier uuid := gen_random_uuid();
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
  v_p3 uuid := gen_random_uuid();
  v_u3 uuid := gen_random_uuid();
  v_q1 uuid := gen_random_uuid();
  v_w1 uuid := gen_random_uuid();
  v_q2 uuid := gen_random_uuid();
  v_w2 uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_res jsonb;
  v_row jsonb;
  v_o1 uuid;
  v_o1_line uuid;
  v_sum numeric;
  v_stats numeric;
begin
  -- Fixture ------------------------------------------------------------------
  perform pg_temp.ss_tenant(v_owner, v_t, v_store, v_wh, v_p1, v_u1, v_p2, v_u2, 'FA');
  perform pg_temp.ss_tenant(v_owner2, v_t2, v_store2, v_wh2, v_q1, v_w1, v_q2, v_w2, 'FB');

  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values
    (v_cashier, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'cashier-fc-' || substr(v_cashier::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_outsider, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'outsider-fc-' || substr(v_outsider::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (v_t, v_cashier, 'staff', false);

  -- Tenant A (jwt = chủ A)
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- SP3: ngưỡng 10 / mục tiêu 50, tồn 0 (nhập 5 rồi bán hết 5 ⇒ có bán)
  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values (v_p3, v_t, 'SP Ba FA', 'SS3-FA', 'none', false, 'active', true, 'SS-REF3-FA', v_owner, v_owner);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values (v_u3, v_t, v_p3, 'hộp', 1, true);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_p3, p_product_unit_id => v_u3, p_source_type => 'manual', p_list_price_before_vat => 30000, p_list_price_after_vat => 30000, p_floor_price_before_vat => 3000, p_floor_price_after_vat => 3000);
  update catalog.products set is_ready_to_sell = true where tenant_id = v_t;
  perform inventory._post_movements(
    v_t, v_wh, 'SETUP', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p3, 'quantity_delta', 5, 'unit_cost', 10000, 'movement_kind', 'RECEIPT')),
    v_owner);
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p3, v_u3, 5000000, 30000)), pg_temp.rep_pay(150000), 'fc-o3');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o3: %', v_res; end if;

  insert into inventory.product_stock_policies (tenant_id, product_id, reorder_threshold, target_level, updated_by)
  values (v_t, v_p1, 80, 200, v_owner), (v_t, v_p3, 10, 50, v_owner);

  -- SP1: đơn 14 hộp hôm nay + đơn 14 hộp lùi 52 ngày
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 14000000, 100000)), pg_temp.rep_pay(1400000), 'fc-o1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o1: %', v_res; end if;
  v_o1 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_o1_line from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_o1;
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 14000000, 100000)), pg_temp.rep_pay(1400000), 'fc-o1b');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o1b: %', v_res; end if;
  update sales.sales_orders set completed_at = completed_at - interval '52 days'
  where tenant_id = v_t and id = (v_res ->> 'salesOrderId')::uuid;

  -- Tenant B có bán SP riêng (không được lọt vào A)
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner2::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner2::text, true);
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q1, v_w1, 7000000, 100000)), pg_temp.rep_pay(700000), 'fc-b1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b1: %', v_res; end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- f1_weighted_rate / f2_days_left_and_suggest -------------------------------
  v_res := inventory.get_purchase_forecast(v_t, null, false, 20);
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'product_id' = v_p1::text;
  if v_row is null then raise exception 'FAIL: f1 SP1 missing: %', v_res; end if;
  if (v_row->>'daily_rate')::numeric <> 0.5 or (v_row->>'qty_8w')::numeric <> 28 then
    raise exception 'FAIL: f1_weighted_rate %', v_row;
  end if;
  if (v_row->>'available')::numeric <> 72 or (v_row->>'days_left')::numeric <> 144.0
     or (v_row->>'suggest_qty')::numeric <> 128 then
    raise exception 'FAIL: f2_days_left_and_suggest %', v_row;
  end if;

  -- f3b_out_of_stock ----------------------------------------------------------
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'product_id' = v_p3::text;
  if (v_row->>'available')::numeric <> 0 or (v_row->>'days_left')::numeric <> 0
     or (v_row->>'suggest_qty')::numeric <> 50 then
    raise exception 'FAIL: f3b_out_of_stock %', v_row;
  end if;

  -- f3c_no_policy / f4_no_sales ----------------------------------------------
  select e into v_row from jsonb_array_elements(v_res->'rows') e where e->>'product_id' = v_p2::text;
  if v_row is null or jsonb_typeof(v_row->'suggest_qty') <> 'null'
     or jsonb_typeof(v_row->'reorder_threshold') <> 'null' then
    raise exception 'FAIL: f3c_no_policy %', v_row;
  end if;
  if (v_row->>'daily_rate')::numeric <> 0 or jsonb_typeof(v_row->'days_left') <> 'null' then
    raise exception 'FAIL: f4_no_sales %', v_row;
  end if;

  -- f6_matches_sales_stats (trước khi trả hàng) --------------------------------
  select coalesce(sum((e->>'qty_8w')::numeric), 0) into v_sum from jsonb_array_elements(v_res->'rows') e;
  v_stats := (sales.get_sales_stats(v_t, 'quantity', 'none', v_today - 55, v_today)->>'total')::numeric;
  if v_sum <> v_stats then
    raise exception 'FAIL: f6_matches_sales_stats % vs %', v_sum, v_stats;
  end if;

  -- f7_count_and_limit ---------------------------------------------------------
  v_res := inventory.get_purchase_forecast(v_t, null, true, 20);
  if (v_res->>'need_reorder_count')::int <> 2 then
    raise exception 'FAIL: f7 need_reorder_count expected 2 (SP1, SP3): %', v_res;
  end if;
  v_res := inventory.get_purchase_forecast(v_t, null, true, 1);
  if (v_res->>'need_reorder_count')::int <> 2 or jsonb_array_length(v_res->'rows') <> 1 then
    raise exception 'FAIL: f7_count_and_limit limit 1: %', v_res;
  end if;
  if v_res->'rows'->0->>'product_id' <> v_p3::text then
    raise exception 'FAIL: f7 sort days_left asc expected SP3 first: %', v_res;
  end if;
  perform inventory.get_purchase_forecast(v_t, null, false, 99);

  -- f3_above_threshold: nâng tồn SP1 lên 90 ------------------------------------
  perform inventory._post_movements(
    v_t, v_wh, 'SETUP', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p1, 'quantity_delta', 18, 'unit_cost', 40000, 'movement_kind', 'RECEIPT')),
    v_owner);
  v_res := inventory.get_purchase_forecast(v_t, null, true, 20);
  if exists (select 1 from jsonb_array_elements(v_res->'rows') e where e->>'product_id' = v_p1::text) then
    raise exception 'FAIL: f3_above_threshold SP1 must not be listed: %', v_res;
  end if;
  v_res := inventory.get_purchase_forecast(v_t, v_p1, true, 20);
  if jsonb_array_length(v_res->'rows') <> 1 or (v_res->'rows'->0->>'suggest_qty')::numeric <> 0 then
    raise exception 'FAIL: f3_above_threshold / f7 single product: %', v_res;
  end if;

  -- f5_returns_reduce_rate: trả 2 hộp của đơn hôm nay -------------------------
  perform pg_temp.rep_return(v_t, v_owner, v_o1, v_o1_line, v_p1, v_u1, 2000000, 'fc-r1');
  v_res := inventory.get_purchase_forecast(v_t, v_p1, true, 20);
  v_row := v_res->'rows'->0;
  if (v_row->>'qty_8w')::numeric <> 26 or (v_row->>'daily_rate')::numeric <> round(110 / 252.0, 1)
     or (v_row->>'daily_rate')::numeric < 0 then
    raise exception 'FAIL: f5_returns_reduce_rate %', v_row;
  end if;
  if (v_row->>'days_left')::numeric <> round((v_row->>'available')::numeric / (110 / 252.0), 1) then
    raise exception 'FAIL: f5 days_left %', v_row;
  end if;

  -- f8_cashier_ok --------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', v_cashier::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_cashier::text, true);
  v_res := inventory.get_purchase_forecast(v_t, null, false, 20);
  if jsonb_array_length(v_res->'rows') < 3 then
    raise exception 'FAIL: f8_cashier_ok %', v_res;
  end if;

  -- f9_other_tenant -------------------------------------------------------------
  perform pg_temp.expect_err(
    format('select inventory.get_purchase_forecast(%L, %L)', v_t, v_q1),
    'CONTEXT_INVALID', 'f9 product of other tenant');
  select coalesce(sum((e->>'qty_8w')::numeric), 0) into v_sum
  from jsonb_array_elements(inventory.get_purchase_forecast(v_t, null, false, 20)->'rows') e;
  if v_sum <> 26 + 5 then
    raise exception 'FAIL: f9 tenant B sales leaked into A (sum %)', v_sum;
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_outsider::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_outsider::text, true);
  perform pg_temp.expect_err(
    format('select inventory.get_purchase_forecast(%L)', v_t),
    'PERMISSION_DENIED', 'f9 non member');

  raise notice 'inventory_purchase_forecast: OK';
end;
$$;

rollback;
