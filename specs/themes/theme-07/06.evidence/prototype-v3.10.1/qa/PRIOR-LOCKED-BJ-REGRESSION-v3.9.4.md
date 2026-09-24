# Prior Locked BJ Regression — v3.9.4

**Result: PASS · 8/8**

Scope: BJ01, BJ02 and BJ05 protected semantics after BJ06 Atomic Change Set.

- PASS — BJ01 single-list stock entry remains available
- PASS — BJ01 detail still separates physical/eligible/reserved/available facts
- PASS — BJ02 review READY fixture remains actionable
- PASS — BJ02 approval READY remains actionable without English leakage
- PASS — BJ05 pick editor still uses explicit quantity precision
- PASS — BJ05 UNKNOWN preserves exact operation identity
- PASS — BJ05 VERIFYING row remains non-actionable
- PASS — No browser errors across BJ01/BJ02/BJ05 regression
