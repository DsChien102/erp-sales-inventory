-- Title: Pricing S6 disable customer price rule
-- Kind: patch
-- Intent: pricing_customer_price_rule_disable_s6
-- Context: TH-04 EP02 S6 CONTRACT + BE
-- Touches: get_customer_price_rule_detail, disable_customer_price_rule
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: pricing_customer_price_rule_s1.sql, pricing_customer_price_rule_detail_s3.sql, pricing_customer_price_rule_update_s5.sql

alter table pricing.customer_price_rules
  add column if not exists disabled_at timestamptz,
  add column if not exists disabled_by uuid,
  add column if not exists disabled_reason text;

update pricing.customer_price_rules
set disabled_at = coalesce(disabled_at, updated_at),
    disabled_by = coalesce(disabled_by, updated_by)
where status = 'disabled'
  and (disabled_at is null or disabled_by is null);

alter table pricing.customer_price_rules
  add constraint customer_price_rules_disabled_reason_length
  check (disabled_reason is null or length(disabled_reason) <= 500);

alter table pricing.customer_price_rules
  add constraint customer_price_rules_disabled_audit_complete
  check (
    status <> 'disabled'
    or (disabled_at is not null and disabled_by is not null)
  );

alter table pricing.customer_price_rule_activities
  drop constraint if exists customer_price_rule_activities_activity_type_check;

alter table pricing.customer_price_rule_activities
  add constraint customer_price_rule_activities_activity_type_check
  check (activity_type in ('created', 'updated', 'disabled'));

alter function pricing.get_customer_price_rule_detail(uuid, uuid, date)
  rename to _get_customer_price_rule_detail_s3;

revoke all on function pricing._get_customer_price_rule_detail_s3(uuid, uuid, date)
  from public, anon, authenticated, service_role;

create or replace function pricing.get_customer_price_rule_detail(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_business_date date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_detail jsonb;
  v_disable_audit jsonb;
begin
  v_detail := pricing._get_customer_price_rule_detail_s3(
    p_tenant_id,
    p_rule_id,
    p_business_date
  );

  select jsonb_build_object(
    'disabled_at', r.disabled_at,
    'disabled_by', r.disabled_by,
    'disabled_reason', r.disabled_reason
  )
  into v_disable_audit
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.id = p_rule_id
    and r.status <> 'deleted';

  return v_detail || coalesce(v_disable_audit, '{}'::jsonb);
end;
$$;

revoke all on function pricing.get_customer_price_rule_detail(uuid, uuid, date)
  from public, anon;
grant execute on function pricing.get_customer_price_rule_detail(uuid, uuid, date)
  to authenticated, service_role;

create or replace function pricing.disable_customer_price_rule(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_expected_version integer,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_rule pricing.customer_price_rules%rowtype;
  v_normalized_reason text := nullif(btrim(p_reason), '');
  v_can_view_floor boolean := false;
  v_old_value jsonb;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.disable'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.disable')
    );
  end if;

  if p_rule_id is null
    or p_expected_version is null
    or p_expected_version <= 0
    or (
      v_normalized_reason is not null
      and length(v_normalized_reason) > 500
    ) then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid customer price rule disable payload.'
    );
  end if;

  select r.* into v_rule
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.id = p_rule_id
    and r.status <> 'deleted'
  for update;

  if not found then
    perform pricing._raise_pricing_error(
      'NOT_FOUND',
      'Customer price rule was not found.'
    );
  end if;

  if v_rule.status = 'disabled' then
    return (pricing._customer_price_rule_result(
      v_rule.id,
      iam.has_permission(
        p_tenant_id,
        'pricing.customer_price_rule.override_floor_price'
      )
    ) -> 'rule') || jsonb_build_object(
      'disabled_at', v_rule.disabled_at,
      'disabled_by', v_rule.disabled_by,
      'disabled_reason', v_rule.disabled_reason
    );
  end if;

  if v_rule.version <> p_expected_version then
    perform pricing._raise_pricing_error(
      'STATE_CHANGED',
      'Customer price rule version changed.',
      jsonb_build_object(
        'expectedVersion', p_expected_version,
        'currentVersion', v_rule.version
      )
    );
  end if;

  if v_rule.status not in ('active', 'needs_review') then
    perform pricing._raise_pricing_error(
      'INVALID_STATUS',
      'Customer price rule cannot be disabled in its current status.',
      jsonb_build_object('status', v_rule.status)
    );
  end if;

  v_can_view_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );

  v_old_value := jsonb_build_object(
    'status', v_rule.status,
    'version', v_rule.version
  );

  update pricing.customer_price_rules
  set status = 'disabled',
      disabled_reason = v_normalized_reason,
      disabled_by = v_actor_id,
      disabled_at = statement_timestamp(),
      updated_by = v_actor_id,
      updated_at = statement_timestamp(),
      version = v_rule.version + 1
  where id = v_rule.id
  returning * into v_rule;

  insert into pricing.customer_price_rule_activities (
    tenant_id,
    customer_price_rule_id,
    activity_type,
    old_value,
    new_value,
    created_by
  ) values (
    p_tenant_id,
    v_rule.id,
    'disabled',
    v_old_value,
    jsonb_build_object(
      'status', v_rule.status,
      'version', v_rule.version,
      'disabled_at', v_rule.disabled_at,
      'disabled_by', v_rule.disabled_by,
      'disabled_reason', v_rule.disabled_reason
    ),
    v_actor_id
  );

  return (pricing._customer_price_rule_result(
    v_rule.id,
    v_can_view_floor
  ) -> 'rule') || jsonb_build_object(
    'disabled_at', v_rule.disabled_at,
    'disabled_by', v_rule.disabled_by,
    'disabled_reason', v_rule.disabled_reason
  );
end;
$$;

revoke all on function pricing.disable_customer_price_rule(uuid, uuid, integer, text) from public, anon;
grant execute on function pricing.disable_customer_price_rule(uuid, uuid, integer, text) to authenticated, service_role;
