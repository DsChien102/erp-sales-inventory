# TH-03: Khách hàng & NCC

**Trạng thái deliver:** `in_progress`

## Mục tiêu

Quản lý hồ sơ đối tác (khách hàng, nhà cung cấp, hoặc cả hai) làm lớp dữ liệu nền cho bán hàng, nhập hàng, hóa đơn, công nợ và tra cứu lịch sử giao dịch.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| partner | **Owner** — codegen enabled | `modules/partner/` ([README](../../../modules/partner/README.md)) |
| iam | Supporting — auth, tenant, permission | `modules/iam/` |
| sales | Supporting — snapshot, publish transaction events | `modules/sales/` |
| inventory | Supporting — publish inbound events | `modules/inventory/` |
| accounting | Supporting — publish debt/payment events | `modules/accounting/` |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| Business scope | [01-business-scope.md](01-business-scope.md) |
| Harness (agent/engineer) | [harness/](harness/) (incl. [07-api-contracts](harness/07-api-contracts.md)) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US | FR | Status |
| ---- | ------ | -- | -- | ------ |
| Epic 01 — Hồ sơ đối tác | [Epic-01-partner-profile/](Epic-01-partner-profile/) | US-01..04 | 5+6+6+5 | **done** |
| Epic 02 — Trạng thái đối tác | [Epic-02-partner-status/](Epic-02-partner-status/) | US-01..02 | 5+4 | todo |
| Epic 03 — Lịch sử giao dịch | [Epic-03-partner-transaction-history/](Epic-03-partner-transaction-history/) | US-01 | 5 | blocked |

Chi tiết slice order và phụ thuộc: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md).

## Quy ước ID

```text
TH-03 / Epic-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SCN-{nn}
Test id (khi có): scn_e01_u02_fr06_01
```

## Agent prompt mẫu

```text
Implement TH-03/Epic-01/US-02/FR-06 per docs/themes/TH-03-partner/harness/00-agent-ritual.md.
Read README → slice-roadmap → US overview → FR spec → harness domain-model + architecture.
Verify: melos run test && ./scripts/ci/verify_harness.sh
```
