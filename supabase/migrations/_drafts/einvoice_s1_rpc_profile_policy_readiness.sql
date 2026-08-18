-- Title: einvoice S1 RPC — profile, policy, readiness
-- Kind: patch
-- Intent: einvoice_s1_rpc_profile_policy_readiness
-- Context: TH-08 / EP-01 / US-02..04
-- Touches: list_provider_templates, get_issuance_profile, set_default_issuance_configuration, get_automation_policy, update_automation_policy, get_configuration_readiness
-- Safety: idempotent ; medium
-- Depends on: einvoice_s1_schema_configuration.sql

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
language sql
security definer
set search_path = einvoice, public
as $$
  select
    ip.profile_version,
    ip.default_template ->> 'template_id',
    ip.default_signing ->> 'signing_config_id',
    ip.default_signing ->> 'method',
    ip.compatibility_warnings
  from einvoice.issuance_profiles ip
  where ip.tenant_id = p_tenant_id;
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
set search_path = einvoice, public
as $$
declare
  v_version int;
begin
  insert into einvoice.issuance_profiles (tenant_id, default_template, default_signing, profile_version)
  values (
    p_tenant_id,
    jsonb_build_object('template_id', p_template_id),
    jsonb_build_object('signing_config_id', p_signing_config_id),
    1
  )
  on conflict (tenant_id) do update set
    default_template = jsonb_build_object('template_id', p_template_id),
    default_signing = jsonb_build_object('signing_config_id', p_signing_config_id),
    profile_version = einvoice.issuance_profiles.profile_version + 1,
    updated_at = now()
  where p_expected_profile_version is null
     or einvoice.issuance_profiles.profile_version = p_expected_profile_version
  returning profile_version into v_version;

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
language sql
security definer
set search_path = einvoice, public
as $$
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
set search_path = einvoice, public
as $$
declare
  v_version int;
begin
  insert into einvoice.invoice_automation_policies (
    tenant_id, auto_issue_enabled, auto_send_enabled, policy_version
  ) values (
    p_tenant_id,
    coalesce(p_auto_issue_enabled, false),
    coalesce(p_auto_send_enabled, false),
    1
  )
  on conflict (tenant_id) do update set
    auto_issue_enabled = coalesce(p_auto_issue_enabled, invoice_automation_policies.auto_issue_enabled),
    auto_send_enabled = coalesce(p_auto_send_enabled, invoice_automation_policies.auto_send_enabled),
    policy_version = invoice_automation_policies.policy_version + 1,
    updated_at = now()
  where invoice_automation_policies.policy_version = p_expected_policy_version
  returning policy_version, auto_issue_enabled, auto_send_enabled, blockers
  into v_version, auto_issue_enabled, auto_send_enabled, blockers;

  if v_version is null then
    raise exception 'STATE_CHANGED: policy version mismatch';
  end if;

  return next;
end;
$$;

create or replace function einvoice.get_configuration_readiness(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_purpose text default null
) returns table(level text, blockers jsonb, warnings jsonb)
language sql
security definer
set search_path = einvoice, public
as $$
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
$$;

create or replace function einvoice.list_provider_templates(
  p_tenant_id uuid,
  p_actor_id uuid,
  p_invoice_with_code boolean default null,
  p_year int default null
) returns table(template_id text, name text, serial text, symbol text)
language plpgsql
security definer
set search_path = einvoice, public
as $$
begin
  if not exists (
    select 1 from einvoice.provider_connections
    where tenant_id = p_tenant_id and status = 'connected'
  ) then
    raise exception 'PROVIDER_NOT_CONNECTED';
  end if;
  return query
  select 'tpl-default', 'Default template', null::text, null::text;
end;
$$;
