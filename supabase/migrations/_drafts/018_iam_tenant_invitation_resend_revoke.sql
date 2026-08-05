-- Title: iam tenant invitation resend / revoke (S9 / EP-03 US-04)
-- Kind: patch
-- Intent: iam_tenant_invitation_resend_revoke
-- Context: TH-01 §S9 ResendInvitationCommand / RevokeInvitationCommand
-- Touches: iam.resend_tenant_invitation, iam.revoke_tenant_invitation,
--          iam.is_current_tenant_invitation_delivery
-- Safety: idempotent ; medium
-- Depends on: iam.tenant_invitations, iam.role_definitions, iam.has_permission,
--             iam.enqueue_outbox_message, iam.record_email_delivery_outcome, iam.append_audit_log
-- Notes: Draft only — do not apply via supabase migration up until promoted.
--        Resend rotates token_hash + 7-day expiry and enqueues email.
--        Revoke never enqueues email; reason persisted in audit after_state.

alter table iam.tenant_invitations
  add column if not exists revoke_reason text,
  add column if not exists delivery_correlation_id text,
  add column if not exists last_sent_at timestamptz;

create table if not exists iam.tenant_invitation_mutate_operations (
  tenant_id uuid not null,
  invitation_id uuid not null,
  operation text not null check (operation in ('resend', 'revoke')),
  idempotency_key text not null,
  payload_hash text not null,
  result jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (tenant_id, invitation_id, operation, idempotency_key)
);

create or replace function iam.is_current_tenant_invitation_delivery(
  p_invitation_id uuid,
  p_correlation_id text
)
returns boolean
language sql
stable
security definer
set search_path = iam, pg_temp
as $$
  select exists (
    select 1
    from iam.tenant_invitations i
    where i.id = p_invitation_id
      and i.delivery_correlation_id = p_correlation_id
      and i.status = 'pending'
  );
$$;

drop function if exists iam._invitation_detail_json(
  iam.tenant_invitations,
  text,
  text,
  text,
  text,
  timestamptz,
  timestamptz
);

create or replace function iam._invitation_detail_json(
  p_inv iam.tenant_invitations,
  p_role_label text,
  p_created_by text,
  p_revoked_at timestamptz default null,
  p_declined_at timestamptz default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = iam, pg_temp
as $$
declare
  v_corr text := coalesce((p_inv).delivery_correlation_id, '');
  v_delivery_status text := 'unknown';
begin
  if v_corr <> '' then
    select o.status
    into v_delivery_status
    from iam.email_delivery_outcomes o
    where o.correlation_id = v_corr
    limit 1;
    if not found then
      v_delivery_status := 'unknown';
    end if;
  end if;

  return jsonb_build_object(
    'invitation_id', (p_inv).id,
    'invitee_email', (p_inv).invitee_email,
    'initial_role_id', (p_inv).initial_role_id,
    'initial_role_label', coalesce(p_role_label, ''),
    'status', (p_inv).status,
    'expires_at', (p_inv).expires_at,
    'delivery_status', coalesce(v_delivery_status, 'unknown'),
    'delivery_correlation_id', v_corr,
    'version', (p_inv).version,
    'created_at', (p_inv).created_at,
    'created_by', coalesce(p_created_by, ''),
    'last_sent_at', (p_inv).last_sent_at,
    'revoked_at', coalesce(
      p_revoked_at,
      case when (p_inv).status = 'revoked' then (p_inv).status_changed_at end
    ),
    'declined_at', coalesce(
      p_declined_at,
      case when (p_inv).status = 'declined' then (p_inv).status_changed_at end
    )
  );
end;
$$;

-- ── resend_tenant_invitation ────────────────────────────────────────────────

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
  v_now timestamptz := timezone('utc', now());
  v_message_id uuid := gen_random_uuid();
  v_correlation_id text := gen_random_uuid()::text;
  v_outcome_id uuid := gen_random_uuid();
  v_masked text;
  v_result jsonb;
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
    p_event_code => 'tenant.invitation.resent',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
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

-- ── revoke_tenant_invitation ────────────────────────────────────────────────

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
  v_now timestamptz := timezone('utc', now());
  v_result jsonb;
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

  -- Intentionally no enqueue_outbox_message on revoke.

  perform iam.append_audit_log(
    p_scope => 'tenant',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_caller,
    p_event_code => 'tenant.invitation.revoked',
    p_subject_type => 'invitation',
    p_subject_id => v_inv.id::text,
    p_result => 'success',
    p_source => 'iam',
    p_tracking_id => p_idempotency_key,
    p_before => null,
    p_after => jsonb_build_object(
      'invitation_id', v_inv.id,
      'version', v_inv.version,
      'revoke_reason', v_reason
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

revoke all on function iam.resend_tenant_invitation(uuid, uuid, int, text)
  from public, anon;
grant execute on function iam.resend_tenant_invitation(uuid, uuid, int, text)
  to authenticated;

revoke all on function iam.revoke_tenant_invitation(uuid, uuid, int, text, text)
  from public, anon;
grant execute on function iam.revoke_tenant_invitation(uuid, uuid, int, text, text)
  to authenticated;

revoke all on function iam.is_current_tenant_invitation_delivery(uuid, text)
  from public, anon;
grant execute on function iam.is_current_tenant_invitation_delivery(uuid, text)
  to authenticated;
