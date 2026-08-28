-- Title: einvoice S2a — readiness/preview/completion RPCs
-- Kind: patch
-- Intent: S2a read+command RPCs (get_issuance_readiness, complete_buyer_invoice_data, request_invoice_preview, get_invoice_preview, store_preview_result)
-- Context: TH-08 EP-02/US-01. NOTE: sales.* source not available — see TODO markers.
-- Touches: einvoice.get_issuance_readiness, einvoice.complete_buyer_invoice_data, einvoice.request_invoice_preview, einvoice.get_invoice_preview, einvoice.store_preview_result
-- Safety: security definer, tenant scoped, raises stable CODE errors
-- Depends on: 005_einvoice_s2a_schema.sql, 002_einvoice_s1_install_module_messaging.sql

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
) language plpgsql security definer set search_path = einvoice, iam, public as $$
declare
  v_provider_status einvoice.provider_connection_status;
  v_capabilities jsonb;
  v_config_ready boolean := false;
  v_provider_connected boolean := false;
  v_supports_preview boolean := false;
  v_warnings jsonb := '[]'::jsonb;
  v_completion_status text := null; -- no completion row → settled (mapped to 'locked' below)
  v_buyer_name text := '';
  v_buyer_tax_code text := null;
  v_buyer_email text := null;
  v_buyer_address text := null;
  v_buyer_type text := 'retail';
begin
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

  -- 3. Check buyer completion if exists
  select bc.status, (bc.resolved_values ->> 'name'), (bc.resolved_values ->> 'taxCode'),
         (bc.resolved_values ->> 'email'), (bc.resolved_values ->> 'address')
  into v_completion_status, v_buyer_name, v_buyer_tax_code, v_buyer_email, v_buyer_address
  from einvoice.buyer_invoice_completions bc
  where bc.tenant_id = p_tenant_id and bc.sales_order_id = p_sales_order_id
  order by bc.created_at desc
  limit 1;

  -- Fallback defaults when not completed (TODO: Theme 05 sales.* join)
  if v_buyer_name is null or v_buyer_name = '' then
    v_buyer_name := 'Người mua hàng';
  end if;

  return query select
    true as order_completed,               -- TODO(Theme05): check sales.orders.status = 'completed'
    false as has_electronic_invoice,       -- TODO(Theme05): check existing invoice for order
    false as has_active_operation,         -- TODO(Theme05): check active issuance attempt
    v_config_ready,
    v_provider_connected,
    v_supports_preview,
    v_buyer_type,
    v_buyer_name,
    v_buyer_email,
    v_buyer_tax_code,
    v_buyer_address,
    -- No completion row → buyer data settled from snapshot → 'locked' (§4.1.2).
    coalesce(v_completion_status, 'locked'),
    true as commercial_data_mappable,  -- TODO(Theme05): map sales.* commercial data → CanonicalInvoiceModel (FR-06/EC-04)
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
  v_partner_id uuid := gen_random_uuid(); -- TODO(Theme05): from sales_order.buyer_partner_id
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
    updated_at
  ) values (
    p_tenant_id,
    p_sales_order_id,
    v_version_text,
    v_partner_id,
    'locked',
    p_eligible_fields,
    p_resolved_values,
    now(),
    now()
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

create or replace function einvoice.request_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid,
  p_expected_order_version int
) returns table(preview_request_id uuid) as $$
declare
  v_id uuid;
begin
  -- Version-bound (BR-13/EC-01): supersede any prior active preview for this order
  -- so a poll never surfaces a stale-version preview after a new request.
  update einvoice.provider_interaction_records
  set status = 'superseded', updated_at = now()
  where tenant_id = p_tenant_id
    and sales_order_id = p_sales_order_id
    and interaction_type = 'preview'
    and status in ('pending', 'ready');

  -- Preview handoff record on the shared technical table (NOT a business entity).
  -- Short-lived (NFR-06): expire so stale previews auto-drop from get_invoice_preview.
  insert into einvoice.provider_interaction_records(
    tenant_id, interaction_type, sales_order_id, correlation_id, order_version,
    status, expires_at)
  values (
    p_tenant_id, 'preview', p_sales_order_id, gen_random_uuid(),
    p_expected_order_version::text, 'pending', now() + interval '15 minutes')
  returning id into v_id;

  perform einvoice.enqueue_internal_command(
    p_tenant_id,
    'einvoice.preview_invoice',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'sales_order_id', p_sales_order_id,
      'preview_request_id', v_id,
      'order_version', p_expected_order_version,
      -- TODO(Theme05): build canonical invoice from sales.* + buyer snapshot.
      'canonical_invoice', '{}'::jsonb
    ),
    p_source_event_id => v_id
  );
  return query select v_id;
end;
$$ language plpgsql security definer set search_path = einvoice, public;

create or replace function einvoice.get_invoice_preview(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns table(
  viewer_ref text,
  preview_payload jsonb,
  status text
) language sql security definer set search_path = einvoice, public as $$
  select
    pir.viewer_ref,
    pir.response_summary as preview_payload,
    pir.status
  from einvoice.provider_interaction_records pir
  where pir.tenant_id = p_tenant_id
    and pir.sales_order_id = p_sales_order_id
    and pir.interaction_type = 'preview'
    and pir.status in ('pending', 'ready')          -- drop superseded/failed
    and (pir.expires_at is null or pir.expires_at > now())  -- drop expired (NFR-06)
  order by pir.created_at desc
  limit 1;
$$;

create or replace function einvoice.store_preview_result(
  p_tenant_id uuid,
  p_preview_request_id uuid,
  p_viewer_ref text default null,
  p_preview_payload jsonb default null,
  p_status text default 'ready'
) returns table(updated boolean) language plpgsql security definer set search_path = einvoice, public as $$
begin
  -- Worker-only writeback (mirror read_provider_credentials): reject non-service roles.
  if current_setting('request.jwt.claim.role', true) is distinct from 'service_role' then
    raise exception 'NO_PERMISSION: store_preview_result is service-role only';
  end if;

  update einvoice.provider_interaction_records
  set
    viewer_ref = p_viewer_ref,
    response_summary = p_preview_payload,
    status = coalesce(p_status, 'ready'),
    updated_at = now()
  where id = p_preview_request_id and tenant_id = p_tenant_id;

  return query select found;
end;
$$;
