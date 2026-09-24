# Isolation Report v1.3.8 — BJ06 deep correction

Parent: `VET45-Theme7-Prototype-Harness-v1.3.7`  
Child: `VET45-Theme7-Prototype-Harness-v1.3.8`

**Result: PASS**

- Parent files: **793**
- Existing files byte-identical: **766**
- Existing files intentionally changed: **27**
- New v1.3.8 artifacts: **24**
- Deleted parent files: **0**
- Unexpected existing-file changes: **0**

## Allowed existing-file changes

- `README.md`
- `specs/themes/theme-07/know-how/decisions/decision-register.md`
- `specs/themes/theme-07/prototype/contracts/action-registry.json`
- `specs/themes/theme-07/prototype/contracts/bj-ui-flow-map.md`
- `specs/themes/theme-07/prototype/contracts/component-usage/UIF-06-COMPONENT-USAGE.md`
- `specs/themes/theme-07/prototype/contracts/component-usage/UIF-06-COMPONENT-USAGE.yaml`
- `specs/themes/theme-07/prototype/contracts/screen-registry.json`
- `specs/themes/theme-07/prototype/contracts/screen-registry.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-030.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-031.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-032.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-033.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-034.md`
- `specs/themes/theme-07/prototype/contracts/screens/SCR-035.md`
- `specs/themes/theme-07/prototype/flows/UIF-06-BJ-06.md`
- `specs/themes/theme-07/prototype/flows/ui-flow-registry.json`
- `specs/themes/theme-07/prototype/html/README.md`
- `specs/themes/theme-07/prototype/html/app.js`
- `specs/themes/theme-07/prototype/html/manifest.json`
- `specs/themes/theme-07/prototype/html/styles.css`
- `specs/themes/theme-07/prototype/html/workbench-data.js`
- `specs/themes/theme-07/prototype/html/workbench-data.json`
- `specs/themes/theme-07/srs/02-business-journeys/06-BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra.md`
- `specs/themes/theme-07/srs/05-use-cases/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra/UC-06-01-xac-minh-hang-duoc-phep-nhan-tra.md`
- `specs/themes/theme-07/srs/05-use-cases/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra/UC-06-02-xu-ly-ngoai-le-truy-vet.md`
- `specs/themes/theme-07/srs/05-use-cases/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra/UC-06-03-ghi-nhan-hang-khach-tra.md`
- `specs/themes/theme-07/srs/05-use-cases/BJ-06-tiep-nhan-va-phan-loai-hang-khach-tra/UC-06-04-phan-loai-hang-thuc-nhan.md`

## New artifacts

- `specs/themes/theme-07/prototype/html/CHANGELOG-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/BJ06-END-USER-QA-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/BJ06-STATIC-CONFORMANCE-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/ISOLATION-REPORT-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/VISUAL-QA-v1.3.8.md`
- `specs/themes/theme-07/prototype/html/qa/all_flows_smoke_v138.py`
- `specs/themes/theme-07/prototype/html/qa/bj06_end_user_v138.py`
- `specs/themes/theme-07/prototype/html/qa/lot-evidence-v138.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR030-all.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR031-cap-changed.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR031-exception-draft.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR031-unverified.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR031-waiting-approval.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR032-wrong-lot-evidence.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR033-editor.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR033-ready-complete.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR034-pending-detail.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR034-rejected.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR035-classified.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/BJ06-SCR035-received.png`
- `specs/themes/theme-07/prototype/html/qa/screenshots-v1.3.8/CONTACT-SHEET.png`
- `specs/themes/theme-07/prototype/html/qa/static_conformance_v138.py`
- `specs/themes/theme-07/prototype/reviews/BJ06-DEEP-CORRECTION-v1.3.8.md`

## Protected baseline conclusion

BJ01, BJ02, BJ04, BJ05, BJ07 and all other non-BJ06 SRS/UIF/Screen Contract artifacts remain byte-identical to v1.3.7. Shared renderer/data files changed only because UIF06 is hosted in the common workbench; BJ05 regression was rerun separately and passed.

## Legacy package validator note

The inherited repository-level `validate_package.py` still stops on missing `prototype/screen-map.md`. The same failure occurs on parent v1.3.7, so this is not a new v1.3.8 regression. Focused BJ06, all-flow, BJ05 regression and isolation gates pass independently.
