---
id: FE-SCR-031
type: fe-slice
theme: theme-07
title: "Hàng khách trả"
owner: SE
status: DRAFT
source_baseline: v3.10.1
materialization: template-migration
---
# FE-SCR-031 — Hàng khách trả

## 1. Mục tiêu

Hiện thực bề mặt `SCR-031` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-031`
- `UC-06-01`
- `UC-06-02`
- `UC-06-03`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-031`
- `DS-PROFILE`
- `UC-06-01`
- `UC-06-02`
- `UC-06-03`

## 5. States và Actions

- `READY`
- `LOADING`
- `WAITING_APPROVAL`
- `RETURN_CAP_CHANGED`
- `SOURCE_CHANGED`
- `CONFLICT`
- `LOCKED`
- `PERMISSION_DENIED`

- `ACT-07-RECEIVE-RETURN` — Ghi nhận hàng trả
- `ACT-07-SUBMIT-LOT-EXCEPTIONS` — Gửi ngoại lệ lô duyệt

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-031` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-031`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
