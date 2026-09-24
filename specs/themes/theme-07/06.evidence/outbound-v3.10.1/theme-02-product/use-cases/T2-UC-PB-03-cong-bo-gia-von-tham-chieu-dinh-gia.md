> **Phân loại:** Handoff tạm thời trong `outbound/`; không phải UC canonical Theme 7.

# T2-UC-PB-03 — Resolve giá vốn tham chiếu

> **Phiên bản:** 4.1.0  
> **Loại:** Trường hợp sử dụng  
> **Hành trình nghiệp vụ:** [T2-BJ-PRICING-BASIS — Chuẩn bị giá bán từ giá vốn tham chiếu định giá](../t2-bj-pricing-basis.md)  
> **Trạng thái:** SPECIFIED_FOR_REVIEW

# 1. Tổng quan

| Thuộc tính | Nội dung |
|---|---|
| Tác nhân chính | Người phụ trách định giá bán |
| Điều kiện kích hoạt | Nguồn hợp lệ được rà soát |
| Mục tiêu | Công bố giá vốn tham chiếu định giá để tạo kết quả nghiệp vụ có thể truy vết và kiểm thử độc lập. |
| Kết quả thành công | <ul><li>PricingCostBasisVersion được tạo</li><li>Versioned pricing basis, không phải Official Cost</li></ul> |
| Kết quả không thành công | <ul><li>Yêu cầu bị từ chối có mã/lý do rõ ràng.</li><li>Không tạo tác động authoritative ngoài draft hoặc bằng chứng được hợp đồng cho phép.</li><li>Dữ liệu nhập được giữ lại khi việc sửa và thử lại là an toàn.</li></ul> |
| Kết quả chưa xác định | <ul><li>Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp.</li></ul> |

# 2. Hợp đồng hành vi

