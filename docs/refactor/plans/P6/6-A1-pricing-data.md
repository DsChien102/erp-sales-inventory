# 6-A1 — Pricing: lớp dữ liệu (model, lỗi, rule, 2 repository)

> Theme 4 (mã cũ P6) · Bước (a) chuyển kiến trúc, phần dữ liệu · Gồm việc 6.1 (PLAN.md mục Theme 4; 6.2 nhập Excel **bỏ**, Q9)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-04, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ 2026-11-04 | Review ✅ R2 2026-11-04 (đã sửa R1-1, R1-2 của R1)
> Sau 6-A1 là **6-A2** (đổi toàn bộ UI pricing + sales + router + DI + fake sang repository, xoá màn nhập Excel và màn "Chọn cách thêm"). 6-A1 **không** đổi tệp nào đang có, chỉ thêm tệp mới.
> Tài liệu: [TH-04](../../../02-yeu-cau/TH-04-chinh-sach-gia.md) mục 6.2 (RPC), 6.4 (mã lỗi), 9.1 (kiến trúc); PLAN.md "Cách chuyển MỘT feature", "Plan chuyển kiến trúc: giữ nghiệp vụ…". Mẫu Theme 2: `5-A1-catalog-data-san-pham.md`, `5-A2-catalog-data-don-vi-truong-gia.md`.

## 1. Mục tiêu

- Có đủ lớp dữ liệu để 6-A2 đổi UI một lượt. Gồm model chép từ `modules/pricing/application` (giữ tên lớp và tên field để UI không phải sửa), phân loại lỗi về `AppException`, câu lỗi theo TH-04 6.4, rule đầu vào thành hàm thuần, và 2 repository:
  - `CustomerPriceRuleRepository` (6.1): tìm, chi tiết, lịch sử, tạo, sửa, tắt, kiểm trước bật lại, bật lại, tra giá riêng đang áp.
  - `SalesPricingRepository`: xem trước giá cả phiếu bán và kiểm giá nhập tay, cho `sales_pricing_lookup.dart` / `sales_draft_backend.dart` dùng ở 6-A2 (Q2).
- **Không** làm `PriceImportRepository` và codec `.xlsx` (việc 6.2 cũ): nhập Excel bỏ hẳn (Q9).
- Có test parity `old` (mapper module) / `new` (repository) dùng **chung giá trị mong đợi**. 6-C xoá nhóm `old` cùng module.
- Việc 6.3 (màn chọn khách / sản phẩm / đơn vị) **đã xong** từ 4-A / 5-A3: `pricing_pick_*_page.dart` gọi `PartnerRepository`, `ProductRepository`, `MeasurementUnitRepository`, `ProductPriceRepository` (đo 2026-11-04). 6-A1 / 6-A2 không đụng.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chia 6-A | **Người dùng chốt 2026-11-04:** 2 plan theo lớp, giống Theme 2. 6-A1 làm dữ liệu, 6-A2 đổi UI + sales + router + DI + fake một lượt |
| Q2 | Sales gọi pricing (xem trước giá, kiểm giá nhập tay, tra giá riêng đang áp, tạo / sửa khi "Lưu làm giá riêng") | **Người dùng chốt 2026-11-04:** chuyển trong 6-A. 6-A1 làm `SalesPricingRepository` + `CustomerPriceRuleRepository.resolveApplicable`; 6-A2 đổi 2 tệp sales và bỏ `IPricingModule` khỏi DI |
| Q3 | Lỗi cũ: bật lại làm mất cờ ghi đè. `PriceRuleDetailCubit.reenable` gửi `acknowledgeOverwrite: true`, nhưng `ReenableCustomerPriceRuleCommandHandler` gọi `ICustomerPriceRuleCommandGateway.reenable(...)` không có tham số đó, và `SupabaseCustomerPriceRuleCommandGateway.reenable` (`modules/pricing/infrastructure/lib/src/domain/customer_price_rule/supabase_customer_price_rule_command_gateway.dart:136-160`) dựng lại command với mặc định `false` ⇒ server luôn nhận `p_acknowledge_overwrite = false` ⇒ bật lại khi có giá riêng `active` trùng hiệu lực luôn bị chặn `DUPLICATE_ACTIVE_RULE` (`20260805002_pricing_patch_overwrite_confirm.sql`, thân `reenable_customer_price_rule`) | **Người dùng chốt 2026-11-04: sửa luôn ở 6-A, đổi có chủ đích.** `reenable(...)` có tham số `acknowledgeOverwrite` và gửi đúng giá trị nhận được. Câu "tự động **tắt** giá riêng trùng" (thực tế là xoá) vẫn để KI-14 ở 6-B |
| Q4 | Câu lỗi thô (`PricingBlockedException.message` tiếng Anh ở sales, `e.message`, "Lỗi: `<mã>`", "Đã có lỗi: `<mã>`") | **Người dùng chốt 2026-11-04:** đổi ở 6-A theo TH-04 6.4. 6-A1 làm hàm `pricingErrorMessage`; 6-A2 thay các chỗ hiện câu thô. Mã đã có câu riêng thì giữ câu đó |
| Q5 | RPC đọc trước lệnh: `get_customer_price_rule_create_context`, `get_customer_price_rule_update_context` (handler tạo / sửa dùng để kiểm trùng, kiểm khách / sản phẩm, kiểm dưới sàn, so version) | **Bỏ** (quy ước Theme 2/3). Repository gọi đúng 1 RPC `create_…` / `update_…`. Đã đối chiếu thân RPC (bản `20260810001`): server tự trả `VALIDATION_ERROR`, `IDEMPOTENCY_CONFLICT`, `REFERENCE_INVALID`, `BELOW_FLOOR_BLOCKED` (`reason` `acknowledgementRequired` / `overridePermissionRequired`), `DUPLICATE_ACTIVE_RULE` (`details.conflictingRuleId`, `reason: overwriteRequired`), `STATE_CHANGED`. Hệ quả ghi ở bảng 5 (D4, D5) |
| Q6 | Kiểm quyền client: pipeline module (`IAccessMetadataRegistry`, `PricingQueryAccessGuard`) và `EvaluateSalesManualPriceQueryHandler` (đòi `override_floor_price` khi `requiresAcknowledgement`) | **Bỏ** (quy ước Theme 3 Q3). Server kiểm `iam.has_permission` ở mọi RPC. TH-04 7.2: mọi thành viên có `override_floor_price` ⇒ không đổi gì với người dùng |
| Q7 | Mã lỗi lạ | Giữ 10 mã ở `_stableCode`; mọi mã khác, lỗi không phải `AppException`, lỗi đọc JSON (`FormatException` của mapper) ⇒ `SYSTEM_ERROR`. **Ghi chú R1-2 (người dùng chốt 2026-11-04, đổi có chủ đích so với `mapPricingRpcError` cũ):** vì `pricingException` đi qua `AppException.from`, các `PostgrestException` không có JSON nhưng có `permission denied` / `42501` / `PERMISSION_DENIED` được đổi sang `NO_PERMISSION`, và `RESOURCE_NOT_FOUND` được đổi sang `NOT_FOUND` (cũ đều ra `SYSTEM_ERROR`; còn mất mạng `NETWORK_ERROR` và `not authenticated` `AUTHENTICATION_REQUIRED` vẫn ra `SYSTEM_ERROR`) |
| Q8 | Lệnh "nhớ giá từ đơn" (`save_remembered_price_from_order`), "xoá" (`delete_customer_price_rule`) | **Không chép** (TH-04 KI-02, 6.2 "Không dùng"). RPC giữ trong DB |
| Q9 | Nhập Excel (EP-04, PR-09) | **Người dùng chốt 2026-11-04: bỏ hẳn tính năng, ngay trong 6-A.** 6-A1 không chép 4 lệnh / query nhập, model nhập, codec `.xlsx`. 6-A2 xoá màn PR-09 và màn PR-03 "Chọn cách thêm" (nút thêm mở thẳng form). 6-C xoá 4 RPC nhập + hàm phụ + bảng lô / dòng nhập + `catalog._resolve_product_unit_for_pricing_import` (sửa migration gốc). Enum nguồn `excel_import` của giá riêng **giữ** trong model (dữ liệu cũ có thể có; 6-C kiểm DB) |

## 3. Hiện trạng (đo 2026-11-04)

App gọi module ở 9 tệp `lib` (5 cubit, `pricing_choose_method_page.dart`, `sales_pricing_lookup.dart`, `sales_draft_backend.dart`, `app_router.dart`) và 40 tệp `lib/features/pricing` import kiểu của module. 16 command / query đang dùng; 5 dòng nhập Excel (gạch ~~…~~) **không chép** (Q9), 6-A2 xoá nơi gọi:

