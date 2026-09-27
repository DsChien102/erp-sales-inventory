# Cross-BJ UI Hardening QA — v2.7.4

**Result: PASS · 24/24 checks**

Scope: all structurally migrated Product UIFs `UIF-01 / UIF-02 / UIF-04 / UIF-05 / UIF-08` (23 canonical screens), plus explicit loaded/disabled/detail scenarios.

Live Figma references used before implementation: `DS v2 / List Row` 525:519; `DS v2 / Summary Card` 525:552; `DS v2 / Entity Card` 525:539; Theme 1 Product detail composition references.

## Checks

- [x] v2.7.4 hardening CSS uses semantic tokens only
- [x] Summary Card is no longer claimed for BJ01/BJ05 product identity
- [x] List Row Disabled state is implemented centrally
- [x] BJ05 queue waiting state stays Navigation rather than changing type
- [x] All 23 migrated BJ screens render at exact 402x874
- [x] All 23 migrated BJ screens have no root horizontal overflow
- [x] No visible clipped text in migrated canonical renders outside intentional horizontal scrollers
- [x] SCR-025 peer order rows all remain Navigation/Default-density 370x76 with chevron
- [x] SCR-025 waiting order uses true Disabled Navigation state
- [x] SCR-025 actionable order stays enabled Navigation peer
- [x] SCR-026 waiting collection remains same Navigation/Default geometry and chevrons
- [x] BJ01 identity uses canonical Status/Compact List Row 370x52
- [x] BJ01 supporting quantities are grouped in content-sized 370px information surface
- [x] BJ01 product detail contains no product Summary Card
- [x] BJ02 real line editor uses Status/Compact List Row for product context
- [x] BJ02 selected-product context has no fixed Summary Card blank space
- [x] BJ02 line editor has no horizontal overflow
- [x] BJ02 receipt record cards no longer have inherited 2px internal overflow
- [x] BJ05 product identity uses Status/Compact List Row 370x52
- [x] BJ05 picking detail no longer uses fixed Summary Card for sparse identity
- [x] Every rendered Compact List Row in migrated scope matches live Figma 370x52/p4-16/gap8/r8
- [x] SCR-028 last content remains reachable above sticky footer at max scroll
- [x] Disabled Navigation uses DS parent opacity 0.4 without anatomy change
- [x] No browser page errors during cross-BJ review
