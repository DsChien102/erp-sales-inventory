# UIF-17 — Component Usage Contract

> **Figma DS migration v2.0.1:** `FIGMA-DS-LOCK.json` / live Figma DS v2.0.2 is the current UI authority. Component names/compositions below are preserved as legacy renderer annotations until Phase 3/4; canonical translation is `../figma-ds/html-figma-ds-mapping.json`. Do not use historical Flutter-DS wording as current authority.

> Status: `PRODUCT_CORRECTED_v1.7.0` · Scope: `BJ-17/UIF-17` · Figma DS v2.0.2 is UI authority; legacy Flutter labels are migration inputs only.

## Product rules

1. `UNKNOWN` is displayed as **Chưa xác định**, not as failure.
2. Evidence determines one of: already committed, proven no-commit, or insufficient evidence.
3. Already committed → establish finality without writing inventory effect again.
4. Proven no-commit → continue **the same operation/request identity** and unchanged confirmed content.
5. Insufficient evidence → keep unresolved + scope protected + owner escalation; no blind retry.
6. Product UI never exposes “retry / replay / polling / hash” as a mental task.

## Screen matrix

| Screen | Surface | Product role |
|---|---|---|
| `SCR-078` | UNKNOWN worklist | locate operation requiring finality |
| `SCR-079` | evidence | commit / no-commit / insufficient assessment |
| `SCR-080` | controlled plan | establish completed or continue same identity |
| `SCR-082` | finality review | verify result without duplicate mutation |
| `SCR-083` | result | completed or unresolved escalated |

Components: `VPageScaffold`, `VAppBar(centerTitle=false)`, `VSearchBar`, `VChip`, `VCard`, `VBadge`, `VText`, `VBanner`, `VButton`, `VEmptyState`, `VLoading`.


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
