# Phiếu bán hàng tạo lại sau đổi/trả — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sau khi quyết toán đơn thay đổi (đổi/trả, thu thêm, hoàn tiền), lần mở phiếu kế tiếp phải tạo phiếu mới (đơn gốc − hàng trả + hàng đổi) thay vì đọc lại bản chụp cũ — **giữ bảng `sales.sales_receipts`**, chỉ sửa SQL.

**Architecture:** Có 2 chỗ chặn, cả hai nằm trong `20260830010_sales_inquiry_receipt_rpcs.sql`:
1. `get_sales_order_detail` trả `currentReceiptId` là phiếu `generated` mới nhất dù phiếu đó cũ hơn quyết toán → app gọi `GetSalesReceiptQuery` đọc bản chụp cũ. **Sửa:** bỏ qua phiếu có `generated_at` < `sales_order_settlements.updated_at` → trả `null` → app tự gọi tạo phiếu.
2. `generate_sales_receipt` dùng nguyên khóa app gửi (`sales-receipt:{tenant}:{order}:v{order.version}`); đổi/trả không tăng `sales_orders.version` nên khóa trùng lần đầu → idempotency replay phiếu cũ. **Sửa:** server ghép `:s{settlement.version}` vào khóa (settlement version tăng mỗi lần `_recompute_sales_settlement`).
App Dart **không đổi** (handler vẫn gửi khóa cũ; server tự phân biệt theo trạng thái quyết toán).

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test` (SQL contract test dạng đọc text migration).

**Spec:** Thiết kế chốt trong chat 2026-09-24 (không có spec file). Tiền đề: thay đổi chưa commit trong working tree — hàm `sales._sales_receipt_lines_payload` + `generate_sales_receipt` in dòng hiện tại (test `sales_receipt_current_lines_sql_contract_test.dart`).

> **Trạng thái (2026-09-25):** user đã implement xong Task 1–3; Claude review Task 1–2 đạt; đã kiểm tra trên DB thật với đơn DH202609240002 (phiếu mới 3 thùng + 5 thùng, Tổng đơn 400.000đ) sau khi dọn phiếu tạo bằng code cũ (`update sales.sales_receipts set status = 'superseded' …`). File plan này được khôi phục lại sau khi bị xoá nhầm.

## Global Constraints

- **Sửa trực tiếp migration gốc** `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql`; tìm hàm theo nội dung, không theo số dòng.
- User **không reset DB**: cuối plan phải xuất file SQL chạy tay (`create or replace`) cho 2 hàm đã sửa.
- Không đổi chữ ký RPC, không đổi DTO/Dart, không đổi bảng.
- Không sửa test baseline `sales_receipt_group_e_sql_contract_test.dart` (đang đọc file `_drafts/010` không còn tồn tại — fail sẵn), `sales_remove_unused_policy_tables_sql_contract_test.dart` (fail sẵn 4 test).
- Không `dart format` cả package; chỉ file test mới.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa hàm: `node .gitnexus/run.cjs impact "<tên hàm>" --direction upstream --repo .` cho `get_sales_order_detail`, `generate_sales_receipt` (hàm SQL có thể ra `UNKNOWN`; báo lại kết quả cho user).

## Lưu ý dễ sót

- **Task 2 — di chuyển, không copy:** khối `select * into v_settlement …` phải **chuyển lên trước** `_begin_sales_idempotency` (xoá ở vị trí cũ). Copy thêm một bản sẽ load/lock quyết toán hai lần.
- **Task 2 — cùng một khóa ở cả hai đầu:** `_complete_sales_idempotency` cuối hàm phải đổi `trim(p_idempotency_key)` → `v_idem_key`. Sót chỗ này thì bản ghi idempotency tạo ở đầu hàm (theo `v_idem_key`) kẹt mãi ở `in_progress`, lần mở phiếu sau báo `IN_PROGRESS`.
- **Task 3 — chỉ 2 hàm:** file SQL chạy tay chỉ gồm `get_sales_order_detail` và `generate_sales_receipt`; `_sales_receipt_lines_payload` user đã chạy trước đó.
- **Phiếu tạo bằng code cũ:** phiếu nào được tạo **sau** lần đổi quyết toán cuối nhưng **trước** khi DB có hàm phiếu mới vẫn bị coi là «còn mới» → cần dọn một lần bằng `update sales.sales_receipts set status = 'superseded' where status = 'generated'` (DB dev), rồi thoát hẳn màn chi tiết đơn và vào lại.

## Khảo sát

| Vị trí | Nội dung |
|---|---|
| `20260830010` `get_sales_order_detail` | `select r.id into v_current_receipt_id from sales.sales_receipts r where … r.status = 'generated' order by r.receipt_version desc …` — không xét quyết toán |
| `20260830010` `generate_sales_receipt` | `v_idem := sales._begin_sales_idempotency(p_tenant_id, 'generate_sales_receipt', p_idempotency_key, p_payload_hash)` chạy **trước** khi load `v_settlement`; cuối hàm `_complete_sales_idempotency(…, trim(p_idempotency_key), …)` |
| `20260830006` `_recompute_sales_settlement` | `version = version + 1, updated_at = now()` — chạy sau mọi collection/refund/adjustment |
| `20260904001` `confirm_return_exchange` | không `update sales.sales_orders` → `sales_orders.version` không đổi |
| App `sales_receipt_operation_handler.dart:267` | khóa `'sales-receipt:$tenantId:$salesOrderId:v$version'` (giữ nguyên) |
| `sales.idempotency_records.idempotency_key` | `varchar(150)`; khóa hiện ~92 ký tự, thêm `:s{bigint}` vẫn < 150 |

## File Structure

- Modify: `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` — 2 hàm `get_sales_order_detail`, `generate_sales_receipt`.
- Create: `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart` — contract test cho cả 2 chỗ chặn.
- Output (không commit): file SQL chạy tay gửi user.

---

### Task 1: `get_sales_order_detail` bỏ qua phiếu cũ hơn quyết toán

**Files:**
- Modify: `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` (hàm `sales.get_sales_order_detail`, khối `select r.id into v_current_receipt_id`)
- Create: `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart`

**Interfaces:**
- Consumes: bảng `sales.sales_order_settlements(tenant_id, sales_order_id, updated_at)` (unique theo `sales_order_id`).
- Produces: `currentReceiptId` = `null` khi phiếu `generated` mới nhất có `generated_at` < `updated_at` của quyết toán. Payload key giữ nguyên `'currentReceiptId'` (test group F dòng 84 vẫn pass).

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "get_sales_order_detail" --direction upstream --repo .`
Expected: báo cáo blast radius (có thể `UNKNOWN` cho hàm SQL). Ghi lại để báo user.

