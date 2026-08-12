---
id: BC-XD-05
type: behavioral-contract
theme: theme-07
title: "Configure inventory product policy"
owner: BA
status: FROZEN
source_baseline: v3.10.1
---
<a id="bc-xd-05"></a>
# BC-XD-05 — Configure inventory product policy

## 1. Ý định

Lưu chính sách tồn thấp và cận hạn theo sản phẩm, có fallback tenant default.

## 2. Phạm vi áp dụng

- Loại: Command
- Owner nguồn: Product configuration
- Journey chính: `CAP-01`

## 3. Đầu vào nghiệp vụ

Product, warehouse mặc định, threshold, target, optional near-expiry days/action override, expected config version.

## 4. Điều kiện trước

Product-config permission; `target ≥ threshold ≥ 0`; days ≥ 0; action thuộc `WARN/BLOCK_SALE`; Phase 1 warehouse must be default.

## 5. Quy tắc nghiệp vụ

Create/update versioned config; invalidate low-stock/expiry eligibility cache; không tạo proposal/PO/alert entity/inventory movement.

## 6. Điều kiện bắt buộc

Các constraint bắt buộc là các guard và rule nguồn ở mục 4–5; migration không bổ sung invariant mới.

## 7. Ảnh hưởng trạng thái

New config version and effective time.

## 9. Kết quả và semantics lỗi

`REPLENISHMENT_CONFIG_INVALID`, `NEAR_EXPIRY_POLICY_INVALID`, `WAREHOUSE_ROUTING_NOT_AVAILABLE`, `VERSION_CONFLICT`.

## 10. Domain và UC sử dụng

- Entity/Read model: External product/warehouse config ref; read by `PRJ-08`.
- Trace: `CAP-01`; `CAP-01-OP-01…03`; `SG-12`; `API-X-04`; `EVT-XD-03`.
