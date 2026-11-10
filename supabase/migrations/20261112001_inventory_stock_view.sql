-- Title: inventory stock overview and detail read RPCs
-- Kind: schema
-- Intent: inventory_stock_view
-- Context: TH-07 / BJ-01; PLAN T7-G5-2
-- Touches: list_stock_overview, get_stock_detail
-- Safety: one-shot ; read-only RPCs
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy

create schema if not exists inventory;

-- 1. list_stock_overview RPC
create or replace function inventory.list_stock_overview(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_warehouse_id uuid;
  v_warehouse_name text;
  v_products jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  select display_name
  into v_warehouse_name
  from inventory.warehouses
  where id = v_warehouse_id
    and tenant_id = p_tenant_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', p.id,
        'name', p.name,
        'code', coalesce(p.sku, ''),
        'barcode', coalesce(p.barcode, ''),
        'base_uom', catalog._product_base_unit_name(p_tenant_id, p.id),
        'is_lot_tracked', (p.tracking_mode = 'lot'),
        'physical', sr.physical,
        'available', sr.available,
        'has_expired', sr.has_expired,
        'has_near_expiry', sr.has_near_expiry,
        'reorder_threshold', psp.reorder_threshold
      ) order by p.name asc
    ),
    '[]'::jsonb
  )
  into v_products
  from catalog.products p
  join inventory._product_stock_rows(p_tenant_id) sr on sr.product_id = p.id
  left join inventory.product_stock_policies psp
    on psp.tenant_id = p_tenant_id
   and psp.product_id = p.id
  where p.tenant_id = p_tenant_id
    and p.deleted_at is null
    and p.business_status = 'active';

  return jsonb_build_object(
    'as_of', now(),
    'warehouse_name', coalesce(v_warehouse_name, ''),
    'products', v_products
  );
end;
$$;

grant execute on function inventory.list_stock_overview(uuid) to authenticated;

-- 2. get_stock_detail RPC
create or replace function inventory.get_stock_detail(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_warehouse_id uuid;
  v_warehouse_name text;
  v_prod record;
  v_sr record;
  v_psp record;
  v_physical numeric := 0;
  v_available numeric := 0;
  v_expired_qty numeric := 0;
  v_today date;
  v_near_days int;
  v_lots jsonb := '[]'::jsonb;
  v_latest_movement jsonb := null;
  v_financial_masked boolean;
  v_method text;
  v_pc record;
  v_cost jsonb := null;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  select display_name
  into v_warehouse_name
  from inventory.warehouses
  where id = v_warehouse_id
    and tenant_id = p_tenant_id;

  select id, name, sku, tracking_mode
  into v_prod
  from catalog.products
  where id = p_product_id
    and tenant_id = p_tenant_id
    and deleted_at is null;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại hoặc không thuộc cửa hàng.');
  end if;

  select physical, available
  into v_sr
  from inventory._product_stock_rows(p_tenant_id)
  where product_id = p_product_id;

  if found then
    v_physical := coalesce(v_sr.physical, 0);
    v_available := coalesce(v_sr.available, 0);
    v_expired_qty := v_physical - v_available;
  end if;

  select reorder_threshold, target_level
  into v_psp
  from inventory.product_stock_policies
  where tenant_id = p_tenant_id
    and product_id = p_product_id;

  if v_prod.tracking_mode = 'lot' then
    v_today := inventory._today();
    v_near_days := inventory._near_expiry_days(p_tenant_id, p_product_id);

    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'lot_id', lr.lot_id,
          'lot_code', lr.lot_code,
          'expiry_date', lr.expiry_date,
          'expiry_precision', lr.expiry_precision,
          'physical', lr.physical,
          'is_expired', lr.is_expired,
          'is_near_expiry', lr.is_near_expiry,
          'days_to_expiry', lr.days_to_expiry
        ) order by lr.expiry_end asc nulls last, lr.lot_code asc
      ),
      '[]'::jsonb
    )
    into v_lots
    from (
      select
        l.id as lot_id,
        l.lot_code,
        l.expiry_date,
        l.expiry_precision,
        sb.physical_quantity as physical,
        inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) as expiry_end,
        case
          when inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) is not null
           and inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) < v_today
            then true
          else false
        end as is_expired,
        case
          when inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) is not null
           and inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) >= v_today
           and v_near_days is not null
           and (inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) - v_today) <= v_near_days
            then true
          else false
        end as is_near_expiry,
        case
          when inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) is not null
            then (inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) - v_today)::int
          else null
        end as days_to_expiry
      from inventory.stock_balances sb
      join inventory.lots l
        on l.tenant_id = sb.tenant_id
       and l.id = sb.lot_key
      where sb.tenant_id = p_tenant_id
        and sb.warehouse_id = v_warehouse_id
        and sb.product_id = p_product_id
        and sb.physical_quantity > 0
    ) lr;
  end if;

  select jsonb_build_object(
    'movement_kind', sm.movement_kind,
    'intent_type', sm.intent_type,
    'intent_id', sm.intent_id,
    'quantity_delta', sm.quantity_delta,
    'business_date', sm.business_date
  )
  into v_latest_movement
  from inventory.stock_movements sm
  where sm.tenant_id = p_tenant_id
    and sm.warehouse_id = v_warehouse_id
    and sm.product_id = p_product_id
  order by sm.ledger_sequence desc
  limit 1;

  if v_is_owner then
    v_financial_masked := false;
    v_method := inventory._cost_method(p_tenant_id);

    select official_unit_cost, moving_avg_cost, ledger_value_vnd
    into v_pc
    from inventory.product_costs
    where tenant_id = p_tenant_id
      and product_id = p_product_id;

    if found then
      v_cost := jsonb_build_object(
        'method', v_method,
        'official_unit_cost', v_pc.official_unit_cost,
        'moving_avg_cost', v_pc.moving_avg_cost,
        'ledger_value_vnd', coalesce(v_pc.ledger_value_vnd, 0)
      );
    else
      v_cost := jsonb_build_object(
        'method', v_method,
        'official_unit_cost', null,
        'moving_avg_cost', null,
        'ledger_value_vnd', 0
      );
    end if;
  else
    v_financial_masked := true;
    v_cost := null;
  end if;

  return jsonb_build_object(
    'as_of', now(),
    'warehouse_name', coalesce(v_warehouse_name, ''),
    'is_owner', v_is_owner,
    'financial_masked', v_financial_masked,
    'product', jsonb_build_object(
      'product_id', v_prod.id,
      'name', v_prod.name,
      'code', coalesce(v_prod.sku, ''),
      'base_uom', catalog._product_base_unit_name(p_tenant_id, v_prod.id),
      'is_lot_tracked', (v_prod.tracking_mode = 'lot')
    ),
    'physical', v_physical,
    'available', v_available,
    'expired_quantity', v_expired_qty,
    'reorder_threshold', v_psp.reorder_threshold,
    'target_level', v_psp.target_level,
    'lots', v_lots,
    'latest_movement', v_latest_movement,
    'cost', v_cost
  );
end;
$$;

grant execute on function inventory.get_stock_detail(uuid, uuid) to authenticated;

