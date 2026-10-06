# Terminology Standard — Theme 09

## UI-friendly labels

| Technical | UI đề xuất |
|---|---|
| AccountingCase | Giao dịch chờ ghi sổ / Chi tiết ghi sổ |
| POSTED | Đã ghi sổ |
| REJECTED | Không thể ghi sổ |
| PERIOD_LOCKED | Kỳ đã khóa |
| RECONCILIATION_NEEDED | Cần đối chiếu |
| AccountingPeriod | Kỳ kế toán |
| ManualAccountingDocument | Điều chỉnh kế toán |
| ReconciliationCase | Trường hợp cần đối chiếu |
| StatutoryBookRun | Bản sổ đã tạo |
| TaxPeriod | Kỳ khai thuế |
| TaxReturn | Hồ sơ khai thuế |

## Copy rules

- Không dùng `posting`, `ledger`, `reconcile`, `finality`, `source of truth` trong UI end-user nếu có từ Việt rõ hơn.
- Dùng “Đã ghi sổ” thay “Posted”.
- Dùng “Cần đối chiếu” thay “Reconciliation required”.
- Dùng “Kỳ đã khóa” thay “Period locked”.
- “Không thể ghi sổ” cần kèm lý do cụ thể; không dùng lỗi hệ thống chung cho rejection nghiệp vụ.
- Với accountant/expert view, có thể hiển thị mã entry/account/tax form trong secondary information.
