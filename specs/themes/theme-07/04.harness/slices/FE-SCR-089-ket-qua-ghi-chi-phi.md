---
id: FE-SCR-089
type: fe-slice
theme: theme-07
title: "Kết quả điều chỉnh giá trị"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v4.3.0
materialization: valuation-design-parity
---
# FE-SCR-089 — Kết quả điều chỉnh giá trị

## 1. Mục tiêu

Kết quả có thẩm quyền của signed adjustment và trạng thái cần cập nhật giá vốn.

## 2. Authority

- Screen Contract: [`SCR-089`](../../03.design/screens/SCR-089.md)
- Use Case: `UC-13-01`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v4.3.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `PROCESSING`, `COMPLETED`, `REJECTED_EXECUTION`, `UNKNOWN`, `PERMISSION_DENIED`
- Components: `VAppBar`, `VEmptyState`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `VBanner`, `VButton`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Final valuation renderer: `03.design/prototype/html/v430-valuation-uiux.js`.

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
