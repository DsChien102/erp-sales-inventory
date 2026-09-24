# BJ-01 Static Contract QA v0.3.2

**Result: 24/24 PASS**

## Checks

- [x] manifest version is 0.3.2 — 0.3.2
- [x] UIF-01 active full screens exactly SCR-001/SCR-003 — ['SCR-001', 'SCR-003']
- [x] UIF-01 entry is SCR-001
- [x] UIF-01 terminal is SCR-003
- [x] flow contract declares two full screens + contextual overlays
- [x] SCR-001 explicitly has no Tra cứu/Cần chú ý tabs
- [x] filtered rows do not repeat chip indicator
- [x] SCR-003 explicitly avoids duplicate available metric
- [x] component usage removes VSegmentedControl
- [x] app has no BJ01 mode tabs
- [x] search placeholder uses mã vạch
- [x] BJ01 UI has no visible tracking labels
- [x] BJ01 UI has no barcode wording
- [x] BJ01 UI has LOT and provenance bottom sheets
- [x] filtered row helper suppresses repeated status
- [x] SCR-003 breakdown has exactly physical/sellable/reserved source calls
- [x] technical provenance labels absent from BJ01 UI
- [x] legacy card-heavy BJ01 classes absent
- [x] BJ01 CSS selectors scoped to UIF-01
- [x] SCR-001 registry states include FILTER_EMPTY — ['READY', 'LOADING', 'EMPTY', 'FILTER_EMPTY', 'STALE', 'PERMISSION_DENIED']
- [x] SCR-003 registry uses only READY/LOADING/STALE/PERMISSION_DENIED — ['READY', 'LOADING', 'STALE', 'PERMISSION_DENIED']
- [x] SCR-004 is overlay — overlay
- [x] SCR-005 is overlay — overlay
- [x] workbench UIF-01 nav has only SCR-001/SCR-003 — ['SCR-001', 'SCR-003']

## Boundary

- Validates BJ-01 v0.3.2 information architecture, registry alignment, copy hygiene and UIF-01 CSS scoping.
- Does not replace runtime/browser visual QA or BJ-02 regression QA.
