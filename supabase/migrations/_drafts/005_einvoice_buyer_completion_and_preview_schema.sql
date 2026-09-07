-- Title: einvoice S2a — buyer completion and preview operations
-- Kind: patch
-- Intent: buyer_invoice_completions plus technical invoice preview operation
-- Context: TH-08 EP-02/US-01; fake-seam — sales.* not yet available
-- Touches: einvoice.buyer_invoice_completions, einvoice.invoice_preview_operations
-- Safety: idempotent (create if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_configuration_schema.sql

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

create table if not exists einvoice.invoice_preview_operations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  version bigint not null default 0,
  provider_connection_id uuid not null
    references einvoice.provider_connections(id),
  sales_order_id uuid not null,
  correlation_id uuid not null,
  order_version varchar(100) not null,
  status text not null default 'PENDING'
    check (status in ('PENDING','READY','FAILED','SUPERSEDED')),
  viewer_ref text null,
  preview_payload jsonb null,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, correlation_id)
);

alter table einvoice.invoice_preview_operations enable row level security;
revoke all on einvoice.invoice_preview_operations from anon, authenticated;
