# 2-B2 — Gửi email qua Edge Function `send-email`

> Phase: P2 · Bước (b) sửa / tính năng mới · Trạng thái: Plan ✅ | Làm ✅ | Review 🔄 (SQL ✅ 2026-10-12; `send-email` deploy ✅; Vault ✅ 2026-10-28 — đủ `project_url`, `email_webhook_secret`; chờ gửi mail lời mời thật khi kiểm tay)
> Gồm việc: 2A.4 (TH-01 KI-07)
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) 6.3, BR-40, BR-41, BR-46, BR-64, BR-66; US-06.2, US-06.3, US-02.3

## 1. Mục tiêu

Email lời mời nhân viên và mã đặt lại mật khẩu **được gửi thật** khi không còn `messaging_worker`:

```text
RPC (create/resend invitation, begin/resend password reset …)
  └─ iam.enqueue_outbox_message(…, 'iam.email.delivery_requested', …)   ← giữ nguyên lời gọi trong RPC
        └─ (sửa) ghi iam.email_jobs (status = queued) thay vì outbox_messages
             └─ trigger after insert ─ pg_net ─▶ Edge Function send-email
                   └─ Resend API ─▶ hộp thư
                   └─ iam.complete_email_job(...) : sent / failed, xoá mã khỏi job, cập nhật email_delivery_outcomes
pg_cron mỗi phút: gửi lại job queued / failed (≤ 5 lần) — lưới an toàn khi pg_net hoặc function lỗi
```

**Không đổi** chữ ký hay thân các RPC lời mời / đặt lại mật khẩu, cũng **không đổi app**: trạng thái gửi ("Đang xếp hàng gửi / Đã gửi email / Chưa gửi được email") vẫn đọc từ `iam.email_delivery_outcomes` như hiện tại.

**Ngoài phạm vi:** mã xác minh đăng ký (Supabase Auth tự gửi, 2-B1); SMTP riêng cho Auth; các sửa KI khác của TH-01 (→ **2-B3**); email nền tảng (`request_platform_password_reset`, P3 — tự chạy được nhờ cùng đường đi).

