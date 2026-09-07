-- Title: platform patch — allow einvoice messaging install
-- Kind: surgical
-- Intent: einvoice_s1_install_messaging
-- Context: TH-08 / S1 worker internal_commands
-- Touches: install_module_messaging
-- Safety: idempotent ; medium
-- Depends on: 20260623000001_platform_messaging_foundation.sql, 001_einvoice_configuration_schema.sql
--
-- Delta vs foundation: add 'einvoice' to installer whitelist, then install
-- canonical outbox/inbox/internal_commands + claim/complete/fail RPCs.
-- Tenant discovery stays on platform.messaging_module_registry (no hand-patched list_tenants).

create or replace function platform.install_module_messaging(p_schema text)
returns void
language plpgsql
security definer
set search_path = platform, pg_temp
as $$
declare
  v_allowed constant text[] := array[
    'iam', 'catalog', 'partner', 'sales',
    'inventory', 'costing', 'accounting', 'dashboard', 'einvoice'
  ];
begin
  if not (p_schema = any (v_allowed)) then
    raise exception 'schema not allowed for messaging install: %', p_schema;
  end if;

  execute format('create schema if not exists %I', p_schema);

  -- Outbox
  execute format($sql$
    create table if not exists %I.outbox_messages (
      id uuid primary key,
      tenant_id uuid not null,
      event_type text not null,
      payload jsonb not null,
      occurred_at timestamptz not null default now(),
      processed_at timestamptz null,
      failed_at timestamptz null,
      error text null,
      retry_count int not null default 0,
      claimed_at timestamptz null,
      claim_token uuid null
    )
  $sql$, p_schema);

  execute format($sql$
    create index if not exists outbox_messages_pending_tenant_idx
      on %I.outbox_messages (tenant_id, occurred_at)
      where processed_at is null and failed_at is null
  $sql$, p_schema);

  -- Inbox
  execute format($sql$
    create table if not exists %I.inbox_messages (
      id uuid primary key,
      tenant_id uuid not null,
      event_type text not null,
      payload jsonb not null,
      occurred_at timestamptz not null,
      processed_at timestamptz null,
      failed_at timestamptz null,
      error text null,
      retry_count int not null default 0,
      claimed_at timestamptz null,
      claim_token uuid null
    )
  $sql$, p_schema);

  execute format($sql$
    create index if not exists inbox_messages_pending_tenant_idx
      on %I.inbox_messages (tenant_id, occurred_at)
      where processed_at is null and failed_at is null
  $sql$, p_schema);

  -- Internal commands
  execute format($sql$
    create table if not exists %I.internal_commands (
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
    )
  $sql$, p_schema);

  execute format($sql$
    create index if not exists internal_commands_pending_tenant_idx
      on %I.internal_commands (tenant_id, enqueued_at)
      where processed_at is null and failed_at is null
  $sql$, p_schema);

  execute format($sql$
    create unique index if not exists internal_commands_source_dedup_idx
      on %I.internal_commands (tenant_id, source_event_id, command_type)
      where source_event_id is not null
  $sql$, p_schema);

  -- enqueue_outbox_message
  execute format($sql$
    create or replace function %I.enqueue_outbox_message(
      p_tenant_id uuid,
      p_event_type text,
      p_payload jsonb,
      p_message_id uuid default gen_random_uuid(),
      p_occurred_at timestamptz default now()
    )
    returns uuid
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      insert into outbox_messages (
        id, tenant_id, event_type, payload, occurred_at
      )
      values (
        p_message_id, p_tenant_id, p_event_type, p_payload, p_occurred_at
      );
      return p_message_id;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- claim_outbox_batch
  execute format($sql$
    create or replace function %I.claim_outbox_batch(
      p_tenant_id uuid,
      p_limit int default 10
    )
    returns table (
      message_id uuid,
      event_type text,
      payload jsonb,
      occurred_at timestamptz,
      claim_token uuid
    )
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      return query
      with candidates as (
        select m.id
        from outbox_messages m
        where m.tenant_id = p_tenant_id
          and m.processed_at is null
          and m.failed_at is null
          and (
            m.claimed_at is null
            or m.claimed_at < now() - interval '10 minutes'
          )
        order by m.occurred_at
        for update skip locked
        limit greatest(p_limit, 1)
      ),
      updated as (
        update outbox_messages m
        set
          claimed_at = now(),
          claim_token = gen_random_uuid()
        from candidates c
        where m.id = c.id
        returning
          m.id,
          m.event_type,
          m.payload,
          m.occurred_at,
          m.claim_token
      )
      select
        u.id,
        u.event_type,
        u.payload,
        u.occurred_at,
        u.claim_token
      from updated u;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- complete_outbox_message
  execute format($sql$
    create or replace function %I.complete_outbox_message(
      p_tenant_id uuid,
      p_message_id uuid,
      p_claim_token uuid
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      update outbox_messages
      set
        processed_at = now(),
        claimed_at = null,
        claim_token = null
      where id = p_message_id
        and tenant_id = p_tenant_id
        and claim_token = p_claim_token
        and processed_at is null;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- fail_outbox_message
  execute format($sql$
    create or replace function %I.fail_outbox_message(
      p_tenant_id uuid,
      p_message_id uuid,
      p_claim_token uuid,
      p_error text
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      update outbox_messages
      set
        failed_at = now(),
        error = p_error,
        retry_count = retry_count + 1,
        claimed_at = null,
        claim_token = null
      where id = p_message_id
        and tenant_id = p_tenant_id
        and claim_token = p_claim_token
        and processed_at is null;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- receive_integration_event
  execute format($sql$
    create or replace function %I.receive_integration_event(
      p_tenant_id uuid,
      p_message_id uuid,
      p_event_type text,
      p_payload jsonb,
      p_occurred_at timestamptz
    )
    returns uuid
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      insert into inbox_messages (
        id, tenant_id, event_type, payload, occurred_at
      )
      values (
        p_message_id, p_tenant_id, p_event_type, p_payload, p_occurred_at
      )
      on conflict (id) do nothing;

      return p_message_id;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- claim_inbox_batch
  execute format($sql$
    create or replace function %I.claim_inbox_batch(
      p_tenant_id uuid,
      p_limit int default 10
    )
    returns table (
      message_id uuid,
      event_type text,
      payload jsonb,
      occurred_at timestamptz,
      claim_token uuid
    )
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      return query
      with candidates as (
        select m.id
        from inbox_messages m
        where m.tenant_id = p_tenant_id
          and m.processed_at is null
          and m.failed_at is null
          and (
            m.claimed_at is null
            or m.claimed_at < now() - interval '10 minutes'
          )
        order by m.occurred_at
        for update skip locked
        limit greatest(p_limit, 1)
      ),
      updated as (
        update inbox_messages m
        set
          claimed_at = now(),
          claim_token = gen_random_uuid()
        from candidates c
        where m.id = c.id
        returning
          m.id,
          m.event_type,
          m.payload,
          m.occurred_at,
          m.claim_token
      )
      select
        u.id,
        u.event_type,
        u.payload,
        u.occurred_at,
        u.claim_token
      from updated u;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- complete_inbox_message
  execute format($sql$
    create or replace function %I.complete_inbox_message(
      p_tenant_id uuid,
      p_message_id uuid,
      p_claim_token uuid
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      update inbox_messages
      set
        processed_at = now(),
        claimed_at = null,
        claim_token = null
      where id = p_message_id
        and tenant_id = p_tenant_id
        and claim_token = p_claim_token
        and processed_at is null;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- fail_inbox_message
  execute format($sql$
    create or replace function %I.fail_inbox_message(
      p_tenant_id uuid,
      p_message_id uuid,
      p_claim_token uuid,
      p_error text
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
    begin
      update inbox_messages
      set
        failed_at = now(),
        error = p_error,
        retry_count = retry_count + 1,
        claimed_at = null,
        claim_token = null
      where id = p_message_id
        and tenant_id = p_tenant_id
        and claim_token = p_claim_token
        and processed_at is null;
    end;
    $fn$
  $sql$, p_schema, p_schema);

  -- enqueue_internal_command
  execute format($sql$
    create or replace function %I.enqueue_internal_command(
      p_tenant_id uuid,
      p_command_type text,
      p_payload jsonb,
      p_source_event_id uuid default null,
      p_command_id uuid default gen_random_uuid()
    )
    returns uuid
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
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
    $fn$
  $sql$, p_schema, p_schema);

  -- claim_internal_commands_batch
  execute format(
    'drop function if exists %I.claim_internal_commands_batch(uuid, integer)',
    p_schema
  );

  execute format($sql$
    create or replace function %I.claim_internal_commands_batch(
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
    set search_path = %I, platform, pg_temp
    as $fn$
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
    $fn$
  $sql$, p_schema, p_schema);

  -- complete_internal_command
  execute format($sql$
    create or replace function %I.complete_internal_command(
      p_tenant_id uuid,
      p_command_id uuid,
      p_claim_token uuid
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
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
    $fn$
  $sql$, p_schema, p_schema);

  -- fail_internal_command
  execute format($sql$
    create or replace function %I.fail_internal_command(
      p_tenant_id uuid,
      p_command_id uuid,
      p_claim_token uuid,
      p_error text
    )
    returns void
    language plpgsql
    security definer
    set search_path = %I, platform, pg_temp
    as $fn$
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
    $fn$
  $sql$, p_schema, p_schema);

  -- Authenticated users need schema usage for the explicitly granted S1 UI
  -- RPCs. Messaging tables and queue RPCs remain worker-only.
  execute format('grant usage on schema %I to service_role', p_schema);
  execute format('grant usage on schema %I to authenticated', p_schema);

  execute format(
    'revoke all on all tables in schema %I from public, anon, authenticated',
    p_schema
  );

  execute format(
    $sql$
    revoke all on function
      %I.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz),
      %I.claim_outbox_batch(uuid, int),
      %I.complete_outbox_message(uuid, uuid, uuid),
      %I.fail_outbox_message(uuid, uuid, uuid, text),
      %I.receive_integration_event(uuid, uuid, text, jsonb, timestamptz),
      %I.claim_inbox_batch(uuid, int),
      %I.complete_inbox_message(uuid, uuid, uuid),
      %I.fail_inbox_message(uuid, uuid, uuid, text),
      %I.enqueue_internal_command(uuid, text, jsonb, uuid, uuid),
      %I.claim_internal_commands_batch(uuid, int),
      %I.complete_internal_command(uuid, uuid, uuid),
      %I.fail_internal_command(uuid, uuid, uuid, text)
    from public, anon, authenticated
    $sql$,
    p_schema, p_schema, p_schema, p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema, p_schema, p_schema, p_schema
  );

  execute format(
    $sql$
    grant execute on function
      %I.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz),
      %I.claim_outbox_batch(uuid, int),
      %I.complete_outbox_message(uuid, uuid, uuid),
      %I.fail_outbox_message(uuid, uuid, uuid, text),
      %I.receive_integration_event(uuid, uuid, text, jsonb, timestamptz),
      %I.claim_inbox_batch(uuid, int),
      %I.complete_inbox_message(uuid, uuid, uuid),
      %I.fail_inbox_message(uuid, uuid, uuid, text),
      %I.enqueue_internal_command(uuid, text, jsonb, uuid, uuid),
      %I.claim_internal_commands_batch(uuid, int),
      %I.complete_internal_command(uuid, uuid, uuid),
      %I.fail_internal_command(uuid, uuid, uuid, text)
    to service_role
    $sql$,
    p_schema, p_schema, p_schema, p_schema, p_schema, p_schema,
    p_schema, p_schema, p_schema, p_schema, p_schema, p_schema
  );

  insert into platform.messaging_module_registry (module_schema)
  values (p_schema)
  on conflict (module_schema) do nothing;

  perform platform.rebuild_messaging_backlog_stats_view();
end;
$$;

revoke all on function platform.install_module_messaging(text) from public, anon, authenticated;
grant execute on function platform.install_module_messaging(text) to service_role;

select platform.install_module_messaging('einvoice');

-- Close PostgreSQL's historical default grants without removing explicit
-- authenticated grants on S1 UI RPCs when this installer is rerun alone.
revoke execute on all functions in schema einvoice from public, anon;
