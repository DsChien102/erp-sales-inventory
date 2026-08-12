# BJ01 Deep Review QA — v3.9.1

**Result: PASS · 31/31**

Scope: approved Wave 1 semantic hardening for BJ01 Tồn kho.

- PASS — Runtime package identifies v3.9.1
- PASS — List freshness is server snapshot wording
- PASS — NOT_CONFIGURED is explicit instead of silently NORMAL: `Oxytetracycline LA · SP-000147
26 chai khả dụng · Chưa có ngưỡng tồn`
- PASS — Product-level expiry copy is scoped to LOT: `Tylosin 20% · SP-000122
4 lọ khả dụng · Có lô hết hạn`
- PASS — All-list decision phrases fit without subtitle ellipsis: `[]`
- PASS — Selected LOW filter controls row attention phrase: `Tylosin 20% · SP-000122
4 lọ khả dụng · Tồn thấp`
- PASS — Selected EXPIRED filter controls row attention phrase: `Tylosin 20% · SP-000122
4 lọ khả dụng · Có lô hết hạn`
- PASS — Product identity does not use a metric badge: `Nobivac DHPPi
SP-000184 · hộp`
- PASS — Availability is an Emphasis Key-value Row: `Khả dụng
106 hộp`
- PASS — Product supporting facts remain authoritative product-grain quantities
- PASS — Physical-to-eligible difference is explained
- PASS — LOT list preserves source expiry precision and physical quantity
- PASS — LOT sheet does not invent reserved or available quantity: `Lô DH2509

Nobivac DHPPi · HSD 15/09/2026

Tồn vật lý
50 hộp
Đủ điều kiện bán
48 hộp
Cận hạn
Còn 19 ngày · vẫn đủ điều kiện bán theo chính sách hiện tại.`
- PASS — Near-expiry WARN explains sellability: `Lô DH2509

Nobivac DHPPi · HSD 15/09/2026

Tồn vật lý
50 hộp
Đủ điều kiện bán
48 hộp
Cận hạn
Còn 19 ngày · vẫn đủ điều kiện bán theo chính sách hiện tại.`
- PASS — MONTH expiry precision is preserved on UI: `Lô TY2511

Tylosin 20% · HSD 11/2027

Tồn vật lý
7 lọ
Đủ điều kiện bán
7 lọ`
- PASS — Expired LOT explains ineligibility: `Lô TY2408

Tylosin 20% · HSD 31/07/2026

Tồn vật lý
11 lọ
Đủ điều kiện bán
0 lọ
Hết hạn
Lượng của lô này không đủ điều kiện bán.`
- PASS — Provenance uses concrete snapshot, movement and reservation source
- PASS — Generic VET45 source copy and vague scope copy are removed
- PASS — Deep history remains a BJ15 handoff
- PASS — Refresh advances only to response query_as_of fixture
- PASS — BJ01 refresh handler does not use client Date()
- PASS — LOW banner frames replenishment as a suggestion
- PASS — EMPTY means inventory data, not absence of product master: `9:41
LTE  100%
Tồn kho

Kho trung tâm · Dữ liệu đến 09:47, 27/08/2026

Tất cả
Hết hàng
Tồn thấp
Cận hạn
Hết hạn
Chưa có dữ liệu tồn kho

Không có dữ liệu trong kho hiện tại.`
- PASS — Representative BJ01 screen has no horizontal overflow: `{'sw': 402, 'cw': 402}`
- PASS — BJ01 LOT fixtures contain no reserved/available fields: `4 LOT fixtures scanned`
- PASS — PRJ-01 explicitly forbids LOT reserved/available
- PASS — PRJ-08 separates stock level from expiry attention
- PASS — Active BJ01 use cases no longer reference retired screen routes: `UC-01-01..05 scanned`
- PASS — Current UIF contract states LOT has no pre-allocation reserved/available
- PASS — Current SCR-003 contract makes availability a metric, not badge
- PASS — No browser errors: `[]`

## Captures

- `01-SCR001-ALL-SEMANTIC.png` — SCR-001 with scoped indicators, query_as_of and NOT_CONFIGURED
- `02-SCR001-LOW-MULTI-INDICATOR.png` — Multi-indicator product under LOW filter uses LOW phrase
- `03-SCR003-NOBIVAC-DETAIL.png` — Availability as metric with eligibility breakdown and LOT list
- `04-LOT-WARN-NO-RESERVATION.png` — LOT detail has physical/eligible/expiry only
- `05-PROVENANCE-CONCRETE.png` — Concrete provenance summary with BJ15 handoff
