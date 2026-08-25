# Kế hoạch triển khai: Dọn dẹp IAM Audit và Owner Activation

> **Dành cho agentic worker:** SUB-SKILL BẮT BUỘC: Dùng superpowers:subagent-driven-development để triển khai kế hoạch này theo từng task. Các Step dùng cú pháp checkbox (`- [ ]`) để theo dõi tiến độ.

**Mục tiêu:** Đưa phần triển khai kỹ thuật của IAM khớp với TH-01 bằng cách bỏ đường lưu trữ dư thừa `iam.platform_audit_logs` và loại bỏ (retire) cơ chế kích hoạt chủ sở hữu song song `iam.owner_activations`.

**Kiến trúc:** `iam.audit_logs` vẫn là kho audit IAM duy nhất; view audit của tenant và platform truy vấn nó theo `scope`. Owner **hợp nhất vào luồng mời** (Design A): onboarding phát một lời mời owner trên `tenant_invitations` (giữ mã, worker gửi mã), owner accept qua cùng cơ chế với staff và trở thành `store_owner`/`is_owner` (người active đầu tiên). Bảng song song `iam.owner_activations` bị retire. `iam.platform_admins` cố ý nằm ngoài phạm vi và sẽ được bàn riêng.

**Tech Stack:** Test Dart với `package:test`, lớp auth của Flutter ERP, các draft SQL Supabase trong `supabase/migrations/_drafts/`, các pattern CQRS/application/infrastructure của IAM trong `modules/iam`.

**Spec:** `docs/themes/TH-01-organization-users/Theme-1-organization-users.md`; harness hỗ trợ: `docs/themes/TH-01-organization-users/harness/01-domain-model.md`, `docs/themes/TH-01-organization-users/harness/02-module-map.md`, `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`.

## Ràng buộc toàn cục (Global Constraints)

- Đọc `AGENTS.md`, `.cursor/rules/vet45-architecture.mdc`, `docs/harness/PROGRESS.md`, và các harness doc của TH-01 trước khi triển khai.
- Dùng GitNexus trước khi sửa code: chạy `impact` trước khi sửa bất kỳ symbol function/class/method nào; cảnh báo người dùng trước khi tiếp tục nếu mức rủi ro là HIGH hoặc CRITICAL.
- Thay đổi SQL do agent thực hiện chỉ được ở dạng draft trong `supabase/migrations/_drafts/`; không tạo hay sửa `supabase/migrations/[0-9]*.sql` trừ khi người dùng yêu cầu promote một cách rõ ràng.
- `iam.audit_logs` là lịch sử audit IAM canonical: append bất biến, redact trước khi lưu, có view cho tenant/platform.
- Platform Audit cho các sự kiện IAM là một consumer/policy/view trên `iam.audit_logs`; không tạo nguồn sự thật (source of truth) audit IAM thứ hai.
- Onboarding tạo Tenant + một **lời mời owner** trên `tenant_invitations` (owner dùng chung cơ chế mã với staff), gửi mã kích hoạt qua worker, và ghi lại trạng thái/correlation của operation. Membership owner tạo **lúc accept** (không ở onboarding).
- Theme 1 không được lưu raw activation token, raw invitation token, password, mã đặt lại mật khẩu, session token, hay bất kỳ credential bí mật nào.
- `iam.platform_admins` nằm ngoài phạm vi kế hoạch này.
- **KHÔNG tự commit.** Sau mỗi task, dừng lại, tóm tắt các file đã đổi và bàn giao để người dùng tự review + commit. Có thể gợi ý lệnh `git add`/`git commit` cho người dùng, nhưng agent không được tự chạy `git commit`.

---

## Cấu trúc file (File Structure)

- Sửa `docs/themes/TH-01-organization-users/harness/06-harness-notes.md` để ghi lại quyết định dọn dẹp và tách `platform_admins` khỏi phần việc này.
- Sửa `docs/themes/TH-01-organization-users/harness/07-api-contracts.md` để nêu rõ ràng buộc triển khai: không dùng `platform_audit_logs` và không dùng `owner_activations`.
- Tạo `modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart` để khoá việc dọn dẹp kho audit.
- Tạo `modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart` để khoá việc retire owner activation.
- Tạo `supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql` chứa SQL draft-only, drop kho audit cũ và kho/RPC owner activation sau khi thay thế hành vi onboarding.
- Archive `supabase/migrations/_drafts/_archive/001_iam_pending_platform_profile_onboarding.sql` sau khi phần pending-profile hữu ích đã được gộp vào draft cleanup.
- Sửa `modules/iam/infrastructure/test/iam_owner_activation_rpc_contract_test.dart`, `iam_owner_activation_store_owner_role_sql_contract_test.dart`, và các SQL test liên quan owner-activation để chúng assert việc retire thay vì giữ luồng cũ.
- Sửa `apps/erp/lib/core/router/app_router.dart` và bỏ các file UI/client của owner activation nếu không luồng nào khác dùng chúng.
- Xoá các app test của owner activation sau khi đã bỏ route/client/page: `apps/erp/test/features/auth/presentation/owner_activation_page_test.dart` và `owner_activation_cubit_test.dart`.

---

## Quyết định thiết kế: schema `iam.audit_logs`

Đây là các quyết định thiết kế đã chốt cho `iam.audit_logs`, không phải đề xuất
để cân nhắc. Bảng đã tồn tại ở `20260811013_iam_platform_audit_read.sql` (với
tập cột cơ bản và 2 index `audit_logs_tenant_occurred_idx`,
`audit_logs_scope_occurred_idx`); các quyết định dưới đây là chuẩn canonical mà
mọi thay đổi audit về sau phải tuân. Việc bổ sung cột/index để khớp chuẩn này
KHÔNG thuộc phạm vi drop/retire của plan này (draft-only) — nó là ràng buộc
thiết kế cho các plan audit tiếp theo.

