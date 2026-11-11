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

-- ===========================================================================
-- Task 2: Sales link tests (S1 - S8)
-- ===========================================================================

create or replace function public._isl_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create or replace function public._isl_pay(p_amount bigint)
returns jsonb
language sql
as $$
  select jsonb_build_array(jsonb_build_object(
    'method', 'cash',
    'amount', jsonb_build_object('amount_minor', p_amount, 'currency_code', 'VND')
  ));
$$;

create or replace function public._isl_finalize(
  p_tenant uuid, p_actor uuid, p_store uuid, p_customer uuid,
  p_lines jsonb, p_payments jsonb, p_due date, p_key text
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
    'unit', jsonb_build_object('productUnitId', l.value ->> 'product_unit_id', 'unitName', 'DV'),
    'quantityMicros', (l.value ->> 'quantity_micros')::bigint,
    'lineTotal', jsonb_build_object(
      'amountMinor',
      (l.value -> 'unit_price' ->> 'amount_minor')::bigint
        * (l.value ->> 'quantity_micros')::bigint / 1000000
    )
  ) order by l.ordinality)
  into v_snap_lines
  from jsonb_array_elements(p_lines) with ordinality as l(value, ordinality);

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

create or replace function public._isl_cancel(p_tenant uuid, p_actor uuid, p_order uuid, p_key text)
returns jsonb
language plpgsql
as $$
declare
  v_ov int;
  v_sv int;
begin
  select version into v_ov from sales.sales_orders where tenant_id = p_tenant and id = p_order;
  select version into v_sv from sales.sales_order_settlements
    where tenant_id = p_tenant and sales_order_id = p_order
    order by version desc limit 1;
  return sales.confirm_sales_order_cancellation(
    command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    sales_order_id => p_order, reason_text => 'ISL test huy',
    idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text,
    expected_order_version => v_ov, expected_settlement_version => v_sv);
end;
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_cust uuid;
  v_today date := inventory._today();

  v_pa uuid := gen_random_uuid();
  v_pb uuid := gen_random_uuid();
  v_pc uuid := gen_random_uuid();
  v_pd uuid := gen_random_uuid();

  v_ua uuid := gen_random_uuid();
  v_ub uuid := gen_random_uuid();
  v_uc uuid := gen_random_uuid();
  v_ud uuid := gen_random_uuid();

  v_lot1 uuid;
  v_lot2 uuid;

  v_res jsonb;
  v_order_id uuid;
  v_sol record;
  v_bal numeric;
  v_bal1 numeric;
  v_bal2 numeric;

  v_pre jsonb;
  v_rx jsonb;
  v_rx_id uuid;
  v_rx_ver int;
  v_sol_id uuid;
  v_ex_line_id uuid;
  v_rx_line record;
