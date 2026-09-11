-- Title: iam patch accept_invitation allow anonymous acceptance for existing accounts
-- Kind: surgical
-- Intent: iam_accept_invitation_anon
-- Context: TH-01 / auth invitation acceptance for existing account
-- Touches: iam.accept_invitation
-- Safety: idempotent ; low
-- Depends on: 20260826003_iam_audit_owner_activation_cleanup

create or replace function iam.accept_invitation(
  p_token text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_tenant iam.tenants;
  v_role iam.role_definitions;
  v_hash text;
  v_email text;
  v_payload_hash text;
  v_existing iam.tenant_invitation_token_operations;
  v_membership iam.memberships;
  v_effective_role text;
  v_should_be_owner boolean := false;
  v_now timestamptz := now();
  v_result jsonb;
  v_audit_before jsonb;
begin
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_hash := iam._invitation_token_hash(p_token);
  v_payload_hash := md5(v_hash || '|accept');

  select * into v_existing
  from iam.tenant_invitation_token_operations o
  where o.token_hash = v_hash
    and o.operation = 'accept'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  -- Token phải là một lời mời hợp lệ (staff HOẶC owner); nếu không →
  -- INVITATION_TOKEN_INVALID (không còn fallback đọc bảng kích hoạt cũ).
  v_inv := iam._load_invitation_by_token(p_token);

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id for update;
  if not found then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  if coalesce(v_tenant.status, 'active') = 'suspended' then
    raise exception 'TENANT_SUSPENDED';
  end if;

  if v_inv.status = 'revoked' then
    raise exception 'INVITATION_REVOKED';
  end if;
  if v_inv.status in ('accepted', 'declined') then
    raise exception 'INVITATION_ALREADY_USED';
  end if;
  if v_inv.status = 'expired' or v_inv.expires_at <= v_now then
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  -- C1. Phân giải caller sau khi nạp lời mời
  if v_caller is not null then
    -- Authenticated: user đang đăng nhập phải đúng email được mời
    select lower(trim(u.email::text)) into v_email
    from auth.users u where u.id = v_caller;

    if v_email is null or v_email <> v_inv.invitee_email then
      raise exception 'INVITATION_EMAIL_MISMATCH';
    end if;
  else
    -- Anonymous: phân giải caller từ auth.users theo email được mời
    select u.id into v_caller
    from auth.users u
    where lower(trim(u.email::text)) = v_inv.invitee_email
    limit 1;

    if v_caller is null then
      raise exception 'INVITATION_EMAIL_MISMATCH';
    end if;
    v_email := v_inv.invitee_email;
  end if;

  -- C2. Xử lý DUPLICATE_MEMBERSHIP (nếu đã là thành viên của tenant)
  select * into v_membership
  from iam.memberships m
  where m.tenant_id = v_inv.tenant_id
    and m.user_id = v_caller
    and m.status = 'active';

  if found then
    -- 0. Chụp trạng thái TRƯỚC khi update
    v_audit_before := jsonb_build_object(
      'invitation_id', v_inv.id,
      'status', v_inv.status,
      'version', v_inv.version
    );

    -- 0b. Lấy vai trò THỰC TẾ của thành viên đã có (không dùng initial_role_id của lời mời)
    select * into v_role
    from iam.role_definitions r
    where r.code = v_membership.role;

    -- 1. Cập nhật lời mời sang accepted (xoay token hash)
    update iam.tenant_invitations
    set status = 'accepted',
        accepted_membership_id = v_membership.id,
        status_changed_at = v_now,
        version = version + 1,
        updated_at = v_now,
        token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex')
    where id = v_inv.id
    returning * into v_inv;

    -- 2. Ghi user_preferences để khi đăng nhập tự động vào đúng tenant này
    insert into iam.user_preferences (user_id, last_selected_tenant_id, updated_at)
    values (v_caller, v_inv.tenant_id, v_now)
    on conflict (user_id) do update
      set last_selected_tenant_id = excluded.last_selected_tenant_id,
          updated_at = excluded.updated_at;

    -- 3. Ghi audit log đầy đủ với vai trò thực tế v_membership.role
    perform iam.append_audit_log(
      p_scope => 'tenant',
      p_tenant_id => v_inv.tenant_id,
      p_actor_user_id => v_caller,
      p_event_code => 'iam.tenant.invitation_accepted',
      p_subject_type => 'tenant',
      p_subject_id => v_inv.tenant_id::text,
      p_result => 'success',
      p_source => 'iam',
      p_tracking_id => p_idempotency_key,
      p_before => v_audit_before,
      p_after => jsonb_build_object(
        'invitation_id', v_inv.id,
        'status', v_inv.status,
        'membership_id', v_membership.id,
        'version', v_inv.version
      ),
      p_actor_type => 'tenant_member',
      p_actor_membership_id => v_membership.id,
      p_actor_display_name => nullif(trim(concat_ws(' ', v_inv.family_name, v_inv.given_name)), ''),
      p_actor_context_label => coalesce(v_role.label, v_membership.role::text),
      p_actor_snapshot => jsonb_build_object(
        'display_name', nullif(trim(concat_ws(' ', v_inv.family_name, v_inv.given_name)), ''),
        'actor_type', 'tenant_member',
        'role_code', v_membership.role::text,
        'role_label', coalesce(v_role.label, v_membership.role::text)
      ),
      p_target_display_name => v_tenant.display_name,
      p_target_secondary_identifier => v_tenant.code,
      p_target_snapshot => jsonb_build_object(
        'display_name', v_tenant.display_name,
        'subject_code', v_tenant.code,
        'secondary_label', v_tenant.code
      ),
      p_correlation_id => p_idempotency_key,
      p_detail_items => jsonb_build_array(
        jsonb_build_object(
          'field_key', 'status',
          'before', v_audit_before->'status',
          'after', to_jsonb(v_inv.status)
        )
      )
    );

    v_result := iam._membership_detail_json(v_membership);

    -- 4. Lưu idempotency
    insert into iam.tenant_invitation_token_operations (
      token_hash, operation, idempotency_key, payload_hash, result
    ) values (
      v_hash, 'accept', p_idempotency_key, v_payload_hash, v_result
    );

    return v_result;
  end if;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;
  if not found or v_role.status <> 'active' then
    raise exception 'ROLE_NOT_ASSIGNABLE';
  end if;

  v_audit_before := jsonb_build_object(
    'invitation_id', v_inv.id,
    'status', v_inv.status,
    'version', v_inv.version
  );

  -- Người active đầu tiên của tenant là chủ: is_owner + role store_owner.
  v_should_be_owner := not exists (
    select 1
    from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.status = 'active'
      and (m.is_owner is true or m.role = 'owner')
  );
  v_effective_role := case
    when v_should_be_owner then 'store_owner'
    else coalesce(v_role.code, 'staff')
  end;

  insert into iam.memberships (
    tenant_id, user_id, role, status, is_owner, version, created_at, updated_at
  )
  values (
    v_inv.tenant_id, v_caller, v_effective_role, 'active', v_should_be_owner, 1, v_now, v_now
  )
  returning * into v_membership;

  update iam.tenant_invitations
  set
    status = 'accepted',
    accepted_membership_id = v_membership.id,
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now,
    token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex')
  where id = v_inv.id
  returning * into v_inv;

  -- C3. Ghi last_selected_tenant_id ở luồng tạo membership mới
  insert into iam.user_preferences (user_id, last_selected_tenant_id, updated_at)
  values (v_caller, v_inv.tenant_id, v_now)
  on conflict (user_id) do update
    set last_selected_tenant_id = excluded.last_selected_tenant_id,
        updated_at = excluded.updated_at;

  -- Owner (người active đầu tiên): tạo/kích hoạt platform_user_profiles với tên
  -- từ lời mời (admin đã nhập lúc onboarding) để Platform Admin hiển thị đúng
  -- tên, tránh "Chưa xác định owner". Staff không có profile platform ở đây.
  if v_should_be_owner then
    insert into iam.platform_user_profiles (
      user_id, email, status, email_verified, given_name, family_middle_name,
      phone_number, created_at, updated_at
    )
    values (
      v_caller, v_email, 'active', true, v_inv.given_name, v_inv.family_name, v_inv.phone,
      v_now, v_now
    )
    on conflict (user_id) do update
      set status = 'active',
          email = coalesce(excluded.email, iam.platform_user_profiles.email),
          email_verified = true,
          given_name = coalesce(excluded.given_name, iam.platform_user_profiles.given_name),
          family_middle_name = coalesce(
            excluded.family_middle_name, iam.platform_user_profiles.family_middle_name
          ),
          phone_number = coalesce(excluded.phone_number, iam.platform_user_profiles.phone_number),
          updated_at = v_now;
  end if;

  v_result := iam._membership_detail_json(v_membership);

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => v_inv.tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'iam.tenant.invitation_accepted',
    p_subject_type => 'tenant',
    p_subject_id => v_inv.tenant_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'invitation_id', v_inv.id,
      'status', v_inv.status,
      'membership_id', v_membership.id,
      'version', v_inv.version
    ),
    p_actor_type => 'tenant_member',
    p_actor_membership_id => v_membership.id,
    p_actor_display_name => nullif(
      trim(concat_ws(' ', v_inv.family_name, v_inv.given_name)),
      ''
    ),
    p_actor_context_label => coalesce(v_role.label, v_effective_role),
    p_actor_snapshot => jsonb_build_object(
      'display_name', nullif(
        trim(concat_ws(' ', v_inv.family_name, v_inv.given_name)),
        ''
      ),
      'actor_type', 'tenant_member',
      'role_code', v_effective_role,
      'role_label', coalesce(v_role.label, v_effective_role)
    ),
    p_target_display_name => v_tenant.display_name,
    p_target_secondary_identifier => v_tenant.code,
    p_target_snapshot => jsonb_build_object(
      'display_name', v_tenant.display_name,
      'subject_code', v_tenant.code,
      'secondary_label', v_tenant.code
    ),
    p_correlation_id => p_idempotency_key,
    p_detail_items => jsonb_build_array(
      jsonb_build_object(
        'field_key', 'status',
        'before', v_audit_before->'status',
        'after', to_jsonb(v_inv.status)
      ),
      jsonb_build_object(
        'field_key', 'membership_id',
        'before', null,
        'after', to_jsonb(v_membership.id)
      )
    )
  );

  insert into iam.tenant_invitation_token_operations (
    token_hash, operation, idempotency_key, payload_hash, result
  ) values (
    v_hash, 'accept', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

-- C4. Phân quyền thực thi
revoke all on function iam.accept_invitation(text, text) from public;
grant execute on function iam.accept_invitation(text, text) to anon, authenticated;
