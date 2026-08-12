---
id: FE-SCR-060
type: fe-slice
theme: theme-07
title: "Chỉ báo tồn kho"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-060 — Chỉ báo tồn kho

## 1. Mục tiêu

Hiện thực bề mặt `SCR-060` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-060`
- `UC-01-04`
- `UC-01-05`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-060`
- `DS-PROFILE`
- `UC-01-04`
- `UC-01-05`

## 5. States và Actions

- `READY`
- `LOADING`
- `EMPTY`
- `STALE`
- `PERMISSION_DENIED`
- `OUT_OF_STOCK`
- `LOW_STOCK`
- `NORMAL`
- `NEAR_EXPIRY_WARN`
- `NEAR_EXPIRY_BLOCKED`

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-060` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-060`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
