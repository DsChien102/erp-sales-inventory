# 5-A2 — Lớp dữ liệu catalog: `MeasurementUnitRepository`, `CustomFieldRepository`, `ProductPriceRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc, phần **dữ liệu** · Gồm việc 5.2, 5.3, 5.4 (phần data) (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01; rà lại theo code 2026-11-02: `includeInactiveValues`, giữ kiểm rỗng, `capturedAt`, khoá giá sàn vắng ở `customConfig`, rule single select khi sửa, trùng cặp snapshot, mã `FLOOR_GREATER_THAN_LIST`) | Làm ⬜ | Review ⬜
> Làm **sau** [5-A1](5-A1-catalog-data-san-pham.md): dùng lại `catalog_errors.dart`, `catalog_error_messages.dart`, `catalog_rules.dart`, `catalog_enums.dart`, cách viết `_guard` và `_Rpc` của 5-A1.
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
| Q7 | Khung giá `customConfig`: handler cũ đọc giá cơ sở + tỷ lệ quy đổi rồi tự tính số tiền gửi lên | **Không tính ở client.** Server `set_product_unit_price_band` tự tính từ `p_list_markup_ratio` / `p_floor_markup_ratio` và giá cơ sở (`20260722001` nhánh `when 'customConfig'`, bỏ qua số tiền client gửi). Repository cho `customConfig`: `listBeforeVat` / `listAfterVat` / `floorBeforeVat` / `floorAfterVat` = `null` ⇒ theo mapper, khoá `p_list_price_before_vat`, `p_list_price_after_vat` **có mặt** với giá trị `null` (hàm không có `default` cho 2 tham số này, phải gửi), khoá `p_floor_price_before_vat`, `p_floor_price_after_vat` **vắng** (mapper bỏ khoá khi `null`; hàm có `default null`). Hệ quả của Q2 (5-A1) |

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

