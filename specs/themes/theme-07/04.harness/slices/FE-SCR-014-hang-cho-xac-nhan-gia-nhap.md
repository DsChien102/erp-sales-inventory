---
id: FE-SCR-014
type: fe-slice
theme: theme-07
title: "Hàng chờ xác lập giá trị"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v4.3.0
materialization: valuation-design-parity
---
# FE-SCR-014 — Hàng chờ xác lập giá trị

## 1. Mục tiêu

Danh sách hàng đã nhận nhưng chưa có giá trị nhập ban đầu; người dùng hiểu ngay việc nào có thể xử lý, cần đối chiếu hoặc cần bổ sung căn cứ.

## 2. Authority

- Screen Contract: [`SCR-014`](../../03.design/screens/SCR-014.md)
- Use Case: `UC-03-01`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v4.3.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `READY`, `LOADING`, `EMPTY`, `FILTER_EMPTY`, `PERMISSION_DENIED`, `FINANCIAL_MASKED`
- Components: `VAppBar`, `VSearchBar`, `VChip`, `DS v2 / List Row`, `VBadge`, `VSkeleton`, `VEmptyState`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Final valuation renderer: `03.design/prototype/html/v430-valuation-uiux.js`.

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
