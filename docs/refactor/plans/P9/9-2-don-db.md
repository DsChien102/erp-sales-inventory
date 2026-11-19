# 9-2 — Dọn DB: bỏ nền messaging `platform`, outbox `iam` / `einvoice`

> Dọn dẹp (P9) · Gồm việc 9.4 của PLAN.md mục "Dọn dẹp"
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-19) | Làm ✅ 2026-11-19 | Review ⬜
> Tài liệu: PLAN.md "Dọn dẹp" (9-2, 9.4), "Quy tắc migration", "Plan xoá / tách / thay code cũ"; 7-C Q3 (nền `platform` để P9); 8-C Q1 (giữ `sales.outbox_messages`); 3-B (onboarding / FK đã xong, test `supabase/tests/iam_legacy_cleanup.sql`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DB không còn nền messaging (`platform`, `costing`, `accounting`, `dashboard`, outbox / inbox / internal_commands của `iam`, outbox `einvoice`). Đường gửi email IAM giữ nguyên hành vi, đổi tên thành `iam.enqueue_email_job`.

**Architecture:** Sửa thẳng migration gốc (không gộp, không viết `drop` ở migration mới). Bỏ 3 file nền (`20260623000001`, `20260623000002`, `20260820008`). Nhánh email của `iam.enqueue_outbox_message` (`20261009003`) thành hàm riêng `iam.enqueue_email_job`. Nhánh còn lại (ghi `iam.outbox_messages`) bỏ cùng mọi chỗ gọi. Outbox `einvoice` bỏ, `einvoice.internal_commands` + 4 hàm hàng đợi giữ.

**Tech Stack:** Postgres / Supabase migrations (plpgsql), test SQL `supabase/tests/*.sql` (psql), test hợp đồng Dart đọc migration (`flutter test`).

**Spec:** thiết kế chốt trong chat 2026-11-19 (người dùng duyệt): mục 1–6 của "Thiết kế 9-2"; phương án B cho đường email.

## Global Constraints

- **Không đổi nghiệp vụ** ngoài các chỗ "đổi có chủ đích" ở mục 2. RPC app / Edge Function gọi giữ nguyên tên, tham số, kết quả.
- **Quy tắc migration:** sửa trong file migration gốc. Không tạo migration mới. File bị xoá ⇒ xoá luôn dòng trong `REGISTRY.yaml`.
- **Giữ:** `sales.outbox_messages` (8-C Q1), `einvoice.internal_commands` + `enqueue_internal_command`, `claim_internal_commands_batch`, `complete_internal_command`, `fail_internal_command`, `iam.idempotency_records` / `_idempotency_find` / `_idempotency_store` (RPC mời nhân viên, sửa hồ sơ đang dùng).
- **Lệnh DB chỉ chạy local, người dùng tự chạy.** Phiên code ghi lệnh vào mục Kết quả rồi chờ kết quả, không tự chạy `supabase db reset`, `psql`. Reset **Dev** (`--linked`) chỉ khi người dùng đồng ý.
  - Reset local: `supabase db reset`
  - Chạy test SQL: `for f in supabase/tests/*.sql; do echo "== $f"; psql "postgresql://postgres:postgres@127.0.0.1:54422/postgres" -v ON_ERROR_STOP=1 -q -f "$f" || break; done`
- Test Dart đọc migration: `cd apps/erp && flutter test test/features/einvoice/data/einvoice_sql_contract_test.dart test/features/sales/data/sales_sql_contract_test.dart`. Ghi số test trước / sau.
- `apps/erp/lib` không sửa (đo 2026-11-19: app và Edge Function không gọi `enqueue_outbox_message`, `platform.*`, schema `costing` / `accounting` / `dashboard`). Không cần chạy `impact` GitNexus (không đổi symbol Dart). Trước commit: `detect_changes`.
- Tìm trong zsh: đặt `--include='*.sql'` trong nháy.
- Phiên code ghi Kết quả (mục 8) sau mỗi task: tệp:dòng, lệch plan, số test. Không tự chấm ĐẠT.

## Review Focus

1. **Email mời nhân viên / đặt lại mật khẩu ngừng gửi** vì còn một chỗ gọi tên cũ trong bản định nghĩa **mới nhất** (lỗi chỉ lộ lúc chạy, plpgsql không kiểm khi tạo hàm). Test: Task 1 Step 5 grep `enqueue_outbox_message` toàn `supabase/` rỗng + `iam_email_jobs.sql` xanh.
2. **Người dùng đăng nhập tự gọi `iam.enqueue_email_job` qua PostgREST** để gửi email tuỳ ý (hàm `security definer`, schema `iam` mở API). Hàm cũ không có `revoke` cho `public` / `authenticated`. Test: Task 1 Step 1 ca `authenticated / anon cannot execute enqueue_email_job`.
3. **Đổi vai trò / tạm ngưng / xoá thành viên lỗi** vì bỏ khối `begin … exception` mà xoá nhầm `append_audit_log` đứng ngay trên. Lịch sử tổ chức phải còn dòng `iam.membership.role_changed`. Test: Task 1 Step 1 ca `assign_member_role still writes audit`.
4. **Hàm einvoice lỗi cú pháp sau khi bỏ `perform`** (khối `begin … exception` rỗng ở `20261031007:362-391`, biến chỉ dùng cho payload outbox còn sót). Test: Task 2 Step 5 `db reset` + `einvoice_th08.sql` xanh.
5. **`supabase start` / PostgREST lỗi** vì `config.toml` còn khai schema không tồn tại. Test: Task 3 Step 5 `supabase db reset` + `supabase status` không lỗi.

---

## 1. Mục tiêu

- `grep -rnE "enqueue_outbox_message|install_module_messaging|messaging_module_registry|messaging_backlog|list_tenants_with_pending_messaging|inbox_messages|platform\." supabase scripts --include='*.sql' --include='*.ts' --include='*.sh' --include='*.toml' --include='*.yaml'` rỗng.
- `grep -rn "outbox_messages" supabase --include='*.sql'` chỉ còn `sales.outbox_messages` (và tên bảng trong test `platform_messaging_removed.sql`).
- `supabase db reset` OK; toàn bộ `supabase/tests/*.sql` xanh; 2 test hợp đồng Dart xanh.

## 2. Quyết định

| Q | Nội dung |
|---|---|
| Q1 | **Đường email → `iam.enqueue_email_job(p_payload jsonb, p_job_id uuid default gen_random_uuid()) returns uuid`** (người dùng chọn B, 2026-11-19). Định nghĩa trong `20261009003` thay chỗ `iam.enqueue_outbox_message` (`:109-235`), thân = **nhánh email** hiện tại (giải `secret_payload_ciphertext`, kiểm `template_id` / `to_email` / `correlation_id`, đọc `tenant_id` / `refs` từ payload, ghi `iam.email_jobs` với `id = p_job_id`), cùng câu lỗi `VALIDATION_ERROR: email secret`. Bỏ `p_tenant_id` (nhánh email không dùng — tenant lấy từ payload), `p_event_type`, `p_occurred_at`. `search_path = iam, pg_temp` (bỏ `platform`). 14 chỗ gọi email `iam.enqueue_outbox_message(<tenant>, 'iam.email.delivery_requested', <payload>, v_message_id)` ⇒ `iam.enqueue_email_job(<payload>, v_message_id)` |
| Q2 | **Quyền `iam.enqueue_email_job`: `revoke all … from public, anon, authenticated`; không `grant` ai** (chỉ RPC `security definer` cùng chủ gọi). **Đổi có chủ đích — lỗ bảo mật đang có:** hàm cũ do `platform.install_module_messaging` tạo chỉ `grant … to service_role`, không `revoke` khỏi `public` (`20260623000001:700-718`); không migration nào thu lại (`grep` 2026-11-19) ⇒ hiện `authenticated` gọi được `iam.enqueue_outbox_message` để gửi email tuỳ ý |
| Q3 | **Bỏ sự kiện không phải email của IAM.** Khối `begin perform iam.enqueue_outbox_message(...) exception when undefined_function then null; end;` ở `_mutate_membership_status` (`20260811014:318-333`, sự kiện trạng thái thành viên) và `assign_member_role` (`20260820005:118-137`, `iam.membership.role_changed`) **xoá cả khối**. Nhật ký `iam.append_audit_log` ngay trên (`20260811014:300-316`, `20260820005:96-115`) giữ nguyên — màn Lịch sử đọc nhật ký này, không đọc outbox |
| Q4 | **Bỏ outbox `einvoice`** (PLAN 9.4 "kể cả einvoice"; 7-C để lại làm nhật ký, không ai đọc — test `nobody reads outbox or inbox`). Bỏ bảng, hàm `einvoice.enqueue_outbox_message`, 12 câu `perform` + 1 `insert` trực tiếp (mục 3). Biến chỉ phục vụ payload outbox xoá theo: `v_emit_attention` (`20261031015:139, 297, 360, 408-422`), `v_display_camel` (`20261031014:245, 390-396, 441, 524-530`) |
| Q5 | **Bỏ 3 schema `costing`, `accounting`, `dashboard` và `platform`**: chỉ do nền messaging tạo, không đối tượng nào khác (`grep` 2026-11-19). `config.toml:13` còn `["public", "graphql_public", "iam", "catalog", "partner", "sales", "receivable", "inventory", "einvoice", "ai"]`; `:15` còn `["public", "iam", "catalog", "partner", "sales", "inventory", "einvoice", "extensions"]` |
| Q6 | **Xoá 3 script cũ** trong `scripts/supabase/`: `messaging_smoke_test.sql`, `run_messaging_smoke_test.sh`, `seed_partner_transaction_history_inbox.sql` (kiểm nền messaging / inbox partner đã bỏ ở 4-C; không ai tham chiếu) |
| Q7 | **Đổi tên gọi ở cả bản định nghĩa cũ đã bị ghi đè** (vd `20260811017`, `20260826001`), không chỉ bản mới nhất ⇒ kiểm xong bằng một lệnh `grep` rỗng. Thân các bản cũ ngoài chỗ gọi không sửa |
| Q8 | **PLAN 9.4 sửa câu chữ:** onboarding / readiness / `provisioning` / `pending_activation` / FK `memberships.user_id` **đã xong ở 3-B** (test `iam_legacy_cleanup.sql`); `iam.idempotency_records` **giữ** |

## 3. Hiện trạng (đo 2026-11-19, HEAD `8042e0f85`)

**Nền `platform`:** `20260623000001` (727 dòng: `platform.messaging_module_registry`, view `messaging_backlog_stats`, `rebuild_messaging_backlog_stats_view`, `list_tenants_with_pending_messaging`, `install_module_messaging` tạo `outbox_messages` / `inbox_messages` / `internal_commands` + 12 hàm cho một schema). `20260623000002` gọi nó cho `iam`, `costing`, `accounting`, `dashboard`. `20260820008` định nghĩa lại `list_tenants_with_pending_messaging`. Người đọc duy nhất là `apps/messaging_worker` (đã xoá ở 3-D).

**`iam.enqueue_outbox_message`** (bản cuối `20261009003:109-235`): `p_event_type <> 'iam.email.delivery_requested'` ⇒ ghi `iam.outbox_messages` (không ai đọc); ngược lại ⇒ ghi `iam.email_jobs` (trigger `email_jobs_dispatch` gửi qua Edge Function). Chỗ gọi (★ = bản mới nhất theo `REGISTRY.yaml`):

| Tệp:dòng | Hàm | Loại |
|---|---|---|
| `20260811014:319` ★ | `_mutate_membership_status` | trạng thái thành viên — xoá (Q3) |
| `20260820005:119` ★ | `assign_member_role` | `role_changed` — xoá (Q3) |
| `20260811017:259` | `create_tenant_invitation` | email |
| `20260811018:198` | `resend_tenant_invitation` | email |
| `20260811021:75, 184` | `begin_password_reset_operation`, `resend_password_reset_operation` | email |
| `20260811025:127, 217` | `…_by_email` ×2 | email |
| `20260826001:174, 578 ★, 669 ★, 786 ★, 882 ★, 1022` | `create_tenant_invitation`, 4 hàm đặt lại mật khẩu ★, `resend_tenant_invitation` | email |
| `20260826002:527` ★ | `resend_tenant_invitation` | email |
| `20260916005:183` ★ | `create_tenant_invitation` | email |

Tất cả chỗ email đều dạng 4 đối số `(<tenant>, 'iam.email.delivery_requested', <payload>, v_message_id)`.

**Outbox `einvoice`** (bảng + hàm ở `20261031002:12-19, 45-66, 213, 225`). Chỗ ghi (đều là bản mới nhất):

| Tệp:dòng | Hàm |
|---|---|
| `20261031007:367, 386` | `record_issuance_success` (trong khối `begin … exception when others`) |
| `20261031007:486` | `record_issuance_failure` |
| `20261031007:544` | `record_issuance_command_integrity_failure` |
| `20261031007:604, 669` | `record_publish_command_dead_letter` |
| `20261031008:229` | `_start_issuance_attempt` (bản cũ; mới nhất ở `20261031023`) |
| `20261031009:684` | `recover_internal_finalization` |
| `20261031012:278-297` | `record_provider_observation` — khối `if p_provider_state_code in ('NOT_FOUND','MISMATCH') then insert into einvoice.outbox_messages … end if;` (chỉ có câu insert) |
| `20261031014:398, 532` | `record_delivery_result`, `record_delivery_command_dead_letter` |
| `20261031015:408-422` | `record_delivery_reconciliation_check` (`if v_emit_attention then … end if;`) |
| `20261031023:586` | `_start_issuance_attempt` |

**Test đọc migration:** `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` (`keeps outbox log writers` `:98` đếm 12 chỗ gọi, `outbox writers use only the 5 log columns` `:123`, `creates einvoice queue directly` `:205` kiểm bảng outbox + 5 hàm + 5 grant, `_installedQueueFns` / `_einvoiceDefines` `:353-375`); `supabase/tests/iam_email_jobs.sql` (5 lần gọi `iam.enqueue_outbox_message`, đếm `iam.outbox_messages` `:24, 41, 71`). `sales_sql_contract_test.dart` không đụng (chỉ kiểm `sales`).

## 4. Đang làm gì (thứ bị xoá / thay)

| # | Thứ bị xoá / thay — đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | `iam.enqueue_outbox_message`, nhánh email: giải mã code, kiểm 3 trường, ghi `iam.email_jobs` (`id = p_message_id`), lỗi `VALIDATION_ERROR: email secret` | `iam.enqueue_email_job` (Q1), cùng thân | `iam_email_jobs.sql` các ca email hiện có (đổi cách gọi, giữ điều kiện) |
| 2 | Nhánh không phải email: ghi `iam.outbox_messages` | **Bỏ** (Q3); nhật ký `append_audit_log` giữ | Ca mới `assign_member_role still writes audit` |
| 3 | Quyền: `service_role` + (ngầm) `public` gọi được | **Đổi có chủ đích** (Q2): không ai ngoài chủ hàm | Ca mới `authenticated / anon cannot execute enqueue_email_job` |
| 4 | `iam.outbox_messages`, `iam.inbox_messages`, `iam.internal_commands` + 11 hàm hàng đợi `iam.*` (do `install_module_messaging('iam')`) | **Bỏ** (không ai gọi — `grep` 2026-11-19) | `platform_messaging_removed.sql` |
| 5 | Schema `costing` / `accounting` / `dashboard` + bảng / hàm hàng đợi của chúng | **Bỏ** (Q5) | `platform_messaging_removed.sql` |
| 6 | `platform.*` (registry, view, 3 hàm) — phục vụ worker đã xoá | **Bỏ** | `platform_messaging_removed.sql` |
| 7 | `einvoice.outbox_messages` + `einvoice.enqueue_outbox_message` + 13 chỗ ghi | **Bỏ** (Q4) | Dart `einvoice has no outbox`; `einvoice_th08.sql` vẫn xanh |
| 8 | `einvoice.internal_commands` + 4 hàm hàng đợi + 2 index | **Giữ nguyên** | Dart `creates einvoice queue directly`; `einvoice_th08.sql` |
| 9 | 3 script `scripts/supabase/*messaging*` / `*inbox*` | **Xoá** (Q6) | grep mục 1 |

## 5. Thay đổi

| Tệp | Việc |
|---|---|
| `supabase/migrations/20260623000001_platform_messaging_foundation.sql`, `20260623000002_install_module_messaging_modules.sql`, `20260820008_platform_list_pending_messaging_queues.sql` | xoá (Task 3) |
| `supabase/migrations/20261009003_iam_email_jobs.sql` | `enqueue_email_job` (Task 1) |
| 9 migration IAM ở mục 3 | đổi chỗ gọi / xoá khối (Task 1) |
| `supabase/migrations/20261031002`, `…007`, `…008`, `…009`, `…012`, `…014`, `…015`, `…023` | bỏ outbox einvoice (Task 2) |
| `supabase/migrations/REGISTRY.yaml` | sửa (Task 1, 2, 3) |
| `supabase/config.toml:13, 15` | sửa (Task 3) |
| `supabase/tests/iam_email_jobs.sql` | sửa (Task 1) |
| `supabase/tests/platform_messaging_removed.sql` | tạo (Task 3) |
| `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` | sửa (Task 2) |
| `scripts/supabase/` 3 tệp | xoá (Task 3) |
| `docs/refactor/PLAN.md` | sửa (Task 4) |

## 6. Các task

### Task 0: Mốc trên code cũ

- [ ] **Step 1:** `cd apps/erp && flutter test test/features/einvoice/data/einvoice_sql_contract_test.dart test/features/sales/data/sales_sql_contract_test.dart 2>&1 | tail -1` ⇒ ghi `+N` vào Kết quả.
- [ ] **Step 2:** Ghi vào Kết quả, nhờ người dùng chạy: `supabase db reset` + vòng test SQL (Global Constraints). Chờ kết quả, ghi tên tệp xanh / đỏ. Tệp nào đỏ trên code cũ ⇒ báo người dùng trước khi làm tiếp (không tính là lỗi của 9-2).

### Task 1: IAM — `iam.enqueue_email_job`, bỏ outbox IAM

**Files:**
- Modify: `supabase/migrations/20261009003_iam_email_jobs.sql:1-13, 109-235` (+ khối `revoke` / `grant` cuối tệp)
- Modify: `20260811014:318-333`, `20260820005:118-137`, `20260811017:259`, `20260811018:198`, `20260811021:75,184`, `20260811025:127,217`, `20260826001:174,578,669,786,882,1022`, `20260826002:527`, `20260916005:183`
- Modify: `supabase/migrations/REGISTRY.yaml:281` (`enqueue_outbox_message` ⇒ `enqueue_email_job: 20261009003_iam_email_jobs.sql`, giữ thứ tự chữ cái)
- Test: `supabase/tests/iam_email_jobs.sql`

**Interfaces:**
- Produces: `iam.enqueue_email_job(p_payload jsonb, p_job_id uuid default gen_random_uuid()) returns uuid` — `security definer`, `search_path = iam, pg_temp`, không ai có quyền `execute` ngoài chủ.

- [ ] **Step 1: Sửa test trước** (`iam_email_jobs.sql`):
  - 4 lần gọi email (`:26, 109, 169, 214`) ⇒ `perform iam.enqueue_email_job(<payload như cũ>, <id như cũ>)` (bỏ đối số tenant và `'iam.email.delivery_requested'`).
  - Bỏ ca non-email (`:62-80`) và biến / truy vấn đếm `iam.outbox_messages` (`:8-9, 24, 41-44`).
  - Thêm (cạnh ca `claim_email_job` `:161`):
    ```sql
    if has_function_privilege('authenticated', 'iam.enqueue_email_job(jsonb, uuid)', 'execute')
       or has_function_privilege('anon', 'iam.enqueue_email_job(jsonb, uuid)', 'execute') then
      raise exception 'authenticated / anon can execute enqueue_email_job';
    end if;
    if to_regclass('iam.outbox_messages') is not null then
      raise exception 'iam.outbox_messages still exists';
    end if;
    ```
  - Thêm ca `assign_member_role still writes audit`: dựng tenant + Owner + 1 thành viên (theo mẫu dựng dữ liệu của `supabase/tests/iam_accept_invitation_reinvite.sql`), `set local request.jwt.claims` thành Owner, gọi `iam.assign_member_role(<tenant>, <membership>, <role khác>)`, kiểm `exists (select 1 from iam.audit_logs where event_code = 'iam.membership.role_changed' and subject_id = <membership>::text)`; không có ⇒ `raise exception 'role change audit missing'`. (Tên bảng / cột nhật ký: đọc `20260826004_iam_audit_logs_v2_rebuild.sql`.)
- [ ] **Step 2:** Nhờ người dùng chạy `iam_email_jobs.sql` trên DB hiện tại ⇒ phải **đỏ** (`function iam.enqueue_email_job(jsonb, uuid) does not exist`). Ghi kết quả.
- [ ] **Step 3: `20261009003`.** Thay `iam.enqueue_outbox_message` bằng `iam.enqueue_email_job` theo Q1 (bỏ nhánh `if p_event_type is distinct from …` `:132-141`; `p_message_id` ⇒ `p_job_id`). Thêm cuối tệp: `revoke all on function iam.enqueue_email_job(jsonb, uuid) from public, anon, authenticated;`. Header: `Title` ⇒ `iam email jobs (enqueue_email_job, claim, complete)`; `Touches:` đổi tên hàm; `Depends on:` bỏ `20260623000002_…`; xoá chú thích `Note (3-B …)` `:11-13` và chú thích `:109-111`, thêm dòng `-- 9-2 (2026-11-19): bỏ outbox IAM; enqueue_outbox_message → enqueue_email_job (chỉ đường email).`
- [ ] **Step 4: Chỗ gọi.** 14 chỗ email ⇒ `iam.enqueue_email_job(<payload>, v_message_id)` (Q1, Q7). Xoá nguyên khối `begin … end;` chứa lời gọi ở `20260811014:318-333` và `20260820005:118-137` (Q3) — khối `append_audit_log` phía trên giữ.
- [ ] **Step 5:** `grep -rn "enqueue_outbox_message" supabase --include='*.sql' | grep -v "einvoice\.\|%I\."` ⇒ rỗng (còn lại chỉ của einvoice — Task 2 — và `20260623000001` — Task 3).
- [ ] **Step 6:** Nhờ người dùng chạy `supabase db reset` + `iam_email_jobs.sql`, `iam_accept_invitation_reinvite.sql`, `iam_legacy_cleanup.sql`, `iam_signup_trigger.sql` ⇒ xanh. Ghi kết quả.
- [ ] **Step 7: Commit** `refactor(db): iam.enqueue_email_job thay outbox IAM (9-2)`.

### Task 2: einvoice — bỏ outbox, giữ hàng đợi

**Files:**
- Modify: `supabase/migrations/20261031002_einvoice_install_module_messaging.sql`, `20261031007`, `…008`, `…009`, `…012`, `…014`, `…015`, `…023` (dòng ở mục 3)
- Modify: `supabase/migrations/REGISTRY.yaml:180` (xoá `enqueue_outbox_message` của einvoice)
- Test: `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart`

- [ ] **Step 1: Sửa test trước.**
  - `keeps outbox log writers` (`:98-121`) và `outbox writers use only the 5 log columns` (`:123-157`) ⇒ thay bằng một test trong group `removed`:
    ```dart
    test('einvoice has no outbox', () {
      final sql = _allMigrationsSql();
      expect(sql.contains('einvoice.outbox_messages'), isFalse);
      expect(sql.contains('einvoice.enqueue_outbox_message'), isFalse);
      expect(_definesFn(sql, 'einvoice', 'enqueue_outbox_message'), isFalse);
      final reg = File('${_findRepoRoot().path}/supabase/migrations/REGISTRY.yaml').readAsStringSync();
      final einvoiceBlock = RegExp(r'^einvoice:\n((?:  .*\n)*)', multiLine: true).firstMatch(reg)!.group(1)!;
      expect(einvoiceBlock.contains('  enqueue_outbox_message:'), isFalse);
    });
    ```
  - `creates einvoice queue directly` (`:205`): mục (3) thay bằng `expect(m.contains('outbox_messages'), isFalse);`; mục (4), (5) bỏ `enqueue_outbox_message` (còn 4 hàm, 4 grant).
  - `_installedQueueFns` / `_einvoiceDefines` (`:353-375`): nhánh `install_module_messaging` không còn đúng ⇒ `_einvoiceDefines` chỉ còn `return _definesFn(sql, 'einvoice', name);`, xoá `_installedQueueFns`.
  - `nobody reads outbox or inbox` (`:159`): giữ.
- [ ] **Step 2:** `flutter test …einvoice_sql_contract_test.dart` ⇒ đỏ đúng ở `einvoice has no outbox` và `creates einvoice queue directly`.
- [ ] **Step 3: `20261031002`.** Xoá bảng outbox (`:12-19`), hàm `enqueue_outbox_message` (`:45-66`), chữ ký của nó trong `revoke` (`:213`) và dòng `grant` (`:225`). Header: `Title` ⇒ `einvoice — hàng đợi internal_commands`; `Touches:` bỏ 2 tên; dòng 7-C giữ, thêm `-- 9-2 (2026-11-19): bỏ outbox (nhật ký không ai đọc).` Tên tệp giữ.
- [ ] **Step 4: 13 chỗ ghi** (mục 3): xoá câu `perform einvoice.enqueue_outbox_message(...)`; `20261031012:278-297` xoá cả khối `if … end if;`; `20261031015` xoá `v_emit_attention` (khai báo `:139`, 2 phép gán `:297, :360`, khối `if` `:408-422`); `20261031014` xoá `v_display_camel` (khai báo `:245, :441`, phép gán `case` `:390-396, :524-530`) — `v_projection` giữ (còn trả về). Khối `begin … exception` ở `20261031007:362-391` vẫn phải còn ít nhất một câu lệnh trước `exception` (câu `update` hiện có). Header từng tệp: thêm `-- 9-2 (2026-11-19): bỏ ghi outbox.` (không sửa `Touches`).
- [ ] **Step 5:** `flutter test …einvoice_sql_contract_test.dart …sales_sql_contract_test.dart` ⇒ xanh, số test = mốc Task 0 − 2 + 1. Nhờ người dùng chạy `supabase db reset` + `einvoice_th08.sql`, `receivable_th06.sql` ⇒ xanh.
- [ ] **Step 6: Commit** `refactor(db): bỏ outbox einvoice, giữ internal_commands (9-2)`.

### Task 3: Bỏ nền `platform` + 3 schema

**Files:**
- Delete: 3 migration nền; `scripts/supabase/messaging_smoke_test.sql`, `run_messaging_smoke_test.sh`, `seed_partner_transaction_history_inbox.sql`
- Modify: `supabase/migrations/REGISTRY.yaml` (khối `platform:` `:438-441`; `bootstrap_grandfathered` `:546-547`; dòng `20260820008` `:658`), `supabase/config.toml:13, 15`
- Create: `supabase/tests/platform_messaging_removed.sql`

- [ ] **Step 1: Viết test** `platform_messaging_removed.sql` (mẫu đầu tệp như `iam_legacy_cleanup.sql`: `begin; do $$ … $$; rollback;`), các ca, mỗi ca `raise exception 'FAIL: …'`:
  - không còn schema: `exists (select 1 from pg_namespace where nspname in ('platform','costing','accounting','dashboard'))`;
  - bảng `outbox_messages` chỉ ở `sales`: `select array_agg(table_schema) from information_schema.tables where table_name = 'outbox_messages'` = `{sales}`;
  - không còn `inbox_messages`; `internal_commands` chỉ ở `einvoice`;
  - không hàm nào tên `enqueue_outbox_message`, `install_module_messaging`, `claim_outbox_batch`, `receive_integration_event` (`pg_proc`);
  - còn `einvoice.enqueue_internal_command`, `claim_internal_commands_batch`, `complete_internal_command`, `fail_internal_command`, `iam.enqueue_email_job`.
- [ ] **Step 2:** Nhờ người dùng chạy tệp này trên DB hiện tại ⇒ **đỏ** ở ca schema. Ghi kết quả.
- [ ] **Step 3:** Xoá 3 migration + 3 script; sửa `REGISTRY.yaml`, `config.toml` theo Q5.
- [ ] **Step 4:** grep mục 1 ⇒ rỗng.
- [ ] **Step 5:** Nhờ người dùng chạy `supabase stop && supabase start` (nạp `config.toml` mới), `supabase db reset`, `supabase status`, rồi **toàn bộ** vòng test SQL ⇒ tất cả xanh, gồm `platform_messaging_removed.sql`. Ghi kết quả từng tệp.
- [ ] **Step 6:** `cd apps/erp && flutter test` (toàn bộ) ⇒ cùng số pass với trước 9-2 (không có test Dart nào đọc 3 file bị xoá — đo 2026-11-19).
- [ ] **Step 7: Commit** `refactor(db): bỏ nền messaging platform và schema costing/accounting/dashboard (9-2)`.

### Task 4: Tài liệu + Dev

- [ ] **Step 1: `docs/refactor/PLAN.md`:** hàng 9-2 (`:844`) cột Plan `✅ [plan](plans/P9/9-2-don-db.md) duyệt <ngày>`, cột Làm `✅ <ngày>`; hàng 9.4 (`:853`) viết lại theo Q8: "bỏ nền messaging `platform` + schema `costing` / `accounting` / `dashboard`; bỏ outbox / inbox `iam`, outbox `einvoice` (trừ `sales.outbox_messages`, 8-C Q1); giữ `einvoice.internal_commands`, `iam.idempotency_records`; đường email IAM ⇒ `iam.enqueue_email_job`. Onboarding / readiness / `provisioning` / `pending_activation` / FK `memberships.user_id` đã xong ở 3-B"; dòng Trạng thái (`:839`) thêm 9-2.
- [ ] **Step 2:** `detect_changes` (GitNexus) ⇒ chỉ tệp trong mục 5. Commit `docs: ghi kết quả 9-2`.
- [ ] **Step 3:** Hỏi người dùng có reset Dev không (`supabase db reset --linked`, quy tắc migration). Không tự chạy.

## 7. Rủi ro / lưu ý

- plpgsql không kiểm tên hàm lúc `create function` ⇒ sót một chỗ gọi tên cũ chỉ lộ khi chạy RPC. Chặn bằng grep (Task 1 Step 5, Task 3 Step 4) + test SQL chạy thật luồng email.
- `supabase/tests/*.sql` có thể đã đỏ sẵn trước 9-2 (G5-0b "còn nợ chạy test SQL") ⇒ Task 0 ghi mốc để không đổ cho 9-2.
- Prod chưa chạy ⇒ không cần migration `drop`. Dev phải reset mới nhận (Task 4 Step 3).
- `REGISTRY.yaml:3` còn ghi lệnh `melos run migrate:seed-registry` (Melos bỏ ở 9-1, công cụ đã xoá ở `8ad18cd27`) — ngoài phạm vi, không sửa.

## 8. Kết quả

- Commit: `24c0f0928` (Task 1), `162fecf58` (Task 2), `2eaa95e7b` (Task 3).
- Dart: mốc trước 9-2 `+19` (einvoice + sales contract); sau Task 2 `+18` (= 19 − 2 + 1). `flutter test` toàn bộ: `+3853 -62`; 62 đỏ đều ở test presentation / golden (catalog, pricing, inventory golden, my_account, tenant_admin), không test SQL contract nào đỏ; chưa có mốc đầy đủ trước 9-2 để so.
- DB: người dùng chạy `supabase db reset` OK; vòng test SQL xanh, gồm `iam_email_jobs`, `platform_messaging_removed`, `iam_legacy_cleanup`, `receivable_th06`, `einvoice_th08`. Task 0 mốc DB cũ và các bước "đỏ trước" (Task 1 Step 2, Task 3 Step 2) bị bỏ qua.
- Ngoài phạm vi (làm thêm theo yêu cầu): `einvoice_th08`, `catalog_th02`, `pricing_th04` đã đỏ sẵn từ trước 9-2 (lệch schema) nên đã sửa test (commit `c57ac4185`, `4169b89a4`); `catalog_th02` / `pricing_th04` chạy với điều kiện nới (grant đọc, tắt RLS trong transaction). Migration `20260805002` thêm `drop function` cho overload cũ của `create_customer_price_rule` và `reenable_customer_price_rule` (trùng bản gây `is not unique`).
- Lưu ý Dev: `reenable_customer_price_rule` cần secret Vault `pricing_reenable_fingerprint_hmac_v1`.
- Chưa kiểm: `catalog.create_product` và `catalog.update_product_profile` còn 2 overload mỗi hàm.
- Lệch plan: comment `Intentionally no enqueue_outbox_message` (`20260811018`, `20260826001`) và header `20260811017` đổi chữ để grep rỗng; grep mục 1 chỉ còn trúng tên tệp `…install_module_messaging.sql` của einvoice (giữ tên tệp theo plan) và test.
- Còn sót (nhẹ): 6 hàm einvoice còn `set search_path = einvoice, platform, pg_temp` (schema không tồn tại, vô hại).

## 9. Review

_(phiên review ghi)_
