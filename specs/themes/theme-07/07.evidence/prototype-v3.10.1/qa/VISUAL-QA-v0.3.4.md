# Visual QA v0.3.4

**Result: PASS**

Reviewed at the canonical **402 × 874** mobile viewport after runtime QA.

## BJ01 specimens reviewed

- `BJ01-SCR-001-all.png` — single stock list, compact rows, no duplicate UOM/tracking noise.
- `BJ01-SCR-001-low.png` — filtered list retains hierarchy without repeating the same LOW badge on each row.
- `BJ01-SCR-003-normal.png` — one primary availability value, compact supporting quantities and LOT rows.
- `BJ01-SCR-003-low.png` — LOW warning explains threshold → target → suggested quantity without creating extra metric cards.
- `BJ01-LOT-sheet.png` — bottom sheet fits viewport, neutral handle, warning status does not recolor the sheet chrome.
- `BJ01-provenance-sheet.png` — business-facing wording, no duplicated technical card stack.

## BJ02 specimens reviewed

- `BJ02-quick-overview-empty.png` — Product search is directly available on Hàng thực nhận.
- `BJ02-quick-overview-search.png` — result overlay is readable and non-matching results are truly hidden.
- `BJ02-quick-overview-uom.png` — multi-UOM choice stays on Hàng thực nhận and no unrelated empty state is shown underneath.
- `BJ02-quick-overview-list.png` — selected Product + UOM becomes an item in the receipt list; no automatic jump to detail.
- `BJ02-detail-four-classifications-lot.png` — four classifications fit in a 2 × 2 layout below total actual quantity; sticky footer does not cover the active fields.
- `BJ02-detail-four-classifications-nonlot.png` — same four-field model for non-LOT Product.

## Visual checks

- No horizontal overflow detected in tested target screens.
- No clipped Product names in BJ01 long-name stress check.
- Search/UOM overlays stay inside the Product viewport.
- Sticky footer remains distinct from scrollable content.
- No new technical English leakage found in BJ01 Product UI.

Visual QA is evidence for this build, not a substitute for Product approval.
