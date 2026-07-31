# TH-01 — Appendices

**Canonical:** [Theme-1-organization-users.md](Theme-1-organization-users.md) §6

Tài liệu dưới đây mirror Appendix Theme 1 để tra cứu nhanh khi viết US / implement. UI/UX Screen Groups vẫn đọc §5 trong canonical.

---

## Appendix (from Theme-1 §6)

## 6.1 API contracts

### 6.1.1 Common API principles

- Sử dụng JSON over HTTPS và stable versioning theo platform API convention.

- Actor phải được xác thực, trừ activation và Invitation endpoint công khai được bảo vệ bằng one-time token, expiry và rate limit.

- Tenant-scoped API phải kiểm tra Platform User status, Tenant status, active Membership, Tenant permission và resource ownership.

- Platform-scoped API phải kiểm tra PlatformAdminContext, platform permission, target state và step-up policy; không yêu cầu actor có Membership trong Tenant đích.

- Identity self-service API chỉ tác động tới authenticated Platform User và không yêu cầu TenantContext.

- Mutation có khả năng retry hoặc tạo side effect lớn phải hỗ trợ `Idempotency-Key`.

- Mutation trên entity có version phải nhận `expected_version`; version không khớp trả `409 STATE_CHANGED`.

- Raw token, mã xác nhận và credential phải nằm trong request body, không đặt trong URL và không được ghi log.

- Response lỗi sử dụng stable `code`, `message_key`, `details` và `correlation_id`; không trả stack trace.

- Cross-Tenant resource sử dụng non-enumerating response khi cần tránh tiết lộ sự tồn tại.

- API success chỉ được trả sau khi domain state và outbox/Audit intent đã commit thành công.

### 6.1.2 Tenant-scoped APIs

|Method|Endpoint|Permission / actor|Purpose|
|---|---|---|---|
|GET|`/me/tenants`|Authenticated Platform User|Liệt kê các Tenant có thể truy cập|
|GET|`/me/tenant-context`|Authenticated Platform User|Đọc TenantContext hiện hành|
|POST|`/me/tenant-context`|Authenticated Platform User|Chọn hoặc chuyển TenantContext sau khi kiểm tra lại access|
|GET|`/tenants/{tenant_id}`|`tenant.view`|Đọc hồ sơ tổ chức|
|PATCH|`/tenants/{tenant_id}`|`tenant.profile.update` hoặc Owner policy|Cập nhật các field hồ sơ được allowlist|
|POST|`/tenants/{tenant_id}/legal-profile`|`tenant.legal_profile.update`|Tạo current Legal Profile|
|PATCH|`/tenants/{tenant_id}/legal-profile`|`tenant.legal_profile.update`|Cập nhật current Legal Profile|
|GET|`/tenants/{tenant_id}/readiness`|`tenant.readiness.view`|Tính blocker và warning hiện hành|
|POST|`/tenants/{tenant_id}/activate`|Owner policy|Kích hoạt Tenant khi không còn blocker|
|GET|`/tenants/{tenant_id}/members`|`tenant.member.view`|Liệt kê Membership|
|GET|`/tenants/{tenant_id}/members/{membership_id}`|`tenant.member.view`|Đọc chi tiết Membership|
|POST|`/tenants/{tenant_id}/members/{membership_id}/deactivate`|`tenant.member.status.update`|Tạm ngừng Membership|
|POST|`/tenants/{tenant_id}/members/{membership_id}/reactivate`|`tenant.member.status.update`|Kích hoạt lại Membership|
|POST|`/tenants/{tenant_id}/members/{membership_id}/remove`|`tenant.member.remove`|Loại Membership khỏi Tenant|
|POST|`/tenants/{tenant_id}/leave`|Current Membership|Rời Tenant; chưa có dedicated MVP visual flow|
|PATCH|`/tenants/{tenant_id}/members/{membership_id}/role`|`tenant.role.assign`|Thay role hiện hành của Membership|
|GET|`/tenants/{tenant_id}/invitations`|`tenant.member.view`|Liệt kê Tenant Invitation|
|GET|`/tenants/{tenant_id}/invitations/{invitation_id}`|`tenant.member.view`|Đọc chi tiết Invitation và delivery outcome reference|
|POST|`/tenants/{tenant_id}/invitations`|`tenant.member.invite`|Tạo Tenant Invitation|
|POST|`/tenants/{tenant_id}/invitations/{invitation_id}/resend`|`tenant.member.invite`|Vô hiệu Invitation cũ và tạo Invitation mới|
|POST|`/tenants/{tenant_id}/invitations/{invitation_id}/revoke`|`tenant.member.invite`|Thu hồi pending Invitation|
|POST|`/tenant-invitations/accept`|Verified invitee|Chấp nhận Invitation bằng token trong body|
|POST|`/tenant-invitations/decline`|Invitee|Từ chối Invitation bằng token trong body|
|GET|`/authorization/roles`|`tenant.role.view`|Liệt kê system role có thể sử dụng|
|GET|`/authorization/roles/{role_id}`|`tenant.permission.view`|Đọc permission composition của role|
|GET|`/me/tenants/{tenant_id}/permissions`|Current Membership|Resolve EffectivePermissions cho runtime authorization|

