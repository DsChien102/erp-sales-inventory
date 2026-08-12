# BJ-02 Runtime / Render Smoke v0.2.9

**Result: 78/78 PASS**

Runs the real BJ-02 renderer in headless Chromium by injecting the self-contained workbench into an `about:blank` target.

## Checks

- [x] workbench boots UIF-02
- [x] mobile frame 402x874 — [402, 874]
- [x] SCR-006 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] SCR-006 permission uses centered empty state
- [x] SCR-007 has document search
- [x] SCR-007 has two document cards
- [x] document search filters by supplier — 1
- [x] document search no-result uses VEmptyState
- [x] document search clear restores results
- [x] SCR-007 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] Document overview exposes both source products
- [x] SCR-009 has primary and secondary hierarchy
- [x] SCR-009 no compressed lot text in primary line initially
- [x] SCR-009 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] SCR-009 read-only hides Quick mutation and disables review
- [x] read-only opens detail for viewing
- [x] SCR-084 true read-only has no editable inputs — 0
- [x] SCR-084 true read-only hides mutation actions
- [x] Document UOM appears only in product identity, no select
- [x] Orphan Theo chứng từ copy removed
- [x] LOT source context says Còn chờ nhận
- [x] LOT derived total starts at 0/120
- [x] Initial lot is open
- [x] existing exception UI shows computed accepted
- [x] partial Document shows remaining info
- [x] derived total updates live
- [x] Add lot appends second lot
- [x] New lot opens and prior collapses
- [x] Delete is inside expanded content not header
- [x] Exact Document quantity suppresses variance banner
- [x] Derived total exact is 120/120
- [x] User can manually open previous lot
- [x] Existing exceptions auto-expand after reopen
- [x] Document over-source shows warning
- [x] Not received after entered data opens VConfirmDialog
- [x] SCR-084 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] Save line returns to overview
- [x] Zero untouched document line marks not received directly
- [x] Overview shows 2/2 handled
- [x] Review CTA enabled when every source item handled
- [x] SCR-010 shows actual LOT code and expiry
- [x] SCR-010 result includes handled-zero line without false received wording
- [x] SCR-010 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] Quick note has no redundant optional copy
- [x] Unresolved supplier shows inline guidance
- [x] Supplier search result has code and phone
- [x] Quick Continue enables after valid header
- [x] Quick overview starts empty with add action
- [x] Product search result is compact discriminator
- [x] Quick multi-UOM asks UOM only at new-item step
- [x] Quick UOM select collapses after choice
- [x] Quick saved item appears in overview
- [x] Duplicate Product+UOM shows blocker and open-existing CTA
- [x] Duplicate Product+UOM does not render LOT editor
- [x] Open-existing returns to existing item editor
- [x] Opening a completed item then Back does not demote its status
- [x] Quick mandatory approval uses info banner
- [x] Quick Review shows note only when present
- [x] Quick Review shows lot identity
- [x] Approver gets receiving context
- [x] Approver gets request summary
- [x] Approver gets actual lot evidence
- [x] Quick approval reason is info not warning
- [x] Approver only has approve/reject decision CTAs
- [x] SCR-011 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] Completed result uses Kết quả theo mục hàng
- [x] Completed result includes lot identity
- [x] Completed does not show valuation-pending banner
- [x] Valuation-pending state shows info banner only when relevant
- [x] SCR-012 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] Unknown recovery uses one loading message
- [x] Unknown recovery avoids duplicate warning banner
- [x] Recovery removes technical operation/movement/approval IDs
- [x] Recovery keeps one useful receipt reference
- [x] Recovery EMPTY uses user-facing VEmptyState
- [x] Recovery EMPTY has no warning banner
- [x] Recovery STALE retains query-only warning/refresh
- [x] SCR-013 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}

## Boundary

- Exercises real DOM/layout and representative end-user interactions on the 402 × 874 product viewport.
- Validates search, multi-product overview, true read-only, multi-LOT, quantity variance, Quick duplicate guard, review/approval context, result and recovery semantics.
- Does not claim pixel parity against the external Vercel Flutter reference.
