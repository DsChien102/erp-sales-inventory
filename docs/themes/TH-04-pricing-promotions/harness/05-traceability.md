# TH-04 EP02 — Traceability

Ma trận truy vết product → role → contract → artifact → test. Tất cả row khởi tạo `todo`, trừ US-02 CONTRACT/BE là `n/a` và S9 E2E là `blocked` theo roadmap.

```text
Requirement: e02/u{us}/fr{fr}/{TYPE}-{id}
Tests: scn_e02_u{us}_fr{fr}_{nn} (BE), wgt_e02_u{us}_fr{fr}_{nn} (FE), e2e_e02_u{us}_fr{fr}_{nn} (E2E)
```

Contracts: [07-api-contracts.md](07-api-contracts.md).

## S1 — US-04 Create manual

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-04 | CONTRACT | §S1 | application | create command/result/detail DTO + fake cases | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S1 | domain/application/infrastructure | aggregate, handler, gateway, create RPC draft | scn_e02_u04_fr01_01 | todo |
| FR-01..05 | FE | §S1 | presentation | create page/cubit/widgets | wgt_e02_u04_fr01_01 | todo |
| FR-01..05 | E2E | §S1 | integration | create through ERP mediator | e2e_e02_u04_fr01_01 | todo |

## S2 — US-01 List/search/filter

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S2 | application | search query/page/list item DTO | fake_pricing_module_test | todo |
| FR-01..06 | BE | §S2 | application/infrastructure | query handler/read gateway/search RPC draft | scn_e02_u01_fr01_01 | todo |
| FR-01..06 | FE | §S2 | presentation | list page/cubit/filter widgets | wgt_e02_u01_fr01_01 | todo |
| FR-01..06 | E2E | §S2 | integration | tenant-scoped list/search | e2e_e02_u01_fr01_01 | todo |

## S3 — US-03 Detail

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S3 | application | detail query/DTO/actions | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S3 | application/infrastructure | detail handler/read gateway/RPC draft | scn_e02_u03_fr01_01 | todo |
| FR-01..05 | FE | §S3 | presentation | detail page/action widgets | wgt_e02_u03_fr01_01 | todo |
| FR-01..05 | E2E | §S3 | integration | real detail + permission actions | e2e_e02_u03_fr01_01 | todo |

## S4 — US-02 Choose add method

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S4 | application | no new server contract | — | n/a |
| US-02 | BE | §S4 | application | no backend mutation | — | n/a |
| FR-01..05 | FE | §S4 | presentation | add-method sheet/navigation | wgt_e02_u02_fr01_01 | todo |
| FR-01..05 | E2E | §S4 | integration | permission-aware route selection | e2e_e02_u02_fr01_01 | todo |

## S5 — US-06 Edit

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-06 | CONTRACT | §S5 | application | update command/result/version DTO | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S5 | domain/application/infrastructure | update policy/handler/RPC draft | scn_e02_u06_fr01_01 | todo |
| FR-01..05 | FE | §S5 | presentation | edit form/state-changed UX | wgt_e02_u06_fr01_01 | todo |
| FR-01..05 | E2E | §S5 | integration | edit/concurrency path | e2e_e02_u06_fr01_01 | todo |

## S6 — US-07 Disable

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-07 | CONTRACT | §S6 | application | disable command/result | fake_pricing_module_test | todo |
| FR-01..04 | BE | §S6 | domain/application/infrastructure | disable transition/handler/RPC draft | scn_e02_u07_fr01_01 | todo |
| FR-01..04 | FE | §S6 | presentation | disable dialog/action refresh | wgt_e02_u07_fr01_01 | todo |
| FR-01..04 | E2E | §S6 | integration | disable via mediator | e2e_e02_u07_fr01_01 | todo |

## S7 — US-08 Reenable

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-08 | CONTRACT | §S7 | application | precheck query/outcome + reenable command | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S7 | domain/application/infrastructure | reenable policy/handler/RPC drafts | scn_e02_u08_fr01_01 | todo |
| FR-01..05 | FE | §S7 | presentation | precheck warning/block dialog | wgt_e02_u08_fr01_01 | todo |
| FR-01..05 | E2E | §S7 | integration | reenable + duplicate/floor path | e2e_e02_u08_fr01_01 | todo |

## S8 — US-05 Excel import

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05 | CONTRACT | §S8 | application | start/get/confirm/cancel contracts + row DTO | fake_pricing_module_test | todo |
| FR-01..06 | BE | §S8 | domain/application/infrastructure | import aggregate/handlers/RPC drafts | scn_e02_u05_fr01_01 | todo |
| FR-01..06 | FE | §S8 | presentation | import wizard/preview/result | wgt_e02_u05_fr01_01 | todo |
| FR-01..06 | E2E | §S8 | integration | mixed-row partial import | e2e_e02_u05_fr01_01 | todo |

## S9 — US-09 Remember from Sales

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-09 | CONTRACT | §S9 | application | public command/outcome DTO/idempotency | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S9 | domain/application/infrastructure | memory aggregate/handler/RPC draft | scn_e02_u09_fr01_01 | todo |
| FR-01..05 | FE | §S9 | presentation | fake Sales confirmation/outcome surface | wgt_e02_u09_fr01_01 | todo |
| FR-01..05 | E2E | §S9 | integration | Sales publisher → Pricing | e2e_e02_u09_fr01_01 | blocked |

## S10 — US-10 History

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-10 | CONTRACT | §S10 | application | history query/activity page DTO | fake_pricing_module_test | todo |
| FR-01..05 | BE | §S10 | application/infrastructure | history handler/read RPC draft | scn_e02_u10_fr01_01 | todo |
| FR-01..05 | FE | §S10 | presentation | activity timeline widgets | wgt_e02_u10_fr01_01 | todo |
| FR-01..05 | E2E | §S10 | integration | mutation then immutable timeline | e2e_e02_u10_fr01_01 | todo |

