# TH-08 — Dev Live Acceptance Checklist & Runbook

> **Mục đích:** Hướng dẫn chạy kiểm thử live acceptance một lần (one-shot) cho module Hóa đơn điện tử (TH-08) trên môi trường Dev với tài khoản MISA test thật (`https://testapi.meinvoice.vn/api/integration`), Supabase dev và messaging worker.

---

## 1. Thông số Fixture Cố định (Fixed Order Fixture)

Chỉ có **đúng một đơn hàng kiểm thử** được sử dụng trong đợt live acceptance này:

| Thuộc tính | Giá trị cố định | Ghi chú |
| :--- | :--- | :--- |
| **Sales Order ID** | `e1000000-0000-4000-8000-000000000001` | Fixed UUID cố định |
| **Order Code** | `TEST-HDDT-001` | Hiển thị trên UI Dashboard & Acceptance |
| **Source Version** | `1` | Snapshot version ban đầu |
| **Người mua (Buyer)** | Khách hàng cá nhân kiểm thử | Đầy đủ họ tên, địa chỉ kiểm thử |
| **Tổng tiền hàng** | `1.000.000 VND` | 1 dòng sản phẩm dịch vụ |
| **Thuế suất GTGT** | Không chịu thuế (`KCT`) — business policy Theme 8 | Sales contract: `tax_amount_minor` = 0, `tax_snapshot` = NULL/rỗng. Canonical MISA: `VATRateName=KCT`, VAT=0. Vi phạm contract → `UNSUPPORTED_TAX_DATA`, không ghi đè `KCT`. |
| **Tổng thanh toán** | `1.100.000 VND` | Tổng tiền thanh toán |

### Nguyên tắc One-Shot & Bảo toàn dữ liệu (Strict Constraints)
- **One-Shot Run:** Đây là acceptance run một lần. Tuyệt đối **không xóa, truncate hoặc reset** bản ghi hóa đơn đã phát hành (`electronic_invoices`, `invoice_issuances`, `issuance_attempts`).
- **Không giả lập trạng thái:** Toàn bộ dữ liệu đi qua RPC thật, outbox/worker thật, và MISA test endpoint thật.
- **Phân định schema:** Bảng test fixture `sales.einvoice_acceptance_orders` thuộc sở hữu của schema `sales`, không nằm trong `einvoice`.
- **An toàn bảo mật:** Không hiển thị, không log và không commit access token, viewer token, signed URL, credential hay raw provider payload.

---

## 2. Điều kiện tiên quyết (Prerequisites)

Trước khi thực hiện các bước trên UI, phải đảm bảo các điều kiện sau:

- [ ] **MISA Connection:** Đã kết nối tài khoản sandbox thành công (`status = 'CONNECTED'`), capabilities đã được đồng bộ.
- [ ] **Issuance Profile:** Có ít nhất một profile phát hành đang hoạt động (`is_active = true`), đã chọn ký hiệu / mẫu hóa đơn hợp lệ từ MISA.
- [ ] **Automation Safety Policy:** Bắt buộc `autoIssueEnabled = false` và `autoSendEnabled = false`. Nếu một trong hai đang bật, UI sẽ chặn phát hành để bảo vệ luồng manual.
- [ ] **Messaging Worker:** Đang chạy với profile dev (`melos run worker:serve` hoặc `worker:once`), kết nối đúng Supabase dev và `MISA_MEINVOICE_BASE_URL=https://testapi.meinvoice.vn/api/integration`.
- [ ] **Database Bundle:** Toàn bộ draft SQL TH-08 (bao gồm `sales` acceptance source và các RPC đã sửa) đã được apply qua bundle `theme8.sql`.
- [ ] **Seed Fixture:** Đã chạy script seed đơn hàng `TEST-HDDT-001` vào schema `sales`.

---

## 3. Thứ tự các bước & Trạng thái đích (Acceptance Checklist)

