# Visual QA — v1.3.6

**Result: PASS · 11 focused specimens reviewed at 402×874.**

Reviewed after runtime/static gates, with Flutter Design System as UI authority and HTML as renderer.

## BJ05
- `BJ05-queue.png` — actionable/waiting hierarchy readable; no horizontal overflow.
- `BJ05-multilot-pick.png` — multiple LOT allocations remain scannable on mobile.
- `BJ05-stale-physical.png` — physical correction copy is explicit rather than technical stale wording.
- `BJ05-partial-handover.png` — customer context + per-allocation actual handover inputs; commit CTA remains visible.

## BJ06
- `BJ06-multiline-receipt.png` — multi-line return overview scans cleanly.
- `BJ06-wrong-lot.png` — mismatch warning and structured reason controls use DS-aligned surfaces; evidence remains below in scrollable content.
- `BJ06-classification-overview.png` — line/LOT status is visible without card inflation.
- `BJ06-classification-sheet.png` — contextual editor does not collide with page sticky footer; hard guard is visible.

## BJ07
- `BJ07-queue.png` — normal queue is quiet; lifecycle and source-change signal are distinct.
- `BJ07-physical-verify.png` — source delta is concrete (`8 → 5`, bỏ 3) and verify task is clear.
- `BJ07-handover-review.png` — final handover is distinct from preparation and remains a single irreversible CTA.

No blocking overlap, cut text, horizontal overflow, English/technical leakage in the focused product surfaces above.
