-- Title: Pricing S3 customer price rule detail
-- Kind: patch
-- Intent: pricing_customer_price_rule_detail_s3
-- Context: TH-04 EP02 S3 CONTRACT + BE
-- Touches: get_customer_price_rule_detail
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: 004_pricing_customer_price_rule_s1.sql, 001_partner_pricing_customer_snapshot.sql, 002_catalog_pricing_price_band_snapshot.sql

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
  v_actor_id uuid := auth.uid();
  v_rule pricing.customer_price_rules%rowtype;
  v_customer jsonb;
  v_product jsonb;
  v_customer_state text;
  v_product_unit_state text;
  v_price_band_state text;
  v_issue_codes jsonb := '[]'::jsonb;
  v_used_stored boolean := false;
  v_can_view_floor boolean;
  v_can_view_history boolean;
  v_list_price_minor bigint;
  v_floor_price_minor bigint;
  v_selected_list bigint;
  v_selected_floor bigint;
  v_warning_codes jsonb;
  v_derived_status text;
  v_available_actions jsonb := '[]'::jsonb;
  v_source_hidden boolean;
begin
  if v_actor_id is null then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Authenticated actor is required.',
      '{}'::jsonb
    );
  end if;

  if p_tenant_id is null or p_rule_id is null or p_business_date is null then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'tenantId, ruleId, and businessDate are required.',
      jsonb_build_object(
        'fieldErrors',
        jsonb_build_object(
          'tenantId', case when p_tenant_id is null then 'required' else null end,
          'ruleId', case when p_rule_id is null then 'required' else null end,
          'businessDate', case when p_business_date is null then 'required' else null end
        )
      )
    );
  end if;

  if not iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.view'
  ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Missing permission to view customer price rules.',
      jsonb_build_object(
        'permission',
        'pricing.customer_price_rule.view'
      )
    );
  end if;

  select *
  into v_rule
  from pricing.customer_price_rules r
  where r.tenant_id = p_tenant_id
    and r.id = p_rule_id
    and r.status <> 'deleted';

  if not found then
    perform pricing._raise_pricing_error(
      'NOT_FOUND',
      'Customer price rule was not found.',
      '{}'::jsonb
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

  if coalesce((v_customer ->> 'exists')::boolean, false) is false then
    v_customer_state := 'missing';
    v_issue_codes := v_issue_codes || jsonb_build_array('customer_reference_missing');
  elsif coalesce((v_customer ->> 'is_customer')::boolean, false) is false
    or coalesce(v_customer ->> 'status', '') not in ('active') then
    v_customer_state := 'inactive';
    v_issue_codes := v_issue_codes || jsonb_build_array('customer_reference_inactive');
  else
    v_customer_state := 'valid';
  end if;

  if coalesce((v_product ->> 'exists')::boolean, false) is false then
    v_product_unit_state := 'missing';
    v_issue_codes := v_issue_codes || jsonb_build_array('product_unit_reference_missing');
  elsif coalesce((v_product ->> 'sellable')::boolean, false) is false then
    v_product_unit_state := 'inactive';
    v_issue_codes := v_issue_codes || jsonb_build_array('product_unit_reference_inactive');
  else
    v_product_unit_state := 'valid';
  end if;

  if coalesce((v_product ->> 'exists')::boolean, false)
    and coalesce((v_product ->> 'minor_units_valid')::boolean, false) is false then
    v_price_band_state := 'invalid_minor_units';
    v_issue_codes := v_issue_codes || jsonb_build_array('price_band_minor_units_invalid');
  elsif coalesce((v_product ->> 'exists')::boolean, false)
    and coalesce(v_product ->> 'currency_code', '') <> ''
    and upper(v_product ->> 'currency_code') <> upper(v_rule.currency_code) then
    v_price_band_state := 'currency_mismatch';
    v_issue_codes := v_issue_codes || jsonb_build_array('price_band_currency_mismatch');
  elsif coalesce((v_product ->> 'exists')::boolean, false)
    and coalesce((v_product ->> 'minor_units_valid')::boolean, false)
    and upper(coalesce(v_product ->> 'currency_code', '')) = upper(v_rule.currency_code) then
    v_price_band_state := 'current';
  else
    v_price_band_state := 'unavailable';
  end if;

  v_list_price_minor := nullif(v_product ->> 'list_price_minor', '')::bigint;
  v_floor_price_minor := nullif(v_product ->> 'floor_price_minor', '')::bigint;

  if v_price_band_state = 'current' then
    v_selected_list := v_list_price_minor;
    v_selected_floor := v_floor_price_minor;
    v_used_stored := false;
  else
    v_selected_list := v_rule.list_price_snapshot_minor;
    v_selected_floor := v_rule.floor_price_snapshot_minor;
    v_used_stored := true;
  end if;

  v_can_view_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );
  v_can_view_history := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.view_history'
  );

  v_warning_codes := coalesce(v_rule.warning_codes, '[]'::jsonb);
  if v_selected_floor is not null
    and v_rule.rule_price_minor < v_selected_floor
    and not exists (
      select 1
      from jsonb_array_elements_text(v_warning_codes) as warning_code
      where warning_code = 'below_floor_price'
    ) then
    v_warning_codes := v_warning_codes || jsonb_build_array('below_floor_price');
  end if;

  v_derived_status := case
    when v_rule.status = 'disabled' then 'disabled'
    when v_rule.status = 'needs_review'
      or v_rule.review_status in ('blocked', 'needs_review')
      or jsonb_array_length(v_rule.blocking_codes) > 0 then 'needs_review'
    when v_rule.effective_to is not null
      and v_rule.effective_to < p_business_date then 'expired'
    when v_rule.effective_from > p_business_date then 'not_yet_effective'
    else 'applying'
  end;

  if v_rule.status in ('active', 'needs_review', 'disabled')
    and iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.update'
    ) then
    v_available_actions := v_available_actions || jsonb_build_array('edit');
  end if;

  if v_rule.status in ('active', 'needs_review')
    and iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.disable'
    ) then
    v_available_actions := v_available_actions || jsonb_build_array('disable');
  end if;

  if v_rule.status = 'disabled'
    and iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.reenable'
    ) then
    v_available_actions := v_available_actions || jsonb_build_array('reenable');
  end if;

  if v_can_view_history then
    v_available_actions := v_available_actions || jsonb_build_array('history');
  end if;

  v_source_hidden := not v_can_view_history;

  return jsonb_build_object(
    'id', v_rule.id,
    'customer', jsonb_build_object(
      'customer_id', v_rule.customer_id,
      'display_name', v_rule.customer_display_name_snapshot,
      'status', v_rule.customer_status_snapshot
    ),
    'product_unit', jsonb_build_object(
      'product_id', v_rule.product_id,
      'product_unit_id', v_rule.product_unit_id,
      'product_name', v_rule.product_name_snapshot,
      'product_reference_id', v_rule.product_reference_id_snapshot,
      'sku', v_rule.product_sku_snapshot,
      'unit_name', v_rule.unit_name_snapshot,
      'sellable_status', v_rule.sellable_status_snapshot
    ),
    'price', jsonb_build_object(
      'amount_minor', v_rule.rule_price_minor,
      'currency_code', v_rule.currency_code
    ),
    'effective_period', jsonb_build_object(
      'effective_from', v_rule.effective_from,
      'effective_to', v_rule.effective_to
    ),
    'rule_type', v_rule.rule_type,
    'source_type', v_rule.source_type,
    'persisted_status', v_rule.status,
    'derived_status', v_derived_status,
    'note', v_rule.note,
    'validation_outcome', jsonb_build_object(
      'outcome', case
        when jsonb_array_length(v_rule.blocking_codes) > 0 then 'blocked'
        when jsonb_array_length(v_warning_codes) > 0 then 'warning'
        when v_rule.price_check_status = 'not_checked' then 'notChecked'
        else 'valid'
      end,
      'warning_codes', v_warning_codes,
      'blocking_codes', v_rule.blocking_codes,
      'list_price', case
        when v_selected_list is null then null
        else jsonb_build_object(
          'amount_minor', v_selected_list,
          'currency_code', v_rule.currency_code
        )
      end,
      'floor_price', case
        when v_can_view_floor and v_selected_floor is not null then
          jsonb_build_object(
            'amount_minor', v_selected_floor,
            'currency_code', v_rule.currency_code
          )
        else null
      end,
      'floor_price_hidden',
        v_selected_floor is not null and not v_can_view_floor
    ),
    'reference_health', jsonb_build_object(
      'customer_state', v_customer_state,
      'product_unit_state', v_product_unit_state,
      'price_band_state', v_price_band_state,
      'issue_codes', v_issue_codes,
      'used_stored_price_band_snapshot', v_used_stored
    ),
    'source_trace', jsonb_build_object(
      'hidden', v_source_hidden,
      'source_import_id', null,
      'source_import_row_id', null,
      'source_order_id', null,
      'source_order_line_id', null
    ),
    'created_by', v_rule.created_by,
    'created_at', v_rule.created_at,
    'updated_by', v_rule.updated_by,
    'updated_at', v_rule.updated_at,
    'version', v_rule.version,
    'available_actions', v_available_actions
  );
end;
$$;

revoke all on function pricing.get_customer_price_rule_detail(uuid, uuid, date) from public, anon;
grant execute on function pricing.get_customer_price_rule_detail(uuid, uuid, date) to authenticated, service_role;
