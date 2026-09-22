---
id: ENT-ARAP-07
type: business-entity
theme: theme-06
title: Dòng số dư đầu kỳ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-07 — Dòng số dư đầu kỳ

## 1. Ý nghĩa nghiệp vụ

Đại diện cho **một khoản công nợ còn mở** của một đối tác tại thời điểm cutover.

## 2. Domain sở hữu

Child entity của đợt số dư đầu kỳ trong Domain Công nợ.

## 3. Identity

`opening_balance_line_id` ổn định trong batch để hỗ trợ audit/idempotent finalization.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `opening_balance_line_id` | Định danh dòng | Có | Child identity |
| `partner_id` | Đối tác | Có | Canonical Partner |
| `direction` | Phải thu / phải trả | Có | Một chiều |
| `amount` | Số còn mở tại cutover | Có | > 0 |
| `basis_date` | Ngày/căn cứ của khoản | Có | Theo quyết định nghiệp vụ |
| `reference` | Tham chiếu cũ nếu có | Không | Không tạo source sale/purchase giả |
| `description` | Mô tả | Không | Giải thích khoản |

## 5. Quan hệ

Thuộc đúng một OpeningBalanceBatch; khi finalization thành công tương ứng với một DebtObligation nguồn số dư đầu kỳ.

## 6. Lifecycle / trạng thái

Lifecycle phụ thuộc batch; sau khi tạo nghĩa vụ thành công không tiếp tục dùng line như nơi cập nhật outstanding.

## 7. Quy tắc và Điều kiện bắt buộc

- Một line biểu diễn một khoản còn mở, không chỉ tổng net Partner.
- Amount là phần còn nợ tại cutover, không phải original historical amount đã bao gồm phần đã trả.
- Partner/direction/amount/date là bắt buộc.

## 8. Behavioral Contract / Use Case liên quan

BJ-02; child của [AGG-ARAP-03](../../../04.architecture/aggregates/AGG-ARAP-03-OpeningBalanceBatch.md).