Không cung cấp API xem EffectivePermissions của một thành viên khác trong MVP UI contract. Quyền của thành viên được giải thích thông qua role detail và permission composition.

**Post-MVP Tenant APIs**

|Method|Endpoint|Permission / actor|Purpose|
|---|---|---|---|
|POST|`/tenants/{tenant_id}/transfer-ownership`|Tenant Owner policy|Tenant-facing ownership transfer|
|POST|`/tenants/{tenant_id}/close`|Tenant Owner policy|Đóng Tenant sau blocker evaluation|

### 6.1.3 Platform-scoped APIs

|Method|Endpoint|Platform permission|Purpose|
|---|---|---|---|
|GET|`/platform/users`|`platform.user.view`|Tìm kiếm và liệt kê Platform User|
|POST|`/platform/users`|`platform.user.create`|Tạo pending Platform User; trong MVP chủ yếu được gọi từ onboarding orchestration|
|GET|`/platform/users/{user_id}`|`platform.user.view`|Đọc Platform User detail và identity status|
|POST|`/platform/users/{user_id}/activation-invitations`|`platform.user.activation_invite.send`|Gửi hoặc gửi lại activation invitation|
|POST|`/platform/users/{user_id}/password-reset-requests`|`platform.user.password_reset.initiate`|Khởi tạo password-reset flow; không trả credential|
|POST|`/platform/users/{user_id}/suspend`|`platform.user.suspend`|Tạm ngừng Platform User|
|POST|`/platform/users/{user_id}/restore`|`platform.user.restore`|Khôi phục Platform User theo identity policy|
|GET|`/platform/tenants`|`platform.tenant.view`|Tìm kiếm và liệt kê Tenant|
|POST|`/platform/tenants`|`platform.tenant.create`|Tạo Tenant, Owner Membership và role mặc định|
|GET|`/platform/tenants/{tenant_id}`|`platform.tenant.view`|Đọc chi tiết quản trị Tenant|
|GET|`/platform/tenants/{tenant_id}/members`|`platform.tenant.member.view`|Đọc Membership của Tenant mà không cần TenantContext|
|POST|`/platform/tenants/{tenant_id}/transfer-ownership`|`platform.tenant.owner.transfer`|Chuyển Owner ở cấp nền tảng và giữ nguyên role|
|POST|`/platform/tenants/{tenant_id}/suspend`|`platform.tenant.suspend`|Tạm ngừng Tenant|
|POST|`/platform/tenants/{tenant_id}/restore`|`platform.tenant.restore`|Khôi phục Tenant suspended|
|POST|`/platform/onboarding-operations`|`platform.tenant.create`|Khởi tạo multi-step onboarding|
|GET|`/platform/onboarding-operations/{operation_id}`|`platform.tenant.view`|Đọc trạng thái từng bước và kết quả|
|POST|`/platform/onboarding-operations/{operation_id}/retry`|Quyền ban đầu của operation|Tiếp tục operation bị partial failure|
|GET|`/platform/audit-logs`|`platform.audit.view`|Truy vấn IAM audit (platform scope)|

### 6.1.4 Provisioning orchestration contract

