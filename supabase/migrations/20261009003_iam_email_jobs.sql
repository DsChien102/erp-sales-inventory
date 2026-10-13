-- Title: iam email jobs replace outbox email delivery
-- Kind: patch
-- Intent: iam_email_jobs
-- Context: TH-01 6.3, BR-64, KI-07
-- Touches: iam.email_jobs, iam.enqueue_outbox_message, iam._email_template_data,
--          iam.claim_email_job, iam.complete_email_job
-- Safety: idempotent ; medium
-- Depends on: 20260623000002_install_module_messaging_modules.sql,
--             20260811001_iam_notify_email_delivery_outcome.sql,
--             20260811017_iam_tenant_invitation_create.sql
-- Note (3-B, 2026-10-11): iam.enqueue_outbox_message is intentionally redefined here instead of being merged
--   into 20260623000001: the original is generated with format() for every schema, so a separate iam
--   version there would be more complex than this override.

create table if not exists iam.email_jobs (
  id uuid primary key,
  tenant_id uuid,
  template_id text not null,
  to_email text not null,
  locale text not null default 'vi',
  correlation_id text not null,
  refs jsonb not null default '{}'::jsonb,
  template_data jsonb not null default '{}'::jsonb,
  secret jsonb,
  status text not null default 'queued'
    check (status in ('queued', 'sending', 'sent', 'failed')),
  attempts int not null default 0,
  last_error text,
  provider_message_id text,
  claimed_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table iam.email_jobs enable row level security;

create index if not exists email_jobs_retryable_idx
  on iam.email_jobs (status, created_at)
  where status in ('queued', 'failed');

grant usage on schema iam to service_role;

-- Template fields for the email body. Unknown templates and missing rows
-- return {} so an old RPC (activation_invitation) still commits.
create or replace function iam._email_template_data(
  p_template_id text,
  p_refs jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = iam, pg_temp
as $$
declare
  v_refs jsonb := coalesce(p_refs, '{}'::jsonb);
  v_invitation_id uuid;
  v_data jsonb;
begin
  if p_template_id = 'password_reset_code' then
    return jsonb_build_object('expires_in_minutes', 10);
  end if;

  if p_template_id is distinct from 'tenant_invitation' then
    return '{}'::jsonb;
  end if;

  if jsonb_typeof(v_refs) is distinct from 'object' then
    return '{}'::jsonb;
  end if;

  begin
    v_invitation_id := nullif(v_refs->>'invitation_id', '')::uuid;
  exception
    when others then
      return '{}'::jsonb;
  end;

  if v_invitation_id is null then
    return '{}'::jsonb;
  end if;

  select jsonb_build_object(
    'tenant_name', t.display_name,
    'role_label', r.label,
    'inviter_name', nullif(
      trim(both from concat_ws(
        ' ',
        nullif(trim(both from p.family_middle_name), ''),
        nullif(trim(both from p.given_name), '')
      )),
      ''
    ),
    'expires_at', i.expires_at
  )
  into v_data
  from iam.tenant_invitations i
  left join iam.tenants t on t.id = i.tenant_id
  left join iam.role_definitions r on r.id = i.initial_role_id
  left join iam.memberships m on m.id = i.invited_by_membership_id
  left join iam.platform_user_profiles p on p.user_id = m.user_id
  where i.id = v_invitation_id;

  return coalesce(v_data, '{}'::jsonb);
end;
$$;

-- Same signature as platform.install_module_messaging. Email events go to
-- iam.email_jobs (BR-64: the code is not stored in outbox_messages). Every
-- other event keeps the original outbox insert.
create or replace function iam.enqueue_outbox_message(
  p_tenant_id uuid,
  p_event_type text,
  p_payload jsonb,
  p_message_id uuid default gen_random_uuid(),
  p_occurred_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = iam, platform, pg_temp
as $$
declare
  v_ciphertext text;
  v_code text;
  v_template_id text;
  v_refs jsonb;
  v_tenant_id uuid;
  v_template_data jsonb;
begin
  if p_event_type is distinct from 'iam.email.delivery_requested' then
    insert into outbox_messages (
      id, tenant_id, event_type, payload, occurred_at
    )
    values (
      p_message_id, p_tenant_id, p_event_type, p_payload, p_occurred_at
    );
    return p_message_id;
  end if;

  v_ciphertext := p_payload->>'secret_payload_ciphertext';
  if v_ciphertext is null or v_ciphertext not like 'transient:%' then
    raise exception 'VALIDATION_ERROR: email secret';
  end if;

  begin
    v_code := convert_from(
      decode(substring(v_ciphertext from 11), 'base64'),
      'UTF8'
    );
  exception
    when others then
      raise exception 'VALIDATION_ERROR: email secret';
  end;

  v_code := nullif(trim(both from v_code), '');
  if v_code is null then
    raise exception 'VALIDATION_ERROR: email secret';
  end if;

  v_template_id := nullif(trim(both from p_payload->>'template_id'), '');
  if v_template_id is null
     or nullif(trim(both from p_payload->>'to_email'), '') is null
     or nullif(trim(both from p_payload->>'correlation_id'), '') is null then
    raise exception 'VALIDATION_ERROR: email secret';
  end if;

  begin
    v_tenant_id := nullif(p_payload->>'tenant_id', '')::uuid;
  exception
    when others then
      v_tenant_id := null;
  end;

  v_refs := p_payload->'refs';
  if v_refs is null or jsonb_typeof(v_refs) is distinct from 'object' then
    v_refs := '{}'::jsonb;
  end if;

  begin
    v_template_data := iam._email_template_data(v_template_id, v_refs);
  exception
    when others then
      v_template_data := '{}'::jsonb;
  end;

  insert into iam.email_jobs (
    id,
    tenant_id,
    template_id,
    to_email,
    locale,
    correlation_id,
    refs,
    template_data,
    secret
  )
  values (
    p_message_id,
    v_tenant_id,
    v_template_id,
    trim(both from p_payload->>'to_email'),
    coalesce(nullif(trim(both from p_payload->>'locale'), ''), 'vi'),
    trim(both from p_payload->>'correlation_id'),
    v_refs,
    coalesce(v_template_data, '{}'::jsonb),
    jsonb_build_object('code', v_code)
  );

  return p_message_id;
end;
$$;

create or replace function iam.claim_email_job(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_job iam.email_jobs;
begin
  update iam.email_jobs
  set
    status = 'sending',
    claimed_at = now(),
    attempts = attempts + 1,
    updated_at = now()
  where id = p_job_id
    and (
      status in ('queued', 'failed')
      or (
        status = 'sending'
        and claimed_at < now() - interval '5 minutes'
      )
    )
    and attempts < 5
    and secret is not null
  returning * into v_job;

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'id', v_job.id,
    'template_id', v_job.template_id,
    'to_email', v_job.to_email,
    'locale', v_job.locale,
    'template_data', v_job.template_data,
    'code', v_job.secret->>'code'
  );
end;
$$;

create or replace function iam.complete_email_job(
  p_job_id uuid,
  p_ok boolean,
  p_provider_message_id text,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_job iam.email_jobs;
  v_attempts int;
  v_outcome text;
begin
  select * into v_job
  from iam.email_jobs
  where id = p_job_id
  for update;

  if not found then
    return;
  end if;

  if coalesce(p_ok, false) then
    update iam.email_jobs
    set
      status = 'sent',
      sent_at = now(),
      secret = null,
      provider_message_id = p_provider_message_id,
      last_error = null,
      updated_at = now()
    where id = p_job_id;
    v_outcome := 'sent';
  else
    update iam.email_jobs
    set
      status = 'failed',
      attempts = case
        when p_error = 'UNKNOWN_TEMPLATE' then 5
        else attempts
      end,
      last_error = left(coalesce(p_error, ''), 500),
      secret = case
        when p_error = 'UNKNOWN_TEMPLATE' or attempts >= 5 then null
        else secret
      end,
      updated_at = now()
    where id = p_job_id
    returning attempts into v_attempts;

    if p_error = 'UNKNOWN_TEMPLATE' or v_attempts >= 5 then
      v_outcome := 'failed';
    end if;
  end if;

  if v_outcome is null then
    return;
  end if;

  perform iam.record_email_delivery_outcome(
    p_correlation_id := v_job.correlation_id,
    p_template_id := v_job.template_id,
    p_status := v_outcome,
    p_tenant_id := v_job.tenant_id,
    p_provider_message_id := case
      when v_outcome = 'sent' then p_provider_message_id
      else null
    end,
    p_error := case
      when v_outcome = 'failed' then left(coalesce(p_error, ''), 500)
      else null
    end
  );
end;
$$;

revoke all on function iam._email_template_data(text, jsonb)
  from public, anon, authenticated;
revoke all on function iam.claim_email_job(uuid)
  from public, anon, authenticated;
revoke all on function iam.complete_email_job(uuid, boolean, text, text)
  from public, anon, authenticated;

grant execute on function iam.claim_email_job(uuid) to service_role;
grant execute on function iam.complete_email_job(uuid, boolean, text, text)
  to service_role;
