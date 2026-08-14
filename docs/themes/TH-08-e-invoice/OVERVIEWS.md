# TH-08 OVERVIEWS — Hóa đơn điện tử

## Purpose

Cho phép doanh nghiệp (tenant) phát hành và quản lý hóa đơn điện tử tuân thủ quy định Việt Nam, thông qua tích hợp **MISA meInvoice**, mà không để ERP client gọi vendor API trực tiếp.

## Scope (MVP hướng tới)

**In scope (đầu ra):**

- Cấu hình kết nối meInvoice per tenant (`appId`, MST, tài khoản, mật khẩu — persist bảo mật)
- Đồng bộ / chọn mẫu số–ký hiệu (`listTemplates`)
- Phát hành HĐ (`publish`), tra cứu trạng thái (`getStatus`), tải XML/PDF (`download`)
- Hàng đợi bền (outbox / internal command) → xử lý trên messaging worker

**Out of scope (phase sau / theme khác):**

- meInvoice hóa đơn đầu vào
- MISA ACT / ASP / CRM
- Chi tiết ký số HSM/USB trên client
- Ghi sổ kế toán / tờ khai thuế (không thuộc TH-08 theo catalog mới)

## Epic map (placeholder)

| Epic | Ý định | Status |
| ---- | ------ | ------ |
| EP-01 — Kết nối vendor & credential | Lưu/kiểm tra kết nối meInvoice per tenant | planned |
| EP-02 — Phát hành & theo dõi HĐĐT | Publish, status, download, idempotency | planned |

Chi tiết US/FR khi theme `in_progress`.

## Quyết định kiến trúc đã chốt

Xem [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md):

1. Credential = tài khoản meInvoice của DN; MST từ cấu hình pháp lý tenant; secret persist encrypted.
2. Chỉ messaging worker gọi MISA (single service hiện tại).
3. Bearer token cache **theo `tenantId`** — không singleton cross-tenant.
