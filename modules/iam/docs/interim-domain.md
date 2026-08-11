# IAM interim domain (Phase 2)

Temporary contracts until SRS Theme 1 (full store provisioning + role management).

## Permission codes

Định nghĩa **một lần** trong domain — không hardcode string trong application/infrastructure/tests:

| Constant (`vet45_iam_domain`) | Code | Granted to | Use case |
| ----------------------------- | ---- | ---------- | -------- |
| `IamPermissions.membersRead` | `iam.members.read` | `staff` | `ListTenantMembers` |
| `IamPermissions.membersAssignRole` | `iam.members.assign_role` | `owner` only (via RPC) | `AssignMemberRole` |

`@RequiresPermission`, `@ModuleManifest`, tests và seed phải tham chiếu constant — xem `modules/iam/domain/lib/src/iam_permissions.dart`.

`owner` role bypasses permission checks in `iam.has_permission` RPC.

## Roles

| Role | Notes |
|------|-------|
| `owner` | Full tenant control; only owners may call `assign_member_role` |
| `staff` | Baseline permissions from `iam.role_permissions` seed |

`AssignMemberRole` validator allows only `owner` and `staff`.

## RPC defense

- `list_tenant_members` — caller must be a member of the tenant
- `assign_member_role` — caller must be `owner` of the tenant
- `get_session_context(tenant_id)` — explicit tenant switch requires membership

## Legacy bootstrap

`bootstrap_owner` has been removed from the app contract and from the IAM
foundation schema. Tenant provisioning now belongs to formal onboarding/store
provisioning flows.

## Cross-module permission placeholders (temporary)

IAM **enforce** mọi permission qua `iam.role_permissions` / `IamPermissionChecker`, nhưng **không sở hữu** permission code của module khác. Trong giai đoạn interim, các string sau được khai báo tạm ở IAM vì Partner/Settings chưa bật codegen:

| Permission | Constant (interim) | Hiện khai báo tại | Chuyển sang (khi module có codegen) |
| ---------- | ------------------ | ----------------- | ----------------------------------- |
| `partner.read`, `partner.write` | `InterimPermissionCodes.*` | `IamModuleDefinition`, `supabase/seed.sql` | `PartnerPermissions` trong `modules/partner/domain/` |
| `settings.einvoice.configure` | `InterimPermissionCodes.settingsEinvoiceConfigure` | `IamModuleDefinition`, `supabase/seed.sql` | module Settings tương ứng |

`iam_module_manifest.g.dart` merge manifest + `@RequiresPermission` trên handler — các permission cross-module **không** đến từ handler IAM, chỉ từ khai báo tay trên.

**Dọn dẹp (tracked in [PROGRESS.md](../../../docs/harness/PROGRESS.md) Phase 2):**

1. Bật `module_manifest` builder trên module sở hữu nghiệp vụ.
2. Xóa permission đó khỏi `IamModuleDefinition`; IAM manifest chỉ giữ `iam.*`.
3. Chạy `melos run codegen`.
4. Giữ hoặc chuyển seed `iam.role_permissions` — catalog runtime vẫn nằm trong schema `iam`, nhưng định nghĩa string thuộc module owner.

## Align later (SRS Theme 1)

- Full aggregates (Tenant, Membership, Role catalog)
- Keep tenant provisioning in formal onboarding/store provisioning flows
- `strict_access_metadata: true` on IAM codegen
- Integration events + messaging worker install
- Hoàn tất permission manifest ownership (mục trên)