- [ ] **Step 2: Viết test fail**

Tạo `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — phiếu bán hàng được tạo lại sau khi quyết toán đổi
/// (đổi/trả, thu thêm, hoàn tiền) thay vì đọc lại bản chụp cũ.
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('detail hides a receipt generated before the latest settlement change', () {
    final detail = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_detail');
    final start = detail.indexOf('into v_current_receipt_id');
    final lookup = detail.substring(start, detail.indexOf('limit 1;', start));
    expect(lookup, contains("r.status = 'generated'"));
    expect(lookup, contains('from sales.sales_order_settlements s'));
    expect(lookup, contains('s.sales_order_id = r.sales_order_id'));
    expect(lookup, contains('s.updated_at > r.generated_at'));
    expect(lookup, contains('and not exists ('));
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

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart`
Expected: FAIL — `lookup` không chứa `from sales.sales_order_settlements s`.

- [ ] **Step 4: Sửa SQL**

Trong `sales.get_sales_order_detail`, thay khối:

```sql
  select r.id
  into v_current_receipt_id
  from sales.sales_receipts r
  where r.tenant_id = v_order.tenant_id
    and r.sales_order_id = v_order.id
    and r.status = 'generated'
  order by r.receipt_version desc, r.generated_at desc, r.id desc
  limit 1;
```

bằng:

```sql
  -- A receipt older than the latest settlement change (return/exchange,
  -- extra collection, refund) is a stale snapshot: return null so the app
  -- generates a fresh receipt instead of re-reading the old one.
  select r.id
  into v_current_receipt_id
  from sales.sales_receipts r
  where r.tenant_id = v_order.tenant_id
    and r.sales_order_id = v_order.id
    and r.status = 'generated'
    and not exists (
      select 1
      from sales.sales_order_settlements s
      where s.tenant_id = r.tenant_id
        and s.sales_order_id = r.sales_order_id
        and s.updated_at > r.generated_at
    )
  order by r.receipt_version desc, r.generated_at desc, r.id desc
  limit 1;
```

- [ ] **Step 5: Chạy test, xác nhận pass + không vỡ test liên quan**

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart test/domain/sales_order/ test/domain/schema/`
Expected: test mới PASS; các test khác chỉ còn các fail có sẵn (`sales_remove_unused_policy_tables_sql_contract_test.dart` 4 test; các test đọc file `_drafts` không tồn tại). Xác nhận bằng cách so với `git stash` như Task 2 Step 7.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart
git commit -m "fix(sales): chi tiết đơn không trả phiếu cũ hơn quyết toán"
```

(User tự commit.)

---

### Task 2: `generate_sales_receipt` khóa idempotency theo version quyết toán

