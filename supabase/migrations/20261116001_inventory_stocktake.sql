-- Title: inventory stocktake sessions, blind count, recount, and cancellation
-- Kind: schema
-- Intent: inventory_stocktake
-- Context: TH-07 / G5-5 Kiểm kê; PLAN T7-G5-5
-- Touches: stocktake_sessions, stocktake_lines, stocktake_counts, _has_open_stocktake, list_stocktake_sessions, get_stocktake_form_options, open_stocktake, get_stocktake_session, save_stocktake_draft, get_stocktake_unexpected_options, add_stocktake_unexpected_line, cancel_stocktake, submit_stocktake_first_count, submit_stocktake_recount
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy, 20260709006_catalog_basic_stock, 20261105001_iam_member_display_name

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table inventory.stocktake_sessions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  code text not null,
  warehouse_id uuid not null references inventory.warehouses (id),
  scope_kind text not null check (scope_kind in ('ALL', 'PRODUCT', 'LOT')),
  scope_product_id uuid null references catalog.products (id),
  scope_lot_id uuid null references inventory.lots (id),
  scope_label text not null,
  counter_user_id uuid not null,
  reason text not null check (length(btrim(reason)) between 1 and 200),
  status text not null default 'COUNTING' check (status in ('COUNTING', 'RECOUNT', 'COMPLETED', 'CANCELLED')),
  result_kind text null check (result_kind is null or result_kind in ('MATCHED', 'ADJUSTED')),
  opened_at timestamptz not null default now(),
  opened_by uuid not null,
  first_submitted_at timestamptz null,
  completed_at timestamptz null,
  completed_by uuid null,
  cancelled_at timestamptz null,
  cancelled_by uuid null,
  cancel_reason text null,
  adjustment_value_vnd bigint null,
  stock_changes jsonb null,
  constraint stocktake_sessions_tenant_code_key unique (tenant_id, code),
  constraint chk_stocktake_sessions_scope check (
    (scope_kind = 'ALL' and scope_product_id is null and scope_lot_id is null)
    or (scope_kind = 'PRODUCT' and scope_product_id is not null and scope_lot_id is null)
    or (scope_kind = 'LOT' and scope_product_id is not null and scope_lot_id is not null)
  )
);

create index stocktake_sessions_tenant_opened_idx
  on inventory.stocktake_sessions (tenant_id, opened_at desc);

create index stocktake_sessions_tenant_status_idx
  on inventory.stocktake_sessions (tenant_id, status);

create table inventory.stocktake_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  session_id uuid not null references inventory.stocktake_sessions (id) on delete cascade,
  line_no int not null,
  product_id uuid not null references catalog.products (id),
  lot_id uuid null references inventory.lots (id),
  new_lot_code text null,
  new_expiry_date date null,
  new_expiry_precision text null check (new_expiry_precision is null or new_expiry_precision in ('DAY', 'MONTH', 'YEAR')),
  is_unexpected boolean not null default false,
  draft_qty numeric null check (draft_qty is null or draft_qty >= 0),
  needs_recount boolean not null default false,
  loss_reason text null check (loss_reason is null or loss_reason in ('LOSS', 'DAMAGED', 'EXPIRED')),
  book_qty_at_commit numeric null,
  adjust_qty numeric null,
  adjust_value_vnd bigint null,
  constraint stocktake_lines_session_line_no_key unique (session_id, line_no)
);

create unique index stocktake_lines_session_item_uidx
  on inventory.stocktake_lines (
    session_id,
    product_id,
    coalesce(lot_id::text, lower(btrim(new_lot_code)), '')
  );

create table inventory.stocktake_counts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  session_id uuid not null references inventory.stocktake_sessions (id) on delete cascade,
  line_id uuid not null references inventory.stocktake_lines (id) on delete cascade,
  round smallint not null check (round in (1, 2)),
  quantity numeric not null check (quantity >= 0),
  counted_by uuid not null,
  counted_at timestamptz not null default now(),
  constraint stocktake_counts_line_round_key unique (line_id, round)
);

-- RLS & Revoke
alter table inventory.stocktake_sessions enable row level security;
alter table inventory.stocktake_lines enable row level security;
alter table inventory.stocktake_counts enable row level security;

revoke all on inventory.stocktake_sessions from public, anon, authenticated;
revoke all on inventory.stocktake_lines from public, anon, authenticated;
revoke all on inventory.stocktake_counts from public, anon, authenticated;

-- Append-only enforcement for stocktake_counts
create trigger trg_stocktake_counts_forbid_mutation
  before update or delete on inventory.stocktake_counts
  for each row execute function inventory._forbid_ledger_mutation();

-- ---------------------------------------------------------------------------
-- 2. Internal Helpers
-- ---------------------------------------------------------------------------

