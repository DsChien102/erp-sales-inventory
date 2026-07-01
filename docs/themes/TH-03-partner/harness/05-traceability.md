# TH-03 — Traceability

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e01/u02/fr06/SCN-01
Test id: scn_e01_u02_fr06_01 (BE), wgt_e02_u01_fr03_01 (FE), e2e_e01_u02_fr06_01 (E2E)
```

<!-- exemplar-complete: e02/u01 -->

**Exemplar:** Epic-01 + Epic-02/US-01 — lane BE/FE/E2E.

Contracts: [07-api-contracts.md](07-api-contracts.md)

---

## Platform — Partner codegen (infrastructure)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-03-PLATFORM | BE | — | infrastructure | `build.yaml` (4 builders), `PartnerCommandPipeline`, `PartnerModuleDefinition` | — | done |
| TH-03-PLATFORM | BE | — | infrastructure | `registerGeneratedPartnerHandlers` / `partner_access_metadata.g.dart` | partner_access_metadata_registry_test | done |

Codegen ritual: [modules/partner/README.md](../../../../modules/partner/README.md).

---

## Epic-01 / US-02 — Ghi nhận đối tác mới

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §US-02 | application | `RegisterPartnerCommand`, `CheckDuplicatePartnersQuery`, DTOs | — | done |
| FR-06 | BE | §US-02 | application | `RegisterPartnerCommandHandler` | scn_e01_u02_fr06_01 | done |
| FR-06 | BE | §US-02 | infrastructure | `partner.register_partner` RPC | — | done |
| FR-05 | BE | §US-02 | application | `CheckDuplicatePartnersQueryHandler` | scn_e01_u02_fr05_01 | done |
| FR-01..06 | FE | §US-02 | presentation | `partner_create_page.dart`, cubit, form widgets | — | done |
| FR-06 | E2E | §US-02 | integration | ERP via `IPartnerModule` | — | done |

---

## Epic-01 / US-01 — Tìm kiếm danh sách

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `SearchPartnersQuery`, `PartnerSearchResultDto` | — | done |
| FR-01..05 | BE | §US-01 | application | `SearchPartnersQueryHandler` | scn_e01_u01_fr01_01 | done |
| FR-01..05 | BE | §US-01 | infrastructure | `partner.search_partners` RPC, `SupabasePartnerReadGateway` | — | done |
| FR-01..05 | FE | §US-01 | presentation | `partner_list_page.dart`, `partner_list_item.dart`, `partner_list_cubit.dart`, search/filter widgets, `partner_list_cubit_test.dart` | — | done |
| FR-01..05 | E2E | §US-01 | integration | list with real data | — | done |

---

## Epic-01 / US-04 — Kiểm tra hồ sơ

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §US-04 | application | `GetPartnerDetailQuery`, `PartnerDetailDto` | — | done |
| FR-04 | BE | §US-04 | application | `GetPartnerDetailQueryHandler` | scn_e01_u04_fr04_01 | done |
| FR-02 | BE | §US-04 | infrastructure | `partner.get_partner_detail` RPC | — | done |
| FR-01..05 | FE | §US-04 | presentation | `partner_detail_page.dart`, detail cubit/widgets | wgt_e01_u04_fr01_01 | done |
| FR-05 | FE | §US-04 | presentation | `partner_transaction_history_tab.dart` | — | placeholder (Epic-03) |
| FR-01..04 | E2E | §US-04 | integration | detail load via real module | — | done |

---

## Epic-01 / US-03 — Bổ sung và chỉnh sửa

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §US-03 | application | `UpdatePartnerProfileCommand`, `CheckDuplicatePartnersForUpdateQuery` | — | done |
| FR-06 | BE | §US-03 | application | `UpdatePartnerProfileCommandHandler` | scn_e01_u03_fr06_01 | done |
| FR-04 | BE | §US-03 | domain | `BusinessPartner.updateProfile` | scn_e01_u03_fr04_01 | done |
| FR-03 | BE | §US-03 | infrastructure | `partner.update_partner` RPC | — | done |
| FR-01..06 | FE | §US-03 | presentation | `partner_edit_page.dart`, edit cubit/widgets | wgt_e01_u03_fr01_01 | done |
| FR-06 | E2E | §US-03 | integration | edit save via real module | — | done |

---

## Epic-02 / US-01 — Dừng sử dụng / sử dụng lại

> Pilot contract-first — exemplar lane cho guard traceability.

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `DeactivatePartnerCommand`, `ReactivatePartnerCommand` | — | done |
| FR-02 | BE | §US-01 | application | Commands + validators | scn_e02_u01_fr02_01 | done |
| FR-03 | BE | §US-01 | domain | `BusinessPartner.deactivate` | scn_e02_u01_fr03_01 | done |
| FR-03 | BE | §US-01 | infrastructure | `partner.deactivate_partner` RPC | scn_e02_u01_fr02_01 | done |
| FR-04 | BE | §US-01 | domain | `BusinessPartner.reactivate` | — | done |
| FR-04 | BE | §US-01 | infrastructure | `partner.reactivate_partner` RPC | scn_e02_u01_fr02_01 | done |
| FR-05 | BE | §US-01 | application | `DeactivatePartnerCommandHandler` / `ReactivatePartnerCommandHandler` | scn_e02_u01_fr02_01 | done |
| FR-01 | FE | §US-01 | presentation | `modules/partner/presentation/lib/src/widgets/partner_detail_menu.dart`, `apps/erp/lib/features/partner/presentation/pages/partner_detail_page.dart` | — | done |
| FR-03 | FE | §US-01 | presentation | `modules/partner/presentation/lib/src/widgets/deactivate_partner_dialog.dart` | wgt_e02_u01_fr03_01 | done |
| FR-04 | FE | §US-01 | presentation | `modules/partner/presentation/lib/src/widgets/reactivate_partner_dialog.dart` | wgt_e02_u01_fr04_01 | done |
| FR-03/04 | E2E | §US-01 | integration | detail → deactivate/reactivate flow | e2e_e02_u01_fr03_01 | done |

---

## Epic-02 / US-02 — Loại bỏ hồ sơ tạo nhầm

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §US-02 | application | `DeletePartnerCommand` | — | done |
| FR-02 | BE | §US-02 | application | `DeletePartnerCommandHandler` | scn_e02_u02_fr04_01 | done |
| FR-02 | BE | §US-02 | domain | `PartnerMustHaveNoTransactionHistoryRule`, `BusinessPartner.delete` | scn_e02_u02_fr02_01 | done |
| FR-03 | BE | §US-02 | infrastructure | `partner.delete_partner` RPC | scn_e02_u02_fr04_01 | done |
| FR-01 | FE | §US-02 | presentation | `partner_detail_menu.dart` | wgt_e02_u02_fr01_01 | done |
| FR-03 | FE | §US-02 | presentation | `delete_partner_dialog.dart` | scn_e02_u02_fr03_01 | done |
| FR-04 | FE | §US-02 | presentation | `partner_detail_page.dart`, `PartnerDetailCubit.deletePartner` | wgt_e02_u02_fr04_01 | done |
| FR-04 | E2E | §US-02 | integration | delete flow via real module | scn_e02_u02_fr04_01 | done |

---

## Epic-03 / US-01 — Theo dõi lịch sử làm việc

> BE + E2E blocked; FE + CONTRACT có thể tiến.

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `ListPartnerTransactionHistoryQuery` (stub) | — | todo |
| FR-01..05 | BE | §US-01 | infrastructure | inbox projection handler | — | blocked |
| FR-01..05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` | wgt_e03_u01_fr01_01 | in_progress |
| FR-01..05 | E2E | §US-01 | integration | cross-module events | — | blocked |
