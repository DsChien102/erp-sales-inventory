-- Title: iam signup create tenant for owner
-- Kind: patch
-- Intent: iam_signup_create_tenant_for_owner
-- Context: TH-01 BR-06, BR-07
-- Touches: iam._create_tenant_for_owner, iam._audit_event_category
-- Safety: idempotent ; medium
-- Depends on: 20260916001_iam_ensure_default_store_scope_helpers.sql, 20260826004_iam_audit_logs_v2_rebuild.sql

-- iam.tenant.created chưa nằm trong danh mục audit. Không đăng ký thì append_audit_log ném AUDIT_EVENT_UNREGISTERED.
create or replace function iam._audit_event_category(p_event_code text)
returns text
language plpgsql
immutable
as $$
begin
  case p_event_code
    when 'iam.membership.deactivated',
         'iam.membership.reactivated',
         'iam.membership.removed',
         'iam.tenant.owner_activated',
         'iam.owner.activated' then return 'member';
    when 'iam.tenant.member_role_assigned',
         'iam.membership.role_changed' then return 'role';
    when 'iam.tenant.profile_updated',
         'iam.tenant.legal_profile_updated',
         'iam.tenant.activated',
         'iam.tenant.created',
         'iam.tenant.suspended',
         'iam.tenant.restored',
         'iam.tenant.closed',
         'iam.tenant.ownership_transferred' then return 'organization';
    when 'iam.tenant.invitation_created',
         'tenant.invitation.created',
         'iam.tenant.invitation_resent',
         'tenant.invitation.resent',
         'iam.tenant.invitation_revoked',
         'tenant.invitation.revoked',
         'iam.tenant.invitation_accepted',
         'tenant.invitation.accepted' then return 'invitation';
    when 'iam.account.profile_updated',
         'iam.user.profile_updated' then return 'account';
    when 'iam.account.password_reset_completed',
         'iam.account.signed_out',
         'iam.platform_user.suspended',
         'iam.platform_user.restored' then return 'security';
    else
      raise exception 'AUDIT_EVENT_UNREGISTERED:%', p_event_code;
  end case;
end;
$$;

revoke all on function iam._audit_event_category(text) from public, anon, authenticated;

create or replace function iam._create_tenant_for_owner(p_user_id uuid, p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_name text := nullif(trim(coalesce(p_payload->>'name', '')), '');
  v_contact_phone text := nullif(trim(coalesce(p_payload->>'contact_phone', '')), '');
  v_contact_email text := nullif(trim(coalesce(p_payload->>'contact_email', '')), '');
  v_province_code text := nullif(trim(coalesce(p_payload->>'province_code', '')), '');
  v_commune_code text := nullif(trim(coalesce(p_payload->>'commune_code', '')), '');
  v_address_text text := nullif(trim(coalesce(p_payload->>'address_text', '')), '');
  v_tenant_id uuid;
  v_now timestamptz := now();
begin
  if p_user_id is null
     or v_name is null
     or v_contact_phone is null
     or v_province_code is null
     or v_commune_code is null
     or v_address_text is null then
    raise exception 'VALIDATION_ERROR: signup_tenant';
  end if;

  -- BR-07: xác minh lần hai không tạo tổ chức thứ hai.
  if exists (
    select 1
    from iam.memberships m
    where m.user_id = p_user_id
      and m.is_owner is true
      and m.removed_at is null
  ) then
    return null;
  end if;

  insert into iam.tenants (
    display_name,
    contact_email,
    contact_phone,
    contact_address_text,
    province_code,
    commune_code,
    status,
    status_changed_at,
    activated_at,
    updated_at
  )
  values (
    v_name,
    v_contact_email,
    v_contact_phone,
    v_address_text,
    v_province_code,
    v_commune_code,
    'active',
    v_now,
    v_now,
    v_now
  )
  returning id into v_tenant_id;

  insert into iam.memberships (
    tenant_id, user_id, role, is_owner, version, created_at, updated_at
  )
  values (
    v_tenant_id, p_user_id, 'store_owner', true, 1, v_now, v_now
  );

  -- Cửa hàng mặc định. Không gán membership_store_scopes: bản accept_invitation hiện tại cũng không còn bước đó.
  perform iam._ensure_tenant_default_store(v_tenant_id);

  insert into iam.user_preferences (user_id, last_selected_tenant_id, updated_at)
  values (p_user_id, v_tenant_id, v_now)
  on conflict (user_id) do update
    set last_selected_tenant_id = excluded.last_selected_tenant_id,
        updated_at = now();

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => v_tenant_id,
    p_actor_user_id => p_user_id,
    p_event_code => 'iam.tenant.created',
    p_subject_type => 'tenant',
    p_subject_id => v_tenant_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => 'signup:' || p_user_id::text,
    p_after => jsonb_build_object('status', 'active', 'display_name', v_name)
  );

  return v_tenant_id;
end;
$$;

revoke all on function iam._create_tenant_for_owner(uuid, jsonb) from public, anon, authenticated;
