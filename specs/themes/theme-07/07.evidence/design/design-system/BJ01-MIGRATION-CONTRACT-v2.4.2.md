# BJ01 / UIF-01 Migration Contract — v2.4.2

## Scope

Cumulative correction on v2.4.1. Business behavior is unchanged. This version closes the **component-selection priority** gap exposed after BJ01 visual fidelity review.

## Mandatory selection order

`matching V-component → existing canonical non-V component → existing Pattern/Template composition → Product composition → new component only after proven reusable gap`

Semantic fit remains mandatory: an unrelated V-component must never be chosen merely because its name starts with `V`.

## BJ01 audit result

| Responsibility | v2.4.1 | v2.4.2 disposition |
|---|---|---|
| App bar | `VAppBar` | KEEP — correct tier 1 reuse. |
| Search | `VSearchBar` inside Search & Filter Header | KEEP — correct tier 1 + existing pattern. |
| Filter | `VChip` | KEEP — correct tier 1 reuse. |
| Status | `VBadge` | KEEP — correct tier 1 reuse. |
| Feedback | `VBanner` | KEEP — correct tier 1 reuse. |
| Empty/access | `VEmptyState` | KEEP — correct tier 1 reuse. |
| Query/handoff actions | `VButton` | KEEP — correct tier 1 reuse. |
| Context sheet | custom `Theme7ContextSheet` shell | **REPLACE with `VBottomSheet` `4695:6353`** — v2.4.1 violated V-first reuse. |
| Quick-filter/list/identity layout wrappers | Theme7 identity markers around direct DS content | **REMOVE component identity**; ordinary layout wrappers are sufficient. `VChip`/`VText`/List Row remain direct owners. |
| Product/LOT/provenance row | `DS v2 / List Row` plus Theme7 row identity marker | KEEP List Row, **remove redundant Theme7 component identity**; no live `VListRow` exists. |
| Supporting metadata | `DS v2 / Info Row` | KEEP — no live `VInfoRow` exists. |
| Availability summary | Product composition | KEEP with justification; no existing V/non-V component matches its exact information responsibility. |

## VBottomSheet exact live source

Live Figma node `4695:6353` is canonical and exposes:

- width 402;
- top padding 12, horizontal padding 16, bottom safe-area padding 44;
- vertical gap 12;
- handle 48×4;
- optional title using H3 18/24 Semi Bold;
- arbitrary content slot;
- actual master top radius **20px**.

The current Foundation alias `Radius/Sheet=16` conflicts with the actual VBottomSheet master. BJ01 follows the **actual component master geometry** for component fidelity and records the DS inconsistency rather than silently normalizing the component to 16px.

## Product composition guard

`Theme7AvailabilitySummary` is allowed only as Product UI composition. `DS v2 / Metric Card` adds a trend/delta responsibility; `DS v2 / Summary Card` is title/body summary; neither represents the BJ01 availability breakdown correctly. Therefore creating a Product composition is preferable to misusing an existing component.
