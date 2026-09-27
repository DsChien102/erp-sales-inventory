---
id: FE-SCR-040
type: fe-slice
theme: theme-07
title: "Xác nhận tiêu hủy"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-040 — Xác nhận tiêu hủy

## 1. Mục tiêu

Hiện thực bề mặt `SCR-040` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-040`
- `UC-10-01`
- `UC-10-02`
- `UC-10-03`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-040`
- `DS-PROFILE`
- `UC-10-01`
- `UC-10-02`
- `UC-10-03`

## 5. States và Actions

- `READY`
- `PRICE_BASIS_REQUIRED`
- `PENDING_APPROVAL`
- `APPROVAL_REVIEW`
- `APPROVED_PENDING_DISPOSAL`
- `COMPLETION`
- `COMPLETION_QTY_BLOCKED`
- `PERMISSION_DENIED`
- `VALIDATION_ERROR`
- `SELF_APPROVAL_NOT_ALLOWED`

- `ACT-08-DISPOSE` — Xác nhận tiêu hủy
- `ACT-COMMON-SAVE-DRAFT` — Tự lưu bản nháp
- `ACT-COMMON-SUBMIT` — Gửi xử lý
- `ACT-COMMON-DECIDE` — Quyết định phê duyệt

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-040` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-040`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
