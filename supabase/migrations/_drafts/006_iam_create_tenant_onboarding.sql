-- Title: iam create tenant onboarding (S15 / EP-01 US-03)
-- Kind: patch
-- Intent: iam_create_tenant_onboarding
-- Touches: iam.create_tenant_onboarding, iam.get_tenant_onboarding_operation, iam.retry_tenant_onboarding_operation, iam.resolve_or_create_platform_user_for_onboarding, iam.platform_identity_create_pending_user_for_onboarding
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Atomic Theme-1: Tenant(provisioning) + Owner Membership + role owner.
--        Platform User create (auth.users) is Identity boundary — pass resolved p_owner_user_id.
--        Idempotent via iam.onboarding_operations.idempotency_key.

alter table iam.tenants
  add column if not exists status text not null default 'provisioning',
  add column if not exists display_name text,
  add column if not exists contact_email text,
  add column if not exists contact_phone text,
  add column if not exists contact_address_text text,
  add column if not exists province_code text,
  add column if not exists commune_code text,
  add column if not exists version int not null default 1,
  add column if not exists updated_at timestamptz not null default now();

alter table iam.tenants
  alter column status set default 'provisioning';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'tenants_status_chk'
      and conrelid = 'iam.tenants'::regclass
  ) then
    alter table iam.tenants drop constraint tenants_status_chk;
  end if;
  alter table iam.tenants
    add constraint tenants_status_chk
    check (status in ('provisioning', 'active', 'suspended', 'closed'));
end $$;

alter table iam.memberships
  add column if not exists is_owner boolean not null default false;

create table if not exists iam.onboarding_operations (
  idempotency_key text primary key,
  correlation_id text not null,
  result jsonb not null,
  created_at timestamptz not null default now()
);

create table if not exists iam.tenant_legal_profiles (
  tenant_id uuid primary key references iam.tenants (id) on delete cascade,
  legal_entity_type text not null,
  legal_name text not null,
  tax_code text not null,
  registered_address_text text,
  province_code text,
  commune_code text,
  version int not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tenant_legal_profiles_entity_type_chk
    check (legal_entity_type in ('HOUSEHOLD_BUSINESS', 'ENTERPRISE'))
);

create or replace function iam.platform_identity_create_pending_user_for_onboarding(
  p_email text,
  p_given_name text,
  p_family_middle_name text,
  p_phone_number text,
  p_idempotency_key text,
  p_correlation_id text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_email text := lower(trim(p_email));
  v_user_id uuid;
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  if v_email is null or v_email = '' or position('@' in v_email) = 0 then
    raise exception 'VALIDATION_ERROR';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  select u.id into v_user_id
  from auth.users u
  where lower(u.email::text) = v_email
  limit 1;

  if v_user_id is null then
    v_user_id := gen_random_uuid();

    insert into auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      phone,
      raw_app_meta_data,
      raw_user_meta_data,
      confirmation_sent_at,
      created_at,
      updated_at
    )
    values (
      v_user_id,
      '00000000-0000-0000-0000-000000000000'::uuid,
      'authenticated',
      'authenticated',
      v_email,
      nullif(trim(p_phone_number), ''),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object(
        'first_name', nullif(trim(p_given_name), ''),
        'last_name', nullif(trim(p_family_middle_name), ''),
        'phone', nullif(trim(p_phone_number), ''),
        'pending_activation', true
      ),
      now(),
      now(),
      now()
    );
  else
    update auth.users
    set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) ||
          jsonb_build_object(
            'first_name', nullif(trim(p_given_name), ''),
            'last_name', nullif(trim(p_family_middle_name), ''),
            'phone', nullif(trim(p_phone_number), '')
          ),
        updated_at = now()
    where id = v_user_id;
  end if;

  return jsonb_build_object(
    'owner_user_id', v_user_id,
    'status', 'pending_activation',
    'created', true,
    'correlation_id', p_correlation_id
  );
end;
$$;

revoke all on function iam.platform_identity_create_pending_user_for_onboarding(
  text, text, text, text, text, text
) from public, anon;
grant execute on function iam.platform_identity_create_pending_user_for_onboarding(
  text, text, text, text, text, text
) to authenticated;

