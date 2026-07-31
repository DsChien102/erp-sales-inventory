-- Title: iam tenant invitation read (S6 list/detail)
-- Kind: patch
-- Intent: iam_tenant_invitation_read
-- Context: TH-01 §S6 ListInvitationsQuery / GetInvitationQuery
-- Touches: iam.list_tenant_invitations, iam.get_tenant_invitation
-- Safety: read-only ; medium
-- Depends on: iam.tenant_invitations (delivery_correlation_id, last_sent_at),
--             iam.role_definitions, iam.memberships, iam.has_permission,
--             iam.email_delivery_outcomes
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Never returns token or token_hash.
--        Pending rows past expires_at surface as effective status expired.

-- ── list_tenant_invitations ─────────────────────────────────────────────────

create or replace function iam.list_tenant_invitations(
  p_tenant_id uuid,
  p_search text,
  p_status text,
  p_cursor text,
  p_limit integer
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
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
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  if v_limit < 1 or v_limit > 100 then
    raise exception 'VALIDATION_ERROR';
  end if;

  if v_status is not null
     and v_status not in ('pending', 'accepted', 'declined', 'revoked', 'expired') then
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

  with base as (
    select
      i.*,
      case
        when i.status = 'pending' and i.expires_at <= timezone('utc', now())
          then 'expired'
        else i.status
      end as effective_status,
      coalesce(rd.label, '') as role_label,
      coalesce(edo.status, 'unknown') as delivery_status
    from iam.tenant_invitations i
    left join iam.role_definitions rd on rd.id = i.initial_role_id
    left join iam.email_delivery_outcomes edo
      on edo.correlation_id = i.delivery_correlation_id
    where i.tenant_id = p_tenant_id
  ),
  filtered as (
    select *
    from base b
    where (v_status is null or b.effective_status = v_status)
      and (
        v_search = ''
        or lower(b.invitee_email) like '%' || v_search || '%'
      )
      and (
        v_cur_created is null
        or (b.created_at, b.id) < (v_cur_created, v_cur_id)
      )
    order by b.created_at desc, b.id desc
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
            'invitation_id', f.id,
            'invitee_email', f.invitee_email,
            'initial_role_id', f.initial_role_id,
            'initial_role_label', f.role_label,
            'status', f.effective_status,
            'expires_at', f.expires_at,
            'delivery_status', f.delivery_status,
            'delivery_correlation_id',
              coalesce(f.delivery_correlation_id, ''),
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

-- ── get_tenant_invitation ───────────────────────────────────────────────────

create or replace function iam.get_tenant_invitation(
  p_tenant_id uuid,
  p_invitation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_created_by text := '';
  v_delivery_status text := 'unknown';
  v_effective_status text;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  select *
  into v_inv
  from iam.tenant_invitations i
  where i.id = p_invitation_id
    and i.tenant_id = p_tenant_id;

  if not found then
    return null;
  end if;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  select m.user_id::text
  into v_created_by
  from iam.memberships m
  where m.id = v_inv.invited_by_membership_id
  limit 1;

  if v_inv.delivery_correlation_id is not null
     and v_inv.delivery_correlation_id <> '' then
    select o.status
    into v_delivery_status
    from iam.email_delivery_outcomes o
    where o.correlation_id = v_inv.delivery_correlation_id
    limit 1;
    if not found then
      v_delivery_status := 'unknown';
    end if;
  end if;

  v_effective_status := case
    when v_inv.status = 'pending' and v_inv.expires_at <= timezone('utc', now())
      then 'expired'
    else v_inv.status
  end;

  return jsonb_build_object(
    'invitation_id', v_inv.id,
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', v_inv.initial_role_id,
    'initial_role_label', coalesce(v_role.label, ''),
    'status', v_effective_status,
    'expires_at', v_inv.expires_at,
    'delivery_status', coalesce(v_delivery_status, 'unknown'),
    'delivery_correlation_id', coalesce(v_inv.delivery_correlation_id, ''),
    'version', v_inv.version,
    'created_at', v_inv.created_at,
    'created_by', coalesce(v_created_by, ''),
    'last_sent_at', v_inv.last_sent_at,
    'revoked_at', case
      when v_inv.status = 'revoked' then v_inv.status_changed_at
      else null
    end,
    'declined_at', case
      when v_inv.status = 'declined' then v_inv.status_changed_at
      else null
    end
  );
end;
$$;

revoke all on function iam.list_tenant_invitations(uuid, text, text, text, integer)
  from public, anon;
grant execute on function iam.list_tenant_invitations(uuid, text, text, text, integer)
  to authenticated;

revoke all on function iam.get_tenant_invitation(uuid, uuid)
  from public, anon;
grant execute on function iam.get_tenant_invitation(uuid, uuid)
  to authenticated;
