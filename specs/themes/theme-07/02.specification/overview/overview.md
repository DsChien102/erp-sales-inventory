---
id: OVERVIEW
type: theme-overview
theme: theme-07
title: "Theme 07 — Kho & Giá vốn"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
# Tổng quan — Theme 07

## 1. Mục tiêu

### 2. Mục đích

SRS xác định một lõi tồn kho và giá vốn đủ giá trị để cửa hàng thú y vận hành ngay, đồng thời không khóa kiến trúc vào một cửa hàng hoặc một kho mãi mãi. Tài liệu là nguồn làm căn cứ cho phân tích, thiết kế dữ liệu, hành vi, prototype UI, API/event, kiểm thử và nghiệm thu.

Hệ thống phải trả lời nhất quán năm câu hỏi:

1. Có bao nhiêu hàng vật lý, ở trạng thái nào và thuộc lô nào?
2. Bao nhiêu hàng đang đủ điều kiện bán và bao nhiêu đã được giữ?
3. Operation nào đã làm số lượng hoặc giá trị thay đổi?
4. Giá vốn chính thức, giá trị ghi sổ và điều chỉnh cuối kỳ được hình thành ra sao?
5. Dữ liệu nào là sự thật kế toán, dữ liệu nào chỉ là giả định hoặc tham chiếu định giá bán?

### 3. Định hướng MVP và nguyên tắc tiến hóa

#### 3.1 Giới hạn hành vi

Phase 1 có đúng **một cửa hàng hoạt động và một kho hoạt động**. Mọi người dùng bán trực tuyến — ở quầy hay từ xa — dùng cùng cửa hàng và kho mặc định. Không có chọn kho, định tuyến kho, chia đơn giữa kho, chuyển kho hoặc đóng/đổi kho.

#### 3.2 Khả năng mở rộng kiến trúc

Mọi identity và hợp đồng vẫn mang `tenant_id`, `store_id`, `warehouse_id`. Mô hình tham chiếu có `Store`, `Warehouse` và `StoreWarehouseAssignment` để mở rộng quan hệ nhiều–nhiều trong tương lai. UI ẩn lựa chọn chỉ có một giá trị, nhưng dữ liệu không hard-code một ID ngầm.

#### 3.3 Không triển khai trước chức năng tương lai

Capability chưa thuộc Phase 1 không xuất hiện dưới dạng màn hình vô hiệu hóa, nhánh ẩn, entity rỗng hoặc operation giả. Yêu cầu ngoài phạm vi bị từ chối bằng lỗi có cấu trúc và không tạo mutation bán phần.

#### 3.4 Đơn giản ở bề mặt, đầy đủ ở hợp đồng

- Lối vào được tổ chức theo vai trò và việc cần làm; người dùng không phải hiểu cấu trúc miền hoặc Screen Group trước khi bắt đầu.
- Chỉ hỏi dữ liệu chưa biết hoặc thực sự cần quyết định; ngữ cảnh và chứng từ đã có được tự điền, trường lô/hạn chỉ mở theo chính sách sản phẩm.
- Nhãn tiếng Việt nghiệp vụ là nội dung chính; enum, stable ID và mã lỗi là thông tin phụ cho hỗ trợ và đối soát.
- Mỗi kết quả nói rõ điều gì xảy ra, tác động là chưa ghi nhận/đã ghi nhận/chưa xác định và bước an toàn tiếp theo.
- Các tối ưu này chỉ là lớp trải nghiệm: máy chủ vẫn kiểm quyền, ngữ cảnh, bất biến, idempotency và finality theo hợp đồng chuẩn.

### 4. Mục tiêu sản phẩm

