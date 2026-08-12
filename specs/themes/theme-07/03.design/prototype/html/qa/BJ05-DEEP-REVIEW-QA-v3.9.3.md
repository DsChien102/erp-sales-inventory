# BJ05 Deep Review QA — v3.9.3

**Result: PASS · 22/22**

Scope: approved Wave 2 / BJ05 semantic hardening and fresh-eye runtime verification.

- PASS — Runtime package identifies v3.9.3
- PASS — Product context does not badge raw remaining quantity
- PASS — Pick input uses quantity precision contract
- PASS — LOT candidates use server pickable quantity and preserve expiry precision
- PASS — Changing LOT creates structured pending physical correction: `{'kind': 'MANUAL', 'status': 'PENDING', 'oldLot': 'DH2507', 'returnQty': 4, 'newLot': 'DH2511', 'repickQty': 4, 'actor': None, 'confirmedAt': None}`
- PASS — Entering picked quantity does not auto-clear physical correction
- PASS — Explicit correction confirmation records actor and time
- PASS — Partial handover increments consumed without shrinking allocated/picked/requested
- PASS — Handover writes immutable evidence identity/actor/source/allocation version
- PASS — Result shows authoritative handover timestamp
- PASS — UNKNOWN marks fulfillment VERIFYING and preserves exact operation identity
- PASS — VERIFYING queue row is non-actionable and distinct from waiting: `SO-260827-21
Đại lý An Phú · Kho chính
Đang xác minh bàn giao`
- PASS — VERIFYING order cannot reopen pick/handover: `('SCR-025', 'SCR-025')`
- PASS — Representative runtime has no horizontal overflow: `{'sw': 402, 'cw': 402}`
- PASS — No browser errors: `[]`
- PASS — Decision register contains BJ05 locks T7-DR-122..130
- PASS — PickAllocation stores allocated/picked/consumed separately
- PASS — HandoverEvidence is an explicit immutable entity
- PASS — Behavioral contract prohibits rewriting pick/allocation history
- PASS — Runtime no longer mutates legacy required/qty/picked fields in BJ05
- PASS — UIF-05 documents UNKNOWN verification lock
- PASS — Integrated Warehouse Home patch freezes the verifying pick task

## Captures

- `01-SCR027-LOT-PICKABLE-PRECISION.png` — LOT candidate uses server pickable quantity and original expiry precision
- `02-SCR027-PHYSICAL-CORRECTION.png` — Physical correction requires explicit actor assertion
- `03-SCR029-PARTIAL-IMMUTABLE.png` — Partial handover result includes authoritative handover timestamp
- `04-SCR029-UNKNOWN-VERIFYING.png` — UNKNOWN freezes handover finality
- `05-SCR025-VERIFYING-NONACTIONABLE.png` — Verification task is disabled in BJ05 queue
