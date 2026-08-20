# TH08 / SG-01 --- Mapped UI Tree

## Thiết lập & mức sẵn sàng HĐĐT

> **Purpose:** UI implementation contract mapping the approved SG-01
> design and business states to VET45 presentation ownership and Design
> System usage.
>
> **Scope:** SG-01 frontend UI only. This document does not define
> backend/provider integration, repository-wide frontend conventions, or
> AI/tool-specific execution instructions.

------------------------------------------------------------------------

## 1. Source of Truth

For SG-01-specific implementation details, use the following precedence:

1.  **Theme 08 BA specification** --- business rules, permissions,
    readiness semantics, valid states and actions.
2.  **Approved SG-01 design** --- visual hierarchy, copy, variants and
    interaction presentation.
3.  **E-Invoice Audit Manifest** --- specimen identity, surface type and
    planned implementation path.
4.  **Existing repository implementation** --- actual component APIs,
    architecture and reusable implementation.
5.  **This document** --- mapping between the sources above.

Repository-wide architecture, frontend layering, coding workflow and
verification rules remain governed by their existing project documents
and are not duplicated here.

------------------------------------------------------------------------

## 2. Related Implementation References

### Theme documentation

``` text
docs/themes/TH-08-e-invoice/
└── Epic-01-provider-connection-config/
```

### Existing legacy implementation

The following existing implementation may contain reusable SG-01
presentation logic or UI:

``` text
apps/erp/lib/features/more/presentation/einvoice_settings/
├── bloc/
│   ├── einvoice_settings_cubit.dart
│   └── einvoice_settings_state.dart
└── pages/
    ├── einvoice_auto_page.dart
    ├── einvoice_connection_page.dart
    ├── einvoice_settings_page.dart
    └── einvoice_template_page.dart
```

These are implementation references only. Final ownership follows the
planned paths in the E-Invoice Audit Manifest.

------------------------------------------------------------------------

## 3. Specimen Catalog & Ownership

  -----------------------------------------------------------------------------------------------------------------------------------------------------------
  Specimen       Surface        Meaning        Ownership      Planned implementation
  -------------- -------------- -------------- -------------- -----------------------------------------------------------------------------------------------
  `SG01-D01`     Full-screen    Tổng quan ---  App feature    `apps/erp/lib/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart`
                 route          Chưa sẵn sàng  page           

  `SG01-D02`     Full-screen    Tổng quan ---  App feature    `apps/erp/lib/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart`
                 route          Sẵn sàng       page           

  `SG01-D04-A`   Full-screen    Kết nối MISA   App feature    `apps/erp/lib/features/einvoice/presentation/pages/provider_connection_page.dart`
                 editor         --- Chưa kết   page           
                                nối                           

  `SG01-D04-B`   Full-screen    Kết nối MISA   App feature    `apps/erp/lib/features/einvoice/presentation/pages/provider_connection_page.dart`
                 editor         --- Đã kết nối page           

  `SG01-D05`     Full-screen    Cấu hình phát  App feature    `apps/erp/lib/features/einvoice/presentation/pages/default_issuance_configuration_page.dart`
                 editor         hành mặc định  page           

  `SG01-D06`     Full-screen    Chính sách tự  App feature    `apps/erp/lib/features/einvoice/presentation/pages/automation_policy_page.dart`
                 editor         động           page           

  `SG01-O01`     Confirmation   Xác nhận ngắt  Module         `modules/einvoice/presentation/lib/src/widgets/disconnect_provider_sheet.dart`
                 sheet          kết nối        reusable       
                                               widget         

  `SG01-O02`     Action sheet   Thao tác kết   Module         `modules/einvoice/presentation/lib/src/widgets/provider_connection_action_sheet.dart`
                                nối            reusable       
                                               widget         

  `SG01-S01`     State message  Không có quyền Module         `modules/einvoice/presentation/lib/src/widgets/configuration_permission_denied_state.dart`
                                               reusable       
                                               widget         

  `SG01-S02`     State message  Không tải được Module         `modules/einvoice/presentation/lib/src/widgets/configuration_load_error_state.dart`
                                thiết lập      reusable       
                                               widget         
  -----------------------------------------------------------------------------------------------------------------------------------------------------------

