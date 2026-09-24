# Release validation — v3.5.1

Parent: **v3.5.0**

## Release decision

**PASS — review ready for Theme 7 browser prototype.**

This release preserves the v3.5.0 business state machine and corrects the remaining UI/prototype defects surfaced by the BJ09 review. The release specifically distinguishes **independent List Row collections** from semantic grouped Product→facts/LOT surfaces, locks mobile `VChip` filters to one horizontally scrollable row, and removes ambiguous generic-previous navigation from auxiliary history/source drill-downs.

## Current release gates

### 1. Static consistency

`specs/themes/theme-07/prototype/html/qa/STATIC-CONSISTENCY-QA-v3.5.1.json`

- **25/25 PASS**.
- 17 Business Journey flows and **85 canonical flow-screen routes**.
- Screen Registry, Workbench and runtime-state registry remain synchronized.
- Effective runtime registry covers **500 declared route-states**.
- v3.5.1 CSS/JS correction layers load after v3.5.0.
- DS conformance permanently locks the transparent independent-list layer, one-row horizontal VChip strip, and explicit launching-parent Back rule.

### 2. Semantic flow / logic E2E

`specs/themes/theme-07/prototype/html/qa/FLOW-LOGIC-E2E-QA-v3.5.1.json`

- **21/21 PASS** against the effective v3.5.1 runtime.
- The complete v3.5.0 logic/recovery correction set is retained: stale-source guards, blind count/branching, maker/approver boundaries, bound mutation inputs, UNKNOWN→BJ17 recovery, control-total validation, costing successor lineage, report scoping, reconciliation/finality evidence checks and canonical entry routing.
- Navigation/read-only actions still do not create business finality.

### 3. Effective runtime UI

`specs/themes/theme-07/prototype/html/qa/RUNTIME-UI-QA-v3.5.1.json`

- **14/14 PASS**.
- **500/500 declared-state renders** on the canonical 402×874 Product viewport.
- **272/272 Audit & Control states**.
- 85 canonical flow-screen routes represented.
- All multi-chip search/filter sets stay **one row**, use horizontal scrolling, keep chip labels intact, and allow the final chip to become fully visible.
- Independent list containers with multiple independent rows have a **transparent parent surface**; white does not bleed into spacing between cards/rows.
- Hidden rows remain actually hidden.
- No forbidden redundant list headings or technical copy leakage covered by the gate.
- No List Row copy/trailing overlap or visible non-ellipsis text clipping.
- **BJ09:** detail → history → Back returns to the same detail context, not the result screen, and preserves result/selection state.
- **BJ15:** result → movement → source → Back → movement → Back → result preserves the auxiliary drill-down hierarchy.
- **0 browser page errors**.

> The old v3.5.0 chip assertion that favored all chips being visible in the initial viewport is intentionally superseded. The locked requirement in v3.5.1 is one-row horizontal scrolling with full reachability of the last chip.

## Cross-screen/UI review

The v3.5.1 correction is applied globally to the supported cumulative list/filter classes rather than only to the BJ09 screenshot:

- Audit & Control independent list surfaces (`ac310-list-surface` / `ac310-list-stack`).
- Compatible legacy independent-list wrappers reached by cumulative Operations/Valuation renderers.
- `ds24-chip-scroll`, `io06-chip-scroll`, `io07-chip-scroll`, `bj05-chip-scroll`, and `ac321-chip-wrap` filter strips.
- Semantic grouped Product→facts/LOT surfaces are intentionally excluded from the transparent-wrapper rule where the shared boundary carries real hierarchy.

Visual captures were regenerated from the effective runtime:

- `specs/themes/theme-07/prototype/html/qa/v351-visual-captures/V351-OPERATIONS-CONTACT-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/v351-visual-captures/V351-VALUATION-CONTACT-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/v351-visual-captures/V351-AUDIT-CONTROL-CONTACT-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/v351-visual-captures/V351-LIST-CHIP-NAV-CONTACT-SHEET.png`

The focused contact sheet was manually reviewed: list gaps show the subtle page surface, BJ09 chips remain in one horizontal strip, and the corrected list/card rhythm is consistent on representative Operations, Audit/Control and reporting screens.

## Compatibility regressions

- All-flow smoke: **85/85 renders**, 0 failures, 0 browser errors.
- Device-frame regression: **7/7 PASS across 85 screens**.
- Prior-BJ regression: **23/23 PASS**.
- Valuation integration: **14/14 PASS**.
- Desktop review-workbench fit: **3/3 PASS**.
- `node --check`: `app.js`, `v350-flow-logic-correction.js`, and `v351-list-chip-navigation-correction.js` PASS.

## Scope boundary

This release validates the **browser prototype** and its represented UI/flow/state behavior. It does not claim production backend guarantees for database transactions, persistence, concurrency, outbox delivery, idempotency across network failures or crash/restart atomicity; those require backend/integration QA.
