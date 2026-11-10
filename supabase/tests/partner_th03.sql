-- TH-03 mục 9.3 "SQL / RPC test" (4-B G11): RPC partner + trigger lịch sử đơn bán + tìm không dấu.
-- Chạy trên DB LOCAL sau `supabase db reset` (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/partner_th03.sql
-- Kết thúc bằng `raise notice 'partner_th03: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (tạo trong giao dịch, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

-- Chạy một câu SQL, kỳ vọng lỗi bắt đầu bằng p_code (vd 'VALIDATION_ERROR').
create function public._th03_expect_err(p_sql text, p_code text)
returns void
language plpgsql
as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm like p_code || '%' then
      return;
    end if;
    raise exception 'FAIL: expected % but got [%] for: %', p_code, sqlerrm, p_sql;
  end;
  raise exception 'FAIL: expected % but statement succeeded: %', p_code, p_sql;
end;
$$;

create function public._th03_person(
  p_tenant uuid, p_actor uuid, p_name text, p_phone text, p_email text default null
)
returns uuid
language sql
as $$
  select c.partner_id
  from partner.create_partner(
    p_tenant, p_actor, 'person', array['customer'],
    jsonb_build_object('full_name', p_name, 'phone', p_phone, 'email', p_email)
  ) c;
$$;

create function public._th03_org(
  p_tenant uuid, p_actor uuid, p_name text, p_phone text
)
returns uuid
language sql
as $$
  select c.partner_id
  from partner.create_partner(
    p_tenant, p_actor, 'organization', array['customer'],
    null,
    jsonb_build_object(
      'organization_name', p_name, 'organization_type', 'company', 'phone', p_phone
    )
  ) c;
$$;

create function public._th03_version(p_partner uuid)
returns integer
language sql
security definer
as $$
  select p.version::integer from partner.partners p where p.partner_id = p_partner;
$$;

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();   -- owner tenant A
  v_ub uuid := gen_random_uuid();   -- owner tenant B
  v_ta uuid;
  v_tb uuid;
  v_p1 uuid;
  v_pdel uuid;
  v_pb uuid;
  v_o1 uuid;
  v_o2 uuid;
  v_o3 uuid;
  v_pact uuid;
  v_pinact uuid;
  v_pdel2 uuid;
  v_pc uuid;
  v_pi uuid;
  v_pt uuid;
  v_pcust uuid;
  v_pcust2 uuid;
  v_pemail uuid;
  v_pname uuid;
  v_order uuid := gen_random_uuid();
  v_order_null uuid := gen_random_uuid();
  v_count int;
  v_eligible boolean;
  v_reason text;
  v_status text;
  v_total bigint;
  v_items text;
  v_org_profile jsonb;
  v_claims text;
  v_psys uuid;
  v_detail jsonb;
begin
  -- 0) Dựng 2 tenant + owner (như iam_legacy_cleanup.sql).
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values
    (
      v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'th03-a-' || v_ua::text || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    ),
    (
      v_ub, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'th03-b-' || v_ub::text || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    );

  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Nha thuoc TH03 A', 'contact_phone', '0900000001',
      'contact_email', 'a@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 1'
    )
  );
  v_tb := iam._create_tenant_for_owner(
    v_ub,
    jsonb_build_object(
      'name', 'Nha thuoc TH03 B', 'contact_phone', '0900000002',
      'contact_email', 'b@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 2'
    )
  );
  if v_ta is null or v_tb is null then
    raise exception 'FAIL: tenants were not created';
  end if;

  v_org_profile := jsonb_build_object(
    'organization_name', 'Cong ty Chuyen Doi', 'organization_type', 'company',
    'phone', '0909999999'
  );

  -- Tenant B: một cá nhân (dùng ở ca 3 "tenant khác").
  v_claims := json_build_object('sub', v_ub::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ub::text, true);
  set local role authenticated;
  v_pb := public._th03_person(v_tb, v_ub, 'Nguoi Tenant B', '0902000001');
  reset role;

  -- Từ đây gọi RPC với tư cách owner tenant A.
  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  set local role authenticated;

  -- =========================================================================
  -- Ca 1: create_partner
  -- =========================================================================
  perform public._th03_expect_err(
    format(
      'select * from partner.create_partner(%L, %L, ''person'', array[]::text[], %L::jsonb)',
      v_ta, v_ua, '{"full_name":"Khong Vai Tro","phone":"0903000001"}'
    ),
    'VALIDATION_ERROR'
  );

  v_p1 := public._th03_person(v_ta, v_ua, 'An Bình', '0901000001');

  perform public._th03_expect_err(
    format(
      'select * from partner.create_partner(%L, %L, ''person'', array[''customer''], %L::jsonb)',
      v_ta, v_ua, '{"full_name":"Trung Sdt","phone":"0901000001"}'
    ),
    'DUPLICATE_WARNING'
  );

  -- Có xác nhận thì tạo được (trùng chỉ là cảnh báo).
  perform 1
  from partner.create_partner(
    v_ta, v_ua, 'person', array['customer'],
    '{"full_name":"Trung Sdt Da Xac Nhan","phone":"0901000001"}'::jsonb,
    null, null, true
  );

  -- =========================================================================
  -- Ca 2: update_partner
  -- =========================================================================
  perform public._th03_expect_err(
    format(
      'select * from partner.update_partner(%L, %L, %L, 99, array[''customer''], %L::jsonb)',
      v_ta, v_ua, v_p1, '{"full_name":"An Bình","phone":"0901000001"}'
    ),
    'STATE_CHANGED'
  );

  v_pdel := public._th03_person(v_ta, v_ua, 'Se Bi Xoa', '0903000002');
  reset role;
  update partner.partners set status = 'deleted' where partner_id = v_pdel;
  set local role authenticated;
  perform public._th03_expect_err(
    format(
      'select * from partner.update_partner(%L, %L, %L, %s, array[''customer''], %L::jsonb)',
      v_ta, v_ua, v_pdel, public._th03_version(v_pdel),
      '{"full_name":"Se Bi Xoa","phone":"0903000002"}'
    ),
    'INVALID_STATUS'
  );

  -- =========================================================================
  -- Ca 3: add_organization_contact với người có sẵn, KHÔNG đặt chính (G3, BR-17)
  -- =========================================================================
  v_o1 := public._th03_org(v_ta, v_ua, 'Cong ty Mot', '0904000001');
  v_o2 := public._th03_org(v_ta, v_ua, 'Cong ty Hai', '0904000002');
  v_o3 := public._th03_org(v_ta, v_ua, 'Cong ty Ba', '0904000003');

  -- tổ chức
  perform public._th03_expect_err(
    format(
      'select * from partner.add_organization_contact(%L, %L, %L, %L, null, null, false)',
      v_ta, v_ua, v_o1, v_o2
    ),
    'VALIDATION_ERROR'
  );
  -- tenant khác
  perform public._th03_expect_err(
    format(
      'select * from partner.add_organization_contact(%L, %L, %L, %L, null, null, false)',
      v_ta, v_ua, v_o1, v_pb
    ),
    'VALIDATION_ERROR'
  );
  -- đã xoá
  v_pdel2 := public._th03_person(v_ta, v_ua, 'Da Xoa Lien He', '0903000003');
  reset role;
  update partner.partners set status = 'deleted' where partner_id = v_pdel2;
  set local role authenticated;
  perform public._th03_expect_err(
    format(
      'select * from partner.add_organization_contact(%L, %L, %L, %L, null, null, false)',
      v_ta, v_ua, v_o1, v_pdel2
    ),
    'INVALID_STATUS'
  );
  -- không có dòng liên kết nào bị tạo bởi các ca bị từ chối
  reset role;
  select count(*) into v_count
  from partner.organization_contacts oc
  where oc.organization_partner_id = v_o1;
  if v_count <> 0 then
    raise exception 'FAIL: rejected contact links must not create rows, got %', v_count;
  end if;
  set local role authenticated;

  -- người đang hoạt động / ngừng hoạt động, không đặt chính: được thêm
  v_pact := public._th03_person(v_ta, v_ua, 'Nguoi Hoat Dong', '0903000004');
  perform 1 from partner.add_organization_contact(v_ta, v_ua, v_o1, v_pact, null, null, false);
  v_pinact := public._th03_person(v_ta, v_ua, 'Nguoi Ngung', '0903000005');
  reset role;
  update partner.partners set status = 'inactive' where partner_id = v_pinact;
  set local role authenticated;
  perform 1 from partner.add_organization_contact(v_ta, v_ua, v_o1, v_pinact, null, null, false);

  reset role;
  select count(*) into v_count
  from partner.organization_contacts oc
  where oc.organization_partner_id = v_o1 and not oc.is_primary;
  if v_count <> 2 then
    raise exception 'FAIL: expected 2 non-primary links on org 1, got %', v_count;
  end if;
  set local role authenticated;

  -- =========================================================================
  -- Ca 4: người ngừng hoạt động không làm chính; ngừng người chính → mất cờ chính mọi nơi
  -- =========================================================================
  v_pi := public._th03_person(v_ta, v_ua, 'Ngung Khong Duoc Chinh', '0903000006');
  reset role;
  update partner.partners set status = 'inactive' where partner_id = v_pi;
  set local role authenticated;
  perform public._th03_expect_err(
    format(
      'select * from partner.add_organization_contact(%L, %L, %L, %L, null, null, true)',
      v_ta, v_ua, v_o1, v_pi
    ),
    'INVALID_STATUS'
  );

  v_pc := public._th03_person(v_ta, v_ua, 'Nguoi Chinh Hai Noi', '0903000007');
  perform 1 from partner.add_organization_contact(v_ta, v_ua, v_o1, v_pc, null, null, true);
  perform 1 from partner.add_organization_contact(v_ta, v_ua, v_o3, v_pc, null, null, true);
  reset role;
  select count(*) into v_count
  from partner.organization_contacts oc
  where oc.person_partner_id = v_pc and oc.is_primary;
  if v_count <> 2 then
    raise exception 'FAIL: expected person primary in 2 organizations, got %', v_count;
  end if;
  set local role authenticated;

  perform 1 from partner.deactivate_partner(v_ta, v_ua, v_pc, public._th03_version(v_pc), 'test');
  reset role;
  select count(*) into v_count
  from partner.organization_contacts oc
  where oc.person_partner_id = v_pc and oc.is_primary;
  if v_count <> 0 then
    raise exception 'FAIL: deactivating a primary contact must clear the flag everywhere, got %',
      v_count;
  end if;
  set local role authenticated;

  -- =========================================================================
  -- Ca 5: transform_to_organization
  -- =========================================================================
  v_pt := public._th03_person(v_ta, v_ua, 'Nguoi Chinh Noi Khac', '0903000008');
  perform 1 from partner.add_organization_contact(v_ta, v_ua, v_o2, v_pt, null, null, true);
  perform public._th03_expect_err(
    format(
      'select * from partner.transform_to_organization(%L, %L, %L, %s, %L::jsonb)',
      v_ta, v_ua, v_pt, public._th03_version(v_pt), v_org_profile::text
    ),
    'PRIMARY_CONTACT_OF_ORGANIZATION'
  );
  perform public._th03_expect_err(
    format(
      'select * from partner.transform_to_organization(%L, %L, %L, %s, %L::jsonb)',
      v_ta, v_ua, v_o1, public._th03_version(v_o1), v_org_profile::text
    ),
    'INVALID_STATUS'
  );

  -- =========================================================================
  -- Ca 6: trigger lịch sử đơn bán (G1, US-07.2, BR-31)
  -- =========================================================================
  v_pcust := public._th03_person(v_ta, v_ua, 'Khach Co Don', '0905000001');
  v_pcust2 := public._th03_person(v_ta, v_ua, 'Khach Doi Sang', '0905000002');

  select e.eligible into v_eligible from partner.check_delete_eligibility(v_ta, v_pcust) e;
  if v_eligible is distinct from true then
    raise exception 'FAIL: customer without orders must be eligible to delete';
  end if;

  -- Insert đơn có khách (chạy với quyền postgres như service ghi đơn).
  reset role;
  insert into sales.sales_orders (
    id, tenant_id, order_code, store_id, seller_user_id, customer_partner_id,
    channel_code, currency_code, lifecycle_status,
    subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor,
    payable_amount_minor, sales_context_snapshot
  )
  values (
    v_order, v_ta, 'TH03-0001', gen_random_uuid(), v_ua, v_pcust,
    'pos', 'VND', 'completed',
    100000, 0, 0, 0, 100000, '{}'::jsonb
  );

  select count(*) into v_count
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 1 then
    raise exception 'FAIL: insert order must write exactly 1 history row, got %', v_count;
  end if;

  select h.partner_id::text = v_pcust::text and h.reference_code = 'TH03-0001'
         and h.amount = 100000 and h.currency = 'VND' and h.status = 'completed'
         and h.can_open_source = false and h.role::text = 'customer'
         and h.transaction_type::text = 'sales_order'
  into v_eligible
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_eligible is distinct from true then
    raise exception 'FAIL: history row fields do not match the order';
  end if;

  set local role authenticated;
  select e.eligible, e.reason into v_eligible, v_reason
  from partner.check_delete_eligibility(v_ta, v_pcust) e;
  if v_eligible is distinct from false or v_reason is distinct from 'HAS_TRANSACTIONS' then
    raise exception 'FAIL: customer with an order must be HAS_TRANSACTIONS, got % / %',
      v_eligible, v_reason;
  end if;
  reset role;

  -- Huỷ đơn: status đổi, vẫn 1 dòng.
  update sales.sales_orders
  set lifecycle_status = 'cancelled', cancelled_at = now()
  where id = v_order;
  select count(*), min(h.status) into v_count, v_status
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 1 or v_status is distinct from 'cancelled' then
    raise exception 'FAIL: cancelling must update the same row, got % rows status %',
      v_count, v_status;
  end if;

  -- Ghi lại cùng đơn (AC-03): vẫn 1 dòng, mã tham chiếu mới.
  update sales.sales_orders set order_code = 'TH03-0001B' where id = v_order;
  update sales.sales_orders set order_code = 'TH03-0001B' where id = v_order;
  select count(*), min(h.reference_code) into v_count, v_status
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 1 or v_status is distinct from 'TH03-0001B' then
    raise exception 'FAIL: updating the same order must keep 1 row, got % rows ref %',
      v_count, v_status;
  end if;

  -- Đổi khách của đơn: dòng cũ chuyển sang khách mới, vẫn 1 dòng.
  update sales.sales_orders set customer_partner_id = v_pcust2 where id = v_order;
  select count(*) into v_count
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 1 then
    raise exception 'FAIL: changing the customer must leave 1 row, got %', v_count;
  end if;
  if not exists (
    select 1 from partner.partner_history_views h
    where h.source_id = v_order and h.partner_id = v_pcust2
  ) then
    raise exception 'FAIL: history row must follow the new customer';
  end if;
  if exists (
    select 1 from partner.partner_history_views h
    where h.partner_id = v_pcust and h.source_id = v_order
  ) then
    raise exception 'FAIL: old customer must not keep the history row';
  end if;

  -- Bỏ khách (Khách lẻ): dòng bị xoá.
  update sales.sales_orders set customer_partner_id = null where id = v_order;
  select count(*) into v_count
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 0 then
    raise exception 'FAIL: walk-in customer must have 0 rows, got %', v_count;
  end if;

  -- Đơn Khách lẻ ngay từ đầu: 0 dòng (AC-02).
  insert into sales.sales_orders (
    id, tenant_id, order_code, store_id, seller_user_id, customer_partner_id,
    channel_code, currency_code, lifecycle_status,
    subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor,
    payable_amount_minor, sales_context_snapshot
  )
  values (
    v_order_null, v_ta, 'TH03-0002', gen_random_uuid(), v_ua, null,
    'pos', 'VND', 'completed',
    50000, 0, 0, 0, 50000, '{}'::jsonb
  );
  select count(*) into v_count
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order_null;
  if v_count <> 0 then
    raise exception 'FAIL: walk-in order must write 0 history rows, got %', v_count;
  end if;

  -- Khách thuộc tenant khác: báo NOT_FOUND, đơn không được ghi (không nuốt dữ liệu sai).
  perform public._th03_expect_err(
    format(
      'insert into sales.sales_orders (id, tenant_id, order_code, store_id, seller_user_id, '
      'customer_partner_id, channel_code, currency_code, lifecycle_status, '
      'subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor, '
      'payable_amount_minor, sales_context_snapshot) values '
      '(%L, %L, ''TH03-0003'', %L, %L, %L, ''pos'', ''VND'', ''completed'', '
      '1000, 0, 0, 0, 1000, ''{}''::jsonb)',
      gen_random_uuid(), v_ta, gen_random_uuid(), v_ua, v_pb
    ),
    'NOT_FOUND'
  );
  if exists (
    select 1 from sales.sales_orders o where o.tenant_id = v_ta and o.order_code = 'TH03-0003'
  ) then
    raise exception 'FAIL: order with a cross-tenant customer must not be stored';
  end if;

  -- Bù dữ liệu cũ: câu bù chạy lại không tạo dòng thứ hai.
  update sales.sales_orders set customer_partner_id = v_pcust where id = v_order;
  insert into partner.partner_history_views (
    tenant_id, partner_id, role, transaction_type, source_module, source_id,
    reference_code, transaction_date, status, amount, currency, can_open_source
  )
  select o.tenant_id, o.customer_partner_id, 'customer', 'sales_order', 'sales', o.id,
         o.order_code, o.completed_at, o.lifecycle_status, o.payable_amount_minor::numeric,
         o.currency_code, false
  from sales.sales_orders o
  join partner.partners p
    on p.partner_id = o.customer_partner_id and p.tenant_id = o.tenant_id
  where o.customer_partner_id is not null
  on conflict (tenant_id, source_module, source_id) do nothing;
  select count(*) into v_count
  from partner.partner_history_views h
  where h.tenant_id = v_ta and h.source_module = 'sales' and h.source_id = v_order;
  if v_count <> 1 then
    raise exception 'FAIL: backfill must be idempotent, got % rows', v_count;
  end if;

  set local role authenticated;

  -- =========================================================================
  -- Ca 7: search_partners không phân biệt dấu (G2, BR-35); '@' chỉ khớp email
  -- =========================================================================
  select s.total, s.items::text into v_total, v_items
  from partner.search_partners(v_ta, 'an binh') s;
  if v_total < 1 or v_items not like '%An Bình%' then
    raise exception 'FAIL: "an binh" must find "An Bình", total %', v_total;
  end if;

  select s.total, s.items::text into v_total, v_items
  from partner.search_partners(v_ta, 'AN BÌNH') s;
  if v_total < 1 or v_items not like '%An Bình%' then
    raise exception 'FAIL: "AN BÌNH" must find "An Bình", total %', v_total;
  end if;

  select s.total into v_total from partner.search_partners(v_ta, 'khong co ten nay') s;
  if v_total <> 0 then
    raise exception 'FAIL: unknown keyword must find nothing, total %', v_total;
  end if;

  v_pemail := public._th03_person(v_ta, v_ua, 'Zzq Email', '0906000001', 'zzq@wxy.vn');
  v_pname := public._th03_person(v_ta, v_ua, 'zzq@wxy ten', '0906000002');
  select s.total, s.items::text into v_total, v_items
  from partner.search_partners(v_ta, 'zzq@wxy') s;
  if v_total <> 1 or v_items not like '%Zzq Email%' or v_items like '%zzq@wxy ten%' then
    raise exception 'FAIL: keyword with @ must match email only, total % items %',
      v_total, v_items;
  end if;

  -- =========================================================================
  -- Ca 8: lọc thời gian chỉ nhận 7 / 30 ngày
  -- =========================================================================
  perform public._th03_expect_err(
    format(
      'select * from partner.search_partners(%L, null, null, null, null, 1, 20, '
      '''updated_at_desc'', 15)',
      v_ta
    ),
    'VALIDATION_ERROR'
  );
  perform 1 from partner.search_partners(v_ta, null, null, null, null, 1, 20, 'updated_at_desc', 7);
  perform 1 from partner.search_partners(v_ta, null, null, null, null, 1, 20, 'updated_at_desc', 30);

  -- =========================================================================
  -- Ca 9: đối tác hệ thống (G5-2b) — chỉ đọc, chi tiết chỉ còn viewHistory
  -- =========================================================================
  reset role;
  insert into partner.partners (tenant_id, partner_type, display_name, is_system, created_by, updated_by)
  values (v_ta, 'organization', 'Mua lẻ / khác', true, v_ua, v_ua)
  returning partner_id into v_psys;
  insert into partner.organization_profiles (
    partner_id, tenant_id, organization_type, organization_name, phone, allow_blank_phone
  ) values (v_psys, v_ta, 'other', 'Mua lẻ / khác', '', true);
  insert into partner.partner_roles (partner_id, tenant_id, role)
  values (v_psys, v_ta, 'supplier');
  set local role authenticated;

  perform public._th03_expect_err(
    format(
      'select * from partner.update_partner(%L, %L, %L, %s, array[''supplier''], null, %L::jsonb)',
      v_ta, v_ua, v_psys, public._th03_version(v_psys),
      '{"organization_name":"Doi ten","organization_type":"other","phone":"0900000000"}'
    ),
    'PARTNER_SYSTEM_LOCKED'
  );
  perform public._th03_expect_err(
    format(
      'select * from partner.soft_delete_partner(%L, %L, %L, %s, ''x'')',
      v_ta, v_ua, v_psys, public._th03_version(v_psys)
    ),
    'PARTNER_SYSTEM_LOCKED'
  );
  perform public._th03_expect_err(
    format(
      'select * from partner.deactivate_partner(%L, %L, %L, %s, ''x'')',
      v_ta, v_ua, v_psys, public._th03_version(v_psys)
    ),
    'PARTNER_SYSTEM_LOCKED'
  );

  v_detail := partner.get_partner_detail(v_ta, v_psys);
  if (v_detail->>'is_system')::boolean is not true
     or v_detail->'available_actions' <> '["viewHistory"]'::jsonb then
    raise exception 'FAIL: system_partner_detail_actions, got %', v_detail;
  end if;

  reset role;
  raise notice 'partner_th03: OK';
end;
$$;

rollback;
