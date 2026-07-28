# TH-01 — Traceability

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e03/u02/fr01/SCN-01
Test id: scn_e03_u02_fr01_01 (BE), wgt_e03_u02_fr01_01 (FE), e2e_e03_u02_fr01_01 (E2E)
```

**Scaffold 2026-07-16:** Skeleton `todo`. Cập nhật row khi slice `in_progress`.

Contracts: [07-api-contracts.md](07-api-contracts.md)

Tổng product: **6 epic, 32 US** (2 Post-MVP) — [README.md](../README.md).

---

## Platform — IAM codegen

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-01-PLATFORM | BE | S0 | infrastructure | `registerGeneratedIamHandlers`, `IamCommandPipeline` | iam_startup_test | done |
| TH-01-PLATFORM | BE | S0 | infrastructure | `iam_access_metadata.g.dart` | iam_startup_test | done |

---

## S-NOTIFY — Resend delivery port

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| S-NOTIFY | CONTRACT | §S-NOTIFY | application | delivery request port / DTO | fake_email_delivery_port_test | done |
| S-NOTIFY | BE | §S-NOTIFY | infrastructure | Internal command + Resend + outcome | scn_notify_01 / scn_notify_02 | done |

---

## S1 — EP-05 / US-01 — List accessible tenants

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S1 | application + domain | `ListAccessibleTenantsQuery` + `AccessibleTenantDto` (`TenantLifecycleStatus`) | scn_e05_u01_fr01_01 | done |
| FR-01.. | BE | §S1 | application + infrastructure + draft SQL | handler + `list_accessible_tenants` RPC | scn_e05_u01_fr01_01 | done |
| FR-01.. | FE | §S1 | presentation | organization selector list via `TenantContextCubit` + FakeIam | wgt_e05_u01_fr01_01 | done |
| FR-01 | E2E | §S1 | integration | ERP via IIamModule | e2e_e05_u01_fr01_01 | done |

---

## S2 — EP-05 / US-02 — Switch tenant

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S2 | application + domain | `SwitchTenantContextCommand` + `TenantContextDto` + context rules | fake_iam_module_test | done |
| FR-01.. | BE | §S2 | application + infrastructure + draft SQL | handler + preference + `iam.switch_tenant_context` | scn_e05_u02_fr01_01 | done |
| FR-01.. | FE | §S2 | presentation | confirmation + `onConfirmSwitch` → `SwitchTenantContextCommand` | wgt_e05_u02_fr01_01 | done |
| FR-01 | E2E | §S2 | integration | switch + reload | e2e_e05_u02_fr01_01 | done |

---

## S3 — EP-05 / US-03 + US-04 — LastSelectedTenant + invalidation

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03/04 | CONTRACT | §S3 | application + domain | `GetTenantContextQuery` + `IPlatformUserPreferencePort` + invalidation fields | fake_iam_module_test | done |
| FR-01.. | BE | §S3 | application + infrastructure + draft SQL | handler + preference + `iam.get_tenant_context` | scn_e05_u03_fr01_01 | done |
| FR-01.. | FE | §S3 | presentation | bootstrap + blocked state (`TenantContextCubit`) | wgt_e05_u03_fr01_01 | done |
| FR-01 | E2E | §S3 | integration | bootstrap + invalidate | e2e_e05_u03_fr01_01 | done |

---

## S7 — EP-03 / US-02 — Invite member

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S7 | application | `CreateInvitationCommand` | fake_iam_module_test | todo |
| FR-01.. | BE | §S7 | application | handler + email delivery enqueue | scn_e03_u02_fr01_01 | todo |
| FR-01.. | FE | §S7 | presentation | invite form | wgt_e03_u02_fr01_01 | done |
| FR-01 | E2E | §S7 | integration | invite + delivery outcome | e2e_e03_u02_fr01_01 | todo |

---

## S8 — EP-03 / US-03 — Accept / decline (App Link)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S8 | application | `AcceptInvitationCommand` / `DeclineInvitationCommand` | fake_iam_module_test | todo |
| FR-01.. | BE | §S8 | application | accept atomic + membership | scn_e03_u03_fr01_01 | todo |
| FR-01.. | FE | §S8 | presentation | deep-link surface → POST body | wgt_e03_u03_fr01_01 | todo |
| FR-01 | E2E | §S8 | integration | App Link handoff | e2e_e03_u03_fr01_01 | todo |

---

## S9 — EP-03 / US-04 — Resend / revoke invitation

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §S9 | application + domain | `ResendInvitationCommand` / `RevokeInvitationCommand` | tenant_invitation_test | done |
| FR-01.. | BE | §S9 | application + infrastructure | handler + RPC | scn_e03_u04_fr01_01 | todo |
| FR-01.. | FE | §S9 | presentation | resend / revoke actions | wgt_e03_u04_fr01_01 | done |
| FR-01 | E2E | §S9 | integration | resend + revoke | e2e_e03_u04_fr01_01 | todo |

---

## S10 — EP-03 / US-05 + US-06 — Membership status / remove

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05/06 | CONTRACT | §S10 | application + domain | `DeactivateMemberCommand` / `ReactivateMemberCommand` / `RemoveMemberCommand` + `TenantMembership` + `SoleOwnerGuard` | tenant_membership_test | done |
| FR-01.. | BE | §S10 | application + infrastructure | handler + RPC | scn_e03_u05_fr01_01 | todo |
| FR-01.. | FE | §S10 | presentation | member detail lifecycle | wgt_e03_u05_fr01_01 | done |
| FR-01 | E2E | §S10 | integration | deactivate / remove | e2e_e03_u05_fr01_01 | todo |

---

## S15 — EP-01 / US-01–US-03 — Platform User + onboarding

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S15 | application | `SearchPlatformUsersQuery` / `GetPlatformUserQuery` + DTOs | fake_iam_module_test | done |
| US-02 | CONTRACT | §S15 | application | `SendActivationInvitationCommand` / `RequestPlatformPasswordResetCommand` / `SuspendPlatformUserCommand` / `RestorePlatformUserCommand` | fake_iam_module_test | done |
| US-03 | CONTRACT | §S15 | application | `CreateTenantOnboardingCommand` + `OnboardingOwnerInput` / `TenantOnboardingResultDto` | fake_iam_module_test | done |
| FR-01.. | BE | §S15 | application + infrastructure + draft SQL | handlers + `IPlatformAdminGateway` + RPCs | scn_e01_u01_fr01_01 / scn_e01_u02_fr01_01 / scn_e01_u03_fr01_01 | done |
| FR-01.. | FE | §S15 | presentation | apps/admin platform users + onboarding wizard | wgt_e01_u01_fr01_01 | done |
| FR-01 | E2E | §S15 | integration | Admin via IIamModule (US-01 list+detail, US-02 lifecycle, US-03 onboarding) | e2e_e01_u01_fr01_01 | done |

---

## S16 — EP-02 / US-06, US-08–US-10 — Platform tenant admin / audit

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-08 | CONTRACT | §S16 | application | `SearchPlatformTenantsQuery` / `GetPlatformTenantQuery` / `ListPlatformTenantMembersQuery` + DTOs | fake_iam_module_test | done |
| US-06 | CONTRACT | §S16 | application | `SuspendPlatformTenantCommand` / `RestorePlatformTenantCommand` | fake_iam_module_test | done |
| US-09 | CONTRACT | §S16 | application | `TransferPlatformTenantOwnershipCommand` | fake_iam_module_test | done |
| US-10 | CONTRACT | §S16 | application | `SearchPlatformAuditLogsQuery` / `GetPlatformAuditLogQuery` + DTOs | fake_iam_module_test | done |
| FR-01.. | BE | §S16 | application + infrastructure + draft SQL | handlers + gateway + RPCs `010`–`013` | scn_e02_u06_u08_u09 / scn_e02_u10 | done |
| FR-01.. | FE | §S16 | presentation | Admin Cubits orgs/detail/audit + `IIamModule` | wgt_e02_u08 / wgt_e02_u10 | done |
| FR-01 | E2E | §S16 | integration | Admin list→detail, suspend/restore, transfer, audit | e2e_e02_u08_fr01_01 | done |

---

## Các slice còn lại

Khi bắt đầu slice: copy bảng mẫu trên vào section `S{n} — EP-xx / US-yy`, điền FR rows, cập nhật Status. Post-MVP EP-02/US-04–05: **không** thêm row phase 1.
