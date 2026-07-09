-- Fix list_product_unit_price_bands: expose base_price + explicit price column aliases.
-- Context: price bands list UI (Giá cơ sở / niêm yết / sàn).
-- Note: return type changed (added base_price) — must drop before recreate.
-- Apply: supabase db query --file supabase/migrations/_drafts/02_catalog_list_price_bands_base_price.sql

drop function if exists catalog.list_product_unit_price_bands(uuid, uuid);

create or replace function catalog.list_product_unit_price_bands(
  p_tenant_id uuid,
  p_product_id uuid
)
returns table (
  product_id uuid,
  base_unit_name text,
  currency text,
  base_price numeric,
  product_unit_id uuid,
  unit_name text,
  is_base_unit boolean,
  is_active boolean,
  list_price numeric,
  floor_price numeric,
  source_type text,
  store_price_rule_name text,
  is_custom_override boolean
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_base_unit_name text;
  v_currency text;
  v_base_price numeric;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_detail') then
    raise exception 'permission denied: catalog.product.view_detail';
  end if;

  if not exists (
    select 1
    from catalog.products
    where id = p_product_id
      and tenant_id = p_tenant_id
      and deleted_at is null
  ) then
    raise exception 'product not found';
  end if;

  perform catalog._ensure_product_has_base_unit(p_tenant_id, p_product_id);

  select pu.unit_name
  into v_base_unit_name
  from catalog.product_units pu
  where pu.product_id = p_product_id
    and pu.tenant_id = p_tenant_id
    and pu.is_base_unit = true
  limit 1;

  select coalesce(bp.currency, 'VND'), bp.base_price_amount
  into v_currency, v_base_price
  from catalog.product_base_price_profiles bp
  where bp.product_id = p_product_id
    and bp.tenant_id = p_tenant_id
  limit 1;

  v_currency := coalesce(v_currency, 'VND');

  return query
  select
    p_product_id,
    v_base_unit_name,
    v_currency,
    v_base_price,
    pu.id,
    pu.unit_name,
    pu.is_base_unit,
    pu.is_active,
    pb.list_price_amount as list_price,
    pb.floor_price_amount as floor_price,
    pb.source_type,
    sr.name as store_price_rule_name,
    coalesce(pb.is_custom_override, false)
  from catalog.product_units pu
  left join catalog.product_unit_price_bands pb
    on pb.product_unit_id = pu.id
   and pb.product_id = p_product_id
   and pb.tenant_id = p_tenant_id
  left join catalog.store_price_rules sr
    on sr.id = pb.store_price_rule_id
  where pu.product_id = p_product_id
    and pu.tenant_id = p_tenant_id
    and pu.is_active = true
  order by pu.is_base_unit desc, pu.unit_name asc;
end;
$$;

revoke all on function catalog.list_product_unit_price_bands(uuid, uuid) from public, anon;
grant execute on function catalog.list_product_unit_price_bands(uuid, uuid) to authenticated, service_role;
