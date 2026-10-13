-- KI-03 / KI-05 / BR-07 (3-B, 3-E): luồng onboarding cũ đã bị gỡ khỏi DB, FK và index chặn dữ liệu sai,
-- lời mời nhân viên vẫn chạy.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/iam_legacy_cleanup.sql

begin;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_staff_email text := 'cleanup-staff-' || v_staff::text || '@example.com';
  v_ghost uuid := gen_random_uuid();
  v_tenant uuid;
  v_tenant_2 uuid;
  v_count int;
  v_role text;
  v_is_owner boolean;
begin
  -- 1) 11 hàm cũ + 3 hàm owner activation không còn trong schema iam.
  select count(*) into v_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'iam'
    and p.proname in (
      'create_tenant_onboarding',
      'reinvite_provisioning_owner',
      'send_activation_invitation',
      'resend_owner_activation',
      'get_tenant_readiness',
      'activate_tenant',
      'bootstrap_owner',
      'platform_identity_create_pending_user_for_onboarding',
      'resolve_or_create_platform_user_for_onboarding',
      '_unwind_provisioning_owner_membership',
      '_cleanup_pending_profile_on_auth_user',
      'inspect_owner_activation',
      'accept_owner_activation',
      '_platform_user_effective_status'
    );
  if v_count <> 0 then
    raise exception 'FAIL: % legacy functions still exist', v_count;
  end if;

  if exists (
    select 1 from pg_trigger t
    where t.tgname = 'trg_cleanup_pending_profile' and not t.tgisinternal
  ) then
    raise exception 'FAIL: trg_cleanup_pending_profile still exists';
  end if;

  if to_regclass('iam.owner_activations') is not null
     or to_regclass('iam.onboarding_operations') is not null then
    raise exception 'FAIL: legacy onboarding tables still exist';
  end if;

  -- 2) Cột trạng thái tổ chức và enum tài khoản nền tảng không còn.
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'iam'
      and table_name = 'tenants'
      and column_name = 'status'
  ) then
    raise exception 'FAIL: iam.tenants.status still exists';
  end if;

  if exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'iam'
      and t.typname = 'platform_user_status'
  ) then
    raise exception 'FAIL: iam.platform_user_status still exists';
  end if;

  if to_regclass('iam.platform_admins') is not null
     or to_regclass('iam.platform_audit_logs') is not null then
    raise exception 'FAIL: platform admin tables still exist';
  end if;

  -- 3) FK: membership không trỏ được tới user không tồn tại (KI-03 / BR-35).
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values
    (
      v_owner, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      'cleanup-owner-' || v_owner::text || '@example.com',
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    ),
    (
      v_staff, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
      v_staff_email,
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), now()
    );

  v_tenant := iam._create_tenant_for_owner(
    v_owner,
    jsonb_build_object(
      'name', 'Nha thuoc Cleanup', 'contact_phone', '0900000001',
      'contact_email', 'owner@example.com', 'province_code', '01',
      'commune_code', '00001', 'address_text', 'So 1'
    )
  );
  if v_tenant is null then
    raise exception 'FAIL: tenant was not created for the owner';
  end if;

  if not exists (select 1 from iam.tenants t where t.id = v_tenant) then
    raise exception 'FAIL: new tenant was not stored';
  end if;

  begin
    insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at)
    values (v_tenant, v_ghost, 'staff', false, 1, now(), now());
    raise exception 'FAIL: membership for a non-existent user must be rejected';
  exception when foreign_key_violation then
    null;
  end;

  -- 4) Index: một người chỉ là Owner của một tổ chức (BR-07).
  insert into iam.tenants (display_name) values ('Nha thuoc thu hai')
  returning id into v_tenant_2;

  begin
    insert into iam.memberships (tenant_id, user_id, role, is_owner, version, created_at, updated_at)
    values (v_tenant_2, v_owner, 'store_owner', true, 1, now(), now());
    raise exception 'FAIL: second owned tenant must be rejected';
  exception when unique_violation then
    null;
  end;

  -- 5) Lời mời nhân viên vẫn chạy: nhận lời mời tạo đúng một membership, không phải Owner.
  insert into iam.tenant_invitations (
    tenant_id, invitee_email, initial_role_id, status, token_hash,
    invited_by_membership_id, expires_at
  )
  values (
    v_tenant,
    lower(v_staff_email),
    'a0000000-0000-4000-8000-000000000002'::uuid,
    'pending',
    iam._invitation_token_hash('C1EANUP9'),
    (select m.id from iam.memberships m where m.tenant_id = v_tenant and m.user_id = v_owner),
    now() + interval '7 days'
  );

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_staff::text, 'role', 'authenticated')::text,
    true
  );
  perform set_config('request.jwt.claim.sub', v_staff::text, true);

  perform iam.accept_invitation('C1EANUP9', gen_random_uuid()::text);

  select m.role, m.is_owner into v_role, v_is_owner
  from iam.memberships m
  where m.tenant_id = v_tenant and m.user_id = v_staff and m.is_active and m.removed_at is null;

  if v_role is distinct from 'warehouse' or v_is_owner is not false then
    raise exception 'FAIL: staff membership role=% is_owner=%', v_role, v_is_owner;
  end if;
end;
$$;

rollback;
