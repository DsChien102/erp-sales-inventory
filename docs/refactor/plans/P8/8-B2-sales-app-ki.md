# 8-B2 — Sales: sửa app theo TH-05 (bỏ nợ cũ / QR / cấn trừ / chính sách trống / "Hoàn tất phiếu", mặc định Tiền mặt, nháp: tải thêm, tìm server, "Tạo bởi")

> Theme 5 (mã cũ P8) · Bước (b) sửa theo TH-05, phần app · Gồm: KI-07, KI-08, KI-10, KI-17, KI-18, KI-21, KI-22, phần sót từ 8-A1 (Q8 `REFERENCE_UNAVAILABLE`, câu "Không xóa được đơn nháp"); thêm 2 sửa SQL nhỏ cho danh sách nháp.
> Trạng thái: Plan ✅ (viết 2026-11-07, duyệt 2026-11-07) | Làm ✅ 2026-11-07 | Review ✅ R2 2026-11-08
> Trước: 8-B1 (dùng chung `supabase/tests/sales_th05.sql`). Sau: 8-B3 (Thu tiền), 8-C.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) US-01.7 (FR-01, FR-02, FR-04, EC-01, EC-02), SG-01, SG-06, SG-09, SG-13 (EP-06 FR-01, FR-03), SG-14 (US-06.7 FR-02), SG-16, 7.3 (KI-07, 08, 10, 17, 18, 21, 22); PLAN.md "Plan xoá / tách / thay code cũ: test giữ hành vi trước", "Quy tắc migration". Mẫu: [8-A4](8-A4-sales-huy-doi-tra.md) (bảng "Đang làm gì", Task 0), `logic/sales_order_list_cubit.dart:160-215` (tải thêm theo `nextCursor`).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, test, impact). **Không commit**. **Không chạy SQL, không reset DB, không push** (mục 7.2 là của người dùng). **Không ghi mục 10**.

## 1. Mục tiêu

- Màn bán hàng không còn chữ / khối nói tới tính năng chưa có: "Nợ cũ", "Xem công nợ", "Công nợ cũ của khách" trên PDF, "Cấn trừ công nợ hiện tại", QR mẫu, "Chưa cấu hình chính sách đổi/trả", "Hoàn tất phiếu".
- Quyết toán đổi/trả mặc định Tiền mặt (như thanh toán).
- SG-01: trang 25, tải thêm khi cuộn; tìm và tab "Đơn của tôi" lọc ở server; "Tạo bởi" hiện tên người tạo cả với nháp của người khác.

