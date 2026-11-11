-- Test suite for inventory_supplier_programs (T7-G5-2b)
-- Run via: psql -f supabase/tests/inventory_supplier_programs.sql
-- Requires Task 2 of G5-2b (partners.is_system, organization_profiles.allow_blank_phone).

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
  v_sup_cust uuid := gen_random_uuid();
  v_sup_off uuid := gen_random_uuid();
  v_walk_in uuid;

  v_p_hop uuid := gen_random_uuid();
  v_p_hop2 uuid := gen_random_uuid();
  v_p_chai uuid := gen_random_uuid();

  v_res jsonb;
  v_prog_id uuid;
  v_prog2_id uuid;
  v_rev int;
  v_list jsonb;
  v_row jsonb;
  v_hint jsonb;
  v_cnt int;
  v_today date := inventory._today();
begin
  -- Setup -------------------------------------------------------------------
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Supplier Program Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_tenant_id, v_owner_id, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'ST01', 'Kho CH', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho tổng', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  insert into catalog.products (id, tenant_id, name, sku, reference_id, created_by, updated_by)
  values
    (v_p_hop, v_tenant_id, 'Nobivac DHPPi', 'NOBI', 'SP-NOBI', v_owner_id, v_owner_id),
    (v_p_hop2, v_tenant_id, 'Nobivac Rabies', 'RABI', 'SP-RABI', v_owner_id, v_owner_id),
    (v_p_chai, v_tenant_id, 'Tylosin chai', 'TYLO', 'SP-TYLO', v_owner_id, v_owner_id);
  insert into catalog.product_units (tenant_id, product_id, unit_name, is_base_unit, conversion_rate_to_base)
  values
    (v_tenant_id, v_p_hop, 'hộp', true, 1),
    (v_tenant_id, v_p_hop2, 'hộp', true, 1),
    (v_tenant_id, v_p_chai, 'chai', true, 1);

  insert into partner.partners (partner_id, tenant_id, partner_type, status, display_name, created_by, updated_by)
  values
    (v_sup_a, v_tenant_id, 'organization', 'active', 'NCC A', v_owner_id, v_owner_id),
    (v_sup_b, v_tenant_id, 'organization', 'active', 'NCC B', v_owner_id, v_owner_id),
    (v_sup_cust, v_tenant_id, 'organization', 'active', 'Chỉ khách', v_owner_id, v_owner_id),
    (v_sup_off, v_tenant_id, 'organization', 'inactive', 'NCC ngừng', v_owner_id, v_owner_id);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values
    (v_sup_a, v_tenant_id, 'supplier'),
    (v_sup_b, v_tenant_id, 'supplier'),
    (v_sup_cust, v_tenant_id, 'customer'),
    (v_sup_off, v_tenant_id, 'supplier');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  v_walk_in := inventory._ensure_walk_in_supplier(v_tenant_id);

  -- create_tier_program_ok --------------------------------------------------
  v_res := inventory.create_supplier_program(v_tenant_id, 'k-create-1', jsonb_build_object(
    'supplier_id', v_sup_a, 'kind', 'TIER_DISCOUNT', 'name', 'Nobivac bậc SL',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
    'tiers', jsonb_build_array(
      jsonb_build_object('min_qty', 100, 'discount_percent', 3),
      jsonb_build_object('min_qty', 300, 'discount_percent', 5))));
  v_prog_id := (v_res->>'program_id')::uuid;
  if (v_res->>'revision')::int <> 1 then
    raise exception 'FAIL: create_tier_program_ok: revision';
  end if;
  v_list := inventory.list_supplier_programs(v_tenant_id);
  v_row := v_list->'programs'->0;
  if v_row->>'common_uom' is distinct from 'hộp'
     or (v_row->'tiers'->0->>'min_qty')::numeric <> 100
     or (v_row->'tiers'->1->>'min_qty')::numeric <> 300 then
    raise exception 'FAIL: create_tier_program_ok: list row %', v_row;
  end if;

  -- create_idempotent_replay ------------------------------------------------
  v_res := inventory.create_supplier_program(v_tenant_id, 'k-create-1', jsonb_build_object(
    'supplier_id', v_sup_a, 'kind', 'TIER_DISCOUNT', 'name', 'Nobivac bậc SL',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
    'tiers', jsonb_build_array(
      jsonb_build_object('min_qty', 100, 'discount_percent', 3),
      jsonb_build_object('min_qty', 300, 'discount_percent', 5))));
  select count(*) into v_cnt from inventory.supplier_programs where tenant_id = v_tenant_id;
  if (v_res->>'program_id')::uuid <> v_prog_id or v_cnt <> 1 then
    raise exception 'FAIL: create_idempotent_replay';
  end if;

  -- hints_case12 (spec gia von ca 12) ---------------------------------------
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_a, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 300, 'unit_price', 100000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 280, 'unit_price', 100000)));
  if (v_hint->'lines'->0->'hint'->'tier'->>'discount_percent')::numeric <> 5
     or (v_hint->'lines'->0->'hint'->'tier'->>'discount_vnd')::bigint <> 1500000
     or (v_hint->'lines'->0->'hint'->'next_tier') <> 'null'::jsonb then
    raise exception 'FAIL: hints_case12: paid 300 got %', v_hint->'lines'->0;
  end if;
  if (v_hint->'lines'->1->'hint'->'tier'->>'discount_percent')::numeric <> 3
     or (v_hint->'lines'->1->'hint'->'tier'->>'discount_vnd')::bigint <> 840000
     or (v_hint->'lines'->1->'hint'->'next_tier'->>'missing_qty')::numeric <> 20 then
    raise exception 'FAIL: hints_case12: paid 280 got %', v_hint->'lines'->1;
  end if;

  -- hints_tier_boundaries ---------------------------------------------------
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_a, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 100, 'unit_price', 1000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 500, 'unit_price', 1000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 50, 'unit_price', 1000)));
  if (v_hint->'lines'->0->'hint'->'tier'->>'discount_percent')::numeric <> 3 then
    raise exception 'FAIL: hints_tier_boundaries: paid 100';
  end if;
  if (v_hint->'lines'->1->'hint'->'tier'->>'discount_percent')::numeric <> 5
     or (v_hint->'lines'->1->'hint'->'next_tier') <> 'null'::jsonb then
    raise exception 'FAIL: hints_tier_boundaries: paid 500';
  end if;
  if (v_hint->'lines'->2->'hint'->'tier') <> 'null'::jsonb
     or (v_hint->'lines'->2->'hint'->'next_tier'->>'missing_qty')::numeric <> 50 then
    raise exception 'FAIL: hints_tier_boundaries: paid 50';
  end if;

  -- hints_other_supplier_null ----------------------------------------------
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_b, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 300, 'unit_price', 1000)));
  if v_hint->'lines'->0->'hint' <> 'null'::jsonb then
    raise exception 'FAIL: hints_other_supplier_null';
  end if;

  -- overlap_blocked_second_insert -------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-ov-1', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_a, 'kind', 'VOLUME_REBATE', 'name', 'Mốc',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
      'target_qty', 1000, 'rebate_percent', 5)::text),
    'PROGRAM_OVERLAP', 'overlap_blocked_second_insert');

  -- form_options_active_program ---------------------------------------------
  v_res := inventory.get_supplier_program_form_options(v_tenant_id);
  select e into v_row from jsonb_array_elements(v_res->'suppliers') e
  where e->>'partner_id' = v_sup_a::text;
  if v_row->'active_program'->>'program_id' <> v_prog_id::text then
    raise exception 'FAIL: form_options_active_program';
  end if;

  -- form_options_excludes_system_and_inactive -------------------------------
  select count(*) into v_cnt from jsonb_array_elements(v_res->'suppliers') e
  where e->>'partner_id' in (v_walk_in::text, v_sup_off::text, v_sup_cust::text);
  if v_cnt <> 0 then
    raise exception 'FAIL: form_options_excludes_system_and_inactive';
  end if;

  -- update_stale_revision_conflict ------------------------------------------
  v_res := inventory.update_supplier_program(v_tenant_id, 'k-upd-1', v_prog_id, 1, jsonb_build_object(
    'name', 'Nobivac bậc SL v2', 'started_on', v_today,
    'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
    'tiers', jsonb_build_array(
      jsonb_build_object('min_qty', 100, 'discount_percent', 3),
      jsonb_build_object('min_qty', 300, 'discount_percent', 5))));
  v_rev := (v_res->>'revision')::int;
  if v_rev <> 2 then
    raise exception 'FAIL: update revision expected 2, got %', v_rev;
  end if;
  perform pg_temp.expect_err(format(
    $q$select inventory.update_supplier_program(%L, 'k-upd-2', %L, 1, %L::jsonb)$q$,
    v_tenant_id, v_prog_id,
    jsonb_build_object('name', 'x', 'product_ids', jsonb_build_array(v_p_hop),
      'tiers', jsonb_build_array(jsonb_build_object('min_qty', 1, 'discount_percent', 1)))::text),
    'VERSION_CONFLICT', 'update_stale_revision_conflict');

  -- update_cannot_change_kind -----------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.update_supplier_program(%L, 'k-upd-3', %L, 2, %L::jsonb)$q$,
    v_tenant_id, v_prog_id,
    jsonb_build_object('kind', 'BUY_X_GET_Y', 'name', 'x', 'buy_qty', 10, 'free_qty', 1,
      'product_ids', jsonb_build_array(v_p_hop))::text),
    'CONTEXT_INVALID', 'update_cannot_change_kind');

  -- update_locked_after_receipt ---------------------------------------------
  insert into inventory.supplier_program_receipts (tenant_id, program_id, receipt_line_id, paid_qty, purchase_amount_vnd)
  values (v_tenant_id, v_prog_id, gen_random_uuid(), 10, 1000000);
  perform pg_temp.expect_err(format(
    $q$select inventory.update_supplier_program(%L, 'k-upd-4', %L, 2, %L::jsonb)$q$,
    v_tenant_id, v_prog_id,
    jsonb_build_object('name', 'x', 'product_ids', jsonb_build_array(v_p_hop),
      'tiers', jsonb_build_array(jsonb_build_object('min_qty', 1, 'discount_percent', 1)))::text),
    'PROGRAM_LOCKED', 'update_locked_after_receipt');

  -- end_twice_locked + overlap released after end ---------------------------
  v_res := inventory.end_supplier_program(v_tenant_id, 'k-end-1', v_prog_id, 2);
  if v_res->>'status' <> 'ENDED' then
    raise exception 'FAIL: end_supplier_program status';
  end if;
  perform pg_temp.expect_err(format(
    $q$select inventory.end_supplier_program(%L, 'k-end-2', %L, 3)$q$, v_tenant_id, v_prog_id),
    'PROGRAM_LOCKED', 'end_twice_locked');

  v_res := inventory.create_supplier_program(v_tenant_id, 'k-vol-1', jsonb_build_object(
    'supplier_id', v_sup_a, 'kind', 'VOLUME_REBATE', 'name', 'Mốc 1000',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
    'target_qty', 1000, 'rebate_percent', 5));
  v_prog2_id := (v_res->>'program_id')::uuid;

  -- hints_volume_rebate -----------------------------------------------------
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_a, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 1000, 'unit_price', 1000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 999, 'unit_price', 1000)));
  if (v_hint->'lines'->0->'hint'->'rebate'->>'would_reach')::boolean is not true
     or (v_hint->'lines'->1->'hint'->'rebate'->>'would_reach')::boolean is not false then
    raise exception 'FAIL: hints_volume_rebate';
  end if;

  -- hints_not_started_null --------------------------------------------------
  update inventory.supplier_programs set started_on = v_today + 1 where id = v_prog2_id;
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_a, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 1000, 'unit_price', 1000)));
  if v_hint->'lines'->0->'hint' <> 'null'::jsonb then
    raise exception 'FAIL: hints_not_started_null';
  end if;
  perform inventory.end_supplier_program(v_tenant_id, 'k-end-3', v_prog2_id, 1);

  -- uom_mismatch_volume -----------------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-uom-1', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_b, 'kind', 'VOLUME_REBATE', 'name', 'Lệch ĐVT',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_chai),
      'target_qty', 100, 'rebate_percent', 2)::text),
    'PROGRAM_UOM_MISMATCH', 'uom_mismatch_volume');
  v_res := inventory.create_supplier_program(v_tenant_id, 'k-uom-vol-ok', jsonb_build_object(
    'supplier_id', v_sup_b, 'kind', 'VOLUME_REBATE', 'name', 'Cùng ĐVT hộp hai SP',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
    'target_qty', 100, 'rebate_percent', 2));
  perform inventory.end_supplier_program(v_tenant_id, 'k-end-vol-ok', (v_res->>'program_id')::uuid, 1);
  v_res := inventory.create_supplier_program(v_tenant_id, 'k-uom-2', jsonb_build_object(
    'supplier_id', v_sup_b, 'kind', 'TIER_DISCOUNT', 'name', 'Bậc hai ĐVT',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_chai),
    'tiers', jsonb_build_array(jsonb_build_object('min_qty', 10, 'discount_percent', 1))));
  perform inventory.end_supplier_program(v_tenant_id, 'k-end-4', (v_res->>'program_id')::uuid, 1);

  -- walk_in_supplier_rejected -----------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-walk-1', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_walk_in, 'kind', 'BUY_X_GET_Y', 'name', 'Mua lẻ',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
      'buy_qty', 10, 'free_qty', 1)::text),
    'PROGRAM_SUPPLIER_INVALID', 'walk_in_supplier_rejected');
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-walk-2', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_cust, 'kind', 'BUY_X_GET_Y', 'name', 'Chỉ khách',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
      'buy_qty', 10, 'free_qty', 1)::text),
    'PROGRAM_SUPPLIER_INVALID', 'walk_in_supplier_rejected (customer only)');

  -- buy_x_get_y_single_product ----------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-bxy-1', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_b, 'kind', 'BUY_X_GET_Y', 'name', 'Hai SP',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop, v_p_hop2),
      'buy_qty', 10, 'free_qty', 1)::text),
    'CONTEXT_INVALID', 'buy_x_get_y_single_product');

  -- hints_buy_x_get_y (ca 13) -----------------------------------------------
  v_res := inventory.create_supplier_program(v_tenant_id, 'k-bxy-2', jsonb_build_object(
    'supplier_id', v_sup_b, 'kind', 'BUY_X_GET_Y', 'name', 'Mua 10 tặng 1',
    'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
    'buy_qty', 10, 'free_qty', 1));
  v_hint := inventory.get_receipt_program_hints(v_tenant_id, v_sup_b, jsonb_build_array(
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 10, 'unit_price', 1000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 25, 'unit_price', 1000),
    jsonb_build_object('product_id', v_p_hop, 'paid_qty', 9, 'unit_price', 1000)));
  if (v_hint->'lines'->0->'hint'->>'suggested_free_qty')::numeric <> 1
     or (v_hint->'lines'->1->'hint'->>'suggested_free_qty')::numeric <> 2
     or (v_hint->'lines'->2->'hint'->>'suggested_free_qty')::numeric <> 0 then
    raise exception 'FAIL: hints_buy_x_get_y: %', v_hint;
  end if;
  perform inventory.end_supplier_program(v_tenant_id, 'k-end-5', (v_res->>'program_id')::uuid, 1);

  -- tiers_must_increase -----------------------------------------------------
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-tier-1', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_b, 'kind', 'TIER_DISCOUNT', 'name', 'Bậc ngược',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
      'tiers', jsonb_build_array(
        jsonb_build_object('min_qty', 300, 'discount_percent', 5),
        jsonb_build_object('min_qty', 100, 'discount_percent', 3)))::text),
    'CONTEXT_INVALID', 'tiers_must_increase (qty)');
  perform pg_temp.expect_err(format(
    $q$select inventory.create_supplier_program(%L, 'k-tier-2', %L::jsonb)$q$,
    v_tenant_id,
    jsonb_build_object('supplier_id', v_sup_b, 'kind', 'TIER_DISCOUNT', 'name', 'Giảm ngược',
      'started_on', v_today, 'product_ids', jsonb_build_array(v_p_hop),
      'tiers', jsonb_build_array(
        jsonb_build_object('min_qty', 100, 'discount_percent', 5),
        jsonb_build_object('min_qty', 300, 'discount_percent', 3)))::text),
    'CONTEXT_INVALID', 'tiers_must_increase (percent)');

  raise notice 'inventory_supplier_programs: all cases passed';
end;
$$;

