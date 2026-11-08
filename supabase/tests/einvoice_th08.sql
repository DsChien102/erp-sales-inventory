-- TH-08 mục 9.3 "SQL / RPC test" (7-B1): cấu hình, chính sách tự động, phát hành, thử lại,
-- người mua (KI-04 / KI-06), phát hành tự động, gửi hoá đơn, khoá quyền hàm của bộ xử lý.
-- Chạy trên DB LOCAL sau `supabase db reset` (không chạy trên Dev):
--   psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql
-- Kết thúc bằng `raise notice 'einvoice_th08: OK'`; mọi ca sai đều `raise exception 'FAIL: …'`.
-- Ca đánh ✱ kiểm phần SỬA của 7-B1; còn lại kiểm hành vi đang có.

begin;

-- ---------------------------------------------------------------------------
-- Hàm giúp (tạo trong giao dịch, bị rollback cuối tệp)
-- ---------------------------------------------------------------------------

-- Chạy một câu SQL, kỳ vọng lỗi bắt đầu bằng / chứa mã p_code (RPC einvoice ném 'CODE: …').
-- p_contains (tuỳ chọn): chuỗi phải có trong thông báo lỗi (vd mã BUYER_* trong details.blockers).
create function public._th08_expect_err(p_sql text, p_code text, p_contains text default null)
returns void
language plpgsql
as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlerrm like p_code || '%' or sqlerrm like '%' || p_code || '%' then
      if p_contains is null or sqlerrm like '%' || p_contains || '%' then
        return;
      end if;
      raise exception 'FAIL: expected [%] containing [%] but got [%] for: %',
        p_code, p_contains, sqlerrm, p_sql;
    end if;
    raise exception 'FAIL: expected [%] but got [%] for: %', p_code, sqlerrm, p_sql;
  end;
  raise exception 'FAIL: expected [%] but statement succeeded: %', p_code, p_sql;
end;
$$;

-- Khách hàng: person (p_type = 'person') hoặc organization. Gọi dưới quyền authenticated.
create function public._th08_customer(
  p_tenant uuid, p_actor uuid, p_type text, p_name text, p_tax_code text, p_address text
)
returns uuid
language plpgsql
as $$
declare
  v_phone text := '09' || lpad((floor(random() * 100000000))::bigint::text, 8, '0');
  v_id uuid;
begin
  if p_type = 'person' then
    select c.partner_id into v_id
    from partner.create_partner(
      p_tenant, p_actor, 'person', array['customer'],
      p_person_profile => jsonb_strip_nulls(jsonb_build_object(
        'full_name', p_name, 'phone', v_phone,
        'tax_code', p_tax_code, 'invoice_address', p_address))
    ) c;
  else
    select c.partner_id into v_id
    from partner.create_partner(
      p_tenant, p_actor, 'organization', array['customer'],
      p_organization_profile => jsonb_strip_nulls(jsonb_build_object(
        'organization_type', 'company', 'organization_name', p_name, 'phone', v_phone,
        'tax_code', p_tax_code, 'invoice_address', p_address))
    ) c;
  end if;
  return v_id;
end;
$$;

-- Bán 1 P1 (100.000), trả đủ tiền mặt ⇒ đơn Hoàn tất. Commercial snapshot của khách chỉ có
-- customerId / displayName / buyerType (không taxCode / invoiceAddress ⇒ ảnh chụp đơn trống,
-- MST và địa chỉ lấy từ hồ sơ khách). Trả salesOrderId.
create function public._th08_sale(
  p_tenant uuid, p_actor uuid, p_store uuid, p_product uuid, p_unit uuid,
  p_customer uuid, p_buyer_type text, p_key text
)
returns uuid
language plpgsql
as $$
declare
  v_lines jsonb;
  v_snapshot jsonb;
  v_res jsonb;
begin
  v_lines := jsonb_build_array(jsonb_build_object(
    'product_id', p_product, 'product_unit_id', p_unit, 'quantity_micros', 1000000,
    'unit_price', jsonb_build_object('amount_minor', 100000, 'currency_code', 'VND')
  ));
  v_snapshot := jsonb_build_object(
    'store', jsonb_build_object('storeId', p_store::text),
    'seller', jsonb_build_object('actorId', p_actor::text),
    'customer', case when p_customer is null then null
      else jsonb_build_object(
        'customerId', p_customer::text,
        'displayName', (select display_name from partner.partners where partner_id = p_customer),
        'buyerType', p_buyer_type)
    end,
    'lines', jsonb_build_array(jsonb_build_object(
      'lineId', gen_random_uuid()::text,
      'product', jsonb_build_object('productId', p_product::text, 'displayName', 'SP'),
      'unit', jsonb_build_object('productUnitId', p_unit::text, 'unitName', 'DV'),
      'quantityMicros', 1000000,
      'lineTotal', jsonb_build_object('amountMinor', 100000)
    ))
  );
  v_res := sales.finalize_sales_order(
    p_command_id => gen_random_uuid(),
    p_tenant_id => p_tenant,
    p_actor_id => p_actor,
    p_store_id => p_store,
    p_source_draft_id => null,
    p_customer_id => p_customer,
    p_currency_code => 'VND',
    p_order_note => null,
    p_commercial_snapshot => v_snapshot,
    p_lines => v_lines,
    p_payment_intents => jsonb_build_array(jsonb_build_object(
      'method', 'cash',
      'amount', jsonb_build_object('amount_minor', 100000, 'currency_code', 'VND'))),
    p_idempotency_key => p_key,
    p_payload_hash => 'h',
    p_correlation_id => gen_random_uuid()::text,
    p_payment_due_date => null,
    p_expected_source_version => null
  );
  if v_res ->> 'status' is distinct from 'succeeded' then
    raise exception 'FAIL: _th08_sale not succeeded: %', v_res;
  end if;
  return (v_res ->> 'salesOrderId')::uuid;