### Variant rules

-   `SG01-D01` and `SG01-D02` are states of the **same overview page**.
-   `SG01-D04-A` and `SG01-D04-B` are states of the **same provider
    connection page**.
-   Ready/not-ready and connected/disconnected must not be implemented
    as duplicate page identities.

------------------------------------------------------------------------

## 4. SG-01 State Contract

SG-01 presentation needs to represent these state dimensions:

``` text
Configuration State
├── access
│   ├── allowed
│   └── denied
│
├── load
│   ├── loading
│   ├── loaded
│   └── failure
│
├── readiness
│   ├── ready
│   └── notReady
│       └── blockerCount
│
├── connection
│   ├── disconnected
│   ├── connected
│   ├── recheckRequired
│   └── reconnectRequired
│
├── issuanceConfiguration
│   ├── missing
│   ├── valid
│   ├── unavailable / stale
│   └── incompatible
│
├── autoIssue
└── autoSend
```

Existing application/domain types should be reused when they already
represent these concepts.

### Readiness rule

Readiness must **not** be derived from MISA connection alone.

``` text
Seller legal profile readiness
+ valid provider connection
+ usable default issuance configuration
+ compatible signing method
= issuance configuration readiness
```

`autoSend` does not determine issuance readiness.

------------------------------------------------------------------------

# 5. Mapped UI Tree

## 5.1 SG01-D01 / SG01-D02 --- Configuration Overview

**Page**

``` text
apps/erp/lib/features/einvoice/presentation/pages/
einvoice_configuration_overview_page.dart
```

**Tree**

``` text
EInvoiceConfigurationOverviewPage
└── VPageScaffold
    ├── title: "Hóa đơn điện tử"
    ├── showBackButton: true
    └── body
        └── scrollable content
            ├── ReadinessSummary
            ├── SettingsNavigationItem
            │   └── Kết nối MISA
            ├── SettingsNavigationItem
            │   └── Cấu hình phát hành
            └── SettingsNavigationItem
                └── Tự động hóa
```

### D01 --- Chưa sẵn sàng

``` text
ReadinessSummary
└── VBanner
    ├── status: warning
    ├── eyebrow: "Cần hoàn tất"
    ├── title: "Chưa sẵn sàng phát hành"
    ├── description:
    │   "Còn {blockerCount} điều kiện cần hoàn tất trước khi có thể phát hành hóa đơn điện tử."
    └── action
        └── VButton
            ├── variant: link
            └── label: "Xem và hoàn tất"
```

`blockerCount` is state-derived. A fixed number is appropriate only for
a specific preview fixture.

### D02 --- Sẵn sàng

``` text
ReadinessSummary
└── VBanner
    ├── status: success
    ├── title: "Sẵn sàng phát hành"
    └── description:
        "Đã đủ điều kiện phát hành hóa đơn điện tử từ đơn hàng Hoàn tất."
```

### Overview navigation items

``` text
Kết nối MISA
├── disconnected
│   └── "Chưa kết nối MISA meInvoice"
├── connected
│   └── "MISA meInvoice · Đã kết nối"
└── other connection states
    └── copy defined by BA/design
```

``` text
Cấu hình phát hành
├── missing
│   └── "Chưa chọn mẫu hóa đơn"
└── configured
    └── "{templateNumber} · {templateSymbol} · {signingSummary}"
```

``` text
Tự động hóa
└── summary derived from autoIssue + autoSend

Examples:
"Phát hành tự động · Gửi email tự động"
"Phát hành thủ công · Gửi email thủ công"
```

------------------------------------------------------------------------

## 5.2 SG01-D04-A / SG01-D04-B --- Provider Connection

**Page**

``` text
apps/erp/lib/features/einvoice/presentation/pages/
provider_connection_page.dart
```

