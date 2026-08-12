# BJ01 / UIF-01 Migration Contract — v2.4.4

**Parent:** v2.4.2  
**Business behavior:** unchanged  
**UI authority:** live Figma DS v2.0.3 (`QVJolM5tAdFKkhP7RIwe3y`)  
**Viewport:** 402×874 · edge 16 · content 370

## Component-selection gate

For every UI responsibility, inspect the live DS before composing Product UI:

`semantically valid V_component → semantically valid existing non-V component → existing Pattern/Template → layout-only composition of existing DS assets → new component only after a reusable gap is proven`

A Product-specific component is **not** created merely to name a grouping. A V-prefix is preferred only when the component responsibility is actually correct.

## v2.4.4 correction

`Theme7AvailabilitySummary` is removed from BJ01. Its responsibility is already expressible by existing Data Display assets:

- Primary **Khả dụng** → `DS v2 / Key-value Row` `525:358`, `State=Emphasis`.
- Supporting quantity rows use the same component in `State=Default`, preserving Figma numeric alignment and JetBrains Mono for values.
- Supporting `Tồn vật lý / Đủ điều kiện bán / Đã giữ` → `DS v2 / Key-value Row` `525:358`, `State=Default`.
- The surrounding element is layout-only; it has no Theme7 component identity.

Why this is the correct DS usage:

- live Figma describes Key-value Row `Emphasis` as reserved for **totals or summary outcomes**;
- Khả dụng is the primary derived inventory outcome (`sellable physical quantity − valid reserved quantity`), so this responsibility fits without inventing trend, prose or a new anatomy;
- `DS v2 / Metric Card` would introduce KPI trend/delta anatomy that BJ01 does not own;
- `DS v2 / Summary Card` is title/body prose summary, not this numeric outcome;
- the Figma master for `VCard` is still pending, therefore it is not used as a substitute for a live source component.

## SCR mapping

| Surface | Canonical UI expression |
|---|---|
| SCR-001 shell | `Mobile / Nested List` + `VAppBar` |
| Search | `DS v2 / Search & Filter Header` → `VSearchBar` |
| Quick filters | direct `VChip` instances |
| Product rows | `DS v2 / List Row` |
| SCR-003 shell | `Mobile / Detail` + `VAppBar` |
| Primary availability | `DS v2 / Key-value Row`, `State=Emphasis` |
| Supporting quantities | `DS v2 / Key-value Row`, `State=Default` |
| LOW/OUT attention | `VBanner` |
| LOT/provenance navigation | `DS v2 / List Row` |
| LOT/provenance overlay | `VBottomSheet` |
| Empty/access/query actions | `VEmptyState` / `VButton` as applicable |

## Hard rules

- One primary availability outcome only; do not repeat it as another metric/card.
- No custom availability card/component.
- No card-per-product list.
- No mutation in BJ01.
- LOT only for LOT-tracked products; no synthetic LOT for NONE.
- As-of context remains visible.
- Protected values are omitted from DOM when unauthorized.
- Exact component anatomy, state, typography, icon sizing and semantic variables are required; component labels alone do not prove compliance.

## v2.4.4 fidelity correction

- The previous Info Row mapping for stock quantities was a semantic mismatch: variable-length labels caused quantity values to drift horizontally and visually collide with labels.
- Quantity summary now uses `DS v2 / Key-value Row` for all four rows: `Emphasis` for Khả dụng, `Default` for Tồn vật lý / Đủ điều kiện bán / Đã giữ.
- Live Figma master width `338px` is preserved and centered inside the `370px` Product content column instead of stretching the component.
- `VBanner` no longer has a forced `min-height: 96px`; brief/default content follows Hug Content behavior while keeping canonical 16px padding, 12px gap, 20px icon, 12px radius and 1px semantic border.
- Search input now fills the remaining VSearchBar width; VChip hit-area pseudo element is correctly anchored to each chip.
- JetBrains Mono is loaded from the same remote font source as Inter; no font files are bundled.
