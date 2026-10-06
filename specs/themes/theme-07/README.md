---
id: T07-README
type: theme-readme
theme: theme-07
title: "Theme 07 — Kho & Giá vốn"
owner: BA/SA
status: FROZEN
version: v4.6.8
parent: v4.6.7
source_baseline: v4.6.7
semantic_delta: BJ02_DESIGN_STATE_CLEANUP
structure_baseline: V45-Theme-skeleton
---
# T07 — Theme 07 — Kho & Giá vốn

## 1. Mục đích

SRS xác định một lõi tồn kho và giá vốn đủ giá trị để cửa hàng thú y vận hành ngay, đồng thời không khóa kiến trúc vào một cửa hàng hoặc một kho mãi mãi. Tài liệu là nguồn làm căn cứ cho phân tích, thiết kế dữ liệu, hành vi, prototype UI, API/event, kiểm thử và nghiệm thu.

Hệ thống phải trả lời nhất quán năm câu hỏi:

1. Có bao nhiêu hàng vật lý, ở trạng thái nào và thuộc lô nào?
2. Bao nhiêu hàng đang đủ điều kiện bán và bao nhiêu đã được giữ?
3. Operation nào đã làm số lượng hoặc giá trị thay đổi?
4. Giá vốn chính thức, giá trị ghi sổ và điều chỉnh cuối kỳ được hình thành ra sao?
5. Dữ liệu nào là sự thật kế toán, dữ liệu nào chỉ là giả định hoặc tham chiếu định giá bán?

## 2. Phạm vi

### 2.1 Trong phạm vi

| Cụm | Năng lực |
|---|---|
| Tổ chức | Một cửa hàng, một kho mặc định; nhiều người dùng trực tuyến; scope kho trên mọi mutation |
| Nhập hàng | Nhận theo chứng từ hoặc nhập nhanh được phép; nhập nhanh đủ dữ liệu luôn vào `PENDING_APPROVAL`, không hỏi có cần duyệt và không đi thẳng `READY`; nhận từng phần; ghi chênh lệch giao nhận; lượng hàng thuộc quyền sở hữu đi vào đúng trạng thái vật lý và trục định giá `VALUATION_PENDING`; BJ03 xác lập giá trị nhập ban đầu bằng nghiệp vụ riêng |
| Theo dõi | Sản phẩm `NONE` hoặc `LOT`; lô nhà sản xuất; ngày sản xuất tùy chọn; hạn dùng theo cấu hình |
| Bán hàng | Query khả dụng; giữ hàng cho sỉ/online; POS online xuất trong checkout; FEFO/FIFO; bàn giao mới giảm vật lý |
| Trả/xử lý | Khách trả, phân loại, trả nhà cung cấp, cách ly, demo, hỏng, hết hạn, tiêu hủy |
| Kiểm kê | Toàn kho/từng phần; predicate + key snapshot; khóa cả key tương lai trong phạm vi; đếm mù; đếm lại; duyệt/hủy; adjustment |
| Sửa sai | Cancellation trước xử lý, reversal/correction sau hoàn tất; không sửa ledger hoặc operation lịch sử |
| Giá vốn | Value ledger; bình quân liên hoàn và cuối kỳ; official cost version; chốt kỳ; COGS true-up; điều chỉnh giá trị hàng nhập |
| Mở đầu | Trạng thái kích hoạt `PREPARING`; chuẩn bị/validate opening batch, duyệt độc lập, commit, báo cáo migration và chuyển nguyên tử sang `ACTIVE` |
| Chính sách tồn sản phẩm | Threshold/target; ngưỡng cận hạn mặc định và ghi đè theo sản phẩm; hành động `WARN`/`BLOCK_SALE`; chỉ báo dẫn xuất |
| Quản trị | RBAC + warehouse scope; che dữ liệu tài chính; phê duyệt theo rủi ro; audit |
| Tin cậy | Idempotency cho mọi mutation bằng idempotency record, source version, atomic commit, `UNKNOWN`, transactional outbox, reconciliation/rebuild |
| Liên miền | Kịch bản chiết khấu mua hàng theo kỳ; handoff pricing cost basis; rà soát cuối kỳ; ba cách nhìn lợi nhuận |

### 2.2 Ngoài phạm vi

- Bin/kệ/vị trí chi tiết.
- Hàng ký gửi, giữ hộ, `CUSTODY_ONLY` và tồn thuộc bên thứ ba.
- Chuyển đổi giữa SKU, repack, BOM hoặc sản xuất.
- Tự động tạo đơn mua hoặc proposal bổ sung có lifecycle.
- Sửa trực tiếp số dư, trạng thái, ledger, giá trị hoặc kết quả operation.
- Định nghĩa promotion, công bố giá bán, hạch toán công nợ và quyết định pháp lý về chuyển quyền sở hữu.

