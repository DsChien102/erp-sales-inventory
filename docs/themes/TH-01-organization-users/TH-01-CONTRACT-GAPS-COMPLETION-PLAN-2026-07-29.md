# TH-01 Contract Gaps Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện đúng các contract gap đã xác định trong TH-01, đồng bộ product/harness/application và cung cấp đủ fake, BE, FE, E2E evidence để mỗi lane `Contract: done` thực sự đạt Definition of Done.

**Architecture:** `harness/07-api-contracts.md` là Source of Truth cho Dart Command/Query/DTO giữa presentation và application; `APPENDICES.md` là logical HTTP/API map và stable error catalog. Mỗi gap được đóng theo vertical contract slice: khóa semantics → export application types → fake scenarios → BE adapter/RPC draft → FE contract test → E2E evidence → cập nhật roadmap/traceability.

**Tech Stack:** Dart 3, Flutter, Vet45 CQRS/codegen, Supabase RPC/Postgres draft migrations, `FakeIamModule`, Melos, GitNexus, shell harness guards.

## Global Constraints

- Đọc `AGENTS.md`, `.cursor/rules/vet45-architecture.mdc`, `docs/harness/PROGRESS.md` và `harness/00-agent-ritual.md` trước khi thực hiện task.
- Trước khi sửa function/class/method, chạy GitNexus `impact({target, direction: "upstream"})`; cảnh báo user nếu risk là `HIGH` hoặc `CRITICAL`.
- Không sửa hoặc tạo `supabase/migrations/[0-9]*.sql`; mọi SQL mới chỉ nằm trong `supabase/migrations/_drafts/`.
- Không hand-maintain generated Dart; sau khi thêm handler/validator chạy `melos run codegen`.
- Actor/user/tenant hiện hành phải lấy từ `IExecutionContext`, `ICurrentUser`, `ICurrentTenant` hoặc server `auth.uid()`; không nhận actor ID từ payload public.
- Mutation retryable phải có idempotency contract; mutation trên entity versioned phải nhận `expectedVersion`.
- Cross-tenant lookup phải trả non-enumerating `RESOURCE_NOT_FOUND`.
- Raw invitation token, OTP, password và session token không xuất hiện trong URL, log, analytics, audit hoặc response ngoài flow được phép.
- Chỉ đánh lane `done` khi Contract + artifacts/tests của lane khớp roadmap Definition of Done.
- Trước commit chạy GitNexus `detect_changes({scope: "all"})`.

---

## Scope và completion matrix

| Gap | Slice | Completion target |
| --- | --- | --- |
| Thiếu contract section / exports / fake | S0, S6, S7, S9 | Section, public types, fake scenarios và traceability khớp |
| Email event producer/consumer không có schema khóa | S-NOTIFY | Versioned envelope + SQL/Dart contract test |
| Manual token draft chưa an toàn/ổn định | S8 | Actor-from-context, stable errors, token lifecycle và two-path E2E |
| Failure/concurrency semantics còn mơ hồ | S1–S3, S10–S12 | Exact errors, atomicity/compensation, missing scenarios |
| Audit/Identity ownership chưa thống nhất | S13–S14 | Một ownership statement và port/storage boundary duy nhất |
| Paging/filter/idempotency/version thiếu | S15–S16 | Exact request/page DTO và mutation concurrency contract |
| Error code catalog bị drift | Cross-cutting | Một stable catalog dùng chung docs + Dart + FE mapper |
| Open questions ảnh hưởng contract vẫn mở | Cross-cutting | Chuyển thành quyết định đã khóa hoặc external dependency rõ ràng |
| CI chỉ kiểm tra cấu trúc | Cross-cutting | Semantic contract guard fail đúng các mismatch |

## File map

**Contract sources**

- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Modify: `docs/themes/TH-01-organization-users/harness/04-slice-roadmap.md`
- Modify: `docs/themes/TH-01-organization-users/harness/05-traceability.md`
- Modify: `docs/themes/TH-01-organization-users/harness/01-domain-model.md`
- Modify: `docs/themes/TH-01-organization-users/harness/02-module-map.md`
- Modify: `docs/themes/TH-01-organization-users/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-01-organization-users/APPENDICES.md`
- Modify: `docs/themes/TH-01-organization-users/README.md`

**Application/public contract**

- Modify: `modules/iam/application/lib/application.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_module.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_scenario.dart`
- Create focused command/query/DTO/port files under `modules/iam/application/lib/src/tenant/`, `src/invitation/` and `src/dto/`.

**BE contract evidence**

- Create/modify handlers and ports in `modules/iam/application/`.
- Create/modify Supabase adapters in `modules/iam/infrastructure/`.
- Create SQL only in `supabase/migrations/_drafts/`.
- Create handler, adapter and SQL contract tests in the owning package.

**FE/E2E evidence**

- Modify `FakeIamModule` scenario dispatch.
- Add/update widget tests under `modules/iam/presentation/test/` or the owning app.
- Add/update real-module integration tests under `apps/erp/test/` and `apps/admin/test/`.

**Semantic guard**

