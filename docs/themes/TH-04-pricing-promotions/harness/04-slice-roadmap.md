# TH-04 EP02 — Slice roadmap

Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**S1/S2/S3/S5/S6/S7/S8/S9/S10 implementation baseline 2026-07-16 (cập nhật FE 2026-07-20; E2E Fake 2026-07-21):**
CONTRACT + **BE Dart** (domain / application / infrastructure / `PricingStartup` / gateway / tests) are `done` cho S1–S10.
**SQL vẫn chỉ là** `_drafts/` **— chưa promote / chưa apply lên DB** → E2E **applied RPC** vẫn future.
**FE EP02** (SG-01…SG-06): S1–S8 + S10 = `done`. S9 FE = `todo` (Sales confirmation surface). ERP DI tạm vẫn `InMemoryPricingModule`.
**E2E Fake harness** (plan B): S1–S8 + S10 = `done (Fake)` qua `pricing_e2e_harness.dart` + `e2e_e02_u`* — không thay DoD RPC. S9 Sales publisher E2E vẫn `blocked`; có mediator Fake smoke.


| #   | Slice                                                                   | Type               | Contract | BE   | FE   | E2E         | Parallel group | E2E blocked by       |
| --- | ----------------------------------------------------------------------- | ------------------ | -------- | ---- | ---- | ----------- | -------------- | -------------------- |
| S1  | [US-04](../Epic-02-customer-price-rules/US-04.md) — Create manual rule  | write              | done     | done | done | done        | —              | applied RPC (future) |
| S2  | [US-01](../Epic-02-customer-price-rules/US-01.md) — List/search/filter  | read               | done     | done | done | done        | A              | applied RPC (future) |
| S3  | [US-03](../Epic-02-customer-price-rules/US-03.md) — Detail/actions      | read               | done     | done | done | done        | A              | applied RPC (future) |
| S4  | [US-02](../Epic-02-customer-price-rules/US-02.md) — Choose add method   | presentation       | n/a      | n/a  | done | done        | A              | —                    |
| S5  | [US-06](../Epic-02-customer-price-rules/US-06.md) — Edit rule           | write              | done     | done | done | done        | B              | applied RPC (future) |
| S6  | [US-07](../Epic-02-customer-price-rules/US-07.md) — Disable             | write              | done     | done | done | done        | B              | applied RPC (future) |
| S7  | [US-08](../Epic-02-customer-price-rules/US-08.md) — Reenable/precheck   | write              | done     | done | done | done        | B              | applied RPC (future) |
| S8  | [US-05](../Epic-02-customer-price-rules/US-05.md) — Excel import        | workflow           | done     | done | done | done        | C              | applied RPC (future) |
| S9  | [US-09](../Epic-02-customer-price-rules/US-09.md) — Remember from Sales | cross-module write | done     | done | todo | **blocked** | C              | Sales publisher/UI   |
| S10 | [US-10](../Epic-02-customer-price-rules/US-10.md) — Activity history    | read               | done     | done | done | done        | C              | applied RPC (future) |


S9 CONTRACT + BE implementation plan: [2026-07-16-pricing-s9-remembered-price-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s9-remembered-price-contract-be.vi.md). SQL draft `011_pricing_remembered_price_from_order_s9.sql` is authored but **not applied**.

S10 CONTRACT + BE implementation plan: [2026-07-16-pricing-s10-activity-history-contract-be.vi.md](../../../superpowers/plans/2026-07-16-pricing-s10-activity-history-contract-be.vi.md). SQL draft `012_pricing_customer_price_rule_history_s10.sql` is authored but **not applied**. FE lane closed 2026-07-20 (`wgt_e02_u10_`* + Fake history scenarios). E2E Fake harness closed 2026-07-21; applied-RPC E2E vẫn future.

S8 FE/E2E hoàn thiện 2026-07-21: canonical template V1, tải file mẫu bằng bytes từ application, partial import, warning acknowledgement và cancel batch khi rời preview. Draft đã được user apply thủ công trên môi trường hiện tại nhưng applied-RPC manual verification vẫn chưa được automation ghi nhận.

SQL drafts EP02 được đánh số promote-order `001`…`015` trong `[supabase/migrations/_drafts/README.md](../../../../supabase/migrations/_drafts/README.md)`. Apply thủ công BR-07/09 rồi list-price live: `013` → `014` → `015`.

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
- E2E **applied RPC** (DoD đầy đủ): real `PricingStartup` + migrated DB; vẫn future khi SQL chưa promote.
- E2E **Fake harness** (lane hiện tại): ERP widget tests với `FakePricingModule` / `PricingE2eModule` + GoRouter — đóng flow/mediator mapping; không claim DoD RPC.



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



### Fake harness (current — plan B)

- [x] ERP tests override GetIt with Fake / `PricingE2eModule` (production DI vẫn `InMemoryPricingModule`).
- [x] Multi-page flows + primary error paths covered by `e2e_e02_u*` under `apps/erp/test/features/pricing/`.
- [x] Mapping matrix in [05-traceability.md](05-traceability.md) updated.
- [ ] S9 Sales publisher UI E2E remains blocked; mediator Fake smoke only.



### Applied RPC (future)

- [ ] ERP DI uses real pricing startup/module through mediator.
- [ ] Tenant/access and RPC boundary are exercised.
- [ ] `melos run test`, ERP tests and harness verification pass.



## Common completion

- [ ] US FR/BR/EC/SCN read and traceability rows updated.
- [ ] No page > 500 lines, inline dialog or direct PostgREST write.
- [ ] GitNexus `detect_changes()` run before commit; no commit if capability unavailable.

Lane status is determined by the artifacts and verification owned by that lane. Workspace-wide failures outside a lane are recorded in `docs/harness/PROGRESS.md` as technical debt instead of holding a completed lane in `in_progress`.

## Where is the “BE” code?


| Artifact                                                       | Path                                                                                        |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Domain / permissions                                           | `modules/pricing/domain/`                                                                   |
| Commands, queries, DTOs, `IPricingModule`, `FakePricingModule` | `modules/pricing/application/`                                                              |
| Gateways, RPC mappers, `PricingStartup`                        | `modules/pricing/infrastructure/`                                                           |
| SQL drafts (unapplied)                                         | `supabase/migrations/_drafts/00{1..15}_*.sql` (TH-04 EP02 ordered; xem `_drafts/README.md`) |
| ERP DI tạm (chưa Startup)                                      | `apps/erp/.../in_memory_pricing_module.dart`                                                |


