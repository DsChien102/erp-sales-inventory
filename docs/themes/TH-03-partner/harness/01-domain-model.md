# TH-03 — Domain model (v2)

> Bounded context: **partner** (`modules/partner/` — **greenfield, chưa implement**). Schema Postgres: `partner`.
> Product spec: [Theme-3-partner.md](../Theme-3-partner.md) §2.
> Analyze: [ddd-domain-modeling](../../../../.cursor/skills/ddd-domain-modeling/SKILL.md) · Implement: [domain-layer](../../../../.cursor/skills/domain-layer/SKILL.md)

**Reboot 2026-07-07:** Thay model cũ (`business_partners` + `entity_type = individual|household_business|company`, `active|inactive`, hard delete) bằng model mới: **Partner root** + **Person/Organization profile** + **soft delete**.

```mermaid
erDiagram
    PARTNERS ||--o| PERSON_PROFILES : has
    PARTNERS ||--o| ORGANIZATION_PROFILES : has
    PARTNERS ||--o{ PARTNER_ROLES : assigned
    PARTNERS ||--o{ ORGANIZATION_CONTACTS : as_organization
    PARTNERS ||--o{ ORGANIZATION_CONTACTS : as_person
    PARTNERS ||--o{ PARTNER_ACTION_LOGS : logs
    PARTNERS ||--o{ PARTNER_HISTORY_VIEWS : history

    PARTNERS {
        uuid partner_id PK
        uuid tenant_id FK
        enum partner_type "person|organization"
        enum status "active|inactive|deleted"
        string display_name
        datetime created_at
        uuid created_by
        datetime updated_at
        uuid updated_by
    }

    PERSON_PROFILES {
        uuid partner_id PK_FK
        enum title "optional honorific"
        string full_name
        string nickname
        string phone
        string phone2
        string email
        string tax_code
        string invoice_name
        string invoice_address
        string invoice_email
        string delivery_province
        string delivery_commune
        string delivery_address
        text note
    }

    ORGANIZATION_PROFILES {
        uuid partner_id PK_FK
        enum organization_type "company|business_household|other"
        string organization_name
        string short_name
        string intl_name
        string phone
        string email
        string tax_code
        string company_address
        string invoice_name
        string invoice_address
        string invoice_email
        string delivery_province
        string delivery_commune
        text note
    }

    PARTNER_ROLES {
        uuid partner_id PK_FK
        enum role PK "customer|supplier"
        boolean is_active
        datetime created_at
        datetime updated_at
    }

    ORGANIZATION_CONTACTS {
        uuid organization_partner_id PK_FK
        uuid person_partner_id PK_FK
        string contact_role
        boolean is_primary
        text note
        datetime created_at
        uuid created_by
        datetime updated_at
        uuid updated_by
    }

    PARTNER_ACTION_LOGS {
        uuid action_log_id PK
        uuid partner_id FK
        enum action_type
        uuid actor_user_id
        text reason
        json before_state
        json after_state
        datetime created_at
    }

    PARTNER_HISTORY_VIEWS {
        uuid history_id PK
        uuid partner_id FK
        enum role "customer|supplier"
        enum transaction_type
        string source_module
        uuid source_id
        string reference_code
        datetime transaction_date
        string status
        decimal amount
        string currency
        boolean can_open_source
    }
```

## Lifecycle

```text
[nháp form] → CreatePartner → active
            → Update profile / đổi role
            → Add/Update/Remove OrganizationContact (Organization only)
            → Transform Person → Organization (giữ partner_id, roles, status)
            → deactivate → reactivate
            → soft delete (status = deleted) nếu chưa phát sinh giao dịch
```

| From | To | Allowed | Ghi chú |
| ---- | -- | ------- | ------- |
| `active` | `inactive` | Yes | Ngừng hoạt động |
| `inactive` | `active` | Yes | Kích hoạt lại |
| `active` | `deleted` | Yes | Xóa mềm nếu đủ điều kiện |
| `inactive` | `deleted` | Yes | Xóa mềm nếu đủ điều kiện |
| `deleted` | `active` | No | Phase 1 không khôi phục |
| `deleted` | hard delete | No | Phase 1 không xóa cứng |

