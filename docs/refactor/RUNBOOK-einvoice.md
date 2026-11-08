# Runbook — Hoá đơn điện tử (Edge Function einvoice-processor + pg_cron)

Kiến trúc xử lý nền HĐĐT (TH-08, 7-E3):
- App / Trigger xếp việc vào `einvoice.internal_commands`.
- Lịch `pg_cron` (`einvoice-processor-tick`) chạy mỗi 30 giây gọi `einvoice._invoke_processor()`.
- Hàm `_invoke_processor()` kiểm tra nếu có việc đến hạn thì dùng `pg_net` gửi HTTP POST tới Edge Function `einvoice-processor` kèm Bearer token `service_role`.
- Edge Function `einvoice-processor` thực hiện các tác vụ phát hành, gửi, đối soát, đồng bộ và tải tài liệu với MISA meInvoice.

> [!WARNING]
> Không dán API key, mật khẩu hoặc secret vào chat hoặc commit vào git.

## 1. Secrets của Edge Function `einvoice-processor`

Đặt secret cho Edge Function trên Dev (`pzlsjedtsntkarkivhve`):

```bash
supabase secrets set \
  MISA_MEINVOICE_APP_ID=… \
  MISA_MEINVOICE_BASE_URL=https://testapi.meinvoice.vn/api/integration \
  MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=false
```

Ý nghĩa các biến (theo TH-08 mục 6.1):
- `MISA_MEINVOICE_APP_ID`: App ID do MISA cấp cho đơn vị tích hợp.
- `MISA_MEINVOICE_BASE_URL`: Endpoint MISA integration (`https://testapi.meinvoice.vn/api/integration` cho sandbox, `https://api.meinvoice.vn/api/integration` cho production).
- `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED`: `true` / `1` để bật gửi email; chỉ có hiệu lực với host `api.meinvoice.vn` — trên testapi luôn coi là không hỗ trợ, dù đặt gì.

## 2. Vault Secrets trong Database

Trong SQL Editor của project Supabase (Dev: `pzlsjedtsntkarkivhve`), kiểm tra và tạo 3 secrets trong Supabase Vault:

1. **`project_url`**: URL của Supabase project (ví dụ `https://pzlsjedtsntkarkivhve.supabase.co`).
2. **`service_role_key`**: Khoá **legacy JWT** của role `service_role` (lấy từ Supabase Dashboard ▸ Project Settings ▸ API Keys ▸ Legacy API Keys).
   > [!IMPORTANT]
   > Khoá mới dạng `sb_secret_…` không phải là JWT, Edge Function sẽ trả lỗi 403 `service_role_required`. Phải dùng chuỗi JWT bắt đầu bằng `eyJ…`.
3. **`einvoice_credential_key`**: Khoá AES-256 (32 bytes hex) dùng để mã hoá mật khẩu tài khoản MISA trong bảng `einvoice.provider_credentials`.

Câu lệnh SQL thiết lập trong Vault:

```sql
select vault.create_secret('https://pzlsjedtsntkarkivhve.supabase.co', 'project_url')
where not exists (select 1 from vault.secrets where name = 'project_url');

select vault.create_secret('<LEGACY_SERVICE_ROLE_JWT>', 'service_role_key')
where not exists (select 1 from vault.secrets where name = 'service_role_key');

select vault.create_secret(
  encode(gen_random_bytes(32), 'hex'),
  'einvoice_credential_key',
  'TH-08 MISA credential encryption key'
)
where not exists (select 1 from vault.secrets where name = 'einvoice_credential_key');
```

Kiểm tra metadata:

```sql
select id, name, description, created_at, updated_at
from vault.secrets
where name in ('project_url', 'service_role_key', 'einvoice_credential_key');
```

## 3. Triển khai lên Dev (Hỏi người dùng trước khi chạy)

Vì đợt refactor có cập nhật các migration gốc (`20261031008`, `20261031013`) và thêm migration cron mới (`20261108001`), áp dụng bằng:

```bash
supabase db reset --linked
supabase functions deploy einvoice-processor
```

## 4. Kiểm tra Vận hành

Sau khi deploy, kiểm tra trong SQL Editor:

1. **Kiểm tra lịch cron:**
   ```sql
   select jobid, jobname, schedule, active, command
   from cron.job
   where jobname = 'einvoice-processor-tick';
   ```
   Kỳ vọng: có 1 dòng, `schedule = '30 seconds'`, `active = true`.

2. **Kiểm tra nhật ký chạy cron:**
   ```sql
   select jobid, runid, job_pid, status, return_message, start_time, end_time
   from cron.job_run_details
   where jobid = (select jobid from cron.job where jobname = 'einvoice-processor-tick')
   order by start_time desc
   limit 5;
   ```

3. **Kiểm tra phản hồi HTTP từ `pg_net`:**
   ```sql
   select id, status_code, error_msg, created, left(content, 200) as response_preview
   from net._http_response
   order by created desc
   limit 5;
   ```
   Kỳ vọng: `status_code = 200`, `response_preview` chứa JSON thống kê lượt xử lý batch của function.

4. **Kiểm tra hàng đợi công việc HĐĐT:**
   ```sql
   select command_type, enqueued_at, claimed_at, processed_at, failed_at, retry_count, left(error, 100) as err
   from einvoice.internal_commands
   order by enqueued_at desc
   limit 10;
   ```

## 5. Tắt tạm và Bật lại Lịch Cron

Khi cần tạm dừng xử lý tự động (ví dụ trong lúc bảo trì hoặc chạy script can thiệp dữ liệu):

```sql
-- Tắt tạm:
select cron.unschedule('einvoice-processor-tick');

-- Bật lại (chu kỳ 30 giây):
select cron.schedule(
  'einvoice-processor-tick',
  '30 seconds',
  $$select einvoice._invoke_processor()$$
);
```

## 6. Môi trường Local

- Khi chạy `supabase start` hoặc `supabase db reset`, migration `20261108001` sẽ tự động tạo extension `pg_net`, `pg_cron` và job `einvoice-processor-tick`.
- Nếu chưa cấu hình Vault secrets `project_url` / `service_role_key`, hàm `_invoke_processor()` sẽ tự kiểm tra và thoát ngay mà không sinh lỗi.
- Kiểm thử suite Edge Function:
  ```bash
  deno test supabase/functions/einvoice-processor
  ```
- Kiểm thử SQL contracts:
  ```bash
  psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql
  ```
- Chạy Edge Function local:
  ```bash
  supabase functions serve einvoice-processor
  ```

