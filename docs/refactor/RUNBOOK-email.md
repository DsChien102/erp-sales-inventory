# Runbook — gửi email (Edge Function `send-email`)

Email lời mời và mã đặt lại mật khẩu đi qua `iam.email_jobs` → `pg_net` → Edge Function `send-email` → Resend. App không đổi. Kiểm tay hộp thư làm sau khi tên miền đã xác minh trên Resend.

Thứ tự: Resend → secret → Vault → `db push` → deploy function. Không dán API key vào chat hoặc vào git.

## Dev (`pzlsjedtsntkarkivhve`)

1. Trên Resend, tạo API key quyền Sending. Chưa có tên miền thì người gửi là `VET45 <onboarding@resend.dev>` — Resend chỉ giao thư tới email của chính tài khoản Resend. Khi đã xác minh tên miền, đổi thành `VET45 <no-reply@mail.<tên-miền>>`.
2. Sinh secret webhook, ít nhất 32 byte:

   ```bash
   openssl rand -hex 32
   ```

3. Đặt secret của function (tự chạy, không dán giá trị vào chat):

   ```bash
   supabase secrets set \
     RESEND_API_KEY=… \
     EMAIL_FROM="VET45 <onboarding@resend.dev>" \
     EMAIL_WEBHOOK_SECRET=… \
     APP_NAME=VET45
   ```

4. Trong SQL Editor của project Dev, ghi Vault (cùng giá trị `EMAIL_WEBHOOK_SECRET` ở bước 3):

   ```sql
   select vault.create_secret('https://pzlsjedtsntkarkivhve.supabase.co', 'project_url');
   select vault.create_secret('<EMAIL_WEBHOOK_SECRET>', 'email_webhook_secret');
   ```

   Tên secret phải đúng `project_url` và `email_webhook_secret`. Thiếu một trong hai thì trigger không gọi HTTP; cron gửi lại sau khi Vault đủ.

5. Đẩy migration và function — hỏi trước khi chạy, vì `db push` ghi lên remote:

   ```bash
   supabase db push
   supabase functions deploy send-email
   ```

   `config.toml` đã tắt `verify_jwt` cho `send-email`. Function kiểm tra header `x-email-webhook-secret`. Nếu migration `20261009001` và `20261009002` (2-B1) chưa lên Dev, chúng đi cùng lần push này.

## Local

`supabase db reset` áp migration, gồm `pg_net`, `pg_cron` và lịch `iam-retry-email-jobs` (mỗi phút). Không có Vault secret thì job vẫn được tạo, trigger không lỗi, cron gửi sau khi cấu hình.

```bash
deno test supabase/functions/send-email/
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -v ON_ERROR_STOP=1 \
  -f supabase/tests/iam_email_jobs.sql
```

Serve function local khi cần:

```bash
supabase functions serve send-email --no-verify-jwt
```

## Prod

Không cấu hình trước P10. Cùng các bước Dev, với project `xodvjcaaxtubnkibmrmn` và tên miền đã xác minh.

## Vận hành

- Job đã gửi có `iam.email_jobs.secret` = null. Mã không còn trong `iam.outbox_messages`.
- Tối đa 5 lần thử. Lỗi giữa chừng giữ outcome `queued` ("Đang xếp hàng gửi"). Hết lượt thì outcome `failed` ("Chưa gửi được email").
- Tắt cron: `select cron.unschedule(jobid) from cron.job where jobname = 'iam-retry-email-jobs';`
