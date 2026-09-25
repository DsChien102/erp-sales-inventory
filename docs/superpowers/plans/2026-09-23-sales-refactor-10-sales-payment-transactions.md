# Sales refactor — Bảng 10 `sales.sales_payment_transactions` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xoá `void_sales_payment` (quyết định 2026-09-09) cùng giá trị `reversal`/`voided`; bỏ 8 cột của `sales.sales_payment_transactions` (`transaction_code`, `idempotency_key`, `confirmed_by_user_id`, `confirmed_at`, `voided_at`, `metadata`, `updated_at` + 2 unique); gộp alter cũ vào `create table` — **sửa trực tiếp migration gốc**, không đổi contract RPC còn lại.

**Architecture:** Bảng ở `20260830005`. Insert ở 4 định nghĩa cuối: `finalize_sales_order` (`008`), `record_sales_payment` + `record_sales_refund` (`20260904001`), `settle_return_exchange_difference` (`013`). Hàm void chỉ có ở `009`. Bản cũ `record_sales_payment`/`record_sales_refund` trong `009` để nguyên (bị ghi đè, thân plpgsql không kiểm tra lúc tạo).

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`.

**Spec:** [10-sales-payment-transactions.md](../specs/sales-schema-refactor/10-sales-payment-transactions.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement**. Thứ tự: sau plan 9. **Bắt buộc sau plan 8** (plan 8 bỏ `max(confirmed_at)` khỏi `_recompute_sales_settlement`). Plan 1 đã đổi lời gọi helper trong các hàm này — tìm theo nội dung.
- Giữ `payment_method_snapshot`, `external_reference`, `status` (`pending | confirmed | failed`), `source_type`, `source_id`, `related_transaction_id`.
- Không đổi enum Dart; không sửa `modules/sales/application/test/contract_foundation_test.dart`.
- Không sửa draft theme8 (`017`).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `finalize_sales_order`, `record_sales_payment`, `record_sales_refund`, `settle_return_exchange_difference`, `void_sales_payment` (hàm SQL → `UNKNOWN`; đã grep: Dart không gọi `void_sales_payment`).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` `create table if not exists sales.sales_payment_transactions` | 27 cột; `sales_payment_tx_code_unique`, `sales_payment_tx_idempotency_unique`, `sales_payment_tx_type_check` (có `reversal`), `sales_payment_tx_status_check` (có `voided`), `sales_payment_tx_related_fk` (chỉ `id`) |
| `20260830005` khối SCHEMA EVOLUTION | `create unique index … sales_payment_tx_tenant_settlement_id_uidx`; cặp drop/drop/add `sales_payment_tx_related_same_settlement_fk`; cặp drop/add `sales_payment_tx_type_direction` (có `or transaction_type = 'reversal'`) |
| `20260830008` `finalize_sales_order` | insert có `transaction_code`, `confirmed_by_user_id`, `idempotency_key` (`… || ':pay:' || v_payment_ordinal`), `confirmed_at` |
| `20260904001` `record_sales_payment` | insert có `transaction_code`, `confirmed_by_user_id`, `idempotency_key`, `confirmed_at` |
| `20260904001` `record_sales_refund` | insert tương tự; 2 đoạn kiểm tra `reversal` (`-- Legacy reversals …` và `and not exists (… 'reversal' …)`) |
| `20260830013` `settle_return_exchange_difference` | insert từng cột một dòng; `transaction_code` = `case … 'RXC-' / 'RXR-' end || …` |
| `20260830009` | header `-- Touches:` có `sales.void_sales_payment`; khối hàm từ `-- ----` + `-- void_sales_payment — append-only reversal …` tới `$$;`; `revoke`/`grant` void |
| Test | `sales_refactor_01_idempotency_records_sql_contract_test.dart` (plan 1) liệt kê `sales.void_sales_payment`, đếm 16/22; `sales_rpc_surface_parity_test.dart:576-577` skip void |

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table` + xoá alter/index cũ |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | insert giao dịch |
| Modify `supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` | 2 insert + kiểm tra reversal |
| Modify `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql` | insert giao dịch |
| Modify `supabase/migrations/20260830009_sales_settlement_rpcs.sql` | xoá void |
| Modify `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart` | bỏ void, 15/21 |
| Modify `modules/sales/infrastructure/test/domain/schema/sales_rpc_surface_parity_test.dart:576-577` | bỏ skip void |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart` | SQL contract test |
| Modify `supabase/migrations/REGISTRY.yaml` | qua `seed_registry --write` |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Bảng (`005`)

