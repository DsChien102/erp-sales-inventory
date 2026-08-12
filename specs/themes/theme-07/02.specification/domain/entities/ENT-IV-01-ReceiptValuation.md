---
id: ENT-IV-01
type: business-entity
theme: theme-07
title: ReceiptValuation
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-01 — ReceiptValuation

## 1. Ý nghĩa nghiệp vụ

Giá trực tiếp và bằng chứng của receipt quantity

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

FK receipt operation line; source price version

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `receipt_valuation_id` | `UUID` | PK | Bắt buộc | Sinh UUID | — |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `receipt_operation_line_id` | `UUID` | FK → `InventoryOperationLine` | Bắt buộc | — | Receipt technical line đã chuyển quyền sở hữu |
| `receipt_item_ref` | `VARCHAR(128)` | Tham chiếu ngoài/receipt aggregate | Bắt buộc | — | Commercial receipt item/source line làm owner của valuation basis; nhiều technical line có thể chung ref |
| `valuation_basis_key` | `VARCHAR(180)` | — | Bắt buộc | — | Stable identity của DirectCostBasis; không đồng nhất với Product+UOM presentation group |
| `basis_version` | `BIGINT` | — | Bắt buộc | — | Version của complete basis |
| `basis_hash` | `CHAR(64)` | — | Bắt buộc | — | Hash toàn component provenance + allocation/tax/FX inputs có ảnh hưởng authoritative |
| `direct_cost_basis_snapshot` | `JSONB` | — | Bắt buộc | — | Immutable complete DirectCostBasis đã commit; gồm component source identity/version, tax/FX/allocation provenance |
| `valuation_scope_key` | `VARCHAR(180)` | — | Nullable | `NULL` | Bắt buộc với `DIRECT_PRICE`; định danh ổn định receipt line + LOT/non-LOT + physical state của lượng đang chờ giá |
| `scope_version_before` | `BIGINT` | — | Nullable | `NULL` | Bắt buộc với `DIRECT_PRICE`; dùng CAS chống xác nhận trên scope stale |
| `confirmed_quantity` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Transaction-UOM quantity xác nhận lần này; `> 0`, không vượt pending scope |
| `transaction_uom_id` | `UUID` | FK → `ProductUnit` | Bắt buộc | — | UOM của commercial receipt item |
| `transaction_uom_snapshot` | `JSONB` | — | Bắt buộc | — | Label/precision/step snapshot dùng ở source transaction |
| `conversion_to_base` | `DECIMAL(24,12)` | — | Bắt buộc | — | Hệ số transaction UOM → base UOM đã snapshot |
| `conversion_version` | `VARCHAR(80)` | — | Bắt buộc | — | Version quy đổi dùng khi nhận |
| `confirmed_base_quantity` | `DECIMAL(20,6)` | — | Bắt buộc | — | Normalized quantity dùng valuation/cost downstream |
| `confirmation_sequence` | `INTEGER` | — | Nullable | `NULL` | Monotonic trong `valuation_scope_key`; cho phép nhiều lần xác nhận từng phần |
| `valuation_kind` | `VARCHAR(30)` | — | Bắt buộc | `DIRECT_PRICE` | Phase 1 current model: `DIRECT_PRICE`; late cost dùng `ENT-IV-07/08` |
| `price_source_type` | `VARCHAR(40)` | — | Bắt buộc | — | Primary commercial source để tra cứu; **không đại diện toàn provenance** của DirectCostBasis |
| `price_source_id` | `VARCHAR(128)` | Tham chiếu ngoài | Bắt buộc | — | — |
| `price_source_version` | `BIGINT` | — | Bắt buộc | — | — |
| `unit_purchase_price` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Direct price trước cost component |
| `deductible_vat_amount` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | — |
| `non_deductible_vat_amount` | `DECIMAL(20,6)` | — | Bắt buộc | `0` | Cấu phần vào direct cost theo policy |
| `confirmed_direct_unit_cost` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Backward-compatible alias: direct unit cost theo transaction UOM |
| `confirmed_direct_unit_cost_transaction` | `DECIMAL(20,6)` | — | Bắt buộc | — | VND / transaction UOM |
| `normalized_direct_unit_cost_base` | `DECIMAL(20,6)` | — | Bắt buộc | — | VND / base UOM; dùng consequence/initial Official Cost |
| `confirmed_value_amount` | `DECIMAL(20,6)` | — | Bắt buộc | — | Authoritative allocated value của lần confirmation; không phải client unit-cost×qty |
| `cumulative_scope_value_after` | `DECIMAL(20,6)` | — | Bắt buộc | — | Cumulative confirmed allocated value sau lần này, phục vụ deterministic partial rounding |
| `currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `evidence_hash` | `CHAR(64)` | — | Bắt buộc | — | Bind complete DirectCostBasis + component provenance/evidence, không chỉ filename/source document |
| `confirmed_by` | `UUID` | FK → `User` | Nullable | `NULL` | Bắt buộc khi confirmed |
| `confirmed_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Bắt buộc khi confirmed |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `version` | `BIGINT` | — | Bắt buộc | `1` | Concurrency/lifecycle |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `receipt_operation_line_id`: FK → `InventoryOperationLine`.
- `receipt_item_ref`: Tham chiếu ngoài/receipt aggregate.
- `transaction_uom_id`: FK → `ProductUnit`.
- `price_source_id`: Tham chiếu ngoài.
- `confirmed_by`: FK → `User`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Một receipt technical line có thể có nhiều direct-price confirmation khi xác nhận từng phần. `valuation_basis_key` bám commercial `receipt_item_ref`, còn `valuation_scope_key` bám technical line + LOT/non-LOT + physical state; nhiều scope có thể chia sẻ một basis. Mỗi confirmation giữ `basis_hash/version`, `scope_version_before`, transaction/base quantity và cumulative allocated value. Partial dùng cumulative rounding nên tổng authoritative cuối cùng không phụ thuộc cách user chia lần xác nhận. Chống trùng dùng command/idempotency identity và CAS của selected basis/scope, không dùng unique một-record-per-line. Late landed cost không dùng `ReceiptValuation`; component đến sau initial confirmation dùng `ENT-IV-07/08`/valuation adjustment và không rewrite record cũ.

## 7. Quy tắc và Điều kiện bắt buộc

Một receipt technical line có thể có nhiều direct-price confirmation khi xác nhận từng phần. `valuation_basis_key` bám commercial `receipt_item_ref`, còn `valuation_scope_key` bám technical line + LOT/non-LOT + physical state; nhiều scope có thể chia sẻ một basis. Mỗi confirmation giữ `basis_hash/version`, `scope_version_before`, transaction/base quantity và cumulative allocated value. Partial dùng cumulative rounding nên tổng authoritative cuối cùng không phụ thuộc cách user chia lần xác nhận. Chống trùng dùng command/idempotency identity và CAS của selected basis/scope, không dùng unique một-record-per-line. Late landed cost không dùng `ReceiptValuation`; component đến sau initial confirmation dùng `ENT-IV-07/08`/valuation adjustment và không rewrite record cũ.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IV-01`
- `BC-IV-05`
- `BC-IV-06`
- `BC-IV-04`
