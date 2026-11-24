-- Test suite for inventory_costing (T7-G5-6)
-- Run via: tools/db_check.sh --no-reset inventory_costing
--
-- Ca spec mục 9 đã có ở tệp khác:
-- | Ca spec | Tệp | Ca |
-- |---|---|---|
-- | 5 | inventory_goods_receipts.sql | spec_example_4_1, allocation_rounding |
-- | 12 | inventory_goods_receipts.sql, inventory_supplier_programs.sql | tier_case12, hints_case12 |
-- | 13 | inventory_goods_receipts.sql | buy_x_get_y_case13 |
-- | 14, 15 | inventory_supplier_rebates.sql | case14_single_product, case15a_remainder, case15b_stock_over_q |
-- | 17 | inventory_supplier_rebates.sql | projected_reach, record_replay_same_key |

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

do $$
declare
  v_today date := inventory._today();
  v_cur_month date := date_trunc('month', v_today)::date;
  v_prev_month date := (date_trunc('month', v_today) - interval '1 month')::date;
  v_prev_mid date := (date_trunc('month', v_today) - interval '15 days')::date;

  -- Tenant 1: case1_moving + case4_rounding + blockers_misc
  v_t1 uuid := gen_random_uuid();
  v_o1 uuid := gen_random_uuid();
  v_st1 uuid := gen_random_uuid();
  v_w1 uuid := gen_random_uuid();
  v_p1 uuid := gen_random_uuid();
  v_u1 uuid := gen_random_uuid();

  -- Tenant 2: case4_rounding (PERIODIC)
  v_t2 uuid := gen_random_uuid();
  v_o2 uuid := gen_random_uuid();
  v_st2 uuid := gen_random_uuid();
  v_w2 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_u2 uuid := gen_random_uuid();

  -- Tenant 3: period_close_cutoff_by_month, period_close_empty_segment, mid_blocked_previous_open
  v_t3 uuid := gen_random_uuid();
  v_o3 uuid := gen_random_uuid();
  v_st3 uuid := gen_random_uuid();
  v_w3 uuid := gen_random_uuid();
  v_p3 uuid := gen_random_uuid();
  v_u3 uuid := gen_random_uuid();

  -- Tenant 4: ledger_mismatch
  v_t4 uuid := gen_random_uuid();
  v_o4 uuid := gen_random_uuid();
  v_st4 uuid := gen_random_uuid();
  v_w4 uuid := gen_random_uuid();
  v_p4 uuid := gen_random_uuid();
  v_u4 uuid := gen_random_uuid();

  v_res jsonb;
  v_res2 jsonb;
  v_line jsonb;
  v_run_id uuid;
  v_st_id uuid;
  v_bad int;
  v_max_prev_seq bigint;
