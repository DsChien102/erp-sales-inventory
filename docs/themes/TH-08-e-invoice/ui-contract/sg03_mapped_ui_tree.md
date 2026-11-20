# TH08 / SG-03 — Mapped UI Tree

## Xác nhận & trạng thái phát hành trên đơn hàng

> **Purpose:** UI contract ở cấp Screen Group giữa Theme 08 SRS, approved SG-03 design, Audit Manifest và implementation.
>
> **Scope:** SG-03 only.
>
> **Primary contexts:** `Chi tiết đơn hàng` và `Kết quả bán hàng` của Theme 05.
>
> **Boundary:** Theme 05 sở hữu màn nguồn. SG-03 sở hữu confirmation phát hành và presentation của issuance state/feedback trên đúng màn nguồn; SG-03 không tạo route processing riêng.

---

## 1. Source of Truth

For SG-03-specific implementation details, use the following precedence:

1. **Theme 08 SRS / BA specification** — business rules, issuance semantics, permissions, state transitions and allowed/blocked actions.
2. **Latest approved SG-03 design** — visual hierarchy, copy, variants and presentation on the source screen.
3. **E-Invoice Audit Manifest** — canonical specimen IDs, surface types and planned implementation paths.
4. **Existing repository implementation** — actual component APIs, architecture and reusable implementation.
5. **This document** — mapping between the sources above.

When the sources disagree, the mismatch is recorded explicitly in this document rather than silently reconciled.

---

## 2. Ownership Boundary

### Theme 05 owns

```text
SalesOrderDetail
├── order summary
├── customer summary
├── payment & debt
├── product lines
├── DocumentsAndInvoicesSection
└── source-screen actions/navigation

SalesResult
├── completed-order result
├── customer summary
├── payment summary
├── DocumentsAndInvoicesSection
└── source-screen actions/navigation
```

### Theme 08 / SG-03 owns

```text
Issuance presentation on Theme 05 source screens
├── IssueInvoiceConfirmationSheet
├── OrderEInvoiceRow issuance-state variants
│   ├── processing
│   ├── issueFailed
│   └── issued transition
├── IssueSuccessToast
└── issuance failure feedback on source owner
```

SG-03 does not duplicate the full `Chi tiết đơn hàng` or `Kết quả bán hàng` screen.

---

## 3. Specimen ≠ Widget

A specimen ID is an auditable UI/state case, not necessarily a unique Flutter widget.

Several SG-03 specimens intentionally share the same implementation unit.

### Implementation units

```text
1. IssueInvoiceConfirmationSheet
   → SG03-O01-A
   → SG03-O01-B
   → SG03-O02

2. OrderEInvoiceRow
   → SG03-R01
   → SG03-R02
   → SG03-R03
   → issued state after T01/T02
   → shared with SG-02

3. IssueSuccessToast
   → SG03-T01
   → SG03-T02

4. Failure feedback
   → SG03-R02
   → `VToast.danger`
   → message:
     "Phát hành hóa đơn điện tử không thành công."
   → required transient feedback
   → not a separate canonical SG03-T failure specimen
```

Do not create separate widgets merely because the same business state is shown on two Theme 05 source screens.

---

## 4. Canonical Specimen Catalog

| Specimen | Surface | Context | State / meaning |
|---|---|---|---|
| `SG03-O01-A` | Confirmation Sheet | Chi tiết đơn hàng | Manual issuance confirmation — standard |
| `SG03-O01-B` | Confirmation Sheet variant | Chi tiết đơn hàng | Warning variant defined by SRS/Audit; current approved design mismatch noted below |
| `SG03-R01` | Contextual row | Chi tiết đơn hàng | Issuance processing / unknown / finalizing |
| `SG03-R02` | Contextual row + feedback | Chi tiết đơn hàng | Determinate issuance failure |
| `SG03-T01` | Toast on source owner | Chi tiết đơn hàng | Issuance success |
| `SG03-O02` | Confirmation Sheet | Kết quả bán hàng | Same manual issuance confirmation contract |
| `SG03-R03` | Contextual row | Kết quả bán hàng | Issuance processing / unknown / finalizing |
| `SG03-T02` | Toast on source owner | Kết quả bán hàng | Issuance success |

Theme 08 SRS defines SG-03 as confirmation and issuance presentation on the correct Theme 05 source owner. It explicitly forbids a separate processing route and SG-04 user-facing UI.

