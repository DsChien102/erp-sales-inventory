---
id: ENT-ARAP-03
type: business-entity
theme: theme-06
title: Phân bổ thanh toán
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-03 — Phân bổ thanh toán

## 1. Ý nghĩa nghiệp vụ

Ghi nhận phần tiền cụ thể từ một khoản thu/chi được dùng để thực hiện một nghĩa vụ công nợ cụ thể.

## 2. Domain sở hữu

Công nợ sở hữu quan hệ và số tiền phân bổ. Aggregate boundary cuối cùng của Allocation còn cần SA review vì allocation đồng thời tiêu hao capacity của Payment và outstanding của DebtObligation.

## 3. Identity

`allocation_id` cần ổn định để truy vết và chống áp dụng lặp. Việc identity nằm hoàn toàn trong Payment aggregate hay có aggregate riêng chưa freeze.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `allocation_id` | Định danh phân bổ | Có | Dùng audit/idempotency |
| `payment_id` | Khoản tiền nguồn | Có | Thuộc cùng Partner/Tenant |
| `obligation_id` | Nghĩa vụ đích | Có | Đúng chiều |
| `amount` | Số tiền phân bổ | Có | > 0 |
| `effective_at` | Thời điểm phân bổ có hiệu lực | Có | Sau commit thành công |
| `status` | Trạng thái kết quả | Có | UNKNOWN/recovery sẽ do BC/architecture chốt |

## 5. Quan hệ

Mỗi Allocation nối đúng một Payment với đúng một DebtObligation. Một Payment có nhiều Allocation; một DebtObligation có thể nhận nhiều Allocation.

## 6. Lifecycle / trạng thái

Phân bổ có hiệu lực độc lập với thời điểm Payment có hiệu lực. Re-allocation sau khi final nằm ngoài Phase 1.

## 7. Quy tắc và Điều kiện bắt buộc

- Cùng tenant, cùng Partner.
- Payment Thu chỉ vào nghĩa vụ phải thu; Payment Chi chỉ vào nghĩa vụ phải trả.
- `amount` không vượt unallocated amount của Payment tại commit.
- `amount` không vượt outstanding của DebtObligation tại commit.
- Phần chưa có kết quả rõ không làm giảm outstanding.

## 8. Behavioral Contract / Use Case liên quan

UC-03-03 dự kiến; cần Shared Behavioral Contract cho money/concurrency/idempotency. Aggregate candidate hiện tại: child của [AGG-ARAP-05](../../../04.architecture/aggregates/AGG-ARAP-05-Payment.md), nhưng đây là điểm review kiến trúc trọng yếu.
