# 5-C — Chuyển SP-10 sang `ProductRepository` + dọn sạch module catalog, inventory

> Theme 2 (mã cũ P5) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-04) | Làm ✅ | Review ⬜
> Làm **sau** 5-A1 … 5-W (đã xong). **Không chờ Theme 7** nữa (Q1).
> Tài liệu: PLAN.md mục Theme 2 dòng 5-C, "Quy tắc dọn module", "Quy tắc migration", "Plan xoá / tách / thay code cũ"; TH-02 US-05.1, US-05.2, 5.8 SP-10, 6.4, KI-04, KI-07; mẫu đã làm: [4-C](../P4/4-C-don-module-partner.md) (lịch sử git).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** SP-10 (màn Tồn kho) chạy qua `ProductRepository` + cubit. App không còn `vet45_catalog_*` / `vet45_inventory_*`. Xoá `modules/catalog`, `modules/inventory`; DB bỏ outbox / inbox của hai schema đó.

**Architecture:** Thêm 2 method tồn cơ bản vào `ProductRepository` (gọi thẳng RPC, giữ rule đầu vào, bỏ đọc trước / sau). SP-10 đổi sang `ProductStockAdjustmentCubit` (mẫu `ProductManualBasePriceCubit`). Rồi xoá module, workspace, DI, nhóm test `old`, outbox SQL như 4-C.

**Tech Stack:** Flutter / Dart (`flutter_bloc`, `get_it`, `go_router`), Supabase Postgres (plpgsql), `flutter_test`.

**Spec:** [TH-02](../../../02-yeu-cau/TH-02-san-pham-va-gia-ban.md) (US-05.1, US-05.2, mục 5.8, 6.4, KI-04, KI-07).

## Global Constraints

- Giữ nghiệp vụ cũ: cùng RPC, cùng tham số, cùng luồng màn. Chỉ đổi ở các chỗ ghi **đổi có chủ đích** trong mục 2 (Q4, Q5, Q6).
- Câu chữ lấy nguyên văn TH-02: "Thay đổi sẽ ghi vào Lịch sử thay đổi.", "Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.", "Tồn kho phải là số nguyên không âm.", "Sản phẩm không tồn tại hoặc đã bị xoá.", "Đã nhập tồn kho ban đầu", "Đã điều chỉnh tồn kho".
- Migration: **sửa thẳng migration gốc**, không tạo migration mới. Phiên code **không** chạy `supabase db reset`, không reset Dev, không chạy SQL. Chỉ ghi "cần reset" vào Kết quả.
- Trước khi sửa mỗi symbol: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả. Trước khi commit: `detect_changes`.
- `flutter analyze` sập vì đường dẫn có dấu: dùng `dart analyze`.
- **Giữ** `modules/` (còn `einvoice`, `partner/integration_events`, `pricing`, `sales`), `packages/vet45_adapters`, `vet45_annotations`, `vet45_generator`, `vet45_shared`. **Giữ** schema `catalog`, `inventory` và mọi RPC (Q7).

## Review Focus

1. **Lý do + ghi chú gộp sai chuỗi.** Chip + ghi chú phải ra `"<lý do> - <ghi chú>"`; chỉ một trong hai thì ra đúng cái đó; không có gì thì `null` (BR-27). Test: Task 0 T0-1…T0-3 (giữ xanh sau khi sửa) + Task 3 test cubit.
2. **Mở SP-10 từ checklist "Thiếu tồn kho".** Sản phẩm đã có đơn vị cơ sở phải hiện được form (lỗi cũ, Q5). Test: Task 3 `sp10_from_checklist_args_shows_form`.
3. **Xung đột tồn (`stale_stock_quantity`).** Phải hiện đúng câu 6.4, ở lại màn, không đổi tồn. Test: T0-4 + Task 3 `sp10_stale_shows_64_message`.
4. **Bấm Lưu hai lần / đang gửi.** Nút Lưu phải khoá khi `loading` (cũ: `_isSubmitting`). Test: Task 3 `sp10_save_disabled_while_loading`.
5. **Script / công cụ đọc đường dẫn trong `modules/catalog`.** `guard_application_use_case_layout.sh`, `schema.lock.yaml` phải chạy qua sau khi xoá. Test: Task 4 / Task 5, bước kiểm.

---

## 1. Mục tiêu

- SP-10 không còn gọi `ICatalogModule`. Đi qua `ProductStockAdjustmentCubit` → `ProductRepository.setBasicStock` / `adjustBasicStock`. Lỗi hiện câu 6.4 (KI-07 phần app), câu chân trang theo KI-04.
- Sửa lỗi mở SP-10 từ checklist (Q5).
- App hết `vet45_catalog_*`, `vet45_inventory_*` (pubspec, DI, test). Xoá `modules/catalog`, `modules/inventory`.
- DB: bỏ outbox / inbox / internal commands của `catalog` và `inventory`.
- Ghi lại thứ tự mới vào PLAN.md (Q2, Q3).

## 2. Quyết định (người dùng chốt 2026-11-04)

