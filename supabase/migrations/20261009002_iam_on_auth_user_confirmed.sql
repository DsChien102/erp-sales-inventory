-- Title: iam profile and tenant on email confirmation
-- Kind: patch
-- Intent: iam_signup_on_auth_user_confirmed
-- Context: TH-01 BR-06, BR-09, US-01.3 AC-03
-- Touches: iam._on_auth_user_confirmed
-- Safety: idempotent ; medium
-- Depends on: 20261009001_iam_create_tenant_for_owner.sql

create or replace function iam._on_auth_user_confirmed()
returns trigger
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_given text := nullif(trim(coalesce(meta->'profile'->>'given_name', meta->>'first_name', '')), '');
  v_family text := nullif(trim(coalesce(meta->'profile'->>'family_name', meta->>'last_name', '')), '');
  v_phone text := nullif(trim(coalesce(meta->'profile'->>'phone', meta->>'phone', '')), '');
  v_now timestamptz := now();
begin
  if new.email_confirmed_at is null then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.email_confirmed_at is not null then
    return new;
  end if;

  insert into iam.platform_user_profiles (
    user_id, status, email_verified, email, given_name, family_middle_name, phone_number, updated_at
  )
  values (
    new.id,
    'active',
    true,
    lower(new.email::text),
    v_given,
    v_family,
    v_phone,
    v_now
  )
  on conflict (user_id) do update
  set status = case
        when iam.platform_user_profiles.status = 'suspended' then 'suspended'
        else 'active'
      end,
      email_verified = true,
      email = excluded.email,
      given_name = coalesce(iam.platform_user_profiles.given_name, excluded.given_name),
      family_middle_name = coalesce(
        iam.platform_user_profiles.family_middle_name,
        excluded.family_middle_name
      ),
      phone_number = coalesce(iam.platform_user_profiles.phone_number, excluded.phone_number),
      updated_at = v_now;

  if meta ? 'signup_tenant' then
    perform iam._create_tenant_for_owner(new.id, meta->'signup_tenant');
    update auth.users
    set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) - 'signup_tenant'
    where id = new.id;
  end if;

  return new;
end;
$$;

revoke all on function iam._on_auth_user_confirmed() from public, anon, authenticated;

drop trigger if exists trg_on_auth_user_confirmed_ins on auth.users;
create trigger trg_on_auth_user_confirmed_ins
  after insert on auth.users
  for each row
  when (new.email_confirmed_at is not null)
  execute function iam._on_auth_user_confirmed();

drop trigger if exists trg_on_auth_user_confirmed_upd on auth.users;
create trigger trg_on_auth_user_confirmed_upd
  after update of email_confirmed_at on auth.users
  for each row
  when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function iam._on_auth_user_confirmed();
