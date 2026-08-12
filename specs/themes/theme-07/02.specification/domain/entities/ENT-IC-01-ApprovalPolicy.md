---
id: ENT-IC-01
type: business-entity
theme: theme-07
title: ApprovalPolicy
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-01 — ApprovalPolicy

## 1. Ý nghĩa nghiệp vụ

Policy version theo operation type/risk

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

natural scope + effective version

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `approval_policy_version_id` | `UUID` | PK | Bắt buộc | Sinh UUID | ID của một policy version bất biến sau khi active |
| `policy_id` | `UUID` | UK thành phần | Bắt buộc | Sinh khi tạo policy | Stable ID qua các version |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | — |
| `version_no` | `BIGINT` | UK thành phần | Bắt buộc | `1` | Tăng đơn điệu theo policy |
| `operation_type` | `VARCHAR(40)` | — | Bắt buộc | — | Selector loại operation |
| `reason_selectors` | `JSONB` | — | Bắt buộc | `{}` | Điều kiện route, không được vô hiệu duyệt nhập nhanh |
| `risk_selectors` | `JSONB` | — | Bắt buộc | `{}` | Điều kiện risk/threshold nếu loại operation cho phép |
| `threshold_amount` | `DECIMAL(20,6)` | — | Nullable | `NULL` | Ngưỡng route; không phải ngưỡng bỏ duyệt nhập nhanh |
| `threshold_currency` | `CHAR(3)` | — | Nullable | `NULL` | Đi cùng threshold amount |
| `required_approval_level` | `INTEGER` | — | Bắt buộc | — | Cấp cao nhất cần đáp ứng |
| `eligible_role_conditions` | `JSONB` | — | Bắt buộc | — | Role/permission/scope hợp lệ |
| `effective_from` | `TIMESTAMPTZ` | — | Bắt buộc | — | Với source cost run Phase 1: không được trước `published_at`; future-effective chỉ khi publication xảy ra trước mốc |
| `effective_to` | `TIMESTAMPTZ` | — | Nullable | `NULL` | Không overlap cùng scope |
| `status` | `VARCHAR(20)` | — | Bắt buộc | `DRAFT` | `DRAFT`, `ACTIVE`, `RETIRED` |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |
| `updated_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `updated_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Audit |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `created_by`: FK → `User`.
- `updated_by`: FK → `User`.

## 6. Lifecycle / trạng thái

**Bất biến nhập hàng nhanh:** policy chỉ xác định tuyến/cấp/người duyệt. Nó không có cờ “có cần duyệt hay không”. Với operation nhập hàng nhanh, submit hợp lệ luôn tạo `ApprovalCase` và chuyển operation sang `PENDING_APPROVAL`; thiếu policy active hoặc thiếu approver đủ cấp thì giữ `DRAFT` và trả structured rejection.

## 7. Quy tắc và Điều kiện bắt buộc

**Bất biến nhập hàng nhanh:** policy chỉ xác định tuyến/cấp/người duyệt. Nó không có cờ “có cần duyệt hay không”. Với operation nhập hàng nhanh, submit hợp lệ luôn tạo `ApprovalCase` và chuyển operation sang `PENDING_APPROVAL`; thiếu policy active hoặc thiếu approver đủ cấp thì giữ `DRAFT` và trả structured rejection.

## 8. Behavioral Contract / Use Case liên quan

- `BC-IC-06`
- `BC-IC-07`
- `BC-IC-09`
