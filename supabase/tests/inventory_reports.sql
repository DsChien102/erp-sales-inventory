-- Test suite for inventory_reports (T7-G5-7)
-- Run via: tools/db_check.sh --no-reset inventory_reports
-- Task 1: r1_report_balance, r2_card_by_lot, r3_prior_month, r4_sources, r5_staff_masked, r10_bad_range
-- Task 2: (appended below) r6 / r7 / r8 / r9 / r5b

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
  select version into v_sv from sales.sales_order_settlements
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

create or replace function pg_temp.rep_row(p_rows jsonb, p_product uuid)
returns jsonb
language sql
as $$
  select e from jsonb_array_elements(p_rows) e where e->>'product_id' = p_product::text;
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_other_t uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_month_start date := date_trunc('month', inventory._today())::date;
  v_prev_end date := (date_trunc('month', inventory._today()) - interval '1 day')::date;
  v_prev_start date := date_trunc('month', (date_trunc('month', inventory._today()) - interval '1 day'))::date;

  v_cust uuid;
  v_sup uuid := gen_random_uuid();
  v_p_lot uuid := gen_random_uuid();
  v_p_plain uuid := gen_random_uuid();
  v_p_old uuid := gen_random_uuid();
  v_u_lot uuid := gen_random_uuid();
  v_u_plain uuid := gen_random_uuid();
  v_u_old uuid := gen_random_uuid();

  v_lot_a uuid;
  v_lot_b uuid;
  v_session uuid := gen_random_uuid();

  v_res jsonb;
  v_res2 jsonb;
  v_row jsonb;
  v_card jsonb;
  v_det jsonb;
  v_order1 uuid;
  v_order2 uuid;
  v_line2 uuid;
  v_return_id uuid;
  v_receipt1 uuid;
  v_mv uuid;
  v_n numeric;
  v_sum_bal numeric;
  v_ledger bigint;
  v_total bigint;

  -- Task 2
  v_order3 uuid;
  v_line3 uuid;
  v_order5 uuid;
  v_sup2 uuid := gen_random_uuid();
  v_sup3 uuid := gen_random_uuid();
  v_p_tier uuid := gen_random_uuid();
  v_u_tier uuid := gen_random_uuid();
  v_prog_tier uuid := gen_random_uuid();
  v_prog_vol uuid := gen_random_uuid();
  v_prog_vol3 uuid := gen_random_uuid();
  v_rebate1 uuid := gen_random_uuid();
  v_rebate3 uuid := gen_random_uuid();
  v_run uuid;
  v_gp jsonb;
  v_gp_prev jsonb;
  v_ord jsonb;
  v_sum bigint;
  v_loss_before bigint;
