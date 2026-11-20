# 6-A2 — Pricing: đổi UI + Sales + router + DI sang repository; bỏ nhập Excel và màn "Chọn cách thêm"

> Theme 4 (mã cũ P6) · Bước (a) chuyển kiến trúc, phần UI · Gồm việc 6.1 (UI), 6.3 (đã xong, chỉ kiểm), Q9 (bỏ 6.2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-04, kèm các đề xuất "duyệt plan là chốt") | Làm ✅ 2026-11-04 | Review ✅ R3 2026-11-05 (đã sửa R1-1, R1-2, R2-1; còn kiểm tay 7.2 — người dùng)
> **Cần 6-A1 xong trước** (dùng `CustomerPriceRuleRepository`, `SalesPricingRepository`, model, `PricingErrorCodes`, `pricingErrorMessage`). Trước khi làm: rà lại các chữ ký ở mục "Interfaces" theo code 6-A1 thật; lệch thì ghi Kết quả, theo code.
> Tài liệu: [TH-04](../../../02-yeu-cau/TH-04-chinh-sach-gia.md) 5.1 (màn), 6.4 (lỗi); [6-A1](6-A1-pricing-data.md) mục 2 (Q1–Q9), 4; PLAN.md "Plan xoá / tách / thay code cũ: test giữ hành vi trước". Mẫu Theme 2: `5-A3-catalog-ui-sang-repository.md`.

## 1. Mục tiêu

- App `erp` không còn gọi `IPricingModule` (pricing UI, `sales_pricing_lookup.dart`, `sales_draft_backend.dart`, router); DI bỏ `PricingStartup` / `IPricingModule`. Thư mục `modules/pricing` và dòng `c45_pricing_*` trong `apps/erp/pubspec.yaml` để 6-C xoá (nhóm `old` của test parity 6-A1 còn dùng).
- 4 cubit còn lại (danh sách, chi tiết, form, lịch sử) + state chuyển `presentation/cubit/` → `logic/` (PLAN "Đổi Cubit" bước 6), dùng repository.
- **Bỏ nhập Excel (Q9 của 6-A1):** xoá màn PR-09 (trang, cubit, widget, service, route `/pricing/import`, test). **Bỏ màn PR-03 "Chọn cách thêm"**: nút thêm ở danh sách mở thẳng `/pricing/new`.
- Câu lỗi thô đổi theo TH-04 6.4 (Q4); bật lại gửi đúng cờ ghi đè (Q3, đã ở repository 6-A1).
- Fake: `FakePricingModule` (module) → `FakeCustomerPriceRuleRepository` + `RecordingSalesPricingRepository` ở `apps/erp/test`.

## 2. Quyết định

