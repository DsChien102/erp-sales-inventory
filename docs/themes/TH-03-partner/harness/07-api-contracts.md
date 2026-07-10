# TH-03 — API contracts (FE ↔ BE) v2

Source of truth giữa presentation và application layer. Types live in `modules/partner/application/`.

Facade: `IPartnerModule` — `modules/partner/application/lib/src/contracts/i_partner_module.dart`.

**CONTRACT lane 2026-07-10:** Commands/queries/DTOs implemented; FE fake qua `FakePartnerModule` (`modules/partner/application/lib/testing.dart`).

**BE lane 2026-07-10:** Domain aggregate, handlers, gateways, `PartnerStartup`, codegen `generated/*.g.dart`; draft SQL `supabase/migrations/_drafts/partner_v2_*.sql` (chưa promote migration; có thể apply thủ công qua SQL editor).

**E2E lane 2026-07-10:** ERP `PartnerStartup` wired trong `apps/erp/lib/core/di/injection.dart`; integration test `e2e_e01_u02_fr06_01` qua mediator + RPC test double.

**Access control:** `@RequiresPermission(PartnerPermissions.*)` + `@RequiresTenant()`; codegen emit `partner_access_metadata.g.dart`.

**Blocked codes:** `NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`, `DUPLICATE_WARNING`, `INVALID_STATUS`, `HAS_TRANSACTIONS`, `STATE_CHANGED`, `SYSTEM_ERROR`.

---

## CMD catalog overview

| CMD | Symbol | Type | Permission | US |
| --- | ------ | ---- | ---------- | -- |
| CMD-01 | `SearchPartnersQuery` | Query | `partner.view` | EP-01/US-01 |
| CMD-02 | `GetPartnerDetailQuery` | Query | `partner.detail.view` | EP-01/US-04 |
| CMD-03 | `CreatePartnerCommand` | Command | `partner.create` | EP-01/US-02 |
| CMD-04 | `UpdatePartnerProfileCommand` | Command | `partner.update` | EP-01/US-03 |
| CMD-05 | `AddOrganizationContactCommand` | Command | `partner.contact.manage` | EP-01/US-05 |
| CMD-06 | `UpdateOrganizationContactCommand` | Command | `partner.contact.manage` | EP-01/US-05 |
| CMD-07 | `RemoveOrganizationContactCommand` | Command | `partner.contact.manage` | EP-01/US-05 |
| CMD-08 | `TransformPersonToOrganizationCommand` | Command | `partner.transform` | EP-01/US-06 |
| CMD-09 | `DeactivatePartnerCommand` | Command | `partner.status.manage` | EP-02/US-01 |
| CMD-10 | `ReactivatePartnerCommand` | Command | `partner.status.manage` | EP-02/US-01 |
| CMD-11 | `CheckDeleteEligibilityQuery` | Query | `partner.delete` | EP-02/US-02 |
| CMD-12 | `SoftDeletePartnerCommand` | Command | `partner.delete` | EP-02/US-02 |
| CMD-13 | `GetPartnerHistoryQuery` | Query | `partner.history.view` | EP-01/US-07 |
| — | `CheckDuplicatePartnersQuery` | Query | create/update flow | EP-01/US-02,03 |
| — | `RecordPartnerHistoryCommand` | Command (internal) | — | EP-01/US-07 |

---

## §S1 — EP-01/US-02 — Tạo Partner mới

### Commands / Queries

| Symbol | Input (summary) | Success | Errors |
| ------ | --------------- | ------- | ------ |
| `CreatePartnerCommand` | tenantId, actorId, partnerType, roles[], personProfile \| organizationProfile, organizationPrimaryContact?, confirmDuplicate | `CreatePartnerResult` (partnerId, warnings[]) | VALIDATION_ERROR, DUPLICATE_WARNING, NO_PERMISSION |
| `CheckDuplicatePartnersQuery` | tenantId, phone?, email?, taxCode?, name? | `List<PartnerDuplicateMatchDto>` (`matchLevel`: possible/exact — **derive** từ `matched_field`: phone/email/taxCode → exact, name → possible) | NO_PERMISSION |

### RPC mapping (BE) — drafted

| Use case | RPC | Status |
| -------- | --- | ------ |
| Create | `partner.create_partner` | drafted |
| Dup check | `partner.check_duplicate` | drafted |

### Fake scenarios (FE)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `create_person_ok` | CreatePartnerCommand person | `CreatePartnerResult(partnerId: 'p-new-1')` |
| `create_organization_ok` | CreatePartnerCommand organization | `CreatePartnerResult(partnerId: 'p-new-2')` |
| `create_dup_warning` | CheckDuplicatePartnersQuery | non-empty duplicate list |
| `create_exact_duplicate` | CheckDuplicatePartnersQuery | exact duplicate; không cho tiếp tục tạo |
| `create_dup_confirmed` | confirmDuplicate=true | `CreatePartnerResult` |
| `create_validation_error` | invalid payload | VALIDATION_ERROR |
| `create_permission_denied` | no partner.create | NO_PERMISSION |

