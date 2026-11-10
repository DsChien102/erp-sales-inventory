-- Test suite for inventory_core (T7-G5-0b)
-- Run via: psql -f supabase/tests/inventory_core.sql (or inside supabase db test runner)

do $$
declare
  v_tenant_id uuid := gen_random_uuid();
  v_user_id uuid := gen_random_uuid();
  v_staff_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_product_id uuid := gen_random_uuid();
  v_movement_id uuid;
  v_val_id uuid;
  v_caught boolean;
  v_seq bigint;
begin
  -- 0. Setup dummy auth users, tenant, store, warehouse, and owner membership
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_user_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-' || substr(v_user_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  ), (
    v_staff_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'staff-' || substr(v_staff_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name)
  values (v_tenant_id, 'Test Tenant');

  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values
    (v_tenant_id, v_user_id, 'owner', true),
    (v_tenant_id, v_staff_id, 'staff', false);

  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'STORE01', 'Cửa hàng chính', 'active');

  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính', 'active');

  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  -- Set session JWT context for owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_user_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_user_id::text, true);

  insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
  values (v_product_id, v_tenant_id, 'Sản phẩm test', v_user_id, v_user_id, 'none', false);

  -- 1. Test case: ledger_update_blocked (sử dụng _next_ledger_sequence tránh đụng sequence)
  v_seq := inventory._next_ledger_sequence(v_tenant_id);
  insert into inventory.stock_movements (
    tenant_id, ledger_sequence, warehouse_id, product_id,
    intent_type, intent_id, movement_kind,
    quantity_delta, business_date, created_by
  ) values (
    v_tenant_id, v_seq, v_warehouse_id, v_product_id,
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
  v_seq := inventory._next_ledger_sequence(v_tenant_id);
  insert into inventory.value_movements (
    tenant_id, ledger_sequence, product_id, movement_id,
    kind, quantity_basis, unit_cost, amount_vnd,
    business_date, created_by
  ) values (
    v_tenant_id, v_seq, v_product_id, v_movement_id,
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
  v_seq := inventory._next_ledger_sequence(v_tenant_id);
  v_caught := false;
  begin
    insert into inventory.value_movements (
      tenant_id, ledger_sequence, product_id,
      kind, quantity_basis, amount_vnd,
      business_date, created_by
    ) values (
      v_tenant_id, v_seq, v_product_id,
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
  v_seq := inventory._next_ledger_sequence(v_tenant_id);
  v_caught := false;
  begin
    insert into inventory.value_movements (
      tenant_id, ledger_sequence, product_id,
      kind, quantity_basis, amount_vnd,
      business_date, created_by
    ) values (
      v_tenant_id, v_seq, v_product_id,
      'SUPPLIER_REBATE', 0, -2000,
      current_date, v_user_id
    );
  exception when check_violation then
    v_caught := true;
  end;
  if not v_caught then
    raise exception 'FAIL: rebate_row_requires_rebate_id';
  end if;

  -- 8. Test case (Task 3): non_owner_require_owner_denied
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);
  v_caught := false;
  begin
    perform inventory._assert_actor(v_tenant_id, 'inventory.read', p_require_owner => true);
  exception when others then
    if sqlerrm like '%Owner permission required%' or sqlerrm like '%PERMISSION_DENIED%' then
      v_caught := true;
    end if;
  end;
  if not v_caught then
    raise exception 'FAIL: non_owner_require_owner_denied';
  end if;
  -- Khôi phục quyền owner
  perform set_config('request.jwt.claim.sub', v_user_id::text, true);

  -- 9. Test case (Task 3): no_assignment_context_invalid
  declare
    v_no_assign_tenant uuid := gen_random_uuid();
  begin
    insert into iam.tenants (id, display_name)
    values (v_no_assign_tenant, 'Tenant No Assign');
    insert into iam.memberships (tenant_id, user_id, role, is_owner)
    values (v_no_assign_tenant, v_user_id, 'owner', true);

    v_caught := false;
    begin
      perform inventory._assert_actor(v_no_assign_tenant, 'inventory.read');
    exception when others then
      if sqlerrm like '%CONTEXT_INVALID%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: no_assignment_context_invalid';
    end if;
  end;

  -- 10. Test case (Task 3): replay_same_hash_returns_saved_result
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

  -- 11. Test case (Task 3): same_key_other_hash_conflict
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

  -- 12. Test case (Task 3): period_created_on_first_use & closed_period_raises
  declare
    v_period_id uuid;
  begin
    v_period_id := inventory._ensure_open_period(v_tenant_id, current_date);
    if v_period_id is null then
      raise exception 'FAIL: period_created_on_first_use';
    end if;

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

  -- -------------------------------------------------------------------------
  -- Task 4: Nobivac moving steps & periodic & rules
  -- -------------------------------------------------------------------------
  declare
    v_res jsonb;
    v_cost record;
    v_bal record;
    v_nobi_id uuid := gen_random_uuid();
    v_sale1_mov_id uuid;
    v_nobi_per_id uuid := gen_random_uuid();
    v_period_id uuid;
  begin
    insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
    values (v_nobi_id, v_tenant_id, 'Nobivac DHPPi Moving', v_user_id, v_user_id, 'none', false);

    -- 13. Nobivac Bước 1: Nhập 100 × 10.000 (MOVING)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 100,
        'movement_kind', 'RECEIPT',
        'unit_cost', 10000
      )),
      v_user_id
    );
    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;
    if v_cost.quantity_on_hand <> 100 or v_cost.ledger_value_vnd <> 1000000 or v_cost.moving_avg_cost <> 10000 then
      raise exception 'FAIL: nobivac step 1 cost: %', v_cost;
    end if;

    -- 14. Nobivac Bước 2: Bán 30 (SALE, -30) -> xuất 30 × 10.000 = -300.000
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', -30,
        'movement_kind', 'SALE'
      )),
      v_user_id
    );
    v_sale1_mov_id := (v_res -> 'movement_ids' ->> 0)::uuid;
    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;
    if v_cost.quantity_on_hand <> 70 or v_cost.ledger_value_vnd <> 700000 or v_cost.moving_avg_cost <> 10000 then
      raise exception 'FAIL: nobivac step 2 cost: %', v_cost;
    end if;

    -- 15. Nobivac Bước 3: Nhập 50 × 13.000 -> m = (700.000 + 650.000)/120 = 11.250
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 50,
        'movement_kind', 'RECEIPT',
        'unit_cost', 13000
      )),
      v_user_id
    );
    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;
    if v_cost.quantity_on_hand <> 120 or v_cost.ledger_value_vnd <> 1350000 or v_cost.moving_avg_cost <> 11250 then
      raise exception 'FAIL: nobivac step 3 cost: %', v_cost;
    end if;

    -- 16. Nobivac Bước 4: Bán 40 (SALE, -40) -> 40 × 11.250 = 450.000 -> tồn 80, giá trị 900.000
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', -40,
        'movement_kind', 'SALE'
      )),
      v_user_id
    );
    select quantity_on_hand, ledger_value_vnd, moving_avg_cost into v_cost
    from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;
    if v_cost.quantity_on_hand <> 80 or v_cost.ledger_value_vnd <> 900000 or v_cost.moving_avg_cost <> 11250 then
      raise exception 'FAIL: nobivac step 4 cost: %', v_cost;
    end if;

    -- 17. Test case: sale_reversal_exact (Huỷ bán 10 hộp từ dòng bán 30 gốc, đơn giá 10.000 dù m = 11.250)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE_REVERSAL', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 10,
        'movement_kind', 'SALE_REVERSAL',
        'source_movement_id', v_sale1_mov_id
      )),
      v_user_id
    );
    declare
      v_rev_val record;
    begin
      select unit_cost, amount_vnd into v_rev_val
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;
      if v_rev_val.unit_cost <> 10000 or v_rev_val.amount_vnd <> 100000 then
        raise exception 'FAIL: sale_reversal_exact value: %', v_rev_val;
      end if;
    end;

    -- 18. Test case: return_in_original_cost (Khách trả 5 hộp từ dòng bán 30 gốc, đơn giá 10.000)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RETURN_IN', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 5,
        'movement_kind', 'RETURN_IN',
        'source_movement_id', v_sale1_mov_id
      )),
      v_user_id
    );
    declare
      v_ret_val record;
    begin
      select unit_cost, amount_vnd into v_ret_val
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;
      if v_ret_val.unit_cost <> 10000 or v_ret_val.amount_vnd <> 50000 then
        raise exception 'FAIL: return_in_original_cost value: %', v_ret_val;
      end if;
    end;

    -- 18b. Test case (P2-2): return_in_source_wrong_kind_or_product_rejected
    declare
      v_rcpt_mov_id uuid;
      v_other_prod uuid := gen_random_uuid();
    begin
      -- Lấy 1 movement_id của loại RECEIPT
      select id into v_rcpt_mov_id
      from inventory.stock_movements
      where tenant_id = v_tenant_id and product_id = v_nobi_id and movement_kind = 'RECEIPT'
      limit 1;

      -- Trỏ nhầm vào dòng RECEIPT -> phải ném CONTEXT_INVALID
      v_caught := false;
      begin
        perform inventory._post_movements(
          v_tenant_id, v_warehouse_id, 'RETURN_IN', gen_random_uuid(), current_date,
          jsonb_build_array(jsonb_build_object(
            'product_id', v_nobi_id,
            'quantity_delta', 1,
            'movement_kind', 'RETURN_IN',
            'source_movement_id', v_rcpt_mov_id
          )),
          v_user_id
        );
      exception when others then
        if sqlerrm like '%CONTEXT_INVALID%' then
          v_caught := true;
        end if;
      end;
      if not v_caught then
        raise exception 'FAIL: return_in_source_wrong_kind_rejected';
      end if;

      -- Trỏ nhầm sang sản phẩm khác -> phải ném CONTEXT_INVALID
      insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
      values (v_other_prod, v_tenant_id, 'SP Khác Trỏ Nhầm', v_user_id, v_user_id, 'none', false);

      v_caught := false;
      begin
        perform inventory._post_movements(
          v_tenant_id, v_warehouse_id, 'RETURN_IN', gen_random_uuid(), current_date,
          jsonb_build_array(jsonb_build_object(
            'product_id', v_other_prod,
            'quantity_delta', 1,
            'movement_kind', 'RETURN_IN',
            'source_movement_id', v_sale1_mov_id
          )),
          v_user_id
        );
      exception when others then
        if sqlerrm like '%CONTEXT_INVALID%' then
          v_caught := true;
        end if;
      end;
      if not v_caught then
        raise exception 'FAIL: return_in_source_wrong_product_rejected';
      end if;
    end;

    -- 19. Test case: count_gain_uses_avg (Kiểm kê tăng 5 hộp dùng m)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'COUNT_GAIN', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 5,
        'movement_kind', 'COUNT_GAIN'
      )),
      v_user_id
    );
    declare
      v_gain_val record;
    begin
      select unit_cost, amount_vnd into v_gain_val
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;
      if v_gain_val.unit_cost is null or v_gain_val.amount_vnd is null or v_gain_val.amount_vnd <= 0 then
        raise exception 'FAIL: count_gain_uses_avg: %', v_gain_val;
      end if;
    end;

    -- 20. Test case: count_gain_empty_requires_cost (Kho trống kiểm kê tăng không có unit_cost -> UNIT_COST_REQUIRED)
    declare
      v_empty_prod uuid := gen_random_uuid();
    begin
      insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
      values (v_empty_prod, v_tenant_id, 'SP Trống Kiểm Kê', v_user_id, v_user_id, 'none', false);

      v_caught := false;
      begin
        perform inventory._post_movements(
          v_tenant_id, v_warehouse_id, 'COUNT_GAIN', gen_random_uuid(), current_date,
          jsonb_build_array(jsonb_build_object(
            'product_id', v_empty_prod,
            'quantity_delta', 5,
            'movement_kind', 'COUNT_GAIN'
          )),
          v_user_id
        );
      exception when others then
        if sqlerrm like '%UNIT_COST_REQUIRED%' then
          v_caught := true;
        end if;
      end;
      if not v_caught then
        raise exception 'FAIL: count_gain_empty_requires_cost';
      end if;
    end;

    -- 21. Test case: receipt_amount_passed_through (Nhập 50 hộp số tiền 618.000 -> ghi đúng 618.000)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', 50,
        'movement_kind', 'RECEIPT',
        'unit_cost', 12360,
        'amount_vnd', 618000
      )),
      v_user_id
    );
    declare
      v_rcpt_val record;
    begin
      select amount_vnd into v_rcpt_val
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;
      if v_rcpt_val.amount_vnd <> 618000 then
        raise exception 'FAIL: receipt_amount_passed_through amount: %', v_rcpt_val;
      end if;
    end;

    -- 22. Test case: period_closed_blocked (Kỳ đóng -> PERIOD_CLOSED, không dòng nào được ghi)
    select id into v_period_id
    from inventory.cost_periods
    where tenant_id = v_tenant_id and period_month = date_trunc('month', current_date)::date;

    update inventory.cost_periods set status = 'CLOSED' where id = v_period_id;

    declare
      v_before_sm_count int;
    begin
      select count(*) into v_before_sm_count from inventory.stock_movements where tenant_id = v_tenant_id;
      v_caught := false;
      begin
        perform inventory._post_movements(
          v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
          jsonb_build_array(jsonb_build_object(
            'product_id', v_nobi_id,
            'quantity_delta', 10,
            'movement_kind', 'RECEIPT',
            'unit_cost', 10000
          )),
          v_user_id
        );
      exception when others then
        if sqlerrm like '%PERIOD_CLOSED%' then
          v_caught := true;
        end if;
      end;
      if not v_caught then
        raise exception 'FAIL: period_closed_blocked exception';
      end if;
      if (select count(*) from inventory.stock_movements where tenant_id = v_tenant_id) <> v_before_sm_count then
        raise exception 'FAIL: period_closed_blocked wrote movements';
      end if;
    end;

    update inventory.cost_periods set status = 'OPEN' where id = v_period_id;

    -- 23. Test case: issue_more_than_stock_insufficient
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_nobi_id,
          'quantity_delta', -10000,
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
      raise exception 'FAIL: issue_more_than_stock_insufficient';
    end if;

    -- 24. Test case: insufficient_stock_rolls_back_all_lines (Dòng 2 thiếu -> cả lệnh rollback)
    declare
      v_sm_count_before int;
      v_vm_count_before int;
      v_cost_before record;
    begin
      select count(*) into v_sm_count_before from inventory.stock_movements where tenant_id = v_tenant_id;
      select count(*) into v_vm_count_before from inventory.value_movements where tenant_id = v_tenant_id;
      select * into v_cost_before from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;

      v_caught := false;
      begin
        perform inventory._post_movements(
          v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
          jsonb_build_array(
            jsonb_build_object(
              'product_id', v_nobi_id,
              'quantity_delta', -5,
              'movement_kind', 'SALE'
            ),
            jsonb_build_object(
              'product_id', v_nobi_id,
              'quantity_delta', -99999,
              'movement_kind', 'SALE'
            )
          ),
          v_user_id
        );
      exception when others then
        if sqlerrm like '%INSUFFICIENT_STOCK%' then
          v_caught := true;
        end if;
      end;
      if not v_caught then
        raise exception 'FAIL: insufficient_stock_rolls_back_all_lines exception';
      end if;

      if (select count(*) from inventory.stock_movements where tenant_id = v_tenant_id) <> v_sm_count_before
         or (select count(*) from inventory.value_movements where tenant_id = v_tenant_id) <> v_vm_count_before then
        raise exception 'FAIL: insufficient_stock_rolls_back_all_lines did not rollback ledger';
      end if;

      declare
        v_cost_after record;
      begin
        select * into v_cost_after from inventory.product_costs where tenant_id = v_tenant_id and product_id = v_nobi_id;
        if v_cost_after.quantity_on_hand <> v_cost_before.quantity_on_hand
           or v_cost_after.ledger_value_vnd <> v_cost_before.ledger_value_vnd
           or v_cost_after.moving_avg_cost <> v_cost_before.moving_avg_cost then
          raise exception 'FAIL: insufficient_stock_rolls_back_all_lines did not rollback product_costs: before %, after %',
            v_cost_before, v_cost_after;
        end if;
      end;
    end;

    -- 25. Test case: nobivac_periodic_provisional (Chuyển sang PERIODIC, bán ghi nhận provisional)
    insert into inventory.cost_policies (tenant_id, method, changed_by)
    values (v_tenant_id, 'PERIODIC', v_user_id)
    on conflict (tenant_id) do update set method = 'PERIODIC';

    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_nobi_id,
        'quantity_delta', -10,
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
        raise exception 'FAIL: nobivac_periodic_provisional';
      end if;
    end;

    -- 26. Test case: periodic_uses_official_version (Có bản chính thức -> dùng giá chính thức, không provisional)
    declare
      v_ver_id uuid := gen_random_uuid();
      v_val_row record;
    begin
      insert into inventory.cost_versions (
        id, tenant_id, product_id, unit_cost,
        method, effective_from_sequence
      ) values (
        v_ver_id, v_tenant_id, v_nobi_id, 10500,
        'PERIODIC', inventory._next_ledger_sequence(v_tenant_id)
      );

      update inventory.product_costs
      set official_unit_cost = 10500,
          official_version_id = v_ver_id
      where tenant_id = v_tenant_id and product_id = v_nobi_id;

      v_res := inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_nobi_id,
          'quantity_delta', -10,
          'movement_kind', 'SALE'
        )),
        v_user_id
      );

      select unit_cost, amount_vnd, is_provisional, cost_version_id into v_val_row
      from inventory.value_movements
      where id = (v_res -> 'lines' -> 0 ->> 'value_movement_id')::uuid;

      if v_val_row.unit_cost <> 10500 or v_val_row.amount_vnd <> -105000
         or v_val_row.is_provisional is not false or v_val_row.cost_version_id <> v_ver_id then
        raise exception 'FAIL: periodic_uses_official_version: %', v_val_row;
      end if;
    end;
  end;

  -- -------------------------------------------------------------------------
  -- Task 4: Lot & Expiry rules
  -- -------------------------------------------------------------------------
  declare
    v_prod_lot uuid := gen_random_uuid();
    v_prod_exp uuid := gen_random_uuid();
    v_res jsonb;
    v_lot_id1 uuid;
  begin
    insert into catalog.products (id, tenant_id, name, created_by, updated_by, tracking_mode, expiry_required)
    values (v_prod_lot, v_tenant_id, 'Hàng theo lô test', v_user_id, v_user_id, 'lot', false);

    -- 27. post_movements_lot_required (Sản phẩm lot nhưng không truyền lô)
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

    -- 28. post_movements_lot_not_allowed (Sản phẩm none nhưng truyền mã lô)
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

    -- 29. post_movements_expiry_required (Sản phẩm expiry_required nhưng thiếu hạn dùng)
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

    -- 30. post_movements_unit_cost_required
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

    -- 31. lot_created_once (Nhập lần 1 -> tạo lô LOT-A)
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_prod_lot,
        'lot_code', 'LOT-A',
        'expiry_date', '2027-01-01',
        'quantity_delta', 10,
        'movement_kind', 'RECEIPT',
        'unit_cost', 25000
      )),
      v_user_id
    );
    select id into v_lot_id1 from inventory.lots where tenant_id = v_tenant_id and product_id = v_prod_lot and lot_code = 'LOT-A';
    if v_lot_id1 is null then
      raise exception 'FAIL: lot_created_once lot missing';
    end if;

    -- Nhập lần 2 cùng mã LOT-A và cùng hạn dùng -> vẫn chỉ 1 bản ghi lots
    v_res := inventory._post_movements(
      v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
      jsonb_build_array(jsonb_build_object(
        'product_id', v_prod_lot,
        'lot_code', 'LOT-A',
        'expiry_date', '2027-01-01',
        'quantity_delta', 5,
        'movement_kind', 'RECEIPT',
        'unit_cost', 25000
      )),
      v_user_id
    );
    if (select count(*) from inventory.lots where tenant_id = v_tenant_id and product_id = v_prod_lot and lot_code = 'LOT-A') <> 1 then
      raise exception 'FAIL: lot_created_once duplicate lot row';
    end if;

    -- 32. lot_same_code_other_expiry_conflict (Nhập cùng mã LOT-A nhưng khác ngày hết hạn -> LOT_ATTRIBUTE_CONFLICT)
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_lot,
          'lot_code', 'LOT-A',
          'expiry_date', '2027-06-01',
          'quantity_delta', 5,
          'movement_kind', 'RECEIPT',
          'unit_cost', 25000
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%LOT_ATTRIBUTE_CONFLICT%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: lot_same_code_other_expiry_conflict';
    end if;

    -- 33. issue_unknown_lot_rejected (Xuất lô chưa tồn tại -> LOT_REQUIRED)
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_lot,
          'lot_code', 'LOT-UNKNOWN',
          'quantity_delta', -1,
          'movement_kind', 'SALE'
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%LOT_REQUIRED%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: issue_unknown_lot_rejected';
    end if;

    -- 34. kind_sign_mismatch_rejected (SALE nhưng dương, hoặc RECEIPT nhưng âm)
    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'SALE', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_lot,
          'lot_code', 'LOT-A',
          'quantity_delta', 5,
          'movement_kind', 'SALE'
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%CONTEXT_INVALID%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: kind_sign_mismatch_rejected (sale positive)';
    end if;

    v_caught := false;
    begin
      perform inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(jsonb_build_object(
          'product_id', v_prod_lot,
          'lot_code', 'LOT-A',
          'expiry_date', '2027-01-01',
          'quantity_delta', -5,
          'movement_kind', 'RECEIPT',
          'unit_cost', 25000
        )),
        v_user_id
      );
    exception when others then
      if sqlerrm like '%CONTEXT_INVALID%' then
        v_caught := true;
      end if;
    end;
    if not v_caught then
      raise exception 'FAIL: kind_sign_mismatch_rejected (receipt negative)';
    end if;

    -- 34b. Test case (P2-5): stock_changes_consolidated_per_product
    -- Lệnh 2 dòng cùng 1 sản phẩm v_prod_lot (2 lô khác nhau) -> stock_changes chỉ có đúng 1 phần tử
    declare
      v_res_multi jsonb;
      v_sc jsonb;
    begin
      v_res_multi := inventory._post_movements(
        v_tenant_id, v_warehouse_id, 'RECEIPT', gen_random_uuid(), current_date,
        jsonb_build_array(
          jsonb_build_object(
            'product_id', v_prod_lot,
            'lot_code', 'LOT-P2-1',
            'expiry_date', '2027-08-01',
            'quantity_delta', 10,
            'movement_kind', 'RECEIPT',
            'unit_cost', 20000
          ),
          jsonb_build_object(
            'product_id', v_prod_lot,
            'lot_code', 'LOT-P2-2',
            'expiry_date', '2027-09-01',
            'quantity_delta', 20,
            'movement_kind', 'RECEIPT',
            'unit_cost', 20000
          )
        ),
        v_user_id
      );

      v_sc := v_res_multi -> 'stock_changes';
      if jsonb_array_length(v_sc) <> 1 then
        raise exception 'FAIL: stock_changes_consolidated_per_product length %', jsonb_array_length(v_sc);
      end if;
      if (v_sc -> 0 ->> 'product_id')::uuid <> v_prod_lot then
        raise exception 'FAIL: stock_changes_consolidated_per_product prod_id mismatch';
      end if;
    end;
  end;

  -- -------------------------------------------------------------------------
  -- Task 5: Hub summary (P1-3 ca 20-21 đã sửa store, warehouse, user membership)
  -- -------------------------------------------------------------------------
  declare
    v_empty_tenant uuid := gen_random_uuid();
    v_empty_wh uuid := gen_random_uuid();
    v_empty_store uuid := gen_random_uuid();
    v_summary jsonb;
  begin
    -- 35. Hub summary: kho trống chưa có biến động -> {activated: false, problems: null}
    insert into iam.tenants (id, display_name)
    values (v_empty_tenant, 'Empty Tenant');

    insert into iam.memberships (tenant_id, user_id, role, is_owner)
    values (v_empty_tenant, v_user_id, 'owner', true);

    insert into iam.stores (id, tenant_id, code, display_name, status)
    values (v_empty_store, v_empty_tenant, 'STORE_EMPTY', 'Cửa hàng trống', 'active');

    insert into inventory.warehouses (id, tenant_id, display_name, status)
    values (v_empty_wh, v_empty_tenant, 'Kho trống', 'active');

    insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
    values (v_empty_tenant, v_empty_store, v_empty_wh, 'active');

    v_summary := inventory.get_warehouse_hub_summary(v_empty_tenant);
    if (v_summary ->> 'activated')::boolean is not false or (v_summary ->> 'problems') is not null then
      raise exception 'FAIL: hub_summary_not_activated_when_no_movement: %', v_summary;
    end if;

    -- 36. Hub summary: kho đã có biến động -> {activated: true, problems: null}
    v_summary := inventory.get_warehouse_hub_summary(v_tenant_id);
    if (v_summary ->> 'activated')::boolean is not true then
      raise exception 'FAIL: hub_summary_activated_after_movement: %', v_summary;
    end if;
  end;

  -- -------------------------------------------------------------------------
  -- Bất biến sổ giá trị: ledger_value_invariant
  -- -------------------------------------------------------------------------
  -- 37. Kiểm tra mọi sản phẩm:
  --   quantity_on_hand = sum(stock_movements.quantity_delta)
  --   ledger_value_vnd = sum(value_movements.amount_vnd)
  declare
    v_r record;
    v_calc_qty numeric;
    v_calc_val bigint;
  begin
    for v_r in
      select tenant_id, product_id, quantity_on_hand, ledger_value_vnd
      from inventory.product_costs
      where tenant_id = v_tenant_id
    loop
      select coalesce(sum(quantity_delta), 0) into v_calc_qty
      from inventory.stock_movements
      where tenant_id = v_r.tenant_id and product_id = v_r.product_id;

      select coalesce(sum(amount_vnd), 0) into v_calc_val
      from inventory.value_movements
      where tenant_id = v_r.tenant_id and product_id = v_r.product_id;

      if v_r.quantity_on_hand <> v_calc_qty then
        raise exception 'FAIL: ledger_value_invariant quantity mismatch prod %: cost %, sm %',
          v_r.product_id, v_r.quantity_on_hand, v_calc_qty;
      end if;

      if v_r.ledger_value_vnd <> v_calc_val then
        raise exception 'FAIL: ledger_value_invariant value mismatch prod %: cost %, vm %',
          v_r.product_id, v_r.ledger_value_vnd, v_calc_val;
      end if;
    end loop;
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
