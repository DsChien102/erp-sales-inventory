-- Title: iam email job dispatch via pg_net and pg_cron
-- Kind: patch
-- Intent: iam_email_dispatch
-- Context: TH-01 6.3, KI-07
-- Touches: iam._invoke_send_email, iam._dispatch_email_job, iam.retry_email_jobs
-- Safety: idempotent ; medium
-- Depends on: 20261009003_iam_email_jobs.sql

create schema if not exists extensions;

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

-- Reads Vault names project_url and email_webhook_secret. Missing secrets
-- return without error so invitation RPCs still commit; cron retries later.
create or replace function iam._invoke_send_email(p_job_id uuid)
returns void
language plpgsql
security definer
set search_path = iam, extensions, pg_temp
as $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
  from vault.decrypted_secrets
  where name = 'project_url'
  limit 1;

  select decrypted_secret into v_secret
  from vault.decrypted_secrets
  where name = 'email_webhook_secret'
  limit 1;

  if nullif(trim(both from v_url), '') is null
     or nullif(trim(both from v_secret), '') is null then
    return;
  end if;

  perform net.http_post(
    url := rtrim(v_url, '/') || '/functions/v1/send-email',
    body := jsonb_build_object('job_id', p_job_id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-email-webhook-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
end;
$$;

create or replace function iam._dispatch_email_job()
returns trigger
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
begin
  begin
    perform iam._invoke_send_email(new.id);
  exception
    when others then
      null;
  end;
  return new;
end;
$$;

drop trigger if exists email_jobs_dispatch on iam.email_jobs;

create trigger email_jobs_dispatch
  after insert on iam.email_jobs
  for each row
  execute function iam._dispatch_email_job();

create or replace function iam.retry_email_jobs()
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_id uuid;
begin
  for v_id in
    select j.id
    from iam.email_jobs j
    where j.secret is not null
      and j.attempts < 5
      and (
        (j.status = 'queued' and j.created_at < now() - interval '1 minute')
        or j.status = 'failed'
        or (
          j.status = 'sending'
          and j.claimed_at < now() - interval '5 minutes'
        )
      )
    order by j.created_at
    limit 20
  loop
    begin
      perform iam._invoke_send_email(v_id);
    exception
      when others then
        null;
    end;
  end loop;
end;
$$;

revoke all on function iam._invoke_send_email(uuid)
  from public, anon, authenticated;
revoke all on function iam._dispatch_email_job()
  from public, anon, authenticated;
revoke all on function iam.retry_email_jobs()
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
    where jobname = 'iam-retry-email-jobs'
  loop
    perform cron.unschedule(v_job.jobid);
  end loop;
end;
$$;

select cron.schedule(
  'iam-retry-email-jobs',
  '* * * * *',
  $$select iam.retry_email_jobs()$$
);
