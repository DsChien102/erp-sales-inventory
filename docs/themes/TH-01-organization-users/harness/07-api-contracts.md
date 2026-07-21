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

*(Bổ sung đầy đủ khi CONTRACT từng slice — không block scaffold.)*

---

## §S-NOTIFY — Notification delivery (Resend)

### Port / contract

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| Mutation RPC (invitation / activation) | business params + email fields | persist + `enqueue_outbox_message` (`iam.email.delivery_requested`) + optional outcome `queued` (same txn) | VALIDATION_ERROR |
| `FakeEmailDeliveryPort.enqueue` (FE/unit only) | `EnqueueEmailDeliveryRequest` | simulates RPC side effect → outcome status per scenario | — |
| `EmailDeliveryRequestedIntegrationEvent` → IE handler | outbox/inbox payload | `ICommandScheduler.enqueue(SendEmailDeliveryCommand, sourceEventId)` | — |
| `SendEmailDeliveryCommand` (internal command, worker) | same payload via serializer; handler calls Resend then updates outcome | outcome `sent` / `failed` | SYSTEM_ERROR (worker `fail_internal_command`) |
| `IEmailDeliveryPort.getOutcomeByCorrelationId` / outcome RPCs | correlationId | `EmailDeliveryOutcomeDto` | — |

**Anti-pattern:** Dart `IIamOutboxClient` / port gọi `enqueue_outbox_message` — cấm; chỉ worker claim/complete/fail.

**Outcome RPCs (draft):** `iam.record_email_delivery_outcome`, `iam.get_email_delivery_outcome_by_correlation` — [`_drafts/iam_notify_email_delivery_outcome.sql`](../../../../supabase/migrations/_drafts/iam_notify_email_delivery_outcome.sql) (chưa promote).

**Templates (logical):** `activation_invitation`, `tenant_invitation`, `password_reset_code`, `security_notification`.

**Email CTA (tenant invite):** HTTPS App Link `https://{host}/i/{opaque}` — opaque map tới invitation; accept API dùng token trong body (xem §S8).

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

## Parallel notes

- FE có thể fake: **yes** sau CONTRACT (`FakeIamModule` + fake notification gateway).
- E2E invite cần S-NOTIFY BE hoặc test double ghi outcome.
- Admin platform CMDs: §S15 CONTRACT done — xem APPENDICES §6.1.3.
