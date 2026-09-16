# TH08 / SG-06 — Mapped UI Tree

## Lấy và lưu tài liệu hóa đơn

> **Purpose:** UI contract ở cấp Screen Group giữa Theme 08 SRS, approved SG-06 design, Audit Manifest và implementation.
>
> **Scope:** SG-06 only.
>
> **Primary context:** `ElectronicInvoice` đã authoritative, được mở từ Bottom Sheet HĐĐT sau phát hành trên đúng màn nguồn Theme 05.
>
> **Boundary:** SG-06 sở hữu Action Sheet chọn/lấy tài liệu PDF hoặc XML và trạng thái loading theo từng document operation. Hệ điều hành sở hữu file exporter. SG-06 không dựng viewer/file screen riêng và không phụ thuộc SG-05.

---

## 1. Source of Truth

For SG-06-specific implementation details, use the following precedence:

1. **Theme 08 SRS / BA specification** — document retrieval rules, permission, document-operation semantics, file-exporter handoff and error behavior.
2. **Latest approved SG-06 design** — visual hierarchy, copy, loading variants and action presentation.
3. **E-Invoice Audit Manifest** — canonical specimen IDs, surface types and planned implementation paths.
4. **Existing repository implementation** — actual component APIs, architecture and reusable presentation anatomy.
5. **This document** — mapping between the sources above.

When sources disagree, the mismatch is recorded explicitly rather than silently reconciled.

---

## 2. Ownership Boundary

### Theme 05 source owner

Theme 05 continues to own the originating screen:

```text
SalesOrderDetail
or
SalesResult
```

The source context must survive the SG-02 → SG-06 → file-exporter round trip.

### SG-02 owns the entry surface

```text
PostIssueEInvoiceActionSheet
└── "Tài liệu XML & PDF"
    └── open SG-06
```

Opening the SG-02 post-issued sheet or the SG-06 document sheet alone must not create a document request.

### SG-06 owns

```text
InvoiceDocumentsActionSheet
├── PDF action
├── XML action
├── PDF loading presentation
└── XML loading presentation
```

### Operating system owns

```text
Native Share Sheet / file exporter
├── Save to Files and other share destinations
├── destination selection
├── save/share destination behavior
└── exporter cancellation (dismiss)
```

SG-06 does not build a VET45 PDF/XML viewer or file browser.
SG-06 must not open the signed download URL in a browser (`launchUrl` / in-app browser / Safari) for PDF or XML save actions.

---

## 3. Specimen ≠ Widget

SG-06 has three canonical specimens but only one public presentation unit.

```text
InvoiceDocumentsActionSheet
├── SG06-O01 — idle
├── SG06-O02 — loading PDF
└── SG06-O03 — loading XML
```

All three specimens map to the same planned widget:

```text
modules/einvoice/presentation/lib/src/widgets/
invoice_documents_action_sheet.dart
```

Do not create:

```text
PdfDocumentsSheet
XmlDocumentsSheet
PdfLoadingSheet
XmlLoadingSheet
```

solely because the approved board contains separate frames.

---

## 4. Canonical Specimen Catalog

| Specimen | Surface | Context | State / meaning | Planned implementation |
|---|---|---|---|---|
| `SG06-O01` | Action Sheet | Authoritative ElectronicInvoice | Idle — choose PDF or XML | `invoice_documents_action_sheet.dart` |
| `SG06-O02` | Action Sheet variant | PDF document operation | Loading PDF | same widget |
| `SG06-O03` | Action Sheet variant | XML document operation | Loading XML | same widget |

The SRS explicitly defines SG-06 as `SG06-O01 → O03`; there is no SG-06 full-screen document page in MVP.

---

## 5. SG-06 State Contract

```text
InvoiceDocumentsPresentationState
├── idle
├── loadingPdf
└── loadingXml
```

The presentation state is operation-specific.

Conceptually, PDF and XML are independent document operations:

```text
InvoiceDocumentOperation
├── PDF
│   ├── idle
│   └── loading / resolving
└── XML
    ├── idle
    └── loading / resolving
```

Existing application/domain types take precedence if they already represent document type and operation state.

### Critical rule

Loading is scoped to the selected document action.