- [ ] **Step 1: Viết test (fail)**

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 10 `sales.sales_payment_transactions`
/// (docs/superpowers/specs/sales-schema-refactor/10-sales-payment-transactions.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  const removed = [
    'transaction_code',
    'idempotency_key',
    'confirmed_by_user_id',
    'confirmed_at',
    'voided_at',
    'metadata',
    'updated_at',
  ];

  test('payment transactions table drops dead columns and void values', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.sales_payment_transactions (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    for (final column in removed) {
      expect(table, isNot(contains(column)), reason: column);
    }
    expect(table, isNot(contains("'reversal'")));
    expect(table, isNot(contains("'voided'")));
    expect(table, contains("check (status in ('pending', 'confirmed', 'failed'))"));
    expect(table, contains('constraint sales_payment_tx_type_direction'));
    expect(table, contains('constraint sales_payment_tx_tenant_settlement_id_unique'));
    expect(table, contains('constraint sales_payment_tx_related_same_settlement_fk'));
    expect(table, isNot(contains('sales_payment_tx_related_fk\n')));
    expect(table, contains('payment_method_snapshot jsonb,'));
    expect(table, contains('external_reference varchar(150),'));
  });

  test('schema evolution block no longer touches payment transactions', () {
    expect(schemaSql, isNot(contains('alter table sales.sales_payment_transactions')));
    expect(schemaSql, isNot(contains('sales_payment_tx_tenant_settlement_id_uidx')));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart`
Expected: FAIL 2 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay cả khối bằng:

```sql
create table if not exists sales.sales_payment_transactions (
  id uuid primary key,
  tenant_id uuid not null,
  sales_order_settlement_id uuid not null,
  transaction_type text not null,
  direction text not null,
  amount_minor bigint not null,
  currency_code char(3) not null,
  payment_method_code varchar(50) not null,
  payment_method_snapshot jsonb,
  status text not null,
  source_context text not null,
  source_type varchar(50),
  source_id uuid,
  related_transaction_id uuid,
  initiated_by_user_id uuid not null,
  reason_code varchar(50),
  reason text,
  external_reference varchar(150),
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint sales_payment_tx_amount_positive check (amount_minor > 0),          -- FC-13
  constraint sales_payment_tx_type_check
    check (transaction_type in ('collection', 'refund')),
  constraint sales_payment_tx_direction_check check (direction in ('inflow', 'outflow')),
  constraint sales_payment_tx_type_direction
    check ((transaction_type = 'collection' and direction = 'inflow')
      or (transaction_type = 'refund' and direction = 'outflow')),
  constraint sales_payment_tx_status_check
    check (status in ('pending', 'confirmed', 'failed')),
  constraint sales_payment_tx_source_context_check
    check (source_context in ('checkout', 'additional_collection',
      'receivable_collection', 'return_exchange', 'cancellation', 'manual_correction')),
  constraint sales_payment_tx_parent_fk
    foreign key (tenant_id, sales_order_settlement_id)
    references sales.sales_order_settlements (tenant_id, id) on delete cascade,  -- FC-01
  constraint sales_payment_tx_tenant_settlement_id_unique
    unique (tenant_id, sales_order_settlement_id, id),
  constraint sales_payment_tx_related_same_settlement_fk
    foreign key (tenant_id, sales_order_settlement_id, related_transaction_id)
    references sales.sales_payment_transactions (tenant_id, sales_order_settlement_id, id)
);
```

- [ ] **Step 4: Xoá khối cũ trong SCHEMA EVOLUTION (`20260830005`)** — xoá 3 đoạn (kèm dòng trống theo sau mỗi đoạn):

```sql
create unique index if not exists sales_payment_tx_tenant_settlement_id_uidx
  on sales.sales_payment_transactions (tenant_id, sales_order_settlement_id, id);
```

```sql
alter table sales.sales_payment_transactions
  drop constraint if exists sales_payment_tx_related_fk;
alter table sales.sales_payment_transactions
  drop constraint if exists sales_payment_tx_related_same_settlement_fk;
alter table sales.sales_payment_transactions
  add constraint sales_payment_tx_related_same_settlement_fk
  foreign key (tenant_id, sales_order_settlement_id, related_transaction_id)
  references sales.sales_payment_transactions (tenant_id, sales_order_settlement_id, id);
```

```sql
alter table sales.sales_payment_transactions
  drop constraint if exists sales_payment_tx_type_direction;
alter table sales.sales_payment_transactions
  add constraint sales_payment_tx_type_direction
  check (
    (transaction_type = 'collection' and direction = 'inflow')
    or (transaction_type = 'refund' and direction = 'outflow')
    or transaction_type = 'reversal'
  );
```

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): slim payment transactions table and fold legacy alters`

---

### Task 2: 4 câu insert + kiểm tra reversal trong hoàn tiền

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  const inserts = <String, String>{
    'sales.finalize_sales_order': '20260830008_sales_checkout_rpcs.sql',
    'sales.record_sales_payment': '20260904001_sales_normalize_outbox_and_commands.sql',
    'sales.record_sales_refund': '20260904001_sales_normalize_outbox_and_commands.sql',
    'sales.settle_return_exchange_difference':
        '20260830013_sales_return_exchange_settlement_rpcs.sql',
  };
  inserts.forEach((fn, file) {
    test('$fn inserts only kept payment columns', () {
      final body = _lastFunctionBlock(_readMigration(file), fn);
      final start = body.indexOf('insert into sales.sales_payment_transactions');
      final insert = body.substring(start, body.indexOf(') values', start));
      for (final column in removed) {
        expect(insert, isNot(contains(column)), reason: column);
      }
      expect(insert, contains('initiated_by_user_id'));
    });
  });

  test('refund no longer checks legacy reversals', () {
    final refund = _lastFunctionBlock(
      _readMigration('20260904001_sales_normalize_outbox_and_commands.sql'),
      'sales.record_sales_refund',
    );
    expect(refund, isNot(contains("'reversal'")));
    expect(refund, contains("and refund.status = 'confirmed';"));
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart`
Expected: FAIL 5 test mới.

- [ ] **Step 3: `finalize_sales_order` (`20260830008`)**

```sql
-- trước
      insert into sales.sales_payment_transactions(
        id, tenant_id, sales_order_settlement_id, transaction_code, transaction_type,
        direction, amount_minor, currency_code, payment_method_code, status, source_context,
        source_type, source_id, initiated_by_user_id, confirmed_by_user_id, idempotency_key,
        external_reference, occurred_at, confirmed_at
      ) values (
        gen_random_uuid(), p_tenant_id, v_settlement_id,
        'PMT-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16)),
        'collection', 'inflow',
        (v_payment -> 'amount' ->> 'amount_minor')::bigint, v_currency_code,
        trim(v_payment ->> 'method'), 'confirmed', 'checkout',
        'sales_order', v_order_id, p_actor_id, p_actor_id,
        trim(p_idempotency_key) || ':pay:' || v_payment_ordinal::text,
        nullif(trim(coalesce(v_payment ->> 'reference', '')), ''),
        now(), now()
      );
-- sau
      insert into sales.sales_payment_transactions(
        id, tenant_id, sales_order_settlement_id, transaction_type,
        direction, amount_minor, currency_code, payment_method_code, status, source_context,
        source_type, source_id, initiated_by_user_id,
        external_reference, occurred_at
      ) values (
        gen_random_uuid(), p_tenant_id, v_settlement_id,
        'collection', 'inflow',
        (v_payment -> 'amount' ->> 'amount_minor')::bigint, v_currency_code,
        trim(v_payment ->> 'method'), 'confirmed', 'checkout',
        'sales_order', v_order_id, p_actor_id,
        nullif(trim(coalesce(v_payment ->> 'reference', '')), ''),
        now()
      );
```

Vòng lặp `for v_payment, v_payment_ordinal in … with ordinality` đổi thành không dùng ordinal:

```sql
-- trước
    for v_payment, v_payment_ordinal in
      select value, ordinality
      from jsonb_array_elements(coalesce(p_payment_intents, '[]'::jsonb)) with ordinality
    loop
-- sau
    for v_payment in
      select value
      from jsonb_array_elements(coalesce(p_payment_intents, '[]'::jsonb))
    loop
```

và xoá dòng khai báo `  v_payment_ordinal bigint;` trong `declare` của `finalize_sales_order` (ngay sau `  v_payment jsonb;`).

- [ ] **Step 4: `record_sales_payment` (`20260904001`)**

```sql
-- trước
  insert into sales.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_code, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, payment_method_snapshot, status,
    source_context, source_type, source_id, initiated_by_user_id, confirmed_by_user_id,
    idempotency_key, external_reference, occurred_at, confirmed_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'PMT-' || upper(substr(replace(v_tx_id::text, '-', ''), 1, 16)),
    'collection', 'inflow', p_amount_minor, v_currency, trim(p_payment_method_code),
    p_payment_method_snapshot, 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'additional_collection'),
    'sales_order', p_sales_order_id, p_actor_id, p_actor_id,
    trim(p_idempotency_key), nullif(trim(coalesce(p_external_reference, '')), ''),
    now(), now()
  );
-- sau
  insert into sales.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, payment_method_snapshot, status,
    source_context, source_type, source_id, initiated_by_user_id,
    external_reference, occurred_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'collection', 'inflow', p_amount_minor, v_currency, trim(p_payment_method_code),
    p_payment_method_snapshot, 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'additional_collection'),
    'sales_order', p_sales_order_id, p_actor_id,
    nullif(trim(coalesce(p_external_reference, '')), ''),
    now()
  );
