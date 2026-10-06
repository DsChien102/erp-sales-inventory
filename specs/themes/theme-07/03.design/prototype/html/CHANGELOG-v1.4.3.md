# CHANGELOG — v1.4.3

Parent: **v1.4.2**  
Scope: **Inventory Operations + BJ03 Product Entry Architecture & Journey Continuity Correction**.

## Why this release exists

v1.4.2 had strong in-flow business and semantic QA, but Product review still found several screens hard to understand when entered outside the review workbench: the user could not always tell **where the screen came from, why the task existed, who owned the current step, where Back should return, or how actor/source handoff resumed**.

The HTML UIF selector is review tooling only and is not treated as Product navigation in this release.

## Changed

### Cross-cutting Product entry architecture

- Added canonical entry classes: `MODULE_ENTRY`, `CONTEXTUAL_DEEP_LINK`, `CONTEXTUAL_ONLY`, `ACTOR_HANDOFF_TASK`, `IN_FLOW_SURFACE`, `SYSTEM_RECOVERY`, `RESULT`.
- Added canonical Back/exit, waiting-owner and re-entry rules in `contracts/entry-architecture.md`.
- Screen registry receives entry-class + canonical-parent metadata for all active Inventory Operations + BJ03 surfaces.
- Product navigation taxonomy now distinguishes module destinations from contextual, actor-handoff, recovery and result surfaces.

### BJ01 / UIF01

- `SCR-001` remains the module entry.
- `SCR-003` can open as a Product/inventory contextual deep link and exits back to the source Product context.

### BJ02 / UIF02

- Generic Inventory entry remains `SCR-006`.
- A known Purchase document can deep-link directly to `SCR-009`; user is not asked again to choose Document vs Quick.
- Maker submit requiring approval ends the maker session in `WAITING_APPROVAL`; it does **not** navigate the maker to `SCR-011`.
- `SCR-011` is an independent approver task surface entered from assigned work/notification.
- `SCR-013` is explicitly `SYSTEM_RECOVERY`, reachable only from UNKNOWN finality and never as a menu destination.

### BJ03 / UIF03

- Module entry mental model is **Hàng chờ xác nhận giá nhập** rather than domain jargon.
- BJ02 may create valuation work, but warehouse actor is not auto-routed into BJ03.
- Assigned goods receipt/valuation task can deep-link to `SCR-015` and Back returns to the valuation worklist.
- Initial valuation vs late-cost BJ13 boundary is documented explicitly.

### BJ04 / UIF04

- Removed ghost Product routing from active UI architecture.
- Canonical Product path is now only: `Order detail → SCR-021 → Back to order`.
- `SCR-020`, `SCR-022`, `SCR-023`, `SCR-024` remain historical/migration contracts only and are registered `RETIRED` for UIF04 Product navigation.
- Old Harness review is marked historical to prevent accidental route resurrection.

### BJ05 / UIF05

- `SCR-025` is the module queue; assigned order task can deep-link to `SCR-026`.
- Back/re-entry returns to the picking queue/source task while preserving valid pick evidence.

### BJ06 / UIF06

- Maker and wrong-LOT approver are modeled as separate actor sessions.
- `SCR-034` is an `ACTOR_HANDOFF_TASK`; maker never navigates into the approver surface.
- `SCR-035` has two explicit mental roles: **Đã nhận hàng khách trả** (intermediate goods receipt milestone) vs **Kết quả phân loại hàng trả** (terminal result).

### BJ07 / UIF07

- Queue-level copy explains that supplier-return work is authorized/transferred by Purchase.
- A specific supplier-return task can deep-link to `SCR-037`.
- Physical/source mismatch clearly hands ownership back to Purchase; warehouse cannot edit commercial quantity/LOT.
- Purchase amendment re-enters the same request/version chain and invalidates only affected evidence.
- `SCR-041` transition trace is corrected to current `T06/T07/T08`; stale `T09/T10/T11` machine-registry references are removed.

## Protected / unchanged business semantics

- No SRS business rule, lifecycle, data entity, approval authority or commit semantics changed.
- BJ05 partial handover rules remain unchanged.
- BJ06 wrong-LOT maker-checker and goods receipt/classification commit semantics remain unchanged.
- BJ07 exact-source preparation, source-amendment and physical/value commit rules remain unchanged.
- UIF08–UIF17 are outside Product-correction scope; their runtime topology/text is protected against parent v1.4.2.

## QA

- Entry architecture static/contract: **43/43 PASS**.
- Entry & journey continuity runtime: **57/57 PASS**.
- Semantic hierarchy regression: **73/73 PASS**.
- Business invariant regression: **17/17 PASS**.
- All-flow runtime smoke: **87 renders PASS**.
- Protected non-target flows UIF08–UIF17: **121/121 PASS**, exact READY-state text/topology + horizontal safety.
- Visual Product review fixtures: **37/37 PASS**, 18 specimens at **402×874**.
- Isolation report: see `qa/ISOLATION-REPORT-v1.4.3.md`.

QA PASS supports Product review and **does not equal Product approval/freeze**.
