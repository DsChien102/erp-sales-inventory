---
id: ENT-IV-07
type: business-entity
theme: theme-07
title: LateLandedCost
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IV-07 — LateLandedCost

## 1. Ý nghĩa nghiệp vụ

Header economic late-cost component với stable source key, current revision, basis/scope hashes và multi-period batch linkage

## 2. Domain sở hữu

`DOM-IV`.

## 3. Identity

unique tenant + source_component_key

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `late_cost_id` | `UUID` | PK | Bắt buộc | Sinh UUID | Immutable record của **một economic source component** |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `source_component_key` | `VARCHAR(180)` | UK thành phần | Bắt buộc | — | Stable economic identity; **không chứa source revision** |
| `source_component_type` | `VARCHAR(40)` | — | Bắt buộc | — | Policy/source normalized type |
| `source_revision` | `BIGINT/VARCHAR` | — | Bắt buộc | — | Current revision used at commit; provenance/freshness only |
| `source_identity` | `JSONB` | — | Bắt buộc | — | Document/line/source-system identity |
| `source_evidence_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds current source evidence snapshot |
| `accounting_route` | `VARCHAR(12)` | — | Bắt buộc | — | `LATE` for ENT-IV-07; same component cannot also be consumed as DIRECT |
| `source_amount` | `DECIMAL(20,6)` | — | Bắt buộc | — | Signed source amount |
| `source_currency` | `CHAR(3)` | — | Bắt buộc | — | — |
| `normalized_amount_vnd` | `DECIMAL(20,6)` | — | Bắt buộc | — | Signed authoritative value after tax/FX normalization |
| `tax_provenance` | `JSONB` | — | Bắt buộc | — | Treatment/version including deductible/non-deductible VAT |
| `fx_provenance` | `JSONB` | — | Nullable | `NULL` | Source/version/rate when needed |
| `allocation_method_id` | `VARCHAR(80)` | — | Bắt buộc | — | Chosen from authoritative allowed set |
| `allocation_policy_version` | `VARCHAR(80)` | — | Bắt buộc | — | — |
| `target_scope_key` | `VARCHAR(180)` | — | Bắt buộc | — | Authoritative source/policy scope identity |
| `target_scope_version` | `VARCHAR(80)` | — | Bắt buộc | — | — |
| `target_scope_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds target membership/selection |
| `late_cost_basis_hash` | `CHAR(64)` | — | Bắt buộc | — | Source+tax+FX+policy+scope+exposure+metric+period basis hash |
| `allocation_hash` | `CHAR(64)` | — | Bắt buộc | — | Binds exact allocation result |
| `adjustment_batch_ids` | `JSONB` | — | Bắt buộc khi completed | `[]` | 1..N batch IDs grouped by posting period |
| `status` | `VARCHAR(30)` | — | Bắt buộc | `DRAFT` | `DRAFT`, `COMPLETED`; command UNKNOWN is not fake commit state |
| `recorded_by` | `UUID` | FK → `User` | Nullable | `NULL` | Required when completed |
| `recorded_at` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Required when completed |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `recorded_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Unique `(tenant_id, source_component_key)`. Source revision is **not** part of business uniqueness. A later revision of the same committed component is correction/reconciliation input, not a second late cost. `normalized_amount_vnd` equals the sum of immutable allocations.
### ValuationExposure — derived immutable preview/commit snapshot
`ValuationExposure` is not a standalone user object. It identifies the exact initial-valued economic exposure targeted by late cost and contains `valuation_exposure_key`, exposure version/hash, receipt item/technical scope, transaction/base UOM normalization, cumulative initial-valued quantity/value, ReceiptValuation references, receipt business date, original period and posting-period mapping.

## 7. Quy tắc và Điều kiện bắt buộc

Unique `(tenant_id, source_component_key)`. Source revision is **not** part of business uniqueness. A later revision of the same committed component is correction/reconciliation input, not a second late cost. `normalized_amount_vnd` equals the sum of immutable allocations.
### ValuationExposure — derived immutable preview/commit snapshot
`ValuationExposure` is not a standalone user object. It identifies the exact initial-valued economic exposure targeted by late cost and contains `valuation_exposure_key`, exposure version/hash, receipt item/technical scope, transaction/base UOM normalization, cumulative initial-valued quantity/value, ReceiptValuation references, receipt business date, original period and posting-period mapping.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IV-06`
