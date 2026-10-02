# CHANGELOG v4.6.4 — BJ02 pending-approval continuity

Parent prototype: **v4.6.3**.

Scope is deliberately focused on **BJ02 — Nhận hàng mua** and the minimum Warehouse Hub candidate integration required to remove the dead-end after submission. Other BJ flows are not redesigned in this release.

## Changes

- `SCR-010 / PENDING_APPROVAL` now has one primary CTA: **Về Kho**.
- Back from `SCR-010 / PENDING_APPROVAL` also returns to Warehouse; it no longer returns to the editable receipt flow after the submitted revision is locked.
- Warehouse Hub candidate adds **Nhận hàng chờ phê duyệt** as the first row under **Cần chú ý**.
- The row opens a dedicated pending-approval worklist inside the Hub candidate.
- Pending receipt rows route an authorized reviewer into `SCR-011 — Phê duyệt yêu cầu nhận hàng`; the candidate assumes an Owner with full Warehouse permissions only for review-fixture purposes.
- Back from `SCR-011` returns to the pending-approval worklist when entered from Warehouse Hub.
- `SCR-010`, `SCR-011`, and `UIF-02` are updated to describe the continuity and permission-aware re-entry behavior.

## Non-goals

- No redesign of BJ05–BJ17.
- No new approval business rule.
- No automatic role switching after maker submission.
- No change to the existing current Warehouse Hub; the v4.6.4 change remains in the candidate comparison path.
