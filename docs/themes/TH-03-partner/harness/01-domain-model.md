# TH-03 — Domain model

> Bounded context: **partner** (`modules/partner/`). Schema Postgres: `partner`.
> Skill: [ddd-domain-modeling](../../../../.cursor/skills/ddd-domain-modeling/SKILL.md)

## Lifecycle

```text
[nháp form] → Register → active
            → Update profile / đổi role
            → deactivate → reactivate
            → soft delete (nếu chưa phát sinh giao dịch)
```

## Aggregate

| Aggregate | Folder | Ghi chú |
| --------- | ------ | ------- |
| `BusinessPartner` | `domain/lib/src/business_partner/` | Một consistency boundary |

## Value objects (planned)

| VO | Mô tả |
| -- | ----- |
| `PartnerRole` | customer, supplier, both |
| `ProfileType` | individual, organization |
| `PartnerName` | Required, không whitespace-only |
| `PhoneNumber` | Bắt buộc khi ghi nhận (Epic-01/US-02 FR-3) |
| `Email`, `TaxCode`, `Address` | Optional, format validated |
| `InvoiceProfile` | Tên/địa chỉ/email trên hóa đơn |
| `PartnerStatus` | active, inactive, deleted |

## Commands

| Command | Epic/US |
| ------- | ------- |
| `RegisterPartnerCommand` | Epic-01/US-02 |
| `UpdatePartnerProfileCommand` | Epic-01/US-03 |
| `ChangePartnerRoleCommand` | Epic-01/US-03 |
| `DeactivatePartnerCommand` | Epic-02/US-01 |
| `ReactivatePartnerCommand` | Epic-02/US-01 |
| `DeletePartnerCommand` | Epic-02/US-02 |

## Queries

| Query | Epic/US |
| ----- | ------- |
| `SearchPartnersQuery` | Epic-01/US-01 |
| `GetPartnerDetailQuery` | Epic-01/US-04 |
| `GetPartnerTransactionHistoryQuery` | Epic-03/US-01 |

## Domain events (planned)

`PartnerRegistered`, `PartnerProfileUpdated`, `PartnerRoleChanged`, `PartnerDeactivated`, `PartnerReactivated`, `PartnerDeleted`

## Integration events — publish

| Type | Khi |
| ---- | --- |
| `partner.partner.registered` | Register |
| `partner.partner.profile_updated` | Update |
| `partner.partner.role_changed` | Đổi role |
| `partner.partner.deactivated` | Deactivate |
| `partner.partner.reactivated` | Reactivate |
| `partner.partner.deleted` | Soft delete |

## Integration events — consume (Epic-03)

| Source | Event (planned) |
| ------ | --------------- |
| sales | `sales.order.checked_out` |
| inventory | `inventory.inbound.recorded` |
| accounting | `accounting.receivable.created` |

## Anti-patterns

- God aggregate gộp transaction history vào `BusinessPartner`
- Dup-check chỉ UI — phải có RPC/query tenant-scoped
- Query-time fan-out sang sales/inventory cho lịch sử — dùng inbox projection
