-- EPIC-02/US-03: product readiness facts RPC for GetProductReadinessQuery.
-- Context: docs/themes/TH-02-product-pricing/harness/07-api-contracts.md
-- Foundation MVP: stock_mode = basic, base_price_mode = manual (hardcoded).
-- TODO EPIC-05/US-01: join catalog.product_stock_profiles for stock_mode + has_stock
-- TODO EPIC-06/US-01: join catalog.product_base_price_profiles for base_price_mode + has_base_price
-- TODO EPIC-06/US-03: join product_unit_price_bands for has_price_band
-- TODO EPIC-03: compute has_required_custom_fields from custom field config

create or replace function catalog.get_product_readiness(
  p_tenant_id uuid,
  p_product_id uuid
)
returns table (
  product_id uuid,
  product_name text,
  has_base_unit boolean,
  has_images boolean,
  has_stock boolean,
  has_base_price boolean,
  has_price_band boolean,
  has_required_custom_fields boolean,
  stock_mode text,
  base_price_mode text
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_detail') then
    raise exception 'permission denied: catalog.product.view_detail';
  end if;

  return query
  select
    p.id as product_id,
    p.name as product_name,
    exists (
      select 1
      from catalog.product_units u
      where u.product_id = p.id
        and u.tenant_id = p_tenant_id
        and u.is_base_unit = true
    ) as has_base_unit,
    exists (
      select 1
      from catalog.product_images i
      where i.product_id = p.id
        and i.tenant_id = p_tenant_id
    ) as has_images,
    false as has_stock,
    false as has_base_price,
    false as has_price_band,
    true as has_required_custom_fields,
    'basic'::text as stock_mode,
    'manual'::text as base_price_mode
  from catalog.products p
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id
    and p.deleted_at is null;
end;
$$;

revoke all on function catalog.get_product_readiness(uuid, uuid)
  from public, anon;
grant execute on function catalog.get_product_readiness(uuid, uuid)
  to authenticated, service_role;
