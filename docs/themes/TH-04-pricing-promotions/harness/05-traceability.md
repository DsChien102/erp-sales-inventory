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
| US-04 | CONTRACT | §S1 | application | create command/result/detail DTO + fake cases | fake_pricing_module_test | done |
| FR-01..05 | BE | §S1 | domain/application/infrastructure | aggregate, handler, gateway, create RPC draft | scn_e02_u04_fr01_01 | done |
| FR-01..05 | FE | §S1 | presentation | create page/cubit/widgets | wgt_e02_u04_fr01_01 | done |
| FR-01..05 | E2E | §S1 | integration | create through ERP mediator | e2e_e02_u04_fr01_01 | todo |

## S2 — US-01 List/search/filter

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §S2 | application | search query/page/list item DTO | fake_pricing_module_test | done |
| FR-01..06 | BE | §S2 | application/infrastructure | query handler/read gateway/search RPC draft | scn_e02_u01_fr01_01 | done |
| FR-01..06 | FE | §S2 | presentation | list page/cubit/filter widgets | wgt_e02_u01_fr01_01 | done |
| FR-01..06 | E2E | §S2 | integration | tenant-scoped list/search | e2e_e02_u01_fr01_01 | todo |

## S3 — US-03 Detail

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-03 | CONTRACT | §S3 | application | detail query/DTO/actions | fake_pricing_module_test | done |
| FR-01..05 | BE | §S3 | application/infrastructure | detail handler/read gateway/RPC draft | scn_e02_u03_fr01_01 | done |
| FR-01..05 | FE | §S3 | presentation | detail page/action widgets | wgt_e02_u03_fr01_01 | done |
| FR-01..05 | E2E | §S3 | integration | real detail + permission actions | e2e_e02_u03_fr01_01 | todo |

## S4 — US-02 Choose add method

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §S4 | application | no new server contract | — | n/a |
| US-02 | BE | §S4 | application | no backend mutation | — | n/a |
| FR-01..05 | FE | §S4 | presentation | add-method sheet/navigation | wgt_e02_u02_fr01_01 | done |
| FR-01..05 | E2E | §S4 | integration | permission-aware route selection | e2e_e02_u02_fr01_01 | todo |

## S5 — US-06 Edit

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-06 | CONTRACT | §S5 | application | update command/detail/version/fake matrix | update_customer_price_rule_contract_test | done |
| FR-01..05 | BE | §S5 | domain/application/infrastructure | aggregate update, handler, gateways, update-context/update RPC drafts | scn_e02_u06_fr01_01 | done |
| FR-01..05 | FE | §S5 | presentation | edit form/state-changed UX | wgt_e02_u06_fr01_01 | done |
| FR-01..05 | E2E | §S5 | integration | edit/concurrency path | e2e_e02_u06_fr01_01 | todo |

## S6 — US-07 Disable

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-07 | CONTRACT | §S6 | application | disable command/detail lifecycle/fake matrix | disable_customer_price_rule_contract_test | done |
| FR-01..04 | BE | §S6 | domain/application/infrastructure | disable transition/handler/gateway/RPC draft | scn_e02_u07_fr01_01 | done |
| FR-01..04 | FE | §S6 | presentation | disable dialog/action refresh | wgt_e02_u07_fr01_01 | done |
| FR-01..04 | E2E | §S6 | integration | disable via mediator | e2e_e02_u07_fr01_01 | todo |

## S7 — US-08 Reenable

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-08 | CONTRACT | §S7 | application | precheck query/outcome + reenable command + 16 fake scenarios | reenable_customer_price_rule_contract_test | done |
| FR-01..05 | BE | §S7 | domain/application/infrastructure | reenable policy/handler/gateway/RPC drafts | pricing_reenable_rpc_mapper_test, pricing_reenable_startup_test, pricing_sql_contract_test (S7) | done |
| FR-01..05 | FE | §S7 | presentation | precheck warning/block dialog | wgt_e02_u08_fr01_01 | done |
| FR-01..05 | E2E | §S7 | integration | reenable + duplicate/floor path | e2e_e02_u08_fr01_01 | todo |

## S8 — US-05 Excel import

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-05 | CONTRACT | §S8 | application | start/get/confirm/cancel + template query + 14 fake scenarios | customer_price_rule_import_contract_test | done |
| FR-01..06 | BE | §S8 | domain/application/infrastructure | import aggregate, bounded OOXML parser, handlers, gateway, authoritative RPC drafts | customer_price_rule_import_test, customer_price_rule_import_handler_test, excel_customer_price_rule_import_file_adapter_test, customer_price_rule_import_rpc_mapper_test, supabase_customer_price_rule_import_gateway_test, pricing_import_startup_test, pricing_customer_price_rule_import_s8_contract_test | done |
| FR-01..06 | FE | §S8 | presentation | import wizard/preview/result | wgt_e02_u05_fr01_01 | done |
| FR-01..06 | E2E | §S8 | integration | mixed-row partial import | e2e_e02_u05_fr01_01 | todo |

