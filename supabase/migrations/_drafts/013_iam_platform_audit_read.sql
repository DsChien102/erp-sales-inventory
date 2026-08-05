-- Title: iam audit storage + platform audit read (S16 / EP-02 US-10)
-- Kind: patch
-- Intent: iam_platform_audit_read
-- Touches: iam.append_audit_log, iam.record_account_security_event, iam.search_platform_audit_logs, iam.get_platform_audit_log, iam.search_tenant_audit_logs, iam.get_tenant_audit_log
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Canonical immutable audit storage is iam.audit_logs (plan §3.4).
--        S13 tenant audit and S16 platform audit share this one table.

-- ── Canonical immutable audit storage (plan §3.4) ─────────────────────────────
create table if not exists iam.audit_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid,
  scope text not null check (scope in ('tenant', 'platform')),
  actor_user_id uuid,
  actor_snapshot jsonb,
  event_code text not null,
  subject_type text not null,
  subject_id text not null,
  result text not null,
  source text not null,
  tracking_id text not null,
  before_state jsonb,
  after_state jsonb,
  redaction_flags text[] not null default '{}',
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint audit_logs_tenant_scope_chk
    check (scope <> 'tenant' or tenant_id is not null)
);

alter table iam.audit_logs enable row level security;

create index if not exists audit_logs_tenant_occurred_idx
  on iam.audit_logs (tenant_id, occurred_at desc, id desc);
create index if not exists audit_logs_scope_occurred_idx
  on iam.audit_logs (scope, occurred_at desc, id desc);