**Flow**

- Resolve Platform User bằng canonical email.

- Tái sử dụng User hiện hữu hoặc tạo User mới ở trạng thái pending activation.

- Gửi activation invitation khi cần.

- Tạo Tenant provisioning, Owner Membership và role mặc định `Chủ cửa hàng` trong cùng transaction của Theme 1.

- Lưu operation status, completed steps và correlation ID.

- Trả `completed` hoặc `partial_failure` kèm retryable step.

**Required behavior**

- Mỗi bước phải idempotent.

- Bước đã hoàn tất không được lặp lại khi retry, trừ khi provider contract hỗ trợ safe replay.

- Không xóa Platform User chỉ vì bước tạo Tenant thất bại.

- Rollback trong Theme 1 phải bao phủ Tenant, Owner Membership, default role assignment và outbox.

- Pending Owner identity không được xem là Tenant activation thành công.

- Mobile UI chỉ cần hiển thị lỗi an toàn và correlation ID; trạng thái kỹ thuật chi tiết phục vụ support.

### 6.1.5 Identity self-service contracts

Các endpoint dưới đây là logical contract do IAM application CQRS (`identity/`) sở hữu; Auth vẫn là credential/session authority. Physical route có thể chuẩn hóa theo convention nền tảng.

|Method|Logical endpoint|Actor|Purpose|
|---|---|---|---|
|GET|`/identity/me`|Authenticated Platform User|Đọc hồ sơ cá nhân hiện hành|
|PATCH|`/identity/me`|Authenticated Platform User|Cập nhật avatar, họ và tên đệm, tên và số điện thoại|
|POST|`/identity/me/password-reset-requests`|Authenticated Platform User|Gửi mã xác nhận tới email đã xác minh|
|POST|`/identity/me/password-reset-requests/{operation_id}/resend`|Authenticated Platform User|Gửi lại mã theo expiry và rate-limit policy|
|POST|`/identity/me/password-reset-requests/{operation_id}/verify`|Authenticated Platform User|Xác minh mã sáu chữ số|
|POST|`/identity/me/password-reset-requests/{operation_id}/complete`|Authenticated Platform User|Thiết lập mật khẩu mới sau khi mã được xác minh|
|POST|`/identity/me/logout`|Authenticated Platform User|Thu hồi phiên hiện hành và đăng xuất|

**Contract rules**

- Email đăng nhập không được cập nhật qua self-service profile form hiện tại.

- IAM lưu self-service profile fields tại `iam.platform_user_profiles`; Auth identity fields chỉ được join/read dưới dạng snapshot an toàn cho presentation, không phải credential authority của IAM.

- Password-reset response không trả password, password hash hoặc credential material.

- Session hiện hành và các session khác tuân theo policy của Supabase Auth; completion chỉ expose `currentSessionRotated`/`otherSessionsRevoked`.

- Profile và credential operation không phụ thuộc TenantContext hoặc Membership.

## 6.2 Event contracts

### 6.2.1 Theme 1 domain events

**Tenant**

- `TenantCreated`

- `TenantProfileUpdated`

- `TenantLegalProfileCreated`

- `TenantLegalProfileUpdated`

- `TenantActivated`

- `TenantOwnershipTransferred`

- `TenantSuspended`

- `TenantRestored`

- `TenantClosed` — Post-MVP

**Membership and Invitation**

- `TenantInvitationCreated`

- `TenantInvitationResent`

- `TenantInvitationAccepted`

- `TenantInvitationDeclined`

- `TenantInvitationRevoked`

- `TenantInvitationExpired`

- `TenantMembershipCreated`

- `TenantMembershipDeactivated`

- `TenantMembershipReactivated`

- `TenantMembershipRemoved`

- `TenantMemberRoleChanged`

**Event rules**

- Trong MVP, `TenantOwnershipTransferred` được phát bởi privileged Platform Admin operation.

- Ownership transfer event phải chứa Owner cũ, Owner mới và xác nhận role không bị thay đổi.

- `TenantClosed` được giữ trong contract registry nhưng không có active MVP producer từ Tenant App.

- Domain state và outbox record phải commit trong cùng transaction.

### 6.2.2 Referenced Platform Identity events

