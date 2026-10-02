# v4.6.5 — Warehouse Hub flat role-aware navigation

Parent: user-provided cleaned `v4.6.4` package.

## Changed

- Restored the Warehouse Hub role review control for four system roles: Chủ cửa hàng, Thủ kho, Kế toán, Nhân viên bán hàng.
- Replaced grouped `Quản lý kho` workspace entries with one flat capability list.
- Removed any capability from the flat list when the same capability is already shown as a Quick Action for the selected role.
- Role-filtered `Cần chú ý` signals.
- Preserved BJ02 pending-approval continuity; maker opens `SCR-010` read-only while approver opens `SCR-011`.
- Retained `SCR-091`–`SCR-096` only for trace/migration; they are no longer required navigation steps from `SCR-090`.

## Unchanged

- Business rules, mutation contracts, finality and inventory/costing semantics outside the Hub navigation presentation.
- Contextual-only capabilities remain contextual-only.