create or replace function inventory._has_open_stocktake(p_tenant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = inventory, pg_temp
as $$
  select exists (
    select 1
    from inventory.stocktake_sessions ss
    where ss.tenant_id = p_tenant_id
      and ss.status in ('COUNTING', 'RECOUNT')
  );
$$;

revoke all on function inventory._has_open_stocktake(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Public RPCs
-- ---------------------------------------------------------------------------

-- 3.1 list_stocktake_sessions
create or replace function inventory.list_stocktake_sessions(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_items jsonb := '[]'::jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select coalesce(jsonb_agg(item_obj order by opened_at desc), '[]'::jsonb)
  into v_items
  from (
    select
      s.opened_at,
      jsonb_build_object(
        'id', s.id,
        'code', s.code,
        'scope_label', s.scope_label,
        'counter_name', iam._member_display_name(s.counter_user_id),
        'status', s.status,
        'opened_at', s.opened_at,
        'line_count', (
          select count(*)::int
          from inventory.stocktake_lines l
          where l.session_id = s.id
        ),
        'counted_count', case
          when s.status = 'COUNTING' then (
            select count(*)::int
            from inventory.stocktake_lines l
            where l.session_id = s.id
              and l.draft_qty is not null
          )
          else (
            select count(*)::int
            from inventory.stocktake_lines l
            where l.session_id = s.id
          )
        end,
        'variance_count', (
          select count(*)::int
          from inventory.stocktake_lines l
          where l.session_id = s.id
            and l.needs_recount
        )
      ) as item_obj
    from inventory.stocktake_sessions s
    where s.tenant_id = p_tenant_id
      and (
        s.status in ('COUNTING', 'RECOUNT')
        or (
          s.status in ('COMPLETED', 'CANCELLED')
          and coalesce(s.completed_at, s.cancelled_at) >= now() - interval '30 days'
        )
      )
  ) rows;

  return jsonb_build_object('items', v_items);
end;
$$;

grant execute on function inventory.list_stocktake_sessions(uuid) to authenticated;

-- 3.2 get_stocktake_form_options
create or replace function inventory.get_stocktake_form_options(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_warehouse_id uuid;
  v_today date := inventory._today();
  v_all_count int := 0;
  v_products jsonb := '[]'::jsonb;
  v_lots jsonb := '[]'::jsonb;
  v_members jsonb := '[]'::jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  with positive_pairs as (
    select
      p.id as product_id,
      p.name as product_name,
      p.sku as product_code,
      coalesce(catalog._product_base_unit_name(p_tenant_id, p.id), '') as uom,
      l.id as lot_id,
      l.lot_code,
      l.expiry_date,
      l.expiry_precision
    from inventory.stock_balances sb
    join catalog.products p
      on p.id = sb.product_id
     and p.tenant_id = p_tenant_id
     and p.deleted_at is null
    left join inventory.lots l
      on l.id = sb.lot_key
     and l.tenant_id = sb.tenant_id
    where sb.tenant_id = p_tenant_id
      and sb.warehouse_id = v_warehouse_id
      and sb.physical_quantity > 0
  )
  select
    count(*)::int,
    coalesce((
      select jsonb_agg(prod_obj order by prod_obj->>'name')
      from (
        select jsonb_build_object(
          'id', pp.product_id,
          'name', pp.product_name,
          'code', pp.product_code,
          'uom', pp.uom,
          'line_count', count(*)::int
        ) as prod_obj
        from positive_pairs pp
        group by pp.product_id, pp.product_name, pp.product_code, pp.uom
      ) gp
    ), '[]'::jsonb),
    coalesce((
      select jsonb_agg(lot_obj order by lot_obj->>'product_name', lot_obj->>'lot_code')
      from (
        select jsonb_build_object(
          'id', pp.lot_id,
          'product_id', pp.product_id,
          'product_name', pp.product_name,
          'code', pp.product_code,
          'lot_code', pp.lot_code,
          'expiry_date', pp.expiry_date,
          'expiry_precision', pp.expiry_precision,
          'is_expired', (
            pp.expiry_date is not null
            and inventory._lot_expiry_end(pp.expiry_date, pp.expiry_precision) < v_today
          ),
          'uom', pp.uom
        ) as lot_obj
        from positive_pairs pp
        where pp.lot_id is not null
      ) gl
    ), '[]'::jsonb)
  into v_all_count, v_products, v_lots
  from positive_pairs;

  select coalesce(jsonb_agg(mem_obj order by mem_obj->>'name'), '[]'::jsonb)
  into v_members
  from (
    select jsonb_build_object(
      'user_id', m.user_id,
      'name', iam._member_display_name(m.user_id)
    ) as mem_obj
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.is_active
  ) gm;

  return jsonb_build_object(
    'all_count', coalesce(v_all_count, 0),
    'products', coalesce(v_products, '[]'::jsonb),
    'lots', coalesce(v_lots, '[]'::jsonb),
    'members', coalesce(v_members, '[]'::jsonb),
    'me', v_actor_id
  );
end;
$$;

grant execute on function inventory.get_stocktake_form_options(uuid) to authenticated;

-- 3.3 open_stocktake
create or replace function inventory.open_stocktake(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_warehouse_id uuid;
  v_today date := inventory._today();
  v_idemp jsonb;
  v_scope_kind text;
  v_product_id uuid;
  v_lot_id uuid;
  v_counter_user_id uuid;
  v_reason text;
  v_scope_label text;
  v_prod_name text;
  v_lot_code text;
  v_lot_product_id uuid;
  v_target_product_ids uuid[];
  v_pair_count int;
  v_conflict record;
  v_seq int;
  v_code text;
  v_session_id uuid := gen_random_uuid();
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;
  v_warehouse_id := (v_actor->>'warehouse_id')::uuid;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stocktake.open',
    p_idempotency_key,
    md5(p_payload::text)
  );

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  v_scope_kind := nullif(btrim(coalesce(p_payload->>'scope_kind', '')), '');
  if v_scope_kind is null or v_scope_kind not in ('ALL', 'PRODUCT', 'LOT') then
    perform inventory._raise('CONTEXT_INVALID', 'Phạm vi kiểm kê không hợp lệ.');
  end if;

  begin
    v_counter_user_id := (p_payload->>'counter_user_id')::uuid;
  exception when others then
    perform inventory._raise('CONTEXT_INVALID', 'Người đếm không hợp lệ.');
  end;

  if v_counter_user_id is null or not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_counter_user_id
      and m.is_active
  ) then
    perform inventory._raise('CONTEXT_INVALID', 'Người đếm không phải thành viên đang hoạt động.');
  end if;

  v_reason := btrim(coalesce(p_payload->>'reason', ''));
  if length(v_reason) < 1 or length(v_reason) > 200 then
    perform inventory._raise('CONTEXT_INVALID', 'Lý do kiểm kê phải từ 1 đến 200 ký tự.');
  end if;

  -- Serialize concurrent open checks within tenant
  perform pg_advisory_xact_lock(
    hashtextextended(p_tenant_id::text || ':stocktake_open', 0)
  );

  if v_scope_kind = 'ALL' then
    if nullif(btrim(coalesce(p_payload->>'product_id', '')), '') is not null
       or nullif(btrim(coalesce(p_payload->>'lot_id', '')), '') is not null then
      perform inventory._raise('CONTEXT_INVALID', 'Phạm vi toàn kho không chọn sản phẩm hoặc lô.');
    end if;
    v_product_id := null;
    v_lot_id := null;
    v_scope_label := 'Toàn kho';
  elsif v_scope_kind = 'PRODUCT' then
    if nullif(btrim(coalesce(p_payload->>'lot_id', '')), '') is not null then
      perform inventory._raise('CONTEXT_INVALID', 'Phạm vi sản phẩm không chọn lô.');
    end if;
    begin
      v_product_id := (p_payload->>'product_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không hợp lệ.');
    end;
    if v_product_id is null then
      perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm là bắt buộc.');
    end if;
    select p.name into v_prod_name
    from catalog.products p
    where p.id = v_product_id
      and p.tenant_id = p_tenant_id
      and p.deleted_at is null;
    if not found then
      perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại.');
    end if;
    v_lot_id := null;
    v_scope_label := v_prod_name;
  else
    begin
      v_lot_id := (p_payload->>'lot_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Lô không hợp lệ.');
    end;
    if v_lot_id is null then
      perform inventory._raise('CONTEXT_INVALID', 'Lô là bắt buộc.');
    end if;

    if nullif(btrim(coalesce(p_payload->>'product_id', '')), '') is not null then
      begin
        v_product_id := (p_payload->>'product_id')::uuid;
      exception when others then
        perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không hợp lệ.');
      end;
    end if;

    select l.product_id, l.lot_code, p.name
    into v_lot_product_id, v_lot_code, v_prod_name
    from inventory.lots l
    join catalog.products p
      on p.id = l.product_id
     and p.tenant_id = l.tenant_id
    where l.id = v_lot_id
      and l.tenant_id = p_tenant_id
      and p.deleted_at is null;

    if not found then
      perform inventory._raise('CONTEXT_INVALID', 'Lô không tồn tại.');
    end if;

    if v_product_id is not null and v_product_id <> v_lot_product_id then
      perform inventory._raise('CONTEXT_INVALID', 'Lô không thuộc sản phẩm đã chọn.');
    end if;
    v_product_id := v_lot_product_id;
    v_scope_label := v_prod_name || ' · Lô ' || v_lot_code;
  end if;

  -- Check positive-stock target lines in scope
  select
    count(*)::int,
    coalesce(array_agg(distinct sb.product_id), '{}'::uuid[])
  into v_pair_count, v_target_product_ids
  from inventory.stock_balances sb
  join catalog.products p
    on p.id = sb.product_id
   and p.tenant_id = p_tenant_id
   and p.deleted_at is null
  where sb.tenant_id = p_tenant_id
    and sb.warehouse_id = v_warehouse_id
    and sb.physical_quantity > 0
    and (
      v_scope_kind = 'ALL'
      or (v_scope_kind = 'PRODUCT' and sb.product_id = v_product_id)
      or (v_scope_kind = 'LOT' and sb.product_id = v_product_id and sb.lot_key = v_lot_id)
    );

  if coalesce(v_pair_count, 0) = 0 then
    perform inventory._raise('STOCKTAKE_SCOPE_EMPTY', 'Kho chưa có hàng trong phạm vi này để kiểm kê.');
  end if;

  -- Check conflict against open COUNTING / RECOUNT sessions
  select s.id, s.code, s.scope_label
  into v_conflict
  from inventory.stocktake_sessions s
  where s.tenant_id = p_tenant_id
    and s.status in ('COUNTING', 'RECOUNT')
    and (
      s.scope_kind = 'ALL'
      or v_scope_kind = 'ALL'
      or exists (
        select 1
        from inventory.stocktake_lines l
        where l.session_id = s.id
          and l.product_id = any(v_target_product_ids)
      )
    )
  order by s.opened_at desc
  limit 1;

  if found then
    v_res := jsonb_build_object(
      'conflict', jsonb_build_object(
        'session_id', v_conflict.id,
        'code', v_conflict.code,
        'scope_label', v_conflict.scope_label
      )
    );
    perform inventory._complete_idempotency(
      p_tenant_id,
      'stocktake.open',
      p_idempotency_key,
      'failed',
      v_res
    );
    return v_res;
  end if;

  -- Code sequence KK-YYMMDD-nn
  perform pg_advisory_xact_lock(
    hashtextextended(p_tenant_id::text || ':stocktake_code:' || v_today::text, 0)
  );
  select count(*)::int + 1
  into v_seq
  from inventory.stocktake_sessions s
  where s.tenant_id = p_tenant_id
    and (s.opened_at at time zone 'Asia/Ho_Chi_Minh')::date = v_today;

  v_code := 'KK-' || to_char(v_today, 'YYMMDD') || '-' || lpad(v_seq::text, 2, '0');

  insert into inventory.stocktake_sessions (
    id, tenant_id, code, warehouse_id, scope_kind, scope_product_id, scope_lot_id,
    scope_label, counter_user_id, reason, status, opened_at, opened_by
  ) values (
    v_session_id, p_tenant_id, v_code, v_warehouse_id, v_scope_kind, v_product_id, v_lot_id,
    v_scope_label, v_counter_user_id, v_reason, 'COUNTING', now(), v_actor_id
  );

  insert into inventory.stocktake_lines (
    tenant_id, session_id, line_no, product_id, lot_id, is_unexpected
  )
  select
    p_tenant_id,
    v_session_id,
    row_number() over (order by p.name, lt.lot_code nulls first, sb.product_id, sb.lot_key),
    sb.product_id,
    case
      when sb.lot_key = '00000000-0000-0000-0000-000000000000'::uuid then null
      else sb.lot_key
    end,
    false
  from inventory.stock_balances sb
  join catalog.products p
    on p.id = sb.product_id
   and p.tenant_id = p_tenant_id
   and p.deleted_at is null
  left join inventory.lots lt
    on lt.id = sb.lot_key
   and lt.tenant_id = sb.tenant_id
  where sb.tenant_id = p_tenant_id
    and sb.warehouse_id = v_warehouse_id
    and sb.physical_quantity > 0
    and (
      v_scope_kind = 'ALL'
      or (v_scope_kind = 'PRODUCT' and sb.product_id = v_product_id)
      or (v_scope_kind = 'LOT' and sb.product_id = v_product_id and sb.lot_key = v_lot_id)
    );

  v_res := jsonb_build_object(
    'session_id', v_session_id,
    'code', v_code
  );
  perform inventory._complete_idempotency(
    p_tenant_id,
    'stocktake.open',
    p_idempotency_key,
    'succeeded',
    v_res
  );
  return v_res;
end;
$$;

grant execute on function inventory.open_stocktake(uuid, text, jsonb) to authenticated;

-- 3.4 get_stocktake_session
create or replace function inventory.get_stocktake_session(
  p_tenant_id uuid,
  p_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_today date := inventory._today();
  v_s inventory.stocktake_sessions%rowtype;
  v_lines jsonb := '[]'::jsonb;
  v_header jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);

  select * into v_s
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  select coalesce(jsonb_agg(line_obj order by line_no), '[]'::jsonb)
  into v_lines
  from (
    select
      l.line_no,
      (
        jsonb_build_object(
          'line_id', l.id,
          'product_id', l.product_id,
          'product_name', p.name,
          'product_code', p.sku,
          'lot_id', l.lot_id,
          'lot_code', coalesce(lt.lot_code, l.new_lot_code),
          'expiry_date', coalesce(lt.expiry_date, l.new_expiry_date),
          'is_expired', (
            coalesce(lt.expiry_date, l.new_expiry_date) is not null
            and inventory._lot_expiry_end(
              coalesce(lt.expiry_date, l.new_expiry_date),
              coalesce(lt.expiry_precision, l.new_expiry_precision)
            ) < v_today
          ),
          'uom', coalesce(catalog._product_base_unit_name(p_tenant_id, l.product_id), ''),
          'is_unexpected', l.is_unexpected,
          'draft_qty', l.draft_qty,
          'needs_recount', l.needs_recount,
          'loss_reason', l.loss_reason
        )
        || case
          when v_s.status <> 'COUNTING' then
            jsonb_build_object(
              'first_qty', c1.quantity,
              'recount_qty', c2.quantity,
              'book_qty', calc.effective_book,
              'variance', coalesce(c2.quantity, c1.quantity) - calc.effective_book,
              'adjust_qty', l.adjust_qty
            )
            || case
              when v_is_owner then
                jsonb_build_object('adjust_value_vnd', l.adjust_value_vnd)
              else
                '{}'::jsonb
            end
          else
            '{}'::jsonb
        end
      ) as line_obj
    from inventory.stocktake_lines l
    join catalog.products p
      on p.id = l.product_id
     and p.tenant_id = p_tenant_id
    left join inventory.lots lt
      on lt.id = l.lot_id
     and lt.tenant_id = p_tenant_id
    left join inventory.stock_balances sb
      on sb.tenant_id = l.tenant_id
     and sb.warehouse_id = v_s.warehouse_id
     and sb.product_id = l.product_id
     and sb.lot_key = coalesce(l.lot_id, '00000000-0000-0000-0000-000000000000'::uuid)
    left join inventory.stocktake_counts c1
      on c1.line_id = l.id
     and c1.round = 1
    left join inventory.stocktake_counts c2
      on c2.line_id = l.id
     and c2.round = 2
    cross join lateral (
      select
        case
          when v_s.status = 'COMPLETED' and l.book_qty_at_commit is not null then
            l.book_qty_at_commit
          when l.lot_id is null and l.new_lot_code is not null then
            0::numeric
          else
            coalesce(sb.physical_quantity, 0)
        end as effective_book
    ) calc
    where l.session_id = v_s.id
  ) rows;

  v_header := jsonb_build_object(
    'id', v_s.id,
    'code', v_s.code,
    'scope_kind', v_s.scope_kind,
    'scope_label', v_s.scope_label,
    'counter_name', iam._member_display_name(v_s.counter_user_id),
    'reason', v_s.reason,
    'status', v_s.status,
    'result_kind', v_s.result_kind,
    'opened_at', v_s.opened_at,
    'first_submitted_at', v_s.first_submitted_at,
    'completed_at', v_s.completed_at,
    'completed_by_name', case
      when v_s.completed_by is not null then iam._member_display_name(v_s.completed_by)
      else null
    end,
    'cancelled_at', v_s.cancelled_at,
    'cancel_reason', v_s.cancel_reason,
    'stock_changes', v_s.stock_changes,
    'lines', v_lines
  );

  if v_is_owner then
    v_header := v_header || jsonb_build_object('adjustment_value_vnd', v_s.adjustment_value_vnd);
  end if;

  return v_header;
end;
$$;

grant execute on function inventory.get_stocktake_session(uuid, uuid) to authenticated;

-- 3.5 save_stocktake_draft
create or replace function inventory.save_stocktake_draft(
  p_tenant_id uuid,
  p_session_id uuid,
  p_line_id uuid,
  p_quantity numeric
)
returns void
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_status text;
  v_needs_recount boolean;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select s.status into v_status
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id
  for share;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  if v_status not in ('COUNTING', 'RECOUNT') then
    perform inventory._raise('STOCKTAKE_STATE_CHANGED', 'Phiên không còn ở trạng thái đếm.');
  end if;

  if p_quantity is not null and p_quantity < 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Số lượng nháp không được âm.');
  end if;

  select l.needs_recount into v_needs_recount
  from inventory.stocktake_lines l
  where l.id = p_line_id
    and l.session_id = p_session_id
    and l.tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy dòng kiểm kê.');
  end if;

  if v_status = 'RECOUNT' and not v_needs_recount then
    perform inventory._raise('CONTEXT_INVALID', 'Chỉ nhập nháp đếm lại cho dòng có chênh lệch.');
  end if;

  update inventory.stocktake_lines
  set draft_qty = p_quantity
  where id = p_line_id;
end;
$$;

grant execute on function inventory.save_stocktake_draft(uuid, uuid, uuid, numeric) to authenticated;

-- 3.6 get_stocktake_unexpected_options
create or replace function inventory.get_stocktake_unexpected_options(
  p_tenant_id uuid,
  p_session_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_s inventory.stocktake_sessions%rowtype;
  v_products jsonb := '[]'::jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select * into v_s
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  select coalesce(jsonb_agg(prod_obj order by prod_obj->>'name'), '[]'::jsonb)
  into v_products
  from (
    select jsonb_build_object(
      'id', p.id,
      'name', p.name,
      'code', p.sku,
      'uom', coalesce(catalog._product_base_unit_name(p_tenant_id, p.id), ''),
      'tracking_mode', p.tracking_mode,
      'lots', case
        when p.tracking_mode = 'lot' then
          coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'id', lt.id,
                'lot_code', lt.lot_code,
                'expiry_date', lt.expiry_date,
                'expiry_precision', lt.expiry_precision
              )
              order by lt.lot_code
            )
            from inventory.lots lt
            where lt.tenant_id = p_tenant_id
              and lt.product_id = p.id
              and not exists (
                select 1
                from inventory.stocktake_lines sl
                where sl.session_id = v_s.id
                  and sl.lot_id = lt.id
              )
          ), '[]'::jsonb)
        else
          '[]'::jsonb
      end
    ) as prod_obj
    from catalog.products p
    join inventory.product_costs pc
      on pc.tenant_id = p_tenant_id
     and pc.product_id = p.id
     and (pc.moving_avg_cost > 0 or pc.official_unit_cost is not null)
    where p.tenant_id = p_tenant_id
      and p.deleted_at is null
      and (
        v_s.scope_kind = 'ALL'
        or p.id = v_s.scope_product_id
      )
      and not (
        p.tracking_mode = 'none'
        and exists (
          select 1
          from inventory.stocktake_lines sl
          where sl.session_id = v_s.id
            and sl.product_id = p.id
        )
      )
  ) rows;

  return jsonb_build_object('products', v_products);
