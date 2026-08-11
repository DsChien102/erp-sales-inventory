# TH-01 — API contracts (FE ↔ BE)

Source of truth giữa presentation và application layer. Types sống trong `modules/iam/application/` (mở rộng theo slice).

Facade: `IIamModule` — mở rộng surface theo roadmap (hiện interim: sign-in/out, switch tenant, list members, assign role).

**Scaffold 2026-07-16:** Catalog + fake scenarios cho S-NOTIFY, EP-05 switch, EP-03 invite/accept. Các § còn lại bổ sung khi slice CONTRACT.

**Access control:** `@RequiresPermission` / `@RequiresTenant` / platform context — codegen `iam_access_metadata.g.dart`.

**Blocked codes (rút gọn):** xem [APPENDICES.md](../APPENDICES.md) §6.4 — `VALIDATION_ERROR`, `PERMISSION_DENIED`, `PLATFORM_PERMISSION_DENIED`, `TENANT_ACCESS_DENIED`, `STATE_CHANGED`, `INVITATION_*`, `LAST_OWNER_PROTECTED`, `READINESS_BLOCKED`, `SYSTEM_ERROR`, …

**HTTP/API product map:** [APPENDICES.md](../APPENDICES.md) §6.1 — harness dưới đây dùng **Dart CMD/Query symbols**.

### Ownership (contract authority — đồng bộ với `01-domain-model` / `02-module-map`)

| Data/capability | Authority | IAM responsibility |
| --- | --- | --- |
| Login email, verified state, credential, recovery OTP, session | Supabase Auth | Read-only snapshot / orchestration |
| Platform User profile fields | IAM, `iam.platform_user_profiles` | Self-service owner |
| IAM audit history | IAM, `iam.audit_logs` | Append immutable, redact before persist, tenant/platform views |
| Email delivery | Notification/Resend | IAM publishes request and reads outcome projection |
| Tenant/Invitation/Membership/Role | IAM | Domain owner |

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
| CMD-INV-07 | `InspectInvitationTokenQuery` | Query | Anonymous, rate-limited | EP-03/US-03 |
| CMD-INV-08 | `RegisterFromInvitationCommand` | Command | Valid invitation proof | EP-03/US-03 |
| CMD-INV-09 | `GetInvitationQuery` | Query | `tenant.member.view` | EP-03/US-01 |
| CMD-MEM-01 | `ListTenantMembersQuery` | Query | `tenant.member.view` | EP-03/US-01 |
| CMD-MEM-02 | `ChangeMemberRoleCommand` | Command | `tenant.role.assign` | EP-04/US-03 (**out_of_scope** S5) |
| CMD-MEM-03 | `GetTenantMemberQuery` | Query | `tenant.member.view` | EP-03/US-05 |
| CMD-MEM-04 | `DeactivateMembershipCommand` | Command | `tenant.member.status.update` | EP-03/US-05 |
| CMD-MEM-05 | `ReactivateMembershipCommand` | Command | `tenant.member.status.update` | EP-03/US-05 |
| CMD-MEM-06 | `RemoveMembershipCommand` | Command | `tenant.member.remove` | EP-03/US-06 |
| CMD-ROLE-01 | `ListSystemRolesQuery` | Query | `tenant.role.view` | EP-04/US-01 (**out_of_scope** S4) |
| CMD-TEN-01 | `GetTenantQuery` | Query | `tenant.view` | EP-02/US-01 |
| CMD-TEN-02 | `ActivateTenantCommand` | Command | Owner / `tenant.activate` | EP-01/US-05 |
| CMD-TEN-03 | `GetTenantReadinessQuery` | Query | `tenant.readiness.view` | EP-01/US-04 |
| CMD-TEN-04 | `UpdateTenantProfileCommand` | Command | `tenant.profile.update` | EP-02/US-02 |
| CMD-TEN-05 | `UpsertLegalProfileCommand` | Command | `tenant.legal_profile.update` | EP-02/US-03 |
| CMD-AUD-01 | `SearchTenantAuditLogsQuery` | Query | `tenant.audit.view` | EP-02/US-07 |
| CMD-AUD-02 | `GetTenantAuditLogQuery` | Query | `tenant.audit.view` | EP-02/US-07 |
| CMD-ACC-01 | `GetMyIdentityProfileQuery` | Query | Authenticated | EP-06/US-01 |
| CMD-ACC-02 | `UpdateMyIdentityProfileCommand` | Command | Authenticated | EP-06/US-02 |
| CMD-ACC-03 | `RequestMyPasswordResetCommand` | Command | Authenticated | EP-06/US-03 |
| CMD-ACC-04 | `ResendMyPasswordResetCommand` | Command | Authenticated | EP-06/US-03 |
| CMD-ACC-05 | `VerifyMyPasswordResetCommand` | Command | Authenticated | EP-06/US-03 |
| CMD-ACC-06 | `CompleteMyPasswordResetCommand` | Command | Authenticated | EP-06/US-03 |
| CMD-ACC-08 | `RequestPasswordResetByEmailCommand` | Command | Anonymous | S0 forgot-password |
| CMD-ACC-09 | `ResendPasswordResetByEmailCommand` | Command | Anonymous | S0 forgot-password |
| CMD-ACC-10 | `VerifyPasswordResetByEmailCommand` | Command | Anonymous | S0 forgot-password |
| CMD-ACC-11 | `CompletePasswordResetByEmailCommand` | Command | Anonymous | S0 forgot-password |
| CMD-ACC-07 | `SignOutCommand` | Command | Authenticated | EP-06/US-04 |
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
| CMD-PLT-16 | `GetTenantOnboardingOperationQuery` | Query | `platform.tenant.create` | EP-01/US-03 |
| CMD-PLT-17 | `RetryTenantOnboardingOperationCommand` | Command | `platform.tenant.create` | EP-01/US-03 |

*(Bổ sung đầy đủ khi CONTRACT từng slice — không block scaffold.)*

---

## §S0 — Platform IAM baseline (session)

