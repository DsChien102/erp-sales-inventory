-- Messaging foundation smoke test (run after migrations).
-- Usage: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/supabase/messaging_smoke_test.sql

begin;

do $$
declare
  v_tenant uuid := '11111111-1111-4111-8111-111111111111';
  v_message_id uuid := '22222222-2222-4222-8222-222222222222';
  v_event_id uuid := '33333333-3333-4333-8333-333333333333';
  v_command_id uuid := '44444444-4444-4444-8444-444444444444';
  v_claim_token uuid;
  v_inbox_count int;
  v_command_count int;
  v_pending bigint;
begin
  -- Outbox enqueue + claim + complete
  perform catalog.enqueue_outbox_message(
    v_tenant,
    'catalog.product.created',
    jsonb_build_object('product_id', gen_random_uuid()),
    v_message_id
  );

  select claim_token
  into v_claim_token
  from catalog.claim_outbox_batch(v_tenant, 10)
  where message_id = v_message_id;

  if v_claim_token is null then
    raise exception 'claim_outbox_batch did not return claim_token';
  end if;

  perform catalog.complete_outbox_message(v_tenant, v_message_id, v_claim_token);

  -- Inbox idempotency (receive twice, one row)
  perform catalog.receive_integration_event(
    v_tenant,
    v_event_id,
    'sales.order.checked_out',
    jsonb_build_object('order_id', gen_random_uuid()),
    now()
  );
  perform catalog.receive_integration_event(
    v_tenant,
    v_event_id,
    'sales.order.checked_out',
    jsonb_build_object('order_id', gen_random_uuid()),
    now()
  );

  select count(*)
  into v_inbox_count
  from catalog.inbox_messages
  where id = v_event_id;

  if v_inbox_count <> 1 then
    raise exception 'inbox idempotency failed: expected 1 row, got %', v_inbox_count;
  end if;

  -- Internal command dedup by (tenant_id, source_event_id, command_type)
  perform catalog.enqueue_internal_command(
    v_tenant,
    'catalog.rebuild_search_projection',
    jsonb_build_object('tenant_id', v_tenant::text),
    v_event_id,
    v_command_id
  );
  perform catalog.enqueue_internal_command(
    v_tenant,
    'catalog.rebuild_search_projection',
    jsonb_build_object('tenant_id', v_tenant::text),
    v_event_id,
    gen_random_uuid()
  );

  select count(*)
  into v_command_count
  from catalog.internal_commands
  where tenant_id = v_tenant
    and source_event_id = v_event_id
    and command_type = 'catalog.rebuild_search_projection';

  if v_command_count <> 1 then
    raise exception 'internal command dedup failed: expected 1 row, got %', v_command_count;
  end if;

  -- Platform discovery should not include completed outbox row
  select count(*)
  into v_pending
  from platform.list_tenants_with_pending_messaging(100)
  where tenant_id = v_tenant;

  if v_pending <> 1 then
    raise exception 'discovery expected tenant with inbox/internal pending, got %', v_pending;
  end if;

  -- Partner inbox claim + projection upsert path (Epic-03 consume smoke)
  declare
    v_partner_id uuid := '55555555-5555-4555-8555-555555555555';
    v_partner_event_id uuid := '66666666-6666-4666-8666-666666666666';
    v_order_id uuid := '77777777-7777-4777-8777-777777777777';
    v_partner_claim_token uuid;
    v_history_count int;
  begin
    insert into partner.business_partners (
      id,
      tenant_id,
      entity_type,
      display_name,
      individual_name,
      phone,
      phone_normalized,
      created_by,
      updated_by
    )
    values (
      v_partner_id,
      v_tenant,
      'individual',
      'Smoke Test Partner',
      'Smoke Test Partner',
      '0900000000',
      '0900000000',
      v_tenant,
      v_tenant
    )
    on conflict (id) do nothing;

    perform partner.receive_integration_event(
      v_tenant,
      v_partner_event_id,
      'sales.order.checked_out',
      jsonb_build_object(
        'tenant_id', v_tenant::text,
        'business_partner_id', v_partner_id::text,
        'order_id', v_order_id::text,
        'order_code', 'SO-SMOKE-001',
        'amount', 250000,
        'status', 'completed',
        'transaction_date', '2026-06-30T10:00:00Z'
      ),
      now()
    );

    select claim_token
    into v_partner_claim_token
    from partner.claim_inbox_batch(v_tenant, 10)
    where message_id = v_partner_event_id;

    if v_partner_claim_token is null then
      raise exception 'partner claim_inbox_batch did not return claim_token';
    end if;

    perform partner.upsert_transaction_history(
      v_tenant,
      v_partner_id,
      'customer',
      'sales',
      'order',
      v_order_id,
      '2026-06-30T10:00:00Z'::timestamptz,
      'SO-SMOKE-001',
      250000,
      'completed',
      'Messaging smoke projection'
    );

    perform partner.complete_inbox_message(
      v_tenant,
      v_partner_event_id,
      v_partner_claim_token
    );

    select count(*)
    into v_history_count
    from partner.partner_transaction_histories
    where tenant_id = v_tenant
      and business_partner_id = v_partner_id
      and source_id = v_order_id;

    if v_history_count <> 1 then
      raise exception 'partner projection smoke failed: expected 1 row, got %', v_history_count;
    end if;
  end;

  raise notice 'messaging smoke test passed';
end;
$$;

rollback;