Quyết định: `iam.audit_logs` là kho Audit Activity hướng người dùng, không phải
bảng raw domain-event. Mỗi operation/correlation nghiệp vụ sinh ra đúng một row
cho bộ render list/detail audit dùng chung giữa Tenant App và Platform Admin.
Khi nhiều domain event bị gộp vào một row, giữ tham chiếu trong
`source_event_refs`.

### Các cột của bảng

| Cột | Kiểu | Bắt buộc | Mục đích |
| --- | ---- | -------- | -------- |
| `id` | `uuid` | Có | Audit ID ổn định hiển thị ở detail của Tenant App và Platform Admin. |
| `scope` | `text` | Có | Phạm vi hiển thị: `tenant` hoặc `platform`. |
| `tenant_id` | `uuid` | Bắt buộc khi `scope = 'tenant'`; nullable với sự kiện thuần platform | Ranh giới tenant cho truy vấn hướng tenant và các hành động platform liên quan tenant. |
| `activity_code` | `text` | Có | Mã activity hướng người dùng sau khi mapping/khử trùng lặp, ví dụ `tenant.member.role_changed`. |
| `event_code` | `text` | Có | Mã sự kiện/audit nguồn canonical dùng cho trace và filter, ví dụ `iam.membership.role_changed`. |
| `event_category` | `text` | Không | Category cho UI/filter: `member`, `role`, `organization`, `invitation`, `account`, `security`, `system`, hoặc nullable với legacy/unknown. |
| `result` | `text` | Có | Kết quả: `success`, `blocked`, hoặc `error`. |
| `title_snapshot` | `text` | Có | Tiêu đề mà list/detail audit hiển thị tại thời điểm ghi. |
| `actor_type` | `text` | Có | Loại chủ thể: `platform_user`, `tenant_member`, `platform_operator`, hoặc `system`. Không dùng role/Owner làm actor type. |
| `actor_user_id` | `uuid` | Không | Id platform user khi chủ thể gắn với một user. |
| `actor_membership_id` | `uuid` | Không | Id membership khi chủ thể hành động trong ngữ cảnh Tenant; null với platform admin, self-service identity, và tiến trình hệ thống. |
| `actor_display_name_snapshot` | `text` | Có | Tên hiển thị lịch sử của chủ thể; vẫn dùng được sau khi user/member bị xoá. |
| `actor_context_label` | `text` | Không | Nhãn role/owner/ngữ cảnh lịch sử, ví dụ `Chủ sở hữu`, `Kế toán`, `Nhân viên vận hành nền tảng`. |
| `actor_snapshot` | `jsonb` | Có, mặc định `{}` | Dữ liệu trình bày chủ thể bất biến bổ sung; đã được allowlist/redact. |
| `target_type` | `text` | Có | Loại thực thể/tham chiếu thật, ví dụ `Tenant`, `TenantMembership`, `TenantInvitation`, `PlatformUser`. |
| `target_id` | `text` | Có | Id target ổn định dạng text; không bịa định danh chỉ dùng cho UI làm nguồn tin cậy. |
| `target_display_name_snapshot` | `text` | Có | Tên hiển thị lịch sử của target. |
| `target_secondary_identifier` | `text` | Không | Định danh hiển thị phụ khi hợp đồng cho phép, ví dụ email hoặc mã số thuế sau chính sách redaction. |
| `target_snapshot` | `jsonb` | Có, mặc định `{}` | Dữ liệu trình bày target bất biến bổ sung; đã được allowlist/redact. |
| `source` | `text` | Có | Bề mặt/hệ thống nguồn: `tenant_app`, `admin`, `auth`, `system`, mã worker/source adapter. |
| `correlation_id` | `text` | Có | Id trace của operation nghiệp vụ; khác với `id` và `event_code`. |
| `tracking_id` | `text` | Không | Giá trị tracking/idempotency tương thích ngược khi khác `correlation_id`. |
| `source_event_refs` | `jsonb` | Có, mặc định `[]` | Mảng tham chiếu raw event bị gộp vào row activity này. |
| `detail_items` | `jsonb` | Có, mặc định `[]` | Nội dung detail render được ở server; giá trị đã redact. |
| `redaction_flags` | `text[]` | Có, mặc định `{}` | Lý do/chính sách redaction dạng machine-readable áp cho row này. |
| `occurred_at` | `timestamptz` | Có | Thời điểm server khi activity xảy ra. |
| `created_at` | `timestamptz` | Có | Thời điểm server khi row audit được lưu. |

### Ràng buộc bắt buộc (Constraints)

```sql
check (scope in ('tenant', 'platform'))
check (scope <> 'tenant' or tenant_id is not null)
check (result in ('success', 'blocked', 'error'))
check (actor_type in ('platform_user', 'tenant_member', 'platform_operator', 'system'))
```

### Index (đã chốt)

Các index này là chuẩn đã chốt cho `iam.audit_logs`. `audit_logs_tenant_occurred_idx`
đã có ở `20260811013`, và index platform ở đây đã tồn tại dưới tên
`audit_logs_scope_occurred_idx`; bốn index còn lại là quyết định phải thêm khi
triển khai schema (nằm ngoài phạm vi drop/retire của plan này).

```sql
create index audit_logs_tenant_occurred_idx
  on iam.audit_logs (tenant_id, occurred_at desc, id desc)
  where scope = 'tenant';

create index audit_logs_platform_occurred_idx
  on iam.audit_logs (occurred_at desc, id desc)
  where scope = 'platform';

create index audit_logs_correlation_idx
  on iam.audit_logs (correlation_id);

create index audit_logs_activity_idx
  on iam.audit_logs (activity_code, occurred_at desc);

create index audit_logs_actor_user_idx
  on iam.audit_logs (actor_user_id, occurred_at desc);

create index audit_logs_target_idx
  on iam.audit_logs (target_type, target_id, occurred_at desc);
```

