# Phiếu bán hàng theo tab «Đơn gốc» / «Sau đổi/trả» — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trên màn chi tiết đơn có đổi/trả, nút «Phiếu bán hàng» ở tab **«Đơn gốc»** mở phiếu **như lúc bán** (hàng gốc, tổng gốc, chỉ khoản thu lúc checkout); tab **«Sau đổi/trả»** giữ phiếu hiện tại (hàng khách đang giữ).

**Architecture:** Cách 1 (user chốt 2026-09-25) — phiếu đơn gốc **tính trực tiếp, không lưu**: RPC chỉ đọc mới `sales.get_sales_order_original_receipt` trả về `document` cùng shape `receipt_snapshot` (không có `settlementSnapshot`). Module sales thêm `GetSalesOrderOriginalReceiptQuery` → `SalesReceiptDocumentDto`. App: tab 0 (khi đơn có phiếu đổi/trả) gọi query mới; xem/in/chia sẻ chạy trên máy, **không ghi** `sales_receipt_activities`. Tab «Sau đổi/trả» và đơn chưa đổi/trả giữ luồng `SalesReceiptOperationHandler` cũ.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; Flutter/flutter_bloc; `vet45_generator` (build_runner) cho CQRS registrar.

**Spec:** Thiết kế chốt trong chat 2026-09-25 (không có spec file).

## Global Constraints

- **Không đổi bảng**, không đổi chữ ký RPC cũ, không đổi `generate_sales_receipt` / `get_sales_receipt` / `get_sales_order_detail`.
- **Sửa trực tiếp migration gốc** `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql`; user **không reset DB** → cuối plan xuất SQL chạy tay (`create or replace` + grant).
- Phiếu đơn gốc: **không lưu, không idempotency, không activity** (không `insert`/`update`).
- UI change được user yêu cầu (tab → phiếu khác nhau); không đổi layout khác. Trang xem trước dùng lại `SalesReceiptPreviewPage` + `SalesReceiptPdfGenerator` như cũ.
- Không `dart format` cả package (repo short-style cũ); chỉ format file mới nếu cần.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa symbol: `node .gitnexus/run.cjs impact "<symbol>" --direction upstream --repo .` cho `ISalesReceiptGateway`, `SupabaseSalesReceiptGateway`, `SalesReceiptRpcMapper`, `SalesReceiptPreviewPage`, `SalesOrderDetailCubit`, `SalesOrderDetailPage`; báo blast radius, cảnh báo nếu HIGH/CRITICAL.

## Lưu ý dễ sót

- **Chỉ khoản thu `checkout`:** phiếu đơn gốc lọc `source_context = 'checkout'` **và** `transaction_type = 'collection'` **và** `status = 'confirmed'`. Không lấy thu thêm/hoàn sau này (đó là phiếu «Sau đổi/trả»).
- **Không có `settlementSnapshot`** trong document đơn gốc → PDF tự in «Tổng đơn» = `orderTotal` (tổng lúc bán). Đừng thêm key này.
- **`ISalesReceiptGateway` có 2 implementer** (`SupabaseSalesReceiptGateway`, `FakeSalesReceiptGateway`) — thêm method vào cả hai, không thì không compile.
- **Chạy build_runner** ở `modules/sales/infrastructure` sau khi thêm handler; kiểm tra `sales_cqrs_registrar.g.dart` có `GetSalesOrderOriginalReceiptQueryHandler`. Không sửa tay file `.g.dart`.
- **Điều kiện tab gốc ở app:** `returns.isNotEmpty && _selectedTabIndex == 0`. Khi đơn chưa có đổi/trả, `effectiveTabIndex` = 0 nhưng tab không hiện → vẫn dùng luồng cũ.
- `SalesReceiptPreviewPage` đổi tham số `receipt` → `document`; cập nhật caller duy nhất `SalesOrderSlipPreviewPage` (`resolvedReceipt.document`).

## Khảo sát