| ID | Mục tiêu | Kết quả có thể kiểm chứng |
|---|---|---|
| `OBJ-01` | Một Dữ liệu gốc về biến động tồn | Mọi thay đổi số lượng truy được đến Inventory Operation và movement bất biến |
| `OBJ-02` | Không bán âm trong giao dịch trực tuyến | Kiểm tra và giữ/xuất nguyên tử; giao dịch commit sau bị từ chối khi thiếu hàng |
| `OBJ-03` | Quản lý lô–hạn dùng đúng nhu cầu sản phẩm | Hỗ trợ `NONE`/`LOT`; hạn dùng chỉ áp dụng khi `LOT`; FEFO và chặn hết hạn |
| `OBJ-04` | Phân tách vật lý, khả dụng và trạng thái | Hàng chờ giá, cách ly, hỏng, hết hạn, demo không bị coi là khả dụng |
| `OBJ-05` | Giá vốn có lịch sử và đối soát được | Hai phương pháp tính song song; version chính thức; adjustment thay vì sửa lịch sử |
| `OBJ-06` | Kiểm soát rủi ro có quyền và phê duyệt | Phạm vi kho, quyền tài chính, maker–checker và tuyến duyệt theo snapshot |
| `OBJ-07` | Bổ sung hàng tối giản nhưng hữu ích | Hiện tồn thấp/hết hàng và lượng gợi ý từ khả dụng, threshold và target |
| `OBJ-08` | Tách kế toán khỏi giả định định giá bán | Kịch bản chiết khấu và pricing cost basis không ghi inventory/value ledger |
| `OBJ-09` | Phục hồi và đối soát được | `UNKNOWN`, outbox, rebuild projection và Reconciliation Case có đường xử lý |

## 2. Phạm vi

### 2.1 Trong phạm vi

| Cụm | Năng lực |
|---|---|
| Tổ chức | Một cửa hàng, một kho mặc định; nhiều người dùng trực tuyến; scope kho trên mọi mutation |
| Nhập hàng | Nhận theo chứng từ hoặc nhập nhanh được phép; nhập nhanh đủ dữ liệu luôn vào `PENDING_APPROVAL`, không hỏi có cần duyệt và không đi thẳng `READY`; nhận từng phần; ghi chênh lệch giao nhận; phần hàng đủ điều kiện vật lý vào `VALUATION_PENDING`, còn hàng cách ly/hỏng vào đúng trạng thái; xác nhận giá bằng operation riêng |
| Theo dõi | Sản phẩm `NONE` hoặc `LOT`; lô nhà sản xuất; ngày sản xuất tùy chọn; hạn dùng theo cấu hình |
| Bán hàng | Query khả dụng; giữ hàng cho sỉ/online; POS online xuất trong checkout; FEFO/FIFO; bàn giao mới giảm vật lý |
| Trả/xử lý | Khách trả, phân loại, trả nhà cung cấp, cách ly, demo, hỏng, hết hạn, tiêu hủy |
| Kiểm kê | Toàn kho/từng phần; predicate + key snapshot; khóa cả key tương lai trong phạm vi; đếm mù; đếm lại; duyệt/hủy; adjustment |
| Sửa sai | Cancellation trước xử lý, reversal/correction sau hoàn tất; không sửa ledger hoặc operation lịch sử |
| Giá vốn | Value ledger; bình quân liên hoàn và cuối kỳ; official cost version; chốt kỳ; COGS true-up; late landed cost |
| Mở đầu | Trạng thái kích hoạt `PREPARING`; chuẩn bị/validate opening batch, duyệt độc lập, commit, báo cáo migration và chuyển nguyên tử sang `ACTIVE` |
| Chính sách tồn sản phẩm | Threshold/target; ngưỡng cận hạn mặc định và ghi đè theo sản phẩm; hành động `WARN`/`BLOCK_SALE`; chỉ báo dẫn xuất |
| Quản trị | RBAC + warehouse scope; che dữ liệu tài chính; phê duyệt theo rủi ro; audit |
| Tin cậy | Idempotency cho mọi mutation bằng `CommandReceipt`, source version, atomic commit, `UNKNOWN`, transactional outbox, reconciliation/rebuild |
| Liên miền | Kịch bản chiết khấu mua hàng theo kỳ; handoff pricing cost basis; rà soát cuối kỳ; ba cách nhìn lợi nhuận |

### 2.1A Định hướng tương lai, chưa triển khai

