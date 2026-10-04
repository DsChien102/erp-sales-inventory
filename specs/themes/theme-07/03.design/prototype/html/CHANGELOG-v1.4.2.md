# CHANGELOG — v1.4.2

Parent: **v1.4.1**  
Scope: **Inventory Operations + BJ03 semantic hierarchy correction**.

## Changed

- UIF02: Product search rows expose selection affordance; LOT review rows have explicit `Lô` identity.
- UIF03: self-describing valuation quantity input; structured scope rows; labeled group value; grouped availability/result effects; normal late-cost guidance becomes quiet footnote.
- UIF05: queue metadata budget reduced; `dòng hàng` vocabulary; partial handover allowance explained near CTA; allocation wording uses LOT when appropriate.
- UIF06: source LOT and actual LOT rendered as separate labeled facts; approver evidence has explicit role label; goods receipt/classification result grouped by Product+UOM → allocation and hides zero classification states.
- UIF07: SCR-037 Product+UOM parent and LOT/allocation children use distinct visual grammar; normal unverified child has `Kiểm` action hint; verification field is explicitly `đối chiếu`, not edit; SCR-039/041 use the same parent-child hierarchy.
- Shared contract drift in SCR-037 corrected: UIF07 is explicitly a physical-verification action context, not generic read-only detail.

## Audited but unchanged

- UIF01 / BJ01.
- UIF04 / BJ04.
- UIF13 runtime/fallback behavior.

## Not changed

- No SRS business-rule/lifecycle/commit semantics changed.
- No screen/transition added or removed.
- `SCR-038` remains outside active UIF07.

## QA

- Semantic hierarchy / 2-second scan: **73/73 PASS**.
- Static + contract conformance: **59/59 PASS**.
- Business-invariant regression: **17/17 PASS**.
- All-flow runtime smoke: **87 renders PASS**.
- Protected-flow regression (UIF01/UIF04/UIF13): **12/12 PASS**; UIF13 READY-state rendered text remains exact-parent equivalent.
- Visual QA: **43/43 PASS** across **21** representative 402×874 screenshots.
- Isolation: **12/12 PASS**; no SRS/know-how/business lifecycle source changed and no file removed.

QA PASS is not Product approval.