| Thuộc tính | Nội dung |
|---|---|
| Nguồn quyết định | [Nhóm G14 — Kiến trúc MVP, chiết khấu mua hàng và định giá bán](../../../../01.knowledge/decisions/decision-register.md#314-g14-chi%E1%BA%BFt-kh%E1%BA%A5u-mua-h%C3%A0ng-%C4%91%E1%BB%8Bnh-gi%C3%A1-b%C3%A1n-v%C3%A0-l%E1%BB%A3i-nhu%E1%BA%ADn) |
| Bài tri thức liên quan | [Đơn giá tồn kho chính thức và tổng giá trị ghi sổ](../../../../01.knowledge/know-how/KB-KGV-015-don-gia-ton-kho-chinh-thuc-va-tong-gia-tri-ghi-so.md); [Công bố đơn giá tồn kho và ghi nhận giá vốn xuất bán](../../../../01.knowledge/know-how/KB-KGV-017-cong-bo-don-gia-ton-kho-va-ghi-nhan-gia-von-xuat-ban.md); [Kịch bản chiết khấu mua hàng theo kỳ](../../../../01.knowledge/know-how/KB-KGV-043-kich-ban-chiet-khau-mua-hang-theo-ky.md); [Từ giá vốn tham chiếu đến giá bán giao dịch](../../../../01.knowledge/know-how/KB-KGV-044-tu-gia-von-tham-chieu-den-gia-ban-giao-dich.md) |
| Hợp đồng dùng chung | [SBC-COM-01 — Bao yêu cầu và định danh](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-02 — Quyền, phạm vi và điều kiện cần](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-03 — Kết quả và phục hồi](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md); [SBC-COM-04 — Finality và tính nguyên tử](../../../../02.specification/behavior/behavioral-contracts/BC-COMMON-EXTENSIONS.md) |
| Hợp đồng hành vi chính | [BC-XD-02 — Publish pricing cost basis and draft](../../../../02.specification/behavior/behavioral-contracts/BC-XD-02.md) |
| Điều kiện cần | Quyền chức năng và phạm vi dữ liệu hợp lệ; tenant/store/warehouse đúng ngữ cảnh; nguồn, policy và lifecycle cho phép thực hiện. |
| Điều kiện đầu vào và định danh | Command envelope dùng chung; source/aggregate ID và version; payload nghiệp vụ; idempotency key; actor, tenant, store và warehouse scope. |
| Quy tắc và bất biến | <ul><li>Hai nguồn được phép: OFFICIAL_COST phải mang Official Cost version; PROJECTED_PURCHASE_DISCOUNT phải mang scenario version</li><li>Provenance: Basis lưu source type/version/value, actor và effective time; không cho nhập số tham chiếu mất nguồn</li><li>Tách khái niệm: Giá vốn tham chiếu định giá không phải Official Cost và không phải giá vốn kế toán</li><li>Giá dự thảo: Basis + chính sách lợi nhuận tạo floor/list draft; chưa thay active price</li><li>Giá bán giao dịch: Active list price còn phải qua publication; promotion và transaction context thuộc Pricing/Sales, ngoài BJ này</li><li>Nguồn projected: Phải hiện rõ rủi ro dự kiến; người dùng có thể chọn nhưng không được dùng làm COGS</li></ul> |
| Thay đổi trạng thái và tác động | Chỉ tạo thay đổi được nêu trong BC-XD-02; UI hoặc adapter không được tự thêm transition. |
| Kiểm toán | Lưu actor, thời điểm nghiệp vụ/ghi nhận, source/version, correlation ID và bằng chứng quyết định áp dụng. |

# 3. Kịch bản nghiệm thu

| ID | Given | When | Then |
|---|---|---|---|
| AS-T2-UC-PB-03-01 | Điều kiện cần hợp lệ và dữ liệu đầu vào đầy đủ | Tác nhân thực hiện “Công bố giá vốn tham chiếu định giá” | PricingCostBasisVersion được tạo; kết quả Versioned pricing basis, không phải Official Cost và có truy vết nguồn. |
| AS-T2-UC-PB-03-02 | Thiếu quyền, sai phạm vi, source stale hoặc dữ liệu vi phạm rule | Yêu cầu được gửi | Bị từ chối trước tác động authoritative; trả mã lỗi và hướng khắc phục an toàn. |
| AS-T2-UC-PB-03-03 | Cùng định danh yêu cầu được gửi lại | Adapter hoặc người dùng thử lại | Trả cùng kết quả đã có hoặc conflict payload; không tạo tác động trùng. |
| AS-T2-UC-PB-03-04 | Không đủ bằng chứng về kết quả cuối | Client timeout hoặc xử lý bị gián đoạn | Nếu chưa chứng minh được commit/no-commit, trả UNKNOWN; giữ nguyên operation/idempotency identity và đối soát trước mọi lần thử tiếp. |

# 4. Hợp đồng UI

| Thuộc tính | Nội dung |
|---|---|
| Bề mặt UI liên quan | [SG-16 — Kịch bản mua và định giá](../../shared-prototype/contracts/sg-16/ui-contract.md) |
| Quy tắc sở hữu | Có thể dùng chung màn hình với UC khác. UI Contract được viết một lần theo bề mặt; file này chỉ sở hữu hành vi và lát nghiệm thu của UC. |
| Các trạng thái của màn hình | READY, LOADING/PROCESSING, VALIDATION_ERROR, PERMISSION_DENIED, CONFLICT/STALE và trạng thái kết quả tương ứng. Chỉ khai state thật sự có ý nghĩa với màn hình. |
| Hành động | Mỗi CTA mutation liên kết đúng một Action ID → UC/BC → API; action không đủ quyền không xuất hiện. |
| Phản hồi | Nêu rõ điều vừa xảy ra, tác động dữ liệu và bước tiếp theo; giữ input ở validation/conflict/UNKNOWN khi an toàn. |
| Khả năng sử dụng | Mobile-first; tên màn hình thấy trước khi chọn; touch target tối thiểu 44 px; không dùng chỉ màu để truyền trạng thái. |

# 5. Hợp đồng kỹ thuật

Xem [hợp đồng kỹ thuật dùng chung và ma trận hiện thực BC](../../../../02.specification/technical-contracts/FND-TECH-01.md#4-bc-realization-matrix).

| BC | Handler | Adapter/API | Transaction boundary | Event/kết quả | Test prefix |
|---|---|---|---|---|---|
| BC-XD-02 | PublishPricingCostBasis | External API-X-02 — POST /v1/pricing-cost-bases | Pricing basis + draft only | EVT-XD-01 PricingCostBasisPublished | TST-BC-XD-02 |

- Request của từng operation nằm cùng dòng BC/operation; không tách heading rời khỏi operation mà nó giải thích.
- Server kiểm tra lại quyền, scope, lifecycle, version và idempotency; UI validation không thay thế server guard.
- HTTP timeout không phải bằng chứng thất bại. Kết quả authoritative lấy từ command receipt/operation result và ledger evidence.

# 6. Truy vết và lát giao hàng

| Phạm vi | Cách dùng |
|---|---|
| BA | [T2-BJ-PRICING-BASIS — Chuẩn bị giá bán từ giá vốn tham chiếu định giá](../t2-bj-pricing-basis.md) xác định vị trí nghiệp vụ; file này khóa hành vi và tiêu chí nghiệm thu. |
| BE | Cài đặt handler/transaction theo BC và API ở phần 5; không lấy Screen Group làm phạm vi backend. |
| FE | Giao theo work package của BJ; trong package đó, UC này là một lát nghiệm thu theo màn hình × state × action. |
| QA | Tạo test từ AS-T2-UC-PB-03-*, BC test prefix và rule/bất biến ở phần 2. |
| Harness | Dùng ID ổn định T2-UC-PB-03, các BC/API/test prefix và link tương đối làm seed; registry không sao chép quy tắc. |

> File này là nguồn đặc tả của T2-UC-PB-03. Business Journey chỉ giữ flow đầu-cuối; UI Contract chỉ giữ cấu trúc/trạng thái bề mặt; hợp đồng dùng chung chỉ được định nghĩa một lần.