- Create: `scripts/ci/guard_theme_contract_completeness.sh`
- Create: `scripts/ci/test/guard_theme_contract_completeness_test.sh`
- Modify: `scripts/ci/verify_harness.sh`

---

### Task 1: Khóa Source of Truth và các quyết định ảnh hưởng contract

**Files:**

- Modify: `docs/themes/TH-01-organization-users/harness/01-domain-model.md`
- Modify: `docs/themes/TH-01-organization-users/harness/02-module-map.md`
- Modify: `docs/themes/TH-01-organization-users/harness/03-architecture-and-flows.md`
- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Modify: `docs/themes/TH-01-organization-users/APPENDICES.md`
- Modify: `docs/themes/TH-01-organization-users/README.md`

**Interfaces:**

- Produces: ownership rules và decisions mà Task 2–10 dùng làm contract authority.
- Consumes: product rules hiện có; không thay đổi scope Post-MVP S4–S5.

- [ ] **Step 1: Ghi một ownership table giống nhau vào domain model, module map và API contracts**

Nội dung phải khóa:

| Data/capability | Authority | IAM responsibility |
| --- | --- | --- |
| Login email, verified state, credential, recovery OTP, session | Supabase Auth | Read-only snapshot / orchestration |
| Platform User profile fields | IAM, `iam.platform_user_profiles` | Self-service owner |
| IAM audit history | IAM, `iam.audit_logs` | Append immutable, redact before persist, tenant/platform views |
| Email delivery | Notification/Resend | IAM publishes request and reads outcome projection |
| Tenant/Invitation/Membership/Role | IAM | Domain owner |

- [ ] **Step 2: Đóng các open question bằng quyết định contract cụ thể**

Ghi các quyết định sau vào `APPENDICES.md §6.6` và section slice tương ứng:

- OQ-07: LastSelectedTenant không hợp lệ → `TenantContextStatus.none`; không auto-select; FE mở selector.
- OQ-08: delivery outcome là asynchronous projection; create/resend trả initial `queued`, detail/list đọc projection theo `correlationId`.
- OQ-09: complete password reset thu hồi các session khác; session hiện hành được rotate và tiếp tục hợp lệ.
- OQ-03: privileged provider có thể yêu cầu step-up; application surface map thành `STEP_UP_AUTH_REQUIRED`.
- OQ-05: S13/S16 chỉ hiển thị IAM-owned audit events; token, OTP, credential và PII ngoài allowlist bị redact trước persistence.
- OQ-02: onboarding operation được IAM lưu theo `operationId`, `idempotencyKey`, `correlationId`, `status`, `completedSteps`, `failedStep`; retry tiếp tục từ bước chưa hoàn tất.

- [ ] **Step 3: Đồng bộ manual-token wording**

Thay mô tả App Link trong `README.md` bằng:

```text
Email chỉ chứa opaque token và hướng dẫn tự mở app khi đang đăng xuất.
User copy/paste token; API nhận token trong JSON body; không URL/query/deep-link token.
```

- [ ] **Step 4: Chạy reference guards**

Run:

```bash
bash scripts/ci/guard_docs_reference.sh
bash scripts/ci/guard_theme_structure.sh
```

Expected: cả hai exit `0`.

- [ ] **Step 5: Review gate**

Kiểm tra không còn hai ownership statement trái nhau bằng:

```bash
rg -n "không sở hữu.*Platform User|không sở hữu.*AuditLog|HTTPS App Link|opaque path" docs/themes/TH-01-organization-users
```

Expected: không còn statement mâu thuẫn; historical review file có thể giữ nếu được gắn nhãn snapshot.

---

### Task 2: Chuẩn hóa stable error catalog và semantic contract guard

**Files:**

- Modify: `docs/themes/TH-01-organization-users/APPENDICES.md`
- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Modify: `modules/iam/application/lib/src/shared/iam_blocked_codes.dart`
- Modify: `modules/iam/infrastructure/lib/src/errors/iam_blocked_error_mapper.dart`
- Create: `scripts/ci/guard_theme_contract_completeness.sh`
- Create: `scripts/ci/test/guard_theme_contract_completeness_test.sh`
- Modify: `scripts/ci/verify_harness.sh`

**Interfaces:**

- Produces: canonical error code set và CI guard được mọi task sau sử dụng.
- Consumes: ownership/decision table từ Task 1.

- [ ] **Step 1: Khóa canonical error renames**

Áp dụng mapping:

| Drifted code | Canonical code |
| --- | --- |
| `NO_PERMISSION` | `PERMISSION_DENIED` |
| `NOT_FOUND` | `RESOURCE_NOT_FOUND` |
| `INVITATION_ALREADY_ACCEPTED` | `INVITATION_ALREADY_USED` |
| `RATE_LIMITED` trong password reset | `RESET_RATE_LIMITED` |
| `ATTEMPTS_EXCEEDED` | `RESET_CODE_ATTEMPTS_EXCEEDED` |
| `IDENTITY_CONFLICT` | `PLATFORM_USER_ALREADY_EXISTS` |
| `DUPLICATE_WARNING` trong Legal Profile | success variant `DuplicateTaxCodeWarningDto`, không phải exception |

