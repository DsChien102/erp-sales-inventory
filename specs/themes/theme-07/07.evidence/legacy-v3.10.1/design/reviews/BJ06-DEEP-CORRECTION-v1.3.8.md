# BJ06 Deep Correction Review — v1.3.8

## Purpose

Correct BJ06 from business source through UI contracts and HTML after the v1.3.7 review exposed state-scope, physical-verification, approval-finality and QA gaps.

## Decisions resolved in this release

### Multi-LOT return trace

For LOT-tracked return inventory, the canonical physical-verification line is:

`Product + UOM + source LOT allocation`

The same Product/UOM delivered from multiple LOTs may therefore appear as multiple return lines. This preserves source trace without forcing the user to infer allocation history inside a single free-text LOT field. Combo returns are decomposed into component lines with combo context; the request remains all-or-nothing at receipt commit.

### Multiple wrong-LOT exceptions

One wrong-LOT return line creates one approval case. A maker may prepare multiple exception lines in one request and submit them together, but each case has its own immutable decision snapshot and `approval_case_id`. The maker request stays read-only while any case is pending. Changing quantity/LOT/reason/evidence invalidates the prior decision for that line.

## Corrected end-user architecture

1. `SCR-030` — queue defaults to `Tất cả`; actionable/waiting are user-selected filters.
2. `SCR-031` — request overview; source data is evidence only; physical verification progress is explicit.
3. `SCR-032` — verify one return line. Normal source LOT is a direct choice; `Lô khác` opens exception evidence.
4. `SCR-034` — separate approver task context, exact case selection, viewable evidence, final decision.
5. `SCR-035` — receipt result; user may classify immediately or defer.
6. `SCR-033` — classification overview + contextual draft editor.
7. `SCR-035` — final classification result; completed request leaves active queue.

## Major regressions eliminated

- No source quantity/LOT prefilled as if the user had physically verified it.
- No global “first pending exception” lookup for approval.
- No reuse of an approved exception after snapshot fields change.
- No repeat Approve/Reject after final decision.
- Reject textarea is tested with real click/focus/type interaction.
- `REJECTED_EXECUTION`, `PERMISSION_DENIED` and `UNKNOWN` do not collapse to success.
- No Back from result into a consumed receipt/classification commit screen.
- Classification does not start pre-completed and provides a safe `Hủy` path.
- Mixed UOM quantities are not summed into a false business total.
- Permission denial on request detail masks protected business data.
- Cap/source changes block commit and require refresh/review.
- Screen/action/UIF registries now map receipt, classification and approval to the correct surfaces.

## QA evidence

- BJ06 end-user/state: 65/65 PASS.
- BJ06 static/contract: 56/56 PASS.
- All-flow runtime: 87 renders PASS.
- BJ05 protected regression: 48/48 end-user + 40/40 static PASS.
- Visual review: 12 focused specimens PASS at 402×874.

This review does not mean Product has frozen BJ06; it means the known v1.3.7 review findings are addressed consistently across source, contract and prototype for the next Product review.