| Q | Nội dung |
|---|---|
| Q1 | **Làm 5-C ngay, không chờ Theme 7.** SP-10 là nơi duy nhất trong `lib/` còn gọi module (2 command). Bước nhập tồn khi tạo sản phẩm đã đi qua `ProductRepository.createGuided` (`p_basic_stock_quantity_base`) từ 5-A3. Thay quyết định "SP-10 giữ module tới 5-C, chạy sau Theme 7" (2026-11-01). |
| Q2 | Xoá hẳn `modules/` + `packages/vet45_adapters`, `vet45_generator` chuyển về **7-5**, vì 7-5 lại là plan dọn module cuối: thứ tự 6-C → 8-C → 7-5 đều trước Theme 7. `vet45_annotations` **không** xoá được ở đó: `packages/vet45_shared/application/lib/src/cqrs/annotations.dart` re-export nó, nên xoá cùng `vet45_shared` ở **9-1**. |
| Q3 | Khi Theme 7 có màn thay (BJ-08 điều chỉnh / kiểm kê, BJ-12 tồn đầu kỳ): xoá SP-10 + route; nút "Sửa" thẻ Tồn kho ở PCC và mục readiness `missing_stock` mở màn Theme 7. Bước nhập tồn khi tạo sản phẩm giữ hay bỏ theo plan Theme 7. DB tồn cơ bản giữ tới 8-D (`search_sellable_products` còn đọc). Ghi vào PLAN mục Theme 7, không làm ở đây. |
| Q4 | **Đổi có chủ đích, chỉ phía app:** KI-07: cubit + câu lỗi 6.4, thêm mã `invalid_stock_quantity`, nhận thêm `product_not_found`. KI-04: câu chân trang. KI-01 / 02 / 05 / 06 (server) để Theme 7, không đổi RPC. |
| Q5 | **Đổi có chủ đích (sửa lỗi cũ):** `product_stock_adjustment_page.dart:144` chỉ coi là có đơn vị cơ sở khi `args.unitName` có giá trị. Checklist (`product_readiness_checklist_page.dart:96`) chỉ truyền `product`, nên luôn hiện S-01. Sửa: đơn vị = `args.unitName ?? args.product.baseUnit`, có đơn vị cơ sở khi chuỗi đó không rỗng. |
| Q6 | **Đổi có chủ đích (quy ước Theme 3 / Theme 2):** bỏ kiểm client cần đọc trước / sau. Handler cũ gọi `loadFacts`, `loadControlCenter`, `listProductUnits` và các luật domain: có đơn vị cơ sở, chế độ `basic`, tồn khớp `expectedQuantity`. **Giữ rule đầu vào** số ≥ 0, cùng câu. Server vẫn kiểm chế độ, số nguyên ≥ 0 và tồn khớp (`adjust_basic_stock`). Riêng **kiểm đơn vị cơ sở khi nhập ban đầu** chỉ còn ở UI (S-01 của SP-10 + checklist chặn `missing_stock` khi `missing_base_unit`), vì `set_basic_stock_quantity_base` không kiểm. Ghi ở mục 6 Rủi ro. |
| Q7 | **Không xoá RPC nào.** 10 RPC chỉ module gọi: `adjust_basic_stock`, `set_basic_stock_quantity_base` (nay app gọi); `request_product_image_upload`, `request_product_maintenance_image_upload` (app gọi qua biến `rpc` trong `_reserveSlot`); `create_product`, `set_initial_price_band` (SQL gọi nội bộ); `get_product_stock_history` (TH-02 KI-03: "Giữ trong DB"); `find_product_by_barcode`, `check_duplicate_measurement_unit_name`, `get_product_custom_field_snapshot` (TH-02 mục 6, bảng RPC, còn liệt kê). Chỉ bỏ outbox / inbox. |
| Q8 | Test hợp đồng SQL trong `modules/catalog/infrastructure/test`: chuyển 8 test xanh của `price_band_sql_contract_test.dart` sang app. **Bỏ** 4 test đọc `supabase/migrations/_drafts/…`, vì các tệp nháp đó đã promote và không còn; đây cũng là 4 lỗi baseline của module. Gồm `catalog_sellable_lookup_by_ids_sql_contract_test`, `product_code_reuse_sql_contract_test`, `catalog_sales_sellable_lookup_sql_contract_test` và test "set base unit creates pending ruleBased band when product has none" của `price_band_sql_contract_test`. |
| Q9 | `supabase/schema.lock.yaml` có 3 mục `source_path: modules/catalog/infrastructure/supabase/sql/functions/*.sql`. Chuyển 3 tệp sang `supabase/sql/catalog/functions/` (gốc dùng chung mà `sql_source_discovery.dart` đã hỗ trợ: `sharedSqlRelativePath = 'supabase/sql'`), sửa `source_path`, giữ nguyên `hash`. |

## 3. Hiện trạng (đo 2026-11-04)

| Thứ | Ai còn dùng |
|---|---|
| `package:vet45_catalog_*` trong `apps/erp/lib` | `core/di/injection.dart:3-4,197-205` (`CatalogStartup.initialize` → `ICatalogModule`); `features/catalog/presentation/pages/product_stock_adjustment_page.dart:4,90-111` |
| `package:vet45_inventory_*` trong app | không tệp nào (chỉ `apps/erp/pubspec.yaml:22-23`) |
| Test app import module | `test/core/di/injection_test.dart:3,50`; `test/features/catalog/support/{catalog_test_registry,fake_catalog_backend,fake_stock_catalog_module,fake_catalog_repositories_test}.dart`; nhóm `old` của `data/product_rpc_parity_test.dart:215`, `data/catalog_unit_field_price_rpc_parity_test.dart:269`, `data/catalog_errors_test.dart:15`, `logic/catalog_rules_test.dart:19`, `logic/product_readiness_test.dart:95` |
| `FakeCatalogBackend` dùng kiểu module | `fake_catalog_backend.dart:20-22` (import), `:97` (`module.StockMovementType`), `:2537-2622` (`handleSetBasicStockQuantityBase`, `handleAdjustBasicStock`, `_readinessSummaryForLegacy`) |
| `registerFakeCatalog(registerLegacyModule:)` | chỉ chính `catalog_test_registry.dart` (không caller nào truyền tham số) |
| Lớp `implements ProductRepository` ngoài fake | `sales_flow_pages_test.dart:1209`, `sales_draft_backend_test.dart:750`, `sales_checkout_page_test.dart:794`: đều có `noSuchMethod` ⇒ thêm method không vỡ |
| Module khác phụ thuộc catalog / inventory | không (grep `pubspec.yaml` trong `modules`, `packages`) |
| Workspace | `pubspec.yaml:20-23, 37-40`; `apps/erp/pubspec.yaml:22-26`; `apps/erp/example/pubspec.yaml:38-45, 58-65` |
| `scripts/ci/guard_application_use_case_layout.sh` | dòng 3, 112 (golden reference `modules/catalog/.../create_product/`), `guarded_areas` dòng 37-46 (10 dòng catalog) |
| `supabase/schema.lock.yaml` | 3 mục trỏ `modules/catalog/infrastructure/supabase/sql/functions/` (Q9) |
| DB outbox | `20260623000002_install_module_messaging_modules.sql:4` (`'catalog'`), `:6` (`'inventory'`). **15** `perform catalog.enqueue_outbox_message(...)` trong 10 tệp (bảng Task 5). `inventory.enqueue_outbox_message`: 0. Không tệp SQL / test / function nào đọc `catalog.*` / `inventory.*` `outbox_messages`, `inbox_messages`, `internal_commands`, `claim_*` |
| Schema | `catalog` tạo lại ở `20260709001:9` (`create schema if not exists`), `inventory` ở `20261104001:10` ⇒ bỏ `install_module_messaging` không mất schema. Không migration nào giữa `20260623000002` và `20260709001` đụng `catalog.` |
| `TEST-BASELINE.md` | dòng 30, 35-37 (hàng module), 221-226 (4 lỗi `modules/catalog/infrastructure`) |
| GitNexus impact (upstream) | `ProductStockAdjustmentPage`: 1 caller trực tiếp (router), chỉ mục báo **CRITICAL** do khớp các process `build` chung (44 process). `catalogException`: 5 caller trực tiếp (4 repository + test), chỉ mục báo **CRITICAL**, cùng lý do. `ProductRepository`: LOW. `registerFakeCatalog`: LOW. ⚠️ Cảnh báo theo CLAUDE.md: phiên code chạy lại và ghi số; đổi `catalogException` chỉ **thêm** nhánh, không đổi nhánh cũ |

## 4. Đang làm gì (thứ bị thay / xoá)

`git show HEAD:apps/erp/lib/features/catalog/presentation/pages/product_stock_adjustment_page.dart`, các handler ở `modules/catalog/application/lib/src/product_stock_profile/commands/`.

