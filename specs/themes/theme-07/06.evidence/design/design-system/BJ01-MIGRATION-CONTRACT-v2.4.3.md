# BJ01 / UIF-01 Migration Contract — v2.4.3

**Parent:** v2.4.2  
**Business behavior:** unchanged  
**UI authority:** live Figma DS v2.0.3 (`QVJolM5tAdFKkhP7RIwe3y`)  
**Viewport:** 402×874 · edge 16 · content 370

## Component-selection gate

For every UI responsibility, inspect the live DS before composing Product UI:

`semantically valid V_component → semantically valid existing non-V component → existing Pattern/Template → layout-only composition of existing DS assets → new component only after a reusable gap is proven`

A Product-specific component is **not** created merely to name a grouping. A V-prefix is preferred only when the component responsibility is actually correct.

## v2.4.3 correction

`Theme7AvailabilitySummary` is removed from BJ01. Its responsibility is already expressible by existing Data Display assets:

- Primary **Khả dụng** → `DS v2 / Key-value Row` `525:358`, `State=Emphasis`.
- Supporting `Tồn vật lý / Đủ điều kiện bán / Đã giữ` → `DS v2 / Info Row` `525:351`.
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
| Supporting quantities | `DS v2 / Info Row` |
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