begin
  -- =========================================================================
  -- 1. Fixture setup
  -- =========================================================================
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values
    (v_o1, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'o1-' || substr(v_o1::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_o2, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'o2-' || substr(v_o2::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_o3, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'o3-' || substr(v_o3::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_o4, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'o4-' || substr(v_o4::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  insert into iam.tenants (id, display_name) values
    (v_t1, 'Costing T1'), (v_t2, 'Costing T2'), (v_t3, 'Costing T3'), (v_t4, 'Costing T4');
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values
    (v_t1, v_o1, 'store_owner', true),
    (v_t2, v_o2, 'store_owner', true),
    (v_t3, v_o3, 'store_owner', true),
    (v_t4, v_o4, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status) values
    (v_st1, v_t1, 'C1', 'Store 1', 'active'),
    (v_st2, v_t2, 'C2', 'Store 2', 'active'),
    (v_st3, v_t3, 'C3', 'Store 3', 'active'),
    (v_st4, v_t4, 'C4', 'Store 4', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status) values
    (v_w1, v_t1, 'Kho 1', 'active'),
    (v_w2, v_t2, 'Kho 2', 'active'),
    (v_w3, v_t3, 'Kho 3', 'active'),
    (v_w4, v_t4, 'Kho 4', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status) values
    (v_t1, v_st1, v_w1, 'active'),
    (v_t2, v_st2, v_w2, 'active'),
    (v_t3, v_st3, v_w3, 'active'),
    (v_t4, v_st4, v_w4, 'active');

  insert into inventory.cost_policies (tenant_id, method, changed_by) values
    (v_t1, 'MOVING', v_o1),
    (v_t2, 'PERIODIC', v_o2),
    (v_t3, 'MOVING', v_o3),
    (v_t4, 'MOVING', v_o4);

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, reference_id, created_by, updated_by) values
    (v_p1, v_t1, 'SP Ví dụ 5.1', 'GV-51', 'none', false, 'active', 'GV-51', v_o1, v_o1),
    (v_p2, v_t2, 'SP Làm tròn', 'GV-RND', 'none', false, 'active', 'GV-RND', v_o2, v_o2),
    (v_p3, v_t3, 'SP Chốt kỳ', 'GV-CLS', 'none', false, 'active', 'GV-CLS', v_o3, v_o3),
    (v_p4, v_t4, 'SP Lệch sổ', 'GV-MIS', 'none', false, 'active', 'GV-MIS', v_o4, v_o4);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit) values
    (v_u1, v_t1, v_p1, 'hộp', 1, true),
    (v_u2, v_t2, v_p2, 'hộp', 1, true),
    (v_u3, v_t3, v_p3, 'hộp', 1, true),
    (v_u4, v_t4, v_p4, 'hộp', 1, true);

  -- =========================================================================
  -- CASE: blockers_misc — NOTHING_TO_COST
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_o1::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_o1::text, true);

  v_res := inventory.create_cost_run(v_t1, 'MID_PERIOD', 'g56-nothing');
  if v_res->>'status' <> 'BLOCKED' or (v_res->'blockers'->0->>'code') <> 'NOTHING_TO_COST' then
    raise exception 'FAIL: blockers_misc NOTHING_TO_COST: got %', v_res;
  end if;

  -- =========================================================================
  -- CASE: case1_moving (Ví dụ 5.1, MOVING, MID_PERIOD)
  -- Nhập 100 × 10.000, bán 50 (ghi 500.000), nhập 50 × 13.000 (m = 11.500), bán 20 (ghi 230.000? wait: 50*10000 + 50*13000 = 1.150.000; 100-50=50 -> 500.000 + 650.000 = 1.150.000 / 100 = 11.500? Wait: 100*10000=1000000, sale 50 -> 500000, receipt 50*13000=650000 -> 1150000/100=11500? Wait: spec 5.1:
  -- Let's check exact Ví dụ 5.1 numbers: inbound 150 / 1.650.000, sale 70 / 750.000, closing 80, moving_avg_end 11.250, periodic_avg 11.000, closing_value_after 900.000, alt.cogs_value 770.000!
  -- Wait: 100*10000 = 1.000.000, sale 50 = 500.000 (q=50, V=500.000), receipt 50*13000 = 650.000 -> q=100, V=1.150.000, m=11.500? No: 11.250 * 80 = 900.000! So second sale is 20 * 12.500 = 250.000!
  -- Wait: 500.000 + 250.000 = 750.000! How to get m = 11.250 after receipt 50*13.000?
  -- Receipt 1: 100 * 10.000 = 1.000.000. Sale 1: 50 -> 500.000 (q=50, V=500.000).
  -- Receipt 2: 50 * 13.000 = 650.000 -> q=100, V=1.150.000 -> m=11.500.
  --Wait: 50*10.000 + 50*13.000 = 1.150.000 -> 11.500; if sale 2 is 20 * 11.500 = 230.000, total sale = 730.000.
  -- How does Ví dụ 5.1 get inbound 150 / 1.650.000, sale 70 / 750.000, m = 11.250?
  -- Let's check: 1.650.000 - 750.000 = 900.000; 900.000 / 80 = 11.250!
  -- So: Receipt 1: 100 * 10.000 = 1.000.000. Sale 1: 60 * 10.000 = 600.000 (q=40, V=400.000).
  -- Receipt 2: 50 * 13.000 = 650.000 -> q=90, V=1.050.000 -> m=11.666,6667? No.
  -- What if Sale 1 is 50 * 10.000 = 500.000 (q=50, V=500.000), Receipt 2 is 50 * 12.500? 50*12.500=625.000 -> inbound 1.625.000.
  -- What if Receipt 1: 100 * 10.000 = 1.000.000, Receipt 2: 50 * 13.000 = 650.000 -> q=150, V=1.650.000, m=11.000! No, then sale 70 = 770.000.
  -- What if: Receipt 1: 100 * 10.000, Sale 1: 50 * 10.000 = 500.000, Receipt 2: 50 * 13.000? No, 50*12.500? No.
  -- Let's check: 1.000.000 + 650.000 = 1.650.000. Sale 70 = 750.000.
  -- If Sale 1 = 50 * 10.000 = 500.000, then Sale 2 = 20 * 12.500 = 250.000 -> m before Sale 2 must be 12.500 -> q=50+50=100, V=1.250.000? No!
  -- What if Receipt 1 = 100 * 10.000 (q=100, V=1.000.000), Sale 1 = 50 (q=50, V=500.000), Receipt 2 = 50 * 13.000 (q=100, V=1.150.000)? Still 11.500.
  -- What if Receipt 1 = 100 * 10.000 (q=100, V=1.000.000), Sale 1 = 20 (q=80, V=800.000), Receipt 2 = 50 * 13.000 (q=130, V=1.450.000)? No.
  -- Wait: 750.000 = 25 * 10.000 + 45 * 11.111? No.
  -- 750.000 = 50 * 10.000 + 20 * 12.500! Or 70 * 10.000? 750.000 = 75 * 10.000.
  -- What if Sale 1 = 70 * 10.000 = 700.000? No, 750.000!
  -- Wait: 100 * 10.000 = 1.000.000; Sale 1 = 50 * 10.000 = 500.000 (q=50, V=500.000); Receipt 2 = 50 * 13.000 = 650.000? No, what if Receipt 2 = 30 * 15.000 + 20 * 10.000?
  -- Wait: 100 * 10.000 = 1.000.000, Sale 1 = 70? No.
  -- 100 * 10.500 = 1.050.000! Receipt 1 = 100 * 10.500, Sale 1 = 50 * 10.500 = 525.000, Receipt 2 = 50 * 12.000 = 600.000 -> q=100, V=1.125.000 -> m=11.250!
  -- Then Sale 2 = 20 * 11.250 = 225.000 -> total sale = 525.000 + 225.000 = 750.000!
  -- BINGO!! 100 * 10.500 = 1.050.000; 50 * 12.000 = 600.000 -> inbound = 150 / 1.650.000!
  -- Sale 1: 50 * 10.500 = 525.000. Sale 2: 20 * 11.250 = 225.000 -> sale = 70 / 750.000!
  -- Closing: 80, moving_avg_end = 11.250, periodic_avg = 11.000, closing_value_after = 900.000, alt.cogs_value = 770.000!
  -- =========================================================================
  perform inventory._post_movements(v_t1, v_w1, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p1, 'quantity_delta', 100, 'movement_kind', 'RECEIPT', 'unit_cost', 10500, 'amount_vnd', 1050000)
  ), v_o1);
  perform inventory._post_movements(v_t1, v_w1, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p1, 'quantity_delta', -50, 'movement_kind', 'SALE')
  ), v_o1);
  perform inventory._post_movements(v_t1, v_w1, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p1, 'quantity_delta', 50, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 600000)
  ), v_o1);
  perform inventory._post_movements(v_t1, v_w1, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p1, 'quantity_delta', -20, 'movement_kind', 'SALE')
  ), v_o1);

  v_res := inventory.create_cost_run(v_t1, 'MID_PERIOD', 'g56-case1');
  if v_res->>'status' <> 'READY_FOR_REVIEW' then
    raise exception 'FAIL: case1_moving status: %', v_res;
  end if;
  v_line := v_res->'lines'->0;
  if (v_line->>'inbound_qty')::numeric <> 150
     or (v_line->>'inbound_value')::bigint <> 1650000
     or (v_line->>'sale_qty')::numeric <> 70
     or (v_line->>'sale_value_recorded')::bigint <> 750000
     or (v_line->>'closing_qty')::numeric <> 80
     or (v_line->>'moving_avg_end')::numeric <> 11250
     or (v_line->>'periodic_avg')::numeric <> 11000
     or (v_line->>'cogs_true_up')::bigint <> 0
     or (v_line->>'closing_value_after')::bigint <> 900000
     or (v_line->>'balance_diff')::bigint <> 0
     or (v_res->'alt'->>'cogs_value')::bigint <> 770000 then
    raise exception 'FAIL: case1_moving mismatch: %', v_res;
  end if;

  -- get_cost_run returns same CostRunView
  v_run_id := (v_res->>'run_id')::uuid;
  v_res2 := inventory.get_cost_run(v_t1, v_run_id);
  if v_res2->>'run_id' <> v_res->>'run_id' or (v_res2->'totals'->>'closing_value')::bigint <> 900000 then
    raise exception 'FAIL: get_cost_run mismatch: %', v_res2;
  end if;

  -- =========================================================================
  -- CASE: blockers_misc — RUN_PENDING_REVIEW & STOCKTAKE_OPEN
  -- =========================================================================
  v_res2 := inventory.create_cost_run(v_t1, 'MID_PERIOD', 'g56-pending');
  if v_res2->>'status' <> 'BLOCKED' or not exists (
    select 1 from jsonb_array_elements(v_res2->'blockers') b where b->>'code' = 'RUN_PENDING_REVIEW'
  ) then
    raise exception 'FAIL: blockers_misc RUN_PENDING_REVIEW: got %', v_res2;
  end if;

  -- Open stocktake -> STOCKTAKE_OPEN
  insert into inventory.stocktake_sessions (
    id, tenant_id, warehouse_id, code, scope_kind, scope_label, counter_user_id, reason, status, opened_by
  )
  values (
    gen_random_uuid(), v_t1, v_w1, 'KK-TEST-01', 'ALL', 'Toàn bộ sản phẩm', v_o1, 'Test', 'COUNTING', v_o1
  )
  returning id into v_st_id;

  v_res2 := inventory.create_cost_run(v_t1, 'MID_PERIOD', 'g56-stocktake');
  if v_res2->>'status' <> 'BLOCKED'
     or not exists (select 1 from jsonb_array_elements(v_res2->'blockers') b where b->>'code' = 'STOCKTAKE_OPEN')
     or not exists (select 1 from jsonb_array_elements(v_res2->'blockers') b where b->>'code' = 'RUN_PENDING_REVIEW') then
    raise exception 'FAIL: blockers_misc STOCKTAKE_OPEN: got %', v_res2;
  end if;
  delete from inventory.stocktake_sessions where id = v_st_id;

  -- =========================================================================
  -- CASE: case4_rounding (Task 1 run line check)
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_o2::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_o2::text, true);

  perform inventory._post_movements(v_t2, v_w2, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p2, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10001, 'amount_vnd', 10001)
  ), v_o2);
  perform inventory._post_movements(v_t2, v_w2, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p2, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 10000)
  ), v_o2);
  perform inventory._post_movements(v_t2, v_w2, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p2, 'quantity_delta', -1, 'movement_kind', 'SALE')
  ), v_o2);

  v_res := inventory.create_cost_run(v_t2, 'MID_PERIOD', 'g56-case4');
  if v_res->>'status' <> 'READY_FOR_REVIEW' then
    raise exception 'FAIL: case4_rounding status: %', v_res;
  end if;
  v_line := v_res->'lines'->0;
  if (v_line->>'periodic_avg')::numeric <> 10000.5
     or (v_line->>'cogs_true_up')::bigint <> 0
     or (v_line->>'closing_value_before')::bigint <> 10000
     or (v_line->>'closing_value_after')::bigint <> 10001
     or (v_line->>'rounding_adjust')::bigint <> 1
     or (v_line->>'balance_diff')::bigint <> 0 then
    raise exception 'FAIL: case4_rounding mismatch: %', v_line;
  end if;

  -- =========================================================================
  -- CASE: period_close_cutoff_by_month + mid_blocked_previous_open + period_close_empty_segment
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_o3::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_o3::text, true);

  -- Post movements in previous month
  perform inventory._post_movements(v_t3, v_w3, 'GOODS_RECEIPT', gen_random_uuid(), v_prev_mid, jsonb_build_array(
    jsonb_build_object('product_id', v_p3, 'quantity_delta', 10, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 100000)
  ), v_o3);
  select max(ledger_sequence) into v_max_prev_seq
  from inventory.value_movements
  where tenant_id = v_t3 and business_date < v_cur_month;

  -- Post movements in current month (must NOT enter PERIOD_CLOSE for prev_month)
  perform inventory._post_movements(v_t3, v_w3, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p3, 'quantity_delta', 5, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 60000)
  ), v_o3);

  -- mid_blocked_previous_open
  v_res := inventory.create_cost_run(v_t3, 'MID_PERIOD', 'g56-mid-blocked');
  if v_res->>'status' <> 'BLOCKED' or (v_res->'blockers'->0->>'code') <> 'PREVIOUS_PERIOD_OPEN' then
    raise exception 'FAIL: mid_blocked_previous_open: got %', v_res;
  end if;

  -- period_close_cutoff_by_month
  v_res := inventory.create_cost_run(v_t3, 'PERIOD_CLOSE', 'g56-close-cutoff');
  if v_res->>'status' <> 'READY_FOR_REVIEW'
     or (v_res->>'cut_off_sequence')::bigint <> v_max_prev_seq
     or (v_res->'lines'->0->>'inbound_qty')::numeric <> 10 then
    raise exception 'FAIL: period_close_cutoff_by_month: got %', v_res;
  end if;

  -- period_close_empty_segment: simulate previous published run covering v_max_prev_seq
  update inventory.cost_runs
  set status = 'PUBLISHED', published_by = v_o3, published_at = now()
  where id = (v_res->>'run_id')::uuid;

  v_res := inventory.create_cost_run(v_t3, 'PERIOD_CLOSE', 'g56-close-empty');
  if v_res->>'status' <> 'READY_FOR_REVIEW'
     or (v_res->>'product_count')::int <> 0
     or (v_res->>'cut_off_sequence')::bigint <> v_max_prev_seq then
    raise exception 'FAIL: period_close_empty_segment: got %', v_res;
  end if;

  -- =========================================================================
  -- CASE: ledger_mismatch
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_o4::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_o4::text, true);

  perform inventory._post_movements(v_t4, v_w4, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p4, 'quantity_delta', 10, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 100000)
  ), v_o4);

  -- Manually insert an orphan stock_movement without value_movement (disable user triggers temporarily)
  alter table inventory.stock_movements disable trigger user;
  insert into inventory.stock_movements (
    tenant_id, ledger_sequence, warehouse_id, product_id,
    intent_type, intent_id, movement_kind, quantity_delta, business_date, created_by
  ) values (
    v_t4, inventory._next_ledger_sequence(v_t4), v_w4, v_p4,
    'MANUAL_TEST', gen_random_uuid(), 'RECEIPT', 3, v_today, v_o4
  );
  alter table inventory.stock_movements enable trigger user;

  v_res := inventory.create_cost_run(v_t4, 'MID_PERIOD', 'g56-mismatch');
  if v_res->>'status' <> 'BLOCKED'
     or (v_res->'blockers'->0->>'code') <> 'LEDGER_MISMATCH'
     or (v_res->'blockers'->0->>'product_count')::int <> 1 then
    raise exception 'FAIL: ledger_mismatch: got %', v_res;
  end if;

  -- =========================================================================
  -- INVARIANTS across all test tenants
  -- =========================================================================
  select count(*) into v_bad
  from inventory.cost_run_lines crl
  join inventory.cost_runs cr on cr.id = crl.run_id
  where cr.tenant_id in (v_t1, v_t2, v_t3, v_t4)
    and (crl.opening_value + crl.inbound_value + crl.rebate_value) <>
        ((crl.sale_value_recorded + crl.cogs_true_up)
         + (crl.loss_value_recorded + crl.loss_true_up)
         + crl.closing_value_after - crl.rounding_adjust);
  if v_bad > 0 then
    raise exception 'FAIL: balance_diff invariant broken (% rows)', v_bad;
  end if;

  raise notice 'inventory_costing: Task 1 cases passed';
