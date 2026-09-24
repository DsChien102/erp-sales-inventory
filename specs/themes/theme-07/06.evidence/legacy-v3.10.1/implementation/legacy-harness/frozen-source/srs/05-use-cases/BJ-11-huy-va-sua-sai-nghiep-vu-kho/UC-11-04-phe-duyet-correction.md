# UC-11-04 — Phê duyệt correction

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-11 — Hủy và sửa sai nghiệp vụ kho](../../../../../../../../02.specification/behavior/journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Người vận hành kho và người duyệt sửa sai |
| Điều kiện kích hoạt | Proposal có snapshot rủi ro |
| Mục tiêu | Phê duyệt correction để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Duyệt hoặc từ chối có lý do</li><li>Approval decision</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G08 — Sửa sai, reversal và kỳ khóa](../../../../../../../../01.knowledge/decisions/decision-register.md#g08); [Nhóm G10 — Inventory Operation, idempotency và sự kiện](../../../../../../../../01.knowledge/decisions/decision-register.md#g10) |
| Bài tri thức liên quan | [Sửa sai tồn kho mà không sửa lịch sử](../../../../../../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md); [Vòng đời của một Inventory Operation](../../../../../../../../01.knowledge/know-how/KB-KGV-027-vong-doi-cua-mot-inventory-operation.md); [Idempotency, phiên bản nguồn và xử lý kết quả chưa xác định](../../../../../../../../01.knowledge/know-how/KB-KGV-028-idempotency-phien-ban-nguon-va-xu-ly-ket-qua-chua-xac-dinh.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-06 — Decide approval](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-06.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Hủy trước thực thi: Chỉ DRAFT, PENDING_APPROVAL hoặc READY được hủy; cancellation không tạo movement/value</li><li>UNKNOWN: Không đảo hoặc thay thế khi chưa xác lập finality; phải đối soát bằng cùng operation ID</li><li>Operation hoàn tất: Không sửa payload/result; tạo operation mới trong correction chain</li><li>Dependency: Chặn reversal nếu làm âm tồn hoặc dependency chưa được trung hòa; không giả lập trung hòa bằng sửa số dư</li><li>Delta hay full reversal: Dùng delta khi chỉ phần sai có thể sửa độc lập và giữ đúng nguồn; dùng reversal + replacement khi toàn operation mất hiệu lực hoặc payload đúng phải được xác lập lại nguyên khối</li><li>Hàng thực quay về: Sale Issue đã bàn giao chỉ tăng tồn qua BJ-06; cancellation/correction không thay thế việc nhận hàng thực tế</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-06; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-11-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Phê duyệt correction” | Duyệt hoặc từ chối có lý do; kết quả Approval decision và có truy vết nguồn. |
| AS-UC-11-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-11-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-11-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-10 — Operation, phê duyệt và sửa sai](../../../prototype/contracts/sg-10/ui-contract.md) |
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
| BA | [BJ-11 — Hủy và sửa sai nghiệp vụ kho](../../../../../../../../02.specification/behavior/journeys/BJ-11-huy-va-sua-sai-nghiep-vu-kho.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-11-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-11-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-11-04. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

