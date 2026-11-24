-- Test suite for ai.run_query / ai._validate_sql (AI-4 Task 2)
-- Run via: tools/db_check.sh --no-reset ai_run_query
-- Cases: q1_basic_select, q2_cut_at_50, q3_cte_and_join, q4_member_sees_cost, q5_timeout (heavy query),
--        q6_other_tenant, q7_syntax_error_message, r1..r16 (rejected statements)

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

create or replace function pg_temp.run_q(p_tenant uuid, p_sql text)
returns jsonb
language sql
as $$
  select ai.run_query(p_tenant, p_sql)::jsonb;
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_owner2 uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
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
  v_outsider uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_cust uuid;
  v_res jsonb;
  v_o1 uuid;
  v_o3 uuid;
  v_o4 uuid;
  v_line3 uuid;
  v_cost_owner bigint;
  v_cost_staff bigint;
  v_before text := current_user;
  v_t0 timestamptz;
  v_msg text;
  v_bad text[];
  v_sql text;
  v_i int;
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

  -- Thành viên không phải chủ của cửa hàng A
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values (v_staff, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'staff-aq-' || substr(v_staff::text, 1, 8) || '@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());
  insert into iam.memberships (tenant_id, user_id, role, is_owner) values (v_t, v_staff, 'staff', false);

  -- q1_basic_select ----------------------------------------------------------
  v_res := pg_temp.run_q(v_t, 'select ma_don, tong_tien_vnd from ai_read.don_ban order by tong_tien_vnd desc');
  if v_res->'cot' <> '["ma_don","tong_tien_vnd"]'::jsonb then
    raise exception 'FAIL: q1_basic_select cot %', v_res->'cot';
  end if;
  if jsonb_array_length(v_res->'dong') <> 4 or (v_res->>'bi_cat')::boolean then
    raise exception 'FAIL: q1_basic_select expected 4 rows, not cut: %', v_res;
  end if;
  if current_user <> v_before then
    raise exception 'FAIL: q1_basic_select role not restored: %', current_user;
  end if;
  -- tên view không cần schema
  v_res := pg_temp.run_q(v_t, 'select count(*) as n from don_ban where trang_thai = ''hoan_tat'';');
  if (v_res->'dong'->0->>'n')::int <> 3 then
    raise exception 'FAIL: q1_basic_select unqualified view count %', v_res;
  end if;
  -- không có dòng ⇒ cột rỗng
  v_res := pg_temp.run_q(v_t, 'select ma_don from ai_read.don_ban where 1 = 0');
  if jsonb_array_length(v_res->'dong') <> 0 or jsonb_array_length(v_res->'cot') <> 0 then
    raise exception 'FAIL: q1_basic_select empty result %', v_res;
  end if;

  -- q8_whitespace_trim: xuống dòng / tab đầu cuối và ';' cuối vẫn được nhận
  v_res := pg_temp.run_q(v_t, chr(10) || chr(9) || 'select 1 as n;' || chr(10));
  if (v_res->'dong'->0->>'n')::int <> 1 then
    raise exception 'FAIL: q8_whitespace_trim %', v_res;
  end if;
  -- r17: hàm có tiền tố schema bị từ chối
  perform pg_temp.expect_err(
    format('select ai.run_query(%L, %L)', v_t, 'select public.sum(1)'),
    'CONTEXT_INVALID', 'r17_schema_qualified_function');

  -- q2_cut_at_50 -------------------------------------------------------------
  v_res := pg_temp.run_q(v_t, 'select * from generate_series(1,200) g');
  if jsonb_array_length(v_res->'dong') <> 50 or not (v_res->>'bi_cat')::boolean then
    raise exception 'FAIL: q2_cut_at_50 %', v_res->>'bi_cat';
  end if;

  -- q3_cte_and_join ----------------------------------------------------------
  v_res := pg_temp.run_q(v_t,
    'with d as (select khach_id, tong_tien_vnd from ai_read.don_ban where trang_thai = ''hoan_tat'') '
    || 'select k.ten_khach, sum(d.tong_tien_vnd) as tong from d join ai_read.khach_hang k on k.khach_id = d.khach_id group by k.ten_khach');
  if jsonb_array_length(v_res->'dong') <> 1 then
    raise exception 'FAIL: q3_cte_and_join expected 1 row, got %', v_res;
  end if;

  -- q4_member_sees_cost ------------------------------------------------------
  v_res := pg_temp.run_q(v_t, 'select sum(gia_von_vnd) as c from ai_read.ban_hang_thuan');
  v_cost_owner := (v_res->'dong'->0->>'c')::bigint;
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_staff::text, true);
  v_res := pg_temp.run_q(v_t, 'select sum(gia_von_vnd) as c from ai_read.ban_hang_thuan');
  v_cost_staff := (v_res->'dong'->0->>'c')::bigint;
  if v_cost_owner is null or v_cost_owner <= 0 or v_cost_owner <> v_cost_staff then
    raise exception 'FAIL: q4_member_sees_cost owner % vs staff %', v_cost_owner, v_cost_staff;
  end if;

  -- q6_other_tenant ----------------------------------------------------------
  perform pg_temp.expect_err(
    format('select ai.run_query(%L, %L)', v_t2, 'select count(*) as n from ai_read.don_ban'),
    'PERMISSION_DENIED', 'q6_other_tenant staff A asks for B');
  v_res := pg_temp.run_q(v_t, 'select count(*) as n from ai_read.don_ban');
  if (v_res->'dong'->0->>'n')::int <> 4 then
    raise exception 'FAIL: q6_other_tenant A must see only its 4 orders, got %', v_res;
  end if;
  perform set_config('request.jwt.claims', json_build_object('sub', v_outsider::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_outsider::text, true);
  perform pg_temp.expect_err(
    format('select ai.run_query(%L, %L)', v_t, 'select 1'),
    'PERMISSION_DENIED', 'q6_other_tenant non member');
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- r1..r16: câu bị từ chối --------------------------------------------------
  v_bad := array[
    'select * from iam.tenants',                                                     -- r1_raw_table
    'select * from auth.users',                                                      -- r2_auth_users
    'select * from pg_class',                                                        -- r3_catalog
    'select * from information_schema.tables',                                       -- r4_info_schema
    'select 1; drop table x',                                                        -- r5_multi_statement
    'select 1 -- x',                                                                 -- r6_comment
    'select * from "ai_read"."don_ban"',                                             -- r7_quoted
    'select pg_sleep(10)',                                                           -- r8_pg_sleep
    format('select set_config(''ai.tenant_id'', ''%s'', true)', v_t2),               -- r9_set_config
    'select current_setting(''ai.tenant_id'')',                                      -- r10_current_setting
    'select md5(''x'')',                                                             -- r11_unknown_function
    'insert into ai_read.don_ban (ma_don) values (''x'')',                           -- r12_insert
    'select ma_don into temp_x from ai_read.don_ban',                                -- r13_into
    'select ma_don from ai_read.don_ban union select name from catalog.products',    -- r14_union_raw
    'select ''' || repeat('x', 4000) || '''',                                        -- r15_too_long
    '   '                                                                            -- r16_empty
  ];
  for v_i in 1 .. array_length(v_bad, 1) loop
    perform pg_temp.expect_err(
      format('select ai.run_query(%L, %L)', v_t, v_bad[v_i]),
      'CONTEXT_INVALID', 'r' || v_i || '_rejected');
  end loop;
  if current_user <> v_before then
    raise exception 'FAIL: rejected statements must not leave the role changed: %', current_user;
  end if;

  -- r1 chi tiết: thông báo cố định, không lộ tên bảng gốc
  begin
    perform ai.run_query(v_t, 'select * from iam.tenants');
  exception when others then
    v_msg := sqlerrm;
  end;
  if v_msg is null or v_msg like '%tenants%' then
    raise exception 'FAIL: r1_raw_table message must not echo raw table: %', v_msg;
  end if;

  -- q5_timeout: join chéo khổng lồ bị chặn nhanh -------------------------------
  v_t0 := clock_timestamp();
  perform pg_temp.expect_err(
    format('select ai.run_query(%L, %L)', v_t,
      'select count(*) from generate_series(1, 100000000) a, generate_series(1, 1000) b'),
    'CONTEXT_INVALID', 'q5_timeout');
  if clock_timestamp() - v_t0 > interval '8 seconds' then
    raise exception 'FAIL: q5_timeout took too long: %', clock_timestamp() - v_t0;
  end if;

  -- q7_syntax_error_message --------------------------------------------------
  v_msg := null;
  begin
    perform ai.run_query(v_t, 'select from from');
  exception when others then
    v_msg := sqlerrm;
  end;
  if v_msg is null or v_msg not like '%CONTEXT_INVALID%' then
    raise exception 'FAIL: q7_syntax_error_message expected CONTEXT_INVALID, got %', v_msg;
  end if;
  if v_msg ~* '(iam|auth|catalog|sales|inventory|partner)\.' then
    raise exception 'FAIL: q7_syntax_error_message leaks schema: %', v_msg;
  end if;

  raise notice 'ai_run_query: OK';
end;
$$;

rollback;
