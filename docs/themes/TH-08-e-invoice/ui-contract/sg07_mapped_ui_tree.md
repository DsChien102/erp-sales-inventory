# TH08 / SG-07 — Mapped UI Tree

## Gửi & gửi lại hóa đơn qua email

> **Purpose:** UI contract ở cấp Screen Group giữa Theme 08 SRS, approved SG-07 design, Audit Manifest và implementation.
>
> **Scope:** SG-07 only.
>
> **Primary context:** `ElectronicInvoice` đã phát hành, được mở từ Bottom Sheet HĐĐT sau phát hành trên đúng màn nguồn Theme 05.
>
> **Boundary:** SG-07 sở hữu Send Sheet, Resend Sheet, delivery history và transient send-result feedback. Theme 05 tiếp tục sở hữu `Chi tiết đơn hàng` / `Kết quả bán hàng`. SG-07 không tạo full-screen delivery-status page.

---

## 0. Slice 5 BE–FE lock (app-owned)

ADR 11: runtime SG-07 thuộc `apps/erp`. Module `modules/einvoice/presentation` chỉ còn reference/catalog; host production **không** gọi `showSendInvoiceSheet` / `showResendInvoiceSheet` module-owned.

### Target app-owned paths

```text
apps/erp/lib/features/sales/presentation/widgets/einvoice/
  send_invoice_sheet.dart
  resend_invoice_sheet.dart
  invoice_delivery_history_view.dart

apps/erp/lib/features/sales/presentation/pages/
  invoice_delivery_history_page.dart
```

### Specimen × interaction matrix (canonical)

| Specimen | Dữ liệu | Tương tác | Kết quả |
| --- | --- | --- | --- |
| SG07-O01-A | mode=send, suggestedEmail có giá trị | sửa email, gửi, hủy | chưa tạo delivery khi mới mở |
| SG07-O01-B | mode=send, suggestion rỗng | nhập email | CTA chỉ bật khi email hợp lệ |
| SG07-O01-C | email sai định dạng | sửa email | helper lỗi trở về helper chuẩn khi hợp lệ |
| SG07-O01-D | submit đang chạy | không tương tác | giữ email/helper/CTA copy, CTA có spinner |
| SG07-O02 | mode=resend, history không rỗng | gửi lại, xem lịch sử | link history luôn có; server suy ra RESEND |
| SG07-D01 | deliveries authoritative | back/retry read | mới nhất trước; không lộ raw provider data |

### `operationLocked` (controlled)

Khi sheet context `operationLocked=true` (có delivery `PROCESSING`):

- field email và CTA gửi bị khóa
- link `Xem lịch sử gửi` vẫn hoạt động
- **không** thêm CTA “Kiểm tra kết quả gửi” hoặc dialog/warning mới

`UNKNOWN` **không** khóa manual resend; worker không auto-retry. UI giữ layout/CTA hiện có.

### Resend CTA copy

Canonical SG07-O02 dùng cùng CTA primary với lần gửi đầu: **`Gửi hóa đơn`** (không đổi nhãn thành “Gửi lại hóa đơn”).

---

## 1. Source of Truth

For SG-07-specific implementation details, use the following precedence:

1. **Theme 08 SRS / BA specification** — delivery semantics, recipient source, validation, loading, resend/history rules, permissions and delivery-state behavior.
2. **Latest approved SG-07 design** — visual hierarchy, copy, variants, source-screen feedback and interaction presentation.
3. **E-Invoice Audit Manifest** — canonical specimen IDs, surface types and planned implementation paths.
4. **Existing repository implementation** — actual component APIs, architecture and reusable presentation anatomy.
5. **This document** — mapping between the sources above.

When sources disagree, record the mismatch explicitly instead of silently changing business or presentation semantics.

---

## 2. Ownership Boundary

### Theme 05 owns source screens

```text
SalesOrderDetail
└── source-screen layout + navigation

SalesResult
└── source-screen layout + navigation
```

SG-07 does not duplicate these screens.

### SG-02 owns entry from post-issued E-Invoice menu

```text
PostIssueEInvoiceActionSheet
└── SendInvoiceAction
    └── SG-07
```

Delivery status shown in SG-02 is a summary projection. Delivery creation/resend/history belongs to SG-07.

### SG-07 owns

