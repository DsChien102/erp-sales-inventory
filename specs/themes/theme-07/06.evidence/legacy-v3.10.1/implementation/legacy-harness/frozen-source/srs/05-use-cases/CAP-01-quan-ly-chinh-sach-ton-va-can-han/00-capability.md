# CAP-01 — Quản lý chính sách tồn và cận hạn

> **Loại artifact:** Supporting capability; không phải Business Journey  
> **Migration:** Theme 7 `4.0.0/BJ-16` → `4.1.0/CAP-01`  
> **Owner:** Inventory Policy / Product Configuration  
> **Phạm vi:** Phase 1 — kho mặc định; versioned/effective-dated policy
> **Quyết định nghiệp vụ:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-018`, `T7-DR-096`, `T7-DR-096#REQ-01`, `T7-DR-096#REQ-02`

# 1. Mục tiêu

Quản lý ngưỡng tồn thấp, mức tồn mục tiêu và chính sách cận hạn có version, scope và fallback rõ ràng để BJ-01, BJ-09 và eligibility rules dùng chung một căn cứ.

# 2. Capability operations

| Operation | Kết quả |
|---|---|
| CAP-01-OP-01 — Cấu hình ngưỡng tồn sản phẩm | Low-stock policy version hợp lệ hoặc bị từ chối |
| CAP-01-OP-02 — Cấu hình cận hạn mặc định | Tenant near-expiry policy version |
| CAP-01-OP-03 — Ghi đè cận hạn theo sản phẩm | Product override hoặc khôi phục tenant fallback |

# 3. Hợp đồng và bất biến

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

# 4. Consumers và boundary

- BJ-01 dùng threshold/target/near-expiry policy để tính chỉ báo.
- BJ-09 và các hợp đồng issue dùng `BLOCK_SALE`/eligibility; CAP-01 không tự đổi trạng thái hoặc issue.
- Theme 10 — Mua hàng sở hữu purchase proposal/PO; CAP-01 không tạo hành động mua.

# 5. Operation contracts chi tiết

- [CAP-01-OP-01-cau](CAP-01-OP-01-cau-hinh-nguong-ton-san-pham.md)
- [CAP-01-OP-02-cau](CAP-01-OP-02-cau-hinh-can-han-mac-dinh.md)
- [CAP-01-OP-03-ghi](CAP-01-OP-03-ghi-de-can-han-theo-san-pham.md)