---

## 5. Planned Ownership from Audit Manifest

```text
SG03-O01-A / O01-B / O02
→ modules/einvoice/presentation/lib/src/widgets/
  issue_invoice_confirmation_sheet.dart

SG03-R01 / R02 / R03
→ modules/einvoice/presentation/lib/src/widgets/
  order_einvoice_row.dart

SG03-T01 / T02
→ modules/einvoice/presentation/lib/src/widgets/
  issue_success_toast.dart
```

`OrderEInvoiceRow` is already implemented by SG-02 and already supports the issuance status variants required by SG-03:

```text
Chưa phát hành
Đang xử lý
Đã phát hành
Phát hành lỗi
```

SG-03 reuses this component for `SG03-R01`, `SG03-R02`, and `SG03-R03`.

No new `OrderEInvoiceRow` implementation is required unless the existing interaction/trailing behavior conflicts with the SG-03 contract.

For `SG03-R02`, the canonical specimen is:

```text
OrderEInvoiceRow(issueFailed)
+
VToast.danger(
  "Phát hành hóa đơn điện tử không thành công."
)
```

The current Audit Manifest does not define a separate failure-toast specimen/path. The toast remains required feedback within the R02/source-owner presentation.

---

## 6. SG-03 State Contract

```text
SG03 Presentation State
├── sourceContext
│   ├── salesOrderDetail
│   └── salesResult
│
├── trigger
│   ├── manual
│   └── automatic
│
├── readiness
│   ├── ready
│   └── blocked
│
├── confirmation
│   ├── closed
│   └── open
│
├── issuance
│   ├── notIssued
│   ├── processing
│   ├── unknown
│   ├── finalizing
│   ├── issued
│   └── issueFailed
│
└── feedback
    ├── none
    ├── successToast
    └── failureFeedback
```

Existing application/domain types take precedence when they already represent these concepts.

### 6.1 Manual issuance gate

```text
SG-02 "Phát hành hóa đơn điện tử"
→ re-evaluate readiness
→ READY
→ SG-03 confirmation
```

A blocked order does not proceed to confirmation. Configuration/buyer-order blockers remain owned by the SG-02 correction flow.

### 6.2 Automatic trigger

Automatic issuance does not open SG-03 confirmation.

```text
automatic trigger
→ no confirmation sheet
→ accepted issuance operation
→ processing presentation on source owner
```

### 6.3 Processing projection

All of these backend/application conditions share the same user-facing processing presentation:

```text
processing
unknown
finalizing
→ "Đang xử lý"
```

An unknown result is **not** a failure.

### 6.4 Success

The invoice is presented as `Đã phát hành` only after the authoritative issuance result is committed.

```text
provider confirmed success
+ Mosaic Retail authoritative invoice registered
→ issued
→ "Đã phát hành"
```

### 6.5 Failure

Only a determinate failure maps to:

```text
issueFailed
→ "Phát hành lỗi"
```

Timeout, missing response or an unresolved result must not be presented as a determinate failure.

---

# 7. Mapped UI Tree

## 7.1 SG03-O01-A — Chi tiết đơn hàng / Xác nhận phát hành

**Module widget**

```text
modules/einvoice/presentation/lib/src/widgets/
issue_invoice_confirmation_sheet.dart
```

**Host**

```text
Theme05SalesOrderDetail
└── IssueInvoiceConfirmationSheet
```

**Approved design tree**

```text
IssueInvoiceConfirmationSheet
└── VBottomSheet / current confirmation-sheet pattern
    ├── drag handle
    ├── title:
    │   "Phát hành hóa đơn điện tử?"
    ├── IssuanceSummary
    │   ├── line 1:
    │   │   "Đơn hàng {orderReference} · Tổng tiền {orderTotal}"
    │   └── line 2:
    │       "Mẫu {templateNumber} · Ký hiệu {templateSymbol} · {authorityMode}"
    └── actions
        ├── ConfirmIssueButton : VButton
        │   ├── primary
        │   └── "Phát hành hóa đơn điện tử"
        └── CancelButton : VButton
            ├── secondary
            └── "Hủy"
```

Example design fixture:

```text
orderReference: "#DH-000129"
orderTotal: "4.445.238đ"
templateNumber: "1/001"
templateSymbol: "C26TAA"
authorityMode: "Có mã CQT"
```

