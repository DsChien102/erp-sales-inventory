# Figma DS Visual QA — v2.7.1

**Result: PASS**

Visual review was performed on the canonical 402×874 mobile frame after the v2.7.1 live-Figma primitive correction layer.

## Reviewed surfaces

- `SCR-025 — Đơn cần lấy hàng`: Navigation and Status peer rows are visually aligned to the same Default List Row height. Actionable row has a chevron; source-owned waiting row does not.
- `SCR-026 — Hàng cần lấy`: order facts are grouped as one white rounded information surface; product Navigation rows are consistent and remain easy to scan.
- `SCR-027 — Chọn lô thay thế`: Selection rows are equal-height, use radio controls, and do not show navigation chevrons.
- `SCR-028 — Rà soát bàn giao`: grouped order facts and Key-value Row hierarchy are visually coherent; Emphasis and Default summary rows match the live DS intent.
- `UIF-08 / SCR-045`: multiple Info Rows remain grouped inside the existing product information card; no nested-card noise was introduced.
- Shared `VToast`: stable success and warning captures match the live component anatomy — 370×56 dark floating surface, semantic circular leading icon, Regular message, plain close X, correct 16px no-footer inset / 10px footer separation.

## Evidence

- `v271-bj05-captures/SCR025-READY.png`
- `v271-bj05-captures/SCR026-READY.png`
- `v271-bj05-captures/SCR027-OVERRIDE.png`
- `v271-bj05-captures/SCR028-PARTIAL.png`
- `v271-shared-captures/TOAST-SUCCESS-WITH-FOOTER.png`
- `v271-shared-captures/TOAST-WARNING-NO-FOOTER.png`
- `v271-shared-captures/UIF08-SCR045.png`

No horizontal clipping, mismatched peer-row height, false chevron affordance, floating multi-row Info Row group, or toast close-icon contamination was found in the reviewed captures.
