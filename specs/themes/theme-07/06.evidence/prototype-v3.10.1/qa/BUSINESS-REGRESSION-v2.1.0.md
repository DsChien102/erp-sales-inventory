# Theme 7 — Business / Interaction Regression v2.1.0

Phase 4 changes UI expression only. Business behavior remains cumulative from parent v2.0.2.

## Current runtime evidence

| Suite | Result on v2.1.0 |
|---|---|
| Inventory Valuation end-user | PASS 54/54 |
| Inventory Valuation scenario matrix | PASS 27/27 |
| Inventory Valuation integration | PASS 14/14 |
| Inventory Audit & Control end-user | PASS 48/48 |
| Inventory Audit & Control scenario matrix | PASS 53 renders |
| Correction & Recovery scenario matrix | PASS 95 renders |
| Control Foundation & Inquiry end-user | PASS 65/65 |
| Control Foundation & Inquiry scenario matrix | PASS 78 renders |
| All-flow active-screen smoke | PASS 85/85 renders |
| Holistic semantic/runtime | PASS 6/6 gates · 497 state renders |

## Inherited legacy assertion debt

Two older text/fixture-oriented assertion suites are not release gates and remain unchanged relative to parent v2.0.2:

- `inventory_ops_end_user_v141.py`: **126/137** on parent v2.0.2 and **126/137** on child v2.1.0; the same 11 historical assertions fail in both.
- `correction_recovery_end_user_v170.py`: **67/68** on parent v2.0.2 and **67/68** on child v2.1.0; the same legacy assertion `BJ17 committed result completed without new operation` fails in both.

These are recorded as baseline test debt, not recast as PASS and not attributed to the Phase 4 UI migration. The current 497-state semantic/runtime gate has zero business issue.