| Command / Query | Handler làm thêm gì ngoài gọi RPC | RPC | Tham số (chép từ mapper) |
|---|---|---|---|
| `SearchCustomerPriceRulesQuery` | validator | `search_customer_price_rules` | `CustomerPriceRuleSearchRpcMapper.params` |
| `GetCustomerPriceRuleDetailQuery` | validator | `get_customer_price_rule_detail` | `CustomerPriceRuleDetailRpcMapper.params` |
| `GetCustomerPriceRuleHistoryQuery` | validator | `get_customer_price_rule_history` | `CustomerPriceRuleHistoryRpcMapper.params` |
| `CreateCustomerPriceRuleCommand` | validator; **RPC đọc trước** create context + kiểm trùng / khách / sản phẩm / dưới sàn; sinh `p_rule_id` (`Uuid().v4()`); chuẩn hoá ghi chú | `create_customer_price_rule` | `PricingRpcMapper.createParams` |
| `UpdateCustomerPriceRuleCommand` | validator; **RPC đọc trước** update context + so version + kiểm như trên (bỏ qua khi không đổi) | `update_customer_price_rule` | `PricingUpdateRpcMapper.updateParams` |
| `DisableCustomerPriceRuleCommand` | validator; `ruleId.trim()`; lý do trim, rỗng → `null` | `disable_customer_price_rule` | `PricingDisableRpcMapper.params` |
| `PrecheckCustomerPriceRuleReenableQuery` | validator | `precheck_customer_price_rule_reenable` | `PricingReenableRpcMapper.precheckParams` |
| `ReenableCustomerPriceRuleCommand` | validator; `ruleId.trim()`; **mất `acknowledgeOverwrite`** (Q3) | `reenable_customer_price_rule` | `PricingReenableRpcMapper.reenableParams` |
| `ResolveApplicableCustomerPriceRuleQuery` | validator | `resolve_applicable_customer_price_rule` | `PricingResolveApplicableRpcMapper.params` |
| ~~`GetCustomerPriceRuleImportTemplateQuery`~~ | (Q9) bỏ | — | — |
| ~~`StartCustomerPriceRuleImportCommand`~~ | (Q9) bỏ | — | — |
| ~~`GetCustomerPriceRuleImportQuery`~~ | (Q9) bỏ | — | — |
| ~~`ConfirmCustomerPriceRuleImportCommand`~~ | (Q9) bỏ | — | — |
| ~~`CancelCustomerPriceRuleImportCommand`~~ | (Q9) bỏ | — | — |
| `PreviewSalesWorkingStatePricingQuery` | validator; mapper kiểm `context_version`, `currency_code`, tập `local_line_id` khớp yêu cầu | `preview_sales_working_state_pricing` | `SalesPricingRpcMapper.previewParams` |
| `EvaluateSalesManualPriceQuery` | validator; **kiểm quyền client** khi `requiresAcknowledgement` (Q6) | `evaluate_sales_manual_price` | `SalesPricingRpcMapper.manualEvaluationParams` |

Đường dẫn mapper: `modules/pricing/infrastructure/lib/src/domain/{customer_price_rule,customer_price_rule_import,sales_pricing}/`. Validator: `modules/pricing/application/lib/src/**/*_validator.dart`. Tất cả RPC ở schema `pricing`, trả `jsonb` (gateway gọi `callMap`).

## 4. Thiết kế

### 4.1 Model (`apps/erp/lib/features/pricing/data/models/`)

Chép **nguyên văn** (tên lớp, field, constructor, getter) từ `modules/pricing/application/lib/src/`; chỉ đổi import. Bỏ `withExecutionContext`, `tenantId` của command / query (không chép command / query). Mỗi tệp một nhóm:

| Tệp | Lớp (nguồn) |
|---|---|
| `pricing_enums.dart` | `CustomerPriceRuleStatus`, `CustomerPriceRuleSourceType` (từ `modules/pricing/domain/lib/src/customer_price_rule/`; giữ `excelImport`), `CustomerPriceRuleDerivedStatus`, `CustomerPriceRuleQuickFilter`, `CustomerPriceRuleActivityType`, `CustomerPriceRuleReferenceState`, `CustomerPriceRulePriceBandState` |
| `pricing_common.dart` | `MoneyDto`, `EffectivePeriodDto`, `CursorPageDto<T>`, `RuleIssueDto`, `RuleValidationOutcomeDto`, `CustomerRefDto`, `ProductUnitRefDto`, `CustomerPriceRuleAvailableActions`, `PricingAvailableActions` |
| `customer_price_rule.dart` | `CustomerPriceRuleDetailDto`, `CustomerPriceRuleReferenceHealthDto`, `CustomerPriceRuleSourceTraceDto`, `CustomerPriceRuleListItemDto`, `CustomerPriceRuleSearchResultDto`, `CreateCustomerPriceRuleResult`, `CustomerPriceRuleReenablePrecheckDto`, `ApplicableCustomerPriceRuleDto`, `ResolveApplicableCustomerPriceRuleResultDto` |
| `customer_price_rule_activity.dart` | `CustomerPriceRuleActivityDto`, `CustomerPriceRuleActivityActorDto`, `CustomerPriceRuleActivitySourceTraceDto` |
| `sales_pricing.dart` | `SalesPricingLineInput`, `SalesPricingLinePreviewDto`, `SalesWorkingStatePricingPreviewDto`, `SalesManualPriceEvaluationDto` |

Barrel `apps/erp/lib/features/pricing/data/models.dart` export cả 5 tệp.

**Không chép:** `CustomerSnapshot`, `ProductPriceBandSnapshot`, `CustomerPriceRuleCreateContext`, `CustomerPriceRuleUpdateContext` (Q5), `RememberedPriceOutcomeDto` (Q8), `SalesWorkingStatePricingInput` (repository nhận tham số rời), `PricingBlockedException` (thay bằng `AppException`), `PricingBlockedCodes` (thay bằng `PricingErrorCodes`, mục 4.2), mọi kiểu nhập Excel (`CustomerPriceRuleImport*`, `ProductUnitResolutionStrategy`; Q9).

`MoneyDto` trùng tên với `MoneyDto` của `vet45_sales_application`. Hai tệp sales ở 6-A2 đã import sales với tiền tố `sales.` nên không đụng nhau.

### 4.2 Lỗi (`apps/erp/lib/features/pricing/data/pricing_errors.dart`)

```dart
abstract final class PricingErrorCodes {
  // Chép 12 hằng của PricingBlockedCodes (modules/pricing/application/lib/src/shared/pricing_blocked_codes.dart),
  // cùng tên, cùng chuỗi: noPermission … systemError, overwriteRequired.
}

/// Q7: giữ cách của mapPricingRpcError. AppException có mã trong 10 mã ổn định
/// (_stableCode) → giữ nguyên code, serverMessage, details; còn lại → SYSTEM_ERROR (cause = error gốc).
AppException pricingException(Object error);
```

Repository bọc mỗi lần gọi bằng `_guard`: `try { return await body(); } on Object catch (e) { throw pricingException(e); }`. Lỗi đọc JSON của mapper (`FormatException`, `TypeError`) cũng thành `SYSTEM_ERROR`, như gateway cũ (`on Object`). Lỗi rule (mục 4.3) ném `AppException(VALIDATION_ERROR)` trước khi gọi RPC và đi qua `_guard` vẫn giữ nguyên (mã nằm trong 10 mã).

### 4.3 Rule (`apps/erp/lib/features/pricing/logic/pricing_rules.dart`)

Hàm thuần, chép điều kiện từ validator tương ứng, **bỏ** mọi kiểm `tenantId` / `actorId` (lấy từ phiên). Vi phạm ⇒ `AppException(PricingErrorCodes.validationError, serverMessage: <message cũ của validator>, details: {'fieldErrors': {<field>: <mã cũ>}})`. Riêng 2 rule sales (validator cũ ném `ValidationException('<câu>')`): `AppException(PricingErrorCodes.validationError, serverMessage: '<câu cũ>')`, không có `details`.

| Hàm | Validator nguồn | Điều kiện giữ |
|---|---|---|
| `checkCreateRule({customerId, productId, productUnitId, idempotencyKey, rulePriceMinor, currencyCode, effectiveFrom, effectiveTo})` | `create_customer_price_rule_command_validator.dart` | 4 id không rỗng (`required`); giá > 0 (`must_be_positive`); `^[A-Z]{3}$` sau trim + upper (`invalid_currency`); đến < từ theo ngày lịch (`before_effective_from`) |
| `checkUpdateRule({ruleId, expectedVersion, rulePriceMinor, effectiveFrom, effectiveTo})` | `update_…_validator.dart` | `ruleId` rỗng / không phải UUID; version > 0; giá > 0; ngày |
| `checkDisableRule({ruleId, expectedVersion, reason})` | `disable_…_validator.dart` | id; version; lý do sau trim ≤ 500 (`too_long`) |
| `checkReenableRule({ruleId, expectedVersion, precheckToken})` | `reenable_…_validator.dart` | id; version; token (nếu có) khớp `^[0-9a-f]{64}$` |
| `checkPrecheckReenable({ruleId, expectedVersion})` | `precheck_…_validator.dart` | id; version |
| `checkRuleId(String ruleId)` | `get_customer_price_rule_detail_query_validator.dart` | id |
| `checkHistoryPage({ruleId, cursor, limit})` | `get_customer_price_rule_history_query_validator.dart` | id; limit 1..100; cursor ≤ 1024 ký tự |
| `checkSearch({q, customerId, productId, limit})` | `search_…_validator.dart` | limit 1..100; `q` ≤ 120; `customerId` / `productId` nếu có thì không rỗng sau trim (`blank`) |
| `checkResolve({customerId, productId, productUnitId})` | `resolve_…_validator.dart` | 3 id không rỗng + là UUID |
| `checkSalesPreview({storeId, customerId, currencyCode, effectiveAt, contextVersion, lines})` | `preview_sales_working_state_pricing_query_validator.dart` | chép đủ 11 điều kiện và câu (gồm `currencyCode != 'VND'`, `effectiveAt.isUtc`, `local_line_id` không trùng, mỗi dòng ≤ 1 cách nhập tay, `0..10000` điểm cơ bản) |
| `checkSalesManualPrice({storeId, customerId, productId, productUnitId, quantityMicros, currencyCode, contextVersion, manualUnitPriceMinor, manualDiscountMinor, manualDiscountBasisPoints})` | `evaluate_sales_manual_price_query_validator.dart` | chép đủ điều kiện và câu (gồm "đúng 1 cách nhập tay": `manualIntentCount != 1`, công thức đếm chép từ `EvaluateSalesManualPriceQuery.manualIntentCount`) |
| `String? normalizeRuleNote(String? note)` | `CustomerPriceRule._normalizeNote` | trim; rỗng → `null` |

