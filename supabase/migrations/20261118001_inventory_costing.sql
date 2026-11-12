-- Title: inventory costing and period close
-- Kind: schema
-- Intent: inventory_costing
-- Context: TH-07 / BJ-14, spec giá vốn mục 2-7, 9; PLAN T7-G5-6
-- Touches: cost_runs, cost_run_lines, _cost_run_compute, _cost_run_is_stale, _cost_run_view, create_cost_run, get_cost_run, get_cost_overview, set_cost_policy, publish_cost_run, discard_cost_run, list_cost_versions
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy, 20261115001_inventory_sales_link, 20261116001_inventory_stocktake, 20261117001_inventory_supplier_rebates

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Tables & FKs & Indexes
-- ---------------------------------------------------------------------------

create table inventory.cost_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  code text not null,
  kind text not null check (kind in ('PERIOD_CLOSE', 'MID_PERIOD')),
  period_id uuid not null references inventory.cost_periods (id),
  period_month date not null,
  from_sequence bigint not null,
  cut_off_sequence bigint not null,
  cut_off_at timestamptz not null,
  method text not null check (method in ('MOVING', 'PERIODIC')),
  status text not null check (status in ('READY_FOR_REVIEW', 'BLOCKED', 'STALE', 'PUBLISHED', 'SUPERSEDED')),
  blockers jsonb not null default '[]'::jsonb,
  supersedes_run_id uuid null references inventory.cost_runs (id),
  based_on_run_id uuid null references inventory.cost_runs (id),
  created_by uuid not null,
  created_at timestamptz not null default now(),
  published_by uuid null,
  published_at timestamptz null,
  constraint cost_runs_tenant_code_key unique (tenant_id, code),
  constraint chk_cost_runs_sequence check (cut_off_sequence >= from_sequence)
);

create unique index idx_cost_runs_tenant_ready
  on inventory.cost_runs (tenant_id)
  where status = 'READY_FOR_REVIEW';

