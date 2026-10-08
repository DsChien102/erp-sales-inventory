# 2-A2 — Chuyển IAM: thành viên, lời mời, vai trò, nhật ký quản trị

> Phase: P2 · Bước (a) chuyển kiến trúc · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: 2B.6 (phần còn lại, trừ phiên / đăng nhập → 2-A3)
> Tài liệu liên quan: [PLAN.md](../../PLAN.md) P2; [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) ID-10, ID-14…ID-20; mẫu: [2-A1](2-A1-iam-tai-khoan-to-chuc.md)

## 1. Mục tiêu

Các màn quản trị thành viên trong tổ chức chạy theo `Page → Cubit (logic/) → Repository (data/) → RPC`, không còn `IIamModule` / `IExecutionContext`:

| Màn (TH-01) | Route | Cubit / nguồn |
|---|---|---|
| ID-10 Hub Người dùng & vai trò | `/more/users-and-roles` | `IamFeatureAccessCubit` (feature `more`) |
| ID-14 Người dùng (Thành viên / Lời mời) | `/more/users` | `OrganizationUsersCubit` |
| ID-15 Mời thành viên | `/more/users/invite` | `OrganizationInviteMemberCubit` + `IamModuleInvitationRoleOptionsSource` |
| ID-16 Chi tiết lời mời | `/more/users/invitations/:id` (+ `/invitation-detail`) | `OrganizationInvitationDetailCubit` |
| ID-17 Chi tiết thành viên | `/more/users/members/:id` (+ `/member-detail`) | `OrganizationMemberDetailCubit` |
| ID-18 Chọn vai trò → Xem trước | `/more/users/select-role`, `/preview-role-change` | (dùng `OrganizationMemberDetailCubit`) |
| ID-19 Vai trò | `/more/roles`, `/more/roles/detail` | (màn tĩnh / danh mục vai trò) |
| ID-20 Lịch sử quản trị | `/more/audit-logs`, `/:id` | `TenantAuditLogsCubit` |

**Không đổi hành vi.** Các sửa TH-01 cho nhóm này (KI-02 mời lại người đã bị loại, KI-06 bỏ mục "Quyền sở hữu", KI-10 bỏ "Quyền được thêm / bị gỡ", KI-11 bộ lọc vai trò, KI-13 "mã lời mời", KI-14 dữ liệu giả) để **2-B2**.

## 2. Hiện trạng: Command/Query → RPC (schema `iam`)

| Cubit | Command / Query | Gateway cũ (chép mapping từ đây) | RPC |
|---|---|---|---|
| `OrganizationUsersCubit` | `ListTenantMembersQuery` | `domain/access/supabase_iam_access_gateway.dart` | `list_tenant_members` |
| | `ListInvitationsQuery` (handler có lọc thêm bằng `contains`) | `domain/invitation/supabase_tenant_invitation_read_port.dart` | `list_tenant_invitations` |
| `OrganizationMemberDetailCubit` | `GetTenantMemberQuery` | `domain/membership/supabase_tenant_membership_read_gateway.dart` | `get_tenant_member` |
| | `AssignMemberRoleCommand` | `domain/access/supabase_iam_access_gateway.dart` | `assign_member_role` |
| | `Deactivate…` / `Reactivate…` / `RemoveMembershipCommand` | `domain/membership/supabase_tenant_membership_command_gateway.dart` | `deactivate_membership`, `reactivate_membership`, `remove_membership` |
| `OrganizationInviteMemberCubit` | `CreateInvitationCommand` (có `idempotencyKey`) | `domain/invitation/supabase_tenant_invitation_command_gateway.dart` | `create_tenant_invitation` |
| `IamModuleInvitationRoleOptionsSource` | `ListAssignableInvitationRolesQuery` | `adapters/invitation/supabase_assignable_invitation_role_read_port.dart` | `list_assignable_invitation_roles` |
| `OrganizationInvitationDetailCubit` | `GetInvitationQuery`, `ResendInvitationCommand`, `RevokeInvitationCommand` | `…invitation_read_port.dart`, `…invitation_command_gateway.dart` | `get_tenant_invitation`, `resend_tenant_invitation`, `revoke_tenant_invitation` |
| `TenantAuditLogsCubit` | `SearchTenantAuditLogsQuery`, `GetTenantAuditLogQuery` | `adapters/audit/supabase_tenant_audit_read_port.dart` | `search_tenant_audit_logs`, `get_tenant_audit_log` |
| `IamFeatureAccessCubit` (`features/more`) | `GetCurrentSessionQuery`, `GetTenantReadinessQuery` | `domain/tenant/supabase_tenant_readiness_gateway.dart` | (phiên) + `get_tenant_readiness` |