### Cấu trúc wire của `detail_items`

```text
detail_items[]
  field_code: String
  label: String
  display_type: VALUE | DIFF
  value: String?
  before: String?
  after: String?
  redacted: bool
```

Ví dụ:

```json
[
  {
    "field_code": "role",
    "label": "Vai trò",
    "display_type": "DIFF",
    "before": "Nhân viên bán hàng",
    "after": "Kế toán",
    "redacted": false
  },
  {
    "field_code": "contact_email",
    "label": "Email liên hệ",
    "display_type": "DIFF",
    "before": "[Đã che]",
    "after": "[Đã che]",
    "redacted": true
  }
]
```

### Quy tắc mapping

- Dev không được render raw domain event trực tiếp. Domain event map qua một
  Audit Activity Mapping Catalog thành một `activity_code` và một row.
- `activity_code`, `event_code`, `id`, và `correlation_id` là các ngữ nghĩa
  riêng biệt, không được dùng lẫn cho nhau.
- Actor type không được là role, owner, hay permission. Role/Owner được lưu như
  actor context/snapshot.
- Target phải là loại thực thể/tham chiếu thật theo hợp đồng domain.
- Redaction diễn ra trước khi lưu; mobile không bao giờ nhận raw password,
  token, OTP, credential, secret, hay giá trị mã thô.
- Tenant App và Platform Admin App dùng chung schema lưu trữ và bộ render detail
  này; chúng chỉ khác nhau ở scope truy vấn, permission, và chính sách tiết lộ.

---

### Task 1: Khoá các quyết định dọn dẹp TH-01 vào harness docs

**Files:**
- Sửa: `docs/themes/TH-01-organization-users/harness/06-harness-notes.md`
- Sửa: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`

**Interfaces:**
- Consumes: các quyết định TH-01 rằng `iam.audit_logs` là canonical và PlatformOnboardingOperation là metadata điều phối.
- Produces: các ràng buộc dọn dẹp đã được tài liệu hoá cho Task 2 và 3.

- [ ] **Step 1: Thêm một harness note cho quyết định dọn dẹp**

Thêm hàng này vào bảng decision/debt log trong `docs/themes/TH-01-organization-users/harness/06-harness-notes.md`:

```markdown
| 2026-08-21 | IAM audit + owner activation implementation drift | Cleanup plan: drop legacy `iam.platform_audit_logs`; retire `iam.owner_activations`; keep platform audit on `iam.audit_logs(scope='platform')`; restore onboarding to pending Platform User + immediate Owner Membership per TH-01. `iam.platform_admins` remains a separate authz bootstrap discussion. |
```

- [ ] **Step 2: Thêm ràng buộc lưu trữ audit rõ ràng**

Trong `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`, dưới `§S13 — EP-02/US-07 — Tenant Audit history (V2)`, sau đoạn nói S16 platform audit dùng `iam.audit_logs(scope platform)`, thêm:

```markdown
Implementation constraint: IAM must not write to or read from `iam.platform_audit_logs`. That table is legacy storage and must be removed by draft cleanup; `SearchPlatformAuditLogsQuery` and `GetPlatformAuditLogQuery` read `iam.audit_logs` with `scope = 'platform'`.
```

- [ ] **Step 3: Thêm ràng buộc retire owner activation rõ ràng**

Trong `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`, dưới mục onboarding platform S15/S16 có liệt kê `CreateTenantOnboardingCommand`, thêm:

```markdown
Implementation constraint: onboarding must not create `iam.owner_activations` or require `inspect_owner_activation` / `accept_owner_activation`. For a new owner, onboarding creates a pending Platform User/profile, creates the Owner Membership atomically with the Tenant, sends activation invitation through Platform Identity/Auth, and relies on identity activation before the user can access Tenant App.
```

- [ ] **Step 4: Kiểm tra diff của doc**

Chạy:

```bash
git diff -- docs/themes/TH-01-organization-users/harness/06-harness-notes.md docs/themes/TH-01-organization-users/harness/07-api-contracts.md
```

Kỳ vọng: diff chứa hai ràng buộc trên và không nhắc tới việc thay đổi `iam.platform_admins`.

- [ ] **Step 5: Bàn giao để người dùng tự commit**

KHÔNG tự chạy `git commit`. Dừng lại, tóm tắt các file đã đổi, và để người dùng tự review + commit. Có thể gợi ý (không tự chạy) commit message: `docs(iam): record audit and owner activation cleanup decisions`.

---

### Task 2: Bỏ `platform_audit_logs` với vai trò kho audit cũ

**Files:**
- Tạo: `modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart`
- Tạo/Sửa: `supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql`
- Giữ nguyên: `supabase/migrations/20260811013_iam_platform_audit_read.sql`, trừ khi người dùng yêu cầu promote migration một cách rõ ràng.

**Interfaces:**
- Consumes: bảng `iam.audit_logs` và các RPC `iam.search_platform_audit_logs`, `iam.get_platform_audit_log`.
- Produces: SQL draft drop bảng và helper cũ trong khi vẫn giữ platform audit đọc từ kho canonical.

- [ ] **Step 1: Chạy GitNexus impact trước khi sửa các SQL contract test**

Chạy:

```text
mcp__gitnexus__impact({ "repo": "vet45", "target": "search_platform_audit_logs", "direction": "upstream" })
mcp__gitnexus__impact({ "repo": "vet45", "target": "suspend_platform_user", "direction": "upstream" })
```

Kỳ vọng: ghi lại rủi ro và các process bị ảnh hưởng vào task notes. Nếu rủi ro HIGH hoặc CRITICAL, dừng và báo cáo trước khi sửa.

Trước khi drop bảng cũ, xác nhận rằng các caller đang chạy chỉ dùng overload mới.
Gateway platform admin của `iam`
(`modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart`)
gọi `suspend_platform_user` với `p_expected_version` + `p_idempotency_key`,
và `restore_platform_user` / `send_activation_invitation` /
`request_platform_password_reset` với `p_expected_version` +
`p_idempotency_key`. Không overload nào trong số đó ghi vào `platform_audit_logs`;
chỉ các overload cũ 1-/2-tham số trong `20260811005` mới ghi. Nếu phát hiện caller
đang chạy dùng chữ ký cũ, dừng và báo cáo trước khi drop.

- [ ] **Step 2: Viết SQL cleanup contract test (đang fail)**

Tạo `modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String canonicalAuditSql;
  late String cleanupDraftSql;

  setUpAll(() {
    final root = _findRepoRoot();
    canonicalAuditSql = File(
      '${root.path}/supabase/migrations/20260811013_iam_platform_audit_read.sql',
    ).readAsStringSync();
    cleanupDraftSql = File(
      '${root.path}/supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql',
    ).readAsStringSync();
  });

  group('platform audit cleanup', () {
    test('platform audit reads canonical audit_logs only', () {
      // `get_platform_audit_log` và `search_platform_audit_logs` có thể xuất
      // hiện theo BẤT KỲ thứ tự nào trong file migration (hiện tại hàm detail
      // đứng trước). Cắt thân mỗi hàm từ header của chính nó đến ranh giới hàm
      // kế tiếp thay vì giả định thứ tự — cách cũ `substring(searchStart,
      // detailStart)` ném RangeError khi hàm detail được định nghĩa trước.
      String bodyOf(String header) {
        final start = canonicalAuditSql.indexOf(header);
        if (start < 0) return '';
        final next = canonicalAuditSql.indexOf(
          'create or replace function ',
          start + header.length,
        );
        return next < 0
            ? canonicalAuditSql.substring(start)
            : canonicalAuditSql.substring(start, next);
      }

      final searchBody = bodyOf(
        'create or replace function iam.search_platform_audit_logs(',
      );
      final detailBody = bodyOf(
        'create or replace function iam.get_platform_audit_log(',
      );
      expect(searchBody, isNotEmpty);
      expect(detailBody, isNotEmpty);

      expect(searchBody, contains('from iam.audit_logs a'));
      expect(searchBody, contains("where a.scope = 'platform'"));
      expect(searchBody, isNot(contains('from iam.platform_audit_logs')));

      expect(detailBody, contains('from iam.audit_logs a'));
      expect(detailBody, contains("and a.scope = 'platform'"));
      expect(detailBody, isNot(contains('from iam.platform_audit_logs')));
    });

    test('cleanup draft drops legacy platform_audit_logs storage', () {
      expect(
        cleanupDraftSql,
        contains('drop table if exists iam.platform_audit_logs'),
      );
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam._platform_audit_redacted_payload(jsonb)'),
      );
      expect(
        cleanupDraftSql,
        isNot(contains('insert into iam.platform_audit_logs')),
      );
    });

    test('cleanup draft drops the dead legacy lifecycle overloads that still '
        'wrote to platform_audit_logs', () {
      // Gateway đang chạy gọi các overload mới mang
      // (p_expected_version, p_idempotency_key); các overload đó KHÔNG chạm
      // platform_audit_logs. Chỉ các overload cũ 1-/2-tham số này còn tham
      // chiếu bảng, nên phải drop chúng TRƯỚC bảng, nếu không chúng bị bỏ lại
      // với tham chiếu tới một relation đã biến mất.
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.suspend_platform_user(uuid, text)'),
      );
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.restore_platform_user(uuid)'),
      );
      expect(
        cleanupDraftSql,
        contains('drop function if exists iam.send_activation_invitation(uuid)'),
      );
      expect(
        cleanupDraftSql,
        contains(
          'drop function if exists iam.request_platform_password_reset(uuid)',
        ),
      );
    });
  });
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Step 3: Chạy test tập trung và xác nhận nó FAIL**