```text
Delivery UI
├── SendInvoiceSheet
│   ├── suggested email
│   ├── empty email
│   ├── validation error
│   └── loading
├── ResendInvoiceSheet
├── InvoiceDeliveryHistoryPage
└── transient send-result feedback on Theme 05 source owner
```

### Theme 03 does not own SG-07 email edits

Email entered in SG-07:

```text
→ applies only to the current InvoiceDelivery
→ does not update Theme 03
→ does not update BuyerInvoiceSnapshot
→ does not update InvoiceSnapshot
```

---

## 3. Specimen ≠ Widget

A specimen is an auditable or approved UI/state case, not necessarily a unique Flutter widget.

### Canonical Audit specimens

```text
SendInvoiceSheet
├── SG07-O01-A — suggested email
├── SG07-O01-B — empty
├── SG07-O01-C — validation error
└── SG07-O01-D — loading

ResendInvoiceSheet
└── SG07-O02

InvoiceDeliveryHistoryPage
└── SG07-D01
```

### Approved-design transient feedback

The latest design also contains:

```text
SG07-T01 — Chi tiết đơn hàng — Gửi thành công
SG07-T02 — Kết quả bán hàng — Gửi thành công

SG07-T03 — Chi tiết đơn hàng — Gửi lỗi
SG07-T04 — Kết quả bán hàng — Gửi lỗi
```

The SRS explicitly notes that independent success/error toasts on the source screen are **not part of the final SG-07 screen inventory**. Therefore they are documented here as required design feedback, but they do not require four independent audit/widget identities.

Variant consolidation:

```text
T01 + T02
→ same success feedback contract
→ different Theme 05 source host only

T03 + T04
→ same failure feedback contract
→ different Theme 05 source host only
```

---

## 4. Canonical Specimen Catalog

| Specimen | Surface | Context | State / meaning | Planned implementation |
|---|---|---|---|---|
| `SG07-O01-A` | Send Sheet | No previous delivery | Suggested email filled | `send_invoice_sheet.dart` |
| `SG07-O01-B` | Send Sheet | No previous delivery | Empty email | `send_invoice_sheet.dart` |
| `SG07-O01-C` | Send Sheet | Draft recipient | Validation error | `send_invoice_sheet.dart` |
| `SG07-O01-D` | Send Sheet variant | Active InvoiceDelivery | Loading / sending | `send_invoice_sheet.dart` |
| `SG07-O02` | Resend Sheet | Has delivery history | Editable resend form | `resend_invoice_sheet.dart` |
| `SG07-D01` | Full-screen route | Has one or more InvoiceDelivery | Delivery history | `invoice_delivery_history_page.dart` |

### Approved-design feedback cases

| Design ID | Surface | Host | Meaning | Canonical relation |
|---|---|---|---|---|
| `SG07-T01` | Toast | Chi tiết đơn hàng | Send success | same success feedback as T02 |
| `SG07-T02` | Toast | Kết quả bán hàng | Send success | same success feedback as T01 |
| `SG07-T03` | Toast | Chi tiết đơn hàng | Send failure | same failure feedback as T04 |
| `SG07-T04` | Toast | Kết quả bán hàng | Send failure | same failure feedback as T03 |

These T-cases are design feedback cases, not additional current Audit Manifest entries.

---

## 5. Planned Ownership from Audit Manifest

```text
SG07-O01-A / O01-B / O01-C / O01-D
→ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  send_invoice_sheet.dart

SG07-O02
→ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  resend_invoice_sheet.dart

SG07-D01
→ apps/erp/lib/features/sales/presentation/pages/
  invoice_delivery_history_page.dart
  (+ invoice_delivery_history_view.dart)
```

Legacy module-owned paths under `modules/einvoice/presentation` remain catalog/reference only after Slice 5 FE lock.

The current Audit Manifest intentionally does not contain separate T01–T04 entries.

---

## 6. SG-07 State Contract

```text
SG07 Presentation State
├── sourceContext
│   ├── salesOrderDetail
│   └── salesResult
│
├── mode
│   ├── firstSend
│   └── resend
│
├── recipient
│   ├── suggested
│   ├── empty
│   ├── validEdited
│   └── invalid
│
├── deliveryOperation
│   ├── idle
│   ├── loading
│   ├── success
│   ├── determinateFailure
│   └── unresolved
│
└── history
    ├── none
    └── available
```

Existing application/domain types take precedence when they already represent these concepts.

### 6.1 Recipient contract

SG-07 accepts exactly one email recipient.

