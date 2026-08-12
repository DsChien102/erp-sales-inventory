# Theme 7 — Exact Figma DS Source Readiness v2.1.2

> **Historical note (superseded by v2.2.0 live preflight):** this report established source indexing readiness. The stricter v2.2.0 audit corrected icon-governance interpretation and introduced runtime-freeze gates before any UIF migration.


## Decision

**READY to begin real UIF/BJ migration.**

This readiness statement applies to the **Design System source and migration infrastructure**, not to the current Product DOM. No UIF/BJ is claimed migrated in v2.1.2.

## Locked live source

- Figma file: `QVJolM5tAdFKkhP7RIwe3y`
- DS version: **2.0.2**
- Figma `Last updated`: **26 August 2026**
- Foundations & Icons: `505:5889`
- Components: `505:5890`
- Patterns & Templates: `505:5891`

## Exact inventory

- Variables: **4 collections / 119 variables**
  - Color Primitive: 39 · Base
  - Color Semantic: 44 · Light
  - Dimension: 30 · Base
  - Opacity: 6 · Base
- Styles: **15 text / 21 paint / 4 effect / 0 grid**
- Icon wrapper: `DS v2 / Icon` `511:673` · **54 variants**
  - sizes: 16 / 20 / 24 / 32 / 48 / 72
  - tones: Primary / Secondary / Muted / Brand / Success / Warning / Danger / Info / Inverse
  - disabled is `Opacity/Disabled = 0.4` on the parent; it is not an icon tone.
  - glyph source must resolve to a Figma `li:*` Lucide component.
  - full exposed Lucide source catalog: **1,676 exact `li:*` sources** = 1,514 remote main components + 162 local components; live catalog signature `c5105795`.
  - exact SVG bytes are exported/downloaded from Figma on demand for the glyphs actually used; the package must never redraw or approximate them.
- Components page: **49 Component Sets + 15 standalone Components = 64 canonical assets**.
- Patterns/Templates page: **10 Component Sets + 12 standalone Components = 22 canonical assets**.

## Parity signatures captured from live Figma

The source lock stores both full-definition and local-schema-normalized signatures. Normalized signatures are executable against the checked-in exact mirror.

| Layer | Live signature |
|---|---:|
| Variables · full | `027dd249` |
| Variables · CSS-normalized | `62680604` |
| Text styles · full | `e1352aec` |
| Text styles · normalized | `2cf9e062` |
| Paint styles · full | `60a9a541` |
| Paint styles · normalized | `c9956865` |
| Effect styles · full | `12a169c3` |
| Effect styles · normalized | `5a57253f` |
| DS Icon wrappers | `ebd6e207` |
| Full exposed `li:*` catalog | `c5105795` |
| Local `li:*` component subset | `3136211b` |
| Components · full structure | `ce8775fc` |
| Components · tuple registry | `c9009f3d` |
| Patterns/Templates · full structure | `560ffa37` |
| Patterns/Templates · tuple registry | `2920e1e0` |

## Exact local source layer now available

- `FIGMA-DS-SOURCE-LOCK.json` — authoritative source identity + signatures.
- `figma-variable-manifest.exact.json` — all 119 variables, exact official WEB syntax and exact values/aliases.
- `html/figma-ds.exact.css` — **119 exact `--vet45-v2-*` definitions**. These are the names from Figma `codeSyntax.WEB`, not locally invented aliases.
- `figma-style-manifest.exact.json` — style IDs and canonical values/bindings.
- `html/figma-ds.styles.exact.css` — exact typography/elevation implementation values.
- `figma-icon-registry.json` — exact 54 wrapper variants and icon governance.
- `FIGMA-DS-ICON-SOURCE-LOCK.json` — full 1,676-glyph Lucide source-catalog identity/signature + exact asset-materialization policy.
- `figma-icon-source-catalog.json` — exact `li:*` sources already referenced by canonical Components/Patterns/Templates.
- `figma-component-registry.json` — exact IDs/names/sections for all 64 Component assets.
- `figma-pattern-template-registry.json` — exact IDs/names/sections for all 22 Pattern/Template assets.
- `UIF-MIGRATION-STATUS.json` — explicitly prevents semantic mapping from being mistaken for implementation.

## Critical implementation boundary

The checked-in registries are a **source index**, not a replacement for reading Figma. Before implementing any canonical Component/Pattern/Template, the implementation step must read that exact node from live Figma with `get_design_context` and reproduce its anatomy, variants, states, tokens, icons and layout in the target HTML stack.

`data-figma-node="..."` alone is never accepted as migration evidence.

## Current Product status

All **17 UIFs remain `LEGACY_NOT_STRUCTURALLY_MIGRATED`** in v2.1.2. `app.js` and `styles.css` are byte-identical to v2.1.1. The new exact Figma CSS source layers are loaded before the transitional legacy adapter, and **85/85 active flow/screen Product renders are pixel-exact to v2.1.1**.

This is intentional: v2.1.2 prepares the correct DS source layer without silently altering business screens.

## Readiness gate

`qa/FIGMA-DS-SOURCE-READINESS-v2.1.2.md`: **PASS · 31/31 gates**.

`qa/SOURCE-READINESS-VISUAL-REGRESSION-v2.1.2.md`: **PASS · 85/85 active Product renders pixel-exact to v2.1.1**, proving readiness work did not silently change UIF/BJ UI.

`qa/FIGMA-DS-MIGRATION-DEMAND-v2.1.2.md`: **497 registered state renders inventoried across all 17 UIFs** for migration planning.
