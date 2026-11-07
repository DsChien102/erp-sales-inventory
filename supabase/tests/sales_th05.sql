-- TH-05 mục 9.3 "SQL / RPC test" (8-B1): checkout, thanh toán, huỷ đơn, đổi/trả, tìm đơn không dấu, đơn vị đã bán.
-- Chạy trên DB LOCAL sau `supabase db reset` (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/sales_th05.sql
-- Kết thúc bằng `raise notice 'sales_th05: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.
-- Ca đánh ✱ kiểm phần SỬA của 8-B1; còn lại kiểm hành vi đang có.
-- 8-B2 / 8-B3 sẽ thêm ca (tìm nháp, lọc người tạo, thu tiền) vào cuối tệp này.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (tạo trong giao dịch, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

-- Chạy một câu SQL, kỳ vọng lỗi chứa mã p_code (RPC sales ném JSON {"code": "..."}).
create function public._th05_expect_err(p_sql text, p_code text)
returns void
language plpgsql
as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm like '%"code": "' || p_code || '"%'
       or sqlerrm like '%"code":"' || p_code || '"%'
       or sqlerrm like p_code || '%' then
      return;
    end if;
    raise exception 'FAIL: expected [%] but got [%] for: %', p_code, sqlerrm, p_sql;
  end;
  raise exception 'FAIL: expected [%] but statement succeeded: %', p_code, p_sql;
end;
$$;

create function public._th05_customer(
  p_tenant uuid, p_actor uuid, p_name text, p_phone text
)
returns uuid
language sql
as $$
  select c.partner_id
  from partner.create_partner(
    p_tenant, p_actor, 'person', array['customer'],
    jsonb_build_object('full_name', p_name, 'phone', p_phone)
  ) c;
$$;

-- Dựng commercial snapshot từ p_lines rồi gọi sales.finalize_sales_order.
-- p_total_delta: cộng thêm vào lineTotal của dòng đầu để giả lập "giá đã đổi" (C04).
create function public._th05_finalize(
  p_tenant uuid, p_actor uuid, p_store uuid, p_customer uuid,
  p_lines jsonb, p_payments jsonb, p_due date, p_key text,
  p_source_draft uuid default null, p_source_version int default null,
  p_total_delta bigint default 0
)
returns jsonb
language plpgsql
as $$
declare
  v_snap_lines jsonb;
  v_snapshot jsonb;
begin
  select jsonb_agg(jsonb_build_object(
    'lineId', gen_random_uuid()::text,
    'product', jsonb_build_object('productId', l.value ->> 'product_id', 'displayName', 'SP'),
    'unit', jsonb_build_object('productUnitId', l.value ->> 'product_unit_id', 'unitName', 'DV'),
    'quantityMicros', (l.value ->> 'quantity_micros')::bigint,
    'lineTotal', jsonb_build_object(
      'amountMinor',
      (l.value -> 'unit_price' ->> 'amount_minor')::bigint
        * (l.value ->> 'quantity_micros')::bigint / 1000000
        + case when l.ordinality = 1 then p_total_delta else 0 end
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
    p_source_draft_id => p_source_draft,
    p_customer_id => p_customer,
    p_currency_code => 'VND',
    p_order_note => null,
    p_commercial_snapshot => v_snapshot,
    p_lines => p_lines,
    p_payment_intents => coalesce(p_payments, '[]'::jsonb),
    p_idempotency_key => p_key,
    p_payload_hash => 'h',
    p_correlation_id => gen_random_uuid()::text,
    p_payment_due_date => p_due,
    p_expected_source_version => p_source_version
  );
end;
$$;

create function public._th05_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create function public._th05_precheck(
  p_tenant uuid, p_actor uuid, p_store uuid, p_customer uuid,
  p_lines jsonb, p_payments jsonb, p_due date
)
returns jsonb
language sql
as $$
  select sales.precheck_sales_order_checkout(
    p_query_id => gen_random_uuid(),
    p_tenant_id => p_tenant,
    p_actor_id => p_actor,
    p_store_id => p_store,
    p_customer_id => p_customer,
    p_currency_code => 'VND',
    p_lines => p_lines,
    p_payment_intents => coalesce(p_payments, '[]'::jsonb),
    p_payment_due_date => p_due
  );
$$;

create function public._th05_has_blocker(p_precheck jsonb, p_code text)
returns boolean
language sql
as $$
  select exists (
    select 1 from jsonb_array_elements(p_precheck -> 'blockers') b where b ->> 'code' = p_code
  );
$$;

-- Dòng nháp đủ trường mà sales._write_draft_lines bắt buộc (20260830007:86-98).
create function public._th05_draft_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_sku', 'SKU-TH05', 'product_name', 'San pham TH05',
    'product_unit_id', p_unit, 'unit_code', 'DV', 'unit_name', 'Don vi',
    'quantity_micros', p_qty_micros,
    'applied_unit_price_minor', p_price,
    'line_total_minor', p_price * p_qty_micros / 1000000
  );
$$;

-- Huỷ đơn với version đang có của đơn + settlement (20260904001:394-406 bắt buộc cả hai).
create function public._th05_cancel(p_tenant uuid, p_actor uuid, p_order uuid, p_key text)
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
    sales_order_id => p_order, reason_text => 'TH05 test huy',
    idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text,
    expected_order_version => v_ov, expected_settlement_version => v_sv);
end;
$$;

create function public._th05_pay(p_amount bigint)
returns jsonb
language sql
as $$
  select jsonb_build_array(jsonb_build_object(
    'method', 'cash',
    'amount', jsonb_build_object('amount_minor', p_amount, 'currency_code', 'VND')
  ));
$$;

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();
  v_ta uuid;
  v_store uuid;
  v_claims text;
  v_res jsonb;
  v_r2 jsonb;
  v_p1 uuid;
  v_u1 uuid;
  v_p2 uuid;
  v_u2 uuid;
  v_u1_conv uuid;   -- đơn vị quy đổi của P1 (C17)
  v_u1_conv2 uuid;  -- đơn vị quy đổi (C18)
  v_u1_conv3 uuid;  -- đơn vị quy đổi (C19)
  v_anbinh uuid;
  v_khachb uuid;
  v_khachc uuid;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_line1 jsonb;
  v_line2 jsonb;
  v_order uuid;
  v_order2 uuid;
  v_n int;
  v_due date;
  v_draft jsonb;
  v_draft_id uuid;
  v_draft_ver int;
  v_ret jsonb;
  v_ret_id uuid;
  v_ret_ver int;
  v_orig_line uuid;
  v_unit_id uuid;
  v_msg text;
begin
  -- 0) Tenant + owner + JWT (như pricing_th04.sql)
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at
  ) values (
    v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'th05-' || v_ua::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Cua hang TH05 Sales Test', 'contact_phone', '0900000005',
      'contact_email', 'th05@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 5'
    )
  );
  if v_ta is null then
    raise exception 'FAIL: tenant was not created';
  end if;
  select s.id into v_store from catalog.stores s where s.tenant_id = v_ta limit 1;

  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  set local role authenticated;

  -- Sản phẩm P1 (100.000), P2 (150.000)
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_name => 'Thuoc P1 TH05',
    p_reference_id => 'TH05-P1', p_unit_name => 'Hop');
  v_p1 := (v_res ->> 'product_id')::uuid;
  select id into v_u1 from catalog.product_units where product_id = v_p1 and is_base_unit = true;
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta, p_product_id => v_p1, p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 100000, p_list_price_after_vat => 100000,
    p_floor_price_before_vat => 50000, p_floor_price_after_vat => 50000);

  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_name => 'Thuoc P2 TH05',
    p_reference_id => 'TH05-P2', p_unit_name => 'Hop');
  v_p2 := (v_res ->> 'product_id')::uuid;
  select id into v_u2 from catalog.product_units where product_id = v_p2 and is_base_unit = true;
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta, p_product_id => v_p2, p_product_unit_id => v_u2,
    p_source_type => 'manual',
    p_list_price_before_vat => 150000, p_list_price_after_vat => 150000,
    p_floor_price_before_vat => 70000, p_floor_price_after_vat => 70000);

  -- Sản phẩm phải bán được; nếu chưa thì bật (giao dịch rollback cuối tệp).
  if exists (select 1 from catalog.products
             where id in (v_p1, v_p2) and is_ready_to_sell is not true) then
    reset role;
    update catalog.products set is_ready_to_sell = true where id in (v_p1, v_p2);
    set local role authenticated;
    raise notice 'sales_th05: is_ready_to_sell phải bật tay cho P1/P2';
  end if;

  -- Đơn vị quy đổi cho C17–C19 (add_product_conversion_unit trả {unit:{id}} như catalog_th02.sql:288)
  v_res := catalog.add_product_conversion_unit(v_ta, v_p1, 'Thung', 10);
  v_u1_conv := (v_res -> 'unit' ->> 'id')::uuid;
  v_res := catalog.add_product_conversion_unit(v_ta, v_p1, 'Loc', 5);
  v_u1_conv2 := (v_res -> 'unit' ->> 'id')::uuid;
  v_res := catalog.add_product_conversion_unit(v_ta, v_p1, 'Bich', 3);
  v_u1_conv3 := (v_res -> 'unit' ->> 'id')::uuid;
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta, p_product_id => v_p1, p_product_unit_id => v_u1_conv,
    p_source_type => 'manual',
    p_list_price_before_vat => 1000000, p_list_price_after_vat => 1000000,
    p_floor_price_before_vat => 500000, p_floor_price_after_vat => 500000);

  -- Khách
  v_anbinh := public._th05_customer(v_ta, v_ua, 'Đại lý An Bình', '0911000001');
  v_khachb := public._th05_customer(v_ta, v_ua, 'Khach B', '0911000002');
  v_khachc := public._th05_customer(v_ta, v_ua, 'Khach C', '0911000003');

  v_line1 := public._th05_line(v_p1, v_u1, 1000000, 100000);       -- 1 × P1 = 100.000
  v_line2 := public._th05_line(v_p2, v_u2, 1000000, 150000);       -- 1 × P2 = 150.000

  -- =========================================================================
  -- C01 Idempotency: cùng key, cùng nội dung → cùng đơn
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, null,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c01-key');
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: C01 first finalize not succeeded: %', v_res;
  end if;
  v_r2 := public._th05_finalize(v_ta, v_ua, v_store, null,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c01-key');
  if v_r2 ->> 'salesOrderId' is distinct from v_res ->> 'salesOrderId' then
    raise exception 'FAIL: C01 replay returned different order: % vs %', v_res, v_r2;
  end if;
  select count(*) into v_n from sales.sales_orders where tenant_id = v_ta;
  if v_n <> 1 then
    raise exception 'FAIL: C01 expected 1 order, got %', v_n;
  end if;

  -- =========================================================================
  -- C02 Cùng key, khác số lượng → IDEMPOTENCY_CONFLICT
  -- =========================================================================
  perform public._th05_expect_err(
    format($f$select public._th05_finalize(%L, %L, %L, null, %L::jsonb, %L::jsonb, null, 'c01-key')$f$,
      v_ta, v_ua, v_store,
      jsonb_build_array(public._th05_line(v_p1, v_u1, 2000000, 100000))::text,
      public._th05_pay(200000)::text),
    'IDEMPOTENCY_CONFLICT');
  -- Ghi chú đoán: nếu RPC trả JSON status='failed' thay vì ném lỗi, ca này FAIL và cần sửa test.

  -- =========================================================================
  -- C03 STALE_VERSION: nháp version cũ
  -- =========================================================================
  v_draft := sales.save_sales_order_draft(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_store_id => v_store,
    p_customer => null, p_currency_code => 'VND',
    p_lines => jsonb_build_array(public._th05_draft_line(v_p1, v_u1, 1000000, 100000)),
    p_idempotency_key => 'c03-draft');
  v_draft_id := (v_draft ->> 'draft_id')::uuid;
  v_draft_ver := (v_draft ->> 'version')::int;
  select count(*) into v_n from sales.sales_orders where tenant_id = v_ta;
  v_res := public._th05_finalize(v_ta, v_ua, v_store, null,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c03-key',
    v_draft_id, v_draft_ver - 1);
  if v_res ->> 'status' is distinct from 'blocked' or v_res ->> 'blockedCode' is distinct from 'STALE_VERSION' then
    raise exception 'FAIL: C03 expected blocked/STALE_VERSION, got %', v_res;
  end if;
  if (select count(*) from sales.sales_orders where tenant_id = v_ta) <> v_n then
    raise exception 'FAIL: C03 created an order despite STALE_VERSION';
  end if;

  -- =========================================================================
  -- C04 ✱ PRICE_CHANGED: lineTotal của snapshot khác tiền server
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, null,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c04-key',
    null, null, 1000);
  if v_res ->> 'status' is distinct from 'blocked' or v_res ->> 'blockedCode' is distinct from 'PRICE_CHANGED' then
    raise exception 'FAIL: C04 expected blocked/PRICE_CHANGED, got %', v_res;
  end if;

  -- =========================================================================
  -- C05 ✱ Khách ngừng hoạt động → CUSTOMER_INVALID (precheck + finalize)
  -- =========================================================================
  reset role;
  update partner.partners set status = 'inactive' where partner_id = v_khachb;
  set local role authenticated;

  v_res := public._th05_precheck(v_ta, v_ua, v_store, v_khachb,
    jsonb_build_array(v_line1), public._th05_pay(100000), null);
  if (v_res ->> 'canFinalize')::boolean is not false
     or not public._th05_has_blocker(v_res, 'CUSTOMER_INVALID') then
    raise exception 'FAIL: C05 precheck expected CUSTOMER_INVALID, got %', v_res;
  end if;
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_khachb,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c05-key');
  if v_res ->> 'status' is distinct from 'blocked' or v_res ->> 'blockedCode' is distinct from 'CUSTOMER_INVALID' then
    raise exception 'FAIL: C05 finalize expected blocked/CUSTOMER_INVALID, got %', v_res;
  end if;
  -- Khách lẻ không sinh CUSTOMER_INVALID (Review Focus 3)
  v_res := public._th05_precheck(v_ta, v_ua, v_store, null,
    jsonb_build_array(v_line1), public._th05_pay(100000), null);
  if public._th05_has_blocker(v_res, 'CUSTOMER_INVALID') then
    raise exception 'FAIL: C05 walk-in precheck must not raise CUSTOMER_INVALID: %', v_res;
  end if;

  -- =========================================================================
  -- C06 ✱ Partner active nhưng vai trò customer is_active = false
  -- =========================================================================
  reset role;
  update partner.partner_roles set is_active = false
    where partner_id = v_khachc and role = 'customer';
  set local role authenticated;

  v_res := public._th05_precheck(v_ta, v_ua, v_store, v_khachc,
    jsonb_build_array(v_line1), public._th05_pay(100000), null);
  if (v_res ->> 'canFinalize')::boolean is not false
     or not public._th05_has_blocker(v_res, 'CUSTOMER_INVALID') then
    raise exception 'FAIL: C06 precheck expected CUSTOMER_INVALID, got %', v_res;
  end if;
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_khachc,
    jsonb_build_array(v_line1), public._th05_pay(100000), null, 'c06-key');
  if v_res ->> 'blockedCode' is distinct from 'CUSTOMER_INVALID' then
    raise exception 'FAIL: C06 finalize expected CUSTOMER_INVALID, got %', v_res;
  end if;

  -- =========================================================================
  -- C07 ✱ Còn nợ, ngày hẹn = hôm nay VN − 1 → RECEIVABLE_DUE_DATE_INVALID
  -- =========================================================================
  v_res := public._th05_precheck(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(v_line1), null, v_today - 1);
  if not public._th05_has_blocker(v_res, 'RECEIVABLE_DUE_DATE_INVALID') then
    raise exception 'FAIL: C07 precheck expected RECEIVABLE_DUE_DATE_INVALID, got %', v_res;
  end if;
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(v_line1), null, v_today - 1, 'c07-key');
  if v_res ->> 'status' is distinct from 'blocked'
     or v_res ->> 'blockedCode' is distinct from 'RECEIVABLE_DUE_DATE_INVALID' then
    raise exception 'FAIL: C07 finalize expected blocked/RECEIVABLE_DUE_DATE_INVALID, got %', v_res;
  end if;

  -- =========================================================================
  -- C08 ✱ Ngày hẹn = hôm nay VN → succeeded, lưu payment_due_date
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(v_line1), null, v_today, 'c08-key');
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: C08 expected succeeded, got %', v_res;
  end if;
  select payment_due_date into v_due from sales.sales_orders
    where id = (v_res ->> 'salesOrderId')::uuid;
  if v_due is distinct from v_today then
    raise exception 'FAIL: C08 payment_due_date expected %, got %', v_today, v_due;
  end if;

  -- =========================================================================
  -- C09 Thu vượt outstanding → OVERPAYMENT_NOT_ALLOWED (đơn nợ 100% của An Bình)
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(v_line1), null, v_today + 7, 'c09-key');
  v_order := (v_res ->> 'salesOrderId')::uuid;
  perform public._th05_expect_err(
    format($f$select sales.record_sales_payment(%L, %L, %L, %L, 100001, 'cash', 'c09-pay', 'h')$f$,
      v_ta, v_ua, v_store, v_order),
    'OVERPAYMENT_NOT_ALLOWED');

  -- =========================================================================
  -- C10 Huỷ đơn C09 → current_payable = 0; thu tiếp → ORDER_CANCELLED
  -- =========================================================================
  v_r2 := sales.precheck_sales_order_cancellation(
    query_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    sales_order_id => v_order);
  v_r2 := public._th05_cancel(v_ta, v_ua, v_order, 'c10-cancel');
  if (select current_payable_amount_minor from sales.sales_order_settlements
      where tenant_id = v_ta and sales_order_id = v_order) is distinct from 0 then
    raise exception 'FAIL: C10 current_payable_amount_minor not 0 after cancel';
  end if;
  perform public._th05_expect_err(
    format($f$select sales.record_sales_payment(%L, %L, %L, %L, 1000, 'cash', 'c10-pay', 'h')$f$,
      v_ta, v_ua, v_store, v_order),
    'ORDER_CANCELLED');

  -- =========================================================================
  -- C11 Đơn đã thu 1 phần → huỷ bị chặn (PAYMENT_ALREADY_COLLECTED)
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(v_line1), public._th05_pay(40000), v_today + 7, 'c11-key');
  v_order := (v_res ->> 'salesOrderId')::uuid;
  begin
    perform public._th05_cancel(v_ta, v_ua, v_order, 'c11-cancel');
    raise exception 'FAIL: C11 cancel of partially-paid order should be blocked';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%CANCELLATION_BLOCKED%' then
      raise exception 'FAIL: C11 expected CANCELLATION_BLOCKED, got [%]', sqlerrm;
    end if;
    if sqlerrm not like '%PAYMENT_ALREADY_COLLECTED%' then
      raise exception 'FAIL: C11 expected reason PAYMENT_ALREADY_COLLECTED, got [%]', sqlerrm;
    end if;
  end;

  -- =========================================================================
  -- C12 Đơn có phiếu đổi/trả đã xác nhận → huỷ: RETURN_EXCHANGE_CONFLICT
  -- C14 ✱ + C15 ✱ cũng dùng đơn này (trả 1 P1, đổi 1 P2, còn nợ)
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(public._th05_line(v_p1, v_u1, 3000000, 100000)),
    public._th05_pay(300000), null, 'c12-key');
  v_order2 := (v_res ->> 'salesOrderId')::uuid;
  select id into v_orig_line from sales.sales_order_lines
    where tenant_id = v_ta and sales_order_id = v_order2 limit 1;

  -- C15 trước: ngày hẹn quá khứ bị chặn (phiếu 1, chưa xác nhận được)
  v_ret := sales.start_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    sales_order_id => v_order2, entry_source => 'standard',
    lines => jsonb_build_array(
      jsonb_build_object('kind', 'returnLine', 'original_sales_order_line_id', v_orig_line,
        'product_id', v_p1, 'product_unit_id', v_u1, 'quantity_micros', 1000000,
        'reason_code', 'OTHER', 'condition_code', 'GOOD'),
      jsonb_build_object('kind', 'exchangeLine', 'product_id', v_p2,
        'product_unit_id', v_u2, 'quantity_micros', 1000000)),
    idempotency_key => 'c14-start', payload_hash => 'h',
    correlation_id => gen_random_uuid()::text,
    reference_decision => jsonb_build_object('exchange_prices_by_product_unit_id',
      jsonb_build_object(v_u2::text, jsonb_build_object('amountMinor', 150000))));
  v_ret_id := (v_ret ->> 'returnExchangeId')::uuid;
  v_ret_ver := (v_ret ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(
    query_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    return_exchange_id => v_ret_id);

  begin
    perform sales.confirm_return_exchange(
      command_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
      return_exchange_id => v_ret_id, idempotency_key => 'c15-confirm', payload_hash => 'h',
      correlation_id => gen_random_uuid()::text, expected_version => v_ret_ver,
      payment_settled_now_minor => 0, payment_due_date => v_today - 1);   -- C15 ✱
    raise exception 'FAIL: C15 confirm with past due date should be blocked';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    -- RETURN_EXCHANGE_BLOCKED dùng chung cho nhiều chỗ chặn ⇒ kiểm đúng câu của ngày hẹn.
    if sqlerrm not like '%RETURN_EXCHANGE_BLOCKED%'
       or sqlerrm not like '%Payment due date cannot be before today%' then
      raise exception 'FAIL: C15 expected due-date block, got [%]', sqlerrm;
    end if;
  end;

  -- C14 ✱: ngày hẹn hợp lệ → lưu vào đơn
  perform sales.confirm_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    return_exchange_id => v_ret_id, idempotency_key => 'c14-confirm', payload_hash => 'h',
    correlation_id => gen_random_uuid()::text, expected_version => v_ret_ver,
    payment_settled_now_minor => 0, payment_due_date => v_today + 7);
  select payment_due_date into v_due from sales.sales_orders where id = v_order2;
  if v_due is distinct from v_today + 7 then
    raise exception 'FAIL: C14 payment_due_date expected %, got %', v_today + 7, v_due;
  end if;

  -- C12: đơn đã có phiếu đổi/trả xác nhận → CANCELLATION_BLOCKED, details.reason RETURN_EXCHANGE_CONFLICT
  begin
    perform public._th05_cancel(v_ta, v_ua, v_order2, 'c12-cancel');
    raise exception 'FAIL: C12 cancel of an order with a confirmed return/exchange should be blocked';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%CANCELLATION_BLOCKED%' or sqlerrm not like '%RETURN_EXCHANGE_CONFLICT%' then
      raise exception 'FAIL: C12 expected CANCELLATION_BLOCKED/RETURN_EXCHANGE_CONFLICT, got [%]', sqlerrm;
    end if;
  end;

  -- =========================================================================
  -- C13 Hai phiếu trả cùng dòng vượt số bán → RETURN_QUANTITY_EXCEEDED
  -- (đơn mới: bán 2, phiếu 1 trả 2 và xác nhận, phiếu 2 trả 1)
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, v_anbinh,
    jsonb_build_array(public._th05_line(v_p1, v_u1, 2000000, 100000)),
    public._th05_pay(200000), null, 'c13-key');
  v_order := (v_res ->> 'salesOrderId')::uuid;
  select id into v_orig_line from sales.sales_order_lines
    where tenant_id = v_ta and sales_order_id = v_order limit 1;
  v_ret := sales.start_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    sales_order_id => v_order, entry_source => 'standard',
    lines => jsonb_build_array(jsonb_build_object(
      'kind', 'returnLine', 'original_sales_order_line_id', v_orig_line,
      'product_id', v_p1, 'product_unit_id', v_u1, 'quantity_micros', 2000000,
      'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    idempotency_key => 'c13-start-1', payload_hash => 'h',
    correlation_id => gen_random_uuid()::text);
  -- Phiếu nháp không giữ số lượng (start_return_exchange chỉ cộng phiếu đã xác nhận) ⇒ xác nhận phiếu 1.
  v_ret_id := (v_ret ->> 'returnExchangeId')::uuid;
  v_ret_ver := (v_ret ->> 'version')::int;
  perform sales.evaluate_return_exchange_valuation(
    query_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    return_exchange_id => v_ret_id);
  perform sales.confirm_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    return_exchange_id => v_ret_id, idempotency_key => 'c13-confirm-1', payload_hash => 'h',
    correlation_id => gen_random_uuid()::text, expected_version => v_ret_ver);
  perform public._th05_expect_err(
    format($f$select sales.start_return_exchange(
      command_id => %L, tenant_id => %L, actor_id => %L, sales_order_id => %L,
      entry_source => 'standard',
      lines => %L::jsonb,
      idempotency_key => 'c13-start-2', payload_hash => 'h', correlation_id => %L)$f$,
      gen_random_uuid()::text, v_ta, v_ua, v_order,
      jsonb_build_array(jsonb_build_object(
        'kind', 'returnLine', 'original_sales_order_line_id', v_orig_line,
        'product_id', v_p1, 'product_unit_id', v_u1, 'quantity_micros', 1000000,
        'reason_code', 'OTHER', 'condition_code', 'GOOD'))::text,
      gen_random_uuid()::text),
    'RETURN_QUANTITY_EXCEEDED');

  -- =========================================================================
  -- C16 ✱ Tìm đơn không dấu
  -- =========================================================================
  v_res := sales.search_sales_orders(
    query_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    search_text => 'an binh');
  if jsonb_array_length(coalesce(v_res -> 'items', '[]'::jsonb)) = 0 then
    raise exception 'FAIL: C16 search "an binh" returned no orders: %', v_res;
  end if;
  -- Mã đơn chữ thường vẫn tìm được (Review Focus 5)
  v_res := sales.search_sales_orders(
    query_id => gen_random_uuid()::text, tenant_id => v_ta, actor_id => v_ua,
    search_text => 'dh' || to_char(v_today, 'YYYYMMDD'));
  if jsonb_array_length(coalesce(v_res -> 'items', '[]'::jsonb)) = 0 then
    raise exception 'FAIL: C16 search by lowercase order code returned nothing: %', v_res;
  end if;

  -- =========================================================================
  -- C17 ✱ Xoá đơn vị quy đổi đã nằm trong dòng đơn bán → bị chặn
  -- =========================================================================
  v_res := public._th05_finalize(v_ta, v_ua, v_store, null,
    jsonb_build_array(public._th05_line(v_p1, v_u1_conv, 1000000, 1000000)),
    public._th05_pay(1000000), null, 'c17-key');
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: C17 setup finalize with conversion unit failed: %', v_res;
  end if;
  begin
    perform catalog.delete_product_conversion_unit(v_ta, v_p1, v_u1_conv);
    raise exception 'FAIL: C17 delete of a sold conversion unit should be blocked';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%Đơn vị đã được dùng trong giao dịch%' then
      raise exception 'FAIL: C17 unexpected error [%]', sqlerrm;
    end if;
  end;

  -- =========================================================================
  -- C18 ✱ Đơn vị chỉ nằm trong dòng nháp đã huỷ → xoá được
  -- C19 ✱ Đơn vị nằm trong dòng nháp active → bị chặn
  -- =========================================================================
  v_draft := sales.save_sales_order_draft(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_store_id => v_store,
    p_customer => null, p_currency_code => 'VND',
    p_lines => jsonb_build_array(public._th05_draft_line(v_p1, v_u1_conv2, 1000000, 100000)),
    p_idempotency_key => 'c18-draft');
  v_draft_id := (v_draft ->> 'draft_id')::uuid;
  v_draft_ver := (v_draft ->> 'version')::int;
  perform sales.cancel_sales_order_draft(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_draft_id => v_draft_id,
    p_store_id => v_store, p_expected_version => v_draft_ver,
    p_idempotency_key => 'c18-cancel');
  perform catalog.delete_product_conversion_unit(v_ta, v_p1, v_u1_conv2);   -- C18: không ném lỗi
  if exists (select 1 from catalog.product_units where id = v_u1_conv2) then
    raise exception 'FAIL: C18 conversion unit still exists after delete';
  end if;

  perform sales.save_sales_order_draft(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_store_id => v_store,
    p_customer => null, p_currency_code => 'VND',
    p_lines => jsonb_build_array(public._th05_draft_line(v_p1, v_u1_conv3, 1000000, 100000)),
    p_idempotency_key => 'c19-draft');
  begin
    perform catalog.delete_product_conversion_unit(v_ta, v_p1, v_u1_conv3);
    raise exception 'FAIL: C19 delete of a unit in an active draft should be blocked';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
    if sqlerrm not like '%Đơn vị đã được dùng trong giao dịch%' then
      raise exception 'FAIL: C19 unexpected error [%]', sqlerrm;
    end if;
  end;

  raise notice 'sales_th05: OK';
end;
$$;

rollback;
