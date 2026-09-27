# Changelog — v2.7.1

Parent: **v2.7.0**  
Scope: **live Figma DS primitive correction + BJ05 re-QA**.

## Fixed

- Re-read the updated live `DS v2 / List Row` (`525:519`) and fixed the generic 44px touch-target cascade that could collapse button rows. Every HTML instance that explicitly claims the canonical List Row now declares Type + Density + State; Default is 76px and Compact is 52px.
- Preserved semantic trailing affordance: Navigation → chevron; Status → no chevron; Selection → selection control/no chevron. BJ05 waiting/source-owned tasks remain true read-only Status rows but align exactly with actionable peers.
- Removed false `DS v2 / List Row` claims from legacy composite inventory rows whose anatomy is not the current Figma master; they remain explicitly marked as legacy pending structural Product migration.
- Applied the established VET45 information-surface composition to multi-row `Info Row` facts: a rounded white information surface groups related rows while each `Info Row` remains transparent `338×44`.
- Fixed BJ05 `Key-value Row` to the live `525:358` Default/Emphasis anatomy and typography.
- Unified the shared toast renderer and corrected `VToast` to live `526:4305`: `370×56`, dark surface, `8px` radius, semantic 24px leading circle, 14/20 Regular message and plain 20px close X. Legacy CSS that painted the close SVG as a semantic circle is explicitly neutralized.
- Re-QA'd BJ05 and the full active harness without changing BJ05 business behavior.

## QA closure

- Shared primitive QA: PASS 31/31.
- Full canonical List Row render audit: PASS, 30 instances, 0 semantic/geometry issues.
- Full Info Row render/grouping audit: PASS, 265 instances, 0 anatomy/grouping issues.
- BJ05 targeted QA: PASS 71/71.
- All-flow runtime smoke: PASS 85 active renders, 0 browser errors.
- Visual QA: PASS on 402×874 captures including List Row, grouped Info Row, Key-value Row and VToast.

## Business behavior

No business rule changed. Allocation remains system-owned; pick does not reduce physical stock; actual handover is the stock commit point; LOT changes invalidate affected pick evidence; cross-UOM numeric aggregation remains prohibited; UNKNOWN has no blind retry.