| Capability | Những gì Phase 1 chỉ giữ lại |
|---|---|
| Nhiều cửa hàng/nhiều kho | Identity, reference model và scope; chưa có routing/selector/transfer |
| Chuyển và đóng kho | Structured rejection; không có trạng thái `IN_TRANSIT` hay close workflow |
| POS offline | Nền tảng idempotency/version/outbox chung; không có device snapshot, sync hoặc conflict entity |
| Serial | Bài tri thức và decision `DEFERRED`; không có tracking mode, UI, API hoặc entity serial |
| Dự báo bổ sung | Không có horizon, inbound, velocity, demand forecast, MOQ, pack multiple, lead time |
| Alert platform | Không có owner/SLA/email/push hoặc lifecycle cảnh báo chung |
| Chuyển tracking khi còn tồn | Chỉ đổi `NONE ↔ LOT` khi vật lý = 0 và không có nghĩa vụ mở |

### 2.2 Ngoài phạm vi

- Bin/kệ/vị trí chi tiết.
- Hàng ký gửi, giữ hộ, `CUSTODY_ONLY` và tồn thuộc bên thứ ba.
- Chuyển đổi giữa SKU, repack, BOM hoặc sản xuất.
- Tự động tạo đơn mua hoặc proposal bổ sung có lifecycle.
- Sửa trực tiếp số dư, trạng thái, ledger, giá trị hoặc kết quả operation.
- Định nghĩa promotion, công bố giá bán, hạch toán công nợ và quyết định pháp lý về chuyển quyền sở hữu.

## 3. Actor và vai trò nghiệp vụ

| Actor | Mục tiêu chính | Giới hạn |
|---|---|---|
| Nhân viên bán hàng/POS | Xem khả dụng, checkout trực tuyến | Không xem dữ liệu tài chính nếu thiếu quyền |
| Nhân viên xử lý đơn | Giữ, lấy hàng, bàn giao | Không tự duyệt operation do mình lập |
| Thủ kho | Nhận, quét lô, kiểm kê, trả/tiêu hủy | Chỉ thao tác trong kho được cấp |
| Kế toán | Xác nhận giá, xem value ledger, tính và công bố giá vốn | Không công bố giá bán |
| Người phê duyệt | Duyệt operation theo mức rủi ro | Quyền và scope được kiểm lại tại thời điểm quyết định |
| Chủ cửa hàng/Quản trị | Xem báo cáo, cấu hình threshold/target, quyết định định giá | Không được sửa tay ledger hoặc kết quả operation |
| Hệ thống Sản phẩm | Sở hữu sản phẩm, UOM, `tracking_mode`, `expiry_required`, combo snapshot | Không sửa balance |
| Hệ thống Mua hàng | Sở hữu PO/receipt intent, assertion quyền sở hữu, giá/chứng từ nguồn | Không ghi movement trực tiếp |
| Hệ thống Bán hàng/POS | Sở hữu đơn, bàn giao, return request | Không quyết định số dư cuối |
| Hệ thống Kế toán | Nhận kết quả giá trị/adjustment để hạch toán | Không sửa Inventory Operation |
| Hệ thống Định giá/Khuyến mại | Sở hữu pricing cost basis, floor/list price, promotion và sales price | Không tạo COGS hoặc value movement |

## 4. Ranh giới với Theme/Domain khác

| Dữ liệu | Nguồn sự thật |
|---|---|
| Thay đổi số lượng | Inventory Movement ledger bất biến |
| Số dư giao dịch | Projection giao dịch dựng từ movement, cập nhật nguyên tử |
| Lô | Lot record theo tenant + product + manufacturer lot code |
| Thay đổi giá trị | Inventory Value Movement ledger bất biến |
| Giá vốn chính thức | Official Cost Version đã công bố |
| Giá vốn ban đầu dòng bán | Snapshot official cost tại bàn giao |
| Điều chỉnh giá vốn cuối kỳ | Valuation Adjustment Line liên kết dòng xuất |
| Giá vốn dự kiến | Phiên bản kịch bản chiết khấu mua hàng; không có quyền kế toán |
| Giá vốn tham chiếu định giá | Miền định giá, có source type/version và người công bố |
| Giá bán | Miền định giá/khuyến mại |

## 5. Business Journey map

