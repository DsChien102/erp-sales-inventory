-- Title: inventory supplier programs
-- Kind: schema
-- Intent: inventory_supplier_programs
-- Context: TH-07 / spec gia von muc 12.1-12.3, 12.6-12.7; PLAN T7-G5-2b
-- Touches: supplier_programs, supplier_program_products, supplier_program_tiers, supplier_program_receipts, _program_is_locked, _ensure_walk_in_supplier, _program_row_json, _validate_program_payload, list_supplier_programs, get_supplier_program, get_supplier_program_form_options, create_supplier_program, update_supplier_program, end_supplier_program, get_receipt_program_hints
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20261111001_inventory_stock_policy, 20260714001_partner_v2_schema (partners.is_system, organization_profiles.allow_blank_phone added in the same plan), 20260709005_catalog_units

create schema if not exists inventory;

-- ---------------------------------------------------------------------------
-- 1. Tables
-- ---------------------------------------------------------------------------

create table inventory.supplier_programs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  supplier_id uuid not null references partner.partners (partner_id),
  name text not null,
  kind text not null,
  status text not null default 'ACTIVE',
  started_on date not null,
  buy_qty numeric,
  free_qty numeric,
  target_qty numeric,
  rebate_percent numeric(5,2),
  progress_qty numeric not null default 0,
  reached_at timestamptz,
  ended_at timestamptz,
  note text,
  revision int not null default 1,
  created_by uuid not null,
  created_at timestamptz not null default now(),
  updated_by uuid not null,
  updated_at timestamptz not null default now(),
  constraint chk_supplier_programs_kind
    check (kind in ('TIER_DISCOUNT', 'BUY_X_GET_Y', 'VOLUME_REBATE')),
  constraint chk_supplier_programs_status
    check (status in ('ACTIVE', 'REACHED', 'RECORDED', 'ENDED')),
  constraint chk_supplier_programs_reached_only_volume
    check (status not in ('REACHED', 'RECORDED') or kind = 'VOLUME_REBATE'),
  constraint chk_supplier_programs_name
    check (length(btrim(name)) between 1 and 120),
  constraint chk_supplier_programs_params check (
    case kind
      when 'TIER_DISCOUNT' then
        buy_qty is null and free_qty is null and target_qty is null and rebate_percent is null
      when 'BUY_X_GET_Y' then
        buy_qty > 0 and free_qty > 0 and target_qty is null and rebate_percent is null
      when 'VOLUME_REBATE' then
        target_qty > 0 and rebate_percent > 0 and rebate_percent <= 100
        and buy_qty is null and free_qty is null
      else false
    end
  )
);

create unique index supplier_programs_one_effective_per_supplier
  on inventory.supplier_programs (tenant_id, supplier_id)
  where status in ('ACTIVE','REACHED');

create index supplier_programs_tenant_status_idx
  on inventory.supplier_programs (tenant_id, status, created_at desc);

create table inventory.supplier_program_products (
  program_id uuid not null references inventory.supplier_programs (id) on delete cascade,
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  primary key (program_id, product_id)
);

create index supplier_program_products_product_idx
  on inventory.supplier_program_products (tenant_id, product_id);

create table inventory.supplier_program_tiers (
  program_id uuid not null references inventory.supplier_programs (id) on delete cascade,
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  min_qty numeric not null check (min_qty > 0),
  discount_percent numeric(5,2) not null check (discount_percent > 0 and discount_percent <= 100),
  constraint supplier_program_tiers_program_min_key unique (program_id, min_qty)
);

create table inventory.supplier_program_receipts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  program_id uuid not null references inventory.supplier_programs (id) on delete cascade,
  receipt_line_id uuid not null,
  paid_qty numeric not null,
  purchase_amount_vnd bigint not null,
  created_at timestamptz not null default now(),
  constraint supplier_program_receipts_program_line_key unique (program_id, receipt_line_id)
);

alter table inventory.supplier_programs enable row level security;
alter table inventory.supplier_program_products enable row level security;
alter table inventory.supplier_program_tiers enable row level security;
alter table inventory.supplier_program_receipts enable row level security;

