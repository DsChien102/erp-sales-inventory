-- TH-04 mục 9.3 "SQL / RPC test" (6-B Task 1 + Task 2): RPC pricing, lọc/sắp server, giá sàn hiện tại, lịch sử.
-- Chạy trên DB LOCAL sau `supabase db reset`:
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/pricing_th04.sql
-- Kết thúc bằng `raise notice 'pricing_th04: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp
-- ---------------------------------------------------------------------------

create function public._th04_expect_err(p_sql text, p_code text)
returns void
language plpgsql
as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm like '%' || p_code || '%' then
      return;
    end if;
    raise exception 'FAIL: expected [%] but got [%] for: %', p_code, sqlerrm, p_sql;
  end;
  raise exception 'FAIL: expected [%] but statement succeeded: %', p_code, p_sql;
end;
$$;

create function public._th04_person(
  p_tenant uuid, p_actor uuid, p_name text, p_phone text default '0901234567'
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

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();
  v_ta uuid;
  v_store_id uuid;
  v_claims text;
  v_res jsonb;
  v_res2 jsonb;
  v_cust1 uuid;
  v_cust2 uuid;
  v_cust3 uuid;
  v_cust4 uuid;
  v_cust5 uuid;
  v_cust_anbinh uuid;
  v_cust_ankhang uuid;
  v_cust_binhminh uuid;
  v_cust_cuong uuid;
  v_p1 uuid;
  v_u1 uuid;
  v_p2 uuid;
  v_u2 uuid;
  v_rule_a uuid := gen_random_uuid();
  v_rule_c uuid := gen_random_uuid();
  v_rule_below uuid := gen_random_uuid();
  v_rule_exp uuid := gen_random_uuid();
  v_rule_dyn uuid := gen_random_uuid();
  v_rule_over uuid := gen_random_uuid();
  v_rule_over_new uuid := gen_random_uuid();
  v_rule_edit uuid := gen_random_uuid();
  v_rule_sort_anbinh uuid := 'a0000000-0000-4000-8000-000000000002'::uuid;
  v_rule_sort_cuong uuid := 'a0000000-0000-4000-8000-000000000001'::uuid;
  v_ub uuid := gen_random_uuid();
  v_note text;
  v_cursor text;
  v_items jsonb;
  v_total int;
  v_count int;
  v_detail jsonb;
begin
  -- 0) Dựng tenant + owner
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values (
    v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'th04-' || v_ua::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Cua hang TH04 Pricing Test', 'contact_phone', '0900000004',
      'contact_email', 'th04@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 4'
    )
  );
  if v_ta is null then
    raise exception 'FAIL: tenant was not created';
  end if;

  select s.id into v_store_id from iam.stores s where s.tenant_id = v_ta limit 1;

  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  -- Test đọc trực tiếp bảng pricing / catalog: cấp quyền đọc trong transaction (rollback cuối tệp).
  grant usage on schema pricing, catalog to authenticated;
  grant select on all tables in schema pricing to authenticated;
  grant select on all tables in schema catalog to authenticated;
  -- reenable_customer_price_rule cần secret trong Vault (deploy tạo; local sau reset chưa có).
  if not exists (select 1 from vault.secrets where name = 'pricing_reenable_fingerprint_hmac_v1') then
    perform vault.create_secret('th04-test-secret', 'pricing_reenable_fingerprint_hmac_v1');
  end if;
  -- RLS chặn đọc trực tiếp; tắt trong transaction để đối chiếu số liệu (RPC không phụ thuộc RLS).
  declare
    v_t record;
  begin
    for v_t in select tablename from pg_tables where schemaname = 'pricing' loop
      execute format('alter table pricing.%I disable row level security', v_t.tablename);
    end loop;
  end;
  set local role authenticated;

  -- Tạo sản phẩm P1 (base unit Hop)
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'Thuoc P1 TH04',
    p_reference_id => 'REF-P1',
    p_new_unit_name => 'Hop'
  );
  v_p1 := (v_res ->> 'product_id')::uuid;
  reset role;
  select id into v_u1 from catalog.product_units where product_id = v_p1 and is_base_unit = true;
  set local role authenticated;

  -- Thiết lập khung giá cho P1 (list 150.000, floor 100.000)
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 150000,
    p_list_price_after_vat => 150000,
    p_floor_price_before_vat => 100000,
    p_floor_price_after_vat => 100000
  );

  -- Tạo khách hàng
  v_cust1 := public._th04_person(v_ta, v_ua, 'Khach Hang 1', '0911000001');
  v_cust2 := public._th04_person(v_ta, v_ua, 'Khach Hang 2', '0911000002');
  v_cust3 := public._th04_person(v_ta, v_ua, 'Khach Hang 3', '0911000003');
  v_cust4 := public._th04_person(v_ta, v_ua, 'Khach Hang 4', '0911000004');

  -- =========================================================================
  -- Ca 1: create_customer_price_rule idempotency
  -- =========================================================================
  v_res := pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => gen_random_uuid(),
    p_customer_id => v_cust1,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 120000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_idempotency_key => 'idem-ca1'
  );

  -- Gọi lại cùng key và payload
  v_res2 := pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => gen_random_uuid(),
    p_customer_id => v_cust1,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 120000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_idempotency_key => 'idem-ca1'
  );
  if (v_res -> 'rule' ->> 'id') <> (v_res2 -> 'rule' ->> 'id') then
    raise exception 'FAIL: Ca 1 replay did not return same rule id';
  end if;

  select count(*) into v_count
  from pricing.customer_price_rules
  where tenant_id = v_ta and idempotency_key = 'idem-ca1';
  if v_count <> 1 then
    raise exception 'FAIL: Ca 1 expected 1 rule, got %', v_count;
  end if;

  -- Cùng key khác giá -> IDEMPOTENCY_CONFLICT
  perform public._th04_expect_err(
    format(
      'select pricing.create_customer_price_rule(%L, %L, %L, %L, %L, 130000, ''VND'', ''2026-01-01''::date, ''idem-ca1'')',
      v_ta, gen_random_uuid(), v_cust1, v_p1, v_u1
    ),
    'IDEMPOTENCY_CONFLICT'
  );

  -- =========================================================================
  -- Ca 2: I-01 Exclusion constraint khi giao khoảng hiệu lực
  -- =========================================================================
  -- A: 2026-01-01 -> null
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_a,
    p_customer_id => v_cust2,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 110000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_effective_to => null,
    p_idempotency_key => 'idem-ca2-a'
  );

  -- C: 2025-01-01 -> 2025-06-30
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_c,
    p_customer_id => v_cust2,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 115000,
    p_currency_code => 'VND',
    p_effective_from => '2025-01-01'::date,
    p_effective_to => '2025-06-30'::date,
    p_idempotency_key => 'idem-ca2-c'
  );

  reset role;
  begin
    update pricing.customer_price_rules set effective_to = null where id = v_rule_c;
    raise exception 'FAIL: Ca 2 expected exclusion constraint violation 23P01';
  exception
    when sqlstate '23P01' then
      -- expected exclusion constraint violation
      null;
  end;
  set local role authenticated;

  -- =========================================================================
  -- Ca 3: Dưới sàn chặn khi không xác nhận, cảnh báo khi có xác nhận
  -- =========================================================================
  perform public._th04_expect_err(
    format(
      'select pricing.create_customer_price_rule(%L, %L, %L, %L, %L, 90000, ''VND'', ''2026-01-01''::date, ''idem-ca3-blk'', null, null, false)',
      v_ta, gen_random_uuid(), v_cust3, v_p1, v_u1
    ),
    'BELOW_FLOOR_BLOCKED'
  );

  v_res := pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_below,
    p_customer_id => v_cust3,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 90000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_idempotency_key => 'idem-ca3-ack',
    p_acknowledge_floor_warning => true
  );
  if (v_res -> 'rule' -> 'validation_outcome' ->> 'outcome') is distinct from 'warning'
    or not ((v_res -> 'rule' -> 'validation_outcome' -> 'warning_codes') ? 'below_floor_price') then
    raise exception 'FAIL: Ca 3 expected review_status warning with below_floor_price';
  end if;

  -- =========================================================================
  -- Ca 4: H5 Lý do sửa giá riêng
  -- =========================================================================
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_customer_id => v_cust4,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 130000,
    p_currency_code => 'VND',
    p_effective_from => '2027-01-01'::date,
    p_note => 'Ghi chu ban dau',
    p_idempotency_key => 'idem-ca4-init'
  );

  -- Sửa lần 1: truyền note và reason
  perform pricing.update_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_expected_version => 1,
    p_rule_price_minor => 135000,
    p_effective_from => '2027-01-01'::date,
    p_effective_to => null,
    p_note => 'Ghi chú cũ',
    p_reason => 'Theo hợp đồng Q3'
  );

  -- Kiểm tra note = 'Ghi chú cũ' trên bảng
  select note into v_note from pricing.customer_price_rules where id = v_rule_edit;
  if v_note is distinct from 'Ghi chú cũ' then
    raise exception 'FAIL: Ca 4 expected note = ''Ghi chú cũ'', got %', v_note;
  end if;

  -- Kiểm tra dòng lịch sử updated mới nhất có new_value ->> 'reason' = 'Theo hợp đồng Q3'
  select new_value into v_res
  from pricing.customer_price_rule_activities
  where customer_price_rule_id = v_rule_edit and activity_type = 'updated'
  order by created_at desc, id desc
  limit 1;
  if (v_res ->> 'reason') is distinct from 'Theo hợp đồng Q3' then
    raise exception 'FAIL: Ca 4 expected activity reason = ''Theo hợp đồng Q3'', got %', v_res ->> 'reason';
  end if;

  -- get_customer_price_rule_history trả item sửa có reason = 'Theo hợp đồng Q3'
  v_res := pricing.get_customer_price_rule_history(v_ta, v_rule_edit);
  -- Cùng transaction nên created_at trùng nhau, thứ tự item không ổn định: tìm theo activity_type.
  if (
    select i ->> 'reason'
    from jsonb_array_elements(v_res -> 'items') i
    where i ->> 'activity_type' = 'updated'
    limit 1
  ) is distinct from 'Theo hợp đồng Q3' then
    raise exception 'FAIL: Ca 4 history updated item reason unexpected: %', v_res -> 'items';
  end if;

  -- Sửa lần 2 không truyền p_reason: note giữ, new_value ->> 'reason' là null
  perform pricing.update_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_expected_version => 2,
    p_rule_price_minor => 136000,
    p_effective_from => '2027-01-01'::date,
    p_effective_to => null,
    p_note => 'Ghi chú cũ'
  );
  select note into v_note from pricing.customer_price_rules where id = v_rule_edit;
  if v_note is distinct from 'Ghi chú cũ' then
    raise exception 'FAIL: Ca 4 note changed after second update';
  end if;
  -- Cùng transaction nên created_at trùng nhau: chọn dòng sửa lần 2 theo giá 136000.
  select new_value into v_res
  from pricing.customer_price_rule_activities
  where customer_price_rule_id = v_rule_edit and activity_type = 'updated'
    and (new_value ->> 'rule_price_minor')::bigint = 136000
  limit 1;
  if (v_res ->> 'reason') is not null then
    raise exception 'FAIL: Ca 4 expected null reason when p_reason omitted';
  end if;

  -- Kiểm tra p_reason dài 201 ký tự bị VALIDATION_ERROR, 200 ký tự thành công
  perform public._th04_expect_err(
    format(
      'select pricing.update_customer_price_rule(%L, %L, 3, 137000, ''2027-01-01''::date, null, null, false, false, %L)',
      v_ta, v_rule_edit, repeat('a', 201)
    ),
    'VALIDATION_ERROR'
  );
  perform pricing.update_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_expected_version => 3,
    p_rule_price_minor => 137000,
    p_effective_from => '2027-01-01'::date,
    p_reason => repeat('a', 200)
  );

  -- =========================================================================
  -- Ca 5: Giá riêng hết hạn, tắt, bật lại -> INVALID_STATUS
  -- =========================================================================
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_exp,
    p_customer_id => public._th04_person(v_ta, v_ua, 'Khach Expired'),
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 125000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_effective_to => '2026-01-31'::date,
    p_idempotency_key => 'idem-ca5'
  );
  perform pricing.disable_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_exp,
    p_expected_version => 1,
    p_reason => 'Tat thu nghiem'
  );

  perform public._th04_expect_err(
    format(
      'select pricing.reenable_customer_price_rule(%L, %L, 2, current_date)',
      v_ta, v_rule_exp
    ),
    'INVALID_STATUS'
  );

  -- =========================================================================
  -- Ca 6: H2 Sắp xếp và phân trang trên 4 khách
  -- =========================================================================
  v_cust_anbinh := public._th04_person(v_ta, v_ua, 'Đại lý An Bình', '0911000011');
  v_cust_ankhang := public._th04_person(v_ta, v_ua, 'an khang', '0911000012');
  v_cust_binhminh := public._th04_person(v_ta, v_ua, 'Bình Minh', '0911000013');
  v_cust_cuong := public._th04_person(v_ta, v_ua, 'Cường', '0911000014');

  -- Tạo sản phẩm riêng P2 để test sắp xếp độc lập
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'Thuoc P2 TH04',
    p_reference_id => 'REF-P2',
    p_new_unit_name => 'Vien'
  );
  v_p2 := (v_res ->> 'product_id')::uuid;
  reset role;
  select id into v_u2 from catalog.product_units where product_id = v_p2 and is_base_unit = true;
  set local role authenticated;

  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_p2,
    p_product_unit_id => v_u2,
    p_source_type => 'manual',
    p_list_price_before_vat => 200000,
    p_list_price_after_vat => 200000,
    p_floor_price_before_vat => 50000,
    p_floor_price_after_vat => 50000
  );

  perform pricing.create_customer_price_rule(
    v_ta, v_rule_sort_anbinh, v_cust_anbinh, v_p2, v_u2, 100000, 'VND', '2026-01-01'::date, 'idem-sort-1'
  );
  perform pricing.create_customer_price_rule(
    v_ta, gen_random_uuid(), v_cust_ankhang, v_p2, v_u2, 120000, 'VND', '2026-01-01'::date, 'idem-sort-2'
  );
  perform pricing.create_customer_price_rule(
    v_ta, gen_random_uuid(), v_cust_binhminh, v_p2, v_u2, 90000, 'VND', '2026-01-01'::date, 'idem-sort-3'
  );
  perform pricing.create_customer_price_rule(
    v_ta, v_rule_sort_cuong, v_cust_cuong, v_p2, v_u2, 100000, 'VND', '2026-01-01'::date, 'idem-sort-4'
  );

  -- Phân trang theo price_desc limit 2
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_product_id => v_p2,
    p_limit => 2,
    p_sort => 'price_desc'
  );
  if (v_res ->> 'total_count')::int <> 4 then
    raise exception 'FAIL: Ca 6 page 1 total_count <> 4 (got %)', v_res ->> 'total_count';
  end if;
  if (v_res ->> 'has_more')::boolean is not true then
    raise exception 'FAIL: Ca 6 page 1 has_more is false';
  end if;
  v_items := v_res -> 'items';
  if jsonb_array_length(v_items) <> 2
    or (v_items -> 0 -> 'price' ->> 'amount_minor')::int <> 120000
    or (v_items -> 1 -> 'price' ->> 'amount_minor')::int <> 100000 then
    raise exception 'FAIL: Ca 6 page 1 items unexpected: %', v_items;
  end if;

  v_cursor := v_res ->> 'next_cursor';
  v_res2 := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_product_id => v_p2,
    p_limit => 2,
    p_sort => 'price_desc',
    p_cursor => v_cursor
  );
  if (v_res2 ->> 'total_count')::int <> 4 then
    raise exception 'FAIL: Ca 6 page 2 total_count <> 4';
  end if;
  v_items := v_res2 -> 'items';
  if jsonb_array_length(v_items) <> 2
    or (v_items -> 0 -> 'price' ->> 'amount_minor')::int <> 100000
    or (v_items -> 1 -> 'price' ->> 'amount_minor')::int <> 90000 then
    raise exception 'FAIL: Ca 6 page 2 items unexpected: %', v_items;
  end if;

  -- Kiểm tra Review Focus 1: hai giá riêng 100 000 là hai dòng khác nhau và thứ tự theo id desc
  if (v_res -> 'items' -> 1 ->> 'id') is distinct from v_rule_sort_anbinh::text
    or (v_res2 -> 'items' -> 0 ->> 'id') is distinct from v_rule_sort_cuong::text then
    raise exception 'FAIL: Ca 6 page 1 item 1 must be An Binh, page 2 item 0 must be Cuong (got % and %)',
      v_res -> 'items' -> 1 ->> 'id', v_res2 -> 'items' -> 0 ->> 'id';
  end if;
  if not ((v_res -> 'items' -> 1 ->> 'id')::uuid > (v_res2 -> 'items' -> 0 ->> 'id')::uuid) then
    raise exception 'FAIL: Ca 6 tie-break id desc failed: % not > %',
      v_res -> 'items' -> 1 ->> 'id', v_res2 -> 'items' -> 0 ->> 'id';
  end if;
  if (v_res -> 'items' -> 1 -> 'customer' ->> 'display_name') is distinct from 'Đại lý An Bình'
    or (v_res2 -> 'items' -> 0 -> 'customer' ->> 'display_name') is distinct from 'Cường' then
    raise exception 'FAIL: Ca 6 customer names wrong on tie-break';
  end if;

  -- Sắp customer_name_asc: "an khang" < "Bình Minh" < "Cường" < "Đại lý An Bình"
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_product_id => v_p2,
    p_limit => 4,
    p_sort => 'customer_name_asc'
  );
  v_items := v_res -> 'items';
  if (v_items -> 0 -> 'customer' ->> 'display_name') is distinct from 'an khang'
    or (v_items -> 1 -> 'customer' ->> 'display_name') is distinct from 'Bình Minh'
    or (v_items -> 2 -> 'customer' ->> 'display_name') is distinct from 'Cường'
    or (v_items -> 3 -> 'customer' ->> 'display_name') is distinct from 'Đại lý An Bình' then
    raise exception 'FAIL: Ca 6 customer_name_asc order wrong: %', v_items;
  end if;

  -- Cursor price_desc gửi kèm price_asc -> VALIDATION_ERROR
  perform public._th04_expect_err(
    format(
      'select pricing.search_customer_price_rules(%L, current_date, p_sort => ''price_asc'', p_cursor => %L)',
      v_ta, v_cursor
    ),
    'VALIDATION_ERROR'
  );

  -- p_sort không hợp lệ -> VALIDATION_ERROR
  perform public._th04_expect_err(
    format(
      'select pricing.search_customer_price_rules(%L, current_date, p_sort => ''abc'')',
      v_ta
    ),
    'VALIDATION_ERROR'
  );

  -- =========================================================================
  -- Ca 7: Q9 Lọc thời gian cập nhật
  -- =========================================================================
  reset role;
  update pricing.customer_price_rules
  set updated_at = statement_timestamp() - interval '10 days'
  where id = v_rule_a;
  set local role authenticated;

  -- updated_within_days = 7 không thấy v_rule_a
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_customer_id => v_cust2,
    p_updated_within_days => 7
  );
  if exists (
    select 1 from jsonb_array_elements(v_res -> 'items') it
    where (it ->> 'id')::uuid = v_rule_a
  ) then
    raise exception 'FAIL: Ca 7 7-day window should not contain 10-day old rule';
  end if;

  -- updated_within_days = 30 thấy v_rule_a
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_customer_id => v_cust2,
    p_updated_within_days => 30
  );
  if not exists (
    select 1 from jsonb_array_elements(v_res -> 'items') it
    where (it ->> 'id')::uuid = v_rule_a
  ) then
    raise exception 'FAIL: Ca 7 30-day window must contain 10-day old rule';
  end if;

  -- updated_within_days = 5 -> VALIDATION_ERROR
  perform public._th04_expect_err(
    format(
      'select pricing.search_customer_price_rules(%L, current_date, p_updated_within_days => 5)',
      v_ta
    ),
    'VALIDATION_ERROR'
  );

  -- =========================================================================
  -- Ca 8: H3 Dưới giá sàn theo giá sàn hiện tại
  -- =========================================================================
  -- Tạo rule 110.000 khi sàn 100.000 (không dưới sàn)
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_dyn,
    p_customer_id => public._th04_person(v_ta, v_ua, 'Khach Dyn Floor', '0911000015'),
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 110000,
    p_currency_code => 'VND',
    p_effective_from => '2026-01-01'::date,
    p_idempotency_key => 'idem-ca8'
  );

  -- Nâng sàn lên 120.000
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 150000,
    p_list_price_after_vat => 150000,
    p_floor_price_before_vat => 120000,
    p_floor_price_after_vat => 120000
  );

  -- search below_floor phải có v_rule_dyn
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_quick_filter => 'below_floor'
  );
  if not exists (
    select 1 from jsonb_array_elements(v_res -> 'items') it
    where (it ->> 'id')::uuid = v_rule_dyn
      and (it -> 'validation_outcome' -> 'warning_codes') ? 'below_floor_price'
  ) then
    raise exception 'FAIL: Ca 8 search below_floor did not reflect raised floor price';
  end if;

  -- chi tiết cũng phải có warning_codes below_floor_price
  v_detail := pricing._get_customer_price_rule_detail_s3(v_ta, v_rule_dyn, current_date);
  if not ((v_detail -> 'validation_outcome' -> 'warning_codes') ? 'below_floor_price') then
    raise exception 'FAIL: Ca 8 detail did not reflect raised floor price';
  end if;

  -- Hạ giá sàn xuống 80.000 -> v_rule_below (90.000) không còn dưới sàn
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 150000,
    p_list_price_after_vat => 150000,
    p_floor_price_before_vat => 80000,
    p_floor_price_after_vat => 80000
  );

  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_quick_filter => 'below_floor'
  );
  if exists (
    select 1 from jsonb_array_elements(v_res -> 'items') it
    where (it ->> 'id')::uuid = v_rule_below
  ) then
    raise exception 'FAIL: Ca 8 lowered floor price should remove rule from below_floor filter';
  end if;

  v_detail := pricing._get_customer_price_rule_detail_s3(v_ta, v_rule_below, current_date);
  if (v_detail -> 'validation_outcome' -> 'warning_codes') ? 'below_floor_price' then
    raise exception 'FAIL: Ca 8 detail should remove below_floor_price when floor is lowered';
  end if;

  -- Ngừng bán đơn vị -> search p_quick_filter => 'all' vẫn có dòng đó, không lỗi
  reset role;
  update catalog.product_units set is_active = false where id = v_u1;
  set local role authenticated;
  v_res := pricing.search_customer_price_rules(
    p_tenant_id => v_ta,
    p_business_date => current_date,
    p_quick_filter => 'all'
  );
  if not exists (
    select 1 from jsonb_array_elements(v_res -> 'items') it
    where (it ->> 'id')::uuid = v_rule_dyn
  ) then
    raise exception 'FAIL: Ca 8 rule missing when unit deactivated';
  end if;

  -- =========================================================================
  -- Ca 9: H6 Tên thành viên trong lịch sử và chi tiết
  -- =========================================================================
  -- Chèn profile cho owner v_ua: 'Nguyễn', 'Lan'
  reset role;
  insert into iam.platform_user_profiles (
    user_id, family_middle_name, given_name, phone_number
  ) values (
    v_ua, 'Nguyễn', 'Lan', '0900000004'
  ) on conflict (user_id) do update
  set family_middle_name = excluded.family_middle_name,
      given_name = excluded.given_name;
  set local role authenticated;

  -- Kiểm tra get_customer_price_rule_history: actor.display_name = 'Nguyễn Lan'
  v_res := pricing.get_customer_price_rule_history(v_ta, v_rule_edit);
  if (v_res -> 'items' -> 0 -> 'actor' ->> 'display_name') is distinct from 'Nguyễn Lan' then
    raise exception 'FAIL: Ca 9 history actor display_name <> ''Nguyễn Lan'' (got %)',
      v_res -> 'items' -> 0 -> 'actor' ->> 'display_name';
  end if;

  -- Tắt rule -> kiểm tra kết quả disable_customer_price_rule và get_customer_price_rule_detail
  v_res2 := pricing.disable_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_expected_version => 4,
    p_reason => 'Tat de kiem tra display name'
  );
  if (v_res2 ->> 'disabled_by_name') is distinct from 'Nguyễn Lan' then
    raise exception 'FAIL: Ca 9 disable result disabled_by_name is distinct from ''Nguyễn Lan'' (got %)',
      v_res2 ->> 'disabled_by_name';
  end if;

  v_detail := pricing.get_customer_price_rule_detail(v_ta, v_rule_edit, current_date);
  if (v_detail ->> 'disabled_by_name') is distinct from 'Nguyễn Lan'
    or (v_detail ->> 'updated_by_name') is distinct from 'Nguyễn Lan' then
    raise exception 'FAIL: Ca 9 detail names is distinct from ''Nguyễn Lan'': disabled_by_name=%, updated_by_name=%',
      v_detail ->> 'disabled_by_name',
      v_detail ->> 'updated_by_name';
  end if;

  -- Tạo user 2 trong tenant (thành viên) không có profile, chỉ có email b@th04.test
  reset role;
  -- Đơn vị đã ngừng ở Ca 8; sửa rule cần đơn vị còn hiệu lực.
  update catalog.product_units set is_active = true where id = v_u1;
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values (
    v_ub, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'b@th04.test',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );
  insert into iam.memberships (
    tenant_id, user_id, role, is_owner, version, created_at, updated_at
  ) values (
    v_ta, v_ub, 'store_owner', false, 1, now(), now()
  );

  -- Đóng vai user 2 để sửa rule v_rule_edit
  v_claims := json_build_object('sub', v_ub::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ub::text, true);
  set local role authenticated;

  perform pricing.update_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_edit,
    p_expected_version => 5,
    p_rule_price_minor => 138000,
    p_effective_from => '2027-01-01'::date,
    p_reason => 'User 2 sua gia'
  );

  -- Kiểm tra lịch sử có actor.display_name = 'b@th04.test'
  v_res := pricing.get_customer_price_rule_history(v_ta, v_rule_edit);
  if (
    select i -> 'actor' ->> 'display_name'
    from jsonb_array_elements(v_res -> 'items') i
    where i ->> 'reason' = 'User 2 sua gia'
    limit 1
  ) is distinct from 'b@th04.test' then
    raise exception 'FAIL: Ca 9 user 2 actor display_name <> ''b@th04.test'' (items %)', v_res -> 'items';
  end if;

  -- Trả lại claims cho v_ua
  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);

  -- Kiểm tra hàm: iam._member_display_name(null) trả về null (gọi bằng vai trò postgres sau khi revoke authenticated)
  reset role;
  if iam._member_display_name(null) is not null then
    raise exception 'FAIL: Ca 9 _member_display_name(null) must return null';
  end if;
  set local role authenticated;

  -- =========================================================================
  -- Ca 10: H1 preview_sales_working_state_pricing áp cả rule warning
  -- =========================================================================
  -- Kích hoạt lại unit để bán
  reset role;
  update catalog.product_units set is_active = true where id = v_u1;
  set local role authenticated;
  -- Thiết lập lại sàn 100k để v_rule_below (90.000) có warning
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 150000,
    p_list_price_after_vat => 150000,
    p_floor_price_before_vat => 100000,
    p_floor_price_after_vat => 100000
  );

  v_res := pricing.preview_sales_working_state_pricing(
    p_tenant_id => v_ta,
    p_store_id => v_store_id,
    p_customer_id => v_cust3,
    p_currency_code => 'VND',
    p_context_version => 1,
    p_effective_at => now(),
    p_lines => jsonb_build_array(
      jsonb_build_object(
        'line_id', gen_random_uuid(),
        'product_id', v_p1,
        'product_unit_id', v_u1,
        'quantity', 1
      )
    )
  );
  if (v_res -> 'lines' -> 0 ->> 'source_code') is distinct from 'CUSTOMER_PRIVATE_RULE'
    or (v_res -> 'lines' -> 0 ->> 'unit_price_minor')::int <> 90000 then
    raise exception 'FAIL: Ca 10 warning rule was not applied in sales preview: %', v_res;
  end if;

  -- =========================================================================
  -- Ca 11: Kiểm tra bất biến 3.3
  -- =========================================================================
  -- Tạo 1 ca ghi đè để có dòng deleted do AUTO_REPLACED_BY_RULE
  v_cust5 := coalesce(v_cust5, public._th04_person(v_ta, v_ua, 'Khach Hang 5', '0911000005'));
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_over,
    p_customer_id => v_cust5,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 140000,
    p_currency_code => 'VND',
    p_effective_from => '2026-05-01'::date,
    p_idempotency_key => 'idem-ca11-over1'
  );
  perform pricing.create_customer_price_rule(
    p_tenant_id => v_ta,
    p_rule_id => v_rule_over_new,
    p_customer_id => v_cust5,
    p_product_id => v_p1,
    p_product_unit_id => v_u1,
    p_rule_price_minor => 145000,
    p_currency_code => 'VND',
    p_effective_from => '2026-05-01'::date,
    p_idempotency_key => 'idem-ca11-over2',
    p_acknowledge_overwrite => true
  );

  -- I-01: Không 2 dòng active cùng tenant, customer, product, unit có khoảng giao nhau
  if exists (
    select 1
    from pricing.customer_price_rules r1
    join pricing.customer_price_rules r2
      on r1.tenant_id = r2.tenant_id
     and r1.customer_id = r2.customer_id
     and r1.product_id = r2.product_id
     and r1.product_unit_id = r2.product_unit_id
     and r1.id <> r2.id
    where r1.tenant_id = v_ta
      and r1.status = 'active'
      and r2.status = 'active'
      and daterange(r1.effective_from, r1.effective_to, '[]') &&
          daterange(r2.effective_from, r2.effective_to, '[]')
  ) then
    raise exception 'FAIL: Invariant I-01 violated';
  end if;

  -- I-02: Dòng deleted có deleted_at
  if exists (
    select 1
    from pricing.customer_price_rules r
    where r.tenant_id = v_ta
      and r.status = 'deleted'
      and r.deleted_at is null
  ) then
    raise exception 'FAIL: Invariant I-02 violated';
  end if;

  -- I-03: Mỗi dòng deleted do ghi đè có đúng 1 dòng lịch sử deleted reason_code AUTO_REPLACED_BY_RULE
  if not exists (
    select 1
    from pricing.customer_price_rule_activities a
    where a.tenant_id = v_ta
      and a.customer_price_rule_id = v_rule_over
      and a.activity_type = 'deleted'
      and (a.new_value ->> 'reason_code') = 'AUTO_REPLACED_BY_RULE'
  ) then
    raise exception 'FAIL: Invariant I-03 violated for overwritten rule';
  end if;

  -- I-05: version = số dòng lịch sử
  if exists (
    select r.id, r.version, count(a.id) as act_count
    from pricing.customer_price_rules r
    left join pricing.customer_price_rule_activities a
      on a.tenant_id = r.tenant_id and a.customer_price_rule_id = r.id
    where r.tenant_id = v_ta
      and r.source_type <> 'excel_import'
    group by r.id, r.version
    having r.version <> count(a.id)
  ) then
    raise exception 'FAIL: Invariant I-05 violated (version <> activity count)';
  end if;

  raise notice 'pricing_th04: OK';
end;
$$;

rollback;
