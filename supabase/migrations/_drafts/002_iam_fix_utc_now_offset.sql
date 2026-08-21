-- Title: IAM fix utc-now offset (store/compare with now())
-- Kind: patch
-- Intent: iam_fix_utc_now_offset
-- Touches: iam.role_definitions, iam.tenant_invitations, iam.tenant_invitation_operations, iam.owner_activations, iam.tenant_invitation_mutate_operations, iam.tenant_invitation_token_operations, iam.send_activation_invitation, iam.request_platform_password_reset, iam.create_tenant_invitation, iam.list_tenant_invitations, iam.get_tenant_invitation, iam.begin_password_reset_operation, iam.resend_password_reset_operation, iam.inspect_owner_activation, iam.begin_password_reset_operation_by_email, iam.resend_password_reset_operation_by_email, iam.resend_tenant_invitation, iam.revoke_tenant_invitation, iam.inspect_invitation_token, iam.accept_invitation, iam.decline_invitation

-- The old `timezone('utc', ` + `now())` expression returns a naive timestamp.
-- When assigned to / compared against a timestamptz column in a session
-- whose TimeZone is Asia/Ho_Chi_Minh (+07), Postgres interprets the naive
-- value as being in that session zone, shifting the stored/compared instant
-- 7 hours early. `now()` is already timestamptz and carries no such
-- ambiguity — it is the correct replacement everywhere below. No other
-- logic changes.

-- ── table column defaults ────────────────────────────────────────────────────

alter table iam.role_definitions alter column created_at set default now();
alter table iam.role_definitions alter column updated_at set default now();

alter table iam.tenant_invitations alter column status_changed_at set default now();
alter table iam.tenant_invitations alter column created_at set default now();
alter table iam.tenant_invitations alter column updated_at set default now();

alter table iam.tenant_invitation_operations alter column created_at set default now();

alter table iam.owner_activations alter column created_at set default now();

alter table iam.tenant_invitation_mutate_operations alter column created_at set default now();

alter table iam.tenant_invitation_token_operations alter column created_at set default now();

-- ── iam.send_activation_invitation(uuid) ─────────────────────────────────────
-- Latest source: 20260811005_iam_platform_user_lifecycle.sql

