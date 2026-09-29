# CATALOG — BJ-xx harness (sample)

SSOT `design_status` cho các Work Slice trong thư mục này. **Không** ghi status trên file slice.  
Sample minh họa — `NON_CANONICAL_EXAMPLE`. Schema: `.agents/skills/to-work-slices/reference.md`.

| id | title | path | design_status | depends_on | sources | family | produces / coverage | lanes / links | blocked_reason |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SL-001 | Khóa ranh giới InventoryOperation | SL-001-inventory-operation-boundary.md | DRAFT | | DOM-IO, ENT-IO-01, AGG-IO-01, BC-IO-16, FND-01 | | AGG-IO-01 boundary | full | |
| SL-002 | Quick receipt — application contract | SL-002-quick-receipt.be-contract.md | DRAFT | SL-001 | BJ-02, UC-02-02, BC-IO-16, BC-IC-07, SCR-009, FND-01 | quick-receipt | Command/Query/DTO + fake | be-contract | |
| SL-003 | Quick receipt — BE impl | SL-003-quick-receipt.be-impl.md | DRAFT | SL-002 | UC-02-02, FND-01, AGG-IO-01 | quick-receipt | RPC / persistence | be-impl | |
| SL-004 | Quick receipt — FE | SL-004-quick-receipt.fe.md | DRAFT | SL-002 | UC-02-02, SCR-009 | quick-receipt | SCR-009 quick mode | fe | |
| SL-005 | Quick receipt — E2E | SL-005-quick-receipt.e2e.md | DRAFT | SL-003, SL-004 | UC-02-02, SCR-009 | quick-receipt | BF/AS xuyên tầng | e2e | |

`READY_TO_IMPLEMENT` chỉ khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.  
Coverage = phạm vi dự kiến, không phải bằng chứng hoàn thành.
