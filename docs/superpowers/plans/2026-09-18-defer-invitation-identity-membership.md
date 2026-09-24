# Kế hoạch triển khai: Tách Invitation, Platform User và Membership đến khi chấp nhận lời mời

> **Dành cho agent triển khai:** BẮT BUỘC dùng skill `superpowers:subagent-driven-development` (khuyến nghị) hoặc `superpowers:executing-plans` để thực hiện lần lượt từng task. Dùng ô đánh dấu `- [ ]` để theo dõi tiến độ.

**Mục tiêu:** Giữ Invitation, Platform User và Membership tách biệt cho đến khi người nhận chấp nhận lời mời; cập nhật readiness, giao diện Admin/Tenant, luồng gửi lại lời mời Owner và hợp đồng QA của Theme 1 theo vòng đời mới.

**Kiến trúc:** Giữ nguyên chữ ký command/gateway/RPC hiện có và chuyển việc tạo Membership sang `iam.accept_invitation`. Khi gửi lời mời chỉ lưu Invitation, trạng thái gửi email, audit và idempotency; riêng onboarding vẫn tạo Tenant và các dữ liệu nền tảng theo hợp đồng hiện hành. Projection Tenant trong Admin hiển thị trạng thái Owner Invitation mới nhất nhưng không tính đó là thành viên. Readiness phân biệt đang chờ và lời mời hết hạn/không còn hợp lệ; cả hai đều chặn kích hoạt. Admin quản lý lời mời Owner, Tenant App quản lý lời mời thành viên thông thường. Giữ đường tương thích cho `target_membership_id` lịch sử. **SQL:** sửa in-place các migration timestamp đang sở hữu RPC (theo `REGISTRY.yaml`); không tạo `_drafts/` mới. Người dùng sẽ `supabase db reset` để áp dụng — ngoại lệ có chủ đích so với quy ước agent thường chỉ viết draft.

**Công nghệ:** Dart 3, Flutter, CQRS qua `IIamModule`, Supabase/PostgreSQL PL/pgSQL, `package:test`, `flutter_test`, Melos, GitNexus.

**Đặc tả:** `docs/superpowers/specs/2026-09-18-defer-invitation-identity-membership-design.md`

## Ràng buộc chung

- Đọc `AGENTS.md`, `.cursor/rules/vet45-architecture.mdc`, `docs/harness/PROGRESS.md` và `docs/themes/TH-01-organization-users/harness/00-agent-ritual.md` trước khi triển khai.
- Chạy GitNexus `impact --direction upstream` trước khi sửa từng function/class/method được nêu tên. Nếu `risk: UNKNOWN`, dùng `rg` xác nhận nơi gọi; nếu HIGH/CRITICAL, báo người dùng trước khi sửa.
- **SQL in-place (đã chốt):** sửa trực tiếp các migration timestamp sở hữu RPC trong `supabase/migrations/` theo bảng map bên dưới. Không tạo tệp mới trong `_drafts/` cho slice này. `REGISTRY.yaml` giữ nguyên owner hiện tại (chỉ đổi body RPC trong đúng file owner). Người dùng sẽ reset DB local để áp dụng; không tạo migration patch/promote mới.
- Map owner RPC (REGISTRY, không đổi file owner):

| RPC | File migration sửa in-place |
| --- | --- |
| `iam.create_tenant_onboarding` | `20260916004_iam_patch_onboarding_default_store_scope.sql` |
| `iam.create_tenant_invitation` | `20260916005_iam_patch_invitation_membership_store_scope.sql` |
| `iam.accept_invitation` | `20260916006_iam_patch_accept_invitation_default_store_scope.sql` |
| `iam.reinvite_provisioning_owner` | `20260911006_iam_reinvite_provisioning_owner.sql` |
| `iam.get_platform_tenant` | `20260911003_iam_get_platform_tenant_owner_from_invitation.sql` |
| `iam.search_platform_tenants` | `20260811010_iam_platform_tenants_read.sql` |
| `iam.search_platform_users` / `iam.get_platform_user` | `20260911002_iam_patch_search_phone_status_casts.sql` |
| `iam.get_tenant_readiness` | `20260811016_iam_tenant_readiness_activate.sql` |

- Kiểm chứng SQL bằng SQL contract tests đọc body từ đúng file migration trên; sau khi code xanh, người dùng `supabase db reset` (hoặc stack local tương đương) để xác nhận runtime. Không dùng `_drafts/` làm trung gian.
- Giữ nguyên chữ ký tham số command, gateway, RPC và kiểu của các trường DTO hiện có. Có thể thêm metadata Invitation chỉ đọc, nullable vào `PlatformTenantDetailDto`; `TenantOnboardingResultDto.ownerMembershipId` và `ownerUserId` tiếp tục nullable.
- Gửi lời mời không được insert/kích hoạt lại `iam.memberships`, insert `iam.platform_user_profiles` hoặc tự tạo UUID người dùng giả.
- Trong phạm vi này, chỉ IAM RPC `iam.accept_invitation` được upsert profile của người được mời và tạo/liên kết Membership đã chấp nhận.
- Giữ `tenant_invitations.target_membership_id`, `_unwind_staff_precreate_membership` và `_unwind_provisioning_owner_membership` cho dữ liệu hybrid lịch sử; không xóa trong thay đổi này.
- Giữ nguyên idempotency scope, payload hash, ranh giới transaction, bí mật token lời mời, luồng email delivery outbox/internal command, audit, grants và khai báo `search_path` của security-definer.
- Tenant `provisioning` có thể chưa có Owner Membership trước khi accept. Nếu có đúng 0 active Owner và Owner Invitation pending còn hiệu lực, readiness trả `OWNER_ACCEPTANCE_PENDING`; nếu không còn lời mời hợp lệ, trả `OWNER_INVITATION_EXPIRED` / “Lời mời hết hạn”. Cả hai đều chặn kích hoạt. Giữ `OWNER_MEMBERSHIP_INVALID` cho nhiều active Owner hoặc trạng thái Owner sai ở Tenant `active`/`suspended`.
- Mỗi thao tác `iam.reinvite_provisioning_owner` mới phải **reuse** Owner Invitation mới nhất (`pending` hoặc `expired`): giữ cùng `invitation_id`/`created_at`, tên, SĐT, vai trò ban đầu và metadata người được mời; chỉ cập nhật email cùng các trường bảo mật/delivery của lần gửi — **không** expire-all rồi insert row thay thế. Invitation `accepted`/`declined`/`revoked` bị từ chối. Replay cùng idempotency key chỉ trả kết quả cũ, không xoay token/gửi email thêm.
- PA-SG-02 giữ nút “Thao tác” hiện có và chỉ triển khai hai bottom sheet khi Owner Invitation hiệu lực là `pending`/`expired`: sheet “Thao tác” có mục “Gửi lại email”, tiếp đó là “Gửi lại email thiết lập?” cho phép giữ hoặc đổi email; “Tạm ngừng tổ chức” vẫn ẩn như hiện tại. Không mở sheet rỗng nếu không còn thao tác hợp lệ. Khi Tenant đã `active`/`suspended`, không hiện “Gửi lại email”; giữ thao tác hiện tại. Không sửa banner/nền trang, không thêm thao tác khôi phục tại màn hình readiness; màn hình đó chỉ hiển thị “Lời mời hết hạn”.
- Platform Admin App chỉ quản lý Owner Invitation giai đoạn provisioning; Tenant App quản lý tạo/gửi lại/thu hồi lời mời thành viên thông thường. Invitation pending không xuất hiện trong danh sách Platform User hoặc thành viên.
- Giữ nguyên các thay đổi không liên quan đang có trong worktree. Đặc biệt, xem diff hiện tại trước khi sửa `apps/admin/lib/features/organizations/presentation/pages/platform_onboarding_page.dart` hoặc widget Organization dùng chung giữa Admin/Tenant.
- Làm theo TDD: thêm test tập trung và thấy test fail đúng lý do, triển khai thay đổi nhỏ nhất, chạy lại test trước mỗi commit.

## Trọng tâm rà soát

- Owner chưa có Membership: Invitation pending hợp lệ thì hiển thị đang chờ, Invitation hết hạn/không còn hợp lệ thì hiển thị “Lời mời hết hạn”; cả hai chặn kích hoạt, không báo lỗi Owner Membership hỏng hoặc thêm thao tác khôi phục trên readiness (Task 6).
- Gửi lại cùng email hoặc đổi email: reuse cùng invitation row, giữ nguyên tên/SĐT và metadata người được mời, token cũ mất hiệu lực, `invitation_id` giữ nguyên; retry idempotent không xoay token lần hai (Task 3 và 7).
- Bản ghi profile placeholder lịch sử không có Auth user phải biến mất khỏi tìm kiếm/chi tiết Platform User; Auth user thật đã tồn tại vẫn hiển thị (Task 5).
- Với Tenant `settingUp` và Invitation `pending`/`expired`, sheet “Thao tác” chỉ có “Gửi lại email”; “Tạm ngừng tổ chức” vẫn ẩn và sheet nhập email phải điền sẵn đúng địa chỉ mới nhất. Không mở sheet rỗng. Với `active`/`suspended`, không có “Gửi lại email” và vẫn có thao tác đổi chủ sở hữu theo hiện trạng (Task 7).
- Invitation thành viên pending không được nằm trong danh sách thành viên; Admin không được lộ các thao tác lời mời thành viên của Tenant App (Task 8).

---

## Danh sách tệp

### Tạo mới

- `modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart` — khóa hành vi không pre-create và chỉ tạo dữ liệu thật khi accept (đọc body từ bốn migration write).
- `modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart` — khóa thứ tự ưu tiên Owner đã accept rồi mới fallback về Invitation pending.
- `modules/iam/infrastructure/test/iam_platform_user_invitation_visibility_sql_contract_test.dart` — khóa bộ lọc theo nguồn dữ liệu Platform User thật.
- `modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart` — khóa các trường hợp readiness/kích hoạt.
- `apps/admin/lib/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart` — bottom sheet nhập email Owner được điền sẵn, kiểm tra hợp lệ và gửi lại/thay thế.
- `apps/admin/test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart` — kiểm tra nội dung sheet, prefill, validation, Hủy/Gửi và trạng thái submit.

### Sửa (SQL — in-place migration timestamp)

- `supabase/migrations/20260916005_iam_patch_invitation_membership_store_scope.sql` — `iam.create_tenant_invitation`: không pre-create profile/Membership.
- `supabase/migrations/20260916004_iam_patch_onboarding_default_store_scope.sql` — `iam.create_tenant_onboarding`: chỉ Invitation Owner; `owner_membership_id` null.
- `supabase/migrations/20260911006_iam_reinvite_provisioning_owner.sql` — `iam.reinvite_provisioning_owner`: reuse cùng Owner Invitation pending/expired; không materialize.
- `supabase/migrations/20260916006_iam_patch_accept_invitation_default_store_scope.sql` — `iam.accept_invitation`: upsert profile thật rồi Membership rồi consume.
- `supabase/migrations/20260911003_iam_get_platform_tenant_owner_from_invitation.sql` — `iam.get_platform_tenant`: ưu tiên Owner đã accept; metadata `owner_invitation_*`.
- `supabase/migrations/20260811010_iam_platform_tenants_read.sql` — `iam.search_platform_tenants`: cùng fallback Owner pending; member count chỉ Membership.
- `supabase/migrations/20260911002_iam_patch_search_phone_status_casts.sql` — `iam.search_platform_users` / `iam.get_platform_user`: gốc `auth.users`, ẩn placeholder không Auth.
- `supabase/migrations/20260811016_iam_tenant_readiness_activate.sql` — `iam.get_tenant_readiness`: `OWNER_ACCEPTANCE_PENDING` / `OWNER_INVITATION_EXPIRED`.

