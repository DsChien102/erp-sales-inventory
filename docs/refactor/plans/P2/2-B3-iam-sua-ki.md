# 2-B3 — Sửa các vấn đề đã biết của IAM (TH-01) và dọn readiness

> Phase: P2 · Bước (b) sửa / tính năng mới · Trạng thái: Plan ✅ | Làm ✅ | Review ✅ (2026-10-12)
> Gồm việc: TH-01 mục 9.2 (KI-02, KI-06, KI-10…KI-14, phần app của KI-05), 2B.6 "bỏ readiness", US-07.1; góp ý còn treo của 2-B1 (#1) và 2-B2 (#1, #2)
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) 3.4, 7.3, US-06.1…06.6, US-07.1, BR-31, BR-33, BR-36, BR-44, BR-55, BR-66

Xong plan này là **luồng IAM phía cửa hàng đủ để kiểm một lượt** (cùng việc còn treo của 2-B1, 2-B2: push migration, config, deploy function).

## 1. Phạm vi và một quyết định cần bạn xác nhận

| KI | Nội dung | Ở plan này? |
|---|---|---|
| KI-02 | `accept_invitation` insert membership mới cho người đã bị loại → trùng khoá | ✅ Sửa DB |
| KI-06 | Hub có mục "Quyền sở hữu" chỉ báo "Chức năng làm sau" | ✅ |
| KI-10 | Xem trước đổi vai trò có "Quyền được thêm / bị gỡ"; danh mục vai trò có "N quyền" | ✅ |
| KI-11 | Bộ lọc thành viên dùng "Quản trị / Bán hàng / Kế toán" | ✅ |
| KI-12 | Gửi lại mã đặt lại mật khẩu đếm 45 giây (server chặn 60) | ✅ |
| KI-13 | "Mã kích hoạt" lẫn với "mã lời mời" | ✅ |
| KI-14 | Ngày giờ giả, câu kỹ thuật, chữ "Membership", "Phiên bản dữ liệu" | ✅ |
| KI-05 (app cửa hàng) | Màn readiness `/more/readiness`, sheet "Kích hoạt tổ chức?", nhãn "Đang khởi tạo" ở hồ sơ tổ chức | ✅ |
| US-07.1 | Mục "Vai trò" trong hub đang "Chức năng làm sau"; trang vai trò có sẵn nhưng không có route | ✅ Nối dữ liệu thật |
| **KI-03** | FK `memberships.user_id → auth.users` | ⏭ **Đề xuất dời sang P3** |
| **KI-05 (DB + màn platform)** | Xoá `create_tenant_onboarding`, `owner_activations`, `*_owner_activation`, `bootstrap_owner`, `activate_tenant`, `get_tenant_readiness`, trạng thái `provisioning` / `pending_activation`; màn platform (`organizations/*`, "Mức hoàn thiện", "Khởi tạo tổ chức"…) | ⏭ **Đề xuất dời sang P3** |

**Vì sao dời KI-03 và phần DB của KI-05 sang P3:** `apps/admin` (còn dùng tới P3) vẫn gọi `create_tenant_onboarding`, luồng này tạo membership Owner "giữ chỗ" khi người đó **chưa có** `auth.users` (FK bị bỏ ở `20260911004` chính vì vậy). Thêm FK hoặc xoá RPC bây giờ sẽ làm hỏng `apps/admin` và dữ liệu `provisioning` cũ trên Dev, trong khi không ảnh hưởng luồng cửa hàng mới (2-B1 luôn có `auth.users` trước khi tạo membership). P3 dựng `/admin` mới và bỏ `apps/admin`, nên dọn DB ở đó gọn nhất. TH-01 7.3 ghi KI-03 / KI-05 phase "P2" → nếu bạn đồng ý, sửa cột Phase thành "P3" và thêm dòng vào PLAN P3.

> Nếu bạn muốn làm KI-03 ngay ở P2: thêm FK `not valid` (chặn dữ liệu mới, bỏ qua dữ liệu cũ) và chấp nhận "Tạo tổ chức" của `apps/admin` hỏng (đúng tinh thần BR-01). Báo Claude để sửa plan.

