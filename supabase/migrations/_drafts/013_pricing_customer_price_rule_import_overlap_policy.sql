-- Title: Pricing import overlap policy (BR-07)
-- Kind: patch
-- Intent: pricing_customer_price_rule_import_overlap_policy
-- Context: TH-04 EP02 BR-07 import auto-disable / duplicate as warning
-- Touches: _evaluate_customer_price_rule_import_row, confirm_customer_price_rule_import
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: 010_pricing_customer_price_rule_import_s8.sql

create or replace function pricing._evaluate_customer_price_rule_import_row(
  p_tenant_id uuid,
  p_import_mode text,
  p_row jsonb,
  p_business_date date,
  p_check_duplicate boolean default true
)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_rule_text text := nullif(btrim(p_row ->> 'rule_id'), '');
  v_customer_text text := nullif(btrim(p_row ->> 'customer_id'), '');
  v_reference text := nullif(btrim(p_row ->> 'product_reference_id'), '');
  v_price_text text := nullif(btrim(p_row ->> 'price'), '');
  v_from_text text := nullif(btrim(p_row ->> 'effective_from'), '');
  v_to_text text := nullif(btrim(p_row ->> 'effective_to'), '');
  v_note text := nullif(btrim(p_row ->> 'note'), '');
  v_rule_id uuid;
  v_customer_id uuid;
  v_price_digits text;
  v_price bigint;
  v_effective_from date;
  v_effective_to date;
  v_action text := 'skip';
  v_errors jsonb := '[]'::jsonb;
  v_warnings jsonb := '[]'::jsonb;
  v_customer jsonb;
  v_catalog jsonb;
  v_product jsonb;
  v_unit jsonb;
  v_target pricing.customer_price_rules%rowtype;
  v_conflicting_rule_id uuid;
  v_can_override_floor boolean := false;
  v_floor bigint;
