-- Test suite: _issue_for_sale không trừ chéo tồn giữa các sản phẩm trong một đơn (patch 20261121002)
-- Run on Dev: supabase db query --linked -f supabase/tests/inventory_issue_multi_line.sql
-- Bọc begin/rollback: fixture không ở lại DB.
-- Cases: m1_multi_line_ok, m2_real_shortage_still_blocked, m3_stock_after
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
  v_t uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_p1 uuid := gen_random_uuid();
  v_u1 uuid := gen_random_uuid();
  v_p2 uuid := gen_random_uuid();
  v_u2 uuid := gen_random_uuid();
  v_res jsonb;
  v_a numeric;
begin
  perform pg_temp.ss_tenant(v_owner, v_t, v_store, v_wh, v_p1, v_u1, v_p2, v_u2, 'ML');
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  -- m1: mỗi sản phẩm tồn 100; đơn 60 + 50 (tổng 110 > 100 nhưng mỗi sản phẩm đủ) phải thành công
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 60000000, 100000), pg_temp.rep_line(v_p2, v_u2, 50000000, 50000)),
    pg_temp.rep_pay(8500000), 'ml-1');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL: m1_multi_line_ok %', v_res;
  end if;

  -- m3: tồn sau đơn = 40 và 50
  select available into v_a from inventory._product_stock_rows(v_t, array[v_p1]);
  if v_a <> 40 then raise exception 'FAIL: m3 SP1 available % expected 40', v_a; end if;
  select available into v_a from inventory._product_stock_rows(v_t, array[v_p2]);
  if v_a <> 50 then raise exception 'FAIL: m3 SP2 available % expected 50', v_a; end if;

  -- m2: thiếu thật vẫn bị chặn (SP2 còn 50, cần 60)
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p1, v_u1, 10000000, 100000), pg_temp.rep_line(v_p2, v_u2, 60000000, 50000)),
    pg_temp.rep_pay(4000000), 'ml-2');
  if v_res ->> 'blockedCode' is distinct from 'INSUFFICIENT_STOCK' then
    raise exception 'FAIL: m2_real_shortage_still_blocked %', v_res;
  end if;

  raise notice 'inventory_issue_multi_line: OK';
end;
$$;

rollback;
