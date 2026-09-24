# CHANGELOG — BJ01 v0.3.3

Parent: `v0.3.2`.

## Changed
- Replaced BJ01-specific search styling with shared `VSearchBar` renderer.
- Replaced custom filter visual styling with `VChip` renderer usage.
- Introduced semantic `VCard` containers for list/summary/LOT/provenance without returning to card-per-product.
- Replaced custom inline status visual with `VBadge` where status is needed.
- Replaced custom attention block with `VBanner` for LOW/OUT/stale.
- Replaced custom text/action controls with `VButton.secondary`.
- Replaced custom Bottom Sheet shell and close icon with exact shared `VBottomSheet` shell.
- Expanded Screen Component Composition Contracts and UIF01 component usage profile.

## Unchanged
- BJ01 business rules/task architecture from v0.3.2.
- BJ02/UIF02 contracts/renderer behavior.
- `index.html` and `tokens.generated.css`.
- Non-BJ01 UIFs.
