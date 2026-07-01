# TH-03 — Traceability

Ma trận truy vết FR → layer → artifact → test. Quy ước Req ID:

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e01/u02/fr06/SCN-01
Test id: scn_e01_u02_fr06_01 (handler/integration), wgt_e02_u01_fr03_01 (widget dialog)
```

<!-- exemplar-complete: deferred -->

**Exemplar:** deferred — điền đầy đủ một US khi mở slice đầu tiên (dự kiến Epic-01/US-02).

---

## Epic-01 / US-01 — Tìm kiếm và rà soát danh sách

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | — | — | `apps/erp/lib/features/partner/presentation/pages/partner_list_page.dart` | — | Implemented (presentation) |
| FR-02 | — | — | `modules/partner/presentation/lib/src/widgets/partner_search_bar.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `modules/partner/presentation/lib/src/widgets/partner_filter_dialog.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `modules/partner/presentation/lib/src/widgets/partner_empty_state.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `modules/partner/presentation/lib/src/bloc/partner_list_cubit.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `modules/partner/presentation/lib/src/bloc/partner_list_state.dart` | — | Implemented (presentation) |

---

## Epic-01 / US-02 — Ghi nhận đối tác mới

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | — | — | `apps/erp/lib/features/partner/presentation/pages/partner_create_page.dart` | — | Implemented (presentation) |
| FR-02 | — | — | `modules/partner/presentation/lib/src/widgets/partner_role_type_section.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `modules/partner/presentation/lib/src/widgets/partner_form_sections.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `modules/partner/presentation/lib/src/bloc/partner_create_cubit.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `modules/partner/presentation/lib/src/bloc/partner_create_state.dart` | — | Implemented (presentation) |

---

## Epic-01 / US-03 — Bổ sung và chỉnh sửa

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | application | `UpdatePartnerProfileCommand` | `apps/erp/lib/features/partner/presentation/pages/partner_edit_page.dart` | — | done |
| FR-02 | application | `GetPartnerDetailQuery` | `modules/partner/presentation/lib/src/widgets/partner_form_sections.dart` | — | done |
| FR-03 | infrastructure | `partner.update_partner` RPC | `modules/partner/presentation/lib/src/widgets/partner_role_type_section.dart` | — | done |
| FR-04 | domain | `BusinessPartner.updateProfile` | `modules/partner/presentation/lib/src/bloc/partner_edit_cubit.dart` | scn_e01_u03_fr04_01 | done |
| FR-05 | application | `CheckDuplicatePartnersQuery` | `modules/partner/presentation/lib/src/bloc/partner_edit_state.dart` | — | done |
| FR-06 | application | `UpdatePartnerProfileCommandHandler` | — | scn_e01_u03_fr06_01 | done |

---

## Epic-01 / US-04 — Kiểm tra hồ sơ

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | application | `GetPartnerDetailQuery` | `apps/erp/lib/features/partner/presentation/pages/partner_detail_page.dart` | — | done |
| FR-02 | infrastructure | `partner.get_partner_detail` RPC | `modules/partner/presentation/lib/src/widgets/partner_detail_header.dart` | — | done |
| FR-03 | application | `PartnerDetailDto` | `modules/partner/presentation/lib/src/widgets/partner_general_info_tab.dart` | — | done |
| FR-04 | application | `GetPartnerDetailQueryHandler` | `modules/partner/presentation/lib/src/bloc/partner_detail_cubit.dart` | scn_e01_u04_fr04_01 | done |
| FR-04 | — | — | `modules/partner/presentation/lib/src/bloc/partner_detail_state.dart` | — | done |
| FR-05 | — | — | `modules/partner/presentation/lib/src/widgets/partner_detail_menu.dart` | — | done |
| FR-05 | — | — | `modules/partner/presentation/lib/src/widgets/partner_transaction_history_tab.dart` | — | placeholder (Epic-03) |

---

## Epic-02 / US-01 — Dừng sử dụng / sử dụng lại

> Placeholder — điền khi mở slice.

| Req ID | Enforce layer | Artifact | Test id | Status |
| ------ | ------------- | -------- | ------- | ------ |
| _pending_ | — | — | — | placeholder |

---

## Epic-02 / US-02 — Loại bỏ hồ sơ tạo nhầm

> Placeholder — điền khi mở slice.

| Req ID | Enforce layer | Artifact | Test id | Status |
| ------ | ------------- | -------- | ------- | ------ |
| _pending_ | — | — | — | placeholder |

---

## Epic-03 / US-01 — Theo dõi lịch sử làm việc

> Placeholder — blocked (cần module nguồn publish events).

| Req ID | Enforce layer | Artifact | Test id | Status |
| ------ | ------------- | -------- | ------- | ------ |
| _pending_ | — | — | — | blocked |