Fixture values are preview values, not business constants.

### Interaction

```text
Hủy / close sheet
→ close confirmation
→ remain on Chi tiết đơn hàng
→ do not create IssuanceAttempt

Phát hành hóa đơn điện tử
→ issue permission/readiness valid at confirmation time
→ submit one business issuance command
```

After the command is accepted:

```text
close confirmation sheet
→ remain on exact source screen
→ OrderEInvoiceRow becomes "Đang xử lý"
```

Opening the sheet alone creates no issuance attempt.

---

## 7.2 SG03-O02 — Kết quả bán hàng / Xác nhận phát hành

`SG03-O02` uses the same business and visual contract as `SG03-O01-A`; only the host source context changes.

```text
Theme05SalesResult
└── IssueInvoiceConfirmationSheet
    ├── title:
    │   "Phát hành hóa đơn điện tử?"
    ├── IssuanceSummary
    │   ├── order reference + total
    │   └── template number + symbol + authority mode
    └── actions
        ├── "Phát hành hóa đơn điện tử"
        └── "Hủy"
```

### Interaction

```text
Hủy / close
→ remain on Kết quả bán hàng
→ no IssuanceAttempt

accepted issue command
→ close sheet
→ remain on Kết quả bán hàng
→ OrderEInvoiceRow becomes "Đang xử lý"
```

Do not create a second public confirmation widget for Sales Result.

---

## 7.3 SG03-O01-B — Warning Confirmation Variant

Theme 08 SRS and the current Audit Manifest define:

```text
SG03-O01-B
→ Confirmation Sheet variant
→ warning
→ primary action remains "Phát hành hóa đơn điện tử"
→ warning does not disable primary action
```

However, the latest approved SG-03 design supplied for this mapping states:

```text
Confirmation chỉ xuất hiện khi IssuanceReadiness = READY.
Blocker dữ liệu người mua được xử lý tại SG-02 trước khi người dùng có thể xác nhận phát hành.
```

No O01-B warning frame is present in the supplied approved design board.

Therefore:

```text
SG03-O01-B
→ remains a canonical SRS/Audit specimen
→ shares IssueInvoiceConfirmationSheet
→ exact current visual/copy is unresolved
→ do not invent warning content from the absent frame
```

See `GAP-01` below.

---

## 7.4 SG03-R01 — Chi tiết đơn hàng / Đang xử lý

`SG03-R01` is a state of the shared `OrderEInvoiceRow`.

```text
Theme05SalesOrderDetail
└── DocumentsAndInvoicesSection
    ├── SalesReceiptRow
    └── OrderEInvoiceRow
        ├── LeadingIcon
        │   └── file-check
        ├── Content
        │   ├── title:
        │   │   "Hóa đơn điện tử"
        │   └── helper:
        │       "Quản lý HĐĐT"
        └── StatusBadge : VBadge
            ├── status: processing
            └── label: "Đang xử lý"
```

### Interaction contract

Any control whose active status is `VBadgeStatus.processing` is non-interactive.

```text
processing / unknown / finalizing
→ badge "Đang xử lý" (VBadgeStatus.processing)
→ row ignores onTap / no click interaction
→ preserve existing row visual (including trailing chevron)
→ no issue action
→ no preview action
→ no send action
```

Shared rule: presentation `EInvoiceStatusInteraction` — do not invent SG-03-specific row variants.

The user remains on the Theme 05 source screen.

There is no SG-04 route.

---

## 7.5 SG03-R03 — Kết quả bán hàng / Đang xử lý

`SG03-R03` is the Sales Result host variant of the same processing row.

```text
Theme05SalesResult
└── DocumentsAndInvoicesSection
    ├── SalesReceiptRow
    └── OrderEInvoiceRow
        ├── LeadingIcon
        │   └── file-check
        ├── Content
        │   ├── title:
        │   │   "Hóa đơn điện tử"
        │   └── helper:
        │       "Quản lý hóa đơn"
        └── StatusBadge : VBadge
            ├── status: processing
            └── label: "Đang xử lý"
```

The source screen keeps its normal order-success actions such as `Về trang chủ` / `Tạo đơn mới`; SG-03 does not replace the Sales Result page with a processing destination.

Unknown/finalizing states remain visually `Đang xử lý`.

