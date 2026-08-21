-- Title: iam tenant audit history v2 before after payloads
-- Kind: patch
-- Intent: iam_tenant_audit_history_v2_payloads
-- Context: TH-01 EP-02 US-07 — capture surgical before/after state payloads in producers
-- Touches: iam.update_tenant_profile, iam.upsert_legal_profile, iam.update_my_platform_user_profile, iam.resend_tenant_invitation, iam.revoke_tenant_invitation, iam.accept_invitation
-- Safety: idempotent ; low
-- Depends on: 20260811005_iam_platform_user_lifecycle, 20260811015_iam_tenant_profile_legal, 20260811018_iam_tenant_invitation_resend_revoke, 20260811020_iam_tenant_invitation_acceptance, iam_tenant_audit_history_v2_storage

-- ── 1. update_tenant_profile ──────────────────────────────────────────────────

create or replace function iam.update_tenant_profile(
  p_tenant_id uuid,
  p_display_name text,
  p_contact_email text,
  p_contact_phone text,
  p_contact_address_text text,
  p_province_code text,
  p_commune_code text,
  p_expected_version int
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_row iam.tenants;
  v_audit_before jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.profile.update') then
    raise exception 'PERMISSION_DENIED';
  end if;

  select * into v_row from iam.tenants t where t.id = p_tenant_id for update;
  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_row.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  v_audit_before := jsonb_build_object(
    'display_name', v_row.display_name,
    'contact_email_masked', case
      when v_row.contact_email is null then null
      when v_row.contact_email like '%@%' then left(v_row.contact_email, 1) || '***@' || split_part(v_row.contact_email, '@', 2)
      else '***'
    end,
    'contact_phone_masked', case
      when v_row.contact_phone is null then null
      when length(v_row.contact_phone) <= 4 then '***'
      else left(v_row.contact_phone, 2) || '***' || right(v_row.contact_phone, 2)
    end,
    'contact_address_masked', case when nullif(trim(v_row.contact_address_text), '') is null then null else '***' end,
    'province_code', v_row.province_code,
    'commune_code', v_row.commune_code,
    'version', v_row.version
  );

  update iam.tenants
  set
    display_name = p_display_name,
    name = p_display_name,
    contact_email = p_contact_email,
    contact_phone = p_contact_phone,
    contact_address_text = p_contact_address_text,
    province_code = p_province_code,
    commune_code = p_commune_code,
    version = v_row.version + 1,
    updated_at = now()
  where id = p_tenant_id
  returning * into v_row;

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => auth.uid(),
    p_event_code => 'iam.tenant.profile_updated',
    p_subject_type => 'tenant',
    p_subject_id => p_tenant_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_tenant_id::text || ':' || v_row.version::text,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'display_name', v_row.display_name,
      'contact_email_masked', case
        when v_row.contact_email is null then null
        when v_row.contact_email like '%@%' then left(v_row.contact_email, 1) || '***@' || split_part(v_row.contact_email, '@', 2)
        else '***'
      end,
      'contact_phone_masked', case
        when v_row.contact_phone is null then null
        when length(v_row.contact_phone) <= 4 then '***'
        else left(v_row.contact_phone, 2) || '***' || right(v_row.contact_phone, 2)
      end,
      'contact_address_masked', case when nullif(trim(v_row.contact_address_text), '') is null then null else '***' end,
      'province_code', v_row.province_code,
      'commune_code', v_row.commune_code,
      'version', v_row.version
    ),
    p_redaction_flags => array[
      'before.contact_email',
      'before.contact_phone',
      'before.contact_address_text',
      'after.contact_email',
      'after.contact_phone',
      'after.contact_address_text'
    ]::text[]
  );

  return iam._tenant_json(v_row);
end;
$$;

-- ── 2. upsert_legal_profile ───────────────────────────────────────────────────

