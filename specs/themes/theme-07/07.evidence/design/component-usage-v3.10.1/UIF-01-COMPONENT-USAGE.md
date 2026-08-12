# UIF-01 — Figma DS Component Usage · v2.4.5

> Authority: live Figma DS v2.0.3. Selection order: **semantically valid V_component → existing canonical non-V component → existing Pattern/Template → layout composition of existing DS assets → new component only after proven reusable gap**.

| Surface | Canonical mapping | Why this level is used |
|---|---|---|
| Shell | Mobile / Nested List or Detail + `VAppBar` | V-component used directly for app bar. |
| Search | `DS v2 / Search & Filter Header` `Layout=Search` → `VSearchBar` | Existing canonical composition. |
| Quick filters | direct `VChip` instances in a layout-only row | Matching V-component exists; no Theme7 filter component. |
| Product result | `DS v2 / List Row` `525:519` | Existing component fully owns navigation-row responsibility. |
| Primary availability | **`DS v2 / Key-value Row` `525:358`, `State=Emphasis`** | Existing DS component explicitly owns totals/summary outcomes; no custom Theme7 component is justified. |
| Supporting inventory facts | **`DS v2 / Key-value Row` `525:358`, `State=Default`** | Quantity facts form a comparable numeric summary; Key-value Row keeps values aligned and uses the canonical numeric type. |
| Attention | `VBanner` `526:4215` | Matching V-component exists. |
| LOT row | `DS v2 / List Row` `525:519` | Existing component fits directly. |
| Provenance entry | `DS v2 / List Row` `525:519` | Existing component fits directly. |
| Context overlay shell | `VBottomSheet` `4695:6353` | Matching V-component exists. |
| Empty/access | `VEmptyState` | Matching V-component exists. |
| Query/handoff | `VButton` | Matching V-component exists. |

## Rule lock

- `Theme7AvailabilitySummary` is removed and must not return.
- Inventory quantity summaries must not use `Info Row`; use `Key-value Row` so comparable values share a stable alignment.
- `VBanner` uses content-driven height (Hug Content behavior); do not impose a fixed/minimum 96px height on brief messages.
- Do not create a named Theme/Product component merely to group existing DS components.
- A V-component is checked first; if its semantic responsibility does not match, use the next valid existing DS component rather than forcing the V-component.
- New components are exceptional: require a documented reusable responsibility gap after DS census, not a screen-specific layout preference.
- Typography is owned by the selected DS component/variant, not inferred from content type: `Key-value Row / Default` uses JetBrains Mono for its value; `Emphasis` uses Inter. Do not apply a global “number = Mono” rule.
- Semantic variables, canonical typography, exact anatomy/state and approved icons remain mandatory.

## v3.9.1 current detail expression

- `SCR-003` Product identity is a compact read-only `DS v2 / List Row` context **without trailing badge**.
- Primary `Khả dụng` uses `DS v2 / Key-value Row 525:358`, `State=Emphasis`; quantity is not a status.
- Supporting inventory facts stay `DS v2 / Key-value Row 525:358`. Eligibility reason rows use the same aligned primitive only when quantity > 0.
- LOT detail never shows Product-level `Đã giữ/Khả dụng`; it uses physical/eligible + expiry evidence.
- A fixed `Summary Card 370×112` is not a generic identity primitive. Never add low-value data simply to fill it.
- Cross-theme reference rule: before correcting a Product composition, inspect canonical DS + Patterns/Templates and mature Product UI in other available Figma Themes to align grouping, density and rhythm; DS semantics still override any legacy outlier.
