-- Title: einvoice S2a — readiness/preview/completion RPCs
-- Kind: patch
-- Intent: S2a read+command RPCs (get_issuance_readiness, complete_buyer_invoice_data, request_invoice_preview, get_invoice_preview, store_preview_result)
-- Context: TH-08 EP-02/US-01.
-- Touches: einvoice.get_issuance_readiness, einvoice.complete_buyer_invoice_data, einvoice.build_canonical_invoice, einvoice.request_invoice_preview, einvoice.get_invoice_preview, einvoice.store_preview_result
-- Safety: security definer, tenant scoped, raises stable CODE errors
-- Depends on: 005_einvoice_buyer_completion_and_preview_schema.sql, 002_einvoice_install_module_messaging.sql, 005_sales_einvoice_dev_acceptance_source.sql

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
  config_warnings jsonb
) language plpgsql security definer set search_path = einvoice, iam, sales, public as $$
declare
  v_provider_status einvoice.provider_connection_status;
  v_capabilities jsonb;
  v_config_ready boolean := false;
  v_provider_connected boolean := false;
  v_supports_preview boolean := false;
  v_warnings jsonb := '[]'::jsonb;
  v_completion_status text := null;
  v_buyer_name text := '';
  v_buyer_tax_code text := null;
  v_buyer_email text := null;
  v_buyer_address text := null;
  v_buyer_type text := 'retail';
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
  where pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
  limit 1;

  if v_provider_status = 'connected' then
    v_provider_connected := true;
  end if;

  if v_capabilities is not null then
    v_supports_preview := coalesce((v_capabilities ->> 'supports_preview')::boolean, false);
  end if;

  -- 2. Check issuance profile & policy
  if exists (
    select 1 from einvoice.issuance_profiles ip
    where ip.tenant_id = p_tenant_id
      and ip.default_template is not null
      and ip.default_signing is not null
  ) and v_provider_connected then
    v_config_ready := true;
  end if;

  select coalesce(ip.compatibility_warnings, '[]'::jsonb)
  into v_warnings
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id;

  if v_warnings is null then
    v_warnings := '[]'::jsonb;
  end if;

  -- 3. Load sales order source snapshot
  select *
  into v_source
  from sales.get_einvoice_source_snapshot(p_tenant_id, p_sales_order_id);

  -- 4. Check buyer completion if exists
  select bc.status, (bc.resolved_values ->> 'name'), (bc.resolved_values ->> 'taxCode'),
         (bc.resolved_values ->> 'email'), (bc.resolved_values ->> 'address')
  into v_completion_status, v_buyer_name, v_buyer_tax_code, v_buyer_email, v_buyer_address
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id and bc.sales_order_id = p_sales_order_id
  order by bc.created_at desc
  limit 1;

  if (v_buyer_name is null or v_buyer_name = '') and v_source.available then
    v_buyer_name := coalesce(v_source.buyer_snapshot ->> 'buyerLegalName', v_source.buyer_snapshot ->> 'name', 'Người mua hàng');
    v_buyer_tax_code := coalesce(v_buyer_tax_code, v_source.buyer_snapshot ->> 'buyerTaxCode');
    v_buyer_email := coalesce(v_buyer_email, v_source.buyer_snapshot ->> 'buyerEmail');
    v_buyer_address := coalesce(v_buyer_address, v_source.buyer_snapshot ->> 'buyerAddress');
  end if;

  if v_buyer_name is null or v_buyer_name = '' then
    v_buyer_name := 'Người mua hàng';
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
    coalesce(v_completion_status, 'locked'),
    (coalesce(v_source.available, false) and jsonb_array_length(coalesce(v_source.commercial_snapshot -> 'lines', '[]'::jsonb)) > 0),
    v_warnings;
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
) language plpgsql security definer set search_path = einvoice, public as $$
declare
  v_version_text varchar(100) := p_expected_order_version::text;
  v_partner_id uuid := gen_random_uuid();
begin
  insert into einvoice.buyer_invoice_completions (
    tenant_id,
    sales_order_id,
    sales_order_version,
    buyer_partner_id,
    status,
    eligible_fields,
    resolved_values,
    locked_at,
    version
  ) values (
    p_tenant_id,
    p_sales_order_id,
    v_version_text,
    v_partner_id,
    'locked',
    p_eligible_fields,
    p_resolved_values,
    now(),
    1
  )
  on conflict (tenant_id, sales_order_id, sales_order_version) do update set
    status = 'locked',
    eligible_fields = p_eligible_fields,
    resolved_values = p_resolved_values,
    locked_at = now(),
    version = einvoice.buyer_invoice_completions.version + 1,
    updated_at = now();

  return query select true, p_eligible_fields, p_resolved_values;
