-- Test suite for inventory_sales_link
-- Plan: T7-G5-4 Task 1 & Task 2

begin;

-- Invariants check helper
create or replace function public._assert_inventory_invariants(p_tenant uuid, p_product uuid, p_case text)
returns void
language plpgsql
as $$
declare
  v_cost_ledger bigint;
  v_vm_sum bigint;
  v_sb_sum numeric;
  v_sm_sum numeric;
begin
  select coalesce(ledger_value_vnd, 0) into v_cost_ledger
  from inventory.product_costs where tenant_id = p_tenant and product_id = p_product;

  select coalesce(sum(amount_vnd), 0) into v_vm_sum
  from inventory.value_movements where tenant_id = p_tenant and product_id = p_product;

  if v_cost_ledger is distinct from v_vm_sum then
    raise exception 'FAIL [%]: cost invariant violated for product %: product_costs=% vs value_movements=%',
      p_case, p_product, v_cost_ledger, v_vm_sum;
  end if;

  select coalesce(sum(physical_quantity), 0) into v_sb_sum
  from inventory.stock_balances where tenant_id = p_tenant and product_id = p_product;

  select coalesce(sum(quantity_delta), 0) into v_sm_sum
  from inventory.stock_movements where tenant_id = p_tenant and product_id = p_product;

  if v_sb_sum is distinct from v_sm_sum then
    raise exception 'FAIL [%]: stock invariant violated for product %: stock_balances=% vs stock_movements=%',
      p_case, p_product, v_sb_sum, v_sm_sum;
  end if;
end;
$$;

do $$
declare
  v_owner_id uuid := gen_random_uuid();
  v_tenant_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();
  v_today date := inventory._today();

  v_p_lot1 uuid := gen_random_uuid();
  v_p_lot_month uuid := gen_random_uuid();
  v_p_nonlot uuid := gen_random_uuid();
  v_p_groups uuid := gen_random_uuid();
  v_p_expired uuid := gen_random_uuid();
  v_p_retin uuid := gen_random_uuid();

  v_u_lot1_base uuid := gen_random_uuid();
  v_u_month_base uuid := gen_random_uuid();
  v_u_nonlot_base uuid := gen_random_uuid();
  v_u_groups_base uuid := gen_random_uuid();
  v_u_groups_conv uuid := gen_random_uuid();
  v_u_expired_base uuid := gen_random_uuid();
  v_u_retin_base uuid := gen_random_uuid();

  v_lot_x uuid;
  v_lot_a uuid;
  v_lot_b uuid;
  v_res jsonb;
  v_line1_id uuid := gen_random_uuid();
  v_ret1_id uuid := gen_random_uuid();
  v_ret2_id uuid := gen_random_uuid();
  v_ret3_id uuid := gen_random_uuid();

  v_phy numeric;
  v_sale_seq bigint;
  v_c_rows int;
