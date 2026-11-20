# 7-A1 — E-invoice: lớp dữ liệu (model, lỗi, rule, evaluator, 2 repository, kích hoạt bộ xử lý)

> **For agentic workers:** REQUIRED SUB-SKILL: dùng superpowers:subagent-driven-development (khuyên dùng) hoặc superpowers:executing-plans để làm theo từng task. Các bước dùng checkbox (`- [ ]`).

> Theme 8 (mã cũ P7) · Bước (a) chuyển kiến trúc, phần dữ liệu · Gồm việc 7.2, 7.3 (phần dữ liệu), 7.5 (phần app) — PLAN.md mục Theme 8
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-08) | Làm ✅ 2026-11-08 | Review ✅ R2 ĐẠT 2026-11-08
> Trước: 7-E3 (Làm ✅ + Review R2 ✅). Sau: **7-A2** (đổi 4 trang thiết lập + 21 tệp HĐĐT của `features/sales` sang 2 repository, `Timer` thay `c45_async_query`, router + DI + fake). 7-A1 **không** đổi tệp nào đang có, chỉ thêm tệp mới.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) mục 6.1 (đường đi), 6.2 (RPC), 6.4 (mã lỗi, câu), 9.1 (kiến trúc), 9.3 (test Dart); PLAN.md "Cách chuyển MỘT feature", "Plan chuyển kiến trúc: giữ nghiệp vụ…". Mẫu: `plans/P6/6-A1-pricing-data.md`. Việc các plan trước giao lại: map `CONFIG_NOT_READY` (7-B1 Q5), link ký Storage cho tài liệu (7-E2b "Không làm"), app gọi `functions.invoke` (7-E1, 7-E3).

**Goal:** Có đủ lớp dữ liệu einvoice trong `apps/erp/lib/features/einvoice/{data,logic}` để 7-A2 đổi toàn bộ UI một lượt, không còn cần `c45_einvoice_*`.

**Architecture:** Hai repository gọi thẳng RPC schema `einvoice` qua `SupabaseRpc`, giữ đúng tham số và cách đọc kết quả của gateway / mapper cũ. Lỗi đi qua bộ phân loại giữ thứ tự `contains` của `mapEinvoiceRpcError`, rồi tới hàm câu lỗi theo TH-08 6.4. Sau mỗi RPC ghi yêu cầu, repository "đánh thức" Edge Function `einvoice-processor` mà không chờ.

**Tech Stack:** Dart / Flutter, `supabase` (`SupabaseClient`, `FunctionsClient`, `SupabaseStorageClient`), `equatable`, `uuid`, `flutter_test`.

## 1. Mục tiêu

- Model chép nguyên văn (tên lớp, field, constructor) từ `modules/einvoice/{application,domain}`: 51 kiểu, mục 4.1.
- `EInvoiceConfigurationRepository` (10 hàm, 4 trang thiết lập) và `EInvoiceRepository` (14 hàm, khu HĐĐT trên đơn) thay 24 Command / Query app đang dùng.
- `IssuanceReadinessEvaluator` sang `logic/`; rule đầu vào của 9 validator sang `logic/einvoice_rules.dart`.
- Phân loại lỗi về `AppException` (`einvoiceException`), câu lỗi theo 6.4 (`einvoiceErrorMessage`, `einvoiceDeliveryErrorMessage`).
- `EInvoiceProcessorTrigger`: gọi `functions.invoke('einvoice-processor', body: {'tenant_id': …})` không chờ, sau 8 RPC ghi yêu cầu.
- Test parity `old` (mapper module) / `new` (repository) dùng **chung hằng mong đợi**. 7-C xoá nhóm `old` cùng module.

