-- Thêm last_activity_at (= auth.users.last_sign_in_at) vào iam.list_tenant_members (10-8h Task 1).

create or replace function iam.list_tenant_members(
  p_tenant_id uuid,
  p_search text default null,
  p_status text default null,
  p_cursor text default null,
  p_limit integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_limit int := coalesce(p_limit, 20);
  v_search text := lower(trim(coalesce(p_search, '')));
  v_status text := nullif(trim(coalesce(p_status, '')), '');
  v_cur_created timestamptz;
  v_cur_id uuid;
  v_cursor_payload jsonb;
  v_items jsonb;
  v_next_cursor text;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.is_active
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  if v_limit < 1 or v_limit > 100 then
    raise exception 'VALIDATION_ERROR';
  end if;

  if v_status is not null and v_status not in ('active', 'inactive', 'removed') then
    raise exception 'VALIDATION_ERROR';
  end if;

  if p_cursor is not null and p_cursor <> '' then
    begin
      v_cursor_payload :=
        convert_from(decode(p_cursor, 'hex'), 'UTF8')::jsonb;
      v_cur_created :=
        (v_cursor_payload ->> 'created_at')::timestamptz;
      v_cur_id :=
        (v_cursor_payload ->> 'id')::uuid;

      if v_cur_created is null or v_cur_id is null then
        raise exception 'VALIDATION_ERROR';
      end if;
    exception
      when others then
        raise exception 'VALIDATION_ERROR';
    end;
  end if;

  with filtered as (
    select
      m.id,
      m.user_id,
      m.role,
      m.is_owner,
      iam._membership_status_code(m.is_active, m.removed_at) as status,
      m.created_at,
      m.version,
      u.last_sign_in_at as last_activity_at,
      coalesce(
        nullif(
          trim(concat_ws(' ', p.family_middle_name, p.given_name)),
          ''
        ),
        ''
      ) as display_name,
      coalesce(u.email::text, '') as email,
      coalesce(rd.id::text, m.role) as role_id,
      coalesce(rd.label, m.role) as role_label
    from iam.memberships m
    left join auth.users u on u.id = m.user_id
    left join iam.platform_user_profiles p on p.user_id = m.user_id
    left join iam.role_definitions rd on rd.code = m.role
    where m.tenant_id = p_tenant_id
      and (v_status is null or iam._membership_status_code(m.is_active, m.removed_at) = v_status)
      and (
        v_search = ''
        or lower(coalesce(u.email::text, ''))
          like '%' || v_search || '%'
        or lower(
          coalesce(
            nullif(
              trim(concat_ws(' ', p.family_middle_name, p.given_name)),
              ''
            ),
            ''
          )
        ) like '%' || v_search || '%'
      )
      and (
        v_cur_created is null
        or (m.created_at, m.id) < (v_cur_created, v_cur_id)
      )
    order by m.created_at desc, m.id desc
    limit v_limit + 1
  ),
  page as (
    select *
    from filtered
    order by created_at desc, id desc
    limit v_limit
  )
  select
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'membership_id', f.id,
            'user_id', f.user_id,
            'display_name', f.display_name,
            'email', f.email,
            'role_id', f.role_id,
            'role_label', f.role_label,
            'is_owner', (f.is_owner is true),
            'status', f.status,
            'joined_at', f.created_at,
            'last_activity_at', f.last_activity_at,
            'version', f.version
          )
          order by f.created_at desc, f.id desc
        )
        from page f
      ),
      '[]'::jsonb
    ),
    case
      when (select count(*) from filtered) > v_limit then (
        select encode(
          convert_to(
            jsonb_build_object(
              'created_at', p.created_at,
              'id', p.id
            )::text,
            'UTF8'
          ),
          'hex'
        )
        from page p
        order by p.created_at asc, p.id asc
        limit 1
      )
      else null
    end
  into v_items, v_next_cursor;

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'next_cursor', v_next_cursor
  );
end;
$$;

revoke all on function iam.list_tenant_members(uuid, text, text, text, integer) from public, anon;
grant execute on function iam.list_tenant_members(uuid, text, text, text, integer) to authenticated;
