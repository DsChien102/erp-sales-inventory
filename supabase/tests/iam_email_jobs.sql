-- Kịch bản iam.email_jobs. Chạy trong một transaction rồi rollback.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/iam_email_jobs.sql

begin;

do $$
declare
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
  perform iam.enqueue_email_job(
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

  perform iam.enqueue_email_job(
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

  if has_function_privilege('authenticated', 'iam.enqueue_email_job(jsonb, uuid)', 'execute')
     or has_function_privilege('anon', 'iam.enqueue_email_job(jsonb, uuid)', 'execute') then
    raise exception 'authenticated / anon can execute enqueue_email_job';
  end if;
  if to_regclass('iam.outbox_messages') is not null then
    raise exception 'iam.outbox_messages still exists';
  end if;

  declare
    v_unknown_id uuid := gen_random_uuid();
    v_unknown_correlation text := gen_random_uuid()::text;
  begin
    perform iam.enqueue_email_job(
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

  perform iam.enqueue_email_job(
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

-- assign_member_role vẫn ghi nhật ký sau khi bỏ outbox IAM (9-2).
do $$
declare
  v_owner uuid := gen_random_uuid();
  v_staff uuid := gen_random_uuid();
  v_tenant uuid;
  v_membership_id uuid;
begin
  insert into auth.users (
    id, instance_id, aud, role, email,
    raw_app_meta_data, raw_user_meta_data,
    email_confirmed_at, created_at, updated_at
  )
  select u, '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated',
         'role-' || u::text || '@example.com',
         '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
         now(), now(), now()
  from unnest(array[v_owner, v_staff]) as u;

  v_tenant := iam._create_tenant_for_owner(
    v_owner,
    jsonb_build_object(
      'name', 'Nha thuoc Role Audit',
      'contact_phone', '0900000002',
      'contact_email', 'owner@example.com',
      'province_code', '01',
      'commune_code', '00001',
      'address_text', 'So 1'
    )
  );

  insert into iam.memberships (
    tenant_id, user_id, role, is_owner, version, created_at, updated_at
  )
  values (v_tenant, v_staff, 'staff', false, 1, now(), now())
  returning id into v_membership_id;

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_owner::text, 'role', 'authenticated')::text,
    true
  );
  perform set_config('request.jwt.claim.sub', v_owner::text, true);

  perform iam.assign_member_role(v_tenant, v_staff, 'accountant');

  if not exists (
    select 1
    from iam.audit_logs
    where event_code = 'iam.membership.role_changed'
      and target_id = v_membership_id::text
  ) then
    raise exception 'role change audit missing';
  end if;
end;
$$;

rollback;
