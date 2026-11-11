-- Title: inventory stock policy and alerts
-- Kind: schema
-- Intent: inventory_stock_policy
-- Context: TH-07 / CAP-01; PLAN T7-G5-2a
-- Touches: stock_policy_settings, product_stock_policies, _today, _lot_expiry_end, _near_expiry_days, _product_stock_rows, get_stock_policy, save_stock_thresholds, save_near_expiry_policy
-- Safety: one-shot ; low lock impact on new tables
-- Depends on: 20261110001_inventory_core, 20260709006_catalog_basic_stock

create schema if not exists inventory;

-- 1. stock_policy_settings table
create table inventory.stock_policy_settings (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  near_expiry_days int null check (near_expiry_days is null or near_expiry_days > 0),
  revision int not null default 0,
  updated_at timestamptz not null default now(),
  updated_by uuid not null
);

alter table inventory.stock_policy_settings enable row level security;
revoke all on inventory.stock_policy_settings from public, anon, authenticated;

-- 2. product_stock_policies table
create table inventory.product_stock_policies (
  tenant_id uuid not null references iam.tenants (id) on delete cascade,
  product_id uuid not null references catalog.products (id) on delete cascade,
  reorder_threshold numeric null,
  target_level numeric null,
  near_expiry_days int null check (near_expiry_days is null or near_expiry_days > 0),
  updated_at timestamptz not null default now(),
  updated_by uuid not null,
  primary key (tenant_id, product_id),
  constraint chk_product_stock_policies_threshold_target_nullity check (
    (reorder_threshold is null) = (target_level is null)
  ),
  constraint chk_product_stock_policies_threshold_target_values check (
    reorder_threshold is null or (
      reorder_threshold >= 0
      and target_level >= reorder_threshold
      and reorder_threshold = trunc(reorder_threshold)
      and target_level = trunc(target_level)
    )
  )
);

alter table inventory.product_stock_policies enable row level security;
revoke all on inventory.product_stock_policies from public, anon, authenticated;

-- 3. _today helper
create or replace function inventory._today()
returns date
language sql
stable
security definer
set search_path = pg_temp
as $$
  select (now() at time zone 'Asia/Ho_Chi_Minh')::date;
$$;

revoke all on function inventory._today() from public, anon, authenticated;

-- 4. _lot_expiry_end helper
create or replace function inventory._lot_expiry_end(
  p_expiry date,
  p_precision text
)
returns date
language plpgsql
immutable
security definer
set search_path = pg_temp
as $$
begin
  if p_expiry is null then
    return null;
  end if;

  case coalesce(nullif(trim(p_precision), ''), 'DAY')
    when 'DAY' then
      return p_expiry;
    when 'MONTH' then
      return (date_trunc('month', p_expiry) + interval '1 month - 1 day')::date;
    when 'YEAR' then
      return make_date(extract(year from p_expiry)::int, 12, 31);
    else
      return p_expiry;
  end case;
end;
$$;

revoke all on function inventory._lot_expiry_end(date, text) from public, anon, authenticated;

-- 5. _near_expiry_days helper
create or replace function inventory._near_expiry_days(
  p_tenant_id uuid,
  p_product_id uuid
)
returns int
language plpgsql
stable
security definer
set search_path = inventory, pg_temp
as $$
declare
  v_days int;
begin
  select near_expiry_days into v_days
  from inventory.product_stock_policies
  where tenant_id = p_tenant_id
    and product_id = p_product_id;

  if v_days is not null then
    return v_days;
  end if;

  select near_expiry_days into v_days
  from inventory.stock_policy_settings
  where tenant_id = p_tenant_id;

  return v_days;
end;
$$;

revoke all on function inventory._near_expiry_days(uuid, uuid) from public, anon, authenticated;

-- 6. _product_stock_rows helper
create or replace function inventory._product_stock_rows(
  p_tenant_id uuid,
  p_product_ids uuid[] default null
)
returns table (
  product_id uuid,
  physical numeric,
  available numeric,
  has_expired boolean,
  has_near_expiry boolean,
  nearest_expiry date
)
language plpgsql
stable
security definer
set search_path = inventory, catalog, pg_temp
as $$
declare
  v_today date := inventory._today();