Chạy:

```bash
dart test modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart
```

Kỳ vọng: FAIL vì `supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql` chưa tồn tại.

- [ ] **Step 4: Tạo draft SQL cleanup**

Tạo `supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql` với nội dung khởi tạo này:

```sql
-- Title: iam audit + owner activation cleanup
-- Kind: patch
-- Intent: iam_audit_owner_activation_cleanup
-- Touches: iam.suspend_platform_user, iam.restore_platform_user, iam.send_activation_invitation, iam.request_platform_password_reset, iam._platform_audit_redacted_payload, iam.platform_audit_logs, iam.owner_activations, iam.inspect_owner_activation, iam.accept_owner_activation, iam.create_tenant_onboarding

-- `iam.audit_logs` is the canonical IAM audit store for tenant and platform
-- views. `iam.platform_audit_logs` was a mis-designed compatibility store and
-- is being removed entirely.
--
-- The live platform user lifecycle RPCs are the newer overloads that carry
-- (p_expected_version, p_idempotency_key); they already do NOT write to
-- platform_audit_logs (they use iam.platform_user_lifecycle_operations). Only
-- the older 1-/2-arg overloads below still reference the table, and nothing
-- reads it (platform audit reads come from iam.audit_logs scope='platform').
-- Drop the dead overloads FIRST so the table can be removed without leaving
-- functions that reference a missing relation.
drop function if exists iam.suspend_platform_user(uuid, text);
drop function if exists iam.restore_platform_user(uuid);
drop function if exists iam.send_activation_invitation(uuid);
drop function if exists iam.request_platform_password_reset(uuid);
drop function if exists iam._platform_audit_redacted_payload(jsonb);
drop table if exists iam.platform_audit_logs;
```

- [ ] **Step 5: Chạy test tập trung và xác nhận nó PASS**