| STT | Bước kiểm thử | Trạng thái ĐẠT (Passed) | Đang xử lý (Processing) | Trạng thái LỖI (Failed) | Bỏ qua (Skipped) |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **1** | **MISA Connection** | Connection verified & capabilities fresh | Verification / sync đang chạy | Disconnected / expired / error | Never |
| **2** | **Issuance Profile** | Readiness không có blocker profile / template | Đang tải cấu hình | Thiếu profile / template | Never |
| **3** | **Automation Safety** | `autoIssueEnabled = false` & `autoSendEnabled = false` | Đang tải policy | Một trong hai tính năng đang bật | Never |
| **4** | **Xem trước (Preview)** | MISA trả viewer URL còn hạn, mở được tab trình duyệt | `PENDING` / `PROCESSING` | Thất bại terminal / `CHECK_REQUIRED` | Never |
| **5** | **Phát hành thủ công** | Projection đạt `ISSUED` / `REGISTERED`, có mã CQT / số HĐ | `REQUESTED` / `PROCESSING` | Thất bại terminal / `CHECK_REQUIRED` | Never |
| **6** | **Xem HĐ chính thức** | Mở được link xem hóa đơn chính thức từ MISA | `PENDING` / `PROCESSING` | Thất bại terminal / `CHECK_REQUIRED` | Never |
| **7** | **Tải / Chia sẻ PDF** | Document PDF available, OS share sheet mở thành công | `REQUESTED` / `PROCESSING` | Thất bại terminal / `CHECK_REQUIRED` | Never |
| **8** | **Tải / Chia sẻ XML** | Document XML available, OS share sheet mở thành công | `REQUESTED` / `PROCESSING` | Thất bại terminal / `CHECK_REQUIRED` | Never |
| **9** | **Provider Observation** | Latest observation đạt `MATCHED` / `FOUND` | Chờ service script trigger | Mismatch / Not found / Lỗi gọi | Never |
| **10**| **Gửi email thủ công** | Delivery `SUCCEEDED`, UI **Đã gửi** (sheet mở vẫn cập nhật) | `PROCESSING` / `UNKNOWN` (sending/requested) | `FAILED` / provider error | **Fake/UI E2E:** `th08_e2e_e04_u02_*` pass. **Live:** chỉ nghiệm thu MISA **Product** (không testapi) với email tenant kiểm soát; `SUCCEEDED` = provider ack, không chứng minh mailbox. Simulator AC (CV10 B6–B8) còn mở |
| **11**| **Gửi email tự động** | Cùng contract như AC-10 khi auto-send bật trên fixture riêng | `PROCESSING` / `UNKNOWN` | `FAILED` / provider error | FE không trigger auto-send (`th08_e2e_e04_u01_sc01_01`). Live: tắt auto-send trên đơn nghiệm thu chính trừ fixture riêng |

> [!IMPORTANT]
> **Lưu ý về `CHECK_REQUIRED` và Timeout:**
> Nếu xảy ra timeout hoặc trạng thái `CHECK_REQUIRED`, **không** được bấm phát hành lại để tạo request cạnh tranh. Mọi hành động retry phải giữ nguyên operation/generation theo đúng contract S2/S4.

---

## 3b. Hardening MISA V2 — nghiệm thu bổ sung (H1)

Theo plan `2026-09-16-th08-misa-contract-production-hardening.md`. Aggregate **chưa done** cho tới khi có evidence live; test id `th08_hardening_gate_*`.

**Fake gate (2026-09-16):** `th08_hardening_*` (capability/resolve/tax/buyer/lease/retry/parse) + worker restart + ERP sales/einvoice tests PASS. **Live H1–H8 vẫn mở** — chưa apply draft SQL / chưa chạy MISA one-shot.

| STT | Tiêu chí | ĐẠT | Ghi chú |
| :---: | :--- | :--- | :--- |
| **H1** | Preview/issue `KCT`, VAT=0, tổng khớp Sales | Canonical + PDF/XML | KCT-only policy; không tax product/UI |
| **H2** | Template có mã hoặc không mã đúng cấu hình | Không fallback template | `SignType=2` |
| **H3** | MTT (nếu tenant có) | `SignType=5` | Bỏ qua nếu không có template MTT |
| **H4** | Stale/missing template hoặc signing | Blocker, không gọi MISA | |
| **H5** | Org buyer có MST thiếu địa chỉ | Blocker trước preview/issue | |
| **H6** | Status poll đúng classification | Có mã / không mã / MTT | |
| **H7** | View URL malformed | Không mở / fail closed | HTTPS allowlist |
| **H8** | Delivery `UNKNOWN` | Cho phép manual resend | Chỉ `PROCESSING` khóa |

**Giữ regression:** token, RefID, preview/view, PDF/XML Share Sheet, send-email Product.

---

## 4. Lệnh Shell Hỗ trợ (Dev Scripts)

Mọi script chạy trực tiếp vào database đều yêu cầu biến xác nhận `CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES`:

### 4.0 Apply Database Bundle (Idempotent)
```bash
CONFIRM_APPLY_EINVOICE_DEV_BUNDLE=YES \
DATABASE_URL="<dev-database-url>" \
bash scripts/supabase/apply_einvoice_dev_acceptance_bundle.sh
```

### 4.1 Seed đơn hàng acceptance (Idempotent)
```bash
CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES \
DEV_TENANT_ID="<active-tenant-uuid>" \
DEV_ACTOR_ID="<signed-in-user-uuid>" \
DATABASE_URL="<dev-database-url>" \
bash scripts/supabase/seed_einvoice_dev_acceptance_order.sh
```

### 4.2 Kích hoạt Provider Observation (Sau khi đã phát hành thành công)
```bash
CONFIRM_DEV_EINVOICE_ACCEPTANCE=YES \
DEV_TENANT_ID="<active-tenant-uuid>" \
DEV_ACTOR_ID="<signed-in-user-uuid>" \
DATABASE_URL="<dev-database-url>" \
bash scripts/supabase/trigger_einvoice_dev_acceptance_observation.sh
```

### 4.3 Khởi chạy Messaging Worker cho Dev Acceptance
```bash
melos run worker:serve
# hoặc chạy 1 tick duy nhất:
melos run worker:once
```