## S9 — US-09 Remember from Sales

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-09 | CONTRACT | §S9 | application | `SaveRememberedPriceFromOrderCommand`, `RememberedPriceOutcomeDto`, 11 fake scenarios | save_remembered_price_from_order_contract_test, fake_pricing_module_test | done |
| FR-01 | BE | §S9 | application/infrastructure | opaque Sales snapshot fields, dedicated gateway port | save_remembered_price_from_order_contract_test | done |
| FR-02 | BE | §S9 | domain/infrastructure | `RememberedPriceRequest` idempotency + stored outcome | remembered_price_request_test | done |
| FR-03 | BE | §S9 | domain/infrastructure | create/update/skip/block policy in RPC draft | pricing_remembered_price_from_order_s9_contract_test | done |
| FR-04 | BE | §S9 | application/infrastructure | outcome DTO + `sourceMemoryRequestId` detail trace | remembered_price_rpc_mapper_test, customer_price_rule_detail_rpc_mapper_test | done |
| FR-05 | BE | §S9 | infrastructure | `memory_created` / `memory_updated` activity trace | pricing_remembered_price_from_order_s9_contract_test | done |
| BR-01 | BE | §S9 | infrastructure | anonymous → `ANONYMOUS_CUSTOMER` stored skip | pricing_remembered_price_from_order_s9_contract_test | done |
| BR-03..04 | BE | §S9 | infrastructure | replay-before-live + `IDEMPOTENCY_CONFLICT` | pricing_remembered_price_from_order_s9_contract_test, supabase_remembered_price_gateway_test | done |
| BR-05..06 | BE | §S9 | domain/infrastructure | manual protection + remembered rule type/source | remembered_price_request_test, pricing_remembered_price_from_order_s9_contract_test | done |
| EC-01..04 | BE | §S9 | application/infrastructure | fake scenarios + mapper/gateway/startup tests | fake_pricing_module_test, pricing_remembered_price_startup_test | done |
| SCN-01..03 | BE | §S9 | application/infrastructure | handler + fake + SQL contract coverage | scn_e02_u09_scn01_01 | done |
| AC-01..04 | BE | §S9 | application/infrastructure | contract isolation, idempotency, protection, trace | save_remembered_price_from_order_contract_test, customer_price_rule_detail_rpc_mapper_test | done |
| FR-01..05 | FE | §S9 | presentation | fake Sales confirmation/outcome surface | wgt_e02_u09_fr01_01 | todo |
| FR-01..05 | E2E | §S9 | integration | Sales publisher → Pricing | e2e_e02_u09_fr01_01 | blocked |

## S10 — US-10 History

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-10 | CONTRACT | §S10 | application | `GetCustomerPriceRuleHistoryQuery`, activity DTOs, 8 fake scenarios | get_customer_price_rule_history_contract_test | done |
| FR-01 | BE | §S10 | application/infrastructure | timeline page newest-first via keyset `(created_at DESC, id DESC)` | get_customer_price_rule_history_contract_test, pricing_customer_price_rule_history_s10_contract_test | done |
| FR-02 | BE | §S10 | application/infrastructure | activity type/actor/source/reason/old-new snapshots | customer_price_rule_history_rpc_mapper_test | done |
| FR-03 | BE | §S10 | application/infrastructure | import/order/memory trace from activity row | get_customer_price_rule_history_contract_test, pricing_customer_price_rule_history_s10_contract_test | done |
| FR-04 | BE | §S10 | application/infrastructure | opaque Base64URL cursor + refresh-safe paging | pricing_customer_price_rule_history_s10_contract_test, pricing_history_startup_test | done |
| FR-05 | BE | §S10 | application/infrastructure | read-only history; no mutation/lock/retention | pricing_customer_price_rule_history_s10_contract_test | done |
| BR-01 | BE | §S10 | application/infrastructure | `view_history` at query + RPC; permission before existence | pricing_history_startup_test, pricing_customer_price_rule_history_s10_contract_test | done |
| BR-02 | BE | §S10 | infrastructure | append-only; no update/delete activity | pricing_customer_price_rule_history_s10_contract_test | done |
| BR-03 | BE | §S10 | infrastructure | tenant + non-deleted rule → `NOT_FOUND` cross-tenant/deleted | get_customer_price_rule_history_contract_test, pricing_customer_price_rule_history_s10_contract_test | done |
| BR-04 | BE | §S10 | infrastructure | floor top-level redaction + fail-closed mapper | customer_price_rule_history_rpc_mapper_test, pricing_customer_price_rule_history_s10_contract_test | done |
| BR-05 | BE | §S10 | docs | export deferred; Q-02 retain indefinitely V1 | US-10.md | done |
| EC-01 | BE | §S10 | application/infrastructure | missing actor → `System/Migration` | get_customer_price_rule_history_contract_test, pricing_customer_price_rule_history_s10_contract_test | done |
| EC-02 | BE | §S10 | application/infrastructure | deep-unmodifiable snapshots; raw keys preserved when allowed | customer_price_rule_history_rpc_mapper_test | done |
| EC-03 | BE | §S10 | application | valid rule, no activity → empty page | get_customer_price_rule_history_contract_test | done |
| EC-04 | BE | §S10 | application | cross-tenant/deleted → `NOT_FOUND` | get_customer_price_rule_history_contract_test | done |
| AC-01 | BE | §S10 | application/infrastructure | timeline actor/source/time/change/reason | get_customer_price_rule_history_contract_test, customer_price_rule_history_rpc_mapper_test | done |
| AC-02 | BE | §S10 | application/infrastructure | pagination stable + tenant-safe | pricing_history_startup_test, pricing_customer_price_rule_history_s10_contract_test | done |
| AC-03 | BE | §S10 | application/infrastructure | read-only + activity-row source trace | pricing_customer_price_rule_history_s10_contract_test | done |
| AC-04 | BE | §S10 | application/infrastructure | legacy/system actor fallback | get_customer_price_rule_history_contract_test | done |
| FR-01..05 | FE | §S10 | presentation | activity timeline widgets | wgt_e02_u10_fr01_01 | done |
| FR-01..05 | E2E | §S10 | integration | mutation then immutable timeline | e2e_e02_u10_fr01_01 | todo |
