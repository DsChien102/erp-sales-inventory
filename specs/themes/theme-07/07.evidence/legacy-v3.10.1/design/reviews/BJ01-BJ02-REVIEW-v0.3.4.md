# BJ01 + BJ02 Product Review — v0.3.4

Parent: `v0.3.3`  
Scope: BJ01 end-user QA corrections + two Product-requested BJ02 UX changes.

## BJ01 — end-user QA

The existing v0.3.3 information architecture was retained. QA focused on whether the current UI behaves and reads correctly for an end user.

Corrections made:
- Search promise and behavior now match: name, product code and barcode all work.
- Refresh of stale stock data visibly updates the as-of timestamp.
- LOW/OUT copy explains the relationship between current availability, threshold, target and suggested replenishment instead of presenting unexplained numbers.
- Provenance entry no longer repeats the timestamp already visible at page level; its sheet uses business-facing wording.
- The BJ01 bottom-sheet handle is neutral rather than danger red.

No new full screen was added.

## BJ02 — requested UX refinements

### 1. Four receipt classifications always visible

`SCR-084 — Chi tiết hàng thực nhận` now always shows:
- Đạt
- Cách ly
- Hỏng
- Từ chối

`Số lượng thực nhận` remains the authoritative total. `Đạt` is derived/read-only so the UI does not create two independent sources for the same quantity. The three exception classifications are editable.

The same model is used for non-LOT and for the active LOT editor.

### 2. Quick Receive searches Product on Hàng thực nhận

Quick Receive keeps the established flow boundary:

`SCR-008 Nhập hàng nhanh → SCR-009 Hàng thực nhận → SCR-084 Chi tiết hàng thực nhận`

The difference is within SCR-009:
- Product search is directly available there.
- If the Product has one valid inbound UOM, it is added to the receipt list immediately.
- If the Product has multiple valid inbound UOMs, UOM is selected on SCR-009 first.
- The Product then appears in the Hàng thực nhận list as an unfinished item.
- Tapping the item opens SCR-084 to enter actual quantity / LOT detail.
- Duplicate Product + UOM remains blocked and points the user to the existing item.

## QA findings fixed during implementation

- Search filtering initially left hidden options visually displayed because an existing grid rule overrode the HTML `hidden` state. Fixed with scoped UIF02 CSS.
- The multi-UOM selection step initially showed the empty-receipt message underneath the pending UOM picker. The empty state is now suppressed while the Product is being completed.
- BJ01 inherited a red bottom-sheet handle from shared CSS. It was corrected only for UIF01 to avoid silently restyling unrelated BJs.

## Boundaries retained

- Flutter Design System remains the visual/component authority; HTML remains the renderer/workbench.
- Quick Receive still always requires approval.
- Maker and approver remain separate actors.
- Approved execution remains system-owned.
- UNKNOWN/recovery still does not create a blind retry/new receipt.
- No unrelated BJ/UIF business contract was intentionally changed.
