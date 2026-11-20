# Theme 1: Tổ chức \& người dùng

# 1\. Overview

## 1\.1 Purpose

Theme 1 thiết lập nền móng tổ chức, người dùng và phân quyền cho toàn bộ Mosaic Retail\. Theme chịu trách nhiệm tạo và quản lý Tenant như ranh giới dữ liệu, quyền truy cập, cấu hình và giao dịch của một đơn vị kinh doanh; quản lý hồ sơ tổ chức, Membership, lời mời tham gia Tenant, system role, permission, ownership, Tenant context và readiness; đồng thời cung cấp actor, Tenant và authorization context cho Theme 2–12\.

Trong tài liệu kỹ thuật và các contract hệ thống, `Tenant` là thuật ngữ domain\. Trên giao diện người dùng, Tenant được hiển thị thống nhất là **Tổ chức**\.

Theme 1 hỗ trợ hai application surface riêng:

1. **Tenant App:** ứng dụng mobile\-first dành cho Owner, người có quyền quản trị và thành viên của tổ chức\. Tenant App hỗ trợ hoàn thiện readiness, kích hoạt tổ chức, quản lý hồ sơ tổ chức, thành viên, lời mời, system role, quyền truy cập, lựa chọn Tenant context, xem lịch sử quản trị và tự quản lý tài khoản cá nhân\.

2. **Platform Admin App:** ứng dụng mobile\-first dành cho Mosaic Retail System Admin và Platform Operator để quản lý Platform User, khởi tạo Tenant, chỉ định Owner đầu tiên, xem tổ chức và thành viên thuộc tổ chức, thay đổi Owner theo platform privilege, tạm ngừng hoặc khôi phục Platform User/Tenant và tra cứu nhật ký quản trị nền tảng\.

Platform Admin App có navigation, permission model và context riêng; không sử dụng TenantContext và không yêu cầu System Admin hoặc Platform Operator có Membership trong Tenant đích\.

Supabase Auth là authority cho login email, email verified state, credential, recovery OTP, authentication protocol và session. Theme 1 / IAM sở hữu Platform User profile fields (`iam.platform_user_profiles`) và IAM audit history (`iam.audit_logs`); đọc Auth qua snapshot/orchestration port. Các chức năng tạo identity credential, đặt lại mật khẩu và đăng xuất điều phối qua contract với Auth / Identity adapters; Theme 1 không lưu raw OTP, password hay session token.

Trong MVP, ownership vẫn là một phần nền tảng của Tenant và được dùng khi khởi tạo Owner đầu tiên, bảo vệ sole Owner và thực hiện privileged ownership transfer từ Platform Admin App\. Tenant\-facing ownership transfer và close Tenant được giữ làm phạm vi Post\-MVP\.

## 1\.2 Business context

Mosaic Retail phục vụ hộ kinh doanh và doanh nghiệp thương mại nhỏ tại Việt Nam, bắt đầu từ bán lẻ offline và có thể mở rộng sang đa điểm, đa kho, đa kênh, bán buôn và B2B\. Theme 1 phải trả lời nhất quán các câu hỏi nền tảng:

- Dữ liệu thuộc đơn vị kinh doanh nào?

- Platform User nào đang thực hiện hành động?

- Actor đang thao tác trong Tenant context hay privileged platform context?

- Platform User có Membership hợp lệ trong Tenant không?

- Membership có role và permission phù hợp không?

- Tenant có đang ở trạng thái cho phép hành động không?

- Resource có thực sự thuộc Tenant hiện hành không?

Tenant không đồng nhất với Store, Warehouse, công ty hay pháp nhân\. Tenant là ranh giới dữ liệu, quyền truy cập, cấu hình và giao dịch của một đơn vị kinh doanh được quản trị độc lập\. Một Tenant có thể đại diện cho hộ kinh doanh, doanh nghiệp hoặc một business unit độc lập; Phase 1 không hỗ trợ nhiều công ty/pháp nhân trong cùng Tenant\.
Trong Phase 1, Tenant user không tự tạo Tenant\. Mosaic Retail System Admin khởi tạo Tenant ở trạng thái `provisioning` và gửi Owner Invitation; Platform User profile và Owner Membership chỉ được tạo khi người nhận chấp nhận lời mời\. Owner sau đó đăng nhập Tenant App, hoàn thiện readiness và activate Tenant\.

## 1\.3 In scope

- Mosaic Retail System Admin tạo Platform User thông qua privileged Platform Identity flow\.

- Gửi lời mời chỉ lưu Invitation và trạng thái gửi. Người được mời bằng email mới chưa trở thành Platform User và chưa có Tenant Membership trước khi accept.

- Quản lý trạng thái Platform User tối thiểu gồm chờ kích hoạt, đang hoạt động và đã tạm ngừng\.

- Gửi lại activation invitation, yêu cầu đặt lại mật khẩu, tạm ngừng và khôi phục Platform User theo platform permission\.

- Mosaic Retail System Admin khởi tạo Tenant và chỉ định Owner đầu tiên\.

- Chọn Auth user hiện hữu hoặc mời email mới làm Owner; không tạo Platform User giả khi gửi lời mời\.

- Gán system role mặc định `Chủ cửa hàng` cho Owner đầu tiên khi khởi tạo Tenant\.

- Quản lý Tenant lifecycle trong phạm vi MVP gồm provisioning, active và suspended\.

- Nhận diện và hiển thị Tenant ở trạng thái closed như một trạng thái kết thúc và chỉ đọc\.

- Quản lý Tenant profile và current Legal Profile\.

- Derived TenantReadiness phục vụ hoàn thiện thiết lập, kích hoạt Tenant và capability gating\.

- Owner hoặc người có quyền phù hợp kích hoạt Tenant khi readiness không còn blocker\.

- Quản lý Membership và Tenant Invitation qua email\.

- Quản lý Membership lifecycle gồm active, inactive và removed\.

- Quản lý một system role hiện hành trên mỗi Membership\.

- Cung cấp bốn system role cố định trong MVP: Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho\.

- Xem danh sách system role và permission composition của từng role theo chế độ read\-only\.

- Thay đổi role hiện hành của Membership theo quyền quản trị Tenant\.

- Gửi lại và thu hồi Tenant Invitation; theo dõi riêng Invitation lifecycle và kết quả gửi email\.

- Quản lý Owner administrative policy độc lập với system role\.

- Platform Admin xem Owner và các Membership của Tenant đích theo platform permission\.

- Platform Admin thay đổi Owner của Tenant đích; role hiện hành của Owner cũ và Owner mới không tự động thay đổi\.

- Resolve TenantContext và EffectivePermissions cho Tenant App\.

- Resolve PlatformAdminContext và platform permission cho Platform Admin App\.

- Chọn và chuyển Tenant context đối với Platform User tham gia nhiều Tenant\.

- Tạm ngừng và khôi phục Tenant thông qua privileged Platform Admin operation\.

- Xem nhật ký quản trị Tenant và nhật ký quản trị nền tảng thông qua IAM audit query contract\.

- Platform User tự xem và cập nhật hồ sơ cá nhân gồm ảnh đại diện, họ và tên đệm, tên và số điện thoại thông qua IAM identity CQRS (`iam.platform_user_profiles`)\.

- Platform User đặt lại mật khẩu bằng mã xác nhận gửi tới email đã xác minh (IAM orchestration; Supabase Auth sở hữu credential/OTP)\.

- Platform User đăng xuất khỏi ứng dụng thông qua IAM `SignOutCommand` (Auth là session authority)\.

- Điều hướng Tenant App theo quyền, trong đó khu vực `Người dùng & vai trò` chỉ hiển thị cho Owner hoặc người có quyền quản trị phù hợp\.

- Cung cấp entry `Tài khoản của tôi` cho mọi Platform User đã đăng nhập\.

- Tích hợp Supabase Auth (external authority), Platform Administration, Platform Authorization, IAM audit, Notification và Platform User Preference\.

- Mobile\-first UI/UX cho cả Tenant App và Platform Admin App\.

## 1\.4 Out of scope

- Theme 1 lưu hoặc quản lý password, mã xác nhận, OTP, MFA secret, credential, access token, refresh token hoặc authentication protocol\.

- Theme 1 sở hữu Auth credential/session store của Supabase Auth, hoặc coi profile self\-service như tenant\-scoped copy thay vì IAM `iam.platform_user_profiles`\.

- Cho System Admin đặt hoặc biết password của Platform User\.

- Cho Platform Admin nhập mật khẩu mới thay người dùng trong luồng đặt lại mật khẩu\.

- Tenant user tự tạo Tenant trong MVP\.

- Tenant Owner tự chuyển quyền sở hữu trong Tenant App trong MVP\.

- Tenant Owner tự đóng Tenant trong Tenant App trong MVP\.

- Tenant\-facing closure blocker review, strong confirmation và close command trong MVP\.

- Khôi phục Tenant đã closed bằng lifecycle flow thông thường\.

- Custom role theo Tenant\.

- Nhiều role đồng thời trên một Membership\.

- User\-specific permission override\.

- Role OWNER; Owner là ownership policy độc lập của Membership\.

- Cho Tenant user sửa role–permission mapping\.

- Permission theo Store, Warehouse hoặc resource scope chi tiết\.

- Tạo Store hoặc Warehouse mặc định khi tạo Tenant\.

- Multi\-company trong một Tenant, Business Group hoặc legal branch trong MVP\.

- Multi\-country, tenant\-configurable timezone hoặc tenant\-configurable base currency trong MVP\.

- Hard delete Tenant, Membership, Invitation, Role hoặc Permission trong lifecycle thông thường\.

- Quản lý HR, payroll hoặc employee profile riêng theo Tenant\.

- Thay đổi email đăng nhập trực tiếp trong form hồ sơ cá nhân; thay đổi email cần identity verification flow riêng và chưa thuộc phạm vi hiện tại\.

- Quản lý MFA, passkey, thiết bị tin cậy hoặc danh sách session chi tiết trong Tenant App\.

- “Đăng nhập thay khách hàng” hoặc impersonation trong Platform Admin App\.

- Bulk provisioning quy mô lớn hoặc import/export Platform User/Tenant\.

- Theme 1 sở hữu AuditLog, activation token, Tenant Invitation raw token, password\-reset code hoặc Notification delivery database\.

- Hiển thị raw token, mã xác nhận, credential hoặc dữ liệu bảo mật nhạy cảm trong UI, application log hoặc Audit payload\.

- Tự động đăng nhập người dùng sau luồng quên mật khẩu từ màn đăng nhập; flow này thuộc Auth / product surface ngoài EP\-06 authenticated reset\.

- Expose EffectivePermissions như một màn tự tra cứu quyền của thành viên thông thường trong Tenant App\.

- Tạo Screen Group độc lập cho mọi no\-permission, context\-invalid hoặc lifecycle\-blocked state; các state này được thể hiện trong Screen Group sở hữu ngữ cảnh\.

- TA\-SG\-07 — Quyền sở hữu \& vòng đời tổ chức trong Tenant App thuộc phạm vi Pending/Post\-MVP\.

## 1\.5 Cross\-theme boundaries



|Capability / Theme|Ownership|Theme 1 responsibility|
|---|---|---|
|Supabase Auth|Login email, verified state, credential, recovery OTP, authentication protocol và provider session|Đọc snapshot an toàn; orchestration password\-reset / sign\-out; không lưu raw OTP, password hay session token|
|IAM Platform User profile (`iam.platform_user_profiles`)|given/family name, phone, avatar reference và self\-service profile fields|Sở hữu profile storage \+ identity CQRS; không mass\-assign email/credential|
|Platform Administration|Admin onboarding operation, privileged application surface và trạng thái orchestration|Tham chiếu onboarding operation; cung cấp Tenant command, platform\-scoped query và privileged ownership\-transfer contract|
|Platform Authorization|Platform admin role/permission và tenant system\-role configuration|Tham chiếu platform privilege; sử dụng tenant role/permission catalog; không cho Tenant chỉnh role–permission mapping|
|IAM Audit (`iam.audit_logs`)|AuditLog, retention, redact, query và actor snapshot|Phát audit intent đáng tin cậy; truy vấn nhật ký quản trị theo platform hoặc Tenant scope; không tạo bảng audit riêng\. Platform Audit bên ngoài chỉ là consumer/policy|
|Notification / Email delivery|Gửi activation invitation, Tenant Invitation, password\-reset code và security notification|Phát delivery request; đọc delivery outcome cần thiết cho UI; không sở hữu delivery database hoặc mã xác nhận|
|Platform User Preference|LastSelectedTenant và preference dùng chung của Platform User|Đọc/ghi preference thông qua contract; luôn validate lại access trước khi sử dụng|
|Theme 2–12|Dữ liệu nghiệp vụ tenant\-scoped|Cung cấp Tenant, actor, Membership, role và permission context; không truy vấn trực tiếp bảng nghiệp vụ của Theme khác|
|Future Tenant closure capability|Tổng hợp blocker từ các Theme nghiệp vụ|Post\-MVP; khi triển khai phải dùng capability contract, không truy vấn trực tiếp bảng Theme khác|
|Store capability|Điểm bán hoặc điểm vận hành|Ngoài Theme 1; Tenant không đồng nhất với Store và không tự tạo Store|
|Theme 7|Warehouse, inventory operation và stock data|Không đồng nhất Warehouse với Tenant; Theme 1 chỉ cung cấp Tenant/actor context|
|Theme 8–9|Chứng từ pháp lý, hóa đơn, kế toán và thuế|Cung cấp current Legal Profile; Theme phát hành chứng từ phải lưu snapshot, không render lại chứng từ lịch sử từ profile hiện hành|

## 1\.6 Users \& roles

|User / actor|Scope|Main needs trong MVP|Authorization source|
|---|---|---|---|
|Mosaic Retail System Admin|Toàn nền tảng|Tạo Platform User, khởi tạo Tenant, chọn Owner đầu tiên, theo dõi onboarding, xem người dùng và tổ chức|Platform permissions|
|Mosaic Retail Platform Operator|Toàn nền tảng|Tạm ngừng/khôi phục Platform User hoặc Tenant, thay đổi Owner theo platform privilege, tra cứu nhật ký quản trị|Platform permissions và step\-up policy khi áp dụng|
|Platform User|Toàn nền tảng|Đăng nhập, kích hoạt tài khoản, tự xem/chỉnh sửa hồ sơ cá nhân, đặt lại mật khẩu, đăng xuất, nhận lời mời và tham gia nhiều Tenant|Supabase Auth (credential/session) \+ IAM identity/ (profile)|
|Tenant Owner|Một Tenant|Hoàn thiện readiness, kích hoạt Tenant, quản lý hồ sơ, thành viên, lời mời, role và lịch sử quản trị trong phạm vi quyền|`is_owner` \+ Membership role|
|Tenant Admin / người có quyền quản trị|Một Tenant|Quản lý hồ sơ, thành viên, lời mời và role theo permission được cấp|Membership role permissions|
|Manager|Một Tenant|Quản lý vận hành theo capability được cấp|Membership role permissions|
|Operational member|Một Tenant|Bán hàng, kho, kế toán hoặc nghiệp vụ khác|Membership role permissions của Theme tương ứng|
|Viewer / Auditor|Một Tenant hoặc platform|Xem dữ liệu và lịch sử trong phạm vi được cấp|Tenant hoặc platform permission|
|System process|Platform / Tenant|Expire Invitation, gửi thông báo, cập nhật delivery outcome, readiness evaluation và access invalidation|System actor policy|

Tên persona trong bảng không bắt buộc trùng system role code cuối cùng\. Owner không phải role; System Admin và Platform Operator không phải Tenant Membership mặc định\.

## 1\.7 Cross references

### 1\.7\.1 Related themes

- Theme 2 — Sản phẩm \& Giá bán\.

- Theme 3 — Đối tác giao dịch\.

- Theme 4 — Chính sách giá và ưu đãi\.

- Theme 5 — Bán hàng \& Đơn hàng\.

- Theme 6 — Công nợ\.

- Theme 7 — Kho \& Giá vốn\.

- Theme 8 — Hóa đơn điện tử\.

- Theme 9 — Ghi sổ kế toán, kê khai thuế\.

- Theme 10 — Dashboard \& báo cáo\.

- Theme 11 — Cảnh báo \& kiểm soát rủi ro\.

- Theme 12 — Tích hợp\.

### 1\.7\.2 Related journeys

- Platform onboarding — System Admin tạo Platform User và Tenant đầu tiên\.

- Hành trình S — Thiết lập vận hành\.

- User Journey 1 — Owner kích hoạt và thiết lập Mosaic Retail lần đầu\.

- User Journey 5 — Owner mời thành viên và kiểm soát vận hành\.

- Mở rộng liên Theme — Thành viên thực hiện nghiệp vụ theo quyền\.

- Mở rộng liên Theme — Owner xem hoạt động do thành viên tạo\.

### 1\.7\.3 Related capability layers

|Capability layer|Theme 1 contribution|
|---|---|
|Platform foundation|Tenant isolation, Platform User reference, Membership và context resolution|
|Platform administration|User provisioning, Tenant onboarding, privileged suspend/restore|
|Access control|Tenant role, permission, Owner policy, platform permission boundary|
|Business operations|Actor context cho Product, Partner, Sales, Receivable và Inventory|
|Compliance|Current Legal Profile, audit dimension và legal snapshot boundary|
|Product analytics|Mapping AA/CAA cho workspace, invitation, role và access denial|

### 1\.7\.4 Related AA/CAA

|Code|CAA|Activation action|Product event|Theme 1 mapping|Coverage|
|---|---|---|---|---|---|
|AA\-S01|No|Tạo không gian kinh doanh sử dụng được|`merchant_workspace_created`|System Admin tạo Tenant; Owner activate và truy cập được|Direct when active and usable|
|AA\-S02|No|Tạo Store hoặc điểm bán|`store_created`|Store tách biệt Tenant|Out of scope|
|AA\-S03|No|Mời người dùng vào đơn vị|`tenant_member_invited`|Tạo Tenant Invitation hợp lệ|Direct|
|AA\-S04|No|Gán vai trò cho thành viên|`role_assigned`|Membership có role hiện hành có hiệu lực|Direct|
|AA\-S05|No|Cấu hình quyền cho vai trò|`permission_configured`|Tenant không edit role\-permission Phase 1|Not covered|
|AA\-S06|Yes|Người dùng thứ hai đăng nhập thành công|`second_user_logged_in`|Accept Invitation chưa đủ; phải đăng nhập Tenant thành công|Partial / cross\-capability|
|AA\-M08|No|Hệ thống chặn action không có quyền|`restricted_action_blocked`|Tenant App hoặc Admin App hiển thị blocked state|Direct|
|AA\-M09|No|Owner xem hoạt động thành viên|`team_activity_reviewed`|Query Platform Audit theo Tenant|Partial|

Quy tắc ghi nhận:

- `TenantCreated` kỹ thuật chưa đủ hoàn thành AA\-S01; Tenant phải `active` và sử dụng được\.

- Platform User activation invitation không phải Tenant Invitation và không hoàn thành AA\-S03\.

- Chấp nhận Tenant Invitation chưa đủ hoàn thành AA\-S06\.

- Gán default role hoàn thành AA\-S04 nhưng không hoàn thành AA\-S05\.

- Domain event, orchestration signal và product analytics event là ba loại khác nhau\.

### 1\.7\.5 Related source documents

- Theme template v2\.

- Product vision\_2026\.07\.12\.

- Mosaic Retail Design System\.

- Mosaic Retail Brand name\.

- Theme 1 — Thiết lập cửa hàng, brainstorm ban đầu\.

- SRS Theme 2 — Sản phẩm \& Giá bán\.

- SRS Theme 3 — Đối tác giao dịch\.

- SRS Theme 4 — Chính sách giá và ưu đãi\.

- SRS Theme 5 — Bán hàng \& Đơn hàng\.

# 2\. Domain foundation

## 2\.1 Domain map

|Domain|Name|Aggregate / authority|Primary responsibilities|External dependencies|
|---|---|---|---|---|
|D\-01|Tenant \& Hồ sơ tổ chức|Tenant|Tenant lifecycle, profile, Legal Profile, ownership, readiness, activation và privileged ownership transfer|Platform Identity, Platform Administration, Platform Audit|
|D\-02|Thành viên \& Lời mời|TenantMembership / TenantInvitation|Membership lifecycle, Invitation lifecycle và trạng thái gửi lời mời|Platform Identity, Notification|
|D\-03|Vai trò \& Quyền|RoleDefinition / PermissionDefinition|System\-role catalog, permission catalog, role assignment và effective permission input|Platform Authorization, business Theme permission registration|
|D\-04|Ngữ cảnh Tenant \& Kiểm soát truy cập|Authorization policy|TenantContext, PlatformAdminContext, access evaluation và cross\-Tenant protection|Platform Identity, Platform User Preference, RLS|

Platform User, credential, session, Platform Admin permission, Notification delivery và AuditLog là platform capabilities được Theme 1 tham chiếu hoặc orchestration; không tạo thêm domain aggregate trong Theme 1\.

## 2\.2 Domain model overview

```Plaintext
Platform Identity
└── PlatformUser
    ├── có thể là Mosaic Retail System Admin / Platform Operator
    └── tham gia nhiều Tenant qua TenantMembership

Platform Admin App
└── PlatformAdminContext
    ├── platform permissions
    ├── onboarding operation
    └── privileged target Tenant/User

Tenant
├── TenantLegalProfile 0..1
├── TenantMembership 1..N
│   ├── role_id
│   ├── is_owner
│   └── status
├── TenantInvitation 0..N
└── TenantReadiness [derived]
```

**Cross\-domain invariants**

- Mọi tenant\-scoped business entity thuộc đúng một Tenant\.

- Một Platform User có thể tham gia hoặc sở hữu nhiều Tenant độc lập\.

- Một Tenant có tối đa một current Legal Profile và tối đa một current Owner Membership\.

- Tenant `active` phải có đúng một active Owner Membership\.

- Owner Membership có đúng một `role_id` như các Membership khác; Owner không phải role\.

- Owner administrative policy chỉ cấp quyền quản trị Theme 1; quyền nghiệp vụ vẫn đến từ role\.

- Một active Membership không đồng nghĩa User có thể truy cập nếu Platform User chưa active hoặc Tenant bị block\.

- TenantContext, LastSelectedTenant và client\-side route không phải bằng chứng cấp quyền\.

- Platform Admin Context không yêu cầu Membership trong Tenant đích nhưng phải có platform permission\.

- Platform User activation invitation và Tenant Invitation là hai lifecycle độc lập\.

- Không hard delete trong lifecycle thông thường; FK dùng `RESTRICT` hoặc `NO ACTION`\.

- Server time là nguồn thời gian cho status transition, expiry và audit metadata\.

- Raw activation token hoặc Tenant Invitation token không được persistence hoặc ghi log\.

**Cross\-domain onboarding orchestration**

