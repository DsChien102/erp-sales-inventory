# UIF-10 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.6.0` · Scope: `BJ-10/UIF-10` · Figma DS v2.0.2 is UI authority; legacy Flutter labels are migration inputs only.

## Product rules

- Entry list contains only non-sellable tenant-owned stock.
- `SCR-040` PREPARE / APPROVAL / APPROVED_PENDING_DISPOSAL / COMPLETION are task-owner modes, not one same-user wizard.
- No visible Save Draft. Missing official/source price basis blocks submit and cannot be bypassed by entering a manual price.
- Approval has zero stock decrement. Only physical completion can invoke `ACT-08-DISPOSE`.
- Actual disposed quantity is authoritative; beyond-policy variance blocks commit and requires new approval. UNKNOWN keeps same operation identity.

## Screen matrix

| Screen | Surface | Visible action(s) |
|---|---|---|
| `SCR-036` | eligible list | none |
| `SCR-037` | detail | contextual request action |
| `SCR-040` | form/review/completion by mode | `ACT-COMMON-SUBMIT` OR `ACT-COMMON-DECIDE` OR `ACT-08-DISPOSE` |
| `SCR-041` | result | none |

Components: `VPageScaffold`, `VAppBar(centerTitle=false)`, `VPagePadding`, `VCard`, `VBadge`, `VText`, `VNumberField`, `VTextField`, `VBanner`, `VButton`, `VEmptyState`, `VSkeleton`, `VLoading`.


## v2.0.2 — Figma DS Phase 3 calibrated expression

This UIF is part of the representative calibration set. The live **Figma Design System v2.0.2** is the UI authority; the older component lists above remain historical migration input only and MUST NOT be used as the current renderer contract.

Current rules:
- Screen shell resolves to the explicit live Mobile template recorded by the runtime mapping.
- `VAppBar` = 56px; mobile content edge = 16px; calibrated page rhythm = 12px where specified by the template.
- Footer actions use `DS v2 / Sticky Footer` (`549:927`) with 92px anatomy and 44px canonical `VButton`.
- Operational navigation/selection rows use `DS v2 / List Row` (`525:519`) rather than a generic clickable `VCard`.
- Read-only facts use `DS v2 / Info Row` (`525:351`) or an explicit token-based `VSection` composition.
- Plain numeric quantity entry uses `VTextField`; `VQuantitySelector` is not a canonical live component and is not used in the calibrated Product renderer.
- State/result surfaces resolve to `Mobile / State` (`551:1746`) where applicable.
- Business behavior, actor handoff, authoritative inputs and UNKNOWN/finality rules are unchanged from the locked Product contracts.

See `../figma-ds/PHASE-3-CALIBRATION-REPORT-v2.0.2.md` for the exact per-screen template mapping and calibration boundary.
