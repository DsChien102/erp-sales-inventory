# CHANGELOG — v2.1.1

Parent: **v2.1.0**  
Scope: **Phase 5 final Figma DS conformance + holistic end-user hardening**.

## Product UI corrections

1. Reclassified result/status/validation page archetypes from mechanically-applied `Mobile / State` to `Mobile / Detail`; true centered `VEmptyState` surfaces switch to State dynamically.
2. Replaced synthetic success `VEmptyState` anatomy with `VSection` composition from `VIcon + VText` and canonical business detail rows.
3. Applied exact `DS v2 / Info Row` geometry/typography globally across all migrated UIFs.
4. Corrected inventory-condition multiline reason field to exact `VTextarea` and enforced canonical multiline appearance.
5. Corrected opening-balance control value to exact `VMoneyField`, including VND formatting and in-field `₫` suffix.
6. Hardened return-classification direct-state rendering so nullable quantities never leak `null` into Product UI; incoherent harness values show `—` and are never considered valid classification completion.

## Not changed

- No SRS/business rule change.
- No screen-registry/topology change.
- No actor/state-machine change.
- No rewrite of previously approved cumulative journey logic.

## QA

- Phase 5 conformance: **29/29 · 497/497 PASS**.
- Visual: **67 specimens · 17/17 UIF · 402×874 PASS**.
- Active-flow smoke: **85/85 PASS**.
- Valuation: **54/54 + 27 + 14 PASS**.
- Inventory Audit & Control: **48/48 + 53 PASS**.
- Correction/Recovery scenarios: **95 PASS**.
- Control Foundation & Inquiry: **65/65 + 78 PASS**.
- Legacy inherited assertions remain unchanged: **126/137** and **67/68**.
