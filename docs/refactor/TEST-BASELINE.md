# Mốc test trước refactor

> Chạy ngày 2026-10-07 tại commit `6809122e0` (sau tag `v-legacy-arch` chỉ thêm commit hạ tầng/tài liệu). PLAN P0.5.
> Lệnh: `flutter test --no-pub -r compact` (package Flutter) hoặc `dart test -r compact` (package Dart) trong từng package có thư mục `test/`. Test không cần Supabase.
> **Cách dùng:** sau mỗi phase, test lỗi nằm trong danh sách dưới đây là lỗi có sẵn; lỗi mới ngoài danh sách là do refactor.

**Tổng:** 41 package · 5688 đạt · **160 lỗi**

> **Sau 3-D (2026-10-11):** 4 package IAM, `apps/admin` và `apps/messaging_worker` đã xoá — các hàng tương ứng dưới đây chỉ còn giá trị lịch sử. `tools/vet45_env` giữ nguyên 107 đạt / **1 lỗi có sẵn** (`config_init_test`: `ExampleGenerator` ghi `auth.env` khi `writeEnvCopies`, test kỳ vọng không có); `apps/erp` 1.494 đạt / 59 lỗi, đều nằm trong danh sách dưới đây.

> **Sau 4-C (2026-11-02, review 4-C R1):** đã xoá `modules/partner/{domain,application,infrastructure}`, `modules/{accounting,costing,dashboard}` (không có test), `packages/vet45_resend`; bỏ các hàng tương ứng trong bảng và mục lỗi `modules/partner/infrastructure` (test `alternate_name` chuyển sang `apps/erp/test/features/partner/data/partner_search_sql_contract_test.dart`, nay xanh). `apps/erp` 1.705 đạt / 61 lỗi, đều trong danh sách `apps/erp` dưới đây. `modules/einvoice/application` 217 / 1 (như baseline). `modules/einvoice/infrastructure` **378 đạt / 60 lỗi**: 2 lỗi baseline (`goi1_configuration` nay lỗi cả tệp lúc nạp) + các test `*_sql_contract` / bundle đọc `supabase/migrations/_drafts/0xx_einvoice_*.sql` (`PathNotFoundException`, "draft SQL must exist", kéo theo `LateInitializationError` ở `tearDownAll`) vì 23 draft đã promote thành `20261031001…023` ngày 2026-10-31 (không do 4-C). Các test này cần trỏ sang migration chính thức (lượt promote / Theme 8, PLAN 7.1); tới lúc đó coi 60 lỗi này là có sẵn.

> **Sau 5-C (2026-11-04, review 5-C đạt):** đã xoá `modules/catalog/{domain,application,infrastructure,integration_events}`, `modules/inventory/{domain,application,infrastructure,integration_events}`; bỏ các hàng tương ứng trong bảng và mục lỗi `modules/catalog/infrastructure` (8 test xanh của `price_band_sql_contract_test` chuyển sang `apps/erp/test/features/catalog/data/catalog_sql_contract_test.dart`; 4 test đọc `supabase/migrations/_drafts/…` đã bỏ, Q8 của 5-C). `apps/erp` **2.112 đạt / 59 lỗi**: 57 lỗi trong danh sách `apps/erp` dưới đây (4 test `product_measurement_units_e2e_test` nay xanh, đã bỏ khỏi danh sách) + ⚠️ **2 lỗi mới, không có trong mốc**: `product_guided_create_e2e_test.dart: e2e_e02_u01_fr01_01: duplicate SKU opens existing product in PCC` và `product_change_history_e2e_test.dart: e2e_e07_u04_fr02_01: product change history can be viewed from PCC`. Cả hai hỏng ở bước tìm tên sản phẩm trên tiêu đề PCC, không dính SP-10 / 5-C; xuất hiện trong lượt đổi UI Theme 2 (5-A3 … 5-W), cần xem lại — **chưa** coi là lỗi có sẵn.

| Package | Loại | Đạt | Lỗi |
|---|---|---|---|
| `apps/messaging_worker` | dart | 45 | 0 |
| `apps/admin` | flutter | 324 | **5** |
| `apps/erp` | flutter | 1343 | **61** |
| `tools/vet45_supabase_migrate` | dart | 76 | 0 |
| `tools/vet45_env` | dart | 107 | **1** |
| `packages/vet45_adapters` | dart | 4 | 0 |
| `packages/vet45_annotations` | dart | 8 | 0 |
| `packages/vet45_generator` | dart | 20 | 0 |
| `packages/vet45_misa` | dart | 80 | 0 |
| `packages/vet45_design_system` | flutter | 288 | **2** |
| `packages/vet45_async_query` | dart | 17 | 0 |
| `modules/iam/integration_events` | dart | 3 | 0 |
| `modules/iam/application` | dart | 225 | 0 |
| `modules/iam/infrastructure` | dart | 289 | **21** |
| `modules/iam/domain` | dart | 40 | 0 |
| `modules/pricing/application` | dart | 183 | 0 |
| `modules/pricing/infrastructure` | dart | 150 | **50** |
| `modules/pricing/domain` | dart | 53 | **1** |
| `modules/sales/domain` | dart | 47 | 0 |
| `modules/einvoice/integration_events` | dart | 16 | 0 |
| `modules/einvoice/application` | dart | 217 | **1** |
| `modules/einvoice/infrastructure` | dart | 741 | **2** |
| `modules/einvoice/domain` | dart | 116 | 0 |
| `modules/einvoice/presentation` | flutter | 79 | 0 |
| `modules/partner/integration_events` | dart | 2 | 0 |
| `packages/vet45_shared/testing` | dart | 6 | 0 |
| `packages/vet45_shared/application` | dart | 5 | 0 |
| `packages/vet45_shared/infrastructure` | dart | 22 | 0 |
| `packages/vet45_shared/domain` | dart | 9 | 0 |
| `modules/sales/integration_events` | dart | 4 | 0 |
| `modules/sales/application` | dart | 171 | 0 |
| `modules/sales/infrastructure` | dart | 360 | **11** |
| `packages/vet45_async_query/packages/async_query_flutter` | flutter | 4 | 0 |