Same interaction contract as SG03-R01: processing badge → non-interactive shared `OrderEInvoiceRow` (no onTap).

---

## 7.6 SG03-R02 — Chi tiết đơn hàng / Phát hành lỗi

`SG03-R02` represents a **determinate** issuance failure.

```text
Theme05SalesOrderDetail
└── DocumentsAndInvoicesSection
    └── OrderEInvoiceRow
        ├── LeadingIcon
        │   └── file-check
        ├── Content
        │   ├── title:
        │   │   "Hóa đơn điện tử"
        │   └── helper:
        │       "Quản lý HĐĐT"
        ├── StatusBadge : VBadge
        │   ├── danger/error semantic
        │   └── label: "Phát hành lỗi"
        └── interaction available again when no operation lock remains
```

### Required failure feedback

`SG03-R02` contains both persistent state and transient feedback:

```text
1. Persistent state
   → OrderEInvoiceRow
   → badge: "Phát hành lỗi"

2. Transient feedback
   → VToast.danger
   → message:
     "Phát hành hóa đơn điện tử không thành công."
```

Mapped UI:

```text
VToast
├── type: danger
├── icon: DS danger-toast icon
├── message:
│   "Phát hành hóa đơn điện tử không thành công."
└── dismiss
```

The danger toast is required for R02. It is transient; the persistent business state remains the row badge `Phát hành lỗi`.

### Retry/business action semantics

The user-facing action remains:

```text
"Phát hành hóa đơn điện tử"
```

Do not rename it to:

```text
"Thử lại"
"Retry"
"Kiểm tra kết quả"
```

When the user chooses to issue again:

```text
Phát hành hóa đơn điện tử
→ re-evaluate current readiness
→ if ready: same SG-03 confirmation contract
→ new business issuance attempt
```

A technical retry inside an existing attempt is not exposed as a normal user action.

---

## 7.7 SG03-T01 — Chi tiết đơn hàng / Phát hành thành công

Success feedback is shown on the same Theme 05 source owner.

```text
Theme05SalesOrderDetail
├── OrderEInvoiceRow
│   ├── title: "Hóa đơn điện tử"
│   ├── helper: "Quản lý HĐĐT"
│   ├── StatusBadge : VBadge
│   │   ├── success
│   │   └── "Đã phát hành"
│   └── trailing: chevron-right
└── IssueSuccessToast
    └── VToast
        ├── type: success
        ├── message:
        │   "Phát hành hóa đơn điện tử thành công."
        └── dismiss
```

The row must become `Đã phát hành` before/with the transient success feedback.

After issuance is authoritative, tapping the row follows the post-issued SG-02 contract.

Success does not automatically open the official invoice viewer.

---

## 7.8 SG03-T02 — Kết quả bán hàng / Phát hành thành công

`SG03-T02` uses the same toast contract as T01 on the Sales Result source owner.

```text
Theme05SalesResult
├── DocumentsAndInvoicesSection
│   └── OrderEInvoiceRow
│       ├── title: "Hóa đơn điện tử"
│       ├── helper: "Quản lý hóa đơn"
│       ├── StatusBadge : VBadge
│       │   ├── success
│       │   └── "Đã phát hành"
│       └── trailing: chevron-right
└── IssueSuccessToast
    └── VToast
        ├── type: success
        ├── message:
        │   "Phát hành hóa đơn điện tử thành công."
        └── dismiss
```

Do not automatically open the MISA official viewer after success.

The Sales Result page keeps its normal Theme 05 actions.

---

## 8. Issuance Transition Map

### Manual issuance

```text
SG-02 pre-issue action
└── "Phát hành hóa đơn điện tử"
    └── readiness re-evaluation
        ├── blocked
        │   └── SG-02 blocker/correction flow
        └── ready
            └── SG03-O01-A / O02
                ├── Hủy
                │   └── source unchanged
                └── Phát hành hóa đơn điện tử
                    └── command accepted
                        └── sheet closes
                            └── R01 / R03 "Đang xử lý"
```

### Processing result

```text
processing
├── unknown
└── finalizing
    ↓
R01 / R03
"Đang xử lý"
```

### Authoritative success

```text
processing
→ authoritative success
→ row "Đã phát hành"
→ T01 / T02 success toast
→ post-issued SG-02 behavior becomes available
```

### Determinate failure

