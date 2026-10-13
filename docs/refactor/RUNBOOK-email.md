# Runbook — gửi email

Hai đường gửi, cùng tên miền **`mail.dschienerp.me`** (Namecheap, Resend region Tokyo), người gửi **`DSC ERP <no-reply@mail.dschienerp.me>`**:

| Email | Ai gửi | Cấu hình |
|---|---|---|
| Mã xác minh đăng ký (6 số) | Supabase Auth qua SMTP Resend | `supabase/config.toml` `[auth.email.smtp]` + template `supabase/templates/confirmation.html` |
| Lời mời nhân viên, mã đặt lại mật khẩu | `iam.email_jobs` → `pg_net` → Edge Function `send-email` → API Resend | secrets của function + Vault |

Không dán API key vào chat hoặc vào git.

## 0. Tên miền trên Resend (đã thêm 2026-10-11, chờ Verified)

Bản ghi khai ở Namecheap ▸ `dschienerp.me` ▸ **Advanced DNS** ▸ Host Records (Host chỉ nhập phần ngắn; không cần MX):

| Loại | Host | Giá trị |
|---|---|---|
| TXT | `resend._domainkey.mail` | chuỗi DKIM `p=…` chép nguyên từ Resend |
| CNAME | `rsend.mail` | `rsend-apne1.forge.rmta.net` |
| CNAME | `send.mail` | `send.forge.rmta.net` |
| TXT | `_dmarc` | `v=DMARC1; p=none;` |

Kiểm: `dig +short CNAME send.mail.dschienerp.me @dns1.registrar-servers.com` (nameserver Namecheap) rồi `@1.1.1.1`. Đủ thì bấm **Verify** trên Resend.

## 1. Supabase Auth dùng SMTP Resend

1. Resend ▸ API Keys ▸ tạo key `erp-dev`, quyền **Sending access**, domain `mail.dschienerp.me`.
2. Ghi key vào `supabase/.env` (đã gitignore; CLI đọc file này khi gặp `env(...)` trong `config.toml`):

   ```bash
   echo 'RESEND_SMTP_PASS=re_…' >> supabase/.env
   ```

3. Áp lên Dev bằng **một** trong hai cách:
   - Dashboard ▸ Authentication ▸ Emails ▸ SMTP Settings: Host `smtp.resend.com`, Port `465`, User `resend`, Password = key, Sender `no-reply@mail.dschienerp.me`, Name `DSC ERP`; Rate Limits ▸ email = 30/h; **hoặc**
   - `supabase config push` (hỏi trước — áp ngay; đẩy luôn bật xác minh email, template, hạn mức 30/h). Đợt kiểm IAM dùng cách này.
4. Local: khối SMTP bật thì `supabase start` cũng gửi thật qua Resend. Muốn đọc thư ở Mailpit (`http://127.0.0.1:54324`) thì tạm đặt `enabled = false`.

## 2. Edge Function `send-email` — Dev (`pzlsjedtsntkarkivhve`)

1. Dùng lại API key ở mục 1 (hoặc tạo key riêng `erp-dev-function`).
2. Sinh secret webhook, ít nhất 32 byte:

   ```bash
   openssl rand -hex 32
   ```

3. Đặt secret của function (tự chạy, không dán giá trị vào chat):

   ```bash
   supabase secrets set \
     RESEND_API_KEY=… \
     EMAIL_FROM="DSC ERP <no-reply@mail.dschienerp.me>" \
     EMAIL_WEBHOOK_SECRET=… \
     APP_NAME="DSC ERP"
   ```

4. Trong SQL Editor của project Dev, ghi Vault (cùng giá trị `EMAIL_WEBHOOK_SECRET` ở bước 3):

   ```sql
   select vault.create_secret('https://pzlsjedtsntkarkivhve.supabase.co', 'project_url');
   select vault.create_secret('<EMAIL_WEBHOOK_SECRET>', 'email_webhook_secret');
   ```

   Tên secret phải đúng `project_url` và `email_webhook_secret`. Thiếu một trong hai thì trigger không gọi HTTP; cron gửi lại sau khi Vault đủ.

5. Đưa migration và function lên Dev — hỏi trước khi chạy. Đợt kiểm IAM dùng `db reset --linked` (đã sửa migration gốc, xem PLAN "Quy tắc migration"); về sau, khi chỉ thêm migration mới, dùng `db push`:

   ```bash
   supabase db reset --linked
   supabase functions deploy send-email
   supabase functions deploy invitation-signup
   ```

   `config.toml` đã tắt `verify_jwt` cho cả hai function. `send-email` kiểm tra header `x-email-webhook-secret`. `invitation-signup` (2-B5: nhân viên chưa có tài khoản nhận lời mời bằng một mã) không cần secret mới — `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` do Supabase cấp sẵn. Nếu migration `20261009001` và `20261009002` (2-B1) chưa lên Dev, chúng đi cùng lần push này.

## Local

`supabase db reset` áp migration, gồm `pg_net`, `pg_cron` và lịch `iam-retry-email-jobs` (mỗi phút). Không có Vault secret thì job vẫn được tạo, trigger không lỗi, cron gửi sau khi cấu hình.

```bash
deno test supabase/functions/send-email/ supabase/functions/invitation-signup/
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
  -v ON_ERROR_STOP=1 \
  -f supabase/tests/iam_email_jobs.sql
```

Serve function local khi cần:

```bash
supabase functions serve send-email --no-verify-jwt
supabase functions serve invitation-signup --no-verify-jwt   # khi chạy app với Supabase local
```

## Prod

Không cấu hình trước P10. Cùng các bước Dev, với project `xodvjcaaxtubnkibmrmn`; tạo API key riêng `erp-prod` trên cùng tên miền.

## Vận hành

- Job đã gửi có `iam.email_jobs.secret` = null. Mã không còn trong `iam.outbox_messages`.
- Tối đa 5 lần thử. Lỗi giữa chừng giữ outcome `queued` ("Đang xếp hàng gửi"). Hết lượt thì outcome `failed` ("Chưa gửi được email").
- Tắt cron: `select cron.unschedule(jobid) from cron.job where jobname = 'iam-retry-email-jobs';`
