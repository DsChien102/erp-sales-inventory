# Deferred Invitation Identity and Membership Design

**Date:** 2026-09-18

**Status:** Updated on 2026-09-21 for same-row Owner Invitation resend; awaiting review

## Goal

Sending an invitation must not create or reactivate an
`iam.platform_user_profiles` row or an `iam.memberships` row. Identity/profile
materialization and membership creation happen only when the invitee accepts a
valid invitation.

This rule applies to:

- tenant member invitations created by `iam.create_tenant_invitation`;
- platform-admin tenant onboarding created by `iam.create_tenant_onboarding`;
- owner invitation resend/email updates performed by
  `iam.reinvite_provisioning_owner`.

## Approved semantics

### Before acceptance

An invitation operation may create or update only the state needed to deliver
and track the invitation:

- the tenant and optional legal profile during platform onboarding;
- the tenant default store, where the existing onboarding contract requires it;
- one `iam.tenant_invitations` row in `pending` state;
- the email delivery outbox/internal-command payload and delivery outcome;
- audit and idempotency records.

It must not:

- insert or reactivate an `iam.memberships` row for the invitee;
- insert a placeholder `iam.platform_user_profiles` row;
- invent a placeholder user UUID;
- expose the invitee through member or platform-user lists before acceptance.

`TenantOnboardingResultDto.ownerMembershipId` is `null` before acceptance.
For a new owner, `ownerUserId` is also `null`; for an existing Auth user it may
contain the already-existing user id, but onboarding does not mutate that
user's profile or memberships.

Invitation-only email addresses must not appear in Platform Admin's Platform
User list or detail, or in Tenant App's member list. An Auth user or real
Platform User that already existed before the invitation remains a real user;
the invitation must not create another user or a membership for that tenant.

### Acceptance boundary

`iam.accept_invitation` is the only IAM database mutation that turns a pending
invitation into tenant access. In one transaction it must:

1. validate and lock the invitation;
2. resolve the verified Auth user and enforce canonical-email equality;
3. upsert the real `iam.platform_user_profiles` row for that Auth user;
4. create the active membership with the invitation's role, or `store_owner`
   for an owner invitation;
5. set `accepted_membership_id` and move the invitation to `accepted`;
6. persist audit, outbox, and idempotency results atomically.

The existing registration path may create/update the real profile immediately
before calling `accept_invitation`; the acceptance upsert must therefore be
idempotent and preserve non-empty profile fields already captured during
registration.

### Decline, revoke, expiry, and compatibility

New invitations have `target_membership_id = null`, so decline, revoke, and
expiry only change invitation lifecycle state. They do not delete profiles or
memberships because none were created by the invitation.

The existing nullable `target_membership_id` column and unwind helpers remain
temporarily for historical invitations created under the hybrid pre-create
model. Old pending rows with a target membership must still be safely unwound;
no destructive schema cleanup is part of this change.

### Platform-admin projections

A provisioning tenant may have no owner membership until acceptance. Platform
tenant detail and search projections must still show the intended owner by
using this precedence:

1. active `is_owner` membership joined to the real profile/Auth user;
2. otherwise, the newest pending owner `tenant_invitations` row.

The pending projection returns owner name/email from the invitation,
`ownerUserId = null` for a new owner, `unverifiedEmail = true`, and does not
add an entry to the members list. Admin detail must also expose the latest
owner-invitation email and effective state so the resend sheet can prefill the
correct email and distinguish resend-eligible `pending`/`expired` from terminal
`accepted`/`declined`/`revoked`. A stored `pending` row past `expires_at` is
reported as `expired`. The member count never includes an invitation.

### Provisioning readiness

For a `provisioning` tenant with no active owner membership:

- if a pending owner invitation is unexpired, show an expected
  `OWNER_ACCEPTANCE_PENDING` condition: “Đang chờ chủ sở hữu chấp nhận lời mời”;
- if no valid pending owner invitation exists, show
  `OWNER_INVITATION_EXPIRED`: “Lời mời hết hạn”. This phase uses that product
  wording for the no-valid-invitation state and does not add a separate
  recovery action to the readiness screen;
- in both cases `can_activate = false`; `iam.activate_tenant` continues to
  re-evaluate readiness and reject activation in the transaction.

If there are multiple active owners, or a tenant is already `active` or
`suspended` without exactly one active owner membership, retain
`OWNER_MEMBERSHIP_INVALID`. Accepting the invitation removes the pending/expired
owner condition; the other readiness checks still apply. Readiness is derived,
not stored as a tenant lifecycle status.

### Reuse the owner invitation when resending or changing email

