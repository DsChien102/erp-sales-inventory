# BJ-02 Runtime QA v0.3.4

**Result: 42/42 PASS**

Chromium interaction QA at 402 × 874 for the two requested BJ02 refinements.

## Checks

- [x] mobile frame 402x874 — [402, 874]
- [x] Quick header still owns supplier/date/evidence before item overview
- [x] Quick header continues to SCR009
- [x] Quick SCR009 has VSearchBar directly
- [x] Quick SCR009 has no Add Product CTA
- [x] empty Quick overview explains search above
- [x] Quick overview no horizontal overflow
- [x] Quick search filters product results
- [x] multi-UOM choice stays on SCR009
- [x] selected product becomes list item on SCR009
- [x] no automatic jump to detail after adding
- [x] tap item opens SCR084
- [x] Product/UOM already selected in normal Quick editor
- [x] LOT editor shows four classification fields immediately — ['Đạt', 'Cách ly', 'Hỏng', 'Từ chối']
- [x] Đạt is read-only derived field
- [x] no classification reveal button
- [x] Đạt derives from total immediately
- [x] Đạt updates when classification changes
- [x] detail no horizontal overflow
- [x] save returns SCR009
- [x] duplicate blocked on SCR009
- [x] duplicate did not add second item
- [x] duplicate offers open existing CTA
- [x] open existing goes to SCR084
- [x] single-UOM product adds immediately on overview
- [x] non-LOT editor shows four classification fields immediately — ['Đạt', 'Cách ly', 'Hỏng', 'Từ chối']
- [x] non-LOT Đạt derives live
- [x] non-LOT Đạt updates live
- [x] completed Quick item returns to overview
- [x] Quick review becomes available after item is handled
- [x] Quick review still requires approval
- [x] maker submit stays in pending approval without stock execution
- [x] approver still has only Duyệt/Từ chối decisions
- [x] approval starts system-owned execution
- [x] system execution reaches authoritative result state
- [x] UNKNOWN recovery keeps same operation and no blind retry CTA
- [x] Document detail keeps source context
- [x] Document LOT detail shows four classification fields — ['Đạt', 'Cách ly', 'Hỏng', 'Từ chối']
- [x] Document has no reveal button
- [x] read-only overview hides Quick search
- [x] read-only overview still shows existing item
- [x] read-only has no mutation footer

## Regression intent

- Keeps the existing BJ02 flow boundaries: Quick header → Hàng thực nhận → item detail → review.
- Product/UOM discovery moved to Hàng thực nhận; item detail still owns actual quantity/LOT editing.
- Four classifications are always visible while `Đạt` remains derived, preserving one authoritative input for total actual quantity.
