# v0.2.6 — BJ-02 isolated calibration

This version fixes the v0.2.5 runtime regression and preserves all non-BJ02 journey artifacts from v0.2.4.

## Runtime fix
- Restored Harness bootstrap (`render()`, flow selector binding, generic-flow handlers).
- Restored Inspect state declarations accidentally removed in v0.2.5.

## Isolation guarantee
- `UIF-01` and `UIF-03..17` data/screens remain from v0.2.4.
- BJ-02-only CSS is scoped under `body[data-active-uif="UIF-02"]`.
- Non-BJ02 toast renderer remains the v0.2.4 implementation.
- BJ-02 keeps the v0.2.5 contract/UI/UX corrections.
