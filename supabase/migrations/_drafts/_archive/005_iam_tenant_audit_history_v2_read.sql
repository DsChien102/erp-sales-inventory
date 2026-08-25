-- Title: IAM tenant audit history V2 read RPC
-- Kind: patch
-- Intent: iam_tenant_audit_history_v2
-- Touches: iam.search_tenant_audit_logs_v2, iam.get_tenant_audit_log

-- 1. Versioned tenant audit log search RPC
create or replace function iam.search_tenant_audit_logs_v2(
  p_tenant_id uuid,
  p_from timestamptz,
  p_to timestamptz,
  p_query text default null,
  p_result text default null,
  p_event_category text default null,
  p_subject_type text default null,
  p_event_codes text[] default null,
  p_cursor text default null,
  p_page_size integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, public
as $$
declare
  v_limit integer;
  v_cursor_time timestamptz;
  v_cursor_id uuid;
  v_total_count integer := 0;
  v_query text;
  v_items jsonb := '[]'::jsonb;
  v_next_cursor text := null;
  v_last_returned_time timestamptz;
  v_last_returned_id uuid;
  v_row record;
  v_count integer := 0;
  v_actor jsonb;
  v_subject jsonb;
begin
  -- 1. Active membership + tenant.audit.view permission check
  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = auth.uid()
      and m.status = 'active'
  ) or not iam.has_permission(p_tenant_id, 'tenant.audit.view') then
    raise exception 'TENANT_PERMISSION_DENIED';
  end if;

  v_limit := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_query := nullif(trim(p_query), '');

  -- Parse cursor
  if p_cursor is not null and p_cursor <> '' then
    begin
      v_cursor_time := split_part(p_cursor, '|', 1)::timestamptz;
      v_cursor_id := split_part(p_cursor, '|', 2)::uuid;
    exception when others then
      v_cursor_time := null;
      v_cursor_id := null;
    end;
  end if;

  -- 2. Count total matches before cursor slicing
  select count(*)
  into v_total_count
  from iam.audit_logs a
  left join auth.users u on u.id = a.actor_user_id
  left join iam.platform_user_profiles up on up.user_id = u.id
  left join iam.tenants t on (
    a.subject_type in ('tenant', 'organization')
    and a.subject_id = t.id::text
    and t.id = a.tenant_id
  )
  left join iam.tenant_invitations inv on (
    a.subject_type = 'invitation'
    and a.subject_id = inv.id::text
    and inv.tenant_id = a.tenant_id
  )
  left join iam.role_definitions inv_role on inv_role.id = inv.initial_role_id
  left join iam.memberships sm on (
    a.subject_type in ('membership', 'member')
    and a.subject_id = sm.id::text
    and sm.tenant_id = a.tenant_id
  )
  left join auth.users su on (
    (
      a.subject_type in ('user', 'account')
      and a.subject_id = su.id::text
      and exists (
        select 1
        from iam.memberships sum_scope
        where sum_scope.tenant_id = a.tenant_id
          and sum_scope.user_id = su.id
      )
    ) or (
      a.subject_type in ('membership', 'member')
      and sm.user_id = su.id
    )
  )
  left join iam.platform_user_profiles sup on sup.user_id = su.id
  where a.scope = 'tenant'
    and a.tenant_id = p_tenant_id
    and a.occurred_at >= p_from
    and a.occurred_at < p_to
    and (p_result is null or a.result = p_result)
    and (p_event_category is null or a.event_category = p_event_category)
    and (p_subject_type is null or a.subject_type = p_subject_type)
    and (p_event_codes is null or a.event_code = any(p_event_codes))
    and (
      v_query is null or
      (a.search_document is not null and a.search_document ilike '%' || lower(v_query) || '%') or
      a.id::text = v_query or
      a.actor_user_id::text = v_query or
      a.subject_id = v_query or
      a.tracking_id ilike '%' || v_query || '%' or
      a.event_code ilike '%' || v_query || '%' or
      nullif(trim(concat_ws(' ', up.family_middle_name, up.given_name)), '') ilike '%' || v_query || '%' or
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), '') ilike '%' || v_query || '%' or
      t.display_name ilike '%' || v_query || '%' or
      t.code ilike '%' || v_query || '%' or
      inv_role.code ilike '%' || v_query || '%' or
      inv_role.label ilike '%' || v_query || '%' or
      sm.role ilike '%' || v_query || '%' or
      nullif(trim(concat_ws(' ', sup.family_middle_name, sup.given_name)), '') ilike '%' || v_query || '%' or
      nullif(trim(concat_ws(' ', su.raw_user_meta_data->>'last_name', su.raw_user_meta_data->>'first_name')), '') ilike '%' || v_query || '%'
    );

  -- 3. Query page items (fetch limit + 1 to detect next page)
  for v_row in
    select
      a.id as audit_log_id,
      a.event_code,
      a.event_category,
      a.result,
      a.occurred_at,
      a.source,
      a.tracking_id,
      a.actor_user_id,
      a.actor_snapshot,
      a.subject_type,
      a.subject_id,
      a.subject_snapshot,
      nullif(trim(concat_ws(' ', up.family_middle_name, up.given_name)), '') as u_full_name,
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), '') as u_display_name,
      m.role as m_role,
      t.display_name as t_display_name,
      t.code as t_code,
      inv_role.code as inv_role,
      inv.invitee_email as inv_email,
      nullif(trim(concat_ws(' ', sup.family_middle_name, sup.given_name)), '') as su_full_name,
      nullif(trim(concat_ws(' ', su.raw_user_meta_data->>'last_name', su.raw_user_meta_data->>'first_name')), '') as su_display_name,
      sm.role as sm_role
    from iam.audit_logs a
    left join auth.users u on u.id = a.actor_user_id
    left join iam.platform_user_profiles up on up.user_id = u.id
    left join lateral (
      select am.role
      from iam.memberships am
      where am.tenant_id = a.tenant_id
        and am.user_id = a.actor_user_id
        and am.status in ('active', 'inactive')
      order by
        case am.status when 'active' then 0 else 1 end,
        am.updated_at desc,
        am.created_at desc,
        am.id desc
      limit 1
    ) m on true
    left join iam.tenants t on (
      a.subject_type in ('tenant', 'organization')
      and a.subject_id = t.id::text
      and t.id = a.tenant_id
    )
    left join iam.tenant_invitations inv on (
      a.subject_type = 'invitation'
      and a.subject_id = inv.id::text
      and inv.tenant_id = a.tenant_id
    )
    left join iam.role_definitions inv_role on inv_role.id = inv.initial_role_id
    left join iam.memberships sm on (
      a.subject_type in ('membership', 'member')
      and a.subject_id = sm.id::text
      and sm.tenant_id = a.tenant_id
    )
    left join auth.users su on (
      (
        a.subject_type in ('user', 'account')
        and a.subject_id = su.id::text
        and exists (
          select 1
          from iam.memberships sum_scope
          where sum_scope.tenant_id = a.tenant_id
            and sum_scope.user_id = su.id
        )
      ) or (
        a.subject_type in ('membership', 'member')
        and sm.user_id = su.id
      )
    )
    left join iam.platform_user_profiles sup on sup.user_id = su.id
    where a.scope = 'tenant'
      and a.tenant_id = p_tenant_id
      and a.occurred_at >= p_from
      and a.occurred_at < p_to
      and (p_result is null or a.result = p_result)
      and (p_event_category is null or a.event_category = p_event_category)
      and (p_subject_type is null or a.subject_type = p_subject_type)
      and (p_event_codes is null or a.event_code = any(p_event_codes))
      and (
        v_query is null or
        (a.search_document is not null and a.search_document ilike '%' || lower(v_query) || '%') or
        a.id::text = v_query or
        a.actor_user_id::text = v_query or
        a.subject_id = v_query or
        a.tracking_id ilike '%' || v_query || '%' or
        a.event_code ilike '%' || v_query || '%' or
        nullif(trim(concat_ws(' ', up.family_middle_name, up.given_name)), '') ilike '%' || v_query || '%' or
        nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), '') ilike '%' || v_query || '%' or
        t.display_name ilike '%' || v_query || '%' or
        t.code ilike '%' || v_query || '%' or
        inv_role.code ilike '%' || v_query || '%' or
        inv_role.label ilike '%' || v_query || '%' or
        sm.role ilike '%' || v_query || '%' or
        nullif(trim(concat_ws(' ', sup.family_middle_name, sup.given_name)), '') ilike '%' || v_query || '%' or
        nullif(trim(concat_ws(' ', su.raw_user_meta_data->>'last_name', su.raw_user_meta_data->>'first_name')), '') ilike '%' || v_query || '%'
      )
      and (
        v_cursor_time is null or
        (a.occurred_at < v_cursor_time or (a.occurred_at = v_cursor_time and a.id < v_cursor_id))
      )
    order by a.occurred_at desc, a.id desc
    limit v_limit + 1
  loop
    v_count := v_count + 1;
    if v_count > v_limit then
      v_next_cursor := to_char(v_last_returned_time at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') || '|' || v_last_returned_id::text;
      exit;
    end if;

    -- Build Actor JSON
    if v_row.actor_snapshot is not null then
      v_actor := jsonb_build_object(
        'user_id', v_row.actor_user_id,
        'display_name', v_row.actor_snapshot->>'display_name',
        'actor_type', coalesce(v_row.actor_snapshot->>'actor_type', 'user'),
        'role_code', v_row.actor_snapshot->>'role_code',
        'role_label', v_row.actor_snapshot->>'role_label',
        'display_origin', 'snapshot'
      );
    elsif v_row.actor_user_id is null then
      v_actor := jsonb_build_object(
        'user_id', null,
        'display_name', 'Hệ thống',
        'actor_type', 'system',
        'role_code', null,
        'role_label', null,
        'display_origin', 'system'
      );
    elsif v_row.u_full_name is not null or v_row.u_display_name is not null then
      v_actor := jsonb_build_object(
        'user_id', v_row.actor_user_id,
        'display_name', coalesce(v_row.u_full_name, v_row.u_display_name, v_row.actor_user_id::text),
        'actor_type', 'user',
        'role_code', v_row.m_role,
        'role_label', case v_row.m_role
          when 'store_owner' then 'Chủ sở hữu'
          when 'store_manager' then 'Quản lý chi nhánh'
          when 'veterinarian' then 'Bác sĩ thú y'
          when 'care_staff' then 'Nhân viên chăm sóc'
          when 'cashier' then 'Thu ngân'
          else v_row.m_role
        end,
        'display_origin', 'current'
      );
    else
      v_actor := jsonb_build_object(
        'user_id', v_row.actor_user_id,
        'display_name', null,
        'actor_type', 'user',
        'role_code', null,
        'role_label', null,
        'display_origin', 'unavailable'
      );
    end if;

    -- Build Subject JSON
    if v_row.subject_snapshot is not null then
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', v_row.subject_snapshot->>'display_name',
        'code', v_row.subject_snapshot->>'subject_code',
        'secondary_label', v_row.subject_snapshot->>'secondary_label',
        'display_origin', 'snapshot'
      );
    elsif v_row.subject_type in ('tenant', 'organization') and v_row.t_display_name is not null then
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', v_row.t_display_name,
        'code', v_row.t_code,
        'secondary_label', null,
        'display_origin', 'current'
      );
    elsif v_row.subject_type in ('membership', 'member') and v_row.su_full_name is not null then
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', coalesce(v_row.su_full_name, v_row.su_display_name, v_row.subject_id),
        'code', v_row.sm_role,
        'secondary_label', case v_row.sm_role
          when 'store_owner' then 'Chủ sở hữu'
          when 'store_manager' then 'Quản lý chi nhánh'
          when 'veterinarian' then 'Bác sĩ thú y'
          when 'care_staff' then 'Nhân viên chăm sóc'
          when 'cashier' then 'Thu ngân'
          else v_row.sm_role
        end,
        'display_origin', 'current'
      );
    elsif v_row.subject_type = 'invitation' and v_row.inv_email is not null then
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', case
          when v_row.inv_email like '%@%' then
            substr(v_row.inv_email, 1, 2) || '***@' || split_part(v_row.inv_email, '@', 2)
          else '***'
        end,
        'code', v_row.inv_role,
        'secondary_label', null,
        'display_origin', 'current'
      );
    elsif v_row.subject_type in ('user', 'account') and v_row.su_full_name is not null then
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', coalesce(v_row.su_full_name, v_row.su_display_name, v_row.subject_id),
        'code', null,
        'secondary_label', null,
        'display_origin', 'current'
      );
    else
      v_subject := jsonb_build_object(
        'type', v_row.subject_type,
        'id', v_row.subject_id,
        'display_name', null,
        'code', null,
        'secondary_label', null,
        'display_origin', 'unavailable'
      );
    end if;

    v_items := v_items || jsonb_build_array(
      jsonb_build_object(
        'audit_log_id', v_row.audit_log_id,
        'event_code', v_row.event_code,
        'event_category', v_row.event_category,
        'result', v_row.result,
        'occurred_at', to_char(v_row.occurred_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
        'source', v_row.source,
        'tracking_id', v_row.tracking_id,
        'actor', v_actor,
        'subject', v_subject
      )
    );
    v_last_returned_time := v_row.occurred_at;
    v_last_returned_id := v_row.audit_log_id;
  end loop;

  return jsonb_build_object(
    'items', v_items,
    'total_count', v_total_count,
    'next_cursor', v_next_cursor
  );
end;
$$;

revoke all on function iam.search_tenant_audit_logs_v2(uuid, timestamptz, timestamptz, text, text, text, text, text[], text, integer) from public, anon;
grant execute on function iam.search_tenant_audit_logs_v2(uuid, timestamptz, timestamptz, text, text, text, text, text[], text, integer) to authenticated;

-- 2. Detail RPC
create or replace function iam.get_tenant_audit_log(
  p_tenant_id uuid,
  p_audit_log_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, public
as $$
declare
  v_row record;
  v_actor jsonb;
  v_subject jsonb;
  v_before_redacted boolean := false;
  v_after_redacted boolean := false;
begin
  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = auth.uid()
      and m.status = 'active'
  ) or not iam.has_permission(p_tenant_id, 'tenant.audit.view') then
    raise exception 'TENANT_PERMISSION_DENIED';
  end if;

  select
    a.id as audit_log_id,
    a.tenant_id,
    a.event_code,
    a.event_category,
    a.result,
    a.occurred_at,
    a.source,
    a.tracking_id,
    a.actor_user_id,
    a.actor_snapshot,
    a.subject_type,
    a.subject_id,
    a.subject_snapshot,
    a.before_state,
    a.after_state,
    a.redaction_flags,
    nullif(trim(concat_ws(' ', up.family_middle_name, up.given_name)), '') as u_full_name,
    nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), '') as u_display_name,
    m.role as m_role,
    t.display_name as t_display_name,
    t.code as t_code,
    inv_role.code as inv_role,
    inv.invitee_email as inv_email,
    nullif(trim(concat_ws(' ', sup.family_middle_name, sup.given_name)), '') as su_full_name,
    nullif(trim(concat_ws(' ', su.raw_user_meta_data->>'last_name', su.raw_user_meta_data->>'first_name')), '') as su_display_name,
    sm.role as sm_role
  into v_row
  from iam.audit_logs a
  left join auth.users u on u.id = a.actor_user_id
  left join iam.platform_user_profiles up on up.user_id = u.id
  left join lateral (
    select am.role
    from iam.memberships am
    where am.tenant_id = a.tenant_id
      and am.user_id = a.actor_user_id
      and am.status in ('active', 'inactive')
    order by
      case am.status when 'active' then 0 else 1 end,
      am.updated_at desc,
      am.created_at desc,
      am.id desc
    limit 1
  ) m on true
  left join iam.tenants t on (
    a.subject_type in ('tenant', 'organization')
    and a.subject_id = t.id::text
    and t.id = a.tenant_id
  )
  left join iam.tenant_invitations inv on (
    a.subject_type = 'invitation'
    and a.subject_id = inv.id::text
    and inv.tenant_id = a.tenant_id
  )
  left join iam.role_definitions inv_role on inv_role.id = inv.initial_role_id
  left join iam.memberships sm on (
    a.subject_type in ('membership', 'member')
    and a.subject_id = sm.id::text
    and sm.tenant_id = a.tenant_id
  )
  left join auth.users su on (
    (
      a.subject_type in ('user', 'account')
      and a.subject_id = su.id::text
      and exists (
        select 1
        from iam.memberships sum_scope
        where sum_scope.tenant_id = a.tenant_id
          and sum_scope.user_id = su.id
      )
    ) or (
      a.subject_type in ('membership', 'member')
      and sm.user_id = su.id
    )
  )
  left join iam.platform_user_profiles sup on sup.user_id = su.id
  where a.id = p_audit_log_id
    and a.scope = 'tenant'
    and a.tenant_id = p_tenant_id;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  -- Redaction derivation
  v_before_redacted := coalesce(
    'before' = any(v_row.redaction_flags) or exists(
      select 1 from unnest(v_row.redaction_flags) f where f like 'before.%'
    ),
    false
  );

  v_after_redacted := coalesce(
    'after' = any(v_row.redaction_flags) or exists(
      select 1 from unnest(v_row.redaction_flags) f where f like 'after.%'
    ),
    false
  );

  -- Build Actor JSON
  if v_row.actor_snapshot is not null then
    v_actor := jsonb_build_object(
      'user_id', v_row.actor_user_id,
      'display_name', v_row.actor_snapshot->>'display_name',
      'actor_type', coalesce(v_row.actor_snapshot->>'actor_type', 'user'),
      'role_code', v_row.actor_snapshot->>'role_code',
      'role_label', v_row.actor_snapshot->>'role_label',
      'display_origin', 'snapshot'
    );
  elsif v_row.actor_user_id is null then
    v_actor := jsonb_build_object(
      'user_id', null,
      'display_name', 'Hệ thống',
      'actor_type', 'system',
      'role_code', null,
      'role_label', null,
      'display_origin', 'system'
    );
  elsif v_row.u_full_name is not null or v_row.u_display_name is not null then
    v_actor := jsonb_build_object(
      'user_id', v_row.actor_user_id,
      'display_name', coalesce(v_row.u_full_name, v_row.u_display_name, v_row.actor_user_id::text),
      'actor_type', 'user',
      'role_code', v_row.m_role,
      'role_label', case v_row.m_role
        when 'store_owner' then 'Chủ sở hữu'
        when 'store_manager' then 'Quản lý chi nhánh'
        when 'veterinarian' then 'Bác sĩ thú y'
        when 'care_staff' then 'Nhân viên chăm sóc'
        when 'cashier' then 'Thu ngân'
        else v_row.m_role
      end,
      'display_origin', 'current'
    );
  else
    v_actor := jsonb_build_object(
      'user_id', v_row.actor_user_id,
      'display_name', null,
      'actor_type', 'user',
      'role_code', null,
      'role_label', null,
      'display_origin', 'unavailable'
    );
  end if;

  -- Build Subject JSON
  if v_row.subject_snapshot is not null then
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', v_row.subject_snapshot->>'display_name',
      'code', v_row.subject_snapshot->>'subject_code',
      'secondary_label', v_row.subject_snapshot->>'secondary_label',
      'display_origin', 'snapshot'
    );
  elsif v_row.subject_type in ('tenant', 'organization') and v_row.t_display_name is not null then
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', v_row.t_display_name,
      'code', v_row.t_code,
      'secondary_label', null,
      'display_origin', 'current'
    );
  elsif v_row.subject_type in ('membership', 'member') and v_row.su_full_name is not null then
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', coalesce(v_row.su_full_name, v_row.su_display_name, v_row.subject_id),
      'code', v_row.sm_role,
      'secondary_label', case v_row.sm_role
        when 'store_owner' then 'Chủ sở hữu'
        when 'store_manager' then 'Quản lý chi nhánh'
        when 'veterinarian' then 'Bác sĩ thú y'
        when 'care_staff' then 'Nhân viên chăm sóc'
        when 'cashier' then 'Thu ngân'
        else v_row.sm_role
      end,
      'display_origin', 'current'
    );
  elsif v_row.subject_type = 'invitation' and v_row.inv_email is not null then
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', case
        when v_row.inv_email like '%@%' then
          substr(v_row.inv_email, 1, 2) || '***@' || split_part(v_row.inv_email, '@', 2)
        else '***'
      end,
      'code', v_row.inv_role,
      'secondary_label', null,
      'display_origin', 'current'
    );
  elsif v_row.subject_type in ('user', 'account') and v_row.su_full_name is not null then
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', coalesce(v_row.su_full_name, v_row.su_display_name, v_row.subject_id),
      'code', null,
      'secondary_label', null,
      'display_origin', 'current'
    );
  else
    v_subject := jsonb_build_object(
      'type', v_row.subject_type,
      'id', v_row.subject_id,
      'display_name', null,
      'code', null,
      'secondary_label', null,
      'display_origin', 'unavailable'
    );
  end if;

  return jsonb_build_object(
    'audit_log_id', v_row.audit_log_id,
    'tenant_id', v_row.tenant_id,
    'event_code', v_row.event_code,
    'event_category', v_row.event_category,
    'result', v_row.result,
    'occurred_at', to_char(v_row.occurred_at at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
    'source', v_row.source,
    'tracking_id', v_row.tracking_id,
    'actor_unavailable', (v_actor->>'display_origin' = 'unavailable'),
    'before_redacted', v_before_redacted,
    'after_redacted', v_after_redacted,
    'actor', v_actor,
    'subject', v_subject,
    'before_state', v_row.before_state,
    'after_state', v_row.after_state
  );
end;
$$;

grant execute on function iam.get_tenant_audit_log(uuid, uuid) to authenticated;
