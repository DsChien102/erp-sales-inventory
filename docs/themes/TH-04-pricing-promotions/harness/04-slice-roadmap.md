# TH-04 EP02 — Slice roadmap

Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Greenfield baseline 2026-07-14:** all actionable lanes start `todo`. Only S9 E2E is blocked by the missing Sales publisher/confirmation flow. CONTRACT, BE and fake-driven FE for S9 remain actionable.

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| - | ----- | ---- | -------- | -- | -- | --- | -------------- | -------------- |
| S1 | [US-04](../Epic-02-customer-price-rules/US-04.md) — Create manual rule | write | todo | todo | todo | todo | — | — |
| S2 | [US-01](../Epic-02-customer-price-rules/US-01.md) — List/search/filter | read | todo | todo | todo | todo | A | S1 test data |
| S3 | [US-03](../Epic-02-customer-price-rules/US-03.md) — Detail/actions | read | todo | todo | todo | todo | A | S1 |
| S4 | [US-02](../Epic-02-customer-price-rules/US-02.md) — Choose add method | presentation | n/a | n/a | todo | todo | A | S1/S8 routes |
| S5 | [US-06](../Epic-02-customer-price-rules/US-06.md) — Edit rule | write | todo | todo | todo | todo | B | S3 |
| S6 | [US-07](../Epic-02-customer-price-rules/US-07.md) — Disable | write | todo | todo | todo | todo | B | S3 |
| S7 | [US-08](../Epic-02-customer-price-rules/US-08.md) — Reenable/precheck | write | todo | todo | todo | todo | B | S6 |
| S8 | [US-05](../Epic-02-customer-price-rules/US-05.md) — Excel import | workflow | todo | todo | todo | todo | C | S1 rule commit policy |
| S9 | [US-09](../Epic-02-customer-price-rules/US-09.md) — Remember from Sales | cross-module write | todo | todo | todo | **blocked** | C | Sales publisher/UI |
| S10 | [US-10](../Epic-02-customer-price-rules/US-10.md) — Activity history | read | todo | todo | todo | todo | C | Any prior mutation |

## Parallel groups

| Group | Slices | Guidance |
| ----- | ------ | -------- |
| A | S2, S3, S4 | Contract/read UI can begin after S1 contract; E2E needs data/routes. |
| B | S5, S6, S7 | Share detail/version/lifecycle semantics; contracts may be reviewed together. |
| C | S8, S9, S10 | Independent workflows after core rule model stabilizes. |

## Lane semantics

- CONTRACT freezes application symbols/DTOs/errors/fake scenarios before BE/FE diverge.
- BE includes domain, handler, port/gateway, RPC draft and tests.
- FE uses `FakePricingModule`; no BE availability prerequisite.
- E2E uses real mediator/startup and applied test environment; external dependency may block only this lane.

## Definition of Done — CONTRACT

- [ ] Commands/queries/DTOs exported from pricing application package.
- [ ] `IPricingModule` and fake scenario matrix cover success, empty/warning/error/state change.
- [ ] Matching section in [07-api-contracts.md](07-api-contracts.md) reviewed by BE and FE.

## Definition of Done — BE

- [ ] Upstream GitNexus impact checked before modifying existing symbols.
- [ ] Domain/handler/validator/port/RPC gateway implemented with annotations and generated registration.
- [ ] SQL exists only as `_drafts/` and RPC params match contract.
- [ ] Handler/gateway/domain tests cover US scenarios and commit-time invariants.

## Definition of Done — FE

- [ ] Thin page + extracted widgets/dialogs/cubit through `IPricingModule`.
- [ ] Screen Group manifest covered in design-system example catalog where applicable.
- [ ] Widget tests use stable `wgt_e02_u{us}_...` IDs and fake scenarios.

## Definition of Done — E2E

- [ ] ERP DI uses real pricing startup/module through mediator.
- [ ] Tenant/access and RPC boundary are exercised.
- [ ] `melos run test`, ERP tests and harness verification pass.

## Common completion

- [ ] US FR/BR/EC/SCN read and traceability rows updated.
- [ ] No page > 500 lines, inline dialog or direct PostgREST write.
- [ ] GitNexus `detect_changes()` run before commit; no commit if capability unavailable.

