# Figma DS Runtime v2.9.3 — Working Freeze status

- Product wiring: **ON for UIF-01, UIF-02, UIF-04, UIF-05, UIF-06, UIF-07, UIF-08**.
- Newly Product-migrated UIF: **UIF-07 / BJ07 — supplier-return execution**.
- Live UI authority: **Figma DS v2.0.3 working audit**; inherited exact local mirror: **v2.0.2**.
- Product canvas: **402×874**; review bezel: **418×890**.
- Status: **WORKING_FREEZE_BJ01_BJ02_BJ04_BJ05_BJ06_BJ07_BJ08_REVIEW_READY**.
- New BJ07 feature component created: **0**.



## v2.9.3 — DS-native grouped collection density correction

- Live Figma Layout `Surface Grouping 4518:1545` is enforced: one homogeneous collection uses one light grouped surface; repeated Product subgroups are not independent cards.
- BJ07 SCR-037: Product+UOM = `List Row / Status / Compact 370×52`; actionable LOT = `Navigation / Default 370×76`.
- BJ07 SCR-039/SCR-041: Product+UOM status row + `Key-value Row 338×44` evidence; raw quantities are not VBadge.
- Same inherited card-soup correction is applied to BJ05 SCR-028 and BJ06 SCR-035.
- No feature component is created; group wrappers are Layout compositions with `data-layout-pattern`, not fake DS component claims.

## v2.9.2 — Canonical Product-group surface correction

- Migrated Product+UOM group identity is no longer implemented as floating `VText + VBadge`.
- BJ07 SCR-037/SCR-039/SCR-041 use `DS v2 / List Row` (`Type=Status`, `Density=Compact`) inside one bordered information surface; child LOT/allocation semantics remain Navigation List Row or Key-value Row.
- Same inherited anti-pattern corrected in BJ05 SCR-028 and BJ06 SCR-035.
- Composition reference order is locked: canonical Figma DS → Patterns/Templates → mature Product UI in prior Themes → HTML.
- No new Theme-specific component; no business behavior change.


## v2.9.1 — BJ07 hierarchy correction

1. SCR-036 is one homogeneous Navigation/Default request collection; stage appears only as badge. Waiting is Navigation/Disabled, not a different row type and not a separate titled collection.
2. SCR-037 differentiates parent from child: request context = Status/Compact; Product+UOM = structural VSection heading; exact LOT/non-LOT allocations = Navigation/Default rows.
3. SCR-039 and SCR-041 use Product+UOM headings plus grouped Key-value allocation evidence; factual result content is left-aligned.
4. Same-UOM totals are permitted only inside an exact Product+UOM group. Cross-UOM aggregation remains prohibited.
5. No new feature component was created. Live Figma DS nodes remain the component authority.

## v2.9.0 — BJ07 structural migration

1. Supplier-return commercial intent remains Purchase/source-owned; Inventory does not approve commerce again or rewrite source quantity/LOT.
2. SCR-036 separates Navigation work from source-owned waiting Status rows; same semantic collection keeps one List Row type/density.
3. SCR-037 is Product+UOM → exact allocation verification. Normal verification uses canonical `VBottomSheet 4695:6353`, no X and no duplicated per-allocation inline form.
4. Source change resets affected verification only; source cancel removes active work and releases pending system-side.
5. SCR-039 is the single actual-handover commit surface. Grouped Info Rows + Key-value allocation evidence avoid cross-UOM aggregation and redundant confirmation.
6. SCR-041 is terminal; COMPLETED/REJECTED/UNKNOWN/PERMISSION semantics preserve no-back and no-blind-retry rules.
7. DS fidelity review order remains: business contract → canonical live Figma component → Patterns/Templates → mature Product UI in available Figma Themes → HTML implementation.

## v2.7.3 locks

