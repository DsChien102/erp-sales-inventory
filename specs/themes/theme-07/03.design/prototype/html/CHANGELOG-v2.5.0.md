# Changelog v2.5.0 — BJ02 Figma DS migration

Parent: **v2.4.5**.

## Product / business corrections

- Revalidated BJ02 end-to-end before UI migration.
- Preserved one Goods receipt → one Supplier.
- Preserved no quick-create Supplier/Product inside receiving.
- nhập hàng nhanh remains approval-required and maker/approver responsibilities remain distinct.
- SCR-084 keeps exactly four authoritative quantity inputs: Đạt / Cách ly / Hỏng / Từ chối; total is derived.
- UNKNOWN result uses same-operation recovery and never blind-retries a mutation.

## Figma DS migration

- Replaced legacy/feature-specific presentation with existing canonical VET45 DS assets where semantically valid.
- Applied canonical List Row, Record Card, search/input/date/file controls, feedback, Sticky Footer and Confirmation Sheet responsibilities.
- Preserved 402×874 mobile canvas, 16px page edge, 370px content width, and ≥44px interaction targets.
- Created **0** BJ02 feature components.

## QA

- BJ02 Figma DS / Business QA: **PASS 39/39**.
- All-flow runtime smoke: **PASS 85/85**, browser errors **0**.
- BJ01 key-value regression: rerun and preserved.
- Release validation is recorded at repository root.
