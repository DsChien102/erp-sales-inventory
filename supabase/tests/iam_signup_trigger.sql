-- Kịch bản kiểm trigger đăng ký cửa hàng. Chạy trong psql local hoặc SQL editor Dev.
-- Kỳ vọng: không raise. Cuối file rollback toàn bộ.
begin;

do $$
declare
  v_user uuid := gen_random_uuid();
  v_other uuid := gen_random_uuid();
  v_tenant_count int;
  v_meta jsonb;
begin
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  )
  values (
    v_user,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'signup-trigger-' || v_user::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'profile', jsonb_build_object('given_name', 'Lan', 'family_name', 'Nguyen', 'phone', '0912345678'),
      'signup_tenant', jsonb_build_object(
        'name', 'Thu y An Phat',
        'contact_phone', '0912345678',
        'contact_email', 'signup-trigger@example.com',
        'province_code', '01',
        'commune_code', '00001',
        'address_text', 'So 1'
      )
    ),
    now(),
    now()
  );

  if exists (
    select 1 from iam.tenants t
    join iam.memberships m on m.tenant_id = t.id
    where m.user_id = v_user
  ) then
    raise exception 'FAIL: tenant created before confirmation';
  end if;
  if exists (select 1 from iam.platform_user_profiles p where p.user_id = v_user) then
    raise exception 'FAIL: profile created before confirmation';
  end if;

  update auth.users set email_confirmed_at = now() where id = v_user;

  select count(*) into v_tenant_count
  from iam.tenants t
  join iam.memberships m on m.tenant_id = t.id
  where m.user_id = v_user and m.is_owner and m.removed_at is null and t.status = 'active' and t.display_name = 'Thu y An Phat';
  if v_tenant_count <> 1 then
    raise exception 'FAIL: expected 1 active tenant, got %', v_tenant_count;
  end if;

  if not exists (
    select 1 from iam.memberships m
    where m.user_id = v_user and m.role = 'store_owner' and m.is_owner and m.removed_at is null
  ) then
    raise exception 'FAIL: missing store_owner membership';
  end if;

  if not exists (
    select 1 from iam.stores s
    join iam.memberships m on m.tenant_id = s.tenant_id
    where m.user_id = v_user and s.code = 'default' and s.status = 'active'
  ) then
    raise exception 'FAIL: missing default store';
  end if;

  if not exists (
    select 1 from iam.user_preferences p
    join iam.memberships m on m.tenant_id = p.last_selected_tenant_id
    where p.user_id = v_user and m.user_id = v_user
  ) then
    raise exception 'FAIL: last selected tenant missing';
  end if;

  if not exists (
    select 1 from iam.audit_logs a
    where a.actor_user_id = v_user and a.event_code = 'iam.tenant.created'
  ) then
    raise exception 'FAIL: missing iam.tenant.created audit';
  end if;

  if not exists (
    select 1 from iam.platform_user_profiles p
    where p.user_id = v_user and p.status = 'active' and p.email_verified
  ) then
    raise exception 'FAIL: profile not active';
  end if;

  select raw_user_meta_data into v_meta from auth.users where id = v_user;
  if v_meta ? 'signup_tenant' then
    raise exception 'FAIL: signup_tenant still in metadata';
  end if;

  update auth.users
  set raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
        'signup_tenant', jsonb_build_object(
          'name', 'Second shop',
          'contact_phone', '0912000000',
          'contact_email', 'second@example.com',
          'province_code', '01',
          'commune_code', '00001',
          'address_text', 'So 2'
        )
      ),
      email_confirmed_at = null
  where id = v_user;
  update auth.users set email_confirmed_at = now() where id = v_user;

  select count(*) into v_tenant_count
  from iam.memberships m
  where m.user_id = v_user and m.is_owner and m.removed_at is null;
  if v_tenant_count <> 1 then
    raise exception 'FAIL: BR-07 created another owner membership, got %', v_tenant_count;
  end if;

  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  )
  values (
    v_other,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'signup-bad-' || v_other::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object(
      'profile', jsonb_build_object('given_name', 'Minh', 'family_name', 'Tran'),
      'signup_tenant', jsonb_build_object(
        'name', 'Missing address',
        'contact_phone', '0912000001',
        'province_code', '01',
        'commune_code', '00001'
      )
    ),
    now(),
    now()
  );

  begin
    update auth.users set email_confirmed_at = now() where id = v_other;
    raise exception 'FAIL: invalid signup_tenant did not raise';
  exception
    when others then
      if sqlerrm like 'FAIL:%' then
        raise;
      end if;
      if position('VALIDATION_ERROR: signup_tenant' in sqlerrm) = 0 then
        raise exception 'FAIL: unexpected error %', sqlerrm;
      end if;
  end;

  if exists (
    select 1 from iam.memberships m where m.user_id = v_other
  ) then
    raise exception 'FAIL: tenant created for invalid payload';
  end if;
end;
$$;

do $$
declare
  v_invited uuid := gen_random_uuid();
begin
  insert into auth.users (
    id, instance_id, aud, role, email, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  )
  values (
    v_invited,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'invited-' || v_invited::text || '@example.com',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('first_name', 'Minh', 'last_name', 'Tran', 'phone', '0900000000'),
    now(),
    now()
  );

  if exists (select 1 from iam.memberships m where m.user_id = v_invited) then
    raise exception 'FAIL: invited user got a tenant';
  end if;
  if not exists (
    select 1 from iam.platform_user_profiles p
    where p.user_id = v_invited and p.status = 'active' and p.given_name = 'Minh'
  ) then
    raise exception 'FAIL: invited user missing profile';
  end if;

  if has_function_privilege('authenticated', 'iam._create_tenant_for_owner(uuid, jsonb)', 'execute') then
    raise exception 'FAIL: authenticated can execute _create_tenant_for_owner';
  end if;
end;
$$;

rollback;