```

- [ ] **Step 5: `record_sales_refund` (`20260904001`)**

1. Xoá khối (kèm dòng trống theo sau):

```sql
    -- Legacy reversals remain historical data even though the void API is removed.
    if exists (
      select 1 from sales.sales_payment_transactions reversal
      where reversal.tenant_id = p_tenant_id
        and reversal.sales_order_settlement_id = v_settlement_id
        and reversal.related_transaction_id = v_related.id
        and reversal.transaction_type = 'reversal'
        and reversal.status = 'confirmed'
    ) then
      raise exception using message = jsonb_build_object(
        'code', 'CONTEXT_INVALID',
        'message', 'Related collection has already been reversed.'
      )::text;
    end if;
```

2. Trong câu tính `v_related_refunded`:

```sql
-- trước
      and refund.status = 'confirmed'
      and not exists (
        select 1 from sales.sales_payment_transactions reversal
        where reversal.tenant_id = p_tenant_id
          and reversal.sales_order_settlement_id = v_settlement_id
          and reversal.related_transaction_id = refund.id
          and reversal.transaction_type = 'reversal'
          and reversal.status = 'confirmed'
      );
-- sau
      and refund.status = 'confirmed';
```

3. Insert:

```sql
-- trước
  insert into sales.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_code, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, status, source_context, source_type,
    source_id, related_transaction_id, initiated_by_user_id, confirmed_by_user_id,
    reason_code, reason, idempotency_key, occurred_at, confirmed_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'PMT-' || upper(substr(replace(v_tx_id::text, '-', ''), 1, 16)),
    'refund', 'outflow', p_amount_minor, v_currency, trim(p_payment_method_code), 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'manual_correction'),
    'sales_order', p_sales_order_id, p_related_transaction_id, p_actor_id, p_actor_id,
    trim(p_reason_code), nullif(trim(coalesce(p_reason, '')), ''),
    trim(p_idempotency_key), now(), now()
  );
