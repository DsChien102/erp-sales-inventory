# CHANGELOG — v2.9.3

Parent: `v2.9.2`

## Changed

- Applied live Figma Layout / Surface Grouping rule `4518:1545`: use the lightest valid boundary and avoid nested/repeated card soup.
- **BJ07 / SCR-037:** removed one outer card per Product+UOM. The collection has one grouped surface; Product+UOM remains exact `List Row / Status / Compact` 370×52 and actionable LOT remains exact `List Row / Navigation / Default` 370×76.
- **BJ07 / SCR-039 + SCR-041:** removed per-Product outer cards. Product state is a semantic Status/Compact row (`Đã kiểm` / `Đã bàn giao`); read-only LOT quantity is canonical `Key-value Row` data, not a quantity badge.
- **BJ07 verification sheet:** quantity is supporting `Info Row` data; the badge expresses verification state only.
- **BJ05 / SCR-028:** flattened repeated Product outer cards into one grouped handover collection. Product summary remains canonical Status/Compact; allocation facts/fields remain canonical 338px DS primitives.
- **BJ06 / SCR-035:** flattened repeated Product result cards into one grouped result collection and corrected a legacy selector that incorrectly promoted a nested section title to H2.
- Added v2.9.3 parity matrix, focused visual review and cross-migrated 33-screen visual audit.

## Unchanged

- Business flows, actor/source ownership, navigation/finality, quantity/UOM boundaries and inventory commit behavior.
- Canonical Product viewport `402×874`; review bezel `418×890`.
- Existing DS component anatomy, variants, tokens and states.
- No new Theme-specific component.