1. Same record collection keeps one `DS v2 / List Row` Type and Density. Temporary unavailability is `State=Disabled`, not a component-family change.
2. Disabled Navigation keeps the same chevron/anatomy and 370×76 geometry; the whole component uses Opacity/Disabled 0.4 and is non-interactive.
3. `Status / Compact` is 370×52 with p4/16, gap8, radius8. Use it for dense read-only context summaries; do not use it for a parent entity when doing so makes it visually compete with child allocation rows.
4. `Summary Card` is not a generic identity shell. Use it only for an actual compact summary; do not add data to fill a fixed specimen height.
5. Multi-row Info Row facts use a content-sized grouped information surface; Info Row itself remains transparent 338×44.
6. UI correction review order: canonical DS → Patterns/Templates → mature Product UI in other available Figma Themes → HTML. Cross-theme screens inform composition/rhythm but do not override DS semantics.
7. Migrated Product UI must pass 402×874 root geometry, clipping, internal/root overflow and sticky-footer reachability gates.

## Current v2.7.3 corrections

- BJ01/SCR-003: Product + `Khả dụng` → Status/Compact context; supporting quantities grouped separately.
- BJ02/SCR-084: actual selected-Product editor context → Status/Compact; Record Card width drift removed.
- BJ04: reviewed, unchanged.
- BJ05/SCR-025 + SCR-026: Navigation collection + Disabled state; SCR-027: compact Product context.
- BJ08: reviewed, unchanged.

## QA

- Cross-BJ UI hardening: PASS 24/24.
- BJ05 targeted QA: PASS 71/71.
- List Row audit: PASS, 32 rendered instances.
- Info Row audit: PASS, 264 rendered instances.
- BJ04 regression: PASS 34/34.
- BJ02 input/review regressions: PASS 20/20 and 18/18.
- All-flow runtime: PASS 85/85, 0 browser errors.

## v2.7.4 hard gate

- Live Figma nodes re-verified: Form Sheet `1353:6355`, VBottomSheet `4695:6353`, Confirmation Sheet `550:1058`, VNumericKeypadSheet `1829:16196`, VTextarea `522:7212`, VButton `521:529`, Icon Button `4431:10317`.
- Exact typography keeps Inter as the canonical first family and adds only non-serif runtime fallbacks; browser UA serif fallback is prohibited.
- Any HTML claiming a DS sheet/component must use the corresponding live Figma anatomy/state and canonical node mapping.

## v2.8.0 — BJ05 sheet correction + BJ06 structural migration

- Product wiring: **UIF-01, UIF-02, UIF-04, UIF-05, UIF-06, UIF-08**.
- BJ05 lot replacement uses canonical `VBottomSheet 4695:6353`: no X, content-driven height, canonical handle/edge/safe-area, no inherited flex dead space.
- BJ06 SCR-030…035 is structurally migrated to live Figma DS composition with no new feature component.
- Product viewport remains exact **402×874**. Desktop workbench scales only the review preview, preserving aspect ratio and Product CSS pixels.
- Review fit is bounded by both available desktop height and width; the document itself must not scroll merely to show the phone.
- Business behavior changed: **no**.

## v2.8.1 — shared review-device frame correction

- Product canvas remains canonical `402×874`.
- Decorative phone bezel is `8px` outside Product canvas; review device border-box is `418×890`.
- Fixes v2.8.0 clipping that reduced the device content-box to `386×858`, visually removing the right/bottom Product edge.
- All 85 active screens are rechecked against the same shell geometry.
- No business behavior changes.

## v2.8.2 — BJ05/BJ06 UX and navigation correction

- BJ05 SCR-027: multi-LOT overview is now a canonical Navigation List Row collection; per-LOT quantity edit is contextual in VBottomSheet. The page no longer stacks a full form for every LOT.
- BJ06 maker navigation is explicit, not derived from screen-catalog order: `032→031`, `031→030`, `033→030`. Approver `SCR-034` remains a separate actor-handoff route.
- SCR-031/SCR-033 remove repeated request metadata groups in favor of compact Status List Row context.
- Product viewport and device-frame correction from v2.8.1 remain unchanged.
