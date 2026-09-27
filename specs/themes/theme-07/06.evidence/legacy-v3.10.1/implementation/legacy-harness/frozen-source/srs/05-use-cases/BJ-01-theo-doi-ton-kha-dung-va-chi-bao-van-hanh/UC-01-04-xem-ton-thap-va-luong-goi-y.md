# UC-01-04 — Xem tồn thấp và lượng gợi ý

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../../../../../../../02.specification/behavior/journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Chủ cửa hàng, người mua hàng hoặc thủ kho |
| Điều kiện kích hoạt | Có availability và threshold/target |
| Mục tiêu | Xem tồn thấp và lượng gợi ý để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Trạng thái OUT/LOW và lượng gợi ý được hiển thị</li><li>Derived replenishment indicator</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G13 — Bổ sung hàng và vòng đời master data](../../../../../../../../01.knowledge/decisions/decision-register.md#g13); [Nhóm G12 — Cảnh báo, phục hồi, hiệu năng và POS offline](../../../../../../../../01.knowledge/decisions/decision-register.md#g12) |
| Bài tri thức liên quan | [Tồn dự kiến và đề xuất bổ sung hàng](../../../../../../../../01.knowledge/know-how/KB-KGV-036-ton-du-kien-va-de-xuat-bo-sung-hang.md); [Cảnh báo tồn kho và vòng đời xử lý](../../../../../../../../01.knowledge/know-how/KB-KGV-038-canh-bao-ton-kho-va-vong-doi-xu-ly.md); [Hàng cận hạn, hết hạn, hư hỏng và tiêu hủy](../../../../../../../../01.knowledge/know-how/KB-KGV-014-hang-can-han-het-han-hu-hong-va-tieu-huy.md); [Tồn vật lý và tồn khả dụng](../../../../../../../../01.knowledge/know-how/KB-KGV-005-ton-vat-ly-va-ton-kha-dung.md) |
| Hợp đồng dùng chung | [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả dùng chung](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-IO-14 — Query low stock suggestions](../../../../../../../../02.specification/behavior/behavioral-contracts/BC-IO-14.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | tenant_id, phạm vi đọc, filter/cut-off/as-of, quyền xem và correlation ID. |
| Quy tắc và bất biến | <ul><li>Căn cứ tồn: Chỉ dùng available quantity hiện hành; không cộng hàng sắp về hoặc trừ nhu cầu dự kiến</li><li>Hết/tồn thấp: OUT khi available bằng 0; LOW khi 0 < available ≤ threshold</li><li>Lượng gợi ý: max(0, target_stock_level − available_quantity) theo đơn vị cơ sở</li><li>Thiếu cấu hình: Gắn NOT_CONFIGURED; không tự suy ra threshold/target</li><li>Cận/hết hạn: Product override ưu tiên tenant default; hết hạn bị loại khỏi khả dụng theo ngày nghiệp vụ dù chỉ báo chưa được mở</li><li>LOT/NONE: Chỉ sản phẩm/lượng có expiry mới xuất hiện trong danh sách cận/hết hạn</li></ul> |
| Thay đổi trạng thái và tác động | Không đổi trạng thái authoritative; chỉ trả read model/snapshot có thời điểm dữ liệu. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-UC-01-04-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Xem tồn thấp và lượng gợi ý” | Trạng thái OUT/LOW và lượng gợi ý được hiển thị; kết quả Derived replenishment indicator và có truy vết nguồn. |
| AS-UC-01-04-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-UC-01-04-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-UC-01-04-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-12 — Chính sách tồn và chỉ báo](../../../prototype/contracts/sg-12/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-IO-14 | QueryLowStockSuggestions | API-Q-02 — GET /v1/inventory/low-stock | Read projection | Query result only | TST-BC-IO-14 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [BJ-01 — Theo dõi tồn, khả dụng và chỉ báo vận hành](../../../../../../../../02.specification/behavior/journeys/BJ-01-theo-doi-ton-kha-dung-va-chi-bao-van-hanh.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-UC-01-04-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định UC-01-04, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của UC-01-04. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

