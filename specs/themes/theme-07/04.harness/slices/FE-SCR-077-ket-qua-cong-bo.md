---
id: FE-SCR-077
type: fe-slice
theme: theme-07
title: "Kết quả công bố giá vốn"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v3.13.0
materialization: valuation-design-parity
---
# FE-SCR-077 — Kết quả công bố giá vốn

## 1. Mục tiêu

Kết quả công bố giá vốn bằng ngôn ngữ nghiệp vụ; thông tin kỹ thuật chỉ giữ trong Inspect/audit.

## 2. Authority

- Screen Contract: [`SCR-077`](../../03.design/screens/SCR-077.md)
- Use Case: `UC-14-04`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v3.13.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `COMPLETED`, `REJECTED_EXECUTION`, `UNKNOWN`, `PERMISSION_DENIED`
- Components: `VAppBar`, `VEmptyState`, `DS v2 / Summary Card`, `DS v2 / Key-value Row`, `VBanner`, `VButton`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
