# Sales refactor — Bảng 1 `sales.idempotency_records` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rút gọn `sales.idempotency_records` còn 7 cột (PK 3 cột), rút gọn chữ ký 2 helper, bỏ trạng thái `uncertain`, xoá câu update thừa ở checkout — **sửa trực tiếp migration gốc**.

**Architecture:** Bảng ở `20260830005`, helper ở `20260830006` (file owner duy nhất). Sau khi đổi chữ ký helper, sửa mọi chỗ gọi trong **định nghĩa cuối** của 16 hàm (`007`–`010`, `012`–`014`, `20260904001`). Contract RPC mà app gọi không đổi.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test` (SQL contract test đọc file migration).

**Spec:** [01-idempotency-records.md](../specs/sales-schema-refactor/01-idempotency-records.md) · Quy ước: [README §Quy ước implement](../specs/sales-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement** trong README spec (sửa file gốc, không `_drafts/`, không `drop column`).
- Không đổi tên/tham số/JSON trả về của RPC mà app gọi.
- Chỉ sửa **định nghĩa cuối** của mỗi hàm plpgsql (owner trong `supabase/migrations/REGISTRY.yaml`). Không sửa bản cũ của `record_sales_payment`, `record_sales_refund` (`009`), `confirm_sales_order_cancellation` (`011`), `confirm_return_exchange` (`014`).
- Giữ biến `v_correlation` trong các hàm (vẫn dùng cho outbox); chỉ bỏ nó khỏi lời gọi `_begin_sales_idempotency`.
- Không `dart format` cả package (xem memory dart-format-style-churn); chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất câu commit rồi dừng chờ review.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "_begin_sales_idempotency" --direction upstream --repo .` và `… "_complete_sales_idempotency" …`. Hàm SQL → kết quả `UNKNOWN`; đối chiếu bằng bảng khảo sát dưới đây (đã grep).

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830005` dòng 18–36 | `create table if not exists sales.idempotency_records` — 13 cột, PK `id`, unique `(tenant_id, command_scope, idempotency_key)`, CHECK có `'uncertain'` |
| `20260830006` dòng 63–193 | `_begin_sales_idempotency(uuid, text, text, text, uuid)`, `_complete_sales_idempotency(uuid, text, text, text, text, uuid, jsonb)` |
| `20260830006` dòng 269–272 | `revoke all on function` với chữ ký cũ |
| `20260830008` dòng 327–336 | câu update thừa trong `finalize_sales_order` |
| `20260830008` dòng 866 | `when v_record.status = 'uncertain' then 'uncertain'` trong `get_checkout_result` |
| `20260830008` dòng 825 | `v_record sales.idempotency_records%rowtype;` — vẫn hợp lệ, giữ |

Chỗ gọi helper ở **định nghĩa cuối** (số lời gọi begin + complete):

| File | Hàm | begin | complete |
|---|---|---|---|
| `20260830007_sales_draft_rpcs.sql` | `save_sales_order_draft`, `update_sales_order_draft`, `cancel_sales_order_draft` | 1 mỗi hàm | 1 mỗi hàm |
| `20260830008_sales_checkout_rpcs.sql` | `finalize_sales_order` | 1 | 2 |
| `20260830009_sales_settlement_rpcs.sql` | `void_sales_payment` | 1 | 1 |
| `20260830010_sales_inquiry_receipt_rpcs.sql` | `generate_sales_receipt` | 1 | 1 |
| | `record_sales_receipt_activity` | 1 | 2 |
| `20260830012_sales_return_exchange_session_rpcs.sql` | `start_return_exchange`, `update_return_exchange`, `cancel_return_exchange` | 1 mỗi hàm | 2 mỗi hàm |
| `20260830013_sales_return_exchange_settlement_rpcs.sql` | `settle_return_exchange_difference` | 1 | 1 |
| `20260830014_sales_return_exchange_confirmation_rpcs.sql` | `complete_return_exchange` | 1 | 1 |
| `20260904001_sales_normalize_outbox_and_commands.sql` | `record_sales_payment`, `record_sales_refund` | 1 mỗi hàm | 1 mỗi hàm |
| | `confirm_sales_order_cancellation` | 1 | 2 |
| | `confirm_return_exchange` | 1 | 1 |

Tổng: 16 begin + 22 complete.

**Baseline test fail sẵn** (2026-09-22, trước refactor): xem README spec. Không sửa trong plan này.

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260830005_sales_rebuild_schema.sql` | `create table sales.idempotency_records` |
| Modify `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql` | 2 helper + revoke |
| Modify `supabase/migrations/20260830007_…` → `20260830010_…`, `20260830012_…` → `20260830014_…`, `20260904001_…` | Lời gọi helper |
| Modify `supabase/migrations/20260830008_sales_checkout_rpcs.sql` | + xoá update thừa, bỏ nhánh `uncertain` |
| Create `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart` | SQL contract test |
| Modify `modules/sales/infrastructure/test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart:125` | Assertion `uncertain` |
| Modify `docs/superpowers/specs/sales-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Rút gọn bảng và 2 helper

**Files:**
- Modify: `supabase/migrations/20260830005_sales_rebuild_schema.sql:18-36`
- Modify: `supabase/migrations/20260830006_sales_shared_rpc_helpers.sql:63-193,269-272`
- Create: `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`

**Interfaces:**
- Produces: `sales._begin_sales_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_payload_hash text) returns jsonb` (key `decision`, `status`, `result_snapshot`; **không** còn `record_id`); `sales._complete_sales_idempotency(p_tenant_id uuid, p_command_scope text, p_idempotency_key text, p_status text, p_result_snapshot jsonb) returns void`, `p_status ∈ {'succeeded','failed'}`.

- [ ] **Step 1: Viết test (fail)**

Tạo file test với nội dung đầy đủ (Task 2 và 3 bổ sung test vào cùng file):

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — Sales refactor bảng 1 `sales.idempotency_records`
/// (docs/superpowers/specs/sales-schema-refactor/01-idempotency-records.md).
void main() {
  final schemaSql = _readMigration('20260830005_sales_rebuild_schema.sql');
  final helperSql = _readMigration('20260830006_sales_shared_rpc_helpers.sql');

  test('idempotency_records keeps 7 columns with composite primary key', () {
    final start = schemaSql.indexOf(
      'create table if not exists sales.idempotency_records (',
    );
    final table = schemaSql.substring(start, schemaSql.indexOf('\n);', start));
    expect(
      table,
      contains('primary key (tenant_id, command_scope, idempotency_key)'),
    );
    expect(table, contains('result_snapshot jsonb,'));
    expect(table, contains('created_at timestamptz not null default now(),'));
    expect(
      table,
      contains("check (status in ('in_progress', 'succeeded', 'failed'))"),
    );
    for (final removed in [
      'id uuid primary key',
      'result_type',
      'result_id',
      'correlation_id',
      'expires_at',
      'updated_at',
      "'uncertain'",
    ]) {
      expect(table, isNot(contains(removed)), reason: removed);
    }
  });

  test('begin helper takes 4 parameters and no longer returns record_id', () {
    final body = _lastFunctionBlock(helperSql, 'sales._begin_sales_idempotency');
    expect(
      body,
      contains(
        'sales._begin_sales_idempotency(\n'
        '  p_tenant_id uuid,\n'
        '  p_command_scope text,\n'
        '  p_idempotency_key text,\n'
        '  p_payload_hash text\n'
        ') returns jsonb',
      ),
    );
    expect(body, isNot(contains('p_correlation_id')));
    expect(body, isNot(contains('record_id')));
    expect(body, isNot(contains("'uncertain'")));
    expect(body, contains("'IDEMPOTENCY_CONFLICT'"));
    expect(body, contains('pg_advisory_xact_lock'));
    expect(
      helperSql,
      contains(
        'revoke all on function sales._begin_sales_idempotency(uuid, text, text, text)\n',
      ),
    );
  });

  test('complete helper takes 5 parameters and accepts succeeded/failed only', () {
    final body = _lastFunctionBlock(
      helperSql,
      'sales._complete_sales_idempotency',
    );
    expect(
      body,
      contains(
        'sales._complete_sales_idempotency(\n'
        '  p_tenant_id uuid,\n'
        '  p_command_scope text,\n'
        '  p_idempotency_key text,\n'
        '  p_status text,\n'
        '  p_result_snapshot jsonb\n'
        ') returns void',
      ),
    );
    expect(body, contains("if p_status not in ('succeeded', 'failed') then"));
    for (final removed in ['result_type', 'result_id', 'updated_at', "'uncertain'"]) {
      expect(body, isNot(contains(removed)), reason: removed);
    }
    expect(
      helperSql,
      contains(
        'revoke all on function sales._complete_sales_idempotency(uuid, text, text, text, jsonb)\n',
      ),
    );
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

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`
Expected: FAIL 3 test.

