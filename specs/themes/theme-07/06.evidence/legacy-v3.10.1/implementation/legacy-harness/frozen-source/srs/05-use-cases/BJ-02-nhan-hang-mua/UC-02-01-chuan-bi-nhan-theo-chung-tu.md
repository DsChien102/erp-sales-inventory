# UC-02-01 — Chuẩn bị nhận theo chứng từ

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Thủ kho; người duyệt khi có ngoại lệ |
| Điều kiện kích hoạt | Chứng từ nguồn hợp lệ được chọn |
| Mục tiêu | Chuẩn bị nhận theo chứng từ để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Hồ sơ thực nhận sẵn sàng hoặc cần duyệt</li><li>Receipt draft gắn source/version</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G03 — Nhận hàng mua và giải phóng khả dụng](../../../../../../../../01.knowledge/decisions/decision-register.md#g03); [Nhóm G02 — Lô, hạn dùng và chính sách theo dõi sản phẩm](../../../../../../../../01.knowledge/decisions/decision-register.md#g02); [Nhóm G11 — Quyền và phê duyệt](../../../../../../../../01.knowledge/decisions/decision-register.md#g11) |
| Bài tri thức liên quan | [Nhận hàng mua và xử lý chênh lệch giao nhận](../../../../../../../../01.knowledge/know-how/KB-KGV-007-nhan-hang-mua-va-xu-ly-chenh-lech-giao-nhan.md); [Hàng đã nhận nhưng chưa chốt giá](../../../../../../../../01.knowledge/know-how/KB-KGV-008-hang-da-nhan-nhung-chua-chot-gia.md); [Chính sách NONE, LOT hoặc SERIAL](../../../../../../../../01.knowledge/know-how/KB-KGV-024-chinh-sach-quan-ly-hang-thong-thuong-theo-lo-hoac-theo-serial.md); [Danh tính và vòng đời của một lô hàng](../../../../../../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Phê duyệt inventory operation theo mức rủi ro](../../../../../../../../01.knowledge/know-how/KB-KGV-031-phe-duyet-inventory-operation-theo-muc-rui-ro.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IO-16 — Maintain operation draft](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-16.md); [BC-IC-07 — Submit inventory operation](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-07.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nhận vượt nguồn: Đánh giá theo từng source line trên lượng đạt lũy kế ở base UOM; ngưỡng % và số lượng tuyệt đối do ApprovalPolicy quy định</li><li>Hàng từ chối: Không tạo movement; vẫn lưu discrepancy/evidence</li><li>Tình trạng ngay khi nhận: Hàng cách ly/hỏng vẫn tăng tồn vật lý vào đúng trạng thái; không được mặc định chuyển thành sellable</li><li>LOT/expiry: NONE không hỏi hạn dùng; LOT mới mở yêu cầu hạn dùng theo product policy</li><li>Nhận từng phần: Cho phép nhiều receipt cùng tham chiếu source line nhưng tổng lượng được kiểm bằng concurrency guard</li><li>Nguyên tử: Movement, balance, lot, result và outbox cùng commit hoặc không có gì commit</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IO-16, BC-IC-07; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-02-01-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Chuẩn bị nhận theo chứng từ” | Hồ sơ thực nhận sẵn sàng hoặc cần duyệt; kết quả Receipt draft gắn source/version và có truy vết nguồn. |
| AS-UC-02-01-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-02-01-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-02-01-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

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
| BC-IO-16 | MaintainOperationDraft | API-C-25 — POST /v1/inventory-operations; PUT /v1/inventory-operations/{id} | Draft + lines + CommandReceipt | Synchronous result | TST-BC-IO-16 |
| BC-IC-07 | SubmitInventoryOperation | API-C-26 — POST /v1/inventory-operations/{id}/submission | Payload lock + risk/policy + approval case + CommandReceipt | Synchronous result | TST-BC-IC-07 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-02 — Nhận hàng mua](../../../../../../../../02.specification/behavior/journeys/BJ-02-nhan-hang-mua.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-02-01-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-02-01, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-02-01. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

