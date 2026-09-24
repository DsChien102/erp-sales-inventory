# Changelog — VET45 Theme 7 Prototype Harness v3.5.1

Parent: **v3.5.0**

## Purpose

v3.5.1 is a cumulative **UI/prototype correctness** release. It keeps the v3.5.0 business state machine and recovery logic intact while correcting list-surface rhythm, filter-chip behavior and auxiliary navigation defects that were still visible in the effective runtime.

## UI / Design System corrections

- **Independent List Row collections:** the collection/wrapper layer is transparent. Each independent List Row/card owns its own white surface; spacing between rows exposes the page/background surface instead of painting a continuous white parent behind the gaps.
- **Semantic grouped surfaces are preserved:** Product→facts and Product→LOT groupings that intentionally share one semantic boundary are not flattened by this correction.
- **VChip search/filter strips:** all supported mobile filter-strip classes stay on one row (`nowrap`) and scroll horizontally when their total width exceeds the canonical 370 px content width. Chips remain canonical, complete and non-truncated; the final chip can be brought fully into view.
- The v3.4 wrapping rule is superseded because it conflicts with the current locked mobile filter-strip behavior.

## Navigation corrections

- **BJ09 / SCR-056 history:** Back is explicitly routed to `SCR-037`, the detail screen that launched history. It no longer relies on flow-array order, so it cannot incorrectly return to the change-result screen.
- **BJ15 movement/source drill-down:** movement detail Back returns to `SCR-055`; source evidence Back returns to `SCR-056`. These auxiliary routes preserve parent context and do not mutate business state/finality.
- A permanent DS/prototype rule is added: auxiliary history/source/evidence drill-down screens must use explicit launching-parent navigation whenever generic previous-screen order could be ambiguous.

## Cross-screen regression prevention

- The transparent independent-list rule is applied to Audit & Control list wrappers and compatible legacy list wrappers reached by cumulative renderers.
- Runtime QA traverses all **500 declared states** and checks independent-list wrapper surfaces, chip-row behavior, hidden-row behavior, List Row overlap/clipping and browser errors.
- BJ09 and analogous BJ15 drill-down Back paths are exercised as real click/navigation sequences.

## Validation model

Current release gates:

- `STATIC-CONSISTENCY-QA-v3.5.1.*`
- `FLOW-LOGIC-E2E-QA-v3.5.1.*`
- `RUNTIME-UI-QA-v3.5.1.*`

No new core Figma DS component or Theme-specific pattern is introduced. Backend database/outbox/network atomicity remains outside the HTML harness.
