# TH-03 — Traceability (v2)

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e01/u02/fr06/SCN-01
Test id: scn_e01_u02_fr06_01 (BE), wgt_e01_u02_fr06_01 (FE), e2e_e01_u02_fr06_01 (E2E)
```

**Reboot 2026-07-07:** Reset toàn bộ về `todo`. Code partner cũ đã gỡ.

Contracts: [07-api-contracts.md](07-api-contracts.md)

Tổng product: **2 epic, 9 US, 63 FR** (xem [README.md](../README.md#epic-index)).

---

## Platform — Partner codegen (infrastructure)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-03-PLATFORM | BE | — | infrastructure | `build.yaml`, `PartnerCommandPipeline`, `PartnerModuleDefinition` | partner_startup_test | done |
| TH-03-PLATFORM | BE | — | infrastructure | `registerGeneratedPartnerHandlers`, `partner_access_metadata.g.dart` | partner_startup_test | done |

Codegen ritual: mirror [modules/iam/README.md](../../../../modules/iam/README.md).

---

## Platform — Messaging worker (EP-01/US-07 consume)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-03-WORKER | BE | §S9 | infrastructure | `PartnerMessagingModule` | partner_messaging_module_test | todo |
| TH-03-WORKER | BE | §S9 | infrastructure | `ProcessInboxCommandHandler`, `ProcessInternalCommandsCommandHandler` | process_inbox_command_handler_test | todo |
| TH-03-WORKER | BE | §S9 | application | consumer handlers `partner_history_consumer_handlers.dart` | partner_history_consumer_handlers_test | done |
| TH-03-WORKER | BE | — | apps/messaging_worker | `messaging_worker_bootstrap.dart` registry partner | messaging_worker_loop_test | todo |
| TH-03-WORKER | E2E | §S9 | integration | cross-module event relay | e2e_s9_history_01 | **blocked** |

---

## S1 — EP-01 / US-02 — Tạo Partner mới

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S1 | application | `CreatePartnerCommand`, `CheckDuplicatePartnersQuery`, DTOs | fake_partner_module_test | done |
| FR-01..07 | BE | §S1 | application | `CreatePartnerCommandHandler` (Person + Organization) | scn_e01_u02_fr01_01 | done |
| FR-05 | BE | §S1 | application | `CheckDuplicatePartnersQueryHandler` | scn_e01_u02_fr05_01 | done |
| FR-01..07 | FE | §S1 | presentation | create person/org flow, dup warning dialog | wgt_e01_u02_fr01_01 | done |
| FR-06 | E2E | §S1 | integration | ERP via `IPartnerModule` | e2e_e01_u02_fr06_01 | done |

---

## S2 — EP-01 / US-01 — Tìm kiếm danh sách

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S2 | application | `SearchPartnersQuery`, `PartnerSearchResultDto` | fake_partner_module_test | done |
| FR-01..07 | BE | §S2 | application | `SearchPartnersQueryHandler` | scn_e01_u01_fr01_01 | done |
| FR-01..07 | FE | §S2 | presentation | `partner_list_page.dart`, list cubit, filters | wgt_e01_u01_fr01_01 | todo |
| FR-01 | E2E | §S2 | integration | list with real data | e2e_e01_u01_fr01_01 | todo |

---

## S3 — EP-01 / US-04 — Xem hồ sơ chi tiết

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §S3 | application | `GetPartnerDetailQuery`, `PartnerDetailDto` + `available_actions` | fake_partner_module_test | done |
| FR-01..07 | BE | §S3 | application | `GetPartnerDetailQueryHandler` | scn_e01_u04_fr01_01 | done |
| FR-01..07 | FE | §S3 | presentation | detail page, profile cards, action sheet | wgt_e01_u04_fr01_01 | todo |
| FR-01 | E2E | §S3 | integration | detail load | e2e_e01_u04_fr01_01 | todo |

---

## S4 — EP-01 / US-03 — Cập nhật hồ sơ

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S4 | application | `UpdatePartnerProfileCommand`, dup check for update | — | done |
| FR-01..07 | BE | §S4 | application | `UpdatePartnerProfileCommandHandler` | scn_e01_u03_fr01_01 | done |
| FR-01..07 | FE | §S4 | presentation | edit page, role selector | wgt_e01_u03_fr01_01 | todo |
| FR-01 | E2E | §S4 | integration | update flow | e2e_e01_u03_fr01_01 | todo |

---

## S5 — EP-01 / US-05 — Quản lý người liên hệ

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05 | CONTRACT | §S5 | application | Add/Update/Remove OrganizationContact commands | — | done |
| FR-01..07 | BE | §S5 | application | contact command handlers | scn_e01_u05_fr01_01 | done |
| FR-01..07 | FE | §S5 | presentation | contact list, add/edit/remove UI | wgt_e01_u05_fr01_01 | todo |
| FR-01 | E2E | §S5 | integration | contact CRUD | e2e_e01_u05_fr01_01 | todo |

---

## S6 — EP-01 / US-06 — Transform Person→Organization

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-06 | CONTRACT | §S6 | application | `TransformPersonToOrganizationCommand` | — | done |
| FR-01..07 | BE | §S6 | application | transform handler + primary contact | scn_e01_u06_fr01_01 | done |
| FR-01..07 | FE | §S6 | presentation | transform dialog + org form | wgt_e01_u06_fr01_01 | todo |
| FR-01 | E2E | §S6 | integration | transform flow | e2e_e01_u06_fr01_01 | todo |

---

## S7 — EP-02 / US-01 — Ngừng hoạt động / kích hoạt lại

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S7 | application | `DeactivatePartnerCommand`, `ReactivatePartnerCommand` | — | done |
| FR-01..07 | BE | §S7 | application | status command handlers | scn_e02_u01_fr01_01 | done |
| FR-01..07 | FE | §S7 | presentation | deactivate/reactivate dialogs | wgt_e02_u01_fr01_01 | todo |
| FR-01 | E2E | §S7 | integration | status flow | e2e_e02_u01_fr01_01 | todo |

---

## S8 — EP-02 / US-02 — Xóa mềm

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S8 | application | `CheckDeleteEligibilityQuery`, `SoftDeletePartnerCommand` | — | done |
| FR-01..07 | BE | §S8 | application | eligibility + soft delete handlers | scn_e02_u02_fr01_01 | done |
| FR-01..07 | FE | §S8 | presentation | delete confirm, HAS_TRANSACTIONS blocked UI | wgt_e02_u02_fr01_01 | todo |
| FR-01 | E2E | §S8 | integration | soft delete flow | e2e_e02_u02_fr01_01 | todo |

---

## S9 — EP-01 / US-07 — Lịch sử làm việc

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-07 | CONTRACT | §S9 | application | `GetPartnerHistoryQuery`, `RecordPartnerHistoryCommand` | fake_partner_module_test | done |
| FR-01..07 | BE | §S9 | application | history query + consumer handlers | scn_e01_u07_fr01_01 | done |
| FR-01..07 | FE | §S9 | presentation | history tab, filters | wgt_e01_u07_fr01_01 | todo |
| FR-01 | E2E | §S9 | integration | cross-module history | e2e_e01_u07_fr01_01 | **blocked** |

---

## Các slice còn lại

Thêm row khi bắt đầu CONTRACT lane. Cập nhật status khi lane `in_progress` / `done`.
