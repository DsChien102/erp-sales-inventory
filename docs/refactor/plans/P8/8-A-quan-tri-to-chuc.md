# 8-A — Quản trị tổ chức cho Platform Admin (app)

> Phase: P8 · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: 8.1, 8.2, 8.3, 8.5 (phần DB 8.4, 8.6 → [8-B](8-B-db-ki08-don-luong-cu.md), làm cùng đợt kiểm IAM)
> Đặc tả: [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) EP-09 (US-09.2…09.4), ID-31…ID-33, BR-12, BR-13, BR-32; [LUONG-UNG-DUNG](../../../02-yeu-cau/LUONG-UNG-DUNG.md) mục 2, 3 (G5, G7), 6; [ADMIN-SCREENS](../../ADMIN-SCREENS.md); bảng thiết kế "Vị trí quản trị tổ chức trong app ERP" (A1, A2, C1–C7).

## 1. Mục tiêu

Phương án A (chốt 2026-10-09): Platform Admin quản lý tổ chức ngay trong `apps/erp`, không có khu `/admin`.

```text
Tab Thêm ▸ QUẢN TRỊ NỀN TẢNG ▸ Tổ chức ─┐
/no-organization ▸ "Quản trị nền tảng" ─┴▶ C1 /more/platform/organizations
                                            └▶ C2 /more/platform/organizations/:id
                                                 └▶ C3 sheet Thao tác
                                                      ├▶ C4 Tạm ngừng / Khôi phục / Đóng (lý do *)
                                                      └▶ C5 /more/platform/organizations/:id/owner ▶ C6 xác nhận
```

Chỉ hiện với Platform Admin; người khác gõ route → `/` (guard G7). RPC vẫn tự kiểm `has_platform_permission` (BR-60).

**Không làm ở đây:** sửa RPC chuyển Owner (KI-08), xoá onboarding / `provisioning`, FK `memberships.user_id` → 8-B. Tổng quan, người dùng nền tảng, nhật ký nền tảng → bỏ (2026-10-09).

