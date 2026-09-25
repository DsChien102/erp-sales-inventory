# Sales refactor — Bảng 3 `sales.sales_order_drafts` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 5 cột không dùng của `sales.sales_order_drafts` (`sales_shift_id`, `expires_at`, `expired_at`, `converted_at`, `cancelled_at`) và tách `preview_snapshot` thành 4 cột rõ ràng — **sửa trực tiếp migration gốc**, giữ nguyên JSON trả app.

**Architecture:** Bảng ở `20260830005`. Mọi RPC nháp + helper ở `20260830007` (file owner). `finalize_sales_order` (`20260830008`) chỉ đổi câu chuyển nháp sang `converted`. Helper `_draft_preview_snapshot` được thay bằng `_draft_customer_snapshot`.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [03-sales-order-drafts.md](../specs/sales-schema-refactor/03-sales-order-drafts.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 1 và 2 (cùng sửa `007`, `008`) — tìm theo nội dung, không theo số dòng.
- Không đổi tên/tham số/key JSON của 5 RPC nháp và `finalize_sales_order`.
- Giữ giá trị `expired` trong CHECK `status`.
- Không sửa `modules/sales/infrastructure/test/domain/sales_order_draft/sales_order_draft_sql_contract_test.dart` (baseline fail `setUpAll`).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "_draft_payload" --direction upstream --repo .`, tương tự cho `save_sales_order_draft`, `update_sales_order_draft`, `cancel_sales_order_draft`, `get_sales_order_draft_for_restore`, `finalize_sales_order` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_drafts` | 17 cột gồm `sales_shift_id`, `preview_snapshot`, `expires_at`, `converted_at`, `cancelled_at`, `expired_at` |
| `20260830007` `_draft_payload` | đọc `preview_snapshot->>'saved_at'`, `->>'saved_by_actor_id'`, `->'customer'`, `->>'pricing_preview_token'`, `->>'needs_revalidation'` |
| `20260830007` `_draft_preview_snapshot(jsonb, text, boolean, uuid, timestamptz)` | dựng `preview_snapshot`; chỉ `save`/`update` gọi |
| `20260830007` `save_sales_order_draft` | insert `…, note, preview_snapshot, version`; biến `v_saved_at` chỉ dùng cho `_draft_preview_snapshot` |
| `20260830007` `update_sales_order_draft` | `preview_snapshot = sales._draft_preview_snapshot(…)`, `updated_at = v_saved_at` |
| `20260830007` `cancel_sales_order_draft` | `cancelled_at = now(),` |
| `20260830007` `get_sales_order_draft_for_restore` | `'saved_at'`, `'saved_by_actor_id'` đọc `preview_snapshot` |
| `20260830007` dòng 5 | `-- Touches: … _draft_preview_snapshot` |
| `20260830007` cuối file | `revoke all on function sales._draft_preview_snapshot(jsonb, text, boolean, uuid, timestamptz) …` |
| `20260830008` `finalize_sales_order` | `set status = 'converted', converted_at = now(), version = version + 1, updated_at = now()` |
| Nơi khác | Không migration nào khác tham chiếu các cột/helper này; `sales_shift_id` không RPC nào dùng |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` nháp |
| Modify `supabase/migrations/20260830007_sales_draft_rpcs.sql` | helper + 4 RPC + header + revoke |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | câu chuyển nháp `converted` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart` | SQL contract test |
| Modify `supabase/migrations/REGISTRY.yaml` | qua `seed_registry --write` |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng + RPC nháp (`005`, `007`)

**Interfaces:**
- Produces: cột `customer_snapshot jsonb`, `pricing_preview_token text`, `needs_revalidation boolean not null default false`, `updated_by_user_id uuid not null`; hàm `sales._draft_customer_snapshot(p_customer jsonb) returns jsonb`.

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 3 `sales.sales_order_drafts`
/// (docs/superpowers/specs/sales-schema-refactor/03-sales-order-drafts.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final draftSql = _readMigration('20260830007_sales_draft_rpcs.sql');

  test('drafts table uses explicit columns instead of preview_snapshot', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_drafts (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in [
      'updated_by_user_id uuid not null,',
      'customer_snapshot jsonb,',
      'pricing_preview_token text,',
      'needs_revalidation boolean not null default false,',
    ]) {
      expect(table, contains(column), reason: column);
    }
    expect(
      table,
      contains("check (status in ('active', 'converted', 'cancelled', 'expired'))"),
    );
    for (final removed in [
      'sales_shift_id',
      'preview_snapshot',
      'expires_at',
      'expired_at',
      'converted_at',
      'cancelled_at',
    ]) {
      expect(table, isNot(contains(removed)), reason: removed);
    }
  });

  test('draft RPC file no longer references preview_snapshot', () {
    expect(draftSql, isNot(contains('preview_snapshot')));
    expect(draftSql, isNot(contains('_draft_preview_snapshot')));
    expect(draftSql, isNot(contains('cancelled_at')));
    expect(
      draftSql,
      contains(
        'revoke all on function sales._draft_customer_snapshot(jsonb) from public, anon, authenticated;',
      ),
    );
  });

  test('payload maps legacy keys from explicit columns', () {
    final payload = _lastFunctionBlock(draftSql, 'sales._draft_payload');
    expect(payload, contains("'saved_at', v_draft.updated_at,"));
    expect(
      payload,
      contains("'saved_by_actor_id', v_draft.updated_by_user_id::text,"),
    );
    expect(payload, contains("'customer', v_draft.customer_snapshot,"));
    expect(
      payload,
      contains("'pricing_preview_token', v_draft.pricing_preview_token,"),
    );
    expect(
      payload,
      contains("'needs_revalidation', v_draft.needs_revalidation,"),
    );

    final restore = _lastFunctionBlock(
      draftSql,
      'sales.get_sales_order_draft_for_restore',
    );
    expect(restore, contains("'saved_at', v_draft.updated_at,"));
    expect(
      restore,
      contains("'saved_by_actor_id', v_draft.updated_by_user_id::text"),
    );
  });

  test('mutations write updated_by_user_id and customer_snapshot', () {
    final save = _lastFunctionBlock(draftSql, 'sales.save_sales_order_draft');
    expect(save, contains('sales._draft_customer_snapshot(p_customer)'));
    expect(save, contains('created_by_user_id, updated_by_user_id,'));
    expect(save, isNot(contains('v_saved_at')));

    final update = _lastFunctionBlock(draftSql, 'sales.update_sales_order_draft');
    expect(
      update,
      contains('customer_snapshot = sales._draft_customer_snapshot(p_customer),'),
    );
    expect(update, contains('updated_by_user_id = p_actor_id,'));

    final cancel = _lastFunctionBlock(draftSql, 'sales.cancel_sales_order_draft');
    expect(cancel, contains('updated_by_user_id = p_actor_id,'));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart`
Expected: FAIL 4 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối `create table if not exists sales.sales_order_drafts (…);` bằng:

```sql
create table if not exists sales.sales_order_drafts (
  id uuid primary key,
  tenant_id uuid not null,
  store_id uuid not null,
  created_by_user_id uuid not null,
  updated_by_user_id uuid not null,                                            -- last actor who saved/cancelled/converted
  customer_partner_id uuid,
  customer_snapshot jsonb,                                                     -- display snapshot for restore; not authoritative
  status text not null,
  currency_code char(3) not null,
  note text,
  pricing_preview_token text,
  needs_revalidation boolean not null default false,
  version bigint not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sales_order_drafts_status_check
    check (status in ('active', 'converted', 'cancelled', 'expired')),
  constraint sales_order_drafts_tenant_id_unique unique (tenant_id, id)         -- enables composite FK (FC-01)
);
```

- [ ] **Step 4: Sửa header `20260830007` dòng 5** — trong `-- Touches:` đổi `_draft_preview_snapshot` thành `_draft_customer_snapshot`.

- [ ] **Step 5: Sửa `_draft_payload`** — thay 5 dòng đọc `preview_snapshot`:

```sql
-- trước
    'saved_at', coalesce((v_draft.preview_snapshot->>'saved_at')::timestamptz, v_draft.updated_at),
    'saved_by_actor_id', coalesce(v_draft.preview_snapshot->>'saved_by_actor_id', v_draft.created_by_user_id::text),
    'customer', v_draft.preview_snapshot->'customer',
    'order_note', v_draft.note,
    'pricing_preview_token', v_draft.preview_snapshot->>'pricing_preview_token',
    'needs_revalidation', coalesce((v_draft.preview_snapshot->>'needs_revalidation')::boolean, false),
-- sau
    'saved_at', v_draft.updated_at,
    'saved_by_actor_id', v_draft.updated_by_user_id::text,
    'customer', v_draft.customer_snapshot,
    'order_note', v_draft.note,
    'pricing_preview_token', v_draft.pricing_preview_token,
    'needs_revalidation', v_draft.needs_revalidation,
```

- [ ] **Step 6: Thay `_draft_preview_snapshot` bằng `_draft_customer_snapshot`** — thay cả hàm `create or replace function sales._draft_preview_snapshot(…) … $$;` bằng:

```sql
create or replace function sales._draft_customer_snapshot(p_customer jsonb)
returns jsonb
language plpgsql
immutable
security definer
set search_path = sales, iam, public, pg_temp
as $$
begin
  if p_customer is null or p_customer = 'null'::jsonb then
    return null;
  end if;
  return jsonb_strip_nulls(jsonb_build_object(
    'customer_id', p_customer->>'customer_id',
    'display_name', p_customer->>'display_name',
    'phone_number', nullif(trim(coalesce(p_customer->>'phone_number', '')), ''),
    'tax_code', nullif(trim(coalesce(p_customer->>'tax_code', '')), '')
  ));
end;
$$;
```

- [ ] **Step 7: Sửa `save_sales_order_draft`**

1. `declare`: xoá dòng `  v_saved_at timestamptz := now();`.
2. Thay câu insert:

```sql
-- trước
  insert into sales.sales_order_drafts(
    id, tenant_id, store_id, created_by_user_id, customer_partner_id, status, currency_code,
    note, preview_snapshot, version
  ) values (
    v_draft_id, p_tenant_id, p_store_id, p_actor_id, v_customer_id, 'active', upper(trim(p_currency_code)),
    nullif(trim(coalesce(p_order_note, '')), ''),
    sales._draft_preview_snapshot(p_customer, p_pricing_preview_token, p_needs_revalidation, p_actor_id, v_saved_at),
    1
  );
-- sau
  insert into sales.sales_order_drafts(
    id, tenant_id, store_id, created_by_user_id, updated_by_user_id,
    customer_partner_id, customer_snapshot, status, currency_code,
    note, pricing_preview_token, needs_revalidation, version
  ) values (
    v_draft_id, p_tenant_id, p_store_id, p_actor_id, p_actor_id,
    v_customer_id, sales._draft_customer_snapshot(p_customer), 'active', upper(trim(p_currency_code)),
    nullif(trim(coalesce(p_order_note, '')), ''),
    nullif(trim(coalesce(p_pricing_preview_token, '')), ''),
    coalesce(p_needs_revalidation, false),
    1
  );
```

- [ ] **Step 8: Sửa `update_sales_order_draft`** — thay câu update:

```sql
-- trước
  update sales.sales_order_drafts
  set customer_partner_id = v_customer_id,
      currency_code = upper(trim(p_currency_code)),
      note = nullif(trim(coalesce(p_order_note, '')), ''),
      preview_snapshot = sales._draft_preview_snapshot(
        p_customer, p_pricing_preview_token, p_needs_revalidation, p_actor_id, v_saved_at
      ),
      version = v_draft.version + 1,
      updated_at = v_saved_at
  where tenant_id = p_tenant_id and id = p_draft_id;
-- sau
  update sales.sales_order_drafts
  set customer_partner_id = v_customer_id,
      customer_snapshot = sales._draft_customer_snapshot(p_customer),
      currency_code = upper(trim(p_currency_code)),
      note = nullif(trim(coalesce(p_order_note, '')), ''),
      pricing_preview_token = nullif(trim(coalesce(p_pricing_preview_token, '')), ''),
      needs_revalidation = coalesce(p_needs_revalidation, false),
      updated_by_user_id = p_actor_id,
      version = v_draft.version + 1,
      updated_at = v_saved_at
  where tenant_id = p_tenant_id and id = p_draft_id;
```

- [ ] **Step 9: Sửa `cancel_sales_order_draft`**

```sql
-- trước
  set status = 'cancelled',
      version = v_draft.version + 1,
      cancelled_at = now(),
      updated_at = now()
-- sau
  set status = 'cancelled',
      version = v_draft.version + 1,
      updated_by_user_id = p_actor_id,
      updated_at = now()
```

- [ ] **Step 10: Sửa `get_sales_order_draft_for_restore`**

```sql
-- trước
    'saved_at', coalesce((v_draft.preview_snapshot->>'saved_at')::timestamptz, v_draft.updated_at),
    'saved_by_actor_id', coalesce(v_draft.preview_snapshot->>'saved_by_actor_id', v_draft.created_by_user_id::text)
-- sau
    'saved_at', v_draft.updated_at,
    'saved_by_actor_id', v_draft.updated_by_user_id::text
```

- [ ] **Step 11: Sửa revoke cuối file**

```sql
-- trước
revoke all on function sales._draft_preview_snapshot(jsonb, text, boolean, uuid, timestamptz) from public, anon, authenticated;
-- sau
revoke all on function sales._draft_customer_snapshot(jsonb) from public, anon, authenticated;
```

- [ ] **Step 12: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 13: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): replace draft preview_snapshot with explicit columns`

---

### Task 2: `finalize_sales_order` bỏ `converted_at`

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()` của file test Task 1:

```dart
  test('finalize converts draft without converted_at', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('converted_at')));
    expect(
      finalize,
      contains(
        "      set status = 'converted',\n"
        '          version = version + 1,\n'
        '          updated_by_user_id = p_actor_id,\n'
        '          updated_at = now()\n',
      ),
    );
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart`
Expected: FAIL test mới.

- [ ] **Step 3: Sửa `20260830008`**

```sql
-- trước
      update sales.sales_order_drafts
      set status = 'converted',
          converted_at = now(),
          version = version + 1,
          updated_at = now()
-- sau
      update sales.sales_order_drafts
      set status = 'converted',
          version = version + 1,
          updated_by_user_id = p_actor_id,
          updated_at = now()
```

- [ ] **Step 4: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 5: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): record converting actor instead of converted_at on drafts`

---

### Task 3: Kiểm chứng + tiến độ

- [ ] **Step 1: Grep toàn bộ migration**

Run: `grep -nE "preview_snapshot|_draft_preview_snapshot|sales_order_drafts.*(converted_at|cancelled_at|expires_at|expired_at|sales_shift_id)|converted_at = now" supabase/migrations/*.sql`
Expected: không còn kết quả.

- [ ] **Step 2: Registry + policy**

Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: OK; `REGISTRY.yaml` đổi `_draft_preview_snapshot` → `_draft_customer_snapshot`.

- [ ] **Step 3: Chạy toàn bộ test Sales infrastructure**

Run: `cd modules/sales/infrastructure && dart test`
Expected: chỉ còn các test baseline fail (README spec); không có fail mới.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 3 README: `✅ Đã chốt · bỏ 5 cột, tách preview_snapshot · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset`:
1. Tạo đơn có khách + ghi chú → lưu nháp. Mở danh sách nháp: thấy tên khách, thời điểm lưu, người lưu.
2. Mở lại nháp: khách, ghi chú, dòng hàng đúng; sửa rồi lưu → thời điểm lưu cập nhật.
3. Huỷ một nháp → biến khỏi danh sách.
4. Mở nháp → thanh toán → nháp biến khỏi danh sách.
5. SQL Editor: `select status, customer_snapshot, pricing_preview_token, needs_revalidation, created_by_user_id, updated_by_user_id, updated_at from sales.sales_order_drafts;`
