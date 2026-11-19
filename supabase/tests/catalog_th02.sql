-- TH-02 mục 9.3 "SQL / RPC test" (5-B Task 1): RPC catalog, chặn 8 ảnh, chip đã xoá, giá & đơn vị.
-- Chạy trên DB LOCAL sau `supabase db reset` (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/catalog_th02.sql
-- Kết thúc bằng `raise notice 'catalog_th02: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (tạo trong giao dịch, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

create function public._th02_expect_err(p_sql text, p_code text)
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

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();
  v_ta uuid;
  v_claims text;
  v_res jsonb;
  v_res2 jsonb;
  v_p1 uuid;
  v_psku1 uuid;
  v_pbu uuid;
  v_psearch uuid;
  v_idem uuid := gen_random_uuid();
  v_count int;
  v_count_before int;
  v_gid uuid;
  v_fid uuid;
  v_u_custom uuid;
  v_u_manual uuid;
  v_band record;
  v_readiness record;
begin
  -- 0) Dựng tenant + owner
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values (
    v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
    'th02-' || v_ua::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  );

  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Nha thuoc TH02 Test', 'contact_phone', '0900000009',
      'contact_email', 'th02@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 9'
    )
  );
  if v_ta is null then
    raise exception 'FAIL: tenant was not created';
  end if;

  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  -- Test đọc trực tiếp bảng catalog: cấp quyền đọc trong transaction (rollback cuối tệp).
  grant usage on schema catalog to authenticated;
  grant select on all tables in schema catalog to authenticated;
  grant execute on all functions in schema catalog to authenticated;
  set local role authenticated;

  -- =========================================================================
  -- Ca 1: create_guided_product cùng p_idempotency_key hai lần -> 1 sản phẩm
  -- =========================================================================
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'San pham Ca 1',
    p_reference_id => 'REF-CA1',
    p_idempotency_key => v_idem
  );
  v_p1 := (v_res ->> 'product_id')::uuid;
  if v_p1 is null then
    raise exception 'FAIL: Ca 1 product_id is null';
  end if;

  v_res2 := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'San pham Ca 1 sua ten',
    p_reference_id => 'REF-CA1-2',
    p_idempotency_key => v_idem
  );
  if (v_res2 ->> 'product_id')::uuid <> v_p1 then
    raise exception 'FAIL: Ca 1 idempotency did not return same product_id';
  end if;

  select count(*) into v_count
  from catalog.products
  where tenant_id = v_ta and idempotency_key = v_idem;
  if v_count <> 1 then
    raise exception 'FAIL: Ca 1 product count <> 1 (got %)', v_count;
  end if;

  -- =========================================================================
  -- Ca 2: create_guided_product có giá mà không đơn vị -> lỗi, không tạo gì
  -- =========================================================================
  select count(*) into v_count_before from catalog.products where tenant_id = v_ta;

  perform public._th02_expect_err(
    format(
      'select catalog.create_guided_product(%L, %L, %L, %L, p_base_price_after_vat => 50000)',
      v_ta, v_ua, 'SP Khong Don Vi 2', 'REF-NO-UNIT-2'
    ),
    'validation_exception: base unit is required for pricing'
  );

  select count(*) into v_count from catalog.products where tenant_id = v_ta;
  if v_count <> v_count_before then
    raise exception 'FAIL: Ca 2 created products unexpectedly';
  end if;

  -- =========================================================================
  -- Ca 3: SKU trùng sản phẩm chưa xoá -> duplicate sku; trùng đã xoá -> tạo được
  -- =========================================================================
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'SP SKU 1',
    p_reference_id => 'REF-SKU-1',
    p_sku => 'SKU-TEST-01'
  );
  v_psku1 := (v_res ->> 'product_id')::uuid;

  perform public._th02_expect_err(
    format(
      'select catalog.create_guided_product(%L, %L, %L, %L, p_sku => %L)',
      v_ta, v_ua, 'SP SKU 2', 'REF-SKU-2', 'SKU-TEST-01'
    ),
    'duplicate sku'
  );

  perform catalog.delete_product(
    p_tenant_id => v_ta,
    p_product_id => v_psku1,
    p_actor_id => v_ua,
    p_reason => 'test xoá để tái sử dụng sku'
  );

  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'SP SKU 3 tai tao',
    p_reference_id => 'REF-SKU-3',
    p_sku => 'SKU-TEST-01'
  );
  if (v_res ->> 'product_id') is null then
    raise exception 'FAIL: Ca 3 cannot reuse sku after soft delete';
  end if;

  -- =========================================================================
  -- Ca 4: set_product_base_unit lần hai -> lỗi
  -- =========================================================================
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'SP Base Unit Test',
    p_reference_id => 'REF-BU-1'
  );
  v_pbu := (v_res ->> 'product_id')::uuid;

  perform catalog.set_product_base_unit(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_new_unit_name => 'Hop'
  );

  perform public._th02_expect_err(
    format(
      'select catalog.set_product_base_unit(%L, %L, p_new_unit_name => ''Vien'')',
      v_ta, v_pbu
    ),
    'Product already has a base unit'
  );

  -- =========================================================================
  -- Ca 5: G1 chặn > 8 ảnh (5a: 9 ảnh lỗi; 5b: 8 ảnh lưu được)
  -- =========================================================================
  -- 5a: update_product_images 9 ảnh
  perform public._th02_expect_err(
    format(
      'select catalog.update_product_images(%L, %L, %L::jsonb)',
      v_ta, v_p1,
      '[{"storage_key":"k1"},{"storage_key":"k2"},{"storage_key":"k3"},{"storage_key":"k4"},{"storage_key":"k5"},{"storage_key":"k6"},{"storage_key":"k7"},{"storage_key":"k8"},{"storage_key":"k9"}]'
    ),
    'tối đa 8 ảnh'
  );

  -- create_guided_product 9 ảnh
  select count(*) into v_count_before from catalog.products where tenant_id = v_ta;
  perform public._th02_expect_err(
    format(
      'select catalog.create_guided_product(%L, %L, %L, %L, p_images => %L::jsonb)',
      v_ta, v_ua, 'SP 9 Anh', 'REF-9IMG',
      '[{"storage_key":"k1"},{"storage_key":"k2"},{"storage_key":"k3"},{"storage_key":"k4"},{"storage_key":"k5"},{"storage_key":"k6"},{"storage_key":"k7"},{"storage_key":"k8"},{"storage_key":"k9"}]'
    ),
    'tối đa 8 ảnh'
  );
  select count(*) into v_count from catalog.products where tenant_id = v_ta;
  if v_count <> v_count_before then
    raise exception 'FAIL: Ca 5a created product with 9 images';
  end if;

  -- 5b: đúng 8 ảnh
  perform catalog.update_product_images(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_images => '[{"storage_key":"k1"},{"storage_key":"k2"},{"storage_key":"k3"},{"storage_key":"k4"},{"storage_key":"k5"},{"storage_key":"k6"},{"storage_key":"k7"},{"storage_key":"k8"}]'::jsonb
  );
  select count(*) into v_count
  from catalog.product_images
  where tenant_id = v_ta and product_id = v_p1;
  if v_count <> 8 then
    raise exception 'FAIL: Ca 5b update_product_images count <> 8 (got %)', v_count;
  end if;

  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'SP 8 Anh',
    p_reference_id => 'REF-8IMG',
    p_images => '[{"storage_key":"k1"},{"storage_key":"k2"},{"storage_key":"k3"},{"storage_key":"k4"},{"storage_key":"k5"},{"storage_key":"k6"},{"storage_key":"k7"},{"storage_key":"k8"}]'::jsonb
  );
  if (v_res ->> 'product_id') is null then
    raise exception 'FAIL: Ca 5b create_guided_product with 8 images failed';
  end if;

  -- =========================================================================
  -- Ca 6: set_manual_base_price -> khung ruleBased / customConfig đúng công thức, manual giữ nguyên
  -- =========================================================================
  -- Thiết lập khung giá cửa hàng: 30% lãi, 10% sàn
  perform catalog.set_store_price_rule(
    p_tenant_id => v_ta,
    p_name => 'Khung chuẩn 30/10',
    p_list_markup_ratio => 0.3,
    p_floor_markup_ratio => 0.1
  );

  -- Đặt giá cơ sở lần 1: 100,000 cho v_pbu
  perform catalog.set_manual_base_price(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_mode => 'manual',
    p_base_price_after_vat => 100000
  );

  -- Áp dụng khung giá cửa hàng (ruleBased) cho đơn vị cơ sở
  perform catalog.apply_store_price_rule(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_confirm_overwrite => true
  );

  -- Thêm đơn vị quy đổi 'Vi' để thiết lập khung customConfig (tỷ lệ riêng 50% list, 20% floor)
  v_res := catalog.add_product_conversion_unit(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_unit_name => 'Vi',
    p_conversion_rate_to_base => 1
  );
  v_u_custom := (v_res -> 'unit' ->> 'id')::uuid;

  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_product_unit_id => v_u_custom,
    p_source_type => 'customConfig',
    p_list_markup_ratio => 0.5,
    p_floor_markup_ratio => 0.2,
    p_list_price_before_vat => 0,
    p_list_price_after_vat => 0
  );

  -- Thêm đơn vị quy đổi 'Vien' để thiết lập khung manual (giá cố định 350,000 / 300,000)
  v_res := catalog.add_product_conversion_unit(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_unit_name => 'Vien',
    p_conversion_rate_to_base => 1
  );
  v_u_manual := (v_res -> 'unit' ->> 'id')::uuid;

  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_product_unit_id => v_u_manual,
    p_source_type => 'manual',
    p_list_price_before_vat => 350000,
    p_list_price_after_vat => 350000,
    p_floor_price_before_vat => 300000,
    p_floor_price_after_vat => 300000
  );

  -- Đặt giá cơ sở lần 2: 200,000 -> tự động tính lại khung ruleBased và customConfig; giữ nguyên manual
  perform catalog.set_manual_base_price(
    p_tenant_id => v_ta,
    p_product_id => v_pbu,
    p_mode => 'manual',
    p_base_price_after_vat => 200000
  );

  -- 1. Kiểm tra khung ruleBased trên đơn vị cơ sở (200k * 1.3 = 260k, 200k * 1.1 = 220k)
  select pb.list_price_before_vat, pb.floor_price_before_vat
  into v_band
  from catalog.product_unit_price_bands pb
  join catalog.product_units pu on pu.id = pb.product_unit_id
  where pb.tenant_id = v_ta
    and pb.product_id = v_pbu
    and pu.is_base_unit = true
    and pb.status = 'active';

  if v_band.list_price_before_vat <> 260000 or v_band.floor_price_before_vat <> 220000 then
    raise exception 'FAIL: Ca 6 ruleBased recalculation wrong (got list=%, floor=%)',
      v_band.list_price_before_vat, v_band.floor_price_before_vat;
  end if;

  -- 2. Kiểm tra khung customConfig trên đơn vị 'Vi' (200k * 1.5 = 300k, 200k * 1.2 = 240k)
  select pb.list_price_before_vat, pb.floor_price_before_vat
  into v_band
  from catalog.product_unit_price_bands pb
  where pb.tenant_id = v_ta
    and pb.product_id = v_pbu
    and pb.product_unit_id = v_u_custom
    and pb.status = 'active';

  if v_band.list_price_before_vat <> 300000 or v_band.floor_price_before_vat <> 240000 then
    raise exception 'FAIL: Ca 6 customConfig recalculation wrong (got list=%, floor=%)',
      v_band.list_price_before_vat, v_band.floor_price_before_vat;
  end if;

  -- 3. Kiểm tra khung manual trên đơn vị 'Vien' (giữ nguyên 350,000 / 300,000 khi base price đổi)
  select pb.list_price_before_vat, pb.floor_price_before_vat
  into v_band
  from catalog.product_unit_price_bands pb
  where pb.tenant_id = v_ta
    and pb.product_id = v_pbu
    and pb.product_unit_id = v_u_manual
    and pb.status = 'active';

  if v_band.list_price_before_vat <> 350000 or v_band.floor_price_before_vat <> 300000 then
    raise exception 'FAIL: Ca 6 manual price should not recalculate (got list=%, floor=%)',
      v_band.list_price_before_vat, v_band.floor_price_before_vat;
  end if;

  -- =========================================================================
  -- Ca 7: set_store_price_rule tỷ lệ sàn > niêm yết -> lỗi; lưu không đổi -> không thêm lịch sử
  -- =========================================================================
  perform public._th02_expect_err(
    format(
      'select * from catalog.set_store_price_rule(%L, %L, 0.1, 0.2)',
      v_ta, 'Khung loi'
    ),
    'markup ratios are invalid'
  );

  select count(*) into v_count_before
  from catalog.store_price_rule_change_history
  where tenant_id = v_ta;

  perform catalog.set_store_price_rule(
    p_tenant_id => v_ta,
    p_name => 'Khung chuẩn 30/10',
    p_list_markup_ratio => 0.3,
    p_floor_markup_ratio => 0.1
  );

  select count(*) into v_count
  from catalog.store_price_rule_change_history
  where tenant_id = v_ta;
  if v_count <> v_count_before then
    raise exception 'FAIL: Ca 7 no-change save added history entry';
  end if;

  -- =========================================================================
  -- Ca 8: apply_store_price_rule lên khung có giá không xác nhận -> overwrite required; sai version -> stale
  -- =========================================================================
  perform public._th02_expect_err(
    format(
      'select * from catalog.apply_store_price_rule(%L, %L, p_confirm_overwrite => false)',
      v_ta, v_pbu
    ),
    'price_band_overwrite_required'
  );

  perform public._th02_expect_err(
    format(
      'select * from catalog.apply_store_price_rule(%L, %L, p_confirm_overwrite => true, p_base_price_version => 999999::bigint)',
      v_ta, v_pbu
    ),
    'stale_base_price'
  );

  -- =========================================================================
  -- Ca 9: Bật bắt buộc cho trường -> thiếu trường thành incomplete; tắt nhóm -> hết blocker
  -- =========================================================================
  v_res := catalog.upsert_custom_field_group(
    p_tenant_id => v_ta,
    p_name => 'Nhóm trường test TH02'
  );
  v_gid := (v_res ->> 'group_id')::uuid;

  v_res := catalog.upsert_custom_field(
    p_tenant_id => v_ta,
    p_group_id => v_gid,
    p_name => 'Hạn dùng phụ',
    p_field_type => 'text'
  );
  v_fid := (v_res ->> 'field_id')::uuid;

  -- Bật bắt buộc
  perform catalog.configure_custom_field_attributes(
    p_tenant_id => v_ta,
    p_field_id => v_fid,
    p_is_required => true,
    p_is_searchable => false,
    p_is_filterable => false,
    p_display_on_list => false
  );

  select r.readiness_status, r.readiness_blockers
  into v_readiness
  from catalog._refresh_product_readiness(v_ta, v_p1) r;

  if not (v_readiness.readiness_blockers @> '[{"code":"missing_required_custom_fields"}]'::jsonb) then
    raise exception 'FAIL: Ca 9 missing_required_custom_fields blocker not found';
  end if;

  -- Tạm tắt nhóm
  perform catalog.upsert_custom_field_group(
    p_tenant_id => v_ta,
    p_name => 'Nhóm trường test TH02',
    p_group_id => v_gid,
    p_is_active => false
  );

  select r.readiness_status, r.readiness_blockers
  into v_readiness
  from catalog._refresh_product_readiness(v_ta, v_p1) r;

  if (v_readiness.readiness_blockers @> '[{"code":"missing_required_custom_fields"}]'::jsonb) then
    raise exception 'FAIL: Ca 9 inactive group still produced blocker';
  end if;

  -- Bật lại nhóm để dùng cho Ca 10
  perform catalog.upsert_custom_field_group(
    p_tenant_id => v_ta,
    p_name => 'Nhóm trường test TH02',
    p_group_id => v_gid,
    p_is_active => true
  );

  -- =========================================================================
  -- Ca 10: upsert_custom_field đổi kiểu trường có dữ liệu -> custom_field_type_change_blocked
  -- =========================================================================
  perform catalog.upsert_product_custom_field_values(
    p_tenant_id => v_ta,
    p_product_id => v_p1,
    p_values => jsonb_build_array(
      jsonb_build_object('field_id', v_fid, 'text_value', 'Gia tri co san')
    )
  );

  perform public._th02_expect_err(
    format(
      'select catalog.upsert_custom_field(%L, %L, %L, ''number'', p_field_id => %L)',
      v_ta, v_gid, 'Hạn dùng phụ', v_fid
    ),
    'custom_field_type_change_blocked'
  );

  -- =========================================================================
  -- Ca 11: search_products('thuc an') thấy 'Thức ăn'; SKU tiền tố; soft_deleted
  -- =========================================================================
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta,
    p_actor_id => v_ua,
    p_name => 'Thức ăn chăn nuôi TH02',
    p_reference_id => 'REF-SEARCH-1',
    p_sku => 'TACN-9988'
  );
  v_psearch := (v_res ->> 'product_id')::uuid;

  -- Tìm không dấu
  select count(*) into v_count
  from catalog.search_products(v_ta, p_keyword => 'thuc an');
  if v_count < 1 then
    raise exception 'FAIL: Ca 11 unaccent search did not find product';
  end if;

  -- Tìm SKU tiền tố
  select count(*) into v_count
  from catalog.search_products(v_ta, p_keyword => 'TACN-');
  if v_count < 1 then
    raise exception 'FAIL: Ca 11 prefix SKU search did not find product';
  end if;

  -- Xoá v_psearch
  perform catalog.delete_product(
    p_tenant_id => v_ta,
    p_product_id => v_psearch,
    p_actor_id => v_ua,
    p_reason => 'test search deleted'
  );

  -- Lọc p_business_statuses = {'soft_deleted'}
  select count(*) into v_count
  from catalog.search_products(
    v_ta,
    p_business_statuses => array['soft_deleted']::text[],
    p_include_soft_deleted => true
  )
  where is_soft_deleted = false;

  if v_count > 0 then
    raise exception 'FAIL: Ca 11 soft_deleted search returned active product';
  end if;

  select count(*) into v_count
  from catalog.search_products(
    v_ta,
    p_business_statuses => array['soft_deleted']::text[],
    p_include_soft_deleted => true
  )
  where product_id = v_psearch and is_soft_deleted = true;

  if v_count <> 1 then
    raise exception 'FAIL: Ca 11 soft_deleted search did not find deleted product';
  end if;

  raise notice 'catalog_th02: OK';
end;
$$;

rollback;

