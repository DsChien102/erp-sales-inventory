-- Title: einvoice S1 RPC — profile, policy, readiness
-- Kind: patch
-- Intent: einvoice_s1_rpc_profile_policy_readiness
-- Context: TH-08 / EP-01 / US-02..04
-- Touches: list_provider_templates, get_issuance_profile, set_default_issuance_configuration, get_automation_policy, update_automation_policy, get_configuration_readiness
-- Safety: idempotent ; medium
-- Depends on: 001_einvoice_configuration_schema.sql

create or replace function einvoice.get_issuance_profile(
  p_tenant_id uuid,
  p_actor_id uuid
) returns table(
  profile_version int,
  template_id text,
  signing_config_id text,
  signing_method text,
  compatibility_warnings jsonb
)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  return query
  select
    ip.profile_version,
    ip.default_template ->> 'template_id',
    ip.default_signing ->> 'signing_config_id',
    ip.default_signing ->> 'method',
    ip.compatibility_warnings
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id
  union all
  select 0, null::text, null::text, null::text, '[]'::jsonb
  where not exists (
    select 1 from einvoice.issuance_profiles where tenant_id = p_tenant_id
  )
  limit 1;
end;
$$;

create or replace function einvoice.set_default_issuance_configuration(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_template_id text,
  p_signing_config_id text,
  p_expected_profile_version int default null
) returns table(
  profile_version int,
  template_id text,
  signing_config_id text,
  signing_method text,
  compatibility_warnings jsonb
)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
declare
  v_version int;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  insert into einvoice.issuance_profiles as ip (
    tenant_id, default_template, default_signing, profile_version
  )
  values (
    p_tenant_id,
    jsonb_build_object('template_id', p_template_id),
    jsonb_build_object('signing_config_id', p_signing_config_id),
    1
  )
  on conflict (tenant_id) do update set
    default_template = jsonb_build_object('template_id', p_template_id),
    default_signing = jsonb_build_object('signing_config_id', p_signing_config_id),
    profile_version = ip.profile_version + 1,
    updated_at = now()
  where p_expected_profile_version is null
     or ip.profile_version = p_expected_profile_version
  returning ip.profile_version into v_version;

  if v_version is null then
    raise exception 'STATE_CHANGED: profile version mismatch';
  end if;

  return query
  select v_version, p_template_id, p_signing_config_id, null::text, '[]'::jsonb;
end;
$$;

create or replace function einvoice.get_automation_policy(
  p_tenant_id uuid,
  p_actor_id uuid
) returns table(
  auto_issue_enabled boolean,
  auto_send_enabled boolean,
  policy_version int,
  blockers jsonb
)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  return query
  select
    coalesce(iap.auto_issue_enabled, false),
    coalesce(iap.auto_send_enabled, false),
    coalesce(iap.policy_version, 0),
    coalesce(iap.blockers, '[]'::jsonb)
  from einvoice.invoice_automation_policies iap
  where iap.tenant_id = p_tenant_id
  union all
  select false, false, 0, '[]'::jsonb
  where not exists (
    select 1 from einvoice.invoice_automation_policies where tenant_id = p_tenant_id
  )
  limit 1;
end;
$$;

