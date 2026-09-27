---
id: FE-SCR-049
type: fe-slice
theme: theme-07
title: "Chi tiết nghiệp vụ kho"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-049 — Chi tiết nghiệp vụ kho

## 1. Mục tiêu

Hiện thực bề mặt `SCR-049` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-049`
- `UC-11-01`
- `UC-11-03`
- `UC-11-05`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-049`
- `DS-PROFILE`
- `UC-11-01`
- `UC-11-03`
- `UC-11-05`

## 5. States và Actions

- `READY`
- `LOADING`
- `PERMISSION_DENIED`
- `UNKNOWN`
- `CANCELABLE`
- `CORRECTABLE`
- `BLOCKED_PHYSICAL_HANDOVER`
- `TERMINAL`

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-049` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-049`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
