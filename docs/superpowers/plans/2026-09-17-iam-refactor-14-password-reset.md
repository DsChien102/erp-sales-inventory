# IAM refactor — Bảng 14 password reset Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xoá phần chuyển tiếp cũ (khối `DO` drop bảng hình dạng cũ + `add column code_hash`) trong migration tạo `password_reset_operations`, và sửa câu mô tả trong domain model cho khớp code. Không đổi schema cuối, không đổi RPC.

**Architecture:** Một task sửa `20260811021_iam_password_reset_operations.sql` và `docs/themes/TH-01-organization-users/harness/01-domain-model.md`.

**Tech Stack:** PostgreSQL/Supabase; Dart `package:test`.

**Spec:** [14-password-reset.md](../specs/iam-schema-refactor/14-password-reset.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 13 (độc lập nội dung).
- Không đổi `create table iam.password_reset_operations` (vẫn có `code_hash`), index, RLS, revoke, hàm.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260811021_iam_password_reset_operations.sql` | Xoá 2 đoạn chuyển tiếp |
| Modify `docs/themes/TH-01-organization-users/harness/01-domain-model.md` | Sửa 1 dòng |
| Create `modules/iam/infrastructure/test/iam_refactor_14_password_reset_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Dọn migration + sửa domain model

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 14 password reset
/// (docs/superpowers/specs/iam-schema-refactor/14-password-reset.md).
void main() {
  final sql = File(
    '${_findRepoRoot().path}/supabase/migrations/20260811021_iam_password_reset_operations.sql',
  ).readAsStringSync();

  test('no legacy-shape upgrade guards remain', () {
    expect(sql, isNot(contains('drop table iam.password_reset_operations cascade')));
    expect(sql, isNot(contains('delivery_code')));
    expect(sql, isNot(contains('add column if not exists code_hash')));
  });

  test('table still stores only the code hash', () {
    final start = sql.indexOf('create table if not exists iam.password_reset_operations (');
    final table = sql.substring(start, sql.indexOf('\n);', start));
    expect(table, contains('code_hash text,'));
    expect(table, contains('attempt_count int not null default 0,'));
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

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_14_password_reset_sql_contract_test.dart`
Expected: FAIL test 1.

- [ ] **Step 3: Sửa `20260811021_iam_password_reset_operations.sql`**

1. Xoá comment + khối:
```sql
-- Drop legacy / incompatible shape so draft re-apply is idempotent.
-- Legacy 022 shape is identified by the plaintext `delivery_code` column or the
-- absence of `operation_id`. The B2 shape (operation_id + code_hash, no
-- delivery_code) is preserved across re-applies.
do $$
begin
  if to_regclass('iam.password_reset_operations') is null then
    return;
  end if;
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'iam'
      and table_name = 'password_reset_operations'
      and column_name = 'delivery_code'
  ) or not exists (
    select 1
    from information_schema.columns
    where table_schema = 'iam'
      and table_name = 'password_reset_operations'
      and column_name = 'operation_id'
  ) then
    drop table iam.password_reset_operations cascade;
  end if;
end $$;
```
2. Xoá comment + câu:
```sql
-- Idempotent for DBs already carrying the metadata-only B2 predecessor.
alter table iam.password_reset_operations
  add column if not exists code_hash text;
```

- [ ] **Step 4: Sửa domain model** — trong `docs/themes/TH-01-organization-users/harness/01-domain-model.md`, thay dòng:
```markdown
- **PasswordResetOperation** (`iam.password_reset_operations`): chỉ metadata trạng thái/timing; recovery OTP + password authoritative ở Supabase Auth, không lưu code.
```
bằng:
```markdown
- **PasswordResetOperation** (`iam.password_reset_operations`): trạng thái/timing của phiên đặt lại mật khẩu bằng mã 6 số do IAM phát; chỉ lưu **bản băm** của mã (`code_hash`), không lưu mã gốc; mật khẩu authoritative ở Supabase Auth.
```

- [ ] **Step 5: Chạy test + policy**
- `cd modules/iam/infrastructure && dart test test/iam_refactor_14_password_reset_sql_contract_test.dart` → PASS
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK

- [ ] **Step 6: Tiến độ spec** — dòng bảng 14 README: `✅ Đã chốt · giữ nguyên · dọn migration + domain model · 📝 Plan … · 🧪 Đã sửa, chờ reset`.

- [ ] **Step 7: Dừng — user reset + smoke test**

Sau `supabase db reset`: quên mật khẩu ở màn đăng nhập (nhận mã, nhập sai 1 lần, nhập đúng, đặt mật khẩu mới, đăng nhập lại); đổi mật khẩu khi đã đăng nhập.
Đề xuất commit: `chore(iam): drop legacy password reset upgrade guards; fix domain model wording`.