Q1–Q9: xem [6-A1 mục 2](6-A1-pricing-data.md#2-quyết-định). Thêm:

| # | Câu hỏi | Chốt |
|---|---|---|
| Q10 | Màn "Chọn cách thêm" sau khi bỏ Excel | **Người dùng chốt 2026-11-04:** bỏ màn. `_openAddFlow` của danh sách push `/pricing/new`; nút thêm (FAB + nút ở trạng thái rỗng) hiện theo `canCreate` (= `available_actions` có `create_manual`, như hiện nay) |
| Q11 | Câu trạng thái rỗng "Tạo giá riêng hoặc nhập từ Excel để bắt đầu." (`pricing_list_page.dart:159`) | Đổi thành "Tạo giá riêng để bắt đầu." (hệ quả trực tiếp của Q9; không để câu hứa tính năng đã bỏ) |
| Q12 | Nhãn còn nhắc Excel cho **dữ liệu cũ**: nguồn "Nhập Excel" (`price_rule_detail_content.dart:279`, `price_rule_activity_detail_sheet.dart:311`), hoạt động "Tạo / Cập nhật từ nhập Excel" (`…activity_detail_sheet.dart:424-425`), lọc nhanh lịch sử "Nhập Excel" (`price_rule_history_view.dart:47,74,280`) | **Giữ ở 6-A2** (chỉ hiển thị dữ liệu có sẵn). Lọc nhanh "Nhập Excel" bỏ ở **6-B** cùng KI-02 (bỏ lọc "Từ đơn hàng" ở cùng widget). Nhãn nguồn / hoạt động: 6-C quyết theo kết quả kiểm DB |
| Q13 | Test của tính năng đã bỏ / không dùng | **Xoá**: `price_rule_import_cubit_test.dart`, `price_rule_import_widgets_test.dart`, nhóm `e2e_e02_u05` của `pricing_import_history_e2e_test.dart`, nhóm `wgt_e02_u02` + `wgt_e02_u05` của `pricing_pages_test.dart`, nhóm `e2e_e02_u02` của `pricing_list_detail_choose_e2e_test.dart`, `remembered_price_mediator_e2e_test.dart` (lệnh nhớ giá app không gọi, Q8), thư mục `test/features/pricing/fixtures/`. Thay bằng test của luồng thêm mới (H1) |
| Q14 | Chỗ đặt fake | `apps/erp/test/features/pricing/support/` (mẫu `test/features/catalog/support/`, `test/features/partner/support/`) |

## 3. Thay đổi

### 3.1 `lib`

| Tệp | Hành động |
|---|---|
| `features/pricing/presentation/cubit/price_rule_{list,detail,form,history}_{cubit,state}.dart` (8 tệp) → `features/pricing/logic/` | `git mv` rồi sửa (mục 4.1). Thư mục `presentation/cubit/` trống ⇒ xoá |
| `features/pricing/presentation/pages/pricing_{list,detail,form,history}_page.dart` | dựng cubit bằng `GetIt.instance<CustomerPriceRuleRepository>()`; bỏ `IExecutionContext`; đổi import; danh sách sửa `_openAddFlow` (mục 4.3), câu rỗng (Q11); form sửa `_mapErrorToMessage` (mục 4.2) |
| `features/pricing/presentation/pages/pricing_choose_method_page.dart` | **xoá** (Q10, bảng H1–H4) |
| `features/pricing/presentation/pages/pricing_import_page.dart`, `cubit/price_rule_import_{cubit,state}.dart`, `formatters/price_rule_import_issue_formatter.dart`, `services/pricing_import_{file_service,log_xlsx_builder}.dart`, `widgets/price_rule_import_{wizard,choose_file,preview,confirm,result,issue_detail_sheet,shared}.dart`, `widgets/pricing_import_cancel_dialog.dart` | **xoá** (Q9). Thư mục `formatters/`, `services/` trống ⇒ xoá |
| 18 tệp `features/pricing/presentation/**` còn lại (ngoài 8 tệp cubit / state ở hàng trên và các tệp bị xoá) đang import `c45_pricing_application` / `c45_pricing_domain` (đo `grep -rl "c45_pricing" lib/features/pricing` sau khi xoá ở trên) | đổi import sang `package:erp/features/pricing/data/models.dart` (+ `data/pricing_errors.dart` nơi dùng `PricingBlockedCodes`); `PricingBlockedCodes.` → `PricingErrorCodes.`; `PricingBlockedException` → `AppException`. Không đổi gì khác |
| `features/pricing/presentation.dart` | bỏ 9 dòng export nhập Excel (dòng 9, 10, 24–30); đổi đường cubit / state sang `logic/` |
| `features/sales/presentation/lookups/sales_pricing_lookup.dart` | mục 4.4 |
| `features/sales/presentation/orchestration/sales_draft_backend.dart:5,460-490` + kiểu `pricing.SalesPricingLinePreviewDto` ở `_toDraftLineInput` | mục 4.4 |
| `core/router/app_router.dart` | xoá import dòng 9 (`c45_pricing_application`), 111 (`pricing_choose_method_page`), 113 (`pricing_import_page`); xoá route `/pricing/choose-method` (dòng ~1267–1271) và `/pricing/import` (~1277–1281); route `/pricing/:ruleId/edit` dùng `CustomerPriceRuleDetailDto` từ model mới |
| `core/di/injection.dart` | thêm `registerLazySingleton<CustomerPriceRuleRepository>` và `<SalesPricingRepository>` (cạnh các repository khác, `rpc: getIt<SupabaseRpc>(), tenantId: () => getIt<SessionController>().requireTenantId()`); xoá `PricingStartup.initialize(...)` + `registerSingleton<IPricingModule>` (dòng 195–203) và import dòng 5–6. `permissionChecker` / `tenantAccessChecker` / `executionContext` **giữ** (sales module còn dùng) |
| `docs/02-yeu-cau/TH-04-chinh-sach-gia.md` | phiên review sửa sau khi xong: EP-04 / PR-03 / PR-09 / KI-03 / kịch bản 5 / RPC nhập → ngoài phạm vi (Q9, Q10) |

**Không** đổi: `pricing_pick_{customer,product,unit}_page.dart` (6.3 đã xong ở 4-A / 5-A3); `apps/erp/pubspec.yaml` (`c45_pricing_*`, `file_picker` còn feature khác dùng); `modules/pricing`.

### 3.2 `test`

| Tệp | Hành động |
|---|---|
| `test/features/pricing/support/fake_pricing_backend.dart` | **tạo** (mục 4.5): chép phần dựng dữ liệu của `FakePricingModule` |
| `test/features/pricing/support/fake_customer_price_rule_repository.dart` | **tạo** (mục 4.5) |
| `test/features/sales/support/recording_sales_pricing_repository.dart` | **tạo** (mục 4.5) |
| `test/features/pricing/pricing_e2e_harness.dart` | `PricingE2eModule` → dùng `FakeCustomerPriceRuleRepository`; `setUpPricingE2E` đăng ký `CustomerPriceRuleRepository` thay `IPricingModule` + `IExecutionContext`; bỏ route choose-method / import, `importFileService` |
| `test/features/pricing/presentation_module/price_rule_list_cubit_test.dart`, `price_rule_history_sg06_test.dart` → `test/features/pricing/logic/` | `git mv`, đổi `_DelayedPricingModule` / `_ImmediatePricingModule` thành subclass của `FakeCustomerPriceRuleRepository` (giữ độ trễ / trả ngay) |
| `test/features/pricing/presentation/pages/pricing_{pages,form_e2e,lifecycle_e2e,list_detail_choose_e2e,import_history_e2e}_test.dart` | đổi cách dựng; xoá nhóm theo Q13; `pricing_import_history_e2e_test.dart` còn nhóm `e2e_e02_u10` ⇒ `git mv` thành `pricing_history_e2e_test.dart`; `_SystemErrorPricingModule` → fake ném `AppException(SYSTEM_ERROR)` |
| `test/features/sales/presentation/{sales_pricing_lookup,sales_draft_backend,sales_checkout_page}_test.dart`, `test/features/sales/sales_flow_pages_test.dart` | `_RecordingPricingModule` → `RecordingSalesPricingRepository` (+ `FakeCustomerPriceRuleRepository` cho "Lưu làm giá riêng"); đăng ký 2 repository thay `IPricingModule` |
| 4 tệp test nhập Excel / nhớ giá + `fixtures/` | **xoá** (Q13) |

## 4. Thiết kế

### 4.1 Cubit (`features/pricing/logic/`)

Chung cho 4 cubit: constructor nhận `required CustomerPriceRuleRepository repository` thay `IPricingModule` + `IExecutionContext`; bỏ mọi `requireTenantId()`; `executeQueryAsync(XQuery(tenantId: …, a: …))` → `_repository.x(a: …)` cùng tham số (bỏ `tenantId`); `on PricingBlockedException catch (e)` → `on AppException catch (e)`; `e.details[...]` → `e.details?[...]`; xoá các nhánh `on ApplicationException catch (e)` (repository đã đổi mọi lỗi sang `AppException`, kể cả thiếu phiên); nhánh `catch (_)` cuối **giữ** câu cũ. Câu lỗi: mục 4.2.

| Cubit | Lệnh cũ → method |
|---|---|
| `PriceRuleListCubit` | `SearchCustomerPriceRulesQuery` → `search(...)` (cùng `q`, `quickFilter`, `statuses`, `sources`, `customerId`, `productId`, `businessDate`, `cursor`, `limit`); bỏ field `canImport` khỏi `PriceRuleListState` và mọi chỗ truyền (`price_rule_list_cubit.dart:69,127,152,167,182`, `price_rule_list_state.dart:16,27,39,57,78,91`). Lọc / sắp xếp phía app (KI-05) **giữ nguyên** (6-B) |
| `PriceRuleDetailCubit` | detail → `getDetail`; history (limit 3) → `getHistory(limit: 3)`; `DisableCustomerPriceRuleCommand` → `disable`; precheck → `precheckReenable`; `ReenableCustomerPriceRuleCommand(…, acknowledgeOverwrite: true)` → `reenable(…, acknowledgeOverwrite: true)` (Q3: giờ mới tới server) |
| `PriceRuleFormCubit` | `CreateCustomerPriceRuleCommand` → `create` (`result.rule`); `UpdateCustomerPriceRuleCommand` → `update`; `reloadExistingRule` → `getDetail`. `_idempotencyKey` (`'form_<ms>'`, giữ suốt vòng đời cubit), `acknowledgeFloorWarning: form.isBelowFloor` giữ nguyên |
| `PriceRuleHistoryCubit` | field công khai `pricingModule`, `executionContext` → `repository`; detail → `getDetail`; history → `getHistory(cursor: …)` |

### 4.2 Câu lỗi (Q4)

Mã đã có câu riêng giữ câu đó (đưa vào `overrides`); chỉ đổi chỗ đang hiện `e.message` / mã thô.

| Chỗ | Cũ | Mới |
|---|---|---|
| `PriceRuleListCubit._messageForBlocked` | `validationError` → `e.message ?? 'Dữ liệu tìm kiếm không hợp lệ.'`; `systemError` → "Không thể tải dữ liệu…"; khác → `e.message ?? …` | `pricingErrorMessage(e, fallback: 'Không thể tải dữ liệu. Vui lòng thử lại.', overrides: {VALIDATION_ERROR: 'Dữ liệu tìm kiếm không hợp lệ.', SYSTEM_ERROR: 'Không thể tải dữ liệu. Vui lòng thử lại.'})` |
| `PriceRuleListCubit` nhánh `ApplicationException` (`e.message`) | | xoá (mục 4.1) |
| `PriceRuleDetailCubit._messageForBlocked` (tải) | tương tự, fallback "Không thể tải chi tiết…" | `pricingErrorMessage(e, fallback: 'Không thể tải chi tiết. Vui lòng thử lại.', overrides: {VALIDATION_ERROR: 'Dữ liệu không hợp lệ.', SYSTEM_ERROR: 'Không thể tải chi tiết. Vui lòng thử lại.'})` |
| `PriceRuleDetailCubit._messageForActionBlocked` | 9 mã có câu riêng (dòng 288–307); `validationError` → `e.message ?? …`; khác → `e.message ?? …` | `pricingErrorMessage(e, fallback: 'Không thể thực hiện thao tác. Vui lòng thử lại.', overrides: {<9 câu cũ, giữ nguyên chữ>, VALIDATION_ERROR: 'Dữ liệu không hợp lệ.'})` |
| `PriceRuleDetailCubit` 4 nhánh `ApplicationException` (`_actionErrorMessage = e.message`, `PriceRuleDetailError(message: e.message)`) | | xoá |
| `PriceRuleHistoryCubit` lỗi khác (`message: e.code`, dòng 90) và nhánh `ApplicationException` (`e.message`) | mã thô / câu thô | `pricingErrorMessage(e, fallback: 'Không thể tải lịch sử. Vui lòng thử lại.', overrides: {NOT_FOUND: 'Không tìm thấy giá riêng này.'})`; nhánh `NO_PERMISSION` giữ state riêng; `catch (e)` cuối giữ "Đã xảy ra lỗi không xác định" |
| `pricing_form_page.dart:_mapErrorToMessage` | `_ => 'Lỗi: $code'` | `_ => 'Không thể lưu giá riêng. Vui lòng thử lại.'` (các mã khác giữ câu) |
| `SalesPricingLookup._message` | `PricingBlockedException` → `message` tiếng Anh của server ?? "Thao tác giá bị từ chối."; khác → "Không thể kết nối dịch vụ giá…" | `pricingErrorMessage(error, fallback: 'Không thể kết nối dịch vụ giá. Vui lòng thử lại.')` |

### 4.3 Thêm mới từ danh sách (Q10)

```dart
Future<void> _openAddFlow(BuildContext context) async {
  final rule = await context.push<CustomerPriceRuleDetailDto>('/pricing/new');
  if (!context.mounted) return;
  if (rule != null) {
    await context.push('/pricing/${rule.id}');
    if (!context.mounted) return;
  }
  _cubit.refresh();
}
```

`PricingFormPage._onSuccess` đã `context.pop(rule)` khi `canPop` ⇒ không sửa form. FAB: `(isInitialError || !state.canCreate) ? null : …` (cũ: `!canCreate && !canImport`).

### 4.4 Sales

`sales_pricing_lookup.dart`:
- Bỏ import `c45_pricing_application`; import `package:erp/features/pricing/data/models.dart` với tiền tố `pricing` (giữ tên `pricing.X` ở thân, đỡ sửa), `customer_price_rule_repository.dart`, `sales_pricing_repository.dart`, `pricing_error_messages.dart`.
- `_preview`: `di<SalesPricingRepository>().preview(storeId: …, customerId: …, currencyCode: …, contextVersion: …, effectiveAt: …, lines: [pricing.SalesPricingLineInput(...)])`; phần dựng `SalesPricingPreviewResult` giữ nguyên. Bỏ `di<IExecutionContext>().requireTenantId()` (repository tự đọc).
- `_evaluate`: `di<SalesPricingRepository>().evaluateManualPrice(...)` cùng tham số.
- `_savePrivate`: `tenantId` **vẫn** lấy `di<IExecutionContext>().requireTenantId()` (là một phần khoá idempotency `sales-private-price-v1:<tenant>:…`, giữ nguyên chuỗi); **bỏ** `requireUserId()` (không còn cần `actorId`). `_resolve` / `_create` / `_update` nhận `CustomerPriceRuleRepository` thay `IPricingModule`: `resolveApplicable(customerId, productId, productUnitId, businessDate: request.effectiveFrom)`, `create(… idempotencyKey: key)`, `update(ruleId: existing.ruleId, expectedVersion: existing.version, …, acknowledgeOverwrite: true)`. Logic đọc lại / thử lại (`on Object` → `_resolve` → `_matches` → retry / rethrow) **giữ nguyên từng nhánh**.
- `_message`: mục 4.2.

`sales_draft_backend.dart`: `_previewPricing` → `di<SalesPricingRepository>().preview(...)` cùng tham số; `on Object → _PricingOutcome(failed: true…)` giữ; kiểu `pricing.SalesPricingLinePreviewDto` lấy từ model mới.

### 4.5 Fake

- `fake_pricing_backend.dart`: `enum FakePricingScenario` chép từ `modules/pricing/application/lib/src/testing/fake_pricing_module.dart:59-152` **bỏ** các giá trị `delete*`, `import*`, `memory*`. Lớp `FakePricingBackend` chép các hàm dựng dữ liệu (`_detail`, `_searchResult`, `_historyMixedItems`, `_updateDetail`, `_disableDetail`, `_reenablePrecheck`, `_reenableDetail`, `_result`…) và đổi `throw PricingBlockedException(code, details: d)` → `throw AppException(code, details: d)`. Nhánh theo scenario giữ đúng như `_handle<X>`.
- `FakeCustomerPriceRuleRepository extends CustomerPriceRuleRepository` (constructor `super(rpc: _unusedRpc, tenantId: () async => 'tenant-test')`, mẫu `test/features/partner/support/fake_partner_repository.dart:18`) với tham số scenario theo nhóm như `PricingE2eModule` hiện nay: `searchScenario`, `detailScenario`, `historyScenario`, `createScenario`, `updateScenario`, `disableScenario`, `reenableScenario`, `reenablePrecheckScenario`, `resolveScenario`; mặc định giống `PricingE2eModule`. Ghi `final List<FakePricingCall> calls` (`method`, `args` map) để test kiểm như đang kiểm `commands`.
- `RecordingSalesPricingRepository extends SalesPricingRepository`: ghi `previewCalls` / `evaluateCalls` (đối số), trả theo hàm `previewResponder` / `evaluateResponder` truyền vào (thay `_RecordingPricingModule` của 4 tệp sales; giữ đúng dữ liệu trả mà từng tệp đang dựng).

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| H1 | Danh sách → "+" → màn chọn cách → "Tạo thủ công" → form → lưu → màn chọn pop `rule.id` → danh sách push chi tiết → về thì `refresh` | **Đổi (Q10):** "+" → form → lưu → pop `rule` → push chi tiết → `refresh` | Bước 0: `e2e_add_flow_opens_detail_after_create` trên code cũ (đi qua màn chọn); sau sửa bỏ bước chạm "Tạo thủ công", giữ mọi kiểm: tới `wgt_e02_u04_fr01_01`, lưu xong thấy chi tiết, `searchCalls` tăng 1 sau khi về |
| H2 | Màn chọn: đọc `available_actions` (search `limit: 1`); không quyền tạo + không quyền nhập → "Không có quyền" | **Đổi (Q10):** nút thêm ẩn khi `!canCreate` (danh sách đã đọc `available_actions` ở lần search) | Bước 0: `wgt_list_fab_hidden_without_create` — search trả `availableActions: []` → không có FAB, trạng thái rỗng không có nút "Thêm giá riêng"; có `create_manual` → có cả hai |
| H3 | Màn chọn: lỗi đọc quyền → trang lỗi | bỏ (lỗi search đã hiện ở danh sách) | — (màn bị xoá; lỗi search phủ bởi `wgt_e02_u01_*` có sẵn) |
| H4 | Màn chọn mở thẳng bằng URL `/pricing/choose-method` | bỏ route; URL lạ → trang lỗi mặc định của go_router (`app_router.dart` không có `errorBuilder`), như mọi URL lạ khác | `router_pricing_removed_routes` (sau sửa): `/pricing/choose-method`, `/pricing/import` không còn trong `GoRouter.configuration.routes` |
| H5 | Cubit danh sách: phân trang + lọc app (`_applyClientOnlyFilters`, `_applySort`, `maxPages`) | giữ | `price_rule_list_cubit_test.dart` (có sẵn) + Bước 0: `list_aggregates_pages_until_filter_satisfied` nếu chưa có ca đi > 1 trang |
| H6 | Chi tiết: `NO_PERMISSION` → state riêng; `NOT_FOUND` → state riêng; khác → lỗi có câu | giữ (mã qua `AppException`) | Bước 0: `detail_maps_no_permission_not_found_error` (3 ca) |
| H7 | Chi tiết: lịch sử 3 dòng lỗi thì vẫn hiện chi tiết (`catch (_)`) | giữ | Bước 0: `detail_shows_rule_when_history_fails` |
| H8 | Tắt / bật lại lỗi: `_actionErrorMessage` + `emit(previous)` | giữ; câu theo 4.2 | `pricing_lifecycle_e2e_test.dart` (có sẵn) + Bước 0: `disable_error_restores_previous_and_sets_message` (`STATE_CHANGED` → "Dữ liệu đã thay đổi. Vui lòng tải lại và thử lại.") |
| H9 | Bật lại gửi `acknowledgeOverwrite: true` nhưng server nhận `false` | **Đổi có chủ đích (Q3)** | sau sửa: `reenable_passes_acknowledge_overwrite` — `FakeCustomerPriceRuleRepository.calls.last.args['acknowledgeOverwrite'] == true` (lớp mạng đã test ở 6-A1 D6) |
| H10 | Form: `DUPLICATE_ACTIVE_RULE` → hộp ghi đè → `confirmOverwrite` gửi `acknowledgeOverwrite: true`; `STATE_CHANGED` → `hasStateChanged`; `NO_PERMISSION` → state riêng; khác → toast câu `_mapErrorToMessage` | giữ; mã lạ đổi câu (4.2) | `pricing_form_e2e_test.dart` (có sẵn) + Bước 0: `form_duplicate_then_confirm_overwrite` (đếm 2 lần `create`, lần 2 `acknowledgeOverwrite: true`, cùng `idempotencyKey`) |
| H11 | Form tạo: một `idempotencyKey` cho cả lần thử lại / ghi đè | giữ | trong H10 |
| H12 | Lịch sử: `NO_PERMISSION` → state riêng, `NOT_FOUND` → "Không tìm thấy giá riêng này.", lỗi khác → **hiện mã** | `NO_PERMISSION`, `NOT_FOUND` giữ; **đổi (Q4)** lỗi khác → câu 6.4 | `price_rule_history_sg06_test.dart` (có sẵn) + Bước 0: `history_error_message_by_code` (sau sửa đổi kỳ vọng ca "lỗi khác" từ mã sang câu, ghi "đổi có chủ đích") |
| H13 | Sales xem trước: mọi lỗi → `SalesExternalOperationException(_message)`; `sales_draft_backend` mọi lỗi → `failed: true` | giữ; câu theo 4.2 | `sales_draft_backend_test.dart`, `sales_checkout_page_test.dart`, `sales_flow_pages_test.dart` (có sẵn) |
| H14 | "Lưu làm giá riêng": thiếu khách → lỗi trước mọi lần gọi; đã có giá riêng mà chưa xác nhận → `overwriteConfirmationRequired`; tạo / sửa lỗi → đọc lại, khớp thì coi như xong, không khớp thì thử lại (tạo) / ném lại (sửa); khoá idempotency `sales-private-price-v1:…` | giữ từng nhánh | `sales_pricing_lookup_test.dart` 7 ca (có sẵn): đổi fake, **giữ** mọi `expect` (kể cả chuỗi khoá) |
| H15 | Sales kiểm giá nhập tay đòi quyền client khi cần xác nhận | **Bỏ (Q6)** | `manual evaluation maps owner result without mutation` (có sẵn) |
| H16 | Sales hiện câu tiếng Anh của server | **Đổi (Q4)** | Bước 0: `lookup_error_message_uses_server_text` trên code cũ (ghi lại hành vi cũ), sau sửa đổi kỳ vọng: `AppException(BELOW_FLOOR_BLOCKED)` → "Giá nhập thấp hơn giá sàn quy định." |
| H17 | Router: `/pricing/:ruleId/edit` thiếu `extra` → về `/pricing` | giữ | Bước 0: `router_edit_without_extra_goes_list` nếu chưa có |
| H18 | Nhập Excel (PR-09), file mẫu, nhật ký | **Bỏ (Q9)** | — (xoá cùng test, Q13) |

**Bước 0 (Task 0):** viết các test "Bước 0" ở bảng trên **trên code cũ** (dùng `PricingE2eModule` / `FakePricingModule` hiện có), chạy xanh, ghi tên vào Kết quả. Task 4 đổi cách dựng sang fake mới, **không** đổi điều kiện kiểm, trừ ca ghi "đổi có chủ đích" (H1 bỏ bước chạm, H12, H16).

## 6. Các bước

> Viết theo `superpowers:writing-plans`. Thực hiện: `superpowers:executing-plans`. Mỗi task xong ghi ngay mục 9. **Không commit**.
> Trước mỗi symbol Dart sửa: `gitnexus impact` (upstream). `initDependencies`, `appRouter`, `SalesPricingLookup`, `SalesDraftBackend` có thể HIGH / CRITICAL: ghi blast radius vào Kết quả, báo người dùng, làm tiếp vì có H1–H17.

**Ràng buộc chung:**
- Không đổi giao diện ngoài: Q10 (luồng thêm), Q11 (một câu), các câu ở 4.2. Không đụng `pricing_pick_*_page.dart`.
- Không sửa lớp trong `features/pricing/data/` của 6-A1; thiếu gì thì ghi Kết quả rồi hỏi.
- Lọc / sắp xếp phía app, KI-02 / 05 / 07 / 08 / 10 / 13 / 14: **không** làm (6-B).

### Task 0: Test giữ hành vi trên code cũ

**Files:** thêm ca vào `test/features/pricing/presentation_module/price_rule_list_cubit_test.dart`, `price_rule_history_sg06_test.dart`, `test/features/pricing/presentation/pages/pricing_{list_detail_choose_e2e,lifecycle_e2e,form_e2e}_test.dart`, `test/features/sales/presentation/sales_pricing_lookup_test.dart`; tạo `test/features/pricing/logic/price_rule_detail_cubit_test.dart` (H6, H7, H8).

- [x] **0.1** Viết các test "Bước 0" ở bảng 5 (H1, H2, H5, H6, H7, H8, H10, H12, H16, H17). H1 trên code cũ: từ `/pricing` chạm FAB → chạm "Tạo thủ công" → điền form (mẫu `pricing_form_e2e_test.dart`) → lưu.
- [x] **0.2** `cd apps/erp && flutter test test/features/pricing test/features/sales` → PASS. Ghi tên test.

### Task 1: Fake mới

**Files:** Create `test/features/pricing/support/{fake_pricing_backend,fake_customer_price_rule_repository}.dart`, `test/features/sales/support/recording_sales_pricing_repository.dart`; Test `test/features/pricing/support/fake_customer_price_rule_repository_test.dart`.

**Consumes:** `CustomerPriceRuleRepository`, `SalesPricingRepository`, model (6-A1).
**Produces:** `FakeCustomerPriceRuleRepository({FakePricingScenario searchScenario = .searchRulesDefault, detailScenario = .ruleDetailActive, historyScenario = .historyMixedSources, createScenario = .createRuleOk, updateScenario = .updateRuleOk, disableScenario = .disableRuleOk, reenableScenario = .reenableOk, reenablePrecheckScenario = .reenablePrecheckValid, resolveScenario = .resolveApplicableOk})` + `List<FakePricingCall> calls`; `RecordingSalesPricingRepository({required Future<SalesWorkingStatePricingPreviewDto> Function(<đối số preview>) previewResponder, Future<SalesManualPriceEvaluationDto> Function(<đối số evaluate>)? evaluateResponder})` + `previewCalls`, `evaluateCalls`.

- [x] **1.1** Test fake: với mỗi scenario đang được test dùng (đếm ở `grep -rhoE "FakePricingScenario\.[a-zA-Z]+" test | sort -u`, bỏ `import*` / `memory*`), kết quả fake mới bằng `FakePricingModule` cũ (so field chính: `id`, `version`, `status`, `price.amountMinor`; lỗi: cùng `code` và `details`). Ghi chú: test này dùng module cũ ⇒ 6-C xoá cùng module.
- [x] **1.2** Viết fake. Chạy test 1.1 → PASS.

### Task 2: Cubit → `logic/` + trang pricing + xoá màn

**Files:** mục 3.1 hàng cubit, trang, màn chọn cách, nhập Excel, 18 tệp đổi import, `presentation.dart`.

- [ ] **2.1** `gitnexus impact` upstream `PriceRuleListCubit`, `PriceRuleDetailCubit`, `PriceRuleFormCubit`, `PriceRuleHistoryCubit`, `PriceRuleListState` → ghi bảng vào Kết quả.
- [ ] **2.2** `git mv` 8 tệp cubit / state sang `logic/`; sửa theo 4.1, 4.2. Bỏ `canImport` (4.1).
- [ ] **2.3** Sửa 4 trang (mục 3.1); `_openAddFlow` (4.3); Q11.
- [ ] **2.4** Xoá màn chọn cách + toàn bộ tệp nhập Excel (mục 3.1); sửa `presentation.dart`.
- [ ] **2.5** Đổi import 18 tệp còn lại; `git grep -n "c45_pricing" -- apps/erp/lib/features/pricing` → rỗng.
- [ ] **2.6** `dart analyze lib/features/pricing` → 0 lỗi.

### Task 3: Sales + router + DI

**Files:** `features/sales/presentation/lookups/sales_pricing_lookup.dart`, `features/sales/presentation/orchestration/sales_draft_backend.dart`, `core/router/app_router.dart`, `core/di/injection.dart`.

- [ ] **3.1** `gitnexus impact` upstream `SalesPricingLookup`, `SalesDraftBackend._previewPricing` (hoặc lớp chứa), `initDependencies`, `appRouter` → ghi Kết quả.
- [ ] **3.2** Sales theo 4.4. Router, DI theo mục 3.1.
- [ ] **3.3** `git grep -n "c45_pricing\|IPricingModule\|PricingStartup" -- apps/erp/lib` → rỗng. `dart analyze lib` → 0 lỗi.

### Task 4: Đổi test sang fake mới, xoá test theo Q13

**Files:** mục 3.2.

- [ ] **4.1** Đổi harness + mọi tệp test mục 3.2 sang `FakeCustomerPriceRuleRepository` / `RecordingSalesPricingRepository`; đăng ký `CustomerPriceRuleRepository` / `SalesPricingRepository` trong GetIt thay `IPricingModule`. Kiểm `commands.whereType<XCommand>()` → `calls.where((c) => c.method == 'x')`.
- [ ] **4.2** Xoá test theo Q13; `git mv` `pricing_import_history_e2e_test.dart` → `pricing_history_e2e_test.dart` (giữ nhóm `e2e_e02_u10`); `git mv` 2 test cubit sang `test/features/pricing/logic/`.
- [ ] **4.3** Sửa kỳ vọng các ca "đổi có chủ đích" (H1, H12, H16); thêm H4, H9.
- [ ] **4.4** `flutter test test/features/pricing test/features/sales` → PASS. Mọi test Bước 0 còn (tên giữ) và xanh.

### Task 5: Kiểm toàn bộ + Kết quả

- [ ] **5.1** `cd apps/erp && dart analyze lib test` → 0 lỗi; `dart run tool/check_feature_imports.dart` → không dòng mới.
- [ ] **5.2** `git grep -n "c45_pricing\|IPricingModule\|FakePricingModule" -- apps/erp/lib apps/erp/test` → chỉ còn `test/features/pricing/data/pricing_rpc_parity_test.dart`, `pricing_errors_test.dart` (nhóm `old` của 6-A1) và `test/features/pricing/support/fake_customer_price_rule_repository_test.dart` (1.1).
- [ ] **5.3** `flutter test` cả app → số lỗi đúng `docs/refactor/TEST-BASELINE.md` (so từng tên; test đã xoá theo Q13 mà có trong baseline thì ghi rõ).
- [ ] **5.4** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})` → ghi số tệp / symbol / luồng / rủi ro; đối chiếu chỉ có pricing, 2 tệp sales, router, DI.

## 7. Kiểm tra

### 7.1 Tự động

Task 5.

### 7.2 Kiểm tay (iPhone simulator + Chrome cửa sổ rộng và hẹp, Dev; người dùng)

1. Khác → Giá riêng: danh sách tải; tìm, lọc, sắp xếp như cũ.
2. "+" mở thẳng form (không còn màn "Chọn cách thêm"); tạo giá riêng → tới chi tiết; về danh sách thấy dòng mới.
3. Tạo trùng hiệu lực → hộp ghi đè → đồng ý → lưu được.
4. Chi tiết → Thao tác → Tắt → Bật lại một giá riêng đang trùng với giá khác → **bật được** (Q3; trước đây báo trùng).
5. Lịch sử hiện; lỗi (tắt mạng) hiện câu tiếng Việt, không hiện mã.
6. Bán hàng: chọn khách có giá riêng → dòng dùng giá riêng; sửa giá tay dưới sàn → hỏi xác nhận; "Lưu làm giá riêng" → lưu được, mở lại thấy hỏi ghi đè.
7. Gõ `/pricing/import`, `/pricing/choose-method` trên Chrome → trang lỗi mặc định của go_router (như mọi URL lạ).

## 8. Rủi ro / lưu ý

- Xoá ~20 tệp `lib` + 4 tệp test: `detect_changes` phải chỉ ra đúng pricing / sales / router / DI.
- `PriceRuleListState` bỏ `canImport`: widget nào đọc field này phải đổi (đo `grep -rn canImport lib` 2026-11-04: chỉ `price_rule_list_{cubit,state}.dart`, `pricing_list_page.dart:92`).
- Test sales dựng dữ liệu xem trước giá bằng tay ở 4 tệp: đổi sang responder phải giữ đúng số.
- Theme 4 chưa có plan web (`6-W`) trong PLAN.md; bố cục web của pricing để plan đó (quy tắc Thiết bị).

### Review Focus (chưa task nào test, phiên review soi)

1. Tạo từ danh sách trên Chrome khi form mở bằng URL trực tiếp (`/pricing/new`, không `canPop`): `_onSuccess` `go('/pricing/<id>')` — vẫn đúng sau khi bỏ màn chọn.
2. Đổi tổ chức khi đang ở danh sách giá riêng: repository đọc `tenantId` mỗi lần gọi (6-A1) ⇒ lần tải sau lấy tổ chức mới.
3. Sales "Lưu làm giá riêng" khi mất mạng giữa chừng: nhánh đọc lại / thử lại giữ đúng (H14) và câu lỗi không lộ tiếng Anh.
4. Câu lỗi bật lại khi giá riêng đã hết hiệu lực: `INVALID_STATUS` → "Không thể thực hiện với trạng thái hiện tại." (6.4 có câu riêng "Giá riêng đã hết hiệu lực…" nhưng do `messageForPrecheckBlocked` xử lý ở bước kiểm trước — kiểm còn chạy).
5. Màn chi tiết mở bằng deep link khi danh sách chưa tải: không phụ thuộc `canCreate`.

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi task** ghi ngay (không dồn cuối), theo mẫu:
> - **Task N — ✅ / 🔄 dở (tới bước …) / ⏭ (lý do)**
> - Tệp:dòng đã đổi / xoá / thêm
> - Lệch so với plan + lý do
> - Test thêm / sửa / xoá (tên) + kết quả chạy
> - Impact (`gitnexus impact`): bảng symbol / risk / direct / impacted / luồng — số lấy từ lệnh, ghi lệnh + thời điểm index
> - Ghi chú cho review
>
> Task 5 ghi thêm: lệnh đã chạy, pass / fail, tên test hỏng đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes()`.

