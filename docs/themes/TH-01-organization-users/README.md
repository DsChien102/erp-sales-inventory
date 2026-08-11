# TH-01: Tổ chức & người dùng

**Trạng thái deliver:** `in_progress` — Epic/US tree + harness scaffold; IAM interim trong `modules/iam/`.

Tenant, user, role, phân quyền và nền tảng truy cập đa tenant cho toàn bộ ERP. Trên UI, Tenant hiển thị là **Tổ chức**.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| iam | **Owner** — auth, tenant, membership, invitation, RBAC, context | `modules/iam/` ([README](../../../modules/iam/README.md)) |
| Notification (Resend) | Supporting — email delivery | contract `S-NOTIFY` — [harness/03](harness/03-architecture-and-flows.md) |
| apps/erp | Tenant App | `apps/erp` |
| apps/admin | Platform Admin App | `apps/admin` (S15 wired via `IIamModule`) |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| **Product spec (canonical)** | [Theme-1-organization-users.md](Theme-1-organization-users.md) |
| Overviews | [OVERVIEWS.md](OVERVIEWS.md) |
| Appendices | [APPENDICES.md](APPENDICES.md) |
| **Harness (agent/engineer)** | [harness/](harness/) |
| Module map | [harness/02-module-map.md](harness/02-module-map.md) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US specs | Status |
| ---- | ------ | -------- | ------ |
| EP-01 — Platform onboarding & activate | [Epic-01-platform-onboarding/](Epic-01-platform-onboarding/) | [US-01](Epic-01-platform-onboarding/US-01.md) … [US-05](Epic-01-platform-onboarding/US-05.md) | S15 done (US-01–03); US-04/05 planned |
| EP-02 — Tổ chức & lịch sử quản trị | [Epic-02-tenant-administration/](Epic-02-tenant-administration/) | [US-01](Epic-02-tenant-administration/US-01.md) … [US-10](Epic-02-tenant-administration/US-10.md) | planned (US-04/05 Post-MVP) |
| EP-03 — Thành viên & lời mời | [Epic-03-membership-invitation/](Epic-03-membership-invitation/) | [US-01](Epic-03-membership-invitation/US-01.md) … [US-06](Epic-03-membership-invitation/US-06.md) | planned |
| EP-04 — Vai trò & quyền | [Epic-04-roles-permissions/](Epic-04-roles-permissions/) | [US-01](Epic-04-roles-permissions/US-01.md) … [US-03](Epic-04-roles-permissions/US-03.md) | planned |
| EP-05 — Tenant context | [Epic-05-tenant-context/](Epic-05-tenant-context/) | [US-01](Epic-05-tenant-context/US-01.md) … [US-04](Epic-05-tenant-context/US-04.md) | planned |
| EP-06 — Tài khoản của tôi | [Epic-06-my-account/](Epic-06-my-account/) | [US-01](Epic-06-my-account/US-01.md) … [US-04](Epic-06-my-account/US-04.md) | planned |

Slice order: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) (S0, S-NOTIFY, S1…).

## Quy ước ID

```text
TH-01 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
```

- **US** = một file `US-{nn}.md` trong folder epic.
- **SCN** = scenario Gherkin trong US.
- UI Screen Groups: canonical §5; US chỉ link Design Reference.

## Kiến trúc chốt (harness)

- **Email:** Resend qua Notification boundary — [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md)
- **Invitation confirmation:** Email chỉ chứa opaque token và hướng dẫn tự mở app khi đang đăng xuất. User copy/paste token; API nhận token trong JSON body; không URL/query/deep-link token.

## Agent prompt mẫu

```text
Implement TH-01 slice S2 (EP-05/US-02) per docs/themes/TH-01-organization-users/Epic-05-tenant-context/US-02.md.
Read README → harness/04-slice-roadmap.md → harness/07-api-contracts.md §S2 → harness/01-domain-model.md.
Golden module: modules/iam/.
Verify: melos run test && ./scripts/ci/verify_harness.sh
```