Chạy:

```bash
dart test modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart
```

Kỳ vọng: PASS.

- [ ] **Step 6: Bàn giao để người dùng tự commit**

KHÔNG tự chạy `git commit`. Dừng lại, tóm tắt các file đã đổi, và để người dùng tự review + commit. Có thể gợi ý (không tự chạy) commit message: `chore(iam): draft removal of legacy platform audit table`.

---

### Task 3: Retire `owner_activations` — hợp nhất owner vào luồng mời (Design A)

**Quyết định thiết kế (Design A):** Owner **dùng CHUNG** cơ chế mã kích hoạt với
staff, thay vì bảng song song `owner_activations`. Mã kích hoạt sống trong
`tenant_invitations.token_hash`, xác minh bởi `iam.inspect_invitation_token`,
tiêu thụ bởi `iam.accept_invitation`, owner/staff nhập mã ở **cùng** màn hình ERP
`InvitationTokenPage`; worker chỉ gửi mã. `owner_activations` là bản sao thừa của
CẢ cơ chế mã lẫn việc tạo membership → drop hoàn toàn.

- **Onboarding** (Platform Admin) tạo tenant + một **lời mời OWNER** trên
  `tenant_invitations` (`is_owner=true`, giữ mã, `invited_by_membership_id=null`);
  worker gửi mã. **KHÔNG** tạo membership, **KHÔNG** pre-create auth user.
- **Owner accept**: nhập mã → (owner mới) `auth.signUp(email,password)` →
  `accept_invitation`. Hàm này **tự** biến người active đầu tiên của tenant thành
  `store_owner` + `is_owner` qua nhánh `v_should_be_owner` sẵn có — nên accept/
  inspect **không cần** logic owner riêng, chỉ cần **gỡ fallback `owner_activations`** cũ.
- Owner mới **không** pre-create ⇒ tránh lỗi "Chưa xác định owner" trước đây.
- Pending owner hiển thị cho Platform Admin dưới dạng **dòng lời mời owner đang
  pending** (không phải bản ghi user) cho tới khi accept — đánh đổi đã chấp nhận.

**Files:**
- Create: `modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart`
- Modify: `supabase/migrations/_drafts/006_iam_audit_owner_activation_cleanup.sql`
- Archive: `supabase/migrations/_drafts/_archive/001_iam_pending_platform_profile_onboarding.sql`
- Modify: `modules/iam/infrastructure/test/iam_owner_activation_rpc_contract_test.dart` (repoint sang draft — Step 8)
- Modify: `modules/iam/infrastructure/test/iam_owner_activation_store_owner_role_sql_contract_test.dart` (trim — Step 8b)
- Giữ nguyên: `modules/iam/infrastructure/test/iam_create_tenant_onboarding_new_owner_sql_contract_test.dart` (đọc promoted `20260811006`; không mâu thuẫn)
- Delete: `modules/iam/infrastructure/test/iam_pending_platform_profile_onboarding_sql_contract_test.dart` (Step 8c)
- Modify: `apps/erp/lib/core/router/app_router.dart` (gỡ import + route `/owner-activation`)
- Modify: `apps/erp/test/features/auth/presentation/wgt_th01_s0_login_test.dart` (gỡ test-block owner-activation + class `_NoCurrentUser` thừa)
- Delete: `apps/erp/lib/features/auth/data/owner_activation_client.dart`
- Delete: `apps/erp/lib/features/auth/presentation/bloc/owner_activation_cubit.dart`
- Delete: `apps/erp/lib/features/auth/presentation/bloc/owner_activation_state.dart`
- Delete: `apps/erp/lib/features/auth/presentation/pages/owner_activation_page.dart`
- Delete: `apps/erp/test/features/auth/presentation/owner_activation_page_test.dart`
- Delete: `apps/erp/test/features/auth/presentation/owner_activation_cubit_test.dart`

**Interfaces:**
- Consumes: `iam.tenant_invitations`, `iam.role_definitions` (mã `store_owner`), token helper `iam._generate_invitation_code` / `iam._invitation_token_hash` / `iam._load_invitation_by_token`, outbox `iam.enqueue_outbox_message`, `iam.record_email_delivery_outcome`, `iam.create_tenant_onboarding`, `iam.accept_invitation`, `iam.inspect_invitation_token`.
- Produces: onboarding phát lời mời owner trên `tenant_invitations`; owner + staff accept qua cùng một hàm; `owner_activations` + RPC bị gỡ.

- [ ] **Step 1: GitNexus impact + liệt kê consumer của `owner_activations`**

```text
mcp__gitnexus__impact({ "repo": "vet45", "target": "create_tenant_onboarding", "direction": "upstream" })
mcp__gitnexus__impact({ "repo": "vet45", "target": "accept_invitation", "direction": "upstream" })
```

```bash
grep -rln "owner_activations" supabase/migrations
```

Kỳ vọng: ghi rủi ro; nếu HIGH/CRITICAL dừng và báo cáo. Consumer của `owner_activations` là `20260811006`/`20260820003` (onboarding), `20260811020` (accept + inspect), `20260811023` (RPC), `20260820006` (prefill) — draft phải thay/gỡ tham chiếu ở onboarding/accept/inspect TRƯỚC khi drop. `accept_invitation` blast radius rộng (staff + owner) — cảnh báo người dùng.

- [ ] **Step 2: Viết retirement contract test (đang fail)**