revoke all on inventory.supplier_programs from public, anon, authenticated;
revoke all on inventory.supplier_program_products from public, anon, authenticated;
revoke all on inventory.supplier_program_tiers from public, anon, authenticated;
revoke all on inventory.supplier_program_receipts from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. Helpers (internal)
-- ---------------------------------------------------------------------------

create or replace function inventory._program_is_locked(p_program_id uuid)
returns boolean
language sql
stable
security definer
set search_path = inventory, pg_temp
as $$
  select exists (
    select 1
    from inventory.supplier_program_receipts r
    where r.program_id = p_program_id
  );
$$;

revoke all on function inventory._program_is_locked(uuid) from public, anon, authenticated;

create or replace function inventory._effective_receipt_program(
  p_tenant_id uuid,
  p_supplier_id uuid,
  p_product_id uuid
)
returns inventory.supplier_programs
language plpgsql
stable
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_prog inventory.supplier_programs%rowtype;
begin
  select sp.* into v_prog
  from inventory.supplier_programs sp
  join inventory.supplier_program_products spp on spp.program_id = sp.id
  where sp.tenant_id = p_tenant_id
    and sp.supplier_id = p_supplier_id
    and sp.status = 'ACTIVE'
    and sp.started_on <= inventory._today()
    and spp.product_id = p_product_id
  limit 1;

  if not found then
    return null;
  end if;
  return v_prog;
end;
$$;

revoke all on function inventory._effective_receipt_program(uuid, uuid, uuid) from public, anon, authenticated;

create or replace function inventory._ensure_walk_in_supplier(p_tenant_id uuid)
returns uuid
language plpgsql
security definer
set search_path = inventory, partner, pg_temp
as $$
declare
  v_id uuid;
  v_actor uuid := auth.uid();
begin
  select p.partner_id
  into v_id
  from partner.partners p
  where p.tenant_id = p_tenant_id
    and p.is_system
  limit 1;

  if v_id is not null then
    return v_id;
  end if;

  insert into partner.partners (
    tenant_id, partner_type, display_name, is_system, created_by, updated_by
  ) values (
    p_tenant_id, 'organization'::partner.partner_type, 'Mua lẻ / khác', true, v_actor, v_actor
  )
  returning partner_id into v_id;

  insert into partner.organization_profiles (
    partner_id, tenant_id, organization_type, organization_name, phone, allow_blank_phone
  ) values (
    v_id, p_tenant_id, 'other'::partner.organization_type, 'Mua lẻ / khác', '', true
  );

  insert into partner.partner_roles (partner_id, tenant_id, role)
  values (v_id, p_tenant_id, 'supplier'::partner.partner_role_type);

  return v_id;
end;
$$;

revoke all on function inventory._ensure_walk_in_supplier(uuid) from public, anon, authenticated;

-- ProgramRow json
create or replace function inventory._program_row_json(
  p_tenant_id uuid,
  p_program_id uuid
)
returns jsonb
language sql
stable
security definer
set search_path = inventory, partner, catalog, pg_temp
as $$
  select jsonb_build_object(
    'program_id', sp.id,
    'name', sp.name,
    'kind', sp.kind,
    'status', sp.status,
    'supplier_id', sp.supplier_id,
    'supplier_name', coalesce(pt.display_name, ''),
    'started_on', sp.started_on,
    'product_ids', coalesce((
      select jsonb_agg(spp.product_id order by spp.product_id)
      from inventory.supplier_program_products spp
      where spp.program_id = sp.id
    ), '[]'::jsonb),
    'product_count', (
      select count(*)
      from inventory.supplier_program_products spp
      where spp.program_id = sp.id
    ),
    'common_uom', (
      select case
        when count(*) > 0 and count(x.u) = count(*) and count(distinct x.u) = 1 then min(x.u)
        else null
      end
      from (
        select catalog._product_base_unit_name(sp.tenant_id, spp.product_id) as u
        from inventory.supplier_program_products spp
        where spp.program_id = sp.id
      ) x
    ),
    'tiers', coalesce((
      select jsonb_agg(
        jsonb_build_object('min_qty', t.min_qty, 'discount_percent', t.discount_percent)
        order by t.min_qty
      )
      from inventory.supplier_program_tiers t
      where t.program_id = sp.id
    ), '[]'::jsonb),
    'buy_qty', sp.buy_qty,
    'free_qty', sp.free_qty,
    'target_qty', sp.target_qty,
    'rebate_percent', sp.rebate_percent,
    'progress_qty', sp.progress_qty
  )
  from inventory.supplier_programs sp
  left join partner.partners pt on pt.partner_id = sp.supplier_id
  where sp.id = p_program_id
    and sp.tenant_id = p_tenant_id;
