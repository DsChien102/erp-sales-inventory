# Final target map và migration matrix

> **Baseline:** Theme 7 package `4.0.0` (`T7-PACKAGE-FREEZE-v4.0.0`)  
> **Target release:** `4.1.0`  
> **Target/owner gates:** `APPROVED`; BJ-09 mới thuộc Inventory Control  
> **Decision baseline:** `T7-BASELINE-FREEZE-v4.0.0` — 102 quyết định / 78 yêu cầu nguyên tử  
> **Internal cut-over:** `COMPLETED` trong package v4.1.0; outbound receiver transfer `DEFERRED_BY_OWNER_DECISION`, D17 chờ Theme 2 adoption

## 1. Target inventory

| Target | Tên/loại | Legacy source | Owner |
|---|---|---|---|
| BJ-01 | Theo dõi tồn, khả dụng và chỉ báo vận hành | BJ-01 + BJ-17 | Inventory Operations / Monitoring |
| BJ-02 | Nhận hàng mua | BJ-02 | Inventory Operations |
| BJ-03 | Xác nhận giá trị ban đầu của hàng nhận | BJ-03 | Inventory Valuation |
| BJ-04 | Quản lý vòng đời giữ hàng | BJ-04 | Inventory Operations |
| BJ-05 | Lấy hàng và bàn giao đơn | BJ-06 + inventory provider UC từ BJ-05 | Inventory Operations |
| BJ-06 | Tiếp nhận và phân loại hàng khách trả | BJ-07 | Inventory Operations |
| BJ-07 | Thực hiện trả hàng cho nhà cung cấp | BJ-08 | Inventory Operations |
| BJ-08 | Kiểm kê và điều chỉnh chênh lệch | BJ-09 | Inventory Control |
| BJ-09 | Quản lý trạng thái hàng | BJ-10 | **Inventory Control** |
| BJ-10 | Tiêu hủy hàng | BJ-11 | Inventory Control |
| BJ-11 | Hủy và sửa sai nghiệp vụ kho | BJ-12 | Inventory Control |
| BJ-12 | Khởi tạo số dư tồn kho đầu kỳ | BJ-13 | Inventory Control / Inventory Valuation |
| BJ-13 | Ghi nhận chi phí mua đến muộn | BJ-14 | Inventory Valuation |
| BJ-14 | Tính và công bố giá vốn | BJ-15 | Inventory Valuation |
| BJ-15 | Tra cứu báo cáo tồn và thẻ kho | BJ-18 | Inventory Reporting / Read layer |
| BJ-16 | Điều tra và đối soát sai lệch | BJ-19 | Inventory Control |
| BJ-17 | Phục hồi nghiệp vụ có kết quả chưa xác định | BJ-20 | Inventory Control + Operation Owner |
| CAP-01 | Supporting capability: chính sách tồn/cận hạn | BJ-16 | Inventory Policy / Product Configuration |
| PROC-01 | Technical procedure: dựng lại projection | BJ-21 | Platform Operations; BJ-16 là caller |
| XREF-01 | Checkout POS | BJ-05 | Theme 5/Sales-POS |
| XREF-02 | Kịch bản chiết khấu mua hàng | BJ-22 | Theme 10 — Mua hàng |
| XREF-03 | Pricing cost basis và price draft | BJ-23 | Theme 2 — Sản phẩm |
| XREF-04 | Pricing review khi cost source đổi | BJ-24 | Theme 2 — Sản phẩm |
| XREF-05 | Ba cách nhìn lợi nhuận | BJ-25 | Reporting/Management Analytics |

## 2. Migration matrix — 25/25 source rows

| Source | Action | Target/handoff |
|---|---|---|
| BJ-01 | `MERGE_TARGET` | BJ-01 |
| BJ-02 | `KEEP` | BJ-02 |
| BJ-03 | `KEEP` | BJ-03 |
| BJ-04 | `KEEP` | BJ-04 |
| BJ-05 | `MOVE` | XREF-01 → T5-BJ-CHECKOUT-POS; atomic issue → BJ-05/UC-05-05 |
| BJ-06 | `KEEP` | BJ-05 |
| BJ-07 | `KEEP` | BJ-06 |
| BJ-08 | `KEEP` | BJ-07 |
| BJ-09 | `KEEP` | BJ-08 |
| BJ-10 | `KEEP` | BJ-09; owner Inventory Control |
| BJ-11 | `KEEP` | BJ-10 |
| BJ-12 | `KEEP` | BJ-11 |
| BJ-13 | `KEEP` | BJ-12 |
| BJ-14 | `KEEP` | BJ-13 |
| BJ-15 | `KEEP` | BJ-14 |
| BJ-16 | `RECLASSIFY` | CAP-01 |
| BJ-17 | `MERGE` | BJ-01 |
| BJ-18 | `KEEP` | BJ-15 |
| BJ-19 | `KEEP` | BJ-16 |
| BJ-20 | `KEEP` | BJ-17 |
| BJ-21 | `RECLASSIFY` | PROC-01 |
| BJ-22 | `MOVE` | XREF-02 → T10-BJ-DISCOUNT-SCENARIO |
| BJ-23 | `MOVE` | XREF-03 → T2-BJ-PRICING-BASIS |
| BJ-24 | `MOVE` | XREF-04 → T2-BJ-PRICING-REVIEW |
| BJ-25 | `MOVE` | XREF-05 → RPT-BJ-PROFIT-VIEWS |

Machine-readable row mapping nằm tại `migration-registry.json`; child-UC/reference rewrite nằm tại `uc-reference-rewrite-registry.json`.


## 3. Decision linkage

Crosswalk D01…D17 nằm tại `decision-crosswalk.json`; trace 24 target artifacts nằm tại `target-decision-trace.json`.