## Aggregate

| Aggregate | Folder | Ghi chú |
| --------- | ------ | ------- |
| `Partner` | `domain/lib/src/partner/` | Root aggregate. Quản lý `partner_type`, `status`, profile (Person hoặc Organization), roles, lifecycle. |

**Không phải aggregate:** `PartnerHistoryView` (read model/projection), `PartnerActionLog` (audit append-only).

## Database tables

| Table | Ghi chú |
| ----- | ------- |
| `partners` | Root entity — `partner_type`, `status`, `display_name`, audit |
| `person_profiles` | 1:0..1 với Partner type `person` |
| `organization_profiles` | 1:0..1 với Partner type `organization` |
| `partner_roles` | Vai trò giao dịch customer/supplier |
| `organization_contacts` | Liên kết Organization ↔ Person (contact) |
| `partner_action_logs` | Audit mọi thao tác quan trọng |
| `partner_history_views` | Read model lịch sử làm việc (projection từ inbox) |

## Value objects & enums

| Symbol | Values / mô tả |
| ------ | -------------- |
| `PartnerType` | `person`, `organization` |
| `PartnerStatus` | `active`, `inactive`, `deleted` |
| `PartnerRoleType` | `customer`, `supplier` |
| `OrganizationType` | `company`, `businessHousehold`, `other` |
| `PersonTitle` | `ong`, `ba`, `anh`, `chi`, ... (optional) |
| `PhoneNumber` | Required; validate format; dup warning tenant-scoped |
| `EmailAddress` | Optional; validate format; dup warning |
| `TaxCode` | Optional; dup warning; warn if missing for company/businessHousehold |
| `InvoiceProfile` | invoice_name, invoice_address, invoice_email |
| `DeliveryAddress` | province, commune, address |
| `OrganizationContactLink` | contact_role, is_primary, note |
| `ActionType` | `create`, `update`, `addContact`, `removeContact`, `transform`, `deactivate`, `reactivate`, `delete` |

## Commands (CMD catalog → CQRS)

| Command | CMD | Epic/US | Ghi chú |
| ------- | --- | ------- | ------- |
| `CreatePartnerCommand` | CMD-03 | EP-01/US-02 | Tạo Person hoặc Organization + roles |
| `UpdatePartnerProfileCommand` | CMD-04 | EP-01/US-03 | Cập nhật profile + roles; không đổi `partner_type` |
| `AddOrganizationContactCommand` | CMD-05 | EP-01/US-05 | Thêm Person contact vào Organization |
| `UpdateOrganizationContactCommand` | CMD-06 | EP-01/US-05 | Cập nhật contact link |
| `RemoveOrganizationContactCommand` | CMD-07 | EP-01/US-05 | Gỡ liên kết (không xóa Person mặc định) |
| `TransformPersonToOrganizationCommand` | CMD-08 | EP-01/US-06 | Giữ `partner_id`; Person cũ → primary contact |
| `DeactivatePartnerCommand` | CMD-09 | EP-02/US-01 | `active` → `inactive` |
| `ReactivatePartnerCommand` | CMD-10 | EP-02/US-01 | `inactive` → `active` |
| `SoftDeletePartnerCommand` | CMD-12 | EP-02/US-02 | `status = deleted` nếu chưa có giao dịch |
| `RecordPartnerHistoryCommand` | internal | EP-01/US-07 | Upsert projection từ integration events |

## Queries

| Query | CMD | Epic/US | Ghi chú |
| ----- | --- | ------- | ------- |
| `SearchPartnersQuery` | CMD-01 | EP-01/US-01 | q, partner_type, role, status, page, sort |
| `GetPartnerDetailQuery` | CMD-02 | EP-01/US-04 | Hồ sơ + `available_actions` |
| `CheckDuplicatePartnersQuery` | — | EP-01/US-02,03 | Dup phone/email/tax/name+phone |
| `CheckDeleteEligibilityQuery` | CMD-11 | EP-02/US-02 | Kiểm tra điều kiện xóa mềm |
| `GetPartnerHistoryQuery` | CMD-13 | EP-01/US-07 | Read model; không fan-out query-time |

