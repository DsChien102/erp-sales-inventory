-- KI-02: mời lại người đã bị loại kích hoạt lại đúng một membership.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/iam_accept_invitation_reinvite.sql

begin;

do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_staff_email text := 'reinvite-' || v_staff::text || '@example.com';
  v_tenant uuid;
  v_membership_id uuid;
  v_count int;
  v_active boolean;
  v_removed timestamptz;
  v_role text;
  v_owner_flag boolean;
  v_same_id uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  values (
    v_owner,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    'owner-' || v_owner::text || '@example.com',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now(),
    now()
  ),
  (
    v_staff,
    '00000000-0000-0000-0000-000000000000'::uuid,
    'authenticated',
    'authenticated',
    v_staff_email,
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now(),
    now()
  );

  v_tenant := iam._create_tenant_for_owner(
    v_owner,
    jsonb_build_object(
      'name', 'Nha thuoc Reinvite',
      'contact_phone', '0900000001',
      'contact_email', 'owner@example.com',
      'province_code', '01',
      'commune_code', '00001',
      'address_text', 'So 1'
    )
  );

  insert into iam.memberships (
    tenant_id, user_id, role, is_owner, version, created_at, updated_at
  )
  values (
    v_tenant, v_staff, 'staff', false, 1, now(), now()
  )
  returning id into v_membership_id;

  update iam.memberships
  set
    is_active = false,
    removed_at = now(),
    version = version + 1,
    status_changed_at = now(),
    updated_at = now()
  where id = v_membership_id;

  insert into iam.tenant_invitations (
    tenant_id,
    invitee_email,
    initial_role_id,
    status,
    token_hash,
    invited_by_membership_id,
    expires_at
  )
  values (
    v_tenant,
    lower(v_staff_email),
    'a0000000-0000-4000-8000-000000000002'::uuid,
    'pending',
    iam._invitation_token_hash('K7P29XQM'),
    (
      select m.id
      from iam.memberships m
      where m.tenant_id = v_tenant and m.user_id = v_owner
    ),
    now() + interval '7 days'
  );

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_staff::text, 'role', 'authenticated')::text,
    true
  );
  perform set_config('request.jwt.claim.sub', v_staff::text, true);

  perform iam.accept_invitation('K7P29XQM', gen_random_uuid()::text);

  select count(*) into v_count
  from iam.memberships m
  where m.tenant_id = v_tenant and m.user_id = v_staff;

  if v_count <> 1 then
    raise exception 'FAIL: expected 1 membership, got %', v_count;
  end if;

  select m.id, m.is_active, m.removed_at, m.role, m.is_owner
  into v_same_id, v_active, v_removed, v_role, v_owner_flag
  from iam.memberships m
  where m.tenant_id = v_tenant and m.user_id = v_staff;

  if v_same_id is distinct from v_membership_id
     or v_active is not true
     or v_removed is not null
     or v_role is distinct from 'warehouse'
     or v_owner_flag is true then
    raise exception
      'FAIL: reactivated row id=% active=% removed=% role=% owner=%',
      v_same_id, v_active, v_removed, v_role, v_owner_flag;
  end if;
end;
$$;

rollback;