### D04-A --- Chưa kết nối

``` text
ProviderConnectionPage
└── VPageScaffold
    ├── title: "Kết nối MISA"
    ├── showBackButton: true
    └── body
        └── form content
            ├── IntroText
            ├── SectionTitle: "Thông tin kết nối"
            ├── SellerInfoCard
            │   ├── InfoRow
            │   │   ├── "Nhà cung cấp"
            │   │   └── "MISA meInvoice"
            │   └── InfoRow
            │       ├── "Mã số thuế đơn vị phát hành"
            │       └── sellerTaxCode
            ├── AccountField
            ├── PasswordField
            ├── HelperText
            └── BottomActions
                ├── "Hủy"
                └── "Kết nối"
```

UI validation:

``` text
account  → required
password → required
```

Stored secrets must not be rendered back into the UI.

### D04-B --- Đã kết nối

``` text
ProviderConnectionPage
└── VPageScaffold
    ├── title: "Kết nối MISA"
    └── body
        └── content
            ├── SectionTitle: "Thông tin kết nối"
            ├── ConnectionInfoCard
            │   ├── InfoRow: Trạng thái → "Đã kết nối"
            │   ├── InfoRow: Nhà cung cấp → "MISA meInvoice"
            │   ├── InfoRow: Tài khoản → safe display account
            │   └── InfoRow: MST đơn vị phát hành → sellerTaxCode
            ├── MetadataText
            │   └── "Kiểm tra gần nhất: {time}, {date}"
            └── ActionButton
                └── "Thao tác"
```

`Thao tác` opens `SG01-O02`.

------------------------------------------------------------------------

## 5.3 SG01-O02 --- Provider Connection Actions

**Module widget**

``` text
modules/einvoice/presentation/lib/src/widgets/
provider_connection_action_sheet.dart
```

``` text
ProviderConnectionActionSheet
└── BottomSheet
    ├── title: "Kết nối MISA"
    └── actions
        ├── Kiểm tra lại kết nối
        │   └── "Xác minh trạng thái kết nối hiện tại"
        ├── Kết nối lại
        │   └── "Thay đổi tài khoản hoặc mật khẩu"
        └── Ngắt kết nối
            └── "Không thể phát hành hóa đơn điện tử mới"
```

Interaction mapping:

``` text
Kiểm tra lại kết nối → recheck action
Kết nối lại          → D04-A / reconnect mode
Ngắt kết nối         → O01
```

------------------------------------------------------------------------

## 5.4 SG01-O01 --- Disconnect Provider Confirmation

**Module widget**

``` text
modules/einvoice/presentation/lib/src/widgets/
disconnect_provider_sheet.dart
```

``` text
DisconnectProviderSheet
└── ConfirmationSheet
    ├── title: "Ngắt kết nối MISA?"
    ├── description:
    │   "Sau khi ngắt kết nối, không thể phát hành hóa đơn điện tử mới.
    │    Hóa đơn và lịch sử đã phát sinh vẫn được giữ nguyên."
    └── actions
        ├── "Giữ kết nối"
        └── "Ngắt kết nối"
```

Interaction mapping:

``` text
Giữ kết nối → close sheet
Ngắt kết nối → submit disconnect action
```

Historical invoices/history remain unaffected by the disconnect state.

------------------------------------------------------------------------

## 5.5 SG01-D05 --- Default Issuance Configuration

**Page**

``` text
apps/erp/lib/features/einvoice/presentation/pages/
default_issuance_configuration_page.dart
```

``` text
DefaultIssuanceConfigurationPage
└── VPageScaffold
    ├── title: "Cấu hình phát hành"
    ├── showBackButton: true
    └── body
        └── form content
            ├── IntroText
            ├── TemplateField
            │   ├── label: "Mẫu hóa đơn"
            │   └── Select
            ├── SyncMetadata
            ├── TemplateInfoCard
            │   ├── InfoRow: Ký hiệu
            │   ├── InfoRow: Cấp mã
            │   └── InfoRow: Loại hóa đơn
            ├── SigningConfigurationField
            │   ├── label: "Hình thức ký số"
            │   └── Select
            └── BottomActions
                ├── "Hủy"
                └── "Lưu"
```

