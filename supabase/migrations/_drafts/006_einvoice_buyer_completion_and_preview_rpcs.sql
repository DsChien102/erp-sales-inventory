-- Title: einvoice S2a — readiness/preview/completion RPCs
-- Kind: patch
-- Intent: S2a read+command RPCs (get_issuance_readiness, complete_buyer_invoice_data, request_invoice_preview, get_invoice_preview, store_preview_result)
-- Context: TH-08 EP-02/US-01.
-- Touches: einvoice.get_issuance_readiness, einvoice.complete_buyer_invoice_data, einvoice._effective_buyer_snapshot, einvoice.build_canonical_invoice, einvoice.request_invoice_preview, einvoice.get_invoice_preview, einvoice.store_preview_result
-- Safety: security definer, tenant scoped, raises stable CODE errors
-- Depends on: 005_einvoice_buyer_completion_and_preview_schema.sql, 002_einvoice_install_module_messaging.sql, 018_sales_einvoice_source_contract.sql

-- Kiểu trả về đổi (thêm source_blockers) → phải drop trước khi tạo lại.
drop function if exists einvoice.get_issuance_readiness(uuid, uuid, uuid);

create or replace function einvoice.get_issuance_readiness(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  order_completed boolean,
  has_electronic_invoice boolean,
  has_active_operation boolean,
  config_ready boolean,
  provider_connected boolean,
  provider_supports_preview boolean,
  buyer_type text,
  buyer_name text,
  buyer_email text,
  buyer_tax_code text,
  buyer_address text,
  buyer_completion_state text,
  commercial_data_mappable boolean,
  config_warnings jsonb,
  source_blockers jsonb
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
declare
  v_provider_status text;
  v_capabilities jsonb;
  v_config_ready boolean := false;
  v_provider_connected boolean := false;
  v_supports_preview boolean := false;
  v_warnings jsonb := '[]'::jsonb;
  v_buyer_name text := '';
  v_buyer_tax_code text := null;
  v_buyer_email text := null;
  v_buyer_address text := null;
  v_buyer_type text;
  v_source record;
  v_has_electronic_invoice boolean := false;
  v_has_active_operation boolean := false;
begin
  -- Access check
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.view') then
      raise exception 'NO_PERMISSION: einvoice.view required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  -- 1. Check provider connection & capabilities
  select pc.status, pc.capabilities_snapshot
  into v_provider_status, v_capabilities
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id and pc.status <> 'DISCONNECTED'
  limit 1;

  if v_provider_status = 'CONNECTED' then
    v_provider_connected := true;
  end if;

  if v_capabilities is not null then
    v_supports_preview := coalesce((v_capabilities ->> 'supports_preview')::boolean, false);
  end if;

  -- 2. Check issuance profile & policy
  if exists (
    select 1 from einvoice.tenant_settings ts
    where ts.tenant_id = p_tenant_id
      and ts.default_template_id is not null
  ) and v_provider_connected then
    v_config_ready := true;
  end if;

  -- 3. Load sales order source snapshot
  select *
  into v_source
  from sales.get_einvoice_source_snapshot(p_tenant_id, p_sales_order_id);

  -- 4. Dữ liệu người mua đã bổ sung (nếu có)
  select bc.buyer_name, bc.buyer_tax_code, bc.buyer_email, bc.buyer_address
  into v_buyer_name, v_buyer_tax_code, v_buyer_email, v_buyer_address
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id and bc.sales_order_id = p_sales_order_id;

  -- Chuẩn hóa giá trị completion về NULL khi rỗng, để coalesce phía dưới
  -- rơi xuống đúng nguồn tiếp theo thay vì giữ chuỗi rỗng.
  v_buyer_name     := nullif(btrim(coalesce(v_buyer_name, '')), '');
  v_buyer_tax_code := nullif(btrim(coalesce(v_buyer_tax_code, '')), '');
  v_buyer_email    := nullif(btrim(coalesce(v_buyer_email, '')), '');
  v_buyer_address  := nullif(btrim(coalesce(v_buyer_address, '')), '');

  if v_source.buyer_partner_id is null then
    -- BR-06: nội dung bắt buộc cho khách lẻ
    v_buyer_type     := 'retail';
    v_buyer_name     := 'Bán cho người tiêu dùng';
    v_buyer_tax_code := null;
    v_buyer_email    := null;
    v_buyer_address  := null;
  else
    -- Loại pháp nhân do Theme 05 chụp lại lúc bán (Task 3b), không suy từ taxCode.
    -- Đơn cũ chưa có buyer_tax_snapshot → NULL → không phân loại được;
    -- khi đó để 'individual' để luật isComplete chỉ đòi tên.
    v_buyer_type := coalesce(v_source.buyer_snapshot ->> 'buyerType', 'individual');
    if v_buyer_type not in ('individual', 'organization') then
      v_buyer_type := 'individual';
    end if;

    -- completion > ảnh chụp Theme 05
    v_buyer_name     := coalesce(v_buyer_name,     v_source.buyer_snapshot ->> 'buyerLegalName');
    v_buyer_tax_code := coalesce(v_buyer_tax_code, v_source.buyer_snapshot ->> 'buyerTaxCode');
    v_buyer_address  := coalesce(v_buyer_address,  v_source.buyer_snapshot ->> 'buyerAddress');
    v_buyer_email    := coalesce(v_buyer_email,    v_source.buyer_snapshot ->> 'buyerEmail');
  end if;

  -- BR-07: KHÔNG điền tên mặc định cho khách định danh.
  -- name rỗng → EffectiveBuyerInvoiceData.isComplete = false
  -- → IssuanceReadinessEvaluator:110-114 phát BUYER_DATA_INCOMPLETE.
  v_buyer_name := coalesce(v_buyer_name, '');

  -- BR-14: Org có MST nhưng thiếu địa chỉ phải bị chặn trước preview/issue.
  -- Readiness domain mapper phát blocker BUYER_ADDRESS_REQUIRED từ các trường này.
  if v_buyer_type = 'organization'
     and v_buyer_tax_code is not null
     and btrim(v_buyer_tax_code) <> ''
     and (v_buyer_address is null or btrim(v_buyer_address) = '') then
    -- keep source fields authoritative; blocker is derived at application/domain.
    null;
  end if;

  -- 5. Existing invoice check
  select exists (
    select 1 from einvoice.electronic_invoices
    where tenant_id = p_tenant_id and sales_order_id = p_sales_order_id
  ) into v_has_electronic_invoice;

  -- 6. Active attempt check
  select exists (
    select 1
    from einvoice.issuance_attempts ia
    join einvoice.invoice_issuances ii on ii.id = ia.invoice_issuance_id
    where ii.tenant_id = p_tenant_id
      and ii.sales_order_id = p_sales_order_id
      and ia.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING')
  ) into v_has_active_operation;

  return query select
    coalesce(v_source.order_completed, false),
    v_has_electronic_invoice,
    v_has_active_operation,
    v_config_ready,
    v_provider_connected,
    v_supports_preview,
    v_buyer_type,
    v_buyer_name,
    v_buyer_email,
    v_buyer_tax_code,
    v_buyer_address,
    'locked'::text,
    (coalesce(v_source.available, false) and jsonb_array_length(coalesce(v_source.commercial_snapshot -> 'lines', '[]'::jsonb)) > 0),
    v_warnings,
    coalesce(v_source.blockers, '[]'::jsonb);
end;
$$;

create or replace function einvoice.complete_buyer_invoice_data(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_expected_order_version int,
  p_eligible_fields jsonb default '[]'::jsonb,
  p_resolved_values jsonb default '{}'::jsonb
) returns table(
  locked boolean,
  eligible_fields jsonb,
  resolved_values jsonb
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
declare
  v_partner_id uuid;
  v_name text;
  v_tax_code text;
  v_email text;
  v_address text;
begin
  -- Chỉ màn hình gọi hàm này (không có lệnh nền), nên bắt buộc có phiên
  -- người dùng — khác các hàm vừa phục vụ màn hình vừa phục vụ worker.
  if auth.uid() is null or p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'NO_PERMISSION: actor mismatch';
  end if;
  -- Cùng quyền với issue_invoice; Dart đòi einvoice.issue cho lệnh này.
  if not iam.has_permission(p_tenant_id, 'einvoice.issue')
     and not iam.has_permission(p_tenant_id, 'einvoice.manage_issuance') then
    raise exception 'NO_PERMISSION: einvoice.issue required';
  end if;
  if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
    raise exception 'NO_PERMISSION: sales order not accessible';
  end if;

  -- Người mua bất biến sau checkout: completion gắn theo đơn; version chỉ lưu vết.
  select s.buyer_partner_id
  into v_partner_id
  from sales.get_einvoice_source_snapshot(p_tenant_id, p_sales_order_id) s;

  if v_partner_id is null then
    raise exception 'VALIDATION_ERROR: buyer partner required';
  end if;

  insert into einvoice.buyer_invoice_completions as bc (
    tenant_id,
    sales_order_id,
    sales_order_version,
    buyer_name,
    buyer_tax_code,
    buyer_email,
    buyer_address,
    completed_by_user_id,
    completed_at
  ) values (
    p_tenant_id,
    p_sales_order_id,
    p_expected_order_version::text,
    nullif(btrim(coalesce(p_resolved_values ->> 'name', '')), ''),
    nullif(btrim(coalesce(p_resolved_values ->> 'taxCode', '')), ''),
    nullif(btrim(coalesce(p_resolved_values ->> 'email', '')), ''),
    nullif(btrim(coalesce(p_resolved_values ->> 'address', '')), ''),
    p_actor_id,
    now()
  )
  on conflict (tenant_id, sales_order_id) do update set
    sales_order_version = excluded.sales_order_version,
    buyer_name = excluded.buyer_name,
    buyer_tax_code = excluded.buyer_tax_code,
    buyer_email = excluded.buyer_email,
    buyer_address = excluded.buyer_address,
    completed_by_user_id = excluded.completed_by_user_id,
    completed_at = excluded.completed_at
  returning bc.buyer_name, bc.buyer_tax_code, bc.buyer_email, bc.buyer_address
  into v_name, v_tax_code, v_email, v_address;

  -- Kiểm tra sau khi ghi: câu ghi đã chờ khoá "for share" của lần phát hành
  -- đang chạy (nếu có) nên giờ thấy được nó; ném lỗi thì cả câu ghi rollback.
  if exists (
    select 1
    from einvoice.electronic_invoices ei
    where ei.tenant_id = p_tenant_id
      and ei.sales_order_id = p_sales_order_id
  ) then
    raise exception 'ALREADY_ISSUED: invoice already issued for this order';
  end if;

  if exists (
    select 1
    from einvoice.issuance_attempts ia
    join einvoice.invoice_issuances ii on ii.id = ia.invoice_issuance_id
    where ii.tenant_id = p_tenant_id
      and ii.sales_order_id = p_sales_order_id
      and ia.status in ('PREPARING', 'SUBMITTED', 'WAITING_RESULT', 'RECONCILING')
  ) then
    raise exception 'OPERATION_IN_PROGRESS: an issuance attempt is running';
  end if;

  return query select
    true,
    p_eligible_fields,
    jsonb_strip_nulls(jsonb_build_object(
      'name', v_name,
      'taxCode', v_tax_code,
      'email', v_email,
      'address', v_address
    ));
end;
$$;

-- EffectiveBuyerInvoiceData = ảnh chụp Theme 05 + dữ liệu đã bổ sung (đè khi có).
-- Dùng chung cho phát hành và xem trước để hai bên thấy cùng một người mua.
create or replace function einvoice._effective_buyer_snapshot(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_base_snapshot jsonb
) returns jsonb
language sql
stable
security definer
set search_path = einvoice, public
as $$
  select coalesce(p_base_snapshot, '{}'::jsonb) || coalesce((
    select jsonb_strip_nulls(jsonb_build_object(
      'buyerLegalName', bc.buyer_name,
      'buyerTaxCode', bc.buyer_tax_code,
      'buyerEmail', bc.buyer_email,
      'buyerAddress', bc.buyer_address
    ))
    from einvoice.buyer_invoice_completions bc
    where bc.tenant_id = p_tenant_id
      and bc.sales_order_id = p_sales_order_id
  ), '{}'::jsonb);
$$;

create or replace function einvoice.build_canonical_invoice(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_source_version text,
  p_buyer_snapshot jsonb,
  p_commercial_snapshot jsonb
) returns jsonb
language plpgsql
security definer
set search_path = einvoice, public, pg_temp
as $$
declare
  v_inv_series text;
  v_selected_template_id text;
  v_selected_inv_series text;
  v_current_inv_series text;
  v_invoice_with_code boolean;
  v_is_mtt boolean;
  v_is_invoice_summary boolean := false;
  v_sign_type int;
  v_lines jsonb;
  v_totals jsonb;
  v_tax_rates jsonb;
  v_buyer_name text;
  v_buyer_type text;
  v_buyer_full_name text;
  v_buyer_legal_name text;
  v_buyer_address text;
  v_buyer_tax_code text;
  v_buyer_phone text;
  v_buyer_email text;
  v_total_amount numeric;
begin
  -- Resolve the selected profile first. The provider capability is checked in a
  -- separate query so a matching template id cannot silently replace the
  -- selected contract with a different series.
  select
    ts.default_template_id,
    ts.default_invoice_series
  into
    v_selected_template_id,
    v_selected_inv_series
  from einvoice.tenant_settings ts
  where ts.tenant_id = p_tenant_id
  limit 1;

  if v_selected_template_id is null or v_selected_inv_series is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'TEMPLATE_NOT_AVAILABLE',
      'details', 'configured template selection is incomplete'
    )::text;
  end if;

  select
    coalesce(
      nullif(btrim(elem ->> 'invoice_series'), ''),
      nullif(btrim(elem ->> 'symbol'), '')
    ),
    coalesce((elem ->> 'is_send_summary')::boolean, false)
  into v_current_inv_series, v_is_invoice_summary
  from einvoice.provider_connections pc
  cross join lateral jsonb_array_elements(
    coalesce(pc.capabilities_snapshot -> 'templates', '[]'::jsonb)
  ) as elem
  where pc.tenant_id = p_tenant_id
    and pc.status = 'CONNECTED'
    and coalesce(elem ->> 'template_id', elem ->> 'templateId') = v_selected_template_id
    and jsonb_typeof(elem -> 'is_available') = 'boolean'
    and (elem ->> 'is_available')::boolean
  limit 1;

  if v_current_inv_series is null then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'TEMPLATE_NOT_AVAILABLE',
      'details', 'configured template is not available in current capability'
    )::text;
  end if;

  if upper(v_selected_inv_series) !~ '^[1256][CK].{2}[TM]'
     or upper(v_current_inv_series) !~ '^[1256][CK].{2}[TM]' then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'TEMPLATE_NOT_AVAILABLE',
      'details', 'configured InvSeries is malformed'
    )::text;
  end if;

  if upper(substr(v_selected_inv_series, 1, 2) || substr(v_selected_inv_series, 5))
     <> upper(substr(v_current_inv_series, 1, 2) || substr(v_current_inv_series, 5)) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'TEMPLATE_NOT_AVAILABLE',
      'details', 'provider template contract drifted outside year rollover'
    )::text;
  end if;

  v_inv_series := upper(v_current_inv_series);
  v_invoice_with_code := upper(substr(v_inv_series, 2, 1)) = 'C';
  v_is_mtt := upper(substr(v_inv_series, 5, 1)) = 'M';

  v_sign_type := case when v_is_mtt then 5 else 2 end;

  -- BR-06 / BR-07 phải áp tại nơi dựng payload, không chỉ ở get_issuance_readiness:
  -- preview và issue gọi thẳng hàm này với buyer_snapshot gốc từ Sales.
  -- MISA có HAI ô tên khác nhau trên hóa đơn:
  --   BuyerFullName  → "Họ tên người mua hàng"  (con người)
  --   BuyerLegalName → "Tên đơn vị"             (pháp nhân)
  -- Đặt tên cá nhân vào BuyerLegalName là ghi một con người thành một tổ chức
  -- trên chứng từ thuế. Định tuyến theo buyerType do Theme 05 chụp lại.
  v_buyer_type := coalesce(p_buyer_snapshot ->> 'buyerType', '');

  if v_buyer_type = 'retail' then
    -- BR-06: khách lẻ dùng nội dung cố định, không có pháp nhân.
    v_buyer_full_name := 'Bán cho người tiêu dùng';
    v_buyer_legal_name := null;
  else
    v_buyer_name := coalesce(
      p_buyer_snapshot ->> 'buyerLegalName',
      p_buyer_snapshot ->> 'name');

    -- BR-07: khách định danh thiếu tên thì chặn, không tự hạ thành khách lẻ.
    if v_buyer_name is null or btrim(v_buyer_name) = '' then
      raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
        'details', 'buyer name is required for an identified buyer'
      )::text;
    end if;

    if v_buyer_type = 'organization' then
      v_buyer_legal_name := v_buyer_name;
      v_buyer_full_name := null;
    else
      -- 'individual', và cả đơn cũ chưa có buyerType: mặc định là con người.
      v_buyer_full_name := v_buyer_name;
      v_buyer_legal_name := null;
    end if;
  end if;

  -- Không bịa địa chỉ. Trước đây coalesce về 'Việt Nam' nên mọi hóa đơn thiếu
  -- địa chỉ đều in ra một địa chỉ không có thật. Thiếu thì để trống.
  v_buyer_address := nullif(btrim(coalesce(
    p_buyer_snapshot ->> 'buyerAddress',
    p_buyer_snapshot ->> 'address',
    '')), '');
  v_buyer_tax_code := p_buyer_snapshot ->> 'buyerTaxCode';
  v_buyer_phone := coalesce(p_buyer_snapshot ->> 'buyerPhoneNumber', p_buyer_snapshot ->> 'phone');
  v_buyer_email := coalesce(p_buyer_snapshot ->> 'buyerEmail', p_buyer_snapshot ->> 'email');

  v_totals := coalesce(p_commercial_snapshot -> 'totals', '{}'::jsonb);

  -- ─────────────────────────────────────────────────────────────────────────
  -- BR-14: preview/issue phải fail closed nếu org có MST nhưng thiếu địa chỉ.
  if v_buyer_type = 'organization'
     and v_buyer_tax_code is not null
     and btrim(v_buyer_tax_code) <> ''
     and (v_buyer_address is null or btrim(v_buyer_address) = '') then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'BUYER_ADDRESS_REQUIRED',
      'details', 'organization buyer with tax code must provide address'
    )::text;
  end if;

  -- ─────────────────────────────────────────────────────────────────────────
  -- ADR-TH08-KCT — Chính sách sản phẩm KCT-only (BA duyệt 16/09/2026)
  --
  -- Quyết định: VET45 trong phạm vi hộ kinh doanh hiện tại không có luồng
  -- cấu hình thuế ở Product, Catalog, Sales hoặc UI. Theme 8 là boundary
  -- duy nhất áp VATRateName=KCT và tiền thuế 0 trên canonical MISA.
  --
  -- Invariant nguồn Sales (fail closed trước khi áp KCT):
  --   mọi line.taxAmountMinor = 0
  --   totals.taxMinor = 0
  --   mọi line.taxSnapshot null hoặc object rỗng
  --
  -- Vi phạm → UNSUPPORTED_TAX_DATA; không ghi đè thành KCT, không gọi provider.
  --
  -- Change control: không có trigger tự gỡ hard-code. Chỉ đổi chính sách
  -- sau quyết định sản phẩm/BA mới và plan riêng cập nhật Product/Sales/e-invoice.
  -- ─────────────────────────────────────────────────────────────────────────
  if exists (
    select 1
    from jsonb_array_elements(
      coalesce(p_commercial_snapshot -> 'lines', '[]'::jsonb)
    ) ln
    where not (ln ? 'taxAmountMinor')
       or jsonb_typeof(ln -> 'taxAmountMinor') is distinct from 'number'
       or ln -> 'taxAmountMinor' <> '0'::jsonb
       or (
         ln ? 'taxSnapshot'
         and ln -> 'taxSnapshot' not in ('null'::jsonb, '{}'::jsonb)
       )
  ) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'UNSUPPORTED_TAX_DATA',
      'details', 'commercial line violates KCT-only contract'
    )::text;
  end if;

  if not (v_totals ? 'taxMinor')
     or jsonb_typeof(v_totals -> 'taxMinor') is distinct from 'number'
     or v_totals -> 'taxMinor' <> '0'::jsonb then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'code', 'UNSUPPORTED_TAX_DATA',
      'details', 'order totals tax violates KCT-only contract'
    )::text;
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'lineNumber',       (ln ->> 'lineSequence')::int,
      'sortOrder',        (ln ->> 'lineSequence')::int,
      'itemName',         ln ->> 'itemName',
      'itemCode',         ln ->> 'itemCode',
      'unitName',         ln ->> 'unitName',
      -- BẤT BIẾN HASH: mọi số trong canonical phải qua trim_scale.
      --
      -- Hash toàn vẹn được tính bằng sha256(canonical::text) ở 008, rồi canonical
      -- đi vòng PostgREST → Dart → quay lại và bị băm lại ở prepare_issuance_publish.
      -- Chuỗi phải sống sót nguyên vẹn qua vòng đó.
      -- Chia numeric trong Postgres cho ra 16 chữ số thập phân (2.0000000000000000);
      -- Dart đọc thành double rồi ghi lại là "2.0" → hash khác → STATE_CHANGED.
      -- trim_scale cắt số 0 thừa nên chuỗi giống nhau ở cả hai phía.
      -- Thêm trường số mới thì cũng phải bọc trim_scale.
      'quantity',         trim_scale((ln ->> 'quantityMicros')::numeric / 1000000.0),
      'unitPrice',        trim_scale((ln ->> 'unitPriceMinor')::numeric),
      'amount',           trim_scale((ln ->> 'grossAmountMinor')::numeric),
      'discountAmount',   trim_scale((ln ->> 'discountMinor')::numeric),
      'amountWithoutVat', trim_scale((ln ->> 'lineTotalMinor')::numeric),
      -- ADR-TH08-KCT: xem chú thích tại khối taxRateInfo bên dưới.
      'vatRateName',      'KCT',
      'vatAmount',        0
    ) order by (ln ->> 'lineSequence')::int
  ), '[]'::jsonb)
  into v_lines
  from jsonb_array_elements(
    coalesce(p_commercial_snapshot -> 'lines', '[]'::jsonb)
  ) ln;

  if jsonb_array_length(v_lines) = 0 then
    raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
      'details', 'originalInvoiceDetail must contain at least one line item'
    )::text;
  end if;

  v_total_amount := coalesce((v_totals ->> 'payableMinor')::numeric, 0);
  if v_total_amount <= 0 then
    raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
      'details', 'totalAmount must be positive'
    )::text;
  end if;

  -- Thiếu khoá thì `NULL <> x` cho ra NULL và `if NULL` không kích hoạt,
  -- tức assert tự vô hiệu hóa đúng lúc dữ liệu hỏng. Kiểm NULL tường minh,
  -- và dùng `is distinct from` để phép so sánh không bao giờ trả NULL.
  if (v_totals ->> 'subtotalMinor') is null
     or (v_totals ->> 'discountMinor') is null
     or (v_totals ->> 'payableMinor') is null
     or (v_totals ->> 'subtotalMinor')::numeric
        - (v_totals ->> 'discountMinor')::numeric
        is distinct from (v_totals ->> 'payableMinor')::numeric then
    raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
      'details', 'totals identity violated: subtotal - discount <> payable'
    )::text;
  end if;

  -- Áp chính sách KCT-only sau khi invariant nguồn đã pass (ADR ở trên).
  v_tax_rates := jsonb_build_array(
    jsonb_build_object(
      'vatRateName', 'KCT',
      'turnover',    trim_scale((v_totals ->> 'payableMinor')::numeric),
      'vatAmount',   0
    )
  );

  return jsonb_build_object(
    'modelVersion', '1.0.0',
    'salesOrderId', p_sales_order_id,
    'sourceVersion', p_source_version,
    'invSeries', v_inv_series,
    'invoiceWithCode', v_invoice_with_code,
    'isInvoiceSummary', v_is_invoice_summary,
    'signType', v_sign_type,
    'invDate', to_char(now() at time zone 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD'),
    'currencyCode', 'VND',
    'exchangeRate', 1,
    'paymentMethodName', 'TM/CK',
    'buyerFullName', v_buyer_full_name,
    'buyerLegalName', v_buyer_legal_name,
    'buyerAddress', v_buyer_address,
    'buyerTaxCode', v_buyer_tax_code,
    'buyerPhoneNumber', v_buyer_phone,
    'buyerEmail', v_buyer_email,
    'totalSaleAmount',     trim_scale((v_totals ->> 'subtotalMinor')::numeric),
    'totalDiscountAmount', trim_scale((v_totals ->> 'discountMinor')::numeric),
    'totalAmountWithoutVat', trim_scale((v_totals ->> 'payableMinor')::numeric),
    'totalVatAmount',      0,
    'totalAmount',         trim_scale((v_totals ->> 'payableMinor')::numeric),
    'originalInvoiceDetail', v_lines,
    'taxRateInfo', v_tax_rates
  );
end;
$$;

create or replace function einvoice.request_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_expected_order_version int
) returns table(preview_request_id uuid)
language plpgsql security definer set search_path = einvoice, iam, sales, public
as $$
declare
  v_request_id uuid := gen_random_uuid();
  v_provider_connection_id uuid;
  v_source record;
  v_canonical jsonb;
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.manage_issuance')
       and not iam.has_permission(p_tenant_id, 'einvoice.view') then
      raise exception 'NO_PERMISSION: einvoice permission required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  select pc.id
  into v_provider_connection_id
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id
    and pc.status <> 'DISCONNECTED'
  limit 1;

  if v_provider_connection_id is null then
    raise exception 'ISSUANCE_NOT_READY: provider not connected';
  end if;

  select *
  into v_source
  from sales.get_einvoice_source_snapshot(p_tenant_id, p_sales_order_id);

  if not coalesce(v_source.available, false) then
    raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object(
      'details', jsonb_build_object('blockers', v_source.blockers)
    )::text;
  end if;

  v_canonical := einvoice.build_canonical_invoice(
    p_tenant_id,
    p_sales_order_id,
    p_expected_order_version::text,
    einvoice._effective_buyer_snapshot(
      p_tenant_id,
      p_sales_order_id,
      v_source.buyer_snapshot
    ),
    v_source.commercial_snapshot
  );

  -- Version-bound (BR-13/EC-01): yêu cầu mới thay bản xem trước cũ của đơn.
  insert into einvoice.invoice_previews as p (
    tenant_id,
    sales_order_id,
    request_id,
    sales_order_version,
    status,
    expires_at,
    requested_at
  ) values (
    p_tenant_id,
    p_sales_order_id,
    v_request_id,
    p_expected_order_version::text,
    'PENDING',
    now() + interval '15 minutes',
    now()
  )
  on conflict (tenant_id, sales_order_id) do update set
    request_id = excluded.request_id,
    sales_order_version = excluded.sales_order_version,
    status = 'PENDING',
    viewer_ref = null,
    failure_code = null,
    failure_message = null,
    failure_source = null,
    completed_at = null,
    expires_at = excluded.expires_at,
    requested_at = excluded.requested_at;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.preview_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', p_sales_order_id,
      'preview_request_id', v_request_id,
      'order_version', p_expected_order_version,
      'provider_connection_id', v_provider_connection_id,
      'canonical_invoice', v_canonical
    ),
    p_source_event_id => v_request_id
  );
  return query select v_request_id;