$$;

revoke all on function inventory._program_row_json(uuid, uuid) from public, anon, authenticated;

-- Shared validation for create / update (everything except supplier and overlap)
create or replace function inventory._validate_program_payload(
  p_tenant_id uuid,
  p_kind text,
  p_payload jsonb
)
returns void
language plpgsql
stable
security definer
set search_path = inventory, catalog, pg_temp
as $$
declare
  v_name text := btrim(coalesce(p_payload->>'name', ''));
  v_product_ids uuid[];
  v_count int;
  v_valid int;
  v_uom_count int;
  v_started date;
  v_today date := inventory._today();
  v_tiers jsonb := coalesce(p_payload->'tiers', '[]'::jsonb);
  v_tier jsonb;
  v_prev_qty numeric := null;
  v_prev_pct numeric := null;
  v_qty numeric;
  v_pct numeric;
  v_n numeric;
  v_m numeric;
begin
  if length(v_name) < 1 or length(v_name) > 120 then
    perform inventory._raise('CONTEXT_INVALID', 'Tên chương trình phải từ 1 đến 120 ký tự.');
  end if;

  -- products
  begin
    select coalesce(array_agg(distinct e::uuid), array[]::uuid[])
    into v_product_ids
    from jsonb_array_elements_text(coalesce(p_payload->'product_ids', '[]'::jsonb)) e;
  exception when others then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách sản phẩm không hợp lệ.');
  end;

  v_count := cardinality(v_product_ids);
  select count(*)
  into v_valid
  from catalog.products p
  where p.tenant_id = p_tenant_id
    and p.id = any(v_product_ids)
    and p.deleted_at is null
    and p.business_status = 'active';

  if v_count < 1 or v_valid <> v_count then
    perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại, đã ngừng hoặc không thuộc cửa hàng.');
  end if;

  if p_kind = 'BUY_X_GET_Y' and v_count <> 1 then
    perform inventory._raise('CONTEXT_INVALID', 'Mua X tặng Y chỉ áp cho một sản phẩm.');
  end if;

  if p_kind = 'VOLUME_REBATE' then
    if exists (
      select 1 from unnest(v_product_ids) pid
      where catalog._product_base_unit_name(p_tenant_id, pid) is null
    ) then
      perform inventory._raise('PROGRAM_UOM_MISMATCH', 'Các sản phẩm phải cùng đơn vị tính cơ sở.');
    end if;

    select count(distinct lower(catalog._product_base_unit_name(p_tenant_id, pid)))
    into v_uom_count
    from unnest(v_product_ids) pid;
    if v_uom_count > 1 then
      perform inventory._raise('PROGRAM_UOM_MISMATCH', 'Các sản phẩm phải cùng đơn vị tính cơ sở.');
    end if;
  end if;

  -- parameters by kind
  if p_kind = 'TIER_DISCOUNT' then
    if jsonb_typeof(v_tiers) <> 'array'
       or jsonb_array_length(v_tiers) < 1
       or jsonb_array_length(v_tiers) > 5 then
      perform inventory._raise('CONTEXT_INVALID', 'Cần từ 1 đến 5 bậc giảm giá.');
    end if;
    for v_tier in select * from jsonb_array_elements(v_tiers)
    loop
      begin
        v_qty := (v_tier->>'min_qty')::numeric;
        v_pct := round((v_tier->>'discount_percent')::numeric, 2);
      exception when others then
        perform inventory._raise('CONTEXT_INVALID', 'Bậc giảm giá không hợp lệ.');
      end;
      if v_qty is null or v_pct is null or v_qty <= 0 or v_pct <= 0 or v_pct > 100 then
        perform inventory._raise('CONTEXT_INVALID', 'Bậc giảm giá không hợp lệ.');
      end if;
      if v_prev_qty is not null and (v_qty <= v_prev_qty or v_pct <= v_prev_pct) then
        perform inventory._raise('CONTEXT_INVALID', 'Số lượng và mức giảm của các bậc phải tăng dần.');
      end if;
      v_prev_qty := v_qty;
      v_prev_pct := v_pct;
    end loop;
  elsif p_kind = 'BUY_X_GET_Y' then
    begin
      v_n := (p_payload->>'buy_qty')::numeric;
      v_m := (p_payload->>'free_qty')::numeric;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Số lượng mua / tặng không hợp lệ.');
    end;
    if v_n is null or v_m is null or v_n <= 0 or v_m <= 0 then
      perform inventory._raise('CONTEXT_INVALID', 'Số lượng mua / tặng phải lớn hơn 0.');
    end if;
  elsif p_kind = 'VOLUME_REBATE' then
    begin
      v_n := (p_payload->>'target_qty')::numeric;
      v_m := round((p_payload->>'rebate_percent')::numeric, 2);
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Mốc hoặc % chiết khấu không hợp lệ.');
    end;
    if v_n is null or v_m is null or v_n <= 0 or v_m <= 0 or v_m > 100 then
      perform inventory._raise('CONTEXT_INVALID', 'Mốc hoặc % chiết khấu không hợp lệ.');
    end if;
  else
    perform inventory._raise('CONTEXT_INVALID', 'Loại ưu đãi không hợp lệ.');
  end if;

  -- started_on
  begin
    v_started := coalesce((p_payload->>'started_on')::date, v_today);
  exception when others then
    perform inventory._raise('CONTEXT_INVALID', 'Ngày bắt đầu không hợp lệ.');
  end;
  if v_started < v_today - 365 or v_started > v_today + 365 then
    perform inventory._raise('CONTEXT_INVALID', 'Ngày bắt đầu phải trong vòng một năm so với hôm nay.');
  end if;
