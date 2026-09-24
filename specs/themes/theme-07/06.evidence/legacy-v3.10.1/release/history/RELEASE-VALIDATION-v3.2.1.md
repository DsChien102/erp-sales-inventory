# Release Validation — VET45 Theme 7 Prototype Harness v3.2.1

## Release intent

Correct the UI-composition defects identified after v3.2.0 without changing business behavior: remove non-DS count/recount card treatment, restore a clear Product→context hierarchy, fix the same Product→LOT peer-card problem in BJ07, and eliminate partially clipped `VChip` filters.

## Authority

- Business: BJ/UC/Decision/Behavioral/UI contracts.
- UI: live Figma Design System in `QVJolM5tAdFKkhP7RIwe3y`.
- HTML: implementation and verification artifact only.
- No new Design System component or feature-specific component family is introduced in v3.2.1.

## Design correction

### BJ08 — count / recount

The rejected treatment used a custom Product card followed by another bordered surface for count facts/quantity. This created card-on-card hierarchy, duplicated visual containers, and made the editable field appear detached from Product context.

v3.2.1 uses existing DS responsibilities only:

- Product identity/status → `DS v2 / List Row`.
- Read-only book/first-count/variance facts → `DS v2 / Key-value Row`.
- Editable quantity → canonical quantity field + numeric keypad sheet.
- Layout → one grouped surface with flat subordinate content; layout wrappers are not declared as DS components.

### BJ07 — Product → LOT

Product remains the parent row. LOT/non-LOT child records are flat subordinate List Rows with dividers inside the same grouped surface. Rounded peer-card styling is removed from child rows.

### VChip

Dense Audit & Control filters use complete canonical `VChip` instances and wrap when necessary. A partially visible chip is explicitly rejected by the QA gate.

## Locked anti-pattern gate

The release rejects:

- per-product custom count/recount cards;
- card-on-card fact/input composition;
- Product and LOT/scope rendered as visually equal peer cards;
- decorative leading icons without semantic value;
- partially clipped chips;
- redundant headings that only rename the obvious list below them.

The rule is persisted in `specs/themes/theme-07/prototype/html/DS-CONFORMANCE.md` for subsequent work.

## Automated validation

`qa/audit_control_composition_v321.py` → **16/16 PASS**.

Validated invariants:

- v3.2.1 cumulative from v3.2.0;
- correction stylesheet loaded after v3.2.0 layers;
- legacy count-card helper absent from the base renderer;
- redundant heading regressions absent;
- canonical chip treatment present;
- BJ07 flattening treatment present;
- **269/269 Audit & Control states** render at 402×874 without root/content horizontal overflow;
- **497/497 cumulative Theme 7 states** render cleanly;
- **0 browser errors**;
- Audit & Control screen/state/action topology unchanged from v3.2.0;
- BJ08 Product context uses canonical List Row and recount facts use canonical Key-value Row;
- every BJ09 state-filter chip is completely visible;
- BJ07 child LOT rows no longer render as peer cards.

Evidence: `specs/themes/theme-07/prototype/html/qa/AUDIT-CONTROL-COMPOSITION-QA-v3.2.1.json`.

## Visual validation

Focused captures reviewed:

- BJ08 `SCR-044` blind count;
- BJ08 `SCR-045` recount required;
- BJ09 `SCR-036` dense state filters;
- BJ07 `SCR-037` Product→LOT preparation hierarchy.

Whole-cluster representative contact sheet: `qa/v321-audit-control-captures/AUDIT-CONTROL-CONTACT-SHEET-v3.2.1.png`.

## Release decision

**PASS — review ready.**
