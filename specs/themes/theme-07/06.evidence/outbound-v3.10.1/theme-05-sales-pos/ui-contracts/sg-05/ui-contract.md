# SG-05 — POS online

> Phiên bản: `3.1.0` · Package freeze: `T7-PACKAGE-FREEZE-v4.1.0` · Nguồn quyết định: `T7-BASELINE-FREEZE-v4.0.0` · Trạng thái: `STATIC_VALIDATED_DERIVED`.

## 1. Mục tiêu, nguồn và ranh giới

**Mục tiêu:** Tìm/quét sản phẩm, lập giỏ và hoàn tất checkout trực tuyến mà không xuất âm tồn.

| Nguồn | Tham chiếu |
|---|---|
| Hành trình chính | `T5-BJ-CHECKOUT-POS` |
| SRS UI/UX | [`08-ui-ux.md`](../../../../legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/08-ui-ux.md) |
| Hợp đồng hành vi | `BC-IO-04` |
| Hợp đồng kỹ thuật | `API-C-04` |
| Bản chạy | [`prototype/index.html#/sg-05/scr-01`](../../../prototype-v4.0.0/index.html#/sg-05/scr-01) |

UI Contract này **không tạo hành vi mới**. Nếu có xung đột, Quyết định nghiệp vụ → SRS → UI Contract → prototype là thứ tự ưu tiên.

## 2. Actor và quyền

| Actor | Khả năng |
|---|---|
| Nhân viên bán hàng | Chỉ thấy dữ liệu và action trong tenant/warehouse scope được cấp; máy chủ kiểm tra lại lifecycle, version, permission và maker–checker. |
| Người chỉ xem/không đủ quyền | Không có CTA mutation; dữ liệu tài chính bị loại khỏi DOM nếu thiếu quyền. |

## 3. Luồng màn hình chính thức

`SCR-05-01` Tìm hoặc quét sản phẩm → `SCR-05-02` Giỏ hàng → `SCR-05-03` Xác nhận lô đề xuất → `SCR-05-04` Rà soát thanh toán → `SCR-05-05` Kết quả bán hàng.

Luồng trên là **đường chính để kiểm chứng UX**. Nhánh lỗi/permission/UNKNOWN không tạo Screen mới khi chỉ là state delta; mỗi state nằm đúng Screen mà người dùng đang làm việc để giữ ngữ cảnh và dữ liệu nhập.

## 4. Danh sách màn hình

| Screen ID | Tên | Mục tiêu | Archetype | Route |
|---|---|---|---|---|
| `SCR-05-01` | Tìm hoặc quét sản phẩm | Thêm sản phẩm đủ điều kiện vào giỏ. | `list` | `#/sg-05/scr-01` |
| `SCR-05-02` | Giỏ hàng | Điều chỉnh số lượng và kiểm tra khả dụng tức thời. | `form` | `#/sg-05/scr-02` |
| `SCR-05-03` | Xác nhận lô đề xuất | Xem lô FEFO/FIFO và chỉ override khi có quyền. | `detail` | `#/sg-05/scr-03` |
| `SCR-05-04` | Rà soát thanh toán | Kiểm lại giỏ, phương thức thanh toán và tác động xuất kho. | `review` | `#/sg-05/scr-04` |
| `SCR-05-05` | Kết quả bán hàng | Hiển thị checkout đã commit hoặc UNKNOWN với cùng request ID. | `result` | `#/sg-05/scr-05` |

## 5. Bao phủ Screen → State → Action

| Screen | State áp dụng và bắt buộc có fixture | Action chính |
|---|---|---|
| `SCR-05-01` | `READY`, `LOADING`, `EMPTY`, `FILTER_EMPTY`, `PERMISSION_DENIED`, `NETWORK_REQUIRED` | Điều hướng/query |
| `SCR-05-02` | `READY`, `VALIDATION_ERROR`, `CONFLICT`, `LOCKED`, `PERMISSION_DENIED`, `INSUFFICIENT_AVAILABLE` | Điều hướng/query |
| `SCR-05-03` | `READY`, `LOADING`, `CONFLICT`, `LOCKED`, `PERMISSION_DENIED`, `LOT_SCAN_REQUIRED` | Điều hướng/query |
| `SCR-05-04` | `READY`, `VALIDATION_ERROR`, `APPROVAL_REQUIRED`, `PERMISSION_DENIED` | `ACT-05-CHECKOUT` |
| `SCR-05-05` | `COMPLETED`, `UNKNOWN`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `UNKNOWN_CHECKOUT` | `ACT-05-CHECKOUT` |

## 6. Nội dung và trạng thái từng màn hình

### 6.1 SCR-05-01 — Tìm hoặc quét sản phẩm

**Mục tiêu:** Thêm sản phẩm đủ điều kiện vào giỏ.

**Bố cục:** `list`; `input.search`, `input.select`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- Nobivac DHPPi — Khả dụng 106 hộp — 185.000 đ
- Amox 500 — Khả dụng 42 hộp — 95.000 đ

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `FILTER_EMPTY` | Không có kết quả phù hợp | Giữ bộ lọc và cho phép xóa điều kiện tìm kiếm. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `NETWORK_REQUIRED` | Cần kết nối | Phase 1 không hoàn tất giao dịch POS khi mất mạng. | Theo dữ liệu nguồn |

### 6.2 SCR-05-02 — Giỏ hàng

**Mục tiêu:** Điều chỉnh số lượng và kiểm tra khả dụng tức thời.

**Bố cục:** `form`; `layout.section`, `input.field-group`, `status.validation-summary`.

**Trường/thông tin mẫu:**
- Nobivac DHPPi: 2 hộp
- Amox 500: 1 hộp
- Tạm tính: 465.000 đ

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `CONFLICT` | Dữ liệu vừa thay đổi | Không ghi đè; tải phiên bản hiện hành để đối chiếu. | Có |
| `LOCKED` | Phạm vi đang bị khóa | Không cho mutation; chỉ dẫn tới công việc đang giữ khóa khi có quyền. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `INSUFFICIENT_AVAILABLE` | Không đủ tồn khả dụng | Không tạo xuất âm hoặc hoàn tất một phần ngoài chính sách. | Theo dữ liệu nguồn |

### 6.3 SCR-05-03 — Xác nhận lô đề xuất

**Mục tiêu:** Xem lô FEFO/FIFO và chỉ override khi có quyền.

**Bố cục:** `detail`; `container.card`, `data.key-value`, `status.banner`.

**Dòng/thẻ dữ liệu mẫu:**
- ND2408 — Hạn 31/12/2027 — Đề xuất · 2 hộp

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `CONFLICT` | Dữ liệu vừa thay đổi | Không ghi đè; tải phiên bản hiện hành để đối chiếu. | Có |
| `LOCKED` | Phạm vi đang bị khóa | Không cho mutation; chỉ dẫn tới công việc đang giữ khóa khi có quyền. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `LOT_SCAN_REQUIRED` | Cần quét hoặc xác nhận lô | Chưa thể checkout sản phẩm theo LOT khi chưa có lô đủ điều kiện. | Theo dữ liệu nguồn |

### 6.4 SCR-05-04 — Rà soát thanh toán

**Mục tiêu:** Kiểm lại giỏ, phương thức thanh toán và tác động xuất kho.

**Bố cục:** `review`; `data.review-summary`, `overlay.confirm-dialog`, `action.button`.

**Dòng/thẻ dữ liệu mẫu:**
- Tổng thanh toán — 3 sản phẩm — 465.000 đ
- Xuất kho — Kho mặc định — 3 đơn vị

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-05-CHECKOUT` → `BC-IO-04` → `API-C-04`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `APPROVAL_REQUIRED` | Cần phê duyệt | Yêu cầu đã được ghi nhận nhưng chưa tạo tác động cuối. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |

### 6.5 SCR-05-05 — Kết quả bán hàng

**Mục tiêu:** Hiển thị checkout đã commit hoặc UNKNOWN với cùng request ID.

**Bố cục:** `result`; `status.result-panel`, `action.next-step`.

**Trường/thông tin mẫu:**
- Đơn hàng: SO-260817-21
- Request ID: POS-7C9A
- Tác động: Đã xuất 3 đơn vị

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-05-CHECKOUT` → `BC-IO-04` → `API-C-04`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `COMPLETED` | Đã hoàn tất | Hiển thị điều đã xảy ra, tác động dữ liệu và bước tiếp theo. | Theo dữ liệu nguồn |
| `UNKNOWN` | Chưa xác định kết quả | Giữ cùng operation identity và đối soát; không coi là thất bại. | Có |
| `REJECTED_EXECUTION` | Không thể thực hiện | Tác động bằng 0; nêu guard bị vi phạm và đường phục hồi an toàn. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `UNKNOWN_CHECKOUT` | Chưa xác định checkout | Tra cứu bằng cùng request ID trước khi thao tác tiếp. | Theo dữ liệu nguồn |

## 7. Action Contract

| Action ID | Nhãn UI | BC chính | API chính | Quyền/scope | Xác nhận | Tác động tại action này |
|---|---|---|---|---|---|---|
| `ACT-05-CHECKOUT` | Thanh toán và xuất kho | `BC-IO-04` | `API-C-04` | Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại | Có | Ghi issue/value movement, COGS snapshot và kết quả checkout nguyên tử |

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
| `FLOW-SG-05` | Happy path đi qua toàn bộ 5 Screen, không ngõ cụt và không tạo capability ngoài Phase 1. |
| `STATE-SG-05` | Mỗi state trong §5 chọn/render được trong prototype đúng Screen. |
| `TRACE-SG-05` | Screen → Action → BC → API khớp composition map và manifest. |
| `UX-SG-05` | Tên Screen thấy trước khi chọn; mobile 390/360; back/cancel không mất input ngoài dự kiến. |
| `SAFE-SG-05` | Permission, conflict, lock và UNKNOWN không tạo mutation hoặc finality giả. |

## 10. Ranh giới bằng chứng

Prototype dùng fixture và mutation trong bộ nhớ. Package đạt `STATIC_VALIDATED`; chưa chứng nhận server guard, persistence, visual parity Figma/Flutter hoặc kết quả chạy trong repository sản phẩm.
