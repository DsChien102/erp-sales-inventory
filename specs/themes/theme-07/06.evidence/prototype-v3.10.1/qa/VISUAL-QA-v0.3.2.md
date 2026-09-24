# Visual QA — BJ-01 v0.3.2

**Result: PASS for Product-review candidate.**

Reviewed real 402 × 874 Chromium specimens in `screenshots-v0.3.2/`:
- `SCR-001-all.png`
- `SCR-001-low.png`
- `SCR-003-normal.png`
- `SCR-003-low.png`
- `LOT-detail-sheet.png`
- `provenance-sheet.png`

## Findings corrected during QA
1. Product rows were still 80 px when an indicator created a third text line. Status was moved inline with product code; runtime target now remains compact.
2. Long Product names on detail were single-line truncated. Detail identity now wraps and remains clear of the availability value.
3. Provenance evidence still looked like a nested card. It now uses simple row separators inside the Bottom Sheet.
4. FILTER_EMPTY clear/filter actions could leave the controller state empty. Both now recover SCR-001 to READY.

## Visual acceptance
- One inventory list; no Tra cứu/Cần chú ý tabs.
- Search + filter chips remain in context. Horizontal chip scrolling is intentional on 402 px; partial next chip indicates more filters.
- Homogeneous Product and LOT lists use row separators, not card-per-record.
- One primary availability value on detail; no duplicate availability in supporting breakdown.
- LOW/OUT use one compact attention row; normal/no-threshold states do not add visual noise.
- LOT/provenance overlays preserve the underlying Product detail context.
- No horizontal overflow in representative states.

This is browser visual QA of the HTML prototype, not a claim of pixel parity against an external design source.
