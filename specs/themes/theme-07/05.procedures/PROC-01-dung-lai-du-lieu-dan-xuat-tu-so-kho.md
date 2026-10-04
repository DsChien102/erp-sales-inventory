---
id: PROC-01
type: procedure
theme: theme-07
title: "Dựng lại dữ liệu dẫn xuất từ sổ kho"
owner: SA/SE
status: FROZEN
source_baseline: v3.10.1
---
# PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho

## 1. Mục đích

> **Loại artifact:** Technical recovery procedure; không phải Business Journey  
> **Migration:** Theme 7 `4.0.0/BJ-21` → `4.1.0/PROC-01`  
> **Owner:** Platform Operations  
> **Caller:** Chỉ BJ-16 sau khi xác nhận ledger đúng và projection sai
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-084`, `T7-DR-084#REQ-02`, `T7-DR-086`, `T7-DR-090`

## 1. Mục tiêu và precondition

Khôi phục projection/read model từ authoritative ledger mà không sửa ledger hoặc operation nguồn. Chỉ chạy khi BJ-16 đã phân loại `PROJECTION_MISMATCH`, chứng minh ledger toàn vẹn và cấp scope/cut-off.

## 2. Procedure

| Step | Hành động | Evidence bắt buộc |
|---|---|---|
| PROC-01-STEP-01 | Xác định projection, scope và cut-off; kiểm ledger integrity | Rebuild plan và integrity decision |
| PROC-01-STEP-02 | Khóa phạm vi rủi ro; snapshot projection cũ/control totals | Safe baseline, old version/hash |
| PROC-01-STEP-03 | Dựng candidate projection từ ledger tới cut-off | Candidate version và input hash |
| PROC-01-STEP-04 | Đối chiếu totals/counts/hash và atomic publish | Validation evidence hoặc failure evidence |

## 3. Hard controls

- Không dùng report/chứng từ nguồn để tái tạo ledger.
- Candidate không đạt totals/count/hash không được publish.
- Publish bằng atomic/versioned switch; không để người dùng thấy dữ liệu trộn phiên bản.
- Failure giữ projection cũ, scope protection và owner/escalation; không ghi đè bán phần.
- Rebuild run lưu ledger cut-off, input/output hash, actor và publish time.
- PROC-01 không giải quyết operation `UNKNOWN`; authority đó thuộc BJ-17.

## 4. Handoff

PROC-01 trả validation evidence về BJ-16. Chỉ BJ-16 có quyền close/reopen Reconciliation Case.

## 5. Step contracts chi tiết

- PROC-01-STEP-01 — Chuẩn bị phạm vi dựng lại
- PROC-01-STEP-02 — Bảo vệ phiên bản dữ liệu dẫn xuất
- PROC-01-STEP-03 — Dựng lại từ ledger
- PROC-01-STEP-04 — Xác minh và công bố kết quả

## 2. Trigger

Theo điều kiện kích hoạt được nêu trong procedure source.

## 3. Điều kiện trước

Theo guard/precondition của các step source.

## 4. Các bước thực hiện

### Bước 1 — Chuẩn bị phạm vi dựng lại

> **Phân loại:** Step contract của PROC-01; không phải UC/BJ canonical.

### PROC-01-STEP-01 — Chuẩn bị phạm vi dựng lại

> **Phiên bản:** 4.1.0  
> **Loại:** Procedure Step  
> **Procedure:** PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

### 1. Tổng quan bước kỹ thuật

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Vận hành hệ thống và người đối soát |
| Điều kiện kích hoạt | Có projection mismatch đã được phân loại |
| Mục tiêu | Chuẩn bị phạm vi dựng lại để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Scope/cut-off hợp lệ hoặc rebuild bị dừng</li><li>Rebuild plan và ledger-integrity decision</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