```text
processing
→ determinate failure
→ R02 "Phát hành lỗi"
→ failure feedback
→ when readiness allows:
   user may choose "Phát hành hóa đơn điện tử" again
```

No user-facing SG-04 processing/reconciliation screen exists.

---

## 9. Action Availability Matrix

| Condition | Confirmation | Issue action | Row interaction | Competing E-Invoice actions |
|---|---|---|---|---|
| Manual + READY + idle | Available | `Phát hành hóa đơn điện tử` | Pre-issue flow | Allowed by SG-02 contract |
| Manual + blocked | Not entered | Blocked by SG-02 | Correction flow | Gated independently |
| Confirmation open | Open | One primary issue action | Source dimmed behind sheet | No duplicate issue submit |
| Processing | Closed | Not available | No competing destination | Blocked |
| Unknown | Closed | Not available | Same as processing | Blocked |
| Finalizing | Closed | Not available | Same as processing | Blocked |
| Issued | Closed | N/A | Post-issued row destination | Post-issued SG-02 contract |
| Determinate failure | Closed | Available again only after readiness gate | May reopen issue flow | No technical retry CTA |

Permission to issue is checked at confirmation time.

---

## 10. Return / Source Context Contract

SG-03 always preserves the originating Theme 05 context.

```text
SalesOrderDetail
→ confirmation
→ cancel / processing / success / failure
→ SalesOrderDetail

SalesResult
→ confirmation
→ cancel / processing / success
→ SalesResult
```

Background/reopen must resolve the current operation and restore the corresponding row state rather than creating another issuance attempt.

---

## 11. Design System Mapping

| UI responsibility | Mosaic Retail mapping |
|---|---|
| Confirmation surface | `VBottomSheet` / current confirmation-sheet pattern |
| Primary confirmation action | `VButton` primary |
| Cancel action | `VButton` secondary |
| E-Invoice contextual row | `OrderEInvoiceRow` module composition |
| Issuance status | `VBadge` |
| Processing status | `VBadgeStatus.processing` — blue/info semantic |
| Issued status | success badge semantic |
| Issue-failed status | danger/error badge semantic |
| Success transient feedback | `VToast(type: success)` |
| Failure transient feedback | `VToast(type: danger)` |
| Row leading icon | `VIcons.fileCheck` |
| Text | `VText` |
| Spacing / typography / radius / colors | existing DS semantic tokens |

`VBadgeStatus.processing` represents an in-progress state, not a warning.

**Interaction rule (shared with SG-02):** any surface whose active status is
`VBadgeStatus.processing` must be non-interactive (`onTap` ignored / action
disabled). Visual badge treatment stays processing; do not invent alternate
chrome for R01/R03.

Feature-specific issuance composition remains in E-Invoice presentation and does not automatically become a new Design System component.

---

## 12. Shared Contract with SG-02

SG-02 and SG-03 intentionally meet at `OrderEInvoiceRow`.

```text
notIssued
→ SG-02 pre-issue behavior

processing / unknown / finalizing
→ SG-03 processing presentation

issueFailed
→ SG-03 failure presentation
→ issue flow may become available again when ready

issued
→ SG-03 success transition
→ SG-02 post-issued behavior
```

Do not create separate `SG02OrderEInvoiceRow` and `SG03OrderEInvoiceRow` components.

The issuance badge and helper text remain independent presentation concepts.

---

## 13. Preview / Specimen Coverage

The SG-03 presentation example should be able to audit:

```text
IssueInvoiceConfirmationSheet
├── O01-A — order detail / standard
├── O01-B — warning variant
│   └── visual unresolved against current approved design
└── O02 — sales result / standard

OrderEInvoiceRow
├── R01 — order detail / processing
├── R02 — order detail / issueFailed
│   └── VToast.danger:
│       "Phát hành hóa đơn điện tử không thành công."
└── R03 — sales result / processing

IssueSuccessToast
├── T01 — order detail / success
└── T02 — sales result / success
```

The preview may use a source-screen host shell to show context, but Theme 05 remains owner of the actual source-screen UI.

Representative non-sensitive fixture values from the approved design:

```text
orderReference: "#DH-000129"
orderTotal: "4.445.238đ"
templateNumber: "1/001"
templateSymbol: "C26TAA"
authorityMode: "Có mã CQT"
```

These values are preview data only.

