# Đổi/trả — sửa lỗi «Settlement plan association is missing or ambiguous» khi thu thêm — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xác nhận đổi/trả có **thu thêm** không còn bị chặn khi cùng một đơn đã có phiên đổi/trả khác (đã hoàn tất hoặc đã hủy) được tạo trong cùng một lần mở app.

**Architecture:** `settle_return_exchange_difference` (owner `20260830013`) — nhánh `collection` tìm bản định giá bằng `sales_order_id + correlation_id` và đòi đúng 1 kết quả. App sinh `correlationId` **một lần mỗi lần mở app** (`IamExecutionContext`, singleton) nên mọi phiên đổi/trả trong cùng lần chạy trùng `correlation_id`; bản định giá của phiên cũ (`confirmed`, hoặc `calculated` nếu phiên bị hủy) làm câu đếm ra ≥ 2 → chặn. **Sửa:** khi có tham số `return_exchange_id` (confirm luôn truyền `v_session.id`), cả collection lẫn refund tìm định giá **theo đúng phiên**; chỉ khi thiếu `return_exchange_id` mới rơi về cách tìm cũ theo `correlation_id` (giữ tương thích). Không đổi app, không đổi bảng, không đổi chữ ký RPC.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test` (SQL contract test đọc text migration).

**Spec:** Chốt trong chat 2026-09-25. Đã tái hiện trên DB dev: đơn có 2 phiên cùng `correlation_id = 17cda1a2-…` — phiên 1 `completed`/`confirmed`, phiên 2 `draft`/`calculated`, app báo «Không tải được quyết toán · Settlement plan association is missing or ambiguous.».

## Global Constraints

- **Sửa trực tiếp migration gốc** `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql`; tìm theo nội dung, không theo số dòng.
- User **không reset DB** → cuối plan xuất SQL chạy tay (`create or replace` nguyên hàm). Chữ ký không đổi nên grant cũ giữ nguyên.
- Không đổi app, DTO, command, bảng, chữ ký RPC. Không đổi `confirm_return_exchange` (đã truyền `return_exchange_id => v_session.id` cho cả collect lẫn refund).
- Giữ nguyên thông báo lỗi cũ cho đường fallback (`'Settlement plan association is missing or ambiguous.'`) và cho refund thiếu id (`'Refund settlement requires return_exchange_id.'`) — test cũ đang kiểm các chuỗi này.
- Không `dart format` cả package.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa: `node .gitnexus/run.cjs impact "settle_return_exchange_difference" --direction upstream --repo .` (hàm SQL có thể ra `UNKNOWN`; báo lại).

## Lưu ý dễ sót

- **Tham chiếu tham số đủ tên:** hàm dùng `#variable_conflict use_column` → luôn viết `settle_return_exchange_difference.return_exchange_id`, không viết trần `return_exchange_id`.
- **Không xoá đường tìm theo `correlation_id`:** chuyển nó thành nhánh fallback (khi `return_exchange_id is null` và `operation = 'collection'`), giữ nguyên câu `count(*)` và thông báo lỗi.
- **Refund thiếu id vẫn phải lỗi** như cũ (`'Refund settlement requires return_exchange_id.'`).
- Phần còn lại của hàm (từ `v_plan := coalesce(v_valuation.valuation_details -> 'settlement_plan', …)` trở đi) **không đổi**.
- Không cần dọn dữ liệu cũ: sau khi sửa, các phiên đang kẹt (như phiên `draft` ở trên) xác nhận lại được ngay.

## Khảo sát

