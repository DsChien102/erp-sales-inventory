---
id: FE-SCR-017
type: fe-slice
theme: theme-07
title: "Rà soát giá trị nhập ban đầu"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v4.3.0
materialization: valuation-design-parity
---
# FE-SCR-017 — Rà soát giá trị nhập ban đầu

## 1. Mục tiêu

Rà soát read-only toàn bộ căn cứ và giá trị nhập ban đầu trước khi xác nhận.

## 2. Authority

- Screen Contract: [`SCR-017`](../../03.design/screens/SCR-017.md)
- Use Case: `UC-03-01`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v4.3.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `READY`, `SOURCE_CHANGED`, `PERMISSION_DENIED`
- Components: `VAppBar`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `VBanner`, tối đa một `DS v2 / Summary Card`, `DS v2 / Sticky Footer`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Final valuation renderer: `03.design/prototype/html/v430-valuation-uiux.js`.

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
