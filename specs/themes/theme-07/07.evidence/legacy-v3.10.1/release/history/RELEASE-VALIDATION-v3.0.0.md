# RELEASE VALIDATION — v3.0.0

Parent: `v2.9.4`  
Status: **PASS — REVIEW READY**

## Scope

Inventory Valuation cluster: **BJ03 + BJ13 + BJ14**. This is a presentation/UX/DS alignment milestone; business behavior, handler semantics and canonical journey topology are unchanged.

## What changed

- **BJ03 — Xác nhận giá trị ban đầu:** Product/UOM is the primary context; LOT/non-LOT + physical state are nested valuation scopes rather than peer cards. Partial quantity stays contextual. Evidence/provenance is a canonical `VBottomSheet`; conflicting sources are not preselected. Review and result reuse the same hierarchy.
- **BJ13 — Chi phí mua đến muộn:** source context, target scope, allocation preview, accounting-period effect and final impact are separated without card soup. One homogeneous collection owns one surface; financial facts use Info/Key-value rows.
- **BJ14 — Tính và công bố giá vốn:** cost runs are visually treated as immutable records; policy method is read-only; the two run-kind options use canonical `VRadio`, not a custom segmented control. Method comparison and blockers each use one grouped surface.
- No new core Design System component was created.

## Figma grounding

Live VET45 Figma Design System (`QVJolM5tAdFKkhP7RIwe3y`) remains UI authority. Primary references used in this release: `List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VRadio 522:7410`, `VSelect 522:7291`, `VBottomSheet 4695:6353`, `VAppBar 547:1594`.

The cluster follows the prior design lesson already locked in Theme 7: parent context is visually stronger than supporting records; Product and LOT/non-LOT are not peer cards; one homogeneous list should not become many independent cards; money/quantity are values, not status badges.

## Business regression

- UIF-03, UIF-13 and UIF-14 click/commit event-handler blocks are byte-for-byte unchanged from v2.9.4.
- Canonical routes remain:
  - BJ03: `SCR-014 → SCR-015 → SCR-017 → SCR-019`; `SCR-016` retired/support only.
  - BJ13: `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`.
  - BJ14: `SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077`; `SCR-075` retired/support only.

## Gates

- Valuation cluster DS/UX gate: **PASS 28/28**, 14 active valuation screens, 0 browser errors.
- Valuation scenarios: **PASS 27/27**.
- Valuation end-user behavior: **PASS 54/54**.
- Valuation integration chain: **PASS 14/14**.
- All-flow runtime: **PASS 85/85 renders**, 0 browser errors.
- Device frame: **PASS 7/7**, 85 screens checked, 0 browser errors.
- Prior-BJ regression: **PASS 23/23**, 0 browser errors.
- BJ07 Product/LOT regression: **PASS 21/21**.
- Review workbench fit: **PASS 3/3**.
- JavaScript syntax: **PASS**.
- Focused visual review: **PASS** at 402×874 for BJ03 queue/scope/evidence/review, BJ13 allocation/review/result, BJ14 run list/setup/calculation/review.

## UX lock carried forward

Use the lightest DS composition that preserves the business hierarchy. Do not explain internal BJ handoffs inside Product UI, do not invent feature-specific components when existing DS primitives cover the responsibility, and do not convert financial/quantity facts into status badges.
