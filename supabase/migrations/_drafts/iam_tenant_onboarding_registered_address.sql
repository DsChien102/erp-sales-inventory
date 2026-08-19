-- Title: iam tenant onboarding registered address
-- Kind: patch
-- Intent: iam_tenant_onboarding_registered_address
-- Touches: iam.create_tenant_onboarding

drop function if exists iam.create_tenant_onboarding(
  uuid, text, text, text, boolean,
  text, text, text, text,
  text, text, text, text, text, text, text, text
);

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
  v_org_legal_name text := nullif(trim(coalesce(p_org_legal_name, '')), '');
  v_org_tax_code text := nullif(trim(coalesce(p_org_tax_code, '')), '');
  v_org_registered_address_text text :=
    nullif(trim(coalesce(p_org_registered_address_text, '')), '');
  v_message_id uuid := gen_random_uuid();
  v_outcome_id uuid := gen_random_uuid();
  v_now timestamptz := timezone('utc', now());
  v_raw_code text;
  v_code_hash text;
  v_ciphertext text;
  v_is_new boolean := coalesce(p_is_new_user, false);
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
    name,
    display_name,
    contact_email,
    contact_phone,
    contact_address_text,
    province_code,
    commune_code,
    status,
    updated_at
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
      tenant_id,
      legal_entity_type,
      legal_name,
      tax_code,
      registered_address_text,
      province_code,
      commune_code,
      created_at,
      updated_at
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
      v_now,
      v_now
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
  end if;

  v_owner_email_masked :=
    left(v_owner_email, 1) || '***' ||
    substring(v_owner_email from position('@' in v_owner_email));

  v_raw_code := iam._generate_invitation_code();
  v_code_hash := iam._invitation_token_hash(v_raw_code);
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_code, 'UTF8'), 'base64');

  insert into iam.owner_activations (
    tenant_id, invitee_email, given_name, family_name, phone, code_hash, expires_at
  )
  values (
    v_tenant_id,
    v_owner_email,
    case when v_is_new then nullif(trim(coalesce(p_owner_given_name, '')), '') end,
    case when v_is_new then nullif(trim(coalesce(p_owner_family_name, '')), '') end,
    case when v_is_new then nullif(trim(coalesce(p_owner_phone, '')), '') end,
    v_code_hash,
    v_now + interval '7 days'
  );

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
      'refs', jsonb_build_object('tenant_id', v_tenant_id::text),
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
    'owner_membership_id', null,
    'owner_user_id', p_owner_user_id,
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
  uuid, text, text, text, boolean,
  text, text, text, text,
  text, text, text, text, text, text, text, text, text
)
  from public, anon;
grant execute on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean,
  text, text, text, text,
  text, text, text, text, text, text, text, text, text
)
  to authenticated;
