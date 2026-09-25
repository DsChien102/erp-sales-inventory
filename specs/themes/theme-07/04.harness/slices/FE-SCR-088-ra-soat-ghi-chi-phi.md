---
id: FE-SCR-088
type: fe-slice
theme: theme-07
title: "Rà soát điều chỉnh giá trị"
owner: SE
status: READY_FOR_PROTOTYPE
source_baseline: v3.13.0
materialization: valuation-design-parity
---
# FE-SCR-088 — Rà soát điều chỉnh giá trị

## 1. Mục tiêu

Rà soát read-only signed adjustment trước khi commit.

## 2. Authority

- Screen Contract: [`SCR-088`](../../03.design/screens/SCR-088.md)
- Use Case: `UC-13-01`
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v3.13.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `READY`, `SOURCE_CHANGED`, `VALIDATION_ERROR`, `PERMISSION_DENIED`
- Components: `VAppBar`, `DS v2 / Info Row`, `DS v2 / Key-value Row`, `DS v2 / Summary Card`, `VBanner`, `VButton`
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Kiểm parity giữa Screen Contract → runtime HTML → Inspect metadata.
- Kiểm empty/loading/error/permission/conflict/unknown khi Screen Contract yêu cầu.
- Kiểm không có horizontal overflow, footer che content hoặc CTA ngoài authority.