-- sau
  insert into sales.sales_payment_transactions(
    id, tenant_id, sales_order_settlement_id, transaction_type, direction,
    amount_minor, currency_code, payment_method_code, status, source_context, source_type,
    source_id, related_transaction_id, initiated_by_user_id,
    reason_code, reason, occurred_at
  ) values (
    v_tx_id, p_tenant_id, v_settlement_id,
    'refund', 'outflow', p_amount_minor, v_currency, trim(p_payment_method_code), 'confirmed',
    coalesce(nullif(trim(p_source_context), ''), 'manual_correction'),
    'sales_order', p_sales_order_id, p_related_transaction_id, p_actor_id,
    trim(p_reason_code), nullif(trim(coalesce(p_reason, '')), ''),
    now()
  );
```

- [ ] **Step 6: `settle_return_exchange_difference` (`20260830013`)** — thay cả câu insert bằng:

```sql
  insert into sales.sales_payment_transactions (
    id,
    tenant_id,
    sales_order_settlement_id,
    transaction_type,
    direction,
    amount_minor,
    currency_code,
    payment_method_code,
    status,
    source_context,
    source_type,
    source_id,
    initiated_by_user_id,
    external_reference,
    occurred_at
  ) values (
    v_transaction_id,
    settle_return_exchange_difference.tenant_id,
    v_settlement.id,
    operation,
    case when operation = 'collection' then 'inflow' else 'outflow' end,
    amount_minor,
    upper(btrim(currency_code)),
    btrim(method),
    'confirmed',
    'return_exchange',
    'return_exchange_order',
    v_rx_id,
    settle_return_exchange_difference.actor_id,
    nullif(btrim(coalesce(reference, '')), ''),
    now()
  );
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): stop writing dropped payment transaction columns`

---

### Task 3: Xoá `void_sales_payment`

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  test('void_sales_payment no longer exists in any migration', () {
    final dir = Directory('${_findRepoRoot().path}/supabase/migrations');
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.sql')) continue;
      expect(
        file.readAsStringSync(),
        isNot(contains('sales.void_sales_payment')),
        reason: file.path,
      );
    }
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart`
Expected: FAIL test mới (`20260830009`).

