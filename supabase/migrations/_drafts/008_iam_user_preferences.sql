-- Title: iam user preferences — LastSelectedTenant (S3 / EP-05 US-03)
-- Kind: patch
-- Intent: iam_user_preferences_last_selected
-- Touches: iam.get_last_selected_tenant, iam.set_last_selected_tenant
-- Notes: Draft only — preference is NOT an access grant; always re-validate.

create table if not exists iam.user_preferences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  last_selected_tenant_id uuid references iam.tenants (id) on delete set null,
  updated_at timestamptz not null default now()
);

alter table iam.user_preferences enable row level security;

drop policy if exists user_preferences_self on iam.user_preferences;
create policy user_preferences_self on iam.user_preferences
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function iam.get_last_selected_tenant()
returns uuid
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  select last_selected_tenant_id
  into v_tenant_id
  from iam.user_preferences
  where user_id = v_user_id;

  return v_tenant_id;
end;
$$;

create or replace function iam.set_last_selected_tenant(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not authenticated';
  end if;

  insert into iam.user_preferences (user_id, last_selected_tenant_id, updated_at)
  values (v_user_id, p_tenant_id, now())
  on conflict (user_id) do update
    set last_selected_tenant_id = excluded.last_selected_tenant_id,
        updated_at = now();
end;
$$;

revoke all on function iam.get_last_selected_tenant() from public, anon;
revoke all on function iam.set_last_selected_tenant(uuid) from public, anon;
grant execute on function iam.get_last_selected_tenant() to authenticated;
grant execute on function iam.set_last_selected_tenant(uuid) to authenticated;
