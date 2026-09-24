-- Title: Sales schema — E-Invoice source snapshot and access gate
-- Kind: patch
-- Intent: sales_einvoice_source_contract
-- Context: TH-08 EP-02 — nguồn đơn hàng Theme 05 thật (fixture đã gỡ)
-- Touches: sales.get_einvoice_source_snapshot, sales.can_access_sales_order
-- Safety: idempotent (create or replace), tenant_id scoped
-- Depends on: 20260830005_sales_rebuild_schema.sql, 20260830001_iam_active_store_context_group_a.sql (iam.can_access_store)

create schema if not exists sales;

create or replace function sales.get_einvoice_source_snapshot(
  p_tenant_id uuid,
  p_sales_order_id uuid
) returns table (
  available boolean,
  source_version text,
  order_completed boolean,
  buyer_partner_id uuid,
  commercial_snapshot jsonb,
  buyer_snapshot jsonb,
  blockers jsonb
)
language plpgsql
security definer
set search_path = sales, public, pg_temp
as $$
declare
  v_order sales.sales_orders%rowtype;
  v_lines jsonb;
begin
  select * into v_order
  from sales.sales_orders
  where tenant_id = p_tenant_id
    and id = p_sales_order_id;

  if not found then
    return query select
      false, null::text, false, null::uuid,
      '{}'::jsonb, '{}'::jsonb,
      jsonb_build_array('ORDER_NOT_FOUND');
    return;
  end if;

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'lineId',           l.id,
      'lineSequence',     l.line_sequence,
      'itemName',         l.product_snapshot ->> 'displayName',
      'itemCode',         coalesce(l.product_snapshot ->> 'sku', ''),
      'unitName',         l.product_unit_snapshot ->> 'unitName',
      'quantityMicros',   l.quantity_micros,
      'unitPriceMinor',   l.unit_price_minor,
      'grossAmountMinor', l.gross_amount_minor,
      'discountMinor',    l.discount_amount_minor,
      'taxAmountMinor',   l.tax_amount_minor,
      'lineTotalMinor',   l.line_total_minor,
      'taxSnapshot',      l.tax_snapshot
    ) order by l.line_sequence
  ), '[]'::jsonb)
  into v_lines
  from sales.sales_order_lines l
  where l.tenant_id = p_tenant_id
    and l.sales_order_id = p_sales_order_id;

  return query select
    true,
    v_order.version::text,
    (v_order.lifecycle_status = 'completed'),
    v_order.customer_partner_id,
    jsonb_build_object(
      'seller', coalesce(v_order.sales_context_snapshot -> 'seller', '{}'::jsonb),
      'lines',  v_lines,
      'totals', jsonb_build_object(
        'subtotalMinor', v_order.subtotal_amount_minor,
        'discountMinor', v_order.discount_amount_minor,
        'taxMinor',      v_order.tax_amount_minor,
        'roundingMinor', v_order.rounding_amount_minor,
        'payableMinor',  v_order.payable_amount_minor
      )
    ),
    jsonb_strip_nulls(jsonb_build_object(
      -- Đơn không gắn khách hàng là bán lẻ. Nói tường minh ở đây thay vì để
      -- tầng trên suy từ việc thiếu khoá: đơn cũ của khách định danh cũng
      -- thiếu buyer_tax_snapshot, suy nhầm sẽ gán họ thành khách lẻ.
      'buyerType',        case
                            when v_order.customer_partner_id is null then 'retail'
                            else v_order.buyer_tax_snapshot ->> 'buyerType'
                          end,
      'buyerLegalName',   coalesce(v_order.buyer_tax_snapshot ->> 'legalName',
                                   v_order.customer_snapshot  ->> 'displayName'),
      'buyerTaxCode',     coalesce(v_order.buyer_tax_snapshot ->> 'taxCode',
                                   v_order.customer_snapshot  ->> 'taxCode'),
      'buyerPhoneNumber', v_order.customer_snapshot ->> 'phoneNumber',
      'buyerEmail',       v_order.buyer_tax_snapshot ->> 'email',
      'buyerAddress',     v_order.buyer_tax_snapshot ->> 'address'
    )),
    case when v_order.lifecycle_status = 'completed'
         then '[]'::jsonb
         else jsonb_build_array('ORDER_NOT_COMPLETED')
    end;
end;
$$;

revoke all on function sales.get_einvoice_source_snapshot(uuid, uuid) from public, anon, authenticated;
grant execute on function sales.get_einvoice_source_snapshot(uuid, uuid) to service_role;

create or replace function sales.can_access_sales_order(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns boolean
language plpgsql
security definer
set search_path = sales, iam, public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_order_store_id uuid;
begin
  -- 1. Auth context và actor phải khớp.
  --    p_actor_id null: `uuid <> NULL` cho ra NULL, `if NULL` không kích hoạt
  --    nên phải kiểm tường minh, nếu không sẽ lọt xuống.
  if v_user_id is null
     or p_actor_id is null
     or v_user_id <> p_actor_id then
    return false;
  end if;

  -- 2. Quyền xem đơn hàng
  if not iam.has_permission(p_tenant_id, 'sales.order.view') then
    return false;
  end if;

  -- 3. Membership còn hoạt động
  --    (trùng một phần với bước 2; giữ cho tường minh)
  if not exists (
    select 1 from iam.memberships
    where tenant_id = p_tenant_id
      and user_id = p_actor_id
      and is_active
      and removed_at is null
  ) then
    return false;
  end if;

  -- 4. Đơn tồn tại trong tenant
  select store_id into v_order_store_id
  from sales.sales_orders
  where tenant_id = p_tenant_id
    and id = p_sales_order_id;

  if not found then
    return false;
  end if;

  -- 5. Store access, khớp sales._assert_sales_actor (iam.can_access_store)
  if not iam.can_access_store(p_tenant_id, v_order_store_id, p_actor_id) then
    return false;
  end if;

  return true;
end;
$$;

revoke all on function sales.can_access_sales_order(uuid, uuid, uuid) from public, anon;
grant execute on function sales.can_access_sales_order(uuid, uuid, uuid) to authenticated, service_role;
