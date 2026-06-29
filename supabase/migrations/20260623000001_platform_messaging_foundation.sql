-- Vet45 messaging foundation: platform schema + per-module install function.
-- Installed modules are registered in platform.messaging_module_registry and
-- exposed via platform.messaging_backlog_stats + list_tenants_with_pending_messaging.

create schema if not exists platform;

create table if not exists platform.messaging_module_registry (
  module_schema text primary key,
  installed_at timestamptz not null default now()
);

revoke all on table platform.messaging_module_registry from public, anon, authenticated;
grant select on table platform.messaging_module_registry to service_role;

-- Empty view until first module is installed; rebuilt by rebuild_messaging_backlog_stats_view().
create or replace view platform.messaging_backlog_stats as
select
  null::text as module_schema,
  null::text as queue_type,
  null::uuid as tenant_id,
  0::bigint as pending_count,
  null::timestamptz as oldest_pending_at
where false;

grant select on platform.messaging_backlog_stats to service_role;

create or replace function platform.rebuild_messaging_backlog_stats_view()
returns void
language plpgsql
security definer
set search_path = platform, pg_temp
as $$
declare
  v_sql text := '';
  r record;
  v_first boolean := true;
begin
  for r in
    select module_schema
    from platform.messaging_module_registry
    order by module_schema
  loop
    if not v_first then
      v_sql := v_sql || ' union all ';
    end if;
    v_first := false;

    v_sql := v_sql || format(
      $part$
      select %L::text as module_schema,
             'outbox'::text as queue_type,
             tenant_id,
             count(*)::bigint as pending_count,
             min(occurred_at) as oldest_pending_at
      from %I.outbox_messages
      where processed_at is null
        and failed_at is null
      group by tenant_id
      union all
      select %L::text,
             'inbox'::text,
             tenant_id,
             count(*)::bigint,
             min(occurred_at)
      from %I.inbox_messages
      where processed_at is null
        and failed_at is null
      group by tenant_id
      union all
      select %L::text,
             'internal_commands'::text,
             tenant_id,
             count(*)::bigint,
             min(enqueued_at)
      from %I.internal_commands
      where processed_at is null
        and failed_at is null
      group by tenant_id
      $part$,
      r.module_schema,
      r.module_schema,
      r.module_schema,
      r.module_schema,
      r.module_schema,
      r.module_schema
    );
  end loop;

  if v_sql = '' then
    v_sql :=
      'select null::text as module_schema, null::text as queue_type, '
      || 'null::uuid as tenant_id, 0::bigint as pending_count, '
      || 'null::timestamptz as oldest_pending_at where false';
  end if;

  execute 'create or replace view platform.messaging_backlog_stats as ' || v_sql;
  grant select on platform.messaging_backlog_stats to service_role;
end;
$$;

revoke all on function platform.rebuild_messaging_backlog_stats_view() from public, anon, authenticated;
grant execute on function platform.rebuild_messaging_backlog_stats_view() to service_role;

create or replace function platform.list_tenants_with_pending_messaging(p_limit int default 100)
returns table (tenant_id uuid, oldest_created_at timestamptz)
language plpgsql
security definer
set search_path = platform, pg_temp
as $$
declare
  v_sql text := '';
  r record;
  v_first boolean := true;
begin
  for r in
    select module_schema
    from platform.messaging_module_registry
    order by module_schema
  loop
    if not v_first then
      v_sql := v_sql || ' union all ';
    end if;
    v_first := false;

    v_sql := v_sql || format(
      $part$
      select tenant_id, occurred_at as ts
      from %I.outbox_messages
      where processed_at is null
        and failed_at is null
      union all
      select tenant_id, occurred_at
      from %I.inbox_messages
      where processed_at is null
        and failed_at is null
      union all
      select tenant_id, enqueued_at
      from %I.internal_commands
      where processed_at is null
        and failed_at is null
      $part$,
      r.module_schema,
      r.module_schema,
      r.module_schema
    );
  end loop;

  if v_sql = '' then
    return;
  end if;

  return query execute format(
    $q$
    select tenant_id, min(ts) as oldest_created_at
    from (%s) pending
    group by tenant_id
    order by oldest_created_at asc
    limit %s
    $q$,
    v_sql,
    greatest(p_limit, 1)
  );
end;
$$;

revoke all on function platform.list_tenants_with_pending_messaging(int) from public, anon, authenticated;
grant execute on function platform.list_tenants_with_pending_messaging(int) to service_role;

create or replace function platform.install_module_messaging(p_schema text)
returns void
language plpgsql
security definer
set search_path = platform, pg_temp
as $$
declare
  v_allowed constant text[] := array[
    'iam', 'catalog', 'partner', 'sales',
    'inventory', 'costing', 'accounting', 'dashboard'
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
        from internal_commands m
        where m.tenant_id = p_tenant_id
          and m.processed_at is null
          and m.failed_at is null
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
          m.claim_token
      )
      select
        u.id,
        u.command_type,
        u.payload,
        u.source_event_id,
        u.enqueued_at,
        u.claim_token
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

  -- Grants: schema usage + RPC execute for service_role only.
  execute format('grant usage on schema %I to service_role', p_schema);

  execute format(
    'revoke all on all tables in schema %I from public, anon, authenticated',
    p_schema
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

grant usage on schema platform to service_role;