end;
$$;

grant execute on function inventory.get_stocktake_unexpected_options(uuid, uuid) to authenticated;

-- 3.7 add_stocktake_unexpected_line
create or replace function inventory.add_stocktake_unexpected_line(
  p_tenant_id uuid,
  p_session_id uuid,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_today date := inventory._today();
  v_s inventory.stocktake_sessions%rowtype;
  v_product_id uuid;
  v_prod record;
  v_lot_id uuid;
  v_lot_code_raw text;
  v_new_lot_code text;
  v_new_expiry_date date;
  v_new_expiry_precision text;
  v_lt record;
  v_out_lot_code text := null;
  v_out_expiry_date date := null;
  v_out_expiry_precision text := null;
  v_line_no int;
  v_line_id uuid := gen_random_uuid();
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu không hợp lệ.');
  end if;

  select * into v_s
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  if v_s.status <> 'COUNTING' then
    perform inventory._raise('STOCKTAKE_STATE_CHANGED', 'Phiên không còn ở trạng thái đếm đầu.');
  end if;

  begin
    v_product_id := (p_payload->>'product_id')::uuid;
  exception when others then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không hợp lệ.');
  end;

  if v_product_id is null then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm là bắt buộc.');
  end if;

  select p.id, p.name, p.sku, p.tracking_mode, p.expiry_required
  into v_prod
  from catalog.products p
  where p.id = v_product_id
    and p.tenant_id = p_tenant_id
    and p.deleted_at is null;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại.');
  end if;

  if v_s.scope_kind in ('PRODUCT', 'LOT') and v_product_id <> v_s.scope_product_id then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm nằm ngoài phạm vi phiên kiểm kê.');
  end if;

  if not exists (
    select 1
    from inventory.product_costs pc
    where pc.tenant_id = p_tenant_id
      and pc.product_id = v_product_id
      and (pc.moving_avg_cost > 0 or pc.official_unit_cost is not null)
  ) then
    perform inventory._raise(
      'UNIT_COST_REQUIRED',
      v_prod.name || ' chưa từng nhập kho. Lập phiếu nhận để đưa hàng vào kho.'
    );
  end if;

  v_lot_code_raw := nullif(btrim(coalesce(p_payload->>'lot_code', '')), '');
  if nullif(btrim(coalesce(p_payload->>'lot_id', '')), '') is not null then
    begin
      v_lot_id := (p_payload->>'lot_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Lô không hợp lệ.');
    end;
  end if;

  if v_prod.tracking_mode = 'none' then
    if v_lot_id is not null or v_lot_code_raw is not null then
      perform inventory._raise('LOT_NOT_ALLOWED', 'Sản phẩm không quản lý theo lô.');
    end if;
    v_lot_id := null;
    v_new_lot_code := null;
    v_new_expiry_date := null;
    v_new_expiry_precision := null;
  else
    if v_lot_id is not null then
      select lt.id, lt.lot_code, lt.expiry_date, lt.expiry_precision
      into v_lt
      from inventory.lots lt
      where lt.id = v_lot_id
        and lt.tenant_id = p_tenant_id
        and lt.product_id = v_product_id;

      if not found then
        perform inventory._raise('CONTEXT_INVALID', 'Lô không thuộc sản phẩm.');
      end if;
      v_out_lot_code := v_lt.lot_code;
      v_out_expiry_date := v_lt.expiry_date;
      v_out_expiry_precision := v_lt.expiry_precision;
      v_new_lot_code := null;
      v_new_expiry_date := null;
      v_new_expiry_precision := null;
    elsif v_lot_code_raw is not null then
      -- Match existing lot by normalized code if present
      select lt.id, lt.lot_code, lt.expiry_date, lt.expiry_precision
      into v_lt
      from inventory.lots lt
      where lt.tenant_id = p_tenant_id
        and lt.product_id = v_product_id
        and lt.lot_code_normalized = lower(v_lot_code_raw);

      if found then
        v_lot_id := v_lt.id;
        v_out_lot_code := v_lt.lot_code;
        v_out_expiry_date := v_lt.expiry_date;
        v_out_expiry_precision := v_lt.expiry_precision;
        v_new_lot_code := null;
        v_new_expiry_date := null;
        v_new_expiry_precision := null;
      else
        begin
          v_new_expiry_date := nullif(btrim(coalesce(p_payload->>'expiry_date', '')), '')::date;
        exception when others then
          perform inventory._raise('CONTEXT_INVALID', 'Hạn sử dụng không hợp lệ.');
        end;

        v_new_expiry_precision := nullif(btrim(coalesce(p_payload->>'expiry_precision', '')), '');
        if v_new_expiry_date is not null then
          v_new_expiry_precision := coalesce(v_new_expiry_precision, 'DAY');
          if v_new_expiry_precision not in ('DAY', 'MONTH', 'YEAR') then
            perform inventory._raise('CONTEXT_INVALID', 'Độ chính xác hạn dùng không hợp lệ.');
          end if;
        else
          if v_prod.expiry_required then
            perform inventory._raise('EXPIRY_REQUIRED', 'Sản phẩm bắt buộc nhập hạn sử dụng.');
          end if;
          v_new_expiry_precision := null;
        end if;
        v_new_lot_code := v_lot_code_raw;
        v_out_lot_code := v_new_lot_code;
        v_out_expiry_date := v_new_expiry_date;
        v_out_expiry_precision := v_new_expiry_precision;
      end if;
    else
      perform inventory._raise('LOT_REQUIRED', 'Sản phẩm quản lý theo lô cần chọn hoặc nhập lô.');
    end if;
  end if;

  if exists (
    select 1
    from inventory.stocktake_lines l
    where l.session_id = v_s.id
      and l.product_id = v_product_id
      and coalesce(l.lot_id::text, lower(btrim(l.new_lot_code)), '') =
          coalesce(v_lot_id::text, lower(btrim(v_new_lot_code)), '')
  ) then
    perform inventory._raise('STOCKTAKE_LINE_EXISTS', 'Mặt hàng này đã có trong phiên.');
  end if;

  select coalesce(max(l.line_no), 0) + 1
  into v_line_no
  from inventory.stocktake_lines l
  where l.session_id = v_s.id;

  insert into inventory.stocktake_lines (
    id, tenant_id, session_id, line_no, product_id, lot_id,
    new_lot_code, new_expiry_date, new_expiry_precision, is_unexpected
  ) values (
    v_line_id, p_tenant_id, v_s.id, v_line_no, v_product_id, v_lot_id,
    v_new_lot_code, v_new_expiry_date, v_new_expiry_precision, true
  );

  return jsonb_build_object(
    'line_id', v_line_id,
    'product_id', v_product_id,
    'product_name', v_prod.name,
    'product_code', v_prod.sku,
    'lot_id', v_lot_id,
    'lot_code', v_out_lot_code,
    'expiry_date', v_out_expiry_date,
    'is_expired', (
      v_out_expiry_date is not null
      and inventory._lot_expiry_end(
        v_out_expiry_date,
        v_out_expiry_precision
      ) < v_today
    ),
    'uom', coalesce(catalog._product_base_unit_name(p_tenant_id, v_product_id), ''),
    'is_unexpected', true,
    'draft_qty', null,
    'needs_recount', false,
    'loss_reason', null
  );
end;
$$;

grant execute on function inventory.add_stocktake_unexpected_line(uuid, uuid, jsonb) to authenticated;

-- 3.8 cancel_stocktake
create or replace function inventory.cancel_stocktake(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_session_id uuid,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_reason text := btrim(coalesce(p_reason, ''));
  v_status text;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stocktake.cancel',
    p_idempotency_key,
    md5(jsonb_build_object('session_id', p_session_id, 'reason', v_reason)::text)
  );

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  select s.status into v_status
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  if v_status not in ('COUNTING', 'RECOUNT') then
    perform inventory._raise('STOCKTAKE_STATE_CHANGED', 'Phiên đã kết thúc hoặc đã bị hủy.');
  end if;

  if length(v_reason) = 0 then
    perform inventory._raise('CANCEL_REASON_REQUIRED', 'Nhập lý do hủy phiên');
  end if;

  if length(v_reason) > 200 then
    perform inventory._raise('CONTEXT_INVALID', 'Lý do hủy tối đa 200 ký tự.');
  end if;

  update inventory.stocktake_sessions
  set status = 'CANCELLED',
      cancelled_at = now(),
      cancelled_by = v_actor_id,
      cancel_reason = v_reason
  where id = p_session_id;

  v_res := jsonb_build_object('status', 'CANCELLED');
  perform inventory._complete_idempotency(
    p_tenant_id,
    'stocktake.cancel',
    p_idempotency_key,
    'succeeded',
    v_res
  );
  return v_res;
end;
$$;

grant execute on function inventory.cancel_stocktake(uuid, text, uuid, text) to authenticated;

-- 3.9 submit_stocktake_first_count
create or replace function inventory.submit_stocktake_first_count(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_session_id uuid,
  p_counts jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_s inventory.stocktake_sessions%rowtype;
  v_elem jsonb;
  v_line_id uuid;
  v_qty numeric;
  v_seen uuid[] := '{}'::uuid[];
  v_missing int := 0;
  v_line record;
  v_book numeric;
  v_diff boolean;
  v_needs_recount_count int := 0;
  v_now timestamptz := now();
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_counts is null or jsonb_typeof(p_counts) <> 'array' then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách số đếm không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stocktake.first',
    p_idempotency_key,
    md5(jsonb_build_object('session_id', p_session_id, 'counts', p_counts)::text)
  );

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  select * into v_s
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  if v_s.status <> 'COUNTING' then
    perform inventory._raise('STOCKTAKE_STATE_CHANGED', 'Phiên không còn ở trạng thái đếm đầu.');
  end if;

  -- Validate supplied rows and extract counts into temporary map via loop check
  for v_elem in select * from jsonb_array_elements(p_counts)
  loop
    begin
      v_line_id := (v_elem->>'line_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Dòng kiểm kê không hợp lệ.');
    end;

    if v_line_id is null or v_line_id = any(v_seen) or not exists (
      select 1
      from inventory.stocktake_lines l
      where l.id = v_line_id
        and l.session_id = v_s.id
    ) then
      perform inventory._raise('CONTEXT_INVALID', 'Dòng kiểm kê không hợp lệ hoặc bị trùng.');
    end if;
    v_seen := array_append(v_seen, v_line_id);

    begin
      v_qty := nullif(btrim(coalesce(v_elem->>'quantity', '')), '')::numeric;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Số đếm không hợp lệ.');
    end;
  end loop;

  -- Check completeness across all session lines
  select count(*)::int
  into v_missing
  from inventory.stocktake_lines l
  left join lateral (
    select nullif(btrim(coalesce(e->>'quantity', '')), '')::numeric as qty
    from jsonb_array_elements(p_counts) e
    where (e->>'line_id')::uuid = l.id
    limit 1
  ) c on true
  where l.session_id = v_s.id
    and (c.qty is null or c.qty < 0);

  if v_missing > 0 then
    perform inventory._raise('STOCKTAKE_COUNT_MISSING', v_missing::text);
  end if;

  -- Insert round 1 counts and compare with current book
  for v_line in
    select
      l.id,
      l.product_id,
      l.lot_id,
      l.new_lot_code,
      (
        select nullif(btrim(e->>'quantity'), '')::numeric
        from jsonb_array_elements(p_counts) e
        where (e->>'line_id')::uuid = l.id
        limit 1
      ) as counted_qty
    from inventory.stocktake_lines l
    where l.session_id = v_s.id
    order by l.line_no
  loop
    insert into inventory.stocktake_counts (
      tenant_id, session_id, line_id, round, quantity, counted_by, counted_at
    ) values (
      p_tenant_id, v_s.id, v_line.id, 1, v_line.counted_qty, v_actor_id, v_now
    );

    if v_line.lot_id is null and v_line.new_lot_code is not null then
      v_book := 0;
    else
      select coalesce(sb.physical_quantity, 0)
      into v_book
      from inventory.stock_balances sb
      where sb.tenant_id = p_tenant_id
        and sb.warehouse_id = v_s.warehouse_id
        and sb.product_id = v_line.product_id
        and sb.lot_key = coalesce(v_line.lot_id, '00000000-0000-0000-0000-000000000000'::uuid);
      v_book := coalesce(v_book, 0);
    end if;

    v_diff := (v_line.counted_qty <> v_book);
    if v_diff then
      v_needs_recount_count := v_needs_recount_count + 1;
    end if;

    update inventory.stocktake_lines
    set needs_recount = v_diff,
        draft_qty = null
    where id = v_line.id;
  end loop;

  if v_needs_recount_count = 0 then
    update inventory.stocktake_sessions
    set status = 'COMPLETED',
        result_kind = 'MATCHED',
        first_submitted_at = v_now,
        completed_at = v_now,
        completed_by = v_actor_id
    where id = v_s.id;

    v_res := jsonb_build_object(
      'status', 'COMPLETED',
      'result_kind', 'MATCHED'
    );
  else
    update inventory.stocktake_sessions
    set status = 'RECOUNT',
        first_submitted_at = v_now
    where id = v_s.id;

    v_res := jsonb_build_object(
      'status', 'RECOUNT',
      'result_kind', null
    );
  end if;

  perform inventory._complete_idempotency(
    p_tenant_id,
    'stocktake.first',
    p_idempotency_key,
    'succeeded',
    v_res
  );
  return v_res;
end;
$$;

grant execute on function inventory.submit_stocktake_first_count(uuid, text, uuid, jsonb) to authenticated;

-- 3.10 submit_stocktake_recount
create or replace function inventory.submit_stocktake_recount(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_session_id uuid,
  p_counts jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_today date := inventory._today();
  v_idemp jsonb;
  v_s inventory.stocktake_sessions%rowtype;
  v_elem jsonb;
  v_line_id uuid;
  v_qty numeric;
  v_loss_reason_raw text;
  v_seen uuid[] := '{}'::uuid[];
  v_missing int := 0;
  v_prod_id uuid;
  v_line record;
  v_book numeric;
  v_delta numeric;
  v_movement_kind text;
  v_mov_reason text;
  v_line_loss_reason text;
  v_mov_elem jsonb;
  v_movement_lines jsonb := '[]'::jsonb;
  v_post_res jsonb;
  v_posted_line jsonb;
  v_total_adj_value bigint := 0;
  v_result_kind text;
  v_now timestamptz := now();
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_counts is null or jsonb_typeof(p_counts) <> 'array' then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách số đếm lại không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stocktake.recount',
    p_idempotency_key,
    md5(jsonb_build_object('session_id', p_session_id, 'counts', p_counts)::text)
  );

  if (v_idemp->>'decision') = 'replay' then
    return v_idemp->'result_snapshot';
  elsif (v_idemp->>'decision') = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  select * into v_s
  from inventory.stocktake_sessions s
  where s.id = p_session_id
    and s.tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Không tìm thấy phiên kiểm kê.');
  end if;

  if v_s.status <> 'RECOUNT' then
    perform inventory._raise('STOCKTAKE_STATE_CHANGED', 'Phiên không còn ở trạng thái đếm lại.');
  end if;

  -- Validate that p_counts only references needs_recount lines of this session
  for v_elem in select * from jsonb_array_elements(p_counts)
  loop
    begin
      v_line_id := (v_elem->>'line_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Dòng kiểm kê không hợp lệ.');
    end;

    if v_line_id is null or v_line_id = any(v_seen) or not exists (
      select 1
      from inventory.stocktake_lines l
      where l.id = v_line_id
        and l.session_id = v_s.id
        and l.needs_recount = true
    ) then
      perform inventory._raise('CONTEXT_INVALID', 'Chỉ được nộp dòng cần đếm lại thuộc phiên.');
    end if;
    v_seen := array_append(v_seen, v_line_id);

    begin
      v_qty := nullif(btrim(coalesce(v_elem->>'quantity', '')), '')::numeric;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Số đếm lại không hợp lệ.');
    end;

    v_loss_reason_raw := nullif(btrim(coalesce(v_elem->>'loss_reason', '')), '');
    if v_loss_reason_raw is not null and v_loss_reason_raw not in ('LOSS', 'DAMAGED', 'EXPIRED') then
      perform inventory._raise('CONTEXT_INVALID', 'Lý do chênh lệch không hợp lệ.');
    end if;
  end loop;

  select count(*)::int
  into v_missing
  from inventory.stocktake_lines l
  left join lateral (
    select nullif(btrim(coalesce(e->>'quantity', '')), '')::numeric as qty
    from jsonb_array_elements(p_counts) e
    where (e->>'line_id')::uuid = l.id
    limit 1
  ) c on true
  where l.session_id = v_s.id
    and l.needs_recount = true
    and (c.qty is null or c.qty < 0);

  if v_missing > 0 then
    perform inventory._raise('STOCKTAKE_COUNT_MISSING', v_missing::text);
  end if;

  -- 1. Advisory locks in product_id ascending order before reading book
  for v_prod_id in
    select distinct l.product_id
    from inventory.stocktake_lines l
    where l.session_id = v_s.id
      and l.needs_recount = true
    order by l.product_id
  loop
    perform pg_advisory_xact_lock(
      hashtext(p_tenant_id::text),
      hashtext(v_prod_id::text)
    );
  end loop;

  -- 2-3. Record round 2 counts & read locked current book
  for v_line in
    select
      l.id,
      l.product_id,
      l.lot_id,
      l.new_lot_code,
      l.new_expiry_date,
      l.new_expiry_precision,
      inp.counted_qty,
      inp.loss_reason_input
    from inventory.stocktake_lines l
    cross join lateral (
      select
        nullif(btrim(e->>'quantity'), '')::numeric as counted_qty,
        nullif(btrim(coalesce(e->>'loss_reason', '')), '') as loss_reason_input
      from jsonb_array_elements(p_counts) e
      where (e->>'line_id')::uuid = l.id
      limit 1
    ) inp
    where l.session_id = v_s.id
      and l.needs_recount = true
    order by l.line_no
  loop
    insert into inventory.stocktake_counts (
      tenant_id, session_id, line_id, round, quantity, counted_by, counted_at
    ) values (
      p_tenant_id, v_s.id, v_line.id, 2, v_line.counted_qty, v_actor_id, v_now
    );

    if v_line.lot_id is null and v_line.new_lot_code is not null then
      v_book := 0;
    else
      select coalesce(sb.physical_quantity, 0)
      into v_book
      from inventory.stock_balances sb
      where sb.tenant_id = p_tenant_id
        and sb.warehouse_id = v_s.warehouse_id
        and sb.product_id = v_line.product_id
        and sb.lot_key = coalesce(v_line.lot_id, '00000000-0000-0000-0000-000000000000'::uuid);
      v_book := coalesce(v_book, 0);
    end if;

    v_delta := v_line.counted_qty - v_book;
    v_line_loss_reason := null;

    if v_delta <> 0 then
      if v_delta > 0 then
        v_movement_kind := 'COUNT_GAIN';
        v_mov_reason := 'COUNT';
      else
        v_line_loss_reason := coalesce(v_line.loss_reason_input, 'LOSS');
        if v_line_loss_reason = 'LOSS' then
          v_movement_kind := 'COUNT_LOSS';
          v_mov_reason := 'LOSS';
        else
          v_movement_kind := 'WRITE_OFF';
          v_mov_reason := v_line_loss_reason;
        end if;
      end if;

      v_mov_elem := jsonb_build_object(
        'line_id', v_line.id,
        'product_id', v_line.product_id,
        'quantity_delta', v_delta,
        'movement_kind', v_movement_kind,
        'reason', v_mov_reason,
        'unit_cost', null
      );

      if v_line.lot_id is not null then
        v_mov_elem := v_mov_elem || jsonb_build_object('lot_id', v_line.lot_id);
      elsif v_line.new_lot_code is not null then
        v_mov_elem := v_mov_elem || jsonb_build_object(
          'lot_code', v_line.new_lot_code,
          'expiry_date', v_line.new_expiry_date,
          'expiry_precision', coalesce(v_line.new_expiry_precision, 'DAY')
        );
      end if;

      v_movement_lines := v_movement_lines || jsonb_build_array(v_mov_elem);
    end if;

    update inventory.stocktake_lines
    set draft_qty = null,
        loss_reason = v_line_loss_reason,
        book_qty_at_commit = v_book,
        adjust_qty = v_delta,
        adjust_value_vnd = case when v_delta = 0 then null else adjust_value_vnd end
    where id = v_line.id;
  end loop;

  -- 4. Post movements once (if any variance remains)
  if jsonb_array_length(v_movement_lines) > 0 then
    v_post_res := inventory._post_movements(
      p_tenant_id,
      v_s.warehouse_id,
      'STOCKTAKE',
      v_s.id,
      v_today,
      v_movement_lines,
      v_actor_id
    );

    for v_posted_line in select * from jsonb_array_elements(v_post_res->'lines')
    loop
      v_total_adj_value := v_total_adj_value + coalesce((v_posted_line->>'amount_vnd')::bigint, 0);

      update inventory.stocktake_lines l
      set adjust_value_vnd = (v_posted_line->>'amount_vnd')::bigint,
          lot_id = coalesce(l.lot_id, sm.lot_id)
      from inventory.stock_movements sm
      where l.id = (v_posted_line->>'line_id')::uuid
        and sm.id = (v_posted_line->>'movement_id')::uuid;
    end loop;

    v_result_kind := 'ADJUSTED';
    update inventory.stocktake_sessions
    set status = 'COMPLETED',
        result_kind = v_result_kind,
        completed_at = v_now,
        completed_by = v_actor_id,
        adjustment_value_vnd = v_total_adj_value,
        stock_changes = v_post_res->'stock_changes'
    where id = v_s.id;
  else
    v_result_kind := 'MATCHED';
    update inventory.stocktake_sessions
    set status = 'COMPLETED',
        result_kind = v_result_kind,
        completed_at = v_now,
        completed_by = v_actor_id
    where id = v_s.id;
  end if;

  v_res := jsonb_build_object(
    'status', 'COMPLETED',
    'result_kind', v_result_kind
  );

  perform inventory._complete_idempotency(
    p_tenant_id,
    'stocktake.recount',
    p_idempotency_key,
    'succeeded',
    v_res
  );
  return v_res;
end;
$$;

grant execute on function inventory.submit_stocktake_recount(uuid, text, uuid, jsonb) to authenticated;