Ngày so theo ngày lịch (chép `_isCalendarDateBefore`). Mã field (`required`, `invalid`, `must_be_positive`…) và câu `serverMessage` chép đúng chuỗi cũ.

### 4.4 Câu lỗi (`apps/erp/lib/features/pricing/logic/pricing_error_messages.dart`, Q4)

```dart
/// TH-04 mục 6.4. [overrides] để màn giữ câu riêng đã có cho một mã.
String pricingErrorMessage(
  Object error, {
  required String fallback,
  Map<String, String> overrides = const {},
});
```

Thứ tự: `overrides[code]` → bảng dưới → `fallback`. Lỗi không phải `AppException` ⇒ coi như `SYSTEM_ERROR`. Không bao giờ trả `serverMessage` hay mã thô.

| Mã | Câu (TH-04 6.4) |
|---|---|
| `NO_PERMISSION` | "Bạn không có quyền thực hiện thao tác này." |
| `VALIDATION_ERROR` | "Thông tin nhập không hợp lệ." |
| `REFERENCE_INVALID` | "Khách hàng hoặc sản phẩm không hợp lệ." |
| `BELOW_FLOOR_BLOCKED` | "Giá nhập thấp hơn giá sàn quy định." |
| `DUPLICATE_ACTIVE_RULE` | "Đã có giá riêng khác đang áp dụng cho cùng khách hàng và sản phẩm." |
| `STATE_CHANGED` | "Dữ liệu đã thay đổi. Vui lòng tải lại." |
| `INVALID_STATUS` | "Không thể thực hiện với trạng thái hiện tại." |
| `NOT_FOUND` | "Mức giá riêng không còn tồn tại." |
| `IDEMPOTENCY_CONFLICT` | "Không thể lưu giá riêng. Vui lòng thử lại." |
| `SYSTEM_ERROR` | "Đã xảy ra lỗi. Vui lòng thử lại." |
| khác | `fallback` |

### 4.5 `CustomerPriceRuleRepository` (`apps/erp/lib/features/pricing/data/customer_price_rule_repository.dart`)

```dart
class CustomerPriceRuleRepository {
  CustomerPriceRuleRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId});

  Future<CustomerPriceRuleSearchResultDto> search({
    required DateTime businessDate, String? q,
    CustomerPriceRuleQuickFilter quickFilter = CustomerPriceRuleQuickFilter.all,
    List<CustomerPriceRuleDerivedStatus> statuses = const [],
    List<CustomerPriceRuleSourceType> sources = const [],
    String? customerId, String? productId, String? cursor, int limit = 20,
  });
  Future<CustomerPriceRuleDetailDto> getDetail({required String ruleId, required DateTime businessDate});
  Future<CursorPageDto<CustomerPriceRuleActivityDto>> getHistory({required String ruleId, String? cursor, int limit = 50});
  Future<CreateCustomerPriceRuleResult> create({
    required String customerId, required String productId, required String productUnitId,
    required int rulePriceMinor, required String currencyCode, required DateTime effectiveFrom,
    DateTime? effectiveTo, String? note, required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false, required String idempotencyKey,
  });
  Future<CustomerPriceRuleDetailDto> update({
    required String ruleId, required int expectedVersion, required int rulePriceMinor,
    required DateTime effectiveFrom, DateTime? effectiveTo, String? note,
    required bool acknowledgeFloorWarning, bool acknowledgeOverwrite = false,
  });
  Future<CustomerPriceRuleDetailDto> disable({required String ruleId, required int expectedVersion, String? reason});
  Future<CustomerPriceRuleReenablePrecheckDto> precheckReenable({required String ruleId, required int expectedVersion, required DateTime businessDate});
  Future<CustomerPriceRuleDetailDto> reenable({
    required String ruleId, required int expectedVersion, required DateTime businessDate,
    String? precheckToken, required bool acknowledgeFloorWarning, bool acknowledgeOverwrite = false, // Q3
  });
  Future<ResolveApplicableCustomerPriceRuleResultDto> resolveApplicable({
    required String customerId, required String productId, required String productUnitId, required DateTime businessDate,
  });
}
```

Mỗi method: gọi rule (4.3) → `_rpc.call('pricing', '<rpc>', params: …)` → ép `Map<String, dynamic>` → hàm đọc JSON chép từ mapper. Tham số giống hệt mapper cũ, kể cả:

- `create`: `p_rule_id` = `const Uuid().v4()` **mỗi lần gọi** (như handler); `p_currency_code` = `currencyCode.trim().toUpperCase()` (như `Money` trong handler — đã sửa ở R1-1); `p_note` = `normalizeRuleNote(note)`; `p_idempotency_key` = `idempotencyKey.trim()`; ngày `yyyy-MM-dd`; `p_effective_to` null khi không có.
- `update`: `p_note` = `normalizeRuleNote(note)` (handler: không đổi gì thì gửi ghi chú cũ, khác đi thì gửi ghi chú mới đã chuẩn hoá; vì "không đổi" có so ghi chú đã chuẩn hoá nên cả hai trường hợp đều bằng `normalizeRuleNote(note)`).
- `disable`: `p_rule_id` = `ruleId.trim()`; `p_reason` = trim, rỗng → `null`.
- `reenable`: `p_rule_id` = `ruleId.trim()`; `p_acknowledge_overwrite` = `acknowledgeOverwrite` (**đổi có chủ đích, Q3**).
- `resolveApplicable`: 3 id `trim()`.

Hàm đọc JSON: chép các `static` đọc kết quả của `CustomerPriceRuleSearchRpcMapper`, `CustomerPriceRuleDetailRpcMapper`, `CustomerPriceRuleHistoryRpcMapper`, `PricingRpcMapper.createResultFromJson`, `PricingUpdateRpcMapper`, `PricingDisableRpcMapper`, `PricingReenableRpcMapper` (gồm kiểm token 64 hex, `rule_version > 0`), `PricingResolveApplicableRpcMapper` vào `apps/erp/lib/features/pricing/data/mappers/customer_price_rule_json.dart`. Giữ mọi kiểm `FormatException` (vd giá sàn ẩn mà có số). Bỏ các hàm dựng tham số (repository tự dựng).

### 4.6 `SalesPricingRepository` (`apps/erp/lib/features/pricing/data/sales_pricing_repository.dart`, Q2)

```dart
class SalesPricingRepository {
  SalesPricingRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId});

  Future<SalesWorkingStatePricingPreviewDto> preview({
    required String storeId, String? customerId, required String currencyCode,
    required int contextVersion, required DateTime effectiveAt, required List<SalesPricingLineInput> lines,
  });
  Future<SalesManualPriceEvaluationDto> evaluateManualPrice({
    required String storeId, String? customerId, required String productId, required String productUnitId,
    required int quantityMicros, required String currencyCode, required int contextVersion,
    int? manualUnitPriceMinor, int? manualDiscountMinor, int? manualDiscountBasisPoints,
    required bool acknowledgeBelowFloor,
  });
}
```

- `preview`: `checkSalesPreview` → RPC → `previewFromPayload(payload, expectedContextVersion: contextVersion, expectedCurrencyCode: currencyCode, expectedLocalLineIds: [for l in lines l.localLineId])` chép từ `SalesPricingRpcMapper`. `p_effective_at` = `effectiveAt.toUtc().toIso8601String()`.
- `evaluateManualPrice`: `checkSalesManualPrice` → RPC → đọc kết quả như `SalesPricingRpcMapper`. **Bỏ** kiểm quyền client (Q6).
- `storeId` do nơi gọi truyền (sales lấy từ `SessionController.requireActiveStoreId()` như cũ).
- Hàm đọc JSON chép vào `apps/erp/lib/features/pricing/data/mappers/sales_pricing_json.dart`. Lỗi kiểm khớp (`context_version` lệch…) của mapper cũ ném gì thì giữ, `_guard` đổi thành `SYSTEM_ERROR`.

## 5. Đang làm gì — test giữ hành vi

6-A1 không xoá / thay code đang chạy (module giữ nguyên tới 6-C, UI đổi ở 6-A2). Bảng dưới liệt kê việc của handler / gateway cũ mà repository phải giữ, để 6-A2 thay mà không mất. Test ở cột cuối viết **trên module cũ** (nhóm `old`) và repository (nhóm `new`) với **cùng giá trị mong đợi**.