| Vị trí | Hiện trạng |
|---|---|
| `20260830013` `settle_return_exchange_difference`, khối sau `_begin_sales_idempotency` | `if operation = 'refund' then` → cần `return_exchange_id`, tìm định giá theo phiên; `else` → cần `sales_order_id`, đếm định giá theo `rx.sales_order_id + coalesce(rx.correlation_id, '') = correlation_id + v.status in ('calculated','confirmed')`, khác 1 → «Settlement plan association is missing or ambiguous.» |
| `20260904001` `confirm_return_exchange` (khối `':collect'`) | gọi settle với `sales_order_id => v_session.sales_order_id, return_exchange_id => v_session.id, correlation_id => v_plan_corr` |
| `20260830012` `cancel_return_exchange` | chỉ đổi `status = 'cancelled'` của phiên, **không** đụng `return_exchange_valuations` |
| `modules/iam/infrastructure/lib/src/configuration/session/iam_execution_context.dart:11` | `correlationId ?? const Uuid().v4()` — một giá trị cho cả lần chạy app |

## File Structure

- Modify: `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql` — khối tìm định giá trong `settle_return_exchange_difference`.
- Create: `modules/sales/infrastructure/test/domain/return_exchange_order/settle_return_exchange_plan_lookup_sql_contract_test.dart`.
- Output (không commit): file SQL chạy tay.

---

### Task 1: Tìm định giá theo `return_exchange_id` cho cả thu thêm và hoàn

**Files:**
- Modify: `supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql`
- Create: `modules/sales/infrastructure/test/domain/return_exchange_order/settle_return_exchange_plan_lookup_sql_contract_test.dart`

