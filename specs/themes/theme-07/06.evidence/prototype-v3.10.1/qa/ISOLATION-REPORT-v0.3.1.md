# Isolation Report — v0.3.1

## Baseline
- Exact input archive: `VET45-Theme7-Prototype-Harness-v0.2.9(1).zip`
- Input SHA-256: `e52523cf16406b6293bd42d747c69b8767fc2c9e1082415303f76c3067f62467`
- v0.3.1 was rebuilt **directly from this archive**. The previous v0.3.0 attempt was not used as a parent.

## File-level result before adding v0.3.1 QA reports
- Baseline existing files: **652**
- Existing files changed intentionally: **18**
- Existing files byte-identical: **634**
- Files deleted: **0**
- New design/release files at this checkpoint: **2**

## Protected-baseline checks
- Non-UIF01 flow files byte-identical: **18/18**
- Non-BJ01 Screen Contract files byte-identical: **77/77**
- Non-UIF01 component-usage files byte-identical: **32/32**
- Theme 7 SRS files byte-identical: **106/106**
- Theme 7 know-how files byte-identical: **54/54**
- Explicit BJ-02 artifacts/screenshots checked byte-identical: **23/23**
- `index.html` and `tokens.generated.css`: byte-identical to v0.2.9.

## Existing-file allowlist actually changed
- `README.md`
- `specs/themes/theme-07/prototype/contracts/component-usage/UIF-01-COMPONENT-USAGE.md`
- `specs/themes/theme-07/prototype/contracts/component-usage/UIF-01-COMPONENT-USAGE.yaml`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-001.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-002.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-003.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-004.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-005.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-060.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-061.md`
- `specs/themes/theme-07/prototype/flows/UIF-01-BJ-01.md`
- `specs/themes/theme-07/prototype/html/README.md`
- `specs/themes/theme-07/prototype/html/app.js`
- `specs/themes/theme-07/prototype/html/manifest.json`
- `specs/themes/theme-07/prototype/html/styles.css`
- `specs/themes/theme-07/prototype/html/workbench-data.js`
- `specs/themes/theme-07/prototype/html/workbench-data.json`
- `specs/themes/theme-07/prototype/reviews/CUMULATIVE-REVIEW-UIF-01.md`

The shared HTML files above (`app.js`, `styles.css`, `workbench-data.*`) are modified only to add/select BJ-01 behavior. `styles.css` uses `body[data-active-uif="UIF-01"] .bj01-*` scoping; BJ-02 runtime regression is documented separately.

## Deleted files
None.

## New files at this checkpoint
- `specs/themes/theme-07/prototype/html/CHANGELOG-v0.3.1.md`
- `specs/themes/theme-07/prototype/reviews/BJ01-PHASE-B-REVIEW-v0.3.1.md`

**Result: PASS** — no pre-existing file outside the declared allowlist changed.
