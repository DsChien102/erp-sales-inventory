# Changelog — Theme 7 Prototype Harness v3.7.0

Parent: **v3.6.4**  
Date: **2026-09-15**

## Integrated VET45 navigation + full Theme 7 workbench mode

- Adds a second workbench mode while preserving the existing review workflow:
  - **Theo BJ / UIF** — existing screen/flow review mode, unchanged.
  - **Toàn Theme 7** — integrated app-style navigation that starts from **Thêm → Kho**.
- Adds a Product UI **Thêm** screen modeled on the supplied VET45 navigation context. In this Theme 7 package, **Kho** is the enabled module entry; surrounding non-Theme-7 modules remain homogeneous `DS v2 / List Row · Type=Navigation` rows in canonical `State=Disabled` with chevrons retained.
- Adds a Theme 7 **Kho** module root organized by user task rather than BJ numbering. It exposes all **17 Business Journeys + CAP-01** as **18 reachable entries** across overview, operations, valuation/costing, audit/control, reporting, and related/setup groups.
- The integrated mode **reuses the same shared screen renderers and runtime state** as BJ/UIF mode. No second copy of business screens or state machines is created.
- Entering a journey from the Kho module root sets the existing `activeFlowId` and first screen for that flow. The first screen gets a deterministic integrated-mode **Back → Kho** behavior; internal Back behavior after that remains the original flow behavior.
- `UIF-04 — Giữ hàng` is surfaced in the full-theme review root for end-to-end reachability, while its underlying business semantics remain contextual to the sales/order domain.
- `CAP-01 — Chính sách tồn & cận hạn` is surfaced in the full-theme review root for reachability. This does **not** close the existing production IA/open-entry question represented by `BG-006`; the review harness does not replace product-source decisions.
- Inspector/sidebar adapt to app-level root screens without leaking review tooling into the 402×874 product viewport.
- No business rule, permission rule, transaction finality, business state-machine, or existing BJ/UIF screen destination is changed.

## QA

- Integrated Theme 7 navigation: **16/16 PASS**, all **18 entries** reachable, deterministic return to Kho, **0 browser errors**.
- Static consistency: **41/41 PASS**.
- Radio/helper DS: **9/9 PASS**, all **518 declared route-state renders** scanned.
- List Navigation State: **15/15 PASS**, all **518 declared route-state renders** scanned.
- List/Card Rhythm: **9/9 PASS**, independent-card collisions **0**.
- Footer Action: **11/11 PASS**.
- Semantic flow/logic E2E: **21/21 PASS**.
- Full Theme completion: **14/14 PASS**.
- Representative coherence: **8/8 PASS**.
- Runtime UI: **14/14 PASS**, **518 declared states**.
- All-flow runtime smoke: **89/89 route renders PASS**, failures **0**, browser errors **0**.
- Device frame: **7/7 PASS**, canonical product canvas remains **402×874**.
- Current package validation: **17/17 PASS**.
