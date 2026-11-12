-- Test suite for inventory_stocktake (T7-G5-5 Task 1)
-- Run via: psql -f supabase/tests/inventory_stocktake.sql

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

create or replace function pg_temp.assert_invariants(p_tenant_id uuid, p_case text)
returns void
language plpgsql
as $$
declare
  v_bad record;
begin
  -- Invariant 1: product_costs.ledger_value_vnd = SUM(value_movements.amount_vnd)
  for v_bad in
    select
      pc.product_id,
      pc.ledger_value_vnd,
      coalesce((
        select sum(vm.amount_vnd)::bigint
        from inventory.value_movements vm
        where vm.tenant_id = p_tenant_id
          and vm.product_id = pc.product_id
      ), 0) as sum_vm
    from inventory.product_costs pc
    where pc.tenant_id = p_tenant_id
  loop
    if v_bad.ledger_value_vnd <> v_bad.sum_vm then
      raise exception 'FAIL: % value invariant mismatch product=% ledger=% vm_sum=%',
        p_case, v_bad.product_id, v_bad.ledger_value_vnd, v_bad.sum_vm;
    end if;
  end loop;

  -- Invariant 2: SUM(stock_balances.physical_quantity) = SUM(stock_movements.quantity_delta)
  for v_bad in
    select
      p.id as product_id,
      coalesce((
        select sum(sb.physical_quantity)
        from inventory.stock_balances sb
        where sb.tenant_id = p_tenant_id
          and sb.product_id = p.id
      ), 0) as sum_sb,
      coalesce((
        select sum(sm.quantity_delta)
        from inventory.stock_movements sm
        where sm.tenant_id = p_tenant_id
          and sm.product_id = p.id
      ), 0) as sum_sm
    from catalog.products p
    where p.tenant_id = p_tenant_id
  loop
    if v_bad.sum_sb <> v_bad.sum_sm then
      raise exception 'FAIL: % stock invariant mismatch product=% sb=% sm=%',
        p_case, v_bad.product_id, v_bad.sum_sb, v_bad.sum_sm;
    end if;
  end loop;
end;
$$;

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_owner_id uuid := gen_random_uuid();
  v_staff_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();

  v_p_oxy uuid := gen_random_uuid();
  v_p_tyl uuid := gen_random_uuid();
  v_p_glove uuid := gen_random_uuid();
  v_p_oil uuid := gen_random_uuid();

  v_lot_ty2511 uuid;
  v_lot_ty2408 uuid;
  v_lot_ty_zero uuid;

  v_today date := inventory._today();
  v_yymmdd text := to_char(inventory._today(), 'YYMMDD');

  v_res jsonb;
  v_res2 jsonb;
  v_sess_all uuid;
  v_sess_prod uuid;
  v_sess_lot uuid;
  v_sess_id uuid;
  v_code text;
  v_line jsonb;
  v_line_oxy uuid;
  v_count_before int;
  v_found_oxy boolean := false;
  v_found_tyl boolean := false;
  v_found_glove boolean := false;
  v_found_oil boolean := false;
  v_found_ty2408_exp boolean := false;