- [ ] **Step 3: Sửa `create table` trong `20260830005`** — thay toàn bộ khối dòng 18–36 bằng:

```sql
create table if not exists sales.idempotency_records (
  tenant_id uuid not null,
  command_scope varchar(100) not null,
  idempotency_key varchar(150) not null,
  payload_hash varchar(128) not null,
  status text not null,
  result_snapshot jsonb,
  created_at timestamptz not null default now(),
  constraint sales_idempotency_records_pkey
    primary key (tenant_id, command_scope, idempotency_key),                   -- FC-18
  constraint sales_idempotency_records_status_check
    check (status in ('in_progress', 'succeeded', 'failed'))
);
```

- [ ] **Step 4: Sửa `_begin_sales_idempotency` trong `20260830006`**

1. Chữ ký: xoá dòng `  p_payload_hash text,` + `  p_correlation_id uuid` → còn `  p_payload_hash text` (dòng cuối, không dấu phẩy).
2. `declare`: xoá dòng `  v_record_id uuid;`.
3. Hai nhánh `return jsonb_build_object(` trong `if found then`: xoá dòng `        'record_id', v_record.id,` và `      'record_id', v_record.id,`.
4. Thay đoạn từ `  v_record_id := gen_random_uuid();` đến hết `return` cuối bằng:

