-- Kịch bản iam.email_jobs. Chạy trong một transaction rồi rollback.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/iam_email_jobs.sql

begin;

do $$
declare
  v_outbox_before bigint;
  v_outbox_after bigint;
  v_jobs_before bigint;
  v_message_id uuid := gen_random_uuid();
  v_other_id uuid := gen_random_uuid();
  v_retry_id uuid := gen_random_uuid();
  v_correlation text := gen_random_uuid()::text;
  v_retry_correlation text := gen_random_uuid()::text;
  v_ciphertext text := 'transient:' || encode(convert_to('123456', 'UTF8'), 'base64');
  v_claim jsonb;
  v_status text;
  v_secret text;
  v_secret_cleared boolean;
  v_attempts int;
  v_i int;
begin
  select count(*) into v_outbox_before from iam.outbox_messages;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000000'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'to_email', 'reset@example.com',
      'correlation_id', v_correlation,
      'locale', 'vi',
      'tenant_id', null,
      'refs', jsonb_build_object('operation_id', gen_random_uuid()::text),
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_message_id
  );

  select count(*) into v_outbox_after from iam.outbox_messages;
  if v_outbox_after <> v_outbox_before then
    raise exception 'email event wrote outbox_messages';
  end if;

  select secret->>'code', status
  into v_secret, v_status
  from iam.email_jobs
  where id = v_message_id;

  if v_status is distinct from 'queued' or v_secret is distinct from '123456' then
    raise exception 'email job not queued with decoded code (status %, code %)', v_status, v_secret;
  end if;

  if (select template_data->>'expires_in_minutes' from iam.email_jobs where id = v_message_id)
     is distinct from '10' then
    raise exception 'password_reset_code template_data missing expires_in_minutes';
  end if;

  select count(*) into v_jobs_before from iam.email_jobs;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000001'::uuid,
    'iam.tenant.created',
    '{"hello":"world"}'::jsonb,
    v_other_id
  );

  if not exists (
    select 1
    from iam.outbox_messages
    where id = v_other_id
      and event_type = 'iam.tenant.created'
  ) then
    raise exception 'non-email event did not enter outbox_messages';
  end if;

  if (select count(*) from iam.email_jobs) <> v_jobs_before then
    raise exception 'non-email event entered email_jobs';
  end if;

  v_claim := iam.claim_email_job(v_message_id);
  if v_claim->>'code' is distinct from '123456' then
    raise exception 'first claim did not return the code';
  end if;
  if iam.claim_email_job(v_message_id) is not null then
    raise exception 'second claim should be null while sending';
  end if;

  perform iam.complete_email_job(v_message_id, true, 're_test', null);

  select status, secret->>'code'
  into v_status, v_secret
  from iam.email_jobs
  where id = v_message_id;

  if v_status is distinct from 'sent' or v_secret is not null then
    raise exception 'completed job should be sent with secret cleared';
  end if;

  select o.status into v_status
  from iam.email_delivery_outcomes o
  where o.correlation_id = v_correlation;

  if v_status is distinct from 'sent' then
    raise exception 'outcome should be sent, got %', v_status;
  end if;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000000'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'to_email', 'retry@example.com',
      'correlation_id', v_retry_correlation,
      'locale', 'vi',
      'refs', '{}'::jsonb,
      'secret_payload_ciphertext', v_ciphertext
    ),
    v_retry_id
  );

  for v_i in 1..5 loop
    v_claim := iam.claim_email_job(v_retry_id);
    if v_claim is null then
      raise exception 'claim % returned null before the attempt limit', v_i;
    end if;
    perform iam.complete_email_job(v_retry_id, false, null, 'provider down');
    if v_i < 5 and exists (
      select 1
      from iam.email_delivery_outcomes o
      where o.correlation_id = v_retry_correlation
        and o.status = 'failed'
    ) then
      raise exception 'outcome marked failed before the last attempt (%)' , v_i;
    end if;
  end loop;

  if iam.claim_email_job(v_retry_id) is not null then
    raise exception 'sixth claim should be null';
  end if;

  select status, secret is null, attempts
  into v_status, v_secret_cleared, v_attempts
  from iam.email_jobs
  where id = v_retry_id;

  if v_status is distinct from 'failed' or not v_secret_cleared or v_attempts <> 5 then
    raise exception 'exhausted job status=% secret_null=% attempts=%',
      v_status, v_secret_cleared, v_attempts;
  end if;

  select o.status into v_status
  from iam.email_delivery_outcomes o
  where o.correlation_id = v_retry_correlation;

  if v_status is distinct from 'failed' then
    raise exception 'exhausted outcome should be failed, got %', v_status;
  end if;

  if has_function_privilege('authenticated', 'iam.claim_email_job(uuid)', 'execute') then
    raise exception 'authenticated can execute claim_email_job';
  end if;

  declare
    v_unknown_id uuid := gen_random_uuid();
    v_unknown_correlation text := gen_random_uuid()::text;
  begin
    perform iam.enqueue_outbox_message(
      '00000000-0000-0000-0000-000000000000'::uuid,
      'iam.email.delivery_requested',
      jsonb_build_object(
        'template_id', 'activation_invitation',
        'to_email', 'unknown-template@example.com',
        'correlation_id', v_unknown_correlation,
        'locale', 'vi',
        'refs', '{}'::jsonb,
        'secret_payload_ciphertext', v_ciphertext
      ),
      v_unknown_id
    );

    if iam.claim_email_job(v_unknown_id) is null then
      raise exception 'unknown template job should be claimable once';
    end if;

    perform iam.complete_email_job(v_unknown_id, false, null, 'UNKNOWN_TEMPLATE');

    select status, secret is null, attempts
    into v_status, v_secret_cleared, v_attempts
    from iam.email_jobs
    where id = v_unknown_id;

    if v_status is distinct from 'failed'
       or not v_secret_cleared
       or v_attempts is distinct from 5 then
      raise exception 'UNKNOWN_TEMPLATE should fail immediately status=% secret_null=% attempts=%',
        v_status, v_secret_cleared, v_attempts;
    end if;

    select o.status into v_status
    from iam.email_delivery_outcomes o
    where o.correlation_id = v_unknown_correlation;

    if v_status is distinct from 'failed' then
      raise exception 'UNKNOWN_TEMPLATE outcome should be failed, got %', v_status;
    end if;

    if iam.claim_email_job(v_unknown_id) is not null then
      raise exception 'UNKNOWN_TEMPLATE job should not be claimed again';
    end if;
  end;

  perform iam.enqueue_outbox_message(
    '00000000-0000-0000-0000-000000000000'::uuid,
    'iam.email.delivery_requested',
    jsonb_build_object(
      'template_id', 'password_reset_code',
      'to_email', 'novault@example.com',
      'correlation_id', gen_random_uuid()::text,
      'locale', 'vi',
      'refs', '{}'::jsonb,
      'secret_payload_ciphertext', v_ciphertext
    ),
    gen_random_uuid()
  );
end;
$$;

rollback;
