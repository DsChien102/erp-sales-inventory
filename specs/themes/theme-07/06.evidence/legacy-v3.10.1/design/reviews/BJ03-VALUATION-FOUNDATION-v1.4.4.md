# BJ03 / UIF03 — Inventory Valuation Foundation Review v1.4.4

## Product conclusion

v1.4.4 corrects the foundation issues found after the first Inventory Valuation prototype: scope identity, partial confirmation cardinality, valuation-vs-physical axes, preview-vs-commit separation, queue ownership, passive calculation step, final review completeness and safe finality.

## Canonical mental model

`Receipt physical completion → VALUATION_PENDING identified scopes → server preview/provenance → user resolves only real conflicts → one final confirmation → VALUATION_CONFIRMED on exact scopes → authoritative availability effect`.

## Non-goals

- No redesign of UIF13/BJ13 in this release.
- No change to Inventory Operations business semantics.
- No automatic conversion of quarantine/damaged/expired to sellable.

## Product-review focus

1. Does a finance user know why a task is actionable vs waiting?
2. Can they identify exactly which LOT/state quantity is being valued?
3. Can happy path be completed without a redundant passive screen?
4. Does final review show unit cost, total value, source and downstream effect without requiring memory?
5. Can partial confirmation be repeated safely on the same technical line?
6. Is UNKNOWN clearly non-actionable and non-retriable?

## Foundation corrections closed

| Finding from v1.4.3 review | v1.4.4 resolution |
|---|---|
| Balance identity lacked valuation state | `TransactionalBalance` now materializes `valuation_state` independently from physical `stock_state`. |
| Partial confirmation conflicted with one-confirmation-per-line rule | `ReceiptValuation` now carries stable scope key/version/confirmed quantity and permits multiple partial confirmations with CAS/idempotency guards. |
| Quantity selection could lose LOT identity | `SCR-015` and contracts use Product+UOM parent → LOT/non-LOT + physical-state exact child scope. |
| Expired/blocked was incorrectly treated as valuation blocker | Valuation eligibility is separated from availability eligibility; physical state is preserved. |
| UC03-01/02 traced to commit API | Added non-mutating `BC-IV-05 / API-Q-11`; only UC03-03 uses `BC-IV-01 / API-C-20`. |
| Missing evidence looked actionable | Queue separates **Có thể xử lý** vs `WAITING_EVIDENCE`; waiting receipt is read-only and aging remains visible. |
| Partial quantity looked like normal quantity editing | Full pending quantity is default; numeric input appears only after **Xác nhận một phần**. |
| Passive calculation screen was mandatory | Ready scope goes `SCR-015 → SCR-017`; `SCR-016` is only conflict/stale/provenance. |
| Final review omitted unit cost and repeated Product context | One Product group now shows actual unit cost, value, source, exact scopes and authoritative effect. |
| Availability was inferred from SELLABLE in the UI | Preview/commit consume authoritative availability effect; fixture proves SELLABLE can still yield `+0` when another blocker exists. |
| Initial official-cost creation was invisible | SCR-017/result show official-cost initialization only when applicable. |
| Result could dead-end when only missing evidence remained | Waiting-only remainder returns safely to worklist; it does not offer an unusable “continue” path. |
| UNKNOWN could look like a normal retryable task | UNKNOWN is non-actionable reconciliation with no blind retry. |

## Release gates

- Static / contract: **27/27 PASS**.
- BJ03 foundation interaction/state: **38/38 PASS**.
- Protected UIF exact runtime regression, including shared-screen UIF13: **181/181 PASS**, zero text/topology diff.
- All-flow runtime: **87 renders PASS**.
- Visual: **21/21 PASS**, 10 specimens at **402×874**.
- Isolation: **16/16 PASS**; frozen-source and know-how byte-identical.

## Remaining Product boundary

`UIF13/BJ13` is intentionally **not** Product-corrected by this release. v1.4.4 only ensures the shared UIF13 runtime remains exactly equivalent to v1.4.3. Before BJ13 design, re-evaluate whether shared Screen IDs remain the right mental-task boundary; do not infer BJ13 Product approval from the protected regression.
