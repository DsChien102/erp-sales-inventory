-- Title: Pricing S5 customer price rule update
-- Kind: patch
-- Intent: pricing_customer_price_rule_update_s5
-- Context: TH-04 EP02 S5 CONTRACT + BE
-- Touches: get_customer_price_rule_update_context, update_customer_price_rule
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: pricing_customer_price_rule_s1.sql, pricing_customer_price_rule_detail_s3.sql, partner_pricing_customer_snapshot.sql, catalog_pricing_price_band_snapshot.sql

alter table pricing.customer_price_rule_activities
  drop constraint if exists customer_price_rule_activities_activity_type_check;

alter table pricing.customer_price_rule_activities
  add constraint customer_price_rule_activities_activity_type_check
  check (activity_type in ('created', 'updated'));

create or replace function pricing.update_customer_price_rule(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_expected_version integer,
  p_rule_price_minor bigint,
  p_effective_from date,
  p_effective_to date,
  p_note text,
  p_acknowledge_floor_warning boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_rule pricing.customer_price_rules%rowtype;
  v_customer jsonb;
  v_product jsonb;
  v_conflicting_rule_id uuid;
  v_can_override_floor boolean := false;
  v_can_view_rules boolean := false;
  v_floor_price_minor bigint;
  v_list_price_minor bigint;
  v_warning_codes jsonb := '[]'::jsonb;
  v_price_check_status text := 'not_checked';
  v_review_status text := 'clear';
  v_next_status text;
  v_normalized_note text := nullif(btrim(p_note), '');
  v_is_noop boolean := false;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.update'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.update')
    );
  end if;

  if p_rule_id is null
    or p_expected_version is null or p_expected_version <= 0
    or p_rule_price_minor is null or p_rule_price_minor <= 0
    or p_effective_from is null
    or (p_effective_to is not null and p_effective_to < p_effective_from) then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid customer price rule update payload.'
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

  if v_rule.id <> p_rule_id then
    perform pricing._raise_pricing_error(
      'NOT_FOUND',
      'Customer price rule was not found.'
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

  if v_rule.status not in ('active', 'needs_review', 'disabled') then
    perform pricing._raise_pricing_error(
      'INVALID_STATUS',
      'Customer price rule cannot be edited in its current status.',
      jsonb_build_object('status', v_rule.status)
    );
  end if;

  v_can_override_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );
  v_can_view_rules := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.view'
  );
  v_is_noop := v_rule.rule_price_minor = p_rule_price_minor
    and v_rule.effective_from = p_effective_from
    and v_rule.effective_to is not distinct from p_effective_to
    and v_rule.note is not distinct from v_normalized_note;

  if v_is_noop then
    return pricing._customer_price_rule_result(
      v_rule.id,
      v_can_override_floor
    ) -> 'rule';
  end if;

  v_customer := partner._get_customer_snapshot_for_pricing(
    p_tenant_id,
    v_rule.customer_id
  );
  v_product := catalog._get_product_price_band_snapshot_for_pricing(
    p_tenant_id,
    v_rule.product_id,
    v_rule.product_unit_id
  );

  if not coalesce((v_customer ->> 'exists')::boolean, false)
    or not coalesce((v_customer ->> 'is_customer')::boolean, false)
    or coalesce(v_customer ->> 'status', '') <> 'active' then
    perform pricing._raise_pricing_error(
      'REFERENCE_INVALID',
      'Customer is not valid for pricing.',
      jsonb_build_object('reference', 'customer')
    );
  end if;

  if not coalesce((v_product ->> 'exists')::boolean, false)
    or not coalesce((v_product ->> 'sellable')::boolean, false)
    or not coalesce((v_product ->> 'minor_units_valid')::boolean, false)
    or upper(coalesce(v_product ->> 'currency_code', '')) <> v_rule.currency_code then
    perform pricing._raise_pricing_error(
      'REFERENCE_INVALID',
      'Product unit or price band is not valid for pricing.',
      jsonb_build_object('reference', 'productUnit')
    );
  end if;

  v_floor_price_minor := nullif(v_product ->> 'floor_price_minor', '')::bigint;
  v_list_price_minor := nullif(v_product ->> 'list_price_minor', '')::bigint;

  if v_floor_price_minor is not null
    and p_rule_price_minor < v_floor_price_minor
    and not coalesce(p_acknowledge_floor_warning, false) then
    perform pricing._raise_pricing_error(
      'BELOW_FLOOR_BLOCKED',
      'Below-floor price requires acknowledgement.',
      jsonb_build_object('reason', 'acknowledgementRequired')
    );
  end if;

  if v_floor_price_minor is not null
    and p_rule_price_minor < v_floor_price_minor
    and not v_can_override_floor then
    perform pricing._raise_pricing_error(
      'BELOW_FLOOR_BLOCKED',
      'Below-floor price requires override permission.',
      jsonb_build_object('reason', 'overridePermissionRequired')
    );
  end if;

  if v_floor_price_minor is not null
    and p_rule_price_minor < v_floor_price_minor then
    v_warning_codes := jsonb_build_array('below_floor_price');
    v_price_check_status := 'override_allowed';
    v_review_status := 'warning';
  elsif v_floor_price_minor is not null then
    v_price_check_status := 'normal';
  end if;

  if v_rule.status <> 'disabled' then
    perform pg_advisory_xact_lock(
      hashtextextended(
        p_tenant_id::text || ':rule:' || v_rule.customer_id::text || ':'
          || v_rule.product_id::text || ':' || v_rule.product_unit_id::text,
        0
      )
    );
    select r.id into v_conflicting_rule_id
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.id <> p_rule_id
      and r.customer_id = v_rule.customer_id
      and r.product_id = v_rule.product_id
      and r.product_unit_id = v_rule.product_unit_id
      and r.status = 'active'
      and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
      and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
    order by r.created_at
    limit 1;
  end if;

  if v_conflicting_rule_id is not null then
    perform pricing._raise_pricing_error(
      'DUPLICATE_ACTIVE_RULE',
      'An active customer price rule overlaps the requested period.',
      jsonb_strip_nulls(
        jsonb_build_object(
          'conflictingRuleId', case
            when v_can_view_rules then v_conflicting_rule_id
            else null
          end
        )
      )
    );
  end if;

  v_next_status := case
    when v_rule.status = 'disabled' then 'disabled'
    else 'active'
  end;

  update pricing.customer_price_rules
  set rule_price_minor = p_rule_price_minor,
      effective_from = p_effective_from,
      effective_to = p_effective_to,
      note = v_normalized_note,
      status = v_next_status,
      review_status = v_review_status,
      list_price_snapshot_minor = v_list_price_minor,
      floor_price_snapshot_minor = v_floor_price_minor,
      price_check_status = v_price_check_status,
      warning_codes = v_warning_codes,
      blocking_codes = '[]'::jsonb,
      updated_by = v_actor_id,
      updated_at = statement_timestamp(),
      version = v_rule.version + 1
  where id = v_rule.id;

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
    'updated',
    jsonb_build_object(
      'rule_price_minor', v_rule.rule_price_minor,
      'currency_code', v_rule.currency_code,
      'effective_from', v_rule.effective_from,
      'effective_to', v_rule.effective_to,
      'note', v_rule.note,
      'source_type', v_rule.source_type,
      'status', v_rule.status,
      'review_status', v_rule.review_status,
      'price_check_status', v_rule.price_check_status,
      'warning_codes', v_rule.warning_codes,
      'blocking_codes', v_rule.blocking_codes,
      'list_price_snapshot_minor', v_rule.list_price_snapshot_minor,
      'floor_price_snapshot_minor', v_rule.floor_price_snapshot_minor,
      'version', v_rule.version
    ),
    jsonb_build_object(
      'rule_price_minor', p_rule_price_minor,
      'currency_code', v_rule.currency_code,
      'effective_from', p_effective_from,
      'effective_to', p_effective_to,
      'note', v_normalized_note,
      'source_type', v_rule.source_type,
      'status', v_next_status,
      'review_status', v_review_status,
      'price_check_status', v_price_check_status,
      'warning_codes', v_warning_codes,
      'blocking_codes', '[]'::jsonb,
      'list_price_snapshot_minor', v_list_price_minor,
      'floor_price_snapshot_minor', v_floor_price_minor,
      'version', v_rule.version + 1
    ),
    v_actor_id
  );

  return pricing._customer_price_rule_result(
    v_rule.id,
    v_can_override_floor
  ) -> 'rule';
