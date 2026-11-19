# TH-01 — Overviews

**Canonical:** [Theme-1-organization-users.md](Theme-1-organization-users.md) §1 · Domain/Data: §2–§3

## Purpose

Theme 1 thiết lập nền móng **Tổ chức** (domain: Tenant), người dùng và phân quyền cho Mosaic Retail: Membership, lời mời, system role, ownership, Tenant context, readiness; đồng thời cung cấp actor/authorization context cho Theme 2–12.

Hai application surface:

1. **Tenant App** — Owner / quản trị / thành viên (TenantContext)
2. **Platform Admin App** — System Admin / Platform Operator (PlatformAdminContext; không cần Membership Tenant đích)

Theme 1 không sở hữu credential/session authority; self-service profile fields do IAM sở hữu còn identity/session authority thuộc Supabase Auth.

## Business context

Tenant là ranh giới dữ liệu/quyền/cấu hình/giao dịch của một đơn vị kinh doanh — **không** đồng nhất Store, Warehouse hay pháp nhân. Phase 1: Tenant user không tự tạo Tenant; System Admin provision Owner + Tenant `provisioning`; Owner hoàn thiện readiness và activate.

## In scope (MVP — tóm tắt)

| Nhóm | Nội dung |
| ---- | -------- |
| Platform User | Tạo pending, activation invite, suspend/restore, khởi tạo password-reset (không đặt credential) |
| Tenant lifecycle | provisioning → active → suspended; nhận diện closed read-only |
| Hồ sơ | Tenant profile + current Legal Profile; TenantReadiness; activate |
| Membership / Invitation | Invite email, resend/revoke, accept/decline; active/inactive/removed |
| Role | Bốn system role cố định; đổi role Membership; catalog read-only |
| Context | TenantContext, PlatformAdminContext, chuyển tổ chức, LastSelectedTenant |
| Audit | Query IAM audit (`iam.audit_logs`) cho tenant / platform scope |
| My Account | Profile, password reset, logout qua Identity |

Chi tiết: [Theme-1-organization-users.md](Theme-1-organization-users.md) §1.3.

## Out of scope (MVP — tóm tắt)

- Credential / MFA / impersonation / bulk import
- Tenant tự tạo / transfer ownership / close (Post-MVP; giữ EP-02/US-04–05)
- Custom role, multi-role Membership, permission override, role `OWNER`
- Hard delete lifecycle; multi-company; Store/Warehouse mặc định khi tạo Tenant

Chi tiết: [Theme-1-organization-users.md](Theme-1-organization-users.md) §1.4.

## Cross-theme boundaries

Theme 1 cung cấp Tenant/actor/Membership/role context; **không** truy vấn bảng nghiệp vụ Theme khác. Supabase Auth / Authorization / IAM audit / Notification / Preference là capability được tham chiếu — xem bảng đầy đủ §1.5 canonical.

## Users & roles

| Actor | Scope | Authorization |
| ----- | ----- | ------------- |
| Mosaic Retail System Admin | Platform | Platform permissions |
| Platform Operator | Platform | Platform permissions (+ step-up khi policy) |
| Platform User | Platform | Identity |
| Tenant Owner | Một Tenant | `is_owner` + Membership role |
| Tenant Admin / member | Một Tenant | Membership role permissions |

Owner **không** phải system role. Chi tiết: §1.6 canonical.

## Epic map

| Epic | Folder | Mục tiêu |
| ---- | ------ | -------- |
| EP-01 | [Epic-01-platform-onboarding](Epic-01-platform-onboarding/) | Platform User, khởi tạo Tenant/Owner, readiness & activate |
| EP-02 | [Epic-02-tenant-administration](Epic-02-tenant-administration/) | Hồ sơ, Legal Profile, lifecycle nền tảng, audit |
| EP-03 | [Epic-03-membership-invitation](Epic-03-membership-invitation/) | Thành viên & lời mời |
| EP-04 | [Epic-04-roles-permissions](Epic-04-roles-permissions/) | Role catalog & gán role |
| EP-05 | [Epic-05-tenant-context](Epic-05-tenant-context/) | Chọn/chuyển tổ chức & context safety |
| EP-06 | [Epic-06-my-account](Epic-06-my-account/) | Tài khoản của tôi (Identity) |

## Domain & data

Không tách file riêng trong bước này. Đọc:

- Domain foundation: [Theme-1-organization-users.md](Theme-1-organization-users.md) §2
- Data & entities: §3
- Appendix (API, events, permissions): [APPENDICES.md](APPENDICES.md)
