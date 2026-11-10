-- Test suite for inventory_stock_view (T7-G5-2)
-- Run via: psql -f supabase/tests/inventory_stock_view.sql

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_owner_id uuid := gen_random_uuid();
  v_staff_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();

  v_p_zero_id uuid := gen_random_uuid();
  v_p_tylo_id uuid := gen_random_uuid();
  v_p_sort_id uuid := gen_random_uuid();

  v_lot_exp_id uuid := gen_random_uuid();
  v_lot_ok_id uuid := gen_random_uuid();

  v_lot_day_id uuid := gen_random_uuid();
  v_lot_month_id uuid := gen_random_uuid();
  v_lot_year_id uuid := gen_random_uuid();
  v_lot_null_id uuid := gen_random_uuid();

  v_today date := inventory._today();
  v_overview jsonb;
  v_detail jsonb;
  v_summary jsonb;
  v_item jsonb;
begin
  -- 0. Setup dummy auth users, tenant, store, warehouse, and memberships
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  ), (
    v_staff_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'staff-' || substr(v_staff_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name)
  values (v_tenant_id, 'Stock View Tenant');

  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values
    (v_tenant_id, v_owner_id, 'owner', true),
    (v_tenant_id, v_staff_id, 'staff', false);

  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'ST01', 'Cửa hàng chính', 'active');

  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho trung tâm', 'active');

  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  -- Products
  insert into catalog.products (
    id, tenant_id, name, sku, barcode, created_by, updated_by, tracking_mode, expiry_required
  ) values
    (v_p_zero_id, v_tenant_id, 'Enrofloxacin 10%', 'SP-000091', '8930001', v_owner_id, v_owner_id, 'none', false),
    (v_p_tylo_id, v_tenant_id, 'Tylosin 20%', 'SP-000122', '8930002', v_owner_id, v_owner_id, 'lot', true),
    (v_p_sort_id, v_tenant_id, 'Nobivac DHPPi', 'SP-000184', '8930003', v_owner_id, v_owner_id, 'lot', false);

  -- Set session to owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- 1. Test case: product_without_movement_listed_zero
  v_overview := inventory.list_stock_overview(v_tenant_id);
  select elem into v_item
  from jsonb_array_elements(v_overview->'products') elem
  where (elem->>'product_id')::uuid = v_p_zero_id;

  if v_item is null
     or (v_item->>'physical')::numeric <> 0
     or (v_item->>'available')::numeric <> 0 then
    raise exception 'FAIL: product_without_movement_listed_zero: %', v_item;
  end if;

  -- 2. Test case: available_excludes_expired_lot
  -- Tylosin: 11 expired + 3 valid => physical 14, available 3, expired_quantity 11
  insert into inventory.lots (id, tenant_id, product_id, lot_code, lot_code_normalized, expiry_date, expiry_precision, created_by)
  values
    (v_lot_exp_id, v_tenant_id, v_p_tylo_id, 'TY2408', 'ty2408', v_today - interval '5 days', 'DAY', v_owner_id),
    (v_lot_ok_id, v_tenant_id, v_p_tylo_id, 'TY2511', 'ty2511', v_today + interval '15 days', 'DAY', v_owner_id);

  insert into inventory.stock_balances (tenant_id, warehouse_id, product_id, lot_key, physical_quantity)
  values
    (v_tenant_id, v_warehouse_id, v_p_tylo_id, v_lot_exp_id, 11),
    (v_tenant_id, v_warehouse_id, v_p_tylo_id, v_lot_ok_id, 3);

  v_detail := inventory.get_stock_detail(v_tenant_id, v_p_tylo_id);
  if (v_detail->>'physical')::numeric <> 14
     or (v_detail->>'available')::numeric <> 3
     or (v_detail->>'expired_quantity')::numeric <> 11 then
    raise exception 'FAIL: available_excludes_expired_lot: %', v_detail;
  end if;

  -- 3. Test case: lots_sorted_by_expiry_end
  -- DAY 2028-09-30 (code A-DAY), MONTH 2028-09-01 -> end 2028-09-30 (code B-MONTH), YEAR 2028-01-01 -> end 2028-12-31 (code C-YEAR), null HSD (code D-NULL)
  insert into inventory.lots (id, tenant_id, product_id, lot_code, lot_code_normalized, expiry_date, expiry_precision, created_by)
  values
    (v_lot_null_id, v_tenant_id, v_p_sort_id, 'D-NULL', 'd-null', null, null, v_owner_id),
    (v_lot_year_id, v_tenant_id, v_p_sort_id, 'C-YEAR', 'c-year', '2028-01-01'::date, 'YEAR', v_owner_id),
    (v_lot_month_id, v_tenant_id, v_p_sort_id, 'B-MONTH', 'b-month', '2028-09-01'::date, 'MONTH', v_owner_id),
    (v_lot_day_id, v_tenant_id, v_p_sort_id, 'A-DAY', 'a-day', '2028-09-30'::date, 'DAY', v_owner_id);

  insert into inventory.stock_balances (tenant_id, warehouse_id, product_id, lot_key, physical_quantity)
  values
    (v_tenant_id, v_warehouse_id, v_p_sort_id, v_lot_null_id, 5),
    (v_tenant_id, v_warehouse_id, v_p_sort_id, v_lot_year_id, 5),
    (v_tenant_id, v_warehouse_id, v_p_sort_id, v_lot_month_id, 5),
    (v_tenant_id, v_warehouse_id, v_p_sort_id, v_lot_day_id, 5);

  v_detail := inventory.get_stock_detail(v_tenant_id, v_p_sort_id);
  if (v_detail->'lots'->0->>'lot_code') <> 'A-DAY'
     or (v_detail->'lots'->1->>'lot_code') <> 'B-MONTH'
     or (v_detail->'lots'->2->>'lot_code') <> 'C-YEAR'
     or (v_detail->'lots'->3->>'lot_code') <> 'D-NULL'
     or (v_detail->'lots'->3->>'days_to_expiry') is not null then
    raise exception 'FAIL: lots_sorted_by_expiry_end: %', v_detail->'lots';
  end if;

  -- 4 & 5. Test case: owner_cost_from_product_costs & staff_cost_masked
  insert into inventory.product_costs (
    tenant_id, product_id, quantity_on_hand, ledger_value_vnd,
    moving_avg_cost, official_unit_cost, last_ledger_sequence
  ) values (
    v_tenant_id, v_p_tylo_id, 14, 1659000,
    118500, 118500, 2
  );

  v_detail := inventory.get_stock_detail(v_tenant_id, v_p_tylo_id);
  if (v_detail->>'is_owner')::boolean is not true
     or (v_detail->>'financial_masked')::boolean is not false
     or (v_detail->'cost'->>'ledger_value_vnd')::bigint <> 1659000
     or (v_detail->'cost'->>'moving_avg_cost')::numeric <> 118500 then
    raise exception 'FAIL: owner_cost_from_product_costs: %', v_detail;
  end if;

  -- Switch to staff
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);

  v_detail := inventory.get_stock_detail(v_tenant_id, v_p_tylo_id);
  if (v_detail->>'is_owner')::boolean is not false
     or (v_detail->>'financial_masked')::boolean is not true
     or (v_detail->>'cost') is not null then
    raise exception 'FAIL: staff_cost_masked: %', v_detail;
  end if;

  -- Switch back to owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- 6. Test case: latest_movement_is_max_sequence
  insert into inventory.stock_movements (
    tenant_id, ledger_sequence, warehouse_id, product_id, lot_id,
    intent_type, intent_id, movement_kind, quantity_delta, business_date, created_by
  ) values
    (v_tenant_id, 1, v_warehouse_id, v_p_tylo_id, v_lot_exp_id, 'RECEIPT', gen_random_uuid(), 'RECEIPT', 14, v_today - interval '30 days', v_owner_id),
    (v_tenant_id, 2, v_warehouse_id, v_p_tylo_id, v_lot_ok_id, 'SALE', gen_random_uuid(), 'SALE', -2, v_today, v_owner_id);

  v_detail := inventory.get_stock_detail(v_tenant_id, v_p_tylo_id);
  if (v_detail->'latest_movement'->>'movement_kind') <> 'SALE'
     or (v_detail->'latest_movement'->>'quantity_delta')::numeric <> -2 then
    raise exception 'FAIL: latest_movement_is_max_sequence: %', v_detail->'latest_movement';
  end if;

  -- 7. Test case: hub_problems_counts
  -- Setup:
  --   v_p_zero_id: available = 0 -> out (1 product)
  --   v_p_tylo_id: available = 3, threshold = 8 -> low, plus has_expired (TY2408) AND has_near_expiry (TY2511 in 15 days <= 30) -> (1 product with multiple indicators)
  --   v_p_sort_id: available = 20, no threshold, expiry in 2028 -> normal (0 indicators)
  -- Expected: products = 2, out = 1, low = 1, expired = 1, near_expiry = 1
  insert into inventory.stock_policy_settings (tenant_id, near_expiry_days, revision, updated_by)
  values (v_tenant_id, 30, 1, v_owner_id);

  insert into inventory.product_stock_policies (tenant_id, product_id, reorder_threshold, target_level, updated_by)
  values (v_tenant_id, v_p_tylo_id, 8, 24, v_owner_id);

  v_summary := inventory.get_warehouse_hub_summary(v_tenant_id);
  if (v_summary->>'activated')::boolean is not true
     or (v_summary->'problems'->>'out')::int <> 1
     or (v_summary->'problems'->>'low')::int <> 1
     or (v_summary->'problems'->>'expired')::int <> 1
     or (v_summary->'problems'->>'near_expiry')::int <> 1
     or (v_summary->'problems'->>'products')::int <> 2 then
    raise exception 'FAIL: hub_problems_counts: %', v_summary;
  end if;

  -- Rollback all test data
  raise exception 'ROLLBACK_TEST_SUCCESS';
exception
  when others then
    if sqlerrm = 'ROLLBACK_TEST_SUCCESS' then
      raise notice 'inventory_stock_view: OK';
    else
      raise;
    end if;
end $$;

