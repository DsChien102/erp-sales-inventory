---
id: ENT-ARAP-CATALOG
type: entity-catalog
theme: theme-06
title: Danh mục Entity — Công nợ
owner: BA/SA
status: IN_REVIEW
---

# Danh mục Entity — Công nợ

Danh mục này phân biệt **owned business entity**, **child entity/value object**, **reference** và **projection** để tránh việc mỗi màn hình/BJ tự tạo một mô hình dữ liệu khác nhau.

## 1. Owned Entity / Child Entity

| ID | Object | Vai trò | Aggregate candidate |
|---|---|---|---|
| [ENT-ARAP-01](ENT-ARAP-01-nghia-vu-cong-no.md) | Nghĩa vụ công nợ | Sự thật về một khoản phải thu/phải trả đã xác lập và dư nợ còn lại | AGG-ARAP-04 |
| [ENT-ARAP-02](ENT-ARAP-02-khoan-thu-chi.md) | Khoản thu/chi | Một khoản tiền có hiệu lực trong nghiệp vụ công nợ | AGG-ARAP-05 |
| [ENT-ARAP-03](ENT-ARAP-03-phan-bo-thanh-toan.md) | Phân bổ thanh toán | Số tiền từ một khoản thu/chi được dùng cho một nghĩa vụ | Child candidate của AGG-ARAP-05; boundary cần SA review |
| [ENT-ARAP-04](ENT-ARAP-04-chinh-sach-phe-duyet.md) | Chính sách phê duyệt | Rule phê duyệt theo tổ chức/action/dải giá trị | AGG-ARAP-01 |
| [ENT-ARAP-05](ENT-ARAP-05-yeu-cau-phe-duyet.md) | Yêu cầu phê duyệt | Một yêu cầu cụ thể, giữ snapshot policy áp dụng | AGG-ARAP-02 |
| [ENT-ARAP-06](ENT-ARAP-06-dot-so-du-dau-ky.md) | Đợt số dư đầu kỳ | Bao nhóm các dòng cutover được lập/trình duyệt cùng đợt | AGG-ARAP-03 |
| [ENT-ARAP-07](ENT-ARAP-07-dong-so-du-dau-ky.md) | Dòng số dư đầu kỳ | Một khoản công nợ còn mở tại thời điểm cutover | Child của AGG-ARAP-03 |
| [ENT-ARAP-08](ENT-ARAP-08-can-tru-cong-no.md) | Cấn trừ công nợ | Nghiệp vụ explicit triệt tiêu một phần phải thu/phải trả cùng Partner | AGG-ARAP-06 |
| [ENT-ARAP-09](ENT-ARAP-09-dong-can-tru.md) | Dòng cấn trừ | Phần giá trị của một nghĩa vụ tham gia cấn trừ | Child của AGG-ARAP-06 |
| [ENT-ARAP-10](ENT-ARAP-10-doi-chieu-cong-no.md) | Đối chiếu công nợ | Một lần đối chiếu với Partner tại mốc/kỳ xác định | AGG-ARAP-07 |

## 2. Reference — không thuộc ownership Công nợ

- `PartnerRef` — canonical Partner thuộc Quản lý đối tác.
- `SourceDocumentRef` / `SourceVersionRef` — chứng từ/phiên bản nguồn thuộc Bán hàng hoặc Mua hàng.
- `UserRef` / `RoleRef` — danh tính và vai trò ngoài ownership Công nợ.
- `AccountingPostingRef` — kết quả ghi sổ thuộc Kế toán.
- `EvidenceRef` — tham chiếu bằng chứng/tệp; mechanism lưu trữ do kiến trúc quyết định.

Reference không được nâng thành owned entity chỉ vì UI cần hiển thị thêm thông tin.

## 3. Projection / Read Model — không phải Entity giao dịch và không phải Aggregate

- `PartnerDebtPosition` — phải thu mở, phải trả mở, chênh lệch, tiền chưa phân bổ theo Partner.
- `OpenDebtList` — danh sách nghĩa vụ còn mở.
- `DebtHistory` — lịch sử nghĩa vụ/thực hiện.
- `UnallocatedPaymentList` — khoản thu/chi còn phần chưa phân bổ.
- `ReconciliationHistory` — lịch sử đối chiếu.
- `ApprovalInbox` — danh sách yêu cầu cần duyệt.

Các projection phải có thể tái lập từ nguồn sự thật canonical; không được dùng projection để thay thế invariant của Aggregate.

## 4. Object cố ý không tạo

- `CustomerDebt` và `SupplierDebt` như hai identity độc lập — không tạo; cùng dùng Partner và chiều nghĩa vụ.
- `NetDebt` như một nghĩa vụ mới — không tạo; chênh lệch chỉ là kết quả tính/read model cho đến khi có nghiệp vụ cấn trừ explicit.
- `ReconciliationAdjustment` trong Phase 1 — không tạo; đối chiếu có chênh lệch không tự điều chỉnh công nợ.
