# 8-B2 — Sales: sửa app theo TH-05 (bỏ nợ cũ / QR / cấn trừ / chính sách trống / "Hoàn tất phiếu", mặc định Tiền mặt, nháp: tải thêm, tìm server, "Tạo bởi")

> Theme 5 (mã cũ P8) · Bước (b) sửa theo TH-05, phần app · Gồm: KI-07, KI-08, KI-10, KI-17, KI-18, KI-21, KI-22, phần sót từ 8-A1 (Q8 `REFERENCE_UNAVAILABLE`, câu "Không xóa được đơn nháp"); thêm 2 sửa SQL nhỏ cho danh sách nháp.
> Trạng thái: Plan ✅ (viết 2026-11-07, duyệt 2026-11-07) | Làm ⬜ | Review ⬜
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

- [ ] **0.1** Viết các test "Task 0" của bảng 5 (B1, B2 cũ, B3 cũ, B4, B6, B8).
- [ ] **0.2** Chạy cùng test có sẵn:
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

- [ ] **1.1** Test `summary_card_has_no_debt_badge` (`find.textContaining('Nợ cũ')` ⇒ `findsNothing`, có khách); `payment_debt_page_has_no_view_debt_card` (`find.text('Xem công nợ')` ⇒ `findsNothing`). Chạy → FAIL. (PDF: xem B12.)
- [ ] **1.2** Sửa theo G1. Chạy test Task 0 + 1.1 → PASS.

### Task 2: G2 KI-08 + G5 KI-18

**Files:** Modify: `presentation/widgets/sales_return_exchange_settlement_body.dart`, `logic/sales_return_exchange_settlement_state.dart:34`, `logic/sales_return_exchange_settlement_cubit.dart:125`. Test: `…/widgets/sales_return_exchange_settlement_body_test.dart`, `…/bloc/sales_return_exchange_settlement_cubit_test.dart`

- [ ] **2.1** Test `settlement_default_method_cash` (state ban đầu và sau `loadAndEvaluate` ⇒ `paymentMethod == SalesPaymentMethod.cash`); `settlement_transfer_shows_no_qr` (chọn Chuyển khoản ⇒ `find.text('QR cửa hàng · ACB')`, `find.text('Nguyễn Văn A')` ⇒ `findsNothing`); `settlement_has_no_offset_debt_switch` (`find.byKey(Key('sw_sg12_offset_debt'))`, `find.text('Sẽ áp dụng khi có module công nợ.')` ⇒ `findsNothing`). Chạy → FAIL.
- [ ] **2.2** Sửa theo Q9, G5. Test cũ kiểm QR / switch: xoá, ghi tên. Chạy → PASS.

### Task 3: G3 KI-10

**Files:** Modify: các tệp KI-10 ở mục 3. Test: session cubit / body / attempt factory / parity

- [ ] **3.1** Sửa theo G3 (xoá code chết; không đổi tham số gửi server).
- [ ] **3.2** Chạy `return_exchange_rpc_parity_test.dart`, `sales_return_exchange_attempt_factory_test.dart`, session cubit / body test → PASS, parity + hash **không sửa** (B9). Test `wgt_sg11_catalog_empty`, `setReturnReason` / `setReturnCondition`: xoá, ghi tên.

### Task 4: G4 KI-17

**Files:** Modify: các tệp KI-17 ở mục 3. Test: `sales_return_exchange_result_page_test.dart`, detail cubit test, repository / parity test của `complete`

- [ ] **4.1** Test `result_body_has_no_complete_button` (`find.text('Hoàn tất phiếu')` ⇒ `findsNothing` với phiếu `confirmed`). Chạy → FAIL.
- [ ] **4.2** Xoá theo Q8. Test `completeIfReady` / `params_complete` / `complete` của fake: xoá, ghi tên. `git grep -n "completeIfReady\|complete_return_exchange\|\.complete(" -- apps/erp/lib/features/sales` ⇒ rỗng (trừ chỗ không liên quan — ghi). Chạy → PASS.

### Task 5: G6 + G7 + G8 danh sách nháp

