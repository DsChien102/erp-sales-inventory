-- Title: ai assistant log and daily quota (schema ai)
-- Kind: schema
-- Intent: ai_assistant_log
-- Context: AI-1 Task 2 (trợ lý "Hỏi VET45"); nhật ký câu hỏi + giới hạn 100 câu / cửa hàng / ngày
-- Touches: assistant_logs, _daily_limit, start_question, finish_question
-- Safety: one-shot ; new schema and table, no impact on existing tables
-- Depends on: 20260811014_iam_tenant_membership_lifecycle

create schema if not exists ai;

grant usage on schema ai to authenticated;

create table if not exists ai.assistant_logs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  user_id uuid not null,
  asked_at timestamptz not null default now(),
  business_date date not null,
  question text not null,
  status text not null default 'dang_xu_ly',
  tool_calls jsonb not null default '[]'::jsonb,
  input_tokens int,
  output_tokens int,
  latency_ms int,
  finished_at timestamptz,
  constraint assistant_logs_question_len check (char_length(question) between 1 and 500),
  constraint assistant_logs_status_check check (status in (
    'dang_xu_ly', 'ok', 'tro_chuyen', 'ngoai_pham_vi', 'chua_ho_tro',
    'tu_choi', 'khong_quyen', 'loi', 'het_luot', 'ban'
  ))
);

create index if not exists assistant_logs_tenant_date_idx
  on ai.assistant_logs (tenant_id, business_date);

alter table ai.assistant_logs enable row level security;
revoke all on table ai.assistant_logs from public, anon, authenticated;

create or replace function ai._raise(p_code text, p_message text)
returns void
language plpgsql
as $$
begin
  raise exception using message = jsonb_build_object(
    'code', p_code,
    'message', p_message
  )::text;
end;
$$;

revoke all on function ai._raise(text, text) from public, anon, authenticated;

create or replace function ai._daily_limit()
returns int
language sql
immutable
as $$
  select 100;
$$;

revoke all on function ai._daily_limit() from public, anon, authenticated;

create or replace function ai.start_question(p_tenant_id uuid, p_question text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ai, iam, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_question text := trim(coalesce(p_question, ''));
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_limit int := ai._daily_limit();
  v_count int;
  v_is_owner boolean;
  v_tenant_name text;
  v_log_id uuid;
begin
  if v_user is null or iam.has_permission(p_tenant_id, 'sales.order.view') is not true then
    perform ai._raise('PERMISSION_DENIED', 'Permission denied.');
  end if;

  if v_question = '' or char_length(v_question) > 500 then
    perform ai._raise('CONTEXT_INVALID', 'Câu hỏi phải có từ 1 đến 500 ký tự.');
  end if;

  -- Khoá theo cửa hàng: hai yêu cầu đồng thời không cùng lọt qua giới hạn.
  perform pg_advisory_xact_lock(hashtext('ai.quota:' || p_tenant_id::text));

  select count(*)::int
  into v_count
  from ai.assistant_logs l
  where l.tenant_id = p_tenant_id
    and l.business_date = v_today
    and l.status <> 'ban';

  if v_count >= v_limit then
    perform ai._raise('QUOTA_EXCEEDED', 'Đã dùng hết lượt hỏi hôm nay.');
  end if;

  select coalesce(m.is_owner, false)
  into v_is_owner
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = v_user;

  select t.display_name
  into v_tenant_name
  from iam.tenants t
  where t.id = p_tenant_id;

  insert into ai.assistant_logs (tenant_id, user_id, business_date, question)
  values (p_tenant_id, v_user, v_today, v_question)
  returning id into v_log_id;

  return jsonb_build_object(
    'log_id', v_log_id,
    'remaining', v_limit - (v_count + 1),
    'is_owner', coalesce(v_is_owner, false),
    'tenant_name', coalesce(v_tenant_name, '')
  );
end;
$$;

revoke all on function ai.start_question(uuid, text) from public, anon;
grant execute on function ai.start_question(uuid, text) to authenticated;

create or replace function ai.finish_question(
  p_log_id uuid,
  p_status text,
  p_tool_calls jsonb,
  p_input_tokens int,
  p_output_tokens int,
  p_latency_ms int
)
returns void
language plpgsql
volatile
security definer
set search_path = ai, iam, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_updated int;
begin
  if p_status is null or p_status = 'dang_xu_ly' or p_status not in (
    'ok', 'tro_chuyen', 'ngoai_pham_vi', 'chua_ho_tro',
    'tu_choi', 'khong_quyen', 'loi', 'het_luot', 'ban'
  ) then
    perform ai._raise('CONTEXT_INVALID', 'Trạng thái không hợp lệ.');
  end if;

  update ai.assistant_logs l
  set status = p_status,
      tool_calls = coalesce(p_tool_calls, '[]'::jsonb),
      input_tokens = p_input_tokens,
      output_tokens = p_output_tokens,
      latency_ms = p_latency_ms,
      finished_at = now()
  where l.id = p_log_id
    and l.user_id = v_user
    and l.status = 'dang_xu_ly';

  get diagnostics v_updated = row_count;
  if v_updated = 0 then
    perform ai._raise('NOT_FOUND', 'Không tìm thấy câu hỏi đang xử lý.');
  end if;
end;
$$;

revoke all on function ai.finish_question(uuid, text, jsonb, int, int, int) from public, anon;
grant execute on function ai.finish_question(uuid, text, jsonb, int, int, int) to authenticated;