create or replace function iam.send_activation_invitation(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_status text;
  v_email text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text;
begin
  if not iam.has_platform_permission('platform.user.activation_invite.send') then
    raise exception 'platform permission denied';
  end if;

  select
    iam._platform_user_effective_status(u.email_confirmed_at),
    u.email::text
  into v_status, v_email
  from auth.users u
  where u.id = p_user_id;

  if v_status is null then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_status <> 'pending_activation' then
    raise exception 'STATE_CHANGED';
  end if;

  if v_email is null or length(trim(v_email)) = 0 then
    raise exception 'VALIDATION_ERROR: activation invitee email missing';
  end if;

  insert into iam.platform_user_profiles (user_id, status)
  values (p_user_id, 'pending_activation')
  on conflict (user_id) do nothing;

  v_masked := left(v_email, 1) || '***' || substring(v_email from position('@' in v_email));

  -- Payload tenant_id is null (platform scope). Outbox partition uses platform messaging uuid.
  perform iam.enqueue_outbox_message(
    v_platform_partition,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', now(),
      'tenant_id', null,
      'template_id', 'activation_invitation',
      'to_email', lower(trim(v_email)),
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object('user_id', p_user_id::text)
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'activation_invitation',
    p_status := 'queued',
    p_tenant_id := null,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  insert into iam.platform_audit_logs (actor_user_id, action, target_user_id)
  values (v_actor, 'platform.user.activation_invite.send', p_user_id);
end;
$$;

revoke all on function iam.send_activation_invitation(uuid) from public, anon;
grant execute on function iam.send_activation_invitation(uuid) to authenticated;

-- ── iam.request_platform_password_reset(uuid) ────────────────────────────────
-- Latest source: 20260811005_iam_platform_user_lifecycle.sql

create or replace function iam.request_platform_password_reset(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_email text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text;
begin
  if not iam.has_platform_permission('platform.user.password_reset.initiate') then
    raise exception 'platform permission denied';
  end if;

  select u.email::text into v_email
  from auth.users u
  where u.id = p_user_id;

  if v_email is null or length(trim(v_email)) = 0 then
    raise exception 'VALIDATION_ERROR: password reset email missing';
  end if;

  v_masked := left(v_email, 1) || '***' || substring(v_email from position('@' in v_email));

  -- Initiate only — never return credentials to Platform Admin.
  -- Payload tenant_id null; outbox partition = platform messaging uuid (not domain tenant).
  perform iam.enqueue_outbox_message(
    v_platform_partition,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', now(),
      'tenant_id', null,
      'template_id', 'password_reset_code',
      'to_email', lower(trim(v_email)),
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object('user_id', p_user_id::text)
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'password_reset_code',
    p_status := 'queued',
    p_tenant_id := null,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  insert into iam.platform_audit_logs (actor_user_id, action, target_user_id)
  values (v_actor, 'platform.user.password_reset.initiate', p_user_id);
end;
$$;

revoke all on function iam.request_platform_password_reset(uuid) from public, anon;
grant execute on function iam.request_platform_password_reset(uuid) to authenticated;

-- ── iam.create_tenant_invitation(uuid, text, uuid, text) ─────────────────────
-- Latest source: 20260811017_iam_tenant_invitation_create.sql

create or replace function iam.create_tenant_invitation(
  p_tenant_id uuid,
  p_invitee_email text,
  p_initial_role_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_email text;
  v_role iam.role_definitions;
  v_actor_membership iam.memberships;
  v_existing_membership iam.memberships;
  v_existing_op iam.tenant_invitation_operations;
  v_payload_hash text;
  v_invitation iam.tenant_invitations;
  v_raw_token text;
  v_token_hash text;
  v_now timestamptz := now();
  v_expires_at timestamptz;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_masked text;
  v_ciphertext text;
  v_result jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  v_email := lower(trim(coalesce(p_invitee_email, '')));
  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_payload_hash := md5(
    p_tenant_id::text || '|' || v_email || '|' || p_initial_role_id::text
  );

  select * into v_existing_op
  from iam.tenant_invitation_operations o
  where o.tenant_id = p_tenant_id
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing_op.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing_op.result;
  end if;

  select * into v_role
  from iam.role_definitions r
  where r.id = p_initial_role_id;

  if not found or v_role.status <> 'active' then
    raise exception 'ROLE_NOT_ASSIGNABLE';
  end if;

  select * into v_actor_membership
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = v_caller
    and m.status = 'active'
  for update;

  if not found then
    raise exception 'PERMISSION_DENIED';
  end if;

  select m.* into v_existing_membership
  from iam.memberships m
  join auth.users u on u.id = m.user_id
  where m.tenant_id = p_tenant_id
    and lower(trim(u.email::text)) = v_email
    and m.status in ('active', 'inactive')
  limit 1;

  if found then
    if v_existing_membership.status = 'active' then
      raise exception 'DUPLICATE_MEMBERSHIP';
    end if;
    if v_existing_membership.status = 'inactive' then
      raise exception 'MEMBERSHIP_INACTIVE';
    end if;
  end if;

  if exists (
    select 1
    from iam.tenant_invitations i
    where i.tenant_id = p_tenant_id
      and i.invitee_email = v_email
      and i.status = 'pending'
  ) then
    raise exception 'INVITATION_PENDING_EXISTS';
  end if;

  -- 8-char Crockford Base32 code (uppercase, no separators). Hash the
  -- canonical form directly; the display layer inserts the dash.
  v_raw_token := iam._generate_invitation_code();
  v_token_hash := iam._invitation_token_hash(v_raw_token);
  v_expires_at := v_now + interval '7 days';

  -- Transient ciphertext stand-in (production: encrypt with key outside DB).
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_token, 'UTF8'), 'base64');
  -- Clear local var after constructing ciphertext materials for outbox.
  -- v_raw_token is only referenced in ciphertext build and must not appear in
  -- refs, audit, or persisted invitation columns.

  insert into iam.tenant_invitations (
    tenant_id,
    invitee_email,
    initial_role_id,
    status,
    token_hash,
    invited_by_membership_id,
    expires_at,
    status_changed_at,
    version,
    created_at,
    updated_at,
    delivery_correlation_id,
    last_sent_at
  )
  values (
    p_tenant_id,
    v_email,
    p_initial_role_id,
    'pending',
    v_token_hash,
    v_actor_membership.id,
    v_expires_at,
    v_now,
    1,
    v_now,
    v_now,
    v_correlation_id,
    v_now
  )
  returning * into v_invitation;

  v_masked := left(v_email, 1) || '***' || substring(v_email from position('@' in v_email));

  perform iam.enqueue_outbox_message(
    p_tenant_id,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', v_now,
      'tenant_id', p_tenant_id,
      'template_id', 'tenant_invitation',
      'to_email', v_email,
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object(
        'invitation_id', v_invitation.id::text,
        'tenant_id', p_tenant_id::text
      ),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'tenant_invitation',
    p_status := 'queued',
    p_tenant_id := p_tenant_id,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  -- Ensure raw token is not retained after outbox enqueue.
  v_raw_token := null;

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.created',
    p_subject_type => 'invitation',
    p_subject_id => v_invitation.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'invitation_id', v_invitation.id,
      'invitee_email_masked', v_masked,
      'initial_role_id', p_initial_role_id,
      'delivery_correlation_id', v_correlation_id
    )
  );

  v_result := jsonb_build_object(
    'invitation_id', v_invitation.id,
    'invitee_email', v_invitation.invitee_email,
    'initial_role_id', v_invitation.initial_role_id,
    'initial_role_label', v_role.label,
    'status', v_invitation.status,
    'expires_at', v_invitation.expires_at,
    'delivery_status', 'queued',
    'delivery_correlation_id', v_correlation_id,
    'version', v_invitation.version,
    'created_at', v_invitation.created_at,
    'created_by', v_caller::text,
    'last_sent_at', v_now,
    'revoked_at', null,
    'declined_at', null
  );

  insert into iam.tenant_invitation_operations (
    tenant_id,
    idempotency_key,
    payload_hash,
    result
  )
  values (
    p_tenant_id,
    p_idempotency_key,
    v_payload_hash,
    v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.create_tenant_invitation(uuid, text, uuid, text)
  from public, anon;
grant execute on function iam.create_tenant_invitation(uuid, text, uuid, text)
  to authenticated;

-- ── iam.list_tenant_invitations(uuid, text, text, text, integer) ─────────────
-- Latest source: 20260811019_iam_tenant_invitation_read.sql

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
        when i.status = 'pending' and i.expires_at <= now()
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

revoke all on function iam.list_tenant_invitations(uuid, text, text, text, integer)
  from public, anon;
grant execute on function iam.list_tenant_invitations(uuid, text, text, text, integer)
  to authenticated;

-- ── iam.get_tenant_invitation(uuid, uuid) ────────────────────────────────────
-- Latest source: 20260811019_iam_tenant_invitation_read.sql

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
    when v_inv.status = 'pending' and v_inv.expires_at <= now()
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

revoke all on function iam.get_tenant_invitation(uuid, uuid)
  from public, anon;
grant execute on function iam.get_tenant_invitation(uuid, uuid)
  to authenticated;

-- ── iam.begin_password_reset_operation() ─────────────────────────────────────
-- Latest source: 20260811021_iam_password_reset_operations.sql

create or replace function iam.begin_password_reset_operation()
returns jsonb
language plpgsql
security definer
set search_path = iam, extensions, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_row iam.password_reset_operations;
  v_code text;
  v_ciphertext text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text;
begin
  if v_user_id is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  select u.email::text into v_email from auth.users u where u.id = v_user_id;
  if v_email is null or length(trim(v_email)) = 0 then
    raise exception 'VALIDATION_ERROR: reset email missing';
  end if;

  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  v_masked := left(v_email, 1) || '***' || substring(v_email from position('@' in v_email));

  insert into iam.password_reset_operations (
    user_id, status, attempt_count, code_hash, expires_at, resend_available_at
  )
  values (
    v_user_id, 'pending', 0,
    extensions.crypt(v_code, extensions.gen_salt('bf')),
    now() + interval '600 seconds',
    now() + interval '60 seconds'
  )
  returning * into v_row;

  v_ciphertext := 'transient:' || encode(convert_to(v_code, 'UTF8'), 'base64');

  perform iam.enqueue_outbox_message(
    v_platform_partition,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', now(),
      'tenant_id', null,
      'template_id', 'password_reset_code',
      'to_email', lower(trim(v_email)),
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object('operation_id', v_row.operation_id::text),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'password_reset_code',
    p_status := 'queued',
    p_tenant_id := null,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  v_code := null;
  v_ciphertext := null;
  return iam._password_reset_operation_json(v_row);
end;
$$;

revoke all on function iam.begin_password_reset_operation() from public, anon;
grant execute on function iam.begin_password_reset_operation() to authenticated;

-- ── iam.resend_password_reset_operation(uuid) ────────────────────────────────
-- Latest source: 20260811021_iam_password_reset_operations.sql

create or replace function iam.resend_password_reset_operation(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, extensions, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_email text;
  v_row iam.password_reset_operations;
  v_code text;
  v_ciphertext text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text;
begin
  select * into v_row
  from iam.password_reset_operations o
  where o.operation_id = p_operation_id
    and o.user_id = v_user_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_row.status = 'completed' then
    raise exception 'STATE_CHANGED';
  end if;

  if now() < v_row.resend_available_at then
    raise exception 'RESET_RATE_LIMITED';
  end if;

  select u.email::text into v_email from auth.users u where u.id = v_user_id;
  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  v_masked := left(v_email, 1) || '***' || substring(v_email from position('@' in v_email));

  update iam.password_reset_operations
  set code_hash = extensions.crypt(v_code, extensions.gen_salt('bf')),
      expires_at = now() + interval '600 seconds',
      resend_available_at = now() + interval '60 seconds',
      attempt_count = 0,
      updated_at = now()
  where operation_id = p_operation_id
  returning * into v_row;

  v_ciphertext := 'transient:' || encode(convert_to(v_code, 'UTF8'), 'base64');

  perform iam.enqueue_outbox_message(
    v_platform_partition,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', now(),
      'tenant_id', null,
      'template_id', 'password_reset_code',
      'to_email', lower(trim(v_email)),
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object('operation_id', v_row.operation_id::text),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'password_reset_code',
    p_status := 'queued',
    p_tenant_id := null,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  v_code := null;
  v_ciphertext := null;
  return iam._password_reset_operation_json(v_row);
end;
$$;

revoke all on function iam.resend_password_reset_operation(uuid) from public, anon;
grant execute on function iam.resend_password_reset_operation(uuid) to authenticated;

-- ── iam.inspect_owner_activation(text) ───────────────────────────────────────
-- Latest source: 20260811023_iam_owner_activation.sql

create or replace function iam.inspect_owner_activation(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_row iam.owner_activations;
  v_hash text;
begin
  if p_code is null or trim(p_code) = '' then
    return jsonb_build_object('valid', false);
  end if;
  v_hash := encode(extensions.digest(upper(trim(p_code)), 'sha256'), 'hex');
  select * into v_row
  from iam.owner_activations
  where code_hash = v_hash
    and status = 'pending'
    and expires_at > now();
  if not found then
    return jsonb_build_object('valid', false);
  end if;
  return jsonb_build_object(
    'valid', true,
    'invitee_email', v_row.invitee_email,
    'tenant_id', v_row.tenant_id,
    'given_name', v_row.given_name,
    'family_name', v_row.family_name,
    'phone', v_row.phone,
    -- Tells the client whether to log in (existing account) or sign up (new).
    'account_exists', exists (
      select 1 from auth.users u where lower(u.email::text) = v_row.invitee_email
    )
  );
end;
$$;

revoke all on function iam.inspect_owner_activation(text) from public;
grant execute on function iam.inspect_owner_activation(text) to anon, authenticated;

-- ── iam.begin_password_reset_operation_by_email(text) ────────────────────────
-- Latest source: 20260811025_iam_password_reset_by_email.sql

create or replace function iam.begin_password_reset_operation_by_email(p_email text)
returns jsonb
language plpgsql
security definer
set search_path = iam, extensions, pg_temp
as $$
declare
  v_email text := lower(trim(coalesce(p_email, '')));
  v_hash text;
  v_user_id uuid;
  v_row iam.password_reset_operations;
  v_code text;
  v_ciphertext text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text;
  v_expires timestamptz := now() + interval '600 seconds';
  v_resend timestamptz := now() + interval '60 seconds';
  v_throttle iam.password_reset_email_throttle;
begin
  if v_email = '' or position('@' in v_email) = 0 then
    raise exception 'VALIDATION_ERROR: email required';
  end if;

  v_hash := encode(extensions.digest(v_email, 'sha256'), 'hex');
  v_masked := iam._mask_reset_email(v_email);

  insert into iam.password_reset_email_throttle (email_hash, last_requested_at, window_count)
  values (v_hash, now(), 1)
  on conflict (email_hash) do update
    set window_count = case
          when iam.password_reset_email_throttle.last_requested_at > now() - interval '60 seconds'
            then iam.password_reset_email_throttle.window_count + 1
          else 1
        end,
        last_requested_at = case
          when iam.password_reset_email_throttle.last_requested_at > now() - interval '60 seconds'
            then iam.password_reset_email_throttle.last_requested_at
          else now()
        end
  returning * into v_throttle;

  if v_throttle.last_requested_at > now() - interval '60 seconds'
     and v_throttle.window_count > 1 then
    return iam._password_reset_public_json(
      gen_random_uuid(), v_masked, v_expires, v_throttle.last_requested_at + interval '60 seconds'
    );
  end if;

  select u.id into v_user_id
  from auth.users u
  where lower(u.email::text) = v_email
  limit 1;

  if v_user_id is null then
    return iam._password_reset_public_json(
      gen_random_uuid(), v_masked, v_expires, v_resend
    );
  end if;

  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  insert into iam.password_reset_operations (
    user_id, status, attempt_count, code_hash, expires_at, resend_available_at
  )
  values (
    v_user_id, 'pending', 0,
    extensions.crypt(v_code, extensions.gen_salt('bf')),
    v_expires,
    v_resend
  )
  returning * into v_row;

  v_ciphertext := 'transient:' || encode(convert_to(v_code, 'UTF8'), 'base64');

  perform iam.enqueue_outbox_message(
    v_platform_partition,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', now(),
      'tenant_id', null,
      'template_id', 'password_reset_code',
      'to_email', v_email,
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object('operation_id', v_row.operation_id::text),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'password_reset_code',
    p_status := 'queued',
    p_tenant_id := null,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  v_code := null;
  v_ciphertext := null;
  return iam._password_reset_public_json(
    v_row.operation_id, v_masked, v_row.expires_at, v_row.resend_available_at
  );
end;
$$;

revoke all on function iam.begin_password_reset_operation_by_email(text) from public;
grant execute on function iam.begin_password_reset_operation_by_email(text) to anon, authenticated;

-- ── iam.resend_password_reset_operation_by_email(uuid) ───────────────────────
-- Latest source: 20260811025_iam_password_reset_by_email.sql

create or replace function iam.resend_password_reset_operation_by_email(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, extensions, pg_temp
as $$
declare
  v_row iam.password_reset_operations;
  v_email text;
  v_code text;
  v_ciphertext text;
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_platform_partition uuid := '00000000-0000-0000-0000-000000000000'::uuid;
  v_masked text := '***';
begin
  select * into v_row
  from iam.password_reset_operations o
  where o.operation_id = p_operation_id
  for update;

  if not found then
    return iam._password_reset_public_json(
      coalesce(p_operation_id, gen_random_uuid()),
      v_masked,
      now() + interval '600 seconds',
      now() + interval '60 seconds'
    );
  end if;

  if v_row.status = 'completed' then
    raise exception 'RESET_CODE_INVALID';
  end if;

  if now() < v_row.resend_available_at then
    raise exception 'RESET_RATE_LIMITED';
  end if;

  select u.email::text into v_email from auth.users u where u.id = v_row.user_id;
  v_masked := iam._mask_reset_email(coalesce(v_email, ''));
  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  update iam.password_reset_operations
  set code_hash = extensions.crypt(v_code, extensions.gen_salt('bf')),
      expires_at = now() + interval '600 seconds',
      resend_available_at = now() + interval '60 seconds',
      attempt_count = 0,
      updated_at = now()
  where operation_id = p_operation_id
  returning * into v_row;

  if v_email is not null then
    v_ciphertext := 'transient:' || encode(convert_to(v_code, 'UTF8'), 'base64');
    perform iam.enqueue_outbox_message(
      v_platform_partition,
      'iam.email.delivery_requested',
      jsonb_build_object(
        'event_version', 1,
        'id', v_message_id,
        'occurred_on', now(),
        'tenant_id', null,
        'template_id', 'password_reset_code',
        'to_email', lower(trim(v_email)),
        'correlation_id', v_correlation_id,
        'outcome_id', v_outcome_id,
        'locale', 'vi',
        'refs', jsonb_build_object('operation_id', v_row.operation_id::text),
        'secret_payload_ciphertext', v_ciphertext
      ),
      v_message_id
    );
    perform iam.record_email_delivery_outcome(
      p_correlation_id := v_correlation_id,
      p_template_id := 'password_reset_code',
      p_status := 'queued',
      p_tenant_id := null,
      p_to_email_masked := v_masked,
      p_id := v_outcome_id
    );
  end if;

  v_code := null;
  v_ciphertext := null;
  return iam._password_reset_public_json(
    v_row.operation_id, v_masked, v_row.expires_at, v_row.resend_available_at
  );
end;
$$;

revoke all on function iam.resend_password_reset_operation_by_email(uuid) from public;
grant execute on function iam.resend_password_reset_operation_by_email(uuid) to anon, authenticated;

-- ── iam.resend_tenant_invitation(uuid, uuid, int, text) ──────────────────────
-- Latest source: 20260811018_iam_tenant_invitation_resend_revoke.sql

create or replace function iam.resend_tenant_invitation(
  p_tenant_id uuid,
  p_invitation_id uuid,
  p_expected_version int,
  p_idempotency_key text
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
  v_existing iam.tenant_invitation_mutate_operations;
  v_payload_hash text;
  v_raw_token text;
  v_token_hash text;
  v_ciphertext text;
  v_now timestamptz := now();
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_masked text;
  v_result jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  v_payload_hash := md5(
    p_tenant_id::text || '|' || p_invitation_id::text || '|' ||
    p_expected_version::text || '|resend'
  );

  select * into v_existing
  from iam.tenant_invitation_mutate_operations o
  where o.tenant_id = p_tenant_id
    and o.invitation_id = p_invitation_id
    and o.operation = 'resend'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  select * into v_inv
  from iam.tenant_invitations i
  where i.id = p_invitation_id
    and i.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_ALREADY_USED';
  end if;

  if v_inv.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  v_raw_token := iam._generate_invitation_code();
  v_token_hash := iam._invitation_token_hash(v_raw_token);
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_token, 'UTF8'), 'base64');

  update iam.tenant_invitations
  set
    token_hash = v_token_hash,
    expires_at = v_now + interval '7 days',
    version = version + 1,
    status_changed_at = v_now,
    updated_at = v_now,
    delivery_correlation_id = v_correlation_id,
    last_sent_at = v_now
  where id = v_inv.id
  returning * into v_inv;

  v_raw_token := null;
  v_masked := left(v_inv.invitee_email, 1) || '***' ||
    substring(v_inv.invitee_email from position('@' in v_inv.invitee_email));

  perform iam.enqueue_outbox_message(
    p_tenant_id,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', v_now,
      'tenant_id', p_tenant_id,
      'template_id', 'tenant_invitation',
      'to_email', v_inv.invitee_email,
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object(
        'invitation_id', v_inv.id::text,
        'tenant_id', p_tenant_id::text
      ),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'tenant_invitation',
    p_status := 'queued',
    p_tenant_id := p_tenant_id,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.resent',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'invitation_id', v_inv.id,
      'version', v_inv.version,
      'delivery_correlation_id', v_correlation_id
    )
  );

  v_result := iam._invitation_detail_json(
    v_inv,
    coalesce(v_role.label, ''),
    v_caller::text,
    null,
    null
  );

  insert into iam.tenant_invitation_mutate_operations (
    tenant_id, invitation_id, operation, idempotency_key, payload_hash, result
  ) values (
    p_tenant_id, p_invitation_id, 'resend', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.resend_tenant_invitation(uuid, uuid, int, text)
  from public, anon;
grant execute on function iam.resend_tenant_invitation(uuid, uuid, int, text)
  to authenticated;

-- ── iam.revoke_tenant_invitation(uuid, uuid, int, text, text) ───────────────
-- Latest source: 20260811018_iam_tenant_invitation_resend_revoke.sql

create or replace function iam.revoke_tenant_invitation(
  p_tenant_id uuid,
  p_invitation_id uuid,
  p_expected_version int,
  p_reason text,
  p_idempotency_key text
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
  v_existing iam.tenant_invitation_mutate_operations;
  v_payload_hash text;
  v_reason text;
  v_now timestamptz := now();
  v_result jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  v_reason := trim(coalesce(p_reason, ''));
  if v_reason = '' or p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  v_payload_hash := md5(
    p_tenant_id::text || '|' || p_invitation_id::text || '|' ||
    p_expected_version::text || '|revoke|' || v_reason
  );

  select * into v_existing
  from iam.tenant_invitation_mutate_operations o
  where o.tenant_id = p_tenant_id
    and o.invitation_id = p_invitation_id
    and o.operation = 'revoke'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  select * into v_inv
  from iam.tenant_invitations i
  where i.id = p_invitation_id
    and i.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_ALREADY_USED';
  end if;

  if v_inv.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  update iam.tenant_invitations
  set
    status = 'revoked',
    revoke_reason = v_reason,
    token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex'),
    version = version + 1,
    status_changed_at = v_now,
    updated_at = v_now
  where id = v_inv.id
  returning * into v_inv;

  -- Intentionally no enqueue_outbox_message on revoke.

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.revoked',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'invitation_id', v_inv.id,
      'version', v_inv.version,
      'revoke_reason', v_reason
    )
  );

  v_result := iam._invitation_detail_json(
    v_inv,
    coalesce(v_role.label, ''),
    v_caller::text,
    v_now,
    null
  );

  insert into iam.tenant_invitation_mutate_operations (
    tenant_id, invitation_id, operation, idempotency_key, payload_hash, result
  ) values (
    p_tenant_id, p_invitation_id, 'revoke', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.revoke_tenant_invitation(uuid, uuid, int, text, text)
  from public, anon;
grant execute on function iam.revoke_tenant_invitation(uuid, uuid, int, text, text)
  to authenticated;

-- ── iam.inspect_invitation_token(text) ───────────────────────────────────────
-- Latest source: 20260820006_iam_invitation_inspection_prefill_profile.sql
-- (supersedes the earlier definition in 20260811020_iam_tenant_invitation_acceptance.sql)

create or replace function iam.inspect_invitation_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_inv iam.tenant_invitations;
  v_owner_activation record;
  v_role iam.role_definitions;
  v_tenant iam.tenants;
  v_account_exists boolean := false;
  v_should_be_owner boolean := false;
  v_hash text;
  v_legacy_hash text;
  v_now timestamptz := now();
begin
  begin
    v_inv := iam._load_invitation_by_token(p_token);
  exception
    when others then
      if sqlerrm like 'INVITATION_TOKEN_INVALID%' then
        v_hash := iam._invitation_token_hash(p_token);
        v_legacy_hash := encode(
          extensions.digest(upper(trim(coalesce(p_token, ''))), 'sha256'),
          'hex'
        );

        select * into v_owner_activation
        from iam.owner_activations oa
        where oa.code_hash in (v_hash, v_legacy_hash)
        limit 1;

        if not found then
          raise exception 'INVITATION_TOKEN_INVALID';
        end if;

        if v_owner_activation.status = 'accepted' then
          raise exception 'INVITATION_ALREADY_USED';
        end if;
        if v_owner_activation.status = 'expired'
            or v_owner_activation.expires_at <= v_now then
          raise exception 'INVITATION_EXPIRED';
        end if;
        if v_owner_activation.status <> 'pending' then
          raise exception 'INVITATION_TOKEN_INVALID';
        end if;

        select * into v_tenant
        from iam.tenants t
        where t.id = v_owner_activation.tenant_id;

        select exists (
          select 1
          from auth.users u
          left join iam.platform_user_profiles p on p.user_id = u.id
          where lower(trim(u.email::text)) = v_owner_activation.invitee_email
            and coalesce(p.status, 'active') <> 'pending_activation'
        ) into v_account_exists;

        return jsonb_build_object(
          'tenant_id', v_owner_activation.tenant_id,
          'tenant_name', coalesce(v_tenant.name, ''),
          'invitee_email', v_owner_activation.invitee_email,
          'initial_role_id', 'owner',
          'initial_role_label', 'Chủ sở hữu',
          'expires_at', v_owner_activation.expires_at,
          'account_exists', v_account_exists,
          'given_name', v_owner_activation.given_name,
          'family_name', v_owner_activation.family_name,
          'phone', v_owner_activation.phone
        );
      end if;
      raise;
  end;

  -- Terminal / expiry checks — still no accountExists on invalid path above.
  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED';
  end if;
  if v_inv.status in ('accepted', 'declined') then
    raise exception 'INVITATION_ALREADY_USED';
  end if;
  if v_inv.status = 'expired' or v_inv.expires_at <= v_now then
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id;
  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  v_should_be_owner := not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.status = 'active'
      and (m.is_owner is true or m.role = 'owner')
  );

  select exists (
    select 1 from auth.users u
    where lower(trim(u.email::text)) = v_inv.invitee_email
  ) into v_account_exists;

  return jsonb_build_object(
    'tenant_id', v_inv.tenant_id,
    'tenant_name', coalesce(v_tenant.name, ''),
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', case when v_should_be_owner then 'owner' else v_inv.initial_role_id::text end,
    'initial_role_label', case when v_should_be_owner then 'Chủ sở hữu' else coalesce(v_role.label, '') end,
    'expires_at', v_inv.expires_at,
    'account_exists', v_account_exists,
    'given_name', null,
    'family_name', null,
    'phone', null
  );
end;
$$;

grant usage on schema iam to anon;
revoke all on function iam.inspect_invitation_token(text) from public;
grant execute on function iam.inspect_invitation_token(text) to anon, authenticated;

-- ── iam.accept_invitation(text, text) ────────────────────────────────────────
-- Latest source: 20260811020_iam_tenant_invitation_acceptance.sql

create or replace function iam.accept_invitation(
  p_token text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_owner_activation record;
  v_tenant iam.tenants;
  v_role iam.role_definitions;
  v_hash text;
  v_legacy_hash text;
  v_email text;
  v_payload_hash text;
  v_existing iam.tenant_invitation_token_operations;
  v_membership iam.memberships;
  v_effective_role text;
  v_should_be_owner boolean := false;
  v_now timestamptz := now();
  v_result jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_hash := iam._invitation_token_hash(p_token);
  v_payload_hash := md5(v_hash || '|accept');

  select * into v_existing
  from iam.tenant_invitation_token_operations o
  where o.token_hash = v_hash
    and o.operation = 'accept'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  begin
    v_inv := iam._load_invitation_by_token(p_token);
  exception
    when others then
      if sqlerrm not like 'INVITATION_TOKEN_INVALID%' then
        raise;
      end if;

      v_legacy_hash := encode(
        extensions.digest(upper(trim(coalesce(p_token, ''))), 'sha256'),
        'hex'
      );

      select * into v_owner_activation
      from iam.owner_activations oa
      where oa.code_hash in (v_hash, v_legacy_hash)
      for update;

      if not found then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;

      select lower(trim(u.email::text)) into v_email
      from auth.users u
      where u.id = v_caller;

      if lower(coalesce(v_email, '')) <> lower(v_owner_activation.invitee_email) then
        update iam.owner_activations
        set attempt_count = attempt_count + 1
        where id = v_owner_activation.id;
        raise exception 'INVITATION_EMAIL_MISMATCH';
      end if;

      if v_owner_activation.status = 'accepted' then
        raise exception 'INVITATION_ALREADY_USED';
      end if;
      if v_owner_activation.status = 'expired'
          or v_owner_activation.expires_at <= v_now then
        update iam.owner_activations
        set status = 'expired'
        where id = v_owner_activation.id;
        raise exception 'INVITATION_EXPIRED';
      end if;
      if v_owner_activation.status <> 'pending' then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;

      select * into v_tenant
      from iam.tenants t
      where t.id = v_owner_activation.tenant_id
      for update;
      if not found then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;
      if coalesce(v_tenant.status, 'active') = 'suspended' then
        raise exception 'TENANT_SUSPENDED';
      end if;

      update iam.memberships
      set role = 'store_owner',
          status = 'active',
          is_owner = true,
          version = version + 1,
          updated_at = v_now
      where tenant_id = v_owner_activation.tenant_id
        and user_id = v_caller
        and status in ('active', 'inactive')
      returning * into v_membership;

      if not found then
        insert into iam.memberships (
          tenant_id,
          user_id,
          role,
          status,
          is_owner,
          version,
          created_at,
          updated_at
        )
        values (
          v_owner_activation.tenant_id,
          v_caller,
          'store_owner',
          'active',
          true,
          1,
          v_now,
          v_now
        )
        returning * into v_membership;
      end if;

      update iam.platform_user_profiles
      set status = 'active',
          email_verified = true,
          email = coalesce(email, v_owner_activation.invitee_email),
          updated_at = v_now
      where user_id = v_caller;

      if not found then
        insert into iam.platform_user_profiles (
          user_id, status, email_verified, email, given_name, family_middle_name,
          phone_number, created_at, updated_at
        )
        values (
          v_caller, 'active', true, v_owner_activation.invitee_email,
          v_owner_activation.given_name,
          v_owner_activation.family_name, v_owner_activation.phone, v_now, v_now
        );
      end if;

      update iam.owner_activations
      set status = 'accepted',
          accepted_at = v_now,
          code_hash = encode(
            extensions.digest(extensions.gen_random_bytes(32), 'sha256'),
            'hex'
          )
      where id = v_owner_activation.id;

      v_result := iam._membership_detail_json(v_membership);

      insert into iam.tenant_invitation_token_operations (
        token_hash, operation, idempotency_key, payload_hash, result
      ) values (
        v_hash, 'accept', p_idempotency_key, v_payload_hash, v_result
      );

      return v_result;
  end;

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id for update;
  if not found then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  -- Suspended tenant: do not consume token.
  if coalesce(v_tenant.status, 'active') = 'suspended' then
    raise exception 'TENANT_SUSPENDED';
  end if;

  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED';
  end if;
  if v_inv.status in ('accepted', 'declined') then
    raise exception 'INVITATION_ALREADY_USED';
  end if;
  if v_inv.status = 'expired' or v_inv.expires_at <= v_now then
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  select lower(trim(u.email::text)) into v_email
  from auth.users u
  where u.id = v_caller;

  if v_email is null or v_email <> v_inv.invitee_email then
    raise exception 'INVITATION_EMAIL_MISMATCH';
  end if;

  if exists (
    select 1 from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'DUPLICATE_MEMBERSHIP';
  end if;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;
  if not found or v_role.status <> 'active' then
    raise exception 'ROLE_NOT_ASSIGNABLE';
  end if;

  v_should_be_owner := not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.status = 'active'
      and (m.is_owner is true or m.role = 'owner')
  );
  -- Ownership is the is_owner flag, not a role: the first active member gets
  -- the operational default role store_owner (is_owner set from v_should_be_owner).
  v_effective_role := case
    when v_should_be_owner then 'store_owner'
    else coalesce(v_role.code, 'staff')
  end;

  insert into iam.memberships (
    tenant_id,
    user_id,
    role,
    status,
    is_owner,
    version,
    created_at,
    updated_at
  )
  values (
    v_inv.tenant_id,
    v_caller,
    v_effective_role,
    'active',
    v_should_be_owner,
    1,
    v_now,
    v_now
  )
  returning * into v_membership;

  update iam.tenant_invitations
  set
    status = 'accepted',
    accepted_membership_id = v_membership.id,
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now,
    -- rotate hash so old token cannot be reused
    token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex')
  where id = v_inv.id
  returning * into v_inv;

  v_result := iam._membership_detail_json(v_membership);

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => v_inv.tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.accepted',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'membership_id', v_membership.id,
      'invitation_id', v_inv.id
    )
  );

  insert into iam.tenant_invitation_token_operations (
    token_hash, operation, idempotency_key, payload_hash, result
  ) values (
    v_hash, 'accept', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.accept_invitation(text, text) from public, anon;
grant execute on function iam.accept_invitation(text, text) to authenticated;

-- ── iam.decline_invitation(text, text) ───────────────────────────────────────
-- Latest source: 20260811020_iam_tenant_invitation_acceptance.sql

create or replace function iam.decline_invitation(
  p_token text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_hash text;
  v_payload_hash text;
  v_existing iam.tenant_invitation_token_operations;
  v_now timestamptz := now();
  v_result jsonb;
  v_delivery_status text;
begin
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_hash := iam._invitation_token_hash(p_token);
  v_payload_hash := md5(v_hash || '|decline');

  select * into v_existing
  from iam.tenant_invitation_token_operations o
  where o.token_hash = v_hash
    and o.operation = 'decline'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  v_inv := iam._load_invitation_by_token(p_token);

  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED';
  end if;
  if v_inv.status in ('accepted', 'declined') then
    raise exception 'INVITATION_ALREADY_USED';
  end if;
  if v_inv.status = 'expired' or v_inv.expires_at <= v_now then
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  update iam.tenant_invitations
  set
    status = 'declined',
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now,
    token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex')
  where id = v_inv.id
  returning * into v_inv;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  select o.status
  into v_delivery_status
  from iam.email_delivery_outcomes o
  where o.correlation_id = coalesce(v_inv.delivery_correlation_id, '')
  limit 1;

  v_result := jsonb_build_object(
    'invitation_id', v_inv.id,
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', v_inv.initial_role_id,
    'initial_role_label', coalesce(v_role.label, ''),
    'status', v_inv.status,
    'expires_at', v_inv.expires_at,
    'delivery_status', coalesce(v_delivery_status, 'unknown'),
    'delivery_correlation_id', coalesce(v_inv.delivery_correlation_id, ''),
    'version', v_inv.version,
    'created_at', v_inv.created_at,
    'created_by', '',
    'last_sent_at', v_inv.last_sent_at,
    'revoked_at', null,
    'declined_at', v_now
  );

  insert into iam.tenant_invitation_token_operations (
    token_hash, operation, idempotency_key, payload_hash, result
  ) values (
    v_hash, 'decline', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.decline_invitation(text, text) from public, anon;
grant execute on function iam.decline_invitation(text, text) to anon, authenticated;
