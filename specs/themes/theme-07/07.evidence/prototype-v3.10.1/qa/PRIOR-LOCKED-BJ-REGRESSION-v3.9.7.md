# Prior Locked BJ Regression — v3.9.7

**Result: PASS · 17/17**

Scope: BJ01 plus locked Wave 2 semantics (BJ02, BJ05, BJ06, BJ07, BJ04) after BJ03 Atomic Change Set.

- PASS — BJ01 single-list stock entry remains available
- PASS — BJ01 detail still separates physical/eligible/reserved/available facts
- PASS — BJ02 review READY fixture remains actionable
- PASS — BJ02 approval READY remains actionable without English leakage
- PASS — BJ05 pick editor still uses explicit quantity precision
- PASS — BJ05 UNKNOWN preserves exact operation identity
- PASS — BJ05 VERIFYING row remains non-actionable
- PASS — BJ06 current ReturnExchangeLine authorization caps receipt
- PASS — BJ06 WAITING request is true read-only
- PASS — BJ06 expired quantity remains system-derived and non-editable
- PASS — BJ06 UNKNOWN preserves exact operation identity and BJ17 handoff
- PASS — No browser errors across BJ01/BJ02/BJ05/BJ06 regression
- PASS — BJ07 queue remains source-owned with no fake RTV_PENDING CTA
- PASS — BJ07 physical verification still uses source allocation identity
- PASS — BJ07 UNKNOWN remains non-blind-retry recovery
- PASS — BJ04 reservation remains read-only current projection
- PASS — BJ04 has no manual mutation action