```text
loadingPdf
→ PDF action locked + spinner
→ XML title/helper unchanged

loadingXml
→ XML action locked + spinner
→ PDF title/helper unchanged
```

Do not replace the entire sheet with a global loading state.

---

# 6. Mapped UI Tree

## 6.1 SG06-O01 — Tài liệu hóa đơn / Idle

**Module widget**

```text
modules/einvoice/presentation/lib/src/widgets/
invoice_documents_action_sheet.dart
```

**Entry**

```text
SG02 PostIssueEInvoiceActionSheet
└── InvoiceDocumentsAction
    ├── title: "Tài liệu XML & PDF"
    └── tap
        └── SG06-O01
```

**Approved design tree**

```text
InvoiceDocumentsActionSheet
└── VBottomSheet / current VET45 Action Sheet pattern
    ├── drag handle
    ├── title:
    │   "Tài liệu hóa đơn điện tử"
    └── DocumentActionList
        ├── SavePdfAction
        │   ├── LeadingIcon : VIcon
        │   ├── Content
        │   │   ├── title:
        │   │   │   "Lưu bản PDF"
        │   │   └── helper:
        │   │       "Lưu hóa đơn dạng PDF vào thiết bị"
        │   └── trailing:
        │       chevron-right
        │
        └── SaveXmlAction
            ├── LeadingIcon : VIcon
            ├── Content
            │   ├── title:
            │   │   "Lưu tệp XML"
            │   └── helper:
            │       "Lưu dữ liệu hóa đơn điện tử dạng XML"
            └── trailing:
                chevron-right
```

### Action count invariant

The sheet contains exactly two document actions:

```text
1. Lưu bản PDF
2. Lưu tệp XML
```

No additional document/view action belongs in SG-06.

### Interaction

```text
open sheet
→ no document request

tap "Lưu bản PDF"
→ check permission/document capability
→ begin PDF document operation
→ SG06-O02

tap "Lưu tệp XML"
→ check permission/document capability
→ begin XML document operation
→ SG06-O03
```

---

## 6.2 SG06-O02 — Đang chuẩn bị bản PDF

Same `InvoiceDocumentsActionSheet`, PDF operation loading.

```text
InvoiceDocumentsActionSheet
└── VBottomSheet
    ├── title:
    │   "Tài liệu hóa đơn điện tử"
    └── DocumentActionList
        ├── SavePdfAction
        │   ├── state: loading / non-interactive
        │   ├── LeadingIcon
        │   │   └── disabled/loading treatment
        │   ├── Content
        │   │   ├── title:
        │   │   │   "Lưu bản PDF"
        │   │   └── helper:
        │   │       "Lưu hóa đơn dạng PDF vào thiết bị"
        │   └── trailing:
        │       LoadingIndicator
        │
        └── SaveXmlAction
            ├── state: normal
            ├── LeadingIcon
            ├── Content
            │   ├── title:
            │   │   "Lưu tệp XML"
            │   └── helper:
            │       "Lưu dữ liệu hóa đơn điện tử dạng XML"
            └── trailing:
                chevron-right
```

### Loading contract

For the selected PDF action:

- Title remains unchanged.
- Helper remains unchanged.
- Repeated PDF interaction is blocked.
- Chevron is replaced by the loading indicator.
- Visual state follows the existing disabled/loading treatment from the shared action-item pattern.

For the XML action:

- Title remains unchanged.
- Helper remains unchanged.
- It is not visually converted into the PDF loading state.
- It retains the normal action presentation shown in the approved design.

Do not:

```text
change title to "Đang tải PDF"
change helper copy
show a global sheet spinner
replace both action rows with loading
start another PDF request from repeated taps
```

### Success

```text
PDF document ready
→ validate file/document response
→ hand off to OS file exporter
→ preserve source context
```

The issuance state remains `Đã phát hành`.

---

## 6.3 SG06-O03 — Đang chuẩn bị tệp XML

Same `InvoiceDocumentsActionSheet`, XML operation loading.

