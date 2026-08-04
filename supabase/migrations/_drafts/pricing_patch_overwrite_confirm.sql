-- Title: Add overwrite confirmation support to create, update, and reenable price rules
-- Kind: patch
-- Intent: pricing_overwrite_confirm
-- Context: TH-04 EP02 — FR-04 "Quyết toán ghi đè quy tắc giá riêng bị trùng"
-- Touches: _auto_disable_overlapping_customer_price_rules, create_customer_price_rule, update_customer_price_rule, reenable_customer_price_rule
-- Safety: idempotent; medium
-- Depends on: 20260725004_pricing_customer_price_rule_s1.sql, 20260725007_pricing_customer_price_rule_update_s5.sql, 20260725009_pricing_customer_price_rule_reenable_s7.sql, 20260725014_pricing_customer_price_rule_lifecycle_eligibility.sql

-- 0. Patch _auto_disable_overlapping_customer_price_rules to soft-delete (status = deleted, deleted_at = timestamp)
create or replace function pricing._auto_disable_overlapping_customer_price_rules(
  p_tenant_id uuid,
  p_keep_rule_id uuid,
  p_customer_id uuid,
  p_product_id uuid,
  p_product_unit_id uuid,
  p_effective_from date,
  p_effective_to date,
  p_actor_id uuid,
  p_replacement_action text
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text :=
      'Tự động xóa mềm do bị ghi đè bởi giá riêng ' || p_keep_rule_id::text;
  v_disabled_count integer := 0;
begin
  with locked as (
    select r.id, r.version, r.status, r.disabled_at, r.disabled_by, r.disabled_reason
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.id <> coalesce(p_keep_rule_id, '00000000-0000-0000-0000-000000000000'::uuid)
      and r.customer_id = p_customer_id
      and r.product_id = p_product_id
      and r.product_unit_id = p_product_unit_id
      and r.status = 'active'
      and r.deleted_at is null
      and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
      and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
    for update
  ),
  updated as (
    update pricing.customer_price_rules r
    set status = 'deleted',
        deleted_at = statement_timestamp(),
        disabled_reason = v_reason,
        disabled_by = p_actor_id,
        disabled_at = statement_timestamp(),
        updated_by = p_actor_id,
        updated_at = statement_timestamp(),
        version = r.version + 1
    from locked l
    where r.id = l.id
    returning
      r.id,
      l.version as old_version,
      r.version as new_version,
      r.status,
      r.disabled_at,
      r.disabled_by,
      r.disabled_reason
  ),
  activity as (
    insert into pricing.customer_price_rule_activities (
      tenant_id,
      customer_price_rule_id,
      activity_type,
      old_value,
      new_value,
      created_by
    )
    select
      p_tenant_id,
      u.id,
      'deleted',
      jsonb_build_object(
        'status', 'active',
        'version', u.old_version
      ),
      jsonb_build_object(
        'status', u.status,
        'version', u.new_version,
        'disabled_at', u.disabled_at,
        'disabled_by', u.disabled_by,
        'disabled_reason', u.disabled_reason,
        'reason_code', 'AUTO_REPLACED_BY_RULE',
        'replacement_rule_id', p_keep_rule_id,
        'replacement_action', p_replacement_action
      ),
      p_actor_id
    from updated u
    returning 1
  )
  select count(*)::integer into v_disabled_count from activity;

  return v_disabled_count;
end;
$$;

revoke all on function pricing._auto_disable_overlapping_customer_price_rules(
  uuid, uuid, uuid, uuid, uuid, date, date, uuid, text
) from public, anon, authenticated, service_role;

-- 1. Patch create_customer_price_rule to support p_acknowledge_overwrite
create or replace function pricing.create_customer_price_rule(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_customer_id uuid,
  p_product_id uuid,
  p_product_unit_id uuid,
  p_rule_price_minor bigint,
  p_currency_code text,
  p_effective_from date,
  p_idempotency_key text,
  p_effective_to date default null,
  p_note text default null,
  p_acknowledge_floor_warning boolean default false,
  p_acknowledge_overwrite boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_customer jsonb;
  v_product jsonb;
  v_conflicting_rule_id uuid;
  v_can_override_floor boolean := false;
  v_floor_price_minor bigint;
  v_list_price_minor bigint;
  v_is_below_floor boolean := false;
  v_warning_codes jsonb := '[]'::jsonb;
  v_review_status text := 'clear';
  v_price_check_status text := 'normal';
  v_payload_hash text;
  v_existing record;
  v_disabled_count integer := 0;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.create'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.create')
    );
  end if;

  if p_tenant_id is null
    or p_rule_id is null
    or p_customer_id is null
    or p_product_id is null
    or p_product_unit_id is null
    or p_rule_price_minor is null
    or p_rule_price_minor <= 0
    or nullif(btrim(coalesce(p_currency_code, '')), '') is null
    or p_effective_from is null
    or nullif(btrim(coalesce(p_idempotency_key, '')), '') is null
    or (p_effective_to is not null and p_effective_to < p_effective_from)
    or (p_note is not null and char_length(p_note) > 500) then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid create customer price rule payload.'
    );
  end if;

  v_payload_hash := encode(
    extensions.digest(
      concat_ws(
        ':',
        p_tenant_id::text,
        p_customer_id::text,
        p_product_id::text,
        p_product_unit_id::text,
        p_rule_price_minor::text,
        upper(p_currency_code),
        p_effective_from::text,
        coalesce(p_effective_to::text, ''),
        coalesce(p_note, '')
      ),
      'sha256'
    ),
    'hex'
  );

  select *
  into v_existing
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.idempotency_key = btrim(p_idempotency_key);

  if found then
    if v_existing.payload_hash = v_payload_hash then
      v_can_override_floor := iam.has_permission(
        p_tenant_id,
        'pricing.customer_price_rule.override_floor_price'
      );
      return pricing._customer_price_rule_result(
        v_existing.id,
        v_can_override_floor
      );
    else
      perform pricing._raise_pricing_error(
        'IDEMPOTENCY_CONFLICT',
        'Idempotency key reuse with different payload.'
      );
    end if;
  end if;

  v_customer := partner._get_customer_snapshot_for_pricing(
    p_tenant_id,
    p_customer_id
  );
  v_product := catalog._get_product_price_band_snapshot_for_pricing(
    p_tenant_id,
    p_product_id,
    p_product_unit_id
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
    or coalesce(v_product ->> 'currency_code', '') <> p_currency_code then
    perform pricing._raise_pricing_error(
      'REFERENCE_INVALID',
      'Product unit or price band is not valid for pricing.',
      jsonb_build_object('reference', 'productUnit')
    );
  end if;

  v_can_override_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );
  v_floor_price_minor := (v_product ->> 'floor_price_minor')::bigint;
  v_list_price_minor := (v_product ->> 'list_price_minor')::bigint;
  v_is_below_floor := v_floor_price_minor is not null
    and p_rule_price_minor < v_floor_price_minor;

  if v_is_below_floor
    and not coalesce(p_acknowledge_floor_warning, false) then
    perform pricing._raise_pricing_error(
      'BELOW_FLOOR_BLOCKED',
      'Below-floor price requires acknowledgement.',
      jsonb_build_object('reason', 'acknowledgementRequired')
    );
  end if;

  if v_is_below_floor and not v_can_override_floor then
    perform pricing._raise_pricing_error(
      'BELOW_FLOOR_BLOCKED',
      'Below-floor price requires override permission.',
      jsonb_build_object('reason', 'overridePermissionRequired')
    );
  end if;

  if v_is_below_floor then
    v_warning_codes := jsonb_build_array('below_floor_price');
    v_price_check_status := 'override_allowed';
    v_review_status := 'warning';
  elsif v_floor_price_minor is not null then
    v_price_check_status := 'normal';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_tenant_id::text || ':rule:' || p_customer_id::text || ':'
        || p_product_id::text || ':' || p_product_unit_id::text,
      0
    )
  );

  select r.id
  into v_conflicting_rule_id
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.customer_id = p_customer_id
    and r.product_id = p_product_id
    and r.product_unit_id = p_product_unit_id
    and r.status = 'active'
    and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
    and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
  limit 1
  for update;

  if v_conflicting_rule_id is not null then
    if not coalesce(p_acknowledge_overwrite, false) then
      perform pricing._raise_pricing_error(
        'DUPLICATE_ACTIVE_RULE',
        'An active customer price rule already overlaps this period.',
        jsonb_build_object(
          'conflictingRuleId', v_conflicting_rule_id,
          'reason', 'overwriteRequired'
        )
      );
    end if;
  end if;

  v_disabled_count := pricing._auto_disable_overlapping_customer_price_rules(
    p_tenant_id,
    p_rule_id,
    p_customer_id,
    p_product_id,
    p_product_unit_id,
    p_effective_from,
    p_effective_to,
    v_actor_id,
    'create_customer_price_rule'
  );

  insert into pricing.customer_price_rules (
    id,
    tenant_id,
    customer_id,
    product_id,
    product_unit_id,
    customer_display_name_snapshot,
    customer_phone_snapshot,
    customer_status_snapshot,
    product_name_snapshot,
    product_reference_id_snapshot,
    product_sku_snapshot,
    unit_name_snapshot,
    sellable_status_snapshot,
    rule_price_minor,
    currency_code,
    review_status,
    effective_from,
    effective_to,
    list_price_snapshot_minor,
    floor_price_snapshot_minor,
    price_check_status,
    warning_codes,
    note,
    created_by,
    updated_by,
    idempotency_key,
    payload_hash
  ) values (
    p_rule_id,
    p_tenant_id,
    p_customer_id,
    p_product_id,
    p_product_unit_id,
    v_customer ->> 'display_name',
    coalesce(v_customer ->> 'phone', partner._profile_phone(p_customer_id)),
    v_customer ->> 'status',
    v_product ->> 'product_name',
    v_product ->> 'product_reference_id',
    v_product ->> 'sku',
    v_product ->> 'unit_name',
    v_product ->> 'sellable_status',
    p_rule_price_minor,
    p_currency_code,
    v_review_status,
    p_effective_from,
    p_effective_to,
    v_list_price_minor,
    v_floor_price_minor,
    v_price_check_status,
    v_warning_codes,
    nullif(btrim(p_note), ''),
    v_actor_id,
    v_actor_id,
    btrim(p_idempotency_key),
    v_payload_hash
  );

  insert into pricing.customer_price_rule_activities (
    tenant_id,
    customer_price_rule_id,
    activity_type,
    old_value,
    new_value,
    created_by
  ) values (
    p_tenant_id,
    p_rule_id,
    'created',
    jsonb_build_object('status', 'none'),
    jsonb_build_object(
      'status', 'active',
      'review_status', v_review_status,
      'rule_price_minor', p_rule_price_minor,
      'currency_code', p_currency_code,
      'effective_from', p_effective_from,
      'effective_to', p_effective_to,
      'disabled_overlapping_count', v_disabled_count
    ),
    v_actor_id
  );

  return pricing._customer_price_rule_result(p_rule_id, v_can_override_floor);
