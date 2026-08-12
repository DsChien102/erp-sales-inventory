---
id: ENT-IC-10
type: business-entity
theme: theme-07
title: StateTransitionPolicyVersion
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-10 — StateTransitionPolicyVersion

## 1. Ý nghĩa nghiệp vụ

Immutable state-transition policy version

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

tenant + policy code + version; policy hash

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu dữ liệu logic | PK/FK | Bắt buộc/nullable | Mặc định | Ràng buộc/ghi chú |
|---|---|---|---|---|---|
| `state_transition_policy_version_id` | `UUID` | PK | Bắt buộc | Sinh UUID | Immutable version identity |
| `tenant_id` | `UUID` | FK → `Tenant` | Bắt buộc | — | Tenant scope |
| `policy_code` | `VARCHAR(80)` | — | Bắt buộc | — | Stable policy family |
| `version_no` | `BIGINT` | UK thành phần | Bắt buộc | — | Monotonic trong policy_code |
| `effective_from` | `TIMESTAMPTZ` | — | Bắt buộc | — | Không overlap version active cùng policy_code |
| `effective_to` | `TIMESTAMPTZ` | — | Nullable | `NULL` | — |
| `transition_rules` | `JSONB` | — | Bắt buộc | — | Canonical `from→to`, permission, reason/evidence, approval route/level, eligibility effect; không chứa UI copy |
| `policy_hash` | `CHAR(64)` | — | Bắt buộc | — | SHA-256 canonical payload |
| `created_by` | `UUID` | FK → `User` | Bắt buộc | — | Audit |
| `created_at` | `TIMESTAMPTZ` | — | Bắt buộc | `now()` | Append-only |

## 5. Quan hệ

- `Trường`: PK/FK.
- `tenant_id`: FK → `Tenant`.
- `created_by`: FK → `User`.

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Policy version bất biến sau khi effective. Request đã submit luôn bám exact version/hash đã snapshot; thay policy tạo version mới, không rewrite request/approval lịch sử.

## 8. Behavioral Contract / Use Case liên quan

Không có liên kết trực tiếp được ghi nhận trong nguồn v3.10.1.
