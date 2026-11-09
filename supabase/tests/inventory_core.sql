-- Test suite for inventory_core (T7-G5-0b)
-- Run via: psql -f supabase/tests/inventory_core.sql (or inside supabase db test runner)

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_user_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();
  v_product_id uuid := gen_random_uuid();
  v_movement_id uuid;
  v_caught boolean;
  v_err_code text;
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
    to_state, valuation_state, quantity_delta, business_date, created_by
  ) values (
    v_tenant_id, 1, v_warehouse_id, v_product_id,
    'RECEIPT', gen_random_uuid(), 'INITIAL',
    'SELLABLE', 'CONFIRMED', 10, current_date, v_user_id
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
