# Changelog — VET45 Theme 7 Prototype Harness v3.5.0

Parent: **v3.4.0**

## Purpose

v3.5.0 is the cumulative **flow / logic / recovery correction** release produced after the full 17-BJ holistic QA. It fixes the semantic defects that could not be detected by state-render coverage alone while preserving the Figma-DS visual baseline from v3.4.0.

## Flow and business-logic corrections

- **BJ01 / BJ06 / BJ07 search:** hidden List Rows are now actually removed from layout after the DS List Row migration; search no longer leaves visually present rows behind.
- **BJ02:** the Quick-receipt behavior is made canonical and unambiguous: selecting Product + valid UOM creates/opens the line and goes directly to `SCR-084`; the stale "add pending then tap again" variant is removed from the flow source.
- **BJ05:** handover revalidates the source version captured at review. A stale source blocks commit with `SOURCE_CHANGED`.
- **BJ06:** the normal-return path now uses the same source-snapshot protection as the wrong-LOT exception path. A source change blocks receipt.
- **BJ08:** blind count starts empty; book quantity and variance stay hidden until first submission. Exact count goes directly to independent approval; only discrepant lines go to recount. Maker/approver boundary is executable, list search/filter is functional, and read-only result navigation never creates finality.
- **BJ09:** state-change reason is bound to the request, validated, preserved into approver review, and the approved transition mutates the selected inventory state rather than a hard-coded fixture.
- **BJ10:** requested quantity, reason and evidence are bound to the request. Approval uses the requested quantity. Physical completion is a separate actor boundary; actual quantity is validated against approved quantity and the terminal result reflects actual completion rather than a fixture value.
- **BJ11:** `Xem kết quả` is navigation only; it no longer mutates a pending result into `COMPLETED`.
- **BJ12:** independent control totals are validated before continuing. Approval revalidates the reviewed source/control snapshot before activation.
- **BJ13:** existing preview-hash/source-version protection remains the reference behavior and is covered by the new semantic E2E gate.
- **BJ14:** successor runs now supersede the actual dirty run, preserving its locked costing method/policy rather than falling back to another method.
- **BJ15:** Product and date-range filters now constrain the movement dataset and export scope. Export context and exported rows therefore describe the same scope.
- **BJ16:** correction handoff preserves the current case/Product/LOT context, source-owner routes no longer dead-end, mismatch review can return to investigation, and evidence version is revalidated before recovery/closure.
- **BJ17:** UNKNOWN resolution preserves the same operation identity, verifies evidence freshness, does not create a duplicate inventory operation, and records finality from the existing operation only.

## UNKNOWN / recovery architecture

- UNKNOWN result screens across the inventory journeys now have an executable handoff to BJ17 rather than a toast/no-op/back-to-retry path.
- Source work is locked while its finality is unresolved so the originating task cannot reappear as a normal retry candidate.
- BJ17 keeps the original operation identity and separates committed / no-effect / insufficient-evidence outcomes.

## Entry and actor boundaries

- Canonical entry routing is executable for assigned counter, approver, disposal completion operator and dirty costing scope.
- Maker, approver and completion-operator responsibilities are represented as separate runtime contexts for the corrected flows.
- Read-only/navigation actions cannot create business finality.

## UI / Design System

- No new core Figma DS component or Theme-specific component family is introduced.
- v3.4.0 composition rules remain in force: one semantic group = one boundary; no product/task card-on-card; semantic spacing separates groups.
- `[hidden]` is made authoritative inside the Product viewport to prevent the List Row migration from defeating search filtering.
- Dense canonical `VChip` collections remain fully visible; partial clipping is blocked.
- User-facing technical enum/version vocabulary remains blocked by runtime QA.

## Validation model

State-render coverage and transition correctness are now reported separately:

- **Static consistency:** `STATIC-CONSISTENCY-QA-v3.5.0.*`
- **Semantic flow/logic E2E:** `FLOW-LOGIC-E2E-QA-v3.5.0.*`
- **Effective runtime UI:** `RUNTIME-UI-QA-v3.5.0.*`

Browser QA validates the prototype state machine represented by the harness. Production database transaction, concurrency, persistence, outbox and network atomicity remain integration/backend responsibilities.