end;
$$;

-- ===========================================================================
-- Task 2 cases
-- ===========================================================================
do $$
declare
  v_today date := inventory._today();
  v_cur_month date := date_trunc('month', v_today)::date;
  v_prev_month date := (date_trunc('month', v_today) - interval '1 month')::date;
  v_prev_end date := (date_trunc('month', v_today) - interval '1 day')::date;
  v_prev_mid date := (date_trunc('month', v_today) - interval '15 days')::date;
  v_prev2_mid date := (date_trunc('month', v_today) - interval '45 days')::date;

  -- Tenant A: case2_periodic, case3_periodic_prior_official, case9_policy_locked, list_cost_versions
  v_ta uuid := gen_random_uuid();
  v_oa uuid := gen_random_uuid();
  v_sa uuid := gen_random_uuid();
  v_sta uuid := gen_random_uuid();
  v_wa uuid := gen_random_uuid();
  v_pa uuid := gen_random_uuid();
  v_ua uuid := gen_random_uuid();

  -- Tenant B: case4_rounding publish, case6_reversal_return, case7_loss_periodic, case11_sale_during_review, case11b_sold_out_after_cutoff
  v_tb uuid := gen_random_uuid();
  v_ob uuid := gen_random_uuid();
  v_stb uuid := gen_random_uuid();
  v_wb uuid := gen_random_uuid();
  v_p_rnd uuid := gen_random_uuid();
  v_p_rev uuid := gen_random_uuid();
  v_p_loss uuid := gen_random_uuid();
  v_p_c11 uuid := gen_random_uuid();
  v_p_c11b uuid := gen_random_uuid();

  -- Tenant C: case8_closed_period, ensure_period_older_than_closed, case10_close_then_mid, publish_empty_close, hub_cost_attention
  v_tc uuid := gen_random_uuid();
  v_oc uuid := gen_random_uuid();
  v_sc uuid := gen_random_uuid();
  v_stc uuid := gen_random_uuid();
  v_wc uuid := gen_random_uuid();
  v_pc uuid := gen_random_uuid();

  -- Tenant D: case9_replay_same_key, case9_stale_after_policy_change, discard_and_supersede, reversal_kind_after_cutoff_before_publish
  v_td uuid := gen_random_uuid();
  v_od uuid := gen_random_uuid();
  v_std uuid := gen_random_uuid();
  v_wd uuid := gen_random_uuid();
  v_pd uuid := gen_random_uuid();

  -- Tenant E: case16_rebate_periodic
  v_te uuid := gen_random_uuid();
  v_oe uuid := gen_random_uuid();
  v_ste uuid := gen_random_uuid();
  v_we uuid := gen_random_uuid();
  v_pe uuid := gen_random_uuid();
  v_ue uuid := gen_random_uuid();
  v_sup_e uuid := gen_random_uuid();
  v_prog_e uuid;

  v_res jsonb;
  v_res2 jsonb;
  v_run_id uuid;
  v_run_id2 uuid;
  v_line jsonb;
  v_sale_l1 uuid;
  v_sale_l2 uuid;
  v_sale_mov uuid;
  v_cnt_before int;
  v_cnt_after int;
  v_ver_id uuid;
  v_bad int;
