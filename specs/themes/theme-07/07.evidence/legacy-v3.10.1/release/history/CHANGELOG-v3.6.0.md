# Changelog — Theme 7 Prototype Harness v3.6.0

Parent: **v3.5.1**  
Date: **2026-09-15**

## Full Theme 7 coverage

- Expands the executable browser prototype from 17 Business Journeys to **17 BJ + CAP-01 supporting policy capability**.
- Renders `SCR-062..065`: stock policy, near-expiry policy, policy review, and update result.
- Current scope: **89 canonical route occurrences**, **77 active unique screens**, **518 declared route-state renders**.
- Keeps `BG-006` explicit: exact production entry/permission/return integration for CAP-01 remains an integration boundary rather than an invented Product-UI rule.

## Flow / logic correction

- **BJ08:** `Hủy phiên` is removed from the browse-list contract and is available only inside an opened active count/recount session; cancellation requires a reason and ends in `CANCELLED`.
- Locks stable-screen continuity: every stable non-root state has an executable continuation/exit.
- Locks explicit auxiliary Back parents; navigation/read-only actions do not create business finality.
- Keeps UNKNOWN recovery same-operation semantics and blocks blind retry.
- Fixes/locks representative-state prerequisites for BJ02, BJ03, BJ07, BJ13 and BJ14.
- Direct terminal representative fixtures are coherent for receiving, valuation and disposal results.

## UX / feedback

- Adds semantic toast feedback for same-context or worklist-return mutations where the outcome would otherwise be easy to miss: inventory refresh, receipt-line save, lot override, return-line save, classification save, RTV allocation confirmation, item-state request, disposal request, correction request and opening-balance approval submission.
- Does **not** add redundant success toasts to dedicated result screens, pure navigation, inline validation, blockers or UNKNOWN recovery.
- Reduces informational-banner noise; normal context uses lighter information treatment while warnings/errors/blockers preserve semantic banners.
- Preserves the v3.5.1 one-row horizontally scrollable `VChip` rule and transparent independent-list wrapper rule.
- Fixes BJ08 confirmation-sheet layering so the underlying destructive footer cannot bleed through the safe-area.

## Authority / design-system clarification

- **Theme 7 screen design & executable UX:** HTML prototype/harness.
- **Business behavior:** BJ / UC / Decision / Flow / Contract artifacts.
- **Figma:** current VET45 Design System plus reference to mature prior-theme designs only; Figma is not the Theme 7 screen-design source.
- No new Theme-specific core DS component is introduced in v3.6.0.

## QA / governance

- Modernizes the current package validator and design-readiness validator for the v3.6.0 runtime baseline while preserving historical v4.3.1/static evidence separately.
- Synchronizes Workbench, Screen Registry, runtime-state registry, flow registry and current validation reports.
- Adds release-blocking representative-state coherence and full-theme completion gates.
- Final current gates pass: static **30/30**, semantic E2E **21/21**, full-theme completion **14/14**, representative coherence **8/8**, runtime UI **14/14**, all-flow smoke **89/89**, device frame **7/7**, package validation **32/32**, prior-BJ regression **23/23**, valuation integration **14/14**, BJ05/BJ06 UX **32/32**, review fit **3/3**, with **0 browser page errors**.

## Evidence boundary

This release validates the browser prototype and the UI/flow/state behavior represented by the harness. It does not prove production backend transaction, persistence, concurrency, database, outbox, network or crash/restart atomicity; those remain backend/integration QA scope.
