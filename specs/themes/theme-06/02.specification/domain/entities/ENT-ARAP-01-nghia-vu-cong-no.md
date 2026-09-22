---
id: ENT-ARAP-01
type: business-entity
theme: theme-06
title: Nghĩa vụ công nợ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-01 — Nghĩa vụ công nợ

## 1. Ý nghĩa nghiệp vụ

Đại diện cho **một nghĩa vụ phải thu hoặc phải trả đã được xác lập** và được Domain Công nợ theo dõi từ giá trị gốc đến dư nợ còn lại. Nghĩa vụ giữ quan hệ với nguồn phát sinh nhưng không sở hữu chứng từ nguồn.

## 2. Domain sở hữu

[DOM-ARAP — Công nợ](../domain-foundation/DOM-ARAP-cong-no.md) sở hữu trạng thái công nợ của nghĩa vụ sau mốc xác lập. Bán hàng/Mua hàng vẫn sở hữu chứng từ nguồn.

## 3. Identity

`obligation_id` là định danh ổn định trong Công nợ. Cần giữ source identity/version đủ để chống ghi trùng và truy vết; quy tắc uniqueness kỹ thuật do SA chốt.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `obligation_id` | Định danh nghĩa vụ | Có | Ổn định sau khi tạo |
| `tenant_id` | Tổ chức sở hữu ngữ cảnh | Có | Allocation/offset không vượt tenant |
| `partner_id` | Đối tác của nghĩa vụ | Có | Dùng canonical Partner ID |
| `direction` | Phải thu / phải trả | Có | Một nghĩa vụ chỉ có một chiều |
| `original_amount` | Giá trị nghĩa vụ ban đầu | Có | Giai đoạn 1 cùng một loại tiền tệ |
| `outstanding_amount` | Dư nợ còn lại | Có | Không âm; không vượt giá trị hợp lệ |
| `source_type` | Loại nguồn | Có | Bán hàng, Mua hàng, Số dư đầu kỳ... |
| `source_ref` | Tham chiếu nguồn | Có | Không biến nguồn thành owned entity |
| `source_version` | Phiên bản nguồn | Khi nguồn có version | Phục vụ correction/recovery |
| `effective_date` | Ngày/mốc nghiệp vụ | Có | Business time, không đồng nhất với recorded time |
| `resolution_state` | Trạng thái xử lý ngoại lệ | Khi có | Có thể thể hiện `Cần xử lý`; mã kỹ thuật chưa freeze |

## 5. Quan hệ

- Thuộc đúng một Partner.
- Có thể được thực hiện bởi nhiều `ENT-ARAP-03 Allocation`.
- Có thể tham gia một hoặc nhiều lần cấn trừ qua `ENT-ARAP-09 DebtOffsetLine` theo lịch sử.
- Có thể được dùng làm căn cứ cho nhiều lần `ENT-ARAP-10 DebtReconciliation`.

## 6. Lifecycle / trạng thái

Semantic tối thiểu: **đã xác lập → còn mở / đã thực hiện hết**; khi source correction không thể áp dụng hợp lệ thì chuyển sang **Cần xử lý** mà không tự đảo settlement. Tên enum kỹ thuật chưa freeze.

## 7. Quy tắc và Điều kiện bắt buộc

- Chỉ tạo nghĩa vụ chính thức sau finality nguồn.
- `outstanding_amount` không được âm.
- Settlement hợp lệ không được vượt outstanding tại thời điểm commit.
- Không silent overwrite sau finality; correction/reversal/version phải giữ lineage.
- Nghĩa vụ đã thanh toán đủ vẫn còn để truy vết nhưng không nằm trong open receivables/payables.

## 8. Behavioral Contract / Use Case liên quan

BJ-02, BJ-03, BJ-04, BJ-05, BJ-06. Aggregate candidate: [AGG-ARAP-04](../../../04.architecture/aggregates/AGG-ARAP-04-DebtObligation.md).
