-- Script dữ liệu bán MÔ PHỎNG 90 ngày cho demo AI-3 ("Cửa hàng Demo AI").
-- Chạy MỘT lần trên Supabase Dev (sau khi đã áp migration 20261121001):
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f scripts/ai/seed_demo_sales.sql
-- Idempotent theo display_name: cửa hàng đã có thì bỏ qua phần dựng, chỉ in bảng kết quả.
-- Tài khoản: demo.chu@vet45.local (chủ), demo.thungan@vet45.local (staff), mật khẩu Demo@12345.
-- Sổ kho / sổ giá trị được lùi cùng ngày đơn (tạm tắt trigger append-only trong khối), nên thẻ kho và lãi gộp khớp lịch sử mô phỏng.
-- Lưu ý: script giữ khoá bảng sổ kho đến hết khối; chạy lúc không ai dùng Dev.

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


do $$
declare
  v_name constant text := 'Cửa hàng Demo AI';
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_store uuid := gen_random_uuid();
  v_wh uuid := gen_random_uuid();
  v_today date := inventory._today();
  v_pw text := extensions.crypt('Demo@12345', extensions.gen_salt('bf'));
  v_p record;
  v_pid uuid;
  v_uid uuid;
  v_d int;
  v_q int;
  v_rate numeric;
  v_orders int;
  v_k int;
  v_o int;
  v_lines jsonb;
  v_total bigint;
  v_res jsonb;
  v_n int := 0;
  v_n2 int;
  v_diag text;
  v_moves jsonb := '[]'::jsonb;
