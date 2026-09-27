# BJ03 / UIF03 — Deep Product Correction Review v1.4.0

## Product verdict

BJ03 keeps the existing five-screen business architecture and deep-corrects the user mental model for initial receipt valuation. No new business rule was required: the current BJ03/UC03/BC-IV-01 source already defines identified partial scope, source conflict resolution, direct-cost composition, FX provenance, valuation/sellability separation, atomic confirmation and UNKNOWN handling.

Active Product path:

`SCR-014 → SCR-015 → SCR-016 → SCR-017 → SCR-019`

## Source rules implemented

1. **Valuation is not sellability.** Confirming value does not make quarantine/damaged/expired stock sellable; only currently eligible physical state becomes available.
2. **Partial scope is explicit.** A user confirms a receipt line or identified quantity part; the remainder stays pending.
3. **Authoritative evidence is not retyped.** PO/receipt/supplier-confirmed price, tax and FX provenance are read-only system facts.
4. **Conflict is a decision, not a default.** When valid sources disagree, no source is preselected; an authorized actor selects the source and records a reason.
5. **Direct cost is derived.** Source price, line/document discounts, known purchase cost, non-deductible tax and approved FX feed the displayed unit cost. Deductible VAT is not added.
6. **Late cost stays separate.** Evidence arriving later is BJ13, not an estimated field in BJ03.
7. **One commit.** `SCR-017` owns `ACT-03-CONFIRM-COST`; there is no second approval or repeat confirmation modal.
8. **Finality is safe.** `SCR-019` distinguishes completed/rejected/unknown/permission outcomes and never navigates Back into a consumed commit.

## Product corrections by screen

### SCR-014 — Chờ xác nhận giá trị
- Receipt task summary, not a generic financial record list.
- Search and three end-user filters.
- Summary uses number of items/parts; it does not add quantities with different UOM.
- Missing-evidence receipts remain visible but are clearly distinguished.

### SCR-015 — Chọn phạm vi xác nhận
- Product+UOM is the user grouping object.
- Physical-state parts remain distinct inside each group.
- Quantity input means **scope to value now**, not a correction to received quantity.
- Missing-evidence parts are disabled; eligible parts in the same receipt can continue.
- Draft selection remains recoverable through normal navigation.

### SCR-016 — Xác định giá nhập
- Provenance-first read-only source facts.
- Source conflict shows both candidates, no preselection, required reason after selection.
- Original foreign-currency amount and accounting FX provenance are shown separately.
- Derived cost breakdown explains discount/cost/tax effects without turning authoritative data into user inputs.
- Late purchase cost is explained as a separate BJ13 task rather than estimated here.

### SCR-017 — Rà soát xác nhận giá
- One irreversible direct-valuation CTA.
- Quantity evidence remains per Product+UOM; only monetary VND total is aggregated.
- Availability impact is separated from value impact.
- Source/version is rechecked before mutation.
- When source changes, the review is blocked, the affected before→after source delta is shown, and unaffected source/reason draft evidence remains intact.

### SCR-019 — Kết quả
- COMPLETED reports exact committed scope and availability impact.
- Partial completion can continue the remaining pending scope.
- REJECTED_EXECUTION has zero mutation and returns to provenance reconciliation.
- UNKNOWN stays non-success, does not expose technical operation identity, and does not blind retry.
- No result state navigates Back to the consumed commit surface.

## Shared UIF13 boundary

`SCR-014/015/017/019` are shared screen identities, but v1.4.0 deliberately corrects **UIF03 only**. The custom renderer immediately falls back to the inherited generic renderer when `activeFlowId !== UIF-03`. Runtime comparison confirms all five UIF13 READY screens remain text-identical to v1.3.9. This is an isolation guarantee, not a Product-approval claim for UIF13; UIF13 remains the target of the next deep-design release.

## Release gate

Product freeze requires: end-user interaction/state QA, static/contract conformance, all-flow runtime smoke, protected BJ05/BJ06/BJ07 regression, UIF13 parent-equivalence regression, 402×874 visual review and file-level isolation against v1.3.9.