end;
$$;

revoke all on function pricing.update_customer_price_rule(uuid, uuid, integer, bigint, date, date, text, boolean) from public, anon;
grant execute on function pricing.update_customer_price_rule(uuid, uuid, integer, bigint, date, date, text, boolean) to authenticated, service_role;

create or replace function pricing.get_customer_price_rule_update_context(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_expected_version integer,
  p_rule_price_minor bigint,
  p_effective_from date,
  p_effective_to date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_rule pricing.customer_price_rules%rowtype;
  v_customer jsonb;
  v_product jsonb;
  v_conflicting_rule_id uuid;
  v_can_override_floor boolean := false;
  v_can_view_rules boolean := false;
  v_floor_price_minor bigint;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.update'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.update')
    );
  end if;

  if p_rule_id is null
    or p_expected_version is null or p_expected_version <= 0
    or p_rule_price_minor is null or p_rule_price_minor <= 0
    or p_effective_from is null
    or (p_effective_to is not null and p_effective_to < p_effective_from) then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid customer price rule update payload.'
    );
  end if;

  select r.* into v_rule
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.id = p_rule_id
    and r.status <> 'deleted';

  if not found then
    perform pricing._raise_pricing_error(
      'NOT_FOUND',
      'Customer price rule was not found.'
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

  if v_rule.status not in ('active', 'needs_review', 'disabled') then
    perform pricing._raise_pricing_error(
      'INVALID_STATUS',
      'Customer price rule cannot be edited in its current status.',
      jsonb_build_object('status', v_rule.status)
    );
  end if;

  v_customer := partner._get_customer_snapshot_for_pricing(
    p_tenant_id,
    v_rule.customer_id
  );
  v_product := catalog._get_product_price_band_snapshot_for_pricing(
    p_tenant_id,
    v_rule.product_id,
    v_rule.product_unit_id
  );
  v_can_override_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );
  v_can_view_rules := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.view'
  );
  v_floor_price_minor := nullif(v_product ->> 'floor_price_minor', '')::bigint;

  if v_rule.status <> 'disabled' then
    select r.id into v_conflicting_rule_id
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.id <> p_rule_id
      and r.customer_id = v_rule.customer_id
      and r.product_id = v_rule.product_id
      and r.product_unit_id = v_rule.product_unit_id
      and r.status = 'active'
      and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
      and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
    order by r.created_at
    limit 1;
  end if;

  return jsonb_build_object(
    'current_rule',
      (pricing._customer_price_rule_result(v_rule.id, v_can_override_floor) -> 'rule')
      || jsonb_build_object(
        'review_status', v_rule.review_status,
        'price_check_status', v_rule.price_check_status
      ),
    'customer', jsonb_build_object(
      'customer_id', v_rule.customer_id,
      'display_name', coalesce(
        nullif(v_customer ->> 'display_name', ''),
        v_rule.customer_display_name_snapshot
      ),
      'status', coalesce(nullif(v_customer ->> 'status', ''), 'missing'),
      'exists', coalesce((v_customer ->> 'exists')::boolean, false),
      'is_customer', coalesce((v_customer ->> 'is_customer')::boolean, false)
    ),
    'product_unit', jsonb_build_object(
      'product_id', v_rule.product_id,
      'product_unit_id', v_rule.product_unit_id,
      'product_name', coalesce(
        nullif(v_product ->> 'product_name', ''),
        v_rule.product_name_snapshot
      ),
      'unit_name', coalesce(
        nullif(v_product ->> 'unit_name', ''),
        v_rule.unit_name_snapshot
      ),
      'sellable_status', coalesce(
        nullif(v_product ->> 'sellable_status', ''),
        'missing'
      ),
      'currency_code', coalesce(
        nullif(v_product ->> 'currency_code', ''),
        v_rule.currency_code
      ),
      'list_price_minor', nullif(v_product ->> 'list_price_minor', '')::bigint,
      'floor_price_minor', case
        when v_can_override_floor then v_floor_price_minor
        else null
      end,
      'floor_price_hidden', v_floor_price_minor is not null
        and not v_can_override_floor,
      'is_below_floor', v_floor_price_minor is not null
        and p_rule_price_minor < v_floor_price_minor
    ),
    'has_conflicting_rule', v_conflicting_rule_id is not null,
    'conflicting_rule_id', case
      when v_can_view_rules then v_conflicting_rule_id
      else null
    end,
    'can_override_floor', v_can_override_floor
  );
end;
$$;

revoke all on function pricing.get_customer_price_rule_update_context(uuid, uuid, integer, bigint, date, date) from public, anon;
grant execute on function pricing.get_customer_price_rule_update_context(uuid, uuid, integer, bigint, date, date) to authenticated, service_role;
