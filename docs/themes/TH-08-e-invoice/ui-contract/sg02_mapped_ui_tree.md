# TH08 / SG-02 — Mapped UI Tree
## Hóa đơn điện tử trên đơn hàng & xem trước MISA

> **Purpose:** UI contract ở cấp Screen Group giữa Theme 08 SRS, approved SG-02 design và implementation.
>
> **Scope:** SG-02 only.
>
> **Primary contexts:** `SalesOrder detail` và `Sales result`.
>
> **Boundary:** Theme 05 sở hữu hai màn nguồn. SG-02 sở hữu E-Invoice row/menu/action surfaces được compose vào các màn nguồn; không dựng lại toàn bộ Chi tiết đơn hàng hoặc Kết quả bán hàng.

---

## 1. Ownership boundary

### Theme 05 owns

```text
SalesOrderDetail
├── order header / summary
├── payment & debt
├── product lines
├── receipt / sales document
└── source-screen navigation

SalesResult
├── completed-order result
├── customer summary
├── payment summary
├── receipt / sales document
└── source-screen navigation
```

### Theme 08 / SG-02 owns

```text
E-Invoice presentation on source screens
├── OrderEInvoiceRow
├── PreIssueEInvoiceActionSheet
│   ├── idle
│   ├── previewLoading
│   └── buyerNotReady
├── ConfigurationBlockerResult
├── OrderDataBlockerResult
├── PreviewFailureToast
└── PostIssueEInvoiceActionSheet
    ├── notSent
    ├── sending
    ├── sent
    ├── sendFailed
    └── officialViewLoading
```

SG-02 does not create a new standalone order-detail or sales-result screen.

---

## 2. Specimen ≠ Widget

A specimen ID is an **auditable UI/state case**, not necessarily a unique Flutter widget.

The Audit Manifest intentionally maps multiple SG-02 specimens to the same planned widget path.

### Implementation units

```text
1. OrderEInvoiceRow
   → SG02-R01
   → SG02-R02

2. PreIssueEInvoiceActionSheet
   → SG02-O01
   → SG02-O02
   → SG02-O03
   → SG02-O04
   → buyerNotReady design variant ("SG02-O07" on design)

3. ConfigurationBlockerResult
   → SG02-D01

4. OrderDataBlockerResult
   → SG02-D02

5. PreviewFailureToast
   → SG02-T01

6. PostIssueEInvoiceActionSheet
   → SG02-O05
      ├── notSent
      ├── sending
      ├── sent
      └── sendFailed
   → SG02-O06
```

### Planned widget paths from Audit Manifest

```text
SG02-R01 / R02
→ modules/einvoice/presentation/lib/src/widgets/order_einvoice_row.dart

SG02-O01 / O02 / O03 / O04
→ modules/einvoice/presentation/lib/src/widgets/pre_issue_einvoice_action_sheet.dart

SG02-D01
→ modules/einvoice/presentation/lib/src/widgets/configuration_blocker_result.dart

SG02-D02
→ modules/einvoice/presentation/lib/src/widgets/order_data_blocker_result.dart

SG02-T01
→ modules/einvoice/presentation/lib/src/widgets/preview_failure_toast.dart

SG02-O05 / O06
→ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  post_issue_einvoice_action_sheet.dart
```

> Note: Pre-issue compositions remain under `modules/einvoice/presentation/` (ADR 11 debt). Post-issued S4 sheets are app-owned.

---

## 3. Canonical specimen catalog

