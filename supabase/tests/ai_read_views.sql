-- Test suite for ai_read views + ai.get_catalog (AI-4 Task 1)
-- Run via: tools/db_check.sh --no-reset ai_read_views
-- Cases: v_don_ban_scope, v_revenue_matches_sales_stats, v_orders_count_matches, v_cost_visible,
--        v_no_pii_columns, v_stock_and_movements, v_no_vars_no_rows, v_other_tenant_isolated,
--        v_direct_access_denied, v_catalog_complete

begin;


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

create or replace function pg_temp.rep_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create or replace function pg_temp.rep_pay(p_amount bigint)
returns jsonb
language sql
as $$
  select jsonb_build_array(jsonb_build_object(
    'method', 'cash',
    'amount', jsonb_build_object('amount_minor', p_amount, 'currency_code', 'VND')
  ));
$$;

create or replace function pg_temp.rep_finalize(
  p_tenant uuid, p_actor uuid, p_store uuid, p_lines jsonb, p_payments jsonb, p_key text,
  p_customer uuid default null, p_due date default null
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
    'unit', jsonb_build_object('productUnitId', l.value ->> 'product_unit_id', 'unitName', coalesce(pu.unit_name, 'DV')),
    'quantityMicros', (l.value ->> 'quantity_micros')::bigint,
    'lineTotal', jsonb_build_object(
      'amountMinor',
      (l.value -> 'unit_price' ->> 'amount_minor')::bigint
        * (l.value ->> 'quantity_micros')::bigint / 1000000
    )
  ) order by l.ordinality)
  into v_snap_lines
  from jsonb_array_elements(p_lines) with ordinality as l(value, ordinality)
  left join catalog.product_units pu on pu.id = (l.value ->> 'product_unit_id')::uuid;

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

create or replace function pg_temp.rep_cancel(p_tenant uuid, p_actor uuid, p_order uuid, p_key text)
returns jsonb
language plpgsql
as $$
declare
  v_ov int;
  v_sv int;
begin
  select version into v_ov from sales.sales_orders where tenant_id = p_tenant and id = p_order;
  select version into v_sv from receivable.sales_order_settlements
    where tenant_id = p_tenant and sales_order_id = p_order
    order by version desc limit 1;
  return sales.confirm_sales_order_cancellation(
    command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    sales_order_id => p_order, reason_text => 'Report test huy',
    idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text,
    expected_order_version => v_ov, expected_settlement_version => v_sv);
end;
$$;

-- Trả `p_qty_micros` của dòng đơn `p_line_id` (phiếu trả hoàn tất); trả về return_exchange_orders.id
create or replace function pg_temp.rep_return(
  p_tenant uuid, p_actor uuid, p_order uuid, p_line_id uuid,
  p_product uuid, p_unit uuid, p_qty_micros bigint, p_key text
)
returns uuid
language plpgsql
as $$
declare
  v_rx jsonb;
  v_rx_id uuid;
  v_rx_ver int;
