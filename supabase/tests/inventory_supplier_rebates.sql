-- Test suite for inventory_supplier_rebates (T7-G5-5b Task 1)
-- Run via: psql -f supabase/tests/inventory_supplier_rebates.sql

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
  v_staff_id uuid := gen_random_uuid();
  v_store_id uuid := gen_random_uuid();
  v_warehouse_id uuid := gen_random_uuid();

  v_sup_a uuid := gen_random_uuid();
  v_sup_b uuid := gen_random_uuid();
  v_sup_c uuid := gen_random_uuid();
  v_sup_cmp_a uuid := gen_random_uuid();
  v_walkin_id uuid;

  -- Products (sorted UUIDs generated cleanly for 15a tie-break)
  v_p14 uuid := gen_random_uuid();
  v_p15a_ids uuid[] := array[
    '10000000-0000-4000-8000-000000000001'::uuid,
    '20000000-0000-4000-8000-000000000002'::uuid,
    '30000000-0000-4000-8000-000000000003'::uuid
  ];
  v_p15b uuid := gen_random_uuid();
  v_p_zero uuid := gen_random_uuid();
  v_p_cap uuid := gen_random_uuid();
  v_p_recomp uuid := gen_random_uuid();
  v_p_err uuid := gen_random_uuid();
  v_p_active uuid := gen_random_uuid();
  v_p_proj uuid := gen_random_uuid();
  v_p_cmp uuid := gen_random_uuid();

  v_u14 uuid := gen_random_uuid();
  v_u15a_1 uuid := gen_random_uuid();
  v_u15a_2 uuid := gen_random_uuid();
  v_u15a_3 uuid := gen_random_uuid();
  v_u15b uuid := gen_random_uuid();
  v_u_zero uuid := gen_random_uuid();
  v_u_cap uuid := gen_random_uuid();
  v_u_recomp uuid := gen_random_uuid();
  v_u_err uuid := gen_random_uuid();
  v_u_active uuid := gen_random_uuid();
  v_u_proj uuid := gen_random_uuid();
  v_u_cmp uuid := gen_random_uuid();

  v_prog14 uuid;
  v_prog15a uuid;
  v_prog15b uuid;
  v_prog_zero uuid;
  v_prog_cap uuid;
  v_prog_recomp uuid;
  v_prog_err uuid;
  v_prog_active uuid;
  v_prog_proj uuid;
  v_prog_cmp uuid;

  v_today date := inventory._today();
  v_res jsonb;
  v_res2 jsonb;
  v_detail jsonb;
  v_hub jsonb;
  v_vm_count_before int;
  v_vm_count_after int;
  v_alloc jsonb;
  v_sup_row jsonb;
  v_cmp_count int;
  v_bad_mismatch int;
  v_bad_rebate_sum int;