## 2. Hiện trạng

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| RPC (schema `iam`, đã có, cấp cho `authenticated`, tự kiểm quyền nền tảng) | `search_platform_tenants(p_query, p_status, p_readiness_state, p_warning_code, p_cursor, p_page_size) → jsonb` · `get_platform_tenant(p_tenant_id) → jsonb` · `list_platform_tenant_members(p_tenant_id) → table` · `suspend_platform_tenant(p_tenant_id, p_reason, p_expected_version, p_idempotency_key)` · `restore_platform_tenant(p_tenant_id, p_expected_version, p_idempotency_key)` · `close_platform_tenant(p_tenant_id, p_reason, p_expected_version, p_idempotency_key)` · `transfer_platform_tenant_ownership(p_tenant_id, p_new_owner_user_id, p_expected_version, p_idempotency_key)` · `has_platform_permission(p_permission) → boolean` | Migration `20260811003`, `…010`, `…011`, `…012`, `20260911003` |
| Ánh xạ JSON (chép từ đây) | `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart`: gọi RPC dòng ~265–410; `_mapTenantSummary` (~535), `_mapTenantDetail` (~550), `_mapTenantMember*` (~603–625) | Bỏ field onboarding / readiness |
| Cubit cũ | `apps/admin/lib/features/organizations/presentation/bloc/platform_tenants_cubit.dart`, `platform_tenant_detail_cubit.dart` | Chép logic, đổi sang repository |
| Màn cũ | `apps/admin/lib/features/organizations/presentation/pages/{organizations_page, platform_tenant_detail_page}.dart` | |
| Widget đã có sẵn trong `erp` (chưa có route) | `apps/erp/lib/features/iam/presentation/organizations/{views/organization_detail_page, views/organization_change_owner_page, widgets/organization_*}.dart` | Thiếu `organization_close_confirmation_bottom_sheet.dart` (chép từ `apps/admin`) |
| Widget của **cửa hàng** trong cùng thư mục — giữ nguyên ở `features/iam` | `select_organization_bottom_sheet`, `confirm_switch_organization_bottom_sheet`, `organization_empty_view` | Dùng cho chọn tổ chức / ID-09 |
| Guard | `core/router/route_guard.dart` G1, G2, G5, G6 | Thêm G7 + ngoại lệ G5 |
| Tạo Platform Admin | `tools/vet45_env` (`vet45 admin create`, `supabase_admin_client.dart`) | `seed.sql` chưa có admin mẫu |

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/features/platform_admin/data/platform_tenant_repository.dart` | Tạo | 7 hàm RPC (Bước 2) |
| `lib/features/platform_admin/data/models/*.dart` | Tạo | `PlatformTenantSummary`, `PlatformTenantDetail`, `PlatformTenantMember`, `CursorPage` (dùng lại của `iam/data` nếu đủ) |
| `lib/features/platform_admin/logic/` | Tạo | `PlatformTenantsCubit`, `PlatformTenantDetailCubit`, `ChangeOwnerCubit` (+ state) |
| `lib/features/platform_admin/presentation/` | Chuyển từ `features/iam/presentation/organizations/` + `apps/admin` | Trang C1, C2, C5; sheet C3, C4 (tạm ngừng / khôi phục / đóng), C6 |
| `lib/core/session/session_controller.dart`, `session_state.dart`, `session_repository.dart` | Sửa | `isPlatformAdmin` |
| `lib/core/router/route_guard.dart`, `session_refresh.dart`, `app_router.dart` | Sửa | Route `/more/platform/**`, G7, ngoại lệ G5 |
| `lib/features/more/presentation/pages/more_page.dart` | Sửa | Nhóm "Quản trị nền tảng" (A1) |
| `lib/features/auth/presentation/pages/no_organization_page.dart` | Sửa | Nút "Quản trị nền tảng" (A2) |
| `supabase/seed.sql`, `README` / `RUNBOOK` | Sửa | Admin mẫu cho local; cách dùng `vet45 admin create` (8.5) |

## 4. Các bước

### Bước 1 — Nhận biết Platform Admin (8.1)

1. `SessionRepository.hasPlatformPermission(String permission)` → `iam.has_platform_permission(p_permission)` (scalar bool).
2. `SessionState.isPlatformAdmin` (mặc định `false`). `SessionController`:
   - sau khi `signedIn` (cả bootstrap có tổ chức lẫn không có tổ chức): gọi `hasPlatformPermission('platform.tenant.read')` một lần, emit `isPlatformAdmin`; lỗi → `false` (không chặn đăng nhập);
   - reset `false` khi đăng xuất / đổi user (state mới — đã có từ 2-A3).
3. `session_refresh.dart`: thêm `isPlatformAdmin` vào bộ khoá `distinct` (guard chạy lại khi cờ đổi).
4. Test: user là admin → cờ `true`; RPC lỗi → `false`; đổi user → `false`.

### Bước 2 — `PlatformTenantRepository` (8.2)

```dart
Future<CursorPage<PlatformTenantSummary>> search({String? query, String? status, String? cursor, int limit = 20});
Future<PlatformTenantDetail> get(String tenantId);                 // chi tiết + version
Future<List<PlatformTenantMember>> listMembers(String tenantId);
Future<void> suspend(String tenantId, {required String reason, required int expectedVersion, required String idempotencyKey});
Future<void> restore(String tenantId, {required int expectedVersion, required String idempotencyKey});   // RPC không nhận lý do — xem Bước 5.3
Future<void> close(String tenantId, {required String reason, required int expectedVersion, required String idempotencyKey});
Future<void> transferOwnership(String tenantId, {required String newOwnerUserId, required int expectedVersion, required String idempotencyKey});
```

- `search`: luôn gửi đủ 6 tham số (PostgREST khớp theo bộ tham số); `p_readiness_state`, `p_warning_code` = `null`; `p_status` ∈ `active | suspended | closed` hoặc `null`.
- Model chép từ `_mapTenantSummary`, `_mapTenantDetail`, `_mapTenantMember*`; **bỏ** field readiness / onboarding / lời mời Owner / `version` hiển thị (vẫn giữ `version` để gửi `p_expected_version`).
- Không cần `tenantId` callback (Platform Admin không thao tác trong tổ chức đang chọn).
- Test `fromJson` 3 model; `search` gửi đủ tham số.

### Bước 3 — Cubit (8.2)

Chép logic từ `apps/admin/.../platform_tenants_cubit.dart`, `platform_tenant_detail_cubit.dart`:

- `PlatformTenantsCubit`: tìm (debounce như cũ), chip trạng thái **Tất cả / Đang hoạt động / Tạm ngừng / Đã đóng**, tải thêm theo `nextCursor`, trống / lỗi / không quyền. **Bỏ** bộ lọc "Mức hoàn thiện".
- `PlatformTenantDetailCubit`: tải chi tiết + thành viên; `suspend / restore / close(reason)` với `idempotencyKey` sinh 1 lần cho mỗi lần mở sheet (dùng `IdempotencyKeyFactory`); sau thao tác tải lại chi tiết; `STATE_CHANGED` → "Dữ liệu đã thay đổi. Vui lòng tải lại rồi xác nhận lại."
- `ChangeOwnerCubit`: danh sách thành viên **đang hoạt động** trừ Owner hiện tại, tìm tên / email, chọn 1, `transferOwnership`; lỗi `OWNER_TARGET_INVALID` → "Không thể chọn thành viên này." (8-B sẽ thêm mã cho trường hợp đã là Owner nơi khác).
- Thông điệp thành công (TH-01 US-09.3, 09.4): "Đã tạm ngừng tổ chức thành công.", "Đã khôi phục tổ chức thành công.", "Đã đóng tổ chức.", "Đã chuyển quyền sở hữu."

### Bước 4 — Màn (8.2) theo khung C1–C6

Chuyển `features/iam/presentation/organizations/{views/organization_detail_page, views/organization_change_owner_page, widgets/organization_{actions_bottom_sheet, card_item, change_owner_confirmation_bottom_sheet, detail_*, filter_*, list_content, restore_confirmation_bottom_sheet, search_bar, suspend_confirmation_bottom_sheet}}.dart` sang `features/platform_admin/presentation/` (`git mv`); chép thêm `organization_close_confirmation_bottom_sheet.dart` và trang danh sách từ `apps/admin`. Sửa theo [ADMIN-SCREENS](../../ADMIN-SCREENS.md) mục 1:

- **C1** `PlatformOrganizationsPage`: tiêu đề "Tổ chức" (phụ đề "Quản trị nền tảng"), ô "Tìm tên hoặc mã tổ chức", 4 chip, thẻ: tên, trạng thái, mã, Chủ sở hữu, số thành viên. Trống "Chưa có tổ chức" (**không** có "Khởi tạo tổ chức").
- **C2** chi tiết: thẻ đầu, "Chủ sở hữu", "Thành viên tổ chức", "Thông tin nền tảng" (Ngày đăng ký, Hoạt động gần nhất, Tạm ngừng / Đóng lúc, Lý do, Người thực hiện); cảnh báo "Quyền vận hành đã bị chặn…" / "Tổ chức đã đóng vĩnh viễn". **Bỏ** "Phiên bản dữ liệu", "Kích hoạt lúc", cảnh báo email / lời mời Owner, "Hồ sơ cơ bản chưa hoàn thiện". Nút "Thao tác" (ẩn khi `closed`).
- **C3** sheet: Tạm ngừng (khi `active`), Khôi phục (khi `suspended`), Đóng (khi `active` / `suspended`), Thay đổi chủ sở hữu (khi `active` / `suspended`). **Bỏ** "Gửi lại email".
- **C4** sheet xác nhận (3 biến thể, lý do bắt buộc "Vui lòng nhập lý do."), chuỗi theo TH-01 US-09.3.
- **C5** chọn Owner mới: Owner hiện tại hiện mờ "Chủ sở hữu hiện tại · không chọn được"; "Vai trò hiện hành của thành viên sẽ được giữ nguyên."; trống "Chưa có thành viên đang hoạt động".
- **C6** xác nhận: 2 ô "Chủ sở hữu hiện tại" → "Chủ sở hữu mới"; câu "`<Owner cũ>` vẫn giữ vai trò Chủ cửa hàng. `<tên>` tiếp tục giữ vai trò `<vai trò>`. Thay đổi có hiệu lực ở yêu cầu tiếp theo." (sửa câu "Bạn vẫn giữ…" của app cũ).

### Bước 5 — Lối vào, route, guard (8.3)

1. `more_page.dart`: nhóm "QUẢN TRỊ NỀN TẢNG" (chỉ khi `isPlatformAdmin`) ▸ "Tổ chức — Tạm ngừng, khôi phục, đóng, chuyển chủ sở hữu" → `/more/platform/organizations` (A1).
2. `no_organization_page.dart`: nút "Quản trị nền tảng" (chỉ khi `isPlatformAdmin`) giữa "Nhập mã lời mời" và "Đăng xuất" (A2).
3. Lý do khôi phục: RPC `restore_platform_tenant` **không có** `p_reason` nhưng TH-01 US-09.3 FR-03 yêu cầu "Lý do *". Làm theo RPC (không có ô lý do khi khôi phục) và ghi vào Review; 8-B quyết định có thêm `p_reason` không.
4. `app_router.dart`: 3 route `/more/platform/organizations`, `/:id`, `/:id/owner`.
5. `route_guard.dart`:
   - **G7**: không phải Platform Admin + `location` bắt đầu `/more/platform` → `/`.
   - **G5** (không có tổ chức → `/no-organization`): thêm ngoại lệ `/more/platform/**` khi `isPlatformAdmin`.
6. Test guard: G7 (thường / admin), G5 ngoại lệ (admin không tổ chức ở `/more/platform/organizations` → ở lại; người thường không tổ chức ở đó → `/no-organization`).

### Bước 6 — Tạo Platform Admin (8.5)

1. `supabase/seed.sql` (chỉ local): thêm 1 admin mẫu (`admin@local.test`) vào `auth.users` (đã xác minh) + `iam.platform_admins`; ghi mật khẩu mẫu trong README local.
2. `docs/refactor/RUNBOOK-email.md` hoặc README gốc: mục "Tạo Platform Admin" — `vet45 admin create --email …` cho Dev / Prod (tool có sẵn, không viết script mới).

### Bước 7 — Dọn chỗ cũ

- Xoá các file đã `git mv` khỏi `features/iam/presentation/organizations/` (giữ 3 widget của cửa hàng ở mục 2). Không xoá `apps/admin` (P9).
- `grep -rn "organizations/views\|organization_detail_page" lib/features/iam` → chỉ còn widget cửa hàng.

### Bước 8 — Commit

Gợi ý: (1) `isPlatformAdmin` + guard; (2) repository + cubit; (3) màn + lối vào; (4) seed / README.

## 5. Kiểm tra

- [ ] `dart analyze lib test`: không error / warning mới. `check_feature_imports`: 0 vi phạm (feature `platform_admin` chỉ dùng `data/` của feature khác nếu cần).
- [ ] `flutter test` toàn `apps/erp`: không lỗi mới so với 2-B4 (1.419 pass / 61 fail).
- [ ] Kiểm tay — gom vào **đợt kiểm IAM** (cần Platform Admin trên Dev: `vet45 admin create`):
  - [ ] Người thường: tab Thêm không có "Quản trị nền tảng"; gõ `/more/platform/organizations` → `/`.
  - [ ] Admin có cửa hàng: tab Thêm có nhóm mới → danh sách → chi tiết.
  - [ ] Admin không có cửa hàng: `/no-organization` có nút "Quản trị nền tảng".
  - [ ] Tạm ngừng tổ chức (lý do) → Owner / thành viên thấy ID-09 ở thao tác kế tiếp → Khôi phục → dùng lại được → Đóng → không còn "Khôi phục".
  - [ ] Chuyển Owner cho thành viên khác → tổ chức đúng 1 Owner; Owner cũ mất hub "Người dùng & vai trò".
- [ ] CHECKLIST: ID-31, ID-32, ID-33, ID-x7 ghi "(b) xong 8-A".

## 6. Rủi ro / lưu ý

- `has_platform_permission` chỉ nhận mã bắt đầu `platform.`; trả `false` cho người bị tạm ngừng.
- Chuyển Owner chưa chặn người nhận đã là Owner nơi khác (KI-08) — cho tới 8-B, tránh thử trường hợp này trên Dev.
- Hai nhóm widget tổ chức dùng chung tên `Organization*`: để không nhầm, widget chuyển sang `platform_admin` đổi tiền tố thành `PlatformOrganization*` khi tiện (không bắt buộc).

## 7. Review

<!-- Claude ghi sau khi bạn code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
