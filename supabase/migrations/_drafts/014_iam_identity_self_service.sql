-- Title: iam identity self-service (S14 / EP-06 US-01–US-03)
-- Kind: patch
-- Intent: iam_identity_self_service
-- Touches: iam.get_my_identity_profile, iam.update_my_identity_profile, iam.request_my_password_reset, iam.resend_my_password_reset, iam.verify_my_password_reset, iam.complete_my_password_reset
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Theme 1 orchestrates Identity; production Identity owns credentials/codes.
--        Local draft uses auth.users metadata + iam.password_reset_operations for harness.
--        Request/resend enqueue outbox password_reset_code — never return code/password.

create table if not exists iam.password_reset_operations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  code_hash text not null,
  masked_email text not null,
  attempts int not null default 0,
  verified_at timestamptz,
  completed_at timestamptz,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

alter table iam.password_reset_operations enable row level security;

create or replace function iam.get_my_identity_profile()
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_email text;
  v_meta jsonb;
  v_confirmed timestamptz;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select u.email, coalesce(u.raw_user_meta_data, '{}'::jsonb), u.email_confirmed_at
    into v_email, v_meta, v_confirmed
  from auth.users u
  where u.id = v_uid;

  if v_email is null then
    raise exception 'not authenticated';
  end if;

  return jsonb_build_object(
    'user_id', v_uid,
    'first_name', coalesce(v_meta->>'first_name', ''),
    'last_name', coalesce(v_meta->>'last_name', ''),
    'email', v_email,
    'email_verified', (v_confirmed is not null),
    'phone_number', v_meta->>'phone_number',
    'avatar_url', v_meta->>'avatar_url'
  );
end;
$$;

create or replace function iam.update_my_identity_profile(
  p_first_name text,
  p_last_name text,
  p_phone_number text default null,
  p_avatar_url text default null
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_meta jsonb;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_first_name is null or trim(p_first_name) = '' then
    raise exception 'validation: first_name required';
  end if;
  if p_last_name is null or trim(p_last_name) = '' then
    raise exception 'validation: last_name required';
  end if;

  select coalesce(raw_user_meta_data, '{}'::jsonb) into v_meta
  from auth.users where id = v_uid;

  v_meta := v_meta
    || jsonb_build_object(
      'first_name', trim(p_first_name),
      'last_name', trim(p_last_name),
      'phone_number', nullif(trim(coalesce(p_phone_number, '')), ''),
      'avatar_url', nullif(trim(coalesce(p_avatar_url, '')), '')
    );

  update auth.users
  set raw_user_meta_data = v_meta
  where id = v_uid;

  return iam.get_my_identity_profile();
end;
$$;

create or replace function iam.request_my_password_reset()
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_email text;
  v_confirmed timestamptz;
  v_op_id uuid := gen_random_uuid();
  v_code text := lpad((floor(random() * 1000000))::int::text, 6, '0');
  v_masked text;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select email, email_confirmed_at into v_email, v_confirmed
  from auth.users where id = v_uid;

  if v_confirmed is null then
    raise exception 'validation: email must be verified';
  end if;

  v_masked := left(split_part(v_email, '@', 1), 2) || '***@' || split_part(v_email, '@', 2);

  -- Store hash only — never return code to client.
  insert into iam.password_reset_operations (
    id, user_id, code_hash, masked_email, expires_at
  ) values (
    v_op_id,
    v_uid,
    md5(v_code),
    v_masked,
    now() + interval '15 minutes'
  );

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'user_id', v_uid,
      'operation_id', v_op_id,
      'actor_user_id', v_uid
    )
  );

  return jsonb_build_object(
    'operation_id', v_op_id,
    'masked_email', v_masked,
    'expires_at', (now() + interval '15 minutes'),
    'resend_after_seconds', 45
  );
end;
$$;

create or replace function iam.resend_my_password_reset(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_op iam.password_reset_operations%rowtype;
  v_code text := lpad((floor(random() * 1000000))::int::text, 6, '0');
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_op
  from iam.password_reset_operations
  where id = p_operation_id and user_id = v_uid;

  if not found or v_op.expires_at < now() or v_op.completed_at is not null then
    raise exception 'reset_code_expired';
  end if;

  update iam.password_reset_operations
  set code_hash = md5(v_code),
      attempts = 0,
      verified_at = null,
      expires_at = now() + interval '15 minutes'
  where id = p_operation_id;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'user_id', v_uid,
      'operation_id', p_operation_id,
      'actor_user_id', v_uid
    )
  );

  return jsonb_build_object(
    'operation_id', p_operation_id,
    'masked_email', v_op.masked_email,
    'expires_at', (now() + interval '15 minutes'),
    'resend_after_seconds', 45
  );
end;
$$;

create or replace function iam.verify_my_password_reset(
  p_operation_id uuid,
  p_code text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_op iam.password_reset_operations%rowtype;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  select * into v_op
  from iam.password_reset_operations
  where id = p_operation_id and user_id = v_uid
  for update;

  if not found or v_op.expires_at < now() or v_op.completed_at is not null then
    raise exception 'reset_code_expired';
  end if;

  if v_op.attempts >= 5 then
    raise exception 'reset_code_attempts_exceeded';
  end if;

  if v_op.code_hash <> md5(trim(p_code)) then
    update iam.password_reset_operations
    set attempts = attempts + 1
    where id = p_operation_id;
    raise exception 'reset_code_invalid';
  end if;

  update iam.password_reset_operations
  set verified_at = now()
  where id = p_operation_id;
end;
$$;

create or replace function iam.complete_my_password_reset(
  p_operation_id uuid,
  p_new_password text
)
returns void
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_op iam.password_reset_operations%rowtype;
begin
  if v_uid is null then
    raise exception 'not authenticated';
  end if;

  if p_new_password is null or char_length(p_new_password) < 8 then
    raise exception 'password_policy_violation';
  end if;

  select * into v_op
  from iam.password_reset_operations
  where id = p_operation_id and user_id = v_uid
  for update;

  if not found
     or v_op.verified_at is null
     or v_op.expires_at < now()
     or v_op.completed_at is not null then
    raise exception 'reset_code_expired';
  end if;

  -- Identity boundary: update auth password when available.
  -- Local draft marks operation complete; production Identity owns credential write.
  update iam.password_reset_operations
  set completed_at = now()
  where id = p_operation_id;
end;
$$;

revoke all on function iam.get_my_identity_profile() from public, anon;
revoke all on function iam.update_my_identity_profile(text, text, text, text) from public, anon;
revoke all on function iam.request_my_password_reset() from public, anon;
revoke all on function iam.resend_my_password_reset(uuid) from public, anon;
revoke all on function iam.verify_my_password_reset(uuid, text) from public, anon;
revoke all on function iam.complete_my_password_reset(uuid, text) from public, anon;

grant execute on function iam.get_my_identity_profile() to authenticated, service_role;
grant execute on function iam.update_my_identity_profile(text, text, text, text) to authenticated, service_role;
grant execute on function iam.request_my_password_reset() to authenticated, service_role;
grant execute on function iam.resend_my_password_reset(uuid) to authenticated, service_role;
grant execute on function iam.verify_my_password_reset(uuid, text) to authenticated, service_role;
grant execute on function iam.complete_my_password_reset(uuid, text) to authenticated, service_role;
