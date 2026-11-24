-- 9-2: nền messaging `platform` và các schema chỉ do nó tạo đã bị gỡ khỏi DB.
-- Chỉ còn sales.outbox_messages (8-C Q1), einvoice.internal_commands và đường email IAM.
-- psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/platform_messaging_removed.sql

begin;

do $$
declare
  v_list text;
begin
  -- 1) Không còn schema platform / costing / accounting / dashboard.
  if exists (
    select 1 from pg_namespace
    where nspname in ('platform', 'costing', 'accounting', 'dashboard')
  ) then
    raise exception 'FAIL: schema platform / costing / accounting / dashboard still exists';
  end if;

  -- 2) outbox_messages chỉ còn ở sales.
  select string_agg(table_schema, ',' order by table_schema) into v_list
  from information_schema.tables
  where table_name = 'outbox_messages';
  if v_list is distinct from 'sales' then
    raise exception 'FAIL: outbox_messages should only exist in sales, found %', v_list;
  end if;

  -- 3) Không còn inbox_messages.
  if exists (select 1 from information_schema.tables where table_name = 'inbox_messages') then
    raise exception 'FAIL: inbox_messages still exists';
  end if;

  -- 4) internal_commands chỉ còn ở einvoice.
  select string_agg(table_schema, ',' order by table_schema) into v_list
  from information_schema.tables
  where table_name = 'internal_commands';
  if v_list is distinct from 'einvoice' then
    raise exception 'FAIL: internal_commands should only exist in einvoice, found %', v_list;
  end if;

  -- 5) Không còn hàm nền messaging.
  select string_agg(n.nspname || '.' || p.proname, ', ') into v_list
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where p.proname in (
    'enqueue_outbox_message', 'install_module_messaging',
    'claim_outbox_batch', 'receive_integration_event'
  );
  if v_list is not null then
    raise exception 'FAIL: messaging functions still exist: %', v_list;
  end if;

  -- 6) Các hàm còn dùng vẫn có mặt.
  if to_regprocedure('einvoice.enqueue_internal_command(uuid, text, jsonb, uuid, uuid)') is null
     or to_regprocedure('einvoice.claim_internal_commands_batch(uuid, integer)') is null
     or to_regprocedure('einvoice.complete_internal_command(uuid, uuid, uuid)') is null
     or to_regprocedure('einvoice.fail_internal_command(uuid, uuid, uuid, text)') is null
     or to_regprocedure('iam.enqueue_email_job(jsonb, uuid)') is null then
    raise exception 'FAIL: a queue / email function is missing';
  end if;
end;
$$;

rollback;