## 2. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `supabase/migrations/20261009005_iam_accept_invitation_reactivate_removed.sql` | Tạo | KI-02 |
| `supabase/migrations/20261009003_iam_email_jobs.sql` | **Sửa tại chỗ** (chưa push lên môi trường nào) | Thứ tự tên người mời; `UNKNOWN_TEMPLATE` hết lượt ngay (góp ý 2-B2) |
| `supabase/tests/iam_accept_invitation_reinvite.sql` | Tạo | Kịch bản SQL KI-02 |
| `lib/features/iam/presentation/readiness/` | Xoá | Màn readiness + cubit + widget |
| `lib/features/iam/data/models/tenant_readiness.dart`, `OrganizationRepository.getReadiness` | Xoá | |
| `lib/features/more/logic/iam_feature_access_*`, `users_and_roles_page.dart` | Sửa | Bỏ readiness, bỏ "Quyền sở hữu", nối "Vai trò" |
| `lib/core/router/app_router.dart` | Sửa | Bỏ `/more/readiness`; `/more/roles`, `/more/roles/:code` thành route thật |
| `lib/features/iam/logic/roles_cubit.dart` (+ state) | Tạo | Danh mục vai trò + số thành viên đang giữ |
| `lib/features/iam/presentation/roles/**` | Sửa | Bỏ "N quyền", dữ liệu thật |
| `lib/features/iam/presentation/users/**` | Sửa | KI-10, KI-11, KI-14 |
| `lib/features/iam/presentation/organization_profile/**` | Sửa | Bỏ sheet "Kích hoạt tổ chức?", nhãn "Đang khởi tạo" |
| `lib/features/iam/presentation/users/views/reset_password_page.dart` | Sửa | KI-12 |
| `lib/features/auth/presentation/**` | Sửa | KI-13; góp ý 2-B1 #1 |
| `lib/core/iam/iam_ui_failure_mapper.dart` | Sửa | Bỏ chuỗi readiness không còn dùng |
| Test | Sửa / tạo | xem Bước 9 |

## 3. Các bước

### Bước 1 — KI-02: mời lại người đã bị loại (DB)

Migration mới: chép **nguyên** `iam.accept_invitation` bản mới nhất (`20260916006_iam_patch_accept_invitation_default_store_scope.sql`), chỉ sửa nhánh `if not v_linked_existing` (chỗ `insert into iam.memberships`):

1. Trước khi insert, tìm bản ghi cũ của đúng người, đúng tổ chức:
   ```sql
   select * into v_membership
   from iam.memberships m
   where m.tenant_id = v_inv.tenant_id and m.user_id = v_caller
   for update;
   ```
2. Có bản ghi và `removed_at is not null` → **kích hoạt lại** (BR-44, BR-33):
   `update iam.memberships set is_active = true, removed_at = null, role = v_effective_role, is_owner = v_should_be_owner, version = version + 1, updated_at = v_now where id = v_membership.id returning * into v_membership;` (cột trạng thái tạm ngừng / lý do loại nếu có — xem `20260811014_iam_tenant_membership_lifecycle.sql` — đặt về null).
3. Có bản ghi đang `is_active` → giữ hành vi hiện tại (nhánh `v_linked_existing` / `DUPLICATE_MEMBERSHIP` như cũ).
4. Có bản ghi `is_active = false` và `removed_at is null` (đang tạm ngừng) → `raise exception 'MEMBERSHIP_INACTIVE'` (Owner phải kích hoạt lại, không dùng lời mời; khớp `create_tenant_invitation` đang chặn `MEMBERSHIP_INACTIVE`).
5. Không có → insert như cũ.
6. Phần còn lại (cập nhật lời mời, audit, idempotency) giữ nguyên; audit dùng `v_membership.id` của bản ghi đã kích hoạt lại.

Kiểm `create_tenant_invitation` (`20260916005`): đoạn tìm `v_existing_membership` chỉ xét `removed_at is null`, nên **mời được** người đã bị loại — không cần sửa.

