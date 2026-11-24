# Mốc test trước refactor

> Chạy ngày 2026-10-07 tại commit `6809122e0` (sau tag `v-legacy-arch` chỉ thêm commit hạ tầng/tài liệu). PLAN P0.5.
> Lệnh: `flutter test --no-pub -r compact` (package Flutter) hoặc `dart test -r compact` (package Dart) trong từng package có thư mục `test/`. Test không cần Supabase.
> **Cách dùng:** sau mỗi phase, test lỗi nằm trong danh sách dưới đây là lỗi có sẵn; lỗi mới ngoài danh sách là do refactor.

**Tổng:** 41 package · 5688 đạt · **160 lỗi**

> **Sau 3-D (2026-10-11):** 4 package IAM, `apps/admin` và `apps/messaging_worker` đã xoá — các hàng tương ứng dưới đây chỉ còn giá trị lịch sử. `tools/c45_env` giữ nguyên 107 đạt / **1 lỗi có sẵn** (`config_init_test`: `ExampleGenerator` ghi `auth.env` khi `writeEnvCopies`, test kỳ vọng không có); `apps/erp` 1.494 đạt / 59 lỗi, đều nằm trong danh sách dưới đây.

> **Sau 4-C (2026-11-02, review 4-C R1):** đã xoá `modules/partner/{domain,application,infrastructure}`, `modules/{accounting,costing,dashboard}` (không có test), `packages/c45_resend`; bỏ các hàng tương ứng trong bảng và mục lỗi `modules/partner/infrastructure` (test `alternate_name` chuyển sang `apps/erp/test/features/partner/data/partner_search_sql_contract_test.dart`, nay xanh). `apps/erp` 1.705 đạt / 61 lỗi, đều trong danh sách `apps/erp` dưới đây. `modules/einvoice/application` 217 / 1 (như baseline). `modules/einvoice/infrastructure` **378 đạt / 60 lỗi**: 2 lỗi baseline (`goi1_configuration` nay lỗi cả tệp lúc nạp) + các test `*_sql_contract` / bundle đọc `supabase/migrations/_drafts/0xx_einvoice_*.sql` (`PathNotFoundException`, "draft SQL must exist", kéo theo `LateInitializationError` ở `tearDownAll`) vì 23 draft đã promote thành `20261031001…023` ngày 2026-10-31 (không do 4-C). Các test này cần trỏ sang migration chính thức (lượt promote / Theme 8, PLAN 7.1); tới lúc đó coi 60 lỗi này là có sẵn.

> **Sau 5-C (2026-11-04, review 5-C đạt):** đã xoá `modules/catalog/{domain,application,infrastructure,integration_events}`, `modules/inventory/{domain,application,infrastructure,integration_events}`; bỏ các hàng tương ứng trong bảng và mục lỗi `modules/catalog/infrastructure` (8 test xanh của `price_band_sql_contract_test` chuyển sang `apps/erp/test/features/catalog/data/catalog_sql_contract_test.dart`; 4 test đọc `supabase/migrations/_drafts/…` đã bỏ, Q8 của 5-C). `apps/erp` **2.112 đạt / 59 lỗi**: 57 lỗi trong danh sách `apps/erp` dưới đây (4 test `product_measurement_units_e2e_test` nay xanh, đã bỏ khỏi danh sách) + ⚠️ **2 lỗi mới, không có trong mốc**: `product_guided_create_e2e_test.dart: e2e_e02_u01_fr01_01: duplicate SKU opens existing product in PCC` và `product_change_history_e2e_test.dart: e2e_e07_u04_fr02_01: product change history can be viewed from PCC`. Cả hai hỏng ở bước tìm tên sản phẩm trên tiêu đề PCC, không dính SP-10 / 5-C; xuất hiện trong lượt đổi UI Theme 2 (5-A3 … 5-W), cần xem lại — **chưa** coi là lỗi có sẵn.

> **Sau 6-C (2026-11-06, review 6-C R1 đạt):** đã xoá `modules/pricing/{domain,application,infrastructure}`; bỏ 3 hàng tương ứng trong bảng và 2 mục lỗi `modules/pricing/infrastructure` (50: test SQL đọc `_drafts/` đã promote, 6-C Q4), `modules/pricing/domain` (1). Bỏ khỏi danh sách `apps/erp` 4 test nhập Excel (`pricing_import_history_e2e_test.dart` ×3, `PricingImportPage (S8)` ×1), đã xoá cùng màn nhập ở 6-A2. Test hợp đồng SQL pricing mới ở `apps/erp/test/features/pricing/data/pricing_sql_contract_test.dart` (10, xanh). `apps/erp` **2.282 đạt / 55 lỗi**: 53 lỗi trong danh sách `apps/erp` dưới đây + 2 lỗi ⚠️ ngoài mốc đã ghi ở mục "Sau 5-C" (`product_guided_create_e2e_test` duplicate SKU, `product_change_history_e2e_test`), không do 6-C. `modules/einvoice/application` 217 / 1 (như baseline).