begin
  return query
  with active_products as (
    select p.id as p_id
    from catalog.products p
    where p.tenant_id = p_tenant_id
      and p.deleted_at is null
      and p.business_status = 'active'
      and (p_product_ids is null or p.id = any(p_product_ids))
  ),
  lot_balances as (
    select
      sb.product_id as p_id,
      sb.lot_key,
      sum(sb.physical_quantity) as lot_physical,
      inventory._lot_expiry_end(l.expiry_date, l.expiry_precision) as expiry_end,
      inventory._near_expiry_days(p_tenant_id, sb.product_id) as near_days
    from inventory.stock_balances sb
    left join inventory.lots l
      on l.tenant_id = sb.tenant_id
     and l.id = sb.lot_key
    where sb.tenant_id = p_tenant_id
    group by sb.product_id, sb.lot_key, l.expiry_date, l.expiry_precision
  ),
  lot_evaluated as (
    select
      lb.p_id,
      lb.lot_physical,
      lb.expiry_end,
      case
        when lb.lot_physical > 0 and lb.expiry_end is not null and lb.expiry_end < v_today
          then true
        else false
      end as is_expired,
      case
        when lb.lot_physical > 0
         and (lb.expiry_end is null or lb.expiry_end >= v_today)
         and lb.near_days is not null
         and lb.expiry_end is not null
         and (lb.expiry_end - v_today) <= lb.near_days
          then true
        else false
      end as is_near_expiry
    from lot_balances lb
  ),
  aggregated as (
    select
      le.p_id,
      coalesce(sum(le.lot_physical), 0) as total_physical,
      coalesce(sum(case when le.is_expired then le.lot_physical else 0 end), 0) as expired_physical,
      coalesce(bool_or(le.is_expired), false) as any_expired,
      coalesce(bool_or(le.is_near_expiry), false) as any_near_expiry,
      min(case when le.lot_physical > 0 then le.expiry_end else null end) as min_expiry
    from lot_evaluated le
    group by le.p_id
  )
  select
    ap.p_id as product_id,
    coalesce(agg.total_physical, 0)::numeric as physical,
    (coalesce(agg.total_physical, 0) - coalesce(agg.expired_physical, 0))::numeric as available,
    coalesce(agg.any_expired, false) as has_expired,
    coalesce(agg.any_near_expiry, false) as has_near_expiry,
    agg.min_expiry as nearest_expiry
  from active_products ap
  left join aggregated agg on agg.p_id = ap.p_id;
end;
$$;

revoke all on function inventory._product_stock_rows(uuid, uuid[]) from public, anon, authenticated;

-- 7. get_stock_policy RPC
create or replace function inventory.get_stock_policy(p_tenant_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_is_owner boolean;
  v_settings record;
  v_revision int := 0;
  v_near_expiry_days int := null;
  v_products jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.read');
  v_is_owner := coalesce((v_actor->>'is_owner')::boolean, false);

  select revision, near_expiry_days
  into v_settings
  from inventory.stock_policy_settings
  where tenant_id = p_tenant_id;

  if found then
    v_revision := v_settings.revision;
    v_near_expiry_days := v_settings.near_expiry_days;
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', p.id,
        'name', p.name,
        'code', coalesce(p.sku, ''),
        'base_uom', catalog._product_base_unit_name(p_tenant_id, p.id),
        'is_lot_tracked', (p.tracking_mode = 'lot'),
        'available', sr.available,
        'has_expired', sr.has_expired,
        'has_near_expiry', sr.has_near_expiry,
        'reorder_threshold', psp.reorder_threshold,
        'target_level', psp.target_level,
        'near_expiry_days', psp.near_expiry_days
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
    'revision', v_revision,
    'is_owner', v_is_owner,
    'near_expiry_days', v_near_expiry_days,
    'products', v_products
  );
end;
$$;

grant execute on function inventory.get_stock_policy(uuid) to authenticated;