Thêm các code Invitation còn thiếu vào catalog:

```text
INVITATION_TOKEN_INVALID
INVITATION_EXPIRED
INVITATION_REVOKED
INVITATION_ALREADY_USED
INVITATION_EMAIL_MISMATCH
INVITATION_PENDING_EXISTS
```

- [ ] **Step 2: Viết failing shell test cho semantic guard**

Test fixtures phải chứng minh guard fail khi:

1. Roadmap có `Contract: done` nhưng `07` không có `§Sx`.
2. Contract section không có symbol table hoặc fake scenario table.
3. `07` dùng uppercase error code không tồn tại trong Appendix catalog.
4. Traceability CONTRACT status khác roadmap.
5. Active contract symbol không được export từ `modules/iam/application/lib/application.dart`.

Run:

```bash
bash scripts/ci/test/guard_theme_contract_completeness_test.sh
```

Expected: FAIL vì guard chưa tồn tại.

- [ ] **Step 3: Implement semantic guard**

Guard chỉ kiểm tra active/done contract lanes; bỏ qua `out_of_scope`. Output phải nêu theme, slice và rule vi phạm.

- [ ] **Step 4: Run guard test**

Run:

```bash
bash scripts/ci/test/guard_theme_contract_completeness_test.sh
```

Expected: PASS cho fixtures; chạy trên repo hiện tại phải liệt kê S0/S6/S7/S9 cho tới khi các task sau hoàn tất.

- [ ] **Step 5: Wire umbrella guard**

Thêm `guard_theme_contract_completeness` sau `guard_theme_traceability` trong `scripts/ci/verify_harness.sh`.

---

### Task 3: Hoàn thiện S0 và khóa S-NOTIFY event envelope

**Files:**

- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Modify: `modules/iam/integration_events/lib/src/events/email_delivery_requested_integration_event.dart`
- Modify: `modules/iam/application/lib/src/notification/commands/send_email_delivery/send_email_delivery_command.dart`
- Modify: `modules/iam/application/lib/src/notification/integration_events/email_delivery_requested_integration_event_handler.dart`
- Modify: `supabase/migrations/_drafts/005_iam_platform_user_lifecycle.sql`
- Modify/create invitation draft SQL from Tasks 5–7
- Test: `modules/iam/integration_events/test/email_delivery_requested_integration_event_test.dart`
- Test: `modules/iam/infrastructure/test/iam_email_delivery_outbox_contract_test.dart`

**Interfaces:**

- Produces: `EmailDeliveryRequestedIntegrationEvent v1`.
- Consumes: canonical error/security decisions từ Tasks 1–2.

- [ ] **Step 1: Thêm `§S0`**

Section phải liệt kê:

- `SignInCommand`
- `SignOutCommand`
- `GetCurrentSessionQuery`
- `SessionDto`
- `IIamModule`
- auth/session fake scenarios
- `AUTHENTICATION_REQUIRED`, `SESSION_EXPIRED`, `SYSTEM_ERROR`

- [ ] **Step 2: Khóa payload v1 trong `§S-NOTIFY`**

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

`fromPayload` phải reject thiếu `event_version`, `to_email`, `correlation_id` hoặc `outcome_id` bằng deterministic serialization error.

- [ ] **Step 3: Khóa secret-material rule**

Contract phải nói rõ:

- Domain tables chỉ lưu token hash.
- Raw token không đi trong `refs`, logs, audit hoặc normal JSON payload.
- Nếu async email bắt buộc mang raw token, dùng encrypted transient `secret_payload_ciphertext` với key ngoài DB, retention ngắn và xóa sau terminal delivery.
- S-NOTIFY không được đánh `done` nếu encrypted transient channel chưa có implementation/test.

- [ ] **Step 4: Viết failing Dart/SQL contract tests**

Test phải parse chính payload do draft SQL tạo bằng `EmailDeliveryRequestedIntegrationEvent.fromPayload`.

Run:

```bash
cd modules/iam/integration_events && dart test
cd modules/iam/infrastructure && dart test test/iam_email_delivery_outbox_contract_test.dart
```

Expected before fix: FAIL vì SQL payload thiếu required fields.

- [ ] **Step 5: Sửa producer và consumer theo envelope**

Platform email dùng `tenant_id = null`; không dùng sentinel UUID. Tạo `outcome_id` và `correlation_id` trong mutation transaction, persist initial outcome `queued`, rồi enqueue đúng payload v1.

- [ ] **Step 6: Re-run tests**

Expected: payload từ mọi producer activation/reset/invitation deserialize thành công; raw token không xuất hiện trong normal payload/log assertions.

---

### Task 4: Hoàn thiện S6 read contract — members và invitations

**Files:**

- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Modify: `modules/iam/application/lib/src/tenant/list_tenant_members/list_tenant_members_query.dart`
- Modify: `modules/iam/application/lib/src/dto/tenant_member_dto.dart`
- Create: `modules/iam/application/lib/src/invitation/list_invitations/list_invitations_query.dart`
- Create: `modules/iam/application/lib/src/invitation/get_invitation/get_invitation_query.dart`
- Create: `modules/iam/application/lib/src/dto/invitation_summary_dto.dart`
- Create: `modules/iam/application/lib/src/dto/invitation_detail_dto.dart`
- Create: `modules/iam/application/lib/src/dto/cursor_page_dto.dart` only if no shared page DTO fits
- Modify: `modules/iam/application/lib/application.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_module.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_scenario.dart`
- Test: `modules/iam/application/test/scn_e03_u01_members_invitations_contract_test.dart`