| Vị trí | Hiện trạng |
|---|---|
| `20260830010` `get_sales_receipt` | mẫu kiểm quyền: `auth.uid()`, `iam.has_permission(…, 'sales.receipt.view')`, `iam.can_access_store`, `_assert_sales_actor`; grant ở cuối file (`revoke … from public, anon;` / `grant execute … to authenticated;`) |
| `20260830010` `generate_sales_receipt` | shape `receipt_snapshot` (receiptNumber, orderNumber, soldAt, store, seller, customer, lines, subtotal, discountTotal, taxTotal, roundingTotal, orderTotal, paidTotal, outstandingTotal, payments, dueAt, settlementSnapshot) |
| `modules/sales/application/lib/src/sales_receipt/` | `GetSalesReceiptQuery` (+ handler dùng `IPermissionChecker.require(SalesPermissions.viewReceipt)`), port `ISalesReceiptGateway` |
| `modules/sales/infrastructure/lib/src/domain/sales_receipt/` | `SupabaseSalesReceiptGateway._call` (map lỗi RPC), `SalesReceiptRpcMapper._document` (private) |
| `modules/sales/infrastructure/build.yaml` | `vet45_generator|cqrs_registrar` sinh `sales_cqrs_registrar.g.dart` |
| `infrastructure/test/domain/schema/sales_rpc_surface_parity_test.dart` | map `_gatewaySurface` khai báo RPC + mapper keys |
| App `sales_order_detail_page.dart` | `_selectedTabIndex` (mặc định 1), `_openReceipt()` dùng `_cubit.viewReceipt/printReceipt/shareReceipt`; đã dùng `MaterialPageRoute` cho màn phụ |
| App `sales_receipt_preview_page.dart` | nhận `SalesReceiptDto receipt` nhưng chỉ dùng `receipt.document` |

Ví dụ: đơn DH202609240002 (4 thùng × 50.000đ, thu 200.000đ tiền mặt lúc bán; sau đổi/trả thu thêm 200.000đ chuyển khoản). Phiếu đơn gốc: 4 thùng, Tổng đơn 200.000đ, Tiền mặt 200.000đ, Còn phải thu 0đ.

---

### Task 1: SQL — RPC chỉ đọc `get_sales_order_original_receipt`

**Files:**
- Modify: `supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql`
- Modify: `supabase/migrations/REGISTRY.yaml`
- Modify: `docs/themes/TH-05-sales-orders/harness/01-domain-model.md`
- Create: `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_original_sql_contract_test.dart`

**Interfaces:**
- Produces: `sales.get_sales_order_original_receipt(p_query_id uuid, p_tenant_id uuid, p_actor_id uuid, p_sales_order_id uuid) returns jsonb` — trả **document** (không envelope), grant `authenticated`.

- [ ] **Step 1: Viết test fail**

Tạo `modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_original_sql_contract_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — phiếu bán hàng «Đơn gốc»: tính trực tiếp, không lưu,
/// chỉ dòng đơn gốc + khoản thu lúc checkout.
void main() {
  final inquirySql = _readMigration('20260830010_sales_inquiry_receipt_rpcs.sql');

  test('original receipt is read-only with receipt view permission and store scope', () {
    final fn = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_original_receipt');
    expect(fn, contains('p_query_id uuid'));
    expect(fn, contains('p_sales_order_id uuid'));
    expect(fn, contains("iam.has_permission(p_tenant_id, 'sales.receipt.view')"));
    expect(fn, contains('iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id)'));
    expect(fn, contains("p_tenant_id, p_actor_id, v_order.store_id, 'sales.receipt.view'"));
    expect(fn, isNot(contains('insert into')));
    expect(fn, isNot(contains('update sales.')));
    expect(fn, isNot(contains('_begin_sales_idempotency')));
  });

  test('original receipt prints order lines, sale totals and checkout collections only', () {
    final fn = _lastFunctionBlock(inquirySql, 'sales.get_sales_order_original_receipt');
    expect(
      fn,
      contains("'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),"),
    );
    expect(fn, contains("and transaction.source_context = 'checkout'"));
    expect(fn, contains("and transaction.transaction_type = 'collection'"));
    expect(fn, contains("and transaction.status = 'confirmed'"));
    final orderTotal = fn.substring(fn.indexOf("'orderTotal'"), fn.indexOf("'paidTotal'"));
    expect(orderTotal, contains('v_order.payable_amount_minor'));
    expect(fn, contains('greatest(v_order.payable_amount_minor - v_paid_minor, 0)'));
    expect(fn, isNot(contains("'settlementSnapshot'")));
  });

  test('original receipt is granted to authenticated only', () {
    expect(
      inquirySql,
      contains(
        'revoke all on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) from public, anon;',
      ),
    );
    expect(
      inquirySql,
      contains(
        'grant execute on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) to authenticated;',
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

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/sales_receipt_original_sql_contract_test.dart`
Expected: FAIL — `sales.get_sales_order_original_receipt not found`.

- [ ] **Step 3: Thêm hàm vào migration 010**

Chèn ngay **sau** hàm `sales.get_sales_receipt` (sau dòng `$$;` kết thúc hàm đó, trước `create or replace function sales.record_sales_receipt_activity(`):