**`MeasurementUnitRepository`** (`features/catalog/data/measurement_unit_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `listTenantUnits({keyword, limit = 50})` | `list_tenant_measurement_units` | rows | `ProductRpcMapper.listTenantUnitsParams` | thân `SupabaseCatalogUnitGateway.listTenantUnits` | `List<TenantMeasurementUnitDto>` |
| `listProductUnits(productId, {includeInactive = false})` | `list_product_units` | rows | `ProductRpcMapper.listProductUnitsParams` | `ProductRpcMapper.productUnitsDtoFromRows` (+ `productUnitDtoFromRow`) như `listProductUnits` của gateway | `ProductUnitsDto` |
| `setBaseUnit(productId, BaseUnitSelection selection)` | `set_product_base_unit` | call | `ProductRpcMapper.setProductBaseUnitParams` | map rỗng (hoặc `null`) → `AppException(unknown, serverMessage: 'Set base unit did not return a result.')`; không đọc thêm (cubit tự tải lại) | `void` |
| `addConversionUnit({productId, unitName, conversionRateToBase})` | `add_product_conversion_unit` | call | `addConversionUnitParams` | không đọc | `void` |
| `deactivateConversionUnit({productId, productUnitId})` | `deactivate_product_conversion_unit` | call | `deactivateConversionUnitParams` | không đọc | `void` |
| `reactivateConversionUnit({productId, productUnitId})` | `reactivate_product_conversion_unit` | call | `reactivateConversionUnitParams` | không đọc | `void` |
| `deleteConversionUnit({productId, productUnitId})` | `delete_product_conversion_unit` | rows | `deleteConversionUnitParams` | không đọc | `void` |

"không đọc" ở cột "Kết quả" (cả 3 bảng) = không dựng DTO; mọi bước kiểm rỗng của gateway cũ đều đã ghi ngay trong ô và phải giữ.

Tham số ngoài app truyền (vd. `p_actor_id`, `p_expected_version` nếu mapper có) lấy đúng như mapper cũ dựng từ command: đọc thân từng hàm `…Params` và chép mọi khoá. Field của command mà app không truyền (giá trị mặc định của command) → dùng **cùng** mặc định.

**`CustomFieldRepository`** (`features/catalog/data/custom_field_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `listConfig()` | `list_custom_field_config` | call | `CustomFieldRpcMapper.listConfigParams` | `configViewFromJson` (+ `groupFromJson`, `fieldFromJson`, `optionFromJson`, `statusFromRpc`, `fieldTypeFromRpc`) | `CustomFieldConfigViewDto` |
| `initializeTemplate()` | `initialize_custom_field_template` | call | `initializeTemplateParams` | không đọc | `void` |
| `upsertGroup({groupId, name, iconKey, status, …})` | `upsert_custom_field_group` | call | `upsertGroupParams` | map rỗng → `AppException(unknown, serverMessage: 'Upsert custom field group did not return a result.')`; không đọc thêm | `void` |
| `reorderGroups(List<String> orderedGroupIds)` | `reorder_custom_field_groups` | call | `reorderGroupsParams` | — | `void` |
| `upsertField({fieldId, groupId, name, fieldType, options, …})` | `upsert_custom_field` | call | `upsertFieldParams` (mảng `options` chép đủ `option_id`, `label`, `sort_order`, `is_active`) | map rỗng → `AppException(unknown, serverMessage: 'Upsert custom field did not return a result.')`; còn lại `fieldFromJson` | `CustomFieldDefinitionDto` (cubit dùng `fieldId`) |
| `configureAttributes({fieldId, isRequired, isSearchable, isFilterable, displayOnList, …})` | `configure_custom_field_attributes` | call | `configureAttributesParams` | không đọc | `void` |
| `reorderFields({groupId, orderedFieldIds})` | `reorder_custom_fields` | call | `reorderFieldsParams` | — | `void` |
| `getProductValues(productId, {includeInactiveValues = false})` | `get_product_custom_field_values` | call | `getProductCustomFieldValuesParams` (gồm `p_include_inactive_values`; `product_custom_field_group_edit_cubit.dart:26` truyền `true`) | map rỗng → `AppException(CatalogErrorCodes.productNotFound)` (gateway cũ: `ApplicationException('Product not found')`); còn lại `productCustomFieldValuesFromJson` (+ `productCustomFieldValueGroupFromJson`, `productCustomFieldValueFieldFromJson`, `readinessSummaryFromJson`, `_toDate`, `_toDouble`) | `ProductCustomFieldValuesDto` |
| `upsertProductValues({productId, values})` | `upsert_product_custom_field_values` | call | `upsertProductCustomFieldValuesParams` (+ `productCustomFieldValueInputToJson`, `_dateOnly`) | map rỗng → `AppException(unknown, serverMessage: 'Upsert product custom field values did not return a result.')`; không đọc thêm | `void` |

Tham số của mọi method: đúng các field của command tương ứng **trừ** `tenantId` / `actorId` (cùng tên, cùng kiểu, cùng mặc định). Đọc command gốc ở `modules/catalog/application/lib/src/custom_field/commands/**`, `product_custom_field_value/**`.

**`ProductPriceRepository`** (`features/catalog/data/product_price_repository.dart`)

| Method mới | RPC | Gọi | Tham số | Kết quả | Trả về |
|---|---|---|---|---|---|
| `setManualBasePrice({productId, basePrice, currency = 'VND'})` | `set_manual_base_price` | call | `ProductRpcMapper.setManualBasePriceParams`: `p_mode: 'manual'`, `p_base_price_after_vat: basePrice`, `p_currency` | không đọc | `void` |
| `listUnitPriceBands(productId)` | `list_product_unit_price_bands` | rows | `ProductPriceBandRpcMapper.listProductUnitPriceBandsParams` | rỗng → `AppException(unknown, serverMessage: 'Product unit price bands did not return a result.')`; còn lại `bandsFromRows` (+ `rowFromListRpc`, `_basePricePerBaseUnitFromRows`, `_readOptional*`, `sourceTypeFromRpc`) | `ProductUnitPriceBandsDto` |
| `getPriceBandSnapshot(List<ProductPriceBandSnapshotRequest> items)` | `get_product_price_band_snapshot` | call | `getPriceBandSnapshotParams` | `snapshotFromJson` (+ `snapshotItemFromJson`, `_productStatusFromRpc`), rồi như `GetProductPriceBandSnapshotQueryHandler`: dựng lại mọi mục với **`capturedAt = DateTime.now().toUtc()`** (một giá trị chung cho cả lần gọi; mapper đặt `DateTime.utc(1970)`) | `ProductPriceBandSnapshotDto` |
| `setUnitPriceBand({productId, productUnitId, sourceType, listBeforeVat, listAfterVat, floorBeforeVat, floorAfterVat, listMarkupRatio, floorMarkupRatio, effectiveFrom, effectiveTo, status})` | `set_product_unit_price_band` | rows | `ProductPriceBandRpcMapper.setProductUnitPriceBandParams` (chép đúng khoá nào dùng `?`: chỉ `p_floor_price_before_vat`, `p_floor_price_after_vat`, `p_effective_from`, `p_effective_to`, `p_status`). **`customConfig`:** 4 tham số giá = `null` ⇒ 2 khoá niêm yết `null`, 2 khoá sàn vắng (Q7). **`manual`:** truyền thẳng giá trị nhập | không đọc | `void` |
| `suggestUnitPrice({productId, productUnitId})` | `suggest_product_unit_price` | rows | `StorePriceRuleRpcMapper.suggestProductUnitPriceParams` | rỗng → `AppException(unknown, serverMessage: 'Suggest product unit price did not return a result.')`; còn lại `suggestionFromRow` | `ProductUnitPriceSuggestionDto` |
| `applyStorePriceRule({productId, productUnitId, storePriceRuleId, basePriceVersion, confirmOverwrite})` | `apply_store_price_rule` | rows | `applyStorePriceRuleParams` | rỗng → `AppException(unknown, serverMessage: 'Apply store price rule did not return a result.')`; không đọc thêm | `void` |
| `getStorePriceRule()` | `get_store_price_rule` | rows | `getStorePriceRuleParams` | rỗng → `null`; còn lại `ruleFromRow(rows.first)` (trả `null` khi thiếu `id`: giữ `null`) | `StorePriceRuleDto?` |
| `setStorePriceRule({name, listMarkupRatio, floorMarkupRatio, status})` | `set_store_price_rule` | rows | `setStorePriceRuleParams` (+ `_statusToRpc`) | rỗng → `AppException(unknown, serverMessage: 'Set store price rule did not return a result.')`; `ruleFromRow(rows.first)` trả `null` → `AppException(unknown, serverMessage: 'Set store price rule returned invalid data.')` (`supabase_store_price_rule_gateway.dart:55–60`); còn lại DTO đó | `StorePriceRuleDto` |
| `getStorePriceRuleHistory({limit, offset})` | `get_store_price_rule_change_history` | call | `StorePriceRuleChangeHistoryRpcMapper.params` | `resultFromJson` (+ `entryFromJson`, `_asDouble`) | `StorePriceRuleChangeHistoryResultDto` |

### 3.3 Việc client module cũ làm quanh các RPC trên

| Handler cũ | Làm thêm trước / sau RPC | Sau 5-A2 |
|---|---|---|
| `Add/Deactivate/Reactivate/DeleteProductConversionUnitCommandHandler` | gọi `list_product_units(includeInactive: true)` rồi chạy `ProductUnitSet` (trùng tên, đơn vị cơ sở, tỷ lệ) | **Bỏ đọc trước** (Q2). Server trả `duplicate product unit "<x>"`, `validation_exception: Base unit cannot be … here.`, `Conversion rate must be greater than zero.`, `product unit not found` (`20260709005`, `20260710004`, `20260709023`). Giữ rule đầu vào (4.2) |
| `SetManualBasePriceCommandHandler` | `mode != 'manual'` → lỗi; đọc readiness (`get_product_readiness`), thiếu đơn vị cơ sở → `MissingBaseUnitException`; chạy `ProductBasePriceProfile.setManual`; sau RPC đọc lại readiness + `list_product_units` để dựng kết quả | **Bỏ đọc trước / sau.** Server: `catalog._ensure_product_has_base_unit` → `missing base unit`; `not_manual_base_price_mode`; `base price cannot be negative` (`20260717008`). `mode` luôn `'manual'` |
| `SetProductUnitPriceBandCommandHandler` | đọc readiness (thiếu đơn vị cơ sở), `list_product_units` (tìm đơn vị, `inactive_product_unit`), PCC (giá cơ sở), tính số tiền `customConfig`, chạy `PriceBandWarningCalculator` → `PriceBandWarningsRequireAcknowledgmentException`; sau RPC đọc readiness | **Bỏ hết** (Q2, Q6, Q7). Server: `product unit not found`, `inactive_product_unit`, `validation_exception: …` (`20260722001`). Giữ rule đầu vào của validator (4.2) |
| `ApplyStorePriceRuleCommandHandler` | `get_store_price_rule` (không có → `Store price rule not found`), PCC (thiếu giá cơ sở → `MissingBasePriceException`), dựng `StorePriceRule` + `ProductUnitPriceBand.set` để kiểm; sau RPC đọc readiness | **Bỏ hết.** Server: `store_price_rule_not_found`, `store_price_rule_inactive`, `missing_base_price`, `stale_base_price`, `price_band_overwrite_required` (`20260717007`) |
| `SetStorePriceRuleCommandHandler` | `StorePriceRule.create` (tên, tỷ lệ ≥ 0, sàn ≤ niêm yết) | **Giữ** (chỉ cần dữ liệu nhập): gộp vào `checkStorePriceRule` (4.2) |
| Validator các command / query | | giữ phần không phải id / tenant / `limit` (4.2) |

## 4. Thiết kế

### 4.1 Model (`features/catalog/data/models/`)

Cùng quy tắc chép của 5-A1 mục 4.1. Thêm:

| Tệp mới | Chứa |
|---|---|
| `measurement_unit.dart` | `TenantMeasurementUnitDto`, `ProductUnitDto`, `ProductUnitsDto` (`application/product_unit/**`) |
| `custom_field_config.dart` | `CustomFieldConfigViewDto`, `CustomFieldGroupConfigDto`, `CustomFieldDefinitionDto`, `CustomFieldType`, `CustomFieldConfigStatus` và kiểu lồng (`application/custom_field/shared/**`, `domain/custom_fields/**`). `CustomFieldSelectOptionDto` đã có ở 5-A1 (`custom_field_filter_option.dart`): **dùng lại**, không chép lần hai |
| `product_custom_field_values.dart` | `ProductCustomFieldValuesDto`, `ProductCustomFieldValueGroupDto`, `ProductCustomFieldValueFieldDto` (`application/product_custom_field_value/queries/**`). `ProductCustomFieldValueInput` đã có ở 5-A1 |
| `price_band.dart` | `ProductUnitPriceBandsDto`, `ProductUnitPriceBandRowDto`, `ProductPriceBandStatus` (+ `toWire`), `ProductPriceBandSnapshotDto`, `ProductPriceBandSnapshotItemDto`, `ProductPriceBandSnapshotRequest`, `ProductUnitPriceSuggestionDto` |
| `store_price_rule.dart` | `StorePriceRuleDto`, `StorePriceRuleStatus`, `StorePriceRuleChangeHistoryResultDto`, `StorePriceRuleChangeHistoryEntryDto` |
| `../../logic/store_price_suggestion.dart` | `StorePriceSuggestionCalculator` (`application/product_unit_price_band/queries/suggest_product_unit_price/store_price_suggestion_calculator.dart`): app gọi thẳng ở `catalog_ui_mapper.dart`, `guided_price_band_submission_resolver.dart`. Chép nguyên |

**Không** chép: `PriceBandWarningCalculator`, `PriceBandValidationWarningDto` (Q6); `SetProductBaseUnitResult`, `ProductUnitMutationResult`, `SetManualBasePriceResult`, `SetProductUnitPriceBandResult`, `ApplyStorePriceRuleResult`, `AppliedStorePriceRuleDto`, `InitializeCustomFieldTemplateResult`, `ConfigureCustomFieldAttributesResult`, `UpsertCustomFieldValuesResult`, `SetStorePriceRuleResult` (method trả `void` / DTO trực tiếp). 5-A3 đổi cubit theo.

### 4.2 Rule (thêm vào `features/catalog/logic/catalog_rules.dart`)

Cùng cách của 5-A1 mục 4.5: ném `AppException(AppErrorCode.validation, serverMessage: <câu cũ nguyên văn>)` (trừ ngoại lệ mã ghi ở `checkUnitPriceBand`), chạy **trước** RPC, bỏ vế tenant / actor / product id / `limit`. `SetManualBasePriceCommandValidator` còn vế `mode != 'manual'` → `NotManualBasePriceModeException`: bỏ, vì repository luôn gửi `'manual'`.

| Hàm | Chép từ (validator / domain) | Gọi ở |
|---|---|---|
| `checkBaseUnitSelection(BaseUnitSelection)` | `SetProductBaseUnitCommandValidator` (id không rỗng; tên không rỗng, ≤ `maxUnitNameLength`) | `setBaseUnit` |
| `checkConversionUnit({unitName, conversionRateToBase})` | `AddProductConversionUnitCommandValidator` (tên không rỗng, ≤ `maxUnitNameLength`, tỷ lệ > 0). Chép hằng `maxUnitNameLength` | `addConversionUnit` |
| `checkUpsertCustomFieldGroup(name)` | `UpsertCustomFieldGroupCommandValidator` | `upsertGroup` |
| `checkReorder(ids)` | `ReorderCustomFieldGroupsCommandValidator`, `ReorderCustomFieldsCommandValidator`: danh sách rỗng → "Ordered group ids must include all groups." / "Ordered field ids must include all fields." (validator chỉ kiểm `isEmpty`, không đọc DB: chép); mỗi id không rỗng → "Group id must not be empty." / "Field id must not be empty.". Tách 2 hàm `checkReorderGroups`, `checkReorderFields` vì câu khác nhau | `reorderGroups`, `reorderFields` |
| `checkUpsertCustomField(...)` | `UpsertCustomFieldCommandValidator` theo thứ tự (group id, tên, `singleSelect` + `options.isEmpty` + **`fieldId == null`** → "Single select field requires options."), **rồi** rule domain của handler `CustomField.create` → `SingleSelectMustHaveOptionsRule` (chạy **cả khi sửa**): `singleSelect` mà không có lựa chọn nào `label.trim()` khác rỗng → "Trường single select phải có ít nhất một option hợp lệ.". Vế tên rỗng của domain trùng validator: bỏ | `upsertField` |
| `checkConfigureAttributes(fieldId)` | `ConfigureCustomFieldAttributesCommandValidator` (field id) | `configureAttributes` |
| `checkUpsertProductValues(values)` | `UpsertCustomFieldValuesCommandValidator` (field id, không trùng field, ≤ 1 giá trị có kiểu mỗi field) | `upsertProductValues` |
| `checkManualBasePrice(basePrice)` | `SetManualBasePriceCommandValidator`: `< 0` → "Giá vốn cơ sở không được âm." (câu cũ; 5-B đổi chữ theo KI-14) | `setManualBasePrice` |
| `checkUnitPriceBand(...)` | `SetProductUnitPriceBandCommandValidator`: chép **mọi** nhánh theo `sourceType` (ruleBased → "Vui lòng dùng lệnh áp dụng khung giá cửa hàng."; customConfig: không có `storePriceRuleId`, không có số tiền, tỷ lệ niêm yết bắt buộc, ≥ 0, sàn ≥ 0 và ≤ niêm yết; manual: không có nguồn công thức, niêm yết bắt buộc, ≥ 0, sàn ≥ 0 và ≤ niêm yết). Thêm nhánh của handler `_createPriceBand` manual: `listBeforeVat` hoặc `listAfterVat` null → "Manual list prices are required.". **Ngoại lệ mã:** 2 vế sàn > niêm yết của nhánh `manual` ở validator ném `FloorPriceGreaterThanListPriceException` (không phải `ValidationException`) ⇒ ném `AppException(CatalogErrorCodes.floorGreaterThanList)` (không `serverMessage`; 4.4 của 5-A1 ra "Giá sàn không được lớn hơn giá niêm yết."), **không** `VALIDATION_ERROR` | `setUnitPriceBand` |
| `checkStorePriceRule({name, listMarkupRatio, floorMarkupRatio})` | `SetStorePriceRuleCommandValidator` (tên, `MarkupRatioMustBeNonNegativeRule` hai nhãn, `SuggestedFloorNotGreaterThanListRule`) + `StorePriceRule.create` của handler (chép các `checkRule` trong `create`; trùng điều kiện với validator thì giữ một lần, câu của validator) | `setStorePriceRule` |
| `checkPriceBandSnapshotRequest(items)` | `GetProductPriceBandSnapshotQueryValidator`: rỗng → "At least one item is required."; > 100 → "At most 100 items can be read at once."; `productId` rỗng → "Product id is required."; `productUnitId` rỗng → "Product unit id is required."; trùng cặp `productId:productUnitId` → "Duplicate product and unit pair is not allowed." | `getPriceBandSnapshot` |

### 4.3 Ba repository

Constructor như `ProductRepository` (5-A1 mục 4.2): `rpc`, `tenantId`, `actorId` (chỉ khi có RPC cần `p_actor_id`; không cần thì bỏ tham số). Mỗi method gọi **đúng 1 RPC**, bọc `_guard` → `catalogException`. Có thể tách `_guard` ra hàm top-level `guardCatalog<T>(Future<T> Function())` trong `catalog_errors.dart` và sửa `ProductRepository` dùng chung (ghi vào Kết quả nếu làm).

## 5. Đang làm gì — test giữ hành vi

| # | Cơ chế cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| H1 | Tham số 25 RPC của mục 3.2 | 3 repository | `test/features/catalog/data/catalog_unit_field_price_rpc_parity_test.dart`: nhóm `old` (mapper cũ) và `new` (repository qua `_Rpc`) so với **cùng** map viết tay. Ca: `setBaseUnit` cả `ExistingTenantUnit` lẫn `NewTenantUnit`; `upsertField` `singleSelect` 2 lựa chọn; `upsertProductValues` đủ 5 kiểu giá trị (chữ, số, ngày, đúng/sai, lựa chọn); `setUnitPriceBand` `manual` có sàn và **`customConfig`** (xem H5); `applyStorePriceRule` có `confirmOverwrite`; `getPriceBandSnapshot` 2 mục; `getProductValues` với `includeInactiveValues: true` → `p_include_inactive_values: true` |
| H2 | Đọc kết quả (`configViewFromJson`, `productCustomFieldValuesFromJson`, `bandsFromRows`, `snapshotFromJson`, `ruleFromRow`, `suggestionFromRow`, `resultFromJson`, `productUnitsDtoFromRows`, `listTenantUnits`) | `fromJson` cạnh model | cùng tệp H1: JSON mẫu → DTO, so từng field. Gồm: `bandsFromRows` có / không `base_price_amount` ở dòng đầu; `ruleFromRow` dòng rỗng / trạng thái `inactive`; `fieldTypeFromRpc` giá trị lạ. Kiểm rỗng (chỉ nhóm `new`, so câu): `setBaseUnit`, `applyStorePriceRule`, `setStorePriceRule` (rỗng; thiếu `id` → "returned invalid data"), `getProductValues` (→ `PRODUCT_NOT_FOUND`), `listUnitPriceBands`, `suggestUnitPrice`, `upsertGroup`, `upsertField`, `upsertProductValues`. `getPriceBandSnapshot`: mọi mục có cùng `capturedAt`, nằm giữa hai mốc `DateTime.now().toUtc()` trước / sau lời gọi |
| H3 | Validator + rule domain trước RPC | `catalog_rules.dart` (4.2) | `test/features/catalog/logic/catalog_rules_test.dart` (tệp của 5-A1, thêm nhóm): mỗi `if` một ca sai + một ca đúng; nhóm `old` gọi validator / `StorePriceRule.create` / `CustomField.create` cũ, nhóm `new` gọi hàm mới, cùng câu. Ca riêng: sửa trường `singleSelect` (`fieldId` có) với 1 lựa chọn nhãn `'  '` → validator qua, `CustomField.create` ném câu tiếng Việt; snapshot trùng cặp; `manual` sàn > niêm yết: nhóm `old` kỳ vọng `FloorPriceGreaterThanListPriceException`, nhóm `new` kỳ vọng mã `FLOOR_GREATER_THAN_LIST` |
| H4 | Handler đọc trước / sau (đơn vị, giá cơ sở, khung giá, áp khung cửa hàng) | **Đổi (Q2):** bỏ | repository test: `addConversionUnit`, `setManualBasePrice`, `setUnitPriceBand`, `applyStorePriceRule` mỗi cái gọi **đúng 1** RPC. `_Rpc` ném `PostgrestException(message: 'missing base unit')` khi `setManualBasePrice` → `AppException` code `MISSING_BASE_UNIT` |
| H5 | `customConfig`: handler gửi số tiền tự tính | **Đổi (Q7):** gửi `null` | parity H1 ca `customConfig`: map mong đợi của nhóm `old` có số tiền (dựng handler với giá cơ sở mẫu), của nhóm `new` có `p_list_price_before_vat: null`, `p_list_price_after_vat: null` và **không có** khoá `p_floor_price_before_vat`, `p_floor_price_after_vat` (kiểm bằng `containsKey` là `false`); mọi khoá khác **giống nhau**. Ghi rõ trong test đây là đổi có chủ đích |
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
- [ ] `git grep -n "package:vet45_" -- apps/erp/lib/features/catalog/data apps/erp/lib/features/catalog/logic` **rỗng**.
- [ ] Không có hai class cùng tên trong `features/catalog/data/models/` (`git grep -hoE "^(final |abstract |sealed )*(class|enum) \w+" -- apps/erp/lib/features/catalog/data/models | sort | uniq -d` rỗng).
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới.
- [ ] `cd apps/erp && flutter test test/features/catalog`: xanh; `flutter test`: không fail mới so với sau 5-A1.

## 8. Rủi ro / lưu ý

- `setProductUnitPriceBandParams` dùng cú pháp bỏ khoá khi `null` (`'p_floor_price_before_vat': ?floorBeforeVat`). Chép đúng: khoá **vắng** khác khoá `null` với PostgREST (vắng → dùng `default` của hàm).
- `ProductPriceBandStatus.toWire()` / `StorePriceRuleStatus`: giữ đúng chuỗi.
- `listProductUnits` của Pricing (`pricing_pick_unit_page`) gọi **không** có `includeInactive` (mặc định `false`) rồi tự lọc `isActive`. Giữ mặc định `false`.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp:dòng · lệch plan + lý do · test thêm / sửa (đổi có chủ đích: dòng H nào) · impact · ghi chú cho review. Bước cuối: lệnh, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`.

## 10. Review

<!-- Phiên review ghi -->
