# 8-B — DB: chặn chuyển Owner sai (KI-08), dọn luồng onboarding cũ, FK thành viên (KI-03)

> Phase: P8 · Trạng thái: Plan 📝 (khung — viết chi tiết khi tới đợt kiểm IAM) | Làm ⬜ | Review ⬜
> Gồm việc: 8.4, 8.6. **Làm cùng đợt kiểm IAM** (bước 7 trong thứ tự PLAN), vì cần `db push` lên Dev; migration đặt timestamp sau `20261009005`.
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

<!-- Claude ghi sau khi bạn code xong -->