Kịch bản `supabase/tests/iam_accept_invitation_reinvite.sql` (`begin … rollback`; đặt `request.jwt.claims` để giả `auth.uid()` như các test hiện có, hoặc gọi phần lõi qua user giả): tổ chức + Owner + nhân viên → loại nhân viên → mời lại → nhân viên chấp nhận → **1** bản ghi `(tenant_id, user_id)`, `is_active`, `removed_at is null`, vai trò mới, `is_owner = false`.

### Bước 2 — Sửa migration email (chưa push) — góp ý 2-B2

Trong `20261009003_iam_email_jobs.sql` (sửa thẳng file vì chưa áp lên môi trường nào):
1. `inviter_name`: `concat_ws(' ', family_middle_name, given_name)` → "Nguyễn Thị Lan".
2. `complete_email_job`: `p_error = 'UNKNOWN_TEMPLATE'` → đặt `attempts = 5`, `secret = null`, outcome `failed` ngay (không thử lại 5 lần vô ích).
3. Cập nhật `supabase/tests/iam_email_jobs.sql` cho trường hợp 2.

### Bước 3 — Bỏ readiness (KI-05 phần app, 2B.6)

1. Xoá `lib/features/iam/presentation/readiness/` và export trong `presentation.dart`.
2. `app_router.dart`: xoá route `/more/readiness` (route cuối cùng còn dùng `IIamModule` / `IExecutionContext` trong `app_router`).
3. `OrganizationRepository.getReadiness`, `data/models/tenant_readiness.dart`: xoá.
4. `IamFeatureAccessCubit` / state: bỏ `readinessStatus`, `readiness`, `canViewReadiness` và khối "Kích hoạt tổ chức để có thể bắt đầu vận hành." ở `users_and_roles_page.dart`.
5. Hồ sơ tổ chức: xoá `confirm_activate_organization_bottom_sheet.dart` và nút / luồng gọi nó; nhãn `TenantLifecycleStatus.provisioning => 'Đang khởi tạo'` ở `organization_profile_ui_mapper.dart` → bỏ nhánh (tổ chức cửa hàng không còn `provisioning`; giá trị lạ hiện như "Đang hoạt động" hoặc ẩn — chọn một, ghi vào Review).
6. `IamUiFailureMapper`: bỏ `readinessBlocked` nếu không còn nơi nào phát ra.
7. **Không** đụng `lib/features/iam/presentation/organizations/**`, `widgets/platform_onboarding_*` (màn platform, P3) và `TenantStatus.provisioning` ở `core/session` (DB còn có thể trả giá trị này tới P3).
8. Grep: `grep -rn "IIamModule\|IExecutionContext" lib/features/iam lib/features/more lib/core/router` → chỉ còn `presentation/testing/`.

### Bước 4 — Hub "Người dùng & vai trò" và trang Vai trò (KI-06, KI-10, US-07.1)

1. `users_and_roles_page.dart`: **xoá** mục "Quyền sở hữu"; mục "Vai trò" → `/more/roles` (bỏ toast "Chức năng làm sau").
2. `RolesCubit` (`features/iam/logic/`): tải `InvitationRepository.listAssignableRoles()` và `MemberRepository.listMembers(status: 'active', limit: 100)` (lặp `nextCursor` nếu còn); đếm thành viên theo `roleCode`. Mô tả vai trò lấy theo TH-01 3.4 (thêm `IamRoleLabelMapper.description(code)` cạnh `toDisplayLabel`).
3. `OrganizationRolesPage`: "Vai trò hệ thống", "`<n>` vai trò hệ thống", mỗi vai trò: tên, mô tả, nhãn "Đang dùng" khi có thành viên; câu "Vai trò vận hành không thay đổi tư cách Chủ sở hữu."; **bỏ** "· `<n>` quyền" và `permissionCount` khỏi `RoleUiModel`. Lỗi → "Không thể tải danh sách vai trò — Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau."
4. `OrganizationRoleDetailPage`: "Vai trò hệ thống · Chỉ đọc", mô tả, danh sách thành viên đang giữ vai trò; **bỏ** danh sách quyền.
5. `app_router.dart`: `/more/roles` → `OrganizationRolesPage`; chi tiết `/more/roles/:code` (giữ `/more/roles/detail` chuyển hướng về `/more/roles`). Guard quyền như các route hub khác (chỉ Owner).
6. `organization_preview_role_change_page.dart`: xoá 2 khối "Quyền được thêm", "Quyền bị gỡ"; thay bằng câu "Vai trò là nhãn công việc; quyền nghiệp vụ của thành viên không thay đổi." (US-06.5 FR-02). Xác nhận: "Đổi vai trò của `<tên>`? — Vai trò `<cũ>` → `<mới>`. Quyền mới có hiệu lực ở yêu cầu tiếp theo."
7. Dòng "Quyền sở hữu: Chủ sở hữu" ở trang chọn / xem trước vai trò: **giữ** (US-06.4 FR-01 vẫn có "Quyền sở hữu" trong chi tiết thành viên — đây là thông tin, không phải mục hub).