end;
$$;

revoke all on function inventory._validate_program_payload(uuid, text, jsonb) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. Read RPCs
-- ---------------------------------------------------------------------------

create or replace function inventory.list_supplier_programs(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_programs jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select coalesce(
    jsonb_agg(
      inventory._program_row_json(p_tenant_id, sp.id)
      order by array_position(array['ACTIVE','REACHED','RECORDED','ENDED'], sp.status), sp.created_at desc
    ),
    '[]'::jsonb
  )
  into v_programs
  from inventory.supplier_programs sp
  where sp.tenant_id = p_tenant_id;

  return jsonb_build_object('programs', v_programs);
end;
$$;

grant execute on function inventory.list_supplier_programs(uuid) to authenticated;

create or replace function inventory.get_supplier_program(
  p_tenant_id uuid,
  p_program_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_sp inventory.supplier_programs%rowtype;
  v_row jsonb;
  v_products jsonb;
  v_receipts jsonb;
  v_base bigint;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select * into v_sp
  from inventory.supplier_programs
  where id = p_program_id
    and tenant_id = p_tenant_id;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình không tồn tại.');
  end if;

  v_row := inventory._program_row_json(p_tenant_id, p_program_id)
    || jsonb_build_object(
      'note', v_sp.note,
      'revision', v_sp.revision,
      'is_locked', inventory._program_is_locked(p_program_id),
      'reached_at', v_sp.reached_at,
      'ended_at', v_sp.ended_at,
      'created_at', v_sp.created_at
    );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', p.id,
        'name', p.name,
        'code', coalesce(p.sku, ''),
        'base_uom', catalog._product_base_unit_name(p_tenant_id, p.id)
      ) order by p.name
    ),
    '[]'::jsonb
  )
  into v_products
  from inventory.supplier_program_products spp
  join catalog.products p on p.id = spp.product_id
  where spp.program_id = p_program_id;

  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'receipt_line_id', r.receipt_line_id,
          'paid_qty', r.paid_qty,
          'purchase_amount_vnd', r.purchase_amount_vnd,
          'created_at', r.created_at
        ) order by r.created_at
      ),
      '[]'::jsonb
    ),
    coalesce(sum(r.purchase_amount_vnd), 0)::bigint
  into v_receipts, v_base
  from inventory.supplier_program_receipts r
  where r.program_id = p_program_id;

  return jsonb_build_object(
    'program', v_row,
    'products', v_products,
    'receipts', v_receipts,
    'base_amount_vnd', v_base
  );
