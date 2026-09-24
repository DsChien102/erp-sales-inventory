# UC-02-03 — Phê duyệt yêu cầu nhận hàng

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Người có quyền và cấp phê duyệt phù hợp, khác người lập |
| Điều kiện kích hoạt | Hồ sơ nhập hàng nhanh đã gửi hoặc hồ sơ nhận theo chứng từ có ngoại lệ cần duyệt |
| Mục tiêu | Ra quyết định có bằng chứng cho yêu cầu nhận hàng, giữ tách biệt giữa quyền cho phép thực thi và tác động tồn kho. |
| Kết quả thành công | <ul><li>Chấp thuận: operation được phép chuyển sang `READY`, nhưng chưa tạo movement.</li><li>Từ chối: kết thúc yêu cầu mà không thay đổi tồn.</li><li>Yêu cầu bổ sung: hồ sơ quay về trạng thái có thể bổ sung theo hợp đồng, không tạo movement.</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../../../../../../01.knowledge/decisions/decision-register.md#g03); [Nhóm G11 — Quyền và phê duyệt](../../../../../../../../01.knowledge/decisions/decision-register.md#g11); [Nhóm G03 — Nhập hàng nhanh bắt buộc duyệt](../../../../../../../../01.knowledge/decisions/decision-register.md#g03) |
| Bài tri thức liên quan | [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../../../../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../../../../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../../../../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../../../../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../../../../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-06 — Decide approval](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-06.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nhập hàng nhanh luôn phải có quyết định duyệt; nhận theo chứng từ chỉ vào UC này khi policy/ngoại lệ yêu cầu.</li><li>Người duyệt phải còn quyền, phạm vi kho và cấp phù hợp tại thời điểm quyết định, đồng thời khác người lập.</li><li>Quyết định đầu tiên commit hợp lệ thắng; yêu cầu sau không ghi đè.</li><li>Phê duyệt chỉ cho phép thực thi, không giữ hàng và không tạo movement; các guard phải được kiểm tra lại khi ghi tồn.</li><li>Từ chối phải có lý do và không tạo tác động tồn kho.</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-06; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-03-01 | Hồ sơ nhập hàng nhanh ở `PENDING_APPROVAL` và người duyệt đủ điều kiện | Người duyệt chấp thuận đúng version | Operation được phép chuyển sang `READY`; chưa tạo movement và lưu đầy đủ quyết định/bằng chứng. |
| AS-UC-02-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-02-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-02-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |
| AS-UC-02-03-05 | Hồ sơ nhận theo chứng từ dưới ngưỡng và không có ngoại lệ | Hệ thống định tuyến sau submit | Không tạo ApprovalCase; operation có thể đi theo nhánh chuẩn. Quy tắc này không áp dụng cho nhập hàng nhanh. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-02 — Nhận hàng](../../../prototype/contracts/sg-02/ui-contract.md) |
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
| BA | [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-02-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-02-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-02-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.
