# T2-BJ-BASE-PRICE-PUBLICATION — Công bố giá bán cơ sở

> **Loại:** New target requirement; không phải một trong 25 BJ migration source  
> **Owner:** Theme 2 — Sản phẩm  
> **Trạng thái:** Proposed handoff destination cần tích hợp hoặc đối chiếu Journey hiện có của Theme 2

# 1. Mục tiêu

Rà soát và phê duyệt floor/list-price draft, chọn effective time và tạo `BaseSellingPriceVersion` đang hiệu lực mà không sửa pricing basis hoặc cost sources.

# 2. Invariants

- Chỉ publication Journey có quyền thay active base price.
- Cost event, pricing-basis version hoặc price draft không tự publish.
- Publication lưu draft version, approver, effective time và superseded price version.
- Promotion/contextual/transaction price nằm ngoài Journey này.
