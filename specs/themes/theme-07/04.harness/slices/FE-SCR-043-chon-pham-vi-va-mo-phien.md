---
id: FE-SCR-043
type: fe-slice
theme: theme-07
title: "Chọn phạm vi và mở phiên"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-043 — Chọn phạm vi và mở phiên

## 1. Mục tiêu

Hiện thực bề mặt `SCR-043` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-043`
- `UC-08-01`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-043`
- `DS-PROFILE`
- `UC-08-01`

## 5. States và Actions

- `READY`
- `VALIDATION_ERROR`
- `CONFLICT`
- `COUNT_SCOPE_HAS_UNRESOLVED_VALUATION`
- `PERMISSION_DENIED`

- `ACT-09-OPEN` — Mở phiên kiểm kê

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-043` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-043`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
