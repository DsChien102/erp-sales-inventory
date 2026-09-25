# Sales refactor — Bảng 4 `sales.sales_order_draft_lines` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tách dữ liệu người dùng nhập (cột phẳng) khỏi `pricing_preview` (hiển thị + kết quả tính giá), thêm cột `manual_discount_basis_points`, bỏ `updated_at` — **sửa trực tiếp migration gốc**, giữ nguyên JSON `lines[]` trả app.

**Architecture:** Bảng ở `20260830005`. `_write_draft_lines` (ghi) và `_draft_payload` (đọc) ở `20260830007` (file owner). Không file nào khác đụng bảng này.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [04-sales-order-draft-lines.md](../specs/sales-schema-refactor/04-sales-order-draft-lines.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 3 (cùng sửa `_draft_payload`) — tìm theo nội dung, không theo số dòng.
- Giữ tên cột `manual_unit_price_input_minor`, `manual_discount_amount_input_minor`.
- Key JSON trong `lines[]` không đổi: `line_id`, `product_id`, `product_sku`, `product_name`, `product_unit_id`, `unit_code`, `unit_name`, `quantity_micros`, `applied_unit_price_minor`, `line_total_minor`, `list_unit_price_minor`, `manual_unit_price_minor`, `manual_discount_minor`, `manual_discount_basis_points`, `pricing_source_code`, `pricing_warning_codes`, `pricing_blocking_codes`, `note`, `needs_revalidation`.
- Không sửa `sales_order_draft_sql_contract_test.dart` (baseline fail).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "_write_draft_lines" --direction upstream --repo .` và `… "_draft_payload" …` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_order_draft_lines` | 13 cột; `pricing_preview jsonb` (nullable); `updated_at` |
| `20260830007` `_draft_payload` | `select coalesce(jsonb_agg(pricing_preview order by line_sequence), '[]'::jsonb), coalesce(sum((pricing_preview->>'line_total_minor')::bigint), 0) … from sales.sales_order_draft_lines where …` |
| `20260830007` `_write_draft_lines` | kiểm tra dòng, dựng `v_obj` 19 key, `insert` 11 cột |
| Nơi khác | Không migration nào khác; test chỉ có `sales_rebuild_schema_sql_contract_test.dart` (tên bảng — vẫn pass) và baseline |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` dòng nháp |
| Modify `supabase/migrations/20260830007_sales_draft_rpcs.sql` | `_draft_payload`, `_write_draft_lines` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_04_order_draft_lines_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Tách cột nhập và `pricing_preview`

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 4 `sales.sales_order_draft_lines`
/// (docs/superpowers/specs/sales-schema-refactor/04-sales-order-draft-lines.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final draftSql = _readMigration('20260830007_sales_draft_rpcs.sql');

  test('draft lines table stores inputs as columns', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_order_draft_lines (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(table, contains('manual_discount_basis_points integer,'));
    expect(table, contains('pricing_preview jsonb not null,'));
    expect(table, contains('line_note text,'));
    expect(table, isNot(contains('updated_at')));
  });

  test('write lines keeps only display and pricing keys in pricing_preview', () {
    final body = _lastFunctionBlock(draftSql, 'sales._write_draft_lines');
    final objStart = body.indexOf('v_obj := jsonb_strip_nulls(jsonb_build_object(');
    final obj = body.substring(objStart, body.indexOf('));', objStart));
    for (final key in [
      'product_sku',
      'product_name',
      'unit_code',
      'unit_name',
      'applied_unit_price_minor',
      'line_total_minor',
      'list_unit_price_minor',
      'pricing_source_code',
      'pricing_warning_codes',
      'pricing_blocking_codes',
      'needs_revalidation',
    ]) {
      expect(obj, contains("'$key'"), reason: key);
    }
    for (final key in [
      'line_id',
      'product_id',
      'product_unit_id',
      'quantity_micros',
      'manual_unit_price_minor',
      'manual_discount_minor',
      'manual_discount_basis_points',
      "'note'",
    ]) {
      expect(obj, isNot(contains(key.startsWith("'") ? key : "'$key'")), reason: key);
    }
    expect(body, contains('manual_discount_basis_points, line_note, pricing_preview'));
  });

  test('payload rebuilds legacy line keys from columns plus pricing_preview', () {
    final body = _lastFunctionBlock(draftSql, 'sales._draft_payload');
    for (final fragment in [
      "'line_id', l.id::text,",
      "'product_id', l.product_id::text,",
      "'product_unit_id', l.product_unit_id::text,",
      "'quantity_micros', l.quantity_micros,",
      "'manual_unit_price_minor', l.manual_unit_price_input_minor,",
      "'manual_discount_minor', l.manual_discount_amount_input_minor,",
      "'manual_discount_basis_points', l.manual_discount_basis_points,",
      "'note', l.line_note",
      ')) || l.pricing_preview',
      'order by l.line_sequence',
    ]) {
      expect(body, contains(fragment), reason: fragment);
    }
    expect(body, isNot(contains('jsonb_agg(pricing_preview order by')));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_04_order_draft_lines_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối `create table if not exists sales.sales_order_draft_lines (…);` bằng:

```sql
create table if not exists sales.sales_order_draft_lines (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_draft_id uuid not null,
  line_sequence integer not null,
  product_id uuid not null,
  product_unit_id uuid not null,
  quantity_micros bigint not null,
  manual_unit_price_input_minor bigint,
  manual_discount_amount_input_minor bigint,
  manual_discount_basis_points integer,
  line_note text,
  pricing_preview jsonb not null,                                              -- display + pricing result only; user inputs live in columns
  created_at timestamptz not null default now(),
  constraint sales_order_draft_lines_seq_unique
    unique (sales_order_draft_id, line_sequence),                              -- FC-05
  constraint sales_order_draft_lines_qty_positive check (quantity_micros > 0),  -- FC-13
  constraint sales_order_draft_lines_parent_fk
    foreign key (tenant_id, sales_order_draft_id)
    references sales.sales_order_drafts (tenant_id, id) on delete cascade       -- FC-01
);
```

- [ ] **Step 4: Sửa `_draft_payload` (`20260830007`)** — thay câu select dòng hàng:

```sql
-- trước
  select coalesce(jsonb_agg(pricing_preview order by line_sequence), '[]'::jsonb),
         coalesce(sum((pricing_preview->>'line_total_minor')::bigint), 0)
  into v_lines, v_total
  from sales.sales_order_draft_lines
  where tenant_id = p_tenant_id and sales_order_draft_id = p_draft_id;
-- sau
  select coalesce(jsonb_agg(
           jsonb_strip_nulls(jsonb_build_object(
             'line_id', l.id::text,
             'product_id', l.product_id::text,
             'product_unit_id', l.product_unit_id::text,
             'quantity_micros', l.quantity_micros,
             'manual_unit_price_minor', l.manual_unit_price_input_minor,
             'manual_discount_minor', l.manual_discount_amount_input_minor,
             'manual_discount_basis_points', l.manual_discount_basis_points,
             'note', l.line_note
           )) || l.pricing_preview
           order by l.line_sequence
         ), '[]'::jsonb),
         coalesce(sum((l.pricing_preview->>'line_total_minor')::bigint), 0)
  into v_lines, v_total
  from sales.sales_order_draft_lines l
  where l.tenant_id = p_tenant_id and l.sales_order_draft_id = p_draft_id;
```

- [ ] **Step 5: Sửa `_write_draft_lines` (`20260830007`)** — giữ nguyên phần kiểm tra dòng; thay đoạn từ `    v_line_id := gen_random_uuid();` đến hết câu `insert … );` bằng:

```sql
    v_line_id := gen_random_uuid();
    v_obj := jsonb_strip_nulls(jsonb_build_object(
      'product_sku', v_line->>'product_sku',
      'product_name', v_line->>'product_name',
      'unit_code', v_line->>'unit_code',
      'unit_name', v_line->>'unit_name',
      'applied_unit_price_minor', (v_line->>'applied_unit_price_minor')::bigint,
      'line_total_minor', (v_line->>'line_total_minor')::bigint,
      'list_unit_price_minor', nullif(v_line->>'list_unit_price_minor', '')::bigint,
      'pricing_source_code', nullif(trim(coalesce(v_line->>'pricing_source_code', '')), ''),
      'pricing_warning_codes', coalesce(v_line->'pricing_warning_codes', '[]'::jsonb),
      'pricing_blocking_codes', coalesce(v_line->'pricing_blocking_codes', '[]'::jsonb),
      'needs_revalidation', coalesce((v_line->>'needs_revalidation')::boolean, false)
    ));

    insert into sales.sales_order_draft_lines(
      id, tenant_id, sales_order_draft_id, line_sequence, product_id, product_unit_id,
      quantity_micros, manual_unit_price_input_minor, manual_discount_amount_input_minor,
      manual_discount_basis_points, line_note, pricing_preview
    ) values (
      v_line_id, p_tenant_id, p_draft_id, v_seq,
      (v_line->>'product_id')::uuid, (v_line->>'product_unit_id')::uuid,
      (v_line->>'quantity_micros')::bigint,
      nullif(v_line->>'manual_unit_price_minor', '')::bigint,
      nullif(v_line->>'manual_discount_minor', '')::bigint,
      nullif(v_line->>'manual_discount_basis_points', '')::integer,
      nullif(trim(coalesce(v_line->>'note', '')), ''),
      v_obj
    );