```Plaintext
Resolve invitee by canonical email
├── Existing Auth user → Owner Invitation (owner_user_id known; no Membership yet)
└── New email → Owner Invitation only (no Platform User, no Membership)

Create Tenant provisioning
→ persist Owner Invitation (is_owner) + delivery queued
→ persist onboarding result / retry state
→ invitee accepts (verified Auth) → upsert profile + Owner Membership
→ Owner opens Tenant App
→ readiness passes
→ activate Tenant
```

- Gửi lời mời không tạo `iam.platform_user_profiles` hay `iam.memberships`\.

- Accept Invitation hợp lệ bằng Auth identity đã xác minh email sẽ upsert Platform User profile thật và tạo active Tenant Membership trong cùng transaction tiêu thụ Invitation\.

- Cross\-capability orchestration dùng correlation ID, idempotency, retry và explicit partial\-failure state\.

**Concurrency and idempotency**

- Mutation có `version` phải nhận `expected_version`; mismatch trả `409 STATE_CHANGED`\.

- Create, activate, resend, transfer, close, suspend và restore phải hỗ trợ idempotency key\.

- Retry thành công không tăng version, không tạo duplicate event và không tạo duplicate Audit\.

- Generic PATCH chỉ cho phép field allowlist; không được sửa lifecycle, ownership, role hoặc token field\.

**Event reliability**

- Domain state và outbox record phải commit cùng transaction\.

- Event envelope tối thiểu gồm `event_id`, `event_type`, `aggregate_type`, `aggregate_id`, `tenant_id` khi có, `actor_type`, `actor_user_id`, `correlation_id`, `occurred_at`, `event_version` và `payload`\.

- Audit intent phải transactionally reliable; không gọi best\-effort sau commit\.

**Error semantics**

- `400`: payload/validation không hợp lệ\.

- `401`: chưa xác thực hoặc session hết hạn\.

- `403`: actor đã xác thực nhưng thiếu permission rõ ràng\.

- `404`: không tồn tại hoặc dùng non\-enumerating response cho cross\-Tenant resource\.

- `409`: lifecycle, concurrency hoặc business precondition conflict\.

- `422`: payload hợp lệ về cú pháp nhưng không thể xử lý theo rule cụ thể, khi API convention cần phân biệt\.

## 2\.3 Domains

### 2\.3\.1 Tenant \& Hồ sơ tổ chức

**Purpose**

Sở hữu Tenant lifecycle, Tenant profile, current Legal Profile, ownership, activation và derived readiness\. Trong MVP, Platform Admin được thay đổi Owner; Tenant\-facing ownership transfer và close Tenant là Post\-MVP\.

**Business rules**

- Chỉ System Admin có `platform.tenant.create` mới được khởi tạo Tenant\.

- System Admin có thể chọn Platform User hiện hữu hoặc tạo User mới qua privileged IAM / Auth onboarding flow\.

- Tenant được tạo ở trạng thái `provisioning`\.

- Tạo Tenant, Owner Membership và role mặc định phải atomic khi accept; khi gửi chỉ atomic Tenant \+ Invitation\.

- Owner đầu tiên được gán role mặc định `Chủ cửa hàng`\.

- Owner User có thể đang chờ kích hoạt, nhưng Tenant chỉ được activate khi User active và email đã xác minh\.

- Tenant profile được lưu trực tiếp trên `tenants`\.

- Khi onboarding, chỉ tên tổ chức là bắt buộc; thông tin liên hệ có thể bổ sung trước khi activate\.

- Legal Profile là current state 0\.\.1 và không mặc định là activation blocker\.

- Tax code trùng chỉ tạo warning và không tiết lộ Tenant khác\.

- Chứng từ lịch sử phải dùng Legal Profile snapshot\.

- Platform Admin được xem Owner và Membership của Tenant theo platform permission\.

- Platform Admin được thay đổi Owner của Tenant active hoặc suspended\.

- Owner mới phải là active Membership cùng Tenant\.

- Thay đổi Owner không làm thay đổi role của Owner cũ hoặc Owner mới\.

- Sole Owner không được deactivate, remove hoặc leave\.

- Suspend/restore Tenant chỉ được thực hiện qua Platform Admin\.

- Tenant\-facing ownership transfer và close Tenant là Post\-MVP\.

- `closed` là trạng thái kết thúc, chỉ đọc và không restore bằng flow thông thường\.

**Invariants**

- Tenant active hoặc suspended có đúng một active Owner Membership\.

- `is_owner = true` chỉ hợp lệ với active Membership\.

- `is_owner` và `role_id` là hai thuộc tính độc lập\.

- Generic profile update không được sửa lifecycle, ownership hoặc role\.

- `closed` là terminal state\.

**Lifecycle / state model**

provisioning → active ↔ suspended

closed

\- Terminal state\.

\- Không có Tenant App command trong MVP\.

\- Không restore bằng flow thông thường\.

TenantReadiness là derived read model:

overall\_status

blocking\_issues\[\]

warnings\[\]

evaluated\_at

Activation blockers tối thiểu:

- Tenant profile cơ bản hợp lệ\.

- Có đúng một active Owner Membership\.

- Owner có active system role\.

- Owner Platform User active và email đã xác minh\.

- Không có platform blocker\.

**Commands \& permissions**

|Command|Actor / permission|Main preconditions|Result|Scope|
|---|---|---|---|---|
|CreateTenant|`platform.tenant.create`|Role Chủ cửa hàng active|Tenant provisioning \+ Owner Invitation|MVP|
|UpdateTenantProfile|Owner policy hoặc `tenant.profile.update`|Tenant mutable; version hợp lệ|Update allowlisted fields|MVP|
|CreateTenantLegalProfile|`tenant.legal_profile.update`|Chưa có profile; dữ liệu hợp lệ|Tạo Legal Profile|MVP|
|UpdateTenantLegalProfile|`tenant.legal_profile.update`|Profile tồn tại; version hợp lệ|Cập nhật Legal Profile|MVP|
|ActivateTenant|Owner policy|Readiness không có blocker|provisioning → active|MVP|
|TransferTenantOwnershipByPlatform|`platform.tenant.owner.transfer`|Target active Membership; Tenant không closed|Chuyển Owner, giữ nguyên role|MVP|
|SuspendTenant|`platform.tenant.suspend`|Tenant active|active → suspended|MVP|
|RestoreTenant|`platform.tenant.restore`|Tenant suspended; invariant hợp lệ|suspended → active|MVP|
|TransferTenantOwnership|Tenant Owner|Target active Membership|Chuyển Owner|Post\-MVP|
|CloseTenant|Tenant Owner / platform privilege|Không có blocker|Tenant closed|Post\-MVP|

**Events**

MVP:

- `TenantCreated`

- `TenantProfileUpdated`

- `TenantLegalProfileCreated`

- `TenantLegalProfileUpdated`

- `TenantActivated`

- `TenantOwnershipTransferred`

- `TenantSuspended`

- `TenantRestored`

Post\-MVP:

1. `TenantClosed`

**API references**

Platform\-scoped MVP APIs:

- `POST /platform/tenants`

- `GET /platform/tenants/{tenant_id}`

- `POST /platform/tenants/{tenant_id}/transfer-ownership`

- `POST /platform/tenants/{tenant_id}/suspend`

- `POST /platform/tenants/{tenant_id}/restore`

Tenant\-scoped MVP APIs:

- `GET /tenants/{tenant_id}`

- `PATCH /tenants/{tenant_id}`

- `POST /tenants/{tenant_id}/legal-profile`

- `PATCH /tenants/{tenant_id}/legal-profile`

- `GET /tenants/{tenant_id}/readiness`

- `POST /tenants/{tenant_id}/activate`

Post\-MVP APIs:

- `POST /tenants/{tenant_id}/transfer-ownership`

- `POST /tenants/{tenant_id}/close`

**Related entities**

- `tenants`

- `tenant_legal_profiles`

- `tenant_memberships`

- `tenant_invitations`

- `PlatformUser` — referenced

- `TenantReadiness` — derived

- `AuditLog` — referenced

### 2\.3\.2 Thành viên \& Lời mời

**Purpose**

Sở hữu Membership lifecycle và Tenant Invitation lifecycle, gồm mời thành viên, chấp nhận, từ chối, gửi lại, thu hồi, tạm ngừng, kích hoạt lại, loại khỏi tổ chức và rời tổ chức\.

**Business rules**

- Tenant Invitation sử dụng email và độc lập với Platform User activation invitation\.

- `initial_role_id` là bắt buộc, không thay đổi sau khi tạo và phải tham chiếu system role đang active\.

- Invitation có thời hạn 7 ngày theo server time\.

- Không lưu raw token; chỉ lưu `token_hash` duy nhất\.

- Gửi lại lời mời phải vô hiệu lời mời cũ và tạo lời mời mới với token và thời hạn mới\.

- Không tạo Invitation khi người dùng đã có active Membership\.

- Inactive Membership phải sử dụng flow kích hoạt lại, không gửi Invitation mới\.

- Removed Membership có thể được mời lại và tạo Membership mới khi chấp nhận\.

- Chấp nhận Invitation yêu cầu Platform User đã đăng nhập, email đã xác minh và khớp canonical email được mời\.

- Chấp nhận Invitation và tạo Membership phải atomic trong Theme 1 boundary\.

- Tenant suspended chặn thao tác chấp nhận nhưng không tự động thu hồi Invitation\.

- Removed Membership là trạng thái kết thúc và không được kích hoạt lại\.

- Membership history và dữ liệu nghiệp vụ đã phát sinh phải được giữ lại\.

- Invitation lifecycle và trạng thái gửi email là hai trạng thái độc lập\.

- Email gửi lỗi không tự động chuyển Invitation sang revoked hoặc expired\.

- Chỉ Invitation đang pending mới được gửi lại hoặc thu hồi\.

- Platform Admin có platform permission phù hợp được đọc Membership của Tenant đích mà không cần TenantContext\.

**Invariants**

- Một Platform User có tối đa một Membership hiện hành, gồm active hoặc inactive, trong cùng Tenant\.

- Một Tenant có tối đa một pending Invitation cho cùng canonical email\.

- Accepted Invitation phải tham chiếu đúng một Membership cùng Tenant\.

- Invitation ở trạng thái terminal không được quay lại pending\.

- Owner protection phải được kiểm tra trước khi deactivate, remove hoặc leave\.

**Lifecycle / state model**

- Membership: `active ↔ inactive`\.

- Membership: `active → removed`\.

- Membership: `inactive → removed`\.

- Invitation: `pending → accepted`\.

- Invitation: `pending → declined`\.

- Invitation: `pending → revoked`\.

- Invitation: `pending → expired`\.

**Commands \& permissions**

|Command|Actor / permission|Main preconditions|Result|
|---|---|---|---|
|CreateTenantInvitation|`tenant.member.invite`|Không có current Membership; role active|Tạo pending Invitation|
|ResendTenantInvitation|`tenant.member.invite`|Invitation pending; role active|Vô hiệu Invitation cũ và tạo Invitation mới|
|RevokeTenantInvitation|`tenant.member.invite`|Invitation pending|`pending → revoked`|
|ExpireTenantInvitation|System process|Server time ≥ `expires_at`|`pending → expired`|
|AcceptTenantInvitation|Verified invitee|Token hợp lệ; Tenant accessible; chưa có current Membership|Tạo active Membership và chuyển Invitation sang accepted|
|DeclineTenantInvitation|Invitee|Token hợp lệ; Invitation pending|`pending → declined`|
|DeactivateMembership|`tenant.member.status.update`|Target active; không phải sole Owner|`active → inactive`|
|ReactivateMembership|`tenant.member.status.update`|Target inactive; role còn sử dụng được|`inactive → active`|
|RemoveMembership|`tenant.member.remove`|Target current; không phải sole Owner|`active/inactive → removed`|
|LeaveTenant|Current Membership|Không phải sole Owner|Membership hiện tại → removed|

**Events**

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

**API references**

- `GET /tenants/{tenant_id}/members`

- `POST /tenants/{tenant_id}/invitations`

- `GET /tenants/{tenant_id}/invitations`

- `GET /tenants/{tenant_id}/invitations/{invitation_id}`

- `POST /tenants/{tenant_id}/invitations/{invitation_id}/resend`

- `POST /tenants/{tenant_id}/invitations/{invitation_id}/revoke`

- `POST /tenant-invitations/accept`

- `POST /tenant-invitations/decline`

- `POST /tenants/{tenant_id}/members/{membership_id}/deactivate`

- `POST /tenants/{tenant_id}/members/{membership_id}/reactivate`

- `POST /tenants/{tenant_id}/members/{membership_id}/remove`

- `POST /tenants/{tenant_id}/leave`

- `GET /platform/tenants/{tenant_id}/members`

**Related entities**

- `tenant_memberships`

- `tenant_invitations`

- `role_definitions`

- `PlatformUser` — referenced

- `NotificationDeliveryStatus` — referenced

- `AuditLog` — referenced

### 2\.3\.3 Vai trò \& Quyền

**Purpose**

Sở hữu system\-role catalog, permission catalog, role–permission mapping và việc thay đổi role hiện hành của Membership\. Platform privilege không thuộc Tenant role\.

**Business rules**

- Role và Permission catalog dùng chung toàn hệ thống, không có `tenant_id`\.

- Tenant không được tạo custom role hoặc chỉnh role–permission mapping trong MVP\.

- System\-role catalog MVP gồm:

    - Chủ cửa hàng

    - Nhân viên bán hàng

    - Kế toán

    - Thủ kho

- `Chủ cửa hàng` là role vận hành và không đồng nhất với Owner\.

- Owner vẫn có đúng một role hiện hành như các Membership khác\.

- Owner đầu tiên được gán mặc định role `Chủ cửa hàng`\.

- Thay đổi role không làm thay đổi ownership\.

- Thay đổi Owner không làm thay đổi role\.

- Role code và Permission code là immutable\.

- Role và Permission không hard delete; lifecycle là `active → deprecated`\.

- Deprecated role không được gán mới hoặc sử dụng cho Invitation mới\.

- Membership đang tham chiếu deprecated role giữ nguyên reference cho tới khi được chuyển role\.

- Deprecated Permission bị loại khỏi EffectivePermissions khi policy có hiệu lực\.

- Tenant App chỉ cho xem role catalog và permission composition ở chế độ read\-only\.

- Flow thay đổi role được khởi tạo từ chi tiết thành viên\.

- Thành viên thông thường không có màn tự tra cứu EffectivePermissions\.

- Permission hiển thị trên UI phải được nhóm theo capability nghiệp vụ và không hiển thị internal platform permission\.

**Invariants**

- Membership active hoặc inactive luôn có `role_id` hợp lệ\.

- Không tồn tại role code `OWNER`\.

- `role_id` và `is_owner` là hai thuộc tính độc lập\.

- Role picker chỉ hiển thị active assignable role\.

- Target Membership của tenant\-facing role change phải thuộc đúng TenantContext hiện hành\.

- EffectivePermissions là derived và không persisted\.

- Bốn system role MVP phải tồn tại trong release configuration trước khi tạo Tenant\.

**Lifecycle / state model**

- RoleDefinition: `active → deprecated`\.

- PermissionDefinition: `active → deprecated`\.

- RolePermission biểu diễn current mapping\.

**Commands \& permissions**

|Command|Actor / permission|Main preconditions|Result|
|---|---|---|---|
|ChangeMemberRole|`tenant.role.assign`|Target là current Membership; role mới active; version hợp lệ|Cập nhật `role_id` và invalidate permission context|
|DeprecateRole|Privileged Authorization process|Impact đã được review|Role không còn assignable|
|DeprecatePermission|Privileged Authorization process|Consumer impact đã được review|Permission bị loại khỏi effective set|
|UpdateRolePermissions|Release/migration process|Không tenant\-facing|Cập nhật global role–permission mapping|

**Events**

- `TenantMemberRoleChanged`

- `RoleDefinitionDeprecated`

- `PermissionDefinitionDeprecated`

- `RolePermissionMappingChanged`

**API references**

- `GET /authorization/roles`

- `GET /authorization/roles/{role_id}`

- `PATCH /tenants/{tenant_id}/members/{membership_id}/role`

- `GET /me/tenants/{tenant_id}/permissions`

**Related entities**

- `role_definitions`

- `permission_definitions`

- `role_permissions`

- `tenant_memberships`

- `tenant_invitations`

- `EffectivePermissions` — derived

- Platform Authorization grants — referenced

### 2\.3\.4 Ngữ cảnh Tenant \& Kiểm soát truy cập

**Purpose**

Resolve TenantContext cho Tenant App, PlatformAdminContext cho Platform Admin App và enforce authorization theo đúng application boundary\.

**Business rules**

- Mỗi tenant\-facing request chỉ có một TenantContext\.

- LastSelectedTenant là preference và phải được kiểm tra lại trước khi sử dụng\.

- Tenant access yêu cầu Platform User active, Tenant status phù hợp và active Membership\.

- Setup access của Tenant provisioning khác business access của Tenant active\.

- Tenant suspended hoặc closed chặn business operation theo policy\.

- UI visibility không thay thế server\-side authorization\.

- Resource thuộc Tenant khác phải dùng non\-enumerating response khi cần tránh disclosure\.

- RLS là lớp bảo vệ bổ sung và không thay thế application authorization\.

- Membership status change, role change, ownership transfer và Tenant status change phải invalidate access từ request tiếp theo\.

- Platform Admin App sử dụng PlatformAdminContext và không cần Membership của actor trong Tenant đích\.

- Platform Admin đọc Membership hoặc thay Owner bằng platform permission\.

- Step\-up authentication được áp dụng khi Platform Security policy yêu cầu\.

- Entry `Người dùng & vai trò` chỉ hiển thị cho Owner hoặc người có permission quản trị phù hợp\.

- Entry `Tài khoản của tôi` hiển thị cho mọi authenticated Platform User\.

- Xem hoặc chỉnh sửa hồ sơ cá nhân, đặt lại mật khẩu và đăng xuất là identity\-scoped operation, không yêu cầu TenantContext\.

- Email đăng nhập và identity status không được cập nhật qua Tenant profile API\.

- Shared no\-permission, context\-invalid và lifecycle\-blocked state được hiển thị trong Screen Group sở hữu ngữ cảnh\.

**Invariants**

- TenantContext chỉ được thiết lập khi Platform User có access hợp lệ\.

- Cross\-Tenant resource không được trả metadata xác nhận sự tồn tại khi actor không có quyền\.

- Client không thể tự nâng quyền bằng `tenant_id`, role name hoặc cached permission\.

- Platform operation phải ghi đúng actor type trong Audit và event\.

- PlatformAdminContext và TenantContext không được sử dụng thay thế cho nhau\.

- Identity self\-service operation không được phụ thuộc vào Membership của Tenant hiện hành\.

**Lifecycle / state model**

- Tenant App: `authenticated → no_context → valid_tenant_context`\.

- TenantContext có thể chuyển sang `invalidated` khi Membership, role, ownership hoặc Tenant lifecycle thay đổi\.

- Khi context không còn hợp lệ, người dùng phải chọn lại hoặc chuyển sang Tenant khác\.

- Platform Admin App: `authenticated → platform_privilege_resolved → privileged_action`\.

- Platform action có thể chuyển sang `step_up_required` khi security policy yêu cầu\.

**Commands \& permissions**

|Command / policy|Actor|Main checks|Result|
|---|---|---|---|
|SelectTenantContext|Authenticated Platform User|Identity active; Tenant accessible; active Membership|Thiết lập runtime TenantContext|
|SwitchTenantContext|Authenticated Platform User|Tenant đích accessible|Tải lại dữ liệu và quyền theo Tenant mới|
|ResolveEffectivePermissions|System|Tenant, Membership, role và Owner policy|Trả derived permission set|
|AuthorizeTenantAction|System|Context, lifecycle, permission và resource Tenant|Allow hoặc deny|
|ResolvePlatformAdminContext|Platform User|Platform privilege và session policy|Thiết lập privileged context|
|AuthorizePlatformAction|System|Platform permission, target state, step\-up và Audit|Allow hoặc deny|
|InvalidateAccessContext|System|Membership, role, ownership hoặc Tenant status thay đổi|Xóa hoặc yêu cầu refresh context|

**Events / signals**

- Tenant context switch và access denial là runtime hoặc product analytics signal\.

- Membership, role, ownership và Tenant lifecycle change phát domain event tại domain sở hữu\.

- Identity self\-service profile event do IAM sở hữu; credential/session event thuộc Auth\.

- Platform privileged action phải được ghi vào IAM `iam.audit_logs` (Platform Audit chỉ consume/policy)\.

**API references**

- `GET /me/tenants`

- `GET /me/tenants/{tenant_id}/access`

- `GET /me/tenants/{tenant_id}/permissions`

- `POST /me/tenant-context`

- `GET /platform/admin-context`

- Platform authorization API hoặc policy contract cho từng privileged action\.

**Related models**

- `TenantContext` — runtime

- `PlatformAdminContext` — runtime

- `EffectivePermissions` — derived

- `LastSelectedTenant` — referenced preference

- `TenantMembership`

- `RoleDefinition`

- `PermissionDefinition`

- `PlatformUser` — referenced

# 3\. Data \& entities

## 3\.1 Relationship model

Theme 1 sử dụng Tenant làm ranh giới dữ liệu, quyền truy cập và cấu hình vận hành\. Platform User gồm Auth\-owned identity (login/credential/session) và IAM\-owned profile (`iam.platform_user_profiles`); một User có thể tham gia nhiều Tenant qua các Membership độc lập\. Mosaic Retail System Admin có thể tạo Platform User và Tenant qua Platform Admin App nhưng không trở thành Membership hoặc Owner mặc định\.

```Plaintext
PlatformUser [Referenced] 1 --- N TenantMembership N --- 1 Tenant
Tenant 1 --- 0..1 TenantLegalProfile
Tenant 1 --- N TenantInvitation
RoleDefinition 1 --- N TenantMembership
RoleDefinition 1 --- N TenantInvitation
RoleDefinition 1 --- N RolePermission
PermissionDefinition 1 --- N RolePermission
TenantMembership 1 --- N TenantInvitation : sends
TenantInvitation 0..1 --- 0..1 TenantMembership : creates_on_acceptance
PlatformOnboardingOperation [Referenced] N --- 0..1 PlatformUser
PlatformOnboardingOperation [Referenced] N --- 0..1 Tenant
```

Các nguyên tắc mô hình:

- Business Profile và core settings lưu trực tiếp trong `tenants`; không tạo `tenant_business_profiles` hoặc `tenant_settings`\.

- Ownership biểu diễn bằng `tenant_memberships.is_owner`; không tạo `tenant_ownerships` và không có role `OWNER`\.

- Mỗi Membership có đúng một system role hiện hành qua `role_id`; không tạo `membership_role_assignments` Phase 1\.