| BJ | Tên |
|---|---|
| `BJ-01` | Theo dõi tồn, khả dụng và chỉ báo vận hành |
| `BJ-02` | Nhận hàng mua |
| `BJ-03` | Xác nhận giá trị ban đầu của hàng nhận |
| `BJ-04` | Quản lý vòng đời giữ hàng |
| `BJ-05` | Lấy hàng và bàn giao đơn |
| `BJ-06` | Tiếp nhận và phân loại hàng khách trả |
| `BJ-07` | Thực hiện trả hàng cho nhà cung cấp |
| `BJ-08` | Kiểm kê và điều chỉnh chênh lệch |
| `BJ-09` | Quản lý trạng thái hàng |
| `BJ-10` | Tiêu hủy hàng |
| `BJ-11` | Hủy và sửa sai nghiệp vụ kho |
| `BJ-12` | Khởi tạo số dư tồn kho đầu kỳ |
| `BJ-13` | Ghi nhận chi phí mua đến muộn |
| `BJ-14` | Tính và công bố giá vốn |
| `BJ-15` | Tra cứu báo cáo tồn và thẻ kho |
| `BJ-16` | Điều tra và đối soát sai lệch |
| `BJ-17` | Phục hồi nghiệp vụ có kết quả chưa xác định |

Xem [Business Journey Map](../behavior/journeys/00-business-journey-map.md).

## 6. Domain map

| Domain | Trách nhiệm nguồn v3.10.1 |
|---|---|
| `DOM-IO` | tiếp nhận yêu cầu có identity/version; quản lý lifecycle Inventory Operation; ghi movement số lượng; cập nhật transactional balance; giữ hàng; trạng thái hàng; hồ sơ lô; return/issue/receipt/correction; phát outbox event. |
| `DOM-IC` | policy snapshot và phê duyệt; warehouse scope; stock count; inventory lock; opening balance governance; Reconciliation Case; recovery/rebuild gate. |
| `DOM-IV` | receipt valuation; value movement ledger; hai phương pháp bình quân; cost calculation run; official cost version; valuation adjustment; COGS initial snapshot và true-up. |

## 7. Giả định và ràng buộc

### 8. Bất biến cấp sản phẩm

1. Không hệ thống nguồn nào sửa số dư hoặc ledger trực tiếp.
2. Mọi mutation có `tenant_id`, `store_id`, `warehouse_id`, `idempotency_key` và source version; Inventory Operation còn có `operation_request_id` ổn định.
3. Một `operation_request_id` ánh xạ một payload và một operation; mỗi `idempotency_key` ánh xạ một command payload/result; cùng khóa khác payload bị chặn.
4. Operation nhiều dòng là all-or-nothing.
5. Quantity movement, value movement, balance, lot, operation result và outbox thuộc cùng commit set khi có liên quan.
6. Movement/value ledger bất biến; sửa sai bằng operation liên kết.
7. Giao dịch trực tuyến không xuất âm.
8. Sản phẩm `NONE` không nhận dữ liệu lô/hạn; sản phẩm `LOT` bắt buộc mã lô nhà sản xuất.
9. Hạn dùng chỉ có nghĩa khi `tracking_mode=LOT`.
10. Giá vốn dự kiến không trở thành giá vốn kế toán.
11. Chốt kỳ không sửa đơn bán hoặc movement gốc.
12. Cập nhật pricing cost basis không tự công bố giá bán.

### 9. Chỉ tiêu chất lượng và vận hành

| ID | Chỉ tiêu |
|---|---|
| `NFR-PERF-01` | Query availability tải chuẩn: `p95 ≤ 300 ms` |
| `NFR-PERF-02` | Giữ/xuất tải chuẩn: `p95 ≤ 1 s`, `p99 ≤ 2 s` |
| `NFR-CAP-01` | Tối thiểu 100 phiên đồng thời/tenant, 50 operation mutation/giây, 10 triệu movement line/năm |
| `NFR-DUR-01` | Operation Hoàn tất có `RPO=0`; ledger/balance/outbox đã commit không được mất |
| `NFR-SEC-01` | Mọi mutation kiểm quyền chức năng + warehouse scope; dữ liệu tài chính có quyền riêng |
| `NFR-AUD-01` | Operation, movement và audit giữ tối thiểu 10 năm; archive vẫn truy vấn/export/rebuild được |
| `NFR-OBS-01` | Mọi `UNKNOWN`, outbox retry, reconciliation và rebuild có metric/log/trace theo stable ID |
| `NFR-ACC-01` | Screen contract hỗ trợ keyboard, focus, nhãn lỗi và trạng thái không chỉ phụ thuộc màu |
| `NFR-UX-01` | Happy path không yêu cầu chọn ngữ cảnh một giá trị hoặc nhập lại dữ liệu nguồn; mọi kết quả có mô tả tác động và bước an toàn tiếp theo |

