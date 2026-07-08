-- EPIC-07/US-04: Product change history read (paginated + category filter).
-- Context: docs/themes/TH-02-product-pricing/harness/07-api-contracts.md (slice #20)
-- Depends on: 01_catalog_guided_create.sql (product_change_history table)
-- Safety: idempotent draft only

create or replace function catalog._product_change_history_category(p_action text)
returns text
language sql
immutable
as $$
  select case lower(trim(p_action))
    when 'created' then 'profile'
    when 'update_product_profile' then 'profile'
    when 'product_profile_updated' then 'profile'
    when 'update_product_images' then 'images'
    when 'product_images_updated' then 'images'
    when 'add_product_unit' then 'units'
    when 'deactivate_product_unit' then 'units'
    when 'reactivate_product_unit' then 'units'
    when 'set_product_base_unit' then 'units'
    when 'set_initial_stock' then 'stock'
    when 'adjust_basic_stock' then 'stock'
    when 'set_manual_base_price' then 'pricing'
    when 'apply_store_price_rule' then 'pricing'
    when 'set_product_unit_price_band' then 'pricing'
    when 'set_initial_price_band' then 'pricing'
    when 'upsert_custom_field_values' then 'custom_fields'
    when 'custom_field_values_updated' then 'custom_fields'
    when 'product_status_changed' then 'status'
    when 'deactivate_product' then 'status'
    when 'reactivate_product' then 'status'
    when 'product_soft_deleted' then 'lifecycle'
    when 'product_restored' then 'lifecycle'
    else 'other'
  end;
$$;

create or replace function catalog.get_product_change_history(
  p_tenant_id uuid,
  p_product_id uuid,
  p_limit int default 50,
  p_offset int default 0,
  p_categories text[] default null
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_can_view_pricing boolean;
  v_can_view_stock boolean;
  v_limit int;
  v_offset int;
  v_total_count int;
  v_items jsonb;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.view_history') then
    raise exception 'permission denied: catalog.product.view_history';
  end if;

  if not exists (
    select 1
    from catalog.products p
    where p.id = p_product_id
      and p.tenant_id = p_tenant_id
  ) then
    raise exception 'product not found';
  end if;

  v_limit := greatest(coalesce(p_limit, 50), 1);
  v_offset := greatest(coalesce(p_offset, 0), 0);

  if v_limit > 100 then
    raise exception 'validation_exception: Limit must be between 1 and 100.';
  end if;

  v_can_view_pricing := iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing');
  v_can_view_stock := iam.has_permission(p_tenant_id, 'catalog.product.manage_stock');

  select count(*)::int
  into v_total_count
  from catalog.product_change_history h
  where h.tenant_id = p_tenant_id
    and h.product_id = p_product_id
    and (
      p_categories is null
      or array_length(p_categories, 1) is null
      or catalog._product_change_history_category(h.action) = any (p_categories)
    );

  select coalesce(jsonb_agg(row_to_json(entry.*) order by entry.occurred_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      h.id,
      h.created_at as occurred_at,
      left(h.actor_id::text, 8) as actor_display_name,
      h.action as change_type,
      case
        when catalog._product_change_history_category(h.action) = 'pricing'
          and not v_can_view_pricing then 'Thay đổi giá (ẩn)'
        when catalog._product_change_history_category(h.action) = 'stock'
          and not v_can_view_stock then 'Thay đổi tồn kho (ẩn)'
        else coalesce(h.payload ->> 'summary', h.action)
      end as summary,
      case
        when catalog._product_change_history_category(h.action) = 'pricing'
          and not v_can_view_pricing then null
        when catalog._product_change_history_category(h.action) = 'stock'
          and not v_can_view_stock then null
        else coalesce(h.payload ->> 'value_before', h.payload #>> '{before,name}')
      end as value_before,
      case
        when catalog._product_change_history_category(h.action) = 'pricing'
          and not v_can_view_pricing then null
        when catalog._product_change_history_category(h.action) = 'stock'
          and not v_can_view_stock then null
        else coalesce(h.payload ->> 'value_after', h.payload #>> '{after,name}')
      end as value_after,
      catalog._product_change_history_category(h.action) as change_category,
      coalesce(h.payload ->> 'source', 'user') as source,
      (
        (catalog._product_change_history_category(h.action) = 'pricing' and not v_can_view_pricing)
        or (catalog._product_change_history_category(h.action) = 'stock' and not v_can_view_stock)
      ) as is_sensitive_masked
    from catalog.product_change_history h
    where h.tenant_id = p_tenant_id
      and h.product_id = p_product_id
      and (
        p_categories is null
        or array_length(p_categories, 1) is null
        or catalog._product_change_history_category(h.action) = any (p_categories)
      )
    order by h.created_at desc
    limit v_limit
    offset v_offset
  ) entry;

  return jsonb_build_object(
    'items', v_items,
    'total_count', v_total_count
  );
end;
$$;

revoke all on function catalog.get_product_change_history(uuid, uuid, int, int, text[])
  from public, anon;
grant execute on function catalog.get_product_change_history(uuid, uuid, int, int, text[])
  to authenticated, service_role;
