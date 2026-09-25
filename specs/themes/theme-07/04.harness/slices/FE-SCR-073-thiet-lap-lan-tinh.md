---
id: FE-SCR-073
type: fe-slice
theme: theme-07
title: "Thiết lập lần tính — Đã hợp nhất"
owner: SE
status: RETIRED
source_baseline: v3.13.0
materialization: valuation-design-parity
---
# FE-SCR-073 — Thiết lập lần tính — Đã hợp nhất

## 1. Mục tiêu

Không hiện thực bề mặt độc lập; Screen đã được hợp nhất/retire và chỉ giữ ID để trace.

## 2. Authority

- Screen Contract: [`SCR-073`](../../03.design/screens/SCR-073.md)
- Use Case: Không có UC active; chỉ giữ migration trace.
- Design System: `03.design/design-system/design-system-profile.md`
- Prototype baseline: `v3.13.0`

## 3. Scope FE

- FE chỉ render state/action/navigation đã có trong Screen Contract và UC/BC.
- Không tự tạo nguồn dữ liệu, rule tài chính, quyền hoặc finality.
- Product UI dùng ngôn ngữ nghiệp vụ; metadata kỹ thuật chỉ ở Inspect/audit.

## 4. State và composition

- States: `RETIRED_ACTIVE_ROUTE`
- Components: Không render component; route đã retired.
- Mobile baseline: `402×874`, edge `16`, touch target tối thiểu `44`.

## 5. Verification

- Không có active route trong `UIF-03/UIF-13/UIF-14`; mọi deep link cũ phải redirect về Screen sở hữu.
