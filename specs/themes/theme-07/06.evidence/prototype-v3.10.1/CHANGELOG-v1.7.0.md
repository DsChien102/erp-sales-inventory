# CHANGELOG — Theme 7 Prototype Harness v1.7.0

Parent: **v1.6.0**  
Scope: **Correction & Recovery — BJ11/UIF11 + BJ16/UIF16 + BJ17/UIF17**

## BJ11 — Hủy và sửa sai nghiệp vụ kho

- Reworked flow from business finality, not old screen sequence.
- Cancel is limited to unexecuted states and has zero inventory/value effect.
- Completed operation remains immutable; correction creates a successor chain.
- Correction editor has one authoritative `Số đúng` input; delta is derived.
- Removed visible Save Draft; background save remains trace-only.
- Maker submit terminates at `Chờ duyệt`; approver is a separate assigned task.
- Approve triggers system recheck + correction automatically; no second user commit.
- UNKNOWN hands off to BJ17 with the same operation identity.
- Physically handed-over sale issue cannot be “returned” through correction.

## BJ16 — Điều tra & đối soát sai lệch

- Evidence-first classification: source mismatch, UNKNOWN, projection mismatch, correction required, ledger-integrity suspicion, or no real discrepancy.
- Projection recovery is offered only after ledger correctness is evidenced.
- Raw technical action selection was removed from Product UI.
- Ledger-integrity suspicion escalates and blocks auto rebuild/correction.
- Review compares business facts and closes/unlocks only when evidence is sufficient.

## BJ17 — UNKNOWN finality recovery

- `UNKNOWN != FAILED` is enforced in UI flow and interaction behavior.
- Commit evidence finalizes from existing effect without duplicate inventory mutation.
- No-commit evidence can continue only the same operation/request identity and same confirmed content.
- Insufficient evidence remains unresolved with owner + scope protection; no blind retry/new operation.

## Governance

- Canonical Product viewport remains `402×874`.
- Entry/handoff/recovery explanation remains in architecture/contracts/Inspect, outside Product UI.
- All non-target UIFs are protected against parent v1.6.0 regression.
- SRS and `theme.manifest.yaml` are not changed by this release.
