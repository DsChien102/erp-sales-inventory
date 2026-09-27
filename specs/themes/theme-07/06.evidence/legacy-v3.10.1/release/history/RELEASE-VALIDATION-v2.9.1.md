# RELEASE VALIDATION — v2.9.1

Parent: `v2.9.0`  
Status: **PASS · REVIEW READY**

## Scope

BJ07 correction only: queue homogeneity, Product+UOM versus LOT/allocation hierarchy, and handover/result evidence hierarchy. Business boundaries and prior migrated BJ behavior are preserved.

## What changed

- SCR-036 is one flat Navigation/Default collection. Work stage is a trailing badge; waiting is the same Navigation row in Disabled state.
- SCR-037 separates parent and child semantics: request context → Product+UOM structural heading → exact allocation Navigation rows.
- SCR-039/SCR-041 use concise context plus Product+UOM headings and grouped Key-value allocation evidence.
- No Theme-specific component was introduced. Live Figma DS remains the UI authority.

## Gates

- BJ07 Figma DS + UX QA: **PASS 52/52**
- All-flow runtime: **PASS 85/85**, 0 browser errors
- Prior migrated BJ regression: **PASS 23/23**
- BJ05 + BJ06 regression: **PASS 32/32**
- Device frame: **PASS 7/7**, 85 screens checked
- Review workbench fit: **PASS 3/3**
- Mobile prototype validator: **PASS**, 0 findings
- JavaScript syntax: **PASS** (`app.js`, `workbench-data.js`)
- Visual review: **PASS**, 9 BJ07 captures / 4 canonical screens

## Locked UX learning

A list stays a list: do not insert stage headings between records of one collection. A business parent (Product+UOM) and its child allocation (LOT/non-LOT) must not use the same visual weight. Final review and result surfaces should expose the minimum facts needed to scan and verify, not repeat cards or prose.
