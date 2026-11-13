-- Title: inventory sales link
-- Kind: schema
-- Intent: inventory_sales_link
-- Context: TH-07 / spec gia von muc 3-4, 9 ca 6; PLAN T7-G5-4
-- Touches: _warehouse_for_store, _stock_shortages, _issue_for_sale, _reversal_kind, _reverse_sale
-- Safety: one-shot ; low lock impact on new helper functions
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Helper: _warehouse_for_store
-- ---------------------------------------------------------------------------

create or replace function inventory._warehouse_for_store(
  p_tenant_id uuid,
  p_store_id  uuid
)
returns uuid
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_warehouse_id uuid;
begin
  select warehouse_id into v_warehouse_id
  from inventory.store_warehouse_assignments
  where tenant_id = p_tenant_id
    and store_id = p_store_id
    and status = 'active'
  limit 1;

  if v_warehouse_id is null then
    perform inventory._raise('CONTEXT_INVALID', 'Cửa hàng chưa được gán kho hoạt động.');
  end if;

  return v_warehouse_id;
end;
$$;

revoke all on function inventory._warehouse_for_store(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Helper: _stock_shortages
-- ---------------------------------------------------------------------------

create or replace function inventory._stock_shortages(
  p_tenant_id uuid,
  p_lines     jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_res jsonb := '[]'::jsonb;
  v_pids uuid[];
  v_rec record;
  v_avail numeric;
  v_pname text;
  v_unit_name text;
  v_rate numeric;
  v_avail_in_unit numeric;
  v_msg text;
begin
  if p_lines is null or jsonb_array_length(p_lines) = 0 then
    return '[]'::jsonb;
  end if;

  select array_agg(distinct (elem->>'product_id')::uuid)
  into v_pids
  from jsonb_array_elements(p_lines) elem
  where (elem->>'product_id') is not null;

  if v_pids is null or array_length(v_pids, 1) = 0 then
    return '[]'::jsonb;
  end if;

  for v_rec in
    with line_ord as (
      select
        (elem->>'product_id')::uuid as prod_id,
        coalesce((elem->>'base_qty')::numeric, 0) as qty,
        elem->>'line_id' as line_id,
        coalesce(elem->>'unit_name', '') as unit_name,
        coalesce((elem->>'conversion_rate')::numeric, 1) as conv_rate,
        row_number() over (partition by (elem->>'product_id')::uuid order by ord) as rn
      from jsonb_array_elements(p_lines) with ordinality as t(elem, ord)
      where (elem->>'product_id') is not null
    )
    select
      lo.prod_id as product_id,
      sum(lo.qty) as requested_qty,
      max(case when lo.rn = 1 then lo.line_id end) as first_line_id,
      max(case when lo.rn = 1 then lo.unit_name end) as first_unit_name,
      max(case when lo.rn = 1 then lo.conv_rate end) as first_conv_rate
    from line_ord lo
    group by lo.prod_id
  loop
    select coalesce(sr.available, 0)
    into v_avail
    from inventory._product_stock_rows(p_tenant_id, array[v_rec.product_id]) sr;

    v_avail := coalesce(v_avail, 0);

    if v_rec.requested_qty > v_avail then
      select p.name into v_pname
      from catalog.products p
      where p.id = v_rec.product_id;

      v_rate := coalesce(v_rec.first_conv_rate, 1);
      if v_rate <= 0 then v_rate := 1; end if;
      v_unit_name := coalesce(v_rec.first_unit_name, '');
      v_avail_in_unit := trunc(greatest(0, v_avail) / v_rate);
      v_msg := format('%s: chỉ còn %s %s bán được.', coalesce(v_pname, 'Sản phẩm'), v_avail_in_unit, v_unit_name);

      v_res := v_res || jsonb_build_object(
        'product_id', v_rec.product_id,
        'line_id', v_rec.first_line_id,
        'requested', v_rec.requested_qty,
        'available', v_avail,
        'message', v_msg
      );
    end if;
  end loop;

  return v_res;
end;
$$;

revoke all on function inventory._stock_shortages(uuid, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Helper: _reversal_kind
-- ---------------------------------------------------------------------------

create or replace function inventory._reversal_kind(
  p_tenant_id        uuid,
  p_sale_movement_id uuid
)
returns text
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_prod_id uuid;
  v_seq bigint;
begin
  select product_id, ledger_sequence
  into v_prod_id, v_seq
  from inventory.stock_movements
  where id = p_sale_movement_id
    and tenant_id = p_tenant_id;

  if v_prod_id is null then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy dòng xuất kho gốc.');
  end if;

  if exists (
    select 1
    from inventory.cost_runs cr
    where cr.tenant_id = p_tenant_id
      and cr.status = 'PUBLISHED'
      and cr.cut_off_sequence >= v_seq
  ) then
    return 'RETURN_IN';
  else
    return 'SALE_REVERSAL';
  end if;
end;
$$;

revoke all on function inventory._reversal_kind(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Helper: _issue_for_sale
-- ---------------------------------------------------------------------------

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

      v_cand_avail := v_lot_rec.physical_quantity - coalesce((v_allocated->>v_lot_rec.lot_key::text)::numeric, 0);

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
          array[v_lot_rec.lot_key::text],
          to_jsonb(coalesce((v_allocated->>v_lot_rec.lot_key::text)::numeric, 0) + v_take)
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

-- ---------------------------------------------------------------------------
-- 5. Helper: _reverse_sale
-- ---------------------------------------------------------------------------

create or replace function inventory._reverse_sale(
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
  v_line_elem jsonb;
  v_line_id uuid;
  v_src_type text;
  v_src_line_id uuid;
  v_need_qty numeric;
  v_total_avail numeric;
  v_sale_rec record;
  v_take numeric;
  v_rev_kind text;
  v_elements jsonb := '[]'::jsonb;
  v_reversed jsonb := '{}'::jsonb;
  v_cand_avail numeric;
  v_post_res jsonb;
  v_out_lines jsonb := '[]'::jsonb;
begin
  if p_lines is null or jsonb_array_length(p_lines) = 0 then
    return jsonb_build_object('lines', '[]'::jsonb, 'stock_changes', '[]'::jsonb);
  end if;

  v_warehouse_id := inventory._warehouse_for_store(p_tenant_id, p_store_id);

  -- (1) Advisory locks: lock products involved in source movements
  for v_prod_id in (
    select distinct m.product_id
    from jsonb_array_elements(p_lines) elem
    join inventory.stock_movements m
      on m.tenant_id = p_tenant_id
     and m.intent_type = elem->>'source_intent_type'
     and m.intent_line_id = nullif(elem->>'source_intent_line_id', '')::uuid
     and m.movement_kind = 'SALE'
    order by m.product_id asc
  ) loop
    perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext(v_prod_id::text));
  end loop;

  -- (2) Allocation per line
  for v_line_elem in select * from jsonb_array_elements(p_lines) loop
    v_line_id := (v_line_elem->>'line_id')::uuid;
    v_src_type := v_line_elem->>'source_intent_type';
    v_src_line_id := nullif(v_line_elem->>'source_intent_line_id', '')::uuid;
    v_need_qty := (v_line_elem->>'base_qty')::numeric;

    if v_src_type is null or v_src_line_id is null or v_line_id is null then
      perform inventory._raise('CONTEXT_INVALID', 'Thiếu thông tin dòng bán gốc để đảo (source_intent_type, source_intent_line_id).');
    end if;

    if not exists (
      select 1
      from inventory.stock_movements m
      where m.tenant_id = p_tenant_id
        and m.intent_type = v_src_type
        and m.intent_line_id = v_src_line_id
        and m.movement_kind = 'SALE'
    ) then
      perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy dòng xuất bán gốc để đảo.');
    end if;

    select coalesce(sum(
      - m.quantity_delta
      - coalesce(rev.reversed_qty, 0)
      - coalesce((v_reversed->>m.id::text)::numeric, 0)
    ), 0)
    into v_total_avail
    from inventory.stock_movements m
    left join (
      select vm_rev.source_movement_id, sum(sm_rev.quantity_delta) as reversed_qty
      from inventory.value_movements vm_rev
      join inventory.stock_movements sm_rev on sm_rev.id = vm_rev.movement_id
      where vm_rev.tenant_id = p_tenant_id
        and sm_rev.movement_kind in ('SALE_REVERSAL', 'RETURN_IN')
      group by vm_rev.source_movement_id
    ) rev on rev.source_movement_id = m.id
    where m.tenant_id = p_tenant_id
      and m.intent_type = v_src_type
      and m.intent_line_id = v_src_line_id
      and m.movement_kind = 'SALE';

    if v_need_qty > v_total_avail then
      perform inventory._raise('CONTEXT_INVALID', 'Số lượng đảo vượt quá số lượng đã xuất.');
    end if;

    for v_sale_rec in
      select
        m.id as movement_id,
        m.product_id,
        m.warehouse_id,
        m.lot_id,
        (- m.quantity_delta - coalesce(rev.reversed_qty, 0)) as avail_qty
      from inventory.stock_movements m
      left join inventory.lots l on l.id = m.lot_id and l.tenant_id = m.tenant_id
      left join (
        select vm_rev.source_movement_id, sum(sm_rev.quantity_delta) as reversed_qty
        from inventory.value_movements vm_rev
        join inventory.stock_movements sm_rev on sm_rev.id = vm_rev.movement_id
        where vm_rev.tenant_id = p_tenant_id
          and sm_rev.movement_kind in ('SALE_REVERSAL', 'RETURN_IN')
        group by vm_rev.source_movement_id
      ) rev on rev.source_movement_id = m.id
      where m.tenant_id = p_tenant_id
        and m.intent_type = v_src_type
        and m.intent_line_id = v_src_line_id
        and m.movement_kind = 'SALE'
      order by inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) desc nulls first, m.ledger_sequence desc
    loop
      if v_need_qty <= 0 then exit; end if;

      v_cand_avail := v_sale_rec.avail_qty - coalesce((v_reversed->>v_sale_rec.movement_id::text)::numeric, 0);

      if v_cand_avail > 0 then
        v_take := least(v_need_qty, v_cand_avail);
        v_rev_kind := inventory._reversal_kind(p_tenant_id, v_sale_rec.movement_id);

        v_elements := v_elements || jsonb_build_object(
          'line_id', v_line_id,
          'product_id', v_sale_rec.product_id,
          'lot_id', v_sale_rec.lot_id,
          'quantity_delta', v_take,
          'movement_kind', v_rev_kind,
          'source_movement_id', v_sale_rec.movement_id
        );

        v_reversed := jsonb_set(
          v_reversed,
          array[v_sale_rec.movement_id::text],
          to_jsonb(coalesce((v_reversed->>v_sale_rec.movement_id::text)::numeric, 0) + v_take)
        );

        v_need_qty := v_need_qty - v_take;
      end if;
    end loop;
  end loop;

  -- (3) Post movements
  v_post_res := inventory._post_movements(
    p_tenant_id,
    v_warehouse_id,
    p_intent_type,
    p_intent_id,
    inventory._today(),
    v_elements,
    p_created_by
  );

  -- (4) Output
  with post_lines as (
    select
      (elem->>'line_id')::uuid as line_id,
      (elem->>'amount_vnd')::bigint as amount_vnd
    from jsonb_array_elements(v_post_res->'lines') elem
  ),
  summed as (
    select line_id, sum(amount_vnd) as amount_vnd
    from post_lines
    group by line_id
  )
  select jsonb_agg(jsonb_build_object(
    'line_id', line_id,
    'amount_vnd', amount_vnd
  ))
  into v_out_lines
  from summed;

  return jsonb_build_object(
    'lines', coalesce(v_out_lines, '[]'::jsonb),
    'stock_changes', coalesce(v_post_res->'stock_changes', '[]'::jsonb)
  );
end;
$$;

revoke all on function inventory._reverse_sale(uuid, uuid, text, uuid, jsonb, uuid) from public, anon, authenticated;
