# CUMULATIVE REVIEW — UIF-05

## Current canonical status

- Baseline: `v1.3.7`.
- Flutter Design System remains UI authority; HTML is renderer/workbench.
- BJ05 preserves Phase-A decisions: normal pick/handover has no approval; FEFO/FIFO is system proposal; override needs permission + reason; physical stock changes only at actual handover.

## Cumulative UX locks

- Queue defaults to all data; chips filter a single list.
- Order/Fulfillment owns its pick lines and allocations.
- Product+UOM may contain 1..N LOT allocations.
- Stale/manual LOT replacement cannot carry old physical pick evidence into the new LOT.
- Handover review contains picked allocations only and never aggregates incompatible UOM quantities into a misleading total.
- Partial handover creates a continuation; full handover closes the active task.
- Result finality prevents Back/blind retry into an already-consumed mutation surface.
- Runtime QA must exercise actual pointer/focus/keyboard interaction for forms and Bottom Sheets.