begin
  -- 1. Fixture --------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  values
    (v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'owner-rep-' || substr(v_owner::text, 1, 8) || '@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_staff, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'staff-rep-' || substr(v_staff::text, 1, 8) || '@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  insert into iam.tenants (id, display_name) values (v_t, 'Report Tenant'), (v_other_t, 'Other Report Tenant');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_t, v_owner, 'store_owner', true), (v_t, v_staff, 'staff', false);
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store, v_t, 'RP01', 'Cửa hàng báo cáo', 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status)
  values (v_wh, v_t, 'Kho báo cáo', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_t, v_store, v_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  insert into inventory.cost_policies (tenant_id, method, changed_by) values (v_t, 'MOVING', v_owner);

  insert into partner.partners (partner_id, tenant_id, partner_type, display_name, status, created_by, updated_by)
  values (v_sup, v_t, 'organization', 'NCC Báo cáo', 'active', v_owner, v_owner);
  insert into partner.partner_roles (partner_id, tenant_id, role) values (v_sup, v_t, 'supplier');

  select c.partner_id into v_cust
  from partner.create_partner(v_t, v_owner, 'person', array['customer'], jsonb_build_object('full_name', 'Khách nợ báo cáo', 'phone', '0988000777')) c;

  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values
    (v_p_lot, v_t, 'Vắc xin Lô', 'RP-LOT', 'lot', true, 'active', true, 'RP-REF-LOT', v_owner, v_owner),
    (v_p_plain, v_t, 'Thuốc Không Lô', 'RP-PLAIN', 'none', false, 'active', true, 'RP-REF-PLAIN', v_owner, v_owner),
    (v_p_old, v_t, 'Hàng Tháng Trước', 'RP-OLD', 'none', false, 'active', true, 'RP-REF-OLD', v_owner, v_owner);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values
    (v_u_lot, v_t, v_p_lot, 'hộp', 1, true),
    (v_u_plain, v_t, v_p_plain, 'hộp', 1, true),
    (v_u_old, v_t, v_p_old, 'hộp', 1, true);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_p_lot, p_product_unit_id => v_u_lot, p_source_type => 'manual', p_list_price_before_vat => 150000, p_list_price_after_vat => 150000, p_floor_price_before_vat => 50000, p_floor_price_after_vat => 50000);
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_p_plain, p_product_unit_id => v_u_plain, p_source_type => 'manual', p_list_price_before_vat => 80000, p_list_price_after_vat => 80000, p_floor_price_before_vat => 20000, p_floor_price_after_vat => 20000);

  update catalog.products set is_ready_to_sell = true where tenant_id = v_t;

  -- Hàng tháng trước: nhận 7 vào ngày cuối tháng trước, nhận thêm 3 hôm nay
  perform inventory._post_movements(
    v_t, v_wh, 'SETUP', gen_random_uuid(), v_prev_end,
    jsonb_build_array(jsonb_build_object('product_id', v_p_old, 'quantity_delta', 7, 'unit_cost', 1000, 'movement_kind', 'RECEIPT')),
    v_owner);
  perform inventory._post_movements(
    v_t, v_wh, 'SETUP', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_old, 'quantity_delta', 3, 'unit_cost', 1000, 'movement_kind', 'RECEIPT')),
    v_owner);

  -- Hai phiếu nhận: lô A 10 (hạn +30), lô B 5 (hạn +60), không lô 20
  v_res := inventory.record_goods_receipt(v_t, 'rep-gr-1', jsonb_build_object(
    'supplier_id', v_sup,
    'lines', jsonb_build_array(
      jsonb_build_object('product_id', v_p_lot, 'unit_id', v_u_lot, 'unit_price_vnd', 100000, 'free_qty', 0,
        'lots', jsonb_build_array(jsonb_build_object('lot_code', 'LA', 'expiry_date', (v_today + 30)::text, 'quantity', 10))),
      jsonb_build_object('product_id', v_p_plain, 'unit_id', v_u_plain, 'unit_price_vnd', 50000, 'free_qty', 0,
        'lots', jsonb_build_array(jsonb_build_object('quantity', 20)))
    )));
  v_receipt1 := (v_res->>'receipt_id')::uuid;
  v_res := inventory.record_goods_receipt(v_t, 'rep-gr-2', jsonb_build_object(
    'supplier_id', v_sup,
    'lines', jsonb_build_array(
      jsonb_build_object('product_id', v_p_lot, 'unit_id', v_u_lot, 'unit_price_vnd', 100000, 'free_qty', 0,
        'lots', jsonb_build_array(jsonb_build_object('lot_code', 'LB', 'expiry_date', (v_today + 60)::text, 'quantity', 5)))
    )));

  select id into v_lot_a from inventory.lots where tenant_id = v_t and product_id = v_p_lot and lot_code = 'LA';
  select id into v_lot_b from inventory.lots where tenant_id = v_t and product_id = v_p_lot and lot_code = 'LB';

  -- Bán 3 → huỷ đơn → bán 2 → trả 1
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p_lot, v_u_lot, 3000000, 150000)), '[]'::jsonb, 'rep-o1',
    v_cust, v_today + 5);  -- bán nợ để đủ điều kiện huỷ (EP-05)
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL: fixture finalize order1: %', v_res;
  end if;
  v_order1 := (v_res ->> 'salesOrderId')::uuid;
  perform pg_temp.rep_cancel(v_t, v_owner, v_order1, 'rep-c1');

  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p_lot, v_u_lot, 2000000, 150000)), pg_temp.rep_pay(300000), 'rep-o2');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL: fixture finalize order2: %', v_res;
  end if;
  v_order2 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_line2 from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_order2;
  v_return_id := pg_temp.rep_return(v_t, v_owner, v_order2, v_line2, v_p_lot, v_u_lot, 1000000, 'rep-r1');

  -- Kiểm kê thiếu 1 (lô B) — phiên kiểm kê ghi trực tiếp (không có màn xem phiên)
  insert into inventory.stocktake_sessions (id, tenant_id, code, warehouse_id, scope_kind, scope_label, counter_user_id, reason, opened_by)
  values (v_session, v_t, 'KK-REP-01', v_wh, 'ALL', 'Toàn kho', v_staff, 'Kiểm kê báo cáo', v_owner);
  perform inventory._post_movements(
    v_t, v_wh, 'STOCKTAKE', v_session, v_today,
    jsonb_build_array(jsonb_build_object('product_id', v_p_lot, 'lot_code', 'LB', 'quantity_delta', -1, 'movement_kind', 'COUNT_LOSS', 'reason', 'COUNT')),
    v_owner);

  -- =========================================================================
  -- r1_report_balance
  -- =========================================================================
  v_res := inventory.get_stock_report(v_t, v_month_start, v_today);
  if (v_res->>'financial_masked')::boolean then
    raise exception 'FAIL: r1_report_balance owner must not be masked';
  end if;
  if not (v_res->>'show_available')::boolean then
    raise exception 'FAIL: r1_report_balance show_available must be true for current month';
  end if;
  v_row := pg_temp.rep_row(v_res->'rows', v_p_lot);
  if v_row is null then
    raise exception 'FAIL: r1_report_balance lot product missing from report';
  end if;
  if (v_row->>'opening_qty')::numeric + (v_row->>'in_qty')::numeric - (v_row->>'out_qty')::numeric <> (v_row->>'closing_qty')::numeric then
    raise exception 'FAIL: r1_report_balance opening+in-out<>closing %', v_row;
  end if;
  if (v_row->>'in_qty')::numeric <> 19 or (v_row->>'out_qty')::numeric <> 6 or (v_row->>'closing_qty')::numeric <> 13 then
    raise exception 'FAIL: r1_report_balance expected in 19 / out 6 / closing 13 (huỷ đơn + trả nằm ở Nhập), got %', v_row;
  end if;
  select coalesce(sum(physical_quantity), 0) into v_sum_bal
  from inventory.stock_balances where tenant_id = v_t and product_id = v_p_lot;
  if (v_row->>'closing_qty')::numeric <> v_sum_bal then
    raise exception 'FAIL: r1_report_balance closing_qty % <> stock_balances %', v_row->>'closing_qty', v_sum_bal;
  end if;
  select ledger_value_vnd into v_ledger from inventory.product_costs where tenant_id = v_t and product_id = v_p_lot;
  if (v_row->>'closing_value')::bigint <> v_ledger then
    raise exception 'FAIL: r1_report_balance closing_value % <> product_costs.ledger_value_vnd %', v_row->>'closing_value', v_ledger;
  end if;
  select coalesce(sum(ledger_value_vnd), 0) into v_total
  from inventory.product_costs where tenant_id = v_t and product_id in (v_p_lot, v_p_plain, v_p_old);
  if (v_res->>'total_closing_value')::bigint <> v_total then
    raise exception 'FAIL: r1_report_balance total_closing_value % <> %', v_res->>'total_closing_value', v_total;
  end if;
  if (v_row->>'available') is null then
    raise exception 'FAIL: r1_report_balance available must be present when show_available';
  end if;
  -- tìm kiếm không phân biệt hoa thường, bỏ dấu cách đầu cuối
  v_res2 := inventory.get_stock_report(v_t, v_month_start, v_today, '  vắc XIN ');
  if jsonb_array_length(v_res2->'rows') <> 1 then
    raise exception 'FAIL: r1_report_balance search expected 1 row, got %', v_res2->'rows';
  end if;

  -- =========================================================================
  -- r2_card_by_lot
  -- =========================================================================
  v_card := inventory.get_stock_card(v_t, v_p_lot, v_month_start, v_today);
  if not (v_card->'product'->>'is_lot_tracked')::boolean or jsonb_array_length(v_card->'lots') <> 2 then
    raise exception 'FAIL: r2_card_by_lot expected lot tracked with 2 lots, got %', v_card->'lots';
  end if;
  if (v_card->'summary'->>'closing_qty')::numeric <> (v_row->>'closing_qty')::numeric then
    raise exception 'FAIL: r2_card_by_lot all-lot closing % <> report %', v_card->'summary'->>'closing_qty', v_row->>'closing_qty';
  end if;
  if (v_card->'summary'->>'closing_qty')::numeric <> v_sum_bal then
    raise exception 'FAIL: r2_card_by_lot all-lot closing <> stock_balances';
  end if;
  if (v_card->>'closing_value')::bigint <> v_ledger then
    raise exception 'FAIL: r2_card_by_lot all-lot closing_value <> ledger';
  end if;

  v_card := inventory.get_stock_card(v_t, v_p_lot, v_month_start, v_today, v_lot_a);
  select (e->>'closing_qty')::numeric into v_n
  from jsonb_array_elements(v_card->'lots') e where e->>'lot_id' = v_lot_a::text;
  if (v_card->'rows'->(jsonb_array_length(v_card->'rows') - 1)->>'balance_after')::numeric <> v_n then
    raise exception 'FAIL: r2_card_by_lot last balance_after <> lots[A].closing_qty (%)', v_n;
  end if;
  if (v_card->'summary'->>'closing_qty')::numeric <> v_n then
    raise exception 'FAIL: r2_card_by_lot summary.closing_qty <> lots[A].closing_qty';
  end if;
  if (v_card->>'closing_value') is not null then
    raise exception 'FAIL: r2_card_by_lot closing_value must be null when filtering by lot';
  end if;
  if exists (select 1 from jsonb_array_elements(v_card->'rows') e where e->>'lot_code' is distinct from 'LA') then
    raise exception 'FAIL: r2_card_by_lot lot filter leaked another lot: %', v_card->'rows';
  end if;

  v_card := inventory.get_stock_card(v_t, v_p_plain, v_month_start, v_today);
  if jsonb_array_length(v_card->'lots') <> 0 or (v_card->'product'->>'is_lot_tracked')::boolean then
    raise exception 'FAIL: r2_card_by_lot non-lot product must have no lots';
  end if;

  -- =========================================================================
  -- r3_prior_month
  -- =========================================================================
  v_res := inventory.get_stock_report(v_t, v_prev_start, v_prev_end);
  if (v_res->>'show_available')::boolean then
    raise exception 'FAIL: r3_prior_month show_available must be false for a past period';
  end if;
  v_row := pg_temp.rep_row(v_res->'rows', v_p_old);
  if v_row is null or (v_row->>'closing_qty')::numeric <> 7 or (v_row->>'available') is not null then
    raise exception 'FAIL: r3_prior_month expected closing 7 without available, got %', v_row;
  end if;
  v_res2 := inventory.get_stock_report(v_t, v_month_start, v_today);
  v_row := pg_temp.rep_row(v_res2->'rows', v_p_old);
  if (v_row->>'opening_qty')::numeric <> 7 or (v_row->>'in_qty')::numeric <> 3 or (v_row->>'closing_qty')::numeric <> 10 then
    raise exception 'FAIL: r3_prior_month report opening this month must equal closing last month, got %', v_row;
  end if;
  v_card := inventory.get_stock_card(v_t, v_p_old, v_prev_start, v_prev_end);
  v_n := (v_card->'summary'->>'closing_qty')::numeric;
  v_card := inventory.get_stock_card(v_t, v_p_old, v_month_start, v_today);
  if (v_card->'summary'->>'opening_qty')::numeric <> v_n then
    raise exception 'FAIL: r3_prior_month card opening this month <> closing last month';
  end if;
  -- sản phẩm chưa từng vào kho không có dòng
  if pg_temp.rep_row(v_res2->'rows', gen_random_uuid()) is not null then
    raise exception 'FAIL: r3_prior_month unexpected row';
  end if;

  -- =========================================================================
  -- r4_sources
  -- =========================================================================
  -- nhận hàng
  select id into v_mv from inventory.stock_movements
  where tenant_id = v_t and product_id = v_p_lot and intent_type = 'GOODS_RECEIPT' and intent_id = v_receipt1;
  v_det := inventory.get_movement_detail(v_t, v_mv);
  if v_det->'source'->>'kind' <> 'RECEIPT'
     or v_det->'source'->>'doc_code' <> (select receipt_no from inventory.goods_receipts where id = v_receipt1)
     or (v_det->'source'->'target'->>'receipt_id')::uuid <> v_receipt1 then
    raise exception 'FAIL: r4_sources receipt source %', v_det->'source';
  end if;
  if (v_det->>'before_qty')::numeric + (v_det->>'quantity_delta')::numeric <> (v_det->>'after_qty')::numeric then
    raise exception 'FAIL: r4_sources receipt before+delta<>after %', v_det;
  end if;

  -- bán (đơn 2)
  select id into v_mv from inventory.stock_movements
  where tenant_id = v_t and intent_type = 'SALES_ORDER' and intent_id = v_order2;
  v_det := inventory.get_movement_detail(v_t, v_mv);
  if v_det->'source'->>'kind' <> 'ORDER'
     or v_det->'source'->>'doc_code' <> (select order_code from sales.sales_orders where id = v_order2)
     or (v_det->'source'->'target'->>'order_id')::uuid <> v_order2 then
    raise exception 'FAIL: r4_sources order source %', v_det->'source';
  end if;
  select coalesce(sum(quantity_delta), 0) into v_n from inventory.stock_movements
  where tenant_id = v_t and product_id = v_p_lot
    and ledger_sequence < (select ledger_sequence from inventory.stock_movements where id = v_mv);
  if (v_det->>'before_qty')::numeric <> v_n
     or (v_det->>'before_qty')::numeric + (v_det->>'quantity_delta')::numeric <> (v_det->>'after_qty')::numeric then
    raise exception 'FAIL: r4_sources order before/after %', v_det;
  end if;

  -- huỷ đơn 1 → mở đơn gốc
  select id into v_mv from inventory.stock_movements
  where tenant_id = v_t and intent_type = 'SALES_CANCELLATION' and product_id = v_p_lot
  order by ledger_sequence limit 1;
  v_det := inventory.get_movement_detail(v_t, v_mv);
  if v_det->'source'->>'kind' <> 'CANCELLATION'
     or (v_det->'source'->'target'->>'order_id')::uuid <> v_order1
     or v_det->'source'->>'doc_code' <> (select order_code from sales.sales_orders where id = v_order1) then
    raise exception 'FAIL: r4_sources cancellation source %', v_det->'source';
  end if;

  -- trả hàng
  select id into v_mv from inventory.stock_movements
  where tenant_id = v_t and intent_type = 'RETURN_EXCHANGE' and product_id = v_p_lot
  order by ledger_sequence limit 1;
  v_det := inventory.get_movement_detail(v_t, v_mv);
  if v_det->'source'->>'kind' <> 'RETURN_EXCHANGE'
     or (v_det->'source'->'target'->>'order_id')::uuid <> v_order2
     or (v_det->'source'->'target'->>'return_id')::uuid <> v_return_id then
    raise exception 'FAIL: r4_sources return source %', v_det->'source';
  end if;

  -- kiểm kê: không có màn xem
  select id into v_mv from inventory.stock_movements
  where tenant_id = v_t and intent_type = 'STOCKTAKE' and intent_id = v_session;
  v_det := inventory.get_movement_detail(v_t, v_mv);
  if v_det->'source'->>'kind' <> 'STOCKTAKE'
     or v_det->'source'->>'doc_code' <> 'KK-REP-01'
     or jsonb_typeof(v_det->'source'->'target') <> 'null' then
    raise exception 'FAIL: r4_sources stocktake source must have null target, got %', v_det->'source';
  end if;
  if (v_det->>'value_amount') is null then
    raise exception 'FAIL: r4_sources owner must see value_amount of a stocktake loss';
  end if;
  if v_det->>'lot_code' <> 'LB' or (v_det->>'quantity_delta')::numeric <> -1 then
    raise exception 'FAIL: r4_sources stocktake lot / delta %', v_det;
  end if;

  -- =========================================================================
  -- r5_staff_masked
  -- =========================================================================
  perform set_config('request.jwt.claim.sub', v_staff::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff::text, 'role', 'authenticated')::text, true);

  v_res2 := inventory.get_stock_report(v_t, v_month_start, v_today);
  if not (v_res2->>'financial_masked')::boolean or (v_res2->>'total_closing_value') is not null then
    raise exception 'FAIL: r5_staff_masked report not masked: %', v_res2;
  end if;
  if exists (select 1 from jsonb_array_elements(v_res2->'rows') e where e->>'closing_value' is not null) then
    raise exception 'FAIL: r5_staff_masked report row leaked closing_value';
  end if;
  v_row := pg_temp.rep_row(v_res2->'rows', v_p_lot);
  if (v_row->>'closing_qty')::numeric <> 13 or (v_row->>'in_qty')::numeric <> 19 then
    raise exception 'FAIL: r5_staff_masked quantities must equal owner view, got %', v_row;
  end if;

  v_card := inventory.get_stock_card(v_t, v_p_lot, v_month_start, v_today);
  if not (v_card->>'financial_masked')::boolean or (v_card->>'closing_value') is not null then
    raise exception 'FAIL: r5_staff_masked card not masked';
  end if;

  v_det := inventory.get_movement_detail(v_t, v_mv);
  if (v_det->>'value_amount') is not null then
    raise exception 'FAIL: r5_staff_masked movement detail leaked value_amount';
  end if;

  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);

  -- =========================================================================
  -- r10_bad_range
  -- =========================================================================
  perform pg_temp.expect_err(
    format('select inventory.get_stock_report(%L, %L::date, %L::date)', v_t, v_today, v_month_start - 1),
    'CONTEXT_INVALID', 'r10_bad_range report from>to');
  perform pg_temp.expect_err(
    format('select inventory.get_stock_report(%L, null::date, %L::date)', v_t, v_today),
    'CONTEXT_INVALID', 'r10_bad_range report null from');
  perform pg_temp.expect_err(
    format('select inventory.get_stock_card(%L, %L, %L::date, null::date)', v_t, v_p_lot, v_today),
    'CONTEXT_INVALID', 'r10_bad_range card null to');
  perform pg_temp.expect_err(
    format('select inventory.get_stock_card(%L, %L, %L::date, %L::date)', v_t, gen_random_uuid(), v_month_start, v_today),
    'CONTEXT_INVALID', 'r10_bad_range card unknown product');
  perform pg_temp.expect_err(
    format('select inventory.get_movement_detail(%L, %L)', v_t, gen_random_uuid()),
    'CONTEXT_INVALID', 'r10_bad_range movement unknown');

  -- =========================================================================
  -- TASK 2 — lãi gộp, nhập theo NCC
  -- =========================================================================
  perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_p_old, p_product_unit_id => v_u_old, p_source_type => 'manual', p_list_price_before_vat => 30000, p_list_price_after_vat => 30000, p_floor_price_before_vat => 10000, p_floor_price_after_vat => 10000);
  update catalog.products set is_ready_to_sell = true where tenant_id = v_t;

  -- r6_gross_profit_product: dữ liệu fixture r1 (đơn 1 bán 3 rồi huỷ, đơn 2 bán 2 trả 1; 150.000 / hộp, giá vốn 100.000)
  v_gp := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT');
  v_row := pg_temp.rep_row(v_gp->'rows', v_p_lot);
  if (v_row->>'revenue_vnd')::bigint <> 750000
     or (v_row->>'deduction_vnd')::bigint <> 600000
     or (v_row->>'net_revenue_vnd')::bigint <> 150000 then
    raise exception 'FAIL: r6_gross_profit_product revenue/deduction/net expected 750000/600000/150000, got %', v_row;
  end if;
  select -coalesce(sum(amount_vnd), 0) into v_sum
  from inventory.value_movements
  where tenant_id = v_t and product_id = v_p_lot
    and kind in ('SALE', 'SALE_REVERSAL', 'RETURN_IN')
    and business_date between v_month_start and v_today;
  if (v_row->>'cogs_at_sale_vnd')::bigint <> v_sum or v_sum <> 100000 then
    raise exception 'FAIL: r6_gross_profit_product cogs_at_sale expected 100000 = -sum(ledger), got % / %', v_row->>'cogs_at_sale_vnd', v_sum;
  end if;
  if (v_row->>'gross_profit_vnd')::bigint <> 50000 or (v_row->>'margin_pct')::numeric <> 33.3 then
    raise exception 'FAIL: r6_gross_profit_product gross profit / margin %', v_row;
  end if;
  if (v_gp->'totals'->>'net_revenue')::bigint <> (
       select coalesce(sum((e->>'net_revenue_vnd')::bigint), 0) from jsonb_array_elements(v_gp->'rows') e) then
    raise exception 'FAIL: r6_gross_profit_product totals.net_revenue <> sum(rows)';
  end if;
  if (v_gp->'totals'->>'profit_after_loss')::bigint <> (v_gp->'totals'->>'gross_profit')::bigint - (v_gp->>'loss_vnd')::bigint then
    raise exception 'FAIL: r6_gross_profit_product profit_after_loss';
  end if;
  v_loss_before := (v_gp->>'loss_vnd')::bigint;
  if v_loss_before <> 100000 then
    raise exception 'FAIL: r6_gross_profit_product loss_vnd expected 100000 (kiểm kê thiếu 1 hộp), got %', v_loss_before;
  end if;

  -- r6_prior_month_return: đơn tháng trước (dời completed_at), trả tháng này
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p_old, v_u_old, 2000000, 30000)), pg_temp.rep_pay(60000), 'rep-o3');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL: fixture finalize order3: %', v_res;
  end if;
  v_order3 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_line3 from sales.sales_order_lines where tenant_id = v_t and sales_order_id = v_order3;
  update sales.sales_orders
  set completed_at = ((v_prev_end::timestamp + interval '12 hours') at time zone 'Asia/Ho_Chi_Minh')
  where tenant_id = v_t and id = v_order3;
  perform pg_temp.rep_return(v_t, v_owner, v_order3, v_line3, v_p_old, v_u_old, 1000000, 'rep-r3');

  v_gp := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT');
  v_row := pg_temp.rep_row(v_gp->'rows', v_p_old);
  if (v_row->>'revenue_vnd')::bigint <> 0 or (v_row->>'deduction_vnd')::bigint <> 30000
     or (v_row->>'net_revenue_vnd')::bigint <> -30000 then
    raise exception 'FAIL: r6_prior_month_return this month expected revenue 0 / deduction 30000, got %', v_row;
  end if;
  -- doanh thu thuần ≤ 0 ⇒ không có tỷ lệ (không chia ra số dương giả)
  if (v_row->>'margin_pct') is not null then
    raise exception 'FAIL: r6_prior_month_return margin_pct must be null when net revenue < 0, got %', v_row;
  end if;
  v_gp_prev := inventory.get_gross_profit_report(v_t, v_prev_start, v_prev_end, 'PRODUCT');
  v_row := pg_temp.rep_row(v_gp_prev->'rows', v_p_old);
  if (v_row->>'revenue_vnd')::bigint <> 60000 or (v_row->>'deduction_vnd')::bigint <> 0 then
    raise exception 'FAIL: r6_prior_month_return last month must be unchanged (revenue 60000, deduction 0), got %', v_row;
  end if;
  v_ord := inventory.get_gross_profit_report(v_t, v_prev_start, v_prev_end, 'ORDER');
  if not exists (select 1 from jsonb_array_elements(v_ord->'rows') e where e->>'order_id' = v_order3::text and (e->>'revenue_vnd')::bigint = 60000) then
    raise exception 'FAIL: r6_prior_month_return ORDER last month must still list order3 in full: %', v_ord->'rows';
  end if;

  -- r8_gross_profit_order
  v_res := pg_temp.rep_finalize(v_t, v_owner, v_store,
    jsonb_build_array(pg_temp.rep_line(v_p_plain, v_u_plain, 2000000, 80000)), pg_temp.rep_pay(160000), 'rep-o5');
  if v_res ->> 'status' <> 'succeeded' then
    raise exception 'FAIL: fixture finalize order5: %', v_res;
  end if;
  v_order5 := (v_res ->> 'salesOrderId')::uuid;
  v_gp := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT');
  v_row := pg_temp.rep_row(v_gp->'rows', v_p_plain);
  v_ord := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'ORDER');
  select e into v_res from jsonb_array_elements(v_ord->'rows') e where e->>'order_id' = v_order5::text;
  if v_res is null
     or (v_res->>'cogs_vnd')::bigint <> (v_row->>'cogs_at_sale_vnd')::bigint
     or (v_res->>'revenue_vnd')::bigint <> 160000
     or (v_res->>'gross_profit_vnd')::bigint <> 160000 - (v_res->>'cogs_vnd')::bigint then
    raise exception 'FAIL: r8_gross_profit_order order5 vs product row: % / %', v_res, v_row;
  end if;
  if (v_res->>'has_provisional')::boolean then
    raise exception 'FAIL: r8_gross_profit_order has_provisional must be false for a final cost';
  end if;
  if exists (select 1 from jsonb_array_elements(v_ord->'rows') e where e->>'order_id' = v_order1::text) then
    raise exception 'FAIL: r8_gross_profit_order cancelled order1 must not be listed';
  end if;
  update sales.sales_order_lines set cogs_is_provisional = true where tenant_id = v_t and sales_order_id = v_order5;
  v_ord := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'ORDER');
  select e into v_res from jsonb_array_elements(v_ord->'rows') e where e->>'order_id' = v_order5::text;
  if not (v_res->>'has_provisional')::boolean then
    raise exception 'FAIL: r8_gross_profit_order has_provisional must be true for provisional cogs';
  end if;
  perform pg_temp.expect_err(
    format('select inventory.get_gross_profit_report(%L, %L::date, %L::date, %L)', v_t, v_month_start, v_today, 'X'),
    'CONTEXT_INVALID', 'r8_gross_profit_order bad mode');

  -- r7_adjust_and_rebate: chèn thẳng dòng sổ / chiết khấu (số liệu tính giá vốn đã có test ở inventory_costing)
  v_run := gen_random_uuid();
  insert into inventory.cost_runs (id, tenant_id, code, kind, period_id, period_month, from_sequence, cut_off_sequence, cut_off_at, method, status, created_by, published_by, published_at)
  select v_run, v_t, 'GV-REP-01', 'MID_PERIOD', cp.id, cp.period_month, 0, 0, now(), 'MOVING', 'PUBLISHED', v_owner, v_owner, now()
  from inventory.cost_periods cp
  where cp.tenant_id = v_t and cp.period_month = v_month_start;
  if not found then
    raise exception 'FAIL: fixture cost period for current month not found';
  end if;
  insert into inventory.value_movements (tenant_id, ledger_sequence, product_id, kind, amount_vnd, cost_run_id, business_date, created_by)
  values
    (v_t, inventory._next_ledger_sequence(v_t), v_p_plain, 'COGS_TRUE_UP', -20000, v_run, v_today, v_owner),
    (v_t, inventory._next_ledger_sequence(v_t), v_p_lot, 'LOSS_TRUE_UP', -5000, v_run, v_today, v_owner);

  insert into inventory.supplier_programs (id, tenant_id, supplier_id, name, kind, status, started_on, target_qty, rebate_percent, progress_qty, created_by, updated_by)
  values (v_prog_vol, v_t, v_sup, 'Tích lũy báo cáo', 'VOLUME_REBATE', 'ACTIVE', v_today, 1000, 10.00, 0, v_owner, v_owner);
  insert into inventory.supplier_rebates (id, tenant_id, program_id, document_no, document_date, base_amount_vnd, proposed_amount_vnd, rebate_amount_vnd, business_date, recorded_by)
  values (v_rebate1, v_t, v_prog_vol, 'CK-REP-01', v_today, 100000, 3000, 3000, v_today, v_owner);
  insert into inventory.supplier_rebate_allocations (rebate_id, tenant_id, product_id, paid_qty, purchase_amount_vnd, rebate_part_vnd, on_hand_qty, inventory_part_vnd, cogs_part_vnd, avg_cost_before, avg_cost_after)
  values (v_rebate1, v_t, v_p_plain, 2, 100000, 3000, 0, 0, 3000, 50000, 50000);

  v_gp := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT');
  v_row := pg_temp.rep_row(v_gp->'rows', v_p_plain);
  if (v_row->>'cogs_adjust_vnd')::bigint <> 20000 or (v_row->>'rebate_vnd')::bigint <> 3000 then
    raise exception 'FAIL: r7_adjust_and_rebate adjust 20000 / rebate 3000, got %', v_row;
  end if;
  if (v_row->>'cogs_after_vnd')::bigint <> (v_row->>'cogs_at_sale_vnd')::bigint + 20000 - 3000 then
    raise exception 'FAIL: r7_adjust_and_rebate cogs_after = at_sale + adjust - rebate, got %', v_row;
  end if;
  if (v_gp->>'loss_vnd')::bigint <> v_loss_before + 5000 then
    raise exception 'FAIL: r7_adjust_and_rebate loss must include LOSS_TRUE_UP: expected %, got %', v_loss_before + 5000, v_gp->>'loss_vnd';
  end if;
  v_row := pg_temp.rep_row(v_gp->'rows', v_p_lot);
  if (v_row->>'cogs_adjust_vnd')::bigint <> 0 or (v_row->>'cogs_at_sale_vnd')::bigint <> 100000 then
    raise exception 'FAIL: r7_adjust_and_rebate loss rows/stocktake must not enter cogs, got %', v_row;
  end if;
  if (v_gp->'totals'->>'profit_after_loss')::bigint <> (v_gp->'totals'->>'gross_profit')::bigint - (v_gp->>'loss_vnd')::bigint then
    raise exception 'FAIL: r7_adjust_and_rebate profit_after_loss';
  end if;

  -- r9_supplier_purchase: bậc giảm giá + mua 10 tặng 1 + chi phí + chiết khấu thương mại
  insert into partner.partners (partner_id, tenant_id, partner_type, display_name, status, created_by, updated_by)
  values (v_sup2, v_t, 'organization', 'NCC Hai', 'active', v_owner, v_owner),
         (v_sup3, v_t, 'organization', 'NCC Chỉ Chiết Khấu', 'active', v_owner, v_owner);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values (v_sup2, v_t, 'supplier'), (v_sup3, v_t, 'supplier');
  insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
  values (v_p_tier, v_t, 'Hàng Bậc Giá', 'RP-TIER', 'none', false, 'active', true, 'RP-REF-TIER', v_owner, v_owner);
  insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
  values (v_u_tier, v_t, v_p_tier, 'hộp', 1, true);
  insert into inventory.supplier_programs (id, tenant_id, supplier_id, name, kind, status, started_on, created_by, updated_by)
  values (v_prog_tier, v_t, v_sup2, 'Bậc giá báo cáo', 'TIER_DISCOUNT', 'ACTIVE', v_today, v_owner, v_owner);
  insert into inventory.supplier_program_products (program_id, tenant_id, product_id) values (v_prog_tier, v_t, v_p_tier);
  insert into inventory.supplier_program_tiers (program_id, tenant_id, min_qty, discount_percent) values (v_prog_tier, v_t, 5, 5.00);

  v_res := inventory.record_goods_receipt(v_t, 'rep-gr-3', jsonb_build_object(
    'supplier_id', v_sup2,
    'freight_cost_vnd', 50000,
    'trade_discount_vnd', 20000,
    'lines', jsonb_build_array(
      jsonb_build_object('product_id', v_p_tier, 'unit_id', v_u_tier, 'unit_price_vnd', 100000,
        'free_qty', 1, 'program_id', v_prog_tier, 'tier_discount_percent', 5.00,
        -- quantity = tổng nhận (gồm hàng tặng) ⇒ mua 10 + tặng 1
        'lots', jsonb_build_array(jsonb_build_object('quantity', 11))))));

  insert into inventory.supplier_programs (id, tenant_id, supplier_id, name, kind, status, started_on, target_qty, rebate_percent, progress_qty, created_by, updated_by)
  values (v_prog_vol3, v_t, v_sup3, 'Tích lũy NCC ba', 'VOLUME_REBATE', 'ACTIVE', v_today, 1000, 10.00, 0, v_owner, v_owner);
  insert into inventory.supplier_rebates (id, tenant_id, program_id, document_no, document_date, base_amount_vnd, proposed_amount_vnd, rebate_amount_vnd, business_date, recorded_by)
  values (v_rebate3, v_t, v_prog_vol3, 'CK-REP-03', v_today, 50000, 1000, 1000, v_today, v_owner);

  v_res := inventory.get_supplier_purchase_report(v_t, v_month_start, v_today);
  select e into v_row from jsonb_array_elements(v_res->'suppliers') e where e->>'supplier_id' = v_sup2::text;
  if v_row is null then
    raise exception 'FAIL: r9_supplier_purchase supplier 2 missing: %', v_res;
  end if;
  if (v_row->>'purchase_vnd')::bigint <> (select sum(purchase_total_vnd) from inventory.goods_receipts where tenant_id = v_t and supplier_id = v_sup2)
     or (v_row->>'freight_vnd')::bigint <> 50000
     or (v_row->>'trade_discount_vnd')::bigint <> 20000
     or (v_row->>'landed_vnd')::bigint <> (select sum(landed_total_vnd) from inventory.goods_receipts where tenant_id = v_t and supplier_id = v_sup2)
     or (v_row->>'receipt_count')::int <> 1 then
    raise exception 'FAIL: r9_supplier_purchase header sums, got %', v_row;
  end if;
  if (v_row->'products'->0->>'paid_qty')::numeric <> 10 or (v_row->'products'->0->>'free_qty')::numeric <> 1 then
    raise exception 'FAIL: r9_supplier_purchase paid 10 / free 1, got %', v_row->'products';
  end if;
  if (v_row->'products'->0->>'avg_landed_unit_cost')::numeric <> round((v_row->'products'->0->>'landed_vnd')::numeric / 11, 4) then
    raise exception 'FAIL: r9_supplier_purchase avg_landed_unit_cost = landed / 11, got %', v_row->'products'->0;
  end if;
  select e into v_row from jsonb_array_elements(v_res->'suppliers') e where e->>'supplier_id' = v_sup::text;
  if (v_row->>'rebate_vnd')::bigint <> 3000 or (v_row->>'receipt_count')::int <> 2 then
    raise exception 'FAIL: r9_supplier_purchase supplier 1 rebate 3000 / 2 receipts, got %', v_row;
  end if;
  select e into v_row from jsonb_array_elements(v_res->'suppliers') e where e->>'supplier_id' = v_sup3::text;
  if v_row is null or (v_row->>'receipt_count')::int <> 0 or (v_row->>'rebate_vnd')::bigint <> 1000
     or jsonb_array_length(v_row->'products') <> 0 then
    raise exception 'FAIL: r9_supplier_purchase rebate-only supplier must appear with 0 receipts, got %', v_row;
  end if;
  if (v_res->'totals'->>'landed')::bigint <> (select sum(landed_total_vnd) from inventory.goods_receipts where tenant_id = v_t) then
    raise exception 'FAIL: r9_supplier_purchase totals.landed';
  end if;

  -- r5b_staff_gross_profit_ok (staff) + supplier purchases still owner-only
  perform set_config('request.jwt.claim.sub', v_staff::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff::text, 'role', 'authenticated')::text, true);
  -- r5b_staff_gross_profit_ok: AI-4 Task 4 mở lãi gộp cho mọi thành viên; số bằng của chủ cùng kỳ
  v_res := inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT');
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  if v_res->'totals' is null
     or (v_res->'totals'->>'net_revenue')::bigint
        is distinct from (inventory.get_gross_profit_report(v_t, v_month_start, v_today, 'PRODUCT')->'totals'->>'net_revenue')::bigint then
    raise exception 'FAIL: r5b_staff_gross_profit_ok staff totals must equal owner totals: %', v_res->'totals';
  end if;
  perform set_config('request.jwt.claim.sub', v_staff::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_staff::text, 'role', 'authenticated')::text, true);
  perform pg_temp.expect_err(
    format('select inventory.get_supplier_purchase_report(%L, %L::date, %L::date)', v_t, v_month_start, v_today),
    'PERMISSION_DENIED', 'r5b_staff_denied supplier purchases');
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);


  raise notice 'inventory_reports: OK';
end;
$$;