- `PlatformUserProvisioned`

- `PlatformUserActivationInvited`

- `PlatformUserActivated`

- `PlatformUserProfileUpdated`

- `PlatformUserPasswordResetRequested`

- `PlatformUserPasswordResetCompleted`

- `PlatformUserSuspended`

- `PlatformUserRestored`

- `PlatformUserSessionRevoked`

Theme 1 không phát các event này như domain owner; chỉ consume hoặc tham chiếu theo integration contract.

### 6.2.3 Orchestration signals

- `TenantOnboardingStarted`

- `TenantOnboardingStepCompleted`

- `TenantOnboardingCompleted`

- `TenantOnboardingFailed`

Orchestration signal không thay thế domain event và không được Theme nghiệp vụ sử dụng làm source of truth cho Tenant lifecycle.

### 6.2.4 Product analytics events

- `merchant_workspace_created`

- `tenant_member_invited`

- `role_assigned`

- `second_user_logged_in`

- `permissioned_action_completed`

- `restricted_action_blocked`

- `team_activity_reviewed`

- `platform_user_provisioning_completed`

- `tenant_onboarding_failed`

- `tenant_context_switched`

- `platform_user_profile_updated`

- `platform_user_password_reset_completed`

- `platform_user_logged_out`

Product analytics payload không được chứa password, token, mã xác nhận hoặc PII không cần thiết.

### 6.2.5 Event envelope

{

"event_id": "evt_uuid",

"event_type": "TenantCreated",

"aggregate_type": "Tenant",

"aggregate_id": "tenant_uuid",

"tenant_id": "tenant_uuid_or_null",

"actor_type": "platform_user|tenant_member|platform_operator|system",

"actor_user_id": "user_uuid_or_null",

"actor_membership_id": "membership_uuid_or_null",

"correlation_id": "correlation_id",

"occurred_at": "2026-07-12T22:30:00+07:00",

"event_version": 1,

"payload": {}

}

- `actor_membership_id` để null đối với Platform Admin, identity self-service và system process.

- `tenant_id` để null đối với event thuần platform không gắn với Tenant.

- Audit hoặc event payload phải redact token, mã xác nhận, credential và PII không cần thiết.

## 6.3 Permission matrix

### 6.3.1 Tenant permissions

Owner policy là lớp quyền quản trị Theme 1 độc lập với system role. Mapping permission của bốn role Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho được quản lý trong Platform Authorization release manifest, không hard-code trong tài liệu Theme 1.

|Permission|Owner policy|Có thể cấp qua system role|MVP usage|Notes|
|---|---|---|---|---|
|`tenant.view`|Có|Có|Có|Đọc hồ sơ tổ chức|
|`tenant.profile.update`|Có|Có|Có|Cập nhật hồ sơ cơ bản|
|`tenant.legal_profile.update`|Có|Có|Có|Tạo hoặc cập nhật Legal Profile|
|`tenant.readiness.view`|Có|Có|Có|Derived read-only|
|`tenant.activate`|Có|Không mặc định|Có|Kích hoạt Tenant provisioning|
|`tenant.member.view`|Có|Có|Có|Xem thành viên và lời mời|
|`tenant.member.invite`|Có|Có|Có|Tạo, gửi lại và thu hồi Invitation|
|`tenant.member.status.update`|Có|Có|Có|Deactivate hoặc reactivate Membership|
|`tenant.member.remove`|Có|Có|Có|Removed là terminal|
|`tenant.role.view`|Có|Có|Có|Xem system-role catalog|
|`tenant.permission.view`|Có|Có|Có|Xem permission composition của role|
|`tenant.role.assign`|Có|Có|Có|Một role hiện hành trên mỗi Membership|
|`tenant.audit.view`|Có|Có|Có|Truy vấn Tenant Audit|

**Post-MVP Tenant permissions**

|Permission|Purpose|
|---|---|
|`tenant.ownership.transfer`|Tenant Owner tự chuyển quyền sở hữu|
|`tenant.close`|Tenant Owner đóng tổ chức sau blocker evaluation|

**Rules**

- Role `Chủ cửa hàng` không tự động cấp ownership.

