---
id: FE-SCR-072
type: fe-slice
theme: theme-07
title: "Công việc giá vốn"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v4.3.0
materialization: valuation-design-parity
---
# FE-SCR-072 — Công việc giá vốn

## 1. Mục tiêu

Danh sách công việc giá vốn theo nhu cầu thực tế: cập nhật trong kỳ, chốt kỳ hoặc việc đang bị chặn.

## 2. Authority

- Screen Contract: [`SCR-072`](../../03.design/screens/SCR-072.md)
- Use Case: `UC-14-01`, `UC-14-04`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v4.3.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `READY`, `LOADING`, `EMPTY`, `PERMISSION_DENIED`
- Components: `VAppBar`, `VSearchBar`, `VChip`, `DS v2 / List Row` (Navigation/Status), `VBadge`, `VSkeleton`, `VEmptyState`, `VButton`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Final valuation renderer: `03.design/prototype/html/v430-valuation-uiux.js`.

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
