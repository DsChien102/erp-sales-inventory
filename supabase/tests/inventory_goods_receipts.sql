-- Test suite for inventory_goods_receipts (T7-G5-3)
-- Run via: psql -f supabase/tests/inventory_goods_receipts.sql

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
  v_tenant_id uuid := gen_random_uuid();
  v_owner_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();

  v_sup_a uuid := gen_random_uuid();
  v_sup_b uuid := gen_random_uuid();
  v_sup_invalid uuid := gen_random_uuid();
  v_walk_in uuid;

  v_p1 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_p3 uuid := gen_random_uuid();
  v_p_lot uuid := gen_random_uuid();
  v_p_unit uuid := gen_random_uuid();

  v_u1_base uuid := gen_random_uuid();
  v_u2_base uuid := gen_random_uuid();
  v_u3_base uuid := gen_random_uuid();
  v_u_lot_base uuid := gen_random_uuid();
  v_u_box_base uuid := gen_random_uuid();
  v_u_crate uuid := gen_random_uuid(); -- conversion rate 10

  v_prog_tier uuid := gen_random_uuid();
  v_prog_rebate uuid := gen_random_uuid();

  v_res jsonb;
  v_payload_spec jsonb;
  v_receipt_spec uuid;
  v_receipt_id uuid;
  v_line_rec record;
  v_rc_header record;
  v_today date := inventory._today();