| Specimen | Surface | Context | State / meaning |
|---|---|---|---|
| `SG02-R01` | Contextual row | Chi tiết đơn hàng | HĐĐT chưa phát hành |
| `SG02-R02` | Contextual row | Kết quả bán hàng | HĐĐT chưa phát hành |
| `SG02-O01` | Action Sheet | Chi tiết đơn hàng | Menu trước phát hành — idle |
| `SG02-O02` | Action Sheet variant | Chi tiết đơn hàng | Preview loading |
| `SG02-O03` | Action Sheet | Kết quả bán hàng | Same contract O01 |
| `SG02-O04` | Action Sheet variant | Kết quả bán hàng | Same contract O02 |
| `SG02-D01` | Full-screen result | ConfigurationReadiness | Blocker — Thiết lập HĐĐT |
| `SG02-D02` | Full-screen result | SalesOrder + BuyerInvoiceSnapshot | Blocker — Thông tin đơn hàng |
| `SG02-T01` | Toast on source | Preview request | Technical failure |
| `SG02-O05` | Action Sheet | ElectronicInvoice reference | Menu sau phát hành |
| `SG02-O06` | Action Sheet variant | ElectronicInvoice reference | Official-view loading |

### Design-only variants

Approved design shows:

```text
SG02-O05-A → Đã phát hành · Chưa gửi
SG02-O05-B → Đã phát hành · Đang gửi
SG02-O05-C → Đã phát hành · Đã gửi
SG02-O05-D → Đã phát hành · Gửi lỗi
```

These are `deliveryStatus` variants of `PostIssueEInvoiceActionSheet`, not independent widgets.

The design also labels a buyer-not-ready sheet as `SG02-O07`. The current SRS/Audit Manifest canonical catalog stops at `O06`, so this contract treats O07 as:

```text
PreIssueEInvoiceActionSheet
+ buyerNotReady state
+ warning/banner content
```

Do not create a new public widget or route solely for O07 unless the current Audit Manifest is later updated to make O07 canonical.

---

## 4. State contract

```text
Order E-Invoice State
├── sourceContext
│   ├── salesOrderDetail
│   └── salesResult
├── invoiceStatus
│   ├── notIssued
│   ├── processing
│   ├── issued
│   └── issueFailed
├── configurationReadiness
│   ├── ready
│   └── blocked
│       ├── legalProfile
│       ├── providerConnection
│       ├── issuanceConfiguration
│       └── signing
├── buyerOrderReadiness
│   ├── ready
│   └── notReady
├── preview
│   ├── idle
│   ├── loading
│   └── failed
├── officialView
│   ├── idle
│   └── loading
└── deliveryStatus
    ├── notSent
    ├── sending
    ├── sent
    └── sendFailed
```

Existing application/domain types take precedence when they already represent these concepts.

### Critical semantic rule

`buyerOrderReadiness = notReady` does **not** mean all E-Invoice actions are disabled.

```text
Buyer/order NOT_READY
├── Phát hành hóa đơn điện tử → blocked
├── Kiểm tra & xem trước      → may remain available when provider capability allows
└── Gửi hóa đơn               → disabled before issuance
```

For an organization buyer, missing tax code after completion is an issuance blocker but does not automatically prohibit preview.

---

## 5. SG02-R01 / R02 — OrderEInvoiceRow

R01 and R02 are two host contexts of the same SG-02 component.

```text
Theme05SourceScreen
└── DocumentsAndInvoicesSection
    ├── SalesReceiptRow                 ← Theme 05
    └── OrderEInvoiceRow                ← SG-02
        ├── LeadingIcon
        ├── Content
        │   ├── title: "Hóa đơn điện tử"
        │   └── helper / readiness text
        ├── StatusBadge
        └── TrailingChevron
```

Canonical row intent:

```text
title  → "Hóa đơn điện tử"
helper → state-specific supporting text
status → trailing
```

Example not-ready design:

```text
helper → "Chưa đủ thông tin"
status → "Chưa phát hành"
```

Behavior:

```text
notIssued + no competing operation
→ tap
→ PreIssueEInvoiceActionSheet

processing
→ show processing state
→ do not allow competing E-Invoice operation

issued
→ tap
→ PostIssueEInvoiceActionSheet
```

Placement is limited to:

- Chi tiết đơn hàng.
- Kết quả bán hàng after successful order creation.

Do not add a separate E-Invoice row/action to the order list.

---

## 6. PreIssueEInvoiceActionSheet — O01 / O02 / O03 / O04 / buyerNotReady

