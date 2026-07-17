# TH-04 EP02 — Slice roadmap

Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**S1/S2/S3/S5/S6/S7/S8/S9/S10 implementation baseline 2026-07-16:** S1, S2, S3, S5, S6, S7, S8 and S9 CONTRACT + BE are `done`. S10 CONTRACT + BE are `done` (SQL draft-only, unapplied). FE/E2E remain `todo` for S10. SQL remains draft-only for all lanes.


| #   | Slice                                                                   | Type               | Contract | BE   | FE   | E2E         | Parallel group | E2E blocked by                            |
| --- | ----------------------------------------------------------------------- | ------------------ | -------- | ---- | ---- | ----------- | -------------- | ----------------------------------------- |
| S1  | [US-04](../Epic-02-customer-price-rules/US-04.md) — Create manual rule  | write              | done     | done | todo | todo        | —              | FE + applied Pricing RPC test environment |
| S2  | [US-01](../Epic-02-customer-price-rules/US-01.md) — List/search/filter  | read               | done     | done | todo | todo        | A              | S1 test data                              |
| S3  | [US-03](../Epic-02-customer-price-rules/US-03.md) — Detail/actions      | read               | done     | done | todo | todo        | A              | S1                                        |
| S4  | [US-02](../Epic-02-customer-price-rules/US-02.md) — Choose add method   | presentation       | n/a      | n/a  | todo | todo        | A              | S1/S8 routes                              |
| S5  | [US-06](../Epic-02-customer-price-rules/US-06.md) — Edit rule           | write              | done     | done | todo | todo        | B              | S3                                        |
| S6  | [US-07](../Epic-02-customer-price-rules/US-07.md) — Disable             | write              | done     | done | todo | todo        | B              | S3                                        |
| S7  | [US-08](../Epic-02-customer-price-rules/US-08.md) — Reenable/precheck   | write              | done     | done | todo | todo        | B              | S6                                        |
| S8  | [US-05](../Epic-02-customer-price-rules/US-05.md) — Excel import        | workflow           | done     | done | todo | todo        | C              | S1 rule commit policy                     |
| S9  | [US-09](../Epic-02-customer-price-rules/US-09.md) — Remember from Sales | cross-module write | done     | done | todo | **blocked** | C              | Sales publisher/UI                        |
| S10 | [US-10](../Epic-02-customer-price-rules/US-10.md) — Activity history    | read               | done     | done | todo | todo        | C              | Any prior mutation                        |

S9 CONTRACT + BE implementation plan: [2026-07-16-pricing-s9-remembered-price-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s9-remembered-price-contract-be.vi.md). SQL draft `pricing_remembered_price_from_order_s9.sql` is authored but **not applied**.

S10 CONTRACT + BE implementation plan: [2026-07-16-pricing-s10-activity-history-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s10-activity-history-contract-be.vi.md). SQL draft `pricing_customer_price_rule_history_s10.sql` is authored but **not applied**. FE/E2E remain `todo`.




## Parallel groups


| Group | Slices      | Guidance                                                                      |
| ----- | ----------- | ----------------------------------------------------------------------------- |
| A     | S2, S3, S4  | Contract/read UI can begin after S1 contract; E2E needs data/routes.          |
| B     | S5, S6, S7  | Share detail/version/lifecycle semantics; contracts may be reviewed together. |
| C     | S8, S9, S10 | Independent workflows after core rule model stabilizes.                       |




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

Lane status is determined by the artifacts and verification owned by that lane. Workspace-wide failures outside a lane are recorded in `docs/harness/PROGRESS.md` as technical debt instead of holding a completed lane in `in_progress`.
