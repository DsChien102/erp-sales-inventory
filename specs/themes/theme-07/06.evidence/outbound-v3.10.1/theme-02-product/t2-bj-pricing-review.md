# T2-BJ-PRICING-REVIEW — Rà soát nguồn định giá khi chi phí tham chiếu thay đổi

> **Trạng thái:** Outbound handoff tạm thời `4.1.0`  
> **Legacy source:** Theme 7 `4.0.0/BJ-24`; Theme 2 được quyền re-ID  
> **Journey owner:** Theme 2 — Sản phẩm
> **Ranh giới Quyết định nghiệp vụ Theme 7:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-076`, `T7-DR-098`, `T7-DR-100#REQ-03`, `T7-DR-101`

# 1. Trigger và outcome

Journey bắt đầu khi Theme 2 nhận một trong hai event hợp lệ:

- `OfficialCostPublished` từ Theme 7;
- `ProjectedPurchaseCostPublished` từ Theme 10 — Mua hàng.

Kết thúc khi review batch hoàn tất, hoặc còn item `SUSPENDED/BLOCKED` có owner/lý do. Event chỉ mở/deduplicate review và đánh dấu `REVIEW_REQUIRED`; không tự thay pricing basis hoặc active price.

# 2. Trường hợp sử dụng

| UC | Tên | Kết quả |
|---|---|---|
| T2-UC-PR-01 | Mở/deduplicate review batch | Một event/scope chỉ tạo một batch |
| T2-UC-PR-02 | Phân nhóm theo provenance/current policy | Nhóm có đủ nguồn hoặc item blocked |
| T2-UC-PR-03 | Quyết định item/bulk | `KEEP`, `USE_OFFICIAL`, `USE_PROJECTED`, `RECALCULATE_SCENARIO` hoặc policy resolve |
| T2-UC-PR-04 | Tạo basis/draft kế nhiệm | Reuse logic T2-BJ-PRICING-BASIS; active price chưa đổi |

# 3. Business rules

- Không tự ghi đè pricing basis khi cost source thay đổi.
- Projected scenario cần tính lại được handoff về Theme 10 — Mua hàng; version cũ bất biến.
- Cùng event/version/scope không tạo nhiều review batch hoặc apply decision hai lần.
- Missing provenance không được gộp vào bulk update.
- Basis/draft hợp lệ được handoff sang `T2-BJ-BASE-PRICE-PUBLICATION`.


# 6. UC dùng lại từ Pricing Basis

- [T2-UC-PB-02 — Kiểm tra provenance và eligibility](use-cases/T2-UC-PB-02-kiem-tra-nguon-goc-dinh-gia.md) được dùng lại để xác minh provenance/eligibility trước khi tạo basis hoặc draft kế nhiệm; ownership canonical của UC vẫn thuộc `T2-BJ-PRICING-BASIS`.
