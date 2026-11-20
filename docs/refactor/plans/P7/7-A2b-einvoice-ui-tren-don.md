# 7-A2b — E-invoice: khu HĐĐT trên đơn sang `EInvoiceRepository`

> **For agentic workers:** REQUIRED SUB-SKILL: dùng superpowers:subagent-driven-development (khuyên dùng) hoặc superpowers:executing-plans để làm theo từng task. Các bước dùng checkbox (`- [ ]`).

> Theme 8 (mã cũ P7) · Bước (a) chuyển kiến trúc, phần UI **trên đơn** · Gồm việc 7.3 (UI; KI-17) — PLAN.md mục Theme 8
> Trạng thái: Plan ✅ (duyệt 2026-11-08) | Làm ✅ 2026-11-08 (còn kiểm tay 5.7 — người dùng) | Review ✅ R2 ĐẠT 2026-11-08
> Trước: 7-A2a (Làm ✅ + Review R2 ✅; 4 trang thiết lập, `FakeEInvoiceConfigurationRepository`, DI `EInvoiceProcessorTrigger` / `EInvoiceConfigurationRepository`). Sau: 7-B2 (KI-01, KI-08, bố cục web), 7-C (xoá module).
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) HD-06 … HD-13, 6.4, KI-17, 9.2 PR 7.3; PLAN.md "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ", "Plan chuyển kiến trúc: giữ nghiệp vụ…". Mẫu: `plans/P7/7-A2a-einvoice-ui-thiet-lap.md`, `plans/P7/7-A1-einvoice-data.md`.

**Goal:** Khu HĐĐT trên đơn (chi tiết đơn + màn kết quả bán) chạy trên `EInvoiceRepository` / `EInvoiceConfigurationRepository` (7-A1), toàn bộ code nằm ở `features/einvoice`, `lib/` không còn import `c45_einvoice_*` (trừ `core/di/injection.dart`, 7-C) và không còn `async_query`.

**Architecture:** `git mv` 25 tệp HĐĐT của `features/sales/presentation` sang `features/einvoice/{logic,presentation}`, chép 6 tệp đơn của `modules/einvoice/presentation` (KI-17), xoá 2 tệp câu lỗi cũ. 3 cubit đổi constructor sang repository; hỏi lại 5 giây chuyển từ `QueryClient.watchQuery` sang `Timer.periodic` trong `OrderEInvoiceCubit`. Sales chỉ nhúng `OrderEInvoiceSection` (import `einvoice/presentation` + `einvoice/data`, không vi phạm R3).

**Tech Stack:** Dart / Flutter, `flutter_bloc`, `equatable`, `get_it`, `flutter_test`.

## Global Constraints

- **Giữ nghiệp vụ:** cùng thứ tự gọi, cùng tham số gửi server, cùng chuỗi chữ, cùng `Key`, cùng luồng sheet. Chỉ đổi ở Q1 (bỏ cache), Q4 (câu lỗi 6.4 — đã chốt ở 7-A1 Q2) và ở các dòng ghi "đổi có chủ đích" trong bảng 3.1.
- **Chuyển nguyên văn:** chỉ đổi import, constructor, lời gọi (mục 5), bắt lỗi (mục 5), hỏi lại (mục 6). Không đổi tên lớp / `enum` / hàm public, trừ tham số constructor ghi ở mục 5.
- **Không đụng:** `modules/einvoice/**` (7-C), `IEInvoiceModule` / `EinvoiceStartup` / `c45_einvoice_*` trong `injection.dart` và `pubspec.yaml` (7-C), `apps/erp/example/` (7-C), `OrderEInvoicePayable` và `SalesEInvoiceEntryCard` (ở lại sales).
- **Luật import** (`dart run tool/check_feature_imports.dart`): không thêm dòng R1 / R2 / R3 mới; sales không import `features/einvoice/logic/**`.
- **Trước khi sửa symbol đang có** (danh sách ở từng Task): chạy `impact({target, direction: "upstream"})` và ghi vào Kết quả; HIGH / CRITICAL thì dừng, báo người dùng.
- **Ghi Kết quả ngay sau mỗi task** theo mẫu mục 9. Phiên code không ghi mục 10.

## Review Focus

1. **Thử lại từ "Lỗi":** bấm phát hành lại → khu chuyển "Đang phát hành" và không nháy về "Lỗi" ở nhịp hỏi lại kế tiếp (Task 0 `B0-3 retry from failed never flashes back to failed`).
2. **`refresh()` trong lúc đang hỏi lại:** không gọi RPC trùng (Task 0 `B0-1 refresh while poll in flight reuses the read`).
3. **Rời trang khi lượt đọc đang treo:** lượt về sau khi `close()` không `emit`, không lỗi (Task 3 `poll result after close is dropped`).
4. **Mạng chậm hơn 5 giây:** không chồng lượt (Task 3 `slow poll does not overlap`).
5. **Màn kết quả bán khi chưa đăng ký `EInvoiceRepository`:** hiện thẻ "Chưa tải được", không văng (Task 3 `result section falls back when repository missing`).

---

## 1. Mục tiêu

Sau 7-A2b:

```text
SalesOrderDetailPage / SalesResultDocumentsSection (features/sales/presentation)
   └─▶ OrderEInvoiceSection (features/einvoice/presentation/widgets)
         └─▶ OrderEInvoiceCubit / OrderInvoiceDeliveryCubit / InvoiceDeliveryHistoryCubit (features/einvoice/logic)
               └─▶ EInvoiceRepository (+ EInvoiceConfigurationRepository cho mẫu) ─▶ SupabaseRpc / functions.invoke
```

- `git grep -n "c45_einvoice\|async_query" -- apps/erp/lib` → chỉ còn `core/di/injection.dart` dòng `c45_einvoice_application` / `c45_einvoice_infrastructure`.
- `git grep -n "QueryClient" -- apps/erp/lib apps/erp/test` → rỗng.
- `apps/erp/lib/features/sales/presentation/{bloc,services}/` không còn tệp HĐĐT; `widgets/einvoice/` không còn.
- KI-17: một chỗ `features/einvoice/presentation`; module chỉ còn bản trùng, xoá ở 7-C.

**Không làm:** KI-08 dòng tóm tắt gửi lại, bố cục web HD-07 … HD-13 (7-B2); gỡ `IEInvoiceModule` / `c45_einvoice_*` / test module (7-C); `apps/erp/example/pubspec.yaml` (7-C).

## 2. Quyết định