| # | Thứ cũ đang làm | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | `_isInitial = args.currentQuantity == null` → nhập ban đầu, ngược lại điều chỉnh | `ProductStockAdjustmentCubit.submit` chọn `setBasicStock` khi `currentQuantity == null`, ngược lại `adjustBasicStock`; page giữ `_isInitial` để vẽ | e2e `e2e_e05_u02_fr01_01`, `e2e_e05_u02_fr02_01` (có sẵn) |
| 2 | Gộp lý do: chip + ghi chú → `"$chip - $note"`; chỉ chip → chip; chỉ ghi chú → ghi chú; không có → `null` (ghi chú `trim()`) | hàm `combineStockAdjustmentReason` trong `logic/product_stock_adjustment_cubit.dart` | T0-1, T0-2, T0-3 |
| 3 | Nhập ban đầu gửi `p_tenant_id`, `p_product_id`, `p_mode: 'basic'`, `p_basic_stock_quantity_base` (`callScalar`) | `ProductRepository.setBasicStock` (`_rpc.call`) | Task 1 `H1 stock-1` (map mong đợi) |
| 4 | Điều chỉnh gửi `p_tenant_id`, `p_product_id`, `p_new_quantity`, `p_reason`, `p_expected_quantity = args.currentQuantity` | `ProductRepository.adjustBasicStock` | Task 1 `H1 stock-2`; T0-4 |
| 5 | Validator: số < 0 → `ValidationException('Số lượng tồn kho ban đầu không được âm.')` / `('Số lượng tồn kho không được âm.')` | `checkSetBasicStock` / `checkAdjustBasicStock` trong `catalog_rules.dart`, cùng câu, `AppErrorCode.validation` | Task 1 rule tests |
| 6 | Handler đọc facts / control center / units, kiểm đơn vị cơ sở, chế độ, tồn khớp, trả `readinessSummary` (SP-10 bỏ qua kết quả) | **Bỏ** (Q6). Server kiểm chế độ, số, tồn khớp; UI kiểm đơn vị cơ sở | T0-4 (xung đột vẫn bị chặn nhờ server / fake) |
| 7 | Validator form: rỗng → "Vui lòng nhập số tồn thực tế"; có `.`/`,` → "Tồn kho phải là số nguyên"; không parse → "Số lượng không hợp lệ"; < 0 → "Tồn kho không được âm" | giữ nguyên trong page | `e2e_e05_stock_rejects_fractional_quantity` (có sẵn) + T0-6 |
| 8 | `_hasChanges`: có số, hoặc chọn chip, hoặc (điều chỉnh) có ghi chú → bật Lưu | giữ trong page | T0-7 |
| 9 | Đang gửi: `_isSubmitting` → nút Lưu `isLoading`, nút Huỷ `null` | `state.status == loading` | Task 3 `sp10_save_disabled_while_loading` |
| 10 | Thành công: toast "Thành công" + "Đã nhập tồn kho ban đầu" / "Đã điều chỉnh tồn kho", `Navigator.pop(true)` (PCC tải lại) | `BlocConsumer.listener` khi `success` | e2e có sẵn (PCC hiện số mới) |
| 11 | Lỗi: toast "Lỗi" + `e.toString()` | toast "Lỗi" + `state.errorMessage` = `catalogErrorMessage(e)` (**đổi có chủ đích** Q4) | T0-4 (ở lại màn) + Task 3 `sp10_stale_shows_64_message` |
| 12 | Đơn vị cơ sở: `hasBaseUnit = args.unitName` không rỗng; chữ đơn vị `args.unitName ?? product.baseUnit` | `unitName ?? product.baseUnit` cho cả hai (**đổi có chủ đích** Q5) | T0-5 (không có đơn vị → S-01) + Task 3 `sp10_from_checklist_args_shows_form` |
| 13 | Chế độ nhập ban đầu ẩn "Lý do", chip, ghi chú | giữ | T0-8 |
| 14 | Chân trang "Thay đổi sẽ ghi vào Lịch sử. Ở Growth, …" | "Thay đổi sẽ ghi vào Lịch sử thay đổi." (**đổi có chủ đích** KI-04) | Task 3 `sp10_footer_ki04` |
| 15 | DI đăng ký `ICatalogModule` (`CatalogStartup.initialize` với `permissionChecker`, `tenantAccessChecker`) | xoá; `permissionChecker`, `tenantAccessChecker` còn dùng cho pricing / sales / einvoice | `injection_test.dart` (bỏ dòng 50) |
| 16 | `FakeStockCatalogModule` gọi `backend.handle…` | `FakeProductRepository.setBasicStock` / `adjustBasicStock` gọi `backend.handleSetBasicStock` / `handleAdjustBasicStock` | `fake_catalog_repositories_test.dart` (Task 2) |
| 17 | Fake backend: nhập ban đầu ném khi chế độ ≠ basic, chưa có đơn vị cơ sở; điều chỉnh ném khi chưa có đơn vị cơ sở, advanced, < 0, lệch `expected`; ghi `FakeStockMovement` | cùng điều kiện, ném `AppException` cùng nghĩa (bảng Task 2) | Task 2 tests |

## 5. Thay đổi

| Tệp | Hành động |
|---|---|
| `apps/erp/lib/features/catalog/data/catalog_errors.dart` | thêm `CatalogErrorCodes.invalidStockQuantity = 'INVALID_STOCK_QUANTITY'`; nhánh `invalid_stock_quantity`; nhánh `product not found` nhận thêm `product_not_found` |
| `apps/erp/lib/features/catalog/logic/catalog_error_messages.dart` | thêm `invalidStockQuantity => 'Tồn kho phải là số nguyên không âm.'` |
| `apps/erp/lib/features/catalog/logic/catalog_rules.dart` | thêm `checkSetBasicStock`, `checkAdjustBasicStock` |
| `apps/erp/lib/features/catalog/data/product_repository.dart` | thêm `setBasicStock`, `adjustBasicStock` |
| `apps/erp/lib/features/catalog/logic/product_stock_adjustment_cubit.dart`, `…_state.dart` | tạo |
| `apps/erp/lib/features/catalog/presentation/pages/product_stock_adjustment_page.dart` | sửa: cubit, Q5, KI-04, bỏ import module / `GetIt<ICatalogModule>` / `IExecutionContext` |
| `apps/erp/lib/core/di/injection.dart` | xoá import 3-4, khối 197-205 |
| `apps/erp/pubspec.yaml` | xoá dòng 22-26 |
| `apps/erp/test/features/catalog/support/fake_catalog_backend.dart` | bỏ import module (20-22); `FakeStockMovement.movementType` → `String`; viết lại 2 handler, xoá `_readinessSummaryForLegacy` |
| `…/support/fake_catalog_repositories.dart` | override 2 method mới |
| `…/support/fake_stock_catalog_module.dart` | xoá |
| `…/support/catalog_test_registry.dart` | bỏ import module, tham số + khối `registerLegacyModule` |
| `…/support/fake_catalog_repositories_test.dart` | đổi 3 test `FakeStockCatalogModule` sang repository; bỏ import module |
| `…/data/product_rpc_parity_test.dart`, `…/data/catalog_unit_field_price_rpc_parity_test.dart`, `…/data/catalog_errors_test.dart`, `…/logic/catalog_rules_test.dart`, `…/logic/product_readiness_test.dart` | xoá nhóm `old`, import module, helper chỉ nhóm `old` dùng (vd `_RecordingDuplicateChecker`). **Không sửa** map / ca của nhóm `new`. Thêm test mới (Task 1) |
| `…/data/catalog_sql_contract_test.dart` | tạo: 8 test chuyển từ `price_band_sql_contract_test.dart` (Q8) |
| `…/presentation/pages/product_stock_e2e_test.dart` | thêm T0-1…T0-8 (Task 0) và test Task 3 |
| `…/logic/product_stock_adjustment_cubit_test.dart` | tạo |
| `apps/erp/test/core/di/injection_test.dart` | bỏ import `vet45_catalog_application` + dòng 50 |
| `modules/catalog`, `modules/inventory` | xoá cả thư mục (trước đó chuyển 3 tệp SQL, Q9) |
| `supabase/sql/catalog/functions/{_base32_sha256_prefix,_build_product_search_text,_normalize_product_sku}.sql` | tạo bằng `git mv` từ `modules/catalog/infrastructure/supabase/sql/functions/` |
| `supabase/schema.lock.yaml` | 3 `source_path` → `supabase/sql/catalog/functions/<tên>.sql` |
| `pubspec.yaml` (gốc) | xoá dòng 20-23, 37-40 |
| `apps/erp/example/pubspec.yaml` | xoá 8 mục `vet45_catalog_*`, `vet45_inventory_*` (38-45, 58-65) |
| `scripts/ci/guard_application_use_case_layout.sh` | xoá 10 dòng `modules/catalog/...` ở `guarded_areas`; dòng 3, 112 đổi sang `modules/einvoice/application/lib/src/configuration/commands/connect_provider/` |
| `supabase/migrations/20260623000002_install_module_messaging_modules.sql` | xoá dòng `'catalog'`, `'inventory'` |
| 10 migration catalog (bảng Task 5) | xoá 15 khối `perform catalog.enqueue_outbox_message(…);` + biến `v_outbox_payload` |
| `docs/refactor/PLAN.md` | Task 6 |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật (như 4-C) |

