# IAM schema refactor — quyết định theo từng bảng

> Bắt đầu: 2026-09-17 · Nhánh thảo luận: `feature/theme8`
> Cách làm: review **từng bảng** trong schema `iam` — bảng có cần giữ không, nếu giữ thì từng cột có hợp lý không.
> Mỗi bảng chốt xong → một file quyết định trong thư mục này. Implement dựa trực tiếp vào các file này.

## Nguyên tắc chung (áp dụng mọi bảng)

1. **Dữ liệu IAM hiện tại là dữ liệu dev**, bỏ được.
2. **Ưu tiên thay đổi nhỏ, ít động luồng chính.** Các thay đổi nghiệp vụ nặng (mô hình hybrid / placeholder user_id, role text↔uuid) để giai đoạn sau, không làm trong đợt này trừ khi file bảng ghi rõ.
3. **Giữ contract RPC**: không đổi chữ ký và các key JSON trả về, trừ khi file bảng ghi rõ. Cột bị gộp/bỏ thì key JSON cũ được **tính ra** từ cột mới để Dart/UI không phải sửa.
4. **Không đổi chữ ký** `iam.has_permission(uuid, text)` và `iam.get_session_context(uuid)` — module khác gọi `has_permission` ~325 chỗ.
5. **Sửa trực tiếp migration gốc, không dùng `_drafts/`** (chốt 2026-09-17 — user sẽ `supabase db reset`). Xem [Quy ước implement](#quy-ước-implement-sửa-trực-tiếp-migration-gốc).
6. Trước khi sửa hàm: chạy GitNexus `impact` (CLAUDE.md). Sửa kèm các `*_sql_contract_test.dart` assert trên nội dung SQL bị đổi.

## Quy ước implement: sửa trực tiếp migration gốc

Reset chạy **toàn bộ** chuỗi migration trên DB rỗng → mọi câu lệnh được thực thi phải hợp lệ với schema mới.

| Loại | Quy tắc |
|---|---|
| Bảng / cột / index / constraint / policy / grant | Sửa tại câu lệnh **tạo ra** nó (`create table`, `alter table … add column`, `create index`…). Bỏ đối tượng → **xoá câu lệnh tạo** (không thêm `drop`) |
| Câu lệnh chạy trực tiếp tham chiếu cột/bảng bị bỏ ở **bất kỳ** migration (`update`/`insert` backfill, khối `DO`, `create index`, `grant`/`revoke`, `alter … set default`, hàm `language sql`) | Sửa/xoá tại chỗ — Postgres kiểm tra ngay khi reset dù bảng rỗng |
| Hàm `plpgsql` | Chỉ sửa **định nghĩa cuối cùng** (file owner trong `supabase/migrations/REGISTRY.yaml`). Bản cũ hơn bị ghi đè và câu SQL trong thân không bị kiểm tra lúc tạo → để nguyên. **Ngoại lệ:** phần `declare`/chữ ký **có** bị kiểm tra — bản cũ khai báo biến/tham số/kiểu trả về là bảng hoặc `%type` của cột bị bỏ thì phải đổi kiểu (vd sang bảng thay thế) |
| Hàm bị bỏ | Xoá định nghĩa ở file owner + `grant`/`revoke` liên quan (xoá cả bản cũ nếu là `language sql`) |
| Đối tượng mới | Thêm vào migration **trước** chỗ đầu tiên cần nó (bắt buộc với hàm `language sql`, kiểu trả về `%rowtype`/bảng, FK) |
| Đổi chữ ký hàm | Ở file owner thêm `drop function if exists <chữ ký cũ>;` trước `create or replace`, cập nhật `grant`/`revoke` |
| Header migration | Thêm/bỏ hàm trong file → cập nhật `-- Touches:`; sau khi sửa chạy `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` và `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` |
| Không còn | File `_drafts/`, khối guard `pg_proc`, `drop column` / `drop table` bổ sung |

**Kiểm chứng mỗi plan:**
1. SQL contract test mới đọc **file migration** (hàm lấy định nghĩa **cuối** trong file).
2. `grep` toàn bộ `supabase/migrations/*.sql` không còn tham chiếu tới đối tượng đã bỏ (ngoài thân hàm plpgsql bản cũ).
3. Chạy lại các SQL contract test cũ bị ảnh hưởng; sửa assertion kiểm tra nội dung đã đổi. **Baseline fail sẵn (2026-09-17, trước refactor):** `sql/iam_active_store_context_contract_test.dart` (setUpAll), `iam_platform_s15_s16_sql_contract_test.dart` (setUpAll), `iam_tenant_audit_v2_payload_sql_contract_test.dart` (10 test), `iam_tenant_audit_v2_read_sql_contract_test.dart` (setUpAll), `iam_owner_activation_retirement_sql_contract_test.dart` (setUpAll) — đều do đọc `_drafts/` không còn; không sửa trong refactor.
4. User chạy `supabase db reset` → toàn chuỗi chạy không lỗi → smoke test app.

**Thứ tự thực hiện plan:** 1 → 1b (đóng tổ chức) → 2 → 3 → 4 → 6 → 8 → 12 → 13 → 14 (plan sau giả định plan trước đã sửa nội dung file).

## Tiến độ

| # | Bảng | Trạng thái | File |
|---|---|---|---|
| 1 | `iam.tenants` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-01-tenants](../../plans/2026-09-17-iam-refactor-01-tenants.md) · 🧪 Đã sửa migration gốc, chờ reset | [01-tenants.md](01-tenants.md) |
| 2 | `iam.tenant_legal_profiles` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-02-tenant-legal-profiles](../../plans/2026-09-17-iam-refactor-02-tenant-legal-profiles.md) · 🧪 Đã sửa migration gốc, chờ reset | [02-tenant-legal-profiles.md](02-tenant-legal-profiles.md) |
| 3 | `iam.memberships` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-03-memberships](../../plans/2026-09-17-iam-refactor-03-memberships.md) · 🧪 Đã sửa migration gốc, chờ reset | [03-memberships.md](03-memberships.md) |
| 4 | `iam.tenant_invitations` | ✅ Đã chốt · 📝 Plan: [2026-09-17-iam-refactor-04-tenant-invitations](../../plans/2026-09-17-iam-refactor-04-tenant-invitations.md) · 🧪 Đã sửa migration gốc, chờ reset | [04-tenant-invitations.md](04-tenant-invitations.md) |
| 5 | `iam.stores` | ✅ Đã chốt · giữ nguyên (không plan) | [05-stores.md](05-stores.md) |
| 6 | `iam.membership_store_scopes` | ✅ Đã chốt · xoá bảng · 📝 Plan: [2026-09-17-iam-refactor-06-membership-store-scopes](../../plans/2026-09-17-iam-refactor-06-membership-store-scopes.md) · 🧪 Đã sửa migration gốc, chờ reset | [06-membership-store-scopes.md](06-membership-store-scopes.md) |
| 7 | `iam.role_definitions` | ✅ Đã chốt · giữ nguyên (không plan) | [07-role-definitions.md](07-role-definitions.md) |
| 8 | `iam.role_permissions` | ✅ Đã chốt · bảng giữ nguyên · 📝 Plan: [2026-09-17-iam-refactor-08-owner-flag-checks](../../plans/2026-09-17-iam-refactor-08-owner-flag-checks.md) · 🧪 Đã sửa migration gốc, chờ reset | [08-role-permissions.md](08-role-permissions.md) |
| 9 | `iam.platform_user_profiles` | ✅ Đã chốt · giữ nguyên (không plan) · ⏸ `email_verified` pending team | [09-platform-user-profiles.md](09-platform-user-profiles.md) |
| 10 | `iam.platform_admins` | ✅ Đã chốt · giữ nguyên · 🐛 bug "Tạm ngừng người dùng" sửa trong plan bảng 8 (Task 2–3) | [10-platform-admins.md](10-platform-admins.md) |
| 11 | `iam.user_preferences` | ✅ Đã chốt · giữ nguyên (không plan) | [11-user-preferences.md](11-user-preferences.md) |
| 12 | Nhóm idempotency (8 bảng) → `iam.idempotency_records` | ✅ Đã chốt · A1 gộp 8→1 · 🧪 Đã sửa migration gốc, chờ reset · Plan: [2026-09-17-iam-refactor-12-idempotency-records](../../plans/2026-09-17-iam-refactor-12-idempotency-records.md) | [12-idempotency-records.md](12-idempotency-records.md) |
| 13 | `iam.audit_logs` | ✅ Đã chốt · bỏ `created_at` · 🧪 Đã sửa migration gốc, chờ reset · Plan: [2026-09-17-iam-refactor-13-audit-logs](../../plans/2026-09-17-iam-refactor-13-audit-logs.md) | [13-audit-logs.md](13-audit-logs.md) |
| 14 | `iam.password_reset_operations`, `iam.password_reset_email_throttle` | ✅ Đã chốt · giữ nguyên · dọn migration + domain model · 🧪 Đã sửa, chờ reset · Plan: [2026-09-17-iam-refactor-14-password-reset](../../plans/2026-09-17-iam-refactor-14-password-reset.md) | [14-password-reset.md](14-password-reset.md) |
| 15 | `iam.email_delivery_outcomes` | ✅ Đã chốt · giữ nguyên (không plan) | [15-email-delivery-outcomes.md](15-email-delivery-outcomes.md) |

