# Entity Catalog — Theme 09

## 1. Quy ước

- `AR`: Aggregate Root.
- `CE`: Child Entity.
- `PE`: Process Entity.
- `REF`: External/owned-by-other reference.
- `VO`: Value Object / embedded structure.
- Projection không được dùng như write-side source of truth.

## 2. Catalog

| Entity | Type | Owner domain | Purpose |
|---|---|---|---|
| AccountingProfile | AR | Hồ sơ & chế độ | Hồ sơ kế toán hiện hành của tenant |
| AccountingSchemeVersion | CE | Hồ sơ & chế độ | Chế độ kế toán có hiệu lực theo thời gian |
| PostingPolicySetVersion | REF/Config | Hồ sơ & chế độ | Bộ rule versioned dùng để diễn giải fact |
| AccountingPeriod | AR | Kỳ kế toán | Mở/khóa kỳ |
| AccountingCase | AR | Tiếp nhận & ghi sổ | Một ca xử lý accounting impact từ source version/purpose |
| AccountingFactSnapshot | CE | Tiếp nhận & ghi sổ | Snapshot canonical tối thiểu của sự thật nguồn |
| PostingAttempt | CE | Tiếp nhận & ghi sổ | Lịch sử attempt xử lý, tách technical attempt khỏi final result |
| AccountingEntry | AR | Sổ kế toán | Bản ghi kế toán authoritative sau posting |
| AccountingEntryLine | CE | Sổ kế toán | Dòng chi tiết theo scheme |
| ManualAccountingDocument | AR | Điều chỉnh | Ý định điều chỉnh thủ công trước khi post |
| AdjustmentLink | CE/VO | Điều chỉnh | Quan hệ original/reversal/replacement |
| ReconciliationCase | PE/AR | Đối chiếu | Điều phối mismatch cần xác lập |
| StatutoryBookRun | AR | Sổ kế toán | Một lần sinh/xuất sổ với watermark rõ |
| BookSnapshotRef | CE | Sổ kế toán | Reference tới output bất biến của run |
| TaxProfile | AR | Thuế | Classification/policy thuế hiệu lực |
| TaxPeriod | AR | Thuế | Kỳ nghĩa vụ thuế |
| TaxCalculationRun | CE | Thuế | Kết quả tính với policy/source watermark |
| TaxReturn | AR | Thuế | Hồ sơ khai theo kỳ/loại nghĩa vụ |
| TaxReturnSnapshot | CE | Thuế | Snapshot bất biến của một version hồ sơ khai |
| SourceReference | VO | Cross-cutting | Định danh đối tượng upstream |
| AccountingDimensionSet | VO | Cross-cutting | Cửa hàng/đối tác/sản phẩm/kho/kênh... theo reference |
| EvidenceReference | VO | Cross-cutting | Link chứng từ/tài liệu bằng chứng |
| Money | VO | Cross-cutting | amount + currency; Phase 1 currency=VND |
| PolicyReference | VO | Cross-cutting | ID/version/effective date của rule đã áp dụng |

## 3. Key entity contracts

### 3.1 AccountingProfile

**Identity:** `accounting_profile_id`, `tenant_id`.

Thuộc tính chính:
- `status`;
- `current_scheme_version_id`;
- `base_currency_code`;
- `business_timezone` reference;
- `effective_from`;
- `version` optimistic concurrency.

Invariant:
- `tenant_id` immutable;
- Phase 1 `base_currency_code = VND`;
- không áp scheme mới ngược vào locked period.

### 3.2 AccountingSchemeVersion

Thuộc tính:
- `scheme_code` — ví dụ `VN_HKD_TT152_2025`;
- `version_no`;
- `effective_from`, `effective_to`;
- `uses_chart_of_accounts`;
- `requires_debit_credit_balance`;
- `applicable_book_codes[]`;
- `posting_policy_set_version_id`.

Không lưu text pháp luật toàn bộ trong entity; legal source/version nằm metadata/config registry.

### 3.3 AccountingPeriod

Thuộc tính:
- `period_id`, `tenant_id`;
- `start_date`, `end_date`;
- `status OPEN|LOCKED`;
- `locked_at`, `locked_by`;
- `lock_reason`;
- `reopen_count`, `last_reopened_at`, `last_reopened_by`, `reopen_reason`;
- `version`.

### 3.4 AccountingCase

Thuộc tính:
- `accounting_case_id`;
- `source_reference`;
- `posting_purpose`;
- `status`;
- `source_effective_at`;
- `proposed_accounting_date`;
- `policy_reference`;
- `received_at`, `finalized_at`;
- `final_result_code`;
- `entry_id` nullable;
- `reconciliation_case_id` nullable.

Uniqueness candidate:
`tenant_id + source_theme + source_object_type + source_object_id + source_version + posting_purpose`.