### Sửa (Dart / docs)

- `modules/iam/application/lib/src/platform/shared/tenant_onboarding_result_dto.dart` — ghi rõ Owner ID nullable là kết quả bình thường trước khi accept.
- `modules/iam/application/lib/src/platform/shared/onboarding_owner_input.dart` — bỏ mô tả cũ cho rằng chọn email mới sẽ tạo Platform User pending.
- `modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_handler.dart` — chỉ sửa comment hybrid/pre-create đã lỗi thời, không đổi đầu vào handler.
- `modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command.dart` — mô tả lại việc thay Owner bằng Invitation.
- `modules/iam/application/lib/src/testing/fake_iam_module.dart` — mô phỏng Owner pending mà không dựng profile/Membership giả.
- `modules/iam/application/test/fake_iam_module_test.dart` — kiểm tra Owner ID nullable và projection thành viên rỗng trước khi accept.
- `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart` — cập nhật kỳ vọng hợp đồng onboarding.
- `modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart` — chứng minh gateway đọc Owner ID nullable mà không lỗi cast.
- `modules/iam/application/lib/src/shared/tenant_readiness_issue_codes.dart` — thêm mã blocker đang chờ/hết hạn.
- `modules/iam/application/lib/src/platform/queries/get_platform_tenant/platform_tenant_detail_dto.dart` — thêm dữ liệu Owner Invitation mới nhất cho Admin UI.
- `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart` — map các trường Owner Invitation chỉ đọc.
- `apps/admin/lib/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart` — gửi `ReinviteProvisioningOwnerCommand` và tải lại chi tiết.
- `apps/admin/lib/features/organizations/presentation/mappers/platform_tenant_ui_mapper.dart` và `apps/admin/lib/features/iam/presentation/organizations/models/organization_ui_model.dart` — tách trạng thái Invitation khỏi trạng thái thành viên.
- `apps/admin/lib/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart` và `views/organization_detail_page.dart` — hai bottom sheet và dây nối PA-SG-02; giữ nguyên banner và thanh “Thao tác” hiện có.
- `apps/admin/lib/features/users/presentation/pages/platform_users_page.dart`, `widgets/platform_users_filter_sheet.dart` và `pages/platform_user_detail_page.dart` — thay đổi PA-D-01/PA-D-03/PA-O-02.
- `apps/admin/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart` và `apps/erp/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart` — nhãn đang chờ/hết hạn, không thêm route khôi phục.
- `apps/admin/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart`, `apps/erp/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart` và `apps/erp/lib/features/more/presentation/bloc/iam_feature_access_state.dart` — phân loại nhất quán các Owner blocker mới.
- `apps/admin/lib/features/iam/presentation/users/views/organization_users_page.dart` và các widget thành phần — bỏ quản lý lời mời thành viên thông thường ở Admin, giữ màn hình đọc danh sách thành viên.
- `docs/themes/TH-01-organization-users/Theme-1-organization-users.md` — sửa hợp đồng vòng đời: tạo identity/Membership khi accept, không phải khi gửi.
- `docs/themes/TH-01-organization-users/harness/06-harness-notes.md` — ghi quyết định thay thế hợp đồng cũ.
- `docs/themes/TH-01-organization-users/harness/05-traceability.md` và `08-fe-evidence.md` — ghi kỳ vọng QA mới mà không nhận phần chưa kiểm chứng là đã hoàn tất.
- `docs/themes/TH-01-organization-users/harness/07-api-contracts.md` — cập nhật side effects/hợp đồng S7, S8 và S15.

### Giữ nguyên

- ERP `OrganizationInviteMemberCubit`, `CreateInvitationCommand` và interface gateway; Tenant App vẫn có UI lời mời thành viên.
- `supabase/migrations/REGISTRY.yaml` (owner RPC không đổi vì sửa in-place đúng file hiện tại).
- Không tạo tệp `_drafts/` mới cho slice này.
- `OWNER_MEMBERSHIP_INVALID` cho Tenant active/suspended hoặc nhiều active Owner; không dùng mã này chỉ vì Owner của Tenant provisioning đang chờ accept.

---

### Task 1: Khóa vòng đời trì hoãn tạo identity/Membership trong tài liệu TH-01

**Tệp:**
- Sửa: `docs/themes/TH-01-organization-users/Theme-1-organization-users.md`
- Sửa: `docs/themes/TH-01-organization-users/harness/05-traceability.md`
- Sửa: `docs/themes/TH-01-organization-users/harness/06-harness-notes.md`
- Sửa: `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`
- Sửa: `docs/themes/TH-01-organization-users/harness/08-fe-evidence.md`

**Đầu vào/đầu ra:**
- Đầu vào: thiết kế đã duyệt tại `docs/superpowers/specs/2026-09-18-defer-invitation-identity-membership-design.md`.
- Đầu ra: quy tắc vòng đời chuẩn cho các task code và SQL sau đó.

- [ ] **Bước 1: Cập nhật side effects của S7**

Trong `harness/07-api-contracts.md`, thay danh sách side effects của S7 bằng đúng hợp đồng sau:

```markdown
### Side effects (cùng transaction)

1. Lưu Invitation: status `pending`, chỉ có `token_hash = SHA-256(token)` (không lưu token thô trong cột).
2. Tạo mã/token lời mời opaque.
3. §S-NOTIFY `enqueue_outbox_message` với template `tenant_invitation`; token thô chỉ đi qua `secret_payload_ciphertext` tùy chọn — không đưa vào `refs` / audit / logs.
4. Kết quả gửi ban đầu `queued` qua `record_email_delivery_outcome`; response có `deliveryStatus=queued` và `deliveryCorrelationId`.
5. **Không** tạo/kích hoạt lại `iam.memberships`, **không** tạo `iam.platform_user_profiles`, giữ `target_membership_id = null` cho lời mời mới. Kiểm tra xung đột Membership chỉ được đọc dữ liệu để validate.
```

- [ ] **Bước 2: Cập nhật hợp đồng accept S8 và onboarding S15**

Thêm quy tắc S8 đã chốt:

```markdown
- Accept là ranh giới tạo dữ liệu thật: sau khi xác minh email, `iam.accept_invitation` upsert bản ghi `platform_user_profiles` thật và tạo/liên kết đúng một active Membership trong cùng transaction tiêu thụ Invitation.
- Invitation lịch sử có `target_membership_id` khác null vẫn đi qua nhánh tương thích link/unwind; Invitation mới không ghi trường này.
```

Thay đoạn mô tả hybrid trong S15 bằng:

```markdown
**Ràng buộc triển khai (trì hoãn tạo dữ liệu Owner):** Onboarding tạo Tenant ở `provisioning` và một Owner Invitation trong `tenant_invitations` (`is_owner=true`), nhưng **không** tạo Owner Membership hoặc bản ghi giả trong `platform_user_profiles`. `owner_membership_id=null`; Owner mới có `owner_user_id=null` cho đến khi chấp nhận lời mời. `iam.accept_invitation` upsert profile thật theo Auth user và tạo Membership `store_owner`/`is_owner=true` trong cùng transaction chuyển Invitation sang `accepted`. Màn hình chi tiết/tìm kiếm Tenant trên Admin hiển thị Owner pending từ Invitation khi chưa có Owner Membership; danh sách thành viên vẫn rỗng. Readiness hiển thị “Đang chờ chủ sở hữu chấp nhận lời mời” nếu pending còn hiệu lực; hiển thị “Lời mời hết hạn” nếu không còn pending hợp lệ; cả hai đều chưa thể kích hoạt Tenant. Từ chối/đánh hết hạn/thu hồi Invitation mới không cần tháo gỡ dữ liệu Owner tạo sẵn, nhưng vẫn giữ helper cũ cho bản ghi hybrid lịch sử. Mỗi request mới tới `iam.reinvite_provisioning_owner` **reuse** Owner Invitation `pending`/`expired` (cùng `invitation_id`, xoay token, gia hạn, cập nhật email) — không expire+insert thay thế; Invitation terminal bị từ chối; replay idempotency chỉ trả kết quả cũ. PA-SG-02 giữ nút “Thao tác”: với Tenant `settingUp` và Invitation `pending`/`expired`, sheet chỉ có “Gửi lại email” và mở sheet “Gửi lại email thiết lập?”; không mở sheet rỗng. “Tạm ngừng tổ chức” vẫn ẩn. Với `active`/`suspended`, không hiện gửi lại email, giữ “Thay đổi chủ sở hữu”; không sửa banner/nền trang và không thêm nút riêng trên màn hình readiness.
```

- [ ] **Bước 3: Cập nhật mô tả nghiệp vụ chuẩn của Theme**

Thay các đoạn nói rằng gửi Invitation tạo Platform User `pending_activation` hoặc Membership tham chiếu người dùng giả đang chờ. Đồng thời cập nhật hợp đồng màn hình PA-D-01, PA-D-03, PA-O-02, PA-SG-02 và TA-D-01 theo tài liệu Theme 1 người dùng gửi, với các câu sau:

```markdown
- Gửi lời mời chỉ lưu Invitation và trạng thái gửi. Người được mời bằng email mới chưa trở thành Platform User và chưa có Tenant Membership trước khi accept.
- Accept Invitation hợp lệ bằng Auth identity đã xác minh email sẽ upsert Platform User profile thật và tạo active Tenant Membership trong cùng transaction tiêu thụ Invitation.
- PA-D-01 loại người chỉ có Invitation và bỏ filter “Chờ kích hoạt”; PA-D-03 hiển thị email ngay dưới tên; bỏ các thao tác người dùng pending của PA-O-02.
- PA-SG-02 quản lý Owner Invitation tại Platform Admin → Tổ chức: giữ nút “Thao tác” hiện có; ở Tenant `settingUp` với Invitation `pending`/`expired`, sheet chỉ có “Gửi lại email” (không có “Tạm ngừng tổ chức”), mở sheet “Gửi lại email thiết lập?”; reuse cùng invitation khi gửi lại/đổi email. Không mở sheet rỗng nếu không còn thao tác hợp lệ. Khi Tenant đã `active` hoặc `suspended`, không hiện gửi lại email, giữ “Thay đổi chủ sở hữu” và các thao tác hiện tại. Không sửa banner/nền trang trong slice UI này.
- TA-D-01 chỉ liệt kê Membership thật. Invitation thành viên pending nằm ở Tenant App → Lời mời; Platform Admin không quản lý loại lời mời này.
- Readiness của Owner phân biệt đang chờ và hết hạn trước khi accept, cả hai có `canActivate=false`; trạng thái hết hạn trên readiness không có thao tác khôi phục.
```

- [ ] **Bước 4: Ghi quyết định thay thế và ma trận QA vào harness**

Thêm dòng sau vào nhật ký quyết định của harness:

```markdown
| 2026-09-21 | Luồng Invitation hybrid tạo sẵn profile và Membership trước khi người nhận đồng ý | Thay bằng luồng tạo dữ liệu khi accept: gửi lời mời tenant/staff và platform-owner chỉ tạo Invitation cùng trạng thái gửi; `accept_invitation` tạo/upsert profile và Membership thật. Projection Owner pending lấy từ `tenant_invitations`; vẫn tương thích bản ghi lịch sử có `target_membership_id`. |
```

Trong `05-traceability.md`, thêm mục cập nhật Theme 1, liệt kê kỳ vọng kiểm thử bên dưới, task phụ trách và tệp test dự kiến. Trong `08-fe-evidence.md`, chú thích rằng kỳ vọng mới của S6/S9/S11/S15 đang chờ kiểm chứng; không dùng trạng thái `done` cũ để nhận hành vi mới đã đạt. Ma trận QA phải bao gồm:

| Tình huống | Kết quả mong đợi sau thay đổi | Task | Tệp test dự kiến |
| --- | --- | --- | --- |
| Onboarding Owner bằng email mới | Tenant provisioning + Owner Invitation pending; chưa có profile/Membership của Owner | 2–3 | `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart` |
| Platform User chờ kích hoạt | Email chỉ có Invitation không xuất hiện ở PA-D-01/PA-D-03; không còn filter pending hoặc action PA-O-02 | 5 | `apps/admin/test/features/users/presentation/pages/platform_users_page_test.dart` |
| Readiness giai đoạn provisioning | Invitation Owner pending hợp lệ → đang chờ; không còn Invitation hợp lệ → “Lời mời hết hạn”; cả hai chặn kích hoạt | 6 | `modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart` |
| Danh sách/chi tiết Platform User | Auth user thật vẫn hiển thị; email nằm ngay dưới tên | 5 | `apps/admin/test/features/users/presentation/pages/platform_user_detail_page_test.dart` |
| Owner Invitation | Chi tiết Tenant trên Admin hiển thị Owner pending nhưng không tăng member count | 4, 7 | `modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart` |
| REI-04 — Đổi email trên cùng invitation | Giữ nguyên tên và số điện thoại; chỉ thay email và các trường bảo mật/delivery của lần gửi. Reuse cùng `invitation_id`, token cũ vô hiệu, không tạo profile/Membership trước accept | 3, 7 | `modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart` |
| Hai bottom sheet PA-SG-02 | Tenant `settingUp` + Invitation `pending`/`expired`: “Thao tác” chỉ có “Gửi lại email”, “Tạm ngừng tổ chức” ẩn; sheet nhập email điền sẵn và cho phép sửa. Không mở sheet rỗng. Tenant `active`/`suspended`: không có “Gửi lại email”, vẫn có “Thay đổi chủ sở hữu” | 7 | `apps/admin/test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart`, `apps/admin/test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart` |
| Invitation thành viên | Lời mời pending chỉ ở khu vực Lời mời của Tenant App, không vào member list hay thao tác Invitation của Platform Admin | 3, 8 | `apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart` |
| Chấp nhận lời mời | Người nhận có email Auth đã xác minh được tạo profile thật + đúng một active Membership trong một transaction | 3, 8 | `apps/erp/test/features/invitations/e2e_e03_u01_u06_test.dart` |

- [ ] **Bước 5: Chạy kiểm tra tài liệu**

Chạy:

```bash
bash scripts/ci/guard_docs_reference.sh
bash scripts/ci/guard_theme_structure.sh
git diff --check
```

Kỳ vọng: cả ba lệnh exit `0`; tài liệu TH-01 không còn mô tả việc tạo ngay profile/Membership khi gửi như hợp đồng hiện hành.

- [ ] **Bước 6: Commit thay đổi hợp đồng tài liệu**

```bash
git add docs/themes/TH-01-organization-users/Theme-1-organization-users.md docs/themes/TH-01-organization-users/harness/05-traceability.md docs/themes/TH-01-organization-users/harness/06-harness-notes.md docs/themes/TH-01-organization-users/harness/07-api-contracts.md docs/themes/TH-01-organization-users/harness/08-fe-evidence.md
git commit -m "docs(iam): defer invitation identity and membership"
```

---

### Task 2: Để hợp đồng Dart và fake biểu diễn Invitation pending, không phải thành viên

**Tệp:**
- Sửa: `modules/iam/application/lib/src/platform/shared/tenant_onboarding_result_dto.dart`
- Sửa: `modules/iam/application/lib/src/platform/shared/onboarding_owner_input.dart`
- Sửa: `modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_handler.dart`
- Sửa: `modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command.dart`
- Sửa: `modules/iam/application/lib/src/testing/fake_iam_module.dart`
- Sửa: `modules/iam/application/test/fake_iam_module_test.dart`
- Sửa: `modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`
- Sửa: `modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart`

**Đầu vào/đầu ra:**
- Đầu vào: constructor `TenantOnboardingResultDto` không đổi và các trường nullable `ownerMembershipId`/`ownerUserId`.
- Đầu ra: fake/gateway trả cả hai ID là `null` cho Owner mới; Owner đã có Auth user chỉ giữ `ownerUserId` sẵn có; `members` chưa có Owner trước khi accept.

- [ ] **Bước 1: Phân tích tác động trước khi sửa symbol Dart**

```bash
node .gitnexus/run.cjs impact "TenantOnboardingResultDto" --direction upstream --repo .
node .gitnexus/run.cjs impact "OnboardingOwnerInput" --direction upstream --repo .
node .gitnexus/run.cjs impact "FakeIamModule" --direction upstream --repo .
node .gitnexus/run.cjs impact "CreateTenantOnboardingCommandHandler" --direction upstream --repo .
```

Kỳ vọng: ghi lại mức rủi ro. Nếu kết quả là `UNKNOWN`, xác nhận các nơi sử dụng bằng:

```bash
rg -n "TenantOnboardingResultDto|ownerMembershipId|_handleOnboarding|_handleReinviteProvisioningOwner" apps modules/iam
```

- [ ] **Bước 2: Viết application tests sẽ fail theo hành vi cũ**

Thêm các assertion sau vào `fake_iam_module_test.dart`:

```dart
test('onboarding_new_user_ok defers owner profile and membership', () async {
  final module = FakeIamModule(
    scenario: FakeIamScenario.onboardingNewUserOk,
  );

  final result = await module.executeCommandAsync<TenantOnboardingResultDto>(
    CreateTenantOnboardingCommand(
      owner: const OnboardingOwnerInput.newUser(
        lastName: 'Nguyễn',
        firstName: 'A',
        email: 'a@example.com',
      ),
      organizationName: 'Org Mới',
      idempotencyKey: 'key-new-deferred',
    ),
  );
  final detail = await module.executeQueryAsync<PlatformTenantDetailDto>(
    GetPlatformTenantQuery(tenantId: result.tenantId),
  );

  expect(result.ownerMembershipId, isNull);
  expect(result.ownerUserId, isNull);
  expect(detail.ownerUserId, isNull);
  expect(detail.ownerEmail, 'a@example.com');
  expect(detail.members, isEmpty);
});
```

Trong test `new owner issues activation without pre-provisioning identity` của `scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart`, đổi assertion thành:

```dart
expect(result.activationIssued, isTrue);
expect(result.ownerMembershipId, isNull);
expect(result.ownerUserId, isNull);
```

Đổi fixture kết quả của gateway test: Owner mới có hai ID null; mọi Owner đều có Membership ID null trước khi accept.

- [ ] **Bước 3: Chạy test tập trung và xác nhận hành vi hybrid cũ làm test fail**

Chạy:

```bash
(cd modules/iam/application && dart test test/fake_iam_module_test.dart test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart)
```

Kỳ vọng: FAIL vì `FakeIamModule` vẫn trả `mem-new-1`/`owner-pending-1` và đưa Owner vào danh sách thành viên giả của Tenant.

- [ ] **Bước 4: Sửa comment của DTO/command, không đổi chữ ký**

Dùng các comment sau:

```dart
/// Kết quả tạo Tenant cùng Owner Invitation.
///
/// Trước khi accept Invitation, [ownerMembershipId] là null. [ownerUserId] là
/// null với người được mời mới hoặc là ID Auth user đã có; onboarding không
/// tạo profile hay Membership cho người được mời.
```

```dart
/// Mời email mới làm Owner đầu tiên của Tenant (không cần mật khẩu).
/// Chỉ tạo Platform User và Owner Membership sau khi chấp nhận lời mời.
```

Dùng đoạn này cho comment của constructor `OnboardingOwnerInput.newUser`, thay câu cũ “Create a pending Platform User”.

```dart
/// Tạo Tenant provisioning và đưa Owner Invitation vào hàng đợi gửi.
/// Chỉ tạo profile và Membership của Owner khi chấp nhận lời mời.
```

- [ ] **Bước 5: Sửa fake onboarding và gửi lại lời mời theo vòng đời mới**

Tạo kết quả onboarding theo mẫu:

```dart
final result = TenantOnboardingResultDto(
  tenantId: isNewUserScenario ? 'tenant-new-1' : 'tenant-exist-1',
  ownerMembershipId: null,
  ownerUserId: isNewUserScenario
      ? null
      : (command.owner.existingUserId ?? 'lan-le'),
  tenantStatus: 'provisioning',
  correlationId: command.correlationId ??
      (isNewUserScenario ? 'corr-new-1' : 'corr-exist-1'),
  isNewUser: isNewUserScenario,
  activationIssued: true,
);
```

Tạo projection Tenant pending mà không có Membership giả:

```dart
PlatformTenantDetailDto(
  tenantId: result.tenantId,
  name: command.organizationName.trim(),
  code: 'TEN-NEW',
  status: TenantLifecycleStatus.provisioning,
  createdAt: DateTime(2026, 8, 3, 9),
  ownerUserId: result.ownerUserId,
  ownerName: resolvedOwnerName,
  ownerEmail: ownerEmail,
  unverifiedEmail: true,
  members: const <PlatformTenantMemberDto>[],
)
```

Áp dụng cùng quy tắc trong `_handleReinviteProvisioningOwner`: `ownerMembershipId: null`, `ownerUserId: null` cho Owner mới, `members: const []`; vẫn giữ tên/email Owner trong projection từ Invitation.

- [ ] **Bước 6: Khóa cách gateway map ID nullable**

Trong `supabase_platform_admin_gateway_onboarding_test.dart`, cho RPC giả trả:

```dart
return {
  'tenant_id': 'tenant-1',
  'owner_membership_id': null,
  'owner_user_id': null,
  'tenant_status': 'provisioning',
  'correlation_id': 'corr-1',
  'is_new_user': true,
  'activation_issued': true,
};
```

Sau đó assert `result.ownerMembershipId` và `result.ownerUserId` đều null. Không cần sửa gateway production vì hai trường đã được decode bằng `as String?`.

- [ ] **Bước 7: Chạy test application, gateway và Admin UI tập trung**

```bash
(cd modules/iam/application && dart test test/fake_iam_module_test.dart test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart)
(cd modules/iam/infrastructure && dart test test/supabase_platform_admin_gateway_onboarding_test.dart)
(cd apps/admin && flutter test test/features/organizations/presentation/bloc/platform_onboarding_cubit_test.dart test/features/users/presentation/pages/platform_onboarding_page_test.dart)
```

Kỳ vọng: toàn bộ test tập trung pass; onboarding vẫn hiển thị tên/email Owner được mời nhưng không tạo thành viên giả.

- [ ] **Bước 8: Commit thay đổi hợp đồng Dart**

```bash
git add modules/iam/application/lib/src/platform/shared/tenant_onboarding_result_dto.dart modules/iam/application/lib/src/platform/shared/onboarding_owner_input.dart modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_handler.dart modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command.dart modules/iam/application/lib/src/testing/fake_iam_module.dart modules/iam/application/test/fake_iam_module_test.dart modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart
git commit -m "refactor(iam): defer invited owner materialization"
```

---

### Task 3: Sửa RPC ghi chỉ tạo Invitation; tạo profile/Membership khi accept