### Task 0 — ✅

- **Tệp:dòng đã đổi / thêm:**
  - `apps/erp/test/features/pricing/pricing_e2e_harness.dart:21–138` (thêm `searchAvailableActions`, `searchCalls`, `createScenario` mutable).
  - `apps/erp/test/features/pricing/presentation/pages/pricing_list_detail_choose_e2e_test.dart:1–160` (thêm H1, H2, H17).
  - `apps/erp/test/features/pricing/presentation_module/price_rule_list_cubit_test.dart:1–240` (thêm H5).
  - `apps/erp/test/features/pricing/logic/price_rule_detail_cubit_test.dart:1–107` (tạo mới: H6, H7, H8).
  - `apps/erp/test/features/pricing/presentation/pages/pricing_lifecycle_e2e_test.dart:46–89` (thêm H8 trên màn chi tiết).
  - `apps/erp/test/features/pricing/presentation/pages/pricing_form_e2e_test.dart:132–184` (thêm H10 + H11).
  - `apps/erp/test/features/pricing/presentation_module/price_rule_history_sg06_test.dart:190–243` (thêm H12).
  - `apps/erp/test/features/sales/presentation/sales_pricing_lookup_test.dart:149–215` (thêm H16).
- **Lệch so với plan:** Không. Đã rà chữ ký 6-A1 (`CustomerPriceRuleRepository`, `SalesPricingRepository`, `PricingErrorCodes`, `pricingErrorMessage`, `models.dart`) — khớp 100% với mục 4.
- **Test thêm + kết quả chạy:** `cd apps/erp && flutter test test/features/pricing test/features/sales` → 894 PASS / 11 lỗi có sẵn trong `TEST-BASELINE.md`:
  - `e2e_add_flow_opens_detail_after_create` (H1) — PASS
  - `wgt_list_fab_hidden_without_create` (H2) — PASS
  - `router_edit_without_extra_goes_list` (H17) — PASS
  - `list_aggregates_pages_until_filter_satisfied` (H5) — PASS
  - `detail_maps_no_permission_not_found_error` (H6) — PASS
  - `detail_shows_rule_when_history_fails` (H7) — PASS
  - `disable_error_restores_previous_and_sets_message` (H8, cubit + e2e) — PASS
  - `form_duplicate_then_confirm_overwrite` (H10, H11) — PASS
  - `history_error_message_by_code` (H12) — PASS
  - `lookup_error_message_uses_server_text` (H16) — PASS