end;
$$;

-- Các hàm đọc dưới quyền chủ (bảng sales / einvoice bật RLS, authenticated bị revoke).
create function public._th08_source_version(p_order uuid)
returns text
language sql
security definer
set search_path = sales, public
as $$
  select o.version::text from sales.sales_orders o where o.id = p_order;
$$;

create function public._th08_attempt_status(p_attempt uuid)
returns text
language sql
security definer
set search_path = einvoice, public
as $$
  select ia.status from einvoice.issuance_attempts ia where ia.id = p_attempt;
$$;

create function public._th08_attempt_count(p_order uuid)
returns int
language sql
security definer
set search_path = einvoice, public
as $$
  select count(*)::int
  from einvoice.issuance_attempts ia
  join einvoice.invoice_issuances ii on ii.id = ia.invoice_issuance_id
  where ii.sales_order_id = p_order;
$$;

-- attempt_no = 1 là lượt đầu, 0 hoặc lớn hơn tổng ⇒ null.
create function public._th08_attempt_id(p_order uuid, p_no int)
returns uuid
language sql
security definer
set search_path = einvoice, public
as $$
  select ia.id
  from einvoice.issuance_attempts ia
  join einvoice.invoice_issuances ii on ii.id = ia.invoice_issuance_id
  where ii.sales_order_id = p_order and ia.attempt_no = p_no;
$$;

create function public._th08_attempt_buyer(p_attempt uuid, p_key text)
returns text
language sql
security definer
set search_path = einvoice, public
as $$
  select ia.attempt_snapshot -> 'buyer' ->> p_key from einvoice.issuance_attempts ia where ia.id = p_attempt;
$$;

create function public._th08_publish_command_count()
returns int
language sql
security definer
set search_path = einvoice, public
as $$
  select count(*)::int from einvoice.internal_commands c where c.command_type = 'einvoice.publish_invoice';
$$;

create function public._th08_invoice_count(p_order uuid)
returns int
language sql
security definer
set search_path = einvoice, public
as $$
  select count(*)::int from einvoice.electronic_invoices ei where ei.sales_order_id = p_order;
$$;

create function public._th08_invoice_id(p_order uuid)
returns uuid
language sql
security definer
set search_path = einvoice, public
as $$
  select ei.id from einvoice.electronic_invoices ei where ei.sales_order_id = p_order;
$$;

create function public._th08_delivery_count(p_invoice uuid)
returns int
language sql
security definer
set search_path = einvoice, public
as $$
  select count(*)::int from einvoice.invoice_deliveries d where d.electronic_invoice_id = p_invoice;
$$;

create function public._th08_delivery_intent(p_delivery uuid)
returns text
language sql
security definer
set search_path = einvoice, public
as $$
  select d.delivery_intent from einvoice.invoice_deliveries d where d.id = p_delivery;
$$;

create function public._th08_completion_tax_code(p_order uuid)
returns text
language sql
security definer
set search_path = einvoice, public
as $$
  select bc.buyer_tax_code from einvoice.buyer_invoice_completions bc where bc.sales_order_id = p_order;
$$;

-- Giả lập bộ xử lý: đưa lượt PREPARING sang WAITING_RESULT rồi ghi thất bại / thành công.
-- (record_issuance_* chỉ nhận SUBMITTED / WAITING_RESULT / RECONCILING.)
create function public._th08_fail(p_tenant uuid, p_attempt uuid)
returns void
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_key text;
  v_hash text;
begin
  update einvoice.issuance_attempts set status = 'WAITING_RESULT'
  where id = p_attempt and status = 'PREPARING';
  select ia.idempotency_key, ia.canonical_payload_hash into v_key, v_hash
  from einvoice.issuance_attempts ia where ia.id = p_attempt;
  perform einvoice.record_issuance_failure(
    p_tenant, p_attempt, v_key, v_hash, 'TH08_ERR', 'th08 test failure');
end;
$$;

create function public._th08_succeed(p_tenant uuid, p_attempt uuid)
returns void
language plpgsql
security definer
set search_path = einvoice, public
as $$
declare
  v_key text;
  v_hash text;
