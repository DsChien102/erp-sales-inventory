---
id: ENT-IV-04
type: business-entity
theme: theme-07
title: OfficialCostVersion
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-04 — OfficialCostVersion

## 1. Ý nghĩa nghiệp vụ

Đơn giá chính thức có hiệu lực

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

unique tenant + product + effective interval

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `official_cost_version_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | Effective scope |
| `product_id` | `UUID` | FK → `Product` | Bắt buộc | — | Effective scope |
| `unit_cost` | `DECIMAL(20,6)` | — | Bắt buộc | — | **VND / base UOM** của Product; không âm |
| `base_uom_id` | `UUID` | FK → `ProductUnit` | Bắt buộc | — | Base UOM authoritative tại version này |
| `base_uom_version` | `VARCHAR(80)` | — | Bắt buộc | — | Snapshot/version để audit normalization |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `source_type` | `VARCHAR(30)` | — | Bắt buộc | — | Cost run hoặc receipt valuation |
| `source_run_id` | `UUID` | FK → `CostCalculationRun` | Nullable | `NULL` | Theo source type |
| `source_receipt_valuation_id` | `UUID` | FK → `ReceiptValuation` | Nullable | `NULL` | Theo source type |
| `selected_method` | `VARCHAR(30)` | — | Nullable | `NULL` | Moving hoặc periodic khi từ cost run |
| `effective_from` | `TIMESTAMPTZ` | — | Bắt buộc | — | — |
| `effective_to` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Exclusive end |
| `published_by` | `UUID` | FK → `User` | Bắt buộc | — | — |
| `published_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | — |
| `predecessor_id` | `UUID` | FK → `OfficialCostVersion` | Nullable | `NULL` | Version trước |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `product_id`: FK → `Product`.
- `base_uom_id`: FK → `ProductUnit`.
- `source_run_id`: FK → `CostCalculationRun`.
- `source_receipt_valuation_id`: FK → `ReceiptValuation`.
- `published_by`: FK → `User`.
- `predecessor_id`: FK → `OfficialCostVersion`.
- `created_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Đúng một source FK phù hợp `source_type`; effective interval không overlap cho cùng tenant + product. Cost-run publication không backdate `effective_from` trước publication commit; giao dịch đã xảy ra giữ cost version thực tế và được reconcile bằng adjustment. Initial receipt bootstrap dùng compare-and-create nguyên tử theo `tenant_id + product_id`: commit đầu tiên tạo version, concurrent confirmation sau không overwrite và trả `ALREADY_INITIALIZED`. `effective_from` của initial version bằng server commit time của confirmation thắng.

## 8. Behavioral Contract / Use Case liên quan

- `BC-XD-02`
- `BC-XD-03`
