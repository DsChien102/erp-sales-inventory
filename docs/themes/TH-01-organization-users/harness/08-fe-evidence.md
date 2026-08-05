# TH-01 — FE evidence matrix

Checklist FE/E2E cho completion plan
[`TH-01-FE-COMPLETION-IMPLEMENTATION-PLAN-2026-07-31.md`](../TH-01-FE-COMPLETION-IMPLEMENTATION-PLAN-2026-07-31.md).

**Rule:** một lane FE chỉ `done` khi **mọi ô evidence** của row đó đã điền (không còn `—`) và khớp production route → `IIamModule` + widget/E2E IDs bắt buộc.

**Baseline 2026-07-31 (Task 0):** re-open theo audit; ô trống = thiếu evidence. Contract/BE không thuộc matrix này.

**D1 (S7):** `locked` (2026-07-31) — production source = `ListAssignableInvitationRolesQuery(tenantId)` → `AssignableRoleOptionDto(roleId, label)` via `IAssignableInvitationRoleReadPort` / `iam.list_assignable_invitation_roles`. FE binds `IamModuleInvitationRoleOptionsSource`. Không dùng `FakeRolesData` trong production.

**Ngoài scope matrix:** S4–S5 (`out_of_scope`); S16 (không re-review trong FE completion plan).

**Task 15 close (2026-07-31):** E2E vertical + failure paths landed; widget IDs gắn vào test names; production fake boundary đã đóng ở Task 14.

Required test IDs: plan § Required FE evidence IDs.

---

## Evidence matrix

| Slice | Production entrypoint | Query/Command evidence | Fake scenario test | Permission evidence | Error evidence | E2E test | Status |
| ----- | --------------------- | ---------------------- | ------------------ | ------------------- | -------------- | -------- | ------ |
| S0 | `/login` → `LoginPage` + IAM nav gating | `SignInCommand` rồi `GetCurrentSessionQuery` | `FakeIamScenario.authSignInOk` / `authInvalid` | session permissions cho menu (More gating) | invalid credentials stay on login | `e2e_th01_s0_session` | `done` |
| S1 | Tenant selector / `TenantContextCubit` | `ListAccessibleTenantsQuery`; honor `AccessibleTenantDto.isSelectable` | `tenantsMulti` / `tenantsProvisioning` | selector disable non-selectable | selector error không fail dashboard | `e2e_e05_u01_fr01_01` | `done` |
| S2 | Switch tenant confirmation | `SwitchTenantContextCommand` | `switchOk` / `switchDenied` | confirm sheet | isolated selector danger toast | `e2e_e05_u02_fr01_01` | `done` |
| S3 | Bootstrap / invalidation UI | `GetTenantContextQuery(bootstrapFromLastSelected)` | `bootstrapValid` / `bootstrapInvalid` / `contextInvalidated` | blocked bootstrap state | invalidation UI | `e2e_e05_u03_fr01_01` | `done` |
| S6 | `/more/users` members + invitations tabs | `ListTenantMembersQuery` / `ListInvitationsQuery` + cursor | `membersSearchOk` / `invitationsSearchOk` / `memberInvitationForbidden` | `tenant.member.*` list | forbidden empty | `e2e_e03_u01_fr01_01` | `done` |
| S7 | `/more/users/invite` | `ListAssignableInvitationRolesQuery` + `CreateInvitationCommand` | `inviteOk` (+ cubit conflict/delivery) | `tenant.member.invite` | conflict giữ form | `e2e_e03_u02_fr01_01` | `done` |
| S8 | `/invitation` opaque token (logged-out) | `InspectInvitationTokenQuery` + `AcceptInvitationCommand` / `RegisterFromInvitationCommand` / `DeclineInvitationCommand` | inspect/accept/register + `inspectInvalidNoLeak` | public (logged-out) | invalid generic; no token leak | `e2e_e03_u03_fr01_01` | `done` |
| S9 | `/more/users/invitations/:invitationId` | `GetInvitationQuery` + `ResendInvitationCommand` / `RevokeInvitationCommand` | `invitationResendOk` / STATE_CHANGED cubit | `tenant.member.invite` | STATE_CHANGED reload; terminal read-only | `e2e_e03_u04_fr01_01` | `done` |
| S10 | `/more/users/members/:membershipId` | `GetTenantMemberQuery` + deactivate / reactivate / remove | `memberDeactivateOk` / `memberLastOwnerProtected` | `tenant.member.status.update` / `tenant.member.remove` | LAST_OWNER_PROTECTED; STATE_CHANGED reload | `e2e_e03_u05_fr01_01` | `done` |
| S11 | `/more/readiness` | `GetTenantReadinessQuery` / `ActivateTenantCommand` (+ context sau success) | `readinessWarningOnly` / `readinessBlocked` / `activateReadinessBlocked` | `tenant.readiness.view` / `tenant.activate` | READINESS_BLOCKED; CTA ẩn khi blocked | `e2e_e01_u05_fr01_01` | `done` |
| S12 | `/more/organization-profile` (+ edit / legal) | `GetTenantQuery` / `UpdateTenantProfileCommand` / `UpsertLegalProfileCommand` | `tenantProfileUpdateOk` / `legalDuplicateWarning` / `tenantProfileStale` | `tenant.profile.*` / legal update | STATE_CHANGED reload; duplicate = success warning | `e2e_e02_u01_fr01_01` | `done` |
| S13 | `/more/audit-logs` (+ `/:auditLogId`) | `SearchTenantAuditLogsQuery` / `GetTenantAuditLogQuery` | `tenantAuditSearchOk` / `tenantAuditForbidden` / actor unavailable / redacted | `tenant.audit.view` | cross-tenant not-found; forbidden | `e2e_e02_u07_fr01_01` | `done` |
| S14 | `/more/my-account` (+ edit / reset) | identity CQRS + reset + `SignOutCommand` | `myAccountOk` / `passwordResetCompleteOk` / `signOutRemoteError` | self-service | remote sign-out warning | `e2e_e06_u01_fr01_01` | `done` |
| S15 | `apps/admin` platform users | `SearchPlatformUsersQuery` (cursor) / `GetPlatformUserQuery` + 4 lifecycle commands | no-N+1 / cursor / activation / password reset / suspend / restore / step-up | `IamPlatformPermissions.*` | RESOURCE_NOT_FOUND; STEP_UP; STATE_CHANGED | `e2e_e01_u01_fr01_01` | `done` |