begin
  update einvoice.issuance_attempts set status = 'WAITING_RESULT'
  where id = p_attempt and status = 'PREPARING';
  select ia.idempotency_key, ia.canonical_payload_hash into v_key, v_hash
  from einvoice.issuance_attempts ia where ia.id = p_attempt;
  perform einvoice.record_issuance_success(
    p_tenant, p_attempt, v_key, v_hash, 'REF-' || p_attempt::text, 'INV-0001', '1C26TAA', now());
end;
$$;

-- ---------------------------------------------------------------------------
-- Ca kiểm
-- ---------------------------------------------------------------------------

do $$
declare
  v_ua uuid := gen_random_uuid();
  v_ub uuid := gen_random_uuid();
  v_ta uuid;
  v_tb uuid;
  v_store uuid;
  v_claims text;
  v_claims_b text;
  v_res jsonb;
  v_p1 uuid;
  v_u1 uuid;
  v_conn uuid;
  v_ka uuid;
  v_kb uuid;
  v_kb2 uuid;
  v_kb3 uuid;
  v_kc uuid;
  v_cmd uuid;
  v_tok uuid;
  v_rc int;
  v_due timestamptz;
  v_n int;
  v_case uuid;
  v_kd uuid;
  v_cfg record;
  v_pol record;
  v_rd record;
  v_iss record;
  v_start record;
  v_n int;
  v_n2 int;
  v_cmd int;
  v_ok boolean;
  v_flag boolean;
  v_status text;
  v_oa uuid;   -- đơn KA (E10)
  v_oa2 uuid;
  v_ob uuid;   -- đơn KB (E15, E19–E25)
  v_oc uuid;
  v_od uuid;
  v_ob2 uuid;
  v_ob3 uuid;
  v_oc2 uuid;  -- đơn KC phát hành tự động (E27–E29)
  v_ver text;
  v_att1 uuid;
  v_att2 uuid;
  v_att3 uuid;
  v_inv uuid;
  v_del1 uuid;
  v_del2 uuid;
  v_proc uuid;
  v_g1 uuid := gen_random_uuid();
  v_g2 uuid := gen_random_uuid();
  v_caps text;