`iam.reinvite_provisioning_owner` must require a provisioning tenant with no
active owner membership and lock both the tenant and its latest owner
invitation. It reuses that `tenant_invitations` row: the operation keeps the
same `invitation_id` and `created_at`, and must not expire/delete that row and
insert a replacement.

Only a `pending` or `expired` owner invitation may be reused. A pending
invitation remains `pending` even when it was still valid before the request.
An invitation whose stored status is `expired` moves back to `pending`.
`accepted`, `declined`, and `revoked` are terminal for this operation and must
be rejected rather than reopened.

For both same-email resend and changed-email resend, the RPC updates the reused
row with the canonical requested email, a new token hash, a new expiry, a new
delivery correlation, `last_sent_at`, an incremented `version`, and
`updated_at`. The old token becomes unusable in the same transaction. It
updates `status_changed_at` only when the stored status actually changes
(`expired` to `pending`); a `pending` to `pending` resend leaves
`status_changed_at` unchanged. `accepted_membership_id` and
`target_membership_id` remain null for a new deferred invitation.

Resend only changes the delivery email and the technical resend state. For both
same-email and changed-email resend, preserve `given_name`, `family_name`,
`phone`, `initial_role_id`, and `created_at` on the reused invitation. The
email-only UI must never replace or clear that invitee identity metadata.
Before updating, apply the same active/inactive membership and
pending-invitation conflict checks to the requested email that creation uses,
excluding the locked invitation itself from the pending conflict check.

The delivery request, audit record, and idempotency result are committed with
the invitation update. A successful operation returns the same
`invitation_id` and `ownerMembershipId = null`. A replay of the same
idempotency key returns the stored result before rotating another token or
enqueueing another email.

### App ownership and presentation

- Platform Admin App owns owner invitations created during tenant onboarding.
  Tenant App does not manage those provisioning-owner invitations.
- Tenant App owns ordinary tenant membership invitations, including their
  resend/revoke actions and a separate “Lời mời” area. Platform Admin App no
  longer offers ordinary tenant-member invitation management.
- PA-D-01 lists only real Platform Users, excludes invitation-only rows, and
  removes the “Chờ kích hoạt” filter. PA-D-03 shows the user's email directly
  beneath the name, replacing “Tài khoản nền tảng”. PA-O-02 pending-user
  actions are removed from the Platform User detail surface.
- PA-SG-02 is the Admin tenant detail reached after successful onboarding and
  on later visits. In this UI slice, keep the existing “Thao tác” bottom-bar
  button and change only two bottom sheets for a provisioning tenant whose
  latest Owner Invitation is `pending` or `expired`. The first, “Thao tác”,
  has one row: “Gửi lại email” with subtitle “Gửi lại liên kết thiết lập cho
  Chủ sở hữu”. “Tạm ngừng tổ chức” remains hidden in this state, as it is
  today; “Thay đổi chủ sở hữu” is not offered there. Tapping the resend row
  opens “Gửi lại email thiết lập?”, with description “Liên kết hiện tại sẽ hết
  hiệu lực. Kiểm tra hoặc cập nhật email trước khi gửi lại.”, label “Email nhận
  liên kết”, a prefilled editable invitation email, helper “Có thể sửa email
  trước khi gửi lại.”, and “Gửi” / “Hủy” buttons. Keeping or changing the
  email calls the same server-side invitation-update operation, refreshes
  detail on success, and never mutates a Platform User or Membership before
  acceptance. Once the tenant is active, “Gửi lại email” is no longer
  available: the action sheet keeps “Thay đổi chủ sở hữu” and the other
  existing active-tenant actions instead. A suspended tenant likewise keeps
  its existing actions without owner-invitation resend. The page background,
  alerts, and action bar are outside this UI slice.
- TA-D-01 member list renders only real tenant memberships; a pending ordinary
  invitation appears only in the separate “Lời mời” area.

The normal PA-SG-02 resend/email-update action is in scope. The separate
readiness-screen recovery flow for an already-expired invitation is not in
scope now; the readiness screen only displays “Lời mời hết hạn”. Admin tenant
detail may still use its normal owner-invitation action. The resend action is
available only when the latest Owner Invitation's effective state is
`pending` or `expired`; it is hidden for `accepted`, `declined`, and
`revoked`. If that leaves a `settingUp` tenant with no eligible action, do not
open an empty action sheet.

## Interfaces

Public Dart command and gateway signatures remain unchanged:

- `CreateInvitationCommand -> InvitationDetailDto`
- `CreateTenantOnboardingCommand -> TenantOnboardingResultDto`
- `ReinviteProvisioningOwnerCommand -> TenantOnboardingResultDto`

`TenantOnboardingResultDto.ownerMembershipId` and `ownerUserId` are already
nullable, so the behavioral change requires documentation and fake/test updates
but no breaking type change.

