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
| — | Delivery enqueue (port) | infra | system / outbox | S-NOTIFY |
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

*(Bổ sung đầy đủ khi CONTRACT từng slice — không block scaffold.)*

---

## §S-NOTIFY — Notification delivery (Resend)

### Port / contract

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `EnqueueEmailDelivery` (outbox / port) | templateId, toEmail, locale, payload refs (invitation_id / operation_id), correlationId — **không** raw token trong log | queued | VALIDATION_ERROR |
| `NotificationDeliveryOutcome` (callback / projection) | messageId, status (`queued`/`sent`/`failed`/`bounced`), provider=`resend` | outcome stored for UI | SYSTEM_ERROR |

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

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `tenants_single` | one membership | one item current |
| `tenants_multi` | many active memberships | list + current marked |
| `tenants_suspended_disabled` | target suspended | item disabled |

---

## §S2 — EP-05/US-02 — Switch tenant context

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SwitchTenantContextCommand` | targetTenantId, confirm | `TenantContextDto` | TENANT_ACCESS_DENIED, TENANT_SUSPENDED, TENANT_CLOSED |

RPC target: extend / replace interim `SwitchActiveTenant`.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `switch_ok` | valid target | new context |
| `switch_denied` | no membership | TENANT_ACCESS_DENIED |
| `switch_suspended` | suspended tenant | TENANT_SUSPENDED |

---

## §S7 — EP-03/US-02 — Create invitation

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `CreateInvitationCommand` | tenantId, inviteeEmail, initialRoleId, idempotencyKey | `InvitationDto` (pending, expiresAt, deliveryOutcome) | VALIDATION_ERROR, DUPLICATE_MEMBERSHIP, ROLE_NOT_ASSIGNABLE, NO_PERMISSION |

Side effect: outbox → §S-NOTIFY `tenant_invitation` template + App Link opaque.

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

## Parallel notes

- FE có thể fake: **yes** sau CONTRACT (`FakeIamModule` + fake notification gateway).
- E2E invite cần S-NOTIFY BE hoặc test double ghi outcome.
- Admin platform CMDs: bổ sung khi S15 CONTRACT — xem APPENDICES §6.1.3.