create or replace function einvoice.update_automation_policy(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_auto_issue_enabled boolean default null,
  p_auto_send_enabled boolean default null,
  p_expected_policy_version int default 0
) returns table(
  auto_issue_enabled boolean,
  auto_send_enabled boolean,
  policy_version int,
  blockers jsonb
)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
declare
  v_version int;
  v_auto_issue_enabled boolean;
  v_auto_send_enabled boolean;
  v_blockers jsonb;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  insert into einvoice.invoice_automation_policies as iap (
    tenant_id, auto_issue_enabled, auto_send_enabled, policy_version
  ) values (
    p_tenant_id,
    coalesce(p_auto_issue_enabled, false),
    coalesce(p_auto_send_enabled, false),
    1
  )
  on conflict (tenant_id) do update set
    auto_issue_enabled = coalesce(p_auto_issue_enabled, iap.auto_issue_enabled),
    auto_send_enabled = coalesce(p_auto_send_enabled, iap.auto_send_enabled),
    policy_version = iap.policy_version + 1,
    updated_at = now()
  where iap.policy_version = p_expected_policy_version
  returning iap.policy_version,
            iap.auto_issue_enabled,
            iap.auto_send_enabled,
            iap.blockers
  into v_version, v_auto_issue_enabled, v_auto_send_enabled, v_blockers;

  if v_version is null then
    raise exception 'STATE_CHANGED: policy version mismatch';
  end if;

  return query
  select v_auto_issue_enabled, v_auto_send_enabled, v_version, v_blockers;
end;
$$;

create or replace function einvoice.get_configuration_readiness(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_purpose text default null
) returns table(level text, blockers jsonb, warnings jsonb)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  return query
  select
    case
      when pc.status is distinct from 'connected' then 'notReady'
      when ip.id is null then 'notReady'
      else 'ready'
    end,
    case
      when pc.status is distinct from 'connected'
        then jsonb_build_array(jsonb_build_object('code','provider_not_connected','message','Not connected'))
      when ip.id is null
        then jsonb_build_array(jsonb_build_object('code','template_unavailable','message','No default template'))
      else '[]'::jsonb
    end,
    '[]'::jsonb
  from (select 1) s
  left join einvoice.provider_connections pc
    on pc.tenant_id = p_tenant_id and pc.status <> 'disconnected'
  left join einvoice.issuance_profiles ip on ip.tenant_id = p_tenant_id;
end;
$$;

create or replace function einvoice.list_provider_templates(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_invoice_with_code boolean default null,
  p_year int default null
) returns table(template_id text, name text, serial text, symbol text)
language plpgsql
security definer
set search_path = einvoice, iam, public
as $$
declare
  v_connection record;
  v_templates jsonb;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  select pc.id, pc.status, pc.capabilities_snapshot
  into v_connection
  from einvoice.provider_connections pc
  where pc.tenant_id = p_tenant_id and pc.status = 'connected'
  limit 1;

  if v_connection.id is null then
    raise exception 'PROVIDER_NOT_CONNECTED';
  end if;

  v_templates := v_connection.capabilities_snapshot -> 'templates';

  if v_templates is not null and jsonb_array_length(v_templates) > 0 then
    return query
    select
      elem ->> 'template_id' as template_id,
      elem ->> 'name' as name,
      elem ->> 'serial' as serial,
      elem ->> 'symbol' as symbol
    from jsonb_array_elements(v_templates) as elem
    where coalesce((elem ->> 'is_available')::boolean, true) = true;
  else
    return query
    select 'tpl-default', 'Default template', null::text, null::text;
  end if;
end;
$$;

revoke all on function einvoice.get_issuance_profile(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.set_default_issuance_configuration(uuid, uuid, text, text, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_automation_policy(uuid, uuid)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.update_automation_policy(uuid, uuid, boolean, boolean, integer)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.get_configuration_readiness(uuid, uuid, text)
  from public, anon, authenticated, service_role;
revoke all on function einvoice.list_provider_templates(uuid, uuid, boolean, integer)
  from public, anon, authenticated, service_role;

grant execute on function einvoice.get_issuance_profile(uuid, uuid) to authenticated;
grant execute on function einvoice.set_default_issuance_configuration(uuid, uuid, text, text, integer) to authenticated;
grant execute on function einvoice.get_automation_policy(uuid, uuid) to authenticated;
grant execute on function einvoice.update_automation_policy(uuid, uuid, boolean, boolean, integer) to authenticated;
grant execute on function einvoice.get_configuration_readiness(uuid, uuid, text) to authenticated;
grant execute on function einvoice.list_provider_templates(uuid, uuid, boolean, integer) to authenticated;