- `is_owner = true` không tự động thay đổi `role_id`.

- Business permission ngoài Theme 1 vẫn được lấy từ system role.

- Sole-Owner protection phải được enforce bất kể actor có permission quản trị.

### 6.3.2 Platform permissions

|Permission|System Admin|Platform Operator|Support viewer|Notes|
|---|---|---|---|---|
|`platform.user.view`|Có|Có|Có|Áp dụng PII masking|
|`platform.user.create`|Có|Theo policy|Không|Tạo pending Platform User|
|`platform.user.activation_invite.send`|Có|Có|Không|Không đặt credential|
|`platform.user.password_reset.initiate`|Có|Theo policy|Không|Chỉ khởi tạo identity flow|
|`platform.user.suspend`|Có|Có|Không|Reason và step-up khi policy yêu cầu|
|`platform.user.restore`|Có|Có|Không|Kiểm tra platform blocker|
|`platform.tenant.view`|Có|Có|Có|Không yêu cầu Tenant Membership|
|`platform.tenant.member.view`|Có|Có|Theo policy|Platform-scoped Membership query|
|`platform.tenant.create`|Có|Theo policy|Không|Onboarding operation|
|`platform.tenant.owner.transfer`|Có|Theo policy|Không|Chuyển Owner, không đổi role|
|`platform.tenant.suspend`|Có|Có|Không|Reason và step-up khi policy yêu cầu|
|`platform.tenant.restore`|Có|Có|Không|Không áp dụng cho closed Tenant|
|`platform.audit.view`|Có|Có|Theo policy|Redaction và retention policy|

Tên persona trong bảng là conceptual platform roles. Physical storage và mapping thuộc Platform Authorization, không thuộc `tenant_memberships.role_id`.

### 6.3.3 Identity self-service authorization

|Operation|Authorization rule|TenantContext required|
|---|---|---|
|Xem hồ sơ cá nhân|Authenticated User chỉ đọc chính mình|Không|
|Cập nhật hồ sơ cá nhân|Authenticated User chỉ cập nhật chính mình|Không|
|Gửi hoặc gửi lại mã xác nhận|Authenticated User; verified email; rate-limit policy|Không|
|Xác minh mã|Đúng operation, code còn hạn và chưa vượt attempt limit|Không|
|Đặt mật khẩu mới|Operation đã được xác minh; password đạt policy|Không|
|Đăng xuất|Authenticated session hiện hành|Không|

- Tenant role và ownership không cấp quyền sửa hồ sơ hoặc credential của Platform User khác.

- Platform Admin credential operation phải sử dụng privileged Platform Identity contract riêng.

## 6.4 Error / blocked response catalog

