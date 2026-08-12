---
id: INT-01
type: integration
theme: theme-07
title: "Cross-theme outbound integration catalog"
owner: SA
status: IN_REVIEW
source_baseline: v3.10.1
---
# INT-01 — Cross-theme outbound integration catalog

## 1. Mục đích và boundary

Khu vực chuyển giao outbound tạm thời của baseline v3.10.1 được biểu diễn theo Integration template. Migration không thay đổi ownership của Theme ngoài và không nâng các gói tạm thời thành capability canonical của Theme 07.

## 2. Producer / Consumer

Xem catalog nguồn ở mục 5; Theme đích và trạng thái tiếp nhận được giữ nguyên như baseline.

## 3. Ownership

Theme 07 tiếp tục chỉ sở hữu phía provider/handoff được nêu trong nguồn. Các artifact của Theme consumer là reference/evidence, không trở thành ownership Theme 07.

## 4. Interaction flow

Theo từng outbound reference trong baseline v3.10.1. Migration không bổ sung flow mới.

## 5. Published contract

> **Trạng thái:** `TEMPORARY_NON_CANONICAL`  
> **Vị trí:** vẫn nằm trong Theme 7 v4.1.0 theo quyết định của Business Owner.  
> **Quy tắc:** không tính vào 17 BJ, 70 UC, 14 SG hoặc Harness canonical của Theme 7; chưa được xóa/chuyển cho tới quyết định tiếp theo.

| Thư mục | Nguồn v4.0.0 | Theme đích đã khóa | Trạng thái tiếp nhận |
|---|---|---|---|
| `theme-05-sales-pos/` | BJ-05 | Theme 5 — Sales/POS | Chờ receiver adoption |
| `theme-10-purchase/` | BJ-22 | **Theme 10 — Mua hàng** | Chờ receiver adoption |
| `theme-02-product/` | BJ-23, BJ-24 | **Theme 2 — Sản phẩm** | Chờ receiver adoption, gồm policy D17 |
| `reporting-analytics/` | BJ-25 | Reporting/Analytics | Chờ receiver adoption |
| `shared-prototype/contracts/` | SG-16, SG-17 | Nhiều Theme đích | Chờ tách theo receiver |

Theme 7 tiếp tục giữ provider contract cho tồn kho, `OfficialCostVersion`, atomic inventory issue và finality; thư mục này giữ lifecycle nguồn để không mất dấu trong thời gian chờ chuyển.

Raw reference artifacts được giữ tại `07.evidence/outbound-v3.10.1/`; prototype runtime của Theme 7 được giữ riêng tại `03.design/prototype/html/` và không phải nguồn semantic của integration.

## 6. Consistency / transaction semantics

Theo `FND-TECH-01` và từng reference nguồn.

## 7. Idempotency / retry / ordering

Theo `FND-TECH-01` và từng reference nguồn.

## 8. Failure và recovery

Theo finality/recovery contract nguồn.

## 9. Observability

Theo technical contract nguồn.

## 10. Verification

Contract/link/ownership review đối với từng outbound boundary.
