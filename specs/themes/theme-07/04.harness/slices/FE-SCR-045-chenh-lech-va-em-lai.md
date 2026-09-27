---
id: FE-SCR-045
type: fe-slice
theme: theme-07
title: "Chênh lệch và đếm lại"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-045 — Chênh lệch và đếm lại

## 1. Mục tiêu

Hiện thực bề mặt `SCR-045` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-045`
- `UC-08-03`
- `UC-08-05`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-045`
- `DS-PROFILE`
- `UC-08-03`
- `UC-08-05`

## 5. States và Actions

- `RECOUNT_REQUIRED`
- `READY`
- `PRICE_BASIS_REQUIRED`
- `VALIDATION_ERROR`
- `LOCK_LOST`
- `PERMISSION_DENIED`

- `ACT-09-SUBMIT` — Nộp kết quả hoặc đếm lại
- `ACT-09-CANCEL` — Hủy phiên kiểm kê

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-045` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-045`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