create table inventory.cost_run_lines (
  run_id uuid not null references inventory.cost_runs (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  old_official_unit_cost numeric(18,4) null,
  opening_qty numeric not null,
  opening_value bigint not null,
  inbound_qty numeric not null,
  inbound_value bigint not null,
  rebate_value bigint not null,
  sale_qty numeric not null,
  sale_value_recorded bigint not null,
  loss_qty numeric not null,
  loss_value_recorded bigint not null,
  closing_qty numeric not null,
  closing_value_before bigint not null,
  moving_avg_end numeric(18,4) not null,
  periodic_avg numeric(18,4) null,
  selected_unit_cost numeric(18,4) null,
  cogs_true_up bigint not null,
  loss_true_up bigint not null,
  rounding_adjust bigint not null,
  closing_value_after bigint not null,
  new_unit_cost numeric(18,4) null,
  primary key (run_id, product_id)
);

create trigger trg_cost_run_lines_append_only
  before update or delete on inventory.cost_run_lines
  for each row execute function inventory._forbid_ledger_mutation();

alter table inventory.cost_runs enable row level security;
alter table inventory.cost_run_lines enable row level security;

revoke all on inventory.cost_runs from public, anon, authenticated;
revoke all on inventory.cost_run_lines from public, anon, authenticated;

alter table inventory.cost_versions
  add constraint fk_cost_versions_run
  foreign key (cost_run_id) references inventory.cost_runs (id);

alter table inventory.cost_periods
  add constraint fk_cost_periods_closing_run
  foreign key (closing_run_id) references inventory.cost_runs (id);

alter table inventory.value_movements
  add constraint fk_value_movements_run
  foreign key (cost_run_id) references inventory.cost_runs (id);

create index idx_value_movements_tenant_product_seq
  on inventory.value_movements (tenant_id, product_id, ledger_sequence);

create index idx_stock_movements_tenant_date_seq
  on inventory.stock_movements (tenant_id, business_date, ledger_sequence);

-- ---------------------------------------------------------------------------
-- 2. _cost_run_compute
-- ---------------------------------------------------------------------------

create or replace function inventory._cost_run_compute(
  p_tenant_id uuid,
  p_from bigint,
  p_cut bigint,
  p_method text
) returns setof inventory.cost_run_lines
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_prod_id uuid;
  v_line inventory.cost_run_lines;
  v_vm record;
  v_m0 numeric(18,4);
  v_q numeric;
  v_val bigint;
  v_m numeric(18,4);
  v_qb numeric;
  v_a bigint;
  v_s numeric(18,4);
begin
  if p_cut <= p_from then
    return;
  end if;

  for v_prod_id in
    select distinct vm.product_id
    from inventory.value_movements vm
    where vm.tenant_id = p_tenant_id
      and vm.ledger_sequence > p_from
      and vm.ledger_sequence <= p_cut
      and vm.kind not in ('COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING')
    order by vm.product_id
  loop
    v_line.run_id := null;
    v_line.product_id := v_prod_id;

    select pc.official_unit_cost
    into v_line.old_official_unit_cost
    from inventory.product_costs pc
    where pc.tenant_id = p_tenant_id
      and pc.product_id = v_prod_id;

    select crl.closing_qty, crl.closing_value_after, crl.moving_avg_end
    into v_line.opening_qty, v_line.opening_value, v_m0
    from inventory.cost_run_lines crl
    join inventory.cost_runs cr on cr.id = crl.run_id
    where cr.tenant_id = p_tenant_id
      and cr.status = 'PUBLISHED'
      and crl.product_id = v_prod_id
    order by cr.cut_off_sequence desc
    limit 1;

    if not found then
      v_line.opening_qty := 0;
      v_line.opening_value := 0;
      v_m0 := 0;
    end if;

    v_line.inbound_qty := 0;
    v_line.inbound_value := 0;
    v_line.rebate_value := 0;
    v_line.sale_qty := 0;
    v_line.sale_value_recorded := 0;
    v_line.loss_qty := 0;
    v_line.loss_value_recorded := 0;

    v_q := v_line.opening_qty;
    v_val := v_line.opening_value;
    v_m := case when v_q > 0 then round(v_val::numeric / v_q, 4) else v_m0 end;

    for v_vm in
      select vm.kind, vm.quantity_basis, vm.amount_vnd
      from inventory.value_movements vm
      where vm.tenant_id = p_tenant_id
        and vm.product_id = v_prod_id
        and vm.ledger_sequence > p_from
        and vm.ledger_sequence <= p_cut
        and vm.kind not in ('COGS_TRUE_UP', 'LOSS_TRUE_UP', 'REVALUE_ROUNDING')
      order by vm.ledger_sequence asc
    loop
      v_qb := v_vm.quantity_basis;
      v_a := v_vm.amount_vnd;

      if v_vm.kind in ('RECEIPT', 'COUNT_GAIN', 'RETURN_IN') then
        v_line.inbound_qty := v_line.inbound_qty + v_qb;
        v_line.inbound_value := v_line.inbound_value + v_a;
        v_q := v_q + v_qb;
        v_val := v_val + v_a;
        if v_q > 0 then
          v_m := round(v_val::numeric / v_q, 4);
        end if;
      elsif v_vm.kind = 'SUPPLIER_REBATE' then
        v_line.rebate_value := v_line.rebate_value + v_a;
        v_val := v_val + v_a;
        if v_q > 0 then
          v_m := round(v_val::numeric / v_q, 4);
        end if;
      elsif v_vm.kind = 'SALE' then
        v_line.sale_qty := v_line.sale_qty + v_qb;
        v_line.sale_value_recorded := v_line.sale_value_recorded + (-v_a);
        v_q := v_q - v_qb;
        v_val := v_val - round(v_qb * v_m)::bigint;
      elsif v_vm.kind = 'SALE_REVERSAL' then
        v_line.sale_qty := v_line.sale_qty - v_qb;
        v_line.sale_value_recorded := v_line.sale_value_recorded - v_a;
        v_q := v_q + v_qb;
        v_val := v_val + v_a;
        if v_q > 0 then
          v_m := round(v_val::numeric / v_q, 4);
        end if;
      elsif v_vm.kind in ('COUNT_LOSS', 'WRITE_OFF') then
        v_line.loss_qty := v_line.loss_qty + v_qb;
        v_line.loss_value_recorded := v_line.loss_value_recorded + (-v_a);
        v_q := v_q - v_qb;
        v_val := v_val - round(v_qb * v_m)::bigint;
      end if;
    end loop;

    v_line.moving_avg_end := v_m;
    v_line.closing_qty := v_line.opening_qty + v_line.inbound_qty - v_line.sale_qty - v_line.loss_qty;
    v_line.closing_value_before :=
      v_line.opening_value + v_line.inbound_value + v_line.rebate_value
      - v_line.sale_value_recorded - v_line.loss_value_recorded;

    if (v_line.opening_qty + v_line.inbound_qty) > 0 then
      v_line.periodic_avg := round(
        (v_line.opening_value + v_line.inbound_value)::numeric
        / (v_line.opening_qty + v_line.inbound_qty),
        4
      );
    else
      v_line.periodic_avg := null;
    end if;

    v_s := case when p_method = 'MOVING' then v_line.moving_avg_end else v_line.periodic_avg end;
    v_line.selected_unit_cost := v_s;

    if v_s is null then
      v_line.cogs_true_up := 0;
      v_line.loss_true_up := 0;
      v_line.rounding_adjust := 0;
      v_line.closing_value_after := v_line.closing_value_before;
      v_line.new_unit_cost := null;
    else
      if p_method = 'MOVING' then
        v_line.cogs_true_up := 0;
        v_line.loss_true_up := 0;
        v_line.closing_value_after := round(v_line.closing_qty * v_s)::bigint;
      else
        v_line.cogs_true_up := round(v_line.sale_qty * v_s)::bigint - v_line.sale_value_recorded;
        v_line.loss_true_up := round(v_line.loss_qty * v_s)::bigint - v_line.loss_value_recorded;
        if v_line.closing_qty > 0 then
          v_line.closing_value_after := round(v_line.closing_qty * v_s)::bigint + v_line.rebate_value;
        else
          v_line.closing_value_after := 0;
        end if;
      end if;

      v_line.rounding_adjust :=
        v_line.closing_value_after
        - (v_line.closing_value_before - v_line.cogs_true_up - v_line.loss_true_up);

      if p_method = 'PERIODIC' and v_line.closing_qty > 0 then
        v_line.new_unit_cost := round(v_line.closing_value_after::numeric / v_line.closing_qty, 4);
      else
        v_line.new_unit_cost := v_s;
      end if;
    end if;

    return next v_line;
  end loop;
end;
$$;

revoke all on function inventory._cost_run_compute(uuid, bigint, bigint, text) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. _cost_run_is_stale
-- ---------------------------------------------------------------------------

create or replace function inventory._cost_run_is_stale(
  p_tenant_id uuid,
  p_run inventory.cost_runs
) returns boolean
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_latest_published_id uuid;
begin
  if p_run.status <> 'READY_FOR_REVIEW' then
    return false;
  end if;

  select cr.id into v_latest_published_id
  from inventory.cost_runs cr
  where cr.tenant_id = p_tenant_id
    and cr.status = 'PUBLISHED'
  order by cr.cut_off_sequence desc
  limit 1;

  if p_run.based_on_run_id is distinct from v_latest_published_id then
    return true;
  end if;

  if p_run.method <> inventory._cost_method(p_tenant_id) then
    return true;
  end if;

  return false;
end;
$$;

revoke all on function inventory._cost_run_is_stale(uuid, inventory.cost_runs) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. _cost_run_view
-- ---------------------------------------------------------------------------

create or replace function inventory._cost_run_view(
  p_tenant_id uuid,
  p_run_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_run inventory.cost_runs;
  v_status text;
  v_lines jsonb;
  v_product_count int;
  v_changed_count int;
  v_closing_value bigint;
  v_cogs_value bigint;
  v_cogs_adjust bigint;
  v_value_adjust bigint;
  v_balance_ok boolean;
  v_alt_method text;
  v_alt_closing bigint;
  v_alt_cogs bigint;
begin
  select * into v_run
  from inventory.cost_runs
  where id = p_run_id
    and tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Lần tính giá vốn không tồn tại.');
  end if;

  v_status := case
    when inventory._cost_run_is_stale(p_tenant_id, v_run) then 'STALE'
    else v_run.status
  end;

  with line_rows as (
    select
      crl.*,
      p.name as product_name,
      p.sku as product_code,
      coalesce(catalog._product_base_unit_name(p_tenant_id, crl.product_id), '') as uom,
      (-crl.cogs_true_up - crl.loss_true_up + crl.rounding_adjust) as line_adjust,
      (
        (crl.opening_value + crl.inbound_value + crl.rebate_value)
        - (
          (crl.sale_value_recorded + crl.cogs_true_up)
          + (crl.loss_value_recorded + crl.loss_true_up)
          + crl.closing_value_after
          - crl.rounding_adjust
        )
      ) as balance_diff
    from inventory.cost_run_lines crl
    join catalog.products p on p.id = crl.product_id
    where crl.run_id = v_run.id
  )
  select
    coalesce(jsonb_agg(
      jsonb_build_object(
        'product_id', lr.product_id,
        'name', lr.product_name,
        'code', lr.product_code,
        'uom', lr.uom,
        'old_official_unit_cost', lr.old_official_unit_cost,
        'opening_qty', lr.opening_qty,
        'opening_value', lr.opening_value,
        'inbound_qty', lr.inbound_qty,
        'inbound_value', lr.inbound_value,
        'rebate_value', lr.rebate_value,
        'sale_qty', lr.sale_qty,
        'sale_value_recorded', lr.sale_value_recorded,
        'loss_qty', lr.loss_qty,
        'loss_value_recorded', lr.loss_value_recorded,
        'closing_qty', lr.closing_qty,
        'closing_value_before', lr.closing_value_before,
        'moving_avg_end', lr.moving_avg_end,
        'periodic_avg', lr.periodic_avg,
        'selected_unit_cost', lr.selected_unit_cost,
        'cogs_true_up', lr.cogs_true_up,
        'loss_true_up', lr.loss_true_up,
        'rounding_adjust', lr.rounding_adjust,
        'closing_value_after', lr.closing_value_after,
        'new_unit_cost', lr.new_unit_cost,
        'line_adjust', lr.line_adjust,
        'balance_diff', lr.balance_diff
      )
      order by abs(lr.line_adjust) desc, lr.product_name asc
    ), '[]'::jsonb),
    count(*)::int,
    count(*) filter (where lr.new_unit_cost is not null and lr.new_unit_cost is distinct from lr.old_official_unit_cost)::int,
    coalesce(sum(lr.closing_value_after), 0)::bigint,
    coalesce(sum(lr.sale_value_recorded + lr.cogs_true_up), 0)::bigint,
    coalesce(sum(lr.cogs_true_up + lr.loss_true_up), 0)::bigint,
    coalesce(sum(lr.line_adjust), 0)::bigint,
    coalesce(bool_and(lr.balance_diff = 0), true)
  into
    v_lines,
    v_product_count,
    v_changed_count,
    v_closing_value,
    v_cogs_value,
    v_cogs_adjust,
    v_value_adjust,
    v_balance_ok
  from line_rows lr;

  v_alt_method := case when v_run.method = 'MOVING' then 'PERIODIC' else 'MOVING' end;

  if v_alt_method = 'PERIODIC' then
    select
      coalesce(sum(
        case
          when crl.periodic_avg is null then crl.closing_value_before
          when crl.closing_qty > 0 then round(crl.closing_qty * crl.periodic_avg)::bigint + crl.rebate_value
          else 0
        end
      ), 0)::bigint,
      coalesce(sum(
        case
          when crl.periodic_avg is null then crl.sale_value_recorded
          else round(crl.sale_qty * crl.periodic_avg)::bigint
        end
      ), 0)::bigint
    into v_alt_closing, v_alt_cogs
    from inventory.cost_run_lines crl
    where crl.run_id = v_run.id;
  else
    select
      coalesce(sum(round(crl.closing_qty * crl.moving_avg_end)::bigint), 0)::bigint,
      coalesce(sum(crl.sale_value_recorded), 0)::bigint
    into v_alt_closing, v_alt_cogs
    from inventory.cost_run_lines crl
    where crl.run_id = v_run.id;
  end if;

  return jsonb_build_object(
    'run_id', v_run.id,
    'code', v_run.code,
    'kind', v_run.kind,
    'period_month', to_char(v_run.period_month, 'YYYY-MM-DD'),
    'status', v_status,
    'method', v_run.method,
    'from_sequence', v_run.from_sequence,
    'cut_off_sequence', v_run.cut_off_sequence,
    'cut_off_at', v_run.cut_off_at,
    'created_at', v_run.created_at,
    'published_at', v_run.published_at,
    'blockers', v_run.blockers,
    'product_count', v_product_count,
    'changed_count', v_changed_count,
    'totals', jsonb_build_object(
      'closing_value', v_closing_value,
      'cogs_value', v_cogs_value,
      'cogs_adjust', v_cogs_adjust,
      'value_adjust', v_value_adjust,
      'balance_ok', v_balance_ok
    ),
    'alt', jsonb_build_object(
      'method', v_alt_method,
      'closing_value', v_alt_closing,
      'cogs_value', v_alt_cogs
    ),
    'lines', v_lines
  );
end;
$$;

revoke all on function inventory._cost_run_view(uuid, uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5. create_cost_run & get_cost_run
-- ---------------------------------------------------------------------------

create or replace function inventory.create_cost_run(
  p_tenant_id uuid,
  p_kind text,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idem jsonb;
  v_last_seq bigint;
  v_old_run inventory.cost_runs;
  v_supersedes_run_id uuid;
  v_from bigint;
  v_based_on_run_id uuid;
  v_today date := inventory._today();
  v_period_id uuid;
  v_period_month date;
  v_cut bigint;
  v_cut_off_at timestamptz;
  v_method text;
  v_blockers jsonb := '[]'::jsonb;
  v_prev_open_month date;
  v_compute_count int;
  v_mismatch_count int;
  v_run_seq int;
  v_code text;
  v_run_id uuid;
  v_pending_run_id uuid;
  v_status text;
  v_result jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', true);
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_kind not in ('MID_PERIOD', 'PERIOD_CLOSE') then
    perform inventory._raise('CONTEXT_INVALID', 'Loại lần tính không hợp lệ: ' || coalesce(p_kind, 'null'));
  end if;

  v_idem := inventory._begin_idempotency(
    p_tenant_id,
    'cost_run.create',
    p_idempotency_key,
    md5(p_kind)
  );
  if (v_idem->>'decision') = 'replay' then
    return v_idem->'result_snapshot';
  elsif (v_idem->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác tạo lần tính giá vốn đang được xử lý.');
  end if;

  perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext('cost'));

  select lc.last_sequence into v_last_seq
  from inventory.ledger_counters lc
  where lc.tenant_id = p_tenant_id
  for update;
  v_last_seq := coalesce(v_last_seq, 0);

  for v_old_run in
    select * from inventory.cost_runs
    where tenant_id = p_tenant_id
      and status = 'READY_FOR_REVIEW'
  loop
    if inventory._cost_run_is_stale(p_tenant_id, v_old_run) then
      update inventory.cost_runs
      set status = 'STALE'
      where id = v_old_run.id;
    end if;
  end loop;

  select id into v_supersedes_run_id
  from inventory.cost_runs
  where tenant_id = p_tenant_id
    and status in ('BLOCKED', 'STALE')
    and kind = p_kind
  order by created_at desc
  limit 1;

  update inventory.cost_runs
  set status = 'SUPERSEDED'
  where tenant_id = p_tenant_id
    and status in ('BLOCKED', 'STALE');

  select id, cut_off_sequence
  into v_based_on_run_id, v_from
  from inventory.cost_runs
  where tenant_id = p_tenant_id
    and status = 'PUBLISHED'
  order by cut_off_sequence desc
  limit 1;
  v_from := coalesce(v_from, 0);

  if p_kind = 'MID_PERIOD' then
    v_period_id := inventory._ensure_open_period(p_tenant_id, v_today);
    select period_month into v_period_month
    from inventory.cost_periods
    where id = v_period_id;
    v_cut := v_last_seq;
    v_cut_off_at := now();
  else
    select id, period_month
    into v_period_id, v_period_month
    from inventory.cost_periods
    where tenant_id = p_tenant_id
      and status = 'OPEN'
    order by period_month asc
    limit 1;

    if not found then
      perform inventory._raise('CONTEXT_INVALID', 'Không có kỳ giá vốn đang mở để chốt.');
    end if;

    select greatest(
      v_from,
      coalesce(max(seq), v_from)
    )
    into v_cut
    from (
      select max(sm.ledger_sequence) as seq
      from inventory.stock_movements sm
      where sm.tenant_id = p_tenant_id
        and sm.business_date >= v_period_month
        and sm.business_date < (v_period_month + interval '1 month')::date
      union all
      select max(vm.ledger_sequence) as seq
      from inventory.value_movements vm
      where vm.tenant_id = p_tenant_id
        and vm.business_date >= v_period_month
        and vm.business_date < (v_period_month + interval '1 month')::date
    ) s;

    v_cut_off_at := ((v_period_month + interval '1 month' - interval '1 minute')::timestamp at time zone 'Asia/Ho_Chi_Minh');
  end if;

  v_method := inventory._cost_method(p_tenant_id);

  -- Blockers in exact order
  select cp.period_month into v_prev_open_month
  from inventory.cost_periods cp
  where cp.tenant_id = p_tenant_id
    and cp.status = 'OPEN'
    and cp.id <> v_period_id
    and cp.period_month < v_period_month
    and (cp.period_month + interval '1 month')::date <= v_today
  order by cp.period_month asc
  limit 1;

  if found then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'PREVIOUS_PERIOD_OPEN',
      'period_month', to_char(v_prev_open_month, 'YYYY-MM-DD')
    ));
  end if;

  if p_kind = 'PERIOD_CLOSE' and (v_period_month + interval '1 month')::date > v_today then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'PERIOD_NOT_ENDED',
      'period_month', to_char(v_period_month, 'YYYY-MM-DD')
    ));
  end if;

  if inventory._has_open_stocktake(p_tenant_id) then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'STOCKTAKE_OPEN'
    ));
  end if;

  select cr.id
  into v_pending_run_id
  from inventory.cost_runs cr
  where cr.tenant_id = p_tenant_id
    and cr.status = 'READY_FOR_REVIEW'
  limit 1;

  if v_pending_run_id is not null then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'RUN_PENDING_REVIEW',
      'pending_run_id', v_pending_run_id
    ));
  end if;

  select count(*)::int into v_compute_count
  from inventory._cost_run_compute(p_tenant_id, v_from, v_cut, v_method);

  if p_kind = 'MID_PERIOD' and v_compute_count = 0 then
    v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
      'code', 'NOTHING_TO_COST'
    ));
  end if;

  if v_compute_count > 0 then
    select count(*)::int into v_mismatch_count
    from inventory._cost_run_compute(p_tenant_id, v_from, v_cut, v_method) c
    where c.closing_qty <> coalesce((
      select sum(sm.quantity_delta)
      from inventory.stock_movements sm
      where sm.tenant_id = p_tenant_id
        and sm.product_id = c.product_id
        and sm.ledger_sequence <= v_cut
    ), 0);

    if v_mismatch_count > 0 then
      v_blockers := v_blockers || jsonb_build_array(jsonb_build_object(
        'code', 'LEDGER_MISMATCH',
        'product_count', v_mismatch_count
      ));
    end if;
  end if;

  select count(*)::int + 1 into v_run_seq
  from inventory.cost_runs cr
  where cr.tenant_id = p_tenant_id
    and cr.period_month = v_period_month;

  v_code := 'GV-' || to_char(v_period_month, 'YYMM') || '-' || lpad(v_run_seq::text, 2, '0');
  v_status := case when jsonb_array_length(v_blockers) > 0 then 'BLOCKED' else 'READY_FOR_REVIEW' end;

  insert into inventory.cost_runs (
    tenant_id, code, kind, period_id, period_month,
    from_sequence, cut_off_sequence, cut_off_at,
    method, status, blockers, supersedes_run_id, based_on_run_id,
    created_by
  ) values (
    p_tenant_id, v_code, p_kind, v_period_id, v_period_month,
    v_from, v_cut, v_cut_off_at,
    v_method, v_status, v_blockers, v_supersedes_run_id, v_based_on_run_id,
    v_actor_id
  ) returning id into v_run_id;

  if v_status = 'READY_FOR_REVIEW' then
    insert into inventory.cost_run_lines (
      run_id, product_id, old_official_unit_cost,
      opening_qty, opening_value, inbound_qty, inbound_value, rebate_value,
      sale_qty, sale_value_recorded, loss_qty, loss_value_recorded,
      closing_qty, closing_value_before, moving_avg_end, periodic_avg,
      selected_unit_cost, cogs_true_up, loss_true_up, rounding_adjust,
      closing_value_after, new_unit_cost
    )
    select
      v_run_id, c.product_id, c.old_official_unit_cost,
      c.opening_qty, c.opening_value, c.inbound_qty, c.inbound_value, c.rebate_value,
      c.sale_qty, c.sale_value_recorded, c.loss_qty, c.loss_value_recorded,
      c.closing_qty, c.closing_value_before, c.moving_avg_end, c.periodic_avg,
      c.selected_unit_cost, c.cogs_true_up, c.loss_true_up, c.rounding_adjust,
      c.closing_value_after, c.new_unit_cost
    from inventory._cost_run_compute(p_tenant_id, v_from, v_cut, v_method) c;
  end if;

  v_result := inventory._cost_run_view(p_tenant_id, v_run_id);
  perform inventory._complete_idempotency(p_tenant_id, 'cost_run.create', p_idempotency_key, 'succeeded', v_result);
  return v_result;