end;
$$;

grant execute on function inventory.get_supplier_program(uuid, uuid) to authenticated;

create or replace function inventory.get_supplier_program_form_options(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_suppliers jsonb;
  v_products jsonb;
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'partner_id', s.partner_id,
        'display_name', s.display_name,
        'active_program', (
          select jsonb_build_object('program_id', sp.id, 'name', sp.name)
          from inventory.supplier_programs sp
          where sp.tenant_id = p_tenant_id
            and sp.supplier_id = s.partner_id
            and sp.status in ('ACTIVE','REACHED')
          limit 1
        )
      ) order by s.display_name
    ),
    '[]'::jsonb
  )
  into v_suppliers
  from partner.partners s
  where s.tenant_id = p_tenant_id
    and s.status = 'active'
    and not s.is_system
    and exists (
      select 1
      from partner.partner_roles r
      where r.partner_id = s.partner_id
        and r.role = 'supplier'
        and r.is_active
    );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', p.id,
        'name', p.name,
        'code', coalesce(p.sku, ''),
        'base_unit_id', bu.id,
        'base_uom', bu.unit_name
      ) order by p.name
    ),
    '[]'::jsonb
  )
  into v_products
  from catalog.products p
  left join lateral (
    select pu.id, pu.unit_name
    from catalog.product_units pu
    where pu.tenant_id = p_tenant_id
      and pu.product_id = p.id
      and pu.is_base_unit
      and pu.is_active
    limit 1
  ) bu on true
  where p.tenant_id = p_tenant_id
    and p.deleted_at is null
    and p.business_status = 'active';

  return jsonb_build_object('suppliers', v_suppliers, 'products', v_products);
end;
$$;

