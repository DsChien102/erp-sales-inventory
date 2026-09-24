# UIF-01 — Cumulative Review v0.3.3

> Parent `v0.3.2`; only BJ01/UIF01 + minimum shared renderer metadata is in scope. BJ02/UIF02 and non-BJ01 artifacts remain protected.

## Architecture retained
- `SCR-001`: one inventory list.
- `SCR-003`: canonical detail.
- `SCR-004/005`: contextual Bottom Sheets.
- Deep trace handoff BJ15.

## Correction in this round
v0.3.2 simplified information hierarchy correctly but still rendered several visible controls/surfaces with BJ01-specific HTML visual patterns. v0.3.3 recomposes them using the locked Flutter DS:
- exact shared `VSearchBar` instead of custom search shell;
- `VChip` instead of custom filter-chip visual definition;
- `VCard` as semantic surface container without returning to card-per-product;
- `VBadge` for compact status;
- `VBanner` for persistent LOW/OUT/stale attention;
- `VButton.secondary` for query/handoff actions;
- exact `VBottomSheet` shell, no custom close icon.

## Isolation
No BJ02 redesign/restyle is allowed. `tokens.generated.css` and `index.html` remain protected; shared `app.js/styles.css` changes must be UIF01-scoped and BJ02 runtime regression must pass.