- `created_by_user_id` của Tenant có thể là Mosaic Retail System Admin và không bắt buộc là Owner hoặc Membership trong Tenant\.

- Tenant Membership chỉ tham chiếu Platform User thật (Auth user); Invitation pending không phải Membership\.

- Platform User activation invitation không lưu trong `tenant_invitations`\.

- Platform onboarding partial failure/retry thuộc Platform Administration, không phải Tenant aggregate\.

- `TenantReadiness`, `EffectivePermissions`, `TenantContext`, `PlatformAdminContext` và `LastSelectedTenant` không phải persisted entities Theme 1\.

- Audit dùng canonical `iam.audit_logs`; không tạo `tenant_action_logs`\.

## 3\.2 Entity relationship diagram

### 3\.2\.1 Conceptual ERD

```mermaid
erDiagram
    PLATFORM_USER ||--o{ TENANT_MEMBERSHIP : participates
    TENANT ||--o{ TENANT_MEMBERSHIP : contains
    TENANT ||--o| TENANT_LEGAL_PROFILE : has
    TENANT ||--o{ TENANT_INVITATION : issues
    ROLE_DEFINITION ||--o{ TENANT_MEMBERSHIP : assigned_to
    ROLE_DEFINITION ||--o{ TENANT_INVITATION : proposed_for
    ROLE_DEFINITION ||--o{ ROLE_PERMISSION : grants
    PERMISSION_DEFINITION ||--o{ ROLE_PERMISSION : included_in
    TENANT_MEMBERSHIP ||--o{ TENANT_INVITATION : sends
    TENANT_INVITATION o|--o| TENANT_MEMBERSHIP : creates
    PLATFORM_ONBOARDING_OPERATION }o--o| PLATFORM_USER : provisions_owner
    PLATFORM_ONBOARDING_OPERATION }o--o| TENANT : provisions
    TENANT ||--o{ AUDIT_LOG : scopes
    PLATFORM_USER ||--o{ AUDIT_LOG : acts```

`PLATFORM_USER` (Auth credential + IAM profile), `PLATFORM_ONBOARDING_OPERATION` (Platform Administration orchestration) và nhật ký quản trị IAM (`iam.audit_logs`) là referenced models theo ownership matrix §APPENDICES\. Module Platform Audit bên ngoài chỉ consume/policy, không sở hữu bảng nguồn\.

### 3\.2\.2 Physical ERD — Phase 1

```mermaid
erDiagram
    TENANTS ||--o| TENANT_LEGAL_PROFILES : has
    TENANTS ||--o{ TENANT_MEMBERSHIPS : contains
    TENANTS ||--o{ TENANT_INVITATIONS : issues
    ROLE_DEFINITIONS ||--o{ TENANT_MEMBERSHIPS : assigned_to
    ROLE_DEFINITIONS ||--o{ TENANT_INVITATIONS : proposed_for
    ROLE_DEFINITIONS ||--o{ ROLE_PERMISSIONS : grants
    PERMISSION_DEFINITIONS ||--o{ ROLE_PERMISSIONS : included_in
    TENANT_MEMBERSHIPS ||--o{ TENANT_INVITATIONS : sends
    TENANT_INVITATIONS o|--o| TENANT_MEMBERSHIPS : creates```

Physical ERD chỉ thể hiện persisted tables Theme 1 và tenant Authorization configuration\. Logical reference tới Platform User hoặc onboarding operation không phụ thuộc tên bảng vật lý của capability sở hữu\.

## 3\.3 Entity catalog

### 3\.3\.1 Persisted and system configuration

|Category|Logical entity|Physical storage|Ownership|Purpose|Notes|
|---|---|---|---|---|---|
|Persisted|Tenant|`tenants`|Theme 1|Tenant boundary, lifecycle và hồ sơ tổ chức|Không đồng nhất với Store hoặc Warehouse; `closed` là terminal state|
|Persisted|TenantLegalProfile|`tenant_legal_profiles`|Theme 1|Hồ sơ pháp lý hiện hành|Quan hệ 0\.\.1 với Tenant|
|Persisted|TenantMembership|`tenant_memberships`|Theme 1|Quan hệ User–Tenant, role và ownership|Một role hiện hành; `is_owner` độc lập với role|
|Persisted|TenantInvitation|`tenant_invitations`|Theme 1|Lời mời tham gia Tenant qua email|Token một lần; Invitation lifecycle độc lập với email delivery|
|System configuration|RoleDefinition|`role_definitions`|Platform Authorization|Global system\-role catalog|MVP có bốn role: Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho|
|System configuration|PermissionDefinition|`permission_definitions`|Platform Authorization|Global permission catalog|Permission code immutable|
|System configuration|RolePermission|`role_permissions`|Platform Authorization|Current role–permission mapping|Không có `tenant_id`; Tenant không chỉnh sửa mapping|

### 3\.3\.2 Referenced, derived and runtime models

|Category|Model|Ownership / persistence|Purpose|Notes|
|---|---|---|---|---|
|Referenced|PlatformUser|Auth (login/credential/session) + IAM profile (`iam.platform_user_profiles`)|Định danh Auth + hồ sơ cá nhân self-service|Một User có thể tham gia nhiều Tenant; Auth authority cho credential; IAM owner profile fields|
|Referenced|AuditLog|IAM (`iam.audit_logs`)|Nhật ký quản trị IAM (tenant + platform views)|Redact trước persist; không phải shared Audit module đa BC|
|Referenced|PlatformOnboardingOperation|IAM|Theo dõi onboarding, retry và partial failure|Không thuộc Tenant aggregate; OQ-02 closed|
|Referenced|NotificationDeliveryStatus|Notification|Hiển thị kết quả gửi activation invitation và Tenant Invitation|Không đồng nhất với Invitation lifecycle; OQ-08 async projection|
|Referenced|PasswordResetOperation|IAM metadata + Auth OTP/password|Gửi mã, xác minh mã và đặt mật khẩu mới|Theme 1 không lưu mã xác nhận hoặc mật khẩu; OQ-09 session rotate|
|Derived|TenantReadiness|Không persisted|Tổng hợp mức sẵn sàng của Tenant|Tính từ trạng thái hiện hành|
|Derived|EffectivePermissions|Không persisted|Kết quả đánh giá quyền của Membership|Tính từ role, permission và Owner policy|
|Runtime|TenantContext|Request/session|Tenant đang được thao tác trong Tenant App|Không phải bằng chứng cấp quyền|
|Runtime|PlatformAdminContext|Platform Admin session|Privileged platform authorization context|Không yêu cầu Tenant Membership|
|Preference|LastSelectedTenant|Platform User Preference|Ghi nhớ Tenant gần nhất|Phải validate lại access trước khi sử dụng|

Danh mục tỉnh/thành và xã/phường là backend reference catalog read\-only, không phải entity và không xuất hiện trong Physical ERD Phase 1\.

## 3\.4 Entity fields

### 3\.4\.1 `tenants`

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|`id`|`uuid`|Có|PK, immutable|Tenant identifier|
|`display_name`|`text`|Có|Không unique|Tên hiển thị của đơn vị kinh doanh|
|`status`|`text`|Có|CHECK: `provisioning`, `active`, `suspended`, `closed`|Lifecycle hiện hành|
|`contact_email`|`text`|Không|Server clean và validate|Email liên hệ; không dùng để đăng nhập hoặc định danh Owner|
|`contact_phone`|`text`|Không|Server clean và validate|Số liên hệ, lưu theo canonical format thống nhất|
|`logo_storage_path`|`text`|Không|Server\-managed|Object path/key; không lưu signed URL|
|`contact_address_text`|`text`|Không|—|Địa chỉ liên hệ đầy đủ|
|`province_code`|`text`|Không|Backend catalog validation|Mã tỉnh/thành phố|
|`commune_code`|`text`|Không|Backend catalog validation|Mã xã/phường; phải thuộc `province_code`|
|`business_timezone`|`text`|Có|CHECK = `Asia/Ho_Chi_Minh`; server\-managed|Timezone nghiệp vụ, read\-only trong Phase 1|
|`base_currency_code`|`text`|Có|CHECK = `VND`; server\-managed|Đồng tiền cơ sở, read\-only trong Phase 1|
|`created_by_user_id`|`uuid`|Có|Logical FK → PlatformUser, immutable|Mosaic Retail System Admin/Platform User thực hiện privileged provisioning|
|`status_changed_at`|`timestamptz`|Có|Server\-managed|Lần thay đổi trạng thái gần nhất|
|`version`|`integer`|Có|Default `1`, tăng dần|Optimistic concurrency counter|
|`created_at`|`timestamptz`|Có|Server\-managed, immutable|Thời điểm tạo|
|`updated_at`|`timestamptz`|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes:**

- Khi tạo Tenant, server gán `business_timezone = Asia/Ho_Chi_Minh` và `base_currency_code = VND`; client không được truyền đè\.

- `province_code` và `commune_code` không có foreign key vật lý; application service validate theo cùng một backend reference catalog\.

- Có `commune_code` thì bắt buộc có `province_code`\.

- Khi đổi `province_code`, `commune_code` hiện tại phải được xóa hoặc validate lại\.

- `created_by_user_id` không suy ra ownership và không yêu cầu User có Membership trong Tenant\.

- Tenant chỉ được activate khi có một active Owner Membership, Owner role active và Owner Platform User active/verified\.

### 3\.4\.2 `tenant_legal_profiles`

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|`tenant_id`|`uuid`|Có|PK/FK → `tenants.id`, immutable|Một current Legal Profile trên mỗi Tenant|
|`legal_entity_type`|`text`|Có|CHECK: `HOUSEHOLD_BUSINESS`, `ENTERPRISE`|Loại chủ thể pháp lý Phase 1|
|`legal_name`|`text`|Có|—|Tên pháp lý|
|`tax_code`|`text`|Có|Non\-unique index|Mã số thuế/định danh thuế đã clean và validate|
|`registered_address_text`|`text`|Không|—|Địa chỉ đăng ký đầy đủ|
|`province_code`|`text`|Không|Backend catalog validation|Mã tỉnh/thành phố của địa chỉ đăng ký|
|`commune_code`|`text`|Không|Backend catalog validation|Mã xã/phường; phải thuộc `province_code`|
|`version`|`integer`|Có|Default `1`, tăng dần|Optimistic concurrency counter|
|`created_at`|`timestamptz`|Có|Server\-managed, immutable|Thời điểm tạo|
|`updated_at`|`timestamptz`|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes:**

- Không tạo row Legal Profile rỗng hoặc draft\. Row chỉ được tạo khi `legal_entity_type`, `legal_name` và `tax_code` hợp lệ\.

- Validation `tax_code` phụ thuộc `legal_entity_type`: `ENTERPRISE` dùng 10 chữ số; `HOUSEHOLD_BUSINESS` dùng 12 chữ số\.

- `tax_code` lưu dưới dạng `text`, được trim và clean trước khi lưu; không có `tax_code_normalized`\.

- Future branch/dependent\-unit support có thể dùng format `1234567890-123` mà không cần đổi kiểu dữ liệu\.

- `tax_code` không global unique\. Hệ thống dùng index và duplicate warning; không tự động liên kết hoặc kế thừa dữ liệu giữa các Tenant trùng mã\.

- Current Legal Profile không được dùng để render lại chứng từ lịch sử; Theme 8 và Theme 9 phải snapshot dữ liệu pháp lý cần thiết\.

### 3\.4\.3 tenant\_memberships

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|id|uuid|Có|PK, immutable|Membership identifier|
|tenant\_id|uuid|Có|FK → `tenants.id`, immutable|Tenant của Membership|
|user\_id|uuid|Có|Logical FK → PlatformUser, immutable|Platform User tham gia Tenant|
|role\_id|uuid|Có|FK → `role_definitions.id`|System role hiện hành|
|is\_owner|boolean|Có|Default false|Ownership flag; không phải role|
|status|text|Có|CHECK: active, inactive, removed|Membership lifecycle|
|status\_changed\_at|timestamptz|Có|Server\-managed|Lần thay đổi trạng thái gần nhất|
|removed\_at|timestamptz|Không|Chỉ có khi `status = removed`|Thời điểm bị loại khỏi Tenant|
|version|integer|Có|Default 1, tăng dần|Optimistic concurrency counter|
|created\_at|timestamptz|Có|Server\-managed, immutable|Thời điểm Membership bắt đầu|
|updated\_at|timestamptz|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes**

- `created_at` đồng thời là thời điểm tham gia; không cần `joined_at`\.

- Một User có tối đa một Membership hiện hành, gồm active hoặc inactive, trong cùng Tenant\.

- Mỗi Tenant có tối đa một Membership có `is_owner = true`\.

- `is_owner = true` chỉ hợp lệ khi Membership active\.

- `is_owner` và `role_id` là hai thuộc tính độc lập\.

- Role `Chủ cửa hàng` không suy ra Membership là Owner\.

- Owner có thể giữ bất kỳ system role active nào\.

- Owner đầu tiên được gán mặc định role `Chủ cửa hàng`\.

- Platform ownership transfer phải cập nhật Owner cũ và Owner mới trong cùng transaction\.

- Platform ownership transfer không thay đổi `role_id` của Owner cũ hoặc Owner mới\.

- Tenant\-facing ownership transfer là Post\-MVP\.

- Sole Owner không được deactivate, remove hoặc leave\.

- Membership active có thể tồn tại khi Platform User chưa kích hoạt; effective access vẫn yêu cầu identity active và email đã xác minh\.

- Removed Membership không được reactivate; người dùng quay lại phải tạo Membership mới\.

- Có unique key bổ sung `(id, tenant_id)` để hỗ trợ composite foreign key từ Invitation\.

### 3\.4\.4 tenant\_invitations

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|id|uuid|Có|PK, immutable|Invitation identifier|
|tenant\_id|uuid|Có|FK → `tenants.id`, immutable|Tenant phát hành Invitation|
|invitee\_email|text|Có|Immutable sau khi tạo|Canonical email được mời|
|initial\_role\_id|uuid|Có|FK → `role_definitions.id`, immutable|Role được gán khi chấp nhận|
|status|text|Có|CHECK: pending, accepted, declined, revoked, expired|Invitation lifecycle|
|token\_hash|text|Có|Globally unique, server\-managed|Hash của token một lần|
|invited\_by\_membership\_id|uuid|Có|Composite FK cùng `tenant_id`|Membership gửi lời mời|
|accepted\_membership\_id|uuid|Không|Unique khi có giá trị; composite FK cùng `tenant_id`|Membership được tạo khi chấp nhận|
|expires\_at|timestamptz|Có|Lớn hơn `created_at`|Thời điểm hết hạn|
|status\_changed\_at|timestamptz|Có|Server\-managed|Lần thay đổi trạng thái gần nhất|
|version|integer|Có|Default 1, tăng dần|Optimistic concurrency counter|
|created\_at|timestamptz|Có|Server\-managed, immutable|Thời điểm tạo|
|updated\_at|timestamptz|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes**

- Invitation mới có thời hạn 7 ngày theo server time\.

- Một Tenant có tối đa một pending Invitation cho cùng canonical email\.

- Không lưu raw token; raw token không được ghi vào log hoặc Audit payload\.

- `status = accepted` khi và chỉ khi có `accepted_membership_id`\.

- `accepted_membership_id` chỉ được ghi một lần\.

- Gửi lại lời mời phải vô hiệu Invitation cũ và tạo Invitation mới với token và thời hạn mới\.

- Không gửi Invitation nếu User đã có active Membership\.

- User có inactive Membership phải dùng flow reactivate\.

- User chỉ có removed Membership có thể được mời lại và tạo Membership mới\.

- Accept phải kiểm tra lại token, verified email, Membership conflict, Tenant status và role status trong cùng transaction\.

- `status` chỉ phản ánh Invitation lifecycle, không phản ánh kết quả gửi email\.

- Không bổ sung `email_sent` hoặc `delivery_failed` vào Invitation status\.

- Email delivery outcome được đọc từ Notification bằng `tenant_invitation` và `invitation_id` làm source reference\.

- Delivery failure không tự động revoke hoặc expire Invitation\.

### 3\.4\.5 role\_definitions

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|id|uuid|Có|PK, immutable|Role identifier|
|code|text|Có|Globally unique, immutable|System role code; không có `OWNER`|
|name|text|Có|—|Tên hiển thị của role|
|description|text|Không|—|Mô tả nghiệp vụ|
|status|text|Có|CHECK: active, deprecated|Role lifecycle|
|deprecated\_at|timestamptz|Không|Có khi `status = deprecated`|Thời điểm ngừng gán mới|
|created\_at|timestamptz|Có|Server\-managed, immutable|Thời điểm tạo|
|updated\_at|timestamptz|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes**

- Role catalog dùng chung toàn hệ thống và không có `tenant_id`\.

- MVP phải seed đúng bốn role hiển thị:

    - Chủ cửa hàng

    - Nhân viên bán hàng

    - Kế toán

    - Thủ kho

- Role code cụ thể do Platform Authorization release manifest quản lý và không được thay đổi sau khi phát hành\.

- Không tồn tại role `OWNER`; ownership được lưu tại `tenant_memberships.is_owner`\.

- Role `Chủ cửa hàng` không đồng nhất với Owner\.

- Tenant không được tạo custom role hoặc thay đổi role definition trong MVP\.

- Deprecated role không được gán mới hoặc sử dụng cho Invitation mới\.

- Membership đang tham chiếu deprecated role giữ nguyên reference cho tới khi được chuyển role có kiểm soát\.

- Không hard delete RoleDefinition\.

### 3\.4\.6 `permission_definitions`

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|`id`|`uuid`|Có|PK, immutable|Permission identifier|
|`code`|`text`|Có|Globally unique, immutable|Permission code|
|`name`|`text`|Có|—|Tên hiển thị|
|`description`|`text`|Không|—|Mô tả permission|
|`capability_code`|`text`|Không|—|Nhóm capability phục vụ tổ chức UI/catalog|
|`status`|`text`|Có|CHECK: `active`, `deprecated`|Permission lifecycle|
|`deprecated_at`|`timestamptz`|Không|Có khi `status = deprecated`|Thời điểm ngừng sử dụng mới|
|`created_at`|`timestamptz`|Có|Server\-managed, immutable|Thời điểm tạo|
|`updated_at`|`timestamptz`|Có|Server\-managed|Lần cập nhật gần nhất|

**Structural notes:**

- Permission catalog dùng chung toàn hệ thống và không có `tenant_id`\.

- Mỗi business Theme đăng ký permission code thuộc capability của mình\.

- Permission đã được sử dụng không bị hard delete\.

- Không cần lưu đồng thời `module_code` và `action_code` nếu thông tin đã được thể hiện trong `code`\.

### 3\.4\.7 `role_permissions`

|Field|Type|Required|Key/Constraint|Description|
|---|---|---|---|---|
|`role_id`|`uuid`|Có|PK/FK → `role_definitions.id`|Thành phần composite PK|
|`permission_id`|`uuid`|Có|PK/FK → `permission_definitions.id`|Thành phần composite PK|
|`created_at`|`timestamptz`|Có|Server\-managed, immutable|Thời điểm tạo mapping|

**Structural notes:**

- Composite primary key: `(role_id, permission_id)`\.

- Đây là current\-state mapping; lịch sử thay đổi thuộc Platform Audit/release history\.

- Thay đổi mapping có hiệu lực với mọi Tenant sử dụng role tương ứng\.

- Tenant User không được insert, update hoặc delete trực tiếp bảng này\.

### 3\.4\.8 PlatformUser reference contract

PlatformUser là composite reference: Auth sở hữu login/credential/session; IAM sở hữu profile fields tại `iam.platform_user_profiles`\.

|Field / attribute|Required for Theme 1|Purpose|
|---|---|---|
|user\_id|Có|Logical identifier của Platform User|
|login\_email|Có|Email đăng nhập và canonical identity lookup (Auth)|
|email\_verified|Có|Kiểm tra activation, invitation acceptance và readiness (Auth snapshot)|
|identity\_status|Có|Phân biệt pending activation, active và suspended|
|family\_middle\_name|Không|Họ và tên đệm trong hồ sơ cá nhân (IAM)|
|given\_name|Không|Tên trong hồ sơ cá nhân (IAM)|
|display\_name|Có|Tên hiển thị tổng hợp từ IAM profile fields|
|phone\_number|Không|Số điện thoại cá nhân (IAM)|
|avatar\_url|Không|Ảnh đại diện hoặc asset reference (IAM)|
|last\_login\_at|Không|Thời điểm đăng nhập gần nhất (Auth snapshot)|
|activation\_expires\_at|Không|Thời hạn kích hoạt đối với pending User|
|suspended\_at|Không|Thời điểm User bị tạm ngừng|
|suspension\_reason|Không|Lý do tạm ngừng được phép hiển thị|
|created\_at|Có|Thời điểm tạo Platform User|
|updated\_at|Có|Lần cập nhật hồ sơ hoặc trạng thái gần nhất|

**Contract rules**

- `user_id` và `login_email` không được cập nhật qua Tenant profile API\.

- Email đăng nhập là read\-only trong màn Tài khoản của tôi\.

- Platform User được tự cập nhật `family_middle_name`, `given_name`, `phone_number` và avatar qua IAM identity CQRS (`iam.platform_user_profiles`)\.

- Avatar upload/storage có thể thuộc shared media capability; IAM chỉ giữ opaque reference\.

- Platform Admin chỉ được đọc các field cần thiết theo platform permission\.

- Theme 1 không lưu bản sao hồ sơ Platform User trong tenant\-scoped table; canonical profile nằm ở IAM\.

- Password, password hash, activation token, password\-reset code, session token và MFA secret không thuộc contract này (Auth)\.

- Membership và ownership summary được Theme 1 query riêng; không phải thuộc tính của PlatformUser\.

- Identity status change phải làm access context được kiểm tra lại từ request tiếp theo\.

### 3\.4\.9 PlatformOnboardingOperation reference contract

|Field|Type|Required|Source|Purpose|
|---|---|---|---|---|
|`operation_id`|`uuid`|Có|Platform Administration|Onboarding operation identifier|
|`owner_user_id`|`uuid`|Không|Platform Administration|Platform User dự kiến làm Owner|
|`tenant_id`|`uuid`|Không|Platform Administration|Tenant đã tạo nếu có|
|`status`|`text`|Có|Platform Administration|`in_progress`, `partial_failure`, `completed`, `cancelled`|
|`current_step`|`text`|Có|Platform Administration|Bước orchestration hiện hành|
|`failure_code`|`text`|Không|Platform Administration|Stable error cho retry/support|
|`correlation_id`|`text`|Có|Platform Administration|Trace xuyên capability|
|`created_by_user_id`|`uuid`|Có|Platform Administration|System Admin actor|
|`created_at`|`timestamptz`|Có|Platform Administration|Thời điểm bắt đầu|
|`updated_at`|`timestamptz`|Có|Platform Administration|Lần thay đổi gần nhất|

