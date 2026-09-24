# Isolation / Regression Report v1.6.0

Parent: **VET45 Theme 7 Prototype Harness v1.5.0**  
Target scope: **UIF08 / UIF09 / UIF10 only**.

## Lineage and protected artifacts

- Release v1.6.0 was copied from the uploaded v1.5.0 package before any Product correction.
- Theme 7 SRS directory is byte-identical to v1.5.0 (`diff -qr`: no differences).
- `theme.manifest.yaml` is byte-identical to v1.5.0; SHA-256 on both: `b1f1d5dfee5ac0363384a7276171953747ef14a749ee0c8f5801bb044a605519`.
- Protected Product runtime regression: **PASS · 3/3 gates · 70 non-target screen renders exact**.
- Inventory Valuation regression on the child package remains **PASS**: end-user `54/54`, scenarios `27/27`, integration `14/14`.
- All-flow runtime smoke after v1.6.0 changes: **PASS · 85 active flow/screen renders**.

## Canonical package validator

The frozen package validator currently exits `1` on **both v1.5.0 parent and v1.6.0 child** before prototype validation because `prototype/screen-map.md` is absent. Both runs fail at the same `validate-package.py` line/condition. This is a pre-existing package-baseline issue, not introduced by v1.6.0.

The v1.6.0 release therefore does **not** claim full canonical validator readiness. Release evidence is the targeted/static/runtime/visual/regression suite documented in `INVENTORY-AUDIT-CONTROL-GROUP-QA-v1.6.0.md`.