### Known design/spec mismatch

BA requires **Hình thức ký số** to be represented separately from the
invoice template.

If the approved design version still does not contain this field, this
remains an open design/spec mismatch and should not be silently resolved
by implementation.

------------------------------------------------------------------------

## 5.6 SG01-D06 --- Automation Policy

**Page**

``` text
apps/erp/lib/features/einvoice/presentation/pages/
automation_policy_page.dart
```

``` text
AutomationPolicyPage
└── VPageScaffold
    ├── title: "Tự động hóa"
    ├── showBackButton: true
    └── body
        └── content
            ├── AutomationCard
            │   ├── SectionTitle: "Quy tắc tự động"
            │   ├── SwitchSettingRow
            │   │   ├── "Tự động phát hành"
            │   │   └── supportingText
            │   └── SwitchSettingRow
            │       ├── "Tự động gửi email"
            │       └── supportingText
            └── BottomActions
                ├── "Hủy"
                └── "Lưu"
```

State:

``` text
autoIssue: bool
autoSend: bool
```

Availability of an automation option follows the provider/configuration
capability defined by the BA/application contract.

------------------------------------------------------------------------

## 5.7 SG01-S01 --- Permission Denied

**Module widget**

``` text
modules/einvoice/presentation/lib/src/widgets/
configuration_permission_denied_state.dart
```

``` text
ConfigurationPermissionDeniedState
└── StateMessage
    ├── semantic icon
    ├── title: "Không có quyền truy cập"
    ├── description:
    │   "Bạn không có quyền xem hoặc thay đổi thiết lập hóa đơn điện tử của Tổ chức này."
    └── action: "Quay lại"
```

Configuration content is not exposed in this state.

------------------------------------------------------------------------

## 5.8 SG01-S02 --- Configuration Load Error

**Module widget**

``` text
modules/einvoice/presentation/lib/src/widgets/
configuration_load_error_state.dart
```

``` text
ConfigurationLoadErrorState
└── StateMessage
    ├── semantic error icon
    ├── title: "Không thể tải dữ liệu"
    ├── description:
    │   "Không thể tải thiết lập hóa đơn điện tử. Hãy thử lại để kiểm tra mức sẵn sàng."
    └── action: "Thử lại"
```

Initial configuration load failure is independent from provider
credential validity.

------------------------------------------------------------------------

## 6. Presentation Ownership Map

SG-01-specific UI compositions should follow these ownership boundaries:

``` text
Design System
└── generic visual primitives/components

E-Invoice module presentation
├── DisconnectProviderSheet
├── ProviderConnectionActionSheet
├── ConfigurationPermissionDeniedState
└── ConfigurationLoadErrorState

ERP E-Invoice feature presentation
├── SG-01 page compositions
└── feature-only compositions required by those pages
```

Potential feature-only compositions include:

``` text
ReadinessSummary
SettingsNavigationItem
ConnectionInfoCard
TemplateInfoCard
SwitchSettingRow
EditorBottomActions
InfoRow
```

These names are descriptive mappings, not mandatory class/file names.
Existing equivalent widgets take precedence.

------------------------------------------------------------------------

## 7. Design System Mapping

### Confirmed from existing SG-01 implementation

  UI responsibility       VET45 mapping
  ----------------------- -------------------------
  Page shell              `VPageScaffold`
  Readiness banner        `VBanner`
  Success semantic        `VBannerStatus.success`
  Warning semantic        `VBannerStatus.warning`
  Card                    `VCard`
  Icon container          `VIconBox`
  Icon                    `VIcon`
  Text                    `VText`
  Button                  `VButton`
  Link button             `VButtonVariant.link`
  Spacing                 `VSpacing`, `VGap`
  Radius                  `VRadius`
  Semantic/theme colors   `context.vColors`