```text
InvoiceDocumentsActionSheet
└── VBottomSheet
    ├── title:
    │   "Tài liệu hóa đơn điện tử"
    └── DocumentActionList
        ├── SavePdfAction
        │   ├── state: normal
        │   ├── LeadingIcon
        │   ├── Content
        │   │   ├── title:
        │   │   │   "Lưu bản PDF"
        │   │   └── helper:
        │   │       "Lưu hóa đơn dạng PDF vào thiết bị"
        │   └── trailing:
        │       chevron-right
        │
        └── SaveXmlAction
            ├── state: loading / non-interactive
            ├── LeadingIcon
            │   └── disabled/loading treatment
            ├── Content
            │   ├── title:
            │   │   "Lưu tệp XML"
            │   └── helper:
            │       "Lưu dữ liệu hóa đơn điện tử dạng XML"
            └── trailing:
                LoadingIndicator
```

### Loading contract

For the selected XML action:

- Title remains unchanged.
- Helper remains unchanged.
- Repeated XML interaction is blocked.
- Chevron is replaced by the loading indicator.
- Visual state follows the existing disabled/loading treatment from the shared action-item pattern.

For the PDF action:

- Title remains unchanged.
- Helper remains unchanged.
- It retains the normal action presentation shown in the approved design.

### Success

```text
XML document ready
→ validate file/document response
→ hand off to OS file exporter
→ preserve source context
```

The issuance state remains `Đã phát hành`.

---

## 7. Shared Action Anatomy

SG-06 action rows visually align with the reusable E-Invoice action-item anatomy already established in SG-02 where applicable.

```text
DocumentActionItem
├── LeadingIcon
├── Content
│   ├── title
│   └── helper
└── Trailing
    ├── chevron-right
    └── or LoadingIndicator
```

This does not require a new Design System component if the existing shared E-Invoice action-row composition already satisfies the contract.

### Normal state

```text
icon
title
helper
chevron-right
tap enabled
```

### Loading state

```text
selected action only
├── interaction locked
├── loading/disabled visual treatment
├── title unchanged
├── helper unchanged
└── spinner replaces chevron
```

The loading state is operational, not a new document-action identity.

---

## 8. Document Operation Semantics

### PDF and XML are separate operations

The SRS treats PDF and XML independently.

```text
PDF request
→ PDF InvoiceDocument operation

XML request
→ XML InvoiceDocument operation
```

A PDF result must not satisfy an XML request and vice versa.

### Document source

Both official documents come from MISA meInvoice.

```text
MISA meInvoice
→ official PDF / XML
→ VET45 validates/records operation result
→ OS file exporter
```

VET45 must not generate a substitute legal PDF/XML from local invoice data.

### Idempotency / unresolved request

Repeated interaction on the same loading document action must not create a competing request.

Timeout or an unresolved response is not automatically a determinate document failure.

---

## 9. File Exporter Handoff

When the requested file is ready and valid:

```text
SG06 document operation
→ OS native Share Sheet (Save to Files / other destinations)
```

SG-06 does not own the exporter destination UI.

### Mobile document success

```text
Mobile document success
→ tải bytes từ signed URL
→ kiểm SHA-256
→ native Share Sheet
→ người dùng chọn Save to Files hoặc destination khác
→ không mở signed URL bằng browser
```

Signed URL is used only as an internal fetch source. It must never be launched or shared as a URL.

Native Share Sheet is opened only after command/query completes, bytes are fully loaded, non-empty, and checksum matches. Loading/locking on SG-06 spans the entire command → poll → HTTP GET → checksum path.

### Return contract

```text
source screen
→ SG02 post-issued sheet
→ SG06
→ native Share Sheet
→ success or dismiss Share Sheet
→ close SG-06
→ exact Theme 05 source context
```

The source may be:

```text
SalesOrderDetail
or
SalesResult
```

### Exporter cancellation

User cancellation / dismiss of the OS Share Sheet:

```text
cancel / dismiss exporter
→ not a document-operation failure
→ no SnackBar lỗi retrieval
→ close SG-06
→ no issuance-state change
→ return safely to source context
```

`ShareResultStatus.success` and `ShareResultStatus.dismissed` are both valid handoffs.
---

## 10. Error Contract

The SRS requires document errors to be reflected on the correct source owner.

