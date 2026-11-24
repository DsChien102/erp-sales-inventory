-- Test suite for ai.assistant_logs / ai.start_question / ai.finish_question (AI-1 Task 2)
-- Run via: tools/db_check.sh --no-reset ai_assistant_log
-- Cases: a1_start_ok, a2_quota, a2b_ban_not_counted, a3_yesterday_not_counted, a4_non_member,
--        a5_question_too_long, a6_finish_other_user, a7_finish_twice, a8_finish_bad_status, a9_no_direct_access

create or replace function pg_temp.expect_err(p_sql text, p_code text, p_case text)
returns void
language plpgsql
as $$
begin
  execute p_sql;
  raise exception 'FAIL: %: expected % but no error', p_case, p_code;
exception when others then
  if sqlerrm like 'FAIL: %' then
    raise;
  end if;
  if sqlerrm not like '%' || p_code || '%' then
    raise exception 'FAIL: %: expected %, got %', p_case, p_code, sqlerrm;
  end if;
end;
$$;


create or replace function pg_temp.as_user(p_user uuid)
returns void
language plpgsql
as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  perform set_config('request.jwt.claim.sub', p_user::text, true);
end;
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_outsider uuid := gen_random_uuid();
  v_t uuid := gen_random_uuid();
  v_today date := (now() at time zone 'Asia/Ho_Chi_Minh')::date;
  v_res jsonb;
  v_log uuid;
  v_status text;
  v_n int;
  v_done boolean;
