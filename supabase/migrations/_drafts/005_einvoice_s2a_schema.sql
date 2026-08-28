-- Title: einvoice S2a — buyer completion table + preview handoff columns
-- Kind: patch
-- Intent: buyer_invoice_completions per §4.4.3; extend provider_interaction_records for preview handoff (NO new business table)
-- Context: TH-08 EP-02/US-01; fake-seam — sales.* not yet available
-- Touches: einvoice.buyer_invoice_completions, einvoice.provider_interaction_records
-- Safety: idempotent (create/alter if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_s1_schema_configuration.sql

-- buyer_invoice_completions per canonical §4.4.3 (process entity, one of the 12 sanctioned).
-- NOTE: stores eligible_fields + resolved_values, NOT the runtime EffectiveBuyerInvoiceData.
create table if not exists einvoice.buyer_invoice_completions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  sales_order_id uuid not null,
  sales_order_version varchar(100) not null,
  buyer_partner_id uuid not null,
  status text not null default 'open',              -- open | locked
  eligible_fields jsonb not null default '[]',      -- required fields missing in BuyerInvoiceSnapshot, allowed to complete
  resolved_values jsonb not null default '{}',      -- controlled-completion values for eligible fields
  source_partner_revision varchar(100),
  source_partner_updated_at timestamptz,
  last_resolved_at timestamptz,
  locked_at timestamptz,
  version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, sales_order_id, sales_order_version)
);
alter table einvoice.buyer_invoice_completions enable row level security;

-- Preview handoff rides on the shared technical record provider_interaction_records (§4.3.5) —
-- NO new business table. S1 created a minimal version; extend it for preview target/status/result.
alter table einvoice.provider_interaction_records
  add column if not exists sales_order_id uuid,
  add column if not exists correlation_id uuid,
  add column if not exists order_version varchar(100),
  add column if not exists status text not null default 'pending',  -- pending | ready | failed
  add column if not exists viewer_ref text,                          -- transient; NFR-06: short-lived, not fully logged
  add column if not exists expires_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

create index if not exists provider_interaction_preview_idx
  on einvoice.provider_interaction_records
     (tenant_id, sales_order_id, interaction_type, created_at desc);
