# UC-13-02 — Tính và phân bổ chi phí

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-13 — Ghi nhận chi phí mua đến muộn](../../../../../../../../02.specification/behavior/journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Kế toán mua hàng hoặc kế toán kho |
| Điều kiện kích hoạt | Có source/scope hợp lệ |
| Mục tiêu | Tính và phân bổ chi phí để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Phân bổ cân bằng hoặc có sai lệch cần sửa</li><li>Allocation draft có provenance</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G07 — Giá vốn và định giá tồn kho](../../../../../../../../01.knowledge/decisions/decision-register.md#g07) |
| Bài tri thức liên quan | [Các thành phần hình thành giá nhập thực tế](../../../../../../../../01.knowledge/know-how/KB-KGV-019-cac-thanh-phan-hinh-thanh-gia-nhap-thuc-te.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../../../../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../../../../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Sửa sai tồn kho mà không sửa lịch sử](../../../../../../../../01.knowledge/know-how/KB-KGV-021-sua-sai-ton-kho-khong-sua-lich-su.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IV-04 — Record late landed cost](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IV-04.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn bắt buộc: Mỗi chi phí phải có source document/line/version và bằng chứng; không nhập một khoản tổng không truy nguyên</li><li>Chống trùng: Cùng source component/version/allocation line chỉ được ghi một lần</li><li>Thành phần giá trị: Chi phí mua, discount, hàng tặng và thuế được chuẩn hóa theo chính sách; VAT được khấu trừ không vào giá vốn</li><li>Ngoại tệ: Sổ tồn dùng VND; dùng tỷ giá do nguồn Kế toán cung cấp; chênh lệch thanh toán không làm đổi giá trị tồn đã ghi</li><li>Phân bổ: Tổng các dòng phân bổ phải khớp tổng chi phí sau chuẩn hóa; phần dư làm tròn phải được xử lý xác định</li><li>Kỳ mở/khóa: Kỳ còn mở ghi vào phạm vi cần tính lại; kỳ đã khóa ghi adjustment ở kỳ mở hiện tại và giữ liên kết kỳ gốc</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IV-04; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-13-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Tính và phân bổ chi phí” | Phân bổ cân bằng hoặc có sai lệch cần sửa; kết quả Allocation draft có provenance và có truy vết nguồn. |
| AS-UC-13-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-13-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-13-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-03 — Hàng chờ giá](../../../prototype/contracts/sg-03/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IV-04 | RecordLateLandedCost | API-C-23 — POST /v1/receipt-valuations/{id}/late-costs | Natural-key receipt + adjustment/value + dirty scope + outbox | EVT-IV-05 LateLandedCostRecorded | TST-BC-IV-04 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-13 — Ghi nhận chi phí mua đến muộn](../../../../../../../../02.specification/behavior/journeys/BJ-13-ghi-nhan-chi-phi-mua-en-muon.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-13-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-13-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-13-02. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

