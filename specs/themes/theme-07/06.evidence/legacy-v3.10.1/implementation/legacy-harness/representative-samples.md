# Representative Samples

## Contract — P0-06 UNKNOWN recovery

- Owner: Inventory Control.
- Finality: only authoritative operation/ledger evidence resolves `UNKNOWN`.
- Safe failure: retain `UNKNOWN`, same identity and evidence chain; never use UI, projection or transport timeout as finality.

## Test — TST-P006-UNKNOWN

- Preconditions: stable operation identity, unchanged fingerprint and accessible owner evidence.
- Action: query/resume the same identity at the P0-06 owner boundary.
- Expected owner effect: remains UNKNOWN until proof exists; no second mutation.
- Negative assertion: projection or event receipt cannot replace owner finality.

## Fixture — FX-TST-P0-06-FENCE

The fixture stores owner, aggregate key, operation identity, SHA-256 payload fingerprint, P0-specific linearization rule and distinct expected results for all eight fence dimensions.

## Blocked/failure example

When the repository adapter is absent, the test is `BLOCKED_BY_REPO_ADAPTER`, not passed or skipped. Recovery: implement handler/DB/outbox mappings, execute with the same fixture identity, capture command/exit/log hashes and then raise evidence to `REPO_EXECUTED`.
