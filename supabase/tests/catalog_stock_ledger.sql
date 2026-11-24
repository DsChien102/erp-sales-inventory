-- Test suite for Task 8: Catalog reads stock from Inventory ledger, basic stock dropped (T7-G5-5)
-- Run via: psql -v ON_ERROR_STOP=1 -f supabase/tests/catalog_stock_ledger.sql

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
  v_today date := inventory._today();

  v_p_a uuid := gen_random_uuid();
  v_p_b uuid;
  v_p_c uuid;
  v_p_null uuid;
  v_res jsonb;

  v_a_search record;
  v_b_search record;
  v_in_stock_count int;
  v_out_stock_count int;
  v_barcode_rec record;
  v_readiness_rec record;
  v_b_ready boolean;
  v_b_blockers jsonb;
  v_summary jsonb;
  v_issues jsonb;
  v_warnings jsonb;
begin
  -- 1. Fixture (khuôn inventory_goods_receipts.sql) --------------------------
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  ) values (
    v_owner_id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'owner-csl-' || substr(v_owner_id::text, 1, 8) || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  insert into iam.tenants (id, display_name) values (v_tenant_id, 'Catalog Ledger Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_tenant_id, v_owner_id, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store_id, v_tenant_id, 'CSL01', 'Cửa hàng CSL', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_warehouse_id, v_tenant_id, 'Kho chính CSL', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_tenant_id, v_store_id, v_warehouse_id, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner_id::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner_id::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by)
  values (v_tenant_id, 'MOVING', v_owner_id)
  on conflict (tenant_id) do nothing;

  -- Product A: có 5 lô còn hạn + 2 lô hết hạn qua RECEIPT
  insert into catalog.products (
    id, tenant_id, name, sku, barcode, tracking_mode, expiry_required,
    business_status, reference_id, created_by, updated_by
  ) values (
    v_p_a, v_tenant_id, 'Sản phẩm A', 'SP-CSL-A', '8938880001',
    'lot', true, 'active', 'REF-CSL-A', v_owner_id, v_owner_id
  );
  insert into catalog.product_units (tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values (v_tenant_id, v_p_a, 'lọ', 1, true);

  perform inventory._post_movements(
    v_tenant_id,
    v_warehouse_id,
    'GOODS_RECEIPT',
    gen_random_uuid(),
    v_today,
    jsonb_build_array(
      jsonb_build_object(
        'product_id', v_p_a,
        'lot_code', 'LOT-GOOD',
        'expiry_date', v_today + 60,
        'expiry_precision', 'DAY',
        'quantity_delta', 5,
        'movement_kind', 'RECEIPT',
        'unit_cost', 20000,
        'amount_vnd', 100000
      ),
      jsonb_build_object(
        'product_id', v_p_a,
        'lot_code', 'LOT-EXP',
        'expiry_date', v_today - 2,
        'expiry_precision', 'DAY',
        'quantity_delta', 2,
        'movement_kind', 'RECEIPT',
        'unit_cost', 20000,
        'amount_vnd', 40000
      )
    ),
    v_owner_id
  );

  -- Product B: chưa nhập kho, có ĐVT + giá bán hợp lệ (manual)
  v_res := catalog.create_guided_product(
    p_tenant_id => v_tenant_id,
    p_actor_id => v_owner_id,
    p_name => 'Sản phẩm B',
    p_reference_id => 'REF-CSL-B',
    p_sku => 'SP-CSL-B',
    p_barcode => '8938880002',
    p_new_unit_name => 'hộp',
    p_basic_stock_quantity_base => null,
    p_base_price_after_vat => 50000,
    p_list_price_before_vat => 70000,
    p_floor_price_before_vat => 60000,
    p_price_band_source_type => 'manual'
  );
  v_p_b := (v_res->>'product_id')::uuid;

  -- =========================================================================
  -- 1. search_stock_from_ledger
  -- =========================================================================
  select * into v_a_search
  from catalog.search_products(
    p_tenant_id => v_tenant_id,
    p_keyword => 'SP-CSL-A'::text,
    p_sort_order => 'updated_at_desc'::text
  )
  where product_id = v_p_a;

  if v_a_search.stock_qty <> 5 or v_a_search.has_stock is distinct from true or v_a_search.stock_mode <> 'advanced' then
    raise exception 'FAIL: search_stock_from_ledger A expected (qty=5, has_stock=true, mode=advanced), got (%, %, %)',
      v_a_search.stock_qty, v_a_search.has_stock, v_a_search.stock_mode;
  end if;

  select * into v_b_search
  from catalog.search_products(
    p_tenant_id => v_tenant_id,
    p_keyword => 'SP-CSL-B'::text,
    p_sort_order => 'updated_at_desc'::text
  )
  where product_id = v_p_b;

  if v_b_search.stock_qty <> 0 or v_b_search.has_stock is distinct from false or v_b_search.stock_mode <> 'advanced' then
    raise exception 'FAIL: search_stock_from_ledger B expected (qty=0, has_stock=false, mode=advanced), got (%, %, %)',
      v_b_search.stock_qty, v_b_search.has_stock, v_b_search.stock_mode;
  end if;

  select
    count(*) filter (where coalesce(stock_qty, 0) > 0)::int,
    count(*) filter (where coalesce(stock_qty, 0) = 0)::int
  into v_in_stock_count, v_out_stock_count
  from catalog.search_products(
    p_tenant_id => v_tenant_id,
    p_sort_order => 'updated_at_desc'::text
  );

  if v_in_stock_count <> 1 or v_out_stock_count <> 1 then
    raise exception 'FAIL: search_stock_from_ledger in/out counts expected (1, 1), got (%, %)',
      v_in_stock_count, v_out_stock_count;
  end if;

  -- =========================================================================
  -- 2. pcc_stock_from_ledger
  -- =========================================================================
  v_res := catalog.get_product_control_center(v_tenant_id, v_p_a);
  if (v_res->>'stock_qty')::numeric <> 7
     or (v_res->'stock_version') is distinct from 'null'::jsonb
     or (v_res->>'stock_mode') <> 'advanced'
     or (v_res->>'has_stock')::boolean is distinct from true then
    raise exception 'FAIL: pcc_stock_from_ledger PCC(A) got %', v_res;
  end if;

  select * into v_barcode_rec
  from catalog.find_product_by_barcode(v_tenant_id, '8938880001');
  if v_barcode_rec.stock_qty <> 7
     or v_barcode_rec.has_stock is distinct from true
     or v_barcode_rec.stock_mode <> 'advanced' then
    raise exception 'FAIL: pcc_stock_from_ledger barcode(A) expected (7, true, advanced), got (%, %, %)',
      v_barcode_rec.stock_qty, v_barcode_rec.has_stock, v_barcode_rec.stock_mode;
  end if;

  -- =========================================================================
  -- 3. readiness_without_stock
  -- =========================================================================
  select p.is_ready_to_sell into v_b_ready
  from catalog.products p
  where p.id = v_p_b and p.tenant_id = v_tenant_id;

  if v_b_ready is distinct from true then
    raise exception 'FAIL: readiness_without_stock B expected is_ready_to_sell=true, got %', v_b_ready;
  end if;

  select * into v_readiness_rec
  from catalog.get_product_readiness(v_tenant_id, v_p_b);

  if v_readiness_rec.has_stock is distinct from false
     or v_readiness_rec.stock_mode <> 'advanced' then
    raise exception 'FAIL: readiness_without_stock get_product_readiness(B) got (has_stock=%, stock_mode=%)',
      v_readiness_rec.has_stock, v_readiness_rec.stock_mode;
  end if;

  select pr.blockers into v_b_blockers
  from catalog.product_readiness pr
  where pr.product_id = v_p_b and pr.tenant_id = v_tenant_id;

  v_summary := catalog._product_readiness_summary_json(v_tenant_id, v_p_b);
  if exists (
    select 1 from jsonb_array_elements(coalesce(v_b_blockers, '[]'::jsonb) || coalesce(v_summary->'blockers', '[]'::jsonb)) elem
    where elem->>'code' in ('missing_stock', 'pending_stock_from_inventory')
  ) then
    raise exception 'FAIL: readiness_without_stock blockers still contain stock codes: readiness=% summary=%',
      v_b_blockers, v_summary;
  end if;

  -- set_product_base_unit on a fresh product without base unit must succeed
  v_res := catalog.create_guided_product(
    p_tenant_id => v_tenant_id,
    p_actor_id => v_owner_id,
    p_name => 'Sản phẩm C',
    p_reference_id => 'REF-CSL-C'
  );
  v_p_c := (v_res->>'product_id')::uuid;
  perform catalog.set_product_base_unit(
    p_tenant_id => v_tenant_id,
    p_product_id => v_p_c,
    p_new_unit_name => 'chai'
  );

  -- =========================================================================
  -- 4. guided_create_rejects_stock
  -- =========================================================================
  perform pg_temp.expect_err(
    format(
      'select catalog.create_guided_product(%L, %L, %L, %L, p_basic_stock_quantity_base => 3)',
      v_tenant_id, v_owner_id, 'SP Tu Choi Ton', 'REF-CSL-REJECT'
    ),
    'validation_exception: basic stock removed',
    'guided_create_rejects_stock'
  );

  v_res := catalog.create_guided_product(
    p_tenant_id => v_tenant_id,
    p_actor_id => v_owner_id,
    p_name => 'SP Cho Phep Null',
    p_reference_id => 'REF-CSL-NULL',
    p_basic_stock_quantity_base => null
  );
  v_p_null := (v_res->>'product_id')::uuid;
  if v_p_null is null then
    raise exception 'FAIL: guided_create_rejects_stock null case returned null product_id';
  end if;

  -- =========================================================================
  -- 5. deletion_issue_from_ledger
  -- =========================================================================
  v_issues := catalog._product_deletion_issues(v_tenant_id, v_p_a);
  if not exists (
    select 1 from jsonb_array_elements(v_issues) elem
    where elem->>'code' = 'has_stock'
  ) then
    raise exception 'FAIL: deletion_issue_from_ledger A missing has_stock: %', v_issues;
  end if;

  v_issues := catalog._product_deletion_issues(v_tenant_id, v_p_b);
  if exists (
    select 1 from jsonb_array_elements(v_issues) elem
    where elem->>'code' = 'has_stock'
  ) then
    raise exception 'FAIL: deletion_issue_from_ledger B should not have has_stock: %', v_issues;
  end if;

  v_warnings := catalog._product_business_status_warnings(v_tenant_id, v_p_a);
  if not exists (
    select 1 from jsonb_array_elements(v_warnings) elem
    where elem->>'code' = 'has_stock'
  ) then
    raise exception 'FAIL: deletion_issue_from_ledger warnings A missing has_stock: %', v_warnings;
  end if;

  -- =========================================================================
  -- 6. tables_dropped
  -- =========================================================================
  if to_regclass('catalog.product_stock_profiles') is not null then
    raise exception 'FAIL: tables_dropped product_stock_profiles still exists';
  end if;
  if to_regclass('catalog.product_stock_movements') is not null then
    raise exception 'FAIL: tables_dropped product_stock_movements still exists';
  end if;
  if to_regprocedure('catalog.set_basic_stock_quantity_base(uuid,uuid,text,numeric)') is not null then
    raise exception 'FAIL: tables_dropped set_basic_stock_quantity_base still exists';
  end if;
  if to_regprocedure('catalog.adjust_basic_stock(uuid,uuid,numeric,text,numeric)') is not null then
    raise exception 'FAIL: tables_dropped adjust_basic_stock still exists';
  end if;
  if to_regprocedure('catalog.get_product_stock_history(uuid,uuid,integer)') is not null then
    raise exception 'FAIL: tables_dropped get_product_stock_history still exists';
  end if;

  raise notice 'ALL CATALOG STOCK LEDGER SQL TESTS PASSED!';
end;
$$;

