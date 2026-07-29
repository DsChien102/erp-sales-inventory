# TH-01 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application layer. Types sống trong `modules/iam/application/` (mở rộng theo slice).

Facade: `IIamModule` — mở rộng surface theo roadmap (hiện interim: sign-in/out, switch tenant, list members, assign role).

**Scaffold 2026-07-16:** Catalog + fake scenarios cho S-NOTIFY, EP-05 switch, EP-03 invite/accept. Các § còn lại bổ sung khi slice CONTRACT.

**Access control:** `@RequiresPermission` / `@RequiresTenant` / platform context — codegen `iam_access_metadata.g.dart`.

**Blocked codes (rút gọn):** xem [APPENDICES.md](../APPENDICES.md) §6.4 — `VALIDATION_ERROR`, `PERMISSION_DENIED`, `PLATFORM_PERMISSION_DENIED`, `TENANT_ACCESS_DENIED`, `STATE_CHANGED`, `INVITATION_*`, `LAST_OWNER_PROTECTED`, `READINESS_BLOCKED`, `SYSTEM_ERROR`, …

**HTTP/API product map:** [APPENDICES.md](../APPENDICES.md) §6.1 — harness dưới đây dùng **Dart CMD/Query symbols**.

---

## CMD catalog overview

| CMD | Symbol (target) | Type | Permission / actor | US |
| --- | --------------- | ---- | ------------------ | -- |
| — | Mutation RPC outbox → inbox → `SendEmailDeliveryCommand` | infra Process* + RPC | system / worker | S-NOTIFY |
| CMD-CTX-01 | `ListAccessibleTenantsQuery` | Query | Authenticated | EP-05/US-01 |
| CMD-CTX-02 | `SwitchTenantContextCommand` | Command | Authenticated | EP-05/US-02 |
| CMD-CTX-03 | `GetTenantContextQuery` | Query | Authenticated | EP-05/US-03 |
| CMD-INV-01 | `CreateInvitationCommand` | Command | `tenant.member.invite` | EP-03/US-02 |
| CMD-INV-02 | `ResendInvitationCommand` | Command | `tenant.member.invite` | EP-03/US-04 |
| CMD-INV-03 | `RevokeInvitationCommand` | Command | `tenant.member.invite` | EP-03/US-04 |
| CMD-INV-04 | `AcceptInvitationCommand` | Command | Verified invitee | EP-03/US-03 |
| CMD-INV-05 | `DeclineInvitationCommand` | Command | Invitee | EP-03/US-03 |
| CMD-INV-06 | `ListInvitationsQuery` | Query | `tenant.member.view` | EP-03/US-01 |
| CMD-MEM-01 | `ListTenantMembersQuery` | Query | `tenant.member.view` | EP-03/US-01 |
| CMD-MEM-02 | `ChangeMemberRoleCommand` | Command | `tenant.role.assign` | EP-04/US-03 |
| CMD-ROLE-01 | `ListSystemRolesQuery` | Query | `tenant.role.view` | EP-04/US-01 |
| CMD-TEN-01 | `GetTenantQuery` | Query | `tenant.view` | EP-02/US-01 |
| CMD-TEN-02 | `ActivateTenantCommand` | Command | Owner / `tenant.activate` | EP-01/US-05 |
| CMD-TEN-03 | `GetTenantReadinessQuery` | Query | `tenant.readiness.view` | EP-01/US-04 |
| CMD-PLT-01 | `SearchPlatformUsersQuery` | Query | `platform.user.view` | EP-01/US-01 |
| CMD-PLT-02 | `GetPlatformUserQuery` | Query | `platform.user.view` | EP-01/US-01 |
| CMD-PLT-03 | `SendActivationInvitationCommand` | Command | `platform.user.activation_invite.send` | EP-01/US-02 |
| CMD-PLT-04 | `RequestPlatformPasswordResetCommand` | Command | `platform.user.password_reset.initiate` | EP-01/US-02 |
| CMD-PLT-05 | `SuspendPlatformUserCommand` | Command | `platform.user.suspend` | EP-01/US-02 |
| CMD-PLT-06 | `RestorePlatformUserCommand` | Command | `platform.user.restore` | EP-01/US-02 |
| CMD-PLT-07 | `CreateTenantOnboardingCommand` | Command | `platform.tenant.create` | EP-01/US-03 |
| CMD-PLT-08 | `SearchPlatformTenantsQuery` | Query | `platform.tenant.view` | EP-02/US-08 |
| CMD-PLT-09 | `GetPlatformTenantQuery` | Query | `platform.tenant.view` | EP-02/US-08 |
| CMD-PLT-10 | `ListPlatformTenantMembersQuery` | Query | `platform.tenant.member.view` | EP-02/US-08 |
| CMD-PLT-11 | `SuspendPlatformTenantCommand` | Command | `platform.tenant.suspend` | EP-02/US-06 |
| CMD-PLT-12 | `RestorePlatformTenantCommand` | Command | `platform.tenant.restore` | EP-02/US-06 |
| CMD-PLT-13 | `TransferPlatformTenantOwnershipCommand` | Command | `platform.tenant.owner.transfer` | EP-02/US-09 |
| CMD-PLT-14 | `SearchPlatformAuditLogsQuery` | Query | `platform.audit.view` | EP-02/US-10 |
| CMD-PLT-15 | `GetPlatformAuditLogQuery` | Query | `platform.audit.view` | EP-02/US-10 |
| CMD-ID-01 | `GetMyIdentityProfileQuery` | Query | Authenticated (`@PublicAccess`) | EP-06/US-01 |
| CMD-ID-02 | `UpdateMyIdentityProfileCommand` | Command | Authenticated (`@PublicAccess`) | EP-06/US-02 |
| CMD-ID-03 | `RequestMyPasswordResetCommand` | Command | Authenticated (`@PublicAccess`) | EP-06/US-03 |
| CMD-ID-04 | `ResendMyPasswordResetCommand` | Command | Authenticated (`@PublicAccess`) | EP-06/US-03 |
| CMD-ID-05 | `VerifyMyPasswordResetCommand` | Command | Authenticated (`@PublicAccess`) | EP-06/US-03 |
| CMD-ID-06 | `CompleteMyPasswordResetCommand` | Command | Authenticated (`@PublicAccess`) | EP-06/US-03 |
| — | `SignOutCommand` (reuse) | Command | Authenticated (`@PublicAccess`) | EP-06/US-04 |

