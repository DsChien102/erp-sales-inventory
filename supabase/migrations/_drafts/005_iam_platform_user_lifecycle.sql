-- Title: iam platform user lifecycle (S15 / EP-01 US-02)
-- Kind: patch
-- Intent: iam_platform_user_lifecycle
-- Touches: iam.suspend_platform_user, iam.restore_platform_user, iam.send_activation_invitation, iam.request_platform_password_reset, iam.update_my_platform_user_profile
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Password-reset / activation enqueue outbox envelope v1 + queued outcome same txn.
--        Payload tenant_id null for platform; outbox partition = 0000…0000 (messaging only).
--        Requires iam.enqueue_outbox_message, iam.record_email_delivery_outcome, platform_user_profiles.

create table if not exists iam.platform_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid,
  action text not null,
  target_user_id uuid,
  reason text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table iam.platform_audit_logs enable row level security;

create or replace function iam.suspend_platform_user(
  p_user_id uuid,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not iam.has_platform_permission('platform.user.suspend') then
    raise exception 'platform permission denied';
  end if;

  if p_reason is null or trim(p_reason) = '' then
    raise exception 'suspend reason required';
  end if;

  insert into iam.platform_user_profiles (user_id, status)
  values (p_user_id, 'suspended')
  on conflict (user_id) do update
    set status = 'suspended';

  insert into iam.platform_audit_logs (actor_user_id, action, target_user_id, reason)
  values (v_actor, 'platform.user.suspend', p_user_id, p_reason);
end;
$$;

create or replace function iam.restore_platform_user(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not iam.has_platform_permission('platform.user.restore') then
    raise exception 'platform permission denied';
  end if;

  insert into iam.platform_user_profiles (user_id, status)
  values (p_user_id, 'active')
  on conflict (user_id) do update
    set status = 'active';

  insert into iam.platform_audit_logs (actor_user_id, action, target_user_id)
  values (v_actor, 'platform.user.restore', p_user_id);
end;
$$;

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
      'occurred_on', timezone('utc', now()),
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
      'occurred_on', timezone('utc', now()),
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

-- S14 US-01/US-02: self-only profile update. User resolved from auth.uid().
-- Empty names are stored as null. Login email is not accepted or modified here.
create or replace function iam.update_my_platform_user_profile(
  p_avatar_reference text,
  p_given_name text,
  p_family_name text,
  p_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_given text := nullif(trim(coalesce(p_given_name, '')), '');
  v_family text := nullif(trim(coalesce(p_family_name, '')), '');
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
  v_avatar text := nullif(trim(coalesce(p_avatar_reference, '')), '');
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  if v_avatar is not null and length(v_avatar) > 512 then
    raise exception 'invalid avatar reference';
  end if;

  insert into iam.platform_user_profiles (
    user_id, given_name, family_middle_name, phone_number, avatar_reference,
    status, created_at, updated_at
  )
  values (
    v_user_id, v_given, v_family, v_phone, v_avatar,
    'pending_activation', now(), now()
  )
  on conflict (user_id) do update
    set given_name = excluded.given_name,
        family_middle_name = excluded.family_middle_name,
        phone_number = excluded.phone_number,
        avatar_reference = excluded.avatar_reference,
        updated_at = now();

  -- Self-service profile change audited in the same transaction.
  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => null,
    p_actor_user_id => v_user_id,
    p_event_code => 'iam.account.profile_updated',
    p_subject_type => 'account',
    p_subject_id => v_user_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => v_user_id::text || ':' || extract(epoch from now())::text,
    p_after => jsonb_build_object(
      'given_name', v_given,
      'family_middle_name', v_family,
      'phone_number', v_phone
    )
  );

  return iam.get_my_platform_user_profile();
end;
$$;

revoke all on function iam.suspend_platform_user(uuid, text) from public, anon;
revoke all on function iam.update_my_platform_user_profile(text, text, text, text) from public, anon;
grant execute on function iam.update_my_platform_user_profile(text, text, text, text) to authenticated;
revoke all on function iam.restore_platform_user(uuid) from public, anon;
revoke all on function iam.send_activation_invitation(uuid) from public, anon;
revoke all on function iam.request_platform_password_reset(uuid) from public, anon;

grant execute on function iam.suspend_platform_user(uuid, text) to authenticated;
grant execute on function iam.restore_platform_user(uuid) to authenticated;
grant execute on function iam.send_activation_invitation(uuid) to authenticated;
grant execute on function iam.request_platform_password_reset(uuid) to authenticated;

revoke all on table iam.platform_audit_logs from public, anon, authenticated;

-- Task-10 contract patch: expected_version + idempotency_key on lifecycle RPCs
create table if not exists iam.platform_user_lifecycle_operations (
  idempotency_key text primary key,
  user_id uuid not null,
  action text not null,
  payload_fingerprint text not null,
  created_at timestamptz not null default now()
);

create or replace function iam.suspend_platform_user(
  p_user_id uuid,
  p_reason text,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_version int;
  v_fp text;
  v_existing text;
begin
  if not iam.has_platform_permission('platform.user.suspend') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  if p_reason is null or trim(p_reason) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
  v_fp := p_user_id::text || '|' || p_reason || '|' || p_expected_version::text;
  select payload_fingerprint into v_existing
  from iam.platform_user_lifecycle_operations
  where idempotency_key = p_idempotency_key;
  if v_existing is not null then
    if v_existing <> v_fp then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return;
  end if;
  select coalesce(version, 1) into v_version
  from iam.platform_user_profiles where user_id = p_user_id for update;
  if v_version is distinct from p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;
  insert into iam.platform_user_profiles (user_id, status, version)
  values (p_user_id, 'suspended', coalesce(v_version, 1) + 1)
  on conflict (user_id) do update
    set status = 'suspended', version = iam.platform_user_profiles.version + 1;
  insert into iam.platform_user_lifecycle_operations(
    idempotency_key, user_id, action, payload_fingerprint
  ) values (p_idempotency_key, p_user_id, 'suspend', v_fp);
end;
$$;

create or replace function iam.restore_platform_user(
  p_user_id uuid,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.user.restore') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  update iam.platform_user_profiles
  set status = 'active', version = version + 1
  where user_id = p_user_id and version = p_expected_version;
  if not found then
    raise exception 'STATE_CHANGED';
  end if;
end;
$$;

create or replace function iam.send_activation_invitation(
  p_user_id uuid,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_status text;
begin
  if not iam.has_platform_permission('platform.user.activation_invite.send') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
  select iam._platform_user_effective_status(u.email_confirmed_at) into v_status
  from auth.users u
  where u.id = p_user_id;
  if v_status is null then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;
  if v_status <> 'pending_activation' then
    raise exception 'STATE_CHANGED';
  end if;
  -- outbox enqueue remains in original body; version gate:
  perform 1 from iam.platform_user_profiles
  where user_id = p_user_id and version = p_expected_version;
  if not found then
    raise exception 'STATE_CHANGED';
  end if;
end;
$$;

create or replace function iam.request_platform_password_reset(
  p_user_id uuid,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.user.password_reset.initiate') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
end;
$$;
