-- Title: Add customer phone snapshot to pricing rules, search, detail, disable, and reenable
-- Kind: patch
-- Intent: pricing_customer_phone_snapshot
-- Context: TH-04 EP02 — FR-03 "số điện thoại khách hàng" thay "mã khách hàng" đồng bộ toàn bộ luồng
-- Touches: _get_customer_snapshot_for_pricing, _customer_price_rule_result, _get_customer_price_rule_detail_s3, search_customer_price_rules
-- Safety: idempotent; medium
-- Depends on: 20260725001_partner_pricing_customer_snapshot.sql, 20260725004_pricing_customer_price_rule_s1.sql, 20260725006_pricing_customer_price_rule_detail_s3.sql, 20260725015_pricing_customer_price_rule_search_list_price_live.sql

-- 1. Patch partner._get_customer_snapshot_for_pricing to include phone number
create or replace function partner._get_customer_snapshot_for_pricing(
  p_tenant_id uuid,
  p_customer_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = partner, pg_temp
as $$
declare
  v_partner record;
begin
  select
    p.partner_id,
    p.display_name,
    p.status::text as status,
    exists (
      select 1
      from partner.partner_roles pr
      where pr.tenant_id = p_tenant_id
        and pr.partner_id = p.partner_id
        and pr.role = 'customer'::partner.partner_role_type
        and pr.is_active = true
    ) as is_customer
  into v_partner
  from partner.partners p
  where p.tenant_id = p_tenant_id
    and p.partner_id = p_customer_id;

  if not found then
    return jsonb_build_object(
      'customer_id', p_customer_id,
      'display_name', '',
      'phone', null,
      'status', 'not_found',
      'exists', false,
      'is_customer', false
    );
  end if;

  return jsonb_build_object(
    'customer_id', v_partner.partner_id,
    'display_name', v_partner.display_name,
    'phone', partner._profile_phone(v_partner.partner_id),
    'status', v_partner.status,
    'exists', true,
    'is_customer', v_partner.is_customer
  );
end;
$$;

revoke all on function partner._get_customer_snapshot_for_pricing(uuid, uuid)
  from public, anon;
grant execute on function partner._get_customer_snapshot_for_pricing(uuid, uuid)
  to authenticated, service_role;

-- 2. Add customer_phone_snapshot column to pricing.customer_price_rules table
alter table pricing.customer_price_rules
  add column if not exists customer_phone_snapshot text;

-- 3. Backfill existing pricing.customer_price_rules records with phone numbers
update pricing.customer_price_rules r
set customer_phone_snapshot = partner._profile_phone(r.customer_id)
where r.customer_phone_snapshot is null;

-- 4. Patch pricing._customer_price_rule_result helper to include phone (language sql)
create or replace function pricing._customer_price_rule_result(
  p_rule_id uuid,
  p_can_view_floor boolean
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'rule', jsonb_build_object(
      'id', r.id,
      'customer', jsonb_build_object(
        'customer_id', r.customer_id,
        'display_name', r.customer_display_name_snapshot,
        'phone', coalesce(r.customer_phone_snapshot, partner._profile_phone(r.customer_id)),
        'status', r.customer_status_snapshot
      ),
      'product_unit', jsonb_build_object(
        'product_id', r.product_id,
        'product_unit_id', r.product_unit_id,
        'product_name', r.product_name_snapshot,
        'product_reference_id', r.product_reference_id_snapshot,
        'sku', r.product_sku_snapshot,
        'unit_name', r.unit_name_snapshot,
        'sellable_status', r.sellable_status_snapshot
      ),
      'price', jsonb_build_object(
        'amount_minor', r.rule_price_minor,
        'currency_code', r.currency_code
      ),
      'effective_period', jsonb_build_object(
        'effective_from', r.effective_from,
        'effective_to', r.effective_to
      ),
      'rule_type', r.rule_type,
      'source_type', r.source_type,
      'persisted_status', r.status,
      'derived_status', case
        when r.status = 'disabled' then 'disabled'
        when r.status = 'needs_review'
          or r.review_status in ('blocked', 'needs_review')
          or jsonb_array_length(r.blocking_codes) > 0 then 'needs_review'
        when r.effective_to is not null
          and r.effective_to < current_date then 'expired'
        when r.effective_from > current_date then 'not_yet_effective'
        else 'applying'
      end,
      'note', r.note,
      'disabled_at', r.disabled_at,
      'disabled_by', r.disabled_by,
      'disabled_reason', r.disabled_reason,
      'validation_outcome', jsonb_build_object(
        'outcome', case r.price_check_status
          when 'not_checked' then 'notChecked'
          when 'override_allowed' then 'warning'
          else 'valid'
        end,
        'warning_codes', r.warning_codes,
        'blocking_codes', r.blocking_codes,
        'list_price', case
          when r.list_price_snapshot_minor is null then null
          else jsonb_build_object(
            'amount_minor', r.list_price_snapshot_minor,
            'currency_code', r.currency_code
          )
        end,
        'floor_price', case
          when p_can_view_floor and r.floor_price_snapshot_minor is not null
            then jsonb_build_object(
              'amount_minor', r.floor_price_snapshot_minor,
              'currency_code', r.currency_code
            )
          else null
        end,
        'floor_price_hidden',
          r.floor_price_snapshot_minor is not null and not p_can_view_floor
      ),
      'reference_health', jsonb_build_object(
        'customer_state', 'valid',
        'product_unit_state', 'valid',
        'price_band_state', case
          when r.price_check_status in (
            'not_checked',
            'normal',
            'override_allowed'
          ) then 'current'
          else 'unavailable'
        end,
        'issue_codes', '[]'::jsonb,
        'used_stored_price_band_snapshot', false
      ),
      'source_trace', jsonb_build_object(
        'hidden', false,
        'source_import_id', null,
        'source_import_row_id', null,
        'source_order_id', null,
        'source_order_line_id', null
      ),
      'created_by', r.created_by,
      'created_at', r.created_at,
      'updated_by', r.updated_by,
      'updated_at', r.updated_at,
      'version', r.version,
      'available_actions', (
        select coalesce(jsonb_agg(action order by ordinality), '[]'::jsonb)
        from (
          select action, ordinality
          from unnest(
            array[
              case
                when r.status in ('active', 'needs_review', 'disabled')
                  and iam.has_permission(
                    r.tenant_id,
                    'pricing.customer_price_rule.update'
                  )
                then 'edit'
              end,
              case
                when r.status in ('active', 'needs_review')
                  and iam.has_permission(
                    r.tenant_id,
                    'pricing.customer_price_rule.disable'
                  )
                then 'disable'
              end,
              case
                when r.status = 'disabled'
                  and iam.has_permission(
                    r.tenant_id,
                    'pricing.customer_price_rule.reenable'
                  )
                then 'reenable'
              end,
              case
                when iam.has_permission(
                  r.tenant_id,
                  'pricing.customer_price_rule.view_history'
                )
                then 'history'
              end
            ]
          ) with ordinality as t(action, ordinality)
          where action is not null
        ) actions
      )
    ),
    'warnings', coalesce(
      (
        select jsonb_agg(jsonb_build_object('code', warning_code))
        from jsonb_array_elements_text(r.warning_codes) as warning_code
      ),
      '[]'::jsonb
    )
  )
  from pricing.customer_price_rules r
  where r.id = p_rule_id;
$$;

revoke all on function pricing._customer_price_rule_result(uuid, boolean)
  from public, anon, authenticated, service_role;

-- 5. Patch pricing._get_customer_price_rule_detail_s3 to include phone in customer object
create or replace function pricing._get_customer_price_rule_detail_s3(
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
      'display_name', coalesce(nullif(v_rule.customer_display_name_snapshot, ''), v_customer ->> 'display_name'),
      'phone', coalesce(v_rule.customer_phone_snapshot, partner._profile_phone(v_rule.customer_id)),
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

revoke all on function pricing._get_customer_price_rule_detail_s3(uuid, uuid, date)
  from public, anon;
grant execute on function pricing._get_customer_price_rule_detail_s3(uuid, uuid, date)
  to authenticated, service_role;

-- 6. Update pricing.search_customer_price_rules
drop function if exists pricing.search_customer_price_rules(
  uuid, text, text, text[], text[], uuid, uuid, date, text, integer
);
drop function if exists pricing.search_customer_price_rules(
  uuid, date, text, text, text[], text[], uuid, uuid, text, integer
);

create or replace function pricing.search_customer_price_rules(
  p_tenant_id uuid,
  p_business_date date,
  p_q text default null,
  p_quick_filter text default 'all',
  p_statuses text[] default null,
  p_sources text[] default null,
  p_customer_id uuid default null,
  p_product_id uuid default null,
  p_cursor text default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_q text := nullif(btrim(coalesce(p_q, '')), '');
  v_search_q text;
  v_quick_filter text := coalesce(nullif(btrim(p_quick_filter), ''), 'all');
  v_cursor jsonb;
  v_cursor_updated_at timestamptz;
  v_cursor_id uuid;
  v_items jsonb := '[]'::jsonb;
  v_has_more boolean := false;
  v_next_cursor_json jsonb;
  v_next_cursor text;
  v_available_actions jsonb := '[]'::jsonb;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.view'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object('permission', 'pricing.customer_price_rule.view')
    );
  end if;

  if p_tenant_id is null
    or p_business_date is null
    or p_limit is null
    or p_limit < 1
    or p_limit > 100
    or (v_q is not null and char_length(v_q) > 120)
    or v_quick_filter not in ('all', 'applying', 'below_floor')
    or coalesce(p_statuses, array[]::text[]) <@ array[
      'applying',
      'not_yet_effective',
      'disabled',
      'expired',
      'needs_review'
    ]::text[] is false
    or coalesce(p_sources, array[]::text[]) <@ array[
      'manual',
      'excel_import',
      'sales_order',
      'migration'
    ]::text[] is false then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid customer price rule search payload.'
    );
  end if;

  v_search_q := case
    when v_q is null then null
    else extensions.unaccent(lower(v_q))
  end;

  if nullif(btrim(coalesce(p_cursor, '')), '') is not null then
    begin
      v_cursor := p_cursor::jsonb;

      if jsonb_typeof(v_cursor) <> 'object'
        or not v_cursor ? 'updated_at'
        or not v_cursor ? 'id'
        or nullif(v_cursor ->> 'updated_at', '') is null
        or nullif(v_cursor ->> 'id', '') is null then
        raise exception 'invalid cursor';
      end if;

      v_cursor_updated_at := (v_cursor ->> 'updated_at')::timestamptz;
      v_cursor_id := (v_cursor ->> 'id')::uuid;
    exception
      when others then
        perform pricing._raise_pricing_error(
          'VALIDATION_ERROR',
          'Invalid customer price rule search cursor.',
          jsonb_build_object('field', 'cursor')
        );
    end;
  end if;

  with projected as (
    select
      r.*,
      case
        when r.status = 'disabled' then 'disabled'
        when r.status = 'needs_review'
          or r.review_status in ('blocked', 'needs_review')
          or jsonb_array_length(r.blocking_codes) > 0
          then 'needs_review'
        when r.effective_to is not null
          and r.effective_to < p_business_date then 'expired'
        when r.effective_from > p_business_date then 'not_yet_effective'
        else 'applying'
      end as derived_status
    from pricing.customer_price_rules r
    where r.tenant_id = p_tenant_id
      and r.status <> 'deleted'
      and r.deleted_at is null
  ),
  filtered as (
    select r.*
    from projected r
    where (
        v_search_q is null
        or extensions.unaccent(lower(r.customer_display_name_snapshot))
          like '%' || v_search_q || '%'
        or lower(coalesce(r.customer_phone_snapshot, ''))
          like '%' || v_search_q || '%'
        or lower(r.customer_id::text) like '%' || v_search_q || '%'
        or extensions.unaccent(lower(r.product_name_snapshot))
          like '%' || v_search_q || '%'
        or lower(r.product_id::text) like '%' || v_search_q || '%'
        or extensions.unaccent(lower(r.product_reference_id_snapshot))
          like '%' || v_search_q || '%'
        or extensions.unaccent(lower(coalesce(r.product_sku_snapshot, '')))
          like '%' || v_search_q || '%'
      )
      and (p_customer_id is null or r.customer_id = p_customer_id)
      and (p_product_id is null or r.product_id = p_product_id)
      and (p_sources is null or r.source_type = any(p_sources))
      and (p_statuses is null or r.derived_status = any(p_statuses))
      and (
        v_quick_filter = 'all'
        or (v_quick_filter = 'applying' and r.derived_status = 'applying')
        or (
          v_quick_filter = 'below_floor'
          and (
            r.warning_codes ? 'below_floor_price'
            or (
              r.floor_price_snapshot_minor is not null
              and r.rule_price_minor < r.floor_price_snapshot_minor
            )
          )
        )
      )
      and (
        v_cursor_updated_at is null
        or r.updated_at < v_cursor_updated_at
        or (
          r.updated_at = v_cursor_updated_at
          and r.id < v_cursor_id
        )
      )
  ),
  page_rows as (
    select r.*
    from filtered r
    order by r.updated_at desc, r.id desc
    limit p_limit + 1
  ),
  enriched as (
    select
      r.*,
      catalog._get_product_price_band_snapshot_for_pricing(
        p_tenant_id,
        r.product_id,
        r.product_unit_id
      ) as price_band
    from page_rows r
  ),
  decorated as (
    select
      r.*,
      row_number() over (order by r.updated_at desc, r.id desc) as row_number,
      case
        when coalesce((r.price_band ->> 'exists')::boolean, false)
          and coalesce((r.price_band ->> 'minor_units_valid')::boolean, false)
          and upper(coalesce(r.price_band ->> 'currency_code', ''))
            = upper(r.currency_code)
        then nullif(r.price_band ->> 'list_price_minor', '')::bigint
        else r.list_price_snapshot_minor
      end as selected_list_price_minor,
      case
        when coalesce((r.price_band ->> 'exists')::boolean, false)
          and coalesce((r.price_band ->> 'minor_units_valid')::boolean, false)
          and upper(coalesce(r.price_band ->> 'currency_code', ''))
            = upper(r.currency_code)
        then nullif(r.price_band ->> 'floor_price_minor', '')::bigint
        else r.floor_price_snapshot_minor
      end as selected_floor_price_minor
    from enriched r
  ),
  items as (
    select
      d.*,
      jsonb_build_object(
        'id', d.id,
        'customer', jsonb_build_object(
          'customer_id', d.customer_id,
          'display_name', d.customer_display_name_snapshot,
          'phone', coalesce(d.customer_phone_snapshot, partner._profile_phone(d.customer_id)),
          'status', d.customer_status_snapshot
        ),
        'product_unit', jsonb_build_object(
          'product_id', d.product_id,
          'product_unit_id', d.product_unit_id,
          'product_name', d.product_name_snapshot,
          'product_reference_id', d.product_reference_id_snapshot,
          'sku', d.product_sku_snapshot,
          'unit_name', d.unit_name_snapshot,
          'sellable_status', d.sellable_status_snapshot
        ),
        'price', jsonb_build_object(
          'amount_minor', d.rule_price_minor,
          'currency_code', d.currency_code
        ),
        'effective_period', jsonb_build_object(
          'effective_from', d.effective_from,
          'effective_to', d.effective_to
        ),
        'rule_type', d.rule_type,
        'source_type', d.source_type,
        'persisted_status', d.status,
        'derived_status', d.derived_status,
        'validation_outcome', jsonb_build_object(
          'outcome', case
            when jsonb_array_length(d.blocking_codes) > 0 then 'blocked'
            when jsonb_array_length(d.warning_codes) > 0 then 'warning'
            when d.price_check_status = 'not_checked' then 'notChecked'
            else 'valid'
          end,
          'warning_codes', d.warning_codes,
          'blocking_codes', d.blocking_codes,
          'list_price', case
            when d.selected_list_price_minor is null then null
            else jsonb_build_object(
              'amount_minor', d.selected_list_price_minor,
              'currency_code', d.currency_code
            )
          end,
          'floor_price_hidden', d.selected_floor_price_minor is not null
        ),
        'updated_at', d.updated_at
      ) as item
    from decorated d
  )
  select
    coalesce(
      jsonb_agg(i.item order by i.updated_at desc, i.id desc)
        filter (where i.row_number <= p_limit),
      '[]'::jsonb
    ),
    count(*) > p_limit,
    (
      array_agg(
        jsonb_build_object('updated_at', i.updated_at, 'id', i.id)
        order by i.updated_at desc, i.id desc
      ) filter (where i.row_number = p_limit)
    )[1]
  into v_items, v_has_more, v_next_cursor_json
  from items i;

  if v_has_more then
    v_next_cursor := v_next_cursor_json::text;
  end if;

  if iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.create'
  ) then
    v_available_actions := v_available_actions || jsonb_build_array(
      'create_manual'
    );
  end if;

  if iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.import'
  ) then
    v_available_actions := v_available_actions || jsonb_build_array('import');
  end if;

  return jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor,
    'has_more', v_has_more,
    'available_actions', v_available_actions
  );
end;
$$;

revoke all on function pricing.search_customer_price_rules(
  uuid, date, text, text, text[], text[], uuid, uuid, text, integer
) from public, anon;

grant execute on function pricing.search_customer_price_rules(
  uuid, date, text, text, text[], text[], uuid, uuid, text, integer
) to authenticated, service_role;