*(Bổ sung đầy đủ khi CONTRACT từng slice — không block scaffold.)*

---

## §S-NOTIFY — Notification delivery (Resend)

### Port / contract

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| Mutation RPC (invitation / activation / password reset) | business params + email fields | persist + `enqueue_outbox_message` (`iam.email.delivery_requested`, full payload) + optional outcome `queued` (same txn) | VALIDATION_ERROR |
| `FakeEmailDeliveryPort.enqueue` (FE/unit only) | `EnqueueEmailDeliveryRequest` | simulates RPC side effect → outcome status per scenario | — |
| `EmailDeliveryRequestedIntegrationEvent` → IE handler | outbox/inbox payload | `ICommandScheduler.enqueue(SendEmailDeliveryCommand, sourceEventId)` | — |
| `SendEmailDeliveryCommand` (internal command, worker) | same payload via serializer; for `password_reset_code`: calls `iam.peek_password_reset_delivery_code` (service_role) then renders code into email body; calls Resend then updates outcome | outcome `sent` / `failed` | SYSTEM_ERROR (worker `fail_internal_command`) |
| `IEmailDeliveryPort.getOutcomeByCorrelationId` / outcome RPCs | correlationId | `EmailDeliveryOutcomeDto` | — |

**Anti-pattern:** Dart `IIamOutboxClient` / port gọi `enqueue_outbox_message` — cấm; chỉ worker claim/complete/fail. **Cấm** plaintext code/token/password trong payload, `refs`, API response, audit, logs.

**Outcome RPCs (draft):** `iam.record_email_delivery_outcome`, `iam.get_email_delivery_outcome_by_correlation` — [`_drafts/iam_notify_email_delivery_outcome.sql`](../../../../supabase/migrations/_drafts/001_iam_notify_email_delivery_outcome.sql) (chưa promote).

