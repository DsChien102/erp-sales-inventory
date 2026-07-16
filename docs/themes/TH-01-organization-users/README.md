# TH-01: Tổ chức & người dùng

**Trạng thái deliver:** `interim` — IAM đang implement trong `modules/iam/`; Epic/US tree đã phân rã từ Theme spec (chưa có harness/).

Tenant, user, role, phân quyền và nền tảng truy cập đa tenant cho toàn bộ ERP. Trên UI, Tenant hiển thị là **Tổ chức**.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| iam | **Owner** — auth, tenant, membership, RBAC catalogue | `modules/iam/` ([README](../../../modules/iam/README.md)) |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| **Product spec (canonical)** | [Theme-1-organization-users.md](Theme-1-organization-users.md) |
| Overviews | [OVERVIEWS.md](OVERVIEWS.md) |
| Appendices | [APPENDICES.md](APPENDICES.md) |
| Module map | [02-module-map.md](02-module-map.md) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US specs | Status |
| ---- | ------ | -------- | ------ |
| EP-01 — Platform onboarding & activate | [Epic-01-platform-onboarding/](Epic-01-platform-onboarding/) | [US-01](Epic-01-platform-onboarding/US-01.md) … [US-05](Epic-01-platform-onboarding/US-05.md) | planned |
| EP-02 — Tổ chức & lịch sử quản trị | [Epic-02-tenant-administration/](Epic-02-tenant-administration/) | [US-01](Epic-02-tenant-administration/US-01.md) … [US-10](Epic-02-tenant-administration/US-10.md) | planned (US-04/05 Post-MVP) |
| EP-03 — Thành viên & lời mời | [Epic-03-membership-invitation/](Epic-03-membership-invitation/) | [US-01](Epic-03-membership-invitation/US-01.md) … [US-06](Epic-03-membership-invitation/US-06.md) | planned |
| EP-04 — Vai trò & quyền | [Epic-04-roles-permissions/](Epic-04-roles-permissions/) | [US-01](Epic-04-roles-permissions/US-01.md) … [US-03](Epic-04-roles-permissions/US-03.md) | planned |
| EP-05 — Tenant context | [Epic-05-tenant-context/](Epic-05-tenant-context/) | [US-01](Epic-05-tenant-context/US-01.md) … [US-04](Epic-05-tenant-context/US-04.md) | planned |
| EP-06 — Tài khoản của tôi | [Epic-06-my-account/](Epic-06-my-account/) | [US-01](Epic-06-my-account/US-01.md) … [US-04](Epic-06-my-account/US-04.md) | planned (derived from TA-SG-10) |

## Quy ước ID

```text
TH-01 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
```

- **US** = một file markdown `US-{nn}.md` trong folder epic (FR table + Scenarios + Design Reference).
- **SCN** = scenario Gherkin trong US.
- **FR** = functional requirement checklist — section 2 trong file US.
- UI Screen Groups: canonical §5; US chỉ link Design Reference.

Harness (`harness/00..07`) — phase sau, khi bắt đầu slice implement.