7-A1 mục 2 và 7-A2a mục 2 vẫn áp dụng. Số Q của 7-A2b đánh riêng:

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | `QueryClient` cũ còn 2 hành vi phụ: (1) cache 5 phút qua các lần mở trang (`injection.dart:53-59` `gcTime`), observer phát ngay snapshot cũ khi mount; (2) observer phát lại snapshot đang cache cả khi lượt đọc **bắt đầu** và khi **lỗi** (`query_observer.dart:51-57`, `query.dart:201-207`), nên `_applyRefreshSnapshot` chạy cả lúc đó (xoá `errorMessage`, `submitting → idle`) | **Người dùng chốt 2026-11-08 (A): bỏ cả hai, đổi có chủ đích.** Chỉ áp snapshot khi đọc thành công; cubit mới luôn bắt đầu từ `initialProjection`. Test N1, N2 (Task 3) |
| Q2 | Tệp đặt ở đâu | Tệp cubit import (state, snapshot, vm lịch sử, idempotency, 4 service) → `logic/` để không có R2 (cùng cách 7-A2a Q4). Còn lại → `presentation/`. `widgets/einvoice/*` gộp phẳng vào `presentation/widgets/`. **Duyệt plan là chốt** |
| Q3 | Phạm vi dọn DI | 7-A2b bỏ `QueryClient` (DI, `main.dart`, `async_query*` trong `apps/erp/pubspec.yaml`), thêm `InvoiceDocumentSignedUrls` + `EInvoiceRepository`. `IEInvoiceModule` / `EinvoiceStartup` / `c45_einvoice_*` để 7-C (quy tắc dọn module). **Người dùng duyệt thiết kế 2026-11-08** |
| Q4 | Câu lỗi | Đã chốt ở 7-A1 Q2: `OrderEInvoiceErrorMessage.of` → `einvoiceErrorMessage`, `OrderInvoiceDeliveryErrorMessage.of` / `.fallback` → `einvoiceDeliveryErrorMessage` / `einvoiceDeliveryFallbackMessage`. Không cần `overrides`: câu riêng của app trong cubit (xem trước chưa sẵn sàng, bản thể hiện, tài liệu) là hằng chuỗi không gắn mã, giữ nguyên |
| Q5 | KI-17 gộp | App đang dùng bản sales của 5 widget (module bị `hide`, `order_einvoice_section.dart:10-24`) ⇒ giữ bản sales, không chép bản module. `einvoice_action_item` hai bản chỉ khác chú thích + một `const` (`diff` 2026-11-08) ⇒ giữ bản sales; `pre_issue_einvoice_action_sheet` chép từ module dùng bản này. Toast (`issue_*_toast`, `send_*_toast`, `preview_failure_toast`), `OrderDataBlockerResult`, `invoice_delivery_history_view` / `send_invoice_copy` / `invoice_documents_copy` của module: app không dùng ⇒ không chép |
| Q6 | `OPERATION_IN_PROGRESS` ở cubit gửi (`order_invoice_delivery_cubit.dart:138` dò `toString()`) | So `e is AppException && e.code == EInvoiceErrorCodes.operationInProgress`. Repository luôn trả `AppException` (7-A1) ⇒ không đổi hành vi thật |

## 3. Hiện trạng (đo 2026-11-08)

- `features/sales` có 17 tệp `lib/` import `c45_einvoice_*` (`git grep`), gồm 25 tệp HĐĐT ở mục 4 và 4 tệp host: `logic/sales_order_detail_cubit.dart:22-23,37-39,69,73-90`, `logic/sales_order_detail_state.dart:8`, `presentation/pages/sales_order_detail_page.dart:6-7,50-53,255-266,494-521`, `presentation/widgets/sales_result_documents_section.dart:4-5,28,36-37,74-81,162-177`. `sales_transaction_result_body.dart:22-23,29-30,76-77` truyền `eInvoiceMediator` / `executionContext` (chỉ cho HĐĐT).
- `OrderEInvoiceCubit` (`bloc/order_einvoice_cubit.dart`, 855 dòng) gọi `IModuleMediator` + `IExecutionContext` + `QueryClient`. `OrderEInvoiceSection` lấy `QueryClientProvider.of(context)` (`:114`), import `c45_einvoice_presentation` cho `OrderEInvoiceRow`, `showPreIssueEInvoiceActionSheet`, `PreIssueSheetState`, `PreIssueAction`, `showIssueInvoiceConfirmationSheet`, `IssueInvoiceConfirmationSummary`.
- `lib/features/sales/presentation.dart:74,88-103` export 17 tệp HĐĐT (dòng 87 `sales_einvoice_entry_card` giữ).
- `main.dart:1-2,38-39` bọc `QueryClientProvider`; `injection.dart:1,53-59` đăng ký `QueryClient`; `pubspec.yaml:10-11` `async_query`, `async_query_flutter`.
- Test app đụng tới (16 tệp chuyển, 141 ca): `test/features/sales/presentation/{order_einvoice_section_test (30), order_einvoice_mount_test (8), order_einvoice_polling_host_test (9)}`, `bloc/{order_einvoice_cubit_test (33), order_invoice_delivery_cubit_test (10), invoice_delivery_history_cubit_test (4)}`, `services/{file_invoice_document_exporter_test (13), url_invoice_viewer_launcher_test (6)}`, `pages/invoice_delivery_history_page_test (2)`, `widgets/{post_issue_einvoice_action_sheet_test (6), invoice_documents_action_sheet_test (5)}`, `widgets/einvoice/{invoice_delivery_history_view_test (4), resend_invoice_sheet_test (3), send_invoice_sheet_test (6), sg07_app_owned_contract_test (2)}`. Xoá: `support/order_einvoice_error_message_test (3)`. Sửa tại chỗ: `presentation_module/widgets/sales_transaction_result_body_test.dart` (7), `test/core/di/injection_test.dart`. Giữ: `support/order_einvoice_payable_test.dart` (4). Fake hiện có: 13 lớp `implements IModuleMediator` tự viết trong các tệp trên.
- Test module chép (27 ca): `modules/einvoice/presentation/test/widgets/{order_einvoice_row_test (7), pre_issue_einvoice_action_sheet_test (7), issue_invoice_confirmation_sheet_test (4), issuance_failure_banner_test (5)}`, `test/support/einvoice_status_interaction_test (4)`.
- Mốc: `docs/refactor/TEST-BASELINE.md` mục "Sau 8-C": `apps/erp` 55 lỗi (so từng tên).

### 3.1 Đang làm gì (giữ hành vi)

| # | Cơ chế cũ (nguồn) | Hành vi | Sau 7-A2b nằm ở | Test giữ hành vi |
|---|---|---|---|---|
| H1 | `_startPolling` `watchQuery(refetchOnMount: true)` (`order_einvoice_cubit.dart:149-185`) | Bắt đầu hỏi lại → đọc ngay một lượt | `OrderEInvoiceCubit._startPolling` gọi `_pollOnce()` ngay (mục 6) | `polls every five seconds and stops on definite failure` (đọc = 1 sau `pump()`) |
| H2 | `refetchInterval: 5s` | Đọc lại mỗi 5 giây | `Timer.periodic(pollInterval)` | cùng ca |
| H3 | `retry: 0`; observer chỉ đọc `queryState.data` | Lỗi đọc không đổi projection | `_pollOnce` nuốt lỗi | `projection fetch error on mount and tick keeps last projection` |
| H4 | `fetchQuery` cùng khoá với observer (`:120-131`, `query.dart:149-153`) | `refresh()` khi đang có lượt đọc → dùng chung lượt đó | `Future<OrderEInvoiceRefreshSnapshot>? _inFlight` dùng chung | **B0-1** |
| H5 | `setPollingActive(false)` / `close()` (`:136-202`) | Dừng hỏi lại; không đọc sau khi đóng | huỷ timer, bỏ kết quả về sau `close` | **B0-2**; `polls issued delivery, pauses on lifecycle and page inactive` |
| H6 | `setQueryData(processing)` sau issue/retry (`:94-101`) | Không nháy về snapshot "Lỗi" đang cache | Bỏ: không còn cache, chỉ áp khi đọc thành công | **B0-3** |
| H7 | Observer phát snapshot cache khi bắt đầu đọc / lỗi | xoá `errorMessage`, `submitting → idle` | **Đổi có chủ đích (Q1)**: chỉ khi đọc thành công | N2 (Task 3) |
| H8 | Cache `gcTime` 5 phút qua các lần mở trang | Cubit mới hiện ngay snapshot cũ | **Đổi có chủ đích (Q1)**: bắt đầu từ `initialProjection` | N1 (Task 3) |
| H9 | `_loadRefreshSnapshot` (`:204-245`) | projection (lỗi → ném); readiness lỗi → `null`; attempt status chỉ khi `failed`, lỗi → `null` | chép nguyên, đổi lời gọi | `refresh reads safe attempt failure metadata…` |
| H10 | `OrderEInvoicePollingHost` | Hỏi lại khi hiện + app trước + `isPageActive` + `shouldPoll` | chuyển nguyên | 9 ca `order_einvoice_polling_host_test` |
| H11 | `OrderEInvoiceErrorMessage.of` | Dò chuỗi thô (lỗi 7-A1 Q2) | **Đổi có chủ đích (7-A1 Q2)**: `einvoiceErrorMessage` | `einvoice_error_messages_test.dart` (đã có) + ca chuyển từ `order_einvoice_error_message_test` |
| H12 | Section: `cubit` / `onCubitCreated` truyền vào | Test dùng cubit ngoài | giữ nguyên | các ca `order_einvoice_section_test` dùng 2 tham số |
| H13 | Trang chi tiết: `isRegistered<IEInvoiceModule>()` → section / toast "chưa được cấu hình" (`:255-266,494`) | Không có DI einvoice vẫn mở trang | `isRegistered<EInvoiceRepository>()` | `sales_order_detail_page_test` (28 ca, không đăng ký einvoice) |
| H14 | Màn kết quả: thiếu mediator / context → `SalesEInvoiceEntryCard('Chưa tải được')` (`:161-187`) | Không văng | thiếu repository → cùng thẻ | Task 3 `result section falls back when repository missing` |
| H15 | `SalesOrderDetailCubit._loadEInvoiceProjection` (`:73-90`) | Không bao giờ ném; module `null` → `null` | `EInvoiceRepository?` | `sales_order_detail_cubit_test` (không đổi) |

