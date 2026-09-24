---
id: FE-SCR-032
type: fe-slice
theme: theme-07
title: "Chi tiết hàng trả"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-032 — Chi tiết hàng trả

## 1. Mục tiêu

Hiện thực bề mặt `SCR-032` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-032`
- `UC-06-01`
- `UC-06-02`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-032`
- `DS-PROFILE`
- `UC-06-01`
- `UC-06-02`

## 5. States và Actions

- `READY`
- `VALIDATION_ERROR`
- `APPROVED_EXCEPTION`
- `REJECTED_EXCEPTION`
- `PENDING_APPROVAL`
- `CONFLICT`
- `LOCKED`
- `PERMISSION_DENIED`

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-032` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-032`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