begin
  -- 1. Setup Auth, Tenant, Warehouse, Store
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-sales-link-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Sales Link Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_tenant_id, v_owner_id, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'ST01', 'Cửa hàng chính SL', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính SL', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by)
  values (v_tenant_id, 'MOVING', v_owner_id)
  on conflict (tenant_id) do nothing;

  -- 2. Setup Products & Units
  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, reference_id, created_by, updated_by)
  values
    (v_p_lot1, v_tenant_id, 'SP Lô 1 FEFO', 'SKU-LOT1', 'lot', true, 'active', 'REF-LOT1', v_owner_id, v_owner_id),
    (v_p_lot_month, v_tenant_id, 'SP Lô Month', 'SKU-MONTH', 'lot', true, 'active', 'REF-MONTH', v_owner_id, v_owner_id),
    (v_p_nonlot, v_tenant_id, 'SP Không Lô', 'SKU-NONLOT', 'none', false, 'active', 'REF-NONLOT', v_owner_id, v_owner_id),
    (v_p_groups, v_tenant_id, 'SP Hai DVT', 'SKU-GROUPS', 'none', false, 'active', 'REF-GROUPS', v_owner_id, v_owner_id),
    (v_p_expired, v_tenant_id, 'SP Het Han', 'SKU-EXPIRED', 'lot', true, 'active', 'REF-EXPIRED', v_owner_id, v_owner_id),
    (v_p_retin, v_tenant_id, 'SP Return In', 'SKU-RETIN', 'none', false, 'active', 'REF-RETIN', v_owner_id, v_owner_id);

  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_u_lot1_base, v_tenant_id, v_p_lot1, 'hộp', 1, true),
    (v_u_month_base, v_tenant_id, v_p_lot_month, 'hộp', 1, true),
    (v_u_nonlot_base, v_tenant_id, v_p_nonlot, 'hộp', 1, true),
    (v_u_groups_base, v_tenant_id, v_p_groups, 'viên', 1, true),
    (v_u_groups_conv, v_tenant_id, v_p_groups, 'hộp', 10, false),
    (v_u_expired_base, v_tenant_id, v_p_expired, 'hộp', 1, true),
    (v_u_retin_base, v_tenant_id, v_p_retin, 'hộp', 1, true);

  -- -------------------------------------------------------------------------
  -- Ca 1: fefo_order
  -- -------------------------------------------------------------------------
  -- Lô X: hết hạn hôm qua (5 hộp)
  -- Lô A: hạn +10 ngày (5 hộp)
  -- Lô B: hạn +40 ngày (5 hộp)
  -- Giá nhập 10.000
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_lot1, 'lot_code', 'LX', 'expiry_date', v_today - 1, 'expiry_precision', 'DAY', 'quantity_delta', 5, 'unit_cost', 10000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', v_p_lot1, 'lot_code', 'LA', 'expiry_date', v_today + 10, 'expiry_precision', 'DAY', 'quantity_delta', 5, 'unit_cost', 10000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', v_p_lot1, 'lot_code', 'LB', 'expiry_date', v_today + 40, 'expiry_precision', 'DAY', 'quantity_delta', 5, 'unit_cost', 10000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  select id into v_lot_x from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_lot1 and lot_code = 'LX';
  select id into v_lot_a from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_lot1 and lot_code = 'LA';
  select id into v_lot_b from inventory.lots where tenant_id = v_tenant_id and product_id = v_p_lot1 and lot_code = 'LB';

  -- Xuất 8 hộp: FEFO lấy A: 5, B: 3; X không đổi
  v_res := inventory._issue_for_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', v_line1_id, 'product_id', v_p_lot1, 'base_qty', 8, 'unit_name', 'hộp', 'conversion_rate', 1)
    ),
    v_owner_id
  );

  if jsonb_array_length(v_res->'lines') <> 1 then
    raise exception 'FAIL: fefo_order expected 1 line in result, got %', v_res;
  end if;

  if (v_res->'lines'->0->>'cogs_amount_vnd')::bigint <> 80000
     or (v_res->'lines'->0->>'cogs_unit_cost')::numeric <> 10000
     or (v_res->'lines'->0->>'is_provisional')::boolean <> false then
    raise exception 'FAIL: fefo_order result lines mismatch: %', v_res;
  end if;

  -- Kiểm tra tồn từng lô: X = 5, A = 0, B = 2
  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_x;
  if v_phy <> 5 then raise exception 'FAIL: fefo_order lot X expected 5, got %', v_phy; end if;

  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_a;
  if v_phy <> 0 then raise exception 'FAIL: fefo_order lot A expected 0, got %', v_phy; end if;

  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_b;
  if v_phy <> 2 then raise exception 'FAIL: fefo_order lot B expected 2, got %', v_phy; end if;

  perform public._assert_inventory_invariants(v_tenant_id, v_p_lot1, 'fefo_order');

  -- -------------------------------------------------------------------------
  -- Ca 2: fefo_month_precision
  -- -------------------------------------------------------------------------
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_lot_month, 'lot_code', 'LM1', 'expiry_date', v_today, 'expiry_precision', 'MONTH', 'quantity_delta', 5, 'unit_cost', 12000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  v_res := inventory._issue_for_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_lot_month, 'base_qty', 3, 'unit_name', 'hộp', 'conversion_rate', 1)
    ),
    v_owner_id
  );
  if (v_res->'lines'->0->>'cogs_amount_vnd')::bigint <> 36000 then
    raise exception 'FAIL: fefo_month_precision failed: %', v_res;
  end if;
  perform public._assert_inventory_invariants(v_tenant_id, v_p_lot_month, 'fefo_month_precision');

  -- -------------------------------------------------------------------------
  -- Ca 3: issue_non_lot
  -- -------------------------------------------------------------------------
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_nonlot, 'quantity_delta', 10, 'unit_cost', 15000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  v_res := inventory._issue_for_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_nonlot, 'base_qty', 4, 'unit_name', 'hộp', 'conversion_rate', 1)
    ),
    v_owner_id
  );
  if (v_res->'lines'->0->>'cogs_amount_vnd')::bigint <> 60000 then
    raise exception 'FAIL: issue_non_lot failed: %', v_res;
  end if;
  perform public._assert_inventory_invariants(v_tenant_id, v_p_nonlot, 'issue_non_lot');

  -- -------------------------------------------------------------------------
  -- Ca 4: issue_groups_lines_by_product
  -- -------------------------------------------------------------------------
  -- Khả dụng 12 viên (nhập 12 viên giá 2000)
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_groups, 'quantity_delta', 12, 'unit_cost', 2000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  -- Hai dòng: dòng 1: 1 hộp (rate 10, base 10), dòng 2: 5 viên (rate 1, base 5) -> tổng 15 > 12 => INSUFFICIENT_STOCK
  begin
    perform inventory._issue_for_sale(
      v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
      jsonb_build_array(
        jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_groups, 'base_qty', 10, 'unit_name', 'hộp', 'conversion_rate', 10),
        jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_groups, 'base_qty', 5, 'unit_name', 'viên', 'conversion_rate', 1)
      ),
      v_owner_id
    );
    raise exception 'FAIL: issue_groups_lines_by_product should raise INSUFFICIENT_STOCK';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%INSUFFICIENT_STOCK%' or sqlerrm not like '%chỉ còn 1 hộp bán được.%' then
      raise exception 'FAIL: issue_groups_lines_by_product unexpected error [%]', sqlerrm;
    end if;
  end;

  -- Nhập thêm 3 viên (tổng 15), gọi lại thành công
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_groups, 'quantity_delta', 3, 'unit_cost', 2000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  v_res := inventory._issue_for_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_groups, 'base_qty', 10, 'unit_name', 'hộp', 'conversion_rate', 10),
      jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_groups, 'base_qty', 5, 'unit_name', 'viên', 'conversion_rate', 1)
    ),
    v_owner_id
  );
  if jsonb_array_length(v_res->'lines') <> 2 then
    raise exception 'FAIL: issue_groups_lines_by_product expected 2 lines, got %', v_res;
  end if;
  perform public._assert_inventory_invariants(v_tenant_id, v_p_groups, 'issue_groups_lines_by_product');

  -- -------------------------------------------------------------------------
  -- Ca 5: insufficient_excludes_expired
  -- -------------------------------------------------------------------------
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_expired, 'lot_code', 'LEXP', 'expiry_date', v_today - 5, 'expiry_precision', 'DAY', 'quantity_delta', 10, 'unit_cost', 5000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  begin
    perform inventory._issue_for_sale(
      v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
      jsonb_build_array(
        jsonb_build_object('line_id', gen_random_uuid(), 'product_id', v_p_expired, 'base_qty', 1, 'unit_name', 'hộp', 'conversion_rate', 1)
      ),
      v_owner_id
    );
    raise exception 'FAIL: insufficient_excludes_expired should raise INSUFFICIENT_STOCK';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%INSUFFICIENT_STOCK%' then
      raise exception 'FAIL: insufficient_excludes_expired unexpected error [%]', sqlerrm;
    end if;
  end;
  perform public._assert_inventory_invariants(v_tenant_id, v_p_expired, 'insufficient_excludes_expired');

  -- -------------------------------------------------------------------------
  -- Ca 6: reverse_latest_expiry_first + reverse_exceeds_remaining
  -- -------------------------------------------------------------------------
  -- Dùng lại dòng bán v_line1_id của v_p_lot1 (đã xuất 8: A 5, B 3)
  -- Trả 4: B (+40 ngày) trả 3, A (+10 ngày) trả 1
  v_res := inventory._reverse_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', v_ret1_id, 'source_intent_type', 'TEST', 'source_intent_line_id', v_line1_id, 'base_qty', 4)
    ),
    v_owner_id
  );
  if (v_res->'lines'->0->>'amount_vnd')::bigint <> 40000 then
    raise exception 'FAIL: reverse_sale 1 amount mismatch: %', v_res;
  end if;

  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_b;
  if v_phy <> 5 then raise exception 'FAIL: reverse_sale 1 lot B expected 5, got %', v_phy; end if;

  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_a;
  if v_phy <> 1 then raise exception 'FAIL: reverse_sale 1 lot A expected 1, got %', v_phy; end if;

  -- Trả tiếp 4: A trả nốt 4 (tổng A = 5)
  v_res := inventory._reverse_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', v_ret2_id, 'source_intent_type', 'TEST', 'source_intent_line_id', v_line1_id, 'base_qty', 4)
    ),
    v_owner_id
  );
  select physical_quantity into v_phy from inventory.stock_balances where tenant_id = v_tenant_id and lot_key = v_lot_a;
  if v_phy <> 5 then raise exception 'FAIL: reverse_sale 2 lot A expected 5, got %', v_phy; end if;

  -- Trả thêm 1: vượt số lượng còn lại -> CONTEXT_INVALID
  begin
    perform inventory._reverse_sale(
      v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
      jsonb_build_array(
        jsonb_build_object('line_id', v_ret3_id, 'source_intent_type', 'TEST', 'source_intent_line_id', v_line1_id, 'base_qty', 1)
      ),
      v_owner_id
    );
    raise exception 'FAIL: reverse_exceeds_remaining should raise CONTEXT_INVALID';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%CONTEXT_INVALID%' then
      raise exception 'FAIL: reverse_exceeds_remaining unexpected error [%]', sqlerrm;
    end if;
  end;

  perform public._assert_inventory_invariants(v_tenant_id, v_p_lot1, 'reverse_sale_lot1');

  -- -------------------------------------------------------------------------
  -- Ca 7: reverse_without_sale
  -- -------------------------------------------------------------------------
  begin
    perform inventory._reverse_sale(
      v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
      jsonb_build_array(
        jsonb_build_object('line_id', gen_random_uuid(), 'source_intent_type', 'TEST', 'source_intent_line_id', gen_random_uuid(), 'base_qty', 1)
      ),
      v_owner_id
    );
    raise exception 'FAIL: reverse_without_sale should raise CONTEXT_INVALID';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%CONTEXT_INVALID%' then
      raise exception 'FAIL: reverse_without_sale unexpected error [%]', sqlerrm;
    end if;
  end;

  -- -------------------------------------------------------------------------
  -- Ca 8: reversal_kind_return_in
  -- -------------------------------------------------------------------------
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_p_retin, 'quantity_delta', 10, 'unit_cost', 5000, 'movement_kind', 'RECEIPT')
    ),
    v_owner_id
  );

  v_line1_id := gen_random_uuid();
  v_res := inventory._issue_for_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', v_line1_id, 'product_id', v_p_retin, 'base_qty', 5, 'unit_name', 'hộp', 'conversion_rate', 1)
    ),
    v_owner_id
  );

  select ledger_sequence into v_sale_seq
  from inventory.stock_movements
  where tenant_id = v_tenant_id and intent_line_id = v_line1_id and movement_kind = 'SALE';

  -- Chèn cost_version sau sequence bán
  insert into inventory.cost_versions (
    tenant_id, product_id, method, effective_from_sequence,
    unit_cost
  ) values (
    v_tenant_id, v_p_retin, 'MOVING', v_sale_seq + 1,
    7000
  );

  -- Đảo bán: _reversal_kind phải ra RETURN_IN
  v_res := inventory._reverse_sale(
    v_tenant_id, v_store_id, 'TEST', gen_random_uuid(),
    jsonb_build_array(
      jsonb_build_object('line_id', gen_random_uuid(), 'source_intent_type', 'TEST', 'source_intent_line_id', v_line1_id, 'base_qty', 2)
    ),
    v_owner_id
  );

  if not exists (
    select 1 from inventory.value_movements
    where tenant_id = v_tenant_id and product_id = v_p_retin and kind = 'RETURN_IN' and unit_cost = 5000
  ) then
    raise exception 'FAIL: reversal_kind_return_in expected RETURN_IN with unit_cost 5000';
  end if;

  perform public._assert_inventory_invariants(v_tenant_id, v_p_retin, 'reversal_kind_return_in');

  -- -------------------------------------------------------------------------
  -- Ca 9: stock_rows_filter
  -- -------------------------------------------------------------------------
  select count(*) into v_c_rows
  from inventory._product_stock_rows(v_tenant_id, array[v_p_lot1]);
  if v_c_rows <> 1 then
    raise exception 'FAIL: stock_rows_filter array[v_p_lot1] expected 1 row, got %', v_c_rows;
  end if;

  select count(*) into v_c_rows
  from inventory._product_stock_rows(v_tenant_id);
  if v_c_rows < 6 then
    raise exception 'FAIL: stock_rows_filter default null expected >= 6 rows, got %', v_c_rows;
  end if;

  raise notice 'inventory_sales_link Task 1: OK';
end;
$$;

rollback;