## 4. Tệp

Chuyển bằng `git mv` (nguồn `apps/erp/lib/features/sales/presentation/`, đích `apps/erp/lib/features/einvoice/`):

| Nguồn | Đích |
|---|---|
| `bloc/order_einvoice_cubit.dart`, `bloc/order_einvoice_state.dart`, `bloc/order_einvoice_refresh_snapshot.dart`, `bloc/order_invoice_delivery_cubit.dart`, `bloc/order_invoice_delivery_state.dart`, `bloc/invoice_delivery_history_cubit.dart`, `bloc/invoice_delivery_history_state.dart` | `logic/` (cùng tên) |
| `models/invoice_delivery_history_vm.dart`, `support/order_einvoice_idempotency_key_factory.dart`, `services/{i_invoice_document_exporter,i_invoice_viewer_launcher,file_invoice_document_exporter,url_invoice_viewer_launcher}.dart` | `logic/` (cùng tên) |
| `pages/invoice_delivery_history_page.dart` | `presentation/pages/` |
| `support/order_einvoice_post_issue_copy.dart`, `support/order_invoice_delivery_copy.dart` | `presentation/support/` |
| `widgets/order_einvoice_section.dart`, `widgets/order_einvoice_polling_host.dart`, `widgets/einvoice/{einvoice_action_item,invoice_delivery_history_view,invoice_delivery_recipient_form,invoice_documents_action_sheet,post_issue_einvoice_action_sheet,resend_invoice_sheet,send_invoice_sheet}.dart` | `presentation/widgets/` (phẳng) |

Chép từ `modules/einvoice/presentation/lib/src/` (Q5): `widgets/{order_einvoice_row,pre_issue_einvoice_action_sheet,issue_invoice_confirmation_sheet,issuance_failure_banner}.dart` → `presentation/widgets/`; `support/{order_einvoice_copy,einvoice_status_interaction}.dart` → `presentation/support/`.

Xoá: `support/order_einvoice_error_message.dart`, `support/order_invoice_delivery_error_message.dart`.

Sửa: `features/sales/logic/sales_order_detail_cubit.dart`, `sales_order_detail_state.dart`, `features/sales/presentation/pages/sales_order_detail_page.dart`, `widgets/sales_result_documents_section.dart`, `widgets/sales_transaction_result_body.dart`, `features/sales/presentation.dart`, `core/di/injection.dart`, `main.dart`, `pubspec.yaml`, `docs/refactor/PLAN.md` (dòng 7-A2b), `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` (KI-17).

Test: mục 7.

## 5. Constructor, lời gọi, bắt lỗi

Constructor mới (bỏ `IExecutionContext`, `IModuleMediator`, `QueryClient`; các tham số khác giữ):

```dart
OrderEInvoiceCubit({
  required String salesOrderId, required int orderVersion,
  required OrderInvoiceProjectionDto initialProjection,
  IssuanceReadinessDto? initialReadiness, bool isBuyerNotReady = false,
  bool hasLoadedInitialProjection = true,
  required EInvoiceRepository repository,
  required EInvoiceConfigurationRepository configurationRepository,
  IInvoiceViewerLauncher? viewerLauncher, IInvoiceDocumentExporter? documentExporter,
  OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory = const OrderEInvoiceIdempotencyKeyFactory(),
  Duration pollInterval = const Duration(seconds: 5),
});
OrderInvoiceDeliveryCubit({required String salesOrderId, required EInvoiceRepository repository, OrderEInvoiceIdempotencyKeyFactory idempotencyKeyFactory = const OrderEInvoiceIdempotencyKeyFactory()});
InvoiceDeliveryHistoryCubit({required String salesOrderId, required EInvoiceRepository repository});
InvoiceDeliveryHistoryPage({Key? key, required String salesOrderId, required EInvoiceRepository repository});
OrderEInvoiceSection({…như cũ…, required EInvoiceRepository repository, required EInvoiceConfigurationRepository configurationRepository}); // bỏ mediator, executionContext
SalesResultDocumentsSection / SalesTransactionResultBody({…, EInvoiceRepository? eInvoiceRepository, EInvoiceConfigurationRepository? eInvoiceConfigurationRepository}); // bỏ eInvoiceMediator, executionContext
SalesOrderDetailCubit({…, EInvoiceRepository? eInvoiceRepository}); // bỏ eInvoiceModule
```

`SalesResultDocumentsSection` lấy `eInvoiceRepository ?? (getIt.isRegistered<EInvoiceRepository>() ? getIt<EInvoiceRepository>() : null)`, tương tự cho cấu hình; một trong hai `null` → thẻ "Chưa tải được" (H14).

Lời gọi (tham số giống Command / Query cũ, bỏ `tenantId` / `actorId`):

| Cũ | Mới |
|---|---|
| `GetOrderInvoiceProjectionQuery` | `repository.getProjection(salesOrderId)` |
| `GetIssuanceReadinessQuery` | `repository.getReadiness(salesOrderId)` |
| `GetIssuanceAttemptStatusQuery` | `repository.getAttemptStatus(salesOrderId)` |
| `RetryIssuanceCommand(salesOrderId, expectedOrderVersion, idempotencyKey)` | `repository.retry(salesOrderId: …, expectedOrderVersion: …, idempotencyKey: …)` |
| `IssueInvoiceCommand(salesOrderId, sourceVersion, idempotencyKey)` | `repository.issue(salesOrderId: …, sourceVersion: orderVersion.toString(), idempotencyKey: …)` |
| `RequestInvoicePreviewCommand(salesOrderId, expectedOrderVersion)` | `repository.requestPreview(salesOrderId: …, expectedOrderVersion: …)` |
| `GetInvoicePreviewQuery` | `repository.getPreview(salesOrderId)` |
| `RequestOfficialInvoiceViewCommand` | `repository.requestOfficialView(salesOrderId)` |
| `GetElectronicInvoiceDetailQuery` | `repository.getDetail(salesOrderId)` |
| `RequestInvoiceDocumentCommand(salesOrderId, documentType)` | `repository.requestDocument(salesOrderId: …, documentType: …)` |
| `GetInvoiceDocumentsQuery` | `repository.getDocuments(salesOrderId)` |
| `GetIssuanceProfileQuery` / `ListProviderTemplatesQuery` | `configurationRepository.getIssuanceProfile()` / `.listTemplates()` |
| `GetSendInvoiceSheetContextQuery` | `repository.getSendSheetContext(salesOrderId)` |
| `SendElectronicInvoiceCommand(salesOrderId, recipientEmail, idempotencyKey)` | `repository.send(salesOrderId: …, recipientEmail: …, idempotencyKey: …)` |
| `GetInvoiceDeliveryHistoryQuery` | `repository.getDeliveryHistory(salesOrderId)` |