```sql
  insert into sales.idempotency_records (
    tenant_id,
    command_scope,
    idempotency_key,
    payload_hash,
    status
  ) values (
    p_tenant_id,
    trim(p_command_scope),
    v_key,
    v_hash,
    'in_progress'
  );

  return jsonb_build_object(
    'decision', 'new',
    'status', 'in_progress'
  );
```

5. Nhánh `if v_record.status in ('in_progress', 'uncertain') then` → `if v_record.status = 'in_progress' then`.

- [ ] **Step 5: Sửa `_complete_sales_idempotency` trong `20260830006`** — thay cả hàm bằng:

```sql
create or replace function sales._complete_sales_idempotency(
  p_tenant_id uuid,
  p_command_scope text,
  p_idempotency_key text,
  p_status text,
  p_result_snapshot jsonb
) returns void
language plpgsql
security definer
set search_path = sales, iam, public, pg_temp
as $$
declare
  v_key text := trim(p_idempotency_key);
begin
  if p_status not in ('succeeded', 'failed') then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Idempotency completion status is invalid.'
    )::text;
  end if;

  update sales.idempotency_records
  set status = p_status,
      result_snapshot = p_result_snapshot
  where tenant_id = p_tenant_id
    and command_scope = trim(p_command_scope)
    and idempotency_key = v_key;

  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'CONTEXT_INVALID',
      'message', 'Idempotency record was not found for completion.'
    )::text;
  end if;
end;
$$;
```

- [ ] **Step 6: Sửa `revoke` (dòng 269–272)**

```sql
revoke all on function sales._begin_sales_idempotency(uuid, text, text, text)
  from public, anon, authenticated;
revoke all on function sales._complete_sales_idempotency(uuid, text, text, text, jsonb)
  from public, anon, authenticated;
```