begin
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
  select u.id, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
         u.tag || '-ai-' || substr(u.id::text, 1, 8) || '@example.com',
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
  from (values (v_owner, 'owner'), (v_staff, 'staff'), (v_outsider, 'outsider')) as u(id, tag);

  insert into iam.tenants (id, display_name) values (v_t, 'Cửa hàng AI');
  insert into iam.memberships (tenant_id, user_id, role, is_owner)
  values (v_t, v_owner, 'store_owner', true), (v_t, v_staff, 'staff', false);

  -- a1_start_ok --------------------------------------------------------------
  perform pg_temp.as_user(v_owner);
  v_res := ai.start_question(v_t, '  Hôm nay bán được bao nhiêu?  ');
  if (v_res->>'remaining')::int <> 99 then
    raise exception 'FAIL: a1_start_ok remaining expected 99, got %', v_res;
  end if;
  if (v_res->>'is_owner')::boolean is not true or v_res->>'tenant_name' <> 'Cửa hàng AI' then
    raise exception 'FAIL: a1_start_ok owner flag / tenant name: %', v_res;
  end if;
  v_log := (v_res->>'log_id')::uuid;
  select status into v_status from ai.assistant_logs where id = v_log;
  if v_status <> 'dang_xu_ly' then
    raise exception 'FAIL: a1_start_ok status expected dang_xu_ly, got %', v_status;
  end if;
  if (select question from ai.assistant_logs where id = v_log) <> 'Hôm nay bán được bao nhiêu?' then
    raise exception 'FAIL: a1_start_ok question must be trimmed';
  end if;

  perform pg_temp.as_user(v_staff);
  v_res := ai.start_question(v_t, 'Hàng nào sắp hết?');
  if (v_res->>'is_owner')::boolean is not false or (v_res->>'remaining')::int <> 98 then
    raise exception 'FAIL: a1_start_ok staff flag / remaining: %', v_res;
  end if;

  -- a6_finish_other_user: nhân viên không đóng được dòng của chủ
  perform pg_temp.expect_err(
    format('select ai.finish_question(%L, %L, %L::jsonb, 1, 1, 1)', v_log, 'ok', '[]'),
    'NOT_FOUND', 'a6_finish_other_user');

  -- a8_finish_bad_status
  perform pg_temp.as_user(v_owner);
  perform pg_temp.expect_err(
    format('select ai.finish_question(%L, %L, %L::jsonb, 1, 1, 1)', v_log, 'xong', '[]'),
    'CONTEXT_INVALID', 'a8_finish_bad_status');
  perform pg_temp.expect_err(
    format('select ai.finish_question(%L, %L, %L::jsonb, 1, 1, 1)', v_log, 'dang_xu_ly', '[]'),
    'CONTEXT_INVALID', 'a8_finish_bad_status dang_xu_ly');

  -- finish ok + a7_finish_twice
  perform ai.finish_question(v_log, 'ok', '[{"name":"thong_ke_ban_hang","args":{},"ok":true}]'::jsonb, 100, 20, 850);
  select status, jsonb_array_length(tool_calls), finished_at is not null
  into v_status, v_n, v_done
  from ai.assistant_logs where id = v_log;
  if v_status <> 'ok' or v_n <> 1 or v_done is not true then
    raise exception 'FAIL: finish_question did not update row';
  end if;
  perform pg_temp.expect_err(
    format('select ai.finish_question(%L, %L, %L::jsonb, 1, 1, 1)', v_log, 'ok', '[]'),
    'NOT_FOUND', 'a7_finish_twice');

  -- a4_non_member
  perform pg_temp.as_user(v_outsider);
  perform pg_temp.expect_err(
    format('select ai.start_question(%L, %L)', v_t, 'Xin chào'),
    'PERMISSION_DENIED', 'a4_non_member');

  -- a5_question_too_long / empty
  perform pg_temp.as_user(v_owner);
  perform pg_temp.expect_err(
    format('select ai.start_question(%L, %L)', v_t, repeat('a', 501)),
    'CONTEXT_INVALID', 'a5_question_too_long');
  perform pg_temp.expect_err(
    format('select ai.start_question(%L, %L)', v_t, '   '),
    'CONTEXT_INVALID', 'a5_question_empty');
  v_res := ai.start_question(v_t, repeat('a', 500));  -- đúng 500 vẫn được
  if v_res is null then raise exception 'FAIL: a5 500 chars must pass'; end if;

  -- a2_quota: đủ 100 dòng hôm nay (đã có 3 dòng: log, staff, 500 ký tự)
  insert into ai.assistant_logs (tenant_id, user_id, business_date, question, status)
  select v_t, v_owner, v_today, 'q' || g, 'ok' from generate_series(1, 97) g;
  perform pg_temp.expect_err(
    format('select ai.start_question(%L, %L)', v_t, 'Thêm một câu'),
    'QUOTA_EXCEEDED', 'a2_quota');

  -- a2b_ban_not_counted: đổi bớt thành 99 'ok' + 5 'ban' → vẫn hỏi được, remaining = 0
  delete from ai.assistant_logs where tenant_id = v_t;
  insert into ai.assistant_logs (tenant_id, user_id, business_date, question, status)
  select v_t, v_owner, v_today, 'q' || g, 'ok' from generate_series(1, 99) g;
  insert into ai.assistant_logs (tenant_id, user_id, business_date, question, status)
  select v_t, v_owner, v_today, 'b' || g, 'ban' from generate_series(1, 5) g;
  v_res := ai.start_question(v_t, 'Câu thứ 100');
  if (v_res->>'remaining')::int <> 0 then
    raise exception 'FAIL: a2b_ban_not_counted remaining expected 0, got %', v_res;
  end if;
  perform pg_temp.expect_err(
    format('select ai.start_question(%L, %L)', v_t, 'Câu thứ 101'),
    'QUOTA_EXCEEDED', 'a2b_ban_not_counted 101st');

  -- a3_yesterday_not_counted
  delete from ai.assistant_logs where tenant_id = v_t;
  insert into ai.assistant_logs (tenant_id, user_id, business_date, question, status)
  select v_t, v_owner, v_today - 1, 'y' || g, 'ok' from generate_series(1, 100) g;
  v_res := ai.start_question(v_t, 'Hôm nay là ngày mới');
  if (v_res->>'remaining')::int <> 99 then
    raise exception 'FAIL: a3_yesterday_not_counted remaining expected 99, got %', v_res;
  end if;

  -- a9_no_direct_access
  set local role authenticated;
  begin
    perform 1 from ai.assistant_logs limit 1;
    reset role;
    raise exception 'FAIL: a9_no_direct_access authenticated could read ai.assistant_logs';
  exception when insufficient_privilege then
    reset role;
  end;

  raise notice 'ai_assistant_log: OK';
end;
$$;