---

## 6. Các task

### Task 0: Test giữ hành vi trên code cũ (bước 0)

**Files:**
- Test: `apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart` (thêm `group('5-C behavior', …)`)

**Interfaces:**
- Consumes: `setUpErpCatalogE2E`, `_buildPccRouter`, `_product1()`, `tapEditStock` (đã có); backend lấy qua `(getIt<ProductRepository>() as FakeProductRepository).backend`; `backend.products` (public).
- Produces: 8 test T0-1…T0-8. Phải xanh trên code cũ **và** sau Task 3. Được đổi cách dựng widget, không đổi điều kiện kiểm.

Ô ghi chú không có key: dùng `find.byType(TextField).last` (ô số là `TextField` đầu tiên trong `input_stock_quantity`). Kịch bản điều chỉnh: `pccReadyToSell`, `product-1` tồn 150 Hộp.

- [x] **Step 1: Viết các test**

| Tên | Thao tác | Kiểm |
|---|---|---|
| `T0-1 adjust combines chip and note` | nhập `147`, chạm "Hao hụt", ghi chú `vỡ 3 chai`, Lưu | `p.stockQty == 147`; `p.stockMovements.last.reason == 'Hao hụt - vỡ 3 chai'`; `.quantityBefore == 150`; `.delta == -3` |
| `T0-2 adjust note only` | nhập `140`, ghi chú `  đếm lại  `, Lưu | `reason == 'đếm lại'` |
| `T0-3 adjust no reason` | nhập `151`, Lưu | `reason == null`; `stockQty == 151` |
| `T0-4 adjust stale stays on page` | mở màn; đặt `p.stockQty = 140` (máy khác vừa đổi); nhập `100`, Lưu, `pumpAndSettle` | `find.byKey(Key('wgt_e05_u01_fr01_01'))` findsOneWidget; `p.stockQty == 140`; `find.text('Lỗi')` findsOneWidget |
| `T0-5 no base unit shows S-01` | `pumpWidget(MaterialApp(home: ProductStockAdjustmentPage(args: ProductStockAdjustmentRouteArgs(product: <ProductListItemModel id 'p-x', baseUnit: null>))))` (cần `registerFakeCatalog(getIt)`) | `find.textContaining('trước khi thiết lập tồn kho')` findsOneWidget; `input_stock_quantity` findsNothing |
| `T0-6 negative rejected` | nhập `-1`, Lưu | `find.text('Tồn kho không được âm')` findsOneWidget; `p.stockQty == 150` |
| `T0-7 save enabled only with changes` | mở màn điều chỉnh | Lưu (`btn_stock_save`) tắt; chạm "Kiểm kê" → bật |
| `T0-8 initial mode hides reason` | `createMinimalProduct(…, baseUnit: 'Hộp')` như `e2e_e05_u02_fr01_01`, `tapEditStock` | `find.text('Lý do')` findsNothing; `find.text('Kiểm kê')` findsNothing; `find.text('Chưa thiết lập')` findsOneWidget |

Kiểm "nút tắt" như các test catalog khác: đọc `onPressed` của nút trong `btn_stock_save` hoặc `ProductFormBottomBar.saveEnabled`. Chọn một cách, ghi vào Kết quả.

- [x] **Step 2: Chạy trên code cũ**

Run: `cd apps/erp && flutter test test/features/catalog/presentation/pages/product_stock_e2e_test.dart`
Expected: PASS hết (8 test mới + 8 test cũ). Đỏ ⇒ dừng, ghi lại (bảng "Đang làm gì" sai).

- [x] **Step 3: Commit**

```bash
git add apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart
git commit -m "test(catalog): 5-C bước 0 — test giữ hành vi SP-10 trên code cũ"
```

### Task 1: Repository, rule, câu lỗi cho tồn cơ bản

**Files:**
- Modify: `apps/erp/lib/features/catalog/logic/catalog_rules.dart`, `apps/erp/lib/features/catalog/data/product_repository.dart`, `apps/erp/lib/features/catalog/data/catalog_errors.dart`, `apps/erp/lib/features/catalog/logic/catalog_error_messages.dart`
- Test: `apps/erp/test/features/catalog/data/product_rpc_parity_test.dart` (nhóm `new`), `…/logic/catalog_rules_test.dart` (nhóm `new`), `…/data/catalog_errors_test.dart` (nhóm `new`), `…/logic/catalog_error_messages_test.dart`

**Interfaces:**
- Produces:
  - `void checkSetBasicStock(int quantity)`: `quantity < 0` ⇒ `AppException(AppErrorCode.validation, serverMessage: 'Số lượng tồn kho ban đầu không được âm.')`
  - `void checkAdjustBasicStock(int newQuantity)`: `< 0` ⇒ `AppException(AppErrorCode.validation, serverMessage: 'Số lượng tồn kho không được âm.')`
  - `Future<void> ProductRepository.setBasicStock({required String productId, required int quantity})`
  - `Future<void> ProductRepository.adjustBasicStock({required String productId, required int newQuantity, String? reason, int? expectedQuantity})`
  - `CatalogErrorCodes.invalidStockQuantity = 'INVALID_STOCK_QUANTITY'`

- [x] **Step 1: Viết test (đỏ)**