## Test đang lỗi

### `apps/admin` (5)

- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/production_boundary_test.dart: presentation.dart does not export Fake* or testing paths
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/widgets/select_organization_bottom_sheet_test.dart: SelectOrganizationBottomSheet renders list of organizations (TA-O-01)
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/iam/presentation_module/widgets/invitation_filter_bottom_sheet_test.dart: InvitationFilterBottomSheet renders all sections and option chips
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/users/presentation/pages/platform_onboarding_page_test.dart: review step displays selected legal entity type correctly
- /Users/macbook/Documents/Đồ án/apps/admin/test/features/users/presentation/pages/platform_onboarding_page_test.dart: organization step fields are submitted to onboarding command

### `apps/erp` (57)

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
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_import_history_e2e_test.dart: e2e_e02_u05 — import (S8) back from preview confirms and cancels the current batch
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_import_history_e2e_test.dart: e2e_e02_u05 — import (S8) canceling the save dialog does not show an error toast
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_import_history_e2e_test.dart: e2e_e02_u05 — import (S8) downloads the backend template through the file service
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u03 — PricingDetailPage (S3) wgt_e02_u03_fr01_01 — chi tiết + CTA Thao tác primary
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty Hủy mở leave confirmation (VConfirmDialog)
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty back mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u04 — PricingFormPage create (S1) SC-06 — dirty system back (maybePop) mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u05 — PricingImportPage (S8) wgt_e02_u05_fr01_01 — wizard import bước chọn file
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u06 — PricingFormPage edit (S5) SC-06 — dirty Hủy trên form sửa mở leave confirmation
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart: wgt_e02_u07 — PriceRuleDisableSheet (S6) wgt_e02_u07_fr01_01 — sheet tắt giá riêng
- /Users/macbook/Documents/Đồ án/apps/erp/test/features/tenant_admin/e2e_e02_u01_u03_u07_test.dart: e2e_e02_u07_fr01_01: audit list/search → activation forensic detail

### `tools/vet45_env` (1)

- test/config_init_test.dart: init requires profile id and scaffolds from target aggregate

### `packages/vet45_design_system` (2)

> **Cập nhật 2026-10-28:** chỉ còn hỏng test đầu (`uses bottom-weighted design-system shadow token`); `panel renders DecoratedBox with boxShadow` đã đạt. DS: 435 đạt / 1 lỗi.

- /Users/macbook/Documents/Đồ án/packages/vet45_design_system/test/v_overlay_menu_shell_test.dart: VOverlayMenuShell uses bottom-weighted design-system shadow token
- /Users/macbook/Documents/Đồ án/packages/vet45_design_system/test/v_overlay_menu_shell_test.dart: VOverlayMenuShell.panel renders DecoratedBox with boxShadow

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

### `modules/pricing/infrastructure` (50)