**Templates (logical):** `activation_invitation`, `tenant_invitation`, `password_reset_code`, `security_notification`.

**Email CTA (tenant invite):** HTTPS App Link `https://{host}/i/{opaque}` — opaque map tới invitation; accept API dùng token trong body (xem §S8).

### Wire payload `iam.email.delivery_requested`

Envelope injected bởi `ProcessOutboxCommandHandler` nếu thiếu: `id`, `tenant_id`, `occurred_on`.

| Field | Required | Ghi chú |
| ----- | -------- | ------- |
| `template_id` | yes | `activation_invitation` \| `tenant_invitation` \| `password_reset_code` \| `security_notification` |
| `to_email` | yes | Resolve trong **mutation RPC** lúc enqueue (đọc `auth.users.email`) — worker không resolve |
| `correlation_id` | yes | UUID text; dùng track outcome |
| `outcome_id` | yes | UUID text; id row `email_delivery_outcomes` (optional `queued` insert cùng txn) |
| `locale` | no | default `vi` |
| `refs` | no | Opaque IDs only — **cấm** code/token/password; xem bảng refs theo template |
| `app_link_url` | no | HTTPS App Link CTA cho invite/activate |

**`tenant_id` platform sentinel:** `00000000-0000-0000-0000-000000000000` (= `EmailDeliveryConstants.platformTenantId`). Dùng cho mọi email không gắn tenant (activation, password reset). Worker/handler map sentinel → `tenantId: null` khi ghi outcome.

**`refs` per template:**

| template_id | refs keys |
| ----------- | --------- |
| `password_reset_code` | `{ "operation_id": "<uuid>", "user_id": "<uuid>" }` |
| `activation_invitation` | `{ "user_id": "<uuid>" }` + `app_link_url` |
| `tenant_invitation` | `{ "invitation_id": "<uuid>", "user_id": "<uuid>" }` + `app_link_url` |
| `security_notification` | opaque — tùy use-case |

**Code reset qua email (phương án worker-fetch):** SQL mutation enqueue **không** có code trong payload/refs; SQL lưu thêm cột `delivery_code` (plaintext, `service_role` only) trên `iam.password_reset_operations`. Worker (internal command) gọi RPC `iam.peek_password_reset_delivery_code(p_operation_id uuid) → text` trước khi render/send. Sau khi `complete_my_password_reset` hoặc hết hạn, RPC xóa/NULL `delivery_code`. Dart renderer đọc mã từ gateway response, không từ `refs`.

**Peek RPC contract:**

| RPC | Auth | Returns | Điều kiện |
| --- | ---- | ------- | --------- |
| `iam.peek_password_reset_delivery_code(p_operation_id uuid)` | `service_role` only | `text` (6-digit code) | operation chưa completed, chưa hết hạn; không xóa khi peek |

**Draft:** [`_drafts/014_iam_identity_self_service.sql`](../../../../supabase/migrations/_drafts/014_iam_identity_self_service.sql) (chưa promote).

### Fake scenarios (FE / BE unit)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `notify_queued_ok` | enqueue after create invitation | outcome `queued` |
| `notify_sent_ok` | provider success | outcome `sent` + messageId |
| `notify_failed` | Resend 5xx / reject | outcome `failed`; invitation vẫn `pending` |
| `notify_rate_limited` | provider 429 | outcome `failed` + retry hint |

---

## §S1 — EP-05/US-01 — List accessible tenants

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `ListAccessibleTenantsQuery` | (actor from context) | `List<AccessibleTenantDto>` (tenantId, name, roleLabel, status, isCurrent) | AUTHENTICATION_REQUIRED |

RPC: `iam.list_accessible_tenants()` (draft). `isCurrent` set in Dart handler from `ICurrentTenant`.