```text
recipientEmail: single email only
```

Forbidden:

```text
CC
BCC
recipient list
checkbox "Lưu email"
automatic update to Theme 03
```

### 6.2 First-send suggestion

For the first delivery:

```text
BuyerInvoiceSnapshot email
→ preferred suggestion when available
```

The SRS also allows fallback based on the most recent successful delivery for the same Partner in the current tenant under its business rules.

A suggested email remains editable.

### 6.3 Resend suggestion

For resend:

```text
most recent InvoiceDelivery of the current ElectronicInvoice
→ DeliveryRecipientSnapshot.email
→ proposed email in Resend Sheet
```

The user may edit it for the new delivery.

### 6.4 Delivery independence

Each user-visible send/resend business intent creates a separate `InvoiceDelivery`.

Technical retry does not create another history row.

Delivery lifecycle remains independent from invoice issuance:

```text
send success / send failure / timeout / unresolved
→ ElectronicInvoice remains "Đã phát hành"
```

### 6.5 Unknown is not failure

Timeout or no response must not automatically become a determinate send failure.

```text
UNKNOWN (first send, no prior success)
→ display "Không xác định kết quả"
→ do not poll as endless SENDING
→ manual resend allowed (operationLocked=false)
→ worker does not auto-retry

prior success + later UNKNOWN/FAILED
→ primary badge remains "Đã gửi"
→ hasSecondaryAttention=true
```

---

# 7. Mapped UI Tree

## 7.1 SG07-O01-A — Gửi hóa đơn / Có email đề xuất

**App-owned widget (Slice 5 target)**

```text
apps/erp/lib/features/sales/presentation/widgets/einvoice/
send_invoice_sheet.dart
```

**Entry**

```text
SG02 PostIssueEInvoiceActionSheet
└── SendInvoiceAction
    └── SG07-O01-A
```

when this is the first delivery and a suggested recipient exists.

**Approved design tree**

```text
SendInvoiceSheet
└── VBottomSheet / current VET45 form-sheet pattern
    ├── drag handle
    ├── title:
    │   "Gửi hóa đơn điện tử"
    ├── InvoiceIdentityText
    │   └── "Hóa đơn số {invoiceNumber} · Ký hiệu {invoiceSymbol}"
    ├── RecipientField
    │   ├── label:
    │   │   "Email người nhận *"
    │   ├── VTextField / email field
    │   │   └── value: suggestedEmail
    │   └── helper:
    │       "Email chỉ áp dụng cho lần gửi này."
    └── actions
        ├── SendButton : VButton
        │   ├── primary
        │   └── "Gửi hóa đơn"
        └── CancelButton : VButton
            ├── secondary
            └── "Hủy"
```

Example design fixture:

```text
invoiceNumber: "0000129"
invoiceSymbol: "C26TAA"
suggestedEmail: "accounting@company.com"
```

Fixture values are preview values, not business constants.

### Interaction

```text
open sheet
→ no InvoiceDelivery is created

Hủy / dismiss
→ close sheet
→ remain on exact Theme 05 source
→ no delivery created

Gửi hóa đơn
→ validate recipient
→ permission/capability gate
→ start one business InvoiceDelivery
→ O01-D loading
```

---

## 7.2 SG07-O01-B — Gửi hóa đơn / Chưa có email

Same `SendInvoiceSheet`, empty recipient state.

```text
SendInvoiceSheet
├── title:
│   "Gửi hóa đơn điện tử"
├── InvoiceIdentityText
├── RecipientField
│   ├── label:
│   │   "Email người nhận *"
│   ├── value: empty
│   ├── placeholder:
│   │   "Nhập email"
│   └── helper:
│       "Email chỉ áp dụng cho lần gửi này."
└── actions
    ├── SendButton
    │   └── enabled only when recipient becomes valid
    └── "Hủy"
```

No email suggestion must be invented from another customer.

Opening this state does not create an `InvoiceDelivery`.

---

## 7.3 SG07-O01-C — Gửi hóa đơn / Email không hợp lệ

Same `SendInvoiceSheet`, validation-error state.

```text
SendInvoiceSheet
├── title:
│   "Gửi hóa đơn điện tử"
├── InvoiceIdentityText
├── RecipientField
│   ├── label:
│   │   "Email người nhận *"
│   ├── value: invalid draft
│   ├── error semantic
│   └── helper:
│       "Email không đúng định dạng."
└── actions
    ├── SendButton
    │   └── disabled
    └── "Hủy"
```