grant execute on function inventory.get_supplier_program_form_options(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- 4. Write RPCs
-- ---------------------------------------------------------------------------

create or replace function inventory.create_supplier_program(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_supplier_id uuid;
  v_kind text := p_payload->>'kind';
  v_started date;
  v_program_id uuid;
  v_tier jsonb;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu chương trình không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'supplier_program.create',
    p_idempotency_key,
    md5(p_payload::text)
  );

  if v_idemp->>'decision' = 'replay' then
    return v_idemp->'result_snapshot';
  elsif v_idemp->>'decision' = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  if v_kind is null or v_kind not in ('TIER_DISCOUNT', 'BUY_X_GET_Y', 'VOLUME_REBATE') then
    perform inventory._raise('CONTEXT_INVALID', 'Loại ưu đãi không hợp lệ.');
  end if;

  begin
    v_supplier_id := (p_payload->>'supplier_id')::uuid;
  exception when others then
    v_supplier_id := null;
  end;

  if v_supplier_id is null or not exists (
    select 1
    from partner.partners s
    where s.partner_id = v_supplier_id
      and s.tenant_id = p_tenant_id
      and s.status = 'active'
      and not s.is_system
      and exists (
        select 1 from partner.partner_roles r
        where r.partner_id = s.partner_id and r.role = 'supplier' and r.is_active
      )
  ) then
    perform inventory._raise('PROGRAM_SUPPLIER_INVALID', 'Nhà cung cấp không hợp lệ hoặc đã ngừng hoạt động.');
  end if;

  perform inventory._validate_program_payload(p_tenant_id, v_kind, p_payload);
  v_started := coalesce((p_payload->>'started_on')::date, inventory._today());

  perform pg_advisory_xact_lock(
    hashtextextended(p_tenant_id::text || ':supplier_program:' || v_supplier_id::text, 0)
  );

  if exists (
    select 1
    from inventory.supplier_programs sp
    where sp.tenant_id = p_tenant_id
      and sp.supplier_id = v_supplier_id
      and sp.status in ('ACTIVE','REACHED')
  ) then
    perform inventory._raise('PROGRAM_OVERLAP', 'NCC này đang có chương trình khác đang chạy.');
  end if;

  begin
    insert into inventory.supplier_programs (
      tenant_id, supplier_id, name, kind, started_on, note,
      buy_qty, free_qty, target_qty, rebate_percent,
      created_by, updated_by
    ) values (
      p_tenant_id, v_supplier_id, btrim(p_payload->>'name'), v_kind, v_started,
      nullif(btrim(coalesce(p_payload->>'note', '')), ''),
      case when v_kind = 'BUY_X_GET_Y' then (p_payload->>'buy_qty')::numeric end,
      case when v_kind = 'BUY_X_GET_Y' then (p_payload->>'free_qty')::numeric end,
      case when v_kind = 'VOLUME_REBATE' then (p_payload->>'target_qty')::numeric end,
      case when v_kind = 'VOLUME_REBATE' then round((p_payload->>'rebate_percent')::numeric, 2) end,
      v_actor_id, v_actor_id
    )
    returning id into v_program_id;
  exception
    when unique_violation then
      perform inventory._raise('PROGRAM_OVERLAP', 'NCC này đang có chương trình khác đang chạy.');
  end;

  insert into inventory.supplier_program_products (program_id, tenant_id, product_id)
  select v_program_id, p_tenant_id, e::uuid
  from jsonb_array_elements_text(p_payload->'product_ids') e
  group by e;

  if v_kind = 'TIER_DISCOUNT' then
    for v_tier in select * from jsonb_array_elements(p_payload->'tiers')
    loop
      insert into inventory.supplier_program_tiers (program_id, tenant_id, min_qty, discount_percent)
      values (
        v_program_id, p_tenant_id,
        (v_tier->>'min_qty')::numeric,
        round((v_tier->>'discount_percent')::numeric, 2)
      );
    end loop;
  end if;

  v_res := jsonb_build_object('program_id', v_program_id, 'revision', 1);

  perform inventory._complete_idempotency(
    p_tenant_id, 'supplier_program.create', p_idempotency_key, 'succeeded', v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.create_supplier_program(uuid, text, jsonb) to authenticated;

create or replace function inventory.update_supplier_program(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_program_id uuid,
  p_expected_revision int,
  p_payload jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_sp inventory.supplier_programs%rowtype;
  v_started date;
  v_tier jsonb;
  v_new_revision int;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    perform inventory._raise('CONTEXT_INVALID', 'Dữ liệu chương trình không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'supplier_program.update',
    p_idempotency_key,
    md5(p_program_id::text || ':' || coalesce(p_expected_revision::text, '') || ':' || p_payload::text)
  );

  if v_idemp->>'decision' = 'replay' then
    return v_idemp->'result_snapshot';
  elsif v_idemp->>'decision' = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  select * into v_sp
  from inventory.supplier_programs
  where id = p_program_id
    and tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình không tồn tại.');
  end if;

  if (p_payload ? 'supplier_id' and p_payload->>'supplier_id' is distinct from v_sp.supplier_id::text)
     or (p_payload ? 'kind' and p_payload->>'kind' is distinct from v_sp.kind) then
    perform inventory._raise('CONTEXT_INVALID', 'Không đổi được nhà cung cấp hoặc loại ưu đãi.');
  end if;

  if v_sp.status not in ('ACTIVE', 'REACHED') or inventory._program_is_locked(p_program_id) then
    perform inventory._raise('PROGRAM_LOCKED', 'Chương trình đã có phiếu nhận gắn hoặc đã kết thúc nên không sửa được.');
  end if;

  if v_sp.revision is distinct from p_expected_revision then
    perform inventory._raise('VERSION_CONFLICT', 'Chương trình đã được sửa ở nơi khác.');
  end if;

  perform inventory._validate_program_payload(p_tenant_id, v_sp.kind, p_payload);
  v_started := coalesce((p_payload->>'started_on')::date, inventory._today());
  v_new_revision := v_sp.revision + 1;

  update inventory.supplier_programs
  set name = btrim(p_payload->>'name'),
      started_on = v_started,
      note = nullif(btrim(coalesce(p_payload->>'note', '')), ''),
      buy_qty = case when v_sp.kind = 'BUY_X_GET_Y' then (p_payload->>'buy_qty')::numeric end,
      free_qty = case when v_sp.kind = 'BUY_X_GET_Y' then (p_payload->>'free_qty')::numeric end,
      target_qty = case when v_sp.kind = 'VOLUME_REBATE' then (p_payload->>'target_qty')::numeric end,
      rebate_percent = case when v_sp.kind = 'VOLUME_REBATE' then round((p_payload->>'rebate_percent')::numeric, 2) end,
      revision = v_new_revision,
      updated_by = v_actor_id,
      updated_at = now()
  where id = p_program_id;

  delete from inventory.supplier_program_products where program_id = p_program_id;
  delete from inventory.supplier_program_tiers where program_id = p_program_id;

  insert into inventory.supplier_program_products (program_id, tenant_id, product_id)
  select p_program_id, p_tenant_id, e::uuid
  from jsonb_array_elements_text(p_payload->'product_ids') e
  group by e;

  if v_sp.kind = 'TIER_DISCOUNT' then
    for v_tier in select * from jsonb_array_elements(p_payload->'tiers')
    loop
      insert into inventory.supplier_program_tiers (program_id, tenant_id, min_qty, discount_percent)
      values (
        p_program_id, p_tenant_id,
        (v_tier->>'min_qty')::numeric,
        round((v_tier->>'discount_percent')::numeric, 2)
      );
    end loop;
  end if;

  v_res := jsonb_build_object('program_id', p_program_id, 'revision', v_new_revision);

  perform inventory._complete_idempotency(
    p_tenant_id, 'supplier_program.update', p_idempotency_key, 'succeeded', v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.update_supplier_program(uuid, text, uuid, int, jsonb) to authenticated;

create or replace function inventory.end_supplier_program(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_program_id uuid,
  p_expected_revision int
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_sp inventory.supplier_programs%rowtype;
  v_new_revision int;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_actor_id := (v_actor->>'actor_id')::uuid;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'supplier_program.end',
    p_idempotency_key,
    md5(p_program_id::text || ':' || coalesce(p_expected_revision::text, ''))
  );

  if v_idemp->>'decision' = 'replay' then
    return v_idemp->'result_snapshot';
  elsif v_idemp->>'decision' = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  select * into v_sp
  from inventory.supplier_programs
  where id = p_program_id
    and tenant_id = p_tenant_id
  for update;

  if not found then
    perform inventory._raise('CONTEXT_INVALID', 'Chương trình không tồn tại.');
  end if;

  if v_sp.status not in ('ACTIVE', 'REACHED') then
    perform inventory._raise('PROGRAM_LOCKED', 'Chương trình đã kết thúc hoặc đã ghi nhận.');
  end if;

  if v_sp.revision is distinct from p_expected_revision then
    perform inventory._raise('VERSION_CONFLICT', 'Chương trình đã được sửa ở nơi khác.');
  end if;

  v_new_revision := v_sp.revision + 1;

  update inventory.supplier_programs
  set status = 'ENDED',
      ended_at = now(),
      revision = v_new_revision,
      updated_by = v_actor_id,
      updated_at = now()
  where id = p_program_id;

  v_res := jsonb_build_object(
    'program_id', p_program_id,
    'status', 'ENDED',
    'revision', v_new_revision
  );

  perform inventory._complete_idempotency(
    p_tenant_id, 'supplier_program.end', p_idempotency_key, 'succeeded', v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.end_supplier_program(uuid, text, uuid, int) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Hints for receipt lines (used by G5-3)
-- ---------------------------------------------------------------------------

create or replace function inventory.get_receipt_program_hints(
  p_tenant_id uuid,
  p_supplier_id uuid,
  p_lines jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = inventory, iam, catalog, partner, pg_temp
as $$
declare
  v_line jsonb;
  v_product_id uuid;
  v_paid numeric;
  v_price numeric;
  v_prog inventory.supplier_programs%rowtype;
  v_tier record;
  v_next record;
  v_hint jsonb;
  v_tier_json jsonb;
  v_next_json jsonb;
  v_free numeric;
  v_out jsonb := '[]'::jsonb;
  v_today date := inventory._today();
begin
  perform inventory._assert_actor(p_tenant_id, 'inventory.read');

  if p_lines is null or jsonb_typeof(p_lines) <> 'array' then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách dòng không hợp lệ.');
  end if;

  for v_line in select * from jsonb_array_elements(p_lines)
  loop
    v_hint := null;
    begin
      v_product_id := (v_line->>'product_id')::uuid;
      v_paid := coalesce((v_line->>'paid_qty')::numeric, 0);
      v_price := coalesce((v_line->>'unit_price')::numeric, 0);
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Dòng phiếu không hợp lệ.');
    end;

    v_prog := inventory._effective_receipt_program(p_tenant_id, p_supplier_id, v_product_id);

    if v_prog.id is not null then
      v_tier_json := null;
      v_next_json := null;
      v_free := null;

      if v_prog.kind = 'TIER_DISCOUNT' then
        select t.min_qty, t.discount_percent into v_tier
        from inventory.supplier_program_tiers t
        where t.program_id = v_prog.id and t.min_qty <= v_paid
        order by t.min_qty desc
        limit 1;
        if found then
          v_tier_json := jsonb_build_object(
            'min_qty', v_tier.min_qty,
            'discount_percent', v_tier.discount_percent,
            'discount_vnd', round(v_paid * v_price * v_tier.discount_percent / 100)::bigint
          );
        end if;

        select t.min_qty, t.discount_percent into v_next
        from inventory.supplier_program_tiers t
        where t.program_id = v_prog.id and t.min_qty > v_paid
        order by t.min_qty asc
        limit 1;
        if found then
          v_next_json := jsonb_build_object(
            'min_qty', v_next.min_qty,
            'discount_percent', v_next.discount_percent,
            'missing_qty', v_next.min_qty - v_paid
          );
        end if;

        v_hint := jsonb_build_object(
          'program_id', v_prog.id, 'program_name', v_prog.name, 'kind', v_prog.kind,
          'tier', v_tier_json, 'next_tier', v_next_json,
          'suggested_free_qty', null, 'rebate', null
        );
      elsif v_prog.kind = 'BUY_X_GET_Y' then
        v_free := floor(v_paid / v_prog.buy_qty) * v_prog.free_qty;
        v_hint := jsonb_build_object(
          'program_id', v_prog.id, 'program_name', v_prog.name, 'kind', v_prog.kind,
          'tier', null, 'next_tier', null,
          'buy_qty', v_prog.buy_qty, 'free_qty', v_prog.free_qty,
          'suggested_free_qty', v_free, 'rebate', null
        );
      else
        v_hint := jsonb_build_object(
          'program_id', v_prog.id, 'program_name', v_prog.name, 'kind', v_prog.kind,
          'tier', null, 'next_tier', null, 'suggested_free_qty', null,
          'rebate', jsonb_build_object(
            'progress_qty', v_prog.progress_qty,
            'target_qty', v_prog.target_qty,
            'would_reach', (v_prog.progress_qty + v_paid >= v_prog.target_qty)
          )
        );
      end if;
    end if;

    v_out := v_out || jsonb_build_array(
      jsonb_build_object('product_id', v_product_id, 'hint', v_hint)
    );
  end loop;

  return jsonb_build_object('lines', v_out);
end;
$$;

grant execute on function inventory.get_receipt_program_hints(uuid, uuid, jsonb) to authenticated;