**DTO note:** `AccessibleTenantDto.status` uses domain `TenantLifecycleStatus` (`provisioning` \| `active` \| `suspended` \| `closed`). Draft [`002_iam_list_accessible_tenants.sql`](../../../../supabase/migrations/_drafts/002_iam_list_accessible_tenants.sql) constraint includes `provisioning`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenants_single` | one membership | one item current |
| `tenants_multi` | many active memberships | list + current marked |
| `tenants_suspended_disabled` | target suspended | item disabled |
| `tenants_provisioning` | provisioning tenant | item with `provisioning` status |

---

## §S2 — EP-05/US-02 — Switch tenant context

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SwitchTenantContextCommand` | `targetTenantId` | `TenantContextDto` | `TENANT_ACCESS_DENIED`, `TENANT_SUSPENDED`, `TENANT_CLOSED`, `VALIDATION_ERROR` |

**Not** `@RequiresTenant` — actor switches *to* target; server re-validates access.

**`TenantContextDto` fields:** `status` (`TenantContextStatus`: none \| valid \| invalidated), `tenantId`, `tenantName`, `roleLabel`, `permissions`, `tenantStatus` (`TenantLifecycleStatus`), `invalidationReason`, `blockedErrorCode`.

**Domain rules (validator):** `TargetTenantMustDifferFromCurrentRule` (when current known). Confirmation dialog is presentation-only (FR-02); dispatch implies confirm.

**Port:** `IIamAccessGateway.switchTenantContext(targetTenantId)`.

**RPC:** `iam.switch_tenant_context` — draft [`007_iam_switch_tenant_context.sql`](../../../../supabase/migrations/_drafts/007_iam_switch_tenant_context.sql). Replaces interim `SwitchActiveTenantCommand` for Group A (interim kept for backward compatibility).

On success BE also updates LastSelectedTenant via `IPlatformUserPreferencePort` (draft [`008_iam_user_preferences.sql`](../../../../supabase/migrations/_drafts/008_iam_user_preferences.sql)).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `switch_ok` | valid target | `status: valid` + new context |
| `switch_denied` | no membership | `TENANT_ACCESS_DENIED` |
| `switch_suspended` | suspended tenant | `TENANT_SUSPENDED` |
| `switch_closed` | closed tenant | `TENANT_CLOSED` |
| `switch_same_tenant` | target == current | `VALIDATION_ERROR` |

---