Operation này không phải aggregate của Theme 1\. Nó tham chiếu kết quả Platform Identity và Theme 1 để support resume/retry, không cấp quyền Tenant\.

## 3\.5 Structural constraints

### 3\.5\.1 Keys and indexes

|Table|Constraint/Index|Purpose|
|---|---|---|
|`tenant_memberships`|Partial UNIQUE `(tenant_id, user_id)` WHERE `status IN ('active','inactive')`|Một Membership hiện hành trên mỗi User–Tenant|
|`tenant_memberships`|Partial UNIQUE `(tenant_id)` WHERE `is_owner = true`|Tối đa một Owner trên mỗi Tenant|
|`tenant_memberships`|UNIQUE `(id, tenant_id)`|Composite FK consistency|
|`tenant_memberships`|INDEX `(user_id, status)`|Liệt kê Tenant User có thể truy cập|
|`tenant_memberships`|INDEX `(tenant_id, status)`|Liệt kê thành viên của Tenant|
|`tenant_invitations`|UNIQUE `token_hash`|Không tái sử dụng token|
|`tenant_invitations`|Partial UNIQUE `(tenant_id, invitee_email)` WHERE `status = 'pending'`|Ngăn pending Invitation trùng|
|`tenant_invitations`|UNIQUE `accepted_membership_id` WHERE NOT NULL|Một Membership được tạo từ tối đa một Invitation|
|`tenant_invitations`|INDEX `(tenant_id, status, expires_at)`|Quản lý Invitation và expiry|
|`tenant_legal_profiles`|INDEX `tax_code`|Tra cứu và duplicate warning|
|`role_definitions`|UNIQUE `code`|Global role identity|
|`permission_definitions`|UNIQUE `code`|Global permission identity|

### 3\.5\.2 Cross\-entity consistency

- Tạo Tenant phải tạo Tenant, Owner Invitation (`is_owner`) và outbox record trong cùng transaction của Theme 1; Owner Membership chỉ khi accept\.

- Tenant active hoặc suspended phải có đúng một active Owner Membership\.

- Platform ownership transfer phải lock Owner hiện tại và Membership nhận ownership, sau đó cập nhật `is_owner` atomic\.

- Platform ownership transfer không được thay đổi `role_id` của Owner cũ hoặc Owner mới\.

- Tenant\-facing ownership transfer là Post\-MVP\.

- Sole Owner không được deactivate, remove hoặc leave\.

- Accept Invitation phải cập nhật Invitation và tạo Membership trong cùng transaction\.

- Invitation chỉ được accepted một lần và không được tạo Membership trùng\.

- Invitation lifecycle không được thay đổi theo Notification delivery outcome\.

- Change role chỉ cập nhật `role_id`; không thay đổi `is_owner` hoặc Membership status\.

- Membership được chuyển sang removed không được dùng lại; Invitation mới phải tạo Membership mới\.

- Platform Admin member query đọc từ `tenant_memberships`; không sao chép Membership sang platform table\.

- Platform User profile update đi IAM (`iam.platform_user_profiles`); Auth credential/session lifecycle không nằm trong transaction Tenant domain — đồng bộ qua IAM identity CQRS / Auth adapters hoặc event\.

- Trạng thái `closed` tiếp tục được bảo toàn trong dữ liệu, nhưng Tenant close command và blocker aggregation là Post\-MVP\.

- Domain mutation và outbox/Audit intent phải commit cùng transaction\.

### 3\.5\.3 Server\-managed and immutable data

- Server quản lý `created_at`, `updated_at`, `status_changed_at`, `removed_at`, `deprecated_at`, `version`, `token_hash`, `business_timezone` và `base_currency_code`\.

- `tenant_id`, `user_id`, `created_by_user_id`, Role code và Permission code là immutable sau khi tạo\.

- `version` là optimistic concurrency counter, không phải historical version number\.

- Khi tạo record có lifecycle, `created_at`, `updated_at` và `status_changed_at` dùng cùng transaction timestamp\.

- Contact email, contact phone, invitation email và tax code phải được clean/validate trước khi persistence; không tạo các field `*_normalized`\.

### 3\.5\.4 Authorization, RLS and audit

- Tenant\-scoped read/write phải kiểm tra Platform User active, Tenant status, active Membership, permission và resource Tenant ownership; không chỉ tin TenantContext\.

- Platform\-scoped read/write phải kiểm tra PlatformAdminContext, platform permission, target state và step\-up policy khi áp dụng\.

- Platform Admin không cần Membership và không được tạo Membership giả trong Tenant đích\.

- `GET /platform/tenants/{tenant_id}/members` yêu cầu platform permission đọc tổ chức và thành viên\.

- Platform ownership transfer yêu cầu `platform.tenant.owner.transfer`, kiểm tra target Membership và ghi privileged Audit\.

- Owner authorization được tính từ `is_owner` và Owner administrative policy; business permission được tính từ `role_id` và `role_permissions`\.

- Role/Permission configuration chỉ được thay đổi qua release manifest, migration hoặc privileged Platform Authorization process\.

- Self\-service profile operation chỉ được thực hiện cho chính authenticated Platform User, trừ privileged identity administration contract được định nghĩa riêng\.

- Password\-reset code, password và session lifecycle do Supabase Auth authorize; IAM chỉ orchestration và ghi metadata/audit an toàn\.

- Thay đổi Membership, role, ownership, Tenant status hoặc identity status phải invalidate cached access context\.

- RLS là lớp bảo vệ bổ sung và không thay application authorization\.

- Mọi hành động quản trị, thay role, thay Owner, suspend/restore và profile security operation phải có Audit phù hợp với capability sở hữu\.

- Audit phải được phát theo cơ chế transactionally reliable; không dùng best\-effort call sau commit\.

- Raw token, mã xác nhận, password, session token và secret không được ghi vào database log, API log hoặc Audit payload\.

- IAM audit query (`iam.audit_logs`) phải áp dụng redaction và không trả dữ liệu vượt permission của actor; Platform Audit bên ngoài chỉ consume\.

## 3\.6 Data classification \& protection

|Data class|Fields / models|Protection requirements|
|---|---|---|
|Personally identifiable information|`contact_email`, `contact_phone`, `invitee_email`, `login_email`, `family_middle_name`, `given_name`, `phone_number`, avatar|Tenant/platform\-scoped access; mask khi cần; hạn chế log và export|
|Legal information|`legal_name`, `tax_code`, `registered_address_text`|Permission cập nhật riêng; không tiết lộ dữ liệu Tenant khác|
|Security\-sensitive data|`token_hash`, Membership status, `is_owner`, role/permission mapping, identity status|Privileged mutation; không expose token hash; Audit bắt buộc|
|Credential and verification data|Password, password hash, activation token, password\-reset code, MFA secret, session token|Không persistence trong Theme 1; không hiển thị hoặc ghi log|
|Identity activity metadata|`last_login_at`, `activation_expires_at`, `suspended_at`, `suspension_reason`|Chỉ hiển thị theo platform permission hoặc cho chính User khi phù hợp|
|Operational metadata|Status, timestamps, version, correlation ID, Audit reference|Server\-managed; client không ghi trực tiếp|

**Protection rules**

- Theme 1 không lưu password, password\-reset code, raw activation token hoặc raw Invitation token\.

- Email và số điện thoại phải được mask tại các màn hình hoặc log không cần hiển thị đầy đủ\.

- Avatar được xem là dữ liệu cá nhân và phải tuân theo quyền truy cập của Platform User profile\.

- Duplicate tax\-code warning không được tiết lộ tên hoặc thông tin của Tenant khác\.

- Invitation conflict không được tiết lộ Membership hoặc Platform User ngoài phạm vi quyền\.

- Audit payload phải redact token, mã xác nhận, credential và dữ liệu cá nhân không cần thiết\.

- Retention, masking, export và quyền đọc chi tiết tuân theo Platform Security và Data Retention policy\.

# 4\. Epics

## 4\.1 Epic map

|Epic|Name|Purpose|Related domains|Related entities/models|Notes|
|---|---|---|---|---|---|
|EP\-01|Quản lý người dùng nền tảng, khởi tạo \& kích hoạt tổ chức|Quản lý Platform User; khởi tạo Tenant và Owner đầu tiên; hoàn thiện readiness và kích hoạt tổ chức|D\-01, D\-03, D\-04|PlatformUser, PlatformOnboardingOperation, tenants, tenant\_memberships, TenantReadiness|Gồm Platform Admin App và Tenant App|
|EP\-02|Quản lý tổ chức \& lịch sử quản trị|Quản lý hồ sơ, Legal Profile, trạng thái Tenant, ownership cấp nền tảng và lịch sử quản trị|D\-01, D\-04|tenants, tenant\_legal\_profiles, tenant\_memberships, AuditLog|Tenant\-facing transfer/close là Post\-MVP|
|EP\-03|Thành viên \& lời mời|Quản lý Tenant Invitation và Membership lifecycle|D\-02, D\-03|tenant\_memberships, tenant\_invitations, role\_definitions|Activation invitation không thuộc Epic này|
|EP\-04|Vai trò \& quyền truy cập|Xem system role, permission composition và thay role hiện hành của Membership|D\-03, D\-04|role\_definitions, permission\_definitions, role\_permissions, EffectivePermissions|Owner không phải role|
|EP\-05|Chọn tổ chức \& kiểm soát Tenant context|Xem, chọn và chuyển Tenant; xử lý context không còn hợp lệ|D\-04|TenantContext, LastSelectedTenant, tenants, tenant\_memberships|Không có TA\-SG\-08 độc lập|
|EP\-06|Tài khoản của tôi|Cho Platform User tự xem, cập nhật hồ sơ, đặt lại mật khẩu và đăng xuất|D\-04, IAM identity/|PlatformUser, PasswordResetOperation, PlatformAdminContext, TenantContext|IAM CQRS orchestration; profile → `iam.platform_user_profiles`; credential/session → Supabase Auth|

##

## 4\.2 EP\-01 — Quản lý người dùng nền tảng, khởi tạo \& kích hoạt tổ chức

### 4\.2\.1 Overview

Epic này cho phép Platform Admin quản lý Platform User, khởi tạo Tenant và Owner đầu tiên; sau đó Owner hoàn thiện readiness và kích hoạt tổ chức trong Tenant App\.

### 4\.2\.2 Business context

Tenant user không tự tạo Tenant trong MVP\. Mosaic Retail chủ động provision Platform User và Tenant, kiểm soát Owner đầu tiên, role mặc định và trạng thái provisioning\. Platform User = Auth\-owned credential/session \+ IAM\-owned profile; Tenant, Membership và readiness thuộc Theme 1\.

### 4\.2\.3 In scope

- Xem, tìm kiếm và lọc Platform User\.

- Xem chi tiết Platform User và các Tenant Membership liên quan\.

- Gửi lại activation invitation cho User đang chờ kích hoạt\.

- Khởi tạo password\-reset flow cho Platform User\.

- Tạm ngừng và khôi phục Platform User theo platform permission\.

- Chọn Platform User hiện hữu hoặc tạo User mới trong onboarding\.

- Khởi tạo Tenant ở trạng thái provisioning\.

- Gửi Owner Invitation với role mặc định `Chủ cửa hàng`; Membership chỉ sau accept\.

- Hiển thị blocker và warning của TenantReadiness\.

- Kích hoạt Tenant khi không còn blocker\.

- Ghi Audit và hỗ trợ idempotency, retry cho các thao tác quản trị\.

### 4\.2\.4 Out of scope

- Platform Admin đặt hoặc xem mật khẩu của Platform User\.

- Tạo Platform User độc lập ngoài onboarding nếu chưa có design/entry point được phê duyệt\.

- Tenant user tự tạo Tenant\.

- Chọn role khác cho Owner đầu tiên trong onboarding\.

- Tự động activate Tenant ngay sau khi khởi tạo\.

- Hiển thị màn kỹ thuật chi tiết cho partial failure trong mobile UI\.

### 4\.2\.5 Entry points

- Platform Admin App → `Người dùng`\.

- Platform Admin App → `Tổ chức` → `Thêm tổ chức`\.

- Platform Admin App → Chi tiết tổ chức → mở chi tiết Platform User\.

- Tenant App → `Thêm` → `Người dùng & vai trò` → readiness khi Tenant đang provisioning\.

- Tenant App → blocker yêu cầu bổ sung hồ sơ tổ chức\.

### 4\.2\.6 User stories

#### 4\.2\.6\.1 User story map

|User story|As user|I want to|So that|Related screen group|
|---|---|---|---|---|
|US\-01|Platform Admin|xem và tra cứu Platform User|kiểm soát người dùng cấp nền tảng|PA\-SG\-01|
|US\-02|Platform Admin|quản lý lifecycle của Platform User|xử lý activation, password reset và access risk|PA\-SG\-01|
|US\-03|Mosaic Retail System Admin|khởi tạo Tenant và Owner đầu tiên|khách hàng có workspace độc lập để thiết lập|PA\-SG\-02|
|US\-04|Tenant Owner|xem readiness của tổ chức|biết điều kiện cần hoàn thiện|TA\-SG\-01|
|US\-05|Tenant Owner|kích hoạt tổ chức khi đủ điều kiện|bắt đầu sử dụng nghiệp vụ|TA\-SG\-01|

#### 4\.2\.6\.2 US\-01 — Xem và tra cứu Platform User

**Business context**

Platform Admin cần tra cứu Platform User theo email, tên và trạng thái, đồng thời xem identity status và các Membership liên quan\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Platform Admin có quyền xem người dùng|xem danh sách và chi tiết Platform User|tôi có thể hỗ trợ và quản trị người dùng đúng đối tượng|

**Functional requirements**

- Hiển thị danh sách Platform User và hỗ trợ tìm kiếm theo tên hoặc email\.

- Hỗ trợ lọc theo trạng thái pending activation, active và suspended\.

- Chi tiết User hiển thị identity status, email verification, ngày tạo và lần đăng nhập gần nhất khi có\.

- Hiển thị các Tenant Membership cùng role và ownership độc lập\.

- Mở chi tiết User từ chi tiết Tenant phải giữ đúng navigation stack\.

**Business rules**

- Platform Admin phải có platform permission đọc Platform User\.

- Role `Chủ cửa hàng` không được dùng để suy ra User là Owner\.

- Dữ liệu identity gồm Auth snapshot (email/verified/status) và IAM profile fields\.

- Danh sách Membership do Theme 1 cung cấp theo platform\-scoped query\.

**Acceptance criteria**

- Kết quả tìm kiếm chỉ chứa Platform User phù hợp điều kiện\.

- Chi tiết User hiển thị chính xác identity status và Membership\.

- Platform Admin không có quyền nhận `403`\.

- Back từ User detail trở về đúng màn nguồn\.

**Scenarios**

**Scenario SC\-01 — Tra cứu Platform User**

- Given Platform Admin có quyền xem người dùng

- When Platform Admin tìm theo email

- Then hệ thống trả về Platform User phù hợp và trạng thái hiện hành

**Scenario SC\-02 — Mở User từ chi tiết Tenant**

- Given Platform Admin đang xem thành viên của một Tenant

- When Platform Admin chọn một thành viên

- Then hệ thống mở Platform User detail và Back trở về Tenant detail

**References**

- Domains: D\-02, D\-04

- APIs: IAM / Auth User query (platform profile \+ Auth snapshot); platform\-scoped Membership query

- UI/UX: PA\-SG\-01, PA\-SG\-03

#### 4\.2\.6\.3 US\-02 — Quản lý lifecycle của Platform User

**Business context**

Platform Admin cần xử lý các trạng thái chờ kích hoạt, đang hoạt động hoặc bị tạm ngừng mà không được tiếp cận credential của người dùng\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Platform Admin có quyền phù hợp|gửi lại kích hoạt, yêu cầu đặt lại mật khẩu, tạm ngừng hoặc khôi phục User|tôi có thể xử lý access và hỗ trợ tài khoản an toàn|

**Functional requirements**

- PA-D-01 loại người chỉ có Invitation và bỏ filter “Chờ kích hoạt”; PA-D-03 hiển thị email ngay dưới tên; bỏ các thao tác người dùng pending của PA-O-02\.

- User active có action yêu cầu đặt lại mật khẩu và tạm ngừng\.

- User suspended có action khôi phục\.

- Suspend yêu cầu xác nhận và lý do\.

- Thành công quay về detail/list phù hợp và hiển thị toast\.

**Business rules**

- Platform Admin không được nhập, xem hoặc nhận mật khẩu mới\.

- Password reset initiate được IAM orchestration; credential/OTP thuộc Supabase Auth (Admin không nhận credential)\.

- Suspend/restore phải ghi privileged Audit\.

- Action khả dụng phụ thuộc identity status hiện hành\.

**Acceptance criteria**

- Action không hợp lệ theo trạng thái không được thực thi\.

- Suspend thành công làm User mất access theo identity policy\.

- Restore thành công cập nhật trạng thái User\.

- Password\-reset request không trả credential cho Platform Admin\.

**Scenarios**

**Scenario SC\-01 — Gửi lại activation invitation**

- Given Platform User đang pending activation

- When Platform Admin chọn gửi lại lời mời kích hoạt

- Then Platform Identity phát activation invitation mới và hệ thống hiển thị kết quả

**Scenario SC\-02 — Tạm ngừng Platform User**

- Given Platform User đang active

- When Platform Admin xác nhận tạm ngừng và nhập lý do

- Then User chuyển sang suspended và Audit được ghi nhận

**References**

- APIs: IAM platform lifecycle \+ Auth adapters (activation, password\-reset initiate, suspend và restore)

- Permissions: platform user administration permissions

- UI/UX: PA\-SG\-01

#### 4\.2\.6\.4 US\-03 — Khởi tạo Tenant và Owner đầu tiên

**Business context**

System Admin cần một flow onboarding thống nhất để tạo hoặc chọn Platform User, tạo Tenant provisioning và chỉ định Owner đầu tiên\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Mosaic Retail System Admin|khởi tạo Tenant và Owner đầu tiên|khách hàng có tổ chức để tiếp tục thiết lập|

**Functional requirements**

- Wizard gồm các bước Owner, Tổ chức và Kiểm tra\.

- Cho phép chọn Platform User hiện hữu hoặc nhập thông tin User mới\.

- User mới gồm họ và tên đệm, tên, email và số điện thoại không bắt buộc\.

- Email đã tồn tại phải resolve về Platform User hiện hữu theo policy\.

- Tên tổ chức là bắt buộc\.

- Role Owner đầu tiên cố định là `Chủ cửa hàng` và hiển thị read\-only\.

- Tạo Tenant và Owner Invitation phải atomic trong Theme 1; profile/Membership khi accept\.

- Thành công mở Tenant detail ở trạng thái provisioning và hiển thị toast\.

**Business rules**

- System Admin phải có `platform.tenant.create`\.

- System Admin không đặt mật khẩu cho User mới\.

- User mới được tạo ở trạng thái pending activation\.

- Người thực hiện onboarding không tự động trở thành Membership\.

- Retry phải sử dụng idempotency và correlation ID\.

**Acceptance criteria**

- Thiếu tên tổ chức hoặc email hợp lệ không thể hoàn tất\.

- Owner đầu tiên có `is_owner = true` và role `Chủ cửa hàng`\.

- Tenant được tạo ở trạng thái provisioning\.

- Retry không tạo duplicate Tenant, Invitation hoặc Membership sau accept\.

**Scenarios**

**Scenario SC\-01 — Khởi tạo với Platform User hiện hữu**

- Given System Admin chọn một Platform User hợp lệ

- When System Admin xác nhận tạo tổ chức

- Then hệ thống tạo Tenant provisioning và Owner Invitation (chưa có Membership)

**Scenario SC\-02 — Khởi tạo với email mới**

- Given email chưa có Auth user

- When System Admin hoàn tất onboarding

- Then Theme 1 tạo Tenant và Owner Invitation; chưa có Platform User hay Membership cho đến khi accept

**References**

- Domains: D\-01, D\-03

- Data: tenants, tenant\_memberships, PlatformUser

- APIs: `POST /platform/tenants`

- UI/UX: PA\-SG\-02

#### 4\.2\.6\.5 US\-04 — Xem mức độ sẵn sàng của tổ chức

**Business context**

Owner cần biết điều kiện bắt buộc nào chưa hoàn tất trước khi kích hoạt tổ chức\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Tenant Owner|xem blocker và warning của tổ chức|tôi biết nội dung cần xử lý trước khi kích hoạt|

**Functional requirements**

- Hiển thị riêng điều kiện bắt buộc và nội dung có thể bổ sung sau\.

- Blocker có CTA dẫn đến màn xử lý phù hợp\.

- Legal Profile mặc định là warning, không phải blocker\.

- Readiness phải được đánh giá lại khi dữ liệu liên quan thay đổi\.

- CTA kích hoạt chỉ khả dụng khi server xác nhận không còn blocker\.

**Business rules**

- TenantReadiness là derived read model\.

- Client không tự xác định readiness\.

- Owner User phải active và email đã xác minh\.

- Tenant phải có đúng một active Owner Membership và role hợp lệ\.

**Acceptance criteria**

- Danh sách blocker và warning khớp kết quả từ server\.

- CTA của blocker mở đúng màn cần bổ sung\.

- Không còn blocker thì CTA kích hoạt được bật\.

- Không có quyền hoặc state thay đổi được hiển thị trong cùng Screen Group\.

**Scenarios**

**Scenario SC\-01 — Tổ chức còn blocker**

- Given Tenant đang provisioning và thiếu thông tin bắt buộc

- When Owner mở readiness

- Then hệ thống hiển thị blocker và CTA xử lý

**Scenario SC\-02 — Tổ chức chỉ còn warning**

- Given Tenant không còn blocker nhưng chưa có Legal Profile

- When Owner mở readiness

- Then hệ thống hiển thị warning và cho phép kích hoạt

**References**

- Domains: D\-01

- APIs: `GET /tenants/{tenant_id}/readiness`

- UI/UX: TA\-SG\-01, TA\-SG\-02

#### 4\.2\.6\.6 US\-05 — Kích hoạt tổ chức

**Business context**

Sau khi hoàn tất các điều kiện bắt buộc, Owner cần xác nhận kích hoạt để mở các capability nghiệp vụ\.

**User story statement**

|As user|I want to|So that|
|---|---|---|
|Tenant Owner|kích hoạt tổ chức khi đủ điều kiện|tổ chức có thể bắt đầu vận hành|

**Functional requirements**

- Hiển thị confirmation trước khi kích hoạt\.

- Server phải đánh giá lại readiness tại thời điểm thực thi\.

- Thành công chuyển Tenant từ provisioning sang active\.

- Sau thành công, điều hướng vào application home và hiển thị toast\.

- Khi state thay đổi hoặc còn blocker, giữ người dùng trong flow và hiển thị lý do\.

**Business rules**

- Chỉ Owner hoặc actor được cấp quyền đặc biệt mới được activate\.

