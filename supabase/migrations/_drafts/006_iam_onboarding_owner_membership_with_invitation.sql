-- Title: iam create_tenant_onboarding owner membership + invitation (hybrid)
-- Kind: patch
-- Intent: iam_hybrid_owner_membership_onboarding
-- Context: TH-01 hybrid — onboarding tạo Owner Membership ngay cùng owner invitation; cho phép membership.user_id placeholder (pending profile) như platform_user_profiles; cleanup signup rebind membership trước khi xóa placeholder
-- Touches: iam.create_tenant_onboarding, iam._cleanup_pending_profile_on_auth_user
-- Safety: idempotent; medium
-- Depends on: 20260826003_iam_audit_owner_activation_cleanup.sql

-- Membership may reference pending placeholder user_id until accept/signup rebinds.
alter table iam.memberships
  drop constraint if exists memberships_user_id_fkey;

create or replace function iam._cleanup_pending_profile_on_auth_user()
returns trigger
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  if new.email is null then
    return new;
  end if;

  -- Rebind memberships that still point at the pending placeholder for this email.
  update iam.memberships m
  set
    user_id = new.id,
    updated_at = timezone('utc', now())
  from iam.platform_user_profiles p
  where m.user_id = p.user_id
    and p.status = 'pending_activation'
    and p.email is not null
    and lower(p.email) = lower(new.email::text)
    and p.user_id <> new.id;

  delete from iam.platform_user_profiles p
  where p.status = 'pending_activation'
    and p.email is not null
    and lower(p.email) = lower(new.email::text)
    and p.user_id <> new.id;
  return new;
end;
$$;

