# CHANGELOG — v4.6.5

## Scope

Role-aware Warehouse Hub review profiles in the HTML prototype only.

## Changed

- Added a workbench-only role controller for `Chủ cửa hàng`, `Thủ kho`, `Kế toán`, `Nhân viên bán hàng`.
- `Chủ cửa hàng` uses `FULL`; other profiles adjust quick actions, `Cần chú ý`, workspace order and workspace visibility on `SCR-090 — Kho`.
- Added runtime metadata for navigation profiles and role-specific QA captures.

## Not changed

- No permission enforcement was added.
- `PAT-NAV`, `PAT-UI-UX`, `SCR-090`–`SCR-096`, BJ, UC and UIF semantics are unchanged.
- Business destination screens and mutations remain canonical.
