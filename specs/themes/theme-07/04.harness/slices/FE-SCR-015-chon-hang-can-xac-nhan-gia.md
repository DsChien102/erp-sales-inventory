---
id: FE-SCR-015
type: fe-slice
theme: theme-07
title: "Chọn hàng cần xác nhận giá"
owner: SE
status: DRAFT
source_baseline: v3.12.0
materialization: template-migration
---
# FE-SCR-015 — Chọn hàng cần xác nhận giá

## 1. Mục tiêu

> **Carry-forward v3.12.0:** Slice này được giữ để bảo toàn delivery/UI mapping của v3.11.0, nhưng các UC lịch sử `UC-03-02` đã được hợp nhất. Nguồn semantic canonical hiện hành là `UC-03-01`. Không được dùng tên/ranh giới UC cũ để tạo business rule mới; consolidation vật lý của Slice/Screen sẽ đi cùng lượt parity downstream.

Hiện thực bề mặt `SCR-015` đúng Screen Contract; không tạo business rule mới.

## 2. Screen Contract

- `SCR-015`
- `UC-03-01`

## 3. Scope

### 3.1 Owns

Rendering, state/action binding và navigation/feedback của Screen.

### 3.2 Does not own

Business semantics của UC/BC hoặc architecture backend.

## 4. Nguồn đầu vào

- `SCR-015`
- `DS-PROFILE`
- `UC-03-01`

## 5. States và Actions

- `READY`
- `LOADING`
- `VALIDATION_ERROR`
- `PERMISSION_DENIED`
- `EVIDENCE_MISSING`
- `ALREADY_CONFIRMED`
- `SOURCE_CHANGED`

## 6. Data / Interface mapping

Action/BC/API mapping được giữ trong Screen Contract và action registry nguồn; FE Slice không tự tạo interface.

## 7. Component composition

Theo mục 9 của `SCR-015` và `DS-PROFILE`.

## 8. Navigation và feedback

Theo Entry/Exit, States và Validation của `SCR-015`.

## 9. Responsive / accessibility

Mobile baseline 402×874 và các rule accessibility đã khóa trong Design System/source contract.

## 10. Verification

Đối chiếu Screen Contract, UC coverage, component mapping và trạng thái/action.

## 11. Delivery

Chưa có production implementation delivery trong baseline; Slice được materialize theo template mới.
