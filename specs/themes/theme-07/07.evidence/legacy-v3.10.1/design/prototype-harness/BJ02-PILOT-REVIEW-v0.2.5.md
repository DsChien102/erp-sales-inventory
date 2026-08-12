# BJ-02 / UIF-02 — Pilot Review v0.2.5

> Phạm vi: chỉ BJ-02/UIF-02. Mục tiêu của vòng này là làm BJ-02 đủ sạch để trở thành calibration baseline trước khi tiếp tục các Journey khác.

## 1. Nguồn đã rà

- `srs/02-business-journeys/02-BJ-02-nhan-hang-mua.md`
- `srs/05-use-cases/BJ-02-nhan-hang-mua/UC-02-01..05`
- `srs/06-shared-behavioral-contracts.md`
- `know-how/decisions/decision-register.md`
- `prototype/flows/UIF-02-BJ-02.md`
- `prototype/contracts/screens/SCR-006..013.md`
- Flutter DS public source cho `VBanner`, `VToast`, `VBottomSheet`, `VDatePicker`, `VButton`, `VCardIcon/VIconBox`, `VIcons`.

## 2. Corrections business/flow

### 2.1 Quick receipt là một task liên tục
Nguồn UC-02-02 yêu cầu quick receipt có đủ source/evidence, supplier, product, quantity/status và LOT/expiry khi áp dụng. Vì vậy pilot sửa luồng:

`SCR-006 → SCR-008 → SCR-010`

thay vì bắt user đi `SCR-008 → SCR-009` chỉ để tiếp tục cùng một form task. `SCR-009` giữ riêng cho nhánh document source.

### 2.2 Quick receipt luôn phê duyệt
Không có nhánh dưới ngưỡng đi thẳng READY. Khi draft hợp lệ, submit luôn tạo ApprovalCase và `PENDING_APPROVAL`.

### 2.3 Blocker trước submit
- Thiếu price/FX basis → `APPROVAL_PRICE_BASIS_REQUIRED`, giữ `DRAFT`.
- Không có eligible approver → `APPROVER_CONFIGURATION_MISSING`, giữ `DRAFT`.
UI không tự suy ra/cấp cao nhất để vượt blocker.

### 2.4 Warehouse Phase 1 là context, không phải choice
Shared contract quy định server tự điền store/warehouse mặc định và API không chấp nhận cặp khác. Prototype vì vậy hiển thị warehouse read-only thay vì selector.

### 2.5 Over-source dùng accepted quantity
Nhận theo chứng từ đánh giá vượt nguồn theo lượng `accepted` lũy kế ở base UOM trên source line; không dùng total delivered. Rejected quantity không tạo movement.

### 2.6 Tracking policy
- `NONE`: không hỏi lot/expiry.
- `LOT`: lot code bắt buộc khi có lượng nhận.
- Expiry chỉ bắt buộc nếu `expiry_required=true`.
- Lot code là mã nhà sản xuất/đóng gói; draft không tạo lot master.
- Existing lot có expiry conflict → blocker.

### 2.7 Valuation
Hàng accepted sau receipt vẫn vào `VALUATION_PENDING`. Receipt không tự hoàn tất valuation/sellability.

### 2.8 Approval outcome
Pilot đã chốt chỉ:
- `APPROVE`
- `REJECT` + reason bắt buộc.

Legacy text “Yêu cầu bổ sung” trong BJ/UC đã được back-propagate loại bỏ. Submitted payload/version đã khóa; nếu cần sửa sau submit thì kết thúc/cancel yêu cầu hiện tại và tạo replacement operation có audit link, không unlock payload cũ.

### 2.9 Financial masking
Price basis/risk value là `FINANCIAL_RESTRICTED`. System vẫn có thể tính policy/routing, nhưng khi actor thiếu quyền thì server không gửi các giá trị này vào UI/DOM. Prototype có state `FINANCIAL_MASKED` cho SCR-010/011.

## 3. UX/UI corrections

### SCR-006
- Choice cards không Badge.
- Icon neutral, không semantic color.
- Một chevron thống nhất.
- Whole-card tap.

### SCR-007
- Quantity không bold riêng.
- “n sản phẩm” thay “n dòng hàng”.
- READY không Badge; partial receipt mới dùng Badge.
- Chevron thống nhất SCR-006.

### SCR-008
- Full progressive quick receipt form.
- Source evidence + supplier + warehouse context + business date.
- Product search/confirm trong cùng Screen.
- Quantity/status + conditional LOT/expiry trong cùng Screen.
- Không lặp UOM.
- Blocker price/approver hiển thị rõ trước review.

### SCR-009
- Product/source prefilled, compact.
- Giảm padding lot allocation.
- Bỏ helper dưới 4 quantity.
- Bỏ LOT badge lặp.
- Bỏ icon trong lot helper.
- `Thêm lô` = secondary.
- Routine balance không dùng Banner.
- `VDatePicker` expiry giữ trailing calendar affordance nhưng bỏ leading label calendar icon theo yêu cầu pilot.

### SCR-010/011
- Routing/risk-first.
- Financial masking.
- SCR-011 chỉ approve/reject.
- Reject reason bằng `VBottomSheet`.

### SCR-012/013
- Auto execution.
- Result surface là confirmation chính; không toast trùng nghĩa.
- UNKNOWN same operation identity; không blind retry.
- Approval evidence chỉ xuất hiện nếu operation thực sự đã qua approval.

## 4. Flutter DS conformance

- `VBanner`: semantic background/accent theo status, không tự thêm outline.
- `VToast`: dark toast surface; semantic leading circular `VIconBox`; close là plain `VIcons.close`.
- `VBottomSheet`: DS sheet shell (handle/title/divider/safe area), không thêm close icon.
- `VButton`: footer medium; add-lot secondary.
- `VIcons.success`: circle-check, không circle-check-big.
- Permission/data-not-displayable: `VEmptyState`.

### Pilot exception cần DS owner quyết định

`BJ02-UX-01_NO_LEADING_DATE_LABEL_ICON`:
- Ở expiry field, pilot bỏ leading calendar icon cạnh label để giảm noise.
- Trailing calendar affordance vẫn giữ.
- Flutter `VDatePicker` hiện render cả leading + trailing icon, nên đây là explicit exception; không được coi là parity 100% cho tới khi DS owner chốt.

## 5. Fixture vs business truth

Các giá trị như `PN-260816-04`, `GD-817-22`, `85.000 đ/hộp`, `Cấp 1`, `120 hộp` chỉ là fixture để kiểm UX. Business contract nằm ở SRS/shared contracts/decision register; prototype không biến fixture thành API rule.

## 6. Pilot readiness gate

BJ-02 chỉ được xem là calibration baseline khi:
- business/flow trace đồng nhất;
- 8 Screen Contracts đồng nhất với UIF;
- DS mapping không có component/prop tự chế;
- state/permission/financial masking đúng;
- quick/document paths chạy end-to-end;
- visual review trên canonical 402 × 874 pass.