## 3. Sơ đồ tổng quan

- Business Journey canonical: `BJ-01` … `BJ-17`.
- Domain sở hữu: `DOM-IO`, `DOM-IC`, `DOM-IV`; quy tắc dùng chung tại `DOM-COM`.
- Chi tiết: [Overview](02.specification/overview/overview.md).

## 4. Điểm bắt đầu theo vai trò

- **BA:** `01.knowledge/` → `02.specification/` → `03.design/`.
- **SA:** `02.specification/domain/` + UC/BC. Contract của outcome nằm trong work slice lúc review để implement.
- **SE:** `04.harness/` và các nguồn được Slice tham chiếu.
- **QA/Harness:** `09.generated/`.

## 5. Tài liệu chính

- [Decision Register](01.knowledge/decisions/decision-register.md)
- [Glossary](01.knowledge/glossary/glossary.md)
- [Theme Overview](02.specification/overview/overview.md)
- [Business Journey Map](02.specification/behavior/journeys/00-business-journey-map.md)
- [Prototype manifest](03.design/prototype/README.md)

## 6. Trạng thái hiện tại

- **v4.6.8:** Design state cleanup cho BJ02; state model của `SCR-008/SCR-010` và generated runtime-state registry khớp trực tiếp source design, không còn state Quick cũ và không cần runtime filter.
- **v4.6.7:** nhập hàng nhanh vẫn no-draft nhưng **không còn `APPROVAL_PRICE_BASIS_REQUIRED` tại BJ02**; submit không yêu cầu price/FX basis, chỉ giữ `APPROVER_CONFIGURATION_MISSING` cho lỗi cấu hình người duyệt.
- **v4.6.6:** UC-02-02 không có `DRAFT`; nhập hàng nhanh chỉ sống trong phiên UI trước submit, create-and-submit hợp lệ mới tạo goods receipt ở `PENDING_APPROVAL`; `BC-IO-16/API-C-25` không áp dụng.

### 6.1 Phạm vi thay đổi v4.6.8

- Không thay đổi nghiệp vụ so với v4.6.7; chỉ làm sạch design/runtime-state registry của BJ02.
- `SCR-010` canonical chỉ còn `READY`, `VALIDATION_ERROR`, `APPROVAL_REQUIRED`, `PERMISSION_DENIED`, `PENDING_APPROVAL`, `APPROVER_CONFIGURATION_MISSING`, `FINANCIAL_MASKED`.
- `SCR-008` không còn state draft legacy trong generated registry.
- Bỏ runtime filter phòng thủ; workbench, manifest và generated registry cùng một nguồn state canonical.
- `PRICE_BASIS_REQUIRED` của BJ10 không thay đổi.

### 6.2 Phạm vi thay đổi v4.6.7

- Chỉ sửa semantic nhập hàng nhanh/BJ02 và các contract/UI/harness dẫn xuất; `UC-02-01` không thay đổi.
- Bỏ `APPROVAL_PRICE_BASIS_REQUIRED` khỏi UC-02-02, BC-IC-07, API-C-26 Quick branch, SCR-010 và runtime state của BJ02.
- nhập hàng nhanh payload không mang price/FX basis; thiếu price/FX không chặn tạo goods receipt ở `PENDING_APPROVAL`.
- `APPROVER_CONFIGURATION_MISSING` vẫn chặn tạo goods receipt khi không resolve được approver theo policy nhập hàng nhanh.
- Price/FX tiếp tục thuộc BJ03/BJ13 theo authority hiện hành.

### 6.3 Phạm vi thay đổi v4.6.6

- Chỉ thay đổi semantic của **UC-02-02 — Nhập hàng nhanh** và các contract/trace/UI/harness dẫn xuất bắt buộc; **UC-02-01 — Nhận theo chứng từ giữ nguyên**.
- `SCR-008 → SCR-009 → SCR-084 → SCR-010` của nhập hàng nhanh chỉ dùng session memory; rời flow, refresh hoặc đóng app thì mất dữ liệu chưa gửi.
- Submit nhập hàng nhanh là một lệnh create-and-submit mang full payload + `idempotencyKey`; success mới tạo `GoodsReceipt`, `ApprovalCase`, `receiptId` và trạng thái đầu `PENDING_APPROVAL`.
- Rejection trước create không để lại goods receipt. Theo v4.6.7, `APPROVAL_PRICE_BASIS_REQUIRED` đã bị loại khỏi nhập hàng nhanh; `APPROVER_CONFIGURATION_MISSING` được giữ. Nhánh Quick không dùng `DRAFT_VALIDATION_FAILED`, `OPERATION_NOT_DRAFT` hoặc `DRAFT_*`.
- `BC-IO-16` / `API-C-25` vẫn tồn tại cho lifecycle có draft nhưng bị loại khỏi nhập hàng nhanh.