---

## 14. Harness & Audit Mapping

Current Audit Manifest mapping:

```text
SG03-O01-A
↔ issue_invoice_confirmation_sheet.dart

SG03-O01-B
↔ issue_invoice_confirmation_sheet.dart

SG03-R01
↔ order_einvoice_row.dart

SG03-R02
↔ order_einvoice_row.dart

SG03-T01
↔ issue_success_toast.dart

SG03-O02
↔ issue_invoice_confirmation_sheet.dart

SG03-R03
↔ order_einvoice_row.dart

SG03-T02
↔ issue_success_toast.dart
```

Manifest statuses follow the repository's existing audit convention:

```text
pending → Chưa làm
stub    → Stub
done    → Done
```

This document does not redefine the criteria for changing AuditStatus.

---

## 15. Known SG-03 Gaps / Mismatches

### GAP-01 — SG03-O01-B warning variant

```text
Source: SRS + Audit Manifest
Specimen: SG03-O01-B
```

SRS defines a confirmation warning variant and says the warning does not disable the primary issue action.

The latest approved design supplied for SG-03 instead states that confirmation appears only when `IssuanceReadiness = READY`, with buyer-data blockers handled by SG-02 before confirmation, and it does not show an O01-B frame.

Therefore the current visual/copy contract for O01-B is unresolved.

Do not invent a new warning message or visual until SRS/design is reconciled.

### GAP-02 — Confirmation information content

SRS says the confirmation contains:

```text
SalesOrder reference
buyer
total
template number
symbol
signing method / no-sign mode
warning when applicable
```

The supplied approved design shows:

```text
order reference
total
template number
symbol
authority mode ("Có mã CQT")
```

The approved design does not visibly show buyer or a separate signing-method line.

The UI tree follows the supplied design for the current visual composition while preserving this as a SRS/design mismatch to resolve.

### Audit note — R02 failure feedback

The approved design for `SG03-R02` requires:

```text
OrderEInvoiceRow(issueFailed)
+
VToast.danger(
  "Phát hành hóa đơn điện tử không thành công."
)
```

The current Audit Manifest models `SG03-R02` as:

```text
Contextual row + feedback
```

and maps its canonical planned path to:

```text
modules/einvoice/presentation/lib/src/widgets/
order_einvoice_row.dart
```

The danger toast is still required implementation feedback for R02 even though it is not represented as a separate `SG03-Txx` specimen.

No additional failure-toast specimen is required unless the Audit Manifest is intentionally expanded later.

---

## 16. Forbidden Interpretations

Do not derive from SG-03:

```text
standalone issuance-processing page
SG-04 user-facing route
manual technical reconciliation CTA
"Thử lại" as the user-facing issuance action
"Kiểm tra kết quả" CTA for normal users
new issuance attempt while current result is processing/unknown/finalizing
failure inferred only from timeout/no response
official invoice viewer before authoritative commit
automatic opening of official viewer after success
confirmation sheet for automatic issuance trigger
one confirmation widget per source screen
one OrderEInvoiceRow per SG
separate UI for unknown/finalizing
technical attempt history, evidence or retry count in normal UI
```

---

## 17. Acceptance Summary

SG-03 is correctly mapped when:

1. Theme 05 remains owner of `Chi tiết đơn hàng` and `Kết quả bán hàng`.
2. Manual issuance enters SG-03 confirmation only after readiness is valid.
3. Automatic issuance does not open confirmation.
4. O01-A and O02 use one `IssueInvoiceConfirmationSheet`.
5. Cancel/close confirmation creates no `IssuanceAttempt`.
6. Accepted issuance closes the sheet and keeps the user on the exact source screen.
7. R01/R03 represent processing, unknown and finalizing as `Đang xử lý`.
8. No competing issuance action exists while the operation is unresolved.
9. No SG-04 processing/reconciliation UI is introduced.
10. R02 represents only determinate issuance failure.
11. The user-facing post-failure action remains `Phát hành hóa đơn điện tử`, not `Thử lại`.
12. Success becomes `Đã phát hành` only after authoritative registration.
13. T01/T02 are transient success feedback on the source owner.
14. Success does not automatically open the official viewer.
15. `OrderEInvoiceRow` remains shared with SG-02.
16. O01-B and confirmation-content mismatches remain explicit until BA/design is reconciled.
