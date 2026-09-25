# Sales refactor — Bảng 5 `sales.sales_orders` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bỏ 7 cột không dùng/trùng của `sales.sales_orders` (giữ `buyer_tax_snapshot` cho hoá đơn điện tử theme8) và gộp phần alter cũ của bảng vào `create table` — **sửa trực tiếp migration gốc**, không đổi contract RPC.

**Architecture:** Bảng ở `20260830005`. Chỉ 2 hàm tham chiếu cột bị bỏ: `finalize_sales_order` (`20260830008`, câu insert) và `generate_sales_receipt` (`20260830010`, key `customer`). Cả hai chỉ có một định nghĩa.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [05-sales-orders.md](../specs/sales-schema-refactor/05-sales-orders.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 1–4 (plan 1–3 cùng sửa `finalize_sales_order`) — tìm theo nội dung, không theo số dòng.
- Giữ `channel_code`, `lock_status`, `buyer_tax_snapshot`, `tax_amount_minor`, `rounding_amount_minor`, `cancelled_at`.
- Không sửa draft theme8 (`017`, `018` trên `feature/theme8`) — việc đồng bộ ghi ở README "Việc phát sinh", làm lúc merge.
- Không đổi key JSON của hoá đơn (`customer` vẫn là object khách hoặc `null` với khách vãng lai).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "finalize_sales_order" --direction upstream --repo .` và `… "generate_sales_receipt" …` (hàm SQL → `UNKNOWN`; đối chiếu khảo sát).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_orders` | 32 cột, gồm 7 cột bỏ: `sales_shift_id`, `reference_code`, `customer_snapshot`, `pricing_summary_snapshot`, `business_time`, `locked_at`, `locked_by_user_id` |
| `20260830005` khối SCHEMA EVOLUTION | `alter table sales.sales_orders add column if not exists payment_due_date date;` và cặp `drop/add constraint sales_orders_commercial_balance` |
| `20260830008` `finalize_sales_order` | insert có `business_time`, `customer_snapshot`, `pricing_summary_snapshot` (giá trị `now()`, `coalesce(… -> 'customer', '{}')`, `jsonb_build_object('subtotalMinor', …)`) |
| `20260830010` `generate_sales_receipt` | `'customer', coalesce(nullif(v_order.customer_snapshot, '{}'::jsonb), v_order.sales_context_snapshot -> 'customer'),` |
| Nơi khác | Không migration Sales nào khác; không test nào tham chiếu 8 cột (kết quả `reference_code`/`customer_snapshot` ở Partner/Pricing là bảng khác) |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter cũ |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | insert trong `finalize_sales_order` |
| Modify `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` | key `customer` trong `generate_sales_receipt` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_05_orders_sql_contract_test.dart` | SQL contract test |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bỏ 7 cột

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 5 `sales.sales_orders`
/// (docs/superpowers/specs/sales-schema-refactor/05-sales-orders.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = [
    'sales_shift_id',
    'reference_code',
    'customer_snapshot',
    'pricing_summary_snapshot',
    'business_time',
    'locked_at',
    'locked_by_user_id',
  ];

  test('sales_orders drops unused columns and owns commercial balance check', () {
    final start = schemaSql.indexOf('create table if not exists sales.sales_orders (');
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    for (final kept in [
      'channel_code varchar(50) not null,',
      "lock_status text not null default 'unlocked',",
      'sales_context_snapshot jsonb not null,',
      'buyer_tax_snapshot jsonb,',
      'cancelled_at timestamptz,',
      'payment_due_date date,',
      'constraint sales_orders_commercial_balance',
    ]) {
      expect(table, contains(kept), reason: kept);
    }
  });

  test('schema evolution block no longer alters sales_orders', () {
    expect(schemaSql, isNot(contains('alter table sales.sales_orders')));
  });

  test('finalize insert omits removed columns', () {
    final checkoutSql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(checkoutSql, 'sales.finalize_sales_order');
    final insertStart = finalize.indexOf('insert into sales.sales_orders(');
    final insert = finalize.substring(
      insertStart,
      finalize.indexOf(');', finalize.indexOf(') values (', insertStart)),
    );
    for (final column in removed) {
      expect(insert, isNot(contains(column)), reason: column);
    }
    expect(insert, contains("p_actor_id, p_customer_id, 'pos', v_currency_code,"));
  });

  test('receipt reads customer from sales_context_snapshot', () {
    final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(receipt, contains("'customer', v_order.sales_context_snapshot -> 'customer',"));
    expect(receipt, isNot(contains('customer_snapshot')));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_05_orders_sql_contract_test.dart`
Expected: FAIL 4 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối `create table if not exists sales.sales_orders (…);` bằng:

```sql
create table if not exists sales.sales_orders (
  id uuid primary key,
  tenant_id uuid not null,
  source_draft_id uuid,
  order_code varchar(50) not null,
  store_id uuid not null,
  seller_user_id uuid not null,
  customer_partner_id uuid,
  channel_code varchar(50) not null,
  currency_code char(3) not null,
  lifecycle_status text not null,
  lock_status text not null default 'unlocked',
  version bigint not null default 1,
  internal_note text,
  subtotal_amount_minor bigint not null,
  discount_amount_minor bigint not null,
  tax_amount_minor bigint not null,
  rounding_amount_minor bigint not null,                                       -- signed
  payable_amount_minor bigint not null,
  sales_context_snapshot jsonb not null,
  buyer_tax_snapshot jsonb,                                                    -- e-invoice buyer identity (TH-08); written by theme8 finalize
  completed_at timestamptz not null default now(),
  cancelled_at timestamptz,
  payment_due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sales_orders_code_unique unique (tenant_id, order_code),           -- FC-02
  constraint sales_orders_source_draft_unique unique (tenant_id, source_draft_id), -- FC-03 (nulls distinct)
  constraint sales_orders_lifecycle_check
    check (lifecycle_status in ('completed', 'cancelled')),
  constraint sales_orders_lock_check check (lock_status in ('unlocked', 'locked')),
  constraint sales_orders_commercial_balance
    check (payable_amount_minor
      = subtotal_amount_minor
        - discount_amount_minor
        + tax_amount_minor
        + rounding_amount_minor),
  constraint sales_orders_source_draft_fk
    foreign key (tenant_id, source_draft_id)
    references sales.sales_order_drafts (tenant_id, id),
  constraint sales_orders_tenant_id_unique unique (tenant_id, id)               -- enables composite FK
);
```

- [ ] **Step 4: Xoá alter cũ trong khối SCHEMA EVOLUTION (`20260830005`)** — xoá 2 đoạn sau (kèm dòng trống theo sau mỗi đoạn); giữ nguyên comment `-- Sales review schema (folded from drafts …)` vì các câu bên dưới nó còn dùng cho bảng khác:

```sql
alter table sales.sales_orders
  add column if not exists payment_due_date date;
```

```sql
alter table sales.sales_orders
  drop constraint if exists sales_orders_commercial_balance;
alter table sales.sales_orders
  add constraint sales_orders_commercial_balance
  check (payable_amount_minor
    = subtotal_amount_minor
      - discount_amount_minor
      + tax_amount_minor
      + rounding_amount_minor);
```

- [ ] **Step 5: Sửa insert trong `finalize_sales_order` (`20260830008`)**

```sql
-- trước
    insert into sales.sales_orders(
      id, tenant_id, source_draft_id, order_code, store_id,
      seller_user_id, customer_partner_id, channel_code, business_time, currency_code,
      lifecycle_status, lock_status, version, internal_note,
      subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor,
      payable_amount_minor, payment_due_date, sales_context_snapshot, customer_snapshot, pricing_summary_snapshot,
      completed_at
    ) values (
      v_order_id, p_tenant_id, p_source_draft_id, v_order_code, p_store_id,
      p_actor_id, p_customer_id, 'pos', now(), v_currency_code,
      'completed', 'unlocked', 1, nullif(trim(coalesce(p_order_note, '')), ''),
      v_subtotal_minor, v_order_discount_minor, 0, 0, v_grand_total_minor, p_payment_due_date,
      v_normalized_commercial_snapshot,
      coalesce(v_normalized_commercial_snapshot -> 'customer', '{}'::jsonb),
      jsonb_build_object(
        'subtotalMinor', v_subtotal_minor,
        'discountMinor', v_order_discount_minor,
        'payableMinor', v_grand_total_minor
      ),
      now()
    );
-- sau
    insert into sales.sales_orders(
      id, tenant_id, source_draft_id, order_code, store_id,
      seller_user_id, customer_partner_id, channel_code, currency_code,
      lifecycle_status, lock_status, version, internal_note,
      subtotal_amount_minor, discount_amount_minor, tax_amount_minor, rounding_amount_minor,
      payable_amount_minor, payment_due_date, sales_context_snapshot,
      completed_at
    ) values (
      v_order_id, p_tenant_id, p_source_draft_id, v_order_code, p_store_id,
      p_actor_id, p_customer_id, 'pos', v_currency_code,
      'completed', 'unlocked', 1, nullif(trim(coalesce(p_order_note, '')), ''),
      v_subtotal_minor, v_order_discount_minor, 0, 0, v_grand_total_minor, p_payment_due_date,
      v_normalized_commercial_snapshot,
      now()
    );
```

- [ ] **Step 6: Sửa `generate_sales_receipt` (`20260830010`)**

```sql
-- trước
    'customer', coalesce(
      nullif(v_order.customer_snapshot, '{}'::jsonb),
      v_order.sales_context_snapshot -> 'customer'
    ),
-- sau
    'customer', v_order.sales_context_snapshot -> 'customer',
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_05_orders_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Grep + policy + toàn bộ test**
- `grep -nE "\b(sales_shift_id|business_time|pricing_summary_snapshot|locked_by_user_id)\b|\blocked_at\b|v_order\.customer_snapshot|\bo\.reference_code\b" supabase/migrations/2026083*.sql supabase/migrations/20260904001*.sql` → không còn kết quả.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.
- `cd modules/sales/infrastructure && dart test` → chỉ còn baseline fail.

- [ ] **Step 9: Tiến độ spec** — dòng bảng 5 README: `✅ Đã chốt · bỏ 7 cột (giữ buyer_tax_snapshot), gộp alter cũ · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 10: Tóm tắt + đề xuất commit, dừng — user reset + smoke test**

Đề xuất commit: `refactor(sales): drop unused and duplicated columns from sales_orders`

Sau `supabase db reset`:
1. Thanh toán 1 đơn có khách, 1 đơn khách vãng lai.
2. Danh sách + tìm kiếm đơn (lọc theo ngày, trạng thái khoá) → hiển thị đúng.
3. Chi tiết đơn → cửa hàng, người bán, khách, ghi chú, dòng hàng, tổng tiền đúng.
4. Tạo hoá đơn cho cả 2 đơn → đơn có khách hiện đúng khách; đơn vãng lai không có khách.
5. Huỷ 1 đơn → trạng thái `cancelled`.