### 3.5 AccountingFactSnapshot

Nội dung canonical tối thiểu:
- source identity/version;
- fact type;
- gross/net/tax/cost amounts khi source cung cấp authoritative;
- counterparty/product/store/warehouse references khi có;
- original effective time;
- evidence references;
- source payload checksum hoặc semantic hash;
- captured_at.

Không copy toàn bộ source aggregate nếu không cần cho audit/accounting.

### 3.6 AccountingEntry

Thuộc tính:
- `entry_id`, `entry_no`;
- `tenant_id`;
- `accounting_date`, `recorded_at`;
- `entry_type AUTO|MANUAL|ADJUSTMENT|REVERSAL|OPENING`;
- `source_case_id` nullable với manual;
- `scheme_version_id`, `policy_reference`;
- `description_vi`;
- `status POSTED|REVERSED`;
- `reverses_entry_id` nullable;
- `created_by_actor` / system origin;
- `version`.

### 3.7 AccountingEntryLine

Thuộc tính:
- `line_id`, `entry_id`, `line_no`;
- `book_category_code`;
- `account_code` nullable;
- `side` nullable `DEBIT|CREDIT`;
- `money`;
- `quantity` nullable;
- `dimension_set`;
- `tax_category_code` nullable;
- `memo_vi`.

Validation phụ thuộc scheme version; không bắt account/side cho chế độ không dùng hệ thống tài khoản.

### 3.8 ManualAccountingDocument

Thuộc tính:
- `manual_document_id`;
- `document_type`;
- `accounting_date`;
- `reason_code`, `reason_text`;
- `evidence_references[]`;
- `status DRAFT|READY|POSTED|CANCELLED`;
- `posted_entry_id` nullable;
- actor/audit metadata.

Rule:
- không được ghi trực tiếp vào owner balance của Theme 6/7;
- nếu adjustment có ý nghĩa cross-theme thì tạo reconciliation/handoff thay vì giả sửa source.

### 3.9 ReconciliationCase

Thuộc tính:
- `case_id`, `case_type`;
- `target_reference`;
- `status OPEN|WAITING_SOURCE|RESOLVED|CLOSED`;
- `detected_at`;
- `evidence[]`;
- `resolution_code`, `resolved_at`;
- `resulting_entry_ids[]`.

### 3.10 StatutoryBookRun

Thuộc tính:
- `book_run_id`;
- `book_code`;
- `period_from`, `period_to`;
- `scheme_version_id`;
- `source_watermark`;
- `generated_at`, `generated_by`;
- `snapshot_ref`;
- `checksum`.

Book run là output snapshot, không phải nơi user sửa số.

### 3.11 TaxProfile

Thuộc tính:
- `tax_profile_id`, `tenant_id`;
- `classification_code`;
- `effective_from/to`;
- `tax_policy_version_id`;
- `filing_frequency` nếu được rule quyết định;
- reference legal profile snapshot khi cần.

### 3.12 TaxPeriod

Thuộc tính:
- `tax_period_id`;
- `tax_type`;
- `period_from/to`;
- `status OPEN|CALCULATED|READY_TO_FILE|FILED|AMENDED`;
- `due_date` policy-derived;
- `latest_calculation_run_id`;
- `latest_return_id`.

### 3.13 TaxCalculationRun

Thuộc tính:
- `calculation_run_id`;
- `tax_period_id`;
- `policy_version_id`;
- `source_watermark`;
- `input_summary`;
- `result_summary`;
- `generated_at`;
- `checksum`.

### 3.14 TaxReturn / TaxReturnSnapshot

`TaxReturn` quản lý lifecycle hồ sơ; `TaxReturnSnapshot` giữ nội dung đã render/chuẩn bị theo `form_schema_version`.

Filed/amended snapshot bất biến. Phase 1 có thể dừng ở `READY_TO_FILE`.

## 4. Reference entities intentionally not owned

Theme 09 chỉ tham chiếu, không tạo entity owner mới cho:
- Tenant/User/Permission — Theme 1.
- Partner — Theme 3.
- SalesOrder/Return — Theme 5.
- Receivable/Payable/Collection/Payment allocation — Theme 6.
- Inventory movement/valuation/official cost — Theme 7.
- ElectronicInvoice — Theme 8.
- Purchase order/receipt commercial term/discount program — Theme 10.

## 5. Projection candidates — chưa phải entity authoritative

- Accounting Worklist.
- Source Posting Status.
- Period Close Summary.
- Ledger/Book View.
- Revenue/Expense by dimension.
- Tax Obligation Summary.
- Return Readiness.

Các projection này sẽ được đặc tả ở `04.architecture/read-models/` khi BA semantic đủ freeze.
