# 8-B — DB: chặn chuyển Owner sai (KI-08), dọn luồng onboarding cũ, FK thành viên (KI-03)

> Phase: P8 · Trạng thái: Plan 📝 (khung — viết chi tiết khi tới đợt kiểm IAM) | Làm 🔄 (mục 1, 2 xong; 3–6 để đợt kiểm IAM) | Review ⬜
> Gồm việc: 8.4, 8.6. Làm **sau 8-C, 8-D**, cùng đợt kiểm IAM (cần `db push` lên Dev); mọi migration đặt timestamp sau `20261009005`.
>
> **Cập nhật 2026-10-11 (quyết định làm gọn IAM, Claude):**
> 1. **KI-08 phải là migration mới**, không sửa thẳng `20260811012` (Dev đã áp file đó → `db push` bỏ qua; Prod dựng mới sẽ khác Dev). Việc: trả `20260811012_iam_platform_transfer_ownership.sql` về nguyên bản (`git checkout HEAD -- …`), chép thân hàm đã sửa sang `20261011001_iam_transfer_owner_ki08.sql` (`Kind: patch`, `Depends on: 20260811012`), giữ test SQL `iam_transfer_ownership_other_owner.sql` và phần app (`ChangeOwnerCubit`).
> 2. **Mục 3–6 làm luôn trong 8-B** (không đợi P9): sau 8-D không còn `apps/admin` / `modules/iam` gọi các RPC cũ.
> 3. Thêm index duy nhất `memberships (user_id) where is_owner and removed_at is null` (khoá BR-07 ở DB) vào cùng migration với mục 5, sau khi đếm vi phạm.
> Đặc tả: TH-01 BR-07, BR-32, BR-35, KI-03, KI-05, KI-08, mục 8.

## 1. Phạm vi

| # | Việc | Ghi chú |
|---|---|---|
| 1 | **KI-08**: `transfer_platform_tenant_ownership` chặn người nhận **đã là Owner tổ chức khác** (`memberships.is_owner` + `removed_at is null` ở tenant khác) → mã mới `OWNER_TARGET_ALREADY_OWNER`; app (8-A `ChangeOwnerCubit`) map thông điệp "Người này đã là chủ sở hữu của một tổ chức khác." | Hàm ở `20260811012_iam_platform_transfer_ownership.sql`; chép nguyên, chỉ thêm kiểm |
| 2 | (Tuỳ chọn) `restore_platform_tenant` nhận `p_reason` để khớp TH-01 US-09.3 FR-03 (lý do bắt buộc khi khôi phục) — hoặc sửa TH-01 bỏ yêu cầu | Quyết định khi viết chi tiết |
| 3 | **KI-05 (DB)**: xoá `create_tenant_onboarding`, `reinvite_provisioning_owner`, `send_activation_invitation`, `resend_owner_activation`, `get_tenant_readiness`, `activate_tenant`, `bootstrap_owner`, `*_owner_activation`, `_unwind_provisioning_owner_membership`, `platform_identity_create_pending_user_for_onboarding`, `resolve_or_create_platform_user_for_onboarding`, trigger `trg_cleanup_pending_profile`; bảng `onboarding_operations`, `owner_activations`; nhánh Owner cũ trong `accept_invitation` / `decline_invitation` | Chỉ sau khi `apps/admin` không còn dùng (P8-A xong); kiểm grep app không còn gọi |
| 4 | Bỏ trạng thái `provisioning` (tenants) và `pending_activation` (platform_user_profiles): dọn dữ liệu cũ trên Dev, sửa check constraint | Dữ liệu Dev là dữ liệu thử |
| 5 | **KI-03**: FK `memberships.user_id → auth.users(id)` (sau khi xoá membership "giữ chỗ" không có user) | Đếm bản ghi mồ côi trước |
| 6 | App: bỏ `TenantStatus.provisioning` và nhánh `isSelectable` cho provisioning ở `core/session` | Sau mục 4 |

## 2. Thứ tự dự kiến

1. Kịch bản SQL kiểm tra (đếm mồ côi, tenant `provisioning`, profile `pending_activation`) chạy trên Dev trong `begin … rollback`.
2. Migration KI-08 (+ mục 2 nếu chọn).
3. Migration dọn dữ liệu + xoá RPC / bảng / trigger cũ + đổi constraint.
4. Migration FK.
5. App: mục 6; map mã `OWNER_TARGET_ALREADY_OWNER`.
6. Push cùng đợt kiểm IAM; kiểm tay kịch bản TH-01 9.3 số 6.

## 3. Review

### Ghi chú triển khai (2026-10-11)

| # | Trạng thái | Chi tiết |
|---|---|---|
| 1 KI-08 | ✅ viết, **chưa áp lên Dev** | Sửa thẳng `supabase/migrations/20260811012_iam_platform_transfer_ownership.sql` (không tạo migration mới; REGISTRY giữ nguyên). Thêm 2 kiểm sau kiểm thành viên: người nhận phải **đang hoạt động** (`is_active` và `removed_at is null`, BR-32) → `OWNER_TARGET_INVALID`; người nhận không được là Owner tổ chức khác (`is_owner` và `removed_at is null`, cùng điều kiện `_create_tenant_for_owner`) → `OWNER_TARGET_ALREADY_OWNER`. **Dev đã áp bản cũ của file này nên `db push` không áp lại** — cần chạy lại thân hàm trên Dev (SQL editor / `vet45 supabase -- db query`) hoặc `migration repair` + push. Kiểm thử: `supabase/tests/iam_transfer_ownership_other_owner.sql` — **chưa chạy**. App: `ChangeOwnerCubit` map mã mới thành "Người này đã là chủ sở hữu của một tổ chức khác." (+ test) |
| 2 Lý do khôi phục | ✅ chốt: bỏ yêu cầu | Giữ RPC không `p_reason`; sửa TH-01 BR-13, US-09.3 FR-03 và `ADMIN-SCREENS` M6c. 8-A đã làm đúng như vậy |
| 3–6 | ⬜ làm sau 8-D (lúc đó không còn code gọi RPC cũ), cùng đợt kiểm IAM | Trước đây chặn bởi `apps/admin` và `modules/iam` cũ còn gọi RPC; mục 3 phải kèm sửa `accept_invitation` / `decline_invitation` (chép lại thân hàm), mục 4–5 cần số liệu Dev |

Lưu ý còn lại cho mục 5 (KI-03): index duy nhất theo người (`memberships (user_id) where is_owner and removed_at is null`) sẽ khoá BR-07 ở mức DB và đóng khe race của hai lần chuyển Owner đồng thời; thêm cùng đợt dọn dữ liệu, sau khi đếm bản ghi vi phạm trên Dev.

<!-- Claude ghi phần dưới sau khi bạn review / kiểm tay -->