begin
  if exists (select 1 from iam.tenants where display_name = v_name) then
    raise notice 'Cửa hàng demo đã có — bỏ qua dựng dữ liệu.';
    return;
  end if;
  perform setseed(0.42);

  -- Tài khoản ----------------------------------------------------------------
  insert into auth.users (id, instance_id, aud, role, email, encrypted_password, raw_app_meta_data, raw_user_meta_data,
                          email_confirmed_at, created_at, updated_at,
                          confirmation_token, recovery_token, email_change_token_new, email_change)
  values
    (v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'demo.chu@vet45.local',
     v_pw, '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now(), '', '', '', ''),
    (v_staff, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated', 'demo.thungan@vet45.local',
     v_pw, '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now(), '', '', '', '');
  insert into auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  values
    (gen_random_uuid(), v_owner, jsonb_build_object('sub', v_owner::text, 'email', 'demo.chu@vet45.local', 'email_verified', true),
     'email', v_owner::text, now(), now(), now()),
    (gen_random_uuid(), v_staff, jsonb_build_object('sub', v_staff::text, 'email', 'demo.thungan@vet45.local', 'email_verified', true),
     'email', v_staff::text, now(), now(), now());

  insert into iam.platform_user_profiles (user_id, email_verified, given_name, family_middle_name)
  values (v_owner, true, 'Chủ', 'Demo'), (v_staff, true, 'Thu ngân', 'Demo')
  on conflict (user_id) do update
    set given_name = excluded.given_name, family_middle_name = excluded.family_middle_name;

  -- Cửa hàng, kho, thành viên ---------------------------------------------------
  insert into iam.tenants (id, display_name) values (v_t, v_name);
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_t, v_owner, 'store_owner', true), (v_t, v_staff, 'staff', false);
  insert into iam.stores (id, tenant_id, code, display_name, status) values (v_store, v_t, 'DEMOAI', v_name, 'active');
  insert into inventory.warehouses (id, tenant_id, display_name, status) values (v_wh, v_t, 'Kho Demo AI', 'active');
  insert into inventory.store_warehouse_assignments (tenant_id, store_id, warehouse_id, status)
  values (v_t, v_store, v_wh, 'active');

  perform set_config('request.jwt.claims', json_build_object('sub', v_owner::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  insert into inventory.cost_policies (tenant_id, method, changed_by) values (v_t, 'MOVING', v_owner);

  -- Sản phẩm: kiểu bán (even/ramp/erratic/slow), tốc độ, đầu-cuối, giá, tồn cuối, ngưỡng, mục tiêu
  create temp table demo_products (
    idx int primary key, name text, kind text, rate_lo numeric, rate_hi numeric, price bigint,
    final_stock int, thr int, tgt int, product_id uuid, unit_id uuid, sold int default 0
  ) on commit drop;
  insert into demo_products (idx, name, kind, rate_lo, rate_hi, price, final_stock, thr, tgt) values
    (1,  'Sữa tươi hộp 1L', 'even',    12,  12,   8000,  40,  60, 240),
    (2,  'Mì gói',          'even',    30,  30,   4000, 500, 150, 600),
    (3,  'Nước suối 500ml', 'ramp',    10,  25,   5000,  70, 100, 400),
    (4,  'Dầu ăn 1L',       'even',     5,   5,  45000, 120,  30, 100),
    (5,  'Gạo 5kg',         'erratic',  6,   6,  90000,  20,  25,  80),
    (6,  'Đường 1kg',       'slow',   1.5, 1.5,  25000,  18,  10,  40),
    (7,  'Bánh quy',        'ramp',     3,   9,  20000,   0,  20,  80),
    (8,  'Nước ngọt lon',   'erratic', 15,  15,  10000,  30,  40, 160),
    (9,  'Bột giặt 3kg',    'slow',     1,   1, 120000,  25,   5,  20),
    (10, 'Giấy vệ sinh lốc','even',     4,   4,  60000,   6,   8,  40),
    (11, 'Xà phòng',        'slow',   0.8, 0.8,  15000,  50,  10,  30),
    (12, 'Cà phê gói',      'even',     8,   8,   3500,  90, null, null);

  for v_p in select * from demo_products order by idx loop
    v_pid := gen_random_uuid();
    v_uid := gen_random_uuid();
    insert into catalog.products (id, tenant_id, name, sku, tracking_mode, expiry_required, business_status, is_ready_to_sell, reference_id, created_by, updated_by)
    values (v_pid, v_t, v_p.name, 'DEMO-' || v_p.idx, 'none', false, 'active', true, 'DEMO-REF-' || v_p.idx, v_owner, v_owner);
    insert into catalog.product_units (id, tenant_id, product_id, unit_name, conversion_rate_to_base, is_base_unit)
    values (v_uid, v_t, v_pid, 'hộp', 1, true);
    perform catalog.set_product_unit_price_band(p_tenant_id => v_t, p_product_id => v_pid, p_product_unit_id => v_uid, p_source_type => 'manual',
      p_list_price_before_vat => v_p.price, p_list_price_after_vat => v_p.price,
      p_floor_price_before_vat => v_p.price / 2, p_floor_price_after_vat => v_p.price / 2);
    update demo_products set product_id = v_pid, unit_id = v_uid where idx = v_p.idx;
    if v_p.thr is not null then
      insert into inventory.product_stock_policies (tenant_id, product_id, reorder_threshold, target_level, updated_by)
      values (v_t, v_pid, v_p.thr, v_p.tgt, v_owner);
    end if;
  end loop;
  update catalog.products set is_ready_to_sell = true where tenant_id = v_t;

  -- Kế hoạch bán: mỗi (ngày, sản phẩm) một số lượng; mỗi ngày 2-4 đơn ------------
  create temp table demo_plan (d int, idx int, qty int, ord int) on commit drop;
  for v_d in reverse 89..0 loop
    v_orders := 2 + floor(random() * 3)::int;
    for v_p in select * from demo_products order by idx loop
      v_rate := v_p.rate_lo + (v_p.rate_hi - v_p.rate_lo) * (89 - v_d) / 89.0;
      v_q := case v_p.kind
        when 'even'    then round(v_rate * (0.7 + 0.6 * random()))
        when 'ramp'    then round(v_rate * (0.7 + 0.6 * random()))
        when 'erratic' then case when random() < 0.3 then round(v_rate * 3 * (0.7 + 0.6 * random()))
                                 else round(v_rate * 0.15 * (0.7 + 0.6 * random())) end
        else               case when random() < least(v_rate / 2.0, 1) then round(2 * (0.7 + 0.6 * random())) else 0 end
      end;
      if v_q > 0 then
        insert into demo_plan values (v_d, v_p.idx, v_q, 1 + floor(random() * v_orders)::int);
      end if;
    end loop;
  end loop;

  update demo_products dp set sold = coalesce((select sum(qty) from demo_plan p where p.idx = dp.idx), 0);

  -- Tồn đầu = tồn cuối + đã bán ------------------------------------------------
  select jsonb_agg(jsonb_build_object('product_id', product_id, 'quantity_delta', final_stock + sold,
                                      'unit_cost', price * 6 / 10, 'movement_kind', 'RECEIPT'))
  into v_moves from demo_products where final_stock + sold > 0;
  perform inventory._post_movements(v_t, v_wh, 'SETUP', gen_random_uuid(), v_today, v_moves, v_owner);

  -- Kiểm tồn sau khi nhập: phải bằng tồn cuối + tổng sẽ bán (chẩn đoán sớm)
  select string_agg(format('%s: có %s, cần %s', dp.name, coalesce(sr.available, 0), dp.final_stock + dp.sold), '; ')
  into v_diag
  from demo_products dp
  left join inventory._product_stock_rows(v_t) sr on sr.product_id = dp.product_id
  where coalesce(sr.available, 0) <> dp.final_stock + dp.sold;
  if v_diag is not null then
    raise exception 'seed: tồn sau nhập không khớp: %', v_diag;
  end if;

  -- Tạo đơn (khuôn rep_finalize) rồi lùi completed_at -------------------------
  for v_d in reverse 89..0 loop
    for v_o in 1..4 loop
      select jsonb_agg(pg_temp.rep_line(dp.product_id, dp.unit_id, p.qty * 1000000::bigint, dp.price) order by dp.idx),
             sum(p.qty * dp.price)
      into v_lines, v_total
      from demo_plan p join demo_products dp on dp.idx = p.idx
      where p.d = v_d and p.ord = v_o;
      continue when v_lines is null;
      v_res := pg_temp.rep_finalize(v_t, v_owner, v_store, v_lines, pg_temp.rep_pay(v_total),
                                    'demo-' || v_d || '-' || v_o);
      if v_res ->> 'status' <> 'succeeded' then
        select string_agg(format('%s: cần %s, còn %s', dp.name, p.qty, coalesce(sr.available, 0)), '; ')
        into v_diag
        from demo_plan p
        join demo_products dp on dp.idx = p.idx
        left join inventory._product_stock_rows(v_t) sr on sr.product_id = dp.product_id
        where p.d = v_d and p.ord = v_o;
        raise exception 'seed: đơn ngày -% #% lỗi: % | tồn: %', v_d, v_o, v_res, v_diag;
      end if;
      if v_d > 0 then
        update sales.sales_orders set completed_at = completed_at - (v_d || ' days')::interval
        where tenant_id = v_t and id = (v_res ->> 'salesOrderId')::uuid;
      end if;
      v_n := v_n + 1;
    end loop;
  end loop;

  -- Lùi cả sổ kho / sổ giá trị cho khớp ngày đơn (báo cáo lãi gộp theo sản phẩm lấy giá vốn
  -- theo value_movements.business_date, doanh thu theo completed_at). Sổ là append-only nên tạm tắt trigger.
  alter table inventory.stock_movements disable trigger user;
  alter table inventory.value_movements disable trigger user;

  update inventory.stock_movements sm
  set business_date = (so.completed_at at time zone 'Asia/Ho_Chi_Minh')::date
  from sales.sales_orders so
  where sm.tenant_id = v_t and so.tenant_id = v_t
    and sm.intent_id = so.id and sm.movement_kind = 'SALE';
  get diagnostics v_n2 = row_count;
  if v_n2 = 0 then
    raise exception 'seed: không khớp được dòng xuất kho với đơn bán (intent_id) — dừng, không lùi sổ';
  end if;

  update inventory.stock_movements
  set business_date = v_today - 90
  where tenant_id = v_t and movement_kind = 'RECEIPT';

  update inventory.value_movements vm
  set business_date = sm.business_date
  from inventory.stock_movements sm
  where vm.tenant_id = v_t and sm.tenant_id = v_t and vm.movement_id = sm.id;

  alter table inventory.stock_movements enable trigger user;
  alter table inventory.value_movements enable trigger user;

  raise notice 'Đã tạo % đơn bán mô phỏng; lùi % dòng xuất kho.', v_n, v_n2;
end;
$$;

-- Kết quả -----------------------------------------------------------------------
select t.id as tenant_id, 'demo.chu@vet45.local' as owner_email, 'demo.thungan@vet45.local' as cashier_email,
       'Sữa tươi hộp 1L' as san_pham_a,
       (select o.order_code from sales.sales_orders o where o.tenant_id = t.id order by o.completed_at desc, o.created_at desc limit 1) as ma_don
from iam.tenants t where t.display_name = 'Cửa hàng Demo AI';

begin;
select set_config('request.jwt.claims', json_build_object('sub', u.id::text, 'role', 'authenticated')::text, true),
       set_config('request.jwt.claim.sub', u.id::text, true)
from auth.users u where u.email = 'demo.chu@vet45.local';
select e->>'name' as ten, e->>'available' as ton, e->>'daily_rate' as ban_ngay, e->>'days_left' as con_ngay,
       e->>'suggest_qty' as nen_nhap
from iam.tenants t,
     lateral jsonb_array_elements(inventory.get_purchase_forecast(t.id, null, false, 20)->'rows') e
where t.display_name = 'Cửa hàng Demo AI';
rollback;
