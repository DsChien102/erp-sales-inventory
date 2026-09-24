# BJ08 / UIF-08 Migration Contract — v2.3.0

## Scope

`SCR-042` through `SCR-047` are structurally migrated in the v2.x prototype layer. Frozen Theme 7 v4.3.1 screen/action IDs remain stable; this contract supersedes stale Product-visibility/placement assumptions for BJ08 without changing the base registry counts.

## Screen mapping

| Screen | Product responsibility | Canonical UI mapping |
|---|---|---|
| SCR-042 | Find/create/resume count session | Mobile / Nested List + List/Search/State patterns |
| SCR-043 | Define immutable count scope and open session | Mobile / Form + VSelect + Search & Select + VDatePicker + temporary time field + VTextarea + Sticky Footer + Confirmation Sheet |
| SCR-044 | Blind first physical count | Mobile / Form + grouped rows + VNumericKeypadSheet + Sticky Footer |
| SCR-045 | Recount only discrepancy lines and collect evidence | Mobile / Form + Info Rows + VNumericKeypadSheet + VTextarea + State feedback + cancellation Confirmation Sheet |
| SCR-046 | Independent approval decision | Mobile / Detail + read-only rows + persistent dual actions + Confirmation Sheet |
| SCR-047 | Terminal/business result | Mobile / Detail + State patterns; no mutation action |

## Business corrections applied in the Product layer

### P01 — request review
The prior UIF rendered a reject action as a terminal rejected result. BJ/BC behavior instead supports an approver decision that returns the session to recount/review while keeping operation identity and lock as policy requires.

v2.3.0 therefore renders `Yêu cầu xem lại` on SCR-046 and routes back to SCR-045. The existing stable `ACT-09-APPROVE / BC-IC-03 / API-C-16` trace is retained as the decision mutation contract. **No backend enum value is invented in this prototype.** Runtime should consume the authoritative allowed decision value from the service contract.

### P02 — no mutation on result
SCR-047 is terminal/result-only. The stale core trace that associates `ACT-09-APPROVE` with SCR-047 is not rendered by v2.3.0.

### P03 — count reason
`BC-IC-01` requires count reason. SCR-043 includes it. The frozen entity model does not yet make persistence ownership explicit; this is recorded as a source-model backport recommendation rather than silently invented.

### P04 — assigned counter
The actor is assigned/authorized by business contract, but the frozen entity does not define a Product-editable assignment model. SCR-043 presents assigned counter as read-only context; it does not invent a user picker.

### P05 — unexpected physical item inside scope
Blind count supports `Thêm hàng thực tế`. It adds an `is_unexpected_key` physical line inside the locked scope and never quick-creates Product master data.

### P06 — recount input
SCR-045 shows book / first count / variance only after first submit and provides a separate editable recount value.

### P07 — evidence / price basis
Evidence is collected when required. Where a price-basis schema is not authoritatively defined, the UI states that the basis is missing and blocks submit; it does not invent a dropdown taxonomy, document type, or price source.

### P08/P09 — cancellation and terminal cancelled result
Cancellation is a session action using `ACT-09-CANCEL / BC-IC-08 / API-C-27`, requires reason, creates no adjustment and releases the lock. It is available from the session context and blocked-evidence recount state; it is intentionally absent from the approval task. SCR-047 includes `CANCELLED`.

### P10 — financial masking
Financial risk is protected data. When unauthorized, the service must omit/mask it before Product rendering; SCR-046 permission/no-financial contexts must not put the real value into DOM and hide it cosmetically.

## Blind-count invariant

Before the first submit, SCR-044 must not render book quantity, variance, a proxy derived from book quantity, or hidden/accessibility-only book values. The QA suite checks the rendered DOM for this invariant.

## DS-specific rules for BJ08

- 402 × 874 Product canvas; 16 px edge; 370 px content width.
- No fixed 421.33 px field specimen width in Product screens.
- No generic `VCard` dependency in BJ08; use structural grouping (`VSection`) and canonical rows.
- Quantity/recount Product UI does not use `VNumberField` or `VQuantitySelector`; opening a quantity value uses `VNumericKeypadSheet`.
- canonical bottom sheet top radius = 16 px.
- Confirmation interactions use `DS v2 / Confirmation Sheet`, not a naked generic `VBottomSheet`.
- `VTimePicker` remains an explicit DS gap. The temporary time field is marked `data-ds-gap="VTimePicker"`.
