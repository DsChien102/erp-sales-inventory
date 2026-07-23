-- Title: catalog set base unit creates pending ruleBased price band
-- Kind: patch
-- Intent: catalog_set_base_unit_pending_rule_based_band
-- Context: TH-02 — edit base unit after name-only create must match guided-create pending band
-- Touches: set_product_base_unit
-- Safety: idempotent ; medium — only creates band when none active; requires manage_pricing
-- Depends on: 20260722001_catalog_pending_automatic_price_bands.sql

create or replace function catalog.set_product_base_unit(
  p_tenant_id uuid,
  p_product_id uuid,
  p_tenant_unit_id uuid default null,
  p_new_unit_name text default null
)
returns jsonb
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
declare
  v_actor_id uuid;
  v_tenant_unit_id uuid;
  v_unit_name text;
  v_facts record;
  v_blockers jsonb;
  v_status catalog.product_readiness_status;
begin
  v_actor_id := auth.uid();
  if v_actor_id is null then
    raise exception 'not authenticated';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_units') then
    raise exception 'permission denied: catalog.product.manage_units';
  end if;

  if not exists (
    select 1
    from catalog.products p
    where p.id = p_product_id
      and p.tenant_id = p_tenant_id
      and p.deleted_at is null
  ) then
    raise exception 'product not found';
  end if;

  if catalog._product_has_active_base_unit(p_tenant_id, p_product_id) then
    raise exception 'validation_exception: Product already has a base unit; change base unit is out of scope.';
  end if;

  if (p_tenant_unit_id is null and catalog._normalize_measurement_unit_name(p_new_unit_name) is null)
     or (p_tenant_unit_id is not null and catalog._normalize_measurement_unit_name(p_new_unit_name) is not null) then
    raise exception 'validation_exception: Exactly one base unit selection is required.';
  end if;

  if p_tenant_unit_id is not null then
    select tu.id, tu.name
    into v_tenant_unit_id, v_unit_name
    from catalog.tenant_measurement_units tu
    where tu.id = p_tenant_unit_id
      and tu.tenant_id = p_tenant_id
      and tu.is_active = true;

    if v_tenant_unit_id is null then
      raise exception 'validation_exception: Measurement unit is inactive or not found.';
    end if;
  else
    v_unit_name := catalog._normalize_measurement_unit_name(p_new_unit_name);

    if length(v_unit_name) > 80 then
      raise exception 'validation_exception: Unit name is too long.';
    end if;

    select tu.id
    into v_tenant_unit_id
    from catalog.tenant_measurement_units tu
    where tu.tenant_id = p_tenant_id
      and tu.name = v_unit_name;

    if v_tenant_unit_id is not null then
      raise exception 'duplicate measurement unit "%"', v_unit_name;
    end if;

    insert into catalog.tenant_measurement_units (
      tenant_id,
      name,
      is_active,
      updated_at
    )
    values (
      p_tenant_id,
      v_unit_name,
      true,
      now()
    )
    returning id into v_tenant_unit_id;
  end if;

  insert into catalog.product_units (
    tenant_id,
    product_id,
    tenant_measurement_unit_id,
    unit_name,
    is_base_unit,
    conversion_rate_to_base,
    updated_at
  )
  values (
    p_tenant_id,
    p_product_id,
    v_tenant_unit_id,
    v_unit_name,
    true,
    1,
    now()
  );

  -- Parity with create_guided_product ruleBased path: first base unit on a
  -- product without an active band creates a pending automatic band (zeros)
  -- when the caller can manage pricing. set_manual_base_price recalculation
  -- then materializes list/floor when a base price is added later.
  if iam.has_permission(p_tenant_id, 'catalog.product.manage_pricing')
     and not exists (
       select 1
       from catalog.product_unit_price_bands pb
       where pb.tenant_id = p_tenant_id
         and pb.product_id = p_product_id
         and pb.status = 'active'
     ) then
    perform 1 from catalog.set_product_unit_price_band(
      p_tenant_id => p_tenant_id,
      p_product_id => p_product_id,
      p_list_price_before_vat => 0,
      p_list_price_after_vat => 0,
      p_floor_price_before_vat => 0,
      p_floor_price_after_vat => 0,
      p_source_type => 'ruleBased'
    );
  end if;

  select *
  into v_facts
  from catalog._product_operational_facts(p_tenant_id, p_product_id);

  v_blockers := catalog._readiness_blockers_from_facts(
    v_facts.has_base_unit,
    v_facts.has_images,
    v_facts.has_stock,
    v_facts.has_base_price,
    v_facts.has_price_band,
    v_facts.has_required_custom_fields,
    v_facts.stock_mode,
    v_facts.base_price_mode
  );

  v_status := case
    when catalog._product_readiness_is_ready(
      v_facts.has_base_unit,
      v_facts.has_images,
      v_facts.has_stock,
      v_facts.has_base_price,
      v_facts.has_price_band,
      v_facts.has_required_custom_fields,
      v_facts.stock_mode,
      v_facts.base_price_mode
    ) then 'ready_to_sell'::catalog.product_readiness_status
    else 'incomplete'::catalog.product_readiness_status
  end;

  insert into catalog.product_readiness (product_id, tenant_id, status, blockers, updated_at)
  values (p_product_id, p_tenant_id, v_status, v_blockers, now())
  on conflict (product_id) do update set
    status = excluded.status,
    blockers = excluded.blockers,
    updated_at = now();

  insert into catalog.product_change_history (tenant_id, product_id, action, payload, actor_id)
  values (
    p_tenant_id,
    p_product_id,
    'set_product_base_unit',
    jsonb_build_object('tenant_measurement_unit_id', v_tenant_unit_id, 'unit_name', v_unit_name, 'readiness_status', v_status),
    v_actor_id
  );

  return jsonb_build_object(
    'product_id', p_product_id,
    'base_unit_name', v_unit_name,
    'readiness_status', v_status::text,
    'readiness_blockers', v_blockers
  );
end;
$$;

revoke all on function catalog.set_product_base_unit(uuid, uuid, uuid, text)
  from public, anon;
grant execute on function catalog.set_product_base_unit(uuid, uuid, uuid, text)
  to authenticated, service_role;