One public widget owns all pre-issued menu states:

```text
PreIssueEInvoiceActionSheet
├── optional ReadinessWarning
├── optional CorrectionAction
└── ActionList
    ├── IssueInvoiceAction
    ├── PreviewInvoiceAction
    └── SendInvoiceAction
```

The source context (`salesOrderDetail` vs `salesResult`) does not require a different public widget.

### 6.1 Idle — SG02-O01 / O03

```text
PreIssueEInvoiceActionSheet
└── VBottomSheet / current DS sheet pattern
    ├── title: "Hóa đơn điện tử"
    └── ActionList
        ├── IssueInvoiceAction
        │   ├── title: "Phát hành hóa đơn điện tử"
        │   ├── supportingText: "Gửi phát hành qua MISA"
        │   └── trailing: chevron
        ├── PreviewInvoiceAction
        │   ├── title: "Kiểm tra & xem trước"
        │   ├── supportingText: "Kiểm tra và mở bản xem trước từ MISA"
        │   └── trailing: chevron
        └── SendInvoiceAction
            ├── title: "Gửi hóa đơn"
            ├── supportingText: "Gửi qua email"
            ├── badge: "Chưa gửi"
            └── disabled
```

Action semantics:

```text
Phát hành
→ re-evaluate issuance readiness
→ configuration blocker → D01
→ buyer/order blocker → D02
→ ready → SG-03 confirmation flow

Kiểm tra & xem trước
→ validate preview eligibility
→ request MISA preview
→ loading → O02/O04
→ success → provider preview viewer
→ technical failure → T01

Gửi hóa đơn
→ disabled before issuance
```

Opening the sheet alone must not create preview, issuance, delivery, or another side effect.

### 6.2 Preview loading — SG02-O02 / O04

Same widget, different state:

```text
PreIssueEInvoiceActionSheet
├── IssueInvoiceAction
│   └── disabled
├── PreviewInvoiceAction
│   ├── copy unchanged
│   ├── loading indicator
│   └── repeated interaction blocked
└── SendInvoiceAction
    └── disabled
```

Loading belongs specifically to `Kiểm tra & xem trước`.

Do not:

- replace the whole sheet with a global spinner;
- change the Preview action copy;
- permit repeated preview submission;
- start issuance after preview success.

Preview success opens the MISA-provided preview. VET45 does not build a substitute legal invoice preview.

### 6.3 Buyer NOT_READY — design label SG02-O07

This is another state of `PreIssueEInvoiceActionSheet`.

```text
PreIssueEInvoiceActionSheet
├── ReadinessWarning
│   ├── title: "Chưa đủ thông tin để phát hành"
│   └── description:
│       "Khách hàng còn thiếu thông tin bắt buộc để phát hành hóa đơn."
├── CorrectionAction
│   └── "Cập nhật thông tin khách hàng"
├── IssueInvoiceAction
│   ├── supportingText: "Cần bổ sung đủ thông tin"
│   └── disabled
├── PreviewInvoiceAction
│   ├── title: "Kiểm tra & xem trước"
│   ├── supportingText: "Kiểm tra và mở bản xem trước từ MISA"
│   └── enabled when preview capability allows
└── SendInvoiceAction
    ├── badge: "Chưa gửi"
    └── disabled
```

`ReadinessWarning` may map to `VBanner` only if the existing VBanner anatomy matches the approved design.

Correction behavior:

```text
Cập nhật thông tin khách hàng
→ Theme 05 correction owner
→ preserve SalesOrder origin
→ return
→ re-evaluate readiness
→ do NOT auto-resume preview
→ do NOT auto-start issuance
```

---

## 7. SG02-D01 — ConfigurationBlockerResult

```text
ConfigurationBlockerResult
└── FullScreenResult / existing state-result pattern
    ├── AppBar
    │   ├── back
    │   └── title: "Điều kiện hóa đơn điện tử"
    └── ResultCard
        ├── warning semantic icon
        ├── title: "Chưa thể tiếp tục"
        ├── description:
        │   "Hoàn tất kết nối MISA và cấu hình phát hành hóa đơn điện tử trước khi tiếp tục."
        └── action: "Mở thiết lập"
```