- **Impact:** Chỉ thêm/mở rộng tệp test, chưa sửa symbol trong `lib/`.
- **Ghi chú cho review:** 11 test lỗi khi chạy `test/features/pricing test/features/sales` đều nằm nguyên trong `TEST-BASELINE.md` dòng 110–120 (trong đó 4 test của `pricing_import_history_e2e_test.dart` và `pricing_pages_test.dart` nhóm `wgt_e02_u05` sẽ xoá ở Task 4 theo Q13).

### Task 1 — ✅

- **Tệp:dòng đã thêm:**
  - `apps/erp/test/features/pricing/support/fake_pricing_backend.dart:1–787` (`FakePricingScenario` bỏ `delete*`, `import*`, `memory*`; `FakePricingBackend` chép dữ liệu từ `FakePricingModule` và ném `AppException`).
  - `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository.dart:1–258` (`FakeCustomerPriceRuleRepository` + `FakePricingCall` + `searchAvailableActions` + `searchCalls`).
  - `apps/erp/test/features/sales/support/recording_sales_pricing_repository.dart:1–156` (`RecordingSalesPricingRepository` + `SalesPricingPreviewCall` + `SalesManualPriceEvaluateCall`).
  - `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository_test.dart:1–397` (parity 19 scenario đang dùng với `FakePricingModule`).
