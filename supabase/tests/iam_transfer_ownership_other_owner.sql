-- KI-08 / BR-07 / BR-32 (iam.transfer_platform_tenant_ownership, 20260811012): chuyển Owner chặn người nhận đã là Owner nơi khác,
-- hoặc không phải thành viên đang hoạt động của tổ chức.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/iam_transfer_ownership_other_owner.sql

begin;

do $$
declare
  v_admin uuid := gen_random_uuid();
  v_owner_a uuid := gen_random_uuid();
  v_owner_b uuid := gen_random_uuid();
  v_active uuid := gen_random_uuid();
  v_removed uuid := gen_random_uuid();
  v_tenant_a uuid;
  v_tenant_b uuid;
  v_code text;
  v_is_owner boolean;
  v_version int;
  v_owner_count int;
begin
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  select
    u.id,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    u.label || '-' || u.id::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(), now(), now()
  from (
    values
      (v_admin, 'admin'),
      (v_owner_a, 'owner-a'),
      (v_owner_b, 'owner-b'),
      (v_active, 'active'),
      (v_removed, 'removed')
  ) as u(id, label);

  insert into iam.platform_admins (user_id) values (v_admin);

  v_tenant_a := iam._create_tenant_for_owner(
    v_owner_a,
    jsonb_build_object(
      'name', 'Nha thuoc A', 'contact_phone', '0900000001',
      'contact_email', 'a@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 1'
    )
  );
  v_tenant_b := iam._create_tenant_for_owner(
    v_owner_b,
    jsonb_build_object(
      'name', 'Nha thuoc B', 'contact_phone', '0900000002',
      'contact_email', 'b@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 2'
    )
  );

  insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at)
  values
    (v_tenant_a, v_active, 'staff', false, 1, now(), now()),
    (v_tenant_a, v_removed, 'staff', false, 1, now(), now());

  update iam.memberships
  set is_active = false, removed_at = now(), updated_at = now()
  where tenant_id = v_tenant_a and user_id = v_removed;

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_admin::text, 'role', 'authenticated')::text,
    true
  );
  perform set_config('request.jwt.claim.sub', v_admin::text, true);

  select coalesce(version, 1) into v_version from iam.tenants where id = v_tenant_a;

  -- 1) Người nhận đã là Owner tổ chức B (không phải thành viên A) → INVALID trước.
  --    Thêm vào A rồi thử lại để chạm đúng kiểm "Owner nơi khác".
  insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at)
  values (v_tenant_a, v_owner_b, 'staff', false, 1, now(), now());

  begin
    perform iam.transfer_platform_tenant_ownership(v_tenant_a, v_owner_b, v_version, gen_random_uuid()::text);
    raise exception 'FAIL: transfer to an owner of another tenant must be blocked';
  exception when others then
    get stacked diagnostics v_code = message_text;
    if v_code <> 'OWNER_TARGET_ALREADY_OWNER' then
      raise exception 'FAIL: expected OWNER_TARGET_ALREADY_OWNER, got %', v_code;
    end if;
  end;

  select m.is_owner into v_is_owner
  from iam.memberships m where m.tenant_id = v_tenant_a and m.user_id = v_owner_a;
  if v_is_owner is not true then
    raise exception 'FAIL: tenant A must keep its owner after a blocked transfer';
  end if;

  -- 2) Thành viên đã bị loại → OWNER_TARGET_INVALID.
  begin
    perform iam.transfer_platform_tenant_ownership(v_tenant_a, v_removed, v_version, gen_random_uuid()::text);
    raise exception 'FAIL: transfer to a removed member must be blocked';
  exception when others then
    get stacked diagnostics v_code = message_text;
    if v_code <> 'OWNER_TARGET_INVALID' then
      raise exception 'FAIL: expected OWNER_TARGET_INVALID, got %', v_code;
    end if;
  end;

  -- 3) Thành viên đang hoạt động, chưa sở hữu nơi nào → thành công, đúng 1 Owner.
  perform iam.transfer_platform_tenant_ownership(v_tenant_a, v_active, v_version, gen_random_uuid()::text);

  select count(*) into v_owner_count
  from iam.memberships m
  where m.tenant_id = v_tenant_a and m.is_owner and m.removed_at is null;
  if v_owner_count <> 1 then
    raise exception 'FAIL: expected exactly 1 owner in tenant A, got %', v_owner_count;
  end if;

  select m.is_owner into v_is_owner
  from iam.memberships m where m.tenant_id = v_tenant_a and m.user_id = v_active;
  if v_is_owner is not true then
    raise exception 'FAIL: the selected member must be the owner';
  end if;

  -- 4) Người vừa thành Owner A giờ không nhận được B.
  insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at)
  values (v_tenant_b, v_active, 'staff', false, 1, now(), now());
  select coalesce(version, 1) into v_version from iam.tenants where id = v_tenant_b;

  begin
    perform iam.transfer_platform_tenant_ownership(v_tenant_b, v_active, v_version, gen_random_uuid()::text);
    raise exception 'FAIL: second tenant ownership must be blocked';
  exception when others then
    get stacked diagnostics v_code = message_text;
    if v_code <> 'OWNER_TARGET_ALREADY_OWNER' then
      raise exception 'FAIL: expected OWNER_TARGET_ALREADY_OWNER, got %', v_code;
    end if;
  end;
end;
$$;

rollback;