end;
$$;

drop function if exists einvoice.get_invoice_preview(uuid, uuid, uuid);

create or replace function einvoice.get_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  viewer_ref text,
  status text,
  failure_code text
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
begin
  if auth.uid() is not null then
    if auth.uid() <> p_actor_id then
      raise exception 'NO_PERMISSION: actor mismatch';
    end if;
    if not iam.has_permission(p_tenant_id, 'einvoice.view') then
      raise exception 'NO_PERMISSION: einvoice.view required';
    end if;
    if not sales.can_access_sales_order(p_tenant_id, p_actor_id, p_sales_order_id) then
      raise exception 'NO_PERMISSION: sales order not accessible';
    end if;
  end if;

  -- Link MISA của bản xem trước hết hạn cùng dòng → dòng hết hạn coi như không có.
  return query
  select p.viewer_ref, p.status, p.failure_code
  from einvoice.invoice_previews p
  where p.tenant_id = p_tenant_id
    and p.sales_order_id = p_sales_order_id
    and p.expires_at > now();
end;
$$;

drop function if exists einvoice.store_preview_result(uuid, uuid, text, jsonb, text);

create or replace function einvoice.store_preview_result(
  p_tenant_id uuid,
  p_sales_order_id uuid,
  p_request_id uuid,
  p_status text,
  p_viewer_ref text default null,
  p_failure_code text default null,
  p_failure_message text default null,
  p_failure_source text default null
) returns table(updated boolean) language plpgsql security definer set search_path = einvoice, public as $$
begin
  -- Worker-only writeback: reject non-service roles.
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: store_preview_result is service-role only';
  end if;

  -- Chỉ yêu cầu hiện hành và chưa có kết quả: kết quả muộn của yêu cầu cũ,
  -- hay lần ghi thứ hai của cùng yêu cầu, trả updated = false.
  update einvoice.invoice_previews p
  set
    status = p_status,
    viewer_ref = p_viewer_ref,
    failure_code = p_failure_code,
    failure_message = p_failure_message,
    failure_source = p_failure_source,
    completed_at = now()
  where p.tenant_id = p_tenant_id
    and p.sales_order_id = p_sales_order_id
    and p.request_id = p_request_id
    and p.status = 'PENDING';

  return query select found;