## 2. Hiện trạng

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Hàm outbox | `iam.enqueue_outbox_message(p_tenant_id, p_event_type, p_payload, p_message_id, p_occurred_at)` — sinh bằng `format()` trong `20260623000001_platform_messaging_foundation.sql` | Chỉ insert `iam.outbox_messages` (`tenant_id not null`) |
| Email trong outbox | `event_type = 'iam.email.delivery_requested'`, payload: `template_id`, `to_email`, `correlation_id`, `outcome_id`, `locale`, `refs`, `secret_payload_ciphertext = 'transient:' + base64(mã)` | 14 migration có chuỗi này; bản mới nhất của RPC: `create_tenant_invitation` (`20260916005`), `resend_tenant_invitation`, `begin_/resend_password_reset_operation`, `begin_password_reset_operation_by_email` (`20260826001`), `resend_password_reset_operation_by_email` (`20260811025`) |
| Trạng thái gửi | `iam.email_delivery_outcomes` (unique `correlation_id`, status `queued/sent/failed/bounced`), ghi qua `iam.record_email_delivery_outcome(...)` (upsert) | `get_tenant_invitation` / `list_tenant_invitations` đọc bảng này |
| Template cũ | `modules/iam/infrastructure/.../email_template_renderer.dart` | Rất sơ sài — viết lại theo TH-01 6.3 |
| Extension | `pgcrypto`, `supabase_vault` đã bật; **chưa** có `pg_net`, `pg_cron` | |
| Edge Function | Chưa có `supabase/functions/` | Đây là function đầu tiên (TH-08 `einvoice-processor` ở P7 dùng cùng mẫu) |
| Deno | Chưa cài trên máy | Cần để chạy / test function local (`brew install deno`) |
| Tên miền gửi | Chưa có (Resend chưa xác minh tên miền) | Tạm `onboarding@resend.dev` → **chỉ gửi được tới email tài khoản Resend** |

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/migrations/20261009003_iam_email_jobs.sql` | Tạo | Bảng `iam.email_jobs`; định nghĩa lại `iam.enqueue_outbox_message`; `iam._email_template_data`; `iam.claim_email_job`, `iam.complete_email_job` |
| `supabase/migrations/20261009004_iam_email_dispatch.sql` | Tạo | `pg_net`, `pg_cron`; trigger `iam._dispatch_email_job`; cron `iam.retry_email_jobs` |
| `supabase/functions/send-email/index.ts` | Tạo | Nhận `{job_id}`, claim, render, gọi Resend, complete |
| `supabase/functions/send-email/templates.ts` | Tạo | 2 template: `tenant_invitation`, `password_reset_code` |
| `supabase/functions/send-email/templates_test.ts` | Tạo | Test render (Deno) |
| `supabase/config.toml` | Sửa | `[functions.send-email] verify_jwt = false` |
| `supabase/tests/iam_email_jobs.sql` | Tạo | Kịch bản SQL (`begin … rollback`) |
| `supabase/migrations/REGISTRY.yaml` | Sửa | Thêm 2 migration |
| `docs/refactor/RUNBOOK-email.md` (hoặc mục trong README Supabase) | Tạo | Các bước cấu hình theo môi trường (Vault, secrets, deploy) |

## 4. Các bước

### Bước 1 — Bảng `iam.email_jobs`

```sql
create table if not exists iam.email_jobs (
  id uuid primary key,                         -- = p_message_id của RPC
  tenant_id uuid,                              -- null cho đặt lại mật khẩu
  template_id text not null,                   -- KHÔNG giới hạn bằng check: còn 'activation_invitation' (onboarding cũ, xoá ở 2-B3)
  to_email text not null,
  locale text not null default 'vi',
  correlation_id text not null,
  refs jsonb not null default '{}',
  template_data jsonb not null default '{}',   -- tên tổ chức, vai trò, hạn… (không chứa mã)
  secret jsonb,                                -- {"code": "..."}; null sau khi gửi xong / hết lượt
  status text not null default 'queued' check (status in ('queued', 'sending', 'sent', 'failed')),
  attempts int not null default 0,
  last_error text,
  provider_message_id text,
  claimed_at timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table iam.email_jobs enable row level security;   -- không policy: client không đọc được
grant usage on schema iam to service_role;              -- Edge Function gọi rpc bằng service_role; hiện schema iam chỉ cấp cho anon / authenticated
create index … on iam.email_jobs (status, created_at) where status in ('queued', 'failed');
```

### Bước 2 — Định nghĩa lại `iam.enqueue_outbox_message`

`create or replace function iam.enqueue_outbox_message(...)` **cùng chữ ký**, `security definer`, `set search_path = iam, platform, pg_temp`:

- `p_event_type = 'iam.email.delivery_requested'`:
  1. Giải mã `secret_payload_ciphertext`: bỏ tiền tố `transient:`, `convert_from(decode(…, 'base64'), 'UTF8')` → `v_code`. Không có hoặc sai dạng → `raise exception 'VALIDATION_ERROR: email secret'`.
  2. `insert into iam.email_jobs (id, tenant_id, template_id, to_email, locale, correlation_id, refs, template_data, secret) values (p_message_id, nullif(payload->>'tenant_id','')::uuid, …, iam._email_template_data(template_id, refs), jsonb_build_object('code', v_code))`.
  3. **Không** ghi `outbox_messages` (mã không còn nằm trong outbox — BR-64). `return p_message_id`.
- Sự kiện khác → giữ nguyên insert `outbox_messages` như bản gốc.

`iam._email_template_data(p_template_id text, p_refs jsonb) returns jsonb` (`stable`, `security definer`):
- `tenant_invitation` (`refs.invitation_id`): `tenant_name` (`tenants.display_name`), `role_label` (`role_definitions.label`), `inviter_name` (tên trong `platform_user_profiles` của người mời qua `invited_by_membership_id`; không có → `null`), `expires_at`.
- `password_reset_code`: `expires_in_minutes = 10`.
- Template khác (vd `activation_invitation` của onboarding cũ, 8 migration còn dùng): trả `{}`. Edge Function gặp template không biết → `complete_email_job(false, 'UNKNOWN_TEMPLATE')` (không ném lỗi ở DB, để RPC cũ không hỏng).
- Không tìm thấy dữ liệu → trả `{}` (không chặn RPC; template có câu dự phòng).

### Bước 3 — Claim / complete (gọi từ Edge Function)

```sql
iam.claim_email_job(p_job_id uuid) returns jsonb
```
`update iam.email_jobs set status = 'sending', claimed_at = now(), attempts = attempts + 1 where id = p_job_id and (status in ('queued','failed') or (status = 'sending' and claimed_at < now() - interval '5 minutes')) and attempts < 5 and secret is not null returning …` → trả `{id, template_id, to_email, locale, template_data, code}`; không claim được → `null` (job đã gửi / đang gửi / hết lượt).

```sql
iam.complete_email_job(p_job_id uuid, p_ok boolean, p_provider_message_id text, p_error text) returns void
```
- `p_ok`: `status = 'sent'`, `sent_at = now()`, `secret = null`, `provider_message_id`.
- Không ok: `status = 'failed'`, `last_error = left(p_error, 500)`; nếu `attempts >= 5` thì `secret = null` (hết lượt, không giữ mã).
- Luôn `perform iam.record_email_delivery_outcome(p_correlation_id := job.correlation_id, p_template_id := job.template_id, p_status := case when p_ok then 'sent' else 'failed' end, p_tenant_id := job.tenant_id, p_provider_message_id := …, p_error := …)`. Chỉ ghi `failed` vào outcome khi đã hết lượt; lỗi giữa chừng giữ `queued` để UI không báo "Chưa gửi được" quá sớm.
- Cả 2 hàm: `revoke all … from public, anon, authenticated; grant execute … to service_role`.

### Bước 4 — Gọi Edge Function khi có job (`20261009004`)

1. `create extension if not exists pg_net with schema extensions;` `create extension if not exists pg_cron;`
2. Hàm `iam._invoke_send_email(p_job_id uuid)`: đọc từ Vault `project_url` và `email_webhook_secret` (`select decrypted_secret from vault.decrypted_secrets where name = …`); thiếu một trong hai → `return` (không lỗi, cron sẽ gửi sau khi cấu hình xong); `perform net.http_post(url := v_url || '/functions/v1/send-email', headers := jsonb_build_object('Content-Type','application/json','x-email-webhook-secret', v_secret), body := jsonb_build_object('job_id', p_job_id))`.
3. Trigger `after insert on iam.email_jobs for each row execute function iam._dispatch_email_job()` → gọi `_invoke_send_email(new.id)`. **Bọc `begin … exception when others then null; end`** — gọi HTTP lỗi không được làm hỏng RPC tạo lời mời.
4. `iam.retry_email_jobs()`: các job `queued` quá 1 phút, `failed` còn lượt, hoặc `sending` treo > 5 phút → `_invoke_send_email` (tối đa 20 job / lần).
5. `select cron.schedule('iam-retry-email-jobs', '* * * * *', 'select iam.retry_email_jobs()');` — viết sao cho chạy lại migration không tạo trùng (`cron.unschedule` nếu đã có).

`net.http_post` chỉ gửi **sau khi transaction commit**, nên RPC rollback thì không có email.

### Bước 5 — Edge Function `send-email`

`supabase/functions/send-email/index.ts` (Deno, `Deno.serve`):

1. Chỉ nhận `POST`; header `x-email-webhook-secret` phải bằng `Deno.env.get('EMAIL_WEBHOOK_SECRET')`, sai → 401.
2. `const { job_id } = await req.json()`.
3. Client `createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)` (2 biến có sẵn trong Edge Runtime); `rpc` vào schema `iam`: `supabase.schema('iam').rpc('claim_email_job', { p_job_id: job_id })`. `null` → trả 200 `{skipped: true}`.
4. Render `templates.ts` → `{subject, html, text}`.
5. `fetch('https://api.resend.com/emails', { method: 'POST', headers: { Authorization: 'Bearer ' + RESEND_API_KEY, 'Content-Type': 'application/json', 'Idempotency-Key': job.id }, body: JSON.stringify({ from: EMAIL_FROM, to: [job.to_email], subject, html, text }) })`.
6. OK → `complete_email_job(job_id, true, data.id, null)`; lỗi → `complete_email_job(job_id, false, null, '<status> <message>')`. Trả 200 kể cả khi Resend lỗi (đã ghi job; cron thử lại).
7. **Không log mã / nội dung email.** Chỉ log `job_id`, `template_id`, kết quả.

`schema('iam')` cần `iam` nằm trong `api.schemas` (đã có). Không cần `verify_jwt` vì gọi bằng secret riêng: `config.toml` → `[functions.send-email] verify_jwt = false`.

**Template** (`templates.ts`, tiếng Việt, HTML đơn giản + bản text; tên app tạm "Mosaic Retail" — đổi ở P10.5; lấy tên từ `Deno.env.get('APP_NAME') ?? 'Mosaic Retail'`):

| Template | Tiêu đề | Nội dung chính (TH-01 6.3) |
|---|---|---|
| `tenant_invitation` | "Lời mời tham gia `<tên tổ chức>` trên Mosaic Retail" | `<người mời>` mời bạn tham gia `<tên tổ chức>` với vai trò `<vai trò>`; **mã lời mời** (8 ký tự, chữ to, giãn cách); hạn 7 ngày (`<ngày giờ hết hạn>`); hướng dẫn: mở app ▸ "Kích hoạt tài khoản" ▸ nhập mã lời mời |
| `password_reset_code` | "Mã đặt lại mật khẩu Mosaic Retail" | Mã 6 số; hết hạn sau 10 phút, chỉ dùng 1 lần; "Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này." |

Escape HTML mọi giá trị từ DB (tên tổ chức, tên người mời). Dùng "mã lời mời" (thống nhất theo KI-13).

### Bước 6 — Kịch bản SQL

`supabase/tests/iam_email_jobs.sql` (`begin … rollback`):
1. Gọi `iam.enqueue_outbox_message(null-uuid, 'iam.email.delivery_requested', <payload password_reset_code có secret 'transient:'+base64('123456')>, gen_random_uuid())` → có 1 `email_jobs` `queued`, `secret->>'code' = '123456'`, **không** có dòng mới trong `outbox_messages`.
2. Sự kiện khác (`'iam.tenant.created'`) → vẫn vào `outbox_messages`, không vào `email_jobs`.
3. `claim_email_job` → trả mã; gọi lần 2 → `null`.
4. `complete_email_job(true)` → `status = 'sent'`, `secret is null`, outcome theo `correlation_id` = `sent`.
5. Job khác: 5 lần claim + `complete(false)` → lần 6 claim trả `null`, `secret is null`, outcome `failed`.
6. `has_function_privilege('authenticated', 'iam.claim_email_job(uuid)', 'execute')` = false.
7. Không có Vault secret → insert job vẫn thành công (trigger không ném).

### Bước 7 — Cấu hình môi trường (Dev; Prod ở P10)

Ghi vào `docs/refactor/RUNBOOK-email.md`, làm theo thứ tự:
1. Resend: tạo API key (Sending access). Chưa có tên miền → `EMAIL_FROM = "Mosaic Retail <onboarding@resend.dev>"` (chỉ gửi tới email tài khoản Resend). Có tên miền → `"Mosaic Retail <no-reply@mail.<tên-miền>>"`.
2. Sinh `EMAIL_WEBHOOK_SECRET` (chuỗi ngẫu nhiên ≥ 32 ký tự, vd `openssl rand -hex 32`).
3. **Bạn tự chạy** (không dán key vào chat): `supabase secrets set RESEND_API_KEY=… EMAIL_FROM="…" EMAIL_WEBHOOK_SECRET=… APP_NAME=Mosaic Retail`.
4. Vault (SQL Editor Dev): `select vault.create_secret('https://<ref>.supabase.co', 'project_url'); select vault.create_secret('<EMAIL_WEBHOOK_SECRET>', 'email_webhook_secret');`
5. `supabase db push` (2 migration) → `supabase functions deploy send-email` — **báo Claude chạy** (cần xác nhận). Nếu 2 migration của 2-B1 vẫn chưa push, chúng đi cùng lần push này (xem việc còn lại ở review 2-B1).

### Bước 8 — Test Edge Function

- `brew install deno` rồi `deno test supabase/functions/send-email/` — test `templates_test.ts`: đủ trường, escape HTML (`<b>` trong tên tổ chức), thiếu `inviter_name` vẫn ra câu dự phòng, không có `undefined` / `null` trong nội dung.
- (Tuỳ chọn) `supabase functions serve send-email` khi có Supabase local.

### Bước 9 — Commit

Gợi ý: (1) migration + test SQL; (2) Edge Function + template + test; (3) runbook + config.

## 5. Kiểm tra

- [ ] Kịch bản SQL Bước 6 chạy hết, không `raise`. Chưa chạy: Docker daemon không mở được lúc làm (`unix:///Users/macbook/.docker/run/docker.sock` không có).
- [x] `deno test` pass (5 test template).
- [x] `flutter test` toàn `apps/erp`: 1.424 pass / 61 fail — khớp mốc 2-B1, không lỗi mới.
- [ ] Kiểm tay trên Dev — **để sau khi mua tên miền và xác minh trên Resend** (quyết định 2026-10-09). Trước đó chỉ cần các mục tự động ở trên + deploy function; review đóng ở 🔄 cho tới khi kiểm xong:
  - [ ] "Quên mật khẩu" với email của bạn → nhận mã 6 số trong ~1 phút → đặt lại được.
  - [ ] Owner mời email của bạn (dùng tài khoản Owner khác) → nhận email có mã lời mời, tên tổ chức, vai trò; chi tiết lời mời hiện "Đã gửi email".
  - [ ] "Gửi lại" lời mời → email mới, mã cũ không dùng được (BR-41).
  - [ ] Table Editor `iam.email_jobs`: job đã gửi có `secret = null`; `iam.outbox_messages` không có dòng email mới.
  - [ ] Tạm đặt sai `RESEND_API_KEY` → job `failed`, `attempts` tăng theo cron; đặt lại đúng → lần thử kế tiếp gửi được.
