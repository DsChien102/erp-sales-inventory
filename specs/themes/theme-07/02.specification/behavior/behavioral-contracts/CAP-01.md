---
id: CAP-01
type: behavioral-contract
theme: theme-07
title: "Quản lý chính sách tồn và cận hạn"
owner: BA
status: IN_REVIEW
source_baseline: v3.10.1
---
# CAP-01 — Quản lý chính sách tồn và cận hạn

## 1. Ý định

Quản lý ngưỡng tồn thấp, mức tồn mục tiêu và chính sách cận hạn có version, scope và fallback rõ ràng để BJ-01, BJ-09 và eligibility rules dùng chung một căn cứ.

## 2. Phạm vi áp dụng

Supporting capability; không phải Business Journey.

- BJ-01 dùng threshold/target/near-expiry policy để tính chỉ báo.
- BJ-09 và các hợp đồng issue dùng `BLOCK_SALE`/eligibility; CAP-01 không tự đổi trạng thái hoặc issue.
- Theme 10 — Mua hàng sở hữu purchase proposal/PO; CAP-01 không tạo hành động mua.

## 3. Đầu vào nghiệp vụ

Theo từng operation contract CAP-01-OP-01..03.

## 4. Điều kiện trước

Phase 1 — kho mặc định; versioned/effective-dated policy theo source baseline.

## 5. Quy tắc nghiệp vụ

| Operation | Kết quả |
|---|---|
| CAP-01-OP-01 — Cấu hình ngưỡng tồn sản phẩm | Low-stock policy version hợp lệ hoặc bị từ chối |
| CAP-01-OP-02 — Cấu hình cận hạn mặc định | Tenant near-expiry policy version |
| CAP-01-OP-03 — Ghi đè cận hạn theo sản phẩm | Product override hoặc khôi phục tenant fallback |

## 6. Điều kiện bắt buộc

| Điểm kiểm soát | Quy tắc |
|---|---|
| Threshold/target | `target_stock_level ≥ low_stock_threshold ≥ 0` |
| Cận hạn | Số ngày không âm; action chỉ `WARN` hoặc `BLOCK_SALE` |
| Fallback | Product override ưu tiên tenant default hiện hành |
| LOT/NONE | Chỉ tạo kết quả cho hàng có expiry |
| Scope | Phase 1 tự áp kho mặc định nhưng model giữ product + warehouse scope |
| Version | Mỗi thay đổi tạo version/effective time; consumer lưu policy version đã dùng |
| Không alert/proposal | Policy không tạo Alert/Proposal identity hoặc lifecycle |
| Không mutation tồn | Thay policy không tạo movement/value; read model/eligibility được dẫn xuất lại |

## 7. Ảnh hưởng trạng thái

Policy changes không tự tạo inventory movement/value; effects giữ nguyên theo source.

## 9. Kết quả và semantics lỗi

Theo từng operation contract.

## 10. Domain và UC sử dụng

- BJ-01 dùng threshold/target/near-expiry policy để tính chỉ báo.
- BJ-09 và các hợp đồng issue dùng `BLOCK_SALE`/eligibility; CAP-01 không tự đổi trạng thái hoặc issue.
- Theme 10 — Mua hàng sở hữu purchase proposal/PO; CAP-01 không tạo hành động mua.