- **Lệch so với plan:** Không.
- **Test thêm + kết quả chạy:** `cd apps/erp && flutter test --no-pub test/features/pricing/support/fake_customer_price_rule_repository_test.dart` → **7 PASS**.
- **Impact:** Chỉ thêm tệp trong `test/`.
- **Ghi chú cho review:** `fake_customer_price_rule_repository_test.dart` dùng `c45_pricing_application/testing.dart` để đối chiếu; sẽ xoá ở 6-C cùng module.

### Task 2 — ✅

- **Tệp:dòng đã đổi / thêm / xoá:**
  - `git mv` 8 tệp `apps/erp/lib/features/pricing/presentation/cubit/price_rule_{list,detail,form,history}_{cubit,state}.dart` → `apps/erp/lib/features/pricing/logic/`, đổi sang `CustomerPriceRuleRepository`, `AppException`, `PricingErrorCodes`, `pricingErrorMessage` (TH-04 6.4), bỏ `IPricingModule`, `IExecutionContext`, `canImport`.
  - `apps/erp/lib/features/pricing/logic/price_rule_list_filters.dart:1–92` (chuyển nội dung từ `presentation/models/price_rule_list_filters.dart` sang `logic/` và giữ re-export ở `presentation/models/price_rule_list_filters.dart` để `logic/` không import `presentation/` — tránh vi phạm R2 của `tool/check_feature_imports.dart`).
  - `apps/erp/lib/features/pricing/presentation/pages/pricing_{list,detail,form,history}_page.dart` (nhận `CustomerPriceRuleRepository` từ `GetIt`, `PricingListPage._openAddFlow` mở thẳng `/pricing/new`, FAB ẩn khi `!state.canCreate`, empty state `'Tạo giá riêng để bắt đầu.'`, `PricingFormPage._mapErrorToMessage` fallback `'Không thể lưu giá riêng. Vui lòng thử lại.'`).
  - `git rm` 15 tệp: `pricing_choose_method_page.dart` + 14 tệp import Excel (`pages/pricing_import_page.dart`, `cubit/price_rule_import_{cubit,state}.dart`, `formatters/price_rule_import_issue_formatter.dart`, `services/pricing_import_{file_service,log_xlsx_builder}.dart`, `widgets/price_rule_import_{wizard,choose_file,preview,confirm,result,issue_detail_sheet,shared}.dart`, `widgets/pricing_import_cancel_dialog.dart`).
  - `apps/erp/lib/features/pricing/presentation.dart:1–35` và 16 widget trong `apps/erp/lib/features/pricing/presentation/widgets/` (đổi import sang `data/models.dart` và `logic/`).