```dart
// product_rpc_parity_test.dart, nhóm new — map mong đợi chép từ ProductRpcMapper cũ
final _expectedSetBasicStockParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_mode': 'basic',
  'p_basic_stock_quantity_base': 30,
};
final _expectedAdjustBasicStockParams = {
  'p_tenant_id': tenantId,
  'p_product_id': productId,
  'p_new_quantity': 47,
  'p_reason': 'Hao hụt - vỡ 3 chai',
  'p_expected_quantity': 50,
};

test('H1 stock-1: set_basic_stock_quantity_base params (single call)', () async {
  await repository.setBasicStock(productId: productId, quantity: 30);
  expect(rpc.calls.single.schema, 'catalog');
  expect(rpc.calls.single.rpc, 'set_basic_stock_quantity_base');
  expect(rpc.calls.single.isCall, isTrue);
  expect(rpc.calls.single.params, _expectedSetBasicStockParams);
});

test('H1 stock-2: adjust_basic_stock params (single call, reason + expected)', () async {
  await repository.adjustBasicStock(
    productId: productId, newQuantity: 47,
    reason: 'Hao hụt - vỡ 3 chai', expectedQuantity: 50);
  expect(rpc.calls.single.rpc, 'adjust_basic_stock');
  expect(rpc.calls.single.params, _expectedAdjustBasicStockParams);
});

test('H1 stock-3: adjust without reason/expected sends nulls', () async {
  await repository.adjustBasicStock(productId: productId, newQuantity: 0);
  expect(rpc.calls.single.params!['p_reason'], isNull);
  expect(rpc.calls.single.params!['p_expected_quantity'], isNull);
  expect(rpc.calls.single.params!.containsKey('p_expected_quantity'), isTrue);
});

test('H1 stock-4: negative quantity rejected before RPC', () async {
  await expectLater(repository.setBasicStock(productId: productId, quantity: -1),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.validation)));
  await expectLater(repository.adjustBasicStock(productId: productId, newQuantity: -1),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.validation)));
  expect(rpc.calls, isEmpty);
});

test('H1 stock-5: stale_stock_quantity → STALE_STOCK_QUANTITY', () async {
  rpc.errorToThrow = const AppException(AppErrorCode.unknown, serverMessage: 'stale_stock_quantity');
  await expectLater(
    repository.adjustBasicStock(productId: productId, newQuantity: 1, expectedQuantity: 2),
    throwsA(isA<AppException>().having((e) => e.code, 'code', CatalogErrorCodes.staleStockQuantity)));
});
```

Thêm vào nhóm `new` của `catalog_errors_test.dart`: `classify('invalid_stock_quantity').code == CatalogErrorCodes.invalidStockQuantity`; `classify('product_not_found').code == CatalogErrorCodes.productNotFound`. `catalog_error_messages_test.dart`: `catalogErrorMessage(AppException(CatalogErrorCodes.invalidStockQuantity)) == 'Tồn kho phải là số nguyên không âm.'`. `catalog_rules_test.dart` nhóm `new`: 2 rule ném đúng câu ở `-1`, không ném ở `0`.

- [x] **Step 2: Chạy, xác nhận đỏ**

Run: `cd apps/erp && flutter test test/features/catalog/data test/features/catalog/logic/catalog_rules_test.dart test/features/catalog/logic/catalog_error_messages_test.dart`
Expected: FAIL (method / mã chưa có)

- [x] **Step 3: Làm**

- 2 method dùng mẫu `ProductPriceRepository.setManualBasePrice`: rule → `_tenantId()` → `_guard(() => _rpc.call('catalog', …))`. Không đọc gì thêm, không trả kết quả.
- `catalogException`: thêm nhánh `invalid_stock_quantity` cạnh `stale_stock_quantity`. Nhánh `product not found` (dòng ≈ 322) đổi điều kiện thành `lower.contains('product not found') || lower.contains('product_not_found')`.

- [x] **Step 4: Chạy lại** (lệnh Step 2). Expected: PASS.

- [x] **Step 5: Commit** `feat(catalog): 5-C ProductRepository.setBasicStock / adjustBasicStock + câu lỗi tồn 6.4`

### Task 2: Fake chuyển sang repository

**Files:**
- Modify: `apps/erp/test/features/catalog/support/fake_catalog_backend.dart`, `…/fake_catalog_repositories.dart`, `…/catalog_test_registry.dart`, `…/fake_catalog_repositories_test.dart`
- Delete: `…/fake_stock_catalog_module.dart`

**Interfaces:**
- Consumes: Task 1 (2 method, `CatalogErrorCodes.invalidStockQuantity`)
- Produces:
  - `Future<void> FakeCatalogBackend.handleSetBasicStock({required String productId, required int quantity})`
  - `Future<void> FakeCatalogBackend.handleAdjustBasicStock({required String productId, required int newQuantity, String? reason, int? expectedQuantity})`
  - `FakeProductRepository.setBasicStock` / `adjustBasicStock`: `calls.add('setBasicStock')` / `calls.add('adjustBasicStock')` rồi gọi backend
  - `FakeStockMovement.movementType` kiểu `String` (`'initial'` / `'adjust'`, khớp cột `movement_type` của DB)
  - `registerFakeCatalog(getIt, {scenario, backend, registerExecutionContext})`: bỏ `registerLegacyModule`

Điều kiện ném giữ như handler cũ, đổi kiểu exception:

| Cũ | Mới |
|---|---|
| `NotBasicStockModeException` | `AppException(CatalogErrorCodes.notBasicStockMode)` |
| `MissingBaseUnitException` | `AppException(CatalogErrorCodes.missingBaseUnit)` |
| `ValidationException('Số lượng tồn kho không được âm.')` | `AppException(AppErrorCode.validation, serverMessage: 'Số lượng tồn kho không được âm.')` |
| `StaleStockQuantityException` | `AppException(CatalogErrorCodes.staleStockQuantity)` |

Nhập ban đầu cũ ném khi `command.mode != 'basic'`. Method mới không có tham số `mode` (luôn `'basic'`) nên bỏ nhánh này; kiểm `prod.stockMode == StockMode.advanced` như handler điều chỉnh.

- [x] **Step 1: Sửa `fake_catalog_repositories_test.dart` (đỏ)**: 3 test cũ (dòng 68, 145, 168) thành:
  - `FakeProductRepository.setBasicStock records call and writes initial movement`: `calls.last == 'setBasicStock'`, `stockQty == 30`, `stockMovements.last.movementType == 'initial'`
  - `FakeProductRepository.adjustBasicStock throws STALE_STOCK_QUANTITY on mismatch`: `expectedQuantity` ≠ tồn ⇒ `code == CatalogErrorCodes.staleStockQuantity`
  - `registerFakeCatalog does not register ICatalogModule`: bỏ hẳn test này (không còn kiểu `ICatalogModule` trong app). Ghi vào Kết quả.
- [x] **Step 2: Chạy, xác nhận đỏ**: `flutter test test/features/catalog/support/fake_catalog_repositories_test.dart`
- [x] **Step 3: Làm** theo Interfaces + bảng. Xoá `fake_stock_catalog_module.dart`, khối `registerLegacyModule` trong `catalog_test_registry.dart`.
- [x] **Step 4: Chạy**: `flutter test test/features/catalog/support`. Expected: PASS. Lúc này `product_stock_e2e_test.dart` **đỏ** (page cũ còn tìm `ICatalogModule`), Task 3 sửa. Đừng commit riêng Task 2; commit cùng Task 3.

### Task 3: Cubit + SP-10