|Code|HTTP|Meaning|UI response|
|---|---|---|---|
|`VALIDATION_ERROR`|400|Payload hoặc field không hợp lệ|Inline validation|
|`AUTHENTICATION_REQUIRED`|401|Chưa đăng nhập|Mở authentication surface|
|`SESSION_EXPIRED`|401|Phiên hết hạn|Xóa dữ liệu nhạy cảm và đăng nhập lại|
|`PERMISSION_DENIED`|403|Thiếu Tenant permission|No-permission state|
|`PLATFORM_PERMISSION_DENIED`|403|Thiếu platform permission|Platform blocked state|
|`STEP_UP_AUTH_REQUIRED`|403|Cần re-authentication hoặc MFA|Mở step-up flow|
|`TENANT_ACCESS_DENIED`|403|Không có Tenant access hợp lệ|Xóa Tenant data và mở selector|
|`INVITATION_EMAIL_MISMATCH`|403|Verified email không khớp email được mời|Yêu cầu đăng nhập đúng email|
|`INVITATION_TOKEN_INVALID`|404|Token lời mời không hợp lệ hoặc không tồn tại|Không lộ account existence|
|`TENANT_NOT_FOUND`|404|Không tồn tại hoặc non-enumerating denial|Generic not-found state|
|`RESOURCE_NOT_FOUND`|404|Resource không tồn tại hoặc không được disclose|Quay về màn an toàn|
|`PLATFORM_USER_NOT_FOUND`|404|Platform User đích không tồn tại|Refresh hoặc tìm lại|
|`CROSS_TENANT_REFERENCE`|404|Resource thuộc Tenant khác|Non-enumerating response|
|`STATE_CHANGED`|409|Version hoặc state đã thay đổi|Tải lại dữ liệu|
|`TENANT_STATE_INVALID`|409|Lifecycle transition không hợp lệ|Hiển thị trạng thái hiện hành|
|`TENANT_SUSPENDED`|409|Tenant bị tạm ngừng|Chặn business operation|
|`TENANT_CLOSED`|409|Tenant đã đóng|Read-only hoặc chuyển Tenant|
|`MEMBERSHIP_INACTIVE`|409|Membership đang inactive|Chuyển Tenant hoặc liên hệ Admin|
|`MEMBERSHIP_REMOVED`|409|Membership đã bị loại|Xóa TenantContext|
|`DUPLICATE_MEMBERSHIP`|409|User đã có current Membership|Mở member/reactivate flow|
|`INVITATION_EXPIRED`|409|Invitation hết hạn|Yêu cầu lời mời mới|
|`INVITATION_REVOKED`|409|Invitation đã bị thu hồi|Đóng flow|
|`INVITATION_ALREADY_USED`|409|Invitation đã ở terminal state|Mở Tenant khi còn access|
|`INVITATION_PENDING_EXISTS`|409|Đã có lời mời pending cùng email|Mở invitation hiện có hoặc revoke|
|`ROLE_NOT_ASSIGNABLE`|409|Role inactive hoặc deprecated|Chọn role khác|
|`LAST_OWNER_PROTECTED`|409|Thao tác ảnh hưởng sole Owner|Yêu cầu Owner hợp lệ khác|
|`OWNER_TARGET_INVALID`|409|Owner mới không phải active Membership cùng Tenant|Chọn lại thành viên|
|`OWNER_IDENTITY_NOT_ACTIVATED`|409|Owner User chưa active hoặc chưa xác minh email|Gửi lại activation hoặc chờ kích hoạt|
|`READINESS_BLOCKED`|409|Tenant vẫn còn blocker|Mở readiness list|
|`PLATFORM_USER_ALREADY_EXISTS`|409|Canonical email đã tồn tại|Chọn Platform User hiện hữu|
|`PLATFORM_USER_NOT_ACTIVATED`|409|Identity đang pending activation|Hiển thị activation state|
|`PLATFORM_USER_SUSPENDED`|409|Identity bị tạm ngừng|Platform blocked state|
|`ACTIVATION_INVITATION_EXPIRED`|409|Activation invitation hết hạn|Cho phép gửi lại|
|`TENANT_PROVISIONING_FAILED`|409|Bước tạo Tenant thất bại|Hiển thị lỗi và retry|
|`PROVISIONING_PARTIAL_FAILURE`|409|Onboarding hoàn tất một phần|Resume operation|
|`IDEMPOTENCY_CONFLICT`|409|Cùng key nhưng payload khác|Dừng retry và kiểm tra operation|
|`IDENTITY_EMAIL_NOT_VERIFIED`|409|Email chưa được xác minh|Yêu cầu xác minh email|
|`RESET_CODE_INVALID`|409|Mã xác nhận không đúng|Hiển thị lỗi tại field|
|`RESET_CODE_EXPIRED`|409|Mã xác nhận hết hạn|Cho phép gửi lại|
|`RESET_CODE_ATTEMPTS_EXCEEDED`|409|Vượt số lần nhập mã|Khóa operation và yêu cầu mã mới|
|`PASSWORD_POLICY_VIOLATION`|422|Mật khẩu mới không đạt policy|Hiển thị yêu cầu mật khẩu|
|`RESET_RATE_LIMITED`|429|Gửi hoặc xác minh quá thường xuyên|Hiển thị thời gian thử lại|
|`SYSTEM_ERROR`|500|Lỗi không mong đợi|Safe retry kèm correlation ID|

