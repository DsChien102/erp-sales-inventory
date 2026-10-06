---
id: ENT-ARAP-06
type: business-entity
theme: theme-06
title: Đợt số dư đầu kỳ
owner: BA/SA
status: IN_REVIEW
---
# ENT-ARAP-06 — Đợt số dư đầu kỳ

## 1. Ý nghĩa nghiệp vụ

Bao nhóm nhiều khoản công nợ còn mở được chuẩn bị trong cùng một đợt cutover để trình duyệt và xác lập.

## 2. Domain sở hữu

Công nợ sở hữu hồ sơ khởi tạo số dư đầu kỳ; không tạo giả giao dịch bán/mua lịch sử.

## 3. Identity

`opening_balance_batch_id` là định danh ổn định của đợt.

## 4. Thuộc tính nghiệp vụ chính

| Thuộc tính | Ý nghĩa | Bắt buộc | Ghi chú |
|---|---|---:|---|
| `opening_balance_batch_id` | Định danh đợt | Có | Audit |
| `tenant_id` | Tổ chức | Có | Scope batch |
| `as_of_date` | Mốc số dư đầu kỳ | Có | Business cutover date |
| `created_by` | Người lập | Có | Maker |
| `status` | Trạng thái đợt | Có | Lifecycle chi tiết chờ UC |
| `approval_request_ref` | Yêu cầu duyệt | Khi policy yêu cầu | Mặc định Phase 1 cần duyệt |

## 5. Quan hệ

Một batch có 1..N `ENT-ARAP-07 OpeningBalanceLine`. Mỗi line sau khi được xác lập thành công tạo/neo một DebtObligation nguồn `OPENING_BALANCE`.

## 6. Lifecycle / trạng thái

Tối thiểu phải phân biệt trạng thái còn chuẩn bị, chờ duyệt/được duyệt nếu áp dụng policy, và đã xác lập. Exact states chờ UC-02.

## 7. Quy tắc và Điều kiện bắt buộc

- Có thể chứa nhiều khoản trong một đợt.
- Mỗi khoản là một công nợ còn mở, không nhập lại phần lịch sử đã thanh toán.
- Sau khi đã phê duyệt/xác lập, không sửa trực tiếp; sai sót đi theo cơ chế xử lý ngoại lệ tương lai.
- Atomicity toàn batch chưa được chốt; SA phải thiết kế recovery/idempotency khi tạo nhiều obligations.

## 8. Behavioral Contract / Use Case liên quan

BJ-02. Aggregate candidate: [AGG-ARAP-03](../../../04.architecture/aggregates/AGG-ARAP-03-OpeningBalanceBatch.md).
