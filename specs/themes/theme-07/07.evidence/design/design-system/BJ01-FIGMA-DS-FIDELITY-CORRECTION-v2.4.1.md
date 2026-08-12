# BJ01 — Figma DS Fidelity Correction v2.4.1

**Parent:** v2.4.0  
**UI authority:** live Figma DS pages `505:5889`, `505:5890`, `505:5891`.

## Correction scope

This release does not change BJ01 business intent. It corrects HTML fidelity and DS usage after visual review exposed drift.

- Inter is explicitly loaded for the HTML renderer; no font binary is bundled in the package.
- `VBanner` is rebuilt to the live `526:4215` anatomy: 20px semantic icon without a decorative circle, 12px gap, 16px padding, 1px semantic border, radius 12, Label/Default title and Body/Small body.
- `VSearchBar` follows `522:7245`: 370x44, icon 20, gap 8, px16, radius 8, Body/Default input.
- `VChip` follows `522:7449`: 34px visual pill inside a >=44px interaction rhythm, px12, Label/Small.
- `DS v2 / List Row` follows `525:519`: 370x76, pl16/pr24, gap12, radius12, 20px leading/trailing icons, Label/Default + Body/Small copy.
- Product rows no longer inject badge + quantity into the Navigation trailing slot. Product availability and attention context live in the subtitle while the trailing anatomy remains the canonical chevron.
- `DS v2 / Info Row` follows `525:351`: 44px, gap8, no divider/card/table treatment.
- AppBar Back uses the canonical 24px icon.
- Theme7 availability summary remains Product UI and consumes canonical typography, spacing, border and radius tokens instead of masquerading as a Core DS component.
- LOT/provenance remain contextual Product UI overlays and consume DS sheet variables.
- A final scoped fidelity stylesheet is loaded last for UIF-01 so historical prototype CSS cannot override canonical geometry.

## Verification

`prototype/html/qa/BJ01-FIGMA-DS-FIDELITY-QA-v2.4.1.md` validates computed browser styles, not only DS labels. The gate covers exact geometry/type for VBanner, VSearchBar, VChip, List Row, Info Row, AppBar icon, Product composition token use, overlays and overflow.
