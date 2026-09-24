# BJ03 Deep Review QA — v3.9.7

**Result: PASS · 61/61**

Scope: approved D03-01..D03-07 / T7-DR-150..156, DirectCostBasis semantics, transaction/base-UOM normalization, deterministic cumulative allocation, basis/scope freshness, Official Cost bootstrap and accounting-time boundaries.

- PASS — Approved BJ03 decisions T7-DR-150..156 are registered
- PASS — Decision register identifies direct valuation amendment v4.2.2
- PASS — Valuation basis is anchored to receipt item/commercial source line
- PASS — Complete DirectCostBasis contains component provenance
- PASS — Exact valuation scope remains technical line/LOT/state/quantity
- PASS — Transaction UOM and base-UOM normalization are explicit in data model
- PASS — Direct cost stores both transaction-UOM and base-UOM unit cost
- PASS — OfficialCostVersion is VND per base UOM
- PASS — ReceiptValuation persists complete basis identity/version/hash/snapshot
- PASS — ReceiptValuation persists authoritative allocated value and cumulative value
- PASS — Evidence hash binds complete basis, not one filename/document
- PASS — Partial allocation/rounding cumulative semantics are explicit
- PASS — BC-IV-01 rechecks selected basis and scope tokens
- PASS — BC-IV-01 writes receipt-business-date value movement
- PASS — BC-IV-05 is non-mutating complete-basis preview
- PASS — Technical API-Q-11 returns basis/scope freshness tokens
- PASS — Technical confirm does not trust client unit-cost multiplication
- PASS — Initial Official Cost bootstrap is compare-and-create atomic
- PASS — Initial Official Cost effective_from is winning server commit time
- PASS — Direct value movement uses receipt period and blocks silent locked-period back-post
- PASS — Late components route to BJ13 rather than rewriting confirmed receipt valuation
- PASS — UC03-01 preview/query does not use business UNKNOWN
- PASS — UC03-02 preview/query does not use business UNKNOWN
- PASS — UC03-03 owns final mutation/finality
- PASS — SCR-016 is retired from active flow
- PASS — SCR-015 contract separates presentation group from valuation basis
- PASS — SCR-017 shows transaction cost and normalized base consequence
- PASS — SCR-017 explicitly removes normal READY badge
- PASS — SCR-019 is command-authoritative result surface
- PASS — Registry removes active UC mapping from historical SCR-016
- PASS — Workbench removes historical SCR-016 from UIF active mapping
- PASS — Action registry binds confirm to basis/scope recheck
- PASS — Harness includes BC-IV-05 preview contract
- PASS — Harness includes API-Q-11 preview operation
- PASS — Harness BC-IV-01 mutation story is UC-03-03 only
- PASS — Current manifest identifies v3.9.7 BJ03 hardening
- PASS — Runtime identifies v3.9.7
- PASS — v3.9.7 BJ03 trace helper is loaded
- PASS — Mixed actionable/waiting receipt remains actionable
- PASS — Scope screen uses Product/UOM hierarchy and exact LOT/state children
- PASS — Scope screen labels conflict as business evidence issue
- PASS — Evidence sheet presents complete basis rather than one raw document
- PASS — Evidence sheet exposes transaction-UOM and base-UOM consequence
- PASS — Review shows transaction unit cost and normalized base consequence
- PASS — Review does not use normal-state Sẵn sàng badge
- PASS — Review names complete basis as Căn cứ giá
- PASS — Financial masked review contains no protected price/value facts
- PASS — Conflicting complete bases are not preselected
- PASS — Conflict resolution requires explicit complete-basis choice and reason
- PASS — Conflict can proceed only after basis choice + reason
- PASS — Selected basis change rejects stale review before mutation
- PASS — Stale selected basis does not navigate to result
- PASS — Cumulative partial allocation closes exactly to authoritative scope value
- PASS — First-cost review states exact Official Cost bootstrap consequence
- PASS — Completed result uses original receipt business date
- PASS — Completed result separately shows server recorded time
- PASS — Completed result reports Official Cost bootstrap in base UOM
- PASS — Completed result shows command-authoritative committed value
- PASS — Runtime active UIF03 route excludes historical SCR-016
- PASS — Focused BJ03 browser has no page errors
- PASS — Focused BJ03 browser has no console errors

## Visual captures
- `01-SCR014-WORKLIST.png` — BJ03 worklist — receipt with mixed basis state stays actionable
- `02-SCR015-DIRECT-COST-BASIS.png` — BJ03 contextual DirectCostBasis/provenance sheet
- `03-SCR017-REVIEW.png` — BJ03 review — transaction and normalized base cost without normal READY badge
- `04-SCR017-STALE-BASIS.png` — BJ03 stale basis — selected-set confirmation blocked before mutation
- `05-SCR019-AUTHORITATIVE-RESULT.png` — BJ03 authoritative result — business date, recorded time and Official Cost bootstrap
