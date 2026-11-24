-- Test suite for inventory_stock_policy (T7-G5-2a)
-- Run via: psql -f supabase/tests/inventory_stock_policy.sql

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_owner_id uuid := gen_random_uuid();
  v_staff_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();

  v_p1_id uuid := gen_random_uuid();
  v_p2_id uuid := gen_random_uuid();
  v_p3_id uuid := gen_random_uuid();
  v_p_none_id uuid := gen_random_uuid();

  v_lot1_id uuid := gen_random_uuid();
  v_lot2_id uuid := gen_random_uuid();
  v_lot3_id uuid := gen_random_uuid();
  v_lot4_id uuid := gen_random_uuid();

  v_today date := inventory._today();
  v_policy jsonb;
  v_res jsonb;
  v_caught boolean;
  v_row record;
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
  values (v_tenant_id, 'Stock Policy Tenant');

  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values
    (v_tenant_id, v_owner_id, 'store_owner', true),
    (v_tenant_id, v_staff_id, 'staff', false);

  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'ST01', 'Kho CH', 'active');

  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho tổng', 'active');

  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  -- Products
  insert into catalog.products (id, tenant_id, name, sku, created_by, updated_by, tracking_mode, expiry_required, reference_id)
  values
    (v_p1_id, v_tenant_id, 'Nobivac DHPPi', 'NOBI', v_owner_id, v_owner_id, 'lot', true, 'REF-' || (v_p1_id)::text),
    (v_p2_id, v_tenant_id, 'Amoxicillin 500', 'AMOX', v_owner_id, v_owner_id, 'lot', true, 'REF-' || (v_p2_id)::text),
    (v_p3_id, v_tenant_id, 'Tylosin 200', 'TYLO', v_owner_id, v_owner_id, 'lot', true, 'REF-' || (v_p3_id)::text),
    (v_p_none_id, v_tenant_id, 'Bông gạc y tế', 'BONG', v_owner_id, v_owner_id, 'none', false, 'REF-' || (v_p_none_id)::text);

  -- Set session to owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- 1. Test case: expired_lot_excluded_from_available
  -- P1 has 2 lots: lot1 expired yesterday (qty 11), lot2 expires in 60 days (qty 3)
  insert into inventory.lots (id, tenant_id, product_id, lot_code, lot_code_normalized, expiry_date, expiry_precision, created_by)
  values
    (v_lot1_id, v_tenant_id, v_p1_id, 'L01', 'l01', v_today - interval '1 day', 'DAY', v_owner_id),
    (v_lot2_id, v_tenant_id, v_p1_id, 'L02', 'l02', v_today + interval '60 days', 'DAY', v_owner_id);

  insert into inventory.stock_balances (tenant_id, warehouse_id, product_id, lot_key, physical_quantity)
  values
    (v_tenant_id, v_warehouse_id, v_p1_id, v_lot1_id, 11),
    (v_tenant_id, v_warehouse_id, v_p1_id, v_lot2_id, 3);

  select * into v_row from inventory._product_stock_rows(v_tenant_id) where product_id = v_p1_id;
  if v_row.physical <> 14 or v_row.available <> 3 or not v_row.has_expired then
    raise exception 'FAIL: expired_lot_excluded_from_available: expected physical 14, available 3, has_expired true, got physical %, available %, has_expired %',
      v_row.physical, v_row.available, v_row.has_expired;
  end if;

  -- 2. Test case: month_precision_expires_end_of_month
  -- P2 has lot with expiry_date = 1st day of current month, precision = 'MONTH'.
  -- Its effective expiry end is last day of current month >= today, so not expired.
  insert into inventory.lots (id, tenant_id, product_id, lot_code, lot_code_normalized, expiry_date, expiry_precision, created_by)
  values
    (v_lot3_id, v_tenant_id, v_p2_id, 'L03', 'l03', date_trunc('month', v_today)::date, 'MONTH', v_owner_id);

  insert into inventory.stock_balances (tenant_id, warehouse_id, product_id, lot_key, physical_quantity)
  values
    (v_tenant_id, v_warehouse_id, v_p2_id, v_lot3_id, 5);

  select * into v_row from inventory._product_stock_rows(v_tenant_id) where product_id = v_p2_id;
  if v_row.has_expired then
    raise exception 'FAIL: month_precision_expires_end_of_month: expected has_expired false, got true';
  end if;

  -- 3. Test case: near_expiry_null_when_unset
  -- Currently no stock_policy_settings exists. Near expiry should be false.
  select * into v_row from inventory._product_stock_rows(v_tenant_id) where product_id = v_p1_id;
  if v_row.has_near_expiry then
    raise exception 'FAIL: near_expiry_null_when_unset: expected has_near_expiry false, got true';
  end if;

  -- 4. Test case: override_beats_default
  -- Set default near_expiry_days = 30, and override for P1 = 90.
  -- Lot2 has expiry in 60 days. With default 30, 60 > 30 so not near. But with override 90, 60 <= 90 so near!
  v_res := inventory.save_near_expiry_policy(
    v_tenant_id,
    'idemp-test-near-1',
    0,
    30,
    jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'days', 90))
  );

  select * into v_row from inventory._product_stock_rows(v_tenant_id) where product_id = v_p1_id;
  if not v_row.has_near_expiry then
    raise exception 'FAIL: override_beats_default: expected has_near_expiry true for P1 with 90 days override, got false';
  end if;

  -- Check revision bumped to 1
  if (v_res->>'revision')::int <> 1 then
    raise exception 'FAIL: revision expected 1, got %', v_res->>'revision';
  end if;

  -- 5. Test case: stale_revision_conflict
  v_caught := false;
  begin
    perform inventory.save_stock_thresholds(
      v_tenant_id,
      'idemp-test-stale',
      0, -- Expected 0, but current is 1
      jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 10, 'target_level', 20))
    );
  exception when others then
    if sqlerrm like '%VERSION_CONFLICT%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: stale_revision_conflict: expected VERSION_CONFLICT';
  end if;

  -- 6. Test case: replay_same_key_returns_same_revision
  -- Save threshold with valid revision 1
  v_res := inventory.save_stock_thresholds(
    v_tenant_id,
    'idemp-thresh-1',
    1,
    jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 10, 'target_level', 20))
  );
  if (v_res->>'revision')::int <> 2 then
    raise exception 'FAIL: save_stock_thresholds expected revision 2, got %', v_res->>'revision';
  end if;

  -- Replay same call
  v_res := inventory.save_stock_thresholds(
    v_tenant_id,
    'idemp-thresh-1',
    1,
    jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 10, 'target_level', 20))
  );
  if (v_res->>'revision')::int <> 2 then
    raise exception 'FAIL: replay_same_key_returns_same_revision expected 2, got %', v_res->>'revision';
  end if;

  -- 7. Test case: invalid_threshold_rejected (target < threshold; decimal 1.5)
  v_caught := false;
  begin
    perform inventory.save_stock_thresholds(
      v_tenant_id,
      'idemp-invalid-1',
      2,
      jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 20, 'target_level', 10))
    );
  exception when others then
    if sqlerrm like '%CONTEXT_INVALID%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: invalid_threshold_rejected (target < threshold): expected CONTEXT_INVALID';
  end if;

  v_caught := false;
  begin
    perform inventory.save_stock_thresholds(
      v_tenant_id,
      'idemp-invalid-2',
      2,
      jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 1.5, 'target_level', 10))
    );
  exception when others then
    if sqlerrm like '%CONTEXT_INVALID%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: invalid_threshold_rejected (decimal 1.5): expected CONTEXT_INVALID';
  end if;

  -- 8. Test case: staff_cannot_save
  -- Switch JWT to staff
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);

  v_caught := false;
  begin
    perform inventory.save_stock_thresholds(
      v_tenant_id,
      'idemp-staff-1',
      2,
      jsonb_build_array(jsonb_build_object('product_id', v_p1_id, 'reorder_threshold', 10, 'target_level', 20))
    );
  exception when others then
    if sqlerrm like '%PERMISSION_DENIED%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: staff_cannot_save thresholds: expected PERMISSION_DENIED';
  end if;

  v_caught := false;
  begin
    perform inventory.save_near_expiry_policy(
      v_tenant_id,
      'idemp-staff-2',
      2,
      30,
      '[]'::jsonb
    );
  exception when others then
    if sqlerrm like '%PERMISSION_DENIED%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: staff_cannot_save near_expiry: expected PERMISSION_DENIED';
  end if;

  -- Staff can read get_stock_policy
  v_policy := inventory.get_stock_policy(v_tenant_id);
  if (v_policy->>'is_owner')::boolean is not false then
    raise exception 'FAIL: staff get_stock_policy is_owner should be false';
  end if;

  -- Switch back to owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- 9. Test case: override_requires_lot_product
  v_caught := false;
  begin
    perform inventory.save_near_expiry_policy(
      v_tenant_id,
      'idemp-none-lot',
      2,
      30,
      jsonb_build_array(jsonb_build_object('product_id', v_p_none_id, 'days', 45))
    );
  exception when others then
    if sqlerrm like '%CONTEXT_INVALID%' then
      v_caught := true;
    else
      raise;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: override_requires_lot_product: expected CONTEXT_INVALID for non-lot product';
  end if;

  -- 10. Test case: overrides_replace_whole_list
  -- Currently P1 has override 90 and thresholds 10/20.
  -- Now save near expiry with override only for P2 (empty P1).
  v_res := inventory.save_near_expiry_policy(
    v_tenant_id,
    'idemp-replace-list',
    2,
    30,
    jsonb_build_array(jsonb_build_object('product_id', v_p2_id, 'days', 45))
  );

  -- P1 near_expiry_days should be null, but reorder_threshold & target_level preserved!
  select * into v_row from inventory.product_stock_policies where tenant_id = v_tenant_id and product_id = v_p1_id;
  if v_row.near_expiry_days is not null or v_row.reorder_threshold <> 10 or v_row.target_level <> 20 then
    raise exception 'FAIL: overrides_replace_whole_list: P1 near_expiry_days should be null and thresholds preserved, got near_expiry_days %, threshold %, target %',
      v_row.near_expiry_days, v_row.reorder_threshold, v_row.target_level;
  end if;

  -- Rollback all test data
  raise exception 'ROLLBACK_TEST_SUCCESS';
exception
  when others then
    if sqlerrm = 'ROLLBACK_TEST_SUCCESS' then
      raise notice 'inventory_stock_policy: OK';
    else
      raise;
    end if;
end $$;