- test/pricing_sql_contract_test.dart: provider snapshot functions are internal-only
- test/pricing_sql_contract_test.dart: pricing draft owns atomic create and never reads provider tables
- test/pricing_sql_contract_test.dart: S1 view permission variable stays inside create-context scope
- test/pricing_sql_contract_test.dart: S2 search draft has the exact public RPC and access boundary
- test/pricing_sql_contract_test.dart: S2 search derives statuses with inclusive effective boundaries
- test/pricing_sql_contract_test.dart: S2 search combines snapshot filters and stable seek pagination
- test/pricing_sql_contract_test.dart: S2 list redacts floor amount and exposes stable screen actions
- test/pricing_sql_contract_test.dart: S3 detail draft has the exact public RPC and access boundary
- test/pricing_sql_contract_test.dart: S3 detail derives status with inclusive boundaries and health codes
- test/pricing_sql_contract_test.dart: S1 create helper emits S3-compatible health and lifecycle actions
- test/pricing_sql_contract_test.dart: S1 result helper includes disabled lifecycle audit fields
- test/pricing_sql_contract_test.dart: S5 update draft exposes exact RPC signatures and grants
- test/pricing_sql_contract_test.dart: S5 activity constraint accepts rows written by later slices
- test/pricing_sql_contract_test.dart: S5 authoritative update locks version and suppresses no-op activity
- test/pricing_sql_contract_test.dart: S5 update uses provider functions without private table reads
- test/pricing_sql_contract_test.dart: S6 disable draft is atomic, idempotent-before-version, draft-only
- test/pricing_sql_contract_test.dart: S7 reenable draft defines helper, RPCs, fingerprint, and ordering
- test/sql/pricing_sales_working_state_preview_contract_test.dart: 003 pricing sales preview draft enforces scope, precedence, and policy
- test/sql/pricing_customer_price_rule_import_price_parse_contract_test.dart: 018 declares exact touches and remains draft-only
- test/sql/pricing_customer_price_rule_import_price_parse_contract_test.dart: evaluator parses Excel N.0 VN thousands and rejects fraction
- test/domain/customer_price_rule_import/excel_customer_price_rule_import_file_adapter_test.dart: parse successes parses sparse rows and native dates from LibreOffice fixture
- test/sql/pricing_customer_price_rule_lifecycle_br070809_contract_test.dart: 013 import overlap draft blocks duplicate rows without auto-disable
- test/sql/pricing_customer_price_rule_lifecycle_br070809_contract_test.dart: 014 lifecycle draft adds delete resolve exclusion and deleted_at
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 draft header, dependencies, and Touches match replaced functions
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: no timestamped S9 migration and no REGISTRY edit
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 draft defines remembered_price_requests schema and security
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 draft extends rule type, activity, and source trace columns
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 public RPC uses exact params and save_memory permission
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 save RPC acquires idempotency lock before replay lookup
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 save RPC handles idempotency conflict and anonymous skip
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 save RPC uses shared rule-key lock and provider-only reads
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 save RPC stores deterministic business outcomes
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 helper is internal-only and public RPC is granted to clients
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 detail projection exposes redacted source_memory_request_id
- test/sql/pricing_remembered_price_from_order_s9_contract_test.dart: S9 save RPC does not swallow technical errors
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: catalog import resolver draft is internal-only provider
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: S8 pricing import draft defines schema, RPCs, and boundaries
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: S8 preview redacts internal floor and matched-rule identifiers
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: S8 cursor is integer Base64URL and maps invalid input to validation
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: S8 confirm performs authoritative rule and activity mutations
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: S8 confirm policy keeps terminal replay before version rejection
- test/sql/pricing_customer_price_rule_import_s8_contract_test.dart: no timestamped migration was added for S8
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 draft header, dependencies, and Touches match replaced functions
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: no timestamped S10 migration and no REGISTRY edit
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 covering keyset index and public RPC signature
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 checks permission before rule existence
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 cursor decode, tuple predicate, limit+1, and next cursor encoding
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 maps actor fallback, source fallback, reason, and S8/S9 traces
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 floor sanitizer redacts known keys without mutating DB rows
- test/sql/pricing_customer_price_rule_history_s10_contract_test.dart: S10 helper is internal-only and public RPC is granted

### `modules/pricing/domain` (1)

- test/customer_price_rule/customer_price_rule_test.dart: Money rejects zero or negative amount

### `modules/einvoice/application` (1)

- test/fake_einvoice_scenarios_e01_test.dart: EP-01 fake scenarios list_templates_ok returns 2 templates

### `modules/einvoice/infrastructure` (2)

- test/electronic_invoice/einvoice_s4_contract_repair_test.dart: S4 contract freezes ambiguous and scope requirements
- test/schema/einvoice_goi1_configuration_sql_contract_test.dart: Task 4 — tenant_settings disconnect clears the default issuance configuration

### `modules/sales/infrastructure` (11)

- test/domain/sales_receipt/sales_receipt_group_e_sql_contract_test.dart: (setUpAll)
- test/domain/return_exchange_order/sales_return_exchange_group_i_settlement_sql_contract_test.dart: evaluate uses Theme 5 / ADR-2 sign and authoritative line/pricing sources
- test/domain/schema/sales_remove_unused_policy_tables_sql_contract_test.dart: promoted baselines no longer create or reference retired tables
- test/domain/schema/sales_remove_unused_policy_tables_sql_contract_test.dart: policy and context responses preserve empty-array contracts
- test/domain/schema/sales_remove_unused_policy_tables_sql_contract_test.dart: confirmation keeps source, valuation, version and lifecycle guards
- test/domain/schema/sales_remove_unused_policy_tables_sql_contract_test.dart: duplicate bootstrap generations remain synchronized
- test/domain/sales_order/sales_read_group_e_sql_contract_test.dart: (setUpAll)
- test/domain/sales_order/order_detail_current_lines_sql_contract_test.dart: (setUpAll)
- test/domain/sales_order/sales_inquiry_group_f_sql_contract_test.dart: (setUpAll)
- test/domain/sales_order/sales_settlement_rebuild_sql_contract_test.dart: mutations recompute settlement and emit canonical fact + settlement_changed
- test/domain/sales_order_draft/sales_order_draft_sql_contract_test.dart: (setUpAll)
