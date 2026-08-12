# Product / LOT Hierarchy QA - v2.9.4

**Result: PASS - 21/21**

- PASS - v2.9.4 layer contains no raw colors: 
- PASS - v2.9.4 CSS loads after v2.9.3: 
- PASS - Product header is a composition, not a new core DS component: 
- PASS - Actionable child uses nested row composition: 
- PASS - SCR037 no longer renders Product/LOT as the same List Row component: 
- PASS - SCR037 uses one collection for all Product/UOM groups: 1
- PASS - SCR037 renders three Product/UOM headers: 3
- PASS - SCR037 renders four nested LOT/non-LOT rows: 4
- PASS - Product headers use package icon while LOT rows do not: 
- PASS - Product and LOT have distinct visual surfaces: {'hb': 'rgb(229, 232, 235)', 'rb': 'rgb(255, 255, 255)', 'hr': '0px', 'rr': '0px', 'rbt': '0px', 'rh': 64, 'rw': 370}
- PASS - LOT rows are flat, not rounded cards: {'hb': 'rgb(229, 232, 235)', 'rb': 'rgb(255, 255, 255)', 'hr': '0px', 'rr': '0px', 'rbt': '0px', 'rh': 64, 'rw': 370}
- PASS - Actionable LOT rows preserve 44px minimum target: {'hb': 'rgb(229, 232, 235)', 'rb': 'rgb(255, 255, 255)', 'hr': '0px', 'rr': '0px', 'rbt': '0px', 'rh': 64, 'rw': 370}
- PASS - Nested hierarchy connector is present: 
- PASS - Child labels identify LOT/non-LOT semantics: ['Lô DH2507', 'Lô DH2511', 'Lô DH2507', 'Không theo lô']
- PASS - Nested LOT row still opens physical verification sheet: 
- PASS - SCR039 reuses the same Product group header hierarchy: 3
- PASS - SCR039 keeps canonical Key-value evidence rows 338x44: 4
- PASS - SCR041 reuses the same Product group header hierarchy: 3
- PASS - SCR041 final evidence remains scroll-reachable above sticky footer: {'ok': True, 'scrollTop': 36, 'lastBottom': 796.8539428710938, 'footerTop': 809.9775390625}
- PASS - Product viewport remains 402x874 with no horizontal overflow: {'app': [402, 874], 'overflow': 0}
- PASS - No browser errors: []