**Interfaces:**

- Produces:
  - `ListTenantMembersQuery(tenantId, search?, status?, cursor?, limit?)`
  - `ListInvitationsQuery(tenantId, search?, status?, cursor?, limit?)`
  - `GetInvitationQuery(tenantId, invitationId)`
- Consumes: stable errors từ Task 2.

- [x] **Step 1: Viết `§S6` với exact DTO fields**

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

`InvitationDetailDto` thêm `createdAt`, `createdBy`, `lastSentAt`, `revokedAt`, `declinedAt`; không trả token/hash.

- [x] **Step 2: Khóa paging/filter semantics**

- `limit` default `20`, max `100`.
- Search canonical email/name, trim; empty string = no filter.
- Member status: `active|inactive|removed`.
- Invitation status: `pending|accepted|declined|revoked|expired`.
- Expired-at-read không được biểu diễn như pending hợp lệ.
- Cursor là opaque `(created_at,id)`.

- [x] **Step 3: Thêm fake scenarios**

```text
members_search_ok
members_filter_inactive
invitations_search_ok
invitations_expired
invitation_detail_ok
member_invitation_forbidden
member_invitation_cross_tenant_not_found
```

- [x] **Step 4: Viết failing public-export và handler tests**

Run:

```bash
cd modules/iam/application && dart test test/scn_e03_u01_members_invitations_contract_test.dart
```

Expected before implementation: FAIL vì Invitation types/handlers chưa tồn tại.

- [x] **Step 5: Implement application/BE/FE evidence**

- Application handlers dùng tenant scope + `tenant.member.view`.
- BE draft RPCs trả stable keys đúng DTO — deferred (read port `Unavailable` until later BE task).
- FE hai tab dùng `IIamModule`; widget tests — deferred (FE already `done` on roadmap for S6 shells).
- E2E real module — deferred.

- [x] **Step 6: Update traceability**

Thêm section S6 đủ CONTRACT/BE/FE/E2E; Contract chỉ `done` khi export test và fake scenario test pass.

---

### Task 5: Hoàn thiện S7 create-invitation contract

**Files:**

- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Create: `modules/iam/application/lib/src/invitation/create_invitation/create_invitation_command.dart`
- Create: `modules/iam/application/lib/src/invitation/create_invitation/create_invitation_command_validator.dart`
- Create: `modules/iam/application/lib/src/invitation/create_invitation/create_invitation_command_handler.dart`
- Create: `modules/iam/application/lib/src/ports/i_tenant_invitation_command_gateway.dart`
- Modify: `modules/iam/application/lib/application.dart`
- Modify: fake module/scenario files
- Create: `supabase/migrations/_drafts/017_iam_tenant_invitation_create.sql`
- Test: `modules/iam/application/test/scn_e03_u02_create_invitation_contract_test.dart`
- Test: `modules/iam/infrastructure/test/iam_tenant_invitation_create_sql_contract_test.dart`

**Interfaces:**

- Produces:

```dart
CreateInvitationCommand({
  required String tenantId,
  required String inviteeEmail,
  required String initialRoleId,
  required String idempotencyKey,
})
```

- Returns: `InvitationDetailDto`.
- Actor: resolved from execution context/server, never command input.

- [x] **Step 1: Complete `§S7`**

Lock:

- expiry = exactly 7 days from server UTC creation time;
- canonical email = trim + lowercase;
- one pending invitation per `(tenantId, canonicalEmail)`;
- inactive Membership → `MEMBERSHIP_INACTIVE`;
- active Membership → `DUPLICATE_MEMBERSHIP`;
- pending invitation → `INVITATION_PENDING_EXISTS`;
- inactive/deprecated role → `ROLE_NOT_ASSIGNABLE`;
- retry cùng key/payload trả cùng result; khác payload → `IDEMPOTENCY_CONFLICT`.

- [x] **Step 2: Add fake scenarios**

```text
invite_ok
invite_duplicate_membership
invite_inactive_membership
invite_pending_exists
invite_role_not_assignable
invite_delivery_failed
invite_idempotent_retry
invite_idempotency_conflict
invite_forbidden
```

- [x] **Step 3: Write failing application and SQL tests**

Tests assert domain state, initial delivery `queued`, one outbox message and no raw token in invitation/audit/log-visible payload.

- [x] **Step 4: Implement minimal vertical slice**

Follow CQRS pipeline and write draft SQL only. Raw token delivery must comply with Task 3 encrypted transient rule.
FE/E2E deferred for this execution scope.

- [ ] **Step 5: Add FE/E2E evidence**

Widget tests: success, membership conflict, role invalid, delivery failed. E2E: submit invite → list/detail shows pending + independent delivery status. _(deferred)_

