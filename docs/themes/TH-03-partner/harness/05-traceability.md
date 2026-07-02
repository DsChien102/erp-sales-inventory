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

## Platform — Messaging worker (Epic-03 consume)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-03-WORKER | BE | §US-01 | infrastructure | `PartnerMessagingModule` (delegate `IPartnerModule.executeCommandAsync`) | partner_messaging_module_test | done |
| TH-03-WORKER | BE | §US-01 | infrastructure | `ProcessInboxCommandHandler`, `ProcessInternalCommandsCommandHandler` (`IRecurringCommand` qua `CommandBus`) | process_inbox_command_handler_test, process_internal_commands_command_handler_test | done |
| TH-03-WORKER | BE | §US-01 | application | consumer handlers `*_integration_event_handler.dart` (`IIntegrationEventNotificationHandler`) | partner_transaction_history_consumer_handlers_test | done |
| TH-03-WORKER | BE | — | apps/messaging_worker | `messaging_worker_bootstrap.dart` registry `['partner']` | messaging_worker_loop_test | done |
| TH-03-WORKER | BE | — | sql | `scripts/supabase/messaging_smoke_test.sql` partner inbox + projection | — | done |

E2E cross-module relay: blocked — xem Epic-03 E2E rows below.

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
| FR-05 | FE | §US-04 | presentation | `partner_transaction_history_tab.dart` | wgt_e03_u01_fr01_01 | done |
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

> E2E blocked — chờ sales/inventory/accounting publish events end-to-end.

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §US-01 | application | `GetPartnerTransactionHistoryQuery` | — | done |
| FR-01 | BE | §US-01 | application | `GetPartnerTransactionHistoryQueryHandler` | scn_e03_u01_fr01_01 | done |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-02: Mở lịch sử làm việc thành công) | wgt_e03_u01_fr01_02 | done |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-03: Không hiển thị lịch sử khi thiếu quyền) | — | done |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-05: Đối tác chưa có lịch sử làm việc) | wgt_e03_u01_fr01_05 | done |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-01: Chuyển hướng người dùng chưa đăng nhập) | — | todo |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-04: Không hiển thị lịch sử của đối tác ngoài tenant) | — | todo |
| FR-01 | FE | §US-01 | presentation | `partner_detail_page.dart` (scn-06: Không tải được lịch sử làm việc) | — | todo |
| FR-01 | E2E | §US-01 | integration | cross-module events | e2e_e03_u01_fr01_01 | blocked |
| FR-02 | BE | §US-01 | infrastructure | `partner.get_partner_transaction_history` RPC, `SupabasePartnerTransactionHistoryReadGateway` | scn_e03_u01_fr02_01 | done |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-01: Hiển thị danh sách lịch sử làm việc) | wgt_e03_u01_fr02_01 | done |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-02: Hiển thị lịch sử theo vai trò Khách hàng) | — | done |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-03: Hiển thị lịch sử theo vai trò Nhà cung cấp) | — | done |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_item.dart` (scn-04: Hiển thị lịch sử của đối tác có cả hai vai trò) | wgt_e03_u01_fr02_04 | done |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_item.dart` (scn-05: Hiển thị dòng lịch sử thiếu mã giao dịch) | — | todo |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_item.dart` (scn-06: Hiển thị dòng lịch sử thiếu giá trị giao dịch) | — | todo |
| FR-02 | FE | §US-01 | presentation | `partner_transaction_item.dart` (scn-07: Không làm thay đổi giao dịch nguồn khi hiển thị lịch sử) | — | todo |
| FR-02 | E2E | §US-01 | integration | display list flow | e2e_e03_u01_fr02_01 | blocked |
| FR-03 | BE | §US-01 | domain | `PartnerTransactionHistoryCriteria` | scn_e03_u01_fr03_01 | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-01: Tìm lịch sử theo mã giao dịch) | wgt_e03_u01_fr03_01 | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-02: Tìm lịch sử theo diễn giải) | — | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-03: Lọc lịch sử theo loại giao dịch) | wgt_e03_u01_fr03_03 | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-04: Lọc lịch sử theo vai trò liên quan) | wgt_e03_u01_fr03_04 | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-05: Lọc lịch sử theo thời gian) | — | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-06: Kết hợp từ khóa và bộ lọc) | — | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-07: Không có lịch sử phù hợp với điều kiện) | — | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-08: Xóa toàn bộ điều kiện tìm kiếm và lọc) | wgt_e03_u01_fr03_08 | done |
| FR-03 | FE | §US-01 | presentation | `partner_transaction_filter_bottom_sheet.dart` (scn-09: Không tải được kết quả tìm kiếm hoặc lọc) | — | done |
| FR-03 | E2E | §US-01 | integration | search & filter flow | e2e_e03_u01_fr03_01 | blocked |
| FR-04 | BE | §US-01 | application | `SalesOrderCheckedOutIntegrationEventHandler` (consumer) + `SalesOrderCheckedOutIntegrationEvent` | scn_e03_u01_fr04_01 | done |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-01: Mở chi tiết giao dịch nguồn thành công) | — | todo |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-02: Không có quyền xem chi tiết giao dịch nguồn) | — | todo |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-03: Giao dịch nguồn không còn tồn tại) | — | todo |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-04: Giao dịch nguồn không thuộc tenant hiện tại) | — | todo |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-05: Module nguồn tạm thời không truy cập được) | — | todo |
| FR-04 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-06: Mở chi tiết không làm thay đổi dữ liệu) | — | todo |
| FR-04 | E2E | §US-01 | integration | source transaction navigation | e2e_e03_u01_fr04_01 | blocked |
| FR-05 | BE | §US-01 | application | `RecordPartnerTransactionHistoryCommand` | scn_e03_u01_fr05_01 | done |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-01: Xem lịch sử của đối tác đang hoạt động) | — | done |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-02: Xem lịch sử của đối tác ngừng hoạt động) | — | todo |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-03: Lịch sử không bị mất sau khi ngừng hoạt động) | — | todo |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-04: Xem lịch sử của đối tác đã xóa trong luồng được phép) | — | todo |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-05: Không hiển thị lịch sử của đối tác đã xóa ngoài luồng được phép) | — | todo |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-06: Đối tác đã xóa nhưng chưa có lịch sử làm việc) | — | todo |
| FR-05 | FE | §US-01 | presentation | `partner_transaction_history_tab.dart` (scn-07: Xem lịch sử không thay đổi trạng thái đối tác) | — | todo |
| FR-05 | E2E | §US-01 | integration | deleted partner history view | e2e_e03_u01_fr05_01 | blocked |