begin
  -- 0) Hai tenant + owner + JWT (như sales_th05.sql)
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at
  ) values
    (v_ua, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'th08a-' || v_ua::text || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()),
    (v_ub, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
     'th08b-' || v_ub::text || '@example.com',
     '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now());

  v_ta := iam._create_tenant_for_owner(
    v_ua,
    jsonb_build_object(
      'name', 'Cua hang TH08 A', 'contact_phone', '0900000008',
      'contact_email', 'th08a@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 8'
    )
  );
  v_tb := iam._create_tenant_for_owner(
    v_ub,
    jsonb_build_object(
      'name', 'Cua hang TH08 B', 'contact_phone', '0900000018',
      'contact_email', 'th08b@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 18'
    )
  );
  if v_ta is null or v_tb is null then
    raise exception 'FAIL: tenants were not created';
  end if;
  select s.id into v_store from catalog.stores s where s.tenant_id = v_ta limit 1;

  v_claims := json_build_object('sub', v_ua::text, 'role', 'authenticated')::text;
  v_claims_b := json_build_object('sub', v_ub::text, 'role', 'authenticated')::text;
  perform set_config('request.jwt.claims', v_claims, true);
  perform set_config('request.jwt.claim.sub', v_ua::text, true);
  set local role authenticated;

  -- Sản phẩm P1 (100.000)
  v_res := catalog.create_guided_product(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_name => 'Thuoc P1 TH08',
    p_reference_id => 'TH08-P1', p_unit_name => 'Hop');
  v_p1 := (v_res ->> 'product_id')::uuid;
  reset role;
  select id into v_u1 from catalog.product_units where product_id = v_p1 and is_base_unit = true;
  if exists (select 1 from catalog.products where id = v_p1 and is_ready_to_sell is not true) then
    update catalog.products set is_ready_to_sell = true where id = v_p1;
    raise notice 'einvoice_th08: is_ready_to_sell phải bật tay cho P1';
  end if;
  set local role authenticated;
  perform catalog.set_product_unit_price_band(
    p_tenant_id => v_ta, p_product_id => v_p1, p_product_unit_id => v_u1,
    p_source_type => 'manual',
    p_list_price_before_vat => 100000, p_list_price_after_vat => 100000,
    p_floor_price_before_vat => 50000, p_floor_price_after_vat => 50000);

  -- Khách
  v_ka := public._th08_customer(v_ta, v_ua, 'person', 'Anh A', null, null);
  v_kb := public._th08_customer(v_ta, v_ua, 'organization', 'Công ty B', '0101234567', '1 Lê Lợi');
  v_kb2 := public._th08_customer(v_ta, v_ua, 'organization', 'Công ty B2', '0101111111', '2 Lê Lợi');
  v_kb3 := public._th08_customer(v_ta, v_ua, 'organization', 'Công ty B3', '0103333333', '3 Lê Lợi');
  v_kc := public._th08_customer(v_ta, v_ua, 'organization', 'Công ty C', null, '4 Lê Lợi');
  v_kd := public._th08_customer(v_ta, v_ua, 'organization', 'Công ty D', '0109999999', null);

  -- Cấu hình HĐĐT (chèn thẳng dưới quyền chủ)
  reset role;
  insert into einvoice.provider_connections (tenant_id, status, capabilities_snapshot)
  values (v_ta, 'CONNECTED', jsonb_build_object(
    'supports_preview', true,
    'supports_email_delivery', true,
    'templates', jsonb_build_array(
      jsonb_build_object('template_id', 'T1', 'invoice_series', '1C26TAA',
                         'is_available', true, 'is_send_summary', false),
      jsonb_build_object('template_id', 'T2', 'invoice_series', '1C26MAA',
                         'is_available', true, 'is_send_summary', false))))
  returning id into v_conn;
  insert into einvoice.tenant_settings (tenant_id, default_template_id, default_invoice_series, profile_version)
  values (v_ta, 'T1', '1C26TAA', 1);

  -- =========================================================================
  -- E01 Chỉ một kết nối khác DISCONNECTED mỗi tenant
  -- =========================================================================
  v_ok := false;
  begin
    insert into einvoice.provider_connections (tenant_id, status) values (v_ta, 'CHECK_REQUIRED');
  exception when unique_violation then
    v_ok := true;
  end;
  if not v_ok then
    raise exception 'FAIL: E01 second active provider connection was accepted';
  end if;

  -- =========================================================================
  -- E02–E05 set_default_issuance_configuration
  -- =========================================================================
  set local role authenticated;
  select * into v_cfg from einvoice.set_default_issuance_configuration(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_template_id => 'T1',
    p_signing_config_id => 'sign-hsm', p_expected_profile_version => 1);
  if v_cfg.signing_config_id is distinct from 'sign-hsm' or v_cfg.profile_version is distinct from 2 then
    raise exception 'FAIL: E02 unexpected result: signing=% version=%', v_cfg.signing_config_id, v_cfg.profile_version;
  end if;

  perform public._th08_expect_err(format(
    'select * from einvoice.set_default_issuance_configuration(p_tenant_id => %L, p_actor_id => %L, p_template_id => %L, p_signing_config_id => %L, p_expected_profile_version => 2)',
    v_ta, v_ua, 'T2', 'sign-hsm'), 'SIGNING_CONFIGURATION_NOT_AVAILABLE');                      -- E03
  perform public._th08_expect_err(format(
    'select * from einvoice.set_default_issuance_configuration(p_tenant_id => %L, p_actor_id => %L, p_template_id => %L, p_signing_config_id => %L, p_expected_profile_version => 2)',
    v_ta, v_ua, 'KHONG_CO', 'sign-hsm'), 'TEMPLATE_NOT_AVAILABLE');                              -- E04
  perform public._th08_expect_err(format(
    'select * from einvoice.set_default_issuance_configuration(p_tenant_id => %L, p_actor_id => %L, p_template_id => %L, p_signing_config_id => %L, p_expected_profile_version => 99)',
    v_ta, v_ua, 'T1', 'sign-hsm'), 'STATE_CHANGED');                                             -- E05

  -- =========================================================================
  -- E06 ✱ KI-02: chưa sẵn sàng (không có mẫu mặc định) ⇒ không bật mới được
  -- =========================================================================
  reset role;
  update einvoice.tenant_settings
  set default_template_id = null, default_invoice_series = null
  where tenant_id = v_ta;
  select ts.policy_version into v_n from einvoice.tenant_settings ts where ts.tenant_id = v_ta;
  set local role authenticated;
  perform public._th08_expect_err(format(
    'select * from einvoice.update_automation_policy(p_tenant_id => %L, p_actor_id => %L, p_auto_issue_enabled => true, p_expected_policy_version => %s)',
    v_ta, v_ua, v_n), 'CONFIG_NOT_READY');
  reset role;
  update einvoice.tenant_settings
  set default_template_id = 'T1', default_invoice_series = '1C26TAA'
  where tenant_id = v_ta;
  select ts.auto_issue_enabled into v_flag from einvoice.tenant_settings ts where ts.tenant_id = v_ta;
  if v_flag then
    raise exception 'FAIL: E06 auto_issue_enabled turned on although the call was refused';
  end if;

  -- E07 ✱ đã sẵn sàng ⇒ bật được
  select ts.policy_version into v_n from einvoice.tenant_settings ts where ts.tenant_id = v_ta;
  set local role authenticated;
  select * into v_pol from einvoice.update_automation_policy(
    p_tenant_id => v_ta, p_actor_id => v_ua,
    p_auto_issue_enabled => true, p_expected_policy_version => v_n);
  if v_pol.auto_issue_enabled is not true then
    raise exception 'FAIL: E07 auto_issue_enabled not true: %', v_pol.auto_issue_enabled;
  end if;

  -- E08 ✱ đang bật sẵn mà mất kết nối: vẫn lưu được cờ gửi email
  reset role;
  update einvoice.provider_connections set status = 'RECONNECT_REQUIRED' where id = v_conn;
  select ts.policy_version into v_n from einvoice.tenant_settings ts where ts.tenant_id = v_ta;
  set local role authenticated;
  select * into v_pol from einvoice.update_automation_policy(
    p_tenant_id => v_ta, p_actor_id => v_ua,
    p_auto_issue_enabled => true, p_auto_send_enabled => true, p_expected_policy_version => v_n);
  if v_pol.auto_issue_enabled is not true or v_pol.auto_send_enabled is not true then
    raise exception 'FAIL: E08 flags not saved: issue=% send=%', v_pol.auto_issue_enabled, v_pol.auto_send_enabled;
  end if;

  -- E09 ✱ tắt luôn được dù chưa sẵn sàng
  select * into v_pol from einvoice.update_automation_policy(
    p_tenant_id => v_ta, p_actor_id => v_ua,
    p_auto_issue_enabled => false, p_expected_policy_version => v_pol.policy_version);
  if v_pol.auto_issue_enabled is not false then
    raise exception 'FAIL: E09 auto_issue_enabled not turned off';
  end if;
  reset role;
  update einvoice.provider_connections set status = 'CONNECTED' where id = v_conn;

  -- =========================================================================
  -- E10–E12, E16 phát hành thủ công: idempotency, xung đột, lệch phiên bản, đang xử lý
  -- =========================================================================
  set local role authenticated;
  v_oa := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_ka, 'individual', 'th08-sale-a');
  v_ver := public._th08_source_version(v_oa);

  select i.attempt_id into v_att1 from einvoice.issue_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_oa,
    p_source_version => v_ver, p_idempotency_key => 'k1') i;
  select i.attempt_id into v_att2 from einvoice.issue_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_oa,
    p_source_version => v_ver, p_idempotency_key => 'k1') i;
  if v_att1 is null or v_att1 is distinct from v_att2 then
    raise exception 'FAIL: E10 replay returned different attempt: % vs %', v_att1, v_att2;
  end if;
  v_n := public._th08_attempt_count(v_oa);
  if v_n <> 1 then
    raise exception 'FAIL: E10 expected 1 attempt but got %', v_n;
  end if;

  perform public._th08_expect_err(format(
    'select * from einvoice.issue_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_source_version => %L, p_idempotency_key => %L, p_acknowledge_warnings => true)',
    v_ta, v_ua, v_oa, v_ver, 'k1'), 'IDEMPOTENCY_CONFLICT');                                    -- E11

  v_oa2 := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_ka, 'individual', 'th08-sale-a2');
  perform public._th08_expect_err(format(
    'select * from einvoice.issue_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_source_version => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_oa2, 'khong-phai-phien-ban', 'k12'),
    'ISSUANCE_NOT_READY', 'SOURCE_VERSION_MISMATCH');                                           -- E12

  perform public._th08_expect_err(format(
    'select * from einvoice.retry_issuance(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_expected_order_version => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_oa, v_ver, 'k16'), 'OPERATION_IN_PROGRESS');                                  -- E16

  -- =========================================================================
  -- E13–E15 ✱ KI-04: server kiểm người mua (phát hành thủ công)
  -- =========================================================================
  v_oc := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kc, 'organization', 'th08-sale-c');
  v_ver := public._th08_source_version(v_oc);
  select * into v_rd from einvoice.get_issuance_readiness(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_oc);
  if v_rd.buyer_tax_code is not null then
    raise exception 'FAIL: E13 readiness buyer_tax_code should be null but is %', v_rd.buyer_tax_code;
  end if;
  v_cmd := public._th08_publish_command_count();
  perform public._th08_expect_err(format(
    'select * from einvoice.issue_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_source_version => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_oc, v_ver, 'k13'), 'ISSUANCE_NOT_READY', 'BUYER_TAX_CODE_REQUIRED');
  if public._th08_attempt_count(v_oc) <> 0 then
    raise exception 'FAIL: E13 an attempt was created for a buyer without tax code';
  end if;
  if public._th08_publish_command_count() <> v_cmd then
    raise exception 'FAIL: E13 einvoice.publish_invoice was enqueued for a buyer without tax code';
  end if;

  v_od := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kd, 'organization', 'th08-sale-d');
  v_ver := public._th08_source_version(v_od);
  perform public._th08_expect_err(format(
    'select * from einvoice.issue_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_source_version => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_od, v_ver, 'k14'), 'ISSUANCE_NOT_READY', 'BUYER_ADDRESS_REQUIRED');           -- E14

  v_ob := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kb, 'organization', 'th08-sale-b');
  v_ver := public._th08_source_version(v_ob);
  select i.attempt_id, i.status into v_iss from einvoice.issue_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob,
    p_source_version => v_ver, p_idempotency_key => 'k15') i;
  if v_iss.status is distinct from 'PREPARING' then
    raise exception 'FAIL: E15 expected PREPARING but got %', v_iss.status;                      -- E15
  end if;

  -- =========================================================================
  -- E17 ✱ KI-06: sửa MST trong hồ sơ khách sau lượt lỗi ⇒ lượt mới mang MST mới
  -- =========================================================================
  v_ob2 := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kb2, 'organization', 'th08-sale-b2');
  v_ver := public._th08_source_version(v_ob2);
  select i.attempt_id into v_att1 from einvoice.issue_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob2,
    p_source_version => v_ver, p_idempotency_key => 'k17a') i;
  reset role;
  perform public._th08_fail(v_ta, v_att1);
  update partner.organization_profiles set tax_code = '0102222222' where partner_id = v_kb2;
  set local role authenticated;
  select * into v_rd from einvoice.get_issuance_readiness(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob2);
  if v_rd.buyer_tax_code is distinct from '0102222222' then
    raise exception 'FAIL: E17 readiness still shows old tax code: %', v_rd.buyer_tax_code;
  end if;
  select i.attempt_id into v_att2 from einvoice.retry_issuance(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob2,
    p_expected_order_version => v_ver, p_idempotency_key => 'k17b') i;
  if public._th08_attempt_buyer(v_att2, 'buyerTaxCode') is distinct from '0102222222' then
    raise exception 'FAIL: E17 attempt 2 buyerTaxCode=%', public._th08_attempt_buyer(v_att2, 'buyerTaxCode');
  end if;
  if public._th08_completion_tax_code(v_ob2) is distinct from '0102222222' then
    raise exception 'FAIL: E17 completion tax code=%', public._th08_completion_tax_code(v_ob2);
  end if;

  -- =========================================================================
  -- E18 ✱ hồ sơ khách bị xoá MST sau lượt lỗi ⇒ lấy giá trị đã chép ở lượt đầu
  -- =========================================================================
  v_ob3 := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kb3, 'organization', 'th08-sale-b3');
  v_ver := public._th08_source_version(v_ob3);
  select i.attempt_id into v_att1 from einvoice.issue_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob3,
    p_source_version => v_ver, p_idempotency_key => 'k18a') i;
  reset role;
  perform public._th08_fail(v_ta, v_att1);
  update partner.organization_profiles set tax_code = null where partner_id = v_kb3;
  set local role authenticated;
  select i.attempt_id into v_att2 from einvoice.retry_issuance(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob3,
    p_expected_order_version => v_ver, p_idempotency_key => 'k18b') i;
  if public._th08_attempt_buyer(v_att2, 'buyerTaxCode') is distinct from '0103333333' then
    raise exception 'FAIL: E18 attempt 2 buyerTaxCode=%', public._th08_attempt_buyer(v_att2, 'buyerTaxCode');
  end if;

  -- =========================================================================
  -- E19–E21 ghi kết quả phát hành
  -- =========================================================================
  reset role;
  v_att1 := public._th08_attempt_id(v_ob, 1);
  perform public._th08_succeed(v_ta, v_att1);
  perform public._th08_succeed(v_ta, v_att1);
  if public._th08_invoice_count(v_ob) <> 1 then
    raise exception 'FAIL: E19 expected 1 electronic invoice but got %', public._th08_invoice_count(v_ob);
  end if;

  -- E20: ghi thất bại sau thành công không đổi trạng thái (hàm có thể từ chối INVALID_STATUS hoặc bỏ qua)
  begin
    perform public._th08_fail(v_ta, v_att1);
  exception when others then
    if sqlerrm not like 'INVALID_STATUS%' then
      raise exception 'FAIL: E20 unexpected error: %', sqlerrm;
    end if;
  end;
  if public._th08_attempt_status(v_att1) is distinct from 'SUCCEEDED' then
    raise exception 'FAIL: E20 attempt status changed to %', public._th08_attempt_status(v_att1);
  end if;
  if public._th08_invoice_count(v_ob) <> 1 then
    raise exception 'FAIL: E20 invoice count changed';
  end if;

  set local role authenticated;
  v_ver := public._th08_source_version(v_ob);
  perform public._th08_expect_err(format(
    'select * from einvoice.retry_issuance(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_expected_order_version => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_ob, v_ver, 'k21'), 'ALREADY_ISSUED');                                          -- E21

  -- =========================================================================
  -- E22–E25 gửi hoá đơn
  -- =========================================================================
  select d.delivery_id into v_del1 from einvoice.send_electronic_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob,
    p_recipient_email => 'b@x.vn', p_idempotency_key => v_g1) d;
  if public._th08_delivery_intent(v_del1) is distinct from 'INITIAL_SEND' then
    raise exception 'FAIL: E22 expected INITIAL_SEND but got %', public._th08_delivery_intent(v_del1);
  end if;

  perform public._th08_expect_err(format(
    'select * from einvoice.send_electronic_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_recipient_email => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_ob, 'b@x.vn', v_g2), 'OPERATION_IN_PROGRESS');                                 -- E23

  reset role;
  update einvoice.invoice_deliveries set status = 'UNKNOWN' where id = v_del1;
  set local role authenticated;
  select d.delivery_id into v_del2 from einvoice.send_electronic_invoice(
    p_tenant_id => v_ta, p_actor_id => v_ua, p_sales_order_id => v_ob,
    p_recipient_email => 'b@x.vn', p_idempotency_key => v_g2) d;
  if public._th08_delivery_intent(v_del2) is distinct from 'RESEND' then
    raise exception 'FAIL: E24 expected RESEND but got %', public._th08_delivery_intent(v_del2);
  end if;

  perform public._th08_expect_err(format(
    'select * from einvoice.send_electronic_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_recipient_email => %L, p_idempotency_key => %L)',
    v_ta, v_ua, v_ob, 'khac@x.vn', v_g2), 'IDEMPOTENCY_CONFLICT');                               -- E25

  -- E26: auto_send_enabled = false ⇒ start_auto_delivery bỏ qua, không thêm dòng gửi
  reset role;
  update einvoice.tenant_settings set auto_send_enabled = false where tenant_id = v_ta;
  v_inv := public._th08_invoice_id(v_ob);
  v_n := public._th08_delivery_count(v_inv);
  perform set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
  perform einvoice.start_auto_delivery(v_ta, v_inv, gen_random_uuid(), gen_random_uuid());
  perform set_config('request.jwt.claims', v_claims, true);
  if public._th08_delivery_count(v_inv) <> v_n then
    raise exception 'FAIL: E26 start_auto_delivery added a delivery while auto_send_enabled = false';
  end if;

  -- =========================================================================
  -- E27–E29 ✱ KI-04: phát hành tự động
  -- =========================================================================
  update einvoice.tenant_settings set auto_issue_enabled = true where tenant_id = v_ta;
  set local role authenticated;
  v_oc2 := public._th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_kc, 'organization', 'th08-sale-c2');
  reset role;
  select * into v_start from einvoice.start_auto_issuance(
    p_tenant_id => v_ta, p_sales_order_id => v_oc2,
    p_trigger_key => 't-kc', p_idempotency_key => 'auto-kc');
  if v_start.status is distinct from 'PENDING_REEVALUATION'
     or v_start.reason is distinct from 'BUYER_TAX_CODE_REQUIRED' then
    raise exception 'FAIL: E27 status=% reason=%', v_start.status, v_start.reason;
  end if;
  v_proc := v_start.process_id;
  if (select p.blocker_code from einvoice.auto_issuance_processes p where p.id = v_proc)
       is distinct from 'BUYER_TAX_CODE_REQUIRED' then
    raise exception 'FAIL: E27 process blocker_code not BUYER_TAX_CODE_REQUIRED';
  end if;
  if public._th08_attempt_count(v_oc2) <> 0 then
    raise exception 'FAIL: E27 an attempt was created for a buyer without tax code';
  end if;

  -- E28: thêm MST nhưng xoá địa chỉ
  update partner.organization_profiles
  set tax_code = '0108888888', invoice_address = null
  where partner_id = v_kc;
  select * into v_start from einvoice.reevaluate_auto_issuance(
    p_tenant_id => v_ta, p_process_id => v_proc, p_source_event_id => 'ev1');
  if v_start.reason is distinct from 'BUYER_ADDRESS_REQUIRED' then
    raise exception 'FAIL: E28 reason=%', v_start.reason;
  end if;
  if (select p.blocker_code from einvoice.auto_issuance_processes p where p.id = v_proc)
       is distinct from 'BUYER_ADDRESS_REQUIRED' then
    raise exception 'FAIL: E28 process blocker_code not updated';
  end if;
  if public._th08_attempt_count(v_oc2) <> 0 then
    raise exception 'FAIL: E28 an attempt was created for a buyer without address';
  end if;

  -- E29: thêm lại địa chỉ ⇒ tạo lượt
  update partner.organization_profiles set invoice_address = '4 Lê Lợi' where partner_id = v_kc;
  select * into v_start from einvoice.reevaluate_auto_issuance(
    p_tenant_id => v_ta, p_process_id => v_proc, p_source_event_id => 'ev2');
  if v_start.status is distinct from 'ATTEMPT_STARTED' then
    raise exception 'FAIL: E29 status=% reason=%', v_start.status, v_start.reason;
  end if;
  if public._th08_attempt_count(v_oc2) <> 1 then
    raise exception 'FAIL: E29 expected 1 attempt but got %', public._th08_attempt_count(v_oc2);
  end if;

  -- =========================================================================
  -- E30 ✱ G4: hàm của bộ xử lý không còn gọi được từ authenticated
  -- =========================================================================
  set local role authenticated;
  perform public._th08_expect_err(format(
    'select * from einvoice.start_auto_issuance(%L, %L, %L, %L)',
    v_ta, v_oc2, 'x-trigger', 'x-key'), 'permission denied');
  perform public._th08_expect_err(format(
    'select * from einvoice.reevaluate_auto_issuance(%L, %L, %L)',
    v_ta, v_proc, 'x-event'), 'permission denied');
  perform public._th08_expect_err(format(
    'select * from einvoice.list_open_auto_issuance_processes(%L, %L)',
    v_ta, v_kc), 'permission denied');
  perform public._th08_expect_err(format(
    'select einvoice.build_canonical_invoice(%L, %L, %L, %L::jsonb, %L::jsonb)',
    v_ta, v_oc2, '1', '{}', '{}'), 'permission denied');
  perform public._th08_expect_err(format(
    'select einvoice._buyer_issuance_blocker(%L, %L, %L, %L::jsonb)',
    v_ta, v_oc2, v_kc, '{}'), 'permission denied');

  -- =========================================================================
  -- E31 owner tenant khác không đụng được tenant này
  -- =========================================================================
  reset role;
  perform set_config('request.jwt.claims', v_claims_b, true);
  perform set_config('request.jwt.claim.sub', v_ub::text, true);
  set local role authenticated;
  perform public._th08_expect_err(format(
    'select * from einvoice.get_issuance_readiness(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L)',
    v_ta, v_ub, v_oa), 'NO_PERMISSION');
  perform public._th08_expect_err(format(
    'select * from einvoice.get_order_invoice_projection(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L)',
    v_ta, v_ub, v_oa), 'NO_PERMISSION');
  perform public._th08_expect_err(format(
    'select * from einvoice.issue_invoice(p_tenant_id => %L, p_actor_id => %L, p_sales_order_id => %L, p_source_version => %L, p_idempotency_key => %L)',
    v_ta, v_ub, v_oa, '1', 'k31'), 'NO_PERMISSION');

  -- =========================================================================
  -- E32 list_tenants_with_due_commands lọc đúng điều kiện claim
  -- =========================================================================
  reset role;
  insert into einvoice.internal_commands (id, tenant_id, command_type, payload, enqueued_at)
  values (gen_random_uuid(), v_tb, 'einvoice.sync_capabilities', '{}', now() + interval '1 hour');
  insert into einvoice.internal_commands (id, tenant_id, command_type, payload, enqueued_at, claimed_at, claim_token)
  values (gen_random_uuid(), v_tb, 'einvoice.sync_capabilities', '{}', now() - interval '1 hour', now() - interval '1 minute', gen_random_uuid());
  insert into einvoice.internal_commands (id, tenant_id, command_type, payload, enqueued_at, processed_at)
  values (gen_random_uuid(), v_tb, 'einvoice.sync_capabilities', '{}', now() - interval '1 hour', now());
  select count(*) into v_n from einvoice.list_tenants_with_due_commands(1000) where tenant_id = v_tb;
  if v_n <> 0 then raise exception 'FAIL E32a: tenant B listed without due command'; end if;
  insert into einvoice.internal_commands (id, tenant_id, command_type, payload, enqueued_at, claimed_at, claim_token)
  values (gen_random_uuid(), v_tb, 'einvoice.sync_capabilities', '{}', now() - interval '1 hour', now() - interval '11 minutes', gen_random_uuid());
  select oldest_due_at into v_due from einvoice.list_tenants_with_due_commands(1000) where tenant_id = v_tb;
  if v_due is null or v_due > now() then raise exception 'FAIL E32b: tenant B not listed with stale claim'; end if;

  -- =========================================================================
  -- E33 reschedule_internal_command không ghi cột không tồn tại (KI-22)
  -- =========================================================================
  select command_id, claim_token, retry_count into v_cmd, v_tok, v_rc
  from einvoice.claim_internal_commands_batch(v_tb, 10);
  if v_cmd is null then raise exception 'FAIL E33: claim returned no row'; end if;
  perform einvoice.reschedule_internal_command(v_tb, v_cmd, v_tok, 120);
  select count(*) into v_n from einvoice.internal_commands
  where id = v_cmd and enqueued_at between now() + interval '119 seconds' and now() + interval '121 seconds'
    and claimed_at is null and claim_token is null and retry_count = v_rc;
  if v_n <> 1 then raise exception 'FAIL E33: reschedule did not reset the row as expected'; end if;
  select count(*) into v_n from einvoice.list_tenants_with_due_commands(1000) where tenant_id = v_tb;
  if v_n <> 0 then raise exception 'FAIL E33: tenant B still listed after reschedule'; end if;

  -- =========================================================================
  -- E34 list_tenants_with_due_commands chỉ service_role
  -- =========================================================================
  perform set_config('request.jwt.claims', v_claims, true);
  set local role authenticated;
  perform public._th08_expect_err('select * from einvoice.list_tenants_with_due_commands(10)', 'permission denied');
  reset role;

  -- =========================================================================
  -- E40 seed_due_issuance_reconciliation_commands không ghi cột không tồn tại (KI-23)
  -- =========================================================================
  insert into einvoice.invoice_reconciliation_cases (
    tenant_id, target_type, target_id, provider_connection_id, reason_code, status,
    check_count, next_check_at, correlation_id
  ) values (
    v_ta, 'ISSUANCE_ATTEMPT', gen_random_uuid(), v_conn, 'E40_TEST', 'PENDING',
    0, now() - interval '1 minute', 'e40'
  )
  returning id into v_case;
  select einvoice.seed_due_issuance_reconciliation_commands(v_ta, 1000) into v_n;
  if v_n < 1 then raise exception 'FAIL E40: seed returned %', v_n; end if;
  select count(*) into v_n from einvoice.internal_commands
  where id = einvoice._reconciliation_poll_command_id(v_case, 1)
    and tenant_id = v_ta
    and command_type = 'einvoice.poll_issuance_status'
    and enqueued_at <= now()
    and processed_at is null and failed_at is null;
  if v_n <> 1 then raise exception 'FAIL E40: poll command not seeded'; end if;

  raise notice 'einvoice_th08: OK';
end;
$$;

rollback;