**Files:**
- Create: `apps/erp/lib/features/catalog/logic/product_stock_adjustment_cubit.dart`, `apps/erp/lib/features/catalog/logic/product_stock_adjustment_state.dart`
- Modify: `apps/erp/lib/features/catalog/presentation/pages/product_stock_adjustment_page.dart`
- Test: `apps/erp/test/features/catalog/logic/product_stock_adjustment_cubit_test.dart`, `…/presentation/pages/product_stock_e2e_test.dart`

**Interfaces:**
- Consumes: Task 1 (`ProductRepository.setBasicStock`, `adjustBasicStock`), `catalogErrorMessage`
- Produces:
  - `String? combineStockAdjustmentReason({String? chip, required String note})`: `note` đã `trim()` ở trong hàm; quy tắc ở bảng mục 4 dòng 2
  - `enum ProductStockAdjustmentStatus { initial, loading, success, failure }`
  - `class ProductStockAdjustmentState extends Equatable { status, errorMessage }` (khuôn `ProductManualBasePriceState`)
  - `ProductStockAdjustmentCubit({required ProductRepository productRepository})`
  - `Future<void> submit({required String productId, required int quantity, int? currentQuantity, String? chip, String note = ''})`: `currentQuantity == null` ⇒ `setBasicStock(quantity)`, bỏ qua `chip` / `note` (như cũ: chế độ nhập ban đầu không có lý do); ngược lại `adjustBasicStock(newQuantity: quantity, reason: combine…, expectedQuantity: currentQuantity)`. Phát `loading` → `success` / `failure(errorMessage: catalogErrorMessage(e))`

- [x] **Step 1: Test cubit (đỏ)**, dùng lớp `_RecordingProductRepository extends Fake implements ProductRepository` trong tệp test, ghi tham số 2 method (mẫu `product_control_center_cubit_test.dart:30`):
  - `combineStockAdjustmentReason`: `(chip 'Hao hụt', note ' vỡ 3 chai ')` → `'Hao hụt - vỡ 3 chai'`; `(null, 'x')` → `'x'`; `('Khác', '')` → `'Khác'`; `(null, '  ')` → `null`
  - `submit initial calls setBasicStock only`: `currentQuantity: null`, `chip: 'Khác'` ⇒ gọi `setBasicStock(quantity)`, không gọi `adjustBasicStock`
  - `submit adjust passes expected = currentQuantity`: `currentQuantity: 50, quantity: 47` ⇒ `expectedQuantity == 50`
  - `emits [loading, success]`
  - `failure maps STALE_STOCK_QUANTITY to 6.4 text`: `errorMessage == 'Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.'`
- [x] **Step 2: Test page (đỏ)** thêm vào `product_stock_e2e_test.dart`:
  - `sp10_from_checklist_args_shows_form`: pump `ProductStockAdjustmentPage(args: ProductStockAdjustmentRouteArgs(product: _product1()))` (chỉ `product`, `baseUnit: 'Hộp'`, giống checklist) ⇒ `input_stock_quantity` findsOneWidget; `find.text('Tồn mới (Hộp)')` findsOneWidget
  - `sp10_stale_shows_64_message`: như T0-4 ⇒ `find.text('Tồn kho hiện tại đã thay đổi. Vui lòng tải lại dữ liệu trước khi điều chỉnh.')` findsOneWidget
  - `sp10_footer_ki04`: `find.text('Thay đổi sẽ ghi vào Lịch sử thay đổi.')` findsOneWidget; `find.textContaining('Growth')` findsNothing
  - `sp10_save_disabled_while_loading`: repository có `Completer` chưa xong; nhập số, Lưu, `pump()` ⇒ nút Lưu đang loading, nút Huỷ `onCancel == null`; chạm Lưu lần hai không gọi thêm (`calls.length == 1`)
- [x] **Step 3: Chạy, xác nhận đỏ**: `flutter test test/features/catalog/logic/product_stock_adjustment_cubit_test.dart test/features/catalog/presentation/pages/product_stock_e2e_test.dart`
- [x] **Step 4: Làm**
  - Cubit / state theo Interfaces.
  - Page: `ProductStockAdjustmentPage.build` bọc `BlocProvider(create: (_) => ProductStockAdjustmentCubit(productRepository: GetIt.instance<ProductRepository>()))`, như `product_manual_base_price_page.dart:34`. Thân cũ chuyển vào widget con. `_submit` chỉ validate form rồi `cubit.submit(...)`. Xoá `_isSubmitting`; dùng `BlocConsumer`, listener lo toast + `Navigator.of(context).pop(true)` khi `success`, toast "Lỗi" + `errorMessage` khi `failure`.
  - Q5: `final unitName = args.unitName ?? args.product.baseUnit ?? ''; final hasBaseUnit = unitName.trim().isNotEmpty;`
  - KI-04: câu chân trang.
  - Bỏ import `vet45_catalog_application`, `vet45_shared_application`.
- [x] **Step 5: Chạy**: `flutter test test/features/catalog` + `dart analyze lib test` (trong `apps/erp`). Expected: catalog xanh, gồm T0-1…T0-8 không sửa điều kiện. `analyze` 0 error / warning mới.
- [x] **Step 6: Commit** (gồm Task 2) `refactor(catalog): 5-C SP-10 qua ProductStockAdjustmentCubit + ProductRepository; sửa mở từ checklist (Q5), KI-04, KI-07`

### Task 4: Xoá module, workspace, DI, nhóm test `old`

**Files:** theo bảng mục 5 (DI, pubspec ×3, `injection_test`, 5 tệp nhóm `old`, `catalog_sql_contract_test.dart`, script CI, `schema.lock.yaml`, `supabase/sql/catalog/functions/`, `modules/catalog`, `modules/inventory`).

**Interfaces:**
- Consumes: Task 3 xong (không còn gì trong `lib/` gọi module ngoài DI).

- [x] **Step 1: Kiểm điều kiện**: `grep -rln "package:vet45_\(catalog\|inventory\)_" apps/erp/lib apps/erp/test` (dùng `grep -r`, không dùng `git grep`: 4-C sót tệp chưa theo dõi). Expected: chỉ `core/di/injection.dart`, `test/core/di/injection_test.dart`, 5 tệp nhóm `old`, `fake_catalog_backend.dart` nếu Task 2 sót. Khác ⇒ dừng, ghi lại.
- [x] **Step 2: Test SQL chuyển sang app (Q8)**: tạo `apps/erp/test/features/catalog/data/catalog_sql_contract_test.dart` từ `price_band_sql_contract_test.dart`. Bỏ test "set base unit creates pending ruleBased band when product has none". `package:test/test.dart` → `package:flutter_test/flutter_test.dart`, giữ `_findRepoRoot`.
  Run: `flutter test test/features/catalog/data/catalog_sql_contract_test.dart`. Expected: **8/8 PASS**, chạy **trước** khi xoá module.
- [x] **Step 3: Bỏ nhóm `old`** ở 5 tệp + import + helper chỉ nhóm `old` dùng. Ghi số test trước / sau từng tệp vào Kết quả. Nhóm `new` không đổi gì.
- [x] **Step 4: DI + `injection_test`**: xoá import 3-4 và khối 197-205 của `injection.dart`; xoá import + dòng 50 của `injection_test.dart`.
- [x] **Step 5: SQL khai báo (Q9)**: `git mv modules/catalog/infrastructure/supabase/sql/functions/<3 tệp> supabase/sql/catalog/functions/`, sửa 3 `source_path` trong `supabase/schema.lock.yaml`.
  Run: `dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart`. Expected: `OK (sources match schema.lock.yaml)`.