create or replace function iam.create_tenant_onboarding(
  p_owner_user_id uuid,
  p_org_name text,
  p_idempotency_key text,
  p_correlation_id text default null,
  p_is_new_user boolean default false,
  p_owner_email text default null,
  p_owner_given_name text default null,
  p_owner_family_name text default null,
  p_owner_phone text default null,
  p_org_display_name text default null,
  p_org_contact_email text default null,
  p_org_contact_phone text default null,
  p_org_contact_address_text text default null,
  p_org_province_code text default null,
  p_org_commune_code text default null,
  p_org_legal_name text default null,
  p_org_tax_code text default null,
  p_org_registered_address_text text default null
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_existing jsonb;
  v_tenant_id uuid;
  v_correlation text;
  v_owner_email text;
  v_owner_email_masked text;
  v_owner_role_id uuid;
  v_invitation_id uuid;
  v_membership_id uuid;
  v_owner_user_id uuid;
  v_org_legal_name text := nullif(trim(coalesce(p_org_legal_name, '')), '');
  v_org_tax_code text := nullif(trim(coalesce(p_org_tax_code, '')), '');
  v_org_registered_address_text text :=
    nullif(trim(coalesce(p_org_registered_address_text, '')), '');
  v_message_id uuid := gen_random_uuid();
  v_outcome_id uuid := gen_random_uuid();
  v_now timestamptz := now();
  v_is_new boolean := coalesce(p_is_new_user, false);
  v_provisioned_user_id uuid;
  v_raw_code text;
  v_code_hash text;
  v_ciphertext text;
  v_result jsonb;
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'platform permission denied';
  end if;

  if p_org_name is null or trim(p_org_name) = '' then
    raise exception 'organization name required';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'idempotency key required';
  end if;

  if v_is_new then
    v_owner_email := lower(trim(coalesce(p_owner_email, '')));
    if v_owner_email = '' or position('@' in v_owner_email) = 0 then
      raise exception 'owner email required';
    end if;
  else
    if p_owner_user_id is null then
      raise exception 'owner user id required';
    end if;
  end if;

  select result into v_existing
  from iam.onboarding_operations
  where idempotency_key = p_idempotency_key;

  if v_existing is not null then
    return v_existing;
  end if;

  v_correlation := coalesce(nullif(trim(p_correlation_id), ''), gen_random_uuid()::text);

  insert into iam.tenants (
    name, display_name, contact_email, contact_phone, contact_address_text,
    province_code, commune_code, status, updated_at
  )
  values (
    trim(p_org_name),
    coalesce(nullif(trim(coalesce(p_org_display_name, '')), ''), trim(p_org_name)),
    nullif(trim(coalesce(p_org_contact_email, '')), ''),
    nullif(trim(coalesce(p_org_contact_phone, '')), ''),
    nullif(trim(coalesce(p_org_contact_address_text, '')), ''),
    nullif(trim(coalesce(p_org_province_code, '')), ''),
    nullif(trim(coalesce(p_org_commune_code, '')), ''),
    'provisioning',
    v_now
  )
  returning id into v_tenant_id;

  if v_org_legal_name is not null and v_org_tax_code is not null then
    insert into iam.tenant_legal_profiles (
      tenant_id, legal_entity_type, legal_name, tax_code,
      registered_address_text, province_code, commune_code, created_at, updated_at
    )
    values (
      v_tenant_id,
      case
        when length(regexp_replace(v_org_tax_code, '\D', '', 'g')) = 12
          then 'HOUSEHOLD_BUSINESS'
        else 'ENTERPRISE'
      end,
      v_org_legal_name,
      v_org_tax_code,
      v_org_registered_address_text,
      nullif(trim(coalesce(p_org_province_code, '')), ''),
      nullif(trim(coalesce(p_org_commune_code, '')), ''),
      v_now, v_now
    );
  end if;

  perform iam.enqueue_outbox_message(
    v_tenant_id,
    'iam.tenant.created',
    jsonb_build_object(
      'tenant_id', v_tenant_id,
      'owner_user_id', p_owner_user_id,
      'actor_user_id', v_actor,
      'correlation_id', v_correlation
    )
  );

  if not v_is_new then
    select lower(u.email::text) into v_owner_email
    from auth.users u
    where u.id = p_owner_user_id;
    if v_owner_email is null or trim(v_owner_email) = '' then
      raise exception 'owner email required';
    end if;
    v_owner_user_id := p_owner_user_id;
  end if;

  if v_is_new then
    select u.id into v_provisioned_user_id
    from auth.users u
    where lower(u.email::text) = v_owner_email
    limit 1;

    if v_provisioned_user_id is null then
      select p.user_id into v_provisioned_user_id
      from iam.platform_user_profiles p
      where lower(p.email) = v_owner_email
      limit 1;
    end if;

    if v_provisioned_user_id is null then
      v_provisioned_user_id := gen_random_uuid();
      insert into iam.platform_user_profiles (
        user_id, email, status, given_name, family_middle_name, phone_number,
        created_at, updated_at
      )
      values (
        v_provisioned_user_id,
        v_owner_email,
        'pending_activation',
        nullif(trim(coalesce(p_owner_given_name, '')), ''),
        nullif(trim(coalesce(p_owner_family_name, '')), ''),
        nullif(trim(coalesce(p_owner_phone, '')), ''),
        v_now, v_now
      );
    end if;
    v_owner_user_id := v_provisioned_user_id;
  end if;

  select id into v_owner_role_id
  from iam.role_definitions
  where code = 'store_owner' and status = 'active';
  if v_owner_role_id is null then
    raise exception 'store_owner role missing';
  end if;

  -- Hybrid: Owner Membership ngay khi onboarding (trước accept).
  insert into iam.memberships (
    tenant_id, user_id, role, status, is_owner, version, created_at, updated_at
  )
  values (
    v_tenant_id, v_owner_user_id, 'store_owner', 'active', true, 1, v_now, v_now
  )
  returning id into v_membership_id;

  v_raw_code := iam._generate_invitation_code();
  v_code_hash := iam._invitation_token_hash(v_raw_code);
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_code, 'UTF8'), 'base64');

  insert into iam.tenant_invitations (
    tenant_id, invitee_email, initial_role_id, status, token_hash,
    is_owner, invited_by_membership_id, given_name, family_name, phone,
    expires_at, status_changed_at, version, created_at, updated_at, delivery_correlation_id
  )
  values (
    v_tenant_id, v_owner_email, v_owner_role_id, 'pending', v_code_hash,
    true, null,
    nullif(trim(coalesce(p_owner_given_name, '')), ''),
    nullif(trim(coalesce(p_owner_family_name, '')), ''),
    nullif(trim(coalesce(p_owner_phone, '')), ''),
    v_now + interval '7 days', v_now,
    1, v_now, v_now, v_correlation
  )
  returning id into v_invitation_id;

  v_owner_email_masked :=
    left(v_owner_email, 1) || '***' ||
    substring(v_owner_email from position('@' in v_owner_email));

  perform iam.enqueue_outbox_message(
    v_tenant_id,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', v_now,
      'tenant_id', v_tenant_id,
      'template_id', 'activation_invitation',
      'to_email', v_owner_email,
      'correlation_id', v_correlation,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object(
        'tenant_id', v_tenant_id::text,
        'invitation_id', v_invitation_id::text
      ),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  v_raw_code := null;

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation,
    p_template_id := 'activation_invitation',
    p_status := 'queued',
    p_tenant_id := v_tenant_id,
    p_to_email_masked := v_owner_email_masked,
    p_id := v_outcome_id
  );

  v_result := jsonb_build_object(
    'tenant_id', v_tenant_id,
    'owner_membership_id', v_membership_id,
    'owner_user_id', v_owner_user_id,
    'tenant_status', 'provisioning',
    'correlation_id', v_correlation,
    'is_new_user', v_is_new,
    'activation_issued', true
  );

  insert into iam.onboarding_operations (idempotency_key, correlation_id, result)
  values (p_idempotency_key, v_correlation, v_result);

  return v_result;
end;
$$;

revoke all on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text
) from public, anon;
grant execute on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text, text, text, text, text, text, text, text, text, text
) to authenticated;
