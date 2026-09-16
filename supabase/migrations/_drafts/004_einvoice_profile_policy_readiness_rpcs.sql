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
  v_template jsonb;
  v_is_mtt boolean;
  v_method text;
  v_sign_type int;
  v_signing jsonb;
begin
  if auth.uid() is null
     or p_actor_id is null
     or p_actor_id <> auth.uid()
     or not iam.has_permission(p_tenant_id, 'einvoice.manage_configuration') then
    raise exception 'NO_PERMISSION: einvoice.manage_configuration required';
  end if;

  select elem
  into v_template
  from einvoice.provider_connections pc,
       jsonb_array_elements(coalesce(pc.capabilities_snapshot -> 'templates', '[]'::jsonb)) as elem
  where pc.tenant_id = p_tenant_id
    and pc.status = 'connected'
    and (elem ->> 'template_id' = p_template_id or elem ->> 'templateId' = p_template_id)
  limit 1;

  if v_template is null then
    raise exception 'TEMPLATE_NOT_AVAILABLE: configured template is not in provider capability';
  end if;

  v_is_mtt := coalesce(
    (v_template ->> 'is_mtt')::boolean,
    upper(substr(coalesce(v_template ->> 'invoice_series', v_template ->> 'symbol', ''), 5, 1)) = 'M'
  );

  if p_signing_config_id in ('sign-nosign', 'sign-mtt') then
    v_method := 'noSign';
    v_sign_type := 5;
  elsif p_signing_config_id = 'sign-hsm' then
    v_method := 'hsm';
    v_sign_type := 2;
  else
    raise exception 'SIGNING_CONFIGURATION_NOT_AVAILABLE: unsupported signing configuration';
  end if;

  if v_is_mtt and v_sign_type is distinct from 5 then
    raise exception 'SIGNING_CONFIGURATION_NOT_AVAILABLE: MTT template requires SignType=5';
  end if;

  if (not v_is_mtt) and v_sign_type is distinct from 2 then
    raise exception 'SIGNING_CONFIGURATION_NOT_AVAILABLE: non-MTT template requires SignType=2';
  end if;

  v_signing := jsonb_build_object(
    'signing_config_id', p_signing_config_id,
    'method', v_method,
    'sign_type', v_sign_type,
    'is_available', true
  );

  v_template := v_template || jsonb_build_object(
    'template_id', coalesce(v_template ->> 'template_id', p_template_id),
    'invoice_series', coalesce(
      nullif(btrim(v_template ->> 'invoice_series'), ''),
      nullif(btrim(v_template ->> 'symbol'), '')
    ),
    'symbol', coalesce(
      nullif(btrim(v_template ->> 'invoice_series'), ''),
      nullif(btrim(v_template ->> 'symbol'), '')
    ),
    'is_mtt', v_is_mtt,
    'invoice_with_code', coalesce(
      (v_template ->> 'invoice_with_code')::boolean,
      upper(substr(coalesce(v_template ->> 'invoice_series', v_template ->> 'symbol', ''), 2, 1)) = 'C'
    ),
    'is_send_summary', coalesce((v_template ->> 'is_send_summary')::boolean, false),
    'is_available', coalesce((v_template ->> 'is_available')::boolean, true)
  );

  insert into einvoice.issuance_profiles as ip (
    tenant_id, default_template, default_signing, profile_version
  )
  values (
    p_tenant_id,
    v_template,
    v_signing,
    1
  )
  on conflict (tenant_id) do update set
    default_template = excluded.default_template,
    default_signing = excluded.default_signing,
    profile_version = ip.profile_version + 1,
    updated_at = now()
  where p_expected_profile_version is null
     or ip.profile_version = p_expected_profile_version
  returning ip.profile_version into v_version;

  if v_version is null then
    raise exception 'STATE_CHANGED: profile version mismatch';
  end if;

  return query
  select v_version, p_template_id, p_signing_config_id, v_method, '[]'::jsonb;
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
) returns table(
  template_id text,
  name text,
  serial text,
  symbol text,
  invoice_series text,
  invoice_with_code boolean,
  is_mtt boolean,
  is_send_summary boolean
)
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
      coalesce(elem ->> 'invoice_series', elem ->> 'symbol') as symbol,
      coalesce(elem ->> 'invoice_series', elem ->> 'symbol') as invoice_series,
      case
        when elem ? 'invoice_with_code' then (elem ->> 'invoice_with_code')::boolean
        else null
      end as invoice_with_code,
      coalesce((elem ->> 'is_mtt')::boolean, false) as is_mtt,
      coalesce((elem ->> 'is_send_summary')::boolean, false) as is_send_summary
    from jsonb_array_elements(v_templates) as elem
    where coalesce((elem ->> 'is_available')::boolean, true) = true
      and (
        p_invoice_with_code is null
        or (
          case
            when elem ? 'invoice_with_code' then (elem ->> 'invoice_with_code')::boolean
            else null
          end
        ) is not distinct from p_invoice_with_code
      );
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
