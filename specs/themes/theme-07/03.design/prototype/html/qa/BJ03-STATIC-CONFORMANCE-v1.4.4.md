# BJ03 Static / Contract Conformance v1.4.4

**Result: PASS · 27/27 checks**

- Covers data model, domain lifecycle, BC preview/commit split, UC trace, BJ03/BJ13 boundary, flow topology and Product-copy leakage.

## Checks

- PASS — TransactionalBalance materializes valuation_state
- PASS — Balance unique key includes valuation_state
- PASS — ReceiptValuation has stable scope key
- PASS — ReceiptValuation has scope version
- PASS — ReceiptValuation has confirmed quantity
- PASS — Partial direct confirmations explicitly allowed
- PASS — Old one-direct-confirmation-per-line rule removed
- PASS — Domain uses two independent axes
- PASS — Old RECEIVED->VALUATION_PENDING->SELLABLE lifecycle removed
- PASS — BC-IV-01 preserves physical state
- PASS — Expired/blocked no longer blocks valuation
- PASS — BC-IV-01 has exact-scope stale/quantity guards
- PASS — Non-mutating preview contract exists
- PASS — Preview API-Q-11 exists
- PASS — UC03-01 maps to preview not confirm
- PASS — UC03-02 maps to preview not confirm
- PASS — UC03-03 remains final confirm command
- PASS — BJ03 start boundary excludes post-valuation late cost
- PASS — BJ03 explicitly routes post-initial late cost to BJ13
- PASS — UI flow happy path bypasses SCR016
- PASS — UI flow keeps SCR016 for conflict
- PASS — UI result distinguishes waiting remainder
- PASS — No end-user technical leakage: identified scope
- PASS — No end-user technical leakage: exact scope
- PASS — No end-user technical leakage: authoritative
- PASS — No end-user technical leakage: value movement
- PASS — No end-user technical leakage: task này