- **Lệch so với plan:**
  1. Ở 6-A1, `pricing_error_messages.dart` được đặt tại `features/pricing/logic/pricing_error_messages.dart` (không phải `data/`), và `AppException` tại `core/errors/app_exception.dart` (không có barrel `core/errors/errors.dart`) → các cubit import đúng đường dẫn thực tế của 6-A1.
  2. Tách phần định nghĩa `price_rule_list_filters.dart` sang `logic/price_rule_list_filters.dart` và giữ re-export tại `presentation/models/price_rule_list_filters.dart` để không phát sinh vi phạm `R2` (`logic/ → presentation/`) khi chạy `tool/check_feature_imports.dart`.
- **Kiểm chứng:** `git grep -n "c45_pricing" -- apps/erp/lib/features/pricing` rỗng; `cd apps/erp && dart analyze lib/features/pricing` → **0 error, 0 warning**.
- **Impact (GitNexus upstream):**
  - `PriceRuleListCubit`: class risk `CRITICAL` (`direct: 812`, `impacted: 1038`); constructor risk `LOW` (`direct: 0`, `impacted: 0`).
  - `PriceRuleDetailCubit`: class risk `CRITICAL` (`direct: 812`, `impacted: 1038`); constructor risk `LOW` (`direct: 0`, `impacted: 0`).
  - `PriceRuleFormCubit`: class risk `CRITICAL` (`direct: 812`, `impacted: 1038`); constructor risk `LOW` (`direct: 0`, `impacted: 0`).
  - `PriceRuleHistoryCubit`: class risk `CRITICAL` (`direct: 815`, `impacted: 1041`); constructor risk `LOW` (`direct: 0`, `impacted: 0`).
  - `PriceRuleListState`: risk `CRITICAL` (`direct: 812`, `impacted: 1038`, `processes_affected: 75`).
- **Ghi chú cho review:** Đã cảnh báo và kiểm tra toàn bộ caller của 4 cubit + `PriceRuleListState` trong `lib/` và `test/`.

### Task 3 — ✅

- **Tệp:dòng đã đổi:**
  - `apps/erp/lib/features/sales/presentation/lookups/sales_pricing_lookup.dart:1–295` (chuyển sang `SalesPricingRepository`, `CustomerPriceRuleRepository`, `SessionController`, `pricingErrorMessage` theo TH-04 6.4).
  - `apps/erp/lib/features/sales/presentation/orchestration/sales_draft_backend.dart:1–631` (chuyển `_previewPricing` sang `SalesPricingRepository.preview` và `pricing.SalesPricingLineInput` từ `features/pricing/data/models.dart`).
  - `apps/erp/lib/core/router/app_router.dart:1–1347` (xoá import & route `/pricing/choose-method`, `/pricing/import`; đổi import sang `features/pricing/data/models.dart`).
  - `apps/erp/lib/core/di/injection.dart:1–215` (xoá `PricingStartup` / `IPricingModule`, đăng ký lazy singleton `CustomerPriceRuleRepository` và `SalesPricingRepository`).
- **Lệch so với plan:** Chữ ký thực tế của 6-A1 (`CustomerPriceRuleRepository({required rpc, required tenantId})`, `SalesPricingRepository({required rpc, required tenantId})` với `preview({required storeId, ...})` và `evaluateManualPrice({required storeId, ...})`, `CreateCustomerPriceRuleResult`) không nhận `actorId` hay `storeId` trong constructor mà truyền `storeId` vào method — đã nối đúng theo chữ ký thực tế của 6-A1.
- **Kiểm chứng:** `git grep -n "c45_pricing\|IPricingModule\|PricingStartup" -- apps/erp/lib` rỗng; `cd apps/erp && dart analyze lib` → **0 error, 0 warning**.
- **Lệch bổ sung (ghi theo R1-2, 2026-11-05; phiên review ghi theo yêu cầu người dùng):**
  1. `sales_pricing_lookup.dart:138` — `_savePrivate` lấy `tenantId` từ `SessionController.requireTenantId()` thay vì `IExecutionContext` (mục 4.4). Cùng giá trị tenant; chuỗi khoá idempotency `sales-private-price-v1:<tenant>:…` không đổi.
  2. `sales_pricing_lookup.dart:290-292` — `_message`: `AppException` → `pricingErrorMessage(error, fallback: 'Thao tác giá bị từ chối.')`; lỗi khác → "Không thể kết nối dịch vụ giá. Vui lòng thử lại." (mục 4.2 ghi một `fallback` "Không thể kết nối…" cho mọi lỗi). Giữ đúng câu cũ cho mã lạ; repository luôn ném `AppException` nên nhánh "khác" thực tế không tới.
- **Impact (GitNexus upstream):**
  - `SalesPricingLookup`: risk `LOW` (`direct: 0`, `impacted: 0`).
  - `SalesDraftBackend`: risk `LOW` (`direct: 0`, `impacted: 0`).
  - `initDependencies`: risk `CRITICAL` (`maxImpactedCount: 1571`, `direct: 1123`).
  - `appRouter`: risk `LOW` (`maxImpactedCount: 0`, `direct: 0`).
- **Ghi chú cho review:** Đã cảnh báo blast radius `CRITICAL` của `initDependencies` và kiểm tra mọi nơi lấy `CustomerPriceRuleRepository` / `SalesPricingRepository` qua GetIt.
- **Lệch thêm (ghi theo R1-2, không sửa code):**
  1. `SalesPricingLookup._savePrivate` (`sales_pricing_lookup.dart:138`) lấy `tenantId` từ `SessionController.requireTenantId()` thay vì `IExecutionContext` như mục 4.4 — cùng giá trị tenant.
  2. `SalesPricingLookup._message` (`sales_pricing_lookup.dart:290-292`) giữ `fallback: 'Thao tác giá bị từ chối.'` cho `AppException` (đúng câu bản cũ cho mã lạ) thay vì `'Không thể kết nối dịch vụ giá…'` ở mục 4.2; lỗi không phải `AppException` vẫn dùng câu kết nối.

### Task 4 — ✅

- **Tệp:dòng đã đổi / di chuyển / xoá:**
  - `git rm` 7 tệp test/fixture tính năng đã bỏ: `test/features/pricing/presentation_module/price_rule_import_{cubit,widgets}_test.dart`, `test/features/pricing/remembered_price_mediator_e2e_test.dart`, `test/features/pricing/fixtures/{4 tệp xlsx}`.
  - `git mv` `test/features/pricing/presentation_module/price_rule_list_cubit_test.dart` → `test/features/pricing/logic/price_rule_list_cubit_test.dart`, `test/features/pricing/presentation_module/price_rule_history_sg06_test.dart` → `test/features/pricing/logic/price_rule_history_sg06_test.dart`, `test/features/pricing/presentation/pages/pricing_import_history_e2e_test.dart` → `test/features/pricing/presentation/pages/pricing_history_e2e_test.dart`.
  - `apps/erp/test/features/pricing/pricing_e2e_harness.dart:1–145` (đổi sang `FakeCustomerPriceRuleRepository`, bỏ route `/pricing/choose-method` và `/pricing/import`).
  - `apps/erp/test/features/pricing/logic/price_rule_list_cubit_test.dart:1–216`, `apps/erp/test/features/pricing/logic/price_rule_detail_cubit_test.dart:1–127` (thêm H9 `reenable_passes_acknowledge_overwrite`), `apps/erp/test/features/pricing/logic/price_rule_history_sg06_test.dart:1–245` (cập nhật H12 `'Đã xảy ra lỗi. Vui lòng thử lại.'`).
  - `apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart:1–486` (cập nhật H3 `'Tạo giá riêng để bắt đầu.'`, bỏ nhóm `wgt_e02_u02` và `wgt_e02_u05`), `pricing_list_detail_choose_e2e_test.dart:1–156` (cập nhật H1 vào thẳng `/pricing/new`, bỏ nhóm `e2e_e02_u02`, thêm H4 `router_pricing_removed_routes`), `pricing_form_e2e_test.dart:1–337`, `pricing_lifecycle_e2e_test.dart:1–245`, `pricing_history_e2e_test.dart:1–57` (bỏ nhóm `e2e_e02_u05`).
  - `apps/erp/test/features/sales/presentation/sales_pricing_lookup_test.dart:1–396` (đổi sang `FakeCustomerPriceRuleRepository` + `RecordingSalesPricingRepository`, cập nhật H16 `'Giá nhập thấp hơn giá sàn quy định.'`), `sales_draft_backend_test.dart:1–610`, `sales_checkout_page_test.dart:1–912`, `test/features/sales/sales_flow_pages_test.dart:1–1706` (đổi sang `RecordingSalesPricingRepository`).
- **Lệch so với plan:**
  1. `remembered_price_mediator_e2e_test.dart` nằm tại `test/features/pricing/remembered_price_mediator_e2e_test.dart` (không phải `presentation/pages/`).
  2. Cập nhật thêm `sales_checkout_page_test.dart` và `sales_flow_pages_test.dart` (đăng ký `SalesPricingRepository` bằng `RecordingSalesPricingRepository` thay cho `_RecordingPricingModule` / `IPricingModule` vì `SalesOrderComposePage` tạo `SalesDraftBackend` mặc định lấy `SalesPricingRepository` từ `GetIt`).
