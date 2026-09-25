---
id: FE-SCR-015
type: fe-slice
theme: theme-07
title: "Xác lập giá trị nhập ban đầu"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v3.13.0
materialization: valuation-design-parity
---
# FE-SCR-015 — Xác lập giá trị nhập ban đầu

## 1. Mục tiêu

Một bề mặt để hiểu hàng thực nhận, rà soát căn cứ giá và cấu thành giá trị; nhập nhanh có thể thêm căn cứ giá trực tiếp bằng sheet.

## 2. Authority

- Screen Contract: [`SCR-015`](../../03.design/screens/SCR-015.md)
- Use Case: `UC-03-01`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v3.13.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `READY`, `LOADING`, `VALIDATION_ERROR`, `PERMISSION_DENIED`, `EVIDENCE_MISSING`, `ALREADY_CONFIRMED`, `SOURCE_CHANGED`
- Components: `VAppBar`, `DS v2 / List Row`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `DS v2 / Summary Card`, `VBanner`, `VButton`, `VTextField`, `VBottomSheet`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
