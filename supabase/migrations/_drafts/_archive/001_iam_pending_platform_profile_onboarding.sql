-- Title: IAM pending platform profile at onboarding
-- Kind: patch
-- Intent: iam_pending_platform_profile_onboarding
-- Touches: iam.platform_user_profiles, iam.owner_activations, iam.create_tenant_onboarding, iam.accept_owner_activation, iam.search_platform_users, iam.get_platform_user

-- 1. Relax FK: a pending profile is materialised before its auth.users row exists.
--    user_id stays the PRIMARY KEY (a plain uuid); only the FK to auth.users is dropped.
alter table iam.platform_user_profiles
  drop constraint if exists platform_user_profiles_user_id_fkey;

-- 2. Canonical email on the profile — the queryable email source for pending users
--    (who have no auth.users row yet).
alter table iam.platform_user_profiles
  add column if not exists email text;

-- 3. Link an activation code to the pre-provisioned placeholder profile so accept
--    can reconcile the generated id onto the real auth id.
alter table iam.owner_activations
  add column if not exists provisioned_user_id uuid;

-- Rebase note (fix round 2): create_tenant_onboarding was rebased onto the 18-param
-- version from 20260820003_iam_tenant_onboarding_registered_address.sql (adds
-- p_org_registered_address_text). A stray 17-param overload was created by round 1
-- against the stale 20260811006 definition; drop it before creating the correct one.
drop function if exists iam.create_tenant_onboarding(
  uuid, text, text, text, boolean,
  text, text, text, text,
  text, text, text, text, text, text, text, text
);

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
  v_now timestamptz := now();
  v_raw_code text;
  v_code_hash text;
  v_ciphertext text;
  v_is_new boolean := coalesce(p_is_new_user, false);
  v_provisioned_user_id uuid;
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

  -- New owner: materialise a pending Platform User profile up-front so the person
  -- appears in the admin Platform Users list/detail before activation. The auth.users
  -- row is NOT created here; accept_owner_activation reconciles the generated id later.
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
        v_now,
        v_now
      );
    end if;
  end if;

  v_owner_email_masked :=
    left(v_owner_email, 1) || '***' ||
    substring(v_owner_email from position('@' in v_owner_email));

  v_raw_code := iam._generate_invitation_code();
  v_code_hash := iam._invitation_token_hash(v_raw_code);
  v_ciphertext := 'transient:' || encode(convert_to(v_raw_code, 'UTF8'), 'base64');

  insert into iam.owner_activations (
    tenant_id, invitee_email, given_name, family_name, phone, code_hash, expires_at,
    provisioned_user_id
  )
  values (
    v_tenant_id,
    v_owner_email,
    case when v_is_new then nullif(trim(coalesce(p_owner_given_name, '')), '') end,
    case when v_is_new then nullif(trim(coalesce(p_owner_family_name, '')), '') end,
    case when v_is_new then nullif(trim(coalesce(p_owner_phone, '')), '') end,
    v_code_hash,
    v_now + interval '7 days',
    coalesce(v_provisioned_user_id, p_owner_user_id)
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

create or replace function iam.accept_owner_activation(
  p_code text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_caller uuid := auth.uid();
  v_email text;
  v_row iam.owner_activations;
  v_hash text;
  v_membership_id text;
begin
  if v_caller is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  select lower(u.email::text) into v_email from auth.users u where u.id = v_caller;
  v_hash := encode(extensions.digest(upper(trim(coalesce(p_code, ''))), 'sha256'), 'hex');

  select * into v_row from iam.owner_activations where code_hash = v_hash for update;
  if not found then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  v_membership_id := v_row.tenant_id::text || ':' || v_caller::text;

  -- Idempotent replay.
  if v_row.status = 'accepted' then
    return jsonb_build_object('membership_id', v_membership_id, 'tenant_id', v_row.tenant_id);
  end if;
  if v_row.status = 'expired' or v_row.expires_at <= now() then
    update iam.owner_activations set status = 'expired' where id = v_row.id;
    raise exception 'INVITATION_EXPIRED';
  end if;
  if v_row.attempt_count >= 5 then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;
  if lower(coalesce(v_email, '')) <> lower(v_row.invitee_email) then
    update iam.owner_activations set attempt_count = attempt_count + 1 where id = v_row.id;
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  -- First owner of the provisioning tenant.
  if not exists (
    select 1 from iam.memberships m
    where m.tenant_id = v_row.tenant_id and m.user_id = v_caller and m.status = 'active'
  ) then
    -- Ownership is the is_owner flag, not a role; the first member gets the
    -- operational default role store_owner.
    insert into iam.memberships (tenant_id, user_id, role, is_owner, status)
    values (v_row.tenant_id, v_caller, 'store_owner', true, 'active');
  end if;

  -- Reconcile a pre-provisioned placeholder profile (created at onboarding with a
  -- generated id) onto the real auth id. GoTrue assigned v_caller at sign-up, which
  -- differs from the placeholder id; copy the placeholder's data across, then drop it.
  if v_row.provisioned_user_id is not null
     and v_row.provisioned_user_id <> v_caller then
    update iam.platform_user_profiles set status = 'active' where user_id = v_caller;
    if not found then
      -- Prefer the placeholder's captured data; fall back to a minimal row if the
      -- placeholder is missing, so activation never silently no-ops.
      insert into iam.platform_user_profiles (
        user_id, email, status, given_name, family_middle_name, phone_number,
        created_at, updated_at
      )
      select
        v_caller, ph.email, 'active', ph.given_name, ph.family_middle_name,
        ph.phone_number, ph.created_at, now()
      from iam.platform_user_profiles ph
      where ph.user_id = v_row.provisioned_user_id;
      if not found then
        insert into iam.platform_user_profiles (user_id, status)
        values (v_caller, 'active');
      end if;
    end if;

    delete from iam.platform_user_profiles
    where user_id = v_row.provisioned_user_id;
  else
    update iam.platform_user_profiles set status = 'active' where user_id = v_caller;
    if not found then
      insert into iam.platform_user_profiles (user_id, status)
      values (v_caller, 'active');
    end if;
  end if;

  -- Defensive cleanup: remove any leftover PENDING placeholder profiles for this
  -- email (orphans from mixed / legacy flows), so the admin list can't show a
  -- pending duplicate beside the now-active account. Only pending rows are touched;
  -- the caller's own (now active) row is never deleted.
  delete from iam.platform_user_profiles
  where status = 'pending_activation'
    and lower(email) = lower(v_row.invitee_email)
    and user_id <> v_caller;

  update iam.owner_activations
     set status = 'accepted', accepted_at = now()
   where id = v_row.id;

  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => v_row.tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'iam.owner.activated',
    p_subject_type => 'membership',
    p_subject_id => v_membership_id,
    p_result => 'success',
    p_source => 'auth',
    p_tracking_id => coalesce(p_idempotency_key, gen_random_uuid()::text)
  );

  return jsonb_build_object('membership_id', v_membership_id, 'tenant_id', v_row.tenant_id);
end;
$$;

revoke all on function iam.accept_owner_activation(text, text) from public, anon;
grant execute on function iam.accept_owner_activation(text, text) to authenticated;

-- Rebase note (fix round 2): get_platform_user / search_platform_users were rebased
-- onto 20260820002_iam_platform_user_suspend_state_changed_fix.sql, which orders the
-- name as family_middle_name, given_name (last, first) and treats a 'suspended'
-- profile status as authoritative over the auth-derived effective status. Both
-- behaviours are preserved below; the pending-user (full outer join + coalesce)
-- change is layered on top.
create or replace function iam.get_platform_user(p_user_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_row record;
  v_memberships jsonb;
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  select
    coalesce(u.id, p.user_id) as user_id,
    coalesce(
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
      nullif(trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')), ''),
      ''
    )::text as full_name,
    coalesce(u.email::text, p.email, '')::text as email,
    (case
      when p.status = 'suspended' then 'suspended'
      when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
      else coalesce(p.status, 'pending_activation')
    end)::text as status,
    (u.email_confirmed_at is not null) as email_verified,
    coalesce(p.created_at, u.created_at) as created_at,
    p.last_login_at,
    coalesce(p.version, 1) as version
  into v_row
  from iam.platform_user_profiles p
  full outer join auth.users u on u.id = p.user_id
  where coalesce(u.id, p.user_id) = p_user_id;

  if v_row.user_id is null then
    raise exception 'platform user not found';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'tenant_id', t.id,
        'tenant_name', t.name,
        'role', m.role,
        'is_owner', m.is_owner
      )
      order by m.created_at
    ),
    '[]'::jsonb
  )
  into v_memberships
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = p_user_id;

  return jsonb_build_object(
    'user_id', v_row.user_id,
    'full_name', v_row.full_name,
    'email', v_row.email,
    'status', v_row.status,
    'email_verified', v_row.email_verified,
    'created_at', v_row.created_at,
    'last_login_at', v_row.last_login_at,
    'memberships', v_memberships,
    'version', v_row.version
  );