Auth/session surface for Tenant App + Admin. Actor từ Auth session / `IExecutionContext` — không nhận actor ID từ payload.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SignInCommand` | email, password | `void` | AUTHENTICATION_REQUIRED, VALIDATION_ERROR, SYSTEM_ERROR |
| `SignOutCommand` | — | `SignOutResultDto` | SYSTEM_ERROR (only when local clear fails) |
| `GetCurrentSessionQuery` | — | `SessionDto` | SESSION_EXPIRED, SYSTEM_ERROR |
| `SessionDto` | — | isAuthenticated, userId?, email?, tenantId?, role?, permissions | — |
| `IIamModule` | facade | presentation entry to CMD/Query surface | — |

**Notes**
- Session ownership: Supabase Auth authoritative; IAM mirrors presentation-safe snapshot only.
- `SESSION_EXPIRED` khi provider báo phiên hết hạn; FE xóa dữ liệu nhạy cảm và mở login.
- Fake scenarios cover happy/invalid/expired without leaking credentials.
- Sequencing rules:
  1. `SignInCommand` returns no session DTO.
  2. Consumer queries `GetCurrentSessionQuery` after successful sign-in.
  3. Absent session returns `SessionDto(isAuthenticated: false)` instead of `AUTHENTICATION_REQUIRED`.
  4. Expired session clears local state before returning `SESSION_EXPIRED`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `auth_sign_in_ok` | valid credentials | `void`; session becomes authenticated |
| `auth_invalid` | bad credentials | AUTHENTICATION_REQUIRED |
| `auth_session_ok` | active provider session | `SessionDto(isAuthenticated: true)` |
| `auth_session_expired` | expired provider session | SESSION_EXPIRED; local state cleared |
| `auth_sign_out_ok` | authenticated | `SignOutResultDto(localCleared: true, remoteSucceeded: true)` |
| `sign_out_remote_error` | provider logout fails | `SignOutResultDto(localCleared: true, remoteSucceeded: false)` |
| `password_reset_by_email_ok` | logged-out email | `PasswordResetRequestResultDto` (same shape whether email exists) |

### Logged-out forgot password (S0 companion — not S14)

S14 `RequestMy*` stays authenticated / `auth.uid()`. Login uses a **separate** public port.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `RequestPasswordResetByEmailCommand` | email | `PasswordResetRequestResultDto` | VALIDATION_ERROR, SYSTEM_ERROR |
| `ResendPasswordResetByEmailCommand` | operationId | `PasswordResetRequestResultDto` | RESET_RATE_LIMITED, RESET_CODE_INVALID, SYSTEM_ERROR |
| `VerifyPasswordResetByEmailCommand` | operationId, code | `PasswordResetVerifyResultDto` | RESET_CODE_INVALID, RESET_CODE_EXPIRED, RESET_CODE_ATTEMPTS_EXCEEDED, SYSTEM_ERROR |
| `CompletePasswordResetByEmailCommand` | operationId, newPassword | `PasswordResetCompletionResultDto(currentSessionRotated: false, otherSessionsRevoked: true)` | RESET_CODE_INVALID, PASSWORD_POLICY_VIOLATION, SYSTEM_ERROR |

**Notes**
- Anti-enumeration: request always returns the same DTO shape; unknown email does not enqueue mail.
- Verify/complete never return `RESOURCE_NOT_FOUND` for a missing operation (`RESET_CODE_INVALID`).
- Draft RPCs: `iam.begin/resend/verify/complete_password_reset_*_by_email` — [`_drafts/026_iam_password_reset_by_email.sql`](../../../../supabase/migrations/_drafts/026_iam_password_reset_by_email.sql).

---

## §S-NOTIFY — Notification delivery (Resend)

### Port / contract

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| Mutation RPC (invitation / activation) | business params + email fields | persist + `enqueue_outbox_message` (`iam.email.delivery_requested`) + optional outcome `queued` (same txn) | VALIDATION_ERROR |
| `FakeEmailDeliveryPort.enqueue` (FE/unit only) | `EnqueueEmailDeliveryRequest` | simulates RPC side effect → outcome status per scenario | — |
| `EmailDeliveryRequestedIntegrationEvent` → IE handler | outbox/inbox payload | `ICommandScheduler.enqueue(SendEmailDeliveryCommand, sourceEventId)` | — |
| `SendEmailDeliveryCommand` (internal command, worker) | same payload via serializer; handler calls Resend then updates outcome | `void` | SYSTEM_ERROR (worker `fail_internal_command`); outcome projection `sent`/`failed` |
| `IEmailDeliveryPort.getOutcomeByCorrelationId` / outcome RPCs | correlationId | `EmailDeliveryOutcomeDto` | — |

**Anti-pattern:** Dart `IIamOutboxClient` / port gọi `enqueue_outbox_message` — cấm; chỉ worker claim/complete/fail.

**Outcome RPCs (draft):** `iam.record_email_delivery_outcome`, `iam.get_email_delivery_outcome_by_correlation` — [`_drafts/001_iam_notify_email_delivery_outcome.sql`](../../../../supabase/migrations/_drafts/001_iam_notify_email_delivery_outcome.sql) (chưa promote).

**Templates (logical):** `activation_invitation`, `tenant_invitation`, `password_reset_code`, `security_notification`.

**Delivery outcome (OQ-08 closed):** asynchronous projection. Create/resend trả initial `queued`; detail/list đọc projection theo `correlationId`. Invitation lifecycle không đồng nhất với delivery outcome.

### Envelope v1 (`EmailDeliveryRequestedIntegrationEvent`)

```json
{
  "event_version": 1,
  "id": "uuid",
  "occurred_on": "UTC ISO-8601",
  "tenant_id": "uuid or null for platform scope",
  "template_id": "activation_invitation|tenant_invitation|password_reset_code|security_notification",
  "to_email": "canonical recipient",
  "correlation_id": "stable operation correlation",
  "outcome_id": "uuid",
  "locale": "vi",
  "refs": {}
}
```

- `fromPayload` **reject** thiếu `event_version`, `to_email`, `correlation_id` hoặc `outcome_id` bằng deterministic serialization error.
- Platform email: payload `tenant_id = null` (không sentinel domain UUID). Outbox/inbox partition vẫn dùng messaging uuid `00000000-0000-0000-0000-000000000000` vì cột tenant NOT NULL.
- Optional `secret_payload_ciphertext` for encrypted transient secrets only.

### Secret-material rule

- Domain tables chỉ lưu token hash.
- Raw token **không** đi trong `refs`, logs, audit hoặc normal JSON payload.
- Nếu async email bắt buộc mang raw token: encrypted transient `secret_payload_ciphertext` với key ngoài DB, retention ngắn, xóa sau terminal delivery.
- S-NOTIFY **không** được đánh lane token-carrying template `done` nếu encrypted transient channel chưa có implementation/test. Templates không mang raw secret (activation/password metadata-only) được phép dùng envelope thường.

**Email content (tenant invite):** Không CTA/link/URL. Email chỉ chứa backend-generated opaque token và hướng dẫn user đang đăng xuất tự mở app, copy/paste token; API chỉ nhận token trong body (xem §S8). Raw token delivery phải dùng `secret_payload_ciphertext`, không `app_link_url`.

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
| `ListAccessibleTenantsQuery` | (actor from context) | `List<AccessibleTenantDto>` | AUTHENTICATION_REQUIRED, SYSTEM_ERROR |

RPC: `iam.list_accessible_tenants()` (draft). `isCurrent` set in Dart handler from `ICurrentTenant`.

**DTO fields:** `tenantId`, `name`, `roleLabel`, `status` (`TenantLifecycleStatus`), `isCurrent`, `isSelectable`.

**Semantics**
- List chỉ gồm membership **active** của actor (inactive/removed membership không xuất hiện).
- `isSelectable == (status == active)` — provisioning / suspended / closed có thể hiện khi policy BE trả về nhưng **không** selectable.
- Closed tenant có thể xuất hiện như disabled (`isSelectable=false`).
- Identity inactive / unauthenticated → lỗi `AUTHENTICATION_REQUIRED` (RPC/`auth.uid()`), không trả list rỗng giả.

**DTO note:** Draft [`002_iam_list_accessible_tenants.sql`](../../../../supabase/migrations/_drafts/002_iam_list_accessible_tenants.sql) constraint includes `provisioning`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenants_single` | one membership | one item current + selectable |
| `tenants_multi` | many active memberships | list + current marked |
| `tenants_suspended_disabled` | target suspended | item `isSelectable=false` |
| `tenants_closed_disabled` | target closed | item `isSelectable=false` |
| `tenants_provisioning` | provisioning tenant | `isSelectable=false` |
| `tenants_excludes_inactive_membership` | inactive membership only | not in list |
| `tenants_identity_inactive` / `tenants_authentication_required` | no auth / identity inactive | AUTHENTICATION_REQUIRED |

---