```text
Document export failure
→ không mở browser fallback
→ SG-06 giữ mở
→ một safe error surface
→ projection vẫn issued
```

```text
document retrieval/validation failure
→ leave/close document operation surface as appropriate
→ for export/native-share failure: keep SG-06 open so the user can retry
→ return/remain on exact Theme 05 source owner
→ show exactly one safe error feedback (SnackBar) there
→ keep ElectronicInvoice issuance state = "Đã phát hành"
```

There is no SG-06 full-screen document error in MVP.

There is no canonical SG06-Txx error specimen in the current Audit Manifest.

### Current visual boundary

The supplied approved SG-06 board contains only:

```text
O01 — idle
O02 — loading PDF
O03 — loading XML
```

It does not define the exact error-feedback visual/copy.

Therefore this contract does not invent:

- a new full-screen error;
- a new SG06-Txx specimen;
- browser fallback as a substitute for native save failure.

Approved safe exporter failure copy (app-owned):

```text
Không thể lưu tài liệu hóa đơn trên thiết bị. Vui lòng thử lại.
```

See `GAP-01` for any remaining approved-design gaps beyond this copy.
---

## 11. Permission / Capability Presentation Contract

SG-06 requires document access/download permission.

Permission is checked when the file is actually granted, not only when the sheet is opened.

Provider/document capability may also determine whether a document action can start.

Known SRS edge case:

```text
provider does not support a document type
→ do not start that document action
```

The supplied approved design does not contain a dedicated unsupported/permission-denied SG-06 frame.

Do not invent a new screen/state without an approved source.

---

## 12. Entry and Return Flow

```text
Theme05 Source
└── OrderEInvoiceRow — Đã phát hành
    └── SG02 PostIssueEInvoiceActionSheet
        └── "Tài liệu XML & PDF"
            └── SG06-O01
                ├── Lưu bản PDF
                │   └── SG06-O02
                │       ├── success → OS File Exporter → Source
                │       └── error   → Source + error feedback
                │
                └── Lưu tệp XML
                    └── SG06-O03
                        ├── success → OS File Exporter → Source
                        └── error   → Source + error feedback
```

There is no SG-05 dependency in this flow.

---

## 13. Action Availability Matrix

| SG-06 state | PDF action | XML action | PDF trailing | XML trailing |
|---|---|---|---|---|
| `O01 idle` | Enabled if permitted/capable | Enabled if permitted/capable | Chevron | Chevron |
| `O02 loadingPdf` | Loading / repeated tap blocked | Disabled (same title/helper) | Spinner | Chevron |
| `O03 loadingXml` | Disabled (same title/helper) | Loading / repeated tap blocked | Chevron | Spinner |

Title/helper copy remains stable in every variant.

Product decision (confirmed): only one foreground document export at a time in ERP. While PDF or XML is loading, the sibling action is disabled (`enabled: false`, `onTap: null`) but keeps stable copy. There is no concurrent PDF+XML loading state.

---

## 14. Design System Mapping

Exact repository APIs take precedence over descriptive names here.

| UI responsibility | Intended mapping |
|---|---|
| Action sheet | `VBottomSheet` / current VET45 sheet pattern |
| Document action row | existing E-Invoice action-item composition if compatible |
| Leading icon | `VIcon` + canonical existing icon |
| Text | `VText` |
| Trailing normal state | chevron-right |
| Trailing loading state | current DS loading indicator |
| Loading/disabled surface | current semantic disabled/loading treatment |
| Spacing | `VSpacing`, `VGap` |
| Colors | semantic `context.vColors` / current DS tokens |
| Error feedback on source | existing feedback pattern; exact SG-06 visual currently unresolved |

### Visual notes from approved design

The selected loading action is visually subdued while retaining title/helper copy and shows a spinner at trailing.

The non-selected sibling keeps the same title/helper and chevron but is disabled until the foreground export finishes.

Do not hardcode PDF/XML-specific colors or loading chrome outside the established Design System / shared E-Invoice action-item contract.

---

## 15. Preview / Specimen Coverage

The SG-06 presentation example should audit:

```text
InvoiceDocumentsActionSheet
├── SG06-O01 — idle
├── SG06-O02 — loading PDF
└── SG06-O03 — loading XML
```

