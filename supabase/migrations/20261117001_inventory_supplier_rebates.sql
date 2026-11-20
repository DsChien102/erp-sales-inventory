-- Title: inventory supplier rebates
-- Kind: schema
-- Intent: inventory_supplier_rebates
-- Context: TH-07 / spec gia von muc 12.4-12.7; PLAN T7-G5-5b
-- Touches: supplier_rebates, supplier_rebate_allocations, _post_value_adjustment, _rebate_allocation, preview_supplier_rebate, record_supplier_rebate, get_projected_cost, compare_suppliers
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy, 20261113001_inventory_supplier_programs, 20261114001_inventory_goods_receipts

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table inventory.supplier_rebates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  program_id uuid not null references inventory.supplier_programs (id),
  document_no text not null,
  document_date date not null,
  base_amount_vnd bigint not null,
  proposed_amount_vnd bigint not null,
  rebate_amount_vnd bigint not null,
  override_reason text null,
  business_date date not null,
  recorded_by uuid not null,
  recorded_at timestamptz not null default now(),
  constraint supplier_rebates_program_key unique (program_id),
  constraint chk_supplier_rebates_doc_no check (length(btrim(document_no)) between 1 and 60),
  constraint chk_supplier_rebates_amount check (rebate_amount_vnd between 1 and base_amount_vnd),
  constraint chk_supplier_rebates_reason check (
    (rebate_amount_vnd = proposed_amount_vnd)
    or (override_reason is not null and length(btrim(override_reason)) between 1 and 300)
  )
);

create index supplier_rebates_tenant_recorded_idx
  on inventory.supplier_rebates (tenant_id, recorded_at desc);

create table inventory.supplier_rebate_allocations (
  rebate_id uuid not null references inventory.supplier_rebates (id) on delete cascade,
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id),
  paid_qty numeric not null,
  purchase_amount_vnd bigint not null,
  rebate_part_vnd bigint not null,
  on_hand_qty numeric not null,
  inventory_part_vnd bigint not null,
  cogs_part_vnd bigint not null,
  avg_cost_before numeric(18,4) not null,
  avg_cost_after numeric(18,4) not null,
  value_movement_id uuid null references inventory.value_movements (id),
  primary key (rebate_id, product_id),
  constraint chk_supplier_rebate_alloc_parts check (
    inventory_part_vnd >= 0
    and cogs_part_vnd >= 0
    and inventory_part_vnd + cogs_part_vnd = rebate_part_vnd
  ),
  constraint chk_supplier_rebate_alloc_vm check (
    (value_movement_id is null) = (inventory_part_vnd = 0)
  )
);

alter table inventory.supplier_rebates enable row level security;
alter table inventory.supplier_rebate_allocations enable row level security;

revoke all on inventory.supplier_rebates from public, anon, authenticated;
revoke all on inventory.supplier_rebate_allocations from public, anon, authenticated;

create trigger trg_supplier_rebates_forbid_mutation
  before update or delete on inventory.supplier_rebates
  for each row execute function inventory._forbid_ledger_mutation();

create trigger trg_supplier_rebate_allocations_forbid_mutation
  before update or delete on inventory.supplier_rebate_allocations
  for each row execute function inventory._forbid_ledger_mutation();

alter table inventory.value_movements
  add constraint value_movements_supplier_rebate_fk
  foreign key (supplier_rebate_id) references inventory.supplier_rebates (id);

-- ---------------------------------------------------------------------------
-- 2. Internal Helpers (revoke execute from public, anon, authenticated)
-- ---------------------------------------------------------------------------