---

## Required widget evidence IDs (target)

| Slice | Widget / Cubit test id | Location (Task 15) |
| ----- | ---------------------- | ------------------ |
| S0 | `wgt_th01_s0_login_session_sequence` | `apps/erp/test/features/auth/presentation/wgt_th01_s0_login_test.dart` |
| S1 | `wgt_e05_u01_fr01_01` | `apps/erp/test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart` |
| S2 | `wgt_e05_u02_fr01_01` | tenant_context + select organization sheet tests |
| S3 | `wgt_e05_u03_fr01_01` | `wgt_e05_tenant_context_test.dart` |
| S6 | `wgt_e03_u01_fr01_01` | `modules/iam/presentation/test/widgets/organization_users_page_test.dart` |
| S7 | `wgt_e03_u02_fr01_01` | `organization_invite_member_page_test.dart` |
| S8 | `wgt_e03_u03_fr01_01` | `apps/erp/test/features/auth/presentation/invitation/invitation_token_page_test.dart` |
| S9 | `wgt_e03_u04_fr01_01` | `organization_invitation_detail_page_test.dart` |
| S10 | `wgt_e03_u05_fr01_01`, `wgt_e03_u06_fr01_01` | `organization_member_detail_page_test.dart` |
| S11 | `wgt_e01_u04_fr01_01`, `wgt_e01_u05_fr01_01` | `modules/iam/presentation/test/readiness/tenant_readiness_page_test.dart` |
| S12 | `wgt_e02_u01_fr01_01`, `wgt_e02_u02_fr01_01`, `wgt_e02_u03_fr01_01` | profile / edit / legal widget tests |
| S13 | `wgt_e02_u07_fr01_01` | `organization_audit_logs_page_test.dart` |
| S14 | `wgt_e06_u01_fr01_01`–`wgt_e06_u04_fr01_01` | my_account / edit (+ E2E reset/logout IDs) |
| S15 | `wgt_e01_u01_fr01_01`, `wgt_e01_u02_fr01_01` | admin platform users/detail tests |

---

## D1 decision log

| Date | Decision | Status |
| ---- | -------- | ------ |
| 2026-07-31 | Cần production source `InvitationRoleOption(roleId, label)` trước Task 6. Đề xuất: `ListAssignableInvitationRolesQuery(tenantId)`. Không tự tạo query trong FE task. | `blocked` |
| 2026-07-31 | Owner khóa hướng 1: `ListAssignableInvitationRolesQuery` → `AssignableRoleOptionDto`; FE `IamModuleInvitationRoleOptionsSource`; draft RPC `iam.list_assignable_invitation_roles`. | `locked` |

---

## External blockers (Task 15)

| Check | Result |
| ----- | ------ |
| `bash scripts/ci/guard_presentation_size.sh` | exit ≠ 0 **chỉ** vì bốn catalog failures đã ghi Global Constraints (không IAM/TH-01) |
| `bash scripts/ci/guard_presentation_dialogs.sh` | exit `0` |
| `bash scripts/ci/guard_design_system_usage.sh` | exit `0` (enforced lane clean; monitored catalog/partner warnings ngoài TH-01) |
| `melos run codegen` / full `melos run test` | không bắt buộc re-run full monorepo trong Task 15 nếu focused suites pass; ghi khi CI chạy |

---

## Liên kết

- Roadmap: [04-slice-roadmap.md](04-slice-roadmap.md)
- Traceability: [05-traceability.md](05-traceability.md)
- Contracts: [07-api-contracts.md](07-api-contracts.md)

## Task 0 verification notes (2026-07-31)

| Check | Result |
| ----- | ------ |
| `bash scripts/ci/guard_theme_structure.sh` | exit `0` |
| `bash scripts/ci/guard_theme_traceability.sh` | exit `0` |
| `bash scripts/ci/guard_theme_contract_completeness.sh TH-01-organization-users` | **script không tồn tại trong repo** (được nhắc trong roadmap note / FE plan nhưng chưa ship vào `scripts/ci/` hay `verify_harness.sh`). Không block Task 0 docs; Contract/BE columns đã xác nhận không đổi bằng diff. |