**Canonical renames (2026-07-29):** `NO_PERMISSION` → `PERMISSION_DENIED`; `NOT_FOUND` → `RESOURCE_NOT_FOUND`; `INVITATION_ALREADY_ACCEPTED` → `INVITATION_ALREADY_USED`; password-reset `RATE_LIMITED` → `RESET_RATE_LIMITED`; `ATTEMPTS_EXCEEDED` → `RESET_CODE_ATTEMPTS_EXCEEDED`; `IDENTITY_CONFLICT` → `PLATFORM_USER_ALREADY_EXISTS`. Legal Profile duplicate tax code là success warning `DuplicateTaxCodeWarningDto` (`DUPLICATE_TAX_CODE_WARNING`), không phải blocked exception.

Các lỗi liên quan `tenant.close` hoặc tenant-facing ownership transfer chỉ được kích hoạt khi capability Post-MVP được triển khai.

## 6.5 Glossary

|Term|Vietnamese name|Short definition|Related domain|Related entity/model|
|---|---|---|---|---|
|Tenant|Tổ chức|Ranh giới dữ liệu, quyền, cấu hình và giao dịch độc lập|D-01|`tenants`|
|Tenant App|Ứng dụng VET45 dành cho tổ chức|Application surface dùng TenantContext cho Owner và thành viên|D-04|TenantContext|
|Platform Admin App|Ứng dụng quản trị nền tảng|Application surface nội bộ cho privileged VET45 actor|Platform reference|PlatformAdminContext|
|Platform User|Người dùng nền tảng|Danh tính dùng chung trên toàn VET45|Auth + IAM profile|PlatformUser|
|Platform User Profile|Hồ sơ người dùng|Hồ sơ cá nhân do IAM sở hữu (`iam.platform_user_profiles`)|IAM|`iam.platform_user_profiles`|
|My Account|Tài khoản của tôi|Khu vực tự quản lý hồ sơ, mật khẩu và đăng xuất|IAM profile + Auth credential|PlatformUser, PasswordResetOperation|
|Activation Invitation|Lời mời kích hoạt tài khoản|Identity-owned one-time activation flow|Platform Identity|Không phải `tenant_invitations`|
|TenantMembership|Thành viên tổ chức|Quan hệ giữa Platform User và Tenant|D-02|`tenant_memberships`|
|TenantInvitation|Lời mời tham gia tổ chức|Email invitation tạo Membership khi được chấp nhận|D-02|`tenant_invitations`|
|Invitation Delivery Outcome|Kết quả gửi lời mời|Trạng thái gửi email độc lập với Invitation lifecycle|Notification|NotificationDeliveryStatus|
|Owner|Chủ sở hữu|Active Membership có `is_owner = true`|D-01, D-02|`tenant_memberships`|
|Chủ cửa hàng|Vai trò Chủ cửa hàng|Một trong bốn system role MVP; không đồng nhất với Owner|D-03|`role_definitions`|
|Legal Profile|Hồ sơ pháp lý|Current legal identity của Tenant|D-01|`tenant_legal_profiles`|
|System Role|Vai trò hệ thống|Role dùng chung toàn nền tảng và được gán cho Membership|D-03|`role_definitions`|
|Permission|Quyền|Khả năng thực hiện một action|D-03|`permission_definitions`|
|EffectivePermissions|Quyền hiệu lực|Derived set từ role, ownership và policy|D-03, D-04|Derived model|
|TenantContext|Ngữ cảnh tổ chức|Tenant hiện hành trong Tenant App|D-04|Runtime model|
|LastSelectedTenant|Tổ chức được chọn gần nhất|User preference và không phải access grant|D-04 reference|Preference model|
|TenantReadiness|Mức độ sẵn sàng|Derived blocker và warning cho activation|D-01|Derived model|
|PasswordResetOperation|Phiên đặt lại mật khẩu|IAM metadata + Auth OTP/password; không lưu raw code|IAM + Supabase Auth|`iam.password_reset_operations`|
|VET45 System Admin|Quản trị viên hệ thống|Actor tạo Platform User, Tenant và thực hiện onboarding|Platform reference|Platform authorization grant|
|Platform Operator|Nhân sự vận hành nền tảng|Actor thực hiện privileged lifecycle operation|Platform reference|Platform authorization grant|
|PlatformAdminContext|Ngữ cảnh quản trị nền tảng|Context dùng platform permission và không yêu cầu Tenant Membership|D-04 reference|Runtime model|
|PlatformOnboardingOperation|Phiên khởi tạo tổ chức|Orchestration state do IAM persist (OQ-02)|IAM|operationId / idempotencyKey / correlationId|
|Store|Điểm bán|Địa điểm bán hàng, không phải Tenant|External|Store capability|
|Warehouse|Kho|Địa điểm quản lý tồn kho, không phải Tenant|Theme 7|Warehouse entity|
|AA|Activation Action|Product usage signal|Product analytics|—|
|CAA|Core Activation Action|Core real-use signal|Product analytics|—|

