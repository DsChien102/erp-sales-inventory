# Theme 7 — Figma DS Component Usage Profile

> **UI authority:** live Figma Design System v2.0.3 in `VET45-Mobile-App` (`QVJolM5tAdFKkhP7RIwe3y`). Product/BJ/UC/contracts decide business behavior; Figma DS decides UI expression; HTML is implementation/verification only.

## Component-selection priority

This order is mandatory for every Theme 7 Product surface:

1. **Canonical `V*` component first** — when a live V-component satisfies the exact responsibility without semantic distortion.
2. **Existing canonical non-V Figma component second** — only when no suitable V-component exists for that responsibility.
3. **Existing Pattern / Template composition** — for structural or interaction responsibility; compose from canonical lower layers rather than inventing a component.
4. **Layout composition of existing DS assets** — ordinary layout/grouping may compose canonical components without creating a named Theme/Product component.
5. **Create a new component last** — only after a proven reusable responsibility gap. A screen-specific grouping is not gap proof; business-specific UI stays ordinary Product UI unless cross-screen/cross-domain reuse and ownership are demonstrated.

`V` is therefore a **preference among semantically valid candidates**, not permission to force an ill-fitting V-component over the correct responsibility.

## Shared usage locks

- Screen shell: select the canonical Mobile template from task architecture; `VAppBar` owns the app bar.
- Actions: `VButton` before any custom button shell.
- Search: `VSearchBar`; use Search & Filter Header only as the existing composition around canonical controls.
- Status/filter: `VBadge` / `VChip` before custom pills.
- Feedback/state: `VBanner`, `VEmptyState`, `VLoading`, `VToast` when their responsibility matches.
- Generic mobile sheet shell: **`VBottomSheet` (`4695:6353`)** before any custom Theme7 sheet shell.
- Numeric transactional sheet: `VNumericKeypadSheet` where its specialized interaction applies.
- If no V-row exists, `DS v2 / List Row` and `DS v2 / Info Row` are valid second-tier canonical choices.
- Approved VET45 icon registry only; no raw Lucide Product usage.
- Semantic variables/text styles first; do not recreate typography, spacing, radius, state or icon conventions locally.

## Governance

A UIF may compose business content, but it may not redefine a canonical component. **Do not promote a layout grouping to a named Theme/Product component by default.** A `data-theme-component` marker requires a proven reusable Product responsibility that is not already represented by existing DS assets. If existing components plus ordinary layout fully represent the UI, use them directly.