-- Recursive secret denylist: strip credential-like keys at every nesting level.
create or replace function iam._audit_redact(p jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_key text;
  v_val jsonb;
  v_out jsonb;
  v_elem jsonb;
  v_arr jsonb;
begin
  if p is null then
    return null;
  end if;

  if jsonb_typeof(p) = 'object' then
    v_out := '{}'::jsonb;
    for v_key, v_val in select * from jsonb_each(p) loop
      if lower(v_key) in (
        'password', 'new_password', 'token', 'access_token', 'refresh_token',
        'otp', 'code', 'verification_code', 'recovery_code', 'secret',
        'nonce', 'session', 'session_token', 'token_hash'
      ) then
        v_out := v_out || jsonb_build_object(v_key, '***');
      else
        v_out := v_out || jsonb_build_object(v_key, iam._audit_redact(v_val));
      end if;
    end loop;
    return v_out;
  elsif jsonb_typeof(p) = 'array' then
    v_arr := '[]'::jsonb;
    for v_elem in select * from jsonb_array_elements(p) loop
      v_arr := v_arr || iam._audit_redact(v_elem);
    end loop;
    return v_arr;
  else
    return p;
  end if;
end;
$$;

-- Private append helper: allowlisted fields only, secret denylist applied.
-- Not granted to app roles; only invoked by other IAM security-definer RPCs.
create or replace function iam.append_audit_log(
  p_scope text,
  p_tenant_id uuid,
  p_actor_user_id uuid,
  p_event_code text,
  p_subject_type text,
  p_subject_id text,
  p_result text,
  p_source text,
  p_tracking_id text,
  p_before jsonb default null,
  p_after jsonb default null,
  p_redaction_flags text[] default '{}'
)
returns uuid
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_id uuid;
begin
  insert into iam.audit_logs (
    tenant_id, scope, actor_user_id, actor_snapshot, event_code,
    subject_type, subject_id, result, source, tracking_id,
    before_state, after_state, redaction_flags, occurred_at
  )
  values (
    p_tenant_id, p_scope, p_actor_user_id, null, p_event_code,
    p_subject_type, p_subject_id, p_result, p_source, p_tracking_id,
    iam._audit_redact(p_before), iam._audit_redact(p_after),
    coalesce(p_redaction_flags, '{}'), now()
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- Security-event RPC for successful external Auth operations. Actor from
-- auth.uid(); accepts only event code / tracking id / subject id.
create or replace function iam.record_account_security_event(
  p_event_code text,
  p_tracking_id text,
  p_subject_id text
)
returns uuid
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
begin
  if v_actor is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  return iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => null,
    p_actor_user_id => v_actor,
    p_event_code => p_event_code,
    p_subject_type => 'account',
    p_subject_id => coalesce(p_subject_id, v_actor::text),
    p_result => 'success',
    p_source => 'auth',
    p_tracking_id => p_tracking_id
  );
end;
$$;

revoke all on function iam.append_audit_log(text, uuid, uuid, text, text, text, text, text, text, jsonb, jsonb, text[]) from public, anon, authenticated;
revoke all on function iam.record_account_security_event(text, text, text) from public, anon;
grant execute on function iam.record_account_security_event(text, text, text) to authenticated;

-- Immutable: app roles never write directly; storage is RPC-only.
revoke insert, update, delete on table iam.audit_logs from public, anon, authenticated;

-- Interim platform audit table retained for one rollout (compatibility);
-- S16 read functions converge onto iam.audit_logs in Task 8. No dual-write.
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
    a.event_code as title,
    a.event_code as action,
    a.result as status,
    a.tracking_id as correlation_id,
    a.source as source_app,
    coalesce(a.before_state::text, '') as before_state,
    coalesce(a.after_state::text, '') as after_state,
    a.occurred_at as created_at,
    coalesce(
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      coalesce(u.email::text, 'Hệ thống')
    ) as actor_name,
    'Nhân viên vận hành nền tảng' as actor_role,
    coalesce(t.name, a.subject_type, '') as target_org_name,
    coalesce(t.code, a.subject_id, left(coalesce(t.id::text, ''), 8)) as target_org_code,
    -- Values were already redacted at write time; never un-redact on read.
    coalesce(a.after_state, '{}'::jsonb) as payload
  into v_row
  from iam.audit_logs a
  left join auth.users u on u.id = a.actor_user_id
  left join iam.tenants t on t.id = a.tenant_id
  where a.id = p_audit_log_id
    and a.scope = 'platform';

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

revoke all on function iam.get_platform_audit_log(uuid) from public, anon;
grant execute on function iam.get_platform_audit_log(uuid) to authenticated;

-- ── S13 tenant-scoped audit read (converged onto iam.audit_logs) ──────────────
-- Cursor encodes (occurred_at, id). Page size default 20, max 100.
create or replace function iam.search_tenant_audit_logs(
  p_tenant_id uuid,
  p_from timestamptz,
  p_to timestamptz,
  p_result text default null,
  p_actor_query text default null,
  p_subject_type text default null,
  p_event_code text default null,
  p_cursor text default null,
  p_page_size integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_limit int := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_cur_occurred timestamptz;
  v_cur_id uuid;
  v_items jsonb;
  v_count int;
  v_next text;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  -- Active membership + audit permission required.
  if not exists (
    select 1 from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.audit.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  if p_cursor is not null and p_cursor <> '' then
    v_cur_occurred := split_part(p_cursor, '|', 1)::timestamptz;
    v_cur_id := split_part(p_cursor, '|', 2)::uuid;
  end if;

  with filtered as (
    select a.*
    from iam.audit_logs a
    left join auth.users u on u.id = a.actor_user_id
    where a.scope = 'tenant'
      and a.tenant_id = p_tenant_id
      and a.occurred_at >= p_from
      and a.occurred_at <= p_to
      and (p_result is null or a.result = p_result)
      and (p_subject_type is null or a.subject_type = p_subject_type)
      and (p_event_code is null or a.event_code = p_event_code)
      and (
        p_actor_query is null or p_actor_query = ''
        or a.actor_user_id::text = p_actor_query
        or coalesce(u.email::text, '') ilike '%' || p_actor_query || '%'
      )
      and (
        v_cur_occurred is null
        or (a.occurred_at, a.id) < (v_cur_occurred, v_cur_id)
      )
    order by a.occurred_at desc, a.id desc
    limit v_limit + 1
  )
  select
    jsonb_agg(
      jsonb_build_object(
        'audit_log_id', f.id,
        'event_code', f.event_code,
        'result', f.result,
        'occurred_at', f.occurred_at,
        'source', f.source,
        'tracking_id', f.tracking_id,
        'actor_user_id', f.actor_user_id,
        'actor_unavailable', f.actor_user_id is not null
          and not exists (select 1 from auth.users au where au.id = f.actor_user_id),
        'subject_type', f.subject_type,
        'subject_id', f.subject_id
      )
      order by f.occurred_at desc, f.id desc
    ),
    count(*)
  into v_items, v_count
  from (select * from filtered order by occurred_at desc, id desc limit v_limit) f;

  -- Compute next cursor if there was an extra row beyond the page.
  if v_count = v_limit then
    select f.occurred_at::text || '|' || f.id::text into v_next
    from (select * from filtered order by occurred_at desc, id desc limit v_limit) f
    order by f.occurred_at asc, f.id asc
    limit 1;
  end if;

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'next_cursor', v_next
  );
end;
$$;

create or replace function iam.get_tenant_audit_log(
  p_tenant_id uuid,
  p_audit_log_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_row iam.audit_logs;
  v_actor_unavailable boolean;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not exists (
    select 1 from iam.memberships m
    where m.tenant_id = p_tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'PERMISSION_DENIED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.audit.view') then
    raise exception 'PERMISSION_DENIED';
  end if;

  -- Detail is filtered by BOTH tenant_id and audit_log_id; a cross-tenant id
  -- returns a non-enumerating RESOURCE_NOT_FOUND.
  select * into v_row
  from iam.audit_logs a
  where a.id = p_audit_log_id
    and a.scope = 'tenant'
    and a.tenant_id = p_tenant_id;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  v_actor_unavailable := v_row.actor_user_id is not null
    and not exists (select 1 from auth.users au where au.id = v_row.actor_user_id);

  return jsonb_build_object(
    'audit_log_id', v_row.id,
    'tenant_id', v_row.tenant_id,
    'event_code', v_row.event_code,
    'result', v_row.result,
    'occurred_at', v_row.occurred_at,
    'source', v_row.source,
    'tracking_id', v_row.tracking_id,
    'actor_user_id', v_row.actor_user_id,
    'actor_unavailable', v_actor_unavailable,
    'subject_type', v_row.subject_type,
    'subject_id', v_row.subject_id,
    'before_redacted', array_length(v_row.redaction_flags, 1) is not null,
    'after_redacted', array_length(v_row.redaction_flags, 1) is not null,
    -- Already redacted at write time; returned as-is (never reconstructed).
    'before_state', v_row.before_state,
    'after_state', v_row.after_state
  );
end;
$$;

revoke all on function iam.search_tenant_audit_logs(uuid, timestamptz, timestamptz, text, text, text, text, text, integer) from public, anon;
grant execute on function iam.search_tenant_audit_logs(uuid, timestamptz, timestamptz, text, text, text, text, text, integer) to authenticated;

revoke all on function iam.get_tenant_audit_log(uuid, uuid) from public, anon;
grant execute on function iam.get_tenant_audit_log(uuid, uuid) to authenticated;

-- Task-10 contract patch: rich filters + cursor page for platform audit search
create or replace function iam.search_platform_audit_logs(
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_actor_user_id text default null,
  p_target_type text default null,
  p_target_id text default null,
  p_action text default null,
  p_result text default null,
  p_source text default null,
  p_correlation_id text default null,
  p_cursor text default null,
  p_page_size integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_limit int := least(greatest(coalesce(p_page_size, 20), 1), 100);
  v_cur_occurred timestamptz;
  v_cur_id uuid;
  v_items jsonb;
  v_count int;
  v_next text;
begin
  if not iam.has_platform_permission('platform.audit.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  -- Cursor encodes (occurred_at, id) like the tenant-scoped search.
  if p_cursor is not null and p_cursor <> '' then
    v_cur_occurred := split_part(p_cursor, '|', 1)::timestamptz;
    v_cur_id := split_part(p_cursor, '|', 2)::uuid;
  end if;

  -- Read from the canonical immutable store (platform scope). p_action is a
  -- free-text search term (the FE search box "Tìm tên hoặc mã tổ chức" is wired
  -- to this param), so it matches event_code OR the target org name/code.
  with filtered as (
    select
      a.id,
      a.event_code,
      a.result,
      a.occurred_at,
      a.source,
      coalesce(
        nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
        coalesce(u.email::text, 'Hệ thống')
      ) as actor_name,
      coalesce(t.name, '') as target_org_name,
      coalesce(t.code, left(coalesce(t.id::text, ''), 8)) as target_org_code
    from iam.audit_logs a
    left join auth.users u on u.id = a.actor_user_id
    left join iam.tenants t on t.id = a.tenant_id
    where a.scope = 'platform'
      and (p_from is null or a.occurred_at >= p_from)
      and (p_to is null or a.occurred_at <= p_to)
      and (p_actor_user_id is null or a.actor_user_id::text = p_actor_user_id)
      and (p_target_type is null or a.subject_type = p_target_type)
      and (p_target_id is null or a.subject_id = p_target_id)
      and (p_result is null or a.result = p_result)
      and (p_source is null or a.source = p_source)
      and (p_correlation_id is null or a.tracking_id = p_correlation_id)
      and (
        p_action is null or p_action = ''
        or a.event_code ilike '%' || p_action || '%'
        or coalesce(t.name, '') ilike '%' || p_action || '%'
        or coalesce(t.code, '') ilike '%' || p_action || '%'
      )
      and (
        v_cur_occurred is null
        or (a.occurred_at, a.id) < (v_cur_occurred, v_cur_id)
      )
    order by a.occurred_at desc, a.id desc
    limit v_limit + 1
  )
  select
    jsonb_agg(
      jsonb_build_object(
        'id', f.id,
        'title', f.event_code,
        'action_code', f.event_code,
        'status', f.result,
        'actor_name', f.actor_name,
        'actor_role', 'Nhân viên vận hành nền tảng',
        'target_org_name', f.target_org_name,
        'target_org_code', f.target_org_code,
        'created_at', f.occurred_at,
        'source_app', f.source
      )
      order by f.occurred_at desc, f.id desc
    ),
    count(*)
  into v_items, v_count
  from (select * from filtered order by occurred_at desc, id desc limit v_limit) f;

  -- Extra row beyond the page → emit a next cursor.
  if v_count = v_limit then
    select f.occurred_at::text || '|' || f.id::text into v_next
    from (select * from filtered order by occurred_at desc, id desc limit v_limit) f
    order by f.occurred_at asc, f.id asc
    limit 1;
  end if;

  return jsonb_build_object(
    'items', coalesce(v_items, '[]'::jsonb),
    'next_cursor', v_next
  );
end;
$$;

revoke all on function iam.search_platform_audit_logs(timestamptz, timestamptz, text, text, text, text, text, text, text, text, integer) from public, anon;
grant execute on function iam.search_platform_audit_logs(timestamptz, timestamptz, text, text, text, text, text, text, text, text, integer) to authenticated;
