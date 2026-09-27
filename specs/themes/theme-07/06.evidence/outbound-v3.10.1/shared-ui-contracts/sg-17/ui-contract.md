# SG-17 — Rà soát căn cứ định giá và lợi nhuận

> Phiên bản: `3.1.0` · Package freeze: `T7-PACKAGE-FREEZE-v4.1.0` · Nguồn quyết định: `T7-BASELINE-FREEZE-v4.0.0` · Trạng thái: `STATIC_VALIDATED_DERIVED`.

## 1. Mục tiêu, nguồn và ranh giới

**Mục tiêu:** Sau chốt kỳ, quyết định giữ/cập nhật nguồn định giá và so sánh ba cách nhìn lợi nhuận.

| Nguồn | Tham chiếu |
|---|---|
| Hành trình chính | `T2-BJ-PRICING-REVIEW`, `RPT-BJ-PROFIT-VIEWS` |
| SRS UI/UX | [`08-ui-ux.md`](../../../legacy-v3.10.1/implementation/legacy-harness/frozen-source/srs/08-ui-ux.md) |
| Hợp đồng hành vi | `BC-XD-04`, `BC-XD-03` |
| Hợp đồng kỹ thuật | `API-Q-03`, `API-X-03` |
| Bản chạy | [`prototype/index.html#/sg-17/scr-01`](../../prototype-v4.0.0/index.html#/sg-17/scr-01) |

UI Contract này **không tạo hành vi mới**. Nếu có xung đột, Quyết định nghiệp vụ → SRS → UI Contract → prototype là thứ tự ưu tiên.

## 2. Actor và quyền

| Actor | Khả năng |
|---|---|
| Người định giá | Chỉ thấy dữ liệu và action trong tenant/warehouse scope được cấp; máy chủ kiểm tra lại lifecycle, version, permission và maker–checker. |
| Kế toán | Chỉ thấy dữ liệu và action trong tenant/warehouse scope được cấp; máy chủ kiểm tra lại lifecycle, version, permission và maker–checker. |
| Người chỉ xem/không đủ quyền | Không có CTA mutation; dữ liệu tài chính bị loại khỏi DOM nếu thiếu quyền. |

## 3. Luồng màn hình chính thức

`SCR-17-01` Đợt rà soát định giá → `SCR-17-02` Nhóm theo nguồn hiện tại → `SCR-17-03` Quyết định theo sản phẩm → `SCR-17-04` So sánh lợi nhuận → `SCR-17-05` Rà soát quyết định → `SCR-17-06` Kết quả áp dụng.

Luồng trên là **đường chính để kiểm chứng UX**. Nhánh lỗi/permission/UNKNOWN không tạo Screen mới khi chỉ là state delta; mỗi state nằm đúng Screen mà người dùng đang làm việc để giữ ngữ cảnh và dữ liệu nhập.

## 4. Danh sách màn hình

| Screen ID | Tên | Mục tiêu | Archetype | Route |
|---|---|---|---|---|
| `SCR-17-01` | Đợt rà soát định giá | Xem batch phát sinh sau official cost published. | `list` | `#/sg-17/scr-01` |
| `SCR-17-02` | Nhóm theo nguồn hiện tại | Tách basis từ official cost và projected scenario. | `dashboard` | `#/sg-17/scr-02` |
| `SCR-17-03` | Quyết định theo sản phẩm | Chọn giữ nguồn cũ, dùng official cost mới hoặc tính lại scenario. | `form` | `#/sg-17/scr-03` |
| `SCR-17-04` | So sánh lợi nhuận | Xem margin tại giao dịch, đã đối soát và dự kiến. | `dashboard` | `#/sg-17/scr-04` |
| `SCR-17-05` | Rà soát quyết định | Kiểm số lượng quyết định và tác động tới basis/draft. | `review` | `#/sg-17/scr-05` |
| `SCR-17-06` | Kết quả áp dụng | Hiển thị basis versions và pricing drafts; giá bán chưa tự công bố. | `result` | `#/sg-17/scr-06` |

## 5. Bao phủ Screen → State → Action

| Screen | State áp dụng và bắt buộc có fixture | Action chính |
|---|---|---|
| `SCR-17-01` | `READY`, `LOADING`, `EMPTY`, `FILTER_EMPTY`, `PERMISSION_DENIED` | Điều hướng/query |
| `SCR-17-02` | `READY`, `LOADING`, `EMPTY`, `STALE`, `PERMISSION_DENIED`, `BULK_ELIGIBLE_OFFICIAL`, `INDIVIDUAL_DECISION_REQUIRED` | Điều hướng/query |
| `SCR-17-03` | `READY`, `VALIDATION_ERROR`, `CONFLICT`, `LOCKED`, `PERMISSION_DENIED`, `INDIVIDUAL_DECISION_REQUIRED` | `ACT-17-APPLY-REVIEW` |
| `SCR-17-04` | `READY`, `LOADING`, `EMPTY`, `STALE`, `PERMISSION_DENIED`, `MARGIN_SOURCE_INCOMPLETE` | `ACT-17-REFRESH-MARGIN` |
| `SCR-17-05` | `READY`, `VALIDATION_ERROR`, `APPROVAL_REQUIRED`, `PERMISSION_DENIED`, `DRAFT_NOT_PUBLISHED` | `ACT-17-APPLY-REVIEW` |
| `SCR-17-06` | `COMPLETED`, `UNKNOWN`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `DRAFT_NOT_PUBLISHED` | `ACT-17-APPLY-REVIEW` |

## 6. Nội dung và trạng thái từng màn hình

### 6.1 SCR-17-01 — Đợt rà soát định giá

**Mục tiêu:** Xem batch phát sinh sau official cost published.

**Bố cục:** `list`; `input.search`, `input.select`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- REV-2026-08 — 84 sản phẩm — Cần quyết định
- REV-2026-07 — Đã hoàn tất — 84/84

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `FILTER_EMPTY` | Không có kết quả phù hợp | Giữ bộ lọc và cho phép xóa điều kiện tìm kiếm. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |

### 6.2 SCR-17-02 — Nhóm theo nguồn hiện tại

**Mục tiêu:** Tách basis từ official cost và projected scenario.

**Bố cục:** `dashboard`; `data.metric-grid`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- Nguồn official cost — Có thể cập nhật hàng loạt — 62 sản phẩm
- Nguồn dự kiến chiết khấu — Cần quyết định riêng — 22 sản phẩm

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** Điều hướng hoặc truy vấn, không tạo mutation.

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `STALE` | Dữ liệu có thể đã cũ | Hiển thị as-of và yêu cầu làm mới trước mutation. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `BULK_ELIGIBLE_OFFICIAL` | Có thể cập nhật hàng loạt | Nhóm này đang dựa trên giá vốn chính thức kỳ trước và đủ điều kiện áp dụng cùng quyết định. | Theo dữ liệu nguồn |
| `INDIVIDUAL_DECISION_REQUIRED` | Cần quyết định từng sản phẩm | Không ghi đè nguồn dự kiến theo lô cập nhật hàng loạt. | Theo dữ liệu nguồn |

### 6.3 SCR-17-03 — Quyết định theo sản phẩm

**Mục tiêu:** Chọn giữ nguồn cũ, dùng official cost mới hoặc tính lại scenario.

**Bố cục:** `form`; `layout.section`, `input.field-group`, `status.validation-summary`.

**Trường/thông tin mẫu:**
- Sản phẩm: Nobivac DHPPi
- Nguồn hiện tại: Scenario v4
- Quyết định: Giữ nguồn hiện tại

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-17-APPLY-REVIEW` → `BC-XD-03` → `API-X-03`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `CONFLICT` | Dữ liệu vừa thay đổi | Không ghi đè; tải phiên bản hiện hành để đối chiếu. | Có |
| `LOCKED` | Phạm vi đang bị khóa | Không cho mutation; chỉ dẫn tới công việc đang giữ khóa khi có quyền. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `INDIVIDUAL_DECISION_REQUIRED` | Cần quyết định từng sản phẩm | Không ghi đè nguồn dự kiến theo lô cập nhật hàng loạt. | Theo dữ liệu nguồn |

### 6.4 SCR-17-04 — So sánh lợi nhuận

**Mục tiêu:** Xem margin tại giao dịch, đã đối soát và dự kiến.

**Bố cục:** `dashboard`; `data.metric-grid`, `data.list`.

**Dòng/thẻ dữ liệu mẫu:**
- Margin tại giao dịch — Giá vốn snapshot — 31,4%
- Margin đã đối soát — Official cost mới — 29,8%
- Margin dự kiến — Scenario chiết khấu — 34,2%

**Dữ liệu nhạy cảm:** Margin và cost basis chỉ render cho quyền tài chính/định giá.

**Hành động chính:** `ACT-17-REFRESH-MARGIN` → `BC-XD-04` → `API-Q-03`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `LOADING` | Đang tải | Giữ nguyên bố cục; không dùng số 0 giả. | Theo dữ liệu nguồn |
| `EMPTY` | Chưa có dữ liệu | Hiển thị lý do rỗng và bước tiếp theo hợp lệ. | Theo dữ liệu nguồn |
| `STALE` | Dữ liệu có thể đã cũ | Hiển thị as-of và yêu cầu làm mới trước mutation. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `MARGIN_SOURCE_INCOMPLETE` | Thiếu nguồn tính lợi nhuận | Hiển thị cách nhìn nào chưa đủ căn cứ. | Theo dữ liệu nguồn |

### 6.5 SCR-17-05 — Rà soát quyết định

**Mục tiêu:** Kiểm số lượng quyết định và tác động tới basis/draft.

**Bố cục:** `review`; `data.review-summary`, `overlay.confirm-dialog`, `action.button`.

**Dòng/thẻ dữ liệu mẫu:**
- Cập nhật official cost — Hàng loạt — 62
- Giữ scenario — Quyết định riêng — 16
- Tính lại scenario — Quyết định riêng — 6

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-17-APPLY-REVIEW` → `BC-XD-03` → `API-X-03`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `READY` | Sẵn sàng | Dữ liệu hiện hành đã sẵn sàng để thao tác. | Theo dữ liệu nguồn |
| `VALIDATION_ERROR` | Cần kiểm tra dữ liệu | Giữ dữ liệu đã nhập và đưa focus tới lỗi đầu tiên. | Có |
| `APPROVAL_REQUIRED` | Cần phê duyệt | Yêu cầu đã được ghi nhận nhưng chưa tạo tác động cuối. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `DRAFT_NOT_PUBLISHED` | Bản nháp chưa công bố | Chưa làm thay đổi giá bán áp dụng. | Theo dữ liệu nguồn |

### 6.6 SCR-17-06 — Kết quả áp dụng

**Mục tiêu:** Hiển thị basis versions và pricing drafts; giá bán chưa tự công bố.

**Bố cục:** `result`; `status.result-panel`, `action.next-step`.

**Trường/thông tin mẫu:**
- Review batch: REV-2026-08
- Basis versions: 84
- Giá bán đã công bố: 0

**Dữ liệu nhạy cảm:** Không có dữ liệu nhạy cảm đặc thù ngoài permission masking chung.

**Hành động chính:** `ACT-17-APPLY-REVIEW` → `BC-XD-03` → `API-X-03`

| State | Nhãn người dùng | Cách thể hiện và phục hồi | Giữ input? |
|---|---|---|---|
| `COMPLETED` | Đã hoàn tất | Hiển thị điều đã xảy ra, tác động dữ liệu và bước tiếp theo. | Theo dữ liệu nguồn |
| `UNKNOWN` | Chưa xác định kết quả | Giữ cùng operation identity và đối soát; không coi là thất bại. | Có |
| `REJECTED_EXECUTION` | Không thể thực hiện | Tác động bằng 0; nêu guard bị vi phạm và đường phục hồi an toàn. | Theo dữ liệu nguồn |
| `PERMISSION_DENIED` | Không có quyền truy cập | Không đưa dữ liệu nhạy cảm vào DOM và không hiển thị CTA mutation. | Theo dữ liệu nguồn |
| `DRAFT_NOT_PUBLISHED` | Bản nháp chưa công bố | Chưa làm thay đổi giá bán áp dụng. | Theo dữ liệu nguồn |

## 7. Action Contract

| Action ID | Nhãn UI | BC chính | API chính | Quyền/scope | Xác nhận | Tác động tại action này |
|---|---|---|---|---|---|---|
| `ACT-17-REFRESH-MARGIN` | Làm mới so sánh lợi nhuận | `BC-XD-04` | `API-Q-03` | Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại | Không | Query báo cáo nhất quán; không mutation |
| `ACT-17-APPLY-REVIEW` | Áp dụng quyết định rà soát | `BC-XD-03` | `API-X-03` | Quyền theo hợp đồng kỹ thuật, tenant và warehouse scope; máy chủ kiểm tra lại | Có | Tạo basis version/pricing draft; không tự công bố giá bán |

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
| `FLOW-SG-17` | Happy path đi qua toàn bộ 6 Screen, không ngõ cụt và không tạo capability ngoài Phase 1. |
| `STATE-SG-17` | Mỗi state trong §5 chọn/render được trong prototype đúng Screen. |
| `TRACE-SG-17` | Screen → Action → BC → API khớp composition map và manifest. |
| `UX-SG-17` | Tên Screen thấy trước khi chọn; mobile 390/360; back/cancel không mất input ngoài dự kiến. |
| `SAFE-SG-17` | Permission, conflict, lock và UNKNOWN không tạo mutation hoặc finality giả. |

## 10. Ranh giới bằng chứng

Prototype dùng fixture và mutation trong bộ nhớ. Package đạt `STATIC_VALIDATED`; chưa chứng nhận server guard, persistence, visual parity Figma/Flutter hoặc kết quả chạy trong repository sản phẩm.
