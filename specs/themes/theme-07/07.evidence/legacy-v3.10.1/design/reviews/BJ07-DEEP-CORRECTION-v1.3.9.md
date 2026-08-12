# BJ07 / UIF07 — Deep Product Correction Review v1.3.9

## Product verdict
BJ07 keeps the source-authorized architecture and corrects execution depth rather than redesigning the business journey.

### Locked corrections
1. Active flow is four surfaces: `SCR-036 → SCR-037 → SCR-039 → SCR-041`; SCR038 stays outside UIF07.
2. Queue expresses warehouse work, not generic inventory state records. Source-owned waiting rows are read-only.
3. UI model is Product+UOM with explicit LOT allocations. Mixed UOM is never summed into a meaningless quantity.
4. Physical verification is distinct from source facts; source quantity is not editable.
5. Physical mismatch/LOT mismatch cannot be “fixed” by warehouse-side partial or substitution. Source amendment is required.
6. Source changes invalidate only affected evidence; remove/cancel releases pending system-side.
7. Actual handover is the only physical/value commit point.
8. Result finality prevents Back-to-commit and UNKNOWN blind retry.

## QA expectation
Business, interaction, runtime, 402×874 visual and isolation/regression gates must all pass before Product freeze.
