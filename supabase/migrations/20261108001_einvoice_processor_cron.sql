-- Title: einvoice processor cron schedule via pg_net and pg_cron
-- Kind: patch
-- Intent: einvoice_processor_cron
-- Context: TH-08 KI-20, 7-E3
-- Touches: einvoice._invoke_processor
-- Safety: idempotent ; medium
-- Depends on: 20261009004_iam_email_dispatch.sql, 20261031009_einvoice_issuance_reconciliation_rpcs.sql

create schema if not exists extensions;

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

-- Reads Vault secrets 'project_url' and 'service_role_key'. If either is missing or empty,
-- returns without error. Only invokes edge function if there are internal commands due.
create or replace function einvoice._invoke_processor()
returns void
language plpgsql
security definer
set search_path = einvoice, extensions, pg_temp
as $$
declare
  v_url text;
  v_key text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'project_url'
  limit 1;

  select decrypted_secret into v_key
  from vault.decrypted_secrets
  where name = 'service_role_key'
  limit 1;

  if nullif(trim(both from v_url), '') is null
     or nullif(trim(both from v_key), '') is null then
    return;
  end if;

  if not exists (
    select 1
    from einvoice.internal_commands m
    where m.processed_at is null
      and m.failed_at is null
      and m.enqueued_at <= now()
      and (m.claimed_at is null or m.claimed_at < now() - interval '10 minutes')
  ) then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/einvoice-processor',
    body := '{}'::jsonb,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_key
    ),
    timeout_milliseconds := 150000
  );
end;
$$;

revoke all on function einvoice._invoke_processor()
  from public, anon, authenticated;

do $$
declare
  v_job record;
begin
  if to_regclass('cron.job') is null then
    raise exception 'pg_cron is not available';
  end if;

  for v_job in
    select jobid
    from cron.job
    where jobname = 'einvoice-processor-tick'
  loop
    perform cron.unschedule(v_job.jobid);
  end loop;
end;
$$;

select cron.schedule(
  'einvoice-processor-tick',
  '30 seconds',
  $$select einvoice._invoke_processor()$$
);

