# TH-03: Khách hàng & NCC

**Trạng thái deliver:** `in_progress` (reboot greenfield — harness v2 synced 2026-07-07)

## Mục tiêu

Quản lý hồ sơ đối tác (khách hàng, nhà cung cấp, hoặc cả hai) làm lớp dữ liệu nền cho bán hàng, nhập hàng, hóa đơn, công nợ và tra cứu lịch sử giao dịch.

**Domain model v2:** Partner (root) + Person/Organization (profile type) + Customer/Supplier (transaction role) + OrganizationContact + soft delete (`active`/`inactive`/`deleted`).

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| partner | **Owner** — greenfield, chờ rebuild | `modules/partner/` (chưa có) |
| iam | Supporting — auth, tenant, permission | `modules/iam/` |
| sales | Supporting — snapshot, publish transaction events | `modules/sales/` |
| inventory | Supporting — publish inbound events | `modules/inventory/` |
| accounting | Supporting — publish debt/payment events | `modules/accounting/` |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| **Product spec (canonical)** | [Theme-3-partner.md](Theme-3-partner.md) |
| Business scope (tóm tắt) | [01-business-scope.md](01-business-scope.md) |
| Harness (agent/engineer) | [harness/](harness/) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US specs | Status |
| ---- | ------ | -------- | ------ |
| EP-01 — Danh sách, hồ sơ & lịch sử | [Epic-01-partner-profile/](Epic-01-partner-profile/) | [US-01](Epic-01-partner-profile/US-01.md) … [US-07](Epic-01-partner-profile/US-07.md) | planned |
| EP-02 — Trạng thái đối tác | [Epic-02-partner-status/](Epic-02-partner-status/) | [US-01](Epic-02-partner-status/US-01.md), [US-02](Epic-02-partner-status/US-02.md) | planned |

Slice order: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) (S1..S9).

## Quy ước ID

```text
TH-03 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
```

- **US** = một file markdown `US-{nn}.md` trong folder epic (FR table + Scenarios + UI/API contract).
- **SCN** = scenario Gherkin trong US (`SCN-01` … `SCN-07`).
- **FR** = functional requirement checklist — section 2 trong file US.

## Agent prompt mẫu

```text
Implement TH-03 slice S1 (EP-01/US-02) per docs/themes/TH-03-partner/Epic-01-partner-profile/US-02.md.
Read README → harness/04-slice-roadmap.md → harness/07-api-contracts.md §S1 → harness/01-domain-model.md.
Golden module: modules/iam/ (codegen + pipeline).
Verify: melos run test && ./scripts/ci/verify_harness.sh
```
