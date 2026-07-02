# TH-01 — Business scope

## Purpose

Thiết lập cửa hàng (tenant), tài khoản người dùng, thành viên, vai trò và phân quyền — nền tảng IAM cho mọi theme nghiệp vụ.

## In scope (interim)

- Đăng nhập / đăng xuất ERP qua `IIamModule`
- Tenant context (`IExecutionContext`, `ITenantAccessChecker`)
- Permission catalogue và access metadata codegen
- Membership interim (tenant ↔ user)

## Out of scope (theme đầy đủ — sau)

- Cấu hình nghiệp vụ theo tenant (giá, thuế, catalog defaults) — thuộc module owner từng theme
- Onboarding wizard end-to-end

## Epic map (dự kiến)

| Epic | Mô tả |
| ---- | ----- |
| E1.1 Tenant & membership | Tạo tenant, mời thành viên |
| E1.2 RBAC | Role, permission assign |
| E1.3 Store settings shell | Entry point cấu hình (delegate module) |

**SRS:** chưa có — đang deliver theo [modules/iam/README.md](../../../modules/iam/README.md).
