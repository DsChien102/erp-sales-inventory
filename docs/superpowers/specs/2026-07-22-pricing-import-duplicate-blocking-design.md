# Pricing Import Duplicate Blocking Design

## Goal

Prevent an Excel import row from creating or updating a customer price rule when its effective period overlaps another active rule with the same tenant, customer, product, and product unit. The existing active rule must remain unchanged.

## Required behavior

- `DUPLICATE_ACTIVE_RULE` is a row error, not a warning.
- Preview marks the conflicting row as `error`, increments `errorRows`, and excludes it from importable rows.
- Users may continue a partial import when at least one other row is importable.
- Confirm revalidates each importable row under the existing rule-key advisory lock.
- A conflict discovered at confirm marks only that row as failed and continues processing the remaining rows.
- Import never auto-disables or overwrites a different active rule to resolve an overlap.
- An explicit update identified by `rule_id` excludes that same rule from overlap detection. It is blocked only when the updated interval overlaps another active rule.
- Warning acknowledgement remains applicable only to non-blocking warnings such as a defaulted effective date or below-floor policy warning.

## Data flow

1. Start import parses and resolves each row.
2. Import validation checks active closed-interval overlap, excluding the row's explicit update target.
3. A conflicting row receives `error_codes: ['DUPLICATE_ACTIVE_RULE']`, `warning_codes` retains only independent warnings, `row_status: 'error'`, and `action: 'skip'`.
4. Preview displays the row using the existing error tone and error-message formatter.
5. The user may continue if `validRows + warningRows > 0`.
6. Confirm re-evaluates each eligible row. A newly detected overlap becomes a failed row and processing continues.
7. Confirm creates or explicitly updates only non-conflicting rows and reports `completed_with_errors` when any row failed or was skipped.

## Scope

- Update the S8 API contract and US-05 scenario language.
- Change the import overlap SQL draft only; do not create or modify timestamped migrations.
- Align application fakes and ERP in-memory behavior with the authoritative contract.
- Preserve the current four-step UI; no new screen or confirmation dialog.
- Add regression tests for preview classification, partial confirm, confirm-time race recheck, explicit self-update, and preservation of the existing active rule.

## Out of scope

- Changing manual create, manual update, re-enable, or remembered-price overlap policies.
- Making the whole batch atomic when one row conflicts.
- Promoting or applying SQL migrations.
