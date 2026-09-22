---
id: ENT-ARAP-02
type: business-entity
theme: theme-06
title: Khoản thu / chi
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-02 — Khoản thu / chi

## 1. Ý nghĩa nghiệp vụ

Đại diện cho một khoản tiền đã được ghi nhận có hiệu lực trong Công nợ. Khoản tiền có chiều **thu** hoặc **chi**, có thể được phân bổ ngay hoặc còn một phần chưa phân bổ.

## 2. Domain sở hữu

Domain Công nợ sở hữu semantic payment phục vụ công nợ. Khi tiền được ghi ở luồng nguồn, Công nợ phải tiếp nhận/tham chiếu thống nhất để **không tạo khoản tiền trùng**.

## 3. Identity

`payment_id` là định danh ổn định trong Công nợ. Với payment từ nguồn ngoài, cần giữ `source_payment_ref`/version đủ để chống duplicate; cơ chế cụ thể thuộc integration architecture.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `payment_id` | Định danh khoản tiền | Có | Ổn định qua retry |
| `tenant_id` | Tổ chức | Có | Allocation cùng tenant |
| `partner_id` | Đối tác | Có | Allocation cùng Partner |
| `direction` | Thu / chi | Có | Thu→phải thu; Chi→phải trả |
| `amount` | Tổng số tiền | Có | > 0 |
| `effective_date` | Mốc khoản tiền có hiệu lực | Có | Sau xác nhận ghi nhận thành công |
| `source_ref` | Nguồn khoản tiền | Không | Có thể từ Bán hàng hoặc ghi trực tiếp trong Công nợ |
| `status` | Trạng thái nghiệp vụ | Có | Reversal ngoài Phase 1 |
| `unallocated_amount` | Phần chưa phân bổ | Có | Giá trị dẫn xuất từ amount và allocation hiệu lực |

## 5. Quan hệ

- Một Payment có thể có nhiều `ENT-ARAP-03 Allocation`.
- Mỗi Payment thuộc đúng một Partner và một direction.

## 6. Lifecycle / trạng thái

Khoản tiền có hiệu lực khi ghi nhận thành công. Giai đoạn 1 không hỗ trợ Payment Reversal. Việc payment có draft hay không sẽ được chốt ở UC/UI, không mặc định trong entity này.

## 7. Quy tắc và Điều kiện bắt buộc

- `amount > 0`.
- Tổng allocation hiệu lực không vượt `amount`.
- Phần chưa phân bổ không tự giảm nghĩa vụ nào.
- Payment đã có hiệu lực và Allocation có hiệu lực là hai commit point riêng.
- Payment từ nguồn không được tạo bản ghi trùng khi Công nợ tiếp nhận.

## 8. Behavioral Contract / Use Case liên quan

BJ-03; payment nguồn liên quan handoff từ Bán hàng/Mua hàng. Aggregate candidate: [AGG-ARAP-05](../../../04.architecture/aggregates/AGG-ARAP-05-Payment.md).