end;
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
set search_path = einvoice, public
as $$
declare
  v_inv_series text;
  v_lines jsonb;
  v_totals jsonb;
  v_tax_rates jsonb;
  v_buyer_name text;
  v_buyer_address text;
  v_buyer_tax_code text;
  v_buyer_phone text;
  v_buyer_email text;
  v_total_amount numeric;
begin
  -- Resolve invSeries by matching configured profile template to verified connection capability template
  select coalesce(elem ->> 'symbol', elem ->> 'serial')
  into v_inv_series
  from einvoice.provider_connections pc,
       einvoice.issuance_profiles ip,
       jsonb_array_elements(coalesce(pc.capabilities_snapshot -> 'templates', '[]'::jsonb)) as elem
  where pc.tenant_id = p_tenant_id
    and pc.status <> 'disconnected'
    and ip.tenant_id = p_tenant_id
    and (elem ->> 'template_id' = ip.default_template ->> 'template_id'
         or elem ->> 'templateId' = ip.default_template ->> 'template_id')
  limit 1;

  if v_inv_series is null or v_inv_series = '' then
    select coalesce(elem ->> 'symbol', elem ->> 'serial')
    into v_inv_series
    from einvoice.provider_connections pc,
         jsonb_array_elements(coalesce(pc.capabilities_snapshot -> 'templates', '[]'::jsonb)) as elem
  where pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
    limit 1;
  end if;

  if v_inv_series is null or v_inv_series = '' then
    v_inv_series := '1C26TAA';
  end if;

  v_buyer_name := coalesce(p_buyer_snapshot ->> 'buyerLegalName', p_buyer_snapshot ->> 'name', 'Khách hàng cá nhân');
  v_buyer_address := coalesce(p_buyer_snapshot ->> 'buyerAddress', p_buyer_snapshot ->> 'address', 'Việt Nam');
  v_buyer_tax_code := p_buyer_snapshot ->> 'buyerTaxCode';
  v_buyer_phone := coalesce(p_buyer_snapshot ->> 'buyerPhoneNumber', p_buyer_snapshot ->> 'phone');
  v_buyer_email := coalesce(p_buyer_snapshot ->> 'buyerEmail', p_buyer_snapshot ->> 'email');

  v_lines := coalesce(p_commercial_snapshot -> 'lines', '[]'::jsonb);
  v_totals := coalesce(p_commercial_snapshot -> 'totals', '{}'::jsonb);

  if jsonb_array_length(v_lines) = 0 then
    raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
      'details', 'originalInvoiceDetail must contain at least one line item'
    )::text;
  end if;

  v_total_amount := coalesce((v_totals ->> 'totalAmount')::numeric, 0);
  if v_total_amount <= 0 then
    raise exception 'VALIDATION_ERROR: %', jsonb_build_object(
      'details', 'totalAmount must be positive'
    )::text;
  end if;

  v_tax_rates := jsonb_build_array(
    jsonb_build_object(
      'vatRateName', '10%',
      'vatRate', 10,
      'turnover', coalesce((v_totals ->> 'totalAmountWithoutVat')::numeric, (v_totals ->> 'totalSaleAmount')::numeric, 0),
      'vatAmount', coalesce((v_totals ->> 'totalVatAmount')::numeric, 0)
    )
  );

  return jsonb_build_object(
    'modelVersion', '1.0.0',
    'salesOrderId', p_sales_order_id,
    'sourceVersion', p_source_version,
    'invSeries', v_inv_series,
    'invDate', to_char(now() at time zone 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD'),
    'currencyCode', 'VND',
    'exchangeRate', 1,
    'paymentMethodName', 'TM/CK',
    'buyerLegalName', v_buyer_name,
    'buyerAddress', v_buyer_address,
    'buyerTaxCode', v_buyer_tax_code,
    'buyerPhoneNumber', v_buyer_phone,
    'buyerEmail', v_buyer_email,
    'totalSaleAmount', coalesce((v_totals ->> 'totalSaleAmount')::numeric, (v_totals ->> 'totalAmountWithoutVat')::numeric, v_total_amount),
    'totalAmountWithoutVat', coalesce((v_totals ->> 'totalAmountWithoutVat')::numeric, (v_totals ->> 'totalSaleAmount')::numeric, v_total_amount),
    'totalVatAmount', coalesce((v_totals ->> 'totalVatAmount')::numeric, 0),
    'totalAmount', v_total_amount,
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
  v_id uuid;
  v_correlation_id uuid := gen_random_uuid();
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
    and pc.status <> 'disconnected'
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
    v_source.buyer_snapshot,
    v_source.commercial_snapshot
  );

  -- Version-bound (BR-13/EC-01): supersede any prior active preview for this order.
  update einvoice.invoice_preview_operations
  set status = 'SUPERSEDED', updated_at = now()
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
    and status in ('PENDING', 'READY');

  insert into einvoice.invoice_preview_operations (
    tenant_id,
    provider_connection_id,
    sales_order_id,
    correlation_id,
    order_version,
    status,
    preview_payload,
    expires_at
  ) values (
    p_tenant_id,
    v_provider_connection_id,
    p_sales_order_id,
    v_correlation_id,
    p_expected_order_version::text,
    'PENDING',
    v_canonical,
    now() + interval '15 minutes'
  )
  returning id into v_id;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.preview_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', p_sales_order_id,
      'preview_request_id', v_id,
      'order_version', p_expected_order_version,
      'provider_connection_id', v_provider_connection_id,
      'canonical_invoice', v_canonical
    ),
    p_source_event_id => v_id
  );
  return query select v_id;