| # | Cũ đang làm gì | Sau 6-A1 nằm ở đâu | Test |
|---|---|---|---|
| D1 | Tham số RPC của 11 lệnh có RPC còn giữ (mục 3) | repository, cùng map | parity `params_<rpc>` × 11 (Task 4, Task 5) |
| D2 | Đọc JSON kết quả (gồm kiểm `FormatException`) | `data/mappers/*_json.dart` | parity `parse_<kiểu>` (Task 1, Task 4, Task 5) |
| D3 | Validator chặn đầu vào trước RPC, mã `VALIDATION_ERROR` + `fieldErrors` | `pricing_rules.dart`, repository gọi trước RPC | `pricing_rules_test.dart` (Task 3) + parity `rule_blocks_before_rpc` (0 lần gọi RPC) |
| D4 | Tạo: RPC đọc trước, chặn trùng **trước** kiểm dưới sàn | **Đổi (Q5):** 1 RPC; server kiểm dưới sàn **trước** trùng. Chỉ khác khi giá dưới sàn mà app gửi `acknowledgeFloorWarning = false` (app chỉ gửi `false` khi giá sàn app biết đã cũ) ⇒ lỗi đầu tiên là `BELOW_FLOOR_BLOCKED` thay vì `DUPLICATE_ACTIVE_RULE` | repository test `create_calls_only_create_rpc` (1 lần gọi, không có `get_customer_price_rule_create_context`) |
| D5 | Sửa: RPC đọc trước, so version ở client → `STATE_CHANGED` | **Đổi (Q5):** server so version (`update_customer_price_rule` báo `STATE_CHANGED`) | `update_calls_only_update_rpc`; `update_propagates_state_changed` (RPC ném `{"code":"STATE_CHANGED"}` → `AppException.code == 'STATE_CHANGED'`) |
| D6 | Bật lại gửi `p_acknowledge_overwrite = false` dù cubit truyền `true` | **Đổi có chủ đích (Q3):** gửi đúng giá trị | `reenable_sends_acknowledge_overwrite` (new: `true` → `true`). Nhóm `old`: `old_reenable_drops_acknowledge_overwrite` ghi lại lỗi cũ (gateway nhận command `acknowledgeOverwrite: true` vẫn gửi `false`) |
| D7 | `mapPricingRpcError`: chỉ 10 mã ổn định, còn lại `SYSTEM_ERROR`; lỗi khác (`FormatException`…) → `SYSTEM_ERROR` | `pricingException` | `pricing_errors_test.dart` (Task 2): cùng bảng đầu vào cho `mapPricingRpcError` (old) và `pricingException` (new) |
| D8 | Xem trước giá: kiểm `context_version` / tiền tệ / tập dòng trả về khớp yêu cầu | `sales_pricing_json.dart` | parity `preview_rejects_mismatched_context` (cả hai đều lỗi; new → `SYSTEM_ERROR`) |
| D9 | Kiểm giá nhập tay: đòi quyền client khi `requiresAcknowledgement` | **Bỏ (Q6)** | `evaluate_returns_result_when_ack_required` (new trả kết quả, không gọi gì thêm) |
| D10 | `ruleId` trim; lý do tắt trim → null | repository | nằm trong D1 (đầu vào có khoảng trắng) |

**Task 0:** viết nhóm `old` của mọi test parity trước (gọi mapper / codec / `mapPricingRpcError` của module qua `implementation_imports`, như `git show 4d35ec33e:apps/erp/test/features/catalog/data/product_rpc_parity_test.dart`), chạy xanh, ghi tên test. Nhóm `new` viết ở Task 1 và task của từng repository, dùng **cùng** hằng mong đợi.

## 6. Các bước

> Viết theo `superpowers:writing-plans`. Thực hiện: `superpowers:executing-plans` (tuần tự trong phiên). Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`).
> 6-A1 chỉ thêm tệp mới ⇒ không sửa symbol có sẵn. Vẫn chạy `gitnexus impact` nếu lỡ phải sửa tệp có sẵn ngoài danh sách.

**Ràng buộc chung** (mọi task):
- Không sửa tệp nào trong `apps/erp/lib` ngoài thư mục mới `features/pricing/data/`, `features/pricing/logic/` (2 tệp `pricing_rules.dart`, `pricing_error_messages.dart`). Không đụng `modules/pricing`.
- Model / hàm đọc JSON: chép nguyên văn, chỉ đổi import. Thấy chỗ nào phải sửa thân mới chạy được ⇒ ghi vào Kết quả, không tự đổi hành vi.
- Không có `tenantId` / `actorId` trong chữ ký repository; `tenantId` lấy qua `_tenantId()` mỗi lần gọi.
- Test đặt ở `apps/erp/test/features/pricing/{data,logic}/`. Test parity có `// ignore_for_file: implementation_imports`.

### Task 0: Nhóm `old` của test parity (trên module)

**Files:**
- Create: `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart` (nhóm `old (mappers)`; nhóm `new` thêm ở Task 1, 4, 5)
- Create: `apps/erp/test/features/pricing/data/pricing_parity_expectations.dart` (hằng mong đợi dùng chung)

- [x] **0.1** Hằng mong đợi, mỗi RPC một map tham số với đầu vào cố định: `tenantId = 'tenant-1'`, `ruleId = '11111111-1111-4111-8111-111111111111'` (đầu vào có khoảng trắng ở `disable` / `reenable` / `resolve`), ngày `DateTime(2026, 11, 4)` → `'2026-11-04'`, `note: '  ghi chú  '` → `'ghi chú'`, `reason: '   '` → `null`. Ví dụ:
  ```dart
  const expectedDisableParams = {
    'p_tenant_id': 'tenant-1', 'p_rule_id': '11111111-1111-4111-8111-111111111111',
    'p_expected_version': 3, 'p_reason': null,
  };
  ```
  `create` / `update`: so map **bỏ** `p_rule_id` (UUID ngẫu nhiên) và kiểm riêng `p_rule_id` khớp `Uuid.isValidUUID`.
- [x] **0.2** Hằng JSON mẫu cho mỗi kiểu kết quả (detail đủ khối `customer`, `product_unit`, `price`, `effective_period`, `validation_outcome`, `reference_health`, `source_trace`; search page; history page có 1 dòng mỗi loại actor; preview 2 dòng; manual evaluation; resolve có `rule` và `rule: null`). Lấy từ test có sẵn của module (`modules/pricing/infrastructure/test/domain/**`) để chắc đúng hình.
- [x] **0.3** Nhóm `old`: gọi `…RpcMapper.<x>Params(<command/query cũ>)` → `equals(expected…)`; `…FromJson(json)` → so field bằng hàm `expectDetail(dto, …)` dùng chung (viết trong tệp expectations, nhận `dynamic` để dùng cho cả kiểu cũ lẫn mới). Thêm `old_reenable_drops_acknowledge_overwrite`: dựng `SupabaseCustomerPriceRuleCommandGateway` với `SupabaseSchemaRpcClient` trên client giả ghi tham số (nếu không dựng được client giả thì kiểm bằng cách đọc chữ ký `ICustomerPriceRuleCommandGateway.reenable` không có `acknowledgeOverwrite` và ghi ⏭ + lý do), `mapPricingRpcError`.
- [x] **0.4** Chạy `cd apps/erp && flutter test test/features/pricing/data/pricing_rpc_parity_test.dart` → PASS. Ghi tên test.

### Task 1: Model + hàm đọc JSON

**Files:**
- Create: `apps/erp/lib/features/pricing/data/models/{pricing_enums,pricing_common,customer_price_rule,customer_price_rule_activity,sales_pricing}.dart`, `apps/erp/lib/features/pricing/data/models.dart`
- Create: `apps/erp/lib/features/pricing/data/mappers/{customer_price_rule_json,sales_pricing_json}.dart`

**Produces:** các lớp ở mục 4.1 (cùng tên, cùng field với module); hàm đọc JSON `CustomerPriceRuleJson.detail(Map)`, `.searchResult(Map)`, `.historyPage(Map)`, `.createResult(Map)`, `.precheck(Map)`, `.resolveResult(Map)`; `SalesPricingJson.preview(Object?, {expectedContextVersion, expectedCurrencyCode, expectedLocalLineIds})`, `.manualEvaluation(Object?)`.

- [x] **1.1** Chép model theo bảng 4.1. `dart analyze lib/features/pricing/data` → 0 lỗi.
- [x] **1.2** Chép hàm đọc JSON (bỏ hàm dựng tham số). Giữ tên hàm private cũ bên trong lớp mới.
- [x] **1.3** Thêm vào `pricing_rpc_parity_test.dart` nhóm `new (json)`: cùng JSON mẫu, cùng `expectDetail…`. Chạy lệnh 0.4 → PASS.

### Task 2: Lỗi + câu lỗi

**Files:**
- Create: `apps/erp/lib/features/pricing/data/pricing_errors.dart`, `apps/erp/lib/features/pricing/logic/pricing_error_messages.dart`
- Test: `apps/erp/test/features/pricing/data/pricing_errors_test.dart`, `apps/erp/test/features/pricing/logic/pricing_error_messages_test.dart`

**Produces:** `PricingErrorCodes` (12 hằng), `AppException pricingException(Object error)`, `String pricingErrorMessage(Object error, {required String fallback, Map<String, String> overrides = const {}})`.

- [x] **2.1** `pricing_errors_test.dart`: bảng đầu vào → mã:
  - `PostgrestException(message: '{"code":"DUPLICATE_ACTIVE_RULE","message":"x","details":{"conflictingRuleId":"r1","reason":"overwriteRequired"}}')` → `DUPLICATE_ACTIVE_RULE`, `details['conflictingRuleId'] == 'r1'`;
  - mỗi mã trong 10 mã ổn định → giữ;
  - `{"code":"OVERWRITE_REQUIRED"}` → `SYSTEM_ERROR` (không có trong `_stableCode`);
  - `{"code":"IMPORT_MODE_MISMATCH"}` → `SYSTEM_ERROR`;
  - `PostgrestException(message: 'boom')` (không JSON) → `SYSTEM_ERROR`;
  - `FormatException('x')`, `StateError('x')` → `SYSTEM_ERROR`;
  - `AppException('VALIDATION_ERROR', details: {'fieldErrors': {...}})` → giữ nguyên `details`.
  Nhóm `old` chạy cùng bảng qua `mapPricingRpcError(RpcException(...))` (với dòng có `RpcException`) — dòng nào không áp được cho bản cũ thì chỉ chạy ở `new`.
- [x] **2.2** `pricing_error_messages_test.dart`: 10 mã → đúng câu ở bảng 4.4; mã lạ → `fallback`; `StateError` → câu `SYSTEM_ERROR`; `overrides: {'STATE_CHANGED': 'A'}` → `'A'`; không câu nào chứa mã hay `serverMessage` (`AppException('X_CODE', serverMessage: 'raw')` với fallback `'F'` → `'F'`).
- [x] **2.3** Chạy 2 test → FAIL (chưa có lớp). Viết 2 tệp. Chạy lại → PASS.

### Task 3: Rule đầu vào

