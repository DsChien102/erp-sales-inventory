# BJ-01 End-user QA v0.3.4

**Result: 26/26 PASS**

End-user review in Chromium at the canonical 402 × 874 viewport.

## Checks

- [x] mobile frame 402x874 — [402, 874]
- [x] one inventory list, no Tra cứu/Cần chú ý tabs
- [x] search placeholder says name/code/barcode
- [x] compact rows do not show tracking policy
- [x] list has no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] barcode search actually finds product — 1
- [x] LOW filter selected
- [x] LOW rows do not repeat LOW badge
- [x] opens stock detail
- [x] detail has one available hero + three supporting quantities — ['Tồn vật lý', 'Đủ điều kiện bán', 'Đã giữ']
- [x] normal product does not get warning noise
- [x] detail has no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] provenance entry does not duplicate timestamp
- [x] long product name wraps instead of clipping
- [x] long content still has no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 858, 'ch': 858}
- [x] lot detail is contextual bottom sheet
- [x] lot sheet keeps only useful business language
- [x] lot sheet no horizontal overflow — {'sw': 386, 'cw': 386, 'sh': 876, 'ch': 858}
- [x] provenance explains source in end-user language
- [x] provenance has no technical English
- [x] LOW message explains threshold
- [x] LOW message explains suggestion reaches target
- [x] refresh returns to READY
- [x] refresh visibly updates as-of — Kho trung tâm · Cập nhật lúc 09:42 · 27/08/2026 -> Kho trung tâm · Cập nhật lúc 09:48 · 27/08/2026
- [x] permission uses full empty state
- [x] permission masks inventory facts

## Scope

- Search/filter behavior, information hierarchy, content hygiene, stale refresh, LOT/provenance overlays, permission masking and mobile overflow.
- This is a product-facing QA gate, not a declaration that future Product review cannot request further refinement.
