-- Title: iam tenant invitation acceptance (S8 / EP-03 US-03)
-- Kind: patch
-- Intent: iam_tenant_invitation_acceptance
-- Context: TH-01 §S8 Inspect / Accept / Decline invitation token
-- Touches: iam.inspect_invitation_token, iam.accept_invitation, iam.decline_invitation
-- Safety: idempotent ; medium
-- Depends on: iam.tenant_invitations, iam.role_definitions, iam.memberships, iam.tenants,
--             iam.append_audit_log, iam.get_auth_user_snapshot, auth.users
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Actor email for accept is resolved from auth.uid() — never from client input.
--        Invalid token raises INVITATION_TOKEN_INVALID without account leak fields.

create extension if not exists pgcrypto;

-- Token-scoped idempotency (accept/decline) keyed by token_hash + operation.
create table if not exists iam.tenant_invitation_token_operations (
  token_hash text not null,
  operation text not null check (operation in ('accept', 'decline')),
  idempotency_key text not null,
  payload_hash text not null,
  result jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (token_hash, operation, idempotency_key)
);

create or replace function iam._invitation_token_hash(p_token text)
returns text
language sql
immutable
as $$
  select encode(digest(trim(p_token), 'sha256'), 'hex');
$$;

create or replace function iam._load_invitation_by_token(p_token text)
returns iam.tenant_invitations
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_hash text;
  v_row iam.tenant_invitations;
begin
  if p_token is null or trim(p_token) = '' then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  v_hash := iam._invitation_token_hash(p_token);

  select * into v_row
  from iam.tenant_invitations i
  where i.token_hash = v_hash
  for update;

  if not found then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  return v_row;
end;
$$;

-- ── inspect_invitation_token ────────────────────────────────────────────────

create or replace function iam.inspect_invitation_token(p_token text)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_tenant iam.tenants;
  v_account_exists boolean := false;
  v_now timestamptz := timezone('utc', now());
begin
  begin
    v_inv := iam._load_invitation_by_token(p_token);
  exception
    when others then
      if sqlerrm like 'INVITATION_TOKEN_INVALID%' then
        raise exception 'INVITATION_TOKEN_INVALID';
      end if;
      raise;
  end;

  -- Terminal / expiry checks — still no accountExists on invalid path above.
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

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id;
  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  select exists (
    select 1 from auth.users u
    where lower(trim(u.email::text)) = v_inv.invitee_email
  ) into v_account_exists;

  return jsonb_build_object(
    'tenant_id', v_inv.tenant_id,
    'tenant_name', coalesce(v_tenant.name, ''),
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', v_inv.initial_role_id,
    'initial_role_label', coalesce(v_role.label, ''),
    'expires_at', v_inv.expires_at,
    'account_exists', v_account_exists
  );
end;
$$;

-- ── accept_invitation ───────────────────────────────────────────────────────

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
  v_tenant iam.tenants;
  v_role iam.role_definitions;
  v_hash text;
  v_email text;
  v_payload_hash text;
  v_existing iam.tenant_invitation_token_operations;
  v_membership iam.memberships;
  v_now timestamptz := timezone('utc', now());
  v_result jsonb;
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

  v_inv := iam._load_invitation_by_token(p_token);

  select * into v_tenant from iam.tenants t where t.id = v_inv.tenant_id for update;
  if not found then
    raise exception 'INVITATION_TOKEN_INVALID';
  end if;

  -- Suspended tenant: do not consume token.
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
    coalesce(v_role.code, 'staff'),
    'active',
    false,
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
    -- rotate hash so old token cannot be reused
    token_hash = encode(digest(gen_random_bytes(32), 'sha256'), 'hex')
  where id = v_inv.id
  returning * into v_inv;

  v_result := iam._membership_detail_json(v_membership);

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => v_inv.tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.accepted',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'membership_id', v_membership.id,
      'invitation_id', v_inv.id
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

-- ── decline_invitation ──────────────────────────────────────────────────────

create or replace function iam.decline_invitation(
  p_token text,
  p_idempotency_key text
)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_inv iam.tenant_invitations;
  v_role iam.role_definitions;
  v_hash text;
  v_payload_hash text;
  v_existing iam.tenant_invitation_token_operations;
  v_now timestamptz := timezone('utc', now());
  v_result jsonb;
  v_delivery_status text;
begin
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  v_hash := iam._invitation_token_hash(p_token);
  v_payload_hash := md5(v_hash || '|decline');

  select * into v_existing
  from iam.tenant_invitation_token_operations o
  where o.token_hash = v_hash
    and o.operation = 'decline'
    and o.idempotency_key = p_idempotency_key;

  if found then
    if v_existing.payload_hash <> v_payload_hash then
      raise exception 'IDEMPOTENCY_CONFLICT';
    end if;
    return v_existing.result;
  end if;

  v_inv := iam._load_invitation_by_token(p_token);

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

  update iam.tenant_invitations
  set
    status = 'declined',
    status_changed_at = v_now,
    version = version + 1,
    updated_at = v_now,
    token_hash = encode(digest(gen_random_bytes(32), 'sha256'), 'hex')
  where id = v_inv.id
  returning * into v_inv;

  select * into v_role from iam.role_definitions r where r.id = v_inv.initial_role_id;

  select o.status
  into v_delivery_status
  from iam.email_delivery_outcomes o
  where o.correlation_id = coalesce(v_inv.delivery_correlation_id, '')
  limit 1;

  v_result := jsonb_build_object(
    'invitation_id', v_inv.id,
    'invitee_email', v_inv.invitee_email,
    'initial_role_id', v_inv.initial_role_id,
    'initial_role_label', coalesce(v_role.label, ''),
    'status', v_inv.status,
    'expires_at', v_inv.expires_at,
    'delivery_status', coalesce(v_delivery_status, 'unknown'),
    'delivery_correlation_id', coalesce(v_inv.delivery_correlation_id, ''),
    'version', v_inv.version,
    'created_at', v_inv.created_at,
    'created_by', '',
    'last_sent_at', v_inv.last_sent_at,
    'revoked_at', null,
    'declined_at', v_now
  );

  insert into iam.tenant_invitation_token_operations (
    token_hash, operation, idempotency_key, payload_hash, result
  ) values (
    v_hash, 'decline', p_idempotency_key, v_payload_hash, v_result
  );

  return v_result;
end;
$$;

revoke all on function iam.inspect_invitation_token(text) from public, anon;
grant execute on function iam.inspect_invitation_token(text) to anon, authenticated;

revoke all on function iam.accept_invitation(text, text) from public, anon;
grant execute on function iam.accept_invitation(text, text) to authenticated;

revoke all on function iam.decline_invitation(text, text) from public, anon;
grant execute on function iam.decline_invitation(text, text) to anon, authenticated;