**Files:**
- Modify: `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql` (hàm `sales.generate_sales_receipt`)
- Modify: `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart`

**Interfaces:**
- Consumes: `v_settlement.version` (bigint, tăng mỗi lần `_recompute_sales_settlement`); `sales._begin_sales_idempotency(uuid, text, text, text)`, `sales._complete_sales_idempotency(uuid, text, text, text, jsonb)` (không đổi).
- Produces: khóa hiệu lực `trim(p_idempotency_key) || ':s' || v_settlement.version`. Chữ ký RPC không đổi; app vẫn gửi `sales-receipt:{tenant}:{order}:v{version}`.

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "generate_sales_receipt" --direction upstream --repo .`
Expected: báo cáo blast radius; ghi lại để báo user.

- [ ] **Step 2: Viết test fail**

Thêm vào `main()` của `sales_receipt_freshness_sql_contract_test.dart` (sau test của Task 1):

```dart
  test('generate scopes the idempotency key to the settlement version', () {
    final receipt = _lastFunctionBlock(inquirySql, 'sales.generate_sales_receipt');
    expect(receipt, contains('v_idem_key text;'));
    expect(
      receipt,
      contains("v_idem_key := trim(p_idempotency_key) || ':s' || v_settlement.version;"),
    );
    expect(
      receipt,
      contains(
        "v_idem := sales._begin_sales_idempotency(\n"
        "    p_tenant_id, 'generate_sales_receipt', v_idem_key, p_payload_hash);",
      ),
    );
    expect(
      receipt,
      contains("'generate_sales_receipt',\n    v_idem_key,\n    'succeeded',"),
    );
    expect(receipt, isNot(contains('trim(p_idempotency_key),')));
    // Settlement must be loaded (and locked) before the key is derived.
    expect(
      receipt.indexOf('select * into v_settlement from sales.sales_order_settlements'),
      lessThan(receipt.indexOf('v_idem_key :=')),
    );
  });
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart`
Expected: FAIL — không có `v_idem_key text;`.

- [ ] **Step 4: Sửa SQL — khai báo biến**

Trong khối `declare` của `sales.generate_sales_receipt`, sau dòng `v_idem jsonb;` thêm:

```sql
  v_idem_key text;
```

- [ ] **Step 5: Sửa SQL — load quyết toán trước, ghép khóa**

> ⚠️ Đây là **di chuyển** khối load quyết toán lên trên idempotency, không phải thêm một bản. Sau khi sửa, trong hàm chỉ còn **một** câu `select * into v_settlement`.

Trong thân hàm, thay đoạn từ `v_idem := sales._begin_sales_idempotency(` đến hết khối `select * into v_settlement … end if;` (hiện tại):

```sql
  v_idem := sales._begin_sales_idempotency(
    p_tenant_id, 'generate_sales_receipt', p_idempotency_key, p_payload_hash);
  if v_idem ->> 'decision' = 'replay' then
    return coalesce(v_idem -> 'result_snapshot', '{}'::jsonb);
  end if;
  if v_idem ->> 'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IN_PROGRESS', 'message', 'Receipt generation is already in progress.'
    )::text;
  end if;

  select * into v_settlement from sales.sales_order_settlements
  where sales_order_id = p_sales_order_id and tenant_id = p_tenant_id
  order by version desc nulls last, id desc
  limit 1
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PROJECTION_PENDING', 'message', 'Settlement projection not ready.'
    )::text;
  end if;
```

bằng:

```sql
  select * into v_settlement from sales.sales_order_settlements
  where sales_order_id = p_sales_order_id and tenant_id = p_tenant_id
  order by version desc nulls last, id desc
  limit 1
  for update;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'PROJECTION_PENDING', 'message', 'Settlement projection not ready.'
    )::text;
  end if;

  -- Return/exchange, extra collection and refund bump the settlement version
  -- but not the order version the client keys on; scoping the key to the
  -- settlement version makes each settlement state produce its own receipt
  -- while retries within one state still replay.
  v_idem_key := trim(p_idempotency_key) || ':s' || v_settlement.version;
  v_idem := sales._begin_sales_idempotency(
    p_tenant_id, 'generate_sales_receipt', v_idem_key, p_payload_hash);
  if v_idem ->> 'decision' = 'replay' then
    return coalesce(v_idem -> 'result_snapshot', '{}'::jsonb);
  end if;
  if v_idem ->> 'decision' = 'in_progress' then
    raise exception using message = jsonb_build_object(
      'code', 'IN_PROGRESS', 'message', 'Receipt generation is already in progress.'
    )::text;
  end if;
