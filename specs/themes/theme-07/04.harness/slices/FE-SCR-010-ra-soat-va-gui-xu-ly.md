---
id: FE-SCR-010
type: fe-slice
theme: theme-07
title: "Rà soát và gửi xử lý"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-010 — Rà soát và gửi xử lý

## 1. Mục tiêu

Hiện thực bề mặt `SCR-010` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-010`
- `UC-02-01`
- `UC-02-02`
- `UC-02-03`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-010`
- `DS-PROFILE`
- `UC-02-01`
- `UC-02-02`
- `UC-02-03`

## 5. States và Actions

- `READY`
- `VALIDATION_ERROR`
- `APPROVAL_REQUIRED`
- `PERMISSION_DENIED`
- `PENDING_APPROVAL`
- `DRAFT_VALIDATION_FAILED`
- `APPROVAL_PRICE_BASIS_REQUIRED`
- `APPROVER_CONFIGURATION_MISSING`
- `FINANCIAL_MASKED`

- `ACT-02-SUBMIT` — Gửi xử lý

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-010` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-010`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
