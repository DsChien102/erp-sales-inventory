# UC-05-05 — Ghi xuất kho nguyên tử

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng dùng chung  
> **Hành trình nghiệp vụ:** [BJ-05 — Lấy hàng và bàn giao đơn](../../../../../../../../02.specification/behavior/journeys/BJ-05-lay-hang-va-ban-giao-on.md)  
> **Consumer/XREF:** [XREF-01 / T5-BJ-CHECKOUT-POS](../../../../../../../outbound-v3.10.1/theme-05-sales-pos/t5-bj-checkout-pos.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Người dùng có thẩm quyền hoặc hệ thống nguồn |
| Điều kiện kích hoạt | Có lô/nguồn xuất hợp lệ và allocation khi hành trình yêu cầu |
| Mục tiêu | Ghi xuất kho nguyên tử để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Movement, balance, reservation nếu có và cost snapshot cùng commit</li><li>Inventory issue result dùng chung</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G01 — Phạm vi, thẩm quyền và mô hình tồn](../../../../../../../../01.knowledge/decisions/decision-register.md#g01); [Nhóm G04 — Khả dụng, giữ hàng và xuất bán](../../../../../../../../01.knowledge/decisions/decision-register.md#g04) |
| Bài tri thức liên quan | [Chọn hàng để xuất và thời điểm hoàn tất xuất bán](../../../../../../../../01.knowledge/know-how/KB-KGV-010-chon-hang-de-xuat-va-thoi-diem-hoan-tat-xuat-ban.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../../../../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Tính nguyên tử khi ghi tồn kho và phát sự kiện](../../../../../../../../01.knowledge/know-how/KB-KGV-029-tinh-nguyen-tu-khi-ghi-ton-kho-va-phat-su-kien.md); [Bán hàng POS offline](../../../../../../../../01.knowledge/know-how/KB-KGV-039-ban-hang-pos-offline.md); [Giữ hàng và xử lý đơn không đủ tồn khả dụng](../../../../../../../../01.knowledge/know-how/KB-KGV-009-giu-hang-va-xu-ly-don-khong-du-ton-kha-dung.md); [Danh tính và vòng đời của một lô hàng](../../../../../../../../01.knowledge/know-how/KB-KGV-025-danh-tinh-va-vong-doi-cua-mot-lo-hang.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IO-04 — Complete online POS checkout](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-04.md); [BC-IO-05 — Pick and hand over fulfillment](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-05.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Không có official cost: Chặn checkout và yêu cầu hoàn tất định giá; không ghi COGS bằng 0 hoặc giá dự kiến</li><li>Chọn lô: FEFO khi có hạn dùng, FIFO khi không có; override cần quyền và lý do</li><li>Cạnh tranh tồn: Giao dịch ghi nhận trước được ưu tiên; yêu cầu sau phải kiểm lại và có thể bị từ chối</li><li>Combo: Mọi component xuất all-or-nothing theo số nguyên combo</li><li>UNKNOWN: Sales chuyển INVENTORY_CONFIRMATION_PENDING; không tạo issue thứ hai, không tự hoàn tất đơn hay refund</li><li>Payment: Nếu payment đã có trước UNKNOWN, Payment/Sales giữ trạng thái pending resolution theo contract liên miền</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-IO-04, BC-IO-05; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-05-05-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Ghi xuất kho nguyên tử” | Movement, balance, reservation nếu có và cost snapshot cùng commit; kết quả Inventory issue result dùng chung và có truy vết nguồn. |
| AS-UC-05-05-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-05-05-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-05-05-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-06 — Pick, pack và bàn giao](../../../prototype/contracts/sg-06/ui-contract.md); [SG-06 — Pick, pack và bàn giao](../../../prototype/contracts/sg-06/ui-contract.md) |
| Quy tắc sở hữu | Không sở hữu màn hình riêng. UI của UC gọi hiển thị trạng thái tiến trình/kết quả và giữ cùng operation identity. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-04 | CompleteOnlinePosCheckout | API-C-04 — POST /v1/pos-checkouts/inventory-completion | Issue/value movement + balance + result + outbox | EVT-IO-03 PosInventoryCompleted | TST-BC-IO-04 |
| BC-IO-05 | HandOverFulfillment | API-C-05 — POST /v1/fulfillments/{id}/handover | Active allocation set/version + reservation consume + issue/value + balance + outbox | EVT-IO-04 FulfillmentHandedOver | TST-BC-IO-05 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-05 — Lấy hàng và bàn giao đơn](../../../../../../../../02.specification/behavior/journeys/BJ-05-lay-hang-va-ban-giao-on.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-05-05-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-05-05, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-05-05. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

