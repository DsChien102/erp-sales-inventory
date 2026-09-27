# Changelog — VET45 Theme 7 Prototype Harness v3.9.7

**Parent:** v3.9.6  
**Scope:** Wave 3 — BJ03 Xác nhận giá trị ban đầu của hàng nhận — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.6 was used as the **single Theme 7 review baseline**.
- Frozen-source remains historical and byte-identical.
- BJ01 and Wave 2 (BJ02, BJ05, BJ06, BJ07, BJ04) retain their locked semantic contracts.
- v3.9.7 becomes the cumulative baseline for the next Wave 3 review, BJ13.

## Approved BJ03 decisions implemented

1. `valuation_basis_key` is anchored to a **commercial receipt item/source line**, not to the Product+UOM presentation group. Multiple LOT/state technical scopes from the same receipt item may share one basis; independent receipt items never auto-merge just because Product+UOM match.
2. Server preview builds one or more complete immutable **DirectCostBasis** candidates. A basis carries commercial price plus relevant discount, benefit, known purchase cost, tax, FX, allocation/rounding and source/version provenance. Conflict is evaluated on authoritative basis facts, not raw document/unit-price identity alone.
3. Direct valuation preserves **transaction UOM** and its conversion snapshot while also storing normalized base quantity/cost. `OfficialCostVersion.unit_cost` is explicitly **VND / base UOM**.
4. Allocation and rounding are deterministic. Partial confirmations use cumulative allocation so total committed value is independent of whether the user confirms `1+1+1`, `2+1` or the full scope at once.
5. Final confirm rechecks selected `basis_version + basis_hash + scope_version`; it does not use one receipt-wide source version as the authoritative freshness gate. One stale selected scope rejects the whole selected set atomically.
6. Initial Official Cost uses atomic compare-and-create by `tenant + product`. The first winning confirmation creates the version; a concurrent later confirmation still commits its ReceiptValuation/ValueMovement but does not overwrite Official Cost and returns `ALREADY_INITIALIZED` semantics.
7. Direct receipt value movement uses `business_date = receipt_business_date`, while `recorded_at` is server commit time and accounting period is the period containing the receipt business date. Components that arrive after initial confirmation route to BJ13/valuation adjustment rather than rewriting historical ReceiptValuation.

## UX / runtime cleanup

- `SCR-016` remains a historical/migration identity only; it has no active UC/UIF route.
- `SCR-015` keeps Product+transaction-UOM as a readable hierarchy but treats valuation basis/source item as the semantic owner of cost.
- DirectCostBasis provenance/conflict is a contextual `VBottomSheet`, not an extra mandatory screen.
- `SCR-017` shows transaction-UOM direct cost plus normalized base-UOM consequence and removes normal-state `Sẵn sàng` badge noise.
- Financial-masked states do not put protected price/value facts into the DOM.
- `SCR-019` renders command-authoritative committed value/availability, receipt business date, server recorded time and Official-Cost bootstrap outcome.
- Final mutation UNKNOWN preserves the same operation identity and hands off to BJ17/system verification; preview/query timeouts remain safe refetches and are not business UNKNOWN.

## Contract / documentation propagation

Updated in the cumulative package:

- Decision Register: `T7-DR-150…156`.
- BJ03 journey and UC-03-01…03.
- Shared behavioral contracts `BC-IV-01` and `BC-IV-05`.
- Technical contracts `API-C-20` and `API-Q-11` payload semantics.
- `ReceiptValuation`, `InventoryValueMovement` and `OfficialCostVersion` data contracts.
- UIF-03 and `SCR-014/015/016/017/019` screen/component contracts.
- Screen registry/catalog, workbench data, action registry and harness contract registry.
- Knowledge-base valuation guidance and current runtime prototype overlay.

## QA

- BJ03 Deep Review: **61/61 PASS**, 5 focused visual captures, 0 browser/console errors.
- BJ03 fresh-eye re-walk: **13/13 PASS**.
- Prior locked regression — BJ01 + Wave 2: **17/17 PASS**.
- Wave 2 Cross-BJ Audit baseline remains **30/30 PASS**.
- Frozen-source immutability: **PASS · 108/108 files byte-identical**.
- Current package validation: **28/28 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 514 declared states.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens checked.