Bắt lỗi / mã:

| Chỗ | Cũ | Mới |
|---|---|---|
| 3 cubit, mọi `OrderEInvoiceErrorMessage.of(e)` | dò chuỗi | `einvoiceErrorMessage(e)` |
| cubit gửi + lịch sử | `OrderInvoiceDeliveryErrorMessage.of(e)` / `.fallback` | `einvoiceDeliveryErrorMessage(e)` / `einvoiceDeliveryFallbackMessage` |
| cubit gửi `:138` | `toString().contains('OPERATION_IN_PROGRESS')` | Q6 |
| Section `:288` | `EInvoiceBlockedException(EInvoiceBlockedCodes.configNotReady)` | `const AppException(EInvoiceErrorCodes.configNotReady)` |
| Section `providerConnected` | `EInvoiceBlockedCodes.providerNotConnected` | `EInvoiceErrorCodes.providerNotConnected` |
| `_applyRefreshSnapshot` blocker | chuỗi `'BUYER_TAX_CODE_REQUIRED'` … | `EInvoiceErrorCodes.buyerTaxCodeRequired`, `buyerDataIncomplete`, chuỗi `'BUYER_SOURCE_UNAVAILABLE'` giữ nguyên (không có hằng) |

Kiểu dữ liệu: mọi DTO / `enum` lấy từ `package:erp/features/einvoice/data/models.dart` (7-A1, cùng tên field).

## 6. Hỏi lại trong `OrderEInvoiceCubit` (Q1)

- Trường: `Timer? _pollTimer; Future<OrderEInvoiceRefreshSnapshot>? _inFlight;`. Bỏ `_pollObserver`, `_pollSubscription`, `_startingPolling`.
- `setPollingActive(bool active)`: giữ chữ ký. `true` → nếu `_pollTimer == null && !isClosed`: `unawaited(_pollOnce())` rồi `_pollTimer = Timer.periodic(pollInterval, (_) => unawaited(_pollOnce()))`. `false` → `cancel`, gán `null`.
- `_read()`: `_inFlight ??= _loadRefreshSnapshot().whenComplete(() => _inFlight = null); return _inFlight!;`. Một lượt đang chạy thì mọi lời gọi dùng chung (H4, Review Focus 4: nhịp đến khi lượt trước còn treo không gọi thêm).
- `_pollOnce()` và `refresh()`: `if (isClosed || !state.isPageActive) return; try { final s = await _read(); if (!isClosed) _applyRefreshSnapshot(s); } catch (_) {}`.
- `issueOrRetry`: bỏ khối `setQueryData` (`:94-101`); giữ `emit(state.toProcessing()); await refresh();`.
- `close()`: `_pollTimer?.cancel(); _pollTimer = null;` rồi `super.close()`.
- `_loadRefreshSnapshot()` không nhận `tenantId` / `actorId` nữa.

## 7. Task

### Task 0: Bước 0 — test giữ hành vi hỏi lại trên code cũ

**Files:**
- Modify: `apps/erp/test/features/sales/presentation/order_einvoice_polling_host_test.dart` (thêm 3 ca, dùng `_ProjectionMediator` có sẵn; thêm `Completer<void>? gate` — nhánh `GetOrderInvoiceProjectionQuery` `await gate?.future` trước khi trả; `executeCommandAsync` nhận `RetryIssuanceCommand`: gán `projection` = `processing` rồi trả `IssueInvoiceResultDto(issuanceId: 'iss-1', attemptId: 'att-1', status: IssuanceAttemptStatus.submitted)`)

Chỉ thêm test, không sửa `lib/`. Dùng `testWidgets` + `tester.pump(Duration)` (thời gian giả; tệp cubit test không có `fakeAsync`). Ba ca phải xanh trên code cũ trước Task 1; Task 3 giữ nguyên điều kiện kiểm.

- [ ] **B0-1** `refresh while poll in flight reuses the read`: projection `processing`, `gate = Completer()`. `pumpWidget(wrapHost)` + `pump()` → `reads == 1` (lượt đang treo). Gọi `unawaited(cubit.refresh())`, `pump()` → `reads == 1`. `gate.complete()`, `pump()` → `reads == 1`.
- [ ] **B0-2** `closing cubit stops polling`: projection `processing`. Mount, `pump()` → `reads == 1`. `pumpWidget(SizedBox())`, `await cubit.close()`, `pump(15s)` → `reads == 1`.
- [ ] **B0-3** `retry from failed never flashes back to failed`: `mediator.projection` = `failed`, `actions: [OrderInvoiceAction.retryIssue]`. Mount, `pump()` (state `failed`, terminal ⇒ host không hỏi lại). Ghi `states = <IssuanceDisplayState>[]` từ `cubit.stream`. `await cubit.issueOrRetry()` (trong `tester.runAsync` nếu cần), `pump()`, rồi `pump(5s)` hai lần → `states` có `processing`, sau phần tử `processing` đầu tiên không còn `failed`; `cubit.state.projection.issuanceDisplayState == processing`.
- [ ] Chạy `cd apps/erp && flutter test test/features/sales/presentation/order_einvoice_polling_host_test.dart` → PASS (12 ca). Nếu ca nào đỏ trên code cũ: dừng, ghi vào Kết quả, báo người dùng (đó là hành vi cũ khác bảng 3.1).
- [ ] Commit `test(einvoice): 7-A2b bước 0 — giữ hành vi hỏi lại khu HĐĐT trên đơn`.

### Task 1: Fake `EInvoiceRepository`

**Files:**
- Create: `apps/erp/test/features/einvoice/support/fake_einvoice_repository.dart`
- Test: `apps/erp/test/features/einvoice/support/fake_einvoice_repository_test.dart`

**Interfaces:** Produces:

```dart
class FakeEInvoiceRepository extends EInvoiceRepository {
  FakeEInvoiceRepository({OrderInvoiceProjectionDto? projection});
  final List<String> calls;                         // tên hàm theo thứ tự, vd 'getProjection'
  OrderInvoiceProjectionDto projection;             // getProjection trả
  IssuanceReadinessDto? readiness;                  // null → ném AppException(systemError)
  IssuanceAttemptStatusDto? attemptStatus;          // null → ném AppException(notFound)
  final List<InvoicePreviewResultDto> previewResults;   // getPreview lấy lần lượt, hết thì lặp phần tử cuối
  final List<ElectronicInvoiceDetailDto> detailResults; // getDetail, cùng quy tắc
  final List<InvoiceDocumentsDto> documentResults;      // getDocuments, cùng quy tắc
  InvoicePreviewResultDto requestPreviewResult; OfficialInvoiceViewDto officialViewResult;
  InvoiceDocumentRetrievalDto documentResult; IssueInvoiceResultDto issueResult;
  SendInvoiceSheetContextDto? sendContext; SendInvoiceResultDto sendResult;
  InvoiceDeliveryHistoryDto history;
  final Map<String, Object> throwOn;                // tên hàm → lỗi ném (sau khi ghi calls)
  final Map<String, Completer<void>> holdOn;        // tên hàm → chờ trước khi trả
}
```