Tạo `modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart` đọc draft cleanup và assert (dùng helper `bodyOf` cắt tới `$$;` để không dính comment/drop của block sau):
- `tenant_invitations` được thêm `is_owner` + `alter column invited_by_membership_id drop not null` + check `tenant_invitations_owner_inviter_chk`.
- `create_tenant_onboarding` chứa `insert into iam.tenant_invitations` + `is_owner` + `'template_id', 'activation_invitation'`; **không** `insert into iam.memberships`; **không** `owner_activations`.
- `accept_invitation` không còn `owner_activations`; có `v_should_be_owner` + `'store_owner'`.
- `inspect_invitation_token` không còn `owner_activations`.
- Có `drop ... iam.inspect_owner_activation(text)`, `drop ... iam.accept_owner_activation(text, text)`, `drop table if exists iam.owner_activations`.

- [ ] **Step 3: Chạy test, xác nhận FAIL**

```bash
dart test modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart
```

- [ ] **Step 4: Draft SQL — cho `tenant_invitations` chứa được lời mời owner**

Thêm vào draft (sau phần audit):

```sql
alter table iam.tenant_invitations
  add column if not exists is_owner boolean not null default false;
alter table iam.tenant_invitations
  alter column invited_by_membership_id drop not null;
alter table iam.tenant_invitations
  drop constraint if exists tenant_invitations_owner_inviter_chk;
alter table iam.tenant_invitations
  add constraint tenant_invitations_owner_inviter_chk
  check (is_owner or invited_by_membership_id is not null);
```

- [ ] **Step 5: Draft SQL — thay `create_tenant_onboarding` để phát lời mời owner**

`create or replace function iam.create_tenant_onboarding(...)` dùng đúng 18 tham số của `20260820003`. Giữ: perms `platform.tenant.create`, validate, idempotency `iam.onboarding_operations`, insert tenant `provisioning`, `tenant_legal_profiles`, outbox `iam.tenant.created`. Thay phần owner:

```sql
-- Fragment bắt buộc:
-- 1. Owner email: owner cũ resolve từ auth.users theo p_owner_user_id; owner mới lấy từ tham số.
-- 2. Role cho lời mời (FK): select id into v_owner_role_id from iam.role_definitions
--    where code = 'store_owner' and status = 'active';  (accept override sang store_owner qua v_should_be_owner)
-- 3. Sinh mã: v_raw_code := iam._generate_invitation_code();
--    v_code_hash := iam._invitation_token_hash(v_raw_code);
--    v_ciphertext := 'transient:' || encode(convert_to(v_raw_code,'UTF8'),'base64');
-- 4. Lời mời OWNER (is_owner, không người mời):
insert into iam.tenant_invitations (
  tenant_id, invitee_email, initial_role_id, status, token_hash,
  is_owner, invited_by_membership_id, expires_at, status_changed_at,
  version, created_at, updated_at, delivery_correlation_id
)
values (
  v_tenant_id, v_owner_email, v_owner_role_id, 'pending', v_code_hash,
  true, null, v_now + interval '7 days', v_now,
  1, v_now, v_now, v_correlation
)
returning id into v_invitation_id;
-- 5. Gửi email 'activation_invitation' kèm secret_payload_ciphertext (mã); rồi v_raw_code := null.
-- 6. KHÔNG insert iam.memberships. KHÔNG iam.owner_activations. result.owner_membership_id = null.
```

- [ ] **Step 6: Draft SQL — gỡ fallback owner-activation khỏi accept + inspect**

`create or replace` lại `iam.accept_invitation(text, text)` và `iam.inspect_invitation_token(text)` bằng cách **sao thân hiện tại** (`20260811020` cho accept; `20260820006` cho inspect — bản mới nhất), rồi **xoá khối `exception when others ... owner_activations ... end`** (fallback). Nhánh staff giữ nguyên — nó ĐÃ biến người active đầu tiên thành `store_owner`/`is_owner` qua `v_should_be_owner`, nên phục vụ cả owner. Yêu cầu: 2 hàm này **không còn** tham chiếu `iam.owner_activations`.

- [ ] **Step 7: Draft SQL — drop `owner_activations` + RPC**

Sau khi onboarding/accept/inspect đã sạch tham chiếu:

```sql
drop function if exists iam.inspect_owner_activation(text);
drop function if exists iam.accept_owner_activation(text, text);
drop table if exists iam.owner_activations;
```

Chạy `dart test .../iam_owner_activation_retirement_sql_contract_test.dart` → PASS.

- [ ] **Step 8: Repoint `iam_owner_activation_rpc_contract_test.dart`**

Đọc draft cleanup; assert drops + onboarding phát lời mời (`insert into iam.tenant_invitations`, `is_owner`, không `insert into iam.memberships`, không `owner_activations`).

- [ ] **Step 8b: Trim `iam_owner_activation_store_owner_role_sql_contract_test.dart`**

Bỏ test `accept_owner_activation creates owner membership...` (RPC bị retire); giữ 2 test canonicalization + `list_accessible_tenants` (đọc `20260811024` / `20260811014`). Nếu biến đọc `20260811023` thành thừa, xoá luôn. `dart analyze` sạch.

- [ ] **Step 8c: Xoá `iam_pending_platform_profile_onboarding_sql_contract_test.dart`**

Test này khoá draft `_drafts/001_...` dựa trên `owner_activations` (đã retire).

- [ ] **Step 9: Chạy test tập trung + chốt sạch**

```bash
dart test modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart \
          modules/iam/infrastructure/test/iam_owner_activation_rpc_contract_test.dart \
          modules/iam/infrastructure/test/iam_owner_activation_store_owner_role_sql_contract_test.dart \
          modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart
grep -rn "owner_activations\|001_iam_pending_platform_profile_onboarding" modules/iam/infrastructure/test
```

Kỳ vọng: PASS; grep chỉ khớp assertion retirement (drop / `isNot(contains(...))`).

> **Lưu ý:** 3 test đọc migration **đã promote** vẫn xanh vì draft chưa promote — `iam_tenant_audit_v2_payload`, `iam_tenant_invitation_acceptance`, `iam_fix_utc_now_offset`. Chúng assert `owner_activations` cũ; sẽ **đỏ khi promote** draft, cập nhật lúc đó.