- [ ] **Step 7: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart test/domain/schema/sales_shared_rpc_helpers_sql_contract_test.dart test/domain/schema/sales_rebuild_schema_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): slim idempotency_records to 7 columns and simplify helpers`

---

### Task 2: Sửa mọi chỗ gọi helper

**Files:**
- Modify: `supabase/migrations/20260830007_sales_draft_rpcs.sql`, `20260830008_sales_checkout_rpcs.sql`, `20260830009_sales_settlement_rpcs.sql`, `20260830010_sales_inquiry_receipt_rpcs.sql`, `20260830012_sales_return_exchange_session_rpcs.sql`, `20260830013_sales_return_exchange_settlement_rpcs.sql`, `20260830014_sales_return_exchange_confirmation_rpcs.sql`, `20260904001_sales_normalize_outbox_and_commands.sql`
- Test: `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`

**Interfaces:**
- Consumes: chữ ký helper mới từ Task 1 (begin 4 tham số, complete 5 tham số).

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  const finalDefinitions = <String, List<String>>{
    '20260830007_sales_draft_rpcs.sql': [
      'sales.save_sales_order_draft',
      'sales.update_sales_order_draft',
      'sales.cancel_sales_order_draft',
    ],
    '20260830008_sales_checkout_rpcs.sql': ['sales.finalize_sales_order'],
    '20260830009_sales_settlement_rpcs.sql': ['sales.void_sales_payment'],
    '20260830010_sales_inquiry_receipt_rpcs.sql': [
      'sales.generate_sales_receipt',
      'sales.record_sales_receipt_activity',
    ],
    '20260830012_sales_return_exchange_session_rpcs.sql': [
      'sales.start_return_exchange',
      'sales.update_return_exchange',
      'sales.cancel_return_exchange',
    ],
    '20260830013_sales_return_exchange_settlement_rpcs.sql': [
      'sales.settle_return_exchange_difference',
    ],
    '20260830014_sales_return_exchange_confirmation_rpcs.sql': [
      'sales.complete_return_exchange',
    ],
    '20260904001_sales_normalize_outbox_and_commands.sql': [
      'sales.record_sales_payment',
      'sales.record_sales_refund',
      'sales.confirm_sales_order_cancellation',
      'sales.confirm_return_exchange',
    ],
  };

  test('final definitions call helpers with the new arity', () {
    var beginCalls = 0;
    var completeCalls = 0;
    finalDefinitions.forEach((file, functions) {
      final sql = _readMigration(file);
      for (final fn in functions) {
        final body = _lastFunctionBlock(sql, fn);
        for (final args in _callArgumentCounts(
          body,
          'sales._begin_sales_idempotency(',
        )) {
          expect(args, 4, reason: '$fn begin');
          beginCalls++;
        }
        for (final args in _callArgumentCounts(
          body,
          'sales._complete_sales_idempotency(',
        )) {
          expect(args, 5, reason: '$fn complete');
          completeCalls++;
        }
      }
    });
    expect(beginCalls, 16);
    expect(completeCalls, 22);
  });
```

Thêm helper cuối file:

```dart
/// Number of top-level arguments of every `<callPrefix>…)` in [sql].
List<int> _callArgumentCounts(String sql, String callPrefix) {
  final counts = <int>[];
  var from = 0;
  while (true) {
    final start = sql.indexOf(callPrefix, from);
    if (start < 0) {
      return counts;
    }
    var depth = 1;
    var commas = 0;
    var inString = false;
    var i = start + callPrefix.length;
    for (; i < sql.length && depth > 0; i++) {
      final ch = sql[i];
      if (ch == "'") {
        inString = !inString;
      } else if (!inString) {
        if (ch == '(') {
          depth++;
        } else if (ch == ')') {
          depth--;
        } else if (ch == ',' && depth == 1) {
          commas++;
        }
      }
    }
    counts.add(commas + 1);
    from = i;
  }
}
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`
Expected: FAIL `final definitions call helpers with the new arity` (begin 5 ≠ 4).

- [ ] **Step 3: Sửa lời gọi `_begin_sales_idempotency`** (16 chỗ, chỉ trong các hàm ở bảng khảo sát) — **xoá tham số cuối `v_correlation`** và dấu phẩy trước nó. Ví dụ:

```sql
-- trước
  v_decision := sales._begin_sales_idempotency(
    p_tenant_id,
    'save_sales_order_draft',
    trim(p_idempotency_key),
    coalesce(p_payload_hash, ''),
    v_correlation
  );
-- sau
  v_decision := sales._begin_sales_idempotency(
    p_tenant_id,
    'save_sales_order_draft',
    trim(p_idempotency_key),
    coalesce(p_payload_hash, '')
  );

-- trước (kiểu một dòng)
  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'start_return_exchange', idempotency_key, payload_hash, v_correlation
  );
-- sau
  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'start_return_exchange', idempotency_key, payload_hash
  );

-- trước (cancel_return_exchange)
  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'cancel_return_exchange', idempotency_key,
    coalesce(nullif(v_hash, ''), 'cancel'), v_correlation
  );
-- sau
  v_idem := sales._begin_sales_idempotency(
    tenant_id, 'cancel_return_exchange', idempotency_key,
    coalesce(nullif(v_hash, ''), 'cancel')
  );
```

- [ ] **Step 4: Sửa lời gọi `_complete_sales_idempotency`** (22 chỗ) — **xoá tham số thứ 5 (`result_type`) và thứ 6 (`result_id`)**. Ví dụ:

```sql
-- trước
  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'save_sales_order_draft',
    trim(p_idempotency_key),
    'succeeded',
    'sales_order_draft',
    v_draft_id,
    v_result
  );
-- sau
  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'save_sales_order_draft',
    trim(p_idempotency_key),
    'succeeded',
    v_result
  );

-- trước (kiểu gọn)
    perform sales._complete_sales_idempotency(
      tenant_id, 'start_return_exchange', trim(idempotency_key),
      'succeeded', 'return_exchange_order', v_existing.id, v_result
    );
-- sau
    perform sales._complete_sales_idempotency(
      tenant_id, 'start_return_exchange', trim(idempotency_key),
      'succeeded', v_result
    );

-- trước (finalize_sales_order, nhánh failed)
    perform sales._complete_sales_idempotency(
      p_tenant_id,
      'finalize_sales_order',
      trim(p_idempotency_key),
      'failed',
      'checkout_result',
      null,
      jsonb_build_object(
-- sau
    perform sales._complete_sales_idempotency(
      p_tenant_id,
      'finalize_sales_order',
      trim(p_idempotency_key),
      'failed',
      jsonb_build_object(
```

Nếu sau khi sửa một biến chỉ còn dùng làm tham số cũ (vd `v_tx_id`, `v_draft_id`, `v_session_id`, `v_inserted`) thì **vẫn giữ** — các biến này còn dùng ở chỗ khác trong hàm. Không đụng khai báo `v_correlation`.

- [ ] **Step 5: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`
Expected: PASS (16 begin, 22 complete).

- [ ] **Step 6: Grep đối chiếu**

Run: `grep -n "v_correlation$\|v_correlation *)" supabase/migrations/2026083000[7-9]*.sql supabase/migrations/2026083001[0-4]*.sql supabase/migrations/20260904001*.sql`
Expected: các dòng còn lại chỉ nằm trong bản cũ của `record_sales_payment`/`record_sales_refund` (`009`), `confirm_sales_order_cancellation` (`011`), `confirm_return_exchange` (`014`), hoặc là lời gọi hàm khác (outbox/emit) — không phải `_begin_sales_idempotency` ở định nghĩa cuối.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): update idempotency helper call sites to new signatures`

---

### Task 3: Dọn checkout (update thừa + `uncertain`)

**Files:**
- Modify: `supabase/migrations/20260830008_sales_checkout_rpcs.sql:327-336,866`
- Modify: `modules/sales/infrastructure/test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart:125`
- Test: `modules/sales/infrastructure/test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`

- [ ] **Step 1: Thêm test (fail)** — thêm vào cuối `main()`:

