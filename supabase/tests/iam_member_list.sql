-- Test suite for iam.list_tenant_members last_activity_at (10-8h Task 1)
-- Run via: tools/db_check.sh iam_member_list
-- Cases: m1_owner_sees_last_activity, m2_staff_denied, m3_cursor_and_search_unchanged

begin;

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
language sql
as $$
  select set_config('request.jwt.claims', json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  select set_config('request.jwt.claim.sub', p_user::text, true);
$$;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff_signed uuid := gen_random_uuid();
  v_staff_never uuid := gen_random_uuid();
  v_tenant uuid := gen_random_uuid();
  v_sign_in timestamptz := '2026-11-21T10:05:00Z';
  v_res jsonb;
  v_page1 jsonb;
  v_page2 jsonb;
  v_signed_item jsonb;
  v_never_item jsonb;
begin
  insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, last_sign_in_at, created_at, updated_at)
  values
    (v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'owner-ml@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), v_sign_in, now(), now()),
    (v_staff_signed, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'staff-signed@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), v_sign_in, now(), now()),
    (v_staff_never, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'staff-never@example.com', '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), null, now(), now());

  insert into iam.tenants (id, display_name) values (v_tenant, 'Member List Test');

  insert into iam.memberships (tenant_id, user_id, role, is_owner, created_at)
  values
    (v_tenant, v_owner, 'store_owner', true, now() - interval '3 minutes'),
    (v_tenant, v_staff_signed, 'staff', false, now() - interval '2 minutes'),
    (v_tenant, v_staff_never, 'accountant', false, now() - interval '1 minute');

  insert into iam.platform_user_profiles (user_id, family_middle_name, given_name)
  values
    (v_owner, 'Nguyễn Văn', 'An'),
    (v_staff_signed, 'Trần Thị', 'Bình'),
    (v_staff_never, 'Lê Văn', 'Cường')
  -- trg_on_auth_user_confirmed_ins đã tạo sẵn dòng profile cho user đã xác nhận email.
  on conflict (user_id) do update
    set family_middle_name = excluded.family_middle_name,
        given_name = excluded.given_name;

  -- m1_owner_sees_last_activity
  perform pg_temp.as_user(v_owner);
  v_res := iam.list_tenant_members(v_tenant, null, null, null, 20);
  if jsonb_array_length(v_res -> 'items') <> 3 then
    raise exception 'FAIL: m1_owner_sees_last_activity: expected 3 items, got %', jsonb_array_length(v_res -> 'items');
  end if;

  select item into v_signed_item
  from jsonb_array_elements(v_res -> 'items') item
  where item ->> 'user_id' = v_staff_signed::text;

  select item into v_never_item
  from jsonb_array_elements(v_res -> 'items') item
  where item ->> 'user_id' = v_staff_never::text;

  if (v_signed_item ->> 'last_activity_at') is null then
    raise exception 'FAIL: m1_owner_sees_last_activity: signed user last_activity_at should not be null';
  end if;
  if (v_signed_item ->> 'last_activity_at')::timestamptz <> v_sign_in then
    raise exception 'FAIL: m1_owner_sees_last_activity: expected %, got %', v_sign_in, v_signed_item ->> 'last_activity_at';
  end if;
  if (v_never_item ? 'last_activity_at') is not true or (v_never_item ->> 'last_activity_at') is not null then
    raise exception 'FAIL: m1_owner_sees_last_activity: never-signed user last_activity_at should be null, got %', v_never_item;
  end if;

  -- m2_staff_denied
  perform pg_temp.as_user(v_staff_signed);
  perform pg_temp.expect_err(
    format('select iam.list_tenant_members(%L::uuid)', v_tenant),
    'PERMISSION_DENIED',
    'm2_staff_denied'
  );

  -- m3_cursor_and_search_unchanged
  perform pg_temp.as_user(v_owner);
  v_page1 := iam.list_tenant_members(v_tenant, null, null, null, 2);
  if jsonb_array_length(v_page1 -> 'items') <> 2 or (v_page1 ->> 'next_cursor') is null then
    raise exception 'FAIL: m3_cursor_and_search_unchanged: expected 2 items and next_cursor';
  end if;
  v_page2 := iam.list_tenant_members(v_tenant, null, null, v_page1 ->> 'next_cursor', 2);
  if jsonb_array_length(v_page2 -> 'items') <> 1 or (v_page2 ->> 'next_cursor') is not null then
    raise exception 'FAIL: m3_cursor_and_search_unchanged: expected 1 item on page 2 and null next_cursor';
  end if;

  v_res := iam.list_tenant_members(v_tenant, 'Bình', null, null, 20);
  if jsonb_array_length(v_res -> 'items') <> 1 or (v_res -> 'items' -> 0 ->> 'user_id') <> v_staff_signed::text then
    raise exception 'FAIL: m3_cursor_and_search_unchanged: search Bình failed, got %', v_res;
  end if;
end;
$$;

rollback;