## §S3 — EP-05/US-03 + US-04 — LastSelectedTenant + invalidation

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetTenantContextQuery` | `bootstrapFromLastSelected` (bool, default false) | `TenantContextDto` | AUTHENTICATION_REQUIRED |

**Behavior (BE):**
- `bootstrapFromLastSelected: false` → validate current session tenant
- `bootstrapFromLastSelected: true` → read LastSelectedTenant preference → validate server-side → resolve or return `none` / `invalidated`
- **OQ-07 (open):** do **not** auto-select another tenant; return `status: none` so FE opens selector

**Preference port:** `IPlatformUserPreferencePort` (`getLastSelectedTenantId` / `setLastSelectedTenantId`) — preference ≠ access grant.

**Port:** `IIamAccessGateway.getValidatedTenantContext(sessionTenantId?)`.

**RPC:** `iam.get_tenant_context` — draft [`009_iam_get_tenant_context.sql`](../../../../supabase/migrations/_drafts/009_iam_get_tenant_context.sql). Preference RPCs: `iam.get_last_selected_tenant` / `iam.set_last_selected_tenant` ([`008_iam_user_preferences.sql`](../../../../supabase/migrations/_drafts/008_iam_user_preferences.sql)).

**US-04 invalidation:** no separate invalidate command — `TenantContextDto.status == invalidated` (+ `invalidationReason` / `blockedErrorCode`) for shared blocked state. Reasons: `membershipRemoved`, `membershipInactive`, `tenantSuspended`, `tenantClosed`, `accessDenied`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `bootstrap_valid` | preference still accessible | `status: valid` |
| `bootstrap_invalid` | preference lost access | `status: none` (OQ-07) |
| `context_invalidated` | membership/tenant change mid-session | `status: invalidated` + reason |
| `context_none` | no preference / no session tenant | `status: none` |

---

## §S7 — EP-03/US-02 — Create invitation

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `CreateInvitationCommand` | tenantId, inviteeEmail, initialRoleId, idempotencyKey | `InvitationDto` (pending, expiresAt, deliveryOutcome) | VALIDATION_ERROR, DUPLICATE_MEMBERSHIP, ROLE_NOT_ASSIGNABLE, NO_PERMISSION |

Side effect: §S-NOTIFY enqueue (`tenant_invitation` template) + App Link opaque.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `invite_ok` | new email + active role | pending invitation + delivery queued |
| `invite_duplicate_membership` | active member | DUPLICATE_MEMBERSHIP |
| `invite_delivery_failed` | Resend fail | invitation pending + delivery failed |

---

## §S8 — EP-03/US-03 — Accept / decline (App Link)

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `AcceptInvitationCommand` | **token** (body), actorUserId | MembershipDto + invitation accepted | INVITATION_EXPIRED, INVITATION_REVOKED, INVITATION_EMAIL_MISMATCH, TENANT_SUSPENDED, AUTHENTICATION_REQUIRED |
| `DeclineInvitationCommand` | **token** (body) | invitation declined | INVITATION_* |

**Deep-link handoff:** App đọc `/i/{opaque}` → resolve/session → POST accept/decline với token trong JSON body (không đặt token trên API query).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `accept_ok` | valid token + verified email match | membership active |
| `accept_email_mismatch` | wrong login email | INVITATION_EMAIL_MISMATCH |
| `accept_expired` | expired | INVITATION_EXPIRED |
| `decline_ok` | valid token | declined |

---

## §S15 — EP-01/US-01–US-03 — Platform User + onboarding

Platform-scoped (Admin App). Permission codes: `IamPlatformPermissions`. No `@RequiresTenant`.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchPlatformUsersQuery` | query?, status? | `List<PlatformUserSummaryDto>` | PLATFORM_PERMISSION_DENIED |
| `GetPlatformUserQuery` | userId | `PlatformUserDetailDto` (+ memberships) | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `SendActivationInvitationCommand` | userId | void (invitation resent) | PLATFORM_PERMISSION_DENIED, STATE_CHANGED |
| `RequestPlatformPasswordResetCommand` | userId | void (no credential returned) | PLATFORM_PERMISSION_DENIED, STATE_CHANGED |
| `SuspendPlatformUserCommand` | userId, reason | void | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, STATE_CHANGED |
| `RestorePlatformUserCommand` | userId | void | PLATFORM_PERMISSION_DENIED, STATE_CHANGED |
| `CreateTenantOnboardingCommand` | owner (`OnboardingOwnerInput`), organizationName, idempotencyKey, correlationId? | `TenantOnboardingResultDto` (tenant provisioning + owner) | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |

**Notes**
- Password-reset initiate only; Platform Admin never receives credentials (BR-01/BR-02).
- Onboarding is atomic in Theme 1; `@Idempotent(keyField: 'idempotencyKey')` — retry must not duplicate User/Tenant/Membership.
- Owner first role fixed `Chủ cửa hàng`; `is_owner=true` independent of role label.
- Side effect (new user / activation / reset): mutation RPC `enqueue_outbox_message` (`iam.email.delivery_requested`) — Dart must not enqueue outbox.
- Platform authz: `IamPermissionChecker` routes `platform.*` → `IPlatformAdminGateway.hasPlatformPermission` (no tenant). Queries enforce via RPC `iam.has_platform_permission`.

**RPCs (draft):**
- `iam.has_platform_permission` — [`_drafts/003_iam_platform_admin_authz.sql`](../../../../supabase/migrations/_drafts/003_iam_platform_admin_authz.sql)
- `iam.search_platform_users`, `iam.get_platform_user` — [`_drafts/004_iam_platform_users_read.sql`](../../../../supabase/migrations/_drafts/004_iam_platform_users_read.sql)
- `iam.suspend_platform_user`, `iam.restore_platform_user`, `iam.send_activation_invitation`, `iam.request_platform_password_reset` — [`_drafts/005_iam_platform_user_lifecycle.sql`](../../../../supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql)
- `iam.create_tenant_onboarding` — [`_drafts/006_iam_create_tenant_onboarding.sql`](../../../../supabase/migrations/_drafts/006_iam_create_tenant_onboarding.sql)
- New Platform User (`auth.users`) = Platform Identity boundary; interim gateway requires resolved `ownerUserId`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `users_search_ok` | query by email | matching summaries |
| `user_detail_ok` | known userId | detail + memberships |
| `user_forbidden_403` | missing `platform.user.view` | PLATFORM_PERMISSION_DENIED |
| `activation_resend_ok` | pendingActivation user | void success |
| `suspend_ok` | active user + reason | status → suspended |
| `restore_ok` | suspended user | status → active |
| `onboarding_existing_user_ok` | existing owner + org name | TenantOnboardingResultDto provisioning |
| `onboarding_new_user_ok` | new email + org name | result + isNewUser=true |
| `onboarding_retry_idempotent` | same idempotencyKey | same result, no duplicate |
| `onboarding_validation_error` | missing org name / invalid email | VALIDATION_ERROR |

