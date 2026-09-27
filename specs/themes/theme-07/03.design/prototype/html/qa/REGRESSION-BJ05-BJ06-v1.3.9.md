# Regression — BJ05 / BJ06 under v1.3.9

**Result: PASS**

v1.3.9 changes the shared HTML renderer/data/CSS only where required for UIF07 and scopes new CSS under `body[data-active-uif="UIF-07"]`.

Regression runs after the BJ07 renderer change:

- `bj05_end_user_v137.py` → **PASS 48/48**.
- `bj06_end_user_v138.py` → **PASS 65/65**.
- `all_flows_smoke_v139.py` → **PASS 87 registered flow/screen renders**.

Historical BJ05/BJ06 QA files and screenshots are restored byte-identical to the v1.3.8 parent after the regression run; v1.3.9 therefore does not publish regenerated legacy evidence as a functional change.

The legacy `validate_contract.py` is intentionally excluded from the v1.3.9 gate: it is hard-coded to the old BJ02/v0.2.9 contract and reports obsolete expectations against cumulative packages. Target release gates are BJ07 end-user/state QA, BJ07 static/contract conformance, all-flow runtime smoke, visual QA and isolation.
