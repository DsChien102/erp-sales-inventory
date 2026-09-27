# BJ-02 Regression — v0.3.2

**Result: PASS**

v0.3.2 was tested as a cumulative successor of v0.3.1. BJ-02/UIF-02 is a protected baseline and was not redesigned in this round.

## Runtime

- Original BJ-02 Chromium suite copied to an isolated temp tree: **78/78 PASS**.
- The test ran outside the canonical v0.3.2 tree, so historical `screenshots-v0.2.9` were not overwritten.

## Protected source/contract checks

- [x] `specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.5.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.7.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.8.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/BJ02-PILOT-REVIEW-v0.2.9.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/component-usage/UIF-02-COMPONENT-USAGE.yaml` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-006.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-007.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-008.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-009.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-010.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-011.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-012.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-013.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/contracts/screens/SCR-084.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/flows/UIF-02-BJ-02.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/html/index.html` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/html/qa/BJ02-REGRESSION-v0.3.1.md` byte-identical to v0.3.1
- [x] `specs/themes/theme-07/prototype/html/tokens.generated.css` byte-identical to v0.3.1

## Protected workbench data

- [x] UIF-02 workbench flow identical to v0.3.1
- [x] SCR-006 workbench screen data identical to v0.3.1
- [x] SCR-007 workbench screen data identical to v0.3.1
- [x] SCR-008 workbench screen data identical to v0.3.1
- [x] SCR-009 workbench screen data identical to v0.3.1
- [x] SCR-084 workbench screen data identical to v0.3.1
- [x] SCR-010 workbench screen data identical to v0.3.1
- [x] SCR-011 workbench screen data identical to v0.3.1
- [x] SCR-012 workbench screen data identical to v0.3.1
- [x] SCR-013 workbench screen data identical to v0.3.1

## BJ-02 screenshot pixel regression

- [x] `SCR-007-document-search.png` pixel-identical
- [x] `SCR-009-document-overview.png` pixel-identical
- [x] `SCR-010-document-review.png` pixel-identical
- [x] `SCR-010-quick-review.png` pixel-identical
- [x] `SCR-011-approval-context.png` pixel-identical
- [x] `SCR-013-recovery.png` pixel-identical
- [x] `SCR-084-document-multilot.png` pixel-identical

Note: one PNG file may differ at binary hash due to PNG metadata/encoding while decoding to identical pixels; pixel comparison is the visual criterion used here.
