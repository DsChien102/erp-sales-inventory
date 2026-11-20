# 5-A2 — Lớp dữ liệu catalog: `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc, phần **dữ liệu** · Gồm việc 5.2, 5.3, 5.4 (phần data) (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01; rà lại theo code 2026-11-02: `includeInactiveValues`, giữ kiểm rỗng, `capturedAt`, khoá giá sàn vắng ở `customConfig`, rule single select khi sửa, trùng cặp snapshot, mã `FLOOR_GREATER_THAN_LIST`; rà lần 2 theo code **sau khi 5-A1 xong** 2026-11-03: Q8 kiểm id, bỏ chép trùng `ProductPriceBandStatus`, tham số thật của lệnh trường bổ sung / khung giá, `productUnitId` null, khoá vắng của giá trị trường, rule quy tắc giá cửa hàng) | Làm ✅ 2026-11-03 | Review ✅ R3 2026-11-03
> Làm **sau** [5-A1](5-A1-catalog-data-san-pham.md) (✅ Làm + Review R2 2026-11-03, commit `4d35ec33e`): dùng lại `catalog_errors.dart`, `catalog_error_messages.dart`, `catalog_rules.dart`, `catalog_enums.dart`, cách viết `_guard` (`product_repository.dart:43`, chỉ bắt `on AppException`) và lớp ghi lời gọi `_RecordingRpc` của `test/features/catalog/data/product_rpc_parity_test.dart` (ném lỗi qua `AppException.from(...)` như `SupabaseRpc`).
> Tài liệu: [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) mục 6.2, 6.4, 9.1. Quyết định chung (chia theo lớp, bỏ đọc trước / sau, bỏ kiểm quyền client, chép hết kiểu): mục 2 của 5-A1.

## 1. Mục tiêu

Thêm 3 repository còn lại của catalog, **chưa** đổi UI (5-A3 nối):

- `MeasurementUnitRepository`: đơn vị tính của tổ chức và của sản phẩm (SP-09).
- `CustomFieldRepository`: cấu hình nhóm / trường bổ sung (SP-14…17) và giá trị trường của một sản phẩm (SP-08).
- `ProductPriceRepository`: giá cơ sở (SP-11), khung giá theo đơn vị (SP-12, SP-13), khung giá cửa hàng + lịch sử (SP-18…20), snapshot khung giá cho Pricing.

Kèm model, rule đầu vào và test parity `old` / `new` như 5-A1.

## 2. Quyết định

Theo 5-A1 mục 2 (Q1–Q5, Q11). Riêng 5-A2:

| # | Câu hỏi | Chốt |
|---|---|---|
| Q6 | Cảnh báo "giá thấp hơn giá cơ sở" của SP-13 (`PriceBandWarningCalculator`, cần đọc PCC + danh sách đơn vị trước lệnh) và sheet "Xác nhận cảnh báo giá" | **Người dùng chốt 2026-11-01: bỏ luôn ở 5-A** (kéo phần sheet của TH-02 KI-16 lên). 5-A2 **không** chép bộ tính, `setUnitPriceBand` không có tham số `confirmAcknowledgeWarnings`. 5-A3 xoá sheet + nhánh bắt lỗi |
| Q7 | Khung giá `customConfig`: handler cũ đọc giá cơ sở + tỷ lệ quy đổi rồi tự tính số tiền gửi lên | **Không tính ở client.** Server `set_product_unit_price_band` tự tính từ `p_list_markup_ratio` / `p_floor_markup_ratio` và giá cơ sở (`20260722001` nhánh `when 'customConfig'`, bỏ qua số tiền client gửi). Repository cho `customConfig`: `listBeforeVat` / `listAfterVat` / `floorBeforeVat` / `floorAfterVat` = `null` ⇒ theo mapper, khoá `p_list_price_before_vat`, `p_list_price_after_vat` **có mặt** với giá trị `null` (hàm không có `default` cho 2 tham số này, phải gửi), khoá `p_floor_price_before_vat`, `p_floor_price_after_vat` **vắng** (mapper bỏ khoá khi `null`; hàm có `default null`). Hệ quả của Q2 (5-A1). Đã kiểm chữ ký ở `20260722001` |
| Q8 | Kiểm id rỗng ở client | **Người dùng chốt 2026-11-03: theo 5-A1.** **Bỏ** vế id truyền thẳng vào method: `productId`, `productUnitId` (deactivate / reactivate / delete đơn vị, khung giá), `fieldId` của `configureAttributes`, `groupId` của `upsertField` / `reorderFields`. **Giữ** vế id nằm trong dữ liệu nhập: `unitId` của `ExistingTenantUnit`, từng id trong danh sách sắp xếp, `fieldId` trong `values`, `productId` / `productUnitId` của từng mục snapshot. Id sai: server báo lỗi |
| Q9 | `setUnitPriceBand` khi `productUnitId == null` (`edit_product_unit_price_band_cubit.dart:18` có kiểu `String?`) | Handler cũ đọc `list_product_units` rồi gửi id của đơn vị cơ sở. Mới: gửi `p_product_unit_id: null`; server tự lấy đơn vị cơ sở (`catalog._resolve_base_product_unit_id`, `20260722001:249`). Hệ quả của Q2. Đổi có chủ đích (H5) |

## 3. Hiện trạng (đo 2026-11-01)

### 3.1 Ai đang gọi

| Nơi | Gọi gì |
|---|---|
| `features/catalog/presentation/bloc/product_measurement_units_cubit.dart` | `ListTenantMeasurementUnitsQuery(keyword, limit: 50)`, `ListProductUnitsQuery(includeInactive: true)`, `SetProductBaseUnitCommand`, `Add/Deactivate/Reactivate/DeleteProductConversionUnitCommand` |
| `…/bloc/product_guided_create_cubit.dart` | `ListCustomFieldConfigQuery`, `ListTenantMeasurementUnitsQuery(limit: 50)`, `GetStorePriceRuleQuery` |
| `…/bloc/custom_field_config_cubit.dart` | `ListCustomFieldConfigQuery`, `InitializeCustomFieldTemplateCommand`, `UpsertCustomFieldGroupCommand`, `ReorderCustomFieldGroupsCommand`, `UpsertCustomFieldCommand` (dùng `result.fieldId`), `ConfigureCustomFieldAttributesCommand`, `ReorderCustomFieldsCommand` |
| `…/bloc/product_custom_field_group_edit_cubit.dart` | `GetProductCustomFieldValuesQuery`, `UpsertCustomFieldValuesCommand` |
| `…/bloc/product_manual_base_price_cubit.dart` | `SetManualBasePriceCommand` |
| `…/bloc/product_price_bands_cubit.dart` | `ListProductUnitPriceBandsQuery` |
| `…/bloc/edit_product_unit_price_band_cubit.dart` | `SuggestProductUnitPriceQuery`, `ApplyStorePriceRuleCommand`, `SetProductUnitPriceBandCommand` (`customConfig` / `manual`) |
| `…/bloc/store_price_rule_settings_cubit.dart` | `GetStorePriceRuleQuery`, `SetStorePriceRuleCommand` (dùng `result.rule`) |
| `…/bloc/store_price_rule_change_history_cubit.dart` | `GetStorePriceRuleChangeHistoryQuery` |
| `features/pricing/presentation/pages/pricing_pick_unit_page.dart:55,65` | `ListProductUnitsQuery`, `GetProductPriceBandSnapshotQuery` |

### 3.2 RPC → tham số → kết quả

Cách đọc bảng như 5-A1 mục 3.2. `infra/` = `modules/catalog/infrastructure/lib/src/domain/`.

Cột "Gọi": **call** = `_rpc.call('catalog', …)` thay cho `callMap` / `callScalar` cũ. `callMap` cũ đổi `null` thành `{}`, nên mọi chỗ "map rỗng" dưới đây hiểu là **`null` hoặc map rỗng**. Kết quả khác `Map` thì đọc như 5-A1 (`result is Map<String, dynamic> ? result : Map<String, dynamic>.from(result as Map)`). **rows** = `_rpc.rows('catalog', …)` thay cho `callList`. Map tham số viết thẳng trong repository như 5-A1 (`product_repository.dart`), không gọi mapper cũ. Cột "Tham số" chỉ nơi chép khoá.

