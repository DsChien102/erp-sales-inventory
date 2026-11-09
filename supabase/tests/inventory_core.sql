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

  -- 8. Test case: replay_same_hash_returns_saved_result
  declare
    v_res jsonb;
  begin
    v_res := inventory._begin_idempotency(v_tenant_id, 'test_scope', 'key_1', 'hash_1');
    if v_res ->> 'decision' <> 'new' then
      raise exception 'FAIL: begin_idempotency_new';
    end if;

    perform inventory._complete_idempotency(
      v_tenant_id, 'test_scope', 'key_1', 'succeeded', '{"ok": true}'::jsonb
    );

    v_res := inventory._begin_idempotency(v_tenant_id, 'test_scope', 'key_1', 'hash_1');
    if v_res ->> 'decision' <> 'replay' or (v_res -> 'result_snapshot' ->> 'ok') <> 'true' then
      raise exception 'FAIL: replay_same_hash_returns_saved_result';
    end if;
  end;

  -- 9. Test case: same_key_other_hash_conflict
  v_caught := false;
  begin
    perform inventory._begin_idempotency(v_tenant_id, 'test_scope', 'key_1', 'other_hash');
  exception when others then
    if sqlerrm like '%IDEMPOTENCY_CONFLICT%' then
      v_caught := true;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: same_key_other_hash_conflict';
  end if;

  -- 10. Test case: period_created_on_first_use
  declare
    v_period_id uuid;
  begin
    v_period_id := inventory._ensure_open_period(v_tenant_id, current_date);
    if v_period_id is null then
      raise exception 'FAIL: period_created_on_first_use';
    end if;

    -- 11. Test case: closed_period_raises
    update inventory.cost_periods
    set status = 'CLOSED'
    where id = v_period_id;

    v_caught := false;
    begin
      perform inventory._ensure_open_period(v_tenant_id, current_date);
    exception when others then
      if sqlerrm like '%PERIOD_CLOSED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: closed_period_raises';
    end if;

    -- Mở lại kỳ để làm tiếp các test Task 4
    update inventory.cost_periods
    set status = 'OPEN'
    where id = v_period_id;
  end;

  -- 12. Test case: post_movements_receipt_moving
  declare
    v_res jsonb;
    v_cost record;
    v_bal record;
    v_prod_lot uuid := gen_random_uuid();
    v_prod_exp uuid := gen_random_uuid();
  begin
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_product_id,
        'quantity_delta', 10,
        'movement_kind', 'RECEIPT',
        'unit_cost', 50000
      )),
      v_user_id
    );

    select physical_quantity into v_bal
    from inventory.stock_balances
    where tenant_id = v_tenant_id and product_id = v_product_id and warehouse_id = v_warehouse_id;
    if v_bal.physical_quantity <> 10 then
      raise exception 'FAIL: post_movements_receipt_moving balance %', v_bal.physical_quantity;
    end if;

    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs
    where tenant_id = v_tenant_id and product_id = v_product_id;
    if v_cost.quantity_on_hand <> 10 or v_cost.ledger_value_vnd <> 500000 or v_cost.moving_avg_cost <> 50000 then
      raise exception 'FAIL: post_movements_receipt_moving cost %', v_cost;
    end if;

    -- 13. Test case: post_movements_sale_moving
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_product_id,
        'quantity_delta', -4,
        'movement_kind', 'SALE'
      )),
      v_user_id
    );

    select physical_quantity into v_bal
    from inventory.stock_balances
    where tenant_id = v_tenant_id and product_id = v_product_id and warehouse_id = v_warehouse_id;
    if v_bal.physical_quantity <> 6 then
      raise exception 'FAIL: post_movements_sale_moving balance %', v_bal.physical_quantity;
    end if;

    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs
    where tenant_id = v_tenant_id and product_id = v_product_id;
    if v_cost.quantity_on_hand <> 6 or v_cost.ledger_value_vnd <> 300000 or v_cost.moving_avg_cost <> 50000 then
      raise exception 'FAIL: post_movements_sale_moving cost %', v_cost;
    end if;

    -- 14. Test case: post_movements_periodic_provisional
    insert into inventory.cost_policies (tenant_id, method, changed_by)
    values (v_tenant_id, 'PERIODIC', v_user_id)
    on conflict (tenant_id) do update set method = 'PERIODIC';

    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_product_id,
        'quantity_delta', -2,
        'movement_kind', 'SALE'
      )),
      v_user_id
    );

    declare
      v_is_prov boolean;
    begin
      select is_provisional into v_is_prov
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;
      if v_is_prov is not true then
        raise exception 'FAIL: post_movements_periodic_provisional';
      end if;
    end;

    -- 15. Test case: post_movements_insufficient_stock
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_product_id,
          'quantity_delta', -100,
          'movement_kind', 'SALE'
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%INSUFFICIENT_STOCK%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: post_movements_insufficient_stock';
    end if;

    -- 16. Test case: post_movements_lot_required
    insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
    values (v_prod_lot, v_tenant_id, 'Hàng theo lô', v_user_id, v_user_id, 'lot', false);

    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_lot,
          'quantity_delta', 5,
          'movement_kind', 'RECEIPT',
          'unit_cost', 20000
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%LOT_REQUIRED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: post_movements_lot_required';
    end if;

    -- 17. Test case: post_movements_lot_not_allowed
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_product_id,
          'lot_code', 'LOT001',
          'quantity_delta', 5,
          'movement_kind', 'RECEIPT',
          'unit_cost', 20000
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%LOT_NOT_ALLOWED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: post_movements_lot_not_allowed';
    end if;

    -- 18. Test case: post_movements_expiry_required
    insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
    values (v_prod_exp, v_tenant_id, 'Hàng bắt buộc date', v_user_id, v_user_id, 'lot', true);

    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_exp,
          'lot_code', 'LOTEXP01',
          'quantity_delta', 5,
          'movement_kind', 'RECEIPT',
          'unit_cost', 30000
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%EXPIRY_REQUIRED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: post_movements_expiry_required';
    end if;

    -- 19. Test case: post_movements_unit_cost_required
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_product_id,
          'quantity_delta', 5,
          'movement_kind', 'RECEIPT'
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%UNIT_COST_REQUIRED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: post_movements_unit_cost_required';
    end if;
  end;

  -- 20. Test case: hub_summary_not_activated_when_no_movement & hub_summary_activated_after_movement
  declare
    v_empty_tenant uuid := gen_random_uuid();
    v_empty_wh uuid := gen_random_uuid();
    v_empty_store uuid := gen_random_uuid();
    v_summary jsonb;
  begin
    insert into iam.tenants (id, name, slug)
    values (v_empty_tenant, 'Empty Tenant', 'empty-' || substr(v_empty_tenant::text, 1, 8));

    insert into inventory.warehouses (id, tenant_id, display_name, status)
    values (v_empty_wh, v_empty_tenant, 'Kho trống', 'active');

    insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
    values (v_empty_tenant, v_empty_store, v_empty_wh, 'active');

    perform set_config('request.jwt.claim.sub', v_user_id::text, true);

    v_summary := inventory.get_warehouse_hub_summary(v_empty_tenant);
    if (v_summary ->> 'activated')::boolean is not false or (v_summary ->> 'problems') is not null then
      raise exception 'FAIL: hub_summary_not_activated_when_no_movement';
    end if;

    -- 21. Test case: hub_summary_activated_after_movement
    insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
    values (v_tenant_id, gen_random_uuid(), v_warehouse_id, 'active')
    on conflict do nothing;

    v_summary := inventory.get_warehouse_hub_summary(v_tenant_id);
    if (v_summary ->> 'activated')::boolean is not true then
      raise exception 'FAIL: hub_summary_activated_after_movement';
    end if;
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
