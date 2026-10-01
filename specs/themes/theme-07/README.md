---
id: T07-README
type: theme-readme
theme: theme-07
title: "Theme 07 — Kho & Giá vốn"
owner: BA/SA
status: FROZEN
version: v4.6.7
parent: v4.6.6
source_baseline: v4.6.6
semantic_delta: NAVIGATION_RATIONALE_ROLE_PROFILE_CONTRACT
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
- **QA/Harness:** `09.generated/`.

## 5. Tài liệu chính

- [Decision Register](01.knowledge/decisions/decision-register.md)
- [Glossary](01.knowledge/glossary/glossary.md)
- [Theme Overview](02.specification/overview/overview.md)
- [Business Journey Map](02.specification/behavior/journeys/00-business-journey-map.md)
- [Navigation & Information Architecture](03.design/patterns/PAT-NAV.md)
- [UI/UX policy](03.design/patterns/PAT-UI-UX.md)
- [Prototype manifest](03.design/prototype/README.md)
- [Architecture foundation](02.specification/technical-contracts/FND-TECH-01.md)

## 6. Trạng thái hiện tại

### 6.0 Lập luận điều hướng và Role Profile v4.6.7

- Bổ sung vào `PAT-NAV` các lập luận đã chốt về cách tổ chức Hub Kho: thiết kế cho trường hợp một người làm toàn bộ Kho, không dùng BJ làm menu, ưu tiên mục đích công việc, Search, quick action có chọn lọc, contextual action và `Cần chú ý` chỉ cho ngoại lệ.
- Chính thức hóa bốn Navigation Profile đang có trong prototype: `FULL`, `WAREHOUSE`, `ACCOUNTING`, `SALES`.
- Khóa rõ ba khái niệm khác nhau: **quyền**, **trách nhiệm**, **mức độ nổi bật trên điều hướng**. Navigation Profile không phải permission contract.
- `SCR-090` tham chiếu Navigation Profile và xác định rõ profile chỉ thay đổi cách trình bày Hub; destination và business flow không đổi.
- Chưa định nghĩa cơ chế tự động hợp nhất nhiều profile. Prototype vẫn mô phỏng một profile tại một thời điểm.
- Không thay đổi BJ, UC, UIF, business rule, permission, Screen Contract nghiệp vụ hoặc HTML prototype.

### 6.1 Mô phỏng vai trò theo BJ/UIF v4.6.6

- Bổ sung bộ điều khiển `Mô phỏng vai trò` trong tab **Theo BJ / UIF** của review workbench.
- Danh sách vai trò lấy trực tiếp từ trường `actors` của các Screen Contract đang có trong UIF; không tạo mapping vai trò mới.
- Khi đổi vai trò, workbench giữ màn hiện tại nếu màn đó đã khai báo actor tương ứng. Nếu không, workbench ưu tiên một màn hiện có chỉ thuộc actor đó; nếu không có thì dùng màn đầu tiên trong cùng UIF đã khai báo actor.
- Screen navigation vẫn hiển thị đầy đủ hành trình; các màn ngoài vai trò đang review chỉ được làm mờ để nhìn rõ handoff.
- Không thay đổi permission, quy tắc tách người yêu cầu/người duyệt, CTA, state transition, mutation, BJ, UC, UIF hoặc Screen Contract.
- Bộ role profile của Hub Kho từ v4.6.5 giữ nguyên và độc lập với mô phỏng actor trong tab Theo BJ / UIF.
- Evidence: `03.design/prototype/html/qa/BJ-ROLE-SIMULATION-QA-v4.6.6.*`.

### 6.2 Role-aware Hub prototype v4.6.5

- Bổ sung bộ điều khiển vai trò trong **review workbench** cho `Chủ cửa hàng`, `Thủ kho`, `Kế toán`, `Nhân viên bán hàng`.
- `Chủ cửa hàng` dùng profile `FULL`; ba role còn lại chỉ thay đổi quick action, `Cần chú ý`, thứ tự và visibility của workspace trên Hub Kho.
- Đây là **prototype candidate để review UX**, chưa phải permission contract và không thay thế RBAC.
- `PAT-NAV`, `SCR-090`–`SCR-096`, 17 BJ, 64 UC và 17 UIF không thay đổi trong v4.6.5.
- Evidence: `03.design/prototype/html/qa/WAREHOUSE-ROLE-PROFILES-QA-v4.6.5.*`.

### 6.3 Navigation / Information Architecture v4.6.4

- `PAT-NAV` là authority chính thức cho Hub Kho, workspace, quick action, contextual/exception/setup entry và destination mapping.
- Bổ sung `SCR-090`–`SCR-096` với `screen_class: NAVIGATION`; các screen này không có BJ/UC/UIF owner riêng.
- `PAT-UI-UX` cho phép hai tuyến trace: business screen theo BJ/UC/UIF và navigation screen theo `PAT-NAV → destination`.
- Không tạo BJ/UC/UIF giả cho việc mở menu hoặc chuyển workspace.
- Business Journey, Use Case và 17 UIF hiện hữu không thay đổi trong release này.
- HTML Hub Kho refined candidate v4.6.3 được dùng làm renderer tham chiếu cho các navigation screen mới; baseline cũ vẫn được giữ trong workbench để so sánh.


### 6.4 Phạm vi kiểm tra v4.6.0

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

### 6.6 Nguồn canonical để tiếp tục

- Quyết định: `01.knowledge/decisions/decision-register.md`
- Know-how: `01.knowledge/know-how/`
- Business Journey: `02.specification/behavior/journeys/`
- Use Case: `02.specification/behavior/use-cases/`
- UI Flow: `03.design/flows/`
- Screen Contract: `03.design/screens/`
- Domain/Entity/BC/Technical Contract: `02.specification/`
- HTML prototype: `03.design/prototype/html/`