Possible blockers:

```text
legal profile
provider connection
issuance configuration/template
signing compatibility
```

`Mở thiết lập` goes to the owning correction flow (SG-01 or Theme 01 as applicable), preserving SalesOrder/source context.

After return:

```text
re-evaluate
do not automatically resume preview/issuance
```

---

## 8. SG02-D02 — OrderDataBlockerResult

```text
OrderDataBlockerResult
└── FullScreenResult / existing state-result pattern
    ├── AppBar
    │   ├── back
    │   └── title: "Điều kiện hóa đơn điện tử"
    └── ResultCard
        ├── warning semantic icon
        ├── title: "Chưa đủ thông tin phát hành"
        ├── description:
        │   "Khách hàng còn thiếu thông tin bắt buộc. Cập nhật hồ sơ để tiếp tục."
        └── action: "Cập nhật hồ sơ"
```

Theme 08 reports the blocker but does not directly edit Theme 05-owned order/buyer invoice information.

```text
Cập nhật hồ sơ
→ Theme 05 correction owner
→ preserve SalesOrder origin
→ return
→ re-evaluate
→ no automatic preview/issuance resume
```

---

## 9. SG02-T01 — PreviewFailureToast

```text
Theme05SourceScreen
└── PreviewFailureToast
    ├── semantic: error
    ├── message:
    │   "Không thể tạo bản xem trước. Vui lòng thử lại."
    └── dismiss
```

Behavior:

```text
technical preview failure
→ return/remain on correct Theme 05 source owner
→ keep issuance state unchanged
→ retry only after explicit user Preview action
```

No new full-screen technical-preview error is introduced.

---

## 10. PostIssueEInvoiceActionSheet — O05 / O06

Pre-issue and post-issue sheets may share low-level visual anatomy internally, but they are **different public semantic widgets**.

Do not merge them into one public widget with a large set of unrelated booleans.

```text
PreIssueEInvoiceActionSheet
→ issuance readiness
→ preview eligibility
→ issue action
→ pre-issue send disabled

PostIssueEInvoiceActionSheet
→ official invoice reference
→ official viewer
→ documents
→ delivery/send status
```

One public `PostIssueEInvoiceActionSheet` owns O05 and O06.

```text
PostIssueEInvoiceActionSheet
├── ViewOfficialInvoiceAction
├── InvoiceDocumentsAction
└── SendInvoiceAction
```

### 10.1 Normal post-issued — SG02-O05

```text
PostIssueEInvoiceActionSheet
└── VBottomSheet / current DS sheet pattern
    ├── title: "Hóa đơn điện tử"
    └── ActionList
        ├── ViewOfficialInvoiceAction
        │   ├── title: "Xem hóa đơn điện tử"
        │   ├── supportingText: "Mở hóa đơn chính thức từ MISA"
        │   └── trailing: chevron
        ├── InvoiceDocumentsAction
        │   ├── title: "Tài liệu XML & PDF"
        │   ├── supportingText: "Lưu bản PDF hoặc tệp XML"
        │   └── trailing: chevron
        └── SendInvoiceAction
            ├── title: "Gửi hóa đơn"
            ├── supportingText: "Gửi qua email"
            ├── VBadge: deliveryStatus
            └── trailing: chevron
```

Destinations:

```text
Xem hóa đơn điện tử → O06 → official MISA viewer
Tài liệu XML & PDF  → SG-06
Gửi hóa đơn         → SG-07
```

There is no SG-05 UI dependency.

### 10.2 Delivery variants — O05-A/B/C/D

Only delivery presentation changes:

```text
deliveryStatus
├── notSent    → VBadge("Chưa gửi")
├── sending    → VBadge("Đang gửi", VBadgeStatus.processing)
├── sent       → VBadge("Đã gửi")
└── sendFailed → VBadge("Gửi lỗi")
```