**Không làm:** màn Thu tiền (8-B3); bố cục web của SG-01 (8-W); chép kiểu DTO (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | PDF phiếu bán / phiếu đổi trả in "Công nợ cũ của khách" + "Tổng công nợ"; server không bao giờ gửi `existingDebtMinor` ⇒ luôn 0 | **Người dùng chốt 2026-11-07:** bỏ cùng KI-07; giữ "Còn phải thu" / "Công nợ phát sinh từ đơn" như mẫu SG-16; app thôi đọc `existingDebtMinor` |
| Q2 | KI-21 tải thêm + ô tìm (đang lọc trên máy, chỉ trong nháp đã tải) | **Người dùng chốt 2026-11-07:** `list_sales_order_drafts` thêm `p_search` (bỏ dấu: tên khách, SĐT, ghi chú) + `p_created_by`; app trang 25, tải thêm theo `next_cursor`; gõ tìm / đổi tab ⇒ tải lại từ trang 1 |
| Q3 | Tab "Đơn của tôi" | Đang lọc **trên máy** theo `savedByActorId` (người lưu cuối) ở `presentation/widgets/sales_draft_list_body.dart:94-96`. **Người dùng chốt 2026-11-07:** lọc ở server theo **người tạo** (`created_by_user_id`). **Đổi có chủ đích:** nháp người khác tạo mà tôi lưu lại không còn ở "Đơn của tôi" |
| Q4 | KI-22 "Tạo bởi" | **Người dùng chốt 2026-11-07:** `sales._draft_payload` thêm `created_by_user_id` + `created_by_name` (`iam._member_display_name`); app bỏ `actorNameResolver`. **Đổi có chủ đích:** hiện người tạo thay người lưu cuối (US-01.7 FR-02) |
| Q5 | Xoá nháp gặp `REFERENCE_UNAVAILABLE` (8-A1 Q8) | Xử lý như `STALE_DATA`: `needsReload = true`, câu "Đơn nháp đã thay đổi. Vui lòng tải lại danh sách." (EC-01) |
| Q6 | Câu "Không hủy được đơn nháp" | Đổi thành "Không xóa được đơn nháp" (US-01.7 FR-04) |
| Q7 | KI-10: `reasonCode` / `conditionCode` trong dòng trả | Bỏ khỏi state / chỉnh sửa / kiểm; **giữ khoá** trong JSON gửi server và trong chuỗi băm của attempt factory, giá trị luôn `null` (hash cùng đầu vào không đổi; server đọc `->>` vẫn ra `null`) |
| Q8 | KI-17: `ReturnExchangeMutationRequest` | **Giữ** — `discard` (huỷ phiếu nháp) còn dùng. Xoá `complete` ở repository / factory / cubit / trang / body |
| Q9 | KI-08: khối "Cấn trừ" | Bỏ hàng có `VSwitch` `sw_sg12_offset_debt` + câu "Sẽ áp dụng khi có module công nợ."; giữ câu giải thích "Phần khách chưa thanh toán cho hàng trả được trừ khỏi nợ của đơn, không hoàn tiền." (đúng nghiệp vụ hiện có). Bỏ `_QrPaymentBlock`, `_QrPlaceholder`, `_QrPlaceholderPainter`; Chuyển khoản chỉ còn chọn phương thức |

## 3. Hiện trạng (đo 2026-11-07, dưới `apps/erp/lib/features/sales/`)

| KI | Chỗ |
|---|---|
| KI-07 | `presentation/widgets/sales_checkout_summary_card.dart:6`, `:53` (huy hiệu "Nợ cũ"); `presentation/models/sales_order/sales_checkout_vm.dart:13`, `:28`, `:64`, `:82`, `:100` (`customerDebtMinor`); `presentation/widgets/sales_order_payment_debt_page.dart:~260-310` (thẻ "Xem công nợ", `onTap` chỉ `VToast` info) |
| KI-07 PDF (Q1) | `presentation/support/sales_slip_pdf_generator.dart:24`, `:48`, `:68`, `:91`, `:149`, `:163-164`, `:262-276`; `presentation/support/sales_receipt_pdf_generator.dart:~283-300` (`_buildDebtSection`); nơi truyền: `presentation/pages/sales_slip_preview_page.dart:19`, `:28`, `:69`, `:102`, `presentation/pages/sales_return_exchange_slip_preview_page.dart:99`, `logic/sales_return_exchange_detail_state.dart:67` |
| KI-08 | `presentation/widgets/sales_return_exchange_settlement_body.dart:~371-398` (switch cấn trừ), `:468-473` (gọi `_QrPaymentBlock`), `:711-~870` (3 lớp QR) |
| KI-10 | `logic/sales_return_exchange_session_state.dart:9` (`catalogEmpty`), `:21-50` (`reasonCode` / `conditionCode` của dòng sửa), `:106-107`, `:124-125`, `:150-151`, `:172-173`, `:193-194` (`reasons` / `conditions`); `logic/sales_return_exchange_session_cubit.dart:98-99`, `:107-108`, `:171-210` (`setReturnReason`, `setReturnCondition`); `presentation/support/sales_return_exchange_session_draft.dart:29-30`, `:71-72`, `:93-118` (`hasPolicyCode` + kiểm mã); `presentation/support/sales_return_exchange_mapper.dart:12`, `:26-27`; `presentation/models/return_exchange_order/sales_return_exchange_session_vm.dart:10-11`, `:21-22`; `presentation/widgets/sales_return_exchange_session_body.dart:62-70`; `presentation/widgets/sales_return_exchange_session_line_rows.dart:100-101` (chú thích); `presentation/support/sales_return_exchange_attempt_factory.dart:320`, `:330`, `:375-376`, `:416-417` |
| KI-17 | `presentation/widgets/sales_return_exchange_result_body.dart:18`, `:26`, `:~95-110` (nút "Hoàn tất phiếu"); `presentation/pages/sales_return_exchange_result_page.dart:103`; `logic/sales_return_exchange_detail_cubit.dart:119-~175` (`completeIfReady`); `data/return_exchange_repository.dart:155-~170` (`complete`); `data/mappers/return_exchange_json.dart` (tham số `complete`); `presentation/support/sales_return_exchange_attempt_factory.dart:214-~240` (`complete`) |
| KI-18 | `logic/sales_return_exchange_settlement_state.dart:34`, `logic/sales_return_exchange_settlement_cubit.dart:125` (`SalesPaymentMethod.manualBankTransfer`) |
| KI-21/22, Q3 | SQL `supabase/migrations/20260830007_sales_draft_rpcs.sql:11-~60` (`_draft_payload`), `:478-527` (`list_sales_order_drafts`), `:586`, `:592` (`revoke` / `grant` chữ ký `(uuid, uuid, uuid, text, integer)`); `data/sales_draft_repository.dart:129-146` (`list`); `data/mappers/sales_draft_json.dart:61-78` (`page`); `logic/sales_draft_list_cubit.dart:19-27`, `:36-130` (`_load`, gọi `list(pageSize: 50)`, tra tên), `:133-162` (`_mapDrafts`, `isOwnedByMe` theo `savedByActorId`), `:163-170` (`searchByKeyword`), `:241-280` (`_emitFiltered`, lọc trên máy); `logic/sales_draft_list_state.dart:5` (`SalesDraftScopeFilter`); `presentation/orchestration/sales_draft_list_scope.dart:39`, `:43-58` (`_resolveActorName`); `presentation/pages/sales_draft_list_page.dart:24`, `:127-150`; `presentation/widgets/sales_draft_list_body.dart:94-98`; `presentation/models/sales_order_draft/sales_draft_list_item_vm.dart:17`, `:31`, `:50-60` |
| Q5, Q6 | `logic/sales_draft_list_cubit.dart:218` (tập mã "stale"), `:225`, `:235` |

Bảng nháp: `created_by_user_id` / `updated_by_user_id`, `customer_snapshot` (khoá `display_name`, `phone_number`), `note` (`20260830005_sales_rebuild_schema.sql:50-69`).

Test đang chạm phần bị bỏ: `test/features/sales/presentation_module/bloc/sales_return_exchange_detail_cubit_test.dart` (7 chỗ), `…/sales_return_exchange_session_cubit_test.dart` (2), `presentation_module/widgets/sales_return_exchange_session_body_test.dart` (3), `…/sales_return_exchange_settlement_body_test.dart` (4), `presentation_module/bloc/sales_draft_list_live_test.dart` (`:206`, `:286` câu "Không hủy được…"), `sales_flow_pages_test.dart` (1), `sales_order_detail_page_test.dart` (1), `data/sales_draft_parity_expectations.dart`, `data/sales_checkout_parity_expectations.dart`, `data/sales_order_inquiry_parity_expectations.dart`, `data/sales_draft_rpc_parity_test.dart:100`, `:120`.

## 4. Thiết kế

### G1. KI-07 + Q1
Xoá huy hiệu "Nợ cũ" và trường `customerDebtMinor` (VM + mọi nơi gán). Xoá thẻ "Xem công nợ". PDF phiếu bán: xoá 2 hàng "Công nợ cũ của khách" / "Tổng công nợ" và tham số `existingCustomerDebtMinor` (generator, 2 trang xem trước, getter `existingCustomerDebtMinor` ở detail state). Phiếu đổi/trả (`sales_receipt_pdf_generator.dart` `_buildDebtSection`): xoá hàng "Công nợ cũ của khách" và hàng tổng cộng dồn với nợ cũ; giữ "Công nợ phát sinh từ đơn". Mapper đọc `existingDebtMinor` (`sales_order_inquiry_json.dart:304`, `sales_receipt_json.dart:259`, `sales_order_get_json.dart:79`, `sales_draft_json.dart:151`) giữ nguyên — trường thuộc DTO module, 8-C bỏ khi chép kiểu.

### G2. KI-08 (Q9)
Bỏ `Row` chứa `VSwitch(key: Key('sw_sg12_offset_debt'))` (`~:372-398`); bỏ khối `if (widget.method != SalesPaymentMethod.cash) ...[ … _QrPaymentBlock(…) ]` (`:468-473`) và 3 lớp QR (`:711-~869`). `_VndGroupingFormatter` (`:870`) giữ.

### G3. KI-10 (Q7)
Xoá `SalesReturnExchangeSessionStatus.catalogEmpty` + nhánh ở body; `reasons` / `conditions` ở state / VM / mapper / `preserveEdits`; `setReturnReason`, `setReturnCondition`; `reasonCode` / `conditionCode` ở dòng sửa; `hasPolicyCode` và phần kiểm mã trong `validate`. Factory + `return_exchange_json.dart:538-539` gửi `'reason_code': null`, `'condition_code': null` (giữ khoá); canonical payload giữ `'conditionCode': null`, `'reasonCode': null`. Đọc `reasonCode` / `conditionCode` từ detail của server (`return_exchange_json.dart:597-598`, `:912-913`) giữ nguyên (DTO module).

### G4. KI-17 (Q8)
Xoá `onComplete` (body + trang), `SalesReturnExchangeDetailCubit.completeIfReady`, `ReturnExchangeRepository.complete`, tham số `complete` trong `return_exchange_json.dart`, `SalesReturnExchangeAttemptFactory.complete`, `completeCalls` của fake. Trạng thái khác của phiếu (nháp / huỷ / bị chặn / thất bại) vẫn hiện nhãn như cũ (US-06.7 FR-02).

### G5. KI-18
Hai chỗ `manualBankTransfer` → `SalesPaymentMethod.cash`.

### G6. Danh sách nháp (KI-21, Q2, Q3)

**SQL** (`20260830007`, sửa tại chỗ):
```sql
create or replace function sales.list_sales_order_drafts(
  p_tenant_id uuid, p_actor_id uuid, p_store_id uuid,
  p_cursor text default null, p_page_size integer default 25,
  p_search text default null, p_created_by uuid default null
) returns jsonb
```
`v_search text := nullif(btrim(catalog.unaccent_immutable(coalesce(p_search, ''))), '');`. Thêm vào `where` của truy vấn con:
```sql
and (p_created_by is null or created_by_user_id = p_created_by)
and (v_search is null
     or catalog.unaccent_immutable(coalesce(customer_snapshot ->> 'display_name', '')) ilike '%' || v_search || '%'
     or catalog.unaccent_immutable(coalesce(customer_snapshot ->> 'phone_number', '')) ilike '%' || v_search || '%'
     or catalog.unaccent_immutable(coalesce(note, '')) ilike '%' || v_search || '%')
```
`revoke` / `grant` `:586`, `:592` đổi chữ ký thành `(uuid, uuid, uuid, text, integer, text, uuid)`. Thứ tự, `has_more`, `next_cursor` giữ nguyên.

**Kiểu mới** `data/models/sales_draft_list_page.dart`:
```dart
final class SalesDraftListEntry {
  const SalesDraftListEntry({required this.draft, required this.createdByUserId, this.createdByName});
  final SalesOrderDraftDto draft;
  final String createdByUserId;
  final String? createdByName;
}
final class SalesDraftListPage {
  const SalesDraftListPage({required this.items, required this.hasMore, this.nextCursor});
  final List<SalesDraftListEntry> items;
  final bool hasMore;
  final String? nextCursor;
}
```

**Repository:** `Future<SalesDraftListPage> list({required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId})`; params thêm `'p_search': search`, `'p_created_by': createdByUserId` (luôn có khoá). `SalesDraftJson.page` trả `SalesDraftListPage`, mỗi phần tử đọc thêm `created_by_user_id` (bắt buộc), `created_by_name` (có thể `null`).

**Cubit** (`SalesDraftListCubit`):
- Bỏ tham số `actorNameResolver`, `_actorNamesCache`, `_allRows` lọc trên máy.
- Thêm `SalesDraftScopeFilter _scope = SalesDraftScopeFilter.mine` và `Future<void> setScope(SalesDraftScopeFilter scope)` (đổi ⇒ tải lại trang 1); `searchByKeyword` ⇒ tải lại trang 1 với `search`; `Future<void> loadMore()` (bỏ qua khi đang tải / `!hasMore`; nối trang theo `nextCursor`; lỗi ⇒ giữ danh sách, `loadMoreError = true`).
- `list(storeId, pageSize: 25, cursor, search: _query, createdByUserId: _scope == mine ? actorId : null)`.
- `SalesDraftListLoaded` / `Loading` thêm `scope`, `hasMore`, `nextCursor`, `isLoadingMore`, `loadMoreError` (mẫu `sales_order_list_cubit.dart`).
- Lời đáp cũ đến sau khi đã đổi tab / từ khoá phải bị bỏ: dùng số thế hệ `_generation` tăng mỗi lần tải lại trang 1, kiểm sau mỗi `await`.
- Xoá nháp thành công vẫn bỏ dòng khỏi danh sách đã tải (`:206`).

**VM / UI:** `createdByName` lấy từ `entry.createdByName`; `isOwnedByMe` bỏ nếu không còn nơi dùng. Trang: `onTabSelected` gọi thêm `cubit.setScope(index == 0 ? mine : all)`; body bỏ lọc `:94-96`, giữ `showCreatedBy = displayScope == all`; cuối danh sách có ô tải thêm / lỗi "Thử lại" như `sales_order_list_body.dart`. Xoá `_resolveActorName` ở `sales_draft_list_scope.dart`.

### G7. KI-22 (Q4)
`sales._draft_payload` (`20260830007:11-~60`) thêm 2 khoá: `'created_by_user_id', v_draft.created_by_user_id::text`, `'created_by_name', iam._member_display_name(v_draft.created_by_user_id)`. `_draft_payload` là `security definer` (chủ = owner migration) nên gọi được `iam._member_display_name` dù hàm này `revoke` khỏi `authenticated`. Kiểm `search_path` của `_draft_payload`; tên hàm viết đủ `iam.`.

### G8. Q5 + Q6
`:218` thêm `error.code == SalesDraftErrorCodes.referenceUnavailable` vào điều kiện `stale`. `:225`, `:235` → `'Không xóa được đơn nháp'`.

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau 8-B2 nằm ở đâu | Test |
|---|---|---|---|
| B1 | `_load`: chặn tải chồng (`_isLoading`), giữ danh sách cũ khi tải lại không `isRefresh`, `NO_PERMISSION` / `DATA_SCOPE_DENIED` ⇒ `SalesDraftListBlocked`, lỗi khác ⇒ `SalesDraftListError('Không thể tải danh sách đơn nháp')` | cubit mới (trang 1) | test có sẵn `sales_draft_list_live_test.dart` (đổi fake theo kiểu `SalesDraftListPage`) + Task 0 `load_blocked_on_no_permission`, `load_error_message` nếu chưa có |
| B2 | Tìm: khớp tên khách, SĐT, ghi chú, mã nháp, không phân biệt hoa thường | **Đổi (Q2):** server tìm theo tên khách, SĐT, ghi chú, bỏ dấu; **không còn** khớp mã nháp (UUID — người dùng không thấy mã này) | Task 0 `search_filters_loaded_rows` (cũ) → sau sửa thay bằng `search_reloads_with_server_param`; SQL D01 |
| B3 | Tab "Đơn của tôi" lọc `isOwnedByMe` (người lưu cuối) | **Đổi (Q3):** server `p_created_by` (người tạo) | Task 0 `mine_tab_filters_by_saved_by` (cũ, widget) → sau sửa `set_scope_mine_sends_created_by`, `set_scope_all_sends_null`; SQL D02 |
| B4 | "Tạo bởi" = tên tra được của chính mình, nháp người khác ⇒ ẩn (UUID bị `creatorLabel` loại) | **Đổi (Q4):** `created_by_name` của server | `creator_label_uses_server_name`; `creatorLabel` vẫn loại UUID / SĐT: test có sẵn của VM (nếu chưa có ⇒ Task 0 `creator_label_rejects_uuid`) |
| B5 | Xoá nháp: thành công bỏ dòng; `STALE_DATA` / `STALE_VERSION` ⇒ `needsReload` + câu; lỗi khác ⇒ câu `salesDraftErrorMessage(…, fallback)` | như cũ + `REFERENCE_UNAVAILABLE` (Q5), câu Q6 | test có sẵn (`:206`, `:286` đổi câu — ghi Kết quả) + `discard_reference_unavailable_needs_reload` |
| B6 | Nhãn "Khách lẻ" khi nháp không có khách; `uiStatus` theo `needsRevalidation` | `_mapDrafts` | Task 0 `maps_walk_in_and_needs_check` (nếu chưa có) |
| B7 | `completeIfReady` + nút "Hoàn tất phiếu" | **Bỏ (KI-17)** | sau sửa `result_body_has_no_complete_button`; test có sẵn của `completeIfReady` xoá — ghi tên vào Kết quả |
| B8 | Trạng thái `catalogEmpty` + câu "Chưa cấu hình chính sách đổi/trả" | **Bỏ (KI-10)** — cubit không bao giờ đặt trạng thái này (`reasons` / `conditions` luôn `const []`, `:98-108`) | Task 0 `session_never_emits_catalog_empty` (cũ: `load` đủ ⇒ `ready`); test body của `wgt_sg11_catalog_empty` xoá |
| B9 | Dòng trả gửi `reason_code` / `condition_code` (luôn `null` vì không có chính sách) | khoá giữ, giá trị `null` (Q7) | parity có sẵn của `return_exchange_rpc_parity_test.dart` (`params_start`, `params_update`) giữ xanh **không sửa**; factory `return_exchange_hash_unchanged_{start,confirm}` giữ xanh |
| B10 | Quyết toán: mặc định Chuyển khoản; chọn khác Tiền mặt ⇒ hiện QR mẫu | **Đổi (KI-18, KI-08):** mặc định Tiền mặt; không QR | `settlement_default_method_cash`; `settlement_transfer_shows_no_qr` |
| B11 | Thanh toán SG-06: có khách ⇒ huy hiệu "Nợ cũ 0 ₫"; Khách lẻ ⇒ ẩn | **Bỏ (KI-07)** | `summary_card_has_no_debt_badge` |
| B12 | PDF: có khách ⇒ "Công nợ cũ của khách" + "Tổng công nợ" | **Bỏ (Q1)**; giữ các hàng còn lại | test có sẵn `sales_slip_pdf_generator_test.dart`, `sales_receipt_pdf_generator_test.dart` giữ xanh (chúng kiểm `bytes` và `settlementRows`, không đọc chữ trong PDF) + Task 6.2 `git grep "Công nợ cũ của khách"` rỗng. Không viết test đọc chữ PDF |

**Bước 0 (Task 0):** các test ghi "Task 0" ở cột cuối viết **trên code cũ**, chạy xanh, ghi tên — rồi mới sửa. Test mang tên "(cũ)" được thay ở task sửa, ghi tên test thay thế vào Kết quả.

## 6. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê. Không đụng `modules/`. Migration sửa tại chỗ.
- Trước khi sửa symbol có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi bảng vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng.
- Câu tiếng Việt chép nguyên văn từ mục 2 / 4.
- Xoá test cũ chỉ khi nó kiểm đúng thứ bị bỏ; ghi tên từng test xoá.

### Task 0: Bước 0 — test giữ hành vi trên code cũ

**Files:** Test: `apps/erp/test/features/sales/logic/sales_draft_list_cubit_test.dart` (mới), `…/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart`, `…/presentation_module/widgets/sales_draft_list_body_test.dart` (mới)

- [x] **0.1** Viết các test "Task 0" của bảng 5 (B1, B2 cũ, B3 cũ, B4, B6, B8).
- [x] **0.2** Chạy cùng test có sẵn:
  ```bash
  cd apps/erp && flutter test test/features/sales/logic/sales_draft_list_cubit_test.dart \
    test/features/sales/presentation_module/widgets/sales_draft_list_body_test.dart \
    test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_detail_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart \
    test/features/sales/presentation_module/widgets/sales_return_exchange_session_body_test.dart \
    test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart \
    test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart \
    test/features/sales/presentation_module/support/sales_receipt_pdf_generator_test.dart \
    test/features/sales/data/return_exchange_rpc_parity_test.dart \
    test/features/sales/data/sales_draft_rpc_parity_test.dart \
    test/features/sales/sales_flow_pages_test.dart test/features/sales/sales_order_detail_page_test.dart
  ```
  Expected: PASS. Ghi số test từng tệp.

### Task 1: G1 KI-07 + Q1

**Files:** Modify: các tệp KI-07 / KI-07 PDF ở mục 3. Test: `sales_checkout_page_test.dart` hoặc test của summary card, 2 test PDF, `sales_order_detail_page_test.dart`

- [x] **1.1** Test `summary_card_has_no_debt_badge` (`find.textContaining('Nợ cũ')` ⇒ `findsNothing`, có khách); `payment_debt_page_has_no_view_debt_card` (`find.text('Xem công nợ')` ⇒ `findsNothing`). Chạy → FAIL. (PDF: xem B12.)
- [x] **1.2** Sửa theo G1. Chạy test Task 0 + 1.1 → PASS.

### Task 2: G2 KI-08 + G5 KI-18

**Files:** Modify: `presentation/widgets/sales_return_exchange_settlement_body.dart`, `logic/sales_return_exchange_settlement_state.dart:34`, `logic/sales_return_exchange_settlement_cubit.dart:125`. Test: `…/widgets/sales_return_exchange_settlement_body_test.dart`, `…/bloc/sales_return_exchange_settlement_cubit_test.dart`

- [x] **2.1** Test `settlement_default_method_cash` (state ban đầu và sau `loadAndEvaluate` ⇒ `paymentMethod == SalesPaymentMethod.cash`); `settlement_transfer_shows_no_qr` (chọn Chuyển khoản ⇒ `find.text('QR cửa hàng · ACB')`, `find.text('Nguyễn Văn A')` ⇒ `findsNothing`); `settlement_has_no_offset_debt_switch` (`find.byKey(Key('sw_sg12_offset_debt'))`, `find.text('Sẽ áp dụng khi có module công nợ.')` ⇒ `findsNothing`). Chạy → FAIL.
- [x] **2.2** Sửa theo Q9, G5. Test cũ kiểm QR / switch: xoá, ghi tên. Chạy → PASS.

### Task 3: G3 KI-10

**Files:** Modify: các tệp KI-10 ở mục 3. Test: session cubit / body / attempt factory / parity

- [x] **3.1** Sửa theo G3 (xoá code chết; không đổi tham số gửi server).
- [x] **3.2** Chạy `return_exchange_rpc_parity_test.dart`, `sales_return_exchange_attempt_factory_test.dart`, session cubit / body test → PASS, parity + hash **không sửa** (B9). Test `wgt_sg11_catalog_empty`, `setReturnReason` / `setReturnCondition`: xoá, ghi tên.

### Task 4: G4 KI-17

**Files:** Modify: các tệp KI-17 ở mục 3. Test: `sales_return_exchange_result_page_test.dart`, detail cubit test, repository / parity test của `complete`

- [x] **4.1** Test `result_body_has_no_complete_button` (`find.text('Hoàn tất phiếu')` ⇒ `findsNothing` với phiếu `confirmed`). Chạy → FAIL.
- [x] **4.2** Xoá theo Q8. Test `completeIfReady` / `params_complete` / `complete` của fake: xoá, ghi tên. `git grep -n "completeIfReady\|complete_return_exchange\|\.complete(" -- apps/erp/lib/features/sales` ⇒ rỗng (trừ chỗ không liên quan — ghi). Chạy → PASS.

### Task 5: G6 + G7 + G8 danh sách nháp

**Files:**
- Modify: `supabase/migrations/20260830007_sales_draft_rpcs.sql` (`_draft_payload`, `list_sales_order_drafts`, `:586`, `:592`)
- Create: `apps/erp/lib/features/sales/data/models/sales_draft_list_page.dart`
- Modify: `data/sales_draft_repository.dart:129-146`, `data/mappers/sales_draft_json.dart:61-78`, `logic/sales_draft_list_cubit.dart`, `logic/sales_draft_list_state.dart`, `presentation/orchestration/sales_draft_list_scope.dart`, `presentation/pages/sales_draft_list_page.dart`, `presentation/widgets/sales_draft_list_body.dart`, `presentation/models/sales_order_draft/sales_draft_list_item_vm.dart`
- Test: `data/sales_draft_repository_test.dart`, `data/sales_draft_rpc_parity_test.dart`, `data/sales_draft_parity_expectations.dart`, `logic/sales_draft_list_cubit_test.dart`, `…/bloc/sales_draft_list_live_test.dart`, `…/widgets/sales_draft_list_body_test.dart`, `test/features/sales/support/fake_sales_draft_repository.dart`; `supabase/tests/sales_th05.sql`

**Produces:** `SalesDraftListPage`, `SalesDraftListEntry`, `SalesDraftRepository.list({required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId})`, `SalesDraftListCubit.setScope(SalesDraftScopeFilter)`, `.loadMore()`.

- [x] **5.1** Test repository: `list_sends_search_and_created_by` (params `p_page_size: 25`, `p_search: 'an'`, `p_created_by: 'user-1'`); `list_null_filters_keep_keys` (`containsKey('p_search')` / `('p_created_by')`, giá trị `null`); `page_reads_created_by_name` (`created_by_name: 'Lan'` ⇒ `items.first.createdByName == 'Lan'`; thiếu `created_by_name` ⇒ `null`). Parity `:100`, `:120`: đổi kỳ vọng (đổi có chủ đích, ghi Kết quả).
- [x] **5.2** Test cubit: `first_load_uses_page_25_and_scope_mine` (`createdByUserId == actorId`); `set_scope_all_sends_null`; `search_reloads_with_server_param` (về trang 1, `cursor == null`); `load_more_appends_next_page` (`hasMore` true, `nextCursor: '25'` ⇒ lời gọi 2 có `cursor: '25'`, 50 dòng); `load_more_ignored_when_no_more`; `load_more_error_keeps_items`; `stale_response_after_scope_change_is_dropped` (lời đáp trang 1 của tab cũ về sau ⇒ không đè); `creator_label_uses_server_name`; `discard_reference_unavailable_needs_reload`; câu `'Không xóa được đơn nháp'` (sửa 2 test có sẵn `:206`, `:286`).
- [x] **5.3** Test widget: `tab_change_calls_set_scope`; `scroll_end_calls_load_more`; `mine_tab_shows_no_created_by`.
- [x] **5.4** `sales_th05.sql` thêm: D01 `list_sales_order_drafts(…, p_search => 'an binh')` thấy nháp của "Đại lý An Bình"; D02 `p_created_by` = user B chỉ ra nháp B tạo; D03 `created_by_name` khác `null` và khác UUID. (Ca cần user thứ 2: dựng như `pricing_th04.sql:653-710`.)
- [x] **5.5** Chạy 5.1–5.3 → FAIL. Sửa theo G6–G8. Chạy test Task 0 (B1, B4–B6) + 5.1–5.3 → PASS.

### Task 6: Tài liệu + kiểm toàn bộ + Kết quả

**Files:** Modify: `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (7.3 KI-07, 08, 10, 17, 18, 21, 22 "Đã sửa 8-B2"; US-01.7 FR-01 ghi "Đơn của tôi" = nháp do tôi tạo; bỏ 🔧 ở FR-05 của EP-03, EP-06 FR-03, US-06.7 FR-02); `docs/refactor/PLAN.md` (dòng 8-B2: Làm ✅ + ngày)

- [x] **6.1** Sửa tài liệu.
- [x] **6.2** Các lệnh ra rỗng:
  ```bash
  git grep -nE "Nợ cũ|Xem công nợ|Công nợ cũ của khách|Cấn trừ công nợ hiện tại|QR cửa hàng|Nguyễn Văn A|Chưa cấu hình chính sách|Hoàn tất phiếu|Không hủy được đơn nháp" -- apps/erp/lib/features/sales
  git grep -nE "actorNameResolver|_resolveActorName|catalogEmpty|completeIfReady|setReturnReason|setReturnCondition|customerDebtMinor|existingCustomerDebtMinor" -- apps/erp/lib apps/erp/test
  ```
- [x] **6.3** `cd apps/erp && dart analyze lib/features/sales test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [x] **6.4** `flutter test` cả app → số lỗi đúng bằng mốc sau 8-B1; 0 lỗi `features/sales`.
- [x] **6.5** `node .gitnexus/run.cjs analyze` rồi `detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa.

### Review Focus (chưa task nào test, phiên review soi)

1. **Gõ tìm nhanh:** mỗi ký tự một lần tải lại ⇒ nhiều RPC; nếu `searchByKeyword` đang có debounce thì giữ, không có thì ghi Kết quả (không tự thêm).
2. **Xoá nháp rồi tải thêm:** bỏ 1 dòng khỏi danh sách đã tải làm lệch `offset` (cursor là số dòng) ⇒ trang sau có thể bỏ sót 1 nháp; chấp nhận (người dùng kéo làm mới thấy lại) — review xác nhận không trùng dòng, không lỗi.
3. **`created_by_name` = "Không rõ"** (`iam._member_display_name` khi không có hồ sơ / email): `creatorLabel` vẫn hiện "Tạo bởi: Không rõ" — đúng ý, không lọc.
4. **Đổi tab khi đang tải thêm:** `isLoadingMore` của tab cũ không được khoá tab mới (`_generation`).
5. **Quyết toán đổi/trả đã mở trước khi cập nhật** giữ `manualBankTransfer` trong state cũ: chỉ ảnh hưởng phiên đang mở; không cần di chuyển dữ liệu.

## 7. Kiểm tra

### 7.1 Tự động
Task 0–6.

### 7.2 Việc của người dùng
- DB local: reset rồi chạy `supabase/tests/sales_th05.sql` (thêm D01–D03) → `sales_th05: OK`. Dev: reset.
- Kiểm tay (iPhone simulator + Chrome): (1) SG-06 có khách: không còn "Nợ cũ"; (2) SG-09 "Thanh toán & công nợ": không còn "Xem công nợ"; (3) xem trước phiếu bán của đơn nợ: không còn "Công nợ cũ của khách"; (4) quyết toán đổi/trả: mặc định Tiền mặt, chọn Chuyển khoản không có QR, không có "Cấn trừ"; (5) kết quả đổi/trả: không có "Hoàn tất phiếu"; (6) tạo 30 nháp → cuộn xuống tải thêm; tìm "an binh" ra nháp "An Bình"; (7) tài khoản thứ 2 tạo nháp → tài khoản 1 ở "Tất cả đơn nháp" thấy "Tạo bởi: <tên tài khoản 2>", ở "Đơn của tôi" không thấy.

## 8. Rủi ro / lưu ý

- **Đổi chữ ký RPC:** sửa tại chỗ ⇒ hàm cũ 5 tham số biến mất sau reset; app cũ chưa cập nhật sẽ lỗi. Gửi đủ 7 khoá (PostgREST khớp theo tên).
- **Lời đáp trễ** khi đổi tab / gõ nhanh: `_generation` (5.2 `stale_response_after_scope_change_is_dropped`).
- **Hash attempt đổi/trả** (Q7): bỏ nhầm khoá `reasonCode` / `conditionCode` khỏi canonical payload ⇒ hash khác; B9 bắt.
- **Ngữ nghĩa "Đơn của tôi" đổi** (Q3): báo người dùng khi kiểm tay 7.2 (7).

## 9. Kết quả (phiên làm code ghi)

<!-- Ghi ngay sau mỗi task: tệp:dòng, lệch plan, số test, bảng impact, tên test xoá / thay. -->

### Task 0: Bước 0 — test giữ hành vi trên code cũ (2026-11-07)
- **Tệp tạo / sửa:**
  - `apps/erp/test/features/sales/logic/sales_draft_list_cubit_test.dart` (mới): 5 test (`load_blocked_on_no_permission`, `load_error_message`, `search_filters_loaded_rows`, `creator_label_rejects_uuid`, `maps_walk_in_and_needs_check`).
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_draft_list_body_test.dart` (mới): 1 test (`mine_tab_filters_by_saved_by`).
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart:61-71`: thêm 1 test (`session_never_emits_catalog_empty`).
- **Lệch plan:** Không.
- **Số test:** 263/263 test PASS qua 14 tệp (`sales_draft_list_cubit_test`: 5, `sales_draft_list_body_test`: 1, `sales_draft_list_live_test`: 15, `sales_return_exchange_session_cubit_test`: 22, `sales_return_exchange_detail_cubit_test`: 10, `sales_return_exchange_settlement_cubit_test`: 19, `sales_return_exchange_session_body_test`: 5, `sales_return_exchange_settlement_body_test`: 15, `sales_slip_pdf_generator_test`: 2, `sales_receipt_pdf_generator_test`: 2, `return_exchange_rpc_parity_test`: 84, `sales_draft_rpc_parity_test`: 33, `sales_flow_pages_test`: 28, `sales_order_detail_page_test`: 22).
- **Impact:** Không sửa symbol production (chỉ viết test).

### Task 1: G1 KI-07 + Q1 (2026-11-07)
- **Tệp tạo / sửa:**
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_checkout_summary_card_test.dart` (mới): 2 test (`summary_card_has_no_debt_badge`, `payment_debt_page_has_no_view_debt_card`).
  - `apps/erp/lib/features/sales/presentation/widgets/sales_checkout_summary_card.dart`: xoá badge `txt_sg05_customer_debt` ("Nợ cũ") và import thừa `MoneyFormatter`.
  - `apps/erp/lib/features/sales/presentation/models/sales_order/sales_checkout_vm.dart`: xoá trường `customerDebtMinor` (constructor, copyWith, props).
  - `apps/erp/example/lib/sales/preview/fixtures.dart`: xoá gán `customerDebtMinor`.
  - `apps/erp/lib/features/sales/presentation/widgets/sales_order_payment_debt_page.dart`: xoá widget `_ReceivableEntry` ("Xem công nợ") và vị trí gọi trong build.
  - `apps/erp/lib/features/sales/presentation/support/sales_slip_pdf_generator.dart`: xoá tham số `existingCustomerDebtMinor` (ở `generateReturnExchange`, `generate`, `_buildReturnSlipBody`), xoá tính toán và khối "Công nợ cũ của khách" / "Tổng công nợ".
  - `apps/erp/lib/features/sales/presentation/support/sales_receipt_pdf_generator.dart:283-294`: `_buildDebtSection` xoá 2 hàng "Công nợ cũ của khách" và "Tổng công nợ", chỉ giữ "Công nợ phát sinh từ đơn".
  - `apps/erp/lib/features/sales/presentation/pages/sales_slip_preview_page.dart`: xoá field và tham số truyền `existingCustomerDebtMinor`.
  - `apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_slip_preview_page.dart`: xoá truyền `existingCustomerDebtMinor`.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_state.dart`: xoá getter `existingCustomerDebtMinor`.
  - `apps/erp/test/features/sales/sales_order_detail_page_test.dart:115`: sửa `expect(find.text('Xem công nợ'), findsOneWidget)` thành `findsNothing` (do đã xoá thẻ theo KI-07).
- **Lệch plan:** Không.
- **Số test:** 265/265 test PASS (263 từ Task 0 + 2 test mới Task 1.1).
- **Impact (gitnexus upstream):**
  - `SalesCheckoutSummaryCard`: MEDIUM (3 direct, 0 process broken).
  - `customerDebtMinor`: LOW (0 direct).
  - `SalesOrderPaymentDebtPage`: MEDIUM (3 direct, 0 process broken).

### Task 2: G2 KI-08 + G5 KI-18 (2026-11-07)
- **Tệp tạo / sửa:**
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart`: thêm test `settlement_default_method_cash`.
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`:
    - Thêm 2 test `settlement_transfer_shows_no_qr` và `settlement_has_no_offset_debt_switch`.
    - Xoá test cũ `offset switch is shown locked with a pending note and cannot change amounts` (thay bằng `settlement_has_no_offset_debt_switch`).
    - Bỏ dòng assertion `expect(find.text('QR cửa hàng · ACB'), findsOneWidget);` trong test `ready collect flow renders payment collection UI`.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_state.dart:34`: đổi mặc định `paymentMethod` thành `SalesPaymentMethod.cash`.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_cubit.dart:125`: `loadAndEvaluate` emit `paymentMethod: SalesPaymentMethod.cash`.
  - `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart`: xoá switch `sw_sg12_offset_debt` và text pending (lines 371-400 cũ), xoá block `_QrPaymentBlock` khi chọn Chuyển khoản (lines 468-473 cũ), xoá các class widget `_QrPaymentBlock`, `_QrPlaceholder`, `_QrPlaceholderPainter` (giữ lại `_VndGroupingFormatter`).
- **Lệch plan:** Không.
- **Số test:** 267/267 test PASS (thêm 3 test mới 2.1, xoá 1 test cũ offset switch: net +2 từ mốc 265 của Task 1).
- **Impact (gitnexus upstream):**
  - `SalesReturnExchangeSettlementState`: MEDIUM (5 direct, 0 process broken).
  - `SalesReturnExchangeSettlementCubit`: MEDIUM (2 direct, 0 process broken).

### Task 3: G3 KI-10 (2026-11-07)
- **Tệp tạo / sửa:**
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_session_state.dart`: xoá `catalogEmpty` khỏi `SalesReturnExchangeSessionStatus`; xoá `reasonCode`, `conditionCode` khỏi `SalesReturnLineEdit`; xoá `reasons`, `conditions` khỏi `SalesReturnExchangeSessionState`.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_session_cubit.dart`: xoá `setReturnReason`, `setReturnCondition`; bỏ truyền `reasons`, `conditions` vào `preserveEdits` và `copyWith`.
  - `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_session_draft.dart`: `buildLines` truyền `reasonCode: null`, `conditionCode: null`; `preserveEdits` bỏ kiểm tra policy codes; xoá `hasPolicyCode`.
  - `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_mapper.dart`: `toSessionVm` bỏ tham số `policy` và các trường `reasons`, `conditions`.
  - `apps/erp/lib/features/sales/presentation/models/return_exchange_order/sales_return_exchange_session_vm.dart`: xoá `reasons`, `conditions`.
  - `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_session_line_rows.dart`: xoá `reasons`, `conditions`, `onReasonChanged`, `onConditionChanged` khỏi `SalesReturnExchangeReturnLineRow`.
  - `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_session_body.dart`: xoá case `catalogEmpty`; xoá `onReturnReasonChanged`, `onReturnConditionChanged` khỏi constructor và `_SessionContent`; cập nhật gọi `SalesReturnExchangeReturnLineRow`.
  - `apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_create_page.dart`: bỏ truyền `onReturnReasonChanged`, `onReturnConditionChanged`.
  - `apps/erp/example/lib/sales/preview/sales_return_exchange_session_preview_section.dart`: xoá block preview 'Catalog empty', xoá `_noopCode` và các callback reason/condition.
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart`: xoá gọi `setReturnReason`, `setReturnCondition` trong `prepareReady` và test quantity clamp; xoá expect `reasons` / `conditions`; sửa `session_never_emits_catalog_empty` (chỉ assert ready).
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_session_body_test.dart`: xoá test assertion `wgt_sg11_catalog_empty`, xoá callback reason/condition trong `_harness`, xoá `reasons` / `conditions` trong `_readyState`.
- **Lệch plan:** Không.
- **Số test:** 267/267 test PASS (tất cả 102 test liên quan Task 3 pass, parity 84/84 và hash attempt giữ nguyên không đổi).
- **Impact (gitnexus upstream):**
  - `SalesReturnExchangeSessionStatus`: LOW (0 direct).
  - `SalesReturnLineEdit`: HIGH (9 direct: session cubit, session draft, preview section, line rows, session body - đã cập nhật đầy đủ, 0 broken process).

### Task 4: G4 KI-17 (2026-11-07)
- **Tệp tạo / sửa:**
  - `apps/erp/test/features/sales/sales_return_exchange_result_page_test.dart`: thêm test `result_body_has_no_complete_button` (Task 4.1 chạy FAIL, sau khi sửa code chạy PASS).
  - `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_result_body.dart`: xoá `onComplete` và button `btn_sg13_complete` ("Hoàn tất phiếu"); xoá nhánh `completing`.
  - `apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_result_page.dart`: xoá `onComplete: () => _cubit.completeIfReady()`.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_cubit.dart`: xoá `completeIfReady`, `_messageForComplete`, `_completeInFlight`, `_currentAttempt`, và các field không dùng.
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_state.dart`: xoá `canComplete`, xoá `completing` khỏi `SalesReturnExchangeDetailStatus`.
  - `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_detail_body.dart`: xoá nhánh `completing`.
  - `apps/erp/lib/features/sales/data/return_exchange_repository.dart`: xoá method `complete`.
  - `apps/erp/lib/features/sales/data/mappers/return_exchange_json.dart`: xoá method `completeParams`.
  - `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart`: xoá method `complete`, xoá operation `complete`, xoá `_idOnlyMutation`.
  - `apps/erp/test/features/sales/support/fake_return_exchange_repository.dart`: xoá `complete`, `completeCalls`, `completeResult`, `completeResults`, `completeError`.
  - `apps/erp/test/features/sales/support/module_backed_sales_repositories.dart`: xoá `complete`.
  - `apps/erp/test/features/sales/data/return_exchange_rpc_parity_test.dart`: xoá test `params_complete`.
  - `apps/erp/test/features/sales/presentation_module/support/sales_return_exchange_attempt_factory_test.dart`: chuyển gọi `complete` sang `discard` trong test correlation trimmed.
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_detail_cubit_test.dart`:
    - Xoá 4 test cũ của complete: `completeIfReady does nothing when completionReady is false`, `completeIfReady dispatches complete attempt then reloads`, `IMPACT_PENDING during complete keeps processing without false success`, `detail_complete_error_fallback`.
    - Sửa test `refresh_not_found_clears_previous_error` để tạo lỗi qua `detailError` thay vì `completeIfReady`.
    - Xoá `canComplete` assertion.
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_checkout_summary_card_test.dart`: xoá unused import.
- **Lệch plan:** Không.
- **Số test:** 263/263 test PASS (thêm 1 test mới 4.1 `result_body_has_no_complete_button`, xoá 5 test cũ: `params_complete` + 4 test `completeIfReady`: net -4 từ mốc 267 của Task 3).
- **Impact (gitnexus upstream):**
  - `completeIfReady`: LOW (1 direct: result page, 0 broken process).
  - `ReturnExchangeRepository.complete`: LOW (0 direct).
  - `git grep -nE "completeIfReady|complete_return_exchange|\.complete\(" -- apps/erp/lib/features/sales` ⇒ RỖNG (0 dòng).

### Task 5: G6 + G7 + G8 (2026-11-07)
- **Tệp tạo / sửa:**
  - `supabase/migrations/20260830007_sales_draft_rpcs.sql`: thêm `created_by_user_id`, `created_by_name` (qua `iam._member_display_name`) vào `sales._draft_payload`. Nâng cấp `sales.list_sales_order_drafts` với `p_search` (dùng `catalog.unaccent_immutable`) và `p_created_by`. Cập nhật revoke/grant signatures.
  - `supabase/tests/sales_th05.sql`: thêm test cases D01 (unaccent search "an binh"), D02 (filter `p_created_by`), D03 (`created_by_name` không null và không phải UUID).
  - `apps/erp/lib/features/sales/data/models/sales_draft_list_page.dart`: tạo mới `SalesDraftListEntry` và `SalesDraftListPage`.
  - `apps/erp/lib/features/sales/data/sales_draft_repository.dart`: cập nhật `list` với named parameters `{required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId}` trả về `Future<SalesDraftListPage>`.
  - `apps/erp/lib/features/sales/data/mappers/sales_draft_json.dart`: cập nhật `page` trả về `SalesDraftListPage` parse từ RPC json.
  - `apps/erp/lib/features/sales/logic/sales_draft_list_state.dart`: thêm `scope`, `hasMore`, `nextCursor`, `isLoadingMore`, `loadMoreError` vào `SalesDraftListState` và `SalesDraftListLoaded`; thêm `copyWith`.
  - `apps/erp/lib/features/sales/logic/sales_draft_list_cubit.dart`: xoá `actorNameResolver`, `_actorNamesCache`, `_allRows`. Thêm `_generation`, `setScope`, `loadMore()`, `clearSearch()`. Tích hợp server search & creator filter. Xử lý `REFERENCE_UNAVAILABLE` với `needsReload: true`, message "Đơn nháp đã thay đổi. Vui lòng tải lại danh sách." (EC-01). Fallback error string "Không xóa được đơn nháp".
  - `apps/erp/lib/features/sales/presentation/widgets/sales_draft_list_body.dart`: xoá lọc client `where((i) => i.isOwnedByMe)`. Thêm `onLoadMore` qua `NotificationListener<ScrollNotification>`, footer spinner và retry error banner.
  - `apps/erp/lib/features/sales/presentation/pages/sales_draft_list_page.dart`: nối `onTabSelected` tới `_cubit.setScope` và `onLoadMore: _cubit.loadMore`.
  - `apps/erp/lib/features/sales/presentation/orchestration/sales_draft_list_scope.dart`: xoá `_resolveActorName` và import `AccountRepository`.
  - `apps/erp/test/features/sales/data/sales_draft_repository_test.dart`: thêm test `list_sends_search_and_created_by`, `list_null_filters_keep_keys`, `page_reads_created_by_name`.
  - `apps/erp/test/features/sales/data/sales_draft_parity_expectations.dart` & `sales_draft_rpc_parity_test.dart`: cập nhật golden params `p_search`, `p_created_by`; cập nhật `expectPage` hỗ trợ `SalesDraftListPage`.
  - `apps/erp/test/features/sales/logic/sales_draft_list_cubit_test.dart`: thêm 9 behavior unit tests mới.
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_draft_list_body_test.dart`: thêm `mine_tab_shows_no_created_by`, `scroll_end_calls_load_more`.
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart`: cập nhật `pageSize: 25`, cập nhật fallback string, xoá test obsolete `actorNameResolver`.
  - `apps/erp/test/features/sales/support/fake_sales_draft_repository.dart`: cập nhật `list` trả về `SalesDraftListPage` với `search`, `createdByUserId`, `hasMore`, `nextCursor`.
  - `apps/erp/test/features/sales/sales_flow_pages_test.dart`: cập nhật expectation EC-01 sang "Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.".
- **Tên test xoá / đổi:**
  - `mine_tab_filters_by_saved_by` (xoá khỏi `sales_draft_list_body_test.dart` do chuyển logic lọc sang server).
  - `cancel_reference_unavailable_no_reload` → `cancel_reference_unavailable_needs_reload` (đổi kỳ vọng theo Q5/EC-01 sang `needsReload: true` và message thông báo reload).
  - `search_filters_loaded_rows`: giữ kiểm tra client khi fake filter như server.
- **Lệch plan:** Tạm thiếu 2 test (`tab_change_calls_set_scope` 5.3, `set_scope_mine_sends_created_by` B3) và kỳ vọng `totalCount` ở live test :75 — đã bổ sung và khắc phục đầy đủ trong Task R1.
- **Số test:** 1214/1214 test sales PASS.
- **Impact (gitnexus upstream):**
  - `SalesDraftRepository.list`: LOW (1 direct: `SalesDraftListCubit`).
  - `SalesDraftListCubit`: LOW (1 direct: `SalesDraftListPage`).

### Task 6: Hoàn tất & Kiểm tra nghiệm thu (2026-11-07)
- **Tệp tạo / sửa:**
  - `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`: cập nhật trạng thái KI-07, 08, 10, 17, 18, 21, 22 thành "Đã sửa 8-B2"; làm rõ US-01.7 FR-01 "Đơn của tôi" = nháp do tôi tạo (`created_by_user_id = current_user_id()`); xoá cờ 🔧 tại EP-03 FR-05, EP-06 FR-03, US-06.7 FR-02.
  - `docs/refactor/PLAN.md`: đánh dấu 8-B2 là "Làm ✅ 2026-11-07".
- **Lệch plan:** Tệp `sales_payment_qr_card.dart` ngoài plan chỉ đổi text — đã xử lý triệt để trong Task R1-5b (xoá bỏ card và file theo phương án B đã chốt).
- **Kết quả nghiệm thu 5 bước:**
  1. `git grep -nE "Nợ cũ|Xem công nợ|Công nợ cũ của khách|Cấn trừ công nợ hiện tại|QR cửa hàng|Nguyễn Văn A|Chưa cấu hình chính sách|Hoàn tất phiếu|Không hủy được đơn nháp" -- apps/erp/lib/features/sales` ⇒ RỖNG (0 kết quả).
  2. `git grep -nE "actorNameResolver|_resolveActorName|catalogEmpty|completeIfReady|setReturnReason|setReturnCondition|customerDebtMinor|existingCustomerDebtMinor" -- apps/erp/lib apps/erp/test` ⇒ RỖNG (0 kết quả, ngoại trừ `_resolveActorName` của `features/iam` không liên quan).
  3. `dart analyze lib/features/sales test/features/sales` ⇒ 0 error, 0 new warning.
  4. `flutter test test/features/sales` ⇒ 1214/1214 PASS.
  5. `flutter test` toàn app ⇒ 2863 đạt / 55 lỗi baseline (khớp mốc `TEST-BASELINE.md` thuộc catalog, pricing, iam, my_account; 0 lỗi mới trong sales).
  6. `detect_changes`: 60 files, 63 symbols (phiên đầu trước R1).

### Task R1: Khắc phục theo Review R1 (2026-11-07)
- **Tệp tạo / sửa / xoá:**
  - `apps/erp/lib/features/sales/logic/sales_draft_list_cubit.dart`:
    - Thêm `force: true` cho `load()` khi gọi từ `setScope` / `searchByKeyword`, bỏ qua chặn `_isLoading` và tăng `_generation` để huỷ bỏ lời đáp cũ đang bay (R1-1).
    - `finally` chỉ đặt `_isLoading = false` khi `gen == _generation` (R1-1).
    - `loadMore` giữ nguyên `totalCount` của trang 1; `discardDraft` giảm `totalCount - 1` không âm (R1-5a).
  - `apps/erp/lib/features/sales/presentation/pages/sales_draft_list_page.dart`:
    - `_tabIndex` khởi tạo từ `_cubit.state.scope == SalesDraftScopeFilter.all ? 1 : 0` trong `initState` (R1-2).
  - `supabase/migrations/20260830007_sales_draft_rpcs.sql`:
    - `list_sales_order_drafts` bổ sung `'total_count'` = `count(*)` nháp active của store (không lọc bởi search/created_by/cursor) (R1-5a).
  - `supabase/tests/sales_th05.sql`:
    - Thêm test D04 kiểm tra `total_count` bất biến qua các bộ lọc tìm kiếm và người tạo (R1-5a).
    - Cập nhật D01 sửa key `'phone'` thành `'phone_number'` và chỉnh nhãn G6/G7.
  - `apps/erp/lib/features/sales/data/models/sales_draft_list_page.dart`: thêm `final int totalCount;` (bắt buộc) (R1-5a).
  - `apps/erp/lib/features/sales/data/mappers/sales_draft_json.dart`: parse `total_count` từ json RPC (ném `FormatException` nếu thiếu/sai kiểu) (R1-5a).
  - `apps/erp/lib/features/sales/logic/sales_draft_list_state.dart`: cập nhật doc comment `totalCount` (tổng active từ server) (R1-5a).
  - `apps/erp/lib/features/sales/presentation/pages/sales_checkout_page.dart`: xoá khối `SalesPaymentQrCard` và khoảng trống ở SG-06 (R1-5b).
  - Xoá tệp `apps/erp/lib/features/sales/presentation/widgets/sales_payment_qr_card.dart` (R1-5b).
  - `apps/erp/lib/features/sales/presentation.dart`: xoá export `sales_payment_qr_card.dart` (R1-5b).
  - `apps/erp/example/lib/sales/preview/sg05_checkout_tab.dart` và `overview_tab.dart`: dọn dẹp tham chiếu tới `SalesPaymentQrCard` (R1-5b).
  - `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`:
    - Sửa dòng 1404 US-06.6 FR-01: "mặc định Chuyển khoản — KI-18" → "mặc định Tiền mặt" (R1-4).
    - Thêm KI-23 vào mục 7.3: SG-06 có thẻ QR mẫu cứng — đã sửa 8-B2 R1 bằng cách bỏ thẻ QR mẫu (R1-5b).
  - `apps/erp/test/features/sales/data/sales_draft_repository_test.dart`: thêm test `page_reads_total_count` (R1-5a).
  - `apps/erp/test/features/sales/data/sales_draft_parity_expectations.dart`: cập nhật `samplePageJson` và `expectPage` với `total_count: 42` (R1-5a).
  - `apps/erp/test/features/sales/logic/sales_draft_list_cubit_test.dart`:
    - Thêm 2 test race condition: `scope_change_while_first_page_in_flight`, `search_while_first_page_in_flight` (R1-1).
    - Thêm test `set_scope_mine_sends_created_by` (R1-3 / B3).
    - Thêm 3 test `total_count`: `total_count_ignores_scope_and_search`, `load_more_keeps_total_count`, `discard_decrements_total_count` (R1-5a).
  - `apps/erp/test/features/sales/presentation_module/widgets/sales_draft_list_body_test.dart`:
    - Thêm test `tab_restores_from_cubit_scope` (R1-2).
    - Thêm test `tab_change_calls_set_scope` (R1-3 / 5.3).
  - `apps/erp/test/features/sales/presentation/sales_checkout_page_test.dart`:
    - Thêm test `checkout_transfer_shows_no_qr` (R1-5b).
  - `apps/erp/test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart`: khôi phục kỳ vọng `totalCount = 2` sau khi search (R1-5a).
  - `apps/erp/test/features/sales/support/fake_sales_draft_repository.dart`: hỗ trợ `totalCount` mặc định theo tổng số items trước khi lọc (R1-5a).
- **Lệch plan:** Không.
- **Kết quả kiểm tra sau R1:**
  1. `git grep -nE "SalesPaymentQrCard|VET45 · ACB|1028 6888|Chủ tài khoản" -- apps/erp` ⇒ RỖNG (chỉ còn 1 dòng CHANGELOG cũ và assertions test phủ định).
  2. `dart analyze lib/features/sales test/features/sales example/lib/sales` ⇒ 0 error, 0 warning mới (11 deprecation hints cũ).
  3. `flutter test test/features/sales` ⇒ 1224/1224 PASS (tăng 10 test so với mốc 1214).
  4. `flutter test` toàn app ⇒ 2873 đạt / 55 lỗi baseline (khớp đúng mốc baseline, 0 lỗi trong sales).
  5. `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all` ⇒ 62 files, 87 symbols. Toàn bộ nằm trong phạm vi plan và R1.

### Task R2: Khắc phục theo Review R2 (2026-11-08)
- **Tệp sửa:**
  - `supabase/tests/sales_th05.sql`:
    - D04: bọc `select count(*) … from sales.sales_order_drafts` bằng `reset role;` … `set local role authenticated;` (R2-1).
    - Lỗi test của 8-B1 cùng kiểu (thấy ở review 8-B2): `public._th05_cancel` đọc version bằng `reset role` rồi `set local role authenticated` trước khi gọi `sales.confirm_sales_order_cancellation` (không dùng `security definer` để RPC huỷ vẫn chạy bằng vai `authenticated`, và vì `set role` bị cấm trong hàm `security definer`); bọc `reset role` / `set local role authenticated` quanh các câu đọc thẳng bảng: `catalog.product_units` (v_u1, v_u2), `catalog.products` (`is_ready_to_sell`, gộp `update` vào cùng khối), C01 + C03 `count(*) sales.sales_orders`, C08 `payment_due_date`, C12 + C13 `sales.sales_order_lines`, C14 `payment_due_date`, C18 `catalog.product_units`. **Lệch R2-1:** thêm cả các câu đọc bảng `catalog` (R2-1 chỉ nêu bảng `sales`) — `catalog` đã `revoke all … from authenticated` (`20260709001:710`) nên cũng lỗi quyền; đọc bằng quyền chủ không đổi ý nghĩa ca test. Không chạy SQL.
  - `apps/erp/lib/features/sales/presentation/pages/sales_checkout_page.dart:~372`: `if (vm.paymentMode != SalesPaymentMode.mixed) const VGap.sm(),` trước nhãn "Mã giao dịch" (R2-2).
- **Impact:** `SalesCheckoutPage` MEDIUM (2 direct, 0 process) — chỉ thêm khoảng cách.
- **Kiểm:** `dart analyze` tệp checkout ⇒ No issues; `flutter test test/features/sales` ⇒ 1224/1224 PASS.
- **Còn lại cho người dùng (7.2):** `pricing_th04.sql` cũng đọc thẳng `catalog.product_units` sau `set local role authenticated` (`:123`, `:396`) — có thể lỗi quyền cùng kiểu khi chạy; ngoài phạm vi 8-B2, chưa sửa.

## 10. Review

<!-- Chỉ phiên review ghi. -->

### R1 (2026-11-07) — **CHƯA ĐẠT**

| Hạng mục | Kết luận |
|---|---|
| G1 KI-07 + Q1 (huy hiệu, thẻ "Xem công nợ", PDF) | ✅ |
| G2 KI-08 + G5 KI-18 (QR, cấn trừ, mặc định Tiền mặt) | ✅ |
| G3 KI-10 (khoá `reason_code` / `condition_code` giữ, giá trị `null`; parity + hash không sửa) | ✅ |
| G4 KI-17 ("Hoàn tất phiếu", `complete`) | ✅ |
| G6 SQL `list_sales_order_drafts` (`p_search`, `p_created_by`, grant/revoke 7 tham số) + G7 `_draft_payload` | ✅ (đọc code; chạy SQL là việc người dùng) |
| G6 cubit: đổi tab / gõ tìm khi trang 1 đang tải | ❌ **R1-1** — yêu cầu mới bị bỏ, dữ liệu cũ hiện dưới tab / từ khoá mới |
| G6 trang: tab trên màn khớp `scope` của cubit | ❌ **R1-2** |
| G8 Q5 + Q6 | ✅ |
| Test 5.3 `tab_change_calls_set_scope`, B3 `set_scope_mine_sends_created_by` | ❌ **R1-3** thiếu |
| Tài liệu TH-05 | ❌ **R1-4** US-06.6 FR-01 (dòng ~1404) còn "mặc định Chuyển khoản — KI-18" |
| Tệp ngoài plan | ⚠️ **R1-5** `sales_payment_qr_card.dart` |
| Kết quả: ghi đúng số / lệnh | ⚠️ **R1-6** |
| Grep 6.2 (đúng lệnh của plan) | ✅ rỗng (chỉ còn `_resolveActorName` của `features/iam` — không liên quan) |
| `dart analyze lib/features/sales test/features/sales` | ✅ 0 lỗi, 0 cảnh báo (9 info `deprecated_member_use` có sẵn) |
| `flutter test test/features/sales` | ✅ 1214/1214 |
| `flutter test` cả app | ✅ 2863 đạt, 55 lỗi = mốc; 0 lỗi `features/sales` (Kết quả ghi 56 — sai, xem R1-6) |

#### Lỗi chính

**R1-1 — `load()` chặn tải chồng nuốt mất lần tải lại của `setScope` / `searchByKeyword`** (`logic/sales_draft_list_cubit.dart:52-60`). `setScope` / `searchByKeyword` đổi `_scope` / `_query` rồi gọi `load(isRefresh: true)`; nếu trang 1 đang tải, `if (_isLoading) return;` thoát ngay, **không tăng `_generation`** ⇒ lời đáp của lần tải cũ đi qua kiểm `gen` và được emit kèm `scope: _scope` / `query: _query` mới. Tái hiện bằng test tạm (đã xoá) dùng `onListGate` chặn lời gọi `list` đầu:
- đổi sang "Tất cả" khi đang tải "Đơn của tôi" ⇒ `scope=all items=(mine) listCalls=1`;
- gõ "an" khi đang tải ⇒ `query=an items=(q=null) listCalls=1`.

Test `stale_response_after_scope_change_is_dropped` xanh **do tình cờ**: `setScope` chạy trước khi lần tải đầu tới `list`, nên lần tải đầu đọc `_scope` mới — không phải ca "lời đáp về muộn". Ô tìm có debounce (Review Focus 1 ✅) nhưng không cứu được: gõ, dừng quá debounce, gõ tiếp khi RPC chưa về ⇒ dính lỗi.

**R1-2 — `_tabIndex` của trang không lấy từ cubit** (`presentation/pages/sales_draft_list_page.dart:24`). `SalesDraftListCubit` sống ở `SalesDraftListScope` (bọc navigator, `sales_typed_routes.dart:58`) nên `_scope` giữ qua các lần mở trang; trang luôn khởi tạo `_tabIndex = 0`. Ở tab "Tất cả đơn nháp" → rời trang → mở lại: tab hiện "Đơn của tôi", danh sách là của tất cả, không có "Tạo bởi"; chạm "Đơn của tôi" (đang chọn sẵn) có thể không gọi `onTabSelected`.

#### Câu hỏi cho người dùng (plan chưa nói, đổi hành vi ngoài ý) — **đã chốt 2026-11-07: Q-R1a = B, Q-R1b = B** (xem R1-5a, R1-5b)

- **Q-R1a — Nút "Đơn nháp (N)" ở SG-02** (`sales_order_compose_page.dart:465`, dùng `totalCount` của cùng cubit). Trước: N = số nháp đã tải của cửa hàng (≤ 50), không theo tab / từ khoá. Nay: N = số dòng đã tải của tab + từ khoá hiện tại (mặc định "Đơn của tôi", ≤ 25 tới khi tải thêm) — đổi tab / gõ tìm ở SG-01 làm N ở SG-02 đổi theo. Chú thích `totalCount` (`sales_draft_list_state.dart:30`) đã sai. Chọn: (A) giữ như hiện tại, sửa chú thích; (B) RPC trả thêm `total_count` của cửa hàng (không lọc) và nút dùng số đó; (C) nút bỏ số.
- **Q-R1b — QR mẫu ở thanh toán SG-06** (`sales_payment_qr_card.dart`, dùng ở `sales_checkout_page.dart:375`): vẫn hiện tài khoản giả "VET45 · ACB", "1028 6888". Phiên code đổi `accountName` 'Nguyễn Văn A' → 'Chủ tài khoản' cho grep 6.2 rỗng — tệp ngoài plan, chỉ che triệu chứng. Grep 6.2 của plan bắt rộng quá (KI-08 chỉ nói quyết toán đổi/trả). Chọn: (A) hoàn nguyên tệp, ghi KI mới vào TH-05 7.3 và làm ở plan sau; (B) bỏ thẻ QR ở SG-06 ngay trong R1 (như KI-08: Chuyển khoản chỉ chọn phương thức).

#### Ghi chú nhỏ (không bắt sửa)
- `sales_th05.sql` D01–D03: nhãn "(G7)" / "(G8)" lệch (đúng là G6 / G7); D01 dựng khách với khoá `'phone'`, không phải `'phone_number'` ⇒ không thử tìm theo SĐT.
- `SalesDraftJson.page`: `created_by_user_id` thiếu ⇒ `''` thay vì báo lỗi như plan ghi "bắt buộc".
- Review Focus 2–5: đạt (xoá rồi tải thêm chỉ có thể bỏ sót, không trùng; "Không rõ" vẫn qua `creatorLabel`; tải thêm của tab cũ bị `_generation` bỏ, `_isLoadingMore` trả trong `finally`; state quyết toán cũ chỉ ảnh hưởng phiên đang mở).

### R1 — việc cần sửa

#### Task R1-1: Đổi tab / từ khoá luôn tải lại và bỏ lời đáp cũ
**Files:** `logic/sales_draft_list_cubit.dart`; test `test/features/sales/logic/sales_draft_list_cubit_test.dart`
- [ ] Test (dùng `Completer` + `fake.onListGate` chặn lời gọi `list` đầu, chỉ thả sau khi gọi `setScope` / `searchByKeyword`): `scope_change_while_first_page_in_flight` (state cuối: `scope == all`, item của lời gọi 2, `listCalls.length == 2`, lời gọi 2 có `createdByUserId == null`); `search_while_first_page_in_flight` (`query == 'an'`, lời gọi 2 có `search == 'an'`). Chạy → FAIL.
- [ ] Sửa: `setScope` / `searchByKeyword` không bị `_isLoading` chặn (vd. `load(isRefresh: true, force: true)`; `force` bỏ qua kiểm `_isLoading`); `finally` chỉ đặt `_isLoading = false` khi `gen == _generation`. `load()` thường (kéo làm mới, `initState`) giữ chặn tải chồng (B1).
- [ ] Chạy test cubit + `sales_draft_list_live_test.dart` → PASS. Sửa hoặc đổi tên `stale_response_after_scope_change_is_dropped` cho đúng ca nó kiểm.

#### Task R1-2: Tab của trang khớp scope của cubit
**Files:** `presentation/pages/sales_draft_list_page.dart`; test `…/widgets/sales_draft_list_body_test.dart` hoặc test trang
- [ ] Test `tab_restores_from_cubit_scope` (cubit đã `setScope(all)` → dựng trang ⇒ tab "Tất cả đơn nháp" được chọn, thẻ có "Tạo bởi"). Chạy → FAIL.
- [ ] Sửa: `_tabIndex` khởi tạo từ `_cubit.state.scope` trong `initState`.
- [ ] Chạy → PASS.

#### Task R1-3: Test còn thiếu
- [ ] `tab_change_calls_set_scope` (5.3), `set_scope_mine_sends_created_by` (B3: từ "Tất cả" về "Đơn của tôi" ⇒ `createdByUserId == actorId`).

#### Task R1-4: TH-05
- [ ] US-06.6 FR-01 (`TH-05…md` ~dòng 1404): "mặc định Chuyển khoản — KI-18" → "mặc định Tiền mặt".

#### Task R1-5a: Nút "Đơn nháp (N)" = tổng nháp của cửa hàng (Q-R1a = B, **người dùng chốt 2026-11-07**)
Căn cứ: TH-05 dòng ~575 (FR-02 SG-02) "số nháp đang có của cửa hàng". Test cũ `totalCount ignores scope and keyword filters` (`sales_draft_list_live_test.dart:75`) đã bị phiên code đổi kỳ vọng `2` → `1` sau khi tìm (không ghi Kết quả) — **khôi phục kỳ vọng cũ** (sau tìm vẫn là tổng).

**Files:** `supabase/migrations/20260830007_sales_draft_rpcs.sql` (`list_sales_order_drafts`), `supabase/tests/sales_th05.sql`, `data/models/sales_draft_list_page.dart`, `data/mappers/sales_draft_json.dart`, `logic/sales_draft_list_cubit.dart`, `logic/sales_draft_list_state.dart` (chú thích `totalCount`); test `data/sales_draft_repository_test.dart`, `data/sales_draft_parity_expectations.dart` / `sales_draft_rpc_parity_test.dart` (nếu so khoá trả về), `logic/sales_draft_list_cubit_test.dart`, `…/bloc/sales_draft_list_live_test.dart`, `support/fake_sales_draft_repository.dart`
- [ ] SQL: thêm vào JSON trả về `'total_count'` = `count(*)` nháp `tenant_id = p_tenant_id and store_id = p_store_id and status = 'active'` — **không** áp `p_search`, `p_created_by`, `offset`.
- [ ] `sales_th05.sql` D04: gọi có `p_search => 'an binh'` và có `p_created_by => v_ub` ⇒ `total_count` bằng nhau và bằng `count(*)` nháp active của store tính trực tiếp từ bảng.
- [ ] `SalesDraftListPage` thêm `final int totalCount;` (bắt buộc); `SalesDraftJson.page` đọc `total_count` (thiếu / không phải số ⇒ `FormatException` như `has_more`). Fake: `totalCount` mặc định = số entry trước khi lọc.
- [ ] Cubit: trang 1 ⇒ `totalCount: page.totalCount`; `loadMore` giữ `totalCount` của trang 1 (không đặt `combined.length`); xoá nháp thành công ⇒ `totalCount - 1` (không dưới 0); `Loading` / `Error` giữ số cũ như hiện có.
- [ ] Test: repository `page_reads_total_count`; cubit `total_count_ignores_scope_and_search` (fake trả `totalCount: 40`, đổi tab / tìm ⇒ vẫn 40), `load_more_keeps_total_count`, `discard_decrements_total_count`; khôi phục kỳ vọng test live `:75`. Chạy → FAIL trước khi sửa, PASS sau.

#### Task R1-5b: Bỏ thẻ QR mẫu ở SG-06 (Q-R1b = B, **người dùng chốt 2026-11-07**)
Căn cứ: TH-05 dòng ~894 (Chuyển khoản chỉ "Số tiền chuyển khoản" + "Mã giao dịch"), dòng ~2236 ("QR động" ngoài phạm vi); cùng loại KI-08.

**Files:** `presentation/pages/sales_checkout_page.dart:372-379` (khối `SalesPaymentQrCard` + 2 `VGap`), xoá `presentation/widgets/sales_payment_qr_card.dart`, `lib/features/sales/presentation.dart:81` (export), `example/lib/sales/preview/sg05_checkout_tab.dart:88-91`, `example/lib/sales/preview/overview_tab.dart:53`; `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` 7.3; test `test/features/sales/sales_checkout_page_test.dart` (hoặc test SG-06 đang có)
- [ ] Test `checkout_transfer_shows_no_qr`: chọn "Chuyển khoản" ⇒ `find.text('VET45 · ACB')`, `find.textContaining('1028 6888')` ⇒ `findsNothing`; `find.byKey(Key('input_sg05_transaction_code'))` ⇒ `findsOneWidget`. Chạy → FAIL.
- [ ] Xoá theo danh sách Files. Chạy → PASS.
- [ ] TH-05 7.3 thêm **KI-23** "SG-06 có thẻ QR mẫu cứng ('VET45 · ACB', số tài khoản giả) khi chọn Chuyển khoản / Kết hợp" — "Đã sửa 8-B2 R1" — P8.
- [ ] `git grep -nE "SalesPaymentQrCard|VET45 · ACB|1028 6888|Chủ tài khoản" -- apps/erp` ⇒ rỗng.

#### Kiểm sau R1 (phiên code chạy, ghi Kết quả)
- [ ] `dart analyze lib/features/sales test/features/sales example/lib/sales` ⇒ 0 lỗi, 0 cảnh báo mới.
- [ ] `flutter test test/features/sales` ⇒ 0 lỗi; `flutter test` cả app ⇒ 55 lỗi = mốc.
- [ ] Việc người dùng (7.2) thêm: reset DB local + chạy `sales_th05.sql` (D04); kiểm tay: SG-02 nút "Đơn nháp (N)" không đổi khi đổi tab / tìm ở SG-01; SG-06 chọn Chuyển khoản không còn QR.

#### Task R1-6: Kết quả ghi lại cho đúng
- [ ] Task 6 ghi lại đúng 2 lệnh grep của 6.2 (Kết quả đang ghi lệnh khác) và kết quả.
- [ ] 6.4: sửa "56 lỗi" thành số đúng (review đo: 2863 đạt / 55 lỗi = mốc) và ghi số đạt.
- [ ] 6.5 `detect-changes`: chưa ghi — chạy và ghi số.
- [ ] Task 0 / 5: ghi tên test bị xoá / đổi: `mine_tab_filters_by_saved_by` (xoá), `cancel_reference_unavailable_no_reload` → `cancel_reference_unavailable_needs_reload` (đổi kỳ vọng theo Q5); `search_filters_loaded_rows` (cũ) vẫn giữ nhờ fake lọc như server — đổi tên hoặc ghi rõ; `totalCount ignores scope and keyword filters` (live `:75`) bị đổi kỳ vọng mà không ghi (R1-5a khôi phục); "Lệch plan" của Task 5 / 6 ghi đủ (thiếu test 5.3, tệp `sales_payment_qr_card.dart` ngoài plan).

### R2 (2026-11-08) — **CHƯA ĐẠT** (còn 2 việc nhỏ)

| Hạng mục | Kết luận |
|---|---|
| R1-1 đổi tab / gõ tìm khi trang 1 đang tải | ✅ `load(force: true)` + `finally` theo `_generation`. Review chạy lại test tạm (chặn đúng lời gọi đầu, thả lời đáp cũ **sau** và **trước** lời đáp mới): cả hai ra `scope=all items=(all) calls=2`; `load()` thường sau đó vẫn chạy (không kẹt `_isLoading`). Test tạm đã xoá |
| R1-2 tab khớp scope cubit | ✅ `sales_draft_list_page.dart` `initState`; test `tab_restores_from_cubit_scope` |
| R1-3 test thiếu | ✅ `tab_change_calls_set_scope`, `set_scope_mine_sends_created_by` |
| R1-4 TH-05 US-06.6 FR-01 | ✅ "mặc định Tiền mặt" |
| R1-5a `total_count` (SQL, model, JSON, cubit, test live `:75` khôi phục `2`) | ✅ app; ❌ ca SQL D04 — **R2-1** |
| R1-5b bỏ QR SG-06 + KI-23 | ✅ (khối QR, tệp, export, 2 chỗ `example/`); ⚠️ khoảng cách — **R2-2** |
| R1-6 Kết quả | ✅ đủ lệnh grep, số 55, `detect-changes`, tên test xoá / đổi |
| Grep 6.2 + grep R1-5b | ✅ rỗng (còn 1 dòng `CHANGELOG.md:199` lịch sử + 2 dòng test phủ định — chấp nhận) |
| `dart analyze lib/features/sales test/features/sales example/lib/sales` | ✅ 0 lỗi, 0 cảnh báo (11 info `deprecated_member_use` có sẵn) |
| `flutter test test/features/sales` | ✅ 1224/1224 |
| `flutter test` cả app | ✅ 2873 đạt / 55 lỗi = mốc; 0 lỗi `features/sales` — khớp Kết quả |

**R2-1 — D04 đọc bảng `sales.sales_order_drafts` bằng vai `authenticated`** (`supabase/tests/sales_th05.sql`, khối D04, sau `set local role authenticated` ở dòng ~739). Các bảng `sales.*` bật RLS và **không có policy nào** (`20260830005_sales_rebuild_schema.sql:459-475`; `grep -i policy` trên migration sales rỗng) ⇒ `count(*)` ra 0 (hoặc "permission denied" nếu `authenticated` không có quyền SELECT), còn `total_count` của RPC (`security definer`) ra số thật ⇒ D04 FAIL. Review chỉ đọc code, chưa chạy SQL.
Cùng kiểu đọc thẳng bảng khi đang là `authenticated` có sẵn từ 8-B1 (chưa ai chạy — 8-B1 Kết quả ghi "Chưa chạy"): `_th05_cancel` (`:171-172`, hàm không `security definer` nên chạy bằng vai người gọi), C01 `:327`, `:353`, `:442`, `:502`, `:547`. Bước 7.2 của 8-B2 chạy cả tệp nên sẽ dừng ở C01 trước khi tới D04. Nếu người dùng đã chạy `sales_th05.sql` sau 8-B1 ra `OK` thì nhận định này sai — bỏ R2-1.

**R2-2 — SG-06 chọn "Chuyển khoản": nhãn "Mã giao dịch" dính sát hàng chip %** (`sales_checkout_page.dart:~371`). Trước đây `VGap.sm` nằm trong khối QR vừa xoá; nay giữa `SalesPaymentPercent…` và `VText('Mã giao dịch')` không còn khoảng cách.

### R2 — việc cần sửa

#### Task R2-1: `sales_th05.sql` đọc bảng bằng quyền chủ
**Files:** `supabase/tests/sales_th05.sql`
- [ ] D04: bọc câu `select count(*) … from sales.sales_order_drafts` bằng `reset role;` … `set local role authenticated;` (claim `request.jwt.claims` giữ nguyên, như mẫu `:402-405`).
- [ ] 8-B1 (cùng tệp, cùng lỗi): `public._th05_cancel` thêm `security definer` (hàm tạo trong giao dịch test bởi chủ DB ⇒ đọc được bảng; RPC bên trong vẫn nhận `p_actor`); các câu đọc thẳng bảng ở C01 `:327`, `:353`, `:442`, `:502`, `:547` bọc `reset role` / `set local role authenticated` như trên. Ghi Kết quả là sửa lỗi test của 8-B1 tìm thấy ở review 8-B2.
- [ ] Không chạy SQL (việc người dùng, 7.2).

#### Task R2-2: Khoảng cách trước "Mã giao dịch"
**Files:** `apps/erp/lib/features/sales/presentation/pages/sales_checkout_page.dart`
- [ ] Trong khối `if (vm.paymentMode != SalesPaymentMode.cash) ...[`, thêm `const VGap.sm(),` trước `VText('Mã giao dịch')` **chỉ khi** `vm.paymentMode != SalesPaymentMode.mixed` (nhánh mixed đã có `VGap.sm` ở cuối khối số tiền chuyển khoản, `:~356`).
- [ ] `flutter test test/features/sales/presentation/sales_checkout_page_test.dart` → PASS.

### Chốt (2026-11-08)
R2-1, R2-2 đã sửa (Kết quả → Task R2); người dùng chốt 8-B2 **ĐẠT**. Giữ tệp plan tới khi người dùng xong 7.2 (`db reset` + `sales_th05.sql`, kiểm tay).