-- 2.1 _post_value_adjustment: value-only ledger line (no stock movement)
create or replace function inventory._post_value_adjustment(
  p_tenant_id uuid,
  p_product_id uuid,
  p_kind text,
  p_amount_vnd bigint,
  p_business_date date,
  p_cost_run_id uuid,
  p_supplier_rebate_id uuid,
  p_created_by uuid default auth.uid()
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_cost inventory.product_costs%rowtype;
  v_q numeric;
  v_val_before bigint;
  v_val_after bigint;
  v_avg_before numeric(18,4);
  v_avg_after numeric(18,4);
  v_seq bigint;
  v_val_id uuid;
begin
  if p_kind is null or p_kind not in ('SUPPLIER_REBATE', 'COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING') then
    perform inventory._raise('CONTEXT_INVALID', 'Loại điều chỉnh giá trị không hợp lệ: ' || coalesce(p_kind, 'null'));
  end if;

  if p_amount_vnd is null or p_business_date is null then
    perform inventory._raise('CONTEXT_INVALID', 'Thiếu số tiền hoặc ngày ghi sổ điều chỉnh giá trị.');
  end if;

  if p_kind = 'SUPPLIER_REBATE' and p_supplier_rebate_id is null then
    perform inventory._raise('CONTEXT_INVALID', 'Điều chỉnh chiết khấu NCC yêu cầu supplier_rebate_id.');
  end if;

  if p_kind in ('COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING') and p_cost_run_id is null then
    perform inventory._raise('CONTEXT_INVALID', 'Điều chỉnh lần tính giá vốn yêu cầu cost_run_id.');
  end if;

  select * into v_cost
  from inventory.product_costs
  where tenant_id = p_tenant_id
    and product_id = p_product_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chưa có dữ liệu giá vốn cho sản phẩm.');
  end if;

  v_q := v_cost.quantity_on_hand;
  v_val_before := v_cost.ledger_value_vnd;
  v_avg_before := v_cost.moving_avg_cost;
  v_val_after := v_val_before + p_amount_vnd;

  if p_kind = 'SUPPLIER_REBATE' and v_val_after < 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Giá trị sổ sau điều chỉnh chiết khấu NCC không được âm.');
  end if;

  if v_q > 0 then
    v_avg_after := greatest(round((v_val_after::numeric / v_q::numeric), 4), 0);
  else
    v_avg_after := v_avg_before;
  end if;

  v_seq := inventory._next_ledger_sequence(p_tenant_id);

  insert into inventory.value_movements (
    tenant_id, ledger_sequence, product_id, movement_id, kind,
    quantity_basis, unit_cost, amount_vnd, cost_version_id, is_provisional,
    cost_run_id, supplier_rebate_id, source_movement_id, business_date, created_by
  ) values (
    p_tenant_id, v_seq, p_product_id, null, p_kind,
    0, null, p_amount_vnd, null, false,
    p_cost_run_id, p_supplier_rebate_id, null, p_business_date,
    coalesce(p_created_by, auth.uid(), '00000000-0000-0000-0000-000000000000'::uuid)
  ) returning id into v_val_id;

  update inventory.product_costs
  set ledger_value_vnd = v_val_after,
      moving_avg_cost = v_avg_after,
      last_ledger_sequence = v_seq,
      updated_at = now()
  where tenant_id = p_tenant_id
    and product_id = p_product_id;

  return jsonb_build_object(
    'value_movement_id', v_val_id,
    'ledger_sequence', v_seq,
    'avg_before', v_avg_before,
    'avg_after', v_avg_after,
    'value_before', v_val_before,
    'value_after', v_val_after
  );
end;
$$;

revoke all on function inventory._post_value_adjustment(uuid, uuid, text, bigint, date, uuid, uuid, uuid) from public, anon, authenticated;

-- 2.2 _rebate_allocation: pure read-only allocation per product
create or replace function inventory._rebate_allocation(
  p_tenant_id uuid,
  p_program_id uuid,
  p_amount_vnd bigint
) returns table (
  product_id uuid,
  paid_qty numeric,
  purchase_amount_vnd bigint,
  rebate_part_vnd bigint,
  on_hand_qty numeric,
  ledger_value_vnd bigint,
  avg_cost_before numeric,
  inventory_part_vnd bigint,
  cogs_part_vnd bigint
)
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
begin
  return query
  with grouped as (
    select
      l.product_id as prod_id,
      sum(r.paid_qty) as sum_paid_qty,
      sum(r.purchase_amount_vnd)::bigint as sum_purchase_vnd
    from inventory.supplier_program_receipts r
    join inventory.goods_receipt_lines l on l.id = r.receipt_line_id
    where r.tenant_id = p_tenant_id
      and r.program_id = p_program_id
    group by l.product_id
    having sum(r.purchase_amount_vnd) > 0
  ),
  totals as (
    select
      g.prod_id,
      g.sum_paid_qty,
      g.sum_purchase_vnd,
      floor((p_amount_vnd::numeric * g.sum_purchase_vnd::numeric) / sum(g.sum_purchase_vnd) over ())::bigint as floor_part,
      row_number() over (order by g.sum_purchase_vnd desc, g.prod_id asc) as rn
    from grouped g
  ),
  with_rebate as (
    select
      t.prod_id,
      t.sum_paid_qty,
      t.sum_purchase_vnd,
      (
        t.floor_part
        + case when t.rn = 1 then (p_amount_vnd - sum(t.floor_part) over ())::bigint else 0::bigint end
      )::bigint as calc_rebate_part
    from totals t
  ),
  with_cost as (
    select
      w.prod_id,
      w.sum_paid_qty,
      w.sum_purchase_vnd,
      w.calc_rebate_part,
      coalesce(pc.quantity_on_hand, 0::numeric) as cur_on_hand,
      coalesce(pc.ledger_value_vnd, 0::bigint) as cur_ledger_val,
      coalesce(pc.moving_avg_cost, 0::numeric(18,4)) as cur_avg_before,
      round(
        w.calc_rebate_part::numeric
        * least(coalesce(pc.quantity_on_hand, 0::numeric), w.sum_paid_qty)
        / w.sum_paid_qty
      )::bigint as inv_raw
    from with_rebate w
    left join inventory.product_costs pc
      on pc.tenant_id = p_tenant_id
     and pc.product_id = w.prod_id
  )
  select
    wc.prod_id,
    wc.sum_paid_qty,
    wc.sum_purchase_vnd,
    wc.calc_rebate_part,
    wc.cur_on_hand,
    wc.cur_ledger_val,
    wc.cur_avg_before,
    least(wc.inv_raw, greatest(wc.cur_ledger_val, 0::bigint))::bigint,
    (wc.calc_rebate_part - least(wc.inv_raw, greatest(wc.cur_ledger_val, 0::bigint)))::bigint
  from with_cost wc;
end;
$$;

revoke all on function inventory._rebate_allocation(uuid, uuid, bigint) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Public RPCs (grant execute to authenticated)
-- ---------------------------------------------------------------------------

-- 3.1 preview_supplier_rebate
create or replace function inventory.preview_supplier_rebate(
  p_tenant_id uuid,
  p_program_id uuid,
  p_amount_vnd bigint default null
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_sp inventory.supplier_programs%rowtype;
  v_prog_row jsonb;
  v_base bigint;
  v_proposed bigint;
  v_amount bigint;
  v_allocations jsonb;
  v_inv_total bigint := 0;
  v_cogs_total bigint := 0;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  if not coalesce((v_actor->>'is_owner')::boolean, false) then
    perform inventory._raise('PERMISSION_DENIED', 'Chỉ chủ cửa hàng ghi nhận được chiết khấu.');
  end if;

  select * into v_sp
  from inventory.supplier_programs
  where id = p_program_id
    and tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình không tồn tại.');
  end if;

  if v_sp.kind <> 'VOLUME_REBATE' or v_sp.status <> 'REACHED' then
    perform inventory._raise('PROGRAM_NOT_REACHED', 'Chương trình chưa đạt mốc hoặc đã ghi nhận chiết khấu.');
  end if;

  select coalesce(sum(r.purchase_amount_vnd), 0)::bigint
  into v_base
  from inventory.supplier_program_receipts r
  where r.tenant_id = p_tenant_id
    and r.program_id = p_program_id;

  if v_base <= 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình chưa có tiền mua hợp lệ.');
  end if;

  v_proposed := round((v_base::numeric * v_sp.rebate_percent) / 100.0)::bigint;
  v_amount := coalesce(p_amount_vnd, v_proposed);

  if v_amount is null or v_amount < 1 or v_amount > v_base then
    perform inventory._raise('REBATE_AMOUNT_INVALID', 'Số tiền ghi nhận phải từ 1 đ đến tổng tiền mua.');
  end if;

  v_prog_row := inventory._program_row_json(p_tenant_id, p_program_id);

  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'product_id', a.product_id,
          'name', p.name,
          'uom', catalog._product_base_unit_name(p_tenant_id, a.product_id),
          'paid_qty', a.paid_qty,
          'purchase_amount_vnd', a.purchase_amount_vnd,
          'rebate_part_vnd', a.rebate_part_vnd,
          'on_hand_qty', a.on_hand_qty,
          'inventory_part_vnd', a.inventory_part_vnd,
          'cogs_part_vnd', a.cogs_part_vnd,
          'avg_cost_before', a.avg_cost_before,
          'avg_cost_after', case
            when a.on_hand_qty > 0 then round(((a.ledger_value_vnd - a.inventory_part_vnd)::numeric / a.on_hand_qty), 4)
            else a.avg_cost_before
          end
        )
        order by a.rebate_part_vnd desc, p.name asc
      ),
      '[]'::jsonb
    ),
    coalesce(sum(a.inventory_part_vnd), 0)::bigint,
    coalesce(sum(a.cogs_part_vnd), 0)::bigint
  into v_allocations, v_inv_total, v_cogs_total
  from inventory._rebate_allocation(p_tenant_id, p_program_id, v_amount) a
  join catalog.products p on p.id = a.product_id;

  return jsonb_build_object(
    'program_id', v_sp.id,
    'program_name', v_sp.name,
    'supplier_name', v_prog_row->>'supplier_name',
    'target_qty', v_sp.target_qty,
    'progress_qty', v_sp.progress_qty,
    'rebate_percent', v_sp.rebate_percent,
    'uom', v_prog_row->>'common_uom',
    'base_amount_vnd', v_base,
    'proposed_amount_vnd', v_proposed,
    'amount_vnd', v_amount,
    'allocations', v_allocations,
    'inventory_part_total', v_inv_total,
    'cogs_part_total', v_cogs_total
  );
