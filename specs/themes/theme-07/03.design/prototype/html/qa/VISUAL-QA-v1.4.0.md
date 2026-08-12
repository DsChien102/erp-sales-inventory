# Visual QA v1.4.0 — BJ03/UIF03

**Result: PASS**

Manual review was performed on the rendered Product UI at the canonical **402×874** phone viewport after the final interaction/static gates. Primary visual evidence is `screenshots-v1.4.0/BJ03-CONTACT-SHEET-v1.4.0.png`.

## Reviewed specimens

| Specimen | Review |
|---|---|
| `BJ03-SCR014-worklist.png` | Search/filter hierarchy is compact; receipt rows show supplier + item/part count; no mixed-UOM quantity total; status badges remain secondary to task identity. |
| `BJ03-SCR015-scope.png` | Product+UOM grouping and physical-state parts are legible; selection/quantity controls remain distinct; 44 px interaction target is respected; long content remains scrollable above the sticky footer. |
| `BJ03-SCR016-conflict.png` | Provenance/calculation hierarchy is clear; source conflict is persistent and blocks review; authoritative price is not presented as an editable money field. |
| `BJ03-SCR016-fx.png` | Original `USD/lọ`, accounting FX provenance, converted VND amount and derived cost are visually separated; no duplicate FX string after correction. |
| `BJ03-SCR017-review.png` | Financial total, item/UOM evidence and availability effect have separate hierarchy; quantities with different UOM are not summed; one primary commit action is visible. |
| `BJ03-SCR017-source-changed.png` | Stale review is unmistakably blocked; affected source delta `before → after` is visible before the user returns to reconciliation; unaffected item evidence remains visible. |
| `BJ03-SCR019-completed.png` | Success result is centered, business-facing and has no Back affordance; exact availability/quarantine effects are readable. |
| `BJ03-SCR019-unknown.png` | UNKNOWN is visually distinct from success, contains no mutation retry and exposes no technical operation identifier. |

## Geometry / usability checks

- Product viewport is exactly **402×874 px**.
- No horizontal overflow on SCR-014/015/016/017/019.
- Long scope/calculation content scrolls vertically; automated reachability checks confirm the last scope guidance and FX guidance can be scrolled fully above the sticky action footer.
- Interactive UIF03 controls use the DS medium control target or larger (≥44 px).
- Key/value anatomy was corrected for UIF03 so labels and values no longer run together on the narrow viewport.
- Product copy does not expose implementation phrases such as `value movement`, technical operation IDs, `Product+UOM`, or “bản nháp UI”. Source evidence versions (`v2`, `v7`) remain intentionally visible as provenance.

**Verdict:** visual gate PASS for BJ03/UIF03 v1.4.0.
