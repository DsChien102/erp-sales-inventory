# Figma DS Working Freeze — v2.3.0

## Authority

1. Product documents/BJ/UC/BC decide business purpose, actor, permissions, branches, finality, mutation and edge cases.
2. Figma Design System decides canonical component, pattern, template, token, icon, spacing, typography, state-expression and interaction convention.
3. HTML is implementation/verification, not a design source.
4. Reuse eligibility is not determined by a `V` prefix.

## Freeze meaning

`WORKING_FREEZE_THEME7_CANONICAL_SURFACE` means the reusable DS dependency surface required by the current Theme 7 migration is clear enough to instantiate without ambiguity. It is intentionally narrower than the v2.2.0 global `FROZEN_RUNTIME_EXACT` target.

This release therefore permits UIF migration while keeping unrelated/open DS items explicitly deferred. It does not rewrite history: the v2.2.0 exact-runtime reports remain valid evidence of their stricter global gate.

## Canonical Theme 7 subset

### Foundations / Icons
- semantic variables and canonical typography/spacing/radius contracts;
- approved VET45 icon registry is the Product source;
- raw Lucide vendor area is not a direct Product UI source.

### Components used by BJ08
- `VAppBar`
- `VButton`
- `VSelect`
- `VDatePicker`
- `VTextarea`
- `VSearchBar`
- `VBadge`
- `DS v2 / List Row`
- `DS v2 / Info Row`
- `VBanner`
- `VEmptyState`
- `VLoading`
- `VNumericKeypadSheet`

### Patterns used by BJ08
- Search & Filter
- State ownership (full-page / section / inline)
- Sticky Footer
- Confirmation Sheet
- Select Sheet
- keyboard-safe action placement

### Templates used by BJ08
- `Mobile / Nested List`
- `Mobile / Form`
- `Mobile / Detail`
- `Mobile / State` only when the entire screen is a non-content state.

## Explicit exclusions / deferred assets

- Detail Pattern family: under review; BJ08 composes Detail Template + Data Display + State/Interaction.
- Identity Template: excluded from Theme 7 freeze.
- Disclosure / Swipe: under review.
- cross-viewport responsive completion: deferred for the Theme 7 mobile 402 × 874 release.
- Sticky Footer `Layout=Commerce`: non-canonical Core specimen.
- Product/Entity-specific result variants: business specimens, not Core pattern variants.
- VCard Figma master: still a generic DS source gap, but BJ08 does not depend on it; grouped `VSection` + rows are used instead.
- global v2.2.0 icon gaps for other UIFs: do not block BJ08 unless the BJ actually demands those glyphs.

## Known technical normalization

- field instances used in Product mobile must fill their 370 px content container; fixed 421.33 px specimen widths must not propagate into Product UI;
- canonical sheet shell uses `Radius/Sheet = 16px`;
- `VNumericKeypadSheet` Product use requires Mode/Title/Unit/Value to be configurable without detach;
- VToast surface binding remains a global DS cleanup and is not a BJ08 blocker.

## New gap proven by BJ08

`VTimePicker` has no confirmed canonical VET45 Figma master. A third-party/community time picker is not accepted as VET45 DS. v2.3.0 marks the time field as a temporary Product composition and does not claim canonical exactness for it.
