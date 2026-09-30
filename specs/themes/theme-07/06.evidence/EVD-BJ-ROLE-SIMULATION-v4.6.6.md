# Evidence — BJ/UIF Role Simulation v4.6.6

**Status: PASS**

## Scope

- Review workbench only, tab `Theo BJ / UIF`.
- Role choices come only from existing Screen Contract `actors` metadata.
- No product permission or business logic changes.

## Verified

- BJ02 exposes `Thủ kho` and `Người phê duyệt`; switching to approver lands on existing `SCR-011`.
- BJ11 exposes `Người phê duyệt độc lập`; switching to that actor lands on existing `SCR-051`.
- BJ08 preserves the existing actor terminology, including `Eligible independent approver`; switching lands on existing `SCR-046`.
- Shared screens that already declare more than one actor remain on the same screen when switching between those declared actors.
- Full BJ screen navigation remains visible; screens outside the simulated actor are only de-emphasized in the review workbench.
- Full-theme Hub role profiles from v4.6.5 remain available and separate.
- Product viewport remains 402×874 with no horizontal overflow.
- Browser errors: 0.

## Source evidence

- `03.design/prototype/html/qa/BJ-ROLE-SIMULATION-QA-v4.6.6.json`
- `03.design/prototype/html/qa/BJ-ROLE-SIMULATION-QA-v4.6.6.md`
- `03.design/prototype/html/qa/ALL-FLOWS-RUNTIME-SMOKE-v4.6.6.json`
