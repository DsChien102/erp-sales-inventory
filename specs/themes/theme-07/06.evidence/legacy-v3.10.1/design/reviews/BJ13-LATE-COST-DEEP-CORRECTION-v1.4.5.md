# BJ13 / UIF13 — Late Landed Cost Deep Product Review v1.4.5

## Product conclusion

v1.4.5 corrects BJ13 from a generic/shared Harness flow into a dedicated late-landed-cost journey. The user now enters from a cost-source task, identifies the exact affected receipt lines, chooses only among allocation methods supplied by authoritative preview policy, reviews a value-only adjustment and receives a result that hands dirty Product/Period scope to BJ14 without implying quantity or official cost was already changed.

## Canonical mental model

`Late cost source component/evidence → source + 1..N exact receipt-line scope → non-mutating normalization/allocation preview → final value-only review → one atomic commit → dirty Product/Period scope → BJ14 recalculation/publish later`.

This is **not** a second initial-valuation flow and is **not** a quantity movement.

## Product architecture

| Step | Screen | Mental task | Entry class |
|---|---|---|---|
| Work queue | `SCR-085` | Find cost-source tasks that can be processed now | `MODULE_ENTRY` |
| Source/scope | `SCR-086` | Understand source component and select exact affected receipt lines | `CONTEXTUAL_DEEP_LINK / IN_FLOW_SURFACE` |
| Allocation | `SCR-087` | Choose a method from the authoritative allowed set and inspect server preview | `IN_FLOW_SURFACE` |
| Final review | `SCR-088` | Confirm the value-only adjustment and downstream scope | `IN_FLOW_SURFACE` |
| Result | `SCR-089` | Understand finality and the handoff to BJ14 | `RESULT` |

Legacy shared `SCR-014/015/017/019` remain BJ03 only in the active Product flow. `SCR-018` is retained only for historical/migration trace.

## Review findings closed

| Finding from BJ13 review | v1.4.5 resolution |
|---|---|
| No canonical Product entry | Added module entry `Giá trị & giá vốn → Chi phí mua bổ sung` and assigned-source-task deep link to SCR-086. |
| SCR-014 used valuation-pending receipt as the task object | Dedicated SCR-085 uses source component/evidence as the primary object. |
| Waiting/missing-source work looked actionable | Waiting task is read-only with owner/reason and no navigation affordance. |
| UC13-01/02 traced to the commit API | Added `BC-IV-06/API-Q-12` non-mutating preview; UC13-01/02 use query/preview only. |
| BC-IV-04 was traced to BJ14 | BC-IV-04 now belongs to BJ13/UC13-03. |
| Commit API was anchored to one receipt valuation | API-C-23 is `POST /v1/late-landed-costs`; source component can target 1..N exact receipt lines. |
| Late-cost data lacked an authoritative source amount/allocation linkage | Added `LateLandedCost` header and immutable `LateLandedCostAllocation` lines with adjustment linkage. |
| Allocation basis was underspecified | UI does not invent an enum. Preview returns `allowed_allocation_methods + policy_version`; multiple valid methods are not preselected. |
| SCR-015 and SCR-018 were passive/dead-end generic surfaces | Replaced by dedicated scope and allocation screens with real task/action semantics. |
| Shared SCR-017 used wrong direct-valuation CTA and quantity effect | Dedicated SCR-088 uses `Ghi chi phí mua bổ sung`; quantity is explicitly unchanged. |
| Shared SCR-019 showed direct-valuation result/event semantics | Dedicated SCR-089 shows late-cost adjustment, posting period, allocation and BJ14 dirty scope. |
| Original vs posting period was invisible | Preview/review/result expose original and posting periods and explain closed-period posting. |
| FX and signed discount behavior lacked proof | Dedicated fixtures cover accounting FX and negative purchase-discount component while preserving sign. |
| Stale source could leave an obsolete allocation visible for commit | Source/version or preview hash mismatch blocks commit and hides obsolete allocation review until regenerated. |
| Result could imply official cost was already published | Result explicitly says `Giá vốn chưa được công bố lại`; BJ14 owns recalculation/publish. |

## Source gap intentionally not invented

The current source does not lock a Phase-1 canonical enumeration of allocation methods or a manual per-line amount override capability. v1.4.5 therefore treats the method set as **authoritative preview data** and does not introduce a new business enum. HTML labels are fixture examples only.

## Domain/data/technical corrections

- `ENT-IV-01 ReceiptValuation` is narrowed back to direct receipt valuation responsibilities.
- `ENT-IV-07/08` represent one late-cost source component/version and its 1..N immutable allocations.
- Source amount, source currency, normalized VND amount, tax/FX provenance, original/posting periods, allocation hash and adjustment linkage are represented explicitly.
- `BC-IV-06/API-Q-12` is read/derive only.
- `BC-IV-04/API-C-23` rebuilds/rechecks source + preview and commits late-cost header, all allocations, value adjustment and dirty scopes atomically.
- No quantity movement; no rewrite of receipt/direct valuation/value history; no automatic official-cost publish.

## Release gates

- BJ13 static/domain/contract: **33/33 PASS**.
- BJ13 end-user/pointer interaction: **36/36 PASS**.
- Protected non-UIF13 exact runtime regression: **100/100 PASS** with zero topology/default-text diff.
- All-flow runtime: **87 renders PASS**.
- Visual: **23/23 PASS**, 11 specimens at canonical **402×874**.
- Product approval remains **PENDING**; QA PASS is evidence, not Product freeze.

## Next boundary

BJ14/UIF14 can now be reviewed against a cleaner valuation chain:

`BJ02 physical receipt → BJ03 initial valuation → BJ13 late value adjustment → BJ14 recalculation/publish`.

Before BJ14 is corrected, it must consume dirty scopes and adjustment/value history without assuming BJ13 already published a new official cost.
