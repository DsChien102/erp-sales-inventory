# UC-12-02 — Rà soát và duyệt batch

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-12 — Khởi tạo số dư tồn kho đầu kỳ](../../../../../../../../02.specification/behavior/journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Quản trị triển khai, kế toán kho và người duyệt |
| Điều kiện kích hoạt | Có prepared batch hợp lệ |
| Mục tiêu | Rà soát và duyệt batch để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Batch được duyệt hoặc từ chối</li><li>Approval decision độc lập với người lập</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G09 — Số dư đầu kỳ và Chuyển đổi chính thức](../../../../../../../../01.knowledge/decisions/decision-register.md#g09) |
| Bài tri thức liên quan | [Chuẩn bị dữ liệu số dư tồn kho đầu kỳ](../../../../../../../../01.knowledge/know-how/KB-KGV-022-chuan-bi-du-lieu-so-du-ton-kho-dau-ky.md); [Xác nhận số dư đầu kỳ, Chuyển đổi chính thức và đối soát migration](../../../../../../../../01.knowledge/know-how/KB-KGV-023-xac-nhan-so-du-dau-ky-chuyen-doi-chinh-thuc-va-doi-soat-migration.md); [Kho, cửa hàng và khóa định danh số dư tồn kho](../../../../../../../../01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md); [Đơn vị tính và cách quy đổi số lượng tồn kho](../../../../../../../../01.knowledge/know-how/KB-KGV-004-don-vi-tinh-va-cach-quy-doi-so-luong-ton-kho.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../../../../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-06 — Decide approval](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-06.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Activation gate: Khi chưa hoàn tất batch đầu tiên, chỉ nghiệp vụ chuẩn bị/duyệt/commit đầu kỳ được phép; mutation thường bị chặn</li><li>Một batch chính thức: Chỉ một opening batch được hoàn tất; sai sau activation phải dùng correction/adjustment</li><li>Dữ liệu bất thường: Quantity âm hoặc quantity bằng 0 nhưng có value bị từ chối; quantity dương phải có căn cứ giá trị đủ để hình thành giá vốn khởi tạo</li><li>Trùng khóa: Không tự gộp im lặng các dòng trùng product + warehouse + state + lot; phải báo lỗi để sửa nguồn</li><li>LOT/expiry: Sản phẩm NONE không có lô; sản phẩm LOT bắt buộc mã lô và chỉ bắt buộc hạn dùng khi product policy yêu cầu</li><li>Trạng thái: Có thể nhập non-sellable khi state được khai rõ; chỉ lượng sellable và đủ dữ liệu mới tăng khả dụng</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-06; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-12-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Rà soát và duyệt batch” | Batch được duyệt hoặc từ chối; kết quả Approval decision độc lập với người lập và có truy vết nguồn. |
| AS-UC-12-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-12-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-12-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-13 — Opening balance](../../../prototype/contracts/sg-13/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-06 | DecideApproval | API-C-19 — POST /v1/approval-cases/{id}/decisions | Approval case + operation state + outbox | EVT-IC-04 ApprovalDecided | TST-BC-IC-06 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-12 — Khởi tạo số dư tồn kho đầu kỳ](../../../../../../../../02.specification/behavior/journeys/BJ-12-khoi-tao-so-du-ton-kho-au-ky.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-12-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-12-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-12-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