- **Test thêm/cập nhật + kết quả chạy:** `cd apps/erp && flutter test --no-pub test/features/pricing test/features/sales` → **854 PASS / 7 lỗi có sẵn trong `TEST-BASELINE.md`** (4 lỗi baseline của `pricing_import_history_e2e_test` (3) và `pricing_pages_test` nhóm `wgt_e02_u05` (1) đã xoá cùng tính năng import Excel theo Q13). Toàn bộ test mới/cập nhật (H1–H17) đều PASS.
- **Impact:** Chỉ sửa tệp trong `test/`.
- **Ghi chú cho review:** Không còn bất kỳ tham chiếu `c45_pricing`, `IPricingModule`, `FakePricingModule` nào trong `apps/erp/lib` và `apps/erp/test` (ngoài `test/features/pricing/support/fake_customer_price_rule_repository_test.dart`).

### Task 5 — ✅

- **5.1 Phân tích tĩnh & kiểm phụ thuộc lớp:**
  - `cd apps/erp && dart analyze lib/features/pricing test/features/pricing lib/features/sales/presentation/lookups/sales_pricing_lookup.dart lib/features/sales/presentation/orchestration/sales_draft_backend.dart test/features/sales/presentation/sales_pricing_lookup_test.dart test/features/sales/presentation/sales_draft_backend_test.dart test/features/sales/support/recording_sales_pricing_repository.dart lib/core/router/app_router.dart lib/core/di/injection.dart` → **0 error, 0 warning** (110 info `deprecated_member_use` / `prefer_conditional_assignment` có sẵn).
  - `cd apps/erp && dart analyze lib test` → **0 error**, 1 warning có sẵn ngoài phạm vi (`test/features/sales/presentation/order_einvoice_section_test.dart:32:28`).
  - `cd apps/erp && dart run tool/check_feature_imports.dart` → không phát sinh vi phạm `R1` hay `R2` mới từ 6-A2 (`pricing/logic/` 0 vi phạm nhờ tách `logic/price_rule_list_filters.dart`); ghi nhận 1 dòng `R3` tại `lib/features/sales/presentation/lookups/sales_pricing_lookup.dart:7` (`package:erp/features/pricing/logic/pricing_error_messages.dart`) — giống hệt mẫu `sales_catalog_product_lookup.dart:5` (`package:erp/features/catalog/logic/catalog_error_messages.dart`) vì `pricing_error_messages.dart` được đặt ở `logic/` từ 6-A1 và 6-A2 không sửa `features/pricing/data/`.
- **5.2 Kiểm tra còn sót `c45_pricing` / `IPricingModule` / `FakePricingModule`:**
  - `git grep -n "c45_pricing\|IPricingModule\|FakePricingModule" -- apps/erp/lib apps/erp/test` → chỉ còn trong `test/features/pricing/data/pricing_rpc_parity_test.dart` và `test/features/pricing/support/fake_customer_price_rule_repository_test.dart` (tệp untracked từ 6-A1 / Task 1, xoá ở 6-C); trên các tệp tracked là **0 kết quả**.
- **5.3 Chạy toàn bộ test `apps/erp` đối chiếu `TEST-BASELINE.md`:**
  - `cd apps/erp && flutter test --no-pub -r compact` → **2.280 PASS / 55 FAIL** (giảm 4 lỗi baseline so với mốc 59 lỗi sau 5-C nhờ xoá 3 test `pricing_import_history_e2e_test.dart` và 1 test `pricing_pages_test.dart` nhóm `wgt_e02_u05` theo Q13).
  - Đối chiếu 55 test lỗi: 53 lỗi nằm nguyên trong `TEST-BASELINE.md` (trong đó 7 lỗi của pricing: 1 ở `pricing_form_e2e_test.dart` và 6 ở `pricing_pages_test.dart`) + 2 lỗi catalog PCC đã ghi nhận ở đầu `TEST-BASELINE.md` sau 5-C (`product_guided_create_e2e_test.dart: e2e_e02_u01_fr01_01` và `product_change_history_e2e_test.dart: e2e_e07_u04_fr02_01`). **0 lỗi mới do 6-A2.**
- **5.4 GitNexus `analyze` & `detect_changes`:**
  - `node .gitnexus/run.cjs analyze --repair-fts --skip-agents-md` + `node .gitnexus/run.cjs analyze --skip-agents-md` → `50,488 nodes | 111,897 edges | 1251 clusters | 300 flows`.
  - `node .gitnexus/run.cjs detect_changes --repo erp-sales-inventory` → `Changes: 50 files, 59 symbols | Affected processes: 1 (Build → PriceRuleHistoryLoading) | Risk level: medium` — toàn bộ symbol thay đổi nằm đúng trong phạm vi 6-A1/6-A2.

### R1 — sửa (2026-11-05)

> Phiên review ghi theo yêu cầu người dùng, từ diff đã kiểm ở R2.

- **Tệp:dòng đã đổi:**
  - `apps/erp/lib/features/pricing/logic/price_rule_history_state.dart`, `apps/erp/lib/features/pricing/logic/price_rule_detail_state.dart` — trả về đúng nội dung `HEAD` (`presentation/cubit/…`), chỉ đổi dòng 2 thành `import '../data/models.dart';` (R1-1).
  - `apps/erp/test/features/pricing/logic/price_rule_history_sg06_test.dart:243-275` — thêm `history_loaded_keeps_sensitive_permission`, `history_no_permission_stops_paging` (R1-1).
  - `apps/erp/test/features/pricing/presentation/pages/pricing_history_e2e_test.dart:38-66` — thêm `history_page_activity_sheet_shows_floor_diff` (R1-1).
  - Kết quả Task 3: thêm mục "Lệch bổ sung" (R1-2).
- **Lệnh đã chạy + kết quả:** `cd apps/erp && dart analyze lib/features/pricing lib/features/sales test/features/pricing test/features/sales` → 0 lỗi (1 cảnh báo có sẵn `order_einvoice_section_test.dart:32`); `flutter test --no-pub test/features/pricing test/features/sales` → 877 đạt / 7 lỗi, cả 7 trong `TEST-BASELINE.md`; 2 tệp test có 3 ca mới → 11 đạt.
- **Impact:** 2 lớp state trả về đúng bản cũ (không đổi chữ ký so với `HEAD`), không có symbol mới.

## 10. Review

### R3 — 2026-11-05 — **ĐẠT**

R2-1 đã làm (phiên review ghi theo yêu cầu người dùng): Kết quả Task 3 có mục "Lệch bổ sung", mục 9 có "R1 — sửa". Code không đổi so với R2 (đã đạt). Còn lại: người dùng chạy `detect_changes()` rồi commit 6-A1 + 6-A2; kiểm tay 7.2 (iPhone + Chrome). TH-04 đã sửa theo Q9 / Q10 (xem PLAN.md Theme 4).

### R2 — 2026-11-05 — **CHƯA ĐẠT** (code đạt; chỉ còn thiếu ghi chép)

| # | Kết quả |
|---|---|
| R1-1 | ✅ `logic/price_rule_history_state.dart`, `logic/price_rule_detail_state.dart` so `git show HEAD:` chỉ khác đúng 1 dòng import. 3 test mới có và đạt: `history_loaded_keeps_sensitive_permission`, `history_no_permission_stops_paging` (`test/features/pricing/logic/price_rule_history_sg06_test.dart:243,254`), `history_page_activity_sheet_shows_floor_diff` (`test/features/pricing/presentation/pages/pricing_history_e2e_test.dart:39`) |
| R1-2 | ❌ **chưa làm**: Kết quả Task 3 vẫn chưa ghi 2 lệch (a) `tenantId` lấy từ `SessionController.requireTenantId()`, (b) `_message` giữ câu dự phòng "Thao tác giá bị từ chối." cho `AppException` |
| Ghi chép lượt sửa R1 | ❌ mục 9 không có phần "R1 — sửa" (tệp:dòng đã đổi, test thêm, lệnh đã chạy) theo mẫu mục 9 |

Review chạy lại: `dart analyze lib/features/{pricing,sales} test/features/{pricing,sales}` → 0 lỗi (1 cảnh báo có sẵn `order_einvoice_section_test.dart:32`); `flutter test test/features/pricing test/features/sales` → 877 đạt / 7 lỗi, cả 7 trong baseline.

**R2 — việc cần sửa:** R2-1 — làm R1-2 (ghi 2 lệch vào Kết quả Task 3) và thêm mục "R1 — sửa" vào mục 9. Không sửa code.

### R1 — 2026-11-04 — **CHƯA ĐẠT**

**Chưa đạt ở 2 chỗ** (còn lại đều đạt, xem bảng "Phần đạt"):