- Activate phải hỗ trợ idempotency\.

- Không activate khi Tenant không ở provisioning\.

- Activation phải phát domain event và Audit\.

**Acceptance criteria**

- Tenant đủ điều kiện được chuyển sang active đúng một lần\.

- Tenant còn blocker không được activate\.

- Retry cùng idempotency key không tạo duplicate event\.

- Sau thành công, quyền và dữ liệu được resolve lại theo Tenant active\.

**Scenarios**

**Scenario SC\-01 — Kích hoạt thành công**

- Given Tenant provisioning không còn blocker

- When Owner xác nhận kích hoạt

- Then Tenant chuyển sang active và ứng dụng mở trang chủ

**Scenario SC\-02 — Readiness thay đổi trước khi kích hoạt**

- Given màn hình đang cho phép kích hoạt nhưng server phát hiện blocker mới

- When Owner xác nhận kích hoạt

- Then hệ thống từ chối thao tác và hiển thị blocker hiện hành

**References**

- APIs: `POST /tenants/{tenant_id}/activate`

- Events: `TenantActivated`

- UI/UX: TA\-SG\-01

##

## 4\.3 EP\-02 — Quản lý tổ chức \& lịch sử quản trị

### 4\.3\.1 Overview

Epic này quản lý hồ sơ tổ chức, Legal Profile, Tenant lifecycle ở cấp nền tảng, ownership cấp nền tảng và lịch sử quản trị\. Tenant\-facing transfer ownership và close Tenant được giữ ở trạng thái Pending/Post\-MVP\.

### 4\.3\.2 Business context

Tenant App cho phép người có quyền duy trì thông tin tổ chức\. Platform Admin App cho phép Mosaic Retail xem Tenant, thành viên, readiness, trạng thái và thực hiện privileged operation mà không cần Membership trong Tenant đích\.

### 4\.3\.3 In scope

- Xem và cập nhật hồ sơ tổ chức\.

- Tạo hoặc cập nhật current Legal Profile\.

- Cảnh báo tax code trùng mà không tiết lộ Tenant khác\.

- Platform Admin xem danh sách và chi tiết Tenant\.

- Platform Admin xem Owner và Membership của Tenant\.

- Platform Admin thay đổi Owner\.

- Platform Admin tạm ngừng và khôi phục Tenant\.

- Xem lịch sử quản trị theo Tenant scope\.

- Xem tổng quan và nhật ký quản trị nền tảng\.

- Nhận diện Tenant closed dưới dạng terminal read\-only state\.

### 4\.3\.4 Out of scope

- Tenant Owner tự chuyển quyền sở hữu trong MVP\.

- Tenant Owner tự đóng tổ chức trong MVP\.

- Closure blocker aggregation trong MVP\.

- Restore Tenant đã closed\.

- Tenant App tự khôi phục Tenant suspended\.

- Chỉnh timezone hoặc base currency\.

- Sửa logo tổ chức nếu chưa được đưa vào MVP design\.

### 4\.3\.5 Entry points

- Tenant App → `Thêm` → `Hồ sơ tổ chức`\.

- Tenant App → readiness blocker → bổ sung thông tin\.

- Tenant App → `Người dùng & vai trò` → `Lịch sử quản trị`\.

- Platform Admin App → `Tổ chức`\.

- Platform Admin App → Tổng quan → Nhật ký quản trị nền tảng\.

- TA\-SG\-07 được giữ mã làm future design reference nhưng không hiển thị trong MVP navigation\.

### 4\.3\.6 User stories

#### 4\.3\.6\.1 User story map

|User story|As user|I want to|So that|Related screen group|Status|
|---|---|---|---|---|---|
|US\-01|Thành viên có quyền|xem hồ sơ tổ chức|biết thông tin và trạng thái hiện hành|TA\-SG\-02|MVP|
|US\-02|Owner hoặc người được ủy quyền|cập nhật hồ sơ tổ chức|thông tin hiển thị luôn chính xác|TA\-SG\-02|MVP|
|US\-03|Người có quyền pháp lý|tạo hoặc cập nhật Legal Profile|capability pháp lý có dữ liệu hiện hành|TA\-SG\-02|MVP|
|US\-04|Tenant Owner|chuyển quyền sở hữu|bàn giao trách nhiệm quản trị|TA\-SG\-07|Post\-MVP|
|US\-05|Tenant Owner|đóng tổ chức|kết thúc vận hành và giữ lịch sử|TA\-SG\-07|Post\-MVP|
|US\-06|Platform Operator|tạm ngừng hoặc khôi phục Tenant|kiểm soát rủi ro cấp nền tảng|PA\-SG\-03|MVP|
|US\-07|Người có quyền audit|xem lịch sử quản trị Tenant|truy vết thay đổi quản trị|TA\-SG\-09|MVP|
|US\-08|Platform Admin|xem Tenant và thành viên|hỗ trợ và quản trị tổ chức|PA\-SG\-03|MVP|
|US\-09|Platform Admin|thay đổi Owner của Tenant|sửa ownership an toàn ở cấp nền tảng|PA\-SG\-03|MVP|
|US\-10|Platform Admin|xem nhật ký quản trị nền tảng|truy vết privileged operation|PA\-SG\-04|MVP|

#### 4\.3\.6\.2 US\-01 — Xem hồ sơ tổ chức

**Functional requirements**

- Hiển thị tên tổ chức, thông tin liên hệ, địa chỉ, trạng thái và Legal Profile hiện hành\.

- Hiển thị trạng thái chưa có Legal Profile khi chưa được tạo\.

- Action chỉnh sửa chỉ hiển thị khi actor có quyền\.

- Tenant suspended hoặc closed vẫn cho xem dữ liệu theo policy\.

**Business rules**

- Dữ liệu phải thuộc TenantContext hiện hành\.

- Email và số điện thoại được hiển thị theo data\-protection policy\.

- Legal Profile là current state, không phải snapshot chứng từ\.

**Acceptance criteria**

- Người có quyền xem được đúng hồ sơ Tenant hiện hành\.

- Người không có quyền chỉnh sửa không thấy mutation action\.

- Cross\-Tenant access không tiết lộ dữ liệu\.

**Scenarios**

**Scenario SC\-01 — Xem hồ sơ hiện hành**

- Given người dùng có quyền xem hồ sơ tổ chức

- When người dùng mở màn hồ sơ

- Then hệ thống hiển thị thông tin của TenantContext hiện hành

**References**

- APIs: `GET /tenants/{tenant_id}`

- UI/UX: TA\-SG\-02

#### 4\.3\.6\.3 US\-02 — Cập nhật hồ sơ tổ chức

**Functional requirements**

- Cho phép cập nhật các field hồ sơ được allowlist\.

- Hiển thị dữ liệu hiện hành khi mở form\.

- Kiểm tra required field và định dạng dữ liệu\.

- Save thành công quay về detail và hiển thị toast\.

- State changed trả lỗi và yêu cầu tải lại dữ liệu\.

**Business rules**

- Không cho sửa status, ownership, timezone hoặc base currency qua profile API\.

- Mutation phải kiểm tra `expected_version`\.

- Tax code và Legal Profile không được cập nhật trong form hồ sơ cơ bản\.

**Acceptance criteria**

- Dữ liệu hợp lệ được lưu và tăng version\.

- Dữ liệu không hợp lệ hiển thị lỗi tại field\.

- Stale version không ghi đè dữ liệu mới hơn\.

**Scenarios**

**Scenario SC\-01 — Cập nhật thành công**

- Given người dùng có `tenant.profile.update`

- When người dùng lưu dữ liệu hợp lệ

- Then hồ sơ được cập nhật và màn detail hiển thị dữ liệu mới

**References**

- APIs: `PATCH /tenants/{tenant_id}`

- UI/UX: TA\-SG\-02

#### 4\.3\.6\.4 US\-03 — Tạo hoặc cập nhật hồ sơ pháp lý

**Functional requirements**

- Cho phép chọn loại chủ thể và nhập tên pháp lý, tax code, địa chỉ đăng ký\.

- Cho phép tạo Legal Profile khi chưa tồn tại hoặc cập nhật profile hiện hành\.

- Tax code trùng hiển thị warning với action tiếp tục hoặc kiểm tra lại\.

- Save thành công quay về hồ sơ tổ chức và hiển thị toast\.

**Business rules**

- Tax code không global unique\.

- Duplicate warning không được tiết lộ Tenant khác\.

- `ENTERPRISE` dùng tax code 10 chữ số; `HOUSEHOLD_BUSINESS` dùng 12 chữ số trong MVP\.

- Chứng từ đã phát hành không được cập nhật theo current Legal Profile\.

**Acceptance criteria**

- Legal Profile hợp lệ được tạo hoặc cập nhật\.

- Tax code sai định dạng bị từ chối\.

- Người dùng có thể tiếp tục lưu sau duplicate warning\.

**Scenarios**

**Scenario SC\-01 — Lưu tax code có cảnh báo trùng**

- Given dữ liệu pháp lý hợp lệ nhưng tax code trùng với dữ liệu khác

- When người dùng chọn vẫn lưu

- Then hệ thống lưu Legal Profile mà không tiết lộ Tenant liên quan

**References**

- APIs: `POST/PATCH /tenants/{tenant_id}/legal-profile`

- UI/UX: TA\-SG\-02

#### 4\.3\.6\.5 US\-04 — Chuyển quyền sở hữu tổ chức

**Status**

- Pending/Post\-MVP\.

- Mã US được giữ để bảo toàn traceability với TA\-SG\-07\.

- Không thuộc MVP functional, API hoặc visual acceptance\.

#### 4\.3\.6\.6 US\-05 — Đóng tổ chức

**Status**

- Pending/Post\-MVP\.

- Bao gồm future blocker aggregation, exact\-name confirmation và close command\.

- Không thuộc MVP functional, API hoặc visual acceptance\.

#### 4\.3\.6\.7 US\-06 — Tạm ngừng hoặc khôi phục Tenant

**Functional requirements**

- Tenant active có action tạm ngừng\.

- Tenant suspended có action khôi phục\.

- Suspend yêu cầu confirmation và lý do\.

- Tenant App hiển thị trạng thái bị tạm ngừng và hướng dẫn liên hệ hỗ trợ\.

- Thành công cập nhật detail và hiển thị toast\.

**Business rules**

- Chỉ Platform Admin có permission phù hợp được thực hiện\.

- Tenant user không được tự restore\.

- Suspended Tenant chặn business operation nhưng giữ dữ liệu và Membership\.

- Closed Tenant không được suspend hoặc restore\.

**Acceptance criteria**

- Active Tenant được chuyển sang suspended\.

- Suspended Tenant được restore khi invariants hợp lệ\.

- Mọi thao tác được ghi Platform Audit\.

**Scenarios**

**Scenario SC\-01 — Tạm ngừng Tenant**

- Given Tenant đang active

- When Platform Operator xác nhận tạm ngừng và nhập lý do

- Then Tenant chuyển sang suspended và access được đánh giá lại

**References**

- APIs: platform suspend/restore APIs

- UI/UX: PA\-SG\-03

#### 4\.3\.6\.8 US\-07 — Xem lịch sử quản trị Tenant

**Functional requirements**

- Hiển thị danh sách sự kiện quản trị theo thời gian\.

- Hỗ trợ lọc theo thời gian, kết quả và actor/subject type\.

- Chi tiết hiển thị event code, Audit ID, actor, target, thời gian, source, tracking ID và before/after\.

- Hỗ trợ trạng thái redacted, actor unavailable, không có kết quả, không có quyền và load error\.

**Business rules**

- AuditLog do IAM sở hữu trong `iam.audit_logs`\.

- Dữ liệu phải được giới hạn theo Tenant scope và permission\.

- Tracking ID là read\-only\.

**Acceptance criteria**

- Kết quả lọc đúng điều kiện\.

- Chi tiết không hiển thị dữ liệu đã bị redaction\.

- Người không có quyền nhận blocked state trong cùng Screen Group\.

**References**

- UI/UX: TA\-SG\-09

#### 4\.3\.6\.9 US\-08 — Xem Tenant và thành viên ở cấp nền tảng

**Functional requirements**

- Hiển thị danh sách Tenant, tìm kiếm và lọc theo lifecycle, cảnh báo và readiness\.

- Chi tiết hiển thị profile, Owner, trạng thái, readiness và Membership khi phù hợp\.

- Membership có thể mở Platform User detail\.

- Tenant provisioning hiển thị readiness issue trực tiếp trong detail\.

**Business rules**

- Platform Admin không cần Membership trong Tenant đích\.

- Query Membership phải dùng platform\-scoped contract\.

- Closed Tenant là read\-only\.

**Acceptance criteria**

- Platform Admin chỉ xem được dữ liệu khi có permission\.

- Thành viên hiển thị đúng role và ownership\.

- Navigation sang User detail và quay lại đúng nguồn\.

**References**

- APIs: platform Tenant detail và Membership query

- UI/UX: PA\-SG\-03

#### 4\.3\.6\.10 US\-09 — Thay đổi Owner ở cấp nền tảng

**Functional requirements**

- Cho phép chọn active Membership cùng Tenant làm Owner mới\.

- Hiển thị role hiện hành của Owner cũ và Owner mới\.

- Confirmation nêu rõ role không thay đổi\.

- Thành công cập nhật ownership summary và hiển thị toast\.

**Business rules**

- Yêu cầu `platform.tenant.owner.transfer`\.

- Tenant không được ở trạng thái closed\.

- Chuyển `is_owner` phải atomic\.

- Không thay đổi `role_id`\.

- Phải invalidate access context và ghi privileged Audit\.

**Acceptance criteria**

- Tenant luôn có đúng một Owner sau mutation\.

- Target không hợp lệ bị từ chối\.

- Retry không tạo duplicate event\.

**Scenarios**

**Scenario SC\-01 — Thay đổi Owner thành công**

- Given target là active Membership cùng Tenant

- When Platform Admin xác nhận thay đổi Owner

- Then ownership được chuyển atomic và role của hai thành viên giữ nguyên

**References**

- APIs: `POST /platform/tenants/{tenant_id}/transfer-ownership`

- UI/UX: PA\-SG\-03

#### 4\.3\.6\.11 US\-10 — Xem nhật ký quản trị nền tảng

**Functional requirements**

- Hiển thị tổng quan hoạt động quản trị nền tảng\.

- Cho phép mở danh sách, lọc và xem chi tiết Audit\.

- Chi tiết hiển thị actor, target, action, result, source, correlation ID và before/after\.

- Áp dụng redaction theo Platform Audit policy\.

**Business rules**

- Chỉ Platform Admin có quyền audit được truy cập\.

- Nhật ký bao gồm privileged action và system event phù hợp\.

- Không hiển thị credential, token hoặc mã xác nhận\.

**Acceptance criteria**

- Platform Admin xem được Audit trong phạm vi quyền\.

- Bộ lọc trả đúng kết quả\.

- Dữ liệu nhạy cảm được redaction\.

**References**

- UI/UX: PA\-SG\-04

## 4\.4 EP\-03 — Thành viên \& lời mời

### 4\.4\.1 Overview

Epic này quản lý danh sách thành viên, Tenant Invitation và Membership lifecycle\. Invitation lifecycle được phân biệt với trạng thái gửi email\.

### 4\.4\.2 Business context

Người quản trị cần mời người dùng tham gia Tenant, kiểm soát lời mời chưa hoàn tất và quản lý access của Membership mà không làm mất dữ liệu lịch sử\.

### 4\.4\.3 In scope

- Xem, tìm kiếm và lọc thành viên\.

- Xem danh sách và chi tiết lời mời\.

- Mời người dùng qua email với initial role\.

- Gửi lại hoặc thu hồi lời mời\.

- Hiển thị trạng thái gửi email độc lập với Invitation status\.

- Chấp nhận hoặc từ chối lời mời qua invitation/identity surface\.

- Xem chi tiết thành viên\.

- Tạm ngừng, kích hoạt lại hoặc loại thành viên\.

- Áp dụng sole\-Owner protection ở backend\.

### 4\.4\.4 Out of scope

- Platform User activation invitation\.

- Chỉnh email hoặc initial role của Invitation đã tạo\.

- Hard delete Membership hoặc Invitation\.

- Self\-service leave Tenant trong MVP visual flow\.

- Owner tự deactivate hoặc remove chính mình\.

- Màn Accept/Decline nằm trực tiếp trong khu vực quản trị Tenant App\.

### 4\.4\.5 Entry points

- Tenant App → `Thêm` → `Người dùng & vai trò` → `Thành viên`\.

- Tab `Thành viên`\.

- Tab `Lời mời`\.

- Member detail\.

- Invitation detail\.

- Public/identity invitation entry từ email\.

### 4\.4\.6 User stories

#### 4\.4\.6\.1 User story map

|User story|As user|I want to|So that|Related screen group|
|---|---|---|---|---|
|US\-01|Người có quyền|xem và tìm kiếm thành viên, lời mời|kiểm soát đội ngũ trong Tenant|TA\-SG\-03|
|US\-02|Owner hoặc Admin được ủy quyền|mời người dùng tham gia Tenant|mở rộng đội ngũ sử dụng Mosaic Retail|TA\-SG\-03|
|US\-03|Người được mời|chấp nhận hoặc từ chối lời mời|chủ động quyết định tham gia|Identity/invitation surface|
|US\-04|Owner hoặc Admin được ủy quyền|gửi lại hoặc thu hồi lời mời|xử lý Invitation chưa hoàn tất|TA\-SG\-03|
|US\-05|Owner hoặc Admin được ủy quyền|xem và thay đổi trạng thái thành viên|kiểm soát access của Membership|TA\-SG\-04|
|US\-06|Owner hoặc Admin được ủy quyền|loại thành viên khỏi tổ chức|kết thúc access nhưng giữ lịch sử|TA\-SG\-04|

#### 4\.4\.6\.2 US\-01 — Xem và tìm kiếm thành viên, lời mời

**Functional requirements**

- Hiển thị hai tab Thành viên và Lời mời\.

- Hỗ trợ tìm kiếm và lọc theo trạng thái\.

- Member item hiển thị tên, email, role, ownership và Membership status\.

- Invitation item hiển thị email, initial role, Invitation status, expiry và delivery outcome\.

- Cho phép mở member detail hoặc invitation detail\.

**Business rules**

- Membership và Invitation là hai loại record độc lập\.

- Delivery outcome không được dùng thay Invitation status\.

- Dữ liệu phải thuộc TenantContext hiện hành\.

**Acceptance criteria**

- Kết quả tìm kiếm và lọc đúng điều kiện\.

- Owner và role được hiển thị độc lập\.

- Invitation hết hạn không hiển thị như pending hợp lệ\.

**References**

- UI/UX: TA\-SG\-03, TA\-SG\-04

#### 4\.4\.6\.3 US\-02 — Mời người dùng tham gia Tenant

**Functional requirements**

- Nhập email và chọn một active system role\.

- Hiển thị thời hạn lời mời 7 ngày\.

- Gửi Invitation và hiển thị kết quả gửi email\.

- Thành công trở về danh sách Lời mời và hiển thị toast\.

**Business rules**

- Không mời User đã có active Membership\.

- Inactive Membership phải dùng reactivate flow\.

- Một Tenant chỉ có một pending Invitation cho cùng canonical email\.

- `initial_role_id` không được thay đổi sau khi tạo\.

**Acceptance criteria**

- Invitation hợp lệ được tạo ở trạng thái pending\.

- Membership conflict được xử lý mà không tiết lộ dữ liệu ngoài quyền\.

- Delivery failure không tự động revoke Invitation\.

**Scenarios**

**Scenario SC\-01 — Mời thành viên thành công**

- Given email chưa có current Membership và role đang active

- When người quản trị gửi lời mời

- Then hệ thống tạo pending Invitation có thời hạn 7 ngày

**References**

- APIs: create Invitation API

- UI/UX: TA\-SG\-03

#### 4\.4\.6\.4 US\-03 — Chấp nhận hoặc từ chối lời mời

**Functional requirements**

- Người nhận mở invitation surface từ email\.

- Chấp nhận yêu cầu đăng nhập và verified email khớp email được mời\.

- Chấp nhận tạo active Membership với initial role\.

- Từ chối chuyển Invitation sang declined\.

**Business rules**

- Token phải hợp lệ, chưa dùng và chưa hết hạn\.

- Accept và tạo Membership phải atomic\.

- Tenant suspended chặn accept nhưng không tự revoke Invitation\.

- UI này thuộc identity/invitation surface, không thuộc TA\-SG\-03 quản trị\.

**Acceptance criteria**

- Invitation hợp lệ được accept đúng một lần\.

- Email không khớp không được tạo Membership\.

- Declined Invitation không thể accept lại\.

**References**

- APIs: accept/decline Invitation APIs

#### 4\.4\.6\.5 US\-04 — Gửi lại hoặc thu hồi lời mời

**Functional requirements**

- Pending Invitation có action gửi lại và thu hồi\.

- Gửi lại tạo Invitation/token mới và cập nhật expiry\.

- Thu hồi yêu cầu confirmation và lý do khi UI policy áp dụng\.

- Thành công cập nhật detail/list và hiển thị toast\.

**Business rules**

- Chỉ pending Invitation mới được resend hoặc revoke\.

- Token cũ phải bị vô hiệu\.

- Resend không được thay email hoặc initial role\.

**Acceptance criteria**

- Invitation cũ không thể được accept sau resend\.

- Revoked Invitation không thể được accept\.

- Delivery outcome mới được hiển thị độc lập\.

**References**

- UI/UX: TA\-SG\-03

#### 4\.4\.6\.6 US\-05 — Xem và thay đổi trạng thái thành viên

**Functional requirements**

- Member detail hiển thị profile reference, role, ownership, trạng thái và ngày tham gia\.

- Active Membership có action đổi role, tạm ngừng và loại thành viên\.

- Inactive Membership có action đổi role, kích hoạt lại và loại thành viên nếu policy cho phép\.

- Removed Membership là read\-only\.

- Thành công quay về detail và hiển thị toast\.

**Business rules**

- Sole Owner không được deactivate\.

- Removed Membership không được reactivate\.

- Status change phải invalidate access từ request tiếp theo\.

- Đổi role được định nghĩa tại EP\-04/US\-03\.

**Acceptance criteria**

- Action hiển thị đúng trạng thái và permission\.

- Deactivate làm Membership mất access\.

- Reactivate khôi phục access theo role hiện hành\.

**References**

- UI/UX: TA\-SG\-04

#### 4\.4\.6\.7 US\-06 — Loại thành viên khỏi tổ chức

**Functional requirements**

- Cho phép loại active hoặc inactive Membership theo permission\.

- Hiển thị confirmation và tác động tới access\.

- Removed Membership chuyển sang terminal read\-only state\.

- Thành công quay về danh sách thành viên và hiển thị toast\.

**Business rules**

- Không được loại sole Owner\.

- Không hard delete Membership\.

