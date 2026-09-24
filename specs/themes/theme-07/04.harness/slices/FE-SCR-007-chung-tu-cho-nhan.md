---
id: FE-SCR-007
type: fe-slice
theme: theme-07
title: "Chứng từ chờ nhận"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-007 — Chứng từ chờ nhận

## 1. Mục tiêu

Hiện thực bề mặt `SCR-007` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-007`
- `UC-02-01`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-007`
- `DS-PROFILE`
- `UC-02-01`

## 5. States và Actions

- `READY`
- `LOADING`
- `EMPTY`
- `FILTER_EMPTY`
- `PERMISSION_DENIED`
- `PARTIAL_RECEIPT`
- `SOURCE_VERSION_STALE`

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-007` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-007`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