begin
  -- 1. Fixture (owner + staff + store + warehouse + cost_policy)
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-reb-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  ), (
    v_staff_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'staff-reb-' || substr(v_staff_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Rebate Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values
    (v_tenant_id, v_owner_id, 'store_owner', true),
    (v_tenant_id, v_staff_id, 'staff', false);

  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'RB01', 'Cửa hàng RB', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho RB', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  insert into inventory.cost_policies (tenant_id, method, changed_by)
  values (v_tenant_id, 'MOVING', v_owner_id)
  on conflict (tenant_id) do nothing;

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  v_walkin_id := inventory._ensure_walk_in_supplier(v_tenant_id);

  insert into partner.partners (partner_id, tenant_id, partner_type, display_name, status, created_by, updated_by)
  values
    (v_sup_a, v_tenant_id, 'organization', 'NCC A', 'active', v_owner_id, v_owner_id),
    (v_sup_b, v_tenant_id, 'organization', 'NCC B', 'active', v_owner_id, v_owner_id),
    (v_sup_c, v_tenant_id, 'organization', 'NCC C', 'active', v_owner_id, v_owner_id),
    (v_sup_cmp_a, v_tenant_id, 'organization', 'NCC So Sánh A', 'active', v_owner_id, v_owner_id);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values
    (v_sup_a, v_tenant_id, 'supplier'),
    (v_sup_b, v_tenant_id, 'supplier'),
    (v_sup_c, v_tenant_id, 'supplier'),
    (v_sup_cmp_a, v_tenant_id, 'supplier');

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, reference_id, created_by, updated_by)
  values
    (v_p14, v_tenant_id, 'Nobivac DHPPi', 'RB-14', 'none', false, 'active', 'RB-14', v_owner_id, v_owner_id),
    (v_p15a_ids[1], v_tenant_id, 'Thuốc A1', 'RB-15A1', 'none', false, 'active', 'RB-15A1', v_owner_id, v_owner_id),
    (v_p15a_ids[2], v_tenant_id, 'Thuốc A2', 'RB-15A2', 'none', false, 'active', 'RB-15A2', v_owner_id, v_owner_id),
    (v_p15a_ids[3], v_tenant_id, 'Thuốc A3', 'RB-15A3', 'none', false, 'active', 'RB-15A3', v_owner_id, v_owner_id),
    (v_p15b, v_tenant_id, 'Thuốc 15B', 'RB-15B', 'none', false, 'active', 'RB-15B', v_owner_id, v_owner_id),
    (v_p_zero, v_tenant_id, 'Thuốc Zero', 'RB-ZERO', 'none', false, 'active', 'RB-ZERO', v_owner_id, v_owner_id),
    (v_p_cap, v_tenant_id, 'Thuốc Cap', 'RB-CAP', 'none', false, 'active', 'RB-CAP', v_owner_id, v_owner_id),
    (v_p_recomp, v_tenant_id, 'Thuốc Recomp', 'RB-RECOMP', 'none', false, 'active', 'RB-RECOMP', v_owner_id, v_owner_id),
    (v_p_err, v_tenant_id, 'Thuốc Err', 'RB-ERR', 'none', false, 'active', 'RB-ERR', v_owner_id, v_owner_id),
    (v_p_active, v_tenant_id, 'Thuốc Active', 'RB-ACT', 'none', false, 'active', 'RB-ACT', v_owner_id, v_owner_id),
    (v_p_proj, v_tenant_id, 'Thuốc Proj', 'RB-PROJ', 'none', false, 'active', 'RB-PROJ', v_owner_id, v_owner_id),
    (v_p_cmp, v_tenant_id, 'Thuốc Compare', 'RB-CMP', 'none', false, 'active', 'RB-CMP', v_owner_id, v_owner_id);

  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_u14, v_tenant_id, v_p14, 'hộp', 1, true),
    (v_u15a_1, v_tenant_id, v_p15a_ids[1], 'hộp', 1, true),
    (v_u15a_2, v_tenant_id, v_p15a_ids[2], 'hộp', 1, true),
    (v_u15a_3, v_tenant_id, v_p15a_ids[3], 'hộp', 1, true),
    (v_u15b, v_tenant_id, v_p15b, 'hộp', 1, true),
    (v_u_zero, v_tenant_id, v_p_zero, 'hộp', 1, true),
    (v_u_cap, v_tenant_id, v_p_cap, 'hộp', 1, true),
    (v_u_recomp, v_tenant_id, v_p_recomp, 'hộp', 1, true),
    (v_u_err, v_tenant_id, v_p_err, 'hộp', 1, true),
    (v_u_active, v_tenant_id, v_p_active, 'hộp', 1, true),
    (v_u_proj, v_tenant_id, v_p_proj, 'hộp', 1, true),
    (v_u_cmp, v_tenant_id, v_p_cmp, 'hộp', 1, true);

  -- =========================================================================
  -- CASE: case14_single_product + hub_programs_reached + replay/twice + staff_masked
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-14', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc 1.000 hộp Q4',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 10,
    'target_qty', 1000,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p14)
  ));
  v_prog14 := (v_res->>'program_id')::uuid;

  -- Receipt 1: 400 x 100.000
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-14a', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p14, 'unit_id', v_u14, 'unit_price_vnd', 100000,
      'program_id', v_prog14, 'lots', jsonb_build_array(jsonb_build_object('quantity', 400))
    ))
  ));

  -- Receipt 2: 600 x 100.000 -> REACHED
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-14b', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p14, 'unit_id', v_u14, 'unit_price_vnd', 100000,
      'program_id', v_prog14, 'lots', jsonb_build_array(jsonb_build_object('quantity', 600))
    ))
  ));

  -- Sell 700 -> on hand 300
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p14, 'quantity_delta', -700, 'movement_kind', 'SALE')),
    v_owner_id
  );

  -- hub_programs_reached: owner sees 1, staff sees 0
  v_hub := inventory.get_warehouse_hub_summary(v_tenant_id);
  if coalesce((v_hub->'problems'->>'programs_reached')::int, -1) <> 1 then
    raise exception 'FAIL: hub_programs_reached owner expected 1, got %', v_hub;
  end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_staff_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);
  v_hub := inventory.get_warehouse_hub_summary(v_tenant_id);
  if coalesce((v_hub->'problems'->>'programs_reached')::int, -1) <> 0 then
    raise exception 'FAIL: hub_programs_reached staff expected 0, got %', v_hub;
  end if;

  -- staff_denied_and_masked (preview & record denied)
  perform pg_temp.expect_err(
    format('select inventory.preview_supplier_rebate(%L::uuid, %L::uuid, null)', v_tenant_id, v_prog14),
    'PERMISSION_DENIED', 'staff_denied preview'
  );
  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-staff-deny', v_prog14,
      jsonb_build_object('document_no', 'CK-STAFF', 'document_date', v_today, 'amount_vnd', 5000000)::text
    ),
    'PERMISSION_DENIED', 'staff_denied record'
  );

  -- Back to owner
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- Preview case14
  v_res := inventory.preview_supplier_rebate(v_tenant_id, v_prog14, null);
  if (v_res->>'base_amount_vnd')::bigint <> 100000000
     or (v_res->>'proposed_amount_vnd')::bigint <> 5000000
     or (v_res->>'inventory_part_total')::bigint <> 1500000
     or (v_res->>'cogs_part_total')::bigint <> 3500000 then
    raise exception 'FAIL: case14_single_product preview mismatch: %', v_res;
  end if;

  -- Record case14
  select count(*) into v_vm_count_before from inventory.value_movements where tenant_id = v_tenant_id;

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-14', v_prog14, jsonb_build_object(
    'document_no', 'CK-2026-14',
    'document_date', v_today,
    'amount_vnd', 5000000
  ));

  select count(*) into v_vm_count_after from inventory.value_movements where tenant_id = v_tenant_id;
  if v_vm_count_after <> v_vm_count_before + 1 then
    raise exception 'FAIL: case14_single_product expected +1 value_movement, got % -> %', v_vm_count_before, v_vm_count_after;
  end if;

  if not exists (
    select 1 from inventory.value_movements vm
    where vm.tenant_id = v_tenant_id
      and vm.product_id = v_p14
      and vm.kind = 'SUPPLIER_REBATE'
      and vm.amount_vnd = -1500000
      and vm.quantity_basis = 0
      and vm.supplier_rebate_id = (v_res->>'rebate_id')::uuid
  ) then
    raise exception 'FAIL: case14_single_product SUPPLIER_REBATE ledger row mismatch';
  end if;

  if not exists (
    select 1 from inventory.product_costs pc
    where pc.tenant_id = v_tenant_id
      and pc.product_id = v_p14
      and pc.ledger_value_vnd = 28500000
      and pc.moving_avg_cost = 95000
  ) then
    raise exception 'FAIL: case14_single_product product_costs mismatch';
  end if;

  -- hub_programs_reached after record -> 0
  v_hub := inventory.get_warehouse_hub_summary(v_tenant_id);
  if coalesce((v_hub->'problems'->>'programs_reached')::int, -1) <> 0 then
    raise exception 'FAIL: hub_programs_reached after record expected 0, got %', v_hub;
  end if;

  -- record_replay_same_key / record_twice_other_key
  v_res2 := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-14', v_prog14, jsonb_build_object(
    'document_no', 'CK-2026-14',
    'document_date', v_today,
    'amount_vnd', 5000000
  ));
  if (v_res2->>'rebate_id')::uuid <> (v_res->>'rebate_id')::uuid then
    raise exception 'FAIL: record_replay_same_key rebate_id mismatch';
  end if;
  select count(*) into v_vm_count_before from inventory.value_movements where tenant_id = v_tenant_id;
  if v_vm_count_before <> v_vm_count_after then
    raise exception 'FAIL: record_replay_same_key inserted extra value_movements';
  end if;

  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-rec-14-other', v_prog14,
      jsonb_build_object('document_no', 'CK-2026-14', 'document_date', v_today, 'amount_vnd', 5000000)::text
    ),
    'PROGRAM_NOT_REACHED', 'record_twice_other_key'
  );

  -- get_supplier_program owner & staff masked
  v_detail := inventory.get_supplier_program(v_tenant_id, v_prog14);
  if (v_detail->>'viewer_is_owner')::boolean is not true
     or (v_detail->'rebate'->>'rebate_amount_vnd')::bigint <> 5000000
     or (v_detail->'rebate'->>'inventory_part_vnd')::bigint <> 1500000
     or (v_detail->'rebate'->>'cogs_part_vnd')::bigint <> 3500000 then
    raise exception 'FAIL: get_supplier_program owner rebate mismatch: %', v_detail;
  end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_staff_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);
  v_detail := inventory.get_supplier_program(v_tenant_id, v_prog14);
  if (v_detail->>'viewer_is_owner')::boolean is not false
     or (v_detail->'rebate'->>'rebate_amount_vnd') is not null
     or (v_detail->'rebate'->>'base_amount_vnd') is not null
     or (v_detail->'rebate'->>'inventory_part_vnd') is not null
     or (v_detail->'rebate'->'allocations'->0->>'avg_cost_after') is not null then
    raise exception 'FAIL: staff_denied_and_masked get_supplier_program not masked: %', v_detail;
  end if;

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- =========================================================================
  -- CASE: case15a_remainder (3 products x 30.000.000, R = 1.000.000)
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-15a', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc 900 hộp 3 SP',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 900,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p15a_ids[1], v_p15a_ids[2], v_p15a_ids[3])
  ));
  v_prog15a := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-15a', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(
      jsonb_build_object('product_id', v_p15a_ids[1], 'unit_id', v_u15a_1, 'unit_price_vnd', 100000, 'program_id', v_prog15a, 'lots', jsonb_build_array(jsonb_build_object('quantity', 300))),
      jsonb_build_object('product_id', v_p15a_ids[2], 'unit_id', v_u15a_2, 'unit_price_vnd', 100000, 'program_id', v_prog15a, 'lots', jsonb_build_array(jsonb_build_object('quantity', 300))),
      jsonb_build_object('product_id', v_p15a_ids[3], 'unit_id', v_u15a_3, 'unit_price_vnd', 100000, 'program_id', v_prog15a, 'lots', jsonb_build_array(jsonb_build_object('quantity', 300)))
    )
  ));

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-15a', v_prog15a, jsonb_build_object(
    'document_no', 'CK-15A',
    'document_date', v_today,
    'amount_vnd', 1000000,
    'override_reason', 'Thoả thuận lại mức chi'
  ));

  for v_alloc in select * from jsonb_array_elements(v_res->'allocations')
  loop
    if (v_alloc->>'product_id')::uuid = v_p15a_ids[1] then
      if (v_alloc->>'rebate_part_vnd')::bigint <> 333334 then
        raise exception 'FAIL: case15a_remainder smallest uuid expected 333334, got %', v_alloc;
      end if;
    else
      if (v_alloc->>'rebate_part_vnd')::bigint <> 333333 then
        raise exception 'FAIL: case15a_remainder other expected 333333, got %', v_alloc;
      end if;
    end if;
  end loop;

  -- =========================================================================
  -- CASE: case15b_stock_over_q (200 pre-program + 600 in-program = 800, Q = 600)
  -- =========================================================================
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-15b-pre', jsonb_build_object(
    'supplier_id', v_sup_b,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p15b, 'unit_id', v_u15b, 'unit_price_vnd', 100000,
      'lots', jsonb_build_array(jsonb_build_object('quantity', 200))
    ))
  ));

  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-15b', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc 600 hộp',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 600,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p15b)
  ));
  v_prog15b := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-15b-in', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p15b, 'unit_id', v_u15b, 'unit_price_vnd', 100000,
      'program_id', v_prog15b, 'lots', jsonb_build_array(jsonb_build_object('quantity', 600))
    ))
  ));

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-15b', v_prog15b, jsonb_build_object(
    'document_no', 'CK-15B',
    'document_date', v_today,
    'amount_vnd', 3000000
  ));
  if (v_res->>'inventory_part_total')::bigint <> 3000000 or (v_res->>'cogs_part_total')::bigint <> 0 then
    raise exception 'FAIL: case15b_stock_over_q mismatch: %', v_res;
  end if;

  -- =========================================================================
  -- CASE: zero_stock_all_cogs
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-zero', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc Zero',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 100,
    'rebate_percent', 10,
    'product_ids', jsonb_build_array(v_p_zero)
  ));
  v_prog_zero := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-zero', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_zero, 'unit_id', v_u_zero, 'unit_price_vnd', 100000,
      'program_id', v_prog_zero, 'lots', jsonb_build_array(jsonb_build_object('quantity', 100))
    ))
  ));

  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_zero, 'quantity_delta', -100, 'movement_kind', 'SALE')),
    v_owner_id
  );

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-zero', v_prog_zero, jsonb_build_object(
    'document_no', 'CK-ZERO',
    'document_date', v_today,
    'amount_vnd', 1000000
  ));
  if (v_res->>'inventory_part_total')::bigint <> 0 or (v_res->>'cogs_part_total')::bigint <> 1000000 then
    raise exception 'FAIL: zero_stock_all_cogs totals mismatch: %', v_res;
  end if;
  if exists (
    select 1 from inventory.supplier_rebate_allocations a
    where a.rebate_id = (v_res->>'rebate_id')::uuid and a.value_movement_id is not null
  ) then
    raise exception 'FAIL: zero_stock_all_cogs created value_movement';
  end if;

  -- =========================================================================
  -- CASE: cap_by_ledger_value
  -- =========================================================================
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cap-b', jsonb_build_object(
    'supplier_id', v_sup_b,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cap, 'unit_id', v_u_cap, 'unit_price_vnd', 1000,
      'lots', jsonb_build_array(jsonb_build_object('quantity', 90))
    ))
  ));

  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-cap', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc Cap',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 10,
    'rebate_percent', 100,
    'product_ids', jsonb_build_array(v_p_cap)
  ));
  v_prog_cap := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cap-a', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cap, 'unit_id', v_u_cap, 'unit_price_vnd', 100000,
      'program_id', v_prog_cap, 'lots', jsonb_build_array(jsonb_build_object('quantity', 10))
    ))
  ));

  -- Sell 95 -> on_hand 5, ledger_value 54.500
  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_cap, 'quantity_delta', -95, 'movement_kind', 'SALE')),
    v_owner_id
  );

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-cap', v_prog_cap, jsonb_build_object(
    'document_no', 'CK-CAP',
    'document_date', v_today,
    'amount_vnd', 1000000
  ));
  if (v_res->>'inventory_part_total')::bigint <> 54500 or (v_res->>'cogs_part_total')::bigint <> 945500 then
    raise exception 'FAIL: cap_by_ledger_value totals mismatch: %', v_res;
  end if;
  if not exists (
    select 1 from inventory.product_costs pc
    where pc.tenant_id = v_tenant_id and pc.product_id = v_p_cap and pc.ledger_value_vnd = 0
  ) then
    raise exception 'FAIL: cap_by_ledger_value ledger_value_vnd not 0';
  end if;

  -- =========================================================================
  -- CASE: record_recomputes_after_sale
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-recomp', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc Recomp',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 1000,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p_recomp)
  ));
  v_prog_recomp := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-recomp', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_recomp, 'unit_id', v_u_recomp, 'unit_price_vnd', 100000,
      'program_id', v_prog_recomp, 'lots', jsonb_build_array(jsonb_build_object('quantity', 1000))
    ))
  ));

  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_recomp, 'quantity_delta', -700, 'movement_kind', 'SALE')),
    v_owner_id
  );

  v_res := inventory.preview_supplier_rebate(v_tenant_id, v_prog_recomp, null);
  if (v_res->>'inventory_part_total')::bigint <> 1500000 then
    raise exception 'FAIL: record_recomputes_after_sale preview expected 1500000, got %', v_res;
  end if;

  perform inventory._post_movements(
    v_tenant_id, v_warehouse_id, 'TEST', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_recomp, 'quantity_delta', -100, 'movement_kind', 'SALE')),
    v_owner_id
  );

  v_res := inventory.record_supplier_rebate(v_tenant_id, 'reb-rec-recomp', v_prog_recomp, jsonb_build_object(
    'document_no', 'CK-RECOMP',
    'document_date', v_today,
    'amount_vnd', 5000000
  ));
  if (v_res->>'inventory_part_total')::bigint <> 1000000 then
    raise exception 'FAIL: record_recomputes_after_sale expected 1000000, got %', v_res;
  end if;

  -- =========================================================================
  -- CASE: preview_errors, record_validation, period_closed
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-active', jsonb_build_object(
    'supplier_id', v_sup_c,
    'name', 'Mốc Active',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 500,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p_active)
  ));
  v_prog_active := (v_res->>'program_id')::uuid;

  perform pg_temp.expect_err(
    format('select inventory.preview_supplier_rebate(%L::uuid, %L::uuid, null)', v_tenant_id, v_prog_active),
    'PROGRAM_NOT_REACHED', 'preview_errors active'
  );

  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-err', jsonb_build_object(
    'supplier_id', v_sup_a,
    'name', 'Mốc Err',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 100,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p_err)
  ));
  v_prog_err := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-err', jsonb_build_object(
    'supplier_id', v_sup_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_err, 'unit_id', v_u_err, 'unit_price_vnd', 100000,
      'program_id', v_prog_err, 'lots', jsonb_build_array(jsonb_build_object('quantity', 100))
    ))
  ));

  perform pg_temp.expect_err(
    format('select inventory.preview_supplier_rebate(%L::uuid, %L::uuid, 0)', v_tenant_id, v_prog_err),
    'REBATE_AMOUNT_INVALID', 'preview_errors amount 0'
  );
  perform pg_temp.expect_err(
    format('select inventory.preview_supplier_rebate(%L::uuid, %L::uuid, 10000001)', v_tenant_id, v_prog_err),
    'REBATE_AMOUNT_INVALID', 'preview_errors amount > base'
  );

  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-val-1', v_prog_err,
      jsonb_build_object('document_no', 'CK-ERR', 'document_date', v_today, 'amount_vnd', 400000, 'override_reason', '  ')::text
    ),
    'REBATE_REASON_REQUIRED', 'record_validation blank reason'
  );
  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-val-2', v_prog_err,
      jsonb_build_object('document_no', 'CK-ERR', 'document_date', v_today + 1, 'amount_vnd', 500000)::text
    ),
    'CONTEXT_INVALID', 'record_validation future date'
  );
  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-val-3', v_prog_err,
      jsonb_build_object('document_no', '', 'document_date', v_today, 'amount_vnd', 500000)::text
    ),
    'CONTEXT_INVALID', 'record_validation empty doc_no'
  );

  -- period_closed
  update inventory.cost_periods
  set status = 'CLOSED'
  where tenant_id = v_tenant_id
    and period_month = date_trunc('month', v_today)::date;

  perform pg_temp.expect_err(
    format('select inventory.record_supplier_rebate(%L::uuid, %L, %L::uuid, %L::jsonb)',
      v_tenant_id, 'reb-val-closed', v_prog_err,
      jsonb_build_object('document_no', 'CK-CLOSED', 'document_date', v_today, 'amount_vnd', 500000)::text
    ),
    'PERIOD_CLOSED', 'period_closed'
  );

  update inventory.cost_periods
  set status = 'OPEN'
  where tenant_id = v_tenant_id
    and period_month = date_trunc('month', v_today)::date;

  if not exists (
    select 1 from inventory.supplier_programs sp
    where sp.id = v_prog_err and sp.status = 'REACHED'
  ) or exists (
    select 1 from inventory.supplier_rebates sr
    where sr.program_id = v_prog_err
  ) then
    raise exception 'FAIL: record_validation/period_closed mutated program or rebate';
  end if;

  -- =========================================================================
  -- CASE: projected_reach
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-proj', jsonb_build_object(
    'supplier_id', v_sup_b,
    'name', 'Mốc Proj 1.000 hộp',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 1000,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p_proj)
  ));
  v_prog_proj := (v_res->>'program_id')::uuid;

  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-proj', jsonb_build_object(
    'supplier_id', v_sup_b,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_proj, 'unit_id', v_u_proj, 'unit_price_vnd', 100000,
      'program_id', v_prog_proj, 'lots', jsonb_build_array(jsonb_build_object('quantity', 400))
    ))
  ));

  select count(*) into v_vm_count_before from inventory.value_movements where tenant_id = v_tenant_id;

  -- x = 600, u = 100.000 -> reaches_target true, rebate_estimate 5.000.000, avg_projected 95.000
  v_res := inventory.get_projected_cost(v_tenant_id, v_prog_proj, v_p_proj, 600, 100000);
  if (v_res->>'reaches_target')::boolean is not true
     or (v_res->>'missing_qty')::numeric <> 0
     or (v_res->>'rebate_estimate')::bigint <> 5000000
     or (v_res->>'avg_now')::numeric <> 100000
     or (v_res->>'avg_projected')::numeric <> 95000
     or (v_res->>'default_unit_price')::bigint <> 100000
     or (v_res->>'financial_masked')::boolean is not false then
    raise exception 'FAIL: projected_reach x=600 mismatch: %', v_res;
  end if;

  -- x = 500, u = 100.000 -> reaches_target false, missing_qty 100, rebate_estimate null, avg_projected 100.000
  v_res := inventory.get_projected_cost(v_tenant_id, v_prog_proj, v_p_proj, 500, 100000);
  if (v_res->>'reaches_target')::boolean is not false
     or (v_res->>'missing_qty')::numeric <> 100
     or (v_res->>'rebate_estimate') is not null
     or (v_res->>'avg_projected')::numeric <> 100000
     or (v_res->>'default_unit_price')::bigint <> 100000 then
    raise exception 'FAIL: projected_reach x=500 mismatch: %', v_res;
  end if;

  -- x = null, u = null -> reaches_target null, rebate_estimate null, avg_projected null, default_unit_price 100.000
  v_res := inventory.get_projected_cost(v_tenant_id, v_prog_proj, v_p_proj, null, null);
  if (v_res->>'reaches_target') is not null
     or (v_res->>'missing_qty')::numeric <> 600
     or (v_res->>'rebate_estimate') is not null
     or (v_res->>'avg_projected') is not null
     or (v_res->>'default_unit_price')::bigint <> 100000 then
    raise exception 'FAIL: projected_reach x=null mismatch: %', v_res;
  end if;

  -- Validation errors
  perform pg_temp.expect_err(
    format('select inventory.get_projected_cost(%L::uuid, %L::uuid, %L::uuid, 0, 100000)', v_tenant_id, v_prog_proj, v_p_proj),
    'CONTEXT_INVALID', 'projected_reach x=0'
  );
  perform pg_temp.expect_err(
    format('select inventory.get_projected_cost(%L::uuid, %L::uuid, %L::uuid, 10, -1)', v_tenant_id, v_prog_proj, v_p_proj),
    'CONTEXT_INVALID', 'projected_reach u=-1'
  );
  perform pg_temp.expect_err(
    format('select inventory.get_projected_cost(%L::uuid, %L::uuid, %L::uuid, 10, 100000)', v_tenant_id, v_prog_err, v_p_err),
    'CONTEXT_INVALID', 'projected_reach not active'
  );

  select count(*) into v_vm_count_after from inventory.value_movements where tenant_id = v_tenant_id;
  if v_vm_count_after <> v_vm_count_before then
    raise exception 'FAIL: projected_reach modified value_movements';
  end if;

  -- =========================================================================
  -- CASE: compare_rows
  -- =========================================================================
  v_res := inventory.create_supplier_program(v_tenant_id, 'reb-prog-cmp', jsonb_build_object(
    'supplier_id', v_sup_cmp_a,
    'name', 'CT So Sánh SP',
    'kind', 'VOLUME_REBATE',
    'started_on', v_today - 5,
    'target_qty', 2000,
    'rebate_percent', 5,
    'product_ids', jsonb_build_array(v_p_cmp)
  ));
  v_prog_cmp := (v_res->>'program_id')::uuid;

  -- NCC So Sánh A: 500 x 95.000 + 500 x 99.400 -> avg 97.200, last 99.400, receipt_count 2, program present
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cmp-a1', jsonb_build_object(
    'supplier_id', v_sup_cmp_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cmp, 'unit_id', v_u_cmp, 'unit_price_vnd', 95000,
      'program_id', v_prog_cmp, 'lots', jsonb_build_array(jsonb_build_object('quantity', 500))
    ))
  ));
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cmp-a2', jsonb_build_object(
    'supplier_id', v_sup_cmp_a,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cmp, 'unit_id', v_u_cmp, 'unit_price_vnd', 99400,
      'program_id', v_prog_cmp, 'lots', jsonb_build_array(jsonb_build_object('quantity', 500))
    ))
  ));

  -- NCC B: 1 receipt, 10 paid + 1 free -> free_qty = 1 > 0, plus other_program = v_prog_proj (not containing v_p_cmp)
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cmp-b', jsonb_build_object(
    'supplier_id', v_sup_b,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cmp, 'unit_id', v_u_cmp, 'unit_price_vnd', 110000,
      'free_qty', 1, 'lots', jsonb_build_array(jsonb_build_object('quantity', 11))
    ))
  ));

  -- Walk-in ("Mua lẻ / khác"): 1 receipt x 90.000 (lower price, still MUST be last because is_system = true)
  perform inventory.record_goods_receipt(v_tenant_id, 'reb-gr-cmp-walkin', jsonb_build_object(
    'supplier_id', v_walkin_id,
    'lines', jsonb_build_array(jsonb_build_object(
      'product_id', v_p_cmp, 'unit_id', v_u_cmp, 'unit_price_vnd', 90000,
      'lots', jsonb_build_array(jsonb_build_object('quantity', 5))
    ))
  ));

  v_res := inventory.compare_suppliers(v_tenant_id, v_p_cmp);
  if (v_res->'product'->>'product_id')::uuid <> v_p_cmp
     or (v_res->'product'->>'code') <> 'RB-CMP'
     or (v_res->'product'->>'uom') <> 'hộp'
     or (v_res->>'financial_masked')::boolean is not false then
    raise exception 'FAIL: compare_rows header mismatch: %', v_res;
  end if;

  v_cmp_count := jsonb_array_length(v_res->'suppliers');
  if v_cmp_count <> 3 then
    raise exception 'FAIL: compare_rows expected 3 suppliers, got %', v_res->'suppliers';
  end if;

  -- Row 0: NCC So Sánh A
  v_sup_row := (v_res->'suppliers')->0;
  if (v_sup_row->>'partner_id')::uuid <> v_sup_cmp_a
     or (v_sup_row->>'is_system')::boolean is not false
     or (v_sup_row->>'avg_landed_unit_cost')::numeric <> 97200
     or (v_sup_row->>'last_landed_unit_cost')::numeric <> 99400
     or (v_sup_row->>'receipt_count')::int <> 2
     or (v_sup_row->>'paid_qty')::numeric <> 1000
     or (v_sup_row->>'free_qty')::numeric <> 0
     or (v_sup_row->'program'->>'program_id')::uuid <> v_prog_cmp
     or (v_sup_row->>'other_program') is not null then
    raise exception 'FAIL: compare_rows row 0 (NCC So Sánh A) mismatch: %', v_sup_row;
  end if;

  -- Row 1: NCC B (free_qty = 1 > 0, other_program = v_prog_proj)
  v_sup_row := (v_res->'suppliers')->1;
  if (v_sup_row->>'partner_id')::uuid <> v_sup_b
     or (v_sup_row->>'free_qty')::numeric <> 1
     or (v_sup_row->>'program') is not null
     or (v_sup_row->'other_program'->>'program_id')::uuid <> v_prog_proj then
    raise exception 'FAIL: compare_rows row 1 (NCC B) mismatch: %', v_sup_row;
  end if;

  -- Row 2 (last): Mua lẻ / khác (is_system true, program & other_program null)
  v_sup_row := (v_res->'suppliers')->2;
  if (v_sup_row->>'partner_id')::uuid <> v_walkin_id
     or (v_sup_row->>'is_system')::boolean is not true
     or (v_sup_row->>'program') is not null
     or (v_sup_row->>'other_program') is not null then
    raise exception 'FAIL: compare_rows last row (walk-in) mismatch: %', v_sup_row;
  end if;

  -- =========================================================================
  -- CASE: staff_masked_projection_compare
  -- =========================================================================
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff_id::text, true);

  v_res := inventory.get_projected_cost(v_tenant_id, v_prog_proj, v_p_proj, 600, 100000);
  if (v_res->>'financial_masked')::boolean is not true
     or (v_res->>'reaches_target')::boolean is not true
     or (v_res->>'avg_now') is not null
     or (v_res->>'avg_projected') is not null
     or (v_res->>'rebate_estimate') is not null
     or (v_res->>'default_unit_price') is not null then
    raise exception 'FAIL: staff_masked_projection_compare projected not masked: %', v_res;
  end if;

  v_res := inventory.compare_suppliers(v_tenant_id, v_p_cmp);
  if (v_res->>'financial_masked')::boolean is not true then
    raise exception 'FAIL: staff_masked_projection_compare compare not masked: %', v_res;
  end if;
  for v_sup_row in select * from jsonb_array_elements(v_res->'suppliers')
  loop
    if (v_sup_row->>'last_landed_unit_cost') is not null
       or (v_sup_row->>'avg_landed_unit_cost') is not null then
      raise exception 'FAIL: staff_masked_projection_compare cost exposed: %', v_sup_row;
    end if;
  end loop;

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  -- =========================================================================
  -- INVARIANTS across tenant
  -- =========================================================================
  select count(*) into v_bad_mismatch
  from inventory.product_costs pc
  where pc.tenant_id = v_tenant_id
    and pc.ledger_value_vnd <> coalesce((
      select sum(vm.amount_vnd)::bigint
      from inventory.value_movements vm
      where vm.tenant_id = v_tenant_id and vm.product_id = pc.product_id
    ), 0);
  if v_bad_mismatch > 0 then
    raise exception 'FAIL: ledger_value_vnd invariant broken (% rows)', v_bad_mismatch;
  end if;

  select count(*) into v_bad_rebate_sum
  from inventory.supplier_rebates sr
  where sr.tenant_id = v_tenant_id
    and sr.rebate_amount_vnd <> coalesce((
      select sum(sra.rebate_part_vnd)::bigint
      from inventory.supplier_rebate_allocations sra
      where sra.rebate_id = sr.id
    ), 0);
  if v_bad_rebate_sum > 0 then
    raise exception 'FAIL: allocation sum invariant broken (% rows)', v_bad_rebate_sum;
  end if;

  -- =========================================================================
  -- CONTRACT: record_goods_receipt checks program status after FOR UPDATE lock
  -- =========================================================================
  if position(
    'not in (''ACTIVE'', ''REACHED'')' in pg_get_functiondef('inventory.record_goods_receipt(uuid, text, jsonb)'::regprocedure)
  ) = 0 then
    raise exception 'FAIL: record_goods_receipt missing post-lock status check for VOLUME_REBATE';
  end if;

  raise notice 'inventory_supplier_rebates: Task 1 & Task 2 cases passed';
end;
$$;