### Bước 5 — Danh sách và chi tiết thành viên (KI-11, KI-14)

1. `member_filter_bottom_sheet.dart`, `organization_users_state.dart`, `organization_users_cubit.dart`: vai trò lọc = "Tất cả" + 4 vai trò 3.4 (Chủ cửa hàng / Nhân viên bán hàng / Kế toán / Thủ kho). Lọc theo **mã vai trò** (`store_owner`…), không so chuỗi nhãn chứa từ khoá.
2. `member_detail_bottom_sheets.dart`: bỏ giá trị giả `'14/07/2026 · 09:30'`, `'14/07/2026 · 09:45'` (và tên giả nếu có) → thiếu dữ liệu hiện "—" (US-06.4 FR-05).
3. `member_detail_body.dart`: bỏ dòng "Phiên bản dữ liệu".
4. Chữ "Membership" trên UI: grep chuỗi hiển thị (bỏ qua tên class / mã lỗi) → thay theo TH-01; câu loại thành viên: "Loại thành viên khỏi tổ chức? — Thành viên sẽ kết thúc vĩnh viễn. Người này cần lời mời mới nếu quay lại." (US-06.6 FR-03).
5. `organization_invite_member_page.dart`: bỏ câu "Kiểm tra catalog iam.role_definitions trên DB rồi thử lại."; giữ "Không tải được danh sách vai trò" + "Thử lại" (US-06.2 FR-05).
6. Chi tiết thành viên: "Thay đổi vai trò — Cập nhật vai trò" (thay "Cập nhật quyền vận hành", US-06.4 FR-03).

### Bước 6 — Mật khẩu, lời mời, xác minh (KI-12, KI-13, góp ý 2-B1 #1)

1. `reset_password_page.dart`: `_secondsRemaining = 45` (2 chỗ) → 60; tốt hơn: một hằng `_resendCooldownSeconds = 60`.
2. `invitation_token_page.dart`, `invitation_confirm_bottom_sheet.dart`: "Mã kích hoạt" → "Mã lời mời" (3 chuỗi; thông điệp theo US-03.1). Grep thêm "kích hoạt" trong `features/auth` để không sót (giữ nút "Kích hoạt tài khoản" ở `/login` — đúng TH-01).
3. `VerifyEmailCubit`: thêm tham số `allowImmediateResend` (hoặc `initialCooldown`); `/verify-email` vào từ đăng nhập → gửi lại được ngay; bước 3 của `/signup` và lời mời giữ 60 giây.

### Bước 7 — Chữ còn lại trong vùng cửa hàng

Grep trong `lib/features/iam/presentation/{users,roles,organization_profile,audit_logs}`, `lib/features/more`, `lib/features/auth`: "Đang khởi tạo", "Đang thiết lập", "Kích hoạt tổ chức", "readiness", "Membership" (chuỗi hiển thị). Còn ở `organizations/`, `widgets/platform_*`, `testing/` thì để P3.

### Bước 8 — (nếu bạn đồng ý mục 1) Ghi quyết định dời KI-03 / KI-05-DB

- TH-01 7.3: cột Phase của KI-03 → "P3"; KI-05 → "P2 (app cửa hàng) / P3 (DB, platform)".
- PLAN P3: thêm dòng "KI-03 FK `memberships.user_id`; xoá onboarding cũ, owner activation, readiness RPC, `provisioning`, `pending_activation`".