Đường dẫn gateway tính từ `modules/iam/infrastructure/lib/src/`. **Trước khi viết repository, mở handler tương ứng** trong `modules/iam/application/lib/src/` để chép phần xử lý ngoài gateway (vd `ListInvitationsQueryHandler` lọc theo từ khoá; handler nào sinh `idempotencyKey` hay kiểm rule thì chuyển vào repository hoặc cubit).

Test liên quan: grep `OrganizationUsersCubit|OrganizationMemberDetailCubit|OrganizationInviteMemberCubit|OrganizationInvitationDetailCubit|TenantAuditLogsCubit|IamFeatureAccessCubit` trong `apps/erp/test` (khoảng 10–15 file, phần lớn dùng `FakeIamModule` / `RecordingIamModule`).

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/features/iam/data/member_repository.dart` | Tạo | `listMembers`, `getMember`, `assignRole`, `deactivate`, `reactivate`, `remove` |
| `lib/features/iam/data/invitation_repository.dart` | Tạo | `listInvitations`, `getInvitation`, `create`, `resend`, `revoke`, `listAssignableRoles` |
| `lib/features/iam/data/audit_log_repository.dart` | Tạo | `search`, `getDetail` |
| `lib/features/iam/data/organization_repository.dart` | Sửa | thêm `getReadiness()` (`get_tenant_readiness`) — dùng tạm đến 2-B2 bỏ readiness |
| `lib/features/iam/data/models/*.dart` | Tạo | model cho thành viên, lời mời, vai trò mời được, nhật ký (giữ tên field DTO cũ) |
| `lib/features/iam/logic/` | Chuyển từ `presentation/users/bloc/`, `presentation/audit_logs/bloc/` | 5 cubit + state |
| `lib/features/more/logic/` | Chuyển từ `presentation/bloc/` | `IamFeatureAccessCubit` + state |
| `lib/features/iam/presentation/users/iam_module_invitation_role_options_source.dart` | Thay | `InvitationRoleOptionsSource` dùng `InvitationRepository` (đổi tên file bỏ chữ `module`) |
| Page / view các route ở mục 1 | Sửa | Nhận repository; `SessionController` khi cần |
| `lib/core/router/app_router.dart`, `lib/core/di/injection.dart` | Sửa | Truyền / đăng ký repository |
| Test liên quan | Sửa / chuyển | Mock repository thay `FakeIamModule` |

## 4. Các bước

### Bước 1 — Model

Tạo trong `lib/features/iam/data/models/`, chép `fromJson` theo đúng mapper của gateway ở mục 2:

- `TenantMember`, `TenantMemberDetail` (thông tin người dùng, vai trò, trạng thái, `version`…).
- `TenantInvitation`, `TenantInvitationDetail` (email, vai trò, trạng thái, thời hạn, người mời…).
- `AssignableInvitationRole` (mã, nhãn).
- `TenantAuditLogPage` (`items`, `totalCount`, `nextCursor`), `TenantAuditLogItem`, `TenantAuditLogDetail` (chép `_mapSubject`, `_asJsonMap`, `TenantAuditLogResultCodes.fromCode` — nếu enum nằm ở application cũ, chép sang `logic/` hoặc `data/models/`).
- `TenantReadiness` (đúng các field `IamFeatureAccessCubit` đang đọc).

Ưu tiên giữ tên class gần DTO cũ để cubit / widget sửa ít (có thể `typedef XxxDto = Xxx;` tạm trong barrel nếu nhiều widget tham chiếu tên cũ — ghi `TODO(P9)` xoá typedef).

### Bước 2 — Repository

Tất cả nhận `SupabaseRpc` + `Future<String> Function() tenantId` (= `SessionController.requireTenantId`).

```dart
class MemberRepository {
  Future<List<TenantMember>> listMembers({/* tham số lọc như query cũ */});
  Future<TenantMemberDetail> getMember(String membershipId);
  Future<TenantMemberDetail> assignRole(String membershipId, String roleCode, {required int expectedVersion});
  Future<void> deactivate(String membershipId, {required int expectedVersion /* + lý do nếu có */});
  Future<void> reactivate(String membershipId, {required int expectedVersion});
  Future<void> remove(String membershipId, {required int expectedVersion});
}