end;
$$;

grant execute on function inventory.preview_supplier_rebate(uuid, uuid, bigint) to authenticated;

-- 3.2 record_supplier_rebate
create or replace function inventory.record_supplier_rebate(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_program_id uuid,
  p_payload jsonb
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_today date := inventory._today();
  v_idemp jsonb;
  v_sp inventory.supplier_programs%rowtype;
  v_prog_row jsonb;
  v_document_no text;
  v_document_date date;
  v_base bigint;
  v_proposed bigint;
  v_amount bigint;
  v_override_reason text;
  v_pid uuid;
  v_rebate_id uuid;
  v_recorded_at timestamptz;
  v_now timestamptz := now();
  v_rec record;
  v_adj jsonb;
  v_vm_id uuid;
  v_avg_after numeric(18,4);
  v_alloc_list jsonb := '[]'::jsonb;
  v_inv_total bigint := 0;
  v_cogs_total bigint := 0;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;
  if not coalesce((v_actor->>'is_owner')::boolean, false) then
    perform inventory._raise('PERMISSION_DENIED', 'Chỉ chủ cửa hàng ghi nhận được chiết khấu.');
  end if;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu ghi nhận không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'supplier_rebate.record',
    p_idempotency_key,
    md5(jsonb_build_object('program_id', p_program_id, 'payload', p_payload)::text)
  );

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  -- (1) Lock program FOR UPDATE and check status
  select * into v_sp
  from inventory.supplier_programs
  where id = p_program_id
    and tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình không tồn tại.');
  end if;

  if v_sp.kind <> 'VOLUME_REBATE' or v_sp.status <> 'REACHED' then
    perform inventory._raise('PROGRAM_NOT_REACHED', 'Chương trình chưa đạt mốc hoặc đã ghi nhận chiết khấu.');
  end if;

  -- (2) Validate payload
  v_document_no := btrim(coalesce(p_payload->>'document_no', ''));
  if length(v_document_no) < 1 or length(v_document_no) > 60 then
    perform inventory._raise('CONTEXT_INVALID', 'Số chứng từ phải từ 1 đến 60 ký tự.');
  end if;

  begin
    v_document_date := nullif(btrim(coalesce(p_payload->>'document_date', '')), '')::date;
  exception when others then
    perform inventory._raise('CONTEXT_INVALID', 'Ngày chứng từ không hợp lệ.');
  end;

  if v_document_date is null or v_document_date < v_sp.started_on or v_document_date > v_today then
    perform inventory._raise('CONTEXT_INVALID', 'Ngày chứng từ không được sau hôm nay hoặc trước ngày bắt đầu chương trình.');
  end if;

  select coalesce(sum(r.purchase_amount_vnd), 0)::bigint
  into v_base
  from inventory.supplier_program_receipts r
  where r.tenant_id = p_tenant_id
    and r.program_id = p_program_id;

  if v_base <= 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình chưa có tiền mua hợp lệ.');
  end if;

  v_proposed := round((v_base::numeric * v_sp.rebate_percent) / 100.0)::bigint;

  begin
    v_amount := (p_payload->>'amount_vnd')::bigint;
  exception when others then
    v_amount := null;
  end;

  if v_amount is null or v_amount < 1 or v_amount > v_base then
    perform inventory._raise('REBATE_AMOUNT_INVALID', 'Số tiền ghi nhận phải từ 1 đ đến tổng tiền mua.');
  end if;

  v_override_reason := nullif(btrim(coalesce(p_payload->>'override_reason', '')), '');
  if v_amount <> v_proposed then
    if v_override_reason is null or length(v_override_reason) > 300 then
      perform inventory._raise('REBATE_REASON_REQUIRED', 'Nhập lý do khi số tiền khác đề xuất.');
    end if;
  else
    v_override_reason := null;
  end if;

  -- (3) Ensure open cost period for today
  perform inventory._ensure_open_period(p_tenant_id, v_today);

  -- (4) Advisory lock per product_id ascending (same key as _post_movements)
  for v_pid in
    select distinct l.product_id
    from inventory.supplier_program_receipts r
    join inventory.goods_receipt_lines l on l.id = r.receipt_line_id
    where r.tenant_id = p_tenant_id
      and r.program_id = p_program_id
    order by l.product_id
  loop
    perform pg_advisory_xact_lock(
      hashtext(p_tenant_id::text),
      hashtext(v_pid::text)
    );
  end loop;

  -- (5) Insert supplier_rebates & allocate AFTER advisory locks
  insert into inventory.supplier_rebates (
    tenant_id, program_id, document_no, document_date,
    base_amount_vnd, proposed_amount_vnd, rebate_amount_vnd,
    override_reason, business_date, recorded_by, recorded_at
  ) values (
    p_tenant_id, p_program_id, v_document_no, v_document_date,
    v_base, v_proposed, v_amount,
    v_override_reason, v_today, v_actor_id, v_now
  ) returning id, recorded_at into v_rebate_id, v_recorded_at;

  -- (6) Post value adjustments and insert allocation rows
  for v_rec in
    select
      a.*,
      p.name as product_name,
      catalog._product_base_unit_name(p_tenant_id, a.product_id) as uom
    from inventory._rebate_allocation(p_tenant_id, p_program_id, v_amount) a
    join catalog.products p on p.id = a.product_id
    order by a.rebate_part_vnd desc, p.name asc
  loop
    if v_rec.inventory_part_vnd > 0 then
      v_adj := inventory._post_value_adjustment(
        p_tenant_id,
        v_rec.product_id,
        'SUPPLIER_REBATE',
        -v_rec.inventory_part_vnd,
        v_today,
        null,
        v_rebate_id,
        v_actor_id
      );
      v_vm_id := (v_adj->>'value_movement_id')::uuid;
      v_avg_after := (v_adj->>'avg_after')::numeric(18,4);
    else
      v_vm_id := null;
      v_avg_after := v_rec.avg_cost_before;
    end if;

    insert into inventory.supplier_rebate_allocations (
      rebate_id, tenant_id, product_id, paid_qty, purchase_amount_vnd,
      rebate_part_vnd, on_hand_qty, inventory_part_vnd, cogs_part_vnd,
      avg_cost_before, avg_cost_after, value_movement_id
    ) values (
      v_rebate_id, p_tenant_id, v_rec.product_id, v_rec.paid_qty, v_rec.purchase_amount_vnd,
      v_rec.rebate_part_vnd, v_rec.on_hand_qty, v_rec.inventory_part_vnd, v_rec.cogs_part_vnd,
      v_rec.avg_cost_before, v_avg_after, v_vm_id
    );

    v_alloc_list := v_alloc_list || jsonb_build_array(
      jsonb_build_object(
        'product_id', v_rec.product_id,
        'name', v_rec.product_name,
        'uom', v_rec.uom,
        'paid_qty', v_rec.paid_qty,
        'purchase_amount_vnd', v_rec.purchase_amount_vnd,
        'rebate_part_vnd', v_rec.rebate_part_vnd,
        'on_hand_qty', v_rec.on_hand_qty,
        'inventory_part_vnd', v_rec.inventory_part_vnd,
        'cogs_part_vnd', v_rec.cogs_part_vnd,
        'avg_cost_before', v_rec.avg_cost_before,
        'avg_cost_after', v_avg_after
      )
    );
    v_inv_total := v_inv_total + v_rec.inventory_part_vnd;
    v_cogs_total := v_cogs_total + v_rec.cogs_part_vnd;
  end loop;

  -- (7) Mark program RECORDED
  update inventory.supplier_programs
  set status = 'RECORDED',
      revision = revision + 1,
      updated_by = v_actor_id,
      updated_at = v_now
  where id = p_program_id;

  v_prog_row := inventory._program_row_json(p_tenant_id, p_program_id);

  v_res := jsonb_build_object(
    'rebate_id', v_rebate_id,
    'document_no', v_document_no,
    'document_date', v_document_date,
    'recorded_at', v_recorded_at,
    'program_id', v_sp.id,
    'program_name', v_sp.name,
    'supplier_name', v_prog_row->>'supplier_name',
    'target_qty', v_sp.target_qty,
    'progress_qty', v_sp.progress_qty,
    'rebate_percent', v_sp.rebate_percent,
    'uom', v_prog_row->>'common_uom',
    'base_amount_vnd', v_base,
    'proposed_amount_vnd', v_proposed,
    'amount_vnd', v_amount,
    'allocations', v_alloc_list,
    'inventory_part_total', v_inv_total,
    'cogs_part_total', v_cogs_total
  );

  perform inventory._complete_idempotency(
    p_tenant_id,
    'supplier_rebate.record',
    p_idempotency_key,
    'succeeded',
    v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.record_supplier_rebate(uuid, text, uuid, jsonb) to authenticated;

-- 3.3 get_projected_cost
create or replace function inventory.get_projected_cost(
  p_tenant_id uuid,
  p_program_id uuid,
  p_product_id uuid,
  p_extra_qty numeric default null,
  p_unit_price numeric default null
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_financial_masked boolean;
  v_sp inventory.supplier_programs%rowtype;
  v_uom text;
  v_missing_qty numeric;
  v_reaches boolean := null;
  v_base_p bigint := 0;
  v_q_p numeric := 0;
  v_q numeric := 0;
  v_v bigint := 0;
  v_m numeric(18,4) := 0;
  v_default_unit_price bigint := null;
  v_rebate_estimate bigint := null;
  v_avg_now numeric(18,4) := null;
  v_avg_projected numeric(18,4) := null;
  v_r_p bigint;
  v_inv_p numeric;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_financial_masked := not v_is_owner;

  select sp.*
  into v_sp
  from inventory.supplier_programs sp
  join inventory.supplier_program_products spp
    on spp.program_id = sp.id
   and spp.tenant_id = sp.tenant_id
  where sp.id = p_program_id
    and sp.tenant_id = p_tenant_id
    and sp.kind = 'VOLUME_REBATE'
    and sp.status = 'ACTIVE'
    and spp.product_id = p_product_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình hoặc sản phẩm không hợp lệ để tính giá vốn dự kiến.');
  end if;

  if (p_extra_qty is not null and p_extra_qty <= 0)
     or (p_unit_price is not null and p_unit_price < 0) then
    perform inventory._raise('CONTEXT_INVALID', 'Số lượng mua thêm phải lớn hơn 0 và đơn giá không được âm.');
  end if;

  v_uom := catalog._product_base_unit_name(p_tenant_id, p_product_id);
  v_missing_qty := greatest(v_sp.target_qty - v_sp.progress_qty - coalesce(p_extra_qty, 0), 0);

  if p_extra_qty is not null then
    v_reaches := (v_sp.progress_qty + p_extra_qty >= v_sp.target_qty);
  end if;

  if v_is_owner then
    select round(l.purchase_amount_vnd::numeric / (l.paid_qty::numeric * l.conversion_rate))::bigint
    into v_default_unit_price
    from inventory.goods_receipt_lines l
    join inventory.goods_receipts gr
      on gr.id = l.receipt_id
     and gr.tenant_id = l.tenant_id
    where gr.tenant_id = p_tenant_id
      and gr.supplier_id = v_sp.supplier_id
      and l.product_id = p_product_id
    order by gr.business_date desc, gr.created_at desc, gr.receipt_no desc, l.line_no desc
    limit 1;

    select coalesce(pc.quantity_on_hand, 0),
           coalesce(pc.ledger_value_vnd, 0),
           coalesce(pc.moving_avg_cost, 0)
    into v_q, v_v, v_m
    from inventory.product_costs pc
    where pc.tenant_id = p_tenant_id
      and pc.product_id = p_product_id;

    if not found then
      v_q := 0;
      v_v := 0;
      v_m := 0;
    end if;

    v_avg_now := v_m;

    if p_extra_qty is not null and p_unit_price is not null then
      select coalesce(sum(r.purchase_amount_vnd), 0)::bigint,
             coalesce(sum(r.paid_qty), 0)::numeric
      into v_base_p, v_q_p
      from inventory.supplier_program_receipts r
      join inventory.goods_receipt_lines l
        on l.id = r.receipt_line_id
       and l.tenant_id = r.tenant_id
      where r.tenant_id = p_tenant_id
        and r.program_id = p_program_id
        and l.product_id = p_product_id;

      v_r_p := round(((v_base_p::numeric + p_extra_qty * p_unit_price) * v_sp.rebate_percent) / 100.0)::bigint;

      if v_reaches then
        v_rebate_estimate := v_r_p;
        v_inv_p := (v_r_p::numeric * least(v_q + p_extra_qty, v_q_p + p_extra_qty)) / (v_q_p + p_extra_qty);
      else
        v_rebate_estimate := null;
        v_inv_p := 0;
      end if;

      if (v_q + p_extra_qty) > 0 then
        v_avg_projected := round((v_v::numeric + p_extra_qty * p_unit_price - v_inv_p) / (v_q + p_extra_qty), 4);
      end if;
    end if;
  end if;

  return jsonb_build_object(
    'product_id', p_product_id,
    'uom', v_uom,
    'progress_qty', v_sp.progress_qty,
    'target_qty', v_sp.target_qty,
    'missing_qty', v_missing_qty,
    'reaches_target', v_reaches,
    'rebate_estimate', v_rebate_estimate,
    'avg_now', v_avg_now,
    'avg_projected', v_avg_projected,
    'default_unit_price', v_default_unit_price,
    'financial_masked', v_financial_masked
  );
end;
$$;

grant execute on function inventory.get_projected_cost(uuid, uuid, uuid, numeric, numeric) to authenticated;

-- 3.4 compare_suppliers
create or replace function inventory.compare_suppliers(
  p_tenant_id uuid,
  p_product_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_financial_masked boolean;
  v_prod record;
  v_uom text;
  v_suppliers jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);
  v_financial_masked := not v_is_owner;

  select id, name, sku
  into v_prod
  from catalog.products
  where id = p_product_id
    and tenant_id = p_tenant_id
    and deleted_at is null;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại hoặc không thuộc cửa hàng.');
  end if;

  v_uom := catalog._product_base_unit_name(p_tenant_id, p_product_id);

  with supplier_agg as (
    select
      gr.supplier_id,
      count(distinct gr.id)::int as receipt_count,
      sum(l.paid_qty::numeric * l.conversion_rate) as paid_qty,
      sum(l.free_qty::numeric * l.conversion_rate) as free_qty,
      round(
        sum(l.landed_amount_vnd)::numeric
        / sum((l.paid_qty + l.free_qty)::numeric * l.conversion_rate),
        4
      ) as avg_landed_unit_cost
    from inventory.goods_receipt_lines l
    join inventory.goods_receipts gr
      on gr.id = l.receipt_id
     and gr.tenant_id = l.tenant_id
    where l.tenant_id = p_tenant_id
      and l.product_id = p_product_id
    group by gr.supplier_id
  ),
  latest_line as (
    select distinct on (gr.supplier_id)
      gr.supplier_id,
      l.landed_unit_cost as last_landed_unit_cost,
      gr.business_date as last_received_on
    from inventory.goods_receipt_lines l
    join inventory.goods_receipts gr
      on gr.id = l.receipt_id
     and gr.tenant_id = l.tenant_id
    where l.tenant_id = p_tenant_id
      and l.product_id = p_product_id
    order by gr.supplier_id, gr.business_date desc, gr.created_at desc, gr.receipt_no desc, l.line_no desc
  ),
  supplier_rows as (
    select
      sa.supplier_id,
      coalesce(pt.display_name, '') as name,
      coalesce(pt.is_system, false) as is_system,
      ll.last_landed_unit_cost,
      ll.last_received_on,
      sa.avg_landed_unit_cost,
      sa.receipt_count,
      sa.paid_qty,
      sa.free_qty,
      sp.id as eff_program_id,
      sp.name as eff_program_name,
      case
        when sp.id is null or coalesce(pt.is_system, false) then false
        else exists (
          select 1
          from inventory.supplier_program_products spp
          where spp.program_id = sp.id
            and spp.tenant_id = p_tenant_id
            and spp.product_id = p_product_id
        )
      end as prog_includes_product
    from supplier_agg sa
    join latest_line ll on ll.supplier_id = sa.supplier_id
    left join partner.partners pt
      on pt.partner_id = sa.supplier_id
     and pt.tenant_id = p_tenant_id
    left join inventory.supplier_programs sp
      on sp.tenant_id = p_tenant_id
     and sp.supplier_id = sa.supplier_id
     and sp.status in ('ACTIVE', 'REACHED')
     and not coalesce(pt.is_system, false)
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'partner_id', sr.supplier_id,
        'name', sr.name,
        'is_system', sr.is_system,
        'last_landed_unit_cost', case when v_is_owner then sr.last_landed_unit_cost else null end,
        'last_received_on', sr.last_received_on,
        'avg_landed_unit_cost', case when v_is_owner then sr.avg_landed_unit_cost else null end,
        'receipt_count', sr.receipt_count,
        'paid_qty', sr.paid_qty,
        'free_qty', sr.free_qty,
        'program', case
          when sr.eff_program_id is not null and sr.prog_includes_product
            then inventory._program_row_json(p_tenant_id, sr.eff_program_id)
          else null
        end,
        'other_program', case
          when sr.eff_program_id is not null and not sr.prog_includes_product
            then jsonb_build_object('program_id', sr.eff_program_id, 'name', sr.eff_program_name)
          else null
        end
      )
      order by sr.is_system asc, sr.avg_landed_unit_cost asc, sr.name asc
    ),
    '[]'::jsonb
  )
  into v_suppliers
  from supplier_rows sr;

  return jsonb_build_object(
    'product', jsonb_build_object(
      'product_id', v_prod.id,
      'name', v_prod.name,
      'code', coalesce(v_prod.sku, ''),
      'uom', v_uom
    ),
    'financial_masked', v_financial_masked,
    'suppliers', v_suppliers
  );
end;
$$;

grant execute on function inventory.compare_suppliers(uuid, uuid) to authenticated;

