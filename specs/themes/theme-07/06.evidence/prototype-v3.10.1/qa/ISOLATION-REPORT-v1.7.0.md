# Isolation / Regression Report v1.7.0

Parent: **VET45 Theme 7 Prototype Harness v1.6.0**  
Target scope: **UIF11 / UIF16 / UIF17 only**.

## Lineage and protected artifacts

- Release v1.7.0 was built directly from the uploaded/canonical v1.6.0 package.
- Theme 7 SRS: **106 files**, byte-identical to v1.6.0 by SHA-256.
- `theme.manifest.yaml` is byte-identical to v1.6.0; SHA-256 on both: `b1f1d5dfee5ac0363384a7276171953747ef14a749ee0c8f5801bb044a605519`.
- Protected Product runtime regression: **PASS · 3/3 gates · 68 non-target screen renders exact**.
- Prior-cluster interaction regression on the child:
  - Inventory Valuation: **54/54 end-user + 27/27 scenario + 14/14 integration PASS**.
  - Inventory Audit & Control: **48/48 end-user + 53 state renders PASS**.
- All-flow runtime smoke after v1.7.0 changes: **PASS · 85 active flow/screen renders**.
- JavaScript syntax: **PASS** (`node --check app.js`).

## Canonical package validator

The frozen package validator exits `1` on **both v1.6.0 parent and v1.7.0 child** at the same pre-existing condition: `prototype/screen-map.md` is absent. In both runs, `validation/validate-package.py` raises `FileNotFoundError` before later package/prototype checks can run.

This is a package-baseline mismatch inherited from the parent, not a new v1.7.0 regression. v1.7.0 therefore **does not claim full canonical validator readiness**. Release evidence is the focused static/runtime/visual/regression suite documented in `CORRECTION-RECOVERY-GROUP-QA-v1.7.0.md`.