begin
  -- 1. Setup tenant & permissions
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-t2-' || substr(v_owner::text, 1, 8) || '@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  insert into iam.tenants (id, display_name) values (v_t, 'Sales Link Tenant T2');
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (v_t, v_owner, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status) values (v_store, v_t, 'ST-T2', 'Cửa hàng T2', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status) values (v_wh, v_t, 'Kho T2', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_t, v_store, v_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by) values (v_t, 'MOVING', v_owner);

  -- Customer
  select c.partner_id into v_cust
  from partner.create_partner(v_t, v_owner, 'person', array['customer'], jsonb_build_object('full_name', 'Khách nợ S2', 'phone', '0988000002')) c;

  -- Products: PA (lot), PB (non-lot), PC (exchange target), PD (out of stock)
  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values
    (v_pa, v_t, 'SP_A Lô', 'SKU-PA', 'lot', true, 'active', true, 'REF-PA', v_owner, v_owner),
    (v_pb, v_t, 'SP_B Ko Lô', 'SKU-PB', 'none', false, 'active', true, 'REF-PB', v_owner, v_owner),
    (v_pc, v_t, 'SP_C Đổi', 'SKU-PC', 'none', false, 'active', true, 'REF-PC', v_owner, v_owner),
    (v_pd, v_t, 'SP_D Hết Hàng', 'SKU-PD', 'none', false, 'active', true, 'REF-PD', v_owner, v_owner);

  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_ua, v_t, v_pa, 'hộp', 1, true),
    (v_ub, v_t, v_pb, 'hộp', 1, true),
    (v_uc, v_t, v_pc, 'hộp', 1, true),
    (v_ud, v_t, v_pd, 'hộp', 1, true);

  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_pa, p_product_unit_id => v_ua, p_source_type => 'manual', p_list_price_before_vat => 50000, p_list_price_after_vat => 50000, p_floor_price_before_vat => 20000, p_floor_price_after_vat => 20000);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_pb, p_product_unit_id => v_ub, p_source_type => 'manual', p_list_price_before_vat => 60000, p_list_price_after_vat => 60000, p_floor_price_before_vat => 30000, p_floor_price_after_vat => 30000);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_pc, p_product_unit_id => v_uc, p_source_type => 'manual', p_list_price_before_vat => 50000, p_list_price_after_vat => 50000, p_floor_price_before_vat => 20000, p_floor_price_after_vat => 20000);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_pd, p_product_unit_id => v_ud, p_source_type => 'manual', p_list_price_before_vat => 30000, p_list_price_after_vat => 30000, p_floor_price_before_vat => 10000, p_floor_price_after_vat => 10000);

  -- Initial stocks
  -- PA: Lô 1 (5 hộp, hạn +10 ngày, giá vốn 10.000), Lô 2 (5 hộp, hạn +20 ngày, giá vốn 12.000)
  perform inventory._post_movements(
    v_t, v_wh, 'SETUP', gen_random_uuid(), v_today,
    jsonb_build_array(
      jsonb_build_object('product_id', v_pa, 'lot_code', 'PA-L1', 'expiry_date', v_today + 10, 'quantity_delta', 5, 'unit_cost', 10000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', v_pa, 'lot_code', 'PA-L2', 'expiry_date', v_today + 20, 'quantity_delta', 5, 'unit_cost', 12000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', v_pb, 'quantity_delta', 10, 'unit_cost', 20000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', v_pc, 'quantity_delta', 5, 'unit_cost', 15000, 'movement_kind', 'RECEIPT')
    ),
    v_owner
  );

  update catalog.products set is_ready_to_sell = true where tenant_id = v_t;

  select id into v_lot1 from inventory.lots where tenant_id = v_t and product_id = v_pa and lot_code = 'PA-L1';
  select id into v_lot2 from inventory.lots where tenant_id = v_t and product_id = v_pa and lot_code = 'PA-L2';

  -- -------------------------------------------------------------------------
  -- S1: Normal Sale + COGS snapshot
  -- -------------------------------------------------------------------------
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 2000000, 50000)),
    public._isl_pay(100000), null, 's1-key');

  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL [S1]: finalize failed: %', v_res;
  end if;

  v_order_id := (v_res ->> 'salesOrderId')::uuid;
  select * into v_sol from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_order_id;

  if v_sol.cogs_amount_vnd <> 22000 or v_sol.cogs_unit_cost <> 11000 or v_sol.cogs_is_provisional is not false then
    raise exception 'FAIL [S1]: cogs snapshot incorrect: amount=%, unit=%, prov=%',
      v_sol.cogs_amount_vnd, v_sol.cogs_unit_cost, v_sol.cogs_is_provisional;
  end if;

  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa and lot_key = v_lot1;
  if v_bal <> 3 then
    raise exception 'FAIL [S1]: lot1 balance expected 3, got %', v_bal;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pa, 'S1');

  -- -------------------------------------------------------------------------
  -- S2: Debt Sale
  -- -------------------------------------------------------------------------
  v_res := public._isl_finalize(v_t, v_owner, v_store, v_cust,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 1000000, 50000)),
    '[]'::jsonb, v_today + 3, 's2-key');

  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL [S2]: debt sale finalize failed: %', v_res;
  end if;

  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa and lot_key = v_lot1;
  if v_bal <> 2 then
    raise exception 'FAIL [S2]: lot1 balance expected 2, got %', v_bal;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pa, 'S2');

  -- -------------------------------------------------------------------------
  -- S4: Cancel order spanning 2 lots (Reverse FEFO)
  -- -------------------------------------------------------------------------
  -- Mua 4 hộp PA: xuất 2 hộp Lô 1 (hết lô 1) và 2 hộp Lô 2 (bán nợ để đủ điều kiện huỷ EP-05)
  v_res := public._isl_finalize(v_t, v_owner, v_store, v_cust,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 4000000, 50000)),
    '[]'::jsonb, v_today + 5, 's4-key');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL [S4]: finalize failed: %', v_res;
  end if;
  v_order_id := (v_res ->> 'salesOrderId')::uuid;

  -- Huỷ đơn
  v_res := public._isl_cancel(v_t, v_owner, v_order_id, 's4-cancel-key');
  if not exists (select 1 from sales.sales_orders where id = v_order_id and lifecycle_status = 'cancelled') then
    raise exception 'FAIL [S4]: order lifecycle not cancelled';
  end if;

  -- Kiểm tra số lượng hoàn về Lô 1 = 2, Lô 2 = 5
  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa and lot_key = v_lot1;
  if v_bal <> 2 then
    raise exception 'FAIL [S4]: lot1 balance after cancellation expected 2, got %', v_bal;
  end if;

  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa and lot_key = v_lot2;
  if v_bal <> 5 then
    raise exception 'FAIL [S4]: lot2 balance after cancellation expected 5, got %', v_bal;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pa, 'S4');

  -- -------------------------------------------------------------------------
  -- S5: 3 partial returns 4/4/1 from PB (initial 10)
  -- -------------------------------------------------------------------------
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pb, v_ub, 10000000, 60000)),
    public._isl_pay(600000), null, 's5-key');
  v_order_id := (v_res ->> 'salesOrderId')::uuid;
  select id into v_sol_id from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_order_id;

  -- Trả lần 1: 4 hộp
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
    jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_sol_id, 'product_id', v_pb, 'product_unit_id', v_ub, 'quantity_micros', 4000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    's5-ret1-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, v_t, v_owner, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_rx_id, 's5-ret1-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);

  -- Trả lần 2: 4 hộp
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
    jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_sol_id, 'product_id', v_pb, 'product_unit_id', v_ub, 'quantity_micros', 4000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    's5-ret2-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, v_t, v_owner, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_rx_id, 's5-ret2-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);

  -- Trả lần 3: 1 hộp
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
    jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_sol_id, 'product_id', v_pb, 'product_unit_id', v_ub, 'quantity_micros', 1000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    's5-ret3-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, v_t, v_owner, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_rx_id, 's5-ret3-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);

  -- Thử trả lần 4: 2 hộp -> phải lỗi RETURN_QUANTITY_EXCEEDED
  begin
    perform sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
      jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_sol_id, 'product_id', v_pb, 'product_unit_id', v_ub, 'quantity_micros', 2000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD')),
      's5-ret4-start', 'h', gen_random_uuid()::text);
    raise exception 'FAIL [S5]: expected RETURN_QUANTITY_EXCEEDED';
  exception when others then
    if sqlerrm not like '%RETURN_QUANTITY_EXCEEDED%' then
      raise exception 'FAIL [S5]: expected RETURN_QUANTITY_EXCEEDED, got %', sqlerrm;
    end if;
  end;

  -- Tổng hoàn lại: 4 + 4 + 1 = 9 hộp PB. Tồn kho PB = 0 + 9 = 9 hộp.
  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pb;
  if v_bal <> 9 then
    raise exception 'FAIL [S5]: balance of PB expected 9, got %', v_bal;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pb, 'S5');

  -- -------------------------------------------------------------------------
  -- S6: Exchange PA -> PC, then return PC
  -- -------------------------------------------------------------------------
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 1000000, 50000)),
    public._isl_pay(50000), null, 's6-key');
  v_order_id := (v_res ->> 'salesOrderId')::uuid;
  select id into v_sol_id from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_order_id;

  -- Đổi 1 hộp PA lấy 1 hộp PC
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
    jsonb_build_array(
      jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_sol_id, 'product_id', v_pa, 'product_unit_id', v_ua, 'quantity_micros', 1000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD'),
      jsonb_build_object('kind', 'exchangeLine', 'product_id', v_pc, 'product_unit_id', v_uc, 'quantity_micros', 1000000)
    ),
    's6-ex-start', 'h', gen_random_uuid()::text,
    reference_decision => jsonb_build_object('exchange_prices_by_product_unit_id',
      jsonb_build_object(v_uc::text, jsonb_build_object('amountMinor', 50000))));
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, v_t, v_owner, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_rx_id, 's6-ex-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);

  -- Kiểm tra COGS snapshot trên return_exchange_lines
  select * into v_rx_line from sales.return_exchange_lines where tenant_id = v_t and return_exchange_order_id = v_rx_id and line_role = 'exchange';
  if v_rx_line.cogs_amount_vnd <> 15000 or v_rx_line.cogs_unit_cost <> 15000 then
    raise exception 'FAIL [S6]: exchange line COGS expected 15000, got amount=%, unit=%', v_rx_line.cogs_amount_vnd, v_rx_line.cogs_unit_cost;
  end if;
  v_ex_line_id := v_rx_line.id;

  -- Trả lại chính món đổi PC đó
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_order_id, 'standard',
    jsonb_build_array(
      jsonb_build_object('kind', 'returnLine', 'source_exchange_line_id', v_ex_line_id, 'product_id', v_pc, 'product_unit_id', v_uc, 'quantity_micros', 1000000, 'reason_code', 'OTHER', 'condition_code', 'GOOD')
    ),
    's6-ret-pc-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, v_t, v_owner, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, v_t, v_owner, v_rx_id, 's6-ret-pc-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);

  -- Tồn PC ban đầu 5, đổi xuất 1 còn 4, trả hoàn 1 về 5
  select physical_quantity into v_bal from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pc;
  if v_bal <> 5 then
    raise exception 'FAIL [S6]: balance of PC expected 5, got %', v_bal;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pa, 'S6-PA');
  perform public._assert_inventory_invariants(v_t, v_pc, 'S6-PC');

  -- -------------------------------------------------------------------------
  -- S7: Insufficient stock (precheck, finalize, idempotent replay)
  -- -------------------------------------------------------------------------
  v_pre := sales.precheck_sales_order_checkout(
    p_query_id => gen_random_uuid(), p_tenant_id => v_t, p_actor_id => v_owner, p_store_id => v_store,
    p_customer_id => null, p_currency_code => 'VND',
    p_lines => jsonb_build_array(public._isl_line(v_pd, v_ud, 1000000, 30000)),
    p_payment_intents => public._isl_pay(30000)
  );

  if (v_pre ->> 'canFinalize')::boolean is not false then
    raise exception 'FAIL [S7]: precheck should have canFinalize = false';
  end if;

  if not exists (select 1 from jsonb_array_elements(v_pre -> 'blockers') b where b ->> 'code' = 'INSUFFICIENT_STOCK') then
    raise exception 'FAIL [S7]: precheck missing INSUFFICIENT_STOCK blocker: %', v_pre;
  end if;

  -- Finalize out of stock
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pd, v_ud, 1000000, 30000)),
    public._isl_pay(30000), null, 's7-blocked-key');

  if v_res ->> 'status' <> 'blocked' or v_res ->> 'blockedCode' <> 'INSUFFICIENT_STOCK' or coalesce(v_res ->> 'blockedMessage', '') = '' then
    raise exception 'FAIL [S7]: finalize blocked result invalid: %', v_res;
  end if;

  -- S7b: Replay blocked
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pd, v_ud, 1000000, 30000)),
    public._isl_pay(30000), null, 's7-blocked-key');

  if v_res ->> 'status' <> 'blocked' or v_res ->> 'blockedCode' <> 'INSUFFICIENT_STOCK' then
    raise exception 'FAIL [S7b]: replay blocked result invalid: %', v_res;
  end if;

  -- -------------------------------------------------------------------------
  -- S8: Idempotent finalize (success)
  -- -------------------------------------------------------------------------
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 1000000, 50000)),
    public._isl_pay(50000), null, 's8-idem-key');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL [S8]: initial finalize failed: %', v_res;
  end if;

  select sum(physical_quantity) into v_bal1 from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa;

  -- Replay
  v_res := public._isl_finalize(v_t, v_owner, v_store, null,
    jsonb_build_array(public._isl_line(v_pa, v_ua, 1000000, 50000)),
    public._isl_pay(50000), null, 's8-idem-key');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL [S8]: replay finalize failed: %', v_res;
  end if;

  select sum(physical_quantity) into v_bal2 from inventory.stock_balances
  where tenant_id = v_t and warehouse_id = v_wh and product_id = v_pa;

  if v_bal1 <> v_bal2 then
    raise exception 'FAIL [S8]: replay deducted stock twice: bal1=% vs bal2=%', v_bal1, v_bal2;
  end if;

  perform public._assert_inventory_invariants(v_t, v_pa, 'S8');

  raise notice 'inventory_sales_link Task 2 (S1-S8): OK';
end;
$$;

rollback;

