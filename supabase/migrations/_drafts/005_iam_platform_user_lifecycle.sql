-- Title: iam platform user lifecycle (S15 / EP-01 US-02)
-- Kind: patch
-- Intent: iam_platform_user_lifecycle
-- Touches: iam.suspend_platform_user, iam.restore_platform_user, iam.send_activation_invitation, iam.request_platform_password_reset
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Password-reset / activation enqueue outbox only — no credentials returned.
--        Requires iam.enqueue_outbox_message (messaging foundation) and platform_user_profiles.

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
begin
  if not iam.has_platform_permission('platform.user.activation_invite.send') then
    raise exception 'platform permission denied';
  end if;

  select status into v_status
  from iam.platform_user_profiles
  where user_id = p_user_id;

  if v_status is not null and v_status <> 'pending_activation' then
    raise exception 'state changed: user is not pending activation';
  end if;

  insert into iam.platform_user_profiles (user_id, status)
  values (p_user_id, 'pending_activation')
  on conflict (user_id) do nothing;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'activation_invitation',
      'user_id', p_user_id,
      'actor_user_id', v_actor
    )
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
begin
  if not iam.has_platform_permission('platform.user.password_reset.initiate') then
    raise exception 'platform permission denied';
  end if;

  -- Initiate only — never return credentials to Platform Admin.
  -- Sentinel tenant_id for platform-scoped outbox (NOT NULL constraint).
  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'user_id', p_user_id,
      'actor_user_id', v_actor
    )
  );

  insert into iam.platform_audit_logs (actor_user_id, action, target_user_id)
  values (v_actor, 'platform.user.password_reset.initiate', p_user_id);
end;
$$;

revoke all on function iam.suspend_platform_user(uuid, text) from public, anon;
revoke all on function iam.restore_platform_user(uuid) from public, anon;
revoke all on function iam.send_activation_invitation(uuid) from public, anon;
revoke all on function iam.request_platform_password_reset(uuid) from public, anon;

grant execute on function iam.suspend_platform_user(uuid, text) to authenticated;
grant execute on function iam.restore_platform_user(uuid) to authenticated;
grant execute on function iam.send_activation_invitation(uuid) to authenticated;
grant execute on function iam.request_platform_password_reset(uuid) to authenticated;

revoke all on table iam.platform_audit_logs from public, anon, authenticated;
