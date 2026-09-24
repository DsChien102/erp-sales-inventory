# Release Validation — v2.9.0

Parent: **v2.8.2**  
Status: **PASS · REVIEW READY**

## Scope

BJ07 / UIF-07 supplier-return execution is structurally migrated to the live Figma Design System without changing the source-owned commercial boundary. No new feature component is introduced.

## Gates

- BJ07 Figma DS + UX: **PASS 55/55**.
- All-flow runtime: **PASS 85/85**, 0 failures, 0 browser errors.
- Prior migrated BJ regression: **PASS 23/23**, 0 browser errors.
- BJ05/BJ06 regression suite: **PASS 32/32**.
- Device frame: **PASS 7/7**, 85 active screens checked at exact 402×874 Product geometry.
- Review workbench fit: **PASS 3/3**.
- Mobile prototype validator: **PASS**, 0 blocker/high findings.
- JavaScript syntax: **PASS** (`app.js`, `workbench-data.js`).
- Visual QA: **PASS**, 9 representative captures across 4 canonical BJ07 screens.

## Locked BJ07 outcome

- Queue uses semantic collections: actionable/ready = canonical Navigation rows; source-owned waiting = independent read-only Status collection.
- Preparation scales as request → Product+UOM → exact source allocation rows; normal fixture fits one Product viewport and many-LOT cases scroll naturally.
- Physical verification uses canonical normal `VBottomSheet 4695:6353`, no X; typed LOT is comparison-only.
- Physical mismatch/source change cannot be repaired by warehouse-side quantity reduction or LOT substitution.
- Final review uses grouped Info Rows and per-allocation Key-value Rows, has one actual-handover primary CTA, and no duplicate confirmation/helper.
- Actual handover is the only physical/value decrement commit. Completed result is terminal; UNKNOWN never blind-retries.

## Visual artifacts

- `specs/themes/theme-07/prototype/html/qa/v290-bj07-captures/BJ07-CANONICAL-CONTACT-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/v290-bj07-captures/SCR037-VERIFY-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/v290-bj07-captures/SCR039-SOURCE-CHANGED.png`
