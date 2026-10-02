-- Title: einvoice S2a — buyer completion and preview operations
-- Kind: patch
-- Intent: buyer_invoice_completions plus current invoice preview per order
-- Context: TH-08 EP-02/US-01; fake-seam — sales.* not yet available
-- Touches: einvoice.buyer_invoice_completions, einvoice.invoice_previews
-- Safety: idempotent (create if not exists), RLS enabled, tenant_id scoped
-- Depends on: 001_einvoice_configuration_schema.sql

-- Dữ liệu người mua bổ sung cho một đơn (tên, MST, email, địa chỉ) khi ảnh
-- chụp Theme 05 thiếu. Một dòng / đơn; ghi đè được tới khi đơn đã phát hành.
create table if not exists einvoice.buyer_invoice_completions (
  tenant_id uuid not null,
  sales_order_id uuid not null,
  sales_order_version text,
  buyer_name text,
  buyer_tax_code text,
  buyer_email text,
  buyer_address text,
  completed_by_user_id uuid not null,
  completed_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  primary key (tenant_id, sales_order_id)
);

alter table einvoice.buyer_invoice_completions enable row level security;
revoke all on einvoice.buyer_invoice_completions from anon, authenticated;

-- Bản xem trước hiện hành của một đơn (S3): mỗi yêu cầu ghi đè dòng và sinh
-- request_id mới; kết quả của yêu cầu cũ bị store_preview_result bỏ qua.
create table if not exists einvoice.invoice_previews (
  tenant_id uuid not null,
  sales_order_id uuid not null,
  request_id uuid not null,
  sales_order_version text,
  status text not null check (status in ('PENDING', 'READY', 'FAILED')),
  viewer_ref text,
  failure_code text,
  failure_message text,
  failure_source text
    check (failure_source is null or failure_source in ('PROVIDER', 'INTERNAL')),
  expires_at timestamptz not null,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  primary key (tenant_id, sales_order_id),
  check (status <> 'READY' or viewer_ref is not null),
  check (status <> 'FAILED' or failure_code is not null)
);

alter table einvoice.invoice_previews enable row level security;
revoke all on einvoice.invoice_previews from anon, authenticated;
