# BJ-01 Runtime / Visual Smoke v0.3.2

**Result: 61/61 PASS**

Runs the real cumulative workbench renderer in headless Chromium with a 402 × 874 product viewport. Screenshots are written only to `screenshots-v0.3.2`; historical BJ-02 screenshots are not touched.

## Checks

- [x] mobile frame remains 402x874 — [402, 874]
- [x] SCR-001 has no Tra cứu/Cần chú ý tabs
- [x] SCR-001 has 5 filter chips — 5
- [x] SCR-001 shows five fixture rows
- [x] SCR-001 search copy uses mã vạch
- [x] SCR-001 has no tracking metadata
- [x] SCR-001 first row uses one compact quantity+UOM
- [x] SCR-001 left metadata does not repeat UOM — Nobivac DHPPi
SP-000184
Có lô cận hạn
- [x] SCR-001 product row remains compact — 66
- [x] SCR-001 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] OUT filter returns expected count — ['INV-ENRO']
- [x] OUT filter includes expected product — ['INV-ENRO']
- [x] OUT filtered rows do not repeat filter status — 0
- [x] LOW filter returns expected count — ['INV-AMX', 'INV-TYLO']
- [x] LOW filter includes expected product — ['INV-AMX', 'INV-TYLO']
- [x] LOW filtered rows do not repeat filter status — 0
- [x] NEAR filter returns expected count — ['INV-NOB']
- [x] NEAR filter includes expected product — ['INV-NOB']
- [x] NEAR filtered rows do not repeat filter status — 0
- [x] EXPIRED filter returns expected count — ['INV-TYLO']
- [x] EXPIRED filter includes expected product — ['INV-TYLO']
- [x] EXPIRED filtered rows do not repeat filter status — 0
- [x] search filters current list
- [x] search no-result retains search and chips
- [x] clear search/filter restores full list
- [x] FILTER_EMPTY renders empty state with filters retained
- [x] FILTER_EMPTY clear recovers READY state
- [x] product row opens SCR-003
- [x] SCR-003 hero shows available once at product level
- [x] SCR-003 supporting breakdown is exactly 3 rows — ['Tồn vật lý', 'Đủ điều kiện bán', 'Đã giữ']
- [x] SCR-003 breakdown does not repeat Khả dụng — ['Tồn vật lý', 'Đủ điều kiện bán', 'Đã giữ']
- [x] SCR-003 normal product has no product-level attention block
- [x] SCR-003 LOT list has two compact rows
- [x] LOT-level near-expiry wording stays on LOT row
- [x] SCR-003 has no technical/English leakage — 09:45
5G
Chi tiết tồn kho
Kho trung tâm
·
Cập nhật lúc 09:42 · 27/08/2026
SP-000184
Nobivac DHPPi
Khả dụng
106 hộp
Số lượng trong kho
Tồn vật lý
120 hộp
Đủ điều kiện bán
118 hộp
Đã giữ
12 hộp
Lô và hạn dùng
2 lô
DH2507
HSD 30/11/2026
62 hộp
Khả dụng

- [x] SCR-003 no legacy card-heavy BJ01 blocks
- [x] SCR-003 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] long product name wraps without horizontal overflow — {'h': 72, 'sw': 249, 'cw': 249}
- [x] LOT opens contextual bottom sheet
- [x] LOT sheet does not navigate away from SCR-003
- [x] LOT sheet shows identity expiry and availability
- [x] LOT sheet has 3 supporting rows without duplicate available — ['Tồn vật lý', 'Đủ điều kiện bán', 'Đã giữ']
- [x] LOT sheet carries update time without extra context cards
- [x] closing LOT sheet returns same detail screen
- [x] provenance opens contextual bottom sheet
- [x] provenance uses Vietnamese business copy
- [x] provenance hides technical terminology
- [x] provenance stays on SCR-003 until explicit handoff
- [x] LOW detail shows one compact attention row
- [x] LOW detail shows threshold and suggested quantity
- [x] LOW non-LOT product has no LOT list
- [x] OUT detail shows Hết hàng
- [x] OUT detail shows configured threshold/suggestion only when useful
- [x] mixed indicator product prioritizes product LOW in detail attention — Tồn thấp
Ngưỡng 8 lọ · Gợi ý bổ sung 20 lọ
- [x] expired status remains on affected LOT row
- [x] no-threshold product stays quiet
- [x] STALE retains data with refresh affordance
- [x] refresh returns current screen to READY
- [x] permission denied does not render inventory quantities
- [x] permission denied uses centered empty surface
- [x] final SCR-001 no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}

## Boundary

- Covers BJ-01 single-list architecture, filters/search, compact information hierarchy, LOT/provenance overlays, LOW/OUT/no-threshold/stale/permission scenarios and overflow.
- Browser smoke plus screenshot review is required; this report does not assert pixel identity with BJ-02 or any external design source.