- Dữ liệu nghiệp vụ và lịch sử actor phải được giữ lại\.

- User quay lại phải qua Invitation và Membership mới\.

**Acceptance criteria**

- Membership hợp lệ được chuyển sang removed\.

- Removed Membership mất access ngay từ request tiếp theo\.

- Sole Owner operation bị từ chối\.

**References**

- UI/UX: TA\-SG\-04

## 4\.5 EP\-04 — Vai trò \& quyền truy cập

### 4\.5\.1 Overview

Epic này cho phép xem bốn system role MVP, xem permission composition và thay role hiện hành của Membership\. Role catalog là read\-only đối với Tenant\.

### 4\.5\.2 Business context

Tenant cần một mô hình role đơn giản và nhất quán\. Owner là ownership policy độc lập; role quyết định quyền nghiệp vụ và không tự thay đổi khi ownership thay đổi\.

### 4\.5\.3 In scope

- Hiển thị bốn system role: Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho\.

- Xem mô tả và permission composition của từng role\.

- Thay role hiện hành của Membership từ member detail\.

- Hiển thị permission delta trước khi xác nhận\.

- Invalidate EffectivePermissions sau khi đổi role\.

### 4\.5\.4 Out of scope

- Custom role\.

- Tenant chỉnh role–permission mapping\.

- Nhiều role trên một Membership\.

- User\-specific permission override\.

- Role `OWNER`\.

- Màn tự tra cứu EffectivePermissions của thành viên thông thường\.

- Screen Group độc lập cho no\-permission state\.

### 4\.5\.5 Entry points

- Tenant App → `Người dùng & vai trò` → `Vai trò`\.

- Role catalog → role detail\.

- Member detail → `Đổi vai trò`\.

### 4\.5\.6 User stories

#### 4\.5\.6\.1 User story map

|User story|As user|I want to|So that|Related screen group|
|---|---|---|---|---|
|US\-01|Người có quyền|xem system\-role catalog|hiểu các role được cung cấp|TA\-SG\-05|
|US\-02|Người có quyền|xem permission của role|hiểu phạm vi nghiệp vụ của role|TA\-SG\-05|
|US\-03|Owner hoặc Admin được ủy quyền|thay role hiện hành của Membership|thành viên có đúng quyền|TA\-SG\-04|

#### 4\.5\.6\.2 US\-01 — Xem system\-role catalog

**Functional requirements**

- Hiển thị đúng bốn system role MVP\.

- Mỗi item hiển thị tên và mô tả ngắn\.

- Không hiển thị role không assignable cho thao tác gán mới\.

- Có trạng thái lỗi tải catalog\.

**Business rules**

- Role catalog dùng chung toàn hệ thống\.

- Tenant không được thêm, sửa hoặc xóa role\.

- Không hiển thị badge active thông thường khi tất cả role đều khả dụng\.

**Acceptance criteria**

- Danh sách hiển thị đúng release catalog\.

- Không xuất hiện role `OWNER`\.

- Không có mutation action trong Tenant App\.

**References**

- UI/UX: TA\-SG\-05

#### 4\.5\.6\.3 US\-02 — Xem permission của vai trò

**Functional requirements**

- Hiển thị tên, mô tả và các nhóm capability của role\.

- Permission được trình bày bằng nhãn nghiệp vụ dễ hiểu\.

- Internal platform permission không được hiển thị\.

- Deprecated role chỉ hiển thị warning khi cần giải thích dữ liệu hiện hữu\.

**Business rules**

- Permission composition là read\-only\.

- Source of truth là Platform Authorization\.

- UI grouping không làm thay đổi permission code hoặc authorization semantics\.

**Acceptance criteria**

- Role detail hiển thị đúng permission mapping hiện hành\.

- Người dùng không thể thay đổi mapping\.

- Load error không hiển thị dữ liệu cache như dữ liệu xác nhận\.

**References**

- UI/UX: TA\-SG\-05

#### 4\.5\.6\.4 US\-03 — Thay đổi vai trò hiện hành của Membership

**Functional requirements**

- Action đổi role được mở từ member detail\.

- Role picker chỉ hiển thị active assignable role\.

- Hiển thị permission delta trước khi xác nhận\.

- Confirmation hiển thị role cũ và role mới\.

- Thành công quay về member detail và hiển thị toast\.

**Business rules**

- Actor phải có `tenant.role.assign`\.

- Target phải là current Membership cùng Tenant\.

- Đổi role không thay đổi `is_owner`\.

- Owner có thể được gán bất kỳ system role hợp lệ nào\.

- Mutation phải kiểm tra version và invalidate permission context\.

**Acceptance criteria**

- Role hợp lệ được cập nhật đúng một lần\.

- Ownership giữ nguyên sau đổi role\.

- Stale version trả state\-changed error\.

- Target removed hoặc role deprecated bị từ chối\.

**Scenarios**

**Scenario SC\-01 — Đổi role thành công**

- Given actor có quyền và target là current Membership

- When actor xác nhận role mới đang active

- Then hệ thống cập nhật `role_id`, giữ nguyên ownership và tải lại quyền

**References**

- APIs: role\-change API

- UI/UX: TA\-SG\-04

## 4\.6 EP\-05 — Chọn tổ chức \& kiểm soát Tenant context

### 4\.6\.1 Overview

Epic này cho phép Platform User xem các Tenant có thể truy cập, chuyển Tenant đang làm việc và xử lý an toàn khi TenantContext không còn hợp lệ\.

### 4\.6\.2 Business context

Một Platform User có thể tham gia nhiều Tenant\. Việc chọn hoặc chuyển Tenant phải tải lại dữ liệu và quyền; LastSelectedTenant chỉ là preference và không được dùng làm bằng chứng cấp quyền\.

### 4\.6\.3 In scope

- Hiển thị Tenant hiện hành\.

- Hiển thị các Tenant có active Membership và access hợp lệ\.

- Hiển thị role hiện hành tại từng Tenant\.

- Vô hiệu lựa chọn Tenant suspended\.

- Xác nhận trước khi chuyển Tenant\.

- Hiển thị loading trong khi resolve context mới\.

- Tải lại dữ liệu và permission sau khi chuyển\.

- Validate LastSelectedTenant\.

- Xử lý context bị invalidated trong Screen Group hiện hành\.

### 4\.6\.4 Out of scope

- Tenant user tự tạo Tenant\.

- Chuyển sang Tenant không có active Membership\.

- Dùng LastSelectedTenant để bỏ qua authorization\.

- Màn TA\-SG\-08 độc lập\.

- Initial tenant selection, no\-Tenant hoặc offline state nếu chưa có design MVP được phê duyệt\.

- Branch hoặc Store selector trong Theme 1\.

### 4\.6\.5 Entry points

- Tenant App Home → tên tổ chức hiện hành\.

- Organization selector\.

- Context\-invalid redirect từ màn đang sử dụng\.

- App startup validation của LastSelectedTenant\.

### 4\.6\.6 User stories

#### 4\.6\.6\.1 User story map

|User story|As user|I want to|So that|Related screen group|
|---|---|---|---|---|
|US\-01|Platform User|xem các Tenant có thể truy cập|biết các tổ chức mình có thể làm việc|TA\-SG\-06|
|US\-02|Platform User thuộc nhiều Tenant|chuyển sang Tenant khác|làm việc trong đúng dữ liệu và quyền|TA\-SG\-06|
|US\-03|Platform User|dùng lại Tenant gần nhất khi còn hợp lệ|mở ứng dụng nhanh hơn|Context contract|
|US\-04|Platform User|được xử lý an toàn khi context mất hiệu lực|không tiếp tục truy cập dữ liệu trái phép|Shared state|

#### 4\.6\.6\.2 US\-01 — Xem các Tenant có thể truy cập

**Functional requirements**

- Selector hiển thị Tenant hiện hành và các Tenant có thể truy cập\.

- Mỗi Tenant hiển thị tên và role hiện hành\.

- Tenant suspended hiển thị disabled\.

- Không hiển thị Tenant không còn accessible\.

**Business rules**

- Accessible Tenant yêu cầu identity active và active Membership\.

- Tenant closed không được chọn làm business context\.

- Role hiển thị không được dùng thay server authorization\.

**Acceptance criteria**

- Danh sách khớp access query hiện hành\.

- Tenant hiện hành được đánh dấu rõ\.

- Tenant không thể truy cập không được chọn\.

**References**

- UI/UX: TA\-SG\-06

#### 4\.6\.6\.3 US\-02 — Chuyển sang Tenant khác

**Functional requirements**

- Chọn Tenant đích từ selector\.

- Hiển thị confirmation trước khi chuyển\.

- Hiển thị loading trong quá trình resolve context\.

- Tải lại navigation, dữ liệu và EffectivePermissions theo Tenant mới\.

- Thành công trở về Home và hiển thị toast\.

**Business rules**

- Server phải kiểm tra lại access tại thời điểm chuyển\.

- Tenant đích phải khác Tenant hiện hành\.

- Context cũ không được dùng sau khi chuyển thành công\.

- LastSelectedTenant chỉ được cập nhật sau khi resolve thành công\.

**Acceptance criteria**

- Dữ liệu sau chuyển chỉ thuộc Tenant đích\.

- Permission được tải lại\.

- Chuyển thất bại giữ nguyên context cũ nếu context cũ vẫn hợp lệ\.

**Scenarios**

**Scenario SC\-01 — Chuyển Tenant thành công**

- Given Platform User có access tới Tenant đích

- When người dùng xác nhận chuyển

- Then hệ thống resolve context mới, tải lại dữ liệu và cập nhật LastSelectedTenant

**References**

- UI/UX: TA\-SG\-06

#### 4\.6\.6\.4 US\-03 — Dùng lại Tenant gần nhất

**Functional requirements**

- Đọc LastSelectedTenant khi khởi động ứng dụng\.

- Validate lại identity, Tenant status và Membership\.

- Nếu hợp lệ, resolve TenantContext\.

- Nếu không hợp lệ, không tự mở dữ liệu của Tenant đó\.

**Business rules**

- LastSelectedTenant là preference, không phải access grant\.

- Validation phải dùng trạng thái server hiện hành\.

- Không cache permission vượt quá thời điểm invalidation\.

**Acceptance criteria**

- Tenant hợp lệ được chọn lại\.

- Tenant không hợp lệ không được resolve\.

- Không có dữ liệu Tenant được hiển thị trước khi validation hoàn tất\.

**References**

- Platform User Preference contract

#### 4\.6\.6\.5 US\-04 — Xử lý TenantContext không còn hợp lệ

**Functional requirements**

- Dừng mutation và không tải thêm dữ liệu khi context bị invalidated\.

- Hiển thị blocked state trong Screen Group hiện hành\.

- Cho phép mở selector khi còn Tenant khác accessible\.

- Xóa dữ liệu nhạy cảm của context cũ khỏi client state\.

**Business rules**

- Invalidation có thể phát sinh từ Membership, role, ownership, identity hoặc Tenant status\.

- Server authorization là nguồn quyết định cuối cùng\.

- Không cần route TA\-SG\-08 độc lập\.

**Acceptance criteria**

- Người dùng không tiếp tục xem dữ liệu mới từ context cũ\.

- Tenant khác còn hợp lệ có thể được chọn\.

- Không còn Tenant hợp lệ thì ứng dụng không hiển thị business workspace\.

**References**

- Domains: D\-04

- UI/UX: shared blocked state

# 5\. UI/UX design

## 5\.1 Design principles

- **DP\-01 — Hai application surface riêng:** Tenant App và Platform Admin App là hai application surface mobile\-first riêng, có navigation, context và permission model độc lập\.

- **DP\-02 — Đúng application context:** Tenant App sử dụng TenantContext và tenant permission; Platform Admin App sử dụng PlatformAdminContext và platform permission\.

- **DP\-03 — Thuật ngữ giao diện:** Trong UI sử dụng thống nhất thuật ngữ `Tổ chức`; `Tenant` chỉ dùng trong domain, API và tài liệu kỹ thuật\.

- **DP\-04 — Mobile portrait:** Màn hình thiết kế theo mobile portrait, frame chuẩn 402 × 874\. Màn dài được kéo dài theo chiều dọc, không resize hoặc kéo giãn nội dung theo chiều ngang\.

- **DP\-05 — One primary action:** Mỗi màn hình chỉ có một primary CTA rõ ràng\. Secondary action dùng secondary button hoặc action sheet; destructive action dùng semantic danger\.

- **DP\-06 — Progressive disclosure:** Form và detail dài được chia theo card hoặc section; chỉ mở màn phụ, bottom sheet hoặc confirmation khi người dùng cần thao tác sâu hơn\.

- **DP\-07 — Ownership và role độc lập:** Role hiện hành và quyền sở hữu luôn được hiển thị riêng\. Role `Chủ cửa hàng` không được dùng để suy ra người dùng là Owner\.

- **DP\-08 — Honest status:** Trạng thái phải được thể hiện bằng text label, không chỉ bằng màu; list, detail và action flow phải hiển thị nhất quán\.

- **DP\-09 — Route, overlay, state và toast:** Màn điều hướng, bottom sheet/modal, trạng thái nội dung và toast là bốn loại UI khác nhau; không tạo một màn hình riêng cho confirmation hoặc success đơn giản\.

- **DP\-10 — Mutation feedback:** Mutation thành công quay về list/detail/Home phù hợp và hiển thị toast\. Không tạo standalone success screen trừ khi nghiệp vụ yêu cầu người dùng đưa ra quyết định tiếp theo\.

- **DP\-11 — Bottom sheet:** Action sheet và confirmation trên mobile dùng bottom sheet có handle, dim overlay và tối đa hai CTA\. Row có chevron khi mở bước tiếp theo\.

- **DP\-12 — Source changed:** Khi dữ liệu thay đổi trong lúc thao tác, hệ thống không ghi đè; hiển thị thông báo và CTA tải lại\.

- **DP\-13 — Permission\-aware navigation:** Entry quản trị chỉ hiển thị khi actor có quyền\. Việc ẩn entry không thay thế server\-side authorization\.

- **DP\-14 — Data protection:** Không hiển thị hoặc ghi lại password, token, mã xác nhận hoặc dữ liệu đã bị redact\. Email và dữ liệu cá nhân được mask khi cần\.

- **DP\-15 — Context safety:** Khi Membership, Tenant hoặc authorization context không còn hợp lệ, client phải xóa dữ liệu nhạy cảm trước khi hiển thị blocked state\.

- **DP\-16 — Design source of truth:** Các Figma board được liệt kê trong Phần 5 là nguồn thiết kế MVP hiện hành\. Low\-fi text\-character visuals của phiên bản trước không còn là nguồn tham chiếu chính\.

- **DP\-17 — MVP boundary:** `TA-SG-07 — Quyền sở hữu & vòng đời tổ chức` được giữ làm future design reference nhưng không thuộc MVP\. Không có `TA-SG-08` độc lập trong MVP\.

## 5\.2 UX concepts

### 5\.2\.1 Tenant App

- Dành cho Owner, người có quyền quản trị và thành viên của tổ chức\.

- Dùng TenantContext, Membership và tenant\-scoped permission\.

- Entry `Người dùng & vai trò` chỉ hiển thị cho Owner hoặc người có quyền quản trị phù hợp\.

- Entry `Tài khoản của tôi` hiển thị cho mọi Platform User đã đăng nhập\.

- Readiness chỉ xuất hiện khi tổ chức đang provisioning hoặc khi actor mở từ entry quản trị phù hợp\.

- Tenant App không có CTA tạo Platform User hoặc tạo tổ chức mới\.

- Tenant\-facing transfer ownership và close Tenant không xuất hiện trong MVP navigation\.

### 5\.2\.2 Platform Admin App

- Dành cho Mosaic Retail System Admin và Platform Operator\.

- Không yêu cầu actor có Membership trong tổ chức đích\.

- Quản lý Platform User, onboarding tổ chức, trạng thái tổ chức, ownership cấp nền tảng và Platform Audit\.

- Privileged mutation sử dụng platform permission, confirmation, reason và step\-up khi policy yêu cầu\.

- Chỉ hiển thị dữ liệu cần thiết cho nghiệp vụ quản trị; không mở rộng sang dữ liệu kinh doanh của tổ chức\.

### 5\.2\.3 Shared mobile patterns

- **Top bar:** Back icon, title ngắn và action bên phải khi cần\.

- **Search:** Đặt ngay dưới top bar; filter mở bằng bottom sheet\.

- **List:** Row hoặc card có thông tin chính, status label và chevron khi mở detail\.

- **Detail:** Nội dung chia thành card; action quản trị được gom trong button `Thao tác`\.

- **Form:** Label cố định, helper text, inline validation và sticky CTA\.

- **Action sheet:** Chỉ hiển thị action hợp lệ theo permission và trạng thái\.

- **Confirmation:** Nêu rõ action, đối tượng và tác động; không dùng copy chung chung như “Bạn có chắc không?”\.

- **Toast:** Dùng cho mutation success hoặc feedback ngắn không cần người dùng lựa chọn\.

- **Empty state:** Dùng khi chưa có dữ liệu\.

- **No\-result state:** Dùng khi search/filter không có kết quả và có CTA xóa bộ lọc khi phù hợp\.

- **Blocked state:** Hiển thị tại Screen Group đang sở hữu ngữ cảnh; không điều hướng tới một `TA-SG-08` riêng\.

- **Navigation return:** Back quay về đúng màn nguồn theo navigation stack, bao gồm trường hợp mở Platform User từ chi tiết tổ chức\.

## 5\.3 User flows

### 5\.3\.1 Platform User lifecycle

Platform Admin App → Danh sách Platform User → Chi tiết User → Chọn action phù hợp trạng thái → Confirmation khi cần → Thực thi qua IAM platform CQRS / Auth adapters → Quay về chi tiết → Toast

### 5\.3\.2 Platform onboarding

Platform Admin App → Thêm tổ chức → Bước Chủ sở hữu → Bước Tổ chức → Bước Kiểm tra → Provisioning → Chi tiết tổ chức đang provisioning → Toast

### 5\.3\.3 Tenant readiness \& activation

Tenant App → Thêm → Người dùng \& vai trò → Readiness → Xử lý điều kiện bắt buộc tại màn liên quan → Quay lại readiness → Xác nhận kích hoạt → Home → Toast

### 5\.3\.4 Hồ sơ tổ chức \& pháp lý

Hồ sơ tổ chức → Thao tác → Chỉnh thông tin tổ chức hoặc thêm/chỉnh hồ sơ pháp lý → Lưu → Cảnh báo tax code trùng khi có → Chi tiết tổ chức → Toast

### 5\.3\.5 Tenant member invitation

Thành viên \& lời mời → Tab Lời mời → Mời thành viên → Nhập email và role → Gửi lời mời → Danh sách lời mời → Toast

### 5\.3\.6 Invitation lifecycle

Chi tiết lời mời → Gửi lại hoặc Thu hồi → Confirmation khi thu hồi → Cập nhật chi tiết/danh sách → Toast

### 5\.3\.7 Membership lifecycle

Danh sách thành viên → Chi tiết thành viên → Thao tác → Tạm ngừng, kích hoạt lại hoặc loại thành viên → Confirmation → Chi tiết hoặc danh sách → Toast

### 5\.3\.8 Change member role

Chi tiết thành viên → Thao tác → Đổi vai trò → Chọn role → Xem thay đổi quyền → Confirmation → Chi tiết thành viên → Toast

### 5\.3\.9 Select and switch organization

Home → Chọn tổ chức hiện hành → Organization selector → Chọn tổ chức đích → Confirmation → Loading → Home của tổ chức mới → Toast

### 5\.3\.10 Platform organization administration

Platform Admin App → Danh sách tổ chức → Chi tiết tổ chức → Xem readiness, Owner và thành viên → Thay Owner hoặc suspend/restore → Confirmation → Chi tiết tổ chức → Toast

### 5\.3\.11 Audit review

Danh sách lịch sử → Filter khi cần → Chi tiết Audit → Hiển thị before/after hoặc redacted state → Back về danh sách

### 5\.3\.12 My Account

Thêm → Tài khoản của tôi → Xem hồ sơ → Chỉnh sửa hoặc đặt lại mật khẩu hoặc đăng xuất

### 5\.3\.13 Password reset

Tài khoản của tôi → Đặt lại mật khẩu → Gửi mã tới email đã xác minh → Nhập mã → Nhập mật khẩu mới → Hồ sơ cá nhân → Toast

## 5\.4 Visual architecture

### 5\.4\.1 Tenant App

Tenant App

├── Home

│   ├── Tổ chức hiện hành

│   └── Chuyển tổ chức

├── Thêm

│   ├── Hồ sơ tổ chức

│   ├── Người dùng \& vai trò \[theo quyền\]

│   │   ├── Readiness \& kích hoạt \[khi provisioning\]

│   │   ├── Thành viên \& lời mời

│   │   ├── Vai trò

│   │   └── Lịch sử quản trị

│   └── Tài khoản của tôi \[mọi authenticated User\]

└── Shared states

├── No permission

├── Context invalid

├── Membership inactive/removed

├── Tenant suspended/closed

└── Error/source changed

### 5\.4\.2 Platform Admin App

Platform Admin App

├── Người dùng

│   ├── Danh sách Platform User

│   ├── Platform User detail

│   └── Activation / reset password / suspend / restore

├── Tổ chức

│   ├── Danh sách tổ chức

│   ├── Onboarding

│   ├── Chi tiết tổ chức

│   ├── Owner \& thành viên

│   └── Transfer Owner / suspend / restore

└── Nhật ký hoạt động

├── Tổng quan

├── Danh sách Audit

├── Bộ lọc

└── Chi tiết Audit

## 5\.5 Screen groups

### 5\.5\.1 Tenant App SG map

|Screen group|Name|Related scope|Figma node|Status|
|---|---|---|---|---|
|TA\-SG\-01|Readiness \& kích hoạt tổ chức|EP\-01/US\-04, US\-05|`174:1520`|MVP|
|TA\-SG\-02|Hồ sơ tổ chức \& pháp lý|EP\-02/US\-01, US\-02, US\-03|`190:325`|MVP|
|TA\-SG\-03|Thành viên \& lời mời|EP\-03/US\-01, US\-02, US\-04|`207:2241`|MVP|
|TA\-SG\-04|Chi tiết \& lifecycle thành viên|EP\-03/US\-05, US\-06; EP\-04/US\-03|`220:32`|MVP|
|TA\-SG\-05|Vai trò hệ thống|EP\-04/US\-01, US\-02|`239:2976`|MVP|
|TA\-SG\-06|Chọn \& chuyển tổ chức|EP\-05/US\-01, US\-02|`255:57`|MVP|
|TA\-SG\-07|Quyền sở hữu \& vòng đời tổ chức|EP\-02/US\-04, US\-05|`267:3415`|Pending/Post\-MVP|
|TA\-SG\-09|Lịch sử quản trị|EP\-02/US\-07|`277:3710`|MVP|
|TA\-SG\-10|Tài khoản của tôi|EP\-06/US\-01 đến US\-04|`460:3172`|MVP|
|**TA\-SG\-08**|||||