### 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Bài tri thức liên quan | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Hiệu năng và năng lực xử lý của hệ thống tồn kho](../01.knowledge/know-how/KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-05 — Reconcile and rebuild projection](../02.specification/behavior/behavioral-contracts/BC-IC-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn dựng: Chỉ dựng từ ledger authoritative tại một cut-off xác định</li><li>Ledger integrity: Nếu ledger không đạt kiểm tra, dừng và escalated; không lấy báo cáo/chứng từ nguồn để tái tạo ledger</li><li>Tính toàn vẹn: Projection ứng viên không được công bố nếu totals/count/hash không đạt</li><li>Publish: Thay projection theo cơ chế nguyên tử hoặc versioned switch; người dùng không thấy dữ liệu trộn giữa hai phiên bản</li><li>Thất bại: Giữ bản hiện hành và bằng chứng rebuild; không ghi đè bằng kết quả bán phần</li><li>Khóa phạm vi: Chỉ khóa phạm vi cần thiết và mở sau khi kiểm tra đạt; failure giữ trạng thái bảo vệ có owner/escalation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

### 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-PROC-01-STEP-01-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Chuẩn bị phạm vi dựng lại” | Scope/cut-off hợp lệ hoặc rebuild bị dừng; kết quả Rebuild plan và ledger-integrity decision và có truy vết nguồn. |
| AS-PROC-01-STEP-01-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-PROC-01-STEP-01-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-PROC-01-STEP-01-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

### 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-078](../03.design/screens/SCR-078.md); [SCR-080](../03.design/screens/SCR-080.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

### 5. Hợp đồng kỹ thuật

Câu hỏi mở: ma trận hiện thực BC từng nằm ở FND-TECH-01 chưa được ghi đủ tại procedure này. Hiện thực API, event và transaction thuộc work slice lúc review để implement.

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

### 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo procedure package; step này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-PROC-01-STEP-01-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định PROC-01-STEP-01, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của PROC-01-STEP-01. Procedure contract giữ flow kỹ thuật có kiểm soát; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Bước 2 — Bảo vệ phiên bản dữ liệu dẫn xuất

> **Phân loại:** Step contract của PROC-01; không phải UC/BJ canonical.

### PROC-01-STEP-02 — Bảo vệ phiên bản dữ liệu dẫn xuất

> **Phiên bản:** 4.1.0  
> **Loại:** Procedure Step dùng chung  
> **Procedure:** PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

### 1. Tổng quan bước kỹ thuật

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Vận hành hệ thống và người đối soát |
| Điều kiện kích hoạt | Rebuild được phép |
| Mục tiêu | Bảo vệ phiên bản dữ liệu dẫn xuất để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Scope được bảo vệ và phiên bản cũ/control totals được chụp</li><li>Safe rebuild baseline dùng chung</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

### 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Bài tri thức liên quan | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Hiệu năng và năng lực xử lý của hệ thống tồn kho](../01.knowledge/know-how/KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-05 — Reconcile and rebuild projection](../02.specification/behavior/behavioral-contracts/BC-IC-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn dựng: Chỉ dựng từ ledger authoritative tại một cut-off xác định</li><li>Ledger integrity: Nếu ledger không đạt kiểm tra, dừng và escalated; không lấy báo cáo/chứng từ nguồn để tái tạo ledger</li><li>Tính toàn vẹn: Projection ứng viên không được công bố nếu totals/count/hash không đạt</li><li>Publish: Thay projection theo cơ chế nguyên tử hoặc versioned switch; người dùng không thấy dữ liệu trộn giữa hai phiên bản</li><li>Thất bại: Giữ bản hiện hành và bằng chứng rebuild; không ghi đè bằng kết quả bán phần</li><li>Khóa phạm vi: Chỉ khóa phạm vi cần thiết và mở sau khi kiểm tra đạt; failure giữ trạng thái bảo vệ có owner/escalation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

### 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-PROC-01-STEP-02-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Bảo vệ phiên bản dữ liệu dẫn xuất” | Scope được bảo vệ và phiên bản cũ/control totals được chụp; kết quả Safe rebuild baseline dùng chung và có truy vết nguồn. |
| AS-PROC-01-STEP-02-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-PROC-01-STEP-02-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-PROC-01-STEP-02-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

