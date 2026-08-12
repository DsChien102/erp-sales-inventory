> **Phân loại:** Handoff tạm thời trong `outbound/`; không phải UC canonical Theme 7.

# RPT-UC-PV-03 — Hiển thị ba cách nhìn lợi nhuận

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [RPT-BJ-PROFIT-VIEWS — So sánh ba cách nhìn lợi nhuận](../rpt-bj-profit-views.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Chủ cửa hàng hoặc quản lý phân tích |
| Điều kiện kích hoạt | Có source set |
| Mục tiêu | Hiển thị ba cách nhìn lợi nhuận để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>Ba margin view được tính hoặc đánh dấu incomplete riêng</li><li>Comparison view</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G14 — Kiến trúc MVP, chiết khấu mua hàng và định giá bán](../../../../01.knowledge/decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn) |
| Bài tri thức liên quan | [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Đối soát giá vốn cuối kỳ và cập nhật đột xuất giữa kỳ](../../../../01.knowledge/know-how/KB-KGV-018-doi-soat-gia-von-cuoi-ky-va-cap-nhat-dot-xuat-giua-ky.md); [Từ giá vốn tham chiếu đến giá bán giao dịch](../../../../01.knowledge/know-how/KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md); [Rà soát giá vốn tham chiếu sau chốt kỳ](../../../../01.knowledge/know-how/KB-KGV-045-ra-soat-gia-von-tham-chieu-sau-chot-ky.md) |
| Hợp đồng dùng chung | [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả dùng chung](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-XD-04 — Query margin comparison](../../../../02.specification/behavior/behavioral-contracts/BC-XD-04.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | tenant_id, phạm vi đọc, filter/cut-off/as-of, quyền xem và correlation ID. |
| Quy tắc và bất biến | <ul><li>Lợi nhuận tại giao dịch: Dùng doanh thu giao dịch và initial COGS đã snapshot khi xuất</li><li>Lợi nhuận sau đối soát: Dùng initial COGS cộng các true-up/adjustment liên kết; không rewrite order/issue gốc</li><li>Lợi nhuận dự kiến: Dùng pricing cost basis hiện hành có provenance; không phải số liệu kế toán</li><li>Thiếu dữ liệu: Đánh dấu cách nhìn tương ứng INCOMPLETE; không lấy Official Cost hay projected cost thay thế im lặng</li><li>Nhãn và provenance: Mỗi kết quả có source type/version/as-of; không collapse thành một con số “margin” không rõ nghĩa</li><li>Quyền tài chính: Hệ thống phải bảo vệ nhất quán mọi kênh xem và xuất dữ liệu; không chỉ ẩn bằng giao diện</li></ul> |
| Thay đổi trạng thái và tác động | Không đổi trạng thái authoritative; chỉ trả read model/snapshot có thời điểm dữ liệu. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-RPT-UC-PV-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Hiển thị ba cách nhìn lợi nhuận” | Ba margin view được tính hoặc đánh dấu incomplete riêng; kết quả Comparison view và có truy vết nguồn. |
| AS-RPT-UC-PV-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-RPT-UC-PV-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-RPT-UC-PV-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Không có finality mutation. Nếu nguồn đọc chưa sẵn sàng hoặc stale, phải trả as_of/stale hoặc lỗi rõ ràng; không suy diễn số liệu. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-17 — Rà soát định giá và lợi nhuận](../../shared-prototype/contracts/sg-17/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../04.architecture/foundations/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-XD-04 | QueryMarginComparison | API-Q-03 — GET /v1/inventory-reports/margin-comparison | Consistent report snapshot | Query result only | TST-BC-XD-04 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [RPT-BJ-PROFIT-VIEWS — So sánh ba cách nhìn lợi nhuận](../rpt-bj-profit-views.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-RPT-UC-PV-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định RPT-UC-PV-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của RPT-UC-PV-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

