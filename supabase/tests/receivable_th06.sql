-- T6-1b: công nợ theo khách, thu theo khách (phần A), cấn trừ khi đổi/trả (phần B).
-- Chạy trên DB LOCAL sau `supabase db reset` (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/receivable_th06.sql
-- Cuối tệp: raise notice 'receivable_th06: OK'; ca sai đều `raise exception 'FAIL: …'`.
-- Thứ tự thực thi trong tệp không đúng thứ tự số ca (A15 chạy ngay sau A07, A08b / A04b ở cuối)
-- vì các ca dùng chung một bộ dữ liệu; nhãn trong thông báo lỗi luôn theo mã ca.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (tạo trong giao dịch, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

create function public._th06_expect_err(p_sql text, p_code text)
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

create function public._th06_expect(p_label text, p_actual text, p_expected text)
returns void
language plpgsql
as $$
begin
  if p_actual is distinct from p_expected then
    raise exception 'FAIL: % expected [%] got [%]', p_label, p_expected, p_actual;
  end if;
end;
$$;

-- Đọc một giá trị bằng quyền chủ (bảng sales / receivable bật RLS không policy), rồi trả vai authenticated.
create function public._th06_val(p_sql text)
returns text
language plpgsql
as $$
declare
  v text;
begin
  reset role;
  execute p_sql into v;
  set local role authenticated;
  return v;
end;
$$;

create function public._th06_customer(
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

create function public._th06_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create function public._th06_pay(p_amount bigint)
returns jsonb
language sql
as $$
  select jsonb_build_array(jsonb_build_object(
    'method', 'cash',
    'amount', jsonb_build_object('amount_minor', p_amount, 'currency_code', 'VND')
  ));
$$;

create function public._th06_finalize(
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
    p_payment_due_date => p_due,
    p_expected_source_version => null
  );
end;
$$;

-- Một đơn p_units đơn vị × 100.000, đã thu p_paid. Trả id đơn.
create function public._th06_order(
  p_tenant uuid, p_actor uuid, p_store uuid, p_customer uuid,
  p_product uuid, p_unit uuid, p_units int, p_paid bigint, p_due date, p_key text
)
returns uuid
language plpgsql
as $$
declare
  v_res jsonb;
begin
  v_res := public._th06_finalize(
    p_tenant, p_actor, p_store, p_customer,
    jsonb_build_array(public._th06_line(p_product, p_unit, p_units::bigint * 1000000, 100000)),
    case when p_paid > 0 then public._th06_pay(p_paid) else null end,
    p_due, p_key);
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: setup đơn % không thành công: %', p_key, v_res;
  end if;
  return (v_res ->> 'salesOrderId')::uuid;
end;
$$;

-- Chỉnh lùi ngày hoàn tất và ngày hẹn (finalize không cho hẹn quá khứ).
create function public._th06_set(p_order uuid, p_days_ago int, p_due date)
returns void
language plpgsql
as $$
begin
  reset role;
  update sales.sales_orders
  set completed_at = now() - make_interval(days => p_days_ago)
  where id = p_order;
  update receivable.sales_order_settlements
  set payment_due_date = p_due
  where sales_order_id = p_order;
  set local role authenticated;
end;
$$;

-- Bất biến TH-06 3.5 (0)…(6).
create function public._th06_invariants(p_tenant uuid, p_label text)
returns void
language plpgsql
as $$
declare
  v_n int;
  v_actor uuid := current_setting('request.jwt.claim.sub')::uuid;
  r record;
  v_rpc bigint;
begin
  reset role;

  -- (0) công thức quyết toán + (5) net_collected không vượt current_payable
  select count(*) into v_n
  from receivable.sales_order_settlements s
  join sales.sales_orders so on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
  where s.tenant_id = p_tenant
    and (
      s.original_payable_amount_minor <> so.payable_amount_minor
      or s.current_payable_amount_minor <> s.original_payable_amount_minor + coalesce((
          select sum(a.amount_minor) from receivable.settlement_obligation_adjustments a
          where a.tenant_id = s.tenant_id and a.sales_order_settlement_id = s.id), 0)
      or s.collected_amount_minor <> coalesce((
          select sum(t.amount_minor) from receivable.sales_payment_transactions t
          where t.tenant_id = s.tenant_id and t.sales_order_settlement_id = s.id
            and t.transaction_type = 'collection' and t.status = 'confirmed'), 0)
      or s.refunded_amount_minor <> coalesce((
          select sum(t.amount_minor) from receivable.sales_payment_transactions t
          where t.tenant_id = s.tenant_id and t.sales_order_settlement_id = s.id
            and t.transaction_type = 'refund' and t.status = 'confirmed'), 0)
      or s.outstanding_amount_minor
         <> greatest(s.current_payable_amount_minor
              - (s.collected_amount_minor - s.refunded_amount_minor), 0)
      or (s.current_payable_amount_minor >= 0
          and s.net_collected_amount_minor > s.current_payable_amount_minor)
    );
  if v_n <> 0 then
    raise exception 'FAIL: % bất biến (0)/(5): % quyết toán sai', p_label, v_n;
  end if;

  select count(*) into v_n
  from sales.sales_orders so
  where so.tenant_id = p_tenant
    and (select count(*) from receivable.sales_order_settlements s
         where s.tenant_id = so.tenant_id and s.sales_order_id = so.id) <> 1;
  if v_n <> 0 then
    raise exception 'FAIL: % bất biến (0): % đơn không có đúng 1 quyết toán', p_label, v_n;
  end if;

  -- (1) công nợ khách (RPC) = Σ outstanding đơn completed ở cửa hàng truy cập được
  for r in
    select so.customer_partner_id as cid, sum(s.outstanding_amount_minor)::bigint as total
    from sales.sales_orders so
    join receivable.sales_order_settlements s on s.tenant_id = so.tenant_id and s.sales_order_id = so.id
    join iam.stores st on st.tenant_id = so.tenant_id and st.id = so.store_id and st.status = 'active'
    where so.tenant_id = p_tenant and so.lifecycle_status = 'completed'
      and so.customer_partner_id is not null
    group by so.customer_partner_id
  loop
    set local role authenticated;
    v_rpc := (receivable.get_customer_receivable_summary(p_tenant, v_actor, r.cid)
              ->> 'outstandingMinor')::bigint;
    reset role;
    if v_rpc is distinct from r.total then
      raise exception 'FAIL: % bất biến (1): khách % RPC % ≠ tổng đơn %', p_label, r.cid, v_rpc, r.total;
    end if;
  end loop;

  -- (2) mỗi lần thu = Σ giao dịch của nó, cùng khách, cùng phương thức
  select count(*) into v_n
  from receivable.customer_collections cc
  where cc.tenant_id = p_tenant
    and (
      cc.amount_minor <> coalesce((
        select sum(t.amount_minor) from receivable.sales_payment_transactions t
        where t.tenant_id = cc.tenant_id and t.source_type = 'customer_collection'
          and t.source_id = cc.id), 0)
      or exists (
        select 1 from receivable.sales_payment_transactions t
        join receivable.sales_order_settlements s on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
        join sales.sales_orders so on so.tenant_id = s.tenant_id and so.id = s.sales_order_id
        where t.tenant_id = cc.tenant_id and t.source_type = 'customer_collection'
          and t.source_id = cc.id
          and (so.customer_partner_id <> cc.customer_partner_id
               or t.payment_method_code <> cc.payment_method_code))
    );
  if v_n <> 0 then
    raise exception 'FAIL: % bất biến (2): % lần thu lệch', p_label, v_n;
  end if;

  -- (3) mỗi cấn trừ có đúng 1 refund offset ở nguồn và 1 collection offset ở nhận, cùng số tiền
  select count(*) into v_n
  from receivable.receivable_offsets o
  where o.tenant_id = p_tenant
    and not (
      exists (
        select 1 from receivable.sales_payment_transactions t
        join receivable.sales_order_settlements s on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
        where t.id = o.source_refund_transaction_id and t.transaction_type = 'refund'
          and t.payment_method_code = 'offset' and t.amount_minor = o.amount_minor
          and s.sales_order_id = o.source_sales_order_id and t.source_id = o.id)
      and exists (
        select 1 from receivable.sales_payment_transactions t
        join receivable.sales_order_settlements s on s.tenant_id = t.tenant_id and s.id = t.sales_order_settlement_id
        where t.id = o.target_collection_transaction_id and t.transaction_type = 'collection'
          and t.payment_method_code = 'offset' and t.amount_minor = o.amount_minor
          and s.sales_order_id = o.target_sales_order_id and t.source_id = o.id)
    );
  if v_n <> 0 then
    raise exception 'FAIL: % bất biến (3): % cấn trừ không đủ cặp giao dịch', p_label, v_n;
  end if;

  -- (4) Σ offset chiều vào = Σ chiều ra
  if (select coalesce(sum(amount_minor) filter (where direction = 'inflow'), 0)
        - coalesce(sum(amount_minor) filter (where direction = 'outflow'), 0)
      from receivable.sales_payment_transactions
      where tenant_id = p_tenant and payment_method_code = 'offset') <> 0 then
    raise exception 'FAIL: % bất biến (4): offset vào ≠ ra', p_label;
  end if;

  -- (6) không giao dịch offset nào ngoài cặp của một receivable_offsets
  select count(*) into v_n
  from receivable.sales_payment_transactions t
  where t.tenant_id = p_tenant and t.payment_method_code = 'offset'
    and t.id not in (
      select source_refund_transaction_id from receivable.receivable_offsets where tenant_id = p_tenant
      union
      select target_collection_transaction_id from receivable.receivable_offsets where tenant_id = p_tenant);
  if v_n <> 0 then
    raise exception 'FAIL: % bất biến (6): % giao dịch offset mồ côi', p_label, v_n;
  end if;

  set local role authenticated;
end;
$$;


-- Phần B: lập phiếu trả hàng (start + evaluate) và xác nhận.
create function public._th06_return(
  p_tenant uuid, p_actor uuid, p_order uuid, p_product uuid, p_unit uuid, p_units int, p_key text
)
returns jsonb
language plpgsql
as $$
declare
  v_line uuid;
  v_ret jsonb;
  v_eval jsonb;
begin
  reset role;
  select id into v_line from sales.sales_order_lines
    where tenant_id = p_tenant and sales_order_id = p_order limit 1;
  set local role authenticated;
  v_ret := sales.start_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    sales_order_id => p_order, entry_source => 'standard',
    lines => jsonb_build_array(jsonb_build_object(
      'kind', 'returnLine', 'original_sales_order_line_id', v_line,
      'product_id', p_product, 'product_unit_id', p_unit,
      'quantity_micros', p_units::bigint * 1000000,
      'reason_code', 'OTHER', 'condition_code', 'GOOD')),
    idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text);
  v_eval := sales.evaluate_return_exchange_valuation(
    query_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    return_exchange_id => (v_ret ->> 'returnExchangeId')::uuid);
  return jsonb_build_object(
    'id', v_ret ->> 'returnExchangeId', 'version', v_ret ->> 'version', 'eval', v_eval);
end;
$$;

-- p_offsets null = không truyền tham số offset_target_order_ids.
create function public._th06_confirm(
  p_tenant uuid, p_actor uuid, p_rx uuid, p_ver int, p_key text, p_offsets uuid[]
)
returns jsonb
language plpgsql
as $$
begin
  if p_offsets is null then
    return sales.confirm_return_exchange(
      command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
      return_exchange_id => p_rx, idempotency_key => p_key, payload_hash => 'h',
      correlation_id => gen_random_uuid()::text, expected_version => p_ver);
  end if;
  return sales.confirm_return_exchange(
    command_id => gen_random_uuid()::text, tenant_id => p_tenant, actor_id => p_actor,
    return_exchange_id => p_rx, idempotency_key => p_key, payload_hash => 'h',
    correlation_id => gen_random_uuid()::text, expected_version => p_ver,
    offset_target_order_ids => p_offsets);
end;
$$;

-- Số giao dịch của một đơn theo loại / phương thức / (tuỳ chọn) số tiền.
create function public._th06_txn(p_order uuid, p_type text, p_method text, p_amount bigint)
returns text
language sql
as $$
  select public._th06_val(format(
    'select count(*) from receivable.sales_payment_transactions t
     join receivable.sales_order_settlements s on s.id = t.sales_order_settlement_id
     where s.sales_order_id = %L and t.transaction_type = %L and t.payment_method_code = %L
       and (%L::bigint is null or t.amount_minor = %L::bigint)',
    p_order, p_type, p_method, p_amount, p_amount));
$$;

create function public._th06_out(p_order uuid)
returns text
language sql
as $$
  select public._th06_val(format(
    'select outstanding_amount_minor from receivable.sales_order_settlements where sales_order_id = %L', p_order));
$$;

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();
  v_ta uuid;
  v_store uuid;
  v_store2 uuid := gen_random_uuid();
  v_res jsonb;
  v_r2 jsonb;
  v_p1 uuid;
  v_u1 uuid;
  v_unit_id uuid;
  v_wh uuid;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_tuan uuid;
  v_hung uuid;
  v_lan uuid;
  v_het uuid;
  v_o1 uuid;
  v_o2 uuid;
  v_o3 uuid;
  v_ohung uuid;
  v_olan uuid;
  v_olan_paid uuid;
  v_owalk uuid;
  v_ocancel uuid;
  v_ohidden uuid;
  v_ohet uuid;
  v_summary_a01 jsonb;
  v_order_a01 jsonb;
  v_cid uuid;
  v_cid2 uuid;
  v_n_cc bigint;
  v_n_tx bigint;
  v_rc_before int;
  v_ids uuid[];
  v_cursor text;
  v_pages int;
  v_x1 uuid;
  v_x2 uuid;
  v_it jsonb;
  v_found boolean;
begin
  -- 0) Tenant + owner + JWT
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at
  ) values (
    v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'th06-' || v_ua::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );
  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Cua hang TH06 Test', 'contact_phone', '0900000006',
      'contact_email', 'th06@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 6'
    )
  );
  select s.id into v_store from iam.stores s where s.tenant_id = v_ta limit 1;

  perform set_config('request.jwt.claims', json_build_object('sub', v_ua::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  set local role authenticated;

  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_name => 'Thuoc TH06',
    p_reference_id => 'TH06-P1', p_new_unit_name => 'Hop');
  v_p1 := (v_res ->> 'product_id')::uuid;
  reset role;
  select id, tenant_measurement_unit_id into v_u1, v_unit_id
    from catalog.product_units where product_id = v_p1 and is_base_unit = true;
  set local role authenticated;
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta, p_product_id => v_p1, p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 100000, p_list_price_after_vat => 100000,
    p_floor_price_before_vat => 50000, p_floor_price_after_vat => 50000);

  reset role;
  update catalog.products set is_ready_to_sell = true where id = v_p1 and is_ready_to_sell is not true;
  perform inventory.ensure_default_store_warehouse_pair(v_ta, gen_random_uuid());
  select warehouse_id into v_wh from inventory.store_warehouse_assignments
    where tenant_id = v_ta and store_id = v_store and status = 'active' limit 1;
  perform inventory._post_movements(
    v_ta, v_wh, 'TEST_SETUP', gen_random_uuid(), v_today,
    jsonb_build_array(jsonb_build_object(
      'product_id', v_p1, 'movement_kind', 'RECEIPT', 'quantity_delta', 1000000,
      'unit_cost', 50000, 'amount_vnd', 50000000000)),
    v_ua);
  set local role authenticated;

  -- 1) Dữ liệu chuẩn (TH-06 2.3 + AC-06 US-01.1)
  v_tuan := public._th06_customer(v_ta, v_ua, 'Anh Tuấn', '0911000601');
  v_hung := public._th06_customer(v_ta, v_ua, 'Trại Hưng Phát', '0911000602');
  v_lan  := public._th06_customer(v_ta, v_ua, 'Chị Lan', '0911000603');
  v_het  := public._th06_customer(v_ta, v_ua, 'Khách Hết Nợ', '0911000604');

  v_o1 := public._th06_order(v_ta, v_ua, v_store, v_tuan, v_p1, v_u1, 40, 0, v_today + 30, 'th06-o1');
  perform public._th06_set(v_o1, 17, v_today - 8);
  v_o2 := public._th06_order(v_ta, v_ua, v_store, v_tuan, v_p1, v_u1, 100, 2000000, v_today + 30, 'th06-o2');
  perform public._th06_set(v_o2, 13, v_today - 3);
  v_o3 := public._th06_order(v_ta, v_ua, v_store, v_tuan, v_p1, v_u1, 60, 0, v_today + 30, 'th06-o3');
  perform public._th06_set(v_o3, 6, v_today + 12);

  v_ohung := public._th06_order(v_ta, v_ua, v_store, v_hung, v_p1, v_u1, 25, 0, v_today + 30, 'th06-ohung');
  perform public._th06_set(v_ohung, 5, v_today);
  v_olan := public._th06_order(v_ta, v_ua, v_store, v_lan, v_p1, v_u1, 60, 0, v_today + 30, 'th06-olan');
  perform public._th06_set(v_olan, 4, v_today + 7);

  -- không góp vào công nợ: đơn trả đủ của Chị Lan, đơn Khách lẻ, đơn huỷ, khách hết nợ, đơn ở cửa hàng không truy cập được
  v_olan_paid := public._th06_order(v_ta, v_ua, v_store, v_lan, v_p1, v_u1, 10, 1000000, null, 'th06-olanpaid');
  v_owalk := public._th06_order(v_ta, v_ua, v_store, null, v_p1, v_u1, 10, 1000000, null, 'th06-owalk');
  v_ohet := public._th06_order(v_ta, v_ua, v_store, v_het, v_p1, v_u1, 10, 1000000, null, 'th06-ohet');
  v_ocancel := public._th06_order(v_ta, v_ua, v_store, v_lan, v_p1, v_u1, 30, 0, v_today + 5, 'th06-ocancel');
  v_ohidden := public._th06_order(v_ta, v_ua, v_store, v_tuan, v_p1, v_u1, 10, 0, v_today + 5, 'th06-ohidden');

  reset role;
  update sales.sales_orders set lifecycle_status = 'cancelled', cancelled_at = now() where id = v_ocancel;
  insert into iam.stores (id, tenant_id, code, display_name, status)
  values (v_store2, v_ta, 'S2-TH06', 'Cua hang 2', 'inactive');
  update sales.sales_orders set store_id = v_store2 where id = v_ohidden;
  set local role authenticated;

  perform public._th06_invariants(v_ta, 'setup');

  -- ===== PHẦN A =====

  -- A01 danh sách + tổng
  v_res := receivable.list_customer_receivables(v_ta, v_ua);
  v_summary_a01 := v_res -> 'summary';
  perform public._th06_expect('A01 totalOutstandingMinor', v_summary_a01 ->> 'totalOutstandingMinor', '26500000');
  perform public._th06_expect('A01 customerCount', v_summary_a01 ->> 'customerCount', '3');
  perform public._th06_expect('A01 overdueCustomerCount', v_summary_a01 ->> 'overdueCustomerCount', '1');
  perform public._th06_expect('A01 overdueAmountMinor', v_summary_a01 ->> 'overdueAmountMinor', '12000000');
  perform public._th06_expect('A01 maxOverdueDays', v_summary_a01 ->> 'maxOverdueDays', '8');
  perform public._th06_expect('A01 số dòng', jsonb_array_length(v_res -> 'items')::text, '3');
  perform public._th06_expect('A01 dòng 1', v_res -> 'items' -> 0 ->> 'customerId', v_tuan::text);
  perform public._th06_expect('A01 dòng 2', v_res -> 'items' -> 1 ->> 'customerId', v_hung::text);
  perform public._th06_expect('A01 dòng 3', v_res -> 'items' -> 2 ->> 'customerId', v_lan::text);
  v_it := v_res -> 'items' -> 0;
  perform public._th06_expect('A01 Tuấn outstanding', v_it ->> 'outstandingMinor', '18000000');
  perform public._th06_expect('A01 Tuấn openOrderCount', v_it ->> 'openOrderCount', '3');
  perform public._th06_expect('A01 Tuấn overdueOrderCount', v_it ->> 'overdueOrderCount', '2');
  perform public._th06_expect('A01 Tuấn overdueAmountMinor', v_it ->> 'overdueAmountMinor', '12000000');
  perform public._th06_expect('A01 Tuấn maxOverdueDays', v_it ->> 'maxOverdueDays', '8');
  perform public._th06_expect('A01 Tuấn isActive', v_it ->> 'isActive', 'true');
  v_order_a01 := (
    select jsonb_agg(e ->> 'customerId' order by ord)
    from jsonb_array_elements(v_res -> 'items') with ordinality t(e, ord));

  -- A02 lọc quá hạn / tìm không dấu: summary không đổi
  v_res := receivable.list_customer_receivables(v_ta, v_ua, 'overdue');
  perform public._th06_expect('A02 overdue số dòng', jsonb_array_length(v_res -> 'items')::text, '1');
  perform public._th06_expect('A02 overdue khách', v_res -> 'items' -> 0 ->> 'customerId', v_tuan::text);
  perform public._th06_expect('A02 overdue summary', (v_res -> 'summary')::text, v_summary_a01::text);
  v_res := receivable.list_customer_receivables(v_ta, v_ua, 'all', 'tuan');
  perform public._th06_expect('A02 tìm tuan số dòng', jsonb_array_length(v_res -> 'items')::text, '1');
  perform public._th06_expect('A02 tìm tuan khách', v_res -> 'items' -> 0 ->> 'customerId', v_tuan::text);
  perform public._th06_expect('A02 tìm summary', (v_res -> 'summary')::text, v_summary_a01::text);

  -- A03 đến hạn hôm nay không quá hạn
  v_res := receivable.list_customer_receivables(v_ta, v_ua);
  v_it := v_res -> 'items' -> 1;
  perform public._th06_expect('A03 maxOverdueDays', v_it ->> 'maxOverdueDays', '0');
  perform public._th06_expect('A03 overdueOrderCount', v_it ->> 'overdueOrderCount', '0');

  -- A04a cursor: size 1 đi 3 trang = thứ tự A01
  v_cursor := null;
  v_ids := '{}';
  v_pages := 0;
  loop
    v_res := receivable.list_customer_receivables(v_ta, v_ua, 'all', null, v_cursor, 1);
    v_pages := v_pages + 1;
    exit when jsonb_array_length(v_res -> 'items') = 0;
    v_ids := v_ids || (v_res -> 'items' -> 0 ->> 'customerId')::uuid;
    v_cursor := v_res ->> 'nextCursor';
    exit when v_cursor is null;
    if v_pages > 20 then raise exception 'FAIL: A04 cursor lặp vô hạn'; end if;
  end loop;
  perform public._th06_expect('A04 số trang', v_pages::text, '3');
  perform public._th06_expect('A04 thứ tự', to_jsonb(v_ids)::text, v_order_a01::text);

  -- A06 chi tiết công nợ một khách (cũ trước)
  v_res := receivable.get_customer_receivable(v_ta, v_ua, v_tuan);
  perform public._th06_expect('A06 outstanding', v_res ->> 'outstandingMinor', '18000000');
  perform public._th06_expect('A06 openOrderCount', v_res ->> 'openOrderCount', '3');
  perform public._th06_expect('A06 overdueOrderCount', v_res ->> 'overdueOrderCount', '2');
  perform public._th06_expect('A06 maxOverdueDays', v_res ->> 'maxOverdueDays', '8');
  perform public._th06_expect('A06 đơn 1', v_res -> 'openOrders' -> 0 ->> 'salesOrderId', v_o1::text);
  perform public._th06_expect('A06 đơn 2', v_res -> 'openOrders' -> 1 ->> 'salesOrderId', v_o2::text);
  perform public._th06_expect('A06 đơn 3', v_res -> 'openOrders' -> 2 ->> 'salesOrderId', v_o3::text);
  perform public._th06_expect('A06 overdueDays 1', v_res -> 'openOrders' -> 0 ->> 'overdueDays', '8');
  perform public._th06_expect('A06 overdueDays 2', v_res -> 'openOrders' -> 1 ->> 'overdueDays', '3');
  perform public._th06_expect('A06 overdueDays 3', v_res -> 'openOrders' -> 2 ->> 'overdueDays', '0');
  perform public._th06_expect('A06 settlementVersion có',
    ((v_res -> 'openOrders' -> 0 ->> 'settlementVersion') is not null)::text, 'true');
  perform public._th06_expect('A06 tổng dòng',
    (select sum((e ->> 'outstandingMinor')::bigint)::text from jsonb_array_elements(v_res -> 'openOrders') e),
    '18000000');
  perform public._th06_expect('A06 summary',
    receivable.get_customer_receivable_summary(v_ta, v_ua, v_tuan)::text,
    jsonb_build_object('outstandingMinor', 18000000, 'openOrderCount', 3, 'maxOverdueDays', 8)::text);
  v_res := receivable.get_customer_receivable_summary(v_ta, v_ua, v_het);
  perform public._th06_expect('A06 summary hết nợ',
    v_res::text, jsonb_build_object('outstandingMinor', 0, 'openOrderCount', 0, 'maxOverdueDays', 0)::text);

  -- A07 thu 10.000.000 tiền mặt, cả 3 đơn
  v_rc_before := public._th06_val(format(
    'select coalesce(max(receipt_version), 0) from sales.sales_receipts where sales_order_id = %L', v_o2))::int;
  v_res := receivable.record_customer_collection(
    v_ta, v_ua, v_tuan, 10000000, 'cash', null, array[v_o1, v_o2, v_o3], 18000000, 'th06-a07');
  v_cid := (v_res ->> 'collectionId')::uuid;
  perform public._th06_expect('A07 số phân bổ', jsonb_array_length(v_res -> 'allocations')::text, '2');
  perform public._th06_expect('A07 đơn 1', v_res -> 'allocations' -> 0 ->> 'salesOrderId', v_o1::text);
  perform public._th06_expect('A07 đơn 1 số tiền', v_res -> 'allocations' -> 0 ->> 'amountMinor', '4000000');
  perform public._th06_expect('A07 đơn 1 còn', v_res -> 'allocations' -> 0 ->> 'outstandingAfterMinor', '0');
  perform public._th06_expect('A07 đơn 2', v_res -> 'allocations' -> 1 ->> 'salesOrderId', v_o2::text);
  perform public._th06_expect('A07 đơn 2 số tiền', v_res -> 'allocations' -> 1 ->> 'amountMinor', '6000000');
  perform public._th06_expect('A07 đơn 2 còn', v_res -> 'allocations' -> 1 ->> 'outstandingAfterMinor', '2000000');
  perform public._th06_expect('A07 outstandingAfter', v_res ->> 'outstandingAfterMinor', '8000000');
  perform public._th06_expect('A07 customer_collections',
    public._th06_val(format(
      'select amount_minor || '':'' || customer_outstanding_before_minor || '':'' || customer_outstanding_after_minor
       from receivable.customer_collections where id = %L', v_cid)),
    '10000000:18000000:8000000');
  perform public._th06_expect('A07 giao dịch',
    public._th06_val(format(
      'select count(*) from receivable.sales_payment_transactions
       where source_context = ''receivable_collection'' and source_type = ''customer_collection''
         and source_id = %L and transaction_type = ''collection''', v_cid)), '2');
  perform public._th06_expect('A07 o1 paid',
    public._th06_val(format('select payment_status from receivable.sales_order_settlements where sales_order_id = %L', v_o1)),
    'paid');
  perform public._th06_expect('A07 o2 partially_paid',
    public._th06_val(format('select payment_status from receivable.sales_order_settlements where sales_order_id = %L', v_o2)),
    'partially_paid');
  perform public._th06_expect('A07 ngày hẹn không đổi',
    public._th06_val(format(
      'select string_agg(payment_due_date::text, '','' order by payment_due_date) from receivable.sales_order_settlements
       where sales_order_id in (%L, %L, %L)', v_o1, v_o2, v_o3)),
    (v_today - 8)::text || ',' || (v_today - 3)::text || ',' || (v_today + 12)::text);
  if public._th06_val(format(
       'select max(receipt_version) from sales.sales_receipts where sales_order_id = %L', v_o2))::int
     <= v_rc_before then
    raise exception 'FAIL: A07 không có phiếu bán hàng phiên bản mới cho đơn 2';
  end if;
  perform public._th06_expect('A07 outbox',
    public._th06_val(format(
      'select count(*) from sales.outbox_messages
       where event_type = ''sales_payment_recorded.v1'' and payload ->> ''customerCollectionId'' = %L', v_cid::text)),
    '2');
  perform public._th06_invariants(v_ta, 'A07');

  -- B16 nhãn thu theo khách trong lịch sử đơn
  perform public._th06_expect('B16 nhãn thu theo khách',
    (select count(*)::text from jsonb_array_elements(
       sales.get_sales_order_timeline(gen_random_uuid()::text, v_ta, v_ua, v_o2) -> 'entries') e
     where e ->> 'eventType' = 'sales_payment_recorded.v1'
       and e ->> 'description' = 'Ghi nhận thu nợ theo khách'), '1');

  -- A15 lịch sử sau A07
  v_res := receivable.list_customer_receivable_history(v_ta, v_ua, v_tuan);
  perform public._th06_expect('A15 kind mới nhất', v_res -> 'items' -> 0 ->> 'kind', 'customer_collection');
  perform public._th06_expect('A15 số tiền', v_res -> 'items' -> 0 ->> 'amountMinor', '10000000');
  perform public._th06_expect('A15 allocations', jsonb_array_length(v_res -> 'items' -> 0 -> 'allocations')::text, '2');
  v_found := false;
  for v_it in select e from jsonb_array_elements(v_res -> 'items') e loop
    if v_it ->> 'kind' = 'order_collection' and v_it ->> 'amountMinor' = '2000000'
       and v_it ->> 'salesOrderId' = v_o2::text then
      v_found := true;
    end if;
  end loop;
  if not v_found then
    raise exception 'FAIL: A15 thiếu dòng order_collection 2.000.000 của đơn 2: %', v_res;
  end if;
  -- A16 lịch sử trả tên người thu (T6-2b Task 1)
  if not ((v_res -> 'items' -> 0) ? 'actorDisplayName') then
    raise exception 'FAIL: A16 dòng customer_collection thiếu khoá actorDisplayName: %', v_res -> 'items' -> 0;
  end if;
  perform public._th06_expect('A16 actorDisplayName',
    coalesce(v_res -> 'items' -> 0 ->> 'actorDisplayName', 'null'),
    public._th06_val(format(
      'select coalesce(iam._member_display_name(%L::uuid), ''null'')', v_ua)));
  perform public._th06_expect('A15 hết trang', coalesce(v_res ->> 'nextCursor', 'null'), 'null');
  v_res := receivable.list_customer_receivable_history(v_ta, v_ua, v_tuan, null, 1);
  perform public._th06_expect('A15 trang 1 có cursor', ((v_res ->> 'nextCursor') is not null)::text, 'true');
  v_r2 := receivable.list_customer_receivable_history(v_ta, v_ua, v_tuan, v_res ->> 'nextCursor', 1);
  perform public._th06_expect('A15 trang 2 khác trang 1',
    ((v_r2 -> 'items' -> 0 ->> 'kind') is distinct from 'customer_collection')::text, 'true');

  -- A08a chỉ chọn đơn 3, sửa số 5.000.000 chuyển khoản (expected 6.000.000)
  v_res := receivable.record_customer_collection(
    v_ta, v_ua, v_tuan, 5000000, 'manualBankTransfer', 'CK123', array[v_o3], 6000000, 'th06-a08a');
  v_cid2 := (v_res ->> 'collectionId')::uuid;
  perform public._th06_expect('A08a số phân bổ', jsonb_array_length(v_res -> 'allocations')::text, '1');
  perform public._th06_expect('A08a còn', v_res -> 'allocations' -> 0 ->> 'outstandingAfterMinor', '1000000');
  perform public._th06_expect('A08a outstandingAfter', v_res ->> 'outstandingAfterMinor', '3000000');
  perform public._th06_expect('A08a đơn 2 không đổi',
    public._th06_val(format('select outstanding_amount_minor from receivable.sales_order_settlements where sales_order_id = %L', v_o2)),
    '2000000');
  perform public._th06_expect('A08a mã giao dịch',
    public._th06_val(format(
      'select external_reference from receivable.sales_payment_transactions where source_id = %L', v_cid2)),
    'CK123');
  perform public._th06_invariants(v_ta, 'A08a');

  -- A11 / A13 thử lại cùng key sau khi công nợ đã đổi → kết quả cũ
  v_n_cc := public._th06_val(format('select count(*) from receivable.customer_collections where tenant_id = %L', v_ta))::bigint;
  v_r2 := receivable.record_customer_collection(
    v_ta, v_ua, v_tuan, 5000000, 'manualBankTransfer', 'CK123', array[v_o3], 6000000, 'th06-a08a');
  perform public._th06_expect('A11 cùng collectionId', v_r2 ->> 'collectionId', v_cid2::text);
  perform public._th06_expect('A11 vẫn 1 lần thu',
    public._th06_val(format('select count(*) from receivable.customer_collections where tenant_id = %L', v_ta)),
    v_n_cc::text);
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 4000000, 'manualBankTransfer', 'CK123', array[%L]::uuid[], 6000000, 'th06-a08a')$f$,
      v_ta, v_ua, v_tuan, v_o3),
    'IDEMPOTENCY_CONFLICT');

  -- A09 / A10 / A12 lỗi: không ghi gì
  v_n_cc := public._th06_val(format('select count(*) from receivable.customer_collections where tenant_id = %L', v_ta))::bigint;
  v_n_tx := public._th06_val(format(
    'select count(*) from receivable.sales_payment_transactions t join receivable.sales_order_settlements s on s.id = t.sales_order_settlement_id where s.tenant_id = %L', v_ta))::bigint;

  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 0, 'cash', null, array[%L]::uuid[], 2000000, 'th06-e1')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'AMOUNT_INVALID');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, '{}'::uuid[], 2000000, 'th06-e2')$f$,
      v_ta, v_ua, v_tuan), 'AMOUNT_INVALID');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 2000001, 'cash', null, array[%L]::uuid[], 2000000, 'th06-e3')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'OVERPAYMENT_NOT_ALLOWED');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'offset', null, array[%L]::uuid[], 2000000, 'th06-e4')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'PAYMENT_METHOD_INVALID');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'abc', null, array[%L]::uuid[], 2000000, 'th06-e5')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'PAYMENT_METHOD_INVALID');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 2000000, 'th06-e6')$f$,
      v_ta, v_ua, gen_random_uuid(), v_o2), 'NOT_FOUND');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 0, 'th06-e7')$f$,
      v_ta, v_ua, v_het, v_ohet), 'NO_OUTSTANDING');
  -- A10 đơn đã hết nợ / thuộc khách khác / expected lệch 1đ
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 0, 'th06-e8')$f$,
      v_ta, v_ua, v_tuan, v_o1), 'RECEIVABLE_CHANGED');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 6000000, 'th06-e9')$f$,
      v_ta, v_ua, v_tuan, v_olan), 'RECEIVABLE_CHANGED');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 2000001, 'th06-e10')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'RECEIVABLE_CHANGED');
  -- A12 đơn ở cửa hàng không truy cập được
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L, %L]::uuid[], 3000000, 'th06-e11')$f$,
      v_ta, v_ua, v_tuan, v_o2, v_ohidden), 'RECEIVABLE_CHANGED');
  perform public._th06_expect('A09 không ghi lần thu',
    public._th06_val(format('select count(*) from receivable.customer_collections where tenant_id = %L', v_ta)),
    v_n_cc::text);
  perform public._th06_expect('A09 không ghi giao dịch',
    public._th06_val(format(
      'select count(*) from receivable.sales_payment_transactions t join receivable.sales_order_settlements s on s.id = t.sales_order_settlement_id where s.tenant_id = %L', v_ta)),
    v_n_tx::text);
  perform public._th06_invariants(v_ta, 'A09');

  -- A14 khách ngừng hoạt động vẫn list / get / record được
  reset role;
  update partner.partners set status = 'inactive' where partner_id = v_lan;
  set local role authenticated;
  v_res := receivable.list_customer_receivables(v_ta, v_ua);
  v_found := false;
  for v_it in select e from jsonb_array_elements(v_res -> 'items') e loop
    if v_it ->> 'customerId' = v_lan::text then
      v_found := true;
      perform public._th06_expect('A14 isActive', v_it ->> 'isActive', 'false');
    end if;
  end loop;
  if not v_found then
    raise exception 'FAIL: A14 khách ngừng hoạt động không có trong danh sách';
  end if;
  v_res := receivable.get_customer_receivable(v_ta, v_ua, v_lan);
  perform public._th06_expect('A14 get isActive', v_res -> 'customer' ->> 'isActive', 'false');
  v_res := receivable.record_customer_collection(
    v_ta, v_ua, v_lan, 1000000, 'cash', null, array[v_olan], 6000000, 'th06-a14');
  perform public._th06_expect('A14 outstandingAfter', v_res ->> 'outstandingAfterMinor', '5000000');
  perform public._th06_invariants(v_ta, 'A14');

  -- A04b hai khách giống hệt nhau (cùng nợ, cùng tên, không hẹn): phân trang size 1 ra đủ 5 khách khác nhau
  v_x1 := public._th06_customer(v_ta, v_ua, 'Khách Giống Nhau', '0911000611');
  v_x2 := public._th06_customer(v_ta, v_ua, 'Khách Giống Nhau', '0911000612');
  perform public._th06_set(public._th06_order(v_ta, v_ua, v_store, v_x1, v_p1, v_u1, 15, 0, v_today + 30, 'th06-x1'), 1, null);
  perform public._th06_set(public._th06_order(v_ta, v_ua, v_store, v_x2, v_p1, v_u1, 15, 0, v_today + 30, 'th06-x2'), 1, null);
  v_cursor := null;
  v_ids := '{}';
  v_pages := 0;
  loop
    v_res := receivable.list_customer_receivables(v_ta, v_ua, 'all', null, v_cursor, 1);
    v_pages := v_pages + 1;
    exit when jsonb_array_length(v_res -> 'items') = 0;
    v_ids := v_ids || (v_res -> 'items' -> 0 ->> 'customerId')::uuid;
    v_cursor := v_res ->> 'nextCursor';
    exit when v_cursor is null;
    if v_pages > 20 then raise exception 'FAIL: A04b cursor lặp vô hạn'; end if;
  end loop;
  perform public._th06_expect('A04b số khách', cardinality(v_ids)::text, '5');
  perform public._th06_expect('A04b khác nhau', (select count(distinct x) from unnest(v_ids) x)::text, '5');

  -- A08b chọn đơn 2 + đơn 3 thu đủ → cả hai 'paid'; sau đó hết nợ → NO_OUTSTANDING
  v_res := receivable.record_customer_collection(
    v_ta, v_ua, v_tuan, 3000000, 'cash', null, array[v_o2, v_o3], 3000000, 'th06-a08b');
  perform public._th06_expect('A08b o2 paid',
    public._th06_val(format('select payment_status from receivable.sales_order_settlements where sales_order_id = %L', v_o2)),
    'paid');
  perform public._th06_expect('A08b o3 paid',
    public._th06_val(format('select payment_status from receivable.sales_order_settlements where sales_order_id = %L', v_o3)),
    'paid');
  perform public._th06_expect('A08b outstandingAfter', v_res ->> 'outstandingAfterMinor', '0');
  perform public._th06_expect_err(
    format($f$select receivable.record_customer_collection(%L, %L, %L, 1000, 'cash', null, array[%L]::uuid[], 0, 'th06-a08c')$f$,
      v_ta, v_ua, v_tuan, v_o2), 'NO_OUTSTANDING');
  perform public._th06_invariants(v_ta, 'A08b');

-- ===== PHẦN B =====
  declare
    v_kb uuid; v_kc uuid; v_kd uuid; v_ke uuid; v_kf uuid; v_kg uuid; v_kh uuid;
    v_b1 uuid; v_b2 uuid; v_b3 uuid;
    v_c1 uuid; v_c2 uuid;
    v_d1 uuid;
    v_e1 uuid; v_e2 uuid;
    v_f1 uuid;
    v_g1 uuid; v_g2 uuid;
    v_h1 uuid; v_h2 uuid; v_h3 uuid; v_h4 uuid;
    v_w1 uuid;
    v_rx jsonb; v_rxid uuid; v_rxver int;
    v_rx_a jsonb; v_det jsonb;
    v_plan jsonb;
    v_movements bigint;
    v_tx_before text;
    v_receipt_before int;
    v_offset_id uuid;
  begin
    v_kb := public._th06_customer(v_ta, v_ua, 'Khách B Cấn Trừ', '0911000621');
    v_kc := public._th06_customer(v_ta, v_ua, 'Khách C Cũ Mới', '0911000622');
    v_kd := public._th06_customer(v_ta, v_ua, 'Khách D Giảm Nợ', '0911000623');
    v_ke := public._th06_customer(v_ta, v_ua, 'Khách E Cấn Hoàn', '0911000624');
    v_kf := public._th06_customer(v_ta, v_ua, 'Khách F Thu Một Phần', '0911000625');
    v_kg := public._th06_customer(v_ta, v_ua, 'Khách G Không Cấn', '0911000626');
    v_kh := public._th06_customer(v_ta, v_ua, 'Khách H Đơn Sai', '0911000627');

    -- B01 / B02 / B11 / B12 / B13: DH-001 đã trả đủ 4tr, DH-002 nợ 2tr, DH-003 nợ 6tr; trả hàng DH-001 500.000
    v_b1 := public._th06_order(v_ta, v_ua, v_store, v_kb, v_p1, v_u1, 40, 4000000, null, 'th06-b1');
    perform public._th06_set(v_b1, 17, null);
    v_b2 := public._th06_order(v_ta, v_ua, v_store, v_kb, v_p1, v_u1, 100, 8000000, v_today + 30, 'th06-b2');
    perform public._th06_set(v_b2, 13, v_today + 10);
    v_b3 := public._th06_order(v_ta, v_ua, v_store, v_kb, v_p1, v_u1, 60, 0, v_today + 30, 'th06-b3');
    perform public._th06_set(v_b3, 6, v_today + 20);

    v_rx := public._th06_return(v_ta, v_ua, v_b1, v_p1, v_u1, 5, 'th06-b1-start');
    v_rxid := (v_rx ->> 'id')::uuid;
    v_rxver := (v_rx ->> 'version')::int;
    v_plan := v_rx -> 'eval' -> 'settlementPlan';
    perform public._th06_expect('B01 receivableReverse', v_plan ->> 'receivableReverseAmountMinor', '0');
    perform public._th06_expect('B01 offsetAmount', v_plan ->> 'offsetAmountMinor', '500000');
    perform public._th06_expect('B01 refundAmount', v_plan ->> 'refundAmountMinor', '0');
    perform public._th06_expect('B01 số ứng viên', jsonb_array_length(v_plan -> 'offsetCandidates')::text, '2');
    perform public._th06_expect('B01 ứng viên 1', v_plan -> 'offsetCandidates' -> 0 ->> 'salesOrderId', v_b2::text);
    perform public._th06_expect('B01 ứng viên 1 offset', v_plan -> 'offsetCandidates' -> 0 ->> 'offsetAmountMinor', '500000');
    perform public._th06_expect('B01 ứng viên 2', v_plan -> 'offsetCandidates' -> 1 ->> 'salesOrderId', v_b3::text);
    perform public._th06_expect('B01 ứng viên 2 offset', v_plan -> 'offsetCandidates' -> 1 ->> 'offsetAmountMinor', '0');
    perform public._th06_expect('B01 ứng viên có settlementVersion',
      ((v_plan -> 'offsetCandidates' -> 0 ->> 'settlementVersion') is not null)::text, 'true');
    perform public._th06_expect('B01 dòng kế hoạch',
      public._th06_val(format(
        'select receivable_reverse_amount_minor || '':'' || offset_amount_minor || '':'' || refund_amount_minor
         from receivable.return_exchange_settlement_plans where return_exchange_order_id = %L', v_rxid)),
      '0:500000:0');
    perform public._th06_expect('B01 valuation_details không còn settlement_plan',
      public._th06_val(format(
        'select (valuation_details ? ''settlement_plan'')::text from sales.return_exchange_valuations where return_exchange_order_id = %L',
        v_rxid)), 'false');

    -- B12 (nháp): processed* = 0
    v_res := sales.get_return_exchange_detail(gen_random_uuid()::text, v_ta, v_ua, v_rxid);
    perform public._th06_expect('B12 nháp offsetAmount', v_res -> 'settlementPlan' ->> 'offsetAmountMinor', '500000');
    perform public._th06_expect('B12 nháp processedRefund', v_res -> 'settlementPlan' ->> 'processedRefundMinor', '0');
    perform public._th06_expect('B12 nháp processedCollect', v_res -> 'settlementPlan' ->> 'processedCollectMinor', '0');

    -- B02 xác nhận với cả hai đơn nhận
    v_receipt_before := public._th06_val(format(
      'select coalesce(max(receipt_version), 0) from sales.sales_receipts where sales_order_id = %L', v_b2))::int;
    v_res := public._th06_confirm(v_ta, v_ua, v_rxid, v_rxver, 'th06-b1-confirm', array[v_b2, v_b3]);
    perform public._th06_expect('B02 status', v_res ->> 'status', 'completed');
    perform public._th06_expect('B02 nguồn refund offset', public._th06_txn(v_b1, 'refund', 'offset', 500000), '1');
    perform public._th06_expect('B02 nguồn không refund cash', public._th06_txn(v_b1, 'refund', 'cash', null), '0');
    perform public._th06_expect('B02 nhận collection offset', public._th06_txn(v_b2, 'collection', 'offset', 500000), '1');
    perform public._th06_expect('B02 nhận còn nợ', public._th06_out(v_b2), '1500000');
    perform public._th06_expect('B02 đơn 3 không đổi', public._th06_out(v_b3), '6000000');
    perform public._th06_expect('B02 đơn 3 không giao dịch offset', public._th06_txn(v_b3, 'collection', 'offset', null), '0');
    perform public._th06_expect('B02 source_type',
      public._th06_val(format(
        'select count(*) from receivable.sales_payment_transactions where payment_method_code = ''offset''
           and source_context = ''return_exchange'' and source_type = ''receivable_offset''
           and sales_order_settlement_id in (select id from receivable.sales_order_settlements where sales_order_id in (%L, %L))',
        v_b1, v_b2)), '2');
    perform public._th06_expect('B02 receivable_offsets',
      public._th06_val(format('select count(*) from receivable.receivable_offsets where return_exchange_order_id = %L', v_rxid)), '1');
    v_offset_id := public._th06_val(format(
      'select id from receivable.receivable_offsets where return_exchange_order_id = %L', v_rxid))::uuid;
    perform public._th06_expect('B02 outbox hai đơn',
      public._th06_val(format(
        'select string_agg(payload ->> ''salesOrderId'', '','' order by payload ->> ''salesOrderId'') from sales.outbox_messages
         where event_type = ''receivable_offset_recorded.v1'' and payload ->> ''offsetId'' = %L', v_offset_id::text)),
      (select string_agg(x, ',' order by x) from unnest(array[v_b1::text, v_b2::text]) x));
    if public._th06_val(format(
         'select max(receipt_version) from sales.sales_receipts where sales_order_id = %L', v_b2))::int
       <= v_receipt_before then
      raise exception 'FAIL: B02 đơn nhận không có phiếu bán hàng mới';
    end if;
    v_res := receivable.list_customer_receivable_history(v_ta, v_ua, v_kb);
    v_found := false;
    for v_it in select e from jsonb_array_elements(v_res -> 'items') e loop
      if v_it ->> 'kind' = 'offset'
         and v_it ->> 'sourceOrderCode' = public._th06_val(format('select order_code from sales.sales_orders where id = %L', v_b1))
         and v_it ->> 'targetOrderCode' = public._th06_val(format('select order_code from sales.sales_orders where id = %L', v_b2))
         and v_it ->> 'amountMinor' = '500000' then
        v_found := true;
      end if;
    end loop;
    if not v_found then
      raise exception 'FAIL: B02 lịch sử thiếu dòng offset DH-001 → DH-002: %', v_res;
    end if;
    perform public._th06_invariants(v_ta, 'B02');

    -- B11 xác nhận lại cùng key: không thêm gì
    v_tx_before := public._th06_val(format(
      'select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta));
    v_r2 := public._th06_confirm(v_ta, v_ua, v_rxid, v_rxver, 'th06-b1-confirm', array[v_b2, v_b3]);
    perform public._th06_expect('B11 không thêm giao dịch',
      public._th06_val(format('select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta)),
      v_tx_before);
    perform public._th06_expect('B11 vẫn 1 receivable_offsets',
      public._th06_val(format('select count(*) from receivable.receivable_offsets where return_exchange_order_id = %L', v_rxid)), '1');

    -- B12 (đã xác nhận)
    v_res := sales.get_return_exchange_detail(gen_random_uuid()::text, v_ta, v_ua, v_rxid);
    perform public._th06_expect('B12 offsetAmount', v_res -> 'settlementPlan' ->> 'offsetAmountMinor', '500000');
    perform public._th06_expect('B12 processedRefund', v_res -> 'settlementPlan' ->> 'processedRefundMinor', '0');
    perform public._th06_expect('B12 remainderRefund', v_res -> 'settlementPlan' ->> 'remainderRefundMinor', '0');
    perform public._th06_expect('B12 remainderCollect', v_res -> 'settlementPlan' ->> 'remainderCollectMinor', '0');
    perform public._th06_expect('B12 số ứng viên', jsonb_array_length(v_res -> 'settlementPlan' -> 'offsetCandidates')::text, '2');

    -- B13 RPC đọc TH-05 cho phương thức offset
    v_res := sales.get_sales_order_payment_transactions(gen_random_uuid()::text, v_ta, v_ua, v_b2);
    v_found := false;
    for v_it in select e from jsonb_array_elements(v_res -> 'items') e loop
      if v_it ->> 'method' = 'offset' then
        v_found := true;
        perform public._th06_expect('B13 counterpartSalesOrderId', v_it ->> 'counterpartSalesOrderId', v_b1::text);
        perform public._th06_expect('B13 counterpartOrderCode', v_it ->> 'counterpartOrderCode',
          public._th06_val(format('select order_code from sales.sales_orders where id = %L', v_b1)));
      end if;
    end loop;
    if not v_found then
      raise exception 'FAIL: B13 đơn nhận không có giao dịch offset: %', v_res;
    end if;
    v_res := sales.get_sales_order_payment_summary(gen_random_uuid(), v_ta, v_ua, v_b2);
    perform public._th06_expect('B13 collectedCash', v_res -> 'collectedCash' ->> 'amountMinor', '8000000');
    perform public._th06_expect('B13 collectedBank', v_res -> 'collectedBank' ->> 'amountMinor', '0');
    perform public._th06_expect('B13 collectedOffset', v_res -> 'collectedOffset' ->> 'amountMinor', '500000');
    perform public._th06_expect('B13 refundedOffset đơn nhận', v_res -> 'refundedOffset' ->> 'amountMinor', '0');
    v_res := sales.get_sales_order_payment_summary(gen_random_uuid(), v_ta, v_ua, v_b1);
    perform public._th06_expect('B13 refundedOffset đơn nguồn', v_res -> 'refundedOffset' ->> 'amountMinor', '500000');
    perform public._th06_expect('B13 phiếu có dòng offset',
      public._th06_val(format(
        'select count(*) from sales.sales_receipts r, jsonb_array_elements(r.receipt_snapshot -> ''payments'') p
         where r.sales_order_id = %L
           and r.receipt_version = (select max(receipt_version) from sales.sales_receipts where sales_order_id = %L)
           and p ->> ''method'' = ''offset'' and p -> ''amount'' ->> ''amountMinor'' = ''500000''',
        v_b2, v_b2)), '1');
    v_res := sales.get_sales_order_timeline(gen_random_uuid()::text, v_ta, v_ua, v_b2);
    v_found := false;
    for v_it in select e from jsonb_array_elements(v_res -> 'entries') e loop
      if v_it ->> 'eventType' = 'receivable_offset_recorded.v1' then v_found := true; end if;
    end loop;
    if not v_found then
      raise exception 'FAIL: B13 timeline đơn nhận thiếu receivable_offset_recorded.v1';
    end if;

    -- B03 giảm nợ chính đơn nguồn: trả 1tr của đơn nợ 6tr
    v_d1 := public._th06_order(v_ta, v_ua, v_store, v_kd, v_p1, v_u1, 60, 0, v_today + 30, 'th06-d1');
    v_rx := public._th06_return(v_ta, v_ua, v_d1, v_p1, v_u1, 10, 'th06-d1-start');
    v_plan := v_rx -> 'eval' -> 'settlementPlan';
    perform public._th06_expect('B03 reverse', v_plan ->> 'receivableReverseAmountMinor', '1000000');
    perform public._th06_expect('B03 offset', v_plan ->> 'offsetAmountMinor', '0');
    perform public._th06_expect('B03 refund', v_plan ->> 'refundAmountMinor', '0');
    perform public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-d1-confirm', null);
    perform public._th06_expect('B03 còn nợ', public._th06_out(v_d1), '5000000');
    perform public._th06_expect('B03 không refund', public._th06_txn(v_d1, 'refund', 'cash', null), '0');
    perform public._th06_expect('B03 không refund offset', public._th06_txn(v_d1, 'refund', 'offset', null), '0');
    perform public._th06_invariants(v_ta, 'B03');

    -- B04 nguồn trả đủ 4tr, trả 3tr, khách nợ đơn khác 2tr → cấn trừ 2tr + hoàn 1tr
    v_e1 := public._th06_order(v_ta, v_ua, v_store, v_ke, v_p1, v_u1, 40, 4000000, null, 'th06-e1');
    perform public._th06_set(v_e1, 10, null);
    v_e2 := public._th06_order(v_ta, v_ua, v_store, v_ke, v_p1, v_u1, 20, 0, v_today + 30, 'th06-e2');
    perform public._th06_set(v_e2, 5, v_today + 10);
    v_rx := public._th06_return(v_ta, v_ua, v_e1, v_p1, v_u1, 30, 'th06-e1-start');
    v_plan := v_rx -> 'eval' -> 'settlementPlan';
    perform public._th06_expect('B04 reverse', v_plan ->> 'receivableReverseAmountMinor', '0');
    perform public._th06_expect('B04 offset', v_plan ->> 'offsetAmountMinor', '2000000');
    perform public._th06_expect('B04 refund', v_plan ->> 'refundAmountMinor', '1000000');
    v_res := public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-e1-confirm', array[v_e2]);
    perform public._th06_expect('B04 refund offset', public._th06_txn(v_e1, 'refund', 'offset', 2000000), '1');
    perform public._th06_expect('B04 refund cash', public._th06_txn(v_e1, 'refund', 'cash', 1000000), '1');
    perform public._th06_expect('B04 net_collected nguồn',
      public._th06_val(format('select net_collected_amount_minor from receivable.sales_order_settlements where sales_order_id = %L', v_e1)),
      '1000000');
    perform public._th06_expect('B04 nhận hết nợ', public._th06_out(v_e2), '0');
    perform public._th06_invariants(v_ta, 'B04');

    -- B05 đơn 1tr đã thu 400k, trả 600k → giảm nợ 600k, không hoàn
    v_f1 := public._th06_order(v_ta, v_ua, v_store, v_kf, v_p1, v_u1, 10, 400000, v_today + 30, 'th06-f1');
    v_rx := public._th06_return(v_ta, v_ua, v_f1, v_p1, v_u1, 6, 'th06-f1-start');
    v_plan := v_rx -> 'eval' -> 'settlementPlan';
    perform public._th06_expect('B05 reverse', v_plan ->> 'receivableReverseAmountMinor', '600000');
    perform public._th06_expect('B05 offset', v_plan ->> 'offsetAmountMinor', '0');
    perform public._th06_expect('B05 refund', v_plan ->> 'refundAmountMinor', '0');
    perform public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-f1-confirm', null);
    perform public._th06_expect('B05 hết nợ', public._th06_out(v_f1), '0');
    perform public._th06_expect('B05 không refund', public._th06_txn(v_f1, 'refund', 'cash', null), '0');
    perform public._th06_invariants(v_ta, 'B05');

    -- B06 offset rỗng / không truyền → hoàn tiền mặt toàn bộ, không cấn trừ
    v_g1 := public._th06_order(v_ta, v_ua, v_store, v_kg, v_p1, v_u1, 10, 1000000, null, 'th06-g1');
    perform public._th06_set(v_g1, 9, null);
    v_g2 := public._th06_order(v_ta, v_ua, v_store, v_kg, v_p1, v_u1, 10, 0, v_today + 30, 'th06-g2');
    perform public._th06_set(v_g2, 4, v_today + 10);
    v_rx := public._th06_return(v_ta, v_ua, v_g1, v_p1, v_u1, 2, 'th06-g1-start-a');
    v_rx_a := v_rx;
    perform public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-g1-confirm-a', '{}'::uuid[]);
    v_rx := public._th06_return(v_ta, v_ua, v_g1, v_p1, v_u1, 3, 'th06-g1-start-b');
    perform public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-g1-confirm-b', null);
    perform public._th06_expect('B06 refund cash 200k', public._th06_txn(v_g1, 'refund', 'cash', 200000), '1');
    perform public._th06_expect('B06 refund cash 300k', public._th06_txn(v_g1, 'refund', 'cash', 300000), '1');
    perform public._th06_expect('B06 không offset', public._th06_txn(v_g1, 'refund', 'offset', null), '0');
    perform public._th06_expect('B06 không receivable_offsets',
      public._th06_val(format('select count(*) from receivable.receivable_offsets where customer_partner_id = %L', v_kg)), '0');
    perform public._th06_expect('B06 đơn khác không đổi', public._th06_out(v_g2), '1000000');
    perform public._th06_invariants(v_ta, 'B06');

    -- B15 cách chia thật sau xác nhận (B06 bỏ hết cấn trừ, kế hoạch từng đề xuất cấn vào g2)
    v_det := sales.get_return_exchange_detail(gen_random_uuid()::text, v_ta, v_ua, (v_rx_a ->> 'id')::uuid);
    perform public._th06_expect('B15 offset thật = 0', v_det #>> '{settlementPlan,offsetAmountMinor}', '0');
    perform public._th06_expect('B15 hoàn thật = 200000', v_det #>> '{settlementPlan,refundAmountMinor}', '200000');
    perform public._th06_expect('B15 ứng viên g2 trừ 0',
      (select c ->> 'offsetAmountMinor' from jsonb_array_elements(v_det #> '{settlementPlan,offsetCandidates}') c
       where c ->> 'salesOrderId' = v_g2::text), '0');

    -- B07 giữa định giá và xác nhận, đơn nhận vừa được thu → STALE_VERSION, không ghi gì
    v_c1 := public._th06_order(v_ta, v_ua, v_store, v_kc, v_p1, v_u1, 10, 1000000, null, 'th06-c1');
    perform public._th06_set(v_c1, 9, null);
    v_c2 := public._th06_order(v_ta, v_ua, v_store, v_kc, v_p1, v_u1, 20, 0, v_today + 30, 'th06-c2');
    perform public._th06_set(v_c2, 4, v_today + 10);
    v_rx := public._th06_return(v_ta, v_ua, v_c1, v_p1, v_u1, 1, 'th06-c1-start');
    v_rxid := (v_rx ->> 'id')::uuid;
    v_rxver := (v_rx ->> 'version')::int;
    perform receivable.record_customer_collection(
      v_ta, v_ua, v_kc, 1, 'cash', null, array[v_c2], 2000000, 'th06-b07-collect');
    v_tx_before := public._th06_val(format(
      'select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta));
    v_movements := public._th06_val(format(
      'select count(*) from inventory.stock_movements where tenant_id = %L', v_ta))::bigint;
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-c1-confirm', array[%L]::uuid[])$f$,
        v_ta, v_ua, v_rxid, v_rxver, v_c2),
      'STALE_VERSION');
    perform public._th06_expect('B07 phiếu vẫn nháp',
      public._th06_val(format('select status from sales.return_exchange_orders where id = %L', v_rxid)), 'draft');
    perform public._th06_expect('B07 không giao dịch mới',
      public._th06_val(format('select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta)),
      v_tx_before);
    perform public._th06_expect('B07 không bút toán kho mới',
      public._th06_val(format('select count(*) from inventory.stock_movements where tenant_id = %L', v_ta)),
      v_movements::text);
    -- B12 (nháp, có cấn trừ đề xuất): processed* = 0
    v_res := sales.get_return_exchange_detail(gen_random_uuid()::text, v_ta, v_ua, v_rxid);
    perform public._th06_expect('B12 phiếu nháp offsetAmount', v_res -> 'settlementPlan' ->> 'offsetAmountMinor', '100000');
    perform public._th06_expect('B12 phiếu nháp processedRefund', v_res -> 'settlementPlan' ->> 'processedRefundMinor', '0');
    perform public._th06_invariants(v_ta, 'B07');

    -- B08 / B09 đơn nhận sai: khách khác, đã huỷ, chính đơn nguồn, trùng, ở cửa hàng không truy cập được
    v_h1 := public._th06_order(v_ta, v_ua, v_store, v_kh, v_p1, v_u1, 10, 1000000, null, 'th06-h1');
    perform public._th06_set(v_h1, 9, null);
    v_h2 := public._th06_order(v_ta, v_ua, v_store, v_kh, v_p1, v_u1, 10, 0, v_today + 30, 'th06-h2');
    perform public._th06_set(v_h2, 4, v_today + 10);
    v_h3 := public._th06_order(v_ta, v_ua, v_store, v_kh, v_p1, v_u1, 10, 0, v_today + 30, 'th06-h3');
    v_h4 := public._th06_order(v_ta, v_ua, v_store, v_kh, v_p1, v_u1, 10, 0, v_today + 30, 'th06-h4');
    reset role;
    update sales.sales_orders set lifecycle_status = 'cancelled', cancelled_at = now() where id = v_h3;
    update sales.sales_orders set store_id = v_store2 where id = v_h4;
    set local role authenticated;
    v_rx := public._th06_return(v_ta, v_ua, v_h1, v_p1, v_u1, 1, 'th06-h1-start');
    v_rxid := (v_rx ->> 'id')::uuid;
    v_rxver := (v_rx ->> 'version')::int;
    -- B09 đơn ở cửa hàng không truy cập được / đơn huỷ không có trong ứng viên
    perform public._th06_expect('B09 số ứng viên', jsonb_array_length(v_rx -> 'eval' -> 'settlementPlan' -> 'offsetCandidates')::text, '1');
    perform public._th06_expect('B09 ứng viên là h2', v_rx -> 'eval' -> 'settlementPlan' -> 'offsetCandidates' -> 0 ->> 'salesOrderId', v_h2::text);
    v_tx_before := public._th06_val(format(
      'select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta));
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-h1-c1', array[%L]::uuid[])$f$, v_ta, v_ua, v_rxid, v_rxver, v_g2),
      'OFFSET_TARGET_INVALID');
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-h1-c2', array[%L]::uuid[])$f$, v_ta, v_ua, v_rxid, v_rxver, v_h3),
      'OFFSET_TARGET_INVALID');
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-h1-c3', array[%L]::uuid[])$f$, v_ta, v_ua, v_rxid, v_rxver, v_h1),
      'OFFSET_TARGET_INVALID');
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-h1-c4', array[%L, %L]::uuid[])$f$, v_ta, v_ua, v_rxid, v_rxver, v_h2, v_h2),
      'OFFSET_TARGET_INVALID');
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-h1-c5', array[%L]::uuid[])$f$, v_ta, v_ua, v_rxid, v_rxver, v_h4),
      'OFFSET_TARGET_INVALID');
    perform public._th06_expect('B08 phiếu vẫn nháp',
      public._th06_val(format('select status from sales.return_exchange_orders where id = %L', v_rxid)), 'draft');
    perform public._th06_expect('B08 không giao dịch mới',
      public._th06_val(format('select count(*) from receivable.sales_payment_transactions where tenant_id = %L', v_ta)),
      v_tx_before);

    -- B10 Khách lẻ: không có đề xuất, gửi id bất kỳ bị từ chối, xác nhận rỗng hoàn như TH-05
    v_w1 := public._th06_order(v_ta, v_ua, v_store, null, v_p1, v_u1, 10, 1000000, null, 'th06-w1');
    v_rx := public._th06_return(v_ta, v_ua, v_w1, v_p1, v_u1, 2, 'th06-w1-start');
    v_plan := v_rx -> 'eval' -> 'settlementPlan';
    perform public._th06_expect('B10 không ứng viên', jsonb_array_length(v_plan -> 'offsetCandidates')::text, '0');
    perform public._th06_expect('B10 offset', v_plan ->> 'offsetAmountMinor', '0');
    perform public._th06_expect('B10 refund', v_plan ->> 'refundAmountMinor', '200000');
    perform public._th06_expect_err(
      format($f$select public._th06_confirm(%L, %L, %L, %s, 'th06-w1-c1', array[%L]::uuid[])$f$,
        v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, v_o1),
      'OFFSET_TARGET_INVALID');
    perform public._th06_confirm(v_ta, v_ua, (v_rx ->> 'id')::uuid, (v_rx ->> 'version')::int, 'th06-w1-c2', '{}'::uuid[]);
    perform public._th06_expect('B10 hoàn tiền mặt', public._th06_txn(v_w1, 'refund', 'cash', 200000), '1');
    perform public._th06_invariants(v_ta, 'B10');

    -- B14 đã xoá hàm cũ
    perform public._th06_expect('B14 settle_return_exchange_difference đã xoá',
      (to_regprocedure('sales.settle_return_exchange_difference(text,uuid,uuid,text,uuid,uuid,bigint,text,text,text,text,text,text,text,bigint)') is null)::text,
      'true');
  end;


  raise notice 'receivable_th06: OK';
end;
$$;

rollback;