**Files:**
- Create: `apps/erp/lib/features/pricing/logic/pricing_rules.dart`
- Test: `apps/erp/test/features/pricing/logic/pricing_rules_test.dart`

**Consumes:** `PricingErrorCodes` (Task 2), `SalesPricingLineInput` (Task 1).
**Produces:** 12 hàm ở bảng 4.3.

- [x] **3.1** Test: mỗi hàm một ca hợp lệ (không ném) và một ca cho **mỗi** điều kiện → `throwsA(isA<AppException>().having((e) => e.code, 'code', 'VALIDATION_ERROR').having((e) => e.details?['fieldErrors'], 'fieldErrors', {'<field>': '<mã>'}))`. Ca biên: giá `0` → `must_be_positive`; `effectiveTo` cùng ngày với `effectiveFrom` nhưng khác giờ → hợp lệ; `effectiveTo` hôm trước → `before_effective_from`; lý do 500 ký tự → hợp lệ, 501 → `too_long`; sales: `effectiveAt` không UTC → lỗi câu `'Effective time must be UTC.'`, 2 dòng trùng `localLineId` → `'Local line ids must be unique.'`, điểm cơ bản `10001` → `'Discount basis points must be in 0..10000.'`; `normalizeRuleNote('  ')` → `null`.
- [x] **3.2** Chạy → FAIL. Viết `pricing_rules.dart`. Chạy → PASS.

### Task 4: `CustomerPriceRuleRepository`

**Files:**
- Create: `apps/erp/lib/features/pricing/data/customer_price_rule_repository.dart`
- Test: `apps/erp/test/features/pricing/data/customer_price_rule_repository_test.dart` + nhóm `new (CustomerPriceRuleRepository)` trong parity

**Consumes:** Task 1–3; `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})`.
**Produces:** chữ ký mục 4.5.

- [x] **4.1** Parity `new`: `_RecordingRpc extends SupabaseRpc` (mẫu `class _RecordingRpc` trong `apps/erp/test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart`) ghi `(schema, fn, params)` và trả JSON mẫu; mỗi method → `schema == 'pricing'`, `fn` đúng, `params` bằng hằng 0.1; kết quả qua `expectDetail…`.
- [x] **4.2** Repository test riêng:
  - `create_calls_only_create_rpc` (D4): 1 lần gọi, `fn == 'create_customer_price_rule'`, `params['p_rule_id']` là UUID v4, gọi 2 lần → 2 `p_rule_id` khác nhau, cùng `p_idempotency_key`;
  - `update_calls_only_update_rpc`, `update_propagates_state_changed` (D5);
  - `reenable_sends_acknowledge_overwrite` (D6): `acknowledgeOverwrite: true` → `params['p_acknowledge_overwrite'] == true`; mặc định → `false`;
  - `rule_blocks_before_rpc` (D3): `create(rulePriceMinor: 0, …)` → `VALIDATION_ERROR`, `calls` rỗng; `getDetail(ruleId: 'x')` → `VALIDATION_ERROR`, `calls` rỗng;
  - `malformed_json_is_system_error` (D7): RPC trả `{'items': 1}` cho `search` → `SYSTEM_ERROR`;
  - `tenant_read_each_call`: `tenantId` closure đếm lần gọi = số lần gọi method.
- [x] **4.3** Chạy → FAIL. Viết repository. Chạy `flutter test test/features/pricing/data/` → PASS.

### Task 5: `SalesPricingRepository`

**Files:**
- Create: `apps/erp/lib/features/pricing/data/sales_pricing_repository.dart`
- Test: `apps/erp/test/features/pricing/data/sales_pricing_repository_test.dart` + nhóm `new (SalesPricingRepository)` trong parity

**Consumes:** Task 1–3. **Produces:** chữ ký mục 4.6.

- [x] **5.1** Parity `new`: `preview` / `evaluateManualPrice` → params bằng `SalesPricingRpcMapper.previewParams` / `manualEvaluationParams` của nhóm `old` (đầu vào: `effectiveAt = DateTime.utc(2026, 11, 4, 3)`, 2 dòng, 1 dòng có `manualUnitPriceMinor`).
- [x] **5.2** Repository test: `preview_rejects_mismatched_context` (D8: RPC trả `context_version` khác → `SYSTEM_ERROR`); `preview_empty_lines_blocked` (0 dòng → `VALIDATION_ERROR`, 0 lần gọi RPC); `evaluate_returns_result_when_ack_required` (D9: RPC trả `requires_acknowledgement: true` → trả DTO, đúng 1 lần gọi).
- [x] **5.3** Chạy → FAIL. Viết. Chạy → PASS.

### Task 6: Kiểm toàn bộ + Kết quả