class InvitationRepository {
  Future<List<TenantInvitation>> listInvitations({/* lọc */});
  Future<TenantInvitationDetail> getInvitation(String invitationId);
  Future<TenantInvitationDetail> create({required String email, required String roleCode, required String idempotencyKey /* + trường khác */});
  Future<TenantInvitationDetail> resend(String invitationId, {required int expectedVersion});
  Future<void> revoke(String invitationId, {required int expectedVersion});
  Future<List<AssignableInvitationRole>> listAssignableRoles();
}

class AuditLogRepository {
  Future<TenantAuditLogPage> search({DateTime? from, DateTime? to, String? category, String? result, String? actor, String? subject, String? keyword, String? cursor, int limit = 20});
  Future<TenantAuditLogDetail> getDetail(String auditLogId);
}
```

Chữ ký cụ thể (tên tham số, kiểu trả về) **lấy đúng theo gateway cũ** — bảng trên chỉ là khung. RPC `search_tenant_audit_logs` có 9 tham số `(uuid, timestamptz, timestamptz, text, text, text, text, text, integer)` (migration `20260811013`).

- `idempotencyKey` của lời mời: nếu handler cũ sinh UUID thì giữ nguyên chỗ sinh (cubit hoặc repository) và ổn định qua lần bấm lại như cũ.
- Lỗi: để `SupabaseRpc` ném `AppException`; cubit vẫn `IamUiFailureMapper.from(e)` (đã hiểu `AppException` từ 2-A1).

### Bước 3 — Cubit sang `logic/`

`git mv` 5 cubit + state (users, member detail, invite member, invitation detail, audit logs) vào `lib/features/iam/logic/`; `IamFeatureAccessCubit` + state vào `lib/features/more/logic/`. Với từng cubit: constructor nhận repository thay `IIamModule` / `IExecutionContext`; mỗi `executeXAsync(...)` → một hàm repository; giữ nguyên state, thứ tự emit, xử lý lỗi.

`IamFeatureAccessCubit`:
- `GetCurrentSessionQuery` → đọc `SessionController` (`hasPermission`, `state.current?.isOwner`, vai trò…) — xem cubit đang đọc field nào của `SessionDto` và lấy tương ứng từ `SessionController` / `IamSession` qua accessor (thêm accessor vào `SessionController` nếu thiếu, vd `role`, `isOwner`).
- `GetTenantReadinessQuery` → `OrganizationRepository.getReadiness()` (giữ nguyên đến 2-B2 bỏ readiness).

### Bước 4 — Nguồn vai trò mời được

`iam_module_invitation_role_options_source.dart` → đổi thành `invitation_role_options_source.dart` (hoặc giữ tên, đổi ruột) dùng `InvitationRepository.listAssignableRoles()`. Giữ nguyên interface mà `OrganizationInviteMemberCubit` / màn chọn vai trò đang dùng.

### Bước 5 — Page, router, DI

1. Các page / view ở mục 1 nhận repository (+ `SessionController` nếu cần), tạo cubit bằng `BlocProvider(create:)`.
2. `users_and_roles_page.dart`, `more_page.dart`: tạo `IamFeatureAccessCubit` với `SessionController` + `OrganizationRepository`.
3. `injection.dart`: `registerLazySingleton` `MemberRepository`, `InvitationRepository`, `AuditLogRepository`.
4. `app_router.dart`: các route ở mục 1 truyền repository; giữ nguyên route trùng (`/more/users/member-detail`, `/invitation-detail`, `/more/audit-logs/detail`) — gộp ở 2-B2.
5. Grep: `grep -rn "IIamModule\|IExecutionContext" lib/features/iam lib/features/more` → chỉ còn ở `presentation/testing/` (fake cũ) và `readiness/` (màn readiness cũ, 2-B2 xoá). Ghi rõ phần còn lại trong mục Review.

### Bước 6 — Test

1. Test cubit: chuyển vào `test/features/iam/logic/` (và `test/features/more/logic/`), thay `FakeIamModule` / `RecordingIamModule` bằng mock repository (mocktail); giữ kịch bản và kỳ vọng.
2. Widget / e2e test dựng page hoặc router: truyền mock repository / đăng ký getIt mới.
3. Test mới tối thiểu: `fromJson` của `TenantMemberDetail`, `TenantInvitationDetail`, `TenantAuditLogPage` (có `next_cursor`, `before_state` rỗng); `AuditLogRepository.search` truyền đúng 9 tham số (mock `SupabaseRpc`).

### Bước 7 — Commit

Gợi ý 3 commit: (1) thành viên + vai trò (member detail, select role, preview); (2) lời mời (users list, invite, invitation detail, role options); (3) nhật ký + feature access.

## 5. Kiểm tra

- [ ] `dart analyze` các file đổi / mới: không issue.
- [ ] `dart run tool/check_feature_imports.dart`: 0 vi phạm.
- [ ] Grep bước 5.5 như ghi chú.
- [ ] `flutter test test/core test/features/iam test/features/more test/features/tenant_admin`: không lỗi ngoài baseline.
- [ ] `flutter test` toàn bộ `apps/erp`: không lỗi mới so với [TEST-BASELINE.md](../../TEST-BASELINE.md).
- [ ] Kiểm tay trên Dev (tài khoản Owner):
  - [ ] Hub "Người dùng & vai trò" mở được; người không có quyền thấy đúng như cũ.
  - [ ] Danh sách thành viên / lời mời, tìm, lọc.
  - [ ] Mời một email (vai trò "Nhân viên") → lời mời xuất hiện; gửi lại, thu hồi. (Email lời mời **không tới** vì worker đã bỏ — 2-B2.)
  - [ ] Chi tiết thành viên: đổi vai trò (chọn → xem trước → xác nhận), tạm ngừng, kích hoạt lại.
  - [ ] Lịch sử quản trị: thấy các thao tác vừa làm, mở chi tiết, tải thêm trang.
- [ ] CHECKLIST: ghi chú "(a) xong 2-A2" cho ID-10, ID-14…ID-20; **tick "Mới" sau 2-B2** (theo góp ý review 2-A1).

## 6. Rủi ro / lưu ý

- **Lọc ở handler**: `ListInvitationsQueryHandler` có lọc phía app (`contains`); nếu bỏ sót, danh sách lời mời sẽ khác. Đọc kỹ từng handler trước khi viết repository.
- **Mã lỗi ở đầu chuỗi**: `AppException` chỉ nhận mã ở đầu message (mapper IAM cũ tìm ở bất kỳ đâu). Trước khi xong, grep `raise exception` trong migration của các RPC ở mục 2 (`20260811014_iam_tenant_membership_lifecycle.sql`, `…017/018/019_iam_tenant_invitation_*`, `20260811013_iam_platform_audit_read.sql`, `20260820005_iam_assign_member_role_fix.sql`, `20260811022_…`) và ghi các câu không theo dạng mã vào mục Review (giống cách review 2-A1).
- `IamFeatureAccessCubit` quyết định ai thấy mục "Người dùng & vai trò": đọc sai field phiên là ẩn / hiện nhầm cả hub. Viết test cho cả Owner và thành viên thường.
- `RecordingIamModule`, `FakeIamModule` (testing cũ) vẫn còn cho phần chưa chuyển; không xoá ở plan này.
- Không có GitNexus; phạm vi theo grep: 5 cubit IAM + 1 cubit `more` (~1.400 dòng), ~10 route, ~10–15 file test.

## 7. Review

<!-- Claude ghi sau khi bạn code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