end;
$$;

revoke all on function einvoice.build_canonical_invoice(uuid, uuid, text, jsonb, jsonb) from public, anon;
grant execute on function einvoice.build_canonical_invoice(uuid, uuid, text, jsonb, jsonb) to authenticated, service_role;

revoke all on function einvoice.get_issuance_readiness(uuid, uuid, uuid) from public, anon;
grant execute on function einvoice.get_issuance_readiness(uuid, uuid, uuid) to authenticated, service_role;

revoke all on function einvoice.complete_buyer_invoice_data(uuid, uuid, uuid, int, jsonb, jsonb) from public, anon;
grant execute on function einvoice.complete_buyer_invoice_data(uuid, uuid, uuid, int, jsonb, jsonb) to authenticated, service_role;

revoke all on function einvoice._effective_buyer_snapshot(uuid, uuid, jsonb) from public, anon, authenticated;

revoke all on function einvoice.request_invoice_preview(uuid, uuid, uuid, int) from public, anon;
grant execute on function einvoice.request_invoice_preview(uuid, uuid, uuid, int) to authenticated, service_role;

revoke all on function einvoice.get_invoice_preview(uuid, uuid, uuid) from public, anon;
grant execute on function einvoice.get_invoice_preview(uuid, uuid, uuid) to authenticated, service_role;

revoke all on function einvoice.store_preview_result(uuid, uuid, uuid, text, text, text, text, text) from public, anon, authenticated;
grant execute on function einvoice.store_preview_result(uuid, uuid, uuid, text, text, text, text, text) to service_role;