end;
$$;

create or replace function einvoice.get_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  viewer_ref text,
  preview_payload jsonb,
  status text
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

  return query
  select
    ipo.viewer_ref,
    ipo.preview_payload,
    ipo.status
  from einvoice.invoice_preview_operations ipo
  where ipo.tenant_id = p_tenant_id
    and ipo.sales_order_id = p_sales_order_id
    and ipo.status in ('PENDING', 'READY')
    and ipo.expires_at > now()
  order by ipo.created_at desc
  limit 1;
end;
$$;

create or replace function einvoice.store_preview_result(
  p_tenant_id uuid,
  p_preview_request_id uuid,
  p_viewer_ref text default null,
  p_preview_payload jsonb default null,
  p_status text default 'READY'
) returns table(updated boolean) language plpgsql security definer set search_path = einvoice, public as $$
begin
  -- Worker-only writeback: reject non-service roles.
  if coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role',
    nullif(current_setting('request.jwt.claim.role', true), '')
  ) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: store_preview_result is service-role only';
  end if;

  update einvoice.invoice_preview_operations
  set
    viewer_ref = p_viewer_ref,
    preview_payload = p_preview_payload,
    status = upper(coalesce(p_status, 'READY')),
    updated_at = now()
  where id = p_preview_request_id and tenant_id = p_tenant_id;

  return query select found;
end;
$$;

revoke all on function einvoice.build_canonical_invoice(uuid, uuid, text, jsonb, jsonb) from public, anon;
grant execute on function einvoice.build_canonical_invoice(uuid, uuid, text, jsonb, jsonb) to authenticated, service_role;

revoke all on function einvoice.get_issuance_readiness(uuid, uuid, uuid) from public, anon;
grant execute on function einvoice.get_issuance_readiness(uuid, uuid, uuid) to authenticated, service_role;

revoke all on function einvoice.complete_buyer_invoice_data(uuid, uuid, uuid, int, jsonb, jsonb) from public, anon;
grant execute on function einvoice.complete_buyer_invoice_data(uuid, uuid, uuid, int, jsonb, jsonb) to authenticated, service_role;

revoke all on function einvoice.request_invoice_preview(uuid, uuid, uuid, int) from public, anon;
grant execute on function einvoice.request_invoice_preview(uuid, uuid, uuid, int) to authenticated, service_role;

revoke all on function einvoice.get_invoice_preview(uuid, uuid, uuid) from public, anon;
grant execute on function einvoice.get_invoice_preview(uuid, uuid, uuid) to authenticated, service_role;

revoke all on function einvoice.store_preview_result(uuid, uuid, text, jsonb, text) from public, anon, authenticated;
grant execute on function einvoice.store_preview_result(uuid, uuid, text, jsonb, text) to service_role;
