---
id: BC-IO-09
type: behavioral-contract
theme: theme-07
title: "Return goods to supplier — actual handover"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-09"></a>
# BC-IO-09 — Return goods to supplier — actual handover

## 1. Ý định

Commit **actual physical handover** trên exact current supplier-return allocation/source slices; không sở hữu source authorization hoặc bước đưa hàng vào `RTV_PENDING`.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO + IV
- Journey chính: `BJ-07`

## 3. Đầu vào nghiệp vụ

Current `source_request_id/source_version/source_line_id/source_allocation_id`, exact resolved source slices, Product/UOM/LOT/quantity, warehouse, actor handover assertion; commercial reference nếu source có thì chỉ là optional lineage.

## 4. Điều kiện trước

Source/version current; exact Product/UOM/LOT khớp current allocation; mọi required physical verification hoàn tất; source slices cộng đúng pending quantity và còn tồn tại ở `RTV_PENDING`; permission + warehouse scope hợp lệ; handover assertion có. **Không yêu cầu commercial supplier price và không approval thương mại lần hai.**

## 5. Quy tắc nghiệp vụ

Lock source/version + pending source slices → recheck → append issue/state/value movements dùng official cost → update balances → tạo immutable source-agnostic `HandoverEvidence` → outbox/accounting handoff. `RTV_PENDING` đã được `BC-IO-17` materialize trước đó.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Physical/value giảm đúng lúc actual handover; immutable evidence có actor/time/source/allocation/source-slice lineage; accounting handoff tách khỏi commercial pricing decision.

## 8. Tính nguyên tử và kết quả cuối

Physical/value giảm đúng lúc actual handover; immutable evidence có actor/time/source/allocation/source-slice lineage; accounting handoff tách khỏi commercial pricing decision.

## 9. Kết quả và semantics lỗi

`SOURCE_VERSION_CONFLICT`, `SOURCE_ALLOCATION_MISMATCH`, `SOURCE_SLICE_MISMATCH`, `INSUFFICIENT_RTV_PENDING`, `LOT_MISMATCH`, `HANDOVER_ASSERTION_REQUIRED`, `PERMISSION_DENIED`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/10/11`, `ENT-IV-02/04`.
- Trace: `BJ-07`; `UC-07-04`; `API-C-09`; `EVT-IV-01`.
