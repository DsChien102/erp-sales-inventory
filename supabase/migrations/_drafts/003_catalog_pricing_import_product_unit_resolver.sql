-- Title: Catalog product unit resolver for Pricing import
-- Kind: patch
-- Intent: pricing_customer_price_rule_import_s8
-- Context: TH-04 EP02 S8 — provider-owned product reference resolution
-- Touches: _resolve_product_unit_for_pricing_import
-- Safety: internal security-definer function; no client execute grant
-- Depends on: 20260713001_catalog_patch_price_band_vat_effective.sql

create or replace function catalog._resolve_product_unit_for_pricing_import(
  p_tenant_id uuid,
  p_product_reference_id text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = catalog, pg_temp
as $$
declare
  v_reference text := btrim(p_product_reference_id);
  v_product record;
  v_base_units jsonb := '[]'::jsonb;
  v_unit_count integer := 0;
begin
  if v_reference is null or v_reference = '' then
    return jsonb_build_object('resolution', 'not_found');
  end if;

  select
    p.id as product_id,
    p.name as product_name,
    p.reference_id as product_reference_id,
    p.sku,
    p.business_status::text as product_status
  into v_product
  from catalog.products p
  where p.tenant_id = p_tenant_id
    and p.reference_id = v_reference
    and p.business_status = 'active'::catalog.product_business_status;

  if not found then
    return jsonb_build_object('resolution', 'not_found');
  end if;

  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'product_id', p.id,
          'product_name', p.name,
          'product_reference_id', p.reference_id,
          'sku', p.sku,
          'product_unit_id', pu.id,
          'unit_name', pu.unit_name,
          'sellable_status', case
            when pu.is_active then 'active' else 'invalid'
          end,
          'currency_code', coalesce(bp.currency, 'VND'),
          'list_price_minor', case
            when pb.list_price_before_vat is null then null
            when mod(pb.list_price_before_vat, 1) = 0
              then pb.list_price_before_vat::bigint
            else null
          end,
          'floor_price_minor', case
            when pb.floor_price_before_vat is null then null
            when mod(pb.floor_price_before_vat, 1) = 0
              then pb.floor_price_before_vat::bigint
            else null
          end,
          'minor_units_valid',
            (pb.list_price_before_vat is null
              or mod(pb.list_price_before_vat, 1) = 0)
            and (pb.floor_price_before_vat is null
              or mod(pb.floor_price_before_vat, 1) = 0),
          'is_base_unit', pu.is_base_unit
        )
        order by pu.id
      ),
      '[]'::jsonb
    ),
    count(distinct pu.id)
  into v_base_units, v_unit_count
  from catalog.product_units pu
  join catalog.products p
    on p.tenant_id = pu.tenant_id
   and p.id = pu.product_id
  left join lateral (
    select
      active_band.list_price_before_vat,
      active_band.floor_price_before_vat
    from catalog.product_unit_price_bands active_band
    where active_band.tenant_id = p.tenant_id
      and active_band.product_id = p.id
      and active_band.product_unit_id = pu.id
      and active_band.status = 'active'
      and active_band.effective_from <= now()
      and (active_band.effective_to is null or active_band.effective_to > now())
    order by active_band.effective_from desc, active_band.id desc
    limit 1
  ) pb on true
  left join catalog.product_base_price_profiles bp
    on bp.tenant_id = p.tenant_id
   and bp.product_id = p.id
  where pu.tenant_id = p_tenant_id
    and pu.product_id = v_product.product_id
    and pu.is_active = true
    and pu.is_base_unit = true;

  if v_unit_count = 0 then
    return jsonb_build_object('resolution', 'not_found');
  end if;

  if v_unit_count > 1 then
    return jsonb_build_object('resolution', 'ambiguous');
  end if;

  return jsonb_build_object(
    'resolution', 'resolved',
    'product_unit', v_base_units -> 0
  );
end;
$$;

revoke all on function catalog._resolve_product_unit_for_pricing_import(uuid, text)
  from public, anon, authenticated, service_role;
