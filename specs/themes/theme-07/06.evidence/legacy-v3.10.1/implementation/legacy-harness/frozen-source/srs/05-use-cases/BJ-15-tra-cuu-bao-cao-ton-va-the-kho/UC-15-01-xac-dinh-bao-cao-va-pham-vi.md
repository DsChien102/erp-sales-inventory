# UC-15-01 — Xác định báo cáo và phạm vi

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-15 — Tra cứu báo cáo tồn và thẻ kho](../../../../../../../../02.specification/behavior/journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Chủ cửa hàng, kế toán hoặc thủ kho |
| Điều kiện kích hoạt | Người dùng mở chức năng báo cáo |
| Mục tiêu | Xác định báo cáo và phạm vi để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Report context hợp lệ hoặc bị từ chối</li><li>Scope/cut-off/permission context</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../../../../../../../../01.knowledge/decisions/decision-register.md#g12) |
| Bài tri thức liên quan | [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../../../../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../../../../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../../../../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Quyền chức năng, phạm vi kho và bảo vệ dữ liệu tài chính](../../../../../../../../01.knowledge/know-how/KB-KGV-030-quyen-chuc-nang-pham-vi-kho-va-bao-ve-du-lieu-tai-chinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) |
| Hợp đồng dùng chung | [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả dùng chung](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IO-01 — Query inventory availability](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-01.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | tenant_id, phạm vi đọc, filter/cut-off/as-of, quyền xem và correlation ID. |
| Quy tắc và bất biến | <ul><li>Ledger authority: Thẻ kho và lịch sử dựa trên movement ledger bất biến; không sửa số dư từ báo cáo</li><li>Cut-off/as-of: Báo cáo phải thể hiện cut-off, thời điểm tạo và độ mới của projection</li><li>Hai loại ngày: Cho phép đọc theo ngày ghi nhận hoặc ngày nghiệp vụ nhưng phải gắn nhãn rõ, không trộn ngầm</li><li>Quantity/value: Quyền xem quantity độc lập với quyền xem official cost, total value và valuation adjustment</li><li>LOT/NONE: Breakdown theo lô chỉ áp dụng cho sản phẩm LOT; không tạo lô giả cho NONE</li><li>Giá trị chi tiết: Giá trị có thẩm quyền ở tenant + sản phẩm; phân bổ theo kho/state/lot nếu có phải gắn nhãn dẫn xuất</li></ul> |
| Thay đổi trạng thái và tác động | Không đổi trạng thái authoritative; chỉ trả read model/snapshot có thời điểm dữ liệu. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-15-01-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác định báo cáo và phạm vi” | Report context hợp lệ hoặc bị từ chối; kết quả Scope/cut-off/permission context và có truy vết nguồn. |
| AS-UC-15-01-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-15-01-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-15-01-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-11 — Thẻ kho và lịch sử](../../../prototype/contracts/sg-11/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-01 | QueryInventoryAvailability | API-Q-01 — GET /v1/inventory/availability | Read snapshot/transactional read | Query result only | TST-BC-IO-01 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-15 — Tra cứu báo cáo tồn và thẻ kho](../../../../../../../../02.specification/behavior/journeys/BJ-15-tra-cuu-bao-cao-ton-va-the-kho.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-15-01-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-15-01, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-15-01. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

