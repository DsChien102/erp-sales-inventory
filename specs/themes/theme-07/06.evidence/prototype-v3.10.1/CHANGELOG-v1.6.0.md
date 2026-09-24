# CHANGELOG — v1.6.0

Parent: **v1.5.0**. Scope: BJ08–BJ10 Inventory Audit & Control.

## Product corrections

- BJ08: true blind count; post-submit discrepancy reveal; evidence/recount; price-basis blocker; separate maker/approver/cancel; result/UNKNOWN finality.
- BJ09: “Tình trạng hàng” list; business-state whitelist; expiry derived; lock true read-only; approval separated; physical/value preserved.
- BJ10: non-sellable source only; price basis required; approval ≠ disposal; physical completion required; actual-qty guard; same-operation UNKNOWN recovery.
- Removed generic architecture explanation from these Product surfaces through dedicated renderers.

## Cumulative protection

No release-lineage reset: all work is based on v1.5.0. Frozen `theme.manifest.yaml` is untouched. Regression gates include v1.5.0 Inventory Valuation and all non-target UIFs.