### 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-079](../03.design/screens/SCR-079.md); [SCR-080](../03.design/screens/SCR-080.md) |
| Quy tắc sở hữu | Không sở hữu màn hình riêng. UI của UC gọi hiển thị trạng thái tiến trình/kết quả và giữ cùng operation identity. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

### 5. Hợp đồng kỹ thuật

Câu hỏi mở: ma trận hiện thực BC từng nằm ở FND-TECH-01 chưa được ghi đủ tại procedure này. Hiện thực API, event và transaction thuộc work slice lúc review để implement.

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

### 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo procedure package; step này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-PROC-01-STEP-02-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định PROC-01-STEP-02, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của PROC-01-STEP-02. Procedure contract giữ flow kỹ thuật có kiểm soát; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Bước 3 — Dựng lại từ ledger

> **Phân loại:** Step contract của PROC-01; không phải UC/BJ canonical.

### PROC-01-STEP-03 — Dựng lại từ ledger

> **Phiên bản:** 4.1.0  
> **Loại:** Procedure Step  
> **Procedure:** PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

### 1. Tổng quan bước kỹ thuật

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Vận hành hệ thống và người đối soát |
| Điều kiện kích hoạt | Có baseline và ledger đáng tin cậy |
| Mục tiêu | Dựng lại từ ledger để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Projection ứng viên được tạo</li><li>Candidate projection</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

### 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Bài tri thức liên quan | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Hiệu năng và năng lực xử lý của hệ thống tồn kho](../01.knowledge/know-how/KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-05 — Reconcile and rebuild projection](../02.specification/behavior/behavioral-contracts/BC-IC-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn dựng: Chỉ dựng từ ledger authoritative tại một cut-off xác định</li><li>Ledger integrity: Nếu ledger không đạt kiểm tra, dừng và escalated; không lấy báo cáo/chứng từ nguồn để tái tạo ledger</li><li>Tính toàn vẹn: Projection ứng viên không được công bố nếu totals/count/hash không đạt</li><li>Publish: Thay projection theo cơ chế nguyên tử hoặc versioned switch; người dùng không thấy dữ liệu trộn giữa hai phiên bản</li><li>Thất bại: Giữ bản hiện hành và bằng chứng rebuild; không ghi đè bằng kết quả bán phần</li><li>Khóa phạm vi: Chỉ khóa phạm vi cần thiết và mở sau khi kiểm tra đạt; failure giữ trạng thái bảo vệ có owner/escalation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

### 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-PROC-01-STEP-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Dựng lại từ ledger” | Projection ứng viên được tạo; kết quả Candidate projection và có truy vết nguồn. |
| AS-PROC-01-STEP-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-PROC-01-STEP-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-PROC-01-STEP-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

### 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-081](../03.design/screens/SCR-081.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

### 5. Hợp đồng kỹ thuật

Câu hỏi mở: ma trận hiện thực BC từng nằm ở FND-TECH-01 chưa được ghi đủ tại procedure này. Hiện thực API, event và transaction thuộc work slice lúc review để implement.

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

### 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo procedure package; step này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-PROC-01-STEP-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định PROC-01-STEP-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của PROC-01-STEP-03. Procedure contract giữ flow kỹ thuật có kiểm soát; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

### Bước 4 — Xác minh và công bố kết quả

> **Phân loại:** Step contract của PROC-01; không phải UC/BJ canonical.

### PROC-01-STEP-04 — Xác minh và công bố kết quả

> **Phiên bản:** 4.1.0  
> **Loại:** Procedure Step  
> **Procedure:** PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

### 1. Tổng quan bước kỹ thuật

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Vận hành hệ thống và người đối soát |
| Điều kiện kích hoạt | Có projection ứng viên |
| Mục tiêu | Xác minh và công bố kết quả để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Bản mới được publish hoặc bản cũ được giữ nguyên</li><li>Validated rebuild result</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

