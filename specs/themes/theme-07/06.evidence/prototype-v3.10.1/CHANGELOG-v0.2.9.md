# CHANGELOG — BJ-02 HTML v0.2.9

## Changed

- SCR-007: document search + proper FILTER_EMPTY.
- SCR-008: supplier unresolved-master inline validation.
- SCR-009: clearer two-level item summary; true read-only propagation; real EMPTY state.
- SCR-084: contextual source quantity, derived LOT total, inline lot deletion, auto-expanded existing exceptions, not-received confirm after entered data.
- SCR-010/011: actual lot evidence, full receipt context, normalized approval feedback.
- SCR-012: result grouping semantics + lot identity; valuation notice state-specific.
- SCR-013: human evidence timeline, one UNKNOWN loading state, VEmptyState for no new result.
- Regression QA: document search now truly hides non-matching cards despite card display rules.
- Draft continuity: opening an already-completed item and pressing Back without edits preserves completion instead of demoting the item to pending.

## Scope guard

Only BJ-02/UIF-02 renderer/contracts/metadata and package-level version/QA files are intentionally changed from v0.2.8.