> **Sau 8-C (2026-11-08, review 8-C R1 đạt):** đã xoá `modules/sales/{domain,application,infrastructure}` (giữ `modules/sales/integration_events`, einvoice dùng tới 7-C); bỏ 3 hàng tương ứng trong bảng và mục lỗi `modules/sales/infrastructure` (11: test SQL đọc `_drafts/`, 8-C Q7). Test hợp đồng SQL sales mới ở `apps/erp/test/features/sales/data/sales_sql_contract_test.dart` (9, xanh). `apps/erp` **2.741 đạt / 55 lỗi**: 53 lỗi trong danh sách `apps/erp` dưới đây + 2 lỗi ⚠️ ngoài mốc đã ghi ở mục "Sau 5-C", không do 8-C. `modules/einvoice/application` 217 / 1 (như baseline).

> **Sau 7-C (2026-11-09, review 7-C R1 đạt):** đã xoá hết `modules/` (`einvoice/{domain,application,infrastructure,presentation,integration_events}`, `partner/integration_events`, `sales/integration_events`) và `packages/c45_misa`, `c45_async_query` (kèm `async_query_flutter`), `c45_adapters`, `c45_generator`; bỏ 12 hàng tương ứng trong bảng và 2 mục lỗi `modules/einvoice/application` (1), `modules/einvoice/infrastructure` (2; test SQL đọc `_drafts/`, 7-C Q4). Test hợp đồng SQL einvoice mới ở `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` (10, xanh). `apps/erp` **3.021 đạt / 55 lỗi** (review chạy lại): 53 lỗi trong danh sách `apps/erp` dưới đây + 2 lỗi ⚠️ ngoài mốc đã ghi ở mục "Sau 5-C", không do 7-C.

> **Sau 9-1 (2026-11-19, review 9-1 R1):** đã xoá `packages/c45_shared/{application,domain,infrastructure,testing}`, `packages/c45_annotations`, `apps/erp/example`; 5 hàng tương ứng trong bảng chỉ còn giá trị lịch sử (cùng `tools/c45_env`, `tools/c45_supabase_migrate` đã xoá ở `8ad18cd27`). `apps/erp` **3.854 đạt / 62 lỗi** (review chạy lại, HEAD `731985ddb`): 51 lỗi trong danh sách `apps/erp` dưới đây + ⚠️ **11 lỗi golden ngoài mốc**, có sẵn trước 9-1 (review chạy lại trên `941594c2b`: cùng `+3 -11`), không do 9-1: `inventory/presentation/costing/costing_golden_test.dart` (077_COMPLETED), `inventory/presentation/stocktake/stocktake_golden_test.dart` (SCR_042_READY, 043_READY, 044_BLIND_COUNT, 045_RECOUNT_REQUIRED, 047_COMPLETED), `inventory/presentation/supplier_rebate/supplier_rebate_golden_test.dart` (P3_PROJECTED, P3_RECORDED, P4_READY, P4_RESULT, P5_READY) — ảnh đích lệch, cần chụp lại hoặc sửa ở đợt sửa UI.

| Package | Loại | Đạt | Lỗi |
|---|---|---|---|
| `apps/messaging_worker` | dart | 45 | 0 |
| `apps/admin` | flutter | 324 | **5** |
| `apps/erp` | flutter | 1343 | **61** |
| `tools/c45_supabase_migrate` | dart | 76 | 0 |
| `tools/c45_env` | dart | 107 | **1** |
| `packages/c45_annotations` | dart | 8 | 0 |
| `packages/c45_design_system` | flutter | 288 | **2** |
| `modules/iam/integration_events` | dart | 3 | 0 |
| `modules/iam/application` | dart | 225 | 0 |
| `modules/iam/infrastructure` | dart | 289 | **21** |
| `modules/iam/domain` | dart | 40 | 0 |
| `packages/c45_shared/testing` | dart | 6 | 0 |
| `packages/c45_shared/application` | dart | 5 | 0 |
| `packages/c45_shared/infrastructure` | dart | 22 | 0 |
| `packages/c45_shared/domain` | dart | 9 | 0 |