## §S2 — EP-05/US-02 — Switch tenant context

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SwitchTenantContextCommand` | `targetTenantId` | `TenantContextDto` | `TENANT_ACCESS_DENIED`, `TENANT_SUSPENDED`, `TENANT_CLOSED`, `VALIDATION_ERROR`, `SYSTEM_ERROR` |

**Not** `@RequiresTenant` — actor switches *to* target; server re-validates access.

**`TenantContextDto` fields:** `status` (`TenantContextStatus`: none \| valid \| invalidated), `tenantId`, `tenantName`, `roleLabel`, `permissions`, `tenantStatus` (`TenantLifecycleStatus`), `invalidationReason`, `blockedErrorCode`.

**Domain rules (validator):** `TargetTenantMustDifferFromCurrentRule` (when current known). Confirmation dialog is presentation-only (FR-02); dispatch implies confirm.

**Atomicity / compensation (application handler):**

1. Validate target differs from current.
2. Resolve server context via `IIamAccessGateway.switchTenantContext`.
3. Establish new session context (`IIamSessionPort.establishAfterSignIn`).
4. Persist LastSelectedTenant (`IPlatformUserPreferencePort.setLastSelectedTenantId`).
5. Return success.

- Nếu bước 3 fail: preference cũ không đổi; throw `SYSTEM_ERROR`.
- Nếu bước 4 fail sau khi session đã đổi: restore session về tenant cũ rồi throw `SYSTEM_ERROR`.

**Port:** `IIamAccessGateway.switchTenantContext(targetTenantId)`.

**RPC:** `iam.switch_tenant_context` — draft [`007_iam_switch_tenant_context.sql`](../../../../supabase/migrations/_drafts/007_iam_switch_tenant_context.sql).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `switch_ok` | valid target | `status: valid` + preference + session |
| `switch_denied` | no membership | `TENANT_ACCESS_DENIED` |
| `switch_suspended` | suspended tenant | `TENANT_SUSPENDED` |
| `switch_closed` | closed tenant | `TENANT_CLOSED` |
| `switch_same_tenant` | target == current | `VALIDATION_ERROR` |
| `switch_session_failure` | session establish fails | `SYSTEM_ERROR`; preference unchanged |
| `switch_preference_failure` | preference persist fails | restore old session + `SYSTEM_ERROR` |

---

## §S3 — EP-05/US-03 + US-04 — LastSelectedTenant + invalidation

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetTenantContextQuery` | `bootstrapFromLastSelected` (bool, default false) | `TenantContextDto` | AUTHENTICATION_REQUIRED |

**Behavior (BE):**
- `bootstrapFromLastSelected: false` → validate current session tenant
- `bootstrapFromLastSelected: true` → read LastSelectedTenant preference → validate server-side → resolve or return `none` / `invalidated`
- **OQ-07 (closed):** LastSelectedTenant không hợp lệ → `TenantContextStatus.none`; **không** auto-select tenant khác; FE mở selector.

**Preference port:** `IPlatformUserPreferencePort` (`getLastSelectedTenantId` / `setLastSelectedTenantId`) — preference ≠ access grant.

**Port:** `IIamAccessGateway.getValidatedTenantContext(sessionTenantId?)`.

**RPC:** `iam.get_tenant_context` — draft [`009_iam_get_tenant_context.sql`](../../../../supabase/migrations/_drafts/009_iam_get_tenant_context.sql). Preference RPCs: `iam.get_last_selected_tenant` / `iam.set_last_selected_tenant` ([`008_iam_user_preferences.sql`](../../../../supabase/migrations/_drafts/008_iam_user_preferences.sql)).

**US-04 invalidation:** `TenantContextDto.status == invalidated` (+ `invalidationReason` / `blockedErrorCode`).

Reasons (`TenantContextInvalidationReason`):
```text
membershipRemoved
membershipInactive
tenantSuspended
tenantClosed
accessDenied
identityInactive
roleNoLongerAssignable
permissionsChanged
ownershipChanged
```

- Identity/membership/tenant denial → `invalidated` (session path) hoặc `none` (bootstrap OQ-07).
- `permissionsChanged` có thể trả **refreshed valid** context (không invalidated) khi server vẫn cấp access với permission set mới.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `bootstrap_valid` | preference still accessible | `status: valid` |
| `bootstrap_invalid` | preference lost access | `status: none` (OQ-07) |
| `context_invalidated` | membership/tenant change mid-session | `status: invalidated` + reason |
| `context_none` | no preference / no session tenant | `status: none` |
| `context_identity_inactive` | identity inactive mid-session | invalidated + `identityInactive` |
| `context_permissions_refreshed` | permission set changed, still allowed | `status: valid` (refreshed) |

---

## §S6 — EP-03/US-01 — List members & invitations

Tenant-scoped. Permission: `tenant.member.view`. Actor từ execution context.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `ListTenantMembersQuery` | tenantId, search?, status?, cursor?, limit? | `CursorPageDto<TenantMemberDto>` | PERMISSION_DENIED, VALIDATION_ERROR, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |
| `ListInvitationsQuery` | tenantId, search?, status?, cursor?, limit? | `CursorPageDto<InvitationSummaryDto>` | PERMISSION_DENIED, VALIDATION_ERROR, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |
| `GetInvitationQuery` | tenantId, invitationId | `InvitationDetailDto` | PERMISSION_DENIED, RESOURCE_NOT_FOUND, SYSTEM_ERROR |

### DTO fields

`TenantMemberDto`:
```text
membershipId, userId, displayName, email, roleId, roleLabel,
isOwner, status, joinedAt, version
```

`InvitationSummaryDto`:
```text
invitationId, inviteeEmail, initialRoleId, initialRoleLabel,
status, expiresAt, deliveryStatus, deliveryCorrelationId, version
```

`InvitationDetailDto` thêm: `createdAt`, `createdBy`, `lastSentAt`, `revokedAt`, `declinedAt`; không trả token/hash.

### Paging / filter semantics

- `limit` default `20`, max `100`.
- Search canonical email/name, trim; empty string = no filter.
- Member status: `active|inactive|removed`.
- Invitation status: `pending|accepted|declined|revoked|expired`.
- Expired-at-read không được biểu diễn như pending hợp lệ.
- Cursor opaque `(created_at,id)`.
- Cross-tenant / unknown invitation → `RESOURCE_NOT_FOUND`.

**RPCs (draft, unpromoted):**
- `iam.list_tenant_members(p_tenant_id, p_search, p_status, p_cursor, p_limit)` → JSON `{items, next_cursor}` — cursor owned by server as opaque `(created_at,id)` — [`_drafts/014_iam_tenant_membership_lifecycle.sql`](../../../../supabase/migrations/_drafts/014_iam_tenant_membership_lifecycle.sql)
- `iam.list_tenant_invitations(...)` / `iam.get_tenant_invitation(p_tenant_id, p_invitation_id)` — [`_drafts/019_iam_tenant_invitation_read.sql`](../../../../supabase/migrations/_drafts/019_iam_tenant_invitation_read.sql)
- Runtime: `SupabaseIamAccessGateway.listTenantMembers`, `SupabaseTenantInvitationReadPort` (never returns token/hash).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `members_search_ok` | search by name/email | matching members page |
| `members_filter_inactive` | status=inactive | inactive members only |
| `invitations_search_ok` | search invitee email | matching invitation summaries |
| `invitations_expired` | expired pending | status=expired (not pending) |
| `invitation_detail_ok` | known invitationId | InvitationDetailDto (no token) |
| `member_invitation_forbidden` | missing tenant.member.view | PERMISSION_DENIED |
| `member_invitation_cross_tenant_not_found` | foreign invitationId | RESOURCE_NOT_FOUND |

---

## §S7 — EP-03/US-02 — Create invitation

Tenant-scoped. Permission: `tenant.member.invite`. Actor/`createdBy` từ execution context/server — **không** nhận `actorUserId` trong command input.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `ListAssignableInvitationRolesQuery` | tenantId | `List<AssignableRoleOptionDto>` (`roleId`, `label`) — roles assignable for invite | PERMISSION_DENIED, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |
| `CreateInvitationCommand` | tenantId, inviteeEmail, initialRoleId, idempotencyKey | `InvitationDetailDto` (`status=pending`, `deliveryStatus` initial, no token/hash) | VALIDATION_ERROR, DUPLICATE_MEMBERSHIP, MEMBERSHIP_INACTIVE, INVITATION_PENDING_EXISTS, ROLE_NOT_ASSIGNABLE, IDEMPOTENCY_CONFLICT, PERMISSION_DENIED, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |

### Locked rules

- Role picker options load via `ListAssignableInvitationRolesQuery` (D1 locked) — không hardcode `FakeRolesData` trên production.
- Expiry = exactly **7 days** from server UTC creation time.
- Canonical email = trim + lowercase; empty/invalid → `VALIDATION_ERROR`.
- One pending invitation per `(tenantId, canonicalEmail)`.
- Inactive Membership for invitee email → `MEMBERSHIP_INACTIVE` (reactivate flow, không invite).
- Active Membership → `DUPLICATE_MEMBERSHIP`.
- Pending invitation already exists → `INVITATION_PENDING_EXISTS`.
- Inactive/deprecated role → `ROLE_NOT_ASSIGNABLE`.
- Same idempotency key + same payload → replay cùng `InvitationDetailDto`.
- Same key + different payload → `IDEMPOTENCY_CONFLICT`.
- Delivery failure **không** revoke invitation (lifecycle độc lập; OQ-08).

### Side effects (same txn)

1. Persist invitation: status `pending`, `token_hash = SHA-256(token)` only (no raw token column).
2. Generate 32-byte CSPRNG Base64URL token.
3. §S-NOTIFY `enqueue_outbox_message` template `tenant_invitation`; raw token only via optional `secret_payload_ciphertext` — never in `refs` / audit / logs.
4. Initial delivery outcome `queued` via `record_email_delivery_outcome`; response `deliveryStatus=queued` + `deliveryCorrelationId`.

**RPC draft:** `iam.create_tenant_invitation` — [`_drafts/017_iam_tenant_invitation_create.sql`](../../../../supabase/migrations/_drafts/017_iam_tenant_invitation_create.sql).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `invite_ok` | new email + active role | pending invitation + delivery queued |
| `invite_duplicate_membership` | active member | DUPLICATE_MEMBERSHIP |
| `invite_inactive_membership` | inactive member | MEMBERSHIP_INACTIVE |
| `invite_pending_exists` | pending invite same email | INVITATION_PENDING_EXISTS |
| `invite_role_not_assignable` | inactive/deprecated role | ROLE_NOT_ASSIGNABLE |
| `invite_delivery_failed` | email provider fail (async) | invitation still pending; deliveryStatus failed |
| `invite_idempotent_retry` | same key + payload | same InvitationDetailDto |
| `invite_idempotency_conflict` | same key + different payload | IDEMPOTENCY_CONFLICT |
| `invite_forbidden` | missing tenant.member.invite | PERMISSION_DENIED |

---

## §S8 — EP-03/US-03 — Accept / decline (manual opaque token)

Token-gated. **Không** nhận `actorUserId` từ client — accept resolves verified actor email từ Auth/Identity snapshot và so sánh canonical với invitation.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `InspectInvitationTokenQuery` | **token** (body) | `InvitationTokenInspectionDto` | INVITATION_TOKEN_INVALID, INVITATION_EXPIRED, INVITATION_REVOKED, INVITATION_ALREADY_USED |
| `AcceptInvitationCommand` | **token** (body), idempotencyKey | `TenantMemberDetailDto` (active) + invitation accepted | INVITATION_TOKEN_INVALID, INVITATION_EXPIRED, INVITATION_REVOKED, INVITATION_ALREADY_USED, INVITATION_EMAIL_MISMATCH, TENANT_SUSPENDED, DUPLICATE_MEMBERSHIP, AUTHENTICATION_REQUIRED, IDEMPOTENCY_CONFLICT |
| `RegisterFromInvitationCommand` | **token** (body), profile, credentialProof, idempotencyKey | `InvitationRegistrationResultDto` (verified user + membership) | INVITATION_TOKEN_INVALID, INVITATION_EXPIRED, INVITATION_REVOKED, INVITATION_ALREADY_USED, INVITATION_EMAIL_MISMATCH, PLATFORM_USER_ALREADY_EXISTS, VALIDATION_ERROR, SYSTEM_ERROR, IDEMPOTENCY_CONFLICT |
| `DeclineInvitationCommand` | **token** (body), idempotencyKey | `InvitationDetailDto` (`status=declined`) | INVITATION_TOKEN_INVALID, INVITATION_EXPIRED, INVITATION_REVOKED, INVITATION_ALREADY_USED, IDEMPOTENCY_CONFLICT |

### DTO fields

`InvitationTokenInspectionDto`:
```text
tenantId, tenantName, inviteeEmail, initialRoleId, initialRoleLabel,
expiresAt, accountExists
```

`InvitationRegistrationProfileInput`:
```text
givenName, familyName, phone?
```

`InvitationRegistrationResultDto`:
```text
userId, membership (TenantMemberDetailDto)
```

### Locked rules

- Invalid token → chỉ `INVITATION_TOKEN_INVALID`; **không** leak `accountExists` / invitation fields.
- Terminal invitation → `INVITATION_EXPIRED` | `INVITATION_REVOKED` | `INVITATION_ALREADY_USED`.
- Accept email mismatch (actor verified email ≠ invitee) → `INVITATION_EMAIL_MISMATCH`.
- Concurrent accept: one success; subsequent same-key replay or `INVITATION_ALREADY_USED`.
- Tenant suspended → `TENANT_SUSPENDED` **without** consuming token.
- Invitation token = email proof for new account; Identity marks email verified; no second activation token.
- Consume token only in same txn as Membership create + invitation → accepted.

### Manual token handoff

1. Màn nhập token chỉ khi user chưa đăng nhập; token POST trong JSON body — không URL/query/client persistence.
2. Token hợp lệ + `accountExists=true` → locked-email login → `AcceptInvitationCommand`.
3. Token hợp lệ + `accountExists=false` → locked-email registration → `RegisterFromInvitationCommand`.
4. Identity tạo OK nhưng IAM accept lỗi tạm: token chưa consume; retry theo nhánh account đã tồn tại.

**RPC draft:** `iam.inspect_invitation_token`, `iam.accept_invitation`, `iam.decline_invitation` — [`_drafts/020_iam_tenant_invitation_acceptance.sql`](../../../../supabase/migrations/_drafts/020_iam_tenant_invitation_acceptance.sql).

**Runtime identity (S8 registration):** `SupabaseInvitationIdentityAdapter` uses Supabase Auth email/password `signUp` + IAM `update_my_platform_user_profile`. Operational requirement: invitation sign-up must return a **verified authenticated session** (`enable_confirmations = false` in local `supabase/config.toml`). Adapter fail-closed → `SYSTEM_ERROR` if session missing or email unverified. Inspect RPC remains the sole `accountExists` authority (no secondary email enumeration).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `inspect_existing_account` | valid token + identity exists | preview + accountExists=true |
| `inspect_new_account` | valid token + identity missing | preview + accountExists=false |
| `inspect_invalid_no_leak` | bad token | INVITATION_TOKEN_INVALID (no account leak) |
| `accept_existing_account_ok` | locked-email login + valid token | membership active |
| `register_and_accept_ok` | valid token + new account data | verified identity + membership active |
| `register_identity_conflict` | email already registered | PLATFORM_USER_ALREADY_EXISTS |
| `accept_email_mismatch` | wrong login email | INVITATION_EMAIL_MISMATCH |
| `accept_expired` | expired | INVITATION_EXPIRED |
| `accept_rotated_token` | old token after resend | INVITATION_TOKEN_INVALID |
| `accept_declined` | declined invitation | INVITATION_ALREADY_USED |
| `accept_concurrent` | second concurrent accept | INVITATION_ALREADY_USED or idempotent replay |
| `accept_tenant_suspended` | suspended tenant | TENANT_SUSPENDED (token not consumed) |
| `accept_retry_after_identity_created` | identity exists after transient IAM failure | membership active, no duplicate identity |
| `decline_ok` | valid token | declined |
| `decline_idempotent_retry` | same key + payload | same declined result |

