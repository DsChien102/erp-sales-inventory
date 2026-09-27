# T2-BJ-PRICING-BASIS — Chuẩn bị giá bán từ giá vốn tham chiếu định giá

> **Trạng thái:** Outbound handoff tạm thời `4.1.0`  
> **Legacy source:** Theme 7 `4.0.0/BJ-23`; Theme 2 được quyền re-ID  
> **Journey owner:** Theme 2 — Sản phẩm  
> **Providers:** Theme 7 (`OfficialCostVersion`) và Theme 10 — Mua hàng (`ProjectedPurchaseCostVersion`)
> **Ranh giới Quyết định nghiệp vụ Theme 7:** `T7-BASELINE-FREEZE-v4.0.0` + `T7-DR-002`, `T7-DR-098`, `T7-DR-100`, `T7-DR-100#REQ-01`, `T7-DR-100#REQ-02`, `T7-DR-100#REQ-03`

# 1. Mục tiêu và ranh giới

Theme 2 nhận hai cost candidates có provenance, resolve thành một `PricingCostBasisVersion`, áp chính sách lợi nhuận để tạo floor/list-price draft và bàn giao sang Journey công bố giá bán cơ sở. Journey không sửa Official Cost, projected purchase cost hoặc active price.

# 2. Trường hợp sử dụng

| UC | Tên | Kết quả |
|---|---|---|
| T2-UC-PB-01 | Thu thập cost candidates | Official/projected versions hợp lệ hoặc nguồn thiếu/stale được nêu rõ |
| T2-UC-PB-02 | Kiểm tra provenance và eligibility | Candidate set đủ điều kiện hoặc `BLOCKED` |
| T2-UC-PB-03 | Resolve giá vốn tham chiếu | `PricingCostBasisVersion` lưu hai refs, policy, resolved value, actor/effective time |
| T2-UC-PB-04 | Tạo dự thảo giá bán | Floor/list-price draft; active price chưa đổi |

# 3. Pricing Cost Basis Policy — Phase 1

> **Receiver gate:** Heuristic `MAX(OfficialCost, ProjectedPurchaseCost)` và yêu cầu `override reason` thuộc `BJ-AUD-D17`; không phải Quyết định nghiệp vụ Theme 7 trong baseline v4.0.0. Theme 2 phải tiếp nhận và đóng băng policy này trước Chuyển đổi chính thức.

| Tình trạng | Xử lý |
|---|---|
| Hai nguồn hợp lệ | Gợi ý `MAX(OfficialCost, ProjectedPurchaseCost)` |
| Chỉ Official Cost hợp lệ | Dùng Official Cost và lưu source type |
| Chỉ projected cost hợp lệ | Cho phép dùng với nhãn `PROJECTED/NON_ACCOUNTING` |
| Không nguồn hợp lệ | `BLOCKED`; không tạo basis/draft |
| Override | Người có quyền được chọn nguồn khác nhưng phải lưu reason/actor/effective time |

Hai candidate là hai cách nhìn hoàn chỉnh, không cộng hoặc lấy weighted average với nhau. Pricing basis không phải Official Cost/COGS.

# 4. Handoff và finality

- `COMPLETED`: pricing basis và draft được tạo, rồi handoff `T2-BJ-BASE-PRICE-PUBLICATION`.
- `REJECTED`: yêu cầu không hợp lệ, active price giữ nguyên.
- `SUSPENDED/BLOCKED`: thiếu/stale provenance hoặc thiếu quyền; work item còn điều kiện tiếp tục.
- Cost candidate/draft không tự thay active price.