### 10. Tiêu chí thành công MVP

- 100% mutation tồn đi qua Inventory Operation và có movement truy vết được.
- 0 trường hợp oversell do race trong test cạnh tranh chuẩn.
- 100% receipt sản phẩm `LOT` bị chặn nếu thiếu mã lô; thiếu hạn bị chặn khi `expiry_required=true`.
- 100% retry cùng request ID trả lại cùng kết quả; payload khác bị từ chối.
- 100% chốt kỳ tạo adjustment liên kết, không update bản ghi xuất gốc.
- 100% số dư projection có thể dựng lại từ ledger trong bài kiểm tra phục hồi.
- 100% capability ngoài phạm vi nêu tại mục 5 trả lỗi có cấu trúc và không mutation.
- Chủ cửa hàng hoàn tất được luồng nhận → định giá → bán → báo cáo với một cửa hàng/kho mà không phải chọn topology.
- Người dùng theo từng vai trò vào đúng công việc, chỉ nhập dữ liệu còn thiếu và hiểu được tác động cùng bước tiếp theo mà không cần đọc mã kỹ thuật.

## 8. Tài liệu nguồn

### 1. Kiểm soát tài liệu

| Thuộc tính | Giá trị |
|---|---|
| Sản phẩm | Quản lý tồn kho và giá vốn |
| Phiên bản SRS | `3.1.0` |
| Package freeze | `T7-PACKAGE-FREEZE-v4.1.0` |
| Nguồn quyết định | `T7-BASELINE-FREEZE-v4.0.0` |
| Trạng thái | `FROZEN` |
| Phạm vi phát hành | Phase 1 / MVP phục vụ early adopter |
| Ngày lập | 2026-08-22 |
| Nguồn yêu cầu | Quyết định nghiệp vụ `T7-DR-001…102 cùng 78 yêu cầu nguyên tử`, Hồ sơ chuyển đổi quyết định và bộ Know-how cùng package |
| Ngôn ngữ nghiệp vụ | Tiếng Việt; tiếng Anh giữ cho ID, enum, API, event và tên trường dữ liệu |
| Mức bằng chứng | `STATIC_VALIDATED` cho đến khi có bằng chứng thực thi |

### 11. Cấu trúc bộ SRS

| Phần | File | Vai trò |
|---:|---|---|
| 01 | `01-overview.md` | Mục tiêu, phạm vi và nguyên tắc |
| 02 | `02-business-journeys/` | Bản đồ 25 hành trình nghiệp vụ và một file cho từng BJ |
| 03 | `03-domain-foundation.md` | Ranh giới miền, thẩm quyền và bất biến |
| 04 | `04-data-entities.md` | Thực thể, quan hệ, lifecycle và projection |
| 05 | `05-use-cases/` | Registry và 97 hồ sơ UC: hành vi, nghiệm thu, UI, kỹ thuật và delivery trace |
| 06 | `06-shared-behavioral-contracts.md` | Registry và định nghĩa hợp đồng hành vi dùng chung |
| 07 | `07-technical-contracts.md` | Quy tắc kỹ thuật, API/event/error/permission catalog dùng chung |
| 08 | `08-ui-ux.md` | Bản đồ Screen Group và quy tắc handoff UI Contract/prototype |
| 09 | `09-traceability-quality.md` | Truy vết, test catalog, quality gates và freeze evidence |

### 12. Tài liệu tham chiếu trong package

- `../know-how/decisions/decision-register.md`
- `../know-how/decisions/decision-migration-record.md`
- `../know-how/glossary/glossary.md`
- `../know-how/wiki/00-table-of-contents.md`