### Bước 9 — Test

- `test/features/more/...iam_feature_access*`, `users_and_roles_page_test.dart`: bỏ readiness; không còn "Quyền sở hữu"; "Vai trò" điều hướng `/more/roles`.
- `test/features/iam/logic/roles_cubit_test.dart` (mới): đếm thành viên theo vai trò; lỗi → thông điệp US-07.1 AC-01.
- Widget trang vai trò: không có chữ "quyền" kiểu "N quyền"; có "Đang dùng".
- `organization_preview_role_change_page` test: không có "Quyền được thêm" / "Quyền bị gỡ"; có câu BR-55.
- Bộ lọc thành viên: lọc "Thủ kho" ra đúng thành viên `warehouse`.
- Chi tiết thành viên thiếu ngày tạm ngừng → "—", không có "14/07/2026".
- `reset_password_page` test: đếm 60 giây.
- `invitation_token_page` test: chuỗi "Mã lời mời …".
- `verify_email_cubit_test`: `allowImmediateResend` → `canResend` ngay.
- Xoá test readiness cũ.

### Bước 10 — Commit

Gợi ý: (1) DB KI-02 + sửa migration email; (2) bỏ readiness; (3) hub + vai trò; (4) thành viên / mật khẩu / lời mời / xác minh.

## 4. Kiểm tra

- [ ] Kịch bản SQL Bước 1 (và `iam_email_jobs.sql` sau Bước 2) — chạy cùng đợt với các kịch bản 2-B1 / 2-B2.
- [ ] `dart analyze lib test`: không error / warning mới. `check_feature_imports`: 0 vi phạm.
- [ ] Grep Bước 3.8, Bước 7.
- [ ] `flutter test` toàn `apps/erp`: không lỗi mới so với 2-B1 (1.424 pass / 61 fail; số pass thay đổi do xoá / thêm test — so theo danh sách fail).
- [ ] Kiểm tay: gom vào **đợt kiểm IAM** sau 2-B3 (TH-01 9.3 kịch bản 1–4).
- [ ] CHECKLIST: ghi chú ID-10, ID-14…ID-20 "(b) xong 2-B3"; tick "Mới" sau đợt kiểm.

## 5. Rủi ro / lưu ý

- **Chép `accept_invitation`**: hàm dài, nhiều nhánh (Owner cũ, `target_membership_id`, idempotency). Chỉ sửa đúng nhánh insert; so diff với `20260916006` trước khi xong (Claude sẽ diff khi review).
- Kích hoạt lại bản ghi cũ giữ nguyên `memberships.id` → lịch sử / chứng từ cũ vẫn trỏ đúng người (đúng ý BR-44).
- Bỏ readiness: `TenantStatus.provisioning` vẫn còn ở `core/session` và `AccessibleTenant.isSelectable` cho tới P3 — cố ý.
- Trang vai trò đếm thành viên phía app (tối đa vài trăm người / tổ chức) — đủ cho đồ án; nếu cần RPC riêng thì để sau.

## 6. Review