### Component mapping requiring repository confirmation

``` text
Account input     → VTextField or current DS equivalent
Password input    → VPasswordField or current DS equivalent
Template select   → VSelect or current DS equivalent
Signing select    → VSelect or current DS equivalent
Automation toggle → VSwitch or current DS equivalent
Bottom sheet      → current VET45 sheet component/pattern
State message     → current VET45 state-message component/pattern
```

The exact existing DS API takes precedence over names shown here.

------------------------------------------------------------------------

## 8. Preview State Coverage

SG-01 harness/fake data should be capable of representing at least:

``` text
Not ready overview
Ready overview

Provider disconnected
Provider connected
Provider recheck required
Provider reconnect required

Issuance configuration missing
Issuance configuration valid

Automation manual
Automation enabled

Permission denied
Configuration load failure
```

The existing E-Invoice fake/testing module should remain the preview
data source.

Example non-sensitive fixture values:

``` text
provider: "MISA meInvoice"
sellerTaxCode: "0101234567"
account: "ketoan@anphu.vn"

template:
  number: "1/001"
  symbol: "C26TAA"
  invoiceType: "Hóa đơn GTGT"
  authorityMode: "Có mã của cơ quan thuế"

lastCheckedAt: "10:40, 05/08/2026"
lastSyncedAt: "10:38, 05/08/2026"
```

Real credentials must not be used in preview fixtures.

------------------------------------------------------------------------

## 9. Harness & Audit Mapping

SG-01 specimens are represented in the E-Invoice audit catalog using:

``` text
pending → Chưa làm
stub    → Stub
done    → Done
```

This document does **not** define the repository-wide criteria for
moving between audit statuses.

For SG-01, the important mapping is:

``` text
Specimen ID
↔ planned implementation path
↔ preview state
↔ audit entry
```

A specimen's audit state must remain consistent with the repository's
existing audit convention.

------------------------------------------------------------------------

## 10. Known SG-01 Gaps / Mismatches

### GAP-01 --- Signing method

``` text
Surface: SG01-D05
Type: BA ↔ Design mismatch
```

BA requires signing method configuration separately from invoice
template. Confirm whether the current approved design has incorporated
it.

### GAP-02 --- Legacy implementation location

``` text
Type: Existing code ↔ planned architecture mismatch
```

Legacy SG-01 code exists under:

``` text
apps/erp/lib/features/more/presentation/einvoice_settings/
```

while the E-Invoice Audit Manifest plans the new surfaces under:

``` text
apps/erp/lib/features/einvoice/presentation/
modules/einvoice/presentation/
```

Legacy code may provide reusable implementation but should not redefine
final ownership.

### GAP-03 --- Legacy readiness calculation

The previously reviewed implementation derives the overview banner from:

``` text
misaConnected
```

This does not represent the complete Theme 08 readiness contract and
must not remain the sole readiness criterion.

------------------------------------------------------------------------

## 11. Implementation Dependencies

SG-01 has the following UI dependency direction:

``` text
Design System components
        ↓
Module reusable widgets
        ↓
Feature-only compositions
        ↓
Pages
        ↓
Harness specimen rendering
```

Repository-wide rules governing how these layers are created, tested,
exported and verified are intentionally not repeated in this document.

------------------------------------------------------------------------

## 12. SG-01 Completion Map

``` text
SG01-D01 / D02
Overview
├── readiness state
├── readiness banner
├── provider summary
├── issuance configuration summary
└── automation summary

SG01-D04-A / D04-B
Provider connection
├── disconnected form
├── connected information
└── connection actions → O02

SG01-O02
Provider actions
└── disconnect → O01

SG01-O01
Disconnect confirmation

SG01-D05
Default issuance configuration
├── template
├── template information
└── signing configuration

SG01-D06
Automation policy
├── auto issue
└── auto send

SG01-S01
Permission denied

SG01-S02
Configuration load failure
```
