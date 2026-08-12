# Visual DS Hierarchy QA — v2.9.3

**Result: PASS**

## Review scope

Manual visual review was performed after automated QA against:

- focused correction captures: BJ05/SCR-028, BJ06/SCR-035, BJ07/SCR-037, BJ07 verification sheet, BJ07/SCR-039 and BJ07/SCR-041;
- the full migrated canonical set: **33 screens** across UIF-01, UIF-02, UIF-04, UIF-05, UIF-06, UIF-07 and UIF-08;
- live Figma DS/Patterns references: `List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, Layout / Surface Grouping `4518:1545`, and mature Theme 1 Product composition `267:3444`.

## Findings

- BJ07/SCR-037 now reads as one preparation collection: Product+UOM context is canonical Status/Compact List Row; actionable LOT rows are canonical Navigation/Default rows; per-Product outer cards are removed.
- BJ07/SCR-039 and SCR-041 now use one grouped evidence surface; Product+UOM state is semantic, and LOT quantities are read-only Key-value data rather than badge pills.
- BJ05/SCR-028 now uses one handover collection surface instead of repeated Product cards; editable actual quantities remain canonical fields.
- BJ06/SCR-035 now uses one result collection surface; Product state is semantic and child evidence remains Info Row. A legacy broad `h2` selector that visually promoted a nested section title was corrected to the canonical 16/22 H4 hierarchy.
- BJ01, BJ02, BJ04 and BJ08 were reviewed for the same anti-pattern and retained where their surfaces represent independent units or already follow flat/grouped DS semantics.
- No unintended clipping, serif fallback, root horizontal overflow, or out-of-canvas Product content was observed in the migrated-screen audit.

## Visual rule locked

**Use the lightest DS-valid surface that preserves hierarchy.** `VSection` is structural grouping, not automatically a Card. One homogeneous collection should not create one outer card per repeated Product when canonical rows can express the hierarchy. Component anatomy must remain exact; flattening is performed at the composition/layout layer, never by deforming a Figma component.

Capture references:

- `v293-focused-captures/CONTACT-SHEET.jpg`
- `v293-migrated-all/CONTACT-SHEET.jpg`