### 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G12 — Ledger, báo cáo và đối soát](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../01.knowledge/decisions/decision-register.md#312-g12-s%E1%BB%95-nghi%E1%BB%87p-v%E1%BB%A5-b%C3%A1o-c%C3%A1o-%C4%91%E1%BB%91i-so%C3%A1t-c%E1%BA%A3nh-b%C3%A1o-v%C3%A0-ph%E1%BB%A5c-h%E1%BB%93i) |
| Bài tri thức liên quan | [Tính chính thức của tồn kho và nguyên tắc chống xuất âm](../01.knowledge/know-how/KB-KGV-006-tinh-chinh-thuc-cua-ton-kho-va-nguyen-tac-chong-xuat-am.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Nhật ký biến động, số dư dẫn xuất và phục hồi sau sự cố](../01.knowledge/know-how/KB-KGV-032-movement-ledger-so-du-dan-xuat-va-phuc-hoi-sau-su-co.md); [Thẻ kho, báo cáo lịch sử và đối soát nguồn](../01.knowledge/know-how/KB-KGV-033-the-kho-bao-cao-lich-su-va-doi-soat-nguon.md); [Hiệu năng và năng lực xử lý của hệ thống tồn kho](../01.knowledge/know-how/KB-KGV-040-hieu-nang-va-nang-luc-xu-ly-cua-he-thong-ton-kho.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IC-05 — Reconcile and rebuild projection](../02.specification/behavior/behavioral-contracts/BC-IC-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Nguồn dựng: Chỉ dựng từ ledger authoritative tại một cut-off xác định</li><li>Ledger integrity: Nếu ledger không đạt kiểm tra, dừng và escalated; không lấy báo cáo/chứng từ nguồn để tái tạo ledger</li><li>Tính toàn vẹn: Projection ứng viên không được công bố nếu totals/count/hash không đạt</li><li>Publish: Thay projection theo cơ chế nguyên tử hoặc versioned switch; người dùng không thấy dữ liệu trộn giữa hai phiên bản</li><li>Thất bại: Giữ bản hiện hành và bằng chứng rebuild; không ghi đè bằng kết quả bán phần</li><li>Khóa phạm vi: Chỉ khóa phạm vi cần thiết và mở sau khi kiểm tra đạt; failure giữ trạng thái bảo vệ có owner/escalation</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IC-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

### 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-PROC-01-STEP-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xác minh và công bố kết quả” | Bản mới được publish hoặc bản cũ được giữ nguyên; kết quả Validated rebuild result và có truy vết nguồn. |
| AS-PROC-01-STEP-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-PROC-01-STEP-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-PROC-01-STEP-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

### 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Màn hình liên quan | [SCR-082](../03.design/screens/SCR-082.md); [SCR-083](../03.design/screens/SCR-083.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

### 5. Hợp đồng kỹ thuật

Câu hỏi mở: ma trận hiện thực BC từng nằm ở FND-TECH-01 chưa được ghi đủ tại procedure này. Hiện thực API, event và transaction thuộc work slice lúc review để implement.

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IC-05 | ReconcileAndRebuild | API-C-18 — POST /v1/reconciliation-cases/{id}/resolution-runs | Case/action/rebuild evidence; target mutation in controlled steps | EVT-IC-03 ReconciliationResolved | TST-BC-IC-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

### 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | PROC-01 — Dựng lại dữ liệu dẫn xuất từ sổ kho xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy nhóm màn hình cũ làm phạm vi backend. |
| FE | Giao theo procedure package; step này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-PROC-01-STEP-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định PROC-01-STEP-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của PROC-01-STEP-04. Procedure contract giữ flow kỹ thuật có kiểm soát; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

## 5. Safety / guardrails

Theo technical/finality/reconciliation constraints trong source procedure. Contract thực thi thuộc work slice lúc review để implement.

## 6. Rollback / recovery

Theo source procedure; không bổ sung recovery path mới.

## 7. Verification sau thực hiện

Theo bước xác minh/công bố của source.

## 8. Owner / escalation

Inventory Control / SA-SE theo scope được source quy định.
