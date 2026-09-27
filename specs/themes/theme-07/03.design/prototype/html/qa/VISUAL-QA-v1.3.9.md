# Visual QA v1.3.9 — BJ07/UIF07

**Result: PASS**

Manual review was performed on the rendered Product UI at the canonical **402×874** phone viewport, supported by the BJ07 end-user runtime checks and the contact sheet in `screenshots-v1.3.9/BJ07-CONTACT-SHEET-v1.3.9.png`.

## Reviewed specimens

| Specimen | Review |
|---|---|
| `BJ07-SCR036-all.png` | Four queue chips fit without wrap/overflow; actionable vs ready vs waiting is readable; no unnecessary technical state. |
| `BJ07-SCR036-waiting.png` | Waiting/source-owned item is visibly read-only and has no chevron/navigation affordance. |
| `BJ07-SCR037-unverified.png` | Product+UOM grouping is clear; multiple LOT allocations are scan-friendly; mixed UOM remains separate; sticky footer does not obscure reachable content. |
| `BJ07-SCR037-lot-mismatch.png` | Verification Bottom Sheet fits 402×874; wrong LOT error is inline/persistent; disabled primary action is visible; no silent substitution path. |
| `BJ07-SCR037-physical-mismatch.png` | Blocking guidance is near the affected task; footer remains disabled; copy sends correction back to the source owner. |
| `BJ07-SCR037-source-delta-granular.png` | Business-facing delta is visible; unaffected verified line remains visibly verified; changed line is explicitly “Cần kiểm lại”. |
| `BJ07-SCR039-ready.png` | Final review preserves item/UOM/LOT hierarchy; quantities with different UOM are not aggregated; no technical source-version number is exposed. |
| `BJ07-SCR041-completed.png` | Terminal success has no Back affordance; line-level handover evidence remains readable; technical operation identity is not exposed in Product UI. |
| `BJ07-SCR041-unknown.png` | UNKNOWN is clearly non-success, has no retry mutation, no technical ID/BJ code, and offers only a safe return action. |
| `BJ07-SCR036-after-complete.png` | Completed task is removed from active work queue without disturbing remaining tasks. |

## Geometry / hierarchy checks

- All captured Product UI images are exactly **402×874 px**.
- Runtime QA confirms no horizontal overflow on SCR-036, SCR-037, SCR-039 and SCR-041.
- Long preparation/review content uses vertical scrolling rather than shrinking text/components.
- Primary footer action remains single and stable; the verification Bottom Sheet suppresses the underlying footer while open.
- No English/technical labels such as `Product+UOM`, `operation identity`, source-version number or `BJ17` are exposed in the reviewed Product UI.

**Verdict:** visual gate PASS for BJ07/UIF07 v1.3.9.