- [ ] **Step 10: Gỡ owner-activation UI ở ERP (owner dùng chung màn mời)**

Trong `app_router.dart` gỡ import `OwnerActivationPage` + route `/owner-activation`. Xoá 4 file lib + 2 test owner-activation. Trong `wgt_th01_s0_login_test.dart` gỡ test-block `wgt_th01_s0_owner_activation_redirects_to_login_until_defined` + class `_NoCurrentUser` thừa. Chốt:

```bash
grep -rn "OwnerActivation\|owner_activation" apps/erp/lib apps/erp/test
```

Kỳ vọng: chỉ còn route stub cục bộ vô hại trong login test (chứng minh nút "Kích hoạt tài khoản" đi tới `/invitation`).

> **Lưu ý (app/worker, ngoài draft SQL):** email owner (template `activation_invitation`) và deep-link phải trỏ owner về **`/invitation`** (InvitationTokenPage), không phải màn owner-activation đã xoá. Owner mới `signUp` lúc accept; owner cũ `signInWithPassword` rồi accept — InvitationTokenPage đã có sẵn 2 nhánh này theo `account_exists`.

- [ ] **Step 11: Chạy test auth ERP**

```bash
cd apps/erp && flutter test test/features/auth
```

Kỳ vọng: PASS.

- [ ] **Step 12: Bàn giao để người dùng tự commit**

KHÔNG tự chạy `git commit`. Tóm tắt file đã đổi (gồm file xoá Step 8c/10 + trim Step 8b/10) và để người dùng review + commit. Gợi ý (không tự chạy): `refactor(iam): retire owner_activations, unify owner into invitation flow`.

---

### Task 4: Kiểm tra cuối và rà soát phạm vi thay đổi

**Files:**
- Chỉ sửa các file thuộc Task 1-3.
- Không sửa `iam.platform_admins` hay tooling của nó trong kế hoạch này.

**Interfaces:**
- Consumes: các thay đổi doc, draft SQL, test, và dọn dẹp ERP đã hoàn tất.
- Produces: branch dọn dẹp đã được kiểm tra, sẵn sàng review/thảo luận.

- [ ] **Step 1: Format các file Dart**

Chạy:

```bash
dart format modules/iam/infrastructure/test apps/erp/lib/core/router
```

Kỳ vọng: formatter exit 0.

- [ ] **Step 2: Chạy các test IAM infrastructure tập trung**

Chạy:

```bash
dart test modules/iam/infrastructure/test/iam_audit_legacy_cleanup_sql_contract_test.dart
dart test modules/iam/infrastructure/test/iam_owner_activation_retirement_sql_contract_test.dart
dart test modules/iam/infrastructure/test/iam_owner_activation_rpc_contract_test.dart
```

Kỳ vọng: tất cả PASS.

- [ ] **Step 3: Chạy kiểm tra migration policy**

Chạy:

```bash
melos run migrate:verify-policy -- --strict
```

Kỳ vọng: PASS, hoặc chỉ báo rằng draft SQL không phải migration timestamp đã promote. Nếu nó cảnh báo `-- Touches`, cập nhật header của draft cleanup để liệt kê đúng các RPC dùng `create or replace`.

- [ ] **Step 4: Chạy harness guard**

Chạy:

```bash
bash scripts/ci/verify_harness.sh
```

Kỳ vọng: PASS, hoặc chỉ có nợ presentation-size đã biết từ trước nằm ngoài phạm vi dọn dẹp IAM. Ghi lại mọi baseline failure không liên quan vào phần handoff cuối.

- [ ] **Step 5: Chạy GitNexus detect changes**

Chạy:

```text
mcp__gitnexus__detect_changes({ "repo": "vet45", "scope": "all" })
```

Kỳ vọng: các symbol/file thay đổi chỉ giới hạn ở docs TH-01, các SQL contract test của IAM infrastructure, draft SQL cleanup, và việc bỏ route/file auth của ERP. Không có thay đổi `platform_admins`.

- [ ] **Step 6: Bàn giao verification để người dùng tự commit (nếu có)**

KHÔNG tự chạy `git commit`. Chạy `git status --short` để liệt kê thay đổi còn lại, tóm tắt cho người dùng, và để người dùng tự review + commit. Có thể gợi ý (không tự chạy) commit message: `test(iam): verify audit and owner activation cleanup`.

```bash
git status --short
```

Kỳ vọng: nếu không có thay đổi nào so với lần bàn giao trước, ghi "no verification diff" và không cần bàn giao commit thêm.

---

### Task 5: Redesign `iam.audit_logs` sang schema V2 (big-bang, dev)

**Quyết định:** Vì đang **dev (chưa production, không có data cần giữ)**, làm **big-bang** — dựng lại `iam.audit_logs` theo schema đã chốt ở mục "Quyết định thiết kế: schema `iam.audit_logs`" (không giữ cột cũ `subject_*`/`tracking_id`/`before_after`), rồi viết lại toàn bộ writer + caller + read RPC + lớp Dart. Chia **5 phase, verify từng phase**. SQL chỉ ở draft (`supabase/migrations/_drafts/007_iam_audit_logs_v2_rebuild.sql`); Dart là code thật.

> **Blast radius:** `append_audit_log` có ~15 call site ở 11 migration đã promote (811011/014/015/016/017/018/020/023/005, 820005...); 4 read RPC ở 811013; lớp Dart audit (port/handler/DTO + tests). Đổi chữ ký writer ⇒ phải `create or replace` lại tất cả caller trong draft.