### Validation contract

```text
invalid email
→ error helper
→ no submit

email becomes valid
→ helper returns to:
  "Email chỉ áp dụng cho lần gửi này."
→ Send button becomes eligible again
```

Do not retain the error helper after the field becomes valid.

---

## 7.4 SG07-O01-D — Đang gửi hóa đơn

Same `SendInvoiceSheet`, active delivery operation.

```text
SendInvoiceSheet
├── title:
│   "Gửi hóa đơn điện tử"
├── InvoiceIdentityText
├── RecipientField
│   ├── value: unchanged
│   ├── disabled
│   └── helper:
│       "Email chỉ áp dụng cho lần gửi này."
└── actions
    ├── SendButton
    │   ├── label remains:
    │   │   "Gửi hóa đơn"
    │   ├── loading
    │   └── repeated interaction blocked
    └── CancelButton
        └── "Hủy"
```

### Stable-content rule

Loading must preserve:

```text
email value
field label
helper copy
primary action label
sheet title
invoice identity
```

Do not change:

```text
"Gửi hóa đơn"
→ "Đang gửi..."

helper
→ loading-specific text
```

The field becomes non-editable while the delivery operation is active.

No competing delivery may be started while the current delivery is `PROCESSING`
(`operationLocked=true`). `UNKNOWN` does not block a new manual resend.

### Result

```text
command accepted as PROCESSING
→ close sheet
→ refresh projection / continue server-side polling

determinate command failure (sync)
→ keep sheet open
→ restore field/CTA
→ one safe SnackBar

UNKNOWN terminal on delivery
→ not automatically determinate "Gửi lỗi"
→ unlock manual resend; no auto retry
```

---

## 7.5 SG07-O02 — Gửi lại hóa đơn

**App-owned widget (Slice 5 target)**

```text
apps/erp/lib/features/sales/presentation/widgets/einvoice/
resend_invoice_sheet.dart
```

`O02` is used when the ElectronicInvoice already has delivery history.

**Approved design tree**

```text
ResendInvoiceSheet
└── VBottomSheet / current VET45 form-sheet pattern
    ├── drag handle
    ├── title:
    │   "Gửi lại hóa đơn điện tử"
    ├── LatestDeliverySummary
    │   └── "Đã gửi gần nhất đến {latestEmail} · {latestDateTime}"
    ├── RecipientField
    │   ├── label:
    │   │   "Email người nhận *"
    │   ├── value:
    │   │   latestDeliveryRecipientEmail
    │   └── helper:
    │       "Email chỉ áp dụng cho lần gửi này."
    ├── HistoryLink
    │   └── "Xem lịch sử gửi"
    └── actions
        ├── ResendButton : VButton
        │   ├── primary
        │   └── "Gửi hóa đơn"
        └── CancelButton : VButton
            ├── secondary
            └── "Hủy"
```

Example design fixture:

```text
latestEmail: "accounting@company.com"
latestDateTime: "05/08/2026, 16:20"
```

### History-link rule

```text
has at least one InvoiceDelivery
→ "Xem lịch sử gửi" visible

no InvoiceDelivery
→ use first-send flow
→ no history link
```

The history link exists inside the Resend Sheet.

Do not add a fourth action to the SG-02 post-issued sheet just to open history.

### Resend interaction

```text
Gửi lại hóa đơn
→ validate current edited recipient
→ start a new business InvoiceDelivery
→ same delivery-operation semantics as first send
```

A resend may use a different recipient email; the new recipient is stored in the new `DeliveryRecipientSnapshot`.

### History navigation

```text
Xem lịch sử gửi
→ SG07-D01
```

---

## 7.6 SG07-D01 — Lịch sử gửi hóa đơn

**App-owned page (Slice 5 target)**

```text
apps/erp/lib/features/sales/presentation/pages/
invoice_delivery_history_page.dart
```

Legacy fixture host (to be removed after route wiring):

```text
apps/erp/lib/features/einvoice/presentation/pages/
invoice_delivery_history_page.dart
```

**Approved design tree**