create or replace function iam.upsert_legal_profile(
  p_tenant_id uuid,
  p_legal_entity_type text,
  p_legal_name text,
  p_tax_code text,
  p_registered_address_text text,
  p_province_code text,
  p_commune_code text,
  p_expected_version int,
  p_allow_duplicate_tax_code boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_row iam.tenants;
  v_profile iam.tenant_legal_profiles;
  v_duplicate_count int := 0;
  v_audit_before jsonb;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.legal_profile.update') then
    raise exception 'PERMISSION_DENIED';
  end if;

  select * into v_row from iam.tenants t where t.id = p_tenant_id for update;
  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_row.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  select count(*) into v_duplicate_count
  from iam.tenant_legal_profiles lp
  where lp.tax_code = p_tax_code
    and lp.tenant_id <> p_tenant_id;

  if v_duplicate_count > 0 and not p_allow_duplicate_tax_code then
    return jsonb_build_object(
      'tenant_version', v_row.version,
      'warning', jsonb_build_object(
        'code', 'DUPLICATE_TAX_CODE_WARNING',
        'message', 'Tax code already used by another organization'
      )
    );
  end if;

  select * into v_profile
  from iam.tenant_legal_profiles
  where tenant_id = p_tenant_id;

  if found then
    v_audit_before := jsonb_build_object(
      'legal_name', v_profile.legal_name,
      'legal_entity_type', v_profile.legal_entity_type,
      'tax_code_masked', case when length(coalesce(v_profile.tax_code, '')) <= 5 then '***' else left(v_profile.tax_code, 3) || '***' || right(v_profile.tax_code, 2) end,
      'registered_address_masked', case
        when nullif(trim(v_profile.registered_address_text), '') is null then null
        else '***'
      end,
      'province_code', v_profile.province_code,
      'commune_code', v_profile.commune_code,
      'version', v_profile.version
    );
  else
    v_audit_before := '{}'::jsonb;
  end if;

  insert into iam.tenant_legal_profiles (
    tenant_id,
    legal_entity_type,
    legal_name,
    tax_code,
    registered_address_text,
    province_code,
    commune_code,
    version
  )
  values (
    p_tenant_id,
    p_legal_entity_type,
    p_legal_name,
    p_tax_code,
    p_registered_address_text,
    p_province_code,
    p_commune_code,
    1
  )
  on conflict (tenant_id) do update
  set
    legal_entity_type = excluded.legal_entity_type,
    legal_name = excluded.legal_name,
    tax_code = excluded.tax_code,
    registered_address_text = excluded.registered_address_text,
    province_code = excluded.province_code,
    commune_code = excluded.commune_code,
    version = iam.tenant_legal_profiles.version + 1,
    updated_at = now()
  returning * into v_profile;

  update iam.tenants
  set
    version = v_row.version + 1,
    updated_at = now()
  where id = p_tenant_id
  returning * into v_row;

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => auth.uid(),
    p_event_code => 'iam.tenant.legal_profile_updated',
    p_subject_type => 'legal_profile',
    p_subject_id => p_tenant_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_tenant_id::text || ':legal:' || v_profile.version::text,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'legal_name', v_profile.legal_name,
      'legal_entity_type', v_profile.legal_entity_type,
      'tax_code_masked', case when length(coalesce(v_profile.tax_code, '')) <= 5 then '***' else left(v_profile.tax_code, 3) || '***' || right(v_profile.tax_code, 2) end,
      'registered_address_masked', case
        when nullif(trim(v_profile.registered_address_text), '') is null then null
        else '***'
      end,
      'province_code', v_profile.province_code,
      'commune_code', v_profile.commune_code,
      'version', v_profile.version
    ),
    p_redaction_flags => array[
      'before.tax_code',
      'before.registered_address_text',
      'after.tax_code',
      'after.registered_address_text'
    ]::text[]
  );

  return jsonb_build_object(
    'tenant_version', v_row.version,
    'profile', jsonb_build_object(
      'tenant_id', v_profile.tenant_id,
      'legal_entity_type', v_profile.legal_entity_type,
      'legal_name', v_profile.legal_name,
      'tax_code', v_profile.tax_code,
      'registered_address_text', v_profile.registered_address_text,
      'province_code', v_profile.province_code,
      'commune_code', v_profile.commune_code,
      'version', v_profile.version,
      'created_at', v_profile.created_at,
      'updated_at', v_profile.updated_at
    )
  );
end;
$$;

-- ── 3. update_my_platform_user_profile ────────────────────────────────────────

