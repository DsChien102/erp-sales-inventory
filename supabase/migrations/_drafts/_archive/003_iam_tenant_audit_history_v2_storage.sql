-- Title: IAM tenant audit history V2 storage
-- Kind: patch
-- Intent: iam_tenant_audit_history_v2
-- Touches: iam._audit_redact, iam._audit_event_category, iam._build_audit_actor_snapshot, iam._build_audit_subject_snapshot, iam.append_audit_log

-- 1. Schema evolution on canonical iam.audit_logs table
alter table iam.audit_logs
  add column if not exists event_category text,
  add column if not exists subject_snapshot jsonb,
  add column if not exists search_document text;

-- 2. Category check constraint
alter table iam.audit_logs
  drop constraint if exists check_iam_audit_logs_event_category;

alter table iam.audit_logs
  add constraint check_iam_audit_logs_event_category
  check (event_category is null or event_category in ('member', 'role', 'organization', 'invitation', 'account', 'security', 'system'));

-- 3. Deterministic backfill of event_category for known legacy rows (never backfill snapshots)
update iam.audit_logs
set event_category = case event_code
  when 'iam.membership.deactivated' then 'member'
  when 'iam.membership.reactivated' then 'member'
  when 'iam.membership.removed' then 'member'
  when 'iam.tenant.member_role_assigned' then 'role'
  when 'iam.membership.role_changed' then 'role'
  when 'iam.tenant.profile_updated' then 'organization'
  when 'iam.tenant.legal_profile_updated' then 'organization'
  when 'iam.tenant.activated' then 'organization'
  when 'iam.tenant.suspended' then 'organization'
  when 'iam.tenant.restored' then 'organization'
  when 'iam.tenant.ownership_transferred' then 'organization'
  when 'iam.tenant.owner_activated' then 'member'
  when 'iam.owner.activated' then 'member'
  when 'iam.tenant.invitation_created' then 'invitation'
  when 'tenant.invitation.created' then 'invitation'
  when 'iam.tenant.invitation_resent' then 'invitation'
  when 'tenant.invitation.resent' then 'invitation'
  when 'iam.tenant.invitation_revoked' then 'invitation'
  when 'tenant.invitation.revoked' then 'invitation'
  when 'iam.tenant.invitation_accepted' then 'invitation'
  when 'tenant.invitation.accepted' then 'invitation'
  when 'iam.account.profile_updated' then 'account'
  when 'iam.user.profile_updated' then 'account'
  when 'iam.account.password_reset_completed' then 'security'
  when 'iam.account.signed_out' then 'security'
  else event_category
end
where event_category is null;

-- 4. Trigram GIN index for free-text search
create index if not exists idx_iam_audit_logs_search_document
  on iam.audit_logs
  using gin (search_document extensions.gin_trgm_ops);

-- 5. Helper: recursively redact credential-like payload keys before persistence
create or replace function iam._audit_redact(p jsonb)
returns jsonb
language plpgsql
immutable
as $$
declare
  v_result jsonb := '{}'::jsonb;
  v_key text;
  v_val jsonb;
  v_normalized_key text;
begin
  if p is null then
    return null;
  end if;

  if jsonb_typeof(p) = 'array' then
    return (
      select coalesce(jsonb_agg(iam._audit_redact(v)), '[]'::jsonb)
      from jsonb_array_elements(p) as items(v)
    );
  end if;

  if jsonb_typeof(p) <> 'object' then
    return p;
  end if;

  for v_key, v_val in select key, value from jsonb_each(p)
  loop
    v_normalized_key := regexp_replace(lower(v_key), '[-_]', '', 'g');
    if v_normalized_key like '%credential%'
      or v_normalized_key like '%clientsecret%'
      or v_normalized_key like '%passwordhash%'
      or v_normalized_key like '%apikey%'
      or v_normalized_key like '%privatekey%'
      or v_normalized_key like '%cookie%'
      or v_normalized_key like '%bearer%'
      or v_normalized_key like '%secretpayloadciphertext%'
      or v_normalized_key like '%tokenhash%'
      or v_normalized_key like '%token%'
      or v_normalized_key like '%password%'
      or v_normalized_key like '%secret%'
      or v_normalized_key like '%otp%'
      or v_normalized_key like '%verificationcode%'
      or v_normalized_key like '%recoverycode%'
      or v_normalized_key like '%nonce%'
      or v_normalized_key like '%session%'
      or v_normalized_key like '%ciphertext%'
      or v_normalized_key in ('code') then
      v_result := v_result || jsonb_build_object(v_key, '[REDACTED]');
    else
      v_result := v_result || jsonb_build_object(v_key, iam._audit_redact(v_val));
    end if;
  end loop;

  return v_result;
end;
$$;