## Việc phát sinh (ngoài phạm vi cột)

| Việc | Nguồn | Trạng thái |
|---|---|---|
| Chặn tổ chức tạm ngừng / đã đóng (server + ERP) + vá 2 RPC tồn kho thiếu quyền | Smoke test TC-08 · [16-tenant-status-access.md](16-tenant-status-access.md) | 🧪 Đã sửa, chờ reset · Plan: [2026-09-18-iam-tenant-status-access](../../plans/2026-09-18-iam-tenant-status-access.md) |
| Người dùng bị tạm ngừng: đá khỏi phiên + thông báo đúng (ERP) | Smoke test 2026-09-18 · plan 8 đã chặn ở server | 🧪 Đã implement Dart client · Plan: [2026-09-18-iam-suspended-user-session](../../plans/2026-09-18-iam-suspended-user-session.md) · chờ smoke test |
| Thu hồi phiên Supabase Auth khi tạm ngừng người dùng | [16-tenant-status-access.md §4](16-tenant-status-access.md#4-ngoài-phạm-vi-để-sau) | ⏸ Để sau |
| RPC + command đóng tenant (`close_platform_tenant`) | [01-tenants.md §5](01-tenants.md#5-tính-năng-đóng-tenant-làm-trong-đợt-này) | ✅ Đã chốt · 📝 Plan 01b · 🧪 Đã sửa, chờ reset |
