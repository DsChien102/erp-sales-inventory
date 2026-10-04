---
id: BC-IO-10
type: behavioral-contract
theme: theme-07
title: "Change inventory state"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-io-10"></a>
# BC-IO-10 — Change inventory state

## 1. Ý định

System-owned execution chuyển quantity giữa `SELLABLE/QUARANTINE/DAMAGED/DEMO` theo immutable basis mà không đổi tổng physical/book value. `EXPIRED` chỉ materialize qua system path.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: IO
- Journey chính: `BJ-09`

## 3. Đầu vào nghiệp vụ

Command envelope + immutable `StateChangeBasis` reference qua `state_change_basis_id`, `basis_hash`; basis bind product/LOT, quantity, from/to, exact source slices `{balance_id,balance_version,valuation_state,quantity}`, transition-policy version/hash, reason/evidence, business date/expiry facts và reservation impact preview.

## 4. Điều kiện trước

Basis/hash current; exact policy version/hash hợp lệ; transition whitelist/permission đạt; `0 < quantity <= exact source quantity`; mọi source balance/version/valuation slice current; không lock/conflict; expiry hard rule đạt; nếu policy cần approval thì current `ApprovalCase(STATE_CHANGE)` phải APPROVED cho đúng basis hash. User path không được chọn `EXPIRED`, `VALUATION_PENDING`, `RETURN_PENDING`, `RTV_PENDING`. Ambiguous source composition bị block.

## 5. Quy tắc nghiệp vụ

Lock exact source balances + affected reservation bucket/group theo deterministic order → recheck basis/policy/approval → append `STATE_TRANSFER` per source slice với `valuation_state_snapshot` giữ nguyên → decrement source stock_state và increment destination stock_state trong **cùng valuation_state** → nếu eligibility giảm, reconcile reservation capacity atomically; giữ consumed history, không rewrite active PickAllocation và phát `allocation_review_required` khi cần → outbox cùng transaction.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

Tổng physical quantity không đổi; **không tạo InventoryValueMovement và authoritative book value không đổi**; availability/reservation impact + allocation-review signal được ghi rõ; event có basis/policy/source-slice lineage.

## 8. Tính nguyên tử và kết quả cuối

Tổng physical quantity không đổi; **không tạo InventoryValueMovement và authoritative book value không đổi**; availability/reservation impact + allocation-review signal được ghi rõ; event có basis/policy/source-slice lineage.

## 9. Kết quả và semantics lỗi

`STATE_TRANSITION_NOT_ALLOWED`, `STATE_SOURCE_SLICE_AMBIGUOUS`, `STATE_CHANGE_BASIS_STALE`, `STATE_POLICY_VERSION_STALE`, `INSUFFICIENT_IN_STATE`, `EXPIRED_SYSTEM_DERIVED`, `LOCK_CONFLICT`, `APPROVAL_BASIS_MISMATCH`.

## 10. Domain và UC sử dụng

- Entity/Read model: `ENT-IO-01/02/03/04/05/08/09/10`, `ENT-IC-02/10/11`; read `ENT-IO-06`.
- Trace: `BJ-09`; `T7-DR-178…184`; `API-C-10`; `EVT-IO-08`.
