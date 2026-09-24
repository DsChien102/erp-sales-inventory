# ISOLATION REPORT — Theme 7 Prototype Harness v1.3.9

- Parent: `VET45-Theme7-Prototype-Harness-v1.3.8`
- Child: `VET45-Theme7-Prototype-Harness-v1.3.9`
- Target correction: **BJ07 / UIF07 — Thực hiện trả hàng cho nhà cung cấp**
- Date: 2026-09-03
- Result: **PASS**

## 1. Cumulative-parent integrity

v1.3.9 was produced directly from the extracted v1.3.8 package. No file was removed from the parent tree.

Final file-level diff against the parent:

- Existing files modified: **28**
- New files added: **22**
- Parent files removed: **0**

The added set is release evidence and v1.3.9-specific QA/review material; it does not replace historical parent evidence.

## 2. Modified existing files — allowed scope

All 28 modified parent files fall inside the approved BJ07 correction surface:

1. Theme/prototype readme and harness status metadata.
2. Theme 7 decision register, with BJ07 supplier-return amendments.
3. BJ07 Business Journey and UC-07-01..04 source specifications.
4. UIF07 flow contract and component-usage contract.
5. SCR-036, SCR-037, SCR-039 and SCR-041 contracts.
6. Cross-UIF/action/screen/UI-flow registries required to keep the package coherent.
7. Shared HTML renderer/data/manifest files needed to render UIF07.
8. `styles.css`, where the **new v1.3.9 BJ07 rules are scoped to `body[data-active-uif="UIF-07"]`**.

No unrelated BJ source specification, unrelated UIF flow contract, or unrelated screen contract was modified.

## 3. Protected BJ05 / BJ06 evidence

The cumulative corrections already frozen in the parent remain protected:

- `BJ05-END-USER-QA-v1.3.7.md`: byte-identical to parent.
- `BJ05-STATIC-CONFORMANCE-v1.3.7.md`: byte-identical to parent.
- `screenshots-v1.3.7/`: no diff.
- `BJ06-END-USER-QA-v1.3.8.md`: byte-identical to parent.
- `BJ06-STATIC-CONFORMANCE-v1.3.8.md`: byte-identical to parent.
- `screenshots-v1.3.8/`: no diff.
- Historical `CONFORMANCE-REPORT.md`: byte-identical to parent.

The shared renderer was therefore regression-tested rather than accepting isolation by filename alone.

## 4. Shared-renderer regression gates

Current release gates after the BJ07 correction:

| Gate | Result |
|---|---:|
| BJ07 end-user interaction QA | **PASS 65/65** |
| BJ07 static conformance | **PASS 39/39** |
| All-flow runtime smoke | **PASS 87 renders** |
| Protected BJ05 end-user regression | **PASS 48/48** |
| Protected BJ06 end-user regression | **PASS 65/65** |
| BJ07 visual QA at 402×874 | **PASS** |

The legacy `validate_contract.py` is not a v1.3.9 release gate because it contains BJ02/v0.2.9-specific historical expectations. Its historical output is intentionally preserved byte-identical from the parent instead of being rewritten to make it appear current.

## 5. BJ07 isolation invariants verified

The v1.3.9 product path remains:

`SCR-036 → SCR-037 → SCR-039 → SCR-041`

`SCR-038` is not reintroduced into UIF07.

The correction preserves these boundaries:

- Supplier return is source-authorized; Theme 7 does not add a second commercial approval.
- `RTV_PENDING` removes availability only; physical/value reduction occurs only at actual supplier handover.
- Warehouse verification does not rewrite source-authorized quantity.
- LOT mismatch is a blocker, not a silent substitution.
- Product + UOM may contain 1..N LOT allocations; different UOMs remain distinct.
- Source changes invalidate only affected verification evidence; unaffected evidence is preserved.
- Waiting/source-owned tasks remain read-only from the warehouse execution queue.
- Final handover is one explicit commit surface, with a source freshness check before commit.
- Final result has safe navigation and does not return to a consumed commit screen.
- `UNKNOWN` does not blind-retry the mutation and does not expose technical recovery identifiers in Product UI.

## 6. Non-semantic inherited formatting repair

`know-how/decisions/decision-register.md` contained an inherited malformed Markdown table boundary around DR113/DR046. The table formatting was repaired while inserting the BJ07 decision rows so the register remains machine/readable. This repair does **not** change the semantic content or status of the inherited decisions.

## 7. Isolation conclusion

**PASS.** v1.3.9 is a cumulative child of v1.3.8, changes the intended BJ07/UIF07 correction surface plus necessary shared registries/renderer metadata, introduces no parent-file removal, preserves frozen BJ05/BJ06 evidence, and passes shared-renderer regression gates.
