# List Navigation State QA — v3.6.3

**Result: PASS · 15/15 PASS**

- Declared route-state renders scanned: **518**
- Baseline mixed Navigation/Status peer-collection renders: **10** across **2 screens**
- Post-fix mixed peer collections: **0**
- Rule: same peer destination collection = same `Navigation` anatomy; unavailable peer = `State=Disabled`, retains chevron, no interaction.

## Checks

- PASS — runtime version
- PASS — all 518 declared route-state renders scanned
- PASS — no mixed Navigation/Status peer collection remains
- PASS — every visible Navigation row keeps a chevron
- PASS — every Disabled Navigation row is natively disabled and uses DS opacity 0.4
- PASS — every enabled Navigation row is an interactive button
- PASS — reported UIF-03 waiting row keeps Navigation anatomy and is Disabled
- PASS — UIF-03 actionable peers remain enabled Navigation rows
- PASS — UIF-13 waiting row keeps Navigation anatomy and is Disabled
- PASS — UIF-13 actionable peers remain enabled Navigation rows
- PASS — UIF-03 disabled row cannot navigate
- PASS — UIF-03 actionable row still navigates
- PASS — UIF-13 disabled row cannot navigate
- PASS — UIF-13 actionable row still navigates
- PASS — no browser page errors
