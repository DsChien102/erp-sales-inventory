---
id: FE-SCR-052
type: fe-slice
theme: theme-07
title: "Hủy hoặc chọn cách sửa"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-052 — Hủy hoặc chọn cách sửa

## 1. Mục tiêu

Hiện thực bề mặt `SCR-052` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-052`
- `UC-11-02`
- `UC-11-03`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-052`
- `DS-PROFILE`
- `UC-11-02`
- `UC-11-03`

## 5. States và Actions

- `CANCEL_UNEXECUTED`
- `CORRECTION_ROUTE`
- `VALIDATION_ERROR`
- `DEPENDENCY_BLOCKED`
- `PERIOD_POLICY_VIOLATION`
- `PERMISSION_DENIED`

- `ACT-10-CANCEL` — Hủy yêu cầu

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-052` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-052`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
