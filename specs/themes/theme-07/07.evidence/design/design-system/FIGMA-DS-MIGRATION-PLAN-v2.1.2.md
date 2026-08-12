# Theme 7 — Figma DS Real Migration Plan

## Objective

Replace the legacy HTML UI implementation in all 17 UIF/BJs with the **actual Figma DS v2.0.2 Component → Pattern → Template system**, while preserving the already-correct business behavior/state model.

This plan deliberately separates **source exactness** from **Product implementation exactness**.

## Non-negotiable migration gate

A Product construct is marked `MIGRATED_EXACT` only when all five gates pass:

1. **Source gate** — exact Figma node is read live; node ID and allowed variants/states are recorded.
2. **Structure gate** — DOM/component anatomy implements the canonical Figma asset/pattern, not a legacy wrapper with a Figma label.
3. **Foundation/Icon gate** — only exact `--vet45-v2-*` variables/styles and exact `DS v2 / Icon` + `li:*` glyph sources are used. The source glyph is identified by the exact live Figma component key, then exact SVG bytes are exported/downloaded and committed locally. No hand-authored SVG path, no name-only substitution, and no new raw color/spacing/radius/shadow convention.
4. **Visual gate** — 402×874 Product screenshot is visually compared against the Figma source/specimen and passes layout, typography, spacing, states, icon size/stroke/tone and safe-area checks.
5. **Behavior gate** — all existing BJ/UIF business, permissions, actor handoff, UNKNOWN/recovery, read-only and commit semantics still pass.

No gate can be replaced by `data-figma-node`, Inspect metadata or static mapping.


## Release-boundary rule: do not mix DS runtime construction with UIF migration

For maximum reviewability and to prevent another false-positive “migration complete” state, the shared Figma DS runtime must be frozen **before** the first UIF/BJ is structurally replaced.

- **v2.1.2** = exact live-Figma source lock/readiness only; Product UIF DOM unchanged.
- **v2.2.0** = exact HTML Figma DS runtime mirror + standalone specimens + source/visual parity; still **no UIF/BJ replacement**.
- **v2.3.0** = first structural UIF/BJ pilot, consuming only the frozen v2.2.0 runtime.

Every later release begins with a **DS drift preflight**: re-read DS version/date and recompute the locked source signatures. If any canonical source changes, stop migration, update the source lock/runtime mirror first, revalidate specimens, and only then continue Product migration.

## Optimal execution strategy

### Stage 1 — Build the shared exact runtime layer first

Do **not** start by rewriting 73 screens independently. Implement reusable Figma DS runtime assets in demand order, in a separate `figma-ds-runtime/` layer, and validate each asset in a standalone specimen before wiring it into a UIF.

Demand across the current 497 states shows the highest-leverage order:

1. **Foundations + primitives** — typography, exact icon wrapper/source resolver, semantic variables, spacing/radius/elevation. The icon resolver is locked against the full **1,676-source** Figma Lucide catalog (`c5105795`) and materializes only exact glyphs actually used by Product UI.
2. **Global shell/templates** — `VAppBar`, mobile status/safe-area anatomy, Root List / Nested List / Detail / Form / State / Search & Select templates.
3. **Read-only/data display** — `DS v2 / Info Row`, `DS v2 / List Row`, `VBadge`, `VChip`, Summary/Record/Timeline surfaces.
4. **Actions** — `VButton`, Icon Button, Link, `DS v2 / Sticky Footer`.
5. **Feedback/status** — `VBanner`, `VEmptyState`, Loading, Skeleton, Toast.
6. **Inputs/selection** — TextField, Textarea, MoneyField, Select, SearchBar, DatePicker, Checkbox, Radio, Switch, FileDropZone.
7. **Patterns/overlays** — Search & Filter Header, Search Results Dropdown, Confirmation/Action/Select/Filter/Form Sheet, Keyboard-safe Action Bar, Toast Layer, Loading Overlay.

Why this order: shell/text/icon/info-row appear in essentially every UIF; building them once removes the largest amount of duplication and prevents 17 divergent interpretations of the same Figma master.

### Stage 2 — Structural pilot across archetypes

Migrate a small set of UIFs that collectively exercise the whole system before broad rollout:

- **UIF-01 / BJ01** — Root/Nested List + chips + list rows + detail/read-only.
- **UIF-15 / BJ15** — dense inquiry/report + read-only metadata + filters.
- **UIF-02 / BJ02** — search/select + multi-field form + product rows + approval handoff.
- **UIF-08 / BJ08** — count/form/review + approval + state surfaces.
- **UIF-10 / BJ10** — destructive flow + confirmation + actor handoff.
- **UIF-17 / BJ17** — UNKNOWN/recovery + state/detail patterns.

These are not “visual samples”. Every migrated screen/state in those UIFs must use the new exact runtime DOM.

### Stage 3 — Cumulative rollout by dependency/risk group

After the pilot is frozen, continue cumulatively:

- **Wave A — Inventory Operations:** UIF-03, UIF-04, UIF-05, UIF-06, UIF-07.
- **Wave B — Audit & Control:** UIF-09, UIF-11, UIF-12.
- **Wave C — Valuation:** UIF-13, UIF-14.
- **Wave D — Correction/Recovery:** UIF-16.

UIF-01/02/08/10/15/17 are already completed by the pilot stage. Every child version uses the previous migrated version as parent; no rebase to pre-migration HTML.

### Stage 4 — Legacy purge

Only after all 17 UIFs pass:

- remove legacy hand-authored SVG `icons`/`dsIconMap` from Product execution;
- remove Product dependency on `--v-*` and `--figma-*` compatibility aliases;
- remove legacy `choice-card`, `review-card`, generic card/field wrappers when their responsibility is covered by Figma DS;
- keep business-specific composition only where no DS component/pattern owns that responsibility;
- keep workbench/Inspect styling isolated outside Product UI.

### Stage 5 — Final 497-state conformance and freeze

Required final evidence:

- 17/17 UIF `MIGRATED_EXACT`;
- 73/73 canonical screens structurally migrated;
- 497/497 registered states runtime PASS;
- 0 Product raw color/spacing/radius/shadow values outside explicit DS-gap allowlist;
- 0 hand-authored Product SVG glyphs;
- 0 migrated Product dependency on legacy `--v-*` aliases;
- exact component/pattern/template node trace for every reusable Product construct;
- full visual review at 402×874;
- business regression suites unchanged or improved;
- Product approval remains explicit and separate from Engineering QA.

## Versioning recommendation

- **v2.1.2** — exact Figma DS source-readiness (current; no UIF replacement).
- **v2.2.0** — shared exact HTML runtime mirror for Figma DS + standalone specimens; **no UIF replacement yet**.
- **v2.3.0** — structural pilot begins: UIF-01/02/08/10/15/17.
- Continue cumulative patch releases within v2.3.x while completing the pilot. Use a new minor for each frozen migration wave thereafter, not merely because files changed.

This gives small reviewable diffs while preserving the cumulative-version rule.
