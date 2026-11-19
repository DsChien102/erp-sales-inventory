# TH-08 S1 — Checklist kết nối MISA sandbox

Checklist này kiểm tra chuỗi thật `Vault → RPC → hàng đợi HĐĐT → einvoice-processor (pg_cron / app) → MISA`.
ERP không gọi HTTP MISA trực tiếp; sau khi lưu credential, trạng thái đúng phải là `checkRequired` cho tới khi Edge Function `einvoice-processor` hoàn tất xác thực và đồng bộ mẫu hoá đơn.

## 1. Database test

- [ ] Toàn bộ migration HĐĐT đã được áp dụng lên Supabase Dev (theo [RUNBOOK-einvoice](../../../../refactor/RUNBOOK-einvoice.md) mục 3).
- [ ] Trong **Project Settings → Data API → Exposed schemas**, thêm `einvoice` rồi lưu cấu hình. Tham chiếu: [Using Custom Schemas](https://supabase.com/docs/guides/api/using-custom-schemas).
- [ ] Nếu ERP vẫn báo `PGRST106`, kiểm tra role `authenticator` có override `pgrst.db_schemas`; reset override hoặc thêm `einvoice` cùng toàn bộ schema đang dùng, sau đó reload cấu hình PostgREST.
- [ ] Xác nhận user đang đăng nhập thuộc đúng tenant và có permission `einvoice.manage_configuration`.
- [ ] Không grant các RPC `claim_*`, `complete_*`, `fail_*`, `read_provider_credentials`, `start_auto_delivery` hoặc `record_connection_verified` cho `authenticated`; chúng chỉ dành cho `service_role`.

Nếu UI trả `NO_PERMISSION`, dừng tại đây và sửa membership/permission của user; đây chưa phải lỗi tài khoản MISA.

## 2. Vault encryption key

Tham chiếu cách tạo/cập nhật secret: [Supabase Vault](https://supabase.com/docs/guides/database/vault).

Tạo một lần trong SQL Editor nếu secret chưa tồn tại:

```sql
select vault.create_secret(
  encode(gen_random_bytes(32), 'hex'),
  'einvoice_credential_key',
  'TH-08 MISA credential encryption key'
)
where not exists (
  select 1 from vault.secrets where name = 'einvoice_credential_key'
);
```

Chỉ kiểm tra metadata, không đọc `vault.decrypted_secrets` ra màn hình/log:

```sql
select id, name, description, created_at, updated_at
from vault.secrets
where name = 'einvoice_credential_key';
```

- [ ] Có đúng một row tên `einvoice_credential_key`.
- [ ] Không đổi/rotate secret sau khi đã lưu credential MISA, trừ khi có quy trình giải mã và mã hóa lại toàn bộ ciphertext.

## 3. Cấu hình Edge Function và pg_cron

Thực hiện theo [docs/refactor/RUNBOOK-einvoice.md](../../../../refactor/RUNBOOK-einvoice.md) mục 1–3:
1. Đặt secrets cho Edge Function: `MISA_MEINVOICE_APP_ID`, `MISA_MEINVOICE_BASE_URL`, `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED`.
2. Tạo 3 Vault secrets: `project_url`, `service_role_key` (legacy JWT), `einvoice_credential_key`.
3. Deploy function: `supabase functions deploy einvoice-processor`.

- [ ] Lịch cron `einvoice-processor-tick` được khởi tạo và chạy định kỳ mỗi 30 giây.
- [ ] Edge Function phản hồi HTTP 200 cho các lượt quét của cron.

## 4. ERP UI

```bash
melos run env:sync
c45 run erp debug
```

- [ ] Đăng nhập đúng user/tenant đã cấp `einvoice.manage_configuration`.
- [ ] Mở màn **Hóa đơn điện tử**.
- [ ] Chạm thẻ **Kết nối MISA**.
- [ ] Mã số thuế lấy từ hồ sơ pháp lý tenant, không nhập tay.
- [ ] Nhập tài khoản/mật khẩu sandbox và chọn **Kết nối**.
- [ ] UI chuyển sang **Chờ kết nối**; không báo “Đã kết nối” ngay khi RPC vừa lưu credential.
- [ ] Chọn **Tải lại trạng thái**, hoặc quay lại màn Hóa đơn điện tử; màn overview phải tự tải lại.
- [ ] Edge Function xử lý thành công: thẻ MISA hiện **Đã kết nối** và chỉ hiện tài khoản đã che.
- [ ] Sai credential: trạng thái thành `reconnectRequired`, UI cho phép **Kết nối lại**.

## 5. Kiểm phía server bằng SQL Editor

Thay `<tenant-id>` bằng tenant đang test:

### Bước 5.1: Kiểm tra kết nối và đồng bộ mẫu
Sau khi bấm Kết nối trên UI (hoặc gọi RPC `einvoice.connect_provider`):
```sql
select command_type, enqueued_at, claimed_at, processed_at, failed_at, retry_count, left(error, 100) as err
from einvoice.internal_commands
where tenant_id = '<tenant-id>'::uuid
  and command_type = 'einvoice.sync_capabilities'
order by enqueued_at desc
limit 5;
```
**Kỳ vọng:** có dòng `einvoice.sync_capabilities` và `processed_at` có giá trị trong ≤ 60 giây (do `pg_cron` gọi Edge Function).
Bảng `einvoice.provider_connections` chuyển trạng thái:
```sql
select status, last_verified_at, connection_version
from einvoice.provider_connections
where tenant_id = '<tenant-id>'::uuid;
```
**Kỳ vọng:** `status = 'CONNECTED'`.

### Bước 5.2: Bật chính sách phát hành và gửi tự động
```sql
update einvoice.tenant_settings
set auto_issue_enabled = true,
    auto_send_enabled = true
where tenant_id = '<tenant-id>'::uuid;
```
> [!NOTE]
> Trên sandbox testapi MISA, `supports_email_delivery` luôn là `false` (chỉ host `api.meinvoice.vn` mới hỗ trợ gửi email). Nếu chỉ muốn kiểm tra luồng phát hành tự động mà không muốn lệnh gửi thử lại 3 lần rồi ghi nhận `failed_at` (`DELIVERY_NOT_SUPPORTED`), có thể đặt `auto_send_enabled = false`.

### Bước 5.3: Tạo đơn hàng khách có email (Luồng phát hành & gửi tự động)
Tạo hoặc hoàn tất đơn bán hàng (`lifecycle_status = 'completed'`):
1. **Trigger xếp việc:**
   ```sql
   select id, command_type, enqueued_at, processed_at, failed_at
   from einvoice.internal_commands
   where tenant_id = '<tenant-id>'::uuid
     and command_type = 'einvoice.start_auto_issuance'
   order by enqueued_at desc limit 1;
   ```
   **Kỳ vọng:** có đúng 1 lệnh `einvoice.start_auto_issuance`.
2. **Tiến trình tự động:**
   ```sql
   select id, status, blocker_code, last_evaluated_at
   from einvoice.auto_issuance_processes
   where tenant_id = '<tenant-id>'::uuid
   order by created_at desc limit 1;
   ```
   **Kỳ vọng:** `status = 'ATTEMPT_STARTED'`.
3. **Phát hành và ghi hoá đơn:**
   Sau khi các lệnh `einvoice.preview_invoice` và `einvoice.publish_invoice` chạy xong, bảng `einvoice.electronic_invoices` có bản ghi mới:
   ```sql
   select id, invoice_number, invoice_series, issued_at
   from einvoice.electronic_invoices
   where tenant_id = '<tenant-id>'::uuid
   order by created_at desc limit 1;
   ```
4. **Trigger gửi tự động:**
   Hoá đơn mới chèn tự động kích hoạt trigger xếp việc `einvoice.start_auto_delivery`:
   ```sql
   select id, command_type, retry_count, left(error, 150) as error_preview, processed_at, failed_at
   from einvoice.internal_commands
   where tenant_id = '<tenant-id>'::uuid
     and command_type = 'einvoice.start_auto_delivery'
   order by enqueued_at desc limit 1;
   ```
   Kiểm tra bảng `einvoice.invoice_deliveries`:
   ```sql
   select id, delivery_intent, status, retry_count
   from einvoice.invoice_deliveries
   where tenant_id = '<tenant-id>'::uuid
   order by created_at desc limit 1;
   ```
   **Kỳ vọng theo từng trường hợp:**
   - **(a) testapi + `auto_send_enabled = true`:** việc `einvoice.start_auto_delivery` thất bại sau các lượt thử (`failed_at is not null`, `retry_count = 3`, `error` chứa `DELIVERY_NOT_SUPPORTED`); bảng `einvoice.invoice_deliveries` có **0 dòng**.
   - **(b) `auto_send_enabled = false`:** việc hoàn tất bình thường (`processed_at is not null`, `failed_at is null`) do bỏ qua theo chính sách (`POLICY_OFF`); bảng `einvoice.invoice_deliveries` có **0 dòng**.
   - **(c) Production (host `api.meinvoice.vn`) + `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=true` + khách có email:** việc hoàn tất (`processed_at is not null`); bảng `einvoice.invoice_deliveries` có **1 dòng** `delivery_intent = 'INITIAL_SEND'`, `status = 'SUCCEEDED'`.

### Bước 5.4: Khách tổ chức thiếu MST (Luồng đánh giá lại)
1. Bán hàng cho khách tổ chức chưa có MST:
   ```sql
   select id, status, blocker_code
   from einvoice.auto_issuance_processes
   where tenant_id = '<tenant-id>'::uuid
   order by created_at desc limit 1;
   ```
   **Kỳ vọng:** `status = 'PENDING_REEVALUATION'`, `blocker_code = 'BUYER_TAX_CODE_REQUIRED'`.
2. Bổ sung MST cho khách hàng trên app (hoặc cập nhật tăng `version` trên `partner.partners`):
   ```sql
   update partner.organization_profiles
   set tax_code = '0101234567'
   where partner_id = '<partner-id>'::uuid;

   update partner.partners
   set version = version + 1
   where partner_id = '<partner-id>'::uuid;
   ```
3. Trigger kích hoạt lệnh `einvoice.reevaluate_auto_issuance`:
   ```sql
   select id, command_type, processed_at, failed_at
   from einvoice.internal_commands
   where tenant_id = '<tenant-id>'::uuid
     and command_type = 'einvoice.reevaluate_auto_issuance'
   order by enqueued_at desc limit 1;
   ```
   **Kỳ vọng:** tiến trình `auto_issuance_processes` chuyển từ `PENDING_REEVALUATION` sang `ATTEMPT_STARTED`.

### Bước 5.5: Kiểm tra các việc hỏng / thất bại
```sql
select command_type, retry_count, left(error, 150) as error_preview, failed_at
from einvoice.internal_commands
where tenant_id = '<tenant-id>'::uuid
  and failed_at is not null
order by failed_at desc
limit 10;
```

## 6. Cách phân loại lỗi

| Dấu hiệu | Kiểm tra trước |
| --- | --- |
| `PGRST106 Invalid schema: einvoice` | Thêm `einvoice` vào Data API Exposed schemas; kiểm tra override `pgrst.db_schemas` |
| `NO_PERMISSION` | User, tenant membership, quyền `einvoice.manage_configuration` |
| `einvoice_credential_key is missing` | Vault secret `einvoice_credential_key` ở bước 2 |
| Queue còn `checkRequired`, chưa processed sau 60s | Kiểm tra `cron.job` `einvoice-processor-tick`, Vault `project_url` và `service_role_key` (legacy JWT); xem `net._http_response` |
| `reconnectRequired` | Kiểm tra MST doanh nghiệp, tài khoản, mật khẩu sandbox và MISA App ID |
| Edge Function trả lỗi 403 `service_role_required` | `service_role_key` trong Vault phải là legacy JWT (bắt đầu bằng `eyJ…`), không dùng key `sb_secret_…` |
| Provider unavailable/timeout | MISA test API bị chậm hoặc ngắt mạng; giữ `checkRequired`, queue tự retry/backoff |