## 6.6 Open questions

|ID|Question|Owner|Status|Notes|
|---|---|---|---|---|
|OQ-01|Exact Platform User lifecycle code và self-registration policy ngoài activation invitation là gì?|Platform Identity|Open|Theme 1 chỉ phụ thuộc contract tối thiểu|
|OQ-02|PlatformOnboardingOperation được persistence tại service nào và retention trong bao lâu?|Architecture|**Closed (2026-07-29)**|IAM lưu theo `operationId`, `idempotencyKey`, `correlationId`, `status`, `completedSteps`, `failedStep`; retry tiếp tục từ bước chưa hoàn tất. Không thuộc Tenant aggregate. Retention chi tiết thuộc ops note ngoài MVP contract shape.|
|OQ-03|Những privileged action nào bắt buộc step-up authentication?|Security / Product|**Closed (2026-07-29)**|Privileged provider có thể yêu cầu step-up trên suspend/restore/ownership transfer và credential-adjacent; application surface map `STEP_UP_AUTH_REQUIRED`.|
|OQ-04|Platform permission và Tenant permission dùng chung physical catalog hay bounded storage riêng?|Architecture|Open|Không được gán platform permission qua Membership role|
|OQ-05|Tenant Audit UI được xem những platform-operator action nào và áp dụng redaction ở mức nào?|Security / Product|**Closed (2026-07-29)**|S13/S16 chỉ hiển thị IAM-owned audit events từ `iam.audit_logs`; token, OTP, credential và PII ngoài allowlist bị redact trước persistence.|
|OQ-06|Legal Profile có cần versioning riêng ngoài current state và Audit hay không?|Product / Accounting|Open|Cần phối hợp Theme 8–9|
|OQ-07|Khi LastSelectedTenant không còn hợp lệ nhưng User có nhiều Tenant accessible, hệ thống mở selector hay chọn deterministic fallback?|Product / UX|**Closed (2026-07-29)**|`TenantContextStatus.none`; không auto-select; FE mở selector.|
|OQ-08|Notification cung cấp delivery outcome cho Tenant Invitation qua synchronous query hay event projection?|Architecture / Notification|**Closed (2026-07-29)**|Async projection; create/resend trả initial `queued`; detail/list đọc theo `correlationId`. Invitation lifecycle độc lập delivery outcome.|
|OQ-09|Sau khi đặt lại mật khẩu trong phiên đã xác thực, phiên hiện hành và các phiên khác được giữ hoặc thu hồi theo policy nào?|Security / Platform Identity|**Closed (2026-07-29)**|Complete → `PasswordResetCompletionResultDto(currentSessionRotated: true, otherSessionsRevoked: true)`; thu hồi session khác, session hiện hành rotate và tiếp tục hợp lệ.|
|OQ-10|Avatar được lưu tại Platform Identity hay shared media capability và áp dụng giới hạn file nào?|Architecture / Platform Identity|Open|Theme 1 chỉ giữ asset reference|

### 6.6.1 Ownership boundary (chốt 2026-07-29)

Đồng bộ harness `01` / `02` / `07`:

| Data/capability | Authority | IAM responsibility |
| --- | --- | --- |
| Login email, verified state, credential, recovery OTP, session | Supabase Auth | Read-only snapshot / orchestration |
| Platform User profile fields | IAM, `iam.platform_user_profiles` | Self-service owner |
| IAM audit history | IAM, `iam.audit_logs` | Append immutable, redact before persist, tenant/platform views |
| Email delivery | Notification/Resend | IAM publishes request and reads outcome projection |
| Tenant/Invitation/Membership/Role | IAM | Domain owner |



