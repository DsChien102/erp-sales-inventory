---
id: BC-IV-04
type: behavioral-contract
theme: theme-07
title: "Ghi điều chỉnh giá trị hàng nhập"
owner: BA
status: FROZEN
source_baseline: v3.12.0
---
# BC-IV-04 — Ghi điều chỉnh giá trị hàng nhập

## 1. Ý định

Ghi một **thành phần điều chỉnh giá trị hàng nhập có dấu** sau khi BJ03 đã xác lập initial value, mà không sửa ReceiptValuation, chứng từ nguồn hoặc cost run lịch sử. Adjustment có thể làm tăng hoặc giảm carrying value.

## 2. Phạm vi áp dụng

- **Loại:** Command.
- **Owner:** `DOM-IV`.
- **Journey / UC:** `BJ-13` / `UC-13-01`.

## 3. Đầu vào nghiệp vụ

- stable `source_component_key` + current source revision/evidence;
- signed source amount + currency và tax/FX treatment khi có;
- route=`ADJUSTMENT`;
- authoritative target scope;
- 1..N `ValuationExposure` allocations;
- allocation method/policy và metric snapshots;
- original period + posting period cho từng allocation;
- `value_adjustment_basis_hash`, `allocation_hash`;
- command/idempotency identity.

## 4. Điều kiện trước

- Actor có quyền tài chính phù hợp.
- Component đã **phát sinh/được xác lập**, không phải forecast hoặc estimate.
- Source revision current; economic component chưa được ghi trùng.
- Target scope/exposure/metric/period mapping current và target đã có initial value.
- Tổng allocation khớp signed source amount sau normalization/rounding.
- Posting period hợp lệ theo policy.

## 5. Quy tắc nghiệp vụ

1. Server dựng lại adjustment preview từ authoritative source/current policy.
2. Ghi `ValueAdjustmentSource` một lần theo stable economic identity.
3. Ghi toàn bộ `ValueAdjustmentAllocation`/exposure linkage.
4. Theo posting period, tạo 1..N `ValuationAdjustmentBatch` + line + `InventoryValueMovement` có dấu.
5. Đánh dấu exact `Product + posting period` dirty cho BJ14.
6. Không quantity movement và không tự publish Official Cost.
7. Component đến sau có thể là vận chuyển, bảo hiểm, thuế/phí không thu hồi, chênh giá, discount/rebate/credit note hoặc commercial true-up hợp lệ.

## 6. Điều kiện bắt buộc

- Forecast/projected commercial benefit **không** được ghi real value ledger.
- Lỗi người dùng đã nhập sai fact ở BJ03 **không** dùng BC này để che sửa sai; route BJ11/correction.
- Source/policy xác định target; user không tùy ý bỏ target khỏi fixed scope.
- Source revision đổi sau preview làm command stale; không partial commit.

## 7. Ảnh hưởng trạng thái

Tạo adjustment provenance + allocations + value movements; exact Product/posting-period scopes chuyển sang trạng thái cần BJ14 tính lại.

## 8. Tính nguyên tử và kết quả cuối

Source component record, allocations, batches, lines, value movements, dirty causes và outbox facts cùng commit hoặc rollback. Nếu finality chưa rõ, làm rõ cùng command identity.

## 9. Kết quả và semantics lỗi

Giữ compatibility với mã lỗi triển khai hiện hành nhưng semantic canonical là **value adjustment**:
`LATE_COST_SOURCE_REQUIRED`, `LATE_COST_SOURCE_STALE`, `LATE_COST_ALREADY_RECORDED`, `LATE_COST_ROUTE_DIRECT`, `LATE_COST_TARGET_SCOPE_INVALID`, `LATE_COST_TARGET_NOT_INITIAL_VALUED`, `LATE_COST_ALLOCATION_METHOD_INVALID`, `LATE_COST_BASIS_STALE`, `LATE_COST_ALLOCATION_MISMATCH`, `LATE_COST_EXPOSURE_STALE`, `POSTING_PERIOD_NOT_OPEN`.

> Các tên lỗi `LATE_COST_*` là compatibility name từ baseline cũ; Technical Contract có thể version hóa tên mới mà không đổi business meaning của BC này.

## 10. Domain và UC sử dụng

- **Domain / Entity:** `ENT-IV-02`, `ENT-IV-05…08`; đọc `ENT-IV-01` và accounting-period facts.
- **UC:** `UC-13-01`.
- **API/Event trace:** `API-C-23`, `EVT-IV-05`.
- **Decision:** `T7-DR-058`, `157…163`, `191…193`.
