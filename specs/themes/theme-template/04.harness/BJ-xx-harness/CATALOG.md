# CATALOG — BJ-xx harness (sample)

SSOT `design_status` cho Work Slice trong thư mục này. Không ghi status trên file slice.
Sample minh họa. `NON_CANONICAL_EXAMPLE`. Schema: [reference.md](../../../../.agents/skills/to-work-slices/reference.md).

| id | title | design_status | depends_on | usecase | blocked_reason |
| --- | --- | --- | --- | --- | --- |
| [SL-001](SL-001-inventory-operation-boundary.md) | Khóa ranh giới InventoryOperation | DRAFT | | | |
| [SL-002](SL-002-quick-receipt.md) | Lập nhận hàng nhanh | DRAFT | SL-001 | [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02.sample.md) | |

`READY_TO_IMPLEMENT` chỉ khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.
