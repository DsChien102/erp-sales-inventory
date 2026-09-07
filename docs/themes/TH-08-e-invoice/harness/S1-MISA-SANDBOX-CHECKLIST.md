# TH-08 S1 — Checklist kết nối MISA sandbox

Checklist này kiểm tra chuỗi thật `Vault → Supabase RPC/queue → messaging_worker → ERP`.
ERP không gọi HTTP MISA trực tiếp; sau khi lưu credential, trạng thái đúng phải là
`checkRequired` cho tới khi worker hoàn tất xác thực.

## 1. Database test

- [ ] Chạy lại toàn bộ [`theme8.sql`](../../../../theme8.sql) trên Supabase test.
- [ ] Trong **Project Settings → Data API → Exposed schemas**, thêm `einvoice`
  rồi lưu cấu hình. Tham chiếu: [Using Custom Schemas](https://supabase.com/docs/guides/api/using-custom-schemas).
- [ ] Nếu ERP vẫn báo `PGRST106`, kiểm tra role `authenticator` có override
  `pgrst.db_schemas`; reset override hoặc thêm `einvoice` cùng toàn bộ schema đang
  dùng, sau đó reload cấu hình PostgREST.
- [ ] Xác nhận user đang đăng nhập thuộc đúng tenant và có permission
  `einvoice.manage_configuration`.
- [ ] Không grant các RPC `claim_*`, `complete_*`, `fail_*`,
  `read_provider_credentials` hoặc `record_connection_verified` cho
  `authenticated`; chúng chỉ dành cho `service_role`.

Nếu UI trả `NO_PERMISSION`, dừng tại đây và sửa membership/permission của user;
đây chưa phải lỗi tài khoản MISA.

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
- [ ] Không đổi/rotate secret sau khi đã lưu credential MISA, trừ khi có quy trình
  giải mã và mã hóa lại toàn bộ ciphertext.

## 3. Worker environment

Sửa profile nguồn `.vet45/profiles/<profileId>/<env>.env`, không sửa trực tiếp
`apps/messaging_worker/.env*`:

```dotenv
SUPABASE_URL=https://<test-project-ref>.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<test-project-service-role-key>
WORKER_TICK_SECRET=<local-test-secret>
MISA_MEINVOICE_APP_ID=<misa-sandbox-app-id>
MISA_MEINVOICE_BASE_URL=https://testapi.meinvoice.vn/api/integration
```

Sau đó:

```bash
melos run env:sync -- --target worker
melos run env:doctor -- --target worker
melos run worker:serve
```

- [ ] Log startup có module `einvoice` trong `boundModules`.
- [ ] Worker dùng đúng Supabase test project và MISA test API.
- [ ] Không đưa `SUPABASE_SERVICE_ROLE_KEY` hay `WORKER_TICK_SECRET` vào ERP.

Để xử lý một vòng rồi thoát có thể dùng `melos run worker:once`.

## 4. ERP

```bash
melos run env:sync -- --target erp
melos run env:doctor -- --target erp
vet45 run erp debug
```

- [ ] Đăng nhập đúng user/tenant đã cấp `einvoice.manage_configuration`.
- [ ] Mở màn **Hóa đơn điện tử** như ảnh tham chiếu.
- [ ] Chạm thẻ **Kết nối MISA**.
- [ ] Mã số thuế lấy từ hồ sơ pháp lý tenant, không nhập tay.
- [ ] Nhập tài khoản/mật khẩu sandbox và chọn **Kết nối**.
- [ ] UI chuyển sang **Chờ kết nối**; không báo “Đã kết nối” ngay khi RPC vừa lưu
  credential.
- [ ] Chọn **Tải lại trạng thái**, hoặc quay lại màn Hóa đơn điện tử; màn overview
  phải tự tải lại.
- [ ] Worker thành công: thẻ MISA hiện **Đã kết nối** và chỉ hiện tài khoản đã che.
- [ ] Sai credential: trạng thái thành `reconnectRequired`, UI cho phép
  **Kết nối lại**.

## 5. Quan sát an toàn trong SQL Editor

Thay `<tenant-id>` bằng tenant đang test:

```sql
select tenant_id, status, last_verified_at, connection_version, updated_at
from einvoice.provider_connections
where tenant_id = '<tenant-id>'::uuid;

select command_type, enqueued_at, processed_at, failed_at, retry_count, error
from einvoice.internal_commands
where tenant_id = '<tenant-id>'::uuid
  and command_type = 'einvoice.sync_capabilities'
order by enqueued_at desc
limit 10;
```

Không query/log `provider_credentials.password_ciphertext`,
`read_provider_credentials` hoặc decrypted Vault secret để debug UI.

## 6. Cách phân loại lỗi

| Dấu hiệu | Kiểm tra trước |
| --- | --- |
| `PGRST106 Invalid schema: einvoice` | thêm `einvoice` vào Data API Exposed schemas; kiểm tra override `pgrst.db_schemas` |
| `NO_PERMISSION` | user, tenant membership, `einvoice.manage_configuration` |
| `einvoice_credential_key is missing` | Vault secret ở bước 2 |
| Queue còn `checkRequired`, chưa processed | worker đang chạy, đúng project, module `einvoice` đã bind |
| `reconnectRequired` | credential/App ID/MST sandbox và phản hồi auth từ MISA |
| Worker báo RPC permission | worker dùng service-role key; bundle SQL mới đã được chạy |
| Provider unavailable/timeout | MISA test API và network; giữ `checkRequired`, queue tự retry/backoff |
