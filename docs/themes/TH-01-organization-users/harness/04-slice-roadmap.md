# TH-01 — Slice roadmap

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a` | `out_of_scope`.

**Scaffold 2026-07-16:** Toàn bộ lane `todo`. Mở rộng `modules/iam/` từ interim. Phase 1 ưu tiên `apps/erp`; Admin App slices ở parallel group **Admin**.

**Contract gaps convergence 2026-07-30:** Mọi lane `Contract: done` (trừ S4–S5 `out_of_scope`) pass `scripts/ci/guard_theme_contract_completeness.sh TH-01-organization-users`.

**BE remediation 2026-07-30:** S6 owner projection và member/invitation
pagination dùng opaque cursor đã được sửa; S8 Auth failures được phân loại
theo provider error code; S10/S11 dùng owner invariant thống nhất và
tenant-first locking (`tenant → membership`) để bảo vệ owner cuối cùng và
tránh lock-order inversion với activation/ownership flows. SQL vẫn ở `_drafts/`;
không promote migration trong nhánh này. FE/E2E không đổi.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). Lane `out_of_scope` được giữ lại để traceability nhưng không tính vào tiến độ hoặc Definition of Done. **Prerequisite chỉ bind lane E2E** — FE fake và BE unit test chạy song song sau CONTRACT.

**2026-07-30 contract canonicalization:** S0 dùng sign-in rồi session query; S13 public range dùng `fromUtc`/`toUtc`; S14 dùng identity-only CQRS với locked DTOs; semantic guard enforce parity.

**2026-07-30 canonicalization remediation closed:** Semantic guard + S0/S13/S14 evidence gates pass; lane statuses dưới đây khớp fresh verification (Task 10). E2E lanes giữ nguyên nếu chưa đổi.


| #        | Slice                                                                                                                                                                                           | Type     | Contract     | BE           | FE           | E2E          | Parallel group | E2E blocked by                                                |
| -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------------ | ------------ | ------------ | ------------ | -------------- | ------------------------------------------------------------- |
| S0       | Platform IAM baseline (codegen, pipeline, session)                                                                                                                                              | platform | done         | done         | done         | n/a          | —              | —                                                             |
| S-NOTIFY | Notification delivery port + Resend adapter contract                                                                                                                                            | infra    | done         | done         | n/a          | n/a          | N              | —                                                             |
| S1       | [EP-05/US-01](../Epic-05-tenant-context/US-01.md) — List accessible tenants                                                                                                                     | read     | done         | done         | done         | done         | A              | —                                                             |
| S2       | [EP-05/US-02](../Epic-05-tenant-context/US-02.md) — Switch tenant context                                                                                                                       | write    | done         | done         | done         | done         | A              | S1                                                            |
| S3       | [EP-05/US-03](../Epic-05-tenant-context/US-03.md) + [US-04](../Epic-05-tenant-context/US-04.md) — LastSelectedTenant + invalidation                                                             | write    | done         | done         | done         | done         | A              | S2                                                            |
| S4       | [EP-04/US-01](../Epic-04-roles-permissions/US-01.md) + [US-02](../Epic-04-roles-permissions/US-02.md) — Role catalog + permissions                                                              | read     | out_of_scope | out_of_scope | out_of_scope | out_of_scope | B              | —                                                             |
| S5       | [EP-04/US-03](../Epic-04-roles-permissions/US-03.md) — Change member role                                                                                                                       | write    | out_of_scope | out_of_scope | out_of_scope | out_of_scope | B              | S4, S7                                                        |
| S6       | [EP-03/US-01](../Epic-03-membership-invitation/US-01.md) — List members & invitations                                                                                                           | read     | done         | done         | done         | todo         | C              | —                                                             |
| S7       | [EP-03/US-02](../Epic-03-membership-invitation/US-02.md) — Invite member (Resend)                                                                                                               | write    | done         | done         | done         | todo         | C              | S-NOTIFY                                                      |
| S8       | [EP-03/US-03](../Epic-03-membership-invitation/US-03.md) — Accept/decline (manual opaque token)                                                                                                 | write    | done         | done         | todo         | todo         | C              | S7                                                            |
| S9       | [EP-03/US-04](../Epic-03-membership-invitation/US-04.md) — Resend/revoke invitation                                                                                                             | write    | done         | done         | done         | todo         | C              | S7                                                            |
| S10      | [EP-03/US-05](../Epic-03-membership-invitation/US-05.md) + [US-06](../Epic-03-membership-invitation/US-06.md) — Membership status / remove                                                      | write    | done         | done         | done         | todo         | C              | S6                                                            |
| S11      | [EP-01/US-04](../Epic-01-platform-onboarding/US-04.md) + [US-05](../Epic-01-platform-onboarding/US-05.md) — Readiness + activate Tenant                                                         | write    | done         | done         | todo         | todo         | D              | S12 (Auth snapshot + readiness/activation adapters delivered) |
| S12      | [EP-02/US-01](../Epic-02-tenant-administration/US-01.md)–[US-03](../Epic-02-tenant-administration/US-03.md) — Profile + Legal Profile                                                           | write    | done         | done         | done         | todo         | D              | —                                                             |
| S13      | [EP-02/US-07](../Epic-02-tenant-administration/US-07.md) — Tenant audit history                                                                                                                 | read     | done         | done         | done         | todo         | D              | E2E flutter test (real ITenantAuditReadPort delivered)        |
| S14      | [EP-06/US-01](../Epic-06-my-account/US-01.md)–[US-04](../Epic-06-my-account/US-04.md) — My Account                                                                                              | write    | done         | done         | done         | done         | E              | —                                                             |
| S15      | [EP-01/US-01](../Epic-01-platform-onboarding/US-01.md)–[US-03](../Epic-01-platform-onboarding/US-03.md) — Platform User + onboarding                                                            | write    | done         | done         | done         | done         | Admin          | S-NOTIFY; apps/admin Melos                                    |
| S16      | [EP-02/US-06](../Epic-02-tenant-administration/US-06.md), [US-08](../Epic-02-tenant-administration/US-08.md)–[US-10](../Epic-02-tenant-administration/US-10.md) — Platform tenant admin / audit | write    | done         | done         | done         | done         | Admin          | S15                                                           |


**Loại khỏi phase 1:** [EP-02/US-04](../Epic-02-tenant-administration/US-04.md), [US-05](../Epic-02-tenant-administration/US-05.md) — Post-MVP.

**Out of scope roadmap hiện tại:** S4–S5 / EP-04 Role & Permission. Giữ nguyên slice, link US, group và dependency để traceability; không lập kế hoạch implement và không tính các lane này vào tiến độ.

### Parallel groups


| Group | Slices   | Ghi chú                                                     |
| ----- | -------- | ----------------------------------------------------------- |
| N     | S-NOTIFY | Contract trước EP-03 invite E2E                             |
| A     | S1–S3    | Gần `SwitchActiveTenant` interim                            |
| B     | S4–S5    | `out_of_scope` — giữ lại cho traceability, không scheduling |
| C     | S6–S10   | Membership + invitation + manual token confirmation         |
| D     | S11–S13  | Tenant App profile / readiness / audit                      |
| E     | S14      | Identity self-service                                       |
| Admin | S15–S16  | `apps/admin`; E2E sau Melos                                 |




## Definition of Done (per lane)



### CONTRACT

- [ ] ++Commands/Queries/DTOs exported trong++ `modules/iam/application/`
- [ ] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)



### BE

- [ ] Domain, handler, validator, gateway, draft SQL trong `_drafts/`
- [ ] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`
- [ ] `melos run codegen` + commit `generated/*.g.dart`
- [ ] Handler test `scn_*` pass