## Test đang lỗi

### `apps/admin` (5)

- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/production_boundary_test.dart: presentation.dart does not export Fake* or testing paths
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/widgets/select_organization_bottom_sheet_test.dart: SelectOrganizationBottomSheet renders list of organizations (TA-O-01)
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/widgets/invitation_filter_bottom_sheet_test.dart: InvitationFilterBottomSheet renders all sections and option chips
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/users/presentation/pages/platform_onboarding_page_test.dart: review step displays selected legal entity type correctly
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/users/presentation/pages/platform_onboarding_page_test.dart: organization step fields are submitted to onboarding command

### `apps/erp` (53)

> **Cập nhật 2026-10-28** (trước khi đóng Theme 1, sau 2-B6 / 2-B7 / W-1; `flutter test --no-pub` cả app: 1524 đạt / 61 lỗi). So với danh sách 2026-10-07: **thêm** `product_measurement_units_e2e_test` `e2e_e04_u02_fr01_01b`, `e2e_e04_u02_fr01_03` (hỏng sẵn ở HEAD, phát hiện ở review 2-B7 R3); **bỏ** 2 test IAM nay đã đạt (`production_boundary_test` "presentation.dart does not export Fake* or testing paths", `platform_onboarding_step_owner_test` "renders warning VBanner…"). Danh sách dưới là bản hiện hành.

- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_catalog_tab_page_test.dart: e2e_e01_u01_fr01_01: keyword search returns matching products
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_config_e2e_test.dart: e2e_e03_u01_fr02_01: create and edit custom field group
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_config_e2e_test.dart: e2e_e03_u01_fr03_01: reorder groups updates visual order
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_config_e2e_test.dart: e2e_e03_u01_fr04_02: single select field requires at least one option
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_config_e2e_test.dart: e2e_e03_u01_fr05_01: configure field attributes and show chips
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_config_e2e_test.dart: e2e_e03_u01_fr06_01: reorder fields within group
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_values_e2e_test.dart: e2e_e03_u02_fr01_01: PCC shows custom field group cards
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_values_e2e_test.dart: e2e_e03_u02_fr02_01: save text custom field value and refresh PCC
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_values_e2e_test.dart: e2e_e03_u02_fr02_02: invalid number value shows field-level error
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_values_e2e_test.dart: e2e_e03_u02_fr03_01: optional field saves while required sibling empty
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_field_values_e2e_test.dart: e2e_e03_u02_fr03_02: filling required custom field clears readiness blocker
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_custom_fields_search_e2e_test.dart: e2e_e03_u03_fr02_01: keyword search via searchable custom fields
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_discovery_e2e_test.dart: e2e_e01_u01_fr01_01: search products by keyword
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_discovery_e2e_test.dart: e2e_e01_u02_fr01_01: list to PCC shows operational cards
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_guided_create_e2e_test.dart: e2e_e02_u02_fr01_01: guided create with initial stock and base cost
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_guided_create_e2e_test.dart: e2e_e02_u02_fr03_01: skip price band defers setup and shows blocker
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_guided_create_page_test.dart: initial stock uses Design System integer field
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_manual_base_price_e2e_test.dart: e2e_e06_u01_fr01_01: PCC shows manual base price card with amount
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_measurement_units_e2e_test.dart: EPIC-04 / US-02 — Đơn vị quy đổi e2e_e04_u02_fr01_01: add new conversion unit on product with base unit
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_measurement_units_e2e_test.dart: EPIC-04 / US-02 — Đơn vị quy đổi e2e_e04_u02_fr01_04: duplicate conversion unit name shows error
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_measurement_units_e2e_test.dart: e2e_e04_u01_fr03_01: base unit search dropdown only shows on match
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr01_01: valid profile edit refreshes PCC
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr01_02: blank name shows field validation error
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr01_03: duplicate SKU shows field error
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr02_01: PCC opens images maintenance gallery
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr02_02: removing primary promotes remaining image
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr02_03: deleting all images shows zero on PCC
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr03_01: duplicate barcode includes inactive product
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_profile_maintenance_e2e_test.dart: e2e_e07_u01_fr04_01: deleting images adds readiness blocker on incomplete product
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_readiness_e2e_test.dart: e2e_e02_u03_fr01_05: ready to sell product shows success badge without banner
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_readiness_e2e_test.dart: e2e_e02_u03_fr02_04: failed create stays on guided create form
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart: e2e_e07_u03_fr01_01: eligible product can be soft-deleted
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart: e2e_e07_u03_fr02_01: deleted product is excluded from default list
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart: e2e_e07_u03_fr02_03: deleted filter shows deleted product label
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_soft_delete_e2e_test.dart: e2e_e07_u03_fr04_01: deleted PCC preserves operational data
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart: e2e_e05_u01_fr01_01: PCC shows basic stock card with quantity
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart: e2e_e05_u01_fr03_01: zero stock is configured not missing
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_stock_e2e_test.dart: e2e_e05_u02_fr02_01: adjust existing stock with reason
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr02_01: editor shows store rule price suggestion
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr02_02: cannot suggest without base price
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr02_03: inactive store rule disables save
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr03_01: apply store rule saves price band
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr03_02: overwrite confirm dialog before applying rule
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/catalog/presentation/pages/product_store_price_rule_e2e_test.dart: e2e_e06_u02_fr04_01: PCC shows custom override label
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/my_account/presentation/e2e_e06_u01_fr01_01_my_account_test.dart: e2e_e06_u02_fr01_01: edit profile save
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_form_e2e_test.dart: e2e_e02_u04 — create (S1) e2e_e02_u04_fr01_05: dirty back shows leave confirmation then stay
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u03 — PricingDetailPage (S3) wgt_e02_u03_fr01_01 — chi tiết + CTA Thao tác primary
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty Hủy mở leave confirmation (VConfirmDialog)
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty back mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty system back (maybePop) mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u06 — PricingFormPage edit (S5) SC-06 — dirty Hủy trên form sửa mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u07 — PriceRuleDisableSheet (S6) wgt_e02_u07_fr01_01 — sheet tắt giá riêng
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/tenant_admin/e2e_e02_u01_u03_u07_test.dart: e2e_e02_u07_fr01_01: audit list/search → activation forensic detail