- Constructor cha: `SupabaseRpc` giả ném `UnimplementedError`, `EInvoiceProcessorTrigger` / `InvoiceDocumentSignedUrls` dựng như `fake_einvoice_configuration_repository.dart`, `tenantId: () async => 'tenant-1'`, `actorId: () async => 'actor-1'`; override cả 14 hàm public.
- Giá trị mặc định lấy từ `FakeEInvoiceFixtures` của module (`issueProcessing`, `projection(...)`, readiness `ready`), viết lại bằng kiểu app.

- [ ] Test (đỏ): `calls` ghi đúng thứ tự `getProjection, getReadiness`; `throwOn['getProjection'] = const AppException('NO_PERMISSION')` → ném đúng lỗi và vẫn ghi `calls`; `holdOn` giữ `getProjection` tới khi `complete`; `previewResults [a, b]` → lần 1 `a`, lần 2 `b`, lần 3 `b`.
- [ ] Viết fake → `flutter test test/features/einvoice/support/` PASS.
- [ ] Commit `test(einvoice): 7-A2b fake EInvoiceRepository`.

### Task 2: Chuyển tệp (chưa đổi hành vi)

**Files:** mục 4 (`git mv` 25 tệp, chép 6 tệp module); 16 tệp test chuyển theo bảng dưới; `features/sales/presentation.dart`.

| Test nguồn (`test/features/sales/presentation/`) | Đích (`test/features/einvoice/`) |
|---|---|
| `order_einvoice_section_test`, `order_einvoice_mount_test`, `order_einvoice_polling_host_test` | `presentation/` |
| `bloc/*` (3 tệp) | `logic/` |
| `services/*` (2 tệp) | `logic/` |
| `pages/invoice_delivery_history_page_test` | `presentation/pages/` |
| `widgets/{post_issue_einvoice_action_sheet_test,invoice_documents_action_sheet_test}`, `widgets/einvoice/*` (4 tệp) | `presentation/widgets/` |

- [ ] `impact` cho `OrderEInvoiceSection`, `OrderEInvoiceCubit`, `OrderInvoiceDeliveryCubit`, `InvoiceDeliveryHistoryCubit`, `InvoiceDeliveryHistoryPage`; ghi vào Kết quả.
- [ ] `git mv` theo mục 4 và bảng test; sửa import tương đối / `package:erp/...` cho đúng chỗ mới. Tệp vẫn import `c45_einvoice_*` như cũ ở bước này.
- [ ] Chép 6 tệp module (Q5): đổi import nội bộ module sang tệp app; `pre_issue_einvoice_action_sheet.dart` import `einvoice_action_item.dart` của app. Section đổi `import 'package:c45_einvoice_presentation/presentation.dart' hide …` thành import 4 widget vừa chép.
- [ ] `presentation.dart` của sales: xoá dòng 74, 88-103 (giữ 87).
- [ ] `sales_result_documents_section.dart`, `sales_transaction_result_body.dart`, `sales_order_detail_page.dart`: sửa import sang đường dẫn mới (chưa đổi tham số).
- [ ] `sg07_app_owned_contract_test.dart`: đường dẫn `lib/features/einvoice/presentation/widgets/order_einvoice_section.dart`; chuỗi `"'einvoice/send_invoice_sheet.dart'"` → `"'send_invoice_sheet.dart'"`, tương tự resend (đổi do gộp phẳng, cùng ý kiểm).
- [ ] `dart analyze lib test/features/einvoice test/features/sales` sạch; `flutter test test/features/einvoice test/features/sales` → cùng số ca đạt như trước Task 2 (ghi số).
- [ ] Commit `refactor(einvoice): 7-A2b chuyển khu HĐĐT trên đơn sang features/einvoice`.

### Task 3: Cubit + widget + host sang repository, hỏi lại bằng `Timer`

**Files:** mọi tệp mục 4 (trừ đã xoá), 4 tệp host sales, 2 tệp câu lỗi xoá; test: 16 tệp đã chuyển ở Task 2, `sales_transaction_result_body_test.dart`, `test/features/einvoice/logic/einvoice_error_messages_test.dart`; Create: 5 tệp test chép từ module dưới `test/features/einvoice/presentation/{widgets,support}/`.

**Interfaces:**
- Consumes: `EInvoiceRepository`, `EInvoiceConfigurationRepository`, `EInvoiceErrorCodes`, `einvoiceErrorMessage`, `einvoiceDeliveryErrorMessage`, `einvoiceDeliveryFallbackMessage` (7-A1); `FakeEInvoiceRepository` (Task 1); `FakeEInvoiceConfigurationRepository` (7-A2a).
- Produces: constructor mục 5.

- [ ] `impact` cho `SalesOrderDetailCubit`, `SalesOrderDetailState`, `SalesResultDocumentsSection`, `SalesTransactionResultBody`, `OrderEInvoiceErrorMessage`, `OrderInvoiceDeliveryErrorMessage`; ghi vào Kết quả.
- [ ] Đổi test sang fake (đỏ): mỗi lớp `_…Mediator implements IModuleMediator` → `FakeEInvoiceRepository` (hoặc lớp con) cấu hình cùng dữ liệu; lỗi thô (`Exception('NO_PERMISSION')`…) → `AppException('<mã>')` như repository thật trả; bỏ `QueryClient` / `QueryClientProvider` / `FakeExecutionContext`. Không đổi điều kiện `expect` nào, trừ câu lỗi đổi theo H11 (ghi từng ca đổi câu vào Kết quả).
- [ ] Thêm ca mới (đỏ):
  - `logic/order_einvoice_cubit_test.dart`:
    - **N1** `new cubit starts from initial projection`: cubit A đọc `issued` rồi `close`; cubit B cùng `salesOrderId`, `initialProjection notIssued`, `hasLoadedInitialProjection: false` → `state.projection.issuanceDisplayState == notIssued` trước lượt đọc đầu.
    - **N2** `poll error keeps error message`: `pollInterval: 10ms`, projection `processing`; `throwOn['requestPreview'] = const AppException('NO_PERMISSION')`, `await requestPreview()` → `errorMessage == 'Bạn không có quyền thực hiện thao tác này.'`. Đặt `throwOn['getProjection']`, `setPollingActive(true)`, chờ 25ms → `errorMessage` không đổi. Xoá `throwOn['getProjection']`, chờ 25ms → `errorMessage == null`.
    - `slow poll does not overlap`: `pollInterval: 10ms`, `holdOn['getProjection']`; chờ 35ms → `calls.where((c) => c == 'getProjection').length == 1`; `complete`, chờ 15ms → `2`.
    - `poll result after close is dropped`: `holdOn`, `setPollingActive(true)`, `await close()`, `complete` → không ném, không `emit` (lắng `stream` trước khi đóng, đếm 0 phần tử sau `close`).
  - `presentation_module/widgets/sales_transaction_result_body_test.dart`: `result section falls back when repository missing` — không truyền repository, `GetIt` không đăng ký → thấy `SalesEInvoiceEntryCard` với `'Chưa tải được'`, không thấy `Key('sales_result_einvoice_section')`.
  - `logic/einvoice_error_messages_test.dart`: chuyển 3 ca của `order_einvoice_error_message_test.dart` sang `einvoiceErrorMessage` (cùng điều kiện "không lộ chuỗi kỹ thuật"); xoá tệp cũ.