revoke all on function iam._audit_redact(jsonb) from public, anon, authenticated;

-- 6. Helper: resolve registered event category
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
         'iam.owner.activated' then
      return 'member';

    when 'iam.tenant.member_role_assigned',
         'iam.membership.role_changed' then
      return 'role';

    when 'iam.tenant.profile_updated',
         'iam.tenant.legal_profile_updated',
         'iam.tenant.activated',
         'iam.tenant.suspended',
         'iam.tenant.restored',
         'iam.tenant.ownership_transferred' then
      return 'organization';

    when 'iam.tenant.invitation_created',
         'tenant.invitation.created',
         'iam.tenant.invitation_resent',
         'tenant.invitation.resent',
         'iam.tenant.invitation_revoked',
         'tenant.invitation.revoked',
         'iam.tenant.invitation_accepted',
         'tenant.invitation.accepted' then
      return 'invitation';

    when 'iam.account.profile_updated',
         'iam.user.profile_updated' then
      return 'account';

    when 'iam.account.password_reset_completed',
         'iam.account.signed_out' then
      return 'security';

    else
      raise exception 'AUDIT_EVENT_UNREGISTERED:%', p_event_code;
  end case;
end;
$$;

revoke all on function iam._audit_event_category(text) from public, anon, authenticated;

-- 7. Helper: build versioned actor snapshot
create or replace function iam._build_audit_actor_snapshot(
  p_tenant_id uuid,
  p_actor_user_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = iam, public
as $$
declare
  v_display_name text;
  v_actor_type text := 'user';
  v_role_code text;
  v_role_label text;
begin
  if p_actor_user_id is null then
    return jsonb_build_object(
      'schema_version', 1,
      'display_name', 'Hệ thống',
      'actor_type', 'system',
      'role_code', null,
      'role_label', null
    );
  end if;

  -- Canonical IAM-owned identity display name. Raw auth metadata is never used.
  select
    nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
    case when pa.user_id is not null then 'platform_operator' else 'user' end,
    case when pa.user_id is not null then 'platform_admin' else null end,
    case when pa.user_id is not null then 'Quản trị nền tảng' else null end
  into v_display_name, v_actor_type, v_role_code, v_role_label
  from iam.platform_user_profiles p
  left join iam.platform_admins pa on pa.user_id = p.user_id
  where p.user_id = p_actor_user_id;

  if v_display_name is null then
    return null;
  end if;

  -- Tenant membership role
  if v_actor_type <> 'platform_operator' and p_tenant_id is not null then
    select m.role, coalesce(rd.label, m.role)
    into v_role_code, v_role_label
    from iam.memberships m
    left join iam.role_definitions rd on rd.code = m.role
    where m.tenant_id = p_tenant_id
      and m.user_id = p_actor_user_id
      and m.status in ('active', 'inactive')
    order by
      case m.status when 'active' then 0 else 1 end,
      m.updated_at desc,
      m.created_at desc,
      m.id desc
    limit 1;

  end if;

  return jsonb_build_object(
    'schema_version', 1,
    'display_name', v_display_name,
    'actor_type', v_actor_type,
    'role_code', v_role_code,
    'role_label', v_role_label
  );
end;
$$;

revoke all on function iam._build_audit_actor_snapshot(uuid, uuid) from public, anon, authenticated;

-- 8. Helper: build versioned subject snapshot
create or replace function iam._build_audit_subject_snapshot(
  p_tenant_id uuid,
  p_subject_type text,
  p_subject_id text
)
returns jsonb
language plpgsql
stable
security definer
set search_path = iam, public
as $$
declare
  v_display_name text;
  v_code text;
  v_secondary_label text;
  v_uuid uuid;
begin
  if p_subject_id is null then
    return null;
  end if;

  -- Safe uuid parsing
  begin
    v_uuid := p_subject_id::uuid;
  exception when others then
    v_uuid := null;
  end;

  if p_subject_type in ('tenant', 'organization') and v_uuid is not null then
    select
      coalesce(t.display_name, t.name, t.code),
      t.code
    into v_display_name, v_code
    from iam.tenants t
    where t.id = v_uuid
      and t.id = p_tenant_id;

  elsif p_subject_type in ('membership', 'member') and v_uuid is not null then
    select
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
      m.role,
      coalesce(rd.label, m.role)
    into v_display_name, v_code, v_secondary_label
    from iam.memberships m
    left join iam.platform_user_profiles p on p.user_id = m.user_id
    left join iam.role_definitions rd on rd.code = m.role
    where m.id = v_uuid
      and m.tenant_id = p_tenant_id;

  elsif p_subject_type in ('invitation') and v_uuid is not null then
    select
      case
        when i.invitee_email like '%@%' then
          left(i.invitee_email, 1) || '***@' || split_part(i.invitee_email, '@', 2)
        else '***'
      end,
      rd.code,
      rd.label
    into v_display_name, v_code, v_secondary_label
    from iam.tenant_invitations i
    left join iam.role_definitions rd on rd.id = i.initial_role_id
    where i.id = v_uuid
      and i.tenant_id = p_tenant_id;

  elsif p_subject_type in ('user', 'account') and v_uuid is not null then
    select
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), '')
    into v_display_name
    from iam.platform_user_profiles p
    where p.user_id = v_uuid
      and (
        p_tenant_id is null
        or exists (
          select 1
          from iam.memberships um
          where um.tenant_id = p_tenant_id
            and um.user_id = p.user_id
        )
      );
  elsif p_subject_type = 'legal_profile' and v_uuid is not null then
    select
      lp.legal_name,
      lp.tax_code,
      lp.legal_entity_type
    into v_display_name, v_code, v_secondary_label
    from iam.tenant_legal_profiles lp
    where lp.tenant_id = v_uuid
      and lp.tenant_id = p_tenant_id;

  elsif p_subject_type = 'role' then
    select
      rd.label,
      rd.code,
      rd.status
    into v_display_name, v_code, v_secondary_label
    from iam.role_definitions rd
    where rd.id::text = p_subject_id
       or rd.code = p_subject_id
    limit 1;
  end if;

  if v_display_name is null then
    return null;
  end if;

  return jsonb_build_object(
    'schema_version', 1,
    'display_name', v_display_name,
    'subject_code', v_code,
    'secondary_label', v_secondary_label
  );
