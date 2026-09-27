---
id: FE-SCR-074
type: fe-slice
theme: theme-07
title: "Tính và rà soát giá vốn"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v4.3.0
materialization: valuation-design-parity
---
# FE-SCR-074 — Tính và rà soát giá vốn

## 1. Mục tiêu

Một bề mặt cho setup cần thiết, tính, blocker, rà soát và chuẩn bị công bố; phương pháp áp dụng lấy từ chính sách tenant và không thể chọn lại.

## 2. Authority

- Screen Contract: [`SCR-074`](../../03.design/screens/SCR-074.md)
- Use Case: `UC-14-01`, `UC-14-04`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v4.3.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `CALCULATING`, `BLOCKED`, `READY_FOR_REVIEW`, `INPUT_CHANGED`, `PERMISSION_DENIED`
- Components: `VAppBar`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `DS v2 / List Row` (Status), `VBanner`, tối đa một `DS v2 / Summary Card`, `DS v2 / Confirmation Sheet`, `DS v2 / Sticky Footer`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Final valuation renderer: `03.design/prototype/html/v430-valuation-uiux.js`.

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