end;
$$;

grant execute on function inventory.create_cost_run(uuid, text, text) to authenticated;

create or replace function inventory.get_cost_run(
  p_tenant_id uuid,
  p_run_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read', true);
  return inventory._cost_run_view(p_tenant_id, p_run_id);
end;
$$;

grant execute on function inventory.get_cost_run(uuid, uuid) to authenticated;


-- ---------------------------------------------------------------------------
-- 6. get_cost_overview
-- ---------------------------------------------------------------------------

create or replace function inventory.get_cost_overview(
  p_tenant_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_today date := inventory._today();
  v_method text;
  v_method_locked boolean;
  v_open_period text;
  v_period_to_close text;
  v_has_pending_run boolean;
  v_runs jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read', true);

  v_method := inventory._cost_method(p_tenant_id);

  select exists (
    select 1
    from inventory.cost_runs cr
    where cr.tenant_id = p_tenant_id
      and cr.status = 'PUBLISHED'
  ) into v_method_locked;

  select to_char(cp.period_month, 'YYYY-MM-DD')
  into v_open_period
  from inventory.cost_periods cp
  where cp.tenant_id = p_tenant_id
    and cp.status = 'OPEN'
    and cp.period_month = date_trunc('month', v_today)::date
  limit 1;

  select to_char(min(cp.period_month), 'YYYY-MM-DD')
  into v_period_to_close
  from inventory.cost_periods cp
  where cp.tenant_id = p_tenant_id
    and cp.status = 'OPEN'
    and (cp.period_month + interval '1 month')::date <= v_today;

  select exists (
    select 1
    from inventory.cost_runs cr
    where cr.tenant_id = p_tenant_id
      and cr.status = 'READY_FOR_REVIEW'
      and not inventory._cost_run_is_stale(p_tenant_id, cr)
  ) into v_has_pending_run;

  with run_rows as (
    select
      cr.id as run_id,
      cr.code,
      cr.kind,
      to_char(cr.period_month, 'YYYY-MM-DD') as period_month,
      case
        when inventory._cost_run_is_stale(p_tenant_id, cr) then 'STALE'
        else cr.status
      end as status,
      (select count(*)::int from inventory.cost_run_lines crl where crl.run_id = cr.id) as product_count,
      jsonb_array_length(cr.blockers) as blocker_count,
      (
        select coalesce(sum(-crl.cogs_true_up - crl.loss_true_up + crl.rounding_adjust), 0)::bigint
        from inventory.cost_run_lines crl
        where crl.run_id = cr.id
      ) as value_adjust_vnd,
      cr.published_at,
      cr.created_at
    from inventory.cost_runs cr
    where cr.tenant_id = p_tenant_id
      and cr.status <> 'SUPERSEDED'
    order by cr.created_at desc
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'run_id', rr.run_id,
      'code', rr.code,
      'kind', rr.kind,
      'period_month', rr.period_month,
      'status', rr.status,
      'product_count', rr.product_count,
      'blocker_count', rr.blocker_count,
      'value_adjust_vnd', case
        when rr.status in ('READY_FOR_REVIEW', 'PUBLISHED', 'STALE') then rr.value_adjust_vnd
        else null
      end,
      'published_at', rr.published_at,
      'created_at', rr.created_at
    )
    order by rr.created_at desc
  ), '[]'::jsonb)
  into v_runs
  from run_rows rr;

  return jsonb_build_object(
    'method', v_method,
    'method_locked', v_method_locked,
    'open_period', v_open_period,
    'period_to_close', v_period_to_close,
    'has_pending_run', v_has_pending_run,
    'runs', v_runs
  );
