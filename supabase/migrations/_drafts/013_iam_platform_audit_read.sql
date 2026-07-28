-- Title: iam platform audit read (S16 / EP-02 US-10)
-- Kind: patch
-- Intent: iam_platform_audit_read
-- Touches: iam.search_platform_audit_logs, iam.get_platform_audit_log
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Detail redacts credential-like payload keys.

create table if not exists iam.platform_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid,
  action text not null,
  target_user_id uuid,
  target_tenant_id uuid,
  reason text,
  status text not null default 'success',
  title text,
  correlation_id text,
  source_app text default 'admin',
  before_state text,
  after_state text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table iam.platform_audit_logs enable row level security;

create or replace function iam._platform_audit_redacted_payload(p jsonb)
returns jsonb
language sql
immutable
as $$
  select coalesce(p, '{}'::jsonb)
    - 'password'
    - 'token'
    - 'access_token'
    - 'refresh_token'
    - 'otp'
    - 'code'
    - 'verification_code'
    - 'secret';
$$;

create or replace function iam.search_platform_audit_logs(
  p_query text default null,
  p_status text default null
)
returns table (
  id uuid,
  title text,
  action_code text,
  status text,
  actor_name text,
  actor_role text,
  target_org_name text,
  target_org_code text,
  created_at timestamptz,
  source_app text
)
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.audit.view') then
    raise exception 'platform permission denied';
  end if;

  return query
  select
    a.id,
    coalesce(a.title, a.action)::text as title,
    a.action::text as action_code,
    coalesce(a.status, 'success')::text as status,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, 'Hệ thống')
    )::text as actor_name,
    'Nhân viên vận hành nền tảng'::text as actor_role,
    coalesce(t.name, '')::text as target_org_name,
    coalesce(t.code, left(coalesce(t.id::text, ''), 8))::text as target_org_code,
    a.created_at,
    coalesce(a.source_app, 'admin')::text as source_app
  from iam.platform_audit_logs a
  left join auth.users u on u.id = a.actor_user_id
  left join iam.tenants t on t.id = a.target_tenant_id
  where (p_status is null or coalesce(a.status, 'success') = p_status)
    and (
      p_query is null
      or p_query = ''
      or coalesce(a.title, '') ilike '%' || p_query || '%'
      or a.action ilike '%' || p_query || '%'
      or coalesce(t.name, '') ilike '%' || p_query || '%'
    )
  order by a.created_at desc
  limit 200;
end;
$$;

create or replace function iam.get_platform_audit_log(p_audit_log_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_row record;
begin
  if not iam.has_platform_permission('platform.audit.view') then
    raise exception 'platform permission denied';
  end if;

  select
    a.id,
    coalesce(a.title, a.action) as title,
    a.action,
    coalesce(a.status, 'success') as status,
    a.correlation_id,
    coalesce(a.source_app, 'admin') as source_app,
    coalesce(a.before_state, '') as before_state,
    coalesce(a.after_state, '') as after_state,
    a.created_at,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, 'Hệ thống')
    ) as actor_name,
    'Nhân viên vận hành nền tảng' as actor_role,
    coalesce(t.name, '') as target_org_name,
    coalesce(t.code, left(coalesce(t.id::text, ''), 8)) as target_org_code,
    iam._platform_audit_redacted_payload(a.payload) as payload
  into v_row
  from iam.platform_audit_logs a
  left join auth.users u on u.id = a.actor_user_id
  left join iam.tenants t on t.id = a.target_tenant_id
  where a.id = p_audit_log_id;

  if v_row.id is null then
    raise exception 'audit log not found';
  end if;

  return jsonb_build_object(
    'id', v_row.id,
    'title', v_row.title,
    'action_code', v_row.action,
    'status', v_row.status,
    'status_label', case v_row.status
      when 'blocked' then 'Bị chặn'
      when 'error' then 'Lỗi'
      else 'Thành công'
    end,
    'actor_name', v_row.actor_name,
    'actor_role', v_row.actor_role,
    'target_org_name', v_row.target_org_name,
    'target_org_code', v_row.target_org_code,
    'timestamp', v_row.created_at,
    'source_app', v_row.source_app,
    'correlation_id', coalesce(v_row.correlation_id, ''),
    'before_state', v_row.before_state,
    'after_state', v_row.after_state,
    'payload', v_row.payload
  );
end;
$$;

revoke all on function iam.search_platform_audit_logs(text, text) from public, anon;
grant execute on function iam.search_platform_audit_logs(text, text) to authenticated;

revoke all on function iam.get_platform_audit_log(uuid) from public, anon;
grant execute on function iam.get_platform_audit_log(uuid) to authenticated;
