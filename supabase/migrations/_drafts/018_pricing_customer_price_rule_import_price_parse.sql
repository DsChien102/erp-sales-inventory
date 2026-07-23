-- Title: Pricing import integer price parse
-- Kind: patch
-- Intent: pricing_customer_price_rule_import_price_parse
-- Touches: _evaluate_customer_price_rule_import_row
-- Safety: accepts Excel N.0 / N.00 and VN 100.000; rejects non-zero fraction
-- Depends on: 017

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
  v_product_text text := nullif(btrim(p_row ->> 'product_id'), '');
  v_unit_text text := nullif(btrim(p_row ->> 'product_unit_id'), '');
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
  v_match jsonb;
  v_match_count integer := 0;
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

  if v_product_text is null
    or v_unit_text is null
    or v_product_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
    or v_unit_text !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    v_errors := v_errors || jsonb_build_array('REFERENCE_INVALID');
  else
    v_catalog := catalog._resolve_product_unit_for_pricing_import(
      p_tenant_id,
      v_product_text::uuid,
      v_unit_text::uuid
    );
    if coalesce(v_catalog ->> 'resolution', '') <> 'resolved' then
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

  -- Integer VND minor: accept Excel N / N.0 / N.00 and VN thousands 100.000;
  -- reject non-zero fractional part (e.g. 100000.5).
  if v_price_text is null then
    v_price_digits := null;
  elsif v_price_text ~ '^\d{1,3}(\.\d{3})+$' then
    -- VN thousand separators: 100.000 / 1.000.000
    v_price_digits := replace(v_price_text, '.', '');
  elsif v_price_text ~ '^\d+\.(0{1,2})$' then
    -- Excel integer serialized as float: 100000.0 / 100000.00
    v_price_digits := split_part(v_price_text, '.', 1);
  elsif v_price_text ~ '^\d+$' then
    v_price_digits := v_price_text;
  elsif v_price_text ~ '^\d{1,3}(,\d{3})+$' then
    -- Comma thousand separators: 100,000
    v_price_digits := replace(v_price_text, ',', '');
  else
    v_price_digits := null;
  end if;

  if v_price_digits is null
    or v_price_digits !~ '^[0-9]+$'
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
    v_match := pricing._match_customer_price_rule_import_overlap(
      p_tenant_id,
      v_customer_id,
      (v_product ->> 'product_id')::uuid,
      (v_product ->> 'product_unit_id')::uuid,
      v_effective_from,
      v_effective_to,
      case when v_rule_id is null then null else v_rule_id end
    );
    v_match_count := (v_match ->> 'match_count')::integer;

    if v_rule_text is null and p_import_mode = 'upsert' then
      if v_match_count = 0 then
        v_action := 'create';
      elsif v_match_count = 1 then
        v_action := 'update';
        v_rule_id := (v_match ->> 'rule_id')::uuid;
        select r.* into v_target
        from pricing.customer_price_rules r
        where r.tenant_id = p_tenant_id and r.id = v_rule_id;
      else
        v_errors := v_errors || jsonb_build_array('AMBIGUOUS_OVERLAPPING_RULES');
      end if;
    elsif v_match_count > 0 then
      v_errors := v_errors || jsonb_build_array('DUPLICATE_ACTIVE_RULE');
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
    'unit_resolution_strategy', case
      when coalesce(v_catalog ->> 'resolution', '') = 'resolved'
        then 'explicit_selection'
      else 'not_found'
    end,
    'matched_rule_id', v_rule_id,
    'matched_rule_version', v_target.version,
    'matched_rule_status', v_target.status
  );
end;
$$;
revoke all on function pricing._evaluate_customer_price_rule_import_row(
  uuid, text, jsonb, date, boolean
) from public, anon, authenticated, service_role;
