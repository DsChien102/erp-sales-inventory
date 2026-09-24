# Inventory Valuation Group Product Correction — v1.5.0

Parent: **v1.4.5**  
Scope: **BJ03/UIF03 + BJ13/UIF13 + BJ14/UIF14**  
Product approval: **PENDING**

## Why this release exists

Inventory Valuation had accumulated two types of debt through earlier design loops: (1) architecture/orchestration explanation was sometimes rendered inside Product UI; (2) use-case/system-state structure was too directly mirrored into screens, producing avoidable navigation loops. v1.5.0 treats the three valuation journeys as one Product family and applies the lessons learned from BJ02, Inventory Operations, BJ03 foundation and BJ13 deep correction.

## Locked Product rule

Entry point, upstream/downstream journey, actor handoff and orchestration are **architecture metadata**. They live in `entry-architecture.md`, UIF flow contracts and Inspect/review artifacts. Product UI does not render them by default. A business fact appears in UI only when it changes the current user's decision or action.

## BJ03 — Initial valuation

### Active flow

`SCR-014 → SCR-015 → SCR-017 → SCR-019`

`SCR-016` is retired from the active Product route. Provenance, calculation breakdown and source conflict are contextual Bottom Sheets opened from SCR-015/SCR-017 and close back to the same mental task.

### Corrections

- Removed the `Nguồn việc` card and other architecture explanation from the queue.
- Preserved actionable vs waiting evidence; waiting work is read-only.
- Kept exact Product+UOM+LOT/non-LOT+physical-state valuation scope and progressive partial quantity.
- Conflict sources are not preselected; reason remains mandatory.
- Final review keeps unit actual cost, value, authoritative availability effect and initial official-cost bootstrap when applicable.
- Source stale blocks commit without routing the user through a separate calculation screen.
- Result distinguishes actionable remainder from waiting-only remainder; UNKNOWN has no blind retry.

## BJ13 — Late landed cost

### Active flow

`SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`

### Corrections

- Removed normal-state domain/orchestration explanation and any internal BJ reference from Product UI.
- Preserved late-cost source component as the primary task object and exact 1..N receipt-line target scope.
- Preserved server-authoritative allocation preview, allowed methods, reconciliation, FX/tax/period provenance and value-only commit.
- Final review now has one edit route (`Chỉnh sửa`) back to allocation rather than multiple backward branches.
- Result communicates `Giá vốn: Cần tính lại` in business language; it does not expose “BJ14”.
- Quantity remains unchanged and official cost is never auto-published by BJ13.

## BJ14 — Cost calculation and publication

### Active flow

`SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077`

`SCR-075` is retired from the active Product route. `CALCULATING`, `BLOCKED`, `READY_FOR_REVIEW` and changed-input behavior are states of the immutable CostCalculationRun/result surface.

### Product design

- SCR-072 is the cost-run/dirty-scope worklist.
- SCR-073 creates a run from type, period and product scope. Cut-off and publication method are system/policy facts, not free user choices.
- SCR-074 calculates/displays **both sourced weighted-average methods on the same immutable snapshot**; the policy-selected publication method is visually identified but not user-selectable.
- Blockers are shown with the responsible owner and no publication action.
- Changed input keeps the old run and requires a successor run.
- SCR-076 is the only final publication review/commit surface.
- Publish atomically represents COGS true-up, ending-inventory adjustment and successor official-cost version; no historical source movement is rewritten.
- `Giá bán: Không thay đổi` is an explicit domain boundary.
- SCR-077 is terminal. UNKNOWN keeps the operation non-retryable until reconciled.

## Cross-journey valuation chain

The Product UI does not render the orchestration, but the external contract remains:

1. BJ03 establishes initial receipt valuation and may bootstrap an initial official cost for downstream operation.
2. BJ13 records late value-only cost components and marks the affected Product/Period scope dirty.
3. BJ14 calculates/reconciles an immutable cost run and publishes successor official-cost versions plus adjustment movements.

These are separate mutations. A downstream handoff is never treated as automatic proof that the next mutation has completed.

## Business/source boundaries preserved

- No new costing method enum was invented; BJ14 uses the two methods already defined by Theme 7 source and the method locked by policy.
- BJ13 allocation methods remain authoritative preview/policy output; fixture labels are not promoted to business enums.
- Financial masking, idempotency/UNKNOWN rules, no historical rewrite and pricing separation remain intact.
- Frozen source/know-how/history are not rewritten by this release.

## QA strategy

This release adds gates specifically aimed at avoiding earlier loops:

- architecture explanation must stay out of normal Product UI;
- active topology must not contain retired calculation/blocker screens;
- partial/LOT/scale/stale/UNKNOWN paths are re-tested;
- 20+ exact valuation scopes and 20+ late-cost targets must remain scrollable without horizontal overflow;
- cost-run method is policy-led, blockers are states, and successor immutability is tested;
- all non-target UIFs must render exactly as v1.4.5;
- visual evidence is captured at canonical 402×874.

QA PASS supports Product review only. It is **not** Product approval/freeze.
