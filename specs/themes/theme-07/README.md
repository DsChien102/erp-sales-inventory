---
id: T07-README
type: theme-readme
theme: theme-07
title: "Theme 07 — Kho & Giá vốn"
owner: BA/SA
status: FROZEN
version: v4.5.1
parent: v4.5.0
source_baseline: v4.5.0
semantic_delta: KNOW_HOW_TRACEABILITY_COMPLETION_NO_BUSINESS_SEMANTIC_CHANGE
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

Bản **v4.5.1** là cumulative patch trực tiếp trên **v4.5.0** để hoàn thiện truy vết tri thức. Bản này **không thay đổi quyết định nghiệp vụ, Business Journey flow, Use Case behavior, UI Flow, Screen Contract, action, state machine hoặc prototype**.

Các thay đổi chính của v4.5.1:

- 17/17 Business Journey có liên kết trực tiếp tới **Bài tri thức cốt lõi** trong mục `Truy vết`.
- 14 Use Case trước đây chưa có Know-how đã được bổ sung, đưa coverage lên **64/64 UC có `Bài tri thức liên quan`**.
- `00-business-journey-map.md` có ma trận **BJ ↔ Know-how** phân biệt `Cốt lõi` và `Hỗ trợ`; toàn bộ **45/45 bài Know-how** được phân loại ít nhất một lần.
- `01.knowledge/know-how/00-table-of-contents.md` có đường tra ngược từ Business Journey sang Know-how.
- Không sửa nội dung rule của 45 bài Know-how; không thay đổi artifact UI/prototype. Bằng chứng visual/runtime của v4.5.0 được carry-forward vì phạm vi design/prototype byte-identical.

### 6.1 Gate của v4.5.1

- BJ → Know-how core: **17/17 PASS**.
- UC → Know-how: **64/64 PASS**.
- Know-how coverage trong BJ map: **45/45 PASS** (`Cốt lõi` hoặc `Hỗ trợ`).
- Relative link validation cho toàn package: xem evidence v4.5.1 tại `06.evidence/`.
- Semantic immutability ngoài traceability: **PASS** theo package diff; không có thay đổi UI/prototype.
- Visual/runtime evidence: carry-forward từ **v4.5.0**; không tuyên bố chạy lại visual QA khi không có thay đổi design/prototype.

### 6.2 Thứ tự đọc đề xuất

1. Đọc `BJ-*` để hiểu mục tiêu và ranh giới nghiệp vụ.
2. Từ mục `Truy vết` của BJ, mở các **Bài tri thức cốt lõi** để hiểu bối cảnh và khái niệm nền.
3. Mở `UC-*` để xem hành vi chi tiết và các bài Know-how bổ sung theo từng Use Case.
4. Mở `UIF-*` từ liên kết trong BJ để xem luồng màn hình.
5. Mở `SCR-*` để xem nội dung, trạng thái, hành động và DS mapping của từng màn.
6. Chạy `03.design/prototype/html/index.html` để kiểm chứng tương tác khi cần.
7. Dùng evidence v4.5.1 tại `06.evidence/` cho traceability/release patch; dùng evidence v4.5.0 cho visual/runtime carry-forward.

### 6.3 Nguồn canonical để tiếp tục

- Quyết định: `01.knowledge/decisions/decision-register.md`
- Know-how: `01.knowledge/know-how/`
- Business Journey: `02.specification/behavior/journeys/`
- Use Case: `02.specification/behavior/use-cases/`
- UI Flow: `03.design/flows/`
- Screen Contract: `03.design/screens/`
- Domain/Entity/BC/Technical Contract: `02.specification/`
- HTML prototype: `03.design/prototype/html/`
- Release evidence: `06.evidence/`
