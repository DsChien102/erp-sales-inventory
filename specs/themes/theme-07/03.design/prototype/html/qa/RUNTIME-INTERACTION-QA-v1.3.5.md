# BJ02 + BJ06 interaction/evidence runtime QA — v1.3.5

**Result: 52/52 PASS**

Chromium interaction QA against the cumulative v1.3.5 workbench at the canonical 402 × 874 product viewport.

## Checks

- [x] Canonical mobile frame is 402 x 874 — [402, 874]
- [x] SCR008 warehouse is a select control
- [x] SCR008 warehouse selector is disabled
- [x] SCR008 warehouse resolves default warehouse — Kho mặc định
- [x] SCR008 date uses native date input
- [x] SCR008 date minimum equals tenant/client current day fixture — min=2026-09-03 today=2026-09-03
- [x] SCR008 evidence is file input
- [x] SCR008 has no text evidence field
- [x] Past receiving date exposes validation error
- [x] Past receiving date blocks Continue
- [x] Missing delivery file blocks Continue
- [x] Uploaded delivery file name is shown
- [x] Valid supplier/date/file enables Continue
- [x] SCR008 product copy has no technical evidence wording
- [x] SCR008 no horizontal overflow
- [x] Quick header advances to SCR009
- [x] Multi-UOM product shows all UOM choices directly — 2
- [x] Multi-UOM chooser has no select/dropdown
- [x] UOM choices remain on SCR009 before selection
- [x] SCR009 UOM chooser no horizontal overflow
- [x] Choosing UOM advances directly to SCR084
- [x] Selected Product/UOM already resolved in detail
- [x] Detail does not ask UOM again
- [x] LOT collection action says Thêm lô khác
- [x] Detail completion CTA remains Xong
- [x] No exact ambiguous Thêm lô button remains
- [x] SCR084 no horizontal overflow
- [x] Single-UOM Product advances directly to SCR084
- [x] Wrong-LOT shows reason choices directly — 4
- [x] Wrong-LOT evidence uses image file input
- [x] Wrong-LOT submit blocked before reason/evidence
- [x] Reason alone is insufficient
- [x] Reason plus LOT image enables maker submit
- [x] Uploaded LOT image filename shown
- [x] SCR032 copy uses Vietnamese reason wording
- [x] SCR032 no horizontal overflow
- [x] Submitting exception returns to return overview
- [x] Approver sees original and actual LOT
- [x] Approver sees structured reason
- [x] Approver sees evidence image reference
- [x] Approver sees maker identity
- [x] SCR034 no horizontal overflow
- [x] Reason Other plus image still blocked without description
- [x] Reason Other becomes valid with description and image
- [x] BJ05 handover explicitly refers to physical handover confirmation
- [x] BJ05 handover does not invent photo/signature/recipient/carrier inputs
- [x] BJ05 handover no horizontal overflow
- [x] BJ07 handover explicitly refers to physical handover confirmation
- [x] BJ07 handover does not invent photo/signature/recipient/carrier inputs
- [x] BJ07 handover hides technical commit/actor wording
- [x] BJ07 handover no horizontal overflow
- [x] No page-level JavaScript errors

## Scope

- BJ02: locked warehouse selector, temporal guard, file evidence, visible UOM choice, direct Product+UOM → detail, unambiguous LOT append.
- BJ06: structured wrong-LOT reason + required image evidence + approver evidence visibility.
- BJ05/BJ07: normal handover keeps system evidence + actor physical confirmation without inventing mandatory photo/signature/recipient fields.
