-- Title: IAM ensure default store + membership scope helpers
-- Kind: patch
-- Intent: iam_ensure_default_store_scope_helpers
-- Context: TH-01/TH-05 — shared idempotent ensure for store context wiring
-- Touches: iam._ensure_tenant_default_store, iam._ensure_membership_default_store_scope
-- Safety: idempotent ; low
-- Depends on: 20260830001_iam_active_store_context_group_a.sql, 20260914001_iam_get_session_context_multi_tenant.sql

create or replace function iam._ensure_tenant_default_store(p_tenant_id uuid)
returns uuid
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_store_id uuid;
  v_tenant_name text;
begin
  if p_tenant_id is null then
    raise exception using errcode = 'P0001',
      message = '{"code":"CONTEXT_INVALID","message":"Tenant id is required.","details":{}}';
  end if;

  select s.id
  into v_store_id
  from iam.stores s
  where s.tenant_id = p_tenant_id
    and s.status = 'active'
    and s.code = 'default'
  limit 1;

  if v_store_id is null then
    select s.id
    into v_store_id
    from iam.stores s
    where s.tenant_id = p_tenant_id
      and s.status = 'active'
    order by s.created_at, s.id
    limit 1;
  end if;

  if v_store_id is null then
    select coalesce(nullif(trim(t.display_name), ''), nullif(trim(t.name), ''), 'Default Store')
    into v_tenant_name
    from iam.tenants t
    where t.id = p_tenant_id;

    if v_tenant_name is null then
      raise exception using errcode = 'P0001',
        message = '{"code":"RESOURCE_NOT_FOUND","message":"Tenant not found.","details":{}}';
    end if;

    insert into iam.stores (tenant_id, code, display_name, status)
    values (p_tenant_id, 'default', v_tenant_name, 'active')
    on conflict (tenant_id, code) do update
      set display_name = excluded.display_name,
          status = 'active'
    returning id into v_store_id;
  end if;

  return v_store_id;
end;
$$;

create or replace function iam._ensure_membership_default_store_scope(
  p_tenant_id uuid,
  p_user_id uuid
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_store_id uuid;
  v_membership_status text;
begin
  if p_tenant_id is null or p_user_id is null then
    return;
  end if;

  select m.status
  into v_membership_status
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = p_user_id;

  if v_membership_status is null or v_membership_status <> 'active' then
    return;
  end if;

  if exists (
    select 1
    from iam.membership_store_scopes scope
    join iam.stores store on store.id = scope.store_id
      and store.tenant_id = scope.tenant_id
    where scope.tenant_id = p_tenant_id
      and scope.user_id = p_user_id
      and scope.is_default
      and store.status = 'active'
  ) then
    return;
  end if;

  v_store_id := iam._ensure_tenant_default_store(p_tenant_id);

  insert into iam.membership_store_scopes (
    tenant_id,
    user_id,
    store_id,
    is_default
  ) values (
    p_tenant_id,
    p_user_id,
    v_store_id,
    true
  )
  on conflict (tenant_id, user_id, store_id) do update
    set is_default = true;
end;
$$;

revoke all on function iam._ensure_tenant_default_store(uuid) from public, anon;
revoke all on function iam._ensure_membership_default_store_scope(uuid, uuid) from public, anon;
