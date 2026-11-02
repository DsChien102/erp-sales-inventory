-- Title: Partner history rows for sales orders (trigger + backfill)
-- Kind: patch
-- Intent: partner_sales_order_history_trigger
-- Context: TH-03 US-07.2 / KI-02 / BR-31 — customer sales orders must write partner transaction history
-- Touches: _trg_sales_order_partner_history
-- Safety: idempotent ; trigger runs in the same transaction as the order write
-- Depends on: 20260830005_sales_rebuild_schema, 20260714004_partner_v2_write_rpc

-- 1) Trigger function
-- Partner không thuộc tenant: upsert_partner_history báo NOT_FOUND làm hỏng câu lệnh ghi đơn.
-- Đúng ý: sales đã kiểm khách (CUSTOMER_INVALID) trước khi ghi; nếu lọt thì dữ liệu sai, không được nuốt.
create or replace function partner._trg_sales_order_partner_history()
returns trigger
language plpgsql
security definer
set search_path = partner, pg_temp
as $$
begin
  -- Đổi khách (hoặc bỏ khách) của đơn: dòng lịch sử cũ không còn đúng.
  if tg_op = 'UPDATE'
     and old.customer_partner_id is not null
     and old.customer_partner_id is distinct from new.customer_partner_id then
    delete from partner.partner_history_views h
    where h.tenant_id = old.tenant_id
      and h.source_module = 'sales'
      and h.source_id = old.id;
  end if;

  if new.customer_partner_id is null then   -- Khách lẻ: không ghi (AC-02)
    return new;
  end if;

  perform partner.upsert_partner_history(
    new.tenant_id,
    new.customer_partner_id,
    'customer',
    'sales_order',
    'sales',
    new.id,
    new.order_code,
    new.completed_at,
    new.lifecycle_status,
    new.payable_amount_minor::numeric,
    new.currency_code,
    false
  );
  return new;
end;
$$;

-- 2) Trigger
drop trigger if exists trg_sales_orders_partner_history on sales.sales_orders;
create trigger trg_sales_orders_partner_history
  after insert or update of customer_partner_id, lifecycle_status, payable_amount_minor, order_code
  on sales.sales_orders
  for each row
  execute function partner._trg_sales_order_partner_history();

-- 3) Grants
revoke all on function partner._trg_sales_order_partner_history() from public, anon, authenticated;

-- 4) Bù đơn đã có trước khi có trigger (chạy lại không tạo dòng thứ hai)
insert into partner.partner_history_views (
  tenant_id, partner_id, role, transaction_type, source_module, source_id,
  reference_code, transaction_date, status, amount, currency, can_open_source
)
select o.tenant_id, o.customer_partner_id, 'customer', 'sales_order', 'sales', o.id,
       o.order_code, o.completed_at, o.lifecycle_status, o.payable_amount_minor::numeric,
       o.currency_code, false
from sales.sales_orders o
join partner.partners p
  on p.partner_id = o.customer_partner_id and p.tenant_id = o.tenant_id
where o.customer_partner_id is not null
on conflict (tenant_id, source_module, source_id) do nothing;