**Tệp:**
- Tạo: `modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart`
- Sửa in-place:
  - `supabase/migrations/20260916005_iam_patch_invitation_membership_store_scope.sql` (`iam.create_tenant_invitation`)
  - `supabase/migrations/20260916004_iam_patch_onboarding_default_store_scope.sql` (`iam.create_tenant_onboarding`)
  - `supabase/migrations/20260911006_iam_reinvite_provisioning_owner.sql` (`iam.reinvite_provisioning_owner`)
  - `supabase/migrations/20260916006_iam_patch_accept_invitation_default_store_scope.sql` (`iam.accept_invitation`)

**Đầu vào/đầu ra:**
- Đầu vào: chữ ký chuẩn của `iam.create_tenant_invitation`, `iam.create_tenant_onboarding`, `iam.reinvite_provisioning_owner` và `iam.accept_invitation` trong đúng file owner ở REGISTRY.
- Đầu ra: các nhánh gửi chỉ tạo Invitation; chỉ một ranh giới tạo profile/Membership khi accept; giữ nguyên dạng response. Không tạo `_drafts/`.

- [ ] **Bước 1: Xem mức tác động và nơi sở hữu RPC chuẩn**

```bash
node .gitnexus/run.cjs impact "createInvitation" --direction upstream --repo .
node .gitnexus/run.cjs impact "createTenantOnboarding" --direction upstream --repo .
rg -n "create_tenant_invitation:|create_tenant_onboarding:|reinvite_provisioning_owner:|accept_invitation:" supabase/migrations/REGISTRY.yaml
```

Kỳ vọng: impact của method có thể là `UNKNOWN` do gọi qua interface/RPC. REGISTRY xác nhận đúng bốn file sửa in-place ở trên.

- [ ] **Bước 2: Viết SQL contract test sẽ fail trước khi sửa migration**

Tạo `iam_deferred_invitation_write_sql_contract_test.dart`. Đọc và nối nội dung bốn file migration write, rồi assert bằng `functionBody` trên chuỗi gộp:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    const files = [
      '20260916005_iam_patch_invitation_membership_store_scope.sql',
      '20260916004_iam_patch_onboarding_default_store_scope.sql',
      '20260911006_iam_reinvite_provisioning_owner.sql',
      '20260916006_iam_patch_accept_invitation_default_store_scope.sql',
    ];
    sql = files
        .map((f) => File('${root.path}/supabase/migrations/$f').readAsStringSync())
        .join('\n');
  });

test('send paths never materialize profiles or memberships', () {
  for (final fn in const [
    'iam.create_tenant_invitation',
    'iam.create_tenant_onboarding',
    'iam.reinvite_provisioning_owner',
  ]) {
    final body = functionBody(sql, fn);
    expect(body, isNot(contains('insert into iam.platform_user_profiles')), reason: fn);
    expect(body, isNot(contains('insert into iam.memberships')), reason: fn);
    expect(body, isNot(contains('update iam.memberships')), reason: fn);
  }
});

test('onboarding and reinvite return no pre-accept membership', () {
  final onboarding = functionBody(sql, 'iam.create_tenant_onboarding');
  expect(onboarding, contains("'owner_membership_id', null"));
  expect(onboarding, contains('insert into iam.tenant_invitations'));
  expect(onboarding, contains('iam.enqueue_outbox_message'));

  final reinvite = functionBody(sql, 'iam.reinvite_provisioning_owner');
  expect(reinvite, contains("'owner_membership_id', null"));
  expect(reinvite, contains('update iam.tenant_invitations'));
  expect(reinvite, contains('iam.enqueue_outbox_message'));
  expect(reinvite, isNot(contains('insert into iam.tenant_invitations')));
});

test('accept upserts the real profile before creating membership', () {
  final body = functionBody(sql, 'iam.accept_invitation');
  final profile = body.indexOf('insert into iam.platform_user_profiles');
  final membership = body.lastIndexOf('insert into iam.memberships');
  final consume = body.lastIndexOf("status = 'accepted'");
  expect(profile, isNonNegative);
  expect(membership, greaterThan(profile));
  expect(consume, greaterThan(membership));
  expect(body, contains('on conflict (user_id) do update'));
  expect(body, contains("when iam.platform_user_profiles.status = 'suspended'"));
  expect(body, contains('v_inv.target_membership_id'));
});

test('reinvite reuses the locked owner invitation row', () {
  final body = functionBody(sql, 'iam.reinvite_provisioning_owner');
  expect(body, contains('update iam.tenant_invitations'));
  expect(body, contains("v_inv.status not in ('pending', 'expired')"));
  expect(body, isNot(contains("set status = 'expired'")));
  expect(body, isNot(contains('insert into iam.tenant_invitations')));
});

}

String functionBody(String sql, String qualifiedName) {
  final start = sql.lastIndexOf(
    'create or replace function $qualifiedName(',
  );
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) throw StateError('$qualifiedName terminator not found');
  return sql.substring(start, end + 3);
}

Directory findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Bước 3: Chạy contract test và xác nhận hành vi hybrid cũ làm test fail**

```bash
(cd modules/iam/infrastructure && dart test test/iam_deferred_invitation_write_sql_contract_test.dart)
```

Kỳ vọng: FAIL vì body migration hiện tại vẫn `insert into iam.platform_user_profiles` / `iam.memberships` trên đường gửi, hoặc reinvite còn expire+insert thay vì reuse row, hoặc chưa upsert profile trên accept theo thứ tự mới.

- [ ] **Bước 4: Sửa in-place bốn migration write (không tạo draft, không đổi header Intent/Touches nếu đã đúng owner)**

Chỉ sửa body `create or replace function` trong đúng file REGISTRY. Không thêm helper RPC không đổi; không tạo file `_drafts/` hay migration timestamp mới.

- [ ] **Bước 5: Bỏ tạo sẵn nhân viên trong `create_tenant_invitation`**

Trong `20260916005_...`, giữ các bước kiểm tra chỉ đọc đối với Membership active/inactive và Invitation pending. Bỏ các block tạo `v_invitee_user_id`, insert `platform_user_profiles`, kích hoạt lại Membership đã xóa hoặc insert Membership. Insert Invitation không có `target_membership_id`:

```sql
insert into iam.tenant_invitations (
  tenant_id,
  invitee_email,
  initial_role_id,
  status,
  token_hash,
  invited_by_membership_id,
  expires_at,
  status_changed_at,
  version,
  created_at,
  updated_at,
  delivery_correlation_id,
  last_sent_at
)
values (
  p_tenant_id,
  v_email,
  p_initial_role_id,
  'pending',
  v_token_hash,
  v_actor_membership.id,
  v_expires_at,
  v_now,
  1,
  v_now,
  v_now,
  v_correlation_id,
  v_now
)
returning * into v_invitation;
```

Bỏ `target_membership_id` khỏi audit payload. Giữ nguyên xác thực role, luồng gửi, audit, result DTO và hành vi `_idempotency_store`.

- [ ] **Bước 6: Bỏ tạo sẵn Owner trong onboarding và gửi lại lời mời**

Trong `20260916004_...` và `20260911006_...`, với cả hai function:

- Lấy `v_owner_email` từ đầu vào Owner mới hoặc Auth user đã có như hiện nay.
- Xác thực role `store_owner` đang active.
- Không tìm/tạo profile placeholder.
- Không insert Owner Membership.
- Vẫn tạo Tenant/default store ở nhánh đang có hành vi này.
- Tạo Owner Invitation với `is_owner=true` và tên/số điện thoại được cung cấp.
- Trả `owner_membership_id = null`.

Giữ cấu trúc kết quả sau:

```sql
v_result := jsonb_build_object(
  'tenant_id', v_tenant_id,
  'owner_membership_id', null,
  'owner_user_id', case when v_is_new then null else p_owner_user_id end,
  'tenant_status', 'provisioning',
  'correlation_id', v_correlation,
  'is_new_user', v_is_new,
  'activation_issued', true
);
```

Với `reinvite_provisioning_owner`, khóa Tenant provisioning rồi khóa Owner Invitation mới nhất (`for update`). Chỉ reuse khi status lưu là `pending` hoặc `expired`; `accepted`/`declined`/`revoked` → reject. `UPDATE` cùng row chỉ thay email chuẩn hóa và các trường kỹ thuật của lần gửi: token hash mới, expiry mới, `delivery_correlation_id`, `last_sent_at`, `version++`, `updated_at`; `status = 'pending'`; `status_changed_at` chỉ đổi khi từ `expired` → `pending`; đặt `accepted_membership_id`/`target_membership_id` về null. Luôn giữ nguyên `invitation_id`, `tenant_id`, `created_at`, `initial_role_id`, `is_owner`, `invited_by_membership_id`, `given_name`, `family_name` và `phone`, kể cả khi đổi email. Áp dụng check Membership active/inactive và `INVITATION_PENDING_EXISTS` cho email mới, **loại trừ** chính invitation đang khóa. Trả cùng `invitation_id`, `owner_membership_id = null`. Replay idempotency trả snapshot cũ trước khi xoay token/gửi email.

- [ ] **Bước 7: Để `accept_invitation` upsert profile thật**

Trong `20260916006_...`, sau khi xác định `v_caller` và `v_email` đã xác minh, nhưng trước khi tìm/tạo Membership, thêm:

```sql
insert into iam.platform_user_profiles (
  user_id, email, status, email_verified,
  given_name, family_middle_name, phone_number,
  created_at, updated_at
)
values (
  v_caller,
  v_email,
  'active',
  true,
  nullif(trim(coalesce(v_inv.given_name, '')), ''),
  nullif(trim(coalesce(v_inv.family_name, '')), ''),
  nullif(trim(coalesce(v_inv.phone, '')), ''),
  v_now,
  v_now
)
on conflict (user_id) do update
set email = excluded.email,
    status = case
      when iam.platform_user_profiles.status = 'suspended'
        then iam.platform_user_profiles.status
      else 'active'
    end,
    email_verified = true,
    given_name = coalesce(
      nullif(trim(iam.platform_user_profiles.given_name), ''),
      excluded.given_name
    ),
    family_middle_name = coalesce(
      nullif(trim(iam.platform_user_profiles.family_middle_name), ''),
      excluded.family_middle_name
    ),
    phone_number = coalesce(
      nullif(trim(iam.platform_user_profiles.phone_number), ''),
      excluded.phone_number
    ),
    updated_at = v_now;
```

Giữ nhánh `target_membership_id` lịch sử trước nhánh fallback tạo Membership mới. Invitation mới có target null nên đi vào nhánh insert hiện có. Chỉ đánh dấu Invitation `accepted` sau khi đã có profile và Membership thật.

- [ ] **Bước 8: Chạy SQL tests và test tương thích lịch sử**

```bash
(cd modules/iam/infrastructure && dart test test/iam_deferred_invitation_write_sql_contract_test.dart)
(cd modules/iam/infrastructure && dart test test/iam_refactor_03_memberships_sql_contract_test.dart test/iam_refactor_04_tenant_invitations_sql_contract_test.dart test/iam_refactor_12_idempotency_records_sql_contract_test.dart)
melos run migrate:verify-policy -- --strict
```

Kỳ vọng: contract test write mới pass; các contract test đọc cùng file migration vẫn pass hoặc được cập nhật tối thiểu nếu assertion cũ giả định pre-create (chỉ sửa assertion đã lỗi thời, không giữ hybrid như hợp đồng hiện hành). Strict policy vẫn OK vì không thêm file migration mới / không đổi `-- Touches:` của file khác.

- [ ] **Bước 9: Commit migration write in-place và contract tests**

```bash
git add supabase/migrations/20260916005_iam_patch_invitation_membership_store_scope.sql supabase/migrations/20260916004_iam_patch_onboarding_default_store_scope.sql supabase/migrations/20260911006_iam_reinvite_provisioning_owner.sql supabase/migrations/20260916006_iam_patch_accept_invitation_default_store_scope.sql modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart
git commit -m "refactor(iam): defer invitation writes until acceptance"
```

