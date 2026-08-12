# RELEASE VALIDATION — v3.0.1

Parent: `v3.0.0`  
Status: **PASS — REVIEW READY**

## Scope

Full **Inventory Operations + Inventory Valuation** UI/DS audit: **BJ01, BJ02, BJ03, BJ04, BJ05, BJ06, BJ07, BJ13, BJ14**. The release covers **41 canonical screens / 228 declared UI states**. It is a presentation, hierarchy, terminology and DS-conformance hardening release; business behavior and canonical journey topology remain unchanged.

## Main corrections

- **List Row leading icon:** icon is now semantic and optional. Product identity keeps the product icon; work queues, request/context summaries and lô/child rows hide decorative icons and reclaim the copy area instead of leaving an empty gutter.
- **BJ07:** the former Product/LOT block is treated correctly as a composition, not a new component. Product + unit = `List Row / Status / Compact`; lô/không theo lô = `List Row / Navigation / Default` without a decorative leading icon. One grouped surface owns the hierarchy.
- **BJ03:** Product parent is a canonical Status/Compact List Row; multi-select valuation scopes use checkbox + text composition. The redundant **“Công việc”** heading is removed. **“Căn cứ và cách tính”** now renders a real empty state when opened without scope instead of a blank sheet.
- **BJ13:** dense queue titles use the actual reference as primary text so long document names, subtitle and badge no longer collide.
- **BJ14 / global terminology:** `Cut-off` is replaced by **“Thời điểm chốt”**; user-facing `UOM`, `LOT`, `FX`, raw `vN`, policy-version codes and backend-state labels are removed from the audited Product UI.
- **Operations-wide:** BJ04/BJ05/BJ06 list helpers reuse the canonical List Row anatomy where their semantics match; meaningless package/file icons are removed, while meaningful Product identity remains.

## Figma grounding

Live VET45 Figma Design System file `QVJolM5tAdFKkhP7RIwe3y` remains UI authority. Primary references: `DS v2 / List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VRadio 522:7410`, `VBottomSheet 4695:6353`, `VAppBar 547:1594`.

**No new core Design System component was created.** Grouped Product → child structures remain layout compositions built from canonical primitives.

## Release gates

- Operations + Valuation v3.0.1 gate: **PASS 37/37** across **41 canonical screens / 228 declared-state renders**, 0 browser errors.
- All-flow runtime: **PASS 85/85 renders**, 0 browser errors.
- Device frame: **PASS 7/7**, all 85 screens checked; Product app remains **402×874** and decorative border-box **418×890**.
- Prior-BJ regression: **PASS 23/23**, 0 browser errors.
- BJ05 + BJ06 UX regression: **PASS 32/32**.
- Grouped Collection / Figma DS regression: **PASS 27/27**.
- Inventory Valuation end-user behavior: **PASS 54/54**.
- Inventory Valuation integration chain: **PASS 14/14**.
- Review workbench fit: **PASS 3/3**.
- JavaScript syntax: **PASS** (`app.js`, `workbench-data.js`).
- Visual review: **PASS** — all 41 canonical first-view screens reviewed through three contact sheets; BJ03 empty evidence sheet and BJ07 verification sheet reviewed separately.

## Behavior regression

The v3.0.1 gate compares the declared screen/state/action topology against **v3.0.0** and confirms it is unchanged. It also checks key runtime invariants, including BJ03 valuation selection not mutating pending received quantity before commit and BJ13 foreign-currency accounting-rate behavior remaining available after the terminology cleanup.

Two historical scripts are not release gates because their assertions are stale rather than indicating a v3.0.1 regression: `business_regression_v143.py` already fails on the v3.0.0 parent due to a hard-coded obsolete quantity, and `inventory_valuation_scenarios_v150.py` expects the old capitalization **“Tỷ giá Kế toán”**. The replacement v3.0.1 checks validate the actual invariants and pass.

## UX lock carried forward

Use the lightest canonical DS composition that makes business hierarchy obvious. A List Row icon must earn its space; do not repeat the task title as a redundant large section heading; do not expose implementation/revision vocabulary to end users; and do not invent a feature component when existing DS components and composition already express the responsibility.
