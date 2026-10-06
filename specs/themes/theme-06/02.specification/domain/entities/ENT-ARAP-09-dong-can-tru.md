---
id: ENT-ARAP-09
type: business-entity
theme: theme-06
title: Dòng cấn trừ công nợ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-09 — Dòng cấn trừ công nợ

## 1. Ý nghĩa nghiệp vụ

Xác định phần giá trị của một nghĩa vụ cụ thể được đưa vào một nghiệp vụ cấn trừ.

## 2. Domain sở hữu

Child entity của DebtOffset; không sở hữu lifecycle của DebtObligation được tham chiếu.

## 3. Identity

`offset_line_id` ổn định trong DebtOffset để audit từng nghĩa vụ tham gia.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `offset_line_id` | Định danh dòng | Có | Child identity |
| `obligation_id` | Nghĩa vụ tham gia | Có | Reference |
| `side` | RECEIVABLE / PAYABLE | Có | Phù hợp direction obligation |
| `amount` | Phần giá trị cấn trừ | Có | > 0 và <= outstanding tại commit |

## 5. Quan hệ

Thuộc một DebtOffset; tham chiếu một DebtObligation. Một obligation có thể xuất hiện trong nhiều offset lịch sử nếu mỗi lần còn đủ outstanding.

## 6. Lifecycle / trạng thái

Lifecycle phụ thuộc DebtOffset; line không được dùng như source of truth cho outstanding sau khi offset đã apply.

## 7. Quy tắc và Điều kiện bắt buộc

- `side` phải khớp direction của obligation.
- Amount không vượt outstanding tại commit.
- Tổng line RECEIVABLE = tổng line PAYABLE = giá trị offset có hiệu lực.

## 8. Behavioral Contract / Use Case liên quan

BJ-06; child của [AGG-ARAP-06](../../../04.architecture/aggregates/AGG-ARAP-06-DebtOffset.md).