**Files:**
- Modify: `supabase/migrations/20260830007_sales_draft_rpcs.sql` (`_draft_payload`, `list_sales_order_drafts`, `:586`, `:592`)
- Create: `apps/erp/lib/features/sales/data/models/sales_draft_list_page.dart`
- Modify: `data/sales_draft_repository.dart:129-146`, `data/mappers/sales_draft_json.dart:61-78`, `logic/sales_draft_list_cubit.dart`, `logic/sales_draft_list_state.dart`, `presentation/orchestration/sales_draft_list_scope.dart`, `presentation/pages/sales_draft_list_page.dart`, `presentation/widgets/sales_draft_list_body.dart`, `presentation/models/sales_order_draft/sales_draft_list_item_vm.dart`
- Test: `data/sales_draft_repository_test.dart`, `data/sales_draft_rpc_parity_test.dart`, `data/sales_draft_parity_expectations.dart`, `logic/sales_draft_list_cubit_test.dart`, `…/bloc/sales_draft_list_live_test.dart`, `…/widgets/sales_draft_list_body_test.dart`, `test/features/sales/support/fake_sales_draft_repository.dart`; `supabase/tests/sales_th05.sql`

**Produces:** `SalesDraftListPage`, `SalesDraftListEntry`, `SalesDraftRepository.list({required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId})`, `SalesDraftListCubit.setScope(SalesDraftScopeFilter)`, `.loadMore()`.

- [ ] **5.1** Test repository: `list_sends_search_and_created_by` (params `p_page_size: 25`, `p_search: 'an'`, `p_created_by: 'user-1'`); `list_null_filters_keep_keys` (`containsKey('p_search')` / `('p_created_by')`, giá trị `null`); `page_reads_created_by_name` (`created_by_name: 'Lan'` ⇒ `items.first.createdByName == 'Lan'`; thiếu `created_by_name` ⇒ `null`). Parity `:100`, `:120`: đổi kỳ vọng (đổi có chủ đích, ghi Kết quả).
- [ ] **5.2** Test cubit: `first_load_uses_page_25_and_scope_mine` (`createdByUserId == actorId`); `set_scope_all_sends_null`; `search_reloads_with_server_param` (về trang 1, `cursor == null`); `load_more_appends_next_page` (`hasMore` true, `nextCursor: '25'` ⇒ lời gọi 2 có `cursor: '25'`, 50 dòng); `load_more_ignored_when_no_more`; `load_more_error_keeps_items`; `stale_response_after_scope_change_is_dropped` (lời đáp trang 1 của tab cũ về sau ⇒ không đè); `creator_label_uses_server_name`; `discard_reference_unavailable_needs_reload`; câu `'Không xóa được đơn nháp'` (sửa 2 test có sẵn `:206`, `:286`).
- [ ] **5.3** Test widget: `tab_change_calls_set_scope`; `scroll_end_calls_load_more`; `mine_tab_shows_no_created_by`.
- [ ] **5.4** `sales_th05.sql` thêm: D01 `list_sales_order_drafts(…, p_search => 'an binh')` thấy nháp của "Đại lý An Bình"; D02 `p_created_by` = user B chỉ ra nháp B tạo; D03 `created_by_name` khác `null` và khác UUID. (Ca cần user thứ 2: dựng như `pricing_th04.sql:653-710`.)
- [ ] **5.5** Chạy 5.1–5.3 → FAIL. Sửa theo G6–G8. Chạy test Task 0 (B1, B4–B6) + 5.1–5.3 → PASS.

### Task 6: Tài liệu + kiểm toàn bộ + Kết quả

**Files:** Modify: `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (7.3 KI-07, 08, 10, 17, 18, 21, 22 "Đã sửa 8-B2"; US-01.7 FR-01 ghi "Đơn của tôi" = nháp do tôi tạo; bỏ 🔧 ở FR-05 của EP-03, EP-06 FR-03, US-06.7 FR-02); `docs/refactor/PLAN.md` (dòng 8-B2: Làm ✅ + ngày)

- [ ] **6.1** Sửa tài liệu.
- [ ] **6.2** Các lệnh ra rỗng:
  ```bash
  git grep -nE "Nợ cũ|Xem công nợ|Công nợ cũ của khách|Cấn trừ công nợ hiện tại|QR cửa hàng|Nguyễn Văn A|Chưa cấu hình chính sách|Hoàn tất phiếu|Không hủy được đơn nháp" -- apps/erp/lib/features/sales
  git grep -nE "actorNameResolver|_resolveActorName|catalogEmpty|completeIfReady|setReturnReason|setReturnCondition|customerDebtMinor|existingCustomerDebtMinor" -- apps/erp/lib apps/erp/test
  ```
- [ ] **6.3** `cd apps/erp && dart analyze lib/features/sales test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [ ] **6.4** `flutter test` cả app → số lỗi đúng bằng mốc sau 8-B1; 0 lỗi `features/sales`.
- [ ] **6.5** `node .gitnexus/run.cjs analyze` rồi `detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa.

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

## 10. Review

<!-- Chỉ phiên review ghi. -->
