---
id: PRJ-10
type: read-model
theme: theme-07
title: MarginComparisonView
owner: SA
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# PRJ-10 — MarginComparisonView

## 1. Mục đích

Projection/read model được materialize từ định nghĩa `PRJ-10` của baseline v3.10.1.

## 2. Owner

Theme 07; owner kỹ thuật cụ thể được xác định bởi Architecture, không thay đổi business ownership từ source.

## 3. Data shape

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `snapshot_id` | `UUID` | PK logic | Bắt buộc | — | Consistent report snapshot |
| `tenant_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `product_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `sales_line_id` | `VARCHAR(128)` | Tham chiếu ngoài | Nullable | `NULL` | Có khi xem theo giao dịch |
| `accounting_period_id` | `UUID` | Khóa projection | Bắt buộc | — | — |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `revenue_amount` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Dữ liệu miền bán hàng |
| `initial_cogs` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Theme 7 cung cấp |
| `true_up_amount` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Theme 7 cung cấp |
| `reconciled_cogs` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Initial COGS + true-up |
| `pricing_cost_basis` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Miền định giá cung cấp |
| `transaction_margin` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | — |
| `reconciled_margin` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | — |
| `projected_margin` | `DECIMAL(20,6)` | — | Nullable | `NULL` | — |
| `official_cost_version_id` | `UUID` | Tham chiếu logic → `OfficialCostVersion` | Nullable | `NULL` | — |
| `pricing_basis_version_id` | `UUID` | Tham chiếu ngoài | Nullable | `NULL` | — |
| `as_of` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |

`MarginComparisonView` là cross-domain projection. Theme 7 chỉ sở hữu cost/COGS facts, không sở hữu doanh thu hoặc quyết định định giá.

## 4. Nguồn dữ liệu

Xem Entity/ledger references được ghi trực tiếp trong data shape nguồn.

## 5. Projection rules

Các rule derive được giữ nguyên trong ghi chú của data shape nguồn.

## 6. Consistency và freshness

Xem `DOM-COM` và `FND-TECH-01` cho consistency/time semantics của baseline.

## 7. Query shape

Query/filter/paging contract được giữ ở BC/API technical source nếu có.

## 8. Rebuild / backfill

Xem `PROC-01` và BC reconciliation nếu projection tham gia rebuild.

## 9. Failure / degradation

Theo technical/finality contract của baseline v3.10.1.

## 10. Verification

Đối chiếu data shape, source sequence/as-of và các BC/query tiêu thụ projection.
