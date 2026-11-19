# T6-2b — Flutter công nợ phải thu: CN-01, CN-02, CN-03 Implementation Plan

> Phase: Theme 6 · Trạng thái: Plan ✅ (duyệt 2026-11-19) | Làm ✅ | Review ✅ R3
> Tài liệu liên quan: PLAN mục Theme 6 (T6-2b), [TH-06](../../../02-yeu-cau/TH-06-cong-no.md) 4.2–4.3, 5.1–5.4, 5.6, 6.1–6.3, 9.3; [T6-1b](T6-1b-cong-no-thu-theo-khach-can-tru.md); [T6-2a prototype](T6-2a-prototype.md)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. (Dự án này: **người dùng tự code**, Claude review ở phiên khác.)

**Goal:** Người dùng mở "Công nợ phải thu" từ menu Thêm, thấy khách còn nợ (quá hạn dẫn đầu), mở công nợ một khách, thu tiền theo khách vào các đơn đã tick (chia cũ trước) — trên iPhone và web, nối RPC thật của T6-1b.

**Architecture:** Feature mới `apps/erp/lib/features/receivable/{data,logic,presentation}` theo khuôn `partner`: `ReceivableRepository` (qua `SupabaseRpc`, schema `receivable`) → 3 cubit → 3 màn. Web hai cột bằng `VListDetailLayout` trong `ReceivableAreaShell` (chép khuôn `PartnerAreaShell`), route `/more/receivables[/:customerId]`. Một migration nhỏ thêm `actorDisplayName` vào lịch sử. Bố cục, chữ, điều kiện hiện/ẩn lấy **nguyên** từ code prototype T6-2a chép trong từng task; so bằng golden 390 / 1280.

**Tech Stack:** Flutter (flutter_bloc, go_router, get_it), `c45_design_system`, PostgreSQL plpgsql (Supabase local).

**Spec:** TH-06 v1.0 + prototype đã chốt `specs/themes/theme-06/03.design/prototype/html/` (README) + thiết kế duyệt trong chat 2026-11-19 (hướng A: T6-2b feature mới, T6-2c sửa màn cũ).

## Global Constraints