end;
$$;

revoke all on function pricing.create_customer_price_rule(
  uuid, uuid, uuid, uuid, uuid, bigint, text, date, text, date, text, boolean, boolean
) from public, anon;
grant execute on function pricing.create_customer_price_rule(
  uuid, uuid, uuid, uuid, uuid, bigint, text, date, text, date, text, boolean, boolean
) to authenticated, service_role;

-- 2. Patch update_customer_price_rule to support p_acknowledge_overwrite
create or replace function pricing.update_customer_price_rule(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_expected_version integer,
  p_rule_price_minor bigint,
  p_effective_from date,
  p_effective_to date default null,
  p_note text default null,
  p_acknowledge_floor_warning boolean default false,
  p_acknowledge_overwrite boolean default false
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
  v_floor_price_minor bigint;
  v_list_price_minor bigint;
  v_warning_codes jsonb := '[]'::jsonb;
  v_price_check_status text := 'normal';
  v_review_status text := 'clear';
  v_next_status text;
  v_disabled_count integer := 0;
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

  if p_tenant_id is null
    or p_rule_id is null
    or p_expected_version is null
    or p_expected_version <= 0
    or p_rule_price_minor is null
    or p_rule_price_minor <= 0
    or p_effective_from is null
    or (p_effective_to is not null and p_effective_to < p_effective_from)
    or (p_note is not null and char_length(p_note) > 500) then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid update customer price rule payload.'
    );
  end if;

  select *
  into v_rule
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

  v_can_override_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );
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

    select r.id
    into v_conflicting_rule_id
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.id <> p_rule_id
      and r.customer_id = v_rule.customer_id
      and r.product_id = v_rule.product_id
      and r.product_unit_id = v_rule.product_unit_id
      and r.status = 'active'
      and r.effective_from <= coalesce(p_effective_to, 'infinity'::date)
      and p_effective_from <= coalesce(r.effective_to, 'infinity'::date)
    limit 1
    for update;

    if v_conflicting_rule_id is not null then
      if not coalesce(p_acknowledge_overwrite, false) then
        perform pricing._raise_pricing_error(
          'DUPLICATE_ACTIVE_RULE',
          'An active customer price rule already overlaps this period.',
          jsonb_build_object(
            'conflictingRuleId', v_conflicting_rule_id,
            'reason', 'overwriteRequired'
          )
        );
      end if;
    end if;

    v_disabled_count := pricing._auto_disable_overlapping_customer_price_rules(
      p_tenant_id,
      p_rule_id,
      v_rule.customer_id,
      v_rule.product_id,
      v_rule.product_unit_id,
      p_effective_from,
      p_effective_to,
      v_actor_id,
      'updated'
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
      note = nullif(btrim(p_note), ''),
      status = v_next_status,
      review_status = v_review_status,
      price_check_status = v_price_check_status,
      warning_codes = v_warning_codes,
      blocking_codes = '[]'::jsonb,
      list_price_snapshot_minor = v_list_price_minor,
      floor_price_snapshot_minor = v_floor_price_minor,
      customer_phone_snapshot = coalesce(
        customer_phone_snapshot,
        partner._profile_phone(v_rule.customer_id)
      ),
      updated_by = v_actor_id,
      updated_at = statement_timestamp(),
      version = v_rule.version + 1
  where id = p_rule_id;

  insert into pricing.customer_price_rule_activities (
    tenant_id,
    customer_price_rule_id,
    activity_type,
    old_value,
    new_value,
    created_by
  ) values (
    p_tenant_id,
    p_rule_id,
    'updated',
    jsonb_build_object(
      'rule_price_minor', v_rule.rule_price_minor,
      'effective_from', v_rule.effective_from,
      'effective_to', v_rule.effective_to,
      'note', v_rule.note,
      'version', v_rule.version
    ),
    jsonb_build_object(
      'rule_price_minor', p_rule_price_minor,
      'effective_from', p_effective_from,
      'effective_to', p_effective_to,
      'note', nullif(btrim(p_note), ''),
      'version', v_rule.version + 1,
      'disabled_overlapping_count', v_disabled_count
    ),
    v_actor_id
  );

  return pricing._customer_price_rule_result(
    p_rule_id,
    v_can_override_floor
  ) -> 'rule';
end;
$$;

revoke all on function pricing.update_customer_price_rule(
  uuid, uuid, integer, bigint, date, date, text, boolean, boolean
) from public, anon;
grant execute on function pricing.update_customer_price_rule(
  uuid, uuid, integer, bigint, date, date, text, boolean, boolean
) to authenticated, service_role;

-- 3. Patch reenable_customer_price_rule to support p_acknowledge_overwrite
create or replace function pricing.reenable_customer_price_rule(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_expected_version integer,
  p_business_date date,
  p_precheck_token text default null,
  p_acknowledge_floor_warning boolean default false,
  p_acknowledge_overwrite boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_rule pricing.customer_price_rules%rowtype;
  v_context jsonb;
  v_blocking_codes jsonb;
  v_current_token text;
  v_conflicting_rule_id uuid;
  v_disabled_count integer := 0;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.reenable'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.reenable')
    );
  end if;

  if p_tenant_id is null
    or p_rule_id is null
    or p_expected_version is null
    or p_expected_version <= 0
    or p_business_date is null then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid reenable customer price rule payload.'
    );
  end if;

  select *
  into v_rule
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

  if v_rule.status <> 'disabled' then
    perform pricing._raise_pricing_error(
      'INVALID_STATUS',
      'Only a disabled customer price rule can be reenabled.',
      jsonb_build_object('status', v_rule.status)
    );
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      p_tenant_id::text || ':rule:' || v_rule.customer_id::text || ':'
        || v_rule.product_id::text || ':' || v_rule.product_unit_id::text,
      0
    )
  );

  v_context := pricing._customer_price_rule_reenable_context(
    p_tenant_id,
    p_rule_id,
    v_actor_id,
    p_business_date
  );

  v_current_token := v_context ->> 'precheck_token';
  if p_precheck_token is not null
    and v_current_token <> p_precheck_token then
    perform pricing._raise_pricing_error(
      'STATE_CHANGED',
      'Customer price rule reenable precheck is stale.',
      jsonb_build_object(
        'reason', 'precheckStale',
        'expectedVersion', p_expected_version,
        'currentVersion', v_rule.version
      )
    );
  end if;

  v_blocking_codes := v_context #> '{validation_outcome,blocking_codes}';

  if v_blocking_codes ?| array[
    'customer_reference_invalid',
    'product_unit_reference_invalid',
    'currency_mismatch'
  ] then
    perform pricing._raise_pricing_error(
      'REFERENCE_INVALID',
      'Customer price rule references are not valid for reenable.'
    );
  end if;

  if coalesce((v_context ->> 'is_expired')::boolean, false) then
    perform pricing._raise_pricing_error(
      'INVALID_STATUS',
      'Customer price rule effective period has expired.',
      jsonb_build_object('reason', 'effectivePeriodExpired')
    );
  end if;

  if coalesce((v_context ->> 'is_below_floor')::boolean, false)
    and (
      not coalesce(p_acknowledge_floor_warning, false)
      or not coalesce((v_context ->> 'can_override_floor')::boolean, false)
    ) then
    perform pricing._raise_pricing_error(
      'BELOW_FLOOR_BLOCKED',
      'Below-floor price requires acknowledgement and override permission.',
      jsonb_build_object(
        'reason', case
          when not coalesce((v_context ->> 'can_override_floor')::boolean, false)
            then 'override_permission_required'
          else 'acknowledgement_required'
        end
      )
    );
  end if;

  select r.id
  into v_conflicting_rule_id
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.id <> p_rule_id
    and r.customer_id = v_rule.customer_id
    and r.product_id = v_rule.product_id
    and r.product_unit_id = v_rule.product_unit_id
    and r.status = 'active'
    and r.effective_from <= coalesce(v_rule.effective_to, 'infinity'::date)
    and v_rule.effective_from <= coalesce(r.effective_to, 'infinity'::date)
  limit 1
  for update;

  if v_conflicting_rule_id is not null then
    if not coalesce(p_acknowledge_overwrite, false) then
      perform pricing._raise_pricing_error(
        'DUPLICATE_ACTIVE_RULE',
        'An active customer price rule already overlaps this period.',
        jsonb_build_object(
          'conflictingRuleId', v_conflicting_rule_id,
          'reason', 'overwriteRequired'
        )
      );
    end if;
  end if;

  v_disabled_count := pricing._auto_disable_overlapping_customer_price_rules(
    p_tenant_id,
    p_rule_id,
    v_rule.customer_id,
    v_rule.product_id,
    v_rule.product_unit_id,
    v_rule.effective_from,
    v_rule.effective_to,
    v_actor_id,
    'reenabled'
  );

  update pricing.customer_price_rules
  set status = 'active',
      disabled_at = null,
      disabled_by = null,
      disabled_reason = null,
      customer_phone_snapshot = coalesce(
        customer_phone_snapshot,
        partner._profile_phone(v_rule.customer_id)
      ),
      updated_by = v_actor_id,
      updated_at = statement_timestamp(),
      version = v_rule.version + 1
  where id = p_rule_id;

  insert into pricing.customer_price_rule_activities (
    tenant_id,
    customer_price_rule_id,
    activity_type,
    old_value,
    new_value,
    created_by
  ) values (
    p_tenant_id,
    p_rule_id,
    'reenabled',
    jsonb_build_object(
      'status', 'disabled',
      'version', v_rule.version
    ),
    jsonb_build_object(
      'status', 'active',
      'version', v_rule.version + 1,
      'precheck_token', p_precheck_token,
      'disabled_overlapping_count', v_disabled_count
    ),
    v_actor_id
  );

  return pricing._customer_price_rule_result(
    p_rule_id,
    coalesce((v_context ->> 'can_override_floor')::boolean, false)
  ) -> 'rule';
end;
$$;

revoke all on function pricing.reenable_customer_price_rule(
  uuid, uuid, integer, date, text, boolean, boolean
) from public, anon;
grant execute on function pricing.reenable_customer_price_rule(
  uuid, uuid, integer, date, text, boolean, boolean
) to authenticated, service_role;
