-- Title: iam self-service password reset operations (S14 / EP-06 US-03)
-- Kind: patch
-- Intent: iam_password_reset_operations
-- Touches: iam.begin_password_reset_operation, iam.get_password_reset_operation, iam.resend_password_reset_operation, iam.mark_password_reset_operation_verified, iam.mark_password_reset_operation_completed
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Metadata ONLY: operation id, user id, status, timestamps, attempt count.
--        The recovery code (and any hash of it) is NEVER stored here; the raw
--        code lives exclusively inside Supabase Auth.
--
-- CONFLICT: Legacy harness `_superseded/022_iam_identity_self_service.sql`
-- used a different shape (id, code_hash, delivery_code). Do not re-apply that
-- file on the same DB. This draft reshapes an incompatible table before create.

-- Drop legacy / incompatible shape so draft re-apply is idempotent.
do $$
begin
  if to_regclass('iam.password_reset_operations') is null then
    return;
  end if;

  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'iam'
      and table_name = 'password_reset_operations'
      and column_name = 'code_hash'
  ) or not exists (
    select 1
    from information_schema.columns
    where table_schema = 'iam'
      and table_name = 'password_reset_operations'
      and column_name = 'operation_id'
  ) then
    drop table iam.password_reset_operations cascade;
  end if;
end $$;

create table if not exists iam.password_reset_operations (
  operation_id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'completed')),
  attempt_count int not null default 0,
  expires_at timestamptz not null,
  resend_available_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table iam.password_reset_operations enable row level security;

create index if not exists password_reset_operations_user_idx
  on iam.password_reset_operations (user_id, created_at desc);

-- Config-aligned windows: OTP expiry 600s, resend frequency 60s.
create or replace function iam.begin_password_reset_operation()
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_row iam.password_reset_operations;
begin
  if v_user_id is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  insert into iam.password_reset_operations (
    user_id, status, attempt_count, expires_at, resend_available_at
  )
  values (
    v_user_id, 'pending', 0, now() + interval '600 seconds',
    now() + interval '60 seconds'
  )
  returning * into v_row;

  return iam._password_reset_operation_json(v_row);
end;
$$;

create or replace function iam.get_password_reset_operation(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_row iam.password_reset_operations;
begin
  select * into v_row
  from iam.password_reset_operations o
  where o.operation_id = p_operation_id
    and o.user_id = auth.uid();

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  return iam._password_reset_operation_json(v_row);
end;
$$;

create or replace function iam.resend_password_reset_operation(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_row iam.password_reset_operations;
begin
  select * into v_row
  from iam.password_reset_operations o
  where o.operation_id = p_operation_id
    and o.user_id = auth.uid()
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

  update iam.password_reset_operations
  set expires_at = now() + interval '600 seconds',
      resend_available_at = now() + interval '60 seconds',
      attempt_count = attempt_count + 1,
      updated_at = now()
  where operation_id = p_operation_id
  returning * into v_row;

  return iam._password_reset_operation_json(v_row);
end;
$$;

create or replace function iam.mark_password_reset_operation_verified(
  p_operation_id uuid
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  update iam.password_reset_operations
  set status = 'verified', updated_at = now()
  where operation_id = p_operation_id
    and user_id = auth.uid()
    and status <> 'completed';

  if not found then
    raise exception 'STATE_CHANGED';
  end if;
end;
$$;

create or replace function iam.mark_password_reset_operation_completed(
  p_operation_id uuid
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  update iam.password_reset_operations
  set status = 'completed', updated_at = now()
  where operation_id = p_operation_id
    and user_id = auth.uid()
    and status = 'verified';

  if not found then
    raise exception 'STATE_CHANGED';
  end if;
end;
$$;

create or replace function iam._password_reset_operation_json(
  p_row iam.password_reset_operations
)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'operation_id', (p_row).operation_id,
    'user_id', (p_row).user_id,
    'status', (p_row).status,
    'expires_at', (p_row).expires_at,
    'resend_available_at', (p_row).resend_available_at
  );
$$;

revoke all on function iam.begin_password_reset_operation() from public, anon;
revoke all on function iam.get_password_reset_operation(uuid) from public, anon;
revoke all on function iam.resend_password_reset_operation(uuid) from public, anon;
revoke all on function iam.mark_password_reset_operation_verified(uuid) from public, anon;
revoke all on function iam.mark_password_reset_operation_completed(uuid) from public, anon;

grant execute on function iam.begin_password_reset_operation() to authenticated;
grant execute on function iam.get_password_reset_operation(uuid) to authenticated;
grant execute on function iam.resend_password_reset_operation(uuid) to authenticated;
grant execute on function iam.mark_password_reset_operation_verified(uuid) to authenticated;
grant execute on function iam.mark_password_reset_operation_completed(uuid) to authenticated;

revoke all on table iam.password_reset_operations from public, anon, authenticated;