```text
InvoiceDeliveryHistoryPage
└── VPageScaffold
    ├── title:
    │   "Lịch sử gửi hóa đơn"
    ├── showBackButton: true
    └── body
        └── scrollable content
            ├── InvoiceSummaryCard : VCard
            │   ├── Header
            │   │   ├── invoice:
            │   │   │   "Hóa đơn số {invoiceNumber}"
            │   │   └── StatusBadge : VBadge
            │   │       └── "Đã phát hành"
            │   ├── InvoiceMetadata
            │   │   └── "Mẫu {templateNumber} · Ký hiệu {invoiceSymbol}"
            │   └── IssuedAt
            │       └── "Phát hành lúc {issuedTime}, {issuedDate}"
            │
            ├── SectionTitle
            │   └── "Các lần gửi"
            │
            └── DeliveryHistoryCard : VCard
                ├── DeliveryHistoryRow
                ├── DeliveryHistoryRow
                └── ...
```

### DeliveryHistoryRow

Each `InvoiceDelivery` is one history row.

```text
DeliveryHistoryRow
├── ResultIcon
├── MainText
│   ├── result
│   └── " · "
│       recipientEmail
└── Metadata
    └── "{date} · {time} · {actor}"
```

Supported user-facing result semantics:

```text
success
→ "Đã gửi"
→ success semantic

determinate failure
→ "Gửi lỗi"
→ danger semantic
```

For an automatic delivery:

```text
actor
→ "Tự động"
```

For a user-triggered delivery:

```text
actor
→ display actor name
```

### Approved design example

```text
Đã gửi · accounting@company.com
05/08/2026 · 16:20 · Nguyễn Văn An

Gửi lỗi · accounting@company.com
05/08/2026 · 16:16 · Nguyễn Văn An

Đã gửi · customer@company.com
05/08/2026 · 16:12 · Tự động
```

### History ordering

History is read-only.

```text
newest first
```

according to the product convention/SRS.

### Forbidden history content

Do not show:

```text
raw MISA response/detail
technical retry count
DeliveryAttempt internals
provider callback payload
technical reconciliation CTA
```

---

# 8. Approved Transient Feedback

The design includes success/error toasts on the exact Theme 05 source owner.

These feedback cases are intentionally consolidated by semantic, not by source screen.

## 8.1 SG07-T01 / SG07-T02 — Gửi thành công

Same feedback contract; only the Theme 05 host differs.

```text
DeliverySuccessFeedback
└── VToast
    ├── type: success
    ├── message:
    │   "Đã gửi hóa đơn."
    └── dismiss
```

Hosts:

```text
SG07-T01
→ Chi tiết đơn hàng

SG07-T02
→ Kết quả bán hàng
```

No separate success-toast implementation is required solely because the source host differs.

After authoritative delivery success, the SG-02 delivery summary may resolve to `Đã gửi` according to the delivery-display contract.

## 8.2 SG07-T03 / SG07-T04 — Gửi lỗi

Same feedback contract; only the Theme 05 host differs.

```text
DeliveryFailureFeedback
└── VToast
    ├── type: danger
    ├── message:
    │   "Không thể gửi hóa đơn. Vui lòng thử lại."
    └── dismiss
```

Hosts:

```text
SG07-T03
→ Chi tiết đơn hàng

SG07-T04
→ Kết quả bán hàng
```

These toasts represent a **determinate delivery failure**.

Do not use this failure toast merely because a delivery request timed out or is still unresolved.

The ElectronicInvoice remains `Đã phát hành`.

---

## 9. Delivery Display Contract

SG-07 follows the Theme 08 delivery-display rules:

| Delivery history / active operation | Primary delivery display | Secondary behavior |
|---|---|---|
| No successful delivery, no active delivery | `Chưa gửi` | none |
| No successful delivery, `PROCESSING` | `Đang gửi` | competing send blocked (`operationLocked`) |
| No successful delivery, latest `UNKNOWN` | `Không xác định kết quả` | manual resend allowed |
| No successful delivery, latest determinate failure | `Gửi lỗi` | send/resend available when allowed |
| At least one successful delivery | `Đã gửi` | later resend PROCESSING/FAILED/UNKNOWN may set secondary attention |

### Prior-success rule

A later resend failure or unresolved result must not erase a previous successful delivery.

```text
at least one success
+ later resend failed/unresolved
→ primary summary remains "Đã gửi"
```

History still records each business delivery independently.

---

## 10. First Send vs Resend

### First send

```text
no InvoiceDelivery for current ElectronicInvoice
→ SendInvoiceSheet
→ title "Gửi hóa đơn điện tử"
→ primary "Gửi hóa đơn"
→ suggestion from first-send recipient rules
→ no history link
```