Do not create separate action-sheet implementations for these four frames.

**Interaction rule:** when the send action's active badge is
`VBadgeStatus.processing` (`Đang gửi`), that action item is disabled — no
`onTap` / no click — while the processing badge visual is preserved. Other
actions stay available unless another gate applies (e.g. official-view loading).
Shared helper: presentation `EInvoiceStatusInteraction`.

Delivery status does not change the authoritative invoice issuance result.

If an invoice has already been sent successfully and a later resend is processing, failed or uncertain, primary delivery status remains `Đã gửi`; secondary resend feedback belongs to SG-07.

### 10.3 Official-view loading — SG02-O06

Same `PostIssueEInvoiceActionSheet`, loading state:

```text
PostIssueEInvoiceActionSheet
├── ViewOfficialInvoiceAction
│   ├── copy unchanged
│   ├── loading indicator
│   └── repeated interaction blocked
├── InvoiceDocumentsAction
│   └── disabled while official view is opening
└── SendInvoiceAction
    └── disabled while official view is opening
```

Loading belongs specifically to `Xem hóa đơn điện tử`.

On success:

```text
open MISA official invoice
```

---

## 11. Shared action-sheet anatomy

`PreIssueEInvoiceActionSheet` and `PostIssueEInvoiceActionSheet` may share internal presentation primitives/compositions if the repository supports it, for example:

```text
EInvoiceActionItem
├── icon
├── title
├── supportingText
├── enabled / disabled
├── loading
├── badge?
├── trailing?
└── onTap
```

or an internal sheet layout:

```text
EInvoiceActionSheetLayout
├── optional header content
└── action items
```

These should remain internal/shared presentation anatomy where appropriate.

Do not collapse pre-issue and post-issue business contracts into one public widget merely to reduce file count.

---

## 12. Action availability matrix

| Condition | Issue | Preview | Send | View official | Documents |
|---|---:|---:|---:|---:|---:|
| Pre-issue + ready | Enabled | Enabled if permitted/capable | Disabled | N/A | N/A |
| Pre-issue + configuration blocker | Blocked → D01 | Gate independently | Disabled | N/A | N/A |
| Pre-issue + buyer/order NOT_READY | Disabled | May remain enabled | Disabled | N/A | N/A |
| Preview loading | Disabled | Loading / no repeat | Disabled | N/A | N/A |
| Issuance processing | No competing operation | No competing operation | No competing operation | N/A | N/A |
| Issued | N/A | N/A | Gate independently | Gate independently | Gate independently |
| Delivery sending (`Đang gửi`) | N/A | N/A | Disabled (processing badge, no onTap) | Enabled | Enabled |
| Official-view loading | N/A | N/A | Temporarily disabled | Loading / no repeat | Temporarily disabled |

Row visibility, preview, issue, official-view, documents and send permissions are independently gated.

---

## 13. Return-context contract

Every SG-02 action preserves source context:

```text
EInvoiceSourceContext
├── salesOrderId
└── origin
    ├── salesOrderDetail
    └── salesResult
```

Required continuity:

```text
close pre/post issue sheet
→ same source screen

close preview viewer
→ same source screen

close official viewer
→ same source screen

close SG-06 / file exporter
→ same source screen

close SG-07 send/resend flow
→ same source screen

return from configuration/order correction
→ same SalesOrder context
→ re-evaluate
→ no automatic side-effect resume
```

Background/reopen resolves current operation status rather than submitting it again.

---

## 14. Design System mapping

Exact repository APIs take precedence over descriptive names here.

| UI responsibility | Intended mapping |
|---|---|
| Bottom/action sheet | `VBottomSheet` or current VET45 sheet pattern |
| Action item | Existing action-row/tile composition using DS primitives |
| Card/surface | `VCard` |
| Delivery status | `VBadge` |
| Warning/banner | `VBanner` or semantic warning composition when anatomy matches |
| Toast | `VToast` / current toast pattern |
| Text | `VText` |
| Icon | `VIcon` |
| Spacing | `VSpacing`, `VGap` |
| Semantic colors | `context.vColors` / current semantic tokens |
| Loading | Current DS loading behavior/component |
| Full-screen result | Existing VET45 state/result pattern |

