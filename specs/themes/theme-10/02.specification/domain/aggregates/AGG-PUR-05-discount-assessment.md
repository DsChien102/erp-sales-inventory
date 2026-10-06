# AGG-PUR-05 — Đánh giá tiến độ và dự báo chiết khấu (`DiscountAssessment`)

**Status:** `PROPOSED_UNFROZEN`

## Mục đích

Tạo snapshot có phiên bản cho một Program Version tại một thời điểm: actual eligible progress, phần còn thiếu, scenario forecast và expected benefit allocation.

## Root và thành phần

- `DiscountAssessment` — logical assessment stream theo program/version.
- `DiscountAssessmentVersion` — immutable snapshot tại `as_of`.
- `AssessmentInputReference` — receipt/order/invoice/return source refs + versions.
- `ProgressBreakdown` — actual eligible theo scope/bucket.
- `ForecastScenario` — assumption set và projected attainment.
- `ExpectedBenefitAllocation` — phân bổ expected benefit theo product/purchase/receipt basis được policy cho phép.

## Invariant

1. Assessment luôn tham chiếu đúng `DiscountProgramVersion`.
2. Actual input và forecast input tách riêng.
3. Một source operation/version không được cộng hai lần trong cùng assessment.
4. Correction/reversal phải invalidate/recompute phần bị ảnh hưởng bằng version mới.
5. UOM khác nhau chỉ được aggregate sau normalization có source.
6. Expected benefit luôn có scenario/version/as_of/assumptions.
7. Assessment không ghi PayableBalance, stock value, Official Cost hoặc Sale Price.
8. Không sinh “xác suất đạt %” nếu chưa có forecasting model được phê duyệt.

## Forecast candidate

`Actual eligible + Open committed eligible + Optional planned eligible` theo scenario.

Mỗi thành phần phải có label, nguồn và rule inclusion. Open order không tự mặc định chắc chắn nhận; weight/probability nếu có là model riêng và Q-08 phải khóa.

## Output

- Confirmed progress.
- Remaining to each tier.
- Scenario attainment.
- Expected commercial benefit.
- Benefit allocations consumable by Kho/Giá vốn để mô phỏng expected receipt/average cost.

## Blocker

Q-01/Q-02/Q-03/Q-04/Q-08 và rounding/UOM normalization policy.
