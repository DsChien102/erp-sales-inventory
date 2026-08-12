# BJ06 Deep Review QA — v3.9.4

**Result: PASS · 40/40**

Scope: approved Wave 2 / BJ06 decisions T7-DR-131..137, Atomic Change Set propagation, runtime verification and fresh-eye review.

- PASS — Runtime package identifies v3.9.4
- PASS — WAITING request row is status-only and disabled: `RET-260827-07
Nhà thuốc thú y Hòa Bình · SO-260820-08
Chờ duyệt lô`
- PASS — WAITING request cannot reopen editing flow: `('SCR-030', 'SCR-030')`
- PASS — ReturnExchangeLine current authorization is the input max
- PASS — Transaction UOM precision is carried to quantity input: `1`
- PASS — Declared return condition is read-only comparison context
- PASS — Physical partial receipt line can be verified below authorization: `{'qty': 2, 'verified': True, 'max': 3, 'remaining': 4}`
- PASS — Wrong-LOT defaults to the approved minimal reason taxonomy
- PASS — Unknown/new LOT progressively requests LOT attributes
- PASS — Evidence is bound by id/version/content hash (SHA-256 when secure context is available): `{'id': 'EV-RET-L1A-001', 'version': 1, 'hash': 'fnv1a:21e9a932'}`
- PASS — New LOT required expiry blocks save until attribute completion
- PASS — New LOT becomes eligible after required expiry is supplied
- PASS — One receipt operation supports concurrent LINE_EXCEPTION cases
- PASS — Approver sees maker/source/order/product/UOM/qty/LOT/reason/evidence
- PASS — Raw approval case ID/hash are not default Product UI
- PASS — Changing approval evidence supersedes prior case/snapshot: `{'status': 'SUPERSEDED', 'current': None}`
- PASS — Expired LOT is system-derived for the whole line
- PASS — Expired line cannot be split into sellable/quarantine/damaged: `{'sellable': 0, 'quarantine': 0, 'damaged': 0, 'expired': 4}`
- PASS — Non-expired classification has exactly three user inputs: `['sellable', 'quarantine', 'damaged']`
- PASS — EXPIRED has no editable input on non-expired line: `['sellable', 'quarantine', 'damaged']`
- PASS — Routine physical classification needs no reason/evidence/approval
- PASS — Completed result uses source request/order and authoritative classified timestamp
- PASS — Result does not invent a return-receipt business number
- PASS — UNKNOWN prohibits blind retry and exposes verification handoff
- PASS — UNKNOWN handoff carries exact same operation identity: `('IO-CRET-001', 'IO-CRET-001')`
- PASS — UNKNOWN transitions to BJ17 recovery flow: `{'flow': 'UIF-17', 'screen': 'SCR-079'}`
- PASS — Representative runtime has no horizontal overflow: `{'sw': 402, 'cw': 402}`
- PASS — No browser page errors: `[]`
- PASS — No browser console errors: `[]`
- PASS — Decision register contains approved BJ06 locks T7-DR-131..137
- PASS — ApprovalCase supports OPERATION and LINE_EXCEPTION subject scope
- PASS — BC-IO-07 binds physical receipt to current authorized return quantity
- PASS — BC-IO-08 makes expiry system-derived and routine classification approval-free
- PASS — BC-IC-06 supports per-line immutable approval subject hash
- PASS — UIF-06 documents same-operation UNKNOWN recovery and no blind retry
- PASS — Runtime reason taxonomy excludes source-integrity blockers from approvable reasons
- PASS — Runtime evidence contract uses SHA-256 content binding
- PASS — BJ06 current screens carry v3.9.4 deep-review trace
- PASS — Current workbench/result contract contains no synthetic RR receipt identity
- PASS — Presentation registries identify v3.9.4

## Captures

- `01-SCR030-WAITING-READONLY.png` — Waiting return request is visible but non-actionable
- `02-SCR032-AUTHORIZED-PARTIAL.png` — Current authorization and declared condition remain clear at line verification
- `03-SCR032-NEW-LOT-EVIDENCE.png` — New LOT completion and content-bound evidence for wrong-LOT approval
- `04-SCR034-BUSINESS-EVIDENCE.png` — Approver decision surface is business-evidence-first
- `05-SCR033-SYSTEM-EXPIRED.png` — Expired quantity is a system fact, not a user allocation input
- `06-SCR035-SOURCE-KEYED-RESULT.png` — Completed result is keyed by source return request and SalesOrder
