# BJ01 + BJ02 — UI / Figma DS corrective contract · v2.5.1

**Parent:** v2.5.0  
**Scope:** corrective patch only; no additional UIF migration.  
**UI authority:** live Figma file `QVJolM5tAdFKkhP7RIwe3y`, pages `505:5889`, `505:5890`, `505:5891`.  
**Business authority:** existing Theme 7 BJ/UC/decision/behavioral/screen contracts; this correction does not invent or supersede business rules.

## Why v2.5.0 was insufficient

The v2.5.0 static/runtime gates proved that screens rendered and that many DS identities were present, but they did not prevent two classes of drift:

1. an inherited/late CSS rule could still visually override a previously corrected Figma component; and
2. BJ02 sometimes used the correct *name* of a DS asset while the Product composition or computed geometry did not match that asset's responsibility/anatomy.

v2.5.1 therefore adds a last-loaded fidelity gate and browser-computed geometry checks.

## BJ01 correction

`DS v2 / Key-value Row` (`525:358`) is restated in the final scoped layer:

- master width/height: `338 × 44`;
- `justify-between`, label/value cannot shrink or wrap into each other;
- all supporting values share one right edge;
- Default: label `Inter 13/20 Regular`, value `JetBrains Mono 14/22 Regular`;
- Emphasis: label `Inter 14/20 SemiBold`, value `Inter 16/22 SemiBold`;
- typography is owned by the Figma variant; there is no global rule that every number uses Mono.

## BJ02 corrections

- SCR-008 Supplier: canonical `VSelect` trigger → `DS v2 / Select Sheet` (`550:1148`) using `VSearchBar` + `List Row / Selection`.
- SCR-008 Warehouse: canonical `VSelect / Disabled`, not `VTextField`.
- SCR-008 evidence: canonical `VFileDropZone` (`522:7507`) remains Default state after selection; filename is content. Leading icon uses approved `li:cloud-upload` slot.
- Sticky Footer: exact `402×92`, `pt=12`, `pb=24`, `px=16`; actions are exactly `44px`; Dual uses `181/8/181`.
- SCR-009 context: flat `VSection` + `Info Row`, no unnecessary Summary Card.
- SCR-084 product identity: flat structural `VSection`, not a feature card.
- SCR-084 four authoritative classifications: explicit `338×44` numeric hit areas composed from `Key-value Row`; editing uses `VNumericKeypadSheet` (`1829:16196`, Quantity specimen `1829:6657`). No four tall VTextFields and no editable total.
- Numeric keypad preserves the existing value until `Lưu`; decimal is disabled for current whole-unit UOM fixtures.
- SCR-010/SCR-011: remove legacy review-card/card soup; use flat `VSection` + `Info Row` / `Key-value Row`.
- Compact VBanner is used only for genuinely short content that fits the canonical 72px density; longer content stays Default.
- No new BJ02 shared component identity is created.

## Release gates

A correction is not complete because `data-ds-component` exists. v2.5.1 requires:

- live Figma responsibility match;
- computed geometry/typography/state checks in Chromium;
- meaningful seeded visual review (not zero-line fixtures);
- browser errors = 0;
- horizontal overflow = 0;
- all-flow smoke regression;
- action/screen registries preserved byte-for-byte from v2.5.0.
