# TH-01 — Traceability

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e03/u02/fr01/SCN-01
Test id: scn_e03_u02_fr01_01 (BE), wgt_e03_u02_fr01_01 (FE), e2e_e03_u02_fr01_01 (E2E)
```

**Scaffold 2026-07-16:** Skeleton `todo`. Cập nhật row khi slice `in_progress`.

**Contract gaps convergence 2026-07-30:** CONTRACT rows cho mọi slice active khớp roadmap `Contract: done` + semantic guard TH-01. **S6–S9 BE: done** (real invitation read/command/acceptance/identity adapters). **S0/S13/S14 Contract+BE(+FE S14) closed** theo remediation Task 10 evidence. FE/E2E còn lại không đánh giá trong remediation này. S14 gộp một section (identity FE + account port/contract).

**2026-07-31 FE completion reopen:** FE (và E2E S0) statuses dưới đây khớp [04-slice-roadmap.md](04-slice-roadmap.md) + [08-fe-evidence.md](08-fe-evidence.md). CONTRACT/BE rows **không đổi**. S7 FE `blocked` (D1). S4–S5 giữ `out_of_scope` (không thêm FE row). S16 không reopen trong plan này.

**2026-09-21 defer invitation identity/membership:** CONTRACT Theme 1 thay vòng đời hybrid. Kỳ vọng QA mới chưa `done` cho đến khi Task 2–8 kiểm chứng. Ma trận (bullet — không dùng pipe-table để tránh xung đột guard Role):

- **Onboarding Owner bằng email mới** (Task 2–3, BE): Tenant provisioning + Owner Invitation pending; chưa có profile/Membership của Owner — `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`
- **Platform User chờ kích hoạt** (Task 5, FE): Email chỉ có Invitation không xuất hiện ở PA-D-01/PA-D-03; không còn filter pending hoặc action PA-O-02 — `apps/admin/test/features/users/presentation/pages/platform_users_page_test.dart`
- **Readiness giai đoạn provisioning** (Task 6, BE): Invitation Owner pending hợp lệ → đang chờ; không còn Invitation hợp lệ → “Lời mời hết hạn”; cả hai chặn kích hoạt — `modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart`
- **Danh sách/chi tiết Platform User** (Task 5, FE): Auth user thật vẫn hiển thị; email nằm ngay dưới tên — `apps/admin/test/features/users/presentation/pages/platform_user_detail_page_test.dart`
- **Owner Invitation** (Task 4, 7, BE): Chi tiết Tenant trên Admin hiển thị Owner pending nhưng không tăng member count — `modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart`
- **Gửi lại cùng email/đổi email** (Task 3, 7, BE): Reuse cùng `invitation_id`, token cũ vô hiệu, không tạo profile/Membership trước accept — `modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart`
- **Hai bottom sheet PA-SG-02** (Task 7, FE): Tenant `settingUp` + Invitation `pending`/`expired`: “Thao tác” chỉ có “Gửi lại email”; không mở sheet rỗng. Tenant `active`/`suspended`: không có “Gửi lại email”, vẫn có “Thay đổi chủ sở hữu” — `organization_actions_bottom_sheet_test.dart`, `owner_invitation_resend_sheet_test.dart`
- **Invitation thành viên** (Task 3, 8, FE): Lời mời pending chỉ ở khu vực Lời mời của Tenant App, không vào member list hay thao tác Invitation của Platform Admin — `apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart`
- **Chấp nhận lời mời** (Task 3, 8, E2E): Người nhận có email Auth đã xác minh được tạo profile thật + đúng một active Membership trong một transaction — `apps/erp/test/features/invitations/e2e_e03_u01_u06_test.dart`

---

Tổng product: **6 epic, 32 US** (2 Post-MVP) — [README.md](../README.md).

---

## S0 — Platform IAM baseline (session)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-01-PLATFORM | CONTRACT | §S0 | application | `SignInCommand<void>` / `SignOutCommand` / `IIamModule` | sign_in_command_handler_test | done |
| TH-01-PLATFORM | CONTRACT | §S0 | application | `GetCurrentSessionQuery` -> `SessionDto` | get_current_session_query_handler_test | done |
| TH-01-PLATFORM | BE | §S0 | infrastructure | `registerGeneratedIamHandlers`, `IamCommandPipeline` | iam_startup_test | done |
| TH-01-PLATFORM | BE | §S0 | infrastructure | `iam_access_metadata.g.dart` | iam_startup_test | done |
| TH-01-PLATFORM | FE | §S0 | presentation | Login: `SignInCommand` rồi `GetCurrentSessionQuery` trước navigate; IAM nav permission gating | wgt_th01_s0_login_session_sequence | done |
| TH-01-PLATFORM | E2E | §S0 | integration | sign in → session query → dashboard | e2e_th01_s0_session | done |

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
| FR-01.. | FE | §S1 | presentation | organization selector list via `TenantContextCubit` + FakeIam; honor `isSelectable` | wgt_e05_u01_fr01_01 | done |
| FR-01 | E2E | §S1 | integration | ERP via IIamModule | e2e_e05_u01_fr01_01 | done |

---

## S2 — EP-05 / US-02 — Switch tenant

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S2 | application + domain | `SwitchTenantContextCommand` + `TenantContextDto` + context rules | fake_iam_module_test | done |
| FR-01.. | BE | §S2 | application + infrastructure + draft SQL | handler + preference + `iam.switch_tenant_context` | scn_e05_u02_fr01_01 | done |
| FR-01.. | FE | §S2 | presentation | confirmation + `onConfirmSwitch` → `SwitchTenantContextCommand`; isolated selector errors | wgt_e05_u02_fr01_01 | done |
| FR-01 | E2E | §S2 | integration | switch + reload | e2e_e05_u02_fr01_01 | done |

---

## S3 — EP-05 / US-03 + US-04 — LastSelectedTenant + invalidation

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03/04 | CONTRACT | §S3 | application + domain | `GetTenantContextQuery` + `IPlatformUserPreferencePort` + invalidation fields | fake_iam_module_test | done |
| FR-01.. | BE | §S3 | application + infrastructure + draft SQL | handler + preference + `iam.get_tenant_context` | scn_e05_u03_fr01_01 | done |
| FR-01.. | FE | §S3 | presentation | bootstrap + blocked state (`TenantContextCubit`); non-selectable tenants | wgt_e05_u03_fr01_01 | done |
| FR-01 | E2E | §S3 | integration | bootstrap + invalidate | e2e_e05_u03_fr01_01 | done |

---

## S6 — EP-03 / US-01 — List members & invitations

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S6 | application | `ListTenantMembersQuery` / `ListInvitationsQuery` / `GetInvitationQuery` + DTOs | scn_e03_u01_members_invitations_contract_test | done |
| FR-01.. | BE | §S6 | application + infrastructure | `SupabaseIamAccessGateway.listTenantMembers` (`iam.list_tenant_members` JSON page); `SupabaseTenantInvitationReadPort` (`iam.list_tenant_invitations` / `iam.get_tenant_invitation`) | iam_tenant_member_read_sql_contract_test / supabase_iam_access_gateway_member_read_test / iam_tenant_invitation_read_sql_contract_test / supabase_tenant_invitation_read_port_test / iam_runtime_wiring_test | done |
| FR-01.. | FE | §S6 | presentation | members/invitations tabs via Cubit + `IIamModule` (no production `FakeUsersData`) | wgt_e03_u01_fr01_01 | done |
| FR-01 | E2E | §S6 | integration | list → filter → detail | e2e_e03_u01_fr01_01 | done |

---

## S7 — EP-03 / US-02 — Invite member

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S7 | application | `CreateInvitationCommand` + fake scenarios | scn_e03_u02_create_invitation_contract_test | done |
| FR-01.. | BE | §S7 | infrastructure | `SupabaseTenantInvitationCommandGateway` + draft `017_iam_tenant_invitation_create.sql` (persisted delivery projection) | scn_e03_u02_create_invitation_contract_test / iam_tenant_invitation_create_sql_contract_test / supabase_tenant_invitation_command_gateway_test | done |
| FR-01.. | FE | §S7 | presentation | invite form + assignable role source (D1) | wgt_e03_u02_fr01_01 | done |
| FR-01 | E2E | §S7 | integration | invite + delivery outcome | e2e_e03_u02_fr01_01 | done |

---

## S8 — EP-03 / US-03 — Accept / decline (manual opaque token)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S8 | application | `InspectInvitationTokenQuery` / `RegisterFromInvitationCommand` / `AcceptInvitationCommand` / `DeclineInvitationCommand` | scn_e03_u03_invitation_acceptance_contract_test | done |
| FR-01.. | BE | §S8 | infrastructure | `SupabaseTenantInvitationAcceptancePort` + `SupabaseInvitationIdentityAdapter` (Auth signUp + profile sync; fail closed without verified session) | scn_e03_u03_invitation_acceptance_contract_test / iam_tenant_invitation_acceptance_sql_contract_test / supabase_tenant_invitation_acceptance_port_test / supabase_invitation_identity_adapter_test / iam_runtime_wiring_test | done |
| FR-01.. | FE | §S8 | presentation | logged-out token entry → locked-email login/registration | wgt_e03_u03_fr01_01 | done |
| FR-01 | E2E | §S8 | integration | manual token → existing/new account → Membership | e2e_e03_u03_fr01_01 | done |

---

## S9 — EP-03 / US-04 — Resend / revoke invitation

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §S9 | application | `ResendInvitationCommand` / `RevokeInvitationCommand` | scn_e03_u04_resend_revoke_invitation_contract_test | done |
| FR-01.. | BE | §S9 | infrastructure | `SupabaseTenantInvitationCommandGateway` + draft `018_iam_tenant_invitation_resend_revoke.sql` (resend updates delivery projection; revoke preserves) | scn_e03_u04_resend_revoke_invitation_contract_test / iam_tenant_invitation_resend_revoke_sql_contract_test / supabase_tenant_invitation_command_gateway_test | done |
| FR-01.. | FE | §S9 | presentation | resend / revoke via Cubit + `expectedVersion` + idempotency | wgt_e03_u04_fr01_01 | done |
| FR-01 | E2E | §S9 | integration | resend + revoke | e2e_e03_u04_fr01_01 | done |

---

## S10 — EP-03 / US-05 + US-06 — Membership status / remove

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05/06 | CONTRACT | §S10 | application + domain | `DeactivateMembershipCommand` / `ReactivateMembershipCommand` / `RemoveMembershipCommand` / `GetTenantMemberQuery` + `TenantMembership` | tenant_membership_test | done |
| FR-01.. | BE | §S10 | application + infrastructure | handlers + gateways + draft `014_iam_tenant_membership_lifecycle.sql` | scn_e03_u05_fr01_01 | done |
| FR-01.. | FE | §S10 | presentation | member detail lifecycle via Cubit + `IIamModule` (no S5 fake role actions) | wgt_e03_u05_fr01_01 / wgt_e03_u06_fr01_01 | done |
| FR-01 | E2E | §S10 | integration | deactivate / remove | e2e_e03_u05_fr01_01 | done |

---

## S12 — EP-02 / US-01–US-03 — Profile + Legal Profile

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01–03 | CONTRACT | §S12 | application + domain | `GetTenantQuery` / `UpdateTenantProfileCommand` / `UpsertLegalProfileCommand` + DTOs | scn_e02_u01 | done |
| FR-01.. | BE | §S12 | application + infrastructure | handlers + gateways + draft `015_iam_tenant_profile_legal.sql` | scn_e02_u01 | done |
| FR-01.. | FE | §S12 | presentation | tenant profile + legal via Query/Command (no mock toast-only) | wgt_e02_u01_fr01_01 / wgt_e02_u02_fr01_01 / wgt_e02_u03_fr01_01 | done |
| FR-01 | E2E | §S12 | integration | profile update + legal upsert | e2e_e02_u01_fr01_01 | done |

---

## S11 — EP-01 / US-04 + US-05 — Readiness + activate Tenant

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04/05 | CONTRACT | §S11 | application | `GetTenantReadinessQuery` / `ActivateTenantCommand` + DTOs | scn_e01_u04_u05 | done |
| FR-01.. | BE | §S11 | application + infrastructure | handlers + gateways + draft `016_iam_tenant_readiness_activate.sql` + `iam.get_auth_user_snapshot` | scn_e01_u04_u05 / iam_tenant_readiness_sql_contract / iam_auth_user_snapshot_sql_contract | done |
| FR-01.. | FE | §S11 | presentation | readiness + activate UI | wgt_e01_u04_fr01_01 / wgt_e01_u05_fr01_01 | done |
| FR-01 | E2E | §S11 | integration | activate provisioning tenant | e2e_e01_u05_fr01_01 | done |

---

## S13 — EP-02 / US-07 — Tenant audit history

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-07 | CONTRACT | §S13 | application | `SearchTenantAuditLogsQuery(fromUtc,toUtc,...)` / `GetTenantAuditLogQuery` + DTOs | scn_e02_u07 | done |
| FR-01.. | BE | §S13 | application + infrastructure | handlers + `SupabaseTenantAuditReadPort` + `iam.search/get_tenant_audit_log` on `iam.audit_logs` | scn_e02_u07 / iam_audit_read_sql_contract | done |
| FR-01.. | FE | §S13 | presentation | tenant audit search/detail via Query (redaction UX) | wgt_e02_u07_fr01_01 | done |
| FR-01 | E2E | §S13 | integration | search + detail | e2e_e02_u07_fr01_01 | done |

---

## S14 — EP-06 / US-01–US-04 — My Account

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01–04 | CONTRACT | §S14 | application | `GetMyIdentityProfileQuery` / `UpdateMyIdentityProfileCommand` / `RequestMyPasswordResetCommand` / `ResendMyPasswordResetCommand` / `VerifyMyPasswordResetCommand` / `CompleteMyPasswordResetCommand` / `SignOutCommand` | scn_e06_u01_u02_u03_my_account_test / iam_contract_fake_scenario_matrix_test | done |
| FR-01..03 | BE | §S14 | application + infrastructure | `SupabasePlatformIdentitySelfServiceAdapter` + `IPlatformIdentitySelfServicePort` (identity-only CQRS) | scn_e06_u01_u02_u03_my_account_test / supabase_platform_identity_self_service_adapter_test | done |
| FR-04 | BE | §S14 | application | `SignOutCommandHandler` local clear in `finally` + remote warning contract | scn_e06_u01_u02_u03_my_account_test | done |
| FR-01.. | FE | §S14 | presentation | My Account / Edit / Reset: single Cubit owners + reset retry + remote sign-out warning | wgt_e06_u01_fr01_01–wgt_e06_u04_fr01_01 | done |
| FR-01 | E2E | §S14 | integration | ERP via FakeIamModule / IIamModule | e2e_e06_u01_fr01_01_my_account_test | done |

---

## S15 — EP-01 / US-01–US-03 — Platform User + onboarding

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S15 | application | `SearchPlatformUsersQuery` / `GetPlatformUserQuery` + DTOs | fake_iam_module_test | done |
| US-02 | CONTRACT | §S15 | application | `SendActivationInvitationCommand` / `RequestPlatformPasswordResetCommand` / `SuspendPlatformUserCommand` / `RestorePlatformUserCommand` | fake_iam_module_test | done |
| US-03 | CONTRACT | §S15 | application | `CreateTenantOnboardingCommand` + `OnboardingOwnerInput` / `TenantOnboardingResultDto` | fake_iam_module_test | done |
| FR-01.. | BE | §S15 | application + infrastructure + draft SQL | handlers + `IPlatformAdminGateway` + RPCs | scn_e01_u01_fr01_01 / scn_e01_u02_fr01_01 / scn_e01_u03_fr01_01 | done |
| FR-01.. | FE | §S15 | presentation | apps/admin platform users: cursor pagination, detail errors, 4 lifecycle actions | wgt_e01_u01_fr01_01 / wgt_e01_u02_fr01_01 | done |
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