### FE

- [ ] UI + cubit wired `IIamModule` (hoặc facade mở rộng)
- [ ] Widget test `wgt_*` với `FakeIamModule` scenario
- [ ] Tenant App: `apps/erp`; Admin: `apps/admin` khi slice Admin



### E2E

- [ ] ERP DI real module; integration / flutter test
- [ ] `melos run test` + `./scripts/ci/verify_harness.sh` pass



### Chung

- [ ] US spec đã đọc (FR/BR/EC/SCN)
- [ ] Traceability rows trong [05-traceability.md](05-traceability.md) cập nhật
- [ ] Page ≤ 500 dòng



## Epic → module


| Epic  | Owner                                                                                     | Surface                                 |
| ----- | ----------------------------------------------------------------------------------------- | --------------------------------------- |
| EP-01 | iam (Platform User profile owned by IAM; Supabase Auth external authority)                | Admin + Tenant App (readiness/activate) |
| EP-02 | iam (IAM-owned audit history in `iam.audit_logs`)                                         | Tenant App + Admin                      |
| EP-03 | iam (+ Notification)                                                                      | Tenant App + invitation surface         |
| EP-04 | iam                                                                                       | Tenant App                              |
| EP-05 | iam (+ Preference)                                                                        | Tenant App                              |
| EP-06 | iam self-service via `IPlatformIdentitySelfServicePort`; Supabase Auth external authority | Tenant App                              |