create or replace function iam.update_my_platform_user_profile(
  p_avatar_reference text,
  p_given_name text,
  p_family_name text,
  p_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_given text := nullif(trim(coalesce(p_given_name, '')), '');
  v_family text := nullif(trim(coalesce(p_family_name, '')), '');
  v_phone text := nullif(trim(coalesce(p_phone, '')), '');
  v_avatar text := nullif(trim(coalesce(p_avatar_reference, '')), '');
  v_existing iam.platform_user_profiles;
  v_audit_before jsonb;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;

  if v_avatar is not null and length(v_avatar) > 512 then
    raise exception 'invalid avatar reference';
  end if;

  select * into v_existing
  from iam.platform_user_profiles
  where user_id = v_user_id;

  if found then
    v_audit_before := jsonb_build_object(
      'given_name', v_existing.given_name,
      'family_middle_name', v_existing.family_middle_name,
      'phone_masked', case when v_existing.phone_number is null then null when length(v_existing.phone_number) <= 5 then '***' else left(v_existing.phone_number, 3) || '***' || right(v_existing.phone_number, 2) end
    );
  else
    v_audit_before := '{}'::jsonb;
  end if;

  insert into iam.platform_user_profiles (
    user_id, given_name, family_middle_name, phone_number, avatar_reference,
    status, created_at, updated_at
  )
  values (
    v_user_id, v_given, v_family, v_phone, v_avatar,
    'pending_activation', now(), now()
  )
  on conflict (user_id) do update
    set given_name = excluded.given_name,
        family_middle_name = excluded.family_middle_name,
        phone_number = excluded.phone_number,
        avatar_reference = excluded.avatar_reference,
        updated_at = now();

  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => null,
    p_actor_user_id => v_user_id,
    p_event_code => 'iam.account.profile_updated',
    p_subject_type => 'account',
    p_subject_id => v_user_id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => v_user_id::text || ':' || extract(epoch from now())::text,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'given_name', v_given,
      'family_middle_name', v_family,
      'phone_masked', case when v_phone is null then null when length(v_phone) <= 5 then '***' else left(v_phone, 3) || '***' || right(v_phone, 2) end
    ),
    p_redaction_flags => array['before.phone_number', 'after.phone_number']::text[]
  );

  return iam.get_my_platform_user_profile();
end;
$$;

-- ── 4. resend_tenant_invitation ───────────────────────────────────────────────