---

### Task 4: Hiển thị Owner Invitation trong projection mà không tạo thành viên

**Tệp:**
- Tạo: `modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart`
- Sửa in-place:
  - `supabase/migrations/20260911003_iam_get_platform_tenant_owner_from_invitation.sql` (`iam.get_platform_tenant`)
  - `supabase/migrations/20260811010_iam_platform_tenants_read.sql` (`iam.search_platform_tenants`)

**Đầu vào/đầu ra:**
- Đầu vào: Owner Invitation pending từ Task 3 và các wire key hiện có của `PlatformTenantSummaryDto`/`PlatformTenantDetailDto`.
- Đầu ra: projection ưu tiên Owner đã accept, fallback về Invitation pending; thêm metadata Owner Invitation mới nhất (`owner_invitation_email`, `owner_invitation_state`, `owner_invitation_expires_at`, `owner_invitation_given_name`, `owner_invitation_family_name`, `owner_invitation_phone`) cho PA-SG-02. Mảng `members` vẫn chỉ gồm Membership thật.

- [ ] **Bước 1: Viết contract test cho read projection, ban đầu phải fail**

Tạo test đọc hai migration read, nối nội dung, trích `iam.get_platform_tenant` và `iam.search_platform_tenants` rồi assert:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final root = findRepoRoot();
    const files = [
      '20260911003_iam_get_platform_tenant_owner_from_invitation.sql',
      '20260811010_iam_platform_tenants_read.sql',
    ];
    sql = files
        .map((f) => File('${root.path}/supabase/migrations/$f').readAsStringSync())
        .join('\n');
  });

test('detail prefers accepted owner and falls back to pending invitation', () {
  final body = functionBody(sql, 'iam.get_platform_tenant');
  expect(body, contains('from iam.memberships m'));
  expect(body, contains('from iam.tenant_invitations i'));
  expect(body, contains("i.is_owner is true"));
  expect(body, contains("i.status = 'pending'"));
  expect(body, contains('i.expires_at > now()'));
  expect(body, contains('owner_priority'));
  expect(body, contains('order by owner_priority, owner_created_at desc'));
  expect(body, contains("'owner_user_id', v_owner.user_id"));
  expect(body, contains("'members', coalesce(v_members, '[]'::jsonb)"));
  expect(body, contains("'owner_invitation_email', v_owner_inv.invitee_email"));
  expect(body, contains("'owner_invitation_state',"));
  expect(body, contains("'owner_invitation_expires_at', v_owner_inv.expires_at"));
});

test('search uses the same pending-owner fallback without inflating member count', () {
  final body = functionBody(sql, 'iam.search_platform_tenants');
  expect(body, contains('left join lateral'));
  expect(body, contains('iam.tenant_invitations'));
  expect(body, contains("status = 'pending'"));
  expect(body, contains('count(distinct m.user_id)'));
  expect(body, isNot(contains('count(distinct i.invitee_email)')));
});

}

String functionBody(String sql, String qualifiedName) {
  final start = sql.lastIndexOf(
    'create or replace function $qualifiedName(',
  );
  if (start < 0) throw StateError('$qualifiedName not found');
  final end = sql.indexOf(r'$$;', start);
  if (end < 0) throw StateError('$qualifiedName terminator not found');
  return sql.substring(start, end + 3);
}

Directory findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Bước 2: Chạy test và xác nhận body cũ làm fail**

```bash
(cd modules/iam/infrastructure && dart test test/iam_deferred_invitation_read_sql_contract_test.dart)
```

Kỳ vọng: FAIL vì migration hiện tại thiếu `owner_priority` / metadata `owner_invitation_*` hoặc chưa có union fallback đúng quy tắc mới.

- [ ] **Bước 3: Sửa in-place hai migration read (không tạo draft)**

Chỉ sửa body function trong đúng hai file REGISTRY. Không đổi `REGISTRY.yaml`. Không tạo `_drafts/002_...`.

- [ ] **Bước 4: Ưu tiên Owner đã accept trong tenant detail**

Trong `20260911003_...`, giữ các trường Tenant/thành viên/vòng đời. Chỉ thay truy vấn chọn Owner bằng union có thứ tự ưu tiên:

```sql
select owner_candidates.*
into v_owner
from (
  select
    0 as owner_priority,
    m.created_at as owner_created_at,
    p.user_id,
    coalesce(
      nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
      nullif(trim(p.email), ''),
      ''
    )::text as owner_name,
    coalesce(nullif(trim(p.email), ''), '')::text as owner_email,
    coalesce(rd.label, m.role::text) as owner_role,
    coalesce(p.email_verified, false) as owner_email_verified
  from iam.memberships m
  join iam.platform_user_profiles p on p.user_id = m.user_id
  left join iam.role_definitions rd on rd.code = m.role
  where m.tenant_id = p_tenant_id
    and m.is_owner
    and m.is_active

  union all

  select
    1 as owner_priority,
    i.created_at as owner_created_at,
    null::uuid as user_id,
    coalesce(
      nullif(trim(concat_ws(' ', i.family_name, i.given_name)), ''),
      i.invitee_email
    )::text as owner_name,
    i.invitee_email::text as owner_email,
    coalesce(rd.label, 'Chủ sở hữu')::text as owner_role,
    false as owner_email_verified
  from iam.tenant_invitations i
  left join iam.role_definitions rd on rd.id = i.initial_role_id
  where i.tenant_id = p_tenant_id
    and i.is_owner is true
    and i.status = 'pending'
    and i.expires_at > now()
) owner_candidates
order by owner_priority, owner_created_at desc
limit 1;
```

Không đưa Owner chỉ có Invitation vào `v_members`.

Đọc Owner Invitation mới nhất độc lập với fallback hiển thị Owner đã accept/đang pending, để Invitation đã hết hạn vẫn cung cấp email cho sheet gửi lại ở Admin. Thêm `v_owner_inv record;` vào khai báo function, rồi chọn bản ghi mới nhất theo `(created_at desc, id desc)`:

```sql
select i.id, i.invitee_email, i.status, i.expires_at,
       i.given_name, i.family_name, i.phone
into v_owner_inv
from iam.tenant_invitations i
where i.tenant_id = p_tenant_id and i.is_owner is true
order by i.created_at desc, i.id desc
limit 1;
```

Thêm các key sau vào `jsonb_build_object` của detail; giữ nguyên mọi key hiện có:

```sql
'owner_invitation_email', v_owner_inv.invitee_email,
'owner_invitation_state', case
  when v_owner_inv.status = 'pending' and v_owner_inv.expires_at > now()
    then 'pending'
  when v_tenant.status = 'provisioning' and v_owner.user_id is null
    then 'expired'
  else null
end,
'owner_invitation_expires_at', v_owner_inv.expires_at,
'owner_invitation_given_name', v_owner_inv.given_name,
'owner_invitation_family_name', v_owner_inv.family_name,
'owner_invitation_phone', v_owner_inv.phone
```

Trạng thái hiển thị `expired` cố ý bao phủ mọi trường hợp không còn Invitation hợp lệ khi chưa có Owner đã accept; UI dùng câu “Lời mời hết hạn”.

- [ ] **Bước 5: Áp dụng cùng thứ tự ưu tiên trong tenant search**

Trong `iam.search_platform_tenants`, lấy các trường Owner qua candidate union trong `left join lateral` với cùng quy tắc ưu tiên, sau đó chọn `owner.owner_name` và `owner.owner_email`. Member count chỉ dựa trên Membership:

```sql
left join lateral (
  select candidates.owner_name, candidates.owner_email
  from (
    select
      0 as owner_priority,
      m.created_at as owner_created_at,
      coalesce(
        nullif(trim(concat_ws(' ', p.family_middle_name, p.given_name)), ''),
        nullif(trim(p.email), ''),
        ''
      )::text as owner_name,
      coalesce(nullif(trim(p.email), ''), '')::text as owner_email
    from iam.memberships m
    join iam.platform_user_profiles p on p.user_id = m.user_id
    where m.tenant_id = t.id
      and m.is_owner
      and m.is_active

    union all

    select
      1 as owner_priority,
      i.created_at as owner_created_at,
      coalesce(
        nullif(trim(concat_ws(' ', i.family_name, i.given_name)), ''),
        i.invitee_email
      )::text as owner_name,
      i.invitee_email::text as owner_email
    from iam.tenant_invitations i
    where i.tenant_id = t.id
      and i.is_owner is true
      and i.status = 'pending'
      and i.expires_at > now()
  ) candidates
  order by candidates.owner_priority, candidates.owner_created_at desc
  limit 1
) owner on true
```

Chọn `owner.owner_name` và `owner.owner_email` trong CTE `filtered`; tính member count đúng theo Membership:

```sql
(
  select count(distinct m.user_id)
  from iam.memberships m
  where m.tenant_id = t.id
    and m.is_active
) as member_count
```

Giữ nguyên filter, phân trang và các result key hiện có.

- [ ] **Bước 6: Chạy regression test cho RPC đọc và mapper**

```bash
(cd modules/iam/infrastructure && dart test test/iam_deferred_invitation_read_sql_contract_test.dart test/supabase_platform_admin_gateway_search_test.dart)
(cd apps/admin && flutter test test/features/users/presentation/pages/platform_onboarding_page_test.dart)
melos run migrate:verify-policy -- --strict
```

Kỳ vọng: tất cả test pass; Owner đã accept được ưu tiên; chi tiết Owner pending vẫn hiển thị mà không tăng thành viên; Invitation mới nhất dù hết hạn vẫn cung cấp email cho action ở Admin.

- [ ] **Bước 7: Commit migration read in-place**

```bash
git add supabase/migrations/20260911003_iam_get_platform_tenant_owner_from_invitation.sql supabase/migrations/20260811010_iam_platform_tenants_read.sql modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart
git commit -m "refactor(iam): project pending owners from invitations"
```

---

### Task 5: PA-D-01/PA-D-03 chỉ hiển thị Platform User thật

**Tệp:**
- Sửa in-place: `supabase/migrations/20260911002_iam_patch_search_phone_status_casts.sql` (`iam.search_platform_users`, `iam.get_platform_user`)
- Tạo: `modules/iam/infrastructure/test/iam_platform_user_invitation_visibility_sql_contract_test.dart`
- Sửa: `apps/admin/lib/features/users/presentation/pages/platform_users_page.dart`
- Sửa: `apps/admin/lib/features/users/presentation/widgets/platform_users_filter_sheet.dart`
- Sửa: `apps/admin/lib/features/users/presentation/pages/platform_user_detail_page.dart`
- Sửa: `apps/admin/lib/features/users/presentation/bloc/platform_user_detail_state.dart`
- Kiểm thử: `apps/admin/test/features/users/presentation/pages/platform_users_page_test.dart`
- Kiểm thử: `apps/admin/test/features/users/presentation/pages/platform_user_detail_page_test.dart`
- Kiểm thử: `apps/admin/test/features/users/presentation/bloc/platform_user_detail_cubit_test.dart`

**Đầu vào/đầu ra:**
- Đầu vào: `iam.search_platform_users`, `iam.get_platform_user`, `PlatformUserSummaryDto`, `PlatformUserDetailDto`.
- Đầu ra: chỉ đọc Platform User có Auth user thật; không có profile placeholder chỉ từ Invitation trong danh sách/chi tiết Admin; giữ thao tác active/suspended.

- [ ] **Bước 1: Phân tích upstream impact và thêm SQL/UI tests sẽ fail**