- [ ] Chép 5 tệp test module (mục 3), đổi `FakeEInvoiceFixtures.projection` sang `OrderInvoiceProjectionDto` app, import tệp app. Chạy → đỏ chỉ vì chưa đổi kiểu (nếu đã xanh vẫn được).
- [ ] Sửa `lib/` theo mục 5, 6: đổi import DTO sang `data/models.dart`; 3 cubit + section + trang lịch sử + 2 sheet gửi đổi constructor / lời gọi; xoá 2 tệp câu lỗi; `SalesOrderDetailCubit` / `State` dùng `EInvoiceRepository?`; trang chi tiết `isRegistered<EInvoiceRepository>()` (H13) và truyền `repository: getIt<EInvoiceRepository>()`, `configurationRepository: getIt<EInvoiceConfigurationRepository>()`; màn kết quả theo mục 5 (H14).
- [ ] `flutter test test/features/einvoice test/features/sales` → PASS. Số ca = trước Task 3 − 3 (tệp câu lỗi xoá) + 3 (ca chuyển sang `einvoice_error_messages_test`) + 4 (N1, N2, slow, close) + 1 (fallback) + 27 (module). Ghi số.
- [ ] `dart analyze lib test/features/einvoice test/features/sales` sạch; `dart run tool/check_feature_imports.dart` không dòng mới; `git grep -n "c45_einvoice\|async_query" -- apps/erp/lib/features` → rỗng.
- [ ] Commit `feat(einvoice): 7-A2b khu HĐĐT trên đơn dùng EInvoiceRepository, hỏi lại bằng Timer`.

### Task 4: DI, `main.dart`, pubspec

**Files:**
- Modify: `apps/erp/lib/core/di/injection.dart:1,53-59,270-281`, `apps/erp/lib/main.dart:1-2,38-39`, `apps/erp/pubspec.yaml:10-11`
- Test: `apps/erp/test/core/di/injection_test.dart`

- [ ] `impact` cho `initDependencies` (hàm dựng DI trong `injection.dart`), `ErpApp.build`; ghi vào Kết quả.
- [ ] Test (đỏ): thêm `expect(getIt.isRegistered<InvoiceDocumentSignedUrls>(), isTrue); expect(getIt.isRegistered<EInvoiceRepository>(), isTrue);` giữ các dòng `IEInvoiceModule`.
- [ ] `injection.dart`: xoá import `async_query` và khối `QueryClient` (`:53-59`); sau `EInvoiceConfigurationRepository` thêm `registerLazySingleton<InvoiceDocumentSignedUrls>(() => InvoiceDocumentSignedUrls(storage: supabaseModule.client.storage))` và `registerLazySingleton<EInvoiceRepository>(…)` với `rpc` / `trigger` / `tenantId` / `actorId` viết giống hệt `EInvoiceConfigurationRepository` (`:273-280`), `signedUrls: getIt<InvoiceDocumentSignedUrls>()`.
- [ ] `main.dart`: bỏ 2 import và `QueryClientProvider`, `ErpApp.build` trả thẳng `MaterialApp.router(...)`.
- [ ] `pubspec.yaml`: xoá `async_query`, `async_query_flutter`; `flutter pub get`.
- [ ] `flutter test test/core/di/injection_test.dart test/features/einvoice test/features/sales` → PASS; `git grep -n "QueryClient\|async_query" -- apps/erp/lib apps/erp/test` → rỗng.
- [ ] Commit `refactor(einvoice): 7-A2b DI EInvoiceRepository, bỏ QueryClient`.

### Task 5: Kiểm cuối + tài liệu