- [ ] CHECKLIST: ghi chú "email qua Edge Function" cho ID-04, ID-15, ID-16.

## 6. Rủi ro / lưu ý

- **Mã nằm trong `email_jobs.secret` đến khi gửi xong** (tối đa 5 lần thử). Bảng bật RLS không policy, hàm đọc chỉ cấp cho `service_role`. Không log mã ở function, không trả mã ra RPC nào khác.
- **Trigger HTTP không được làm hỏng nghiệp vụ**: lỗi `pg_net` / thiếu Vault phải bị nuốt trong trigger; cron là đường dự phòng.
- **Gửi trùng**: claim theo trạng thái + `Idempotency-Key = job.id` ở Resend. Trigger và cron có thể cùng gọi một job; chỉ một lần claim thành công.
- **Chưa có tên miền**: Resend chỉ gửi tới email tài khoản Resend; người khác nhận lỗi 403 → job `failed`. Đó là giới hạn môi trường, không phải lỗi code.
- `pg_cron` chạy mỗi phút trên Dev — rất nhẹ; nếu cần tắt: `select cron.unschedule('iam-retry-email-jobs');`.
- Định nghĩa lại `iam.enqueue_outbox_message` ảnh hưởng **mọi** sự kiện IAM ghi outbox: nhánh không phải email phải giữ y nguyên bản gốc (so sánh với `20260623000001`).

