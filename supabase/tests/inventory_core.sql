-- Test suite for inventory_core (T7-G5-0b)
-- Run via: psql -f supabase/tests/inventory_core.sql (or inside supabase db test runner)

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_user_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();
  v_product_id uuid := gen_random_uuid();
  v_movement_id uuid;
  v_val_id uuid;
  v_caught boolean;
begin
  -- Setup dummy tenant and warehouse
  insert into iam.tenants (id, name, slug)
  values (v_tenant_id, 'Test Tenant', 'test-' || substr(v_tenant_id::text, 1, 8));

  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính', 'active');

  insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
  values (v_product_id, v_tenant_id, 'Sản phẩm test', v_user_id, v_user_id, 'none', false);

  -- 1. Test case: ledger_update_blocked
  insert into inventory.stock_movements (
    tenant_id, ledger_sequence, warehouse_id, product_id,
    intent_type, intent_id, movement_kind,
    quantity_delta, business_date, created_by
  ) values (
    v_tenant_id, 1, v_warehouse_id, v_product_id,
    'RECEIPT', gen_random_uuid(), 'RECEIPT',
    10, current_date, v_user_id
  ) returning id into v_movement_id;

  v_caught := false;
  begin
    update inventory.stock_movements
    set quantity_delta = 20
    where id = v_movement_id;
  exception when others then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: ledger_update_blocked';
  end if;

  -- 2. Test case: ledger_delete_blocked
  v_caught := false;
  begin
    delete from inventory.stock_movements
    where id = v_movement_id;
  exception when others then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: ledger_delete_blocked';
  end if;

  -- 3. Test case: tracking_change_after_movement_locked
  v_caught := false;
  begin
    update catalog.products
    set tracking_mode = 'lot'
    where id = v_product_id;
  exception when others then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: tracking_change_after_movement_locked';
  end if;

  -- 4. Test case: tracking_change_without_movement_ok
  declare
    v_product_no_movement uuid := gen_random_uuid();
  begin
    insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
    values (v_product_no_movement, v_tenant_id, 'SP chưa có biến động', v_user_id, v_user_id, 'none', false);

    update catalog.products
    set tracking_mode = 'lot'
    where id = v_product_no_movement;
  exception when others then
    raise exception 'FAIL: tracking_change_without_movement_ok';
  end;

  -- 5. Test case: value_ledger_update_blocked
  insert into inventory.value_movements (
    tenant_id, ledger_sequence, product_id, movement_id,
    kind, quantity_basis, unit_cost, amount_vnd,
    business_date, created_by
  ) values (
    v_tenant_id, 2, v_product_id, v_movement_id,
    'RECEIPT', 10, 10000, 100000,
    current_date, v_user_id
  ) returning id into v_val_id;

  v_caught := false;
  begin
    update inventory.value_movements
    set amount_vnd = 200000
    where id = v_val_id;
  exception when others then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: value_ledger_update_blocked';
  end if;

  -- 6. Test case: adjust_row_requires_run
  v_caught := false;
  begin
    insert into inventory.value_movements (
      tenant_id, ledger_sequence, product_id,
      kind, quantity_basis, amount_vnd,
      business_date, created_by
    ) values (
      v_tenant_id, 3, v_product_id,
      'COGS_TRUE_UP', 0, 5000,
      current_date, v_user_id
    );
  exception when check_violation then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: adjust_row_requires_run';
  end if;

  -- 7. Test case: rebate_row_requires_rebate_id
  v_caught := false;
  begin
    insert into inventory.value_movements (
      tenant_id, ledger_sequence, product_id,
      kind, quantity_basis, amount_vnd,
      business_date, created_by
    ) values (
      v_tenant_id, 4, v_product_id,
      'SUPPLIER_REBATE', 0, -2000,
      current_date, v_user_id
    );
  exception when check_violation then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: rebate_row_requires_rebate_id';
  end if;

  -- Rollback all test data
  raise exception 'ROLLBACK_TEST_SUCCESS';
exception
  when others then
    if sqlerrm = 'ROLLBACK_TEST_SUCCESS' then
      raise notice 'inventory_core: OK';
    else
      raise;
    end if;
end $$;
