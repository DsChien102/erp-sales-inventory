# SG-16 — Kịch bản chiết khấu và bản nháp định giá

> Phiên bản: `3.1.0` · Package freeze: `T7-PACKAGE-FREEZE-v4.1.0` · Nguồn quyết định: `T7-BASELINE-FREEZE-v4.0.0` · Trạng thái: `STATIC_VALIDATED_DERIVED`.

## 1. Mục tiêu, nguồn và ranh giới

**Mục tiêu:** Ước lượng chiết khấu mua theo kỳ, tính giá vốn dự kiến và tùy chọn công bố làm nguồn định giá.

| Nguồn | Tham chiếu |
|---|---|
| Hành trình chính | `T10-BJ-DISCOUNT-SCENARIO`, `T2-BJ-PRICING-BASIS` |
| SRS UI/UX | [`08-ui-ux.md`](../../../legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/08-ui-ux.md) |
| Hợp đồng hành vi | `BC-XD-01`, `BC-XD-02` |
| Hợp đồng kỹ thuật | `API-X-01`, `API-X-02` |
| Bản chạy | [`prototype/index.html#/sg-16/scr-01`](../../prototype-v4.0.0/index.html#/sg-16/scr-01) |

UI Contract này **không tạo hành vi mới**. Nếu có xung đột, Quyết định nghiệp vụ → SRS → UI Contract → prototype là thứ tự ưu tiên.

## 2. Actor và quyền

| Actor | Khả năng |
|---|---|
| Chủ cửa hàng | Chỉ thấy dữ liệu và action trong tenant/warehouse scope được cấp; máy chủ kiểm tra lại lifecycle, version, permission và maker–checker. |
| Người định giá | Chỉ thấy dữ liệu và action trong tenant/warehouse scope được cấp; máy chủ kiểm tra lại lifecycle, version, permission và maker–checker. |
| Người chỉ xem/không đủ quyền | Không có CTA mutation; dữ liệu tài chính bị loại khỏi DOM nếu thiếu quyền. |

## 3. Luồng màn hình chính thức

`SCR-16-01` Các kịch bản chiết khấu → `SCR-16-02` Nhập giả định mua hàng → `SCR-16-03` Kết quả giá vốn dự kiến → `SCR-16-04` Rà soát nguồn định giá → `SCR-16-05` Kết quả công bố nguồn.

Luồng trên là **đường chính để kiểm chứng UX**. Nhánh lỗi/permission/UNKNOWN không tạo Screen mới khi chỉ là state delta; mỗi state nằm đúng Screen mà người dùng đang làm việc để giữ ngữ cảnh và dữ liệu nhập.

## 4. Danh sách màn hình

| Screen ID | Tên | Mục tiêu | Archetype | Route |
|---|---|---|---|---|
| `SCR-16-01` | Các kịch bản chiết khấu | Xem scenario theo kỳ và version. | `list` | `#/sg-16/scr-01` |
| `SCR-16-02` | Nhập giả định mua hàng | Nhập lượng, giá mua và loại lợi ích dự kiến. | `form` | `#/sg-16/scr-02` |
| `SCR-16-03` | Kết quả giá vốn dự kiến | Xem projected cost và provenance; luôn gắn nhãn không kế toán. | `dashboard` | `#/sg-16/scr-03` |
| `SCR-16-04` | Rà soát nguồn định giá | Chọn có công bố projected cost thành pricing basis hay không. | `review` | `#/sg-16/scr-04` |
| `SCR-16-05` | Kết quả công bố nguồn | Hiển thị basis version và pricing draft riêng. | `result` | `#/sg-16/scr-05` |

## 5. Bao phủ Screen → State → Action

| Screen | State áp dụng và bắt buộc có fixture | Action chính |
|---|---|---|
| `SCR-16-01` | `READY`, `LOADING`, `EMPTY`, `FILTER_EMPTY`, `PERMISSION_DENIED`, `DRAFT_SCENARIO`, `PUBLISHED_AS_PRICING_SOURCE` | Điều hướng/query |
| `SCR-16-02` | `READY`, `VALIDATION_ERROR`, `CONFLICT`, `LOCKED`, `PERMISSION_DENIED` | `ACT-16-CALCULATE` |
| `SCR-16-03` | `READY`, `LOADING`, `EMPTY`, `STALE`, `PERMISSION_DENIED`, `CALCULATED_NON_ACCOUNTING` | Điều hướng/query |
| `SCR-16-04` | `READY`, `VALIDATION_ERROR`, `APPROVAL_REQUIRED`, `PERMISSION_DENIED`, `CALCULATED_NON_ACCOUNTING` | `ACT-16-PUBLISH-BASIS` |
| `SCR-16-05` | `COMPLETED`, `UNKNOWN`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `PUBLISHED_AS_PRICING_SOURCE` | `ACT-16-PUBLISH-BASIS` |

## 6. Nội dung và trạng thái từng màn hình

### 6.1 SCR-16-01 — Các kịch bản chiết khấu

**Mục tiêu:** Xem scenario theo kỳ và version.

**Bố cục:** `list`; `input.search`, `input.select`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- Q3 · Nobivac — Version 4 — Đã tính
- Q3 · Amox — Version 2 — Bản nháp

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `FILTER_EMPTY` | Không có kết quả phù hợp | Giữ bộ lọc và cho phép xóa điều kiện tìm kiếm. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `DRAFT_SCENARIO` | Kịch bản đang là bản nháp | Kết quả chỉ để so sánh; chưa là nguồn tham chiếu định giá được công bố. | Theo dữ liệu nguồn |
| `PUBLISHED_AS_PRICING_SOURCE` | Đã công bố nguồn định giá | Không tự thay đổi giá bán hoặc sổ kế toán. | Theo dữ liệu nguồn |

### 6.2 SCR-16-02 — Nhập giả định mua hàng

**Mục tiêu:** Nhập lượng, giá mua và loại lợi ích dự kiến.

**Bố cục:** `form`; `layout.section`, `input.field-group`, `status.validation-summary`.

**Trường/thông tin mẫu:**
- Sản phẩm: Nobivac DHPPi
- Lượng dự kiến: 1.000 hộp
- Giá mua cơ sở: 83.000 đ
- Chiết khấu: 8% + 20 hộp tặng

**Lưu ý:** Giả định có thể được tạo trước PO và receipt.

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-16-CALCULATE` → `BC-XD-01` → `API-X-01`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `CONFLICT` | Dữ liệu vừa thay đổi | Không ghi đè; tải phiên bản hiện hành để đối chiếu. | Có |
| `LOCKED` | Phạm vi đang bị khóa | Không cho mutation; chỉ dẫn tới công việc đang giữ khóa khi có quyền. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |

### 6.3 SCR-16-03 — Kết quả giá vốn dự kiến

**Mục tiêu:** Xem projected cost và provenance; luôn gắn nhãn không kế toán.

**Bố cục:** `dashboard`; `data.metric-grid`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- Giá vốn dự kiến — Sau chiết khấu — 74.920 đ
- Tiết kiệm dự kiến — Theo kỳ — 8,08 triệu

**Dữ liệu nhạy cảm:** Giá dự kiến chỉ render cho người có quyền định giá/tài chính.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `STALE` | Dữ liệu có thể đã cũ | Hiển thị as-of và yêu cầu làm mới trước mutation. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `CALCULATED_NON_ACCOUNTING` | Đã tính — không phải giá vốn kế toán | Kết quả chỉ phục vụ quyết định định giá bán. | Theo dữ liệu nguồn |

### 6.4 SCR-16-04 — Rà soát nguồn định giá

**Mục tiêu:** Chọn có công bố projected cost thành pricing basis hay không.

**Bố cục:** `review`; `data.review-summary`, `overlay.confirm-dialog`, `action.button`.

**Dòng/thẻ dữ liệu mẫu:**
- Nguồn — PROJECTED_PURCHASE_DISCOUNT — Scenario v4
- Tác động kế toán — Không — 0 bút toán
- Giá bán — Chỉ tạo bản nháp — Chưa công bố

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-16-PUBLISH-BASIS` → `BC-XD-02` → `API-X-02`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `APPROVAL_REQUIRED` | Cần phê duyệt | Yêu cầu đã được ghi nhận nhưng chưa tạo tác động cuối. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `CALCULATED_NON_ACCOUNTING` | Đã tính — không phải giá vốn kế toán | Kết quả chỉ phục vụ quyết định định giá bán. | Theo dữ liệu nguồn |

### 6.5 SCR-16-05 — Kết quả công bố nguồn

**Mục tiêu:** Hiển thị basis version và pricing draft riêng.

**Bố cục:** `result`; `status.result-panel`, `action.next-step`.

**Trường/thông tin mẫu:**
- Pricing basis: PB-260817-04
- Nguồn: Scenario v4
- Pricing draft: PD-260817-08

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-16-PUBLISH-BASIS` → `BC-XD-02` → `API-X-02`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `COMPLETED` | Đã hoàn tất | Hiển thị điều đã xảy ra, tác động dữ liệu và bước tiếp theo. | Theo dữ liệu nguồn |
| `UNKNOWN` | Chưa xác định kết quả | Giữ cùng operation identity và đối soát; không coi là thất bại. | Có |
| `REJECTED_EXECUTION` | Không thể thực hiện | Tác động bằng 0; nêu guard bị vi phạm và đường phục hồi an toàn. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `PUBLISHED_AS_PRICING_SOURCE` | Đã công bố nguồn định giá | Không tự thay đổi giá bán hoặc sổ kế toán. | Theo dữ liệu nguồn |

## 7. Action Contract

| Action ID | Nhãn UI | BC chính | API chính | Quyền/scope | Xác nhận | Tác động tại action này |
|---|---|---|---|---|---|---|
| `ACT-16-CALCULATE` | Tính kịch bản | `BC-XD-01` | `API-X-01` | Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại | Không | Tạo scenario/version; không inventory/AP/accounting mutation |
| `ACT-16-PUBLISH-BASIS` | Công bố giá vốn tham chiếu | `BC-XD-02` | `API-X-02` | Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại | Có | Tạo pricing basis và draft; không tự công bố giá bán |

Mỗi CTA mutation có đúng **một Action ID, một BC chính và một API chính**. Double submit giữ cùng idempotency key; timeout/`UNKNOWN` dùng cùng operation identity để query hoặc đối soát.

## 8. Responsive, accessibility và content

- Thiết kế mobile-first ở viewport tham chiếu `390 px`, kiểm tra tối thiểu đến `360 px` và desktop.
- Tên Screen luôn hiển thị trước khi chọn; không chỉ dùng số `01/02/…`.
- Controller và trace panel của prototype được đánh dấu ngoài sản phẩm; Figma chỉ capture vùng `[data-design-viewport]`.
- Touch target tối thiểu 44 px; keyboard order tự nhiên; visible focus; field/error liên kết bằng label.
- Trạng thái không chỉ phân biệt bằng màu. Mã kỹ thuật nằm ở “Chi tiết hỗ trợ”.
- Validation/conflict/UNKNOWN giữ input khi an toàn và luôn nói rõ **điều vừa xảy ra – tác động dữ liệu – bước tiếp theo**.

## 9. Acceptance và truy vết

| Gate | Phải chứng minh |
|---|---|
| `FLOW-SG-16` | Happy path đi qua toàn bộ 5 Screen, không ngõ cụt và không tạo capability ngoài Phase 1. |
| `STATE-SG-16` | Mỗi state trong §5 chọn/render được trong prototype đúng Screen. |
| `TRACE-SG-16` | Screen → Action → BC → API khớp composition map và manifest. |
| `UX-SG-16` | Tên Screen thấy trước khi chọn; mobile 390/360; back/cancel không mất input ngoài dự kiến. |
| `SAFE-SG-16` | Permission, conflict, lock và UNKNOWN không tạo mutation hoặc finality giả. |

## 10. Ranh giới bằng chứng

Prototype dùng fixture và mutation trong bộ nhớ. Package đạt `STATIC_VALIDATED`; chưa chứng nhận server guard, persistence, visual parity Figma/Flutter hoặc kết quả chạy trong repository sản phẩm.
