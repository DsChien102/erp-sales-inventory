# UIF-08 — Figma DS Component Usage · v3.10.0

> Status: `BJ08_DEEP_REVIEW_ALIGNED_v3.10.0` · Authority: live Figma Design System v2.0.3.

## Product locks
1. SCR-044 true blind count; no book/variance proxy before FIRST submit.
2. Count row distinguishes Product + physical stock state + LOT + base UOM; valuation state never becomes counter UI.
3. SCR-042 has no destructive cancellation; cancellation is contextual on SCR-044/SCR-045 only.
4. Zero variance routes directly to SCR-047, never SCR-046.
5. Recount shows round context; old round evidence is immutable, not editable.
6. SCR-046 is independent read-only approval for non-zero variance only.
7. Financial risk values are server-omitted unless authorized.
8. UNKNOWN preserves command/session identity and hands off BJ17.

| Screen | Canonical DS | Product composition | Mutation |
|---|---|---|---|
| SCR-042 | Search & Filter Header, List Row, VBadge when semantic, VButton | Theme7StockCountSession | none; create is navigation |
| SCR-043 | Mobile/Form, Info Row, VSelect, VTextField, Search & Select, VBanner, Sticky Footer | Theme7ScopeTarget | ACT-09-OPEN |
| SCR-044 | Mobile/Form, Info Row, VBanner, VNumericKeypadSheet, Search & Select, Sticky Footer | Theme7StockCountLine | ACT-09-SUBMIT; ACT-09-CANCEL contextually |
| SCR-045 | Mobile/Form, Info Row, VBanner, VNumericKeypadSheet, Sticky Footer | Theme7StockRecountLine, Theme7CountBasisStatus | ACT-09-SUBMIT; ACT-09-CANCEL contextually |
| SCR-046 | Mobile/Detail, Info Row, VBanner, VButton, Sticky Footer, Confirmation Sheet | Theme7StockCountReview | ACT-09-APPROVE only |
| SCR-047 | Mobile/Detail + State Pattern + Info Row | Theme7OperationResult | none |

Use semantic variables, 402×874, 16px edge, touch ≥44px, disabled parent opacity 0.4, approved VET45 icon registry. No Theme-specific component when existing DS composition suffices.