```bash
node .gitnexus/run.cjs impact "search_platform_users" --direction upstream --repo .
node .gitnexus/run.cjs impact "get_platform_user" --direction upstream --repo .
node .gitnexus/run.cjs impact "PlatformUserDetailState" --direction upstream --repo .
```

Trong SQL contract test mới, đọc `20260911002_iam_patch_search_phone_status_casts.sql`, trích body của hai function bằng helper `functionBody`/`findRepoRoot` ở Task 4 rồi assert:

```dart
for (final name in const ['iam.search_platform_users', 'iam.get_platform_user']) {
  final body = functionBody(sql, name);
  expect(body, contains('from auth.users u'));
  expect(body, contains('left join iam.platform_user_profiles p on p.user_id = u.id'));
}
expect(sql, isNot(contains('full outer join auth.users')));
```

Thêm widget assertions: list/filter sheet không còn tùy chọn “Chờ kích hoạt”; PA-D-03 hiện `user.email` dưới tên thay cho “Tài khoản nền tảng”; chi tiết `pendingActivation` không có action PA-O-02. Giữ test đặt lại mật khẩu/tạm ngừng của user active và khôi phục user suspended.

- [ ] **Bước 2: Chạy test tập trung và xác nhận trạng thái đỏ**

```bash
(cd modules/iam/infrastructure && dart test test/iam_platform_user_invitation_visibility_sql_contract_test.dart)
(cd apps/admin && flutter test test/features/users/presentation/pages/platform_users_page_test.dart test/features/users/presentation/pages/platform_user_detail_page_test.dart)
```

Kỳ vọng: body SQL cũ (full outer join / profile-first) và nội dung/filter/action UI cũ làm các assertion mới fail.

- [ ] **Bước 3: Sửa in-place hai function trong `20260911002_...`**

Giữ kiểm tra quyền, hành vi tìm kiếm/trạng thái của user thật, phân trang, grants và response keys. Thay full outer join bằng truy vấn lấy Auth làm gốc:

```sql
from auth.users u
left join iam.platform_user_profiles p on p.user_id = u.id
```

Trong detail, dùng `where u.id = p_user_id`. Profile placeholder lịch sử không có Auth user phải trả not-found; Auth user thật chưa có profile vẫn hiển thị. Không xóa bản ghi lịch sử hoặc enum `pendingActivation` vì Auth user hiện hữu và đường tương thích vẫn có thể dùng. Không tạo `_drafts/003_...`.

- [ ] **Bước 4: Sửa giao diện PA-D-01/PA-D-03/PA-O-02**

Bỏ chip `pendingActivation` khỏi `PlatformUsersPage._filters` và `VChip` tương ứng trong `showPlatformUsersFilterSheet`. Ở header trang chi tiết, thay `VText('Tài khoản nền tảng', ...)` bằng `VText(user.email, ...)`. Bỏ action card `showActivationInvite` và nhánh tạm ngừng chỉ dành cho pending trong `PlatformUserDetailState`; giữ `showPasswordReset`, tạm ngừng user active và khôi phục user suspended. Deep link tới profile placeholder không có Auth user phải hiện trạng thái not-found đang có.

- [ ] **Bước 5: Chạy test xanh rồi commit**

```bash
(cd modules/iam/infrastructure && dart test test/iam_platform_user_invitation_visibility_sql_contract_test.dart test/iam_platform_user_profile_sql_contract_test.dart)
(cd apps/admin && flutter test test/features/users/presentation/pages/platform_users_page_test.dart test/features/users/presentation/pages/platform_user_detail_page_test.dart test/features/users/presentation/bloc/platform_user_detail_cubit_test.dart)
git diff --check
git add supabase/migrations/20260911002_iam_patch_search_phone_status_casts.sql modules/iam/infrastructure/test/iam_platform_user_invitation_visibility_sql_contract_test.dart apps/admin/lib/features/users/presentation/pages/platform_users_page.dart apps/admin/lib/features/users/presentation/widgets/platform_users_filter_sheet.dart apps/admin/lib/features/users/presentation/pages/platform_user_detail_page.dart apps/admin/lib/features/users/presentation/bloc/platform_user_detail_state.dart apps/admin/test/features/users/presentation/pages/platform_users_page_test.dart apps/admin/test/features/users/presentation/pages/platform_user_detail_page_test.dart apps/admin/test/features/users/presentation/bloc/platform_user_detail_cubit_test.dart
git commit -m "refactor(iam): separate platform users from pending invitations"
```

---

### Task 6: Phân biệt Owner Invitation đang chờ và hết hạn trong readiness

**Tệp:**
- Sửa in-place: `supabase/migrations/20260811016_iam_tenant_readiness_activate.sql` (`iam.get_tenant_readiness`)
- Tạo: `modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart`
- Sửa: `modules/iam/application/lib/src/shared/tenant_readiness_issue_codes.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart`
- Sửa: `apps/erp/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart`
- Kiểm thử: `apps/admin/test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart`
- Tạo: `apps/erp/test/features/iam/tenant_readiness_cta_mapper_test.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart`
- Sửa: `apps/erp/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart`
- Sửa: `apps/erp/lib/features/more/presentation/bloc/iam_feature_access_state.dart`

**Đầu vào/đầu ra:**
- Đầu vào: `iam.get_tenant_readiness`, `iam.activate_tenant` không đổi và `TenantReadinessDto.blockers`.
- Đầu ra: hai mã `OWNER_ACCEPTANCE_PENDING` và `OWNER_INVITATION_EXPIRED`, đều chặn kích hoạt; không thêm action khôi phục trên readiness.

- [ ] **Bước 1: Phân tích impact và viết contract test sẽ fail**

```bash
node .gitnexus/run.cjs impact "get_tenant_readiness" --direction upstream --repo .
node .gitnexus/run.cjs impact "TenantReadinessIssueCodes" --direction upstream --repo .
```

Thêm SQL contract assertions đọc `20260811016_iam_tenant_readiness_activate.sql` cho nhánh đang chờ/hết hạn và việc đánh giá lại readiness khi kích hoạt:

```dart
final body = functionBody(sql, 'iam.get_tenant_readiness');
expect(body, contains("'OWNER_ACCEPTANCE_PENDING'"));
expect(body, contains("'OWNER_INVITATION_EXPIRED'"));
expect(body, contains('i.expires_at > now()'));
expect(body, contains("v_tenant.status = 'provisioning'"));
expect(body, contains("'OWNER_MEMBERSHIP_INVALID'"));
expect(body, contains('jsonb_array_length(v_blockers) = 0'));
```

Thêm mapper/widget tests xác nhận hai mã mới hiển thị đúng câu tiếng Việt đã duyệt, không có route sửa lỗi, và `canActivate=false` khiến action kích hoạt không khả dụng.

- [ ] **Bước 2: Chạy test tập trung và xác nhận trạng thái đỏ**

```bash
(cd modules/iam/infrastructure && dart test test/iam_provisioning_owner_readiness_sql_contract_test.dart)
(cd apps/admin && flutter test test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart)
```

Kỳ vọng: mã mới còn thiếu trong migration và câu UI `OWNER_MEMBERSHIP_INVALID` cũ làm test fail.

- [ ] **Bước 3: Sửa in-place `iam.get_tenant_readiness` trong `20260811016_...`**

Giữ mọi điều kiện hiện có về profile, pháp lý, Auth snapshot, quyền và `can_activate`. Chỉ thay nhánh đếm Owner bằng:

```sql
if v_owner_count <> 1 then
  if v_owner_count = 0 and v_tenant.status = 'provisioning' then
    if exists (
      select 1 from iam.tenant_invitations i
      where i.tenant_id = p_tenant_id
        and i.is_owner is true
        and i.status = 'pending'
        and i.expires_at > now()
    ) then
      v_blockers := v_blockers || to_jsonb('OWNER_ACCEPTANCE_PENDING'::text);
    else
      v_blockers := v_blockers || to_jsonb('OWNER_INVITATION_EXPIRED'::text);
    end if;
  else
    v_blockers := v_blockers || to_jsonb('OWNER_MEMBERSHIP_INVALID'::text);
  end if;
else
  select m.user_id into v_owner_user
  from iam.memberships m
  where m.tenant_id = p_tenant_id
    and m.is_owner is true
    and m.is_active
  limit 1;

  select iam._platform_user_effective_status(u.email_confirmed_at)
  into v_owner_effective_status
  from auth.users u
  where u.id = v_owner_user;

  if coalesce(v_owner_effective_status, '') <> 'active' then
    v_blockers := v_blockers || to_jsonb('OWNER_IDENTITY_INACTIVE'::text);
  end if;

  v_snapshot := iam.get_auth_user_snapshot(v_owner_user);
  if v_snapshot ->> 'account_status' = 'unavailable' then
    v_blockers := v_blockers || to_jsonb('OWNER_IDENTITY_UNAVAILABLE'::text);
  elsif coalesce((v_snapshot ->> 'email_verified')::boolean, false) is not true then
    v_blockers := v_blockers || to_jsonb('OWNER_EMAIL_UNVERIFIED'::text);
  end if;
end if;
```

Không sửa `iam.activate_tenant`; RPC này vẫn gọi readiness trong transaction và trả `READINESS_BLOCKED` cho cả hai mã mới.

- [ ] **Bước 4: Map mã lỗi sang Admin và Tenant UI**

Thêm `ownerAcceptancePending` và `ownerInvitationExpired` vào `TenantReadinessIssueCodes`. Ở cả hai CTA mapper, hiển thị lần lượt “Đang chờ chủ sở hữu chấp nhận lời mời” và “Lời mời hết hạn”. Đưa hai mã vào nhóm Owner blocker trong widget readiness của hai app và nhóm Owner trong `IamFeatureAccessState` của ERP. `routeFor` trả `null`; không thêm nút gửi lại ở màn hình readiness.

- [ ] **Bước 5: Chạy test xanh rồi commit**

```bash
(cd modules/iam/infrastructure && dart test test/iam_provisioning_owner_readiness_sql_contract_test.dart test/iam_tenant_readiness_sql_contract_test.dart)
(cd apps/admin && flutter test test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart)
(cd apps/erp && flutter test test/features/iam/tenant_readiness_cta_mapper_test.dart)
git diff --check
git add supabase/migrations/20260811016_iam_tenant_readiness_activate.sql modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart modules/iam/application/lib/src/shared/tenant_readiness_issue_codes.dart apps/admin/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart apps/erp/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart apps/admin/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart apps/erp/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart apps/erp/lib/features/more/presentation/bloc/iam_feature_access_state.dart apps/admin/test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart apps/erp/test/features/iam/tenant_readiness_cta_mapper_test.dart
git commit -m "feat(iam): distinguish pending and expired owner readiness"
```

---

### Task 7: Triển khai hai bottom sheet gửi lại Owner Invitation tại chi tiết Tenant trên Admin (PA-SG-02)

**Tệp:**
- Tạo: `apps/admin/lib/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart`
- Sửa: `modules/iam/application/lib/src/platform/queries/get_platform_tenant/platform_tenant_detail_dto.dart`
- Sửa: `modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command_validator.dart`
- Sửa: `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart`
- Sửa: `apps/admin/lib/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart`
- Sửa: `apps/admin/lib/features/organizations/presentation/mappers/platform_tenant_ui_mapper.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/organizations/models/organization_ui_model.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/organizations/views/organization_detail_page.dart`
- Sửa: `apps/admin/lib/features/organizations/presentation/pages/platform_tenant_detail_page.dart`
- Kiểm thử: `modules/iam/infrastructure/test/supabase_platform_admin_gateway_search_test.dart`
- Kiểm thử: `apps/admin/test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart`
- Kiểm thử: `apps/admin/test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart`
- Tạo kiểm thử: `apps/admin/test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart`
- Kiểm thử: `apps/admin/test/features/organizations/presentation/pages/organization_detail_page_test.dart`

