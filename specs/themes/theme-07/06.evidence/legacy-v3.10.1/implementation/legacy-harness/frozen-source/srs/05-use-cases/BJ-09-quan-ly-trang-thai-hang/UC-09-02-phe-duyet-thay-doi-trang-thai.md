# UC-09-02 — Phê duyệt thay đổi trạng thái

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-09 — Quản lý trạng thái hàng](../../../../../../../../02.specification/behavior/journeys/BJ-09-quan-ly-trang-thai-hang.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Thủ kho hoặc quản lý kho |
| Điều kiện kích hoạt | Yêu cầu vượt ngưỡng/rủi ro |
| Mục tiêu | Phê duyệt thay đổi trạng thái để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Duyệt hoặc từ chối có lý do</li><li>Approval decision</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G06 — Trả hàng, hết hạn và loại bỏ](../../../../../../../../01.knowledge/decisions/decision-register.md#g06); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../../../../../../01.knowledge/decisions/decision-register.md#g02) |
| Bài tri thức liên quan | [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../../../../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../../../../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../../../../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Hàng ký gửi, hàng demo và quyền sở hữu](../../../../../../../../01.knowledge/know-how/KB-KGV-034-quyen-so-huu-hang-hoa-hang-ky-gui-va-hang-demo.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-06 — Decide approval](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-06.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Ma trận chuyển trạng thái: Chỉ cho các chuyển đổi được whitelist; mỗi chuyển đổi xác định quyền, lý do, bằng chứng và mức duyệt</li><li>Tổng vật lý: Chuyển trạng thái không làm đổi tổng physical quantity của sản phẩm/lô</li><li>Hết hạn: Xác định trực tiếp từ hạn dùng và ngày nghiệp vụ; loại khỏi khả dụng ngay, không phụ thuộc tác vụ nền đã materialize EXPIRED hay chưa</li><li>Cận hạn: Chỉ là chỉ báo/policy WARN hoặc BLOCK_SALE; không phải state movement và không tạo hồ sơ cảnh báo có lifecycle</li><li>Demo: Vẫn thuộc physical và book value nhưng không khả dụng; muốn bán lại phải qua chuyển trạng thái được phép</li><li>Reservation: Khi eligible giảm, phát tác động để BJ-04 đánh giá lại; BJ này không tự sửa order hoặc PickAllocation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-06; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-09-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Phê duyệt thay đổi trạng thái” | Duyệt hoặc từ chối có lý do; kết quả Approval decision và có truy vết nguồn. |
| AS-UC-09-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-09-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-09-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-08 — Trạng thái, trả NCC và tiêu hủy](../../../prototype/contracts/sg-08/ui-contract.md) |
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
| BA | [BJ-09 — Quản lý trạng thái hàng](../../../../../../../../02.specification/behavior/journeys/BJ-09-quan-ly-trang-thai-hang.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-09-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-09-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-09-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

