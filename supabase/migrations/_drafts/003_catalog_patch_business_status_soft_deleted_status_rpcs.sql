-- Title: catalog patch business_status soft_deleted status RPCs
-- Kind: patch
-- Intent: catalog_business_status_soft_deleted
-- Context: TH-02 — deactivate/reactivate guard on soft_deleted status
-- Touches: deactivate_product, reactivate_product
-- Safety: idempotent
-- Depends on: 001_catalog_patch_business_status_soft_deleted_schema.sql, 001b_catalog_patch_business_status_soft_deleted_backfill.sql

create or replace function catalog.deactivate_product(
  p_tenant_id uuid,
  p_product_id uuid,
  p_actor_id uuid default auth.uid(),
  p_reason text default null,
  p_expected_version integer default null,
  p_confirm_acknowledge_warnings boolean default false
)
returns table (
  product_id uuid,
  previous_status text,
  current_status text,
  readiness_status text,
  readiness_blockers jsonb,
  version integer,
  reason text,
  warnings jsonb,
  history_entry jsonb
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
#variable_conflict use_column
declare
  v_product catalog.products%rowtype;
  v_previous_status text;
  v_current_status text := 'inactive';
  v_warnings jsonb := '[]'::jsonb;
  v_history_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_status') then
    raise exception 'permission denied: catalog.product.manage_status';
  end if;

  select *
  into v_product
  from catalog.products p
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id
  for update;

  if not found then
    raise exception 'product not found';
  end if;

  if v_product.business_status = 'soft_deleted'::catalog.product_business_status then
    raise exception 'product is soft-deleted and cannot change business status';
  end if;

  if p_expected_version is not null and p_expected_version <> v_product.version then
    raise exception 'stale_product_version: expected=% current=%',
      p_expected_version,
      v_product.version;
  end if;

  if v_product.business_status = 'inactive'::catalog.product_business_status then
    raise exception 'validation_exception: Product is already inactive.';
  end if;

  v_warnings := catalog._product_business_status_warnings(p_tenant_id, p_product_id);
  if jsonb_array_length(v_warnings) > 0 and not coalesce(p_confirm_acknowledge_warnings, false) then
    raise exception 'product_business_status_warnings_require_acknowledgment: %',
      v_warnings::text;
  end if;

  v_previous_status := v_product.business_status::text;

  update catalog.products
  set business_status = 'inactive',
      updated_at = now(),
      updated_by = p_actor_id,
      version = catalog.products.version + 1
  where tenant_id = p_tenant_id
    and id = p_product_id;

  perform * from catalog._refresh_product_readiness(p_tenant_id, p_product_id);

  insert into catalog.product_change_history (
    tenant_id,
    product_id,
    action,
    payload,
    actor_id
  )
  values (
    p_tenant_id,
    p_product_id,
    'product_status_changed',
    jsonb_build_object(
      'value_before', v_previous_status,
      'value_after', v_current_status,
      'reason', nullif(btrim(coalesce(p_reason, '')), ''),
      'warnings', v_warnings
    ),
    p_actor_id
  )
  returning id into v_history_id;

  perform catalog.enqueue_outbox_message(
    p_tenant_id,
    'catalog.product.deactivated',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'product_id', p_product_id,
      'previous_status', v_previous_status,
      'current_status', v_current_status,
      'reason', nullif(btrim(coalesce(p_reason, '')), '')
    )
  );

  return query
  select *
  from catalog._product_business_status_result_row(
    p_tenant_id,
    p_product_id,
    v_previous_status,
    v_current_status,
    p_reason,
    v_warnings,
    v_history_id
  );
end;
$$;

create or replace function catalog.reactivate_product(
  p_tenant_id uuid,
  p_product_id uuid,
  p_actor_id uuid default auth.uid(),
  p_reason text default null,
  p_expected_version integer default null
)
returns table (
  product_id uuid,
  previous_status text,
  current_status text,
  readiness_status text,
  readiness_blockers jsonb,
  version integer,
  reason text,
  warnings jsonb,
  history_entry jsonb
)
language plpgsql
security definer
set search_path = catalog, iam, pg_temp
as $$
#variable_conflict use_column
declare
  v_product catalog.products%rowtype;
  v_previous_status text;
  v_current_status text := 'active';
  v_history_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;

  if p_actor_id is null or p_actor_id <> auth.uid() then
    raise exception 'actor mismatch';
  end if;

  if not iam.has_permission(p_tenant_id, 'catalog.product.manage_status') then
    raise exception 'permission denied: catalog.product.manage_status';
  end if;

  select *
  into v_product
  from catalog.products p
  where p.tenant_id = p_tenant_id
    and p.id = p_product_id
  for update;

  if not found then
    raise exception 'product not found';
  end if;

  if v_product.business_status = 'soft_deleted'::catalog.product_business_status then
    raise exception 'product is soft-deleted and cannot change business status';
  end if;

  if p_expected_version is not null and p_expected_version <> v_product.version then
    raise exception 'stale_product_version: expected=% current=%',
      p_expected_version,
      v_product.version;
  end if;

  if v_product.business_status = 'active'::catalog.product_business_status then
    raise exception 'validation_exception: Product is already active.';
  end if;

  v_previous_status := v_product.business_status::text;

  update catalog.products
  set business_status = 'active',
      updated_at = now(),
      updated_by = p_actor_id,
      version = catalog.products.version + 1
  where tenant_id = p_tenant_id
    and id = p_product_id;

  perform * from catalog._refresh_product_readiness(p_tenant_id, p_product_id);

  insert into catalog.product_change_history (
    tenant_id,
    product_id,
    action,
    payload,
    actor_id
  )
  values (
    p_tenant_id,
    p_product_id,
    'product_status_changed',
    jsonb_build_object(
      'value_before', v_previous_status,
      'value_after', v_current_status,
      'reason', nullif(btrim(coalesce(p_reason, '')), '')
    ),
    p_actor_id
  )
  returning id into v_history_id;

  perform catalog.enqueue_outbox_message(
    p_tenant_id,
    'catalog.product.reactivated',
    jsonb_build_object(
      'tenant_id', p_tenant_id,
      'product_id', p_product_id,
      'previous_status', v_previous_status,
      'current_status', v_current_status,
      'reason', nullif(btrim(coalesce(p_reason, '')), '')
    )
  );

  return query
  select *
  from catalog._product_business_status_result_row(
    p_tenant_id,
    p_product_id,
    v_previous_status,
    v_current_status,
    p_reason,
    '[]'::jsonb,
    v_history_id
  );
end;
$$;