**Đầu vào/đầu ra:**
- Đầu vào: các wire key `owner_invitation_*` từ Task 4 và `ReinviteProvisioningOwnerCommand({tenantId, owner, idempotencyKey})` hiện có.
- Đầu ra: nút “Thao tác” hiện có mở sheet “Thao tác”; với Tenant `settingUp`, sheet này chỉ có “Gửi lại email” và mở sheet thứ hai “Gửi lại email thiết lập?”. Giữ hoặc đổi email đều gọi một thao tác backend rồi tải lại chi tiết. Với `active`/`suspended`, không có mục gửi lại email; giữ “Thay đổi chủ sở hữu” cùng các thao tác hiện tại. Không đổi banner, nền trang hay thanh hành động.

- [ ] **Bước 1: Xem impact và viết DTO/cubit/widget tests sẽ fail**

```bash
node .gitnexus/run.cjs impact "PlatformTenantDetailDto" --direction upstream --repo .
node .gitnexus/run.cjs impact "ReinviteProvisioningOwnerCommandValidator" --direction upstream --repo .
node .gitnexus/run.cjs impact "PlatformTenantDetailCubit" --direction upstream --repo .
```

Kiểm tra các wire key chính xác từ Task 4 được map vào trường DTO nullable. Với Tenant `settingUp`, widget test xác nhận nút “Thao tác” hiện có mở sheet “Thao tác” chỉ có mục “Gửi lại email” và subtitle “Gửi lại liên kết thiết lập cho Chủ sở hữu”; không hiện “Thay đổi chủ sở hữu” hay “Tạm ngừng tổ chức”. Nhấn mục này mở sheet “Gửi lại email thiết lập?” với đúng mô tả, nhãn, helper và nút “Gửi” / “Hủy” của mock; email điền sẵn từ Owner Invitation mới nhất. Hủy không gửi command; email sai chặn submit; gửi cùng `owner@example.com` hoặc đổi thành `new@example.com` đều phát `ReinviteProvisioningOwnerCommand` với email đã chuẩn hóa. Test loading, lỗi giữ sheet/dữ liệu để thử lại, thành công đóng sheet và tải lại detail. Thêm test riêng cho `active` và `suspended`: không tìm thấy “Gửi lại email”, vẫn có “Thay đổi chủ sở hữu” và các action tương ứng; không mở sheet resend ở hai trạng thái này.

- [ ] **Bước 2: Chạy test tập trung và xác nhận trạng thái đỏ**

```bash
(cd modules/iam/infrastructure && dart test test/supabase_platform_admin_gateway_search_test.dart)
(cd apps/admin && flutter test test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart test/features/organizations/presentation/pages/organization_detail_page_test.dart)
```

Kỳ vọng: thiếu trường Invitation, mục “Gửi lại email”, sheet thứ hai và command khiến assertions mới fail.

- [ ] **Bước 3: Map metadata của read model mà không tạo thành viên**

Thêm `String? ownerInvitationEmail`, `String? ownerInvitationState`, `String? ownerInvitationGivenName`, `String? ownerInvitationFamilyName`, `String? ownerInvitationPhone` và `DateTime? ownerInvitationExpiresAt` vào `PlatformTenantDetailDto` và `OrganizationUiModel`. Map sáu wire key từ Task 4 trong `SupabasePlatformAdminGateway._mapTenantDetail`, dùng `_parseDate` cho hạn mời, rồi truyền qua `PlatformTenantUiMapper.fromDetail`. Đổi `OrganizationUiModel.memberCount` trả `members.length`, không trả 1 giả.

- [ ] **Bước 4: Cho phép thay Owner chỉ bằng email, giữ đúng dữ liệu cũ**

Bottom sheet chỉ nhập email nên validator của lệnh reinvite phải cho phép first/last name rỗng khi `owner.isNewUser`; vẫn bắt buộc email hợp lệ và idempotency key ổn định. Không đổi kiểm tra tên của onboarding. Trong migration write Task 3 (`20260911006_iam_reinvite_provisioning_owner.sql`), reuse Owner Invitation đang khóa; chỉ thay email và các trường bảo mật/delivery của lần gửi, luôn giữ nguyên tên/SĐT cùng metadata người được mời. Xoay token và enqueue delivery trên cùng `invitation_id`, không đụng profile/Membership.

Cubit tạo command chỉ có email bằng input type hiện có:

```dart
ReinviteProvisioningOwnerCommand(
  tenantId: tenantId,
  owner: OnboardingOwnerInput.newUser(
    lastName: '',
    firstName: '',
    email: canonicalEmail,
  ),
  idempotencyKey: operationKey,
)
```

Test việc giữ nguyên metadata người được mời ở cả hai trường hợp cùng email và đổi email trong SQL contract; Admin cubit chỉ gửi email đã chuẩn hóa và tải lại detail.

- [ ] **Bước 5: Nối đúng hai bottom sheet của Admin**

Giữ nguyên `OrganizationDetailBottomBar`: nút “Thao tác” mở `OrganizationActionsBottomSheet` khi còn thao tác hợp lệ. Với Tenant `settingUp` và `ownerInvitationState` hiệu lực `pending`/`expired`, sheet có tiêu đề “Thao tác” và đúng một mục “Gửi lại email” với subtitle “Gửi lại liên kết thiết lập cho Chủ sở hữu”; không có “Thay đổi chủ sở hữu”, “Tạm ngừng tổ chức”, “Khôi phục tổ chức” hay “Đóng tổ chức”. Nếu `settingUp` mà Invitation terminal (`accepted`/`declined`/`revoked`) hoặc thiếu state hợp lệ — **không mở sheet rỗng**. Với Tenant `active`/`suspended`, không thêm mục “Gửi lại email” và giữ “Thay đổi chủ sở hữu” cùng các action theo trạng thái hiện tại. Nhấn “Gửi lại email” đóng sheet thứ nhất rồi mở `OwnerInvitationResendSheet`. Không sửa `OrganizationDetailAlerts`, banner, nội dung nền của detail page hoặc thanh hành động.

Sheet thứ hai có tiêu đề “Gửi lại email thiết lập?”, mô tả “Liên kết hiện tại sẽ hết hiệu lực. Kiểm tra hoặc cập nhật email trước khi gửi lại.”, nhãn “Email nhận liên kết”, helper “Có thể sửa email trước khi gửi lại.”, nút chính “Gửi” và nút phụ “Hủy”. Dùng design system và `VEmailValidator.isValid`, điền ban đầu `ownerInvitationEmail ?? ownerEmail ?? ''`, cho phép sửa, trả email đã trim/lowercase; chặn nút “Gửi” khi email không hợp lệ hoặc đang submit. “Hủy” chỉ đóng sheet, không tạo command. `PlatformTenantDetailPage` truyền callback qua `OrganizationDetailPage`; cubit gửi `ReinviteProvisioningOwnerCommand` rồi tải lại detail khi thành công. Không tạo sheet xác nhận thứ ba.

Dùng `UuidIdempotencyKeyFactory` cho operation key: thử lại cùng một lần submit lỗi với email không đổi phải dùng lại key; đổi email hoặc submit thành công thì xóa key. Transaction backend ở Task 3 — không phải UI — reuse invitation và xoay token. Trang onboarding hiện đã điều hướng tới tenant detail sau khi thành công; không ghi đè các thay đổi không liên quan đang có ở trang đó.

- [ ] **Bước 6: Chạy test xanh rồi commit**

```bash
(cd modules/iam/infrastructure && dart test test/supabase_platform_admin_gateway_search_test.dart test/iam_deferred_invitation_write_sql_contract_test.dart)
(cd apps/admin && flutter test test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart test/features/organizations/presentation/pages/organization_detail_page_test.dart)
git diff --check
git add modules/iam/application/lib/src/platform/queries/get_platform_tenant/platform_tenant_detail_dto.dart modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command_validator.dart modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart apps/admin/lib/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart apps/admin/lib/features/organizations/presentation/mappers/platform_tenant_ui_mapper.dart apps/admin/lib/features/iam/presentation/organizations/models/organization_ui_model.dart apps/admin/lib/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart apps/admin/lib/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart apps/admin/lib/features/iam/presentation/organizations/views/organization_detail_page.dart apps/admin/lib/features/organizations/presentation/pages/platform_tenant_detail_page.dart modules/iam/infrastructure/test/supabase_platform_admin_gateway_search_test.dart apps/admin/test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart apps/admin/test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart apps/admin/test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart apps/admin/test/features/organizations/presentation/pages/organization_detail_page_test.dart
git commit -m "feat(admin): resend or replace provisioning owner invitation"
```

---

### Task 8: Chỉ Tenant App quản lý lời mời thành viên thông thường

**Tệp:**
- Sửa: `apps/admin/lib/features/iam/presentation/users/views/organization_users_page.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/users/widgets/organization_users_body.dart`
- Sửa: `apps/admin/lib/features/iam/presentation/users/widgets/member_list_section.dart`
- Kiểm thử: `apps/admin/test/features/iam/presentation_module/widgets/organization_users_page_test.dart`
- Kiểm thử: `apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart`

**Đầu vào/đầu ra:**
- Đầu vào: `ListTenantMembersQuery` và `ListInvitationsQuery` là hai read model riêng.
- Đầu ra: Platform Admin không còn điểm vào cho mời/gửi lại/thu hồi lời mời thành viên thông thường; Tenant App giữ khu vực Lời mời riêng; TA-D-01 chỉ hiện Membership thật.

- [ ] **Bước 1: Thêm UI tests sẽ fail và xem impact**

```bash
node .gitnexus/run.cjs impact "OrganizationUsersPage" --direction upstream --repo .
```

Trong Admin widget tests, assert danh sách thành viên không còn nút “Mời thành viên”, tab “Lời mời” hoặc điều hướng tới `/more/users/invite` hay `/more/users/invitations/:id`. Hiện Admin chưa đăng ký route cho các path đó nhưng `OrganizationUsersPage._navigateInvite` có nhánh fallback `MaterialPageRoute`; bỏ nhánh fallback và cả hai callback push. Trong Tenant App tests, email chỉ có Invitation nằm dưới “Lời mời”, không ở “Thành viên”; sau khi accept và tạo Membership mới xuất hiện trong danh sách thành viên. Giữ quyền xem danh sách thành viên hiện có.

- [ ] **Bước 2: Chạy test và xác nhận trạng thái đỏ**

```bash
(cd apps/admin && flutter test test/features/iam/presentation_module/widgets/organization_users_page_test.dart)
(cd apps/erp && flutter test test/features/iam/presentation_module/widgets/organization_users_page_test.dart)
```

Kỳ vọng: Admin vẫn còn lộ thao tác Invitation thông thường nên test fail; Tenant App có thể đã đáp ứng việc tách hai danh sách và không cần sửa code production.

- [ ] **Bước 3: Giới hạn giao diện Admin, giữ Tenant App**

