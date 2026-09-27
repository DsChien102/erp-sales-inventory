> **Phân loại:** Step contract của PROC-01; không phải UC/BJ canonical.

# PROC-01-STEP-04 — Xác minh và công bố kết quả

> **Phiên bản:** 4.1.0  
> **Loại:** Procedure Step  
> **Procedure:** [PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho](00-procedure.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan bước kỹ thuật

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Vận hành hệ thống và người đối soát |
| Điều kiện kích hoạt | Có projection ứng viên |
| Mục tiêu | Xác minh và công bố kết quả để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Bản mới được publish hoặc bản cũ được giữ nguyên</li><li>Validated rebuild result</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../../../../../../../../01.knowledge/decisions/decision-register.md#g12); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../../../../../../01.knowledge/decisions/decision-register.md#g12) |
| Bài tri thức liên quan | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../../../../../../../../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Movement ledger, số dư dẫn xuất và phục hồi sau sự cố](../../../../../../../../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../../../../../../../../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Hiệu năng và năng lực xử lý của hệ thống tồn kho](../../../../../../../../01.knowledge/know-how/KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-05 — Reconcile and rebuild projection](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IC-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn dựng: Chỉ dựng từ ledger authoritative tại một cut-off xác định</li><li>Ledger integrity: Nếu ledger không đạt kiểm tra, dừng và escalated; không lấy báo cáo/chứng từ nguồn để tái tạo ledger</li><li>Tính toàn vẹn: Projection ứng viên không được công bố nếu totals/count/hash không đạt</li><li>Publish: Thay projection theo cơ chế nguyên tử hoặc versioned switch; người dùng không thấy dữ liệu trộn giữa hai phiên bản</li><li>Thất bại: Giữ bản hiện hành và bằng chứng rebuild; không ghi đè bằng kết quả bán phần</li><li>Khóa phạm vi: Chỉ khóa phạm vi cần thiết và mở sau khi kiểm tra đạt; failure giữ trạng thái bảo vệ có owner/escalation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-PROC-01-STEP-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác minh và công bố kết quả” | Bản mới được publish hoặc bản cũ được giữ nguyên; kết quả Validated rebuild result và có truy vết nguồn. |
| AS-PROC-01-STEP-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-PROC-01-STEP-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-PROC-01-STEP-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-15 — UNKNOWN và đối soát](../../../prototype/contracts/sg-15/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho](00-procedure.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo procedure package; step này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-PROC-01-STEP-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định PROC-01-STEP-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của PROC-01-STEP-04. Procedure contract giữ flow kỹ thuật có kiểm soát; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

