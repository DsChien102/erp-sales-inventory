# Changelog — VET45 Theme 7 Prototype Harness v3.10.1

**Parent:** v3.10.0  
**Scope:** Wave 4 — BJ09 Quản lý tình trạng hàng — Deep-Dive Semantic Traceability hardening.

## Authority / baseline

- v3.10.0 is the single direct cumulative parent.
- Frozen source is preserved byte-for-byte against the direct parent.
- BJ01, Wave 2, Wave 3 and BJ08 locks remain protected by regression.
- v3.10.1 hardens BJ09 only plus one shared AppBar accessibility correction discovered by fresh-eye QA.

## Approved BJ09 decisions implemented

1. Canonical business state for sample/demo stock is `DEMO`; UI label is **Dùng thử**. `TRIAL` is retired from active contract/runtime.
2. Transition rules are owned by immutable, versioned `StateTransitionPolicyVersion` rather than hard-coded UI lists.
3. Partial state change is user-entered quantity, while the server resolves the exact source balance/valuation slices. Ambiguity blocks the operation.
4. `STATE_TRANSFER` preserves each source slice's valuation state and authoritative book value; it creates no inventory value movement.
5. `EXPIRED` is system-derived from LOT expiry + tenant business date and is not a user-selectable destination.
6. When eligibility decreases, state balances and reservation capacity/reconciliation commit atomically; active PickAllocation is not silently rewritten.
7. Maker submit freezes immutable `StateChangeBasis`; ApprovalCase binds the exact basis hash. Approver records only a decision. System execution rechecks the basis immediately before commit.

## Data / behavior / technical changes

- Added `ENT-IC-10 StateTransitionPolicyVersion` and `ENT-IC-11 StateChangeBasis`.
- `InventoryMovement` now stores `valuation_state_snapshot` for state-transfer evidence.
- Hardened `BC-IO-10`, `BC-IC-06`, `BC-IC-07` and `API-C-10` around basis, policy, source-slice, approval and reservation finality.
- Added explicit errors for ambiguous source slices, stale basis/policy and approval-basis mismatch.
- `EVT-IO-08` carries state-change basis/policy/source/reservation lineage.

## UI / prototype changes

- Current state (`Từ`) is authoritative read-only; destination (`Sang`) is policy-derived.
- User never chooses valuation state or source balance slice.
- Maker and approver are separate tasks; maker sees a submitted/pending result rather than an in-session actor switch.
- `ACT-08-STATE` is `TRACE_ONLY_SYSTEM`; no direct state-mutation CTA is rendered.
- Approval view shows business evidence needed for the decision without balance IDs, policy hashes or valuation jargon.
- Reject reason is mandatory and correctly enables the confirmation action after input.
- Expired LOT presentation has no manual “mark expired” action.
- Result separates physical impact, book-value impact and reservation reallocation impact.
- Shared `VAppBar` back target was corrected to an actual 44×44 touch target; full Theme regression confirms no header regression.

## QA

- BJ09 Deep Review: **127/127 PASS**.
- BJ09 Fresh-eye: **31/31 PASS**, 10 focused captures.
- Prior locked regression including BJ08: **37/37 PASS**.
- Wave 3 Cross-BJ audit regression: **35/35 PASS**.
- Frozen source: **108/108 byte-identical to direct parent v3.10.0**.
- Current package validation: **66/66 PASS**.
- Full Theme end-user regression: **19/19 PASS**.
- Flow & Logic E2E: **26/26 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 browser errors.
- Runtime UI: **14/14 PASS**, 514 declared state renders / 89 canonical routes.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 routes/screens checked.
- Structural package: **10/10 PASS** before final release closure; rerun after release metadata generation.
