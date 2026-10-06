# v2.6.0 — BJ04 Figma DS structural migration

- Cumulative from v2.5.5.
- Structurally migrated `BJ-04 / UIF-04` to the live Figma DS canonical surface.
- Kept exactly one active Product surface: `SCR-021 — Giữ hàng theo đơn`.
- Preserved the Phase-1 business lock: reservation create/amend/release/re-evaluate is source/system-driven; Inventory has no manual mutation workflow.
- Replaced legacy context/product card grouping with `DS v2 / Info Row` + `VSection` + `DS v2 / List Row (Status)`.
- Uses `VBadge Warning` only on product rows that are actually short; FULL has no success banner/badge.
- `PARTIAL/SHORT` uses a compact warning without aggregating shortage quantities across different UOMs.
- `RELEASED` is an informational lifecycle state and is not rendered as shortage.
- `STALE` represents a reconciled/latest projection and has no technical retry CTA.
- Removed visible `Chỉ xem`/entry-explanation noise from the AppBar while keeping the surface truly read-only by behavior.
- Preserved 402×874 mobile canvas, Back-to-source behavior and all non-target BJ code/registries.
- Added scoped `v260-bj04-ds-fidelity.css`; no new reusable Theme 7 component.
