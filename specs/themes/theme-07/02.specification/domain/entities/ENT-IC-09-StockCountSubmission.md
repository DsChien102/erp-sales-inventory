---
id: ENT-IC-09
type: business-entity
theme: theme-07
title: StockCountSubmission
owner: BA/SA
status: FROZEN
source_baseline: v3.10.1
---
# ENT-IC-09 — StockCountSubmission

## 1. Ý nghĩa nghiệp vụ

Immutable FIRST/RECOUNT evidence round

## 2. Domain sở hữu

`DOM-IC`.

## 3. Identity

unique session + round_no; payload hash

## 4. Thuộc tính nghiệp vụ chính

| Trường | Kiểu | Bắt buộc | Ghi chú |
|---|---|---|---|
| `submission_id` | UUID | Có | PK |
| `tenant_id` | UUID | Có | — |
| `session_id` | UUID | Có | FK StockCountSession |
| `round_no` | INTEGER | Có | Monotonic trong session; unique `(session_id, round_no)` |
| `round_type` | VARCHAR(12) | Có | `FIRST`, `RECOUNT` |
| `predecessor_submission_id` | UUID | Không | Recount lineage |
| `actor_id` | UUID | Có | Counter thực tế |
| `assignment_version` | BIGINT | Có | Actor assignment rechecked |
| `submitted_at` | TIMESTAMPTZ | Có | Server time |
| `line_observations` | JSONB | Có | PhysicalCountKey + base quantity + unexpected identity facts; immutable |
| `payload_hash` | CHAR(64) | Có | Canonical observations hash |
| `command_receipt_id` | UUID | Có | Idempotency/finality lineage |
| `created_at` | TIMESTAMPTZ | Có | Immutable evidence time |

## 5. Quan hệ

unique session + round_no; payload hash

## 6. Lifecycle / trạng thái

Không có lifecycle riêng được tách thêm ngoài các quy tắc nguồn ở mục 7.

## 7. Quy tắc và Điều kiện bắt buộc

Immutable evidence cho từng vòng FIRST/RECOUNT.

Submission không update/delete theo workflow. Request recount tạo submission mới; StockCountLine chỉ chiếu latest evidence.

## 8. Behavioral Contract / Use Case liên quan

- `UC-08-02`