---

## §S16 — EP-02/US-06, US-08–US-10 — Platform tenant admin / audit

Platform-scoped (Admin App). Permission codes: `IamPlatformPermissions`. No `@RequiresTenant`.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchPlatformTenantsQuery` | query?, status? | `List<PlatformTenantSummaryDto>` | PLATFORM_PERMISSION_DENIED |
| `GetPlatformTenantQuery` | tenantId | `PlatformTenantDetailDto` (+ members) | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `ListPlatformTenantMembersQuery` | tenantId | `List<PlatformTenantMemberDto>` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `SuspendPlatformTenantCommand` | tenantId, reason | void | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, STATE_CHANGED |
| `RestorePlatformTenantCommand` | tenantId | void | PLATFORM_PERMISSION_DENIED, STATE_CHANGED |
| `TransferPlatformTenantOwnershipCommand` | tenantId, newOwnerUserId, idempotencyKey | void | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, STATE_CHANGED |
| `SearchPlatformAuditLogsQuery` | query?, status? | `List<PlatformAuditLogSummaryDto>` | PLATFORM_PERMISSION_DENIED |
| `GetPlatformAuditLogQuery` | auditLogId | `PlatformAuditLogDetailDto` (redacted) | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |

**Notes**
- Tenant status uses domain `TenantLifecycleStatus` (`provisioning` \| `active` \| `suspended` \| `closed`).
- Closed tenant rejects suspend/restore/ownership transfer (US-06 BR-04, US-09 BR-02).
- Ownership transfer flips `is_owner` atomically; does **not** change `role` / `role_id` (US-09 BR-03/04).
- Transfer is retry-safe via `@Idempotent(keyField: 'idempotencyKey')`.
- Audit detail redacts credentials / tokens / verification codes (US-10 BR-03).
- Platform authz: `IamPermissionChecker` routes `platform.*` → `IPlatformAdminGateway.hasPlatformPermission`.

**RPCs (draft):**
- `iam.search_platform_tenants`, `iam.get_platform_tenant`, `iam.list_platform_tenant_members` — [`_drafts/010_iam_platform_tenants_read.sql`](../../../../supabase/migrations/_drafts/010_iam_platform_tenants_read.sql)
- `iam.suspend_platform_tenant`, `iam.restore_platform_tenant` — [`_drafts/011_iam_platform_tenant_lifecycle.sql`](../../../../supabase/migrations/_drafts/011_iam_platform_tenant_lifecycle.sql)
- `iam.transfer_platform_tenant_ownership` — [`_drafts/012_iam_platform_transfer_ownership.sql`](../../../../supabase/migrations/_drafts/012_iam_platform_transfer_ownership.sql)
- `iam.search_platform_audit_logs`, `iam.get_platform_audit_log` — [`_drafts/013_iam_platform_audit_read.sql`](../../../../supabase/migrations/_drafts/013_iam_platform_audit_read.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenants_search_ok` | query by name/code | matching summaries |
| `tenant_detail_ok` | known tenantId | detail + members |
| `tenant_forbidden_403` | missing `platform.tenant.view` | PLATFORM_PERMISSION_DENIED |
| `tenant_suspend_ok` | active tenant + reason | status → suspended |
| `tenant_restore_ok` | suspended tenant | status → active |
| `tenant_closed_reject` | closed tenant lifecycle action | STATE_CHANGED |
| `ownership_transfer_ok` | active member as new owner | one owner (`is_owner`) |
| `ownership_invalid_target` | non-member / invalid target | VALIDATION_ERROR |
| `audit_search_ok` | filter by title/action | matching summaries |
| `audit_forbidden_403` | missing `platform.audit.view` | PLATFORM_PERMISSION_DENIED |