-- 8. save_stock_thresholds RPC
create or replace function inventory.save_stock_thresholds(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_expected_revision int,
  p_lines jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_current_revision int := 0;
  v_new_revision int;
  v_elem jsonb;
  v_product_id uuid;
  v_reorder_threshold numeric;
  v_target_level numeric;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.stock_policy.manage', true);
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_lines is null or jsonb_typeof(p_lines) <> 'array' then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách ngưỡng không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stock_policy.thresholds',
    p_idempotency_key,
    md5(coalesce(p_expected_revision::text, '') || p_lines::text)
  );

  if v_idemp->>'decision' = 'replay' then
    return v_idemp->'result_snapshot';
  elsif v_idemp->>'decision' = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  -- Ensure settings row exists and lock for update
  insert into inventory.stock_policy_settings (
    tenant_id, near_expiry_days, revision, updated_at, updated_by
  ) values (
    p_tenant_id, null, 0, now(), v_actor_id
  )
  on conflict (tenant_id) do nothing;

  select revision
  into v_current_revision
  from inventory.stock_policy_settings
  where tenant_id = p_tenant_id
  for update;

  if v_current_revision <> p_expected_revision then
    perform inventory._raise('VERSION_CONFLICT', 'Chính sách vừa được cập nhật ở nơi khác.');
  end if;

  for v_elem in select * from jsonb_array_elements(p_lines)
  loop
    begin
      v_product_id := (v_elem->>'product_id')::uuid;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Mã sản phẩm không hợp lệ.');
    end;

    if not exists (
      select 1 from catalog.products
      where id = v_product_id
        and tenant_id = p_tenant_id
        and deleted_at is null
    ) then
      perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không tồn tại hoặc không thuộc cửa hàng.');
    end if;

    if (v_elem->>'reorder_threshold') is null or (v_elem->>'target_level') is null then
      perform inventory._raise('CONTEXT_INVALID', 'Thiếu ngưỡng cảnh báo hoặc mức tồn mục tiêu.');
    end if;

    begin
      v_reorder_threshold := (v_elem->>'reorder_threshold')::numeric;
      v_target_level := (v_elem->>'target_level')::numeric;
    exception when others then
      perform inventory._raise('CONTEXT_INVALID', 'Giá trị ngưỡng hoặc mục tiêu không phải số hợp lệ.');
    end;

    if v_reorder_threshold < 0
       or v_target_level < v_reorder_threshold
       or v_reorder_threshold <> trunc(v_reorder_threshold)
       or v_target_level <> trunc(v_target_level) then
      perform inventory._raise('CONTEXT_INVALID', 'Giá trị ngưỡng hoặc mục tiêu không hợp lệ.');
    end if;

    insert into inventory.product_stock_policies (
      tenant_id, product_id, reorder_threshold, target_level, near_expiry_days, updated_at, updated_by
    ) values (
      p_tenant_id, v_product_id, v_reorder_threshold, v_target_level, null, now(), v_actor_id
    ) on conflict (tenant_id, product_id) do update set
      reorder_threshold = excluded.reorder_threshold,
      target_level = excluded.target_level,
      updated_at = excluded.updated_at,
      updated_by = excluded.updated_by;
  end loop;

  v_new_revision := v_current_revision + 1;

  update inventory.stock_policy_settings
  set revision = v_new_revision,
      updated_at = now(),
      updated_by = v_actor_id
  where tenant_id = p_tenant_id;

  v_res := jsonb_build_object('revision', v_new_revision);

  perform inventory._complete_idempotency(
    p_tenant_id,
    'stock_policy.thresholds',
    p_idempotency_key,
    'succeeded',
    v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.save_stock_thresholds(uuid, text, int, jsonb) to authenticated;

-- 9. save_near_expiry_policy RPC
create or replace function inventory.save_near_expiry_policy(
  p_tenant_id uuid,
  p_idempotency_key text,
  p_expected_revision int,
  p_default_days int,
  p_overrides jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = inventory, iam, catalog, pg_temp
as $$
declare
  v_actor jsonb;
  v_actor_id uuid;
  v_idemp jsonb;
  v_current_revision int := 0;
  v_new_revision int;
  v_elem jsonb;
  v_product_id uuid;
  v_days int;
  v_override_ids uuid[] := array[]::uuid[];
  v_prod record;
  v_res jsonb;
begin
  v_actor := inventory._assert_actor(p_tenant_id, 'inventory.stock_policy.manage', true);
  v_actor_id := (v_actor->>'actor_id')::uuid;

  if p_default_days is not null and p_default_days <= 0 then
    perform inventory._raise('CONTEXT_INVALID', 'Số ngày cận hạn mặc định phải lớn hơn 0.');
  end if;

  if p_overrides is not null and jsonb_typeof(p_overrides) <> 'array' then
    perform inventory._raise('CONTEXT_INVALID', 'Danh sách sản phẩm riêng không hợp lệ.');
  end if;

  v_idemp := inventory._begin_idempotency(
    p_tenant_id,
    'stock_policy.near_expiry',
    p_idempotency_key,
    md5(coalesce(p_expected_revision::text, '') || coalesce(p_default_days::text, '') || coalesce(p_overrides::text, ''))
  );

  if v_idemp->>'decision' = 'replay' then
    return v_idemp->'result_snapshot';
  elsif v_idemp->>'decision' = 'in_progress' then
    perform inventory._raise('COMMAND_IN_PROGRESS', 'Thao tác đang được xử lý.');
  end if;

  insert into inventory.stock_policy_settings (
    tenant_id, near_expiry_days, revision, updated_at, updated_by
  ) values (
    p_tenant_id, null, 0, now(), v_actor_id
  )
  on conflict (tenant_id) do nothing;

  select revision
  into v_current_revision
  from inventory.stock_policy_settings
  where tenant_id = p_tenant_id
  for update;

  if v_current_revision <> p_expected_revision then
    perform inventory._raise('VERSION_CONFLICT', 'Chính sách vừa được cập nhật ở nơi khác.');
  end if;

  if p_overrides is not null then
    for v_elem in select * from jsonb_array_elements(p_overrides)
    loop
      begin
        v_product_id := (v_elem->>'product_id')::uuid;
      exception when others then
        perform inventory._raise('CONTEXT_INVALID', 'Mã sản phẩm riêng không hợp lệ.');
      end;

      select id, tracking_mode into v_prod
      from catalog.products
      where id = v_product_id
        and tenant_id = p_tenant_id
        and deleted_at is null;

      if not found then
        perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm riêng không tồn tại.');
      end if;

      if v_prod.tracking_mode <> 'lot' then
        perform inventory._raise('CONTEXT_INVALID', 'Sản phẩm không quản lý theo lô không được đặt cận hạn riêng.');
      end if;

      if (v_elem->>'days') is null then
        perform inventory._raise('CONTEXT_INVALID', 'Thiếu số ngày cận hạn riêng.');
      end if;

      begin
        v_days := (v_elem->>'days')::int;
      exception when others then
        perform inventory._raise('CONTEXT_INVALID', 'Số ngày cận hạn riêng không phải số nguyên.');
      end;

      if v_days <= 0 then
        perform inventory._raise('CONTEXT_INVALID', 'Số ngày cận hạn riêng phải lớn hơn 0.');
      end if;

      v_override_ids := array_append(v_override_ids, v_product_id);

      insert into inventory.product_stock_policies (
        tenant_id, product_id, reorder_threshold, target_level, near_expiry_days, updated_at, updated_by
      ) values (
        p_tenant_id, v_product_id, null, null, v_days, now(), v_actor_id
      ) on conflict (tenant_id, product_id) do update set
        near_expiry_days = excluded.near_expiry_days,
        updated_at = excluded.updated_at,
        updated_by = excluded.updated_by;
    end loop;
  end if;

  -- Clear near_expiry_days for all products not in v_override_ids
  update inventory.product_stock_policies
  set near_expiry_days = null,
      updated_at = now(),
      updated_by = v_actor_id
  where tenant_id = p_tenant_id
    and (cardinality(v_override_ids) = 0 or product_id <> all(v_override_ids))
    and near_expiry_days is not null;

  v_new_revision := v_current_revision + 1;

  update inventory.stock_policy_settings
  set revision = v_new_revision,
      near_expiry_days = p_default_days,
      updated_at = now(),
      updated_by = v_actor_id
  where tenant_id = p_tenant_id;

  v_res := jsonb_build_object('revision', v_new_revision);

  perform inventory._complete_idempotency(
    p_tenant_id,
    'stock_policy.near_expiry',
    p_idempotency_key,
    'succeeded',
    v_res
  );

  return v_res;
end;
$$;

grant execute on function inventory.save_near_expiry_policy(uuid, text, int, int, jsonb) to authenticated;