## 7. Review

- Ngày, commit được review: 2026-10-09, working tree trên `31ea66cb3` (chưa commit).
- Kết quả: **Code đạt; chưa chạy trên DB và chưa gửi mail thật** → Review 🔄.
  - `20261009003`: nhánh không phải email của `enqueue_outbox_message` giữ y bản gốc (`20260623000001`); `create or replace` giữ nguyên quyền cũ. Giải mã `transient:` an toàn, thiếu trường → `VALIDATION_ERROR`. `_email_template_data` không bao giờ ném (lỗi → `{}`), template lạ (`activation_invitation`) không làm hỏng RPC cũ. Claim / complete đúng: tối đa 5 lần, xoá `secret` khi gửi xong hoặc hết lượt, outcome chỉ chuyển `failed` khi hết lượt. Quyền: `revoke` khỏi client, `grant` cho `service_role` + `usage` schema `iam`.
  - `20261009004`: lỗi `pg_net` / thiếu Vault bị nuốt trong trigger; `retry_email_jobs` giới hạn 20 job / phút; lịch cron `unschedule` trước khi tạo lại (chạy lại không trùng).
  - `send-email`: so secret thời gian hằng, kiểm UUID, `Idempotency-Key = job.id`, lỗi mạng / template lạ đều ghi job `failed`, log không có mã / nội dung. `config.toml`: `verify_jwt = false`. `deno check` không lỗi; `deno test`: 5/5 pass (escape HTML, câu dự phòng, không còn `undefined`).
  - Kịch bản `supabase/tests/iam_email_jobs.sql`: đủ 7 trường hợp của Bước 6 — **chưa chạy** (không có Docker / Supabase local).
  - 2 migration **chưa có trên Dev**; function chưa deploy; secrets / Vault chưa đặt.
  - App không đổi → không chạy lại `flutter test` (mốc bạn ghi: 1.424 / 61).
