-- Title: Pricing S10 customer price rule activity history
-- Kind: patch
-- Intent: pricing_customer_price_rule_history_s10
-- Context: TH-04 EP02 S10 CONTRACT + BE
-- Touches: _customer_price_rule_history_snapshot, get_customer_price_rule_history
-- Safety: draft only; do not apply or promote without explicit migration review
-- Depends on: pricing_customer_price_rule_s1.sql, pricing_customer_price_rule_update_s5.sql, pricing_customer_price_rule_disable_s6.sql, pricing_customer_price_rule_reenable_s7.sql, pricing_customer_price_rule_import_s8.sql, pricing_remembered_price_from_order_s9.sql

create index if not exists customer_price_rule_activities_history_page_idx
  on pricing.customer_price_rule_activities (
    tenant_id,
    customer_price_rule_id,
    created_at desc,
    id desc
  );

create or replace function pricing._customer_price_rule_history_snapshot(
  p_snapshot jsonb,
  p_can_view_floor boolean
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_snapshot is null then
    return null;
  end if;

  if p_can_view_floor then
    return p_snapshot;
  end if;

  return p_snapshot
    - 'floor_price_snapshot_minor'
    - 'floor_price_minor'
    - 'floor_price';
end;
$$;

revoke all on function pricing._customer_price_rule_history_snapshot(jsonb, boolean)
  from public, anon, authenticated, service_role;

create or replace function pricing.get_customer_price_rule_history(
  p_tenant_id uuid,
  p_rule_id uuid,
  p_cursor text default null,
  p_limit integer default 50
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
  v_can_view_floor boolean;
  v_cursor jsonb;
  v_cursor_created_at timestamptz;
  v_cursor_id uuid;
  v_encoded text;
  v_items jsonb := '[]'::jsonb;
  v_has_more boolean := false;
  v_next_cursor text;
begin
  if v_actor_id is null
    or not iam.has_permission(
      p_tenant_id,
      'pricing.customer_price_rule.view_history'
    ) then
    perform pricing._raise_pricing_error(
      'NO_PERMISSION',
      'Permission denied.',
      jsonb_build_object(
        'permission',
        'pricing.customer_price_rule.view_history'
      )
    );
  end if;

  if p_tenant_id is null
    or p_rule_id is null
    or p_limit is null
    or p_limit < 1
    or p_limit > 100 then
    perform pricing._raise_pricing_error(
      'VALIDATION_ERROR',
      'Invalid customer price rule history payload.'
    );
  end if;

  select r.*
  into v_rule
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

  if nullif(btrim(coalesce(p_cursor, '')), '') is not null then
    begin
      v_encoded := translate(p_cursor, '-_', '+/');
      v_encoded := v_encoded || repeat('=', (4 - length(v_encoded) % 4) % 4);
      v_cursor := convert_from(decode(v_encoded, 'base64'), 'utf8')::jsonb;

      if jsonb_typeof(v_cursor) <> 'object'
        or not v_cursor ? 'createdAt'
        or not v_cursor ? 'id'
        or nullif(v_cursor ->> 'createdAt', '') is null
        or nullif(v_cursor ->> 'id', '') is null then
        raise exception 'invalid cursor';
      end if;

      v_cursor_created_at := (v_cursor ->> 'createdAt')::timestamptz;
      v_cursor_id := (v_cursor ->> 'id')::uuid;
      if v_cursor_created_at is null or v_cursor_id is null then
        raise exception 'invalid cursor';
      end if;
    exception
      when others then
        perform pricing._raise_pricing_error(
          'VALIDATION_ERROR',
          'Invalid customer price rule history cursor.',
          jsonb_build_object('fieldErrors', jsonb_build_object('cursor', 'invalid'))
        );
    end;
  end if;

  v_can_view_floor := iam.has_permission(
    p_tenant_id,
    'pricing.customer_price_rule.override_floor_price'
  );

  with page_rows as (
    select
      a.*,
      row_number() over (
        order by a.created_at desc, a.id desc
      ) as row_number
    from pricing.customer_price_rule_activities a
    where a.tenant_id = p_tenant_id
      and a.customer_price_rule_id = p_rule_id
      and (
        p_cursor is null
        or nullif(btrim(coalesce(p_cursor, '')), '') is null
        or a.created_at < v_cursor_created_at
        or (
          a.created_at = v_cursor_created_at
          and a.id < v_cursor_id
        )
      )
    order by a.created_at desc, a.id desc
    limit p_limit + 1
  ),
  decorated as (
    select
      r.*,
      case
        when nullif(r.new_value ->> 'source_type', '') is not null
          then r.new_value ->> 'source_type'
        when nullif(r.old_value ->> 'source_type', '') is not null
          then r.old_value ->> 'source_type'
        when r.activity_type in ('import_created', 'import_updated')
          then 'excel_import'
        when r.activity_type in ('memory_created', 'memory_updated')
          then 'sales_order'
        else v_rule.source_type
      end as resolved_source_type,
      coalesce(
        nullif(r.new_value ->> 'reason', ''),
        nullif(r.new_value ->> 'disabled_reason', '')
      ) as resolved_reason,
      case
        when r.created_by is null then null
        else left(r.created_by::text, 8)
      end as actor_display_name,
      r.created_by is null as is_system_actor,
      pricing._customer_price_rule_history_snapshot(
        r.old_value,
        v_can_view_floor
      ) as sanitized_old_value,
      pricing._customer_price_rule_history_snapshot(
        r.new_value,
        v_can_view_floor
      ) as sanitized_new_value,
      (
        not v_can_view_floor
        and (
          (r.old_value ? 'floor_price_snapshot_minor')
          or (r.old_value ? 'floor_price_minor')
          or (r.old_value ? 'floor_price')
          or (r.new_value ? 'floor_price_snapshot_minor')
          or (r.new_value ? 'floor_price_minor')
          or (r.new_value ? 'floor_price')
        )
      ) as sensitive_values_hidden
    from page_rows r
  ),
  projected as (
    select
      d.row_number,
      d.created_at,
      d.id,
      jsonb_build_object(
        'id', d.id,
        'activity_type', d.activity_type,
        'actor', jsonb_build_object(
          'actor_id', d.created_by,
          'display_name', case
            when d.is_system_actor then 'System/Migration'
            else d.actor_display_name
          end,
          'is_system_actor', d.is_system_actor
        ),
        'source_type', d.resolved_source_type,
        'old_value', d.sanitized_old_value,
        'new_value', d.sanitized_new_value,
        'reason', d.resolved_reason,
        'source_trace', jsonb_build_object(
          'import_id', d.import_id,
          'import_row_id', d.import_row_id,
          'order_id', d.source_order_id,
          'order_line_id', d.source_order_line_id,
          'memory_request_id', d.source_memory_request_id,
          'sold_at', d.source_sold_at
        ),
        'sensitive_values_hidden', d.sensitive_values_hidden,
        'created_at', d.created_at
      ) as item
    from decorated d
  )
  select
    coalesce(
      jsonb_agg(p.item order by p.created_at desc, p.id desc)
        filter (where p.row_number <= p_limit),
      '[]'::jsonb
    ),
    count(*) > p_limit,
    (
      array_agg(p.id order by p.created_at desc, p.id desc)
        filter (where p.row_number = p_limit)
    )[1],
    (
      array_agg(p.created_at order by p.created_at desc, p.id desc)
        filter (where p.row_number = p_limit)
    )[1]
  into
    v_items,
    v_has_more,
    v_cursor_id,
    v_cursor_created_at
  from projected p;

  if v_has_more then
    v_next_cursor := rtrim(
      translate(
        encode(
          convert_to(
            jsonb_build_object(
              'createdAt', v_cursor_created_at,
              'id', v_cursor_id
            )::text,
            'utf8'
          ),
          'base64'
        ),
        '+/',
        '-_'
      ),
      '='
    );
  end if;

  return jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor,
    'has_more', v_has_more
  );
end;
$$;

revoke all on function pricing.get_customer_price_rule_history(
  uuid, uuid, text, integer
) from public, anon, authenticated, service_role;

grant execute on function pricing.get_customer_price_rule_history(
  uuid, uuid, text, integer
) to authenticated, service_role;