**Interfaces:**
- Consumes: tham số sẵn có `return_exchange_id uuid`, `sales_order_id uuid`, `correlation_id text`, `operation text`.
- Produces: không đổi chữ ký / kết quả; chỉ đổi cách chọn `v_valuation`.

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "settle_return_exchange_difference" --direction upstream --repo .`
Ghi lại kết quả để báo user.

- [ ] **Step 2: Viết test fail**

Tạo `modules/sales/infrastructure/test/domain/return_exchange_order/settle_return_exchange_plan_lookup_sql_contract_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — settle tìm bản định giá theo đúng phiên đổi/trả khi có
/// `return_exchange_id`, để nhiều phiên cùng `correlation_id` (một lần mở app)
/// không làm thu thêm bị «missing or ambiguous».
void main() {
  final settlementSql = _readMigration('20260830013_sales_return_exchange_settlement_rpcs.sql');
  final confirmSql = _readMigration('20260904001_sales_normalize_outbox_and_commands.sql');

  test('settle resolves the plan by return_exchange_id before any correlation lookup', () {
    final settle = _lastFunctionBlock(settlementSql, 'sales.settle_return_exchange_difference');
    const byId = 'if settle_return_exchange_difference.return_exchange_id is not null then';
    expect(settle, contains(byId));
    final byIdAt = settle.indexOf(byId);
    final correlationAt = settle.indexOf("coalesce(rx.correlation_id, '')");
    expect(correlationAt, greaterThan(byIdAt));
    final byIdBlock = settle.substring(byIdAt, correlationAt);
    expect(
      byIdBlock,
      contains(
        'and return_exchange_valuations.return_exchange_order_id\n'
        '        = settle_return_exchange_difference.return_exchange_id',
      ),
    );
    expect(byIdBlock, contains("'Stored settlement plan is missing.'"));
    expect(byIdBlock, isNot(contains('correlation_id')));
  });

  test('refund without id still fails and correlation lookup stays as fallback', () {
    final settle = _lastFunctionBlock(settlementSql, 'sales.settle_return_exchange_difference');
    expect(settle, contains("elsif operation = 'refund' then"));
    expect(settle, contains("'Refund settlement requires return_exchange_id.'"));
    expect(settle, contains("'Settlement plan association is missing or ambiguous.'"));
    expect(settle, isNot(contains("if operation = 'refund' then\n    if return_exchange_id is null then")));
  });

  test('confirm passes the session id to the collect settle', () {
    final confirm = _lastFunctionBlock(confirmSql, 'sales.confirm_return_exchange');
    final start = confirm.indexOf("|| ':collect')");
    final end = confirm.indexOf("':confirm-collect'", start);
    expect(start, greaterThan(-1));
    expect(confirm.substring(start, end), contains('return_exchange_id => v_session.id,'));
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

Run: `cd modules/sales/infrastructure && dart test test/domain/return_exchange_order/settle_return_exchange_plan_lookup_sql_contract_test.dart`
Expected: 2 test đầu FAIL (chưa có nhánh theo id); test «confirm passes the session id» PASS (khảo sát đúng).

- [ ] **Step 4: Sửa SQL**

Trong `sales.settle_return_exchange_difference`, thay nguyên khối từ `if operation = 'refund' then` (ngay sau khối `_begin_sales_idempotency` / `in_progress`) tới hết `end if;` đóng nhánh collection (ngay trước dòng `v_plan := coalesce(v_valuation.valuation_details -> 'settlement_plan', '{}'::jsonb);`) — hiện là:

```sql
  if operation = 'refund' then
    if return_exchange_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Refund settlement requires return_exchange_id.'
      )::text;
    end if;
    select * into v_valuation
    from sales.return_exchange_valuations
    where return_exchange_valuations.tenant_id = settle_return_exchange_difference.tenant_id
      and return_exchange_valuations.return_exchange_order_id
        = settle_return_exchange_difference.return_exchange_id
    for update;
    if not found then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Stored settlement plan is missing.'
      )::text;
    end if;
  else
    if sales_order_id is null then
      … (khối đếm theo correlation_id, giữ nguyên) …
    for update of v;
  end if;
```

bằng:

```sql
  -- Resolve the plan by the session when the caller names it (confirm always
  -- does). One app run reuses one correlation id across sessions, so the
  -- correlation lookup below is only a fallback for callers without an id.
  if settle_return_exchange_difference.return_exchange_id is not null then
    select * into v_valuation
    from sales.return_exchange_valuations
    where return_exchange_valuations.tenant_id = settle_return_exchange_difference.tenant_id
      and return_exchange_valuations.return_exchange_order_id
        = settle_return_exchange_difference.return_exchange_id
    for update;
    if not found then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Stored settlement plan is missing.'
      )::text;
    end if;
  elsif operation = 'refund' then
    raise exception using message = jsonb_build_object(
      'code', 'RETURN_EXCHANGE_BLOCKED',
      'message', 'Refund settlement requires return_exchange_id.'
    )::text;
  else
    if sales_order_id is null then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Collection settlement requires sales_order_id.'
      )::text;
    end if;
    select count(*) into v_plan_count
    from sales.return_exchange_valuations v
    join sales.return_exchange_orders rx
      on rx.id = v.return_exchange_order_id
     and rx.tenant_id = v.tenant_id
    where v.tenant_id = settle_return_exchange_difference.tenant_id
      and rx.sales_order_id = settle_return_exchange_difference.sales_order_id
      and coalesce(rx.correlation_id, '') = settle_return_exchange_difference.correlation_id
      and v.status in ('calculated', 'confirmed');
    if v_plan_count is distinct from 1 then
      raise exception using message = jsonb_build_object(
        'code', 'RETURN_EXCHANGE_BLOCKED',
        'message', 'Settlement plan association is missing or ambiguous.'
      )::text;
    end if;
    select v.* into v_valuation
    from sales.return_exchange_valuations v
    join sales.return_exchange_orders rx
      on rx.id = v.return_exchange_order_id
     and rx.tenant_id = v.tenant_id
    where v.tenant_id = settle_return_exchange_difference.tenant_id
      and rx.sales_order_id = settle_return_exchange_difference.sales_order_id
      and coalesce(rx.correlation_id, '') = settle_return_exchange_difference.correlation_id
      and v.status in ('calculated', 'confirmed')
    for update of v;
  end if;
```

(Nhánh fallback `else` giữ nguyên văn khối cũ — chỉ chuyển vị trí.)

- [ ] **Step 5: Chạy test + so baseline**

```bash
cd modules/sales/infrastructure
dart test test/domain/return_exchange_order/ test/domain/schema/ test/domain/sales_order/
```

Expected: 3 test mới PASS; `sales_return_exchange_group_i_settlement_sql_contract_test.dart` và các test return_exchange khác PASS như trước. Các fail còn lại phải trùng baseline — xác nhận:

```bash
git stash push -q -- ../../../supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql
dart test test/domain/return_exchange_order/ test/domain/schema/ test/domain/sales_order/ 2>&1 | grep -E "\[E\]"
git stash pop -q
```

Danh sách `[E]` (trừ 2 test mới) giống nhau trước/sau.

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql modules/sales/infrastructure/test/domain/return_exchange_order/settle_return_exchange_plan_lookup_sql_contract_test.dart
git commit -m "fix(sales): thu thêm đổi/trả tìm kế hoạch quyết toán theo phiên"
```

(User tự commit.)

---

### Task 2: SQL chạy tay + kiểm tra lại trên DB thật (user)

**Files:**
- Output (không commit): `$SCRATCH/settle_plan_lookup_manual.sql`

- [ ] **Step 1: Xuất file SQL chạy tay**

```bash
F=supabase/migrations/20260830013_sales_return_exchange_settlement_rpcs.sql
O="$SCRATCH/settle_plan_lookup_manual.sql"
s=$(grep -n "^create or replace function sales.settle_return_exchange_difference(" "$F" | tail -1 | cut -d: -f1)
e=$(awk -v s="$s" 'NR>s && /^\$\$;/ {print NR; exit}' "$F")
{
  echo "-- Chạy tay trên SQL editor: thu thêm đổi/trả tìm kế hoạch quyết toán theo phiên."
  echo "begin;"; echo
  sed -n "${s},${e}p" "$F"; echo
  echo "commit;"
} > "$O"
grep -c "settle_return_exchange_difference.return_exchange_id is not null" "$O"
```

Expected: in ra `1`. Đọc lại file, gửi user (SendUserFile). Chữ ký không đổi nên không cần chạy lại grant.

- [ ] **Step 2: User chạy file trên SQL editor**

Expected: `COMMIT`, không lỗi.

- [ ] **Step 3: User kiểm tra lại kịch bản đã tái hiện (không tắt app giữa chừng)**

Sản phẩm: wxdie 50.000đ/hộp, Căng quá 100.000đ/thùng; khách có tên.

| Kịch bản | Kỳ vọng sau khi sửa |
|---|---|
| Phiên `draft` đang kẹt (đơn đã tái hiện, `correlation_id 17cda1a2-…`) → mở lại quyết toán → Xác nhận | ✅ Thành công, không còn «missing or ambiguous» |
| B: đơn mới wxdie × 2 (thu đủ 100.000đ) → đổi/trả 1: trả 1 hộp, đổi 1 thùng Căng quá (+50.000đ) → xác nhận; **không tắt app** → đổi/trả 2 tương tự → xác nhận | ✅ Cả 2 lần thành công |
| A: đơn mới → đổi/trả tới màn quyết toán → hủy phiếu; **không tắt app** → đổi/trả lại có thu thêm → xác nhận | ✅ Thành công |
| So sánh: lần 2 là hoàn tiền (trả 1 hộp, không lấy gì) | ✅ Thành công như trước |

- [ ] **Step 4: User kiểm tra DB**

```sql
select rx.created_at, rx.status as rx_status, rx.correlation_id,
       v.status as valuation_status, v.net_difference_minor
from sales.return_exchange_orders rx
join sales.return_exchange_valuations v on v.return_exchange_order_id = rx.id
join sales.sales_orders o on o.id = rx.sales_order_id
where o.order_code = '<mã đơn>'
order by rx.created_at;
```

Expected: nhiều phiên cùng `correlation_id` vẫn có thể xuất hiện (không đổi phía app) nhưng mỗi phiên đã xác nhận đều `completed` / `confirmed`; `sales_payment_transactions` có đủ khoản thu `return_exchange` cho từng phiên.

- [ ] **Step 5: Tóm tắt kết quả cho user**
