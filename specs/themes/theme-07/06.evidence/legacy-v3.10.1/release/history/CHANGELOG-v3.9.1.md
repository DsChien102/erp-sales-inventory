# Changelog — VET45 Theme 7 Prototype Harness v3.9.1

**Parent:** v3.9.0  
**Scope:** Wave 1 — BJ01 Tồn kho — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.0 was used as the **single Theme 7 review baseline**.
- No separate Theme 7 source package was used as authority.
- v3.9.1 becomes the next cumulative review baseline after release.

## Approved BJ01 decisions implemented

1. **Reservation authority stays Product + Warehouse.** BJ01 no longer invents `Đã giữ/Khả dụng` at LOT grain; LOT allocation remains BJ05 responsibility.
2. **Independent indicators.** Stock level and expiry attention are separate dimensions; the selected filter determines the one decision phrase shown on the Product row.
3. **Server freshness.** UI uses `query_as_of` and wording `Dữ liệu đến`; refresh never turns client click time into business freshness.
4. **Eligibility explanation.** When physical quantity exceeds eligible quantity, BJ01 can show reason breakdown for the excluded quantity.
5. **Explicit missing policy.** `NOT_CONFIGURED` is different from NORMAL and is visible in monitoring context.
6. **Expiry semantics.** Near-expiry distinguishes `WARN` from `BLOCK_SALE`; source precision `DAY/MONTH/YEAR` is preserved.
7. **Concrete provenance.** Trace summary contains query-as-of, recent physical movement/source and reservation summary; generic `Nguồn dữ liệu: Tồn kho VET45` is removed. Deep history remains BJ15.
8. **Availability is a metric.** `Khả dụng` uses canonical `DS v2 / Key-value Row · Emphasis`, not a status badge.

## Fresh-eye refinements after implementation

- Product row identity is now `Tên · mã`; the second line is `N UOM khả dụng · attention` so decision phrases are not truncated by identity metadata.
- `NOT_CONFIGURED` list copy is shortened to `Chưa có ngưỡng tồn`; the detail surface keeps the fuller explanation.
- Product-level expiry copy is scoped explicitly as `Có lô cận hạn / Có lô hết hạn`.
- Empty state is `Chưa có dữ liệu tồn kho`; a Product with zero quantity remains a Product row.
- Suggested replenishment is explicitly framed as `Gợi ý bổ sung`, not an instruction or purchase proposal.
- Actor trace for monitoring surfaces now includes `Người mua hàng`, consistent with UC-01-04/05.

## Contract / data corrections

- `PRJ-01 AvailabilityView`: Product and LOT grain are separated; LOT rows do not own reservation/available quantity before authoritative pick allocation; `query_as_of`, eligibility breakdown and expiry precision are explicit.
- `PRJ-08 LowStockView`: `monitoring_config_status`, `stock_level_status` and `expiry_attention` are independent; threshold/target may be absent when NOT_CONFIGURED.
- Active UC screen references now follow current `UIF-01`: SCR-001 / SCR-003 + LOT/Provenance overlays; deep history is BJ15.
- Screen registry and workbench examples were synchronized with the current semantic expression.

## Runtime / UI

- LOT Bottom Sheet shows physical, eligible and expiry semantics only.
- WARN near-expiry explains that stock remains eligible; expired stock explains ineligibility.
- Provenance Bottom Sheet shows a concrete source/movement and reservation summary.
- STALE refresh advances to a server-response fixture timestamp, not `new Date()`.
- No new core Design System component was introduced.

## Cross-BJ impact scan

Reviewed semantic dependencies without redesigning BJ work ahead of their wave:

- **BJ04:** current reservation lifecycle already reserves before LOT allocation and remains compatible.
- **BJ05:** remains owner of authoritative LOT allocation/pick behavior.
- **BJ09:** current eligibility / BLOCK_SALE relationship remains compatible.
- **BJ12:** no new lifecycle behavior added; only BJ01 empty-state wording changed.
- **BJ15:** remains owner of deep stock-card/history trace.
- **CAP-01:** threshold/target and WARN/BLOCK_SALE policy remain the shared source used by BJ01.

## QA

- BJ01 Deep Review: **31/31 PASS**, 5 focused captures, 0 browser errors.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 browser errors.
- Runtime UI: **14/14 PASS**, **518 declared states**.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, **89 screens**.
- Current package validation: **19/19 PASS**.