### 6.4 Phạm vi kiểm tra v4.6.4

- Tập trung `BJ-02 — Nhận hàng mua`; các BJ khác giữ nguyên baseline trước đó.
- `SCR-010/PENDING_APPROVAL` có CTA **Về Kho**; Back cũng quay về Hub Kho và không mở lại editor của submitted revision.
- Hub Kho candidate đưa **Nhận hàng chờ phê duyệt** lên đầu `Cần chú ý` và có worklist để mở lại yêu cầu đang chờ.
- Người có quyền duyệt mở `SCR-011`; người chỉ có quyền xem chỉ được xem goods receipt đã gửi read-only theo capability contract.
- Runtime/visual QA mới nằm tại `03.design/prototype/html/qa/WAREHOUSE-HUB-BJ02-CONTINUITY-QA-v4.6.4.*`.

### 6.5 Phạm vi kiểm tra v4.6.0

- `T7-DR-196` — UI định giá chỉ làm việc với giá trị VND đã chuẩn hóa.
- `T7-DR-197` — Căn cứ giá trực tiếp Phase 1 có nguồn có thẩm quyền, ngày căn cứ và bằng chứng tách biệt.
- `T7-DR-198` — Công thức và điều kiện hợp lệ của phân bổ BJ13.
- `T7-DR-199` — Phạm vi chốt kỳ BJ14 do policy cấp tenant cho phép.
- `SCR-008` — Xác định header của một lần nhập nhanh trước khi ghi hàng thực nhận. Màn này chỉ xử lý nhà cung cấp, kho mặc định, ngày nhận và chứng từ giao nhận; Product/UOM/LOT/quantity nằm ở `SCR-009/SCR-084`.
- `SCR-015` — Làm việc với các Product/UOM còn `VALUATION_PENDING`, hiểu căn cứ đang dùng và chọn các dòng đủ điều kiện để xác nhận giá trị ban đầu. Màn này là **workspace**, không phải màn rà soát cuối.
- `SCR-017` — Cho kế toán kiểm tra **toàn bộ phạm vi sắp ghi** trước mutation. Đây là summary review, không lặp lại workspace `SCR-015`.
- `SCR-086` — Giúp kế toán hiểu nguồn điều chỉnh, phạm vi source-owned, chọn **một phương pháp phân bổ hợp lệ**, xem được vì sao từng Product nhận số tiền đó và xác nhận ghi adjustment.
- `SCR-089` — Thông báo finality của adjustment. Result screen ưu tiên kết quả nghiệp vụ, không lặp lại toàn bộ preview.
- `SCR-074` — Một bề mặt cho setup → calculating → blocked/ready → xác nhận publication. `SCR-073/075/076` là alias/retired state, không phải active screen riêng.
- `SCR-077` — Cho biết publication đã có hiệu lực và **phần chênh lệch nào thực sự được ghi**.

### 6.5 Các điểm giao diện đã đồng bộ

- Prototype HTML hiện hành dùng `v460-semantic-ux.css/js` làm lớp semantic/UX cuối cùng.
- `SCR-088` không còn là active route; legacy/deep-link hội tụ về `SCR-086`.
- BJ13 không chia đều khi metric không hợp lệ; preview bị chặn theo `T7-DR-198`.
- BJ03/BJ13 không hiển thị hoặc yêu cầu người dùng nhập tỷ giá; UI chỉ dùng giá trị VND đã chuẩn hóa.
- BJ14 đọc phương pháp và phạm vi chốt kỳ từ tenant policy; UI không hard-code lựa chọn theo run.

### 6.5 Nguồn canonical để tiếp tục

- Quyết định: `01.knowledge/decisions/decision-register.md`
- Know-how: `01.knowledge/know-how/`
- Business Journey: `02.specification/behavior/journeys/`
- Use Case: `02.specification/behavior/use-cases/`
- UI Flow: `03.design/flows/`
- Screen Contract: `03.design/screens/`
- Domain/Entity/BC: `02.specification/`
- HTML prototype: `03.design/prototype/html/`