end;
$$;

grant execute on function inventory.get_cost_overview(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 7. set_cost_policy
-- ---------------------------------------------------------------------------

create or replace function inventory.set_cost_policy(
  p_tenant_id uuid,
  p_method text,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idem jsonb;
  v_result jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', true);
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_method not in ('MOVING', 'PERIODIC') then
    perform inventory._raise('CONTEXT_INVALID', 'Phương pháp giá vốn không hợp lệ: ' || coalesce(p_method, 'null'));
  end if;

  v_idem := inventory._begin_idempotency(
    p_tenant_id,
    'cost_policy.set',
    p_idempotency_key,
    md5(p_method)
  );
  if (v_idem->>'decision') = 'replay' then
    return v_idem->'result_snapshot';
  elsif (v_idem->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đổi phương pháp giá vốn đang được xử lý.');
  end if;

  perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext('cost'));

  if exists (
    select 1
    from inventory.cost_runs cr
    where cr.tenant_id = p_tenant_id
      and cr.status = 'PUBLISHED'
  ) then
    perform inventory._raise('COST_POLICY_LOCKED', 'Đã công bố giá vốn nên không đổi được phương pháp.');
  end if;

  insert into inventory.cost_policies (
    tenant_id, method, changed_at, changed_by
  ) values (
    p_tenant_id, p_method, now(), v_actor_id
  )
  on conflict (tenant_id) do update
    set method = excluded.method,
        changed_at = excluded.changed_at,
        changed_by = excluded.changed_by;

  v_result := jsonb_build_object(
    'method', p_method,
    'method_locked', false
  );

  perform inventory._complete_idempotency(p_tenant_id, 'cost_policy.set', p_idempotency_key, 'succeeded', v_result);
  return v_result;
end;
$$;

grant execute on function inventory.set_cost_policy(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 8. publish_cost_run
-- ---------------------------------------------------------------------------

create or replace function inventory.publish_cost_run(
  p_tenant_id uuid,
  p_run_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idem jsonb;
  v_run inventory.cost_runs;
  v_date date;
  v_line inventory.cost_run_lines;
  v_lock_product_id uuid;
  v_eff bigint;
  v_ver_id uuid;
  v_result jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read', true);
  v_actor_id := (v_actor->>'actor_id')::uuid;

  v_idem := inventory._begin_idempotency(
    p_tenant_id,
    'cost_run.publish',
    p_idempotency_key,
    md5(p_run_id::text)
  );
  if (v_idem->>'decision') = 'replay' then
    return v_idem->'result_snapshot';
  elsif (v_idem->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác công bố giá vốn đang được xử lý.');
  end if;

  perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext('cost'));

  select * into v_run
  from inventory.cost_runs
  where id = p_run_id
    and tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Lần tính giá vốn không tồn tại.');
  end if;

  if v_run.status <> 'READY_FOR_REVIEW' then
    perform inventory._raise('COST_RUN_NOT_READY', 'Lần tính không còn ở trạng thái chờ công bố.');
  end if;

  if inventory._cost_run_is_stale(p_tenant_id, v_run) then
    perform inventory._raise('COST_RUN_STALE', 'Dữ liệu đầu vào đã thay đổi. Hãy tạo lần tính kế tiếp.');
  end if;

  v_date := case
    when v_run.kind = 'PERIOD_CLOSE' then (v_run.period_month + interval '1 month' - interval '1 day')::date
    else inventory._today()
  end;

  for v_lock_product_id in
    select crl.product_id
    from inventory.cost_run_lines crl
    where crl.run_id = v_run.id
    order by crl.product_id asc
  loop
    perform pg_advisory_xact_lock(
      hashtext(p_tenant_id::text),
      hashtext(v_lock_product_id::text)
    );
  end loop;

  for v_line in
    select *
    from inventory.cost_run_lines crl
    where crl.run_id = v_run.id
    order by crl.product_id asc
  loop
    if v_line.cogs_true_up <> 0 then
      perform inventory._post_value_adjustment(
        p_tenant_id, v_line.product_id, 'COGS_TRUE_UP', -v_line.cogs_true_up,
        v_date, v_run.id, null, v_actor_id
      );
    end if;

    if v_line.loss_true_up <> 0 then
      perform inventory._post_value_adjustment(
        p_tenant_id, v_line.product_id, 'LOSS_TRUE_UP', -v_line.loss_true_up,
        v_date, v_run.id, null, v_actor_id
      );
    end if;

    if v_line.rounding_adjust <> 0 then
      perform inventory._post_value_adjustment(
        p_tenant_id, v_line.product_id, 'REVALUE_ROUNDING', v_line.rounding_adjust,
        v_date, v_run.id, null, v_actor_id
      );
    end if;
  end loop;

  select coalesce(lc.last_sequence, 0) + 1
  into v_eff
  from inventory.ledger_counters lc
  where lc.tenant_id = p_tenant_id;
  v_eff := coalesce(v_eff, 1);

  for v_line in
    select *
    from inventory.cost_run_lines crl
    where crl.run_id = v_run.id
      and crl.new_unit_cost is not null
    order by crl.product_id asc
  loop
    insert into inventory.cost_versions (
      tenant_id, product_id, unit_cost, method, effective_from_sequence, cost_run_id
    ) values (
      p_tenant_id, v_line.product_id, v_line.new_unit_cost, v_run.method, v_eff, v_run.id
    ) returning id into v_ver_id;

    update inventory.product_costs pc
    set official_version_id = v_ver_id,
        official_unit_cost = v_line.new_unit_cost,
        moving_avg_cost = case
          when v_run.method = 'PERIODIC' and pc.quantity_on_hand > 0
            then greatest(round(pc.ledger_value_vnd::numeric / pc.quantity_on_hand, 4), 0)
          else pc.moving_avg_cost
        end,
        updated_at = now()
    where pc.tenant_id = p_tenant_id
      and pc.product_id = v_line.product_id;
  end loop;

  if v_run.kind = 'PERIOD_CLOSE' then
    update inventory.cost_periods
    set status = 'CLOSED',
        closed_at = now(),
        closed_by = v_actor_id,
        closing_run_id = v_run.id
    where id = v_run.period_id;

    insert into inventory.cost_periods (tenant_id, period_month, status)
    values (p_tenant_id, (v_run.period_month + interval '1 month')::date, 'OPEN')
    on conflict (tenant_id, period_month) do nothing;
  end if;

  update inventory.cost_runs
  set status = 'PUBLISHED',
      published_by = v_actor_id,
      published_at = now()
  where id = v_run.id;

  v_result := inventory._cost_run_view(p_tenant_id, v_run.id);
  perform inventory._complete_idempotency(p_tenant_id, 'cost_run.publish', p_idempotency_key, 'succeeded', v_result);
  return v_result;
end;
$$;

grant execute on function inventory.publish_cost_run(uuid, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 9. discard_cost_run
-- ---------------------------------------------------------------------------

create or replace function inventory.discard_cost_run(
  p_tenant_id uuid,
  p_run_id uuid,
  p_idempotency_key text
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_idem jsonb;
  v_run inventory.cost_runs;
  v_status text;
  v_result jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read', true);

  v_idem := inventory._begin_idempotency(
    p_tenant_id,
    'cost_run.discard',
    p_idempotency_key,
    md5(p_run_id::text)
  );
  if (v_idem->>'decision') = 'replay' then
    return v_idem->'result_snapshot';
  elsif (v_idem->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác bỏ lần tính đang được xử lý.');
  end if;

  perform pg_advisory_xact_lock(hashtext(p_tenant_id::text), hashtext('cost'));

  select * into v_run
  from inventory.cost_runs
  where id = p_run_id
    and tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Lần tính giá vốn không tồn tại.');
  end if;

  v_status := case
    when inventory._cost_run_is_stale(p_tenant_id, v_run) then 'STALE'
    else v_run.status
  end;

  if v_status not in ('READY_FOR_REVIEW', 'BLOCKED', 'STALE') then
    perform inventory._raise('COST_RUN_NOT_READY', 'Lần tính không còn ở trạng thái chờ công bố.');
  end if;

  update inventory.cost_runs
  set status = 'SUPERSEDED'
  where id = v_run.id;

  v_result := jsonb_build_object(
    'run_id', v_run.id,
    'status', 'SUPERSEDED'
  );

  perform inventory._complete_idempotency(p_tenant_id, 'cost_run.discard', p_idempotency_key, 'succeeded', v_result);
  return v_result;
end;
$$;

grant execute on function inventory.discard_cost_run(uuid, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- 10. list_cost_versions
-- ---------------------------------------------------------------------------

create or replace function inventory.list_cost_versions(
  p_tenant_id uuid,
  p_product_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_name text;
  v_uom text;
  v_versions jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read', true);

  select p.name into v_name
  from catalog.products p
  where p.id = p_product_id
    and p.tenant_id = p_tenant_id
    and p.deleted_at is null;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại.');
  end if;

  v_uom := coalesce(catalog._product_base_unit_name(p_tenant_id, p_product_id), '');

  select coalesce(jsonb_agg(
    jsonb_build_object(
      'version_id', cv.id,
      'unit_cost', cv.unit_cost,
      'method', cv.method,
      'run_code', coalesce(cr.code, ''),
      'published_at', cr.published_at
    )
    order by cv.effective_from_sequence desc
  ), '[]'::jsonb)
  into v_versions
  from inventory.cost_versions cv
  left join inventory.cost_runs cr on cr.id = cv.cost_run_id
  where cv.tenant_id = p_tenant_id
    and cv.product_id = p_product_id;

  return jsonb_build_object(
    'product_id', p_product_id,
    'name', v_name,
    'uom', v_uom,
    'versions', v_versions
  );
end;
$$;

grant execute on function inventory.list_cost_versions(uuid, uuid) to authenticated;
