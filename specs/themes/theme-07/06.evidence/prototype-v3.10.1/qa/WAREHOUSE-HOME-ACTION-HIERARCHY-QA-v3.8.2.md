# Warehouse Home Action Hierarchy QA — v3.8.2

**Result: PASS · 21/21 PASS**

- `Tạo thao tác` is no longer a standalone primary CTA after Tra cứu.
- The action is Secondary and sits in the `Việc của bạn` work context alongside task disclosure.
- Tra cứu and `Tất cả chức năng kho` stay below the work context; full catalog discoverability remains unchanged.

## Checks

- PASS — runtime version
- PASS — two workbench modes preserved
- PASS — Warehouse Home remains task-driven
- PASS — work queue remains first decision section
- PASS — standalone primary create section removed
- PASS — exactly one Create action remains
- PASS — Create action moved into work context
- PASS — Create action is Secondary, not Primary
- PASS — task disclosure and Create action share one action row
- PASS — Tra cứu remains below work context
- PASS — full-function catalog remains after Tra cứu
- PASS — Create sheet opens from new placement
- PASS — Create sheet still has four user-initiated actions
- PASS — Create sheet still has no redundant Close CTA
- PASS — Escape dismisses Create sheet
- PASS — work expansion shows all five tasks
- PASS — Create remains in work action row after re-render
- PASS — secondary catalog still exposes all 17 BJ + CAP-01
- PASS — canonical 402x874 product / 418x890 review frame preserved
- PASS — Warehouse Home has no horizontal overflow
- PASS — no browser page errors