- [ ] **5.1** `cd apps/erp && dart analyze lib test` → không lỗi / cảnh báo mới.
- [ ] **5.2** `dart run tool/check_feature_imports.dart` → không dòng mới so với trước 7-A2b (ghi danh sách dòng `einvoice` / `sales` mới nếu có).
- [ ] **5.3** `git grep -n "c45_einvoice" -- apps/erp/lib` → chỉ `core/di/injection.dart`. `git grep -n "features/sales/presentation/\(bloc\|services\)/.*invoice\|widgets/einvoice/" -- apps/erp` → rỗng.
- [ ] **5.4** `flutter test test/features/einvoice/` → PASS (ghi số ca). `flutter test` cả app → số lỗi đúng 55 như `TEST-BASELINE.md` mục "Sau 8-C" (so từng tên; tên test chuyển chỗ không nằm trong danh sách lỗi). `cd modules/einvoice/presentation && flutter test` → không đổi so với sau 7-A2a.
- [ ] **5.5** TH-08: KI-17 cột cuối "✅ 7-A2a (thiết lập) + 7-A2b (trên đơn) (2026-…); bản trùng module xoá ở 7-C". PLAN.md: dòng 7-A2b cột Làm.
- [ ] **5.6** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "compare", base_ref: "<commit trước Task 0>"})`. Chỉ được có tệp mục 4 + test + tài liệu. Ghi số tệp / symbol / luồng / rủi ro.
- [ ] **5.7** Kiểm tay (iPhone + web, Dev, đơn Hoàn tất, MISA đã kết nối, cron `einvoice-processor` chạy):
  - Chi tiết đơn: khu HĐĐT hiện đúng trạng thái; xem trước mở trình xem; phát hành → "Đang phát hành" → "Đã phát hành" không cần rời trang;
  - Sau phát hành: xem bản chính thức, tải PDF / XML, gửi email, gửi lại, mở lịch sử gửi;
  - Màn kết quả bán: thẻ HĐĐT đổi từ "đang tải" sang trạng thái thật;
  - Đưa app xuống nền khi đang "Đang phát hành", mở lại → tiếp tục cập nhật.

## 8. Rủi ro / lưu ý

- **Trùng tên với module:** sau 7-A2b app có `PostIssueEInvoiceActionSheet`, `OrderEInvoiceRow`… ở `features/einvoice`, module cũng export cùng tên. Không tệp `lib/` nào còn import `c45_einvoice_presentation` ⇒ không đụng. Test chép từ module chỉ import tệp app.
- **Lượt đọc treo khi đổi tenant:** repository đọc `tenantId()` mỗi lượt; trang dựng lại theo `StoreShell` nên cubit cũ bị đóng (Review Focus 3).
- **Cubit test dùng thời gian thật:** app không có `fake_async` (7-A2a Task 3); ca mới dùng `pollInterval` ngắn + `Future.delayed`. Ca widget dùng `tester.pump(Duration)`.
- **`apps/erp/example/pubspec.yaml`** còn `async_query` — để 7-C.

## 9. Kết quả (phiên làm code ghi)

Mỗi task ghi ngay sau khi xong:

- **Task N — ✅ / ⚠️**
  - Tệp:dòng đã đổi / thêm:
  - Lệch plan + lý do:
  - Test thêm / sửa, lệnh, số ca pass / fail:
  - Impact (symbol, số caller, luồng, mức rủi ro):
  - Ghi chú cho review:

- **Task 1–4 — ✅ (ghi lại sau R1, 2026-11-08)**
  - Tệp: Task 1 `test/features/einvoice/support/fake_einvoice_repository.dart`; Task 2 `git mv` 25 tệp + chép 6 tệp module (mục 4); Task 3 cubit / section / trang lịch sử / host sales (mục 5, 6); Task 4 `core/di/injection.dart`, `main.dart`, `pubspec.yaml`.
  - Lệch plan: (1) 4 service (`i_invoice_*`, `file_*`, `url_*`) đặt ở `features/einvoice/data/` thay vì `logic/` vì sales dùng chúng (R3); không re-export qua `models.dart`, tệp dùng thì import thẳng. (2) Cubit test khai báo lại các lớp `…Command` / `…Query` giả để giữ nguyên `expect`. (3) `apps/erp/example/lib/sales/preview/sg06_result_tab.dart` sửa import vì `presentation.dart` của sales bỏ export. (4) `FakeEInvoiceScenario` chép sang `test/features/einvoice/support/fake_einvoice_scenario.dart` (17 giá trị đang dùng) để test không phụ thuộc module.
  - Sửa theo R1: R1-1 bỏ dòng dò chuỗi thô trong `einvoice_error_messages.dart`, lỗi test đổi sang `AppException`, 3 ca chuyển + 1 ca `serverMessage` không đổi câu; R1-2 4 test chép từ module import tệp app; R1-3 2 ca section xanh; R1-4 thêm B0-1 / B0-2 / B0-3 vào `order_einvoice_polling_host_test.dart` (12 ca), `slow poll does not overlap` dùng `pollInterval: 10ms`; R1-5, R1-6 như trên.
  - Test: `flutter test test/features/einvoice test/features/sales test/core/di/injection_test.dart` → 1357 đạt, 10 bỏ qua, 0 đỏ.
  - Ghi chú: B0-3 không dùng `runAsync` / `closeSubject` (treo vì `cubit.close()` trong vùng thời gian giả); dùng `unawaited` + `pump`.
- **Task 5 — chưa**: `detect_changes`, so 55 lỗi nền (`TEST-BASELINE.md`), kiểm tay 5.7.

## 10. Review

### R1 — 2026-11-08: **CHƯA ĐẠT**

Phạm vi xem: `df9ddbd0a` (Task 1), `4f8b6aa6c` (Task 2), cùng phần chưa commit trong cây làm việc (Task 3, Task 4). Mục 9 Kết quả còn trống, nên review tự đo lại mọi số.

| Hạng mục | Kết quả |
|---|---|
| `dart analyze lib test` | ✅ không có error hay warning. Có 1 info mới: `data/file_invoice_document_exporter.dart:9` unnecessary_import (xem R1-5) |
| `check_feature_imports` | ✅ không có dòng `einvoice` / `sales` mới |
| `git grep c45_einvoice\|async_query -- lib` | ✅ chỉ còn `core/di/injection.dart:2-3` |
| `git grep QueryClient -- lib test` | ✅ rỗng |
| `flutter test test/features/einvoice test/features/sales test/core/di/injection_test.dart` | ❌ 1348 ca đạt, 2 ca đỏ (R1-3) |
| Cubit hỏi lại (mục 6) | ✅ đúng thiết kế: `_read` dùng chung lượt, `_pollOnce`/`refresh` nuốt lỗi, bỏ `setQueryData`, `close` huỷ timer |
| Lời gọi, bắt lỗi (mục 5), Q6 | ✅ khớp bảng; `order_invoice_delivery_cubit` so `e.code` |
| DI / `main.dart` / pubspec (Task 4) | ✅ khớp plan; `injection_test` có thêm 2 dòng `expect` |
| Host sales (H13, H14, H15) | ✅; trang chi tiết kiểm thêm `isRegistered<EInvoiceConfigurationRepository>()` (hợp lý) |
| Câu lỗi (Q4 / H11) | ❌ đưa lại việc dò chuỗi thô (R1-1) |
| Test chép từ module (27 ca) | ❌ 4/5 tệp vẫn test widget của module (R1-2) |
| Task 0 (B0-1, B0-2, B0-3) | ❌ chưa có (R1-4) |
| Task 5 (tài liệu, `detect_changes`, kiểm tay), mục 9 | ❌ chưa làm (R1-7) |

#### R1 — việc cần sửa

- [ ] **R1-1 (nặng) Câu lỗi dò lại chuỗi thô, ngược với 7-A1 Q2.** `logic/einvoice_error_messages.dart:29` thêm `if (raw.contains(targetCode)) return true;`. `raw` lấy từ `toString()` của lỗi, mà `toString()` của `AppException` có cả `serverMessage`. Hệ quả: một `AppException(SYSTEM_ERROR)` có `serverMessage` nhắc tới `NOT_FOUND` / `NO_PERMISSION` sẽ ra sai câu. Dòng này cũng đổi hành vi 4 trang thiết lập của 7-A2a.
  - Xoá dòng 29.
  - Trong test, đổi lỗi thô sang `AppException('<mã>')` như plan Task 3 đã ghi, ví dụ `order_einvoice_cubit_test.dart:1492` `Exception('RPC error: NO_PERMISSION')` → `const AppException('NO_PERMISSION')`. Làm tương tự ở các tệp test khác còn đỏ sau khi xoá dòng.
  - Chuyển 3 ca của `order_einvoice_error_message_test.dart` đã xoá (`missing invoice template says to choose a template`, `fully returned order has its own message`, `source version mismatch asks to reload`) sang `test/features/einvoice/logic/einvoice_error_messages_test.dart`, gọi `einvoiceErrorMessage(const AppException('<mã>'))`. Bước này hiện chưa làm: tệp test đó không đổi.
- [ ] **R1-2 (nặng) 4 tệp test chép từ module vẫn test widget của module.** `presentation/widgets/{pre_issue_einvoice_action_sheet,issue_invoice_confirmation_sheet,issuance_failure_banner}_test.dart` và `presentation/support/einvoice_status_interaction_test.dart` import `package:c45_einvoice_presentation/presentation.dart` (và `c45_einvoice_domain`), không import tệp app. Vì vậy 4 tệp app đã chép ở Task 2 chưa có test nào. Đổi import sang `package:erp/features/einvoice/presentation/...` và `data/models.dart`, như `order_einvoice_row_test.dart` đang làm. Chạy lại: 27 ca phải đạt.
- [ ] **R1-3 (nặng) 2 ca đỏ trong `order_einvoice_section_test.dart`.** Cả hai do dữ liệu test, code `lib/` không sai.
  - `save pdf keeps documents sheet open and disables xml`: constructor `_TestMediator` (`:96-110`) chép mọi trường của `FakeEInvoiceRepository.forScenario(...)` trừ `documentResults`. Vì vậy `getDocuments` trả rỗng và không bao giờ tải. Cần chép thêm `documentResults` (và cả `previewResults` / `detailResults` để các ca khác không gặp lại lỗi này).
  - `deliveryPending locks send on post-issue sheet`: cubit hỏi lại (đúng H1) và đọc projection của fake `sendSheetInitial` (`deliveryPending: false`), nên ghi đè trạng thái `pendingProjection` mà test đã `emit`. Bản cũ dùng `FakeEInvoiceModule`, trả projection khác. Sửa bằng cách cho fake trả `pendingProjection`: dùng `onMediatorCreated: (m) => m.projection = pendingProjection`. Giữ nguyên các `expect`.
- [ ] **R1-4 (vừa) Task 0 chưa làm; Review Focus 1, 2, 4 chưa có test đúng ý.** Code cũ đã thay xong nên không chạy được "bước 0 trên code cũ" nữa. Viết 3 ca trên code mới trong `test/features/einvoice/presentation/order_einvoice_polling_host_test.dart`, dùng `FakeEInvoiceRepository.holdOn['getProjection']` thay cho `gate`. Điều kiện kiểm giữ đúng mục 7 Task 0:
  - **B0-1** `refresh while poll in flight reuses the read`;
  - **B0-2** `closing cubit stops polling`;
  - **B0-3** `retry from failed never flashes back to failed`. `retry` của fake đổi `projection` sang `processing`. Ca này là Review Focus 1, mục duy nhất kiểm H6 sau khi bỏ `setQueryData`.

  Thêm vào đó, ca `slow poll does not overlap` hiện tại (`order_einvoice_cubit_test.dart:1543`) chỉ gọi `refresh()` hai lần, tức là trùng ý với B0-1. Đổi nó theo plan: `pollInterval: 10ms`, `holdOn['getProjection']`, `setPollingActive(true)`, chờ 35ms → 1 lượt `getProjection`; `complete`, chờ 15ms → 2 lượt. Đây là ca kiểm `Timer` không chồng lượt (Review Focus 4).
- [ ] **R1-5 (nhỏ) Lệch Q2: 4 service đặt ở `data/` và được re-export từ `data/models.dart`.** Đặt ở `data/` là đúng: `sales_result_documents_section.dart` / `sales_transaction_result_body.dart` dùng `IInvoiceViewerLauncher` / `IInvoiceDocumentExporter`, nên nếu để ở `logic/` thì sales vi phạm R3. Plan sót chỗ này. Riêng `models.dart:6-9` re-export `file_invoice_document_exporter.dart` / `url_invoice_viewer_launcher.dart` thì kéo phần cài đặt thiết bị vào mọi tệp import model (kể cả repository) và gây import vòng (info `unnecessary_import` ở `file_invoice_document_exporter.dart:9`).
  - Bỏ 4 dòng export trong `models.dart`; tệp nào dùng thì import thẳng `data/i_invoice_*.dart` / `data/*_exporter.dart`.
  - Ghi lệch này vào mục 9 Task 2.
- [ ] **R1-6 (vừa) Test còn dựa vào module, 7-C xoá module là gãy.** `test/features/einvoice/support/fake_einvoice_repository.dart:11`, `presentation/order_einvoice_section_test.dart:7`, `presentation/order_einvoice_mount_test.dart:7`, `sales/presentation_module/widgets/sales_transaction_result_body_test.dart:10` import `c45_einvoice_application/testing.dart` chỉ để lấy `enum FakeEInvoiceScenario`. Sửa: chép `enum` (chỉ các giá trị `forScenario` dùng) sang `test/features/einvoice/support/fake_einvoice_scenario.dart`, rồi đổi import. Kiểm: `git grep -n "c45_einvoice" -- apps/erp/test/features/einvoice/presentation apps/erp/test/features/einvoice/support apps/erp/test/features/sales` → rỗng.
- [ ] **R1-7 Task 5 và mục 9.**
  - Ghi mục 9 cho Task 1–5: tệp:dòng, lệch plan (R1-5; cubit test khai báo lại các lớp `…Command` / `…Query` giả để giữ nguyên `expect`), số ca, impact.
  - Commit Task 3 và Task 4 (hiện chưa commit).
  - TH-08 KI-17 (`TH-08-hoa-don-dien-tu.md:1510`) cột cuối.
  - Chạy `flutter test` cả app, so với 55 lỗi của `TEST-BASELINE.md`.
  - Chạy `detect_changes`.
  - Kiểm tay 5.7 (iPhone + web).

Ghi chú, không bắt sửa:
- Ca N1 chỉ kiểm state ngay sau constructor. Vì không còn cache dùng chung giữa các cubit nên N1 vẫn đủ.
- Ca `poll result after close is dropped` không phát hiện được `emit` sau `close`, vì `refresh` nuốt `StateError`. Guard `isClosed` trong `_applyRefreshSnapshot` vẫn đúng.
- Ca `result section falls back when repository missing` có thể thêm `expect(find.byKey(const Key('sales_result_einvoice_section')), findsNothing)` như plan ghi.
- `apps/erp/example/lib/sales/preview/sg06_result_tab.dart` có sửa, dù plan ghi "không đụng example". Sửa này là cần, vì `presentation.dart` của sales đã bỏ export; `dart analyze` của example không có lỗi. Ghi vào mục 9.

### R2 — 2026-11-08: **ĐẠT**

Phạm vi xem: `a26db5628` (Task 3, Task 4, các việc sửa R1). Review tự đo lại mọi số.

| Hạng mục | Kết quả |
|---|---|
| R1-1 câu lỗi | ✅ `einvoice_error_messages.dart:25-29` chỉ xét `code` và `blockers`. Lỗi trong test đã đổi sang `AppException`. `einvoice_error_messages_test` có 3 ca chuyển sang, cộng ca `server message mentioning another code does not change the message` |
| R1-2 test chép từ module | ✅ 4 tệp import tệp app (`presentation/widgets/*`, `support/*`, `data/models.dart`) |
| R1-3 2 ca đỏ | ✅ xanh |
| R1-4 B0-1 … B0-3, ca `Timer` | ✅ `order_einvoice_polling_host_test.dart:370,395,413` giữ đúng điều kiện kiểm của Task 0; `retry` của fake đổi sang `processing` (`fake_einvoice_repository.dart:442-454`). `slow poll does not overlap` (`order_einvoice_cubit_test.dart:1546`) dùng `setPollingActive` + `pollInterval: 10ms`; chạy 6 lần, đạt cả 6 |
| R1-5 service ở `data/` | ✅ `models.dart` chỉ export model; lệch plan đã ghi ở mục 9 |
| R1-6 test không dựa vào module | ✅ `git grep c45_einvoice` trong `test/features/einvoice/{presentation,support}` và `test/features/sales` → rỗng |
| `dart analyze lib test` | ✅ không có error hay warning; info `unnecessary_import` của R1 đã hết |
| `check_feature_imports` | ✅ dòng `einvoice` / `sales` giống hệt trước 7-A2b (4 dòng R1 của 7-A1, các dòng R2 / R3 có sẵn của sales) |
| `flutter test test/features/einvoice test/features/sales test/core/di/injection_test.dart` | ✅ 1357 đạt, 10 bỏ qua, 0 đỏ |
| `flutter test` cả `apps/erp` (5.4) | ✅ 3008 đạt / 55 lỗi = 53 lỗi trong danh sách `TEST-BASELINE.md` + 2 lỗi ⚠️ đã ghi ở mục "Sau 5-C". So từng tên: không có lỗi nào của einvoice / sales |
| Phạm vi (thay 5.6) | ✅ `git diff --name-only e3f17a988 HEAD` → 74 tệp. Ngoài `features/{einvoice,sales}` và `docs/` chỉ có `core/di/injection.dart`, `main.dart`, `pubspec.yaml`, `injection_test.dart` (Task 4) và `example/.../sg06_result_tab.dart` (đã ghi lệch). Phiên review không chạy được `detect_changes` vì không có công cụ GitNexus |
| 5.5 tài liệu | ✅ TH-08 KI-17 (`:1510`) đã ghi 7-A2a + 7-A2b; mục 9 đã ghi |

Còn lại (không chặn ĐẠT):
- Kiểm tay 5.7 (iPhone + web): người dùng làm.
- Ghi chú: `slow poll does not overlap` chỉ chờ 8ms sau `complete` (plan ghi 15ms). Tick thứ 4 rơi vào khoảng 40ms, nên nếu máy CI chậm thì ca này có thể chập chờn. Nếu thấy đỏ ngẫu nhiên, nâng lên 15–25ms.