The RPC signatures also remain unchanged. Only their transactional behavior and
result values change.

## Idempotency and concurrency

- Keep the existing operation scopes and stable client idempotency keys.
- A replay returns the original invitation/onboarding snapshot without creating
  identity or membership state.
- A replay of the same reinvite idempotency key returns its original result
  before changing the invitation, rotating another token, or enqueueing another
  email.
- Business state, invitation, delivery request, audit, and idempotency result
  stay in one database transaction.
- `accept_invitation` must lock before checking/creating membership so two
  concurrent accepts cannot create two memberships.
- Existing membership and pending-invitation uniqueness checks remain server
  authoritative. For a changed email, the reinvite RPC excludes the locked
  invitation itself but rejects a different pending invitation for the same
  tenant and canonical email.

## Migration strategy

Implementation starts as four atomic IAM SQL drafts sharing one intent:

- `supabase/migrations/_drafts/001_iam_patch_deferred_invitation_writes.sql`
- `supabase/migrations/_drafts/002_iam_patch_deferred_invitation_reads.sql`
- `supabase/migrations/_drafts/003_iam_patch_platform_user_invitation_visibility.sql`
- `supabase/migrations/_drafts/004_iam_patch_provisioning_owner_readiness.sql`

Each draft owns only RPCs whose bodies actually change and lists all of them in
`-- Touches:`. They may later be promoted together with `--bundle-intent`. No
timestamped migration or `REGISTRY.yaml` update is allowed
without a separate, explicit promotion request.

## Alternatives rejected

1. **Pre-create an inactive membership.** This still creates the membership
   record at send time and leaves invitation cleanup coupled to membership
   lifecycle.
2. **Keep a placeholder profile but defer membership.** This still pollutes the
   platform-user source of truth with a person who has not accepted.
3. **Create a separate pending-invitee table.** `tenant_invitations` already
   contains the required email, owner name/phone, role, status, and delivery
   metadata; another table would duplicate lifecycle state.
4. **Expire the old Owner Invitation and insert a replacement.** Resend and
   email correction are revisions of the same outstanding invitation. Keeping
   its identity avoids duplicate invitation history while token rotation,
   versioning, audit, and idempotency still preserve security and traceability.

## Acceptance criteria

- Sending a tenant member invitation for a new email changes the invitation,
  delivery, audit, and idempotency tables but not profiles or memberships.
- Creating or re-inviting a tenant owner from Admin does not create a profile or
  membership.
- The Admin tenant list/detail still shows the pending owner from invitation
  data and distinguishes pending from expired; the members list remains empty
  for that owner.
- Provisioning with a valid pending owner invitation reports waiting, not
  `OWNER_MEMBERSHIP_INVALID`; without a valid invitation it reports “Lời mời
  hết hạn”. Both block activation. Active/suspended tenants still require
  exactly one active owner membership.
- Admin Platform User list excludes invitation-only rows and its pending filter
  and pending-user actions are removed; an existing real user is not deleted.
- For a provisioning tenant, Admin detail retains its existing “Thao tác”
  bottom bar. Its action sheet shows only “Gửi lại email”, never “Tạm ngừng tổ
  chức”; that row opens the prefilled “Gửi lại email thiết lập?” sheet with
  editable email and “Gửi” / “Hủy”. This UI slice does not modify background
  alerts or the action bar. Same-email and changed-email submissions both
  preserve the existing `invitation_id`, rotate its token, renew its expiry,
  and enqueue a new delivery without inserting or deleting an Invitation.
- For an active or suspended tenant, the action sheet does not show “Gửi lại
  email”; existing ownership-transfer and lifecycle actions remain available
  under their current status rules.
- Platform Admin does not manage ordinary member invitations; Tenant App keeps
  its ordinary invitation area separate from the membership list.
- Accepting an invitation creates/upserts the real profile and creates exactly
  one active membership in the same transaction as consuming the invitation.
- Decline/revoke/expiry of a new invitation leaves no invitee profile or
  membership to clean up.
- Historical hybrid invitations with a non-null `target_membership_id` remain
  safe to accept or unwind.
- Same-email resend and changed-email resend reuse the existing
  `pending`/`expired` Owner Invitation; they do not reopen
  `accepted`/`declined`/`revoked` invitations.
- The Admin resend action is not offered for
  `accepted`/`declined`/`revoked` Owner Invitations; no empty action sheet is
  shown.
- Idempotent retry returns the same result without a second token rotation,
  delivery request, invitation, profile, or membership.
- Theme 1 QA expectations for onboarding, Platform Users, pending owners,
  invitation resend/email update, and member lists are updated with focused
  regressions; no external QA artifact absent from this repo is assumed to
  exist.
