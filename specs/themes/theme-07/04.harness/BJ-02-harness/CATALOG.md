# CATALOG — BJ-02 harness

SSOT `design_status` cho Work Slice của [BJ-02](../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md). Không ghi status trên file slice.
Schema: [reference.md](../../../../../.agents/skills/to-work-slices/reference.md).

`document-receipt` không có file: chờ Theme 10. Card «Nhận theo chứng từ» nằm trên SCR-006 và thuộc SL-002. Card không mở SCR-007.

| id | title | design_status | depends_on | usecase | blocked_reason |
| --- | --- | --- | --- | --- | --- |
| SL-001 | Nhận theo chứng từ | BLOCKED | | [UC-02-01](../../02.specification/behavior/use-cases/UC-02-01-chuan-bi-nhan-theo-chung-tu.md) | Chờ Theme 10 cung cấp chứng từ nguồn. Không mở SCR-007. |
| [SL-002](SL-002-quick-receipt.md) | Gửi phiếu nhận nhanh | IN_REVIEW | SL-006 | [UC-02-02](../../02.specification/behavior/use-cases/UC-02-02-chuan-bi-nhap-hang-nhanh.md) | |
| [SL-003](SL-003-receipt-approval.md) | Phê duyệt phiếu nhận | IN_REVIEW | SL-002 | [UC-02-03](../../02.specification/behavior/use-cases/UC-02-03-phe-duyet-yeu-cau-nhan-hang.md) | |
| [SL-004](SL-004-physical-receipt.md) | Ghi nhận tồn vật lý | IN_REVIEW | SL-003 | [UC-02-04](../../02.specification/behavior/use-cases/UC-02-04-ghi-nhan-hang-vao-ton-vat-ly.md) | |
| [SL-005](SL-005-receipt-finality.md) | Tra cứu finality phiếu nhận | IN_REVIEW | SL-004 | [UC-02-05](../../02.specification/behavior/use-cases/UC-02-05-truy-van-va-phuc-hoi-ngan-ket-qua-nhan-hang.md) | |
| [SL-006](SL-006-default-warehouse.md) | Thiết lập cặp cửa hàng/kho mặc định | READY_TO_IMPLEMENT | | | |

`READY_TO_IMPLEMENT` chỉ khi mọi `depends_on` đã `READY_TO_IMPLEMENT` hoặc `VERIFIED`.