- [x] **Step 6: Xoá thư mục + workspace**: `git rm -r modules/catalog modules/inventory` (kiểm trước: `git status --short modules/catalog modules/inventory` không có tệp chưa commit cần giữ). Sửa `pubspec.yaml` gốc (−8 dòng), `apps/erp/pubspec.yaml` (−5), `apps/erp/example/pubspec.yaml` (−8 mục).
  Run: `flutter pub get` ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example`. Expected: không lỗi phân giải.
- [x] **Step 7: Script CI**: xoá 10 dòng catalog ở `guarded_areas`; dòng 3, 112 → `modules/einvoice/application/lib/src/configuration/commands/connect_provider/`.
  Run: `scripts/ci/guard_application_use_case_layout.sh`. Expected: `OK`.
- [x] **Step 8: Kiểm**: `dart analyze lib test` (apps/erp) 0 error / warning mới; `flutter test` (apps/erp) không fail mới so với `TEST-BASELINE.md`.
- [x] **Step 9: Commit** `chore(catalog): 5-C xoá modules/catalog, modules/inventory + workspace, DI, nhóm test old`

### Task 5: DB — bỏ outbox / inbox catalog + inventory

**Files:** `supabase/migrations/20260623000002_install_module_messaging_modules.sql` và 10 tệp:

| Tệp | Số khối `perform catalog.enqueue_outbox_message` | Có `v_outbox_payload` (khai báo + gán + dùng) |
|---|---|---|
| `20260709001_catalog_guided_create.sql` | 1 | có |
| `20260709007_catalog_manual_base_price.sql` | 1 | có |
| `20260709011_catalog_product_business_status.sql` | 2 | — (`jsonb_build_object` tại chỗ) |
| `20260709012_catalog_product_soft_delete.sql` | 2 | — |
| `20260710001_catalog_product_reference_id.sql` | 1 | có |
| `20260710003_catalog_patch_inline_normalize_products_rpcs.sql` | 2 | có (1 khối) |
| `20260712006_catalog_patch_business_status_soft_deleted_soft_delete_rpcs.sql` | 2 | — |
| `20260712007_catalog_patch_business_status_soft_deleted_status_rpcs.sql` | 2 | — |
| `20260713002_catalog_patch_base_price_vat.sql` | 1 | có |
| `20260717005_catalog_product_code_reuse_after_soft_delete_rpcs.sql` | 1 | có |

- [x] **Step 1**: xoá dòng `select platform.install_module_messaging('catalog');` và `('inventory');`. **Giữ** `'iam'`, `'sales'`, `'costing'`, `'accounting'`, `'dashboard'` (P9 lo).
- [x] **Step 2**: ở 10 tệp: xoá mỗi khối `perform catalog.enqueue_outbox_message(` … `);` (gồm `jsonb_build_object(...)` tới dấu `;`); xoá dòng khai báo `v_outbox_payload jsonb;` và câu gán `v_outbox_payload := jsonb_build_object(…);`. Không đổi gì khác.
- [x] **Step 3: Kiểm**:
  - `grep -rc "enqueue_outbox_message" supabase/migrations/2026070900{1,7}* supabase/migrations/20260709011* supabase/migrations/20260709012* supabase/migrations/2026071000{1,3}* supabase/migrations/2026071200{6,7}* supabase/migrations/20260713002* supabase/migrations/20260717005*` ⇒ tất cả `0`
  - `grep -rn "v_outbox_payload" supabase/migrations` ⇒ rỗng
  - `grep -rnE "(catalog|inventory)\.(outbox_messages|inbox_messages|internal_commands|enqueue_outbox_message|claim_|receive_integration_event)" supabase` ⇒ rỗng
  - `grep -n "install_module_messaging('\(catalog\|inventory\)')" supabase/migrations -r` ⇒ rỗng
  - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ không lỗi mới (1 warning có sẵn `_trg_sales_order_partner_history`)
- [x] **Step 4**: ghi vào Kết quả: **người dùng** chạy `supabase db reset` local + `supabase/tests/catalog_th02.sql`, kiểm `information_schema.tables` của schema `catalog` / `inventory` không còn `outbox_messages`, `inbox_messages`, `internal_commands`; **cần reset Dev**. Phiên code không chạy.
- [x] **Step 5: Commit** `chore(db): 5-C bỏ outbox / inbox catalog + inventory (sửa migration gốc)`

### Task 6: PLAN.md + kiểm tổng

- [x] **Step 1: PLAN.md** (phiên viết plan đã sửa lúc tạo plan; phiên code chỉ kiểm lại và cập nhật cột Làm):
  - dòng 5-C: nội dung theo plan này (Q1, Q2, Q9), Plan 📝 → link; cập nhật `✅ 2026-11-04`.
  - "Thứ tự chốt lại 2026-11-03" (dòng 17) và "Quy tắc dọn module" mục 4 (dòng 121): 5-C làm ngay; **7-5** xoá `modules/` + `vet45_adapters`, `vet45_generator`; `vet45_annotations` ở **9-1**;
  - dòng 7-5, 9-1: như trên;
  - mục Theme 7: ghi Q3;
  - Rủi ro theo mục (dòng 803): bỏ dòng "modules/catalog chưa xoá được".
- [x] **Step 2: Kiểm tổng**
  - `grep -rn "package:vet45_\(catalog\|inventory\)_" apps modules packages tools` ⇒ rỗng
  - `ls modules` ⇒ `einvoice partner pricing sales`
  - `cd apps/erp && dart analyze lib test` ⇒ 0 error, 0 warning mới
  - `cd apps/erp && flutter test` ⇒ 2110 pass, 59 fail trùng tên `TEST-BASELINE.md`; không fail mới
  - `cd apps/erp/example && dart analyze lib` ⇒ 0 lỗi
  - `dart test` ở `modules/einvoice/application`, `modules/einvoice/infrastructure` ⇒ không lỗi biên dịch mới so với baseline
  - `scripts/ci/guard_application_use_case_layout.sh` ⇒ `OK`; `verify_schema_lock_sync.dart` ⇒ `OK`; `verify_migration_policy.dart` ⇒ không lỗi mới (0 error, warnings có sẵn)
  - `gitnexus analyze` + `detect_changes` ⇒ 132 files, 283 symbols
- [x] **Step 3**: ghi Kết quả (mục 8). Không tự chấm Review.

## 7. Rủi ro / lưu ý

- **Q6, kiểm đơn vị cơ sở khi nhập ban đầu:** `set_basic_stock_quantity_base` (`20260712003:48`) không kiểm đơn vị cơ sở; trước đây domain client kiểm. Sau 5-C chỉ còn UI chặn (S-01 + checklist). Gọi RPC thẳng vẫn ghi được tồn khi chưa có đơn vị cơ sở. Đây là lỗ hổng server có từ trước (BR-12), để Theme 7 thay cùng KI-01/02/05/06.
- `adjust_basic_stock` ném `product_not_found` khi **chưa có hồ sơ tồn**. SP-10 chỉ gọi điều chỉnh khi `currentQuantity != null` nên không gặp. Câu hiện ra (nếu gặp): "Sản phẩm không tồn tại hoặc đã bị xoá."
- `not_basic_stock_mode` không có câu riêng ở 6.4 ⇒ câu chung "Đã xảy ra lỗi. Vui lòng thử lại.". PCC chỉ mở SP-10 khi `canAdjust` (`stockMode == basic`), nên hiếm gặp.
- Xoá `install_module_messaging('catalog')` thì không còn `catalog.internal_commands`. Theme 7 / 8-D không được tìm bảng này.
- `modules/` chưa trống (còn einvoice, partner/integration_events, pricing, sales). `packages/vet45_generator/test` có chuỗi `'vet45_inventory_application'` trong fixture: chỉ là chuỗi cấu hình, không phân giải package, không sửa.
- SQL tồn cơ bản (`product_stock_profiles`, 2 RPC) giữ tới 8-D / Theme 7 (Q3).

## 8. Kết quả (phiên làm code ghi)

- **Trạng thái:** ✅ Hoàn thành toàn bộ plan 5-C.
- **Task 0:** ✅ Test giữ hành vi SP-10 trên code cũ
  - Commit: `1b459eb41` `test(catalog): 5-C bước 0 — test giữ hành vi SP-10 trên code cũ`
  - Thêm 8 test (T0-1…T0-8) trong `apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart`.
  - Nút tắt: kiểm tra `tester.widget<ElevatedButton>(find.byKey(const Key('btn_stock_save'))).onPressed != null`.
- **Task 1:** ✅ Repository, rule, câu lỗi tồn cơ bản
  - Commit: `2a62b7876` `feat(catalog): 5-C ProductRepository.setBasicStock / adjustBasicStock + câu lỗi tồn 6.4`
  - Tệp sửa: `apps/erp/lib/features/catalog/logic/catalog_rules.dart` (thêm `checkSetBasicStock`, `checkAdjustBasicStock`), `apps/erp/lib/features/catalog/data/product_repository.dart` (`setBasicStock`, `adjustBasicStock`), `apps/erp/lib/features/catalog/data/catalog_errors.dart` (`CatalogErrorCodes.invalidStockQuantity`, sửa map `product_not_found`), `apps/erp/lib/features/catalog/logic/catalog_error_messages.dart` (`invalidStockQuantity` -> "Tồn kho phải là số nguyên không âm.").
  - Test parity/rules/errors: thêm các test trong `product_rpc_parity_test.dart`, `catalog_rules_test.dart`, `catalog_errors_test.dart`, `catalog_error_messages_test.dart`.
- **Task 2 & Task 3:** ✅ Fake chuyển sang repository + Cubit + SP-10
  - Commit: `d1f180a46` `refactor(catalog): 5-C SP-10 qua ProductStockAdjustmentCubit + ProductRepository; sửa mở từ checklist (Q5), KI-04, KI-07`
  - Tệp tạo mới: `apps/erp/lib/features/catalog/logic/product_stock_adjustment_cubit.dart`, `apps/erp/lib/features/catalog/logic/product_stock_adjustment_state.dart`, `apps/erp/test/features/catalog/logic/product_stock_adjustment_cubit_test.dart`.
  - Tệp sửa: `apps/erp/lib/features/catalog/presentation/pages/product_stock_adjustment_page.dart` (chuyển sang `BlocConsumer` + `ProductStockAdjustmentCubit`, fix Q5 `args.unitName ?? args.product.baseUnit`, footer KI-04, câu lỗi 6.4), fake backend và repository trong `apps/erp/test/features/catalog/support/`.
  - Xoá: `fake_stock_catalog_module.dart`.
  - 12/12 behavior test trong `product_stock_e2e_test.dart` PASS (T0-1…T0-8 + 4 test SP-10 mới).
- **Task 4:** ✅ Xoá module, workspace, DI, nhóm test old
  - Commit: `b8e58744e` `chore(catalog): 5-C xoá modules/catalog, modules/inventory + workspace, DI, nhóm test old`
  - Thêm `apps/erp/test/features/catalog/data/catalog_sql_contract_test.dart` (8/8 PASS).
  - Bỏ nhóm `old` và helper liên quan ở 5 file test parity/rules:
    - `product_rpc_parity_test.dart`: 50 -> 29 tests
    - `catalog_unit_field_price_rpc_parity_test.dart`: 74 -> 37 tests
    - `catalog_errors_test.dart`: 76 -> 40 tests
    - `catalog_rules_test.dart`: 162 -> 83 tests
    - `product_readiness_test.dart`: 10 -> 5 tests
  - Bỏ `ICatalogModule`, `IInventoryModule` khỏi DI (`apps/erp/lib/core/di/injection.dart` và `injection_test.dart`).
  - Chuyển 3 tệp SQL sang `supabase/sql/catalog/functions/`, cập nhật `schema.lock.yaml` (verify OK).
  - Xoá `modules/catalog`, `modules/inventory` khỏi git và disk.
  - Xoá 8 dependencies catalog/inventory ở `pubspec.yaml` gốc, `apps/erp/pubspec.yaml`, `apps/erp/example/pubspec.yaml`.
  - `scripts/ci/guard_application_use_case_layout.sh` OK.
- **Task 5:** ✅ DB — bỏ outbox / inbox catalog + inventory
  - Commit: `b039cce2d` `chore(db): 5-C bỏ outbox / inbox catalog + inventory (sửa migration gốc)`
  - Sửa `20260623000002_install_module_messaging_modules.sql`: bỏ `'catalog'` và `'inventory'`.
  - Sửa 10 migration catalog gốc: bỏ toàn bộ khai báo `v_outbox_payload`, gán payload và lời gọi `perform catalog.enqueue_outbox_message(...)`.
  - Đã kiểm tra: 0 lời gọi `enqueue_outbox_message`, không còn `v_outbox_payload`, không còn bảng outbox/inbox của catalog/inventory trong supabase.
  - Lưu ý cho review / người dùng: **cần reset Dev**; người dùng chạy `supabase db reset` ở môi trường local khi thuận tiện.
- **Task 6:** ✅ PLAN.md + kiểm tổng
  - `docs/refactor/PLAN.md`: cập nhật cột Làm của 5-C thành `✅ 2026-11-04`.
  - `grep -rn "package:vet45_\(catalog\|inventory\)_"`: rỗng.
  - `ls modules`: `einvoice partner pricing sales`.
  - `cd apps/erp && dart analyze lib test`: 0 error.
  - `cd apps/erp/example && dart analyze lib`: 0 error.
  - `cd apps/erp && flutter test`: 2110 tests passed; các test fail (59) hoàn toàn trùng với danh sách đã ghi trong `docs/refactor/TEST-BASELINE.md` (không có fail mới).
  - `scripts/ci/guard_application_use_case_layout.sh`: OK.
  - `verify_schema_lock_sync.dart`: OK.
  - `verify_migration_policy.dart`: OK (0 error, warnings có sẵn).
  - GitNexus `detect_changes`: 132 files, 283 symbols, 16 affected processes.

## 9. Review

<!-- Chỉ phiên review ghi -->