- **Phạm vi T6-2b:** CN-01, CN-02, CN-03, route, mục menu Thêm, migration tên người. **Không** sửa SG-09 / 09b / 09c / 13 / 14, PT-07, sheet thu một đơn `sales_record_payment_sheet` (T6-2c). Chạm đơn ở CN-02 chỉ mở SG-09 hiện có.
- Lệnh DB (`supabase db reset`, `psql`, `tools/db_check.sh`) **người dùng tự chạy local**. Không sửa migration cũ.
- Tiền hiển thị theo prototype: `18.000.000 ₫` (có khoảng trắng + `₫`, TH-06 5.6), **không** dùng `MoneyFormatter.formatMinor` (ra `18.000.000đ`). Số "trần" (lịch sử, khối chia, dòng đơn CN-03) = `MoneyFormatter.formatMinorPlain`. Ô nhập có hậu tố `đ` (prototype `rw-amount__unit`). Mọi số: `FontFeature.tabularFigures()`.
- Nhãn hạn (BR-30): `Quá hạn N ngày` (đỏ + icon cảnh báo), `Đến hạn hôm nay`, `Hẹn dd/MM`, `Không có hẹn`. **Số ngày quá hạn lấy từ server** (`overdueDays`, `maxOverdueDays`, BR-31); app chỉ so `dueDate` với ngày hôm nay của máy để tách "hôm nay" / "hẹn".
- Vùng chạm ≥ 44 (`VSpacing.minTouchTarget`): dòng khách, dòng đơn, ô tick, nút xoá tìm.
- Chữ trên màn **đúng nguyên văn code prototype** chép trong task (gồm "Chữ tạm" README prototype — coi như đã chốt cùng ảnh 2026-11-18).
- Màu / khoảng / bo góc dùng token Dart (`context.vColors.*`, `VSpacing.*`, `VRadius.*`, `VTypography.*`); Dart là nguồn — nền nhạt CSS lệch nhẹ Dart (`primary-50` #F1F9F2 ↔ `surfaceBrand` #EBF4EE, `danger-50` #FBE8E8 ↔ `dangerBg` #F8ECEC) thì **lấy Dart**, không gõ mã màu.
- Mã phương thức gửi RPC: `cash`, `manualBankTransfer` (không `offset`).
- Quyền: route kiểm `receivable.view`; nút "Thu tiền" kiểm `receivable.collect` (qua `SessionController.hasPermission`).
- Ảnh đích: `docs/refactor/plans/T6/img/T6-2b/proto-CN-0x-<state>-390|1280.png` (đã chép 62 ảnh). Golden Flutter ghi cạnh đó tên `flutter-CN-0x-<state>-390|1280.png`.
- CLAUDE.md: trước khi sửa symbol có sẵn (`kMoreEntries`, `buildAppRouter`/danh sách route, `configureDependencies`) chạy GitNexus `impact` và ghi kết quả vào Kết quả; trước commit cuối chạy `detect_changes()`.

## Quyết định (chốt trong chat 2026-11-19 + quyết định của Claude, bạn sửa nếu sai)

1. Hướng A: T6-2b chỉ feature `receivable`; T6-2c sửa màn cũ + `/impeccable audit` + kịch bản 9.1. *(bạn chốt)*
2. Thêm `actorDisplayName` vào `list_customer_receivable_history` (migration mới) để CN-02 hiện "06/11 14:20 · Nguyễn An". *(bạn duyệt)*
3. Định dạng tiền `… ₫` theo prototype + TH-06 5.6, khác phần còn lại của app (`…đ`). *(Claude)*
4. Lỗi tải chi tiết khách (khối đầu + đơn) = cả trang "Không tải được công nợ" + `Thử lại` (chữ CN-01); lỗi lịch sử = khối lỗi riêng (FR-06). *(Claude — prototype chỉ vẽ lỗi khối lịch sử)*
5. CN-03: mở ra **chưa tick đơn nào**, ô tiền trống (ca `empty`); tick / bỏ tick → số tiền = Σ còn nợ các đơn đang tick (TH-06 9.3); gõ tay số nhỏ hơn thì chia cũ trước trong đơn đã tick. *(prototype)*
6. Lỗi ghi CN-03: `RECEIVABLE_CHANGED` → hộp "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại." + `Tải lại` (đóng sheet, tải lại CN-02); lỗi khác → dòng đỏ trong sheet: thông điệp 6.3 nếu có mã, không thì "Không ghi nhận được. Thử lại?" + `Thử lại` (giữ khoá chống trùng). *(Claude)*
7. "Đang hiển thị n / N khách" (prototype `rv-showing`) chỉ hiện khi lọc Quá hạn **và** ô tìm trống (n = `overdueCustomerCount`, N = `customerCount`); khi tìm thì ẩn (server phân trang, không biết tổng sau tìm). *(Claude)*
8. `get_customer_receivable_summary` (PT-07) để T6-2c. *(Claude)*

## Review Focus

1. **Thử lại sau lỗi mạng giữ cùng khoá** — `submit()` lần 2 sau lỗi gửi cùng `p_idempotency_key`; đổi số / tick / phương thức / mã giao dịch thì khoá mới. Test: Task 5 `retry keeps idempotency key`, `edit after error makes new key`.
2. **Tick / bỏ tick làm sai số tiền đã gõ** — gõ 5.000.000 rồi tick thêm đơn → số tiền thành Σ đơn đang tick (ghi đè số gõ tay, đúng 9.3); bỏ tick hết → số 0, nút khoá, hiện "Chọn ít nhất một đơn để thu.". Test: Task 5 `toggle resets amount to scope total`, `untick all locks submit`.
3. **Số rất lớn / tên dài trên 390** — 1.234.567.890 ₫ và tên công ty dài: tên cắt `…`, tiền không xuống hàng, nhãn hạn không đẩy tiền (ảnh `proto-CN-01-long-390`). Test: Task 3 golden `long` 390 + không `FlutterError` tràn.
4. **Tìm gõ nhanh** — gõ "t", "tu", "tuan" trong < 300 ms chỉ gọi RPC **một** lần với `p_search: 'tuan'`; kết quả trả về muộn của lần gọi cũ không đè kết quả mới. Test: Task 3 `debounces search` và `drops stale response`.
5. **Hết nợ sau khi thu** — thu "Tất cả đơn · trả hết": CN-02 thành "Không còn nợ", ẩn nút "Thu tiền", "Không còn đơn nào nợ"; CN-01 (cột trái web) không còn khách đó. Test: Task 5 widget `pay all then paid-off`.

---

## File Structure

| File | Hành động | Trách nhiệm |
|---|---|---|
| `supabase/migrations/20261125001_receivable_history_actor_name.sql` | tạo | Task 1: `create or replace` `list_customer_receivable_history` thêm `actorDisplayName` |
| `supabase/tests/receivable_th06.sql` | sửa | Task 1: ca A14 |
| `supabase/migrations/REGISTRY.yaml` | sinh lại | Task 1 |
| `apps/erp/lib/features/receivable/data/receivable_models.dart` | tạo | DTO + enum (Task 2) |
| `apps/erp/lib/features/receivable/data/receivable_repository.dart` | tạo | 4 RPC (Task 2) |
| `apps/erp/lib/features/receivable/logic/receivable_format.dart` | tạo | `formatVnd`, `formatVndBare`, nhãn hạn (Task 2) |
| `apps/erp/lib/features/receivable/logic/receivable_allocation.dart` | tạo | `allocateOldestFirst`, `collectionPreview` (Task 2) |
| `apps/erp/lib/features/receivable/logic/receivable_error_messages.dart` | tạo | bảng 6.3 (Task 2) |
| `apps/erp/lib/features/receivable/logic/receivable_list_cubit.dart` (+ `_state`) | tạo | CN-01 (Task 3) |
| `apps/erp/lib/features/receivable/logic/customer_receivable_cubit.dart` (+ `_state`) | tạo | CN-02 (Task 4) |
| `apps/erp/lib/features/receivable/logic/customer_collection_cubit.dart` (+ `_state`) | tạo | CN-03 (Task 5) |
| `apps/erp/lib/features/receivable/presentation/widgets/receivable_parts.dart` | tạo | phần dùng chung = `ui.js` (Task 3) |
| `apps/erp/lib/features/receivable/presentation/pages/receivable_list_page.dart` | tạo | CN-01 (Task 3) |
| `apps/erp/lib/features/receivable/presentation/receivable_area_shell.dart`, `receivable_routes.dart` | tạo | shell + route (Task 3) |
| `apps/erp/lib/features/receivable/presentation/pages/customer_receivable_page.dart` | tạo | CN-02 (Task 4) |
| `apps/erp/lib/features/receivable/presentation/widgets/customer_collection_sheet.dart` | tạo | CN-03 (Task 5) |
| `apps/erp/lib/core/di/injection.dart` | sửa | đăng ký `ReceivableRepository` (Task 2) |
| `apps/erp/lib/core/router/app_router.dart` | sửa | `...receivableRoutes(hasPermission: _hasTenantPermission)` (Task 3) |
| `apps/erp/lib/features/more/presentation/more_entries.dart` | sửa | mục "Công nợ phải thu" (Task 3) |
| `apps/erp/test/features/receivable/**` | tạo | test từng task; `support/receivable_fixtures.dart` (dữ liệu ví dụ 2.3), `support/fake_receivable_repository.dart` |
| `docs/02-yeu-cau/TH-06-cong-no.md`, `docs/refactor/PLAN.md` | sửa | Task 6 |

---

### Task 1: DB — tên người trong lịch sử công nợ

**Files:**
- Create: `supabase/migrations/20261125001_receivable_history_actor_name.sql`
- Modify: `supabase/tests/receivable_th06.sql` (thêm ca A14 vào phần A), `supabase/migrations/REGISTRY.yaml` (sinh lại)

**Interfaces:**
- Consumes: `receivable.list_customer_receivable_history(uuid, uuid, uuid, text, int)` (`20261124001` dòng 562–687), `iam._member_display_name(p_user_id uuid) returns text` (`20261105001`).
- Produces: mỗi phần tử `items[]` có thêm khoá `actorDisplayName text|null` (= `iam._member_display_name(h.actor_id)`, `null` khi `actor_id` null). Chữ ký, quyền, cursor **không đổi**.

- [ ] **Bước 1: Test đỏ A14** trong `receivable_th06.sql` (sau A13): dùng dữ liệu A có sẵn, sau lần thu theo khách của Anh Tuấn gọi `list_customer_receivable_history`; `raise exception 'FAIL: A14 …'` nếu dòng `kind = 'customer_collection'` đầu tiên không có khoá `actorDisplayName` hoặc giá trị khác `iam._member_display_name(<actor test>)`.
- [ ] **Bước 2: Người dùng chạy** `psql "$DB_URL" -f supabase/tests/receivable_th06.sql` → `FAIL: A14`.
- [ ] **Bước 3: Viết migration** theo `_migration.template.sql` (`Kind: patch`, `Touches: list_customer_receivable_history`, `Depends on: 20261124002_receivable_return_offsets`): `create or replace function` chép nguyên thân `20261124001:562–687`, chỉ thêm một dòng `'actorDisplayName', iam._member_display_name(h.actor_id),` ngay sau `'actorId', h.actor_id,`. Giữ `revoke` / `grant` như cũ.
- [ ] **Bước 4: Người dùng chạy** `supabase db reset` rồi test A + B → `receivable_th06: OK`. Sinh lại `REGISTRY.yaml` theo cách T6-1b Task 3.
- [ ] **Bước 5: Sửa TH-06 6.2** bảng "Khoá JSON thật": thêm `actorDisplayName` sau `actorId`.
- [ ] **Bước 6: Commit** `feat(receivable): T6-2b lịch sử công nợ trả tên người` (chỉ `git add` 4 file trên).

---

### Task 2: Dữ liệu, định dạng, chia tiền (không UI)

**Files:**
- Create: `lib/features/receivable/data/receivable_models.dart`, `data/receivable_repository.dart`, `logic/receivable_format.dart`, `logic/receivable_allocation.dart`, `logic/receivable_error_messages.dart`
- Modify: `lib/core/di/injection.dart` (cạnh `PartnerRepository`, dòng ~126)
- Test: `test/features/receivable/data/receivable_repository_test.dart`, `test/features/receivable/logic/receivable_format_test.dart`, `test/features/receivable/logic/receivable_allocation_test.dart`, `test/features/receivable/support/receivable_fixtures.dart`

(Đường dẫn `lib/…`, `test/…` tính từ `apps/erp/`.)

**Interfaces — Produces** (mọi task sau dùng đúng tên này):

```dart
// receivable_models.dart — tất cả final + const ctor + Equatable; fromJson theo khoá JSON TH-06 6.2
enum ReceivableFilter { all, overdue }            // wire = name
enum ReceivableHistoryKind { customerCollection, orderCollection, offset, refund } // wire: customer_collection / order_collection / offset / refund
enum CollectionMethod { cash, manualBankTransfer } // wire = name
class ReceivableSummary { int totalOutstandingMinor, customerCount, overdueCustomerCount, overdueAmountMinor, maxOverdueDays; }
class CustomerReceivableRow { String customerId, displayName; String? phone; bool isActive; int outstandingMinor, openOrderCount, overdueOrderCount, overdueAmountMinor, maxOverdueDays; DateTime? nextDueDate; }
class CustomerReceivablePage { ReceivableSummary summary; List<CustomerReceivableRow> items; String? nextCursor; }
class ReceivableCustomer { String customerId, displayName; String? phone; bool isActive; }
class OpenReceivableOrder { String salesOrderId, orderCode; DateTime completedAt; int payableMinor, outstandingMinor; DateTime? dueDate; int overdueDays; int settlementVersion; }
class CustomerReceivableDetail { ReceivableCustomer customer; int outstandingMinor, openOrderCount, overdueOrderCount, maxOverdueDays; List<OpenReceivableOrder> openOrders; } // openOrders cũ trước (server xếp)
class HistoryAllocation { String orderCode; int amountMinor; }
class ReceivableHistoryItem { ReceivableHistoryKind kind; DateTime occurredAt; int amountMinor; String? paymentMethodCode, externalReference, actorDisplayName, orderCode, sourceOrderCode, targetOrderCode, returnExchangeReference; List<HistoryAllocation> allocations; }
class ReceivableHistoryPage { List<ReceivableHistoryItem> items; String? nextCursor; }
class CustomerCollectionRequest { String customerId; int amountMinor; CollectionMethod method; String? externalReference; List<String> orderIds; int expectedOutstandingMinor; String idempotencyKey; }
class CustomerCollectionResult { String collectionId; int outstandingAfterMinor; }

// receivable_repository.dart — ctor như PartnerRepository: ({required SupabaseRpc rpc, required Future<String> Function() tenantId, required Future<String> Function() actorId})
Future<CustomerReceivablePage> list({ReceivableFilter filter = ReceivableFilter.all, String? search, String? cursor});
Future<CustomerReceivableDetail> getCustomer(String customerId);
Future<ReceivableHistoryPage> history(String customerId, {String? cursor});
Future<CustomerCollectionResult> recordCollection(CustomerCollectionRequest request);

// receivable_format.dart
String formatVnd(int minor);      // "18.000.000 ₫" (= MoneyFormatter.formatMinorPlain + ' ₫')
String formatVndBare(int minor);  // "18.000.000"
enum DueKind { overdue, today, upcoming, none }
class DueLabel { DueKind kind; int? days; String text; }
DueLabel orderDueLabel({required DateTime? dueDate, required int overdueDays, required DateTime today});
DueLabel customerDueLabel({required int maxOverdueDays, required DateTime? nextDueDate, required DateTime today});

// receivable_allocation.dart
class CollectionAllocation { String salesOrderId; int allocatedMinor, outstandingAfterMinor; }
List<CollectionAllocation> allocateOldestFirst(List<OpenReceivableOrder> orders, int amountMinor);
class CollectionPreview { List<OpenReceivableOrder> applicable; int scopeTotal, customerTotal; bool over; List<CollectionAllocation> allocations; int afterMinor; bool canSubmit; }
CollectionPreview collectionPreview({required List<OpenReceivableOrder> orders, required Set<String> selectedIds, required int amountMinor});

// receivable_error_messages.dart
const Map<String, String> kReceivableErrorMessages; // bảng 6.3, dùng cho AppException.userMessage(kReceivableErrorMessages)
```

Tham số RPC (mọi hàm gửi thêm `p_tenant_id`, `p_actor_id`):

| Hàm | RPC | Tham số riêng |
|---|---|---|
| `list` | `list_customer_receivables` | `p_filter` (`filter.name`), `p_search` (trim, rỗng → null), `p_cursor`, `p_page_size: 50` |
| `getCustomer` | `get_customer_receivable` | `p_customer_partner_id` |
| `history` | `list_customer_receivable_history` | `p_customer_partner_id`, `p_cursor`, `p_page_size: 20` |
| `recordCollection` | `record_customer_collection` | `p_customer_partner_id`, `p_amount_minor`, `p_payment_method_code` (`method.name`), `p_external_reference` (trim, rỗng → null), `p_order_ids`, `p_expected_outstanding_minor`, `p_idempotency_key` |

Prototype gốc của hàm thuần (`specs/themes/theme-06/03.design/prototype/html/`), chép để giữ đúng hành vi:

`specs/themes/theme-06/03.design/prototype/html/app/format.js:10-17`

```js
export function dueLabel(dueDate, today) {
  if (!dueDate) return { kind: 'none', text: 'Không có hẹn' };
  const diff = dayNum(today) - dayNum(dueDate);
  if (diff > 0) return { kind: 'overdue', days: diff, text: `Quá hạn ${diff} ngày` };
  if (diff === 0) return { kind: 'today', text: 'Đến hạn hôm nay' };
  const [, m, d] = dueDate.split('-');
  return { kind: 'upcoming', text: `Hẹn ${d}/${m}` };
}
```

`specs/themes/theme-06/03.design/prototype/html/app/allocate.js:1-9`

```js
export function allocateOldestFirst(orders, amountMinor) {
  let left = amountMinor; const out = [];
  for (const o of orders) {
    if (left <= 0) break;
    const a = Math.min(left, o.outstandingMinor);
    if (a > 0) { out.push({ id: o.id, allocatedMinor: a, outstandingAfterMinor: o.outstandingMinor - a }); left -= a; }
  }
  return out;
}
```

`specs/themes/theme-06/03.design/prototype/html/app/cn03.js:29-40`

```js
/** Thuần: phạm vi áp dụng = các đơn đã tick (giữ thứ tự cũ trước). Số tiền mặc định = Σ còn nợ các đơn đã tick (scopeTotal). */
export function cn03Scope(orders, selectedIds = []) {
  const applicable = orders.filter((o) => selectedIds.includes(o.id));
  return { applicable, scopeTotal: applicable.reduce((s, o) => s + o.outstandingMinor, 0), customerTotal: orders.reduce((s, o) => s + o.outstandingMinor, 0) };
}

/** Thuần: kết quả tính cho một số tiền (dùng cả khi gõ tay). */
export function cn03Calc(amount, orders, total, customerTotal = total) {
  const over = amount > total;
  const alloc = amount > 0 && !over ? allocateOldestFirst(orders, amount) : [];
  return { over, alloc, after: customerTotal - (over ? 0 : amount), canSubmit: amount > 0 && !over };
}
```

Khác prototype có chủ đích: `dueLabel` Dart **không tự tính số ngày** — `overdueDays > 0` → `overdue` với `days = overdueDays`; còn lại so `dueDate` với `today` (cùng ngày → `today`, sau → `upcoming` "Hẹn dd/MM"), `dueDate == null` → `none`. `customerDueLabel` tương tự với `maxOverdueDays` / `nextDueDate` (server đã chọn hẹn gần nhất chưa quá hạn).

- [ ] **Bước 1: `support/receivable_fixtures.dart`** — dữ liệu ví dụ 2.3 (giống `data.js` T6-2a), `today = DateTime(2026, 11, 18)`:
  - `tuanOrders` (cũ trước): `DH-001` payable 4.000.000 / còn 4.000.000 / hẹn 10/11 / overdueDays 8; `DH-002` 10.000.000 / 8.000.000 / 15/11 / 3; `DH-003` 6.000.000 / 6.000.000 / 30/11 / 0. id = `'so-001'`, `'so-002'`, `'so-003'`.
  - `tuanDetail` (outstanding 18.000.000, 3 đơn, 2 quá hạn, max 8), `tuanHistoryBefore` (một `customerCollection` 2.000.000 cash 06/11 14:20 "Nguyễn An" vào DH-002), `summaryBefore` = `{26.500.000, 3, 1, 12.000.000, 8}`, `rowsBefore` = Anh Tuấn / Trại Hưng Phát (2.500.000, 2 đơn, hẹn 18/11) / Chị Lan (6.000.000, 1 đơn, hẹn 25/11), và JSON server tương ứng (`tuanDetailJson`, `listJson`, `historyJson`) để test `fromJson`.
- [ ] **Bước 2: Test đỏ**
  - `receivable_format_test.dart`: `formatVnd(18000000) == '18.000.000 ₫'`, `formatVnd(0) == '0 ₫'`, `formatVnd(1234567890) == '1.234.567.890 ₫'`, `formatVndBare(2000000) == '2.000.000'`; `orderDueLabel(dueDate: 10/11, overdueDays: 8, today)` → `(overdue, 8, 'Quá hạn 8 ngày')`; `(18/11, 0)` → `(today, 'Đến hạn hôm nay')`; `(25/11, 0)` → `(upcoming, 'Hẹn 25/11')`; `(null, 0)` → `(none, 'Không có hẹn')`; `customerDueLabel(maxOverdueDays: 8, nextDueDate: 30/11)` → `Quá hạn 8 ngày`; `(0, 18/11)` → `Đến hạn hôm nay`; `(0, null)` → `Không có hẹn`.
  - `receivable_allocation_test.dart` (bộ số T6-2a): `allocateOldestFirst([DH-001 4e6, DH-002 8e6], 10e6)` → `[(so-001, 4e6, 0), (so-002, 6e6, 2e6)]`; amount 0 → `[]`; amount = tổng → mọi `outstandingAfterMinor == 0`. `collectionPreview(tuanOrders, …)`: chọn cả 3, 10e6 → alloc DH-001 4e6→0, DH-002 6e6→2e6, `afterMinor 8e6`, `canSubmit`; chọn `{so-002}`, 8e6 → `[(so-002, 8e6, 0)]`, `afterMinor 10e6`; chọn `{so-001, so-003}`, 5e6 → `[(so-001, 4e6, 0), (so-003, 1e6, 5e6)]`, `afterMinor 13e6`; chọn `{so-002}`, 8.000.001 → `over`, `allocations []`, `afterMinor 18e6`, `!canSubmit`; chọn `{}` → `scopeTotal 0`, `!canSubmit`; `applicable` giữ thứ tự `orders` dù `selectedIds` khác thứ tự.
  - `receivable_repository_test.dart` (khuôn `_Rpc` của `sales_receipt_repository_test.dart`): mỗi hàm gọi đúng schema `receivable` + tên RPC + tham số bảng trên (gồm `p_page_size`, `p_search` rỗng → `null`, `p_external_reference` "  " → `null`, `p_payment_method_code: 'manualBankTransfer'`); `fromJson` của `listJson` / `tuanDetailJson` / `historyJson` ra đúng fixture (gồm `kind: 'customer_collection'` → `customerCollection`, `allocations[0].orderCode == 'DH-002'`, `actorDisplayName == 'Nguyễn An'`, `nextDueDate` / `dueDate` null khi JSON null); lỗi `{"code":"RECEIVABLE_CHANGED",…}` → `AppException.code == 'RECEIVABLE_CHANGED'` và `userMessage(kReceivableErrorMessages) == 'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.'`.
- [ ] **Bước 3: Chạy** `cd apps/erp && flutter test test/features/receivable` → FAIL (chưa có file).
- [ ] **Bước 4: Cài đặt** 5 file theo Interfaces; `kReceivableErrorMessages` chép nguyên cột "Thông điệp" của TH-06 6.3 cho `NOT_FOUND`→"Không tìm thấy khách hàng.", `AMOUNT_INVALID`, `NO_OUTSTANDING`, `OVERPAYMENT_NOT_ALLOWED`, `RECEIVABLE_CHANGED`, `PAYMENT_METHOD_INVALID` (`PERMISSION_DENIED` đã được `AppException` đổi sang `NO_PERMISSION`, dùng câu chung). Đăng ký DI: `..registerLazySingleton<ReceivableRepository>(() => ReceivableRepository(rpc: getIt<SupabaseRpc>(), tenantId: …, actorId: …))` chép đúng hai lambda của `PartnerRepository`.
- [ ] **Bước 5: Chạy lại** → PASS; `flutter analyze lib/features/receivable test/features/receivable` sạch.
- [ ] **Bước 6: Commit** `feat(receivable): T6-2b repository, định dạng, chia cũ trước`

---

### Task 3: CN-01 danh sách khách + shell web hai cột + route + menu Thêm

**Files:**
- Create: `logic/receivable_list_cubit.dart`, `logic/receivable_list_state.dart`, `presentation/widgets/receivable_parts.dart`, `presentation/pages/receivable_list_page.dart`, `presentation/receivable_area_shell.dart`, `presentation/receivable_routes.dart`
- Modify: `lib/core/router/app_router.dart` (thêm `...receivableRoutes(hasPermission: _hasTenantPermission),` cạnh `...reportsRoutes(),` dòng ~661), `lib/features/more/presentation/more_entries.dart`
- Test: `test/features/receivable/logic/receivable_list_cubit_test.dart`, `test/features/receivable/presentation/cn01_test.dart`, `test/features/receivable/presentation/receivable_golden_test.dart`, `test/features/receivable/support/fake_receivable_repository.dart`

**Interfaces:**
- Consumes: Task 2 (`ReceivableRepository.list`, `CustomerReceivablePage`, `customerDueLabel`, `formatVnd`).
- Produces:
  - `enum ReceivableListStatus { loading, ready, error }`; `class ReceivableListState { status; ReceivableFilter filter; String query; ReceivableSummary? summary; List<CustomerReceivableRow> items; String? nextCursor; bool loadingMore; }`
  - `class ReceivableListCubit extends Cubit<ReceivableListState>` — ctor `({required ReceivableRepository repository, Duration searchDebounce = const Duration(milliseconds: 300)})`; `Future<void> load()`, `void toggleOverdue()` (all ↔ overdue, tải lại), `void setQuery(String text)` (debounce rồi tải lại), `void clearQuery()` (tải lại ngay), `Future<void> loadMore()` (khi `nextCursor != null && !loadingMore`), `Future<void> refresh()` (giữ filter / query). Phản hồi của lần tải cũ đến muộn bị bỏ (đếm `_requestId`).
  - `receivable_parts.dart` (= `ui.js`): `ReceivableDueBadge(DueLabel label, {double fontSize})`, `ReceivableInactiveBadge()`, `ReceivableSectionTitle(String text)`, `ReceivableEmpty({required String title, String? description, String? actionLabel, VoidCallback? onAction, VIcons icon})`.
  - `ReceivableListPage({required ReceivableListCubit cubit, String? selectedId, DateTime? today})`, `ReceivableAreaShell({required Widget child, String? selectedId, ReceivableRepository? repository, ReceivableListCubit? cubit})`, `List<RouteBase> receivableRoutes({required bool Function(String code) hasPermission})`.
  - Route: `/more/receivables` (tên `receivable.list`), `/more/receivables/:customerId` (`receivable.customer`). `receivableRoutes({required bool Function(String code) hasPermission})` — `app_router.dart` truyền `_hasTenantPermission`; shell builder kiểm `receivable.view`, không có → `Scaffold` + `VAppBar('Công nợ phải thu')` + `ReceivableEmpty(title: 'Bạn không có quyền thực hiện thao tác này.')`. Web tách đôi + chưa chọn → "Chọn một khách để xem công nợ" (khuôn `partner.list` dòng 574–588). Chạm dòng: tách đôi → `context.go('/more/receivables/<id>')`; iPhone → `context.push(...)` (khuôn `PartnerListPage._openPartnerDetail`). Task 4 thay trang chi tiết tạm bằng CN-02.
  - `MoreEntry(id: 'receivables', icon: <một VIcons có sẵn gần nghĩa tiền / ví; không có thì VIcons.chart>, title: 'Công nợ phải thu', subtitle: 'Khách đang nợ, quá hạn, thu tiền', route: '/more/receivables', needsActiveTenant: true, matchPrefixes: ['/more/receivables'])` đặt **ngay sau** `customers` ("Khách hàng & NCC") (FR-04 US-04.1; prototype `patches` `more-menu`). Mục "Báo cáo" giữ nguyên.

**Ảnh đích (Prototype | Flutter):**

| Prototype 390 | Flutter 390 | Prototype 1280 | Flutter 1280 |
|---|---|---|---|
| ![](img/T6-2b/proto-CN-01-all-390.png) `all` | ![](img/T6-2b/flutter-CN-01-all-390.png) | ![](img/T6-2b/proto-CN-01-all-1280.png) | ![](img/T6-2b/flutter-CN-01-all-1280.png) |
| ![](img/T6-2b/proto-CN-01-many-390.png) `many` | ![](img/T6-2b/flutter-CN-01-many-390.png) | ![](img/T6-2b/proto-CN-01-many-1280.png) | ![](img/T6-2b/flutter-CN-01-many-1280.png) |
| ![](img/T6-2b/proto-CN-01-no-overdue-390.png) `no-overdue` | ![](img/T6-2b/flutter-CN-01-no-overdue-390.png) | ![](img/T6-2b/proto-CN-01-no-overdue-1280.png) | ![](img/T6-2b/flutter-CN-01-no-overdue-1280.png) |
| ![](img/T6-2b/proto-CN-01-overdue-390.png) `overdue` | ![](img/T6-2b/flutter-CN-01-overdue-390.png) | ![](img/T6-2b/proto-CN-01-overdue-1280.png) | ![](img/T6-2b/flutter-CN-01-overdue-1280.png) |
| ![](img/T6-2b/proto-CN-01-search-empty-390.png) `search-empty` | ![](img/T6-2b/flutter-CN-01-search-empty-390.png) | ![](img/T6-2b/proto-CN-01-search-empty-1280.png) | ![](img/T6-2b/flutter-CN-01-search-empty-1280.png) |
| ![](img/T6-2b/proto-CN-01-empty-390.png) `empty` | ![](img/T6-2b/flutter-CN-01-empty-390.png) | ![](img/T6-2b/proto-CN-01-empty-1280.png) | ![](img/T6-2b/flutter-CN-01-empty-1280.png) |
| ![](img/T6-2b/proto-CN-01-error-390.png) `error` | ![](img/T6-2b/flutter-CN-01-error-390.png) | ![](img/T6-2b/proto-CN-01-error-1280.png) | ![](img/T6-2b/flutter-CN-01-error-1280.png) |
| ![](img/T6-2b/proto-CN-01-loading-390.png) `loading` | ![](img/T6-2b/flutter-CN-01-loading-390.png) | ![](img/T6-2b/proto-CN-01-loading-1280.png) | ![](img/T6-2b/flutter-CN-01-loading-1280.png) |
| ![](img/T6-2b/proto-CN-01-loading-more-390.png) `loading-more` | ![](img/T6-2b/flutter-CN-01-loading-more-390.png) | ![](img/T6-2b/proto-CN-01-loading-more-1280.png) | ![](img/T6-2b/flutter-CN-01-loading-more-1280.png) |
| ![](img/T6-2b/proto-CN-01-long-390.png) `long` | ![](img/T6-2b/flutter-CN-01-long-390.png) | ![](img/T6-2b/proto-CN-01-long-1280.png) | ![](img/T6-2b/flutter-CN-01-long-1280.png) |

**Code prototype (chép nguyên văn):**

`specs/themes/theme-06/03.design/prototype/html/app/ui.js:16-33`

```js
export function dueBadge(l) {
  const warn = l.kind === 'overdue';
  return `<span class="rc-due rc-due--${l.kind}">${warn ? icon('alert', 'icon--sm') : ''}<span>${esc(l.text)}</span></span>`;
}

export function inactiveBadge() { return '<span class="ds24-badge ds24-badge--neutral">Ngừng hoạt động</span>'; }

export function btn(label, { kind = 'primary', attrs = '', disabled = false, full = false } = {}) {
  return `<button class="button button--${kind}${full ? ' button--full' : ''}" type="button" ${attrs}${disabled ? ' disabled' : ''}>${esc(label)}</button>`;
}

export function empty({ title, description = '', action = '', actionAttrs = '', iconName = 'inbox' }) {
  return `<div class="ds24-empty"><div class="ds24-empty__media">${icon(iconName, 'icon--48')}</div><h3>${esc(title)}</h3>${description ? `<p>${esc(description)}</p>` : ''}${action ? btn(action, { kind: 'secondary', attrs: actionAttrs }) : ''}</div>`;
}

export function skeletonRows(n) {
  return `<div class="skeleton-stack">${Array.from({ length: n }, () => '<div class="skeleton skeleton--row"></div>').join('')}</div>`;
}
```

`specs/themes/theme-06/03.design/prototype/html/app/cn01.js:9-98`

```js
export const fold = (s) => String(s).normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();

const RANK = { overdue: 0, today: 1, upcoming: 2, none: 3 };
const nextDue = (c) => c.orders.filter((o) => o.outstandingMinor > 0 && o.dueDate).map((o) => o.dueDate).sort()[0] || '9999';
const byDebt = (a, b) => totalOf(b) - totalOf(a) || a.displayName.localeCompare(b.displayName, 'vi');

/** Mức khẩn: quá hạn lâu nhất trước, rồi đến hạn hôm nay, rồi hẹn gần nhất, rồi không hẹn; cùng mức thì nợ nhiều trước. */
export function sortedByUrgency(list) {
  return [...list].sort((a, b) => {
    const la = customerDueLabel(a.orders, TODAY); const lb = customerDueLabel(b.orders, TODAY);
    return RANK[la.kind] - RANK[lb.kind] || (lb.days || 0) - (la.days || 0) || nextDue(a).localeCompare(nextDue(b)) || byDebt(a, b);
  });
}

/** Ô tổng: tổng còn phải thu, số khách, và phần quá hạn (tiền, số khách, ngày lâu nhất). */
export function summaryV(list) {
  const over = list.filter((c) => customerDueLabel(c.orders, TODAY).kind === 'overdue');
  return {
    totalMinor: list.reduce((s, c) => s + totalOf(c), 0),
    customerCount: list.length,
    overdueMinor: over.reduce((s, c) => s + overdueAmountMinor(c.orders, TODAY), 0),
    overdueCustomerCount: over.length,
    oldestOverdueDays: Math.max(0, ...over.map((c) => customerDueLabel(c.orders, TODAY).days)),
  };
}

export function filterCustomers(list, { filter = 'all', query = '' } = {}) {
  let r = list;
  if (filter === 'overdue') r = r.filter((c) => customerDueLabel(c.orders, TODAY).kind === 'overdue');
  const q = fold(query.trim());
  if (q) r = r.filter((c) => fold(c.displayName).includes(q) || (c.phone || '').replace(/\s/g, '').includes(q.replace(/\s/g, '')));
  return sortedByUrgency(r);
}

/** Dòng khách: trái = tên + SĐT·đơn, phải = tiền + nhãn hạn. */
function row(c, { selectedId, overdueOnly }) {
  const l = customerDueLabel(c.orders, TODAY);
  const n = c.orders.filter((o) => o.outstandingMinor > 0).length;
  const sub = `${c.phone ? `${esc(c.phone)} · ` : ''}${n} đơn`;
  const extra = overdueOnly && l.kind === 'overdue' ? `<span class="rc-due__amount">· ${formatVnd(overdueAmountMinor(c.orders, TODAY))}</span>` : '';
  const sel = selectedId === c.id;
  return `<button class="rv-row${sel ? ' is-selected' : ''}" type="button" data-nav="cn02:${c.id}"${sel ? ' aria-current="true"' : ''}>
    <span class="rv-row__main"><span class="rv-row__name"><span class="rc-ellipsis" title="${esc(c.displayName)}">${esc(c.displayName)}</span>${c.isActive ? '' : inactiveBadge()}</span><span class="rv-row__sub">${sub}</span></span>
    <span class="rv-row__side"><span class="rv-money">${formatVnd(totalOf(c))}</span><span class="rv-row__due">${dueBadge(l)}${extra}</span></span>
  </button>`;
}

export function cn01List(list, opts = {}) {
  const shown = filterCustomers(list, opts);
  if (!shown.length) return empty({ title: 'Không tìm thấy khách phù hợp.', action: 'Xoá tìm kiếm', actionAttrs: 'data-clear-search', iconName: 'search' });
  const count = shown.length < list.length ? `<p class="rv-showing" role="status">Đang hiển thị ${shown.length} / ${list.length} khách</p>` : '';
  return `${count}<div class="rv-list">${shown.map((c) => row(c, { ...opts, overdueOnly: opts.filter === 'overdue' })).join('')}${opts.loadingMore ? '<div class="rc-loadmore"><span class="rc-spinner" role="status" aria-label="Đang tải thêm"></span></div>' : ''}</div>`;
}

export function hero(s, filter = 'all') {
  if (!s.overdueCustomerCount) return `<div class="rv-hero rv-hero--ok" role="status">${icon('checkCircle')}<span class="rv-hero__text"><b>Không có khoản nào quá hạn</b><span>Tất cả khách đang nợ còn trong hạn hẹn.</span></span></div>`;
  const on = filter === 'overdue';
  return `<button class="rv-hero${on ? ' is-active' : ''}" type="button" data-filter="${on ? 'all' : 'overdue'}" aria-pressed="${on}" aria-label="Quá hạn ${formatVnd(s.overdueMinor)}, ${s.overdueCustomerCount} khách. ${on ? 'Đang lọc quá hạn, bấm để xem tất cả' : 'Bấm để chỉ xem khách quá hạn'}"><span class="rv-hero__label">${icon('alert', 'icon--sm')}Quá hạn</span><span class="rv-hero__amount rv-money">${formatVnd(s.overdueMinor)}</span><span class="rv-hero__sub">${s.overdueCustomerCount} khách · lâu nhất ${s.oldestOverdueDays} ngày</span><span class="rv-hero__chev">${on ? 'Xem tất cả' : icon('chevronRight', 'icon--sm')}</span></button>`;
}

function head(list, { filter, query }) {
  const s = summaryV(list);
  return `<div data-region="cn01-hero">${hero(s, filter)}</div>
  <div class="rv-total"><span class="rv-total__label">Tổng còn phải thu</span><span class="rv-total__row"><span class="rv-total__quiet rv-money">${formatVnd(s.totalMinor)}</span><span class="rv-total__count">${s.customerCount} khách</span></span></div>
  <label class="rc-search">${icon('search')}<input type="text" data-search value="${esc(query)}" placeholder="Tìm tên, SĐT" aria-label="Tìm tên, SĐT"><button class="rc-search__clear" type="button" aria-label="Xoá tìm kiếm" data-clear-search>${icon('close', 'icon--sm')}</button></label>`;
}

const DATASETS = {
  long: () => [...customers, ...edgeCustomers],
  many: () => richCustomers,
  'no-overdue': () => customers.filter((c) => customerDueLabel(c.orders, TODAY).kind !== 'overdue'),
};

/** Cột / màn CN-01 (không gồm khung hai cột web). */
export function cn01Column(state, device, { selectedId = null } = {}) {
  const list = DATASETS[state]?.() ?? customers;
  const filter = state === 'overdue' ? 'overdue' : 'all';
  const query = state === 'search-empty' ? 'xyz' : '';
  const back = device === 'iphone';
  const title = 'Công nợ phải thu';
  if (state === 'loading') return page({ title, back, device, body: `<div class="rv-skel-hero skeleton"></div><div class="rc-skel-controls"><div class="skeleton skeleton--search"></div></div>${skeletonRows(6)}` });
  if (state === 'empty') return page({ title, back, device, body: empty({ title: 'Không có khách nào đang nợ', description: 'Đơn bán nợ sẽ hiện ở đây.' }) });
  if (state === 'error') return page({ title, back, device, body: empty({ title: 'Không tải được công nợ', action: 'Thử lại', actionAttrs: 'data-retry', iconName: 'alert' }) });
  return page({ title, back, device, body: `${head(list, { filter, query })}<div data-region="cn01-list">${cn01List(list, { filter, query, selectedId, loadingMore: state === 'loading-more' })}</div>` });
}

export function renderCn01(state, device) {
  if (device === 'web') return `<div class="rc-twocol"><div class="rc-col">${cn01Column(state, device)}</div><div class="rc-col rc-col--right"><div class="rc-pick">Chọn một khách để xem công nợ</div></div></div>`;
  return cn01Column(state, device);
}
```

`specs/themes/theme-06/03.design/prototype/html/styles/cn01.css:1-41`

```css
/* CN-01 — "Quá hạn dẫn đầu" (phương án B, chốt 2026-11-18). Chỉ token --c45-v2-*; cỡ chữ chỉ dùng bậc DESIGN.md: 13 / 14 / 28. */
:root { --rv-fs-headline: 28px; }

/* hero: số tiền quá hạn */
.rv-hero { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: center; column-gap: var(--c45-v2-space-3); row-gap: 2px; width: calc(100% - 2 * var(--c45-v2-space-4)); margin: var(--c45-v2-space-4) var(--c45-v2-space-4) 0; padding: var(--c45-v2-space-4); border: 1px solid color-mix(in srgb, var(--c45-v2-danger-500) 25%, var(--c45-v2-surface-default)); border-radius: var(--c45-v2-radius-card); background: var(--c45-v2-danger-50); text-align: left; font: inherit; color: inherit; cursor: pointer; }
.rv-hero:hover { background: color-mix(in srgb, var(--c45-v2-danger-50) 92%, var(--c45-v2-danger-500)); }
.rv-hero:focus-visible { outline: 2px solid var(--c45-v2-focus-ring); outline-offset: 2px; }
.rv-hero__label { grid-column: 1; display: inline-flex; align-items: center; gap: var(--c45-v2-space-1); color: var(--c45-v2-text-danger); font-size: var(--rc-fs-sm); font-weight: 600; }
.rv-hero .rv-hero__amount { grid-column: 1; color: var(--c45-v2-text-danger); font-size: var(--rv-fs-headline); line-height: 1.3; }
.rv-hero__sub { grid-column: 1; color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); }
.rv-hero__chev { grid-column: 2; grid-row: 1 / span 3; display: inline-flex; align-items: center; color: var(--c45-v2-icon-muted); font-size: var(--rc-fs-sm); font-weight: 600; }
.rv-hero.is-active { border-color: var(--c45-v2-danger-500); box-shadow: inset 0 0 0 1px var(--c45-v2-danger-500); }
.rv-hero.is-active .rv-hero__chev { color: var(--c45-v2-text-danger); }
.rv-hero--ok { grid-template-columns: auto minmax(0, 1fr); border-color: var(--c45-v2-border-brand); background: var(--c45-v2-primary-50); color: var(--c45-v2-text-success); cursor: default; }
.rv-hero--ok:hover { background: var(--c45-v2-primary-50); }
.rv-hero__text { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.rv-hero__text b { color: var(--c45-v2-text-primary); font-size: var(--rc-fs-md); font-weight: 600; }
.rv-hero__text span { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); }
.rv-skel-hero { height: 108px; margin: var(--c45-v2-space-4) var(--c45-v2-space-4) 0; border-radius: var(--c45-v2-radius-card); }

/* tổng còn phải thu: thu nhỏ, đứng sau hero */
.rv-total { display: flex; flex-direction: column; gap: 2px; padding: var(--c45-v2-space-3) var(--c45-v2-space-4) var(--c45-v2-space-2); }
.rv-total__label { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-weight: 600; }
.rv-total__row { display: flex; align-items: baseline; justify-content: space-between; gap: var(--c45-v2-space-3); }
.rv-total .rv-total__quiet { font-size: var(--rc-fs-md); }
.rv-showing { margin: 0; padding: var(--c45-v2-space-2) var(--c45-v2-space-4); color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-weight: 600; }
.rv-total__count { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); white-space: nowrap; }

/* dòng khách: trái = tên + SĐT·đơn, phải = tiền + nhãn hạn */
.rv-list { display: flex; flex-direction: column; border-top: 1px solid var(--c45-v2-border-default); }
.rv-row { display: grid; grid-template-columns: minmax(0, 1fr) auto; align-items: start; gap: var(--c45-v2-space-3); width: 100%; min-height: var(--c45-v2-touch-minimum); padding: var(--c45-v2-space-3) var(--c45-v2-space-4); border: 0; border-bottom: 1px solid var(--c45-v2-border-default); background: var(--c45-v2-surface-default); text-align: left; font: inherit; color: inherit; cursor: pointer; }
.rv-row:hover { background: var(--c45-v2-neutral-100); }
.rv-row:focus-visible { outline: 2px solid var(--c45-v2-focus-ring); outline-offset: -2px; }
.rv-row.is-selected, .rv-row.is-selected:hover { background: var(--c45-v2-primary-50); }
.rv-row__main { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.rv-row__name { display: flex; align-items: center; gap: var(--c45-v2-space-2); min-width: 0; font-size: var(--rc-fs-md); font-weight: 600; }
.rv-row__sub { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-variant-numeric: tabular-nums; white-space: nowrap; }
.rv-row__side { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }
.rv-row__due { display: flex; align-items: center; gap: var(--c45-v2-space-1); font-size: var(--rc-fs-sm); }
.rv-money { font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 700; font-size: var(--rc-fs-md); }
.rc-app[data-device="web"] .rv-row { padding-block: var(--c45-v2-space-2); }
```

`specs/themes/theme-06/03.design/prototype/html/styles/receivable.css:12-41`

```css
.rc-twocol { display: grid; grid-template-columns: 380px 1fr; flex: 1; min-height: 0; }
.rc-twocol > .rc-col { overflow: hidden; display: flex; flex-direction: column; min-height: 0; }
.rc-twocol > .rc-col:first-child { border-right: 1px solid var(--c45-v2-border-default); }
.rc-col--right { background: var(--c45-v2-surface-canvas); }
.rc-pick { margin: auto; color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-lg); }
.rc-placeholder { margin: auto; color: var(--c45-v2-text-secondary); }

.rc-page { display: flex; flex-direction: column; flex: 1; min-height: 0; background: var(--c45-v2-surface-default); }
.rc-body { flex: 1; min-height: 0; overflow: hidden; display: flex; flex-direction: column; }
.rc-footer { flex: 0 0 auto; padding: var(--c45-v2-space-3) var(--c45-v2-space-4); border-top: 1px solid var(--c45-v2-border-default); background: var(--c45-v2-surface-default); display: flex; gap: var(--c45-v2-space-3); }
.rc-footer .button { flex: 1; }
.rc-ellipsis { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
.rc-money { font-variant-numeric: tabular-nums; text-align: right; white-space: nowrap; font-weight: 700; }

/* CN-01 */
.rc-search { margin: 0 var(--c45-v2-space-4) var(--c45-v2-space-3); display: flex; align-items: center; gap: var(--c45-v2-space-2); min-height: var(--c45-v2-touch-minimum); padding: 0 var(--c45-v2-space-3); border: 1px solid var(--c45-v2-border-input); border-radius: var(--c45-v2-radius-input); color: var(--c45-v2-icon-muted); }
.rc-search__clear { flex: 0 0 auto; display: inline-grid; place-items: center; width: var(--c45-v2-touch-minimum); height: var(--c45-v2-touch-minimum); margin-right: calc(-1 * var(--c45-v2-space-3)); border: 0; background: transparent; color: var(--c45-v2-icon-secondary); cursor: pointer; }
.rc-search__clear:focus-visible { outline: 2px solid var(--c45-v2-focus-ring); outline-offset: -2px; border-radius: var(--c45-v2-radius-input); }
.rc-search:has(input:placeholder-shown) .rc-search__clear { display: none; }
.rc-skel-controls { padding: 0 var(--c45-v2-space-4); }
.rc-skel-controls .skeleton--search { margin-top: var(--c45-v2-space-3); }
.rc-skel-controls + .skeleton-stack { padding-top: var(--c45-v2-space-3); }
.rc-search input { flex: 1; min-width: 0; border: 0; outline: 0; background: transparent; font: inherit; color: var(--c45-v2-text-primary); }
.rc-due { display: inline-flex; align-items: center; gap: var(--c45-v2-space-1); font-weight: 600; color: var(--c45-v2-text-secondary); }
.rc-due--overdue { color: var(--c45-v2-text-danger); }
.rc-due--today { color: var(--c45-v2-text-warning); }
.rc-due__amount { color: var(--c45-v2-text-danger); font-weight: 600; font-variant-numeric: tabular-nums; }
.rc-loadmore { display: flex; justify-content: center; padding: var(--c45-v2-space-4); }
.rc-spinner { width: var(--c45-v2-icon-24); height: var(--c45-v2-icon-24); border-radius: var(--c45-v2-radius-pill); border: 3px solid var(--c45-v2-border-default); border-top-color: var(--c45-v2-action-primary-default); animation: spin .8s linear infinite; }
.skeleton-stack { padding: var(--c45-v2-space-4); }
```

Token dùng (giá trị CSS → Dart): `space-1/2/3/4/5` 4/8/12/16/20 → `VSpacing.space1…5`; `touch-minimum` 44 → `VSpacing.minTouchTarget`; `radius-card` 12 → `VRadius.card`; `radius-input` 8 → `VRadius.input`; `border-default` #E5E8EB → `borderDefault`; `border-input` #868E98 → `borderInput`; `border-brand` → `borderBrand`; `surface-default` → `surface`; `surface-canvas` → `background`; `text-primary/secondary/muted` → `textPrimary/textSecondary/textMuted`; `text-danger` → `danger`; `text-warning` → `warning`; `text-success` → `success`; `danger-50` → `dangerBg`; `danger-500` → `danger`; `primary-50` → `surfaceBrand`; `neutral-100` (hover) → `surfaceHover`; `icon-muted` #9AA3AD → `VColors.neutral400`; `icon-secondary` #6B7480 → `textMuted`. Cỡ chữ: 13 → `VTypography.bodySmall`, 14 → `bodyDefault`/`labelDefault` (600), 28 → `headingH1`.

**Ánh xạ phần tử → Flutter (CN-01):**

| Phần tử prototype | Flutter | Thông số |
|---|---|---|
| `page({title:'Công nợ phải thu', back})` | `Scaffold` + `VAppBar(title: 'Công nợ phải thu', showBackButton: !split)` | web tách đôi: không nút lùi (prototype `back = device === 'iphone'`) |
| `.rv-hero` (có quá hạn) | `Semantics(button, label: <aria-label prototype>)` + `InkWell` trong `Container` | margin `space4` trên/trái/phải; padding `space4`; viền 1 `danger` @25% trộn `surface` (`Color.alphaBlend(danger.withOpacity(.25), surface)`); bo `VRadius.card`; nền `dangerBg`. Lưới 2 cột: trái = nhãn (icon `VIcons.warning` cỡ 16 + "Quá hạn", 13/600 `danger`), số (`formatVnd(summary.overdueAmountMinor)`, 28/700 `danger`, cao dòng 1.3, tabular), dòng phụ "`n` khách · lâu nhất `N` ngày" (13 `textSecondary`); phải = chevron (`neutral400`) hoặc "Xem tất cả" (13/600 `danger`) khi đang lọc. Đang lọc: viền 2 `danger` (`border` 1 + `inset` 1). Bấm → `toggleOverdue()` |
| `.rv-hero--ok` (không quá hạn) | `Container` không bấm | viền `borderBrand`, nền `surfaceBrand`; icon check `success`; "Không có khoản nào quá hạn" 14/600 `textPrimary`; "Tất cả khách đang nợ còn trong hạn hẹn." 13 `textSecondary` |
| `.rv-total` | `Padding(fromLTRB(16,12,16,8))` + `Column` | "Tổng còn phải thu" 13/600 `textSecondary`; hàng: `formatVnd(totalOutstandingMinor)` 14/700 tabular ↔ "`customerCount` khách" 13 `textSecondary` (baseline, `spaceBetween`) |
| `.rc-search` | `VSearchBar(hintText: 'Tìm tên, SĐT', onChanged: setQuery, onClear: clearQuery)` | margin `0 16 12`; cao ≥ 44; nút xoá chỉ hiện khi có chữ (`VSearchBar` tự lo) |
| `.rv-showing` | `Text` | xem Quyết định 7; padding `8 16`; 13/600 `textSecondary`; `Semantics(liveRegion)` |
| `.rv-list` / `.rv-row` | `ListView` dòng `InkWell` | viền trên danh sách 1 `borderDefault`; mỗi dòng: padding `12 16` (web `8 16`), viền dưới 1, nền `surface` (đang chọn `surfaceBrand`), cao ≥ 44; trái (`Expanded`): tên 14/600 `maxLines 1, ellipsis` + `ReceivableInactiveBadge` khi `!isActive`; dưới "`phone` · `n` đơn" (thiếu phone → "`n` đơn") 13 `textSecondary`; phải (cột canh phải, không co): `formatVnd(outstandingMinor)` 14/700 tabular `softWrap:false`; dưới `ReceivableDueBadge(customerDueLabel(...), fontSize 13)` + khi lọc quá hạn và nhãn overdue: "· `formatVnd(overdueAmountMinor)`" 13/600 `danger` |
| `dueBadge` (`.rc-due`) | `ReceivableDueBadge` | `Row(min)` khoảng 4; overdue: icon cảnh báo 16 + chữ `danger`; today: `warning`; còn lại `textSecondary`; chữ 600. `Semantics(label: text)` |
| `inactiveBadge` | `VBadge(label: 'Ngừng hoạt động', tone: VComponentTone.neutral, variant: VBadgeVariant.soft, isSmall: true)` | |
| `.rc-loadmore .rc-spinner` | `Padding(16)` + `VLoading` cỡ 24 | khi `loadingMore`; cuộn tới cuối 200 px → `loadMore()` |
| `loading` | `VSkeleton` hero cao 108 bo `card` margin `16 16 0` + ô tìm + 6 dòng | |
| `empty` | `ReceivableEmpty(title: 'Không có khách nào đang nợ', description: 'Đơn bán nợ sẽ hiện ở đây.')` | không nút |
| `error` | `ReceivableEmpty(title: 'Không tải được công nợ', actionLabel: 'Thử lại', onAction: load, icon: cảnh báo)` | |
| `search-empty` (`cn01List` rỗng) | `ReceivableEmpty(title: 'Không tìm thấy khách phù hợp.', actionLabel: 'Xoá tìm kiếm', onAction: clearQuery, icon: tìm)` | thay vùng danh sách, hero/tổng/tìm vẫn hiện |
| `.rc-twocol` / `.rc-pick` | `VListDetailLayout(listWidth: 380)` trong `ReceivableAreaShell` | prototype cột trái 380 (mặc định DS 360 → truyền 380); "Chọn một khách để xem công nợ" 16 `textSecondary` giữa cột phải, nền `background` |

Thứ tự dòng = thứ tự server (BR-10); app **không** tự sắp (`sortedByUrgency` của prototype chỉ để có dữ liệu). Lọc / tìm: gọi lại RPC (prototype `filterCustomers` chạy trên máy). `summary` luôn lấy từ phản hồi mới nhất (server không đổi theo lọc / tìm, BR-11).

- [ ] **Bước 1: `fake_receivable_repository.dart`** — `class FakeReceivableRepository implements ReceivableRepository` có hàng đợi kết quả / lỗi theo từng hàm (`Completer` để giữ phản hồi), ghi lại tham số mỗi lần gọi (`listCalls`, `collectionCalls`…). Task 4–5 dùng lại.
- [ ] **Bước 2: Test cubit đỏ** `receivable_list_cubit_test.dart`:
  - `load` → `loading` rồi `ready` với `summaryBefore`, 3 dòng đúng thứ tự fake trả.
  - `toggleOverdue` → gọi `list(filter: overdue)`; gọi lại → `all`.
  - `debounces search`: `setQuery('t')`, `('tu')`, `('tuan')` cách nhau 100 ms, `fakeAsync` trôi 300 ms → đúng **1** lần gọi với `search: 'tuan'`.
  - `drops stale response`: lần gọi 1 giữ bằng `Completer`, lần gọi 2 trả trước → state theo lần 2; lần 1 về sau không đổi state.
  - `loadMore` nối `items`, gửi `cursor`; không gọi khi `nextCursor == null` hoặc đang `loadingMore`.
  - lỗi → `error`; `load()` lại → `ready`.
- [ ] **Bước 3: Chạy → FAIL. Cài cubit + state. Chạy → PASS.**
- [ ] **Bước 4: GitNexus** `impact({target: "kMoreEntries", direction: "upstream"})` và `impact` cho hàm dựng router trong `app_router.dart` (tên thật đọc ở đầu file); ghi blast radius vào Kết quả; HIGH/CRITICAL → dừng báo người dùng.
- [ ] **Bước 5: Widget test đỏ** `cn01_test.dart` (mặt vẽ 390×844 bằng helper giống `useInventoryTestSurface`, `today` = 18/11):
  - `all`: thấy "Quá hạn", "12.000.000 ₫", "1 khách · lâu nhất 8 ngày", "Tổng còn phải thu", "26.500.000 ₫", "3 khách", "Anh Tuấn", "0901 234 567 · 3 đơn", "Quá hạn 8 ngày", "Đến hạn hôm nay", "Hẹn 25/11".
  - chạm hero → cubit `filter == overdue`, thấy "Xem tất cả", "· 12.000.000 ₫", "Đang hiển thị 1 / 3 khách".
  - `no-overdue` (summary `overdueCustomerCount 0`) → "Không có khoản nào quá hạn", hero không bấm được.
  - `search-empty` → "Không tìm thấy khách phù hợp." + bấm "Xoá tìm kiếm" → `clearQuery`.
  - `empty`, `error` + "Thử lại" gọi lại `list`.
  - khách `isActive: false` → "Ngừng hoạt động".
  - 1280×800: tách đôi, chưa chọn → "Chọn một khách để xem công nợ"; không có nút lùi.
  - mục menu: `kMoreEntries` có `receivables` ngay sau `customers`, `route == '/more/receivables'`.
- [ ] **Bước 6: Cài** `receivable_parts.dart`, `receivable_list_page.dart`, `receivable_area_shell.dart`, `receivable_routes.dart`; sửa `app_router.dart`, `more_entries.dart`. Chi tiết tạm cho `:customerId` = `SizedBox.shrink()` (Task 4 thay). Chạy → PASS.
- [ ] **Bước 7: Golden** `receivable_golden_test.dart` — nhóm `CN-01`, mỗi state trong bảng ảnh × {390×844, 1280×800}, `matchesGoldenFile` ghi vào `docs/refactor/plans/T6/img/T6-2b/flutter-CN-01-<state>-<w>.png` (khuôn `_goldenPath` của `costing_golden_test.dart`, đổi thư mục). Dữ liệu: `all` = 3 khách; `many` = 8 khách (`richCustomers` của `data.js`); `long` = 3 khách + công ty tên dài (không SĐT, 1.234.567.890 ₫) + Cô Hoa ngừng hoạt động; `loading`/`loading-more` dùng `Completer` chưa xong (`pump()` thay vì `pumpAndSettle`). Chạy `flutter test --update-goldens test/features/receivable/presentation/receivable_golden_test.dart`, mở từng cặp ảnh (Read) so với `proto-…`; sửa tới khi bố cục, thứ tự, chữ khớp (font hệ thống ở prototype → không bắt lệch font). Lệch còn lại ghi "Lệch plan + lý do" ở Kết quả.
- [ ] **Bước 8: Commit** `feat(receivable): T6-2b CN-01 danh sách khách còn nợ`

---

### Task 4: CN-02 công nợ của khách

**Files:**
- Create: `logic/customer_receivable_cubit.dart`, `logic/customer_receivable_state.dart`, `presentation/pages/customer_receivable_page.dart`
- Modify: `presentation/receivable_routes.dart` (route `:customerId` dựng CN-02), `test/features/receivable/presentation/receivable_golden_test.dart`
- Test: `test/features/receivable/logic/customer_receivable_cubit_test.dart`, `test/features/receivable/presentation/cn02_test.dart`

**Interfaces:**
- Consumes: Task 2 (`getCustomer`, `history`, `orderDueLabel`, `formatVnd`, `formatVndBare`), Task 3 (`receivable_parts.dart`, `ReceivableListCubit.refresh`).
- Produces:
  - `enum LoadStatus { loading, ready, error }`; `class CustomerReceivableState { LoadStatus detailStatus; CustomerReceivableDetail? detail; LoadStatus historyStatus; List<ReceivableHistoryItem> history; String? historyCursor; bool historyLoadingMore; }`
  - `class CustomerReceivableCubit` — ctor `({required ReceivableRepository repository, required String customerId})`; `Future<void> load()` (chi tiết và lịch sử **song song, lỗi độc lập**), `Future<void> retryHistory()`, `Future<void> loadMoreHistory()`, `Future<void> reload()` (sau khi thu / `Tải lại`).
  - `CustomerReceivablePage({required String customerId, ReceivableRepository? repository, DateTime? today})` — tự tạo cubit; nút "Thu tiền" gọi `showCustomerCollectionSheet` (Task 5; ở task này nút có nhưng `onPressed` để trống + `// T6-2b Task 5`).

**Ảnh đích:**

| Prototype 390 | Flutter 390 | Prototype 1280 | Flutter 1280 |
|---|---|---|---|
| ![](img/T6-2b/proto-CN-02-full-390.png) `full` | ![](img/T6-2b/flutter-CN-02-full-390.png) | ![](img/T6-2b/proto-CN-02-full-1280.png) | ![](img/T6-2b/flutter-CN-02-full-1280.png) |
| ![](img/T6-2b/proto-CN-02-after-offset-390.png) `after-offset` | ![](img/T6-2b/flutter-CN-02-after-offset-390.png) | ![](img/T6-2b/proto-CN-02-after-offset-1280.png) | ![](img/T6-2b/flutter-CN-02-after-offset-1280.png) |
| ![](img/T6-2b/proto-CN-02-block-error-390.png) `block-error` | ![](img/T6-2b/flutter-CN-02-block-error-390.png) | ![](img/T6-2b/proto-CN-02-block-error-1280.png) | ![](img/T6-2b/flutter-CN-02-block-error-1280.png) |
| ![](img/T6-2b/proto-CN-02-paid-off-390.png) `paid-off` | ![](img/T6-2b/flutter-CN-02-paid-off-390.png) | ![](img/T6-2b/proto-CN-02-paid-off-1280.png) | ![](img/T6-2b/flutter-CN-02-paid-off-1280.png) |
| ![](img/T6-2b/proto-CN-02-inactive-390.png) `inactive` | ![](img/T6-2b/flutter-CN-02-inactive-390.png) | ![](img/T6-2b/proto-CN-02-inactive-1280.png) | ![](img/T6-2b/flutter-CN-02-inactive-1280.png) |
| ![](img/T6-2b/proto-CN-02-no-history-390.png) `no-history` | ![](img/T6-2b/flutter-CN-02-no-history-390.png) | ![](img/T6-2b/proto-CN-02-no-history-1280.png) | ![](img/T6-2b/flutter-CN-02-no-history-1280.png) |

**Code prototype (chép nguyên văn):**

`specs/themes/theme-06/03.design/prototype/html/app/cn02.js:7-74`

```js
const day = (iso) => `${iso.slice(8, 10)}/${iso.slice(5, 7)}`;
const stamp = (iso) => `${day(iso)} ${iso.slice(11, 16)}`;
const find = (id) => [...customers, ...edgeCustomers].find((c) => c.id === id);

/** Mô hình thuần của CN-02 cho từng state; renderCn02 dùng lại. */
export function cn02Model(state) {
  const tuan = find('c-tuan');
  let c; let moment = null;
  if (state === 'after-offset') { c = tuan; moment = 'afterOffset'; }
  else if (state === 'paid-off') { c = tuan; moment = 'paidOff'; }
  else if (state === 'inactive') c = find('c-hoa');
  else if (state === 'no-history') c = find('c-lan');
  else if (state === 'afterCollect') { c = tuan; moment = 'afterCollect'; }
  else { c = tuan; moment = 'before'; } // full, block-error
  const { orders, history } = moment ? tuanAt(moment) : c;
  const open = orders.filter((o) => o.outstandingMinor > 0);
  return {
    customer: c, orders: open, history,
    total: open.reduce((s, o) => s + o.outstandingMinor, 0),
    overdueCount: open.filter((o) => dueLabel(o.dueDate, TODAY).kind === 'overdue').length,
    historyError: state === 'block-error',
  };
}

function historyRow(h) {
  const when = stamp(h.at);
  if (h.kind === 'collection') {
    const m = h.method === 'cash' ? 'Tiền mặt' : `Chuyển khoản${h.ref ? ` ${esc(h.ref)}` : ''}`;
    return `<div class="rc-hist"><div class="rc-hist__title">Thu ${formatVnd(h.amount).replace(' ₫', '')} · ${m}</div><div class="rc-hist__meta">${when} · ${esc(h.by)}</div><div class="rc-hist__meta">Vào: ${h.allocations.map((a) => `${esc(a.code)} ${formatVnd(a.amount).replace(' ₫', '')}`).join(', ')}</div></div>`;
  }
  if (h.kind === 'order_payment') return `<div class="rc-hist"><div class="rc-hist__title">Thu ${formatVnd(h.amount).replace(' ₫', '')} · đơn ${esc(h.orderCode)}</div><div class="rc-hist__meta">${when}</div></div>`;
  if (h.kind === 'offset') return `<div class="rc-hist"><div class="rc-hist__title">Cấn trừ ${formatVnd(h.amount).replace(' ₫', '')} · từ trả hàng đơn ${esc(h.fromOrder)} (phiếu ${esc(h.returnCode)}) sang đơn ${esc(h.toOrder)}</div><div class="rc-hist__meta">${when} · ${esc(h.by)}</div></div>`;
  return `<div class="rc-hist"><div class="rc-hist__title">Hoàn ${formatVnd(h.amount).replace(' ₫', '')} · đơn ${esc(h.orderCode)}</div><div class="rc-hist__meta">${when}</div></div>`;
}

function orderRow(o) {
  const due = dueLabel(o.dueDate, TODAY);
  return `<button class="rc-order${due.kind === 'overdue' ? ' is-overdue' : ''}" type="button" data-nav="sg09:${o.code}"><span class="rc-order__main"><span class="rc-order__code">${esc(o.code)} · ${day(o.completedAt)}</span>${dueBadge(due)}</span><span class="rc-order__money"><span class="rc-order__owed">Còn nợ ${formatVnd(o.outstandingMinor)}</span><span class="rc-order__total">Tổng ${formatVnd(o.payableMinor)}</span></span><span class="rc-order__chev">${icon('chevronRight', 'icon--sm')}</span></button>`;
}

function content(m) {
  const c = m.customer;
  const sub = m.total > 0
    ? `<div class="rc-chead__sub"><span>${m.orders.length} đơn ·</span>${m.overdueCount ? `<span class="rc-chead__warn">${icon('alert', 'icon--sm')}${m.overdueCount} quá hạn</span>` : `<span>${m.overdueCount} quá hạn</span>`}</div>`
    : '';
  const head = `<section class="rc-chead"><div class="rc-chead__who"><span class="rc-chead__name rc-ellipsis">${esc(c.displayName)}</span>${c.phone ? `<span class="rc-chead__phone">${esc(c.phone)}</span>` : ''}${c.isActive ? '' : inactiveBadge()}</div>
    <div class="rc-chead__owed"><span class="rc-chead__label">${m.total > 0 ? 'Còn nợ' : 'Không còn nợ'}</span><span class="rc-money rc-chead__amount">${formatVnd(m.total)}</span></div>${sub}</section>`;
  const orders = `<h4 class="rc-section">ĐƠN CÒN NỢ (cũ trước)</h4>${m.orders.length ? `<div class="rc-group">${m.orders.map(orderRow).join('')}</div>` : '<p class="rc-note">Không còn đơn nào nợ</p>'}`;
  let hist;
  if (m.historyError) hist = `<div class="rc-blockerr"><p>Không tải được</p>${btn('Thử lại', { kind: 'secondary', attrs: 'data-retry-block' })}</div>`;
  else if (!m.history.length) hist = '<p class="rc-note">Chưa có lần thu nào</p>';
  else hist = `<div class="rc-group">${m.history.map(historyRow).join('')}<button class="rc-more" type="button">Xem thêm</button></div>`;
  return `<div class="rc-scroll rc-cn02">${head}${orders}<h4 class="rc-section">LỊCH SỬ THU &amp; CẤN TRỪ</h4>${hist}</div>`;
}

export function cn02Page(state, device, opts = {}) {
  const m = cn02Model(state);
  const footer = m.total > 0 ? btn('Thu tiền', { full: true, attrs: 'data-nav="cn03:empty"' }) : '';
  return page({ title: 'Công nợ khách hàng', back: device === 'iphone', device, body: content(m), footer }) + (opts.toast ? toast(opts.toast) : '');
}

export function renderCn02(state, device, opts = {}) {
  if (device === 'web') {
    const m = cn02Model(state);
    return `<div class="rc-twocol"><div class="rc-col">${cn01Column('all', 'web', { selectedId: m.customer.id })}</div><div class="rc-col rc-col--right">${cn02Page(state, device, opts)}</div></div>`;
  }
  return cn02Page(state, device, opts);
}
```

`specs/themes/theme-06/03.design/prototype/html/styles/receivable.css:19-24`

```css
.rc-page { display: flex; flex-direction: column; flex: 1; min-height: 0; background: var(--c45-v2-surface-default); }
.rc-body { flex: 1; min-height: 0; overflow: hidden; display: flex; flex-direction: column; }
.rc-footer { flex: 0 0 auto; padding: var(--c45-v2-space-3) var(--c45-v2-space-4); border-top: 1px solid var(--c45-v2-border-default); background: var(--c45-v2-surface-default); display: flex; gap: var(--c45-v2-space-3); }
.rc-footer .button { flex: 1; }
.rc-ellipsis { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
.rc-money { font-variant-numeric: tabular-nums; text-align: right; white-space: nowrap; font-weight: 700; }
```

`specs/themes/theme-06/03.design/prototype/html/styles/receivable.css:43-81`

```css
/* CN-02 */
.rc-scroll { flex: 1; min-height: 0; overflow: hidden; }
.rc-section { margin: 0; padding: var(--c45-v2-space-4) var(--c45-v2-space-4) var(--c45-v2-space-2); color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-xs); font-weight: 700; letter-spacing: .4px; }
.rc-note { margin: 0; padding: var(--c45-v2-space-3) var(--c45-v2-space-4); color: var(--c45-v2-text-secondary); }
/* CN-02 bố cục chốt bằng /impeccable live 2026-11-18 (phương án 1: tiền còn nợ dẫn mắt, đơn gom trong một khung, đơn quá hạn tô nền) */
.rc-cn02 { background: var(--c45-v2-surface-canvas); }
.rc-cn02 .rc-section { padding-top: var(--c45-v2-space-5); letter-spacing: .04em; }
.rc-chead { display: grid; gap: var(--c45-v2-space-1); padding: var(--c45-v2-space-5) var(--c45-v2-space-4) var(--c45-v2-space-4); background: var(--c45-v2-surface-default); border-bottom: 1px solid var(--c45-v2-border-default); }
.rc-chead__who { display: flex; align-items: baseline; gap: var(--c45-v2-space-2); min-width: 0; }
.rc-chead__name { font-size: var(--rc-fs-lg); font-weight: 700; }
.rc-chead__phone { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-variant-numeric: tabular-nums; white-space: nowrap; }
.rc-chead__who .ds24-badge { align-self: center; flex: 0 0 auto; }
.rc-chead__owed { display: grid; gap: 2px; margin-top: var(--c45-v2-space-3); }
.rc-chead__label { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-weight: 600; }
.rc-chead__amount { text-align: left; font-size: var(--rc-fs-display); line-height: 1.1; letter-spacing: -0.02em; color: var(--c45-v2-text-primary); }
.rc-chead__sub { display: flex; align-items: center; gap: var(--c45-v2-space-1); color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); }
.rc-chead__warn { display: inline-flex; align-items: center; gap: var(--c45-v2-space-1); color: var(--c45-v2-text-danger); font-weight: 600; }
.rc-group { margin: 0 var(--c45-v2-space-4); background: var(--c45-v2-surface-default); border: 1px solid var(--c45-v2-border-default); border-radius: var(--c45-v2-radius-card); overflow: hidden; }
.rc-order { display: grid; grid-template-columns: 1fr auto 16px; align-items: center; gap: var(--c45-v2-space-3); width: 100%; min-height: 64px; padding: var(--c45-v2-space-3) var(--c45-v2-space-3) var(--c45-v2-space-3) var(--c45-v2-space-4); border: 0; border-top: 1px solid var(--c45-v2-border-default); background: transparent; font: inherit; color: inherit; text-align: left; cursor: pointer; }
.rc-order:first-child { border-top: 0; }
.rc-order.is-overdue { background: var(--c45-v2-danger-50); }
.rc-order:hover { background: var(--c45-v2-neutral-100); }
.rc-order:focus-visible { outline: 2px solid var(--c45-v2-focus-ring); outline-offset: -2px; }
.rc-order__main { display: grid; gap: var(--c45-v2-space-1); min-width: 0; }
.rc-order__code { font-weight: 700; font-variant-numeric: tabular-nums; }
.rc-order__main .rc-due { font-size: var(--rc-fs-sm); }
.rc-order__money { display: grid; justify-items: end; gap: 2px; font-variant-numeric: tabular-nums; }
.rc-order__owed { font-weight: 700; white-space: nowrap; }
.rc-order__total { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); white-space: nowrap; }
.rc-order__chev { display: inline-flex; color: var(--c45-v2-icon-muted); }
.rc-hist { display: grid; gap: 2px; padding: var(--c45-v2-space-3) var(--c45-v2-space-4); border-top: 1px solid var(--c45-v2-border-default); }
.rc-hist:first-child { border-top: 0; }
.rc-hist__title { font-weight: 600; font-variant-numeric: tabular-nums; }
.rc-hist__meta { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); }
.rc-more { width: 100%; min-height: var(--c45-v2-touch-minimum); border: 0; border-top: 1px solid var(--c45-v2-border-default); background: transparent; font: inherit; color: var(--c45-v2-text-brand); font-weight: 600; cursor: pointer; }
.rc-group > .rc-more:first-child { border-top: 0; }
.rc-blockerr { display: flex; flex-direction: column; align-items: center; gap: var(--c45-v2-space-2); padding: var(--c45-v2-space-5) var(--c45-v2-space-4); color: var(--c45-v2-text-secondary); }
.rc-blockerr p { margin: 0; }
.rc-toast { position: absolute; left: 0; right: 0; bottom: calc(var(--c45-v2-space-18) + var(--c45-v2-space-3)); }
```

**Ánh xạ phần tử → Flutter (CN-02):**

| Phần tử prototype | Flutter | Thông số |
|---|---|---|
| `page({title:'Công nợ khách hàng'})` | `Scaffold(backgroundColor: background)` + `VAppBar(title: 'Công nợ khách hàng', showBackButton: !split)` | |
| `.rc-chead` | `Container` nền `surface`, viền dưới 1 `borderDefault` | padding `20 16 16`; khoảng dòng 4 |
| `.rc-chead__who` | `Row(baseline)` | tên 16/700 = `VTypography.bodyDefault.copyWith(fontSize: 16, fontWeight: FontWeight.w700)` (DS không có bậc 16/700), `ellipsis`; SĐT 13 `textSecondary` tabular; `ReceivableInactiveBadge` |
| `.rc-chead__owed` | `Column` | margin trên 12; nhãn "Còn nợ" / "Không còn nợ" 13/600 `textSecondary`; số `formatVnd(outstandingMinor)` 32/700, cao dòng 1.1, `letterSpacing -0.64` (−0.02em), canh trái, tabular (DS không có 32 → ghi lý do) |
| `.rc-chead__sub` | `Row` | "`n` đơn ·" + (có quá hạn: icon cảnh báo 16 + "`m` quá hạn" 600 `danger`; không: "0 quá hạn" `textSecondary`); ẩn khi hết nợ |
| `.rc-section` (`cn02`) | `ReceivableSectionTitle` | padding `20 16 8`; 12/700 (`VTypography.caption` 12/600 → `w700`), `letterSpacing 0.48`, `textSecondary`; chữ "ĐƠN CÒN NỢ (cũ trước)", "LỊCH SỬ THU & CẤN TRỪ" |
| `.rc-group` | `Container` margin ngang 16, nền `surface`, viền 1, bo `card`, `clipBehavior` | |
| `.rc-order` | `InkWell` → `context.push('/sales/orders/<salesOrderId>')` | lưới `1fr auto 16`, khoảng 12; cao ≥ 64; padding `12 12 12 16`; viền trên 1 trừ dòng đầu; quá hạn nền `dangerBg`; trái: "`orderCode` · `dd/MM` (completedAt)" 14/700 tabular + `ReceivableDueBadge(orderDueLabel, fontSize 13)`; phải canh phải: "Còn nợ `formatVnd`" 14/700 + "Tổng `formatVnd(payableMinor)`" 13 `textSecondary`; chevron 16 `neutral400` |
| `.rc-note` | `Padding(12 16)` `Text` `textSecondary` | "Không còn đơn nào nợ", "Chưa có lần thu nào" |
| `historyRow` / `.rc-hist` | `Padding(12 16)` + `Column(gap 2)` + viền trên trừ dòng đầu | tiêu đề 14/600 tabular, meta 13 `textSecondary`. Chữ theo `kind` — **chép nguyên** `historyRow` ở trên, ánh xạ: `customerCollection` ↔ `collection` (`paymentMethodCode == 'cash'` → "Tiền mặt", còn lại "Chuyển khoản" + " `externalReference`" nếu có; meta 1 = "`dd/MM HH:mm` · `actorDisplayName`" (null → bỏ " · …"), meta 2 = "Vào: " + `allocations` "`orderCode` `formatVndBare`" nối ", "); `orderCollection` ↔ `order_payment`; `offset` (`sourceOrderCode` → `fromOrder`, `returnExchangeReference` → `returnCode`, `targetOrderCode` → `toOrder`, meta có người); `refund`. Giờ = `occurredAt.toLocal()` |
| `.rc-more` "Xem thêm" | `InkWell` cao ≥ 44, viền trên 1, chữ 600 `textBrand` | chỉ hiện khi `historyCursor != null`; `historyLoadingMore` → `VLoading` nhỏ |
| `.rc-blockerr` | `Column` giữa, padding `20 16`: "Không tải được" `textSecondary` + `VButton.secondary('Thử lại', onPressed: retryHistory)` | chỉ khối lịch sử |
| `.rc-footer` + `btn('Thu tiền', full)` | `SafeArea` + `Container` viền trên 1, padding `12 16`, `VButton(primary, 'Thu tiền', expand)` | chỉ khi `outstandingMinor > 0` **và** `hasPermission('receivable.collect')` |
| web `renderCn02` | cột trái CN-01 tô dòng `selectedId` (Task 3 đã có) | |
| (Quyết định 4) chi tiết lỗi | `ReceivableEmpty('Không tải được công nợ', 'Thử lại' → load)` | |

- [ ] **Bước 1: Test cubit đỏ** `customer_receivable_cubit_test.dart`: `load` gọi `getCustomer` và `history` song song (cả hai đang chờ cùng lúc); lịch sử lỗi + chi tiết được → `detailStatus ready`, `historyStatus error`; `retryHistory` chỉ gọi `history`; `loadMoreHistory` nối và gửi cursor; `reload` gọi lại cả hai, xoá lịch sử cũ.
- [ ] **Bước 2: Chạy → FAIL; cài; → PASS.**
- [ ] **Bước 3: Widget test đỏ** `cn02_test.dart` (390, dữ liệu fixtures):
  - `full`: "Anh Tuấn", "0901 234 567", "Còn nợ", "18.000.000 ₫", "3 đơn ·", "2 quá hạn", "DH-001 · …", "Còn nợ 4.000.000 ₫", "Tổng 4.000.000 ₫", "Quá hạn 8 ngày", "Thu 2.000.000 · Tiền mặt", "06/11 14:20 · Nguyễn An", "Vào: DH-002 2.000.000", nút "Thu tiền".
  - `after-offset` (đơn DH-002 1.500.000 + DH-003; lịch sử có `offset` 500.000 DH-001 → DH-002 phiếu #DT-0001): "Cấn trừ 500.000 · từ trả hàng đơn DH-001 (phiếu #DT-0001) sang đơn DH-002"; không có "DH-001 ·" trong khối đơn; "Còn nợ" "7.500.000 ₫".
  - `paid-off`: "Không còn nợ", "Không còn đơn nào nợ", **không** có "Thu tiền".
  - `block-error`: khối đơn có dữ liệu, "Không tải được" + "Thử lại" gọi `history` lần 2.
  - `no-history`: "Chưa có lần thu nào". `inactive`: "Ngừng hoạt động".
  - chạm dòng DH-002 → router nhận `/sales/orders/so-002` (dùng `GoRouter` test nhỏ ghi lại location).
  - thiếu quyền `receivable.collect` → không có "Thu tiền".
- [ ] **Bước 4: Cài trang + nối route `:customerId`; → PASS.**
- [ ] **Bước 5: Golden** nhóm `CN-02` như Task 3 Bước 7 (web: shell hai cột, cột trái chọn Anh Tuấn). So ảnh, sửa, ghi lệch.
- [ ] **Bước 6: Commit** `feat(receivable): T6-2b CN-02 công nợ của khách`

---

### Task 5: CN-03 thu tiền theo khách

**Files:**
- Create: `logic/customer_collection_cubit.dart`, `logic/customer_collection_state.dart`, `presentation/widgets/customer_collection_sheet.dart`
- Modify: `presentation/pages/customer_receivable_page.dart` (nối nút "Thu tiền"), `test/features/receivable/presentation/receivable_golden_test.dart`
- Test: `test/features/receivable/logic/customer_collection_cubit_test.dart`, `test/features/receivable/presentation/cn03_test.dart`

**Interfaces:**
- Consumes: Task 2 (`collectionPreview`, `recordCollection`, `kReceivableErrorMessages`, `formatVnd`, `formatVndBare`, `orderDueLabel`), Task 4 (`CustomerReceivableCubit.reload`), Task 3 (`ReceivableListCubit.refresh`, đọc bằng `context.read` nếu có trong cây), `IdempotencyKeyFactory` (`lib/core/iam/idempotency_key_factory.dart`).
- Produces:
  - `enum CollectionStep { form, confirm }`; `enum CollectionPhase { idle, submitting, error, changed, success }`
  - `class CustomerCollectionState { Set<String> selectedIds; int amountMinor; CollectionMethod method; String externalReference; CollectionStep step; CollectionPhase phase; String? errorMessage; String? idempotencyKey; CustomerCollectionResult? result; CollectionPreview preview; bool get isDirty => amountMinor > 0 || selectedIds.isNotEmpty; }`
  - `class CustomerCollectionCubit` — ctor `({required ReceivableRepository repository, required String customerId, required List<OpenReceivableOrder> orders, IdempotencyKeyFactory keyFactory = const UuidIdempotencyKeyFactory()})`; `void toggleOrder(String salesOrderId)`, `void toggleAll()`, `void setAmountText(String text)` (`MoneyFormatter.parseMinor`), `void setMethod(CollectionMethod m)`, `void setReference(String text)`, `void openConfirm()` (chỉ khi `preview.canSubmit`), `void backToForm()`, `Future<void> submit()`.
  - Mọi lệnh sửa (`toggle*`, `setAmountText`, `setMethod`, `setReference`) đặt `idempotencyKey = null`, `phase = idle`. `toggleOrder` / `toggleAll` đặt `amountMinor = preview.scopeTotal` của lựa chọn mới. `toggleAll`: đang chọn hết → bỏ hết; còn lại → chọn hết.
  - `submit()`: `step = form`, `phase = submitting`; khoá = `state.idempotencyKey ?? keyFactory.next('receivable-collection')` (lưu vào state **trước** khi gọi); request: `orderIds` = `preview.applicable` (thứ tự cũ trước), `expectedOutstandingMinor = preview.scopeTotal`, `externalReference` chỉ khi `manualBankTransfer`. Thành công → `success` + `result`. `RECEIVABLE_CHANGED` → `changed`. Lỗi khác → `error` + `errorMessage = e.userMessage(kReceivableErrorMessages)` cho mã có trong bảng, còn lại `'Không ghi nhận được. Thử lại?'`; giữ khoá.
  - `sealed class CollectionSheetOutcome` với ba lớp con: `CollectionCollected(CustomerCollectionResult result, int amountMinor)`, `CollectionNeedsReload()`, `CollectionCancelled()`.
  - `Future<CollectionSheetOutcome> showCustomerCollectionSheet(BuildContext context, {required String customerId, required String customerName, required List<OpenReceivableOrder> orders, ReceivableRepository? repository})` — gọi `showVAdaptiveSheet(title: null, isDismissible: false, enableDrag: false, …)`; sheet đóng không có giá trị (`null`) → `CollectionCancelled()`.
  - CN-02 xử lý: `CollectionCollected` → `VToast.show(title: 'Đã thu ${formatVnd(amount)} từ $customerName', message: '', type: VToastType.success)`, `cubit.reload()`, `ReceivableListCubit.refresh()`; `CollectionNeedsReload` → `cubit.reload()` + `refresh()`; `CollectionCancelled` → không làm gì.

**Ảnh đích:**

| Prototype 390 | Flutter 390 | Prototype 1280 | Flutter 1280 |
|---|---|---|---|
| ![](img/T6-2b/proto-CN-03-empty-390.png) `empty` | ![](img/T6-2b/flutter-CN-03-empty-390.png) | ![](img/T6-2b/proto-CN-03-empty-1280.png) | ![](img/T6-2b/flutter-CN-03-empty-1280.png) |
| ![](img/T6-2b/proto-CN-03-valid-390.png) `valid` | ![](img/T6-2b/flutter-CN-03-valid-390.png) | ![](img/T6-2b/proto-CN-03-valid-1280.png) | ![](img/T6-2b/flutter-CN-03-valid-1280.png) |
| ![](img/T6-2b/proto-CN-03-over-390.png) `over` | ![](img/T6-2b/flutter-CN-03-over-390.png) | ![](img/T6-2b/proto-CN-03-over-1280.png) | ![](img/T6-2b/flutter-CN-03-over-1280.png) |
| ![](img/T6-2b/proto-CN-03-transfer-390.png) `transfer` | ![](img/T6-2b/flutter-CN-03-transfer-390.png) | ![](img/T6-2b/proto-CN-03-transfer-1280.png) | ![](img/T6-2b/flutter-CN-03-transfer-1280.png) |
| ![](img/T6-2b/proto-CN-03-confirm-390.png) `confirm` | ![](img/T6-2b/flutter-CN-03-confirm-390.png) | ![](img/T6-2b/proto-CN-03-confirm-1280.png) | ![](img/T6-2b/flutter-CN-03-confirm-1280.png) |
| ![](img/T6-2b/proto-CN-03-submitting-390.png) `submitting` | ![](img/T6-2b/flutter-CN-03-submitting-390.png) | ![](img/T6-2b/proto-CN-03-submitting-1280.png) | ![](img/T6-2b/flutter-CN-03-submitting-1280.png) |
| ![](img/T6-2b/proto-CN-03-submit-error-390.png) `submit-error` | ![](img/T6-2b/flutter-CN-03-submit-error-390.png) | ![](img/T6-2b/proto-CN-03-submit-error-1280.png) | ![](img/T6-2b/flutter-CN-03-submit-error-1280.png) |
| ![](img/T6-2b/proto-CN-03-changed-390.png) `changed` | ![](img/T6-2b/flutter-CN-03-changed-390.png) | ![](img/T6-2b/proto-CN-03-changed-1280.png) | ![](img/T6-2b/flutter-CN-03-changed-1280.png) |
| ![](img/T6-2b/proto-CN-03-leave-confirm-390.png) `leave-confirm` | ![](img/T6-2b/flutter-CN-03-leave-confirm-390.png) | ![](img/T6-2b/proto-CN-03-leave-confirm-1280.png) | ![](img/T6-2b/flutter-CN-03-leave-confirm-1280.png) |
| ![](img/T6-2b/proto-CN-03-all-390.png) `all` | ![](img/T6-2b/flutter-CN-03-all-390.png) | ![](img/T6-2b/proto-CN-03-all-1280.png) | ![](img/T6-2b/flutter-CN-03-all-1280.png) |
| ![](img/T6-2b/proto-CN-03-one-390.png) `one` | ![](img/T6-2b/flutter-CN-03-one-390.png) | ![](img/T6-2b/proto-CN-03-one-1280.png) | ![](img/T6-2b/flutter-CN-03-one-1280.png) |
| ![](img/T6-2b/proto-CN-03-multi-390.png) `multi` | ![](img/T6-2b/flutter-CN-03-multi-390.png) | ![](img/T6-2b/proto-CN-03-multi-1280.png) | ![](img/T6-2b/flutter-CN-03-multi-1280.png) |
| ![](img/T6-2b/proto-CN-03-one-over-390.png) `one-over` | ![](img/T6-2b/flutter-CN-03-one-over-390.png) | ![](img/T6-2b/proto-CN-03-one-over-1280.png) | ![](img/T6-2b/flutter-CN-03-one-over-1280.png) |
| ![](img/T6-2b/proto-CN-03-one-confirm-390.png) `one-confirm` | ![](img/T6-2b/flutter-CN-03-one-confirm-390.png) | ![](img/T6-2b/proto-CN-03-one-confirm-1280.png) | ![](img/T6-2b/flutter-CN-03-one-confirm-1280.png) |
| ![](img/T6-2b/proto-CN-03-success-390.png) `success` | ![](img/T6-2b/flutter-CN-03-success-390.png) | ![](img/T6-2b/proto-CN-03-success-1280.png) | ![](img/T6-2b/flutter-CN-03-success-1280.png) |

**Code prototype (chép nguyên văn):**

`specs/themes/theme-06/03.design/prototype/html/app/ui.js:35-46`

```js
export function sheet({ title, body, actions = '', device }) {
  if (device === 'web') return dialog({ title, body, actions });
  return `<div class="sheet-backdrop"><section class="bottom-sheet rc-sheet" role="dialog" aria-modal="true" aria-label="${esc(title)}"><div class="sheet-handle"></div><div class="sheet-title"><h3>${esc(title)}</h3></div><div class="sheet-divider"></div><div class="sheet-content">${body}</div><div class="sheet-actions">${actions}</div></section></div>`;
}

export function dialog({ title, body = '', actions = '' }) {
  return `<div class="confirm-backdrop"><section class="confirm-dialog rc-dialog" role="dialog" aria-modal="true" aria-label="${esc(title)}"><h3>${esc(title)}</h3>${body ? `<div class="rc-dialog__body">${body}</div>` : ''}<div class="confirm-dialog-actions">${actions}</div></section></div>`;
}

export function toast(text) {
  return `<div class="toast rc-toast" role="status">${icon('check')}<span>${esc(text)}</span></div>`;
}
```

`specs/themes/theme-06/03.design/prototype/html/app/cn03.js:9-111`

```js
export const grp = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
const bare = (n) => formatVnd(n).replace(' ₫', '');

export const CN03_STATES = {
  empty: { amount: 0, selectedIds: [] },
  valid: { amount: 10e6, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  over: { amount: 18000001, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  transfer: { amount: 10e6, method: 'transfer', ref: 'FT2611180001', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  confirm: { amount: 10e6, overlay: 'confirm', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  submitting: { amount: 10e6, phase: 'submitting', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  'submit-error': { amount: 10e6, phase: 'error', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  changed: { amount: 10e6, overlay: 'changed', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  'leave-confirm': { amount: 10e6, overlay: 'leave', selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  all: { amount: 18e6, selectedIds: ['DH-001', 'DH-002', 'DH-003'] },
  one: { amount: 8e6, selectedIds: ['DH-002'] },
  multi: { amount: 5e6, selectedIds: ['DH-001', 'DH-003'] },
  'one-over': { amount: 8000001, selectedIds: ['DH-002'] },
  'one-confirm': { amount: 8e6, overlay: 'confirm', selectedIds: ['DH-002'] },
};

/** Thuần: phạm vi áp dụng = các đơn đã tick (giữ thứ tự cũ trước). Số tiền mặc định = Σ còn nợ các đơn đã tick (scopeTotal). */
export function cn03Scope(orders, selectedIds = []) {
  const applicable = orders.filter((o) => selectedIds.includes(o.id));
  return { applicable, scopeTotal: applicable.reduce((s, o) => s + o.outstandingMinor, 0), customerTotal: orders.reduce((s, o) => s + o.outstandingMinor, 0) };
}

/** Thuần: kết quả tính cho một số tiền (dùng cả khi gõ tay). */
export function cn03Calc(amount, orders, total, customerTotal = total) {
  const over = amount > total;
  const alloc = amount > 0 && !over ? allocateOldestFirst(orders, amount) : [];
  return { over, alloc, after: customerTotal - (over ? 0 : amount), canSubmit: amount > 0 && !over };
}

export function allocHtml(calc, orders) {
  if (!calc.alloc.length) return '';
  const code = (id) => orders.find((o) => o.id === id).code;
  return `<h4 class="rc-section rc-section--tight">SẼ TRỪ VÀO</h4>${calc.alloc.map((a) => `<div class="rc-alloc"><span>${esc(code(a.id))}</span><span class="rc-alloc__amt">${bare(a.allocatedMinor)}</span><span class="rc-alloc__res">${a.outstandingAfterMinor === 0 ? '→ hết nợ' : `→ còn ${bare(a.outstandingAfterMinor)}`}</span></div>`).join('')}<div class="rc-alloc-total"><span>Khách còn nợ sau khi thu</span><span class="rc-money">${formatVnd(calc.after)}</span></div>`;
}

/** Danh sách đơn có ô tick; kết quả chia nằm ngay trong từng dòng. Ô tick đầu danh sách = tất cả đơn (= trả hết). */
export function ordersHtml(allOrders, selectedIds, calc, lock = '') {
  const by = Object.fromEntries(calc.alloc.map((x) => [x.id, x]));
  const allOn = allOrders.length > 0 && allOrders.every((o) => selectedIds.includes(o.id));
  const someOn = selectedIds.length > 0 && !allOn;
  const total = allOrders.reduce((s, o) => s + o.outstandingMinor, 0);
  const master = `<button class="rw-master" type="button" role="checkbox" aria-checked="${allOn ? 'true' : someOn ? 'mixed' : 'false'}" data-pick-all${lock}>${k7CheckMark(allOn)}<span class="rw-master__label">Tất cả đơn · trả hết</span><span class="rw-money">${bare(total)}</span></button>`;
  const rows = allOrders.map((o) => {
    const on = selectedIds.includes(o.id);
    const a = by[o.id];
    const res = !on ? '<span class="rw-res rw-res--off">Không thu</span>'
      : a ? `<span class="rw-res">Trừ ${bare(a.allocatedMinor)} → ${a.outstandingAfterMinor === 0 ? 'hết nợ' : `còn ${bare(a.outstandingAfterMinor)}`}</span>`
      : calc.alloc.length ? '<span class="rw-res rw-res--off">Chưa nhận</span>' : '';
    return `<button class="rw-order${on ? ' is-on' : ''}" type="button" role="checkbox" aria-checked="${on}" data-pick="${esc(o.id)}"${lock}>${k7CheckMark(on)}<span class="rw-order__main"><span class="rw-order__code">${esc(o.code)}</span>${dueBadge(dueLabel(o.dueDate, TODAY))}</span><span class="rw-order__side"><span class="rw-money">Còn nợ ${bare(o.outstandingMinor)}</span>${res}</span></button>`;
  }).join('');
  return `<div class="rw-orders" role="group" aria-label="Chọn đơn nhận tiền">${master}${rows}</div>`;
}

export function derivedHtml(calc, picked = 0) {
  if (!picked) return '<small class="rc-hint">Chọn ít nhất một đơn để thu.</small>';
  return `${calc.over ? '<small class="rc-error" role="alert">Số tiền vượt quá tổng còn nợ của các đơn đã chọn.</small>' : ''}${calc.alloc.length ? `<div class="rw-after"><span>Khách còn nợ sau khi thu</span><span class="rw-money">${formatVnd(calc.after)}</span></div>` : ''}`;
}

function form({ amount, method = 'cash', ref = '', phase, selectedIds = [] }, allOrders, customerTotal) {
  const { applicable: orders, scopeTotal: total } = cn03Scope(allOrders, selectedIds);
  const calc = cn03Calc(amount, orders, total, customerTotal);
  const lock = phase === 'submitting' ? ' disabled' : '';
  const seg = [['cash', 'Tiền mặt'], ['transfer', 'Chuyển khoản']].map(([k, t]) => `<button type="button" class="ds-segment${k === method ? ' is-selected' : ''}" data-method="${k}" aria-pressed="${k === method}"${lock}>${t}</button>`).join('');
  return `<button class="rc-close" type="button" aria-label="Đóng" data-close>${icon('close')}</button>
  <p class="rw-who">${NAME} · Còn nợ ${formatVnd(customerTotal)}</p>
  <div data-region="cn03-orders">${ordersHtml(allOrders, selectedIds, calc, lock)}</div>
  <span class="rw-label">Số tiền</span>
  <div class="rw-amount"><input class="ds24-field__control" data-amount inputmode="numeric" autocomplete="off" aria-label="Số tiền" value="${amount ? grp(amount) : ''}"${lock}><span class="rw-amount__unit">đ</span></div>
  <div class="rc-method"><span class="rc-method__label">Phương thức</span><div class="ds-segmented" role="group" aria-label="Phương thức">${seg}</div></div>
  <div data-region="cn03-ref">${method === 'transfer' ? `<label class="ds24-field rc-field"><span>Mã giao dịch (Không bắt buộc)</span><input class="ds24-field__control" data-ref value="${esc(ref)}"${lock}></label>` : ''}</div>
  <div data-region="cn03-derived">${derivedHtml(calc, orders.length)}</div>
  ${phase === 'error' ? `<div class="rc-submit-error" role="alert"><span>Không ghi nhận được. Thử lại?</span>${btn('Thử lại', { kind: 'secondary', attrs: 'data-submit' })}</div>` : ''}`;
}

function actions(phase, canSubmit) {
  return `${btn('Quay lại', { kind: 'secondary', attrs: `data-close${phase === 'submitting' ? ' disabled' : ''}` })}${btn(phase === 'submitting' ? 'Đang ghi nhận...' : 'Xác nhận thu', { attrs: 'data-confirm', disabled: !canSubmit || phase === 'submitting' })}`;
}

export function renderCn03(state, device, opts = {}) {
  if (state === 'success') return renderCn02('afterCollect', device, { toast: `Đã thu ${formatVnd(10e6)} từ ${NAME}` });
  const st = { amount: 0, method: 'cash', ref: '', ...CN03_STATES[state] };
  if (opts.amount != null) st.amount = opts.amount;
  if (opts.selectedIds) st.selectedIds = opts.selectedIds;
  const { orders: allOrders } = tuanAt('before');
  const { applicable: orders, scopeTotal, customerTotal } = cn03Scope(allOrders, st.selectedIds);
  const calc = cn03Calc(st.amount, orders, scopeTotal, customerTotal);
  const base = renderCn02('full', device);
  const main = sheet({ title: 'Thu tiền', body: form(st, allOrders, customerTotal), actions: actions(st.phase, calc.canSubmit), device });
  let over = '';
  if (st.overlay === 'confirm') {
    const m = st.method === 'cash' ? 'Tiền mặt' : 'Chuyển khoản';
    over = sheet({ title: 'Xác nhận thu tiền?', body: `<p class="rc-confirm-line">Thu ${formatVnd(st.amount)} ${m} từ ${NAME}${orders.length === allOrders.length ? ' · tất cả đơn' : orders.length === 1 ? ` · đơn ${esc(orders[0].code)}` : ` · ${orders.length} đơn đã chọn`}</p>${allocHtml(calc, orders)}`, actions: `${btn('Quay lại', { kind: 'secondary' })}${btn('Xác nhận')}`, device }).replace('class="sheet-backdrop"', 'class="sheet-backdrop rc-top"').replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  } else if (st.overlay === 'changed') {
    over = dialog({ title: 'Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.', actions: btn('Tải lại') }).replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  } else if (st.overlay === 'leave') {
    over = dialog({ title: 'Bỏ khoản thu đang nhập?', actions: `${btn('Ở lại', { kind: 'secondary' })}${btn('Bỏ', { kind: 'danger' })}` }).replace('class="confirm-backdrop"', 'class="confirm-backdrop rc-top"');
  }
  return base + (st.overlay === 'confirm' ? '' : main) + over;
}
```

`specs/themes/theme-06/03.design/prototype/html/styles/cn03.css:1-32`

```css
/* CN-03 Thu tiền — phương án A "Đơn là biểu mẫu" (chốt 2026-11-18). Chỉ token --c45-v2-*; cỡ chữ: 13 / 14 / 22. */
.rw-who { margin: 0; color: var(--c45-v2-text-secondary); font-weight: 600; font-size: var(--rc-fs-sm); }
.rw-label { font-weight: 600; font-size: var(--rc-fs-sm); }
.rw-row { display: flex; align-items: center; justify-content: space-between; gap: var(--c45-v2-space-3); margin-bottom: calc(-1 * var(--c45-v2-space-2)); }
.rw-row--top { margin-bottom: 0; }
.rw-money { font-variant-numeric: tabular-nums; white-space: nowrap; font-weight: 700; font-size: var(--rc-fs-md); }
.rw-money--in { color: var(--c45-v2-text-success); }
.rw-money--off { color: var(--c45-v2-text-muted); font-weight: 600; }
.rw-money--done { color: var(--c45-v2-text-success); }
.rw-amount { display: flex; align-items: center; gap: var(--c45-v2-space-2); }
.rw-amount input { flex: 1; min-width: 0; text-align: right; font-variant-numeric: tabular-nums; font-size: 22px; font-weight: 700; }
.rw-amount__unit { font-weight: 700; font-size: var(--rc-fs-md); }
.rw-after { display: flex; justify-content: space-between; align-items: baseline; gap: var(--c45-v2-space-3); padding: var(--c45-v2-space-3) 0 var(--c45-v2-space-1); border-top: 1px solid var(--c45-v2-border-default); font-weight: 600; font-size: var(--rc-fs-md); }

/* A: dòng đơn mang kết quả chia */
.rw-orders { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); }
.rw-order { display: grid; grid-template-columns: var(--c45-v2-touch-minimum) minmax(0, 1fr) auto; align-items: center; gap: var(--c45-v2-space-2); width: 100%; min-height: 64px; padding: var(--c45-v2-space-2) var(--c45-v2-space-3) var(--c45-v2-space-2) 0; border: 1px solid var(--c45-v2-border-default); border-radius: var(--c45-v2-radius-card); background: var(--c45-v2-surface-default); text-align: left; font: inherit; color: inherit; cursor: pointer; }
.rw-order > .k7-check__box { margin: auto; }
.rw-order.is-on { border-color: var(--c45-v2-border-brand); background: var(--c45-v2-primary-50); }
.rw-order__main { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.rw-order__code { font-weight: 700; font-size: var(--rc-fs-md); }
.rw-order__main .rc-due { font-size: var(--rc-fs-sm); }
.rw-order__side { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }
.rw-res { color: var(--c45-v2-text-success); font-weight: 600; font-size: var(--rc-fs-sm); font-variant-numeric: tabular-nums; white-space: nowrap; }
.rw-res--off { color: var(--c45-v2-text-muted); }
.rw-order--static { grid-template-columns: minmax(0, 1fr) auto; padding: var(--c45-v2-space-2) var(--c45-v2-space-3); cursor: default; }
.rw-order--static.is-on { background: var(--c45-v2-surface-default); border-color: var(--c45-v2-border-default); }

.rw-master { display: grid; grid-template-columns: var(--c45-v2-touch-minimum) minmax(0, 1fr) auto; align-items: center; gap: var(--c45-v2-space-2); width: 100%; min-height: var(--c45-v2-touch-minimum); padding: 0 var(--c45-v2-space-3) 0 0; border: 0; background: transparent; font: inherit; color: inherit; text-align: left; cursor: pointer; }
.rw-master > .k7-check__box { margin: auto; }
.rw-master__label { font-weight: 600; font-size: var(--rc-fs-md); }
.rw-master:focus-visible, .rw-order:focus-visible { outline: 2px solid var(--c45-v2-focus-ring); outline-offset: 2px; }
```

`specs/themes/theme-06/03.design/prototype/html/styles/receivable.css:83-111`

```css
/* CN-03 */
.rc-sheet { position: relative; max-height: 92%; display: flex; flex-direction: column; }
.rc-sheet .sheet-content { overflow-y: auto; min-height: 0; padding: 0 var(--c45-v2-space-4); display: flex; flex-direction: column; gap: var(--c45-v2-space-3); }
.rc-sheet .sheet-actions, .rc-dialog .rc-actions { padding: var(--c45-v2-space-3) var(--c45-v2-space-4) var(--c45-v2-space-4); margin-top: 0; }
.rc-sheet .sheet-title { padding-right: 56px; }
.rc-dialog { position: relative; width: min(100%, 480px); }
.rc-dialog__body { display: flex; flex-direction: column; gap: var(--c45-v2-space-3); }
.rc-dialog .confirm-dialog-actions { margin-top: var(--c45-v2-space-4); }
.rc-top { z-index: 100; }
.rc-close { position: absolute; top: var(--c45-v2-space-2); right: var(--c45-v2-space-2); width: var(--c45-v2-touch-minimum); height: var(--c45-v2-touch-minimum); border: 0; background: transparent; color: var(--c45-v2-icon-secondary); cursor: pointer; display: grid; place-items: center; }
.rc-sheet .rc-close { top: calc(-1 * var(--c45-v2-space-1)); }
.rc-sub { margin: 0; color: var(--c45-v2-text-secondary); font-weight: 600; }
.rc-field > span:first-child { font-weight: 600; font-size: var(--rc-fs-sm); }
.rc-amount { display: flex; align-items: center; gap: var(--c45-v2-space-2); }
.rc-amount .ds24-field__control { flex: 1; text-align: right; font-variant-numeric: tabular-nums; font-size: var(--rc-fs-xl); font-weight: 700; }
.rc-amount__unit { font-weight: 700; font-size: var(--rc-fs-lg); }
.rc-payall { display: flex; justify-content: flex-end; }
.rc-method { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); }
.rc-method__label { font-weight: 600; font-size: var(--rc-fs-sm); }
.rc-error { color: var(--c45-v2-text-danger); font-weight: 600; }
.rc-section--tight { padding-left: 0; padding-right: 0; }
.rc-alloc { display: grid; grid-template-columns: 64px 1fr auto; gap: var(--c45-v2-space-2); padding: var(--c45-v2-space-1) 0; font-variant-numeric: tabular-nums; }
.rc-alloc__amt { text-align: right; font-weight: 600; }
.rc-alloc__res { color: var(--c45-v2-text-secondary); min-width: 108px; }
.rc-alloc-total { display: flex; justify-content: space-between; align-items: baseline; padding-top: var(--c45-v2-space-2); border-top: 1px solid var(--c45-v2-border-default); font-weight: 600; }
.rc-submit-error { display: flex; align-items: center; justify-content: space-between; gap: var(--c45-v2-space-2); color: var(--c45-v2-text-danger); font-weight: 600; }
.rc-confirm-line { margin: 0; font-weight: 600; }
.rc-sheet .sheet-handle { background: var(--c45-v2-neutral-300); }
.rc-sheet .sheet-content { padding-top: var(--c45-v2-space-3); }
```

`specs/themes/theme-06/03.design/prototype/html/styles/receivable.css:160-162`

```css
.rc-hint { color: var(--c45-v2-text-secondary); font-size: var(--rc-fs-sm); font-weight: 600; }
.rc-dialog { max-height: calc(100% - 2 * var(--c45-v2-space-4)); display: flex; flex-direction: column; }
.rc-dialog__body { overflow-y: auto; min-height: 0; }
```

**Ánh xạ phần tử → Flutter (CN-03):**

| Phần tử prototype | Flutter | Thông số |
|---|---|---|
| `sheet()` / `dialog()` (web) | `showVAdaptiveSheet` (iPhone sheet đáy, ≥ desktop hộp thoại) | sheet cao tối đa 92%; nội dung cuộn, padding ngang 16, khoảng 12; tiêu đề do widget tự vẽ (để đổi "Thu tiền" ↔ "Xác nhận thu tiền?") |
| `.rc-close` | `IconButton` 44×44 góc trên phải, icon đóng `textMuted` | cùng hành vi "Quay lại" (hỏi khi `isDirty`) |
| `.rw-who` | `Text` 13/600 `textSecondary` | "`tên` · Còn nợ `formatVnd(customerTotal)`" |
| `.rw-master` | `Semantics(checked/mixed)` + `InkWell` cao ≥ 44 | cột 44 \| 1fr \| auto; `VCheckbox(value: allOn, …)` (một phần → `null` nếu `VCheckbox` hỗ trợ tristate, không thì `false` + `semanticLabel` "một phần"); "Tất cả đơn · trả hết" 14/600; `formatVndBare(customerTotal)` 14/700 tabular |
| `.rw-order` | `InkWell` + `Container` | cột 44 \| 1fr \| auto, khoảng 8; cao ≥ 64; padding `8 12 8 0`; viền 1 `borderDefault`, bo `card`, nền `surface`; đang tick: viền `borderBrand`, nền `surfaceBrand`; trái: mã 14/700 + `ReceivableDueBadge(fontSize 13)` (nhãn **không** xuống hàng: `softWrap:false`, xem Review Focus 3); phải: "Còn nợ `bare`" 14/700 + kết quả 13/600 tabular: không tick "Không thu" `textMuted`; có phần chia "Trừ `bare` → hết nợ" / "→ còn `bare`" `success`; tick nhưng chưa nhận "Chưa nhận" `textMuted`. Khoá khi `submitting` |
| `.rw-label` + `.rw-amount` | "Số tiền" 13/600; `VMoneyField(controller, suffixText: 'đ')` | chữ số 22/700 canh phải tabular (`VTypography.headingH2`); gõ → `setAmountText`; controller cập nhật khi tick (giữ con trỏ cuối) |
| `.rc-method` | "Phương thức" 13/600 + `VSegmentedControl(segments: ['Tiền mặt','Chuyển khoản'])` | |
| `cn03-ref` | `VTextField(label: 'Mã giao dịch (Không bắt buộc)')` | chỉ khi `manualBankTransfer` |
| `derivedHtml` | chưa tick: "Chọn ít nhất một đơn để thu." 13/600 `textSecondary`; vượt: "Số tiền vượt quá tổng còn nợ của các đơn đã chọn." 600 `danger` (`Semantics(liveRegion)`); có chia: hàng "Khách còn nợ sau khi thu" ↔ `formatVnd(afterMinor)` 14/600 viền trên 1, padding `12 0 4` | |
| `.rc-submit-error` | `Row(spaceBetween)`: `errorMessage` 600 `danger` + `VButton.secondary('Thử lại', submit)` | `phase == error` |
| `actions()` | `Row` 2 nút giãn đều: `VButton.secondary('Quay lại')`, `VButton.primary('Xác nhận thu' / 'Đang ghi nhận...')` | khoá khi `!canSubmit` hoặc `submitting`; padding `12 16 16`; "Xác nhận thu" → `openConfirm()` |
| `overlay === 'confirm'` | cùng sheet, `step == confirm`: tiêu đề "Xác nhận thu tiền?"; `.rc-confirm-line` 600: "Thu `formatVnd` `Tiền mặt|Chuyển khoản` từ `tên`" + (" · tất cả đơn" \| " · đơn `mã`" \| " · `n` đơn đã chọn"); `allocHtml` (tiêu đề "SẼ TRỪ VÀO" `ReceivableSectionTitle` không padding ngang; dòng lưới 64 \| 1fr \| auto(min 108): mã, `bare` 600 canh phải, "→ hết nợ" / "→ còn `bare`" `textSecondary`; tổng "Khách còn nợ sau khi thu" ↔ `formatVnd` viền trên); nút `Quay lại` (`backToForm`) / `Xác nhận` (`submit`) | |
| `overlay === 'changed'` | `showDialog` → `VModal`/hộp DS: tiêu đề "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại.", một nút "Tải lại" → đóng hộp + sheet với `CollectionNeedsReload()` | |
| `overlay === 'leave'` | hộp "Bỏ khoản thu đang nhập?" — "Ở lại" (secondary) / "Bỏ" (danger) | `PopScope(canPop: !isDirty)`; cả nút đóng, "Quay lại" (bước form), phím lùi đều qua đây; không hỏi khi `!isDirty` |
| `success` | đóng sheet `CollectionCollected` → CN-02 tải lại + toast | ảnh `success` = CN-02 sau thu + toast |

- [ ] **Bước 1: Test cubit đỏ** `customer_collection_cubit_test.dart` (orders = `tuanOrders`, key factory giả trả `k1`, `k2`, …):
  - khởi tạo: không tick, `amountMinor 0`, `!preview.canSubmit`.
  - `toggle resets amount to scope total`: `setAmountText('5.000.000')` sau khi tick `so-001`, rồi `toggleOrder('so-003')` → `amountMinor == 10.000.000`.
  - `toggleAll` → 3 đơn, 18.000.000; lần 2 → rỗng, 0.
  - `untick all locks submit`: tick `so-002` rồi bỏ → `amountMinor 0`, `!canSubmit`.
  - `setAmountText('10.000.000đ')` → 10.000.000; `'abc'` → 0.
  - vượt: tick `so-002`, `setAmountText('8000001')` → `preview.over`, `openConfirm()` không đổi `step`.
  - `submit` thành công: request `orderIds ['so-001','so-002','so-003']` (dù tick theo thứ tự khác), `expectedOutstandingMinor 18.000.000`, `amountMinor 10.000.000`, `method cash`, `externalReference null`, `idempotencyKey 'k1'` → `success`.
  - chuyển khoản: `setMethod(manualBankTransfer)`, `setReference(' FT2611180001 ')` → request `externalReference 'FT2611180001'`; về `cash` → `null`.
  - `retry keeps idempotency key`: lỗi `NETWORK_ERROR` → `error`, `errorMessage 'Không ghi nhận được. Thử lại?'`; `submit()` lại → vẫn `'k1'`.
  - `edit after error makes new key`: sau lỗi, `setAmountText('9.000.000')`, `submit()` → `'k2'`.
  - `RECEIVABLE_CHANGED` → `changed`; `OVERPAYMENT_NOT_ALLOWED` → `error` + "Số tiền vượt quá tổng còn nợ của khách.".
  - đang `submitting`: gọi `submit()` lần 2 không tạo lời gọi thứ 2.
- [ ] **Bước 2: Chạy → FAIL; cài; → PASS.**
- [ ] **Bước 3: Widget test đỏ** `cn03_test.dart` (390 và 1280; CN-02 Anh Tuấn → bấm "Thu tiền"):
  - mở: "Thu tiền", "Anh Tuấn · Còn nợ 18.000.000 ₫", "Tất cả đơn · trả hết", "Chọn ít nhất một đơn để thu.", nút "Xác nhận thu" khoá.
  - chạm "Tất cả đơn · trả hết" rồi sửa ô thành 10.000.000 → dòng DH-001 "Trừ 4.000.000 → hết nợ", DH-002 "Trừ 6.000.000 → còn 2.000.000", DH-003 "Chưa nhận", "Khách còn nợ sau khi thu" "8.000.000 ₫".
  - "Chuyển khoản" → hiện "Mã giao dịch (Không bắt buộc)".
  - "Xác nhận thu" → "Xác nhận thu tiền?", "Thu 10.000.000 ₫ Tiền mặt từ Anh Tuấn · tất cả đơn", "SẼ TRỪ VÀO"; "Xác nhận" → fake nhận đúng request; sheet đóng; toast "Đã thu 10.000.000 ₫ từ Anh Tuấn"; `getCustomer` gọi lần 2.
  - `pay all then paid-off`: tick tất cả, xác nhận; fake lần tải sau trả công nợ 0 → "Không còn nợ", không có "Thu tiền"; fake `list` lần sau không còn Anh Tuấn → (web 1280) cột trái không còn "Anh Tuấn".
  - lỗi `RECEIVABLE_CHANGED` → hộp "Công nợ của khách vừa thay đổi. Hãy tải lại rồi thử lại." → "Tải lại" → sheet đóng, `getCustomer` gọi lại.
  - đã tick rồi bấm đóng → "Bỏ khoản thu đang nhập?"; "Ở lại" giữ sheet; "Bỏ" đóng. Chưa nhập gì bấm đóng → đóng ngay.
- [ ] **Bước 4: Cài sheet + nối nút CN-02; → PASS.**
- [ ] **Bước 5: Golden** nhóm `CN-03` (15 ca × 2 khổ; ca dữ liệu theo `CN03_STATES` ở trên; `submitting` giữ `Completer`; `changed` / `leave-confirm` mở hộp; `success` = CN-02 sau thu + toast). So ảnh, sửa, ghi lệch.
- [ ] **Bước 6: Commit** `feat(receivable): T6-2b CN-03 thu tiền theo khách`

---

### Task 6: Kiểm cả gói, cập nhật tài liệu

**Files:** Modify `docs/refactor/PLAN.md` (bảng Theme 6), `docs/02-yeu-cau/TH-06-cong-no.md` (5.1 nếu route/chữ đổi; 9.4 dòng T6-2 tách thành T6-2b / T6-2c), file plan này (mục Kết quả).

- [ ] **Bước 1:** `cd apps/erp && flutter analyze && flutter test test/features/receivable test/features/more` → sạch, PASS. Chạy cả `flutter test` một lần; lỗi ngoài `receivable` / `more` ghi vào Kết quả (phần đổi/trả đã biết hỏng từ T6-1b, T6-2c sửa).
- [ ] **Bước 2: Chạy tay trên Supabase local (người dùng)** — dữ liệu ví dụ 2.3: menu Thêm → "Công nợ phải thu" → Anh Tuấn → thu 10.000.000 tiền mặt (tick tất cả, sửa số) → CN-02 còn 8.000.000, lịch sử có dòng mới có tên người; thu "Tất cả đơn · trả hết" → khách biến khỏi CN-01. Làm trên iPhone (simulator) và web (Chrome ≥ 1280). Ảnh lỗi → `img/T6-2b/user-<SCR>-<mô tả>.png`.
- [ ] **Bước 3: PLAN.md** — dòng **T6-2b** cột Làm → ✅ kèm commit; dòng "Trạng thái" Theme 6 cập nhật (dòng T6-2b / T6-2c đã tách lúc viết plan).
- [ ] **Bước 4: GitNexus** `detect_changes({scope: "compare", base_ref: "main"})` — chỉ symbol của `receivable`, `kMoreEntries`, router, DI; ghi vào Kết quả.
- [ ] **Bước 5: Commit** `docs(refactor): T6-2b kết quả, tách T6-2c` (chỉ các file của plan; nhánh đang có thay đổi khác chưa commit).

---

## Self-review (người viết plan)

- **Spec coverage:** US-01.1/01.2 (CN-01, hero quá hạn = lọc, tìm, tải thêm, trống, lỗi) → Task 3; US-01.3 (CN-02, mọi loại dòng lịch sử, khối lỗi riêng, ẩn "Thu tiền" khi hết nợ, chạm đơn → SG-09) → Task 4; US-02.1 (CN-03 tick đơn, chia cũ trước, vượt, xác nhận, chống trùng, `RECEIVABLE_CHANGED`, hỏi khi rời) → Task 5; US-04.1 menu Thêm → Task 3; 5.6 (≥ 44, tabular, icon + chữ) → Global Constraints + bảng ánh xạ; 6.1–6.3 → Task 2; 9.3 phần CN-01/02/03 + `allocateOldestFirst` → Task 2–5.
- **Chưa làm có chủ ý (T6-2c):** SG-13 cấn trừ, SG-09 / 09b / 09c / 14, PT-07 (`get_customer_receivable_summary`), bỏ sheet thu một đơn, `/impeccable audit`, kịch bản 9.1 đủ 6 bước.
- **Nhất quán tên:** `ReceivableRepository.{list,getCustomer,history,recordCollection}`, `collectionPreview`, `orderDueLabel` / `customerDueLabel`, `formatVnd` / `formatVndBare`, `CollectionSheetOutcome`, `showCustomerCollectionSheet` dùng giống nhau ở Task 2–5.

## Kết quả

**Phiên code 2026-11-19 (Claude Sonnet 5.5).** Commit: `47e6e75e7` (Task 2), `63ec503fe` (Task 3), `c93e9881d` (Task 4), `8920fd120` (Task 5). Task 1 (DB) **chưa commit**.

**Task 1 (DB) — chưa xác minh.** Đã viết: ca A14 trong `supabase/tests/receivable_th06.sql`, migration `20261125001_receivable_history_actor_name.sql`, sửa REGISTRY (owner `list_customer_receivable_history`) và TH-06 6.2. Chưa chạy `psql` / `supabase db reset` (lệnh DB người dùng tự chạy) nên **chưa thấy A14 đỏ rồi xanh**. Chưa commit vì migration phụ thuộc file T6-1b chưa commit, REGISTRY / TH-06 còn lẫn thay đổi khác. Người dùng chạy: `psql "$DB_URL" -f supabase/tests/receivable_th06.sql` (trước migration → `FAIL: A14`), `supabase db reset`, chạy lại test A + B.

**GitNexus.** `impact kMoreEntries` → LOW (0 dependants); `impact appRouter` → LOW (0); `impact configureDependencies` → "not found" (index cũ). `_hasTenantPermission` (CRITICAL, 1865 caller) **không sửa**, chỉ truyền tham chiếu vào `receivableRoutes`. `detect_changes -s compare -b 26a4ef78b` → 41 file, 26 symbol, 0 process, risk low (code: `appRouter`, `kMoreEntries`; còn lại là tài liệu).

**Test.** `flutter test test/features/receivable test/features/more` → 163 PASS. Golden: 62 ảnh `flutter-CN-0x-*` (CN-01 20, CN-02 12, CN-03 30) cạnh ảnh `proto-…`.

**Lệch plan + lý do**
- Tên trùng: widget CN-02 đặt `CustomerReceivableDetailPage` (model `CustomerReceivablePage` ở Task 2 đã dùng tên đó).
- CN-03 không dùng `showVAdaptiveSheet`: hộp thoại DS có nút Đóng riêng đóng thẳng, bỏ qua hỏi "Bỏ khoản thu đang nhập?". Tự chọn `Dialog` (≥ `VBreakpoints.desktop`) / `showVBottomSheet`.
- Ô số tiền dùng `VTextField` + bộ định dạng dấu chấm (không dùng `VMoneyField`: DS định dạng dấu phẩy, prototype dấu chấm).
- Nhãn hạn trong dòng đơn CN-03 được xuống hàng (ảnh `proto-CN-03-valid-390` xuống hàng "Quá hạn / 3 ngày"); CN-01 / CN-02 vẫn không xuống hàng.
- Nút xoá tìm dùng `IconButton` 44×44 tự dựng (`VSearchBar.onClear` chỉ có icon 20 px).
- Lọc / tìm không hiện khung chờ (giữ danh sách cũ) để không mất ô tìm đang gõ; `load()` mới hiện khung chờ.
- "Xem thêm" ở lịch sử chỉ hiện khi còn `cursor` (prototype luôn hiện).
- Golden nạp font Inter của DS (mặc định Ahem rộng, tràn giả); icon font không nạp nên icon hiện ô vuông (giống mọi golden khác của dự án). Toast `VToast` nổi đáy, đè lên nút "Thu tiền" (prototype đặt trên footer).
- Test widget CN-02 / CN-03 viết sau trang (không đỏ trước); test cubit viết trước và đã thấy đỏ.
- Fixtures thêm SĐT Hưng Phát / Chị Lan và ngày hoàn thành đơn theo prototype.

**Toàn bộ `flutter test` (2026-11-19).** 3832 PASS / 64 FAIL, không lỗi nào ở `receivable`. 2 lỗi `store_shell_test` do mục menu mới làm chỉ số sub-entry lệch +1 → đã sửa (commit riêng). Còn lại ngoài phạm vi: `my_account` / `pricing` / `tenant_admin` (9 lỗi) **cũng đỏ ở commit `26a4ef78b` trước khi làm** (chạy trong worktree tạm); `catalog` (42) và `inventory` (11) chưa kiểm ở baseline, không đụng file nào tôi sửa. `flutter analyze` toàn app: 263 info/warning sẵn có, phần `receivable` chỉ còn 1 info (`fake_async` chưa khai báo dev_dependency, các test khác cũng import như vậy).

**Việc còn lại (người dùng).** Chạy DB cho Task 1; chạy tay 9.1 trên iPhone simulator + Chrome (Task 6 Bước 2); không commit tài liệu vì `PLAN.md`, TH-06 còn lẫn thay đổi T6-1b chưa commit (đã sửa nội dung, chưa `git add`).

## Review

### R1 — 2026-11-19 · 🔄 cần sửa 1 việc + chờ kết quả DB

**Đã kiểm.**
- So ảnh trước khi đọc code: `CN-01` all / overdue-1280 / long-390, `CN-02` full, `CN-03` valid / confirm / empty-1280 / success. Bố cục, thứ tự, chữ khớp prototype. Icon hiện ô vuông là do golden không nạp font icon (như mọi golden khác). Thanh trạng thái và nút lùi chỉ có ở prototype (golden dựng trang không có ngăn trước).
- Đọc code: repository, 3 cubit, sheet CN-03, route / shell, diff `app_router.dart`, `more_entries.dart`, `injection.dart`, `store_shell_test.dart`. Migration `20261125001` so với thân gốc `20261124001:562–687`: chỉ khác `create or replace` và một dòng `actorDisplayName`.
- `flutter analyze` (receivable, more, router, di): chỉ 1 info `fake_async` (dự án cũng dùng như vậy ở test khác). `flutter test test/features/receivable test/features/more test/features/dashboard`: **184 PASS**.
- Review Focus 1–5 đều có test (`retry keeps idempotency key`, `edit after error makes new key`, `toggle resets amount to scope total`, `untick all locks submit`, `long 390`, `debounces search`, `drops stale response`, `pay all then paid-off`).
- Các chỗ lệch plan ghi ở Kết quả đều hợp lý: dùng `Dialog` / `showVBottomSheet` vì nút đóng của hộp thoại DS không hỏi "Bỏ khoản thu đang nhập?"; ô tiền dùng `VTextField` với dấu chấm; tên `CustomerReceivableDetailPage`; "Xem thêm" chỉ hiện khi còn cursor.

**Cần sửa**

1. **(Trung bình) CN-01: tải thêm trong lúc đang đổi lọc / tìm làm lẫn dữ liệu** — `receivable_list_cubit.dart`. `toggleOverdue()`, `setQuery()` (trong 300 ms chờ) và `clearQuery()` đổi `filter` / `query` nhưng vẫn giữ `nextCursor` cũ và `status = ready`. Nếu người dùng đang ở gần cuối danh sách (> 50 khách), `loadMore()` sẽ chạy và:
   - gửi cursor của lần lọc cũ kèm lọc / từ khoá mới;
   - tăng `_requestId`, nên kết quả của `_fetch` mới bị bỏ;
   - kết quả: danh sách = các khách của lọc cũ + một trang của lọc mới, trong khi ô hero đang báo "đang lọc Quá hạn".

   Cách sửa:
   - Khi đổi lọc / tìm (trước khi gọi `_fetch`), đặt `nextCursor: () => null` để `loadMore` không chạy được.
   - Cho `loadMore` dùng bộ đếm riêng (`_moreId`) để không làm mất kết quả của `_fetch`; `_fetch` tăng cả hai bộ đếm để trang tải thêm cũ về muộn cũng bị bỏ.
   - Thêm test `loadMore bị chặn khi đang đổi lọc`: có `nextCursor`, gọi `toggleOverdue()` (giữ phản hồi bằng `Completer`), gọi `loadMore()` → không có lời gọi `list` mang cursor; xong `_fetch` thì `items` = kết quả lọc mới.

**Chưa xác minh (người dùng chạy local)**

2. **Task 1 DB.** Chưa thấy A14 đỏ rồi xanh. Cần chạy:
   - `psql "$DB_URL" -f supabase/tests/receivable_th06.sql` khi **chưa** có migration 20261125001 (hoặc trước `db reset`) → phải ra `FAIL: A14`;
   - `supabase db reset`, rồi chạy lại test → `receivable_th06: OK`.

   Gửi lại kết quả để chốt. Lưu ý: `receivable_th06.sql` có **hai nhãn A14** (dòng ~677 "tên người thu" và ~769 "khách ngừng hoạt động"). Đổi nhãn sau thành A15 để thông báo lỗi không trùng.

**Gợi ý (không bắt buộc)**

- Toast "Đã thu …" đè lên nút "Thu tiền" (đã ghi ở Kết quả). Nếu `VToast` / `SnackBar` cho đặt lề dưới thì đẩy lên trên thanh dưới như prototype (`rc-toast`: đáy 72 + 12).
- `_GroupedDigitsFormatter`: gõ quá 19 chữ số thì `int.tryParse` trả `null` và ô hiện `0`. Có thể chặn độ dài (ví dụ tối đa 15 chữ số).

**Commit / tài liệu.** Task 1 (migration, A14, REGISTRY, TH-06 6.2), file plan này, ảnh `img/T6-2b/proto-*` và phần sửa `PLAN.md` vẫn chưa commit. Commit sau khi DB xanh, cùng hoặc sau commit T6-1b (migration 20261125001 phụ thuộc 20261124002).

### R2 — 2026-11-19 · 🔄 Flutter đạt, chờ kết quả DB

- **R1-1 đã sửa** (`1c277f202`):
  - `toggleOverdue` / `setQuery` / `clearQuery` xoá `nextCursor`;
  - `loadMore` dùng bộ đếm riêng `_moreId`, `_fetch` tăng cả hai bộ đếm.
  - Hai test mới: `loadMore bị chặn khi đang đổi lọc`, `loadMore cũ về muộn không đè kết quả của lọc mới`. Cả hai bám đúng tình huống lỗi.
- Đổi nhãn ca SQL: ca tên người thu thành **A16** (A15 đã có sẵn), A14 giữ cho "khách ngừng hoạt động". Không còn nhãn trùng.
- `flutter test test/features/receivable`: **154 PASS**. `flutter analyze lib/features/receivable`: sạch.
- **Còn lại:** chưa có kết quả chạy DB của Task 1 (R1-2). Đổi nhãn nên kỳ vọng mới là: trước migration ra `FAIL: A16`; sau `supabase db reset` ra `receivable_th06: OK`. Có kết quả thì Review ✅.

### R3 — 2026-11-19 · ✅ đạt

- **Task 1 DB đã xác minh:**
  - trước migration `20261125001`: `tools/db_check.sh --no-reset receivable_th06` ra `FAIL: A16` (thiếu `actorDisplayName`);
  - sau `tools/db_check.sh receivable_th06` (reset + plpgsql_check + test): `receivable_th06: OK`, chỉ còn 2 nợ đã biết.
- Sửa test A16 (theo yêu cầu người dùng): giá trị kỳ vọng tính qua `public._th06_val` vì `iam._member_display_name` đã thu quyền của `authenticated`. Migration không đổi.
- Flutter giữ kết quả R2 (154 PASS, analyze sạch).
- **Còn phải commit:** migration `20261125001`, `receivable_th06.sql`, REGISTRY, TH-06 6.2, file plan, ảnh `img/T6-2b/proto-*`, PLAN.md. Commit cùng hoặc sau T6-1b.
