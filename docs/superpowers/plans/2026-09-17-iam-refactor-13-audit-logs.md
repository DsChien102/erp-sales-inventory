# IAM refactor — Bảng 13 `iam.audit_logs` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ cột `iam.audit_logs.created_at` (luôn bằng `occurred_at`, không ai đọc) — **sửa trực tiếp migration gốc**.

**Architecture:** Một task: sửa `create table iam.audit_logs` và câu insert trong `iam.append_audit_log` (cùng file `20260826004_iam_audit_logs_v2_rebuild.sql`, file owner). Key JSON `created_at` của các RPC đọc đã lấy từ `occurred_at` → không đổi.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [13-audit-logs.md](../specs/iam-schema-refactor/13-audit-logs.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 12.
- Không đổi chữ ký `append_audit_log`; tham số `p_occurred_at` giữ nguyên.
- Không promote, **không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "append_audit_log" --direction upstream --repo .` (hàm SQL → `UNKNOWN`).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260826004_…` `create table iam.audit_logs` | `created_at timestamptz not null default now(),` |
| `20260826004_…` `append_audit_log` (định nghĩa cuối) | danh sách cột insert `…, redaction_flags, occurred_at, created_at` và giá trị `coalesce(p_occurred_at, v_now), v_now` |
| `20260826004_…` RPC đọc | `a.occurred_at as created_at`, `'created_at', f.occurred_at` — alias đầu ra, **giữ** |
| `20260811013_iam_platform_audit_read.sql` | `create table iam.audit_logs` bản cũ — bị `drop table if exists iam.audit_logs cascade` ở `20260826004` → không ảnh hưởng |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260826004_iam_audit_logs_v2_rebuild.sql` | Bỏ cột + insert |
| Create `modules/iam/infrastructure/test/iam_refactor_13_audit_logs_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ `created_at`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor bảng 13 `iam.audit_logs`
/// (docs/superpowers/specs/iam-schema-refactor/13-audit-logs.md).
void main() {
  final sql = _readMigration('20260826004_iam_audit_logs_v2_rebuild.sql');

  test('audit_logs table has occurred_at and no created_at', () {
    final start = sql.indexOf('create table iam.audit_logs (');
    final table = sql.substring(start, sql.indexOf('\n);', start));
    expect(table, contains('occurred_at timestamptz not null default now(),'));
    expect(table, isNot(contains('created_at')));
  });

  test('append_audit_log no longer writes created_at', () {
    final body = _lastFunctionBlock(sql, 'iam.append_audit_log');
    expect(body, contains('redaction_flags, occurred_at\n'));
    expect(body, isNot(contains('occurred_at, created_at')));
    expect(body, isNot(contains('coalesce(p_occurred_at, v_now), v_now')));
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
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

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_13_audit_logs_sql_contract_test.dart`
Expected: FAIL 2 test.

- [ ] **Step 3: Sửa `create table iam.audit_logs`** — xoá dòng `  created_at timestamptz not null default now(),` (ngay sau `  occurred_at timestamptz not null default now(),`).

- [ ] **Step 4: Sửa `append_audit_log`**
1. `    redaction_flags, occurred_at, created_at` → `    redaction_flags, occurred_at`
2. `    coalesce(p_occurred_at, v_now), v_now` → `    coalesce(p_occurred_at, v_now)`

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_13_audit_logs_sql_contract_test.dart test/iam_audit_logs_v2_schema_sql_contract_test.dart test/iam_audit_read_sql_contract_test.dart test/iam_audit_storage_sql_contract_test.dart test/iam_audit_producer_sql_contract_test.dart`
Expected: PASS (sửa assertion cũ nếu kiểm tra `created_at` của bảng audit; trừ baseline fail sẵn).

- [ ] **Step 6: Grep + policy**
- `grep -nE "audit_logs.*created_at|\ba\.created_at\b" supabase/migrations/20260826004_iam_audit_logs_v2_rebuild.sql` → không còn tham chiếu cột (alias đầu ra `as created_at` / `'created_at', f.occurred_at` được phép).
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.

- [ ] **Step 7: Tiến độ spec** — dòng bảng 13 README: `✅ Đã chốt · bỏ created_at · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 8: Dừng — user reset + smoke test**

Sau `supabase db reset`: thực hiện vài thao tác (sửa hồ sơ tổ chức, mời người, tạm ngừng tổ chức); mở màn audit tổ chức và audit nền tảng → danh sách, chi tiết, thời gian hiển thị đúng.
```sql
select column_name from information_schema.columns
where table_schema = 'iam' and table_name = 'audit_logs' and column_name in ('occurred_at', 'created_at');
```
Expected: chỉ `occurred_at`.
Đề xuất commit: `refactor(iam): drop audit_logs.created_at`.
