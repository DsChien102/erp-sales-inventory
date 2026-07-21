# TH-04 EP02 — Slice roadmap

Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**S1/S2/S3/S5/S6/S7/S8/S9/S10 implementation baseline 2026-07-16 (cập nhật FE 2026-07-20):**
CONTRACT + **BE Dart** (domain / application / infrastructure / `PricingStartup` / gateway / tests) are `done` cho S1–S10.
**SQL vẫn chỉ là `_drafts/` — chưa promote / chưa apply lên DB** → app ERP chưa gọi được RPC pricing thật; E2E thật bị block.
**FE EP02** (SG-01…SG-06): S1–S8 + S10 = `done` (pages/widgets/cubit + `wgt_e02_u*` + FakePricingModule). S9 FE = `todo` (cần Sales confirmation surface). ERP DI tạm vẫn `InMemoryPricingModule`.


| #   | Slice                                                                   | Type               | Contract | BE   | FE          | E2E         | Parallel group | E2E blocked by                            |
| --- | ----------------------------------------------------------------------- | ------------------ | -------- | ---- | ----------- | ----------- | -------------- | ----------------------------------------- |
| S1  | [US-04](../Epic-02-customer-price-rules/US-04.md) — Create manual rule  | write              | done     | done | done        | todo        | —              | applied Pricing RPC test environment      |
| S2  | [US-01](../Epic-02-customer-price-rules/US-01.md) — List/search/filter  | read               | done     | done | done        | todo        | A              | S1 test data                              |
| S3  | [US-03](../Epic-02-customer-price-rules/US-03.md) — Detail/actions      | read               | done     | done | done        | todo        | A              | S1                                        |
| S4  | [US-02](../Epic-02-customer-price-rules/US-02.md) — Choose add method   | presentation       | n/a      | n/a  | done        | todo        | A              | S1/S8 routes                              |
| S5  | [US-06](../Epic-02-customer-price-rules/US-06.md) — Edit rule           | write              | done     | done | done        | todo        | B              | S3                                        |
| S6  | [US-07](../Epic-02-customer-price-rules/US-07.md) — Disable             | write              | done     | done | done        | todo        | B              | S3                                        |
| S7  | [US-08](../Epic-02-customer-price-rules/US-08.md) — Reenable/precheck   | write              | done     | done | done        | todo        | B              | S6                                        |
| S8  | [US-05](../Epic-02-customer-price-rules/US-05.md) — Excel import        | workflow           | done     | done | done        | todo        | C              | S1 rule commit policy                     |
| S9  | [US-09](../Epic-02-customer-price-rules/US-09.md) — Remember from Sales | cross-module write | done     | done | todo        | **blocked** | C              | Sales publisher/UI                        |
| S10 | [US-10](../Epic-02-customer-price-rules/US-10.md) — Activity history    | read               | done     | done | done        | todo        | C              | Any prior mutation                        |

S9 CONTRACT + BE implementation plan: [2026-07-16-pricing-s9-remembered-price-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s9-remembered-price-contract-be.vi.md). SQL draft `pricing_remembered_price_from_order_s9.sql` is authored but **not applied**.

S10 CONTRACT + BE implementation plan: [2026-07-16-pricing-s10-activity-history-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s10-activity-history-contract-be.vi.md). SQL draft `pricing_customer_price_rule_history_s10.sql` is authored but **not applied**. FE lane closed 2026-07-20 (`wgt_e02_u10_*` + Fake history scenarios); E2E vẫn mở tới khi promote/apply RPC.


## Parallel groups


| Group | Slices      | Guidance                                                                      |
| ----- | ----------- | ----------------------------------------------------------------------------- |
| A     | S2, S3, S4  | Contract/read UI can begin after S1 contract; E2E needs data/routes.          |
| B     | S5, S6, S7  | Share detail/version/lifecycle semantics; contracts may be reviewed together. |
| C     | S8, S9, S10 | Independent workflows after core rule model stabilizes.                       |




## Lane semantics

- CONTRACT freezes application symbols/DTOs/errors/fake scenarios before BE/FE diverge.
- **BE (harness) = Dart BE đã xong:** domain + handler + validator + port/gateway + `PricingStartup` + SQL **draft** trong `supabase/migrations/_drafts/` + tests.
  - **Không** có nghĩa schema/RPC đã có trên Postgres local/remote.
  - Để “thấy BE trên app”: cần **promote draft → migration timestamp** + apply DB + đổi DI từ `InMemoryPricingModule` → `PricingStartup`.
- FE uses `FakePricingModule` (harness) hoặc tạm `InMemoryPricingModule` (ERP demo); no applied-RPC prerequisite for UI.
- E2E uses real mediator/startup and **applied** test environment; external dependency may block only this lane.



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

- [x] Thin page + extracted widgets/dialogs/cubit through `IPricingModule`.
- [x] Screen Group manifest covered in design-system example catalog where applicable (`VBanner` + shared primitives; feature screens stay in `modules/pricing/presentation`).
- [x] Widget tests use stable `wgt_e02_u{us}_...` IDs and fake scenarios (`apps/erp/test/features/pricing/presentation/pages/pricing_pages_test.dart` + `modules/pricing/presentation/test/`).
  - S9 FE deferred: Sales confirmation surface chưa có → giữ `todo`.



## Definition of Done — E2E

- [ ] ERP DI uses real pricing startup/module through mediator.
- [ ] Tenant/access and RPC boundary are exercised.
- [ ] `melos run test`, ERP tests and harness verification pass.



## Common completion

- [ ] US FR/BR/EC/SCN read and traceability rows updated.
- [ ] No page > 500 lines, inline dialog or direct PostgREST write.
- [ ] GitNexus `detect_changes()` run before commit; no commit if capability unavailable.

Lane status is determined by the artifacts and verification owned by that lane. Workspace-wide failures outside a lane are recorded in `docs/harness/PROGRESS.md` as technical debt instead of holding a completed lane in `in_progress`.

## Where is the “BE” code?

| Artifact | Path |
| -------- | ---- |
| Domain / permissions | `modules/pricing/domain/` |
| Commands, queries, DTOs, `IPricingModule`, `FakePricingModule` | `modules/pricing/application/` |
| Gateways, RPC mappers, `PricingStartup` | `modules/pricing/infrastructure/` |
| SQL drafts (unapplied) | `supabase/migrations/_drafts/pricing_*.sql` (+ catalog/partner provider drafts) |
| ERP DI tạm (chưa Startup) | `apps/erp/.../in_memory_pricing_module.dart` |
