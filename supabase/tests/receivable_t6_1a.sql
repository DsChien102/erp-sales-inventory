-- T6-1a: ba bảng tiền ở schema receivable, ngày hẹn trả nằm ở quyết toán.
-- Chạy trên DB LOCAL (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/receivable_t6_1a.sql
-- Cuối tệp: raise notice 'receivable_t6_1a: OK'; ca sai đều `raise exception 'FAIL: …'`.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (chép từ sales_th05.sql, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

create function public._t61a_customer(
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
create function public._t61a_finalize(
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
    'lineId', 'line-' || l.ordinality::text,
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

create function public._t61a_line(p_product uuid, p_unit uuid, p_qty_micros bigint, p_price bigint)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', p_qty_micros,
    'unit_price', jsonb_build_object('amount_minor', p_price, 'currency_code', 'VND')
  );
$$;

create function public._t61a_pay(p_amount bigint)
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
  v_t text;
  v_n int;
  v_ua uuid := gen_random_uuid();
  v_ta uuid;
  v_store uuid;
  v_res jsonb;
  v_p1 uuid;
  v_u1 uuid;
  v_unit_id uuid;
  v_wh uuid;
  v_cust uuid;
  v_line1 jsonb;
  v_order uuid;
  v_due date;
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_pay jsonb;
  v_han date;
begin
  -- M01 ba bảng ở receivable, không còn ở sales
  foreach v_t in array array['sales_order_settlements', 'sales_payment_transactions', 'settlement_obligation_adjustments'] loop
    if to_regclass('receivable.' || v_t) is null then
      raise exception 'FAIL: M01 receivable.% không tồn tại', v_t;
    end if;
    if to_regclass('sales.' || v_t) is not null then
      raise exception 'FAIL: M01 sales.% vẫn còn', v_t;
    end if;
  end loop;

  -- M02 cột ngày hẹn
  if exists (select 1 from information_schema.columns
             where table_schema = 'sales' and table_name = 'sales_orders' and column_name = 'payment_due_date') then
    raise exception 'FAIL: M02 sales.sales_orders vẫn còn cột payment_due_date';
  end if;
  if not exists (select 1 from information_schema.columns
                 where table_schema = 'receivable' and table_name = 'sales_order_settlements'
                   and column_name = 'payment_due_date' and data_type = 'date') then
    raise exception 'FAIL: M02 receivable.sales_order_settlements thiếu cột payment_due_date kiểu date';
  end if;

  -- M03 không hàm nào còn trỏ tên cũ
  select count(*) into v_n
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname not in ('pg_catalog', 'information_schema')
    and p.prosrc ~ 'sales\.(sales_order_settlements|sales_payment_transactions|settlement_obligation_adjustments)';
  if v_n <> 0 then
    raise exception 'FAIL: M03 còn % hàm trỏ tên bảng tiền cũ ở schema sales', v_n;
  end if;

  -- M04 không hàm nào đọc ngày hẹn từ đơn
  select count(*) into v_n
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
  where n.nspname not in ('pg_catalog', 'information_schema')
    and p.prosrc ~ '(v_order|so)\.payment_due_date';
  if v_n <> 0 then
    raise exception 'FAIL: M04 còn % hàm đọc payment_due_date từ đơn', v_n;
  end if;

  -- M05 RLS vẫn bật trên 3 bảng
  select count(*) into v_n
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'receivable'
    and c.relname in ('sales_order_settlements', 'sales_payment_transactions', 'settlement_obligation_adjustments')
    and c.relrowsecurity;
  if v_n <> 3 then
    raise exception 'FAIL: M05 RLS bật trên % / 3 bảng receivable', v_n;
  end if;

  -- M06 bán nợ có hẹn → ngày hẹn ở quyết toán, biên lai, AI
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at
  ) values (
    v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    't61a-' || v_ua::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );
  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Cua hang T61A Test', 'contact_phone', '0900000061',
      'contact_email', 't61a@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 61'
    )
  );
  select s.id into v_store from iam.stores s where s.tenant_id = v_ta limit 1;

  perform set_config('request.jwt.claims', json_build_object('sub', v_ua::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  set local role authenticated;

  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_name => 'Thuoc T61A',
    p_reference_id => 'T61A-P1', p_new_unit_name => 'Hop');
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

  v_cust := public._t61a_customer(v_ta, v_ua, 'Khach T61A', '0911000061');
  v_line1 := public._t61a_line(v_p1, v_u1, 1000000, 100000);

  v_res := public._t61a_finalize(v_ta, v_ua, v_store, v_cust,
    jsonb_build_array(v_line1), null, v_today + 3, 'm06-key');
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: M06 finalize expected succeeded, got %', v_res;
  end if;
  v_order := (v_res ->> 'salesOrderId')::uuid;

  reset role;
  select payment_due_date into v_due from receivable.sales_order_settlements
    where tenant_id = v_ta and sales_order_id = v_order;
  set local role authenticated;
  if v_due is distinct from v_today + 3 then
    raise exception 'FAIL: M06 quyết toán payment_due_date expected %, got %', v_today + 3, v_due;
  end if;

  v_res := sales.get_sales_order_payment_summary(gen_random_uuid(), v_ta, v_ua, v_order);
  if v_res ->> 'dueAt' is distinct from to_char(v_today + 3, 'YYYY-MM-DD') then
    raise exception 'FAIL: M06 payment summary dueAt expected %, got %', v_today + 3, v_res ->> 'dueAt';
  end if;

  -- AI: ai_read.don_ban.han_thanh_toan
  reset role;
  perform set_config('ai.tenant_id', v_ta::text, true);
  perform set_config('ai.store_id', v_store::text, true);
  perform set_config('ai.warehouse_id', v_wh::text, true);
  set local role ai_reader;
  select han_thanh_toan into v_han from ai_read.don_ban where don_id = v_order;
  reset role;
  if v_han is distinct from v_today + 3 then
    raise exception 'FAIL: M06 ai_read.don_ban.han_thanh_toan expected %, got %', v_today + 3, v_han;
  end if;

  raise notice 'receivable_t6_1a: OK';
end;
$$;

rollback;
