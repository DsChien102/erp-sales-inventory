---
id: FE-SCR-038
type: fe-slice
theme: theme-07
title: "Chuyển trạng thái"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-038 — Chuyển trạng thái

## 1. Mục tiêu

Hiện thực bề mặt `SCR-038` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-038`
- `UC-07-02`
- `UC-07-03`
- `UC-09-01`
- `UC-09-02`
- `UC-09-04`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-038`
- `DS-PROFILE`
- `UC-07-02`
- `UC-07-03`
- `UC-09-01`
- `UC-09-02`
- `UC-09-04`

## 5. States và Actions

- `READY`
- `VALIDATION_ERROR`
- `PENDING_APPROVAL`
- `APPROVAL_REVIEW`
- `LOCKED`
- `SELF_APPROVAL_NOT_ALLOWED`
- `PERMISSION_DENIED`
- `STATE_CHANGE_BASIS_STALE`

- `ACT-08-STATE` — Hệ thống ghi chuyển trạng thái
- `ACT-COMMON-SAVE-DRAFT` — Tự lưu bản nháp
- `ACT-COMMON-SUBMIT` — Gửi xử lý
- `ACT-COMMON-DECIDE` — Quyết định phê duyệt

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-038` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-038`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
