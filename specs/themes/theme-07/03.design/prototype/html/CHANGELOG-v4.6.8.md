# Changelog v4.6.8 — BJ02 Design State Cleanup

Parent: `v4.6.7`.

- `SCR-010` canonical state list remains: `READY`, `VALIDATION_ERROR`, `APPROVAL_REQUIRED`, `PERMISSION_DENIED`, `PENDING_APPROVAL`, `APPROVER_CONFIGURATION_MISSING`, `FINANCIAL_MASKED`.
- Removed stale Quick Receipt draft/price-basis blocker states from generated runtime-state registries for `SCR-010`.
- Removed the defensive runtime state filter from the v4.6.7 patch; the design source itself is now authoritative and clean.
- Added `runtime-state-registry-v4.6.8.json` as the canonical current generated registry.
- No change to `UC-02-01`, BJ10 `PRICE_BASIS_REQUIRED`, or other valid state models.