---

## §S2 — EP-01/US-01 — Tìm kiếm danh sách

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `SearchPartnersQuery` | tenantId, q?, partnerType?, role?, status?, page, limit, sort | `PartnerSearchResultDto` | NO_PERMISSION |

RPC: `partner.search_partners` / `partner.v_partner_list`

`p_query` matches (ilike): `display_name`, `phone`, `email`, `tax_code` (MST).
If `p_query` contains `@`, search **email only**.

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `search_empty` | SearchPartnersQuery | empty items |
| `search_mixed_types` | default | Person + Organization items |
| `search_filtered_status` | status=inactive | filtered subset |

---

## §S3 — EP-01/US-04 — Xem hồ sơ chi tiết

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetPartnerDetailQuery` | tenantId, partnerId | `PartnerDetailDto` (profile, roles, contacts?, available_actions) | NOT_FOUND, NO_PERMISSION |

RPC: `partner.get_partner_detail`

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `detail_person_active` | person partner | PersonDetailDto + actions |
| `detail_organization_with_contacts` | org partner | OrganizationDetailDto + contacts |
| `detail_deleted` | deleted partner | NOT_FOUND or restricted view per spec |

---

## §S4 — EP-01/US-03 — Cập nhật hồ sơ

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `UpdatePartnerProfileCommand` | partnerId, profile fields, roles[], confirmDuplicate, expectedVersion | `UpdatePartnerProfileResult` | VALIDATION_ERROR, DUPLICATE_WARNING, STATE_CHANGED, INVALID_STATUS |

RPC: `partner.update_partner`

---

## §S5 — EP-01/US-05 — Quản lý người liên hệ

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `AddOrganizationContactCommand` | organizationPartnerId, personPartnerId \| newPersonProfile, contactRole?, isPrimary | `AddOrganizationContactResult` | VALIDATION_ERROR, NO_PERMISSION |
| `UpdateOrganizationContactCommand` | organizationPartnerId, personPartnerId, contactRole?, isPrimary | void / result | VALIDATION_ERROR |
| `RemoveOrganizationContactCommand` | organizationPartnerId, personPartnerId | void | NOT_FOUND |

RPC: `partner.add_organization_contact`, `partner.update_organization_contact`, `partner.remove_organization_contact`

---

## §S6 — EP-01/US-06 — Transform Person→Organization

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `TransformPersonToOrganizationCommand` | partnerId, organizationProfile, expectedVersion | `TransformPartnerResult` (same partnerId) | INVALID_STATUS (not person), VALIDATION_ERROR, STATE_CHANGED |

RPC: `partner.transform_to_organization`

---

## §S7 — EP-02/US-01 — Ngừng hoạt động / kích hoạt lại

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `DeactivatePartnerCommand` | partnerId, reason?, expectedVersion | `DeactivatePartnerResult` | INVALID_STATUS, NO_PERMISSION |
| `ReactivatePartnerCommand` | partnerId, reason?, expectedVersion | `ReactivatePartnerResult` | INVALID_STATUS |

RPC: `partner.deactivate_partner`, `partner.reactivate_partner`

---

## §S8 — EP-02/US-02 — Xóa mềm

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `CheckDeleteEligibilityQuery` | partnerId | `DeleteEligibilityDto` (eligible, reason?) | NOT_FOUND |
| `SoftDeletePartnerCommand` | partnerId, reason?, expectedVersion | `SoftDeletePartnerResult` | HAS_TRANSACTIONS, INVALID_STATUS |

RPC: `partner.check_delete_eligibility`, `partner.soft_delete_partner`

---

## §S9 — EP-01/US-07 — Lịch sử làm việc

| Symbol | Input | Success | Errors |
| ------ | ----- | ------- | ------ |
| `GetPartnerHistoryQuery` | partnerId, role?, transactionType?, dateFrom?, dateTo?, page | `PartnerHistoryResultDto` | NO_PERMISSION |
| `RecordPartnerHistoryCommand` | internal — projection upsert | void | — |

RPC: `partner.get_partner_history`, `partner.upsert_partner_history` (internal)

| scenario_id | trigger | fake response |
| ----------- | ------- | ------------- |
| `history_empty` | GetPartnerHistoryQuery | empty list |
| `history_mixed` | default | sales + inventory rows |
| `history_no_source_permission` | can_open_source=false | items without deep link |

---

## Parallel notes

- FE có thể fake sau CONTRACT lane — không cần RPC/DB
- E2E prerequisite: xem [04-slice-roadmap.md](04-slice-roadmap.md)
- S9 E2E **blocked** until cross-module events ship
