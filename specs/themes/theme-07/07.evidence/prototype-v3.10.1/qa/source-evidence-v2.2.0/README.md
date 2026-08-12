# Figma DS live source evidence — v2.2.0 candidate

This folder records the live-read evidence used by the v2.2.0 preflight. It is evidence only; it does not replace the canonical Figma file.

## Canonical source

- Figma file: `QVJolM5tAdFKkhP7RIwe3y`
- DS version observed live: `2.0.2`
- Foundations & Icons page: `505:5889`
- Components page: `505:5890`
- Patterns & Templates page: `505:5891`
- Canonical Product viewport: `402x874`

## Live facts revalidated

- `VButton` (`521:529`) exposes 48 variants: 4 hierarchies x 4 states x 3 sizes.
- `DS v2 / Icon` (`511:673`) exposes 54 variants: 6 sizes x 9 tones.
- Approved Product Icon Library contains exactly 28 Product-ready icon entries. The raw Lucide frame is vendor source only.
- `VAppBar` (`547:1594`) has Root / Back / Context / Root context types.
- `DS v2 / Sticky Footer` (`549:927`) has 5 variants including Commerce.
- Live variable/style bindings confirm `Label / Small = 12/16 600` and `Mono / Numeric = 14/22 400`.

## Tooling boundary

- Live metadata, variable definitions, screenshots and asset-export URLs are readable.
- Code Connect graph APIs are unavailable on the current Pro plan even with a Full seat; Organization/Enterprise is required by Figma.
- `get_design_context` was not used because its required design-to-code guidance resource is unavailable in the current environment. No anatomy was inferred to compensate.
- Figma asset export URLs are short-lived, while this container cannot resolve `figma.com`; therefore exact SVG bytes have not been committed locally.

## Open freeze gates

1. **G1 — Approved icon coverage:** 7 actually rendered legacy semantics require glyphs absent from the 28-entry approved Product Icon Library.
2. **G2 — Read-only informational sheets:** 4 Product contexts have no canonical read-only Info/Detail Sheet in DS v2.0.2.
3. **G3 — Full anatomy proof:** every demanded component/pattern/template still needs non-inferred exact anatomy evidence.
4. **G4 — Exact icon bytes:** exact approved SVG bytes must be materialized locally before runtime freeze.
5. **G5 — Full runtime visual parity:** the isolated runtime currently represents only a subset of demanded assets/variants.

Until all five gates close, `productWiring=false` and no UIF/BJ migration is allowed.