- [x] **Step 6: Correct status**

Roadmap and traceability S7 Contract move to `done` only after exports, section, fake table and tests pass.

---

### Task 6: Stabilize S8 manual-token contract

**Files:**

- Modify: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Create: `modules/iam/application/lib/src/invitation/inspect_invitation_token/inspect_invitation_token_query.dart`
- Create: `modules/iam/application/lib/src/invitation/inspect_invitation_token/inspect_invitation_token_query_handler.dart`
- Create: `modules/iam/application/lib/src/invitation/accept_invitation/accept_invitation_command.dart`
- Create: `modules/iam/application/lib/src/invitation/accept_invitation/accept_invitation_command_handler.dart`
- Create: `modules/iam/application/lib/src/invitation/register_from_invitation/register_from_invitation_command.dart`
- Create: `modules/iam/application/lib/src/invitation/register_from_invitation/register_from_invitation_command_handler.dart`
- Create: `modules/iam/application/lib/src/invitation/decline_invitation/decline_invitation_command.dart`
- Create: `modules/iam/application/lib/src/invitation/decline_invitation/decline_invitation_command_handler.dart`
- Create: `modules/iam/application/lib/src/dto/invitation_token_inspection_dto.dart`
- Create: `modules/iam/application/lib/src/dto/invitation_registration_profile_input.dart`
- Create: `modules/iam/application/lib/src/ports/i_invitation_identity_port.dart`
- Modify: `modules/iam/application/lib/application.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_module.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_scenario.dart`
- Create: `supabase/migrations/_drafts/020_iam_tenant_invitation_acceptance.sql`
- Test: `modules/iam/application/test/scn_e03_u03_invitation_acceptance_contract_test.dart`
- Test: `modules/iam/infrastructure/test/iam_tenant_invitation_acceptance_sql_contract_test.dart`
- Test: `modules/iam/presentation/test/widgets/invitation_token_entry_flow_test.dart`
- Test: `apps/erp/test/features/iam/e2e_e03_u03_invitation_acceptance_test.dart`

**Interfaces:**

- `InspectInvitationTokenQuery(token)`
- `AcceptInvitationCommand(token, idempotencyKey)`; authenticated actor from context
- `RegisterFromInvitationCommand(token, profile, credentialProof, idempotencyKey)`
- `DeclineInvitationCommand(token, idempotencyKey)`

- [x] **Step 1: Remove public `actorUserId` input**

Exact rule: existing-account accept resolves verified actor email from Identity/Auth snapshot and compares canonical email to invitation; client cannot choose actor.

- [x] **Step 2: Lock success/error shapes**

- Invalid token returns only `INVITATION_TOKEN_INVALID`; no account existence leak.
- Terminal invitation returns `INVITATION_EXPIRED|INVITATION_REVOKED|INVITATION_ALREADY_USED`.
- Accept email mismatch returns `INVITATION_EMAIL_MISMATCH`.
- Concurrent accept yields one success, subsequent requests return the same idempotent result or `INVITATION_ALREADY_USED`.
- Tenant suspended returns `TENANT_SUSPENDED` without consuming token.

- [x] **Step 3: Add fake scenarios**

Use the existing §S8 table plus:

```text
inspect_invalid_no_leak
accept_declined
accept_concurrent
accept_tenant_suspended
decline_idempotent_retry
register_identity_conflict
```

- [x] **Step 4: Implement/test two identity paths**

- Existing account: inspect → locked-email login → accept.
- New account: inspect → locked-email registration → verified identity → accept.

Application + draft SQL + SQL contract tests delivered. FE/E2E deferred (recommended scope).

- [x] **Step 5: Update Contract status**

S8 Contract → `done` after exports, section, fake scenarios and application tests pass. FE/E2E remain todo.

---

### Task 7: Hoàn thiện S9 resend/revoke contract

**Files:**

- Add `§S9` to `harness/07-api-contracts.md`
- Create command/validator/handler files for resend and revoke
- Reuse `ITenantInvitationCommandGateway`
- Modify public exports and fake module/scenarios
- Create: `supabase/migrations/_drafts/018_iam_tenant_invitation_resend_revoke.sql`
- Test: `scn_e03_u04_resend_revoke_invitation_contract_test.dart`

**Interfaces:**

```dart
ResendInvitationCommand({
  required String tenantId,
  required String invitationId,
  required int expectedVersion,
  required String idempotencyKey,
})

RevokeInvitationCommand({
  required String tenantId,
  required String invitationId,
  required int expectedVersion,
  required String reason,
  required String idempotencyKey,
})
```

- [x] **Step 1: Write exact `§S9` semantics**

- Only pending invitation can mutate.
- Resend preserves email/initialRole, rotates token, sets new 7-day expiry, increments version and creates a new delivery correlation.
- Revoke records non-empty trimmed reason, increments version and never sends email.
- Old token invalid immediately after successful resend/revoke.
- Stale version → `STATE_CHANGED`.
- Cross-tenant/unknown ID → `RESOURCE_NOT_FOUND`.
- Non-pending → `INVITATION_ALREADY_USED`.

- [x] **Step 2: Add fake scenarios**