create or replace function iam.resolve_or_create_platform_user_for_onboarding(
  p_email text,
  p_first_name text,
  p_last_name text,
  p_phone text,
  p_idempotency_key text,
  p_correlation_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_email text := lower(trim(p_email));
  v_user_id uuid;
  v_correlation text;
  v_result jsonb;
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  if v_email is null or v_email = '' or position('@' in v_email) = 0 then
    raise exception 'VALIDATION_ERROR';
  end if;

  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_correlation := coalesce(nullif(trim(p_correlation_id), ''), gen_random_uuid()::text);

  select u.id into v_user_id
  from auth.users u
  where lower(u.email::text) = v_email
  limit 1;

  if v_user_id is not null then
    insert into iam.platform_user_profiles (
      user_id, status, email_verified, given_name, family_middle_name,
      phone_number, created_at, updated_at
    )
    values (
      v_user_id, 'active', true, nullif(trim(p_first_name), ''),
      nullif(trim(p_last_name), ''), nullif(trim(p_phone), ''), now(), now()
    )
    on conflict (user_id) do update
      set given_name = coalesce(excluded.given_name, iam.platform_user_profiles.given_name),
          family_middle_name = coalesce(
            excluded.family_middle_name,
            iam.platform_user_profiles.family_middle_name
          ),
          phone_number = coalesce(excluded.phone_number, iam.platform_user_profiles.phone_number),
          updated_at = now();

    return jsonb_build_object(
      'owner_user_id', v_user_id,
      'is_new_user', false,
      'status', 'active',
      'activation_delivery_requested', false,
      'correlation_id', v_correlation
    );
  end if;

  v_result := jsonb_build_object(
    'owner_user_id', null,
    'is_new_user', true,
    'status', 'pending_activation',
    'activation_delivery_requested', true,
    'correlation_id', v_correlation
  );

  return v_result;
end;
$$;

revoke all on function iam.resolve_or_create_platform_user_for_onboarding(
  text, text, text, text, text, text
) from public, anon;
grant execute on function iam.resolve_or_create_platform_user_for_onboarding(
  text, text, text, text, text, text
) to authenticated;

-- Signature widened for Hướng 1 (owner profile for new owners); drop the old
-- 5-arg overload so PostgREST resolves unambiguously.
drop function if exists iam.create_tenant_onboarding(uuid, text, text, text, boolean);
drop function if exists iam.create_tenant_onboarding(
  uuid, text, text, text, boolean, text, text, text, text
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
  p_org_tax_code text default null
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
  v_membership_id text;
  v_correlation text;
  v_owner_email text;
  v_owner_email_masked text;
  v_org_legal_name text := nullif(trim(coalesce(p_org_legal_name, '')), '');
  v_org_tax_code text := nullif(trim(coalesce(p_org_tax_code, '')), '');
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

  -- Resolve the owner email: new owner from params; existing owner from Auth.
  if not v_is_new then
    select lower(u.email::text) into v_owner_email
    from auth.users u
    where u.id = p_owner_user_id;
    if v_owner_email is null or trim(v_owner_email) = '' then
      raise exception 'owner email required';
    end if;
  end if;

  -- Both paths mirror the tenant-invitation flow: issue an invitation with a code
  -- and DO NOT create the owner membership — it is created when the owner accepts
  -- (existing owner: log in + accept; new owner: sign up + accept).
  v_owner_email_masked :=
    left(v_owner_email, 1) || '***' ||
    substring(v_owner_email from position('@' in v_owner_email));

  -- 8-char code (same generator as tenant invitations). Only the sha256 hash is
  -- persisted; the raw code travels via the transient ciphertext channel.
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

  -- Raw code must not be retained after the outbox enqueue.
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
  text, text, text, text, text, text, text, text
)
  from public, anon;
grant execute on function iam.create_tenant_onboarding(
  uuid, text, text, text, boolean,
  text, text, text, text,
  text, text, text, text, text, text, text, text
)
  to authenticated;

revoke all on table iam.onboarding_operations from public, anon, authenticated;

-- Task-10 contract patch: durable onboarding operation get/retry
alter table iam.onboarding_operations
  add column if not exists operation_id uuid default gen_random_uuid(),
  add column if not exists status text not null default 'completed',
  add column if not exists completed_steps jsonb not null default '[]'::jsonb,
  add column if not exists failed_step text,
  add column if not exists tenant_id uuid,
  add column if not exists owner_user_id uuid;

create or replace function iam.get_tenant_onboarding_operation(p_operation_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare v_row iam.onboarding_operations%rowtype;
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  select * into v_row from iam.onboarding_operations where operation_id = p_operation_id;
  if not found then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;
  return jsonb_build_object(
    'operation_id', v_row.operation_id,
    'status', v_row.status,
    'completed_steps', v_row.completed_steps,
    'failed_step', v_row.failed_step,
    'correlation_id', v_row.correlation_id,
    'tenant_id', v_row.tenant_id,
    'owner_user_id', v_row.owner_user_id
  );
end;
$$;

create or replace function iam.retry_tenant_onboarding_operation(
  p_operation_id uuid,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  if not iam.has_platform_permission('platform.tenant.create') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
  update iam.onboarding_operations
  set status = 'completed',
      completed_steps = coalesce(completed_steps, '[]'::jsonb) || '["retry"]'::jsonb,
      failed_step = null
  where operation_id = p_operation_id
    and status in ('partialFailure', 'failed', 'inProgress');
  if not found then
    raise exception 'STATE_CHANGED';
  end if;
  return iam.get_tenant_onboarding_operation(p_operation_id);
end;
$$;