**Không làm:** đổi cubit / page / router / DI (7-A2); `Timer` hỏi lại, KI-15 / KI-16 / KI-17 (7-A2); KI-01, KI-08, bố cục web (7-B2); `verify_provider_connection` (Q5); RPC / migration (giữ nguyên chữ ký, TH-08 9.4); xoá module (7-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Xem trước: `RequestInvoicePreviewCommandHandler` đọc `get_issuance_readiness` + evaluator rồi mới gọi `request_invoice_preview`. Quy ước Theme 2/3 là bỏ RPC đọc trước, nhưng server (`20261031006`, thân `request_invoice_preview`) chỉ kiểm kết nối + ảnh chụp đơn, **không** kiểm mẫu hoá đơn / người mua (KI-05: code khoá xem trước khi thiếu người mua) | **Người dùng chốt 2026-11-08: giữ đọc trước** (ngoại lệ có lý do). `EInvoiceRepository.requestPreview` = `get_issuance_readiness` → evaluator → chặn như handler → `request_invoice_preview` |
| Q2 | Lỗi đang có: `OrderEInvoiceErrorMessage.of` (`apps/erp/lib/features/sales/presentation/support/order_einvoice_error_message.dart:15-18`) trả `error.message`, mà `mapEinvoiceRpcError` luôn gán `message` = chuỗi thô (`PostgrestException(message: NO_PERMISSION: …, code: P0001, …)`) ⇒ người dùng thấy mã thô; cả bảng câu bên dưới không bao giờ chạy tới | **Người dùng chốt 2026-11-08: sửa ở 7-A, đổi có chủ đích, theo 6.4.** Hàm câu lỗi xét `code` + `details['blockers']` theo thứ tự bảng 6.4, **không bao giờ** trả `serverMessage`. Câu do app tự đặt ("Không đủ điều kiện xem trước") giữ bằng `overrides` ở chỗ gọi (7-A2). Hệ quả kèm theo (cũng là đổi có chủ đích): `einvoiceException` giữ `NETWORK_ERROR` cho lỗi mạng (cũ ra `SYSTEM_ERROR`) để có câu "Mất mạng" của 6.4; `ISSUANCE_NOT_READY` bóc đúng `details.blockers` (cũ `_parseIssuanceBlockers` cắt ở dấu `:` đầu tiên của `PostgrestException(message…` nên luôn ra `[]`) |
| Q3 | Gọi `einvoice-processor` sau RPC ghi yêu cầu: chờ hay không | **Người dùng chốt 2026-11-08: không chờ, nuốt lỗi.** Chỉ gọi khi RPC thành công; `unawaited`; mọi lỗi (mạng, 4xx / 5xx, CORS) chỉ ghi log mức `warning`; không ảnh hưởng kết quả trả về. `pg_cron` 30 giây là lưới đỡ (TH-08 6.1 "gọi ngay, không chờ kết quả") |
| Q4 | Một hay hai repository | **Người dùng chốt 2026-11-08: 2 repository theo nhóm màn** (`EInvoiceConfigurationRepository` 10 hàm, `EInvoiceRepository` 14 hàm), giống Theme 4. Task 7 sửa chữ TH-08 6.1 / 9.1 và dòng 7-A1 của PLAN.md cho khớp |
| Q5 | `VerifyProviderConnectionCommand` (nút "Kiểm tra lại", `provider_connection_cubit.dart:160`) | **Không chép.** KI-15 xoá nút ở 7-A2; quy ước "code sắp bỏ theo KI thì bỏ luôn ở (a)". RPC `verify_provider_connection` giữ trong DB |
| Q6 | RPC đọc trước / kiểm quyền client khác | Không có: 23 handler còn lại chỉ gọi 1 RPC (đo 2026-11-08); pipeline module không gắn kiểm quyền cho einvoice. Server kiểm `iam.has_permission` + `can_access_sales_order` |
| Q7 | Lớp lỗi con (`ConfigNotReadyException`, `ProviderNotConnectedException`, `ProviderUnavailableException`, `ProviderAuthFailedException`) mà cubit bắt bằng `on …` | Không chép. Mapper cũ không bao giờ trả các lớp con này (chỉ `EInvoiceBlockedException` chung, trừ `IssuanceNotReadyException`) ⇒ các nhánh đó không bao giờ chạy. 7-A2 đổi sang so `e.code`. **Riêng `CONFIG_NOT_READY` (7-B1 Q5):** `einvoiceException` trả `AppException('CONFIG_NOT_READY')`, nên nhánh "Chưa đủ điều kiện" của màn Tự động hoá chạy được từ 7-A2 (đổi có chủ đích, test D7) |

## 3. Hiện trạng (đo 2026-11-08)

App gọi module ở 6 cubit / widget trong `features/sales` + 5 tệp `modules/einvoice/presentation` (4 cubit, `provider_connection_view.dart:81`). 25 Command / Query, bỏ 1 (Q5) còn 24. Mọi gateway gọi `SupabaseSchemaRpcClient.callList` (schema `einvoice`) rồi lấy `rows.first`. Rỗng thì `RpcException('… returned no rows')` → `SYSTEM_ERROR`, trừ 2 ngoại lệ ghi ở bảng. Đường dẫn mapper: `modules/einvoice/infrastructure/lib/src/{data_access/einvoice_rpc_mapper.dart, data_access/electronic_invoice_rpc_mapper.dart, domain/issuance/issuance_rpc_mapper.dart, domain/delivery/delivery_rpc_mapper.dart}`.

| # | Command / Query → hàm mới | RPC | Tham số (nguồn) | Đọc kết quả (nguồn) | Làm thêm |
|---|---|---|---|---|---|
| C1 | `GetProviderConnectionScreenQuery` → `getConnectionScreen()` | `get_provider_connection_screen` | tenant, actor | `EinvoiceRpcMapper.mapConnectionScreen` | — |
| C2 | `ConnectProviderCommand` → `connect` | `connect_provider` | `EinvoiceRpcMapper.connectProviderParams` (username `trim`, password nguyên văn, `p_expected_connection_version` chỉ khi có) | `mapConnectionResult` | validator; **kích hoạt** |
| C3 | `ReconnectProviderCommand` → `reconnect` | `reconnect_provider` | `reconnectProviderParams` | `mapConnectionResult` | **kích hoạt** |
| C4 | `DisconnectProviderCommand` → `disconnect` | `disconnect_provider` | `disconnectProviderParams` (`p_confirm`) | `mapConnectionResult` | — |
| C5 | `ListProviderTemplatesQuery` → `listTemplates` | `list_provider_templates` | tenant, actor, `p_invoice_with_code` / `p_year` chỉ khi có | `mapTemplateList(rows)` — **rỗng → `[]`** | — |
| C6 | `GetIssuanceProfileQuery` → `getIssuanceProfile()` | `get_issuance_profile` | tenant, actor | `mapIssuanceProfile` | — |
| C7 | `SetDefaultIssuanceConfigurationCommand` → `setDefaultConfiguration` | `set_default_issuance_configuration` | `SupabaseIssuanceProfileGateway.setDefaultConfiguration` (2 id `trim`, `p_expected_profile_version` chỉ khi có) | `mapIssuanceProfile` | validator |
| C8 | `GetAutomationPolicyQuery` → `getAutomationPolicy()` | `get_automation_policy` | tenant, actor | `mapAutomationPolicy` | — |
| C9 | `UpdateAutomationPolicyCommand` → `updateAutomationPolicy` | `update_automation_policy` | `SupabaseAutomationPolicyGateway.updatePolicy` (2 cờ chỉ khi khác `null`) | `mapAutomationPolicy` | validator |
| C10 | `GetConfigurationReadinessQuery` → `getConfigurationReadiness` | `get_configuration_readiness` | tenant, actor, `p_purpose` = `purpose.name` chỉ khi có | `mapConfigurationReadiness` | — |
| O1 | `GetOrderInvoiceProjectionQuery` → `getProjection` | `get_order_invoice_projection` | `IssuanceRpcMapper.orderInvoiceProjectionParams` | `orderInvoiceProjectionFromRow` | — |
| O2 | `GetIssuanceReadinessQuery` → `getReadiness` | `get_issuance_readiness` | tenant, actor, order | `EinvoiceRpcMapper.issuanceReadinessInputFromRow` → **evaluator** → `IssuanceReadinessDto` | dựng DTO như `GetIssuanceReadinessQueryHandler` |
| O3 | `GetIssuanceAttemptStatusQuery` → `getAttemptStatus` | `get_issuance_attempt_status` | `getIssuanceAttemptStatusParams` | `issuanceAttemptStatusFromRow` | — |
| O4 | `RequestInvoicePreviewCommand` → `requestPreview` | `get_issuance_readiness` rồi `request_invoice_preview` | `SupabaseInvoicePreviewGateway.persistRequestAndEnqueue` (`p_expected_order_version`) | trả `InvoicePreviewResultDto(viewerRef: null, warnings: [messages của evaluation.warnings])` | validator; **đọc trước (Q1)**; **kích hoạt** |
| O5 | `GetInvoicePreviewQuery` → `getPreview` | `get_invoice_preview` | tenant, actor, order | `EinvoiceRpcMapper.invoicePreviewResultFromRow` — **rỗng → `InvoicePreviewResultDto(viewerRef: null, warnings: [])`** | — |
| O6 | `IssueInvoiceCommand` → `issue` | `issue_invoice` | `IssuanceRpcMapper.issueInvoiceParams` (`p_acknowledge_warnings` = `acknowledgeWarnings ?? false`) | `issueInvoiceResultFromRow` | validator; **kích hoạt** |
| O7 | `RetryIssuanceCommand` → `retry` | `retry_issuance` | `retryIssuanceParams` (`p_expected_order_version` = `toString()`) | `issueInvoiceResultFromRow` | validator; **kích hoạt** |
| O8 | `RequestOfficialInvoiceViewCommand` → `requestOfficialView` | `request_official_invoice_view` | `ElectronicInvoiceRpcMapper.scopedSalesOrderParams` | `officialViewFromRow` | validator; **kích hoạt** |
| O9 | `GetElectronicInvoiceDetailQuery` → `getDetail` | `get_electronic_invoice_detail` | `scopedSalesOrderParams` | `detailFromRow` | — |
| O10 | `RequestInvoiceDocumentCommand` → `requestDocument` | `request_invoice_document` | `requestDocumentParams` (`documentTypeToRpc`) | `documentRetrievalFromRow` → **link ký** (`_withSignedDownloadUrl`) | validator; **kích hoạt** |
| O11 | `GetInvoiceDocumentsQuery` → `getDocuments` | `get_invoice_documents` | `scopedSalesOrderParams` | `documentsFromRow` → **link ký + gộp trạng thái** (`_withSignedDownloadUrls`, `_withSignedItem`, `_aggregateRetrievalStatus` của `supabase_electronic_invoice_read_gateway.dart`) | — |
| O12 | `GetSendInvoiceSheetContextQuery` → `getSendSheetContext` | `get_send_invoice_sheet_context` | `DeliveryRpcMapper.sendSheetContextParams` | `sendSheetContextFromRow` | — |
| O13 | `SendElectronicInvoiceCommand` → `send` | `send_electronic_invoice` | `DeliveryRpcMapper.startManualParams` (email **nguyên văn**, không `trim`) | `sendInvoiceResultFromRow` | validator (email `trim` rồi kiểm); **kích hoạt** |
| O14 | `GetInvoiceDeliveryHistoryQuery` → `getDeliveryHistory` | `get_invoice_delivery_history` | `historyParams` | `historyFromRow` | — |

**Lỗi:** gateway dựng `SupabaseSchemaRpcClient(mapError: (error, [st]) => RpcException(error.toString()))` (`data_access_module.dart:57`), bắt `RpcException` và đưa qua `mapEinvoiceRpcError` (`infrastructure/lib/src/errors/einvoice_error_mapper.dart`). Lỗi đọc JSON của mapper (`TypeError`, `FormatException`) **lọt ra nguyên dạng** (không bắt). Validator ném `ValidationException('<câu tiếng Anh>')`.

**Link ký:** `InvoiceDocumentSignedUrlResolver` (`infrastructure/lib/src/storage/invoice_document_signed_url_resolver.dart`): bucket `einvoice-documents`, hạn 300 giây, lỗi → `null`; `expiresAt` = bây giờ + 300 giây.

## 4. Thiết kế

### 4.1 Model (`apps/erp/lib/features/einvoice/data/models/`)

Chép **nguyên văn** từ nguồn (chỉ đổi import; giữ `extends Equatable` / `props` nếu có). Mỗi tệp một nhóm:

| Tệp | Lớp (nguồn dưới `modules/einvoice/`) |
|---|---|
| `einvoice_enums.dart` | `domain/lib/src/`: `DeliveryActorType`, `DeliveryDisplayState`, `DeliveryKind`, `DeliveryRecipientSource`, `DeliveryStatus`, `DeliveryTriggerType` (`delivery/enums/`), `InvoiceDocumentStatus`, `InvoiceDocumentType` (`electronic_invoice/enums/`), `BuyerType` (`issuance/buyer_completion/`), `BuyerCompletionStatus`, `InternalFinalizationStatus`, `IssuanceAttemptStatus`, `IssuanceDisplayState`, `IssuanceReadinessLevel` (`issuance/enums/`), `SigningMethod` (`issuance_profile/`), `ProviderConnectionStatus` (`provider_connection/`), `ConfigurationReadinessLevel`, `IssuancePurpose` (`shared/`); `application/lib/src/delivery/shared/send_invoice_sheet_mode.dart`: `SendInvoiceSheetMode`; `application/lib/src/shared/order_invoice_action.dart`: `OrderInvoiceAction` |
| `configuration_models.dart` | `application/lib/src/configuration/`: `ProviderConnectionResultDto`, `AutomationPolicyDto`, `ConfigurationReadinessDto`, `IssuanceProfileDto`, `ProviderConnectionScreenDto`, `ProviderTemplateDto`, `LegalProfileSummaryDto`, `ProviderConnectionSummaryDto`, `ReadinessBlockerDto`, `ReadinessWarningDto` |
| `issuance_models.dart` | `application/lib/src/issuance/` + `shared/order_invoice_projection_dto.dart`: `IssueInvoiceResultDto`, `InvoicePreviewResultDto`, `IssuanceAttemptStatusDto`, `IssuanceReadinessDto`, `OrderInvoiceProjectionDto`; `domain/lib/src/issuance/buyer_completion/effective_buyer_invoice_data.dart`: `EffectiveBuyerInvoiceData` |
| `electronic_invoice_models.dart` | `application/lib/src/electronic_invoice/`: `OfficialInvoiceViewDto`, `InvoiceDocumentRetrievalDto`, `ElectronicInvoiceDetailDto`, `InvoiceDocumentItemDto`, `InvoiceDocumentsDto` |
| `delivery_models.dart` | `application/lib/src/delivery/`: `SendInvoiceResultDto`, `InvoiceDeliveryHistoryDto`, `InvoiceDeliveryItemDto`, `SendInvoiceSheetContextDto` |

Barrel `apps/erp/lib/features/einvoice/data/models.dart` export cả 5 tệp.

**Không chép:** mọi `*Command` / `*Query` / `*StartRequest`, `EInvoiceBlockedException` + 11 lớp `*Exception` (Q7), `ProviderConnectionCheckResultDto` (Q5), DTO chỉ bộ xử lý dùng (`*OperationContextDto`, `ProviderObservationDto`, `Reconciliation*`, `AutoDeliveryResultDto`, …), `ConfigurationReadinessEvaluator` (chỉ chép 2 lớp `ReadinessBlocker` / `ReadinessWarning` của tệp đó, mục 4.4).

### 4.2 Lỗi (`apps/erp/lib/features/einvoice/data/einvoice_errors.dart`)

```dart
abstract final class EInvoiceErrorCodes {
  // Chép 26 hằng của EInvoiceBlockedCodes (application/lib/src/shared/einvoice_blocked_codes.dart),
  // cùng tên, cùng chuỗi; thêm `static const network = 'NETWORK_ERROR';` (Q2).
}

/// Q2 / Q7. Thứ tự giữ đúng mapEinvoiceRpcError.
AppException einvoiceException(Object error);
```

Thuật toán (đi theo thứ tự, gặp nhánh nào trả nhánh đó):

1. `error is AppException` mà `error.cause is PostgrestException`: `text = error.cause.toString()` (đúng chuỗi `RpcException(error.toString())` cũ), `upper = text.toUpperCase()`:
   - `upper.contains('IDEMPOTENCY_CONFLICT')` → `IDEMPOTENCY_CONFLICT`;
   - `upper.contains('ISSUANCE_NOT_READY')` → `ISSUANCE_NOT_READY`, `details: {'blockers': <List<String>>}`. Lấy từ `(error.cause as PostgrestException).message`: phần sau `'ISSUANCE_NOT_READY:'`, `jsonDecode`, lấy `['details']['blockers']`, mỗi phần tử `toString()`; lỗi / thiếu → `[]` (Q2);
   - lần lượt 17 mã theo **đúng thứ tự danh sách** ở `einvoice_error_mapper.dart:22-40` (`NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `INVALID_STATUS`, `STATE_CHANGED`, `PROVIDER_NOT_CONNECTED`, `PROVIDER_AUTH_FAILED`, `PROVIDER_UNAVAILABLE`, `CONFIG_NOT_READY`, `BUYER_DATA_INCOMPLETE`, `BUYER_TAX_CODE_REQUIRED`, `ORDER_NOT_COMPLETED`, `ALREADY_ISSUED`, `OPERATION_IN_PROGRESS`, `RESULT_UNDETERMINED`, `DOCUMENT_UNAVAILABLE`, `DELIVERY_NOT_SUPPORTED`) → mã đó;
   - `text.toLowerCase().contains('permission denied')` → `NO_PERMISSION`;
   - còn lại → `SYSTEM_ERROR`.

   Mọi nhánh: `serverMessage: (error.cause as PostgrestException).message`, `cause: error.cause`.
2. `error is AppException` mà `code == 'NETWORK_ERROR'` → giữ nguyên (Q2).
3. `error is AppException` khác (rule ở 4.4, `SYSTEM_ERROR` repository tự ném, `CONFIG_NOT_READY` / `ISSUANCE_NOT_READY` của `requestPreview`) → giữ nguyên.
4. Còn lại (`FormatException`, `TypeError`, `StateError`…) → `AppException('SYSTEM_ERROR', cause: error)`.

Repository bọc mỗi hàm bằng `_guard`: `try { return await body(); } on Object catch (e) { throw einvoiceException(e); }`. Việc đọc `tenantId()` / `actorId()` nằm trong `_guard`.

### 4.3 Câu lỗi (`apps/erp/lib/features/einvoice/logic/einvoice_error_messages.dart`, Q2)

```dart
/// TH-08 6.4 "Khối HĐĐT trên đơn". [overrides] để chỗ gọi giữ câu riêng cho một mã.
String einvoiceErrorMessage(Object? error, {Map<String, String> overrides = const {}});

const einvoiceDeliveryFallbackMessage = 'Không thể gửi hóa đơn lúc này. Vui lòng thử lại.';

/// TH-08 6.4 "Gửi email".
String einvoiceDeliveryErrorMessage(Object? error);
```

`einvoiceErrorMessage`:
- `error` không phải `AppException`: `toString()` chứa `PlatformException` hoặc `Error while launching` → câu "Không mở được link". Còn lại → coi như `AppException.from(error)`.
- `overrides[code]`, nếu có, thắng.
- Sau đó duyệt bảng 6.4 **theo thứ tự dòng**; một dòng khớp khi `code == <mã>` **hoặc** `details['blockers']` chứa `<mã>`: `NO_PERMISSION`, `STATE_CHANGED`, `TEMPLATE_NOT_AVAILABLE`, `SIGNING_CONFIGURATION_NOT_AVAILABLE`, `UNSUPPORTED_TAX_DATA`, `BUYER_ADDRESS_REQUIRED`, `ORDER_FULLY_RETURNED`, `SOURCE_VERSION_MISMATCH`, `CONFIG_NOT_READY`, `ISSUANCE_NOT_READY`, `VALIDATION_ERROR`, `STALE_VERSION`, `DELIVERY_NOT_SUPPORTED`, `OPERATION_IN_PROGRESS`, `NOT_FOUND`, `PROVIDER_UNAVAILABLE`, `DOCUMENT_UNAVAILABLE`, `NETWORK_ERROR` (dòng "Mất mạng / timeout"). Không dòng nào khớp → câu "Khác".
- Câu chép **nguyên văn** từ TH-08 6.4 (trùng chuỗi đang có trong `order_einvoice_error_message.dart`).

`einvoiceDeliveryErrorMessage`: `NO_PERMISSION`, `DELIVERY_NOT_SUPPORTED`, `OPERATION_IN_PROGRESS`, `VALIDATION_ERROR`, `NOT_FOUND`, `NETWORK_ERROR` hoặc `PROVIDER_UNAVAILABLE` → câu bảng "Gửi email"; còn lại → `einvoiceDeliveryFallbackMessage`.

Hai hàm **không bao giờ** trả `serverMessage` hay mã thô.

### 4.4 Rule + evaluator (`apps/erp/lib/features/einvoice/logic/`)

`issuance_readiness_evaluator.dart`: chép nguyên văn `IssuanceReadinessInput` (`domain/lib/src/issuance/services/issuance_readiness_input.dart`), `IssuanceReadinessEvaluation` + `IssuanceReadinessEvaluator` (`…/issuance_readiness_evaluator.dart`), cùng `ReadinessBlocker`, `ReadinessWarning` (`domain/lib/src/shared/services/configuration_readiness_evaluator.dart:9-28`).

`einvoice_rules.dart`: hàm thuần, chép điều kiện validator, **bỏ** kiểm `tenantId` / `actorId`. Vi phạm → `AppException(EInvoiceErrorCodes.validationError, serverMessage: '<câu tiếng Anh cũ của validator>')`.

| Hàm | Validator nguồn (`application/lib/src/…`) | Điều kiện giữ |
|---|---|---|
| `checkConnect({username, password})` | `configuration/commands/connect_provider/…_validator.dart` | `username.trim()` rỗng; `password` rỗng (không trim) |
| `checkSetDefaultConfiguration({templateId, signingConfigId})` | `set_default_issuance_configuration/…` | 2 id rỗng sau trim |
| `checkUpdateAutomationPolicy({expectedPolicyVersion, autoIssueEnabled, autoSendEnabled})` | `update_automation_policy/…` | version < 0; cả hai cờ `null` |
| `checkSalesOrderId(String salesOrderId)` | `request_invoice_preview`, `request_official_invoice_view`, `request_invoice_document` | rỗng sau trim |
| `checkIssue({salesOrderId, sourceVersion, idempotencyKey})` | `issuance/commands/issue_invoice/…` | order; `sourceVersion.trim()` rỗng; khoá không phải UUID (`Uuid.isValidUUID(fromString:)`) |
| `checkRetry({salesOrderId, expectedOrderVersion, idempotencyKey})` | `retry_issuance/…` | order; version ≤ 0; khoá |
| `checkSend({salesOrderId, recipientEmail, idempotencyKey})` | `delivery/commands/send_electronic_invoice/…` | order; email: `trim()` rồi rỗng hoặc không khớp `^[^\s@]+@[^\s@]+\.[^\s@]+$` (`DeliveryRecipientEmailMustBeValidRule`), câu `'Delivery recipient email must be a valid address'`; khoá |

### 4.5 Kích hoạt (`apps/erp/lib/features/einvoice/data/einvoice_processor_trigger.dart`, Q3)

```dart
class EInvoiceProcessorTrigger {
  EInvoiceProcessorTrigger(FunctionsClient functions);
  /// Không chờ, không ném. Lỗi → Logger('EInvoiceProcessorTrigger').warning(...) (không ghi body / tenant).
  void kick(String tenantId);
}
```

Thân: `unawaited(_functions.invoke('einvoice-processor', body: {'tenant_id': tenantId}).then((_) {}, onError: (Object e, StackTrace st) => _log.warning('einvoice-processor kick failed', e, st)))`, bọc thêm `try/catch` đồng bộ (invoke ném ngay khi dựng request).

### 4.6 Link ký (`apps/erp/lib/features/einvoice/data/invoice_document_signed_urls.dart`)

Chép `InvoiceDocumentSignedUrlResolver` thành `InvoiceDocumentSignedUrls({required SupabaseStorageClient storage, int ttlSeconds = 300, String bucket = 'einvoice-documents'})`, với `Future<String?> tryCreate(String ref)` (mọi lỗi → `null` + `warning`) và `DateTime leaseExpiresAt({DateTime? now})`. Logger: `package:logging`.

### 4.7 Hai repository

```dart
class EInvoiceConfigurationRepository {
  EInvoiceConfigurationRepository({
    required SupabaseRpc rpc, required EInvoiceProcessorTrigger trigger,
    required Future<String> Function() tenantId, required Future<String> Function() actorId,
  });
  Future<ProviderConnectionScreenDto> getConnectionScreen();
  Future<ProviderConnectionResultDto> connect({required String username, required String password, int? expectedConnectionVersion});
  Future<ProviderConnectionResultDto> reconnect({required String connectionId, required String username, required String password, int? expectedConnectionVersion});
  Future<ProviderConnectionResultDto> disconnect({required String connectionId, required bool confirm});
  Future<List<ProviderTemplateDto>> listTemplates({bool? invoiceWithCode, int? year});
  Future<IssuanceProfileDto> getIssuanceProfile();
  Future<IssuanceProfileDto> setDefaultConfiguration({required String templateId, required String signingConfigId, int? expectedProfileVersion});
  Future<AutomationPolicyDto> getAutomationPolicy();
  Future<AutomationPolicyDto> updateAutomationPolicy({required int expectedPolicyVersion, bool? autoIssueEnabled, bool? autoSendEnabled});
  Future<ConfigurationReadinessDto> getConfigurationReadiness({IssuancePurpose? purpose});
}

class EInvoiceRepository {
  EInvoiceRepository({
    required SupabaseRpc rpc, required EInvoiceProcessorTrigger trigger, required InvoiceDocumentSignedUrls signedUrls,
    required Future<String> Function() tenantId, required Future<String> Function() actorId,
  });
  Future<OrderInvoiceProjectionDto> getProjection(String salesOrderId);
  Future<IssuanceReadinessDto> getReadiness(String salesOrderId);
  Future<IssuanceAttemptStatusDto> getAttemptStatus(String salesOrderId);
  Future<InvoicePreviewResultDto> requestPreview({required String salesOrderId, required int expectedOrderVersion});
  Future<InvoicePreviewResultDto> getPreview(String salesOrderId);
  Future<IssueInvoiceResultDto> issue({required String salesOrderId, required String sourceVersion, required String idempotencyKey, bool? acknowledgeWarnings});
  Future<IssueInvoiceResultDto> retry({required String salesOrderId, required int expectedOrderVersion, required String idempotencyKey, bool? acknowledgeWarnings});
  Future<OfficialInvoiceViewDto> requestOfficialView(String salesOrderId);
  Future<ElectronicInvoiceDetailDto> getDetail(String salesOrderId);
  Future<InvoiceDocumentRetrievalDto> requestDocument({required String salesOrderId, required InvoiceDocumentType documentType});
  Future<InvoiceDocumentsDto> getDocuments(String salesOrderId);
  Future<SendInvoiceSheetContextDto> getSendSheetContext(String salesOrderId);
  Future<SendInvoiceResultDto> send({required String salesOrderId, required String recipientEmail, required String idempotencyKey});
  Future<InvoiceDeliveryHistoryDto> getDeliveryHistory(String salesOrderId);
}
```

Mỗi hàm: `_guard(() async { rule (4.4) → _rpc.rows('einvoice', '<rpc>', params: …) → rỗng ⇒ throw const AppException(EInvoiceErrorCodes.systemError) (trừ C5, O5) → hàm đọc JSON (4.8) → [kích hoạt] })`. Tham số **giống hệt** cột "Tham số" ở mục 3. Không dùng `SupabaseRpc.firstRow`, vì nó ném `NOT_FOUND` còn cũ ra `SYSTEM_ERROR`.

- **Kích hoạt:** C2, C3, O4, O6, O7, O8, O10, O13 gọi `_trigger.kick(tenantId)` **sau** khi đọc kết quả xong, ngay trước `return`. RPC lỗi hoặc đọc JSON lỗi ⇒ không gọi.
- **`requestPreview` (Q1):** `checkSalesOrderId` → `get_issuance_readiness` → `IssuanceReadinessEvaluator.evaluate(input)`. Nếu `!evaluation.canPreview`: có blocker `code == 'CONFIG_NOT_READY'` ⇒ `throw const AppException('CONFIG_NOT_READY')`; không có ⇒ `throw AppException('ISSUANCE_NOT_READY', serverMessage: 'Không đủ điều kiện xem trước', details: {'blockers': [mã các blocker]})`. Ngược lại gọi `request_invoice_preview` (rỗng ⇒ `SYSTEM_ERROR`) → kích hoạt → trả `InvoicePreviewResultDto(viewerRef: null, warnings: [for (final w in evaluation.warnings) w.message])`.
- **`getReadiness`:** dựng `IssuanceReadinessDto` đúng như `GetIssuanceReadinessQueryHandler.handle` (`level`, `blockers` → `ReadinessBlockerDto`, `warnings` → `ReadinessWarningDto`, `buyerCompletionState`).
- **`requestDocument` / `getDocuments`:** chép `_withSignedDownloadUrl` (command gateway `:203-231`), `_withSignedDownloadUrls`, `_withSignedItem`, `_aggregateRetrievalStatus` (read gateway) thành hàm private của `EInvoiceRepository`, gọi qua `_signedUrls`.

### 4.8 Hàm đọc JSON (`apps/erp/lib/features/einvoice/data/mappers/`)

Chép các hàm `static` **đọc kết quả** ở mục 3 (cùng hàm private chúng gọi: `connectionStatusFromWire`, `mapDocumentStatus`, `mapDocumentType`, `deliveryItemsFromRpc`, `delivery*FromRpc`, `recipientSourceFromRpc`, …), giữ tên, bỏ hàm dựng tham số và hàm chỉ bộ xử lý dùng:

| Tệp | Lớp mới ← nguồn |
|---|---|
| `configuration_json.dart` | `EInvoiceConfigurationJson` ← `EinvoiceRpcMapper`: `mapConnectionResult`, `mapConnectionScreen`, `mapTemplateList`, `mapIssuanceProfile`, `mapAutomationPolicy`, `mapConfigurationReadiness`, `connectionStatusFromWire` |
| `issuance_json.dart` | `EInvoiceIssuanceJson` ← `EinvoiceRpcMapper.issuanceReadinessInputFromRow`, `.invoicePreviewResultFromRow`; `IssuanceRpcMapper.issueInvoiceResultFromRow`, `.orderInvoiceProjectionFromRow`, `.issuanceAttemptStatusFromRow` |
| `electronic_invoice_json.dart` | `EInvoiceDocumentJson` ← `ElectronicInvoiceRpcMapper`: `officialViewFromRow`, `documentRetrievalFromRow`, `detailFromRow`, `documentsFromRow`, `mapDocumentStatus`, `mapDocumentType`, `documentTypeToRpc` |
| `delivery_json.dart` | `EInvoiceDeliveryJson` ← `DeliveryRpcMapper`: `sendInvoiceResultFromRow`, `sendSheetContextFromRow`, `historyFromRow`, `deliveryItemsFromRpc` + 6 hàm `*FromRpc` |

Nếu `issuanceReadinessInputFromRow` gọi `buyerCompletionContextFromRow` hay hàm khác thì chép kèm. Thấy hàm nào kéo theo kiểu không có ở 4.1 ⇒ ghi vào Kết quả, không tự thêm kiểu.

## 5. Đang làm gì — test giữ hành vi

7-A1 không xoá / thay code đang chạy (UI đổi ở 7-A2, module xoá ở 7-C). Bảng dưới liệt kê việc của handler / gateway / mapper cũ mà repository phải giữ. Nhóm `old` chạy trên module, nhóm `new` trên tệp mới, **cùng giá trị mong đợi**.

| # | Cũ đang làm gì | Sau 7-A1 nằm ở đâu | Test |
|---|---|---|---|
| D1 | Tham số RPC của 24 hàm (mục 3), gồm `trim` username / 2 id cấu hình, khoá tuỳ chọn chỉ có khi khác `null`, `p_expected_order_version` dạng chuỗi ở `retry`, `acknowledgeWarnings ?? false`, email gửi nguyên văn | repository | parity `params_<rpc>` × 24 (Task 0, 5, 6) |
| D2 | Đọc JSON kết quả | `data/mappers/*_json.dart` | parity `parse_<kiểu>` (Task 0, 1) |
| D3 | 9 validator chặn trước RPC | `einvoice_rules.dart`, repository gọi trước RPC | `einvoice_rules_test.dart` (Task 3) + `rule_blocks_before_rpc` (0 lần gọi RPC) (Task 5, 6) |
| D4 | RPC trả 0 dòng → `SYSTEM_ERROR`; riêng `list_provider_templates` → `[]`, `get_invoice_preview` → DTO rỗng | repository | `empty_rows_is_system_error`, `templates_empty_list`, `preview_empty_dto` |
| D5 | Xem trước: đọc readiness + evaluator; thiếu mẫu → `CONFIG_NOT_READY`; chặn khác → `ISSUANCE_NOT_READY` câu "Không đủ điều kiện xem trước"; được thì `request_invoice_preview` và trả `warnings` của evaluator (Q1) | `EInvoiceRepository.requestPreview` | `preview_config_not_ready_blocks_rpc`, `preview_buyer_blocks_rpc`, `preview_ok_returns_warnings` (Task 6) |
| D6 | `getReadiness` = RPC + evaluator → `IssuanceReadinessDto` | `EInvoiceRepository.getReadiness` | parity `readiness_dto` (old: `GetIssuanceReadinessQueryHandler` với gateway giả; new: repository; cùng JSON) |
| D7 | `mapEinvoiceRpcError`: thứ tự `contains`, `permission denied`, còn lại `SYSTEM_ERROR` | `einvoiceException` | `einvoice_errors_test.dart` cùng bảng cho old / new (Task 2). **Đổi có chủ đích:** `CONFIG_NOT_READY` không còn là lớp chung bị cubit bỏ qua (Q7, 7-B1 Q5); `blockers` bóc đúng; lỗi mạng → `NETWORK_ERROR` (Q2) — 3 dòng này chỉ chạy `new`, kèm ghi chú |
| D8 | Lỗi đọc JSON lọt ra nguyên dạng | **Đổi:** `_guard` → `SYSTEM_ERROR` (như Theme 4) | `malformed_json_is_system_error` |
| D9 | Câu lỗi: trả chuỗi thô (lỗi Q2) | **Đổi có chủ đích:** `einvoiceErrorMessage` / `einvoiceDeliveryErrorMessage` theo 6.4 | `einvoice_error_messages_test.dart` (Task 4) |
| D10 | Tài liệu: link ký 300 giây; tạo link lỗi → `checkRequired`; gộp trạng thái PDF / XML | `EInvoiceRepository` + `InvoiceDocumentSignedUrls` | `document_signed_url_ok`, `document_signed_url_fail_check_required`, `documents_aggregate_status` (Task 6) |
| D11 | (mới, Q3) Không có gì đánh thức bộ xử lý | `EInvoiceProcessorTrigger` | `kick_after_write_rpcs` (8 hàm, mỗi hàm đúng 1 lần, body `{'tenant_id': …}`), `no_kick_on_reads` (16 hàm còn lại 0 lần), `no_kick_when_rpc_fails`, `kick_failure_does_not_throw` (Task 4b, 5, 6) |
| D12 | `tenantId` / `actorId` đọc mỗi lần gọi qua execution context | closure `tenantId()` / `actorId()` | `tenant_read_each_call` |

## 6. Các bước

> Thực hiện: `superpowers:executing-plans` hoặc `superpowers:subagent-driven-development`. Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`).
> 7-A1 chỉ thêm tệp mới ⇒ không sửa symbol có sẵn. Lỡ phải sửa tệp có sẵn ngoài danh sách thì chạy `gitnexus impact` trước và ghi vào Kết quả.

**Global Constraints** (mọi task):
- Chỉ tạo tệp trong `apps/erp/lib/features/einvoice/data/`, `apps/erp/lib/features/einvoice/logic/` và `apps/erp/test/features/einvoice/{data,logic}/`. Không sửa `modules/`, `core/`, DI, router, cubit. Riêng Task 7 sửa tài liệu.
- Model / hàm đọc JSON / evaluator: chép nguyên văn, chỉ đổi import. Phải sửa thân mới chạy được ⇒ ghi Kết quả, không đổi hành vi.
- Tệp `lib` mới không import `c45_*`. Test parity được import module, có `// ignore_for_file: implementation_imports`.
- Không có `tenantId` / `actorId` trong chữ ký hàm repository.
- Câu tiếng Việt chép nguyên văn TH-08 6.4.

**Review Focus** (chưa task nào test được trọn, phiên review soi):
1. Chuỗi `PostgrestException.toString()` của gói `supabase` đang dùng phải giống lúc module chạy (nhánh 1 của 4.2 dựa vào đó). Test Task 2 dựng `PostgrestException` thật, nên mọi đổi định dạng sẽ lộ ra ở đó; review kiểm thêm `details` có chứa chữ mã khác không (vd `hint`).
2. `issuanceAttemptStatusFromRow(rows.first)` nhận `Map` không ép kiểu: bản chép nhận `Map<String, dynamic>` từ `SupabaseRpc.rows`, kiểm không đổi nghĩa.
3. `requestPreview` chạy evaluator trên dữ liệu đọc **trước** RPC: giữ đúng như cũ, không tự thêm đọc lại.
4. Ngày giờ trong DTO (`expiresAt`, `requestedAt`…): mapper cũ `DateTime.parse` không `toLocal()` ⇒ bản chép giữ y nguyên.
5. `kick` dùng `tenantId` đã đọc trong `_guard` của lần gọi đó, không đọc lại.

### Task 0: Nhóm `old` của test parity (trên module)

**Files:**
- Create: `apps/erp/test/features/einvoice/data/einvoice_parity_expectations.dart` (hằng dùng chung)
- Create: `apps/erp/test/features/einvoice/data/einvoice_rpc_parity_test.dart` (nhóm `old`; `new` thêm ở Task 1, 5, 6)

- [x] **0.1** Hằng tham số mỗi RPC với đầu vào cố định: `tenant = '11111111-1111-4111-8111-111111111111'`, `actor = '22222222-2222-4222-8222-222222222222'`, `order = '33333333-3333-4333-8333-333333333333'`, `key = '44444444-4444-4444-8444-444444444444'`. Đầu vào có khoảng trắng: `username: '  misa-user  '` → `'misa-user'`; `password: ' p '` → `' p '`; `templateId: ' 1C26TAA '`; email `' a@b.vn '` gửi nguyên `' a@b.vn '`. Mỗi lệnh có trường tuỳ chọn có **2 ca**: có và `null` (vd `expectedConnectionVersion: 3` → có `p_expected_connection_version: 3`; `null` → không có khoá). Ví dụ:
  ```dart
  const expectedRetryParams = {
    'p_tenant_id': tenant, 'p_actor_id': actor, 'p_sales_order_id': order,
    'p_expected_order_version': '7', 'p_idempotency_key': key, 'p_acknowledge_warnings': false,
  };
  ```
- [x] **0.2** Hằng JSON mẫu cho mỗi hàm đọc kết quả ở 4.8, lấy từ test có sẵn của module (`modules/einvoice/infrastructure/test/data_access/einvoice_rpc_mapper_test.dart`, `…/domain/issuance/supabase_issuance_gateways_test.dart`, `supabase_order_invoice_projection_read_gateway_test.dart`, `supabase_issuance_reconciliation_gateway_test.dart`, `…/domain/delivery/supabase_delivery_*_gateway_test.dart`, `…/electronic_invoice/supabase_electronic_invoice_gateways_test.dart`). Readiness: 3 bộ (sẵn sàng; thiếu mẫu; khách tổ chức thiếu MST / địa chỉ). Hàm so field `expectX(dynamic dto, …)` viết trong tệp expectations, nhận `dynamic` để dùng cho cả kiểu cũ lẫn mới.
- [x] **0.3** Nhóm `old`: gọi hàm dựng tham số cũ (`EinvoiceRpcMapper.connectProviderParams(ConnectProviderCommand(...))`, `IssuanceRpcMapper.retryIssuanceParams(RetryIssuanceStartRequest(...))`, `DeliveryRpcMapper.startManualParams(...)`, …) → `equals(expected…)`. Với gateway dựng map tại chỗ (C1, C5–C10, O2, O4, O5): dựng gateway với `SupabaseSchemaRpcClient` trên client giả ghi tham số; không dựng được thì so bằng đọc nguồn và ghi ⏭ + lý do. Hàm đọc JSON cũ → `expectX`. `readiness_dto`: `GetIssuanceReadinessQueryHandler(readinessGateway: <giả trả input từ JSON>)`.
- [x] **0.4** Chạy `cd apps/erp && flutter test test/features/einvoice/data/einvoice_rpc_parity_test.dart` → PASS. Ghi tên test vào Kết quả.

### Task 1: Model + hàm đọc JSON

**Files:**
- Create: `apps/erp/lib/features/einvoice/data/models/{einvoice_enums,configuration_models,issuance_models,electronic_invoice_models,delivery_models}.dart`, `apps/erp/lib/features/einvoice/data/models.dart`
- Create: `apps/erp/lib/features/einvoice/data/mappers/{configuration_json,issuance_json,electronic_invoice_json,delivery_json}.dart`

**Interfaces:**
- Consumes: `IssuanceReadinessInput` (Task 3). Task 1 tạo trước tệp `logic/issuance_readiness_evaluator.dart` chỉ chứa `IssuanceReadinessInput`; Task 3 thêm phần còn lại vào cùng tệp.
- Produces: các lớp ở 4.1; `EInvoiceConfigurationJson`, `EInvoiceIssuanceJson`, `EInvoiceDocumentJson`, `EInvoiceDeliveryJson` với tên hàm `static` như 4.8.

- [x] **1.1** Chép model theo 4.1 và `IssuanceReadinessInput`. `cd apps/erp && dart analyze lib/features/einvoice` → 0 lỗi.
- [x] **1.2** Chép hàm đọc JSON theo 4.8.
- [x] **1.3** Thêm nhóm `new (json)` vào parity: cùng JSON mẫu, cùng `expectX`. Chạy lệnh 0.4 → PASS.

### Task 2: Phân loại lỗi

**Files:**
- Create: `apps/erp/lib/features/einvoice/data/einvoice_errors.dart`
- Test: `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart`

**Interfaces:** Produces `EInvoiceErrorCodes` (26 + `network`), `AppException einvoiceException(Object error)`.

- [x] **2.1** Viết test. Đầu vào là `PostgrestException(message: m, code: 'P0001')`, bọc qua `AppException.from` cho `new`, qua `RpcException(e.toString())` → `mapEinvoiceRpcError` cho `old`. Bảng `m` → mã (cả hai nhóm):
  - `'NO_PERMISSION: einvoice.issue required'` → `NO_PERMISSION`;
  - `'IDEMPOTENCY_CONFLICT: payload differs for key k'` → `IDEMPOTENCY_CONFLICT`;
  - `'INVALID_STATUS: ALREADY_ISSUED'` → `INVALID_STATUS` (thứ tự danh sách: `INVALID_STATUS` đứng trước `ALREADY_ISSUED`);
  - `'STATE_CHANGED: connection version mismatch'` → `STATE_CHANGED`;
  - `'TEMPLATE_NOT_AVAILABLE: x'` → `SYSTEM_ERROR` (không có trong 17 mã);
  - `'permission denied for function issue_invoice'` (code `42501`) → `NO_PERMISSION`;
  - `'boom'` → `SYSTEM_ERROR`;
  - `'ISSUANCE_NOT_READY: provider not connected'` → `ISSUANCE_NOT_READY`.
  
  Chỉ `new` (đổi có chủ đích, ghi chú `// Q2` / `// Q7`):
  - `'ISSUANCE_NOT_READY: {"details":{"blockers":["ORDER_FULLY_RETURNED"]}}'` → `details['blockers'] == ['ORDER_FULLY_RETURNED']`;
  - `'CONFIG_NOT_READY: auto issue requires readiness'` → `code == 'CONFIG_NOT_READY'`;
  - `AppException('NETWORK_ERROR')` → giữ `NETWORK_ERROR`;
  - `FormatException('x')`, `StateError('x')` → `SYSTEM_ERROR`;
  - `AppException('VALIDATION_ERROR', serverMessage: 'username is required')` → giữ nguyên;
  - mọi ca có Postgrest: `serverMessage == m`.
- [x] **2.2** Chạy → FAIL (chưa có hàm). Viết `einvoice_errors.dart` theo 4.2. Chạy `flutter test test/features/einvoice/data/einvoice_errors_test.dart` → PASS.

### Task 3: Evaluator + rule đầu vào

**Files:**
- Modify (tệp mới của Task 1): `apps/erp/lib/features/einvoice/logic/issuance_readiness_evaluator.dart`
- Create: `apps/erp/lib/features/einvoice/logic/einvoice_rules.dart`
- Test: `apps/erp/test/features/einvoice/logic/issuance_readiness_evaluator_test.dart`, `apps/erp/test/features/einvoice/logic/einvoice_rules_test.dart`

**Interfaces:** Consumes `EInvoiceErrorCodes` (Task 2), enum (Task 1). Produces `IssuanceReadinessEvaluator.evaluate(IssuanceReadinessInput) → IssuanceReadinessEvaluation` (có `canPreview`, `level`, `blockers`, `warnings`, `buyerCompletionState`), `ReadinessBlocker`, `ReadinessWarning`, 7 hàm ở bảng 4.4.

- [x] **3.1** Chép `modules/einvoice/domain/test/issuance/issuance_readiness_evaluator_test.dart` (470 dòng), chỉ đổi import sang `package:erp/features/einvoice/...`. Chạy → FAIL.
- [x] **3.2** Chép evaluator theo 4.4. Chạy → PASS (đủ số ca như bản module; ghi số ca).
- [x] **3.3** `einvoice_rules_test.dart`: mỗi hàm 1 ca hợp lệ và 1 ca cho **mỗi** điều kiện → `throwsA(isA<AppException>().having((e) => e.code, 'code', 'VALIDATION_ERROR').having((e) => e.serverMessage, 'msg', '<câu cũ>'))`. Ca biên: `password: ' '` → hợp lệ (không trim); `expectedPolicyVersion: 0` → hợp lệ, `-1` → `'expectedPolicyVersion must be non-negative'`; cả hai cờ `null` → `'At least one of autoIssueEnabled or autoSendEnabled must be set'`; `expectedOrderVersion: 0` → `'expectedOrderVersion must be positive'`; khoá `'abc'` → `'idempotencyKey must be a canonical UUID'`; email `' a@b.vn '` → hợp lệ, `'a@b'` → `'Delivery recipient email must be a valid address'`. Chạy → FAIL; viết `einvoice_rules.dart`; chạy → PASS.

### Task 4: Câu lỗi + kích hoạt + link ký

**Files:**
- Create: `apps/erp/lib/features/einvoice/logic/einvoice_error_messages.dart`, `apps/erp/lib/features/einvoice/data/einvoice_processor_trigger.dart`, `apps/erp/lib/features/einvoice/data/invoice_document_signed_urls.dart`
- Test: `apps/erp/test/features/einvoice/logic/einvoice_error_messages_test.dart`, `apps/erp/test/features/einvoice/data/einvoice_processor_trigger_test.dart`

**Interfaces:** Produces `einvoiceErrorMessage`, `einvoiceDeliveryErrorMessage`, `einvoiceDeliveryFallbackMessage` (4.3); `EInvoiceProcessorTrigger.kick` (4.5); `InvoiceDocumentSignedUrls.tryCreate`, `.leaseExpiresAt` (4.6).

- [x] **4.1** `einvoice_error_messages_test.dart`:
  - mỗi dòng 6.4 "Khối HĐĐT" → đúng câu: theo `code` (vd `AppException('NO_PERMISSION')`) và theo blocker (`AppException('ISSUANCE_NOT_READY', details: {'blockers': ['ORDER_FULLY_RETURNED']})` → "Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.");
  - thứ tự: blockers `['BUYER_ADDRESS_REQUIRED', 'ORDER_FULLY_RETURNED']` → câu `BUYER_ADDRESS_REQUIRED` (dòng trên thắng);
  - `ISSUANCE_NOT_READY` không blocker → câu `ISSUANCE_NOT_READY`;
  - `AppException('ISSUANCE_NOT_READY', serverMessage: 'Không đủ điều kiện xem trước')` không override → câu bảng (không trả serverMessage);
  - `overrides: {'ISSUANCE_NOT_READY': 'Không đủ điều kiện xem trước'}` → câu override;
  - `AppException('NETWORK_ERROR')`, `TimeoutException('x')` → "Không kết nối được dịch vụ hóa đơn điện tử. Vui lòng thử lại.";
  - `PlatformException(code: 'x')` → câu "Không mở được link";
  - `AppException('X_CODE', serverMessage: 'raw')`, `null` → "Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.";
  - `einvoiceDeliveryErrorMessage`: 6 dòng bảng "Gửi email" + `PROVIDER_UNAVAILABLE` → câu mạng + mã lạ → `einvoiceDeliveryFallbackMessage`.
- [x] **4.2** `einvoice_processor_trigger_test.dart` với `_FakeFunctions implements FunctionsClient` (ghi `(functionName, body)`, `noSuchMethod` ném):
  - `kick_invokes_processor_with_tenant`: `kick(tenant)` → 1 lần `('einvoice-processor', {'tenant_id': tenant})`;
  - `kick_failure_does_not_throw`: fake trả `Future.error(FunctionException(status: 500))` → `kick` không ném, `await pumpEventQueue()` không có lỗi chưa bắt;
  - `kick_sync_throw_does_not_throw`: fake ném đồng bộ → `kick` không ném.
- [x] **4.3** Chạy 2 test → FAIL. Viết 3 tệp theo 4.3–4.6. Chạy → PASS.

### Task 5: `EInvoiceConfigurationRepository`

**Files:**
- Create: `apps/erp/lib/features/einvoice/data/einvoice_configuration_repository.dart`
- Test: `apps/erp/test/features/einvoice/data/einvoice_configuration_repository_test.dart` + nhóm `new (configuration)` trong parity
- [x] **5.1** Parity `new`: `_RecordingRpc implements SupabaseRpc` (mẫu `apps/erp/test/features/sales/data/sales_draft_rpc_parity_test.dart:176-191`, thêm `rows` gọi `call` rồi chuẩn hoá như `SupabaseRpc.rows`) + `_RecordingTrigger extends EInvoiceProcessorTrigger` (ghi `kick`). 10 hàm × các ca 0.1 → `schema == 'einvoice'`, `fn` đúng, `params` bằng hằng 0.1; kết quả qua `expectX`.
- [x] **5.2** Test riêng:
  - `kick_after_write_rpcs`: `connect`, `reconnect` → `kicks == [tenant]`;
  - `no_kick_on_reads`: 8 hàm còn lại → `kicks` rỗng;
  - `no_kick_when_rpc_fails`: `connect` với RPC ném `PostgrestException(message: 'STATE_CHANGED: connection version mismatch')` → `AppException.code == 'STATE_CHANGED'`, `kicks` rỗng;
  - `update_policy_config_not_ready` (D7): RPC ném `'CONFIG_NOT_READY: …'` → `code == 'CONFIG_NOT_READY'`;
  - `rule_blocks_before_rpc`: `connect(username: ' ', password: 'x')` → `VALIDATION_ERROR`, `calls` rỗng; `updateAutomationPolicy(expectedPolicyVersion: 1)` → `VALIDATION_ERROR`, `calls` rỗng;
  - `empty_rows_is_system_error`: `getIssuanceProfile` với `result = []` → `SYSTEM_ERROR`;
  - `templates_empty_list`: `listTemplates` với `[]` → `isEmpty`;
  - `malformed_json_is_system_error`: `getAutomationPolicy` với `[{'policy_version': 'x'}]` → `SYSTEM_ERROR`;
  - `tenant_read_each_call`: closure đếm = số lần gọi.
- [x] **5.3** Chạy → FAIL. Viết repository. Chạy `flutter test test/features/einvoice/data/` → PASS.

### Task 6: `EInvoiceRepository`

**Files:**
- Create: `apps/erp/lib/features/einvoice/data/einvoice_repository.dart`
- Test: `apps/erp/test/features/einvoice/data/einvoice_repository_test.dart` + nhóm `new (order)` trong parity

**Interfaces:** Consumes Task 1–4 (`IssuanceReadinessEvaluator`, `InvoiceDocumentSignedUrls`, `EInvoiceProcessorTrigger`). Produces chữ ký `EInvoiceRepository` ở 4.7.

- [x] **6.1** Parity `new`: 14 hàm, params bằng hằng 0.1 (O4 kiểm cả 2 lần gọi: `get_issuance_readiness` rồi `request_invoice_preview`); `readiness_dto` bằng `GetIssuanceReadinessQueryHandler` của nhóm `old`. `_FakeSignedUrls extends InvoiceDocumentSignedUrls` trả URL cố định hoặc `null`.
- [x] **6.2** Test riêng:
  - `kick_after_write_rpcs`: `requestPreview` (input sẵn sàng), `issue`, `retry`, `requestOfficialView`, `requestDocument`, `send` → mỗi hàm `kicks == [tenant]`;
  - `no_kick_on_reads`: 8 hàm đọc → `kicks` rỗng;
  - `preview_config_not_ready_blocks_rpc` (D5): readiness thiếu mẫu → `code == 'CONFIG_NOT_READY'`, chỉ 1 lần gọi (`get_issuance_readiness`), `kicks` rỗng;
  - `preview_buyer_blocks_rpc`: khách tổ chức thiếu MST → `code == 'ISSUANCE_NOT_READY'`, `serverMessage == 'Không đủ điều kiện xem trước'`, `details['blockers']` chứa `'BUYER_TAX_CODE_REQUIRED'`, 1 lần gọi;
  - `preview_ok_returns_warnings`: sẵn sàng có cảnh báo → 2 lần gọi, `viewerRef == null`, `warnings` = message của cảnh báo evaluator;
  - `preview_empty_dto` (D4): `getPreview` với `[]` → `viewerRef == null`, `warnings` rỗng;
  - `issue_ack_default_false`: `issue(acknowledgeWarnings: null)` → `params['p_acknowledge_warnings'] == false`;
  - `send_email_untrimmed`: `send(recipientEmail: ' a@b.vn ')` → `params['p_recipient_email'] == ' a@b.vn '`;
  - `document_signed_url_ok` (D10): `requestDocument` row `status: AVAILABLE, file_ref: 'r'` + fake URL `'u'` → `downloadUrl == 'u'`, `status == available`;
  - `document_signed_url_fail_check_required`: fake trả `null` → `status == checkRequired`, `downloadUrl == null`;
  - `documents_aggregate_status`: PDF `AVAILABLE` (URL lỗi) + XML `PENDING` → `pdf.status == checkRequired`, `retrievalStatus == checkRequired`; PDF `AVAILABLE` (URL ok) + XML `PENDING` → `retrievalStatus == pending`; PDF có `expiresAt` = `leaseExpiresAt()` của fake;
  - `no_kick_when_rpc_fails`: `issue` với RPC ném `'ISSUANCE_NOT_READY: {"details":{"blockers":["BUYER_TAX_CODE_REQUIRED"]}}'` → `details['blockers'] == ['BUYER_TAX_CODE_REQUIRED']`, `kicks` rỗng;
  - `empty_rows_is_system_error`: `getProjection` với `[]` → `SYSTEM_ERROR`;
  - `rule_blocks_before_rpc`: `issue(idempotencyKey: 'abc', …)` và `send(recipientEmail: 'a@b', …)` → `VALIDATION_ERROR`, `calls` rỗng.
- [x] **6.3** Chạy → FAIL. Viết repository. Chạy `flutter test test/features/einvoice/` → PASS.

### Task 7: Kiểm toàn bộ + tài liệu + Kết quả

**Files:**
- Modify: `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` mục 6.1 (sơ đồ "Sau refactor": `EInvoiceRepository` → "`EInvoiceConfigurationRepository` / `EInvoiceRepository`"), mục 9.1 dòng đầu (`data/einvoice_repository.dart` → thêm `data/einvoice_configuration_repository.dart`)
- Modify: `docs/refactor/PLAN.md` dòng 7-A1 (Nội dung: "2 repository (Q4)…", cột Làm), việc 7.2 ("`EInvoiceRepository` (kết nối, mẫu…)" → "`EInvoiceConfigurationRepository`")

- [x] **7.1** `cd apps/erp && dart analyze lib/features/einvoice test/features/einvoice` → 0 lỗi, 0 cảnh báo mới.
- [x] **7.2** `dart run tool/check_feature_imports.dart` → không dòng mới của `einvoice`.
- [x] **7.3** `git grep -n "c45_" -- apps/erp/lib/features/einvoice/data apps/erp/lib/features/einvoice/logic` → rỗng.
- [x] **7.4** `flutter test test/features/einvoice/` → PASS (ghi số ca); `flutter test` cả app → số lỗi đúng bằng `docs/refactor/TEST-BASELINE.md` (so từng tên).
- [x] **7.5** Sửa TH-08 / PLAN.md như mục Files.
- [x] **7.6** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})`: chỉ tệp mới + 2 tệp tài liệu; ghi số tệp / symbol / luồng / rủi ro vào Kết quả.

## 7. Kiểm tra

Tự động: Task 7. Không có kiểm tay, vì 7-A1 không đổi màn nào. Kiểm tay toàn Theme 8, gồm thử `functions.invoke` trên Chrome (7-E1 N6, preflight `OPTIONS` khi `verify_jwt` bật), ở 7-A2.

## 8. Rủi ro / lưu ý

- **Câu lỗi đổi (Q2):** từ 7-A2 người dùng thấy câu 6.4 thay vì chuỗi thô. Mã server chưa có trong 17 mã (`TEMPLATE_NOT_AVAILABLE`, `SIGNING_CONFIGURATION_NOT_AVAILABLE`, `STATE_INVALID`…) vẫn `SYSTEM_ERROR` như cũ ⇒ câu "Khác". Màn thiết lập bắt lỗi lưu bằng `catch (_)` nên không đổi gì.
- **`kick` trên web:** chưa kiểm preflight thật (7-E1 N6). Lỗi chỉ ghi log (Q3), việc vẫn chạy nhờ `pg_cron` ≤ 30 giây.
- **`AUTHENTICATION_REQUIRED`** (JWT hết hạn) có cause Postgrest ⇒ nhánh 1 ⇒ `SYSTEM_ERROR` như cũ.
- **Thiếu phiên:** `tenantId()` / `actorId()` ném `AUTHENTICATION_REQUIRED` không có cause Postgrest ⇒ nhánh 3, giữ nguyên mã. Không tới được trong app vì `StoreShell` chặn.
- Chép mapper dài (~1.700 dòng nguồn, chỉ phần đọc) dễ sót: parity D1 / D2 là lưới chặn; review so `diff` mapper cũ với tệp mới.

## 9. Kết quả (phiên làm code ghi)

- **Task 0 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/test/features/einvoice/data/einvoice_parity_expectations.dart` (660 dòng): chứa hằng tham số cố định, JSON mẫu RPC cho 24 command/query, các hàm `expectX(dynamic dto, ...)`.
    - `apps/erp/test/features/einvoice/data/einvoice_rpc_parity_test.dart` (nhóm `old`): kiểm tra mapper và gateway cũ của `modules/einvoice`.
  - Kết quả test: 32 passed, 10 skipped (10 ca gateway inline không dựng được standalone vì phụ thuộc DI sâu, so bằng mã nguồn và để parity cho `new`).

- **Task 1 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/lib/features/einvoice/data/models/einvoice_enums.dart` (149 dòng): 20 enum/lớp domain/status HĐĐT. Tổng model: 45 model + 6 kiểu evaluator = 51 kiểu, khớp plan.
    - `apps/erp/lib/features/einvoice/data/models/configuration_models.dart` (137 dòng).
    - `apps/erp/lib/features/einvoice/data/models/issuance_models.dart` (136 dòng).
    - `apps/erp/lib/features/einvoice/data/models/electronic_invoice_models.dart` (106 dòng).
    - `apps/erp/lib/features/einvoice/data/models/delivery_models.dart` (73 dòng).
    - `apps/erp/lib/features/einvoice/data/models.dart` (5 dòng): barrel export.
    - `apps/erp/lib/features/einvoice/data/mappers/configuration_json.dart` (134 dòng).
    - `apps/erp/lib/features/einvoice/data/mappers/issuance_json.dart` (206 dòng).
    - `apps/erp/lib/features/einvoice/data/mappers/electronic_invoice_json.dart` (155 dòng).
    - `apps/erp/lib/features/einvoice/data/mappers/delivery_json.dart` (176 dòng).
    - `apps/erp/lib/features/einvoice/logic/issuance_readiness_evaluator.dart` (chứa `IssuanceReadinessInput`, `IssuanceReadinessLineItemInput`).
  - Đã thêm nhóm `new (json)` vào `einvoice_rpc_parity_test.dart`.
  - Lệch so với plan:
    - `RpcException` → `FormatException` ở 4 tệp mapper (`configuration_json`, `issuance_json`, `electronic_invoice_json`, `delivery_json`) để loại bỏ hoàn toàn phụ thuộc vào `c45_shared` (kết quả vẫn bọc thành `SYSTEM_ERROR` qua `einvoiceException`).
    - Nhánh `PostgrestException e => e` trong `einvoiceException` để giữ nguyên nếu đầu vào đã là `PostgrestException`.
  - Kết quả test: 49 passed, 10 skipped.

- **Task 2 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/lib/features/einvoice/data/einvoice_errors.dart` (147 dòng): `EInvoiceErrorCodes` (27 mã) và hàm `einvoiceException(Object error)`.
    - `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart` (106 dòng): 13 ca kiểm tra phân loại lỗi Postgrest, AppException, StateError, FormatException, trích xuất `details['blockers']` và `CONFIG_NOT_READY`.
  - Kết quả test: 13/13 passed.

- **Task 3 — ✅ Hoàn thành**
  - Tệp đã thêm/sửa:
    - `apps/erp/lib/features/einvoice/logic/issuance_readiness_evaluator.dart` (216 dòng): triển khai hoàn chỉnh `IssuanceReadinessEvaluator`, `ReadinessBlocker`, `ReadinessWarning`, `IssuanceReadinessEvaluation`.
    - `apps/erp/test/features/einvoice/logic/issuance_readiness_evaluator_test.dart` (471 dòng): chép nguyên văn 16 ca test từ `modules/einvoice/domain/test/issuance/issuance_readiness_evaluator_test.dart`.
    - `apps/erp/lib/features/einvoice/logic/einvoice_rules.dart` (134 dòng): 7 hàm kiểm tra tính hợp lệ trước RPC theo bảng 4.4.
    - `apps/erp/test/features/einvoice/logic/einvoice_rules_test.dart` (248 dòng): 21 ca test kiểm tra validation error, trim, canonical UUID, email hợp lệ.
  - Kết quả test: 16/16 evaluator tests passed, 21/21 rules tests passed.

- **Task 4 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/lib/features/einvoice/logic/einvoice_error_messages.dart` (125 dòng): `einvoiceErrorMessage`, `einvoiceDeliveryErrorMessage`, `einvoiceDeliveryFallbackMessage` chuẩn theo TH-08 mục 6.4.
    - `apps/erp/lib/features/einvoice/data/einvoice_processor_trigger.dart` (28 dòng): `EInvoiceProcessorTrigger` gửi invoke bất đồng bộ mà không ném lỗi nếu thất bại.
    - `apps/erp/lib/features/einvoice/data/invoice_document_signed_urls.dart` (40 dòng): `InvoiceDocumentSignedUrls` gọi `storage.from(...).createSignedUrl`.
    - `apps/erp/test/features/einvoice/logic/einvoice_error_messages_test.dart` (227 dòng): 8 test suites kiểm tra từng trường hợp mã lỗi, blocker ưu tiên, override, mạng, platform exception.
    - `apps/erp/test/features/einvoice/data/einvoice_processor_trigger_test.dart` (56 dòng): 3 tests kiểm tra kích hoạt trigger, nuốt lỗi sync/async.
    - `apps/erp/test/features/einvoice/data/invoice_document_signed_urls_test.dart` (71 dòng): 3 tests kiểm tra tạo URL, lỗi trả null, tính `leaseExpiresAt`.
  - Kết quả test: 8 passed (error messages), 3 passed (trigger), 3 passed (signed urls).

- **Task 5 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/lib/features/einvoice/data/einvoice_configuration_repository.dart` (295 dòng): 10 phương thức kết nối, đồng bộ mẫu, profile phát hành, chính sách tự động, sẵn sàng cấu hình.
    - `apps/erp/test/features/einvoice/data/einvoice_configuration_repository_test.dart` (221 dòng): 9 tests kiểm tra kick sau write, no kick on read, no kick khi lỗi, rule validation, empty/malformed error.
  - Thêm nhóm `new (configuration)` vào `einvoice_rpc_parity_test.dart` (10 phương thức).
  - Kết quả test: 9/9 configuration repository tests passed; parity test tăng lên 60 passed, 10 skipped.

- **Task 6 — ✅ Hoàn thành**
  - Tệp đã thêm:
    - `apps/erp/lib/features/einvoice/data/einvoice_repository.dart` (573 dòng): 14 phương thức thao tác hoá đơn theo đơn hàng.
    - `apps/erp/test/features/einvoice/data/einvoice_repository_test.dart` (389 dòng): 14 tests kiểm tra kick sau write, no kick on read, blocker preview, warning, default flags, email untrimmed, signed url fallback, aggregate retrieval status.
  - Thêm nhóm `new (order)` vào `einvoice_rpc_parity_test.dart` (14 phương thức).
  - Kết quả test: 14/14 einvoice repository tests passed; parity test đạt 74 passed, 10 skipped.

- **Task 7 — ✅ Hoàn thành**
  - **7.1** `cd apps/erp && dart analyze lib/features/einvoice test/features/einvoice` → 0 errors, 0 warnings.
  - **7.2** `dart run tool/check_feature_imports.dart` → Hợp lệ (chỉ có 4 dòng R1 nội bộ einvoice `data/` import `logic/rules` và `logic/evaluator` theo đúng thiết kế, 0 dòng R2/R3 vi phạm).
  - **7.3** `git grep -n "c45_" -- apps/erp/lib/features/einvoice/data apps/erp/lib/features/einvoice/logic` → Rỗng (exit code 1).
  - **7.4** `flutter test test/features/einvoice/` → PASS (168 passed, 10 skipped).
    - `flutter test` toàn bộ `apps/erp` → 2.902 passed, 10 skipped, 55 failed. Đối chiếu `docs/refactor/TEST-BASELINE.md`: đúng chính xác 55 lỗi có sẵn (53 lỗi baseline + 2 lỗi UI PCC ngoài mốc), không phát sinh bất kỳ lỗi mới nào.
  - **7.5** Đã cập nhật tài liệu:
    - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`: cập nhật mục 6.1 (sơ đồ kiến trúc mới gồm `EInvoiceConfigurationRepository` và `EInvoiceRepository`), mục 9.1.
    - `docs/refactor/PLAN.md`: cập nhật bảng Theme 8 (hàng 7-A1, cột Làm `✅ 2026-11-08`) và chi tiết việc 7.2.
  - **7.6** GitNexus:
    - `node .gitnexus/run.cjs analyze` → 48,896 nodes | 107,259 edges | 1311 clusters | 300 flows.
    - `node .gitnexus/run.cjs detect_changes -r erp-sales-inventory -s all` → 4 files modified đã theo dõi (`AGENTS.md`, `CLAUDE.md`, `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/PLAN.md`), 9 symbols changed, 0 affected processes, Risk level: low. Lệnh `detect_changes` chỉ thấy các tệp đã theo dõi git; ngoài ra có 28 tệp mới chưa theo dõi (18 tệp trong `apps/erp/lib/features/einvoice/{data,logic}/`, 10 tệp trong `apps/erp/test/features/einvoice/{data,logic}/`) và 1 tệp plan.

### R1 — sửa (2026-11-08)

- **R1-1:** Đã sửa điều kiện chặn trong `einvoice_repository.dart:148` thành `if (!evaluation.canPreview)` để khớp hoàn toàn với `request_invoice_preview_command_handler.dart:34`. Khách tổ chức chỉ thiếu MST (`canPreview == true`) vẫn tiếp tục gọi `request_invoice_preview`. Thêm `sampleReadinessOrgMissingAddressJson()` vào `einvoice_parity_expectations.dart`; chuyển `preview_buyer_blocks_rpc` sang dùng fixture thiếu địa chỉ (`BUYER_ADDRESS_REQUIRED`); thêm ca `preview_tax_code_only_still_requests_preview` (2 lần gọi, `kicks == [tenant]`).
- **R1-2:** Đã bỏ dòng gọi thừa `EInvoiceRules.checkConnect` trong `EInvoiceConfigurationRepository.reconnect`. Thêm ca `reconnect_has_no_rule` (`reconnect(connectionId: 'c', username: ' ', password: '')` → gọi RPC với `p_username == ''`).
- **R1-3:** Đã khôi phục `.toUtc()` và `try/catch on FormatException` trong `_requiredDateTime` / `_optionalDateTime` của `delivery_json.dart`. Bỏ `.toUpperCase()` trong `_attemptStatusFromRpc` của `issuance_json.dart`. Thêm 2 ca vào parity `new (json)`: `delivery_timestamp_is_utc` và `attempt_status_lowercase_rejected`.
- **R1-4:** Chuẩn hóa `einvoice_error_messages.dart`: chỉ kiểm tra `PlatformException` / `Error while launching` khi `error is! AppException`; bỏ so chuỗi thô `permission` và `order_version_mismatch`; bỏ `DEPENDENCY_UNAVAILABLE`. Thêm ca test kiểm tra chuỗi thô trong `AppException` không gây match sai: `AppException('SYSTEM_ERROR', serverMessage: 'missing permission scope')` và `AppException('X_CODE', serverMessage: 'PlatformException')` đều trả về câu thông báo mặc định.
- **R1-5:** Đổi relative import `../../../../core/errors/app_exception.dart` thành package import `package:erp/core/errors/app_exception.dart` trong `data/einvoice_errors.dart` và `logic/einvoice_rules.dart`.
- **R1-6:** Cập nhật số liệu và các điểm lệch plan trong mục 9. Chạy lại kiểm tra:
  - `dart analyze lib/features/einvoice test/features/einvoice`: 0 errors, 0 warnings.
  - `flutter test test/features/einvoice/`: 173 passed, 10 skipped (tăng 5 ca so với trước R1).
  - `dart run tool/check_feature_imports.dart`: 4 dòng R1 nội bộ einvoice, 0 dòng R2/R3.

## 10. Review

<!-- Phiên review ghi; phiên code không tự chấm ĐẠT / xoá task R<n>. -->

### R1 — 2026-11-08 — **CHƯA ĐẠT** (6 việc sửa nhỏ; 2 repository, tham số RPC, kích hoạt, phân loại lỗi đúng)

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `dart analyze lib/features/einvoice test/features/einvoice` | ✅ | chạy lại: No issues found |
| `flutter test test/features/einvoice/` | ✅ 168 + 10 bỏ qua | chạy lại, khớp Kết quả. 10 ca `old` bỏ qua có lý do; review đối chiếu nguồn 5 gateway dựng map tại chỗ (`supabase_{provider_connection_read,issuance_profile,automation_policy,configuration_readiness_read,issuance_readiness_read}_gateway.dart`): khớp hằng 0.1 |
| Tham số 24 RPC (D1) | ✅ | parity `new` + đọc tay: `trim` username / 2 id, khoá tuỳ chọn `?x`, `retry` gửi `toString()`, `acknowledgeWarnings ?? false`, email nguyên văn |
| Rỗng → `SYSTEM_ERROR`, trừ C5 / O5 (D4) | ✅ | 22 chỗ ném, `listTemplates` không kiểm rỗng, `getPreview` trả DTO rỗng |
| Kích hoạt (D11, Q3) | ✅ | đúng 8 hàm, `kick` sau khi đọc JSON xong, dùng `tenant` của lần gọi; `requestDocument` kick sau khi ký link. Trigger `unawaited` + `try/catch` đồng bộ |
| `einvoiceException` (D7) | ✅ | thứ tự `contains` khớp `einvoice_error_mapper.dart:10-58`; blockers bóc sau `ISSUANCE_NOT_READY:` khớp định dạng `raise exception 'ISSUANCE_NOT_READY: %', jsonb_build_object('details', …)` (`20261031008:330`). Thêm nhánh `PostgrestException e => e` (không có trong plan, vô hại) |
| Link ký + gộp trạng thái (D10) | ✅ | so từng hàm với 2 gateway cũ: chỉ đổi tên resolver |
| Evaluator | ✅ | thân `IssuanceReadinessEvaluator` giống hệt bản module; 16 ca chép |
| `requestPreview` (D5, Q1) | ❌ | điều kiện chặn khác handler — R1-1 |
| Rule (D3) | ⚠️ | 7 hàm khớp validator cũ; nhưng `reconnect` gọi thêm `checkConnect` — R1-2 |
| Hàm đọc JSON (D2) | ⚠️ | so từng hàm cũ / mới: `RpcException` → `FormatException` (bắt buộc, kết quả vẫn `SYSTEM_ERROR`); nhưng 2 chỗ đổi thân — R1-3 |
| Câu lỗi (D9, Q2) | ⚠️ | 18 câu khớp nguyên văn TH-08 6.4; nhưng còn so chuỗi thô ngoài bảng — R1-4 |
| Import | ⚠️ | R1-5 |
| `check_feature_imports` | ✅ | 4 dòng R1 `data/` → `logic/` (rule, evaluator) cùng mẫu `sales`, `pricing`, `catalog`; không R2 / R3 |
| `git grep c45_` trong `lib/features/einvoice/{data,logic}` | ✅ | rỗng |
| TH-08 6.1 / 9.1, PLAN.md 7-A1 / 7.2 | ✅ | |
| Số liệu Kết quả | ⚠️ | R1-6 |

#### R1 — việc cần sửa

- [ ] **R1-1 — `requestPreview` chặn rộng hơn handler (người dùng chốt 2026-11-08: về như cũ).** `einvoice_repository.dart:148` dùng `!evaluation.canPreview || evaluation.blockers.isNotEmpty`; handler cũ (`request_invoice_preview_command_handler.dart:34`) chỉ `!evaluation.canPreview`. Evaluator không đặt `previewForbidden` cho `BUYER_TAX_CODE_REQUIRED` (`issuance_readiness_evaluator.dart:162-168`), nên khách tổ chức chỉ thiếu MST thì code cũ vẫn gọi `request_invoice_preview`, còn code mới ném `ISSUANCE_NOT_READY`. UI đã làm mờ nút này (AC-02), nên người dùng không gặp, nhưng (a) phải giữ nghiệp vụ. Lỗi gốc ở plan: ca `preview_buyer_blocks_rpc` (6.2) lấy nhầm ca thiếu MST.
  - Sửa điều kiện thành `if (!evaluation.canPreview)`.
  - `einvoice_parity_expectations.dart`: thêm `sampleReadinessOrgMissingAddressJson()`. Chép từ `sampleReadinessOrgMissingTaxJson()`, đổi `buyer_tax_code: '0101234567'`, `buyer_address: null`. Đây cũng là bộ readiness thứ 3 mà Task 0.2 yêu cầu nhưng còn thiếu.
  - `preview_buyer_blocks_rpc`: đổi sang fixture thiếu địa chỉ; `blockers` chứa `'BUYER_ADDRESS_REQUIRED'`; 1 lần gọi.
  - Thêm ca `preview_tax_code_only_still_requests_preview`: fixture thiếu MST → 2 lần gọi (`get_issuance_readiness`, `request_invoice_preview`), `kicks == [tenant]`.
- [ ] **R1-2 — `reconnect` có rule mà code cũ không có.** `einvoice_configuration_repository.dart:91` gọi `EInvoiceRules.checkConnect`. Module không có `reconnect_provider_command_validator.dart`, và bảng mục 3 dòng C3 không ghi validator. Bỏ dòng đó. Thêm ca `reconnect_has_no_rule`: `reconnect(connectionId: 'c', username: ' ', password: '')` → 1 lần gọi RPC, `params['p_username'] == ''`.
- [ ] **R1-3 — Hai hàm đọc JSON bị đổi thân** (ràng buộc chung: chép nguyên văn).
  - `mappers/delivery_json.dart:164-175`: `_requiredDateTime` / `_optionalDateTime` bỏ mất `.toUtc()` và `try/catch`. Chép lại như `delivery_rpc_mapper.dart:473-483`: `try { return DateTime.parse(…).toUtc(); } on FormatException { throw FormatException('RPC row has malformed timestamp: $key'); }`. Không làm thế thì chuỗi không có múi giờ ra giờ địa phương, `isUtc` khác bản cũ.
  - `mappers/issuance_json.dart:131`: `switch (raw.toUpperCase())` → `switch (raw)` (bản cũ `issuance_rpc_mapper.dart:229` không đổi hoa, trạng thái chữ thường phải ném).
  - Thêm 2 ca vào nhóm `new (json)` của parity: `delivery_timestamp_is_utc` (`'2026-11-08T10:00:00'` → `isUtc == true`) và `attempt_status_lowercase_rejected` (`'pending'` → `throwsFormatException`).
- [ ] **R1-4 — Câu lỗi còn so chuỗi thô ngoài 6.4** (4.3: chỉ xét `code` + `details['blockers']`). `einvoice_error_messages.dart`:
  - bỏ `|| raw.contains('permission')` (`:30`): `AppException('SYSTEM_ERROR', serverMessage: '… permission …')` đang ra câu "không có quyền";
  - bỏ `|| raw.contains('order_version_mismatch')` (`:33`);
  - bỏ `matches('DEPENDENCY_UNAVAILABLE')` (`:82`) và `code == 'DEPENDENCY_UNAVAILABLE'` (`:118`);
  - chỉ xét `PlatformException` / `Error while launching` khi `error is! AppException` (`:8`);
  - giữ `TimeoutException` / `SocketException`, vì `AppException.from` đã ra `NETWORK_ERROR`.
  
  Thêm ca: `AppException('SYSTEM_ERROR', serverMessage: 'missing permission scope')` → câu "Khác"; `AppException('X_CODE', serverMessage: 'PlatformException')` → câu "Khác".
- [ ] **R1-5 — Import tương đối vượt quá `lib/`.** `data/einvoice_errors.dart:5` và `logic/einvoice_rules.dart:3` dùng `'../../../../core/errors/app_exception.dart'`. Từ `lib/features/einvoice/{data,logic}/`, 4 lần `..` lên tới `apps/erp/`, không phải `lib/`. Import này chạy được chỉ vì URI `package:` bị chặn ở gốc gói. Đổi thành `package:erp/core/errors/app_exception.dart` cho giống 2 repository.
- [ ] **R1-6 — Kết quả.**
  - (a) Task 1 ghi "13 enum", thực tế `einvoice_enums.dart` có **20** (đếm `^(class|enum)`); tổng model 45 + 6 kiểu evaluator = 51, khớp plan.
  - (b) Ghi vào "Lệch plan" những thay đổi chưa ghi: `RpcException` → `FormatException` ở 4 tệp mapper (liệt kê hàm); nhánh `PostgrestException e => e` trong `einvoiceException`.
  - (c) 7.6: `detect_changes` chỉ thấy tệp đã theo dõi, nên "4 files" chưa gồm **28 tệp mới** (18 `lib`, 10 `test`) + plan. Ghi rõ điều này.
  - (d) Sau R1-1 … R1-5, chạy lại `flutter test test/features/einvoice/` và `dart analyze`, ghi số ca mới.

**Không chặn (ghi nhận):** `requestPreview` không đọc `preview_request_id` (cũ ép `as String`, thiếu cột thì ném `TypeError`). Bản mới mềm hơn mà không đổi kết quả trả về, chấp nhận. Kết quả ghi số dòng ít hơn `wc -l` 1 ở vài tệp, không bắt sửa.

R2 = lượt review sau khi phiên code làm xong R1-1 … R1-6 và ghi vào mục 9 (thêm "**R1 — sửa**"; không tự tích `[x]` ở mục 10).

### R2 — 2026-11-08 — **ĐẠT**

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `dart analyze lib/features/einvoice test/features/einvoice` | ✅ | chạy lại: No issues found |
| `flutter test test/features/einvoice/` | ✅ 173 + 10 bỏ qua | chạy lại; +5 ca so với R1, khớp "R1 — sửa" |
| `git grep c45_` trong `lib/features/einvoice/{data,logic}` | ✅ | rỗng |
| R1-1 `requestPreview` | ✅ | `einvoice_repository.dart:148` `if (!evaluation.canPreview)` khớp handler; fixture `sampleReadinessOrgMissingAddressJson` (MST có, địa chỉ `null`); `preview_buyer_blocks_rpc` → `BUYER_ADDRESS_REQUIRED`; `preview_tax_code_only_still_requests_preview` 2 lần gọi + kick |
| R1-2 `reconnect` | ✅ | hết `checkConnect`; `reconnect_has_no_rule` gửi `p_username == ''` |
| R1-3 mapper | ✅ | `delivery_json.dart` `_requiredDateTime` / `_optionalDateTime` có lại `.toUtc()` + `try/catch`; `issuance_json.dart:131` `switch (raw)`; 2 ca parity `delivery_timestamp_is_utc`, `attempt_status_lowercase_rejected` |
| R1-4 câu lỗi | ✅ | chỉ xét `code` + `blockers`; `PlatformException` chỉ khi `error is! AppException`; hết `permission` / `order_version_mismatch` / `DEPENDENCY_UNAVAILABLE`; 2 ca mới ra câu "Khác" |
| R1-5 import | ✅ | `package:erp/core/errors/app_exception.dart` ở 2 tệp |
| R1-6 Kết quả | ✅ | 20 enum, 51 kiểu; lệch plan (`FormatException`, nhánh `PostgrestException`) đã ghi; 7.6 ghi rõ 28 tệp mới chưa theo dõi |

Còn lại (người dùng): `git add` các tệp mới rồi `node .gitnexus/run.cjs detect-changes` trước commit. Không có bước DB. Tiếp theo: plan 7-A2.