Principles:

- Reuse existing DS components first.
- Feature-specific compositions do not automatically become DS components.
- Reusable E-Invoice surfaces used from both Theme 05 source screens belong in E-Invoice presentation.
- Do not hardcode visual tokens already owned by DS.
- Disabled is semantic: text, icon, trailing affordance, badge/action chrome must use coherent disabled treatment.

---

## 15. Known design interpretation

### Disabled-state inconsistency

Some design frames show an action as disabled while icon/trailing treatment still appears active.

Treat this as a known design rendering defect, not intended behavior:

```text
action.state = disabled
→ entire action follows DS disabled treatment
```

Do not intentionally reproduce active-looking icons inside disabled actions.

### SG02-O07

```text
Design label:
SG02-O07 — Menu HĐĐT · Chưa đủ thông tin

Implementation meaning:
PreIssueEInvoiceActionSheet(state: buyerNotReady)
+ ReadinessWarning / VBanner
```

It is not a new implementation unit.

---

## 16. Preview / specimen coverage

The presentation example should be able to audit:

```text
OrderEInvoiceRow
├── R01
│   ├── ready/not issued
│   └── buyer not ready
└── R02
    ├── ready/not issued
    └── buyer not ready

PreIssueEInvoiceActionSheet
├── O01 — order detail / idle
├── O02 — order detail / preview loading
├── O03 — sales result / idle
├── O04 — sales result / preview loading
└── buyerNotReady — design O07

ConfigurationBlockerResult
└── D01

OrderDataBlockerResult
└── D02

PreviewFailureToast
└── T01

PostIssueEInvoiceActionSheet
├── O05
│   ├── notSent
│   ├── sending
│   ├── sent
│   └── sendFailed
└── O06 — official-view loading
```

Fixture values are preview data, not business constants.

The example catalog should preview SG-02-owned surfaces without duplicating production Theme 05 routing or rebuilding full Theme 05 pages unless the existing harness intentionally supplies a source-screen host.

---

## 17. Forbidden interpretations

Do not derive from SG-02:

```text
one widget per specimen/frame
standalone E-Invoice order-detail page
standalone E-Invoice sales-result page
E-Invoice row on order list
new public widget for design O07
separate action sheets for O05-A/B/C/D
one public action-sheet widget mixing all pre/post business semantics
VET45-rendered legal invoice preview
global sheet loading for preview/official-view
automatic issuance after preview
automatic resume after correction
automatic conversion of buyer type
send before issuance
SG-05 invoice-profile UI
technical reconciliation UI
```

---

## 18. Acceptance summary

SG-02 is correctly mapped when:

1. Theme 05 remains owner of Chi tiết đơn hàng and Kết quả bán hàng.
2. `OrderEInvoiceRow` implements both R01 and R02.
3. One `PreIssueEInvoiceActionSheet` implements O01/O02/O03/O04 and buyer-not-ready design O07.
4. O01/O03 differ by source context, not widget identity.
5. O02/O04 differ by source context, not widget identity.
6. One `PostIssueEInvoiceActionSheet` implements O05/O06.
7. O05-A/B/C/D are `VBadge`/delivery-state variants, not separate widgets.
8. PreIssue and PostIssue remain separate public semantic widgets even if they share internal action-item anatomy.
9. Preview and issuance remain separate operations.
10. Buyer/order NOT_READY blocks issuance without automatically blocking preview.
11. Loading is action-specific and prevents duplicate submission.
12. Configuration blockers route to owning setup flow.
13. Buyer/order blockers route to Theme 05 correction ownership.
14. Returning from correction re-evaluates state without auto-resuming side effects.
15. Viewer/document/send flows return to the exact originating source context.
16. Disabled actions use coherent DS disabled treatment.
17. No VET45-generated legal preview or independent invoice-profile screen is introduced.