---

## §S9 — EP-03/US-04 — Resend / revoke invitation

Tenant-scoped. Permission: `tenant.member.invite`. Actor từ execution context.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `ResendInvitationCommand` | tenantId, invitationId, expectedVersion, idempotencyKey | `InvitationDetailDto` (pending, new expiry/version/deliveryCorrelationId) | VALIDATION_ERROR, STATE_CHANGED, RESOURCE_NOT_FOUND, INVITATION_ALREADY_USED, PERMISSION_DENIED, IDEMPOTENCY_CONFLICT, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |
| `RevokeInvitationCommand` | tenantId, invitationId, expectedVersion, reason, idempotencyKey | `InvitationDetailDto` (`status=revoked`) | VALIDATION_ERROR, STATE_CHANGED, RESOURCE_NOT_FOUND, INVITATION_ALREADY_USED, PERMISSION_DENIED, IDEMPOTENCY_CONFLICT, AUTHENTICATION_REQUIRED, SYSTEM_ERROR |

### Locked rules

- Only **pending** invitation may resend/revoke; non-pending → `INVITATION_ALREADY_USED`.
- Resend: preserve inviteeEmail + initialRoleId; rotate `token_hash`; new 7-day expiry from server UTC; increment version; new delivery correlation; §S-NOTIFY enqueue `tenant_invitation` with `secret_payload_ciphertext` (no raw token in refs).
- Revoke: non-empty trimmed reason required; increment version; **never** enqueue email; set `revokedAt`.
- Old token invalid immediately after successful resend/revoke.
- Stale `expectedVersion` → `STATE_CHANGED`.
- Cross-tenant / unknown invitationId → `RESOURCE_NOT_FOUND`.
- Same idempotency key + same payload → replay; different payload → `IDEMPOTENCY_CONFLICT`.

**RPC draft:** `iam.resend_tenant_invitation`, `iam.revoke_tenant_invitation` — [`_drafts/018_iam_tenant_invitation_resend_revoke.sql`](../../../../supabase/migrations/_drafts/018_iam_tenant_invitation_resend_revoke.sql).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `invitation_resend_ok` | pending + matching version | pending + rotated expiry/version + delivery queued |
| `invitation_revoke_ok` | pending + reason | status=revoked |
| `invitation_old_token_invalid` | accept with pre-resend token | INVITATION_TOKEN_INVALID |
| `invitation_state_changed` | stale expectedVersion | STATE_CHANGED |
| `invitation_terminal_reject` | accepted/declined/revoked/expired | INVITATION_ALREADY_USED |
| `invitation_cross_tenant_not_found` | foreign invitationId | RESOURCE_NOT_FOUND |
| `invitation_resend_delivery_failed` | async delivery fail | invitation still pending; deliveryStatus failed |

---

## §S15 — EP-01/US-01–US-03 — Platform User + onboarding

Platform-scoped (Admin App). Permission codes: `IamPlatformPermissions`. No `@RequiresTenant`.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchPlatformUsersQuery` | query?, status?, cursor?, limit? | `CursorPageDto<PlatformUserSummaryDto>` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `GetPlatformUserQuery` | userId | `PlatformUserDetailDto` (+ memberships, version) | PLATFORM_PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `SendActivationInvitationCommand` | userId, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `RequestPlatformPasswordResetCommand` | userId, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `SuspendPlatformUserCommand` | userId, reason, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `RestorePlatformUserCommand` | userId, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `CreateTenantOnboardingCommand` | owner (`OnboardingOwnerInput`), organizationName, idempotencyKey, correlationId? | `TenantOnboardingResultDto` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, IDEMPOTENCY_CONFLICT |
| `GetTenantOnboardingOperationQuery` | operationId | `TenantOnboardingOperationDto` | PLATFORM_PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `RetryTenantOnboardingOperationCommand` | operationId, idempotencyKey | `TenantOnboardingOperationDto` | PLATFORM_PERMISSION_DENIED, STATE_CHANGED, IDEMPOTENCY_CONFLICT, VALIDATION_ERROR |

**Locked search shape**

```text
query?, status?, cursor?, limit?
```

Default limit `20`, max `100`; cursor opaque and stable.

**Lifecycle concurrency:** every privileged mutate includes `expectedVersion` + `idempotencyKey`. Same key+payload → same result; same key/different payload → `IDEMPOTENCY_CONFLICT`. Stale version → `STATE_CHANGED`.

**Onboarding operation**

`TenantOnboardingOperationDto(status, completedSteps, failedStep, correlationId, tenantId?, ownerUserId?)`
Status: `inProgress` \| `completed` \| `partialFailure` \| `failed`.
Atomic boundary: Tenant + Owner Membership + role + IAM outbox; Identity creation is an external step recorded in operation progress. Retry resumes incomplete steps.

**Notes**
- Password-reset initiate only; Platform Admin never receives credentials (BR-01/BR-02).
- `PlatformUserSummaryDto.status` / `PlatformUserDetailDto.status` are effective activation status derived from Supabase Auth: `active` when `auth.users.email_confirmed_at is not null`, otherwise `pendingActivation`.
- `PlatformUserDetailDto.emailVerified` is Auth-derived: `auth.users.email_confirmed_at is not null`.
- `iam.platform_user_profiles.status` and `iam.platform_user_profiles.email_verified` are legacy/ignored for Platform User read DTOs until their lifecycle meaning is redefined.
- `SearchPlatformUsersQuery.status` filters by effective status, not by `iam.platform_user_profiles.status`.
- Create onboarding: `@Idempotent(keyField: 'idempotencyKey')`.
- **OQ-02 (closed):** IAM persists operation by `operationId` / `idempotencyKey` / `correlationId` / status / steps.
- Owner first role fixed `Chủ cửa hàng`; `is_owner=true` independent of role label.
- Side effect email: RPC `enqueue_outbox_message` (`iam.email.delivery_requested`) — Dart must not enqueue outbox.
- **OQ-03 (closed):** step-up → `STEP_UP_AUTH_REQUIRED` on suspend/restore/credential-adjacent.

**RPCs (draft):**
- `iam.has_platform_permission` — [`_drafts/003_iam_platform_admin_authz.sql`](../../../../supabase/migrations/_drafts/003_iam_platform_admin_authz.sql)
- `iam.search_platform_users`, `iam.get_platform_user` — [`_drafts/004_iam_platform_users_read.sql`](../../../../supabase/migrations/_drafts/004_iam_platform_users_read.sql)
- lifecycle + activation/reset — [`_drafts/005_iam_platform_user_lifecycle.sql`](../../../../supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql)
- onboarding create/get/retry — [`_drafts/006_iam_create_tenant_onboarding.sql`](../../../../supabase/migrations/_drafts/006_iam_create_tenant_onboarding.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `users_search_ok` | query by email | cursor page of summaries |
| `users_search_paged` | cursor/limit | nextCursor when more |
| `user_detail_ok` | known userId | detail + memberships + version |
| `user_verified_profile_pending_reads_active` | profile pending/false + Auth confirmed | list/detail status `active`, detail `emailVerified=true` |
| `user_unverified_profile_pending_reads_pending` | profile pending/false + Auth unconfirmed | list/detail status `pendingActivation`, detail `emailVerified=false` |
| `users_filter_active_uses_effective_status` | filter `active` | includes profile-pending users with Auth confirmed |
| `users_filter_pending_uses_effective_status` | filter `pendingActivation` | excludes profile-pending users with Auth confirmed |
| `user_forbidden_403` | missing `platform.user.view` | PLATFORM_PERMISSION_DENIED |
| `activation_resend_ok` | pendingActivation + version/key | void success |
| `suspend_ok` | active user + reason | status → suspended |
| `suspend_stale_version` | wrong expectedVersion | STATE_CHANGED |
| `suspend_idempotency_conflict` | same key / different payload | IDEMPOTENCY_CONFLICT |
| `restore_ok` | suspended user | status → active |
| `step_up_required` | privileged mutate | STEP_UP_AUTH_REQUIRED |
| `onboarding_existing_user_ok` | existing owner + org | TenantOnboardingResultDto |
| `onboarding_new_user_ok` | new email + org | result + isNewUser=true |
| `onboarding_retry_idempotent` | same idempotencyKey | same result |
| `onboarding_partial_failure` | identity step failed | status=partialFailure + failedStep |
| `onboarding_resume_ok` | retry after partialFailure | continues incomplete steps |
| `onboarding_validation_error` | missing org / invalid email | VALIDATION_ERROR |

---

## §S16 — EP-02/US-06, US-08–US-10 — Platform tenant admin / audit

Platform-scoped (Admin App). Permission codes: `IamPlatformPermissions`. No `@RequiresTenant`.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchPlatformTenantsQuery` | query?, status?, readinessState?, warningCode?, cursor?, limit? | `CursorPageDto<PlatformTenantSummaryDto>` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `GetPlatformTenantQuery` | tenantId | `PlatformTenantDetailDto` (+ members, version) | PLATFORM_PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `ListPlatformTenantMembersQuery` | tenantId | `List<PlatformTenantMemberDto>` | PLATFORM_PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `SuspendPlatformTenantCommand` | tenantId, reason, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR, TENANT_STATE_INVALID, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `RestorePlatformTenantCommand` | tenantId, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, TENANT_STATE_INVALID, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `TransferPlatformTenantOwnershipCommand` | tenantId, newOwnerUserId, expectedVersion, idempotencyKey | `void` | PLATFORM_PERMISSION_DENIED, OWNER_TARGET_INVALID, TENANT_STATE_INVALID, STATE_CHANGED, IDEMPOTENCY_CONFLICT, STEP_UP_AUTH_REQUIRED |
| `SearchPlatformAuditLogsQuery` | fromUtc?, toUtc?, actorUserId?, targetType?, targetId?, action?, result?, source?, correlationId?, cursor?, limit? | `CursorPageDto<PlatformAuditLogSummaryDto>` | PLATFORM_PERMISSION_DENIED, VALIDATION_ERROR |
| `GetPlatformAuditLogQuery` | auditLogId | `PlatformAuditLogDetailDto` (redacted) | PLATFORM_PERMISSION_DENIED, RESOURCE_NOT_FOUND |