```

- [ ] **Step 6: Sửa SQL — hoàn tất idempotency bằng cùng khóa**

> ⚠️ Bắt buộc. Nếu vẫn để `trim(p_idempotency_key)`, bản ghi idempotency mở bằng `v_idem_key` ở Step 5 không bao giờ được đóng → kẹt `in_progress`, lần sau báo `IN_PROGRESS`.

Cuối hàm, thay:

```sql
  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'generate_sales_receipt',
    trim(p_idempotency_key),
    'succeeded',
    v_result);
```

bằng:

```sql
  perform sales._complete_sales_idempotency(
    p_tenant_id,
    'generate_sales_receipt',
    v_idem_key,
    'succeeded',
    v_result);
```

- [ ] **Step 7: Chạy test, xác nhận pass + so baseline**

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/ test/domain/sales_order/ test/domain/schema/`
Expected: 2 test freshness + `sales_receipt_current_lines_sql_contract_test.dart` + `sales_refactor_15_receipts_sql_contract_test.dart` PASS. Các fail còn lại phải trùng baseline: xác nhận bằng

```bash
git stash push -q -- supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql
(cd modules/sales/infrastructure && dart test test/domain/sales_receipt/ test/domain/sales_order/ test/domain/schema/ 2>&1 | grep -E "\[E\]")
git stash pop -q
```

Danh sách `[E]` (trừ test freshness/current-lines mới) phải giống nhau trước/sau.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_freshness_sql_contract_test.dart
git commit -m "fix(sales): tạo lại phiếu bán hàng khi quyết toán thay đổi"
```

(User tự commit.)

---

### Task 3: SQL chạy tay + kiểm tra trên DB thật (user)

**Files:**
- Output (không commit): `$SCRATCH/receipt_refresh_manual.sql` (thư mục scratchpad của session)

**Interfaces:**
- Consumes: 2 hàm đã sửa ở Task 1–2 trong migration 010 (và `_sales_receipt_lines_payload` đã được user chạy trước đó).

- [ ] **Step 1: Xuất file SQL chạy tay**

> Chỉ 2 hàm dưới đây. `_sales_receipt_lines_payload` user đã chạy trước đó, không đưa vào.

Tách nguyên văn 2 hàm từ migration (tìm theo nội dung) vào một file bọc `begin; … commit;`:

```bash
F=supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql
O="$SCRATCH/receipt_refresh_manual.sql"
block() { s=$(grep -n "^create or replace function $1(" "$F" | tail -1 | cut -d: -f1); e=$(awk -v s="$s" 'NR>s && /^\$\$;/ {print NR; exit}' "$F"); sed -n "${s},${e}p" "$F"; }
{
  echo "-- Chạy tay trên SQL editor: phiếu bán hàng tạo lại sau khi quyết toán thay đổi."
  echo "-- Tương đương get_sales_order_detail + generate_sales_receipt trong 20260830010."
  echo "begin;"; echo
  block sales.get_sales_order_detail; echo
  block sales.generate_sales_receipt; echo
  echo "commit;"
} > "$O"
grep -c "create or replace function" "$O"
```

Expected: in ra `2`. Đọc lại file, gửi cho user (SendUserFile).

- [ ] **Step 2: User chạy file trên SQL editor**

Expected: `COMMIT`, không lỗi.

- [ ] **Step 3: User kiểm tra trên app với đơn đã đổi/trả (vd DH202609240002)**

Thoát hẳn màn chi tiết đơn (hoặc tắt/mở lại app) → vào lại đơn → mở phiếu. Expected: phiếu mới (3 thùng + 5 thùng, Tiền hàng 400.000đ, Tổng đơn 400.000đ), khớp phần sản phẩm ở chi tiết đơn.

Nếu vẫn chỉ có phiếu cũ: kiểm tra phiếu cũ có được tạo **sau** lần đổi quyết toán cuối không (xem «Lưu ý dễ sót») và dọn bằng `update sales.sales_receipts … set status = 'superseded'`.

- [ ] **Step 4: User kiểm tra DB**

```sql
select r.receipt_version, r.status, r.generated_at,
       jsonb_array_length(r.receipt_snapshot -> 'lines') as so_dong
from sales.sales_receipts r
join sales.sales_orders o on o.id = r.sales_order_id
where o.order_code = 'DH202609240002'
order by r.receipt_version;
```

Expected: phiếu 1 `superseded`, phiếu 2 `generated` với 2 dòng. Mở lại phiếu lần nữa không sinh phiếu 3 (idempotency replay trong cùng trạng thái quyết toán). `sales.idempotency_records` có khóa `…:v1:s3` với `status = succeeded`.

- [ ] **Step 5: Tóm tắt kết quả cho user**

Nêu: đã chạy/chưa chạy được gì, kết quả kiểm tra, còn lại gì (vd phiếu các đơn khác sẽ tự tạo lại khi mở).