```dart
  test('checkout drops pre-write snapshot update and uncertain mapping', () {
    final sql = _readMigration('20260830008_sales_checkout_rpcs.sql');
    final finalize = _lastFunctionBlock(sql, 'sales.finalize_sales_order');
    expect(finalize, isNot(contains('Retain recovery scope')));
    expect(finalize, isNot(contains('update sales.idempotency_records')));
    final result = _lastFunctionBlock(sql, 'sales.get_checkout_result');
    expect(result, isNot(contains("'uncertain'")));
    expect(
      result,
      contains("when v_record.status = 'in_progress' then 'processing'"),
    );
  });
```

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart`
Expected: FAIL test mới.

- [ ] **Step 3: Xoá update thừa trong `finalize_sales_order`** — xoá nguyên khối sau (kèm dòng trống sau nó), nằm ngay trước `  begin` + `    if p_source_draft_id is not null then`:

```sql
  -- Retain recovery scope even if a future worker leaves this record unresolved.
  update sales.idempotency_records
  set result_snapshot = jsonb_build_object(
        'storeId', p_store_id,
        'requestedByUserId', p_actor_id
      )
  where tenant_id = p_tenant_id
    and command_scope = 'finalize_sales_order'
    and idempotency_key = trim(p_idempotency_key);

```

- [ ] **Step 4: Bỏ nhánh `uncertain` trong `get_checkout_result`** — xoá dòng:

```sql
      when v_record.status = 'uncertain' then 'uncertain'
```

- [ ] **Step 5: Sửa test cũ** `sales_checkout_group_d_sql_contract_test.dart:125`:

```dart
    expect(statusSql, isNot(contains("'uncertain'")));
```

- [ ] **Step 6: Chạy test, xác nhận pass**

Run: `cd modules/sales/infrastructure && dart test test/domain/schema/sales_refactor_01_idempotency_records_sql_contract_test.dart test/domain/sales_order/sales_checkout_group_d_sql_contract_test.dart`
Expected: PASS.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

Đề xuất: `refactor(sales): drop unreachable uncertain status and redundant checkout snapshot write`

---

### Task 4: Kiểm chứng toàn bộ + tiến độ

**Files:**
- Modify: `docs/superpowers/specs/sales-schema-refactor/README.md`

- [ ] **Step 1: Grep toàn bộ migration**

Run: `grep -nE "idempotency_records.*(result_type|result_id|correlation_id|expires_at|updated_at)|'record_id'" supabase/migrations/*.sql`
Expected: không còn kết quả.

Run: `grep -n "'uncertain'" supabase/migrations/20260830005_sales_rebuild_schema.sql supabase/migrations/20260830006_sales_shared_rpc_helpers.sql supabase/migrations/20260830008_sales_checkout_rpcs.sql`
Expected: không còn kết quả.

- [ ] **Step 2: Registry + policy**

Run: `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write && dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict`
Expected: OK; `REGISTRY.yaml` không đổi (không thêm/bỏ hàm).

- [ ] **Step 3: Chạy toàn bộ test Sales infrastructure**

Run: `cd modules/sales/infrastructure && dart test`
Expected: chỉ còn 11 test baseline fail (README spec); không có fail mới.

- [ ] **Step 4: Tiến độ spec** — dòng bảng 1 README: `✅ Đã chốt · bỏ 6 cột, bỏ uncertain · 📝 Plan … · 🧪 Đã sửa migration gốc, chờ reset`.

- [ ] **Step 5: Dừng — user reset + smoke test**

Sau `supabase db reset`:
1. Lưu nháp, sửa nháp, huỷ nháp.
2. Thanh toán đơn; bấm thanh toán lại cùng lúc hai lần (hoặc gửi lại cùng key) → chỉ một đơn.
3. Thu thêm, hoàn tiền trên đơn; in/chia sẻ hoá đơn.
4. Huỷ đơn; đổi trả (mở, sửa, xác nhận, tất toán chênh lệch, hoàn tất).
5. SQL Editor: `select command_scope, status, count(*) from sales.idempotency_records group by 1, 2;` → chỉ `succeeded`/`failed`.
