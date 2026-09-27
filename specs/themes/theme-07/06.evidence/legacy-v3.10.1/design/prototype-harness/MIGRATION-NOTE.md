# Prototype Structure Migration

Canonical prototype artifacts now live under:

- `prototype/flows/` (moved from `ui/flows/`)
- `prototype/contracts/`
- `prototype/contracts/component-usage/`
- `prototype/contracts/screens/` (replaces `ui-contracts/screens/`)
- `prototype/html/`

The former `ui/` and `ui-contracts/` directories are intentionally absent from this Harness package to prevent dual sources. Historical migration documents may still mention their old paths.

## Integrity manifests

The original Theme 7 integrity files outside `prototype/` belong to the pre-Harness / DR1 baseline and are retained for historical traceability. They are not the integrity authority for this restructured package.

For the current Harness workspace, use `prototype/HARNESS-CHECKSUMS.sha256` together with `prototype/HARNESS-VALIDATION.json`.
