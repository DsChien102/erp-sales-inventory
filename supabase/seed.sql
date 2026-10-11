-- Vet45 dev seed — IAM baseline role permissions (temporary until SRS).
-- Owner role bypasses permission checks in RPC; only non-owner roles need rows here.
-- Values must match apps/erp/lib/core/iam/iam_codes.dart (permission codes).

insert into iam.role_permissions (role, permission)
values
  ('staff', 'settings.einvoice.configure'), -- InterimPermissionCodes.settingsEinvoiceConfigure
  ('staff', 'iam.members.read')       -- IamPermissions.membersRead
on conflict do nothing;

-- Platform Admin mẫu cho local (admin@local.test / Vet45Local!2026).
-- Chỉ chạy qua `supabase db reset`; Dev / Prod dùng `vet45 admin create` (README).
-- Lỗi ở khối này không được làm hỏng `db reset`.
do $$
declare
  v_email constant text := 'admin@local.test';
  v_id uuid;
begin
  select id into v_id from auth.users where email = v_email;

  if v_id is null then
    v_id := '00000000-0000-4000-8000-0000000000a1';
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    )
    values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
      v_email, extensions.crypt('Vet45Local!2026', extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      '{"email_verified":true,"first_name":"Admin","last_name":"Nền tảng"}'::jsonb,
      now(), now(), '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    )
    values (
      gen_random_uuid(), v_id, v_id::text,
      jsonb_build_object('sub', v_id::text, 'email', v_email, 'email_verified', true),
      'email', now(), now(), now()
    );
  end if;

  insert into iam.platform_admins (user_id) values (v_id) on conflict do nothing;
exception
  when others then
    raise notice 'seed: bỏ qua Platform Admin mẫu (%)', sqlerrm;
end $$;
