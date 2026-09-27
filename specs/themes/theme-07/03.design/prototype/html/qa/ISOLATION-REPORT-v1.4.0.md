# ISOLATION REPORT — Theme 7 Prototype Harness v1.4.0

- Parent: `VET45-Theme7-Prototype-Harness-v1.3.9`
- Child: `VET45-Theme7-Prototype-Harness-v1.4.0`
- Target correction: **BJ03 / UIF03 — Xác nhận giá trị ban đầu của hàng nhận**
- Date: 2026-09-03
- Result: **PASS**

## 1. Cumulative-parent integrity

v1.4.0 was produced directly from the extracted v1.3.9 package. No parent file was removed.

Final file-level diff against the parent, including this report:

- Existing parent files modified: **22**
- New files added: **20**
- Parent files removed: **0**
- Final package file count: **859**

## 2. Modified existing files — allowed scope

All 22 modified parent files are inside the approved UIF03 correction surface or cumulative metadata required to render it coherently:

1. Root/prototype/HTML release README metadata.
2. Harness/component/cross-UIF/action/screen/UI-flow registries.
3. UIF03 component-usage contract.
4. UIF03 flow contract.
5. SCR-014, SCR-015, SCR-016, SCR-017 and SCR-019 design contracts.
6. Shared HTML manifest/workbench renderer files required by the cumulative harness.
7. `app.js` for mode-scoped UIF03 behavior.
8. `styles.css` for v1.4.0 rules scoped to `body[data-active-uif="UIF-03"]`.

No SRS file and no `know-how/` file differs from v1.3.9. The release therefore implements already-defined BJ03/UC03/BC-IV-01 rules rather than inserting a new business decision through UI code.

## 3. Shared UIF13 isolation

UIF03 and UIF13 share screen identities, so filename isolation alone is insufficient.

Verified controls:

- Custom renderers for `SCR-014`, `SCR-015`, `SCR-017`, `SCR-019` immediately fall back to the inherited generic renderer when `activeFlowId !== "UIF-03"`.
- Shared workbench screen payloads `SCR-014`, `SCR-015`, `SCR-017`, `SCR-019` are semantically identical to v1.3.9.
- UIF13 READY Product text was rendered side-by-side from pristine v1.3.9 and final v1.4.0. All five screens are identical: `SCR-014`, `SCR-015`, `SCR-018`, `SCR-017`, `SCR-019`.

This proves non-interference. It does **not** claim UIF13 Product approval; inherited UIF13 behavior is intentionally deferred to the next deep-design release.

## 4. Protected Inventory Operations evidence

Frozen evidence remains byte-identical to the parent:

- BJ05 v1.3.7 protected QA/screenshots: **12 files, 0 changed**.
- BJ06 v1.3.8 protected QA/screenshots: **15 files, 0 changed**.
- BJ07 v1.3.9 protected QA/screenshots: **13 files, 0 changed**.

Protected behavior was also rerun against the final v1.4.0 renderer in a temporary copy, so the historical evidence files were not regenerated.

## 5. Release gates

| Gate | Result |
|---|---:|
| BJ03 end-user / interaction / state QA | **PASS 71/71** |
| BJ03 static / contract conformance | **PASS 53/53** |
| All-flow runtime smoke | **PASS 87 renders** |
| BJ05 regression | **PASS 48/48** |
| BJ06 regression | **PASS 65/65** |
| BJ07 regression | **PASS 65/65** |
| UIF13 parent-equivalence render | **PASS 5/5 screens identical** |
| 402×874 visual QA | **PASS** |
| JSON + selected YAML parse | **PASS** |
| `node --check app.js` | **PASS** |

The historical `validate_contract.py` remains excluded as a release gate because it is tied to an older BJ02 contract baseline; v1.4.0 does not rewrite its historical evidence.

## 6. BJ03 invariants verified

- Active Product path remains `SCR-014 → SCR-015 → SCR-016 → SCR-017 → SCR-019`.
- Valuation scope is receipt line / identified quantity part grouped by Product+UOM; mixed-UOM quantity is not aggregated.
- Authoritative price/tax/FX evidence is read-only; source conflict has no preselection and requires an explicit reason.
- Foreign source amount and accounting FX provenance remain separately visible.
- Direct-cost calculation does not invent late landed cost; BJ13 retains that responsibility.
- Value effect and sellability/availability effect are distinct.
- Source/version stale blocks commit, shows affected before→after delta and preserves unaffected draft resolution.
- `SCR-017` owns one direct-valuation commit; there is no second approval or repeat confirmation modal.
- Exact selected pending quantity is decremented on successful commit; unselected remainder stays pending.
- COMPLETED / REJECTED_EXECUTION / UNKNOWN / PERMISSION finality is distinct; no result state returns Back to a consumed commit and UNKNOWN never blind-retries.
- Product UI avoids technical operation identity and implementation jargon.
- Interactive controls meet the 44 px target; long content remains reachable above sticky footers.

## 7. Isolation conclusion

**PASS.** v1.4.0 is a cumulative child of v1.3.9, changes only the intended BJ03/UIF03 product-design surface plus necessary shared registries/renderer metadata, introduces no parent-file removal, preserves business-source files and frozen Inventory Operations evidence, preserves UIF13 inherited runtime behavior, and passes interaction/static/runtime/visual/regression gates.