end;
$$;

revoke all on function iam._build_audit_subject_snapshot(uuid, text, text) from public, anon, authenticated;

-- 8. Replace append_audit_log body with V2 snapshots and search document builder
create or replace function iam.append_audit_log(
  p_scope text,
  p_tenant_id uuid,
  p_actor_user_id uuid,
  p_event_code text,
  p_subject_type text,
  p_subject_id text,
  p_result text,
  p_source text,
  p_tracking_id text,
  p_before jsonb default null,
  p_after jsonb default null,
  p_redaction_flags text[] default '{}'::text[]
)
returns uuid
language plpgsql
security definer
set search_path = iam, public
as $$
declare
  v_id uuid;
  v_category text;
  v_actor_snapshot jsonb;
  v_subject_snapshot jsonb;
  v_email_pattern constant text := '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}';
  v_phone_pattern constant text := '\+?[0-9][0-9 ().-]{7,}[0-9]';
  v_safe_subject_id text;
  v_safe_tracking_id text;
  v_search_document text;
begin
  if p_scope = 'tenant' and p_tenant_id is null then
    raise exception 'TENANT_ID_REQUIRED_FOR_TENANT_SCOPE';
  end if;

  v_category := iam._audit_event_category(p_event_code);
  v_actor_snapshot := iam._build_audit_actor_snapshot(p_tenant_id, p_actor_user_id);
  v_subject_snapshot := iam._build_audit_subject_snapshot(p_tenant_id, p_subject_type, p_subject_id);
  v_safe_subject_id := regexp_replace(regexp_replace(p_subject_id, v_email_pattern, '***', 'gi'), v_phone_pattern, '***', 'g');
  v_safe_tracking_id := regexp_replace(regexp_replace(p_tracking_id, v_email_pattern, '***', 'gi'), v_phone_pattern, '***', 'g');

  v_search_document := lower(
    concat_ws(
      ' ',
      p_event_code,
      v_category,
      p_subject_type,
      v_safe_subject_id,
      v_safe_tracking_id,
      v_actor_snapshot->>'display_name',
      v_subject_snapshot->>'display_name',
      v_subject_snapshot->>'subject_code'
    )
  );

  insert into iam.audit_logs (
    scope,
    tenant_id,
    actor_user_id,
    actor_snapshot,
    event_code,
    event_category,
    subject_type,
    subject_id,
    subject_snapshot,
    search_document,
    result,
    source,
    tracking_id,
    before_state,
    after_state,
    redaction_flags,
    occurred_at
  ) values (
    p_scope,
    p_tenant_id,
    p_actor_user_id,
    v_actor_snapshot,
    p_event_code,
    v_category,
    p_subject_type,
    p_subject_id,
    v_subject_snapshot,
    v_search_document,
    p_result,
    p_source,
    p_tracking_id,
    iam._audit_redact(p_before),
    iam._audit_redact(p_after),
    coalesce(p_redaction_flags, '{}'::text[]),
    now()
  )
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function iam.append_audit_log(text, uuid, uuid, text, text, text, text, text, text, jsonb, jsonb, text[]) from public, anon, authenticated;
