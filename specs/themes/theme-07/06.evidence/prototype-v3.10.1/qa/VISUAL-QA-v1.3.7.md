# BJ05 Visual QA v1.3.7

**Result: PASS · 10 focused specimens reviewed at canonical 402×874 Product viewport**

## Review focus

- hierarchy and density on mobile;
- no clipped text, horizontal overflow or CTA overlap;
- queue default/filter semantics are visible without redundant navigation;
- waiting/source-owned work reads as read-only rather than an actionable pick task;
- multi-LOT progress and physical-correction warning remain understandable without exposing technical allocation/version identifiers;
- LOT replacement Bottom Sheet supports a clear selection → reason → confirm sequence;
- partial handover preserves customer context and only shows allocations actually picked;
- finality/result surfaces provide a safe next CTA and do not visually imply Back to a consumed commit surface;
- warning/error states are visually distinct from successful handover.

## Specimens

1. `BJ05-SCR025-all.png` — default `Tất cả`, chip order and mixed actionable/waiting queue.
2. `BJ05-SCR026-in-progress.png` — real in-progress pick state; compact product progress.
3. `BJ05-SCR026-waiting-order.png` — source-waiting order; item rows are read-only and carry no item navigation chevron.
4. `BJ05-SCR027-override-sheet.png` — alternative LOT, expiry/available evidence, reason field and explicit confirmation.
5. `BJ05-SCR026-stale-correction.png` — stale allocation invalidates old pick and blocks handover until physical correction.
6. `BJ05-SCR028-partial-review.png` — picked allocations only, actual handover quantity and remaining-product summary.
7. `BJ05-SCR028-source-changed.png` — irreversible commit is blocked after source change and routes to refreshed pick state.
8. `BJ05-SCR029-partial-result.png` — partial finality plus continuation CTA.
9. `BJ05-SCR029-full-result.png` — full finality plus queue CTA.
10. `BJ05-SCR029-rejected.png` — rejected execution is not rendered as success and provides safe recovery.

## Findings resolved during this visual pass

- Removed item-level chevrons from source-waiting/read-only pick rows; the previous disabled-button presentation still looked tappable.
- Kept cross-UOM quantities out of aggregate summary copy; summary uses product count while actual quantities remain per Product/UOM/LOT.
- Verified result screens have a visible footer CTA and no Back affordance into `SCR-028`.

Automated geometry checks are covered by `BJ05-END-USER-QA-v1.3.7.md`; visual PASS is separate from Product approval.