```

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_04_order_draft_lines_sql_contract_test.dart test/domain/schema/sales_refactor_03_order_drafts_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Grep + policy + toàn bộ test**
- `grep -n "sales_order_draft_lines" supabase/migrations/*.sql` → chỉ `20260830005` (create + RLS) và `20260830007` (`_draft_payload`, `_write_draft_lines`).
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 8: Tiến độ spec** — dòng bảng 4 README: `✅ Đã chốt · cột = dữ liệu nhập, pricing_preview = hiển thị/giá, bỏ updated_at · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 9: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): store draft line inputs in columns, keep pricing_preview display-only`

Sau `supabase db reset`:
1. Tạo nháp 2 dòng: một dòng sửa giá tay, một dòng giảm giá theo % → lưu.
2. Mở lại nháp: số lượng, giá tay, giảm %, ghi chú dòng, tên/mã sản phẩm, đơn vị, thành tiền, tổng tiền đúng như lúc lưu.
3. Sửa số lượng một dòng → lưu → mở lại đúng.
4. SQL Editor: `select line_sequence, quantity_micros, manual_unit_price_input_minor, manual_discount_amount_input_minor, manual_discount_basis_points, line_note, pricing_preview from sales.sales_order_draft_lines order by created_at desc limit 5;` → `pricing_preview` không còn `product_id`, `quantity_micros`, `note`.
