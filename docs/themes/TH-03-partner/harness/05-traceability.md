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
| FR-02 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_search_bar.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_filter_dialog.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_empty_state.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_list_cubit.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_list_state.dart` | — | Implemented (presentation) |

---

## Epic-01 / US-02 — Ghi nhận đối tác mới

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | — | — | `apps/erp/lib/features/partner/presentation/pages/partner_create_page.dart` | — | Implemented (presentation) |
| FR-02 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_role_type_section.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_form_sections.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_create_cubit.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_create_state.dart` | — | Implemented (presentation) |

---

## Epic-01 / US-03 — Bổ sung và chỉnh sửa

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | — | — | `apps/erp/lib/features/partner/presentation/pages/partner_edit_page.dart` | — | Implemented (presentation) |
| FR-02 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_form_sections.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_role_type_section.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_edit_cubit.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_edit_state.dart` | — | Implemented (presentation) |

---

## Epic-01 / US-04 — Kiểm tra hồ sơ

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| FR-01 | — | — | `apps/erp/lib/features/partner/presentation/pages/partner_detail_page.dart` | — | Implemented (presentation) |
| FR-02 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_detail_header.dart` | — | Implemented (presentation) |
| FR-03 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_general_info_tab.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_detail_cubit.dart` | — | Implemented (presentation) |
| FR-04 | — | — | `apps/erp/lib/features/partner/presentation/bloc/partner_detail_state.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_transaction_history_tab.dart` | — | Implemented (presentation) |
| FR-05 | — | — | `apps/erp/lib/features/partner/presentation/widgets/partner_transaction_item.dart` | — | Implemented (presentation) |

---

## Epic-02 / US-01 — Dừng sử dụng / sử dụng lại

> Placeholder — điền khi mở slice.

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| _pending_ | — | — | — | — | placeholder |

---

## Epic-02 / US-02 — Loại bỏ hồ sơ tạo nhầm

> Placeholder — điền khi mở slice.

| Req ID | Enforce layer | Artifact | Presentation artifact | Test id | Status |
| ------ | ------------- | -------- | --------------------- | ------- | ------ |
| _pending_ | — | — | — | — | placeholder |

---

## Epic-03 / US-01 — Theo dõi lịch sử làm việc

> Placeholder — blocked (cần module nguồn publish events).

| Req ID | Enforce layer | Artifact | Test id | Status |
| ------ | ------------- | -------- | ------- | ------ |
| _pending_ | — | — | — | blocked |