| # | Chưa đạt ở đâu | Sai gì | Yêu cầu nào bị vi phạm |
|---|---|---|---|
| R1-1 | `lib/features/pricing/logic/price_rule_history_state.dart:12` (và cả tệp), `lib/features/pricing/logic/price_rule_detail_state.dart:30,53,62` | Hai tệp state bị sửa thân, không chỉ đổi import. **Lỗi thấy được:** `hasSensitivePermission` mặc định đổi `true` → `false`. `PriceRuleHistoryCubit` không truyền giá trị này khi emit `Loaded`, nên màn Lịch sử (`pricing_history_page.dart:61`) luôn nhận `false`. Mở một hoạt động bất kỳ: sheet hiện banner "Quyền hạn chế — Bạn không có quyền xem một số dữ liệu nhạy cảm." và "Chênh lệch giá sàn" thành "Ẩn theo quyền 🔒" (`price_rule_activity_detail_sheet.dart:78,166-173`), với **mọi** người dùng. Bản cũ hiện đủ (TH-04 7.2: mọi thành viên xem được giá sàn). Thay đổi khác cùng tệp: `NoPermission` bỏ `hasReachedMax: true` (giờ `false` ⇒ `fetchHistory` không còn bị chặn sau khi không có quyền); `isFirstLoad` mặc định `false` → `true`; `items` / `nextCursor` / `hasReachedMax` thành tuỳ chọn; `final class` → `class`; `props` dùng cả `ruleContext` thay `ruleContext?.id`. `price_rule_detail_state.dart`: `props` đổi từ `[rule.id, rule.version, rule.persistedStatus, recentActivities.length]` sang `[rule, recentActivities]` (đổi cách Bloc bỏ qua state trùng), `PriceRuleDetailActionSuccess` thêm field bắt buộc `actionMessage`. Kết quả Task 2 ghi "Lệch: không" | Mục 3.1 (state chỉ `git mv` + đổi import); ràng buộc chung "không đổi giao diện ngoài"; mục 1 "giữ nghiệp vụ" |
| R1-2 | `lib/features/sales/presentation/lookups/sales_pricing_lookup.dart:138,290-292` | 2 chỗ làm khác plan nhưng Kết quả không ghi: (a) `_savePrivate` lấy `tenantId` từ `SessionController.requireTenantId()` thay vì `IExecutionContext` như mục 4.4; (b) `_message` giữ câu "Thao tác giá bị từ chối." làm `fallback` cho `AppException`, mục 4.2 ghi `fallback: 'Không thể kết nối dịch vụ giá…'` cho mọi lỗi. Cả hai đều chấp nhận được (cùng giá trị tenant; câu giữ đúng bản cũ cho mã lạ) | Ràng buộc "lệch plan thì ghi Kết quả" (mẫu mục 9) |

**R1 — việc cần sửa:**

- **R1-1 — Trả 2 tệp state về như cũ, chỉ đổi import.** Lấy `git show HEAD:apps/erp/lib/features/pricing/presentation/cubit/price_rule_history_state.dart` và `…/price_rule_detail_state.dart`, chỉ thay `import 'package:c45_pricing_application/application.dart';` bằng `import '../data/models.dart';`. Sửa nơi gọi nếu có dùng các tham số mới tuỳ chọn (đo bằng `dart analyze`). Thêm test:
  - `history_loaded_keeps_sensitive_permission` (`test/features/pricing/logic/price_rule_history_sg06_test.dart`): `fetchHistory()` với fake mặc định ⇒ `state.hasSensitivePermission == true`.
  - `history_page_activity_sheet_shows_floor_diff` (widget, màn `/pricing/<id>/history` qua harness): mở một hoạt động `updated` ⇒ **không** có "Quyền hạn chế", **không** có "Ẩn theo quyền 🔒".
  - `history_no_permission_stops_paging`: sau `PriceRuleHistoryNoPermission`, gọi `fetchHistory()` lần nữa ⇒ fake không nhận thêm lần gọi `getHistory`.
- **R1-2 — Ghi 2 lệch ở trên vào Kết quả Task 3** (không sửa code).

**Phần đạt:**

| Hạng mục | Kết quả |
|---|---|
| 4 cubit (`list`, `detail`, `form`, `history`) | ✅ so `git show HEAD:` từng dòng: chỉ đổi `IPricingModule` → repository, bỏ `tenantId`, `PricingBlockedException` → `AppException`, bỏ nhánh `ApplicationException`, câu lỗi theo 4.2 (giữ đủ 9 câu riêng của `_messageForActionBlocked`), bỏ `canImport`. `reenable` gửi `acknowledgeOverwrite: true` (Q3). `PriceRuleListState`, `PriceRuleFormState` chỉ đổi import / bỏ `canImport` |
| 4 trang | ✅ `_openAddFlow` đúng 4.3; FAB theo `canCreate`; câu rỗng Q11; `_mapErrorToMessage` mã lạ → "Không thể lưu giá riêng. Vui lòng thử lại." |
| 16 widget đổi import | ✅ ngoài dòng `import` không có dòng nào khác bị sửa |
| `price_rule_list_filters.dart` chuyển sang `logic/` + re-export | ✅ nội dung giữ nguyên; lệch có ghi, hợp lý (tránh R2) |
| Xoá màn chọn cách + 14 tệp nhập Excel, `presentation.dart` | ✅ |
| Sales (`sales_pricing_lookup`, `sales_draft_backend`) | ✅ tham số preview / evaluate / resolve / create / update giữ nguyên; nhánh đọc lại / thử lại giữ từng nhánh; khoá idempotency giữ chuỗi; bỏ `actorId`. Trừ R1-2 |
| Router, DI | ✅ bỏ 2 route + 2 import; 2 `registerLazySingleton` đúng mẫu; bỏ `PricingStartup` |
| `dart analyze lib test` | ✅ 0 lỗi; 1 cảnh báo có sẵn (`order_einvoice_section_test.dart:32`) |
| `check_feature_imports` | ✅ (chấp nhận) chỉ 2 dòng `R1` của 6-A1 và 1 dòng `R3` `sales_pricing_lookup.dart:7` (cùng mẫu `sales_catalog_product_lookup.dart:5`), Kết quả đã ghi |
| `git grep c45_pricing\|IPricingModule\|FakePricingModule\|PricingStartup` | ✅ `lib`: rỗng; `test`: chỉ 3 tệp nhóm `old` / đối chiếu fake (6-C xoá) |
| `flutter test` cả app | ✅ 2.280 đạt / 55 lỗi, khớp Kết quả: 53 trong danh sách baseline + 2 test catalog ghi ở mốc sau 5-C; 4 lỗi baseline của nhập Excel mất do test đã xoá (Q13). 0 lỗi mới |
| Test giữ hành vi H1–H17 | ✅ đủ tên ở bảng 5, đều đạt; H4 kiểm trên `appRouter` thật |

**Góp ý P3 (không chặn):** số impact ở Kết quả Task 2 (cả 5 symbol cùng `direct: 812`, `impacted: 1038`) trông như GitNexus gộp theo tệp / lớp chứa, không phải số riêng từng symbol; lần sau ghi kèm lệnh đã chạy. TH-04 (EP-04, PR-03, PR-09, KI-03, kịch bản 5, RPC nhập) phiên review sẽ sửa khi 6-A2 đạt (mục 3.1).

### Sửa R1 — 2026-11-05

- **R1-1 — đã sửa.** Xác nhận review đúng: ở Task 2 hai tệp state bị sửa thân, Kết quả "Lệch: không" là sai. Đã trả `logic/price_rule_history_state.dart` và `logic/price_rule_detail_state.dart` về đúng `git show HEAD:…/presentation/cubit/…`, chỉ thay `import 'package:c45_pricing_application/application.dart';` bằng `import '../data/models.dart';` (giữ `hasSensitivePermission = true`, `NoPermission.hasReachedMax = true`, `isFirstLoad = false`, `props` cũ, bỏ `actionMessage`, `final class`). `dart analyze lib test` không phát sinh lỗi ở nơi gọi.
  - Test thêm (đều PASS): `history_loaded_keeps_sensitive_permission`, `history_no_permission_stops_paging` (`test/features/pricing/logic/price_rule_history_sg06_test.dart`); `history_page_activity_sheet_shows_floor_diff` (`test/features/pricing/presentation/pages/pricing_history_e2e_test.dart`).
  - Lệch so với yêu cầu: fake mặc định không có hoạt động `updated` ở trang đầu (chỉ có `_historyOlderItem`), và hoạt động theo đơn hàng làm sheet overflow 223px trong khung test (lỗi có sẵn, ngoài phạm vi) ⇒ test mở hoạt động `created` thủ công và kiểm "không có 'Quyền hạn chế'", "không có 'Ẩn theo quyền 🔒'".
  - Kiểm đột biến: đặt lại mặc định `hasSensitivePermission = false` ⇒ `history_loaded_keeps_sensitive_permission` và `history_page_activity_sheet_shows_floor_diff` FAIL; đã trả lại.
- **R1-2 — đã ghi** hai lệch vào Kết quả Task 3 (không sửa code).
- **Kiểm chứng sau sửa:** `flutter test --no-pub` cả app → 2.283 PASS / 55 FAIL, cùng tập 55 lỗi như trước (53 baseline + 2 catalog sau 5-C; 7 lỗi pricing đều trong baseline), 0 lỗi mới.