- [x] **6.1** `cd apps/erp && dart analyze lib/features/pricing test/features/pricing` → 0 lỗi, 0 cảnh báo mới.
- [x] **6.2** `dart run tool/check_feature_imports.dart` → không dòng mới của `pricing` (tệp `data/` mới chỉ import `core/` và chính `features/pricing`).
- [x] **6.3** `flutter test test/features/pricing/` → PASS; `flutter test` cả app → số lỗi đúng bằng `docs/refactor/TEST-BASELINE.md` (so từng tên).
- [x] **6.4** `git grep -n "vet45_pricing" -- apps/erp/lib/features/pricing/data apps/erp/lib/features/pricing/logic` → rỗng.
- [x] **6.5** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})`: chỉ tệp mới; ghi số tệp / symbol / luồng / rủi ro vào Kết quả.

## 7. Kiểm tra

Tự động: mục 6 Task 6. Không có kiểm tay (6-A1 không đổi màn nào). Kiểm tay toàn Theme 4 ở 6-A2 mục 7.2.

## 8. Rủi ro / lưu ý

- **Thứ tự lỗi khi tạo (D4).** Chỉ lộ ra khi giá sàn app đang biết đã cũ. 6-A2 giữ màn xử lý cả hai mã như cũ (`PriceRuleFormCubit._handleBlocked`).
- **`OVERWRITE_REQUIRED`** có trong `PricingBlockedCodes` nhưng không trong `_stableCode` ⇒ vẫn `SYSTEM_ERROR` (Q7). Server không trả mã này (đo `grep` migration 2026-11-04).
- **Lỗi không phải JSON** (chốt R1-2 2026-11-04, đổi có chủ đích so với `mapPricingRpcError` cũ): mất mạng (`NETWORK_ERROR`) và `not authenticated` (`AUTHENTICATION_REQUIRED`) không nằm trong 10 mã ổn định ⇒ vẫn `SYSTEM_ERROR`; riêng `PostgrestException` có `permission denied` / `42501` / `PERMISSION_DENIED` ⇒ `NO_PERMISSION` và `RESOURCE_NOT_FOUND` ⇒ `NOT_FOUND` (nhờ đi qua `AppException.from`, trong khi `mapPricingRpcError` cũ ra `SYSTEM_ERROR`).
- **Thiếu phiên** (`SessionController.requireTenantId` ném `AUTHENTICATION_REQUIRED`): đọc `tenantId` nằm trong `_guard` ⇒ `SYSTEM_ERROR` (cũ: lệnh → `NO_PERMISSION` "Execution context is required.", cubit tự đọc → `ApplicationException`). Không tới được trong app vì `StoreShell` chặn khi chưa có tổ chức.
- `MoneyDto` trùng tên với sales (mục 4.1).
- Chép nguyên văn mapper dài (~1.400 dòng) dễ sót: parity D1 / D2 là lưới chặn; review so `diff` giữa mapper cũ và tệp mới.

### Review Focus (chưa task nào test, phiên review soi)

1. Ngày lịch: `effectiveFrom` là `DateTime` giờ địa phương 00:00 ở Việt Nam ⇒ `_date` lấy năm / tháng / ngày, **không** `toUtc()` (nếu chép nhầm sang `toIso8601String()` sẽ lùi một ngày). D1 dùng `DateTime(2026, 11, 4)` giờ địa phương; review kiểm thêm `DateTime(2026, 11, 4, 0, 30)`.
2. `p_effective_at` của `preview` phải `toUtc()` (khác các ngày khác).
3. JSON có số nguyên dạng `double` (`1200.0`) ở tiền: mapper cũ `_requiredInt` nhận số nguyên dạng double — kiểm bản chép giữ.
4. `CursorPageDto.hasMore` / `nextCursor` khi `next_cursor` null mà `has_more` true: giữ đúng cách cũ (không tự sửa).

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi task** ghi ngay (không dồn cuối), theo mẫu:
> - **Task N — ✅ / 🔄 dở (tới bước …) / ⏭ (lý do)**
> - Tệp:dòng đã thêm / đổi
> - Lệch so với plan + lý do
> - Test thêm / sửa (tên) + kết quả chạy
> - Impact (`gitnexus impact`, nếu có sửa symbol có sẵn) — số lấy từ lệnh, ghi lệnh + thời điểm index
> - Ghi chú cho review
>
> Task 6 ghi thêm: lệnh đã chạy, pass / fail, tên test hỏng đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.

### Task 0 — ✅

- **Tệp:dòng đã thêm:**
  - `apps/erp/test/features/pricing/data/pricing_parity_expectations.dart:1–529` (hằng đầu vào cố định, 11 map tham số mong đợi, 8 JSON mẫu, 8 hàm `expect*` nhận `dynamic`).
  - `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart:1–478` (nhóm `old (mappers)` + `_FakePricingRpcSupabase`).
- **Lệch so với plan:** Không.
- **Test thêm + kết quả chạy:** `cd apps/erp && flutter test test/features/pricing/data/pricing_rpc_parity_test.dart` → **23 PASS**:
  - `old (mappers) params params_search_customer_price_rules`
  - `old (mappers) params params_get_customer_price_rule_detail`
  - `old (mappers) params params_get_customer_price_rule_history`
  - `old (mappers) params params_create_customer_price_rule`
  - `old (mappers) params params_update_customer_price_rule`
  - `old (mappers) params params_disable_customer_price_rule`
  - `old (mappers) params params_precheck_customer_price_rule_reenable`
  - `old (mappers) params params_reenable_customer_price_rule`
  - `old (mappers) params params_resolve_applicable_customer_price_rule`
  - `old (mappers) params params_preview_sales_working_state_pricing`
  - `old (mappers) params params_evaluate_sales_manual_price`
  - `old (mappers) json parse_detail`
  - `old (mappers) json parse_create_result`
  - `old (mappers) json parse_search_result`
  - `old (mappers) json parse_history_page`
  - `old (mappers) json parse_reenable_precheck`
  - `old (mappers) json parse_resolve_found`
  - `old (mappers) json parse_resolve_null`
  - `old (mappers) json parse_sales_preview`
  - `old (mappers) json parse_sales_manual_evaluation`
  - `old (mappers) json preview_rejects_mismatched_context`
  - `old (mappers) old_reenable_drops_acknowledge_overwrite`
  - `old (mappers) old_map_pricing_rpc_error`
- **Impact:** Chỉ thêm tệp test mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** `old_reenable_drops_acknowledge_overwrite` dựng thật `ReenableCustomerPriceRuleCommandHandler` + `SupabaseCustomerPriceRuleCommandGateway` + `SupabaseSchemaRpcClient` trên `_FakePricingRpcSupabase` để ghi nhận `p_acknowledge_overwrite == false` khi truyền `acknowledgeOverwrite: true`.

### Task 1 — ✅

- **Tệp:dòng đã thêm / đổi:**
  - `apps/erp/lib/features/pricing/data/models/pricing_enums.dart:1–38` (8 enum: `CustomerPriceRuleStatus`, `CustomerPriceRuleSourceType`, `CustomerPriceRuleType`, `CustomerPriceRuleDerivedStatus`, `CustomerPriceRuleQuickFilter`, `CustomerPriceRuleActivityType`, `CustomerPriceRuleReferenceState`, `CustomerPriceRulePriceBandState`).
  - `apps/erp/lib/features/pricing/data/models/pricing_common.dart:1–95` (9 lớp: `MoneyDto`, `EffectivePeriodDto`, `CursorPageDto<T>`, `RuleIssueDto`, `RuleValidationOutcomeDto`, `CustomerRefDto`, `ProductUnitRefDto`, `CustomerPriceRuleAvailableActions`, `PricingAvailableActions`).
  - `apps/erp/lib/features/pricing/data/models/customer_price_rule.dart:1–171` (9 lớp: `CustomerPriceRuleDetailDto`, `CustomerPriceRuleReferenceHealthDto`, `CustomerPriceRuleSourceTraceDto`, `CustomerPriceRuleListItemDto`, `CustomerPriceRuleSearchResultDto`, `CreateCustomerPriceRuleResult`, `CustomerPriceRuleReenablePrecheckDto`, `ApplicableCustomerPriceRuleDto`, `ResolveApplicableCustomerPriceRuleResultDto`).
  - `apps/erp/lib/features/pricing/data/models/customer_price_rule_activity.dart:1–57` (3 lớp: `CustomerPriceRuleActivityDto`, `CustomerPriceRuleActivityActorDto`, `CustomerPriceRuleActivitySourceTraceDto`).
  - `apps/erp/lib/features/pricing/data/models/sales_pricing.dart:1–85` (4 lớp: `SalesPricingLineInput`, `SalesPricingLinePreviewDto`, `SalesWorkingStatePricingPreviewDto`, `SalesManualPriceEvaluationDto`).
  - `apps/erp/lib/features/pricing/data/models.dart:1–5` (barrel export 5 tệp model).
  - `apps/erp/lib/features/pricing/data/mappers/customer_price_rule_json.dart:1–572` (`CustomerPriceRuleJson`: `detail`, `searchResult`, `historyPage`, `createResult`, `precheck`, `resolveResult`).
  - `apps/erp/lib/features/pricing/data/mappers/sales_pricing_json.dart:1–158` (`SalesPricingJson`: `preview`, `manualEvaluation`).
  - `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart:3–4,412–491` (thêm nhóm `new (json)`).
- **Lệch so với plan:**
  - `pricing_enums.dart` có thêm `CustomerPriceRuleType` (`enum CustomerPriceRuleType { specialPrice, rememberedPrice }` từ `modules/pricing/domain/lib/src/customer_price_rule/customer_price_rule_type.dart`) vì `CustomerPriceRuleDetailDto` và `CustomerPriceRuleListItemDto` có trường `final CustomerPriceRuleType ruleType;` (bảng 4.1 sót liệt kê tên này nhưng bắt buộc phải có để không import `vet45_pricing_domain`).
  - Khi gộp các mapper đọc kết quả vào một lớp `CustomerPriceRuleJson`: hàm `_item` của `CustomerPriceRuleHistoryRpcMapper` đổi tên thành `_historyItem` (để không đụng `_item` của `CustomerPriceRuleSearchRpcMapper`), và `_requiredStrings` của `PricingReenableRpcMapper` (có kiểm trùng mã cảnh báo) đổi tên thành `_requiredUniqueStrings` (để không đụng `_requiredStrings` của `CustomerPriceRuleDetailRpcMapper`); `_money` dùng `_requiredInt` (chép từ `PricingRpcMapper._requiredInt`) để nhận cả số nguyên dạng `double` (`1200.0`) theo Review Focus 3.
  - `SalesPricingJson.preview` và `.manualEvaluation` bỏ khối `try { ... } on PricingBlockedException` (vì không chép `PricingBlockedException`), ném thẳng `FormatException` để `_guard` của repository ở Task 5 đổi sang `AppException(SYSTEM_ERROR)` theo mục 4.6.
- **Test thêm + kết quả chạy:** `cd apps/erp && dart analyze lib/features/pricing/data && flutter test test/features/pricing/data/pricing_rpc_parity_test.dart` → **0 issues, 34 PASS** (thêm 11 test trong `new (json)`: `parse_detail`, `parse_create_result`, `parse_search_result`, `parse_history_page`, `parse_reenable_precheck`, `parse_resolve_found`, `parse_resolve_null`, `parse_sales_preview`, `parse_sales_manual_evaluation`, `preview_rejects_mismatched_context`, `money_accepts_integer_double_and_rejects_fractional_double`).
- **Impact:** Chỉ thêm tệp mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** Đã thêm test `money_accepts_integer_double_and_rejects_fractional_double` kiểm tra Review Focus 3 (`1200.0` → `1200`, `1200.5` → `FormatException`).

### Task 2 — ✅

- **Tệp:dòng đã thêm:**
  - `apps/erp/lib/features/pricing/data/pricing_errors.dart:1–39` (`PricingErrorCodes` với 11 hằng chép từ `PricingBlockedCodes`, `_stableCodes` 10 mã, `pricingException`).
  - `apps/erp/lib/features/pricing/logic/pricing_error_messages.dart:1–29` (`pricingErrorMessage` theo bảng 4.4).
  - `apps/erp/test/features/pricing/data/pricing_errors_test.dart:1–127` (31 test: 14 `old (mapPricingRpcError)` + 17 `new (pricingException)`).
  - `apps/erp/test/features/pricing/logic/pricing_error_messages_test.dart:1–61` (13 test cho 10 mã, fallback, `StateError`, `overrides`).
- **Lệch so với plan:** `PricingBlockedCodes` gốc (`modules/pricing/application/lib/src/shared/pricing_blocked_codes.dart`) thực tế có **11** hằng (10 mã ổn định + `overwriteRequired`), không phải 12 như ghi chú ở mục 4.2.
- **Test thêm + kết quả chạy:** Chạy trước khi viết lớp → FAIL; sau khi viết 2 tệp → `cd apps/erp && flutter test test/features/pricing/data/pricing_errors_test.dart test/features/pricing/logic/pricing_error_messages_test.dart` → **44 PASS** (31 ở `pricing_errors_test.dart`, 13 ở `pricing_error_messages_test.dart`).
- **Impact:** Chỉ thêm tệp mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** Không.

### Task 3 — ✅

- **Tệp:dòng đã thêm:**
  - `apps/erp/lib/features/pricing/logic/pricing_rules.dart:1–365` (12 hàm kiểm tra đầu vào theo bảng 4.3: `checkCreateRule`, `checkUpdateRule`, `checkDisableRule`, `checkReenableRule`, `checkPrecheckReenable`, `checkRuleId`, `checkHistoryPage`, `checkSearch`, `checkResolve`, `checkSalesPreview`, `checkSalesManualPrice`, `normalizeRuleNote`).
  - `apps/erp/test/features/pricing/logic/pricing_rules_test.dart:1–967` (65 test phủ đủ 12 hàm và tất cả ca biên ở bước 3.1).
- **Lệch so với plan:** Không.
- **Test thêm + kết quả chạy:** Chạy trước khi viết `pricing_rules.dart` → FAIL; sau khi viết → `cd apps/erp && dart analyze lib/features/pricing/logic/pricing_rules.dart test/features/pricing/logic/pricing_rules_test.dart && flutter test test/features/pricing/logic/pricing_rules_test.dart` → **0 issues, 65 PASS**.
- **Impact:** Chỉ thêm tệp mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** Không.

### Task 4 — ✅

- **Tệp:dòng đã thêm / đổi:**
  - `apps/erp/lib/features/pricing/data/customer_price_rule_repository.dart:1–355` (`CustomerPriceRuleRepository`: `search`, `getDetail`, `getHistory`, `create`, `update`, `disable`, `precheckReenable`, `reenable`, `resolveApplicable` + `_guard`, `_date`, `_quickFilterWire`, `_derivedStatusWire`, `_sourceWire`).
  - `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart:1–12,494–707` (thêm nhóm `new (CustomerPriceRuleRepository)` với 9 test parity `params_*` + `_RecordingRpc`).
  - `apps/erp/test/features/pricing/data/customer_price_rule_repository_test.dart:1–248` (8 test: `create_calls_only_create_rpc`, `update_calls_only_update_rpc`, `update_propagates_state_changed`, `reenable_sends_acknowledge_overwrite`, `rule_blocks_before_rpc`, `malformed_json_is_system_error`, `tenant_read_each_call`, `local_calendar_date_at_00_30_is_not_converted_to_utc`).
- **Lệch so với plan:** Không.
- **Test thêm + kết quả chạy:** Chạy trước khi viết `customer_price_rule_repository.dart` → FAIL; sau khi viết → `cd apps/erp && dart analyze lib/features/pricing/data test/features/pricing/data && flutter test test/features/pricing/data/` → **0 issues, 82 PASS**.
- **Impact:** Chỉ thêm tệp mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** Đã thêm test `local_calendar_date_at_00_30_is_not_converted_to_utc` kiểm tra Review Focus 1 (`DateTime(2026, 11, 4, 0, 30)` giờ địa phương giữ nguyên `'2026-11-04'`, không gọi `toUtc()`).

### Task 5 — ✅

- **Tệp:dòng đã thêm / đổi:**
  - `apps/erp/lib/features/pricing/data/sales_pricing_repository.dart:1–121` (`SalesPricingRepository`: `preview`, `evaluateManualPrice` + `_guard`, `_lineParams`).
  - `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart:11,670–736` (thêm nhóm `new (SalesPricingRepository)` với 2 test parity `params_preview_sales_working_state_pricing`, `params_evaluate_sales_manual_price`).
  - `apps/erp/test/features/pricing/data/sales_pricing_repository_test.dart:1–146` (3 test: `preview_rejects_mismatched_context`, `preview_empty_lines_blocked`, `evaluate_returns_result_when_ack_required`).
- **Lệch so với plan:** Không.
- **Test thêm + kết quả chạy:** Chạy trước khi viết `sales_pricing_repository.dart` → FAIL; sau khi viết → `cd apps/erp && dart analyze lib/features/pricing/data test/features/pricing/data && flutter test test/features/pricing/data/` → **0 issues, 87 PASS**.
- **Impact:** Chỉ thêm tệp mới, không sửa symbol có sẵn.
- **Ghi chú cho review:** Không.

### Task 6 — ✅

- **Lệnh đã chạy + kết quả:**
  - **6.1:**
    - `cd apps/erp && dart analyze lib/features/pricing/data lib/features/pricing/logic test/features/pricing/data test/features/pricing/logic` → **No issues found!** (0 lỗi, 0 cảnh báo, 0 info).
    - `cd apps/erp && dart analyze lib/features/pricing test/features/pricing` → **0 lỗi, 0 cảnh báo** (134 info `deprecated_member_use` / `prefer_conditional_assignment` có sẵn ở `presentation/`).
  - **6.2:** `cd apps/erp && dart run tool/check_feature_imports.dart` → không có dòng R2/R3 của `pricing`; có 2 dòng R1 (`lib/features/pricing/data/customer_price_rule_repository.dart:5` và `lib/features/pricing/data/sales_pricing_repository.dart:5` import `logic/pricing_rules.dart` theo đúng thiết kế mục 4.3/4.5/4.6, giống hệt `partner_repository.dart:4` và 4 repository của `catalog/data/`). Các tệp mới trong `pricing/data/` chỉ import `core/` và chính `features/pricing`.
  - **6.3:**
    - `cd apps/erp && flutter test test/features/pricing/data test/features/pricing/logic` → **165 PASS / 0 FAIL** (87 ở `data/`, 78 ở `logic/`).
    - `cd apps/erp && flutter test test/features/pricing/` → **239 PASS / 11 FAIL**; 11 test lỗi đều nằm ở `presentation/` và khớp đúng 11 dòng `pricing/presentation` trong `docs/refactor/TEST-BASELINE.md:110–120`.
    - `cd apps/erp && flutter test --no-pub -r compact` (cả app) → **2.277 PASS / 59 FAIL** (`2.112 + 165 = 2.277` đạt; 59 lỗi khớp 100% mốc sau 5-C trong `docs/refactor/TEST-BASELINE.md:13,65–121`: 57 lỗi trong danh sách + 2 lỗi `product_guided_create_e2e_test` / `product_change_history_e2e_test`, 0 lỗi mới).
  - **6.4:** `git grep -n "vet45_pricing" -- apps/erp/lib/features/pricing/data apps/erp/lib/features/pricing/logic` → **rỗng**.
  - **6.5:**
    - `node .gitnexus/run.cjs analyze` (chạy lúc 2026-11-04 22:03 +07:00): `50,764 nodes | 113,320 edges | 1268 clusters | 300 flows`.
    - `node .gitnexus/run.cjs detect_changes --scope all --repo erp-sales-inventory`: `Changes: 4 files, 9 symbols | Affected processes: 0 | Risk level: low` (4 tệp thay đổi đã theo dõi trong git là tệp tài liệu từ 5-C chưa commit; toàn bộ 19 tệp code/test của 6-A1 đều là tệp mới untracked dưới `apps/erp/{lib,test}/features/pricing/{data,logic}/`, không sửa symbol có sẵn nào).

### R1 — sửa (2026-11-04)

- **Tệp:dòng đã thêm / đổi:**
  - `apps/erp/lib/features/pricing/data/customer_price_rule_repository.dart:138` (`create`: `'p_currency_code': currencyCode.trim().toUpperCase()` — R1-1).
  - `apps/erp/lib/features/pricing/data/sales_pricing_repository.dart:33–53,92` (`preview`: `final normalizedCurrencyCode = currencyCode.trim().toUpperCase();` dùng cho cả `'p_currency_code'` và `expectedCurrencyCode`; `evaluateManualPrice`: `'p_currency_code': currencyCode.trim().toUpperCase()` — R1-1).
  - `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart:279–361,754–896` (thêm 6 test parity tiền tệ chữ thường `' vnd '` → `'VND'` ở cả `old` và `new`: `params_create_customer_price_rule_lowercase_currency`, `params_preview_sales_working_state_pricing_lowercase_currency`, `params_evaluate_sales_manual_price_lowercase_currency` — R1-1).
  - `apps/erp/test/features/pricing/data/sales_pricing_repository_test.dart:104–133` (thêm `preview_accepts_lowercase_currency`: đầu vào `' vnd '`, RPC trả `currency_code: 'VND'` → trả DTO — R1-1).
  - `apps/erp/test/features/pricing/data/pricing_errors_test.dart:70–80,108–143` (thêm test `maps non-JSON permission and not-found messages to SYSTEM_ERROR` ở nhóm `old (mapPricingRpcError)` và 4 test ở nhóm `new (pricingException)`: `PostgrestException(message: 'permission denied: pricing.sales.preview')` → `NO_PERMISSION`, `PostgrestException(message: 'not authenticated')` → `SYSTEM_ERROR`, `PostgrestException(message: 'PERMISSION_DENIED: x')` → `NO_PERMISSION`, `PostgrestException(message: 'RESOURCE_NOT_FOUND: x')` → `NOT_FOUND` — R1-2).
  - `docs/refactor/plans/P6/6-A1-pricing-data.md:27,179,350` (cập nhật Q7, mục 4.5 và mục 8 theo chốt R1-1 / R1-2).
- **Test thêm / sửa + kết quả chạy:**
  - `cd apps/erp && dart analyze lib/features/pricing/data lib/features/pricing/logic test/features/pricing/data test/features/pricing/logic` → **No issues found!** (0 lỗi, 0 cảnh báo, 0 info).
  - `cd apps/erp && flutter test test/features/pricing/data test/features/pricing/logic` → **177 PASS / 0 FAIL** (98 ở `data/`, 79 ở `logic/`; tăng +12 test so với trước R1).
- **Impact (`gitnexus impact`, index lúc 2026-11-04 22:03 +07:00):**
  - `node .gitnexus/run.cjs impact create -f apps/erp/lib/features/pricing/data/customer_price_rule_repository.dart --kind Method -r erp-sales-inventory` → `impactedCount: 0, risk: LOW`.
  - `node .gitnexus/run.cjs impact preview -f apps/erp/lib/features/pricing/data/sales_pricing_repository.dart --kind Method -r erp-sales-inventory` → `impactedCount: 0, risk: LOW`.
  - `node .gitnexus/run.cjs impact evaluateManualPrice -f apps/erp/lib/features/pricing/data/sales_pricing_repository.dart --kind Method -r erp-sales-inventory` → `impactedCount: 0, risk: LOW`.

## 10. Review

### R2 — 2026-11-04 — **ĐẠT** (đã sửa R1-1, R1-2 của R1)

| Việc R1 | Kết quả kiểm lại |
|---|---|
| R1-1 mã tiền tệ chữ hoa | ✅ `customer_price_rule_repository.dart:138`, `sales_pricing_repository.dart:33` (dùng cho cả `p_currency_code` và `expectedCurrencyCode` của `preview`), `:92`. 6 test parity `*_lowercase_currency` (3 `old` + 3 `new`, đầu vào `' vnd '` → `'VND'`) và `preview_accepts_lowercase_currency` đều đạt |
| R1-2 lệch mã lỗi Q7 (giữ hành vi mới, người dùng chốt) | ✅ Q7 (dòng 27) và mục 8 (dòng 350) đã ghi đúng. `pricing_errors_test.dart`: nhóm `old` khoá hành vi cũ (4 câu → `SYSTEM_ERROR`), nhóm `new` có 4 ca (`permission denied…` → `NO_PERMISSION`, `not authenticated` → `SYSTEM_ERROR`, `PERMISSION_DENIED: x` → `NO_PERMISSION`, `RESOURCE_NOT_FOUND: x` → `NOT_FOUND`) |

Review chạy lại:

| Lệnh | Kết quả |
|---|---|
| `dart analyze lib/features/pricing/{data,logic} test/features/pricing/{data,logic}` | ✅ No issues found |
| `flutter test test/features/pricing/data test/features/pricing/logic` | ✅ 177 đạt (khớp Kết quả "R1 — sửa": +12 so với R1) |
| `flutter test test/features/pricing/` | ✅ 251 đạt / 11 lỗi, 11 lỗi đúng 11 dòng baseline `TEST-BASELINE.md:110–120` |
| `check_feature_imports` | ✅ chỉ 2 dòng `R1` đã chấp nhận ở R1 |
| Tệp có sẵn bị sửa | ✅ không: `git status` chỉ còn tệp tài liệu có từ trước 6-A1; mọi tệp code / test của 6-A1 là tệp mới |
| Impact ghi trong Kết quả | ✅ 3 lệnh `impact` của 3 method đã sửa, `impactedCount: 0`, LOW (method mới, chưa ai gọi) |

Còn lại (không chặn): góp ý P3-1…P3-4 của R1 giữ nguyên. Người dùng: chạy `detect_changes()` rồi commit. Sau đó làm 6-A2.

### R1 — 2026-11-04 — **CHƯA ĐẠT**

**Chưa đạt ở 2 chỗ** (còn lại đều đạt, xem bảng dưới):

| # | Chưa đạt ở đâu | Sai gì | Yêu cầu nào bị vi phạm |
|---|---|---|---|
| R1-1 | `customer_price_rule_repository.dart:138` (`create`); `sales_pricing_repository.dart:41`, `:50` (`preview`), `:91` (`evaluateManualPrice`) | Gửi `p_currency_code` nguyên chuỗi nhận vào, và `preview` so tiền tệ server trả với chuỗi chưa chuẩn hoá. Bản cũ gửi `trim().toUpperCase()`. Đầu vào `'vnd'` / `' VND '`: cũ chạy bình thường, mới gửi sai mã tiền tệ (create, evaluate) hoặc báo `SYSTEM_ERROR` (preview) | Ràng buộc chung "chép nguyên văn, không tự đổi hành vi"; D1 (tham số RPC giống hệt mapper cũ) |
| R1-2 | `pricing_errors.dart:33` (`pricingException`) + mục 8 của plan | Lỗi không có JSON được đổi mã khác bản cũ: `permission denied…` / `42501` / `PERMISSION_DENIED` ⇒ `NO_PERMISSION`, `RESOURCE_NOT_FOUND` ⇒ `NOT_FOUND`. `mapPricingRpcError` cũ trả `SYSTEM_ERROR` cho cả 3. Kết quả không ghi lệch này, và mục 8 ghi ngược lại ("bản mới cũng `SYSTEM_ERROR`"). Test `pricing_errors_test.dart` không có ca nào cho các lỗi này | Q7 ("giữ đúng cách `mapPricingRpcError`"); ràng buộc chung "thấy chỗ phải đổi ⇒ ghi vào Kết quả" |

Không có lỗi nào làm hỏng app đang chạy: 6-A1 chỉ thêm tệp mới, chưa nơi nào gọi tới. Vì vậy 2 chỗ này phải sửa trước 6-A2, lúc UI chuyển sang dùng repository.

**Phần đạt:**

| Hạng mục | Kết quả |
|---|---|
| Task 0–5 | ✅ đủ tệp, đủ test như Kết quả ghi |
| Task 6 (kiểm toàn bộ) | ✅ Kết quả ghi đủ 6.1–6.5; review chạy lại 6.1–6.4, số khớp |
| `dart analyze` 4 thư mục mới | ✅ 0 issues (review chạy lại) |
| `flutter test test/features/pricing/data test/features/pricing/logic` | ✅ 165 đạt (87 `data/` + 78 `logic/`, khớp Kết quả) |
| `flutter test test/features/pricing/` | ✅ 239 đạt / 11 lỗi, cả 11 có trong `TEST-BASELINE.md` |
| `flutter test` cả app | ✅ 59 lỗi = mốc sau 5-C (`TEST-BASELINE.md:13`: 57 trong danh sách + 2 test catalog ghi ở đoạn mốc). Không tệp nào ngoài `features/pricing` import tệp mới (xem P3-4) |
| `check_feature_imports` | ✅ (chấp nhận) 2 dòng `R1` mới: `customer_price_rule_repository.dart:5`, `sales_pricing_repository.dart:5` (`data/` import `logic/pricing_rules.dart`). Cùng mẫu với catalog (7 dòng) và partner (1 dòng) đã chấp nhận ở Theme 2/3 ⇒ đúng quy ước; Kết quả đã ghi. Kỳ vọng "không dòng mới" của plan 6.2 viết sai |
| `vet45_pricing` trong `data/`, `logic/` | ✅ rỗng |
| So với mapper cũ | Đã so tham số 11 RPC, các kiểm `FormatException` (bỏ đúng phần update / create context của Q5), chặn lộ giá sàn ở lịch sử, `floor_price_hidden`: ✅ trừ R1-1, R1-2 (bảng trên) và P3-1 (chấp nhận) |

### R1 — việc cần sửa

- **R1-1 — Mã tiền tệ: chuẩn hoá chữ hoa như bản cũ.** Bản cũ gửi `trim().toUpperCase()`: `create` qua `Money(...)` trong `CreateCustomerPriceRuleCommandHandler` (`p_currency_code` = `candidate.price.currencyCode`), `preview` / `evaluateManualPrice` qua hàm dựng `PreviewSalesWorkingStatePricingQuery` / `EvaluateSalesManualPriceQuery`. Bản mới gửi nguyên chuỗi (plan 4.5 ghi "không upper" là **sai**), và `preview` so `expectedCurrencyCode` với chuỗi chưa chuẩn hoá ⇒ đầu vào `'vnd'` bị `SYSTEM_ERROR` thay vì chạy. Hiện app chỉ truyền `'VND'` nên chưa lộ, nhưng phải giữ đúng hành vi.
  - Sửa: `customer_price_rule_repository.dart:138`, `sales_pricing_repository.dart:41`, `:50`, `:91` dùng `currencyCode.trim().toUpperCase()`.
  - Test: thêm parity `params_create_customer_price_rule_lowercase_currency`, `params_preview_…_lowercase_currency`, `params_evaluate_…_lowercase_currency` (đầu vào `' vnd '`, nhóm `old` và `new` cùng mong đợi `'VND'`), và repository test `preview_accepts_lowercase_currency` (RPC trả `currency_code: 'VND'` → trả DTO).
- **R1-2 — Lỗi không phải JSON: ghi lệch Q7 và khoá bằng test.** `pricingException` đi qua `AppException.from`, nên các lỗi sau giờ ra mã ổn định, còn `mapPricingRpcError` cũ ra `SYSTEM_ERROR`:
  - `PostgrestException` có `permission denied` hoặc `42501` ⇒ `NO_PERMISSION`. RPC `preview_sales_working_state_pricing` / `evaluate_sales_manual_price` ném đúng câu `permission denied: pricing.sales.…`.
  - Mã `PERMISSION_DENIED` ⇒ `NO_PERMISSION`, `RESOURCE_NOT_FOUND` ⇒ `NOT_FOUND` (`_normalize`).
  - Mục 8 đang ghi "`permission denied` thường: … bản mới cũng `SYSTEM_ERROR`" — **sai**.
  - **Người dùng chốt 2026-11-04: giữ hành vi mới, không sửa code** (câu "Bạn không có quyền…" đúng hơn câu lỗi chung; TH-04 7.2 mọi thành viên có quyền nên thực tế không gặp). Việc: sửa câu ở mục 8 và ghi chú vào Q7; thêm 2 dòng vào bảng `pricing_errors_test.dart` nhóm `new`: `PostgrestException(message: 'permission denied: pricing.sales.preview')` → `NO_PERMISSION`, `PostgrestException(message: 'not authenticated')` → `SYSTEM_ERROR`. Thêm cả `PostgrestException(message: 'PERMISSION_DENIED: x')` → `NO_PERMISSION`, `PostgrestException(message: 'RESOURCE_NOT_FOUND: x')` → `NOT_FOUND`.

### Góp ý P3 (không chặn)

1. `_money` của `detail` / `search` / `reenable` cũ **chặt** (`amount is! int` ⇒ `FormatException`), chỉ `createResultFromJson` nhận `1200.0`. Bản mới nhận `1200.0` ở mọi chỗ. Review Focus 3 của plan viết sai tiền đề; Kết quả đã ghi lệch này. Nới hơn, vô hại ⇒ chấp nhận.
2. Envelope có `message` không phải chuỗi hoặc `details` không phải map: cũ ⇒ `SYSTEM_ERROR`, mới giữ mã (details `null`). Server không trả kiểu này ⇒ chấp nhận.
3. `PricingErrorCodes` có 11 hằng (plan 4.2 ghi 12 — lỗi chép của plan, Kết quả đã ghi).
4. `TEST-BASELINE.md`: danh sách `apps/erp` mới có 57 tên, còn 2 test catalog lỗi (`product_change_history_e2e_test` `e2e_e07_u04_fr02_01`, `product_guided_create_e2e_test` `e2e_e02_u01_fr01_01`) chỉ ghi ở đoạn mốc dòng 13. Lượt cập nhật baseline sau nên thêm 2 tên này vào danh sách để so tự động được.