**Files:**
- Create: `supabase/migrations/_drafts/007_iam_audit_logs_v2_rebuild.sql` (toàn bộ SQL của Task 5).
- Create: `modules/iam/infrastructure/test/iam_audit_logs_v2_schema_sql_contract_test.dart` (khoá schema + writer + read RPC V2).
- Modify (Dart): read port + query handler + DTO audit (`modules/iam/application/lib/src/tenant/...audit...`, `modules/iam/infrastructure/lib/src/...audit...`) + tests tương ứng.

- [ ] **Phase 1 — Schema V2**

Tạo draft `007_iam_audit_logs_v2_rebuild.sql`: `drop table if exists iam.audit_logs cascade;` rồi `create table iam.audit_logs (...)` theo đúng bảng cột ở mục quyết định (id, scope, tenant_id, activity_code, event_code, event_category, result, title_snapshot, actor_type, actor_user_id, actor_membership_id, actor_display_name_snapshot, actor_context_label, actor_snapshot, target_type, target_id, target_display_name_snapshot, target_secondary_identifier, target_snapshot, source, correlation_id, tracking_id, source_event_refs, detail_items, redaction_flags, occurred_at, created_at) + 4 `check` + 6 index. Viết test schema (đỏ→xanh).

- [ ] **Phase 2 — `append_audit_log` V2**

`create or replace function iam.append_audit_log(...)` chữ ký V2 (nhận activity_code, event_code, event_category, result, title_snapshot, actor_type, actor_*_snapshot, target_*, source, correlation_id, detail_items, redaction_flags...). Giữ tham số hợp lý có default để caller gọn.

- [ ] **Phase 3 — Viết lại ~15 caller**

Trong draft, `create or replace` lại từng hàm có gọi `append_audit_log` (811011/014/015/016/017/018/020/023/005, 820005 + accept/inspect ở cleanup draft) sao cho map sang chữ ký V2 (subject→target, tracking→correlation, before/after→detail_items). Chốt: `grep -rn "append_audit_log(" draft` — mọi call site dùng đúng tham số V2.

- [ ] **Phase 4 — 4 read RPC V2**

`create or replace` `search_platform_audit_logs`, `get_platform_audit_log`, `search_tenant_audit_logs`, `get_tenant_audit_log` đọc cột V2 (target_*, correlation_id, detail_items...). Cập nhật shape trả về.

- [ ] **Phase 5 — Dart audit layer + tests**

Sửa read port + query handler + DTO (`tenant_audit_log_result`, `..._search_page_dto`, platform tương ứng) map cột V2; cập nhật contract/infra tests. Chạy `dart test modules/iam` xanh.

- [ ] **Phase 6 — Verify Task 5**

`melos run migrate:verify-policy -- --strict`; `dart test modules/iam`; `bash scripts/ci/verify_harness.sh`. Bàn giao (không tự commit).

---

## Tự rà soát (Self-Review)

**Độ phủ spec:** Task 1 ghi lại các quyết định dọn dẹp TH-01. Task 2 bỏ bảng Platform Audit dư thừa (và các overload lifecycle cũ 1-/2-tham số vốn là writer duy nhất còn lại của nó) trong khi vẫn giữ `iam.audit_logs(scope='platform')` và không đụng các overload đang chạy `(…, p_expected_version, p_idempotency_key)`. Task 3 retire `owner_activations` theo **Design A (hợp nhất owner vào luồng mời)**: `create_tenant_onboarding` phát một **lời mời owner** trên `tenant_invitations` (`is_owner`, giữ mã, `invited_by_membership_id=null`), worker gửi mã; membership tạo **lúc accept** — `accept_invitation` tự biến người active đầu tiên thành `store_owner`/`is_owner` qua `v_should_be_owner`, nên chỉ cần **gỡ fallback `owner_activations`** khỏi `accept_invitation` + `inspect_invitation_token`, rồi drop `owner_activations` + RPC. Owner và staff dùng **chung** cơ chế mã + màn hình `InvitationTokenPage`. Mỗi test owner-activation hiện có được xử lý rõ ràng — repoint sang draft cleanup (`iam_owner_activation_rpc_contract_test`, Step 8), trim bỏ assertion `accept_owner_activation` (`iam_owner_activation_store_owner_role_sql_contract_test`, Step 8b), giữ nguyên vì nó khoá onboarding promoted `20260811006` (`iam_create_tenant_onboarding_new_owner_sql_contract_test`), hoặc xoá vì nó khoá draft dựa trên `owner_activations` đã retire (`iam_pending_platform_profile_onboarding_sql_contract_test`, Step 8c). Task 4 kiểm tra phạm vi và cố ý để `platform_admins` nguyên vẹn.

**Rà placeholder:** Task 3 Step 5/6 cố ý đưa *fragment* cho thân `create_tenant_onboarding` và cho việc gỡ fallback owner khỏi `accept_invitation`/`inspect_invitation_token` — agent dựng thân hàm hoàn chỉnh bằng cách sao từ bản hiện hành (`20260820003` cho onboarding, `20260811020` cho accept, `20260820006` cho inspect) rồi áp fragment/gỡ khối `exception when others`, theo lưu ý trong từng Step. Việc email/deep-link owner trỏ về `/invitation` và owner mới `signUp`/owner cũ `signInWithPassword` lúc accept là tích hợp app/worker, cố ý nằm ngoài draft SQL (đã ghi chú ở Step 10). Các task còn lại có đủ file chính xác, nội dung test, lệnh, và kết quả kỳ vọng.

**Nhất quán kiểu/chữ ký:** Tên file test và tên object SQL nhất quán qua các task: `006_iam_audit_owner_activation_cleanup.sql`, `iam_audit_legacy_cleanup_sql_contract_test.dart`, `iam_owner_activation_retirement_sql_contract_test.dart`, `iam.search_platform_audit_logs`, `iam.get_platform_audit_log`, `iam.create_tenant_onboarding`, `iam.accept_invitation`, `iam.inspect_invitation_token`, `iam.inspect_owner_activation`, và `iam.accept_owner_activation`.