### `tools/c45_env` (1)

- test/config_init_test.dart: init requires profile id and scaffolds from target aggregate

### `packages/c45_design_system` (2)

> **Cập nhật 2026-10-28:** chỉ còn hỏng test đầu (`uses bottom-weighted design-system shadow token`); `panel renders DecoratedBox with boxShadow` đã đạt. DS: 435 đạt / 1 lỗi.

- /Users/macbook/Documents/Đồ án/packages/c45_design_system/test/v_overlay_menu_shell_test.dart: VOverlayMenuShell uses bottom-weighted design-system shadow token
- /Users/macbook/Documents/Đồ án/packages/c45_design_system/test/v_overlay_menu_shell_test.dart: VOverlayMenuShell.panel renders DecoratedBox with boxShadow

### `modules/iam/infrastructure` (21)

- test/iam_owner_activation_retirement_sql_contract_test.dart: (setUpAll)
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract file exists and conforms to migration draft policy headers
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract update_tenant_profile captures pre-mutation before state and after state
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract upsert_legal_profile captures before and masks tax_code
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract legal profile masks registered address before audit persistence
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract update_my_platform_user_profile captures before and masks phone
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract resend and revoke capture before/after with canonical event codes
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract accept_invitation audit is owned by the final cleanup draft
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract masks contact PII before append and flags before/after independently
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract uses canonical identity and invitation schema names
- test/iam_tenant_audit_v2_payload_sql_contract_test.dart: 004_iam_tenant_audit_history_v2_payloads.sql contract never exposes plaintext token, otp, or secret in audit payloads
- test/iam_audit_legacy_cleanup_sql_contract_test.dart: (setUpAll)
- test/iam_audit_app_source_contract_test.dart: audit writer accepts only the two known client app sources
- test/iam_audit_logs_v2_schema_sql_contract_test.dart: (setUpAll)
- test/iam_owner_activation_rpc_contract_test.dart: (setUpAll)
- test/iam_platform_user_profile_sql_contract_test.dart: (setUpAll)
- test/iam_tenant_audit_v2_read_sql_contract_test.dart: (setUpAll)
- test/iam_platform_s15_s16_sql_contract_test.dart: (setUpAll)
- test/iam_active_drafts_sequence_sql_contract_test.dart: no active IAM SQL drafts remain after in-place promote merge
- test/iam_fix_utc_now_offset_sql_contract_test.dart: (setUpAll)
- test/sql/iam_active_store_context_contract_test.dart: (setUpAll)

