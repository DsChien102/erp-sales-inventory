-- EPIC-06/US-04: Price band snapshot for Sales/Promotions consumers.
-- Context: docs/themes/TH-02-product-pricing/harness/07-api-contracts.md (slice #19)
-- Depends on: 09_catalog_product_unit_price_band.sql
-- Safety: idempotent draft only

create or replace function catalog.get_product_price_band_snapshot(
  p_tenant_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_item jsonb;
  v_product_id uuid;
  v_product_unit_id uuid;
  v_items jsonb := '[]'::jsonb;
  v_can_view_floor boolean;
  v_row record;
  v_list_price numeric;
  v_floor_price numeric;
  v_list_price_missing boolean;
  v_floor_price_missing boolean;
  v_floor_price_hidden boolean;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view') then
    raise exception 'permission denied: catalog.product.view';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'validation_exception: Items must be a JSON array.';
  end if;

  if jsonb_array_length(p_items) = 0 then
    raise exception 'validation_exception: At least one item is required.';
  end if;

  if jsonb_array_length(p_items) > 100 then
    raise exception 'validation_exception: At most 100 items can be read at once.';
  end if;

  v_can_view_floor := iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing');

  for v_item in
    select value
    from jsonb_array_elements(p_items)
  loop
    if coalesce(v_item ->> 'product_id', '') = '' then
      raise exception 'validation_exception: Product id is required.';
    end if;

    if coalesce(v_item ->> 'product_unit_id', '') = '' then
      raise exception 'validation_exception: Product unit id is required.';
    end if;

    v_product_id := (v_item ->> 'product_id')::uuid;
    v_product_unit_id := (v_item ->> 'product_unit_id')::uuid;

    select
      p.id as product_id,
      pu.id as product_unit_id,
      pu.unit_name,
      coalesce(bp.currency, 'VND') as currency,
      pb.list_price_amount,
      pb.floor_price_amount,
      pu.is_active as is_unit_active,
      p.business_status::text as product_business_status
    into v_row
    from catalog.products p
    join catalog.product_units pu
      on pu.product_id = p.id
     and pu.tenant_id = p.tenant_id
     and pu.id = v_product_unit_id
    left join catalog.product_unit_price_bands pb
      on pb.product_unit_id = pu.id
     and pb.product_id = p.id
     and pb.tenant_id = p.tenant_id
    left join catalog.product_base_price_profiles bp
      on bp.product_id = p.id
     and bp.tenant_id = p.tenant_id
    where p.id = v_product_id
      and p.tenant_id = p_tenant_id
      and p.deleted_at is null;

    if not found then
      raise exception 'product not found';
    end if;

    v_list_price := v_row.list_price_amount;
    v_floor_price := v_row.floor_price_amount;
    v_list_price_missing := v_list_price is null;
    v_floor_price_missing := v_floor_price is null;
    v_floor_price_hidden := not v_can_view_floor;

    if v_floor_price_hidden then
      v_floor_price := null;
    end if;

    v_items := v_items || jsonb_build_array(
      jsonb_build_object(
        'product_id', v_row.product_id,
        'product_unit_id', v_row.product_unit_id,
        'unit_name', v_row.unit_name,
        'currency', v_row.currency,
        'list_price', v_list_price,
        'list_price_missing', v_list_price_missing,
        'floor_price', v_floor_price,
        'floor_price_missing', v_floor_price_missing,
        'floor_price_hidden', v_floor_price_hidden,
        'is_unit_active', coalesce(v_row.is_unit_active, false),
        'product_business_status', v_row.product_business_status
      )
    );
  end loop;

  return jsonb_build_object('items', v_items);
end;
$$;

revoke all on function catalog.get_product_price_band_snapshot(uuid, jsonb)
  from public, anon;
grant execute on function catalog.get_product_price_band_snapshot(uuid, jsonb)
  to authenticated, service_role;