end;
$$;

revoke all on function iam.get_platform_user(uuid) from public, anon;
grant execute on function iam.get_platform_user(uuid) to authenticated;

create or replace function iam.search_platform_users(
  p_query text default null,
  p_status text default null,
  p_cursor text default null,
  p_page_size integer default 20
)
returns jsonb
language plpgsql
security definer
set search_path = iam, auth, pg_temp
as $$
declare
  v_limit int := least(greatest(coalesce(p_page_size, 20), 1), 100);
begin
  if not iam.has_platform_permission('platform.user.view') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;
  return jsonb_build_object(
    'items', coalesce((
      select jsonb_agg(row_to_json(t)::jsonb)
      from (
        select
          coalesce(u.id, p.user_id) as user_id,
          coalesce(
            nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
            nullif(
              trim(concat_ws(' ', u.raw_user_meta_data->>'last_name', u.raw_user_meta_data->>'first_name')),
              ''
            ),
            ''
          )::text as full_name,
          coalesce(u.email::text, p.email, '')::text as email,
          (case
            when p.status = 'suspended' then 'suspended'
            when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
            else coalesce(p.status, 'pending_activation')
          end)::text as status,
          coalesce(p.created_at, u.created_at) as created_at,
          coalesce(p.version, 1) as version
        from iam.platform_user_profiles p
        full outer join auth.users u on u.id = p.user_id
        where (
            p_status is null
            or (case
                  when p.status = 'suspended' then 'suspended'
                  when u.id is not null then iam._platform_user_effective_status(u.email_confirmed_at)
                  else coalesce(p.status, 'pending_activation')
                end) = p_status
          )
          and (
            p_query is null or p_query = ''
            or coalesce(u.email, p.email) ilike '%' || p_query || '%'
            or coalesce(p.given_name, '') ilike '%' || p_query || '%'
            or coalesce(p.family_middle_name, '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'first_name', '') ilike '%' || p_query || '%'
            or coalesce(u.raw_user_meta_data->>'last_name', '') ilike '%' || p_query || '%'
          )
          -- Durable de-dup guard: a pending placeholder carries a generated id that
          -- differs from the real auth id, so when the person activates (via accept,
          -- login audit, or any path) their active row appears under the auth id and
          -- the placeholder can linger as an orphan. Hide such an orphan — a
          -- profile-only pending row (no auth row of its own) whose email already has
          -- a real auth account — so the list can never show the person twice,
          -- regardless of which write path created the active row.
          and not (
            u.id is null
            and p.status = 'pending_activation'
            and p.email is not null
            and exists (
              select 1 from auth.users au
              where lower(au.email::text) = lower(p.email)
            )
          )
        order by coalesce(p.created_at, u.created_at) desc
        limit v_limit
      ) t
    ), '[]'::jsonb),
    'next_cursor', null
  );
end;
$$;

revoke all on function iam.search_platform_users(text, text, text, integer) from public, anon;
grant execute on function iam.search_platform_users(text, text, text, integer) to authenticated;

-- Path-independent orphan cleanup: whenever a real auth account is created, drop any
-- pending onboarding placeholder for the same email. The placeholder carries a
-- generated id (different from the auth id), and the profile is later activated by
-- multiple paths (accept_invitation, accept_owner_activation, login audit) — only some
-- of which know the placeholder. This trigger fires regardless of the activation path,
-- so the person can never end up as two rows.
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
  delete from iam.platform_user_profiles p
  where p.status = 'pending_activation'
    and p.email is not null
    and lower(p.email) = lower(new.email::text)
    and p.user_id <> new.id;
  return new;
end;
$$;

drop trigger if exists trg_cleanup_pending_profile on auth.users;
create trigger trg_cleanup_pending_profile
  after insert on auth.users
  for each row
  execute function iam._cleanup_pending_profile_on_auth_user();

-- Enforce at most one PENDING placeholder profile per email — a DB-level guard
-- against races / mixed data creating duplicate pending rows. Placed LAST so that,
-- if the DB still holds duplicate pending emails from earlier tests, this index
-- fails WITHOUT aborting the function (re)definitions above. Dedupe pending rows,
-- then this succeeds. NULL emails do not conflict (Postgres unique ignores NULLs).
create unique index if not exists platform_user_profiles_pending_email_uidx
  on iam.platform_user_profiles (lower(email))
  where status = 'pending_activation';