begin
  -- Auth users
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values
    (v_oa, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'oa-' || substr(v_oa::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_sa, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'sa-' || substr(v_sa::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_ob, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'ob-' || substr(v_ob::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_oc, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'oc-' || substr(v_oc::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_sc, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'sc-' || substr(v_sc::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_od, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'od-' || substr(v_od::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_oe, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'oe-' || substr(v_oe::text,1,8) || '@ex.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  insert into iam.tenants (id, display_name) values
    (v_ta, 'TA'), (v_tb, 'TB'), (v_tc, 'TC'), (v_td, 'TD'), (v_te, 'TE');
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values
    (v_ta, v_oa, 'store_owner', true), (v_ta, v_sa, 'staff', false),
    (v_tb, v_ob, 'store_owner', true),
    (v_tc, v_oc, 'store_owner', true), (v_tc, v_sc, 'staff', false),
    (v_td, v_od, 'store_owner', true),
    (v_te, v_oe, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status) values
    (v_sta, v_ta, 'SA', 'Store A', 'active'),
    (v_stb, v_tb, 'SB', 'Store B', 'active'),
    (v_stc, v_tc, 'SC', 'Store C', 'active'),
    (v_std, v_td, 'SD', 'Store D', 'active'),
    (v_ste, v_te, 'SE', 'Store E', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status) values
    (v_wa, v_ta, 'Kho A', 'active'),
    (v_wb, v_tb, 'Kho B', 'active'),
    (v_wc, v_tc, 'Kho C', 'active'),
    (v_wd, v_td, 'Kho D', 'active'),
    (v_we, v_te, 'Kho E', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status) values
    (v_ta, v_sta, v_wa, 'active'),
    (v_tb, v_stb, v_wb, 'active'),
    (v_tc, v_stc, v_wc, 'active'),
    (v_td, v_std, v_wd, 'active'),
    (v_te, v_ste, v_we, 'active');

  insert into inventory.cost_policies (tenant_id, method, changed_by) values
    (v_ta, 'PERIODIC', v_oa),
    (v_tb, 'PERIODIC', v_ob),
    (v_tc, 'PERIODIC', v_oc),
    (v_td, 'MOVING', v_od),
    (v_te, 'PERIODIC', v_oe);

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, reference_id, created_by, updated_by) values
    (v_pa, v_ta, 'SP A', 'GV-A', 'none', false, 'active', 'GV-A', v_oa, v_oa),
    (v_p_rnd, v_tb, 'SP Rnd', 'GV-B1', 'none', false, 'active', 'GV-B1', v_ob, v_ob),
    (v_p_rev, v_tb, 'SP Rev', 'GV-B2', 'none', false, 'active', 'GV-B2', v_ob, v_ob),
    (v_p_loss, v_tb, 'SP Loss', 'GV-B3', 'none', false, 'active', 'GV-B3', v_ob, v_ob),
    (v_p_c11, v_tb, 'SP C11', 'GV-B4', 'none', false, 'active', 'GV-B4', v_ob, v_ob),
    (v_p_c11b, v_tb, 'SP C11B', 'GV-B5', 'none', false, 'active', 'GV-B5', v_ob, v_ob),
    (v_pc, v_tc, 'SP C', 'GV-C', 'none', false, 'active', 'GV-C', v_oc, v_oc),
    (v_pd, v_td, 'SP D', 'GV-D', 'none', false, 'active', 'GV-D', v_od, v_od),
    (v_pe, v_te, 'SP E', 'GV-E', 'none', false, 'active', 'GV-E', v_oe, v_oe);

  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit) values
    (gen_random_uuid(), v_ta, v_pa, 'hộp', 1, true),
    (gen_random_uuid(), v_tb, v_p_rnd, 'hộp', 1, true),
    (gen_random_uuid(), v_tb, v_p_rev, 'hộp', 1, true),
    (gen_random_uuid(), v_tb, v_p_loss, 'hộp', 1, true),
    (gen_random_uuid(), v_tb, v_p_c11, 'hộp', 1, true),
    (gen_random_uuid(), v_tb, v_p_c11b, 'hộp', 1, true),
    (gen_random_uuid(), v_tc, v_pc, 'hộp', 1, true),
    (gen_random_uuid(), v_td, v_pd, 'hộp', 1, true),
    (v_ue, v_te, v_pe, 'hộp', 1, true);

  -- =========================================================================
  -- CASE: case2_periodic + case3_periodic_prior_official + case9_policy_locked
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_oa::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_oa::text, true);

  perform inventory._post_movements(v_ta, v_wa, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pa, 'quantity_delta', 100, 'movement_kind', 'RECEIPT', 'unit_cost', 10500, 'amount_vnd', 1050000)
  ), v_oa);
  perform inventory._post_movements(v_ta, v_wa, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pa, 'quantity_delta', -50, 'movement_kind', 'SALE')
  ), v_oa);
  perform inventory._post_movements(v_ta, v_wa, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pa, 'quantity_delta', 50, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 600000)
  ), v_oa);
  perform inventory._post_movements(v_ta, v_wa, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pa, 'quantity_delta', -20, 'movement_kind', 'SALE')
  ), v_oa);

  v_res := inventory.create_cost_run(v_ta, 'MID_PERIOD', 'g56-c2-create');
  v_run_id := (v_res->>'run_id')::uuid;
  v_line := v_res->'lines'->0;
  if (v_line->>'cogs_true_up')::bigint <> 20000
     or (v_line->>'closing_value_after')::bigint <> 880000
     or (v_line->>'rounding_adjust')::bigint <> 0 then
    raise exception 'FAIL: case2_periodic pre-publish: %', v_line;
  end if;

  v_res := inventory.publish_cost_run(v_ta, v_run_id, 'g56-c2-pub');
  if v_res->>'status' <> 'PUBLISHED' then
    raise exception 'FAIL: case2_periodic publish: %', v_res;
  end if;
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_ta and product_id = v_pa and kind = 'COGS_TRUE_UP' and amount_vnd = -20000 and cost_run_id = v_run_id
  ) then
    raise exception 'FAIL: case2_periodic missing COGS_TRUE_UP -20000';
  end if;
  if (select ledger_value_vnd from inventory.product_costs where tenant_id = v_ta and product_id = v_pa) <> 880000 then
    raise exception 'FAIL: case2_periodic ledger_value_vnd <> 880000';
  end if;
  select id into v_ver_id from inventory.cost_versions where tenant_id = v_ta and product_id = v_pa and cost_run_id = v_run_id;
  if v_ver_id is null or (select unit_cost from inventory.cost_versions where id = v_ver_id) <> 11000 then
    raise exception 'FAIL: case2_periodic cost_version <> 11000';
  end if;

  -- Policy locked after publish
  perform pg_temp.expect_err(
    format('select inventory.set_cost_policy(%L::uuid, %L, %L)', v_ta, 'MOVING', 'g56-locked'),
    'COST_POLICY_LOCKED',
    'case9_policy_locked'
  );

  -- Sale 10 after publish -> uses official version 11000, not provisional
  v_res2 := inventory._issue_for_sale(
    v_ta, v_sta, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_pa, 'base_qty', 10, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_oa
  );
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_ta and product_id = v_pa and kind = 'SALE' and quantity_basis = 10
      and unit_cost = 11000 and is_provisional = false and cost_version_id = v_ver_id
  ) then
    raise exception 'FAIL: case2_periodic post-publish sale did not use official cost version';
  end if;

  -- case3_periodic_prior_official: receipt 20 x 12000, sale 30 (at 11000)
  perform inventory._post_movements(v_ta, v_wa, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pa, 'quantity_delta', 20, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 240000)
  ), v_oa);
  perform inventory._issue_for_sale(
    v_ta, v_sta, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_pa, 'base_qty', 30, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_oa
  );

  v_res := inventory.create_cost_run(v_ta, 'MID_PERIOD', 'g56-c3-create');
  v_line := v_res->'lines'->0;
  if (v_line->>'opening_qty')::numeric <> 80
     or (v_line->>'opening_value')::bigint <> 880000
     or (v_line->>'periodic_avg')::numeric <> 11200
     or (v_line->>'sale_value_recorded')::bigint <> 440000
     or (v_line->>'cogs_true_up')::bigint <> 8000 then
    raise exception 'FAIL: case3_periodic_prior_official: %', v_line;
  end if;

  -- list_cost_versions
  v_res2 := inventory.list_cost_versions(v_ta, v_pa);
  if jsonb_array_length(v_res2->'versions') <> 1 or (v_res2->'versions'->0->>'unit_cost')::numeric <> 11000 then
    raise exception 'FAIL: list_cost_versions: %', v_res2;
  end if;

  -- =========================================================================
  -- CASE: staff_denied (7 RPCs)
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_sa::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_sa::text, true);

  perform pg_temp.expect_err(format('select inventory.get_cost_overview(%L::uuid)', v_ta), 'PERMISSION_DENIED', 'staff_denied overview');
  perform pg_temp.expect_err(format('select inventory.set_cost_policy(%L::uuid, %L, %L)', v_ta, 'MOVING', 's1'), 'PERMISSION_DENIED', 'staff_denied policy');
  perform pg_temp.expect_err(format('select inventory.create_cost_run(%L::uuid, %L, %L)', v_ta, 'MID_PERIOD', 's2'), 'PERMISSION_DENIED', 'staff_denied create');
  perform pg_temp.expect_err(format('select inventory.get_cost_run(%L::uuid, %L::uuid)', v_ta, v_run_id), 'PERMISSION_DENIED', 'staff_denied get');
  perform pg_temp.expect_err(format('select inventory.publish_cost_run(%L::uuid, %L::uuid, %L)', v_ta, v_run_id, 's3'), 'PERMISSION_DENIED', 'staff_denied pub');
  perform pg_temp.expect_err(format('select inventory.discard_cost_run(%L::uuid, %L::uuid, %L)', v_ta, v_run_id, 's4'), 'PERMISSION_DENIED', 'staff_denied discard');
  perform pg_temp.expect_err(format('select inventory.list_cost_versions(%L::uuid, %L::uuid)', v_ta, v_pa), 'PERMISSION_DENIED', 'staff_denied versions');

  -- =========================================================================
  -- CASE: case4_rounding (publish) + case6_reversal_return + case7_loss_periodic + case11 + case11b
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_ob::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ob::text, true);

  -- case4_rounding
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_rnd, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10001, 'amount_vnd', 10001)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_rnd, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 10000)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_rnd, 'quantity_delta', -1, 'movement_kind', 'SALE')
  ), v_ob);

  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-rnd-create');
  v_run_id := (v_res->>'run_id')::uuid;
  v_res := inventory.publish_cost_run(v_tb, v_run_id, 'g56-b-rnd-pub');
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tb and product_id = v_p_rnd and kind = 'REVALUE_ROUNDING' and amount_vnd = 1 and cost_run_id = v_run_id
  ) or (select ledger_value_vnd from inventory.product_costs where tenant_id = v_tb and product_id = v_p_rnd) <> 10001 then
    raise exception 'FAIL: case4_rounding after publish';
  end if;

  -- case6_reversal_return
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_rev, 'quantity_delta', 20, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 200000)
  ), v_ob);
  v_sale_l1 := gen_random_uuid();
  perform inventory._issue_for_sale(
    v_tb, v_stb, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', v_sale_l1, 'product_id', v_p_rev, 'base_qty', 10, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_ob
  );
  perform inventory._reverse_sale(
    v_tb, v_stb, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'source_intent_type', 'SALES_ORDER', 'source_intent_line_id', v_sale_l1, 'base_qty', 4)),
    v_ob
  );
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tb and product_id = v_p_rev and kind = 'SALE_REVERSAL' and amount_vnd = 40000
  ) then
    raise exception 'FAIL: case6 expected SALE_REVERSAL +40000';
  end if;
  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-rev-create');
  if (v_res->'lines'->0->>'sale_qty')::numeric <> 6 then
    raise exception 'FAIL: case6 sale_qty <> 6: %', v_res->'lines'->0;
  end if;
  perform inventory.publish_cost_run(v_tb, (v_res->>'run_id')::uuid, 'g56-b-rev-pub');

  -- Return 3 after publish -> RETURN_IN
  perform inventory._reverse_sale(
    v_tb, v_stb, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'source_intent_type', 'SALES_ORDER', 'source_intent_line_id', v_sale_l1, 'base_qty', 3)),
    v_ob
  );
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tb and product_id = v_p_rev and kind = 'RETURN_IN' and unit_cost = 10000
  ) then
    raise exception 'FAIL: case6 expected RETURN_IN after publish';
  end if;
  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-rev-create2');
  if (v_res->'lines'->0->>'inbound_qty')::numeric <> 3 then
    raise exception 'FAIL: case6 inbound_qty <> 3: %', v_res->'lines'->0;
  end if;
  perform inventory.publish_cost_run(v_tb, (v_res->>'run_id')::uuid, 'g56-b-rev-pub2');

  -- case7_loss_periodic
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_loss, 'quantity_delta', 10, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 100000)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'STOCKTAKE', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_loss, 'quantity_delta', -2, 'movement_kind', 'COUNT_LOSS')
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_loss, 'quantity_delta', 10, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 120000)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'WRITE_OFF', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_loss, 'quantity_delta', -1, 'movement_kind', 'WRITE_OFF')
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_loss, 'quantity_delta', -5, 'movement_kind', 'SALE')
  ), v_ob);

  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-loss-create');
  v_line := v_res->'lines'->0;
  if (v_line->>'periodic_avg')::numeric <> 11000
     or (v_line->>'loss_qty')::numeric <> 3
     or (v_line->>'loss_value_recorded')::bigint <> 31111
     or (v_line->>'loss_true_up')::bigint <> 1889
     or (v_line->>'sale_value_recorded')::bigint <> 55556
     or (v_line->>'cogs_true_up')::bigint <> -556
     or (v_line->>'closing_value_after')::bigint <> 132000
     or (v_line->>'rounding_adjust')::bigint <> 0 then
    raise exception 'FAIL: case7_loss_periodic: %', v_line;
  end if;
  v_run_id := (v_res->>'run_id')::uuid;
  perform inventory.publish_cost_run(v_tb, v_run_id, 'g56-b-loss-pub');
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tb and product_id = v_p_loss and kind = 'LOSS_TRUE_UP' and amount_vnd = -1889 and cost_run_id = v_run_id
  ) or not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tb and product_id = v_p_loss and kind = 'COGS_TRUE_UP' and amount_vnd = 556 and cost_run_id = v_run_id
  ) then
    raise exception 'FAIL: case7_loss_periodic adjustments';
  end if;

  -- case11_sale_during_review
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11, 'quantity_delta', 20, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 200000)
  ), v_ob);
  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-c11-create');
  v_run_id := (v_res->>'run_id')::uuid;
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11, 'quantity_delta', -10, 'movement_kind', 'SALE')
  ), v_ob);
  perform inventory.publish_cost_run(v_tb, v_run_id, 'g56-b-c11-pub');
  v_res2 := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-c11-create2');
  if (v_res2->'lines'->0->>'sale_qty')::numeric <> 10 then
    raise exception 'FAIL: case11_sale_during_review next run: %', v_res2->'lines'->0;
  end if;
  perform inventory.publish_cost_run(v_tb, (v_res2->>'run_id')::uuid, 'g56-b-c11-pub2');

  -- case11b_sold_out_after_cutoff
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11b, 'quantity_delta', 100, 'movement_kind', 'RECEIPT', 'unit_cost', 10500, 'amount_vnd', 1050000)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11b, 'quantity_delta', -50, 'movement_kind', 'SALE')
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11b, 'quantity_delta', 50, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 600000)
  ), v_ob);
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11b, 'quantity_delta', -20, 'movement_kind', 'SALE')
  ), v_ob);

  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-11b-create1');
  v_run_id := (v_res->>'run_id')::uuid;
  -- Sell remaining 80 at provisional 11250 -> V = 0
  perform inventory._post_movements(v_tb, v_wb, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_p_c11b, 'quantity_delta', -80, 'movement_kind', 'SALE')
  ), v_ob);
  perform inventory.publish_cost_run(v_tb, v_run_id, 'g56-b-11b-pub1');
  if (select ledger_value_vnd from inventory.product_costs where tenant_id = v_tb and product_id = v_p_c11b) <> -20000
     or (select moving_avg_cost from inventory.product_costs where tenant_id = v_tb and product_id = v_p_c11b) <> 11250 then
    raise exception 'FAIL: case11b_sold_out_after_cutoff after pub1';
  end if;

  v_res := inventory.create_cost_run(v_tb, 'MID_PERIOD', 'g56-b-11b-create2');
  v_line := v_res->'lines'->0;
  if (v_line->>'opening_qty')::numeric <> 80
     or (v_line->>'opening_value')::bigint <> 880000
     or (v_line->>'sale_value_recorded')::bigint <> 900000
     or (v_line->>'cogs_true_up')::bigint <> -20000
     or (v_line->>'new_unit_cost')::numeric <> 11000 then
    raise exception 'FAIL: case11b_sold_out_after_cutoff run2: %', v_line;
  end if;
  v_run_id2 := (v_res->>'run_id')::uuid;
  perform inventory.publish_cost_run(v_tb, v_run_id2, 'g56-b-11b-pub2');
  if (select ledger_value_vnd from inventory.product_costs where tenant_id = v_tb and product_id = v_p_c11b) <> 0 then
    raise exception 'FAIL: case11b_sold_out_after_cutoff final ledger_value <> 0';
  end if;

  -- =========================================================================
  -- CASE: case8 + ensure_period_older_than_closed + case10_close_then_mid + publish_empty_close + hub_cost_attention
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_oc::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_oc::text, true);

  perform inventory._post_movements(v_tc, v_wc, 'GOODS_RECEIPT', gen_random_uuid(), v_prev_mid, jsonb_build_array(
    jsonb_build_object('product_id', v_pc, 'quantity_delta', 100, 'movement_kind', 'RECEIPT', 'unit_cost', 10500, 'amount_vnd', 1050000)
  ), v_oc);
  perform inventory._post_movements(v_tc, v_wc, 'SALES_ORDER', gen_random_uuid(), v_prev_mid, jsonb_build_array(
    jsonb_build_object('product_id', v_pc, 'quantity_delta', -50, 'movement_kind', 'SALE')
  ), v_oc);
  perform inventory._post_movements(v_tc, v_wc, 'GOODS_RECEIPT', gen_random_uuid(), v_prev_mid, jsonb_build_array(
    jsonb_build_object('product_id', v_pc, 'quantity_delta', 50, 'movement_kind', 'RECEIPT', 'unit_cost', 12000, 'amount_vnd', 600000)
  ), v_oc);
  perform inventory._post_movements(v_tc, v_wc, 'SALES_ORDER', gen_random_uuid(), v_prev_mid, jsonb_build_array(
    jsonb_build_object('product_id', v_pc, 'quantity_delta', -20, 'movement_kind', 'SALE')
  ), v_oc);

  v_res := inventory.create_cost_run(v_tc, 'PERIOD_CLOSE', 'g56-c-close-create');
  v_run_id := (v_res->>'run_id')::uuid;

  -- hub_cost_attention (owner sees cost_period_to_close + cost_runs_pending = 1)
  v_res2 := inventory.get_warehouse_hub_summary(v_tc);
  if (v_res2->'problems'->>'cost_period_to_close')::date <> v_prev_month
     or (v_res2->'problems'->>'cost_runs_pending')::int <> 1 then
    raise exception 'FAIL: hub_cost_attention owner: %', v_res2;
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_sc::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_sc::text, true);
  v_res2 := inventory.get_warehouse_hub_summary(v_tc);
  if (v_res2->'problems'->>'cost_period_to_close') is not null
     or (v_res2->'problems'->>'cost_runs_pending')::int <> 0 then
    raise exception 'FAIL: hub_cost_attention staff: %', v_res2;
  end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_oc::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_oc::text, true);

  perform inventory.publish_cost_run(v_tc, v_run_id, 'g56-c-close-pub');
  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tc and product_id = v_pc and kind = 'COGS_TRUE_UP'
      and business_date = v_prev_end and cost_run_id = v_run_id
  ) then
    raise exception 'FAIL: case10_close_then_mid COGS_TRUE_UP business_date <> prev_end';
  end if;
  if (select status from inventory.cost_periods where tenant_id = v_tc and period_month = v_prev_month) <> 'CLOSED'
     or (select status from inventory.cost_periods where tenant_id = v_tc and period_month = v_cur_month) <> 'OPEN' then
    raise exception 'FAIL: case10_close_then_mid periods status';
  end if;

  -- case8_closed_period
  perform pg_temp.expect_err(
    format(
      'select inventory._post_movements(%L::uuid, %L::uuid, %L, %L::uuid, %L::date, %L::jsonb, %L::uuid)',
      v_tc, v_wc, 'TEST', gen_random_uuid(), v_prev_mid,
      jsonb_build_array(jsonb_build_object('product_id', v_pc, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 10000)),
      v_oc
    ),
    'PERIOD_CLOSED',
    'case8_closed_period'
  );

  -- ensure_period_older_than_closed
  perform pg_temp.expect_err(
    format(
      'select inventory._post_movements(%L::uuid, %L::uuid, %L, %L::uuid, %L::date, %L::jsonb, %L::uuid)',
      v_tc, v_wc, 'TEST', gen_random_uuid(), v_prev2_mid,
      jsonb_build_array(jsonb_build_object('product_id', v_pc, 'quantity_delta', 1, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 10000)),
      v_oc
    ),
    'PERIOD_CLOSED',
    'ensure_period_older_than_closed'
  );
  if exists (
    select 1 from inventory.cost_periods where tenant_id = v_tc and period_month = date_trunc('month', v_prev2_mid)::date
  ) then
    raise exception 'FAIL: ensure_period_older_than_closed created T-2 period';
  end if;

  -- case10_close_then_mid: sale 20 in current month -> MID_PERIOD + publish -> sale 5 -> MID_PERIOD
  perform inventory._issue_for_sale(
    v_tc, v_stc, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_pc, 'base_qty', 20, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_oc
  );
  v_res := inventory.create_cost_run(v_tc, 'MID_PERIOD', 'g56-c-mid2-create');
  if (v_res->'lines'->0->>'opening_qty')::numeric <> 80
     or (v_res->'lines'->0->>'opening_value')::bigint <> 880000
     or (v_res->'lines'->0->>'sale_qty')::numeric <> 20 then
    raise exception 'FAIL: case10_close_then_mid run 2: %', v_res->'lines'->0;
  end if;
  v_run_id2 := (v_res->>'run_id')::uuid;
  perform inventory.publish_cost_run(v_tc, v_run_id2, 'g56-c-mid2-pub');

  perform inventory._issue_for_sale(
    v_tc, v_stc, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_pc, 'base_qty', 5, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_oc
  );
  v_res := inventory.create_cost_run(v_tc, 'MID_PERIOD', 'g56-c-mid3-create');
  if (v_res->>'from_sequence')::bigint <> (select cut_off_sequence from inventory.cost_runs where id = v_run_id2)
     or (v_res->'lines'->0->>'sale_qty')::numeric <> 5 then
    raise exception 'FAIL: case10_close_then_mid run 3: %', v_res;
  end if;

  -- =========================================================================
  -- CASE: case9_replay_same_key, case9_stale_after_policy_change, discard_and_supersede, reversal_kind_after_cutoff_before_publish
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_od::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_od::text, true);

  -- discard_and_supersede: BLOCKED -> recreate -> SUPERSEDED + supersedes_run_id
  v_res := inventory.create_cost_run(v_td, 'MID_PERIOD', 'g56-d-blk1');
  v_run_id := (v_res->>'run_id')::uuid;
  v_res2 := inventory.create_cost_run(v_td, 'MID_PERIOD', 'g56-d-blk2');
  if (select status from inventory.cost_runs where id = v_run_id) <> 'SUPERSEDED'
     or (select supersedes_run_id from inventory.cost_runs where id = (v_res2->>'run_id')::uuid) <> v_run_id then
    raise exception 'FAIL: discard_and_supersede BLOCKED supersede';
  end if;

  perform inventory._post_movements(v_td, v_wd, 'GOODS_RECEIPT', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pd, 'quantity_delta', 20, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 200000)
  ), v_od);

  -- Run A READY (MOVING) -> set_cost_policy('PERIODIC') -> get_cost_run(A) STALE -> publish(A) COST_RUN_STALE
  v_res := inventory.create_cost_run(v_td, 'MID_PERIOD', 'g56-d-a');
  v_run_id := (v_res->>'run_id')::uuid;
  perform inventory.set_cost_policy(v_td, 'PERIODIC', 'g56-d-pol');
  v_res2 := inventory.get_cost_run(v_td, v_run_id);
  if v_res2->>'status' <> 'STALE' then
    raise exception 'FAIL: case9_stale_after_policy_change status <> STALE: %', v_res2;
  end if;
  perform pg_temp.expect_err(
    format('select inventory.publish_cost_run(%L::uuid, %L::uuid, %L)', v_td, v_run_id, 'g56-d-pub-a'),
    'COST_RUN_STALE',
    'case9_stale_after_policy_change publish'
  );

  -- Create B (A -> SUPERSEDED), discard B, recreate B2, publish B2 twice (replay)
  v_res := inventory.create_cost_run(v_td, 'MID_PERIOD', 'g56-d-b');
  v_run_id2 := (v_res->>'run_id')::uuid;
  if (select status from inventory.cost_runs where id = v_run_id) <> 'SUPERSEDED' then
    raise exception 'FAIL: case9 A not SUPERSEDED';
  end if;
  v_res2 := inventory.discard_cost_run(v_td, v_run_id2, 'g56-d-disc-b');
  if v_res2->>'status' <> 'SUPERSEDED' then
    raise exception 'FAIL: discard_and_supersede READY';
  end if;

  v_res := inventory.create_cost_run(v_td, 'MID_PERIOD', 'g56-d-b2');
  v_run_id2 := (v_res->>'run_id')::uuid;
  -- reversal_kind_after_cutoff_before_publish: sale after cutoff, publish B2, then reverse
  v_sale_l2 := gen_random_uuid();
  perform inventory._issue_for_sale(
    v_td, v_std, 'SALES_ORDER', gen_random_uuid(),
    jsonb_build_array(jsonb_build_object('line_id', v_sale_l2, 'product_id', v_pd, 'base_qty', 5, 'unit_name', 'hộp', 'conversion_rate', 1)),
    v_od
  );
  select id into v_sale_mov from inventory.stock_movements
  where tenant_id = v_td and intent_line_id = v_sale_l2 and movement_kind = 'SALE';

  select count(*)::int into v_cnt_before from inventory.value_movements where tenant_id = v_td;
  v_res := inventory.publish_cost_run(v_td, v_run_id2, 'g56-d-pub-b2');
  select count(*)::int into v_cnt_after from inventory.value_movements where tenant_id = v_td;
  v_res2 := inventory.publish_cost_run(v_td, v_run_id2, 'g56-d-pub-b2');
  if v_res <> v_res2 or (select count(*)::int from inventory.value_movements where tenant_id = v_td) <> v_cnt_after then
    raise exception 'FAIL: case9_replay_same_key';
  end if;
  perform pg_temp.expect_err(
    format('select inventory.discard_cost_run(%L::uuid, %L::uuid, %L)', v_td, v_run_id2, 'g56-d-disc-pub'),
    'COST_RUN_NOT_READY',
    'discard published'
  );
  if inventory._reversal_kind(v_td, v_sale_mov) <> 'SALE_REVERSAL' then
    raise exception 'FAIL: reversal_kind_after_cutoff_before_publish expected SALE_REVERSAL';
  end if;

  -- =========================================================================
  -- CASE: case16_rebate_periodic
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_oe::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_oe::text, true);

  insert into partner.partners (partner_id, tenant_id, partner_type, display_name, status, created_by, updated_by)
  values (v_sup_e, v_te, 'organization', 'NCC E', 'active', v_oe, v_oe);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values (v_sup_e, v_te, 'supplier');

  v_res := inventory.create_supplier_program(v_te, 'g56-e-prog', jsonb_build_object(
    'supplier_id', v_sup_e,
    'name', 'Mốc 1000',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 1000,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_pe)
  ));
  v_prog_e := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_te, 'g56-e-gr', jsonb_build_object(
    'supplier_id', v_sup_e,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_pe, 'unit_id', v_ue, 'unit_price_vnd', 100000,
      'program_id', v_prog_e, 'lots', jsonb_build_array(jsonb_build_object('quantity', 1000))
    ))
  ));
  perform inventory._post_movements(v_te, v_we, 'SALES_ORDER', gen_random_uuid(), v_today, jsonb_build_array(
    jsonb_build_object('product_id', v_pe, 'quantity_delta', -700, 'movement_kind', 'SALE')
  ), v_oe);
  perform inventory.record_supplier_rebate(v_te, 'g56-e-reb', v_prog_e, jsonb_build_object(
    'document_no', 'CK-16',
    'document_date', v_today,
    'amount_vnd', 5000000
  ));

  v_res := inventory.create_cost_run(v_te, 'MID_PERIOD', 'g56-e-create');
  v_line := v_res->'lines'->0;
  if (v_line->>'rebate_value')::bigint <> -1500000
     or (v_line->>'periodic_avg')::numeric <> 100000
     or (v_line->>'closing_value_after')::bigint <> 28500000
     or (v_line->>'new_unit_cost')::numeric <> 95000
     or (v_line->>'balance_diff')::bigint <> 0 then
    raise exception 'FAIL: case16_rebate_periodic: %', v_line;
  end if;

  -- =========================================================================
  -- CASE: publish_empty_close
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_od::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_od::text, true);
  insert into inventory.cost_periods (tenant_id, period_month, status)
  values (v_td, v_prev_month, 'OPEN')
  on conflict (tenant_id, period_month) do nothing;
  v_res := inventory.create_cost_run(v_td, 'PERIOD_CLOSE', 'g56-d-empty-close');
  if v_res->>'status' <> 'READY_FOR_REVIEW' or (v_res->>'product_count')::int <> 0 then
    raise exception 'FAIL: publish_empty_close create: %', v_res;
  end if;
  perform inventory.publish_cost_run(v_td, (v_res->>'run_id')::uuid, 'g56-d-empty-close-pub');
  if (select status from inventory.cost_periods where tenant_id = v_td and period_month = v_prev_month) <> 'CLOSED'
     or (select status from inventory.cost_periods where tenant_id = v_td and period_month = v_cur_month) <> 'OPEN' then
    raise exception 'FAIL: publish_empty_close periods status';
  end if;

  -- =========================================================================
  -- INVARIANTS across Task 2 tenants
  -- =========================================================================
  select count(*) into v_bad
  from inventory.product_costs pc
  where pc.tenant_id in (v_ta, v_tb, v_tc, v_td, v_te)
    and pc.ledger_value_vnd <> coalesce((
      select sum(vm.amount_vnd)::bigint
      from inventory.value_movements vm
      where vm.tenant_id = pc.tenant_id and vm.product_id = pc.product_id
    ), 0);
  if v_bad > 0 then
    raise exception 'FAIL: Task 2 ledger_value_vnd invariant broken (% rows)', v_bad;
  end if;

  raise notice 'inventory_costing: Task 1 & Task 2 cases passed';
end;
$$;