begin
  v_rx := sales.start_return_exchange(gen_random_uuid()::text, p_tenant, p_actor, p_order, 'standard',
    jsonb_build_array(jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', p_line_id,
      'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
      'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    p_key || '-start', 'h', gen_random_uuid()::text);
  v_rx_id := (v_rx ->> 'returnExchangeId')::uuid;
  v_rx_ver := (v_rx ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(gen_random_uuid()::text, p_tenant, p_actor, v_rx_id);
  perform sales.confirm_return_exchange(gen_random_uuid()::text, p_tenant, p_actor, v_rx_id,
    p_key || '-conf', 'h', gen_random_uuid()::text, expected_version => v_rx_ver);
  return v_rx_id;
end;
$$;



-- Dựng một cửa hàng: chủ, kho, cửa hàng, 2 sản phẩm có tồn 100
create or replace function pg_temp.ss_tenant(
  p_owner uuid, p_t uuid, p_store uuid, p_wh uuid,
  p_p1 uuid, p_u1 uuid, p_p2 uuid, p_u2 uuid, p_tag text
)
returns void
language plpgsql
as $$
begin
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (p_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'owner-ss-' || p_tag || '-' || substr(p_owner::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.tenants (id, display_name) values (p_t, 'Stats Tenant ' || p_tag);
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (p_t, p_owner, 'store_owner', true);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (p_store, p_t, 'SS' || p_tag, 'Cửa hàng ' || p_tag, 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (p_wh, p_t, 'Kho ' || p_tag, 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (p_t, p_store, p_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', p_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_owner::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by) values (p_t, 'MOVING', p_owner);

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values
    (p_p1, p_t, 'SP Một ' || p_tag, 'SS1-' || p_tag, 'none', false, 'active', true, 'SS-REF1-' || p_tag, p_owner, p_owner),
    (p_p2, p_t, 'SP Hai ' || p_tag, 'SS2-' || p_tag, 'none', false, 'active', true, 'SS-REF2-' || p_tag, p_owner, p_owner);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values (p_u1, p_t, p_p1, 'hộp', 1, true), (p_u2, p_t, p_p2, 'hộp', 1, true);
  perform catalog.set_product_unit_price_band(p_tenant_id => p_t, p_product_id => p_p1, p_product_unit_id => p_u1, p_source_type => 'manual', p_list_price_before_vat => 100000, p_list_price_after_vat => 100000, p_floor_price_before_vat => 10000, p_floor_price_after_vat => 10000);
  perform catalog.set_product_unit_price_band(p_tenant_id => p_t, p_product_id => p_p2, p_product_unit_id => p_u2, p_source_type => 'manual', p_list_price_before_vat => 50000, p_list_price_after_vat => 50000, p_floor_price_before_vat => 5000, p_floor_price_after_vat => 5000);
  update catalog.products set is_ready_to_sell = true where tenant_id = p_t;

  perform inventory._post_movements(
    p_t, p_wh, 'SETUP', gen_random_uuid(), inventory._today(),
    jsonb_build_array(
      jsonb_build_object('product_id', p_p1, 'quantity_delta', 100, 'unit_cost', 40000, 'movement_kind', 'RECEIPT'),
      jsonb_build_object('product_id', p_p2, 'quantity_delta', 100, 'unit_cost', 20000, 'movement_kind', 'RECEIPT')),
    p_owner);
end;
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_owner2 uuid := gen_random_uuid();
  v_outsider uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_t2 uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_store2 uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_wh2 uuid := gen_random_uuid();
  v_p1 uuid := gen_random_uuid();
  v_u1 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_u2 uuid := gen_random_uuid();
  v_q1 uuid := gen_random_uuid();
  v_w1 uuid := gen_random_uuid();
  v_q2 uuid := gen_random_uuid();
  v_w2 uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_from date := inventory._today() - 6;
  v_cust uuid;
  v_res jsonb;
  v_o1 uuid;
  v_o3 uuid;
  v_o4 uuid;
  v_line3 uuid;
  v_n bigint;
  v_n2 bigint;
  v_sum bigint;
  v_qty numeric;
  v_stats_total bigint;
  v_stats_qty numeric;
  v_stats_orders bigint;
  v_avail numeric;
  v_avail_view numeric;
  v_nguong numeric;
  v_denied boolean := false;
  v_cat json;
  v_view json;
  v_col json;
  v_views int := 0;
begin
  -- 1. Fixture --------------------------------------------------------------
  perform pg_temp.ss_tenant(v_owner, v_t, v_store, v_wh, v_p1, v_u1, v_p2, v_u2, 'A');
  perform pg_temp.ss_tenant(v_owner2, v_t2, v_store2, v_wh2, v_q1, v_w1, v_q2, v_w2, 'B');

  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (v_outsider, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'outsider-ss-' || substr(v_outsider::text, 1, 8) || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  -- Tenant A (jwt = chủ A)
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  select c.partner_id into v_cust
  from partner.create_partner(v_t, v_owner, 'person', array['customer'], jsonb_build_object('full_name', 'Khách thống kê', 'phone', '0988000999')) c;

  -- o1: SP Một x1 100000, có khách, trả đủ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), pg_temp.rep_pay(100000), 'ss-o1', v_cust, null);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o1: %', v_res; end if;
  v_o1 := (v_res ->> 'salesOrderId')::uuid;

  -- o2: SP Hai x1 50000, khách lẻ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p2, v_u2, 1000000, 50000)), pg_temp.rep_pay(50000), 'ss-o2');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o2: %', v_res; end if;

  -- o3: SP Một x2 200000, khách lẻ; rồi trả 1
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 2000000, 100000)), pg_temp.rep_pay(200000), 'ss-o3');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o3: %', v_res; end if;
  v_o3 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_line3 from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_o3;
  perform pg_temp.rep_return(v_t, v_owner, v_o3, v_line3, v_p1, v_u1, 1000000, 'ss-r1');

  -- o4: SP Một x1, bán nợ rồi huỷ
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 1000000, 100000)), '[]'::jsonb, 'ss-o4', v_cust, v_today + 5);
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture o4: %', v_res; end if;
  v_o4 := (v_res ->> 'salesOrderId')::uuid;
  perform pg_temp.rep_cancel(v_t, v_owner, v_o4, 'ss-c4');

  -- Tenant B (jwt = chủ B): 2 đơn 100000 + 50000
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner2::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner2::text, true);
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q1, v_w1, 1000000, 100000)), pg_temp.rep_pay(100000), 'ss-b1');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b1: %', v_res; end if;
  v_res := pg_temp.rep_finalize(v_t2, v_owner2, v_store2,
    jsonb_build_array(pg_temp.rep_line(v_q2, v_w2, 1000000, 50000)), pg_temp.rep_pay(50000), 'ss-b2');
  if v_res ->> 'status' <> 'succeeded' then raise exception 'FAIL: fixture b2: %', v_res; end if;

  -- Quay lại chủ A
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- Số liệu đối chiếu (chạy bằng chủ A, trước khi đổi role)
  v_stats_total := (sales.get_sales_stats(v_t, 'revenue', 'none', v_from, v_today)->>'total')::bigint;
  v_stats_qty := (sales.get_sales_stats(v_t, 'quantity', 'none', v_from, v_today)->>'total')::numeric;
  v_stats_orders := (sales.get_sales_stats(v_t, 'order_count', 'none', v_from, v_today)->>'total')::bigint;
  select (e->>'available')::numeric into v_avail
  from jsonb_array_elements(inventory.list_stock_overview(v_t)->'products') e
  where e->>'product_id' = v_p1::text;

  -- v_catalog_complete (gọi bằng chủ A) --------------------------------------
  v_cat := ai.get_catalog();
  if json_array_length(v_cat) <> 6 then
    raise exception 'FAIL: v_catalog_complete expected 6 views, got %', json_array_length(v_cat);
  end if;
  for v_view in select * from json_array_elements(v_cat) loop
    v_views := v_views + 1;
    if coalesce(v_view->>'mo_ta', '') = '' then
      raise exception 'FAIL: v_catalog_complete view % has empty mo_ta', v_view->>'view';
    end if;
    for v_col in select * from json_array_elements(v_view->'cot') loop
      if coalesce(v_col->>'mo_ta', '') = '' then
        raise exception 'FAIL: v_catalog_complete column %.% has empty mo_ta', v_view->>'view', v_col->>'ten';
      end if;
      -- v_no_pii_columns
      if (v_col->>'ten') ~ '(dien_thoai|email|dia_chi|phone|mst)' then
        raise exception 'FAIL: v_no_pii_columns column %.%', v_view->>'view', v_col->>'ten';
      end if;
    end loop;
  end loop;

  -- Người ngoài tenant gọi catalog
  perform set_config('request.jwt.claims', json_build_object('sub', v_outsider::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_outsider::text, true);
  perform pg_temp.expect_err('select ai.get_catalog()', 'PERMISSION_DENIED', 'v_catalog_complete outsider');
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- Đọc view bằng role ai_reader, cửa hàng A ---------------------------------
  perform set_config('ai.tenant_id', v_t::text, true);
  perform set_config('ai.store_id', v_store::text, true);
  perform set_config('ai.warehouse_id', v_wh::text, true);
  set local role ai_reader;

  -- v_don_ban_scope
  select count(*) into v_n from ai_read.don_ban;
  select count(*) into v_n2 from ai_read.don_ban where trang_thai = 'hoan_tat';
  if v_n <> 4 or v_n2 <> 3 then
    reset role;
    raise exception 'FAIL: v_don_ban_scope expected 4 rows (3 hoan_tat), got % / %', v_n, v_n2;
  end if;
  select count(*) into v_n from ai_read.don_ban where trang_thai = 'da_huy';
  if v_n <> 1 then
    reset role;
    raise exception 'FAIL: v_don_ban_scope expected 1 da_huy, got %', v_n;
  end if;
  select count(*) into v_n from ai_read.don_ban where ten_khach = 'Khách lẻ' and khach_id is null;
  if v_n <> 2 then
    reset role;
    raise exception 'FAIL: v_don_ban_scope expected 2 walk-in orders, got %', v_n;
  end if;
  select count(*) into v_n from ai_read.don_ban where ten_khach = 'Khách thống kê';
  if v_n <> 2 then
    reset role;
    raise exception 'FAIL: v_don_ban_scope expected 2 orders of named customer, got %', v_n;
  end if;

  -- v_revenue_matches_sales_stats
  select coalesce(sum(doanh_thu_vnd), 0), coalesce(sum(so_luong), 0)
  into v_sum, v_qty
  from ai_read.ban_hang_thuan
  where ngay between v_from and v_today;
  if v_sum <> v_stats_total or v_sum = 0 then
    reset role;
    raise exception 'FAIL: v_revenue_matches_sales_stats % vs %', v_sum, v_stats_total;
  end if;
  if v_qty <> v_stats_qty then
    reset role;
    raise exception 'FAIL: v_revenue_matches_sales_stats quantity % vs %', v_qty, v_stats_qty;
  end if;
  select count(*) into v_n from ai_read.ban_hang_thuan where loai_dong = 'tra';
  select count(*) into v_n2 from ai_read.ban_hang_thuan where loai_dong = 'huy';
  if v_n < 1 or v_n2 < 1 then
    reset role;
    raise exception 'FAIL: v_revenue_matches_sales_stats must contain tra and huy rows, got % / %', v_n, v_n2;
  end if;

  -- v_orders_count_matches
  select count(*) into v_n from ai_read.don_ban
  where trang_thai = 'hoan_tat' and ngay_ban between v_from and v_today;
  if v_n <> v_stats_orders then
    reset role;
    raise exception 'FAIL: v_orders_count_matches % vs %', v_n, v_stats_orders;
  end if;

  -- v_cost_visible
  select coalesce(sum(gia_von_vnd), 0) into v_sum from ai_read.ban_hang_thuan;
  if v_sum <= 0 then
    reset role;
    raise exception 'FAIL: v_cost_visible expected positive cost, got %', v_sum;
  end if;

  -- v_stock_and_movements
  select ton_kha_dung, nguong_canh_bao into v_avail_view, v_nguong
  from ai_read.ton_kho where san_pham_id = v_p1;
  if v_avail_view is distinct from v_avail then
    reset role;
    raise exception 'FAIL: v_stock_and_movements ton_kha_dung % vs list_stock_overview %', v_avail_view, v_avail;
  end if;
  select count(*) into v_n from ai_read.ton_kho;
  if v_n <> 2 then
    reset role;
    raise exception 'FAIL: v_stock_and_movements expected 2 products, got %', v_n;
  end if;
  select count(*) into v_n from ai_read.bien_dong_kho where loai = 'RECEIPT';
  select count(*) into v_n2 from ai_read.bien_dong_kho where loai = 'SALE';
  if v_n < 1 or v_n2 < 1 then
    reset role;
    raise exception 'FAIL: v_stock_and_movements RECEIPT % / SALE %', v_n, v_n2;
  end if;
  select count(*) into v_n from ai_read.san_pham;
  select count(*) into v_n2 from ai_read.khach_hang;
  if v_n <> 2 or v_n2 <> 1 then
    reset role;
    raise exception 'FAIL: v_stock_and_movements san_pham % / khach_hang %', v_n, v_n2;
  end if;
  reset role;
  if v_nguong is not null then
    raise exception 'FAIL: v_stock_and_movements nguong_canh_bao must be null, got %', v_nguong;
  end if;

  -- v_no_vars_no_rows
  perform set_config('ai.tenant_id', '', true);
  perform set_config('ai.store_id', '', true);
  perform set_config('ai.warehouse_id', '', true);
  set local role ai_reader;
  select (select count(*) from ai_read.don_ban) + (select count(*) from ai_read.ban_hang_thuan)
       + (select count(*) from ai_read.ton_kho) + (select count(*) from ai_read.bien_dong_kho)
       + (select count(*) from ai_read.san_pham) + (select count(*) from ai_read.khach_hang)
  into v_n;
  reset role;
  if v_n <> 0 then
    raise exception 'FAIL: v_no_vars_no_rows expected 0 rows, got %', v_n;
  end if;

  -- v_other_tenant_isolated: đổi sang cửa hàng B
  perform set_config('ai.tenant_id', v_t2::text, true);
  perform set_config('ai.store_id', v_store2::text, true);
  perform set_config('ai.warehouse_id', v_wh2::text, true);
  set local role ai_reader;
  select count(*), coalesce(sum(tong_tien_vnd), 0) into v_n, v_sum from ai_read.don_ban;
  select count(*) into v_n2 from ai_read.ton_kho where ten_san_pham like '%A';
  reset role;
  if v_n <> 2 or v_sum <> 150000 then
    raise exception 'FAIL: v_other_tenant_isolated expected 2 orders / 150000, got % / %', v_n, v_sum;
  end if;
  if v_n2 <> 0 then
    raise exception 'FAIL: v_other_tenant_isolated tenant B must not see tenant A products';
  end if;

  -- Mix: tenant A + kho của B ⇒ không thấy dữ liệu kho B của A (hai biến khác cửa hàng)
  perform set_config('ai.tenant_id', v_t::text, true);
  perform set_config('ai.store_id', v_store2::text, true);
  set local role ai_reader;
  select count(*) into v_n from ai_read.don_ban;
  reset role;
  if v_n <> 0 then
    raise exception 'FAIL: v_other_tenant_isolated tenant A with store B must see 0 orders, got %', v_n;
  end if;

  -- v_direct_access_denied
  set local role authenticated;
  begin
    perform 1 from ai_read.don_ban limit 1;
  exception when insufficient_privilege then
    v_denied := true;
  end;
  reset role;
  if not v_denied then
    raise exception 'FAIL: v_direct_access_denied authenticated must not read ai_read views';
  end if;

  raise notice 'ai_read_views: OK';
end;
$$;

rollback;
