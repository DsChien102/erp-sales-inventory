# Release Validation — v2.6.0

**Result: PASS · 26/26 release checks**

## Scope

BJ04/UIF-04 structural Figma DS migration only. Parent v2.5.5 behavior and prior migrated UIF-01/UIF-02/UIF-08 are retained.

## Checks

- [x] Root README identifies v2.6.0 / parent v2.5.5.
- [x] Workbench version is 2.6.0.
- [x] `v260-bj04-ds-fidelity.css` is wired after prior cumulative correction layers.
- [x] UIF-04 remains one active Product screen: SCR-021.
- [x] SCR-021 remains contextual-only from the source sales order.
- [x] Reservation lifecycle mutation remains source/system-driven.
- [x] No reserve/release/reallocation mutation CTA or Footer Action is rendered.
- [x] AppBar retains Back + order context and no trailing action.
- [x] Visible Product UI removes redundant `Chỉ xem` / entry-explanation noise.
- [x] Order context uses canonical `DS v2 / Info Row`.
- [x] Product projection uses non-interactive `DS v2 / List Row · Type=Status`.
- [x] Shortage uses `VBadge Warning` only on affected rows.
- [x] FULL has no success banner/badge noise.
- [x] PARTIAL/SHORT does not aggregate shortage quantity across UOMs.
- [x] RELEASED is not rendered as shortage.
- [x] STALE has no technical retry action.
- [x] State feedback uses compact canonical `VBanner` and fits its 72px density gate.
- [x] LOADING uses `VSkeleton`.
- [x] PERMISSION_DENIED uses `VEmptyState`.
- [x] Canonical mobile canvas is 402×874.
- [x] SCR-021 has no horizontal overflow.
- [x] No raw hex/rgb color was introduced in UIF-04 fidelity CSS.
- [x] No new Theme 7 reusable component was introduced.
- [x] BJ04 Figma DS/Product QA — PASS 34/34.
- [x] All-flow runtime smoke — PASS 85/85 with 0 browser errors.
- [x] `action-registry.json` and `screen-registry.json` hashes remain identical to v2.5.5.

## QA evidence

- `specs/themes/theme-07/prototype/html/qa/BJ04-FIGMA-DS-QA-v2.6.0.md`
- `specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v2.6.0.md`
- `specs/themes/theme-07/prototype/html/qa/BJ04-VISUAL-QA-v2.6.0.md`
- `specs/themes/theme-07/prototype/html/qa/v260-bj04-captures/`
