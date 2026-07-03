-- Seed partner transaction history via inbox ingest (Epic-03 dev/smoke).
-- Prerequisite: existing partner row in partner.business_partners for tenant.
-- Usage: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/supabase/seed_partner_transaction_history_inbox.sql

-- Example tenant/partner ids — replace before running.
\set tenant_id '11111111-1111-4111-8111-111111111111'
\set partner_id 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'

begin;

select partner.receive_integration_event(
  :'tenant_id'::uuid,
  gen_random_uuid(),
  'sales.order.checked_out',
  jsonb_build_object(
    'tenant_id', :'tenant_id',
    'business_partner_id', :'partner_id',
    'order_id', gen_random_uuid(),
    'order_code', 'SO-DEV-001',
    'amount', 250000,
    'status', 'completed',
    'description', 'Dev seed order',
    'transaction_date', now()
  ),
  now()
);

commit;

-- After insert, run messaging_worker tick (service role) to drain partner inbox.
