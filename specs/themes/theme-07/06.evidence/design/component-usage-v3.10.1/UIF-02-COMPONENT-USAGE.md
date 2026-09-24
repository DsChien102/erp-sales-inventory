# UIF-02 — Figma DS Component Usage · v2.5.2

**Scope:** BJ-02 / UIF-02  
**UI authority:** live Figma DS — pages `505:5889`, `505:5890`, `505:5891`  
**Business authority:** BJ02/UC/shared contracts and screen contracts.

## Selection rule

`V_component phù hợp → canonical component khác → Pattern/Template → composition từ asset hiện hữu → component mới chỉ khi chứng minh reusable gap.`

BJ02 v2.5.2 creates **no new feature component identity**. A layout/grouping is not declared as a component.

## Screen mapping

| Screen | Template | Main existing DS assets |
|---|---|---|
| SCR-006 | Mobile / Nested List | VAppBar, DS v2 / List Row |
| SCR-007 | Mobile / Nested List | VSearchBar, DS v2 / Record Card, VEmptyState |
| SCR-008 | Mobile / Form | VSelect, VTextField, VFileDropZone, VBanner, DS v2 / Select Sheet, DS v2 / List Row Selection, VSearchBar, VButton, DS v2 / Sticky Footer |
| SCR-009 | Mobile / Nested List | VSection, DS v2 / Info Row, VSearchBar, DS v2 / Record Card, DS v2 / List Row Selection, VEmptyState, VButton |
| SCR-084 | Mobile / Form | VSection, VTextField, VSelect, DS v2 / Key-value Row, VNumericKeypadSheet, VButton, DS v2 / Sticky Footer |
| SCR-010 | Mobile / Detail | VBanner, VSection, DS v2 / Info Row, DS v2 / Key-value Row, VButton, DS v2 / Sticky Footer |
| SCR-011 | Mobile / Detail | VBanner, VSection, DS v2 / Info Row, DS v2 / Key-value Row, VButton, DS v2 / Sticky Footer |
| SCR-012 | Mobile / Detail/State by state | VLoading, VEmptyState, VBanner, VSection, DS v2 / Key-value Row, VButton |
| SCR-013 | Mobile / Detail/State by state | VLoading, VBanner, DS v2 / Timeline Item, VButton |

## Locked implementation constraints

- `DS v2 / List Row` uses only canonical row responsibilities; rich receipt summaries use `DS v2 / Record Card`.
- Supplier selection in Quick receipt uses `VSelect → DS v2 / Select Sheet`; it is not a custom inline combobox and never creates Supplier master data.
- v3.9.2 supersedes the historical disabled-selector rule: a locked receiving warehouse is an authoritative read-only fact and uses `VTextField` read-only expression, not a disabled selector with a fake chevron.
- `VFileDropZone` keeps the canonical `310×116` Default geometry/state after a file is selected; selected filename changes content, not component state. The leading icon uses the approved `li:cloud-upload` slot.
- `DS v2 / Sticky Footer` is `402×92`, `pt=12`, `pb=24`; actions are `44px` high. Dual decisions use `181 + 8 + 181`.
- Four authoritative quantity inputs are `Đạt / Cách ly / Hỏng / Từ chối`. They are explicit `338×44` numeric hit areas composed with `DS v2 / Key-value Row` and edited through `VNumericKeypadSheet`; total is derived/read-only.
- `VNumericKeypadSheet` preserves the previous value until `Lưu`; decimal is disabled for the current whole-unit UOM fixtures.
- Review/approval screens use flat `VSection` + `Info Row` / `Key-value Row`; do not reintroduce legacy `review-card` card soup.
- `VBanner` Compact is only used with brief copy that fits the canonical 72px density. Longer guidance uses Default density.
- Quick receipt never creates Supplier/Product master data; maker submit and approver decision are separate actor contexts.
- UNKNOWN keeps the same operation identity and never offers blind retry.

## v2.5.2 Quick flow correction

- Quick Product with one inbound UOM opens `SCR-084` immediately after Product selection.
- Quick Product with multiple inbound UOMs exposes all UOMs as direct `DS v2 / List Row` Selection choices; choosing one opens `SCR-084` immediately. No `VSelect` dropdown is used for this decision.
- The real `SCR-008 → SCR-009` interaction path is a mandatory runtime QA gate; direct seeded screen renders are not sufficient.
- No new Theme7 shared component is introduced.

## v2.7.3 current selected-Product context

- `SCR-084` selected Product uses `DS v2 / List Row 525:519`, `Type=Status`, `Density=Compact` (`370×52`) rather than an ad-hoc identity section or sparse fixed-height Summary Card.
- The same compact context-row pattern is used only where the Product context is read-only and subordinate to the editing task; quantity and LOT controls remain separate.
- Record Card supporting content uses available content width (`100%`) rather than a hard-coded inner width, preventing the inherited 2px overflow on `SCR-007/SCR-009`.

- v3.9.2: SCR-008 warehouse/date are read-only `VTextField`; no `VDatePicker` or generic `VTextarea`. Delivery evidence supports multiple refs under Shared Attachment Policy. SCR-084 uses `VSelect + VTextField` composition to preserve DAY/MONTH/YEAR precision.
