# CHANGELOG — v2.9.2

Parent: `v2.9.1`

## Changed
- BJ07 SCR-037/SCR-039/SCR-041: replaced free-floating Product+UOM `VText + VBadge` headers with canonical `DS v2 / List Row`, `Type=Status`, `Density=Compact`, inside coherent bordered group surfaces.
- BJ07 allocation children retain exact semantics: Navigation List Row during preparation; Key-value Row during handover/result.
- BJ05 SCR-028: replaced ad-hoc product header with the same canonical Product+UOM summary row; allocation header converted to Key-value Row.
- BJ06 SCR-035: replaced free-text result product header with canonical Product+UOM Status/Compact List Row.
- Added a cross-migrated UX rule: canonical DS → Patterns/Templates → mature prior-Theme Product UI reference → HTML; never float arbitrary text+badge when DS already provides the semantic primitive.

## Unchanged
- Business flows, source ownership, quantities/UOM boundaries, navigation/finality rules and actual inventory commit points.
- Canonical Product viewport `402×874`.
- No new Theme-specific component.
