# Changelog v2.5.1 — BJ01 + BJ02 UI / Figma DS correction

Parent: **v2.5.0**.

## Corrected

- Re-applied BJ01 `Key-value Row 525:358` fidelity in a last-loaded scoped layer so later BJ/legacy CSS cannot reintroduce the old label/value collision.
- Reworked BJ02 SCR-008 around canonical `VSelect`, `Select Sheet`, `VFileDropZone`, `VDatePicker`, `VTextarea` and exact Sticky Footer geometry.
- Replaced BJ02 four tall classification fields with explicit numeric hit areas + canonical `VNumericKeypadSheet`.
- Flattened Product identity and review/approval compositions; removed unnecessary card surfaces.
- Corrected Compact VBanner usage to prevent clipped copy.
- Added approved cloud-upload icon slot to the file drop zone.
- Added computed-style + visual QA for BJ01/BJ02 and re-ran all 85 active flow/screen renders.

No business rule, action registry, or screen registry is intentionally changed in this patch.
