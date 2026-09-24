# Changelog — VET45 Theme 7 Prototype Harness v3.10.0

**Parent:** v3.9.9  
**Scope:** Wave 4 — BJ08 Kiểm kê kho — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.9 is the single parent baseline for this cumulative update.
- Frozen-source remains historical and byte-identical to the parent ZIP.
- BJ01, Wave 2 and the completed Wave 3 locks remain protected by regression.
- v3.10.0 hardens BJ08 only; Wave 4 remains open and continues with BJ09 after this lock candidate.

## Approved BJ08 decisions implemented

1. Stock count opens through an **atomic count barrier before cutoff**: scope normalization → barrier acquisition → in-flight serialization → cutoff ledger sequence → book snapshot → session/line/lock commit.
2. `CountScopeSnapshot` is the immutable scope authority. Group scope resolves exact Product membership at open; prospective LOTs are admitted only under the frozen Product/Group rules.
3. Physical count identity is `Warehouse + Product + physical stock_state + LOT/non-LOT` in base UOM. Phase 1 blocks unresolved/mixed valuation state before opening a session.
4. FIRST and RECOUNT evidence are immutable `StockCountSubmission` rounds. Recount never overwrites earlier physical evidence.
5. `ApprovalCase` supports `STOCK_COUNT_SESSION` directly and excludes every actor who contributed count evidence from the eligible approver set. `REQUEST_RECOUNT` creates immutable predecessor/successor lineage.
6. Unexpected physical stock requires complete physical identity. Counter never enters surplus price; surplus adjustment requires an authoritative `surplus_value_basis`.
7. Non-zero variance approval binds exact risk/value basis and rechecks it at commit. Final zero variance completes the session, creates no adjustment and releases the lock without synthetic approval.

## Contract / UX hardening

- UC actors are split by real authority: opener, assigned counter, independent approver and authorized canceller.
- `ACT-09-CANCEL` is contextual only on SCR-044/SCR-045; browse and approval surfaces do not own destructive cancellation.
- SCR-044 remains true blind count: book/variance/proxy are absent before FIRST submit.
- Recount shows book + first count + variance while preserving prior round evidence.
- SCR-046 is read-only independent approval for non-zero variance only; self-approval is blocked.
- Zero-variance FIRST/RECOUNT paths route directly to SCR-047.
- SCR-047 renders command-authoritative zero/adjusted/cancelled/rejected/UNKNOWN results. UNKNOWN preserves the same operation identity and hands off to BJ17 without blind retry.
- Financial risk/value is server-masked when permission is absent.
- The existing Figma DS composition is retained; the approval overflow found during regression was fixed with DS-compatible copy, not ad-hoc CSS.

## QA

- BJ08 Deep Review: **135/135 PASS**.
- BJ08 Fresh-eye: **18/18 PASS**.
- Prior locked regression — BJ01 + Wave 2 + Wave 3: **29/29 PASS**.
- Wave 3 Cross-BJ Audit regression: **35/35 PASS**.
- Frozen-source immutability: **108/108 byte-identical to parent ZIP**.
- Current package validation: **67/67 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **23/23 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 514 route-state renders, 89 canonical routes.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens.
- Focused BJ08 visual captures: **9**, 0 page errors.