- Không có Figma board và không được triển khai như một Screen Group độc lập\.

- No\-permission, context\-invalid và lifecycle\-blocked state được đặt trong Screen Group đang sở hữu ngữ cảnh\.

- Giữ khoảng trống mã để không renumber TA\-SG\-09 và TA\-SG\-10\.

### 5\.5\.2 TA\-SG\-01 — Readiness \& kích hoạt tổ chức

**Purpose**

Giúp Owner xem các điều kiện bắt buộc, xử lý blocker và kích hoạt tổ chức\.

**Entry points**

- `Thêm`\.

- `Người dùng & vai trò`\.

- Entry quản trị khi tổ chức đang provisioning\.

**UI contract**

- Entry `Người dùng & vai trò` chỉ hiển thị theo permission\.

- Readiness chia thành `Điều kiện bắt buộc` và `Có thể bổ sung sau`\.

- Legal Profile là warning, không mặc định là blocker\.

- Blocker có CTA deep\-link tới màn xử lý, chủ yếu là TA\-SG\-02\.

- Không có màn blocker detail riêng\.

- CTA kích hoạt chỉ khả dụng khi server xác nhận không còn blocker\.

- Activation confirmation dùng bottom sheet\.

- Thành công điều hướng về Home và hiển thị toast\.

- Lỗi, no\-permission hoặc source\-changed được hiển thị trong cùng flow\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Thêm|
|TA\-D\-02|Người dùng \& vai trò|
|TA\-D\-03|Readiness — còn điều kiện bắt buộc|
|TA\-D\-04|Readiness — đủ điều kiện kích hoạt|
|TA\-D\-05|Confirmation kích hoạt — bottom sheet|
|TA\-D\-06|Home sau kích hoạt \+ toast|

### 5\.5\.3 TA\-SG\-02 — Hồ sơ tổ chức \& pháp lý

**Purpose**

Cho người dùng xem và cập nhật hồ sơ tổ chức cùng current Legal Profile\.

**Entry points**

- `Thêm` → `Hồ sơ tổ chức`\.

- Readiness blocker từ TA\-SG\-01\.

**UI contract**

- Detail hiển thị tên tổ chức, liên hệ, địa chỉ và Legal Profile hiện hành hoặc trạng thái chưa có\.

- Không hiển thị readiness summary, timezone hoặc currency nếu không cần cho nghiệp vụ\.

- Action `Thao tác` mở bottom sheet gồm chỉnh thông tin tổ chức và thêm/chỉnh hồ sơ pháp lý\.

- Hồ sơ tổ chức và Legal Profile dùng hai form riêng\.

- Không có chỉnh logo trong phạm vi MVP hiện tại\.

- Duplicate tax code là warning với hai action `Vẫn lưu` và `Kiểm tra lại`\.

- Save thành công quay về detail và hiển thị toast\.

- No\-permission và source\-changed là state trong cùng Screen Group\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Chi tiết hồ sơ tổ chức|
|TA\-D\-02|Action sheet hồ sơ tổ chức|
|TA\-D\-03|Chỉnh thông tin tổ chức|
|TA\-D\-04|Thêm hồ sơ pháp lý|
|TA\-D\-05|Chỉnh hồ sơ pháp lý|
|TA\-D\-06|Cảnh báo tax code trùng|
|TA\-D\-07|Chi tiết sau khi lưu \+ toast|

### 5\.5\.4 TA\-SG\-03 — Thành viên \& lời mời

**Purpose**

Quản lý danh sách Membership, Tenant Invitation và flow mời thành viên\.

**Entry points**

- `Người dùng & vai trò` → `Thành viên`\.

- Member/Invitation tabs\.

**UI contract**

- Giao diện Tenant App có hai tab `Thành viên` và `Lời mời`\. Platform Admin không quản lý lời mời thành viên thông thường\.

- Hỗ trợ search, status filter và count\.

- Form mời chỉ gồm email và initial role\.

- Invitation detail hiển thị email, role, tổ chức, thời điểm gửi, thời hạn, Invitation status và delivery outcome\.

- Invitation status và email delivery outcome được hiển thị độc lập\.

- Gửi lại không cần confirmation; thành công hiển thị toast\.

- Thu hồi dùng confirmation bottom sheet và có thể nhập lý do\.

- Accept/Decline của người nhận thuộc identity/invitation surface, không thuộc board quản trị này\.

- Membership conflict, invalid hoặc expired state được xử lý trong flow, không tạo Screen Group riêng\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Tab Thành viên|
|TA\-D\-02|Tab Lời mời|
|TA\-D\-03|Mời thành viên|
|TA\-D\-04|Chi tiết lời mời|
|TA\-D\-05|Gửi lại lời mời \+ toast|
|TA\-D\-06|Confirmation thu hồi — bottom sheet|
|TA\-D\-07|Danh sách/chi tiết sau thu hồi \+ toast|
|TA\-D\-08|Empty / no result / error|

### 5\.5\.5 TA\-SG\-04 — Chi tiết \& lifecycle thành viên

**Purpose**

Xem Membership detail, thay đổi role và quản lý Membership lifecycle\.

**Entry points**

- Tab Thành viên → chọn thành viên\.

- Platform navigation từ các màn có member reference\.

**UI contract**

- Detail hiển thị identity reference, role hiện hành, ownership, Membership status và ngày tham gia\.

- Role hiển thị theo dạng `Vai trò hiện hành`\.

- Ownership hiển thị riêng theo dạng `Quyền sở hữu: Chủ sở hữu` khi áp dụng\.

- Active Membership có action đổi vai trò, tạm ngừng và loại thành viên\.

- Inactive Membership có action đổi vai trò, kích hoạt lại và loại thành viên khi policy cho phép\.

- Removed Membership là terminal và read\-only\.

- Flow đổi role gồm role picker, permission delta và confirmation\.

- Thay role không thay đổi ownership\.

- Suspend, reactivate và remove dùng confirmation bottom sheet\.

- Sole\-Owner protection phải được backend enforce và hiển thị blocked reason tại flow tương ứng\.

- Self\-service leave Tenant chưa thuộc MVP visual coverage\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Chi tiết thành viên active|
|TA\-D\-02|Action sheet thành viên|
|TA\-D\-03|Chọn vai trò|
|TA\-D\-04|Xem thay đổi quyền|
|TA\-D\-05|Confirmation đổi vai trò|
|TA\-D\-06|Chi tiết sau đổi vai trò \+ toast|
|TA\-D\-07|Confirmation tạm ngừng|
|TA\-D\-08|Chi tiết thành viên inactive|
|TA\-D\-09|Confirmation kích hoạt lại|
|TA\-D\-10|Confirmation loại thành viên|
|TA\-D\-11|Chi tiết Membership đã loại|

### 5\.5\.6 TA\-SG\-05 — Vai trò hệ thống

**Purpose**

Cho người có quyền xem system\-role catalog và permission composition ở chế độ read\-only\.

**Entry points**

- `Người dùng & vai trò` → `Vai trò`\.

**UI contract**

- Top bar sử dụng tên `Vai trò`\.

- Danh sách gồm đúng bốn role: Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho\.

- Không hiển thị status badge cho role active thông thường\.

- Role detail nhóm permission theo capability nghiệp vụ và dùng nhãn tiếng Việt dễ hiểu\.

- Không hiển thị internal platform permission\.

- Không có role picker, permission preview, confirmation hoặc EffectivePermissions trong Screen Group này\.

- Flow đổi role thuộc TA\-SG\-04\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Danh sách vai trò|
|TA\-D\-02|Chi tiết vai trò|
|TA\-D\-03|Catalog error|

### 5\.5\.7 TA\-SG\-06 — Chọn \& chuyển tổ chức

**Purpose**

Cho Platform User chuyển giữa các tổ chức đang có quyền truy cập trong lúc sử dụng ứng dụng\.

**Entry points**

- Home → tên tổ chức hiện hành\.

**UI contract**

- Selector hiển thị tổ chức hiện hành và các tổ chức accessible\.

- Mỗi tổ chức hiển thị tên và role hiện hành\.

- Tổ chức suspended được hiển thị disabled khi cần giải thích lý do không thể chọn\.

- Không hiển thị Store hoặc Warehouse\.

- Không có CTA tạo tổ chức mới\.

- Chọn tổ chức mở confirmation\.

- Trong lúc chuyển hiển thị loading và không cho thao tác dữ liệu cũ\.

- Thành công trở về Home của tổ chức mới và hiển thị toast\.

- Initial post\-login selection, search, unsaved\-data warning, no\-organization và offline state chưa thuộc MVP visual coverage\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Home với tổ chức hiện hành|
|TA\-D\-02|Organization selector|
|TA\-D\-03|Confirmation chuyển tổ chức|
|TA\-D\-04|Đang chuyển tổ chức|
|TA\-D\-05|Home của tổ chức mới \+ toast|

### 5\.5\.8 TA\-SG\-07 — Quyền sở hữu \& vòng đời tổ chức

**Status**

- Pending/Post\-MVP\.

- Không xuất hiện trong MVP navigation\.

- Không được tính vào MVP design coverage hoặc acceptance\.

- Figma node `267:3415` chỉ là future research/design reference\.

**Future scope**

- Tenant Owner tự chuyển quyền sở hữu\.

- Review blocker trước khi đóng tổ chức\.

- Strong confirmation khi đóng\.

- Tenant\-facing closed state và hậu quả sau khi đóng\.

**MVP boundary**

- Ownership hiện hành vẫn được hiển thị tại Membership và Platform Admin App\.

- Platform Admin transfer ownership thuộc PA\-SG\-03\.

- Tenant suspended/closed state được xử lý tại màn đang sử dụng hoặc organization selector\.

### 5\.5\.9 Shared blocked, context\-invalid \& feedback patterns

**Status**

- Đây là shared UI pattern, không phải `TA-SG-08`\.

**Patterns**

|State|Presentation|Main behavior|
|---|---|---|
|No permission|Inline blocked state hoặc full\-content state trong SG hiện hành|Không hiển thị mutation CTA|
|Membership inactive|Blocked state trong màn hiện hành|Cho phép chuyển tổ chức khi có lựa chọn khác|
|Membership removed|Clear dữ liệu cũ rồi hiển thị blocked state|Không cho retry mutation|
|Tenant suspended|Banner hoặc blocked state tùy context|Business operation bị chặn|
|Tenant closed|Read\-only/blocked state|Không có restore tenant\-facing|
|Context invalid|Clear/partition cache trước khi render|Mở organization selector khi phù hợp|
|Not found/cross\-Tenant|Non\-enumerating message|Quay lại màn an toàn|
|Source changed|Inline message hoặc bottom sheet|CTA tải lại|
|System error|Error state trong SG hiện hành|CTA thử lại khi an toàn|

### 5\.5\.10 TA\-SG\-09 — Lịch sử quản trị

**Purpose**

Cho người có quyền xem AuditLog của tổ chức từ IAM (`iam.audit_logs`).

**Entry points**

- `Người dùng & vai trò` → `Lịch sử quản trị`\.

**UI contract**

- Danh sách hiển thị sự kiện theo thời gian và actor\.

- Filter dùng bottom sheet\.

- Bộ lọc gồm thời gian, kết quả, actor/subject type và nhóm nhanh Thành viên, Vai trò, Tổ chức\.

- Audit detail hiển thị event code, Audit ID, actor/type, target, thời gian, source, tracking ID và before/after\.

- Hỗ trợ actor là người dùng hoặc system process\.

- Tracking ID là read\-only\.

- Nội dung nhạy cảm phải được redact\.

- Actor đã rời tổ chức vẫn được hiển thị bằng historical snapshot\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Lịch sử quản trị|
|TA\-D\-02|Bộ lọc — bottom sheet|
|TA\-D\-03|Chi tiết Audit|
|TA\-D\-04|Nội dung đã redact|
|TA\-D\-05|Không có kết quả|
|TA\-D\-06|Actor không còn khả dụng|
|TA\-D\-07|No permission / load error|

### 5\.5\.11 TA\-SG\-10 — Tài khoản của tôi

**Purpose**

Cho mọi authenticated Platform User tự quản lý hồ sơ cá nhân, mật khẩu và phiên sử dụng\.

**Entry points**

- `Thêm` → `Tài khoản của tôi`\.

**UI contract**

- Profile thuộc Platform User, không thuộc Membership\.

- Hiển thị avatar/initials, họ và tên đệm, tên, email đăng nhập, trạng thái xác minh và số điện thoại\.

- Email đăng nhập là read\-only\.

- Action gồm chỉnh sửa thông tin, đặt lại mật khẩu và đăng xuất\.

- Form chỉnh sửa cho phép cập nhật avatar, họ và tên đệm, tên và số điện thoại\.

- Password\-reset flow gửi mã sáu chữ số tới email đã xác minh và hiển thị email đã mask\.

- Form mật khẩu mới chỉ xuất hiện sau khi mã được xác minh\.

- Thành công quay về profile và hiển thị toast\.

- Logout dùng confirmation bottom sheet\.

- Profile và credential operation không phụ thuộc TenantContext\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|TA\-D\-01|Tài khoản của tôi|
|TA\-D\-02|Chỉnh sửa thông tin cá nhân|
|TA\-D\-03|Hồ sơ sau cập nhật \+ toast|
|TA\-D\-04|Yêu cầu đặt lại mật khẩu|
|TA\-D\-05|Nhập và xác minh mã|
|TA\-D\-06|Nhập mật khẩu mới|
|TA\-D\-07|Hồ sơ sau đổi mật khẩu \+ toast|
|TA\-D\-08|Confirmation đăng xuất — bottom sheet|

### 5\.5\.12 Platform Admin App SG map

|Screen group|Name|Related scope|Figma node|Status|
|---|---|---|---|---|
|PA\-SG\-01|Quản lý người dùng nền tảng|EP\-01/US\-01, US\-02|`40:32`|MVP|
|PA\-SG\-02|Khởi tạo khách hàng \& Chủ sở hữu|EP\-01/US\-03|`81:458`|MVP|
|PA\-SG\-03|Quản lý tổ chức cấp nền tảng|EP\-02/US\-06, US\-08, US\-09|`95:920`|MVP|
|PA\-SG\-04|Nhật ký hoạt động|EP\-02/US\-10|`104:1023`|MVP|

### 5\.5\.13 PA\-SG\-01 — Quản lý người dùng nền tảng

**Purpose**

Cho Platform Admin xem, tra cứu và quản lý lifecycle của Platform User\.

**Entry points**

- Platform Admin App → `Người dùng`\.

- Chi tiết tổ chức → chọn một Membership\.

**UI contract**

- Danh sách hỗ trợ search theo tên/email và filter theo identity status\.

- Không có standalone create Platform User trong MVP; User mới được tạo từ PA\-SG\-02\.

- User detail hiển thị email verification, identity status, lần đăng nhập gần nhất, ngày tạo và Membership\.

- Active User có action đặt lại mật khẩu và tạm ngừng\.

- PA-D-01 loại người chỉ có Invitation và bỏ filter “Chờ kích hoạt”; PA-D-03 hiển thị email ngay dưới tên; bỏ các thao tác người dùng pending của PA-O-02.

- PA-SG-02 quản lý Owner Invitation tại Platform Admin → Tổ chức: giữ nút “Thao tác” hiện có; ở Tenant `settingUp` với Invitation `pending`/`expired`, sheet chỉ có “Gửi lại email” (không có “Tạm ngừng tổ chức”), mở sheet “Gửi lại email thiết lập?”; reuse cùng invitation khi gửi lại/đổi email. Không mở sheet rỗng nếu không còn thao tác hợp lệ. Khi Tenant đã `active` hoặc `suspended`, không hiện gửi lại email, giữ “Thay đổi chủ sở hữu” và các thao tác hiện tại. Không sửa banner/nền trang trong slice UI này.

- TA-D-01 chỉ liệt kê Membership thật. Invitation thành viên pending nằm ở Tenant App → Lời mời; Platform Admin không quản lý loại lời mời này.

- Readiness của Owner phân biệt đang chờ và hết hạn trước khi accept, cả hai có `canActivate=false`; trạng thái hết hạn trên readiness không có thao tác khôi phục.

- Active User có action đặt lại mật khẩu và tạm ngừng.

- Platform Admin không nhập hoặc xem mật khẩu\.

- Suspend dùng confirmation và reason\.

- Mutation thành công cập nhật detail/list và hiển thị toast\.

- Mở User từ tổ chức phải Back về đúng chi tiết tổ chức\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|PA\-D\-01|Danh sách Platform User|
|PA\-D\-02|Bộ lọc User|
|PA\-D\-03|Platform User detail — active|
|PA\-D\-04|Platform User detail — pending activation|
|PA\-D\-05|Platform User detail — suspended|
|PA\-D\-06|Gửi lại activation invitation|
|PA\-D\-07|Khởi tạo password reset|
|PA\-D\-08|Confirmation tạm ngừng|
|PA\-D\-09|Confirmation khôi phục|
|PA\-D\-10|Detail sau mutation \+ toast|

### 5\.5\.14 PA\-SG\-02 — Khởi tạo khách hàng \& Chủ sở hữu

**Purpose**

Cung cấp wizard ba bước để mời Owner (email mới hoặc Auth user hiện hữu), khởi tạo tổ chức; không tạo Platform User/Membership trước accept\.

**Entry points**

- Platform Admin App → `Tổ chức` → `Thêm tổ chức`\.

**UI contract**

- Wizard gồm ba bước: `Chủ sở hữu`, `Tổ chức`, `Kiểm tra`\.

- Bước Chủ sở hữu cho phép tìm User hiện hữu hoặc nhập thông tin User mới\.

- User mới nhập họ và tên đệm, tên, email và số điện thoại không bắt buộc\.

- User tự thiết lập mật khẩu qua activation flow\.

- Bước Tổ chức yêu cầu tên tổ chức; thông tin liên hệ, địa chỉ và pháp lý là tùy chọn\.

- Role ban đầu hiển thị read\-only là `Chủ cửa hàng`\.

- Ownership và role được hiển thị riêng tại bước Kiểm tra\.

- Error khi submit được hiển thị tại bước Kiểm tra bằng toast hoặc inline message\.

- Thành công mở chi tiết tổ chức đang provisioning và hiển thị toast\.

- Partial\-failure detail được giữ ở backend/support contract, không tạo màn riêng trong mobile MVP\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|PA\-D\-01|Bước Chủ sở hữu|
|PA\-D\-02|Bước Tổ chức|
|PA\-D\-03|Bước Kiểm tra|
|PA\-D\-04|Đang provisioning|
|PA\-D\-05|Chi tiết tổ chức provisioning \+ toast|
|PA\-D\-06|Submit error tại bước Kiểm tra|

### 5\.5\.15 PA\-SG\-03 — Quản lý tổ chức cấp nền tảng

**Purpose**

Cho Platform Admin xem tổ chức, readiness, Owner, thành viên và thực hiện privileged lifecycle/ownership operation\.

**Entry points**

- Platform Admin App → `Tổ chức`\.

- PA\-SG\-02 sau onboarding thành công\.

**UI contract**

- Danh sách hỗ trợ search và filter theo lifecycle, warning và readiness\.

- Filter mở bằng bottom sheet\.

- Provisioning detail hiển thị readiness issue trực tiếp\.

- Active detail hiển thị hồ sơ, Owner và danh sách thành viên inline\.

- Thành viên có thể mở Platform User detail tại PA\-SG\-01\.

- Active Tenant có action thay Owner và tạm ngừng\.

- Suspended Tenant có action thay Owner và khôi phục\.

- Closed Tenant là read\-only và không có restore\.

- Owner picker chỉ hiển thị active Membership cùng tổ chức\.

- Confirmation transfer nêu rõ role của Owner cũ và Owner mới không thay đổi\.

- Suspend/restore dùng confirmation, reason và step\-up khi policy yêu cầu\.

- Thành công quay về detail và hiển thị toast\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|PA\-D\-01|Danh sách tổ chức|
|PA\-D\-02|Bộ lọc tổ chức|
|PA\-D\-03|Chi tiết tổ chức provisioning|
|PA\-D\-04|Chi tiết tổ chức active \+ thành viên|
|PA\-D\-05|Chi tiết tổ chức suspended|
|PA\-D\-06|Chi tiết tổ chức closed|
|PA\-D\-07|Chọn Owner mới|
|PA\-D\-08|Confirmation thay Owner|
|PA\-D\-09|Confirmation tạm ngừng|
|PA\-D\-10|Confirmation khôi phục|
|PA\-D\-11|Detail sau mutation \+ toast|

### 5\.5\.16 PA\-SG\-04 — Nhật ký hoạt động

**Purpose**

Cho Platform Admin xem tổng quan và tra cứu privileged Audit hoặc system event cấp nền tảng\.

**Entry points**

- Platform Admin App → `Nhật ký hoạt động`\.

- Tổng quan Admin → hoạt động gần đây\.

**UI contract**

- Screen Group tập trung vào audit, không phải security management suite\.

- Không có standalone step\-up, session timeout hoặc no\-permission screen trong board này\.

- Danh sách hỗ trợ filter theo thời gian, kết quả và actor/subject type\.

- Chi tiết hiển thị action, result, event code, Audit ID, actor/type, target, thời gian, source, correlation ID và before/after\.

- Redaction được áp dụng theo Platform Audit policy\.

- Không hiển thị password, token, mã xác nhận hoặc secret\.

- No\-result, no\-permission và load\-error được hiển thị như state của list/detail\.

**Screen/state list**

|Design ID|Screen / state|
|---|---|
|PA\-D\-01|Tổng quan Admin|
|PA\-D\-02|Platform Audit list|
|PA\-D\-03|Bộ lọc Audit — bottom sheet|
|PA\-D\-04|Chi tiết privileged Audit|
|PA\-D\-05|Redacted / no result / no permission / error states|

# 6\. Appendix

## 6\.1 API contracts

### 6\.1\.1 Common API principles

- Sử dụng JSON over HTTPS và stable versioning theo platform API convention\.

- Actor phải được xác thực, trừ activation và Invitation endpoint công khai được bảo vệ bằng one\-time token, expiry và rate limit\.

- Tenant\-scoped API phải kiểm tra Platform User status, Tenant status, active Membership, Tenant permission và resource ownership\.

- Platform\-scoped API phải kiểm tra PlatformAdminContext, platform permission, target state và step\-up policy; không yêu cầu actor có Membership trong Tenant đích\.

- Identity self\-service API chỉ tác động tới authenticated Platform User và không yêu cầu TenantContext\.

- Mutation có khả năng retry hoặc tạo side effect lớn phải hỗ trợ `Idempotency-Key`\.

- Mutation trên entity có version phải nhận `expected_version`; version không khớp trả `409 STATE_CHANGED`\.