- Ngày, commit được review: 2026-10-09, working tree trên `78952e915` (chưa commit).
- Kết quả: **Code đạt; phần DB chờ đợt kiểm IAM** → Review 🔄 (cùng 2-B1, 2-B2).
  - **Quyết định mục 1** đã áp dụng: TH-01 7.3 KI-03 → P3, KI-05 tách P2 (app) / P3 (DB, platform); PLAN thêm 3.6.
  - **KI-02** (`20261009005`): so với `20260916006` chỉ khác đúng nhánh insert — tìm bản ghi `(tenant, user)` `for update`; đã loại → kích hoạt lại cùng `id` (`is_active`, `removed_at = null`, vai trò mới, `version + 1`, `status_changed_at`); đang hoạt động → `DUPLICATE_MEMBERSHIP`; tạm ngừng → `MEMBERSHIP_INACTIVE`; chưa có → insert. Quyền giữ như bản gốc. Kịch bản `iam_accept_invitation_reinvite.sql` có, chưa chạy.
  - **Migration email** (sửa tại chỗ, chưa push): tên người mời "họ đệm + tên"; `UNKNOWN_TEMPLATE` → `attempts = 5`, xoá `secret`, outcome `failed` ngay; `retry_email_jobs` không còn chọn job này. Test SQL bổ sung trường hợp.
  - **Readiness**: xoá màn, cubit, widget, model, `getReadiness`, sheet "Kích hoạt tổ chức?", nhãn "Đang khởi tạo" ở vùng cửa hàng. 4 file test bị xoá đều chỉ test readiness (kể cả `tenant_admin/e2e_e01_u04_u05_test.dart`).
  - **Hub / vai trò**: bỏ "Quyền sở hữu"; "Vai trò" → `/more/roles` (chỉ Owner) với `RolesCubit` (vai trò + thành viên đang giữ, lặp hết `nextCursor`); bỏ "N quyền"; chi tiết `/more/roles/:code`. Xem trước đổi vai trò dùng câu BR-55.
  - **KI-11 / 12 / 13 / 14**, góp ý 2-B1 #1 (`allowImmediateResend` khi vào từ đăng nhập): đúng plan. Grep chuỗi cũ trong vùng cửa hàng: chỉ còn "Kích hoạt tổ chức" là tên sự kiện audit `iam.tenant.activated` (cần giữ để đọc lịch sử cũ).
  - `IIamModule` / `IExecutionContext`: hết trong `features/iam` (trừ `testing/`) và `features/more`. `app_router.dart` còn `IExecutionContext` ở 12 route catalog / partner / einvoice — ngoài IAM (lệnh grep Bước 3.8 của plan viết quá rộng).
  - `dart analyze lib test`: không error; warning duy nhất có từ trước. `check_feature_imports`: 0 vi phạm.
  - `flutter test` toàn `apps/erp`: **1.404 pass / 61 fail**; danh sách fail trùng khớp 2-B1; số pass giảm do xoá test readiness và thêm test mới (vai trò, bộ lọc, ngày thiếu).
- Góp ý (không chặn):
  1. `RolesCubit` suy ra mã vai trò từ **nhãn** (`IamRoleLabelMapper.toRoleCode(label)`) vì `list_assignable_invitation_roles` chỉ trả `role_id`, `label`. Đổi nhãn trong `role_definitions` là hỏng đếm. Khi đụng RPC này lần sau (vd P3), cho trả thêm `code`.
  2. Route vai trò kiểm `getIt<IamSession>().isOwner`; nên dùng `SessionController.isOwner` cho đồng nhất với các phần đã chuyển (đổi khi dọn `IamSession` ở P9).
- **Đợt kiểm IAM** (gộp việc còn lại của 2-B1, 2-B2, 2-B3), theo thứ tự:
  1. Chạy 3 kịch bản SQL cùng 5 migration `20261009001…005` trong `begin … rollback` trên Dev (Claude chạy khi bạn đồng ý).
  2. `db push` 5 migration → `config push` (bật xác minh email) → secrets + Vault (`RUNBOOK-email.md`) → `functions deploy send-email`.
  3. Kiểm tay TH-01 9.3 kịch bản 1–4 (mail thật sau khi có tên miền).

### Cập nhật 2026-10-12 — đợt kiểm IAM

- `db reset --linked` trên Dev (sau bản sửa `activated_at`) rồi chạy 4 kịch bản trong SQL Editor — `iam_signup_trigger`, `iam_email_jobs`, `iam_accept_invitation_reinvite`, `iam_legacy_cleanup`: **cả 4 không raise** (người dùng chạy, 2026-10-12).
- KI-02 đạt trên DB thật (`iam_accept_invitation_reinvite.sql`): mời lại người đã bị loại dùng lại đúng bản ghi thành viên, kích hoạt lại, vai trò mới, không phải Owner. `iam_legacy_cleanup.sql` phần lời mời nhân viên cũng đạt.
- Phần app đã đạt ở review trước → **Review ✅**. Kiểm tay TH-01 9.3 kịch bản 3–4 và tick CHECKLIST làm cùng đợt kiểm tay (không chặn).