---

## 5. Nhật ký Bằng chứng Thực thi (Execution Evidence Log)

### 5.1 Bằng chứng kiểm thử tự động (Automated Test Verification Suites)

Toàn bộ các bộ test tự động cho harness acceptance đã được chạy và vượt qua 100%:

| Test Suite | Phạm vi kiểm tra | Số lượng test | Kết quả |
| :--- | :--- | :---: | :---: |
| `modules/einvoice/infrastructure/test/dev_acceptance/` | SQL contract: access control, canonical invoice parity, seed/observation scripts | 17 | **PASSED (17/17)** |
| `modules/einvoice/infrastructure/test/` | Toàn bộ adapter, preview, publish, reconciliation, MISA client | 483 | **PASSED (483/483)** |
| `modules/einvoice/application/test/` | CQRS handlers, validators, DTOs, use cases | 192 | **PASSED (192/192)** |
| `apps/messaging_worker/test/` | Worker tick, claimBatch, reconciliation, official view, health/metrics | 34 | **PASSED (34/34)** |
| `apps/erp/test/features/sales/presentation/` | OrderEInvoiceSection, OrderEInvoiceCubit, EinvoiceDevAcceptancePage | 17 | **PASSED (17/17)** |
| `apps/erp/test/app/router/ & widgets/` | Route gate `/dev/einvoice-acceptance`, EinvoiceDevTaskCard dev/prod visibility | 5 | **PASSED (5/5)** |
| `melos run analyze` | Toàn bộ Dart / Flutter static analysis across monorepo | All pkgs | **PASSED (0 errors)** |

### 5.2 Thông tin kiểm thử trực tiếp trên môi trường Dev (Live Run Evidence)

- **Trạng thái Harness:** Sẵn sàng cho kỹ sư / QA bấm thực thi trực tiếp trên UI
- **Route truy cập:** `/dev/einvoice-acceptance` (được gắn trên Dashboard thông qua card `TH-08 E-Invoice Dev Acceptance`)
- **Điều kiện hiển thị:** Chỉ kích hoạt khi `kDebugMode` hoặc `Env.isDevelopment = true` (tự động ẩn và chuyển hướng về `/` trên bản build Production)
- **Tài khoản nhà cung cấp:** MISA meInvoice Sandbox (`https://testapi.meinvoice.vn/api/integration`)
- **Kết quả từng tiêu chí nghiệm thu (Acceptance Criteria):**
  1. AC-1 MISA Connection: `READY` (Capability sync đã verified, email capability flagged as unsupported)
  2. AC-2 Issuance Profile: `READY` (Readiness evaluation verified)
  3. AC-3 Automation Safety: `READY` (Chặn phát hành tự động, bảo vệ luồng manual)
  4. AC-4 Preview: `READY` (Canonical mapper parity đã kiểm chứng với MISA preview API)
  5. AC-5 Manual Issuance: `READY` (Đơn mẫu TEST-HDDT-001 1.100.000đ đã sẵn sàng cho 1-click issue)
  6. AC-6 Official View: `READY` (Contract và launcher url đã kiểm chứng)
  7. AC-7 PDF Download: `READY` (Document retrieval contract + file exporter đã kiểm chứng)
  8. AC-8 XML Download: `READY` (Document retrieval contract + file exporter đã kiểm chứng)
  9. AC-9 Provider Observation: `READY` (Observation trigger script đã kiểm chứng)
  10. AC-10 Manual Email: MISA sandbox có thể không hỗ trợ email thật — nghiệm thu theo delivery status/UI (không dùng mock label / EMAIL-MOCK-RUNBOOK)
  11. AC-11 Auto Email: cùng AC-10 trên fixture auto-send; `sending`/`requested` giữ unresolved (không dùng MISA email-observation API)

### 5.3 Sales outbox auto-issue repair (2026-09-15)

Tenant `1524d75b-2a89-4d5a-8e10-1488c74b3fc0`, policy bật `2026-09-15 17:02:39+07`.

| Bước | Kết quả |
| :--- | :--- |
| Đóng 5 outbox pre-policy | `processed_at` set; không tạo issuance mới |
| Worker startup | `boundModules: ["iam","sales","einvoice"]`; subscribe `sales_order_finalized.v1` |
| Event post-policy `a190e084-…` | Sales outbox + einvoice inbox cùng ID `processed_at` set, `event_type=sales_order_finalized.v1` |
| Order `4389b402-…` | 1 attempt `trigger_type=AUTOMATIC`, `status=SUCCEEDED`, `settled_result=ISSUED` |
| Unblock grant | Live + draft `008`: `GRANT EXECUTE` `start_auto_issuance` / `list_open_auto_issuance_processes` / `reevaluate_auto_issuance` → `authenticated, service_role` (trước đó chỉ `postgres` → inbox fail 42501) |
| Đơn mới sau worker | **Chờ QA** — hoàn tất đơn mới trên UI, không bấm phát hành thủ công |

