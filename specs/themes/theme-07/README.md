---
id: T07-README
type: theme-readme
theme: theme-07
title: "Theme 07 — Kho & Giá vốn"
owner: BA/SA
status: FROZEN
version: v3.12.0
parent: v3.11.0
source_baseline: v3.11.0
semantic_delta: BJ_UC_V5_AND_VALUATION_SEMANTIC_ALIGNMENT
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
| Tin cậy | Idempotency cho mọi mutation bằng `CommandReceipt`, source version, atomic commit, `UNKNOWN`, transactional outbox, reconciliation/rebuild |
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
- **SA:** `02.specification/domain/` + UC/BC → `02.specification/domain/` + `02.specification/technical-contracts/`.
- **SE:** `04.harness/` và các nguồn được Slice tham chiếu.
- **QA/Harness:** `06.evidence/` + `09.generated/`.

## 5. Tài liệu chính

- [Decision Register](01.knowledge/decisions/decision-register.md)
- [Glossary](01.knowledge/glossary/glossary.md)
- [Theme Overview](02.specification/overview/overview.md)
- [Business Journey Map](02.specification/behavior/journeys/00-business-journey-map.md)
- [Prototype manifest](03.design/prototype/README.md)
- [Architecture foundation](02.specification/technical-contracts/FND-TECH-01.md)

## 6. Trạng thái hiện tại

Bản **v3.12.0** kế thừa nguyên vẹn cây thư mục mới của **v3.11.0** và là baseline semantic/specification mới cho Theme 7. Lần cập nhật này không sửa HTML prototype.

Các thay đổi canonical:

- Toàn bộ **17 Business Journey** được rewrite theo BJ template v5.
- Toàn bộ Use Case được chuẩn hóa theo UC template v5; danh mục canonical hiện có **64 UC**. Các UC lịch sử của BJ03/BJ13/BJ14 được hợp nhất theo mục tiêu nghiệp vụ và commit point, có migration ledger trong `00-use-case-map.md`.
- Cụm định giá được khóa lại: `BJ03 — Xác lập giá trị nhập ban đầu` → `BJ13 — Điều chỉnh giá trị hàng nhập` → `BJ14 — Tính và công bố giá vốn`.
- BJ03 không tạo `OfficialCostVersion`; BJ14 là owner duy nhất của giá vốn chính thức. Phương pháp công bố lấy từ chính sách cấp tenant, không chọn lại theo từng lần tính.
- Nhập hàng nhanh phải hoàn tất BJ03 mà không phụ thuộc Theme 10; nhận theo chứng từ có thể dùng nguồn thương mại do Theme 10 cung cấp.
- Domain/Entity `COM`, `IC`, `IV` đã được align theo template mới; `IO` giữ nội dung nâng cấp đã có từ source v3.11.0.
- Technical/Integration/Behavioral Contract liên quan được đồng bộ với semantic mới.
- Các Slice cũ bị ảnh hưởng bởi UC consolidation được remap về UC canonical nhưng vẫn giữ file carry-forward để không làm mất delivery history.

### 6.1 Giới hạn có chủ đích của v3.12.0

`03.design/` và HTML prototype vẫn là carry-forward từ v3.11.0. Vì BJ03/BJ13/BJ14 đã đổi semantic và một số UC được hợp nhất, **UI/HTML chưa đạt parity với specification v3.12.0**. Việc redesign Screen/UI contract và HTML được dành cho **v3.13.0**; prototype hiện hành không được dùng làm nguồn quyết định nghiệp vụ cho cụm valuation.

### 6.2 Nguồn canonical để tiếp tục

- Quyết định: `01.knowledge/decisions/decision-register.md`
- Business Journey: `02.specification/behavior/journeys/`
- Use Case: `02.specification/behavior/use-cases/`
- Domain/Entity/BC/Technical Contract: `02.specification/`
- Prototype hiện hành: chỉ dùng làm bằng chứng carry-forward để chuẩn bị lượt parity v3.13.0