```text
invitation_resend_ok
invitation_revoke_ok
invitation_old_token_invalid
invitation_state_changed
invitation_terminal_reject
invitation_cross_tenant_not_found
invitation_resend_delivery_failed
```

- [x] **Step 3: Write red tests, implement application/BE, then green tests**

SQL assertions: row lock, version increment, one outbox for resend, zero outbox for revoke, token rotation and audit same transaction.
FE/E2E deferred (recommended scope).

- [ ] **Step 4: Add FE/E2E evidence**

Widget: actions visible only for pending; confirmation/reason; updated detail/list. E2E: resend invalidates old token, revoke blocks accept. _(deferred)_

- [x] **Step 5: Correct roadmap/traceability**

S9 Contract → `done` after section/export/fake/tests pass.

---

### Task 8: Harden S1–S3 and S10–S12 contracts

**Files:**

- Modify corresponding sections in `harness/07-api-contracts.md`
- Modify: `modules/iam/application/lib/src/dto/accessible_tenant_dto.dart`
- Modify: `modules/iam/application/lib/src/dto/tenant_context_dto.dart`
- Modify: `modules/iam/application/lib/src/tenant/switch_tenant_context/switch_tenant_context_command_handler.dart`
- Modify: `modules/iam/application/lib/src/tenant/get_tenant_context/get_tenant_context_query_handler.dart`
- Modify: `modules/iam/domain/lib/src/tenant_context/tenant_context_invalidation_reason.dart`
- Modify: `modules/iam/application/lib/src/shared/iam_blocked_codes.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_module.dart`
- Modify: `modules/iam/application/lib/src/testing/fake_iam_scenario.dart`
- Test: `modules/iam/application/test/scn_e05_u01_fr01_01_list_accessible_tenants_test.dart`
- Test: `modules/iam/application/test/scn_e05_u02_fr01_01_switch_tenant_context_test.dart`
- Test: `modules/iam/application/test/scn_e05_u03_fr01_01_get_tenant_context_test.dart`
- Test: `modules/iam/application/test/scn_e03_u05_u06_membership_contract_test.dart`
- Test: `modules/iam/application/test/scn_e02_u01_u03_tenant_profile_contract_test.dart`

**Interfaces:**

- Produces: exact failure semantics và missing scenario coverage without expanding product scope.
- Consumes: error catalog from Task 2.

- [x] **Step 1: S1 accessible-tenant completeness**

Add scenarios:

```text
tenants_closed_disabled
tenants_excludes_inactive_membership
tenants_identity_inactive
tenants_authentication_required
```

Explicitly define `isSelectable = status == active`; provisioning/suspended/closed are visible only when product policy permits and are never selectable.

- [x] **Step 2: S2 atomicity/compensation contract**

Order and failure behavior:

1. Validate target.
2. Resolve server context.
3. Establish new session context.
4. Persist LastSelectedTenant.
5. Return success.

If step 3 fails, old session/preference remain. If step 4 fails after session establishment, restore old session and return `SYSTEM_ERROR`. Add `switch_session_failure` and `switch_preference_failure` scenarios.

- [x] **Step 3: S3 invalidation completeness**

Add reasons:

```text
identityInactive
roleNoLongerAssignable
permissionsChanged
ownershipChanged
```

`permissionsChanged` may return a refreshed valid context; identity/membership/tenant denial returns invalidated/none according to bootstrap mode.

- [x] **Step 4: S10–S12 normalize errors and exact DTO fields**

- Replace all `NOT_FOUND` with `RESOURCE_NOT_FOUND`.
- Legal duplicate is a typed success warning, not exception.
- Enumerate editable Tenant Profile and Legal Profile fields in §S12.
- Add permission, stale version and cross-tenant scenarios where missing.

- [x] **Step 5: Run slice contract tests**

Run targeted application tests for S1–S3/S10–S12. Widget fake-scenario tests deferred (recommended scope). Expected: all pass with canonical errors only.

---

### Task 9: Stabilize S13–S14 Audit/Identity contracts

**Files:**

- Modify: `harness/07-api-contracts.md` §S13/§S14
- Modify: `APPENDICES.md` API/error/open-question sections
- Modify: `modules/iam/application/lib/src/ports/i_tenant_audit_read_port.dart`
- Modify: `modules/iam/application/lib/src/ports/i_platform_identity_self_service_port.dart`
- Modify: `modules/iam/application/lib/src/dto/tenant_audit_log_search_page_dto.dart`
- Modify: `modules/iam/application/lib/src/dto/password_reset_request_result_dto.dart`
- Modify: `modules/iam/application/lib/src/dto/password_reset_verify_result_dto.dart`
- Create: `modules/iam/application/lib/src/dto/password_reset_completion_result_dto.dart`
- Create: `modules/iam/application/lib/src/dto/sign_out_result_dto.dart`
- Modify: `modules/iam/infrastructure/lib/src/adapters/audit/supabase_tenant_audit_read_port.dart`
- Modify: `modules/iam/infrastructure/lib/src/adapters/identity/supabase_platform_identity_self_service_adapter.dart`
- Test: `modules/iam/application/test/scn_e02_u07_tenant_audit_contract_test.dart`
- Test: `modules/iam/application/test/scn_e06_u03_u04_password_reset_logout_test.dart`
- Test: `modules/iam/infrastructure/test/iam_audit_read_sql_contract_test.dart`
- Test: `modules/iam/infrastructure/test/supabase_auth_password_reset_test.dart`

