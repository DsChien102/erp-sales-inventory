# Aggregate Catalog — Candidate v0.1.0

**Owner:** SA, review cùng BA  
**Status:** `IN_REVIEW`  

Đây là candidate architecture để kiểm tra semantic của baseline, chưa phải persistence design cuối.

## AGG-T09-01 — Accounting Profile

**Root:** `AccountingProfile`

Sở hữu:
- identity theo tenant;
- trạng thái hồ sơ kế toán;
- `AccountingSchemeVersion` effective-dated;
- reference tới `PostingPolicySetVersion`;
- tax/accounting classification dùng để chọn rule.

Invariant:
- một tenant chỉ có một profile hiệu lực cho cùng accounting scope tại một thời điểm;
- version mới không rewrite period đã khóa;
- thay chế độ phải có `effective_from` và migration decision.

## AGG-T09-02 — Accounting Period

**Root:** `AccountingPeriod`

Sở hữu:
- khoảng ngày;
- state `OPEN|LOCKED`;
- lock/reopen metadata;
- close evidence summary.

Invariant:
- period của cùng tenant/scope không overlap;
- posting commit vào period `LOCKED` bị chặn;
- reopen cần privileged permission + reason + audit.

## AGG-T09-03 — Accounting Case

**Root:** `AccountingCase`

Child/owned:
- `AccountingFactSnapshot`;
- `PostingAttempt` history nhẹ;
- final business result.

Identity đề xuất:
`tenant + source_theme + source_object_type + source_object_id + source_version + posting_purpose`.

Invariant:
- một source version/purpose không có hai final `POSTED` case;
- source snapshot bất biến sau `POSTED`;
- final result không bị technical retry ghi đè.

## AGG-T09-04 — Accounting Entry

**Root:** `AccountingEntry`

Child:
- `AccountingEntryLine[]`;
- `AdjustmentLink[]`;
- dimension/evidence references.

Invariant:
- posted entry immutable;
- correction bằng entry mới;
- nếu scheme yêu cầu Nợ/Có, tổng debit = tổng credit theo currency;
- nếu scheme đơn giản không dùng account, line phải hợp lệ theo book/category schema;
- mỗi entry giữ policy/scheme version đã áp dụng.

## AGG-T09-05 — Manual Accounting Document

**Root:** `ManualAccountingDocument`

Mục đích: capture ý định điều chỉnh không bắt nguồn trực tiếp từ một event tự động.

Invariant:
- bắt buộc reason;
- yêu cầu evidence theo policy;
- không được dùng command này để mutate subledger của Theme 6/7;
- khi post sẽ tạo `AccountingEntry`, document không tự là ledger record.

## AGG-T09-06 — Reconciliation Case

**Root:** `ReconciliationCase`

Sở hữu process state, mismatch evidence, resolution links.

Không sở hữu business result cuối của source Theme.

Invariant:
- case chỉ đóng khi mismatch đã được xác lập resolution;
- không tự “chọn một bên đúng” nếu source owner chưa final.

## AGG-T09-07 — Statutory Book Run

**Root:** `StatutoryBookRun`

Child:
- `BookSnapshotRef`;
- generation metadata;
- source watermark/filter.

Invariant:
- một exported snapshot là bất biến;
- rebuild tạo run mới;
- book rows là projection, không trở thành nguồn ghi sổ ngược.

## AGG-T09-08 — Tax Profile

**Root:** `TaxProfile`

Sở hữu:
- classification có hiệu lực;
- tax policy references;
- filing obligation configuration do Theme 09 được phép sở hữu.

Không sở hữu legal profile gốc của Tenant.

## AGG-T09-09 — Tax Period

**Root:** `TaxPeriod`

Child:
- `TaxCalculationRun[]`;
- obligation status;
- source coverage summary.

Invariant:
- calculation run giữ policy version + source watermark;
- final snapshot không tự đổi do dữ liệu master hiện hành đổi.

## AGG-T09-10 — Tax Return

**Root:** `TaxReturn`

Child:
- `TaxReturnSnapshot[]`;
- amendment/replacement links;
- submission metadata trong Phase tương lai.

Invariant:
- form/schema version là explicit;
- amendment tạo version/return relation mới, không mutate filed snapshot;
- Phase 1 có thể dừng ở `READY_TO_FILE` nếu submission chưa hỗ trợ.

## Aggregate relationship

```text
AccountingProfile ──selects──> AccountingScheme/Policy
AccountingPeriod ──guards──> AccountingCase ──posts──> AccountingEntry
ManualAccountingDocument ──posts──> AccountingEntry
AccountingEntry ──projects──> StatutoryBookRun
AccountingCase/Entry ──may open──> ReconciliationCase
AccountingProfile/Entries ──feed──> TaxProfile/TaxPeriod ──produces──> TaxReturn
```

## Chưa chốt ở architecture

- physical partition/table design;
- event envelope/schema;
- outbox/inbox strategy chi tiết;
- sequence/numbering của entry;
- concurrency token cụ thể;
- read-model storage;
- tax submission integration.
