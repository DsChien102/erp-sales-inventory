-- Title: einvoice — hàng đợi internal_commands + nhật ký outbox
-- Kind: surgical
-- Intent: einvoice_s1_install_messaging
-- Context: TH-08 / S1 worker internal_commands
-- Touches: einvoice.internal_commands, einvoice.outbox_messages, einvoice.enqueue_outbox_message, einvoice.enqueue_internal_command, einvoice.claim_internal_commands_batch, einvoice.complete_internal_command, einvoice.fail_internal_command
-- Safety: idempotent ; medium
-- Depends on: 20261031001_einvoice_configuration_schema.sql
-- 7-C (2026-11-09): bỏ messaging (inbox, hàm outbox / inbox, đăng ký platform); outbox_messages = nhật ký sự kiện, không ai đọc.

create schema if not exists einvoice;

-- Outbox messages (nhật ký sự kiện, 5 cột)
create table if not exists einvoice.outbox_messages (
  id uuid primary key,
  tenant_id uuid not null,
  event_type text not null,
  payload jsonb not null,
  occurred_at timestamptz not null default now()
);

-- Internal commands
create table if not exists einvoice.internal_commands (
  id uuid primary key,
  tenant_id uuid not null,
  command_type text not null,
  payload jsonb not null,
  source_event_id uuid null,
  enqueued_at timestamptz not null default now(),
  processed_at timestamptz null,
  failed_at timestamptz null,
  error text null,
  retry_count int not null default 0,
  claimed_at timestamptz null,
  claim_token uuid null
);

create index if not exists internal_commands_pending_tenant_idx
  on einvoice.internal_commands (tenant_id, enqueued_at)
  where processed_at is null and failed_at is null;

create unique index if not exists internal_commands_source_dedup_idx
  on einvoice.internal_commands (tenant_id, source_event_id, command_type)
  where source_event_id is not null;

-- enqueue_outbox_message
create or replace function einvoice.enqueue_outbox_message(
  p_tenant_id uuid,
  p_event_type text,
  p_payload jsonb,
  p_message_id uuid default gen_random_uuid(),
  p_occurred_at timestamptz default now()
)
returns uuid
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  insert into outbox_messages (
    id, tenant_id, event_type, payload, occurred_at
  )
  values (
    p_message_id, p_tenant_id, p_event_type, p_payload, p_occurred_at
  );
  return p_message_id;
end;
$$;

-- enqueue_internal_command
create or replace function einvoice.enqueue_internal_command(
  p_tenant_id uuid,
  p_command_type text,
  p_payload jsonb,
  p_source_event_id uuid default null,
  p_command_id uuid default gen_random_uuid()
)
returns uuid
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  insert into internal_commands (
    id, tenant_id, command_type, payload, source_event_id
  )
  values (
    p_command_id, p_tenant_id, p_command_type, p_payload, p_source_event_id
  )
  on conflict do nothing;

  return p_command_id;
end;
$$;

drop function if exists einvoice.claim_internal_commands_batch(uuid, integer);

create or replace function einvoice.claim_internal_commands_batch(
  p_tenant_id uuid,
  p_limit int default 10
)
returns table (
  command_id uuid,
  command_type text,
  payload jsonb,
  source_event_id uuid,
  enqueued_at timestamptz,
  claim_token uuid,
  retry_count int
)
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  return query
  with candidates as (
    select m.id
    from internal_commands m
    where m.tenant_id = p_tenant_id
      and m.processed_at is null
      and m.failed_at is null
      and m.enqueued_at <= now()
      and (
        m.claimed_at is null
        or m.claimed_at < now() - interval '10 minutes'
      )
    order by m.enqueued_at
    for update skip locked
    limit greatest(p_limit, 1)
  ),
  updated as (
    update internal_commands m
    set
      claimed_at = now(),
      claim_token = gen_random_uuid()
    from candidates c
    where m.id = c.id
    returning
      m.id,
      m.command_type,
      m.payload,
      m.source_event_id,
      m.enqueued_at,
      m.claim_token,
      m.retry_count
  )
  select
    u.id,
    u.command_type,
    u.payload,
    u.source_event_id,
    u.enqueued_at,
    u.claim_token,
    u.retry_count
  from updated u;
end;
$$;

-- complete_internal_command
create or replace function einvoice.complete_internal_command(
  p_tenant_id uuid,
  p_command_id uuid,
  p_claim_token uuid
)
returns void
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  update internal_commands
  set
    processed_at = now(),
    claimed_at = null,
    claim_token = null
  where id = p_command_id
    and tenant_id = p_tenant_id
    and claim_token = p_claim_token
    and processed_at is null;
end;
$$;

-- fail_internal_command
create or replace function einvoice.fail_internal_command(
  p_tenant_id uuid,
  p_command_id uuid,
  p_claim_token uuid,
  p_error text
)
returns void
language plpgsql
security definer
set search_path = einvoice, platform, pg_temp
as $$
begin
  update internal_commands
  set
    failed_at = now(),
    error = p_error,
    retry_count = retry_count + 1,
    claimed_at = null,
    claim_token = null
  where id = p_command_id
    and tenant_id = p_tenant_id
    and claim_token = p_claim_token
    and processed_at is null;
end;
$$;

grant usage on schema einvoice to service_role;
grant usage on schema einvoice to authenticated;

revoke all on all tables in schema einvoice from public, anon, authenticated;

revoke all on function
  einvoice.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz),
  einvoice.enqueue_internal_command(uuid, text, jsonb, uuid, uuid),
  einvoice.claim_internal_commands_batch(uuid, int),
  einvoice.complete_internal_command(uuid, uuid, uuid),
  einvoice.fail_internal_command(uuid, uuid, uuid, text)
from public, anon, authenticated;

grant execute on function einvoice.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz) to service_role;
grant execute on function einvoice.enqueue_internal_command(uuid, text, jsonb, uuid, uuid) to service_role;
grant execute on function einvoice.claim_internal_commands_batch(uuid, int) to service_role;
grant execute on function einvoice.complete_internal_command(uuid, uuid, uuid) to service_role;
grant execute on function einvoice.fail_internal_command(uuid, uuid, uuid, text) to service_role;

-- Close PostgreSQL's historical default grants without removing explicit
-- authenticated grants on S1 UI RPCs when this installer is rerun alone.
revoke execute on all functions in schema einvoice from public, anon;