**Locked search shapes**

Tenants:

```text
query?, status?, readinessState?, warningCode?, cursor?, limit?
```

Audit:

```text
fromUtc?, toUtc?, actorUserId?, targetType?, targetId?,
action?, result?, source?, correlationId?, cursor?, limit?
```

Default limit `20`, max `100`.

**Notes**
- Tenant status: `TenantLifecycleStatus` (`provisioning` \| `active` \| `suspended` \| `closed`).
- Closed tenant lifecycle → `TENANT_STATE_INVALID` (not `STATE_CHANGED`).
- Ownership invalid target → `OWNER_TARGET_INVALID` (not `VALIDATION_ERROR`).
- Ownership transfer flips `is_owner` atomically; does **not** change `role` / `role_id`.
- Transfer `@Idempotent(keyField: 'idempotencyKey')` + payload conflict → `IDEMPOTENCY_CONFLICT`.
- **OQ-05 (closed):** IAM-owned events from `iam.audit_logs` (scope `platform`); secrets/PII redact before persist.
- **OQ-03 (closed):** step-up → `STEP_UP_AUTH_REQUIRED`.

**RPCs (draft):**
- tenants read — [`_drafts/010_iam_platform_tenants_read.sql`](../../../../supabase/migrations/_drafts/010_iam_platform_tenants_read.sql)
- tenant lifecycle — [`_drafts/011_iam_platform_tenant_lifecycle.sql`](../../../../supabase/migrations/_drafts/011_iam_platform_tenant_lifecycle.sql)
- ownership — [`_drafts/012_iam_platform_transfer_ownership.sql`](../../../../supabase/migrations/_drafts/012_iam_platform_transfer_ownership.sql)
- audit — [`_drafts/013_iam_platform_audit_read.sql`](../../../../supabase/migrations/_drafts/013_iam_platform_audit_read.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenants_search_ok` | query by name/code | cursor page |
| `tenants_search_filtered` | readiness/warning | filtered page |
| `tenant_detail_ok` | known tenantId | detail + members + version |
| `tenant_forbidden_403` | missing `platform.tenant.view` | PLATFORM_PERMISSION_DENIED |
| `tenant_suspend_ok` | active + reason | status → suspended |
| `tenant_restore_ok` | suspended | status → active |
| `tenant_closed_reject` | closed lifecycle action | TENANT_STATE_INVALID |
| `ownership_transfer_ok` | active member as new owner | one owner |
| `ownership_invalid_target` | non-member | OWNER_TARGET_INVALID |
| `ownership_idempotency_conflict` | same key / different payload | IDEMPOTENCY_CONFLICT |
| `audit_search_ok` | filters | cursor page |
| `audit_detail_ok` | known id | redacted detail |
| `audit_forbidden_403` | missing `platform.audit.view` | PLATFORM_PERMISSION_DENIED |

---

## §S10 — EP-03/US-05 + US-06 — Membership lifecycle

Tenant-scoped. Ports: `ITenantMembershipReadGateway`, `ITenantMembershipCommandGateway` (không mở rộng `IIamAccessGateway`).

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetTenantMemberQuery` | tenantId, membershipId | `TenantMemberDetailDto` | PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `DeactivateMembershipCommand` | tenantId, membershipId, expectedVersion | `TenantMemberDetailDto` (inactive) | LAST_OWNER_PROTECTED, STATE_CHANGED, RESOURCE_NOT_FOUND, PERMISSION_DENIED, MEMBERSHIP_REMOVED |
| `ReactivateMembershipCommand` | tenantId, membershipId, expectedVersion | `TenantMemberDetailDto` (active) | ROLE_NOT_ASSIGNABLE, STATE_CHANGED, RESOURCE_NOT_FOUND, MEMBERSHIP_REMOVED, PERMISSION_DENIED |
| `RemoveMembershipCommand` | tenantId, membershipId, expectedVersion | `TenantMemberDetailDto` (removed) | LAST_OWNER_PROTECTED, STATE_CHANGED, RESOURCE_NOT_FOUND, PERMISSION_DENIED |

**Notes**
- `MembershipStatus`: `active` \| `inactive` \| `removed` (terminal).
- Transitions: `active→inactive`, `inactive→active`, `active|inactive→removed`. Removed không reactivate.
- Sole Owner: deactivate/remove → `LAST_OWNER_PROTECTED`.
- Cross-tenant / unknown membershipId → non-enumerating `RESOURCE_NOT_FOUND` (không dùng `NOT_FOUND`).
- Missing permission → `PERMISSION_DENIED`.
- Stale `expectedVersion` → `STATE_CHANGED`.
- Access resolution chỉ dùng Membership `active`. Inactive → `MEMBERSHIP_INACTIVE`; removed → `MEMBERSHIP_REMOVED`.
- Admin member list vẫn đọc được cả ba status.
- Mutation: lock row + `expectedVersion`; enqueue `iam.membership.deactivated|reactivated|removed` + Audit intent same-txn.
- Blocked codes: `IamBlockedCodes` / `IamBlockedException`.

**RPCs (draft):** `iam.get_tenant_member`, `iam.deactivate_membership`, `iam.reactivate_membership`, `iam.remove_membership` + patch access RPCs — [`_drafts/014_iam_tenant_membership_lifecycle.sql`](../../../../supabase/migrations/_drafts/014_iam_tenant_membership_lifecycle.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `member_detail_ok` | known membershipId | TenantMemberDetailDto |
| `member_not_found` | unknown / cross-tenant id | RESOURCE_NOT_FOUND |
| `member_deactivate_ok` | active non-sole-owner | status → inactive, version+1 |
| `member_reactivate_ok` | inactive | status → active, version+1 |
| `member_remove_ok` | active/inactive non-sole-owner | status → removed, version+1 |
| `member_last_owner_protected` | sole Owner deactivate/remove | LAST_OWNER_PROTECTED |
| `member_state_changed` | stale expectedVersion | STATE_CHANGED |
| `member_removed_terminal` | reactivate removed | MEMBERSHIP_REMOVED |
| `member_forbidden` | missing permission | PERMISSION_DENIED |

---

## §S12 — EP-02/US-01–US-03 — Tenant Profile + Legal Profile

Tenant-scoped. Ports: `ITenantProfileReadGateway`, `ITenantProfileCommandGateway`.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetTenantQuery` | tenantId | `TenantDto` (+ current Legal Profile nullable) | PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `UpdateTenantProfileCommand` | tenantId, editable snapshot, expectedVersion | `TenantDto` | VALIDATION_ERROR, STATE_CHANGED, PERMISSION_DENIED, RESOURCE_NOT_FOUND |
| `UpsertLegalProfileCommand` | tenantId, legal snapshot, expectedVersion, allowDuplicateTaxCode | `UpsertLegalProfileResultDto` (saved \| warning `DuplicateTaxCodeWarningDto`) | VALIDATION_ERROR, STATE_CHANGED, PERMISSION_DENIED, RESOURCE_NOT_FOUND |

### Editable fields

`UpdateTenantProfileCommand` allowlist:
```text
displayName, contactEmail, contactPhone, contactAddressText,
provinceCode, communeCode
```
Không nhận: status, ownership, businessTimezone, baseCurrencyCode, tax code, activatedAt.

`UpsertLegalProfileCommand` allowlist:
```text
legalEntityType, legalName, taxCode, registeredAddressText,
provinceCode, communeCode, allowDuplicateTaxCode
```

**Notes**
- Duplicate tax-code two-step: `allowDuplicateTaxCode=false` → không ghi, trả **success** `UpsertLegalProfileResultDto.warning = DuplicateTaxCodeWarningDto` (`DUPLICATE_TAX_CODE_WARNING`) — không phải blocked exception; confirm với `true` rồi lưu trong transaction.
- Tax code: digits only; ENTERPRISE 10; HOUSEHOLD_BUSINESS 12.
- Email trim+lowercase; phone normalize VN `0…` → `+84`.
- Dual-write legacy `name` ↔ `display_name` trong giai đoạn tương thích.
- Province/commune optional; commune requires valid province membership (IAM-private admin units seed).
- Cross-tenant / unknown tenant → `RESOURCE_NOT_FOUND`.

**RPCs (draft):** `iam.get_tenant`, `iam.update_tenant_profile`, `iam.upsert_legal_profile` — [`_drafts/015_iam_tenant_profile_legal.sql`](../../../../supabase/migrations/_drafts/015_iam_tenant_profile_legal.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenant_profile_ok` | known tenant | TenantDto |
| `tenant_profile_update_ok` | valid snapshot | updated TenantDto, version+1 |
| `tenant_profile_validation` | bad email/phone | VALIDATION_ERROR |
| `tenant_profile_stale` | stale version | STATE_CHANGED |
| `tenant_profile_forbidden` | missing permission | PERMISSION_DENIED |
| `tenant_profile_not_found` | cross-tenant / unknown | RESOURCE_NOT_FOUND |
| `legal_upsert_ok` | valid legal | UpsertLegalProfileResultDto |
| `legal_duplicate_warning` | tax code trùng + allow=false | success warning `DuplicateTaxCodeWarningDto` (no peer PII) |
| `legal_duplicate_confirm` | same + allow=true | saved |

---

## §S11 — EP-01/US-04 + US-05 — Readiness + activate Tenant

Tenant-scoped. Activation snapshot via Platform Identity provider port (IAM không đọc Identity table).

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetTenantReadinessQuery` | tenantId | `TenantReadinessDto` | PERMISSION_DENIED |
| `ActivateTenantCommand` | tenantId, expectedVersion, idempotencyKey | `TenantActivationResultDto` | READINESS_BLOCKED, STATE_CHANGED, IDEMPOTENCY_CONFLICT, TENANT_STATE_INVALID, PERMISSION_DENIED |

**Notes**
- Readiness = derived mỗi request; không persist/cache như access grant.
- Blocker codes: `TENANT_DISPLAY_NAME_MISSING`, `TENANT_CONTACT_EMAIL_MISSING_OR_INVALID`, `TENANT_CONTACT_PHONE_MISSING_OR_INVALID`, `TENANT_CONTACT_ADDRESS_MISSING`, `OWNER_MEMBERSHIP_INVALID`, `OWNER_ROLE_INVALID`, `OWNER_IDENTITY_INACTIVE`, `OWNER_EMAIL_UNVERIFIED`, `PLATFORM_BLOCKER_PRESENT`.
- Warnings: `LEGAL_PROFILE_MISSING`, `DUPLICATE_TAX_CODE`.
- Activate: lock Tenant + Owner Membership; re-evaluate readiness in txn; idempotency on `(tenant_id, idempotency_key)`.
- BE `done`: owner identity readiness dùng `iam.get_auth_user_snapshot` (Auth read-only) + platform profile status; activation ghi đúng một outbox `iam.tenant.activated` + một audit row same-txn.

**RPCs (draft):** `iam.get_tenant_readiness`, `iam.activate_tenant` — [`_drafts/016_iam_tenant_readiness_activate.sql`](../../../../supabase/migrations/_drafts/016_iam_tenant_readiness_activate.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `readiness_blocked` | missing profile fields | blockers present, canActivate=false |
| `readiness_warning_only` | legal missing | warnings only, canActivate=true |
| `activate_ok` | provisioning + no blockers | status → active |
| `activate_readiness_blocked` | blocker at mutate time | READINESS_BLOCKED |
| `activate_idempotent_retry` | same key + payload | same result, one event |
| `activate_idempotency_conflict` | same key different payload | IDEMPOTENCY_CONFLICT |
| `activate_already_active` | active + new key | TENANT_STATE_INVALID |

---

## §S13 — EP-02/US-07 — Tenant Audit history

Tenant-scoped. Port: `ITenantAuditReadPort` → `SupabaseTenantAuditReadPort`. Đọc từ canonical `iam.audit_logs` (scope `tenant`); S16 platform audit dùng chung bảng này (scope `platform`). Interim `iam.platform_audit_logs` giữ để tương thích một vòng rollout, không dual-write.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchTenantAuditLogsQuery` | tenantId, fromUtc, toUtc, result?, actorUserId?, subjectType?, eventCode?, cursor?, limit? | `TenantAuditLogSearchPageDto` | PERMISSION_DENIED, VALIDATION_ERROR, SYSTEM_ERROR |
| `GetTenantAuditLogQuery` | tenantId, auditLogId | `TenantAuditLogDetailDto` | PERMISSION_DENIED, RESOURCE_NOT_FOUND, SYSTEM_ERROR |

**Locked search shape**

```text
tenantId, fromUtc, toUtc, result?, actorUserId?, subjectType?,
eventCode?, cursor?, limit?
```

**Detail fields:** auditLogId, tenantId, eventCode, actor (nullable + `actorUnavailable`), subjectType/subjectId, occurredAt, source, trackingId, redacted before/after (`beforeRedacted`/`afterRedacted` + optional `beforeState`/`afterState`).

**Notes**
- Default page size 20, max 100. Time range UTC, `from <= to`.
- Detail luôn kèm tenantId + auditLogId (chống cross-tenant enumeration). Unknown/cross-tenant detail → `RESOURCE_NOT_FOUND`.
- Actor unavailable → actor nullable + `actorUnavailable=true`. Redacted before/after không khôi phục ở IAM.
- Cursor encode `(occurred_at, id)`; opaque and stable.
- **OQ-05 (closed):** S13 chỉ hiển thị IAM-owned audit events (scope `tenant`); token, OTP, credential và PII ngoài allowlist bị redact trước persistence (`AuditPayloadRedactor`).
- BE `done`: real `SupabaseTenantAuditReadPort` nối `iam.search_tenant_audit_logs` / `iam.get_tenant_audit_log`.

**RPCs (draft):** `iam.audit_logs` (canonical storage), `iam.append_audit_log`, `iam.record_account_security_event`, `iam.search_tenant_audit_logs`, `iam.get_tenant_audit_log`, `iam.search_platform_audit_logs`, `iam.get_platform_audit_log` — [`_drafts/013_iam_platform_audit_read.sql`](../../../../supabase/migrations/_drafts/013_iam_platform_audit_read.sql)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenant_audit_search_ok` | filters | summaries page |
| `tenant_audit_detail_ok` | known id | detail (+ redaction state) |
| `tenant_audit_empty` | no matches | empty page |
| `tenant_audit_forbidden` | missing permission | PERMISSION_DENIED |
| `tenant_audit_provider_error` | adapter unavailable | SYSTEM_ERROR |
| `tenant_audit_actor_unavailable` | deleted actor | actorUnavailable=true |
| `tenant_audit_cross_tenant` | foreign auditLogId | RESOURCE_NOT_FOUND |

---

## §S14 — EP-06/US-01–US-04 — My Account

No `@RequiresTenant`. `identity/` là **public CQRS surface duy nhất** cho self-service. Tất cả operation đi qua `IPlatformIdentitySelfServicePort`.

- Profile fields (`given/family name`, `phone`, `avatarReference`) do IAM sở hữu trong `iam.platform_user_profiles`.
- Login email / verified state / recovery OTP / password / session do Supabase Auth sở hữu; IAM chỉ đọc snapshot và orchestration.
- Completion chỉ trả session-policy booleans, không trả credential/token.

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetMyIdentityProfileQuery` | (authenticated user) | `MyIdentityProfileDto` | AUTHENTICATION_REQUIRED, SYSTEM_ERROR |
| `UpdateMyIdentityProfileCommand` | firstName, lastName, phoneNumber?, avatarUrl? | `MyIdentityProfileDto` | VALIDATION_ERROR, SYSTEM_ERROR |
| `RequestMyPasswordResetCommand` | — | `PasswordResetRequestResultDto` | RESET_RATE_LIMITED, SYSTEM_ERROR |
| `ResendMyPasswordResetCommand` | operationId | `PasswordResetRequestResultDto` (refreshed expiresAt/resendAvailableAt) | RESET_RATE_LIMITED, STATE_CHANGED, SYSTEM_ERROR |
| `VerifyMyPasswordResetCommand` | operationId, code | `PasswordResetVerifyResultDto` | RESET_CODE_INVALID, RESET_CODE_EXPIRED, RESET_CODE_ATTEMPTS_EXCEEDED, STATE_CHANGED, SYSTEM_ERROR |
| `CompleteMyPasswordResetCommand` | operationId, newPassword | `PasswordResetCompletionResultDto` | PASSWORD_POLICY_VIOLATION, STATE_CHANGED, SYSTEM_ERROR |
| `SignOutCommand` | — | `SignOutResultDto` | SYSTEM_ERROR (chỉ khi local clear fail) |

**Locked password-reset / sign-out result types**

- Request / Resend → `PasswordResetRequestResultDto(operationId, maskedEmail, expiresAt, resendAvailableAt)`.
- Verify → `PasswordResetVerifyResultDto(verified)`.
- Complete → `PasswordResetCompletionResultDto(currentSessionRotated: true, otherSessionsRevoked: true)`.
- Sign out → `SignOutResultDto(localCleared: true, remoteSucceeded: bool)` — FE có thể cảnh báo remote fail mà không giữ secrets local.

**Canonical reset errors (only):**

```text
RESET_RATE_LIMITED
RESET_CODE_INVALID
RESET_CODE_EXPIRED
RESET_CODE_ATTEMPTS_EXCEEDED
PASSWORD_POLICY_VIOLATION
STATE_CHANGED
SYSTEM_ERROR
```

**Notes**
- Email không có trong update input (immutable / no mass-assignment).
- Avatar = opaque `avatarReference`; `null` = xóa. Upload/storage ngoài slice.
- Reset: 6-digit code thuộc Auth; response/logs/DTO **không** chứa code, password, hash, session token.
- **OQ-09 (closed):** sau `CompleteMyPasswordResetCommand` thu hồi các session khác; session hiện hành được rotate và tiếp tục hợp lệ (`currentSessionRotated` / `otherSessionsRevoked`).
- `SignOutCommandHandler` luôn clear IAM session local; `remoteSucceeded=false` khi provider logout lỗi (không rethrow sau local clear).
- BE `done`: real `SupabasePlatformIdentitySelfServiceAdapter` = `SupabasePlatformUserProfileGateway` + `SupabaseAuthAccountClient` + `SupabasePasswordResetOperationStore` (metadata only, không lưu code).

**RPCs (draft):** `iam.get_my_platform_user_profile`, `iam.update_my_platform_user_profile` — [`_drafts/004_iam_platform_users_read.sql`](../../../../supabase/migrations/_drafts/004_iam_platform_users_read.sql) / [`_drafts/005_iam_platform_user_lifecycle.sql`](../../../../supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql); password-reset metadata `iam.begin/get/resend/mark_verified/mark_completed_password_reset_operation` — [`_drafts/021_iam_password_reset_operations.sql`](../../../../supabase/migrations/_drafts/021_iam_password_reset_operations.sql). Recovery OTP/password/session authoritative ở Supabase Auth (không RPC IAM).

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `my_account_ok` | authenticated | MyIdentityProfileDto |
| `my_account_update_ok` | valid profile | updated MyIdentityProfileDto |
| `password_reset_request_ok` | verified email | PasswordResetRequestResultDto |
| `password_reset_resend_ok` | within policy | refreshed PasswordResetRequestResultDto |
| `password_reset_verify_ok` | valid code | PasswordResetVerifyResultDto(verified: true) |
| `password_reset_invalid_code` | bad code | RESET_CODE_INVALID |
| `password_reset_complete_ok` | verified + policy ok | PasswordResetCompletionResultDto |
| `sign_out_ok` | authenticated | SignOutResultDto(localCleared: true, remoteSucceeded: true) |
| `sign_out_remote_error` | provider fails | `SignOutResultDto(localCleared: true, remoteSucceeded: false)` |
| `identity_unavailable` | no adapter | SYSTEM_ERROR |

---

## Parallel notes

- FE có thể fake: **yes** sau CONTRACT (`FakeIamModule` + fake notification gateway).
- E2E invite cần S-NOTIFY BE hoặc test double ghi outcome.
- Admin platform CMDs: §S15 + §S16 CONTRACT — xem APPENDICES §6.1.3.
- S10–S14 CONTRACT sections: §S10 / §S12 / §S11 / §S13 / §S14 (thứ tự implement BE theo plan).
