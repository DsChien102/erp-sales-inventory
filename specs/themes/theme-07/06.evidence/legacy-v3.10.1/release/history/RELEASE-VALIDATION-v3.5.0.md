# Release validation — v3.5.0

Parent: **v3.4.0**

## Release decision

**PASS — browser prototype release candidate for Theme 7 flow / logic / UI review.**

The post-v3.4.0 holistic QA findings have been corrected and re-tested in the effective runtime. The current release deliberately separates **declared-state rendering** from **business-transition correctness** so a large render count can no longer be interpreted as proof that the state machine is correct.

## Current release gates

### 1. Static consistency

`specs/themes/theme-07/prototype/html/qa/STATIC-CONSISTENCY-QA-v3.5.0.json`

- **13/13 PASS**
- 17 Business Journey flows.
- 85 canonical flow-screen routes.
- Every active screen has a screen contract and every active flow has a flow document.
- Screen Registry, Workbench and runtime-state registry are synchronized for names and states.
- Effective runtime-state registry covers **500 declared route-states**.
- Newly reachable v3.5 states are declared rather than existing only inside imperative handlers.
- BJ02 Quick behavior is unambiguous in the flow source.

### 2. Semantic flow / logic E2E

`specs/themes/theme-07/prototype/html/qa/FLOW-LOGIC-E2E-QA-v3.5.0.json`

- **21/21 PASS**
- Search rows remain genuinely hidden after DS migration.
- BJ03 source-version review guard.
- BJ04 read-only reservation projection.
- BJ07 stale-source handover guard.
- BJ13 preview-hash and source-version guard.
- BJ08 blind count, conditional branching, actor boundary and finality.
- BJ08 list search/filter behavior.
- BJ09 bound reason + state mutation.
- BJ10 bound request → approval → physical completion.
- BJ05 stale-source commit guard.
- BJ06 normal-return stale-source guard.
- UNKNOWN → BJ17 recovery and no blind retry.
- BJ12 control totals + stale approval protection.
- BJ14 successor lineage + costing-method lock.
- BJ15 Product/date/export scoping.
- BJ16 correction-context integrity, no dead end, evidence freshness.
- BJ17 same-operation finality + evidence freshness.
- Canonical entry routing / actor contexts.
- Navigation/read-only actions do not create finality.

### 3. Effective runtime UI

`specs/themes/theme-07/prototype/html/qa/RUNTIME-UI-QA-v3.5.0.json`

- **15/15 PASS**
- **500/500 declared-state renders** on the canonical Product viewport.
- **272/272 Audit & Control state renders**.
- 85 canonical flow-screen routes represented.
- Canonical Product root **402×874** and review bezel **418×890**.
- **0 browser page errors**.
- No root/content horizontal overflow.
- No partially clipped canonical `VChip`.
- `[hidden]` rows are actually hidden.
- No forbidden redundant list headings (`Công việc`, `Phiên đang thực hiện`).
- No user-facing technical English/enums/raw revision leakage covered by the terminology gate.
- No `undefined`, `[object Object]` or `null` copy leakage.
- No List Row copy/trailing-action overlap.
- No visible non-ellipsis text clipping.
- Visible text actions meet the minimum 40px height gate.
- Visible icon-only actions have accessible labels.
- Corrected Product/task screens have no card-on-card nesting.
- Representative controls remain inside the device viewport.

## Visual QA

Visual contact sheets were regenerated from the effective v3.5 runtime and manually reviewed:

- `V350-OPERATIONS-CONTACT-SHEET.png`
- `V350-VALUATION-CONTACT-SHEET.png`
- `V350-AUDIT-CONTROL-CONTACT-SHEET.png`
- `V350-KEY-CORRECTIONS-CONTACT-SHEET.png`

The reviewed key corrections include BJ07 Product→LOT hierarchy, BJ08 blind count/recount/approval, BJ10 disposal request, BJ12 opening-balance controls, BJ15 scoped report, BJ16 reconciliation/recovery, and BJ17 finality review.

## Compatibility spot checks

The cumulative harness was also spot-checked against mature regression utilities already present in the package:

- All-flow smoke: **85 renders / 0 failures / 0 browser errors**.
- Prior-BJ regression: **23/23 PASS / 0 browser errors**.
- Valuation integration regression: **14/14 PASS**.
- Device-frame regression: **7/7 PASS across 85 screens / 0 browser errors**.
- Desktop review-workbench fit: **3/3 PASS**.

Historical QA scripts whose assertions intentionally lock an older release number, old state count, or superseded composition rule are retained as historical evidence and are not current v3.5 release gates.

## Scope boundary

This release validates the **browser prototype**: UI, local state transitions, guards, actor/context handoff, recovery behavior and represented finality rules. It does **not** claim production backend guarantees for database transactions, concurrency, persistence, outbox delivery, idempotency across network failures, or crash/restart atomicity. Those require backend/integration QA.