**`MeasurementUnitRepository`** (`features/catalog/data/measurement_unit_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `listTenantUnits({keyword, limit = 50})` | `list_tenant_measurement_units` | rows | `ProductRpcMapper.listTenantUnitsParams` | thân `SupabaseCatalogUnitGateway.listTenantUnits` | `List<TenantMeasurementUnitDto>` |
| `listProductUnits(productId, {includeInactive = false})` | `list_product_units` | rows | `ProductRpcMapper.listProductUnitsParams` | `ProductRpcMapper.productUnitsDtoFromRows` (+ `productUnitDtoFromRow`) như `listProductUnits` của gateway | `ProductUnitsDto` |
| `setBaseUnit(productId, BaseUnitSelection selection)` | `set_product_base_unit` | call | `ProductRpcMapper.setProductBaseUnitParams` | map rỗng (hoặc `null`) → `AppException(unknown, serverMessage: 'Set base unit did not return a result.')`; không đọc thêm (cubit tự tải lại) | `void` |
| `addConversionUnit({productId, unitName, conversionRateToBase})` | `add_product_conversion_unit` | call | `addConversionUnitParams` (`unitName` gửi **nguyên**, không `trim`: mapper cũ gửi `command.unitName`) | không đọc (cũ: `productUnitMutationResultFromRow`, không còn kiểu trả) | `void` |
| `deactivateConversionUnit({productId, productUnitId})` | `deactivate_product_conversion_unit` | call | `deactivateConversionUnitParams` | không đọc (như trên) | `void` |
| `reactivateConversionUnit({productId, productUnitId})` | `reactivate_product_conversion_unit` | call | `reactivateConversionUnitParams` | không đọc (như trên) | `void` |
| `deleteConversionUnit({productId, productUnitId})` | `delete_product_conversion_unit` | rows | `deleteConversionUnitParams` | không đọc | `void` |

"không đọc" ở cột "Kết quả" (cả 3 bảng) = không dựng DTO; mọi bước kiểm rỗng của gateway cũ đều đã ghi ngay trong ô và phải giữ.

Tham số ngoài app truyền (vd. `p_actor_id`, `p_expected_version` nếu mapper có) lấy đúng như mapper cũ dựng từ command: đọc thân từng hàm `…Params` và chép mọi khoá. Field của command mà app không truyền (giá trị mặc định của command) → dùng **cùng** mặc định.

**`CustomFieldRepository`** (`features/catalog/data/custom_field_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `listConfig()` | `list_custom_field_config` | call | `CustomFieldRpcMapper.listConfigParams` | `configViewFromJson` (+ `groupFromJson`, `fieldFromJson`, `optionFromJson`, `statusFromRpc`, `fieldTypeFromRpc`) | `CustomFieldConfigViewDto` |
| `initializeTemplate({String? templateId})` | `initialize_custom_field_template` | call | `initializeTemplateParams` (`p_template_id` **có mặt**, `null` khi không truyền; app không truyền) | không đọc | `void` |
| `upsertGroup({String? groupId, required String name, String? iconKey, bool isActive = true})` | `upsert_custom_field_group` | call | `upsertGroupParams` (`p_group_id`, `p_name`, `p_icon_key`, `p_is_active`) | map rỗng → `AppException(unknown, serverMessage: 'Upsert custom field group did not return a result.')`; không đọc thêm (cũ `groupFromJson`, cubit không dùng) | `void` |
| `reorderGroups(List<String> orderedGroupIds)` | `reorder_custom_field_groups` | call | `reorderGroupsParams` | — | `void` |
| `upsertField({required String groupId, String? fieldId, required String name, required CustomFieldType fieldType, List<CustomFieldSelectOptionDto> options = const [], bool isActive = true})` | `upsert_custom_field` | call | `upsertFieldParams` (`p_field_type: fieldType.name`; mảng `p_options` chép đủ `option_id`, `label`, `sort_order`, `is_active`; `p_is_active`) | map rỗng → `AppException(unknown, serverMessage: 'Upsert custom field did not return a result.')`; còn lại `fieldFromJson` | `CustomFieldDefinitionDto` (cubit dùng `fieldId`) |
| `configureAttributes({required String fieldId, required bool isRequired, required bool isSearchable, required bool isFilterable, required bool displayOnList})` | `configure_custom_field_attributes` | call | `configureAttributesParams` | không đọc | `void` |
| `reorderFields({groupId, orderedFieldIds})` | `reorder_custom_fields` | call | `reorderFieldsParams` | — | `void` |
| `getProductValues(productId, {includeInactiveValues = false})` | `get_product_custom_field_values` | call | `getProductCustomFieldValuesParams` (gồm `p_include_inactive_values`; `product_custom_field_group_edit_cubit.dart:26` truyền `true`) | map rỗng → `AppException(CatalogErrorCodes.productNotFound)` (gateway cũ: `ApplicationException('Product not found')`); còn lại `productCustomFieldValuesFromJson` (+ `productCustomFieldValueGroupFromJson` có gọi `customFieldGroupDisplayName` (đã có ở 5-A1, `custom_field_filter_option.dart:5`), `productCustomFieldValueFieldFromJson`, `optionFromJson`, `_toDate`, `_toDouble`; giữ `whereType<Map<String, dynamic>>()` như cũ). **Không** dùng `readinessSummaryFromJson` (chỉ kết quả upsert cũ dùng) | `ProductCustomFieldValuesDto` |
| `upsertProductValues({required String productId, required List<ProductCustomFieldValueInput> values})` | `upsert_product_custom_field_values` | call | `upsertProductCustomFieldValuesParams` + `productCustomFieldValueInputToJson`: mỗi mục chỉ có `field_id` và các khoá **khác null** (khoá `null` **vắng**), `date_value` = `_dateOnly` (`toUtc()` rồi `yyyy-MM-dd`). **Khác** `p_custom_field_values` của `createGuided` 5-A1 (đủ khoá, `toIso8601String()`): **không** dùng chung hàm | map rỗng → `AppException(unknown, serverMessage: 'Upsert product custom field values did not return a result.')`; không đọc thêm | `void` |

Tham số của mọi method: đúng các field của command tương ứng **trừ** `tenantId` / `actorId` (cùng tên, cùng kiểu, cùng mặc định). Đọc command gốc ở `modules/catalog/application/lib/src/custom_field/commands/**`, `product_custom_field_value/**`.

**`ProductPriceRepository`** (`features/catalog/data/product_price_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `setManualBasePrice({productId, basePrice, currency = 'VND'})` | `set_manual_base_price` | call | `ProductRpcMapper.setManualBasePriceParams`: `p_mode: 'manual'`, `p_base_price_after_vat: basePrice`, `p_currency` | không đọc | `void` |
| `listUnitPriceBands(productId)` | `list_product_unit_price_bands` | rows | `ProductPriceBandRpcMapper.listProductUnitPriceBandsParams` | rỗng → `AppException(unknown, serverMessage: 'Product unit price bands did not return a result.')`; còn lại `bandsFromRows` (+ `rowFromListRpc`, `_basePricePerBaseUnitFromRows`, `_readOptional*`, `sourceTypeFromRpc`) | `ProductUnitPriceBandsDto` |
| `getPriceBandSnapshot(List<ProductPriceBandSnapshotRequest> items)` | `get_product_price_band_snapshot` | call | `getPriceBandSnapshotParams` | `snapshotFromJson` (+ `snapshotItemFromJson`, `_productStatusFromRpc`), rồi như `GetProductPriceBandSnapshotQueryHandler`: dựng lại mọi mục (chép mọi field, kể cả `effectiveFrom`, `effectiveTo`, `status` mà mapper để `null`) với **`capturedAt = DateTime.now().toUtc()`** lấy **sau** RPC (một giá trị chung cho cả lần gọi; mapper đặt `DateTime.utc(1970)`). Có thể đặt `capturedAt` thành tham số của `fromJson` thay vì dựng lại | `ProductPriceBandSnapshotDto` |
| `setUnitPriceBand({required String productId, String? productUnitId, PriceBandSourceType sourceType = PriceBandSourceType.manual, int? listBeforeVat, int? listAfterVat, int? floorBeforeVat, int? floorAfterVat, double? listMarkupRatio, double? floorMarkupRatio, DateTime? effectiveFrom, DateTime? effectiveTo, ProductPriceBandStatus? status})`. **Không** có `storePriceRuleId` (app không truyền; `ruleBased` đi qua `applyStorePriceRule`) | `set_product_unit_price_band` | rows | `ProductPriceBandRpcMapper.setProductUnitPriceBandParams` (chép đúng khoá nào dùng `?`: chỉ `p_floor_price_before_vat`, `p_floor_price_after_vat`, `p_effective_from` / `p_effective_to` (`toUtc().toIso8601String()`), `p_status` (`toWire()`); vắng `p_status` ⇒ server `default 'active'`). `p_store_price_rule_id: null` luôn có mặt. `p_product_unit_id: productUnitId` (có thể `null`, Q9). `p_source_type`: `sourceTypeToRpc` (`'customConfig'` / `'manual'`). **`customConfig`:** 4 tham số giá = `null` ⇒ 2 khoá niêm yết `null`, 2 khoá sàn vắng (Q7). **`manual`:** truyền thẳng giá trị nhập | không đọc | `void` |
| `suggestUnitPrice({required String productId, String? productUnitId})` | `suggest_product_unit_price` | rows | `StorePriceRuleRpcMapper.suggestProductUnitPriceParams` (`p_product_unit_id` có mặt, có thể `null`) | rỗng → `AppException(unknown, serverMessage: 'Suggest product unit price did not return a result.')`; còn lại `suggestionFromRow` | `ProductUnitPriceSuggestionDto` |
| `applyStorePriceRule({required String productId, String? productUnitId, String? storePriceRuleId, int? basePriceVersion, bool confirmOverwrite = false})` | `apply_store_price_rule` | rows | `applyStorePriceRuleParams` (6 khoá, đều có mặt) | rỗng → `AppException(unknown, serverMessage: 'Apply store price rule did not return a result.')`; không đọc thêm (cũ `appliedFromRow`, ném lỗi ép kiểu khi thiếu giá: bỏ cùng kiểu trả) | `void` |
| `getStorePriceRule()` | `get_store_price_rule` | rows | `getStorePriceRuleParams` | rỗng → `null`; còn lại `ruleFromRow(rows.first)` (trả `null` khi thiếu `id`: giữ `null`) | `StorePriceRuleDto?` |
| `setStorePriceRule({required String name, required double listMarkupRatio, required double floorMarkupRatio, StorePriceRuleStatus status = StorePriceRuleStatus.active})` | `set_store_price_rule` | rows | `setStorePriceRuleParams` (+ `_statusToRpc`; `name` gửi nguyên, không `trim`) | rỗng → `AppException(unknown, serverMessage: 'Set store price rule did not return a result.')`; `ruleFromRow(rows.first)` trả `null` → `AppException(unknown, serverMessage: 'Set store price rule returned invalid data.')` (`supabase_store_price_rule_gateway.dart:55–60`); còn lại DTO đó | `StorePriceRuleDto` |
| `getStorePriceRuleHistory({int limit = 50, int offset = 0})` | `get_store_price_rule_change_history` | call | `StorePriceRuleChangeHistoryRpcMapper.params` | `resultFromJson` (+ `entryFromJson`, `_asDouble`) | `StorePriceRuleChangeHistoryResultDto` |

### 3.3 Việc client module cũ làm quanh các RPC trên

| Handler cũ | Làm thêm trước / sau RPC | Sau 5-A2 |
|---|---|---|
| `Add/Deactivate/Reactivate/DeleteProductConversionUnitCommandHandler` | gọi `list_product_units(includeInactive: true)` rồi chạy `ProductUnitSet` (trùng tên, đơn vị cơ sở, tỷ lệ) | **Bỏ đọc trước** (Q2). Server trả `duplicate product unit "<x>"`, `validation_exception: Base unit cannot be … here.`, `Conversion rate must be greater than zero.`, `product unit not found` (`20260709005`, `20260710004`, `20260709023`). Giữ rule đầu vào (4.2) |
| `SetManualBasePriceCommandHandler` | `mode != 'manual'` → lỗi; đọc readiness (`get_product_readiness`), thiếu đơn vị cơ sở → `MissingBaseUnitException`; chạy `ProductBasePriceProfile.setManual`; sau RPC đọc lại readiness + `list_product_units` để dựng kết quả | **Bỏ đọc trước / sau.** Server: `catalog._ensure_product_has_base_unit` → `missing base unit`; `not_manual_base_price_mode`; `base price cannot be negative` (`20260717008`). `mode` luôn `'manual'` |
| `SetProductUnitPriceBandCommandHandler` | đọc readiness (thiếu đơn vị cơ sở), `list_product_units` (tìm đơn vị; `productUnitId == null` ⇒ lấy đơn vị cơ sở; `inactive_product_unit`), PCC (giá cơ sở), `customConfig`: tỷ lệ quy đổi ≤ 0 → "Product unit conversion rate is invalid." rồi tính số tiền; `manual`: niêm yết null → "Manual list prices are required." (không tới được: validator đã ném "Giá niêm yết là bắt buộc."); chạy `PriceBandWarningCalculator` → `PriceBandWarningsRequireAcknowledgmentException`; sau RPC đọc readiness | **Bỏ hết** (Q2, Q6, Q7, Q9). Server: `missing base unit`, `product unit not found`, `inactive_product_unit`, `validation_exception: …` (`20260722001`). Giữ rule đầu vào của validator (4.2) |
| `ApplyStorePriceRuleCommandHandler` | `get_store_price_rule` (không có → `Store price rule not found`), PCC (thiếu giá cơ sở → `MissingBasePriceException`), dựng `StorePriceRule` + `ProductUnitPriceBand.set` để kiểm; sau RPC đọc readiness | **Bỏ hết.** Server: `store_price_rule_not_found`, `store_price_rule_inactive`, `missing_base_price`, `stale_base_price`, `price_band_overwrite_required` (`20260717007`) |
| `SetStorePriceRuleCommandHandler` | `StorePriceRule.create` (tên, tỷ lệ ≥ 0, `PriceBandMarkupConfig`: tỷ lệ sàn ≤ tỷ lệ niêm yết) | **Giữ** phần tới được (chỉ cần dữ liệu nhập): gộp vào `checkStorePriceRule` (4.2) |
| `UpsertCustomFieldCommandHandler`, `UpsertCustomFieldGroupCommandHandler` | `CustomField.create` / `CustomFieldGroup.create` (tên, single select) | Giữ phần tới được: `checkUpsertCustomField` (4.2); `CustomFieldGroup.create` chỉ kiểm tên, trùng validator |
| Validator các command / query (pipeline chạy, kể cả lệnh mà handler không tự gọi như `SetProductBaseUnitCommandValidator`: đăng ký ở `catalog_cqrs_registrar.g.dart`) | | giữ theo Q8; bỏ vế tenant và `limit` / `offset` (`ListTenantMeasurementUnitsQueryValidator`: `limit` 1…100; `GetStorePriceRuleChangeHistoryQueryValidator`: `limit` 1…100, `offset` ≥ 0; app luôn truyền 50 / số mục đã tải) |

## 4. Thiết kế

### 4.1 Model (`features/catalog/data/models/`)

Cùng quy tắc chép của 5-A1 mục 4.1. Thêm:

| Tệp mới | Chứa |
|---|---|
| `measurement_unit.dart` | `TenantMeasurementUnitDto`, `ProductUnitDto`, `ProductUnitsDto` (`application/product_unit/**`) |
| `custom_field_config.dart` | `CustomFieldConfigViewDto`, `CustomFieldGroupConfigDto`, `CustomFieldDefinitionDto` (`application/custom_field/shared/**`), `CustomFieldType`, `CustomFieldConfigStatus` (`domain/custom_fields/custom_field_type.dart`, `custom_field_config_status.dart`). **Dùng lại** của 5-A1, không chép lần hai: `CustomFieldSelectOptionDto`, `customFieldGroupDisplayName` (`custom_field_filter_option.dart`). `CustomFieldListValueDto.fieldType` của 5-A1 vẫn là `String` (`product_list_item_tile.dart:67` so với `CustomFieldType.number.name`): không đổi ở 5-A2 |
| `product_custom_field_values.dart` | `ProductCustomFieldValuesDto`, `ProductCustomFieldValueGroupDto`, `ProductCustomFieldValueFieldDto` (`application/product_custom_field_value/queries/get_product_custom_field_values/**`; `fieldType` là `String`). `ProductCustomFieldValueInput` đã có ở 5-A1 (`product_inputs.dart:62`) |
| `price_band.dart` | `ProductUnitPriceBandsDto`, `ProductUnitPriceBandRowDto`, `ProductPriceBandSnapshotDto`, `ProductPriceBandSnapshotItemDto`, `ProductPriceBandSnapshotRequest`, `ProductUnitPriceSuggestionDto`. **Dùng lại** của 5-A1 (`catalog_enums.dart`): `ProductPriceBandStatus` (`:65`, có `toWire` / `tryFromWire`), `PriceBandSourceType` (`:158`), `ProductBusinessStatus` |
| `store_price_rule.dart` | `StorePriceRuleDto`, `StorePriceRuleStatus`, `StorePriceCalculationType` (field `calculationType` của DTO, `ruleFromRow` đặt `markup`), `StorePriceRuleChangeHistoryResultDto`, `StorePriceRuleChangeHistoryEntryDto` |
| `../../logic/store_price_suggestion.dart` | `StorePriceSuggestionCalculator` (`application/product_unit_price_band/queries/suggest_product_unit_price/store_price_suggestion_calculator.dart`): app gọi thẳng `suggest` ở `catalog_ui_mapper.dart:32,51`, `guided_price_band_submission_resolver.dart:98`. Chép nguyên cả 3 hàm (`scaleBasePriceForUnit`, `suggest`, `basePriceVersionFor`) |

`ProductUnitDto`, `ProductUnitsDto`, `TenantMeasurementUnitDto`: 5-A1 **chưa** có (5-A1 chỉ có `ProductConversionUnitDto` của PCC, khác kiểu). `BaseUnitSelection` / `ExistingTenantUnit` / `NewTenantUnit` đã có (`product_inputs.dart:43`).

**Không** chép: `PriceBandWarningCalculator`, `PriceBandValidationWarningDto` (Q6); `SetProductBaseUnitResult`, `ProductUnitMutationResult`, `SetManualBasePriceResult`, `SetProductUnitPriceBandResult`, `ApplyStorePriceRuleResult`, `AppliedStorePriceRuleDto`, `InitializeCustomFieldTemplateResult`, `ConfigureCustomFieldAttributesResult`, `UpsertCustomFieldValuesResult`, `SetStorePriceRuleResult` (method trả `void` / DTO trực tiếp). 5-A3 đổi cubit theo.

### 4.2 Rule (thêm vào `features/catalog/logic/catalog_rules.dart`)

Cùng cách của 5-A1 mục 4.5: ném `AppException(AppErrorCode.validation, serverMessage: <câu cũ nguyên văn>)` (trừ ngoại lệ mã ghi ở `checkUnitPriceBand`), chạy **trước** RPC. Bỏ vế tenant / actor, `limit` / `offset`, và vế id theo **Q8** (id truyền thẳng vào method). `SetManualBasePriceCommandValidator` còn vế `mode != 'manual'` → `NotManualBasePriceModeException`: bỏ, vì repository luôn gửi `'manual'`. Câu dưới đây chép **nguyên văn** từ code (đã đối chiếu 2026-11-03).

Method **không** có rule (chỉ còn vế id / tenant / `limit` theo Q8): `listTenantUnits`, `listProductUnits`, `deactivateConversionUnit`, `reactivateConversionUnit`, `deleteConversionUnit`, `listConfig`, `initializeTemplate`, `configureAttributes`, `getProductValues`, `listUnitPriceBands`, `suggestUnitPrice`, `applyStorePriceRule`, `getStorePriceRule`, `getStorePriceRuleHistory`.

| Hàm | Chép từ (validator / domain) | Gọi ở |
|---|---|---|
| `checkBaseUnitSelection(BaseUnitSelection)` | `SetProductBaseUnitCommandValidator`: `ExistingTenantUnit` `unitId.trim()` rỗng → "Measurement unit id is required." (**khác** câu "Base unit id is required." của `checkCreateGuided`); `NewTenantUnit` `name.trim()` rỗng → "Unit name must not be empty."; dài > `maxUnitNameLength` (80) → "Unit name is too long." | `setBaseUnit` |
| `checkConversionUnit({unitName, conversionRateToBase})` | `AddProductConversionUnitCommandValidator`: `unitName.trim()` rỗng → "Unit name must not be empty."; > 80 → "Unit name is too long."; tỷ lệ ≤ 0 → "Conversion rate must be greater than zero.". Hằng `maxUnitNameLength = 80` dùng chung với `checkBaseUnitSelection` | `addConversionUnit` |
| `checkUpsertCustomFieldGroup(name)` | `UpsertCustomFieldGroupCommandValidator`: `name.trim()` rỗng → "Group name must not be empty.". `CustomFieldGroup.create` chỉ kiểm lại tên: bỏ | `upsertGroup` |
| `checkReorderGroups(ids)`, `checkReorderFields(ids)` | `ReorderCustomFieldGroupsCommandValidator`, `ReorderCustomFieldsCommandValidator`: danh sách rỗng → "Ordered group ids must include all groups." / "Ordered field ids must include all fields." (validator chỉ kiểm `isEmpty`, không đọc DB: chép); mỗi id `trim()` rỗng → "Group id must not be empty." / "Field id must not be empty.". Vế `groupId` rỗng ("Group id is required.") của `ReorderCustomFieldsCommandValidator`: bỏ (Q8) | `reorderGroups`, `reorderFields` |
| `checkUpsertCustomField({fieldId, name, fieldType, options})` | `UpsertCustomFieldCommandValidator` theo thứ tự (bỏ vế group id, Q8): `name.trim()` rỗng → "Field name must not be empty."; `singleSelect` + `options.isEmpty` + **`fieldId == null`** → "Single select field requires options."; **rồi** rule domain của handler `CustomField.create` → `SingleSelectMustHaveOptionsRule` (chạy **cả khi sửa**): `singleSelect` mà không có lựa chọn nào `label.trim()` khác rỗng → "Trường single select phải có ít nhất một option hợp lệ.". Vế tên rỗng của domain trùng validator: bỏ | `upsertField` |
| `checkUpsertProductValues(values)` | `UpsertCustomFieldValuesCommandValidator`, mỗi mục theo thứ tự: `fieldId.trim()` rỗng → "Field id is required."; trùng `fieldId` → "Duplicate custom field value."; > 1 giá trị có kiểu → "Only one typed value is allowed per custom field.". Đếm giá trị: **dùng lại** `_typedValueCount` có sẵn trong `catalog_rules.dart:137` (cùng điều kiện). Câu **khác** phần giá trị trường của `checkCreateGuided`: không gộp | `upsertProductValues` |
| `checkManualBasePrice(basePrice)` | `SetManualBasePriceCommandValidator`: `< 0` → "Giá vốn cơ sở không được âm." (câu cũ; 5-B đổi chữ theo KI-14). `ProductBasePriceProfile.setManual` / `BasePrice` không kiểm thêm | `setManualBasePrice` |
| `checkUnitPriceBand({sourceType, listBeforeVat, listAfterVat, floorBeforeVat, floorAfterVat, listMarkupRatio, floorMarkupRatio})` | `SetProductUnitPriceBandCommandValidator` theo `sourceType`. **ruleBased** → "Vui lòng dùng lệnh áp dụng khung giá cửa hàng.". **customConfig:** có số tiền nào khác null → "Cấu hình riêng chỉ nhận tỷ lệ phần trăm."; `listMarkupRatio == null` → "Tỷ lệ giá niêm yết là bắt buộc."; `< 0` → "Tỷ lệ không được âm."; sàn khác null: `< 0` → "Tỷ lệ không được âm.", `> niêm yết` → "Tỷ lệ giá sàn không được lớn hơn tỷ lệ giá niêm yết.". **manual:** có tỷ lệ nào khác null → "Giá thủ công không được có nguồn công thức."; niêm yết trước / sau VAT null → "Giá niêm yết là bắt buộc."; `< 0` → "Giá không được âm."; mỗi giá sàn khác null: `< 0` → "Giá không được âm.", `>` niêm yết cùng loại VAT → ngoại lệ mã (dưới). Vế `storePriceRuleId != null` của cả hai nhánh: **bỏ** (repository không nhận tham số này, mục 3.2). "Manual list prices are required." của handler: **bỏ** (không tới được). **Ngoại lệ mã:** 2 vế sàn > niêm yết của nhánh `manual` ném `FloorPriceGreaterThanListPriceException` (không phải `ValidationException`) ⇒ ném `AppException(CatalogErrorCodes.floorGreaterThanList)` (không `serverMessage`; 4.4 của 5-A1 ra "Giá sàn không được lớn hơn giá niêm yết."), **không** `VALIDATION_ERROR` | `setUnitPriceBand` |
| `checkStorePriceRule({name, listMarkupRatio, floorMarkupRatio})` | `SetStorePriceRuleCommandValidator` theo thứ tự: `name.trim()` rỗng → "Tên quy tắc giá là bắt buộc."; niêm yết `< 0` → "Tỷ lệ cộng thêm Giá niêm yết phải lớn hơn hoặc bằng 0."; sàn `< 0` → "Tỷ lệ cộng thêm Giá sàn phải lớn hơn hoặc bằng 0."; `SuggestedFloorNotGreaterThanListRule(basePrice: 100)`: `(100 × (1 + sàn)).roundToDouble() > (100 × (1 + niêm yết)).roundToDouble()` → "Giá sàn không được lớn hơn giá niêm yết.". **Rồi** vế duy nhất còn tới được của `StorePriceRule.create` (`PriceBandMarkupConfig` → `FloorMarkupRatioNotGreaterThanListMarkupRatioRule`): sàn > niêm yết (chưa làm tròn) → "Floor markup ratio must not be greater than list markup ratio." (tới được khi chênh nhỏ, vd. niêm yết 0.1, sàn 0.104: 110 = 110 nên validator qua). Các vế khác của `create` (tỷ lệ ≥ 0 nhãn tiếng Anh, tên rỗng sau `trim`) trùng validator: bỏ | `setStorePriceRule` |
| `checkPriceBandSnapshotRequest(items)` | `GetProductPriceBandSnapshotQueryValidator` (id nằm trong dữ liệu nhập: giữ theo Q8): rỗng → "At least one item is required."; > 100 → "At most 100 items can be read at once."; từng mục: `productId.trim()` rỗng → "Product id is required."; `productUnitId.trim()` rỗng → "Product unit id is required."; trùng cặp `productId:productUnitId` → "Duplicate product and unit pair is not allowed." | `getPriceBandSnapshot` |

### 4.3 Ba repository

Constructor: `rpc` (`SupabaseRpc`), `tenantId` (`Future<String> Function()`), như `ProductRepository` (5-A1). **Không** có `actorId`: không RPC nào của 25 RPC trên nhận `p_actor_id` (đã đọc mọi mapper). Không có `hasPermission` (Q3 của 5-A1). Mỗi method: rule (4.2) → `await _tenantId()` → **đúng 1 RPC** bọc `_guard` → `catalogException`. Có thể tách `_guard` ra hàm top-level `guardCatalog<T>(Future<T> Function())` trong `catalog_errors.dart` và sửa `ProductRepository` dùng chung (chạy impact `ProductRepository`, ghi vào Kết quả nếu làm).

## 5. Đang làm gì — test giữ hành vi

| # | Cơ chế cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| H1 | Tham số 25 RPC của mục 3.2 | 3 repository | `test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart`: nhóm `old` (mapper cũ; `setManualBasePriceParams` dựng `ProductBasePriceProfile` như handler cũ) và `new` (repository qua `_RecordingRpc` chép mẫu 5-A1) so với **cùng** map viết tay; mỗi RPC một ca, kiểm cả tên schema `catalog` và tên RPC. Ca riêng: `setBaseUnit` cả `ExistingTenantUnit` lẫn `NewTenantUnit`; `initializeTemplate()` có khoá `p_template_id: null`; `upsertField` `singleSelect` 2 lựa chọn; `upsertProductValues` đủ 5 kiểu giá trị (chữ, số, ngày, đúng/sai, lựa chọn) **và** một mục chỉ có `fieldId` (kiểm `containsKey` các khoá giá trị là `false`), ngày `DateTime.utc(2026, 11, 3, 23)` → `'2026-11-03'` (dùng giờ UTC để test không phụ thuộc múi giờ máy chạy); `setUnitPriceBand` `manual` có sàn, `manual` không sàn (khoá sàn vắng, `p_status` vắng) và **`customConfig`** (xem H5); `applyStorePriceRule` có `confirmOverwrite` và `storePriceRuleId: null`; `getPriceBandSnapshot` 2 mục; `getProductValues` với `includeInactiveValues: true` → `p_include_inactive_values: true` |
| H2 | Đọc kết quả (`configViewFromJson`, `productCustomFieldValuesFromJson`, `bandsFromRows`, `snapshotFromJson`, `ruleFromRow`, `suggestionFromRow`, `resultFromJson`, `productUnitsDtoFromRows`, `listTenantUnits`) | `fromJson` cạnh model | cùng tệp H1: JSON mẫu → DTO, so từng field. Gồm: `bandsFromRows` có / không `base_price_amount` ở dòng đầu; `ruleFromRow` dòng rỗng / trạng thái `inactive`; `fieldTypeFromRpc` giá trị lạ. Kiểm rỗng (chỉ nhóm `new`, so câu; RPC loại **call** thử cả kết quả `null` lẫn `{}`): `setBaseUnit`, `applyStorePriceRule`, `setStorePriceRule` (rỗng; thiếu `id` → "returned invalid data"), `getProductValues` (→ `PRODUCT_NOT_FOUND`), `listUnitPriceBands`, `suggestUnitPrice`, `upsertGroup`, `upsertField`, `upsertProductValues`. `getPriceBandSnapshot`: mọi mục có cùng `capturedAt`, nằm giữa hai mốc `DateTime.now().toUtc()` trước / sau lời gọi |
| H3 | Validator + rule domain trước RPC | `catalog_rules.dart` (4.2) | `test/features/catalog/logic/catalog_rules_test.dart` (tệp của 5-A1, thêm nhóm): mỗi `if` một ca sai + một ca đúng; nhóm `old` gọi validator / `StorePriceRule.create` / `CustomField.create` cũ, nhóm `new` gọi hàm mới, cùng câu. Ca riêng: sửa trường `singleSelect` (`fieldId` có) với 1 lựa chọn nhãn `'  '` → validator qua, `CustomField.create` ném câu tiếng Việt; snapshot trùng cặp; `manual` sàn > niêm yết: nhóm `old` kỳ vọng `FloorPriceGreaterThanListPriceException`, nhóm `new` kỳ vọng mã `FLOOR_GREATER_THAN_LIST`; quy tắc cửa hàng niêm yết 0.1 / sàn 0.104 → validator qua, `StorePriceRule.create` ném "Floor markup ratio must not be greater than list markup ratio.", nhóm `new` cùng câu. Vế id bỏ theo Q8 (vd. `productUnitId: ''` khi ngừng dùng đơn vị, `groupId: ''` khi sắp xếp trường): nhóm `new` kiểm **có** gọi RPC (không ném ở client), ghi là đổi có chủ đích |
| H4 | Handler đọc trước / sau (đơn vị, giá cơ sở, khung giá, áp khung cửa hàng) | **Đổi (Q2):** bỏ | repository test: `addConversionUnit`, `setManualBasePrice`, `setUnitPriceBand`, `applyStorePriceRule` mỗi cái gọi **đúng 1** RPC. `_RecordingRpc` ném lỗi `PostgrestException(message: 'missing base unit')` (qua `AppException.from`) khi `setManualBasePrice` → `AppException` code `MISSING_BASE_UNIT`; `'inactive_product_unit'` khi `setUnitPriceBand` → `INACTIVE_PRODUCT_UNIT` |
| H5 | `customConfig`: handler gửi số tiền tự tính; `productUnitId == null`: handler gửi id đơn vị cơ sở | **Đổi (Q7, Q9):** gửi `null` | parity H1 ca `customConfig`: map mong đợi của nhóm `old` có số tiền (gọi `setProductUnitPriceBandParams` với số tiền mà handler cũ tính: giá cơ sở mẫu × tỷ lệ quy đổi × (1 + tỷ lệ), viết tay trong test), của nhóm `new` có `p_list_price_before_vat: null`, `p_list_price_after_vat: null` và **không có** khoá `p_floor_price_before_vat`, `p_floor_price_after_vat` (kiểm bằng `containsKey` là `false`); mọi khoá khác **giống nhau**. Ca `productUnitId: null` (chỉ nhóm `new`): `p_product_unit_id` có mặt, giá trị `null`. Ghi rõ trong test đây là đổi có chủ đích |
| H6 | `PriceBandWarningCalculator` → `PriceBandWarningsRequireAcknowledgmentException` | **Đổi (Q6):** bỏ | không test ở 5-A2 (5-A3 kiểm màn) |

## 6. Các bước

Trước mỗi symbol sửa: `gitnexus impact` (upstream), ghi vào Kết quả. 5-A2 chỉ thêm tệp; nếu tách `_guard` dùng chung thì chạy impact cho `ProductRepository`.

### Bước 0: nhóm `old` của H1, H2, H3 trên code cũ. Chạy xanh, ghi tên test

### Bước 1: model (4.1)

### Bước 2: rule (4.2) + nhóm `new` H3

### Bước 3: 3 repository (4.3) + nhóm `new` H1, H2, H4, H5

### Bước 4: kiểm (mục 7), ghi Kết quả, `detect_changes()`

## 7. Kiểm tra

- [ ] `git diff --stat`: chỉ tệp mới dưới `features/catalog/{data,logic}/` + test; sửa `product_repository.dart` chỉ khi tách `_guard`.
- [ ] `git grep -n "package:c45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic` **rỗng**.
- [ ] Không có hai class cùng tên trong `features/catalog/data/models/` (`git grep -hoE "^(final |abstract |sealed )*(class|enum) \w+" -- apps/erp/lib/features/catalog/data/models | sort | uniq -d` rỗng).
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới.
- [ ] `cd apps/erp && flutter test test/features/catalog`: xanh; `flutter test`: không fail mới so với sau 5-A1.

## 8. Rủi ro / lưu ý

- `setProductUnitPriceBandParams` dùng cú pháp bỏ khoá khi `null` (`'p_floor_price_before_vat': ?floorBeforeVat`). Chép đúng: khoá **vắng** khác khoá `null` với PostgREST (vắng → dùng `default` của hàm).
- `ProductPriceBandStatus.toWire()` / `StorePriceRuleStatus`: giữ đúng chuỗi.
- `listProductUnits` của Pricing (`pricing_pick_unit_page`) gọi **không** có `includeInactive` (mặc định `false`) rồi tự lọc `isActive`. Giữ mặc định `false`.
- `_dateOnly` cũ đổi ngày sang UTC trước khi cắt `yyyy-MM-dd`: ngày chọn lúc 00:00 giờ máy (UTC+7) ra ngày hôm trước. Giữ nguyên ở 5-A2 (parity). **Người dùng chốt 2026-11-03:** là lỗi, ghi thành TH-02 KI-24, sửa ở 5-B (G9).
- Trong `catalog_rules.dart` có 3 câu gần giống nhau cho id đơn vị / giá trị trường (`checkCreateGuided` của 5-A1 so với `checkBaseUnitSelection`, `checkUpsertProductValues`): giữ **riêng** từng câu như code cũ, không gộp.
- `guided_price_band_submission_resolver.dart:19,22` còn nhắc `SetInitialPriceBandCommand` trong chú thích: 5-A3 sửa, 5-A2 không đụng.

## 9. Kết quả (phiên làm code ghi)

- **Bước 0 ✅:**
  - `apps/erp/test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart:269–855`: nhóm `old (mappers)` (37 tests) kiểm tra tham số 25 RPC qua mappers cũ (`ProductRpcMapper`, `CustomFieldRpcMapper`, `ProductPriceBandRpcMapper`, `StorePriceRuleRpcMapper`, `StorePriceRuleChangeHistoryRpcMapper`). (Dòng 28–268 là các map tham số RPC mong đợi `_expected*Params`).
  - `apps/erp/test/features/catalog/logic/catalog_rules_test.dart:19–1508`: các sub-group `old (CommandValidators)` (33 sub-tests) đối chiếu validator CQRS cũ và domain rule cũ (`StorePriceRule.create`, `CustomField.create`).
  - Cả hai nhóm test `old` đều chạy xanh trước khi bước sang Bước 1.

- **Bước 1 ✅:**
  - Chép 22 kiểu DTO/enum vào `apps/erp/lib/features/catalog/data/models/`:
    - `measurement_unit.dart` (3 kiểu): `TenantMeasurementUnitDto`, `ProductUnitDto`, `ProductUnitsDto`.
    - `custom_field_config.dart` (5 kiểu): `CustomFieldType`, `CustomFieldConfigStatus`, `CustomFieldConfigViewDto`, `CustomFieldGroupConfigDto`, `CustomFieldDefinitionDto` + mappers `fieldTypeFromRpc`, `statusFromRpc` (`:21,28`). Dùng lại `CustomFieldSelectOptionDto`, `customFieldGroupDisplayName` từ `custom_field_filter_option.dart` (5-A1).
    - `product_custom_field_values.dart` (3 kiểu): `ProductCustomFieldValuesDto`, `ProductCustomFieldValueGroupDto`, `ProductCustomFieldValueFieldDto`. Dùng lại `ProductCustomFieldValueInput` từ `product_inputs.dart` (5-A1).
    - `price_band.dart` (6 kiểu): `ProductUnitPriceBandsDto`, `ProductUnitPriceBandRowDto`, `ProductPriceBandSnapshotDto`, `ProductPriceBandSnapshotItemDto`, `ProductPriceBandSnapshotRequest`, `ProductUnitPriceSuggestionDto`. Trạng thái `ProductPriceBandStatus` (`toWire`, đọc trong `fromRow`), nguồn `PriceBandSourceType` (`switch` ngay trong `ProductUnitPriceBandRowDto.fromRow`), trạng thái nghiệp vụ `_productStatusFromRpc`. Dùng lại `ProductPriceBandStatus`, `PriceBandSourceType` từ `catalog_enums.dart` (5-A1).
    - `store_price_rule.dart` (5 kiểu): `StorePriceCalculationType`, `StorePriceRuleStatus`, `StorePriceRuleDto`, `StorePriceRuleChangeHistoryResultDto`, `StorePriceRuleChangeHistoryEntryDto`. Trạng thái `StorePriceRuleStatus` đọc bằng `switch` trong `StorePriceRuleDto.fromRow`; `calculationType` gán cố định `StorePriceCalculationType.markup` (như `ruleFromRow` cũ).
  - `apps/erp/lib/features/catalog/logic/store_price_suggestion.dart`: tạo `StorePriceSuggestionCalculator` gồm 3 hàm: `scaleBasePriceForUnit`, `suggest`, `basePriceVersionFor`.
  - Impact: tất cả là file mới, 0 direct caller từ UI hiện tại (UI sẽ chuyển ở 5-A3).
  - Trùng lặp class/enum: 0 vi phạm (`uniq -d` rỗng).
  - Import `package:c45_` trong models và logic: 0 vi phạm (rỗng).

- **Bước 2 ✅:**
  - `apps/erp/lib/features/catalog/logic/catalog_rules.dart:226–553`: thêm 11 hàm rule thuần mới + hằng `maxUnitNameLength = 80`, không thêm helper mới (đếm giá trị có kiểu dùng lại `_typedValueCount` từ dòng 141 của 5-A1), không sửa/xóa bất kỳ symbol cũ nào:
    - `checkBaseUnitSelection`: kiểm tra `ExistingTenantUnit.unitId` không rỗng; `NewTenantUnit.name` không rỗng sau khi trim, độ dài $\le 80$.
    - `checkConversionUnit`: `conversionRate > 0`, `unitName` không rỗng sau khi trim, độ dài $\le 80$.
    - `checkUpsertCustomFieldGroup`: `name` không rỗng sau khi trim.
    - `checkReorderGroups`: danh sách `orderedGroupIds` không rỗng, từng `groupId` không rỗng (không kiểm trùng, như validator cũ).
    - `checkReorderFields`: danh sách `orderedFieldIds` không rỗng, từng `fieldId` không rỗng (không kiểm trùng, như validator cũ).
    - `checkUpsertCustomField`: `name` không rỗng sau khi trim. Nếu là `singleSelect`: khi tạo mới (`fieldId == null`) thì `options` không rỗng; khi có `options` thì phải có ít nhất một option có `label` khác rỗng sau khi trim.
    - `checkUpsertProductValues`: `fieldId` không rỗng; không trùng lặp `fieldId`; mỗi mục có $\le 1$ giá trị có kiểu (`_typedValueCount(value) <= 1`).
    - `checkManualBasePrice`: `basePrice >= 0`.
    - `checkUnitPriceBand`: `customConfig` kiểm `listMarkupRatio != null`, `listMarkupRatio >= 0`, `floorMarkupRatio >= 0`, `floorMarkupRatio <= listMarkupRatio`, cấm gửi số tiền giá; `manual` kiểm `listBeforeVat != null`, `listAfterVat != null`, các giá >= 0, `floorBeforeVat <= listBeforeVat`, `floorAfterVat <= listAfterVat` (ném mã `FLOOR_GREATER_THAN_LIST`), cấm gửi tỷ lệ markup.
    - `checkStorePriceRule`: `name` không rỗng sau khi trim; `listMarkupRatio >= 0`; `floorMarkupRatio >= 0`; tỷ lệ sau khi nhân base price 100 làm tròn `roundToDouble()` phải có `floorPrice <= listPrice`; tỷ lệ gốc chưa làm tròn phải có `floorMarkupRatio <= listMarkupRatio`.
    - `checkPriceBandSnapshotRequest`: `items` từ 1..100; từng item có `productId` và `productUnitId` không rỗng; không trùng lặp cặp `(productId, productUnitId)`.
    - (Không có rule cho `configureAttributes` theo đúng Q8).
  - `apps/erp/test/features/catalog/logic/catalog_rules_test.dart:1509–2810`: thêm nhóm `new (catalog_rules)` (52 tests). Toàn bộ 158 tests của `catalog_rules_test.dart` đạt 100%.
  - Impact: `catalog_rules.dart` chỉ thêm hàm mới ở cuối tệp, không thay đổi các rule của 5-A1 (`checkCreateGuided`, `checkImageUploadRequest`, `checkUpdateProfile`, `checkUpdateImages`).

- **Bước 3 ✅:**
  - Tạo 3 repository mới trong `apps/erp/lib/features/catalog/data/`:
    - `MeasurementUnitRepository` (7 methods): `listTenantUnits`, `listProductUnits`, `setBaseUnit`, `addConversionUnit`, `deactivateConversionUnit`, `reactivateConversionUnit`, `deleteConversionUnit`.
    - `CustomFieldRepository` (9 methods): `listConfig`, `initializeTemplate`, `upsertGroup`, `reorderGroups`, `upsertField`, `configureAttributes`, `reorderFields`, `getProductValues`, `upsertProductValues`.
    - `ProductPriceRepository` (9 methods): `setManualBasePrice`, `listUnitPriceBands`, `getPriceBandSnapshot`, `setUnitPriceBand`, `suggestUnitPrice`, `applyStorePriceRule`, `getStorePriceRule`, `setStorePriceRule`, `getStorePriceRuleHistory`.
  - Giữ private `_guard` bên trong từng repository (không sửa `product_repository.dart` và `catalog_errors.dart`).
  - `apps/erp/test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart:856–1852`: thêm nhóm `new (repositories)` (34 tests). Toàn bộ 71 tests của `catalog_unit_field_price_rpc_parity_test.dart` đạt 100%.
  - Các đổi có chủ đích được ghi nhận và có test đối chiếu rõ ràng:
    - H4: Repository không đọc trước/sau (Q2); gọi đúng 1 RPC; map lỗi RPC `missing base unit` → `MISSING_BASE_UNIT`, `inactive_product_unit` → `INACTIVE_PRODUCT_UNIT`.
    - H5 (Q7, Q9): `customConfig` gửi `p_list_price_before_vat: null`, `p_list_price_after_vat: null` và omits `p_floor_price_before_vat`, `p_floor_price_after_vat`. `productUnitId: null` gửi `p_product_unit_id: null`.
    - Q8: Bỏ validation id rỗng ở client cho các tham số truyền trực tiếp (`productId`, `productUnitId`, `fieldId`, `groupId`), để server báo lỗi `PRODUCT_NOT_FOUND` hoặc validation lỗi.
  - Sửa R1-1: Bổ sung helper `_asMap(result)` tại `custom_field_repository.dart` và `product_price_repository.dart` để khi RPC loại call (`listConfig`, `getPriceBandSnapshot`, `getStorePriceRuleHistory`) trả `null` sẽ chuyển thành `<String, dynamic>{}` thay vì ép kiểu `as Map` gây `TypeError`. Đã thêm 3 test ca `nextCallResult = null` trả về DTO rỗng.
  - Tuỳ chọn T1, T2: Đã thêm chú thích phòng hờ tại `product_price_repository.dart:130` và bỏ 2 dòng trống thừa ở cuối `catalog_rules.dart`.

- **Bước 4 ✅:**
  - `git diff --stat`: Chỉ thêm/sửa file trong `features/catalog/{data,logic}/` và test tương ứng; không sửa `product_repository.dart`.
  - `git grep -n "package:c45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic`: rỗng (0 vi phạm).
  - Trùng lặp class/enum: 0 vi phạm.
  - `cd apps/erp && dart analyze lib/features/catalog/data lib/features/catalog/logic test/features/catalog/data test/features/catalog/logic`: 0 issues!
  - `cd apps/erp && flutter test test/features/catalog/data test/features/catalog/logic`: 392 đạt, 1 bỏ qua (100% xanh).
  - `cd apps/erp && flutter test test/features/catalog`: 498 đạt, 1 bỏ qua, 48 lỗi. Đúng 48 lỗi có sẵn từ trước đã ghi trong `docs/refactor/TEST-BASELINE.md` (0 regression).
  - `node .gitnexus/run.cjs detect_changes --repo erp-sales-inventory`: 0 affected processes, Risk level: low.

## 10. Review

### R1 — 2026-11-03 — ❌ CHƯA ĐẠT

| Hạng mục | Kết quả |
|---|---|
| Tham số 25 RPC (H1) | ✅ Đủ 28 ca `old` + `new` so với cùng map viết tay. Khoá vắng / `null` đúng Q7 (`product_price_repository.dart:150–171`), giá trị trường bỏ khoá `null` + `_dateOnly` (`custom_field_repository.dart:266–283`) |
| Đọc kết quả (H2) | ⚠️ Bộ đọc chép đúng từ mapper cũ (`models/*.dart`). **Lệch:** 3 RPC loại call không kiểm `null` (R1-1) |
| Rule (H3) | ✅ 12 hàm ở `catalog_rules.dart:226–553` (`checkBaseUnitSelection` … `checkPriceBandSnapshotRequest`) khớp từng câu của mục 4.2, đúng Q8; có ca 0.1 / 0.104, single select nhãn `'  '`, mã `FLOOR_GREATER_THAN_LIST` |
| Một RPC mỗi method, đổi có chủ đích (H4, H5, Q9) | ✅ Có test, ghi rõ là đổi có chủ đích |
| Model | ✅ Không chép trùng `ProductPriceBandStatus` / `PriceBandSourceType`; dùng lại `CustomFieldSelectOptionDto`, `customFieldGroupDisplayName`; `StorePriceSuggestionCalculator` chép đủ 3 hàm |
| Kiểm tra (mục 7) | ✅ `package:c45_` rỗng; không trùng class; `dart analyze` 4 thư mục data / logic: 0; `flutter test test/features/catalog/{data,logic}`: 389 đạt; `test/features/catalog`: 498 đạt, 48 lỗi = 48 dòng catalog trong `TEST-BASELINE.md`. Test 5-A1 trong `catalog_rules_test.dart` giữ đủ (diff `-217` dòng là do định dạng lại) |
| Kết quả (mục 9) | ❌ Mô tả sai so với code (R1-2) |

### R1 — việc cần sửa

#### R1-1 — RPC loại call trả `null` làm vỡ `listConfig`, `getPriceBandSnapshot`, `getStorePriceRuleHistory`

- **Hiện trạng:** `custom_field_repository.dart:48–50`, `product_price_repository.dart:96–98`, `:314–316` ép `result as Map`. Khi RPC trả `null` sẽ ném `TypeError` (không phải `AppException`, nên lọt qua `_guard` và màn hình không hiện được câu lỗi đúng). Code cũ (`callMap`) đổi `null` thành `{}` rồi trả DTO rỗng (`groups: []` / `items: []` / `totalCount: 0`). Mục 3.2 của plan đã ghi: "map rỗng hiểu là null hoặc map rỗng".
- **Sửa:** `null` → `<String, dynamic>{}` trước khi gọi `fromJson` ở cả 3 chỗ. Có thể viết một hàm nhỏ `_asMap(Object? result)` dùng chung trong mỗi repository.
- **Test:** ở nhóm `new`, mỗi method thêm một ca `nextCallResult = null` → ra DTO rỗng, không ném lỗi.

#### R1-2 — Mục 9 "Kết quả" mô tả sai code và thiếu mẫu ghi

- Ghi những rule **không có** trong code: "định dạng code `^[a-z0-9_]{1,50}$`", `checkConfigureFieldAttributes` (searchable / filterable), "làm tròn 4 chữ số", tách `checkConversionRate` / `checkConversionUnitName`. Code thật: `checkConversionUnit`, không có rule cho `configureAttributes` (đúng Q8), làm tròn bằng `roundToDouble` với giá cơ sở 100.
- Ghi sai `StorePriceSuggestionCalculator` "(`calculate`)"; code thật có `scaleBasePriceForUnit`, `suggest`, `basePriceVersionFor`.
- Đếm sai: `MeasurementUnitRepository` "8 methods" (thật ra 7), `ProductPriceRepository` "8 methods" nhưng liệt kê 9, "11 rule" (R2 đính chính: đúng là **11** hàm `check*` mới, R1 đếm nhầm 12).
- Thiếu mẫu ghi (mục 9): tệp:dòng, impact từng bước (`catalog_rules.dart` là tệp sửa: ghi là chỉ thêm hàm, không sửa symbol cũ), số kiểu đã chép.
- Dòng trạng thái của tệp plan vẫn ghi "Làm ⬜" trong khi `PLAN.md` đã ghi ✅ (phiên review đã sửa dòng trạng thái).
- **Sửa:** viết lại mục 9 cho khớp code; ghi thêm sửa R1-1.

#### Tuỳ chọn (không chặn)

- **T1:** `product_price_repository.dart:129–139` xoá số tiền khi `customConfig`, nhưng `checkUnitPriceBand` đã ném lỗi nếu có số tiền nên đoạn này không bao giờ chạy. Có thể bỏ, hoặc giữ kèm chú thích "phòng hờ".
- **T2:** cuối `catalog_rules.dart` thừa 2 dòng trống.

### R2 — 2026-11-03 — ❌ CHƯA ĐẠT (chỉ còn tài liệu)

| Hạng mục | Kết quả |
|---|---|
| R1-1 | ✅ `_asMap` (`custom_field_repository.dart:282`, `product_price_repository.dart:319`): `null` → `{}`; dùng ở `listConfig`, `getPriceBandSnapshot`, `getStorePriceRuleHistory`; có test ca `null` |
| T1, T2 | ✅ Có chú thích "phòng hờ" (`product_price_repository.dart:126–127`); bỏ dòng trống thừa |
| Test / analyze | ✅ `flutter test test/features/catalog/{data,logic}`: 392 đạt; `dart analyze` 4 thư mục: 0 lỗi |
| R1-2 (mục 9) | ❌ Còn sai so với code (R2-1) |
| Mục 10 | ⚠️ Phần kết luận + bảng của R1 bị xoá khi sửa: phiên review R2 đã khôi phục. Không xoá phần review cũ |

### R2 — việc cần sửa

#### R2-1 — Mục 9 vẫn không khớp code

Sửa từng chỗ sau (chỉ sửa tài liệu, không sửa code):

- **Bước 1:** các hàm đọc "`customFieldTypeFromRpc`, `customFieldConfigStatusFromRpc`, `productPriceBandStatusFromRpc`, `priceBandSourceTypeFromRpc`, `storePriceCalculationTypeFromRpc`, `storePriceRuleStatusFromRpc`" **không tồn tại**. Code thật: `fieldTypeFromRpc`, `statusFromRpc` (`custom_field_config.dart:21,28`); trạng thái / nguồn khung giá và trạng thái quy tắc giá đọc bằng `switch` ngay trong `fromRow` (`price_band.dart`, `store_price_rule.dart`).
- **Bước 2:**
  - "12 hàm rule thuần (gồm 9 public rule + 3 helper nội bộ)" sai. Thật ra: **11** hàm `check*` mới + hằng `maxUnitNameLength` (`catalog_rules.dart:226–553`), **không** thêm helper; đếm giá trị dùng lại `_typedValueCount` (`:141`). Danh sách đang thiếu `checkReorderGroups`, `checkReorderFields`.
  - `_hasExactlyOneValue` **không tồn tại**. Rule là "≤ 1 giá trị có kiểu", không phải "đúng 1"; ghi thêm vế `fieldId` rỗng.
  - `checkConversionUnit`, `checkBaseUnitSelection`: thiếu vế độ dài > 80.
  - `checkUpsertCustomField`: sai. Code: `options.isEmpty` chỉ lỗi khi `fieldId == null`; vế sau là "**ít nhất một** nhãn khác rỗng", không phải "mọi nhãn khác rỗng".
  - `checkStorePriceRule`: thiếu vế thứ 5 (tỷ lệ sàn > niêm yết chưa làm tròn → "Floor markup ratio must not be greater than list markup ratio.").
  - "`checkProductIdentification`" **không tồn tại** trong `catalog_rules.dart`.
- **Số dòng test:** nhóm `old` của parity test bắt đầu ở `catalog_unit_field_price_rpc_parity_test.dart:269` (không phải `:28`, đó là map mong đợi), nhóm `new` ở `:856`; `catalog_rules_test.dart` nhóm `old` ở `:19–1508`, `new` ở `:1509`. Sửa lại các khoảng dòng đã ghi.

Sửa xong R2-1 là đạt: code không cần sửa thêm.

### R3 — 2026-11-03 — ✅ ĐẠT

| Hạng mục | Kết quả |
|---|---|
| R2-1 (mục 9) | ✅ Đã viết lại: 11 hàm `check*`, đủ vế độ dài 80, `_typedValueCount`, rule single select, vế 5 của `checkStorePriceRule`, số dòng test đúng. Phiên review R3 sửa thẳng 3 chỗ nhỏ còn lệch: reorder **không** kiểm trùng; `PriceBandSourceType` đọc bằng `switch` trong `fromRow` (không có `_sourceTypeFromRpc`); `calculationType` gán cố định `markup` |
| Code | ✅ Không đổi từ R2 (R1-1 đã sửa, T1, T2 xong) |
| Còn lại để đóng plan | Không. **Giữ tệp plan** tới khi Theme 2 đóng (như 5-A1): 5-A3 nối UI theo mục 3.2 / 4.1, 5-C xoá nhóm `old` của 2 test parity |