begin
  -- 1. Fixture: Auth, Tenant, Owner + Staff, Store, Warehouse ------------------
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-st-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Chủ cửa hàng"}'::jsonb,
    now(), now(), now()
  ), (
    v_staff_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'staff-st-' || substr(v_staff_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"full_name":"Nguyễn Văn An"}'::jsonb,
    now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Stocktake Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values
    (v_tenant_id, v_owner_id, 'store_owner', true),
    (v_tenant_id, v_staff_id, 'staff', false);

  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'ST01', 'Cửa hàng chính ST', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính ST', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by)
  values (v_tenant_id, 'MOVING', v_owner_id)
  on conflict (tenant_id) do nothing;

  -- 2. Products & Base Units ---------------------------------------------------
  insert into catalog.products (
    id, tenant_id, name, sku, barcode, tracking_mode, expiry_required,
    business_status, reference_id, created_by, updated_by
  ) values
    (v_p_oxy, v_tenant_id, 'Oxytetracycline 100ml', 'OXY-01', '8931001', 'none', false, 'active', 'ST-OXY', v_owner_id, v_owner_id),
    (v_p_tyl, v_tenant_id, 'Tylosin 20%', 'TYL-01', '8931002', 'lot', true, 'active', 'ST-TYL', v_owner_id, v_owner_id),
    (v_p_glove, v_tenant_id, 'Găng tay khám', 'GLV-01', '8931003', 'none', false, 'active', 'ST-GLV', v_owner_id, v_owner_id),
    (v_p_oil, v_tenant_id, 'Dầu khoáng', 'OIL-01', '8931004', 'none', false, 'active', 'ST-OIL', v_owner_id, v_owner_id);

  insert into catalog.product_units (tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_tenant_id, v_p_oxy, 'chai', 1, true),
    (v_tenant_id, v_p_tyl, 'lọ', 1, true),
    (v_tenant_id, v_p_glove, 'hộp', 1, true),
    (v_tenant_id, v_p_oil, 'chai', 1, true);

  -- 3. Seed stock via _post_movements ------------------------------------------
  perform inventory._post_movements(
    v_tenant_id,
    v_warehouse_id,
    'TEST',
    gen_random_uuid(),
    v_today,
    jsonb_build_array(
      jsonb_build_object(
        'product_id', v_p_oxy,
        'quantity_delta', 12,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000,
        'amount_vnd', 120000
      ),
      jsonb_build_object(
        'product_id', v_p_tyl,
        'lot_code', 'TY2511',
        'expiry_date', v_today + 60,
        'expiry_precision', 'DAY',
        'quantity_delta', 3,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000,
        'amount_vnd', 30000
      ),
      jsonb_build_object(
        'product_id', v_p_tyl,
        'lot_code', 'TY2408',
        'expiry_date', v_today - 1,
        'expiry_precision', 'DAY',
        'quantity_delta', 11,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000,
        'amount_vnd', 110000
      ),
      jsonb_build_object(
        'product_id', v_p_tyl,
        'lot_code', 'TY_ZERO',
        'expiry_date', v_today + 30,
        'expiry_precision', 'DAY',
        'quantity_delta', 2,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000,
        'amount_vnd', 20000
      ),
      jsonb_build_object(
        'product_id', v_p_glove,
        'quantity_delta', 5,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000,
        'amount_vnd', 50000
      )
    ),
    v_owner_id
  );

  -- Zero out Găng tay and TY_ZERO while keeping product_costs / lot row
  perform inventory._post_movements(
    v_tenant_id,
    v_warehouse_id,
    'TEST',
    gen_random_uuid(),
    v_today,
    jsonb_build_array(
      jsonb_build_object(
        'product_id', v_p_glove,
        'quantity_delta', -5,
        'movement_kind', 'COUNT_LOSS',
        'reason', 'COUNT'
      ),
      jsonb_build_object(
        'product_id', v_p_tyl,
        'lot_code', 'TY_ZERO',
        'quantity_delta', -2,
        'movement_kind', 'COUNT_LOSS',
        'reason', 'COUNT'
      )
    ),
    v_owner_id
  );

  select id into v_lot_ty2511 from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_tyl and lot_code = 'TY2511';
  select id into v_lot_ty2408 from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_tyl and lot_code = 'TY2408';
  select id into v_lot_ty_zero from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_tyl and lot_code = 'TY_ZERO';

  -- =========================================================================
  -- CASE 1: options_only_stock
  -- =========================================================================
  v_res := inventory.get_stocktake_form_options(v_tenant_id);
  if (v_res->>'all_count')::int <> 3 then
    raise exception 'FAIL: options_only_stock expected all_count=3, got %', v_res->>'all_count';
  end if;

  for v_line in select * from jsonb_array_elements(v_res->'products')
  loop
    if (v_line->>'id')::uuid = v_p_oxy then v_found_oxy := true; end if;
    if (v_line->>'id')::uuid = v_p_tyl then
      v_found_tyl := true;
      if (v_line->>'line_count')::int <> 2 then
        raise exception 'FAIL: options_only_stock Tylosin line_count expected 2, got %', v_line->>'line_count';
      end if;
    end if;
    if (v_line->>'id')::uuid = v_p_glove then v_found_glove := true; end if;
    if (v_line->>'id')::uuid = v_p_oil then v_found_oil := true; end if;
  end loop;

  if not v_found_oxy or not v_found_tyl or v_found_glove or v_found_oil then
    raise exception 'FAIL: options_only_stock product presence mismatch (%)', v_res->'products';
  end if;

  for v_line in select * from jsonb_array_elements(v_res->'lots')
  loop
    if (v_line->>'id')::uuid = v_lot_ty2408 then
      v_found_ty2408_exp := (v_line->>'is_expired')::boolean;
    end if;
  end loop;
  if not v_found_ty2408_exp then
    raise exception 'FAIL: options_only_stock TY2408 is_expired expected true';
  end if;

  -- =========================================================================
  -- CASE 2: open_all, open_product, open_lot (+ sequence & scope_label)
  -- =========================================================================
  v_res := inventory.open_stocktake(
    v_tenant_id,
    'key-open-all-1',
    jsonb_build_object(
      'scope_kind', 'ALL',
      'counter_user_id', v_staff_id,
      'reason', 'Kiểm kê định kỳ'
    )
  );
  v_sess_all := (v_res->>'session_id')::uuid;
  if v_res->>'code' <> ('KK-' || v_yymmdd || '-01') then
    raise exception 'FAIL: open_all expected KK-%-01, got %', v_yymmdd, v_res->>'code';
  end if;

  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_all);
  if v_res2->>'scope_label' <> 'Toàn kho' or jsonb_array_length(v_res2->'lines') <> 3 then
    raise exception 'FAIL: open_all scope_label or line count mismatch: %', v_res2;
  end if;

  -- =========================================================================
  -- CASE 3: blind_count_hides_book (while v_sess_all is COUNTING)
  -- =========================================================================
  for v_line in select * from jsonb_array_elements(v_res2->'lines')
  loop
    if (v_line ? 'book_qty') or (v_line ? 'variance') or (v_line ? 'first_qty')
       or (v_line ? 'recount_qty') or (v_line ? 'adjust_qty') or (v_line ? 'adjust_value_vnd') then
      raise exception 'FAIL: blind_count_hides_book leaked column in line: %', v_line;
    end if;
    if (v_line->>'product_id')::uuid = v_p_oxy then
      v_line_oxy := (v_line->>'line_id')::uuid;
    end if;
  end loop;

  -- =========================================================================
  -- CASE 4: staff_no_money (COUNTING session via staff actor)
  -- =========================================================================
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);
  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_all);
  if (v_res2 ? 'adjustment_value_vnd') then
    raise exception 'FAIL: staff_no_money leaked adjustment_value_vnd to staff';
  end if;
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- =========================================================================
  -- CASE 5: draft_saved
  -- =========================================================================
  perform inventory.save_stocktake_draft(v_tenant_id, v_sess_all, v_line_oxy, 10);
  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_all);
  if (
    select (el->>'draft_qty')::numeric
    from jsonb_array_elements(v_res2->'lines') el
    where (el->>'line_id')::uuid = v_line_oxy
  ) <> 10 then
    raise exception 'FAIL: draft_saved expected draft_qty=10';
  end if;

  v_res2 := inventory.list_stocktake_sessions(v_tenant_id);
  if (
    select (el->>'counted_count')::int
    from jsonb_array_elements(v_res2->'items') el
    where (el->>'id')::uuid = v_sess_all
  ) <> 1 then
    raise exception 'FAIL: draft_saved expected list counted_count=1';
  end if;

  perform inventory.save_stocktake_draft(v_tenant_id, v_sess_all, v_line_oxy, null);
  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_all);
  if (
    select el->>'draft_qty'
    from jsonb_array_elements(v_res2->'lines') el
    where (el->>'line_id')::uuid = v_line_oxy
  ) is not null then
    raise exception 'FAIL: draft_saved expected cleared draft_qty=null';
  end if;

  perform pg_temp.expect_err(
    format('select inventory.save_stocktake_draft(%L, %L, %L, -1)', v_tenant_id, v_sess_all, v_line_oxy),
    'CONTEXT_INVALID',
    'draft_saved negative qty'
  );

  -- =========================================================================
  -- CASE 6: unexpected_requires_cost (on open ALL session)
  -- =========================================================================
  v_res2 := inventory.get_stocktake_unexpected_options(v_tenant_id, v_sess_all);
  v_found_glove := false;
  v_found_oil := false;
  for v_line in select * from jsonb_array_elements(v_res2->'products')
  loop
    if (v_line->>'id')::uuid = v_p_glove then v_found_glove := true; end if;
    if (v_line->>'id')::uuid = v_p_oil then v_found_oil := true; end if;
  end loop;
  if not v_found_glove or v_found_oil then
    raise exception 'FAIL: unexpected_requires_cost expected Glove present and Oil absent (%)', v_res2;
  end if;

  perform pg_temp.expect_err(
    format(
      'select inventory.add_stocktake_unexpected_line(%L, %L, %L::jsonb)',
      v_tenant_id, v_sess_all, jsonb_build_object('product_id', v_p_oil)::text
    ),
    'UNIT_COST_REQUIRED',
    'unexpected_requires_cost oil'
  );

  v_line := inventory.add_stocktake_unexpected_line(
    v_tenant_id,
    v_sess_all,
    jsonb_build_object('product_id', v_p_glove)
  );
  if coalesce((v_line->>'is_unexpected')::boolean, false) <> true then
    raise exception 'FAIL: unexpected_requires_cost expected is_unexpected=true, got %', v_line;
  end if;

  perform pg_temp.expect_err(
    format(
      'select inventory.add_stocktake_unexpected_line(%L, %L, %L::jsonb)',
      v_tenant_id, v_sess_all, jsonb_build_object('product_id', v_p_glove)::text
    ),
    'STOCKTAKE_LINE_EXISTS',
    'unexpected_requires_cost duplicate glove'
  );

  v_line := inventory.add_stocktake_unexpected_line(
    v_tenant_id,
    v_sess_all,
    jsonb_build_object(
      'product_id', v_p_tyl,
      'lot_code', 'TY2601',
      'expiry_date', v_today + 90,
      'expiry_precision', 'DAY'
    )
  );
  if v_line->>'lot_code' <> 'TY2601' or (v_line->>'lot_id') is not null then
    raise exception 'FAIL: unexpected_requires_cost new lot TY2601 mismatch: %', v_line;
  end if;

  -- =========================================================================
  -- CASE 7: hub_open_count (while v_sess_all is open)
  -- =========================================================================
  v_res2 := inventory.get_warehouse_hub_summary(v_tenant_id);
  if (v_res2->'problems'->>'stocktakes_open')::int <> 1 or not inventory._has_open_stocktake(v_tenant_id) then
    raise exception 'FAIL: hub_open_count expected 1 and true, got %', v_res2;
  end if;

  -- =========================================================================
  -- CASE 8: open_conflict_all (ALL is open -> LOT fails with conflict)
  -- =========================================================================
  select count(*)::int into v_count_before from inventory.stocktake_sessions where tenant_id = v_tenant_id;
  v_res2 := inventory.open_stocktake(
    v_tenant_id,
    'key-conflict-lot-under-all',
    jsonb_build_object(
      'scope_kind', 'LOT',
      'lot_id', v_lot_ty2408,
      'counter_user_id', v_staff_id,
      'reason', 'Kiểm tra lô'
    )
  );
  if v_res2->'conflict'->>'code' <> (v_res->>'code')
     or (select count(*)::int from inventory.stocktake_sessions where tenant_id = v_tenant_id) <> v_count_before then
    raise exception 'FAIL: open_conflict_all (ALL open -> LOT) mismatch: %', v_res2;
  end if;

  -- =========================================================================
  -- CASE 9: cancel_requires_reason (cancel v_sess_all)
  -- =========================================================================
  perform pg_temp.expect_err(
    format(
      'select inventory.cancel_stocktake(%L, %L, %L, %L)',
      v_tenant_id, 'key-cancel-blank', v_sess_all, '   '
    ),
    'CANCEL_REASON_REQUIRED',
    'cancel_requires_reason blank'
  );

  v_res2 := inventory.cancel_stocktake(v_tenant_id, 'key-cancel-ok-1', v_sess_all, 'Đóng ca sớm');
  if v_res2->>'status' <> 'CANCELLED' then
    raise exception 'FAIL: cancel_requires_reason expected CANCELLED, got %', v_res2;
  end if;

  perform pg_temp.expect_err(
    format(
      'select inventory.cancel_stocktake(%L, %L, %L, %L)',
      v_tenant_id, 'key-cancel-again', v_sess_all, 'Huỷ lại'
    ),
    'STOCKTAKE_STATE_CHANGED',
    'cancel_requires_reason already cancelled'
  );

  perform pg_temp.expect_err(
    format('select inventory.save_stocktake_draft(%L, %L, %L, 5)', v_tenant_id, v_sess_all, v_line_oxy),
    'STOCKTAKE_STATE_CHANGED',
    'cancel_requires_reason draft after cancel'
  );

  -- After cancel, hub_open_count = 0 and _has_open_stocktake = false
  v_res2 := inventory.get_warehouse_hub_summary(v_tenant_id);
  if (v_res2->'problems'->>'stocktakes_open')::int <> 0 or inventory._has_open_stocktake(v_tenant_id) then
    raise exception 'FAIL: hub_open_count expected 0 and false after cancel, got %', v_res2;
  end if;

  -- =========================================================================
  -- CASE 10: open_lot (-02) & open_conflict_same_product & open_conflict_all
  -- =========================================================================
  v_res := inventory.open_stocktake(
    v_tenant_id,
    'key-open-lot-2',
    jsonb_build_object(
      'scope_kind', 'LOT',
      'lot_id', v_lot_ty2408,
      'counter_user_id', v_owner_id,
      'reason', 'Kiểm lô hết hạn'
    )
  );
  v_sess_lot := (v_res->>'session_id')::uuid;
  v_code := v_res->>'code';
  if v_code <> ('KK-' || v_yymmdd || '-02') then
    raise exception 'FAIL: open_lot expected KK-%-02, got %', v_yymmdd, v_code;
  end if;

  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_lot);
  if v_res2->>'scope_label' <> 'Tylosin 20% · Lô TY2408' or jsonb_array_length(v_res2->'lines') <> 1 then
    raise exception 'FAIL: open_lot scope_label or lines mismatch: %', v_res2;
  end if;

  -- Conflict: open PRODUCT Tylosin while LOT TY2408 is open
  select count(*)::int into v_count_before from inventory.stocktake_sessions where tenant_id = v_tenant_id;
  v_res2 := inventory.open_stocktake(
    v_tenant_id,
    'key-conflict-prod-under-lot',
    jsonb_build_object(
      'scope_kind', 'PRODUCT',
      'product_id', v_p_tyl,
      'counter_user_id', v_owner_id,
      'reason', 'Kiểm SP trùng'
    )
  );
  if v_res2->'conflict'->>'code' <> v_code
     or (select count(*)::int from inventory.stocktake_sessions where tenant_id = v_tenant_id) <> v_count_before then
    raise exception 'FAIL: open_conflict_same_product mismatch: %', v_res2;
  end if;

  -- Conflict: open ALL while LOT is open
  v_res2 := inventory.open_stocktake(
    v_tenant_id,
    'key-conflict-all-under-lot',
    jsonb_build_object(
      'scope_kind', 'ALL',
      'counter_user_id', v_owner_id,
      'reason', 'Kiểm toàn kho trùng'
    )
  );
  if v_res2->'conflict'->>'code' <> v_code
     or (select count(*)::int from inventory.stocktake_sessions where tenant_id = v_tenant_id) <> v_count_before then
    raise exception 'FAIL: open_conflict_all (session open -> ALL) mismatch: %', v_res2;
  end if;

  -- Cancel LOT session then open PRODUCT Tylosin (-03)
  perform inventory.cancel_stocktake(v_tenant_id, 'key-cancel-lot', v_sess_lot, 'Chuyển sang kiểm cả SP');

  v_res := inventory.open_stocktake(
    v_tenant_id,
    'key-open-prod-3',
    jsonb_build_object(
      'scope_kind', 'PRODUCT',
      'product_id', v_p_tyl,
      'counter_user_id', v_owner_id,
      'reason', 'Kiểm cả Tylosin'
    )
  );
  v_sess_prod := (v_res->>'session_id')::uuid;
  if v_res->>'code' <> ('KK-' || v_yymmdd || '-03') then
    raise exception 'FAIL: open_product expected KK-%-03, got %', v_yymmdd, v_res->>'code';
  end if;

  v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_prod);
  if v_res2->>'scope_label' <> 'Tylosin 20%' or jsonb_array_length(v_res2->'lines') <> 2 then
    raise exception 'FAIL: open_product scope_label or lines mismatch: %', v_res2;
  end if;

  -- =========================================================================
  -- CASE 11: open_replay
  -- =========================================================================
  select count(*)::int into v_count_before from inventory.stocktake_sessions where tenant_id = v_tenant_id;
  v_res2 := inventory.open_stocktake(
    v_tenant_id,
    'key-open-prod-3',
    jsonb_build_object(
      'scope_kind', 'PRODUCT',
      'product_id', v_p_tyl,
      'counter_user_id', v_owner_id,
      'reason', 'Kiểm cả Tylosin'
    )
  );
  if (v_res2->>'session_id')::uuid <> v_sess_prod
     or (select count(*)::int from inventory.stocktake_sessions where tenant_id = v_tenant_id) <> v_count_before then
    raise exception 'FAIL: open_replay mismatch: % vs %', v_res2, v_sess_prod;
  end if;

  -- =========================================================================
  -- CASE 12: open_scope_empty
  -- =========================================================================
  perform pg_temp.expect_err(
    format(
      'select inventory.open_stocktake(%L, %L, %L::jsonb)',
      v_tenant_id,
      'key-empty-lot',
      jsonb_build_object(
        'scope_kind', 'LOT',
        'lot_id', v_lot_ty_zero,
        'counter_user_id', v_owner_id,
        'reason', 'Kiểm lô tồn 0'
      )::text
    ),
    'STOCKTAKE_SCOPE_EMPTY',
    'open_scope_empty'
  );

  -- Clean cancel of v_sess_prod
  perform inventory.cancel_stocktake(v_tenant_id, 'key-cancel-prod', v_sess_prod, 'Xong kiểm thử Task 1');
  if inventory._has_open_stocktake(v_tenant_id) then
    raise exception 'FAIL: expected no open stocktake at end of Task 1 tests';
  end if;

  -- =========================================================================
  -- TASK 2: submit_stocktake_first_count & submit_stocktake_recount
  -- State entering Task 2: Oxy=12, TY2511=3, TY2408=11 (all @ 10,000 VND)
  -- =========================================================================
  perform pg_temp.assert_invariants(v_tenant_id, 'task2_start');

  -- CASE 13: first_missing + first_all_match
  declare
    v_line_ty2511 uuid;
    v_line_ty2408 uuid;
    v_mov_before int;
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-all-match',
      jsonb_build_object(
        'scope_kind', 'ALL',
        'counter_user_id', v_staff_id,
        'reason', 'Kiểm toàn kho khớp'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_id);

    select (e->>'line_id')::uuid into v_line_oxy from jsonb_array_elements(v_res2->'lines') e where (e->>'product_id')::uuid = v_p_oxy;
    select (e->>'line_id')::uuid into v_line_ty2511 from jsonb_array_elements(v_res2->'lines') e where (e->>'lot_id')::uuid = v_lot_ty2511;
    select (e->>'line_id')::uuid into v_line_ty2408 from jsonb_array_elements(v_res2->'lines') e where (e->>'lot_id')::uuid = v_lot_ty2408;

    -- first_missing: omit TY2408
    perform pg_temp.expect_err(
      format(
        'select inventory.submit_stocktake_first_count(%L, %L, %L, %L::jsonb)',
        v_tenant_id,
        'key-t2-first-missing',
        v_sess_id,
        jsonb_build_array(
          jsonb_build_object('line_id', v_line_oxy, 'quantity', 12),
          jsonb_build_object('line_id', v_line_ty2511, 'quantity', 3)
        )::text
      ),
      'STOCKTAKE_COUNT_MISSING',
      'first_missing'
    );

    if (inventory.get_stocktake_session(v_tenant_id, v_sess_id)->>'status') <> 'COUNTING' then
      raise exception 'FAIL: first_missing should keep session COUNTING';
    end if;

    -- first_all_match
    select count(*)::int into v_mov_before from inventory.stock_movements where tenant_id = v_tenant_id;
    v_res2 := inventory.submit_stocktake_first_count(
      v_tenant_id,
      'key-t2-first-match-ok',
      v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_oxy, 'quantity', 12),
        jsonb_build_object('line_id', v_line_ty2511, 'quantity', 3),
        jsonb_build_object('line_id', v_line_ty2408, 'quantity', 11)
      )
    );
    if v_res2->>'status' <> 'COMPLETED' or v_res2->>'result_kind' <> 'MATCHED' then
      raise exception 'FAIL: first_all_match unexpected result: %', v_res2;
    end if;
    if (select count(*)::int from inventory.stock_movements where tenant_id = v_tenant_id) <> v_mov_before then
      raise exception 'FAIL: first_all_match created unexpected stock_movements';
    end if;

    v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    if (
      select count(*)
      from jsonb_array_elements(v_res2->'lines') e
      where (e->>'book_qty') is null or (e->>'variance')::numeric <> 0
    ) <> 0 then
      raise exception 'FAIL: first_all_match get_stocktake_session expected book_qty & variance=0: %', v_res2;
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'first_all_match');
  end;

  -- CASE 14: sale_during_count_matches (Review Focus 1)
  declare
    v_line_ty2511 uuid;
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-sale-during-count',
      jsonb_build_object(
        'scope_kind', 'LOT',
        'lot_id', v_lot_ty2511,
        'counter_user_id', v_owner_id,
        'reason', 'Bán trong lúc đếm'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    select (e->>'line_id')::uuid into v_line_ty2511
    from jsonb_array_elements(inventory.get_stocktake_session(v_tenant_id, v_sess_id)->'lines') e;

    -- Sale -2 of TY2511 (3 -> 1)
    perform inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_p_tyl, 'lot_id', v_lot_ty2511, 'quantity_delta', -2, 'movement_kind', 'SALE'
      )),
      v_owner_id
    );

    -- Count physical = 1 -> matches live book!
    v_res2 := inventory.submit_stocktake_first_count(
      v_tenant_id,
      'key-t2-sale-during-count-first',
      v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_ty2511, 'quantity', 1))
    );
    if v_res2->>'status' <> 'COMPLETED' or v_res2->>'result_kind' <> 'MATCHED' then
      raise exception 'FAIL: sale_during_count_matches expected COMPLETED/MATCHED, got %', v_res2;
    end if;
    if exists (
      select 1 from inventory.stock_movements
      where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id
    ) then
      raise exception 'FAIL: sale_during_count_matches must not create STOCKTAKE movement';
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'sale_during_count_matches');
  end;

  -- CASE 15: recount_uses_current_book + recount_replay + recount_wrong_state
  declare
    v_mov_rec record;
    v_cnt_mov_before int;
    v_cnt_r2_before int;
  begin
    -- Oxy book = 12
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-recount-book',
      jsonb_build_object(
        'scope_kind', 'PRODUCT',
        'product_id', v_p_oxy,
        'counter_user_id', v_owner_id,
        'reason', 'Kiểm Oxy có bán'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    select (e->>'line_id')::uuid into v_line_oxy
    from jsonb_array_elements(inventory.get_stocktake_session(v_tenant_id, v_sess_id)->'lines') e;

    v_res2 := inventory.submit_stocktake_first_count(
      v_tenant_id,
      'key-t2-recount-book-first',
      v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 7))
    );
    if v_res2->>'status' <> 'RECOUNT' then
      raise exception 'FAIL: recount_uses_current_book expected RECOUNT, got %', v_res2;
    end if;

    -- Sale -1 of Oxy (12 -> 11) before recount
    perform inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_p_oxy, 'quantity_delta', -1, 'movement_kind', 'SALE'
      )),
      v_owner_id
    );

    -- Recount = 6 -> delta = 6 - 11 = -5 (COUNT_LOSS, LOSS)
    v_res2 := inventory.submit_stocktake_recount(
      v_tenant_id,
      'key-t2-recount-book-ok',
      v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 6))
    );
    if v_res2->>'status' <> 'COMPLETED' or v_res2->>'result_kind' <> 'ADJUSTED' then
      raise exception 'FAIL: recount_uses_current_book commit expected ADJUSTED, got %', v_res2;
    end if;

    select * into v_mov_rec
    from inventory.stock_movements
    where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id;
    if not found or v_mov_rec.movement_kind <> 'COUNT_LOSS' or v_mov_rec.reason <> 'LOSS' or v_mov_rec.quantity_delta <> -5 then
      raise exception 'FAIL: recount_uses_current_book movement mismatch: %', v_mov_rec;
    end if;

    if (
      select physical_quantity from inventory.stock_balances
      where tenant_id = v_tenant_id and warehouse_id = v_warehouse_id and product_id = v_p_oxy
    ) <> 6 then
      raise exception 'FAIL: recount_uses_current_book expected Oxy stock=6';
    end if;

    v_res := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    if ((v_res->'lines'->0->>'book_qty')::numeric <> 11)
       or ((v_res->'lines'->0->>'adjust_qty')::numeric <> -5) then
      raise exception 'FAIL: recount_uses_current_book line snapshot mismatch: %', v_res->'lines'->0;
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'recount_uses_current_book');

    -- recount_replay
    select count(*)::int into v_cnt_mov_before from inventory.stock_movements where tenant_id = v_tenant_id;
    select count(*)::int into v_cnt_r2_before from inventory.stocktake_counts where session_id = v_sess_id and round = 2;
    v_res := inventory.submit_stocktake_recount(
      v_tenant_id,
      'key-t2-recount-book-ok',
      v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 6))
    );
    if v_res <> v_res2
       or (select count(*)::int from inventory.stock_movements where tenant_id = v_tenant_id) <> v_cnt_mov_before
       or (select count(*)::int from inventory.stocktake_counts where session_id = v_sess_id and round = 2) <> v_cnt_r2_before then
      raise exception 'FAIL: recount_replay created extra writes';
    end if;

    -- recount_wrong_state
    perform pg_temp.expect_err(
      format(
        'select inventory.submit_stocktake_recount(%L, %L, %L, %L::jsonb)',
        v_tenant_id,
        'key-t2-recount-wrong-state',
        v_sess_id,
        jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 6))::text
      ),
      'STOCKTAKE_STATE_CHANGED',
      'recount_wrong_state'
    );
  end;

  -- CASE 16: matched_line_not_adjusted_after_sale + expired_write_off + staff_no_money (COMPLETED)
  -- Restock TY2511 +2 -> TY2511=3, TY2408=11
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object(
      'product_id', v_p_tyl, 'lot_id', v_lot_ty2511, 'quantity_delta', 2,
      'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 20000
    )),
    v_owner_id
  );
  declare
    v_line_ty2511 uuid;
    v_line_ty2408 uuid;
    v_mov_count int;
    v_mov_rec record;
    v_val_rec record;
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-tyl-matched-and-expired',
      jsonb_build_object(
        'scope_kind', 'PRODUCT',
        'product_id', v_p_tyl,
        'counter_user_id', v_owner_id,
        'reason', 'Kiểm Tylosin + xuất hủy lô hết hạn'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    select (e->>'line_id')::uuid into v_line_ty2511 from jsonb_array_elements(v_res2->'lines') e where (e->>'lot_id')::uuid = v_lot_ty2511;
    select (e->>'line_id')::uuid into v_line_ty2408 from jsonb_array_elements(v_res2->'lines') e where (e->>'lot_id')::uuid = v_lot_ty2408;

    -- First count: TY2511 matches (3), TY2408 mismatches (0)
    v_res2 := inventory.submit_stocktake_first_count(
      v_tenant_id,
      'key-t2-tyl-first',
      v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_ty2511, 'quantity', 3),
        jsonb_build_object('line_id', v_line_ty2408, 'quantity', 0)
      )
    );
    if v_res2->>'status' <> 'RECOUNT' then
      raise exception 'FAIL: matched_line_not_adjusted_after_sale expected RECOUNT';
    end if;

    -- Sale -1 on matched line TY2511 (3 -> 2)
    perform inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_p_tyl, 'lot_id', v_lot_ty2511, 'quantity_delta', -1, 'movement_kind', 'SALE'
      )),
      v_owner_id
    );

    -- Recount only TY2408=0 with loss_reason EXPIRED
    v_res2 := inventory.submit_stocktake_recount(
      v_tenant_id,
      'key-t2-tyl-recount',
      v_sess_id,
      jsonb_build_array(jsonb_build_object(
        'line_id', v_line_ty2408, 'quantity', 0, 'loss_reason', 'EXPIRED'
      ))
    );
    if v_res2->>'status' <> 'COMPLETED' or v_res2->>'result_kind' <> 'ADJUSTED' then
      raise exception 'FAIL: expired_write_off expected ADJUSTED, got %', v_res2;
    end if;

    select count(*)::int into v_mov_count
    from inventory.stock_movements
    where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id;
    if v_mov_count <> 1 then
      raise exception 'FAIL: matched_line_not_adjusted_after_sale expected exactly 1 movement, got %', v_mov_count;
    end if;

    select * into v_mov_rec
    from inventory.stock_movements
    where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id;
    if v_mov_rec.lot_id <> v_lot_ty2408 or v_mov_rec.movement_kind <> 'WRITE_OFF'
       or v_mov_rec.reason <> 'EXPIRED' or v_mov_rec.quantity_delta <> -11 then
      raise exception 'FAIL: expired_write_off movement mismatch: %', v_mov_rec;
    end if;

    select * into v_val_rec
    from inventory.value_movements
    where tenant_id = v_tenant_id and movement_id = v_mov_rec.id;
    if v_val_rec.kind <> 'WRITE_OFF' or v_val_rec.amount_vnd <> -110000 then
      raise exception 'FAIL: expired_write_off value_movement mismatch: %', v_val_rec;
    end if;

    -- Owner sees money fields; staff does not
    v_res := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    if (v_res->>'adjustment_value_vnd')::bigint <> -110000 then
      raise exception 'FAIL: expired_write_off owner adjustment_value_vnd expected -110000, got %', v_res->>'adjustment_value_vnd';
    end if;

    perform set_config('request.jwt.claim.sub', v_staff_id::text, true);
    v_res := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    if (v_res ? 'adjustment_value_vnd')
       or exists (select 1 from jsonb_array_elements(v_res->'lines') e where (e ? 'adjust_value_vnd')) then
      raise exception 'FAIL: staff_no_money leaked money fields on completed session';
    end if;
    perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

    perform pg_temp.assert_invariants(v_tenant_id, 'expired_write_off');
  end;

  -- CASE 17: damaged_write_off (Oxy 6 -> 4)
  declare
    v_mov_rec record;
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-damaged-open',
      jsonb_build_object(
        'scope_kind', 'PRODUCT',
        'product_id', v_p_oxy,
        'counter_user_id', v_owner_id,
        'reason', 'Kiểm hàng hỏng'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    select (e->>'line_id')::uuid into v_line_oxy
    from jsonb_array_elements(inventory.get_stocktake_session(v_tenant_id, v_sess_id)->'lines') e;

    perform inventory.submit_stocktake_first_count(
      v_tenant_id, 'key-t2-damaged-first', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 4))
    );
    perform inventory.submit_stocktake_recount(
      v_tenant_id, 'key-t2-damaged-recount', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 4, 'loss_reason', 'DAMAGED'))
    );

    select * into v_mov_rec
    from inventory.stock_movements
    where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id;
    if v_mov_rec.movement_kind <> 'WRITE_OFF' or v_mov_rec.reason <> 'DAMAGED' or v_mov_rec.quantity_delta <> -2 then
      raise exception 'FAIL: damaged_write_off mismatch: %', v_mov_rec;
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'damaged_write_off');
  end;

  -- CASE 18: count_gain_moving + unexpected_new_lot_gain (Oxy=4->6 +2, TY2511=2, TY2601=0->4 +4)
  declare
    v_line_ty2511 uuid;
    v_line_ty2601 uuid;
    v_new_lot_id uuid;
    v_val_rec record;
    v_mov_rec record;
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-gain-open',
      jsonb_build_object(
        'scope_kind', 'ALL',
        'counter_user_id', v_owner_id,
        'reason', 'Kiểm phát sinh thừa + lô mới'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    v_line := inventory.add_stocktake_unexpected_line(
      v_tenant_id,
      v_sess_id,
      jsonb_build_object(
        'product_id', v_p_tyl,
        'lot_code', 'TY2601',
        'expiry_date', v_today + 90,
        'expiry_precision', 'DAY'
      )
    );
    v_line_ty2601 := (v_line->>'line_id')::uuid;

    v_res2 := inventory.get_stocktake_session(v_tenant_id, v_sess_id);
    select (e->>'line_id')::uuid into v_line_oxy from jsonb_array_elements(v_res2->'lines') e where (e->>'product_id')::uuid = v_p_oxy;
    select (e->>'line_id')::uuid into v_line_ty2511 from jsonb_array_elements(v_res2->'lines') e where (e->>'lot_id')::uuid = v_lot_ty2511;

    perform inventory.submit_stocktake_first_count(
      v_tenant_id,
      'key-t2-gain-first',
      v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_oxy, 'quantity', 6),
        jsonb_build_object('line_id', v_line_ty2511, 'quantity', 2),
        jsonb_build_object('line_id', v_line_ty2601, 'quantity', 4)
      )
    );

    v_res2 := inventory.submit_stocktake_recount(
      v_tenant_id,
      'key-t2-gain-recount',
      v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_oxy, 'quantity', 6),
        jsonb_build_object('line_id', v_line_ty2601, 'quantity', 4)
      )
    );
    if v_res2->>'result_kind' <> 'ADJUSTED' then
      raise exception 'FAIL: count_gain_moving expected ADJUSTED, got %', v_res2;
    end if;

    -- Check Oxy COUNT_GAIN +2 @ 10000 = 20000
    select vm.* into v_val_rec
    from inventory.stock_movements sm
    join inventory.value_movements vm on vm.movement_id = sm.id
    where sm.tenant_id = v_tenant_id and sm.intent_type = 'STOCKTAKE' and sm.intent_id = v_sess_id
      and sm.product_id = v_p_oxy;
    if v_val_rec.kind <> 'COUNT_GAIN' or v_val_rec.unit_cost <> 10000 or v_val_rec.amount_vnd <> 20000 then
      raise exception 'FAIL: count_gain_moving Oxy valuation mismatch: %', v_val_rec;
    end if;

    -- Check TY2601 lot created + COUNT_GAIN +4
    select id into v_new_lot_id
    from inventory.lots
    where tenant_id = v_tenant_id and product_id = v_p_tyl and lot_code = 'TY2601';
    if v_new_lot_id is null then
      raise exception 'FAIL: unexpected_new_lot_gain TY2601 lot not created';
    end if;

    select * into v_mov_rec
    from inventory.stock_movements
    where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id
      and lot_id = v_new_lot_id;
    if not found or v_mov_rec.movement_kind <> 'COUNT_GAIN' or v_mov_rec.quantity_delta <> 4 then
      raise exception 'FAIL: unexpected_new_lot_gain movement mismatch: %', v_mov_rec;
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'count_gain_moving_and_new_lot');
  end;

  -- CASE 19: recount_back_to_book (Oxy=6 -> first 4 -> recount 6 -> MATCHED)
  begin
    v_res := inventory.open_stocktake(
      v_tenant_id,
      'key-t2-back-to-book-open',
      jsonb_build_object(
        'scope_kind', 'PRODUCT',
        'product_id', v_p_oxy,
        'counter_user_id', v_owner_id,
        'reason', 'Đếm lại khớp sổ'
      )
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    select (e->>'line_id')::uuid into v_line_oxy
    from jsonb_array_elements(inventory.get_stocktake_session(v_tenant_id, v_sess_id)->'lines') e;

    perform inventory.submit_stocktake_first_count(
      v_tenant_id, 'key-t2-back-to-book-first', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 4))
    );
    v_res2 := inventory.submit_stocktake_recount(
      v_tenant_id, 'key-t2-back-to-book-recount', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_oxy, 'quantity', 6))
    );
    if v_res2->>'status' <> 'COMPLETED' or v_res2->>'result_kind' <> 'MATCHED' then
      raise exception 'FAIL: recount_back_to_book expected MATCHED, got %', v_res2;
    end if;
    if exists (
      select 1 from inventory.stock_movements
      where tenant_id = v_tenant_id and intent_type = 'STOCKTAKE' and intent_id = v_sess_id
    ) then
      raise exception 'FAIL: recount_back_to_book should not create stock_movements';
    end if;
    perform pg_temp.assert_invariants(v_tenant_id, 'recount_back_to_book');
  end;

  -- CASE 20: count_gain_periodic (PERIODIC tenant: COUNT_GAIN official 12000, COUNT_LOSS official vs provisional)
  declare
    v_per_tenant uuid := gen_random_uuid();
    v_per_owner uuid := gen_random_uuid();
    v_per_store uuid := gen_random_uuid();
    v_per_wh uuid := gen_random_uuid();
    v_per_p_priced uuid := gen_random_uuid();
    v_per_p_unpriced uuid := gen_random_uuid();
    v_cv_id uuid := gen_random_uuid();
    v_line_priced uuid;
    v_line_unpriced uuid;
    v_val_rec record;
  begin
    insert into auth.users (
      id, instance_id, aud, role, email,
      raw_app_meta_data, raw_user_meta_data,
      email_confirmed_at, created_at, updated_at
    ) values (
      v_per_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'owner-per-' || substr(v_per_owner::text, 1, 8) || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{"full_name":"Chủ Định Kỳ"}'::jsonb,
      now(), now(), now()
    );
    insert into iam.tenants (id, display_name) values (v_per_tenant, 'Periodic Stocktake Tenant');
    insert into iam.memberships (tenant_id, user_id, role, is_owner)
    values (v_per_tenant, v_per_owner, 'store_owner', true);
    insert into iam.stores (id, tenant_id, code, display_name, status)
    values (v_per_store, v_per_tenant, 'PER01', 'Cửa hàng định kỳ', 'active');
    insert into inventory.warehouses (id, tenant_id, display_name, status)
    values (v_per_wh, v_per_tenant, 'Kho định kỳ', 'active');
    insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
    values (v_per_tenant, v_per_store, v_per_wh, 'active');

    perform set_config('request.jwt.claims', json_build_object('sub', v_per_owner::text, 'role', 'authenticated')::text, true);
    perform set_config('request.jwt.claim.sub', v_per_owner::text, true);

    insert into inventory.cost_policies (tenant_id, method, changed_by)
    values (v_per_tenant, 'PERIODIC', v_per_owner);

    insert into catalog.products (
      id, tenant_id, name, sku, tracking_mode, expiry_required,
      business_status, reference_id, created_by, updated_by
    ) values
      (v_per_p_priced, v_per_tenant, 'SP Có Giá Chính Thức', 'PER-1', 'none', false, 'active', 'PER-1', v_per_owner, v_per_owner),
      (v_per_p_unpriced, v_per_tenant, 'SP Tạm Tính', 'PER-2', 'none', false, 'active', 'PER-2', v_per_owner, v_per_owner);

    insert into catalog.product_units (tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
    values
      (v_per_tenant, v_per_p_priced, 'hộp', 1, true),
      (v_per_tenant, v_per_p_unpriced, 'hộp', 1, true);

    perform inventory._post_movements(
      v_per_tenant, v_per_wh, 'TEST', gen_random_uuid(), v_today,
      jsonb_build_array(
        jsonb_build_object('product_id', v_per_p_priced, 'quantity_delta', 5, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 50000),
        jsonb_build_object('product_id', v_per_p_unpriced, 'quantity_delta', 5, 'movement_kind', 'RECEIPT', 'unit_cost', 10000, 'amount_vnd', 50000)
      ),
      v_per_owner
    );

    -- Official periodic cost 12,000 for v_per_p_priced only
    insert into inventory.cost_versions (id, tenant_id, product_id, unit_cost, method, effective_from_sequence)
    values (v_cv_id, v_per_tenant, v_per_p_priced, 12000, 'PERIODIC', 1);
    update inventory.product_costs
    set official_version_id = v_cv_id,
        official_unit_cost = 12000
    where tenant_id = v_per_tenant and product_id = v_per_p_priced;

    -- Part A: COUNT_GAIN on priced -> 12,000 (official)
    v_res := inventory.open_stocktake(
      v_per_tenant, 'key-per-gain-open',
      jsonb_build_object('scope_kind', 'PRODUCT', 'product_id', v_per_p_priced, 'counter_user_id', v_per_owner, 'reason', 'Kiểm thừa định kỳ')
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    select (e->>'line_id')::uuid into v_line_priced
    from jsonb_array_elements(inventory.get_stocktake_session(v_per_tenant, v_sess_id)->'lines') e;

    perform inventory.submit_stocktake_first_count(
      v_per_tenant, 'key-per-gain-first', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_priced, 'quantity', 7))
    );
    perform inventory.submit_stocktake_recount(
      v_per_tenant, 'key-per-gain-recount', v_sess_id,
      jsonb_build_array(jsonb_build_object('line_id', v_line_priced, 'quantity', 7))
    );

    select vm.* into v_val_rec
    from inventory.stock_movements sm
    join inventory.value_movements vm on vm.movement_id = sm.id
    where sm.tenant_id = v_per_tenant and sm.intent_type = 'STOCKTAKE' and sm.intent_id = v_sess_id;
    if v_val_rec.kind <> 'COUNT_GAIN' or v_val_rec.unit_cost <> 12000 or v_val_rec.amount_vnd <> 24000 or v_val_rec.is_provisional then
      raise exception 'FAIL: count_gain_periodic COUNT_GAIN mismatch: %', v_val_rec;
    end if;

    -- Part B: COUNT_LOSS on priced (12,000, non-provisional) vs unpriced (provisional = true)
    v_res := inventory.open_stocktake(
      v_per_tenant, 'key-per-loss-open',
      jsonb_build_object('scope_kind', 'ALL', 'counter_user_id', v_per_owner, 'reason', 'Kiểm thiếu định kỳ')
    );
    v_sess_id := (v_res->>'session_id')::uuid;
    v_res2 := inventory.get_stocktake_session(v_per_tenant, v_sess_id);
    select (e->>'line_id')::uuid into v_line_priced from jsonb_array_elements(v_res2->'lines') e where (e->>'product_id')::uuid = v_per_p_priced;
    select (e->>'line_id')::uuid into v_line_unpriced from jsonb_array_elements(v_res2->'lines') e where (e->>'product_id')::uuid = v_per_p_unpriced;

    perform inventory.submit_stocktake_first_count(
      v_per_tenant, 'key-per-loss-first', v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_priced, 'quantity', 6),
        jsonb_build_object('line_id', v_line_unpriced, 'quantity', 4)
      )
    );
    perform inventory.submit_stocktake_recount(
      v_per_tenant, 'key-per-loss-recount', v_sess_id,
      jsonb_build_array(
        jsonb_build_object('line_id', v_line_priced, 'quantity', 6, 'loss_reason', 'LOSS'),
        jsonb_build_object('line_id', v_line_unpriced, 'quantity', 4, 'loss_reason', 'LOSS')
      )
    );

    select vm.* into v_val_rec
    from inventory.stock_movements sm
    join inventory.value_movements vm on vm.movement_id = sm.id
    where sm.tenant_id = v_per_tenant and sm.intent_type = 'STOCKTAKE' and sm.intent_id = v_sess_id
      and sm.product_id = v_per_p_priced;
    if v_val_rec.kind <> 'COUNT_LOSS' or v_val_rec.unit_cost <> 12000 or v_val_rec.amount_vnd <> -12000 or v_val_rec.is_provisional then
      raise exception 'FAIL: count_gain_periodic priced COUNT_LOSS mismatch: %', v_val_rec;
    end if;

    select vm.* into v_val_rec
    from inventory.stock_movements sm
    join inventory.value_movements vm on vm.movement_id = sm.id
    where sm.tenant_id = v_per_tenant and sm.intent_type = 'STOCKTAKE' and sm.intent_id = v_sess_id
      and sm.product_id = v_per_p_unpriced;
    if v_val_rec.kind <> 'COUNT_LOSS' or v_val_rec.amount_vnd <> -10000 or not v_val_rec.is_provisional then
      raise exception 'FAIL: count_gain_periodic unpriced COUNT_LOSS expected is_provisional=true: %', v_val_rec;
    end if;

    perform pg_temp.expect_err(
      format(
        'select inventory.open_stocktake(%L, %L, %L::jsonb)',
        v_per_tenant,
        'key-missing-scope-kind',
        jsonb_build_object('counter_user_id', v_per_owner, 'reason', 'Thiếu phạm vi')::text
      ),
      'CONTEXT_INVALID',
      'open_stocktake missing scope_kind'
    );

    perform pg_temp.assert_invariants(v_per_tenant, 'count_gain_periodic');
  end;
end $$;