```sql
-- As-sold receipt for the «Đơn gốc» tab: original order lines, sale totals
-- and checkout collections only. Read-only and never persisted — the stored
-- receipt (generate_sales_receipt) is the after-return/exchange version.
create or replace function sales.get_sales_order_original_receipt(
  p_query_id uuid,
  p_tenant_id uuid,
  p_actor_id uuid,
  p_sales_order_id uuid
) returns jsonb
language plpgsql
security definer
set search_path = sales, iam, public, pg_temp
as $$
declare
  v_order sales.sales_orders%rowtype;
  v_payments jsonb;
  v_paid_minor bigint;
begin
  if auth.uid() is distinct from p_actor_id then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;
  if iam.has_permission(p_tenant_id, 'sales.receipt.view') is not true then
    raise exception using message = jsonb_build_object(
      'code', 'PERMISSION_DENIED', 'message', 'Permission denied.'
    )::text;
  end if;

  select * into v_order from sales.sales_orders
  where id = p_sales_order_id and tenant_id = p_tenant_id;
  if not found then
    raise exception using message = jsonb_build_object(
      'code', 'NOT_FOUND', 'message', 'Sales order not found.'
    )::text;
  end if;
  if not iam.can_access_store(p_tenant_id, v_order.store_id, p_actor_id) then
    raise exception using message = jsonb_build_object(
      'code', 'DATA_SCOPE_DENIED', 'message', 'Store scope denied.'
    )::text;
  end if;

  perform sales._assert_sales_actor(
    p_tenant_id, p_actor_id, v_order.store_id, 'sales.receipt.view'
  );

  -- Checkout collections only: later collections/refunds belong to the
  -- after-return/exchange receipt.
  select
    coalesce(jsonb_agg(jsonb_build_object(
      'method', method_total.payment_method_code,
      'amount', jsonb_build_object(
        'amountMinor', method_total.paid_minor,
        'currencyCode', v_order.currency_code
      ),
      'status', 'confirmed'
    ) order by method_total.first_at, method_total.payment_method_code), '[]'::jsonb),
    coalesce(sum(method_total.paid_minor), 0)::bigint
  into v_payments, v_paid_minor
  from (
    select
      transaction.payment_method_code,
      sum(transaction.amount_minor) as paid_minor,
      min(transaction.occurred_at) as first_at
    from sales.sales_payment_transactions transaction
    join sales.sales_order_settlements settlement
      on settlement.id = transaction.sales_order_settlement_id
     and settlement.tenant_id = transaction.tenant_id
    where transaction.tenant_id = p_tenant_id
      and settlement.sales_order_id = p_sales_order_id
      and transaction.status = 'confirmed'
      and transaction.source_context = 'checkout'
      and transaction.transaction_type = 'collection'
    group by transaction.payment_method_code
  ) method_total;

  return jsonb_build_object(
    'receiptNumber', 'PBH-' || to_char(v_order.created_at at time zone 'utc', 'YYYYMMDD')
      || '-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 8)),
    'orderNumber', coalesce(
      nullif(btrim(v_order.order_code), ''),
      'SO-' || upper(substr(replace(v_order.id::text, '-', ''), 1, 12))
    ),
    'soldAt', to_char(v_order.completed_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
    'store', coalesce(v_order.sales_context_snapshot -> 'store', '{}'::jsonb),
    'seller', coalesce(v_order.sales_context_snapshot -> 'seller', '{}'::jsonb),
    'customer', v_order.sales_context_snapshot -> 'customer',
    'lines', sales._sales_order_lines_payload(p_tenant_id, p_sales_order_id, v_order.currency_code),
    'subtotal', jsonb_build_object(
      'amountMinor', v_order.subtotal_amount_minor,
      'currencyCode', v_order.currency_code
    ),
    'discountTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.discount_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'taxTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.tax_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'roundingTotal', jsonb_build_object(
      'amountMinor', coalesce(v_order.rounding_amount_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'orderTotal', jsonb_build_object(
      'amountMinor', v_order.payable_amount_minor,
      'currencyCode', v_order.currency_code
    ),
    'paidTotal', jsonb_build_object(
      'amountMinor', v_paid_minor,
      'currencyCode', v_order.currency_code
    ),
    'outstandingTotal', jsonb_build_object(
      'amountMinor', greatest(v_order.payable_amount_minor - v_paid_minor, 0),
      'currencyCode', v_order.currency_code
    ),
    'payments', v_payments,
    'dueAt', case
      when v_order.payment_due_date is null then null
      else to_char(v_order.payment_due_date, 'YYYY-MM-DD')
    end
  );
end;
$$;
```

- [ ] **Step 4: Thêm grant**

Ngay sau 2 dòng grant hiện có của `get_sales_receipt` (`revoke all on function sales.get_sales_receipt(uuid, uuid, uuid, uuid, integer) from public, anon;` … `grant execute on function sales.get_sales_receipt(uuid, uuid, uuid, uuid, integer) to authenticated;`), thêm:

```sql
revoke all on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) from public, anon;
grant execute on function sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid) to authenticated;
```

- [ ] **Step 5: Header migration + REGISTRY**

Header dòng `-- Touches:` của migration 010: thêm `, get_sales_order_original_receipt` ngay sau `get_sales_receipt`.

`supabase/migrations/REGISTRY.yaml`: thêm (theo thứ tự chữ cái, ngay trước `get_sales_order_payment_summary:`):

```yaml
  get_sales_order_original_receipt: 20260830010_sales_inquiry_receipt_rpcs.sql
```

- [ ] **Step 6: Ghi chú domain**

Trong `docs/themes/TH-05-sales-orders/harness/01-domain-model.md`, bảng query (dòng có `` `GetSalesReceiptQuery` | receipt DTO | receipt ``), thêm dòng ngay sau:

```markdown
| `GetSalesOrderOriginalReceiptQuery` | receipt document (as-sold, read-only) | tab «Đơn gốc»: dòng đơn gốc + tổng lúc bán + khoản thu checkout; không lưu, không activity |
```

- [ ] **Step 7: Chạy test**

Run: `cd modules/sales/infrastructure && dart test test/domain/sales_receipt/ test/domain/schema/`
Expected: 3 test mới PASS; các fail còn lại trùng baseline (các test đọc file `_drafts` không tồn tại, `sales_remove_unused_policy_tables` 4 test). `sales_rpc_surface_parity_test.dart` có thể fail «RPC không khai báo trong surface» cho tới Task 2 Step 9 — ghi nhận, không sửa ở task này.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql supabase/migrations/REGISTRY.yaml docs/themes/TH-05-sales-orders/harness/01-domain-model.md modules/sales/infrastructure/test/domain/sales_receipt/sales_receipt_original_sql_contract_test.dart
git commit -m "feat(sales): RPC phiếu bán hàng đơn gốc (chỉ đọc)"
```

(User tự commit.)

---

### Task 2: Module sales — `GetSalesOrderOriginalReceiptQuery`

**Files:**
- Create: `modules/sales/application/lib/src/sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart`
- Create: `modules/sales/application/lib/src/sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query_handler.dart`
- Modify: `modules/sales/application/lib/src/sales_receipt/ports/i_sales_receipt_gateway.dart`
- Modify: `modules/sales/application/lib/src/testing/fake_sales_receipt_gateway.dart`
- Modify: `modules/sales/application/lib/application.dart`
- Modify: `modules/sales/infrastructure/lib/src/domain/sales_receipt/sales_receipt_rpc_mapper.dart`
- Modify: `modules/sales/infrastructure/lib/src/domain/sales_receipt/supabase_sales_receipt_gateway.dart`
- Regenerate: `modules/sales/infrastructure/lib/src/configuration/processing/generated/*.g.dart`
- Test: `modules/sales/application/test/sales_receipt/group_e_sales_receipt_test.dart`
- Test: `modules/sales/infrastructure/test/domain/sales_receipt/supabase_sales_receipt_gateway_test.dart`
- Test: `modules/sales/infrastructure/test/domain/schema/sales_rpc_surface_parity_test.dart`

**Interfaces:**
- Consumes: RPC `get_sales_order_original_receipt` (Task 1).
- Produces:
  - `final class GetSalesOrderOriginalReceiptQuery extends SalesReadContract<SalesReceiptDocumentDto>` với `required String salesOrderId`.
  - `GetSalesOrderOriginalReceiptQueryHandler({required IPermissionChecker permissionChecker, required ISalesReceiptGateway receiptGateway})`.
  - `ISalesReceiptGateway.getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query) → Future<SalesReceiptDocumentDto>`.
  - `SalesReceiptRpcMapper.originalReceiptParams(query)`, `SalesReceiptRpcMapper.documentFromJson(Map<String, dynamic>)`.
  - `FakeSalesReceiptGateway.getOriginalCalls` (int), tham số `originalError`.

- [ ] **Step 1: Chạy impact**

```bash
node .gitnexus/run.cjs impact "ISalesReceiptGateway" --direction upstream --repo .
node .gitnexus/run.cjs impact "SupabaseSalesReceiptGateway" --direction upstream --repo .
node .gitnexus/run.cjs impact "SalesReceiptRpcMapper" --direction upstream --repo .
```

- [ ] **Step 2: Viết test fail (application)**

Trong `modules/sales/application/test/sales_receipt/group_e_sales_receipt_test.dart`, thêm vào `group('TH-05 Group E S14 sales receipt', …)`:

```dart
    test('original receipt query returns the as-sold document', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesOrderOriginalReceiptQueryHandler(
        permissionChecker: _AllowAllPermissionChecker(),
        receiptGateway: gateway,
      );

      final document = await handler.handle(
        GetSalesOrderOriginalReceiptQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(document.receiptNumber, 'PBH-20260812-0129');
      expect(gateway.getOriginalCalls, 1);
      expect(gateway.generateCalls, 0);
    });

    test('original receipt query enforces receipt view permission', () async {
      final gateway = FakeSalesReceiptGateway(receipt: _receipt);
      final handler = GetSalesOrderOriginalReceiptQueryHandler(
        permissionChecker: _DenyPermissionChecker(),
        receiptGateway: gateway,
      );

      await expectLater(
        handler.handle(
          GetSalesOrderOriginalReceiptQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(gateway.getOriginalCalls, 0);
    });
```

- [ ] **Step 3: Viết test fail (infrastructure)**

Trong `supabase_sales_receipt_gateway_test.dart`, thêm vào `group('SupabaseSalesReceiptGateway', …)`:

```dart
    test('original receipt maps the as-sold document without receipt envelope', () async {
      final rpc = _FakeRpcClient(
        response: Map<String, dynamic>.from(_receiptJson()['document'] as Map),
      );
      final gateway = SupabaseSalesReceiptGateway(rpcClient: rpc);

      final document = await gateway.getOriginalReceipt(
        GetSalesOrderOriginalReceiptQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_sales_order_original_receipt');
      expect(rpc.lastParams?['p_query_id'], isA<String>());
      expect(rpc.lastParams?['p_tenant_id'], 'tenant-1');
      expect(rpc.lastParams?['p_actor_id'], 'actor-1');
      expect(rpc.lastParams?['p_sales_order_id'], 'order-1');
      expect(document.lines, hasLength(1));
      expect(document.settlementSnapshot, isNull);
    });
```

- [ ] **Step 4: Chạy test, xác nhận fail**

```bash
cd modules/sales/application && dart test test/sales_receipt/group_e_sales_receipt_test.dart
cd ../infrastructure && dart test test/domain/sales_receipt/supabase_sales_receipt_gateway_test.dart
```

Expected: FAIL — compile error `GetSalesOrderOriginalReceiptQuery` chưa tồn tại.

- [ ] **Step 5: Query + handler**

`get_sales_order_original_receipt_query.dart`:

```dart
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_base.dart';
import '../../../shared/sales_receipt_document_dto.dart';

/// As-sold receipt document for the «Đơn gốc» tab: original order lines, sale
/// totals and checkout payments. Computed on read, never persisted.
@RequiresPermission(SalesPermissions.viewReceipt)
@RequiresTenant()
final class GetSalesOrderOriginalReceiptQuery extends SalesReadContract<SalesReceiptDocumentDto> {
  GetSalesOrderOriginalReceiptQuery({
    super.id,
    super.tenantId,
    super.actorId,
    required this.salesOrderId,
  });

  final String salesOrderId;

  GetSalesOrderOriginalReceiptQuery withExecutionContext({
    required String tenantId,
    String actorId = '',
  }) => GetSalesOrderOriginalReceiptQuery(
    id: id,
    tenantId: tenantId,
    actorId: actorId,
    salesOrderId: salesOrderId,
  );
}
```

`get_sales_order_original_receipt_query_handler.dart`:

```dart
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_document_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'get_sales_order_original_receipt_query.dart';

@QueryHandlerFor(GetSalesOrderOriginalReceiptQuery)
final class GetSalesOrderOriginalReceiptQueryHandler
    implements IQueryHandler<GetSalesOrderOriginalReceiptQuery, SalesReceiptDocumentDto> {
  GetSalesOrderOriginalReceiptQueryHandler({
    required IPermissionChecker permissionChecker,
    required ISalesReceiptGateway receiptGateway,
  }) : _permissionChecker = permissionChecker,
       _receiptGateway = receiptGateway;

  final IPermissionChecker _permissionChecker;
  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDocumentDto> handle(GetSalesOrderOriginalReceiptQuery query) async {
    // QueryBus does not apply the authorization pipeline; enforce explicitly.
    await _permissionChecker.require(SalesPermissions.viewReceipt);
    return _receiptGateway.getOriginalReceipt(query);
  }
}
```

- [ ] **Step 6: Port + fake + exports**

`i_sales_receipt_gateway.dart`: thêm import

```dart
import '../../shared/sales_receipt_document_dto.dart';
import '../queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart';
```

và method cuối interface:

```dart
  Future<SalesReceiptDocumentDto> getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query);
```

`fake_sales_receipt_gateway.dart`: thêm 2 import tương ứng (`../sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart`, `../shared/sales_receipt_document_dto.dart`); constructor thêm `this.originalError,`; field `final Object? originalError;`, `int getOriginalCalls = 0;`; method:

```dart
  @override
  Future<SalesReceiptDocumentDto> getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query) async {
    getOriginalCalls += 1;
    if (originalError != null) throw originalError!;
    return _receipt.document;
  }
```

`application.dart`: sau dòng `export 'src/sales_receipt/queries/get_sales_receipt/get_sales_receipt_query_handler.dart';` thêm:

```dart
export 'src/sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart';
export 'src/sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query_handler.dart';
```

- [ ] **Step 7: Mapper**

Trong `SalesReceiptRpcMapper`, sau `getReceiptParams(...)` thêm:

```dart
  static Map<String, dynamic> originalReceiptParams(GetSalesOrderOriginalReceiptQuery query) {
    return <String, dynamic>{
      'p_query_id': query.id,
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_sales_order_id': query.salesOrderId,
    };
  }

  /// The as-sold receipt RPC returns the document directly (no envelope).
  static SalesReceiptDocumentDto documentFromJson(Map<String, dynamic> json) => _document(json);
```

- [ ] **Step 8: Supabase gateway**

Trong `SupabaseSalesReceiptGateway`, thêm method (sau `getReceipt`) và tách `_call` thành generic `_invoke`:

```dart
  @override
  Future<SalesReceiptDocumentDto> getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query) {
    return _invoke(
      'get_sales_order_original_receipt',
      SalesReceiptRpcMapper.originalReceiptParams(query),
      SalesReceiptRpcMapper.documentFromJson,
    );
  }

  Future<SalesReceiptDto> _call(String procedure, Map<String, dynamic> params) =>
      _invoke(procedure, params, SalesReceiptRpcMapper.salesReceiptFromJson);

  Future<T> _invoke<T>(
    String procedure,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic> json) map,
  ) async {
    try {
      final json = await _rpcClient.call(procedure, params: params);
      return map(json);
    } on RpcException catch (error) {
      throw _mapSalesRpcError(error);
    } on SalesContractException {
      rethrow;
    } on FormatException {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales receipt operation failed.',
      );
    } on Object {
      throw const SalesContractException(
        'DEPENDENCY_UNAVAILABLE',
        message: 'Sales receipt operation failed.',
      );
    }
  }
```

(Xoá thân `_call` cũ — logic try/catch chuyển nguyên sang `_invoke`.)

- [ ] **Step 9: RPC surface parity**

Trong `sales_rpc_surface_parity_test.dart`, map `_gatewaySurface`, thêm ngay sau entry `'get_sales_receipt'`:

```dart
  'get_sales_order_original_receipt': (
    owner: '010_sales_inquiry_receipt_rpcs.sql',
    mapperKeys: {
      'p_query_id',
      'p_tenant_id',
      'p_actor_id',
      'p_sales_order_id',
    },
  ),
```

- [ ] **Step 10: Sinh lại registrar**

```bash
cd modules/sales/infrastructure
dart run build_runner build --delete-conflicting-outputs
grep -n "GetSalesOrderOriginalReceiptQueryHandler" lib/src/configuration/processing/generated/sales_cqrs_registrar.g.dart
```

Expected: có dòng `registerQueryHandler<GetSalesOrderOriginalReceiptQuery, SalesReceiptDocumentDto, GetSalesOrderOriginalReceiptQueryHandler>`. Xem `git diff --stat lib/src/configuration/processing/generated/` — chỉ các file generated liên quan thay đổi.

- [ ] **Step 11: Chạy test + analyze**

```bash
cd modules/sales/application && dart test test/sales_receipt/ && dart analyze lib test/sales_receipt
cd ../infrastructure && dart test test/domain/sales_receipt/ test/domain/schema/sales_rpc_surface_parity_test.dart && dart analyze lib test/domain/sales_receipt
```

Expected: test mới + parity PASS (trừ fail có sẵn của `sales_receipt_group_e_sql_contract_test.dart` đọc `_drafts`); analyze sạch.

- [ ] **Step 12: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add modules/sales/application modules/sales/infrastructure
git commit -m "feat(sales): query phiếu bán hàng đơn gốc"
```

(User tự commit; `git add` theo đúng file đã sửa nếu working tree còn thay đổi khác.)

---

### Task 3: App — tab «Đơn gốc» mở phiếu đơn gốc

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_receipt_preview_page.dart`
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_order_slip_preview_page.dart`
- Modify: `apps/erp/lib/features/sales/presentation/bloc/sales_order/sales_order_detail_cubit.dart`
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_order_detail_page.dart`
- Test: `apps/erp/test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart`
- Test: `apps/erp/test/features/sales/sales_order_slip_preview_page_test.dart` (chạy lại, không cần sửa)

**Interfaces:**
- Consumes: `GetSalesOrderOriginalReceiptQuery` (Task 2).
- Produces: `SalesOrderDetailCubit.viewOriginalReceipt() → Future<SalesReceiptDocumentDto>`; `SalesReceiptPreviewPage({required SalesReceiptDocumentDto document, required onPrint, required onShare})`.

- [ ] **Step 1: Chạy impact**

```bash
node .gitnexus/run.cjs impact "SalesReceiptPreviewPage" --direction upstream --repo .
node .gitnexus/run.cjs impact "SalesOrderDetailCubit" --direction upstream --repo .
node .gitnexus/run.cjs impact "SalesOrderDetailPage" --direction upstream --repo .
```

- [ ] **Step 2: Viết test fail (cubit)**

Trong `sales_order_detail_cubit_test.dart`:

(a) `_RecordingSalesModule.executeQueryAsync`: ngay trước `if (query is app.GetSalesReceiptQuery) {` thêm:

```dart
    if (query is app.GetSalesOrderOriginalReceiptQuery) {
      return _receipt().document as TResult;
    }
```

(b) Trong `group('SalesOrderDetailCubit S19 receipt', …)` thêm:

```dart
    test('viewOriginalReceipt reads the as-sold receipt without the stored receipt flow', () async {
      final module = _RecordingSalesModule();
      final cubit = _buildCubit(module: module);
      addTearDown(cubit.close);
      await cubit.load();
      await _drain();

      final document = await cubit.viewOriginalReceipt();

      final query = module.queries.whereType<app.GetSalesOrderOriginalReceiptQuery>().single;
      expect(query.salesOrderId, 'order-1');
      expect(query.tenantId, 'tenant-1');
      expect(query.actorId, 'actor-1');
      expect(document.receiptNumber, _receipt().document.receiptNumber);
      expect(module.queries.whereType<app.GetSalesReceiptQuery>(), isEmpty);
      expect(module.commands, isEmpty);
    });
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart`
Expected: FAIL — `viewOriginalReceipt` chưa tồn tại.

- [ ] **Step 4: Cubit**

Trong `SalesOrderDetailCubit`, ngay sau `viewReceipt()`:

```dart
  /// As-sold receipt for the «Đơn gốc» tab. Read-only: it has no receipt id,
  /// so print/share of it records no receipt activity.
  Future<SalesReceiptDocumentDto> viewOriginalReceipt() async {
    final tenantId = await executionContext.requireTenantId();
    final actorId = await executionContext.requireUserId();
    return salesModule.executeQueryAsync<SalesReceiptDocumentDto>(
      GetSalesOrderOriginalReceiptQuery(
        tenantId: tenantId,
        actorId: actorId,
        salesOrderId: orderId,
      ),
    );
  }
```

- [ ] **Step 5: Trang xem trước nhận document**

`sales_receipt_preview_page.dart`: đổi

```dart
    required this.receipt,
```
→
```dart
    required this.document,
```
```dart
  final SalesReceiptDto receipt;
```
→
```dart
  final SalesReceiptDocumentDto document;
```
và xoá dòng `final document = receipt.document;` trong `build`.

`sales_order_slip_preview_page.dart`: trong `return SalesReceiptPreviewPage(`, đổi `receipt: resolvedReceipt,` → `document: resolvedReceipt.document,`.

- [ ] **Step 6: Trang chi tiết đơn — rẽ nhánh theo tab**

Trong `_SalesOrderDetailPageState._openReceipt()`, ngay sau dòng `if (!mounted || sheetAction == null) return;` thêm:

```dart
    final returns = _cubit.state.history?.returns ?? const [];
    if (returns.isNotEmpty && _selectedTabIndex == 0) {
      await _openOriginalReceipt(sheetAction);
      return;
    }
```

Thêm các method (sau `_openReceipt`):

```dart
  /// «Đơn gốc» tab: as-sold receipt computed on read. Print/share run on the
  /// device only — there is no stored receipt to record activity against.
  Future<void> _openOriginalReceipt(SalesResultReceiptAction action) async {
    try {
      final document = await _cubit.viewOriginalReceipt();
      if (!mounted) return;
      switch (action) {
        case SalesResultReceiptAction.view:
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SalesReceiptPreviewPage(
                document: document,
                onPrint: _printReceiptDocument,
                onShare: _shareReceiptDocument,
              ),
            ),
          );
        case SalesResultReceiptAction.print:
          await _printReceiptDocument(document);
        case SalesResultReceiptAction.share:
          await _shareReceiptDocument(document);
      }
    } catch (error) {
      if (!mounted) return;
      VToast.show(
        context,
        title: 'Thao tác phiếu thất bại',
        message: _receiptIssueMessage(SalesTransactionResultMapper.issueFor(error)),
        type: VToastType.danger,
      );
    }
  }

  Future<void> _printReceiptDocument(SalesReceiptDocumentDto document) async {
    final bytes = await SalesReceiptPdfGenerator.generate(document);
    if (!mounted) return;
    await SalesPdfRunner.print(
      context: context,
      bytes: bytes,
      name: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
    );
  }

  Future<void> _shareReceiptDocument(SalesReceiptDocumentDto document) async {
    final bytes = await SalesReceiptPdfGenerator.generate(document);
    if (!mounted) return;
    await SalesPdfRunner.share(
      context: context,
      bytes: bytes,
      filename: SalesReceiptPdfGenerator.sanitizeFileName(document.receiptNumber),
    );
  }
```

(Import đã có qua `package:erp/features/sales/presentation.dart` và `package:vet45_sales_application/application.dart`.)

- [ ] **Step 7: Chạy test + analyze**

```bash
cd apps/erp
flutter test test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart test/features/sales/sales_order_slip_preview_page_test.dart test/features/sales/sales_order_detail_page_test.dart
flutter test test/features/sales/
flutter analyze lib/features/sales/presentation/pages/sales_receipt_preview_page.dart lib/features/sales/presentation/pages/sales_order_slip_preview_page.dart lib/features/sales/presentation/pages/sales_order_detail_page.dart lib/features/sales/presentation/bloc/sales_order/sales_order_detail_cubit.dart test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart
```

Expected: PASS toàn bộ; analyze «No issues found!». Nếu test khác fail, so baseline bằng `git stash` để xác nhận không do task này.

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add apps/erp/lib/features/sales/presentation/pages/sales_receipt_preview_page.dart apps/erp/lib/features/sales/presentation/pages/sales_order_slip_preview_page.dart apps/erp/lib/features/sales/presentation/pages/sales_order_detail_page.dart apps/erp/lib/features/sales/presentation/bloc/sales_order/sales_order_detail_cubit.dart apps/erp/test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart
git commit -m "feat(sales): tab Đơn gốc mở phiếu bán hàng như lúc bán"
```

(User tự commit.)

---

### Task 4: SQL chạy tay + kiểm tra trên DB thật (user)

**Files:**
- Output (không commit): `$SCRATCH/original_receipt_manual.sql`

- [ ] **Step 1: Xuất file SQL chạy tay**

```bash
F=supabase/migrations/20260830010_sales_inquiry_receipt_rpcs.sql
O="$SCRATCH/original_receipt_manual.sql"
block() { s=$(grep -n "^create or replace function $1(" "$F" | tail -1 | cut -d: -f1); e=$(awk -v s="$s" 'NR>s && /^\$\$;/ {print NR; exit}' "$F"); sed -n "${s},${e}p" "$F"; }
{
  echo "-- Chạy tay trên SQL editor: phiếu bán hàng đơn gốc (chỉ đọc)."
  echo "begin;"; echo
  block sales.get_sales_order_original_receipt; echo
  grep "sales.get_sales_order_original_receipt(uuid, uuid, uuid, uuid)" "$F"; echo
  echo "commit;"
} > "$O"
grep -c "get_sales_order_original_receipt" "$O"
```

Expected: ≥ 3 (hàm + revoke + grant). Đọc lại file, gửi cho user (SendUserFile).

- [ ] **Step 2: User chạy file trên SQL editor**

Expected: `COMMIT`, không lỗi.

- [ ] **Step 3: User kiểm tra trên app (đơn DH202609240002)**

Thoát hẳn chi tiết đơn → vào lại → tab **«Đơn gốc»** → Phiếu bán hàng → Xem:

| Tab | Kỳ vọng |
|---|---|
| Đơn gốc | 4 thùng × 50.000đ · Tiền hàng 200.000đ · **Tổng đơn 200.000đ** · Tiền mặt 200.000đ · Còn phải thu 0đ · **không** có dòng Chuyển khoản / Điều chỉnh sau bán |
| Sau đổi/trả | Như hiện tại: 3 thùng + 5 thùng · Tổng đơn 400.000đ · Tiền mặt 200.000đ · Chuyển khoản 200.000đ |
| Đơn chưa đổi/trả (không có tab) | Như hiện tại |

In / Chia sẻ ở tab «Đơn gốc» mở hộp thoại in/chia sẻ của máy bình thường.

- [ ] **Step 4: User kiểm tra DB không bị ghi**

```sql
select count(*) from sales.sales_receipts r
join sales.sales_orders o on o.id = r.sales_order_id
where o.order_code = 'DH202609240002';
```

Expected: số phiếu **không tăng** sau khi mở/in/chia sẻ phiếu tab «Đơn gốc».

- [ ] **Step 5: Tóm tắt kết quả cho user**