## Domain events

| Event | Khi |
| ----- | --- |
| `PartnerCreated` | Sau create thành công |
| `PartnerProfileUpdated` | Sau update profile/roles |
| `OrganizationContactAdded` | Sau add contact |
| `OrganizationContactUpdated` | Sau update contact |
| `OrganizationContactRemoved` | Sau remove contact |
| `PartnerTransformedToOrganization` | Sau transform Person→Organization |
| `PartnerDeactivated` | Sau deactivate |
| `PartnerReactivated` | Sau reactivate |
| `PartnerSoftDeleted` | Sau soft delete |

## Integration events — publish

| Type | Khi |
| ---- | --- |
| `partner.partner.created` | Create |
| `partner.partner.profile_updated` | Update |
| `partner.partner.contact_changed` | Add/update/remove contact |
| `partner.partner.transformed` | Transform |
| `partner.partner.deactivated` | Deactivate |
| `partner.partner.reactivated` | Reactivate |
| `partner.partner.soft_deleted` | Soft delete |

## Integration events — consume

| Source | Event | Mục đích |
| ------ | ----- | -------- |
| sales | `sales.order.checked_out` | Projection history (customer) |
| inventory | `inventory.inbound.recorded` | Projection history (supplier) |
| accounting | `accounting.receivable.created` | Projection history |
| accounting | `accounting.payable.created` | Projection history |

## Data rules

| Rule ID | Rule |
| ------- | ---- |
| DR-01 | Partner phải có `partner_type`, `status`, `display_name` và ít nhất một role |
| DR-02 | `partner_type` chỉ `person` hoặc `organization` |
| DR-03 | Person Partner có `person_profiles`; Organization Partner có `organization_profiles` — không cả hai |
| DR-04 | Customer/Supplier là vai trò giao dịch, độc lập với `partner_type` |
| DR-05 | `phone` bắt buộc; sai format chặn; trùng cảnh báo (Phase 1 warn-only) |
| DR-06 | `email`, `tax_code` optional; trùng cảnh báo tenant-scoped |
| DR-07 | Organization thiếu MST → cảnh báo với `company`/`business_household` |
| DR-08 | Partner mới mặc định `status = active` |
| DR-09 | `inactive`/`deleted` không chọn cho giao dịch mới |
| DR-10 | `deleted` không hiển thị danh sách mặc định |
| DR-11 | Soft delete chỉ khi chưa phát sinh giao dịch (`HAS_TRANSACTIONS` nếu có) |
| DR-12 | Transform chỉ Person→Organization; giữ `partner_id`, roles, status |
| DR-13 | Person sau transform trở thành primary contact của Organization |
| DR-14 | Mỗi Organization tối đa một primary contact |
| DR-15 | Mọi mutation quan trọng ghi `partner_action_logs` |
| DR-16 | `partner_history_views` là projection — không thuộc aggregate Partner |

## Blocked response codes (presentation boundary)

`NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `DUPLICATE_WARNING`, `INVALID_STATUS`, `HAS_TRANSACTIONS`, `STATE_CHANGED`, `SYSTEM_ERROR` — xem Theme spec §4.3.

## Anti-patterns

- God aggregate gộp history vào Partner.
- Hard delete mặc định (Phase 1 chỉ soft delete).
- Đổi `partner_type` qua form update thông thường (phải qua Transform command).
- Tách Customer/Supplier thành aggregate riêng.
- Dup-check chỉ ở UI — cần RPC tenant-scoped.
- Query-time fan-out sang sales/inventory/accounting cho history.
- Xóa Person khi gỡ OrganizationContact.

## Implement

Code domain: [domain-layer skill](../../../../.cursor/skills/domain-layer/SKILL.md) → `modules/partner/domain/lib/src/partner/`.
Commands/handlers: [application-layer](../../../../.cursor/skills/application-layer/SKILL.md).
SQL draft: `supabase/migrations/_drafts/partner_v2_*.sql` (chưa tạo — slice BE).
