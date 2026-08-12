# Figma DS Live Preflight QA — v2.2.0

## Decision

**NOT YET 100% FREEZE-READY.** Live Figma access is restored and the source mirror is materially stronger, but three source/contract gates and two evidence gates remain open. No Product UIF/BJ has been rewired.

## What is now reconfirmed live

- Figma DS: v2.0.2, pages `505:5889` / `505:5890` / `505:5891`.
- Canonical mobile frame contract: **402×874**; mobile edge 16; touch target ≥44.
- `DS v2 / Icon` wrapper: 6 sizes × 9 tones = **54 variants**.
- VButton: **48 variants** (Primary/Secondary/Tertiary/Danger × Default/Pressed/Disabled/Loading × Small/Default/Large).
- Live bindings reconfirm semantic color, spacing, radius and typography values on high-demand masters including VButton, VTextField, List Row, Sticky Footer, VBanner, Search & Filter Header and DS v2 / Icon.
- Typography discrepancies are resolved in favor of live bound styles: `Label / Small = 12/16`, `Mono / Numeric = 14/22`.

## Exact source classifications

- Canonical component/pattern/template nodes remain indexed locally.
- `VText`, `VPagePadding` and similar primitives resolve to Foundations rather than fake component masters.
- `VAppBarTitle`, `VEmptyTitle`, etc. are owned slots, not standalone components.
- `VChoiceList`, `VNumberField`, `VTextFormField`, `VDatePickerField`, `VSegmentedButton` must be structurally normalized to canonical lower-layer assets; legacy names must disappear from migrated Product DOM.
- `VPageScaffold` is contextual: every screen must use its actual Root List / Nested List / Detail / Form / Wizard / Search & Select / State template rather than a generic scaffold identity.
- Generic naked `VBottomSheet` is not a canonical target.

## Open gates

### G1 — Approved icon library

The approved Product Icon Library contains **28** entries. The raw `Lucide Icons` area is a vendor source pool, not direct Product authority. The 497-state demand audit found seven actually-rendered legacy semantics with no approved Product glyph yet. These must be added/approved in Figma DS or the Product design must be changed to an already-approved semantic.

### G2 — Read-only informational sheet

UIF-01, UIF-03 and UIF-15 contain read-only informational/detail bottom-sheet interactions. Figma DS v2.0.2 has Action/Confirmation/Select/Filter/Form Sheet and VModal, but no canonical Info/Detail Sheet. A source decision is required before 1:1 migration.

### G3 — Full anatomy proof

Current tooling can read metadata, variable definitions and screenshots. Code Connect bulk graph is unavailable on the current Pro plan, and the design-context guidance resource required by the design-context tool is not available in this environment. Therefore missing internal anatomy must not be guessed.

### G4 — Exact icon bytes

Exact SVG byte materialization for all approved demanded glyphs is not complete in the local runtime. The current legacy SVG registry remains forbidden for migrated UI.

### G5 — Visual parity

The isolated runtime has only a subset of demanded assets/variants. It is a proof workspace, not yet a full visual mirror.

## Migration start condition

Do not begin UIF replacement until G1–G5 are closed and v2.2.0 is explicitly marked **FROZEN_RUNTIME_EXACT**. Product wiring must remain OFF until the next cumulative release.