- [ ] **Step 3: Sửa `20260830009_sales_settlement_rpcs.sql`**

1. Header: `-- Touches: sales.record_sales_payment, sales.record_sales_refund, sales.void_sales_payment, _settlement_id_for_order, _settlement_mutation_snapshot` → bỏ `sales.void_sales_payment, `.
2. Xoá nguyên khối từ

```sql
-- ---------------------------------------------------------------------------
-- void_sales_payment — append-only reversal; original row stays intact.
-- ---------------------------------------------------------------------------
create or replace function sales.void_sales_payment(
```

đến hết `$$;` của hàm đó (kèm dòng trống theo sau).

3. Xoá 2 câu:

```sql
revoke all on function sales.void_sales_payment(
  uuid, uuid, uuid, uuid, uuid, text, text, text, text, uuid
) from public, anon;
```

```sql
grant execute on function sales.void_sales_payment(
  uuid, uuid, uuid, uuid, uuid, text, text, text, text, uuid
) to authenticated;
```

- [ ] **Step 4: Sửa test plan 1** `sales_refactor_01_idempotency_records_sql_contract_test.dart`

```dart
// trước
    '20260830009_sales_settlement_rpcs.sql': ['sales.void_sales_payment'],
// sau (xoá dòng này)
```

```dart
// trước
    expect(beginCalls, 16);
    expect(completeCalls, 22);
// sau
    expect(beginCalls, 15);
    expect(completeCalls, 21);
```

- [ ] **Step 5: Sửa `sales_rpc_surface_parity_test.dart`** — xoá 2 dòng:

```dart
      // Removed by draft 025; the timestamped bootstrap remains historical.
      if (fn == 'void_sales_payment') continue;
```

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_10_payment_transactions_sql_contract_test.dart test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart test/domain/schema/sales_rpc_surface_parity_test.dart test/domain/sales_order/sales_settlement_rebuild_sql_contract_test.dart`
Expected: PASS (trừ test baseline trong `sales_settlement_rebuild_sql_contract_test.dart`: *mutations recompute settlement and emit canonical fact + settlement_changed*; file này không nhắc `void_sales_payment`).

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): remove void_sales_payment per 2026-09-09 decision`

---

### Task 4: Kiểm chứng + tiến độ

- [ ] **Step 1: Grep**
- `grep -rn "void_sales_payment" supabase/migrations modules/sales --include='*.sql' --include='*.dart'` → không còn (ngoài Dart enum/mapper nếu có).
- `grep -nE "'PMT-'|'RXC-'|'RXR-'|:pay:" supabase/migrations/2026083*.sql supabase/migrations/20260904001*.sql` → chỉ còn trong bản cũ `record_sales_payment`/`record_sales_refund` của `009`.

- [ ] **Step 2: Registry + policy**

Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: OK; `REGISTRY.yaml` bỏ dòng `void_sales_payment`.

- [ ] **Step 3: Chạy toàn bộ test Sales infrastructure**

Run: `cd modules/sales/infrastructure && dart test`
Expected: chỉ còn baseline fail.

- [ ] **Step 4a: Sửa domain model** `docs/themes/TH-05-sales-orders/harness/01-domain-model.md` dòng 3:

```markdown
<!-- trước -->
> Quyết định 2026-09-09: không hỗ trợ hủy riêng khoản thu/hoàn đã xác nhận. Bỏ API/method tạo void; lịch sử reversal và event cũ được giữ để tra cứu. SQL removal nằm ở draft 025, chưa tự apply.
<!-- sau -->
> Quyết định 2026-09-09: không hỗ trợ hủy riêng khoản thu/hoàn đã xác nhận. Bỏ API/method tạo void. SQL đã xoá `void_sales_payment` và giá trị `reversal`/`voided` (Sales refactor bảng 10, 2026-09-23).
```

- [ ] **Step 4: Tiến độ spec** — dòng bảng 10 README: `✅ Đã chốt · xoá void, bỏ 8 cột · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset`:
1. Thanh toán đơn bằng 2 phương thức (tiền mặt + chuyển khoản có mã tham chiếu) → 2 giao dịch.
2. Thu thêm cho đơn còn nợ; hoàn tiền một phần khoản thu → danh sách giao dịch đúng loại/chiều/số tiền/lý do.
3. Hoàn quá số còn hoàn được → lỗi `REFUND_EXCEEDS_COLLECTED`.
4. Đổi trả có chênh lệch → tất toán → giao dịch `return_exchange` xuất hiện, timeline nối đúng phiếu.
5. Gửi lại cùng lệnh thu thêm (cùng key) → không tạo giao dịch thứ hai.
