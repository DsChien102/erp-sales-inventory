# Changelog v1.3.9 — BJ07/UIF07 Deep Product Correction

Parent: **v1.3.8**.

## Corrected
- SCR-036 supplier-return queue: default All; actionable/ready/waiting; waiting source-owned read-only; search no-result.
- SCR-037: Product+UOM groups with 1..N LOT allocations; explicit physical verification; optional scan; physical mismatch blocker; no warehouse-side quantity/LOT override.
- Source delta: add/change/remove/cancel; granular verification invalidation; system release for removed/cancelled pending scope.
- SCR-039: exact-source final handover review; mixed UOM remains separate; source-version recheck; no second approval/modal.
- SCR-041: COMPLETED/REJECTED_EXECUTION/UNKNOWN/PERMISSION finality, safe navigation, no Back-to-commit or blind retry.
- Registry parity: UIF07 is four active screens; SCR038 remains UIF09 only.

## Protected
BJ05 v1.3.7 and BJ06 v1.3.8 behavior are regression baselines. Shared renderer/CSS changes are scoped and re-tested.