- Raw token, mã xác nhận và credential phải nằm trong request body, không đặt trong URL và không được ghi log\.

- Response lỗi sử dụng stable `code`, `message_key`, `details` và `correlation_id`; không trả stack trace\.

- Cross\-Tenant resource sử dụng non\-enumerating response khi cần tránh tiết lộ sự tồn tại\.

- API success chỉ được trả sau khi domain state và outbox/Audit intent đã commit thành công\.

### 6\.1\.2 Tenant\-scoped APIs

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

Không cung cấp API xem EffectivePermissions của một thành viên khác trong MVP UI contract\. Quyền của thành viên được giải thích thông qua role detail và permission composition\.

**Post\-MVP Tenant APIs**

|Method|Endpoint|Permission / actor|Purpose|
|---|---|---|---|
|POST|`/tenants/{tenant_id}/transfer-ownership`|Tenant Owner policy|Tenant\-facing ownership transfer|
|POST|`/tenants/{tenant_id}/close`|Tenant Owner policy|Đóng Tenant sau blocker evaluation|

### 6\.1\.3 Platform\-scoped APIs

|Method|Endpoint|Platform permission|Purpose|
|---|---|---|---|
|GET|`/platform/users`|`platform.user.view`|Tìm kiếm và liệt kê Platform User|
|POST|`/platform/users`|`platform.user.create`|Tạo pending Platform User; trong MVP chủ yếu được gọi từ onboarding orchestration|
|GET|`/platform/users/{user_id}`|`platform.user.view`|Đọc Platform User detail và identity status|
|POST|`/platform/users/{user_id}/activation-invitations`|`platform.user.activation_invite.send`|Gửi hoặc gửi lại activation invitation|
|POST|`/platform/users/{user_id}/password-reset-requests`|`platform.user.password_reset.initiate`|Khởi tạo password\-reset flow; không trả credential|
|POST|`/platform/users/{user_id}/suspend`|`platform.user.suspend`|Tạm ngừng Platform User|
|POST|`/platform/users/{user_id}/restore`|`platform.user.restore`|Khôi phục Platform User theo identity policy|
|GET|`/platform/tenants`|`platform.tenant.view`|Tìm kiếm và liệt kê Tenant|
|POST|`/platform/tenants`|`platform.tenant.create`|Tạo Tenant provisioning và Owner Invitation; Membership khi accept|
|GET|`/platform/tenants/{tenant_id}`|`platform.tenant.view`|Đọc chi tiết quản trị Tenant|
|GET|`/platform/tenants/{tenant_id}/members`|`platform.tenant.member.view`|Đọc Membership của Tenant mà không cần TenantContext|
|POST|`/platform/tenants/{tenant_id}/transfer-ownership`|`platform.tenant.owner.transfer`|Chuyển Owner ở cấp nền tảng và giữ nguyên role|
|POST|`/platform/tenants/{tenant_id}/suspend`|`platform.tenant.suspend`|Tạm ngừng Tenant|
|POST|`/platform/tenants/{tenant_id}/restore`|`platform.tenant.restore`|Khôi phục Tenant suspended|
|POST|`/platform/onboarding-operations`|`platform.tenant.create`|Khởi tạo multi\-step onboarding|
|GET|`/platform/onboarding-operations/{operation_id}`|`platform.tenant.view`|Đọc trạng thái từng bước và kết quả|
|POST|`/platform/onboarding-operations/{operation_id}/retry`|Quyền ban đầu của operation|Tiếp tục operation bị partial failure|
|GET|`/platform/audit-logs`|`platform.audit.view`|Truy vấn privileged Platform Audit|

### 6\.1\.4 Provisioning orchestration contract

**Flow**

- Resolve invitee bằng canonical email (Auth user hiện hữu hoặc email mới)\.

- Chỉ lưu Owner Invitation và trạng thái gửi; không tạo User pending hay Membership\.

- Tạo Tenant provisioning trong cùng transaction của Theme 1\.

- Lưu operation status, completed steps và correlation ID\.

- Trả `completed` hoặc `partial_failure` kèm retryable step\.

**Required behavior**

- Mỗi bước phải idempotent\.

- Bước đã hoàn tất không được lặp lại khi retry, trừ khi provider contract hỗ trợ safe replay\.

- Không xóa Platform User chỉ vì bước tạo Tenant thất bại\.

- Rollback trong Theme 1 phải bao phủ Tenant, Owner Invitation và outbox; không unwind Membership giả vì Invitation mới không pre-create\.

- Pending Owner identity không được xem là Tenant activation thành công\.

- Mobile UI chỉ cần hiển thị lỗi an toàn và correlation ID; trạng thái kỹ thuật chi tiết phục vụ support\.

### 6\.1\.5 Identity self\-service contracts

Các endpoint dưới đây là logical contract do IAM application CQRS (`identity/`) sở hữu; Auth vẫn là credential/session authority\. Physical route có thể chuẩn hóa theo convention nền tảng\.

|Method|Logical endpoint|Actor|Purpose|
|---|---|---|---|
|GET|`/identity/me`|Authenticated Platform User|Đọc hồ sơ cá nhân hiện hành|
|PATCH|`/identity/me`|Authenticated Platform User|Cập nhật avatar, họ và tên đệm, tên và số điện thoại|
|POST|`/identity/me/password-reset-requests`|Authenticated Platform User|Gửi mã xác nhận tới email đã xác minh|
|POST|`/identity/me/password-reset-requests/{operation_id}/resend`|Authenticated Platform User|Gửi lại mã theo expiry và rate\-limit policy|
|POST|`/identity/me/password-reset-requests/{operation_id}/verify`|Authenticated Platform User|Xác minh mã sáu chữ số|
|POST|`/identity/me/password-reset-requests/{operation_id}/complete`|Authenticated Platform User|Thiết lập mật khẩu mới sau khi mã được xác minh|
|POST|`/identity/me/logout`|Authenticated Platform User|Thu hồi phiên hiện hành và đăng xuất|

**Contract rules**

- Email đăng nhập không được cập nhật qua self\-service profile form hiện tại\.

- IAM lưu self\-service profile fields tại `iam.platform_user_profiles`; Auth identity fields chỉ được join/read dưới dạng snapshot an toàn cho presentation\. Theme 1 / IAM không lưu mã xác nhận, password hoặc session token\.

- Password\-reset response không trả password, password hash hoặc credential material\.

- Session hiện hành và các session khác tuân theo policy của Supabase Auth; completion chỉ expose `currentSessionRotated`/`otherSessionsRevoked`\.

- Profile và credential operation không phụ thuộc TenantContext hoặc Membership\.

## 6\.2 Event contracts

### 6\.2\.1 Theme 1 domain events

**Tenant**

- `TenantCreated`

- `TenantProfileUpdated`

- `TenantLegalProfileCreated`

- `TenantLegalProfileUpdated`

- `TenantActivated`

- `TenantOwnershipTransferred`

- `TenantSuspended`

- `TenantRestored`

- `TenantClosed` — Post\-MVP

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

- Trong MVP, `TenantOwnershipTransferred` được phát bởi privileged Platform Admin operation\.

- Ownership transfer event phải chứa Owner cũ, Owner mới và xác nhận role không bị thay đổi\.

- `TenantClosed` được giữ trong contract registry nhưng không có active MVP producer từ Tenant App\.

- Domain state và outbox record phải commit trong cùng transaction\.

### 6\.2\.2 Referenced Platform Identity events

- `PlatformUserProvisioned`

- `PlatformUserActivationInvited`

- `PlatformUserActivated`

- `PlatformUserProfileUpdated`

- `PlatformUserPasswordResetRequested`

- `PlatformUserPasswordResetCompleted`

- `PlatformUserSuspended`

- `PlatformUserRestored`

- `PlatformUserSessionRevoked`

Theme 1 không phát các event này như domain owner; chỉ consume hoặc tham chiếu theo integration contract\.

### 6\.2\.3 Orchestration signals

- `TenantOnboardingStarted`

- `TenantOnboardingStepCompleted`

- `TenantOnboardingCompleted`

- `TenantOnboardingFailed`

Orchestration signal không thay thế domain event và không được Theme nghiệp vụ sử dụng làm source of truth cho Tenant lifecycle\.

### 6\.2\.4 Product analytics events

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

Product analytics payload không được chứa password, token, mã xác nhận hoặc PII không cần thiết\.

### 6\.2\.5 Event envelope

\{

"event\_id": "evt\_uuid",

"event\_type": "TenantCreated",

"aggregate\_type": "Tenant",

"aggregate\_id": "tenant\_uuid",

"tenant\_id": "tenant\_uuid\_or\_null",

"actor\_type": "platform\_user\|tenant\_member\|platform\_operator\|system",

"actor\_user\_id": "user\_uuid\_or\_null",

"actor\_membership\_id": "membership\_uuid\_or\_null",

"correlation\_id": "correlation\_id",

"occurred\_at": "2026\-07\-12T22:30:00\+07:00",

"event\_version": 1,

"payload": \{\}

\}

- `actor_membership_id` để null đối với Platform Admin, identity self\-service và system process\.

- `tenant_id` để null đối với event thuần platform không gắn với Tenant\.

- Audit hoặc event payload phải redact token, mã xác nhận, credential và PII không cần thiết\.

## 6\.3 Permission matrix

### 6\.3\.1 Tenant permissions

Owner policy là lớp quyền quản trị Theme 1 độc lập với system role\. Mapping permission của bốn role Chủ cửa hàng, Nhân viên bán hàng, Kế toán và Thủ kho được quản lý trong Platform Authorization release manifest, không hard\-code trong tài liệu Theme 1\.

|Permission|Owner policy|Có thể cấp qua system role|MVP usage|Notes|
|---|---|---|---|---|
|`tenant.view`|Có|Có|Có|Đọc hồ sơ tổ chức|
|`tenant.profile.update`|Có|Có|Có|Cập nhật hồ sơ cơ bản|
|`tenant.legal_profile.update`|Có|Có|Có|Tạo hoặc cập nhật Legal Profile|
|`tenant.readiness.view`|Có|Có|Có|Derived read\-only|
|`tenant.activate`|Có|Không mặc định|Có|Kích hoạt Tenant provisioning|
|`tenant.member.view`|Có|Có|Có|Xem thành viên và lời mời|
|`tenant.member.invite`|Có|Có|Có|Tạo, gửi lại và thu hồi Invitation|
|`tenant.member.status.update`|Có|Có|Có|Deactivate hoặc reactivate Membership|
|`tenant.member.remove`|Có|Có|Có|Removed là terminal|
|`tenant.role.view`|Có|Có|Có|Xem system\-role catalog|
|`tenant.permission.view`|Có|Có|Có|Xem permission composition của role|
|`tenant.role.assign`|Có|Có|Có|Một role hiện hành trên mỗi Membership|
|`tenant.audit.view`|Có|Có|Có|Truy vấn Tenant Audit|

**Post\-MVP Tenant permissions**

|Permission|Purpose|
|---|---|
|`tenant.ownership.transfer`|Tenant Owner tự chuyển quyền sở hữu|
|`tenant.close`|Tenant Owner đóng tổ chức sau blocker evaluation|

**Rules**

- Role `Chủ cửa hàng` không tự động cấp ownership\.

- `is_owner = true` không tự động thay đổi `role_id`\.

- Business permission ngoài Theme 1 vẫn được lấy từ system role\.

- Sole\-Owner protection phải được enforce bất kể actor có permission quản trị\.

### 6\.3\.2 Platform permissions

|Permission|System Admin|Platform Operator|Support viewer|Notes|
|---|---|---|---|---|
|`platform.user.view`|Có|Có|Có|Áp dụng PII masking|
|`platform.user.create`|Có|Theo policy|Không|Tạo pending Platform User|
|`platform.user.activation_invite.send`|Có|Có|Không|Không đặt credential|
|`platform.user.password_reset.initiate`|Có|Theo policy|Không|Chỉ khởi tạo identity flow|
|`platform.user.suspend`|Có|Có|Không|Reason và step\-up khi policy yêu cầu|
|`platform.user.restore`|Có|Có|Không|Kiểm tra platform blocker|
|`platform.tenant.view`|Có|Có|Có|Không yêu cầu Tenant Membership|
|`platform.tenant.member.view`|Có|Có|Theo policy|Platform\-scoped Membership query|
|`platform.tenant.create`|Có|Theo policy|Không|Onboarding operation|
|`platform.tenant.owner.transfer`|Có|Theo policy|Không|Chuyển Owner, không đổi role|
|`platform.tenant.suspend`|Có|Có|Không|Reason và step\-up khi policy yêu cầu|
|`platform.tenant.restore`|Có|Có|Không|Không áp dụng cho closed Tenant|
|`platform.audit.view`|Có|Có|Theo policy|Redaction và retention policy|

Tên persona trong bảng là conceptual platform roles\. Physical storage và mapping thuộc Platform Authorization, không thuộc `tenant_memberships.role_id`\.

### 6\.3\.3 Identity self\-service authorization

|Operation|Authorization rule|TenantContext required|
|---|---|---|
|Xem hồ sơ cá nhân|Authenticated User chỉ đọc chính mình|Không|
|Cập nhật hồ sơ cá nhân|Authenticated User chỉ cập nhật chính mình|Không|
|Gửi hoặc gửi lại mã xác nhận|Authenticated User; verified email; rate\-limit policy|Không|
|Xác minh mã|Đúng operation, code còn hạn và chưa vượt attempt limit|Không|
|Đặt mật khẩu mới|Operation đã được xác minh; password đạt policy|Không|
|Đăng xuất|Authenticated session hiện hành|Không|

- Tenant role và ownership không cấp quyền sửa hồ sơ hoặc credential của Platform User khác\.

- Platform Admin credential operation phải sử dụng privileged Platform Identity contract riêng\.

## 6\.4 Error / blocked response catalog

|Code|HTTP|Meaning|UI response|
|---|---|---|---|
|`VALIDATION_ERROR`|400|Payload hoặc field không hợp lệ|Inline validation|
|`AUTHENTICATION_REQUIRED`|401|Chưa đăng nhập|Mở authentication surface|
|`SESSION_EXPIRED`|401|Phiên hết hạn|Xóa dữ liệu nhạy cảm và đăng nhập lại|
|`PERMISSION_DENIED`|403|Thiếu Tenant permission|No\-permission state|
|`PLATFORM_PERMISSION_DENIED`|403|Thiếu platform permission|Platform blocked state|
|`STEP_UP_AUTH_REQUIRED`|403|Cần re\-authentication hoặc MFA|Mở step\-up flow|
|`TENANT_ACCESS_DENIED`|403|Không có Tenant access hợp lệ|Xóa Tenant data và mở selector|
|`INVITATION_EMAIL_MISMATCH`|403|Verified email không khớp email được mời|Yêu cầu đăng nhập đúng email|
|`TENANT_NOT_FOUND`|404|Không tồn tại hoặc non\-enumerating denial|Generic not\-found state|
|`RESOURCE_NOT_FOUND`|404|Resource không tồn tại hoặc không được disclose|Quay về màn an toàn|
|`PLATFORM_USER_NOT_FOUND`|404|Platform User đích không tồn tại|Refresh hoặc tìm lại|
|`CROSS_TENANT_REFERENCE`|404|Resource thuộc Tenant khác|Non\-enumerating response|
|`STATE_CHANGED`|409|Version hoặc state đã thay đổi|Tải lại dữ liệu|
|`TENANT_STATE_INVALID`|409|Lifecycle transition không hợp lệ|Hiển thị trạng thái hiện hành|
|`TENANT_SUSPENDED`|409|Tenant bị tạm ngừng|Chặn business operation|
|`TENANT_CLOSED`|409|Tenant đã đóng|Read\-only hoặc chuyển Tenant|
|`MEMBERSHIP_INACTIVE`|409|Membership đang inactive|Chuyển Tenant hoặc liên hệ Admin|
|`MEMBERSHIP_REMOVED`|409|Membership đã bị loại|Xóa TenantContext|
|`DUPLICATE_MEMBERSHIP`|409|User đã có current Membership|Mở member/reactivate flow|
|`INVITATION_EXPIRED`|409|Invitation hết hạn|Yêu cầu lời mời mới|
|`INVITATION_REVOKED`|409|Invitation đã bị thu hồi|Đóng flow|
|`INVITATION_ALREADY_USED`|409|Invitation đã ở terminal state|Mở Tenant khi còn access|
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

Các lỗi liên quan `tenant.close` hoặc tenant\-facing ownership transfer chỉ được kích hoạt khi capability Post\-MVP được triển khai\.

## 6\.5 Glossary

|Term|Vietnamese name|Short definition|Related domain|Related entity/model|
|---|---|---|---|---|
|Tenant|Tổ chức|Ranh giới dữ liệu, quyền, cấu hình và giao dịch độc lập|D\-01|`tenants`|
|Tenant App|Ứng dụng Mosaic Retail dành cho tổ chức|Application surface dùng TenantContext cho Owner và thành viên|D\-04|TenantContext|
|Platform Admin App|Ứng dụng quản trị nền tảng|Application surface nội bộ cho privileged Mosaic Retail actor|Platform reference|PlatformAdminContext|
|Platform User|Người dùng nền tảng|Danh tính dùng chung trên toàn Mosaic Retail|Referenced|PlatformUser|
|Platform User Profile|Hồ sơ người dùng|Hồ sơ cá nhân do IAM sở hữu (`iam.platform_user_profiles`)|IAM|`iam.platform_user_profiles`|
|My Account|Tài khoản của tôi|Khu vực tự quản lý hồ sơ (IAM), mật khẩu và đăng xuất (Auth qua IAM CQRS)|IAM identity/|PlatformUser, PasswordResetOperation|
|Mosaic Retail System Admin|Quản trị viên hệ thống|Actor tạo Platform User, Tenant và thực hiện onboarding|Platform reference|Platform authorization grant|
|Platform Operator|Nhân sự vận hành nền tảng|Actor thực hiện privileged lifecycle operation|Platform reference|Platform authorization grant|
|PlatformAdminContext|Ngữ cảnh quản trị nền tảng|Context dùng platform permission và không yêu cầu Tenant Membership|D\-04 reference|Runtime model|
|PlatformOnboardingOperation|Phiên khởi tạo tổ chức|Orchestration state cho create User, Tenant và Owner|Platform reference|PlatformOnboardingOperation|
|Activation Invitation|Lời mời kích hoạt tài khoản|Identity\-owned one\-time activation flow|Platform Identity|Không phải `tenant_invitations`|
|TenantMembership|Thành viên tổ chức|Quan hệ giữa Platform User và Tenant|D\-02|`tenant_memberships`|
|TenantInvitation|Lời mời tham gia tổ chức|Email invitation tạo Membership khi được chấp nhận|D\-02|`tenant_invitations`|
|Invitation Delivery Outcome|Kết quả gửi lời mời|Trạng thái gửi email độc lập với Invitation lifecycle|Notification|NotificationDeliveryStatus|
|Owner|Chủ sở hữu|Active Membership có `is_owner = true`|D\-01, D\-02|`tenant_memberships`|
|Chủ cửa hàng|Vai trò Chủ cửa hàng|Một trong bốn system role MVP; không đồng nhất với Owner|D\-03|`role_definitions`|
|Legal Profile|Hồ sơ pháp lý|Current legal identity của Tenant|D\-01|`tenant_legal_profiles`|
|System Role|Vai trò hệ thống|Role dùng chung toàn nền tảng và được gán cho Membership|D\-03|`role_definitions`|
|Permission|Quyền|Khả năng thực hiện một action|D\-03|`permission_definitions`|
|EffectivePermissions|Quyền hiệu lực|Derived set từ role, ownership và policy|D\-03, D\-04|Derived model|
|TenantContext|Ngữ cảnh tổ chức|Tenant hiện hành trong Tenant App|D\-04|Runtime model|
|LastSelectedTenant|Tổ chức được chọn gần nhất|User preference và không phải access grant|D\-04 reference|Preference model|
|TenantReadiness|Mức độ sẵn sàng|Derived blocker và warning cho activation|D\-01|Derived model|
|PasswordResetOperation|Phiên đặt lại mật khẩu|IAM metadata \+ Auth OTP/password; không lưu raw code|IAM \+ Supabase Auth|`iam.password_reset_operations`|
|Store|Điểm bán|Địa điểm bán hàng, không phải Tenant|External|Store capability|
|Warehouse|Kho|Địa điểm quản lý tồn kho, không phải Tenant|Theme 7|Warehouse entity|
|AA|Activation Action|Product usage signal|Product analytics|—|
|CAA|Core Activation Action|Core real\-use signal|Product analytics|—|

## 6\.6 Open questions

|ID|Question|Owner|Status|Notes|
|---|---|---|---|---|
|OQ\-01|Exact Platform User lifecycle code và self\-registration policy ngoài activation invitation là gì?|Platform Identity|Open|Theme 1 chỉ phụ thuộc contract tối thiểu|
|OQ\-02|PlatformOnboardingOperation được persistence tại service nào và retention trong bao lâu?|Architecture|Open|Cần cho retry và support; không thuộc Tenant aggregate|
|OQ\-03|Những privileged action nào bắt buộc step\-up authentication?|Security / Product|Open|Tối thiểu cần đánh giá suspend, restore, ownership transfer và credential operation|
|OQ\-04|Platform permission và Tenant permission dùng chung physical catalog hay bounded storage riêng?|Architecture|Open|Không được gán platform permission qua Membership role|
|OQ\-05|Tenant Audit UI được xem những platform\-operator action nào và áp dụng redaction ở mức nào?|Security / Product|**Closed (2026-07-29)**|S13/S16 hiển thị IAM-owned events từ `iam.audit_logs`; redaction áp dụng trước persist.|
|OQ\-06|Legal Profile có cần versioning riêng ngoài current state và Audit hay không?|Product / Accounting|Open|Cần phối hợp Theme 8–9|
|OQ\-07|Khi LastSelectedTenant không còn hợp lệ nhưng User có nhiều Tenant accessible, hệ thống mở selector hay chọn deterministic fallback?|Product / UX|Open|Initial bootstrap chưa có MVP visual coverage|
|OQ\-08|Notification cung cấp delivery outcome cho Tenant Invitation qua synchronous query hay event projection?|Architecture / Notification|Open|Invitation lifecycle không phụ thuộc delivery outcome|
|OQ\-09|Sau khi đặt lại mật khẩu trong phiên đã xác thực, phiên hiện hành và các phiên khác được giữ hoặc thu hồi theo policy nào?|Security / Supabase Auth|**Closed (2026-07-29)**|Complete trả `currentSessionRotated=true`, `otherSessionsRevoked=true`; session hiện hành tiếp tục hợp lệ sau rotate.|
|OQ\-10|Avatar được lưu tại Platform Identity hay shared media capability và áp dụng giới hạn file nào?|Architecture / Platform Identity|Open|Theme 1 chỉ giữ asset reference|