begin
  -- 1. Setup Auth, Tenant, Warehouse -----------------------------------------
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-gr-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Goods Receipt Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_tenant_id, v_owner_id, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'GR01', 'Cửa hàng chính GR', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính GR', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  -- Set auth context
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- Cost policy (kỳ được _ensure_open_period tự mở)
  insert into inventory.cost_policies (tenant_id, method, changed_by)
  values (v_tenant_id, 'MOVING', v_owner_id)
  on conflict (tenant_id) do nothing;

  -- 2. Setup Suppliers -------------------------------------------------------
  v_walk_in := inventory._ensure_walk_in_supplier(v_tenant_id);

  insert into partner.partners (partner_id, tenant_id, partner_type, display_name, status, created_by, updated_by)
  values
    (v_sup_a, v_tenant_id, 'organization', 'Nhà cung cấp Á Châu', 'active', v_owner_id, v_owner_id),
    (v_sup_b, v_tenant_id, 'organization', 'Nhà cung cấp Bình Minh', 'active', v_owner_id, v_owner_id),
    (v_sup_invalid, v_tenant_id, 'person', 'Khách hàng lẻ', 'active', v_owner_id, v_owner_id);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values
    (v_sup_a, v_tenant_id, 'supplier'),
    (v_sup_b, v_tenant_id, 'supplier'),
    (v_sup_invalid, v_tenant_id, 'customer');

  -- 3. Setup Products & Units ------------------------------------------------
  insert into catalog.products (id, tenant_id, name, sku, barcode, tracking_mode, expiry_required, business_status, reference_id, created_by, updated_by)
  values
    (v_p1, v_tenant_id, 'Nobivac DHPPi', 'SP-01', '8930001', 'none', false, 'active', 'GR-SP-01', v_owner_id, v_owner_id),
    (v_p2, v_tenant_id, 'Oxytetracycline LA', 'SP-02', '8930002', 'none', false, 'active', 'GR-SP-02', v_owner_id, v_owner_id),
    (v_p3, v_tenant_id, 'Vitamin C', 'SP-03', '8930003', 'none', false, 'active', 'GR-SP-03', v_owner_id, v_owner_id),
    (v_p_lot, v_tenant_id, 'Vắc xin Dại', 'SP-LOT', '8930004', 'lot', true, 'active', 'GR-SP-LOT', v_owner_id, v_owner_id),
    (v_p_unit, v_tenant_id, 'Men tiêu hóa', 'SP-UNIT', '8930005', 'none', false, 'active', 'GR-SP-UNIT', v_owner_id, v_owner_id);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_u1_base, v_tenant_id, v_p1, 'hộp', 1, true),
    (v_u2_base, v_tenant_id, v_p2, 'hộp', 1, true),
    (v_u3_base, v_tenant_id, v_p3, 'hộp', 1, true),
    (v_u_lot_base, v_tenant_id, v_p_lot, 'hộp', 1, true),
    (v_u_box_base, v_tenant_id, v_p_unit, 'hộp', 1, true),
    (v_u_crate, v_tenant_id, v_p_unit, 'thùng', 10, false);

  -- 4. Setup Programs --------------------------------------------------------
  -- Tier discount program on v_sup_a for v_p1
  insert into inventory.supplier_programs (
    id, tenant_id, supplier_id, name, kind, status, started_on, created_by, updated_by
  ) values (
    v_prog_tier, v_tenant_id, v_sup_a, 'Ưu đãi Nobivac Bậc', 'TIER_DISCOUNT', 'ACTIVE', v_today, v_owner_id, v_owner_id
  );
  insert into inventory.supplier_program_products (program_id, tenant_id, product_id)
  values (v_prog_tier, v_tenant_id, v_p1);
  insert into inventory.supplier_program_tiers (program_id, tenant_id, min_qty, discount_percent)
  values (v_prog_tier, v_tenant_id, 100, 3.00), (v_prog_tier, v_tenant_id, 300, 5.00);

  -- Volume rebate program on v_sup_b for v_p3
  insert into inventory.supplier_programs (
    id, tenant_id, supplier_id, name, kind, status, started_on, target_qty, rebate_percent, progress_qty, created_by, updated_by
  ) values (
    v_prog_rebate, v_tenant_id, v_sup_b, 'Tích lũy Vitamin C', 'VOLUME_REBATE', 'ACTIVE', v_today, 1000, 10.00, 0, v_owner_id, v_owner_id
  );
  insert into inventory.supplier_program_products (program_id, tenant_id, product_id)
  values (v_prog_rebate, v_tenant_id, v_p3);

  -- =========================================================================
  -- TEST CASE: spec_example_4_1
  -- 2 sản phẩm không lô, hộp, paid 6 × 100.000, paid 4 × 100.000; F 50.000, D 20.000
  -- Kỳ vọng: a 600.000 / 400.000, f 30.000 / 20.000, k 12.000 / 8.000, g 618.000 / 412.000
  -- =========================================================================
  v_payload_spec := jsonb_build_object(
      'supplier_id', v_sup_a,
      'freight_cost_vnd', 50000,
      'trade_discount_vnd', 20000,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p1, 'unit_id', v_u1_base, 'unit_price_vnd', 100000,
          'free_qty', 0, 'program_id', v_prog_tier, 'tier_discount_percent', 0,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 6))
        ),
        jsonb_build_object(
          'product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 100000,
          'free_qty', 0, 'program_id', null,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 4))
        )
      )
    );
  v_res := inventory.record_goods_receipt(v_tenant_id, 'key-spec-4-1', v_payload_spec);

  v_receipt_id := (v_res->>'receipt_id')::uuid;
  v_receipt_spec := v_receipt_id;
  if (v_res->>'landed_total_vnd')::bigint <> 1030000 then
    raise exception 'FAIL: spec_example_4_1 landed_total mismatch %', v_res->>'landed_total_vnd';
  end if;

  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p1;
  if v_line_rec.purchase_amount_vnd <> 600000 or v_line_rec.allocated_freight_vnd <> 30000 or v_line_rec.allocated_discount_vnd <> 12000 or v_line_rec.landed_amount_vnd <> 618000 or v_line_rec.landed_unit_cost <> 103000 then
    raise exception 'FAIL: spec_example_4_1 line 1 calc mismatch';
  end if;

  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p2;
  if v_line_rec.purchase_amount_vnd <> 400000 or v_line_rec.allocated_freight_vnd <> 20000 or v_line_rec.allocated_discount_vnd <> 8000 or v_line_rec.landed_amount_vnd <> 412000 or v_line_rec.landed_unit_cost <> 103000 then
    raise exception 'FAIL: spec_example_4_1 line 2 calc mismatch';
  end if;

  -- =========================================================================
  -- TEST CASE: tier_case12
  -- 1 dòng paid 300 × 100.000, bậc 5% -> gross 30.000.000, tier 1.500.000, g 28.500.000
  -- =========================================================================
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-tier-12',
    jsonb_build_object(
      'supplier_id', v_sup_a,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p1, 'unit_id', v_u1_base, 'unit_price_vnd', 100000,
          'free_qty', 0, 'program_id', v_prog_tier, 'tier_discount_percent', 5.00,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 300))
        )
      )
    )
  );

  v_receipt_id := (v_res->>'receipt_id')::uuid;
  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p1;
  if v_line_rec.gross_amount_vnd <> 30000000 or v_line_rec.tier_discount_vnd <> 1500000 or v_line_rec.landed_amount_vnd <> 28500000 or v_line_rec.landed_unit_cost <> 95000 then
    raise exception 'FAIL: tier_case12 line calc mismatch';
  end if;

  -- =========================================================================
  -- TEST CASE: buy_x_get_y_case13
  -- kho trước có 20 hộp bq 50.000. Phiếu mới: lô 11 hộp, free 1, giá 50.000
  -- landed_unit_cost = 45.454,5455
  -- =========================================================================
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-buy-x-13',
    jsonb_build_object(
      'supplier_id', v_sup_b,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 50000,
          'free_qty', 1,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 11))
        )
      )
    )
  );

  v_receipt_id := (v_res->>'receipt_id')::uuid;
  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p2;
  if v_line_rec.paid_qty <> 10 or v_line_rec.landed_amount_vnd <> 500000 or v_line_rec.landed_unit_cost <> 45454.5455 then
    raise exception 'FAIL: buy_x_get_y_case13 line calc mismatch';
  end if;

  -- =========================================================================
  -- TEST CASE: allocation_rounding
  -- 3 sản phẩm; dòng 1 có 3 lô 1/1/1 × 111.112 (a 333.336), dòng 2, 3 mỗi dòng 1 × 333.332
  -- A 1.000.000, F 100.000, D 10.001 -> f 33.334 / 33.333 / 33.333; k 3.335 / 3.333 / 3.333
  -- =========================================================================
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-alloc-round',
    jsonb_build_object(
      'supplier_id', v_sup_a,
      'freight_cost_vnd', 100000,
      'trade_discount_vnd', 10001,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p_lot, 'unit_id', v_u_lot_base, 'unit_price_vnd', 111112,
          'free_qty', 0,
          'lots', jsonb_build_array(
            jsonb_build_object('lot_code', 'LOT-01', 'expiry_date', '2026-12-31', 'quantity', 1),
            jsonb_build_object('lot_code', 'LOT-02', 'expiry_date', '2026-12-31', 'quantity', 1),
            jsonb_build_object('lot_code', 'LOT-03', 'expiry_date', '2026-12-31', 'quantity', 1)
          )
        ),
        jsonb_build_object(
          'product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 333332,
          'free_qty', 0,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 1))
        ),
        jsonb_build_object(
          'product_id', v_p3, 'unit_id', v_u3_base, 'unit_price_vnd', 333332,
          'free_qty', 0,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 1))
        )
      )
    )
  );

  v_receipt_id := (v_res->>'receipt_id')::uuid;
  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p_lot;
  if v_line_rec.allocated_freight_vnd <> 33334 or v_line_rec.allocated_discount_vnd <> 3335 or v_line_rec.landed_amount_vnd <> 363335 or v_line_rec.landed_unit_cost <> 121111.6667 then
    raise exception 'FAIL: allocation_rounding line 1 calc mismatch: % % % %',
      v_line_rec.allocated_freight_vnd, v_line_rec.allocated_discount_vnd, v_line_rec.landed_amount_vnd, v_line_rec.landed_unit_cost;
  end if;

  -- =========================================================================
  -- TEST CASE: unit_conversion_landed_cost
  -- ĐVT thùng (rate 10), lô 2 thùng, giá 500.000 / thùng -> landed_unit_cost 50.000 / hộp
  -- =========================================================================
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-unit-conv',
    jsonb_build_object(
      'supplier_id', v_sup_b,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p_unit, 'unit_id', v_u_crate, 'unit_price_vnd', 500000,
          'free_qty', 0,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 2))
        )
      )
    )
  );

  v_receipt_id := (v_res->>'receipt_id')::uuid;
  select * into v_line_rec from inventory.goods_receipt_lines where receipt_id = v_receipt_id and product_id = v_p_unit;
  if v_line_rec.landed_amount_vnd <> 1000000 or v_line_rec.landed_unit_cost <> 50000 then
    raise exception 'FAIL: unit_conversion_landed_cost mismatch';
  end if;

  -- =========================================================================
  -- TEST CASE: walk_in_supplier_ok
  -- =========================================================================
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-walk-in',
    jsonb_build_object(
      'supplier_id', v_walk_in,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 50000,
          'free_qty', 0,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 1))
        )
      )
    )
  );

  -- =========================================================================
  -- TEST CASE: Error Cases (expect_err)
  -- =========================================================================
  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-sup-req', '{"lines":[]}'),
    'SUPPLIER_REQUIRED',
    'supplier_required'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-sup-inv', jsonb_build_object('supplier_id', v_sup_invalid, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p1, 'unit_id', v_u1_base, 'unit_price_vnd', 1000, 'lots', jsonb_build_array(jsonb_build_object('quantity', 1)))))),
    'SUPPLIER_INVALID',
    'supplier_invalid'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-prog-chg', jsonb_build_object('supplier_id', v_sup_a, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p1, 'unit_id', v_u1_base, 'unit_price_vnd', 1000, 'program_id', gen_random_uuid(), 'lots', jsonb_build_array(jsonb_build_object('quantity', 1)))))),
    'RECEIPT_PROGRAM_CHANGED',
    'program_changed_rejected'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-tier-inv', jsonb_build_object('supplier_id', v_sup_b, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 1000, 'tier_discount_percent', 5, 'lots', jsonb_build_array(jsonb_build_object('quantity', 1)))))),
    'CONTEXT_INVALID',
    'tier_percent_without_tier_program'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-disc-large', jsonb_build_object('supplier_id', v_sup_b, 'trade_discount_vnd', 200000, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 100000, 'lots', jsonb_build_array(jsonb_build_object('quantity', 1)))))),
    'RECEIPT_DISCOUNT_TOO_LARGE',
    'discount_too_large'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-free-tot', jsonb_build_object('supplier_id', v_sup_b, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p2, 'unit_id', v_u2_base, 'unit_price_vnd', 100000, 'free_qty', 2, 'lots', jsonb_build_array(jsonb_build_object('quantity', 2)))))),
    'CONTEXT_INVALID',
    'free_not_less_than_total'
  );

  -- =========================================================================
  -- TEST CASE: volume_rebate_reached
  -- Tiền đề: v_p3 target 1000. Nhập 950 rồi nhập 80 -> REACHED (progress 1030)
  -- =========================================================================
  perform inventory.record_goods_receipt(
    v_tenant_id,
    'key-rebate-950',
    jsonb_build_object(
      'supplier_id', v_sup_b,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p3, 'unit_id', v_u3_base, 'unit_price_vnd', 10000,
          'program_id', v_prog_rebate,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 950))
        )
      )
    )
  );

  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'key-rebate-80',
    jsonb_build_object(
      'supplier_id', v_sup_b,
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p3, 'unit_id', v_u3_base, 'unit_price_vnd', 10000,
          'program_id', v_prog_rebate,
          'lots', jsonb_build_array(jsonb_build_object('quantity', 80))
        )
      )
    )
  );

  if jsonb_array_length(v_res->'reached_programs') <> 1 then
    raise exception 'FAIL: volume_rebate_reached should report reached_programs';
  end if;

  select * into v_rc_header from inventory.supplier_programs where id = v_prog_rebate;
  if v_rc_header.status <> 'REACHED' or v_rc_header.progress_qty <> 1030 then
    raise exception 'FAIL: volume_rebate_reached program state mismatch';
  end if;

  -- =========================================================================
  -- TEST CASE: program_locked_after_receipt
  -- =========================================================================
  if not inventory._program_is_locked(v_prog_tier) then
    raise exception 'FAIL: program_locked_after_receipt v_prog_tier should be locked';
  end if;

  -- =========================================================================
  -- TEST CASE: lot_conflict_rolls_back
  -- LOT-01 đã có với HSD 2026-12-31. Gửi lại với HSD 2027-01-01 -> LOT_ATTRIBUTE_CONFLICT
  -- =========================================================================
  perform pg_temp.expect_err(
    format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'err-lot-conflict', jsonb_build_object('supplier_id', v_sup_a, 'lines', jsonb_build_array(jsonb_build_object('product_id', v_p_lot, 'unit_id', v_u_lot_base, 'unit_price_vnd', 50000, 'lots', jsonb_build_array(jsonb_build_object('lot_code', 'LOT-01', 'expiry_date', '2027-01-01', 'quantity', 5)))))),
    'LOT_ATTRIBUTE_CONFLICT',
    'lot_conflict_rolls_back'
  );

  -- =========================================================================
  -- TEST CASE: record_idempotent_replay
  -- =========================================================================
  declare
    v_replay jsonb;
  begin
    -- Gửi lại cùng khoá + cùng payload ⇒ trả lại đúng phiếu cũ, không ghi thêm
    v_replay := inventory.record_goods_receipt(v_tenant_id, 'key-spec-4-1', v_payload_spec);
    if (v_replay->>'receipt_id')::uuid is distinct from v_receipt_spec then
      raise exception 'FAIL: record_idempotent_replay returned % instead of %', v_replay->>'receipt_id', v_receipt_spec;
    end if;
    if (select count(*) from inventory.goods_receipts where tenant_id = v_tenant_id and id = v_receipt_spec) <> 1 then
      raise exception 'FAIL: record_idempotent_replay duplicated receipt';
    end if;
    -- Cùng khoá, payload khác ⇒ IDEMPOTENCY_CONFLICT
    perform pg_temp.expect_err(
      format('select inventory.record_goods_receipt(%L, %L, %L::jsonb)', v_tenant_id, 'key-spec-4-1', jsonb_build_object('dummy', 1)),
      'IDEMPOTENCY_CONFLICT',
      'record_idempotent_conflict'
    );
  end;

  -- =========================================================================
  -- TEST CASE: receipt_no_sequence
  -- =========================================================================
  select receipt_no into v_rc_header from inventory.goods_receipts where tenant_id = v_tenant_id order by created_at asc limit 1;
  if v_rc_header.receipt_no not like 'PN-%-01' then
    raise exception 'FAIL: receipt_no_sequence first receipt was %', v_rc_header.receipt_no;
  end if;

  -- =========================================================================
  -- TEST CASE: list_and_get
  -- =========================================================================
  v_res := inventory.list_goods_receipts(v_tenant_id, v_sup_a);
  if jsonb_array_length(v_res->'receipts') < 1 then
    raise exception 'FAIL: list_goods_receipts should return receipts for v_sup_a';
  end if;

  v_res := inventory.get_goods_receipt(v_tenant_id, (v_res->'receipts'->0->>'receipt_id')::uuid);
  if v_res->'receipt'->>'receipt_no' is null or jsonb_array_length(v_res->'lines') < 1 then
    raise exception 'FAIL: get_goods_receipt invalid result';
  end if;

  -- Phiếu không thuộc tenant (mã lạ) ⇒ CONTEXT_INVALID
  perform pg_temp.expect_err(
    format('select inventory.get_goods_receipt(%L, %L)', v_tenant_id, gen_random_uuid()),
    'CONTEXT_INVALID',
    'get_goods_receipt unknown receipt'
  );
  -- Tenant không phải thành viên ⇒ PERMISSION_DENIED (chặn ở _assert_actor)
  perform pg_temp.expect_err(
    format('select inventory.get_goods_receipt(%L, %L)', gen_random_uuid(), (v_res->'receipt'->>'receipt_id')::uuid),
    'PERMISSION_DENIED',
    'get_goods_receipt cross tenant blocked'
  );

  -- Test get_receipt_lots_keep_entry_order
  v_res := inventory.record_goods_receipt(
    v_tenant_id,
    'order-test-key-1',
    jsonb_build_object(
      'supplier_id', v_sup_a,
      'supplier_doc_no', 'HD-ORDER-1',
      'lines', jsonb_build_array(
        jsonb_build_object(
          'product_id', v_p_lot,
          'unit_id', v_u_lot_base,
          'unit_price_vnd', 100000,
          'free_qty', 0,
          'lots', jsonb_build_array(
            jsonb_build_object('lot_code', 'LOT_B', 'expiry_date', '2027-01-01', 'expiry_precision', 'DAY', 'quantity', 10),
            jsonb_build_object('lot_code', 'LOT_A', 'expiry_date', '2027-01-01', 'expiry_precision', 'DAY', 'quantity', 10),
            jsonb_build_object('lot_code', 'LOT_C', 'expiry_date', '2027-01-01', 'expiry_precision', 'DAY', 'quantity', 10)
          )
        )
      )
    )
  );

  v_res := inventory.get_goods_receipt(v_tenant_id, (v_res->>'receipt_id')::uuid);
  if (v_res->'lines'->0->'lots'->0->>'lot_code') <> 'LOT_B' or
     (v_res->'lines'->0->'lots'->1->>'lot_code') <> 'LOT_A' or
     (v_res->'lines'->0->'lots'->2->>'lot_code') <> 'LOT_C' then
    raise exception 'FAIL: get_receipt_lots_keep_entry_order lots did not preserve entry order';
  end if;

  raise notice 'ALL GOODS RECEIPT SQL TESTS PASSED!';
end;
$$;