begin
  if p_import_mode not in ('create_only', 'update_only', 'upsert') then
    v_errors := v_errors || jsonb_build_array('IMPORT_MODE_MISMATCH');
  elsif v_rule_text is null then
    if p_import_mode = 'update_only' then
      v_errors := v_errors || jsonb_build_array('IMPORT_MODE_MISMATCH');
    else
      v_action := 'create';
    end if;
  elsif p_import_mode = 'create_only' then
    v_errors := v_errors || jsonb_build_array('IMPORT_MODE_MISMATCH');
  elsif v_rule_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    v_errors := v_errors || jsonb_build_array('INVALID_RULE_ID');
  else
    v_rule_id := v_rule_text::uuid;
    v_action := 'update';
    select r.* into v_target
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id and r.id = v_rule_id and r.status <> 'deleted';
    if not found then
      v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
    end if;
  end if;

  if v_customer_text is null or
    v_customer_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
  else
    v_customer_id := v_customer_text::uuid;
    v_customer := partner._get_customer_snapshot_for_pricing(
      p_tenant_id, v_customer_id
    );
    if not coalesce((v_customer ->> 'exists')::boolean, false)
      or not coalesce((v_customer ->> 'is_customer')::boolean, false)
      or coalesce(v_customer ->> 'status', '') <> 'active' then
      v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
    end if;
  end if;

  if v_reference is null then
    v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
  else
    v_catalog := catalog._resolve_product_unit_for_pricing_import(
      p_tenant_id, v_reference
    );
    if coalesce(v_catalog ->> 'resolution', '') = 'ambiguous' then
      v_errors := v_errors || jsonb_build_array('AMBIGUOUS_PRODUCT_UNIT');
    elsif coalesce(v_catalog ->> 'resolution', '') <> 'resolved' then
      v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
    else
      v_product := v_catalog -> 'product_unit';
      v_unit := jsonb_build_object(
        'product_unit_id', v_product -> 'product_unit_id',
        'unit_name', v_product -> 'unit_name',
        'is_base_unit', v_product -> 'is_base_unit'
      );
      if not coalesce((v_product ->> 'minor_units_valid')::boolean, false)
        or coalesce(v_product ->> 'sellable_status', '') <> 'active' then
        v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
      end if;
    end if;
  end if;

  v_price_digits := regexp_replace(coalesce(v_price_text, ''), '[,._[:space:]]', '', 'g');
  if v_price_digits !~ '^[0-9]+$'
    or length(v_price_digits) > 19
    or v_price_digits::numeric <= 0
    or v_price_digits::numeric > 9223372036854775807 then
    v_errors := v_errors || jsonb_build_array('INVALID_PRICE');
  else
    v_price := v_price_digits::bigint;
  end if;

  if v_from_text is null then
    v_warnings := v_warnings || jsonb_build_array('EFFECTIVE_FROM_DEFAULTED');
    v_effective_from := p_business_date;
  elsif v_from_text !~ '^\d{4}-\d{2}-\d{2}$'
    or to_char(to_date(v_from_text, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> v_from_text then
    v_errors := v_errors || jsonb_build_array('INVALID_DATE');
  else
    v_effective_from := v_from_text::date;
  end if;

  if v_to_text is not null then
    if v_to_text !~ '^\d{4}-\d{2}-\d{2}$'
      or to_char(to_date(v_to_text, 'YYYY-MM-DD'), 'YYYY-MM-DD') <> v_to_text then
      v_errors := v_errors || jsonb_build_array('INVALID_DATE');
    else
      v_effective_to := v_to_text::date;
    end if;
  end if;
  if v_effective_from is not null and v_effective_to is not null
    and v_effective_to < v_effective_from then
    v_errors := v_errors || jsonb_build_array('INVALID_PERIOD');
  end if;
  if v_note is not null and char_length(v_note) > 500 then
    v_errors := v_errors || jsonb_build_array('NOTE_TOO_LONG');
  end if;

  if v_action = 'update' and v_target.id is not null and v_product is not null
    and (v_target.customer_id <> v_customer_id
      or v_target.product_id <> (v_product ->> 'product_id')::uuid
      or v_target.product_unit_id <> (v_product ->> 'product_unit_id')::uuid) then
    v_errors := v_errors || jsonb_build_array('RULE_KEY_MISMATCH');
  end if;

  v_can_override_floor := iam.has_permission(
    p_tenant_id, 'pricing.customer_price_rule.override_floor_price'
  );
  v_floor := nullif(v_product ->> 'floor_price_minor', '')::bigint;
  if v_floor is not null and v_price is not null and v_price < v_floor then
    if v_can_override_floor then
      v_warnings := v_warnings || jsonb_build_array('BELOW_FLOOR_PRICE');
    else
      v_errors := v_errors || jsonb_build_array('BELOW_FLOOR_BLOCKED');
    end if;
  end if;

  if p_check_duplicate and jsonb_array_length(v_errors) = 0
    and v_customer_id is not null and v_product is not null
    and (v_action = 'create' or v_target.status <> 'disabled') then
    select r.id into v_conflicting_rule_id
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.id <> coalesce(v_rule_id, '00000000-0000-0000-0000-000000000000'::uuid)
      and r.customer_id = v_customer_id
      and r.product_id = (v_product ->> 'product_id')::uuid
      and r.product_unit_id = (v_product ->> 'product_unit_id')::uuid
      and r.status = 'active'
      and r.effective_from <= coalesce(v_effective_to, 'infinity'::date)
      and v_effective_from <= coalesce(r.effective_to, 'infinity'::date)
    order by r.created_at limit 1;
    if v_conflicting_rule_id is not null then
      v_warnings := v_warnings || jsonb_build_array('DUPLICATE_ACTIVE_RULE');
    end if;
  end if;

  if jsonb_array_length(v_errors) > 0 then v_action := 'skip'; end if;
  return jsonb_build_object(
    'row_status', case when jsonb_array_length(v_errors) > 0 then 'error'
      when jsonb_array_length(v_warnings) > 0 then 'warning' else 'valid' end,
    'action', v_action,
    'error_codes', v_errors,
    'warning_codes', v_warnings,
    'normalized_price_minor', v_price,
    'normalized_effective_from', case when v_from_text is null then null else v_effective_from end,
    'commit_effective_from', v_effective_from,
    'normalized_effective_to', v_effective_to,
    'normalized_note', v_note,
    'customer_id', v_customer_id,
    'customer_snapshot', v_customer,
    'product_snapshot', v_product,
    'unit_snapshot', v_unit,
    'unit_resolution_strategy', case coalesce(v_catalog ->> 'resolution', '')
      when 'resolved' then 'default_selling_unit'
      when 'ambiguous' then 'ambiguous' else 'not_found' end,
    'matched_rule_id', v_rule_id,
    'matched_rule_version', v_target.version,
    'matched_rule_status', v_target.status
  );
end;
$$;
revoke all on function pricing._evaluate_customer_price_rule_import_row(
  uuid, text, jsonb, date, boolean
) from public, anon, authenticated, service_role;

create or replace function pricing.confirm_customer_price_rule_import(
  p_tenant_id uuid,
  p_import_id uuid,
  p_expected_version integer,
  p_business_date date,
  p_acknowledge_warning_rows boolean
)
returns jsonb
language plpgsql security definer set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_batch pricing.customer_price_rule_imports%rowtype;
  v_row pricing.customer_price_rule_import_rows%rowtype;
  v_eval jsonb;
  v_customer jsonb;
  v_product jsonb;
  v_target pricing.customer_price_rules%rowtype;
  v_customer_id uuid;
  v_product_id uuid;
  v_product_unit_id uuid;
  v_rule_id uuid;
  v_conflicting_rule_id uuid;
  v_effective_from date;
  v_effective_to date;
  v_price bigint;
  v_floor bigint;
  v_list bigint;
  v_warnings jsonb;
  v_review_status text;
  v_price_status text;
begin
  if v_actor_id is null or not iam.has_permission(
    p_tenant_id, 'pricing.customer_price_rule.import'
  ) then perform pricing._raise_pricing_error('NO_PERMISSION', 'Import permission is required.'); end if;
  if p_business_date is null or p_expected_version is null or p_expected_version <= 0 then
    perform pricing._raise_pricing_error('VALIDATION_ERROR', 'Invalid confirm request.');
  end if;
  select b.* into v_batch from pricing.customer_price_rule_imports b
  where b.id = p_import_id and b.tenant_id = p_tenant_id for update;
  if not found then perform pricing._raise_pricing_error('NOT_FOUND', 'Import batch was not found.'); end if;
  if v_batch.status in ('completed', 'completed_with_errors') then
    return jsonb_build_object('batch', pricing._import_batch_result(p_import_id),
      'processed_at', v_batch.confirmed_at, 'is_replay', true);
  end if;
  if v_batch.status <> 'ready_to_import' then
    perform pricing._raise_pricing_error('INVALID_STATUS', 'Import batch is not ready.');
  end if;
  if v_batch.version <> p_expected_version then
    perform pricing._raise_pricing_error('STATE_CHANGED', 'Import batch version changed.');
  end if;
  if exists (select 1 from pricing.customer_price_rule_import_rows r
      where r.import_id = p_import_id and r.row_status = 'warning')
    and not coalesce(p_acknowledge_warning_rows, false) then
    perform pricing._raise_pricing_error('VALIDATION_ERROR',
      'Warning acknowledgement is required.',
      jsonb_build_object('reason', 'acknowledgementRequired'));
  end if;
  update pricing.customer_price_rule_imports set status = 'importing'
  where id = p_import_id;

  for v_row in select r.* from pricing.customer_price_rule_import_rows r
    where r.import_id = p_import_id order by r.row_number asc, r.id asc loop
    if v_row.row_status = 'error' then
      update pricing.customer_price_rule_import_rows set
        row_status = 'skipped', action = 'skip', updated_at = statement_timestamp()
      where id = v_row.id;
      continue;
    end if;
    if v_row.row_status not in ('valid', 'warning') then continue; end if;

    v_eval := pricing._evaluate_customer_price_rule_import_row(
      p_tenant_id, v_batch.import_mode,
      jsonb_build_object('rule_id', v_row.raw_rule_id,
        'customer_id', v_row.raw_customer_id,
        'product_reference_id', v_row.raw_product_reference_id,
        'price', v_row.raw_price, 'effective_from', v_row.raw_effective_from,
        'effective_to', v_row.raw_effective_to, 'note', v_row.raw_note),
      p_business_date, false
    );
    if jsonb_array_length(v_eval -> 'error_codes') > 0 then
      update pricing.customer_price_rule_import_rows set row_status = 'failed',
        action = 'skip', error_codes = v_eval -> 'error_codes',
        warning_codes = v_eval -> 'warning_codes', updated_at = statement_timestamp()
      where id = v_row.id;
      continue;
    end if;
    if (v_eval ->> 'action') = 'update' and
      v_row.matched_rule_version is distinct from (v_eval ->> 'matched_rule_version')::integer then
      update pricing.customer_price_rule_import_rows set row_status = 'failed',
        action = 'skip', error_codes = jsonb_build_array('STATE_CHANGED'),
        warning_codes = v_eval -> 'warning_codes', updated_at = statement_timestamp()
      where id = v_row.id;
      continue;
    end if;

    v_customer := partner._get_customer_snapshot_for_pricing(
      p_tenant_id, (v_eval ->> 'customer_id')::uuid
    );
    v_product := (catalog._resolve_product_unit_for_pricing_import(
      p_tenant_id, v_row.raw_product_reference_id
    )) -> 'product_unit';
    v_customer_id := (v_eval ->> 'customer_id')::uuid;
    v_product_id := (v_product ->> 'product_id')::uuid;
    v_product_unit_id := (v_product ->> 'product_unit_id')::uuid;
    v_effective_from := (v_eval ->> 'commit_effective_from')::date;
    v_effective_to := (v_eval ->> 'normalized_effective_to')::date;
    v_price := (v_eval ->> 'normalized_price_minor')::bigint;
    v_floor := nullif(v_product ->> 'floor_price_minor', '')::bigint;
    v_list := nullif(v_product ->> 'list_price_minor', '')::bigint;
    v_warnings := v_eval -> 'warning_codes';
    v_review_status := case when jsonb_array_length(v_warnings) > 0 then 'warning' else 'clear' end;
    v_price_status := case when v_floor is null then 'not_checked'
      when v_price < v_floor then 'override_allowed' else 'normal' end;

    perform pg_advisory_xact_lock(hashtextextended(
      p_tenant_id::text || ':rule:' || v_customer_id::text || ':'
        || v_product_id::text || ':' || v_product_unit_id::text, 0));

    if (v_eval ->> 'action') = 'create' then
      v_rule_id := gen_random_uuid();
      perform pricing._auto_disable_overlapping_customer_price_rules(
        p_tenant_id,
        v_rule_id,
        v_customer_id,
        v_product_id,
        v_product_unit_id,
        v_effective_from,
        v_effective_to,
        v_actor_id,
        'import_created'
      );
      insert into pricing.customer_price_rules (
        id, tenant_id, customer_id, product_id, product_unit_id,
        customer_display_name_snapshot, customer_status_snapshot,
        product_name_snapshot, product_reference_id_snapshot, product_sku_snapshot,
        unit_name_snapshot, sellable_status_snapshot, rule_price_minor,
        currency_code, rule_type, source_type, source_import_id, source_import_row_id,
        status, review_status, effective_from, effective_to,
        list_price_snapshot_minor, floor_price_snapshot_minor, price_check_status,
        warning_codes, blocking_codes, note, created_by, updated_by,
        idempotency_key, payload_hash
      ) values (
        v_rule_id, p_tenant_id, v_customer_id, v_product_id, v_product_unit_id,
        v_customer ->> 'display_name', v_customer ->> 'status',
        v_product ->> 'product_name', v_product ->> 'product_reference_id',
        v_product ->> 'sku', v_product ->> 'unit_name',
        v_product ->> 'sellable_status', v_price,
        coalesce(v_product ->> 'currency_code', 'VND'), 'special_price',
        'excel_import', p_import_id, v_row.id, 'active', v_review_status,
        v_effective_from, v_effective_to, v_list, v_floor, v_price_status,
        v_warnings, '[]'::jsonb, v_eval ->> 'normalized_note',
        v_actor_id, v_actor_id, 'import:' || v_row.id::text,
        md5((v_eval - 'customer_snapshot' - 'product_snapshot' - 'unit_snapshot')::text)
      );
      insert into pricing.customer_price_rule_activities (
        tenant_id, customer_price_rule_id, activity_type, new_value,
        import_id, import_row_id, created_by
      ) values (p_tenant_id, v_rule_id, 'import_created',
        jsonb_build_object('rule_id', v_rule_id, 'source_type', 'excel_import',
          'version', 1), p_import_id, v_row.id, v_actor_id);
    else
      select r.* into v_target from pricing.customer_price_rules r
      where r.tenant_id = p_tenant_id and r.id = (v_eval ->> 'matched_rule_id')::uuid
      for update;
      if not found or v_target.version <> (v_eval ->> 'matched_rule_version')::integer then
        update pricing.customer_price_rule_import_rows set row_status = 'failed',
          action = 'skip', error_codes = jsonb_build_array('STATE_CHANGED'),
          updated_at = statement_timestamp() where id = v_row.id;
        continue;
      end if;
      v_rule_id := v_target.id;
      if v_target.status <> 'disabled' then
        perform pricing._auto_disable_overlapping_customer_price_rules(
          p_tenant_id,
          v_rule_id,
          v_customer_id,
          v_product_id,
          v_product_unit_id,
          v_effective_from,
          v_effective_to,
          v_actor_id,
          'import_updated'
        );
      end if;
      update pricing.customer_price_rules set
        customer_display_name_snapshot = v_customer ->> 'display_name',
        customer_status_snapshot = v_customer ->> 'status',
        product_name_snapshot = v_product ->> 'product_name',
        product_reference_id_snapshot = v_product ->> 'product_reference_id',
        product_sku_snapshot = v_product ->> 'sku',
        unit_name_snapshot = v_product ->> 'unit_name',
        sellable_status_snapshot = v_product ->> 'sellable_status',
        rule_price_minor = v_price, effective_from = v_effective_from,
        effective_to = v_effective_to, note = v_eval ->> 'normalized_note',
        status = case when v_target.status = 'disabled' then 'disabled' else 'active' end,
        review_status = v_review_status, list_price_snapshot_minor = v_list,
        floor_price_snapshot_minor = v_floor, price_check_status = v_price_status,
        warning_codes = v_warnings, blocking_codes = '[]'::jsonb,
        updated_by = v_actor_id, updated_at = statement_timestamp(),
        version = v_target.version + 1
      where id = v_target.id;
      insert into pricing.customer_price_rule_activities (
        tenant_id, customer_price_rule_id, activity_type, old_value, new_value,
        import_id, import_row_id, created_by
      ) values (p_tenant_id, v_target.id, 'import_updated',
        jsonb_build_object('version', v_target.version,
          'source_type', v_target.source_type, 'status', v_target.status),
        jsonb_build_object('version', v_target.version + 1,
          'source_type', v_target.source_type,
          'status', case when v_target.status = 'disabled' then 'disabled' else 'active' end),
        p_import_id, v_row.id, v_actor_id);
    end if;
    update pricing.customer_price_rule_import_rows set row_status = 'imported',
      action = v_eval ->> 'action', normalized_price_minor = v_price,
      normalized_effective_from = v_effective_from,
      normalized_effective_to = v_effective_to,
      normalized_note = v_eval ->> 'normalized_note',
      customer_snapshot = v_customer, product_snapshot = v_product,
      unit_snapshot = v_eval -> 'unit_snapshot', warning_codes = v_warnings,
      error_codes = '[]'::jsonb, affected_rule_id = v_rule_id,
      updated_at = statement_timestamp() where id = v_row.id;
  end loop;

  update pricing.customer_price_rule_imports b set
    status = case when s.failed_rows = 0 and s.skipped_rows = 0
      then 'completed' else 'completed_with_errors' end,
    version = b.version + 1, imported_rows = s.imported_rows,
    skipped_rows = s.skipped_rows, failed_rows = s.failed_rows,
    confirmed_by = v_actor_id, confirmed_at = statement_timestamp()
  from (select
    count(*) filter (where row_status = 'imported')::integer imported_rows,
    count(*) filter (where row_status = 'skipped')::integer skipped_rows,
    count(*) filter (where row_status = 'failed')::integer failed_rows
    from pricing.customer_price_rule_import_rows where import_id = p_import_id
  ) s where b.id = p_import_id;
  return jsonb_build_object('batch', pricing._import_batch_result(p_import_id),
    'processed_at', statement_timestamp(), 'is_replay', false);
end;
$$;

revoke all on function pricing.confirm_customer_price_rule_import(uuid, uuid, integer, date, boolean)
  from public, anon;
grant execute on function pricing.confirm_customer_price_rule_import(uuid, uuid, integer, date, boolean)
  to authenticated, service_role;