---

## §S14 — EP-06/US-01–US-04 — My Account (Identity self-service)

Tenant App self-service. Actor: Authenticated Platform User. **No** TenantContext / Membership. Theme 1 orchestrates via `IIdentitySelfServiceGateway` — does not persist profile copy, codes, passwords, or session tokens.

Do **not** reuse Admin `RequestPlatformPasswordResetCommand` (`platform.user.password_reset.initiate`).

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetMyIdentityProfileQuery` | — | `MyIdentityProfileDto` | SYSTEM_ERROR / not authenticated |
| `UpdateMyIdentityProfileCommand` | firstName, lastName, phoneNumber?, avatarUrl? | `MyIdentityProfileDto` | VALIDATION_ERROR |
| `RequestMyPasswordResetCommand` | — | `PasswordResetOperationDto` (operationId, maskedEmail; **no** code) | VALIDATION_ERROR (unverified email), rate-limit |
| `ResendMyPasswordResetCommand` | operationId | `PasswordResetOperationDto` | RESET_CODE_EXPIRED, rate-limit |
| `VerifyMyPasswordResetCommand` | operationId, code | void | RESET_CODE_INVALID, RESET_CODE_EXPIRED, RESET_CODE_ATTEMPTS_EXCEEDED |
| `CompleteMyPasswordResetCommand` | operationId, newPassword | void (session kept) | PASSWORD_POLICY_VIOLATION, RESET_CODE_* |
| `SignOutCommand` | — | void | SYSTEM_ERROR (still clear local) |

**Notes**
- Email is read-only on profile form (US-01/US-02).
- Password reset = 6-digit in-app code after login — **not** magic link / App Link.
- Responses/logs never include password, hash, or verification code.
- After `CompleteMyPasswordResetCommand`, keep current session and return to profile (FR-05).
- Side effect (request/resend): mutation RPC `enqueue_outbox_message` (`iam.email.delivery_requested`, template `password_reset_code`) — Dart must not enqueue outbox.
- Avatar: nullable `avatarUrl` string only in S14 (OQ-10 upload deferred).

**RPCs (draft):**
- `iam.get_my_identity_profile`, `iam.update_my_identity_profile` — [`_drafts/iam_identity_self_service.sql`](../../../../supabase/migrations/_drafts/iam_identity_self_service.sql)
- `iam.request_my_password_reset`, `iam.resend_my_password_reset`, `iam.verify_my_password_reset`, `iam.complete_my_password_reset` — same draft

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `my_profile_ok` | open My Account | profile DTO (minh@gmail.com) |
| `my_profile_load_fail` | get profile | SYSTEM_ERROR |
| `update_profile_ok` | save edit form | updated profile |
| `update_validation_error` | empty first/last name | VALIDATION_ERROR |
| `reset_request_ok` | start reset | operationId + maskedEmail |
| `reset_code_invalid` | wrong 6-digit code | RESET_CODE_INVALID |
| `reset_code_expired` | expired operation | RESET_CODE_EXPIRED |
| `reset_attempts_exceeded` | too many verify tries | RESET_CODE_ATTEMPTS_EXCEEDED |
| `reset_password_policy` | short password | PASSWORD_POLICY_VIOLATION |
| `reset_complete_ok` | verify + complete | void success, session kept |
| `logout_ok` | confirm logout | SignOut clears session |

---

## Parallel notes

- FE có thể fake: **yes** sau CONTRACT (`FakeIamModule` + fake notification gateway).
- E2E invite cần S-NOTIFY BE hoặc test double ghi outcome.
- Admin platform CMDs: §S15 + §S16 CONTRACT — xem APPENDICES §6.1.3.
- S14 My Account: §S14 CONTRACT — xem APPENDICES §6.1.5.