### Resend

```text
has InvoiceDelivery history
→ ResendInvoiceSheet
→ title "Gửi lại hóa đơn điện tử"
→ primary "Gửi hóa đơn" (same CTA copy as first send)
→ suggestion from latest delivery of current ElectronicInvoice
→ show history link
→ when operationLocked: field/CTA locked, history link still enabled
```

Do not collapse first send and resend into presentation copy that loses their distinct user intent.

They may share lower-level email-field/form anatomy internally, but they are separate public semantic surfaces in the current Audit Manifest.

---

## 11. Validation Contract

Validation belongs to the current email draft.

### Valid

```text
helper:
"Email chỉ áp dụng cho lần gửi này."

primary action:
eligible
```

### Empty

```text
field blank
normal helper
primary action unavailable until valid
```

### Invalid

```text
error semantic
helper:
"Email không đúng định dạng."

primary action:
disabled
```

### Corrected after invalid

```text
valid email entered
→ remove validation error
→ restore normal helper
→ primary becomes eligible
```

The current draft email must never update the customer's master profile automatically.

---

## 12. Loading Contract

Loading is an active delivery operation, not a new field value.

```text
O01-D
├── email value unchanged
├── email field disabled
├── normal helper unchanged
├── primary copy unchanged
├── primary button loading
└── repeated submit blocked
```

The SRS requires:

```text
Button label remains "Gửi hóa đơn"
Button state = Loading
```

The exact spinner/rendering follows the current Design System `VButton` loading contract.

For resend, the same delivery-operation rule applies when its send command is active even though the current Audit Manifest has only one explicit loading specimen (`O01-D`).

---

## 13. Permission Contract

Send permission and history-view permission are independent.

```text
send permission
≠
view history permission
```

Opening SG-07 must not be treated as proof that every subsequent action is authorized.

Permission is re-evaluated for the operation being performed.

The approved design does not define separate permission-denied SG-07 frames.

Do not invent a new full-screen permission surface from SG-07 alone.

---

## 14. Entry / Return Flow

```text
Theme05 source
└── OrderEInvoiceRow — Đã phát hành
    └── SG02 PostIssueEInvoiceActionSheet
        └── Gửi hóa đơn
            └── SG07
                ├── no history
                │   └── O01-A/B/C/D
                │
                └── has history
                    └── O02
                        └── Xem lịch sử gửi
                            └── D01
```

### Return continuity

```text
close O01 / O02
→ exact Theme 05 source

D01 back
→ Resend Sheet / O02

send success/failure
→ exact Theme 05 source
→ transient feedback there
```

The SRS explicitly defines history back as returning to the Resend Sheet.

---

## 15. Design System Mapping

Exact repository APIs take precedence over descriptive names here.

| UI responsibility | Intended mapping |
|---|---|
| Send / Resend sheet | `VBottomSheet` / current VET45 form-sheet pattern |
| Email input | current DS email/text-field component |
| Input validation | existing DS field error state |
| Primary action | `VButton` primary |
| Cancel action | `VButton` secondary |
| Loading send action | existing `VButton` loading behavior |
| History page shell | `VPageScaffold` |
| Invoice/history card | `VCard` |
| Issuance/delivery status | `VBadge` / semantic status |
| Success feedback | `VToast(type: success)` |
| Failure feedback | `VToast(type: danger)` |
| Text | `VText` |
| Spacing / typography / colors | existing DS semantic tokens |

### No new global component implied

Send/resend form composition, invoice history row and delivery feedback remain Theme 08 presentation compositions unless repository audit shows a genuine cross-product Design System gap.

---

## 16. Preview / Specimen Coverage

The SG-07 presentation example should cover the canonical Audit specimens:

```text
SendInvoiceSheet
├── O01-A — suggested email
├── O01-B — empty
├── O01-C — invalid
└── O01-D — loading

ResendInvoiceSheet
└── O02

InvoiceDeliveryHistoryPage / page specimen
└── D01
```

The approved-design transient feedback should also be visually verifiable:

```text
Success feedback
├── T01 — order detail host
└── T02 — sales result host
    → same toast contract

Failure feedback
├── T03 — order detail host
└── T04 — sales result host
    → same toast contract
```

Preview duplication is not required merely because host contexts differ; the harness may keep separate design/audit labels when needed.

No real email delivery RPC is required for presentation preview.