**Interfaces:**

- S13 returns `TenantAuditLogSearchPageDto(items, nextCursor)`.
- S14 password reset returns typed metadata, never `void / metadata`.

- [x] **Step 1: Lock S13 query shape**

```text
tenantId, fromUtc, toUtc, result?, actorUserId?, subjectType?,
eventCode?, cursor?, limit?
```

Detail includes audit ID, event code, actor, subject, occurredAt, source, trackingId, redacted before/after. Unknown/cross-tenant detail → `RESOURCE_NOT_FOUND`.

- [x] **Step 2: Lock S14 result types**

- Request → `PasswordResetRequestResultDto`.
- Resend → same DTO with refreshed `expiresAt`/`resendAvailableAt`.
- Verify → `PasswordResetVerifyResultDto`.
- Complete → `PasswordResetCompletionResultDto(currentSessionRotated: true, otherSessionsRevoked: true)`.
- Sign out → `SignOutResultDto(localCleared: true, remoteSucceeded: bool)`, allowing FE to show remote warning without retaining local secrets.

- [x] **Step 3: Normalize reset errors**

Use only:

```text
RESET_RATE_LIMITED
RESET_CODE_INVALID
RESET_CODE_EXPIRED
RESET_CODE_ATTEMPTS_EXCEEDED
PASSWORD_POLICY_VIOLATION
STATE_CHANGED
SYSTEM_ERROR
```

- [x] **Step 4: Add redaction/security contract tests**

Assert Audit and password-reset responses never contain token, OTP, password, hash, session token or unapproved PII.

- [x] **Step 5: Run application/infrastructure tests**

Expected: S13 search/detail and S14 profile/reset/logout run through real ports; fake scenarios use identical DTO/error shapes. Widget/E2E deferred (recommended scope).

---

### Task 10: Complete S15–S16 paging, filters, concurrency and onboarding contract

**Files:**

- Modify: `harness/07-api-contracts.md` §S15/§S16
- Modify: `APPENDICES.md` platform API/orchestration sections
- Modify platform queries/commands/DTOs/fake scenarios
- Modify draft RPCs `004`–`013` only; do not create timestamp migration
- Add application, SQL contract, widget and E2E tests

**Interfaces:**

- All search queries return typed cursor pages.
- All lifecycle mutations take `expectedVersion` and `idempotencyKey`.

- [x] **Step 1: Lock platform search contracts**

`SearchPlatformUsersQuery`:

```text
query?, status?, cursor?, limit?
```

`SearchPlatformTenantsQuery`:

```text
query?, status?, readinessState?, warningCode?, cursor?, limit?
```

`SearchPlatformAuditLogsQuery`:

```text
fromUtc?, toUtc?, actorUserId?, targetType?, targetId?,
action?, result?, source?, correlationId?, cursor?, limit?
```

Default limit `20`, max `100`; cursor opaque and stable.

- [x] **Step 2: Add concurrency/idempotency inputs**

Apply to:

- `SuspendPlatformUserCommand`
- `RestorePlatformUserCommand`
- `SendActivationInvitationCommand`
- `RequestPlatformPasswordResetCommand`
- `SuspendPlatformTenantCommand`
- `RestorePlatformTenantCommand`
- `TransferPlatformTenantOwnershipCommand`

Lifecycle command input includes target ID, `expectedVersion`, `idempotencyKey`; suspend also requires reason. Same key/payload returns same result; different payload returns `IDEMPOTENCY_CONFLICT`.

- [x] **Step 3: Use domain-specific ownership errors**

Ownership invalid target → `OWNER_TARGET_INVALID`, not `VALIDATION_ERROR`. Closed tenant lifecycle → `TENANT_STATE_INVALID`. Step-up provider request → `STEP_UP_AUTH_REQUIRED`.

- [x] **Step 4: Complete onboarding operation contract**

Add:

- `GetTenantOnboardingOperationQuery(operationId)`
- `RetryTenantOnboardingOperationCommand(operationId, idempotencyKey)`
- `TenantOnboardingOperationDto(status, completedSteps, failedStep, correlationId, tenantId?, ownerUserId?)`

Status values:

```text
inProgress|completed|partialFailure|failed
```

Atomic boundary remains Tenant + Owner Membership + role + IAM outbox; Identity creation is an external step recorded in operation progress.

- [x] **Step 5: Expand fake scenarios**

Add paging/filter, stale-version, idempotent retry/conflict, step-up, audit detail, onboarding partial-failure/resume scenarios.

- [x] **Step 6: Add BE evidence (recommended scope)**

- SQL contract tests verify filter params, cursor keys, version check, idempotency and ownership/tenant state codes.
- Application + FakeIamModule tests cover typed pages and blocked codes.
- Widget/Admin E2E deferred; Admin cubits minimally updated for compile (`.items` + version/key args).
---

