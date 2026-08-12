# Isolation Report — v0.3.2 vs v0.3.1

**Result: PASS**

Rule: v0.3.2 is an incremental BJ-01/UIF-01 correction on cumulative parent v0.3.1. Existing files may change only inside the explicit BJ-01/shared-renderer allowlist; everything else is protected.

## Summary

- Parent files: **657**
- Existing files unchanged: **634**
- Existing files intentionally changed: **23**
- New v0.3.2 review/QA artifacts: **15**
- Deleted parent files: **0**
- Unexpected existing-file changes: **0**
- Changes outside root README + Theme 7 prototype layer: **0**

## Intentional existing-file allowlist

- [x] `README.md`
- [x] `specs/themes/theme-07/prototype/CUMULATIVE-REVIEW-UIF-01.md`
- [x] `specs/themes/theme-07/prototype/README.md`
- [x] `specs/themes/theme-07/prototype/contracts/bj-ui-flow-map.md`
- [x] `specs/themes/theme-07/prototype/contracts/component-usage/UIF-01-COMPONENT-USAGE.md`
- [x] `specs/themes/theme-07/prototype/contracts/component-usage/UIF-01-COMPONENT-USAGE.yaml`
- [x] `specs/themes/theme-07/prototype/contracts/navigation-areas.md`
- [x] `specs/themes/theme-07/prototype/contracts/screen-registry.json`
- [x] `specs/themes/theme-07/prototype/contracts/screen-registry.md`
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-001.md`
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-003.md`
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-004.md`
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-005.md`
- [x] `specs/themes/theme-07/prototype/flows/UIF-01-BJ-01.md`
- [x] `specs/themes/theme-07/prototype/flows/ui-flow-registry.json`
- [x] `specs/themes/theme-07/prototype/html/README.md`
- [x] `specs/themes/theme-07/prototype/html/app.js`
- [x] `specs/themes/theme-07/prototype/html/manifest.json`
- [x] `specs/themes/theme-07/prototype/html/styles.css`
- [x] `specs/themes/theme-07/prototype/html/workbench-data.js`
- [x] `specs/themes/theme-07/prototype/html/workbench-data.json`
- [x] `specs/themes/theme-07/prototype/reviews/CUMULATIVE-REVIEW-UIF-01.md`
- [x] `specs/themes/theme-07/prototype/reviews/LOCAL-REVIEW-UIF-01.md`

## Protected shared/BJ-02 anchors

- [x] `specs/themes/theme-07/prototype/html/index.html` byte-identical
- [x] `specs/themes/theme-07/prototype/html/tokens.generated.css` byte-identical
- [x] BJ-02 runtime suite: 78/78 PASS (see `BJ02-REGRESSION-v0.3.2.md`).
- [x] BJ-02 protected contract/source checks: 19/19 byte-identical.
- [x] BJ-02 workbench flow/screen subtrees: 10/10 identical.
- [x] BJ-02 historical screenshot specimens: 7/7 pixel-identical after isolated runtime replay.

## New artifacts

- `specs/themes/theme-07/prototype/html/CHANGELOG-BJ01-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/BJ01-RUNTIME-QA-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/BJ01-STATIC-QA-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/BJ02-REGRESSION-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/ISOLATION-REPORT-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/VISUAL-QA-v0.3.2.md`
- `specs/themes/theme-07/prototype/html/qa/bj01_runtime_v032.py`
- `specs/themes/theme-07/prototype/html/qa/bj01_validate_v032.py`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/LOT-detail-sheet.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/SCR-001-all.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/SCR-001-low.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/SCR-003-low.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/SCR-003-normal.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v0.3.2/provenance-sheet.png`
- `specs/themes/theme-07/prototype/reviews/BJ01-PHASE-B-REVIEW-v0.3.2.md`

## Conclusion

No BJ-02/UIF-02 redesign or restyle occurred in v0.3.2. Shared renderer changes are additive/scoped to `UIF-01`; BJ-02 runtime and pixel regression confirm the protected baseline remains intact.