- Việc còn lại để đóng review (gộp với việc còn lại của 2-B1):
  1. Chạy 2 kịch bản SQL (`iam_signup_trigger.sql`, `iam_email_jobs.sql`) cùng 4 migration trong `begin … rollback` trên Dev (`supabase db query --linked -f …`) — Claude chạy khi bạn đồng ý.
  2. `supabase db push` 4 migration (`20261009001…004`) → `config push` (2-B1) → đặt secrets + Vault theo `RUNBOOK-email.md` → `functions deploy send-email`.
  3. Sau khi có tên miền + Resend xác minh: kiểm tay mục 5.
- Góp ý:
  1. **Sửa (nhỏ, nên làm trước khi push):** `_email_template_data` ghép tên người mời `given_name` rồi `family_middle_name` → email hiện "Lan Nguyễn Thị". Đổi thứ tự `concat_ws(' ', family_middle_name, given_name)` → "Nguyễn Thị Lan" (cách hiển thị tên người Việt, giống app).
  2. Job `activation_invitation` (onboarding cũ) sẽ bị thử 5 lần rồi mới `failed` vì `UNKNOWN_TEMPLATE` coi như lỗi tạm. Không hại; hết khi 2-B3 xoá onboarding cũ. Nếu muốn gọn: `complete_email_job` nhận lỗi `UNKNOWN_TEMPLATE` thì đặt `attempts = 5` luôn.
  3. Thử lại không giãn cách (5 lần trong ~5 phút): Resend lỗi lâu hơn thì lời mời thành "Chưa gửi được email", Owner phải bấm "Gửi lại". Chấp nhận cho đồ án; ghi vào RUNBOOK.

### Cập nhật 2026-10-12 — đợt kiểm IAM

- `db reset --linked` trên Dev (sau bản sửa `activated_at`) rồi chạy 4 kịch bản trong SQL Editor — `iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_legacy_cleanup`: **cả 4 không raise** (người dùng chạy, 2026-10-12).
- `iam_email_jobs.sql` đạt: email event vào `email_jobs` (không vào outbox), mã giải được, claim / complete, thử lại 5 lần rồi `failed`, mẫu lạ fail ngay, quyền `claim_email_job` không cấp cho `authenticated`.
- Secrets Edge Function đã đặt (`RESEND_API_KEY`, `EMAIL_FROM` = "DSC ERP <no-reply@mail.dschienerp.me>", `EMAIL_WEBHOOK_SECRET`, `APP_NAME`).
- **Còn lại để đóng:** ghi Vault `project_url`, `email_webhook_secret` (sau lần reset cuối); `supabase functions deploy send-email`; Owner mời một email thật → nhận mail lời mời.