create or replace function iam.resend_tenant_invitation(
  p_tenant_id uuid,
  p_invitation_id uuid,
  p_expected_version int,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_existing iam.tenant_invitation_mutate_operations;
  v_payload_hash text;
  v_raw_token text;
  v_token_hash text;
  v_ciphertext text;
  v_now timestamptz := now();
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_masked text;
  v_result jsonb;
  v_audit_before jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  v_payload_hash := md5(
    p_tenant_id::text || '|' || p_invitation_id::text || '|' ||
    p_expected_version::text || '|resend'
  );

  select * into v_existing
  from iam.tenant_invitation_mutate_operations o
  where o.tenant_id = p_tenant_id
    and o.invitation_id = p_invitation_id
    and o.operation = 'resend'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  select * into v_inv
  from iam.tenant_invitations i
  where i.id = p_invitation_id
    and i.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_ALREADY_USED';
  end if;

  if v_inv.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  v_audit_before := jsonb_build_object(
    'invitation_id', v_inv.id,
    'status', v_inv.status,
    'version', v_inv.version,
    'delivery_correlation_id', v_inv.delivery_correlation_id
  );

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  v_raw_token := iam._generate_invitation_code();
  v_token_hash := iam._invitation_token_hash(v_raw_token);
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_token, 'UTF8'), 'base64');

  update iam.tenant_invitations
  set
    token_hash = v_token_hash,
    expires_at = v_now + interval '7 days',
    version = version + 1,
    status_changed_at = v_now,
    updated_at = v_now,
    delivery_correlation_id = v_correlation_id,
    last_sent_at = v_now
  where id = v_inv.id
  returning * into v_inv;

  v_raw_token := null;
  v_masked := left(v_inv.invitee_email, 1) || '***' ||
    substring(v_inv.invitee_email from position('@' in v_inv.invitee_email));

  perform iam.enqueue_outbox_message(
    p_tenant_id,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'event_version', 1,
      'id', v_message_id,
      'occurred_on', v_now,
      'tenant_id', p_tenant_id,
      'template_id', 'tenant_invitation',
      'to_email', v_inv.invitee_email,
      'correlation_id', v_correlation_id,
      'outcome_id', v_outcome_id,
      'locale', 'vi',
      'refs', jsonb_build_object(
        'invitation_id', v_inv.id::text,
        'tenant_id', p_tenant_id::text
      ),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_correlation_id,
    p_template_id := 'tenant_invitation',
    p_status := 'queued',
    p_tenant_id := p_tenant_id,
    p_to_email_masked := v_masked,
    p_id := v_outcome_id
  );

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'iam.tenant.invitation_resent',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'status', v_inv.status,
      'invitation_id', v_inv.id,
      'version', v_inv.version,
      'delivery_correlation_id', v_correlation_id
    )
  );

  v_result := iam._invitation_detail_json(
    v_inv,
    coalesce(v_role.label, ''),
    v_caller::text,
    null,
    null
  );

  insert into iam.tenant_invitation_mutate_operations (
    tenant_id, invitation_id, operation, idempotency_key, payload_hash, result
  ) values (
    p_tenant_id, p_invitation_id, 'resend', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

-- ── 5. revoke_tenant_invitation ───────────────────────────────────────────────

create or replace function iam.revoke_tenant_invitation(
  p_tenant_id uuid,
  p_invitation_id uuid,
  p_expected_version int,
  p_reason text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_existing iam.tenant_invitation_mutate_operations;
  v_payload_hash text;
  v_reason text;
  v_now timestamptz := now();
  v_result jsonb;
  v_audit_before jsonb;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  v_reason := trim(coalesce(p_reason, ''));
  if v_reason = '' or p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  if not iam.has_permission(p_tenant_id, 'tenant.member.invite') then
    raise exception 'PERMISSION_DENIED';
  end if;

  v_payload_hash := md5(
    p_tenant_id::text || '|' || p_invitation_id::text || '|' ||
    p_expected_version::text || '|revoke|' || v_reason
  );

  select * into v_existing
  from iam.tenant_invitation_mutate_operations o
  where o.tenant_id = p_tenant_id
    and o.invitation_id = p_invitation_id
    and o.operation = 'revoke'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  select * into v_inv
  from iam.tenant_invitations i
  where i.id = p_invitation_id
    and i.tenant_id = p_tenant_id
  for update;

  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  if v_inv.status <> 'pending' then
    raise exception 'INVITATION_ALREADY_USED';
  end if;

  if v_inv.version <> p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  v_audit_before := jsonb_build_object(
    'invitation_id', v_inv.id,
    'status', v_inv.status,
    'version', v_inv.version
  );

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  update iam.tenant_invitations
  set
    status = 'revoked',
    revoke_reason = v_reason,
    token_hash = encode(extensions.digest(extensions.gen_random_bytes(32), 'sha256'), 'hex'),
    version = version + 1,
    status_changed_at = v_now,
    updated_at = v_now
  where id = v_inv.id
  returning * into v_inv;

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'iam.tenant.invitation_revoked',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'status', v_inv.status,
      'invitation_id', v_inv.id,
      'revoke_reason', v_reason,
      'version', v_inv.version
    )
  );

  v_result := iam._invitation_detail_json(
    v_inv,
    coalesce(v_role.label, ''),
    v_caller::text,
    v_now,
    null
  );

  insert into iam.tenant_invitation_mutate_operations (
    tenant_id, invitation_id, operation, idempotency_key, payload_hash, result
  ) values (
    p_tenant_id, p_invitation_id, 'revoke', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

-- ── 6. accept_invitation ──────────────────────────────────────────────────────

create or replace function iam.accept_invitation(
  p_token text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_inv iam.tenant_invitations;
  v_owner_activation record;
  v_tenant iam.tenants;
  v_role iam.role_definitions;
  v_hash text;
  v_legacy_hash text;
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
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

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

  begin
    v_inv := iam._load_invitation_by_token(p_token);
  exception
    when others then
      if sqlerrm not like 'INVITATION_TOKEN_INVALID%' then
        raise;
      end if;

      v_legacy_hash := encode(
        extensions.digest(upper(trim(coalesce(p_token, ''))), 'sha256'),
        'hex'
      );

      select * into v_owner_activation
      from iam.owner_activations oa
      where oa.code_hash in (v_hash, v_legacy_hash)
      for update;

      if not found then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;

      select lower(trim(u.email::text)) into v_email
      from auth.users u
      where u.id = v_caller;

      if lower(coalesce(v_email, '')) <> lower(v_owner_activation.invitee_email) then
        update iam.owner_activations
        set attempt_count = attempt_count + 1
        where id = v_owner_activation.id;
        raise exception 'INVITATION_EMAIL_MISMATCH';
      end if;

      if v_owner_activation.status = 'accepted' then
        raise exception 'INVITATION_ALREADY_USED';
      end if;
      if v_owner_activation.status = 'expired'
          or v_owner_activation.expires_at <= v_now then
        update iam.owner_activations
        set status = 'expired'
        where id = v_owner_activation.id;
        raise exception 'INVITATION_EXPIRED';
      end if;
      if v_owner_activation.status <> 'pending' then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;

      select * into v_tenant
      from iam.tenants t
      where t.id = v_owner_activation.tenant_id
      for update;
      if not found then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;
      if coalesce(v_tenant.status, 'active') = 'suspended' then
        raise exception 'TENANT_SUSPENDED';
      end if;

      update iam.memberships
      set role = 'store_owner',
          status = 'active',
          is_owner = true,
          version = version + 1,
          updated_at = v_now
      where tenant_id = v_owner_activation.tenant_id
        and user_id = v_caller
        and status in ('active', 'inactive')
      returning * into v_membership;

      if not found then
        insert into iam.memberships (
          tenant_id,
          user_id,
          role,
          status,
          is_owner,
          version,
          created_at,
          updated_at
        )
        values (
          v_owner_activation.tenant_id,
          v_caller,
          'store_owner',
          'active',
          true,
          1,
          v_now,
          v_now
        )
        returning * into v_membership;
      end if;

      update iam.platform_user_profiles
      set status = 'active',
          email_verified = true,
          email = coalesce(email, v_owner_activation.invitee_email),
          updated_at = v_now
      where user_id = v_caller;

      if not found then
        insert into iam.platform_user_profiles (
          user_id, status, email_verified, email, given_name, family_middle_name,
          phone_number, created_at, updated_at
        )
        values (
          v_caller, 'active', true, v_owner_activation.invitee_email,
          v_owner_activation.given_name,
          v_owner_activation.family_name, v_owner_activation.phone, v_now, v_now
        );
      end if;

      update iam.owner_activations
      set status = 'accepted',
          accepted_at = v_now,
          code_hash = encode(
            extensions.digest(extensions.gen_random_bytes(32), 'sha256'),
            'hex'
          )
      where id = v_owner_activation.id;

      v_result := iam._membership_detail_json(v_membership);

      insert into iam.tenant_invitation_token_operations (
        token_hash, operation, idempotency_key, payload_hash, result
      ) values (
        v_hash, 'accept', p_idempotency_key, v_payload_hash, v_result
      );

      return v_result;
  end;

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

  select lower(trim(u.email::text)) into v_email
  from auth.users u
  where u.id = v_caller;

  if v_email is null or v_email <> v_inv.invitee_email then
    raise exception 'INVITATION_EMAIL_MISMATCH';
  end if;

  if exists (
    select 1 from iam.memberships m
    where m.tenant_id = v_inv.tenant_id
      and m.user_id = v_caller
      and m.status = 'active'
  ) then
    raise exception 'DUPLICATE_MEMBERSHIP';
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
    tenant_id,
    user_id,
    role,
    status,
    is_owner,
    version,
    created_at,
    updated_at
  )
  values (
    v_inv.tenant_id,
    v_caller,
    v_effective_role,
    'active',
    v_should_be_owner,
    1,
    v_now,
    v_now
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

  v_result := iam._membership_detail_json(v_membership);

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => v_inv.tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'iam.tenant.invitation_accepted',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => v_audit_before,
    p_after => jsonb_build_object(
      'invitation_id', v_inv.id,
      'status', v_inv.status,
      'membership_id', v_membership.id,
      'version', v_inv.version
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
