# AGG-PUR-04 — Chương trình chiết khấu mua hàng (`PurchaseDiscountProgram`)

**Status:** `PROPOSED_UNFROZEN`

## Mục đích

Lưu điều khoản thương mại theo kỳ một cách versioned/effective-dated để hệ thống biết **ai, cái gì, trong kỳ nào, theo căn cứ nào, đạt ngưỡng nào thì hưởng quyền lợi gì**.

## Root và thành phần

- `PurchaseDiscountProgram` — identity của chương trình.
- `DiscountProgramVersion` — bộ điều khoản có hiệu lực.
- `EligibilityScope` — NCC, products/product groups, UOM/conversion context và exclusions.
- `QualificationRule` — basis tính progress.
- `DiscountTier` — threshold/bậc.
- `BenefitRule` — %/amount/application mode và rule phân bổ.

## Lifecycle đề xuất

`Nháp → Sắp hiệu lực → Đang hiệu lực → Kết thúc` hoặc `Hủy`.

Lifecycle không đồng nghĩa quyền lợi đã earned; entitlement được đánh giá riêng.

## Invariant

1. Program thuộc một NCC hoặc một commercial counterparty scope được business xác nhận.
2. Mỗi version có kỳ/effective window rõ.
3. Scope và rule thay đổi tạo version mới.
4. `qualification_basis`, `benefit_application_mode`, threshold/tier và benefit type phải tường minh; không để downstream tự suy diễn.
5. Program tương lai không tự kéo giao dịch quá khứ vào scope nếu rule không cho phép.
6. Terms không chứa forecast numbers; forecast thuộc AGG-PUR-05.

## Candidate rule set

- Application mode: `TOÀN_KỲ_KHI_ĐẠT` hoặc `PHẦN_VƯỢT_NGƯỠNG`.
- Multi-tier: hỗ trợ ở model.
- Benefit type Phase candidate: `% giảm` và `số tiền giảm`; hàng tặng `FUTURE_CANDIDATE` nếu chưa chốt.

## Blocker

Q-01/Q-02/Q-04/Q-03.