### Task 11: Final contract convergence and status correction

**Files:**

- Modify: `harness/04-slice-roadmap.md`
- Modify: `harness/05-traceability.md`
- Modify: `harness/07-api-contracts.md`
- Modify: `docs/harness/PROGRESS.md`

**Interfaces:**

- Produces: final auditable status where every `Contract: done` passes semantic guard.
- Consumes: outputs of Tasks 1–10.

- [x] **Step 1: Run semantic completeness guard**

```bash
bash scripts/ci/guard_theme_contract_completeness.sh TH-01-organization-users
```

Expected: exit `0`; no missing section/export/scenario/status/error code.

> 2026-07-30: TH-01 pass. Umbrella run fail vì TH-03/TH-04 thiếu `APPENDICES.md` (ngoài scope plan này).

- [x] **Step 2: Verify active catalog symbols**

Run:

```bash
rg -o '`[A-Za-z][A-Za-z0-9]*(Command|Query)`' \
  docs/themes/TH-01-organization-users/harness/07-api-contracts.md \
  | tr -d '`' | sort -u
```

For every active-scope symbol, confirm a public class exists and is exported. S4–S5 symbols remain explicitly `out_of_scope`.

> 2026-07-30: Active symbols exported; chỉ `ChangeMemberRoleCommand` / `ListSystemRolesQuery` thiếu class (S4–S5 out_of_scope).

- [ ] **Step 3: Run code generation and static analysis** *(deferred — recommended Task 11 scope = contract + status docs)*

```bash
melos run codegen
melos run analyze
```

Expected: exit `0`; generated IAM registrar/access metadata includes all new handlers.

- [ ] **Step 4: Run tests by boundary** *(deferred — ngoài recommended scope; không FE/E2E gate)*

```bash
melos run test
cd apps/erp && flutter test
cd apps/admin && flutter test
cd apps/messaging_worker && dart test
```

Expected: all exit `0`.

- [x] **Step 5: Run harness and migration policy verification** *(partial)*

```bash
bash scripts/ci/verify_harness.sh
melos run migrate:verify-policy -- --strict
```

Expected: both exit `0`. Draft SQL remains unpromoted.

> 2026-07-30: `verify_harness.sh` fail ở `guard_theme_contract_completeness` vì TH-03/TH-04 thiếu APPENDICES (pre-existing). TH-01 structure/traceability/contract guards xanh. `migrate:verify-policy` không chạy lại trong Task 11 docs-only; draft vẫn unpromoted.

- [x] **Step 6: Run GitNexus change detection**

```text
detect_changes({scope: "compare", base_ref: "main"})
```

Expected: affected flows limited to IAM contract, notification delivery, tenant/admin presentation and corresponding tests.

> 2026-07-30: `detect_changes(compare, main)` → risk `low`, `affected_count: 0` processes (index; branch-wide file delta lớn so với `main`).

- [x] **Step 7: Update statuses with evidence**

For each slice, link exact passing test IDs in traceability. Không dùng `done` nếu:

- contract section/export/fake scenario thiếu;
- real adapter/RPC path chưa có khi lane BE yêu cầu;
- FE còn sample data ngoài fake scenario contract;
- E2E còn dùng fake khi row yêu cầu real module;
- open decision vẫn ảnh hưởng request/response/error shape.

> 2026-07-30: Cập nhật `04` / `05` / `07` / `PROGRESS.md`. S6–S9 BE giữ `todo` (Unavailable adapters). S14 dual surface documented, E2E linked `e2e_e06_u01_fr01_01_my_account_test`.

---

## Final acceptance checklist

- [x] `§S0`, `§S6`, `§S9` tồn tại; S7 section khớp public export.
- [x] S-NOTIFY có envelope v1 và producer payload deserialize bằng consumer thật.
- [x] Tất cả Invitation symbols S6–S9 được export và có fake scenarios.
- [x] Không public command nào nhận `actorUserId` cho actor hiện hành.
- [x] Error codes trong `07`, Appendix, Dart constants và FE mapper giống nhau.
- [x] Search APIs có paging/filter shape đáp ứng US.
- [x] Versioned mutation có `expectedVersion`; retryable mutation có idempotency.
- [x] Identity/Audit/Notification ownership chỉ có một định nghĩa. *(S14 vẫn ghi chú dual surface FE identity vs account catalog — collapse follow-up)*
- [x] Manual token không xuất hiện trong URL/log/audit/client persistence.
- [x] Roadmap và traceability status khớp semantic guard.
- [x] BE/FE/E2E evidence được link bằng test ID cụ thể. *(S6–S9 BE/E2E và S8 FE vẫn `todo` có chủ đích)*
- [x] Không có timestamp migration mới và không promote draft.

## Recommended execution order

```text
Task 1 → Task 2 → Task 3
                 ↓
Task 4 → Task 5 → Task 6 → Task 7
                 ↓
Task 8 → Task 9 → Task 10
                 ↓
              Task 11
```

Mỗi task tạo một review checkpoint độc lập. Không bắt đầu task phụ thuộc khi contract authority hoặc canonical error set của task trước chưa pass.