Trong `OrganizationUsersPage` của Admin, gọi `loadMembers(reset: true)` thay cho `loadInitial()`, render `OrganizationUsersBody` chỉ có thành viên, bỏ callback `_navigateInvite` và `_openInvitation`. Trong body riêng của Admin, bỏ tham số constructor `onInviteTap`/`onInvitationTap`, tab “Lời mời”, nhánh filter/search Invitation và nút mời nổi. Trong `MemberListSection` của Admin, bỏ tham số `onInviteTap` và CTA “Mời thành viên” ở empty state; giữ danh sách và bộ lọc chỉ đọc. Sau khi sửa, chạy `rg -n 'OrganizationInviteMemberPage|OrganizationInvitationDetailPage|/more/users/invite|/more/users/invitations' apps/admin/lib` và xác nhận các page class còn lại không có điểm vào điều hướng từ Admin; không xóa các class đó trong thay đổi này. Không xóa `OrganizationInviteMemberPage`, tab Lời mời, `ResendInvitationCommand` hay `RevokeInvitationCommand` của Tenant App. Giữ action Owner ở Admin từ Task 7.

- [ ] **Bước 4: Chạy test xanh rồi commit**

```bash
(cd apps/admin && flutter test test/features/iam/presentation_module/widgets/organization_users_page_test.dart)
(cd apps/erp && flutter test test/features/iam/presentation_module/widgets/organization_users_page_test.dart)
git diff --check
git add apps/admin/lib/features/iam/presentation/users/views/organization_users_page.dart apps/admin/lib/features/iam/presentation/users/widgets/organization_users_body.dart apps/admin/lib/features/iam/presentation/users/widgets/member_list_section.dart apps/admin/test/features/iam/presentation_module/widgets/organization_users_page_test.dart apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart
git commit -m "refactor(iam): keep member invitations in tenant app"
```

---

### Task 9: Kiểm chứng toàn bộ vòng đời Theme 1 và reset DB local

**Tệp:**
- Chỉ kiểm chứng: tất cả tệp thay đổi ở Task 1–8 (gồm migration timestamp đã sửa in-place).

**Đầu vào/đầu ra:**
- Đầu vào: kết quả Task 1–8.
- Đầu ra: bằng chứng kiểm chứng cuối cùng; migration in-place đã nằm trong `supabase/migrations/`; người dùng `supabase db reset` để áp dụng schema mới. Không tạo `_drafts/`, không `migrate:promote-drafts`, không đổi `REGISTRY.yaml` (owner RPC giữ nguyên).

- [x] **Bước 1: Kiểm tra format của các tệp Dart đã sửa**

```bash
dart format --output=none --set-exit-if-changed \
  modules/iam/application/lib/src/platform/shared/tenant_onboarding_result_dto.dart \
  modules/iam/application/lib/src/platform/shared/onboarding_owner_input.dart \
  modules/iam/application/lib/src/platform/commands/create_tenant_onboarding/create_tenant_onboarding_command_handler.dart \
  modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command.dart \
  modules/iam/application/lib/src/platform/commands/reinvite_provisioning_owner/reinvite_provisioning_owner_command_validator.dart \
  modules/iam/application/lib/src/platform/queries/get_platform_tenant/platform_tenant_detail_dto.dart \
  modules/iam/application/lib/src/shared/tenant_readiness_issue_codes.dart \
  modules/iam/application/lib/src/testing/fake_iam_module.dart \
  modules/iam/application/test/fake_iam_module_test.dart \
  modules/iam/application/test/scn_e01_u03_fr01_01_create_tenant_onboarding_test.dart \
  modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart \
  modules/iam/infrastructure/test/iam_deferred_invitation_write_sql_contract_test.dart \
  modules/iam/infrastructure/test/iam_deferred_invitation_read_sql_contract_test.dart \
  modules/iam/infrastructure/test/iam_platform_user_invitation_visibility_sql_contract_test.dart \
  modules/iam/infrastructure/test/iam_provisioning_owner_readiness_sql_contract_test.dart \
  modules/iam/infrastructure/test/supabase_platform_admin_gateway_onboarding_test.dart \
  modules/iam/infrastructure/test/supabase_platform_admin_gateway_search_test.dart \
  apps/admin/lib/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart \
  apps/admin/lib/features/organizations/presentation/mappers/platform_tenant_ui_mapper.dart \
  apps/admin/lib/features/iam/presentation/organizations/widgets/owner_invitation_resend_sheet.dart \
  apps/admin/lib/features/organizations/presentation/pages/platform_tenant_detail_page.dart \
  apps/admin/lib/features/users/presentation/pages/platform_users_page.dart \
  apps/admin/lib/features/users/presentation/widgets/platform_users_filter_sheet.dart \
  apps/admin/lib/features/users/presentation/pages/platform_user_detail_page.dart \
  apps/admin/lib/features/users/presentation/bloc/platform_user_detail_state.dart \
  apps/admin/lib/features/iam/presentation/organizations/models/organization_ui_model.dart \
  apps/admin/lib/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart \
  apps/admin/lib/features/iam/presentation/organizations/views/organization_detail_page.dart \
  apps/admin/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart \
  apps/admin/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart \
  apps/admin/lib/features/iam/presentation/users/views/organization_users_page.dart \
  apps/admin/lib/features/iam/presentation/users/widgets/organization_users_body.dart \
  apps/admin/lib/features/iam/presentation/users/widgets/member_list_section.dart \
  apps/erp/lib/features/iam/presentation/readiness/tenant_readiness_cta_mapper.dart \
  apps/erp/lib/features/iam/presentation/readiness/widgets/tenant_readiness_issue_list.dart \
  apps/erp/lib/features/more/presentation/bloc/iam_feature_access_state.dart \
  apps/erp/test/features/iam/tenant_readiness_cta_mapper_test.dart \
  apps/admin/test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart \
  apps/admin/test/features/organizations/presentation/pages/organization_detail_page_test.dart \
  apps/admin/test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart \
  apps/admin/test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart \
  apps/admin/test/features/users/presentation/pages/platform_onboarding_page_test.dart \
  apps/admin/test/features/users/presentation/pages/platform_users_page_test.dart \
  apps/admin/test/features/users/presentation/pages/platform_user_detail_page_test.dart \
  apps/admin/test/features/users/presentation/bloc/platform_user_detail_cubit_test.dart \
  apps/admin/test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart \
  apps/admin/test/features/iam/presentation_module/widgets/organization_users_page_test.dart \
  apps/erp/test/features/iam/presentation_module/widgets/organization_users_page_test.dart
```

Mỗi task phải format tệp Dart mình sửa trước khi commit; bước kiểm tra chỉ đọc cuối cùng phải exit `0` và không format tệp không liên quan đang thay đổi trong worktree.

- [x] **Bước 2: Chạy các bộ test tập trung**

```bash
(cd modules/iam/application && dart test)
(cd modules/iam/infrastructure && dart test test/iam_deferred_invitation_write_sql_contract_test.dart test/iam_deferred_invitation_read_sql_contract_test.dart test/iam_platform_user_invitation_visibility_sql_contract_test.dart test/iam_provisioning_owner_readiness_sql_contract_test.dart test/iam_tenant_readiness_sql_contract_test.dart test/supabase_platform_admin_gateway_onboarding_test.dart test/supabase_platform_admin_gateway_search_test.dart)
(cd apps/admin && flutter test test/features/organizations/presentation/bloc/platform_onboarding_cubit_test.dart test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart test/features/organizations/presentation/pages/organization_detail_page_test.dart test/features/iam/presentation_module/widgets/organization_actions_bottom_sheet_test.dart test/features/iam/presentation_module/widgets/owner_invitation_resend_sheet_test.dart test/features/users/presentation/pages/platform_onboarding_page_test.dart test/features/users/presentation/pages/platform_users_page_test.dart test/features/users/presentation/pages/platform_user_detail_page_test.dart test/features/users/presentation/bloc/platform_user_detail_cubit_test.dart test/features/iam/presentation_module/readiness/tenant_readiness_page_test.dart test/features/iam/presentation_module/widgets/organization_users_page_test.dart)
(cd apps/erp && flutter test test/features/iam/tenant_readiness_cta_mapper_test.dart test/features/iam/presentation_module/widgets/organization_users_page_test.dart test/features/invitations/e2e_e03_u01_u06_test.dart)
```

Kỳ vọng: các bộ test tập trung đều pass. Đối chiếu từng dòng ma trận QA Theme 1 ở Task 1 với một test cụ thể và kết quả của nó; không suy diễn hành vi transaction DB chỉ từ SQL text-contract tests.

- [x] **Bước 3: Kiểm chứng workspace và chính sách migration**

```bash
melos run analyze
melos run test
melos run migrate:verify-policy -- --strict
bash scripts/ci/verify_harness.sh
bash scripts/ci/guard_docs_reference.sh
bash scripts/ci/guard_theme_structure.sh
git diff --check
```

Kỳ vọng: migration policy và `git diff --check` pass. Nếu baseline workspace còn lỗi đã biết, ghi chính xác package/guard nào fail và chứng minh từng test IAM/Admin/ERP tập trung ở Bước 2 xanh; không gọi bộ test tổng là pass nếu thực tế fail.

- [x] **Bước 4: Phân tích tác động thay đổi bằng GitNexus**

```bash
node .gitnexus/run.cjs detect-changes --scope all --repo .
```

Kỳ vọng: xem từng process bị ảnh hưởng được báo cáo. Nếu `partial: true` hoặc `truncated: true` thì chưa đủ dữ liệu; chạy lại với output đầy đủ trước khi kết luận. Báo người dùng trước khi tiếp tục nếu báo cáo cuối có rủi ro HIGH/CRITICAL.

- [ ] **Bước 5: Reset DB local và smoke runtime (người dùng / khi được phép)**

Xác nhận không còn tệp `_drafts/` mới của slice này; `REGISTRY.yaml` không cần cập nhật vì đã sửa đúng file owner. Khi người dùng sẵn sàng:

```bash
supabase db reset
# hoặc stack local tương đương đã đồng bộ với supabase/migrations/
```

Sau reset, chạy các kịch bản chấp nhận trực tiếp trên DB: gửi Owner/Member Invitation (không tạo profile/Membership trước accept), accept, gửi lại cùng email/đổi email, từ chối token cũ, hiển thị Platform User/thành viên và chặn kích hoạt khi lời mời đang chờ/đã hết hạn. Agent không tự promote draft; không tạo migration timestamp mới.

---

## Tự rà soát

- Độ phủ đặc tả: lời mời thành viên, onboarding Owner ban đầu, gửi lại cùng email/đổi email, accept, Admin projection, danh sách/chi tiết Platform User, Owner readiness, phân quyền UI Admin/Tenant, QA Theme 1, tương thích decline/revoke/expiry, idempotency và reset DB local đều có task phụ trách.
- Quét placeholder: các bước triển khai có tên tệp, symbol, assertion, mẫu SQL và lệnh cụ thể; không còn dấu nhắc triển khai chưa xác định.
- Nhất quán kiểu dữ liệu: chữ ký command/gateway/RPC công khai và kiểu trường DTO hiện có không đổi; `ownerMembershipId`/`ownerUserId` vẫn là `String?`; detail của Owner pending có `ownerUserId` null, `List<PlatformTenantMemberDto>` rỗng và metadata Invitation mới nullable.
- Nhất quán UI: chỉ hai bottom sheet PA-SG-02 cần thêm/sửa; `settingUp` chỉ thấy “Gửi lại email” trong sheet “Thao tác”, “Tạm ngừng tổ chức” vẫn ẩn; `active`/`suspended` không thấy gửi lại email, vẫn có đổi chủ sở hữu; không đổi banner, nền trang và nút “Thao tác” hiện có.
- Nhất quán migration: sửa in-place đúng file REGISTRY — bốn write RPC (`20260916004`, `20260916005`, `20260916006`, `20260911006`), hai tenant read (`20260911003`, `20260811010`), hai Platform User read (`20260911002`), một readiness (`20260811016`). Không tạo `_drafts/`; không đổi owner trong `REGISTRY.yaml`; áp dụng bằng `supabase db reset`.