---

## 17. Harness & Audit Mapping

Current Audit Manifest:

```text
SG07-O01-A
↔ send_invoice_sheet.dart

SG07-O01-B
↔ send_invoice_sheet.dart

SG07-O01-C
↔ send_invoice_sheet.dart

SG07-O01-D
↔ send_invoice_sheet.dart

SG07-O02
↔ resend_invoice_sheet.dart

SG07-D01
↔ invoice_delivery_history_page.dart
```

The current Audit Manifest does not include:

```text
SG07-T01
SG07-T02
SG07-T03
SG07-T04
```

This matches the SRS note that independent success/error toasts on source screens are not part of the final screen inventory.

The toasts remain approved transient feedback and may be implemented/reused without expanding the Audit Manifest unless the team intentionally changes the audit convention.

---

## 18. Known SG-07 Gaps / Mismatches

### GAP-01 — Toasts exist in approved design but not final Audit screen inventory

Approved design contains:

```text
T01 / T02 — "Đã gửi hóa đơn."
T03 / T04 — "Không thể gửi hóa đơn. Vui lòng thử lại."
```

SRS says source-screen success/error toasts are independent feedback and are not part of the final screen inventory.

Therefore:

```text
visual feedback → required by approved design
audit specimen expansion → not required by current SRS/Audit convention
```

Do not create four unique toast widgets just because four host frames are shown.

### GAP-02 — Loading specimen is listed for Send Sheet only

Audit/SRS explicitly list `O01-D` as the loading Send Sheet variant.

Resend uses the same delivery operation semantics, but there is no separate canonical Resend-loading specimen in the final inventory.

If preview/implementation needs to demonstrate resend loading, reuse the same stable-value/helper/loading rules without inventing a new SG07-Oxx identifier.

---

## 19. Forbidden Interpretations

Do not derive from SG-07:

```text
CC/BCC
multiple recipient emails
checkbox to save email
automatic Theme 03 email update
automatic BuyerInvoiceSnapshot update
automatic InvoiceSnapshot update
full-screen delivery-status page
technical "Kiểm tra kết quả" CTA
technical retry row in history
one history row per technical retry
raw MISA detail in history
delivery failure changing invoice issuance state
timeout automatically becoming "Gửi lỗi"
history action added as a fourth action in SG-02 post-issued sheet
separate Send Sheet for O01-A/B/C/D
separate success implementation for T01 vs T02
separate failure implementation for T03 vs T04
four new Audit entries solely because the design board shows four source-host toast frames
```

---

## 20. Acceptance Summary

SG-07 is correctly mapped when:

1. SG-07 starts from the post-issued `Gửi hóa đơn` action owned by SG-02.
2. First-send O01-A/B/C/D are states of one `SendInvoiceSheet`.
3. O01-A suggests one email and keeps it editable.
4. O01-B starts blank when no valid suggestion exists.
5. O01-C shows `Email không đúng định dạng.` and prevents submit.
6. Validating the email again restores `Email chỉ áp dụng cho lần gửi này.`.
7. O01-D preserves email value/helper/copy, disables the field and blocks repeated submit.
8. Opening a Send/Resend Sheet alone creates no `InvoiceDelivery`.
9. Email entered in SG-07 applies only to that delivery and does not update Theme 03/snapshots.
10. O02 is the resend surface when delivery history exists.
11. O02 proposes the latest delivery recipient for the same ElectronicInvoice and remains editable.
12. `Xem lịch sử gửi` exists only in the Resend Sheet when history exists.
13. D01 is read-only and shows each business `InvoiceDelivery` as one history row.
14. History shows result, actual recipient email, time and actor/`Tự động`.
15. History hides raw provider/technical attempt detail.
16. D01 back returns to the Resend Sheet.
17. Delivery failure/unknown never changes invoice issuance state `Đã phát hành`.
18. Prior successful delivery remains the primary `Đã gửi` truth even if a later resend fails/is unresolved.
19. T01/T02 share one success-feedback contract: `Đã gửi hóa đơn.`.
20. T03/T04 share one failure-feedback contract: `Không thể gửi hóa đơn. Vui lòng thử lại.`.
21. Determinate failure feedback is not used for timeout/unresolved delivery.
22. No full-screen success/error delivery page is introduced.
23. No extra SG-02 history action is introduced.
24. The exact Theme 05 source context is preserved across send/resend/history/feedback flows.
