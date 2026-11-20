-- Title: inventory patch issue-for-sale allocation key per product
-- Kind: patch
-- Intent: inventory_issue_for_sale_alloc_key
-- Context: AI-3 (seed dữ liệu mô phỏng phát hiện): đơn nhiều dòng hàng không quản lý lô bị chặn nhầm INSUFFICIENT_STOCK
-- Touches: _issue_for_sale
-- Safety: idempotent ; low (create or replace, chỉ đổi khoá cấp phát trong bước chọn lô FEFO)
-- Depends on: 20261115001_inventory_sales_link
--
-- Lỗi: v_allocated khoá theo lot_key; mọi sản phẩm không quản lý lô có chung lot_key = 00000000-…
-- nên số đã cấp cho sản phẩm trước trong cùng đơn bị trừ vào tồn sản phẩm sau.
-- Sửa: khoá = product_id || ':' || lot_key. Phần còn lại giữ nguyên.

create or replace function inventory._issue_for_sale(
  p_tenant_id    uuid,
  p_store_id     uuid,
  p_intent_type  text,
  p_intent_id    uuid,
  p_lines        jsonb,
  p_created_by   uuid default auth.uid()
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_warehouse_id uuid;
  v_prod_id uuid;
  v_shortages jsonb;
  v_shortage_msg text;
  v_today date := inventory._today();
  v_line_elem jsonb;
  v_line_id uuid;
  v_line_need numeric;
  v_lot_rec record;
  v_cand_avail numeric;
  v_take numeric;
  v_allocated jsonb := '{}'::jsonb;
  v_alloc_key text;
  v_movement_elements jsonb := '[]'::jsonb;
  v_post_res jsonb;
  v_out_lines jsonb := '[]'::jsonb;
begin
  if p_lines is null or jsonb_array_length(p_lines) = 0 then
    return jsonb_build_object('lines', '[]'::jsonb, 'stock_changes', '[]'::jsonb);
  end if;

  v_warehouse_id := inventory._warehouse_for_store(p_tenant_id, p_store_id);

  -- (1) Advisory locks: ordered by product_id asc, strictly BEFORE reading any stock balances/lots
  for v_prod_id in (
    select distinct (elem->>'product_id')::uuid as pid
    from jsonb_array_elements(p_lines) elem
    where (elem->>'product_id') is not null
    order by pid asc
  ) loop
    perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext(v_prod_id::text));
  end loop;

  -- (2) Check shortages
  v_shortages := inventory._stock_shortages(p_tenant_id, p_lines);
  if jsonb_array_length(v_shortages) > 0 then
    select string_agg(s->>'message', E'\n') into v_shortage_msg
    from jsonb_array_elements(v_shortages) s;
    perform inventory._raise('INSUFFICIENT_STOCK', v_shortage_msg);
  end if;

  -- (3) Choose lots FEFO
  for v_line_elem in select * from jsonb_array_elements(p_lines) loop
    v_line_id := (v_line_elem->>'line_id')::uuid;
    v_prod_id := (v_line_elem->>'product_id')::uuid;
    v_line_need := (v_line_elem->>'base_qty')::numeric;

    for v_lot_rec in
      select
        sb.lot_key,
        case when p.tracking_mode = 'lot' and sb.lot_key <> '00000000-0000-0000-0000-000000000000'::uuid then sb.lot_key else null end as lot_id,
        sb.physical_quantity
      from inventory.stock_balances sb
      join catalog.products p on p.id = sb.product_id and p.tenant_id = sb.tenant_id
      left join inventory.lots l on l.id = sb.lot_key and l.tenant_id = sb.tenant_id
      where sb.tenant_id = p_tenant_id
        and sb.warehouse_id = v_warehouse_id
        and sb.product_id = v_prod_id
        and sb.physical_quantity > 0
        and (
          p.tracking_mode <> 'lot'
          or inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) is null
          or inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) >= v_today
        )
      order by
        case when p.tracking_mode = 'lot' then inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) else null end asc nulls last,
        case when p.tracking_mode = 'lot' then l.created_at else p.created_at end asc,
        sb.lot_key asc
    loop
      if v_line_need <= 0 then exit; end if;

      -- khoá cấp phát theo sản phẩm + lô: hàng không quản lý lô cùng lot_key (uuid 0) nên khoá chỉ theo lô sẽ trừ chéo giữa các sản phẩm
      v_alloc_key := v_prod_id::text || ':' || v_lot_rec.lot_key::text;

      v_cand_avail := v_lot_rec.physical_quantity - coalesce((v_allocated->>v_alloc_key)::numeric, 0);

      if v_cand_avail > 0 then
        v_take := least(v_line_need, v_cand_avail);

        v_movement_elements := v_movement_elements || jsonb_build_object(
          'line_id', v_line_id,
          'product_id', v_prod_id,
          'lot_id', v_lot_rec.lot_id,
          'quantity_delta', -v_take,
          'movement_kind', 'SALE'
        );

        v_allocated := jsonb_set(
          v_allocated,
          array[v_alloc_key],
          to_jsonb(coalesce((v_allocated->>v_alloc_key)::numeric, 0) + v_take)
        );

        v_line_need := v_line_need - v_take;
      end if;
    end loop;

    if v_line_need > 0 then
      perform inventory._raise('INSUFFICIENT_STOCK', 'Không đủ tồn kho khả dụng để xuất.');
    end if;
  end loop;

  -- (4) Post movements
  v_post_res := inventory._post_movements(
    p_tenant_id,
    v_warehouse_id,
    p_intent_type,
    p_intent_id,
    v_today,
    v_movement_elements,
    p_created_by
  );

  -- (5) Consolidated output
  with post_lines as (
    select
      (elem->>'line_id')::uuid as line_id,
      (elem->>'amount_vnd')::bigint as amount_vnd,
      (elem->>'unit_cost')::numeric as unit_cost,
      (elem->>'cost_version_id')::uuid as cost_version_id,
      (elem->>'is_provisional')::boolean as is_provisional,
      ord
    from jsonb_array_elements(v_post_res->'lines') with ordinality as t(elem, ord)
  ),
  first_per_line as (
    select distinct on (line_id)
      line_id, unit_cost, cost_version_id, is_provisional
    from post_lines
    order by line_id, ord asc
  ),
  summed_per_line as (
    select
      line_id,
      - sum(amount_vnd) as cogs_amount_vnd
    from post_lines
    group by line_id
  )
  select jsonb_agg(jsonb_build_object(
    'line_id', s.line_id,
    'cogs_amount_vnd', s.cogs_amount_vnd,
    'cogs_unit_cost', f.unit_cost,
    'cost_version_id', f.cost_version_id,
    'is_provisional', f.is_provisional
  ))
  into v_out_lines
  from summed_per_line s
  join first_per_line f on f.line_id = s.line_id;

  return jsonb_build_object(
    'lines', coalesce(v_out_lines, '[]'::jsonb),
    'stock_changes', coalesce(v_post_res->'stock_changes', '[]'::jsonb)
  );
end;
$$;

revoke all on function inventory._issue_for_sale(uuid, uuid, text, uuid, jsonb, uuid) from public, anon, authenticated;