Preview needs to prove:

```text
O01
├── PDF normal + chevron
└── XML normal + chevron

O02
├── PDF loading + spinner + no repeated PDF tap
└── XML disabled + same title/helper + chevron

O03
├── PDF disabled + same title/helper + chevron
└── XML loading + spinner + no repeated XML tap
```

The preview does not need to implement a real MISA request or real OS file exporter.

---

## 16. Harness & Audit Mapping

Current Audit Manifest mapping:

```text
SG06-O01
↔ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  invoice_documents_action_sheet.dart

SG06-O02
↔ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  invoice_documents_action_sheet.dart

SG06-O03
↔ apps/erp/lib/features/sales/presentation/widgets/einvoice/
  invoice_documents_action_sheet.dart
```

All three specimen IDs intentionally point to one widget path.

Manifest statuses continue to follow the repository's existing audit convention:

```text
pending → Chưa làm
stub    → Stub
done    → Done
```

This document does not redefine AuditStatus criteria.

---

## 17. Known SG-06 Gaps / Mismatches

### GAP-01 — Exact document-error feedback visual/copy

SRS requires:

```text
Error
→ đúng source owner
→ issuance state remains "Đã phát hành"
→ no full-screen document error
```

The current approved SG-06 design does not include an error-feedback frame or exact user-facing copy.

Therefore the error behavior is known, but exact transient-feedback visual/copy remains unresolved.

Do not invent a new SG06-Txx specimen solely to fill this gap.

### GAP-02 — Simultaneous PDF + XML loading presentation

Product decision (confirmed for ERP S4): only one foreground document export at a time. Sibling is disabled while the selected type loads. There is no concurrent PDF+XML loading UI.

The canonical visual set remains:

```text
idle
loadingPdf
loadingXml
```

There is no approved `loadingPdfAndXml` specimen, and the application must not invent one.

---

## 18. Forbidden Interpretations

Do not derive from SG-06:

```text
SG-05 dependency
standalone PDF page
standalone XML page
VET45 legal-document viewer
VET45-generated legal PDF
VET45-generated legal XML
document request just because the sheet opens
global loading spinner replacing the sheet
changed action title/helper while loading
repeated request for the same loading document type
issuance status changing because document retrieval fails
full-screen document-error page
public long-lived signed URL
file-export destination UI owned by VET45
exporter cancellation treated as retrieval failure
separate public widget for O01/O02/O03
```

---

## 19. Acceptance Summary

SG-06 is correctly mapped when:

1. It is entered from `Tài liệu XML & PDF` in the SG-02 post-issued action sheet.
2. Opening SG-06 creates no document request.
3. O01 contains exactly `Lưu bản PDF` and `Lưu tệp XML`.
4. O01/O02/O03 use one `InvoiceDocumentsActionSheet`.
5. PDF and XML title/helper copy remain stable across loading variants.
6. O02 locks the PDF action (spinner) and disables XML while keeping XML title/helper.
7. O03 locks the XML action (spinner) and disables PDF while keeping PDF title/helper.
8. The non-selected action remains disabled (not tappable) until the foreground export finishes.
9. Repeated interaction on the currently loading document action is blocked.
10. PDF/XML are obtained from MISA meInvoice rather than generated by VET45.
11. A valid ready file is handed to the operating-system native Share Sheet (Save to Files), never opened via browser/`launchUrl`.
12. Bytes are fetched from the signed URL, SHA-256 verified, then shared as `XFile` with correct MIME/filename; Share Sheet appears only after verification.
13. Closing/cancelling (dismiss) Share Sheet safely returns to the exact Theme 05 source context and closes SG-06 without an error SnackBar.
14. Exporter cancellation is not treated as document failure.
15. Document retrieval/validation/export failure does not change `Đã phát hành`; keeps SG-06 open with one safe error surface and re-enables PDF/XML.
16. No full-screen SG-06 document-error surface is introduced.
17. No SG-05 UI dependency is introduced.
18. Exact error-feedback UI beyond the approved save-to-device copy remains explicit as a gap until further design approval.
19. A simultaneous PDF+XML loading visual is not invented without an approved contract.
