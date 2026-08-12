---
id: FE-SCR-009-QUICK
type: fe-slice
theme: theme-07
title: Hàng thực nhận — Quick mode
owner: SE
status: DRAFT
sample_of: FE-SLICE.template.md
sample_status: DERIVED_SAMPLE
---
# FE-SCR-009-QUICK — Hàng thực nhận — Quick mode

## 1. Mục tiêu

Hiện thực Quick mode của `SCR-009`: tìm Product, chọn UOM khi cần, mở one-item editor và hiển thị danh sách item đã/chưa xử lý đúng Screen Contract.

## 2. Screen Contract

- Chính: `SCR-009`.
- UC: `UC-02-02`.
- Child screen dependency: `SCR-084`.
- Next: `SCR-010`.

## 3. Scope

### 3.1 Owns

- Quick Product search UI.
- Direct UOM selection khi có nhiều inbound UOM hợp lệ.
- Item list/summary và duplicate feedback.
- Navigation `SCR-009 ↔ SCR-084` và `SCR-009 → SCR-010`.
- Empty/read-only/permission state theo contract.

### 3.2 Does not own

- Business validation của Aggregate.
- Background draft persistence semantics.
- Product creation.
- Submit/approval behavior ở `SCR-010`.

## 4. Nguồn đầu vào

- `SCR-009`.
- `UC-02-02`.
- UIF-02 transitions `T08`, `T09`, `T12`.
- Design System components nêu trong Screen Contract.
- Published BE interface cho Product lookup/draft mutation khi đã được khóa.

## 5. States và Actions

- `EMPTY`: search vẫn hiển thị.
- Editable list.
- `LOCKED/READ_ONLY`.
- Product search → resolve Product.
- Multiple UOM → visible single choice.
- Duplicate Product+UOM → warning + mở item hiện có.
- `Rà soát` chỉ enabled khi có ≥1 item và tất cả đã xử lý.

## 6. Data / Interface mapping

- Search Product/UOM: consume owner-domain read interface.
- Tạo/mở/update item: consume BE application path của Quick Receipt draft.
- FE không gọi trực tiếp Aggregate hoặc tự tái hiện invariant.

## 7. Component composition

`VCard`, `VSearchBar`, `VIcon.chevronRight`, `Theme7InlineSingleChoice`, `VBanner.warning`, `VButton.primary`, `VEmptyState`.

## 8. Navigation và feedback

- Chọn đủ Product+UOM → đi thẳng `SCR-084`.
- `Xong` ở `SCR-084` → quay `SCR-009`.
- Duplicate → không tạo item mới; mở item đã có.

## 9. Responsive / accessibility

Mobile-first; touch target tối thiểu 44px theo baseline UI; không dùng chỉ màu để truyền trạng thái.

## 10. Verification

- Product 1 UOM → chọn là vào editor.
- Product nhiều UOM → tất cả lựa chọn hiện trực tiếp, không dropdown.
- Duplicate → không tạo item mới.
- Read-only → không có mutation controls.
- 1..N items render ổn; document/quick không bị lẫn semantics.

## 11. Delivery

Sample chưa gắn MR/build; mục tiêu là kiểm tra template FE Slice.
